#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_beiling_mountain_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_pine,
    draw_rock,
    polygon,
    rgba,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_western_plateau_dnf_snow_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "western_plateau_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "western_plateau_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "western_plateau_dnf_foreground_v1.png"


def draw_snow_mountain_band(draw: ImageDraw.ImageDraw, w: int, h: int, base_y: float, height: float, color: tuple[int, int, int, int], seed: str) -> None:
    rng = random.Random(seed)
    peaks: list[tuple[float, float]] = [(0, base_y + height * 0.38)]
    steps = 13
    for i in range(steps + 1):
        x = w * i / steps
        peak = math.sin(i * 1.27 + rng.random() * 0.52) * height * 0.10
        y = base_y - height * (0.48 + rng.random() * 0.42) + peak
        peaks.append((x, y))
    peaks.append((w, base_y + height * 0.38))
    draw.polygon(polygon(peaks), fill=color)
    for i in range(1, len(peaks) - 2, 2):
        x, y = peaks[i]
        next_x, _next_y = peaks[min(i + 1, len(peaks) - 2)]
        snow_w = (next_x - x) * 0.82
        draw.polygon(
            polygon([(x - snow_w * 0.20, y + height * 0.05), (x + snow_w * 0.20, y - height * 0.02), (x + snow_w * 0.46, y + height * 0.22), (x + snow_w * 0.05, y + height * 0.16)]),
            fill=rgba(224, 230, 216, round(color[3] * 0.58)),
        )


def draw_ice_lake(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int) -> None:
    draw.ellipse(box(x, y, x + w, y + h), fill=rgba(54, 112, 130, round(alpha * 0.78)), outline=rgba(218, 236, 228, round(alpha * 0.62)), width=2)
    draw.ellipse(box(x + w * 0.08, y + h * 0.12, x + w * 0.86, y + h * 0.72), fill=rgba(190, 224, 222, round(alpha * 0.34)))
    draw.ellipse(box(x + w * 0.20, y + h * 0.22, x + w * 0.70, y + h * 0.54), fill=rgba(236, 244, 232, round(alpha * 0.16)))
    for i in range(13):
        t = i / 12.0
        yy = y + h * (0.24 + t * 0.48)
        draw.arc(box(x + w * 0.12, yy - h * 0.12, x + w * 0.90, yy + h * 0.12), 10, 170, fill=rgba(230, 244, 234, 34 + i * 2), width=1)
    for i in range(7):
        t = i / 6.0
        draw.line(
            [xy(x + w * (0.20 + t * 0.52), y + h * (0.17 + t * 0.08)), xy(x + w * (0.34 + t * 0.50), y + h * (0.70 - t * 0.05))],
            fill=rgba(236, 246, 238, 22 + i * 3),
            width=1,
        )


def draw_soft_clouds(size: tuple[int, int], seed: str, y0: float, y1: float, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(16):
        x = rng.uniform(-w * 0.06, w * 1.06)
        y = rng.uniform(y0, y1)
        rx = rng.uniform(w * 0.040, w * 0.105)
        ry = rng.uniform(18, 44)
        draw.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba(230, 232, 218, rng.randint(round(alpha * 0.45), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(18))


def draw_prayer_flags(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    x0, y0 = start
    x1, y1 = end
    draw.line([xy(x0, y0), xy(x1, y1)], fill=rgba(42, 28, 18, round(alpha * 0.72)), width=2)
    colors = [(154, 46, 42), (214, 152, 56), (54, 104, 118), (84, 128, 62), (210, 210, 166)]
    for i in range(17):
        t = (i + 0.35) / 17.0
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + math.sin(t * math.pi * 2.0) * 5
        flag_w = rng.uniform(15, 23)
        flag_h = rng.uniform(18, 28)
        color = colors[i % len(colors)]
        draw.polygon(
            polygon([(x, y), (x + flag_w, y + rng.uniform(-2, 3)), (x + flag_w * 0.80, y + flag_h), (x + 2, y + flag_h * 0.84)]),
            fill=rgba(color[0], color[1], color[2], round(alpha * rng.uniform(0.56, 0.86))),
            outline=rgba(28, 18, 12, round(alpha * 0.32)),
        )


def draw_supply_tent(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.08, y + h * 0.62, x + w * 1.08, y + h * 1.08), fill=rgba(0, 0, 0, 50))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))
    draw.polygon(
        polygon([(x, y + h), (x + w * 0.22, y + h * 0.30), (x + w * 0.52, y), (x + w * 0.84, y + h * 0.32), (x + w, y + h), (x + w * 0.58, y + h * 0.82)]),
        fill=rgba(132, 62, 48, round(alpha * 0.90)),
        outline=rgba(42, 22, 16, round(alpha * 0.84)),
    )
    draw.polygon(
        polygon([(x + w * 0.22, y + h * 0.30), (x + w * 0.52, y), (x + w * 0.58, y + h * 0.82), (x + w * 0.34, y + h * 0.92)]),
        fill=rgba(176, 142, 94, round(alpha * 0.80)),
    )
    for i in range(4):
        cx = x + w * (0.16 + i * 0.18)
        cy = y + h * (0.92 + (i % 2) * 0.04)
        draw.rectangle(box(cx - w * 0.050, cy - h * 0.10, cx + w * 0.075, cy + h * 0.05), fill=rgba(78, 48, 28, round(alpha * 0.76)), outline=rgba(28, 18, 12, round(alpha * 0.58)), width=1)
        draw.line([xy(cx - w * 0.035, cy - h * 0.03), xy(cx + w * 0.055, cy - h * 0.05)], fill=rgba(226, 184, 110, round(alpha * 0.36)), width=1)


