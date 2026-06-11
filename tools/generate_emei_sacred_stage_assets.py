#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_beiling_mountain_stage_assets import (
    SIZE,
    add_glow,
    box,
    draw_mountain_band,
    draw_pine,
    draw_plank_bridge,
    draw_rock,
    polygon,
    rgba,
    save,
    vertical_gradient,
    xy,
)
from generate_luoyang_dnf_capital_stage_assets import draw_flag, draw_lantern


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_emei_sacred_dnf_cloud_temple_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "emei_sacred_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "emei_sacred_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "emei_sacred_dnf_foreground_v1.png"


def draw_cloud_band(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for i in range(18):
        cx = w * (i / 17.0) + rng.uniform(-70, 70)
        cy = y + rng.uniform(-height * 0.34, height * 0.34)
        rx = rng.uniform(w * 0.055, w * 0.13)
        ry = rng.uniform(height * 0.24, height * 0.52)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(226, 234, 218, rng.randint(round(alpha * 0.55), alpha)))
    layer = layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.12))))
    return layer


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("emei-sacred-floor-v1")

    top_y = h * 0.480
    draw.polygon(polygon([(w * 0.06, top_y), (w * 0.94, top_y - h * 0.022), (w * 1.05, h + 24), (w * -0.05, h + 24)]), fill=rgba(96, 92, 70, 92))
    image.alpha_composite(draw_cloud_band(size, h * 0.600, h * 0.105, "emei-floor-cloud-back", 54))

    path = [(w * 0.43, top_y - h * 0.016), (w * 0.57, top_y - h * 0.024), (w * 0.82, h + 28), (w * 0.18, h + 28)]
    draw.polygon(polygon(path), fill=rgba(138, 124, 90, 116), outline=rgba(50, 40, 28, 84))
    for step in range(15):
        t = step / 14.0
        y = top_y + h * (0.02 + t * t * 0.46)
        spread = w * (0.10 + t * 0.26)
        draw.line([xy(w * 0.50 - spread, y), xy(w * 0.50 + spread, y - h * 0.014)], fill=rgba(222, 204, 150, 40 + step * 4), width=max(2, round(2 + t * 2)))
        draw.line([xy(w * 0.50 - spread, y + 8), xy(w * 0.50 + spread, y - h * 0.014 + 8)], fill=rgba(26, 22, 16, 24 + step * 2), width=1)
    for col in range(28):
        t = col / 27.0
        sx = w * (0.02 + t * 0.96)
        tx = w * (0.50 + math.sin(col * 0.71) * 0.05)
        draw.line([xy(sx, h + 18), xy(tx, top_y - h * 0.024)], fill=rgba(56, 46, 32, 18 + int(abs(t - 0.5) * 34)), width=1)

    draw_plank_bridge(draw, image, w * 0.61, h * 0.592, w * 0.20, h * 0.048, 128)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.61 + t * 0.29)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.024), fill=rgba(240, 230, 176, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.044, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(224, 205, 134, 24 + lane * 3), width=2)

    for _ in range(220):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 20, h * 0.99)
        if rng.random() < 0.22:
            draw_rock(draw, x, y - 18, rng.uniform(18, 46), rng.uniform(12, 30), rng.randint(42, 88), (178, 166, 116))
        elif rng.random() < 0.54:
            length = rng.uniform(9, 58)
            angle = rng.uniform(-0.26, 0.18)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(56, 68, 38, rng.randint(22, 62)), width=1)
        else:
            r = rng.uniform(1.2, 3.8)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(138, 136, 84, rng.randint(26, 80)))
    return image


