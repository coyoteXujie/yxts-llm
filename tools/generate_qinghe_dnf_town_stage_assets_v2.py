#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_qinghe_dnf_town_stage_assets import add_glow, add_painterly_grain, box, polygon, rgba, vertical_gradient, xy


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
SCENE_PATH = PROJECT / "assets" / "world" / "scenes" / "scene_qinghe_dnf_town_v2.png"
LAYER_DIR = PROJECT / "assets" / "world" / "stage_layers"
FLOOR_PATH = LAYER_DIR / "qinghe_dnf_floor_v2.png"
MIDGROUND_PATH = LAYER_DIR / "qinghe_dnf_shopfronts_v2.png"
FOREGROUND_PATH = LAYER_DIR / "qinghe_dnf_foreground_v2.png"
HIGH_SHOPFRONT = LAYER_DIR / "qinghe_shopfront_layer_v2.png"
HIGH_FOREGROUND = LAYER_DIR / "qinghe_foreground_layer_v1.png"
SIZE = (1672, 941)


def paste_scaled_fit(canvas: Image.Image, source_path: Path, target_width: int, y: int) -> tuple[int, int]:
    source = Image.open(source_path).convert("RGBA")
    scale = target_width / source.size[0]
    target_height = round(source.size[1] * scale)
    resized = source.resize((target_width, target_height), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, (0, y))
    return target_width, target_height


