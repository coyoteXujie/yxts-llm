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
from generate_luoyang_dnf_capital_stage_assets import draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_qingcheng_mtn_dnf_daoist_gate_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "qingcheng_mtn_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "qingcheng_mtn_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "qingcheng_mtn_dnf_foreground_v1.png"


def draw_stream(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw.polygon(
        polygon([(x, y + h * 0.24), (x + w * 0.48, y), (x + w, y + h * 0.24), (x + w * 0.78, y + h), (x + w * 0.10, y + h * 0.82)]),
        fill=rgba(44, 112, 116, alpha),
        outline=rgba(22, 66, 68, round(alpha * 0.62)),
    )
    for band in range(11):
        t = band / 10.0
        sy = y + h * (0.20 + t * 0.58)
        draw.arc(box(x + w * (0.08 + t * 0.06), sy - 7, x + w * (0.78 + t * 0.08), sy + 10), 8, 166, fill=rgba(214, 244, 232, 26 + (band % 3) * 8), width=1)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qingcheng-mountain-floor-v1")

    top_y = h * 0.475
    draw.polygon(polygon([(w * 0.05, top_y), (w * 0.95, top_y - h * 0.022), (w * 1.05, h + 24), (w * -0.05, h + 24)]), fill=rgba(88, 102, 70, 88))
    draw_stream(draw, w * 0.58, h * 0.55, w * 0.34, h * 0.30, 92)

    path = [(w * 0.42, top_y - h * 0.018), (w * 0.58, top_y - h * 0.026), (w * 0.82, h + 28), (w * 0.18, h + 28)]
    draw.polygon(polygon(path), fill=rgba(126, 112, 82, 118), outline=rgba(42, 34, 24, 82))
    for step in range(13):
        t = step / 12.0
        y = top_y + h * (0.02 + t * t * 0.45)
        spread = w * (0.10 + t * 0.25)
        draw.line([xy(w * 0.50 - spread, y), xy(w * 0.50 + spread, y - h * 0.014)], fill=rgba(208, 198, 146, 38 + step * 4), width=max(2, round(2 + t * 2)))
        draw.line([xy(w * 0.50 - spread, y + 7), xy(w * 0.50 + spread, y - h * 0.014 + 7)], fill=rgba(30, 24, 18, 24 + step * 2), width=1)
    for col in range(26):
        t = col / 25.0
        sx = w * (0.04 + t * 0.92)
        tx = w * (0.50 + math.sin(col * 0.72) * 0.06)
        draw.line([xy(sx, h + 18), xy(tx, top_y - h * 0.024)], fill=rgba(48, 42, 30, 18 + int(abs(t - 0.5) * 34)), width=1)

    draw_plank_bridge(draw, image, w * 0.60, h * 0.600, w * 0.22, h * 0.052, 134)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.60 + t * 0.29)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.023), fill=rgba(212, 232, 168, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.044, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(196, 218, 136, 24 + lane * 3), width=2)

    for _ in range(210):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 20, h * 0.99)
        if rng.random() < 0.20:
            draw_rock(draw, x, y - 18, rng.uniform(18, 44), rng.uniform(12, 30), rng.randint(42, 86), (168, 162, 118))
        elif rng.random() < 0.55:
            length = rng.uniform(9, 56)
            angle = rng.uniform(-0.28, 0.20)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(44, 72, 34, rng.randint(22, 62)), width=1)
        else:
            r = rng.uniform(1.2, 3.6)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(104, 138, 74, rng.randint(26, 80)))
    return image


