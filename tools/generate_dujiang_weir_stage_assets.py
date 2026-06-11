#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge, draw_tea_hut
from generate_linan_dnf_water_city_stage_assets import draw_arch_bridge, draw_boat, draw_willow
from generate_luoyang_dnf_capital_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_flag,
    draw_lantern,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_dujiang_weir_dnf_waterworks_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "dujiang_weir_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "dujiang_weir_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "dujiang_weir_dnf_foreground_v1.png"


def draw_stone_weir(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(polygon([(x - 38, y + h * 0.70), (x + w + 42, y + h * 0.54), (x + w + 20, y + h), (x - 50, y + h * 1.10)]), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)
    draw.polygon(
        polygon([(x, y + h * 0.18), (x + w, y), (x + w + 34, y + h * 0.38), (x + w * 0.05, y + h * 0.58)]),
        fill=rgba(128, 116, 92, alpha),
        outline=rgba(42, 34, 24, round(alpha * 0.72)),
    )
    for index in range(10):
        t = index / 9.0
        px = x + w * t
        py = y + h * (0.18 - 0.18 * t)
        draw.line([xy(px, py), xy(px + 30, py + h * 0.38)], fill=rgba(54, 44, 32, round(alpha * 0.34)), width=2)
    for row in range(3):
        offset = row * h * 0.13
        draw.line([xy(x + w * 0.05, y + h * 0.28 + offset), xy(x + w * 1.02, y + h * 0.10 + offset)], fill=rgba(216, 204, 154, round(alpha * 0.22)), width=2)
    for splash in range(16):
        t = splash / 15.0
        sx = x + w * (0.05 + t * 0.90)
        sy = y + h * (0.50 - t * 0.12)
        draw.arc(box(sx - 24, sy - 8, sx + 32, sy + 10), 7, 168, fill=rgba(218, 244, 236, 44 + splash % 4 * 8), width=1)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("dujiang-weir-floor-v1")

    horizon = h * 0.46
    water_top = h * 0.500
    water_bottom = h * 0.755
    path_top = h * 0.618
    main_channel = [
        (w * 0.00, water_top + h * 0.02),
        (w * 0.48, water_top - h * 0.02),
        (w * 0.68, water_bottom - h * 0.08),
        (w * 1.04, water_bottom - h * 0.02),
        (w * 1.03, h * 0.90),
        (w * 0.60, h * 0.82),
        (w * 0.38, h * 0.70),
        (w * -0.05, h * 0.79),
    ]
    draw.polygon(polygon(main_channel), fill=rgba(42, 112, 124, 142), outline=rgba(22, 66, 70, 76))
    split_channel = [
        (w * 0.46, water_top - h * 0.01),
        (w * 0.62, water_top - h * 0.035),
        (w * 0.92, water_top + h * 0.06),
        (w * 0.98, water_top + h * 0.16),
        (w * 0.69, water_top + h * 0.17),
        (w * 0.53, water_top + h * 0.08),
    ]
    draw.polygon(polygon(split_channel), fill=rgba(70, 142, 136, 100), outline=rgba(28, 76, 72, 62))
    for band in range(24):
        t = band / 23.0
        y = water_top + h * (0.020 + t * 0.28)
        drift = math.sin(band * 1.23) * 42
        draw.line([xy(w * 0.04 + drift, y), xy(w * 0.94 + drift * 0.18, y - h * 0.034)], fill=rgba(178, 232, 226, 30 + (band % 5) * 8), width=2)
    for ripple in range(58):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(water_top + 16, water_bottom + 42)
        draw.arc(box(x - 28, y - 7, x + 42, y + 9), 7, 170, fill=rgba(226, 248, 240, rng.randint(20, 60)), width=1)

    draw.polygon(
        polygon([(w * 0.10, path_top), (w * 0.46, path_top - h * 0.045), (w * 0.88, h + 26), (w * -0.05, h + 28)]),
        fill=rgba(136, 118, 82, 112),
        outline=rgba(54, 42, 28, 82),
    )
    for row in range(18):
        t = row / 17.0
        y = path_top + (t * t) * h * 0.38
        left = w * (0.08 - t * 0.15)
        right = w * (0.48 + t * 0.46)
        draw.line([xy(left, y), xy(right, y - h * 0.020)], fill=rgba(220, 202, 140, 28 + row * 3), width=max(1, round(1.6 + t * 2.4)))
    for col in range(24):
        t = col / 23.0
        start_x = w * (-0.02 + t * 0.96)
        target_x = w * (0.34 + math.sin(col * 0.74) * 0.11)
        draw.line([xy(start_x, h + 18), xy(target_x, horizon + h * 0.02)], fill=rgba(62, 48, 34, 20 + int(abs(t - 0.5) * 36)), width=1)

    draw_stone_weir(draw, image, w * 0.33, h * 0.520, w * 0.30, h * 0.120, 186)
    draw_arch_bridge(draw, image, w * 0.58, h * 0.535, w * 0.28, h * 0.120, 176)
    draw_plank_bridge(draw, image, w * 0.18, h * 0.580, w * 0.22, h * 0.052, 140)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.64 + t * 0.27)
        draw.ellipse(box(w * 0.11, y - h * 0.014, w * 0.89, y + h * 0.022), fill=rgba(220, 232, 168, 10 + lane * 3))
        draw.arc(box(w * 0.13, y - h * 0.043, w * 0.87, y + h * 0.041), 7, 174, fill=rgba(222, 212, 138, 24 + lane * 3), width=2)

    for _ in range(220):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(path_top + 10, h * 0.99)
        if rng.random() < 0.42:
            r = rng.uniform(1.4, 4.2)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(112, 136, 78, rng.randint(28, 80)))
        else:
            length = rng.uniform(10, 62)
            angle = rng.uniform(-0.28, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(54, 78, 36, rng.randint(20, 62)), width=1)
    return image


