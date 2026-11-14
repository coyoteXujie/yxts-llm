#!/usr/bin/env python3
"""
批量生成横版舞台背景资产
为缺少横版舞台的 46 个区域生成地面/中景/前景三层 PNG
使用地形和区域类型驱动的颜色方案
"""

from __future__ import annotations
import math, random, json, sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
DATA_DIR = PROJECT / "data"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
SCENE_DIR = PROJECT / "assets" / "world" / "scenes"

SIZE = (1672, 941)
SCENE_SIZE = (1672, 941)  # 场景背景与舞台背景同尺寸
W, H = SIZE
SEED_BASE = "batch-gen-v1"
OUTPUT_QUALITY = 95

# ─── 地形配色方案 ─────────────────────────────────────

TERRAIN_PALETTES = {
    # (terrain_substring) -> (top_sky, bottom_sky, ground, accent, water)
    "default":   ((180, 200, 215), (130, 150, 170), (120, 100, 70),  (90, 70, 40),    (60, 120, 130)),
    "plain":     ((190, 210, 220), (140, 160, 175), (130, 115, 75),  (100, 85, 50),   (50, 110, 120)),
    "field":     ((200, 215, 210), (155, 175, 155), (145, 135, 70),  (110, 100, 45),  (55, 115, 110)),
    "town":      ((195, 205, 210), (145, 150, 155), (125, 105, 75),  (95, 75, 45),    (55, 110, 115)),
    "water":     ((175, 200, 220), (120, 155, 180), (110, 95, 70),   (80, 65, 40),    (50, 115, 135)),
    "river":     ((170, 198, 220), (115, 150, 175), (105, 90, 65),   (75, 60, 38),    (45, 110, 140)),
    "lake":      ((165, 195, 220), (110, 145, 175), (100, 85, 60),   (70, 55, 35),    (40, 105, 140)),
    "canal":     ((175, 200, 215), (120, 155, 170), (110, 95, 70),   (80, 65, 40),    (48, 112, 138)),
    "mountain":  ((160, 175, 195), (110, 125, 145), (105, 90, 65),   (75, 60, 38),    (50, 100, 110)),
    "cliff":     ((155, 170, 190), (105, 120, 140), (100, 85, 60),   (70, 55, 35),    (48, 95, 105)),
    "pass":      ((160, 178, 195), (110, 128, 145), (108, 92, 65),   (78, 62, 38),    (50, 100, 110)),
    "gorge":     ((145, 165, 185), (95, 115, 135),  (95, 80, 58),    (65, 50, 32),    (40, 90, 110)),
    "valley":    ((165, 185, 200), (115, 135, 150), (110, 95, 70),   (80, 65, 40),    (50, 100, 115)),
    "forest":    ((180, 205, 195), (130, 160, 140), (100, 110, 55),  (65, 80, 30),    (45, 100, 105)),
    "bamboo":    ((185, 210, 195), (135, 165, 140), (105, 115, 55),  (70, 85, 30),    (50, 105, 110)),
    "garden":    ((195, 210, 195), (150, 170, 145), (120, 115, 65),  (90, 85, 38),    (55, 110, 115)),
    "desert":    ((220, 200, 170), (185, 160, 125), (165, 135, 75),  (135, 105, 50),  (60, 100, 110)),
    "spring":    ((195, 210, 215), (150, 170, 175), (130, 110, 75),  (100, 80, 48),   (55, 115, 125)),
    "marsh":     ((175, 195, 185), (125, 150, 140), (100, 105, 60),  (70, 75, 35),    (45, 100, 100)),
    "sect":      ((185, 195, 205), (135, 145, 155), (120, 100, 70),  (90, 70, 40),    (55, 105, 115)),
    "snow":      ((210, 215, 225), (180, 190, 205), (160, 155, 150), (130, 125, 120), (100, 130, 150)),
    "ford":      ((180, 200, 210), (130, 155, 170), (115, 100, 70),  (85, 70, 42),    (48, 112, 130)),
    "mound":     ((195, 200, 195), (150, 155, 145), (130, 110, 70),  (100, 80, 42),   (55, 105, 110)),
    "tide":      ((170, 195, 215), (115, 145, 170), (105, 90, 65),   (75, 60, 38),    (42, 108, 142)),
    "waterway":  ((172, 198, 218), (118, 150, 175), (108, 92, 65),   (78, 62, 38),    (44, 110, 140)),
    "river_valley": ((160, 185, 200), (110, 135, 150), (105, 90, 65), (75, 60, 38),   (45, 100, 120)),
    "lake_palace": ((180, 200, 220), (130, 155, 180), (115, 100, 70), (85, 70, 42),   (50, 110, 130)),
    "shadow_sect": ((140, 140, 155), (90, 90, 105),  (80, 70, 55),   (55, 45, 30),    (40, 80, 90)),
    "daoist_sect": ((185, 200, 205), (140, 155, 160), (120, 105, 70), (90, 75, 42),   (55, 105, 115)),
    "water_town":  ((180, 202, 218), (128, 155, 175), (112, 95, 68),  (82, 65, 38),   (48, 112, 135)),
    "snow_sect":   ((210, 215, 225), (180, 190, 205), (160, 155, 150), (130, 125, 120), (100, 130, 150)),
    "bath":        ((195, 205, 210), (155, 165, 170), (135, 115, 75), (105, 85, 45),   (58, 118, 128)),
}


