#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_flower_sect_dnf_garden_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "flower_sect_dnf_garden_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "flower_sect_dnf_garden_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "flower_sect_dnf_garden_foreground_v1.png"
SIZE = (1672, 941)


def rgba(r: int, g: int, b: int, a: int = 255) -> tuple[int, int, int, int]:
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), max(0, min(255, a)))


def xy(x: float, y: float) -> tuple[int, int]:
    return (round(x), round(y))


def box(x0: float, y0: float, x1: float, y1: float) -> tuple[int, int, int, int]:
    return (round(x0), round(y0), round(x1), round(y1))


def polygon(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [xy(x, y) for x, y in points]


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    for y in range(h):
        t = y / max(1, h - 1)
        r = round(top[0] + (bottom[0] - top[0]) * t)
        g = round(top[1] + (bottom[1] - top[1]) * t)
        b = round(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (w, y)], fill=rgba(r, g, b, 255))
    return image


def add_glow(image: Image.Image, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> None:
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius, cx + radius, cy + radius), fill=rgba(color[0], color[1], color[2], alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(max(2, round(radius * 0.40))))
    image.alpha_composite(glow)


def draw_mountain_band(draw: ImageDraw.ImageDraw, w: int, h: int, base_y: float, height: float, color: tuple[int, int, int, int], seed: str) -> None:
    rng = random.Random(seed)
    points: list[tuple[float, float]] = [(0, base_y + height * 0.45)]
    steps = 15
    for i in range(steps + 1):
        x = w * i / steps
        peak = math.sin(i * 1.16 + rng.random() * 0.62) * height * 0.08
        y = base_y - height * (0.36 + rng.random() * 0.42) + peak
        points.append((x, y))
    points.append((w, base_y + height * 0.45))
    draw.polygon(polygon(points), fill=color)


def draw_tile_roof(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, color: tuple[int, int, int], trim: tuple[int, int, int], alpha: int) -> None:
    draw.polygon(
        polygon([
            (x - w * 0.10, y + h * 0.50),
            (x + w * 0.50, y),
            (x + w * 1.10, y + h * 0.50),
            (x + w * 1.02, y + h * 0.66),
            (x - w * 0.02, y + h * 0.68),
        ]),
        fill=rgba(color[0], color[1], color[2], alpha),
        outline=rgba(35, 18, 16, min(255, alpha + 12)),
    )
    draw.line([xy(x + w * 0.03, y + h * 0.58), xy(x + w * 0.97, y + h * 0.56)], fill=rgba(trim[0], trim[1], trim[2], round(alpha * 0.56)), width=4)
    draw.line([xy(x - w * 0.04, y + h * 0.67), xy(x + w * 1.04, y + h * 0.64)], fill=rgba(20, 12, 12, round(alpha * 0.42)), width=3)
    for tile in range(13):
        t = tile / 12.0
        tx = x + w * (0.04 + t * 0.92)
        ty = y + h * (0.25 + abs(t - 0.5) * 0.18)
        draw.line([xy(tx, ty), xy(tx + w * 0.055, y + h * 0.63)], fill=rgba(38, 18, 16, round(alpha * 0.30)), width=1)


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, color: tuple[int, int, int] = (208, 55, 50)) -> None:
    add_glow(image, (x, y + 2 * scale), 24 * scale, (255, 128, 58), 42)
    draw.line([xy(x, y - 25 * scale), xy(x, y - 8 * scale)], fill=rgba(52, 32, 20, 180), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 11 * scale, y - 8 * scale, x + 11 * scale, y + 17 * scale), fill=rgba(color[0], color[1], color[2], 186), outline=rgba(255, 222, 132, 118), width=max(1, round(2 * scale)))
    draw.line([xy(x - 8 * scale, y + 3 * scale), xy(x + 8 * scale, y + 3 * scale)], fill=rgba(255, 220, 136, 88), width=max(1, round(scale)))


