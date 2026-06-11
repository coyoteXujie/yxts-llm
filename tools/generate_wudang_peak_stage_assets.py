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
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_wudang_peak_dnf_golden_summit_v1.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "wudang_peak_dnf_floor_v1.png"
MIDGROUND_PATH = LAYER_DIR / "wudang_peak_dnf_midground_v1.png"
FOREGROUND_PATH = LAYER_DIR / "wudang_peak_dnf_foreground_v1.png"


def draw_cloud_band(size: tuple[int, int], y: float, height: float, seed: str, alpha: int) -> Image.Image:
    w, _h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    for _ in range(20):
        cx = rng.uniform(-w * 0.06, w * 1.06)
        cy = y + rng.uniform(-height * 0.36, height * 0.36)
        rx = rng.uniform(w * 0.050, w * 0.140)
        ry = rng.uniform(height * 0.22, height * 0.54)
        draw.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(232, 234, 214, rng.randint(round(alpha * 0.48), alpha)))
    return layer.filter(ImageFilter.GaussianBlur(max(8, round(height * 0.14))))


def draw_taiji_disc(draw: ImageDraw.ImageDraw, x: float, y: float, radius: float, alpha: int) -> None:
    draw.ellipse(box(x - radius, y - radius * 0.45, x + radius, y + radius * 0.45), fill=rgba(0, 0, 0, round(alpha * 0.22)))
    draw.ellipse(box(x - radius * 0.78, y - radius * 0.38, x + radius * 0.78, y + radius * 0.38), fill=rgba(116, 108, 86, round(alpha * 0.76)), outline=rgba(34, 30, 24, round(alpha * 0.70)), width=2)
    draw.arc(box(x - radius * 0.55, y - radius * 0.28, x + radius * 0.55, y + radius * 0.28), 0, 180, fill=rgba(230, 220, 166, round(alpha * 0.42)), width=3)
    draw.arc(box(x - radius * 0.55, y - radius * 0.28, x + radius * 0.55, y + radius * 0.28), 180, 360, fill=rgba(22, 24, 22, round(alpha * 0.42)), width=3)
    draw.ellipse(box(x - radius * 0.18, y - radius * 0.10, x + radius * 0.03, y + radius * 0.08), fill=rgba(226, 216, 158, round(alpha * 0.50)))
    draw.ellipse(box(x + radius * 0.04, y - radius * 0.08, x + radius * 0.18, y + radius * 0.08), fill=rgba(22, 24, 20, round(alpha * 0.46)))


def draw_stone_stairs(draw: ImageDraw.ImageDraw, w: int, h: int, top_y: float, bottom_y: float, alpha: int) -> None:
    path = [(w * 0.43, top_y), (w * 0.57, top_y - h * 0.014), (w * 0.82, bottom_y), (w * 0.18, bottom_y + h * 0.02)]
    draw.polygon(polygon(path), fill=rgba(126, 118, 88, round(alpha * 0.76)), outline=rgba(38, 32, 24, round(alpha * 0.60)))
    for step in range(18):
        t = step / 17.0
        y = top_y + (bottom_y - top_y) * (0.03 + t * t * 0.96)
        spread = w * (0.075 + t * 0.285)
        cx = w * (0.50 + math.sin(step * 0.42) * 0.012)
        draw.line([xy(cx - spread, y), xy(cx + spread, y - h * 0.012)], fill=rgba(222, 206, 146, 36 + step * 3), width=max(2, round(2 + t * 2.4)))
        draw.line([xy(cx - spread * 0.96, y + 8), xy(cx + spread * 0.92, y - h * 0.012 + 8)], fill=rgba(24, 20, 16, 22 + step * 2), width=1)
    for col in range(28):
        t = col / 27.0
        sx = w * (0.03 + t * 0.94)
        tx = w * (0.50 + math.sin(col * 0.83) * 0.050)
        draw.line([xy(sx, bottom_y + h * 0.05), xy(tx, top_y - h * 0.018)], fill=rgba(52, 44, 32, 16 + int(abs(t - 0.5) * 32)), width=1)


