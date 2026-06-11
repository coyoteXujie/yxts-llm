#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_changan_dnf_west_market_stage_assets import draw_market_house
from generate_linan_dnf_water_city_stage_assets import draw_arch_bridge, draw_boat
from generate_luoyang_dnf_capital_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_cart,
    draw_flag,
    draw_gate_tower,
    draw_lantern,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_jiangling_dnf_river_city_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "jiangling_dnf_river_city_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "jiangling_dnf_river_city_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "jiangling_dnf_river_city_foreground_v1.png"


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("jiangling-river-city-floor-v1")

    quay_top = h * 0.49
    water_top = h * 0.525
    water_bottom = h * 0.715
    street_top = h * 0.62
    draw.polygon(polygon([(0, water_top), (w, water_top - h * 0.018), (w, water_bottom), (0, water_bottom + h * 0.035)]), fill=rgba(40, 88, 112, 130))
    for band in range(18):
        t = band / 17.0
        y = water_top + h * (0.018 + t * 0.16)
        drift = math.sin(band * 1.39) * 28
        draw.line([xy(w * 0.04 + drift, y), xy(w * 0.96 + drift * 0.20, y - h * 0.018)], fill=rgba(154, 218, 226, 32 + (band % 4) * 9), width=2)
    for ripple in range(50):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(water_top + h * 0.020, water_bottom - h * 0.012)
        draw.arc(box(x - 30, y - 7, x + 44, y + 9), 8, 168, fill=rgba(216, 238, 232, rng.randint(18, 54)), width=1)

    draw.polygon(polygon([(w * 0.04, quay_top), (w * 0.96, quay_top - h * 0.014), (w * 0.92, h * 0.61), (w * 0.08, h * 0.64)]), fill=rgba(126, 96, 62, 104), outline=rgba(50, 36, 24, 72))
    for i in range(13):
        t = i / 12.0
        x = w * (0.08 + t * 0.84)
        y = quay_top - h * 0.014 * t
        draw.line([xy(x, y - h * 0.020), xy(x - w * 0.008, y + h * 0.105)], fill=rgba(54, 34, 20, 126), width=4)
    draw.line([xy(w * 0.06, quay_top + h * 0.040), xy(w * 0.94, quay_top + h * 0.022)], fill=rgba(30, 20, 12, 92), width=4)

    draw.polygon(
        polygon([(w * 0.05, street_top), (w * 0.95, street_top - h * 0.020), (w * 1.06, h + 24), (w * -0.06, h + 24)]),
        fill=rgba(154, 112, 70, 92),
        outline=rgba(58, 38, 24, 68),
    )
    for row in range(20):
        t = row / 19.0
        y = street_top + (t * t) * h * 0.36
        draw.line([xy(w * (0.04 - t * 0.10), y), xy(w * (0.96 + t * 0.10), y - h * 0.018)], fill=rgba(82, 50, 32, round(86 - t * 28)), width=max(1, round(1.2 + t * 2.2)))
    for col in range(30):
        t = col / 29.0
        start_x = w * (-0.02 + t * 1.04)
        target_x = w * (0.48 + math.sin(col * 0.72) * 0.075)
        draw.line([xy(start_x, h + 16), xy(target_x, street_top - h * 0.12)], fill=rgba(68, 42, 28, 22 + int(abs(t - 0.5) * 36)), width=1)

    draw_arch_bridge(draw, image, w * 0.30, h * 0.548, w * 0.25, h * 0.105, 118)
    for x, y, color in (
        (w * 0.22, h * 0.575, (168, 58, 42)),
        (w * 0.47, h * 0.565, (68, 120, 132)),
        (w * 0.66, h * 0.575, (190, 128, 48)),
        (w * 0.78, h * 0.570, (118, 74, 132)),
    ):
        draw.polygon(polygon([(x - w * 0.065, y), (x + w * 0.065, y - h * 0.010), (x + w * 0.075, y + h * 0.038), (x - w * 0.055, y + h * 0.046)]), fill=rgba(color[0], color[1], color[2], 58), outline=rgba(250, 220, 150, 78))

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.65 + t * 0.25)
        draw.ellipse(box(w * 0.11, y - h * 0.014, w * 0.89, y + h * 0.022), fill=rgba(246, 226, 158, 11 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(236, 204, 126, 25 + lane * 3), width=2)

    for _ in range(180):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(street_top + 12, h * 0.99)
        length = rng.uniform(10, 60)
        angle = rng.uniform(-0.20, 0.18)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.40)], fill=rgba(76, 48, 32, rng.randint(20, 58)), width=1)
    return image


