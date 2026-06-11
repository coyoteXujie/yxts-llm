#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_bamboo_cluster,
    draw_mountain_band,
    draw_plank_bridge,
    draw_tea_hut,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)
from generate_beiling_mountain_stage_assets import draw_rock
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_shennongjia_dnf_ancient_forest_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "shennongjia_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "shennongjia_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "shennongjia_dnf_foreground_v1.png"


def draw_forest_mist(size: tuple[int, int], y: float, height: float, seed: str, alpha: int, color: tuple[int, int, int] = (198, 226, 178)) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(22):
        cx = rng.uniform(-w * 0.08, w * 1.08)
        cy = y + rng.uniform(-height * 0.42, height * 0.42)
        rx = rng.uniform(w * 0.040, w * 0.135)
        ry = rng.uniform(height * 0.20, height * 0.52)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(color[0], color[1], color[2], rng.randint(round(alpha * 0.36), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(10, round(height * 0.16))))


def draw_giant_tree(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    trunk_w = 70 * scale
    trunk_h = 320 * scale
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - trunk_w * 1.05, y - trunk_h * 0.04, x + trunk_w * 1.25, y + trunk_h * 0.22), fill=rgba(0, 0, 0, 54))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))
    trunk = [
        (x - trunk_w * 0.44, y),
        (x - trunk_w * 0.36, y - trunk_h * 0.30),
        (x - trunk_w * 0.28, y - trunk_h * 0.78),
        (x + trunk_w * 0.12, y - trunk_h),
        (x + trunk_w * 0.38, y - trunk_h * 0.62),
        (x + trunk_w * 0.36, y - trunk_h * 0.18),
        (x + trunk_w * 0.46, y),
    ]
    draw.polygon(polygon(trunk), fill=rgba(74, 50, 30, alpha), outline=rgba(24, 16, 10, round(alpha * 0.78)))
    for i in range(11):
        t = i / 10.0
        bx = x - trunk_w * 0.22 + math.sin(i * 1.4) * trunk_w * 0.12
        draw.line([xy(bx, y - trunk_h * (0.08 + t * 0.82)), xy(bx + rng.uniform(-18, 24) * scale, y - trunk_h * (0.18 + t * 0.78))], fill=rgba(122, 88, 48, round(alpha * 0.34)), width=max(1, round(3 * scale)))
    for side in (-1, 1):
        for i in range(3):
            root_y = y - rng.uniform(2, 18) * scale
            draw.line(
                [xy(x + side * trunk_w * 0.18, root_y), xy(x + side * trunk_w * (0.62 + i * 0.22), root_y + rng.uniform(12, 32) * scale)],
                fill=rgba(54, 34, 20, round(alpha * 0.86)),
                width=max(3, round((8 - i * 1.4) * scale)),
            )
    canopy = Image.new("RGBA", image.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(canopy)
    for _ in range(16):
        cx = x + rng.uniform(-130, 140) * scale
        cy = y - trunk_h * rng.uniform(0.78, 1.18)
        rx = rng.uniform(58, 112) * scale
        ry = rng.uniform(34, 72) * scale
        cd.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(38, rng.randint(82, 128), rng.randint(44, 74), round(alpha * rng.uniform(0.18, 0.44))))
    image.alpha_composite(canopy.filter(ImageFilter.GaussianBlur(max(3, round(7 * scale)))))
    for _ in range(42):
        lx = x + rng.uniform(-100, 116) * scale
        ly = y - rng.uniform(112, 300) * scale
        draw.line([xy(lx, ly), xy(lx + rng.uniform(-24, 24) * scale, ly + rng.uniform(42, 105) * scale)], fill=rgba(58, 94, 44, rng.randint(38, 86)), width=max(1, round(2 * scale)))


