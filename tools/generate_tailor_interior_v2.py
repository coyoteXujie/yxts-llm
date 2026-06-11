#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_blacksmith_interior_v2 import SIZE, add_glow, box, draw_shadow, gradient, poly, rgba, xy


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_tailor_dnf_interior_v2.png"


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((63, 48, 72), 250))
    draw.rectangle(box(0, 0, w, 58), fill=rgba((18, 13, 23), 230))
    for x in [78, 210, 408, 650, 850, 1100, 1370, 1518]:
        draw.rectangle(box(x - 16, 40, x + 16, wall_bottom + 34), fill=rgba((28, 20, 34), 188))
        draw.line([xy(x + 5, 78), xy(x - 7, wall_bottom - 20)], fill=rgba((232, 164, 92), 34), width=2)
    for y in [112, 198, 292, 380]:
        draw.line([xy(68, y), xy(w - 70, y - 16)], fill=rgba((26, 18, 30), 126), width=5)
        draw.line([xy(70, y + 14), xy(w - 72, y - 2)], fill=rgba((236, 178, 112), 38), width=2)
    sign = box(w * 0.405, h * 0.170, w * 0.595, h * 0.250)
    draw.rounded_rectangle(sign, radius=6, fill=rgba((42, 30, 48), 240), outline=rgba((238, 192, 118), 122), width=3)
    for i in range(5):
        x = w * (0.424 + i * 0.038)
        draw.line([xy(x, h * 0.194), xy(x - 14, h * 0.235)], fill=rgba((255, 214, 142), 142), width=4)
    add_glow(image, (w * 0.50, h * 0.278), 155, (236, 176, 112), 22)


