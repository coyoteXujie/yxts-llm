#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band
from generate_linan_dnf_water_city_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_arch_bridge,
    draw_boat,
    draw_willow,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern
from generate_minjiang_river_stage_assets import draw_ferry_pier


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_hanjiang_river_dnf_clear_ferry_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "hanjiang_river_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "hanjiang_river_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "hanjiang_river_dnf_foreground_v1.png"


def draw_river_glints(draw: ImageDraw.ImageDraw, w: int, h: int, top: float, bottom: float, seed: str, alpha: int) -> None:
    rng = random.Random(seed)
    for band in range(32):
        t = band / 31.0
        y = top + (bottom - top) * (0.05 + t * 0.86)
        drift = math.sin(band * 1.07) * w * 0.035
        draw.line([xy(w * 0.03 + drift, y), xy(w * 0.96 + drift * 0.20, y - h * 0.018)], fill=rgba(194, 240, 228, rng.randint(24, alpha)), width=2)
    for _ in range(92):
        x = rng.uniform(w * 0.04, w * 0.97)
        y = rng.uniform(top + 18, bottom - 12)
        draw.arc(box(x - 38, y - 8, x + 54, y + 10), 5, 174, fill=rgba(232, 248, 236, rng.randint(20, 62)), width=1)


def draw_reed_cluster(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, count: int, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    for i in range(count):
        ox = rng.uniform(-28, 28) * scale
        height = rng.uniform(54, 118) * scale
        lean = rng.uniform(-16, 18) * scale
        stem_alpha = rng.randint(round(alpha * 0.55), alpha)
        draw.line([xy(x + ox, y), xy(x + ox + lean, y - height)], fill=rgba(56, 92, 52, stem_alpha), width=max(1, round(2 * scale)))
        if i % 3 == 0:
            tip_x = x + ox + lean
            tip_y = y - height
            draw.ellipse(box(tip_x - 4 * scale, tip_y - 12 * scale, tip_x + 5 * scale, tip_y + 6 * scale), fill=rgba(146, 106, 58, round(alpha * 0.58)))


def draw_sandbar(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    points = [
        (x, y + h * 0.52),
        (x + w * 0.20, y + h * 0.18),
        (x + w * 0.58, y),
        (x + w, y + h * 0.34),
        (x + w * 0.82, y + h * 0.72),
        (x + w * 0.32, y + h * 0.84),
    ]
    draw.polygon(polygon(points), fill=rgba(184, 158, 94, alpha), outline=rgba(96, 72, 40, round(alpha * 0.48)))
    for _ in range(44):
        px = rng.uniform(x + w * 0.06, x + w * 0.92)
        py = rng.uniform(y + h * 0.16, y + h * 0.78)
        length = rng.uniform(8, 26)
        draw.line([xy(px, py), xy(px + length, py - rng.uniform(1, 5))], fill=rgba(116, 92, 48, rng.randint(18, 52)), width=1)


def draw_rice_field_band(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw.polygon(polygon([(x, y + h * 0.18), (x + w, y), (x + w * 0.95, y + h), (x + w * 0.04, y + h * 0.95)]), fill=rgba(116, 142, 66, alpha), outline=rgba(48, 76, 34, round(alpha * 0.38)))
    for row in range(6):
        t = row / 5.0
        yy = y + h * (0.16 + t * 0.66)
        draw.line([xy(x + w * 0.03, yy), xy(x + w * 0.96, yy - h * 0.12)], fill=rgba(214, 208, 118, round(alpha * 0.28)), width=1)
    for col in range(9):
        t = col / 8.0
        xx = x + w * (0.06 + t * 0.86)
        draw.line([xy(xx, y + h * 0.15), xy(xx + w * 0.05, y + h * 0.92)], fill=rgba(58, 92, 38, round(alpha * 0.28)), width=1)


def draw_farm_house(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.05, y + h * 0.78, x + w * 0.96, y + h * 1.08), fill=rgba(0, 0, 0, 46))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.12, y + h * 0.42, x + w * 0.88, y + h), fill=rgba(148, 114, 72, alpha), outline=rgba(46, 28, 16, round(alpha * 0.70)))
    draw.polygon(
        polygon([(x - w * 0.06, y + h * 0.46), (x + w * 0.50, y), (x + w * 1.06, y + h * 0.46), (x + w * 0.92, y + h * 0.62), (x + w * 0.08, y + h * 0.64)]),
        fill=rgba(92, 70, 38, alpha),
        outline=rgba(30, 18, 10, round(alpha * 0.94)),
    )
    draw.rectangle(box(x + w * 0.26, y + h * 0.62, x + w * 0.44, y + h), fill=rgba(48, 30, 18, round(alpha * 0.76)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.56, x + w * 0.76, y + h * 0.72), fill=rgba(50, 92, 86, 102), outline=rgba(26, 18, 12, 120))


