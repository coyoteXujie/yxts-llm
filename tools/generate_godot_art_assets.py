#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
import re
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "godot_project" / "data"
ASSETS = ROOT / "godot_project" / "assets"
TILE_DIR = ASSETS / "world" / "tiles"
SCENE_DIR = ASSETS / "world" / "scenes"
NPC_DIR = ASSETS / "characters" / "generated_map_sprites"
PORTRAIT_DIR = ASSETS / "characters" / "npc" / "portraits"
PLAYER_DIR = ASSETS / "characters" / "player"
PARTS_DIR = ASSETS / "characters" / "parts"
ITEM_ICON_DIR = ASSETS / "items" / "icons"
SKILL_ICON_DIR = ASSETS / "skills" / "icons"
UI_DIR = ASSETS / "ui"
PREVIEW_DIR = ASSETS / "previews"
MANIFEST = ASSETS / "generated_art_manifest.json"
NPC_SPRITE_MAPPING = DATA / "npc_sprite_assets.json"
NPC_PORTRAIT_MAPPING = DATA / "npc_portrait_assets.json"
ITEM_ICON_MAPPING = DATA / "item_icon_assets.json"
SKILL_ICON_MAPPING = DATA / "skill_icon_assets.json"
SCENE_BACKGROUND_MAPPING = DATA / "scene_background_assets.json"

SCALE = 3
TILE_SIZE = 48
CHAR_SIZE = (96, 128)


def color(rgb: tuple[float, float, float] | tuple[float, float, float, float], alpha: int | None = None) -> tuple[int, int, int, int]:
    values = list(rgb)
    if len(values) == 3:
        values.append(1.0)
    if alpha is not None:
        values[3] = alpha / 255.0
    return tuple(max(0, min(255, round(v * 255))) for v in values)  # type: ignore[return-value]


def lighten(c: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        round(c[0] + (255 - c[0]) * amount),
        round(c[1] + (255 - c[1]) * amount),
        round(c[2] + (255 - c[2]) * amount),
        c[3],
    )


