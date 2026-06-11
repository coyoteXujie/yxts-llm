#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band, draw_plank_bridge, draw_tea_hut
from generate_linan_dnf_water_city_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_arch_bridge,
    draw_boat,
    draw_willow,
    polygon,
    rgba,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_minjiang_river_dnf_valley_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "minjiang_river_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "minjiang_river_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "minjiang_river_dnf_foreground_v1.png"


def draw_rope_bridge(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(
        polygon([(x - 44, y + h * 0.62), (x + w + 48, y + h * 0.48), (x + w + 34, y + h * 0.84), (x - 58, y + h * 1.02)]),
        fill=rgba(0, 0, 0, 54),
    )
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))
    for rail in (-0.38, -0.18):
        points = []
        for step in range(18):
            t = step / 17.0
            px = x + w * t
            py = y + h * (rail + 0.22 * math.sin(t * math.pi))
            points.append(xy(px, py))
        draw.line(points, fill=rgba(56, 36, 20, round(alpha * 0.90)), width=5)
    deck = []
    for step in range(18):
        t = step / 17.0
        deck.append((x + w * t, y + h * (0.05 + 0.18 * math.sin(t * math.pi))))
    for step in range(17, -1, -1):
        t = step / 17.0
        deck.append((x + w * t, y + h * (0.42 + 0.18 * math.sin(t * math.pi))))
    draw.polygon(polygon(deck), fill=rgba(88, 56, 30, alpha), outline=rgba(24, 14, 8, round(alpha * 0.92)))
    for plank in range(15):
        t = plank / 14.0
        px = x + w * t
        py = y + h * (0.10 + 0.18 * math.sin(t * math.pi))
        draw.line([xy(px, py - h * 0.28), xy(px + 8, py + h * 0.52)], fill=rgba(20, 12, 8, round(alpha * 0.52)), width=2)
    for post in range(6):
        t = post / 5.0
        px = x + w * t
        py = y + h * (0.04 + 0.18 * math.sin(t * math.pi))
        draw.line([xy(px, py - h * 0.56), xy(px - 7, py + h * 0.55)], fill=rgba(40, 24, 12, round(alpha * 0.96)), width=4)


def draw_ferry_pier(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.04, y + h * 0.62, x + w * 0.98, y + h * 1.08), fill=rgba(0, 0, 0, 56))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x, y + h * 0.36), (x + w, y + h * 0.18), (x + w + 30, y + h * 0.46), (x + 22, y + h * 0.70)]),
        fill=rgba(92, 58, 30, alpha),
        outline=rgba(24, 14, 8, round(alpha * 0.92)),
    )
    for beam in range(9):
        t = beam / 8.0
        px = x + w * t
        draw.line([xy(px, y + h * 0.34 - h * 0.18 * t), xy(px + 30, y + h * 0.66 - h * 0.16 * t)], fill=rgba(22, 12, 8, round(alpha * 0.48)), width=2)
    for post in range(5):
        t = post / 4.0
        px = x + w * (0.08 + t * 0.82)
        py = y + h * (0.41 - 0.16 * t)
        draw.line([xy(px, py - 22), xy(px - 8, py + h * 0.72)], fill=rgba(42, 26, 12, round(alpha * 0.92)), width=5)
    draw.line([xy(x + w * 0.08, y + h * 0.23), xy(x + w * 0.96, y + h * 0.08)], fill=rgba(56, 34, 18, round(alpha * 0.84)), width=4)