def draw_golden_hall(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.05, y + h * 0.78, x + w * 0.97, y + h * 1.08), fill=rgba(0, 0, 0, 64))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))
    wall = rgba(178, 144, 88, alpha)
    pillar = rgba(112, 42, 34, alpha)
    dark = rgba(36, 26, 18, round(alpha * 0.86))
    roof = rgba(194, 146, 42, alpha)
    draw.rectangle(box(x + w * 0.08, y + h * 0.43, x + w * 0.92, y + h), fill=wall, outline=dark, width=2)
    for post in (0.15, 0.30, 0.50, 0.70, 0.85):
        px = x + w * post
        draw.rectangle(box(px, y + h * 0.43, px + w * 0.025, y + h), fill=pillar)
        draw.line([xy(px + w * 0.014, y + h * 0.46), xy(px + w * 0.014, y + h * 0.95)], fill=rgba(248, 210, 110, round(alpha * 0.24)), width=1)
    draw.polygon(
        polygon([(x - w * 0.05, y + h * 0.43), (x + w * 0.50, y + h * 0.02), (x + w * 1.05, y + h * 0.43), (x + w * 0.92, y + h * 0.59), (x + w * 0.08, y + h * 0.59)]),
        fill=roof,
        outline=rgba(54, 34, 18, alpha),
    )
    draw.polygon(
        polygon([(x + w * 0.08, y + h * 0.52), (x + w * 0.50, y + h * 0.20), (x + w * 0.92, y + h * 0.52), (x + w * 0.82, y + h * 0.57), (x + w * 0.18, y + h * 0.57)]),
        fill=rgba(224, 182, 68, round(alpha * 0.72)),
    )
    for tile in range(13):
        t = tile / 12.0
        tx = x + w * (0.02 + t * 0.96)
        draw.line([xy(tx, y + h * 0.30), xy(tx + w * 0.056, y + h * 0.56)], fill=rgba(92, 54, 18, round(alpha * 0.32)), width=1)
    sign = box(x + w * 0.35, y + h * 0.470, x + w * 0.65, y + h * 0.570)
    draw.rectangle(sign, fill=rgba(40, 28, 18, 214), outline=rgba(250, 222, 134, 152), width=2)
    for line in range(3):
        lx = x + w * (0.405 + line * 0.075)
        draw.line([xy(lx, y + h * 0.523), xy(lx + w * 0.036, y + h * 0.505)], fill=rgba(255, 232, 150, 112), width=2)
    door_w = w * 0.18
    door_x = x + w * 0.50 - door_w * 0.50
    draw.rounded_rectangle(box(door_x, y + h * 0.63, door_x + door_w, y + h), radius=round(door_w * 0.14), fill=rgba(44, 32, 28, 172), outline=rgba(238, 190, 96, 122), width=2)
    for lx in (x + w * 0.19, x + w * 0.81):
        draw_lantern(draw, image, lx, y + h * 0.62, 0.54)


def draw_side_pavilion(draw: ImageDraw.ImageDraw, image: Image.Image, x: float, y: float, w: float, h: float, alpha: int) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rectangle(box(x + w * 0.08, y + h * 0.76, x + w * 0.94, y + h * 1.04), fill=rgba(0, 0, 0, 46))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    draw.rectangle(box(x + w * 0.12, y + h * 0.42, x + w * 0.88, y + h), fill=rgba(150, 132, 88, alpha), outline=rgba(28, 24, 18, round(alpha * 0.80)), width=2)
    draw.polygon(
        polygon([(x - w * 0.04, y + h * 0.42), (x + w * 0.50, y + h * 0.08), (x + w * 1.04, y + h * 0.42), (x + w * 0.90, y + h * 0.58), (x + w * 0.10, y + h * 0.58)]),
        fill=rgba(58, 82, 58, alpha),
        outline=rgba(18, 22, 14, alpha),
    )
    for post in (0.22, 0.42, 0.62, 0.80):
        px = x + w * post
        draw.rectangle(box(px, y + h * 0.45, px + w * 0.026, y + h), fill=rgba(82, 48, 34, round(alpha * 0.92)))
    draw.rectangle(box(x + w * 0.36, y + h * 0.60, x + w * 0.64, y + h), fill=rgba(38, 34, 30, round(alpha * 0.74)))


