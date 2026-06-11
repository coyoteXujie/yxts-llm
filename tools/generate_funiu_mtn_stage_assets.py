#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_tea_hut
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
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_funiu_mtn_dnf_forest_mine_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "funiu_mtn_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "funiu_mtn_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "funiu_mtn_dnf_foreground_v1.png"


def draw_ground_mist(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(18):
        cx = rng.uniform(-w * 0.06, w * 1.06)
        cy = y + rng.uniform(-height * 0.34, height * 0.34)
        rx = rng.uniform(w * 0.040, w * 0.130)
        ry = rng.uniform(height * 0.20, height * 0.48)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(210, 220, 178, rng.randint(round(alpha * 0.36), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.15))))


def draw_mountain_stream(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    water = [
        (x, y + h * 0.18),
        (x + w * 0.22, y),
        (x + w * 0.48, y + h * 0.20),
        (x + w * 0.78, y + h * 0.08),
        (x + w, y + h * 0.26),
        (x + w * 0.82, y + h),
        (x + w * 0.45, y + h * 0.84),
        (x + w * 0.10, y + h * 0.92),
    ]
    draw.polygon(polygon(water), fill=rgba(46, 116, 116, alpha), outline=rgba(20, 62, 58, round(alpha * 0.64)))
    for i in range(18):
        t = i / 17.0
        yy = y + h * (0.16 + t * 0.68)
        drift = math.sin(i * 1.4) * w * 0.04
        draw.arc(box(x + w * 0.06 + drift, yy - 8, x + w * 0.88 + drift * 0.24, yy + 12), 4, 172, fill=rgba(206, 242, 222, rng.randint(24, 68)), width=1)


def draw_small_waterfall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.polygon(
        polygon([(x + w * 0.28, y), (x + w * 0.70, y + h * 0.02), (x + w * 0.82, y + h * 0.84), (x + w * 0.18, y + h * 0.94), (x + w * 0.12, y + h * 0.35)]),
        fill=rgba(126, 206, 196, round(alpha * 0.26)),
    )
    for _ in range(14):
        sx = x + w * rng.uniform(0.20, 0.74)
        ld.line([xy(sx, y + rng.uniform(0, h * 0.05)), xy(sx + rng.uniform(-20, 20), y + h * rng.uniform(0.72, 0.96))], fill=rgba(224, 250, 230, rng.randint(28, 78)), width=rng.randint(1, 3))
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(2)))
    draw.ellipse(box(x - w * 0.22, y + h * 0.82, x + w * 1.22, y + h * 1.10), fill=rgba(48, 126, 112, round(alpha * 0.34)), outline=rgba(200, 238, 220, round(alpha * 0.26)), width=2)


def draw_mine_cave(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.08, y + h * 0.62, x + w * 1.08, y + h * 1.12), fill=rgba(0, 0, 0, 62))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x, y + h), (x + w * 0.10, y + h * 0.26), (x + w * 0.50, y), (x + w * 0.92, y + h * 0.30), (x + w, y + h), (x + w * 0.70, y + h * 1.05), (x + w * 0.20, y + h * 1.04)]),
        fill=rgba(78, 76, 62, alpha),
        outline=rgba(24, 22, 18, round(alpha * 0.78)),
    )
    draw.ellipse(box(x + w * 0.30, y + h * 0.36, x + w * 0.72, y + h * 1.03), fill=rgba(18, 20, 18, round(alpha * 0.88)))
    for px in (x + w * 0.28, x + w * 0.72):
        draw.line([xy(px, y + h * 0.52), xy(px, y + h * 1.04)], fill=rgba(80, 52, 28, round(alpha * 0.86)), width=5)
    draw.line([xy(x + w * 0.26, y + h * 0.56), xy(x + w * 0.74, y + h * 0.54)], fill=rgba(88, 58, 30, round(alpha * 0.86)), width=5)
    for i in range(4):
        ox = x + w * (0.18 + i * 0.18)
        draw.polygon(polygon([(ox, y + h * 0.22), (ox + w * 0.08, y + h * 0.16), (ox + w * 0.04, y + h * 0.62)]), fill=rgba(160, 150, 104, round(alpha * 0.22)))


