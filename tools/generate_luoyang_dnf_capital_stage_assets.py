#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_luoyang_dnf_capital_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "luoyang_dnf_capital_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "luoyang_dnf_capital_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "luoyang_dnf_capital_foreground_v1.png"
SIZE = (1672, 941)


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
    glow = glow.filter(ImageFilter.GaussianBlur(max(2, round(radius * 0.40))))
    image.alpha_composite(glow)


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


def draw_roof(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, alpha: int, accent: tuple[int, int, int]) -> None:
    draw.polygon(
        polygon([
            (x - w * 0.09, y + h * 0.50),
            (x + w * 0.50, y),
            (x + w * 1.10, y + h * 0.50),
            (x + w * 0.98, y + h * 0.70),
            (x + w * 0.02, y + h * 0.72),
        ]),
        fill=rgba(85, 36, 24, alpha),
        outline=rgba(31, 18, 13, min(255, alpha + 18)),
    )
    draw.line([xy(x + w * 0.02, y + h * 0.64), xy(x + w * 0.98, y + h * 0.60)], fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.48)), width=3)
    for tile in range(9):
        t = tile / 8.0
        tx = x + w * (0.06 + t * 0.88)
        draw.line([xy(tx, y + h * 0.30 + math.sin(tile * 0.8) * 3), xy(tx + w * 0.08, y + h * 0.66)], fill=rgba(18, 12, 9, round(alpha * 0.36)), width=1)


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float) -> None:
    add_glow(image, (x, y), 30 * scale, (255, 122, 40), 50)
    draw.line([xy(x, y - 28 * scale), xy(x, y - 10 * scale)], fill=rgba(58, 36, 20, 180), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 13 * scale, y - 10 * scale, x + 13 * scale, y + 17 * scale), fill=rgba(205, 40, 27, 180), outline=rgba(255, 205, 100, 130), width=max(1, round(2 * scale)))
    draw.line([xy(x - 8 * scale, y + 3 * scale), xy(x + 8 * scale, y + 3 * scale)], fill=rgba(255, 194, 90, 94), width=max(1, round(scale)))


def draw_shopfront(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    x: float,
    y: float,
    w: float,
    h: float,
    wall: tuple[int, int, int],
    accent: tuple[int, int, int],
    alpha: int = 236,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.05, y + h * 0.74, x + w * 0.97, y + h * 1.06), fill=rgba(0, 0, 0, 54))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(shadow)

    draw.rectangle(box(x + w * 0.06, y + h * 0.30, x + w * 0.96, y + h), fill=rgba(wall[0], wall[1], wall[2], alpha), outline=rgba(54, 32, 20, 142), width=2)
    draw_roof(draw, x, y, w, h * 0.46, alpha, accent)
    door_w = w * 0.25
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rectangle(box(door_x, y + h * 0.56, door_x + door_w, y + h), fill=rgba(40, 22, 14, 166), outline=rgba(accent[0], accent[1], accent[2], 98), width=2)
    draw.line([xy(door_x + door_w * 0.50, y + h * 0.58), xy(door_x + door_w * 0.50, y + h * 0.98)], fill=rgba(8, 5, 3, 96), width=2)
    for i in range(2):
        wx = x + w * (0.14 + i * 0.58)
        wy = y + h * 0.50
        draw.rectangle(box(wx, wy, wx + w * 0.16, wy + h * 0.16), fill=rgba(39, 48, 45, 100), outline=rgba(20, 18, 13, 118), width=2)
        draw.line([xy(wx + w * 0.08, wy), xy(wx + w * 0.08, wy + h * 0.16)], fill=rgba(230, 205, 148, 56), width=1)
    sign = box(x + w * 0.30, y + h * 0.33, x + w * 0.70, y + h * 0.44)
    draw.rectangle(sign, fill=rgba(76, 31, 15, 188), outline=rgba(246, 198, 105, 132), width=2)
    draw.line([xy(x + w * 0.36, y + h * 0.385), xy(x + w * 0.64, y + h * 0.365)], fill=rgba(255, 222, 126, 88), width=2)
    draw_lantern(draw, image, x + w * 0.16, y + h * 0.45, 0.78)
    draw_lantern(draw, image, x + w * 0.85, y + h * 0.45, 0.78)