def darken(c: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (round(c[0] * (1.0 - amount)), round(c[1] * (1.0 - amount)), round(c[2] * (1.0 - amount)), c[3])


def with_alpha(c: tuple[int, int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return (c[0], c[1], c[2], alpha)


class Painter:
    def __init__(self, image: Image.Image):
        self.image = image
        self.draw = ImageDraw.Draw(image)

    def xy(self, value: tuple[float, float]) -> tuple[int, int]:
        return (round(value[0] * SCALE), round(value[1] * SCALE))

    def box(self, value: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
        return tuple(round(v * SCALE) for v in value)  # type: ignore[return-value]

    def polygon(self, points: list[tuple[float, float]], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None) -> None:
        self.draw.polygon([self.xy(point) for point in points], fill=fill, outline=outline)

    def ellipse(self, bbox: tuple[float, float, float, float], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None, width: int = 1) -> None:
        self.draw.ellipse(self.box(bbox), fill=fill, outline=outline, width=max(1, width * SCALE))

    def rect(self, bbox: tuple[float, float, float, float], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None, width: int = 1) -> None:
        self.draw.rectangle(self.box(bbox), fill=fill, outline=outline, width=max(1, width * SCALE))

    def line(self, points: list[tuple[float, float]], fill: tuple[int, int, int, int], width: float = 1.0) -> None:
        self.draw.line([self.xy(point) for point in points], fill=fill, width=max(1, round(width * SCALE)))

    def arc(self, bbox: tuple[float, float, float, float], start: float, end: float, fill: tuple[int, int, int, int], width: float = 1.0) -> None:
        self.draw.arc(self.box(bbox), start=start, end=end, fill=fill, width=max(1, round(width * SCALE)))


def new_canvas(size: tuple[int, int], fill: tuple[int, int, int, int] = (0, 0, 0, 0)) -> tuple[Image.Image, Painter]:
    image = Image.new("RGBA", (size[0] * SCALE, size[1] * SCALE), fill)
    return image, Painter(image)


def save_canvas(image: Image.Image, path: Path, size: tuple[int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = image.resize(size, Image.Resampling.LANCZOS)
    image.save(path)


def noise_points(seed: str, count: int, size: int = TILE_SIZE) -> list[tuple[float, float, float]]:
    rng = random.Random(seed)
    return [(rng.uniform(0, size), rng.uniform(0, size), rng.uniform(0.6, 1.8)) for _ in range(count)]


def generate_tile(name: str, base: tuple[int, int, int, int], painter_func) -> Path:
    image, p = new_canvas((TILE_SIZE, TILE_SIZE), base)
    for x, y, radius in noise_points(name, 18):
        p.ellipse((x - radius, y - radius, x + radius, y + radius), with_alpha(lighten(base, 0.08), 28))
    painter_func(p)
    path = TILE_DIR / f"tile_{name}.png"
    save_canvas(image, path, (TILE_SIZE, TILE_SIZE))
    return path


def generate_tiles() -> dict[str, str]:
    def grass(p: Painter) -> None:
        for i in range(7):
            x = 6 + i * 7
            p.line([(x, 35), (x + 3, 27)], color((0.54, 0.65, 0.32), 95), 1.1)
        p.ellipse((29, 14, 34, 18), color((0.62, 0.70, 0.38), 65))

    def road(p: Painter) -> None:
        p.polygon([(0, 27), (48, 18), (48, 33), (0, 42)], color((0.68, 0.58, 0.40), 130))
        p.line([(0, 15), (48, 8)], color((0.34, 0.27, 0.18), 48), 1)
        for x, y, r in noise_points("road_stone", 7):
            p.ellipse((x - r, y - r, x + r, y + r), color((0.24, 0.19, 0.13), 70))

    def water(p: Painter) -> None:
        for y in (15, 27, 37):
            p.arc((5, y - 6, 27, y + 6), 190, 350, color((0.72, 0.88, 0.95), 90), 1.4)
            p.arc((23, y - 6, 45, y + 6), 190, 350, color((0.09, 0.20, 0.28), 55), 1.2)

    def building(p: Painter) -> None:
        p.rect((6, 14, 42, 41), color((0.38, 0.22, 0.14), 170), color((0.19, 0.10, 0.06), 180), 2)
        p.polygon([(4, 16), (24, 6), (44, 16), (39, 20), (9, 20)], color((0.25, 0.12, 0.08), 190))
        for x in (15, 25, 35):
            p.line([(x, 14), (x - 5, 20)], color((0.58, 0.32, 0.18), 120), 1)

    def forest(p: Painter) -> None:
        for cx, cy, r in [(18, 28, 12), (30, 22, 11), (24, 15, 9)]:
            p.ellipse((cx - r, cy - r, cx + r, cy + r), color((0.10, 0.27, 0.13), 190))
        p.line([(24, 26), (24, 42)], color((0.15, 0.09, 0.04), 150), 3)

    def courtyard(p: Painter) -> None:
        for y in range(8, 45, 11):
            p.line([(4, y), (44, y - 3)], color((0.64, 0.58, 0.42), 70), 1)
        p.rect((10, 10, 38, 38), color((0.20, 0.17, 0.12), 35), color((0.74, 0.64, 0.42), 80), 1)

    def sect(p: Painter) -> None:
        p.arc((8, 8, 40, 40), 0, 360, color((0.86, 0.70, 0.36), 110), 2)
        p.line([(24, 6), (24, 42)], color((0.82, 0.68, 0.36), 75), 1)
        p.line([(7, 24), (41, 24)], color((0.82, 0.68, 0.36), 75), 1)

    def snow(p: Painter) -> None:
        for x, y, r in noise_points("snow", 10):
            p.ellipse((x - r, y - r, x + r, y + r), color((1.0, 1.0, 1.0), 125))
        p.line([(8, 14), (38, 34)], color((1.0, 1.0, 1.0), 75), 1)

    def bridge(p: Painter) -> None:
        p.rect((5, 14, 43, 35), color((0.52, 0.31, 0.16), 170), color((0.22, 0.11, 0.05), 130), 1)
        for x in range(10, 42, 8):
            p.line([(x, 10), (x, 39)], color((0.24, 0.13, 0.06), 140), 1.2)
        p.line([(5, 20), (43, 20)], color((0.78, 0.56, 0.28), 110), 2)
        p.line([(5, 30), (43, 30)], color((0.78, 0.56, 0.28), 110), 2)

    def field(p: Painter) -> None:
        for y in (13, 24, 35):
            p.line([(3, y), (45, y - 7)], color((0.72, 0.72, 0.34), 110), 1.5)
        for x in (12, 26, 39):
            p.line([(x, 7), (x - 8, 43)], color((0.22, 0.27, 0.12), 60), 1)

    def mountain(p: Painter) -> None:
        p.polygon([(2, 43), (20, 9), (39, 43)], color((0.25, 0.25, 0.23), 185))
        p.polygon([(15, 24), (20, 9), (25, 25)], color((0.75, 0.74, 0.66), 110))
        p.line([(20, 9), (30, 43)], color((0.08, 0.08, 0.08), 70), 1.5)

    def city(p: Painter) -> None:
        building(p)
        p.rect((12, 28, 36, 38), color((0.20, 0.14, 0.09), 75), None, 1)
        p.line([(0, 24), (48, 24)], color((0.78, 0.64, 0.38), 70), 1.2)

    def town(p: Painter) -> None:
        p.polygon([(8, 22), (24, 12), (40, 22), (36, 26), (12, 26)], color((0.30, 0.17, 0.10), 140))
        p.rect((13, 26, 35, 39), color((0.24, 0.16, 0.10), 90))
        p.line([(0, 34), (48, 26)], color((0.68, 0.56, 0.36), 65), 1.4)

    def village(p: Painter) -> None:
        p.polygon([(10, 24), (24, 14), (38, 24)], color((0.28, 0.20, 0.10), 115))
        p.rect((15, 24, 33, 37), color((0.20, 0.16, 0.10), 75))
        p.line([(6, 39), (42, 33)], color((0.68, 0.62, 0.36), 75), 1.2)

    def shop(p: Painter) -> None:
        p.rect((7, 16, 41, 40), color((0.65, 0.42, 0.24), 135), color((0.25, 0.13, 0.06), 120), 1)
        p.line([(8, 19), (40, 19)], color((0.94, 0.70, 0.32), 140), 2)
        p.rect((14, 10, 34, 17), color((0.75, 0.53, 0.25), 115))

    def temple(p: Painter) -> None:
        p.polygon([(5, 17), (24, 6), (43, 17), (38, 21), (10, 21)], color((0.67, 0.45, 0.22), 170))
        p.rect((13, 21, 35, 39), color((0.32, 0.24, 0.17), 135))
        p.line([(24, 8), (24, 39)], color((0.82, 0.66, 0.36), 70), 1)

    def marsh(p: Painter) -> None:
        for y in (18, 28, 36):
            p.line([(5, y), (43, y - 2)], color((0.45, 0.65, 0.58), 90), 2)
        for x in (12, 25, 38):
            p.line([(x, 38), (x + 2, 25)], color((0.12, 0.28, 0.16), 120), 1.4)

    def desert(p: Painter) -> None:
        for y in (20, 31, 40):
            p.arc((2, y - 8, 45, y + 8), 200, 340, color((0.80, 0.67, 0.42), 110), 1.5)
        p.ellipse((31, 11, 35, 15), color((0.92, 0.78, 0.46), 65))

    def bamboo(p: Painter) -> None:
        for x in (13, 24, 35):
            p.line([(x, 7), (x - 3, 42)], color((0.11, 0.29, 0.11), 190), 2)
            p.line([(x, 18), (x + 8, 13)], color((0.36, 0.66, 0.28), 125), 1.6)
            p.line([(x - 1, 28), (x - 8, 24)], color((0.36, 0.66, 0.28), 110), 1.4)

    def cliff(p: Painter) -> None:
        mountain(p)
        for x in (12, 25, 35):
            p.line([(x, 18), (x - 8, 43)], color((0.10, 0.10, 0.09), 100), 1.4)

    specs = {
        "grass": ((0.32, 0.47, 0.27), grass),
        "road": ((0.58, 0.50, 0.36), road),
        "water": ((0.17, 0.34, 0.48), water),
        "building": ((0.48, 0.31, 0.21), building),
        "forest": ((0.17, 0.32, 0.18), forest),
        "courtyard": ((0.47, 0.43, 0.34), courtyard),
        "sect": ((0.39, 0.43, 0.35), sect),
        "snow": ((0.72, 0.80, 0.86), snow),
        "bridge": ((0.46, 0.31, 0.18), bridge),
        "field": ((0.42, 0.50, 0.25), field),
        "mountain": ((0.35, 0.37, 0.32), mountain),
        "city": ((0.50, 0.45, 0.34), city),
        "town": ((0.47, 0.43, 0.32), town),
        "village": ((0.42, 0.48, 0.30), village),
        "shop": ((0.56, 0.40, 0.28), shop),
        "temple": ((0.42, 0.36, 0.30), temple),
        "marsh": ((0.22, 0.39, 0.34), marsh),
        "desert": ((0.60, 0.50, 0.34), desert),
        "bamboo": ((0.25, 0.45, 0.25), bamboo),
        "cliff": ((0.40, 0.40, 0.37), cliff),
    }
    result = {}
    for name, (base, func) in specs.items():
        path = generate_tile(name, color(base), func)
        result[name] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    return result


PRESETS = {
    "default": ("standard", "oval", "topknot", "none", "short_robe", "none", "none", (0.54, 0.46, 0.34), (0.24, 0.20, 0.16), (0.78, 0.62, 0.32)),
    "innkeeper": ("round", "round", "sideburns", "merchant_cap", "merchant_robe", "abacus", "coin", (0.62, 0.36, 0.20), (0.84, 0.68, 0.36), (0.96, 0.78, 0.34)),
    "waiter": ("slim", "round", "short", "cloth_cap", "work_apron", "towel", "none", (0.44, 0.38, 0.28), (0.86, 0.80, 0.64), (0.76, 0.58, 0.30)),
    "tofu_seller": ("graceful", "soft", "long_tail", "none", "plain_hanfu", "basket", "water", (0.78, 0.82, 0.72), (0.45, 0.64, 0.58), (0.92, 0.88, 0.70)),
    "scholar": ("thin", "long", "beard", "scholar_hat", "scholar_robe", "scroll", "book", (0.40, 0.48, 0.50), (0.82, 0.78, 0.64), (0.62, 0.50, 0.28)),
    "constable": ("strong", "square", "short", "constable_hat", "official_uniform", "dao", "badge", (0.18, 0.28, 0.38), (0.12, 0.12, 0.14), (0.78, 0.32, 0.22)),
    "elder": ("aged", "aged", "white_beard", "soft_cap", "elder_robe", "staff", "none", (0.45, 0.42, 0.30), (0.70, 0.64, 0.48), (0.58, 0.48, 0.28)),
    "monk": ("solid", "round", "bald", "monk_dots", "monk_robe", "beads", "lotus", (0.72, 0.42, 0.20), (0.52, 0.24, 0.12), (0.86, 0.70, 0.38)),
    "blacksmith": ("broad", "square", "headband", "headband", "smith_apron", "hammer", "spark", (0.36, 0.28, 0.22), (0.18, 0.16, 0.15), (0.84, 0.42, 0.18)),
    "wandering_hero": ("heroic", "sharp", "high_topknot", "none", "hero_robe", "sword", "wind", (0.28, 0.34, 0.42), (0.12, 0.14, 0.18), (0.86, 0.72, 0.42)),
    "town_trader": ("round", "round", "sideburns", "merchant_cap", "merchant_robe", "abacus", "coin", (0.48, 0.34, 0.24), (0.68, 0.55, 0.34), (0.90, 0.70, 0.32)),
    "cook": ("strong", "round", "short", "cloth_cap", "work_apron", "club", "none", (0.54, 0.36, 0.24), (0.88, 0.82, 0.64), (0.72, 0.44, 0.20)),
    "butcher": ("broad", "square", "headband", "headband", "leather", "dao", "scar", (0.42, 0.22, 0.16), (0.18, 0.14, 0.12), (0.82, 0.32, 0.20)),
    "flower_seller": ("graceful", "soft", "long_tail", "flower_pin", "plain_hanfu", "basket", "flower", (0.72, 0.62, 0.70), (0.45, 0.56, 0.48), (0.94, 0.68, 0.76)),
    "doctor": ("thin", "long", "beard", "scholar_hat", "scholar_robe", "scroll", "lotus", (0.50, 0.58, 0.50), (0.84, 0.80, 0.62), (0.58, 0.68, 0.42)),
    "poison_master": ("slim", "sharp", "long_tail", "face_mask", "night_suit", "dagger", "shadow", (0.10, 0.16, 0.12), (0.18, 0.36, 0.22), (0.58, 0.82, 0.34)),
    "tailor": ("slim", "oval", "short", "soft_cap", "work_apron", "scroll", "none", (0.50, 0.44, 0.58), (0.76, 0.70, 0.62), (0.70, 0.58, 0.34)),
    "town_guard": ("strong", "square", "short", "constable_hat", "official_uniform", "dao", "badge", (0.16, 0.25, 0.33), (0.10, 0.11, 0.13), (0.76, 0.30, 0.20)),
    "town_elder": ("aged", "aged", "white_beard", "soft_cap", "elder_robe", "staff", "none", (0.48, 0.43, 0.34), (0.70, 0.62, 0.46), (0.60, 0.48, 0.28)),
    "noble": ("thin", "long", "topknot", "scholar_hat", "scholar_robe", "fan", "coin", (0.56, 0.46, 0.62), (0.30, 0.26, 0.36), (0.88, 0.70, 0.34)),
    "child": ("child", "round", "short", "cloth_cap", "plain_hanfu", "none", "none", (0.58, 0.64, 0.52), (0.32, 0.40, 0.32), (0.92, 0.68, 0.34)),
    "wanderer": ("standard", "oval", "topknot", "none", "plain_hanfu", "staff", "wind", (0.42, 0.46, 0.40), (0.24, 0.26, 0.24), (0.72, 0.62, 0.38)),
    "swordsman_poet": ("heroic", "sharp", "high_topknot", "none", "hero_robe", "sword", "wind", (0.42, 0.48, 0.62), (0.12, 0.14, 0.18), (0.90, 0.78, 0.48)),
    "bagua_master": ("master", "square", "beard", "sect_crown", "sect_robe", "blade", "bagua", (0.44, 0.43, 0.38), (0.18, 0.17, 0.16), (0.82, 0.68, 0.38)),
    "bagua_disciple": ("strong", "square", "topknot", "sect_crown", "sect_robe", "blade", "bagua", (0.38, 0.37, 0.34), (0.16, 0.15, 0.14), (0.76, 0.62, 0.34)),
    "flower_master": ("graceful", "soft", "long_tail", "flower_pin", "flowing_hanfu", "fan", "flower", (0.76, 0.40, 0.52), (0.92, 0.72, 0.78), (0.98, 0.82, 0.48)),
    "flower_disciple": ("graceful", "soft", "long_tail", "flower_pin", "flowing_hanfu", "fan", "flower", (0.68, 0.42, 0.56), (0.86, 0.66, 0.74), (0.96, 0.78, 0.46)),
    "honglian_master": ("master", "square", "high_topknot", "dark_crown", "sect_robe", "great_blade", "lotus", (0.56, 0.08, 0.08), (0.16, 0.08, 0.06), (0.96, 0.58, 0.24)),
    "honglian_disciple": ("strong", "rough", "headband", "headband", "sect_robe", "club", "lotus", (0.52, 0.12, 0.10), (0.22, 0.10, 0.08), (0.90, 0.50, 0.22)),
    "naja_master": ("slim", "sharp", "masked", "face_mask", "night_suit", "dagger", "shadow", (0.08, 0.10, 0.10), (0.12, 0.26, 0.18), (0.50, 0.78, 0.42)),
    "naja_disciple": ("slim", "sharp", "masked", "face_mask", "night_suit", "dagger", "shadow", (0.10, 0.12, 0.12), (0.16, 0.30, 0.20), (0.48, 0.68, 0.36)),
    "taiji_master": ("thin", "long", "white_beard", "daoist_crown", "daoist_robe", "whisk", "taiji", (0.78, 0.78, 0.72), (0.20, 0.20, 0.20), (0.62, 0.68, 0.74)),
    "taiji_disciple": ("thin", "long", "topknot", "daoist_crown", "daoist_robe", "whisk", "taiji", (0.70, 0.70, 0.66), (0.18, 0.18, 0.18), (0.58, 0.64, 0.70)),
    "xueshan_master": ("strong", "sharp", "hood", "snow_hood", "fur_robe", "sword", "snow", (0.72, 0.82, 0.90), (0.36, 0.46, 0.60), (0.94, 0.96, 0.98)),
    "xueshan_disciple": ("strong", "sharp", "hood", "snow_hood", "fur_robe", "sword", "snow", (0.64, 0.76, 0.86), (0.32, 0.44, 0.58), (0.92, 0.96, 1.0)),
    "thug": ("rough", "square", "messy", "none", "ragged", "club", "scar", (0.44, 0.18, 0.14), (0.16, 0.12, 0.10), (0.72, 0.30, 0.18)),
    "bandit": ("broad", "rough", "messy", "bandit_wrap", "leather", "dao", "scar", (0.36, 0.16, 0.12), (0.12, 0.10, 0.08), (0.78, 0.26, 0.16)),
    "assassin": ("slim", "sharp", "masked", "face_mask", "night_suit", "dagger", "shadow", (0.08, 0.08, 0.10), (0.38, 0.08, 0.10), (0.82, 0.28, 0.22)),
    "boss": ("boss", "sharp", "wild", "dark_crown", "dark_armor", "great_blade", "dragon", (0.12, 0.10, 0.12), (0.48, 0.08, 0.08), (0.95, 0.62, 0.24)),
}


NAME_PRESETS = {
    "平阿四": "innkeeper", "店小二": "waiter", "阿青": "tofu_seller", "老夫子": "scholar", "捕快": "constable",
    "村长": "elder", "道德和尚": "monk", "铁匠": "blacksmith", "大侠": "wandering_hero", "苏梦瑶": "flower_disciple",
    "陈天行": "wandering_hero", "赵无极": "constable", "玄机子": "bagua_master", "花如玉": "flower_master",
    "烈火": "honglian_master", "蛇王": "naja_master", "太极真人": "taiji_master", "冰魄": "xueshan_master",
    "逍遥子": "wandering_hero", "阎商": "town_trader", "葛朗台": "town_trader", "小商贩": "town_trader",
    "厨师": "cook", "屠夫": "butcher", "卖花女": "flower_seller", "平一指": "doctor", "何铁手": "poison_master",
    "小裁缝": "tailor", "何裁缝": "tailor", "巡捕": "town_guard", "衙役": "town_guard", "老婆婆": "town_elder",
    "妇人": "town_elder", "公子哥": "noble", "书童": "child", "小童": "child", "何喜": "wanderer",
    "过路人": "wanderer", "茅十七": "wanderer", "李白": "swordsman_poet", "韦扬": "bagua_master",
    "清照": "flower_master", "于红儒": "honglian_master", "钟央": "naja_master", "清虚道人": "taiji_master",
    "白瑞德": "xueshan_master", "流氓": "thug", "流氓头": "bandit", "独角大盗": "bandit", "土匪甲": "bandit",
    "土匪头目": "bandit", "采花大盗": "assassin", "黑衣大盗": "assassin", "绣花女": "assassin",
    "魔化和尚": "boss", "雪豹": "xueshan_disciple", "神秘人": "boss",
}


def preset_for_npc(npc: dict) -> tuple[str, str, str, str, str, str, str, tuple[float, float, float], tuple[float, float, float], tuple[float, float, float]]:
    name = str(npc.get("name", ""))
    key = NAME_PRESETS.get(name)
    faction = str(npc.get("faction", "none"))
    if key is None and bool(npc.get("is_master", False)):
        key = {
            "bagua": "bagua_master",
            "flower": "flower_master",
            "honglian": "honglian_master",
            "naja": "naja_master",
            "taiji": "taiji_master",
            "xueshan": "xueshan_master",
            "xiaoyao": "wandering_hero",
        }.get(faction)
    if key is None:
        key = {
            "bagua": "bagua_disciple",
            "flower": "flower_disciple",
            "honglian": "honglian_disciple",
            "naja": "naja_disciple",
            "taiji": "taiji_disciple",
            "xueshan": "xueshan_disciple",
            "xiaoyao": "wandering_hero",
        }.get(faction)
    if key is None:
        if str(npc.get("npc_type", "normal")) == "enemy":
            key = "bandit"
        elif str(npc.get("npc_type", "normal")) == "trader":
            key = "town_trader"
        else:
            key = "default"
    return PRESETS[key]


def build_scale(build: str) -> tuple[float, float]:
    return {
        "round": (1.12, 0.98), "slim": (0.88, 1.05), "thin": (0.86, 1.08), "strong": (1.10, 1.02),
        "broad": (1.22, 0.98), "aged": (0.92, 0.95), "graceful": (0.92, 1.08), "heroic": (1.04, 1.12),
        "master": (1.08, 1.10), "rough": (1.08, 0.96), "boss": (1.26, 1.16), "child": (0.76, 0.78),
    }.get(build, (1.0, 1.0))


def draw_prop(p: Painter, prop: str, primary, secondary, accent, front: bool) -> None:
    ink = color((0.07, 0.06, 0.05), 230)
    metal = color((0.78, 0.80, 0.76), 220)
    if prop in {"sword", "blade", "dao", "great_blade"} and not front:
        width = 2.0 if prop != "great_blade" else 4.0
        p.line([(62, 77), (78, 28)], metal, width)
        p.line([(58, 75), (67, 82)], darken(accent, 0.15), 3)
    if prop == "club" and not front:
        p.line([(32, 78), (20, 38)], darken(secondary, 0.2), 4.0)
    if prop == "staff" and not front:
        p.line([(27, 102), (27, 32)], darken(secondary, 0.2), 3.0)
    if prop == "hammer" and front:
        p.line([(27, 70), (18, 92)], darken(secondary, 0.2), 3.0)
        p.rect((11, 63, 25, 72), darken(accent, 0.10), ink, 1)
    if prop == "abacus" and front:
        p.rect((25, 67, 39, 82), darken(accent, 0.08), ink, 1)
        for y in (71, 76):
            p.line([(27, y), (37, y)], ink, 1)
        for x in (29, 34):
            p.ellipse((x - 1.4, 70, x + 1.4, 73), lighten(accent, 0.25), ink, 1)
            p.ellipse((x - 1.4, 75, x + 1.4, 78), lighten(accent, 0.25), ink, 1)
    if prop == "basket" and front:
        p.ellipse((24, 74, 41, 91), color((0.66, 0.46, 0.25), 210), ink, 1)
        p.arc((25, 65, 40, 84), 180, 360, ink, 1.2)
    if prop == "scroll" and front:
        p.rect((57, 63, 70, 84), color((0.88, 0.82, 0.62), 230), ink, 1)
        p.line([(60, 68), (68, 68)], color((0.45, 0.32, 0.18), 180), 1)
        p.line([(60, 74), (68, 74)], color((0.45, 0.32, 0.18), 160), 1)
    if prop == "fan" and front:
        for angle in range(-35, 36, 18):
            rad = math.radians(angle)
            p.line([(63, 78), (63 + math.sin(rad) * 18, 78 - math.cos(rad) * 15)], accent, 1.4)
        p.arc((47, 58, 79, 90), 210, 330, lighten(primary, 0.2), 4.0)
    if prop in {"dagger", "whisk"} and front:
        if prop == "dagger":
            p.line([(67, 72), (76, 57)], metal, 2.0)
            p.line([(64, 74), (69, 80)], darken(accent, 0.15), 2.0)
        else:
            p.line([(67, 68), (76, 46)], darken(accent, 0.15), 2.0)
            for dx in (-4, -1, 2, 5):
                p.line([(76, 46), (82 + dx, 62)], color((0.88, 0.88, 0.82), 120), 1)
    if prop == "beads" and front:
        for i in range(9):
            angle = math.radians(210 + i * 15)
            x = 48 + math.cos(angle) * 13
            y = 59 + math.sin(angle) * 10
            p.ellipse((x - 1.8, y - 1.8, x + 1.8, y + 1.8), darken(accent, 0.05), ink, 1)
    if prop == "towel" and front:
        p.polygon([(28, 58), (43, 61), (39, 84), (27, 80)], color((0.88, 0.84, 0.70), 220), ink)


def draw_outfit(p: Painter, outfit: str, build: str, primary, secondary, accent) -> None:
    ink = color((0.07, 0.06, 0.05), 205)
    sx, sy = build_scale(build)
    top = 50
    bottom = 104 if build != "child" else 91
    half_top = 14 * sx
    half_bottom = 20 * sx
    if outfit in {"work_apron", "smith_apron", "official_uniform", "leather", "night_suit", "ragged", "dark_armor"}:
        p.polygon([(48 - half_top, top), (48 + half_top, top), (48 + half_bottom, bottom - 8), (48, bottom + 4), (48 - half_bottom, bottom - 8)], primary, ink)
        p.rect((48 - half_top, top + 10, 48 + half_top, top + 16), darken(secondary, 0.08))
        if outfit in {"work_apron", "smith_apron"}:
            p.rect((48 - 12 * sx, top + 4, 48 + 12 * sx, bottom - 6), lighten(secondary, 0.22), ink, 1)
        if outfit == "official_uniform":
            p.rect((40, 58, 56, 72), darken(accent, 0.12), ink, 1)
        if outfit == "night_suit":
            p.line([(38, 60), (58, 76)], accent, 2)
        if outfit == "dark_armor":
            for y in (59, 70, 81):
                p.line([(34, y), (62, y)], darken(accent, 0.15), 1.5)
    else:
        p.polygon([(48 - half_top, top), (48 + half_top, top), (48 + half_bottom, bottom - 5), (48, bottom + 4), (48 - half_bottom, bottom - 5)], primary, ink)
        p.line([(48 - half_top + 3, top + 7), (48 + half_top - 2, bottom - 22)], accent, 2.0)
        p.line([(48 + half_top - 4, top + 8), (48 - half_top + 5, bottom - 18)], darken(secondary, 0.05), 1.2)
        p.rect((48 - half_top, 75, 48 + half_top, 80), darken(accent, 0.2))
        if outfit in {"flowing_hanfu", "daoist_robe", "fur_robe"}:
            p.polygon([(48 - half_bottom, bottom - 7), (48, bottom + 7), (48 + half_bottom, bottom - 7), (56, bottom + 10), (40, bottom + 10)], lighten(primary, 0.05), None)
        if outfit == "fur_robe":
            p.line([(34, 51), (62, 51)], color((0.96, 0.98, 1.0), 170), 5)
    arm_y = 60
    p.line([(48 - half_top + 1, arm_y), (27, 77)], darken(primary, 0.08), 5)
    p.line([(48 + half_top - 1, arm_y), (69, 76)], darken(primary, 0.10), 5)
    p.ellipse((23, 74, 29, 81), color((0.84, 0.68, 0.52), 230))
    p.ellipse((67, 73, 73, 80), color((0.84, 0.68, 0.52), 230))
    p.line([(40, bottom - 2), (37, 113)], ink, 3)
    p.line([(56, bottom - 2), (59, 113)], ink, 3)


def draw_head(p: Painter, head: str, hair: str, hat: str, primary, secondary, accent) -> None:
    ink = color((0.07, 0.06, 0.05), 225)
    skin = color((0.84, 0.68, 0.52), 235)
    if head == "aged":
        skin = color((0.78, 0.64, 0.50), 235)
    if head == "sharp":
        bbox = (37, 25, 59, 49)
    elif head == "long":
        bbox = (38, 23, 58, 51)
    elif head == "square":
        bbox = (36, 27, 60, 50)
    else:
        bbox = (37, 25, 59, 49)
    p.ellipse(bbox, skin, ink, 1)
    if hair not in {"bald", "masked", "hood"}:
        p.arc((36, 21, 60, 44), 190, 350, ink, 4)
    if hair in {"topknot", "high_topknot"}:
        p.line([(48, 23), (48, 14 if hair == "high_topknot" else 18)], ink, 2.5)
        p.ellipse((44, 11, 52, 18), ink)
    if hair in {"long_tail", "wild", "messy"}:
        p.line([(39, 36), (32, 63)], ink, 3)
        p.line([(57, 36), (64, 62)], ink, 3)
    if hair in {"beard", "white_beard"}:
        beard = color((0.88, 0.86, 0.78), 220) if hair == "white_beard" else ink
        p.polygon([(42, 46), (54, 46), (48, 62)], beard)
    if hair == "headband":
        p.line([(37, 32), (59, 30)], accent, 3)
    if hair in {"masked", "hood"} or hat in {"face_mask", "snow_hood"}:
        if hat == "snow_hood":
            p.ellipse((33, 18, 63, 54), color((0.86, 0.92, 0.96), 210), darken(accent, 0.12), 1)
            p.ellipse((38, 25, 58, 50), skin, ink, 1)
        else:
            p.rect((36, 37, 60, 48), darken(primary, 0.15))
    if hat == "merchant_cap":
        p.polygon([(35, 27), (48, 18), (61, 27), (57, 31), (39, 31)], darken(secondary, 0.08), ink)
    elif hat == "cloth_cap" or hat == "soft_cap":
        p.arc((36, 19, 60, 37), 180, 360, darken(secondary, 0.1), 5)
    elif hat == "scholar_hat":
        p.rect((36, 20, 60, 26), darken(secondary, 0.10), ink)
        p.rect((42, 13, 54, 23), darken(secondary, 0.02), ink)
    elif hat == "constable_hat":
        p.rect((35, 22, 61, 29), darken(secondary, 0.05), ink)
        p.polygon([(42, 21), (48, 13), (54, 21)], accent, ink)
    elif hat == "sect_crown":
        p.polygon([(37, 25), (48, 13), (59, 25)], darken(primary, 0.18), ink)
        p.ellipse((45, 17, 51, 23), accent)
    elif hat == "daoist_crown":
        p.line([(40, 21), (56, 21)], darken(secondary, 0.15), 3)
        p.ellipse((44, 13, 52, 21), darken(secondary, 0.04), ink, 1)
    elif hat == "dark_crown":
        p.polygon([(36, 26), (42, 15), (48, 26), (54, 15), (60, 26)], darken(primary, 0.25), ink)
    elif hat == "flower_pin":
        for angle in range(0, 360, 72):
            rad = math.radians(angle)
            cx = 59 + math.cos(rad) * 3
            cy = 25 + math.sin(rad) * 3
            p.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), lighten(accent, 0.18))
    p.ellipse((43, 36, 45, 38), ink)
    p.ellipse((51, 36, 53, 38), ink)
    p.line([(45, 44), (52, 44)], color((0.26, 0.12, 0.10), 150), 1)


def draw_motif(p: Painter, motif: str, accent, primary) -> None:
    ink = color((0.07, 0.06, 0.05), 210)
    if motif == "bagua":
        p.ellipse((43, 65, 53, 75), with_alpha(accent, 120), ink, 1)
        p.line([(48, 66), (48, 74)], ink, 1)
        p.line([(44, 70), (52, 70)], ink, 1)
    elif motif in {"flower", "lotus"}:
        for angle in range(0, 360, 72):
            rad = math.radians(angle)
            cx = 48 + math.cos(rad) * 5
            cy = 68 + math.sin(rad) * 4
            p.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), lighten(accent, 0.18))
    elif motif == "snow":
        for angle in range(0, 180, 45):
            rad = math.radians(angle)
            p.line([(48 - math.cos(rad) * 6, 68 - math.sin(rad) * 6), (48 + math.cos(rad) * 6, 68 + math.sin(rad) * 6)], accent, 1)
    elif motif == "taiji":
        p.ellipse((43, 64, 53, 74), color((0.94, 0.94, 0.88), 170), ink, 1)
        p.arc((43, 64, 53, 74), 90, 270, ink, 2)
    elif motif == "badge":
        p.rect((44, 64, 52, 72), accent, ink, 1)
    elif motif == "scar":
        p.line([(40, 38), (44, 43)], color((0.62, 0.10, 0.08), 170), 1.2)
    elif motif == "shadow":
        p.line([(40, 66), (56, 74)], with_alpha(accent, 130), 2)
    elif motif == "coin":
        p.ellipse((44, 65, 52, 73), accent, ink, 1)
    elif motif == "book":
        p.rect((43, 65, 53, 74), color((0.86, 0.78, 0.58), 150), ink, 1)
    elif motif == "wind":
        p.arc((38, 61, 60, 76), 200, 345, with_alpha(accent, 150), 2)
    elif motif == "spark":
        p.line([(44, 67), (52, 71)], accent, 1.5)
        p.line([(52, 67), (44, 71)], accent, 1.5)
    elif motif == "dragon":
        p.arc((37, 58, 62, 83), 200, 30, with_alpha(accent, 140), 2.5)


def draw_character(preset, path: Path, variant_seed: int = 0) -> None:
    build, head, hair, hat, outfit, prop, motif, primary_raw, secondary_raw, accent_raw = preset
    primary = color(primary_raw)
    secondary = color(secondary_raw)
    accent = color(accent_raw)
    if variant_seed:
        tint = ((variant_seed * 17) % 9 - 4) / 100.0
        primary = lighten(primary, tint) if tint > 0 else darken(primary, -tint)
    image, p = new_canvas(CHAR_SIZE)
    if build in {"master", "boss"}:
        p.ellipse((21, 30, 75, 116), with_alpha(accent, 28))
    if motif == "snow":
        p.ellipse((22, 30, 74, 112), color((0.80, 0.92, 1.0), 35))
    draw_prop(p, prop, primary, secondary, accent, front=False)
    draw_outfit(p, outfit, build, primary, secondary, accent)
    draw_head(p, head, hair, hat, primary, secondary, accent)
    draw_prop(p, prop, primary, secondary, accent, front=True)
    draw_motif(p, motif, accent, primary)
    save_canvas(image, path, CHAR_SIZE)


def generate_npc_sprites() -> dict[str, str]:
    npcs = json.loads((DATA / "npcs.json").read_text(encoding="utf-8"))
    mapping: dict[str, str] = {}
    for npc in npcs:
        npc_id = int(npc.get("id", 0))
        name = str(npc.get("name", f"npc_{npc_id}"))
        filename = f"npc_{npc_id:03d}.png"
        path = NPC_DIR / filename
        draw_character(preset_for_npc(npc), path, npc_id)
        mapping[name] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    NPC_SPRITE_MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mapping


def draw_frame(p: Painter, width: int, height: int, accent: tuple[int, int, int, int]) -> None:
    p.rect((4, 4, width - 4, height - 4), color((0.07, 0.06, 0.045), 210), accent, 2)
    p.line([(14, 14), (width - 14, 9)], with_alpha(lighten(accent, 0.22), 90), 1.2)
    p.line([(12, height - 14), (width - 12, height - 19)], with_alpha(darken(accent, 0.20), 85), 1.2)


def generate_npc_portraits(npcs: dict[str, str]) -> dict[str, str]:
    records = json.loads((DATA / "npcs.json").read_text(encoding="utf-8"))
    mapping: dict[str, str] = {}
    for npc in records:
        npc_id = int(npc.get("id", 0))
        name = str(npc.get("name", f"npc_{npc_id}"))
        preset = preset_for_npc(npc)
        accent = color(preset[-1])
        primary = color(preset[-3])
        image, p = new_canvas((192, 192), color((0.08, 0.07, 0.055), 255))
        for index in range(9):
            y = 26 + index * 16
            p.arc((12, y - 16, 180, y + 28), 200, 340, with_alpha(lighten(primary, 0.30), 30), 1.5)
        p.ellipse((28, 22, 164, 178), with_alpha(accent, 36))
        draw_frame(p, 192, 192, with_alpha(accent, 210))
        draw_portrait_character(p, preset, npc_id)
        path = PORTRAIT_DIR / f"portrait_{npc_id:03d}.png"
        save_canvas(image, path, (192, 192))
        mapping[name] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    NPC_PORTRAIT_MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mapping


def draw_portrait_character(p: Painter, preset, variant_seed: int = 0) -> None:
    build, head, hair, hat, outfit, prop, motif, primary_raw, secondary_raw, accent_raw = preset
    primary = color(primary_raw)
    secondary = color(secondary_raw)
    accent = color(accent_raw)
    if variant_seed:
        tint = ((variant_seed * 13) % 11 - 5) / 100.0
        primary = lighten(primary, tint) if tint > 0 else darken(primary, -tint)
    ink = color((0.055, 0.045, 0.035), 235)
    skin = color((0.84, 0.68, 0.52), 245)
    if head == "aged":
        skin = color((0.77, 0.63, 0.50), 245)
    if prop in {"sword", "blade", "dao", "great_blade"}:
        p.line([(134, 151), (163, 38)], color((0.78, 0.80, 0.76), 190), 3 if prop != "great_blade" else 5)
        p.line([(127, 149), (143, 163)], darken(accent, 0.20), 5)
    if prop == "staff":
        p.line([(49, 185), (49, 46)], darken(secondary, 0.25), 4)
    p.polygon([(54, 122), (138, 122), (170, 190), (22, 190)], primary, ink)
    p.line([(67, 130), (124, 182)], accent, 3)
    p.line([(124, 129), (73, 181)], darken(secondary, 0.08), 2)
    p.rect((52, 154, 140, 162), darken(accent, 0.22))
    if outfit in {"official_uniform", "dark_armor", "night_suit"}:
        p.rect((74, 134, 118, 164), darken(secondary, 0.10), ink)
    if outfit == "fur_robe":
        p.arc((48, 106, 144, 154), 190, 350, color((0.94, 0.96, 1.0), 190), 9)
    p.rect((82, 102, 110, 127), skin)
    if hair in {"hood", "masked"} or hat == "snow_hood":
        hood_color = color((0.76, 0.84, 0.92), 230) if hat == "snow_hood" else darken(primary, 0.20)
        p.ellipse((53, 25, 139, 119), hood_color, ink, 2)
    if hair not in {"bald", "hood", "masked"}:
        if hair in {"long_tail", "wild", "messy"}:
            p.line([(67, 76), (45, 147)], ink, 7)
            p.line([(125, 76), (147, 147)], ink, 7)
        p.arc((62, 26, 130, 92), 180, 360, ink, 9)
    face_box = (66, 43, 126, 108)
    if head == "long":
        face_box = (68, 36, 124, 112)
    elif head == "square":
        face_box = (62, 48, 130, 110)
    elif head == "sharp":
        face_box = (68, 40, 124, 109)
    p.ellipse(face_box, skin, ink, 2)
    if hair in {"topknot", "high_topknot"}:
        top = 14 if hair == "high_topknot" else 23
        p.line([(96, 42), (96, top)], ink, 4)
        p.ellipse((86, top - 9, 106, top + 8), ink)
    if hair in {"beard", "white_beard"}:
        beard = color((0.86, 0.84, 0.76), 235) if hair == "white_beard" else ink
        p.polygon([(77, 97), (115, 97), (96, 137)], beard)
    if hair == "headband":
        p.line([(64, 59), (128, 55)], accent, 5)
    if hat == "merchant_cap":
        p.polygon([(58, 50), (96, 20), (134, 50), (124, 61), (68, 61)], darken(secondary, 0.05), ink)
    elif hat in {"cloth_cap", "soft_cap"}:
        p.arc((61, 24, 131, 70), 180, 360, darken(secondary, 0.08), 10)
    elif hat == "scholar_hat":
        p.rect((58, 34, 134, 47), darken(secondary, 0.12), ink)
        p.rect((78, 13, 114, 38), darken(secondary, 0.03), ink)
    elif hat == "constable_hat":
        p.rect((57, 34, 135, 50), darken(secondary, 0.08), ink)
        p.polygon([(77, 35), (96, 10), (115, 35)], accent, ink)
    elif hat == "sect_crown":
        p.polygon([(61, 46), (96, 11), (131, 46)], darken(primary, 0.20), ink)
        p.ellipse((88, 23, 104, 40), accent, ink)
    elif hat == "daoist_crown":
        p.line([(72, 33), (120, 33)], darken(secondary, 0.16), 6)
        p.ellipse((82, 10, 110, 36), darken(secondary, 0.03), ink, 2)
    elif hat == "dark_crown":
        p.polygon([(58, 49), (75, 17), (96, 47), (117, 17), (134, 49)], darken(primary, 0.26), ink)
    elif hat == "flower_pin":
        for angle in range(0, 360, 72):
            rad = math.radians(angle)
            cx = 130 + math.cos(rad) * 7
            cy = 40 + math.sin(rad) * 7
            p.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), lighten(accent, 0.18), ink)
    if hat == "face_mask":
        p.rect((63, 82, 129, 105), darken(primary, 0.16))
    p.ellipse((80, 72, 86, 78), ink)
    p.ellipse((106, 72, 112, 78), ink)
    p.line([(84, 95), (108, 95)], color((0.24, 0.10, 0.08), 150), 2)
    if motif in {"flower", "lotus"}:
        for angle in range(0, 360, 72):
            rad = math.radians(angle)
            cx = 96 + math.cos(rad) * 11
            cy = 146 + math.sin(rad) * 9
            p.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), lighten(accent, 0.12))
    elif motif == "bagua":
        p.ellipse((83, 134, 109, 160), with_alpha(accent, 140), ink, 2)
        p.line([(96, 136), (96, 158)], ink, 1.5)
        p.line([(85, 147), (107, 147)], ink, 1.5)
    elif motif == "taiji":
        p.ellipse((83, 134, 109, 160), color((0.92, 0.92, 0.86), 180), ink, 2)
        p.arc((83, 134, 109, 160), 90, 270, ink, 3)
    elif motif == "snow":
        for angle in range(0, 180, 45):
            rad = math.radians(angle)
            p.line([(96 - math.cos(rad) * 16, 146 - math.sin(rad) * 16), (96 + math.cos(rad) * 16, 146 + math.sin(rad) * 16)], accent, 2)
    elif motif == "badge":
        p.rect((84, 134, 108, 158), accent, ink, 2)