def draw_secret_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.06, y + h * 0.74, x + w * 0.96, y + h * 1.06), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.14, y + h * 0.38, x + w * 0.86, y + h), fill=rgba(86, 78, 58, alpha), outline=rgba(24, 20, 16, round(alpha * 0.82)), width=2)
    draw.polygon(
        polygon([(x - w * 0.06, y + h * 0.42), (x + w * 0.50, y), (x + w * 1.06, y + h * 0.42), (x + w * 0.92, y + h * 0.60), (x + w * 0.08, y + h * 0.62)]),
        fill=rgba(44, 66, 42, alpha),
        outline=rgba(12, 20, 10, alpha),
    )
    draw.rectangle(box(x + w * 0.38, y + h * 0.56, x + w * 0.62, y + h), fill=rgba(24, 30, 24, round(alpha * 0.82)), outline=rgba(176, 142, 72, 104), width=2)
    sign = box(x + w * 0.34, y + h * 0.405, x + w * 0.66, y + h * 0.505)
    draw.rectangle(sign, fill=rgba(38, 28, 18, 194), outline=rgba(220, 176, 92, 132), width=2)
    draw.arc(box(x + w * 0.40, y + h * 0.425, x + w * 0.60, y + h * 0.498), 20, 330, fill=rgba(218, 190, 112, 100), width=2)
    for lx in (x + w * 0.20, x + w * 0.80):
        draw_lantern(draw, image, lx, y + h * 0.60, 0.48)


