#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge
from generate_linan_dnf_water_city_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_arch_bridge,
    polygon,
    rgba,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_cart, draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_xindu_field_dnf_farmland_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "xindu_field_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "xindu_field_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "xindu_field_dnf_foreground_v1.png"


def draw_field_band(
    draw: ImageDraw.ImageDraw,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    color: tuple[int, int, int],
    alpha: int,
    seed: str,
) -> None:
    rng = random.Random(seed)
    draw.polygon(
        polygon([(x0, y0), (x1, y0 - 18), (x1 + 50, y1), (x0 - 52, y1 + 18)]),
        fill=rgba(color[0], color[1], color[2], alpha),
        outline=rgba(48, 72, 32, round(alpha * 0.45)),
    )
    for row in range(13):
        t = row / 12.0
        y = y0 + (y1 - y0) * t
        draw.line([xy(x0 - 28 + t * 18, y), xy(x1 + 30 - t * 22, y - 18)], fill=rgba(214, 220, 118, round(alpha * 0.24)), width=1)
    for _ in range(70):
        x = rng.uniform(x0, x1)
        y = rng.uniform(y0, y1)
        length = rng.uniform(8, 34)
        draw.line([xy(x, y), xy(x + rng.uniform(-6, 9), y - length)], fill=rgba(66, 132, 48, rng.randint(34, 92)), width=1)


def draw_haystack(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int) -> None:
    w = 72 * scale
    h = 66 * scale
    draw.ellipse(box(x - w * 0.50, y - h * 0.20, x + w * 0.52, y + h * 0.18), fill=rgba(92, 58, 26, round(alpha * 0.36)))
    draw.polygon(
        polygon([(x - w * 0.46, y + h * 0.08), (x - w * 0.18, y - h * 0.70), (x + w * 0.12, y - h * 0.92), (x + w * 0.46, y + h * 0.08)]),
        fill=rgba(184, 142, 68, alpha),
        outline=rgba(88, 56, 28, round(alpha * 0.64)),
    )
    for i in range(8):
        t = i / 7.0
        sx = x - w * 0.34 + w * 0.68 * t
        draw.line([xy(sx, y - h * 0.62 + math.sin(i) * 4 * scale), xy(sx + rng_offset(i) * 10 * scale, y + h * 0.04)], fill=rgba(236, 202, 104, round(alpha * 0.34)), width=1)


def rng_offset(index: int) -> float:
    return math.sin(index * 1.73) * 0.8


