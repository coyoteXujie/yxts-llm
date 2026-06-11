#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_blacksmith_interior_v2 import SIZE, add_glow, box, draw_shadow, gradient, poly, rgba, xy


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_teahouse_dnf_interior_v2.png"


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((62, 58, 42), 250))
    draw.rectangle(box(0, 0, w, 58), fill=rgba((16, 16, 10), 230))
    for x in [82, 214, 420, 660, 852, 1098, 1376, 1516]:
        draw.rectangle(box(x - 17, 40, x + 17, wall_bottom + 34), fill=rgba((26, 24, 16), 188))
        draw.line([xy(x + 5, 78), xy(x - 8, wall_bottom - 18)], fill=rgba((176, 214, 118), 34), width=2)
    for y in [112, 198, 290, 380]:
        draw.line([xy(70, y), xy(w - 70, y - 16)], fill=rgba((22, 20, 14), 126), width=5)
        draw.line([xy(70, y + 14), xy(w - 70, y - 2)], fill=rgba((184, 218, 126), 34), width=2)
    sign = box(w * 0.397, h * 0.165, w * 0.603, h * 0.252)
    draw.rounded_rectangle(sign, radius=6, fill=rgba((34, 42, 24), 240), outline=rgba((210, 222, 136), 124), width=3)
    for i in range(5):
        x = w * (0.425 + i * 0.038)
        draw.line([xy(x, h * 0.193), xy(x - 14, h * 0.235)], fill=rgba((238, 232, 156), 142), width=4)
    add_glow(image, (w * 0.50, h * 0.276), 160, (178, 220, 118), 20)