def draw_gate_tower(draw: ImageDraw.ImageDraw, image: Image.Image, cx: float, base_y: float, w: float, h: float, alpha: int = 226) -> None:
    wall_color = rgba(176, 126, 84, alpha)
    dark = rgba(56, 34, 22, round(alpha * 0.78))
    draw.rectangle(box(cx - w * 0.44, base_y - h * 0.58, cx + w * 0.44, base_y), fill=wall_color, outline=rgba(72, 42, 24, 150), width=3)
    arch_w = w * 0.20
    arch_h = h * 0.38
    draw.rounded_rectangle(box(cx - arch_w * 0.5, base_y - arch_h, cx + arch_w * 0.5, base_y + 4), radius=round(arch_w * 0.48), fill=rgba(28, 18, 12, round(alpha * 0.90)), outline=rgba(230, 180, 98, 84), width=2)
    for i in range(7):
        x = cx - w * 0.34 + w * 0.68 * i / 6.0
        draw.rectangle(box(x - w * 0.018, base_y - h * 0.56, x + w * 0.018, base_y - h * 0.45), fill=rgba(92, 58, 36, round(alpha * 0.76)))
    draw_roof(draw, cx - w * 0.50, base_y - h * 0.84, w, h * 0.34, alpha, (224, 158, 62))
    draw.rectangle(box(cx - w * 0.22, base_y - h * 0.74, cx + w * 0.22, base_y - h * 0.58), fill=rgba(118, 60, 30, round(alpha * 0.88)), outline=rgba(238, 188, 100, 106), width=2)
    draw.line([xy(cx - w * 0.12, base_y - h * 0.66), xy(cx + w * 0.12, base_y - h * 0.68)], fill=rgba(255, 222, 126, 98), width=2)
    for side in (-1.0, 1.0):
        draw.line([xy(cx + side * w * 0.36, base_y - h * 0.46), xy(cx + side * w * 0.36, base_y + h * 0.08)], fill=dark, width=5)
        draw_lantern(draw, image, cx + side * w * 0.30, base_y - h * 0.34, 0.82)
    add_glow(image, (cx, base_y - h * 0.24), w * 0.18, (255, 170, 70), 18)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("luoyang-dnf-capital-floor-v1")

    horizon = h * 0.47
    bottom = h + 18
    draw.polygon(
        polygon([(w * 0.03, horizon), (w * 0.97, horizon - h * 0.018), (w * 1.05, bottom), (w * -0.05, bottom)]),
        fill=rgba(178, 116, 68, 76),
    )
    for row in range(21):
        t = row / 20.0
        y = horizon + (t * t) * h * 0.50
        alpha = round(86 - t * 28)
        draw.line([xy(w * (0.03 - t * 0.11), y), xy(w * (0.97 + t * 0.11), y - h * 0.018)], fill=rgba(82, 48, 31, alpha), width=max(1, round(1.2 + t * 2.4)))
    for i in range(30):
        t = i / 29.0
        start_x = w * (0.01 + t * 0.98)
        target_x = w * (0.48 + math.sin(i * 0.85) * 0.07)
        draw.line([xy(start_x, bottom), xy(target_x, horizon - 22)], fill=rgba(77, 44, 28, 30 + int(abs(t - 0.5) * 34)), width=1)
    for _ in range(170):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(horizon + h * 0.04, h * 0.97)
        length = rng.uniform(10, 70)
        angle = rng.uniform(-0.18, 0.16)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(76, 45, 30, rng.randint(22, 58)), width=1)

    for cx, cy, pw, ph, color in (
        (w * 0.30, h * 0.55, w * 0.14, h * 0.050, (158, 64, 42)),
        (w * 0.44, h * 0.54, w * 0.17, h * 0.052, (68, 122, 122)),
        (w * 0.58, h * 0.54, w * 0.17, h * 0.052, (180, 120, 52)),
        (w * 0.72, h * 0.55, w * 0.15, h * 0.050, (150, 58, 48)),
    ):
        draw.polygon(polygon([(cx - pw * 0.50, cy), (cx + pw * 0.46, cy - ph * 0.10), (cx + pw * 0.56, cy + ph * 0.48), (cx - pw * 0.44, cy + ph * 0.58)]), fill=rgba(color[0], color[1], color[2], 64), outline=rgba(250, 221, 150, 86))

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.58 + t * 0.30)
        draw.ellipse(box(w * 0.10, y - h * 0.016, w * 0.90, y + h * 0.024), fill=rgba(255, 230, 168, 12 + lane * 3))
        draw.arc(box(w * 0.11, y - h * 0.045, w * 0.89, y + h * 0.042), 5, 176, fill=rgba(255, 222, 145, 26 + lane * 3), width=2)
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(0, h * 0.88, w, h), fill=rgba(18, 12, 8, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    draw_gate_tower(draw, image, w * 0.50, h * 0.46, w * 0.34, h * 0.40, 226)
    shops = [
        (w * 0.02, h * 0.17, w * 0.20, h * 0.31, (206, 154, 102), (216, 142, 56)),
        (w * 0.21, h * 0.21, w * 0.17, h * 0.27, (214, 166, 112), (180, 74, 45)),
        (w * 0.62, h * 0.20, w * 0.17, h * 0.28, (202, 146, 94), (70, 130, 138)),
        (w * 0.78, h * 0.16, w * 0.20, h * 0.32, (218, 164, 104), (218, 142, 56)),
    ]
    for x, y, ww, hh, wall, accent in shops:
        draw_shopfront(draw, image, x, y, ww, hh, wall, accent)

    for x in (w * 0.10, w * 0.25, w * 0.38, w * 0.62, w * 0.76, w * 0.92):
        draw.rectangle(box(x - w * 0.028, h * 0.392, x + w * 0.028, h * 0.435), fill=rgba(54, 31, 20, 112), outline=rgba(238, 188, 96, 54), width=1)
        draw.line([xy(x - w * 0.020, h * 0.421), xy(x + w * 0.022, h * 0.408)], fill=rgba(255, 224, 142, 54), width=1)
        draw_lantern(draw, image, x, h * (0.31 + (int(x) % 3) * 0.018), 0.78)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.rectangle(box(0, h * 0.46, w, h * 0.56), fill=rgba(242, 220, 178, 26))
    fog = fog.filter(ImageFilter.GaussianBlur(14))
    image.alpha_composite(fog)
    return image


def draw_flag(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, side: float, accent: tuple[int, int, int], alpha: int) -> None:
    draw.line([xy(x, y - 110 * scale), xy(x + side * 8 * scale, y + 18 * scale)], fill=rgba(42, 26, 16, alpha), width=max(2, round(4 * scale)))
    draw.polygon(polygon([
        (x, y - 104 * scale),
        (x - side * 72 * scale, y - 86 * scale),
        (x - side * 58 * scale, y - 42 * scale),
        (x, y - 50 * scale),
    ]), fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.72)), outline=rgba(28, 18, 12, round(alpha * 0.62)))
    draw.line([xy(x - side * 50 * scale, y - 70 * scale), xy(x - side * 14 * scale, y - 76 * scale)], fill=rgba(255, 226, 132, round(alpha * 0.48)), width=max(1, round(2 * scale)))