def draw_river_valley_floor(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("minjiang-river-floor-v1")

    river_top = h * 0.485
    river_bottom = h * 0.790
    bank_top = h * 0.605
    river = [
        (w * -0.04, river_top + h * 0.04),
        (w * 0.26, river_top - h * 0.02),
        (w * 0.50, river_top + h * 0.03),
        (w * 0.84, river_top - h * 0.02),
        (w * 1.04, river_top + h * 0.08),
        (w * 1.03, river_bottom),
        (w * 0.70, river_bottom + h * 0.06),
        (w * 0.42, river_bottom - h * 0.02),
        (w * 0.12, river_bottom + h * 0.05),
        (w * -0.05, river_bottom - h * 0.02),
    ]
    draw.polygon(polygon(river), fill=rgba(42, 116, 134, 150), outline=rgba(18, 62, 76, 78))
    for band in range(28):
        t = band / 27.0
        y = river_top + h * (0.026 + t * 0.270)
        drift = math.sin(band * 1.31) * 46
        draw.line([xy(w * 0.03 + drift, y), xy(w * 0.97 + drift * 0.20, y - h * 0.030)], fill=rgba(174, 232, 224, 28 + (band % 5) * 8), width=2)
    for ripple in range(72):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(river_top + 20, river_bottom + 20)
        draw.arc(box(x - 34, y - 8, x + 48, y + 10), 5, 172, fill=rgba(226, 248, 236, rng.randint(18, 58)), width=1)

    near_bank = [(w * 0.02, bank_top), (w * 0.42, bank_top - h * 0.045), (w * 1.05, h + 28), (w * -0.06, h + 30)]
    draw.polygon(polygon(near_bank), fill=rgba(134, 112, 72, 118), outline=rgba(54, 40, 26, 78))
    for row in range(19):
        t = row / 18.0
        y = bank_top + (t * t) * h * 0.38
        left = w * (0.02 - t * 0.10)
        right = w * (0.46 + t * 0.55)
        draw.line([xy(left, y), xy(right, y - h * 0.020)], fill=rgba(224, 202, 132, 26 + row * 3), width=max(1, round(1.5 + t * 2.6)))
    for col in range(26):
        t = col / 25.0
        start_x = w * (-0.04 + t * 1.08)
        target_x = w * (0.35 + math.sin(col * 0.86) * 0.12)
        draw.line([xy(start_x, h + 18), xy(target_x, h * 0.49)], fill=rgba(70, 50, 32, 20 + int(abs(t - 0.5) * 38)), width=1)

    draw_rope_bridge(draw, image, w * 0.36, h * 0.545, w * 0.34, h * 0.095, 178)
    draw_arch_bridge(draw, image, w * 0.09, h * 0.560, w * 0.24, h * 0.105, 138)
    draw_ferry_pier(draw, image, w * 0.64, h * 0.620, w * 0.22, h * 0.088, 162)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.64 + t * 0.27)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(214, 232, 166, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(224, 208, 136, 22 + lane * 3), width=2)

    for _ in range(240):
        x = rng.uniform(w * 0.02, w * 0.99)
        y = rng.uniform(bank_top + 8, h * 0.99)
        if rng.random() < 0.54:
            length = rng.uniform(12, 64)
            angle = rng.uniform(-0.30, 0.22)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(48, 82, 36, rng.randint(20, 66)), width=1)
        else:
            r = rng.uniform(1.3, 4.2)
            draw.ellipse(box(x - r, y - r * 0.52, x + r, y + r * 0.52), fill=rgba(122, 148, 72, rng.randint(28, 84)))
    return image