def generate_player_sprites() -> dict[str, str]:
    faction_presets = {
        "none": ("heroic", "sharp", "high_topknot", "none", "hero_robe", "sword", "wind", (0.18, 0.27, 0.33), (0.10, 0.13, 0.16), (0.78, 0.65, 0.38)),
        "bagua": PRESETS["bagua_disciple"],
        "flower": PRESETS["flower_disciple"],
        "honglian": PRESETS["honglian_disciple"],
        "naja": PRESETS["naja_disciple"],
        "taiji": PRESETS["taiji_disciple"],
        "xueshan": PRESETS["xueshan_disciple"],
        "xiaoyao": PRESETS["wandering_hero"],
    }
    result: dict[str, str] = {}
    for gender in ("male", "female"):
        for faction, preset in faction_presets.items():
            values = list(preset)
            if gender == "female" and faction in {"none", "bagua", "honglian", "naja", "taiji", "xueshan", "xiaoyao"}:
                values[1] = "soft"
                values[2] = "long_tail"
            path = PLAYER_DIR / f"player_{gender}_{faction}.png"
            draw_character(tuple(values), path, len(faction) + (17 if gender == "female" else 0))
            result[f"{gender}_{faction}"] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    return result


def generate_part(name: str, category: str, preset_key: str, only: str) -> str:
    preset = list(PRESETS[preset_key])
    if only == "head":
        preset[4] = "none"
        preset[5] = "none"
        preset[6] = "none"
    elif only == "outfit":
        preset[1] = "none"
        preset[2] = "none"
        preset[3] = "none"
        preset[5] = "none"
        preset[6] = "none"
    elif only == "prop":
        preset[1] = "none"
        preset[2] = "none"
        preset[3] = "none"
        preset[4] = "none"
        preset[6] = "none"
    path = PARTS_DIR / category / f"{name}.png"
    image, p = new_canvas(CHAR_SIZE)
    build, head, hair, hat, outfit, prop, motif, primary_raw, secondary_raw, accent_raw = tuple(preset)
    primary = color(primary_raw)
    secondary = color(secondary_raw)
    accent = color(accent_raw)
    if only == "head":
        draw_head(p, head, hair, hat, primary, secondary, accent)
    elif only == "outfit":
        draw_outfit(p, outfit, build, primary, secondary, accent)
        draw_motif(p, motif, accent, primary)
    elif only == "prop":
        draw_prop(p, prop, primary, secondary, accent, front=False)
        draw_prop(p, prop, primary, secondary, accent, front=True)
    save_canvas(image, path, CHAR_SIZE)
    return "res://" + str(path.relative_to(ROOT / "godot_project"))