def draw_water_gate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.04, y + h * 0.76, x + w * 1.00, y + h * 1.08), fill=rgba(0, 0, 0, 52))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(shadow)
    draw.rectangle(box(x + w * 0.06, y + h * 0.34, x + w * 0.94, y + h), fill=rgba(126, 104, 72, alpha), outline=rgba(38, 26, 18, round(alpha * 0.78)))
    draw.polygon(
        polygon([(x - w * 0.04, y + h * 0.40), (x + w * 0.50, y), (x + w * 1.04, y + h * 0.40), (x + w * 0.94, y + h * 0.58), (x + w * 0.06, y + h * 0.58)]),
        fill=rgba(72, 64, 46, alpha),
        outline=rgba(20, 14, 10, alpha),
    )
    for tile in range(9):
        t = tile / 8.0
        tx = x + w * (0.03 + t * 0.94)
        draw.line([xy(tx, y + h * 0.27), xy(tx + w * 0.06, y + h * 0.56)], fill=rgba(24, 18, 12, round(alpha * 0.32)), width=1)
    for row in range(3):
        draw.line(
            [xy(x + w * 0.08, y + h * (0.47 + row * 0.13)), xy(x + w * 0.92, y + h * (0.45 + row * 0.13))],
            fill=rgba(220, 202, 142, round(alpha * 0.20)),
            width=1,
        )
    for post in (0.18, 0.36, 0.62, 0.82):
        draw.line([xy(x + w * post, y + h * 0.44), xy(x + w * (post - 0.03), y + h)], fill=rgba(42, 28, 18, round(alpha * 0.82)), width=5)
    draw.rectangle(box(x + w * 0.28, y + h * 0.56, x + w * 0.72, y + h * 0.72), fill=rgba(42, 28, 18, 160), outline=rgba(232, 196, 104, 110), width=2)
    draw.line([xy(x + w * 0.34, y + h * 0.64), xy(x + w * 0.66, y + h * 0.625)], fill=rgba(246, 218, 128, 96), width=2)
    for gate in range(3):
        gx = x + w * (0.24 + gate * 0.23)
        draw.line([xy(gx, y + h * 0.74), xy(gx - w * 0.03, y + h * 1.06)], fill=rgba(22, 16, 10, 120), width=4)
        draw.rectangle(box(gx - w * 0.045, y + h * 0.76, gx + w * 0.045, y + h * 0.90), fill=rgba(38, 80, 76, 54), outline=rgba(24, 18, 12, 72))