def draw_cliff_village(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.76, x + w * 0.96, y + h * 1.08), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.10, y + h * 0.34, x + w * 0.90, y + h), fill=rgba(136, 98, 58, alpha), outline=rgba(38, 24, 14, round(alpha * 0.72)))
    draw.polygon(
        polygon([(x - w * 0.06, y + h * 0.42), (x + w * 0.50, y), (x + w * 1.06, y + h * 0.42), (x + w * 0.94, y + h * 0.60), (x + w * 0.06, y + h * 0.62)]),
        fill=rgba(74, 58, 38, alpha),
        outline=rgba(22, 14, 8, alpha),
    )
    for tile in range(8):
        t = tile / 7.0
        tx = x + w * (0.08 + t * 0.84)
        draw.line([xy(tx, y + h * 0.24), xy(tx + w * 0.06, y + h * 0.58)], fill=rgba(30, 20, 14, round(alpha * 0.34)), width=1)
    draw.rectangle(box(x + w * 0.22, y + h * 0.56, x + w * 0.42, y + h), fill=rgba(48, 32, 22, round(alpha * 0.78)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.54, x + w * 0.77, y + h * 0.70), fill=rgba(44, 76, 72, 104), outline=rgba(24, 18, 12, 124))
    sign = box(x + w * 0.36, y + h * 0.365, x + w * 0.66, y + h * 0.475)
    draw.rectangle(sign, fill=rgba(50, 30, 16, 172), outline=rgba(220, 170, 84, 112), width=2)
    draw.line([xy(x + w * 0.41, y + h * 0.425), xy(x + w * 0.61, y + h * 0.405)], fill=rgba(244, 212, 122, 82), width=2)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.37, w, h * 0.60), fill=rgba(220, 236, 210, 38))
    md.ellipse(box(w * 0.08, h * 0.39, w * 0.55, h * 0.62), fill=rgba(220, 238, 216, 26))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(18)))

    for x, y, scale, count, seed in (
        (w * 0.08, h * 0.505, 0.72, 13, "minjiang-mid-bamboo-left"),
        (w * 0.30, h * 0.490, 0.64, 10, "minjiang-mid-bamboo-bank"),
        (w * 0.88, h * 0.515, 0.78, 14, "minjiang-mid-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 132, seed)

    draw_tea_hut(draw, image, w * 0.08, h * 0.304, w * 0.17, h * 0.20, 174)
    draw_cliff_village(draw, image, w * 0.70, h * 0.300, w * 0.18, h * 0.21, 178)
    draw_ferry_pier(draw, image, w * 0.33, h * 0.515, w * 0.20, h * 0.075, 132)
    draw_plank_bridge(draw, image, w * 0.58, h * 0.505, w * 0.18, h * 0.046, 118)

    rail_y = h * 0.532
    draw.line([xy(w * 0.05, rail_y), xy(w * 0.96, rail_y - h * 0.020)], fill=rgba(62, 40, 22, 136), width=5)
    draw.line([xy(w * 0.05, rail_y + 22), xy(w * 0.96, rail_y + 2)], fill=rgba(28, 18, 10, 90), width=3)
    for post in range(14):
        t = post / 13.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - h * 0.020 * t
        draw.line([xy(x, y - 24), xy(x - 5, y + 34)], fill=rgba(44, 28, 16, 132), width=4)

    for x, side in ((w * 0.28, -1.0), (w * 0.56, 1.0), (w * 0.82, -1.0)):
        draw_flag(draw, x, h * 0.500, 0.74, side, (72, 124, 78), 142)
    for x in (w * 0.14, w * 0.42, w * 0.70):
        draw_lantern(draw, image, x, h * 0.485, 0.48)
    draw_boat(draw, image, w * 0.20, h * 0.575, 0.84, 164)
    draw_boat(draw, image, w * 0.76, h * 0.590, 0.78, 148)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("minjiang-river-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(10, 16, 10, 92))
    draw_willow(draw, w * 0.040, h * 0.800, 1.12, 1.0)
    draw_willow(draw, w * 0.970, h * 0.805, 1.02, -1.0)
    draw_bamboo_cluster(draw, w * 0.14, h * 0.965, 0.80, 10, 172, "minjiang-front-bamboo-left", True)
    draw_bamboo_cluster(draw, w * 0.88, h * 0.960, 0.82, 11, 178, "minjiang-front-bamboo-right", True)

    for x0, x1, y in ((w * 0.00, w * 0.28, h * 0.856), (w * 0.64, w * 0.99, h * 0.842)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(60, 40, 24, 214), width=8)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(40, 26, 16, 220), width=5)

    for _ in range(126):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.074)
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=rgba(46, 104, 42, rng.randint(42, 114)), width=1)

    for i in range(9):
        x = w * (0.30 + i * 0.046)
        y = h * (0.910 + (i % 3) * 0.012)
        draw.rectangle(box(x - 16, y - 18, x + 20, y + 17), fill=rgba(70, 48, 28, 128), outline=rgba(28, 18, 12, 118), width=2)
        draw.line([xy(x - 10, y - 4), xy(x + 13, y - 6)], fill=rgba(222, 190, 118, 54), width=1)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.20, h * 0.76, w * 0.34, h * 1.08), fill=rgba(218, 232, 208, 44))
    fd.ellipse(box(w * 0.62, h * 0.77, w * 1.14, h * 1.06), fill=rgba(212, 228, 206, 40))
    fd.ellipse(box(w * 0.28, h * 0.56, w * 0.76, h * 0.72), fill=rgba(220, 244, 234, 24))
    image.alpha_composite(fog.filter(ImageFilter.GaussianBlur(24)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (138, 176, 166), (84, 104, 68))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.15), h * 0.21, (230, 238, 180), 34)
    draw_mountain_band(draw, w, h, h * 0.32, h * 0.27, rgba(70, 104, 90, 68), "minjiang-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.42, h * 0.25, rgba(52, 84, 68, 98), "minjiang-mid-mountain")
    draw_mountain_band(draw, w, h, h * 0.51, h * 0.22, rgba(44, 64, 48, 112), "minjiang-near-mountain")

    rng = random.Random("minjiang-river-scene-v1")
    for i in range(13):
        x = w * (0.015 + i * 0.082)
        y = h * (0.15 + (i % 5) * 0.030)
        draw.ellipse(box(x - 68, y - 13, x + 86, y + 22), fill=rgba(220, 234, 212, 14 + (i % 4) * 5))
    for _ in range(96):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.15, h * 0.73)
        length = rng.uniform(4, 13)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(158, 190, 94, rng.randint(16, 62)), width=1)

    image.alpha_composite(draw_river_valley_floor(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_river_valley_floor(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Minjiang river DNF valley stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