def draw_far_environment(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    rng = random.Random("qinghe-v2-far")
    for band in range(5):
        base_y = height * (0.135 + band * 0.050)
        color = rgba(56 + band * 16, 76 + band * 13, 62 + band * 8, 70 - band * 7)
        points = [(0, base_y + height * 0.12)]
        for index in range(15):
            x = width * index / 14.0
            y = base_y + math.sin(index * 0.92 + band * 1.15) * height * (0.018 + band * 0.004)
            points.append((x, y))
        points.append((width, base_y + height * 0.12))
        draw.polygon(polygon(points), fill=color)
    for index in range(16):
        x = width * (0.035 + index * 0.064)
        y = height * (0.205 + rng.random() * 0.075)
        w = width * rng.uniform(0.030, 0.060)
        h = height * rng.uniform(0.045, 0.070)
        draw.rectangle(box(x - w * 0.34, y, x + w * 0.34, y + h), fill=rgba(74, 54, 38, 42))
        draw.polygon(
            polygon([(x - w * 0.58, y + h * 0.10), (x, y - h * 0.48), (x + w * 0.58, y + h * 0.10), (x + w * 0.48, y + h * 0.28), (x - w * 0.48, y + h * 0.28)]),
            fill=rgba(82, 42, 30, 58),
        )


def draw_floor_layer(size: tuple[int, int] = SIZE) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-floor-v2-rich")
    horizon = height * 0.485
    bottom = height + 20

    draw.polygon(
        polygon([(width * -0.04, horizon + 8), (width * 1.04, horizon - 24), (width * 1.08, bottom), (width * -0.08, bottom)]),
        fill=rgba(150, 102, 63, 132),
    )
    draw.polygon(
        polygon([(width * 0.08, horizon + 38), (width * 0.92, horizon + 10), (width * 1.00, bottom), (width * 0.00, bottom)]),
        fill=rgba(178, 124, 74, 96),
    )

    for row in range(30):
        t = row / 29.0
        y = horizon + (t * t) * height * 0.51
        alpha = round(118 - t * 48)
        draw.line(
            [xy(width * (0.00 - t * 0.10), y), xy(width * (1.00 + t * 0.10), y - height * 0.022)],
            fill=rgba(66, 42, 28, alpha),
            width=max(1, round(1.2 + t * 3.6)),
        )
        if row % 2 == 0:
            draw.line(
                [xy(width * (0.04 - t * 0.08), y + 7 + t * 10), xy(width * (0.96 + t * 0.08), y - height * 0.016 + 7 + t * 10)],
                fill=rgba(246, 210, 142, round(alpha * 0.22)),
                width=1,
            )

    for column in range(38):
        t = column / 37.0
        start_x = width * (0.005 + t * 0.99)
        target_x = width * (0.50 + math.sin(column * 0.67) * 0.075)
        draw.line([xy(start_x, bottom), xy(target_x, horizon - 30)], fill=rgba(72, 45, 30, 30 + int(abs(t - 0.5) * 42)), width=1)

    for _ in range(520):
        x = rng.uniform(width * 0.02, width * 0.98)
        y = rng.uniform(horizon + height * 0.015, height * 0.985)
        length = rng.uniform(10, 84)
        angle = rng.uniform(-0.24, 0.20)
        color = rng.choice([(92, 58, 36), (128, 82, 48), (210, 162, 96), (48, 32, 24)])
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.34)], fill=rgba(color[0], color[1], color[2], rng.randint(18, 56)), width=1)

    for cx, cy, pw, ph, color in (
        (width * 0.18, height * 0.590, width * 0.16, height * 0.060, (178, 64, 44)),
        (width * 0.36, height * 0.565, width * 0.18, height * 0.060, (68, 128, 142)),
        (width * 0.55, height * 0.568, width * 0.18, height * 0.058, (194, 132, 54)),
        (width * 0.73, height * 0.592, width * 0.20, height * 0.064, (80, 136, 96)),
        (width * 0.88, height * 0.578, width * 0.14, height * 0.052, (184, 70, 44)),
    ):
        pts = [(cx - pw * 0.54, cy), (cx + pw * 0.48, cy - ph * 0.14), (cx + pw * 0.58, cy + ph * 0.52), (cx - pw * 0.46, cy + ph * 0.62)]
        draw.polygon(polygon(pts), fill=rgba(color[0], color[1], color[2], 88), outline=rgba(255, 228, 154, 98))
        draw.line([xy(cx - pw * 0.36, cy + ph * 0.50), xy(cx + pw * 0.42, cy + ph * 0.42)], fill=rgba(35, 22, 14, 86), width=2)

    for lane in range(7):
        t = (lane + 0.45) / 7.0
        y = height * (0.555 + t * 0.34)
        draw.ellipse(box(width * 0.08, y - height * 0.014, width * 0.92, y + height * 0.022), fill=rgba(255, 232, 170, 12 + lane * 4))
        draw.arc(box(width * 0.10, y - height * 0.044, width * 0.90, y + height * 0.040), 6, 176, fill=rgba(255, 220, 142, 24 + lane * 4), width=2)

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rectangle(box(0, height * 0.885, width, height), fill=rgba(18, 12, 8, 66))
    shadow_draw.rectangle(box(0, height * 0.458, width, height * 0.535), fill=rgba(248, 224, 176, 24))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow)
    return image


def draw_midground_layer(size: tuple[int, int] = SIZE) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle(box(0, height * 0.055, width, height * 0.510), fill=rgba(18, 12, 8, 14))
    _, shop_height = paste_scaled_fit(image, HIGH_SHOPFRONT, width, round(height * 0.040))
    draw = ImageDraw.Draw(image)

    fog = Image.new("RGBA", size, (0, 0, 0, 0))
    fog_draw = ImageDraw.Draw(fog)
    fog_draw.rectangle(box(0, height * 0.500, width, height * 0.600), fill=rgba(245, 224, 184, 24))
    fog_draw.ellipse(box(width * 0.15, height * 0.410, width * 0.86, height * 0.595), fill=rgba(250, 225, 178, 12))
    fog = fog.filter(ImageFilter.GaussianBlur(16))
    image.alpha_composite(fog)
    return image


