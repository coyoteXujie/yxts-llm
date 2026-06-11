#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_blacksmith_interior_v2 import SIZE, add_glow, box, draw_shadow, gradient, poly, rgba, xy


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_medicine_dnf_interior_v2.png"


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((56, 72, 48), 250))
    draw.rectangle(box(0, 0, w, 58), fill=rgba((15, 20, 14), 224))
    for x in [88, 220, 408, 642, 840, 1094, 1374, 1510]:
        draw.rectangle(box(x - 16, 40, x + 16, wall_bottom + 34), fill=rgba((22, 30, 20), 178))
        draw.line([xy(x + 5, 76), xy(x - 6, wall_bottom - 22)], fill=rgba((122, 186, 86), 34), width=2)
    for y in [112, 194, 284, 374]:
        draw.line([xy(70, y), xy(w - 70, y - 16)], fill=rgba((20, 28, 18), 124), width=5)
        draw.line([xy(70, y + 14), xy(w - 70, y - 2)], fill=rgba((138, 202, 96), 34), width=2)
    draw.rounded_rectangle(box(w * 0.405, h * 0.178, w * 0.595, h * 0.250), radius=6, fill=rgba((30, 46, 24), 238), outline=rgba((174, 224, 112), 118), width=3)
    for i in range(5):
        x = w * (0.430 + i * 0.034)
        draw.line([xy(x, h * 0.196), xy(x - 14, h * 0.236)], fill=rgba((230, 240, 156), 138), width=4)
    add_glow(image, (w * 0.50, h * 0.274), 150, (122, 196, 86), 20)


