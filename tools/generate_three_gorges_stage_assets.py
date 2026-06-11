#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge, draw_tea_hut
from generate_beiling_mountain_stage_assets import SIZE, box, draw_rock, polygon, rgba, save, vertical_gradient, xy
from generate_linan_dnf_water_city_stage_assets import add_glow, draw_boat, draw_willow
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern
from generate_minjiang_river_stage_assets import draw_ferry_pier, draw_rope_bridge


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_three_gorges_dnf_rapids_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "three_gorges_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "three_gorges_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "three_gorges_dnf_foreground_v1.png"


def draw_spray_band(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(24):
        cx = rng.uniform(-w * 0.04, w * 1.04)
        cy = y + rng.uniform(-height * 0.36, height * 0.36)
        rx = rng.uniform(w * 0.035, w * 0.115)
        ry = rng.uniform(height * 0.18, height * 0.46)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(220, 238, 222, rng.randint(round(alpha * 0.35), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.16))))


def draw_cliff_wall(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str, flipped: bool = False) -> None:
    rng = random.Random(seed)
    if flipped:
        points = [(x + w, y), (x + w * 0.18, y + h * 0.05), (x, y + h * 0.34), (x + w * 0.22, y + h), (x + w * 1.04, y + h * 1.08)]
    else:
        points = [(x, y), (x + w * 0.82, y + h * 0.05), (x + w, y + h * 0.34), (x + w * 0.78, y + h), (x - w * 0.04, y + h * 1.08)]
    draw.polygon(polygon(points), fill=rgba(62, 68, 58, alpha), outline=rgba(20, 22, 18, round(alpha * 0.74)))
    for i in range(16):
        t = i / 15.0
        yy = y + h * (0.10 + t * 0.82)
        if flipped:
            x0 = x + w * rng.uniform(0.12, 0.92)
            x1 = x + w * rng.uniform(0.00, 0.72)
        else:
            x0 = x + w * rng.uniform(0.08, 0.88)
            x1 = x + w * rng.uniform(0.28, 1.00)
        draw.line([xy(x0, yy), xy(x1, yy + rng.uniform(-12, 10))], fill=rgba(148, 152, 122, rng.randint(22, 58)), width=rng.randint(1, 3))
    for i in range(8):
        t = i / 7.0
        crack_x = x + w * (0.18 + t * 0.70 if not flipped else 0.82 - t * 0.70)
        draw.line(
            [xy(crack_x, y + h * rng.uniform(0.12, 0.32)), xy(crack_x + rng.uniform(-34, 34), y + h * rng.uniform(0.62, 0.98))],
            fill=rgba(18, 20, 16, rng.randint(34, 80)),
            width=1,
        )