def draw_plateau_temple(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.06, y + h * 0.78, x + w * 0.96, y + h * 1.08), fill=rgba(0, 0, 0, 58))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.10, y + h * 0.34, x + w * 0.90, y + h), fill=rgba(126, 108, 80, alpha), outline=rgba(34, 28, 24, round(alpha * 0.78)))
    draw.polygon(
        polygon([(x - w * 0.06, y + h * 0.42), (x + w * 0.50, y), (x + w * 1.06, y + h * 0.42), (x + w * 0.92, y + h * 0.60), (x + w * 0.08, y + h * 0.60)]),
        fill=rgba(72, 66, 58, alpha),
        outline=rgba(18, 16, 14, alpha),
    )
    snow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(snow)
    sd.polygon(polygon([(x + w * 0.02, y + h * 0.45), (x + w * 0.50, y + h * 0.05), (x + w * 0.98, y + h * 0.45), (x + w * 0.85, y + h * 0.49), (x + w * 0.12, y + h * 0.50)]), fill=rgba(232, 236, 224, 72))
    image.alpha_composite(snow.filter(ImageFilter.GaussianBlur(2)))
    for post in (0.18, 0.36, 0.64, 0.82):
        px = x + w * post
        draw.line([xy(px, y + h * 0.42), xy(px - w * 0.02, y + h)], fill=rgba(42, 32, 24, round(alpha * 0.82)), width=4)
    draw.rectangle(box(x + w * 0.38, y + h * 0.58, x + w * 0.62, y + h), fill=rgba(34, 28, 26, round(alpha * 0.84)), outline=rgba(218, 194, 132, 104), width=2)
    sign = box(x + w * 0.34, y + h * 0.365, x + w * 0.66, y + h * 0.475)
    draw.rectangle(sign, fill=rgba(46, 32, 20, 178), outline=rgba(226, 192, 118, 118), width=2)
    draw.line([xy(x + w * 0.40, y + h * 0.420), xy(x + w * 0.60, y + h * 0.405)], fill=rgba(246, 224, 146, 84), width=2)


def draw_glacier_cave(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.08, y + h * 0.60, x + w * 1.08, y + h * 1.10), fill=rgba(0, 0, 0, 56))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x, y + h), (x + w * 0.10, y + h * 0.28), (x + w * 0.50, y), (x + w * 0.92, y + h * 0.28), (x + w, y + h), (x + w * 0.72, y + h * 1.05), (x + w * 0.22, y + h * 1.02)]),
        fill=rgba(112, 130, 128, alpha),
        outline=rgba(34, 42, 44, round(alpha * 0.70)),
    )
    draw.ellipse(box(x + w * 0.30, y + h * 0.36, x + w * 0.72, y + h * 1.02), fill=rgba(24, 32, 38, round(alpha * 0.82)))
    draw.polygon(polygon([(x + w * 0.20, y + h * 0.18), (x + w * 0.36, y + h * 0.12), (x + w * 0.26, y + h * 0.70)]), fill=rgba(220, 236, 232, round(alpha * 0.28)))
    draw.polygon(polygon([(x + w * 0.72, y + h * 0.16), (x + w * 0.84, y + h * 0.32), (x + w * 0.76, y + h * 0.76)]), fill=rgba(220, 236, 232, round(alpha * 0.24)))


