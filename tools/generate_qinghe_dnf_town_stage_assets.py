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


def draw_platform(draw: ImageDraw.ImageDraw, cx: float, cy: float, w: float, h: float, color: tuple[int, int, int]) -> None:
    pts = [(cx - w * 0.54, cy), (cx + w * 0.46, cy - h * 0.10), (cx + w * 0.57, cy + h * 0.48), (cx - w * 0.43, cy + h * 0.58)]
    draw.polygon(polygon(pts), fill=rgba(color[0], color[1], color[2], 98), outline=rgba(255, 239, 181, 112))
    inset = [(x * 0.92 + cx * 0.08, y * 0.88 + (cy + h * 0.22) * 0.12) for x, y in pts]
    draw.line(polygon(inset + [inset[0]]), fill=rgba(255, 255, 220, 92), width=2)
    draw.line([xy(cx - w * 0.42, cy + h * 0.55), xy(cx + w * 0.46, cy + h * 0.45)], fill=rgba(28, 22, 15, 88), width=3)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-dnf-floor-v1")

    horizon = h * 0.49
    bottom = h + 12
    draw.polygon(
        polygon([(w * 0.02, horizon), (w * 0.98, horizon - h * 0.018), (w * 1.05, bottom), (w * -0.05, bottom)]),
        fill=rgba(186, 123, 66, 42),
    )

    for row in range(18):
        t = row / 17.0
        y = horizon + (t * t) * h * 0.50
        alpha = round(72 - t * 22)
        width = max(1, round(1.1 + t * 2.4))
        draw.line([xy(w * (0.03 - t * 0.10), y), xy(w * (0.97 + t * 0.10), y - h * 0.018)], fill=rgba(80, 45, 28, alpha), width=width)

    vanishing_left = (w * 0.34, horizon - h * 0.08)
    vanishing_right = (w * 0.64, horizon - h * 0.09)
    for i in range(24):
        t = i / 23.0
        start_x = w * (0.02 + t * 0.96)
        target = vanishing_left if i % 2 == 0 else vanishing_right
        alpha = 40 + int(abs(t - 0.5) * 24)
        draw.line([xy(start_x, bottom), xy(target[0] + (t - 0.5) * w * 0.10, target[1])], fill=rgba(78, 43, 26, alpha), width=2)

    for _ in range(120):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(horizon + h * 0.04, h * 0.96)
        length = rng.uniform(10, 58)
        angle = rng.uniform(-0.18, 0.18)
        alpha = rng.randint(24, 58)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(80, 48, 30, alpha), width=1)

    for cx, cy, pw, ph, color in (
        (w * 0.47, h * 0.52, w * 0.16, h * 0.055, (70, 142, 150)),
        (w * 0.58, h * 0.52, w * 0.18, h * 0.055, (69, 139, 143)),
        (w * 0.68, h * 0.52, w * 0.16, h * 0.055, (168, 58, 42)),
        (w * 0.84, h * 0.52, w * 0.18, h * 0.055, (197, 142, 48)),
    ):
        draw_platform(draw, cx, cy, pw, ph, color)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.58 + t * 0.30)
        draw.ellipse(box(w * 0.10, y - h * 0.015, w * 0.90, y + h * 0.024), fill=rgba(255, 233, 172, 12 + lane * 3))
        draw.arc(box(w * 0.11, y - h * 0.045, w * 0.89, y + h * 0.042), 5, 176, fill=rgba(255, 229, 155, 26 + lane * 3), width=2)

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(0, h * 0.88, w, h), fill=rgba(18, 12, 8, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow)
    return image


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float = 1.0) -> None:
    add_glow(image, (x, y), 26 * scale, (255, 120, 32), 52)
    draw.line([xy(x, y - 26 * scale), xy(x, y - 12 * scale)], fill=rgba(55, 32, 18, 170), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 12 * scale, y - 10 * scale, x + 12 * scale, y + 16 * scale), fill=rgba(195, 38, 25, 172), outline=rgba(255, 199, 96, 120), width=max(1, round(2 * scale)))
    draw.line([xy(x - 8 * scale, y + 3 * scale), xy(x + 8 * scale, y + 3 * scale)], fill=rgba(255, 185, 82, 85), width=max(1, round(scale)))


