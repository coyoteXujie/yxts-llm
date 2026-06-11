#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "godot_project" / "assets" / "world" / "shop_interiors"
SIZE = (1344, 864)


SHOP_SPECS = {
    "inn": {
        "accent": (220, 132, 64),
        "wall": (102, 56, 34),
        "goods": (222, 168, 82),
        "sign": 3,
    },
    "medicine": {
        "accent": (102, 176, 92),
        "wall": (70, 86, 54),
        "goods": (116, 182, 92),
        "sign": 5,
    },
    "blacksmith": {
        "accent": (214, 76, 42),
        "wall": (90, 54, 42),
        "goods": (198, 184, 150),
        "sign": 4,
    },
    "tailor": {
        "accent": (172, 118, 206),
        "wall": (86, 62, 94),
        "goods": (210, 154, 218),
        "sign": 4,
    },
    "market": {
        "accent": (224, 166, 58),
        "wall": (106, 70, 38),
        "goods": (224, 170, 68),
        "sign": 6,
    },
    "teahouse": {
        "accent": (114, 176, 118),
        "wall": (78, 88, 58),
        "goods": (144, 194, 128),
        "sign": 5,
    },
}


def rgba(color: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return (color[0], color[1], color[2], alpha)


def box(x1: float, y1: float, x2: float, y2: float) -> tuple[int, int, int, int]:
    return (round(x1), round(y1), round(x2), round(y2))


def xy(x: float, y: float) -> tuple[int, int]:
    return (round(x), round(y))


def polygon(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [xy(x, y) for x, y in points]


def add_glow(image: Image.Image, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius * 0.56, cx + radius, cy + radius * 0.56), fill=rgba(color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, round(radius * 0.32))))
    image.alpha_composite(layer)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
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


def draw_floor(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, accent: tuple[int, int, int]) -> None:
    w, h = image.size
    draw.polygon(
        polygon([(0, wall_bottom), (w, wall_bottom - h * 0.015), (w, h), (0, h)]),
        fill=rgba((118, 78, 45), 240),
    )
    draw.polygon(
        polygon([(w * 0.08, wall_bottom + h * 0.04), (w * 0.92, wall_bottom + h * 0.02), (w * 1.04, h), (w * -0.04, h)]),
        fill=rgba((158, 104, 56), 82),
    )
    for row in range(15):
        t = row / 14.0
        y = wall_bottom + (t * t) * (h - wall_bottom - 34)
        draw.line([xy(w * (0.04 - t * 0.10), y), xy(w * (0.96 + t * 0.10), y - h * 0.016)], fill=rgba((55, 32, 20), round(118 - t * 45)), width=max(1, round(1.2 + t * 3.2)))
    for col in range(18):
        t = col / 17.0
        x = w * (0.02 + t * 0.96)
        target_x = w * (0.50 + math.sin(col * 0.7) * 0.055)
        draw.line([xy(x, h), xy(target_x, wall_bottom + h * 0.03)], fill=rgba((50, 30, 20), 34 + round(abs(t - 0.5) * 50)), width=1)
    for lane in range(5):
        y = h * (0.62 + lane * 0.068)
        draw.ellipse(box(w * 0.25, y - h * 0.014, w * 0.75, y + h * 0.028), fill=rgba(accent, 24 - lane * 2))