def generate_parts() -> dict[str, dict[str, str]]:
    specs = {
        "heads": [
            ("head_town", "default"), ("head_scholar", "scholar"), ("head_constable", "constable"), ("head_monk", "monk"),
            ("head_flower", "flower_disciple"), ("head_masked", "naja_disciple"), ("head_snow", "xueshan_disciple"),
        ],
        "outfits": [
            ("robe_town", "default"), ("robe_merchant", "innkeeper"), ("robe_scholar", "scholar"), ("uniform_constable", "constable"),
            ("robe_monk", "monk"), ("robe_bagua", "bagua_disciple"), ("robe_flower", "flower_disciple"), ("robe_honglian", "honglian_disciple"),
            ("robe_naja", "naja_disciple"), ("robe_taiji", "taiji_disciple"), ("robe_xueshan", "xueshan_disciple"), ("robe_hero", "wandering_hero"),
        ],
        "props": [
            ("prop_sword", "wandering_hero"), ("prop_blade", "bagua_disciple"), ("prop_fan", "flower_disciple"), ("prop_dagger", "naja_disciple"),
            ("prop_whisk", "taiji_disciple"), ("prop_staff", "elder"), ("prop_abacus", "innkeeper"), ("prop_basket", "tofu_seller"),
            ("prop_scroll", "scholar"), ("prop_hammer", "blacksmith"),
        ],
    }
    result: dict[str, dict[str, str]] = {}
    for category, items in specs.items():
        only = "head" if category == "heads" else "outfit" if category == "outfits" else "prop"
        result[category] = {}
        for name, preset_key in items:
            result[category][name] = generate_part(name, category, preset_key, only)
    return result