def draw_rapid_river(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    river = [
        (x - w * 0.04, y + h * 0.10),
        (x + w * 0.18, y + h * 0.02),
        (x + w * 0.42, y + h * 0.14),
        (x + w * 0.68, y + h * 0.00),
        (x + w * 1.04, y + h * 0.16),
        (x + w * 1.02, y + h * 0.92),
        (x + w * 0.70, y + h),
        (x + w * 0.38, y + h * 0.88),
        (x + w * 0.12, y + h),
        (x - w * 0.04, y + h * 0.86),
    ]
    draw.polygon(polygon(river), fill=rgba(34, 106, 126, alpha), outline=rgba(14, 52, 66, round(alpha * 0.68)))
    for band in range(34):
        t = band / 33.0
        yy = y + h * (0.055 + t * 0.82)
        drift = math.sin(band * 1.17) * w * 0.035
        color_alpha = rng.randint(28, 84)
        draw.line([xy(x + w * 0.02 + drift, yy), xy(x + w * 0.98 + drift * 0.35, yy - h * rng.uniform(0.020, 0.052))], fill=rgba(184, 236, 226, color_alpha), width=2)
    for _ in range(120):
        cx = rng.uniform(x + w * 0.03, x + w * 0.98)
        cy = rng.uniform(y + h * 0.08, y + h * 0.92)
        rx = rng.uniform(16, 58)
        draw.arc(box(cx - rx, cy - 8, cx + rx, cy + 12), 4, 174, fill=rgba(232, 250, 236, rng.randint(26, 88)), width=rng.randint(1, 2))
    for _ in range(26):
        cx = rng.uniform(x + w * 0.08, x + w * 0.92)
        cy = rng.uniform(y + h * 0.20, y + h * 0.82)
        draw_rock(draw, cx, cy, rng.uniform(18, 46), rng.uniform(10, 28), rng.randint(42, 90), (154, 150, 116))


def draw_cliff_plank_path(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(polygon([(x - 26, y + h * 0.36), (x + w + 48, y + h * 0.18), (x + w + 36, y + h * 0.56), (x - 42, y + h * 0.78)]), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(polygon([(x, y + h * 0.18), (x + w, y), (x + w + 32, y + h * 0.30), (x + 20, y + h * 0.50)]), fill=rgba(88, 58, 34, alpha), outline=rgba(24, 14, 8, round(alpha * 0.88)))
    for plank in range(14):
        t = plank / 13.0
        px = x + w * t
        draw.line([xy(px, y + h * (0.17 - 0.16 * t)), xy(px + 28, y + h * (0.49 - 0.16 * t))], fill=rgba(18, 10, 6, round(alpha * 0.48)), width=2)
    draw.line([xy(x - 12, y - h * 0.10), xy(x + w + 14, y - h * 0.25)], fill=rgba(46, 28, 14, round(alpha * 0.86)), width=4)
    for post in range(6):
        t = post / 5.0
        px = x + w * t
        py = y + h * (0.08 - 0.18 * t)
        draw.line([xy(px, py - h * 0.36), xy(px - 6, py + h * 0.44)], fill=rgba(36, 22, 12, round(alpha * 0.92)), width=4)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("three-gorges-floor-v1")
    river_top = h * 0.470
    river_height = h * 0.365
    draw_rapid_river(draw, w * 0.03, river_top, w * 0.94, river_height, 164, "three-gorges-rapids-floor")
    bank_top = h * 0.600
    draw.polygon(polygon([(w * -0.04, bank_top), (w * 0.33, bank_top - h * 0.045), (w * 1.04, h + 28), (w * -0.06, h + 28)]), fill=rgba(126, 110, 76, 118), outline=rgba(50, 38, 26, 78))
    draw.polygon(polygon([(w * 0.62, bank_top - h * 0.020), (w * 1.04, bank_top + h * 0.020), (w * 1.08, h + 24), (w * 0.76, h + 24)]), fill=rgba(112, 100, 72, 88), outline=rgba(42, 34, 24, 62))
    for row in range(18):
        t = row / 17.0
        y = bank_top + (t * t) * h * 0.36
        draw.line([xy(w * (-0.02 - t * 0.10), y), xy(w * (0.48 + t * 0.50), y - h * 0.022)], fill=rgba(218, 198, 128, 24 + row * 3), width=max(1, round(1.5 + t * 2.4)))
    draw_ferry_pier(draw, image, w * 0.61, h * 0.620, w * 0.22, h * 0.088, 168)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.64 + t * 0.27)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(214, 232, 172, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(224, 210, 142, 22 + lane * 3), width=2)
    for _ in range(170):
        x = rng.uniform(w * 0.02, w * 0.99)
        y = rng.uniform(bank_top + 8, h * 0.99)
        if rng.random() < 0.46:
            length = rng.uniform(12, 58)
            angle = rng.uniform(-0.32, 0.22)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(48, 82, 36, rng.randint(20, 66)), width=1)
        else:
            r = rng.uniform(1.3, 4.2)
            draw.ellipse(box(x - r, y - r * 0.52, x + r, y + r * 0.52), fill=rgba(132, 138, 86, rng.randint(28, 82)))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_cliff_wall(draw, w * -0.06, h * 0.245, w * 0.28, h * 0.360, 154, "three-gorges-left-cliff")
    draw_cliff_wall(draw, w * 0.78, h * 0.240, w * 0.30, h * 0.365, 150, "three-gorges-right-cliff", True)
    image.alpha_composite(draw_spray_band(size, h * 0.420, h * 0.125, "three-gorges-mid-spray", 42))
    draw_cliff_plank_path(draw, image, w * 0.12, h * 0.435, w * 0.28, h * 0.070, 156)
    draw_rope_bridge(draw, image, w * 0.39, h * 0.505, w * 0.28, h * 0.090, 156)
    draw_tea_hut(draw, image, w * 0.70, h * 0.305, w * 0.17, h * 0.19, 168)
    draw_ferry_pier(draw, image, w * 0.32, h * 0.535, w * 0.20, h * 0.075, 136)
    draw_plank_bridge(draw, image, w * 0.58, h * 0.512, w * 0.18, h * 0.046, 126)
    for x, y, scale, count, seed in (
        (w * 0.08, h * 0.515, 0.62, 8, "three-gorges-mid-bamboo-left"),
        (w * 0.88, h * 0.520, 0.66, 10, "three-gorges-mid-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 124, seed)
    for x, side in ((w * 0.24, -1.0), (w * 0.52, 1.0), (w * 0.82, -1.0)):
        draw_flag(draw, x, h * 0.496, 0.72, side, (86, 112, 70), 136)
    for x in (w * 0.15, w * 0.42, w * 0.74):
        draw_lantern(draw, image, x, h * 0.485, 0.45)
    draw_boat(draw, image, w * 0.24, h * 0.585, 0.86, 166)
    draw_boat(draw, image, w * 0.74, h * 0.600, 0.78, 148)
    rail_y = h * 0.535
    draw.line([xy(w * 0.05, rail_y), xy(w * 0.95, rail_y - h * 0.020)], fill=rgba(62, 40, 22, 128), width=5)
    for post in range(14):
        t = post / 13.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - h * 0.020 * t
        draw.line([xy(x, y - 22), xy(x - 5, y + 34)], fill=rgba(44, 28, 16, 124), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("three-gorges-foreground-v1")
    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(10, 14, 10, 94))
    draw_willow(draw, w * 0.040, h * 0.802, 1.06, 1.0)
    draw_willow(draw, w * 0.970, h * 0.806, 1.00, -1.0)
    draw_rock(draw, -w * 0.05, h * 0.785, w * 0.22, h * 0.20, 216, (168, 158, 112))
    draw_rock(draw, w * 0.82, h * 0.785, w * 0.22, h * 0.20, 214, (168, 158, 112))
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.858), (w * 0.64, w * 0.99, h * 0.844)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(60, 40, 24, 216), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(28, 20, 12, 170), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(38, 24, 14, 220), width=5)
    for _ in range(126):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=rgba(46, 96, 42, rng.randint(42, 112)), width=1)
    for i in range(9):
        x = w * (0.30 + i * 0.046)
        y = h * (0.910 + (i % 3) * 0.012)
        draw.rectangle(box(x - 16, y - 18, x + 20, y + 17), fill=rgba(70, 48, 28, 126), outline=rgba(28, 18, 12, 118), width=2)
        draw.line([xy(x - 10, y - 4), xy(x + 13, y - 6)], fill=rgba(222, 190, 118, 54), width=1)
    image.alpha_composite(draw_spray_band(size, h * 0.835, h * 0.150, "three-gorges-front-spray", 48))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (134, 156, 142), (72, 86, 64))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.56, h * 0.135), h * 0.210, (238, 224, 152), 34)
    draw_mountain_band(draw, w, h, h * 0.350, h * 0.300, rgba(58, 82, 76, 70), "three-gorges-far")
    draw_mountain_band(draw, w, h, h * 0.455, h * 0.295, rgba(42, 64, 58, 102), "three-gorges-mid")
    draw_mountain_band(draw, w, h, h * 0.555, h * 0.250, rgba(34, 44, 36, 128), "three-gorges-near")
    image.alpha_composite(draw_spray_band(size, h * 0.285, h * 0.095, "three-gorges-sky-spray", 36))
    rng = random.Random("three-gorges-scene-v1")
    for _ in range(95):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.72)
        length = rng.uniform(5, 16)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(164, 190, 120, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 60))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 32))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Three Gorges DNF rapids stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
