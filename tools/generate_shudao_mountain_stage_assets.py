#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

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
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern
from generate_minjiang_river_stage_assets import draw_rope_bridge


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_shudao_mtn_dnf_cliff_road_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "shudao_mtn_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "shudao_mtn_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "shudao_mtn_dnf_foreground_v1.png"


def draw_cliff_wall(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    points = [(x, y + h), (x + w * 0.08, y + h * 0.18)]
    for step in range(7):
        t = step / 6.0
        points.append((x + w * (0.12 + t * 0.80), y + h * rng.uniform(0.00, 0.26)))
    points.extend([(x + w, y + h * 0.96), (x + w * 0.70, y + h * 1.06)])
    draw.polygon(polygon(points), fill=rgba(58, 54, 46, alpha), outline=rgba(18, 16, 14, round(alpha * 0.70)))
    for crack in range(18):
        sx = x + rng.uniform(w * 0.10, w * 0.92)
        sy = y + rng.uniform(h * 0.14, h * 0.94)
        length = rng.uniform(h * 0.06, h * 0.22)
        draw.line([xy(sx, sy), xy(sx + rng.uniform(-20, 34), sy + length)], fill=rgba(20, 18, 16, rng.randint(40, 92)), width=1)
    for edge in range(8):
        sx = x + w * (0.16 + edge * 0.10)
        draw.line([xy(sx, y + h * 0.20), xy(sx - 26, y + h * 0.88)], fill=rgba(150, 132, 96, round(alpha * 0.18)), width=2)


def draw_pass_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.04, y + h * 0.78, x + w * 0.96, y + h * 1.08), fill=rgba(0, 0, 0, 58))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.08, y + h * 0.35, x + w * 0.92, y + h), fill=rgba(116, 84, 50, alpha), outline=rgba(34, 22, 14, round(alpha * 0.78)))
    draw.polygon(
        polygon([(x - w * 0.05, y + h * 0.42), (x + w * 0.50, y), (x + w * 1.05, y + h * 0.42), (x + w * 0.92, y + h * 0.60), (x + w * 0.08, y + h * 0.60)]),
        fill=rgba(68, 54, 36, alpha),
        outline=rgba(20, 14, 8, alpha),
    )
    for tile in range(10):
        t = tile / 9.0
        tx = x + w * (0.04 + t * 0.92)
        draw.line([xy(tx, y + h * 0.25), xy(tx + w * 0.06, y + h * 0.58)], fill=rgba(24, 18, 12, round(alpha * 0.36)), width=1)
    draw.rectangle(box(x + w * 0.34, y + h * 0.58, x + w * 0.66, y + h), fill=rgba(36, 24, 16, round(alpha * 0.86)))
    sign = box(x + w * 0.30, y + h * 0.375, x + w * 0.70, y + h * 0.485)
    draw.rectangle(sign, fill=rgba(46, 28, 14, 178), outline=rgba(224, 176, 88, 118), width=2)
    draw.line([xy(x + w * 0.37, y + h * 0.43), xy(x + w * 0.62, y + h * 0.405)], fill=rgba(244, 212, 122, 86), width=2)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("shudao-mountain-floor-v1")
    top_y = h * 0.472
    draw.polygon(polygon([(w * 0.04, top_y), (w * 0.92, top_y - 26), (w * 1.05, h + 22), (w * -0.05, h + 26)]), fill=rgba(88, 78, 58, 92))
    for band in range(9):
        t = band / 8.0
        y = top_y + (t * t) * h * 0.45
        left = w * (0.08 - t * 0.10)
        right = w * (0.94 + t * 0.06)
        draw.polygon(
            polygon([(left, y), (right, y - 28), (right + 48, y + 42), (left - 38, y + 58)]),
            fill=rgba(82, 72, 54, round(54 + t * 52)),
            outline=rgba(22, 20, 17, round(46 + t * 50)),
        )
        draw.line([xy(left + 30, y + 8), xy(right - 20, y - 20)], fill=rgba(172, 150, 100, round(28 + t * 22)), width=2)
    draw_rope_bridge(draw, image, w * 0.42, h * 0.555, w * 0.30, h * 0.085, 168)
    draw_plank_bridge(draw, image, w * 0.16, h * 0.535, w * 0.24, h * 0.055, 138)
    for _ in range(190):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 24, h * 0.98)
        length = rng.uniform(10, 66)
        angle = rng.uniform(-0.26, 0.18)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.45)], fill=rgba(34, 29, 22, rng.randint(24, 64)), width=1)
        if rng.random() < 0.18:
            draw_rock(draw, x, y - 18, rng.uniform(18, 48), rng.uniform(12, 30), rng.randint(42, 84))
    for _ in range(260):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(top_y + 16, h * 0.99)
        if rng.random() < 0.44:
            r = rng.uniform(1.2, 4.2)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(118, 106, 76, rng.randint(34, 92)))
        else:
            length = rng.uniform(8, 44)
            angle = rng.uniform(-0.34, 0.22)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(178, 156, 104, rng.randint(18, 48)), width=1)
    for edge in range(14):
        t = edge / 13.0
        y = top_y + h * (0.05 + t * 0.38)
        draw.line([xy(w * (0.04 - t * 0.08), y), xy(w * (0.98 + t * 0.05), y - h * 0.020)], fill=rgba(22, 18, 14, 28 + edge * 2), width=max(1, round(1 + t * 3)))
        draw.line([xy(w * (0.09 - t * 0.06), y + 8), xy(w * (0.92 + t * 0.05), y - h * 0.016 + 8)], fill=rgba(214, 194, 132, 14 + edge), width=1)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.57 + t * 0.30)
        draw.ellipse(box(w * 0.10, y - h * 0.015, w * 0.90, y + h * 0.022), fill=rgba(226, 210, 152, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.045, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(218, 198, 130, 22 + lane * 3), width=2)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_cliff_wall(draw, w * -0.02, h * 0.260, w * 0.30, h * 0.36, 132, "shudao-left-wall")
    draw_cliff_wall(draw, w * 0.74, h * 0.250, w * 0.30, h * 0.37, 128, "shudao-right-wall")
    draw_pass_gate(draw, image, w * 0.38, h * 0.275, w * 0.22, h * 0.24, 176)
    draw_plank_bridge(draw, image, w * 0.10, h * 0.454, w * 0.24, h * 0.052, 112)
    draw_plank_bridge(draw, image, w * 0.64, h * 0.468, w * 0.22, h * 0.050, 108)
    for x, y, scale, alpha in (
        (w * 0.08, h * 0.50, 0.74, 150),
        (w * 0.24, h * 0.46, 0.62, 126),
        (w * 0.72, h * 0.46, 0.66, 132),
        (w * 0.91, h * 0.49, 0.76, 150),
    ):
        draw_pine(draw, x, y, scale, alpha, math.sin(x) * 11.0)
    for x, side in ((w * 0.32, -1.0), (w * 0.62, 1.0)):
        draw_flag(draw, x, h * 0.500, 0.76, side, (128, 54, 36), 142)
    for x in (w * 0.42, w * 0.54, w * 0.67):
        draw_lantern(draw, image, x, h * 0.488, 0.44)
    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.40, w, h * 0.58), fill=rgba(218, 218, 192, 34))
    md.ellipse(box(w * 0.18, h * 0.36, w * 0.82, h * 0.60), fill=rgba(218, 218, 192, 22))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(18)))
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("shudao-mountain-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(16, 13, 10, 94))
    draw_cliff_wall(draw, -w * 0.04, h * 0.700, w * 0.22, h * 0.30, 214, "shudao-front-left")
    draw_cliff_wall(draw, w * 0.82, h * 0.690, w * 0.24, h * 0.31, 210, "shudao-front-right")
    draw_pine(draw, w * 0.05, h * 0.88, 1.10, 196, 18.0)
    draw_pine(draw, w * 0.95, h * 0.88, 1.04, 188, -16.0)
    for _ in range(84):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.82, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.060)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(44, 82, 38, rng.randint(42, 106)), width=1)
    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.20, h * 0.76, w * 0.34, h * 1.08), fill=rgba(218, 218, 190, 42))
    fd.ellipse(box(w * 0.58, h * 0.76, w * 1.18, h * 1.06), fill=rgba(210, 206, 178, 38))
    fd.ellipse(box(w * 0.20, h * 0.54, w * 0.78, h * 0.73), fill=rgba(224, 224, 204, 24))
    image.alpha_composite(fog.filter(ImageFilter.GaussianBlur(24)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (144, 158, 150), (98, 92, 72))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.54, h * 0.14), h * 0.20, (230, 226, 176), 30)
    draw_mountain_band(draw, w, h, h * 0.38, h * 0.34, rgba(64, 78, 70, 78), "shudao-far")
    draw_mountain_band(draw, w, h, h * 0.47, h * 0.32, rgba(52, 62, 52, 108), "shudao-mid")
    draw_mountain_band(draw, w, h, h * 0.56, h * 0.30, rgba(40, 44, 38, 130), "shudao-near")
    for i in range(10):
        x = w * (0.04 + i * 0.105)
        y = h * (0.18 + (i % 4) * 0.035)
        draw.ellipse(box(x - 60, y - 16, x + 76, y + 18), fill=rgba(226, 226, 206, 20 + (i % 3) * 7))
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 60))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 32))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Shudao mountain DNF cliff road stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
