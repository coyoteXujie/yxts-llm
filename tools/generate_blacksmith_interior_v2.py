#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_blacksmith_dnf_interior_v2.png"
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
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius * 0.58, cx + radius, cy + radius * 0.58), fill=rgba(color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, round(radius * 0.30))))
    image.alpha_composite(layer)


def draw_shadow(image: Image.Image, center: tuple[float, float], radius: tuple[float, float], alpha: int) -> None:
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    rx, ry = radius
    draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=(0, 0, 0, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, round(ry * 0.45))))
    image.alpha_composite(layer)


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((68, 48, 42), 250))
    draw.rectangle(box(0, 0, w, 58), fill=rgba((18, 12, 10), 230))
    for x in [88, 218, 420, 670, 865, 1130, 1380, 1510]:
        draw.rectangle(box(x - 17, 40, x + 17, wall_bottom + 34), fill=rgba((28, 20, 17), 185))
        draw.line([xy(x + 5, 76), xy(x - 7, wall_bottom - 18)], fill=rgba((218, 82, 36), 36), width=2)
    for y in [112, 194, 284, 374]:
        draw.line([xy(70, y), xy(w - 70, y - 16)], fill=rgba((22, 16, 13), 130), width=5)
        draw.line([xy(70, y + 14), xy(w - 70, y - 2)], fill=rgba((230, 82, 38), 32), width=2)
    draw.rounded_rectangle(box(w * 0.39, h * 0.177, w * 0.61, h * 0.252), radius=6, fill=rgba((42, 22, 16), 238), outline=rgba((236, 146, 78), 120), width=3)
    for i in range(5):
        x = w * (0.425 + i * 0.038)
        draw.line([xy(x, h * 0.196), xy(x - 16, h * 0.238)], fill=rgba((250, 205, 126), 148), width=4)
    add_glow(image, (w * 0.50, h * 0.275), 150, (234, 92, 38), 22)


