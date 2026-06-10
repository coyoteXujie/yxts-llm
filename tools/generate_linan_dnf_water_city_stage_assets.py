#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_linan_dnf_water_city_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "linan_dnf_water_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "linan_dnf_waterfront_v1.png"
FOREGROUND_PATH = LAYER_DIR / "linan_dnf_water_foreground_v1.png"
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


def draw_roof(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, roof: tuple[int, int, int], accent: tuple[int, int, int], alpha: int) -> None:
    draw.polygon(
        polygon([
            (x - w * 0.08, y + h * 0.48),
            (x + w * 0.50, y),
            (x + w * 1.08, y + h * 0.48),
            (x + w * 0.96, y + h * 0.64),
            (x + w * 0.04, y + h * 0.66),
        ]),
        fill=rgba(roof[0], roof[1], roof[2], alpha),
        outline=rgba(32, 20, 15, min(255, alpha + 18)),
    )
    draw.line([xy(x + w * 0.04, y + h * 0.58), xy(x + w * 0.96, y + h * 0.54)], fill=rgba(accent[0], accent[1], accent[2], round(alpha * 0.42)), width=3)
    for tile in range(8):
        t = tile / 7.0
        tx = x + w * (0.08 + t * 0.84)
        draw.line([xy(tx, y + h * 0.26 + math.sin(tile) * 3), xy(tx + w * 0.08, y + h * 0.62)], fill=rgba(20, 14, 12, round(alpha * 0.34)), width=1)


def draw_lantern(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, warm: bool = True) -> None:
    glow = (255, 120, 42) if warm else (140, 220, 230)
    add_glow(image, (x, y), 28 * scale, glow, 48)
    draw.line([xy(x, y - 28 * scale), xy(x, y - 10 * scale)], fill=rgba(52, 34, 22, 178), width=max(1, round(2 * scale)))
    draw.ellipse(box(x - 12 * scale, y - 10 * scale, x + 12 * scale, y + 16 * scale), fill=rgba(198, 42, 28, 176), outline=rgba(255, 210, 112, 124), width=max(1, round(2 * scale)))
    draw.line([xy(x - 8 * scale, y + 2 * scale), xy(x + 8 * scale, y + 2 * scale)], fill=rgba(255, 204, 110, 92), width=max(1, round(scale)))


def draw_waterfront_shop(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    x: float,
    y: float,
    w: float,
    h: float,
    wall: tuple[int, int, int],
    roof: tuple[int, int, int],
    accent: tuple[int, int, int],
    alpha: int = 238,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.72, x + w * 0.92, y + h * 1.04), fill=rgba(0, 0, 0, 52))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(shadow)

    draw.rectangle(box(x + w * 0.08, y + h * 0.28, x + w * 0.92, y + h), fill=rgba(wall[0], wall[1], wall[2], alpha), outline=rgba(54, 36, 24, 145), width=2)
    draw_roof(draw, x, y, w, h * 0.42, roof, accent, alpha)

    door_w = w * 0.22
    door_x = x + w * 0.50 - door_w * 0.50
    door_top = y + h * 0.54
    draw.rounded_rectangle(box(door_x, door_top, door_x + door_w, y + h), radius=round(door_w * 0.32), fill=rgba(24, 55, 72, 172), outline=rgba(accent[0], accent[1], accent[2], 118), width=2)
    draw.arc(box(door_x, door_top - door_w * 0.28, door_x + door_w, door_top + door_w * 0.62), 180, 360, fill=rgba(230, 242, 232, 88), width=2)

    for i in range(2):
        wx = x + w * (0.18 + i * 0.50)
        wy = y + h * 0.48
        draw.rounded_rectangle(box(wx, wy, wx + w * 0.18, wy + h * 0.18), radius=6, fill=rgba(24, 68, 90, 116), outline=rgba(38, 48, 54, 132), width=2)
        draw.line([xy(wx + w * 0.09, wy), xy(wx + w * 0.09, wy + h * 0.18)], fill=rgba(230, 244, 232, 52), width=1)

    sign = box(x + w * 0.34, y + h * 0.31, x + w * 0.66, y + h * 0.42)
    draw.rectangle(sign, fill=rgba(77, 36, 18, 184), outline=rgba(245, 202, 115, 132), width=2)
    draw.line([xy(x + w * 0.38, y + h * 0.365), xy(x + w * 0.62, y + h * 0.345)], fill=rgba(252, 226, 138, 86), width=2)

    draw_lantern(draw, image, x + w * 0.16, y + h * 0.42, 0.78)
    draw_lantern(draw, image, x + w * 0.84, y + h * 0.42, 0.78)