def rgba(r, g, b, a=255):
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), max(0, min(255, a)))

def xy(x, y):
    return (round(x), round(y))

def box(x0, y0, x1, y1):
    return (round(x0), round(y0), round(x1), round(y1))


def _lookup_palette(terrain: str) -> dict:
    for key, palette in TERRAIN_PALETTES.items():
        if key in terrain:
            return palette
    return TERRAIN_PALETTES["default"]


def vertical_gradient(size, top_rgb, bottom_rgb):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        r = round(top_rgb[0] + (bottom_rgb[0] - top_rgb[0]) * t)
        g = round(top_rgb[1] + (bottom_rgb[1] - top_rgb[1]) * t)
        b = round(top_rgb[2] + (bottom_rgb[2] - top_rgb[2]) * t)
        draw.line([(0, y), (w, y)], fill=rgba(r, g, b, 255))
    return img


def add_glow(image, center, radius, color, alpha):
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius, cx + radius, cy + radius), fill=rgba(*color, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(max(2, round(radius * 0.42))))
    image.alpha_composite(glow)


def draw_mountain_band(draw, w, h, base_y, height, color, seed_str):
    rng = random.Random(seed_str)
    points = [(0, base_y + height * 0.38)]
    steps = 16
    for i in range(steps + 1):
        x = w * i / steps
        y = base_y - height * (0.34 + rng.random() * 0.42) + math.sin(i * 1.19) * height * 0.08
        points.append((x, y))
    points.append((w, base_y + height * 0.38))
    draw.polygon([(round(px), round(py)) for px, py in points], fill=color)


def draw_forest_band(draw, w, h, base_y, height, color, seed_str, trunk_color):
    rng = random.Random(seed_str)
    draw_mountain_band(draw, w, h, base_y, height, color, seed_str)
    for i in range(32):
        x = rng.uniform(0, w)
        trunk_h = rng.uniform(height * 0.3, height * 0.7)
        tw = max(2, rng.uniform(2, 5))
        draw.line([xy(x, base_y), xy(x, base_y - trunk_h)], fill=trunk_color, width=round(tw))
        for branch in range(3):
            bx = x + rng.uniform(-20, 20)
            by = base_y - trunk_h * rng.uniform(0.4, 0.9)
            draw.line([xy(bx, by), xy(bx + rng.uniform(-40, 40), by - rng.uniform(10, 30))],
                       fill=rgba(*color[:3], round(color[3] * 0.6)), width=1)