def draw_floor(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((96, 77, 50), 246))
    draw.polygon(poly([(w * 0.12, top + 36), (w * 0.88, top + 14), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((134, 104, 60), 78))
    for i in range(17):
        t = i / 16.0
        y = top + (t * t) * (h - top - 30)
        draw.line([xy(w * (-0.05 + t * 0.08), y), xy(w * (1.05 - t * 0.08), y - 17)], fill=rgba((38, 31, 22), round(120 - t * 48)), width=max(1, round(1.4 + t * 3.4)))
    for i in range(16):
        t = i / 15.0
        if i % 3 == 1:
            continue
        x = w * (0.03 + t * 0.94)
        target = w * (0.50 + math.sin(i * 0.49) * 0.028)
        draw.line([xy(x, h), xy(target, top + 30)], fill=rgba((48, 38, 24), 18 + round(abs(t - 0.5) * 30)), width=1)
    draw.polygon(poly([(w * 0.23, h * 0.662), (w * 0.77, h * 0.638), (w * 0.68, h * 0.854), (w * 0.31, h * 0.870)]), fill=rgba((48, 92, 56), 138))
    draw.polygon(poly([(w * 0.31, h * 0.710), (w * 0.69, h * 0.692), (w * 0.63, h * 0.820), (w * 0.37, h * 0.833)]), fill=rgba((76, 132, 72), 84))


def draw_drawer_cabinet(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = (w * 0.365, h * 0.135, w * 0.635, h * 0.420)
    draw_shadow(image, (w * 0.50, h * 0.432), (260, 18), 56)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((38, 48, 28), 232), outline=rgba((138, 214, 86), 114), width=3)
    draw.rectangle(box(rect[0] + 18, rect[1] + 18, rect[2] - 18, rect[3] - 18), fill=rgba((76, 48, 26), 138))
    cols = 7
    rows = 5
    cell_w = (rect[2] - rect[0] - 60) / cols
    cell_h = (rect[3] - rect[1] - 56) / rows
    for row in range(rows):
        for col in range(cols):
            x = rect[0] + 30 + col * cell_w
            y = rect[1] + 30 + row * cell_h
            drawer = box(x, y, x + cell_w * 0.78, y + cell_h * 0.66)
            fill = (92 + (row % 2) * 10, 56 + (col % 3) * 6, 30)
            draw.rectangle(drawer, fill=rgba(fill, 182), outline=rgba((152, 218, 96), 80))
            cx = (drawer[0] + drawer[2]) * 0.5
            cy = (drawer[1] + drawer[3]) * 0.5
            draw.ellipse(box(cx - 3, cy - 3, cx + 3, cy + 3), fill=rgba((220, 184, 92), 108))
    add_glow(image, (w * 0.50, h * 0.408), 160, (124, 196, 88), 18)


def draw_side_shelf(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, side: float) -> None:
    w, h = SIZE
    rect = (x - 142, h * 0.135, x + 142, h * 0.415)
    draw_shadow(image, (x, h * 0.432), (150, 16), 46)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((34, 42, 26), 218), outline=rgba((126, 196, 82), 86), width=2)
    for row in range(4):
        y = rect[1] + 40 + row * 56
        draw.line([xy(rect[0] + 22, y), xy(rect[2] - 22, y - 5)], fill=rgba((126, 84, 42), 154), width=4)
        for col in range(6):
            px = rect[0] + 42 + col * 39
            if (row + col) % 2 == 0:
                draw.ellipse(box(px - 10, y - 30, px + 10, y - 10), fill=rgba((86, 158, 70), 136))
            else:
                draw.rounded_rectangle(box(px - 10, y - 34, px + 10, y - 10), radius=3, fill=rgba((94, 52, 28), 156), outline=rgba((156, 210, 92), 64), width=1)
    for i in range(4):
        px = x + side * (90 - i * 36)
        draw.line([xy(px, h * 0.115), xy(px + side * 8, h * (0.200 + i * 0.012))], fill=rgba((170, 210, 118), 82), width=2)
        draw.ellipse(box(px + side * 2 - 9, h * (0.205 + i * 0.012) - 6, px + side * 2 + 9, h * (0.205 + i * 0.012) + 16), fill=rgba((80, 154, 70), 110))


def draw_counter(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rect = (w * 0.070, h * 0.425, w * 0.355, h * 0.585)
    draw_shadow(image, (w * 0.21, h * 0.610), (215, 24), 70)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((76, 46, 27), 238), outline=rgba((152, 206, 86), 102), width=3)
    draw.polygon(poly([(rect[0] + 24, rect[1] + 24), (rect[2] - 12, rect[1] + 14), (rect[2] - 42, rect[3] + 36), (rect[0] + 50, rect[3] + 42)]), fill=rgba((136, 88, 42), 116))
    for i in range(5):
        x = rect[0] + 52 + i * 78
        draw.line([xy(x, rect[1] + 24), xy(x - 10, rect[3] - 10)], fill=rgba((24, 18, 12), 112), width=2)
    draw_scale(draw, (w * 0.245, h * 0.410), 0.84)
    draw_mortar(draw, (w * 0.145, h * 0.415), 0.82)
    for i in range(8):
        x = rect[0] + 44 + i * 48
        y = rect[1] - 14 + (i % 2) * 7
        draw.rounded_rectangle(box(x - 12, y - 20, x + 12, y + 9), radius=3, fill=rgba((94, 50, 28), 174), outline=rgba((132, 204, 84), 86), width=1)


def draw_scale(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float) -> None:
    x, y = center
    draw.line([xy(x, y - 58 * scale), xy(x, y + 8 * scale)], fill=rgba((210, 186, 116), 146), width=max(1, round(3 * scale)))
    draw.line([xy(x - 64 * scale, y - 42 * scale), xy(x + 64 * scale, y - 42 * scale)], fill=rgba((214, 188, 112), 150), width=max(1, round(2 * scale)))
    for side in [-1.0, 1.0]:
        px = x + side * 56 * scale
        draw.line([xy(px, y - 42 * scale), xy(px - side * 16 * scale, y - 8 * scale)], fill=rgba((210, 186, 116), 118), width=1)
        draw.ellipse(box(px - 30 * scale, y - 10 * scale, px + 30 * scale, y + 6 * scale), fill=rgba((92, 68, 38), 138), outline=rgba((218, 196, 132), 92), width=max(1, round(1.3 * scale)))


def draw_mortar(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float) -> None:
    x, y = center
    draw.ellipse(box(x - 34 * scale, y - 10 * scale, x + 34 * scale, y + 24 * scale), fill=rgba((44, 54, 38), 184), outline=rgba((150, 210, 108), 74), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 24 * scale, y - 22 * scale, x + 24 * scale, y + 8 * scale), fill=rgba((70, 100, 54), 166))
    draw.line([xy(x + 14 * scale, y - 30 * scale), xy(x + 54 * scale, y - 60 * scale)], fill=rgba((132, 88, 48), 156), width=max(1, round(5 * scale)))