def draw_summit_temple(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.78, x + w * 0.94, y + h * 1.08), fill=rgba(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    image.alpha_composite(shadow)

    wall = rgba(198, 184, 136, alpha)
    timber = rgba(96, 62, 42, alpha)
    dark = rgba(34, 28, 20, round(alpha * 0.84))
    roof = rgba(176, 126, 52, alpha)
    draw.rectangle(box(x + w * 0.09, y + h * 0.40, x + w * 0.91, y + h), fill=wall, outline=dark, width=2)
    for post in (0.16, 0.32, 0.50, 0.68, 0.84):
        px = x + w * post
        draw.rectangle(box(px, y + h * 0.40, px + w * 0.024, y + h), fill=timber)
        draw.line([xy(px + w * 0.014, y + h * 0.44), xy(px + w * 0.014, y + h * 0.96)], fill=rgba(234, 180, 90, round(alpha * 0.24)), width=1)
    draw.polygon(
        polygon([(x - w * 0.03, y + h * 0.42), (x + w * 0.50, y + h * 0.04), (x + w * 1.03, y + h * 0.42), (x + w * 0.91, y + h * 0.58), (x + w * 0.09, y + h * 0.58)]),
        fill=roof,
        outline=rgba(42, 28, 16, alpha),
    )
    for tile in range(11):
        t = tile / 10.0
        tx = x + w * (0.04 + t * 0.92)
        draw.line([xy(tx, y + h * 0.30), xy(tx + w * 0.058, y + h * 0.56)], fill=rgba(74, 42, 20, round(alpha * 0.34)), width=1)
    draw.rectangle(box(x + w * 0.36, y + h * 0.46, x + w * 0.64, y + h * 0.56), fill=rgba(54, 28, 18, 214), outline=rgba(246, 208, 126, 152), width=2)
    for line in range(3):
        lx = x + w * (0.40 + line * 0.08)
        draw.line([xy(lx, y + h * 0.51), xy(lx + w * 0.036, y + h * 0.495)], fill=rgba(255, 232, 154, 102), width=2)
    door_w = w * 0.17
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rounded_rectangle(box(door_x, y + h * 0.62, door_x + door_w, y + h), radius=round(door_w * 0.14), fill=rgba(46, 34, 30, 168), outline=rgba(230, 178, 96, 112), width=2)
    for lx in (x + w * 0.20, x + w * 0.80):
        draw_lantern(draw, image, lx, y + h * 0.60, 0.58)


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_cloud_band(size, h * 0.455, h * 0.120, "emei-mid-cloud", 50))

    for x, y, scale, alpha, lean in (
        (w * 0.12, h * 0.48, 0.70, 140, 8.0),
        (w * 0.25, h * 0.45, 0.58, 118, -5.0),
        (w * 0.78, h * 0.45, 0.60, 122, 7.0),
        (w * 0.91, h * 0.49, 0.70, 142, -12.0),
    ):
        draw_pine(draw, x, y, scale, alpha, lean)

    draw_summit_temple(draw, image, w * 0.35, h * 0.215, w * 0.30, h * 0.315, 222)
    draw_summit_temple(draw, image, w * 0.13, h * 0.330, w * 0.17, h * 0.200, 160)
    draw_summit_temple(draw, image, w * 0.70, h * 0.330, w * 0.17, h * 0.200, 160)

    for x, side in ((w * 0.30, -1.0), (w * 0.70, 1.0)):
        draw_flag(draw, x, h * 0.505, 0.78, side, (178, 126, 56), 150)
    rail_y = h * 0.532
    draw.line([xy(w * 0.07, rail_y), xy(w * 0.93, rail_y - 16)], fill=rgba(72, 46, 28, 134), width=5)
    for post in range(12):
        t = post / 11.0
        px = w * (0.08 + t * 0.84)
        py = rail_y - 16 * t
        draw.line([xy(px, py - 22), xy(px - 4, py + 34)], fill=rgba(46, 30, 18, 132), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("emei-sacred-foreground-v1")

    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(14, 14, 10, 92))
    draw_pine(draw, w * 0.035, h * 0.88, 1.10, 204, 18.0)
    draw_pine(draw, w * 0.965, h * 0.87, 1.05, 194, -18.0)
    draw_rock(draw, -w * 0.03, h * 0.80, w * 0.18, h * 0.17, 206, (174, 164, 114))
    draw_rock(draw, w * 0.82, h * 0.79, w * 0.20, h * 0.18, 202, (174, 164, 114))
    for x0, x1, y in ((w * 0.00, w * 0.25, h * 0.858), (w * 0.70, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.018)], fill=rgba(56, 38, 22, 205), width=8)
        for i in range(6):
            tx = x0 + (x1 - x0) * (i / 5.0)
            draw.line([xy(tx, y - h * 0.032), xy(tx + w * 0.007, h)], fill=rgba(36, 24, 14, 210), width=5)
    for _ in range(95):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.82, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.066)
        draw.line([xy(x, y), xy(x + rng.uniform(-7, 8), y - length)], fill=rgba(68, 92, 46, rng.randint(40, 102)), width=1)
    image.alpha_composite(draw_cloud_band(size, h * 0.855, h * 0.160, "emei-front-cloud", 42))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (156, 176, 164), (92, 102, 74))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.58, h * 0.14), h * 0.22, (244, 230, 162), 42)
    draw_mountain_band(draw, w, h, h * 0.36, h * 0.30, rgba(70, 94, 84, 70), "emei-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.45, h * 0.28, rgba(54, 76, 64, 96), "emei-mid-mountain")
    draw_mountain_band(draw, w, h, h * 0.54, h * 0.24, rgba(42, 52, 42, 118), "emei-near-mountain")
    image.alpha_composite(draw_cloud_band(size, h * 0.255, h * 0.080, "emei-sky-cloud", 42))

    rng = random.Random("emei-sacred-scene-v1")
    for _ in range(72):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.70)
        length = rng.uniform(4, 12)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(174, 188, 102, rng.randint(14, 52)), width=1)

    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 26))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(vignette)
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Emei sacred DNF cloud temple stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