def draw_arch_bridge(draw: ImageDraw.ImageDraw, image: Image.Image, cx: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(cx - w * 0.54, y + h * 0.26, cx + w * 0.54, y + h * 0.62), fill=rgba(0, 0, 0, 64))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)

    draw.arc(box(cx - w * 0.50, y - h * 0.28, cx + w * 0.50, y + h * 0.80), 190, 350, fill=rgba(198, 186, 154, alpha), width=22)
    draw.arc(box(cx - w * 0.42, y - h * 0.18, cx + w * 0.42, y + h * 0.68), 190, 350, fill=rgba(78, 64, 46, round(alpha * 0.52)), width=4)
    draw.line([xy(cx - w * 0.48, y + h * 0.33), xy(cx + w * 0.48, y + h * 0.25)], fill=rgba(218, 208, 176, alpha), width=10)
    draw.line([xy(cx - w * 0.44, y + h * 0.41), xy(cx + w * 0.46, y + h * 0.33)], fill=rgba(65, 50, 35, round(alpha * 0.42)), width=4)
    for i in range(8):
        t = i / 7.0
        x = cx - w * 0.42 + w * 0.84 * t
        top_y = y + h * (0.20 + 0.08 * math.sin(t * math.pi))
        draw.line([xy(x, top_y - h * 0.22), xy(x - 4, top_y + h * 0.30)], fill=rgba(66, 48, 32, round(alpha * 0.74)), width=3)
    add_glow(image, (cx + w * 0.44, y + h * 0.06), 22, (255, 150, 58), 34)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("linan-dnf-water-floor-v1")

    horizon = h * 0.47
    water_top = h * 0.50
    street_top = h * 0.58
    draw.polygon(polygon([(0, water_top), (w, water_top - 22), (w, h * 0.69), (0, h * 0.72)]), fill=rgba(44, 103, 118, 126))
    for i in range(12):
        t = i / 11.0
        y = water_top + h * (0.015 + t * 0.15)
        drift = math.sin(i * 1.7) * 18
        draw.line([xy(w * 0.06 + drift, y), xy(w * 0.94 + drift * 0.20, y - 16)], fill=rgba(168, 227, 232, 34 + i % 3 * 8), width=2)

    draw.polygon(
        polygon([(w * 0.05, street_top), (w * 0.95, street_top - 18), (w * 1.05, h + 20), (w * -0.05, h + 24)]),
        fill=rgba(184, 132, 86, 82),
    )
    for row in range(19):
        t = row / 18.0
        y = street_top + (t * t) * h * 0.40
        alpha = round(82 - t * 26)
        draw.line([xy(w * (0.04 - t * 0.10), y), xy(w * (0.96 + t * 0.10), y - 15)], fill=rgba(82, 48, 32, alpha), width=max(1, round(1.1 + t * 2.0)))
    for i in range(26):
        t = i / 25.0
        start_x = w * (0.02 + t * 0.96)
        target_x = w * (0.38 + math.sin(i * 1.37) * 0.08)
        draw.line([xy(start_x, h + 20), xy(target_x, horizon)], fill=rgba(86, 52, 36, 28 + int(abs(t - 0.5) * 30)), width=1)

    for _ in range(150):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(street_top + 18, h * 0.97)
        length = rng.uniform(10, 62)
        angle = rng.uniform(-0.16, 0.14)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(72, 45, 32, rng.randint(24, 58)), width=1)

    draw_arch_bridge(draw, image, w * 0.54, h * 0.525, w * 0.31, h * 0.13, 178)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.62 + t * 0.28)
        draw.ellipse(box(w * 0.12, y - h * 0.014, w * 0.88, y + h * 0.022), fill=rgba(255, 238, 182, 12 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.040), 6, 176, fill=rgba(255, 230, 158, 26 + lane * 3), width=2)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.44, w, h * 0.58), fill=rgba(230, 244, 232, 34))
    mist = mist.filter(ImageFilter.GaussianBlur(16))
    image.alpha_composite(mist)

    shops = [
        (w * 0.02, h * 0.17, w * 0.22, h * 0.31, (225, 218, 186), (88, 45, 34), (46, 128, 150)),
        (w * 0.22, h * 0.13, w * 0.22, h * 0.36, (238, 228, 196), (102, 52, 38), (206, 69, 45)),
        (w * 0.45, h * 0.19, w * 0.18, h * 0.28, (232, 224, 198), (78, 58, 48), (50, 139, 150)),
        (w * 0.62, h * 0.12, w * 0.21, h * 0.36, (226, 215, 182), (111, 50, 36), (214, 126, 48)),
        (w * 0.82, h * 0.20, w * 0.16, h * 0.27, (236, 226, 197), (76, 54, 42), (46, 128, 150)),
    ]
    for x, y, ww, hh, wall, roof, accent in shops:
        draw_waterfront_shop(draw, image, x, y, ww, hh, wall, roof, accent)

    draw_arch_bridge(draw, image, w * 0.31, h * 0.495, w * 0.25, h * 0.11, 140)
    draw_arch_bridge(draw, image, w * 0.74, h * 0.500, w * 0.22, h * 0.10, 126)

    for x in (w * 0.10, w * 0.29, w * 0.43, w * 0.63, w * 0.80, w * 0.93):
        draw.rectangle(box(x - w * 0.026, h * 0.405, x + w * 0.026, h * 0.445), fill=rgba(54, 33, 22, 100), outline=rgba(238, 190, 98, 52), width=1)
        draw.line([xy(x - w * 0.018, h * 0.432), xy(x + w * 0.020, h * 0.420)], fill=rgba(255, 224, 142, 52), width=1)
        draw_lantern(draw, image, x, h * (0.33 + (int(x) % 3) * 0.018), 0.82)

    return image


