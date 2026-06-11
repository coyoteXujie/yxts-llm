#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge
from generate_changan_dnf_west_market_stage_assets import draw_awning, draw_market_house
from generate_linan_dnf_water_city_stage_assets import draw_arch_bridge
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
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_chengdu_dnf_tianfu_market_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "chengdu_dnf_tianfu_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "chengdu_dnf_tianfu_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "chengdu_dnf_tianfu_foreground_v1.png"


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("chengdu-tianfu-floor-v1")

    horizon = h * 0.47
    canal_top = h * 0.535
    canal_bottom = h * 0.655
    street_top = h * 0.59
    draw.polygon(polygon([(0, canal_top), (w, canal_top - h * 0.018), (w, canal_bottom), (0, canal_bottom + h * 0.035)]), fill=rgba(44, 112, 104, 112))
    for band in range(15):
        t = band / 14.0
        y = canal_top + h * (0.012 + t * 0.10)
        drift = math.sin(band * 1.41) * 24
        draw.line([xy(w * 0.06 + drift, y), xy(w * 0.94 + drift * 0.22, y - h * 0.016)], fill=rgba(172, 228, 210, 28 + (band % 4) * 8), width=2)

    draw.polygon(
        polygon([(w * 0.04, horizon), (w * 0.96, horizon - h * 0.018), (w * 0.92, street_top), (w * 0.08, street_top + h * 0.035)]),
        fill=rgba(122, 136, 72, 72),
    )
    draw.polygon(
        polygon([(w * 0.06, street_top), (w * 0.94, street_top - h * 0.018), (w * 1.06, h + 24), (w * -0.06, h + 24)]),
        fill=rgba(154, 124, 74, 96),
        outline=rgba(58, 42, 26, 72),
    )
    for row in range(20):
        t = row / 19.0
        y = street_top + (t * t) * h * 0.38
        draw.line([xy(w * (0.04 - t * 0.10), y), xy(w * (0.96 + t * 0.10), y - h * 0.018)], fill=rgba(82, 52, 32, round(82 - t * 26)), width=max(1, round(1.2 + t * 2.4)))
    for col in range(30):
        t = col / 29.0
        start_x = w * (-0.02 + t * 1.04)
        target_x = w * (0.50 + math.sin(col * 0.68) * 0.080)
        draw.line([xy(start_x, h + 16), xy(target_x, horizon - h * 0.020)], fill=rgba(68, 44, 28, 22 + int(abs(t - 0.5) * 34)), width=1)

    draw_arch_bridge(draw, image, w * 0.39, h * 0.548, w * 0.21, h * 0.088, 126)
    draw_plank_bridge(draw, image, w * 0.61, h * 0.565, w * 0.20, h * 0.050, 126)

    for cx, cy, pw, ph, color in (
        (w * 0.25, h * 0.575, w * 0.16, h * 0.050, (86, 146, 94)),
        (w * 0.43, h * 0.565, w * 0.16, h * 0.050, (196, 146, 58)),
        (w * 0.59, h * 0.568, w * 0.15, h * 0.050, (68, 132, 130)),
        (w * 0.74, h * 0.575, w * 0.15, h * 0.050, (158, 72, 128)),
    ):
        draw.polygon(polygon([(cx - pw * 0.52, cy), (cx + pw * 0.48, cy - ph * 0.10), (cx + pw * 0.58, cy + ph * 0.50), (cx - pw * 0.45, cy + ph * 0.60)]), fill=rgba(color[0], color[1], color[2], 58), outline=rgba(246, 224, 150, 78))

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.635 + t * 0.265)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(236, 232, 166, 11 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(226, 218, 132, 25 + lane * 3), width=2)

    for _ in range(210):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(street_top + 10, h * 0.99)
        if rng.random() < 0.34:
            r = rng.uniform(1.4, 4.2)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(126, 154, 72, rng.randint(30, 88)))
        else:
            length = rng.uniform(10, 62)
            angle = rng.uniform(-0.24, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.40)], fill=rgba(70, 58, 32, rng.randint(20, 58)), width=1)
    return image


