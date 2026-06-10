#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_qinghe_dnf_town_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "qinghe_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "qinghe_dnf_shopfronts_v1.png"
FOREGROUND_PATH = LAYER_DIR / "qinghe_dnf_foreground_v1.png"
SIZE = (1672, 941)


def rgba(r: int, g: int, b: int, a: int = 255) -> tuple[int, int, int, int]:
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), max(0, min(255, a)))


def xy(x: float, y: float) -> tuple[int, int]:
    return (round(x), round(y))


def box(x0: float, y0: float, x1: float, y1: float) -> tuple[int, int, int, int]:
    return (round(x0), round(y0), round(x1), round(y1))


def polygon(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [xy(x, y) for x, y in points]


def add_glow(image: Image.Image, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> None:
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius, cx + radius, cy + radius), fill=rgba(color[0], color[1], color[2], alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(max(2, round(radius * 0.38))))
    image.alpha_composite(glow)


def add_soft_shadow(image: Image.Image, rect: tuple[float, float, float, float], alpha: int, blur: float = 10.0) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rectangle(box(*rect), fill=rgba(0, 0, 0, alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(2, round(blur))))
    image.alpha_composite(shadow)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(1, height - 1)
        r = round(top[0] + (bottom[0] - top[0]) * t)
        g = round(top[1] + (bottom[1] - top[1]) * t)
        b = round(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (width, y)], fill=rgba(r, g, b, 255))
    return image


def add_painterly_grain(image: Image.Image, seed: str, alpha: int = 18, count: int = 420) -> None:
    rng = random.Random(seed)
    draw = ImageDraw.Draw(image)
    width, height = image.size
    for _ in range(count):
        x = rng.uniform(0, width)
        y = rng.uniform(height * 0.08, height * 0.96)
        length = rng.uniform(16, 90)
        angle = rng.uniform(-0.28, 0.22)
        tint = rng.randint(-18, 26)
        draw.line(
            [xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.36)],
            fill=rgba(132 + tint, 102 + tint, 74 + tint, rng.randint(max(4, alpha - 10), alpha + 8)),
            width=1,
        )


def draw_far_hills(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    for band in range(4):
        base_y = height * (0.19 + band * 0.055)
        color = rgba(78 + band * 18, 92 + band * 14, 76 + band * 8, 78 - band * 9)
        points = [(0, base_y + height * 0.12)]
        for index in range(14):
            x = width * index / 13.0
            y = base_y + math.sin(index * 1.06 + band * 0.9) * height * (0.018 + band * 0.004)
            points.append((x, y))
        points.append((width, base_y + height * 0.12))
        draw.polygon(polygon(points), fill=color)


def draw_distant_roofs(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    for index in range(12):
        x = width * (0.04 + index * 0.083)
        y = height * (0.17 + (index % 4) * 0.025)
        w = width * (0.045 + (index % 3) * 0.010)
        h = height * 0.055
        draw.rectangle(box(x - w * 0.34, y, x + w * 0.34, y + h), fill=rgba(86, 61, 42, 42))
        draw.polygon(
            polygon([(x - w * 0.55, y + h * 0.08), (x, y - h * 0.46), (x + w * 0.58, y + h * 0.08), (x + w * 0.46, y + h * 0.25), (x - w * 0.48, y + h * 0.26)]),
            fill=rgba(98, 44, 30, 64),
        )


def draw_roof(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, roof: tuple[int, int, int], accent: tuple[int, int, int], alpha: int = 232) -> None:
    draw.polygon(
        polygon([
            (x - w * 0.10, y + h * 0.48),
            (x + w * 0.50, y),
            (x + w * 1.10, y + h * 0.48),
            (x + w * 0.98, y + h * 0.72),
            (x + w * 0.03, y + h * 0.74),
        ]),
        fill=rgba(roof[0], roof[1], roof[2], alpha),
        outline=rgba(32, 18, 12, min(255, alpha + 12)),
    )
    draw.line([xy(x + w * 0.03, y + h * 0.66), xy(x + w * 0.98, y + h * 0.61)], fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.50)), width=3)
    draw.line([xy(x + w * 0.00, y + h * 0.75), xy(x + w * 1.00, y + h * 0.72)], fill=rgba(26, 16, 11, round(alpha * 0.72)), width=5)
    for tile in range(10):
        t = tile / 9.0
        tx = x + w * (0.05 + t * 0.90)
        draw.line(
            [xy(tx, y + h * 0.31 + math.sin(tile * 0.7) * 2.5), xy(tx + w * 0.075, y + h * 0.66)],
            fill=rgba(26, 16, 12, round(alpha * 0.35)),
            width=1,
        )


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float = 1.0, alpha: int = 190) -> None:
    add_glow(image, (x, y), 28 * scale, (255, 118, 36), 48)
    draw.line([xy(x, y - 28 * scale), xy(x, y - 11 * scale)], fill=rgba(55, 32, 18, 180), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 12 * scale, y - 10 * scale, x + 12 * scale, y + 17 * scale), fill=rgba(198, 38, 25, alpha), outline=rgba(255, 205, 98, 132), width=max(1, round(2 * scale)))
    for offset in (-0.36, 0.0, 0.36):
        draw.arc(
            box(x - 10 * scale, y - 9 * scale + offset * 6 * scale, x + 10 * scale, y + 15 * scale + offset * 6 * scale),
            190,
            350,
            fill=rgba(255, 178, 84, 80),
            width=max(1, round(scale)),
        )


