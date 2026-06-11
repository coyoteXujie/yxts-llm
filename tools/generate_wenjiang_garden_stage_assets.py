#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_flower_sect_garden_stage_assets import draw_market_stall, draw_plum_blossoms, draw_stone_lantern
from generate_linan_dnf_water_city_stage_assets import (
    SIZE,
    add_glow,
    box,
    polygon,
    rgba,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_lantern
from generate_xindu_field_stage_assets import draw_farmhouse


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_wenjiang_garden_dnf_flower_fields_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "wenjiang_garden_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "wenjiang_garden_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "wenjiang_garden_dnf_foreground_v1.png"


def draw_flower_rows(
    draw: ImageDraw.ImageDraw,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    palette: list[tuple[int, int, int]],
    alpha: int,
    seed: str,
) -> None:
    rng = random.Random(seed)
    draw.polygon(
        polygon([(x0, y0), (x1, y0 - 20), (x1 + 48, y1), (x0 - 52, y1 + 22)]),
        fill=rgba(82, 126, 62, round(alpha * 0.62)),
        outline=rgba(42, 76, 34, round(alpha * 0.46)),
    )
    for row in range(14):
        t = row / 13.0
        y = y0 + (y1 - y0) * t
        color = palette[row % len(palette)]
        draw.line([xy(x0 - 26 + t * 18, y), xy(x1 + 30 - t * 22, y - 18)], fill=rgba(color[0], color[1], color[2], round(alpha * 0.50)), width=2)
    for _ in range(150):
        x = rng.uniform(x0, x1)
        y = rng.uniform(y0, y1)
        color = palette[rng.randrange(len(palette))]
        r = rng.uniform(1.2, 3.4)
        draw.ellipse(box(x - r, y - r * 0.70, x + r, y + r * 0.70), fill=rgba(color[0], color[1], color[2], rng.randint(46, 118)))
        if rng.random() < 0.38:
            draw.line([xy(x, y + 2), xy(x + rng.uniform(-3, 4), y + rng.uniform(10, 24))], fill=rgba(48, 108, 48, rng.randint(30, 78)), width=1)


def draw_flower_basket(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    w = 64 * scale
    h = 44 * scale
    draw.ellipse(box(x - w * 0.52, y - h * 0.18, x + w * 0.52, y + h * 0.22), fill=rgba(68, 40, 20, round(alpha * 0.34)))
    draw.polygon(
        polygon([(x - w * 0.46, y - h * 0.05), (x + w * 0.44, y - h * 0.12), (x + w * 0.32, y + h * 0.52), (x - w * 0.34, y + h * 0.56)]),
        fill=rgba(120, 72, 36, alpha),
        outline=rgba(38, 22, 12, round(alpha * 0.72)),
    )
    draw.arc(box(x - w * 0.38, y - h * 0.62, x + w * 0.38, y + h * 0.20), 205, 335, fill=rgba(58, 34, 18, round(alpha * 0.80)), width=max(1, round(3 * scale)))
    for i in range(18):
        px = x + rng.uniform(-w * 0.36, w * 0.36)
        py = y - rng.uniform(h * 0.20, h * 0.54)
        color = (222, 96, 126) if i % 3 == 0 else ((236, 184, 82) if i % 3 == 1 else (176, 116, 202))
        r = rng.uniform(2.0, 4.0) * scale
        draw.ellipse(box(px - r, py - r, px + r, py + r), fill=rgba(color[0], color[1], color[2], round(alpha * 0.84)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("wenjiang-garden-floor-v1")

    horizon = h * 0.470
    path_top = h * 0.595
    palette_left = [(214, 98, 128), (238, 176, 88), (184, 132, 204), (228, 210, 122)]
    palette_right = [(226, 116, 152), (246, 194, 98), (150, 184, 112), (198, 126, 198)]
    draw_flower_rows(draw, w * 0.03, horizon, w * 0.43, h * 0.625, palette_left, 112, "wenjiang-left-flowers")
    draw_flower_rows(draw, w * 0.55, horizon - 12, w * 0.98, h * 0.625, palette_right, 112, "wenjiang-right-flowers")
    draw.polygon(
        polygon([(w * 0.08, path_top), (w * 0.92, path_top - h * 0.024), (w * 1.06, h + 24), (w * -0.06, h + 24)]),
        fill=rgba(152, 118, 82, 100),
        outline=rgba(62, 42, 30, 72),
    )
    for row in range(18):
        t = row / 17.0
        y = path_top + (t * t) * h * 0.39
        draw.line([xy(w * (0.08 - t * 0.14), y), xy(w * (0.92 + t * 0.13), y - h * 0.018)], fill=rgba(220, 190, 130, 26 + row * 3), width=max(1, round(1.4 + t * 2.2)))
    for col in range(24):
        t = col / 23.0
        start_x = w * (-0.02 + t * 1.04)
        target_x = w * (0.50 + math.sin(col * 0.72) * 0.09)
        draw.line([xy(start_x, h + 16), xy(target_x, horizon)], fill=rgba(72, 50, 32, 18 + int(abs(t - 0.5) * 32)), width=1)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.635 + t * 0.265)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(242, 218, 170, 12 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(226, 202, 142, 24 + lane * 3), width=2)
    for _ in range(230):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(path_top + 10, h * 0.99)
        if rng.random() < 0.54:
            color = palette_left[rng.randrange(len(palette_left))]
            r = rng.uniform(1.1, 3.6)
            draw.ellipse(box(x - r, y - r * 0.65, x + r, y + r * 0.65), fill=rgba(color[0], color[1], color[2], rng.randint(28, 86)))
        else:
            length = rng.uniform(10, 54)
            angle = rng.uniform(-0.26, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.40)], fill=rgba(68, 72, 34, rng.randint(20, 58)), width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.39, w, h * 0.58), fill=rgba(232, 222, 196, 30))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(18)))

    draw_plum_blossoms(draw, image, w * 0.08, h * 0.520, 0.72, 126, "wenjiang-left-plum")
    draw_plum_blossoms(draw, image, w * 0.91, h * 0.520, 0.70, 124, "wenjiang-right-plum")
    draw_farmhouse(draw, image, w * 0.15, h * 0.310, w * 0.17, h * 0.195, 164)
    draw_farmhouse(draw, image, w * 0.68, h * 0.305, w * 0.18, h * 0.200, 168)
    draw_market_stall(draw, image, w * 0.40, h * 0.405, w * 0.16, h * 0.130, 158)
    draw_market_stall(draw, image, w * 0.54, h * 0.410, w * 0.15, h * 0.122, 148)
    draw_stone_lantern(draw, image, w * 0.34, h * 0.540, 0.72, 118)
    draw_stone_lantern(draw, image, w * 0.74, h * 0.545, 0.66, 112)
    for x in (w * 0.22, w * 0.48, w * 0.64, w * 0.78):
        draw_lantern(draw, image, x, h * 0.492, 0.44)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("wenjiang-garden-foreground-v1")
    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(18, 12, 12, 86))
    draw_plum_blossoms(draw, image, w * 0.02, h * 0.950, 1.02, 188, "wenjiang-front-left-plum")
    draw_plum_blossoms(draw, image, w * 0.98, h * 0.950, 0.98, 184, "wenjiang-front-right-plum")
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.860), (w * 0.68, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(72, 42, 30, 198), width=8)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(42, 24, 16, 206), width=5)
    for i in range(9):
        draw_flower_basket(draw, w * (0.29 + i * 0.055), h * (0.914 + (i % 2) * 0.016), 0.55 + (i % 3) * 0.08, 138, f"wenjiang-basket-{i}")
    for _ in range(110):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        color = (226, rng.randint(92, 170), rng.randint(126, 204))
        r = rng.uniform(1.2, 3.4)
        draw.ellipse(box(x - r, y - r * 0.62, x + r, y + r * 0.62), fill=rgba(color[0], color[1], color[2], rng.randint(34, 96)))
    haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    hd.ellipse(box(-w * 0.18, h * 0.77, w * 0.34, h * 1.08), fill=rgba(236, 212, 210, 34))
    hd.ellipse(box(w * 0.64, h * 0.77, w * 1.16, h * 1.06), fill=rgba(236, 212, 210, 32))
    image.alpha_composite(haze.filter(ImageFilter.GaussianBlur(24)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (164, 174, 148), (98, 104, 70))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.14), h * 0.20, (238, 228, 170), 34)
    for band, color in enumerate(((76, 108, 78, 62), (64, 94, 66, 82), (54, 82, 58, 98))):
        base_y = h * (0.31 + band * 0.065)
        points = [(0, base_y + h * 0.12)]
        for i in range(14):
            x = w * i / 13.0
            y = base_y + math.sin(i * 1.08 + band) * h * 0.024
            points.append((x, y))
        points.append((w, base_y + h * 0.12))
        draw.polygon(polygon(points), fill=rgba(color[0], color[1], color[2], color[3]))
    rng = random.Random("wenjiang-garden-scene-v1")
    for i in range(13):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.10, h * 0.31)
        r = rng.uniform(34, 82)
        draw.ellipse(box(x - r, y - r * 0.24, x + r, y + r * 0.24), fill=rgba(238, 226, 210, rng.randint(18, 44)))
    for _ in range(110):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(198, 144, 118, rng.randint(16, 58)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 26))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 52))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 26))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 26))
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
    print(f"OK generated Wenjiang garden DNF flower fields stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
