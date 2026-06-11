#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge, draw_tea_hut
from generate_beiling_mountain_stage_assets import SIZE, add_glow, box, draw_rock, polygon, rgba, save, vertical_gradient, xy
from generate_linan_dnf_water_city_stage_assets import draw_boat
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern
from generate_minjiang_river_stage_assets import draw_rope_bridge
from generate_three_gorges_stage_assets import draw_cliff_plank_path, draw_cliff_wall, draw_rapid_river, draw_spray_band


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_yiling_gap_dnf_canyon_gate_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "yiling_gap_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "yiling_gap_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "yiling_gap_dnf_foreground_v1.png"


def draw_waterfall_curtain(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.polygon(
        polygon([(x + w * 0.20, y), (x + w * 0.74, y + h * 0.02), (x + w * 0.86, y + h * 0.86), (x + w * 0.10, y + h * 0.96), (x + w * 0.08, y + h * 0.26)]),
        fill=rgba(118, 206, 198, round(alpha * 0.32)),
    )
    for _ in range(22):
        sx = x + w * rng.uniform(0.16, 0.76)
        ld.line([xy(sx, y + rng.uniform(0, h * 0.04)), xy(sx + rng.uniform(-18, 20), y + h * rng.uniform(0.74, 0.98))], fill=rgba(224, 250, 232, rng.randint(34, 92)), width=rng.randint(1, 3))
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(2)))
    draw.ellipse(box(x - w * 0.24, y + h * 0.84, x + w * 1.24, y + h * 1.12), fill=rgba(42, 116, 112, round(alpha * 0.36)), outline=rgba(214, 240, 220, round(alpha * 0.28)), width=2)


def draw_hidden_valley_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x + w * 0.02, y + h * 0.74, x + w * 0.98, y + h * 1.08), fill=rgba(0, 0, 0, 52))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x, y + h), (x + w * 0.10, y + h * 0.36), (x + w * 0.50, y), (x + w * 0.92, y + h * 0.35), (x + w, y + h), (x + w * 0.72, y + h * 1.04), (x + w * 0.24, y + h * 1.05)]),
        fill=rgba(70, 72, 56, alpha),
        outline=rgba(24, 22, 18, round(alpha * 0.82)),
    )
    draw.ellipse(box(x + w * 0.30, y + h * 0.42, x + w * 0.72, y + h * 1.02), fill=rgba(18, 22, 18, round(alpha * 0.84)))
    draw.rectangle(box(x + w * 0.25, y + h * 0.28, x + w * 0.76, y + h * 0.36), fill=rgba(82, 54, 30, round(alpha * 0.72)), outline=rgba(206, 166, 92, round(alpha * 0.44)), width=2)
    for px in (x + w * 0.24, x + w * 0.76):
        draw.line([xy(px, y + h * 0.44), xy(px, y + h * 1.03)], fill=rgba(76, 50, 28, round(alpha * 0.84)), width=5)


def draw_mine_ore_vein(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int) -> None:
    for i, ox in enumerate((-36, -12, 18, 42)):
        color = rgba(82, 86, 78, round(alpha * (0.88 + i * 0.02)))
        draw.polygon(
            polygon([(x + ox * scale, y + 28 * scale), (x + (ox - 16) * scale, y - 18 * scale), (x + (ox + 8) * scale, y - 42 * scale), (x + (ox + 25) * scale, y + 20 * scale)]),
            fill=color,
            outline=rgba(26, 28, 24, round(alpha * 0.68)),
        )
        draw.line([xy(x + (ox - 5) * scale, y - 18 * scale), xy(x + (ox + 16) * scale, y + 10 * scale)], fill=rgba(180, 174, 126, 56), width=max(1, round(2 * scale)))