def draw_farmhouse(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.72, x + w * 0.94, y + h * 1.08), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.10, y + h * 0.35, x + w * 0.90, y + h), fill=rgba(168, 122, 68, alpha), outline=rgba(44, 28, 16, round(alpha * 0.72)))
    draw.polygon(
        polygon([(x - w * 0.07, y + h * 0.44), (x + w * 0.50, y), (x + w * 1.08, y + h * 0.44), (x + w * 0.94, y + h * 0.62), (x + w * 0.06, y + h * 0.64)]),
        fill=rgba(76, 58, 34, alpha),
        outline=rgba(24, 16, 10, alpha),
    )
    for tile in range(9):
        t = tile / 8.0
        tx = x + w * (0.06 + t * 0.88)
        draw.line([xy(tx, y + h * 0.26), xy(tx + w * 0.06, y + h * 0.58)], fill=rgba(30, 22, 14, round(alpha * 0.34)), width=1)
    draw.rectangle(box(x + w * 0.24, y + h * 0.57, x + w * 0.43, y + h), fill=rgba(48, 34, 22, round(alpha * 0.76)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.54, x + w * 0.78, y + h * 0.70), fill=rgba(44, 76, 58, 108), outline=rgba(24, 20, 14, 126))
    sign = box(x + w * 0.36, y + h * 0.365, x + w * 0.66, y + h * 0.475)
    draw.rectangle(sign, fill=rgba(54, 32, 16, 176), outline=rgba(226, 180, 90, 116), width=2)
    draw.line([xy(x + w * 0.42, y + h * 0.422), xy(x + w * 0.60, y + h * 0.405)], fill=rgba(246, 218, 126, 86), width=2)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("xindu-field-floor-v1")

    horizon = h * 0.470
    canal_top = h * 0.540
    canal_bottom = h * 0.635
    path_top = h * 0.595
    draw_field_band(draw, w * 0.03, horizon, w * 0.44, h * 0.610, (104, 150, 64), 92, "xindu-left-field")
    draw_field_band(draw, w * 0.54, horizon - 10, w * 0.97, h * 0.615, (116, 160, 68), 88, "xindu-right-field")
    draw.polygon(polygon([(0, canal_top), (w, canal_top - h * 0.018), (w, canal_bottom), (0, canal_bottom + h * 0.030)]), fill=rgba(58, 128, 116, 104), outline=rgba(22, 70, 64, 66))
    for band in range(16):
        t = band / 15.0
        y = canal_top + h * (0.010 + t * 0.080)
        drift = math.sin(band * 1.35) * 28
        draw.line([xy(w * 0.04 + drift, y), xy(w * 0.96 + drift * 0.20, y - h * 0.014)], fill=rgba(178, 230, 204, 24 + (band % 4) * 8), width=2)

    draw.polygon(
        polygon([(w * 0.08, path_top), (w * 0.92, path_top - h * 0.024), (w * 1.06, h + 24), (w * -0.06, h + 24)]),
        fill=rgba(146, 118, 72, 106),
        outline=rgba(58, 42, 28, 74),
    )
    for row in range(18):
        t = row / 17.0
        y = path_top + (t * t) * h * 0.39
        draw.line([xy(w * (0.08 - t * 0.14), y), xy(w * (0.92 + t * 0.13), y - h * 0.018)], fill=rgba(220, 196, 122, 28 + row * 3), width=max(1, round(1.5 + t * 2.2)))
    for col in range(24):
        t = col / 23.0
        start_x = w * (-0.02 + t * 1.04)
        target_x = w * (0.50 + math.sin(col * 0.72) * 0.09)
        draw.line([xy(start_x, h + 16), xy(target_x, horizon)], fill=rgba(72, 50, 32, 20 + int(abs(t - 0.5) * 34)), width=1)

    draw_arch_bridge(draw, image, w * 0.42, h * 0.548, w * 0.18, h * 0.075, 118)
    draw_plank_bridge(draw, image, w * 0.64, h * 0.558, w * 0.18, h * 0.046, 120)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.635 + t * 0.265)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(232, 232, 160, 11 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(222, 214, 128, 24 + lane * 3), width=2)

    for _ in range(260):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(path_top + 10, h * 0.99)
        if rng.random() < 0.44:
            r = rng.uniform(1.2, 4.0)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(126, 154, 72, rng.randint(28, 82)))
        else:
            length = rng.uniform(10, 58)
            angle = rng.uniform(-0.26, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.40)], fill=rgba(70, 58, 32, rng.randint(20, 58)), width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.39, w, h * 0.58), fill=rgba(218, 232, 188, 30))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(18)))

    for x, y, scale, count, seed in (
        (w * 0.07, h * 0.515, 0.70, 12, "xindu-mid-bamboo-left"),
        (w * 0.91, h * 0.515, 0.72, 13, "xindu-mid-bamboo-right"),
        (w * 0.30, h * 0.500, 0.54, 8, "xindu-mid-bamboo-small"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 128, seed)
    draw_farmhouse(draw, image, w * 0.10, h * 0.300, w * 0.18, h * 0.205, 176)
    draw_farmhouse(draw, image, w * 0.70, h * 0.292, w * 0.18, h * 0.210, 178)
    draw_farmhouse(draw, image, w * 0.43, h * 0.330, w * 0.14, h * 0.160, 142)
    for x, side in ((w * 0.34, -1.0), (w * 0.62, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.72, side, (80, 132, 62), 136)
    for x in (w * 0.20, w * 0.47, w * 0.76):
        draw_lantern(draw, image, x, h * 0.485, 0.44)
    draw_cart(draw, image, w * 0.60, h * 0.540, 0.60, 116)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("xindu-field-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(12, 17, 9, 90))
    draw_bamboo_cluster(draw, w * 0.02, h * 0.950, 0.78, 9, 182, "xindu-front-left", True)
    draw_bamboo_cluster(draw, w * 0.98, h * 0.950, 0.78, 9, 180, "xindu-front-right", True)
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.860), (w * 0.68, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(56, 42, 24, 204), width=8)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(34, 24, 14, 212), width=5)
    for i in range(8):
        draw_haystack(draw, w * (0.30 + i * 0.055), h * (0.915 + (i % 2) * 0.016), 0.48 + (i % 3) * 0.08, 128)
    for _ in range(120):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.070)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(58, 118, 48, rng.randint(38, 108)), width=1)

    haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    hd.ellipse(box(-w * 0.18, h * 0.78, w * 0.32, h * 1.08), fill=rgba(214, 226, 178, 34))
    hd.ellipse(box(w * 0.66, h * 0.78, w * 1.16, h * 1.06), fill=rgba(214, 226, 178, 32))
    image.alpha_composite(haze.filter(ImageFilter.GaussianBlur(24)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (142, 176, 146), (88, 112, 70))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.14), h * 0.20, (234, 236, 168), 34)
    draw_mountain_band(draw, w, h, h * 0.34, h * 0.22, rgba(72, 108, 82, 70), "xindu-far-hills")
    draw_mountain_band(draw, w, h, h * 0.42, h * 0.19, rgba(54, 88, 62, 92), "xindu-mid-hills")

    rng = random.Random("xindu-field-scene-v1")
    for i in range(12):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.10, h * 0.30)
        r = rng.uniform(34, 78)
        draw.ellipse(box(x - r, y - r * 0.24, x + r, y + r * 0.24), fill=rgba(224, 238, 206, rng.randint(20, 46)))
    for _ in range(100):
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
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 56))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 28))
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
    print(f"OK generated Xindu field DNF farmland stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
