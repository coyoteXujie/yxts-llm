#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from enum import IntEnum
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "godot_project" / "assets" / "world" / "backdrops"
OUT_PATH = OUT_DIR / "world_map_painted_v1.png"

MAP_WIDTH = 96
MAP_HEIGHT = 72
TEXTURE_TILE_SIZE = 32
WIDTH = MAP_WIDTH * TEXTURE_TILE_SIZE
HEIGHT = MAP_HEIGHT * TEXTURE_TILE_SIZE


class Tile(IntEnum):
    GRASS = 0
    ROAD = 1
    WATER = 2
    BUILDING = 3
    FOREST = 4
    COURTYARD = 5
    SECT = 6
    SNOW = 7
    BRIDGE = 8
    FIELD = 9
    MOUNTAIN = 10
    CITY = 11
    TOWN = 12
    VILLAGE = 13
    SHOP = 14
    TEMPLE = 15
    MARSH = 16
    DESERT = 17
    BAMBOO = 18
    CLIFF = 19


CITY_RECTS = [
    (35, 20, 18, 10, "city"),
    (12, 31, 17, 10, "city"),
    (14, 55, 18, 10, "city"),
    (58, 40, 17, 10, "city"),
    (73, 55, 18, 10, "city"),
]
TOWN_RECTS = [
    (26, 13, 9, 7), (51, 18, 7, 5), (57, 14, 7, 5), (72, 10, 7, 5),
    (6, 31, 6, 5), (18, 26, 7, 5), (30, 34, 7, 5), (8, 45, 7, 5),
    (70, 52, 6, 5), (84, 54, 7, 5), (79, 47, 7, 5), (12, 51, 6, 5),
    (34, 55, 7, 5), (34, 63, 7, 5), (78, 47, 7, 5), (50, 42, 7, 5),
]
VILLAGE_RECTS = [(38, 44, 8, 5), (6, 25, 8, 5), (50, 58, 7, 5), (83, 29, 7, 5)]
SECT_RECTS = [
    (20, 8, 8, 6, "bagua"),
    (44, 7, 9, 6, "xueshan"),
    (36, 34, 8, 6, "honglian"),
    (63, 32, 8, 6, "taiji"),
    (77, 34, 8, 6, "naja"),
    (84, 47, 8, 6, "flower"),
    (80, 61, 8, 5, "xiaoyao"),
]
RIVER_LINES = [
    [(-2, 16), (16, 15), (36, 17), (60, 15), (98, 13)],
    [(35, 21), (43, 23), (53, 22), (61, 24)],
    [(47, 49), (61, 48), (76, 50), (98, 52)],
    [(20, 51), (19, 58), (21, 71)],
    [(66, 36), (68, 43), (73, 50)],
]
ROAD_LINES = [
    [(43, 25), (34, 22), (30, 17), (24, 12)],
    [(43, 25), (30, 29), (21, 36)],
    [(20, 36), (20, 47), (23, 58)],
    [(44, 25), (55, 31), (66, 45)],
    [(66, 45), (74, 51), (82, 60)],
    [(53, 25), (65, 35), (80, 37)],
    [(23, 58), (40, 58), (65, 45)],
    [(43, 25), (57, 16), (78, 14), (94, 12)],
    [(37, 37), (43, 37), (50, 34)],
    [(66, 35), (66, 45)],
    [(82, 60), (88, 50)],
    [(20, 36), (11, 47)],
]
BRIDGES = [(30, 16), (57, 15), (53, 22), (66, 42), (75, 50), (82, 59), (20, 58)]


def tile_seed(x: int, y: int) -> int:
    return abs((x * 928371 + y * 689287 + x * y * 37) % 9973)


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        round(a[0] + (b[0] - a[0]) * t),
        round(a[1] + (b[1] - a[1]) * t),
        round(a[2] + (b[2] - a[2]) * t),
    )


def px(point: tuple[float, float]) -> tuple[float, float]:
    return (
        point[0] * TEXTURE_TILE_SIZE + TEXTURE_TILE_SIZE * 0.5,
        point[1] * TEXTURE_TILE_SIZE + TEXTURE_TILE_SIZE * 0.5,
    )