def generate_item_icons() -> dict[str, str]:
    items = json.loads((DATA / "items.json").read_text(encoding="utf-8"))
    mapping: dict[str, str] = {}
    for item in items:
        item_id = str(item.get("id", "item"))
        item_type = str(item.get("type", "misc"))
        image, p = new_canvas((64, 64))
        bg = color((0.10, 0.085, 0.065), 235)
        accent = color((0.78, 0.62, 0.32), 230)
        if item_type == "weapon":
            accent = color((0.72, 0.74, 0.70), 230)
        elif item_type == "armor":
            accent = color((0.46, 0.58, 0.66), 230)
        elif "flower" in item_id:
            accent = color((0.88, 0.44, 0.58), 230)
        p.rect((4, 4, 60, 60), bg, accent, 2)
        p.ellipse((9, 9, 55, 55), color((0.22, 0.18, 0.12), 110))
        _draw_item_symbol(p, item_id, item_type, accent)
        path = ITEM_ICON_DIR / f"{item_id}.png"
        save_canvas(image, path, (64, 64))
        mapping[item_id] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    ITEM_ICON_MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mapping


def load_skill_names() -> dict[str, str]:
    source = (ROOT / "godot_project" / "scripts" / "autoload" / "game_data.gd").read_text(encoding="utf-8")
    block_match = re.search(r"const SKILL_NAMES := \{(?P<body>.*?)\n\}", source, re.S)
    if block_match == None:
        return {}
    return dict(re.findall(r'"(kf_[a-zA-Z0-9_]+)"\s*:\s*"([^"]+)"', block_match.group("body")))


