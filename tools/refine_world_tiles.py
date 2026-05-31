#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
TILE_DIR = ROOT / "godot_project" / "assets" / "world" / "tiles"
PREVIEW_DIR = ROOT / "godot_project" / "assets" / "previews"
SIZE = 96
WORK = 192
SCALE = WORK / SIZE
VARIANT_COUNT = 4


def rgba(rgb: tuple[int, int, int], a: int = 255) -> tuple[int, int, int, int]:
    return (rgb[0], rgb[1], rgb[2], a)


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(a[0] + (b[0] - a[0]) * t),
        int(a[1] + (b[1] - a[1]) * t),
        int(a[2] + (b[2] - a[2]) * t),
    )


def xy(point: tuple[float, float]) -> tuple[int, int]:
    return (round(point[0] * SCALE), round(point[1] * SCALE))


def box(rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return (
        round(rect[0] * SCALE),
        round(rect[1] * SCALE),
        round(rect[2] * SCALE),
        round(rect[3] * SCALE),
    )


def draw_line(draw: ImageDraw.ImageDraw, points, fill, width: float = 1.0) -> None:
    draw.line([xy(p) for p in points], fill=fill, width=max(1, round(width * SCALE)))


def draw_poly(draw: ImageDraw.ImageDraw, points, fill, outline=None) -> None:
    draw.polygon([xy(p) for p in points], fill=fill, outline=outline)


def draw_rect(draw: ImageDraw.ImageDraw, rect, fill, outline=None, width: float = 1.0) -> None:
    draw.rectangle(box(rect), fill=fill, outline=outline, width=max(1, round(width * SCALE)))


def draw_ellipse(draw: ImageDraw.ImageDraw, rect, fill, outline=None, width: float = 1.0) -> None:
    draw.ellipse(box(rect), fill=fill, outline=outline, width=max(1, round(width * SCALE)))


def base_canvas(name: str, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> tuple[Image.Image, ImageDraw.ImageDraw, random.Random]:
    image = Image.new("RGBA", (WORK, WORK), rgba(top))
    draw = ImageDraw.Draw(image, "RGBA")
    for y in range(WORK):
        t = y / max(1, WORK - 1)
        color = mix(top, bottom, t)
        draw.line([(0, y), (WORK, y)], fill=rgba(color))
    rng = random.Random(name)
    for _i in range(420):
        x = rng.randrange(WORK)
        y = rng.randrange(WORK)
        radius = rng.choice([1, 1, 2, 2, 3])
        alpha = rng.randrange(10, 28)
        tint = mix(top, (255, 255, 235), rng.random() * 0.18)
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=rgba(tint, alpha))
    return image, draw, rng


def finish(image: Image.Image, path: Path) -> None:
    base = image.copy()
    alpha = base.getchannel("A")
    if alpha.getextrema()[0] < 255:
        backdrop = Image.new("RGBA", base.size, tuple(base.getpixel((base.size[0] // 2, base.size[1] // 2))[:3]) + (255,))
        backdrop.alpha_composite(base)
        image = backdrop
    image.putalpha(255)
    image = image.filter(ImageFilter.GaussianBlur(0.18 * SCALE))
    image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def grass(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (67, 107, 57), (44, 84, 45))
    for _i in range(42):
        x = rng.uniform(4, 92)
        y = rng.uniform(10, 90)
        h = rng.uniform(5, 14)
        draw_line(draw, [(x, y), (x + rng.uniform(-2, 3), y - h)], rgba((122, 154, 76), rng.randrange(75, 128)), 1.1)
        if rng.random() < 0.35:
            draw_line(draw, [(x, y - h * 0.45), (x + rng.uniform(4, 8), y - h * 0.66)], rgba((84, 132, 64), 70), 1.0)
    for _i in range(10):
        x = rng.uniform(8, 88)
        y = rng.uniform(12, 84)
        draw_ellipse(draw, (x - 1.5, y - 1.2, x + 1.5, y + 1.2), rgba((218, 177, 91), 70))
    return image


def road(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (142, 120, 82), (103, 87, 63))
    for y in range(8, 96, 13):
        draw_line(draw, [(0, y + rng.uniform(-2, 2)), (96, y - 7 + rng.uniform(-2, 2))], rgba((201, 177, 123), 55), 1.3)
    for _i in range(34):
        x = rng.uniform(3, 92)
        y = rng.uniform(4, 92)
        w = rng.uniform(4, 10)
        h = rng.uniform(2, 5)
        color = rgba(mix((88, 70, 47), (190, 164, 112), rng.random() * 0.55), rng.randrange(50, 100))
        draw_ellipse(draw, (x - w, y - h, x + w, y + h), color, rgba((70, 52, 34), 35), 0.7)
    return image


def water(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (34, 93, 122), (19, 56, 83))
    for y in range(10, 95, 12):
        phase = rng.uniform(-5, 5)
        points = []
        for x in range(-8, 108, 8):
            points.append((x, y + math.sin((x + phase) / 13.0) * 3.0))
        draw_line(draw, points, rgba((157, 205, 214), 70), 1.6)
        draw_line(draw, [(px, py + 5) for px, py in points], rgba((8, 37, 58), 45), 1.1)
    for _i in range(10):
        x = rng.uniform(8, 88)
        y = rng.uniform(8, 88)
        draw_ellipse(draw, (x - 6, y - 2, x + 6, y + 2), rgba((206, 232, 224), 35))
    return image


def building(name: str, roof: tuple[int, int, int], wall: tuple[int, int, int]) -> Image.Image:
    image, draw, rng = base_canvas(name, (84, 57, 38), (62, 42, 30))
    draw_rect(draw, (12, 35, 84, 88), rgba(wall, 210), rgba((52, 28, 17), 165), 1.4)
    draw_poly(draw, [(4, 37), (48, 10), (92, 37), (82, 48), (14, 48)], rgba(roof, 232))
    for x in range(16, 88, 12):
        draw_line(draw, [(x, 34), (x - 10, 48)], rgba(mix(roof, (240, 180, 96), 0.35), 120), 1.1)
    draw_line(draw, [(9, 44), (87, 44)], rgba((231, 169, 83), 100), 2.0)
    draw_rect(draw, (38, 58, 58, 88), rgba((31, 18, 11), 118), rgba((178, 124, 65), 75), 1.0)
    if "shop" in name:
        draw_rect(draw, (18, 51, 78, 60), rgba((219, 156, 67), 120))
        for x in range(24, 76, 13):
            draw_line(draw, [(x, 51), (x + 8, 60)], rgba((97, 39, 22), 95), 1.0)
    if "temple" in name or "sect" in name:
        draw_line(draw, [(18, 31), (48, 12), (78, 31)], rgba((247, 214, 109), 85), 1.4)
    if rng.random() < 0.7:
        draw_ellipse(draw, (76, 54, 85, 66), rgba((239, 92, 43), 95))
    return image


def forest(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (39, 82, 43), (22, 57, 35))
    for _i in range(12):
        cx = rng.uniform(8, 88)
        cy = rng.uniform(10, 78)
        r = rng.uniform(9, 19)
        draw_ellipse(draw, (cx - r, cy - r * 0.75, cx + r, cy + r * 0.75), rgba((16, 55, 26), rng.randrange(120, 175)))
        draw_ellipse(draw, (cx - r * 0.65, cy - r * 1.0, cx + r * 0.7, cy + r * 0.6), rgba((35, 91, 41), rng.randrange(90, 145)))
    return image


def bamboo(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (59, 108, 54), (31, 76, 39))
    for i in range(13):
        x = rng.uniform(-4, 100)
        sway = rng.uniform(-5, 5)
        draw_line(draw, [(x, 96), (x + sway, 0)], rgba((22, 72, 25), 150), 2.0)
        for y in range(16, 90, 20):
            draw_line(draw, [(x + sway * y / 96, y), (x + 15, y - 7)], rgba((88, 148, 65), 90), 1.6)
            draw_line(draw, [(x + sway * y / 96, y + 4), (x - 13, y)], rgba((64, 128, 56), 75), 1.3)
    return image


def field(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (108, 130, 55), (68, 94, 43))
    for y in range(8, 98, 10):
        draw_line(draw, [(0, y), (96, y - 14)], rgba((184, 178, 76), 120), 1.8)
        draw_line(draw, [(0, y + 4), (96, y - 10)], rgba((37, 67, 29), 58), 1.0)
    for _i in range(24):
        x = rng.uniform(4, 92)
        y = rng.uniform(4, 92)
        draw_line(draw, [(x, y), (x + rng.uniform(-3, 3), y - rng.uniform(6, 13))], rgba((198, 184, 76), 80), 1.0)
    return image


def mountain(name: str, cliff: bool = False) -> Image.Image:
    top = (106, 111, 99) if not cliff else (103, 103, 99)
    bottom = (61, 66, 59) if not cliff else (67, 66, 63)
    image, draw, rng = base_canvas(name, top, bottom)
    peaks = [(-10, 88, 32, 19, 72), (21, 90, 50, 11, 85), (49, 90, 106, 23, 76)]
    for left, base_y, right, top_x, top_y in peaks:
        shade = (54, 56, 52) if not cliff else (47, 48, 48)
        hi = (163, 160, 137) if not cliff else (144, 143, 131)
        draw_poly(draw, [(left, base_y), (top_x, top_y), (right, base_y)], rgba(shade, 205))
        draw_poly(draw, [(top_x, top_y), (top_x + 7, top_y + 24), (top_x - 8, top_y + 25)], rgba(hi, 110))
        draw_line(draw, [(top_x, top_y), (right - 6, base_y)], rgba((25, 25, 22), 70), 1.4)
    for _i in range(11):
        x = rng.uniform(5, 90)
        y = rng.uniform(15, 88)
        draw_line(draw, [(x, y), (x + rng.uniform(9, 18), y + rng.uniform(8, 20))], rgba((25, 24, 22), 40), 1.0)
    return image


def snow(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (185, 204, 213), (134, 158, 171))
    for _i in range(22):
        x = rng.uniform(4, 92)
        y = rng.uniform(5, 90)
        draw_ellipse(draw, (x - 2, y - 1.4, x + 2, y + 1.4), rgba((255, 255, 255), rng.randrange(70, 140)))
    draw_line(draw, [(8, 25), (42, 55), (88, 32)], rgba((255, 255, 255), 72), 1.5)
    draw_line(draw, [(0, 75), (96, 58)], rgba((83, 110, 130), 36), 1.0)
    return image


def bridge(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (112, 73, 37), (74, 43, 22))
    draw_rect(draw, (5, 25, 91, 70), rgba((100, 58, 27), 210), rgba((45, 23, 12), 150), 1.3)
    for x in range(10, 92, 12):
        draw_line(draw, [(x, 19), (x - 5, 78)], rgba((44, 22, 10), 115), 1.4)
    for y in (31, 57):
        draw_line(draw, [(6, y), (90, y - 3)], rgba((207, 150, 75), 120), 2.0)
    for _i in range(16):
        x = rng.uniform(9, 88)
        y = rng.uniform(29, 66)
        draw_ellipse(draw, (x - 2, y - 1, x + 2, y + 1), rgba((41, 22, 11), 60))
    return image


def desert(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (166, 137, 87), (116, 91, 58))
    for y in range(14, 94, 12):
        points = [(x, y + math.sin((x + rng.random() * 20) / 18.0) * 4) for x in range(-4, 104, 8)]
        draw_line(draw, points, rgba((216, 184, 118), 65), 1.3)
        draw_line(draw, [(px, py + 5) for px, py in points], rgba((86, 61, 36), 35), 1.0)
    return image


def marsh(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (49, 99, 86), (31, 70, 60))
    for _i in range(12):
        x = rng.uniform(5, 90)
        y = rng.uniform(5, 90)
        draw_ellipse(draw, (x - 13, y - 4, x + 13, y + 4), rgba((28, 80, 92), 70))
    for _i in range(34):
        x = rng.uniform(0, 96)
        y = rng.uniform(25, 95)
        draw_line(draw, [(x, y), (x + rng.uniform(-4, 4), y - rng.uniform(9, 21))], rgba((39, 78, 37), 95), 1.3)
    return image


def courtyard(name: str) -> Image.Image:
    image, draw, rng = base_canvas(name, (112, 98, 70), (77, 68, 51))
    for y in range(9, 96, 14):
        draw_line(draw, [(0, y), (96, y - 5)], rgba((178, 159, 112), 80), 1.1)
    for x in range(10, 96, 17):
        draw_line(draw, [(x, 0), (x - 8, 96)], rgba((45, 38, 28), 42), 0.9)
    for _i in range(12):
        x = rng.uniform(8, 88)
        y = rng.uniform(8, 88)
        draw_rect(draw, (x - 5, y - 2, x + 5, y + 2), rgba((53, 45, 34), 38))
    return image


def generate(seed_suffix: str = "") -> dict[str, Image.Image]:
	return {
		"grass": grass("grass" + seed_suffix),
		"road": road("road" + seed_suffix),
		"water": water("water" + seed_suffix),
		"building": building("building" + seed_suffix, (119, 59, 32), (84, 49, 31)),
		"forest": forest("forest" + seed_suffix),
		"courtyard": courtyard("courtyard" + seed_suffix),
		"sect": building("sect" + seed_suffix, (128, 91, 39), (75, 64, 45)),
		"snow": snow("snow" + seed_suffix),
		"bridge": bridge("bridge" + seed_suffix),
		"field": field("field" + seed_suffix),
		"mountain": mountain("mountain" + seed_suffix),
		"city": courtyard("city" + seed_suffix),
		"town": courtyard("town" + seed_suffix),
		"village": field("village" + seed_suffix),
		"shop": building("shop" + seed_suffix, (153, 73, 32), (99, 58, 33)),
		"temple": building("temple" + seed_suffix, (132, 88, 39), (76, 62, 46)),
		"marsh": marsh("marsh" + seed_suffix),
		"desert": desert("desert" + seed_suffix),
		"bamboo": bamboo("bamboo" + seed_suffix),
		"cliff": mountain("cliff" + seed_suffix, True),
	}


def write_preview(paths: list[Path]) -> None:
	PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
	columns = 8
	rows = math.ceil(len(paths) / columns)
	sheet = Image.new("RGBA", (columns * SIZE, rows * SIZE), rgba((25, 23, 19)))
	for index, path in enumerate(paths):
		tile = Image.open(path).convert("RGBA")
		sheet.alpha_composite(tile, ((index % columns) * SIZE, (index // columns) * SIZE))
	sheet.save(PREVIEW_DIR / "tiles_refined_preview.png")


def main() -> None:
	paths: list[Path] = []
	for variant in range(VARIANT_COUNT):
		seed_suffix = "" if variant == 0 else f"_v{variant}"
		for name, image in generate(seed_suffix).items():
			suffix = "" if variant == 0 else f"_v{variant}"
			path = TILE_DIR / f"tile_{name}{suffix}.png"
			finish(image, path)
			paths.append(path)
	write_preview(paths)
	print("refined_tiles=%d preview=%s" % (len(paths), PREVIEW_DIR / "tiles_refined_preview.png"))


if __name__ == "__main__":
    main()