def draw_shop_entrance(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, accent: tuple[int, int, int]) -> None:
    add_glow(image, (x + w * 0.50, y + h * 0.60), min(w, h) * 0.38, accent, 24)
    draw.rectangle(box(x + w * 0.10, y + h * 0.28, x + w * 0.90, y + h), fill=rgba(34, 22, 16, 22), outline=rgba(255, 227, 166, 28), width=1)
    draw.polygon(
        polygon([(x - w * 0.05, y + h * 0.28), (x + w * 0.50, y), (x + w * 1.05, y + h * 0.28), (x + w * 0.93, y + h * 0.39), (x + w * 0.07, y + h * 0.39)]),
        fill=rgba(42, 25, 17, 28),
    )
    draw.rectangle(box(x + w * 0.27, y + h * 0.41, x + w * 0.73, y + h * 0.58), fill=rgba(42, 21, 13, 92), outline=rgba(245, 189, 98, 76), width=1)
    for i in range(3):
        tx = x + w * (0.22 + i * 0.28)
        draw.line([xy(tx, y + h * 0.11), xy(tx + w * 0.06, y + h * 0.35)], fill=rgba(255, 205, 118, 18), width=1)
    draw_lantern(draw, image, x + w * 0.13, y + h * 0.50, 0.75)
    draw_lantern(draw, image, x + w * 0.87, y + h * 0.50, 0.75)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    draw.rectangle(box(0, h * 0.09, w, h * 0.45), fill=rgba(28, 18, 12, 8))
    for x, y, ww, hh, accent in (
        (w * 0.02, h * 0.10, w * 0.28, h * 0.38, (170, 45, 28)),
        (w * 0.35, h * 0.17, w * 0.18, h * 0.30, (58, 130, 160)),
        (w * 0.54, h * 0.21, w * 0.17, h * 0.26, (64, 145, 145)),
        (w * 0.66, h * 0.14, w * 0.20, h * 0.34, (185, 76, 45)),
        (w * 0.82, h * 0.22, w * 0.15, h * 0.25, (205, 151, 52)),
    ):
        draw_shop_entrance(draw, image, x, y, ww, hh, accent)

    for x in (w * 0.15, w * 0.32, w * 0.47, w * 0.68, w * 0.84):
        draw.rectangle(box(x - w * 0.035, h * 0.35, x + w * 0.035, h * 0.39), fill=rgba(45, 23, 13, 92), outline=rgba(234, 179, 92, 48), width=1)
        draw.line([xy(x - w * 0.025, h * 0.378), xy(x + w * 0.028, h * 0.365)], fill=rgba(255, 218, 132, 42), width=1)

    for x, y, s in ((w * 0.12, h * 0.27, 1.1), (w * 0.40, h * 0.31, 0.9), (w * 0.74, h * 0.28, 1.0), (w * 0.91, h * 0.32, 0.85)):
        draw_lantern(draw, image, x, y, s)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.rectangle(box(0, h * 0.46, w, h * 0.54), fill=rgba(245, 225, 180, 24))
    fog = fog.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(fog)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-dnf-foreground-v1")

    draw.rectangle(box(0, h * 0.93, w, h), fill=rgba(22, 14, 9, 88))
    for x0, x1, y in ((w * 0.00, w * 0.24, h * 0.89), (w * 0.63, w * 0.86, h * 0.86)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.018)], fill=rgba(55, 33, 21, 210), width=8)
        draw.line([xy(x0 + w * 0.012, y + h * 0.045), xy(x1 - w * 0.010, y + h * 0.020)], fill=rgba(45, 27, 17, 198), width=6)
        for i in range(5):
            tx = x0 + (x1 - x0) * (i / 4.0)
            draw.line([xy(tx, y - h * 0.035), xy(tx + w * 0.01, h)], fill=rgba(38, 24, 16, 216), width=5)

    for x, y, ww, hh in ((w * 0.02, h * 0.82, w * 0.12, h * 0.10), (w * 0.18, h * 0.84, w * 0.10, h * 0.08), (w * 0.83, h * 0.82, w * 0.16, h * 0.11)):
        draw.rectangle(box(x, y, x + ww, y + hh), fill=rgba(24, 16, 11, 112), outline=rgba(87, 52, 29, 104), width=2)
        draw.line([xy(x + ww * 0.08, y + hh * 0.26), xy(x + ww * 0.92, y + hh * 0.18)], fill=rgba(235, 161, 83, 48), width=2)

    for _ in range(52):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.87, h * 0.99)
        length = rng.uniform(h * 0.014, h * 0.050)
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=rgba(78, 104, 45, rng.randint(46, 96)), width=1)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.ellipse(box(-w * 0.18, h * 0.80, w * 0.28, h * 1.06), fill=rgba(240, 235, 218, 40))
    md.ellipse(box(w * 0.72, h * 0.82, w * 1.12, h * 1.04), fill=rgba(230, 220, 198, 26))
    mist = mist.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(mist)
    return image


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> int:
    if not SCENE_PATH.exists():
        raise SystemExit(f"missing base scene image: {SCENE_PATH}")
    size = Image.open(SCENE_PATH).size
    save(draw_floor_layer(size), FLOOR_PATH)
    save(draw_midground_layer(size), MIDGROUND_PATH)
    save(draw_foreground_layer(size), FOREGROUND_PATH)
    print(f"OK generated qinghe DNF town layers size={size}")
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
