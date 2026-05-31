#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROP_DIR = ROOT / "godot_project" / "assets" / "world" / "props"
PREVIEW_DIR = ROOT / "godot_project" / "assets" / "previews"
SIZE = 128
WORK = 256
SCALE = WORK / SIZE


def rgba(rgb: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return (rgb[0], rgb[1], rgb[2], alpha)


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


def line(draw: ImageDraw.ImageDraw, points, fill, width: float = 1.0) -> None:
    draw.line([xy(point) for point in points], fill=fill, width=max(1, round(width * SCALE)))


def poly(draw: ImageDraw.ImageDraw, points, fill, outline=None) -> None:
    draw.polygon([xy(point) for point in points], fill=fill, outline=outline)


def ellipse(draw: ImageDraw.ImageDraw, rect, fill, outline=None, width: float = 1.0) -> None:
    draw.ellipse(box(rect), fill=fill, outline=outline, width=max(1, round(width * SCALE)))


def rect(draw: ImageDraw.ImageDraw, bounds, fill, outline=None, width: float = 1.0) -> None:
    draw.rectangle(box(bounds), fill=fill, outline=outline, width=max(1, round(width * SCALE)))


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (WORK, WORK), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image, "RGBA")


def shadow(draw: ImageDraw.ImageDraw, center=(64, 111), radius=(42, 9), alpha: int = 44) -> None:
    ellipse(draw, (center[0] - radius[0], center[1] - radius[1], center[0] + radius[0], center[1] + radius[1]), rgba((0, 0, 0), alpha))


def roof(base=(92, 38, 20), light=(207, 109, 48), sign: bool = False) -> Image.Image:
    image, draw = canvas()
    shadow(draw, (66, 105), (48, 10), 36)
    poly(draw, [(13, 72), (64, 30), (115, 72), (104, 86), (24, 86)], rgba(base, 238))
    poly(draw, [(23, 73), (64, 38), (64, 84), (24, 86)], rgba(mix(base, light, 0.48), 210))
    poly(draw, [(64, 38), (105, 73), (104, 86), (64, 84)], rgba(mix(base, (55, 22, 12), 0.28), 222))
    line(draw, [(19, 79), (109, 79)], rgba((247, 185, 80), 114), 2.0)
    for x in range(28, 107, 16):
        line(draw, [(x, 66), (x - 11, 84)], rgba((58, 23, 14), 95), 1.4)
    if sign:
        rect(draw, (39, 86, 89, 101), rgba((55, 25, 12), 225))
        line(draw, [(45, 94), (83, 94)], rgba((231, 182, 82), 118), 1.4)
    return image


def tree(flower: bool = False) -> Image.Image:
    image, draw = canvas()
    shadow(draw, (67, 112), (34, 8), 42)
    line(draw, [(65, 110), (65, 55)], rgba((67, 36, 18), 232), 7.0)
    line(draw, [(65, 74), (41, 50)], rgba((67, 36, 18), 155), 3.0)
    line(draw, [(65, 68), (90, 43)], rgba((67, 36, 18), 150), 2.6)
    if flower:
        colors = [(148, 58, 78), (203, 101, 116), (232, 151, 155)]
    else:
        colors = [(20, 74, 34), (35, 111, 49), (55, 139, 63)]
    ellipse(draw, (18, 25, 69, 76), rgba(colors[0], 222))
    ellipse(draw, (50, 14, 108, 72), rgba(colors[1], 224))
    ellipse(draw, (35, 48, 100, 95), rgba(colors[2], 205))
    ellipse(draw, (21, 57, 58, 91), rgba(mix(colors[0], (0, 0, 0), 0.18), 188))
    line(draw, [(28, 69), (92, 55)], rgba((192, 212, 128), 50), 1.6)
    if flower:
        for i in range(11):
            x = 29 + (i * 13) % 61
            y = 34 + (i * 19) % 44
            ellipse(draw, (x - 2, y - 2, x + 2, y + 2), rgba((255, 218, 218), 115))
    return image


def bamboo() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 113), (36, 7), 36)
    for i, x in enumerate([34, 45, 56, 68, 80, 93]):
        sway = (i % 3 - 1) * 4
        line(draw, [(x, 112), (x + sway, 26)], rgba((25, 82, 27), 220), 2.6)
        for y in [42, 61, 80]:
            line(draw, [(x + sway * y / 112, y), (x + 17, y - 7)], rgba((91, 158, 67), 130), 2.0)
            line(draw, [(x + sway * y / 112, y + 4), (x - 15, y - 1)], rgba((63, 133, 55), 112), 1.6)
    return image


