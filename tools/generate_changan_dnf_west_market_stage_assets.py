#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_luoyang_dnf_capital_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_cart,
    draw_flag,
    draw_lantern,
    draw_roof,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_changan_dnf_west_market_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "changan_dnf_west_market_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "changan_dnf_west_market_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "changan_dnf_west_market_foreground_v1.png"


def draw_awning(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, color: tuple[int, int, int], alpha: int) -> None:
    draw.line([xy(x, y + h * 0.88), xy(x + w, y + h * 0.80)], fill=rgba(52, 32, 20, round(alpha * 0.82)), width=4)
    draw.polygon(
        polygon([
            (x - w * 0.03, y + h * 0.24),
            (x + w * 0.50, y),
            (x + w * 1.04, y + h * 0.24),
            (x + w * 0.94, y + h * 0.62),
            (x + w * 0.08, y + h * 0.68),
        ]),
        fill=rgba(color[0], color[1], color[2], alpha),
        outline=rgba(48, 29, 18, round(alpha * 0.72)),
    )
    for stripe in range(5):
        tx = x + w * (0.08 + stripe * 0.20)
        draw.line(
            [xy(tx, y + h * 0.12), xy(tx + w * 0.06, y + h * 0.62)],
            fill=rgba(255, 226, 142, round(alpha * (0.36 if stripe % 2 else 0.18))),
            width=2,
        )
    add_glow(image, (x + w * 0.50, y + h * 0.46), w * 0.20, (255, 194, 92), 18)


def draw_market_house(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    x: float,
    y: float,
    w: float,
    h: float,
    wall: tuple[int, int, int],
    accent: tuple[int, int, int],
    banner: tuple[int, int, int],
    alpha: int = 232,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.04, y + h * 0.78, x + w * 1.02, y + h * 1.08), fill=rgba(0, 0, 0, 54))
    shadow = shadow.filter(ImageFilter.GaussianBlur(11))
    image.alpha_composite(shadow)

    draw.rectangle(box(x + w * 0.05, y + h * 0.31, x + w * 0.98, y + h), fill=rgba(wall[0], wall[1], wall[2], alpha), outline=rgba(64, 40, 24, 145), width=2)
    draw_roof(draw, x, y, w, h * 0.44, alpha, accent)
    draw_awning(draw, image, x + w * 0.17, y + h * 0.44, w * 0.66, h * 0.25, banner, round(alpha * 0.88))

    door_w = w * 0.23
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rectangle(box(door_x, y + h * 0.60, door_x + door_w, y + h), fill=rgba(38, 23, 15, round(alpha * 0.82)), outline=rgba(accent[0], accent[1], accent[2], 92), width=2)
    for i in range(2):
        wx = x + w * (0.13 + i * 0.62)
        wy = y + h * 0.54
        draw.rectangle(box(wx, wy, wx + w * 0.14, wy + h * 0.13), fill=rgba(34, 43, 42, 92), outline=rgba(24, 19, 13, 120), width=2)
        draw.line([xy(wx + w * 0.07, wy), xy(wx + w * 0.07, wy + h * 0.13)], fill=rgba(238, 205, 142, 48), width=1)
    draw.rectangle(box(x + w * 0.34, y + h * 0.35, x + w * 0.66, y + h * 0.44), fill=rgba(88, 38, 18, 185), outline=rgba(245, 198, 96, 126), width=2)
    draw.line([xy(x + w * 0.40, y + h * 0.395), xy(x + w * 0.60, y + h * 0.375)], fill=rgba(255, 226, 132, 88), width=2)
    draw_lantern(draw, image, x + w * 0.14, y + h * 0.42, 0.72)
    draw_lantern(draw, image, x + w * 0.86, y + h * 0.42, 0.72)


