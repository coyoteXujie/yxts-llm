#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_bashu_bamboo_stage_assets import draw_bamboo_cluster, draw_mountain_band
from generate_beiling_mountain_stage_assets import draw_rock
from generate_linan_dnf_water_city_stage_assets import SIZE, add_glow, box, polygon, rgba, save, vertical_gradient, xy
from generate_luoyang_dnf_capital_stage_assets import draw_cart, draw_flag, draw_lantern
from generate_xindu_field_stage_assets import draw_field_band, draw_haystack


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_dangyang_plain_dnf_battlefield_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "dangyang_plain_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "dangyang_plain_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "dangyang_plain_dnf_foreground_v1.png"


def draw_field_mist(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(18):
        cx = rng.uniform(-w * 0.06, w * 1.06)
        cy = y + rng.uniform(-height * 0.34, height * 0.34)
        rx = rng.uniform(w * 0.040, w * 0.135)
        ry = rng.uniform(height * 0.18, height * 0.46)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(226, 222, 178, rng.randint(round(alpha * 0.34), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.16))))


def draw_old_official_road(draw: ImageDraw.ImageDraw, w: int, h: int, top_y: float, alpha: int) -> None:
    draw.polygon(
        polygon([(w * 0.18, top_y), (w * 0.70, top_y - h * 0.030), (w * 1.06, h + 28), (w * -0.06, h + 30)]),
        fill=rgba(142, 114, 72, alpha),
        outline=rgba(58, 40, 26, round(alpha * 0.62)),
    )
    for row in range(22):
        t = row / 21.0
        y = top_y + (t * t) * h * 0.390
        left = w * (0.16 - t * 0.20)
        right = w * (0.70 + t * 0.30)
        draw.line([xy(left, y), xy(right, y - h * 0.026)], fill=rgba(222, 198, 122, 26 + row * 3), width=max(1, round(1.4 + t * 2.6)))
    for rut in (0.32, 0.56):
        points = []
        for step in range(18):
            t = step / 17.0
            points.append(xy(w * (rut + math.sin(step * 0.80) * 0.025), top_y + h * (0.035 + t * t * 0.34)))
        draw.line(points, fill=rgba(78, 52, 32, 58), width=3)


def draw_battlefield_stele(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - 70 * scale, y + 20 * scale, x + 78 * scale, y + 52 * scale), fill=rgba(0, 0, 0, 46))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    draw.polygon(
        polygon([(x - 30 * scale, y + 34 * scale), (x - 22 * scale, y - 78 * scale), (x + 20 * scale, y - 86 * scale), (x + 36 * scale, y + 34 * scale)]),
        fill=rgba(92, 92, 72, alpha),
        outline=rgba(32, 30, 24, round(alpha * 0.78)),
    )
    for i in range(4):
        yy = y - 50 * scale + i * 18 * scale
        draw.line([xy(x - 13 * scale, yy), xy(x + 18 * scale, yy - 3 * scale)], fill=rgba(198, 176, 104, 58), width=max(1, round(2 * scale)))
    draw.rectangle(box(x - 48 * scale, y + 22 * scale, x + 54 * scale, y + 42 * scale), fill=rgba(70, 60, 44, round(alpha * 0.90)), outline=rgba(28, 22, 16, round(alpha * 0.70)))


def draw_abandoned_relay_station(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.06, y + h * 0.78, x + w * 1.00, y + h * 1.10), fill=rgba(0, 0, 0, 52))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.10, y + h * 0.42, x + w * 0.88, y + h), fill=rgba(138, 100, 60, alpha), outline=rgba(42, 26, 14, round(alpha * 0.74)), width=2)
    draw.polygon(
        polygon([(x - w * 0.08, y + h * 0.44), (x + w * 0.50, y), (x + w * 1.08, y + h * 0.45), (x + w * 0.94, y + h * 0.62), (x + w * 0.06, y + h * 0.64)]),
        fill=rgba(76, 58, 36, alpha),
        outline=rgba(22, 14, 8, alpha),
    )
    draw.rectangle(box(x + w * 0.24, y + h * 0.60, x + w * 0.44, y + h), fill=rgba(46, 30, 18, round(alpha * 0.76)))
    draw.rectangle(box(x + w * 0.58, y + h * 0.54, x + w * 0.78, y + h * 0.70), fill=rgba(46, 78, 62, 98), outline=rgba(24, 18, 12, 120))
    sign = box(x + w * 0.32, y + h * 0.370, x + w * 0.68, y + h * 0.485)
    draw.rectangle(sign, fill=rgba(52, 30, 16, 176), outline=rgba(220, 170, 88, 116), width=2)
    draw.line([xy(x + w * 0.39, y + h * 0.430), xy(x + w * 0.62, y + h * 0.408)], fill=rgba(242, 212, 124, 84), width=2)