def draw_cave(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.08, y + h * 0.62, x + w * 1.08, y + h * 1.12), fill=rgba(0, 0, 0, 58))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.polygon(
        polygon([(x, y + h), (x + w * 0.10, y + h * 0.25), (x + w * 0.50, y), (x + w * 0.92, y + h * 0.28), (x + w, y + h), (x + w * 0.70, y + h * 1.05), (x + w * 0.20, y + h * 1.03)]),
        fill=rgba(80, 88, 70, alpha),
        outline=rgba(26, 30, 22, round(alpha * 0.76)),
    )
    draw.ellipse(box(x + w * 0.30, y + h * 0.35, x + w * 0.72, y + h * 1.03), fill=rgba(18, 24, 22, round(alpha * 0.86)))
    draw.polygon(polygon([(x + w * 0.18, y + h * 0.22), (x + w * 0.34, y + h * 0.14), (x + w * 0.28, y + h * 0.72)]), fill=rgba(176, 184, 132, round(alpha * 0.24)))
    draw.polygon(polygon([(x + w * 0.74, y + h * 0.18), (x + w * 0.86, y + h * 0.34), (x + w * 0.76, y + h * 0.74)]), fill=rgba(176, 184, 132, round(alpha * 0.20)))


def draw_waterfall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    mist = Image.new("RGBA", image.size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    water_shape = [
        (x + w * 0.24, y + h * 0.02),
        (x + w * 0.74, y),
        (x + w * 0.88, y + h * 0.40),
        (x + w * 0.74, y + h * 0.88),
        (x + w * 0.18, y + h * 0.94),
        (x + w * 0.10, y + h * 0.44),
    ]
    md.polygon(polygon(water_shape), fill=rgba(126, 210, 202, round(alpha * 0.30)))
    md.polygon(
        polygon([(x + w * 0.40, y + h * 0.04), (x + w * 0.66, y + h * 0.02), (x + w * 0.58, y + h * 0.84), (x + w * 0.32, y + h * 0.88)]),
        fill=rgba(218, 250, 232, round(alpha * 0.20)),
    )
    for i in range(22):
        sx = x + w * (0.16 + rng.random() * 0.68)
        top_y = y + rng.uniform(0, h * 0.08)
        bottom_y = y + h * rng.uniform(0.72, 0.96)
        md.line([xy(sx, top_y), xy(sx + rng.uniform(-26, 24), bottom_y)], fill=rgba(222, 252, 236, rng.randint(26, 82)), width=rng.randint(1, 3))
    image.alpha_composite(mist.filter(ImageFilter.GaussianBlur(3)))
    draw.ellipse(box(x - w * 0.28, y + h * 0.82, x + w * 1.28, y + h * 1.12), fill=rgba(48, 124, 116, round(alpha * 0.40)), outline=rgba(190, 238, 222, round(alpha * 0.28)), width=2)
    for i in range(9):
        yy = y + h * (0.86 + i * 0.023)
        draw.arc(box(x - w * 0.10, yy - 8, x + w * 1.10, yy + 14), 4, 176, fill=rgba(226, 252, 236, 28 + i * 3), width=1)


def draw_herb_patch(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int, seed: str) -> None:
    rng = random.Random(seed)
    for i in range(28):
        px = x + rng.uniform(-54, 54) * scale
        py = y + rng.uniform(-18, 22) * scale
        length = rng.uniform(14, 42) * scale
        color = (78, rng.randint(132, 188), rng.randint(54, 92)) if i % 5 else (164, 72, 118)
        draw.line([xy(px, py), xy(px + rng.uniform(-8, 8) * scale, py - length)], fill=rgba(color[0], color[1], color[2], round(alpha * rng.uniform(0.45, 0.92))), width=max(1, round(2 * scale)))
        if i % 4 == 0:
            r = rng.uniform(2, 4) * scale
            draw.ellipse(box(px - r, py - length - r, px + r, py - length + r), fill=rgba(210, 96, 132, round(alpha * 0.70)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("shennongjia-floor-v1")
    top_y = h * 0.485
    stream = [
        (w * 0.05, h * 0.590),
        (w * 0.28, h * 0.555),
        (w * 0.46, h * 0.625),
        (w * 0.66, h * 0.660),
        (w * 0.94, h * 0.620),
        (w * 1.04, h * 0.730),
        (w * 0.68, h * 0.792),
        (w * 0.44, h * 0.720),
        (w * 0.20, h * 0.704),
        (w * -0.04, h * 0.748),
    ]
    draw.polygon(polygon([(w * 0.04, top_y), (w * 0.96, top_y - 22), (w * 1.06, h + 24), (w * -0.06, h + 24)]), fill=rgba(82, 116, 58, 108))
    draw.polygon(polygon(stream), fill=rgba(42, 122, 112, 126), outline=rgba(20, 66, 56, 76))
    for line in range(20):
        t = line / 19.0
        y = h * (0.575 + t * 0.175)
        drift = math.sin(line * 1.4) * 28
        draw.line([xy(w * 0.06 + drift, y), xy(w * 0.94 + drift * 0.24, y - 22)], fill=rgba(166, 230, 210, 24 + line % 4 * 9), width=2)
    path = [(w * 0.31, top_y - 12), (w * 0.55, top_y - 26), (w * 0.88, h + 28), (w * 0.13, h + 28)]
    draw.polygon(polygon(path), fill=rgba(128, 108, 74, 104), outline=rgba(52, 40, 28, 70))
    for row in range(14):
        t = row / 13.0
        y = top_y + h * (0.030 + t * t * 0.410)
        left = w * (0.32 - t * 0.22)
        right = w * (0.56 + t * 0.34)
        draw.line([xy(left, y), xy(right, y - 18)], fill=rgba(210, 190, 118, 30 + row * 3), width=max(2, round(2 + t)))
    draw_plank_bridge(draw, image, w * 0.36, h * 0.575, w * 0.28, h * 0.060, 164)
    for x, y, scale, seed in (
        (w * 0.24, h * 0.640, 0.70, "shennong-herb-left"),
        (w * 0.56, h * 0.560, 0.56, "shennong-herb-mid"),
        (w * 0.78, h * 0.660, 0.74, "shennong-herb-right"),
    ):
        draw_herb_patch(draw, x, y, scale, 140, seed)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.61 + t * 0.28)
        draw.ellipse(box(w * 0.11, y - h * 0.014, w * 0.89, y + h * 0.022), fill=rgba(208, 232, 164, 10 + lane * 3))
        draw.arc(box(w * 0.13, y - h * 0.044, w * 0.87, y + h * 0.040), 7, 176, fill=rgba(190, 218, 130, 24 + lane * 3), width=2)
    for _ in range(230):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 10, h * 0.99)
        if rng.random() < 0.44:
            length = rng.uniform(12, 56)
            angle = rng.uniform(-0.42, 0.25)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(40, 78, 32, rng.randint(22, 68)), width=1)
        elif rng.random() < 0.76:
            r = rng.uniform(1.2, 4.0)
            draw.ellipse(box(x - r, y - r * 0.5, x + r, y + r * 0.5), fill=rgba(138, 174, 76, rng.randint(32, 92)))
        else:
            draw_rock(draw, x, y - 18, rng.uniform(16, 42), rng.uniform(10, 28), rng.randint(36, 82), (154, 164, 112))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_forest_mist(size, h * 0.390, h * 0.170, "shennong-mid-mist", 44))
    draw_waterfall(draw, image, w * 0.455, h * 0.235, w * 0.125, h * 0.300, 142, "shennong-waterfall")
    draw_cave(draw, image, w * 0.105, h * 0.333, w * 0.180, h * 0.205, 160)
    draw_tea_hut(draw, image, w * 0.68, h * 0.305, w * 0.20, h * 0.220, 178)
    for x, y, scale, alpha, seed in (
        (w * 0.18, h * 0.535, 0.72, 150, "shennong-tree-left"),
        (w * 0.37, h * 0.525, 0.58, 132, "shennong-tree-mid-left"),
        (w * 0.66, h * 0.530, 0.60, 136, "shennong-tree-mid-right"),
        (w * 0.88, h * 0.540, 0.76, 152, "shennong-tree-right"),
    ):
        draw_giant_tree(draw, image, x, y, scale, alpha, seed)
    for x, y, scale, count, seed in (
        (w * 0.08, h * 0.520, 0.60, 10, "shennong-bamboo-left"),
        (w * 0.92, h * 0.530, 0.64, 11, "shennong-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 126, seed)
    draw_plank_bridge(draw, image, w * 0.17, h * 0.510, w * 0.19, h * 0.050, 120)
    draw_plank_bridge(draw, image, w * 0.57, h * 0.518, w * 0.20, h * 0.052, 118)
    for x, side in ((w * 0.31, -1.0), (w * 0.61, 1.0), (w * 0.82, -1.0)):
        draw_flag(draw, x, h * 0.500, 0.72, side, (88, 128, 72), 132)
    for x in (w * 0.16, w * 0.42, w * 0.72):
        draw_lantern(draw, image, x, h * 0.485, 0.45)
    rail_y = h * 0.535
    draw.line([xy(w * 0.05, rail_y), xy(w * 0.95, rail_y - h * 0.020)], fill=rgba(56, 42, 24, 126), width=5)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = rail_y - h * 0.020 * t
        draw.line([xy(x, y - 24), xy(x - 4, y + 34)], fill=rgba(42, 30, 18, 122), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("shennongjia-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(8, 14, 8, 98))
    draw_giant_tree(draw, image, w * 0.035, h * 0.910, 0.88, 218, "shennong-front-left-tree")
    draw_giant_tree(draw, image, w * 0.965, h * 0.905, 0.84, 208, "shennong-front-right-tree")
    draw_rock(draw, -w * 0.04, h * 0.805, w * 0.20, h * 0.18, 206, (154, 164, 112))
    draw_rock(draw, w * 0.82, h * 0.795, w * 0.21, h * 0.19, 204, (154, 164, 112))
    for x0, x1, y in ((w * 0.00, w * 0.30, h * 0.858), (w * 0.66, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(54, 42, 24, 212), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(26, 20, 12, 174), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(32, 24, 14, 218), width=5)
    for _ in range(120):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.81, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.075)
        color = rgba(44, 102, 42, rng.randint(42, 112)) if rng.random() < 0.80 else rgba(190, 80, 128, rng.randint(40, 98))
        draw.line([xy(x, y), xy(x + rng.uniform(-9, 9), y - length)], fill=color, width=1)
    for x, y, scale, seed in (
        (w * 0.26, h * 0.910, 0.66, "shennong-front-herb-left"),
        (w * 0.74, h * 0.905, 0.70, "shennong-front-herb-right"),
    ):
        draw_herb_patch(draw, x, y, scale, 154, seed)
    image.alpha_composite(draw_forest_mist(size, h * 0.835, h * 0.155, "shennong-front-mist", 54, (186, 226, 170)))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (104, 146, 116), (54, 78, 46))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.54, h * 0.135), h * 0.220, (224, 236, 142), 34)
    draw_mountain_band(draw, w, h, h * 0.340, h * 0.300, rgba(52, 92, 68, 72), "shennong-far")
    draw_mountain_band(draw, w, h, h * 0.445, h * 0.285, rgba(38, 76, 52, 104), "shennong-mid")
    draw_mountain_band(draw, w, h, h * 0.555, h * 0.245, rgba(28, 52, 34, 130), "shennong-near")
    image.alpha_composite(draw_forest_mist(size, h * 0.260, h * 0.110, "shennong-sky-mist", 40))
    rng = random.Random("shennongjia-scene-v1")
    for _ in range(110):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.13, h * 0.74)
        length = rng.uniform(5, 16)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(138, 202, 104, rng.randint(14, 60)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 34))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 62))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 36))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 36))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Shennongjia DNF ancient forest stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
