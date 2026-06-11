#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_mountain_band
from generate_hanjiang_river_stage_assets import draw_reed_cluster, draw_river_glints, draw_sandbar
from generate_linan_dnf_water_city_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_boat,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_yunmeng_marsh_dnf_mist_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "yunmeng_marsh_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "yunmeng_marsh_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "yunmeng_marsh_dnf_foreground_v1.png"


def draw_lotus_patch(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    for _ in range(24):
        px = rng.uniform(x, x + w)
        py = rng.uniform(y, y + h)
        rx = rng.uniform(10, 28)
        ry = rng.uniform(4, 11)
        draw.ellipse(box(px - rx, py - ry, px + rx, py + ry), fill=rgba(54, 116, 62, rng.randint(round(alpha * 0.35), alpha)), outline=rgba(22, 52, 28, rng.randint(30, 78)))
        if rng.random() < 0.22:
            draw.ellipse(box(px - 4, py - 10, px + 5, py - 2), fill=rgba(210, 146, 176, rng.randint(64, 112)))


def draw_poison_mist(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(22):
        cx = rng.uniform(-w * 0.05, w * 1.05)
        cy = y + rng.uniform(-height * 0.38, height * 0.38)
        rx = rng.uniform(w * 0.045, w * 0.150)
        ry = rng.uniform(height * 0.18, height * 0.50)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(158, 196, 124, rng.randint(round(alpha * 0.34), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.16))))


