import arcade
import math
import random
from typing import Optional, Dict, Callable, Set
from ..config import TILE_PALETTE, BUILDING_COLORS, VISUAL_CONFIG
from ..entities import Map
from .draw_utils import (SW, SH, TS, get_anim_time, map_to_world, world_to_screen,
                         draw_text, lighten, darken, alpha, draw_gradient_rect)
from .texture_gen import (apply_texture_noise, draw_water_tile, draw_grass_detail,
                           draw_road_detail, draw_soft_shadow, draw_gradient_rect as pil_gradient)
from .post_process import get_post_processor, get_advanced_lights
from .ink_renderer import InkTextureGenerator

WATER_TIDS = {2, 27, 105}
TREE_TIDS = {4, 26, 51, 52, 53, 54}
PLANT_TIDS = {55, 56, 57, 58}
FLOWER_TIDS = {31, 59, 60, 61, 62, 63}
COUNTER_TIDS = {64, 65, 66, 67, 68}
DESK_TIDS = {22, 69, 70, 71}
BENCH_TIDS = {72, 73, 74}
SHELF_TIDS = {35, 75, 76, 77}
SCULPTURE_TIDS = {78, 79, 80}
HILL_TIDS = {12, 93, 94, 95, 96}
STONE_TIDS = {97, 98, 99}
WALL_TIDS = {8, 19, 81, 100, 101, 102, 103, 104}
BUILDING_TIDS = {3, 9, 13, 14, 15, 16, 17, 18, 90}
ROAD_TIDS = {1, 6, 10, 106}

_LIGHT_SOURCES = []

CHUNK_SIZE = 10
_chunk_cache: Dict[tuple, arcade.Texture] = {}


def add_light_source(wx, wy, radius=120, color=(255, 200, 100), intensity=0.5):
    _LIGHT_SOURCES.append((wx, wy, radius, color, intensity))


def clear_light_sources():
    _LIGHT_SOURCES.clear()


def _get_tile_color(tid: int) -> tuple:
    palette = TILE_PALETTE.get(tid) or TILE_PALETTE.get(0) or {"base": (128, 128, 128)}
    return palette["base"]


def _draw_tree_pine(draw, px, py, c, detail):
    cx, cy = px + TS // 2, py + TS // 2
    draw.rectangle([cx - 3, cy + 2, cx + 3, cy + 18], fill=(100, 70, 40))
    pts_l = [(cx, cy - 18), (cx - 16, cy + 4), (cx + 16, cy + 4)]
    draw.polygon(pts_l, fill=(*detail, 255))
    pts_m = [(cx, cy - 12), (cx - 12, cy + 8), (cx + 12, cy + 8)]
    draw.polygon(pts_m, fill=(*lighten(detail, 15), 255))


def _draw_tree_willow(draw, px, py, c, detail):
    cx, cy = px + TS // 2, py + TS // 2
    draw.rectangle([cx - 3, cy - 2, cx + 3, cy + 18], fill=(100, 70, 40))
    draw.ellipse([cx - 18, cy - 16, cx + 18, cy + 6], fill=(*detail, 255))
    for dx in [-14, -8, 0, 8, 14]:
        draw.line([cx + dx, cy + 2, cx + dx - 2, cy + 16], fill=(*darken(detail, 20), 180), width=1)


def _draw_tree_bamboo(draw, px, py, c, detail):
    cx, cy = px + TS // 2, py + TS // 2
    for dx in [-8, 0, 8]:
        draw.rectangle([cx + dx - 2, py + 4, cx + dx + 2, py + TS - 4], fill=(80, 130, 50))
        last_ny = py + 10
        for ny in range(py + 10, py + TS - 8, 12):
            draw.line([cx + dx - 4, ny, cx + dx + 4, ny], fill=(60, 110, 35), width=1)
            last_ny = ny
        draw.ellipse([cx + dx - 8, last_ny - 10, cx + dx + 8, last_ny], fill=(*detail, 255))


def _draw_tree_dead(draw, px, py, c, detail):
    cx, cy = px + TS // 2, py + TS // 2
    draw.rectangle([cx - 3, cy + 4, cx + 3, cy + 18], fill=(90, 65, 35))
    draw.line([cx, cy + 4, cx - 14, cy - 8], fill=(90, 65, 35), width=2)
    draw.line([cx, cy + 4, cx + 12, cy - 6], fill=(90, 65, 35), width=2)
    draw.line([cx - 14, cy - 8, cx - 18, cy - 14], fill=(90, 65, 35), width=1)
    draw.line([cx + 12, cy - 6, cx + 16, cy - 12], fill=(90, 65, 35), width=1)


def _draw_plant(draw, px, py, c, detail, accent):
    cx, cy = px + TS // 2, py + TS // 2 + 6
    draw.ellipse([cx - 12, cy - 8, cx + 12, cy + 8], fill=(*detail, 255))
    draw.ellipse([cx - 8, cy - 12, cx + 8, cy + 4], fill=(*lighten(detail, 10), 255))
    draw.ellipse([cx - 4, cy - 14, cx + 4, cy - 6], fill=(*accent, 255))


def _draw_flower(draw, px, py, c, detail, accent):
    cx, cy = px + TS // 2, py + TS // 2 + 8
    draw.ellipse([cx - 10, cy - 6, cx + 10, cy + 6], fill=(60, 130, 35))
    for dx, dy in [(-6, -4), (6, -4), (0, -8), (-4, 2), (4, 2)]:
        draw.ellipse([cx + dx - 4, cy + dy - 4, cx + dx + 4, cy + dy + 4], fill=(*detail, 255))
    draw.ellipse([cx - 2, cy - 10, cx + 2, cy - 6], fill=(*accent, 255))


def _draw_counter(draw, px, py, c, detail, accent, counter_type):
    draw.rectangle([px + 6, py + 14, px + TS - 6, py + TS - 6], fill=(*c, 255))
    draw.rectangle([px + 6, py + 10, px + TS - 6, py + 16], fill=(*accent, 255))
    draw.line([px + 6, py + 16, px + TS - 6, py + 16], fill=(*darken(c, 20), 255), width=2)
    if counter_type == 65:
        for i in range(3):
            draw.ellipse([px + 12 + i * 14, py + 20, px + 20 + i * 14, py + 28], fill=(80, 140, 60))
    elif counter_type == 66:
        draw.line([px + 14, py + 22, px + 14, py + 10], fill=(180, 180, 190), width=2)
        draw.line([px + 28, py + 22, px + 28, py + 10], fill=(180, 180, 190), width=2)
        draw.line([px + 42, py + 22, px + 42, py + 10], fill=(180, 180, 190), width=2)
    elif counter_type == 67:
        draw.ellipse([px + 14, py + 18, px + 22, py + 26], fill=(220, 190, 60))
        draw.ellipse([px + 30, py + 18, px + 38, py + 26], fill=(220, 190, 60))


