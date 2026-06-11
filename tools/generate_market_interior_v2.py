#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_blacksmith_interior_v2 import SIZE, add_glow, box, draw_shadow, gradient, poly, rgba, xy


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot_project" / "assets" / "world" / "shop_interiors" / "shop_market_dnf_interior_v2.png"


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    wall_bottom = h * 0.49
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((72, 54, 40), 250))
    draw.rectangle(box(0, 0, w, 58), fill=rgba((20, 14, 10), 230))
    for x in [80, 210, 420, 655, 848, 1095, 1378, 1516]:
        draw.rectangle(box(x - 17, 40, x + 17, wall_bottom + 32), fill=rgba((30, 22, 16), 188))
        draw.line([xy(x + 5, 78), xy(x - 8, wall_bottom - 20)], fill=rgba((232, 132, 60), 34), width=2)
    for y in [112, 198, 290, 380]:
        draw.line([xy(70, y), xy(w - 70, y - 16)], fill=rgba((26, 18, 12), 128), width=5)
        draw.line([xy(70, y + 14), xy(w - 70, y - 2)], fill=rgba((246, 166, 82), 34), width=2)
    sign = box(w * 0.400, h * 0.167, w * 0.600, h * 0.252)
    draw.rounded_rectangle(sign, radius=6, fill=rgba((48, 30, 18), 240), outline=rgba((246, 186, 98), 124), width=3)
    for i in range(6):
        x = w * (0.420 + i * 0.033)
        draw.line([xy(x, h * 0.194), xy(x - 13, h * 0.236)], fill=rgba((255, 216, 138), 142), width=4)
    add_glow(image, (w * 0.50, h * 0.275), 160, (238, 132, 58), 20)


