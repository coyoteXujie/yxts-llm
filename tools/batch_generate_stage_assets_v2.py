#!/usr/bin/env python3
"""
v2 批量生成横版舞台背景资产
大幅提升画质细节：多层远景、建筑轮廓、植被细节、地表纹理
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

W, H = 1672, 941
SEED_BASE = "batch-gen-v2"

# ─── 地形调色板 ───
# (sky_top, sky_bot, ground, accent, water, building)
PALETTES = {
    "plain":     ((182,202,218),(132,152,168),(148,128,78),(108,90,50),(60,120,130),(100,80,55)),
    "field":     ((192,210,205),(145,165,145),(160,145,75),(120,108,48),(55,115,110),(105,90,50)),
    "town":      ((188,200,208),(140,148,152),(140,115,78),(100,80,48),(55,110,115),(108,85,52)),
    "city":      ((182,196,206),(135,142,148),(135,110,75),(95,75,45),(55,110,115),(115,90,55)),
    "water":     ((168,192,215),(115,148,172),(118,98,68),(82,65,38),(42,108,135),(90,75,48)),
    "river":     ((165,190,212),(110,140,165),(112,92,62),(78,60,36),(38,105,138),(88,72,45)),
    "lake":      ((160,188,212),(105,138,165),(108,88,58),(75,58,34),(35,100,138),(85,70,42)),
    "mountain":  ((155,170,190),(105,120,140),(110,90,60),(78,58,34),(45,95,108),(85,68,42)),
    "cliff":     ((148,165,185),(98,115,135),(105,85,58),(72,52,30),(42,90,102),(80,65,38)),
    "forest":    ((175,200,190),(125,155,135),(108,118,55),(70,85,30),(42,98,102),(88,80,38)),
    "bamboo":    ((180,205,190),(130,160,135),(112,120,55),(75,88,30),(48,102,108),(90,82,40)),
    "desert":    ((215,195,165),(178,155,120),(170,138,78),(138,108,50),(55,98,108),(120,95,55)),
    "snow":      ((208,212,222),(175,185,200),(165,158,152),(132,126,120),(95,125,145),(140,130,120)),
    "sect":      ((178,190,200),(128,138,148),(125,105,72),(92,72,42),(50,100,112),(110,85,50)),
    "marsh":     ((168,188,178),(118,142,132),(105,108,58),(72,78,32),(40,95,95),(85,80,42)),
    "garden":    ((188,205,190),(142,162,138),(128,120,65),(92,88,38),(50,108,112),(100,90,48)),
    "valley":    ((158,178,195),(108,128,145),(112,92,65),(80,62,38),(42,95,112),(88,72,42)),
    "spring":    ((188,205,210),(142,162,168),(135,115,75),(102,82,48),(50,110,120),(105,85,50)),
    "pass":      ((155,172,188),(105,122,140),(110,90,62),(78,58,34),(45,92,108),(85,68,40)),
    "canal":     ((168,195,210),(115,148,165),(115,95,68),(82,65,38),(42,108,135),(92,76,46)),
    "gorge":     ((140,158,178),(90,108,128),(100,82,58),(68,50,30),(36,85,105),(80,65,38)),
    "mound":     ((188,195,190),(142,148,138),(135,112,72),(102,82,44),(48,100,108),(102,85,48)),
    "ford":      ((175,195,205),(125,148,162),(120,102,70),(88,72,40),(42,108,128),(95,78,46)),
    "tide":      ((165,190,210),(110,140,165),(110,90,62),(78,60,36),(38,105,140),(88,72,44)),
    "waterway":  ((166,192,212),(112,142,168),(112,92,64),(80,62,36),(40,106,138),(88,72,44)),
    "bath":      ((188,202,208),(145,158,165),(138,118,78),(105,85,48),(52,112,124),(108,88,52)),
    "shadow_sect":((135,135,150),(85,85,100),(82,72,56),(56,46,30),(36,76,86),(70,58,42)),
    "daoist_sect":((178,195,200),(132,148,155),(125,108,72),(92,78,44),(50,102,112),(105,85,50)),
    "snow_sect": ((208,212,222),(175,185,200),(165,158,152),(132,126,120),(95,125,145),(140,130,120)),
    "lake_palace":((175,195,215),(125,148,175),(118,102,70),(88,72,42),(45,108,130),(100,82,48)),
    "water_town":((175,195,212),(122,148,168),(118,98,68),(85,68,40),(42,108,135),(95,80,48)),
    "starter_town":((188,200,208),(140,148,152),(140,115,78),(100,80,48),(55,110,115),(108,85,52)),
    "river_valley":((155,178,195),(105,128,145),(110,90,62),(78,58,36),(40,98,118),(88,72,42)),
}

def rgba(r,g,b,a=255): return (max(0,min(255,r)),max(0,min(255,g)),max(0,min(255,b)),max(0,min(255,a)))
def xy(x,y): return (round(x),round(y))
def box(x0,y0,x1,y1): return (round(x0),round(y0),round(x1),round(y1))

def get_palette(terrain: str):
    for key, p in PALETTES.items():
        if key in terrain:
            return p
    return PALETTES["plain"]

def draw_sky(draw, top, bot):
    for y in range(H):
        t = y / max(1, H-1)
        draw.line([(0,y),(W,y)], fill=rgba(
            round(top[0]+(bot[0]-top[0])*t),
            round(top[1]+(bot[1]-top[1])*t),
            round(top[2]+(bot[2]-top[2])*t), 255))

def draw_mountains(draw, base_y, height, color, rng, seed):
    pts = [(0, base_y + height*0.3)]
    steps = 20
    for i in range(steps+1):
        x = W * i / steps
        y = base_y - height * (0.3 + rng.random()*0.5) + math.sin(i*1.37 + hash(seed)*0.01)*height*0.06
        pts.append((x, y))
    pts.append((W, base_y + height*0.3))
    draw.polygon([(round(px),round(py)) for px,py in pts], fill=color)

def draw_tree(draw, x, y, h, r, trunk_color, crown_color, alpha):
    tw = max(2, round(r*0.5))
    draw.line([xy(x,y), xy(x, y-h)], fill=rgba(*trunk_color, round(alpha*0.8)), width=tw)
    draw.ellipse(box(x-r, y-h-r*0.6, x+r, y-h+r*0.4), fill=rgba(*crown_color, round(alpha*0.85)))

def draw_building(draw, x, y, w, h, color, alpha, rng):
    draw.rectangle(box(x-w//2, y-h, x+w//2, y), fill=rgba(*color, round(alpha*0.9)))
    roof_w = int(w*0.75)
    draw.polygon([(x-roof_w, y-h*0.88), (x, y-h*1.18), (x+roof_w, y-h*0.88)], fill=rgba(*color, round(alpha*0.85)))
    # window
    win_w = max(4, w//5)
    draw.rectangle(box(x-win_w, y-h*0.55, x+win_w, y-h*0.38), fill=rgba(*color, round(alpha*0.6)))

def draw_cloud(draw, x, y, w, h, alpha, rng):
    c = rgba(255,255,255,round(alpha))
    draw.ellipse(box(x-w*0.5, y-h*0.4, x+w*0.5, y+h*0.4), fill=c)
    draw.ellipse(box(x-w*0.3, y-h*0.5, x+w*0.3, y+h*0.35), fill=c)

# ─── 地面层 ───
def gen_floor(terrain, palette, rng):
    sky_top, sky_bot, ground, accent, water_c, build_c = palette
    img = Image.new("RGBA", (W,H), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    gtop = int(H * 0.52)
    is_water = any(w in terrain for w in ("river","lake","canal","water","marsh","tide","ford","waterway"))
    is_snow = "snow" in terrain
    is_desert = "desert" in terrain

    # Sky
    draw_sky(draw, sky_top, sky_bot)

    # Clouds (2-3 layers)
    for i in range(8):
        cx = rng.uniform(-100, W+100)
        cy = rng.uniform(20, H*0.22)
        cw = rng.uniform(80, 180)
        ch = cw * 0.35
        ca = rng.uniform(40, 100)
        draw_cloud(draw, cx, cy, cw, ch, ca, rng)

    # Distant mountains (3 bands)
    for band in range(3):
        by = gtop - H * (0.18 + band * 0.06)
        bh = H * (0.06 + band * 0.03)
        dim = 0.25 + band * 0.22
        c = rgba(round(sky_top[0]*dim), round(sky_top[1]*dim), round(sky_top[2]*dim), 255)
        draw_mountains(draw, by, bh, c, rng, f"mtn-{band}")

    # Ground
    if is_water:
        # Water surface
        draw.rectangle(box(0, gtop, W, H), fill=rgba(*water_c, 255))
        # Waves
        for i in range(60):
            y = gtop + rng.uniform(0, H-gtop)
            alpha = rng.uniform(20, 55)
            ww = rng.uniform(30, 80)
            draw.line([(rng.uniform(0, W), y), (rng.uniform(0, W), y+rng.uniform(-4,4))],
                       fill=rgba(*water_c, round(alpha)), width=rng.randint(1,2))
        # Sparkle
        for i in range(20):
            x = rng.uniform(0, W)
            y = gtop + rng.uniform(0, H-gtop)
            draw.ellipse(box(x-2, y-1, x+2, y+1), fill=rgba(255,255,255,round(rng.uniform(30,80))))
    elif is_snow:
        draw.rectangle(box(0, gtop, W, H), fill=rgba(215,210,205,255))
        for i in range(30):
            y = gtop + rng.uniform(0, H-gtop)
            draw.line([(0, y), (W, y+rng.uniform(-3,3))], fill=rgba(225,220,215,round(rng.uniform(30,70))), width=rng.randint(2,5))
    elif is_desert:
        draw.rectangle(box(0, gtop, W, H), fill=rgba(*ground, 255))
        for i in range(50):
            y = gtop + rng.uniform(0, H-gtop)
            draw.line([(0, y), (W, y+rng.uniform(-8,8))], fill=rgba(*accent, round(rng.uniform(15,35))), width=rng.randint(1,2))
        # Dune highlights
        for i in range(15):
            y = gtop + rng.uniform(0, H-gtop)
            hw = rng.uniform(40, 120)
            draw.line([(rng.uniform(0, W), y), (rng.uniform(0, W)+hw, y-rng.uniform(6,14))],
                       fill=rgba(235,215,180,round(rng.uniform(15,35))), width=2)
    else:
        # Grass/earth ground
        draw.rectangle(box(0, gtop, W, H), fill=rgba(*ground, 255))
        for i in range(60):
            y = gtop + rng.uniform(0, H-gtop)
            draw.line([(0, y), (W, y)], fill=rgba(*accent, round(rng.uniform(12,30))), width=rng.randint(1,3))
        # Path
        for i in range(15):
            y = gtop + (H-gtop)*i/14
            pw = rng.uniform(80, 200)
            draw.line([(W//2-pw, y), (W//2+pw, y+rng.uniform(-5,5))],
                       fill=rgba(*accent, round(rng.uniform(20,45))), width=3)

    # Docks/piers for water regions
    if is_water:
        for i in range(3):
            x = rng.uniform(100, W-100)
            draw.rectangle(box(x-8, gtop-20, x+8, gtop+60), fill=rgba(82,52,27,180))
            draw.line([(x-18, gtop+55), (x+18, gtop+55)], fill=rgba(62,38,18,200), width=6)

    # Foreground trees on edges
    for i in range(6):
        x = rng.uniform(-40, W+40)
        if x < 80 or x > W-80:
            th = rng.uniform(120, 200)
            draw_tree(draw, x, H, th, rng.uniform(20, 32),
                      (60, 45, 30), (50, 85, 45), rng.uniform(120, 180))

    # Bottom edge darken
    draw.rectangle(box(0, H-80, W, H), fill=rgba(0,0,0,45))
    return img

# ─── 中景层 ───
def gen_midground(terrain, palette, rtype, rng):
    sky_top, sky_bot, ground, accent, water_c, build_c = palette
    img = Image.new("RGBA", (W,H), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    gtop = int(H * 0.52)
    is_water = any(w in terrain for w in ("river","lake","canal","water","marsh","tide","ford","waterway"))
    is_mountain = any(w in terrain for w in ("mountain","cliff","pass","gorge","valley"))
    is_forest = any(w in terrain for w in ("forest","bamboo","garden"))
    is_city = rtype in ("city","town")
    is_sect = rtype == "sect"
    is_snow = "snow" in terrain

    # Mid-ground mountains
    if is_mountain or is_snow:
        for band in range(3):
            by = gtop - H * (0.10 + band * 0.08)
            bh = H * (0.08 + band * 0.05)
            dim = 0.4 + band * 0.25
            c = rgba(round(accent[0]*dim), round(accent[1]*dim), round(accent[2]*dim), round(180-band*30))
            draw_mountains(draw, by, bh, c, rng, f"mg-mtn-{band}")

    # Forest canopy for forest regions
    if is_forest:
        for band in range(2):
            by = gtop - H * (0.08 + band * 0.05)
            bh = H * (0.06 + band * 0.04)
            c = rgba(round(ground[0]*0.5), round(ground[1]*0.7), round(ground[2]*0.5), round(140-band*40))
            draw_mountains(draw, by, bh, c, rng, f"mg-forest-{band}")
        # Trees
        for i in range(12):
            x = rng.uniform(20, W-20)
            th = rng.uniform(90, 160)
            draw_tree(draw, x, gtop+5, th, rng.uniform(22, 38),
                      (70, 55, 35), (55, 95, 48), rng.uniform(100, 180))

    # Buildings for cities/towns
    if is_city:
        for i in range(10):
            x = rng.uniform(40, W-40)
            bw = rng.uniform(50, 90)
            bh = rng.uniform(70, 130)
            draw_building(draw, x, gtop, bw, bh, build_c, rng.uniform(140, 200), rng)

    # Sect buildings
    if is_sect:
        # Main hall
        cx = W // 2
        draw_building(draw, cx, gtop, 120, 160, build_c, 220, rng)
        # Side buildings
        for i in range(4):
            x = cx + (-1 if i < 2 else 1) * rng.uniform(120, 220)
            bw = rng.uniform(50, 80)
            bh = rng.uniform(80, 110)
            draw_building(draw, x, gtop, bw, bh, build_c, rng.uniform(140, 180), rng)
        # Gate
        gw, gh = 60, 100
        draw.rectangle(box(cx-gw//2, gtop-gh, cx+gw//2, gtop), fill=rgba(*build_c, 200))
        draw.rectangle(box(cx-18, gtop-50, cx+18, gtop), fill=rgba(0,0,0,140))
        draw.polygon([(cx-50, gtop-gh*0.85), (cx, gtop-gh*1.15), (cx+50, gtop-gh*0.85)],
                      fill=rgba(*build_c, 180))

    # Snow caps for snow regions
    if is_snow:
        draw.rectangle(box(0, gtop, W, H), fill=rgba(200,195,190,45))

    return img

# ─── 前景层 ───
def gen_foreground(terrain, palette, rng):
    sky_top, sky_bot, ground, accent, water_c, build_c = palette
    img = Image.new("RGBA", (W,H), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    gtop = int(H * 0.52)
    is_forest = any(w in terrain for w in ("forest","bamboo","garden"))
    is_mountain = any(w in terrain for w in ("mountain","cliff","pass","gorge"))
    is_desert = "desert" in terrain

    # Foreground trees
    if is_forest:
        for i in range(6):
            x = rng.uniform(-60, W+60)
            if x < 100 or x > W-100 or i < 2:
                th = rng.uniform(140, 220)
                draw_tree(draw, x, H, th, rng.uniform(28, 42),
                          (50, 38, 28), (45, 78, 40), rng.uniform(120, 180))

    # Mountain rocks
    if is_mountain:
        for i in range(4):
            x = rng.uniform(-30, W+30)
            rh = rng.uniform(80, 150)
            rw = rng.uniform(40, 80)
            draw.polygon([(x, H), (x-rw//2, H-rh), (x+rw//2, H-rh*0.7)],
                          fill=rgba(*accent, round(rng.uniform(100, 160))))

    # Desert foreground dunes
    if is_desert:
        for i in range(4):
            x = rng.uniform(-40, W+40)
            dh = rng.uniform(30, 60)
            dw = rng.uniform(80, 150)
            draw.polygon([(x-dw, H), (x, H-dh), (x+dw, H)],
                          fill=rgba(*accent, round(rng.uniform(60, 120))))

    # Bottom vignette
    draw.rectangle(box(0, H-100, W, H), fill=rgba(0,0,0,55))
    draw.rectangle(box(0, 0, 12, H), fill=rgba(0,0,0,40))
    draw.rectangle(box(W-12, 0, W, H), fill=rgba(0,0,0,40))
    # Top vignette
    draw.rectangle(box(0, 0, W, 8), fill=rgba(0,0,0,35))

    return img

# ─── 场景背景 ───
def gen_scene(terrain, palette, rng):
    sky_top, sky_bot, ground, accent, water_c, build_c = palette
    img = Image.new("RGBA", (W,H), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Sky
    draw_sky(draw, sky_top, sky_bot)

    # Clouds
    for i in range(8):
        cx = rng.uniform(-50, W+50)
        cy = rng.uniform(20, H*0.22)
        draw_cloud(draw, cx, cy, rng.uniform(80, 200), rng.uniform(25, 60), rng.uniform(50, 100), rng)

    # Mountains
    gtop = int(H * 0.52)
    for band in range(3):
        by = gtop - H * (0.22 + band * 0.07)
        bh = H * (0.07 + band * 0.04)
        dim = 0.2 + band * 0.2
        c = rgba(round(sky_top[0]*dim), round(sky_top[1]*dim), round(sky_top[2]*dim), 255)
        draw_mountains(draw, by, bh, c, rng, f"sc-mtn-{band}")

    # Ground
    draw.rectangle(box(0, gtop, W, H), fill=rgba(*ground, 255))
    for i in range(30):
        y = gtop + rng.uniform(0, H-gtop)
        draw.line([(0, y), (W, y)], fill=rgba(*accent, round(rng.uniform(10, 25))), width=1)

    return img

def generate(region_id, terrain, rtype):
    palette = get_palette(terrain)
    rng = random.Random(f"{SEED_BASE}-{region_id}")

    floor = gen_floor(terrain, palette, rng)
    mid = gen_midground(terrain, palette, rtype, rng)
    fore = gen_foreground(terrain, palette, rng)
    scene = gen_scene(terrain, palette, rng)

    LAYER_DIR.mkdir(parents=True, exist_ok=True)
    SCENE_DIR.mkdir(parents=True, exist_ok=True)
    slug = f"{region_id}_v2"

    floor.save(LAYER_DIR / f"{slug}_floor.png", quality=98)
    mid.save(LAYER_DIR / f"{slug}_midground.png", quality=98)
    fore.save(LAYER_DIR / f"{slug}_foreground.png", quality=98)
    scene.save(SCENE_DIR / f"scene_{region_id}_v2.png", quality=98)

    return {
        "floor": f"res://assets/world/stage_layers/{slug}_floor.png",
        "midground": f"res://assets/world/stage_layers/{slug}_midground.png",
        "foreground": f"res://assets/world/stage_layers/{slug}_foreground.png",
    }

def main():
    with open(DATA_DIR/"regions.json") as f:
        rs = json.load(f)
    regions = list(rs.values()) if isinstance(rs, dict) else rs

    with open(DATA_DIR/"stage_layer_assets.json") as f:
        stages = json.load(f)
    if not isinstance(stages, dict):
        stages = {}

    with open(DATA_DIR/"scene_background_assets.json") as f:
        scenes = json.load(f)
    if not isinstance(scenes, dict):
        scenes = {}

    # Replace batch_v1 entries with v2
    counts = {"generated": 0, "skipped_has_dnf": 0}
    for region in regions:
        rid = region["id"]
        existing = stages.get(rid, {})
        # Skip if already has DNF-style (hand-crafted) assets
        if isinstance(existing, dict):
            floor = existing.get("floor", "")
            if floor and "_dnf_" in floor:
                counts["skipped_has_dnf"] += 1
                continue

        terrain = region.get("terrain", "plain")
        rtype = region.get("type", "wild")
        name = region.get("name", rid)

        print(f"  [{counts['generated']+1}] {name} ({rid}) - {terrain}")

        try:
            paths = generate(rid, terrain, rtype)
            stages[rid] = paths
            scenes[rid] = f"res://assets/world/scenes/scene_{rid}_v2.png"
            counts["generated"] += 1
        except Exception as e:
            import traceback; traceback.print_exc()
            print(f"    ❌ {e}")

    with open(DATA_DIR/"stage_layer_assets.json", "w") as f:
        json.dump(stages, f, indent=2, ensure_ascii=False)
    with open(DATA_DIR/"scene_background_assets.json", "w") as f:
        json.dump(scenes, f, indent=2, ensure_ascii=False)

    print(f"\n生成: {counts['generated']}, 跳过(DNF手绘): {counts['skipped_has_dnf']}")

    # Size stats
    sizes = []
    for f in sorted(LAYER_DIR.glob("*_v2_*.png")):
        sizes.append(f.stat().st_size / 1024)
    if sizes:
        print(f"v2 平均: {sum(sizes)/len(sizes):.0f}KB, 范围: {min(sizes):.0f}KB-{max(sizes):.0f}KB")

if __name__ == "__main__":
    main()