def draw_building_row(draw, w, h, y, count, accent, alpha, seed_str):
    rng = random.Random(seed_str)
    spacing = w / (count + 1)
    for i in range(count):
        x = spacing * (i + 1) + rng.uniform(-spacing * 0.15, spacing * 0.15)
        bw = rng.uniform(48, 96)
        bh = rng.uniform(60, 120)
        draw.rectangle(box(x - bw / 2, y - bh, x + bw / 2, y), fill=rgba(*accent, round(alpha * rng.uniform(0.6, 0.9))))
        draw.rectangle(box(x - bw / 4, y - bh * 0.35, x + bw / 4, y - bh * 0.2), fill=rgba(*accent, round(alpha * 0.8)))
        roof_top = y - bh
        draw.polygon([(round(x - bw * 0.7), round(roof_top + bh * 0.12)),
                       (round(x), round(roof_top - bh * 0.15)),
                       (round(x + bw * 0.7), round(roof_top + bh * 0.12))],
                      fill=rgba(*accent, round(alpha * 0.7)))


# ─── 图层生成 ─────────────────────────────────────────

def generate_floor(size, terrain, accent, water_color, rng):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    ground_top = h * 0.52

    is_water = any(w in terrain for w in ["river", "lake", "canal", "water", "marsh", "tide", "ford", "waterway"])
    is_mountain = any(w in terrain for w in ["mountain", "cliff", "pass", "gorge"])
    is_desert = "desert" in terrain
    is_snow = "snow" in terrain
    is_forest = any(w in terrain for w in ["forest", "bamboo", "garden"])

    # Ground
    if is_water:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(*water_color, 180))
        for i in range(30):
            y = ground_top + rng.uniform(0, h - ground_top)
            draw.line([(0, y), (w, y + rng.uniform(-10, 10))], fill=rgba(*water_color, round(rng.uniform(30, 80))), width=1)
    elif is_snow:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(210, 205, 200, 255))
        for i in range(20):
            y = ground_top + rng.uniform(0, h - ground_top)
            draw.line([(0, y), (w, y + rng.uniform(-5, 5))], fill=rgba(225, 220, 215, round(rng.uniform(40, 90))), width=rng.randint(2, 5))
    else:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(*accent, 255))
        for i in range(40):
            y = ground_top + rng.uniform(0, h - ground_top)
            alpha = rng.uniform(20, 60)
            draw.line([(0, y), (w, y)], fill=rgba(*accent, round(alpha)), width=rng.randint(1, 3))

    # Path
    if not is_water and not is_mountain:
        path_color = rgba(*accent, 80)
        draw.rectangle(box(w * 0.25, ground_top, w * 0.75, h), fill=path_color)
        for i in range(10):
            y = ground_top + (h - ground_top) * i / 9
            draw.line([(w * 0.25, y), (w * 0.75, y + rng.uniform(-8, 8))], fill=rgba(*accent, round(rng.uniform(20, 40))), width=1)

    # Water reflection for water regions
    if is_water:
        for i in range(15):
            x = rng.uniform(0, w)
            y = ground_top + rng.uniform(0, h - ground_top)
            highlight = rgba(200, 220, 230, round(rng.uniform(20, 50)))
            draw.line([(x, y), (x + rng.uniform(20, 60), y + rng.uniform(-5, 5))], fill=highlight, width=1)

    return img