def draw_floor(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((82, 70, 50), 246))
    draw.polygon(poly([(w * 0.10, top + 36), (w * 0.90, top + 12), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((128, 104, 62), 76))
    for i in range(18):
        t = i / 17.0
        y = top + (t * t) * (h - top - 30)
        draw.line([xy(w * (-0.05 + t * 0.08), y), xy(w * (1.05 - t * 0.08), y - 17)], fill=rgba((36, 31, 22), round(124 - t * 48)), width=max(1, round(1.4 + t * 3.5)))
    for i in range(17):
        t = i / 16.0
        if i % 3 == 1:
            continue
        x = w * (0.03 + t * 0.94)
        target = w * (0.50 + math.sin(i * 0.50) * 0.030)
        draw.line([xy(x, h), xy(target, top + 30)], fill=rgba((48, 39, 25), 18 + round(abs(t - 0.5) * 30)), width=1)
    draw.polygon(poly([(w * 0.21, h * 0.660), (w * 0.79, h * 0.628), (w * 0.69, h * 0.868), (w * 0.30, h * 0.880)]), fill=rgba((62, 92, 54), 126))
    draw.polygon(poly([(w * 0.31, h * 0.710), (w * 0.69, h * 0.688), (w * 0.63, h * 0.820), (w * 0.36, h * 0.838)]), fill=rgba((112, 138, 74), 78))


def draw_windows(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x in [w * 0.245, w * 0.755]:
        rect = (x - 120, h * 0.135, x + 120, h * 0.315)
        draw_shadow(image, (x, h * 0.335), (122, 14), 34)
        draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((36, 54, 48), 150), outline=rgba((186, 220, 130), 78), width=3)
        for i in range(4):
            xx = rect[0] + 40 + i * 48
            draw.line([xy(xx, rect[1] + 16), xy(xx, rect[3] - 14)], fill=rgba((22, 24, 16), 120), width=3)
        for row in range(3):
            yy = rect[1] + 42 + row * 42
            draw.line([xy(rect[0] + 14, yy), xy(rect[2] - 14, yy - 6)], fill=rgba((22, 24, 16), 116), width=3)
        add_glow(image, (x, h * 0.250), 118, (120, 178, 150), 18)


def draw_tea_shelf(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, side: float) -> None:
    w, h = SIZE
    rect = (x - 145, h * 0.168, x + 145, h * 0.430)
    draw_shadow(image, (x, h * 0.448), (150, 17), 48)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((36, 34, 22), 218), outline=rgba((178, 216, 116), 84), width=2)
    colors = [(82, 112, 58), (128, 76, 40), (58, 94, 86), (150, 118, 54), (92, 62, 40)]
    for row in range(4):
        y = rect[1] + 42 + row * 52
        draw.line([xy(rect[0] + 22, y + 6), xy(rect[2] - 22, y - 2)], fill=rgba((126, 92, 48), 150), width=4)
        for col in range(6):
            px = rect[0] + 40 + col * 40
            color = colors[(row + col) % len(colors)]
            if (row + col) % 2 == 0:
                draw.ellipse(box(px - 12, y - 34, px + 12, y - 8), fill=rgba(color, 158), outline=rgba((204, 220, 132), 48), width=1)
                draw.rectangle(box(px - 9, y - 18, px + 9, y - 2), fill=rgba(color, 152))
            else:
                draw.rounded_rectangle(box(px - 12, y - 36, px + 12, y - 8), radius=4, fill=rgba(color, 148), outline=rgba((204, 220, 132), 50), width=1)
    for i in range(4):
        px = x + side * (92 - i * 40)
        draw.line([xy(px, h * 0.108), xy(px + side * 8, h * (0.184 + i * 0.010))], fill=rgba((198, 220, 138), 76), width=2)
        draw.ellipse(box(px - 8, h * (0.188 + i * 0.010), px + 10, h * (0.238 + i * 0.010)), fill=rgba((84, 132, 72), 100))


def draw_counter(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = (w * 0.068, h * 0.430, w * 0.352, h * 0.588)
    draw_shadow(image, (w * 0.205, h * 0.612), (218, 24), 68)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((74, 48, 28), 238), outline=rgba((186, 220, 126), 96), width=3)
    draw.polygon(poly([(rect[0] + 24, rect[1] + 22), (rect[2] - 12, rect[1] + 14), (rect[2] - 42, rect[3] + 36), (rect[0] + 50, rect[3] + 42)]), fill=rgba((136, 92, 42), 112))
    for i in range(5):
        x = rect[0] + 52 + i * 78
        draw.line([xy(x, rect[1] + 24), xy(x - 10, rect[3] - 10)], fill=rgba((24, 18, 12), 108), width=2)
    for i in range(8):
        x = rect[0] + 46 + i * 48
        y = rect[1] - 14 + (i % 2) * 7
        draw.rounded_rectangle(box(x - 12, y - 24, x + 12, y + 8), radius=4, fill=rgba((70, 104, 54), 162), outline=rgba((196, 224, 126), 58), width=1)
    draw_teapot(draw, image, (w * 0.270, h * 0.414), 0.84, (72, 92, 58))
    draw_teacups(draw, (w * 0.140, h * 0.417), 0.78)


def draw_teapot(draw: ImageDraw.ImageDraw, image: Image.Image, center: tuple[float, float], scale: float, color: tuple[int, int, int]) -> None:
    x, y = center
    draw_shadow(image, (x, y + 24 * scale), (42 * scale, 8 * scale), 36)
    draw.ellipse(box(x - 38 * scale, y - 28 * scale, x + 38 * scale, y + 28 * scale), fill=rgba(color, 186), outline=rgba((210, 224, 148), 68), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 17 * scale, y - 45 * scale, x + 18 * scale, y - 18 * scale), fill=rgba(color, 164))
    draw.arc(box(x + 20 * scale, y - 18 * scale, x + 70 * scale, y + 30 * scale), start=250, end=470, fill=rgba((210, 224, 148), 112), width=max(1, round(3 * scale)))
    draw.polygon(poly([(x - 36 * scale, y - 5 * scale), (x - 78 * scale, y - 18 * scale), (x - 38 * scale, y + 8 * scale)]), fill=rgba(color, 152))
    add_glow(image, (x, y - 10 * scale), 72 * scale, (148, 210, 118), 14)


def draw_teacups(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float) -> None:
    x, y = center
    for i in range(4):
        px = x + i * 28 * scale
        draw.ellipse(box(px - 12 * scale, y - 10 * scale, px + 12 * scale, y + 7 * scale), fill=rgba((212, 220, 160), 128), outline=rgba((86, 112, 64), 70), width=max(1, round(1.2 * scale)))
        draw.rectangle(box(px - 10 * scale, y - 4 * scale, px + 10 * scale, y + 13 * scale), fill=rgba((80, 108, 62), 132))
        draw.ellipse(box(px - 10 * scale, y + 3 * scale, px + 10 * scale, y + 16 * scale), fill=rgba((48, 68, 42), 130))


def draw_table(draw: ImageDraw.ImageDraw, image: Image.Image, center: tuple[float, float], scale: float, color: tuple[int, int, int]) -> None:
    x, y = center
    draw_shadow(image, (x, y + 70 * scale), (120 * scale, 18 * scale), 62)
    draw.ellipse(box(x - 118 * scale, y - 44 * scale, x + 118 * scale, y + 48 * scale), fill=rgba(color, 220), outline=rgba((204, 220, 138), 72), width=max(1, round(3 * scale)))
    draw.ellipse(box(x - 88 * scale, y - 28 * scale, x + 88 * scale, y + 28 * scale), fill=rgba((116, 82, 44), 102))
    for leg_x in [x - 56 * scale, x + 54 * scale]:
        draw.line([xy(leg_x, y + 26 * scale), xy(leg_x - 12 * scale, y + 112 * scale)], fill=rgba((42, 30, 20), 208), width=max(1, round(7 * scale)))
    draw_teapot(draw, image, (x - 16 * scale, y - 26 * scale), 0.55 * scale, (74, 108, 64))
    draw_teacups(draw, (x + 42 * scale, y - 16 * scale), 0.60 * scale)