def draw_ambush_watch_shed(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.05, y + h * 0.78, x + w * 0.96, y + h * 1.08), fill=rgba(0, 0, 0, 48))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    for px in (x + w * 0.22, x + w * 0.70):
        draw.line([xy(px, y + h * 0.56), xy(px - w * 0.03, y + h * 1.02)], fill=rgba(46, 28, 14, round(alpha * 0.86)), width=5)
    draw.rectangle(box(x + w * 0.12, y + h * 0.44, x + w * 0.84, y + h * 0.72), fill=rgba(92, 60, 34, alpha), outline=rgba(24, 14, 8, round(alpha * 0.86)), width=2)
    draw.polygon(polygon([(x, y + h * 0.46), (x + w * 0.46, y + h * 0.12), (x + w * 0.96, y + h * 0.44), (x + w * 0.86, y + h * 0.58), (x + w * 0.08, y + h * 0.60)]), fill=rgba(70, 58, 38, alpha), outline=rgba(22, 14, 8, alpha))
    draw_flag(draw, x + w * 0.90, y + h * 0.70, 0.58, 1.0, (118, 72, 42), round(alpha * 0.80))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("yiling-gap-floor-v1")
    river_top = h * 0.480
    draw_rapid_river(draw, w * 0.12, river_top, w * 0.76, h * 0.310, 150, "yiling-narrow-rapid")
    path_top = h * 0.612
    draw.polygon(polygon([(w * -0.04, path_top), (w * 0.35, path_top - h * 0.055), (w * 1.06, h + 26), (w * -0.06, h + 28)]), fill=rgba(122, 108, 76, 116), outline=rgba(46, 34, 24, 76))
    draw.polygon(polygon([(w * 0.58, path_top - h * 0.020), (w * 1.04, path_top + h * 0.020), (w * 1.08, h + 24), (w * 0.74, h + 24)]), fill=rgba(100, 94, 70, 86), outline=rgba(38, 32, 24, 60))
    draw_plank_bridge(draw, image, w * 0.38, h * 0.582, w * 0.26, h * 0.060, 150)
    for row in range(18):
        t = row / 17.0
        y = path_top + (t * t) * h * 0.36
        draw.line([xy(w * (-0.02 - t * 0.09), y), xy(w * (0.48 + t * 0.50), y - h * 0.024)], fill=rgba(216, 196, 128, 24 + row * 3), width=max(1, round(1.5 + t * 2.4)))
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.66 + t * 0.25)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(214, 232, 172, 9 + lane * 3))
    for _ in range(190):
        x = rng.uniform(w * 0.02, w * 0.99)
        y = rng.uniform(path_top + 8, h * 0.99)
        if rng.random() < 0.44:
            draw_rock(draw, x, y - 15, rng.uniform(16, 42), rng.uniform(10, 26), rng.randint(36, 86), (152, 146, 106))
        else:
            length = rng.uniform(12, 56)
            angle = rng.uniform(-0.34, 0.22)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.38)], fill=rgba(48, 82, 36, rng.randint(20, 66)), width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_cliff_wall(draw, w * -0.07, h * 0.205, w * 0.32, h * 0.435, 172, "yiling-left-sliced-cliff")
    draw_cliff_wall(draw, w * 0.76, h * 0.205, w * 0.33, h * 0.435, 168, "yiling-right-sliced-cliff", True)
    image.alpha_composite(draw_spray_band(size, h * 0.402, h * 0.130, "yiling-mid-spray", 42))
    draw_waterfall_curtain(draw, image, w * 0.57, h * 0.250, w * 0.115, h * 0.260, 128, "yiling-waterfall")
    draw_hidden_valley_gate(draw, image, w * 0.14, h * 0.320, w * 0.18, h * 0.205, 164)
    draw_ambush_watch_shed(draw, image, w * 0.70, h * 0.332, w * 0.15, h * 0.180, 150)
    draw_mine_ore_vein(draw, w * 0.80, h * 0.510, 0.80, 120)
    draw_cliff_plank_path(draw, image, w * 0.10, h * 0.445, w * 0.28, h * 0.070, 154)
    draw_rope_bridge(draw, image, w * 0.41, h * 0.505, w * 0.24, h * 0.084, 142)
    draw_tea_hut(draw, image, w * 0.34, h * 0.315, w * 0.15, h * 0.170, 130)
    for x, y, scale, count, seed in (
        (w * 0.08, h * 0.520, 0.60, 8, "yiling-bamboo-left"),
        (w * 0.90, h * 0.520, 0.62, 9, "yiling-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 118, seed)
    for x, side in ((w * 0.22, -1.0), (w * 0.51, 1.0), (w * 0.80, -1.0)):
        draw_flag(draw, x, h * 0.495, 0.70, side, (102, 90, 58), 136)
    for x in (w * 0.16, w * 0.43, w * 0.74):
        draw_lantern(draw, image, x, h * 0.485, 0.43)
    draw_boat(draw, image, w * 0.28, h * 0.585, 0.76, 138)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("yiling-gap-foreground-v1")
    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(10, 12, 8, 98))
    draw_rock(draw, -w * 0.05, h * 0.780, w * 0.24, h * 0.210, 218, (158, 152, 112))
    draw_rock(draw, w * 0.80, h * 0.780, w * 0.24, h * 0.210, 216, (158, 152, 112))
    for x0, x1, y in ((w * 0.00, w * 0.31, h * 0.858), (w * 0.64, w * 0.99, h * 0.844)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(60, 40, 24, 216), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(28, 20, 12, 172), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(38, 24, 14, 220), width=5)
    for _ in range(118):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        color = rgba(46, 96, 42, rng.randint(42, 112)) if rng.random() < 0.72 else rgba(112, 94, 56, rng.randint(40, 98))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    for i in range(9):
        x = w * (0.30 + i * 0.046)
        y = h * (0.910 + (i % 3) * 0.012)
        draw.rectangle(box(x - 16, y - 18, x + 20, y + 17), fill=rgba(70, 48, 28, 126), outline=rgba(28, 18, 12, 118), width=2)
    image.alpha_composite(draw_spray_band(size, h * 0.835, h * 0.150, "yiling-front-spray", 46))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (126, 148, 132), (66, 78, 56))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.55, h * 0.135), h * 0.200, (232, 216, 142), 30)
    draw_mountain_band(draw, w, h, h * 0.335, h * 0.300, rgba(56, 76, 70, 72), "yiling-far")
    draw_mountain_band(draw, w, h, h * 0.455, h * 0.285, rgba(42, 58, 52, 104), "yiling-mid")
    draw_mountain_band(draw, w, h, h * 0.555, h * 0.245, rgba(32, 40, 32, 126), "yiling-near")
    image.alpha_composite(draw_spray_band(size, h * 0.285, h * 0.100, "yiling-sky-spray", 34))
    rng = random.Random("yiling-gap-scene-v1")
    for _ in range(96):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.72)
        length = rng.uniform(5, 15)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(158, 188, 112, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 62))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 32))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Yiling gap DNF canyon gate stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