def generate_midground(size, terrain, accent, top_sky, region_type, rng):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    ground_top = h * 0.52
    is_mountain = any(w in terrain for w in ["mountain", "cliff", "pass", "gorge", "valley"])
    is_forest = any(w in terrain for w in ["forest", "bamboo", "garden"])
    is_water = any(w in terrain for w in ["river", "lake", "canal", "water", "marsh", "tide", "ford", "waterway"])
    is_city = region_type == "city"
    is_town = region_type == "town"
    is_sect = region_type == "sect"
    is_snow = "snow" in terrain

    # Distant mountains/forest
    if is_mountain:
        for band in range(2):
            by = ground_top - h * (0.12 + band * 0.08)
            bh = h * (0.10 + band * 0.06)
            dim = 0.5 + band * 0.3
            c = rgba(round(top_sky[0] * dim), round(top_sky[1] * dim), round(top_sky[2] * dim), round(120 - band * 30))
            draw_mountain_band(draw, w, h, by, bh, c, f"mtn-{band}")
    elif is_forest:
        for band in range(2):
            by = ground_top - h * (0.10 + band * 0.06)
            bh = h * (0.08 + band * 0.04)
            green = rgba(round(accent[0] * 0.5), round(accent[1] * 0.7), round(accent[2] * 0.5), round(100 - band * 30))
            draw_mountain_band(draw, w, h, by, bh, green, f"forest-{band}")

    # Buildings for towns/cities
    if is_city or is_town:
        draw_building_row(draw, w, h, ground_top, 6, accent, 160, "buildings")
        draw_building_row(draw, w, h, ground_top - h * 0.08, 4, top_sky, 100, "bg-buildings")

    # Sect buildings
    if is_sect:
        draw_building_row(draw, w, h, ground_top, 3, accent, 200, "sect-buildings")
        # Gate
        gate_x = w // 2
        draw.rectangle(box(gate_x - 40, ground_top - 120, gate_x + 40, ground_top), fill=rgba(*accent, 200))
        draw.rectangle(box(gate_x - 25, ground_top - 65, gate_x + 25, ground_top), fill=rgba(0, 0, 0, 120))
        # Roof
        draw.polygon([(gate_x - 60, ground_top - 90), (gate_x, ground_top - 140), (gate_x + 60, ground_top - 90)],
                      fill=rgba(*accent, 220) if not is_snow else rgba(200, 195, 190, 220))
        if is_snow:
            draw.rectangle(box(0, ground_top, w, h), fill=rgba(200, 195, 190, 60))

    # Trees for forest/garden
    if is_forest or (is_town and not is_water):
        for i in range(8):
            x = rng.uniform(0, w)
            trunk_h = rng.uniform(80, 160)
            tw = max(2, rng.uniform(3, 6))
            draw.line([xy(x, ground_top), xy(x, ground_top - trunk_h)],
                       fill=rgba(80, 60, 40, round(rng.uniform(120, 200))), width=round(tw))
            crown_r = rng.uniform(24, 48)
            draw.ellipse(box(x - crown_r, ground_top - trunk_h - crown_r * 0.6, x + crown_r, ground_top - trunk_h + crown_r * 0.4),
                          fill=rgba(round(accent[0] * 0.6), round(accent[1] * 0.8), round(accent[2] * 0.6), round(rng.uniform(80, 160))))

    return img


def generate_foreground(size, terrain, accent, rng):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    is_water = any(w in terrain for w in ["river", "lake", "canal", "water", "marsh", "tide", "ford"])
    is_forest = any(w in terrain for w in ["forest", "bamboo", "garden"])
    is_snow = "snow" in terrain
    is_desert = "desert" in terrain
    is_mountain = any(w in terrain for w in ["mountain", "cliff", "pass", "gorge"])

    # Bottom edge darker
    draw.rectangle(box(0, h * 0.88, w, h), fill=rgba(*accent, 80))

    # Foreground trees
    if is_forest:
        for i in range(5):
            x = rng.uniform(-30, w + 30)
            trunk_h = rng.uniform(120, 200)
            tw = max(3, rng.uniform(4, 8))
            draw.line([xy(x, h), xy(x, h - trunk_h)], fill=rgba(50, 40, 30, round(rng.uniform(150, 220))), width=round(tw))
            crown_r = rng.uniform(30, 55)
            draw.ellipse(box(x - crown_r, h - trunk_h - crown_r * 0.5, x + crown_r, h - trunk_h + crown_r * 0.5),
                          fill=rgba(round(accent[0] * 0.5), round(accent[1] * 0.7), round(accent[2] * 0.5), round(rng.uniform(100, 180))))
    elif is_mountain:
        for i in range(3):
            x = rng.uniform(-20, w + 20)
            draw.line([xy(x, h), xy(x + rng.uniform(-10, 10), h - rng.uniform(100, 160))],
                       fill=rgba(*accent, round(rng.uniform(100, 160))), width=round(rng.uniform(4, 10)))
    elif is_desert:
        for i in range(8):
            x = rng.uniform(-20, w + 20)
            dh = rng.uniform(20, 50)
            draw.line([xy(x, h), xy(x + rng.uniform(-15, 15), h - dh)],
                       fill=rgba(*accent, round(rng.uniform(50, 120))), width=round(rng.uniform(2, 5)))

    # Corner vignette
    draw.rectangle(box(0, h * 0.94, w, h), fill=rgba(0, 0, 0, 80))
    draw.rectangle(box(0, 0, 8, h), fill=rgba(0, 0, 0, 60))
    draw.rectangle(box(w - 8, 0, w, h), fill=rgba(0, 0, 0, 60))

    return img