def draw_plum_blossoms(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    trunk = rgba(66, 38, 28, round(alpha * 0.90))
    draw.line([xy(x, y), xy(x + 22 * scale, y - 130 * scale)], fill=trunk, width=max(3, round(8 * scale)))
    draw.line([xy(x + 12 * scale, y - 76 * scale), xy(x - 64 * scale, y - 136 * scale)], fill=trunk, width=max(2, round(4 * scale)))
    draw.line([xy(x + 24 * scale, y - 96 * scale), xy(x + 88 * scale, y - 162 * scale)], fill=trunk, width=max(2, round(4 * scale)))
    draw.line([xy(x + 16 * scale, y - 122 * scale), xy(x - 24 * scale, y - 196 * scale)], fill=trunk, width=max(2, round(3 * scale)))
    canopy = Image.new("RGBA", image.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(canopy)
    for cluster in range(10):
        cx = x + rng.uniform(-90, 96) * scale
        cy = y - rng.uniform(118, 226) * scale
        radius = rng.uniform(30, 62) * scale
        cd.ellipse(box(cx - radius, cy - radius * 0.62, cx + radius, cy + radius * 0.70), fill=rgba(183, 91, 112, round(alpha * rng.uniform(0.28, 0.52))))
    canopy = canopy.filter(ImageFilter.GaussianBlur(max(2, round(5 * scale))))
    image.alpha_composite(canopy)
    for _ in range(70):
        px = x + rng.uniform(-118, 118) * scale
        py = y - rng.uniform(112, 238) * scale
        r = rng.uniform(1.4, 3.2) * scale
        cd_color = rgba(238, rng.randint(122, 175), rng.randint(150, 194), round(alpha * rng.uniform(0.28, 0.72)))
        draw.ellipse(box(px - r, py - r * 0.7, px + r, py + r * 0.7), fill=cd_color)


def draw_bamboo_cluster(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, count: int, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    for index in range(count):
        dx = rng.uniform(-38, 38) * scale
        lean = rng.uniform(-18, 18) * scale
        height = rng.uniform(140, 230) * scale
        base = (x + dx, y + rng.uniform(-4, 10) * scale)
        top = (base[0] + lean, base[1] - height)
        stem = rgba(44, 104, 66, round(alpha * rng.uniform(0.55, 0.92)))
        draw.line([xy(*base), xy(*top)], fill=stem, width=max(2, round(rng.uniform(3, 5) * scale)))
        for knot in range(4):
            t = (knot + 1) / 5.0
            kx = base[0] + (top[0] - base[0]) * t
            ky = base[1] + (top[1] - base[1]) * t
            draw.line([xy(kx - 6 * scale, ky), xy(kx + 6 * scale, ky - 1 * scale)], fill=rgba(194, 214, 128, round(alpha * 0.34)), width=1)
        for leaf in range(4):
            t = rng.uniform(0.15, 0.80)
            lx = base[0] + (top[0] - base[0]) * t
            ly = base[1] + (top[1] - base[1]) * t
            side = -1 if leaf % 2 == 0 else 1
            draw.line([xy(lx, ly), xy(lx + side * rng.uniform(24, 54) * scale, ly + rng.uniform(10, 26) * scale)], fill=rgba(68, 138, 76, round(alpha * 0.48)), width=max(1, round(2 * scale)))


def draw_stone_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    add_glow(image, (x, y - 37 * scale), 18 * scale, (255, 178, 82), round(alpha * 0.18))
    stone = rgba(126, 120, 104, alpha)
    dark = rgba(38, 34, 28, round(alpha * 0.62))
    draw.rectangle(box(x - 8 * scale, y - 44 * scale, x + 8 * scale, y), fill=stone, outline=dark)
    draw.rectangle(box(x - 23 * scale, y - 68 * scale, x + 23 * scale, y - 40 * scale), fill=rgba(82, 68, 54, round(alpha * 0.92)), outline=dark)
    draw.polygon(polygon([(x - 35 * scale, y - 70 * scale), (x, y - 94 * scale), (x + 35 * scale, y - 70 * scale), (x + 25 * scale, y - 62 * scale), (x - 25 * scale, y - 62 * scale)]), fill=stone, outline=dark)
    draw.rectangle(box(x - 34 * scale, y - 6 * scale, x + 34 * scale, y + 8 * scale), fill=stone, outline=dark)


def draw_banner(draw: ImageDraw.ImageDraw, x: float, y: float, h: float, color: tuple[int, int, int], alpha: int, side: float = 1.0) -> None:
    draw.line([xy(x, y), xy(x + side * 10, y + h)], fill=rgba(52, 32, 22, alpha), width=4)
    cloth = [(x, y + 8), (x + side * 66, y + 26), (x + side * 55, y + 92), (x + side * 3, y + 72)]
    draw.polygon(polygon(cloth), fill=rgba(color[0], color[1], color[2], round(alpha * 0.74)), outline=rgba(38, 22, 18, round(alpha * 0.62)))
    draw.line([xy(x + side * 16, y + 38), xy(x + side * 48, y + 45)], fill=rgba(255, 224, 154, round(alpha * 0.36)), width=2)


def draw_sect_hall(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    x: float,
    y: float,
    w: float,
    h: float,
    scale_detail: float,
    alpha: int = 238,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.72, x + w * 0.94, y + h * 1.08), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)

    wall = rgba(202, 184, 145, alpha)
    timber = rgba(108, 36, 30, alpha)
    shade = rgba(65, 26, 24, round(alpha * 0.76))
    draw.rectangle(box(x + w * 0.07, y + h * 0.30, x + w * 0.93, y + h), fill=wall, outline=shade, width=2)
    for post in range(5):
        px = x + w * (0.13 + post * 0.185)
        draw.rectangle(box(px, y + h * 0.31, px + w * 0.025, y + h), fill=timber)
        draw.line([xy(px + w * 0.016, y + h * 0.34), xy(px + w * 0.016, y + h * 0.95)], fill=rgba(192, 92, 70, round(alpha * 0.28)), width=1)
    draw.rectangle(box(x + w * 0.07, y + h * 0.44, x + w * 0.93, y + h * 0.51), fill=rgba(92, 31, 28, round(alpha * 0.92)))
    draw_tile_roof(draw, x, y, w, h * 0.42, (83, 56, 52), (232, 170, 108), alpha)

    door_w = w * 0.18
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rounded_rectangle(box(door_x, y + h * 0.54, door_x + door_w, y + h), radius=round(door_w * 0.18), fill=rgba(44, 32, 42, 180), outline=rgba(224, 166, 102, 128), width=2)
    draw.line([xy(door_x + door_w * 0.5, y + h * 0.58), xy(door_x + door_w * 0.5, y + h * 0.98)], fill=rgba(190, 142, 96, 74), width=1)

    for i in range(2):
        wx = x + w * (0.20 + i * 0.44)
        draw.rectangle(box(wx, y + h * 0.58, wx + w * 0.13, y + h * 0.76), fill=rgba(42, 76, 76, 112), outline=rgba(49, 36, 28, 145), width=2)
        draw.line([xy(wx + w * 0.065, y + h * 0.58), xy(wx + w * 0.065, y + h * 0.76)], fill=rgba(224, 234, 206, 50), width=1)
        draw.line([xy(wx, y + h * 0.67), xy(wx + w * 0.13, y + h * 0.67)], fill=rgba(224, 234, 206, 46), width=1)

    sign = box(x + w * 0.36, y + h * 0.34, x + w * 0.64, y + h * 0.445)
    draw.rectangle(sign, fill=rgba(52, 28, 20, 204), outline=rgba(240, 192, 112, 148), width=2)
    for line in range(3):
        lx = x + w * (0.40 + line * 0.08)
        draw.line([xy(lx, y + h * 0.385), xy(lx + w * 0.038, y + h * 0.372)], fill=rgba(252, 222, 145, 88), width=max(1, round(2 * scale_detail)))

    for lx in (x + w * 0.15, x + w * 0.85):
        draw_lantern(draw, image, lx, y + h * 0.49, scale_detail * 0.88)


def draw_market_stall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.08, y + h * 0.70, x + w * 1.05, y + h * 1.08), fill=rgba(0, 0, 0, 52))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    image.alpha_composite(shadow)
    draw.rectangle(box(x + w * 0.08, y + h * 0.44, x + w * 0.90, y + h * 0.78), fill=rgba(74, 48, 30, alpha), outline=rgba(20, 12, 8, round(alpha * 0.72)))
    draw.polygon(polygon([(x, y + h * 0.40), (x + w, y + h * 0.34), (x + w * 0.92, y + h * 0.48), (x + w * 0.08, y + h * 0.54)]), fill=rgba(165, 52, 52, round(alpha * 0.90)), outline=rgba(46, 22, 18, alpha))
    for stripe in range(4):
        sx = x + w * (0.10 + stripe * 0.22)
        draw.line([xy(sx, y + h * 0.39), xy(sx + w * 0.10, y + h * 0.51)], fill=rgba(234, 185, 116, round(alpha * 0.44)), width=3)
    for item in range(5):
        cx = x + w * (0.18 + item * 0.14)
        cy = y + h * 0.59 + math.sin(item) * h * 0.02
        color = (198, 74, 80) if item % 2 == 0 else (87, 128, 76)
        draw.ellipse(box(cx - w * 0.035, cy - h * 0.045, cx + w * 0.035, cy + h * 0.035), fill=rgba(color[0], color[1], color[2], round(alpha * 0.76)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("flower-sect-garden-floor-v1")
    court_top = h * 0.50
    draw.polygon(polygon([(w * 0.06, court_top), (w * 0.94, court_top - 18), (w * 1.06, h + 24), (w * -0.06, h + 24)]), fill=rgba(160, 126, 95, 96))

    for row in range(18):
        t = row / 17.0
        y = court_top + (t * t) * h * 0.43
        alpha = round(82 - t * 20)
        draw.line([xy(w * (0.05 - t * 0.10), y), xy(w * (0.95 + t * 0.10), y - 18)], fill=rgba(72, 54, 44, alpha), width=max(1, round(1 + t * 2)))
    for col in range(30):
        t = col / 29.0
        start_x = w * (0.02 + t * 0.96)
        target_x = w * (0.46 + math.sin(col * 0.77) * 0.06)
        draw.line([xy(start_x, h + 18), xy(target_x, court_top - 12)], fill=rgba(78, 56, 42, 24 + int(abs(t - 0.5) * 38)), width=1)

    path = [(w * 0.41, court_top - 18), (w * 0.59, court_top - 26), (w * 0.82, h + 28), (w * 0.18, h + 28)]
    draw.polygon(polygon(path), fill=rgba(204, 184, 142, 82), outline=rgba(86, 62, 42, 74))
    for step in range(9):
        t = step / 8.0
        y = court_top + h * (0.03 + t * t * 0.39)
        spread = w * (0.11 + t * 0.24)
        draw.line([xy(w * 0.50 - spread, y), xy(w * 0.50 + spread, y - 11)], fill=rgba(236, 218, 170, 44 + step * 3), width=3)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.60 + t * 0.29)
        draw.ellipse(box(w * 0.11, y - h * 0.015, w * 0.89, y + h * 0.024), fill=rgba(254, 228, 182, 12 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.045, w * 0.88, y + h * 0.040), 6, 176, fill=rgba(244, 208, 144, 26 + lane * 3), width=2)

    for _ in range(210):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(court_top + 10, h * 0.98)
        length = rng.uniform(8, 46)
        angle = rng.uniform(-0.20, 0.18)
        if rng.random() < 0.34:
            petal_r = rng.uniform(1.3, 3.3)
            draw.ellipse(box(x - petal_r, y - petal_r * 0.55, x + petal_r, y + petal_r * 0.55), fill=rgba(230, rng.randint(116, 164), rng.randint(146, 190), rng.randint(36, 86)))
        else:
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.45)], fill=rgba(62, 44, 34, rng.randint(20, 54)), width=1)
    draw_stone_lantern(draw, image, w * 0.22, h * 0.59, 0.82, 134)
    draw_stone_lantern(draw, image, w * 0.78, h * 0.58, 0.80, 126)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    garden_haze = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(garden_haze)
    hd.rectangle(box(0, h * 0.37, w, h * 0.56), fill=rgba(232, 216, 196, 34))
    garden_haze = garden_haze.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(garden_haze)

    for x, y, scale, seed in (
        (w * 0.08, h * 0.49, 0.78, "flower-mid-left"),
        (w * 0.88, h * 0.49, 0.74, "flower-mid-right"),
        (w * 0.28, h * 0.43, 0.48, "flower-mid-back-left"),
        (w * 0.72, h * 0.42, 0.52, "flower-mid-back-right"),
    ):
        draw_plum_blossoms(draw, image, x, y, scale, 154, seed)

    draw_bamboo_cluster(draw, w * 0.16, h * 0.50, 0.62, 14, 126, "flower-mid-bamboo-left")
    draw_bamboo_cluster(draw, w * 0.83, h * 0.50, 0.58, 13, 118, "flower-mid-bamboo-right")

    draw_sect_hall(draw, image, w * 0.31, h * 0.16, w * 0.38, h * 0.34, 0.92, 238)
    draw_sect_hall(draw, image, w * 0.08, h * 0.25, w * 0.22, h * 0.25, 0.66, 206)
    draw_sect_hall(draw, image, w * 0.70, h * 0.25, w * 0.22, h * 0.25, 0.66, 206)

    for x in (w * 0.24, w * 0.34, w * 0.66, w * 0.76):
        draw.rectangle(box(x - w * 0.015, h * 0.46, x + w * 0.015, h * 0.52), fill=rgba(78, 45, 32, 102), outline=rgba(232, 176, 102, 58))
        draw.line([xy(x - w * 0.010, h * 0.505), xy(x + w * 0.012, h * 0.488)], fill=rgba(255, 226, 144, 60), width=1)
        draw_lantern(draw, image, x, h * 0.405, 0.66)

    draw_banner(draw, w * 0.37, h * 0.31, h * 0.18, (166, 56, 70), 166, -1.0)
    draw_banner(draw, w * 0.63, h * 0.31, h * 0.18, (166, 56, 70), 166, 1.0)
    draw_market_stall(draw, image, w * 0.18, h * 0.46, w * 0.14, h * 0.15, 154)
    draw_market_stall(draw, image, w * 0.68, h * 0.465, w * 0.13, h * 0.14, 146)

    rail_y = h * 0.525
    draw.line([xy(w * 0.06, rail_y), xy(w * 0.94, rail_y - 15)], fill=rgba(82, 47, 30, 142), width=5)
    draw.line([xy(w * 0.06, rail_y + 20), xy(w * 0.94, rail_y + 5)], fill=rgba(36, 23, 16, 92), width=3)
    for post in range(12):
        t = post / 11.0
        x = w * (0.08 + t * 0.84)
        y = rail_y - 15 * t
        draw.line([xy(x, y - 22), xy(x - 4, y + 34)], fill=rgba(54, 31, 22, 138), width=4)

    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("flower-sect-garden-foreground-v1")

    draw.rectangle(box(0, h * 0.932, w, h), fill=rgba(24, 14, 12, 82))
    draw_plum_blossoms(draw, image, w * 0.02, h * 0.88, 1.12, 214, "flower-front-left")
    draw_plum_blossoms(draw, image, w * 0.98, h * 0.87, 1.05, 204, "flower-front-right")

    for x0, x1, y in ((w * 0.00, w * 0.24, h * 0.85), (w * 0.72, w * 1.02, h * 0.84)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.04)], fill=rgba(66, 42, 28, 166), width=7)
        for post in range(5):
            t = post / 4.0
            x = x0 + (x1 - x0) * t
            py = y - h * 0.04 * t
            draw.line([xy(x, py - h * 0.04), xy(x - 7, py + h * 0.06)], fill=rgba(50, 32, 22, 166), width=5)

    for _ in range(90):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.76, h * 0.99)
        if rng.random() < 0.58:
            r = rng.uniform(1.6, 4.2)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(238, rng.randint(120, 170), rng.randint(150, 200), rng.randint(42, 112)))
        else:
            length = rng.uniform(h * 0.016, h * 0.056)
            draw.line([xy(x, y), xy(x + rng.uniform(-7, 8), y - length)], fill=rgba(50, 88, 46, rng.randint(38, 92)), width=1)

    soft = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(soft)
    sd.ellipse(box(-w * 0.16, h * 0.76, w * 0.28, h * 1.05), fill=rgba(92, 28, 40, 42))
    sd.ellipse(box(w * 0.68, h * 0.75, w * 1.14, h * 1.05), fill=rgba(78, 30, 40, 38))
    soft = soft.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(soft)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (160, 180, 174), (118, 104, 90))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.55, h * 0.16), h * 0.21, (255, 218, 160), 38)
    draw_mountain_band(draw, w, h, h * 0.39, h * 0.29, rgba(90, 118, 112, 72), "flower-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.46, h * 0.25, rgba(76, 100, 86, 96), "flower-mid-mountain")
    for i in range(10):
        x = w * (0.03 + i * 0.11)
        y = h * (0.21 + (i % 4) * 0.026)
        draw.ellipse(box(x - 58, y - 14, x + 80, y + 18), fill=rgba(244, 226, 210, 16 + (i % 3) * 7))

    floor = draw_floor_layer(size)
    midground = draw_midground_layer(size)
    foreground = draw_foreground_layer(size)
    image.alpha_composite(floor)
    image.alpha_composite(midground)
    image.alpha_composite(foreground)

    petal_fog = Image.new("RGBA", size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(petal_fog)
    rng = random.Random("flower-scene-petal-drift-v1")
    for _ in range(120):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.18, h * 0.78)
        r = rng.uniform(1.2, 3.4)
        pd.ellipse(box(x - r, y - r * 0.5, x + r, y + r * 0.5), fill=rgba(240, rng.randint(124, 174), rng.randint(152, 202), rng.randint(20, 74)))
    petal_fog = petal_fog.filter(ImageFilter.GaussianBlur(0.35))
    image.alpha_composite(petal_fog)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 56))
    vd.rectangle(box(0, 0, w * 0.07, h), fill=rgba(0, 0, 0, 26))
    vd.rectangle(box(w * 0.93, 0, w, h), fill=rgba(0, 0, 0, 26))
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(vignette)
    return image.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Flower Sect garden stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
