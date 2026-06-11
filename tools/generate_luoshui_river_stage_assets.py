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


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_luoshui_river_dnf_bridge_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "luoshui_river_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "luoshui_river_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "luoshui_river_dnf_foreground_v1.png"


def draw_riverbank_floor(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("luoshui-river-floor-v1")

    horizon = h * 0.47
    river_top = h * 0.505
    river_bottom = h * 0.735
    path_top = h * 0.615
    draw.polygon(polygon([(0, river_top), (w, river_top - 30), (w, river_bottom), (0, river_bottom + 46)]), fill=rgba(44, 99, 116, 142))
    for band in range(18):
        t = band / 17.0
        y = river_top + h * (0.018 + t * 0.18)
        drift = math.sin(band * 1.47) * 34
        draw.line([xy(w * 0.04 + drift, y), xy(w * 0.95 + drift * 0.20, y - h * 0.020)], fill=rgba(166, 224, 226, 34 + (band % 4) * 9), width=2)
    for ripple in range(46):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(river_top + h * 0.025, river_bottom - h * 0.010)
        draw.arc(box(x - 30, y - 7, x + 42, y + 9), 6, 168, fill=rgba(214, 244, 238, rng.randint(20, 58)), width=1)

    draw.polygon(
        polygon([
            (w * 0.12, path_top),
            (w * 0.52, path_top - h * 0.040),
            (w * 1.04, h + 22),
            (w * -0.06, h + 24),
        ]),
        fill=rgba(152, 120, 76, 108),
        outline=rgba(60, 44, 28, 76),
    )
    for row in range(18):
        t = row / 17.0
        y = path_top + (t * t) * h * 0.38
        left = w * (0.10 - t * 0.15)
        right = w * (0.55 + t * 0.47)
        draw.line([xy(left, y), xy(right, y - h * 0.020)], fill=rgba(224, 196, 122, 28 + row * 3), width=max(1, round(1.5 + t * 2.5)))
    for col in range(24):
        t = col / 23.0
        start_x = w * (-0.02 + t * 1.06)
        target_x = w * (0.40 + math.sin(col * 0.92) * 0.10)
        draw.line([xy(start_x, h + 16), xy(target_x, horizon + h * 0.02)], fill=rgba(70, 48, 32, 22 + int(abs(t - 0.5) * 38)), width=1)

    draw_arch_bridge(draw, image, w * 0.46, h * 0.525, w * 0.36, h * 0.145, 192)
    draw_plank_bridge(draw, image, w * 0.61, h * 0.565, w * 0.23, h * 0.052, 132)

    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.64 + t * 0.27)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(226, 236, 168, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(236, 214, 138, 25 + lane * 3), width=2)

    for _ in range(210):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(path_top + 10, h * 0.99)
        if rng.random() < 0.58:
            length = rng.uniform(10, 64)
            angle = rng.uniform(-0.28, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.45)], fill=rgba(54, 82, 38, rng.randint(20, 62)), width=1)
        else:
            r = rng.uniform(1.4, 4.4)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(126, 146, 72, rng.randint(30, 84)))
    return image