def ridge() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (65, 111), (49, 9), 46)
    poly(draw, [(11, 108), (41, 38), (63, 76), (89, 24), (119, 108)], rgba((55, 56, 51), 228))
    poly(draw, [(41, 38), (55, 87), (11, 108)], rgba((156, 151, 129), 132))
    poly(draw, [(89, 24), (98, 103), (63, 76)], rgba((173, 169, 145), 128))
    line(draw, [(41, 38), (119, 108)], rgba((25, 24, 22), 90), 2.0)
    line(draw, [(89, 24), (55, 107)], rgba((20, 19, 18), 74), 1.4)
    return image


def gate() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 112), (45, 8), 42)
    for x in [35, 93]:
        rect(draw, (x - 5, 62, x + 5, 114), rgba((74, 38, 18), 232))
        line(draw, [(x - 3, 64), (x - 3, 110)], rgba((173, 105, 48), 84), 1.2)
    poly(draw, [(20, 61), (64, 34), (108, 61), (99, 75), (29, 75)], rgba((102, 43, 22), 240))
    poly(draw, [(32, 62), (64, 43), (64, 74), (29, 75)], rgba((204, 127, 52), 138))
    line(draw, [(28, 74), (100, 74)], rgba((245, 190, 82), 105), 2.0)
    rect(draw, (45, 77, 83, 92), rgba((42, 20, 10), 220))
    line(draw, [(50, 85), (78, 85)], rgba((226, 178, 82), 95), 1.2)
    return image


def awning() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 112), (35, 7), 30)
    poly(draw, [(25, 64), (84, 48), (108, 62), (49, 80)], rgba((139, 51, 27), 235))
    for offset in [0, 14, 28, 42, 56]:
        line(draw, [(31 + offset, 63 - offset * 0.25), (45 + offset, 77 - offset * 0.25)], rgba((232, 143, 61), 125), 2.2)
    line(draw, [(49, 80), (49, 113)], rgba((68, 34, 17), 180), 2.0)
    line(draw, [(102, 63), (102, 110)], rgba((68, 34, 17), 180), 2.0)
    return image


def shelf() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 111), (42, 7), 32)
    rect(draw, (20, 48, 108, 102), rgba((76, 38, 18), 238))
    for y in [62, 78, 94]:
        line(draw, [(24, y), (104, y)], rgba((212, 146, 66), 110), 2.0)
    for x in range(31, 101, 14):
        ellipse(draw, (x - 3, 52, x + 3, 58), rgba((194, 147, 71), 130))
        ellipse(draw, (x - 2, 69, x + 2, 75), rgba((93, 132, 57), 120))
    return image


def lantern() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 113), (20, 5), 28)
    line(draw, [(54, 114), (54, 30)], rgba((60, 31, 14), 220), 3.0)
    line(draw, [(54, 40), (84, 34)], rgba((67, 34, 15), 210), 2.4)
    ellipse(draw, (76, 39, 101, 65), rgba((184, 45, 24), 238))
    ellipse(draw, (83, 44, 94, 60), rgba((255, 191, 74), 98))
    line(draw, [(89, 65), (89, 80)], rgba((235, 162, 66), 170), 1.5)
    return image


def market_stall() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (65, 112), (47, 9), 38)
    rect(draw, (28, 79, 99, 110), rgba((78, 39, 18), 235))
    poly(draw, [(20, 61), (44, 38), (95, 44), (111, 65), (96, 76), (28, 74)], rgba((136, 50, 27), 238))
    for x in [29, 45, 61, 77, 93]:
        line(draw, [(x, 54), (x + 8, 75)], rgba((230, 139, 56), 118), 2.0)
    for x in range(39, 88, 12):
        ellipse(draw, (x - 4, 87, x + 4, 95), rgba((205, 154, 63), 140))
    line(draw, [(29, 74), (29, 113)], rgba((62, 31, 14), 185), 2.2)
    line(draw, [(99, 74), (99, 113)], rgba((62, 31, 14), 185), 2.2)
    return image


def bridge_railing() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 107), (52, 6), 28)
    for y, alpha in [(67, 230), (88, 190)]:
        line(draw, [(13, y), (115, y - 9)], rgba((113, 67, 28), alpha), 4.0)
        line(draw, [(13, y + 5), (115, y - 4)], rgba((211, 149, 70), 92), 1.5)
    for x in range(19, 115, 19):
        line(draw, [(x, 54), (x, 101)], rgba((70, 35, 15), 210), 2.2)
    return image


def stone_lantern() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 113), (28, 6), 34)
    rect(draw, (55, 72, 73, 110), rgba((95, 92, 78), 235))
    rect(draw, (43, 58, 85, 73), rgba((78, 75, 66), 240))
    poly(draw, [(38, 58), (64, 39), (90, 58)], rgba((94, 91, 78), 240))
    rect(draw, (53, 74, 75, 87), rgba((68, 65, 57), 235))
    ellipse(draw, (59, 63, 69, 73), rgba((255, 190, 75), 85))
    return image


