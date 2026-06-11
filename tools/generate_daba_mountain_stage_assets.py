#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster
from generate_beiling_mountain_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_mountain_band,
    draw_pine,
    draw_plank_bridge,
    draw_rock,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)
from generate_funiu_mtn_stage_assets import draw_ground_mist, draw_mine_cave, draw_small_waterfall, draw_stone_altar
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_daba_mtn_dnf_mine_peak_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "daba_mtn_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "daba_mtn_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "daba_mtn_dnf_foreground_v1.png"


def draw_mountain_creek(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    water = [
        (x, y + h * 0.22),
        (x + w * 0.24, y + h * 0.02),
        (x + w * 0.48, y + h * 0.18),
        (x + w * 0.76, y + h * 0.05),
        (x + w, y + h * 0.24),
        (x + w * 0.82, y + h),
        (x + w * 0.42, y + h * 0.86),
        (x + w * 0.10, y + h * 0.96),
    ]
    draw.polygon(polygon(water), fill=rgba(40, 110, 118, alpha), outline=rgba(18, 58, 64, round(alpha * 0.66)))
    for band in range(20):
        t = band / 19.0
        yy = y + h * (0.14 + t * 0.72)
        drift = math.sin(band * 1.37) * w * 0.045
        draw.arc(box(x + w * 0.06 + drift, yy - 8, x + w * 0.88 + drift * 0.24, yy + 12), 4, 172, fill=rgba(204, 240, 220, rng.randint(22, 66)), width=1)


def draw_mine_track(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int) -> None:
    rail_a = []
    rail_b = []
    for i in range(18):
        t = i / 17.0
        px = x + w * t
        wave = math.sin(t * math.pi * 1.2) * h * 0.10
        rail_a.append(xy(px, y + h * (0.20 + t * 0.10) + wave))
        rail_b.append(xy(px, y + h * (0.48 + t * 0.13) + wave))
    draw.line(rail_a, fill=rgba(54, 36, 22, round(alpha * 0.86)), width=4)
    draw.line(rail_b, fill=rgba(44, 28, 18, round(alpha * 0.76)), width=3)
    for sleeper in range(14):
        t = sleeper / 13.0
        px = x + w * t
        yy = y + h * (0.28 + t * 0.10 + math.sin(t * math.pi * 1.2) * 0.10)
        draw.line([xy(px - 8, yy - h * 0.12), xy(px + 12, yy + h * 0.30)], fill=rgba(82, 54, 30, round(alpha * 0.70)), width=3)


def draw_ore_veins(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int, copper: bool = False) -> None:
    glow = (178, 116, 68) if copper else (164, 174, 132)
    for i, ox in enumerate((-44, -18, 12, 38)):
        color = rgba(76, 82, 74, round(alpha * (0.86 + i * 0.03)))
        draw.polygon(
            polygon([(x + ox * scale, y + 30 * scale), (x + (ox - 18) * scale, y - 22 * scale), (x + (ox + 7) * scale, y - 48 * scale), (x + (ox + 28) * scale, y + 18 * scale)]),
            fill=color,
            outline=rgba(24, 26, 22, round(alpha * 0.68)),
        )
        draw.line([xy(x + (ox - 5) * scale, y - 20 * scale), xy(x + (ox + 18) * scale, y + 10 * scale)], fill=rgba(glow[0], glow[1], glow[2], 62), width=max(1, round(2 * scale)))


def draw_hidden_pass_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x + w * 0.08, y + h * 0.76, x + w * 0.94, y + h * 1.08), fill=rgba(0, 0, 0, 52))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x + w * 0.02, y + h), (x + w * 0.18, y + h * 0.36), (x + w * 0.52, y), (x + w * 0.88, y + h * 0.36), (x + w, y + h), (x + w * 0.72, y + h * 1.03), (x + w * 0.26, y + h * 1.03)]),
        fill=rgba(62, 70, 56, alpha),
        outline=rgba(22, 24, 18, round(alpha * 0.80)),
    )
    draw.ellipse(box(x + w * 0.34, y + h * 0.48, x + w * 0.68, y + h * 1.00), fill=rgba(18, 22, 18, round(alpha * 0.84)))
    draw.rectangle(box(x + w * 0.26, y + h * 0.32, x + w * 0.78, y + h * 0.42), fill=rgba(74, 48, 28, round(alpha * 0.72)), outline=rgba(202, 162, 88, round(alpha * 0.44)), width=2)
    for lx in (x + w * 0.24, x + w * 0.80):
        draw_lantern(draw, image, lx, y + h * 0.64, 0.42)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("daba-mtn-floor-v1")
    top_y = h * 0.500
    draw.polygon(polygon([(w * 0.02, top_y), (w * 0.96, top_y - 28), (w * 1.06, h + 26), (w * -0.06, h + 28)]), fill=rgba(86, 92, 58, 112), outline=rgba(40, 36, 24, 68))
    draw_mountain_creek(draw, w * 0.06, h * 0.570, w * 0.86, h * 0.190, 98, "daba-creek")
    path = [(w * 0.30, top_y - 10), (w * 0.58, top_y - 34), (w * 0.90, h + 28), (w * 0.12, h + 28)]
    draw.polygon(polygon(path), fill=rgba(118, 104, 74, 118), outline=rgba(48, 38, 26, 76))
    draw_plank_bridge(draw, image, w * 0.40, h * 0.584, w * 0.28, h * 0.058, 148)
    draw_mine_track(draw, w * 0.27, h * 0.650, w * 0.48, h * 0.080, 142)
    for row in range(15):
        t = row / 14.0
        y = top_y + h * (0.030 + t * t * 0.405)
        left = w * (0.28 - t * 0.22)
        right = w * (0.58 + t * 0.34)
        draw.line([xy(left, y), xy(right, y - 20)], fill=rgba(202, 186, 122, 28 + row * 3), width=max(1, round(1.5 + t * 2.2)))
    for _ in range(250):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 8, h * 0.99)
        if rng.random() < 0.35:
            draw_rock(draw, x, y - 17, rng.uniform(16, 48), rng.uniform(10, 30), rng.randint(38, 90), (142, 142, 104))
        else:
            length = rng.uniform(12, 60)
            angle = rng.uniform(-0.36, 0.24)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.36)], fill=rgba(44, 76, 36, rng.randint(22, 68)), width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_ground_mist(size, h * 0.390, h * 0.150, "daba-mid-mist", 46))
    draw_small_waterfall(draw, image, w * 0.455, h * 0.250, w * 0.110, h * 0.260, 126, "daba-waterfall")
    draw_mine_cave(draw, image, w * 0.10, h * 0.320, w * 0.190, h * 0.220, 172)
    draw_hidden_pass_gate(draw, image, w * 0.70, h * 0.315, w * 0.18, h * 0.205, 156)
    draw_stone_altar(draw, image, w * 0.58, h * 0.500, 0.78, 132)
    draw_ore_veins(draw, w * 0.30, h * 0.505, 0.84, 132, False)
    draw_ore_veins(draw, w * 0.78, h * 0.515, 0.80, 126, True)
    for x, y, scale, alpha, lean in (
        (w * 0.18, h * 0.525, 0.78, 152, 12.0),
        (w * 0.35, h * 0.500, 0.64, 128, -7.0),
        (w * 0.64, h * 0.505, 0.68, 132, 6.0),
        (w * 0.91, h * 0.530, 0.80, 150, -12.0),
    ):
        draw_pine(draw, x, y, scale, alpha, lean)
    for x, y, scale, count, seed in (
        (w * 0.07, h * 0.525, 0.58, 8, "daba-bamboo-left"),
        (w * 0.92, h * 0.535, 0.60, 9, "daba-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 116, seed)
    for x, side in ((w * 0.28, -1.0), (w * 0.50, 1.0), (w * 0.83, -1.0)):
        draw_flag(draw, x, h * 0.500, 0.72, side, (92, 108, 62), 136)
    rail_y = h * 0.535
    draw.line([xy(w * 0.05, rail_y), xy(w * 0.95, rail_y - h * 0.020)], fill=rgba(54, 38, 24, 132), width=5)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - h * 0.020 * t
        draw.line([xy(x, y - 24), xy(x - 4, y + 34)], fill=rgba(38, 28, 18, 128), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("daba-mtn-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(8, 10, 8, 104))
    draw_pine(draw, w * 0.04, h * 0.895, 1.10, 208, 18.0)
    draw_pine(draw, w * 0.96, h * 0.890, 1.06, 204, -18.0)
    draw_rock(draw, -w * 0.04, h * 0.795, w * 0.22, h * 0.20, 218, (146, 144, 104))
    draw_rock(draw, w * 0.81, h * 0.790, w * 0.22, h * 0.20, 216, (146, 144, 104))
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.858), (w * 0.66, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(50, 36, 24, 218), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(24, 18, 12, 172), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(32, 24, 14, 220), width=5)
    for i in range(10):
        x = w * (0.28 + i * 0.052)
        y = h * (0.918 + (i % 2) * 0.014)
        draw.rectangle(box(x - 15, y - 18, x + 20, y + 17), fill=rgba(66, 48, 30, 122), outline=rgba(24, 18, 12, 114), width=2)
    for _ in range(126):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.81, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        color = rgba(44, 86, 36, rng.randint(42, 112)) if rng.random() < 0.78 else rgba(114, 96, 58, rng.randint(38, 92))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    image.alpha_composite(draw_ground_mist(size, h * 0.835, h * 0.150, "daba-front-mist", 44))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (116, 132, 106), (60, 68, 44))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.55, h * 0.135), h * 0.205, (220, 212, 134), 28)
    draw_mountain_band(draw, w, h, h * 0.320, h * 0.330, rgba(58, 78, 66, 78), "daba-far")
    draw_mountain_band(draw, w, h, h * 0.445, h * 0.310, rgba(42, 58, 48, 112), "daba-mid")
    draw_mountain_band(draw, w, h, h * 0.560, h * 0.265, rgba(32, 38, 30, 136), "daba-near")
    image.alpha_composite(draw_ground_mist(size, h * 0.275, h * 0.110, "daba-sky-mist", 38))
    rng = random.Random("daba-mtn-scene-v1")
    for _ in range(96):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.72)
        length = rng.uniform(5, 14)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(150, 176, 94, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 66))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 34))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Daba mountain DNF mine peak stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