def draw_fishing_shed(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.74, x + w * 0.94, y + h * 1.06), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    image.alpha_composite(shadow)
    draw.rectangle(box(x + w * 0.10, y + h * 0.36, x + w * 0.90, y + h), fill=rgba(136, 104, 70, alpha), outline=rgba(40, 28, 18, round(alpha * 0.74)))
    draw.polygon(
        polygon([(x - w * 0.05, y + h * 0.44), (x + w * 0.50, y), (x + w * 1.05, y + h * 0.44), (x + w * 0.94, y + h * 0.62), (x + w * 0.06, y + h * 0.64)]),
        fill=rgba(70, 58, 42, alpha),
        outline=rgba(24, 16, 10, alpha),
    )
    for post in (0.22, 0.50, 0.78):
        draw.line([xy(x + w * post, y + h * 0.42), xy(x + w * (post - 0.03), y + h * 1.08)], fill=rgba(48, 32, 20, round(alpha * 0.82)), width=4)
    draw.rectangle(box(x + w * 0.24, y + h * 0.57, x + w * 0.43, y + h), fill=rgba(48, 34, 24, round(alpha * 0.76)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.54, x + w * 0.77, y + h * 0.70), fill=rgba(36, 76, 78, 108), outline=rgba(24, 20, 15, 126))
    draw.line([xy(x + w * 0.12, y + h * 0.50), xy(x + w * 0.02, y + h * 0.88)], fill=rgba(206, 178, 98, round(alpha * 0.54)), width=2)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.rectangle(box(0, h * 0.39, w, h * 0.58), fill=rgba(224, 238, 220, 36))
    mist = mist.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(mist)

    for x, y, scale, count, seed in (
        (w * 0.07, h * 0.50, 0.70, 12, "luoshui-mid-left-bamboo"),
        (w * 0.86, h * 0.51, 0.74, 14, "luoshui-mid-right-bamboo"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 132, seed)

    draw_tea_hut(draw, image, w * 0.08, h * 0.315, w * 0.18, h * 0.20, 176)
    draw_fishing_shed(draw, image, w * 0.72, h * 0.30, w * 0.18, h * 0.21, 178)

    draw.line([xy(w * 0.05, h * 0.535), xy(w * 0.95, h * 0.515)], fill=rgba(64, 42, 24, 132), width=5)
    draw.line([xy(w * 0.05, h * 0.558), xy(w * 0.95, h * 0.538)], fill=rgba(28, 18, 10, 86), width=3)
    for post in range(13):
        t = post / 12.0
        x = w * (0.06 + t * 0.88)
        y = h * 0.535 - h * 0.020 * t
        draw.line([xy(x, y - 26), xy(x - 5, y + 34)], fill=rgba(46, 30, 16, 132), width=4)

    for x, side in ((w * 0.31, -1.0), (w * 0.60, 1.0)):
        draw.line([xy(x, h * 0.37), xy(x + side * 10, h * 0.53)], fill=rgba(46, 30, 18, 142), width=4)
        draw.polygon(polygon([(x, h * 0.37), (x + side * 62, h * 0.40), (x + side * 50, h * 0.46), (x + side * 5, h * 0.43)]), fill=rgba(72, 118, 70, 110), outline=rgba(24, 40, 22, 82))

    draw_boat(draw, image, w * 0.20, h * 0.575, 0.86, 172)
    draw_boat(draw, image, w * 0.80, h * 0.585, 0.78, 150)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("luoshui-river-foreground-v1")

    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(12, 16, 10, 88))
    draw_willow(draw, w * 0.035, h * 0.80, 1.20, 1.0)
    draw_willow(draw, w * 0.980, h * 0.80, 1.08, -1.0)
    draw_bamboo_cluster(draw, w * 0.12, h * 0.96, 0.78, 9, 168, "luoshui-front-left", True)
    draw_bamboo_cluster(draw, w * 0.90, h * 0.96, 0.76, 9, 160, "luoshui-front-right", True)

    for x0, x1, y in ((w * 0.00, w * 0.25, h * 0.86), (w * 0.70, w * 0.99, h * 0.845)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(64, 42, 26, 212), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(42, 28, 18, 218), width=5)

    for _ in range(100):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.070)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(48, 104, 42, rng.randint(42, 112)), width=1)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.ellipse(box(-w * 0.18, h * 0.77, w * 0.32, h * 1.08), fill=rgba(218, 232, 208, 42))
    fd.ellipse(box(w * 0.66, h * 0.78, w * 1.16, h * 1.05), fill=rgba(212, 228, 206, 38))
    fog = fog.filter(ImageFilter.GaussianBlur(24))
    image.alpha_composite(fog)
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (144, 178, 168), (92, 110, 72))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.16), h * 0.20, (230, 232, 176), 34)
    draw_mountain_band(draw, w, h, h * 0.35, h * 0.25, rgba(72, 104, 86, 72), "luoshui-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.43, h * 0.23, rgba(54, 82, 66, 96), "luoshui-mid-mountain")

    rng = random.Random("luoshui-river-scene-v1")
    for i in range(12):
        x = w * (0.02 + i * 0.087)
        y = h * (0.17 + (i % 5) * 0.028)
        draw.ellipse(box(x - 64, y - 12, x + 82, y + 20), fill=rgba(220, 232, 210, 14 + (i % 4) * 5))
    for _ in range(80):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.16, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(160, 190, 92, rng.randint(16, 60)), width=1)

    image.alpha_composite(draw_riverbank_floor(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 30))
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
    save(draw_riverbank_floor(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Luoshui river DNF bridge stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