def draw_willow(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, side: float) -> None:
    trunk = rgba(46, 33, 20, 180)
    leaf = rgba(62, 118, 62, 110)
    draw.line([xy(x, y), xy(x + side * 22 * scale, y - 132 * scale)], fill=trunk, width=max(2, round(6 * scale)))
    for i in range(15):
        t = i / 14.0
        start = (x + side * (16 + math.sin(i) * 7) * scale, y - (106 + t * 54) * scale)
        end = (start[0] - side * (44 + (i % 4) * 9) * scale, start[1] + (54 + (i % 3) * 18) * scale)
        draw.line([xy(*start), xy(*end)], fill=leaf, width=max(1, round(2 * scale)))


def draw_boat(draw: ImageDraw.ImageDraw, image: Image.Image, cx: float, cy: float, scale: float, alpha: int = 190) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(cx - 92 * scale, cy - 4 * scale, cx + 94 * scale, cy + 34 * scale), fill=rgba(0, 0, 0, 62))
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(8 * scale)))
    image.alpha_composite(shadow)
    draw.polygon(polygon([
        (cx - 112 * scale, cy),
        (cx + 104 * scale, cy - 10 * scale),
        (cx + 74 * scale, cy + 35 * scale),
        (cx - 72 * scale, cy + 45 * scale),
    ]), fill=rgba(58, 34, 18, alpha), outline=rgba(24, 16, 10, alpha))
    draw.line([xy(cx - 96 * scale, cy + 10 * scale), xy(cx + 88 * scale, cy + 2 * scale)], fill=rgba(210, 152, 74, round(alpha * 0.36)), width=max(1, round(3 * scale)))
    draw.line([xy(cx - 22 * scale, cy - 64 * scale), xy(cx - 22 * scale, cy + 16 * scale)], fill=rgba(42, 28, 18, alpha), width=max(1, round(3 * scale)))
    draw.polygon(polygon([(cx - 18 * scale, cy - 62 * scale), (cx + 44 * scale, cy - 30 * scale), (cx - 18 * scale, cy - 12 * scale)]), fill=rgba(221, 230, 218, round(alpha * 0.78)), outline=rgba(66, 86, 82, round(alpha * 0.50)))


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("linan-dnf-water-foreground-v1")

    draw.rectangle(box(0, h * 0.93, w, h), fill=rgba(20, 15, 11, 82))
    for x0, x1, y in ((w * 0.00, w * 0.25, h * 0.85), (w * 0.68, w * 0.98, h * 0.84)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(65, 42, 26, 212), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.035), xy(tx + w * 0.008, h)], fill=rgba(42, 28, 18, 220), width=5)

    draw_boat(draw, image, w * 0.16, h * 0.86, 1.0, 198)
    draw_boat(draw, image, w * 0.86, h * 0.88, 0.84, 160)
    draw_willow(draw, w * 0.035, h * 0.78, 1.15, 1.0)
    draw_willow(draw, w * 0.985, h * 0.78, 1.05, -1.0)

    for _ in range(70):
        x = rng.uniform(w * 0.01, w * 0.99)
        y = rng.uniform(h * 0.84, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.058)
        color = rgba(64, 116, 58, rng.randint(48, 105))
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=color, width=1)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.ellipse(box(-w * 0.20, h * 0.78, w * 0.34, h * 1.06), fill=rgba(224, 240, 232, 48))
    md.ellipse(box(w * 0.54, h * 0.78, w * 1.14, h * 1.04), fill=rgba(216, 232, 224, 36))
    mist = mist.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(mist)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (168, 196, 196), (112, 154, 152))
    draw = ImageDraw.Draw(image)

    rng = random.Random("linan-dnf-water-scene-v1")
    for band in range(3):
        base_y = h * (0.24 + band * 0.055)
        color = rgba(56 + band * 8, 104 + band * 9, 92 + band * 7, 78 - band * 12)
        points = [(0, base_y + h * 0.12)]
        for i in range(13):
            x = w * i / 12.0
            y = base_y + math.sin(i * 1.42 + band) * h * (0.018 + band * 0.006)
            points.append((x, y))
        points.append((w, base_y + h * 0.12))
        draw.polygon(polygon(points), fill=color)

    for i in range(10):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.10, h * 0.28)
        r = rng.uniform(32, 74)
        draw.ellipse(box(x - r, y - r * 0.24, x + r, y + r * 0.24), fill=rgba(238, 248, 244, rng.randint(28, 52)))

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
    print(f"OK generated Linan DNF water-city stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