def draw_wall(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, wall: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    w, h = image.size
    draw.rectangle(box(0, 0, w, wall_bottom), fill=rgba((wall[0], wall[1], wall[2]), 246))
    draw.rectangle(box(0, 0, w, h * 0.060), fill=rgba((25, 15, 10), 190))
    for x in [w * 0.08, w * 0.25, w * 0.50, w * 0.75, w * 0.92]:
        draw.rectangle(box(x - w * 0.012, h * 0.035, x + w * 0.012, wall_bottom + h * 0.058), fill=rgba((36, 20, 13), 154))
        draw.line([xy(x - w * 0.005, h * 0.10), xy(x + w * 0.010, wall_bottom - h * 0.030)], fill=rgba(accent, 30), width=2)
    for y in [h * 0.13, h * 0.22, h * 0.32, h * 0.43]:
        draw.line([xy(w * 0.06, y), xy(w * 0.94, y - h * 0.018)], fill=rgba((28, 16, 10), 96), width=4)
        draw.line([xy(w * 0.06, y + h * 0.014), xy(w * 0.94, y - h * 0.004)], fill=rgba(accent, 24), width=1)
    for side in (-1.0, 1.0):
        x = w * (0.12 if side < 0.0 else 0.88)
        draw.rectangle(box(x - w * 0.020, h * 0.09, x + w * 0.020, wall_bottom + h * 0.090), fill=rgba((22, 13, 9), 178))
        draw.line([xy(x + side * w * 0.018, h * 0.11), xy(w * 0.50, h * 0.065)], fill=rgba(accent, 56), width=5)
        draw.line([xy(x + side * w * 0.028, wall_bottom - h * 0.030), xy(w * 0.50, wall_bottom - h * 0.090)], fill=rgba((18, 11, 8), 142), width=4)


def draw_sign(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, sign_strokes: int, accent: tuple[int, int, int]) -> None:
    w, h = image.size
    cx = w * 0.50
    cy = wall_bottom - h * 0.150
    sign = box(cx - w * 0.145, cy - h * 0.038, cx + w * 0.145, cy + h * 0.038)
    draw.rounded_rectangle(box(sign[0] - 16, sign[1] - 12, sign[2] + 16, sign[3] + 12), radius=8, fill=rgba((20, 12, 8), 118))
    draw.rounded_rectangle(sign, radius=5, fill=rgba((72, 30, 15), 226), outline=rgba((232, 184, 92), 122), width=3)
    for i in range(sign_strokes):
        t = (i + 0.5) / sign_strokes
        x = sign[0] + (sign[2] - sign[0]) * t
        draw.line([xy(x, sign[1] + h * 0.013), xy(x - w * 0.012, sign[3] - h * 0.012)], fill=rgba((250, 216, 132), 162), width=3)
        if i % 2 == 0:
            draw.line([xy(x - w * 0.012, sign[1] + h * 0.045), xy(x + w * 0.014, sign[1] + h * 0.034)], fill=rgba((244, 174, 82), 118), width=2)
    add_glow(image, (cx, cy + h * 0.055), w * 0.12, accent, 28)


def draw_shelves(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, accent: tuple[int, int, int], rng: random.Random) -> None:
    w, h = image.size
    for side in (-1.0, 1.0):
        cx = w * (0.18 if side < 0.0 else 0.82)
        shelf = box(cx - w * 0.115, h * 0.125, cx + w * 0.115, wall_bottom - h * 0.050)
        draw.rounded_rectangle(shelf, radius=6, fill=rgba((48, 26, 16), 210), outline=rgba((178, 112, 54), 92), width=2)
        for row in range(4):
            y = shelf[1] + (shelf[3] - shelf[1]) * (row + 0.28) / 4.2
            draw.line([xy(shelf[0] + 18, y), xy(shelf[2] - 18, y - 3)], fill=rgba((164, 94, 42), 164), width=4)
            for col in range(5):
                x = shelf[0] + 42 + col * ((shelf[2] - shelf[0] - 84) / 4.0)
                color = (
                    min(255, accent[0] + rng.randint(-24, 24)),
                    min(255, accent[1] + rng.randint(-24, 24)),
                    min(255, accent[2] + rng.randint(-24, 24)),
                )
                if row % 2 == 0:
                    draw.ellipse(box(x - 8, y - 23, x + 8, y - 8), fill=rgba(color, 128))
                else:
                    draw.rectangle(box(x - 9, y - 29, x + 9, y - 10), fill=rgba((112, 58, 30), 150), outline=rgba(color, 84))


def draw_counter(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, accent: tuple[int, int, int]) -> None:
    w, h = image.size
    rect = (w * 0.14, wall_bottom - h * 0.128, w * 0.86, wall_bottom + h * 0.060)
    draw.rounded_rectangle(box(rect[0] - 12, rect[1] - 8, rect[2] + 12, rect[3] + 20), radius=8, fill=rgba((12, 8, 5), 92))
    draw.rounded_rectangle(box(*rect), radius=6, fill=rgba((86, 42, 20), 238), outline=rgba((188, 108, 48), 120), width=3)
    draw.polygon(
        polygon([(rect[0] + 24, rect[1] + 28), (rect[2] - 24, rect[1] + 18), (rect[2] - 56, rect[3] + 42), (rect[0] + 56, rect[3] + 48)]),
        fill=rgba((154, 84, 34), 106),
    )
    draw.rectangle(box(rect[0], rect[1], rect[2], rect[1] + h * 0.035), fill=rgba((178, 100, 42), 190))
    for i in range(8):
        x = rect[0] + (rect[2] - rect[0]) * (i + 0.5) / 8.0
        draw.line([xy(x, rect[1] + 18), xy(x - 10, rect[3] - 10)], fill=rgba((30, 17, 10), 96), width=2)
    add_glow(image, (w * 0.50, rect[1] + h * 0.050), w * 0.28, accent, 18)


def draw_lamps(draw: ImageDraw.ImageDraw, image: Image.Image, wall_bottom: float, accent: tuple[int, int, int]) -> None:
    w, h = image.size
    for x in (w * 0.28, w * 0.50, w * 0.72):
        y = h * 0.115
        draw.line([xy(x, h * 0.050), xy(x, y)], fill=rgba((224, 176, 92), 112), width=2)
        draw.ellipse(box(x - 16, y - 8, x + 16, y + 30), fill=rgba(accent, 178), outline=rgba((74, 34, 18), 136), width=2)
        draw.line([xy(x - 10, y + 2), xy(x + 10, y + 24)], fill=rgba((255, 232, 146), 84), width=1)
        add_glow(image, (x, wall_bottom + h * 0.020), w * 0.09, accent, 28)


def draw_background_figures(draw: ImageDraw.ImageDraw, wall_bottom: float, accent: tuple[int, int, int]) -> None:
    w, h = SIZE
    for i, x in enumerate([w * 0.36, w * 0.43, w * 0.57, w * 0.64]):
        foot_y = wall_bottom - h * (0.012 + (i % 2) * 0.012)
        scale = 0.78 + (i % 3) * 0.05
        side = -1 if i % 2 == 0 else 1
        body_h = h * 0.110 * scale
        draw.ellipse(box(x - 24 * scale, foot_y - 1, x + 24 * scale, foot_y + 9), fill=rgba((0, 0, 0), 42))
        shoulder = (x, foot_y - body_h * 0.65)
        hip = (x - side * 5 * scale, foot_y - body_h * 0.20)
        draw.polygon(
            polygon([
                (shoulder[0] - 20 * scale, shoulder[1]),
                (shoulder[0] + 18 * scale, shoulder[1] + 4 * scale),
                (hip[0] + 18 * scale, hip[1]),
                (x + 10 * scale, foot_y),
                (x - 16 * scale, foot_y - 2 * scale),
                (hip[0] - 20 * scale, hip[1]),
            ]),
            fill=rgba((max(18, accent[0] // 2), max(18, accent[1] // 2), max(18, accent[2] // 2)), 104),
        )
        head = (x + side * 5 * scale, foot_y - body_h * 0.90)
        draw.ellipse(box(head[0] - 10 * scale, head[1] - 10 * scale, head[0] + 10 * scale, head[1] + 10 * scale), fill=rgba((44, 27, 18), 132))
        hand = (shoulder[0] + side * 26 * scale, shoulder[1] + 20 * scale)
        draw.line([xy(shoulder[0] + side * 14 * scale, shoulder[1] + 10 * scale), xy(*hand)], fill=rgba((28, 17, 11), 122), width=2)


def draw_theme(draw: ImageDraw.ImageDraw, image: Image.Image, shop_id: str, wall_bottom: float, accent: tuple[int, int, int], goods: tuple[int, int, int]) -> None:
    w, h = image.size
    if shop_id == "blacksmith":
        forge = (w * 0.75, wall_bottom + h * 0.145)
        draw.rounded_rectangle(box(forge[0] - 72, forge[1] - 42, forge[0] + 72, forge[1] + 44), radius=8, fill=rgba((58, 34, 24), 224))
        add_glow(image, forge, 86, (255, 86, 34), 100)
        draw.ellipse(box(forge[0] - 34, forge[1] - 26, forge[0] + 34, forge[1] + 28), fill=rgba((255, 104, 40), 164))
        for i in range(6):
            x = w * (0.42 + i * 0.050)
            draw.line([xy(x, h * 0.19), xy(x + 52, wall_bottom - h * 0.048)], fill=rgba(goods, 136), width=4)
    elif shop_id == "medicine":
        cabinet = box(w * 0.38, h * 0.14, w * 0.62, wall_bottom - h * 0.055)
        draw.rounded_rectangle(cabinet, radius=5, fill=rgba((48, 28, 16), 216), outline=rgba(accent, 82), width=2)
        for row in range(5):
            for col in range(6):
                x1 = cabinet[0] + 18 + col * ((cabinet[2] - cabinet[0] - 36) / 6.0)
                y1 = cabinet[1] + 18 + row * ((cabinet[3] - cabinet[1] - 36) / 5.0)
                draw.rectangle(box(x1, y1, x1 + 34, y1 + 24), fill=rgba((96, 50, 26), 150), outline=rgba(goods, 60))
        for i in range(9):
            x = w * (0.20 + i * 0.075)
            y = wall_bottom + h * (0.120 + (i % 2) * 0.028)
            draw.line([xy(x, y), xy(x + 14, y - 48)], fill=rgba((42, 98, 42), 142), width=2)
            draw.ellipse(box(x + 7, y - 58, x + 29, y - 38), fill=rgba(goods, 108))
    elif shop_id == "tailor":
        for i in range(7):
            x = w * (0.23 + i * 0.080)
            top = wall_bottom - h * (0.030 + (i % 2) * 0.014)
            draw.line([xy(x, top), xy(x + 30, wall_bottom + h * 0.190)], fill=rgba(goods, 138), width=8)
            draw.line([xy(x + 18, top + 12), xy(x + 48, wall_bottom + h * 0.195)], fill=rgba((244, 208, 238), 86), width=4)
        stand = (w * 0.78, wall_bottom + h * 0.160)
        draw.line([xy(stand[0], stand[1] - 92), xy(*stand)], fill=rgba((42, 24, 16), 168), width=4)
        draw.polygon(polygon([(stand[0], stand[1] - 94), (stand[0] + 54, stand[1] - 30), (stand[0], stand[1] + 8), (stand[0] - 54, stand[1] - 30)]), fill=rgba(goods, 120))
    elif shop_id in {"inn", "teahouse"}:
        for i in range(4 if shop_id == "inn" else 3):
            cx = w * (0.26 + i * 0.16)
            cy = wall_bottom + h * (0.195 + (i % 2) * 0.032)
            draw.ellipse(box(cx - 56, cy - 16, cx + 56, cy + 20), fill=rgba((20, 13, 8), 82))
            draw.rounded_rectangle(box(cx - 50, cy - 22, cx + 50, cy + 10), radius=9, fill=rgba((92, 48, 24), 204), outline=rgba(goods, 70), width=2)
            draw.ellipse(box(cx - 18, cy - 42, cx + 18, cy - 8), fill=rgba(goods, 104))
        if shop_id == "teahouse":
            screen = box(w * 0.11, h * 0.15, w * 0.28, wall_bottom - h * 0.030)
            draw.rounded_rectangle(screen, radius=4, fill=rgba((42, 34, 22), 164), outline=rgba(accent, 70), width=2)
            for i in range(4):
                x = screen[0] + (screen[2] - screen[0]) * (i + 1) / 5.0
                draw.line([xy(x, screen[1] + 16), xy(x, screen[3] - 16)], fill=rgba(accent, 72), width=2)
    else:
        for i in range(10):
            x = w * (0.18 + (i % 5) * 0.15)
            y = wall_bottom + h * (0.135 + (i // 5) * 0.125)
            draw.rounded_rectangle(box(x - 34, y - 22, x + 34, y + 20), radius=5, fill=rgba((86, 44, 22), 204), outline=rgba(goods, 72), width=2)
            draw.ellipse(box(x - 10, y - 44, x + 14, y - 20), fill=rgba(goods, 118))


def draw_counter_goods(draw: ImageDraw.ImageDraw, shop_id: str, wall_bottom: float, accent: tuple[int, int, int], goods: tuple[int, int, int]) -> None:
    w, h = SIZE
    top_y = wall_bottom - h * 0.100
    for i in range(9):
        x = w * (0.23 + i * 0.068)
        y = top_y - h * (0.004 + (i % 2) * 0.012)
        if shop_id == "blacksmith":
            draw.line([xy(x - 22, y + 12), xy(x + 28, y - 10)], fill=rgba(goods, 166), width=4)
            draw.ellipse(box(x - 32, y + 8, x - 24, y + 16), fill=rgba(accent, 120))
        elif shop_id == "medicine":
            draw.rounded_rectangle(box(x - 11, y - 26, x + 11, y + 8), radius=3, fill=rgba((94, 48, 26), 176), outline=rgba(goods, 98), width=1)
        elif shop_id == "tailor":
            draw.line([xy(x - 20, y + 10), xy(x + 22, y - 10)], fill=rgba(goods, 154), width=5)
            draw.line([xy(x - 18, y - 2), xy(x + 20, y + 7)], fill=rgba((244, 210, 238), 92), width=2)
        elif shop_id in {"inn", "teahouse"}:
            draw.ellipse(box(x - 12, y - 12, x + 12, y + 12), fill=rgba((96, 42, 20), 174))
            draw.ellipse(box(x + 6, y - 18, x + 18, y - 6), fill=rgba(goods, 122))
        else:
            draw.rounded_rectangle(box(x - 17, y - 18, x + 17, y + 10), radius=4, fill=rgba((94, 46, 20), 178), outline=rgba(goods, 82), width=1)
            draw.ellipse(box(x + 3, y - 30, x + 19, y - 14), fill=rgba(goods, 118))


def draw_foreground(draw: ImageDraw.ImageDraw, image: Image.Image, accent: tuple[int, int, int]) -> None:
    w, h = image.size
    draw.rectangle(box(0, 0, w, h * 0.050), fill=rgba((16, 9, 6), 188))
    draw.rectangle(box(0, h - h * 0.055, w, h), fill=rgba((10, 7, 5), 164))
    for x in (w * 0.055, w * 0.945):
        draw.rounded_rectangle(box(x - 20, h * 0.070, x + 20, h * 0.944), radius=7, fill=rgba((22, 12, 8), 186))
        draw.line([xy(x + (10 if x < w * 0.5 else -10), h * 0.090), xy(x + (10 if x < w * 0.5 else -10), h * 0.900)], fill=rgba(accent, 56), width=3)
    shade = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.rectangle(box(0, 0, w * 0.12, h), fill=(0, 0, 0, 78))
    sd.rectangle(box(w * 0.88, 0, w, h), fill=(0, 0, 0, 78))
    sd.rectangle(box(0, h * 0.88, w, h), fill=(0, 0, 0, 74))
    shade = shade.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shade)


def add_grain(image: Image.Image, seed: str) -> None:
    rng = random.Random(seed)
    w, h = image.size
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(900):
        x = rng.uniform(0, w)
        y = rng.uniform(0, h)
        length = rng.uniform(2, 16)
        alpha = rng.randint(6, 22)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-2, 2))], fill=rgba((255, 232, 178), alpha), width=1)
    image.alpha_composite(layer)


def render_shop(shop_id: str, spec: dict) -> Image.Image:
    rng = random.Random(f"shop-dnf-interior-{shop_id}-v1")
    accent = spec["accent"]
    wall = spec["wall"]
    goods = spec["goods"]
    image = gradient(SIZE, (44, 28, 18), (96, 58, 34))
    draw = ImageDraw.Draw(image)
    wall_bottom = SIZE[1] * 0.48
    draw_wall(draw, image, wall_bottom, wall, accent)
    draw_floor(draw, image, wall_bottom, accent)
    draw_shelves(draw, image, wall_bottom, accent, rng)
    draw_sign(draw, image, wall_bottom, int(spec["sign"]), accent)
    draw_lamps(draw, image, wall_bottom, accent)
    draw_background_figures(draw, wall_bottom, accent)
    draw_counter(draw, image, wall_bottom, accent)
    draw_theme(draw, image, shop_id, wall_bottom, accent, goods)
    draw_counter_goods(draw, shop_id, wall_bottom, accent, goods)
    draw_foreground(draw, image, accent)
    add_grain(image, shop_id)
    return image.convert("RGB")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for shop_id, spec in SHOP_SPECS.items():
        image = render_shop(shop_id, spec)
        image.save(OUT_DIR / f"shop_{shop_id}_dnf_interior_v1.png", optimize=True)
    print(f"OK generated {len(SHOP_SPECS)} shop DNF interior backgrounds size={SIZE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