def draw_drum_tower(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    draw.rectangle(box(x - 42 * scale, y - 84 * scale, x + 42 * scale, y + 10 * scale), fill=rgba(84, 50, 28, round(alpha * 0.88)), outline=rgba(28, 16, 10, alpha), width=max(1, round(2 * scale)))
    draw.polygon(polygon([(x - 58 * scale, y - 86 * scale), (x, y - 124 * scale), (x + 58 * scale, y - 86 * scale), (x + 48 * scale, y - 72 * scale), (x - 48 * scale, y - 70 * scale)]), fill=rgba(88, 40, 28, alpha), outline=rgba(24, 14, 10, alpha))
    draw.ellipse(box(x - 30 * scale, y - 56 * scale, x + 30 * scale, y + 2 * scale), fill=rgba(160, 52, 34, round(alpha * 0.86)), outline=rgba(230, 180, 96, round(alpha * 0.62)), width=max(1, round(2 * scale)))
    add_glow(image, (x, y - 28 * scale), 36 * scale, (255, 126, 54), 24)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.42, w, h * 0.58), fill=rgba(224, 226, 204, 30))
    mist = mist.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(mist)

    wall_y = h * 0.455
    draw.rectangle(box(w * 0.03, wall_y - h * 0.150, w * 0.97, wall_y), fill=rgba(156, 112, 72, 170), outline=rgba(70, 44, 26, 118), width=3)
    for i in range(13):
        x = w * (0.06 + i * 0.073)
        draw.rectangle(box(x - w * 0.012, wall_y - h * 0.150, x + w * 0.012, wall_y - h * 0.080), fill=rgba(94, 58, 34, 150))
    draw_gate_tower(draw, image, w * 0.50, h * 0.485, w * 0.30, h * 0.34, 218)

    houses = [
        (w * 0.04, h * 0.265, w * 0.16, h * 0.235, (202, 146, 86), (194, 62, 42), (196, 122, 42)),
        (w * 0.20, h * 0.300, w * 0.16, h * 0.205, (182, 134, 92), (66, 126, 136), (176, 58, 42)),
        (w * 0.64, h * 0.292, w * 0.16, h * 0.215, (196, 140, 86), (190, 88, 44), (66, 124, 136)),
        (w * 0.80, h * 0.260, w * 0.16, h * 0.238, (208, 154, 92), (118, 64, 136), (202, 124, 48)),
    ]
    for args in houses:
        draw_market_house(draw, image, *args)

    draw_boat(draw, image, w * 0.14, h * 0.575, 0.90, 168)
    draw_boat(draw, image, w * 0.86, h * 0.585, 0.80, 146)
    draw_drum_tower(draw, image, w * 0.38, h * 0.495, 0.86, 172)
    draw_drum_tower(draw, image, w * 0.62, h * 0.497, 0.78, 154)

    for x in (w * 0.10, w * 0.26, w * 0.40, w * 0.60, w * 0.74, w * 0.90):
        draw_lantern(draw, image, x, h * (0.385 + (int(x) % 2) * 0.018), 0.76)
    for x, side in ((w * 0.31, -1.0), (w * 0.69, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.86, side, (174, 42, 34), 170)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("jiangling-river-city-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(18, 12, 8, 92))
    draw_cart(draw, image, w * 0.15, h * 0.885, 0.88, 176)
    draw_cart(draw, image, w * 0.86, h * 0.895, 0.80, 154)
    draw_flag(draw, w * 0.045, h * 0.80, 1.04, -1.0, (184, 44, 34), 210)
    draw_flag(draw, w * 0.955, h * 0.785, 0.98, 1.0, (214, 132, 48), 194)

    for x0, x1, y in ((w * 0.00, w * 0.26, h * 0.855), (w * 0.68, w * 0.99, h * 0.84)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(62, 38, 24, 214), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.036), xy(tx + w * 0.008, h)], fill=rgba(40, 26, 16, 220), width=5)

    for i in range(8):
        x = w * (0.28 + i * 0.065)
        y = h * (0.915 + (i % 2) * 0.016)
        draw.rectangle(box(x - 22, y - 24, x + 26, y + 18), fill=rgba(84, 50, 28, 124), outline=rgba(28, 18, 12, 116), width=2)
        if i % 3 == 0:
            draw.ellipse(box(x - 14, y - 34, x + 16, y - 8), fill=rgba(184, 88, 44, 76))

    for _ in range(82):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.82, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.060)
        draw.line([xy(x, y), xy(x + rng.uniform(-6, 8), y - length)], fill=rgba(86, 102, 44, rng.randint(38, 96)), width=1)

    haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    hd.ellipse(box(-w * 0.16, h * 0.78, w * 0.30, h * 1.08), fill=rgba(226, 206, 174, 34))
    hd.ellipse(box(w * 0.68, h * 0.78, w * 1.14, h * 1.06), fill=rgba(224, 202, 168, 32))
    haze = haze.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(haze)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (150, 172, 160), (98, 116, 96))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.56, h * 0.14), h * 0.20, (236, 224, 174), 32)
    for band in range(3):
        base_y = h * (0.23 + band * 0.060)
        color = rgba(62 + band * 7, 92 + band * 8, 82 + band * 6, 74 - band * 10)
        points = [(0, base_y + h * 0.13)]
        for i in range(14):
            x = w * i / 13.0
            y = base_y + math.sin(i * 1.30 + band * 0.8) * h * (0.017 + band * 0.005)
            points.append((x, y))
        points.append((w, base_y + h * 0.13))
        draw.polygon(polygon(points), fill=color)

    rng = random.Random("jiangling-river-city-scene-v1")
    for i in range(12):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.10, h * 0.30)
        r = rng.uniform(34, 76)
        draw.ellipse(box(x - r, y - r * 0.24, x + r, y + r * 0.24), fill=rgba(230, 238, 220, rng.randint(20, 44)))

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 30))
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
    print(f"OK generated Jiangling DNF river-city stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
