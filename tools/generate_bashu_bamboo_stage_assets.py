#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_bashu_bamboo_dnf_bamboo_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "bashu_bamboo_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "bashu_bamboo_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "bashu_bamboo_dnf_foreground_v1.png"
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
    points: list[tuple[float, float]] = [(0, base_y + height * 0.38)]
    steps = 16
    for i in range(steps + 1):
        x = w * i / steps
        y = base_y - height * (0.34 + rng.random() * 0.42) + math.sin(i * 1.19) * height * 0.08
        points.append((x, y))
    points.append((w, base_y + height * 0.38))
    draw.polygon(polygon(points), fill=color)


def draw_bamboo_cluster(
    draw: ImageDraw.ImageDraw,
    x: float,
    y: float,
    scale: float,
    count: int,
    alpha: int,
    seed: str,
    tall: bool = False,
) -> None:
    rng = random.Random(seed)
    for index in range(count):
        dx = rng.uniform(-64, 64) * scale
        base_y = y + rng.uniform(-16, 18) * scale
        height = rng.uniform(190, 320) * scale * (1.22 if tall else 1.0)
        lean = rng.uniform(-32, 32) * scale
        base = (x + dx, base_y)
        top = (base[0] + lean, base_y - height)
        width = max(2, round(rng.uniform(4.0, 7.5) * scale * (1.18 if tall else 1.0)))
        stem = rgba(rng.randint(42, 72), rng.randint(118, 158), rng.randint(64, 88), round(alpha * rng.uniform(0.62, 0.96)))
        draw.line([xy(*base), xy(*top)], fill=stem, width=width)
        draw.line([xy(base[0] + width * 0.8, base[1]), xy(top[0] + width * 0.8, top[1])], fill=rgba(200, 224, 130, round(alpha * 0.22)), width=max(1, width // 3))
        for knot in range(6):
            t = (knot + 1) / 7.0
            kx = base[0] + (top[0] - base[0]) * t
            ky = base[1] + (top[1] - base[1]) * t
            draw.line([xy(kx - 8 * scale, ky), xy(kx + 8 * scale, ky - 1 * scale)], fill=rgba(205, 220, 126, round(alpha * 0.32)), width=1)
        for leaf in range(6):
            t = rng.uniform(0.18, 0.86)
            lx = base[0] + (top[0] - base[0]) * t
            ly = base[1] + (top[1] - base[1]) * t
            side = -1 if (leaf + index) % 2 == 0 else 1
            length = rng.uniform(38, 86) * scale
            draw.line([xy(lx, ly), xy(lx + side * length, ly + rng.uniform(10, 34) * scale)], fill=rgba(58, 130, 74, round(alpha * 0.46)), width=max(1, round(2 * scale)))


def draw_plank_bridge(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(polygon([(x - 44, y + h * 0.38), (x + w + 44, y + h * 0.22), (x + w + 26, y + h * 0.72), (x - 54, y + h * 0.86)]), fill=rgba(0, 0, 0, 62))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)
    draw.polygon(polygon([(x, y), (x + w, y - h * 0.15), (x + w + 30, y + h * 0.34), (x - 28, y + h * 0.56)]), fill=rgba(82, 52, 27, alpha), outline=rgba(24, 14, 8, alpha))
    for plank in range(12):
        t = plank / 11.0
        px = x + w * t
        draw.line([xy(px, y - h * (0.15 * t)), xy(px + 18, y + h * (0.52 - 0.14 * t))], fill=rgba(18, 10, 6, round(alpha * 0.45)), width=2)
    for rail_y in (-0.34, -0.10):
        draw.line([xy(x - 18, y + h * rail_y), xy(x + w + 18, y - h * (0.15 - rail_y))], fill=rgba(52, 34, 18, round(alpha * 0.88)), width=5)
    for post in range(5):
        t = post / 4.0
        px = x + w * t
        py = y - h * (0.15 * t)
        draw.line([xy(px, py - h * 0.48), xy(px - 6, py + h * 0.44)], fill=rgba(38, 24, 12, round(alpha * 0.92)), width=4)


def draw_tea_hut(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.10, y + h * 0.70, x + w * 0.94, y + h * 1.06), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(shadow)
    draw.rectangle(box(x + w * 0.10, y + h * 0.34, x + w * 0.90, y + h), fill=rgba(158, 118, 72, alpha), outline=rgba(38, 24, 16, round(alpha * 0.72)))
    draw.polygon(
        polygon([(x - w * 0.06, y + h * 0.44), (x + w * 0.50, y), (x + w * 1.06, y + h * 0.44), (x + w * 0.94, y + h * 0.60), (x + w * 0.06, y + h * 0.62)]),
        fill=rgba(76, 62, 44, alpha),
        outline=rgba(20, 14, 10, alpha),
    )
    for tile in range(9):
        t = tile / 8.0
        tx = x + w * (0.08 + t * 0.84)
        draw.line([xy(tx, y + h * 0.25), xy(tx + w * 0.06, y + h * 0.58)], fill=rgba(30, 22, 16, round(alpha * 0.34)), width=1)
    draw.rectangle(box(x + w * 0.22, y + h * 0.58, x + w * 0.42, y + h), fill=rgba(46, 34, 28, round(alpha * 0.76)))
    draw.rectangle(box(x + w * 0.55, y + h * 0.54, x + w * 0.77, y + h * 0.72), fill=rgba(46, 72, 64, 112), outline=rgba(34, 24, 18, 132))
    sign = box(x + w * 0.38, y + h * 0.37, x + w * 0.64, y + h * 0.48)
    draw.rectangle(sign, fill=rgba(52, 32, 18, 176), outline=rgba(224, 176, 90, 118), width=2)
    draw.line([xy(x + w * 0.42, y + h * 0.425), xy(x + w * 0.60, y + h * 0.405)], fill=rgba(244, 216, 126, 86), width=2)


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("bashu-bamboo-floor-v1")
    ground_top = h * 0.50

    stream = [
        (w * 0.06, h * 0.58),
        (w * 0.26, h * 0.56),
        (w * 0.45, h * 0.62),
        (w * 0.64, h * 0.66),
        (w * 0.93, h * 0.62),
        (w * 1.03, h * 0.72),
        (w * 0.66, h * 0.78),
        (w * 0.46, h * 0.72),
        (w * 0.23, h * 0.69),
        (w * -0.05, h * 0.74),
    ]
    draw.polygon(polygon([(w * 0.04, ground_top), (w * 0.96, ground_top - 20), (w * 1.06, h + 24), (w * -0.06, h + 24)]), fill=rgba(92, 116, 58, 96))
    draw.polygon(polygon(stream), fill=rgba(54, 126, 120, 112), outline=rgba(24, 66, 60, 74))
    for line in range(16):
        t = line / 15.0
        y = h * (0.575 + t * 0.16)
        drift = math.sin(line * 1.4) * 22
        draw.line([xy(w * 0.08 + drift, y), xy(w * 0.94 + drift * 0.24, y - 22)], fill=rgba(166, 228, 210, 26 + line % 4 * 8), width=2)

    path = [(w * 0.34, ground_top - 16), (w * 0.54, ground_top - 26), (w * 0.86, h + 26), (w * 0.15, h + 28)]
    draw.polygon(polygon(path), fill=rgba(148, 120, 78, 104), outline=rgba(56, 42, 28, 72))
    for row in range(12):
        t = row / 11.0
        y = ground_top + h * (0.03 + t * t * 0.40)
        left = w * (0.33 - t * 0.22)
        right = w * (0.55 + t * 0.32)
        draw.line([xy(left, y), xy(right, y - 18)], fill=rgba(215, 190, 124, 32 + row * 3), width=3)

    draw_plank_bridge(draw, image, w * 0.35, h * 0.575, w * 0.28, h * 0.060, 168)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.61 + t * 0.28)
        draw.ellipse(box(w * 0.11, y - h * 0.014, w * 0.89, y + h * 0.022), fill=rgba(212, 232, 166, 10 + lane * 3))
        draw.arc(box(w * 0.13, y - h * 0.044, w * 0.87, y + h * 0.040), 7, 176, fill=rgba(196, 218, 132, 24 + lane * 3), width=2)

    for _ in range(220):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(ground_top + 8, h * 0.99)
        if rng.random() < 0.46:
            length = rng.uniform(12, 54)
            angle = rng.uniform(-0.40, 0.25)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(42, 76, 32, rng.randint(22, 64)), width=1)
        else:
            r = rng.uniform(1.2, 3.8)
            draw.ellipse(box(x - r, y - r * 0.5, x + r, y + r * 0.5), fill=rgba(138, 170, 76, rng.randint(32, 88)))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.39, w, h * 0.58), fill=rgba(216, 232, 190, 34))
    mist = mist.filter(ImageFilter.GaussianBlur(20))
    image.alpha_composite(mist)

    for x, y, scale, count, seed in (
        (w * 0.10, h * 0.51, 0.78, 18, "bashu-mid-1"),
        (w * 0.28, h * 0.49, 0.68, 16, "bashu-mid-2"),
        (w * 0.72, h * 0.50, 0.72, 18, "bashu-mid-3"),
        (w * 0.90, h * 0.52, 0.80, 19, "bashu-mid-4"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 142, seed)

    draw_tea_hut(draw, image, w * 0.08, h * 0.28, w * 0.22, h * 0.23, 196)
    draw_tea_hut(draw, image, w * 0.70, h * 0.29, w * 0.20, h * 0.22, 184)
    draw_plank_bridge(draw, image, w * 0.14, h * 0.505, w * 0.20, h * 0.050, 118)
    draw_plank_bridge(draw, image, w * 0.66, h * 0.520, w * 0.18, h * 0.046, 112)

    rail_y = h * 0.535
    draw.line([xy(w * 0.04, rail_y), xy(w * 0.96, rail_y - 18)], fill=rgba(62, 42, 22, 134), width=5)
    draw.line([xy(w * 0.04, rail_y + 22), xy(w * 0.96, rail_y + 4)], fill=rgba(30, 20, 12, 92), width=3)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - 18 * t
        draw.line([xy(x, y - 24), xy(x - 4, y + 34)], fill=rgba(48, 32, 18, 130), width=4)

    for x, side in ((w * 0.37, -1.0), (w * 0.63, 1.0)):
        draw.line([xy(x, h * 0.37), xy(x + side * 8, h * 0.52)], fill=rgba(44, 28, 16, 142), width=4)
        draw.polygon(polygon([(x, h * 0.37), (x + side * 58, h * 0.40), (x + side * 48, h * 0.46), (x + side * 4, h * 0.43)]), fill=rgba(58, 112, 68, 110), outline=rgba(20, 38, 22, 82))
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("bashu-bamboo-foreground-v1")
    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(14, 18, 11, 92))
    draw_bamboo_cluster(draw, w * 0.02, h * 0.91, 1.05, 14, 220, "bashu-front-left", True)
    draw_bamboo_cluster(draw, w * 0.98, h * 0.90, 1.02, 14, 210, "bashu-front-right", True)
    draw_bamboo_cluster(draw, w * 0.50, h * 0.99, 0.74, 7, 114, "bashu-front-low", False)

    for _ in range(95):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.066)
        draw.line([xy(x, y), xy(x + rng.uniform(-10, 10), y - length)], fill=rgba(50, 104, 44, rng.randint(42, 110)), width=1)

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(-w * 0.16, h * 0.78, w * 0.30, h * 1.08), fill=rgba(8, 18, 10, 48))
    sd.ellipse(box(w * 0.70, h * 0.78, w * 1.16, h * 1.08), fill=rgba(8, 18, 10, 48))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(shadow)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (132, 166, 150), (82, 94, 58))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.16), h * 0.20, (228, 238, 170), 36)
    draw_mountain_band(draw, w, h, h * 0.38, h * 0.28, rgba(76, 104, 82, 68), "bashu-far")
    draw_mountain_band(draw, w, h, h * 0.46, h * 0.24, rgba(54, 84, 62, 96), "bashu-mid")
    for i in range(12):
        x = w * (0.02 + i * 0.09)
        y = h * (0.20 + (i % 5) * 0.026)
        draw.ellipse(box(x - 62, y - 12, x + 78, y + 18), fill=rgba(212, 232, 190, 14 + (i % 4) * 5))

    floor = draw_floor_layer(size)
    midground = draw_midground_layer(size)
    foreground = draw_foreground_layer(size)
    image.alpha_composite(floor)
    image.alpha_composite(midground)
    image.alpha_composite(foreground)

    leaf_drift = Image.new("RGBA", size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(leaf_drift)
    rng = random.Random("bashu-scene-leaf-drift-v1")
    for _ in range(120):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.78)
        length = rng.uniform(4, 12)
        ld.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(162, 194, 92, rng.randint(18, 70)), width=1)
    image.alpha_composite(leaf_drift)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
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
    print(f"OK generated Bashu bamboo stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