def generate_skill_icons() -> dict[str, str]:
    skills = load_skill_names()
    mapping: dict[str, str] = {}
    for skill_id, skill_name in skills.items():
        image, p = new_canvas((64, 64))
        primary, secondary, accent = _skill_palette(skill_id)
        p.rect((4, 4, 60, 60), color((0.075, 0.068, 0.052), 238), accent, 2)
        p.ellipse((9, 9, 55, 55), with_alpha(primary, 72))
        p.arc((10, 13, 55, 52), 200, 345, with_alpha(lighten(accent, 0.18), 92), 2.0)
        _draw_skill_symbol(p, skill_id, skill_name, primary, secondary, accent)
        path = SKILL_ICON_DIR / f"{skill_id}.png"
        save_canvas(image, path, (64, 64))
        mapping[skill_id] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    SKILL_ICON_MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mapping


def _skill_palette(skill_id: str) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]:
    if "bagua" in skill_id or "bazhen" in skill_id or "hunyuan" in skill_id or "youlong" in skill_id:
        return color((0.34, 0.28, 0.48), 230), color((0.16, 0.13, 0.22), 230), color((0.88, 0.70, 0.36), 235)
    if "hua" in skill_id or "liu" in skill_id or "meihua" in skill_id or "sanhua" in skill_id:
        return color((0.58, 0.26, 0.40), 230), color((0.20, 0.10, 0.16), 230), color((0.96, 0.62, 0.72), 235)
    if "taiji" in skill_id or "wanliu" in skill_id or "xuanxu" in skill_id:
        return color((0.62, 0.64, 0.60), 230), color((0.14, 0.14, 0.13), 230), color((0.86, 0.84, 0.72), 235)
    if "xue" in skill_id or "taxue" in skill_id:
        return color((0.42, 0.58, 0.70), 230), color((0.18, 0.25, 0.32), 230), color((0.86, 0.94, 1.0), 235)
    if "hexiang" in skill_id or "jiaoyi" in skill_id or "pifeng" in skill_id or "taizu" in skill_id or "tongji" in skill_id:
        return color((0.66, 0.16, 0.12), 230), color((0.22, 0.07, 0.05), 230), color((1.0, 0.58, 0.26), 235)
    if "renshu" in skill_id or "wufa" in skill_id or "wuying" in skill_id or "yidao" in skill_id:
        return color((0.16, 0.32, 0.20), 230), color((0.06, 0.09, 0.07), 230), color((0.58, 0.82, 0.38), 235)
    if "xiaoyao" in skill_id or "beiming" in skill_id or "liuyang" in skill_id or "xiaowuxiang" in skill_id or "lingbo" in skill_id:
        return color((0.20, 0.44, 0.34), 230), color((0.08, 0.15, 0.13), 230), color((0.78, 0.88, 0.52), 235)
    return color((0.34, 0.36, 0.36), 230), color((0.13, 0.13, 0.12), 230), color((0.78, 0.62, 0.32), 235)


def _draw_skill_symbol(
    p: Painter,
    skill_id: str,
    skill_name: str,
    primary: tuple[int, int, int, int],
    secondary: tuple[int, int, int, int],
    accent: tuple[int, int, int, int],
) -> None:
    ink = color((0.035, 0.03, 0.025), 235)
    metal = color((0.82, 0.84, 0.80), 235)
    if "sword" in skill_id or "jian" in skill_id or "huafei" in skill_id or "liu" in skill_id:
        p.polygon([(31, 8), (38, 37), (32, 48), (26, 37)], metal, ink)
        p.line([(21, 44), (43, 44)], accent, 4)
        p.line([(32, 45), (32, 58)], secondary, 4)
        p.arc((12, 10, 52, 56), 215, 315, with_alpha(accent, 150), 2)
    elif "blade" in skill_id or "dao" in skill_id or "pifeng" in skill_id or "xuanxu" in skill_id or "yidao" in skill_id:
        p.polygon([(21, 9), (45, 15), (35, 44), (24, 50)], metal, ink)
        p.line([(32, 44), (24, 58)], secondary, 4)
        p.arc((14, 7, 56, 51), 188, 288, with_alpha(accent, 150), 3)
    elif "palm" in skill_id or "fist" in skill_id or "bare" in skill_id or "taizu" in skill_id or "liuyang" in skill_id:
        p.ellipse((20, 14, 44, 46), color((0.82, 0.58, 0.42), 235), ink)
        for x in (18, 25, 32, 39):
            p.line([(x, 25), (x + 2, 12)], color((0.82, 0.58, 0.42), 235), 4)
        p.arc((11, 10, 55, 56), 205, 330, with_alpha(accent, 150), 3)
    elif "force" in skill_id or "hunyuan" in skill_id or "jiaoyi" in skill_id or "beiming" in skill_id or "xiaowuxiang" in skill_id:
        p.ellipse((18, 18, 46, 46), with_alpha(accent, 170), ink, 2)
        p.arc((13, 13, 51, 51), 30, 310, primary, 4)
        p.arc((23, 23, 41, 41), 210, 130, lighten(accent, 0.28), 3)
    elif "dodge" in skill_id or "youlong" in skill_id or "meihua" in skill_id or "wanliu" in skill_id or "taxue" in skill_id or "wuying" in skill_id or "lingbo" in skill_id or "xiaoyao_you" in skill_id:
        p.line([(14, 46), (30, 28), (48, 16)], accent, 4)
        p.arc((12, 18, 38, 50), 200, 20, with_alpha(accent, 145), 2.5)
        p.arc((24, 8, 58, 43), 205, 30, with_alpha(lighten(accent, 0.22), 130), 2.5)
        p.ellipse((42, 13, 49, 20), lighten(accent, 0.16), ink)
    elif "bazhen" in skill_id or "bagua" in skill_id:
        p.ellipse((17, 17, 47, 47), with_alpha(accent, 120), ink, 2)
        for angle in range(0, 360, 45):
            rad = math.radians(angle)
            p.line([(32 + math.cos(rad) * 10, 32 + math.sin(rad) * 10), (32 + math.cos(rad) * 21, 32 + math.sin(rad) * 21)], accent, 2)
        p.rect((28, 24, 36, 40), secondary, ink)
    elif "literate" in skill_id:
        p.rect((20, 13, 45, 51), color((0.88, 0.80, 0.58), 235), ink)
        for y in (22, 30, 38):
            p.line([(25, y), (40, y - 2)], secondary, 1.5)
        p.line([(15, 48), (31, 16)], accent, 2.5)
    else:
        p.ellipse((20, 20, 44, 44), accent, ink)
        p.arc((14, 14, 50, 50), 220, 40, lighten(accent, 0.20), 3)