def draw_snow_altar(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    w = 118 * scale
    h = 100 * scale
    draw.ellipse(box(x - w * 0.55, y + h * 0.18, x + w * 0.58, y + h * 0.48), fill=rgba(0, 0, 0, round(alpha * 0.22)))
    for tier in range(3):
        tw = w * (0.92 - tier * 0.16)
        th = h * 0.18
        ty = y + h * (0.20 - tier * 0.16)
        draw.polygon(polygon([(x - tw * 0.50, ty), (x + tw * 0.50, ty - th * 0.15), (x + tw * 0.44, ty + th), (x - tw * 0.45, ty + th * 1.10)]), fill=rgba(110, 106, 92, round(alpha * (0.88 - tier * 0.06))), outline=rgba(40, 36, 30, round(alpha * 0.62)))
    draw.line([xy(x, y - h * 0.58), xy(x, y + h * 0.02)], fill=rgba(64, 46, 32, round(alpha * 0.90)), width=max(2, round(4 * scale)))
    draw.polygon(polygon([(x, y - h * 0.58), (x + w * 0.32, y - h * 0.42), (x + w * 0.26, y - h * 0.25), (x + w * 0.02, y - h * 0.36)]), fill=rgba(126, 54, 46, round(alpha * 0.78)), outline=rgba(42, 24, 18, round(alpha * 0.62)))
    draw_lantern(draw, image, x - w * 0.22, y - h * 0.02, 0.38 * scale)
    draw_lantern(draw, image, x + w * 0.22, y - h * 0.02, 0.38 * scale)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("western-plateau-floor-v1")
    top_y = h * 0.482
    lake_top = h * 0.520
    draw.polygon(polygon([(w * 0.05, top_y), (w * 0.95, top_y - 22), (w * 1.06, h + 24), (w * -0.06, h + 26)]), fill=rgba(96, 100, 72, 92))
    for band in range(9):
        t = band / 8.0
        y = top_y + (t * t) * h * 0.45
        left = w * (0.07 - t * 0.10)
        right = w * (0.94 + t * 0.07)
        fill = rgba(88 + round(t * 12), 92 + round(t * 8), 72 + round(t * 5), round(54 + t * 48))
        draw.polygon(polygon([(left, y), (right, y - 24), (right + 48, y + 44), (left - 42, y + 58)]), fill=fill, outline=rgba(28, 30, 26, round(46 + t * 46)))
        draw.line([xy(left + 30, y + 7), xy(right - 20, y - 18)], fill=rgba(214, 218, 200, round(24 + t * 26)), width=2)
    draw_ice_lake(draw, w * 0.16, lake_top, w * 0.68, h * 0.135, 142)
    step_top = h * 0.555
    for step in range(16):
        t = step / 15.0
        y = step_top + (t * t) * h * 0.36
        half = w * (0.075 + t * 0.25)
        cx = w * (0.50 + math.sin(step * 0.47) * 0.018)
        draw.polygon(
            polygon([(cx - half, y), (cx + half, y - h * 0.012), (cx + half * 0.88, y + h * 0.030), (cx - half * 0.88, y + h * 0.040)]),
            fill=rgba(124, 118, 94, 34 + step * 3),
            outline=rgba(32, 30, 24, 24 + step * 2),
        )
        draw.line([xy(cx - half * 0.82, y + h * 0.010), xy(cx + half * 0.72, y - h * 0.004)], fill=rgba(224, 226, 202, 28 + step * 2), width=1)
    for _ in range(250):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(top_y + 18, h * 0.99)
        if rng.random() < 0.34:
            r = rng.uniform(1.2, 4.6)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(202, 210, 194, rng.randint(26, 78)))
        else:
            length = rng.uniform(8, 46)
            angle = rng.uniform(-0.34, 0.24)
            color = rgba(90, 122, 72, rng.randint(24, 62)) if rng.random() < 0.55 else rgba(218, 222, 206, rng.randint(20, 58))
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=color, width=1)
    for _ in range(42):
        x = rng.uniform(w * 0.06, w * 0.94)
        y = rng.uniform(h * 0.60, h * 0.95)
        draw_rock(draw, x, y, rng.uniform(16, 42), rng.uniform(9, 24), rng.randint(34, 72), (190, 196, 176))
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.59 + t * 0.30)
        draw.ellipse(box(w * 0.10, y - h * 0.015, w * 0.90, y + h * 0.022), fill=rgba(228, 230, 210, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.045, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(230, 226, 202, 22 + lane * 3), width=2)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.36, w, h * 0.58), fill=rgba(226, 232, 220, 38))
    md.ellipse(box(w * 0.08, h * 0.34, w * 0.92, h * 0.62), fill=rgba(218, 228, 220, 24))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(20)))
    draw_glacier_cave(draw, image, w * 0.07, h * 0.330, w * 0.18, h * 0.205, 156)
    draw_plateau_temple(draw, image, w * 0.40, h * 0.284, w * 0.20, h * 0.232, 174)
    draw_supply_tent(draw, image, w * 0.265, h * 0.445, w * 0.115, h * 0.105, 144)
    draw_supply_tent(draw, image, w * 0.615, h * 0.440, w * 0.120, h * 0.110, 150)
    draw_snow_altar(draw, image, w * 0.74, h * 0.505, 0.78, 152)
    for x, y, scale, alpha in (
        (w * 0.19, h * 0.50, 0.58, 112),
        (w * 0.31, h * 0.49, 0.52, 104),
        (w * 0.39, h * 0.51, 0.45, 92),
        (w * 0.66, h * 0.50, 0.48, 98),
        (w * 0.88, h * 0.50, 0.60, 118),
    ):
        draw_pine(draw, x, y, scale, alpha, math.sin(x) * 8.0)
    draw_prayer_flags(draw, (w * 0.30, h * 0.470), (w * 0.44, h * 0.430), 126, "western-prayer-left")
    draw_prayer_flags(draw, (w * 0.57, h * 0.430), (w * 0.72, h * 0.480), 128, "western-prayer-right")
    for x, side in ((w * 0.33, -1.0), (w * 0.62, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.74, side, (112, 62, 62), 132)
    rail_y = h * 0.548
    draw.line([xy(w * 0.08, rail_y), xy(w * 0.91, rail_y - h * 0.018)], fill=rgba(62, 44, 30, 96), width=4)
    for post in range(12):
        t = post / 11.0
        px = w * (0.09 + t * 0.80)
        py = rail_y - h * 0.018 * t
        draw.line([xy(px, py - 18), xy(px - 4, py + 28)], fill=rgba(42, 30, 20, 112), width=3)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("western-plateau-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(16, 18, 16, 92))
    draw_rock(draw, -w * 0.04, h * 0.800, w * 0.18, h * 0.17, 208, (210, 216, 200))
    draw_rock(draw, w * 0.84, h * 0.790, w * 0.19, h * 0.18, 208, (210, 216, 200))
    draw_pine(draw, w * 0.04, h * 0.90, 0.92, 178, 15.0)
    draw_pine(draw, w * 0.96, h * 0.90, 0.88, 174, -14.0)
    for x0, x1, y in ((w * 0.00, w * 0.26, h * 0.858), (w * 0.70, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(48, 34, 24, 204), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(30, 22, 18, 178), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(34, 24, 18, 216), width=5)
    draw_prayer_flags(draw, (w * 0.020, h * 0.830), (w * 0.180, h * 0.775), 130, "western-front-left-flags")
    draw_prayer_flags(draw, (w * 0.830, h * 0.775), (w * 0.985, h * 0.830), 130, "western-front-right-flags")
    for _ in range(100):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.060)
        color = rgba(78, 112, 66, rng.randint(38, 96)) if rng.random() < 0.62 else rgba(220, 226, 212, rng.randint(34, 92))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    for i in range(10):
        x = w * (0.30 + i * 0.045)
        y = h * (0.912 + (i % 3) * 0.012)
        draw.rectangle(box(x - 15, y - 18, x + 20, y + 15), fill=rgba(68, 48, 34, 116), outline=rgba(24, 18, 14, 110), width=1)
        draw.line([xy(x - 10, y - 5), xy(x + 12, y - 7)], fill=rgba(230, 220, 168, 54), width=1)
    snow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(snow)
    sd.ellipse(box(-w * 0.20, h * 0.76, w * 0.34, h * 1.08), fill=rgba(224, 230, 220, 42))
    sd.ellipse(box(w * 0.60, h * 0.76, w * 1.18, h * 1.06), fill=rgba(224, 230, 220, 38))
    for _ in range(120):
        x = rng.uniform(-w * 0.05, w * 1.05)
        y = rng.uniform(h * 0.10, h * 0.98)
        sd.line([xy(x, y), xy(x + rng.uniform(18, 46), y + rng.uniform(-5, 4))], fill=rgba(238, 244, 232, rng.randint(18, 58)), width=1)
    image.alpha_composite(snow.filter(ImageFilter.GaussianBlur(1)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (162, 180, 172), (88, 96, 78))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.54, h * 0.14), h * 0.22, (246, 230, 172), 38)
    draw_snow_mountain_band(draw, w, h, h * 0.35, h * 0.34, rgba(74, 88, 86, 78), "western-far-snow")
    draw_snow_mountain_band(draw, w, h, h * 0.45, h * 0.32, rgba(56, 68, 66, 110), "western-mid-snow")
    draw_snow_mountain_band(draw, w, h, h * 0.56, h * 0.28, rgba(46, 50, 44, 126), "western-near-snow")
    image.alpha_composite(draw_soft_clouds(size, "western-soft-clouds", h * 0.145, h * 0.285, 42))
    rng = random.Random("western-plateau-scene-v1")
    for ridge in range(40):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.29, h * 0.54)
        length = rng.uniform(28, 90)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-7, 4))], fill=rgba(210, 218, 204, rng.randint(10, 30)), width=1)
    for _ in range(100):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.12, h * 0.74)
        draw.line([xy(x, y), xy(x + rng.uniform(12, 36), y + rng.uniform(-4, 4))], fill=rgba(230, 238, 226, rng.randint(14, 48)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
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
    print(f"OK generated Western plateau DNF snow stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