def draw_daoist_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.78, x + w * 0.94, y + h * 1.08), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)
    wall = rgba(178, 170, 132, alpha)
    timber = rgba(66, 84, 64, alpha)
    dark = rgba(26, 32, 24, round(alpha * 0.84))
    draw.rectangle(box(x + w * 0.10, y + h * 0.42, x + w * 0.90, y + h), fill=wall, outline=dark, width=2)
    for post in (0.18, 0.34, 0.66, 0.82):
        px = x + w * post
        draw.rectangle(box(px, y + h * 0.42, px + w * 0.028, y + h), fill=timber)
        draw.line([xy(px + w * 0.016, y + h * 0.44), xy(px + w * 0.016, y + h * 0.96)], fill=rgba(196, 222, 158, round(alpha * 0.24)), width=1)
    draw.polygon(
        polygon([(x - w * 0.02, y + h * 0.42), (x + w * 0.50, y + h * 0.08), (x + w * 1.02, y + h * 0.42), (x + w * 0.90, y + h * 0.57), (x + w * 0.10, y + h * 0.57)]),
        fill=rgba(48, 64, 50, alpha),
        outline=rgba(18, 22, 16, alpha),
    )
    for tile in range(10):
        t = tile / 9.0
        tx = x + w * (0.06 + t * 0.88)
        draw.line([xy(tx, y + h * 0.31), xy(tx + w * 0.060, y + h * 0.55)], fill=rgba(16, 20, 14, round(alpha * 0.34)), width=1)
    door_w = w * 0.18
    for door_x in (x + w * 0.27 - door_w * 0.5, x + w * 0.73 - door_w * 0.5):
        draw.rounded_rectangle(box(door_x, y + h * 0.64, door_x + door_w, y + h), radius=round(door_w * 0.15), fill=rgba(34, 42, 38, 166), outline=rgba(212, 190, 120, 112), width=2)
    sign = box(x + w * 0.36, y + h * 0.47, x + w * 0.64, y + h * 0.57)
    draw.rectangle(sign, fill=rgba(38, 28, 20, 210), outline=rgba(226, 196, 118, 150), width=2)
    for line in range(3):
        lx = x + w * (0.40 + line * 0.08)
        draw.line([xy(lx, y + h * 0.515), xy(lx + w * 0.036, y + h * 0.500)], fill=rgba(248, 222, 148, 96), width=2)
    for lx in (x + w * 0.20, x + w * 0.80):
        draw_lantern(draw, image, lx, y + h * 0.61, 0.56)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    hd.rectangle(box(0, h * 0.37, w, h * 0.57), fill=rgba(216, 232, 206, 38))
    haze = haze.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(haze)

    draw_bamboo_cluster(draw, w * 0.08, h * 0.515, 0.68, 13, 130, "qingcheng-mid-bamboo-left")
    draw_bamboo_cluster(draw, w * 0.91, h * 0.515, 0.66, 13, 126, "qingcheng-mid-bamboo-right")
    for x, y, scale, alpha, lean in (
        (w * 0.13, h * 0.47, 0.72, 144, 10.0),
        (w * 0.27, h * 0.44, 0.60, 120, -6.0),
        (w * 0.76, h * 0.45, 0.62, 126, 7.0),
        (w * 0.90, h * 0.49, 0.70, 144, -12.0),
    ):
        draw_pine(draw, x, y, scale, alpha, lean)

    draw_daoist_gate(draw, image, w * 0.34, h * 0.230, w * 0.32, h * 0.300, 218)
    draw_daoist_gate(draw, image, w * 0.12, h * 0.325, w * 0.18, h * 0.205, 160)
    draw_daoist_gate(draw, image, w * 0.70, h * 0.325, w * 0.18, h * 0.205, 160)

    for x, side in ((w * 0.31, -1.0), (w * 0.69, 1.0)):
        draw.line([xy(x, h * 0.365), xy(x + side * 10, h * 0.515)], fill=rgba(44, 28, 18, 148), width=4)
        draw.polygon(polygon([(x, h * 0.365), (x + side * 58, h * 0.392), (x + side * 48, h * 0.452), (x + side * 4, h * 0.425)]), fill=rgba(88, 130, 78, 114), outline=rgba(20, 34, 16, 92))

    rail_y = h * 0.530
    draw.line([xy(w * 0.07, rail_y), xy(w * 0.93, rail_y - 16)], fill=rgba(60, 42, 26, 134), width=5)
    for post in range(12):
        t = post / 11.0
        px = w * (0.08 + t * 0.84)
        py = rail_y - 16 * t
        draw.line([xy(px, py - 22), xy(px - 4, py + 34)], fill=rgba(42, 28, 18, 128), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qingcheng-mountain-foreground-v1")

    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(12, 16, 10, 90))
    draw_pine(draw, w * 0.035, h * 0.88, 1.10, 206, 18.0)
    draw_pine(draw, w * 0.965, h * 0.87, 1.06, 196, -18.0)
    draw_bamboo_cluster(draw, w * 0.16, h * 0.97, 0.74, 9, 174, "qingcheng-front-left", True)
    draw_bamboo_cluster(draw, w * 0.88, h * 0.97, 0.72, 9, 168, "qingcheng-front-right", True)
    draw_rock(draw, -w * 0.03, h * 0.80, w * 0.18, h * 0.17, 206, (168, 162, 118))
    draw_rock(draw, w * 0.82, h * 0.79, w * 0.20, h * 0.18, 202, (168, 162, 118))
    for x0, x1, y in ((w * 0.00, w * 0.25, h * 0.858), (w * 0.70, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.018)], fill=rgba(50, 36, 22, 205), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.032), xy(tx + w * 0.007, h)], fill=rgba(32, 22, 14, 210), width=5)

    for _ in range(95):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.82, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.066)
        draw.line([xy(x, y), xy(x + rng.uniform(-7, 8), y - length)], fill=rgba(44, 92, 40, rng.randint(42, 106)), width=1)
    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.18, h * 0.77, w * 0.34, h * 1.06), fill=rgba(214, 228, 196, 40))
    fd.ellipse(box(w * 0.56, h * 0.78, w * 1.14, h * 1.04), fill=rgba(206, 222, 190, 34))
    fog = fog.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(fog)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (136, 166, 148), (84, 104, 70))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.56, h * 0.15), h * 0.20, (228, 236, 178), 34)
    draw_mountain_band(draw, w, h, h * 0.38, h * 0.30, rgba(62, 94, 78, 74), "qingcheng-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.47, h * 0.28, rgba(48, 76, 58, 104), "qingcheng-mid-mountain")
    draw_mountain_band(draw, w, h, h * 0.55, h * 0.24, rgba(38, 54, 40, 120), "qingcheng-near-mountain")

    rng = random.Random("qingcheng-mountain-scene-v1")
    for i in range(11):
        x = w * (0.04 + i * 0.09)
        y = h * (0.17 + (i % 4) * 0.030)
        draw.ellipse(box(x - 60, y - 14, x + 78, y + 18), fill=rgba(222, 234, 210, 18 + (i % 4) * 6))
    for _ in range(80):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(150, 188, 96, rng.randint(14, 54)), width=1)

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(vignette)
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Qingcheng mountain DNF Daoist gate stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