def _draw_item_symbol(p: Painter, item_id: str, item_type: str, accent) -> None:
    ink = color((0.05, 0.04, 0.03), 230)
    metal = color((0.82, 0.84, 0.80), 235)
    wood = color((0.45, 0.26, 0.12), 230)
    red = color((0.75, 0.16, 0.12), 235)
    green = color((0.34, 0.60, 0.36), 235)
    if item_type == "weapon":
        if "whip" in item_id:
            p.arc((14, 14, 52, 52), 210, 70, accent, 4)
            p.line([(38, 44), (49, 54)], wood, 4)
        elif "dagger" in item_id:
            p.polygon([(31, 10), (39, 34), (32, 41), (25, 34)], metal, ink)
            p.rect((25, 39, 39, 45), accent, ink)
            p.line([(32, 44), (32, 56)], wood, 4)
        elif "blade" in item_id:
            p.polygon([(22, 10), (43, 14), (34, 45), (24, 49)], metal, ink)
            p.line([(31, 45), (26, 57)], wood, 4)
        elif "diaogan" in item_id:
            p.line([(18, 54), (47, 9)], wood, 3)
            p.arc((41, 11, 58, 31), 260, 50, metal, 1.4)
        else:
            p.polygon([(31, 7), (38, 36), (32, 45), (26, 36)], metal, ink)
            p.line([(21, 42), (43, 42)], accent, 4)
            p.line([(32, 43), (32, 57)], wood, 4)
    elif item_type == "armor":
        p.polygon([(20, 15), (32, 21), (44, 15), (50, 53), (32, 58), (14, 53)], accent, ink)
        p.line([(32, 22), (32, 55)], darken(accent, 0.25), 1.5)
        p.line([(20, 34), (44, 34)], lighten(accent, 0.18), 2)
    elif "baozi" in item_id:
        p.ellipse((17, 22, 47, 49), color((0.90, 0.76, 0.52), 235), ink)
        for x in (25, 32, 39):
            p.line([(x, 25), (x - 2, 36)], color((0.58, 0.38, 0.18), 110), 1.2)
    elif "chicken" in item_id or "meat" in item_id:
        p.ellipse((17, 19, 47, 48), color((0.72, 0.34, 0.16), 235), ink)
        p.line([(42, 42), (52, 51)], color((0.90, 0.82, 0.62), 235), 5)
    elif "wine" in item_id:
        p.rect((25, 15, 40, 49), color((0.54, 0.28, 0.16), 235), ink)
        p.rect((27, 9, 38, 17), color((0.34, 0.18, 0.10), 235), ink)
        p.line([(28, 26), (37, 26)], accent, 2)
    elif "yao" in item_id or "shengji" in item_id or "dan" in item_id:
        p.ellipse((20, 18, 44, 48), color((0.76, 0.22, 0.18), 235), ink)
        p.rect((26, 9, 38, 20), color((0.88, 0.78, 0.56), 235), ink)
        p.line([(26, 33), (38, 33)], color((0.98, 0.88, 0.62), 200), 2)
    elif "flower" in item_id:
        for angle in range(0, 360, 60):
            rad = math.radians(angle)
            cx = 32 + math.cos(rad) * 10
            cy = 28 + math.sin(rad) * 8
            p.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), red if "red" in item_id else color((0.88, 0.76, 0.68), 235), ink)
        p.line([(32, 38), (27, 55)], green, 3)
    elif "fish" in item_id:
        p.ellipse((15, 24, 47, 43), color((0.56, 0.66, 0.70), 235), ink)
        p.polygon([(46, 33), (57, 23), (57, 44)], color((0.42, 0.52, 0.58), 235), ink)
        p.ellipse((22, 31, 25, 34), ink)
    elif "doufu" in item_id:
        fill = color((0.88, 0.90, 0.74), 235) if "green" in item_id else color((0.92, 0.88, 0.72), 235)
        p.rect((18, 24, 47, 46), fill, ink)
        p.line([(18, 35), (47, 35)], color((0.62, 0.66, 0.48), 100), 1)
    elif "tang_hulu" in item_id:
        p.line([(24, 53), (45, 11)], wood, 2)
        for cx, cy in [(29, 43), (34, 33), (39, 23)]:
            p.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), red, ink)
    else:
        p.ellipse((20, 20, 44, 44), accent, ink)


def generate_scene_backgrounds() -> dict[str, str]:
    regions = json.loads((DATA / "regions.json").read_text(encoding="utf-8"))
    mapping: dict[str, str] = {}
    for region in regions:
        region_id = str(region.get("id", "region"))
        terrain = str(region.get("terrain", "plain"))
        region_type = str(region.get("type", "wild"))
        image, p = new_canvas((640, 360), color((0.08, 0.075, 0.060), 255))
        _draw_scene_base(p, region_type, terrain)
        path = SCENE_DIR / f"scene_{region_id}.png"
        save_canvas(image, path, (640, 360))
        mapping[region_id] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    SCENE_BACKGROUND_MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mapping


def _draw_scene_base(p: Painter, region_type: str, terrain: str) -> None:
    sky = color((0.28, 0.30, 0.28), 255)
    ground = color((0.30, 0.37, 0.24), 255)
    water = color((0.16, 0.32, 0.42), 255)
    if "snow" in terrain:
        sky = color((0.36, 0.42, 0.46), 255)
        ground = color((0.70, 0.78, 0.84), 255)
    elif "desert" in terrain:
        sky = color((0.48, 0.42, 0.30), 255)
        ground = color((0.58, 0.48, 0.30), 255)
    elif "water" in terrain or "lake" in terrain or "river" in terrain or "canal" in terrain or "marsh" in terrain:
        sky = color((0.26, 0.34, 0.36), 255)
        ground = water
    p.rect((0, 0, 640, 360), sky)
    for i in range(7):
        y = 52 + i * 28
        p.arc((20, y - 50, 620, y + 70), 190, 345, color((0.78, 0.76, 0.66), 22), 2)
    mountain_color = color((0.20, 0.23, 0.21), 170)
    if "snow" in terrain:
        mountain_color = color((0.62, 0.70, 0.76), 190)
    for offset, height in [(0, 120), (110, 150), (260, 110), (400, 140), (520, 105)]:
        p.polygon([(offset - 50, 210), (offset + 80, 70 + (160 - height)), (offset + 210, 210)], mountain_color)
    if region_type == "city":
        _draw_city_scene(p, ground)
    elif region_type == "town":
        _draw_town_scene(p, ground, terrain)
    elif region_type == "sect":
        _draw_sect_scene(p, ground, terrain)
    else:
        _draw_wild_scene(p, ground, terrain)
    p.rect((0, 306, 640, 360), color((0.06, 0.055, 0.045), 70))
    p.line([(0, 306), (640, 294)], color((0.82, 0.66, 0.36), 55), 1.5)


def _draw_city_scene(p: Painter, ground) -> None:
    p.rect((0, 220, 640, 360), ground)
    for x in range(40, 610, 105):
        p.rect((x, 162, x + 72, 250), color((0.28, 0.18, 0.11), 210), color((0.10, 0.06, 0.04), 190), 1)
        p.polygon([(x - 8, 162), (x + 36, 128), (x + 80, 162), (x + 68, 174), (x + 4, 174)], color((0.42, 0.20, 0.12), 220))
    p.line([(0, 275), (640, 236)], color((0.62, 0.52, 0.34), 120), 7)


def _draw_town_scene(p: Painter, ground, terrain: str) -> None:
    p.rect((0, 214, 640, 360), ground)
    for x in range(64, 600, 136):
        p.rect((x, 186, x + 88, 252), color((0.25, 0.18, 0.11), 190), color((0.10, 0.06, 0.04), 170), 1)
        p.polygon([(x - 12, 188), (x + 44, 148), (x + 100, 188), (x + 84, 202), (x + 4, 202)], color((0.34, 0.18, 0.10), 215))
    if "starter" in terrain:
        p.ellipse((266, 151, 374, 258), color((0.10, 0.24, 0.10), 180))
        p.line([(320, 215), (320, 300)], color((0.14, 0.08, 0.04), 180), 8)
    p.line([(0, 286), (640, 252)], color((0.62, 0.52, 0.34), 115), 5)


def _draw_sect_scene(p: Painter, ground, terrain: str) -> None:
    p.rect((0, 220, 640, 360), ground)
    hall = color((0.30, 0.24, 0.17), 220)
    roof = color((0.50, 0.28, 0.12), 230)
    if "flower" in terrain:
        roof = color((0.62, 0.30, 0.42), 230)
    elif "shadow" in terrain:
        roof = color((0.10, 0.16, 0.12), 230)
    elif "snow" in terrain:
        roof = color((0.62, 0.72, 0.82), 230)
    p.rect((220, 156, 420, 268), hall, color((0.08, 0.06, 0.04), 190), 2)
    p.polygon([(176, 160), (320, 78), (464, 160), (430, 184), (210, 184)], roof)
    p.line([(320, 92), (320, 268)], color((0.82, 0.66, 0.36), 80), 2)
    p.arc((260, 180, 380, 300), 200, 340, color((0.82, 0.66, 0.36), 85), 3)


