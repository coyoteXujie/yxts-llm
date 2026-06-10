#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_beiling_mtn_dnf_mountain_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "beiling_mtn_dnf_mountain_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "beiling_mtn_dnf_mountain_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "beiling_mtn_dnf_mountain_foreground_v1.png"
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
    glow = glow.filter(ImageFilter.GaussianBlur(max(2, round(radius * 0.42))))
    image.alpha_composite(glow)


def draw_mountain_band(draw: ImageDraw.ImageDraw, w: int, h: int, base_y: float, height: float, color: tuple[int, int, int, int], seed: str) -> None:
    rng = random.Random(seed)
    points: list[tuple[float, float]] = [(0, base_y + height * 0.36)]
    steps = 14
    for i in range(steps + 1):
        x = w * i / steps
        peak = math.sin(i * 1.31 + rng.random() * 0.4) * height * 0.10
        y = base_y - height * (0.46 + rng.random() * 0.34) + peak
        points.append((x, y))
    points.append((w, base_y + height * 0.36))
    draw.polygon(polygon(points), fill=color)


def draw_pine(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int, lean: float = 0.0) -> None:
    trunk = rgba(36, 28, 18, alpha)
    foliage = rgba(20, 64, 34, round(alpha * 0.82))
    draw.line([xy(x, y), xy(x + lean * scale, y - 140 * scale)], fill=trunk, width=max(2, round(5 * scale)))
    top_x = x + lean * scale
    for tier in range(5):
        ty = y - (122 - tier * 24) * scale
        width = (76 - tier * 10) * scale
        draw.polygon(
            polygon([
                (top_x, ty - 34 * scale),
                (top_x - width * 0.52, ty + 22 * scale),
                (top_x + width * 0.50, ty + 18 * scale),
            ]),
            fill=foliage,
            outline=rgba(8, 26, 16, round(alpha * 0.55)),
        )
    draw.line([xy(top_x - 18 * scale, y - 78 * scale), xy(top_x + 32 * scale, y - 84 * scale)], fill=rgba(96, 132, 70, round(alpha * 0.34)), width=max(1, round(2 * scale)))


def draw_rock(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, accent: tuple[int, int, int] = (154, 138, 102)) -> None:
    draw.polygon(
        polygon([
            (x, y + h * 0.88),
            (x + w * 0.18, y + h * 0.18),
            (x + w * 0.58, y),
            (x + w, y + h * 0.38),
            (x + w * 0.86, y + h),
            (x + w * 0.24, y + h * 1.05),
        ]),
        fill=rgba(58, 54, 45, alpha),
        outline=rgba(20, 18, 15, round(alpha * 0.72)),
    )
    draw.line([xy(x + w * 0.22, y + h * 0.32), xy(x + w * 0.54, y + h * 0.12)], fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.36)), width=2)
    draw.line([xy(x + w * 0.56, y + h * 0.10), xy(x + w * 0.78, y + h * 0.68)], fill=rgba(18, 15, 12, round(alpha * 0.38)), width=2)