# ─── 主流程 ───────────────────────────────────────────

def generate_region_stage(region_id: str, terrain: str, region_type: str) -> dict:
    """为指定区域生成三层舞台背景，返回层路径字典"""
    palette = _lookup_palette(terrain)
    top_sky, bottom_sky, ground, accent, water_color = palette

    rng = random.Random(f"{SEED_BASE}-{region_id}")
    slug = f"{region_id}_batch_v1"

    floor_img = generate_floor(SIZE, terrain, accent, water_color, rng)
    mid_img = generate_midground(SIZE, terrain, accent, top_sky, region_type, rng)
    fore_img = generate_foreground(SIZE, terrain, accent, rng)

    # Sky background
    sky = vertical_gradient(SIZE, top_sky, bottom_sky)
    # Composite midground over sky
    sky.paste(mid_img, (0, 0), mid_img)
    mid_img = sky

    floor_path = LAYER_DIR / f"{slug}_floor.png"
    mid_path = LAYER_DIR / f"{slug}_midground.png"
    fore_path = LAYER_DIR / f"{slug}_foreground.png"

    LAYER_DIR.mkdir(parents=True, exist_ok=True)

    floor_img.save(floor_path, quality=OUTPUT_QUALITY)
    mid_img.save(mid_path, quality=OUTPUT_QUALITY)
    fore_img.save(fore_path, quality=OUTPUT_QUALITY)

    # Also generate scene background (瓦片图 + 天空 + 地面)
    scene_img = generate_scene_background(terrain, accent, top_sky, bottom_sky, rng)
    scene_path = SCENE_DIR / f"scene_{region_id}_batch_v1.png"
    SCENE_DIR.mkdir(parents=True, exist_ok=True)
    scene_img.save(scene_path, quality=OUTPUT_QUALITY)

    return {
        "floor": str(floor_path.relative_to(PROJECT)),
        "midground": str(mid_path.relative_to(PROJECT)),
        "foreground": str(fore_path.relative_to(PROJECT)),
        "scene": str(scene_path.relative_to(PROJECT)),
    }


def generate_scene_background(terrain, accent, top_sky, bottom_sky, rng):
    """生成场景背景图（天空+远景+地面）"""
    w, h = SCENE_SIZE
    img = Image.new("RGBA", SCENE_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Sky gradient
    for y in range(h):
        t = y / max(1, h - 1)
        r = round(top_sky[0] + (bottom_sky[0] - top_sky[0]) * t)
        g = round(top_sky[1] + (bottom_sky[1] - top_sky[1]) * t)
        b = round(top_sky[2] + (bottom_sky[2] - top_sky[2]) * t)
        draw.line([(0, y), (w, y)], fill=rgba(r, g, b, 255))

    ground_top = h * 0.52
    is_water = any(w in terrain for w in ["river", "lake", "canal", "water", "marsh", "tide"])
    is_snow = "snow" in terrain
    is_desert = "desert" in terrain

    # Distant mountains
    for band in range(3):
        by = ground_top - h * (0.20 + band * 0.08)
        bh = h * (0.08 + band * 0.04)
        dim = 0.3 + band * 0.25
        c = rgba(round(top_sky[0] * dim), round(top_sky[1] * dim), round(top_sky[2] * dim), 255)
        draw_mountain_band(draw, w, h, by, bh, c, f"scene-mtn-{band}")

    # Ground
    if is_water:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(*accent, 255))
        for i in range(20):
            y = ground_top + rng.uniform(0, h - ground_top)
            draw.line([(0, y), (w, y + rng.uniform(-8, 8))], fill=rgba(*accent, round(rng.uniform(20, 60))), width=1)
    elif is_snow:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(210, 205, 200, 255))
    elif is_desert:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(*accent, 255))
    else:
        draw.rectangle(box(0, ground_top, w, h), fill=rgba(*accent, 255))
        for i in range(20):
            y = ground_top + rng.uniform(0, h - ground_top)
            draw.line([(0, y), (w, y)], fill=rgba(*accent, round(rng.uniform(20, 40))), width=rng.randint(1, 2))

    # Clouds
    for i in range(6):
        cx = rng.uniform(0, w)
        cy = rng.uniform(20, h * 0.25)
        cr = rng.uniform(40, 100)
        c_alpha = round(rng.uniform(60, 130))
        draw.ellipse(box(cx - cr, cy - cr * 0.4, cx + cr, cy + cr * 0.4),
                      fill=rgba(255, 255, 255, c_alpha))

    return img