def _draw_wild_scene(p: Painter, ground, terrain: str) -> None:
    if "river" in terrain or "lake" in terrain or "water" in terrain or "canal" in terrain or "marsh" in terrain:
        p.rect((0, 210, 640, 360), color((0.16, 0.32, 0.42), 235))
        for y in (238, 276, 315):
            p.arc((30, y - 40, 610, y + 46), 190, 345, color((0.70, 0.86, 0.92), 80), 2.5)
    else:
        p.rect((0, 218, 640, 360), ground)
    if "forest" in terrain or "bamboo" in terrain:
        for x in range(40, 640, 72):
            p.ellipse((x - 26, 152, x + 34, 250), color((0.08, 0.24, 0.10), 170))
            p.line([(x, 220), (x, 330)], color((0.10, 0.06, 0.03), 150), 5)
    if "field" in terrain or "garden" in terrain:
        for y in range(236, 352, 24):
            p.line([(0, y), (640, y - 38)], color((0.68, 0.68, 0.32), 90), 2)
    if "desert" in terrain:
        for y in (236, 282, 326):
            p.arc((0, y - 40, 640, y + 50), 200, 340, color((0.84, 0.70, 0.42), 115), 3)


def generate_ui_assets() -> dict[str, str]:
    specs = {
        "panel_ink": (320, 160),
        "button_gold": (180, 48),
        "slot_item": (72, 72),
        "bar_hp": (240, 28),
        "bar_mp": (240, 28),
        "marker_quest": (48, 48),
        "marker_npc": (48, 48),
        "marker_target": (48, 48),
    }
    result: dict[str, str] = {}
    for name, size in specs.items():
        image, p = new_canvas(size, (0, 0, 0, 0))
        if name.startswith("bar_"):
            fill = color((0.78, 0.14, 0.12), 230) if name == "bar_hp" else color((0.18, 0.40, 0.72), 230)
            p.rect((2, 2, size[0] - 2, size[1] - 2), color((0.08, 0.065, 0.045), 235), color((0.78, 0.62, 0.32), 220), 2)
            p.rect((8, 8, size[0] - 8, size[1] - 8), fill)
        elif name.startswith("marker_"):
            accent = color((0.94, 0.72, 0.22), 235)
            if name == "marker_npc":
                accent = color((0.50, 0.72, 0.92), 235)
            elif name == "marker_target":
                accent = color((0.90, 0.22, 0.18), 235)
            p.ellipse((8, 8, 40, 40), with_alpha(accent, 90), accent, 2)
            p.polygon([(24, 10), (31, 25), (24, 38), (17, 25)], accent, color((0.04, 0.03, 0.02), 220))
        else:
            p.rect((2, 2, size[0] - 2, size[1] - 2), color((0.075, 0.068, 0.052), 235), color((0.66, 0.52, 0.28), 220), 2)
            p.line([(12, 12), (size[0] - 12, 8)], color((0.90, 0.76, 0.42), 72), 1.5)
            p.line([(12, size[1] - 12), (size[0] - 12, size[1] - 18)], color((0.04, 0.03, 0.02), 90), 1.5)
        path = UI_DIR / f"{name}.png"
        save_canvas(image, path, size)
        result[name] = "res://" + str(path.relative_to(ROOT / "godot_project"))
    return result


def main() -> None:
    TILE_DIR.mkdir(parents=True, exist_ok=True)
    SCENE_DIR.mkdir(parents=True, exist_ok=True)
    NPC_DIR.mkdir(parents=True, exist_ok=True)
    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    PLAYER_DIR.mkdir(parents=True, exist_ok=True)
    PARTS_DIR.mkdir(parents=True, exist_ok=True)
    ITEM_ICON_DIR.mkdir(parents=True, exist_ok=True)
    SKILL_ICON_DIR.mkdir(parents=True, exist_ok=True)
    UI_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    tiles = generate_tiles()
    npcs = generate_npc_sprites()
    portraits = generate_npc_portraits(npcs)
    players = generate_player_sprites()
    parts = generate_parts()
    item_icons = generate_item_icons()
    skill_icons = generate_skill_icons()
    scenes = generate_scene_backgrounds()
    ui = generate_ui_assets()
    previews = generate_previews(tiles, npcs, players, portraits, item_icons, skill_icons, scenes)
    manifest = {
        "generated_by": "tools/generate_godot_art_assets.py",
        "style": "2D ink-wash wuxia, deterministic component sprites",
        "tiles": tiles,
        "npc_map_sprites": npcs,
        "npc_portraits": portraits,
        "player_map_sprites": players,
        "character_parts": parts,
        "item_icons": item_icons,
        "skill_icons": skill_icons,
        "scene_backgrounds": scenes,
        "ui": ui,
        "previews": previews,
        "counts": {
            "tiles": len(tiles),
            "npc_map_sprites": len(npcs),
            "npc_portraits": len(portraits),
            "player_map_sprites": len(players),
            "parts": sum(len(v) for v in parts.values()),
            "item_icons": len(item_icons),
            "skill_icons": len(skill_icons),
            "scene_backgrounds": len(scenes),
            "ui": len(ui),
        },
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "Generated art assets: "
        f"tiles={len(tiles)} npcs={len(npcs)} portraits={len(portraits)} "
        f"players={len(players)} parts={manifest['counts']['parts']} icons={len(item_icons)} "
        f"skills={len(skill_icons)} scenes={len(scenes)} ui={len(ui)}"
    )


def generate_previews(
    tiles: dict[str, str],
    npcs: dict[str, str],
    players: dict[str, str],
    portraits: dict[str, str],
    item_icons: dict[str, str],
    skill_icons: dict[str, str],
    scenes: dict[str, str],
) -> dict[str, str]:
    tile_sheet = Image.new("RGBA", (10 * 48, 2 * 48), (24, 22, 18, 255))
    for index, res_path in enumerate(tiles.values()):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        tile_sheet.alpha_composite(Image.open(path).convert("RGBA"), ((index % 10) * 48, (index // 10) * 48))
    tile_preview = PREVIEW_DIR / "tiles_preview.png"
    tile_sheet.save(tile_preview)

    npc_items = list(npcs.values())
    npc_sheet = Image.new("RGBA", (10 * 48, 10 * 64), (24, 22, 18, 255))
    for index, res_path in enumerate(npc_items[:100]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA").resize((48, 64), Image.Resampling.LANCZOS)
        npc_sheet.alpha_composite(image, ((index % 10) * 48, (index // 10) * 64))
    npc_preview = PREVIEW_DIR / "npc_preview.png"
    npc_sheet.save(npc_preview)

    player_items = list(players.values())
    player_sheet = Image.new("RGBA", (8 * 72, 2 * 96), (24, 22, 18, 255))
    for index, res_path in enumerate(player_items[:16]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA").resize((72, 96), Image.Resampling.LANCZOS)
        player_sheet.alpha_composite(image, ((index % 8) * 72, (index // 8) * 96))
    player_preview = PREVIEW_DIR / "player_preview.png"
    player_sheet.save(player_preview)

    portrait_items = list(portraits.values())
    portrait_sheet = Image.new("RGBA", (10 * 96, 10 * 96), (24, 22, 18, 255))
    for index, res_path in enumerate(portrait_items[:100]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA").resize((96, 96), Image.Resampling.LANCZOS)
        portrait_sheet.alpha_composite(image, ((index % 10) * 96, (index // 10) * 96))
    portrait_preview = PREVIEW_DIR / "npc_portrait_preview.png"
    portrait_sheet.save(portrait_preview)

    icon_items = list(item_icons.values())
    icon_sheet = Image.new("RGBA", (8 * 64, 3 * 64), (24, 22, 18, 255))
    for index, res_path in enumerate(icon_items[:24]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA")
        icon_sheet.alpha_composite(image, ((index % 8) * 64, (index // 8) * 64))
    icon_preview = PREVIEW_DIR / "item_icon_preview.png"
    icon_sheet.save(icon_preview)

    skill_items = list(skill_icons.values())
    skill_sheet = Image.new("RGBA", (8 * 64, 6 * 64), (24, 22, 18, 255))
    for index, res_path in enumerate(skill_items[:48]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA")
        skill_sheet.alpha_composite(image, ((index % 8) * 64, (index // 8) * 64))
    skill_preview = PREVIEW_DIR / "skill_icon_preview.png"
    skill_sheet.save(skill_preview)

    scene_items = list(scenes.values())
    scene_sheet = Image.new("RGBA", (4 * 160, 4 * 90), (24, 22, 18, 255))
    for index, res_path in enumerate(scene_items[:16]):
        path = ROOT / "godot_project" / res_path.removeprefix("res://")
        image = Image.open(path).convert("RGBA").resize((160, 90), Image.Resampling.LANCZOS)
        scene_sheet.alpha_composite(image, ((index % 4) * 160, (index // 4) * 90))
    scene_preview = PREVIEW_DIR / "scene_preview.png"
    scene_sheet.save(scene_preview)

    return {
        "tiles": "res://" + str(tile_preview.relative_to(ROOT / "godot_project")),
        "npc": "res://" + str(npc_preview.relative_to(ROOT / "godot_project")),
        "player": "res://" + str(player_preview.relative_to(ROOT / "godot_project")),
        "npc_portrait": "res://" + str(portrait_preview.relative_to(ROOT / "godot_project")),
        "item_icon": "res://" + str(icon_preview.relative_to(ROOT / "godot_project")),
        "skill_icon": "res://" + str(skill_preview.relative_to(ROOT / "godot_project")),
        "scene": "res://" + str(scene_preview.relative_to(ROOT / "godot_project")),
    }


if __name__ == "__main__":
    main()