def draw_signboard(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, accent: tuple[int, int, int], seed: int) -> None:
    draw.rounded_rectangle(box(x, y, x + w, y + h), radius=round(h * 0.13), fill=rgba(74, 30, 15, 205), outline=rgba(247, 198, 102, 142), width=2)
    rng = random.Random(seed)
    for stroke in range(4):
        sx = x + w * (0.20 + stroke * 0.16 + rng.uniform(-0.02, 0.02))
        sy = y + h * rng.uniform(0.30, 0.62)
        draw.line(
            [xy(sx, sy), xy(sx + w * rng.uniform(0.09, 0.19), sy - h * rng.uniform(0.05, 0.18))],
            fill=rgba(255, 225, 130, 82),
            width=2,
        )
    draw.line([xy(x + w * 0.12, y + h * 0.80), xy(x + w * 0.88, y + h * 0.72)], fill=rgba(accent[0], accent[1], accent[2], 60), width=1)


def draw_window(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw.rectangle(box(x, y, x + w, y + h), fill=rgba(42, 50, 45, round(alpha * 0.64)), outline=rgba(24, 18, 13, round(alpha * 0.75)), width=2)
    draw.line([xy(x + w * 0.50, y + 2), xy(x + w * 0.50, y + h - 2)], fill=rgba(232, 205, 146, round(alpha * 0.36)), width=1)
    draw.line([xy(x + 2, y + h * 0.50), xy(x + w - 2, y + h * 0.50)], fill=rgba(232, 205, 146, round(alpha * 0.30)), width=1)
    draw.line([xy(x + w * 0.12, y + h * 0.82), xy(x + w * 0.88, y + h * 0.30)], fill=rgba(246, 232, 180, round(alpha * 0.18)), width=1)


def draw_counter_goods(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, accent: tuple[int, int, int], seed: int) -> None:
    rng = random.Random(seed)
    draw.rectangle(box(x, y, x + w, y + h), fill=rgba(68, 38, 22, 160), outline=rgba(24, 16, 10, 124), width=2)
    draw.line([xy(x + w * 0.04, y + h * 0.28), xy(x + w * 0.96, y + h * 0.18)], fill=rgba(235, 160, 84, 72), width=2)
    for item in range(5):
        cx = x + w * (0.15 + item * 0.18)
        cy = y + h * (0.12 + rng.uniform(-0.03, 0.04))
        draw.ellipse(box(cx - w * 0.040, cy - h * 0.20, cx + w * 0.040, cy + h * 0.10), fill=rgba(accent[0], accent[1], accent[2], 126))


def draw_figure(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, color: tuple[int, int, int], alpha: int = 138) -> None:
    draw.ellipse(box(x - 8 * scale, y - 42 * scale, x + 8 * scale, y - 24 * scale), fill=rgba(52, 36, 26, alpha))
    draw.polygon(
        polygon([
            (x - 15 * scale, y - 23 * scale),
            (x + 13 * scale, y - 24 * scale),
            (x + 18 * scale, y + 14 * scale),
            (x - 16 * scale, y + 16 * scale),
        ]),
        fill=rgba(color[0], color[1], color[2], alpha),
    )
    draw.line([xy(x - 12 * scale, y - 10 * scale), xy(x - 25 * scale, y + 4 * scale)], fill=rgba(44, 26, 15, round(alpha * 0.76)), width=max(1, round(3 * scale)))
    draw.line([xy(x + 12 * scale, y - 11 * scale), xy(x + 25 * scale, y + 2 * scale)], fill=rgba(44, 26, 15, round(alpha * 0.76)), width=max(1, round(3 * scale)))


def draw_shopfront(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    x: float,
    y: float,
    w: float,
    h: float,
    wall: tuple[int, int, int],
    roof: tuple[int, int, int],
    accent: tuple[int, int, int],
    seed: int,
    alpha: int = 236,
) -> None:
    add_soft_shadow(image, (x + w * 0.03, y + h * 0.78, x + w * 1.01, y + h * 1.07), 54, 12.0)
    draw.rectangle(box(x + w * 0.05, y + h * 0.30, x + w * 0.97, y + h), fill=rgba(wall[0], wall[1], wall[2], alpha), outline=rgba(55, 31, 19, 144), width=2)
    draw_roof(draw, x, y, w, h * 0.45, roof, accent, alpha)

    for pillar in (0.10, 0.35, 0.65, 0.91):
        px = x + w * pillar
        draw.rectangle(box(px - w * 0.012, y + h * 0.32, px + w * 0.012, y + h * 0.99), fill=rgba(82, 39, 20, round(alpha * 0.80)))
        draw.line([xy(px, y + h * 0.34), xy(px + w * 0.012, y + h * 0.94)], fill=rgba(238, 171, 84, round(alpha * 0.18)), width=1)

    door_w = w * 0.24
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rectangle(box(door_x, y + h * 0.56, door_x + door_w, y + h), fill=rgba(36, 20, 13, 174), outline=rgba(accent[0], accent[1], accent[2], 106), width=2)
    draw.line([xy(door_x + door_w * 0.50, y + h * 0.58), xy(door_x + door_w * 0.50, y + h * 0.98)], fill=rgba(7, 5, 3, 102), width=2)
    draw.arc(box(door_x - door_w * 0.06, y + h * 0.48, door_x + door_w * 1.06, y + h * 0.76), 180, 360, fill=rgba(247, 198, 108, 72), width=2)

    draw_window(draw, x + w * 0.15, y + h * 0.50, w * 0.16, h * 0.16, alpha)
    draw_window(draw, x + w * 0.70, y + h * 0.50, w * 0.16, h * 0.16, alpha)
    draw_signboard(draw, x + w * 0.31, y + h * 0.335, w * 0.38, h * 0.105, accent, seed)
    draw_counter_goods(draw, x + w * 0.16, y + h * 0.82, w * 0.22, h * 0.12, accent, seed + 100)
    if seed % 2 == 0:
        draw_counter_goods(draw, x + w * 0.64, y + h * 0.80, w * 0.20, h * 0.12, accent, seed + 200)

    draw_figure(draw, x + w * 0.24, y + h * 0.80, 0.82, (64, 42, 32), 110)
    if seed % 3 == 0:
        draw_figure(draw, x + w * 0.78, y + h * 0.80, 0.72, (84, 38, 28), 102)
    draw_lantern(draw, image, x + w * 0.15, y + h * 0.45, 0.76)
    draw_lantern(draw, image, x + w * 0.86, y + h * 0.45, 0.76)


def draw_vendor_stall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, accent: tuple[int, int, int], alpha: int = 178) -> None:
    add_soft_shadow(image, (x - 70 * scale, y + 10 * scale, x + 78 * scale, y + 40 * scale), 44, 8.0 * scale)
    draw.rectangle(box(x - 62 * scale, y - 32 * scale, x + 62 * scale, y + 18 * scale), fill=rgba(74, 42, 24, alpha), outline=rgba(28, 18, 12, alpha), width=max(1, round(3 * scale)))
    draw.polygon(
        polygon([(x - 76 * scale, y - 32 * scale), (x, y - 76 * scale), (x + 78 * scale, y - 32 * scale), (x + 62 * scale, y - 18 * scale), (x - 62 * scale, y - 18 * scale)]),
        fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.88)),
        outline=rgba(36, 20, 14, alpha),
    )
    for item in range(6):
        cx = x - 42 * scale + item * 17 * scale
        cy = y - 8 * scale + math.sin(item) * 3 * scale
        draw.ellipse(box(cx - 6 * scale, cy - 8 * scale, cx + 6 * scale, cy + 4 * scale), fill=rgba(218 - item * 14, 128 + item * 12, 54, round(alpha * 0.82)))
    draw_figure(draw, x + 42 * scale, y + 8 * scale, 0.70 * scale, (72, 48, 30), round(alpha * 0.68))