def draw_brewing_table(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    base = (w * 0.750, h * 0.565)
    draw_shadow(image, (base[0], base[1] + 80), (190, 22), 66)
    add_glow(image, (base[0], base[1] + 10), 190, (88, 178, 94), 54)
    draw.rounded_rectangle(box(base[0] - 138, base[1] - 44, base[0] + 138, base[1] + 62), radius=10, fill=rgba((48, 36, 26), 224), outline=rgba((132, 202, 86), 98), width=3)
    draw.ellipse(box(base[0] - 60, base[1] - 66, base[0] + 62, base[1] + 38), fill=rgba((34, 50, 34), 214), outline=rgba((174, 222, 118), 82), width=3)
    draw.ellipse(box(base[0] - 42, base[1] - 54, base[0] + 44, base[1] + 12), fill=rgba((84, 176, 88), 130))
    for i in range(7):
        x = base[0] - 110 + i * 36
        draw.rounded_rectangle(box(x - 12, base[1] - 88, x + 12, base[1] - 34), radius=5, fill=rgba((72, 38, 22), 156), outline=rgba((132, 208, 86), 62), width=1)
    for i in range(20):
        t = i / 19.0
        x = base[0] - 48 + t * 96
        y = base[1] - 96 - math.sin(t * math.pi * 3.0) * 10
        draw.line([xy(x, y), xy(x + 10, y - 34 - (i % 3) * 8)], fill=rgba((122, 214, 134), 34 + (i % 4) * 12), width=1)


def draw_hanging_herbs(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    for i in range(14):
        x = w * (0.18 + i * 0.050)
        y = h * (0.105 + (i % 3) * 0.012)
        draw.line([xy(x, h * 0.052), xy(x + 4, y + 70)], fill=rgba((160, 210, 124), 88), width=2)
        for k in range(5):
            px = x + math.sin(k * 1.7 + i) * 12
            py = y + 24 + k * 10
            draw.ellipse(box(px - 8, py - 5, px + 8, py + 8), fill=rgba((74, 148, 66), 98 - k * 8))


def draw_figure(draw: ImageDraw.ImageDraw, image: Image.Image, foot: tuple[float, float], scale: float, side: float, cloth: tuple[int, int, int], alpha: int) -> None:
    x, y = foot
    body_h = 126 * scale
    body_w = 32 * scale
    shoulder = (x, y - body_h * 0.64)
    hip = (x - side * 6 * scale, y - body_h * 0.22)
    head = (x + side * 6 * scale, y - body_h * 0.88)
    draw_shadow(image, (x, y + 7 * scale), (36 * scale, 8 * scale), round(alpha * 0.24))
    draw.polygon(poly([
        (shoulder[0] - body_w, shoulder[1]),
        (shoulder[0] + body_w * 0.90, shoulder[1] + 6 * scale),
        (hip[0] + body_w * 0.78, hip[1]),
        (x + body_w * 0.40, y),
        (x - body_w * 0.72, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba(cloth, alpha))
    draw.ellipse(box(head[0] - 13 * scale, head[1] - 13 * scale, head[0] + 13 * scale, head[1] + 13 * scale), fill=rgba((42, 30, 22), alpha))
    hand = (shoulder[0] + side * body_w * 1.60, shoulder[1] + body_h * 0.16)
    draw.line([xy(shoulder[0] + side * body_w * 0.70, shoulder[1] + 10 * scale), xy(*hand)], fill=rgba((30, 22, 16), alpha), width=max(1, round(4 * scale)))
    draw.rounded_rectangle(box(hand[0] - 8 * scale, hand[1] - 12 * scale, hand[0] + 10 * scale, hand[1] + 16 * scale), radius=2, fill=rgba((86, 130, 62), round(alpha * 0.74)))


def draw_floor_props(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for i in range(9):
        x = w * (0.085 + (i % 5) * 0.060)
        y = h * (0.720 + (i // 5) * 0.070 + (i % 2) * 0.018)
        draw_shadow(image, (x, y + 18), (26, 6), 46)
        draw.ellipse(box(x - 18, y - 22, x + 18, y + 26), fill=rgba((44, 58, 34), 166), outline=rgba((132, 206, 86), 56), width=2)
    for i in range(7):
        x = w * (0.605 + (i % 4) * 0.060)
        y = h * (0.735 + (i // 4) * 0.064)
        draw_shadow(image, (x, y + 16), (32, 7), 50)
        draw.rectangle(box(x - 30, y - 22, x + 30, y + 14), fill=rgba((56, 38, 24), 170))
        draw.line([xy(x - 22, y - 4), xy(x + 22, y - 14)], fill=rgba((156, 214, 98), 74), width=2)


def draw_vapor_and_motes(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    rng = random.Random("medicine-v2-vapor")
    w, h = SIZE
    vapor = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vapor)
    for _ in range(30):
        x = w * (0.62 + rng.random() * 0.25)
        y = h * (0.30 + rng.random() * 0.30)
        rx = rng.uniform(35, 116)
        ry = rng.uniform(16, 46)
        vd.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba((92, 180, 116), rng.randint(16, 42)))
    vapor = vapor.filter(ImageFilter.GaussianBlur(20))
    image.alpha_composite(vapor)
    for _ in range(150):
        x = w * (0.18 + rng.random() * 0.70)
        y = h * (0.30 + rng.random() * 0.48)
        length = rng.uniform(4, 18)
        angle = rng.uniform(-0.9, 0.4)
        alpha = rng.randint(18, 70)
        color = (rng.randint(116, 190), rng.randint(190, 238), rng.randint(90, 140))
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length)], fill=rgba(color, alpha), width=1)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x in [60, w - 60]:
        draw.rounded_rectangle(box(x - 26, 34, x + 26, h - 42), radius=9, fill=rgba((14, 18, 12), 214))
        draw.line([xy(x + (12 if x < w * 0.5 else -12), 72), xy(x + (12 if x < w * 0.5 else -12), h - 76)], fill=rgba((132, 208, 86), 56), width=3)
    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, 46), fill=(10, 14, 9, 198))
    vd.rectangle(box(0, h * 0.895, w, h), fill=(8, 10, 6, 126))
    vd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 78))
    vd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 78))
    vignette = vignette.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(vignette)