def draw_herb_stall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw.rectangle(box(x + w * 0.05, y + h * 0.42, x + w * 0.95, y + h), fill=rgba(128, 88, 48, alpha), outline=rgba(42, 26, 16, round(alpha * 0.74)))
    draw_awning(draw, image, x, y + h * 0.18, w, h * 0.32, (74, 142, 82), round(alpha * 0.88))
    for i in range(5):
        px = x + w * (0.16 + i * 0.17)
        py = y + h * 0.62 + (i % 2) * h * 0.06
        draw.rectangle(box(px - w * 0.045, py - h * 0.06, px + w * 0.045, py + h * 0.06), fill=rgba(82, 46, 24, 154), outline=rgba(214, 176, 92, 68))
        draw.line([xy(px, py - h * 0.06), xy(px + w * 0.020, py - h * 0.18)], fill=rgba(42, 108, 46, 118), width=2)
        draw.ellipse(box(px + w * 0.010, py - h * 0.22, px + w * 0.055, py - h * 0.15), fill=rgba(106, 176, 82, 104))
    draw.rectangle(box(x + w * 0.32, y + h * 0.34, x + w * 0.68, y + h * 0.45), fill=rgba(66, 34, 18, 174), outline=rgba(236, 196, 98, 118), width=2)
    draw.line([xy(x + w * 0.38, y + h * 0.395), xy(x + w * 0.62, y + h * 0.375)], fill=rgba(250, 226, 132, 88), width=2)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.40, w, h * 0.58), fill=rgba(218, 232, 190, 30))
    mist = mist.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(mist)

    for x, y, scale, count, seed in (
        (w * 0.05, h * 0.51, 0.68, 12, "chengdu-mid-bamboo-left"),
        (w * 0.93, h * 0.51, 0.72, 14, "chengdu-mid-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 126, seed)

    draw_gate_tower(draw, image, w * 0.50, h * 0.480, w * 0.27, h * 0.31, 208)
    houses = [
        (w * 0.04, h * 0.275, w * 0.16, h * 0.225, (198, 150, 88), (214, 128, 50), (90, 142, 80)),
        (w * 0.20, h * 0.300, w * 0.15, h * 0.200, (184, 138, 90), (82, 134, 138), (194, 128, 44)),
        (w * 0.65, h * 0.292, w * 0.15, h * 0.210, (202, 154, 94), (206, 98, 46), (84, 138, 80)),
        (w * 0.80, h * 0.266, w * 0.16, h * 0.230, (210, 162, 98), (130, 74, 140), (206, 136, 50)),
    ]
    for args in houses:
        draw_market_house(draw, image, *args)

    draw_herb_stall(draw, image, w * 0.33, h * 0.375, w * 0.17, h * 0.135, 176)
    draw_herb_stall(draw, image, w * 0.51, h * 0.382, w * 0.16, h * 0.125, 160)

    for x in (w * 0.10, w * 0.25, w * 0.39, w * 0.60, w * 0.75, w * 0.90):
        draw_lantern(draw, image, x, h * (0.39 + (int(x) % 2) * 0.018), 0.72)
    for x, side in ((w * 0.30, -1.0), (w * 0.70, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.80, side, (76, 132, 66), 158)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("chengdu-tianfu-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(12, 16, 9, 90))
    draw_bamboo_cluster(draw, w * 0.02, h * 0.94, 0.82, 10, 190, "chengdu-front-left", True)
    draw_bamboo_cluster(draw, w * 0.98, h * 0.94, 0.82, 10, 184, "chengdu-front-right", True)
    draw_cart(draw, image, w * 0.18, h * 0.890, 0.82, 158)
    draw_cart(draw, image, w * 0.84, h * 0.895, 0.76, 148)

    for x0, x1, y in ((w * 0.00, w * 0.23, h * 0.86), (w * 0.70, w * 0.99, h * 0.845)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(54, 40, 22, 206), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(34, 24, 14, 214), width=5)

    for i in range(8):
        x = w * (0.28 + i * 0.065)
        y = h * (0.918 + (i % 2) * 0.014)
        draw.rectangle(box(x - 20, y - 22, x + 24, y + 18), fill=rgba(76, 48, 26, 118), outline=rgba(28, 18, 12, 108), width=2)
        if i % 2 == 0:
            draw.ellipse(box(x - 10, y - 32, x + 14, y - 10), fill=rgba(104, 154, 72, 82))

    for _ in range(95):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.064)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(56, 112, 46, rng.randint(38, 102)), width=1)

    haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    hd.ellipse(box(-w * 0.16, h * 0.78, w * 0.30, h * 1.08), fill=rgba(214, 226, 178, 34))
    hd.ellipse(box(w * 0.68, h * 0.78, w * 1.14, h * 1.06), fill=rgba(214, 226, 178, 32))
    haze = haze.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(haze)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (142, 172, 146), (90, 112, 70))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.14), h * 0.20, (232, 236, 168), 34)
    draw_mountain_band(draw, w, h, h * 0.34, h * 0.22, rgba(72, 108, 82, 72), "chengdu-far-hills")
    draw_mountain_band(draw, w, h, h * 0.42, h * 0.20, rgba(54, 88, 62, 94), "chengdu-mid-hills")

    rng = random.Random("chengdu-tianfu-scene-v1")
    for i in range(12):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.10, h * 0.30)
        r = rng.uniform(34, 78)
        draw.ellipse(box(x - r, y - r * 0.24, x + r, y + r * 0.24), fill=rgba(224, 238, 206, rng.randint(20, 46)))
    for _ in range(90):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(158, 194, 92, rng.randint(16, 58)), width=1)

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
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
    print(f"OK generated Chengdu DNF Tianfu market stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