def draw_west_gate(draw: ImageDraw.ImageDraw, image: Image.Image, cx: float, base_y: float, w: float, h: float) -> None:
    wall = rgba(190, 142, 92, 224)
    draw.rectangle(box(cx - w * 0.50, base_y - h * 0.48, cx + w * 0.50, base_y), fill=wall, outline=rgba(76, 48, 28, 150), width=3)
    for i in range(9):
        x = cx - w * 0.42 + w * 0.84 * i / 8.0
        draw.rectangle(box(x - w * 0.014, base_y - h * 0.49, x + w * 0.014, base_y - h * 0.36), fill=rgba(98, 62, 38, 165))
    arch_w = w * 0.24
    draw.rounded_rectangle(box(cx - arch_w * 0.5, base_y - h * 0.34, cx + arch_w * 0.5, base_y + 6), radius=round(arch_w * 0.48), fill=rgba(24, 16, 12, 210), outline=rgba(236, 184, 94, 96), width=2)
    draw_roof(draw, cx - w * 0.48, base_y - h * 0.76, w * 0.96, h * 0.30, 228, (226, 150, 58))
    draw.rectangle(box(cx - w * 0.18, base_y - h * 0.64, cx + w * 0.18, base_y - h * 0.50), fill=rgba(122, 48, 26, 204), outline=rgba(245, 198, 96, 116), width=2)
    draw.line([xy(cx - w * 0.11, base_y - h * 0.58), xy(cx + w * 0.11, base_y - h * 0.60)], fill=rgba(255, 226, 130, 92), width=2)
    for side in (-1.0, 1.0):
        draw_lantern(draw, image, cx + side * w * 0.34, base_y - h * 0.31, 0.82)
        draw.line([xy(cx + side * w * 0.42, base_y - h * 0.35), xy(cx + side * w * 0.42, base_y + h * 0.08)], fill=rgba(48, 30, 20, 180), width=5)
    add_glow(image, (cx, base_y - h * 0.23), w * 0.20, (255, 170, 70), 20)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("changan-dnf-west-market-floor-v1")

    horizon = h * 0.47
    bottom = h + 20
    draw.polygon(polygon([(w * 0.04, horizon), (w * 0.96, horizon - h * 0.02), (w * 1.06, bottom), (w * -0.06, bottom)]), fill=rgba(184, 132, 78, 86))
    for row in range(23):
        t = row / 22.0
        y = horizon + (t * t) * h * 0.50
        draw.line([xy(w * (0.02 - t * 0.10), y), xy(w * (0.98 + t * 0.10), y - h * 0.020)], fill=rgba(82, 50, 32, round(92 - t * 32)), width=max(1, round(1.1 + t * 2.6)))
    for i in range(34):
        t = i / 33.0
        start_x = w * (-0.02 + t * 1.04)
        target_x = w * (0.50 + math.sin(i * 0.74) * 0.08)
        draw.line([xy(start_x, bottom), xy(target_x, horizon - 24)], fill=rgba(78, 46, 28, 26 + int(abs(t - 0.5) * 38)), width=1)
    for _ in range(190):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(horizon + h * 0.035, h * 0.97)
        length = rng.uniform(12, 72)
        angle = rng.uniform(-0.20, 0.18)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(76, 48, 31, rng.randint(22, 58)), width=1)

    for cx, cy, pw, ph, color in (
        (w * 0.27, h * 0.55, w * 0.15, h * 0.052, (164, 54, 42)),
        (w * 0.42, h * 0.54, w * 0.16, h * 0.050, (196, 132, 58)),
        (w * 0.58, h * 0.54, w * 0.16, h * 0.050, (68, 124, 135)),
        (w * 0.73, h * 0.55, w * 0.15, h * 0.052, (132, 62, 128)),
    ):
        draw.polygon(polygon([(cx - pw * 0.52, cy), (cx + pw * 0.48, cy - ph * 0.10), (cx + pw * 0.58, cy + ph * 0.50), (cx - pw * 0.45, cy + ph * 0.60)]), fill=rgba(color[0], color[1], color[2], 66), outline=rgba(250, 222, 148, 82))
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.58 + t * 0.31)
        draw.ellipse(box(w * 0.09, y - h * 0.016, w * 0.91, y + h * 0.024), fill=rgba(255, 232, 170, 11 + lane * 3))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    draw_west_gate(draw, image, w * 0.50, h * 0.47, w * 0.36, h * 0.40)
    houses = [
        (w * 0.02, h * 0.18, w * 0.19, h * 0.30, (218, 166, 104), (224, 150, 58), (178, 48, 38)),
        (w * 0.20, h * 0.22, w * 0.18, h * 0.27, (204, 150, 98), (78, 130, 138), (196, 126, 46)),
        (w * 0.62, h * 0.21, w * 0.18, h * 0.28, (214, 158, 98), (210, 112, 48), (76, 122, 132)),
        (w * 0.79, h * 0.17, w * 0.19, h * 0.31, (222, 170, 108), (132, 62, 128), (190, 48, 40)),
    ]
    for args in houses:
        draw_market_house(draw, image, *args)

    for x in (w * 0.10, w * 0.24, w * 0.38, w * 0.62, w * 0.77, w * 0.92):
        draw.rectangle(box(x - w * 0.030, h * 0.398, x + w * 0.030, h * 0.438), fill=rgba(54, 31, 20, 112), outline=rgba(238, 188, 96, 54), width=1)
        draw.line([xy(x - w * 0.020, h * 0.425), xy(x + w * 0.022, h * 0.412)], fill=rgba(255, 224, 142, 54), width=1)
        draw_lantern(draw, image, x, h * (0.31 + (int(x) % 3) * 0.018), 0.76)

    for i in range(8):
        x = w * (0.13 + i * 0.105)
        base = h * (0.492 + (i % 2) * 0.010)
        draw.line([xy(x, base), xy(x + w * 0.035, base - h * 0.070)], fill=rgba(82, 50, 28, 94), width=3)
        draw.ellipse(box(x + w * 0.025, base - h * 0.090, x + w * 0.055, base - h * 0.060), fill=rgba(174, 98, 46, 90))

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.rectangle(box(0, h * 0.47, w, h * 0.57), fill=rgba(240, 218, 174, 24))
    fog = fog.filter(ImageFilter.GaussianBlur(15))
    image.alpha_composite(fog)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("changan-dnf-west-market-foreground-v1")

    draw.rectangle(box(0, h * 0.93, w, h), fill=rgba(24, 15, 9, 86))
    draw_flag(draw, w * 0.045, h * 0.80, 1.08, -1.0, (186, 42, 34), 214)
    draw_flag(draw, w * 0.955, h * 0.79, 1.02, 1.0, (214, 132, 48), 198)
    draw_cart(draw, image, w * 0.16, h * 0.885, 0.96, 182)
    draw_cart(draw, image, w * 0.84, h * 0.895, 0.86, 160)

    for x0, x1, y in ((w * 0.00, w * 0.22, h * 0.86), (w * 0.70, w * 0.99, h * 0.84)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.018)], fill=rgba(62, 38, 24, 212), width=8)
        for i in range(5):
            tx = x0 + (x1 - x0) * (i / 4.0)
            draw.line([xy(tx, y - h * 0.035), xy(tx + w * 0.008, h)], fill=rgba(42, 28, 18, 220), width=5)
    for i in range(5):
        x = w * (0.30 + i * 0.095)
        y = h * (0.91 + (i % 2) * 0.018)
        draw.rectangle(box(x - 24, y - 26, x + 28, y + 18), fill=rgba(82, 50, 28, 122), outline=rgba(28, 18, 12, 116), width=2)
        draw.ellipse(box(x - 16, y - 34, x + 16, y - 8), fill=rgba(186, 112, 48, 72))
    for _ in range(64):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.86, h * 0.99)
        length = rng.uniform(h * 0.014, h * 0.046)
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=rgba(88, 96, 44, rng.randint(38, 88)), width=1)

    dust = Image.new("RGBA", size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    dd.ellipse(box(-w * 0.13, h * 0.80, w * 0.30, h * 1.05), fill=rgba(232, 210, 176, 32))
    dd.ellipse(box(w * 0.68, h * 0.80, w * 1.12, h * 1.04), fill=rgba(226, 202, 166, 30))
    dust = dust.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(dust)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (178, 166, 138), (142, 108, 72))
    draw = ImageDraw.Draw(image)

    for band in range(3):
        base_y = h * (0.22 + band * 0.055)
        color = rgba(106 + band * 12, 94 + band * 10, 70 + band * 8, 70 - band * 10)
        points = [(0, base_y + h * 0.13)]
        for i in range(14):
            x = w * i / 13.0
            y = base_y + math.sin(i * 1.18 + band * 0.7) * h * (0.016 + band * 0.004)
            points.append((x, y))
        points.append((w, base_y + h * 0.13))
        draw.polygon(polygon(points), fill=color)
    for i in range(11):
        x = w * (0.06 + i * 0.09)
        y = h * (0.14 + (i % 4) * 0.024)
        draw.rectangle(box(x - 16, y - 12, x + 16, y + 64), fill=rgba(72, 52, 34, 42))
        draw.polygon(polygon([(x - 32, y), (x, y - 26), (x + 34, y), (x + 26, y + 12), (x - 26, y + 14)]), fill=rgba(90, 42, 28, 56))

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(0, h * 0.91, w, h), fill=rgba(0, 0, 0, 56))
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
    print(f"OK generated Changan DNF west-market stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