def add_texture(image: Image.Image) -> None:
    rng = random.Random("medicine-interior-v2-texture")
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(3100):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 25)
        alpha = rng.randint(5, 26)
        color = (206, 238, 156) if rng.random() > 0.58 else (30, 42, 22)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(240):
        x = rng.uniform(w * 0.18, w * 0.86)
        y = rng.uniform(h * 0.54, h * 0.90)
        r = rng.uniform(1.0, 3.6)
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba((128, 220, 92), rng.randint(16, 58)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (28, 36, 28), (72, 72, 46))
    draw = ImageDraw.Draw(image)
    draw_wall(draw, image)
    draw_floor(draw)
    draw_hanging_herbs(draw)
    draw_side_shelf(draw, image, SIZE[0] * 0.205, -1.0)
    draw_side_shelf(draw, image, SIZE[0] * 0.800, 1.0)
    draw_drawer_cabinet(draw, image)
    draw_counter(draw, image)
    draw_brewing_table(draw, image)
    draw_figure(draw, image, (SIZE[0] * 0.455, SIZE[1] * 0.666), 0.76, 1.0, (56, 74, 42), 136)
    draw_figure(draw, image, (SIZE[0] * 0.690, SIZE[1] * 0.520), 0.62, -1.0, (60, 88, 62), 104)
    draw_floor_props(draw, image)
    draw_vapor_and_motes(draw, image)
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