def draw_stone_altar(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    w = 120 * scale
    h = 96 * scale
    draw.ellipse(box(x - w * 0.58, y + h * 0.18, x + w * 0.58, y + h * 0.46), fill=rgba(0, 0, 0, round(alpha * 0.22)))
    for tier in range(3):
        tw = w * (0.94 - tier * 0.18)
        th = h * 0.18
        ty = y + h * (0.22 - tier * 0.15)
        draw.polygon(polygon([(x - tw * 0.50, ty), (x + tw * 0.50, ty - th * 0.14), (x + tw * 0.44, ty + th), (x - tw * 0.44, ty + th * 1.08)]), fill=rgba(112, 104, 84, round(alpha * (0.90 - tier * 0.06))), outline=rgba(38, 34, 26, round(alpha * 0.66)))
    draw.line([xy(x, y - h * 0.55), xy(x, y + h * 0.02)], fill=rgba(62, 44, 30, round(alpha * 0.88)), width=max(2, round(4 * scale)))
    draw.polygon(polygon([(x, y - h * 0.55), (x + w * 0.30, y - h * 0.40), (x + w * 0.24, y - h * 0.23), (x + w * 0.02, y - h * 0.34)]), fill=rgba(88, 118, 62, round(alpha * 0.78)), outline=rgba(30, 40, 22, round(alpha * 0.62)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("funiu-mtn-floor-v1")
    top_y = h * 0.485
    draw.polygon(polygon([(w * 0.05, top_y), (w * 0.95, top_y - 22), (w * 1.06, h + 24), (w * -0.06, h + 24)]), fill=rgba(94, 104, 62, 100))
    draw_mountain_stream(draw, w * 0.08, h * 0.555, w * 0.78, h * 0.210, 104, "funiu-stream")
    path = [(w * 0.33, top_y - 12), (w * 0.56, top_y - 26), (w * 0.88, h + 28), (w * 0.14, h + 28)]
    draw.polygon(polygon(path), fill=rgba(134, 116, 78, 112), outline=rgba(50, 40, 28, 76))
    for row in range(14):
        t = row / 13.0
        y = top_y + h * (0.030 + t * t * 0.410)
        left = w * (0.32 - t * 0.22)
        right = w * (0.56 + t * 0.34)
        draw.line([xy(left, y), xy(right, y - 18)], fill=rgba(210, 190, 122, 30 + row * 3), width=max(2, round(2 + t)))
    draw_plank_bridge(draw, image, w * 0.38, h * 0.575, w * 0.28, h * 0.060, 156)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.61 + t * 0.28)
        draw.ellipse(box(w * 0.11, y - h * 0.014, w * 0.89, y + h * 0.022), fill=rgba(216, 224, 156, 10 + lane * 3))
        draw.arc(box(w * 0.13, y - h * 0.044, w * 0.87, y + h * 0.040), 7, 176, fill=rgba(198, 206, 126, 24 + lane * 3), width=2)
    for _ in range(230):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 10, h * 0.99)
        if rng.random() < 0.24:
            draw_rock(draw, x, y - 18, rng.uniform(16, 44), rng.uniform(10, 28), rng.randint(38, 88), (158, 150, 104))
        elif rng.random() < 0.58:
            length = rng.uniform(12, 58)
            angle = rng.uniform(-0.38, 0.24)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(48, 78, 34, rng.randint(22, 64)), width=1)
        else:
            r = rng.uniform(1.2, 4.2)
            draw.ellipse(box(x - r, y - r * 0.5, x + r, y + r * 0.5), fill=rgba(132, 150, 76, rng.randint(30, 86)))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_ground_mist(size, h * 0.390, h * 0.150, "funiu-mid-mist", 42))
    draw_small_waterfall(draw, image, w * 0.455, h * 0.260, w * 0.105, h * 0.250, 130, "funiu-waterfall")
    draw_mine_cave(draw, image, w * 0.10, h * 0.330, w * 0.185, h * 0.205, 164)
    draw_secret_gate(draw, image, w * 0.68, h * 0.300, w * 0.20, h * 0.225, 172)
    draw_stone_altar(draw, image, w * 0.58, h * 0.510, 0.78, 138)
    for x, y, scale, alpha, lean in (
        (w * 0.18, h * 0.525, 0.72, 146, 12.0),
        (w * 0.34, h * 0.500, 0.58, 122, -7.0),
        (w * 0.64, h * 0.505, 0.62, 128, 6.0),
        (w * 0.90, h * 0.530, 0.74, 146, -12.0),
    ):
        draw_pine(draw, x, y, scale, alpha, lean)
    for x, y, scale, count, seed in (
        (w * 0.08, h * 0.525, 0.58, 9, "funiu-bamboo-left"),
        (w * 0.92, h * 0.535, 0.60, 10, "funiu-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 118, seed)
    draw_tea_hut(draw, image, w * 0.30, h * 0.330, w * 0.16, h * 0.175, 132)
    for x, side in ((w * 0.29, -1.0), (w * 0.52, 1.0), (w * 0.82, -1.0)):
        draw_flag(draw, x, h * 0.500, 0.72, side, (90, 118, 62), 132)
    for x in (w * 0.16, w * 0.42, w * 0.72):
        draw_lantern(draw, image, x, h * 0.485, 0.43)
    rail_y = h * 0.535
    draw.line([xy(w * 0.05, rail_y), xy(w * 0.95, rail_y - h * 0.020)], fill=rgba(58, 42, 24, 128), width=5)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - h * 0.020 * t
        draw.line([xy(x, y - 24), xy(x - 4, y + 34)], fill=rgba(42, 30, 18, 124), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("funiu-mtn-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(10, 12, 8, 96))
    draw_pine(draw, w * 0.04, h * 0.895, 1.08, 208, 18.0)
    draw_pine(draw, w * 0.96, h * 0.888, 1.02, 200, -18.0)
    draw_rock(draw, -w * 0.04, h * 0.795, w * 0.20, h * 0.19, 214, (154, 148, 104))
    draw_rock(draw, w * 0.82, h * 0.790, w * 0.21, h * 0.19, 210, (154, 148, 104))
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.858), (w * 0.66, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(54, 40, 24, 214), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(26, 18, 12, 174), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(34, 24, 14, 218), width=5)
    for _ in range(118):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.81, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.070)
        color = rgba(48, 90, 38, rng.randint(42, 106)) if rng.random() < 0.84 else rgba(116, 92, 54, rng.randint(38, 92))
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=color, width=1)
    image.alpha_composite(draw_ground_mist(size, h * 0.835, h * 0.150, "funiu-front-mist", 42))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (122, 142, 112), (72, 80, 50))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.55, h * 0.135), h * 0.210, (232, 222, 142), 30)
    draw_mountain_band(draw, w, h, h * 0.335, h * 0.315, rgba(64, 82, 66, 72), "funiu-far")
    draw_mountain_band(draw, w, h, h * 0.445, h * 0.295, rgba(50, 64, 48, 104), "funiu-mid")
    draw_mountain_band(draw, w, h, h * 0.555, h * 0.250, rgba(38, 44, 34, 130), "funiu-near")
    image.alpha_composite(draw_ground_mist(size, h * 0.265, h * 0.105, "funiu-sky-mist", 38))
    rng = random.Random("funiu-mtn-scene-v1")
    for _ in range(92):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.72)
        length = rng.uniform(5, 14)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(156, 180, 96, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 60))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 34))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Funiu mountain DNF forest mine stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