def draw_stone_marker(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int) -> None:
    w = 54 * scale
    h = 112 * scale
    draw.polygon(
        polygon([(x - w * 0.34, y + h), (x - w * 0.26, y + h * 0.18), (x, y), (x + w * 0.28, y + h * 0.20), (x + w * 0.36, y + h)]),
        fill=rgba(118, 112, 94, alpha),
        outline=rgba(42, 34, 24, round(alpha * 0.70)),
    )
    for line in range(4):
        ly = y + h * (0.34 + line * 0.12)
        draw.line([xy(x - w * 0.15, ly), xy(x + w * 0.15, ly - h * 0.02)], fill=rgba(42, 32, 22, round(alpha * 0.40)), width=max(1, round(2 * scale)))


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.38, w, h * 0.59), fill=rgba(224, 238, 218, 36))
    mist = mist.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(mist)

    for x, y, scale, count, seed in (
        (w * 0.07, h * 0.50, 0.70, 12, "dujiang-mid-bamboo-left"),
        (w * 0.91, h * 0.51, 0.74, 14, "dujiang-mid-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 132, seed)

    draw_tea_hut(draw, image, w * 0.08, h * 0.315, w * 0.17, h * 0.20, 170)
    draw_water_gate(draw, image, w * 0.40, h * 0.300, w * 0.20, h * 0.225, 188)
    draw_water_gate(draw, image, w * 0.62, h * 0.322, w * 0.16, h * 0.185, 158)
    draw_stone_marker(draw, w * 0.33, h * 0.460, 0.86, 150)
    draw_stone_marker(draw, w * 0.80, h * 0.465, 0.74, 132)

    draw.line([xy(w * 0.05, h * 0.532), xy(w * 0.95, h * 0.508)], fill=rgba(64, 44, 28, 132), width=5)
    draw.line([xy(w * 0.05, h * 0.555), xy(w * 0.95, h * 0.532)], fill=rgba(28, 18, 10, 86), width=3)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = h * 0.532 - h * 0.024 * t
        draw.line([xy(x, y - 24), xy(x - 5, y + 34)], fill=rgba(46, 30, 16, 132), width=4)

    for x, side in ((w * 0.31, -1.0), (w * 0.82, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.78, side, (76, 128, 76), 150)
    for x in (w * 0.14, w * 0.42, w * 0.57, w * 0.70):
        draw_lantern(draw, image, x, h * 0.485, 0.54)
    draw_boat(draw, image, w * 0.18, h * 0.580, 0.78, 142)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("dujiang-weir-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(10, 15, 10, 88))
    draw_willow(draw, w * 0.035, h * 0.800, 1.10, 1.0)
    draw_bamboo_cluster(draw, w * 0.14, h * 0.960, 0.78, 9, 168, "dujiang-front-left", True)
    draw_bamboo_cluster(draw, w * 0.91, h * 0.960, 0.78, 9, 164, "dujiang-front-right", True)
    for x0, x1, y in ((w * 0.00, w * 0.28, h * 0.858), (w * 0.68, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(64, 42, 26, 212), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(42, 28, 18, 218), width=5)

    for _ in range(120):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(48, 106, 44, rng.randint(42, 112)), width=1)
    for i in range(7):
        x = w * (0.30 + i * 0.055)
        y = h * (0.908 + (i % 2) * 0.014)
        draw.rectangle(box(x - 18, y - 20, x + 22, y + 18), fill=rgba(72, 50, 30, 122), outline=rgba(28, 18, 12, 116), width=2)
        draw.line([xy(x - 12, y - 3), xy(x + 15, y - 5)], fill=rgba(222, 190, 118, 52), width=1)

    spray = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(spray)
    sd.ellipse(box(w * 0.34, h * 0.50, w * 0.70, h * 0.70), fill=rgba(220, 244, 234, 32))
    sd.ellipse(box(-w * 0.18, h * 0.77, w * 0.32, h * 1.08), fill=rgba(218, 232, 208, 42))
    sd.ellipse(box(w * 0.66, h * 0.78, w * 1.16, h * 1.05), fill=rgba(212, 228, 206, 36))
    spray = spray.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(spray)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (142, 176, 162), (84, 108, 70))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.57, h * 0.15), h * 0.20, (230, 236, 176), 34)
    draw_mountain_band(draw, w, h, h * 0.34, h * 0.26, rgba(68, 104, 86, 72), "dujiang-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.43, h * 0.23, rgba(52, 84, 66, 96), "dujiang-mid-mountain")

    rng = random.Random("dujiang-weir-scene-v1")
    for i in range(12):
        x = w * (0.02 + i * 0.087)
        y = h * (0.16 + (i % 5) * 0.028)
        draw.ellipse(box(x - 66, y - 13, x + 84, y + 21), fill=rgba(220, 232, 210, 14 + (i % 4) * 5))
    for _ in range(88):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(160, 190, 94, rng.randint(16, 60)), width=1)

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
    print(f"OK generated Dujiang Weir DNF waterworks stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