def draw_tree(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int) -> None:
    draw.rectangle(box(x - 8 * scale, y - 90 * scale, x + 8 * scale, y + 12 * scale), fill=rgba(67, 42, 24, round(alpha * 0.72)))
    for index in range(8):
        angle = index * math.tau / 8.0
        cx = x + math.cos(angle) * 35 * scale
        cy = y - 72 * scale + math.sin(angle) * 22 * scale
        draw.ellipse(box(cx - 35 * scale, cy - 20 * scale, cx + 35 * scale, cy + 20 * scale), fill=rgba(52, 101, 45, round(alpha * (0.54 + (index % 3) * 0.06))))
    draw.ellipse(box(x - 54 * scale, y - 106 * scale, x + 48 * scale, y - 46 * scale), fill=rgba(75, 132, 54, round(alpha * 0.54)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-dnf-floor-v2")

    horizon = height * 0.475
    bottom = height + 16
    draw.polygon(
        polygon([(width * 0.02, horizon), (width * 0.98, horizon - height * 0.020), (width * 1.06, bottom), (width * -0.06, bottom)]),
        fill=rgba(180, 126, 77, 82),
    )

    for row in range(24):
        t = row / 23.0
        y = horizon + (t * t) * height * 0.51
        alpha = round(86 - t * 30)
        draw.line(
            [xy(width * (0.02 - t * 0.12), y), xy(width * (0.98 + t * 0.12), y - height * 0.020)],
            fill=rgba(82, 49, 32, alpha),
            width=max(1, round(1.1 + t * 2.7)),
        )
        if row % 3 == 1:
            draw.line(
                [xy(width * (0.06 - t * 0.09), y + 8 + t * 12), xy(width * (0.94 + t * 0.08), y - height * 0.014 + 8 + t * 10)],
                fill=rgba(236, 200, 132, round(alpha * 0.24)),
                width=1,
            )

    for column in range(32):
        t = column / 31.0
        start_x = width * (0.005 + t * 0.99)
        target_x = width * (0.50 + math.sin(column * 0.76) * 0.08)
        draw.line([xy(start_x, bottom), xy(target_x, horizon - 24)], fill=rgba(78, 45, 28, 28 + int(abs(t - 0.5) * 38)), width=1)

    for _ in range(220):
        x = rng.uniform(width * 0.04, width * 0.96)
        y = rng.uniform(horizon + height * 0.025, height * 0.97)
        length = rng.uniform(9, 72)
        angle = rng.uniform(-0.22, 0.18)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.36)], fill=rgba(84, 52, 34, rng.randint(22, 62)), width=1)

    for cx, cy, pw, ph, color in (
        (width * 0.23, height * 0.55, width * 0.13, height * 0.050, (165, 70, 48)),
        (width * 0.40, height * 0.53, width * 0.16, height * 0.055, (60, 125, 136)),
        (width * 0.56, height * 0.535, width * 0.15, height * 0.050, (190, 128, 52)),
        (width * 0.72, height * 0.55, width * 0.18, height * 0.055, (82, 130, 96)),
        (width * 0.86, height * 0.54, width * 0.13, height * 0.048, (178, 70, 44)),
    ):
        pts = [(cx - pw * 0.52, cy), (cx + pw * 0.46, cy - ph * 0.12), (cx + pw * 0.58, cy + ph * 0.50), (cx - pw * 0.44, cy + ph * 0.60)]
        draw.polygon(polygon(pts), fill=rgba(color[0], color[1], color[2], 76), outline=rgba(255, 230, 158, 94))
        draw.line([xy(cx - pw * 0.36, cy + ph * 0.50), xy(cx + pw * 0.42, cy + ph * 0.42)], fill=rgba(38, 22, 14, 78), width=2)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = height * (0.57 + t * 0.31)
        draw.ellipse(box(width * 0.10, y - height * 0.016, width * 0.90, y + height * 0.025), fill=rgba(255, 232, 168, 14 + lane * 4))
        draw.arc(box(width * 0.11, y - height * 0.045, width * 0.89, y + height * 0.043), 5, 176, fill=rgba(255, 223, 146, 28 + lane * 4), width=2)

    for _ in range(36):
        x = rng.uniform(width * 0.03, width * 0.97)
        y = rng.uniform(height * 0.76, height * 0.98)
        draw.ellipse(box(x - rng.uniform(3, 8), y - rng.uniform(1, 3), x + rng.uniform(6, 16), y + rng.uniform(1, 3)), fill=rgba(28, 18, 12, rng.randint(22, 48)))

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rectangle(box(0, height * 0.88, width, height), fill=rgba(18, 12, 8, 60))
    shadow_draw.rectangle(box(0, height * 0.45, width, height * 0.52), fill=rgba(245, 220, 170, 22))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    draw.rectangle(box(0, height * 0.08, width, height * 0.47), fill=rgba(34, 21, 14, 18))
    draw_tree(draw, width * 0.045, height * 0.45, 1.05, 120)
    draw_tree(draw, width * 0.955, height * 0.45, 0.95, 112)

    shops = [
        (width * 0.035, height * 0.145, width * 0.225, height * 0.335, (178, 113, 74), (95, 38, 26), (210, 92, 45)),
        (width * 0.245, height * 0.190, width * 0.160, height * 0.290, (196, 143, 92), (78, 52, 34), (68, 142, 154)),
        (width * 0.400, height * 0.165, width * 0.185, height * 0.318, (166, 120, 82), (92, 45, 28), (218, 147, 54)),
        (width * 0.575, height * 0.190, width * 0.165, height * 0.290, (184, 132, 86), (76, 45, 30), (82, 150, 106)),
        (width * 0.720, height * 0.135, width * 0.215, height * 0.350, (170, 103, 70), (112, 42, 26), (210, 70, 44)),
        (width * 0.890, height * 0.220, width * 0.110, height * 0.260, (198, 148, 96), (74, 44, 31), (205, 155, 58)),
    ]
    for index, (x, y, w, h, wall, roof, accent) in enumerate(shops):
        draw_shopfront(draw, image, x, y, w, h, wall, roof, accent, index + 10)

    draw_vendor_stall(draw, image, width * 0.335, height * 0.505, 0.92, (198, 61, 42), 176)
    draw_vendor_stall(draw, image, width * 0.635, height * 0.500, 0.84, (64, 135, 136), 166)

    for x in (width * 0.12, width * 0.31, width * 0.49, width * 0.69, width * 0.82, width * 0.94):
        draw.rectangle(box(x - width * 0.024, height * 0.392, x + width * 0.024, height * 0.435), fill=rgba(54, 31, 20, 116), outline=rgba(238, 188, 96, 56), width=1)
        draw.line([xy(x - width * 0.018, height * 0.421), xy(x + width * 0.020, height * 0.408)], fill=rgba(255, 224, 142, 56), width=1)
        draw_lantern(draw, image, x, height * (0.31 + (int(x) % 3) * 0.016), 0.76)

    for x in (width * 0.08, width * 0.52, width * 0.88):
        draw.line([xy(x, height * 0.47), xy(x + width * 0.03, height * 0.56)], fill=rgba(58, 33, 20, 152), width=5)
        draw.polygon(polygon([(x, height * 0.455), (x + width * 0.045, height * 0.475), (x + width * 0.028, height * 0.515)]), fill=rgba(178, 70, 45, 122))

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fog_draw = ImageDraw.Draw(fog)
    fog_draw.rectangle(box(0, height * 0.465, width, height * 0.560), fill=rgba(242, 220, 178, 28))
    fog = fog.filter(ImageFilter.GaussianBlur(14))
    image.alpha_composite(fog)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-dnf-foreground-v2")

    draw.rectangle(box(0, height * 0.925, width, height), fill=rgba(22, 14, 9, 90))
    for x0, x1, y in ((width * 0.00, width * 0.27, height * 0.865), (width * 0.66, width * 1.00, height * 0.845)):
        draw.line([xy(x0, y), xy(x1, y - height * 0.018)], fill=rgba(62, 38, 24, 216), width=8)
        draw.line([xy(x0 + width * 0.010, y + height * 0.044), xy(x1 - width * 0.010, y + height * 0.020)], fill=rgba(43, 28, 18, 204), width=6)
        for index in range(6):
            tx = x0 + (x1 - x0) * (index / 5.0)
            draw.line([xy(tx, y - height * 0.036), xy(tx + width * 0.008, height)], fill=rgba(42, 28, 18, 224), width=5)

    for x, y, w, h, accent in (
        (width * 0.030, height * 0.815, width * 0.135, height * 0.095, (190, 75, 46)),
        (width * 0.190, height * 0.830, width * 0.100, height * 0.075, (78, 130, 96)),
        (width * 0.760, height * 0.812, width * 0.145, height * 0.105, (68, 128, 140)),
        (width * 0.905, height * 0.832, width * 0.083, height * 0.080, (210, 150, 58)),
    ):
        draw.rectangle(box(x, y, x + w, y + h), fill=rgba(24, 16, 11, 122), outline=rgba(94, 56, 32, 108), width=2)
        draw.line([xy(x + w * 0.08, y + h * 0.26), xy(x + w * 0.92, y + h * 0.18)], fill=rgba(235, 161, 83, 50), width=2)
        for item in range(3):
            cx = x + w * (0.18 + item * 0.28)
            draw.ellipse(box(cx - w * 0.05, y - h * 0.10, cx + w * 0.05, y + h * 0.12), fill=rgba(accent[0], accent[1], accent[2], 74))

    for _ in range(68):
        x = rng.uniform(width * 0.02, width * 0.98)
        y = rng.uniform(height * 0.855, height * 0.99)
        length = rng.uniform(height * 0.014, height * 0.050)
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=rgba(74, 102, 45, rng.randint(44, 98)), width=1)

    for x in (width * 0.06, width * 0.94):
        draw_tree(draw, x, height * 0.86, 0.86, 112)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    mist_draw = ImageDraw.Draw(mist)
    mist_draw.ellipse(box(-width * 0.18, height * 0.79, width * 0.29, height * 1.06), fill=rgba(238, 226, 206, 38))
    mist_draw.ellipse(box(width * 0.70, height * 0.80, width * 1.14, height * 1.04), fill=rgba(232, 218, 196, 30))
    mist_draw.rectangle(box(0, 0, width, height * 0.055), fill=rgba(8, 4, 2, 54))
    mist = mist.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(mist)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = vertical_gradient(size, (157, 174, 158), (137, 116, 86))
    draw = ImageDraw.Draw(image)
    draw_far_hills(draw, width, height)
    draw_distant_roofs(draw, width, height)

    sky_haze = Image.new("RGBA", size, (0, 0, 0, 0))
    haze_draw = ImageDraw.Draw(sky_haze)
    haze_draw.rectangle(box(0, height * 0.30, width, height * 0.48), fill=rgba(239, 226, 190, 34))
    sky_haze = sky_haze.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(sky_haze)

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    add_painterly_grain(image, "qinghe-scene-grain-v2", 14, 560)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.rectangle(box(0, 0, width, height * 0.07), fill=rgba(0, 0, 0, 34))
    vignette_draw.rectangle(box(0, height * 0.91, width, height), fill=rgba(0, 0, 0, 56))
    vignette_draw.rectangle(box(0, 0, width * 0.075, height), fill=rgba(0, 0, 0, 30))
    vignette_draw.rectangle(box(width * 0.925, 0, width, height), fill=rgba(0, 0, 0, 30))
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(vignette)
    return image.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def main() -> int:
    size = SIZE
    if SCENE_PATH.exists():
        size = Image.open(SCENE_PATH).size
    save(draw_scene(size), SCENE_PATH)
    save(draw_floor_layer(size), FLOOR_PATH)
    save(draw_midground_layer(size), MIDGROUND_PATH)
    save(draw_foreground_layer(size), FOREGROUND_PATH)
    print(f"OK generated Qinghe DNF town stage assets size={size}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