def draw_floor_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("wudang-peak-floor-v1")
    top_y = h * 0.468
    draw.polygon(polygon([(w * 0.05, top_y), (w * 0.95, top_y - h * 0.020), (w * 1.05, h + 24), (w * -0.05, h + 24)]), fill=rgba(92, 96, 70, 94))
    draw_cloud = draw_cloud_band(size, h * 0.610, h * 0.120, "wudang-floor-cloud", 38)
    image.alpha_composite(draw_cloud)
    draw_taiji_disc(draw, w * 0.50, h * 0.565, w * 0.135, 124)
    draw_stone_stairs(draw, w, h, top_y + h * 0.015, h + 22, 158)
    for lane in range(5):
        t = (lane + 0.5) / 5.0
        y = h * (0.60 + t * 0.29)
        draw.ellipse(box(w * 0.10, y - h * 0.014, w * 0.90, y + h * 0.023), fill=rgba(236, 222, 164, 10 + lane * 3))
        draw.arc(box(w * 0.12, y - h * 0.044, w * 0.88, y + h * 0.040), 7, 176, fill=rgba(220, 202, 130, 24 + lane * 3), width=2)
    for _ in range(230):
        x = rng.uniform(w * 0.03, w * 0.97)
        y = rng.uniform(top_y + 18, h * 0.99)
        if rng.random() < 0.20:
            draw_rock(draw, x, y - 18, rng.uniform(16, 42), rng.uniform(12, 28), rng.randint(38, 82), (176, 168, 118))
        elif rng.random() < 0.54:
            length = rng.uniform(10, 58)
            angle = rng.uniform(-0.30, 0.20)
            draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.42)], fill=rgba(50, 76, 38, rng.randint(20, 62)), width=1)
        else:
            r = rng.uniform(1.2, 3.8)
            draw.ellipse(box(x - r, y - r * 0.55, x + r, y + r * 0.55), fill=rgba(126, 134, 82, rng.randint(26, 78)))
    return image


def draw_midground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    image.alpha_composite(draw_cloud_band(size, h * 0.420, h * 0.118, "wudang-mid-cloud", 44))
    for x, y, scale, alpha, lean in (
        (w * 0.10, h * 0.50, 0.78, 152, 12.0),
        (w * 0.24, h * 0.455, 0.62, 124, -7.0),
        (w * 0.74, h * 0.455, 0.62, 126, 6.0),
        (w * 0.91, h * 0.505, 0.76, 148, -13.0),
    ):
        draw_pine(draw, x, y, scale, alpha, lean)
    draw_golden_hall(draw, image, w * 0.34, h * 0.208, w * 0.32, h * 0.330, 226)
    draw_side_pavilion(draw, image, w * 0.14, h * 0.325, w * 0.17, h * 0.205, 158)
    draw_side_pavilion(draw, image, w * 0.70, h * 0.325, w * 0.17, h * 0.205, 158)
    draw_taiji_disc(draw, w * 0.50, h * 0.535, w * 0.075, 126)
    for x, side in ((w * 0.30, -1.0), (w * 0.70, 1.0)):
        draw_flag(draw, x, h * 0.500, 0.75, side, (74, 106, 72), 142)
    for x in (w * 0.22, w * 0.38, w * 0.62, w * 0.78):
        draw_lantern(draw, image, x, h * 0.500, 0.44)
    rail_y = h * 0.535
    draw.line([xy(w * 0.07, rail_y), xy(w * 0.93, rail_y - h * 0.018)], fill=rgba(66, 46, 28, 134), width=5)
    draw.line([xy(w * 0.07, rail_y + 22), xy(w * 0.93, rail_y + 4)], fill=rgba(28, 20, 14, 90), width=3)
    for post in range(13):
        t = post / 12.0
        px = w * (0.08 + t * 0.84)
        py = rail_y - h * 0.018 * t
        draw.line([xy(px, py - 22), xy(px - 4, py + 34)], fill=rgba(42, 30, 18, 132), width=4)
    return image