def draw_floor(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((84, 67, 56), 246))
    draw.polygon(poly([(w * 0.12, top + 36), (w * 0.88, top + 14), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((136, 92, 54), 76))
    for i in range(17):
        t = i / 16.0
        y = top + (t * t) * (h - top - 30)
        draw.line([xy(w * (-0.05 + t * 0.08), y), xy(w * (1.05 - t * 0.08), y - 17)], fill=rgba((34, 25, 22), round(126 - t * 50)), width=max(1, round(1.4 + t * 3.4)))
    for i in range(16):
        t = i / 15.0
        if i % 3 == 1:
            continue
        x = w * (0.03 + t * 0.94)
        target = w * (0.50 + math.sin(i * 0.51) * 0.030)
        draw.line([xy(x, h), xy(target, top + 28)], fill=rgba((48, 36, 28), 18 + round(abs(t - 0.5) * 32)), width=1)
    draw.polygon(poly([(w * 0.22, h * 0.650), (w * 0.78, h * 0.620), (w * 0.68, h * 0.858), (w * 0.30, h * 0.872)]), fill=rgba((65, 43, 34), 138))
    draw.polygon(poly([(w * 0.31, h * 0.704), (w * 0.70, h * 0.682), (w * 0.63, h * 0.822), (w * 0.36, h * 0.836)]), fill=rgba((94, 51, 35), 82))
    for i in range(120):
        x = w * (0.20 + (i % 24) * 0.026) + (i % 3) * 3
        y = h * (0.585 + (i // 24) * 0.052)
        draw.line([xy(x, y), xy(x + 18, y - 4)], fill=rgba((92, 64, 42), 44), width=1)


def draw_weapon_rack(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, side: float) -> None:
    draw_shadow(image, (x, y + 92), (135, 18), 58)
    draw.rounded_rectangle(box(x - 118, y - 98, x + 118, y + 104), radius=6, fill=rgba((38, 26, 20), 206), outline=rgba((164, 88, 48), 78), width=2)
    for row in range(4):
        yy = y - 62 + row * 46
        draw.line([xy(x - 96, yy), xy(x + 98, yy - 6)], fill=rgba((156, 91, 48), 145), width=4)
    for i in range(7):
        px = x - 80 + i * 27
        length = 118 + (i % 3) * 24
        draw.line([xy(px, y + 62), xy(px + side * 38, y + 62 - length)], fill=rgba((194, 188, 162), 158), width=3)
        draw.line([xy(px - side * 14, y + 18), xy(px + side * 22, y - 4)], fill=rgba((236, 122, 54), 92), width=2)
        if i % 2 == 0:
            draw.line([xy(px + side * 32, y + 62 - length + 12), xy(px + side * 50, y + 62 - length + 36)], fill=rgba((244, 220, 154), 80), width=1)


def draw_forge(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    forge = (w * 0.775, h * 0.555)
    add_glow(image, forge, 270, (255, 80, 28), 92)
    add_glow(image, (forge[0], forge[1] + 24), 145, (255, 196, 64), 100)
    draw_shadow(image, (forge[0], forge[1] + 118), (180, 28), 88)
    draw.rounded_rectangle(box(forge[0] - 142, forge[1] - 80, forge[0] + 150, forge[1] + 96), radius=10, fill=rgba((54, 32, 25), 238), outline=rgba((216, 88, 42), 112), width=4)
    draw.ellipse(box(forge[0] - 78, forge[1] - 58, forge[0] + 84, forge[1] + 56), fill=rgba((255, 92, 30), 196))
    draw.ellipse(box(forge[0] - 46, forge[1] - 34, forge[0] + 50, forge[1] + 34), fill=rgba((255, 194, 66), 164))
    for i in range(7):
        x = forge[0] - 100 + i * 33
        draw.line([xy(x, forge[1] - 74), xy(x + 12, forge[1] + 80)], fill=rgba((22, 14, 10), 116), width=3)
    draw.rounded_rectangle(box(forge[0] - 126, forge[1] - 126, forge[0] + 128, forge[1] - 80), radius=8, fill=rgba((38, 24, 18), 225), outline=rgba((236, 136, 68), 78), width=2)
    for i in range(34):
        angle = -math.pi * 0.94 + i * math.pi / 33.0
        radius = 44 + (i % 4) * 16
        x = forge[0] + math.cos(angle) * radius
        y = forge[1] - 18 + math.sin(angle) * radius * 0.62
        draw.line([xy(x, y), xy(x + math.cos(angle) * 16, y + math.sin(angle) * 8)], fill=rgba((255, 186, 58), 64 + (i % 3) * 26), width=1)


def draw_anvil(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    base = (w * 0.51, h * 0.672)
    draw_shadow(image, (base[0], base[1] + 58), (140, 22), 86)
    draw.rounded_rectangle(box(base[0] - 70, base[1] - 38, base[0] + 72, base[1] + 16), radius=9, fill=rgba((54, 54, 50), 232), outline=rgba((210, 190, 142), 94), width=3)
    draw.polygon(poly([(base[0] - 100, base[1] - 28), (base[0] - 70, base[1] - 8), (base[0] - 72, base[1] + 12), (base[0] - 122, base[1] + 4)]), fill=rgba((70, 70, 66), 210))
    draw.polygon(poly([(base[0] + 72, base[1] - 26), (base[0] + 126, base[1] - 10), (base[0] + 72, base[1] + 10)]), fill=rgba((80, 78, 70), 215))
    draw.rectangle(box(base[0] - 38, base[1] + 12, base[0] + 42, base[1] + 84), fill=rgba((42, 38, 34), 220))
    draw.line([xy(base[0] - 78, base[1] - 30), xy(base[0] + 70, base[1] - 36)], fill=rgba((236, 220, 166), 84), width=2)
    draw.line([xy(base[0] - 6, base[1] - 72), xy(base[0] + 86, base[1] - 36)], fill=rgba((204, 168, 102), 126), width=7)
    draw.rounded_rectangle(box(base[0] - 30, base[1] - 86, base[0] + 18, base[1] - 58), radius=4, fill=rgba((78, 42, 22), 210))


def draw_workbench(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = (w * 0.060, h * 0.430, w * 0.345, h * 0.590)
    draw_shadow(image, (w * 0.20, h * 0.612), (220, 24), 72)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((76, 43, 26), 238), outline=rgba((196, 98, 48), 100), width=3)
    draw.polygon(poly([(rect[0] + 24, rect[1] + 24), (rect[2] - 12, rect[1] + 14), (rect[2] - 42, rect[3] + 36), (rect[0] + 50, rect[3] + 42)]), fill=rgba((146, 75, 35), 116))
    for i in range(5):
        x = rect[0] + 52 + i * 78
        draw.line([xy(x, rect[1] + 24), xy(x - 10, rect[3] - 10)], fill=rgba((24, 16, 12), 112), width=2)
    for i in range(8):
        x = rect[0] + 50 + i * 50
        y = rect[1] - 16 + (i % 2) * 9
        draw.line([xy(x - 18, y + 12), xy(x + 22, y - 12)], fill=rgba((196, 188, 160), 150), width=4)
        draw.ellipse(box(x - 28, y + 7, x - 18, y + 17), fill=rgba((238, 90, 38), 126))


def draw_figure(draw: ImageDraw.ImageDraw, image: Image.Image, foot: tuple[float, float], scale: float, side: float, alpha: int) -> None:
    x, y = foot
    body_h = 128 * scale
    body_w = 34 * scale
    shoulder = (x, y - body_h * 0.64)
    hip = (x - side * 6 * scale, y - body_h * 0.22)
    head = (x + side * 6 * scale, y - body_h * 0.88)
    draw_shadow(image, (x, y + 7 * scale), (38 * scale, 8 * scale), round(alpha * 0.24))
    draw.polygon(poly([
        (shoulder[0] - body_w, shoulder[1]),
        (shoulder[0] + body_w * 0.88, shoulder[1] + 6 * scale),
        (hip[0] + body_w * 0.78, hip[1]),
        (x + body_w * 0.40, y),
        (x - body_w * 0.72, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba((72, 48, 34), alpha))
    draw.ellipse(box(head[0] - 13 * scale, head[1] - 13 * scale, head[0] + 13 * scale, head[1] + 13 * scale), fill=rgba((46, 28, 20), alpha))
    hand = (shoulder[0] + side * body_w * 1.65, shoulder[1] + body_h * 0.16)
    draw.line([xy(shoulder[0] + side * body_w * 0.70, shoulder[1] + 10 * scale), xy(*hand)], fill=rgba((30, 20, 15), alpha), width=max(1, round(4 * scale)))
    hammer_tip = (hand[0] + side * 48 * scale, hand[1] - 44 * scale)
    draw.line([xy(*hand), xy(*hammer_tip)], fill=rgba((184, 164, 126), round(alpha * 0.82)), width=max(1, round(3 * scale)))
    draw.rounded_rectangle(box(hammer_tip[0] - 16 * scale, hammer_tip[1] - 8 * scale, hammer_tip[0] + 16 * scale, hammer_tip[1] + 8 * scale), radius=2, fill=rgba((52, 44, 38), alpha))


def draw_side_props(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for i in range(7):
        x = w * (0.63 + (i % 4) * 0.052)
        y = h * (0.755 + (i // 4) * 0.055)
        draw_shadow(image, (x, y + 16), (34, 8), 54)
        draw.rectangle(box(x - 28, y - 24, x + 28, y + 14), fill=rgba((34, 24, 20), 188))
        draw.line([xy(x - 22, y - 6), xy(x + 18, y - 18)], fill=rgba((210, 178, 126), 104), width=2)
    for i in range(7):
        x = w * (0.075 + i * 0.038)
        y = h * (0.742 + (i % 2) * 0.048)
        draw_shadow(image, (x, y + 20), (26, 6), 48)
        draw.ellipse(box(x - 18, y - 22, x + 18, y + 26), fill=rgba((38, 30, 26), 178), outline=rgba((210, 92, 46), 58), width=2)


def draw_sparks_and_smoke(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    rng = random.Random("blacksmith-v2-sparks")
    w, h = SIZE
    smoke = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    sd = ImageDraw.Draw(smoke)
    for i in range(26):
        x = w * (0.64 + rng.random() * 0.26)
        y = h * (0.26 + rng.random() * 0.24)
        rx = rng.uniform(45, 120)
        ry = rng.uniform(18, 42)
        sd.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba((24, 24, 22), rng.randint(18, 42)))
    smoke = smoke.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(smoke)
    for _ in range(170):
        x = w * (0.60 + rng.random() * 0.34)
        y = h * (0.36 + rng.random() * 0.34)
        length = rng.uniform(4, 22)
        angle = rng.uniform(-1.3, 0.25)
        alpha = rng.randint(30, 118)
        color = (255, rng.randint(138, 218), rng.randint(38, 90))
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length)], fill=rgba(color, alpha), width=1)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x in [60, w - 60]:
        draw.rounded_rectangle(box(x - 26, 34, x + 26, h - 42), radius=9, fill=rgba((18, 12, 10), 216))
        draw.line([xy(x + (12 if x < w * 0.5 else -12), 72), xy(x + (12 if x < w * 0.5 else -12), h - 76)], fill=rgba((238, 94, 42), 52), width=3)
    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, 46), fill=(12, 8, 7, 198))
    vd.rectangle(box(0, h * 0.895, w, h), fill=(9, 7, 6, 126))
    vd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 82))
    vd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 82))
    vignette = vignette.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(vignette)


def add_texture(image: Image.Image) -> None:
    rng = random.Random("blacksmith-interior-v2-texture")
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(3100):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 25)
        alpha = rng.randint(5, 26)
        color = (255, 190, 122) if rng.random() > 0.55 else (36, 24, 20)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(220):
        x = rng.uniform(w * 0.18, w * 0.88)
        y = rng.uniform(h * 0.53, h * 0.90)
        r = rng.uniform(1.0, 3.8)
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba((255, 112, 38), rng.randint(18, 66)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (34, 29, 28), (82, 58, 48))
    draw = ImageDraw.Draw(image)
    draw_wall(draw, image)
    draw_floor(draw)
    draw_weapon_rack(draw, image, SIZE[0] * 0.205, SIZE[1] * 0.305, -1.0)
    draw_weapon_rack(draw, image, SIZE[0] * 0.800, SIZE[1] * 0.305, 1.0)
    draw_workbench(draw, image)
    draw_forge(draw, image)
    draw_anvil(draw, image)
    draw_figure(draw, image, (SIZE[0] * 0.485, SIZE[1] * 0.666), 0.78, 1.0, 138)
    draw_figure(draw, image, (SIZE[0] * 0.690, SIZE[1] * 0.520), 0.62, -1.0, 104)
    draw_side_props(draw, image)
    draw_sparks_and_smoke(draw, image)
    draw_foreground(draw, image)
    add_texture(image)
    return image.convert("RGB")


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image = render()
    image.save(OUT, optimize=True)
    print(f"OK generated {OUT} size={SIZE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