def well() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (65, 112), (36, 7), 36)
    ellipse(draw, (31, 75, 97, 109), rgba((80, 72, 60), 240))
    ellipse(draw, (42, 80, 86, 99), rgba((18, 31, 37), 235))
    line(draw, [(38, 79), (38, 39)], rgba((74, 39, 18), 225), 3.4)
    line(draw, [(90, 79), (90, 39)], rgba((74, 39, 18), 225), 3.4)
    line(draw, [(34, 39), (94, 39)], rgba((82, 43, 20), 230), 3.2)
    poly(draw, [(35, 39), (64, 23), (93, 39), (86, 48), (42, 48)], rgba((122, 65, 28), 225))
    return image


def boat() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 107), (46, 7), 24)
    poly(draw, [(17, 82), (34, 105), (92, 105), (113, 81), (91, 70), (31, 71)], rgba((71, 37, 17), 238))
    poly(draw, [(31, 73), (64, 62), (93, 72), (83, 83), (39, 83)], rgba((141, 89, 41), 198))
    line(draw, [(39, 88), (90, 87)], rgba((222, 162, 84), 95), 2.0)
    line(draw, [(44, 76), (96, 49)], rgba((197, 167, 108), 115), 1.8)
    return image


def banner() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (59, 113), (21, 5), 28)
    line(draw, [(49, 114), (49, 25)], rgba((67, 34, 15), 225), 3.0)
    poly(draw, [(51, 29), (93, 39), (83, 77), (51, 69)], rgba((157, 31, 21), 240))
    poly(draw, [(53, 35), (83, 42), (77, 59), (53, 54)], rgba((222, 82, 38), 110))
    line(draw, [(55, 42), (82, 49)], rgba((248, 194, 83), 90), 1.5)
    return image


def rock_cluster() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (65, 113), (39, 7), 40)
    rocks = [(25, 104, 42, 68, 56), (46, 110, 66, 54, 87), (74, 106, 89, 72, 107)]
    for left, base_y, top_x, top_y, right in rocks:
        poly(draw, [(left, base_y), (top_x, top_y), (right, base_y)], rgba((70, 70, 64), 224))
        poly(draw, [(top_x, top_y), (top_x + 7, base_y - 8), (left, base_y)], rgba((151, 147, 126), 124))
        line(draw, [(top_x, top_y), (right, base_y)], rgba((26, 25, 23), 72), 1.5)
    return image


def shrine() -> Image.Image:
    image, draw = canvas()
    shadow(draw, (64, 113), (29, 6), 35)
    rect(draw, (45, 58, 83, 111), rgba((80, 76, 66), 236))
    rect(draw, (38, 48, 90, 60), rgba((57, 53, 47), 240))
    poly(draw, [(36, 48), (64, 31), (92, 48)], rgba((102, 95, 78), 230))
    line(draw, [(53, 78), (75, 78)], rgba((218, 179, 91), 82), 1.4)
    line(draw, [(56, 91), (72, 91)], rgba((218, 179, 91), 60), 1.2)
    return image


def finish(image: Image.Image, path: Path) -> None:
    image = image.filter(ImageFilter.GaussianBlur(0.16 * SCALE))
    image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def generate() -> dict[str, Image.Image]:
    return {
        "roof": roof(),
        "shop_roof": roof((116, 45, 22), (223, 128, 49), True),
        "temple_roof": roof((122, 76, 29), (231, 179, 71), True),
        "tree": tree(False),
        "flower_tree": tree(True),
        "bamboo": bamboo(),
        "ridge": ridge(),
        "gate": gate(),
        "awning": awning(),
        "shelf": shelf(),
        "lantern": lantern(),
        "market_stall": market_stall(),
        "bridge_railing": bridge_railing(),
        "stone_lantern": stone_lantern(),
        "well": well(),
        "boat": boat(),
        "banner": banner(),
        "rock_cluster": rock_cluster(),
        "shrine": shrine(),
    }


def write_preview(paths: list[Path]) -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    columns = 5
    rows = math.ceil(len(paths) / columns)
    sheet = Image.new("RGBA", (columns * SIZE, rows * SIZE), rgba((31, 29, 24)))
    for index, path in enumerate(paths):
        tile = Image.open(path).convert("RGBA")
        x = (index % columns) * SIZE
        y = (index // columns) * SIZE
        sheet.alpha_composite(tile, (x, y))
    sheet.save(PREVIEW_DIR / "world_props_preview.png")


def main() -> None:
    paths: list[Path] = []
    for name, image in generate().items():
        path = PROP_DIR / f"prop_{name}.png"
        finish(image, path)
        paths.append(path)
    write_preview(paths)
    print("world_props=%d preview=%s" % (len(paths), PREVIEW_DIR / "world_props_preview.png"))


if __name__ == "__main__":
    main()