def draw_foreground_layer(size: tuple[int, int] = SIZE) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    source = Image.open(HIGH_FOREGROUND).convert("RGBA")
    resized = source.resize((width, height), Image.Resampling.LANCZOS)
    image.alpha_composite(resized, (0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-foreground-v2-extra")
    draw.rectangle(box(0, height * 0.928, width, height), fill=rgba(18, 12, 8, 78))
    for _ in range(90):
        x = rng.uniform(width * 0.03, width * 0.97)
        y = rng.uniform(height * 0.845, height * 0.990)
        length = rng.uniform(height * 0.014, height * 0.050)
        draw.line([xy(x, y), xy(x + rng.uniform(-5, 7), y - length)], fill=rgba(74, 112, 48, rng.randint(36, 86)), width=1)
    for x, y, w, h, accent in (
        (width * 0.060, height * 0.805, width * 0.112, height * 0.080, (178, 72, 46)),
        (width * 0.805, height * 0.802, width * 0.128, height * 0.092, (68, 130, 140)),
    ):
        draw.rectangle(box(x, y, x + w, y + h), fill=rgba(24, 16, 11, 104), outline=rgba(94, 56, 32, 88), width=2)
        for item in range(4):
            cx = x + w * (0.16 + item * 0.22)
            draw.ellipse(box(cx - w * 0.045, y - h * 0.10, cx + w * 0.045, y + h * 0.12), fill=rgba(accent[0], accent[1], accent[2], 68))

    mist = Image.new("RGBA", size, (0, 0, 0, 0))
    mist_draw = ImageDraw.Draw(mist)
    mist_draw.ellipse(box(-width * 0.18, height * 0.80, width * 0.32, height * 1.06), fill=rgba(238, 226, 206, 32))
    mist_draw.ellipse(box(width * 0.70, height * 0.80, width * 1.14, height * 1.05), fill=rgba(232, 218, 196, 28))
    mist_draw.rectangle(box(0, 0, width, height * 0.056), fill=rgba(8, 4, 2, 52))
    mist = mist.filter(ImageFilter.GaussianBlur(22))
    image.alpha_composite(mist)
    return image


def draw_scene(size: tuple[int, int] = SIZE) -> Image.Image:
    width, height = size
    image = vertical_gradient(size, (132, 154, 142), (112, 92, 66))
    draw = ImageDraw.Draw(image)
    draw_far_environment(draw, width, height)
    sky_haze = Image.new("RGBA", size, (0, 0, 0, 0))
    haze_draw = ImageDraw.Draw(sky_haze)
    haze_draw.rectangle(box(0, height * 0.285, width, height * 0.500), fill=rgba(236, 220, 184, 34))
    sky_haze = sky_haze.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(sky_haze)
    image.alpha_composite(draw_floor_layer(size))
    image.alpha_composite(draw_midground_layer(size))
    image.alpha_composite(draw_foreground_layer(size))
    add_painterly_grain(image, "qinghe-scene-v2-grain", 6, 220)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.rectangle(box(0, 0, width, height * 0.070), fill=rgba(0, 0, 0, 36))
    vignette_draw.rectangle(box(0, height * 0.905, width, height), fill=rgba(0, 0, 0, 58))
    vignette_draw.rectangle(box(0, 0, width * 0.070, height), fill=rgba(0, 0, 0, 32))
    vignette_draw.rectangle(box(width * 0.930, 0, width, height), fill=rgba(0, 0, 0, 32))
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(vignette)
    return image.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def main() -> int:
    save(draw_scene(SIZE), SCENE_PATH)
    save(draw_floor_layer(SIZE), FLOOR_PATH)
    save(draw_midground_layer(SIZE), MIDGROUND_PATH)
    save(draw_foreground_layer(SIZE), FOREGROUND_PATH)
    print(f"OK generated Qinghe DNF town v2 assets size={SIZE}")
    print(SCENE_PATH)
    print(FLOOR_PATH)
    print(MIDGROUND_PATH)
    print(FOREGROUND_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