def draw_secret_sandbar_room(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw_sandbar(draw, x - w * 0.15, y + h * 0.50, w * 1.32, h * 0.40, round(alpha * 0.54), "hanjiang-secret-sandbar")
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x + w * 0.04, y + h * 0.66, x + w * 0.92, y + h * 1.06), fill=rgba(0, 0, 0, 52))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    draw.rectangle(box(x + w * 0.24, y + h * 0.40, x + w * 0.78, y + h * 0.86), fill=rgba(88, 76, 56, alpha), outline=rgba(28, 22, 16, round(alpha * 0.82)), width=2)
    draw.polygon(polygon([(x + w * 0.12, y + h * 0.42), (x + w * 0.52, y + h * 0.15), (x + w * 0.88, y + h * 0.42), (x + w * 0.80, y + h * 0.54), (x + w * 0.20, y + h * 0.54)]), fill=rgba(70, 90, 62, alpha), outline=rgba(24, 30, 18, alpha))
    draw.rectangle(box(x + w * 0.42, y + h * 0.56, x + w * 0.62, y + h * 0.86), fill=rgba(24, 28, 22, round(alpha * 0.82)), outline=rgba(204, 166, 90, round(alpha * 0.42)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("hanjiang-river-floor-v1")
    river_top = h * 0.425
    river_bottom = h * 0.770
    bank_top = h * 0.632

    river = [
        (w * -0.05, river_top + h * 0.020),
        (w * 0.25, river_top - h * 0.025),
        (w * 0.54, river_top + h * 0.018),
        (w * 0.82, river_top - h * 0.010),
        (w * 1.05, river_top + h * 0.042),
        (w * 1.05, river_bottom),
        (w * 0.72, river_bottom + h * 0.052),
        (w * 0.42, river_bottom - h * 0.010),
        (w * 0.10, river_bottom + h * 0.042),
        (w * -0.05, river_bottom - h * 0.020),
    ]
    draw.polygon(polygon(river), fill=rgba(42, 132, 146, 146), outline=rgba(18, 68, 82, 82))
    draw_river_glints(draw, w, h, river_top, river_bottom, "hanjiang-wide-river", 74)
    draw_sandbar(draw, w * 0.39, h * 0.505, w * 0.22, h * 0.070, 96, "hanjiang-mid-sandbar")
    draw_sandbar(draw, w * 0.68, h * 0.565, w * 0.19, h * 0.060, 72, "hanjiang-right-sandbar")

    draw.polygon(polygon([(w * -0.02, bank_top), (w * 0.46, bank_top - h * 0.030), (w * 1.06, h + 28), (w * -0.06, h + 28)]), fill=rgba(148, 126, 76, 112), outline=rgba(60, 42, 26, 70))
    for row in range(20):
        t = row / 19.0
        y = bank_top + h * 0.035 + (t * t) * h * 0.32
        draw.line([xy(w * (-0.04 - t * 0.07), y), xy(w * (0.56 + t * 0.52), y - h * 0.020)], fill=rgba(226, 206, 136, 24 + row * 3), width=max(1, round(1.4 + t * 2.5)))
    draw_ferry_pier(draw, image, w * 0.18, h * 0.585, w * 0.26, h * 0.092, 166)
    draw_arch_bridge(draw, image, w * 0.66, h * 0.575, w * 0.25, h * 0.100, 128)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.67 + t * 0.25)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(218, 234, 166, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(226, 208, 132, 23 + lane * 3), width=2)
    for _ in range(210):
        x = rng.uniform(w * 0.02, w * 0.99)
        y = rng.uniform(bank_top + 8, h * 0.99)
        if rng.random() < 0.55:
            length = rng.uniform(12, 60)
            angle = rng.uniform(-0.24, 0.22)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.36)], fill=rgba(52, 96, 40, rng.randint(20, 68)), width=1)
        else:
            r = rng.uniform(1.2, 4.2)
            draw.ellipse(box(x - r, y - r * 0.50, x + r, y + r * 0.50), fill=rgba(132, 154, 78, rng.randint(28, 86)))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.355, w, h * 0.575), fill=rgba(220, 240, 216, 34))
    md.ellipse(box(w * 0.12, h * 0.34, w * 0.78, h * 0.60), fill=rgba(222, 238, 220, 24))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(18)))

    draw_rice_field_band(draw, w * 0.02, h * 0.365, w * 0.30, h * 0.105, 114)
    draw_rice_field_band(draw, w * 0.72, h * 0.365, w * 0.25, h * 0.100, 102)
    draw_farm_house(draw, image, w * 0.09, h * 0.285, w * 0.15, h * 0.185, 168)
    draw_farm_house(draw, image, w * 0.76, h * 0.292, w * 0.14, h * 0.172, 148)
    draw_secret_sandbar_room(draw, image, w * 0.47, h * 0.406, w * 0.14, h * 0.125, 136)

    for x, y, scale, count, seed in (
        (w * 0.05, h * 0.520, 0.64, 12, "hanjiang-reeds-left"),
        (w * 0.31, h * 0.520, 0.50, 8, "hanjiang-reeds-pier"),
        (w * 0.91, h * 0.520, 0.70, 14, "hanjiang-reeds-right"),
    ):
        draw_reed_cluster(draw, x, y, scale, count, 136, seed)
    draw_bamboo_cluster(draw, w * 0.15, h * 0.505, 0.56, 8, 112, "hanjiang-mid-bamboo-left")
    draw_bamboo_cluster(draw, w * 0.86, h * 0.505, 0.56, 9, 116, "hanjiang-mid-bamboo-right")
    draw_boat(draw, image, w * 0.24, h * 0.555, 0.82, 168)
    draw_boat(draw, image, w * 0.58, h * 0.548, 0.74, 132)
    draw_boat(draw, image, w * 0.80, h * 0.588, 0.76, 150)

    for x, side in ((w * 0.22, -1.0), (w * 0.48, 1.0), (w * 0.73, -1.0)):
        draw_flag(draw, x, h * 0.500, 0.70, side, (74, 128, 92), 138)
    for x in (w * 0.20, w * 0.38, w * 0.68):
        draw_lantern(draw, image, x, h * 0.480, 0.44)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("hanjiang-river-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(10, 16, 10, 90))
    draw_willow(draw, w * 0.045, h * 0.795, 1.08, 1.0)
    draw_willow(draw, w * 0.965, h * 0.800, 1.04, -1.0)
    for x, y, scale, count, seed in (
        (w * 0.13, h * 0.962, 0.82, 18, "hanjiang-front-reed-left"),
        (w * 0.86, h * 0.958, 0.86, 19, "hanjiang-front-reed-right"),
    ):
        draw_reed_cluster(draw, x, y, scale, count, 190, seed)
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.855), (w * 0.66, w * 0.99, h * 0.842)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(60, 40, 24, 214), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 2)], fill=rgba(26, 18, 12, 168), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(40, 26, 16, 220), width=5)
    for _ in range(118):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        color = rgba(46, 104, 42, rng.randint(42, 114)) if rng.random() < 0.82 else rgba(138, 112, 60, rng.randint(38, 92))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    for i in range(8):
        x = w * (0.32 + i * 0.048)
        y = h * (0.912 + (i % 3) * 0.012)
        draw.rectangle(box(x - 15, y - 18, x + 20, y + 17), fill=rgba(70, 48, 28, 126), outline=rgba(28, 18, 12, 116), width=2)
        if i % 2 == 0:
            draw.arc(box(x - 15, y - 30, x + 20, y - 6), 190, 348, fill=rgba(214, 190, 118, 62), width=2)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.18, h * 0.74, w * 0.34, h * 1.08), fill=rgba(218, 232, 208, 42))
    fd.ellipse(box(w * 0.64, h * 0.76, w * 1.14, h * 1.06), fill=rgba(212, 228, 206, 40))
    fd.ellipse(box(w * 0.25, h * 0.52, w * 0.82, h * 0.72), fill=rgba(220, 244, 234, 22))
    image.alpha_composite(fog.filter(ImageFilter.GaussianBlur(24)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (142, 184, 172), (84, 110, 72))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.56, h * 0.14), h * 0.22, (232, 238, 180), 34)
    draw_mountain_band(draw, w, h, h * 0.310, h * 0.245, rgba(78, 112, 94, 54), "hanjiang-far-bank")
    draw_mountain_band(draw, w, h, h * 0.405, h * 0.210, rgba(58, 94, 72, 76), "hanjiang-near-bank")
    rng = random.Random("hanjiang-river-scene-v1")
    cloud_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(cloud_layer)
    for i in range(14):
        x = w * (0.018 + i * 0.076)
        y = h * (0.13 + (i % 5) * 0.028)
        cd.ellipse(box(x - 86, y - 18, x + 102, y + 24), fill=rgba(218, 236, 214, 10 + (i % 4) * 4))
        cd.ellipse(box(x - 44, y - 10, x + 66, y + 15), fill=rgba(238, 246, 226, 8 + (i % 3) * 3))
    image.alpha_composite(cloud_layer.filter(ImageFilter.GaussianBlur(8)))
    for _ in range(86):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.70)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(160, 194, 96, rng.randint(15, 54)), width=1)

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 56))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 28))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Hanjiang river DNF clear ferry stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