def draw_foreground_layer(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("wudang-peak-foreground-v1")
    draw.rectangle(box(0, h * 0.925, w, h), fill=rgba(14, 14, 10, 94))
    draw_pine(draw, w * 0.035, h * 0.885, 1.14, 210, 18.0)
    draw_pine(draw, w * 0.965, h * 0.875, 1.08, 200, -18.0)
    draw_rock(draw, -w * 0.04, h * 0.792, w * 0.20, h * 0.19, 214, (178, 168, 116))
    draw_rock(draw, w * 0.82, h * 0.785, w * 0.21, h * 0.19, 210, (178, 168, 116))
    for x0, x1, y in ((w * 0.00, w * 0.26, h * 0.858), (w * 0.69, w * 0.99, h * 0.846)):
        draw.line([xy(x0, y), xy(x1, y - h * 0.020)], fill=rgba(52, 36, 22, 212), width=8)
        draw.line([xy(x0, y + 22), xy(x1, y + 1)], fill=rgba(28, 20, 12, 168), width=5)
        for i in range(7):
            tx = x0 + (x1 - x0) * (i / 6.0)
            draw.line([xy(tx, y - h * 0.034), xy(tx + w * 0.008, h)], fill=rgba(34, 24, 14, 220), width=5)
    for i in range(10):
        x = w * (0.29 + i * 0.047)
        y = h * (0.914 + (i % 3) * 0.011)
        draw.rectangle(box(x - 16, y - 20, x + 20, y + 15), fill=rgba(72, 50, 32, 124), outline=rgba(28, 20, 14, 118), width=1)
        draw.line([xy(x - 10, y - 6), xy(x + 13, y - 8)], fill=rgba(232, 204, 126, 56), width=1)
    for _ in range(108):
        x = rng.uniform(w * 0.02, w * 0.98)
        y = rng.uniform(h * 0.81, h * 0.99)
        length = rng.uniform(h * 0.016, h * 0.070)
        draw.line([xy(x, y), xy(x + rng.uniform(-8, 8), y - length)], fill=rgba(52, 96, 42, rng.randint(42, 108)), width=1)
    image.alpha_composite(draw_cloud_band(size, h * 0.845, h * 0.150, "wudang-front-cloud", 40))
    return image


def draw_scene(size: tuple[int, int]) -> Image.Image:
    w, h = size
    image = vertical_gradient(size, (154, 172, 150), (84, 94, 66))
    draw = ImageDraw.Draw(image)
    add_glow(image, (w * 0.54, h * 0.115), h * 0.250, (250, 218, 122), 54)
    draw_mountain_band(draw, w, h, h * 0.355, h * 0.310, rgba(66, 88, 76, 70), "wudang-far-mountain")
    draw_mountain_band(draw, w, h, h * 0.455, h * 0.295, rgba(50, 74, 60, 100), "wudang-mid-mountain")
    draw_mountain_band(draw, w, h, h * 0.552, h * 0.250, rgba(38, 50, 40, 122), "wudang-near-mountain")
    image.alpha_composite(draw_cloud_band(size, h * 0.255, h * 0.085, "wudang-sky-cloud", 42))
    rng = random.Random("wudang-peak-scene-v1")
    for _ in range(92):
        x = rng.uniform(w * 0.04, w * 0.96)
        y = rng.uniform(h * 0.14, h * 0.70)
        length = rng.uniform(5, 14)
        draw.line([xy(x, y), xy(x + length, y + rng.uniform(-3, 4))], fill=rgba(178, 190, 108, rng.randint(14, 54)), width=1)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, w, h * 0.08), fill=rgba(0, 0, 0, 28))
    vd.rectangle(box(0, h * 0.90, w, h), fill=rgba(0, 0, 0, 58))
    vd.rectangle(box(0, 0, w * 0.08, h), fill=rgba(0, 0, 0, 30))
    vd.rectangle(box(w * 0.92, 0, w, h), fill=rgba(0, 0, 0, 30))
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(18)))
    return image.convert("RGB")


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Wudang peak DNF golden summit stage assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