def main():
    # Load regions
    with open(DATA_DIR / "regions.json") as f:
        regions_raw = json.load(f)
    regions = list(regions_raw.values()) if isinstance(regions_raw, dict) else regions_raw

    # Load existing stage layers
    stage_path = DATA_DIR / "stage_layer_assets.json"
    with open(stage_path) as f:
        stage_assets = json.load(f)
    if not isinstance(stage_assets, dict):
        stage_assets = {}

    existing = set(stage_assets.keys())
    total = len(regions)
    missing = [r for r in regions if r["id"] not in existing]

    print(f"总区域: {total}")
    print(f"已有横版舞台: {len(existing)}")
    print(f"需要生成: {len(missing)}")
    print()

    # Load existing scene background assets
    scene_assets_path = DATA_DIR / "scene_background_assets.json"
    with open(scene_assets_path) as f:
        scene_assets = json.load(f)
    if not isinstance(scene_assets, dict):
        scene_assets = {}

    generated = []
    for i, region in enumerate(missing):
        rid = region["id"]
        terrain = region.get("terrain", "plain")
        rtype = region.get("type", "wild")
        name = region.get("name", rid)

        print(f"[{i+1}/{len(missing)}] 生成 {name} ({rid}) - {terrain}")
        try:
            result = generate_region_stage(rid, terrain, rtype)
            # Convert to res:// paths
            res_paths = {
                "floor": "res://" + result["floor"],
                "midground": "res://" + result["midground"],
                "foreground": "res://" + result["foreground"],
            }
            stage_assets[rid] = res_paths
            # Also update scene background
            scene_assets[rid] = "res://" + result["scene"]
            generated.append(rid)
            print(f"  ✅ 完成")
        except Exception as e:
            import traceback
            print(f"  ❌ 失败: {e}")
            traceback.print_exc()

    # Save updated stage_layer_assets.json
    with open(stage_path, "w", encoding="utf-8") as f:
        json.dump(stage_assets, f, indent=2, ensure_ascii=False)

    # Save updated scene_background_assets.json
    with open(scene_assets_path, "w", encoding="utf-8") as f:
        json.dump(scene_assets, f, indent=2, ensure_ascii=False)

    print(f"\n✅ 成功生成 {len(generated)}/{len(missing)} 个区域")
    if generated:
        print("生成区域:", ", ".join(generated))

    # Print summary statistics
    total_images = len(generated) * 3
    print(f"总共生成 {total_images} 个 PNG 文件")

    # Check file sizes
    small_files = []
    for rid in generated:
        for layer in ["floor", "midground", "foreground"]:
            path_str = stage_assets.get(rid, {}).get(layer, "")
            if path_str:
                path = Path(str(path_str).replace("res://", str(PROJECT) + "/"))
                if path.exists():
                    size_kb = path.stat().st_size / 1024
                    if size_kb < 5:
                        small_files.append((rid, layer, size_kb))

    if small_files:
        print("\n⚠️ 小文件警告（可能生成有误）:")
        for rid, layer, size in small_files[:10]:
            print(f"  {rid}/{layer}: {size:.1f}KB")


if __name__ == "__main__":
    main()