def _draw_desk(draw, px, py, c, detail, accent, desk_type):
    draw.rectangle([px + 8, py + 16, px + TS - 8, py + TS - 12], fill=(*c, 255))
    draw.rectangle([px + 8, py + 14, px + TS - 8, py + 18], fill=(*accent, 255))
    if desk_type == 71:
        draw.rectangle([px + 4, py + 14, px + TS - 4, py + TS - 10], fill=(*c, 255))
        draw.rectangle([px + 4, py + 12, px + TS - 4, py + 16], fill=(*accent, 255))


def _draw_bench(draw, px, py, c, detail, accent, bench_type):
    if bench_type == 74:
        draw.rectangle([px + 4, py + 20, px + TS - 4, py + TS - 14], fill=(*c, 255))
        draw.rectangle([px + 4, py + 18, px + TS - 4, py + 22], fill=(*accent, 255))
    else:
        draw.rectangle([px + 10, py + 20, px + TS - 10, py + TS - 14], fill=(*c, 255))
        draw.rectangle([px + 10, py + 18, px + TS - 10, py + 22], fill=(*accent, 255))


def _draw_shelf(draw, px, py, c, detail, accent, shelf_type):
    draw.rectangle([px + 6, py + 6, px + TS - 6, py + TS - 6], fill=(*c, 255))
    for sy in [py + 16, py + 28, py + 40]:
        draw.line([px + 6, sy, px + TS - 6, sy], fill=(*darken(c, 15), 255), width=2)
    if shelf_type == 76:
        for sy in [py + 12, py + 24, py + 36]:
            for bx in range(px + 10, px + TS - 10, 10):
                draw.rectangle([bx, sy, bx + 6, sy + 8], fill=(180, 60, 60))
    elif shelf_type == 77:
        for sy in [py + 12, py + 24, py + 36]:
            for bx in range(px + 10, px + TS - 10, 10):
                draw.ellipse([bx, sy, bx + 6, sy + 8], fill=(80, 140, 60))


def _draw_sculpture(draw, px, py, c, detail, accent, sc_type):
    cx, cy = px + TS // 2, py + TS // 2
    if sc_type == 78:
        draw.rectangle([cx - 14, cy + 8, cx + 14, cy + 18], fill=(*darken(c, 10), 255))
        draw.rectangle([cx - 8, cy - 6, cx + 8, cy + 10], fill=(*c, 255))
        draw.ellipse([cx - 10, cy - 14, cx + 10, cy - 2], fill=(*lighten(c, 10), 255))
    elif sc_type == 79:
        draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=(*c, 255))
        draw.ellipse([cx - 8, cy - 18, cx + 8, cy - 6], fill=(*accent, 255))
        draw.line([cx, cy + 12, cx, cy + 20], fill=(*darken(c, 20), 255), width=3)
    elif sc_type == 80:
        draw.rectangle([cx - 10, cy + 4, cx + 10, cy + 20], fill=(*c, 255))
        draw.line([cx - 8, cy + 4, cx - 16, cy - 8], fill=(*accent, 255), width=3)
        draw.line([cx + 8, cy + 4, cx + 16, cy - 8], fill=(*accent, 255), width=3)