def draw_floor(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((82, 67, 62), 246))
    draw.polygon(poly([(w * 0.12, top + 38), (w * 0.88, top + 14), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((138, 96, 82), 78))
    for i in range(17):
        t = i / 16.0
        y = top + (t * t) * (h - top - 30)
        draw.line([xy(w * (-0.05 + t * 0.08), y), xy(w * (1.05 - t * 0.08), y - 17)], fill=rgba((35, 28, 30), round(124 - t * 48)), width=max(1, round(1.4 + t * 3.4)))
    for i in range(16):
        t = i / 15.0
        if i % 3 == 1:
            continue
        x = w * (0.03 + t * 0.94)
        target = w * (0.50 + math.sin(i * 0.57) * 0.030)
        draw.line([xy(x, h), xy(target, top + 30)], fill=rgba((48, 36, 36), 16 + round(abs(t - 0.5) * 30)), width=1)
    draw.polygon(poly([(w * 0.20, h * 0.655), (w * 0.80, h * 0.625), (w * 0.70, h * 0.865), (w * 0.29, h * 0.878)]), fill=rgba((88, 44, 72), 132))
    draw.polygon(poly([(w * 0.31, h * 0.705), (w * 0.69, h * 0.686), (w * 0.63, h * 0.820), (w * 0.36, h * 0.836)]), fill=rgba((150, 78, 92), 84))
    for i in range(44):
        x = w * (0.24 + (i % 11) * 0.050)
        y = h * (0.686 + (i // 11) * 0.043)
        draw.line([xy(x, y), xy(x + 36, y - 6)], fill=rgba((238, 184, 126), 38), width=1)


def draw_fabric_roll(draw: ImageDraw.ImageDraw, image: Image.Image, center: tuple[float, float], size: tuple[float, float], color: tuple[int, int, int], side: float) -> None:
    x, y = center
    rw, rh = size
    draw_shadow(image, (x, y + rh * 0.44), (rw * 0.46, rh * 0.08), 42)
    draw.rounded_rectangle(box(x - rw * 0.50, y - rh * 0.46, x + rw * 0.50, y + rh * 0.42), radius=max(3, round(rh * 0.10)), fill=rgba(color, 176), outline=rgba((246, 210, 144), 64), width=2)
    for i in range(5):
        xx = x - rw * 0.38 + i * rw * 0.19
        draw.line([xy(xx, y - rh * 0.38), xy(xx - side * rw * 0.10, y + rh * 0.35)], fill=rgba((26, 20, 24), 52), width=1)
    draw.ellipse(box(x - rw * 0.53, y - rh * 0.38, x - rw * 0.34, y + rh * 0.38), fill=rgba((34, 24, 32), 116), outline=rgba((248, 210, 146), 56), width=1)
    draw.ellipse(box(x - rw * 0.48, y - rh * 0.24, x - rw * 0.39, y + rh * 0.24), fill=rgba((240, 214, 162), 46))


def draw_shelf(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, side: float) -> None:
    w, h = SIZE
    rect = (x - 150, h * 0.132, x + 150, h * 0.425)
    draw_shadow(image, (x, h * 0.440), (160, 18), 50)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((34, 26, 38), 218), outline=rgba((228, 174, 108), 86), width=2)
    palette = [(172, 72, 94), (66, 116, 150), (194, 144, 70), (96, 142, 94), (132, 78, 152), (220, 110, 82)]
    for row in range(4):
        y = rect[1] + 46 + row * 56
        draw.line([xy(rect[0] + 22, y + 6), xy(rect[2] - 22, y - 2)], fill=rgba((132, 82, 52), 152), width=4)
        for col in range(5):
            px = rect[0] + 48 + col * 48
            color = palette[(row * 2 + col) % len(palette)]
            draw_fabric_roll(draw, image, (px, y - 20 + (col % 2) * 4), (36, 28), color, side)
    for i in range(4):
        px = x + side * (96 - i * 40)
        py = h * (0.115 + i * 0.018)
        draw.line([xy(px, h * 0.055), xy(px + side * 8, py + 86)], fill=rgba((224, 184, 122), 88), width=2)
        draw.polygon(poly([
            (px + side * -18, py + 32),
            (px + side * 20, py + 22),
            (px + side * 12, py + 118),
            (px + side * -24, py + 112),
        ]), fill=rgba(palette[(i + 1) % len(palette)], 112))


def draw_hanging_bolts(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rack_y = h * 0.115
    draw.line([xy(w * 0.310, rack_y), xy(w * 0.690, rack_y - 10)], fill=rgba((238, 196, 126), 128), width=5)
    colors = [(190, 70, 100), (72, 118, 166), (236, 168, 76), (95, 144, 98), (132, 80, 158), (222, 112, 82)]
    for i, color in enumerate(colors):
        x = w * (0.335 + i * 0.063)
        top = rack_y + (i % 2) * 10
        length = h * (0.220 + (i % 3) * 0.032)
        draw.line([xy(x, rack_y - 2), xy(x + 4, top + 20)], fill=rgba((238, 206, 150), 92), width=2)
        draw.polygon(poly([
            (x - 28, top + 16),
            (x + 32, top + 9),
            (x + 20, top + length),
            (x - 35, top + length + 9),
        ]), fill=rgba(color, 136))
        draw.line([xy(x - 19, top + 24), xy(x + 16, top + length - 10)], fill=rgba((255, 230, 174), 32), width=2)
        add_glow(image, (x, top + length * 0.56), 58, color, 10)


def draw_cutting_table(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    base = (w * 0.505, h * 0.655)
    draw_shadow(image, (base[0], base[1] + 74), (245, 30), 78)
    top = [
        (base[0] - 230, base[1] - 70),
        (base[0] + 238, base[1] - 86),
        (base[0] + 198, base[1] + 62),
        (base[0] - 214, base[1] + 86),
    ]
    draw.polygon(poly(top), fill=rgba((94, 54, 42), 240))
    draw.line([xy(base[0] - 220, base[1] - 56), xy(base[0] + 226, base[1] - 72)], fill=rgba((246, 198, 124), 72), width=3)
    draw.polygon(poly([
        (base[0] - 156, base[1] - 36),
        (base[0] + 94, base[1] - 50),
        (base[0] + 62, base[1] + 34),
        (base[0] - 174, base[1] + 48),
    ]), fill=rgba((210, 92, 112), 154))
    draw.polygon(poly([
        (base[0] + 40, base[1] - 38),
        (base[0] + 176, base[1] - 46),
        (base[0] + 154, base[1] + 18),
        (base[0] + 28, base[1] + 28),
    ]), fill=rgba((78, 130, 168), 126))
    for i in range(13):
        x = base[0] - 170 + i * 24
        draw.line([xy(x, base[1] - 28), xy(x + 58, base[1] - 34)], fill=rgba((250, 222, 158), 82), width=1)
    draw.arc(box(base[0] + 104, base[1] + 2, base[0] + 170, base[1] + 54), start=210, end=520, fill=rgba((230, 218, 188), 150), width=3)
    draw.arc(box(base[0] + 146, base[1] - 2, base[0] + 212, base[1] + 50), start=200, end=510, fill=rgba((230, 218, 188), 150), width=3)
    draw.line([xy(base[0] + 154, base[1] + 25), xy(base[0] + 210, base[1] - 28)], fill=rgba((208, 190, 146), 150), width=3)
    draw.line([xy(base[0] + 156, base[1] + 23), xy(base[0] + 92, base[1] - 22)], fill=rgba((208, 190, 146), 140), width=3)
    for leg_x in [base[0] - 164, base[0] + 154]:
        draw.line([xy(leg_x, base[1] + 54), xy(leg_x - 18, base[1] + 145)], fill=rgba((46, 30, 28), 210), width=8)


def draw_mannequin(draw: ImageDraw.ImageDraw, image: Image.Image, foot: tuple[float, float], scale: float, color: tuple[int, int, int]) -> None:
    x, y = foot
    draw_shadow(image, (x, y + 8 * scale), (38 * scale, 8 * scale), 42)
    draw.line([xy(x, y - 128 * scale), xy(x, y)], fill=rgba((92, 58, 42), 190), width=max(1, round(4 * scale)))
    draw.line([xy(x - 32 * scale, y - 96 * scale), xy(x + 34 * scale, y - 104 * scale)], fill=rgba((92, 58, 42), 176), width=max(1, round(3 * scale)))
    draw.polygon(poly([
        (x - 44 * scale, y - 104 * scale),
        (x + 48 * scale, y - 112 * scale),
        (x + 36 * scale, y - 28 * scale),
        (x + 10 * scale, y - 6 * scale),
        (x - 36 * scale, y - 20 * scale),
    ]), fill=rgba(color, 156))
    draw.line([xy(x - 28 * scale, y - 86 * scale), xy(x + 22 * scale, y - 34 * scale)], fill=rgba((255, 224, 166), 44), width=max(1, round(2 * scale)))


def draw_dye_vats(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    rng = random.Random("tailor-dye-vats")
    for i, color in enumerate([(70, 122, 168), (198, 80, 108), (108, 146, 82)]):
        x = w * (0.755 + i * 0.062)
        y = h * (0.692 + (i % 2) * 0.050)
        draw_shadow(image, (x, y + 34), (48, 9), 54)
        draw.ellipse(box(x - 44, y - 30, x + 44, y + 18), fill=rgba((48, 34, 30), 210), outline=rgba((234, 186, 118), 68), width=2)
        draw.ellipse(box(x - 34, y - 25, x + 34, y + 6), fill=rgba(color, 148))
        draw.rectangle(box(x - 38, y - 8, x + 38, y + 44), fill=rgba((60, 38, 30), 210))
        draw.ellipse(box(x - 38, y + 22, x + 38, y + 58), fill=rgba((42, 28, 25), 212))
        add_glow(image, (x, y - 5), 82, color, 22)
        for k in range(10):
            px = x - 28 + k * 6 + rng.random() * 3
            draw.line([xy(px, y - 38), xy(px + rng.uniform(-10, 8), y - 72 - rng.random() * 28)], fill=rgba(color, 22 + k * 3), width=1)


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
        (shoulder[0] + body_w * 0.92, shoulder[1] + 6 * scale),
        (hip[0] + body_w * 0.78, hip[1]),
        (x + body_w * 0.42, y),
        (x - body_w * 0.72, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba(cloth, alpha))
    draw.ellipse(box(head[0] - 13 * scale, head[1] - 13 * scale, head[0] + 13 * scale, head[1] + 13 * scale), fill=rgba((40, 28, 24), alpha))
    hand = (shoulder[0] + side * body_w * 1.58, shoulder[1] + body_h * 0.16)
    draw.line([xy(shoulder[0] + side * body_w * 0.70, shoulder[1] + 10 * scale), xy(*hand)], fill=rgba((30, 21, 18), alpha), width=max(1, round(4 * scale)))
    draw.line([xy(hand[0], hand[1]), xy(hand[0] + side * 52 * scale, hand[1] - 10 * scale)], fill=rgba((238, 216, 176), round(alpha * 0.68)), width=max(1, round(2 * scale)))


def draw_floor_props(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    palette = [(196, 82, 104), (68, 116, 156), (220, 148, 70), (94, 138, 94), (132, 82, 156)]
    for i in range(11):
        x = w * (0.070 + (i % 6) * 0.058)
        y = h * (0.735 + (i // 6) * 0.060 + (i % 2) * 0.018)
        draw_fabric_roll(draw, image, (x, y), (58, 32), palette[i % len(palette)], -1.0)
    for i in range(9):
        x = w * (0.610 + (i % 5) * 0.044)
        y = h * (0.785 + (i // 5) * 0.060)
        draw_shadow(image, (x, y + 14), (24, 5), 38)
        draw.polygon(poly([(x - 22, y - 14), (x + 22, y - 20), (x + 28, y + 8), (x - 18, y + 12)]), fill=rgba(palette[(i + 2) % len(palette)], 118))


def draw_fabric_motes(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    rng = random.Random("tailor-v2-fabric-motes")
    w, h = SIZE
    haze = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    for _ in range(26):
        x = w * (0.18 + rng.random() * 0.68)
        y = h * (0.23 + rng.random() * 0.42)
        rx = rng.uniform(38, 118)
        ry = rng.uniform(16, 44)
        color = rng.choice([(226, 156, 116), (146, 92, 170), (90, 132, 178)])
        hd.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba(color, rng.randint(10, 28)))
    haze = haze.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(haze)
    for _ in range(170):
        x = w * (0.16 + rng.random() * 0.72)
        y = h * (0.28 + rng.random() * 0.52)
        length = rng.uniform(4, 18)
        angle = rng.uniform(-0.7, 0.5)
        color = rng.choice([(250, 208, 150), (214, 108, 132), (112, 154, 190), (150, 218, 146)])
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length)], fill=rgba(color, rng.randint(18, 72)), width=1)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x, side, color in [(58, 1.0, (128, 54, 86)), (w - 58, -1.0, (58, 92, 134))]:
        draw.rounded_rectangle(box(x - 24, 34, x + 24, h - 42), radius=8, fill=rgba((18, 12, 18), 216))
        draw.line([xy(x + side * 12, 74), xy(x + side * 12, h - 76)], fill=rgba((238, 188, 122), 54), width=3)
        draw.polygon(poly([
            (x + side * 22, 82),
            (x + side * 116, 70),
            (x + side * 88, h * 0.80),
            (x + side * 12, h * 0.84),
        ]), fill=rgba(color, 78))
    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, 46), fill=(12, 8, 13, 198))
    vd.rectangle(box(0, h * 0.895, w, h), fill=(9, 7, 9, 126))
    vd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 78))
    vd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 78))
    vignette = vignette.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(vignette)


def add_texture(image: Image.Image) -> None:
    rng = random.Random("tailor-interior-v2-texture")
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(3600):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 26)
        alpha = rng.randint(5, 28)
        color = rng.choice([(246, 204, 146), (198, 92, 118), (82, 126, 168), (32, 24, 32)])
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(290):
        x = rng.uniform(w * 0.18, w * 0.86)
        y = rng.uniform(h * 0.53, h * 0.90)
        r = rng.uniform(1.0, 4.0)
        color = rng.choice([(238, 140, 128), (112, 158, 202), (236, 188, 112), (126, 196, 126)])
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(color, rng.randint(16, 62)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (35, 30, 42), (86, 62, 62))
    draw = ImageDraw.Draw(image)
    draw_wall(draw, image)
    draw_floor(draw)
    draw_hanging_bolts(draw, image)
    draw_shelf(draw, image, SIZE[0] * 0.202, -1.0)
    draw_shelf(draw, image, SIZE[0] * 0.805, 1.0)
    draw_cutting_table(draw, image)
    draw_mannequin(draw, image, (SIZE[0] * 0.330, SIZE[1] * 0.620), 0.82, (206, 82, 108))
    draw_mannequin(draw, image, (SIZE[0] * 0.670, SIZE[1] * 0.580), 0.70, (72, 118, 166))
    draw_dye_vats(draw, image)
    draw_figure(draw, image, (SIZE[0] * 0.465, SIZE[1] * 0.660), 0.76, 1.0, (94, 62, 88), 138)
    draw_figure(draw, image, (SIZE[0] * 0.610, SIZE[1] * 0.535), 0.58, -1.0, (70, 94, 122), 100)
    draw_floor_props(draw, image)
    draw_fabric_motes(draw, image)
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