def tile_box(rect: tuple[float, float, float, float], inset: float = 0.0) -> tuple[float, float, float, float]:
    x, y, w, h = rect
    return (
        x * TEXTURE_TILE_SIZE + inset,
        y * TEXTURE_TILE_SIZE + inset,
        (x + w) * TEXTURE_TILE_SIZE - inset,
        (y + h) * TEXTURE_TILE_SIZE - inset,
    )


class WorldTiles:
    def __init__(self) -> None:
        self.tiles = [[Tile.GRASS for _ in range(MAP_WIDTH)] for _ in range(MAP_HEIGHT)]

    def set_tile(self, x: int, y: int, tile_id: Tile) -> None:
        if 0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT:
            self.tiles[y][x] = tile_id

    def get_tile(self, x: int, y: int) -> Tile:
        if 0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT:
            return self.tiles[y][x]
        return Tile.GRASS

    def fill_rect(self, rect: tuple[int, int, int, int], tile_id: Tile) -> None:
        x, y, w, h = rect
        for ty in range(y, y + h):
            for tx in range(x, x + w):
                self.set_tile(tx, ty, tile_id)

    def rough_fill_rect(self, rect: tuple[int, int, int, int], tile_id: Tile, edge_width: int = 2) -> None:
        x, y, w, h = rect
        for ty in range(y, y + h):
            for tx in range(x, x + w):
                edge_distance = min(min(tx - x, x + w - 1 - tx), min(ty - y, y + h - 1 - ty))
                if edge_distance < edge_width and tile_seed(tx, ty) % 4 == 0:
                    continue
                self.set_tile(tx, ty, tile_id)

    def paint_line(self, points: list[tuple[int, int]], tile_id: Tile, radius: int = 0, preserve_water: bool = False) -> None:
        for index in range(len(points) - 1):
            start = points[index]
            end = points[index + 1]
            steps = int(max(abs(end[0] - start[0]), abs(end[1] - start[1])) * 3.0) + 1
            for step in range(steps + 1):
                t = step / max(steps, 1)
                point = (start[0] + (end[0] - start[0]) * t, start[1] + (end[1] - start[1]) * t)
                for ox in range(-radius, radius + 1):
                    for oy in range(-radius, radius + 1):
                        tx = round(point[0]) + ox
                        ty = round(point[1]) + oy
                        if preserve_water and self.get_tile(tx, ty) == Tile.WATER:
                            self.set_tile(tx, ty, Tile.WATER)
                        elif tile_id == Tile.ROAD and self.get_tile(tx, ty) == Tile.WATER:
                            self.set_tile(tx, ty, Tile.BRIDGE)
                        else:
                            self.set_tile(tx, ty, tile_id)

    def paint_mountain_biome(self, rect: tuple[int, int, int, int], base_tile: Tile, obstacle_tile: Tile, density: int) -> None:
        self.rough_fill_rect(rect, base_tile)
        x, y, w, h = rect
        for ty in range(y, y + h):
            for tx in range(x, x + w):
                seed = tile_seed(tx, ty)
                ridge_band = abs((ty - y) * 3 - (tx - x)) % 13 == 0
                if seed % density == 0 or (ridge_band and seed % 3 == 0):
                    self.set_tile(tx, ty, obstacle_tile)
                    if seed % 5 == 0:
                        self.set_tile(tx + 1, ty, obstacle_tile)

    def generate(self) -> None:
        self.paint_mountain_biome((0, 0, 96, 8), Tile.GRASS, Tile.MOUNTAIN, 9)
        self.rough_fill_rect((0, 8, 15, 10), Tile.FOREST)
        self.paint_mountain_biome((38, 5, 20, 12), Tile.SNOW, Tile.MOUNTAIN, 7)
        self.paint_mountain_biome((30, 31, 30, 6), Tile.GRASS, Tile.MOUNTAIN, 8)
        self.rough_fill_rect((6, 39, 18, 11), Tile.DESERT)
        self.rough_fill_rect((4, 55, 22, 17), Tile.BAMBOO)
        self.rough_fill_rect((24, 54, 15, 14), Tile.FIELD)
        self.rough_fill_rect((56, 31, 18, 9), Tile.FOREST)
        self.rough_fill_rect((68, 38, 18, 13), Tile.MARSH)
        self.rough_fill_rect((80, 42, 16, 12), Tile.FOREST)
        self.rough_fill_rect((73, 55, 22, 15), Tile.MARSH)
        self.paint_mountain_biome((47, 9, 9, 7), Tile.GRASS, Tile.CLIFF, 5)
        self.rough_fill_rect((54, 58, 14, 9), Tile.FIELD)

        for line in RIVER_LINES:
            self.paint_line(line, Tile.WATER, 1 if line in (RIVER_LINES[0], RIVER_LINES[2]) else 0, True)
        self.fill_rect((77, 59, 13, 8), Tile.WATER)

        for rect in CITY_RECTS:
            self.paint_city(rect[:4], rect[4])
        for rect in TOWN_RECTS:
            self.paint_town(rect)
        for rect in VILLAGE_RECTS:
            self.paint_village(rect)
        for rect in SECT_RECTS:
            self.paint_sect(rect[:4], rect[4])
        for line in ROAD_LINES:
            self.paint_line(line, Tile.ROAD, 1)
        for x, y in BRIDGES:
            self.set_tile(x, y, Tile.BRIDGE)
            self.set_tile(x + 1, y, Tile.BRIDGE)

    def paint_city(self, rect: tuple[int, int, int, int], city_id: str) -> None:
        x, y, w, h = rect
        self.fill_rect(rect, Tile.CITY)
        self.paint_line([(x + 1, y + h // 2), (x + w - 2, y + h // 2)], Tile.ROAD, 1)
        self.paint_line([(x + w // 2, y + 1), (x + w // 2, y + h - 2)], Tile.ROAD, 1)
        market = Tile.MARSH if city_id == "linan" else Tile.FIELD if city_id == "chengdu" else Tile.SHOP
        for block in [(x + 2, y + 1, 3, 2), (x + w - 5, y + 1, 3, 2), (x + 2, y + h - 3, 3, 2), (x + w - 5, y + h - 3, 3, 2)]:
            self.fill_rect(block, Tile.BUILDING)
        self.fill_rect((x + w // 2 - 1, y + h // 2 - 1, 3, 3), market)
        if city_id == "luoyang":
            self.fill_rect((x + 12, y + 2, 3, 3), Tile.TEMPLE)

    def paint_town(self, rect: tuple[int, int, int, int]) -> None:
        x, y, w, h = rect
        self.fill_rect(rect, Tile.TOWN)
        self.paint_line([(x, y + h // 2), (x + w - 1, y + h // 2)], Tile.ROAD, 0)
        self.fill_rect((x + 1, y + 1, 2, 2), Tile.BUILDING)
        self.fill_rect((x + w - 3, y + 1, 2, 2), Tile.SHOP)

    def paint_village(self, rect: tuple[int, int, int, int]) -> None:
        x, y, w, h = rect
        self.fill_rect(rect, Tile.VILLAGE)
        self.paint_line([(x, y + h // 2), (x + w - 1, y + h // 2)], Tile.ROAD, 0)
        self.fill_rect((x + 1, y + 1, 2, 2), Tile.BUILDING)
        self.fill_rect((x + w - 3, y + h - 3, 2, 2), Tile.FIELD)

    def paint_sect(self, rect: tuple[int, int, int, int], sect_id: str) -> None:
        x, y, w, h = rect
        ground = Tile.SNOW if sect_id == "xueshan" else Tile.FOREST if sect_id == "flower" else Tile.MARSH if sect_id == "xiaoyao" else Tile.SECT
        self.fill_rect(rect, ground)
        self.paint_line([(x + w // 2, y), (x + w // 2, y + h - 1)], Tile.ROAD, 0)
        self.paint_line([(x + 1, y + h // 2), (x + w - 2, y + h // 2)], Tile.ROAD, 0)
        self.fill_rect((x + w // 2 - 1, y + 1, 3, 2), Tile.TEMPLE)


def make_gradient() -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), (42, 52, 36))
    pixels = image.load()
    for y in range(HEIGHT):
        v = y / max(1, HEIGHT - 1)
        base = mix((43, 58, 39), (80, 70, 45), v)
        for x in range(WIDTH):
            radial = math.hypot((x / WIDTH - 0.48) * 1.25, (y / HEIGHT - 0.46) * 1.1)
            warm = max(0.0, 1.0 - radial * 1.7)
            noise = ((x * 17 + y * 31 + (x // 23) * 9 + (y // 19) * 13) % 29) - 14
            tint = mix(base, (106, 83, 48), warm * 0.18)
            pixels[x, y] = (
                max(0, min(255, tint[0] + noise // 4)),
                max(0, min(255, tint[1] + noise // 5)),
                max(0, min(255, tint[2] + noise // 6)),
            )
    return image.convert("RGBA")


def terrain_mask(world: WorldTiles, tile_ids: set[Tile], expand: float, blur: float, alpha: int = 210) -> Image.Image:
    mask = Image.new("L", (WIDTH, HEIGHT), 0)
    draw = ImageDraw.Draw(mask)
    for y, row in enumerate(world.tiles):
        for x, tile_id in enumerate(row):
            if tile_id not in tile_ids:
                continue
            seed = tile_seed(x, y)
            jitter_x = ((seed * 19) % 17 - 8) * 0.12
            jitter_y = ((seed * 29) % 17 - 8) * 0.12
            cx = (x + 0.5 + jitter_x) * TEXTURE_TILE_SIZE
            cy = (y + 0.5 + jitter_y) * TEXTURE_TILE_SIZE
            rx = TEXTURE_TILE_SIZE * (0.72 + expand + (seed % 11) * 0.018)
            ry = TEXTURE_TILE_SIZE * (0.66 + expand + (seed % 7) * 0.02)
            draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=alpha)
    return mask.filter(ImageFilter.GaussianBlur(blur))


def paste_color(base: Image.Image, color: tuple[int, int, int, int], mask: Image.Image) -> None:
    layer = Image.new("RGBA", base.size, color)
    base.alpha_composite(Image.composite(layer, Image.new("RGBA", base.size, (0, 0, 0, 0)), mask))


def draw_lines_layer(
    base: Image.Image,
    lines: list[list[tuple[int, int]]],
    color: tuple[int, int, int, int],
    width: int,
    blur: float = 0.0,
    shadow: tuple[int, int, int, int] | None = None,
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for points in lines:
        coords = [px(point) for point in points]
        if shadow is not None:
            draw.line([(x + 0, y + TEXTURE_TILE_SIZE * 0.18) for x, y in coords], fill=shadow, width=width + 5, joint="curve")
        draw.line(coords, fill=color, width=width, joint="curve")
    if blur > 0.0:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def draw_settlement(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], kind: str, seed_base: int) -> None:
    x0, y0, x1, y1 = tile_box(rect, inset=TEXTURE_TILE_SIZE * 0.12)
    rng = random.Random(seed_base)
    if kind == "city":
        fill = (117, 78, 44, 154)
        outline = (220, 164, 82, 92)
        roof = (139, 55, 31, 198)
        count = 13
    elif kind == "sect":
        fill = (89, 88, 53, 150)
        outline = (223, 186, 88, 98)
        roof = (116, 68, 33, 190)
        count = 8
    elif kind == "town":
        fill = (114, 86, 52, 124)
        outline = (210, 165, 96, 76)
        roof = (132, 65, 34, 168)
        count = 5
    else:
        fill = (98, 89, 50, 110)
        outline = (185, 156, 85, 62)
        roof = (119, 71, 36, 150)
        count = 4
    draw.rounded_rectangle((x0, y0, x1, y1), radius=TEXTURE_TILE_SIZE * 0.75, fill=fill, outline=outline, width=max(2, TEXTURE_TILE_SIZE // 12))
    for _ in range(count):
        cx = rng.uniform(x0 + TEXTURE_TILE_SIZE * 0.7, x1 - TEXTURE_TILE_SIZE * 0.7)
        cy = rng.uniform(y0 + TEXTURE_TILE_SIZE * 0.65, y1 - TEXTURE_TILE_SIZE * 0.45)
        w = rng.uniform(TEXTURE_TILE_SIZE * 0.35, TEXTURE_TILE_SIZE * 0.95)
        h = rng.uniform(TEXTURE_TILE_SIZE * 0.18, TEXTURE_TILE_SIZE * 0.36)
        draw.polygon(
            [(cx - w, cy), (cx, cy - h), (cx + w, cy), (cx + w * 0.75, cy + h * 0.42), (cx - w * 0.75, cy + h * 0.42)],
            fill=roof,
        )
        draw.line((cx - w * 0.75, cy + h * 0.42, cx + w * 0.75, cy + h * 0.42), fill=(241, 184, 85, 68), width=1)


def draw_detail_strokes(base: Image.Image, world: WorldTiles) -> None:
    rng = random.Random(20260610)
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for _ in range(900):
        x = rng.randrange(WIDTH)
        y = rng.randrange(HEIGHT)
        angle = rng.uniform(0.0, math.tau)
        length = rng.uniform(TEXTURE_TILE_SIZE * 0.6, TEXTURE_TILE_SIZE * 2.8)
        alpha = rng.randrange(12, 34)
        draw.line(
            (x, y, x + math.cos(angle) * length, y + math.sin(angle) * length),
            fill=(30, 22, 14, alpha),
            width=rng.randrange(1, 3),
        )
    for y, row in enumerate(world.tiles):
        for x, tile_id in enumerate(row):
            seed = tile_seed(x, y)
            if tile_id in {Tile.FOREST, Tile.BAMBOO} and seed % 5 == 0:
                cx, cy = px((x, y))
                draw.ellipse((cx - 12, cy - 10, cx + 14, cy + 12), fill=(24, 68, 30, 84))
                draw.ellipse((cx - 2, cy - 18, cx + 20, cy + 4), fill=(47, 102, 42, 72))
            elif tile_id in {Tile.MOUNTAIN, Tile.CLIFF} and seed % 4 == 0:
                cx, cy = px((x, y))
                draw.polygon([(cx - 18, cy + 12), (cx - 5, cy - 17), (cx + 18, cy + 11)], fill=(42, 42, 36, 100))
                draw.line((cx - 5, cy - 17, cx + 7, cy + 10), fill=(156, 145, 111, 54), width=2)
            elif tile_id == Tile.MARSH and seed % 5 == 0:
                cx, cy = px((x, y))
                for offset in (-8, -2, 5, 11):
                    draw.line((cx + offset, cy + 14, cx + offset + (seed % 7 - 3), cy - 8), fill=(50, 92, 47, 82), width=1)
            elif tile_id == Tile.FIELD and seed % 4 == 0:
                cx, cy = px((x, y))
                draw.arc((cx - 18, cy - 10, cx + 18, cy + 16), 200, 340, fill=(205, 178, 83, 76), width=2)
            elif tile_id == Tile.WATER and seed % 7 == 0:
                cx, cy = px((x, y))
                draw.line((cx - 15, cy, cx + 14, cy - 3), fill=(185, 218, 214, 58), width=2)
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.35)))


def draw_lighting(base: Image.Image) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rectangle((0, 0, WIDTH, HEIGHT), outline=(248, 205, 112, 32), width=6)
    for index in range(5):
        y = HEIGHT * (0.11 + index * 0.13)
        draw.line((WIDTH * 0.10, y, WIDTH * 0.90, y + TEXTURE_TILE_SIZE * 1.3), fill=(255, 218, 139, 22), width=3)
    vignette = Image.new("L", base.size, 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-WIDTH * 0.18, -HEIGHT * 0.16, WIDTH * 1.18, HEIGHT * 1.13), fill=205)
    vignette = Image.eval(vignette.filter(ImageFilter.GaussianBlur(90)), lambda p: max(0, 210 - p))
    shadow = Image.new("RGBA", base.size, (12, 8, 5, 128))
    layer.alpha_composite(Image.composite(shadow, Image.new("RGBA", base.size, (0, 0, 0, 0)), vignette))
    base.alpha_composite(layer)


def render(world: WorldTiles) -> Image.Image:
    image = make_gradient()
    terrain_specs = [
        ({Tile.FIELD}, (105, 116, 57, 138), 0.55, 18.0),
        ({Tile.DESERT}, (163, 126, 70, 150), 0.70, 22.0),
        ({Tile.BAMBOO}, (50, 106, 50, 148), 0.72, 20.0),
        ({Tile.FOREST}, (36, 90, 42, 156), 0.75, 24.0),
        ({Tile.MARSH}, (47, 94, 69, 156), 0.76, 23.0),
        ({Tile.SNOW}, (181, 199, 205, 166), 0.60, 18.0),
        ({Tile.MOUNTAIN, Tile.CLIFF}, (72, 72, 61, 168), 0.55, 14.0),
    ]
    for ids, color, expand, blur in terrain_specs:
        paste_color(image, color, terrain_mask(world, ids, expand, blur))

    river_mask = Image.new("L", image.size, 0)
    river_draw = ImageDraw.Draw(river_mask)
    for points in RIVER_LINES:
        river_draw.line([px(point) for point in points], fill=230, width=TEXTURE_TILE_SIZE * 2, joint="curve")
    river_draw.rounded_rectangle(tile_box((77, 59, 13, 8)), radius=TEXTURE_TILE_SIZE * 2, fill=228)
    river_mask = river_mask.filter(ImageFilter.GaussianBlur(13.0))
    paste_color(image, (42, 91, 116, 205), river_mask)
    draw_lines_layer(image, RIVER_LINES, (104, 156, 176, 90), TEXTURE_TILE_SIZE, 4.0)

    road_shadow = (38, 26, 14, 72)
    draw_lines_layer(image, ROAD_LINES, (142, 111, 66, 190), TEXTURE_TILE_SIZE, 2.8, road_shadow)
    draw_lines_layer(image, ROAD_LINES, (212, 178, 104, 72), max(3, TEXTURE_TILE_SIZE // 6), 1.0)

    settlement_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    settlement_draw = ImageDraw.Draw(settlement_layer)
    for index, rect in enumerate(CITY_RECTS):
        draw_settlement(settlement_draw, rect[:4], "city", index + 900)
    for index, rect in enumerate(TOWN_RECTS):
        draw_settlement(settlement_draw, rect, "town", index + 1100)
    for index, rect in enumerate(VILLAGE_RECTS):
        draw_settlement(settlement_draw, rect, "village", index + 1300)
    for index, rect in enumerate(SECT_RECTS):
        draw_settlement(settlement_draw, rect[:4], "sect", index + 1500)
    image.alpha_composite(settlement_layer.filter(ImageFilter.GaussianBlur(0.4)))

    bridge_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    bridge_draw = ImageDraw.Draw(bridge_layer)
    for x, y in BRIDGES:
        cx, cy = px((x + 0.5, y))
        bridge_draw.rounded_rectangle((cx - 26, cy - 8, cx + 42, cy + 8), radius=4, fill=(120, 72, 30, 180))
        bridge_draw.line((cx - 24, cy - 6, cx + 40, cy - 6), fill=(236, 178, 92, 72), width=2)
    image.alpha_composite(bridge_layer)

    draw_detail_strokes(image, world)
    draw_lighting(image)
    return image.convert("RGB")


def main() -> None:
    world = WorldTiles()
    world.generate()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image = render(world)
    image.save(OUT_PATH, optimize=True)
    print(f"world_backdrop={OUT_PATH} size={image.size[0]}x{image.size[1]}")


if __name__ == "__main__":
    main()