def draw_boardwalk(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(polygon([(x - 34, y + h * 0.48), (x + w + 42, y + h * 0.20), (x + w + 46, y + h * 0.62), (x - 38, y + h * 0.92)]), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    rail_a = []
    rail_b = []
    for i in range(18):
        t = i / 17.0
        px = x + w * t
        wave = math.sin(t * math.pi * 1.4) * h * 0.10
        rail_a.append(xy(px, y + h * (0.18 + 0.05 * t) + wave))
        rail_b.append(xy(px, y + h * (0.50 + 0.08 * t) + wave))
    deck = []
    for i in range(18):
        t = i / 17.0
        px = x + w * t
        wave = math.sin(t * math.pi * 1.4) * h * 0.10
        deck.append((px, y + h * (0.26 + 0.05 * t) + wave))
    for i in range(17, -1, -1):
        t = i / 17.0
        px = x + w * t
        wave = math.sin(t * math.pi * 1.4) * h * 0.10
        deck.append((px, y + h * (0.62 + 0.07 * t) + wave))
    draw.polygon(polygon(deck), fill=rgba(84, 58, 34, alpha), outline=rgba(22, 14, 8, round(alpha * 0.90)))
    draw.line(rail_a, fill=rgba(42, 28, 16, round(alpha * 0.88)), width=4)
    draw.line(rail_b, fill=rgba(42, 28, 16, round(alpha * 0.78)), width=3)
    for plank in range(16):
        t = plank / 15.0
        px = x + w * t + rng.uniform(-4, 4)
        yy = y + h * (0.30 + 0.08 * t + 0.10 * math.sin(t * math.pi * 1.4))
        draw.line([xy(px, yy - h * 0.10), xy(px + 10, yy + h * 0.34)], fill=rgba(24, 14, 8, round(alpha * 0.48)), width=2)
        if plank % 3 == 0:
            draw.line([xy(px, yy - h * 0.30), xy(px - 5, yy + h * 0.50)], fill=rgba(34, 22, 12, round(alpha * 0.80)), width=4)


def draw_stilt_hideout(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.05, y + h * 0.78, x + w * 1.00, y + h * 1.13), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    for px in (x + w * 0.18, x + w * 0.44, x + w * 0.72):
        draw.line([xy(px, y + h * 0.72), xy(px - w * 0.04, y + h * 1.12)], fill=rgba(44, 28, 14, round(alpha * 0.88)), width=5)
    draw.rectangle(box(x + w * 0.08, y + h * 0.36, x + w * 0.90, y + h * 0.78), fill=rgba(92, 66, 42, alpha), outline=rgba(28, 18, 10, round(alpha * 0.86)), width=2)
    draw.polygon(
        polygon([(x - w * 0.08, y + h * 0.40), (x + w * 0.46, y), (x + w * 1.04, y + h * 0.38), (x + w * 0.92, y + h * 0.54), (x + w * 0.06, y + h * 0.56)]),
        fill=rgba(58, 72, 42, alpha),
        outline=rgba(18, 24, 12, alpha),
    )
    draw.rectangle(box(x + w * 0.25, y + h * 0.54, x + w * 0.44, y + h * 0.78), fill=rgba(24, 20, 14, round(alpha * 0.80)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.50, x + w * 0.76, y + h * 0.63), fill=rgba(38, 86, 76, 96), outline=rgba(20, 16, 12, 116))
    draw_flag(draw, x + w * 0.92, y + h * 0.74, 0.64, 1.0, (88, 122, 58), round(alpha * 0.70))


def draw_ancient_marsh_stones(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - 92 * scale, y + 18 * scale, x + 106 * scale, y + 54 * scale), fill=rgba(0, 0, 0, 46))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    for i, offset in enumerate((-62, -28, 18, 56)):
        height = (80 + (i % 2) * 24) * scale
        width = (26 + i * 3) * scale
        px = x + offset * scale
        draw.polygon(
            polygon([(px - width, y + 32 * scale), (px - width * 0.72, y - height), (px + width * 0.66, y - height * 0.92), (px + width, y + 30 * scale)]),
            fill=rgba(82, 92, 66, round(alpha * (0.82 + i * 0.03))),
            outline=rgba(30, 36, 24, round(alpha * 0.70)),
        )
        draw.line([xy(px - width * 0.30, y - height * 0.58), xy(px + width * 0.36, y - height * 0.46)], fill=rgba(156, 184, 96, 46), width=2)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("yunmeng-marsh-floor-v1")
    water_top = h * 0.420
    water_bottom = h * 0.800
    bank_top = h * 0.640

    draw.polygon(
        polygon([(w * -0.05, water_top), (w * 0.18, water_top - h * 0.025), (w * 0.38, water_top + h * 0.045), (w * 0.64, water_top - h * 0.012), (w * 1.05, water_top + h * 0.045), (w * 1.05, water_bottom), (w * 0.68, water_bottom + h * 0.042), (w * 0.38, water_bottom - h * 0.018), (w * -0.05, water_bottom + h * 0.020)]),
        fill=rgba(36, 108, 102, 138),
        outline=rgba(16, 52, 48, 84),
    )
    draw_river_glints(draw, w, h, water_top, water_bottom, "yunmeng-slow-water", 52)
    draw_lotus_patch(draw, w * 0.08, h * 0.500, w * 0.30, h * 0.120, 110, "yunmeng-lotus-left")
    draw_lotus_patch(draw, w * 0.58, h * 0.535, w * 0.32, h * 0.140, 106, "yunmeng-lotus-right")
    draw_sandbar(draw, w * 0.40, h * 0.545, w * 0.24, h * 0.088, 76, "yunmeng-center-island")
    draw_sandbar(draw, w * 0.14, h * 0.580, w * 0.17, h * 0.064, 58, "yunmeng-left-island")

    draw.polygon(polygon([(w * -0.02, bank_top), (w * 0.50, bank_top - h * 0.025), (w * 1.06, h + 28), (w * -0.06, h + 28)]), fill=rgba(94, 104, 58, 112), outline=rgba(38, 52, 26, 76))
    for row in range(18):
        t = row / 17.0
        y = bank_top + h * 0.020 + (t * t) * h * 0.34
        draw.line([xy(w * (-0.04 - t * 0.06), y), xy(w * (0.58 + t * 0.50), y - h * 0.020)], fill=rgba(168, 166, 92, 22 + row * 3), width=max(1, round(1.2 + t * 2.2)))
    draw_boardwalk(draw, image, w * 0.24, h * 0.590, w * 0.52, h * 0.110, 178, "yunmeng-main-boardwalk")
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.68 + t * 0.24)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(178, 206, 124, 9 + lane * 3))
    for _ in range(220):
        x = rng.uniform(w * 0.02, w * 0.99)
        y = rng.uniform(bank_top + 4, h * 0.99)
        length = rng.uniform(14, 70)
        color = rgba(44, 88, 38, rng.randint(24, 78)) if rng.random() < 0.75 else rgba(114, 108, 58, rng.randint(26, 72))
        draw.line([xy(x, y), xy(x + rng.uniform(-10, 12), y - length)], fill=color, width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_poison_mist(size, h * 0.405, h * 0.150, "yunmeng-mid-mist", 44))

    draw_ancient_marsh_stones(draw, image, w * 0.48, h * 0.485, 0.86, 128)
    draw_stilt_hideout(draw, image, w * 0.71, h * 0.300, w * 0.17, h * 0.220, 166)
    draw_stilt_hideout(draw, image, w * 0.10, h * 0.318, w * 0.14, h * 0.188, 132)
    for x, y, scale, count, seed in (
        (w * 0.06, h * 0.520, 0.76, 22, "yunmeng-mid-reeds-left"),
        (w * 0.30, h * 0.510, 0.68, 18, "yunmeng-mid-reeds-center"),
        (w * 0.63, h * 0.512, 0.70, 20, "yunmeng-mid-reeds-right"),
        (w * 0.92, h * 0.525, 0.80, 24, "yunmeng-mid-reeds-edge"),
    ):
        draw_reed_cluster(draw, x, y, scale, count, 146, seed)
    draw_boat(draw, image, w * 0.27, h * 0.555, 0.68, 132)
    draw_boat(draw, image, w * 0.62, h * 0.572, 0.72, 144)
    for x in (w * 0.17, w * 0.76):
        draw_lantern(draw, image, x, h * 0.485, 0.42)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("yunmeng-marsh-foreground-v1")
    draw.rectangle(box(0, h * 0.922, w, h), fill=rgba(8, 12, 8, 104))
    for x, y, scale, count, seed in (
        (w * 0.06, h * 0.970, 1.10, 34, "yunmeng-front-left"),
        (w * 0.95, h * 0.965, 1.12, 36, "yunmeng-front-right"),
        (w * 0.20, h * 0.965, 0.78, 18, "yunmeng-front-low-left"),
        (w * 0.80, h * 0.960, 0.82, 20, "yunmeng-front-low-right"),
    ):
        draw_reed_cluster(draw, x, y, scale, count, 220, seed)
    for x0, x1, y in ((w * 0.00, w * 0.32, h * 0.850), (w * 0.64, w * 0.99, h * 0.842)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(48, 34, 20, 214), width=8)
        draw.line([xy(x0, y + 20), xy(x1, y + 1)], fill=rgba(18, 14, 10, 166), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(32, 22, 12, 220), width=5)
    for _ in range(100):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.084)
        color = rgba(40, 94, 38, rng.randint(48, 126)) if rng.random() < 0.80 else rgba(126, 104, 58, rng.randint(42, 104))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    image.alpha_composite(draw_poison_mist(size, h * 0.805, h * 0.160, "yunmeng-front-mist", 50))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (102, 138, 122), (48, 68, 44))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.55, h * 0.15), h * 0.20, (202, 220, 142), 22)
    draw_mountain_band(draw, w, h, h * 0.335, h * 0.235, rgba(52, 86, 70, 52), "yunmeng-far-reed-bank")
    draw_mountain_band(draw, w, h, h * 0.430, h * 0.205, rgba(38, 66, 50, 78), "yunmeng-near-reed-bank")
    image.alpha_composite(draw_poison_mist(size, h * 0.260, h * 0.110, "yunmeng-sky-mist", 38))
    rng = random.Random("yunmeng-marsh-scene-v1")
    for _ in range(120):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.13, h * 0.72)
        length = rng.uniform(4, 13)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-4, 4))], fill=rgba(146, 184, 82, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 36))
    vd.rectangle(box(0, h * 0.88, w, h), fill=rgba(0, 0, 0, 72))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 34))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Yunmeng marsh DNF mist stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