def _draw_hill(draw, px, py, c, detail, accent, hill_type):
    cx, cy = px + TS // 2, py + TS - 6
    if hill_type == 93:
        pts = [(cx, cy - 18), (cx - 20, cy), (cx + 20, cy)]
    elif hill_type == 94:
        pts = [(cx, cy - 28), (cx - 24, cy), (cx + 24, cy)]
    elif hill_type == 95:
        pts = [(cx, cy - 36), (cx - 28, cy), (cx + 28, cy)]
    elif hill_type == 96:
        pts = [(cx, cy - 28), (cx - 24, cy), (cx + 24, cy)]
    else:
        pts = [(cx, cy - 24), (cx - 22, cy), (cx + 22, cy)]
    draw.polygon(pts, fill=(*c, 255))
    mid_pts = [(pts[0][0], pts[0][1] + (pts[1][1] - pts[0][1]) // 3),
               (pts[1][0] + (pts[0][0] - pts[1][0]) // 3, pts[1][1] - (pts[1][1] - pts[0][1]) // 6),
               (pts[2][0] + (pts[0][0] - pts[2][0]) // 3, pts[2][1] - (pts[2][1] - pts[0][1]) // 6)]
    draw.polygon(mid_pts, fill=(*lighten(c, 12), 255))
    draw.line([pts[0], pts[2]], fill=(*darken(c, 20), 255), width=1)
    draw.line([pts[0], pts[1]], fill=(*darken(c, 15), 255), width=1)
    if hill_type == 96:
        draw.polygon([(cx, cy - 28), (cx - 10, cy - 18), (cx + 10, cy - 18)], fill=(235, 240, 250))
        draw.polygon([(cx, cy - 28), (cx - 5, cy - 22), (cx + 5, cy - 22)], fill=(245, 248, 255))


def _draw_stone(draw, px, py, c, detail, accent, stone_type):
    cx, cy = px + TS // 2, py + TS // 2 + 4
    if stone_type == 97:
        draw.ellipse([cx - 8, cy - 6, cx + 8, cy + 6], fill=(*c, 255))
        draw.ellipse([cx - 5, cy - 8, cx + 5, cy - 2], fill=(*lighten(c, 10), 255))
    elif stone_type == 98:
        draw.ellipse([cx - 12, cy - 10, cx + 12, cy + 10], fill=(*c, 255))
        draw.ellipse([cx - 8, cy - 12, cx + 8, cy - 2], fill=(*lighten(c, 10), 255))
    elif stone_type == 99:
        draw.ellipse([cx - 18, cy - 14, cx + 18, cy + 14], fill=(*c, 255))
        draw.ellipse([cx - 12, cy - 16, cx + 12, cy - 2], fill=(*lighten(c, 10), 255))
        draw.line([cx - 8, cy - 4, cx + 6, cy + 6], fill=(*darken(c, 15), 255), width=1)


def _draw_terrain_transitions(draw, game_map, chunk_tx, chunk_ty, cx_tiles, cy_tiles, map_h):
    """Draw smooth transitions between terrain types"""
    SOFT_TERRAIN = {0, 5, 6, 11, 39, 43, 1, 10, 106}
    WATER_TERRAIN = {2, 27, 32, 105}
    HARD_TERRAIN = WALL_TIDS | BUILDING_TIDS | {7, 8, 20, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104}
    EDGE_BLEND_PX = 8
    WATER_BLEND_PX = 6

    for local_ty in range(cy_tiles):
        global_ty = chunk_ty * CHUNK_SIZE + local_ty
        if global_ty >= len(game_map.tiles):
            break
        row = game_map.tiles[global_ty]
        for local_tx in range(cx_tiles):
            global_tx = chunk_tx * CHUNK_SIZE + local_tx
            if global_tx >= len(row):
                break
            tid = row[global_tx]
            if tid in HARD_TERRAIN:
                continue
            px = local_tx * TS
            py = (cy_tiles - 1 - local_ty) * TS
            c = _get_tile_color(tid)

            is_water = tid in WATER_TERRAIN

            neighbors = []
            if global_ty > 0:
                neighbors.append(("top", game_map.tiles[global_ty - 1][global_tx] if global_tx < len(game_map.tiles[global_ty - 1]) else tid))
            if global_ty + 1 < len(game_map.tiles):
                neighbors.append(("bottom", game_map.tiles[global_ty + 1][global_tx] if global_tx < len(game_map.tiles[global_ty + 1]) else tid))
            if global_tx > 0:
                neighbors.append(("left", row[global_tx - 1]))
            if global_tx + 1 < len(row):
                neighbors.append(("right", row[global_tx + 1]))

            for direction, ntid in neighbors:
                if ntid == tid or ntid in HARD_TERRAIN:
                    continue
                n_is_water = ntid in WATER_TERRAIN

                # 特殊处理水面到草地的过渡 - 渐变效果
                if is_water != n_is_water:
                    blend_px = WATER_BLEND_PX
                    if is_water:  # 当前是水，邻居是陆地
                        land_c = _get_tile_color(0)  # 草色
                        for i in range(blend_px):
                            alpha = int(200 * (1 - i / blend_px))
                            if direction == "top":
                                draw.rectangle([px, py + TS - blend_px + i, px + TS, py + TS - blend_px + i + 1],
                                              fill=(*land_c, alpha))
                            elif direction == "bottom":
                                draw.rectangle([px, py + i, px + TS, py + i + 1],
                                              fill=(*land_c, alpha))
                            elif direction == "left":
                                draw.rectangle([px + TS - blend_px + i, py, px + TS - blend_px + i + 1, py + TS],
                                              fill=(*land_c, alpha))
                            elif direction == "right":
                                draw.rectangle([px + i, py, px + i + 1, py + TS],
                                              fill=(*land_c, alpha))
                    else:  # 当前是陆地，邻居是水
                        water_c = _get_tile_color(2)  # 水色
                        for i in range(blend_px):
                            alpha = int(150 * (1 - i / blend_px))
                            if direction == "top":
                                draw.rectangle([px, py, px + TS, py + i + 1], fill=(*water_c, alpha))
                            elif direction == "bottom":
                                draw.rectangle([px, py + TS - i - 1, px + TS, py + TS], fill=(*water_c, alpha))
                            elif direction == "left":
                                draw.rectangle([px, py, px + i + 1, py + TS], fill=(*water_c, alpha))
                            elif direction == "right":
                                draw.rectangle([px + TS - i - 1, py, px + TS, py + TS], fill=(*water_c, alpha))
                    continue

                # 道路到草地的过渡
                if (tid in {10, 1, 106} and ntid == 0) or (tid == 0 and ntid in {10, 1, 106}):
                    blend_px = EDGE_BLEND_PX
                    nc = _get_tile_color(ntid)
                    for i in range(blend_px):
                        alpha = int(120 * (1 - i / blend_px))
                        blend_c = (
                            (c[0] + nc[0]) // 2,
                            (c[1] + nc[1]) // 2,
                            (c[2] + nc[2]) // 2,
                            alpha
                        )
                        if direction == "top":
                            draw.rectangle([px, py + TS - blend_px + i, px + TS, py + TS - blend_px + i + 1], fill=blend_c)
                        elif direction == "bottom":
                            draw.rectangle([px, py + i, px + TS, py + i + 1], fill=blend_c)
                        elif direction == "left":
                            draw.rectangle([px + TS - blend_px + i, py, px + TS - blend_px + i + 1, py + TS], fill=blend_c)
                        elif direction == "right":
                            draw.rectangle([px + i, py, px + i + 1, py + TS], fill=blend_c)
                    continue

                # 一般软地形混合
                if tid in SOFT_TERRAIN and ntid in SOFT_TERRAIN:
                    nc = _get_tile_color(ntid)
                    blend_px = EDGE_BLEND_PX
                    for i in range(blend_px):
                        alpha = int(100 * (1 - i / blend_px))
                        blend_c = (
                            (c[0] + nc[0]) // 2,
                            (c[1] + nc[1]) // 2,
                            (c[2] + nc[2]) // 2,
                            alpha
                        )
                        if direction == "top":
                            draw.rectangle([px, py + TS - blend_px + i, px + TS, py + TS - blend_px + i + 1], fill=blend_c)
                        elif direction == "bottom":
                            draw.rectangle([px, py + i, px + TS, py + i + 1], fill=blend_c)
                        elif direction == "left":
                            draw.rectangle([px + TS - blend_px + i, py, px + TS - blend_px + i + 1, py + TS], fill=blend_c)
                        elif direction == "right":
                            draw.rectangle([px + i, py, px + i + 1, py + TS], fill=blend_c)


def _draw_wall_variant(draw, px, py, c, detail, accent, wall_type):
    draw.rectangle([px + 2, py + 2, px + TS - 2, py + TS - 2], fill=(*c, 255))
    draw.line([px + 2, py + TS // 2, px + TS - 2, py + TS // 2], fill=(*darken(c, 15), 255), width=1)
    draw.line([px + TS // 2, py + 2, px + TS // 2, py + TS - 2], fill=(*darken(c, 10), 255), width=1)
    if wall_type == 104:
        for ny in range(py + 8, py + TS - 4, 12):
            draw.line([px + 4, ny, px + TS - 4, ny], fill=(*darken(c, 8), 255), width=1)
    elif wall_type == 103:
        for ny in range(py + 6, py + TS - 4, 10):
            draw.line([px + 4, ny, px + TS - 4, ny], fill=(*darken(c, 12), 255), width=1)
            offset = 0 if (ny - py) // 10 % 2 == 0 else TS // 4
            for nx in range(px + 4 + offset, px + TS - 4, TS // 2):
                draw.line([nx, ny, nx, ny + 10], fill=(*darken(c, 8), 255), width=1)


def _render_chunk_to_texture(game_map, chunk_tx, chunk_ty, map_h):
    try:
        from PIL import Image, ImageDraw, ImageFilter
        cx_tiles = min(CHUNK_SIZE, len(game_map.tiles[0]) - chunk_tx * CHUNK_SIZE)
        cy_tiles = min(CHUNK_SIZE, len(game_map.tiles) - chunk_ty * CHUNK_SIZE)
        if cx_tiles <= 0 or cy_tiles <= 0:
            return None

        img_w = cx_tiles * TS
        img_h = cy_tiles * TS
        img = Image.new('RGBA', (img_w, img_h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        for local_ty in range(cy_tiles):
            global_ty = chunk_ty * CHUNK_SIZE + local_ty
            if global_ty >= len(game_map.tiles):
                break
            row = game_map.tiles[global_ty]
            for local_tx in range(cx_tiles):
                global_tx = chunk_tx * CHUNK_SIZE + local_tx
                if global_tx >= len(row):
                    break
                tid = row[global_tx]
                c = _get_tile_color(tid)
                px = local_tx * TS
                py = (cy_tiles - 1 - local_ty) * TS

                draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))

                rng = random.Random(global_tx * 9973 + global_ty * 1013)
                jitter = rng.randint(-6, 6)
                if jitter != 0:
                    jc = (max(0, min(255, c[0] + jitter)),
                          max(0, min(255, c[1] + jitter)),
                          max(0, min(255, c[2] + jitter)))
                    draw.rectangle([px + 1, py + 1, px + TS - 1, py + TS - 1], fill=(*jc, 255))

                palette = TILE_PALETTE.get(tid) or TILE_PALETTE.get(0) or {"detail": (100, 100, 100), "accent": (150, 150, 150)}
                detail = palette["detail"]
                accent = palette["accent"]

                if tid in WATER_TIDS:
                    draw_water_tile(draw, px, py, TS, c, lighten(c, 30), seed=global_tx * 1000 + global_ty)

                elif tid == 51:
                    _draw_tree_pine(draw, px, py, c, detail)
                elif tid == 52:
                    _draw_tree_willow(draw, px, py, c, detail)
                elif tid == 53:
                    _draw_tree_bamboo(draw, px, py, c, detail)
                elif tid == 54:
                    _draw_tree_dead(draw, px, py, c, detail)
                elif tid == 4:
                    _draw_tree_pine(draw, px, py, c, detail)
                elif tid == 26:
                    _draw_tree_bamboo(draw, px, py, c, detail)

                elif tid in PLANT_TIDS:
                    _draw_plant(draw, px, py, c, detail, accent)

                elif tid in FLOWER_TIDS:
                    _draw_flower(draw, px, py, c, detail, accent)

                elif tid in COUNTER_TIDS:
                    _draw_counter(draw, px, py, c, detail, accent, tid)

                elif tid in DESK_TIDS:
                    _draw_desk(draw, px, py, c, detail, accent, tid)

                elif tid in BENCH_TIDS:
                    _draw_bench(draw, px, py, c, detail, accent, tid)

                elif tid in SHELF_TIDS:
                    _draw_shelf(draw, px, py, c, detail, accent, tid)

                elif tid in SCULPTURE_TIDS:
                    _draw_sculpture(draw, px, py, c, detail, accent, tid)

                elif tid in HILL_TIDS:
                    _draw_hill(draw, px, py, c, detail, accent, tid)

                elif tid in STONE_TIDS:
                    _draw_stone(draw, px, py, c, detail, accent, tid)

                elif tid in WALL_TIDS:
                    if tid == 81:
                        for bx in range(px + 8, px + TS - 4, 10):
                            draw.line([bx, py + 4, bx, py + TS - 4], fill=(*c, 255), width=3)
                        draw.line([px + 4, py + 4, px + TS - 4, py + 4], fill=(*c, 255), width=2)
                        draw.line([px + 4, py + TS - 4, px + TS - 4, py + TS - 4], fill=(*c, 255), width=2)
                    else:
                        _draw_wall_variant(draw, px, py, c, detail, accent, tid)

                elif tid in BUILDING_TIDS:
                    bc = BUILDING_COLORS.get("default", BUILDING_COLORS["default"])
                    if tid == 90:
                        bc = {"wall": (135, 108, 68), "roof": (120, 90, 50), "door": (100, 70, 40)}
                    wall_c = bc["wall"]
                    roof_c = bc["roof"]
                    door_c = bc.get("door", (100, 70, 40))
                    draw.rectangle([px + 2, py + 2, px + TS - 2, py + TS - 2], fill=(*wall_c, 255))
                    draw.rectangle([px + 2, py + int(TS * 0.55), px + TS - 2, py + TS - 2], fill=(*roof_c, 255))
                    roof_top = py + int(TS * 0.55)
                    draw.polygon([(px - 2, roof_top + 3), (px + TS // 2, roof_top - 8), (px + TS + 2, roof_top + 3)],
                                  fill=(*darken(roof_c, 15), 255))
                    draw.line([(px - 2, roof_top + 3), (px + TS // 2, roof_top - 8)], fill=(*darken(roof_c, 30), 255), width=1)
                    draw.line([(px + TS + 2, roof_top + 3), (px + TS // 2, roof_top - 8)], fill=(*darken(roof_c, 30), 255), width=1)
                    draw.line([(px - 2, roof_top + 3), (px + TS + 2, roof_top + 3)], fill=(*darken(roof_c, 25), 255), width=2)
                    pillar_c = (150, 60, 40)
                    draw.rectangle([px + 4, roof_top + 3, px + 7, py + TS - 4], fill=(*pillar_c, 255))
                    draw.rectangle([px + TS - 7, roof_top + 3, px + TS - 4, py + TS - 4], fill=(*pillar_c, 255))
                    door_w = TS // 4
                    door_x = px + TS // 2 - door_w // 2
                    door_y = roof_top + 5
                    draw.rectangle([door_x, door_y, door_x + door_w, py + TS - 4], fill=(*door_c, 255))
                    draw.arc([door_x, door_y - 4, door_x + door_w, door_y + 4], 180, 360, fill=(*darken(door_c, 20), 255), width=1)
                    win_c = (200, 210, 230)
                    win_s = TS // 7
                    for wx_off in [-TS // 4, TS // 4]:
                        wx = px + TS // 2 + wx_off - win_s // 2
                        wy = roof_top + TS // 5
                        draw.rectangle([wx, wy, wx + win_s, wy + win_s], fill=(*win_c, 220))
                        draw.line([wx + win_s // 2, wy, wx + win_s // 2, wy + win_s], fill=(*darken(win_c, 40), 220), width=1)
                        draw.line([wx, wy + win_s // 2, wx + win_s, wy + win_s // 2], fill=(*darken(win_c, 40), 220), width=1)

                elif tid == 50:
                    cx_p = px + TS // 2
                    draw.rectangle([cx_p - 5, py + 4, cx_p + 5, py + TS - 4], fill=(*c, 255))
                    draw.rectangle([cx_p - 8, py + 2, cx_p + 8, py + 8], fill=(*lighten(c, 15), 255))
                    draw.rectangle([cx_p - 8, py + TS - 8, cx_p + 8, py + TS - 2], fill=(*lighten(c, 10), 255))

                elif tid == 82:
                    draw.rectangle([px + 8, py + 14, px + TS - 8, py + TS - 6], fill=(*c, 255))
                    draw.rectangle([px + 8, py + 10, px + TS - 8, py + 16], fill=(*accent, 255))
                    draw.rectangle([px + 10, py + 8, px + 18, py + 14], fill=(220, 215, 210))

                elif tid == 83:
                    draw.rectangle([px + 4, py + 8, px + TS - 4, py + TS - 4], fill=(*c, 255))
                    draw.rectangle([px + 4, py + 6, px + TS - 4, py + 10], fill=(*accent, 255))
                    draw.line([px + 4, py + 10, px + TS - 4, py + 10], fill=(*darken(c, 20), 255), width=2)

                elif tid == 84:
                    cx_b = px + TS // 2
                    draw.rectangle([px + 2, py + TS // 2, px + TS - 2, py + TS - 2], fill=(160, 145, 120))
                    draw.arc([px + 4, py + TS // 4, px + TS - 4, py + TS // 2 + 8], 180, 360, fill=(140, 125, 100), width=3)
                    for rail_x in [px + 8, px + TS - 8]:
                        draw.rectangle([rail_x - 1, py + TS // 4 - 4, rail_x + 1, py + TS // 2], fill=(120, 105, 80))
                    draw.line([px + 6, py + TS // 2 - 2, px + TS - 6, py + TS // 2 - 2], fill=(130, 115, 90), width=1)

                elif tid == 85:
                    draw.rectangle([px + 14, py + 16, px + TS - 14, py + TS - 10], fill=(*c, 255))
                    draw.line([px + 16, py + 18, px + 22, py + 18], fill=(*accent, 255), width=1)
                    draw.line([px + 16, py + 22, px + 20, py + 22], fill=(*accent, 255), width=1)

                elif tid == 86:
                    cx_br = px + TS // 2
                    draw.line([cx_br, py + 10, cx_br, py + TS - 8], fill=(*c, 255), width=2)
                    draw.line([cx_br, py + 10, cx_br + 14, py + 20], fill=(*detail, 255), width=2)
                    draw.line([cx_br, py + 14, cx_br + 12, py + 22], fill=(*detail, 255), width=1)

                elif tid == 87:
                    draw.ellipse([px + 16, py + 14, px + TS - 16, py + TS - 10], fill=(*c, 255))
                    draw.arc([px + 16, py + 10, px + TS - 16, py + 20], 0, 180, fill=(*accent, 255), width=2)

                elif tid == 88:
                    for i in range(3):
                        lx = px + 10 + i * 16
                        draw.rectangle([lx, py + 20, lx + 12, py + TS - 8], fill=(*c, 255))
                        draw.ellipse([lx - 2, py + 16, lx + 14, py + 24], fill=(*accent, 255))

                elif tid == 89:
                    draw.rectangle([px + 6, py + 20, px + TS - 6, py + TS - 8], fill=(*c, 255))
                    draw.rectangle([px + 8, py + 22, px + TS - 8, py + TS - 10], fill=(*lighten(c, 10), 255))

                elif tid == 91:
                    for by in range(py + 2, py + TS - 2, 8):
                        offset = 0 if (by - py) // 8 % 2 == 0 else TS // 4
                        for bx in range(px + 2 + offset, px + TS - 2, TS // 2):
                            draw.rectangle([bx, by, bx + TS // 2 - 3, by + 6], fill=(*c, 255))
                            draw.rectangle([bx + 1, by + 1, bx + TS // 2 - 4, by + 5], fill=(*lighten(c, 8), 255))

                elif tid == 92:
                    cx_f = px + TS // 2
                    cy_f = py + TS // 2
                    draw.ellipse([cx_f - 10, cy_f - 4, cx_f + 10, cy_f + 4], fill=(*accent, 255))
                    draw.polygon([(cx_f - 6, cy_f), (cx_f - 2, cy_f - 6), (cx_f + 6, cy_f), (cx_f + 2, cy_f + 6)], fill=(*detail, 255))
                    draw.ellipse([cx_f - 4, cy_f - 4, cx_f, cy_f], fill=(30, 30, 30))

                elif tid == 21:
                    cx_w = px + TS // 2
                    cy_w = py + TS // 2
                    draw.ellipse([cx_w - 12, cy_w - 12, cx_w + 12, cy_w + 12], fill=(100, 140, 180))
                    draw.ellipse([cx_w - 8, cy_w - 8, cx_w + 8, cy_w + 8], fill=(80, 120, 160))
                    draw.rectangle([cx_w - 2, cy_w - 14, cx_w + 2, cy_w - 8], fill=(120, 100, 80))

                elif tid == 28:
                    draw.rectangle([px + 6, py + 6, px + TS - 6, py + TS - 6], fill=(*detail, 255))
                    draw.arc([px + 10, py + 2, px + TS - 10, py + 14], 180, 360, fill=(*darken(detail, 20), 255), width=2)

                elif tid == 34:
                    draw.rectangle([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(140, 120, 100))
                    for i in range(3):
                        draw.line([px + 4, py + 8 + i * 16, px + TS - 4, py + 8 + i * 16], fill=(160, 140, 110), width=1)
                    draw.rectangle([px + 8, py + 8, px + TS - 8, py + TS - 8], outline=(180, 160, 120))

                elif tid == 41:
                    draw.rectangle([px + 8, py + 4, px + TS - 8, py + TS - 4], fill=(60, 60, 70))
                    for i in range(4):
                        bx = px + 8 + i * 14
                        draw.line([bx, py + 4, bx, py + TS - 4], fill=(100, 100, 110), width=2)

                elif tid == 42:
                    draw.rectangle([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(*c, 255))
                    for i in range(3):
                        lx = px + 10 + i * 16
                        draw.ellipse([lx, py + 10, lx + 12, py + 22], fill=(255, 140, 40))

                elif tid == 46:
                    mx_c = px + TS // 2
                    my_c = py + 8
                    draw.rectangle([mx_c - 2, my_c, mx_c + 2, my_c + 10], fill=(200, 180, 150))
                    draw.ellipse([mx_c - 6, my_c + 6, mx_c + 6, my_c + 18], fill=(*accent, 255))

                elif tid == 37:
                    draw.polygon([(px + TS // 2, py + 8), (px + 12, py + TS - 8), (px + TS - 12, py + TS - 8)], fill=(*c, 255))
                    draw.ellipse([px + 20, py + 20, px + 30, py + 30], fill=(255, 200, 50))
                    draw.ellipse([px + 28, py + 16, px + 36, py + 26], fill=(255, 150, 30))

                elif tid == 29:
                    draw.rectangle([px + TS // 2 - 2, py + 8, px + TS // 2 + 2, py + TS - 4], fill=(100, 80, 60))
                    draw.ellipse([px + TS // 2 - 8, py + 4, px + TS // 2 + 8, py + 14], fill=(255, 200, 80))

                elif tid == 30:
                    draw.rectangle([px + 12, py + 20, px + TS - 12, py + TS - 8], fill=(140, 120, 90))
                    draw.rectangle([px + 10, py + 18, px + TS - 10, py + 22], fill=(160, 140, 100))
                    draw.rectangle([px + 14, py + 10, px + 18, py + 20], fill=(120, 100, 70))

                elif tid == 23:
                    draw.rectangle([px + 12, py + 12, px + TS - 12, py + TS - 8], fill=(*c, 255))
                    draw.rectangle([px + 10, py + 10, px + TS - 10, py + 14], fill=(*accent, 255))
                    draw.arc([px + 18, py + 8, px + 28, py + 16], 0, 180, fill=(200, 180, 80), width=2)

                elif tid == 24:
                    draw.rectangle([px + 8, py + 12, px + TS - 8, py + TS - 6], fill=(*c, 255))
                    draw.ellipse([px + TS // 2 - 6, py + 8, px + TS // 2 + 6, py + 16], fill=(*accent, 255))

                elif tid == 25:
                    draw.rectangle([px + 6, py + 10, px + TS - 6, py + TS - 6], fill=(*c, 255))
                    draw.line([px + 6, py + 10, px + TS - 6, py + TS - 6], fill=(*detail, 255), width=2)
                    draw.line([px + TS - 6, py + 10, px + 6, py + TS - 6], fill=(*detail, 255), width=2)

                elif tid == 36:
                    draw.rectangle([px + 14, py + 12, px + TS - 14, py + TS - 8], fill=(120, 120, 130))
                    draw.rectangle([px + 12, py + 10, px + TS - 12, py + 14], fill=(140, 140, 150))

                elif tid == 38:
                    draw.rectangle([px + 14, py + 14, px + TS - 14, py + TS - 6], fill=(140, 140, 140))
                    draw.ellipse([px + 18, py + 8, px + 26, py + 16], fill=(100, 100, 100))
                    draw.line([px + 14, py + 10, px + 22, py + 18], fill=(120, 120, 120), width=1)

                elif tid == 39:
                    for ry in range(py + 4, py + TS - 4, 8):
                        for rx in range(px + 4, px + TS - 4, 8):
                            draw.ellipse([rx, ry, rx + 6, ry + 6], fill=(180, 200, 80))

                elif tid == 40:
                    for sy in range(py + 2, py + TS - 2, 6):
                        for sx in range(px + 2, px + TS - 2, 6):
                            draw.rectangle([sx, sy, sx + 4, sy + 4], fill=(*lighten(c, 5), 255))

                elif tid == 43:
                    draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))
                    for sy in range(py + 4, py + TS - 4, 8):
                        draw.line([px + 4, sy, px + TS - 4, sy], fill=(*darken(c, 10), 100), width=1)

                elif tid == 44:
                    draw.ellipse([px + 16, py + 16, px + TS - 16, py + TS - 16], fill=(*c, 255))
                    draw.ellipse([px + 20, py + 12, px + 28, py + 20], fill=(*detail, 255))
                    draw.rectangle([px + TS // 2 - 2, py + 8, px + TS // 2 + 2, py + 18], fill=(180, 160, 120))

                elif tid == 45:
                    draw.rectangle([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(*c, 255))
                    draw.line([px + 4, py + TS // 3, px + TS - 4, py + TS // 3], fill=(*darken(c, 15), 255), width=2)
                    draw.line([px + TS // 3, py + 4, px + TS // 3, py + TS - 4], fill=(*darken(c, 10), 255), width=1)

                elif tid == 47:
                    draw.rectangle([px + 8, py + 8, px + TS - 8, py + TS - 4], fill=(*c, 255))
                    draw.rectangle([px + 6, py + 6, px + TS - 6, py + 10], fill=(*accent, 255))
                    draw.ellipse([px + TS // 2 - 6, py + 12, px + TS // 2 + 6, py + 20], fill=(*detail, 255))

                elif tid == 48:
                    draw.rectangle([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(*c, 255))
                    for by in range(py + 8, py + TS - 4, 8):
                        draw.line([px + 4, by, px + TS - 4, by], fill=(*darken(c, 10), 255), width=1)

                elif tid == 49:
                    draw.rectangle([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(*c, 255))
                    draw.ellipse([px + 8, py + 8, px + TS - 8, py + TS - 8], fill=(*accent, 255))
                    draw.line([px + 4, py + 4, px + TS - 4, py + TS - 4], fill=(*detail, 255), width=2)

                elif tid == 107:
                    draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))
                    for sy in range(py + 4, py + TS - 2, 10):
                        offset = 0 if (sy - py) // 10 % 2 == 0 else 5
                        for sx in range(px + 2 + offset, px + TS - 2, 10):
                            draw.rectangle([sx, sy, sx + 8, sy + 8], outline=(*darken(c, 8), 120), width=1)

                elif tid == 7:  # Bridge - 木质桥梁
                    plank_c = (140, 115, 80)
                    rail_c = (100, 78, 50)
                    shadow_c = (70, 55, 35)
                    # 桥面阴影
                    draw.rectangle([px + 2, py + TS // 2 - 2, px + TS - 2, py + TS - 2], fill=(*shadow_c, 100))
                    # 横向木板
                    for by in range(py + TS // 2, py + TS - 2, 6):
                        shade = 1.0 - abs((by - py - TS // 2) / (TS // 2) - 0.5) * 0.3
                        bc = tuple(int(plank_c[i] * shade) for i in range(3))
                        draw.rectangle([px + 3, by, px + TS - 3, by + 4], fill=(*bc, 255))
                        # 木板纹理
                        draw.line([px + 4, by + 2, px + TS - 4, by + 2], fill=(*darken(plank_c, 15), 100), width=1)
                    # 桥面纵向中缝
                    draw.line([px + TS // 2, py + TS // 2, px + TS // 2, py + TS - 2], fill=(*darken(plank_c, 20), 180), width=2)
                    # 栏杆柱
                    for bx in range(px + 4, px + TS - 2, TS // 3):
                        draw.rectangle([bx - 1, py + TS // 2 - 2, bx + 1, py + TS // 2 + 6], fill=(*rail_c, 255))
                    # 栏杆横梁
                    draw.line([px + 4, py + TS // 2 - 1, px + TS - 4, py + TS // 2 - 1], fill=(*lighten(rail_c, 15), 255), width=2)
                    # 桥下水面
                    water_c = (60, 100, 160, 120)
                    for wy in range(py, py + TS // 2, 4):
                        for wx in range(px, px + TS, 8):
                            draw.rectangle([wx, wy, wx + 8, wy + 4], fill=water_c)

                elif tid == 10:  # Stone Road - 石板路 (青石铺就)
                    # 基底
                    draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))
                    # 不规则石板纹理
                    rng_road = random.Random(global_tx * 7777 + global_ty * 3337)
                    stone_color1 = lighten(c, 12)
                    stone_color2 = darken(c, 8)
                    stone_color3 = (c[0] + 8, c[1] + 5, c[2] - 5)
                    # 石板分块 - 用不规则的矩形模拟青石板
                    for _ in range(6):
                        sx = px + rng_road.randint(2, TS - 16)
                        sy = py + rng_road.randint(2, TS - 16)
                        sw = rng_road.randint(10, 20)
                        sh = rng_road.randint(8, 14)
                        sc = rng_road.choice([stone_color1, stone_color2, stone_color3])
                        draw.rectangle([sx, sy, sx + sw, sy + sh], fill=(*sc, 200))
                        # 石板边缘深色缝隙
                        draw.rectangle([sx, sy, sx + sw, sy + sh], outline=(*darken(c, 15), 120), width=1)
                    # 路面纹理(细碎石)
                    for _ in range(8):
                        gx = px + rng_road.randint(3, TS - 4)
                        gy = py + rng_road.randint(3, TS - 4)
                        gs = rng_road.choice([lighten(c, 20), darken(c, 12)])
                        draw.rectangle([gx, gy, gx + 2, gy + 2], fill=(*gs, 150))
                    # 路面中线(若有)
                    if global_tx % 3 == 0:
                        draw.line([px + TS // 2, py + 2, px + TS // 2, py + TS - 2], fill=(*darken(c, 10), 60), width=1)

                elif tid == 106:  # Dirt Road (新土路)
                    draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))
                    rng_dirt = random.Random(global_tx * 5551 + global_ty * 2221)
                    # 泥土纹理
                    for _ in range(10):
                        dx = px + rng_dirt.randint(2, TS - 4)
                        dy = py + rng_dirt.randint(2, TS - 4)
                        dc = rng_dirt.choice([lighten(c, 10), darken(c, 8), (*c, 255)])
                        draw.rectangle([dx, dy, dx + 4, dy + 4], fill=(*dc[:3], 130))
                    # 车辙印
                    draw.line([px + TS // 3, py + 2, px + TS // 3, py + TS - 2], fill=(*darken(c, 18), 100), width=3)
                    draw.line([px + 2 * TS // 3, py + 2, px + 2 * TS // 3, py + TS - 2], fill=(*darken(c, 18), 100), width=3)

                elif tid == 1:  # Dirt Road (old)
                    draw.rectangle([px, py, px + TS, py + TS], fill=(*c, 255))
                    rng_dr = random.Random(global_tx * 1123 + global_ty * 4567)
                    for _ in range(12):
                        dx = px + rng_dr.randint(2, TS - 4)
                        dy = py + rng_dr.randint(2, TS - 4)
                        draw.rectangle([dx, dy, dx + 3, dy + 3], fill=(*detail[:3], 120))

                elif tid == 20:  # Gate - 城门/院门
                    # 宏伟城门
                    gate_w = TS // 2
                    gate_h = TS - 12
                    gate_x = px + TS // 2 - gate_w // 2
                    gate_y = py + 6
                    # 门洞
                    draw.rectangle([gate_x, gate_y, gate_x + gate_w, gate_y + gate_h], fill=(40, 30, 20))
                    # 门框
                    for i in range(3):
                        a = 255 - i * 50
                        draw.rectangle([gate_x - i - 2, gate_y - i - 2, gate_x + gate_w + i + 2, gate_y + gate_h + i + 2],
                                      outline=(*lighten(c, 15), a), width=1)
                    # 穹顶弧线
                    draw.arc([gate_x - 4, gate_y - gate_h // 5, gate_x + gate_w + 4, gate_y + gate_h // 4], 180, 360,
                            fill=(*accent, 255), width=3)
                    # 门钉
                    for gdx in range(gate_x + 6, gate_x + gate_w - 4, 8):
                        for gdy in range(gate_y + 6, gate_y + gate_h - 6, 10):
                            draw.ellipse([gdx, gdy, gdx + 3, gdy + 3], fill=(200, 180, 50))
                    # 门槛
                    draw.rectangle([gate_x - 2, gate_y + gate_h, gate_x + gate_w + 2, gate_y + gate_h + 4],
                                  fill=(*darken(c, 15), 255))
                    # 门环
                    ring_x = gate_x + gate_w // 2
                    ring_y = gate_y + gate_h // 3
                    draw.ellipse([ring_x - 4, ring_y - 4, ring_x + 4, ring_y + 4], fill=(200, 170, 60))
                    draw.ellipse([ring_x - 2, ring_y - 2, ring_x + 2, ring_y + 2], fill=(180, 150, 40))

                elif tid == 33:
                    draw.rectangle([px + 8, py + 8, px + TS - 8, py + TS - 8], fill=(*c, 255))
                    for i in range(4):
                        draw.line([px + 8, py + 12 + i * 10, px + TS - 8, py + 12 + i * 10], fill=(*detail, 255), width=1)

                elif tid == 32:
                    draw.ellipse([px + 8, py + 8, px + TS - 8, py + TS - 8], fill=(80, 120, 160))
                    draw.ellipse([px + 12, py + 12, px + TS - 12, py + TS - 12], fill=(60, 100, 140))

                if tid == 0 or tid == 5 or tid == 7 or tid == 11 or tid == 31 or tid == 33 or tid == 37 or tid == 38 or tid == 42:
                    draw_grass_detail(draw, px, py, TS, c, detail, seed=global_tx * 100 + global_ty)

                if tid in ROAD_TIDS:
                    draw_road_detail(draw, px, py, TS, c, detail, seed=global_tx * 100 + global_ty)

                if tid in TREE_TIDS:
                    draw_soft_shadow(draw, px + TS // 2, py + TS // 2 + 10, 20, 8, alpha=30)

                if tid in BUILDING_TIDS:
                    draw_soft_shadow(draw, px + TS // 2, py + TS + 2, TS - 8, 8, alpha=35)

        _draw_terrain_transitions(draw, game_map, chunk_tx, chunk_ty, cx_tiles, cy_tiles, map_h)

        # ── 水墨风格叠加层 ──
        if VISUAL_CONFIG.get("ink_style_enabled", False):
            ink_gen = InkTextureGenerator(tile_size=TS)
            ink_opacity = VISUAL_CONFIG.get("ink_style_opacity", 0.35)
            # tile type -> ink generator method mapping
            _INK_DISPATCH = {
                0:  ("grass",      ink_gen.generate_ink_grass),
                2:  ("water",      ink_gen.generate_ink_water),
                10: ("stone_road", ink_gen.generate_ink_stone_road),
            }
            for local_ty in range(cy_tiles):
                global_ty = chunk_ty * CHUNK_SIZE + local_ty
                if global_ty >= len(game_map.tiles):
                    break
                row = game_map.tiles[global_ty]
                for local_tx in range(cx_tiles):
                    global_tx = chunk_tx * CHUNK_SIZE + local_tx
                    if global_tx >= len(row):
                        break
                    tid = row[global_tx]
                    entry = _INK_DISPATCH.get(tid)
                    if entry is None:
                        continue
                    _name, gen_fn = entry
                    seed = global_tx * 1000 + global_ty
                    ink_tex = gen_fn(seed=seed)
                    if ink_tex is None:
                        continue
                    # 降低整体alpha到指定不透明度
                    r_ch, g_ch, b_ch, a_ch = ink_tex.split()
                    a_ch = a_ch.point(lambda v: int(v * ink_opacity))
                    ink_tex = Image.merge('RGBA', (r_ch, g_ch, b_ch, a_ch))
                    px = local_tx * TS
                    py = (cy_tiles - 1 - local_ty) * TS
                    img.paste(ink_tex, (px, py), ink_tex)

        img = apply_texture_noise(img, intensity=0.04, seed=chunk_tx * 1000 + chunk_ty)
        img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
        texture = arcade.Texture(img)
        return texture, img_w, img_h
    except ImportError:
        return None


def draw_map(camera_x: float, camera_y: float, game_map: Optional[Map]):
    if not game_map or not game_map.tiles:
        arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (80, 160, 80))
        return

    map_w = len(game_map.tiles[0]) if game_map.tiles else 0
    map_h = len(game_map.tiles)
    chunks_x = (map_w + CHUNK_SIZE - 1) // CHUNK_SIZE
    chunks_y = (map_h + CHUNK_SIZE - 1) // CHUNK_SIZE

    vx_min, vx_max = camera_x - SW / 2, camera_x + SW / 2
    vy_min, vy_max = camera_y - SH / 2, camera_y + SH / 2

    start_cx = max(0, int(vx_min / (CHUNK_SIZE * TS)) - 1)
    end_cx = min(chunks_x, int(vx_max / (CHUNK_SIZE * TS)) + 2)
    start_cy = max(0, int((map_h * TS - vy_max) / (CHUNK_SIZE * TS)) - 1)
    end_cy = min(chunks_y, int((map_h * TS - vy_min) / (CHUNK_SIZE * TS)) + 2)

    for cy in range(start_cy, end_cy):
        for cx in range(start_cx, end_cx):
            cache_key = (cx, cy, game_map.id if hasattr(game_map, 'id') else id(game_map))
            if cache_key not in _chunk_cache:
                result = _render_chunk_to_texture(game_map, cx, cy, map_h)
                if result:
                    _chunk_cache[cache_key] = result
                else:
                    continue

            texture, img_w, img_h = _chunk_cache[cache_key]
            world_x = cx * CHUNK_SIZE * TS
            world_y = (map_h - (cy + 1) * CHUNK_SIZE) * TS
            sx, sy = world_to_screen(world_x, world_y, camera_x, camera_y)

            if sx + img_w < 0 or sx > SW or sy + img_h < 0 or sy > SH:
                continue

            arcade.draw_texture_rect(texture, arcade.LBWH(sx, sy, img_w, img_h))

    _draw_building_labels(camera_x, camera_y, game_map)
    _draw_lighting_overlay(camera_x, camera_y)
    get_advanced_lights().draw(camera_x, camera_y)


def _draw_building_labels(camera_x, camera_y, game_map):
    labels = game_map.labels if hasattr(game_map, 'labels') else []
    for label in labels:
        lx, ly, text = label[0], label[1], label[2]
        fk = label[3] if len(label) > 3 else "default"
        building_type = label[4] if len(label) > 4 else ""
        wx, wy = map_to_world(lx, ly, len(game_map.tiles))
        sx, sy = world_to_screen(wx, wy + 1.5, camera_x, camera_y)
        if 0 <= sx <= SW and 0 <= sy <= SH:
            bc = BUILDING_COLORS.get(fk, BUILDING_COLORS["default"])
            tw, th = len(text) * 12 + 20, 26
            # 背景
            arcade.draw_rect_filled(arcade.LBWH(sx - tw / 2, sy - th / 2, tw, th), 
                                   (bc["wall"][0] // 2, bc["wall"][1] // 2, bc["wall"][2] // 2, 230))
            arcade.draw_rect_outline(arcade.LBWH(sx - tw / 2, sy - th / 2, tw, th), 
                                    (*bc["roof"][:3], 240), 2)
            # 类型小图标颜色
            type_colors = {
                "tavern": (200, 160, 80),
                "blacksmith": (140, 140, 160),
                "tailor": (160, 120, 180),
                "herbalist": (80, 160, 100),
                "temple": (220, 200, 80),
                "training": (180, 100, 60),
                "market": (100, 180, 200),
                "residence": (160, 150, 120),
            }
            dot_c = type_colors.get(building_type, bc["roof"][:3])
            arcade.draw_circle_filled(sx - tw / 2 + 8, sy, 4, (*dot_c, 240))
            arcade.draw_circle_outline(sx - tw / 2 + 8, sy, 4, (255, 255, 255, 180), 1)
            draw_text(text, sx + 2, sy, (240, 235, 215), 11, "center", "center")


def _draw_lighting_overlay(camera_x, camera_y):
    if not _LIGHT_SOURCES or not VISUAL_CONFIG.get("glow_enabled", True):
        return
    for wx, wy, radius, color, intensity in _LIGHT_SOURCES:
        sx, sy = world_to_screen(wx, wy, camera_x, camera_y)
        if -radius <= sx <= SW + radius and -radius <= sy <= SH + radius:
            for i in range(3):
                t = i / 3
                r = radius * (1 - t * 0.7)
                a = int(intensity * 50 * (1 - t))
                arcade.draw_circle_filled(sx, sy, r, (*color[:3], max(0, min(255, a))))


def invalidate_chunk_cache():
    _chunk_cache.clear()
    from . import minimap_renderer as mm
    mm._minimap_dirty = True