def draw_cart(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - 88 * scale, y - 4 * scale, x + 92 * scale, y + 38 * scale), fill=rgba(0, 0, 0, 62))
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(8 * scale)))
    image.alpha_composite(shadow)
    draw.rectangle(box(x - 66 * scale, y - 46 * scale, x + 64 * scale, y + 18 * scale), fill=rgba(76, 44, 24, alpha), outline=rgba(28, 18, 12, alpha), width=max(1, round(3 * scale)))
    draw.polygon(polygon([(x - 78 * scale, y - 46 * scale), (x, y - 86 * scale), (x + 80 * scale, y - 46 * scale), (x + 64 * scale, y - 32 * scale), (x - 64 * scale, y - 32 * scale)]), fill=rgba(156, 62, 42, alpha), outline=rgba(40, 22, 14, alpha))
    for side in (-1.0, 1.0):
        draw.ellipse(box(x + side * 46 * scale - 15 * scale, y + 8 * scale, x + side * 46 * scale + 15 * scale, y + 38 * scale), fill=rgba(28, 18, 12, alpha))


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("luoyang-dnf-capital-foreground-v1")

    draw.rectangle(box(0, h * 0.93, w, h), fill=rgba(22, 14, 9, 88))
    draw_flag(draw, w * 0.04, h * 0.80, 1.05, -1.0, (190, 48, 34), 210)
    draw_flag(draw, w * 0.96, h * 0.80, 1.00, 1.0, (210, 140, 54), 196)
    draw_cart(draw, image, w * 0.17, h * 0.87, 1.00, 186)
    draw_cart(draw, image, w * 0.84, h * 0.89, 0.84, 160)

    for x0, x1, y in ((w * 0.00, w * 0.22, h * 0.86), (w * 0.69, w * 0.98, h * 0.84)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.018)], fill=rgba(62, 38, 24, 210), width=8)
        for i in range(5):
            tx = x0 + (x1 - x0) * (i / 4.0)
            draw.line([xy(tx, y - h * 0.035), xy(tx + w * 0.008, h)], fill=rgba(42, 28, 18, 220), width=5)

    for _ in range(56):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.86, h * 0.99)
        length = rng.uniform(h * 0.014, h * 0.046)
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=rgba(84, 96, 45, rng.randint(42, 92)), width=1)

    dust = Image.new("RGBA", size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    dd.ellipse(box(-w * 0.15, h * 0.80, w * 0.30, h * 1.05), fill=rgba(230, 210, 176, 36))
    dd.ellipse(box(w * 0.68, h * 0.80, w * 1.14, h * 1.04), fill=rgba(226, 202, 166, 30))
    dust = dust.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(dust)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (160, 172, 158), (136, 118, 88))
    draw = ImageDraw.Draw(image)

    for band in range(3):
        base_y = h * (0.24 + band * 0.055)
        color = rgba(88 + band * 14, 94 + band * 10, 78 + band * 7, 72 - band * 10)
        points = [(0, base_y + h * 0.13)]
        for i in range(13):
            x = w * i / 12.0
            y = base_y + math.sin(i * 1.23 + band) * h * (0.016 + band * 0.005)
            points.append((x, y))
        points.append((w, base_y + h * 0.13))
        draw.polygon(polygon(points), fill=color)
    for i in range(9):
        x = w * (0.08 + i * 0.105)
        y = h * (0.16 + (i % 3) * 0.030)
        draw.rectangle(box(x - 18, y - 16, x + 18, y + 68), fill=rgba(68, 54, 38, 44))
        draw.polygon(polygon([(x - 34, y), (x, y - 30), (x + 36, y), (x + 28, y + 12), (x - 28, y + 14)]), fill=rgba(80, 38, 26, 58))

    floor = draw_floor_layer(size)
    mid = draw_midground_layer(size)
    fg = draw_foreground_layer(size)
    image.alpha_composite(floor)
    image.alpha_composite(mid)
    image.alpha_composite(fg)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(0, h * 0.91, w, h), fill=rgba(0, 0, 0, 54))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
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
    print(f"OK generated Luoyang DNF capital stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