def draw_tomb_mound(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(box(x - w * 0.55, y + h * 0.42, x + w * 0.62, y + h * 0.80), fill=rgba(0, 0, 0, 42))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    draw.ellipse(box(x - w * 0.52, y, x + w * 0.52, y + h * 0.70), fill=rgba(90, 110, 58, round(alpha * 0.70)), outline=rgba(38, 58, 28, round(alpha * 0.60)))
    draw.rectangle(box(x - w * 0.20, y + h * 0.34, x + w * 0.22, y + h * 0.78), fill=rgba(54, 48, 36, round(alpha * 0.90)), outline=rgba(24, 20, 14, round(alpha * 0.72)), width=2)
    draw.arc(box(x - w * 0.20, y + h * 0.18, x + w * 0.22, y + h * 0.50), 180, 360, fill=rgba(184, 158, 92, 72), width=2)
    draw.line([xy(x - w * 0.38, y + h * 0.40), xy(x + w * 0.40, y + h * 0.35)], fill=rgba(132, 150, 78, 52), width=2)


def draw_broken_chariot(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, scale: float, alpha: int) -> None:
    draw.rectangle(box(x - 46 * scale, y - 16 * scale, x + 44 * scale, y + 18 * scale), fill=rgba(82, 48, 26, alpha), outline=rgba(26, 16, 10, round(alpha * 0.80)), width=max(1, round(2 * scale)))
    for wx in (x - 34 * scale, x + 36 * scale):
        draw.ellipse(box(wx - 18 * scale, y + 5 * scale, wx + 18 * scale, y + 41 * scale), outline=rgba(30, 18, 10, round(alpha * 0.86)), width=max(2, round(4 * scale)))
        draw.line([xy(wx - 14 * scale, y + 23 * scale), xy(wx + 14 * scale, y + 23 * scale)], fill=rgba(36, 22, 12, round(alpha * 0.74)), width=max(1, round(2 * scale)))
        draw.line([xy(wx, y + 8 * scale), xy(wx, y + 39 * scale)], fill=rgba(36, 22, 12, round(alpha * 0.74)), width=max(1, round(2 * scale)))
    draw.line([xy(x + 42 * scale, y - 4 * scale), xy(x + 98 * scale, y - 34 * scale)], fill=rgba(64, 38, 20, round(alpha * 0.82)), width=max(2, round(4 * scale)))
    draw.line([xy(x - 48 * scale, y - 14 * scale), xy(x - 76 * scale, y - 38 * scale)], fill=rgba(64, 38, 20, round(alpha * 0.72)), width=max(2, round(3 * scale)))


def draw_weapon_relics(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float, alpha: int) -> None:
    for i, offset in enumerate((-42, -16, 18, 44)):
        lean = (-1 if i % 2 == 0 else 1) * 10 * scale
        draw.line([xy(x + offset * scale, y + 26 * scale), xy(x + offset * scale + lean, y - 44 * scale)], fill=rgba(58, 44, 28, round(alpha * 0.86)), width=max(1, round(3 * scale)))
        draw.polygon(
            polygon([(x + offset * scale + lean, y - 52 * scale), (x + offset * scale + lean + 7 * scale, y - 40 * scale), (x + offset * scale + lean - 6 * scale, y - 39 * scale)]),
            fill=rgba(156, 150, 118, round(alpha * 0.70)),
        )


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("dangyang-plain-floor-v1")
    horizon = h * 0.465
    path_top = h * 0.590
    draw_field_band(draw, w * 0.02, horizon, w * 0.38, h * 0.610, (112, 148, 64), 90, "dangyang-left-rice")
    draw_field_band(draw, w * 0.58, horizon - 4, w * 0.98, h * 0.620, (128, 154, 70), 86, "dangyang-right-rice")
    draw_old_official_road(draw, w, h, path_top, 112)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.640 + t * 0.265)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.022), fill=rgba(230, 224, 150, 11 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.043, w * 0.88, y + h * 0.041), 7, 174, fill=rgba(218, 200, 120, 23 + lane * 3), width=2)
    for _ in range(260):
        x = rng.uniform(w * 0.03, w * 0.98)
        y = rng.uniform(path_top + 8, h * 0.99)
        if rng.random() < 0.22:
            draw_rock(draw, x, y - 14, rng.uniform(12, 34), rng.uniform(8, 20), rng.randint(28, 66), (142, 134, 92))
        elif rng.random() < 0.42:
            r = rng.uniform(1.2, 4.0)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(136, 154, 76, rng.randint(28, 82)))
        else:
            length = rng.uniform(10, 58)
            angle = rng.uniform(-0.28, 0.20)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.40)], fill=rgba(76, 62, 34, rng.randint(20, 58)), width=1)
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_field_mist(size, h * 0.405, h * 0.140, "dangyang-mid-mist", 34))
    draw_abandoned_relay_station(draw, image, w * 0.10, h * 0.292, w * 0.18, h * 0.205, 170)
    draw_tomb_mound(draw, image, w * 0.73, h * 0.365, w * 0.18, h * 0.160, 142)
    draw_battlefield_stele(draw, image, w * 0.50, h * 0.500, 0.86, 142)
    draw_weapon_relics(draw, w * 0.38, h * 0.510, 0.72, 132)
    draw_broken_chariot(draw, image, w * 0.62, h * 0.510, 0.62, 126)
    for x, y, scale, count, seed in (
        (w * 0.05, h * 0.515, 0.64, 9, "dangyang-bamboo-left"),
        (w * 0.90, h * 0.512, 0.66, 10, "dangyang-bamboo-right"),
    ):
        draw_bamboo_cluster(draw, x, y, scale, count, 118, seed)
    for x, side, color in ((w * 0.30, -1.0, (126, 82, 48)), (w * 0.58, 1.0, (92, 112, 62)), (w * 0.82, -1.0, (128, 72, 46))):
        draw_flag(draw, x, h * 0.500, 0.72, side, color, 136)
    for x in (w * 0.20, w * 0.72):
        draw_lantern(draw, image, x, h * 0.480, 0.43)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("dangyang-plain-foreground-v1")
    draw.rectangle(box(0, h * 0.928, w, h), fill=rgba(14, 16, 8, 90))
    draw_cart(draw, image, w * 0.16, h * 0.890, 0.74, 132)
    draw_haystack(draw, w * 0.86, h * 0.900, 0.74, 144)
    draw_broken_chariot(draw, image, w * 0.55, h * 0.890, 0.50, 118)
    for x0, x1, y in ((w * 0.00, w * 0.32, h * 0.855), (w * 0.66, w * 0.99, h * 0.842)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(58, 42, 24, 206), width=8)
        draw.line([xy(x0, y + 20), xy(x1, y + 2)], fill=rgba(28, 20, 12, 150), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(36, 24, 14, 212), width=5)
    for i in range(8):
        x = w * (0.30 + i * 0.052)
        y = h * (0.918 + (i % 2) * 0.014)
        draw.rectangle(box(x - 15, y - 18, x + 20, y + 17), fill=rgba(72, 50, 28, 118), outline=rgba(28, 18, 12, 112), width=2)
    for _ in range(118):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.80, h * 0.99)
        length = rng.uniform(h * 0.018, h * 0.070)
        color = rgba(64, 118, 46, rng.randint(38, 108)) if rng.random() < 0.74 else rgba(132, 104, 54, rng.randint(38, 92))
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=color, width=1)
    image.alpha_composite(draw_field_mist(size, h * 0.820, h * 0.140, "dangyang-front-mist", 34))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (150, 174, 130), (88, 104, 60))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.57, h * 0.14), h * 0.205, (238, 226, 150), 30)
    draw_mountain_band(draw, w, h, h * 0.330, h * 0.230, rgba(80, 104, 72, 58), "dangyang-far-hills")
    draw_mountain_band(draw, w, h, h * 0.420, h * 0.205, rgba(58, 84, 58, 82), "dangyang-near-hills")
    image.alpha_composite(draw_field_mist(size, h * 0.280, h * 0.100, "dangyang-sky-haze", 30))
    rng = random.Random("dangyang-plain-scene-v1")
    for _ in range(96):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.72)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(168, 188, 90, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 28))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Dangyang plain DNF battlefield stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
