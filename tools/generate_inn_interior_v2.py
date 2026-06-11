#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_inn_dnf_interior_v2.png"
SIZE = (1600, 900)


def rgba(color: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def box(x1: float, y1: float, x2: float, y2: float) -> tuple[int, int, int, int]:
    return round(x1), round(y1), round(x2), round(y2)


def xy(x: float, y: float) -> tuple[int, int]:
    return round(x), round(y)


def poly(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [xy(x, y) for x, y in points]


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    w, h = size
    for y in range(h):
        t = y / max(1, h - 1)
        color = (
            round(top[0] * (1.0 - t) + bottom[0] * t),
            round(top[1] * (1.0 - t) + bottom[1] * t),
            round(top[2] * (1.0 - t) + bottom[2] * t),
            255,
        )
        draw.line([(0, y), (w, y)], fill=color)
    return image


def add_glow(image: Image.Image, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius * 0.55, cx + radius, cy + radius * 0.55), fill=rgba(color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, round(radius * 0.28))))
    image.alpha_composite(layer)


def draw_shadow(image: Image.Image, center: tuple[float, float], radius: tuple[float, float], alpha: int) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    rx, ry = radius
    draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=(0, 0, 0, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, round(ry * 0.42))))
    image.alpha_composite(layer)


def draw_floor(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((112, 74, 44), 245))
    draw.polygon(poly([(w * 0.12, top + 34), (w * 0.88, top + 12), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((174, 111, 58), 86))
    for i in range(18):
        t = i / 17.0
        y = top + (t * t) * (h - top - 28)
        draw.line([xy(w * (-0.08 + t * 0.10), y), xy(w * (1.08 - t * 0.10), y - 18)], fill=rgba((42, 26, 18), round(134 - t * 58)), width=max(1, round(1.3 + t * 3.8)))
    for i in range(20):
        t = i / 25.0
        x = w * (0.02 + t * 0.96)
        vanishing = w * (0.50 + math.sin(i * 0.63) * 0.035)
        if i % 4 == 0 and abs(t - 0.5) > 0.16:
            draw.line([xy(x, h), xy(vanishing, top + 28)], fill=rgba((58, 38, 24), 14 + round(abs(t - 0.5) * 24)), width=1)
    draw.polygon(
        poly([(w * 0.22, h * 0.660), (w * 0.78, h * 0.632), (w * 0.70, h * 0.862), (w * 0.30, h * 0.878)]),
        fill=rgba((108, 44, 34), 186),
    )
    draw.polygon(
        poly([(w * 0.28, h * 0.700), (w * 0.72, h * 0.682), (w * 0.66, h * 0.826), (w * 0.34, h * 0.838)]),
        fill=rgba((140, 64, 40), 120),
    )
    draw.line([xy(w * 0.25, h * 0.674), xy(w * 0.76, h * 0.648)], fill=rgba((230, 170, 82), 78), width=2)
    draw.line([xy(w * 0.32, h * 0.854), xy(w * 0.68, h * 0.842)], fill=rgba((32, 18, 13), 98), width=2)
    for i in range(9):
        y = h * (0.62 + i * 0.034)
        draw.ellipse(box(w * 0.22, y - 12, w * 0.78, y + 18), fill=rgba((226, 145, 62), 22 - i))


def draw_back_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((92, 55, 38), 250))
    draw.rectangle(box(0, 0, w, 55), fill=rgba((20, 12, 8), 220))
    for x in [90, 220, 420, 720, 880, 1180, 1380, 1510]:
        draw.rectangle(box(x - 16, 42, x + 16, wall_bottom + 30), fill=rgba((36, 21, 14), 172))
        draw.line([xy(x + 5, 72), xy(x - 4, wall_bottom - 20)], fill=rgba((210, 130, 58), 34), width=2)
    for y in [108, 190, 278, 374]:
        draw.line([xy(70, y), xy(w - 70, y - 18)], fill=rgba((28, 17, 11), 124), width=5)
        draw.line([xy(70, y + 14), xy(w - 70, y - 4)], fill=rgba((224, 142, 62), 34), width=2)
    for x in [w * 0.17, w * 0.83]:
        draw.rounded_rectangle(box(x - 82, 132, x + 82, 300), radius=8, fill=rgba((34, 44, 48), 166), outline=rgba((214, 142, 64), 88), width=3)
        for k in range(4):
            lx = x - 64 + k * 42
            draw.line([xy(lx, 144), xy(lx + 16, 288)], fill=rgba((168, 218, 212), 40), width=2)
        add_glow(image, (x, 246), 120, (74, 132, 138), 22)


def draw_balcony(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    y = h * 0.332
    draw_shadow(image, (w * 0.50, y + 56), (w * 0.47, 18), 64)
    draw.rounded_rectangle(box(w * 0.11, y - 24, w * 0.89, y + 24), radius=7, fill=rgba((68, 37, 20), 236), outline=rgba((214, 132, 58), 104), width=3)
    draw.rectangle(box(w * 0.13, y - 8, w * 0.87, y + 56), fill=rgba((52, 27, 16), 210))
    for i in range(18):
        x = w * 0.14 + i * (w * 0.72 / 17.0)
        draw.line([xy(x, y - 22), xy(x - 7, y + 58)], fill=rgba((22, 14, 10), 150), width=3)
        draw.ellipse(box(x - 10, y - 28, x + 10, y - 8), fill=rgba((196, 118, 48), 160))
    draw.line([xy(w * 0.12, y + 58), xy(w * 0.88, y + 46)], fill=rgba((238, 158, 72), 62), width=2)


def draw_stair(draw: ImageDraw.ImageDraw, side: float) -> None:
    w, h = SIZE
    top = (w * (0.20 if side < 0 else 0.80), h * 0.365)
    low = (w * (0.32 if side < 0 else 0.68), h * 0.565)
    draw.line([xy(*top), xy(*low)], fill=rgba((48, 28, 18), 218), width=18)
    draw.line([xy(top[0] + side * 18, top[1] + 2), xy(low[0] + side * 22, low[1])], fill=rgba((216, 142, 72), 88), width=4)
    for i in range(8):
        t = i / 7.0
        x = top[0] * (1 - t) + low[0] * t
        y = top[1] * (1 - t) + low[1] * t
        draw.line([xy(x - side * 54, y + 3), xy(x + side * 18, y - 10)], fill=rgba((118, 66, 34), 188), width=5)
        draw.line([xy(x - side * 50, y + 8), xy(x + side * 18, y - 5)], fill=rgba((28, 16, 10), 90), width=2)


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, color: tuple[int, int, int]) -> None:
    draw.line([xy(x, 46), xy(x, y - 18 * scale)], fill=rgba((230, 176, 96), 118), width=max(1, round(2 * scale)))
    add_glow(image, (x, y + 26 * scale), 72 * scale, color, 46)
    draw.ellipse(box(x - 22 * scale, y - 12 * scale, x + 22 * scale, y + 42 * scale), fill=rgba(color, 188), outline=rgba((62, 31, 16), 150), width=max(1, round(2 * scale)))
    draw.line([xy(x - 13 * scale, y + 2 * scale), xy(x + 13 * scale, y + 32 * scale)], fill=rgba((255, 230, 142), 88), width=max(1, round(1.2 * scale)))
    draw.rectangle(box(x - 12 * scale, y + 40 * scale, x + 12 * scale, y + 52 * scale), fill=rgba((88, 38, 18), 150))


def draw_sign(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = box(w * 0.405, h * 0.190, w * 0.595, h * 0.266)
    draw.rounded_rectangle(box(rect[0] - 18, rect[1] - 14, rect[2] + 18, rect[3] + 16), radius=9, fill=rgba((12, 8, 5), 132))
    draw.rounded_rectangle(rect, radius=6, fill=rgba((58, 28, 16), 238), outline=rgba((238, 182, 88), 142), width=3)
    strokes = [
        ((0.23, 0.24), (0.19, 0.78)),
        ((0.48, 0.20), (0.42, 0.80)),
        ((0.70, 0.22), (0.66, 0.78)),
        ((0.22, 0.54), (0.38, 0.45)),
        ((0.60, 0.54), (0.78, 0.42)),
    ]
    x1, y1, x2, y2 = rect
    for (a, b) in strokes:
        draw.line([xy(x1 + (x2 - x1) * a[0], y1 + (y2 - y1) * a[1]), xy(x1 + (x2 - x1) * b[0], y1 + (y2 - y1) * b[1])], fill=rgba((250, 218, 132), 168), width=4)
    add_glow(image, ((x1 + x2) * 0.5, y2 + 42), 160, (220, 128, 58), 24)


def draw_counter(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = (w * 0.075, h * 0.415, w * 0.340, h * 0.560)
    draw_shadow(image, (w * 0.21, h * 0.585), (w * 0.18, 22), 76)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((82, 42, 22), 238), outline=rgba((210, 126, 52), 112), width=3)
    draw.polygon(poly([(rect[0] + 18, rect[1] + 26), (rect[2] - 12, rect[1] + 14), (rect[2] - 30, rect[3] + 34), (rect[0] + 40, rect[3] + 40)]), fill=rgba((174, 93, 38), 128))
    for i in range(5):
        x = rect[0] + 40 + i * 74
        draw.line([xy(x, rect[1] + 24), xy(x - 8, rect[3] - 10)], fill=rgba((26, 16, 10), 110), width=2)
    for i in range(5):
        x = rect[0] + 48 + i * 68
        y = rect[1] - 8 + (i % 2) * 6
        draw.ellipse(box(x - 12, y - 12, x + 12, y + 12), fill=rgba((92, 36, 18), 186))
        draw.ellipse(box(x + 10, y - 20, x + 23, y - 8), fill=rgba((226, 152, 72), 130))
    draw.rounded_rectangle(box(w * 0.275, h * 0.358, w * 0.430, h * 0.412), radius=5, fill=rgba((42, 24, 14), 210), outline=rgba((238, 182, 88), 76), width=2)
    for i in range(7):
        x = w * 0.295 + i * 24
        draw.line([xy(x, h * 0.370), xy(x + 8, h * 0.400)], fill=rgba((236, 174, 82), 92), width=2)


def draw_table(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, occupied: bool) -> None:
    draw_shadow(image, (x, y + 24 * scale), (86 * scale, 16 * scale), 68)
    draw.ellipse(box(x - 70 * scale, y - 20 * scale, x + 70 * scale, y + 24 * scale), fill=rgba((42, 24, 14), 98))
    draw.rounded_rectangle(box(x - 62 * scale, y - 34 * scale, x + 62 * scale, y + 8 * scale), radius=10, fill=rgba((106, 57, 28), 230), outline=rgba((224, 142, 62), 88), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 18 * scale, y - 50 * scale, x + 18 * scale, y - 22 * scale), fill=rgba((84, 34, 18), 190))
    draw.ellipse(box(x + 24 * scale, y - 48 * scale, x + 43 * scale, y - 28 * scale), fill=rgba((222, 150, 72), 122))
    if occupied:
        draw_figure(draw, image, (x - 62 * scale, y + 2 * scale), 0.70 * scale, 1.0, (56, 85, 82), 142)
        draw_figure(draw, image, (x + 68 * scale, y - 2 * scale), 0.66 * scale, -1.0, (116, 66, 45), 132)


def draw_figure(draw: ImageDraw.ImageDraw, image: Image.Image, foot: tuple[float, float], scale: float, side: float, cloth: tuple[int, int, int], alpha: int) -> None:
    x, y = foot
    h = 106 * scale
    body_w = 28 * scale
    head = (x + side * 6 * scale, y - h * 0.86)
    shoulder = (x, y - h * 0.62)
    hip = (x - side * 5 * scale, y - h * 0.22)
    draw_shadow(image, (x, y + 4 * scale), (32 * scale, 6 * scale), round(alpha * 0.25))
    draw.polygon(poly([
        (shoulder[0] - body_w, shoulder[1]),
        (shoulder[0] + body_w * 0.88, shoulder[1] + 5 * scale),
        (hip[0] + body_w * 0.78, hip[1]),
        (x + body_w * 0.40, y),
        (x - body_w * 0.76, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba(cloth, alpha))
    draw.ellipse(box(head[0] - 12 * scale, head[1] - 12 * scale, head[0] + 12 * scale, head[1] + 12 * scale), fill=rgba((50, 30, 20), alpha))
    hand = (shoulder[0] + side * body_w * 1.50, shoulder[1] + h * 0.17)
    draw.line([xy(shoulder[0] + side * body_w * 0.66, shoulder[1] + 8 * scale), xy(*hand)], fill=rgba((34, 20, 13), alpha), width=max(1, round(3 * scale)))
    draw.ellipse(box(hand[0] - 4 * scale, hand[1] - 4 * scale, hand[0] + 4 * scale, hand[1] + 4 * scale), fill=rgba((224, 164, 108), round(alpha * 0.70)))


def draw_jars_and_side_props(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for side in [-1.0, 1.0]:
        base_x = w * (0.055 if side < 0 else 0.945)
        for i in range(5):
            x = base_x + side * (34 + i * 42)
            y = h * (0.72 + (i % 3) * 0.042)
            scale = 0.78 + (i % 2) * 0.18
            draw_shadow(image, (x, y + 20 * scale), (28 * scale, 7 * scale), 62)
            draw.ellipse(box(x - 20 * scale, y - 26 * scale, x + 20 * scale, y + 30 * scale), fill=rgba((90, 38, 20), 198), outline=rgba((226, 142, 62), 72), width=2)
            draw.rectangle(box(x - 11 * scale, y - 38 * scale, x + 11 * scale, y - 22 * scale), fill=rgba((128, 62, 28), 176))
    for i in range(8):
        x = w * (0.54 + i * 0.045)
        y = h * (0.455 + (i % 2) * 0.020)
        draw.line([xy(x, y + 12), xy(x + 28, y - 16)], fill=rgba((198, 168, 112), 118), width=3)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    draw.rectangle(box(0, 0, w, 42), fill=rgba((14, 9, 7), 206))
    for x in [58, w - 58]:
        draw.rounded_rectangle(box(x - 24, 34, x + 24, h - 42), radius=9, fill=rgba((20, 12, 8), 214))
        draw.line([xy(x + (11 if x < w * 0.5 else -11), 68), xy(x + (11 if x < w * 0.5 else -11), h - 76)], fill=rgba((222, 142, 62), 58), width=3)
    curtain = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    cd = ImageDraw.Draw(curtain)
    cd.rectangle(box(0, 0, w, h * 0.060), fill=(12, 8, 6, 178))
    cd.rectangle(box(0, h * 0.895, w, h), fill=(10, 7, 5, 106))
    cd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 76))
    cd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 76))
    curtain = curtain.filter(ImageFilter.GaussianBlur(16))
    image.alpha_composite(curtain)


def add_texture(image: Image.Image, seed: str) -> None:
    rng = random.Random(seed)
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(2600):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 24)
        alpha = rng.randint(5, 26)
        color = (255, 226, 162) if rng.random() > 0.42 else (52, 30, 20)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(260):
        x = rng.uniform(w * 0.10, w * 0.90)
        y = rng.uniform(h * 0.50, h * 0.92)
        r = rng.uniform(1.2, 3.4)
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba((236, 166, 78), rng.randint(12, 38)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (38, 31, 28), (102, 69, 43))
    draw = ImageDraw.Draw(image)
    draw_back_wall(draw, image)
    draw_floor(draw, image)
    draw_balcony(draw, image)
    draw_stair(draw, -1.0)
    draw_stair(draw, 1.0)
    draw_sign(draw, image)
    for x, scale, color in [
        (SIZE[0] * 0.24, 0.92, (222, 110, 48)),
        (SIZE[0] * 0.50, 1.04, (224, 146, 62)),
        (SIZE[0] * 0.76, 0.92, (118, 176, 128)),
    ]:
        draw_lantern(draw, image, x, SIZE[1] * 0.145, scale, color)
    draw_counter(draw, image)
    draw_table(draw, image, SIZE[0] * 0.48, SIZE[1] * 0.665, 0.92, True)
    draw_table(draw, image, SIZE[0] * 0.69, SIZE[1] * 0.735, 0.80, True)
    draw_table(draw, image, SIZE[0] * 0.37, SIZE[1] * 0.795, 0.76, False)
    draw_figure(draw, image, (SIZE[0] * 0.405, SIZE[1] * 0.455), 0.72, -1.0, (96, 56, 32), 126)
    draw_figure(draw, image, (SIZE[0] * 0.785, SIZE[1] * 0.470), 0.70, 1.0, (54, 88, 76), 118)
    draw_jars_and_side_props(draw, image)
    draw_foreground(draw, image)
    add_texture(image, "inn-interior-v2")
    return image.convert("RGB")


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image = render()
    image.save(OUT, optimize=True)
    print(f"OK generated {OUT} size={SIZE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