def draw_floor(draw: ImageDraw.ImageDraw) -> None:
    w, h = SIZE
    top = h * 0.49
    draw.polygon(poly([(0, top), (w, top - 18), (w, h), (0, h)]), fill=rgba((92, 72, 48), 246))
    draw.polygon(poly([(w * 0.10, top + 34), (w * 0.90, top + 12), (w * 1.04, h), (-w * 0.04, h)]), fill=rgba((152, 104, 58), 80))
    for i in range(18):
        t = i / 17.0
        y = top + (t * t) * (h - top - 30)
        draw.line([xy(w * (-0.05 + t * 0.08), y), xy(w * (1.05 - t * 0.08), y - 17)], fill=rgba((42, 30, 20), round(126 - t * 48)), width=max(1, round(1.4 + t * 3.5)))
    for i in range(17):
        t = i / 16.0
        if i % 3 == 1:
            continue
        x = w * (0.03 + t * 0.94)
        target = w * (0.50 + math.sin(i * 0.48) * 0.030)
        draw.line([xy(x, h), xy(target, top + 30)], fill=rgba((54, 36, 24), 18 + round(abs(t - 0.5) * 30)), width=1)
    draw.polygon(poly([(w * 0.19, h * 0.657), (w * 0.81, h * 0.626), (w * 0.70, h * 0.872), (w * 0.29, h * 0.882)]), fill=rgba((88, 58, 36), 132))
    for i in range(116):
        x = w * (0.18 + (i % 29) * 0.024)
        y = h * (0.580 + (i // 29) * 0.060) + (i % 3) * 2
        draw.line([xy(x, y), xy(x + 18, y - 4)], fill=rgba((152, 102, 54), 42), width=1)


def draw_lanterns(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for i, x in enumerate([185, 340, 1220, 1400, 760, 890]):
        y = h * (0.120 + (i % 3) * 0.030)
        draw.line([xy(x, h * 0.052), xy(x + 8, y)], fill=rgba((238, 190, 118), 96), width=2)
        add_glow(image, (x, y + 36), 86, (255, 146, 48), 30)
        draw.ellipse(box(x - 24, y + 4, x + 24, y + 62), fill=rgba((204, 58, 42), 150), outline=rgba((252, 206, 126), 82), width=2)
        draw.line([xy(x - 19, y + 24), xy(x + 19, y + 20)], fill=rgba((255, 214, 142), 58), width=1)
        draw.line([xy(x - 18, y + 42), xy(x + 18, y + 38)], fill=rgba((255, 214, 142), 50), width=1)


def draw_awning(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, width: float, color: tuple[int, int, int], flip: float) -> None:
    draw_shadow(image, (x, y + 112), (width * 0.42, 16), 44)
    draw.polygon(poly([
        (x - width * 0.50, y),
        (x + width * 0.50, y - 16),
        (x + width * 0.42, y + 60),
        (x - width * 0.46, y + 72),
    ]), fill=rgba(color, 148))
    for i in range(7):
        t = i / 6.0
        xx = x - width * 0.43 + width * 0.86 * t
        draw.line([xy(xx, y + 6), xy(xx - flip * 10, y + 64)], fill=rgba((255, 214, 142), 54), width=2)
    for i in range(9):
        t = i / 8.0
        xx = x - width * 0.44 + width * 0.88 * t
        draw.polygon(poly([(xx - 16, y + 60), (xx + 14, y + 58), (xx - 2, y + 88)]), fill=rgba(color, 118))


def draw_basket(draw: ImageDraw.ImageDraw, image: Image.Image, center: tuple[float, float], scale: float, color: tuple[int, int, int], goods: str) -> None:
    x, y = center
    draw_shadow(image, (x, y + 16 * scale), (34 * scale, 7 * scale), 42)
    draw.ellipse(box(x - 36 * scale, y - 18 * scale, x + 36 * scale, y + 18 * scale), fill=rgba((92, 58, 30), 176), outline=rgba((214, 150, 76), 68), width=max(1, round(2 * scale)))
    draw.rectangle(box(x - 34 * scale, y - 6 * scale, x + 34 * scale, y + 26 * scale), fill=rgba((112, 70, 34), 176))
    draw.ellipse(box(x - 34 * scale, y + 8 * scale, x + 34 * scale, y + 34 * scale), fill=rgba((70, 42, 24), 156))
    count = 10 if goods != "cloth" else 6
    for i in range(count):
        px = x - 24 * scale + (i % 5) * 12 * scale
        py = y - 18 * scale + (i // 5) * 9 * scale + (i % 2) * 2 * scale
        if goods == "round":
            draw.ellipse(box(px - 7 * scale, py - 7 * scale, px + 7 * scale, py + 7 * scale), fill=rgba(color, 168))
        elif goods == "leaf":
            draw.ellipse(box(px - 8 * scale, py - 4 * scale, px + 10 * scale, py + 8 * scale), fill=rgba(color, 156))
        else:
            draw.rounded_rectangle(box(px - 11 * scale, py - 6 * scale, px + 12 * scale, py + 8 * scale), radius=max(1, round(2 * scale)), fill=rgba(color, 140))


def draw_crate(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, color: tuple[int, int, int]) -> None:
    draw_shadow(image, (x, y + h * 0.58), (w * 0.52, h * 0.11), 46)
    draw.polygon(poly([(x - w * 0.50, y - h * 0.40), (x + w * 0.46, y - h * 0.48), (x + w * 0.55, y + h * 0.34), (x - w * 0.46, y + h * 0.44)]), fill=rgba(color, 184))
    draw.line([xy(x - w * 0.44, y - h * 0.12), xy(x + w * 0.48, y - h * 0.20)], fill=rgba((34, 22, 14), 86), width=2)
    for i in range(3):
        xx = x - w * 0.26 + i * w * 0.25
        draw.line([xy(xx, y - h * 0.35), xy(xx - w * 0.04, y + h * 0.34)], fill=rgba((246, 168, 86), 50), width=1)


def draw_stall(draw: ImageDraw.ImageDraw, image: Image.Image, center: tuple[float, float], width: float, color: tuple[int, int, int], side: float) -> None:
    x, y = center
    draw_shadow(image, (x, y + 82), (width * 0.48, 22), 66)
    draw_awning(draw, image, x, y - 190, width * 0.92, color, side)
    top = [
        (x - width * 0.50, y - 46),
        (x + width * 0.50, y - 62),
        (x + width * 0.42, y + 42),
        (x - width * 0.45, y + 62),
    ]
    draw.polygon(poly(top), fill=rgba((92, 56, 34), 236))
    draw.line([xy(x - width * 0.45, y - 34), xy(x + width * 0.45, y - 50)], fill=rgba((246, 178, 96), 72), width=3)
    for leg_x in [x - width * 0.36, x + width * 0.34]:
        draw.line([xy(leg_x, y + 36), xy(leg_x - side * 12, y + 152)], fill=rgba((42, 26, 16), 210), width=8)
    goods = [
        ((x - width * 0.31, y - 58), (190, 54, 42), "round"),
        ((x - width * 0.12, y - 64), (82, 146, 70), "leaf"),
        ((x + width * 0.09, y - 62), (228, 156, 68), "round"),
        ((x + width * 0.30, y - 66), (112, 78, 150), "cloth"),
    ]
    for pos, gcolor, kind in goods:
        draw_basket(draw, image, pos, 0.78, gcolor, kind)
    for i in range(5):
        xx = x - width * 0.32 + i * width * 0.16
        draw.rounded_rectangle(box(xx - 16, y - 108 + (i % 2) * 5, xx + 16, y - 70 + (i % 2) * 5), radius=4, fill=rgba((90, 50, 26), 160), outline=rgba((246, 178, 96), 56), width=1)


def draw_back_shelves(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, side: float) -> None:
    w, h = SIZE
    rect = (x - 142, h * 0.150, x + 142, h * 0.420)
    draw_shadow(image, (x, h * 0.435), (150, 17), 46)
    draw.rounded_rectangle(box(*rect), radius=8, fill=rgba((38, 28, 20), 216), outline=rgba((224, 140, 70), 84), width=2)
    colors = [(188, 62, 46), (216, 150, 68), (82, 142, 72), (78, 112, 150), (130, 84, 150)]
    for row in range(4):
        y = rect[1] + 46 + row * 54
        draw.line([xy(rect[0] + 22, y + 5), xy(rect[2] - 22, y - 2)], fill=rgba((142, 82, 40), 150), width=4)
        for col in range(6):
            px = rect[0] + 40 + col * 40
            color = colors[(row + col) % len(colors)]
            if (row + col) % 2 == 0:
                draw.ellipse(box(px - 11, y - 31, px + 11, y - 9), fill=rgba(color, 142))
            else:
                draw.rounded_rectangle(box(px - 13, y - 34, px + 13, y - 10), radius=3, fill=rgba(color, 142), outline=rgba((242, 184, 100), 54), width=1)
    for i in range(5):
        px = x + side * (92 - i * 38)
        draw.line([xy(px, h * 0.106), xy(px + side * 6, h * (0.180 + i * 0.010))], fill=rgba((232, 184, 112), 72), width=2)
        draw.rounded_rectangle(box(px - 10, h * (0.178 + i * 0.010), px + 12, h * (0.232 + i * 0.010)), radius=3, fill=rgba(colors[i % len(colors)], 108))


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
        (shoulder[0] + body_w * 0.92, shoulder[1] + 7 * scale),
        (hip[0] + body_w * 0.78, hip[1]),
        (x + body_w * 0.44, y),
        (x - body_w * 0.72, y - 2 * scale),
        (hip[0] - body_w * 0.82, hip[1]),
    ]), fill=rgba(cloth, alpha))
    draw.ellipse(box(head[0] - 13 * scale, head[1] - 13 * scale, head[0] + 13 * scale, head[1] + 13 * scale), fill=rgba((42, 28, 20), alpha))
    hand = (shoulder[0] + side * body_w * 1.55, shoulder[1] + body_h * 0.18)
    draw.line([xy(shoulder[0] + side * body_w * 0.70, shoulder[1] + 9 * scale), xy(*hand)], fill=rgba((30, 20, 14), alpha), width=max(1, round(4 * scale)))
    draw.ellipse(box(hand[0] - 8 * scale, hand[1] - 8 * scale, hand[0] + 8 * scale, hand[1] + 8 * scale), fill=rgba((224, 144, 72), round(alpha * 0.70)))


def draw_floor_goods(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for i in range(9):
        x = w * (0.075 + (i % 5) * 0.060)
        y = h * (0.750 + (i // 5) * 0.066 + (i % 2) * 0.016)
        draw_basket(draw, image, (x, y), 0.78, [(194, 58, 42), (82, 146, 72), (226, 156, 64)][i % 3], "round" if i % 2 == 0 else "leaf")
    for i in range(8):
        x = w * (0.610 + (i % 4) * 0.065)
        y = h * (0.770 + (i // 4) * 0.062)
        draw_crate(draw, image, x, y, 70, 52, [(98, 58, 32), (122, 70, 36), (78, 54, 38)][i % 3])
    for i in range(7):
        x = w * (0.770 + (i % 4) * 0.052)
        y = h * (0.602 + (i // 4) * 0.070)
        draw.ellipse(box(x - 22, y - 20, x + 22, y + 28), fill=rgba((86, 54, 30), 160), outline=rgba((222, 154, 78), 58), width=2)
        draw.line([xy(x - 14, y - 2), xy(x + 14, y - 12)], fill=rgba((246, 188, 112), 44), width=1)


def draw_market_air(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    rng = random.Random("market-v2-air")
    w, h = SIZE
    haze = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    for _ in range(30):
        x = w * (0.14 + rng.random() * 0.74)
        y = h * (0.25 + rng.random() * 0.48)
        rx = rng.uniform(40, 120)
        ry = rng.uniform(16, 42)
        hd.ellipse(box(x - rx, y - ry, x + rx, y + ry), fill=rgba((236, 138, 72), rng.randint(10, 28)))
    haze = haze.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(haze)
    for _ in range(190):
        x = w * (0.14 + rng.random() * 0.74)
        y = h * (0.27 + rng.random() * 0.56)
        length = rng.uniform(4, 20)
        angle = rng.uniform(-0.8, 0.5)
        color = rng.choice([(250, 190, 112), (214, 86, 54), (100, 156, 86), (88, 126, 170)])
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length)], fill=rgba(color, rng.randint(18, 76)), width=1)


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image) -> None:
    w, h = SIZE
    for x, side in [(58, 1.0), (w - 58, -1.0)]:
        draw.rounded_rectangle(box(x - 26, 34, x + 26, h - 42), radius=9, fill=rgba((18, 12, 8), 216))
        draw.line([xy(x + side * 12, 74), xy(x + side * 12, h - 76)], fill=rgba((238, 146, 64), 56), width=3)
    draw.polygon(poly([(0, h * 0.842), (w * 0.20, h * 0.796), (w * 0.26, h), (0, h)]), fill=rgba((36, 24, 18), 112))
    draw.polygon(poly([(w, h * 0.828), (w * 0.80, h * 0.798), (w * 0.74, h), (w, h)]), fill=rgba((38, 26, 18), 118))
    vignette = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, 46), fill=(13, 8, 5, 198))
    vd.rectangle(box(0, h * 0.895, w, h), fill=(10, 7, 4, 126))
    vd.rectangle(box(0, 0, w * 0.11, h), fill=(0, 0, 0, 78))
    vd.rectangle(box(w * 0.89, 0, w, h), fill=(0, 0, 0, 78))
    vignette = vignette.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(vignette)


def add_texture(image: Image.Image) -> None:
    rng = random.Random("market-interior-v2-texture")
    w, h = SIZE
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(3800):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(3, 26)
        alpha = rng.randint(5, 28)
        color = rng.choice([(255, 190, 112), (204, 70, 48), (92, 144, 78), (42, 30, 18)])
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 3))], fill=rgba(color, alpha), width=1)
    for _ in range(330):
        x = rng.uniform(w * 0.16, w * 0.88)
        y = rng.uniform(h * 0.53, h * 0.90)
        r = rng.uniform(1.0, 4.0)
        color = rng.choice([(234, 92, 54), (94, 166, 84), (238, 166, 72), (120, 90, 170)])
        draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(color, rng.randint(16, 64)))
    image.alpha_composite(layer)


def render() -> Image.Image:
    image = gradient(SIZE, (38, 32, 24), (94, 66, 44))
    draw = ImageDraw.Draw(image)
    draw_wall(draw, image)
    draw_floor(draw)
    draw_lanterns(draw, image)
    draw_back_shelves(draw, image, SIZE[0] * 0.195, -1.0)
    draw_back_shelves(draw, image, SIZE[0] * 0.805, 1.0)
    draw_stall(draw, image, (SIZE[0] * 0.300, SIZE[1] * 0.605), 410, (174, 52, 42), -1.0)
    draw_stall(draw, image, (SIZE[0] * 0.700, SIZE[1] * 0.592), 430, (62, 112, 150), 1.0)
    draw_figure(draw, image, (SIZE[0] * 0.470, SIZE[1] * 0.662), 0.75, 1.0, (92, 62, 42), 136)
    draw_figure(draw, image, (SIZE[0] * 0.590, SIZE[1] * 0.532), 0.58, -1.0, (70, 94, 70), 100)
    draw_figure(draw, image, (SIZE[0] * 0.385, SIZE[1] * 0.520), 0.54, 1.0, (98, 54, 64), 92)
    draw_floor_goods(draw, image)
    draw_market_air(draw, image)
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