def draw_plank_bridge(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(polygon([(x - 28, y + h * 0.25), (x + w + 36, y + h * 0.12), (x + w + 16, y + h * 0.55), (x - 46, y + h * 0.68)]), fill=rgba(0, 0, 0, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)
    draw.polygon(polygon([(x, y), (x + w, y - h * 0.14), (x + w + 28, y + h * 0.36), (x - 24, y + h * 0.54)]), fill=rgba(72, 44, 24, alpha), outline=rgba(22, 14, 8, alpha))
    for plank in range(10):
        t = plank / 9.0
        px = x + w * t
        draw.line([xy(px, y - h * (0.12 * t)), xy(px + 14, y + h * (0.50 - 0.12 * t))], fill=rgba(12, 8, 5, round(alpha * 0.46)), width=2)
    for rail in range(2):
        ry = y - h * (0.34 if rail == 0 else 0.12)
        draw.line([xy(x - 18, ry), xy(x + w + 12, ry - h * 0.12)], fill=rgba(42, 27, 16, round(alpha * 0.88)), width=4)
    for post in range(5):
        t = post / 4.0
        px = x + w * t
        py = y - h * (0.18 * t)
        draw.line([xy(px, py - h * 0.44), xy(px - 6, py + h * 0.42)], fill=rgba(34, 22, 13, round(alpha * 0.92)), width=4)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("beiling-mountain-floor-v1")
    top_y = h * 0.48
    bottom = h + 18
    floor = rgba(92, 82, 58, 88)
    draw.polygon(polygon([(w * 0.06, top_y), (w * 0.94, top_y - 18), (w * 1.05, bottom), (w * -0.05, bottom)]), fill=floor)
    for band in range(8):
        t = band / 7.0
        y = top_y + (t * t) * h * 0.45
        inset = w * (0.08 - t * 0.09)
        draw.polygon(
            polygon([(inset, y), (w - inset, y - 18), (w - inset + 42, y + 42), (inset - 36, y + 56)]),
            fill=rgba(84, 76, 58, round(54 + t * 46)),
            outline=rgba(24, 21, 17, round(42 + t * 50)),
        )
        draw.line([xy(inset + 28, y + 6), xy(w - inset - 22, y - 12)], fill=rgba(174, 152, 100, round(30 + t * 20)), width=2)
    draw_plank_bridge(draw, image, w * 0.36, h * 0.545, w * 0.30, h * 0.060, 162)
    for _ in range(160):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(top_y + 28, h * 0.97)
        length = rng.uniform(8, 58)
        angle = rng.uniform(-0.22, 0.16)
        alpha = rng.randint(24, 62)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.45)], fill=rgba(34, 29, 22, alpha), width=1)
        if rng.random() < 0.15:
            draw_rock(draw, x, y - 18, rng.uniform(18, 44), rng.uniform(12, 28), rng.randint(42, 82))
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.57 + t * 0.30)
        draw.ellipse(box(w * 0.10, y - h * 0.015, w * 0.90, y + h * 0.022), fill=rgba(226, 210, 152, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.045, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(218, 198, 130, 22 + lane * 3), width=2)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_plank_bridge(draw, image, w * 0.18, h * 0.455, w * 0.24, h * 0.055, 120)
    draw_plank_bridge(draw, image, w * 0.62, h * 0.465, w * 0.22, h * 0.052, 112)
    for x, y, scale, alpha in (
        (w * 0.10, h * 0.48, 0.72, 150),
        (w * 0.24, h * 0.45, 0.62, 128),
        (w * 0.76, h * 0.46, 0.66, 136),
        (w * 0.91, h * 0.50, 0.74, 150),
    ):
        draw_pine(draw, x, y, scale, alpha, math.sin(x) * 12.0)
    for x, y, ww, hh, alpha in (
        (w * 0.02, h * 0.47, w * 0.15, h * 0.11, 140),
        (w * 0.42, h * 0.43, w * 0.15, h * 0.10, 120),
        (w * 0.82, h * 0.48, w * 0.16, h * 0.12, 150),
    ):
        draw_rock(draw, x, y, ww, hh, alpha)
    for x in (w * 0.32, w * 0.68):
        draw.line([xy(x, h * 0.36), xy(x + 8, h * 0.50)], fill=rgba(34, 22, 12, 148), width=4)
        draw.polygon(polygon([(x, h * 0.36), (x + 62, h * 0.385), (x + 50, h * 0.44), (x, h * 0.42)]), fill=rgba(128, 42, 28, 112), outline=rgba(20, 14, 10, 90))
    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.42, w, h * 0.56), fill=rgba(214, 216, 190, 32))
    mist = mist.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(mist)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("beiling-mountain-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(18, 14, 10, 92))
    draw_pine(draw, w * 0.035, h * 0.88, 1.14, 208, 18.0)
    draw_pine(draw, w * 0.965, h * 0.87, 1.06, 194, -18.0)
    draw_rock(draw, -w * 0.03, h * 0.80, w * 0.18, h * 0.17, 210)
    draw_rock(draw, w * 0.83, h * 0.79, w * 0.20, h * 0.18, 206)
    for _ in range(72):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.84, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.060)
        color = rgba(44, 82, 38, rng.randint(42, 102))
        draw.line([xy(x, y), xy(x + rng.uniform(-7, 8), y - length)], fill=color, width=1)
    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.18, h * 0.78, w * 0.34, h * 1.06), fill=rgba(218, 218, 190, 38))
    fd.ellipse(box(w * 0.56, h * 0.78, w * 1.14, h * 1.04), fill=rgba(210, 206, 178, 32))
    fog = fog.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(fog)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (142, 154, 142), (104, 96, 74))
    draw = ImageDraw.Draw(image)
    draw_mountain_band(draw, w, h, h * 0.44, h * 0.32, rgba(64, 74, 64, 82), "beiling-far")
    draw_mountain_band(draw, w, h, h * 0.50, h * 0.30, rgba(54, 62, 50, 110), "beiling-mid")
    draw_mountain_band(draw, w, h, h * 0.56, h * 0.28, rgba(42, 46, 38, 128), "beiling-near")
    for i in range(9):
        x = w * (0.06 + i * 0.11)
        y = h * (0.20 + (i % 3) * 0.035)
        draw.ellipse(box(x - 56, y - 16, x + 72, y + 16), fill=rgba(225, 226, 206, 22 + (i % 3) * 7))
    floor = draw_floor_layer(size)
    mid = draw_midground_layer(size)
    foreground = draw_foreground_layer(size)
    image.alpha_composite(floor)
    image.alpha_composite(mid)
    image.alpha_composite(foreground)
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 36))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 32))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 32))
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
    print(f"OK generated Beiling mountain stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
