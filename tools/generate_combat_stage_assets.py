#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
DATA = PROJECT / "data"
ASSET_ROOT = PROJECT / "assets" / "world" / "combat_stages"
MAPPING = DATA / "combat_stage_assets.json"

SIZE = (1280, 720)
SCALE = 2
W = SIZE[0] * SCALE
H = SIZE[1] * SCALE


def rgba(r: int, g: int, b: int, a: int = 255) -> tuple[int, int, int, int]:
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), max(0, min(255, a)))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return (
        round(a[0] + (b[0] - a[0]) * amount),
        round(a[1] + (b[1] - a[1]) * amount),
        round(a[2] + (b[2] - a[2]) * amount),
    )


def xy(x: float, y: float) -> tuple[int, int]:
    return (round(x * SCALE), round(y * SCALE))


def box(x0: float, y0: float, x1: float, y1: float) -> tuple[int, int, int, int]:
    return (round(x0 * SCALE), round(y0 * SCALE), round(x1 * SCALE), round(y1 * SCALE))


def polygon(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [xy(x, y) for x, y in points]


def new_image(fill: tuple[int, int, int, int] = (0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (W, H), fill)


def save_image(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = image.resize(SIZE, Image.Resampling.LANCZOS)
    image.save(path)


def res_path(path: Path) -> str:
    return "res://" + str(path.relative_to(PROJECT))


def draw_vertical_gradient(image: Image.Image, top: tuple[int, int, int], mid: tuple[int, int, int], bottom: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(image)
    for y in range(H):
        t = y / max(1, H - 1)
        if t < 0.58:
            c = mix(top, mid, t / 0.58)
        else:
            c = mix(mid, bottom, (t - 0.58) / 0.42)
        draw.line([(0, y), (W, y)], fill=rgba(c[0], c[1], c[2], 255))


def add_glow(base: Image.Image, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> None:
    glow = new_image()
    draw = ImageDraw.Draw(glow)
    cx, cy = center
    draw.ellipse(box(cx - radius, cy - radius, cx + radius, cy + radius), fill=rgba(color[0], color[1], color[2], alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(round(radius * SCALE * 0.42)))
    base.alpha_composite(glow)


def draw_roof(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, roof: tuple[int, int, int, int], ink: tuple[int, int, int, int]) -> None:
    draw.polygon(
        polygon([(x - w * 0.10, y + h * 0.52), (x + w * 0.50, y), (x + w * 1.10, y + h * 0.52), (x + w, y + h * 0.70), (x, y + h * 0.70)]),
        fill=roof,
    )
    draw.line([xy(x + 4, y + h * 0.66), xy(x + w - 4, y + h * 0.60)], fill=ink, width=max(1, round(3 * SCALE)))
    for i in range(6):
        tx = x + w * (0.10 + i * 0.16)
        draw.line([xy(tx, y + h * 0.22), xy(tx + w * 0.10, y + h * 0.62)], fill=rgba(238, 168, 84, 56), width=max(1, round(1.2 * SCALE)))


def draw_backdrop() -> Image.Image:
    image = new_image()
    draw_vertical_gradient(image, (26, 38, 48), (98, 75, 47), (34, 24, 19))
    draw = ImageDraw.Draw(image)
    rng = random.Random("qinghe-combat-backdrop")

    add_glow(image, (900, 140), 135, (255, 184, 84), 60)
    add_glow(image, (190, 245), 95, (72, 140, 152), 42)

    for layer, alpha in enumerate((118, 98, 74)):
        base_y = 315 + layer * 38
        pts = [(0, 520)]
        for i in range(9):
            x = i * 160 - 60
            y = base_y - rng.randint(35, 118) - layer * 16
            pts.append((x, y))
        pts.extend([(1340, 520), (0, 520)])
        color = rgba(36 + layer * 12, 48 + layer * 9, 45 + layer * 6, alpha)
        draw.polygon(polygon(pts), fill=color)

    for x in range(-40, 1340, 170):
        height = rng.randint(56, 112)
        y = 326 - rng.randint(0, 30)
        body = rgba(45, 31, 23, 125)
        roof = rgba(90, 45, 24, 155)
        draw.rectangle(box(x + 20, y, x + 108, y + height), fill=body)
        draw_roof(draw, x, y - 38, 130, 70, roof, rgba(18, 12, 8, 130))
        for wx in range(2):
            draw.rectangle(box(x + 40 + wx * 34, y + 22, x + 52 + wx * 34, y + 38), fill=rgba(255, 166, 74, 42))

    for y, alpha in ((210, 36), (275, 44), (348, 34), (424, 30)):
        fog = new_image()
        fd = ImageDraw.Draw(fog)
        fd.rectangle(box(0, y - 10, 1280, y + 26), fill=rgba(225, 205, 165, alpha))
        fog = fog.filter(ImageFilter.GaussianBlur(18 * SCALE))
        image.alpha_composite(fog)

    vignette = new_image()
    vd = ImageDraw.Draw(vignette)
    vd.rectangle(box(0, 0, 1280, 720), outline=rgba(0, 0, 0, 190), width=round(38 * SCALE))
    vignette = vignette.filter(ImageFilter.GaussianBlur(28 * SCALE))
    image.alpha_composite(vignette)
    return image


def draw_midground() -> Image.Image:
    image = new_image()
    draw = ImageDraw.Draw(image)
    ink = rgba(20, 12, 8, 205)
    beam = rgba(64, 37, 22, 210)
    wall = rgba(103, 70, 42, 178)
    roof = rgba(126, 56, 28, 218)

    structures = [(-70, 272, 310, 172), (210, 248, 285, 145), (775, 256, 330, 158), (1060, 286, 270, 140)]
    for x, y, w, h in structures:
        draw.rectangle(box(x + 26, y + 46, x + w - 22, y + h), fill=wall, outline=ink, width=round(2 * SCALE))
        draw_roof(draw, x, y, w, 92, roof, ink)
        for col in range(4):
            cx = x + 52 + col * (w - 106) / 3
            draw.rectangle(box(cx - 7, y + 58, cx + 7, y + h), fill=beam)
        for col in range(3):
            wx = x + 70 + col * (w - 140) / 2
            draw.rectangle(box(wx, y + 78, wx + 38, y + 110), fill=rgba(230, 148, 70, 48), outline=rgba(35, 18, 10, 115), width=round(1 * SCALE))

    for x, y in ((94, 380), (343, 348), (835, 360), (1150, 396)):
        add_glow(image, (x, y), 38, (255, 124, 36), 72)
        draw.ellipse(box(x - 15, y - 12, x + 15, y + 16), fill=rgba(196, 42, 25, 180), outline=rgba(255, 194, 92, 135), width=round(1.4 * SCALE))
        draw.line([xy(x, y - 34), xy(x, y - 12)], fill=rgba(38, 20, 11, 170), width=round(2 * SCALE))

    for x in (420, 552, 682):
        draw.rectangle(box(x, 326, x + 72, 354), fill=rgba(74, 36, 18, 175), outline=rgba(219, 150, 70, 105), width=round(1 * SCALE))
        draw.line([xy(x + 10, 344), xy(x + 62, 338)], fill=rgba(250, 192, 96, 80), width=round(1 * SCALE))

    return image


def draw_floor() -> Image.Image:
    image = new_image()
    draw = ImageDraw.Draw(image)
    ground = rgba(93, 70, 49, 235)
    near = rgba(42, 27, 21, 228)
    draw.polygon(polygon([(74, 418), (1206, 407), (1320, 735), (-40, 735)]), fill=ground)
    draw.polygon(polygon([(0, 624), (1280, 604), (1280, 720), (0, 720)]), fill=near)

    for i in range(9):
        t = i / 8
        y = 426 + t * 252
        alpha = round(92 - t * 32)
        draw.line([xy(82 - t * 116, y), xy(1198 + t * 122, y - 18)], fill=rgba(17, 11, 8, alpha), width=round((1.5 + t * 2.6) * SCALE))
    for i in range(15):
        t = i / 14
        x0 = 96 + t * 1084
        draw.line([xy(x0, 417), xy(x0 + (t - 0.5) * 250, 720)], fill=rgba(18, 12, 9, 48), width=round(1.6 * SCALE))

    rng = random.Random("qinghe-combat-floor")
    for _ in range(70):
        x = rng.randint(40, 1230)
        y = rng.randint(438, 696)
        length = rng.randint(14, 64)
        angle = rng.uniform(-0.22, 0.22)
        draw.line([xy(x, y), xy(x + math.cos(angle) * length, y + math.sin(angle) * length * 0.35)], fill=rgba(10, 7, 5, rng.randint(28, 76)), width=round(rng.uniform(0.7, 1.8) * SCALE))
    for x, y, w in ((300, 604, 185), (710, 574, 260), (990, 660, 170)):
        draw.ellipse(box(x, y, x + w, y + 18), fill=rgba(206, 168, 92, 24))
        draw.arc(box(x, y - 16, x + w, y + 24), 8, 176, fill=rgba(255, 218, 122, 44), width=round(1.3 * SCALE))
    return image


def draw_foreground() -> Image.Image:
    image = new_image()
    draw = ImageDraw.Draw(image)
    ink = rgba(12, 7, 5, 210)
    wood = rgba(44, 24, 14, 220)

    draw.rectangle(box(0, 0, 1280, 34), fill=rgba(18, 10, 7, 235))
    for x in range(-30, 1320, 150):
        draw.polygon(polygon([(x, 0), (x + 120, 0), (x + 98, 76), (x + 18, 72)]), fill=rgba(42, 20, 12, 198))
        draw.line([xy(x + 10, 68), xy(x + 105, 74)], fill=rgba(206, 126, 56, 70), width=round(1.4 * SCALE))

    for x in (34, 1234):
        draw.line([xy(x, 38), xy(x - 18 if x > 640 else x + 18, 710)], fill=wood, width=round(10 * SCALE))
        draw.line([xy(x + (12 if x < 640 else -12), 170), xy(x + (42 if x < 640 else -42), 690)], fill=rgba(236, 160, 74, 52), width=round(2 * SCALE))

    for x, y, s in ((106, 646, 1.0), (1184, 620, 1.2), (1018, 676, 0.9)):
        draw.rectangle(box(x - 36 * s, y - 30 * s, x + 38 * s, y + 16 * s), fill=rgba(40, 22, 12, 190), outline=ink, width=round(1.6 * SCALE))
        draw.line([xy(x - 30 * s, y - 7 * s), xy(x + 32 * s, y - 13 * s)], fill=rgba(214, 142, 70, 80), width=round(1.3 * SCALE))
    for x, y in ((238, 96), (1005, 112)):
        add_glow(image, (x, y), 60, (255, 128, 44), 55)
        draw.ellipse(box(x - 18, y - 14, x + 18, y + 20), fill=rgba(176, 35, 22, 185), outline=rgba(255, 188, 92, 120), width=round(1.4 * SCALE))
        draw.line([xy(x, 34), xy(x, y - 14)], fill=rgba(26, 14, 9, 160), width=round(2 * SCALE))

    fog = new_image()
    fd = ImageDraw.Draw(fog)
    fd.rectangle(box(0, 640, 1280, 720), fill=rgba(220, 186, 130, 38))
    fog = fog.filter(ImageFilter.GaussianBlur(22 * SCALE))
    image.alpha_composite(fog)
    return image


def generate_qinghe() -> dict[str, str]:
    out_dir = ASSET_ROOT / "qinghe"
    outputs = {
        "backdrop": out_dir / "qinghe_combat_backdrop_v1.png",
        "midground": out_dir / "qinghe_combat_midground_v1.png",
        "floor": out_dir / "qinghe_combat_floor_v1.png",
        "foreground": out_dir / "qinghe_combat_foreground_v1.png",
    }
    save_image(draw_backdrop(), outputs["backdrop"])
    save_image(draw_midground(), outputs["midground"])
    save_image(draw_floor(), outputs["floor"])
    save_image(draw_foreground(), outputs["foreground"])
    return {layer: res_path(path) for layer, path in outputs.items()}


def main() -> None:
    mapping = {"qinghe": generate_qinghe()}
    MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Generated combat stage assets: qinghe layers=4")


if __name__ == "__main__":
    main()