def draw_stove(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    base = (w * 0.755, h * 0.592)
    draw_shadow(image, (base[0], base[1] + 80), (165, 22), 66)
    add_glow(image, (base[0], base[1] + 12), 190, (224, 136, 58), 48)
    draw.rounded_rectangle(box(base[0] - 120, base[1] - 42, base[0] + 120, base[1] + 70), radius=10, fill=rgba((54, 38, 28), 226), outline=rgba((206, 178, 108), 80), width=3)
    draw.ellipse(box(base[0] - 54, base[1] - 62, base[0] + 56, base[1] + 28), fill=rgba((52, 64, 46), 212), outline=rgba((210, 224, 148), 80), width=3)
    draw.ellipse(box(base[0] - 35, base[1] - 52, base[0] + 36, base[1] + 3), fill=rgba((98, 120, 70), 120))
    for i in range(5):
        x = base[0] - 88 + i * 42
        draw.rounded_rectangle(box(x - 12, base[1] - 86, x + 12, base[1] - 34), radius=5, fill=rgba((86, 62, 38), 150), outline=rgba((204, 218, 132), 54), width=1)
    for i in range(24):
        t = i / 23.0
        x = base[0] - 46 + t * 92
        y = base[1] - 94 - math.sin(t * math.pi * 3.0) * 9
        draw.line([xy(x, y), xy(x + 8, y - 30 - (i % 3) * 8)], fill=rgba((204, 226, 176), 34 + (i % 4) * 10), width=1)


def draw_screen(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    x = w * 0.500
    y = h * 0.346
    draw_shadow(image, (x, y + 86), (160, 15), 42)
    for i in range(4):
        px = x - 126 + i * 84
        draw.rounded_rectangle(box(px - 34, y - 122, px + 34, y + 90), radius=5, fill=rgba((46, 58, 38), 144), outline=rgba((194, 220, 132), 60), width=2)
        draw.line([xy(px - 22, y - 90), xy(px + 18, y - 16)], fill=rgba((216, 222, 156), 38), width=2)
        for k in range(4):
            lx = px - 18 + k * 12
            draw.line([xy(lx, y - 54), xy(lx + 18, y + 64)], fill=rgba((76, 112, 62), 36), width=1)
    add_glow(image, (x, y - 20), 155, (148, 196, 118), 14)


def draw_figure(draw: ImageDraw.ImageDraw, image: Image.Image, foot: tuple[float, float], scale: float, side: float, cloth: tuple[int, int, int], alpha: int) -> None:
    x, y = foot
    body_h = 124 * scale
    body_w = 32 * scale
    shoulder = (x, y - body_h * 0.64)
    hip = (x - side * 6 * scale, y - body_h * 0.22)
    head = (x + side * 6 * scale, y - body_h * 0.88)
    draw_shadow(image, (x, y + 7 * scale), (36 * scale, 8 * scale), round(alpha * 0.24))
    draw.polygon(poly([
        (shoulder[0] - body_w, shoulder[1]),
        (shoulder[0] + body_w * 0.90, shoulder[1] + 7 * scale),
        (hip[0] + body_w * 0.76, hip[1]),
        (x + body_w * 0.42, y),
        (x - body_w * 0.72, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba(cloth, alpha))
    draw.ellipse(box(head[0] - 13 * scale, head[1] - 13 * scale, head[0] + 13 * scale, head[1] + 13 * scale), fill=rgba((40, 28, 20), alpha))
    hand = (shoulder[0] + side * body_w * 1.55, shoulder[1] + body_h * 0.18)
    draw.line([xy(shoulder[0] + side * body_w * 0.70, shoulder[1] + 9 * scale), xy(*hand)], fill=rgba((30, 22, 16), alpha), width=max(1, round(4 * scale)))
    draw.ellipse(box(hand[0] - 7 * scale, hand[1] - 7 * scale, hand[0] + 7 * scale, hand[1] + 7 * scale), fill=rgba((214, 220, 148), round(alpha * 0.68)))


def draw_floor_props(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for i in range(8):
        x = w * (0.070 + (i % 5) * 0.060)
        y = h * (0.735 + (i // 5) * 0.066 + (i % 2) * 0.016)
        draw_shadow(image, (x, y + 18), (25, 6), 40)
        draw.ellipse(box(x - 18, y - 22, x + 18, y + 24), fill=rgba((70, 96, 54), 150), outline=rgba((194, 220, 132), 54), width=2)
    for i in range(8):
        x = w * (0.595 + (i % 4) * 0.060)
        y = h * (0.755 + (i // 4) * 0.062)
        draw_shadow(image, (x, y + 14), (30, 6), 42)
        draw.rounded_rectangle(box(x - 24, y - 20, x + 24, y + 10), radius=4, fill=rgba((76, 52, 30), 154), outline=rgba((196, 218, 132), 44), width=1)
        draw.line([xy(x - 18, y - 6), xy(x + 16, y - 14)], fill=rgba((196, 220, 132), 44), width=1)


def draw_steam_and_motes(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    rng = random.Random("teahouse-v2-steam")
    w, h = SIZE
    steam = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    sd = ImageDraw.Draw(steam)
    for _ in range(32):
        x = w * (0.40 + rng.random() * 0.42)
        y = h * (0.26 + rng.random() * 0.42)
        rx = rng.uniform(38, 116)
        ry = rng.uniform(16, 42)
        sd.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba((204, 226, 180), rng.randint(12, 34)))
    steam = steam.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(steam)
    for _ in range(185):
        x = w * (0.16 + rng.random() * 0.72)
        y = h * (0.27 + rng.random() * 0.55)
        length = rng.uniform(4, 18)
        angle = rng.uniform(-0.9, 0.4)
        color = rng.choice([(220, 232, 168), (126, 180, 120), (224, 172, 94), (98, 132, 156)])
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length)], fill=rgba(color, rng.randint(16, 70)), width=1)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x, side in [(60, 1.0), (w - 60, -1.0)]:
        draw.rounded_rectangle(box(x - 26, 34, x + 26, h - 42), radius=9, fill=rgba((14, 14, 9), 216))
        draw.line([xy(x + side * 12, 74), xy(x + side * 12, h - 76)], fill=rgba((184, 220, 126), 54), width=3)
    for x, side in [(w * 0.105, 1.0), (w * 0.895, -1.0)]:
        draw.line([xy(x, h * 0.660), xy(x + side * 42, h * 0.920)], fill=rgba((42, 66, 36), 132), width=3)
        for i in range(8):
            y = h * (0.680 + i * 0.030)
            draw.ellipse(box(x + side * (8 + i * 3) - 18, y - 6, x + side * (8 + i * 3) + 18, y + 10), fill=rgba((70, 130, 62), 72))
    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, 46), fill=(9, 11, 7, 198))
    vd.rectangle(box(0, h * 0.895, w, h), fill=(7, 8, 5, 126))
    vd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 78))
    vd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 78))
    vignette = vignette.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(vignette)


def add_texture(image: Image.Image) -> None:
    rng = random.Random("teahouse-interior-v2-texture")
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(3650):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 26)
        alpha = rng.randint(5, 27)
        color = rng.choice([(220, 232, 156), (120, 164, 92), (218, 148, 84), (28, 32, 20)])
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(280):
        x = rng.uniform(w * 0.16, w * 0.86)
        y = rng.uniform(h * 0.53, h * 0.90)
        r = rng.uniform(1.0, 4.0)
        color = rng.choice([(210, 226, 140), (96, 158, 84), (218, 144, 78), (92, 132, 160)])
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(color, rng.randint(16, 62)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (30, 36, 26), (82, 72, 48))
    draw = ImageDraw.Draw(image)
    draw_wall(draw, image)
    draw_floor(draw)
    draw_windows(draw, image)
    draw_screen(draw, image)
    draw_tea_shelf(draw, image, SIZE[0] * 0.195, -1.0)
    draw_tea_shelf(draw, image, SIZE[0] * 0.805, 1.0)
    draw_counter(draw, image)
    draw_table(draw, image, (SIZE[0] * 0.465, SIZE[1] * 0.646), 0.95, (92, 58, 34))
    draw_table(draw, image, (SIZE[0] * 0.660, SIZE[1] * 0.590), 0.70, (78, 56, 36))
    draw_stove(draw, image)
    draw_figure(draw, image, (SIZE[0] * 0.370, SIZE[1] * 0.668), 0.72, 1.0, (64, 84, 48), 130)
    draw_figure(draw, image, (SIZE[0] * 0.555, SIZE[1] * 0.548), 0.58, -1.0, (86, 62, 42), 100)
    draw_figure(draw, image, (SIZE[0] * 0.720, SIZE[1] * 0.675), 0.76, -1.0, (74, 92, 64), 132)
    draw_floor_props(draw, image)
    draw_steam_and_motes(draw, image)
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
