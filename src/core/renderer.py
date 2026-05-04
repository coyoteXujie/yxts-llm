import arcade
import os
import math
import random
from typing import Optional, Dict, List, Tuple
from .config import (GAME_CONFIG, COLORS, UI_CONFIG, VISUAL_CONFIG,
                     TILE_PALETTE, BUILDING_COLORS, CHAR_PALETTE)
from .entities import Player, NPC, Map, Faction, NpcType, FACTION_NAMES

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TILES_DIR = os.path.join(BASE_DIR, "assets", "tiles")

SW = GAME_CONFIG["screen_width"]
SH = GAME_CONFIG["screen_height"]
TS = GAME_CONFIG["tile_size"]

FONT = "SimHei"
FONT_LATIN = "Arial"

_text_cache = {}
_tile_cache = {}
_anim_time = 0.0
_dialog_chars_shown = 999
_dialog_text_full = ""
_dialog_text_timer = 0.0
_hurt_flash = 0.0


def _draw_text(text, x, y, color, size, anchor_x="left", anchor_y="center", width=None):
    key = (text, int(x), int(y), color, size, anchor_x, anchor_y, width)
    if key not in _text_cache:
        t = arcade.Text(text, x, y, color, size, font_name=FONT,
                        anchor_x=anchor_x, anchor_y=anchor_y, width=width)
        _text_cache[key] = t
    _text_cache[key].draw()


def _map_to_world(tx: int, ty: int, map_h: int) -> tuple:
    x = tx * TS + TS / 2
    y = (map_h - 1 - ty) * TS + TS / 2
    return x, y


def _world_to_screen(wx: float, wy: float, camera_x: float, camera_y: float) -> tuple:
    sx = wx - camera_x + SW / 2
    sy = wy - camera_y + SH / 2
    return sx, sy


def set_anim_time(t: float):
    global _anim_time
    _anim_time = t


def set_hurt_flash(v: float):
    global _hurt_flash
    _hurt_flash = v


def set_dialog_text(text: str):
    global _dialog_text_full, _dialog_chars_shown, _dialog_text_timer
    if text != _dialog_text_full:
        _dialog_text_full = text
        _dialog_chars_shown = 0
        _dialog_text_timer = 0.0


def update_dialog_anim(dt: float):
    global _dialog_chars_shown, _dialog_text_timer
    if _dialog_chars_shown < len(_dialog_text_full):
        _dialog_text_timer += dt
        _dialog_chars_shown = min(len(_dialog_text_full), int(_dialog_text_timer * 30))


def _lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1[:3], c2[:3]))


def _lighten(c, amount=30):
    return tuple(min(255, v + amount) for v in c[:3])


def _darken(c, amount=30):
    return tuple(max(0, v - amount) for v in c[:3])


def _alpha(c, a):
    return (*c[:3], a)


def _draw_gradient_rect(x, y, w, h, color_top, color_bot, steps=6):
    step_h = h / steps
    for i in range(steps):
        t = i / max(1, steps - 1)
        c = _lerp_color(color_top, color_bot, t)
        arcade.draw_rect_filled(arcade.LBWH(x, y + h - (i + 1) * step_h, w, step_h + 1), c)


# ──────────────────────────────────────────────
#  地图渲染
# ──────────────────────────────────────────────

WALKABLE_TIDS = {0, 5, 6, 7, 10, 11, 12, 13, 14, 15, 21, 22, 23, 24, 25, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 42, 43, 44, 45, 46}
WATER_TIDS = {1, 27, 40}
WALL_TIDS = {2, 3, 8, 9, 16, 17, 18, 19, 20, 26, 41, 47, 48, 49}
TREE_TIDS = {4, 11, 22, 31, 44}
BUILDING_TIDS = {3, 8, 9, 13, 14, 15, 16, 17, 18, 19, 20, 26, 47, 48, 49}
ROAD_TIDS = {6, 10, 12, 24, 28, 30, 34, 35, 36, 45, 46}
SPECIAL_TIDS = {41, 49}

_LIGHT_SOURCES = []


def add_light_source(wx, wy, radius=120, color=(255, 200, 100), intensity=0.5):
    _LIGHT_SOURCES.append((wx, wy, radius, color, intensity))


def clear_light_sources():
    _LIGHT_SOURCES.clear()


def draw_map(camera_x: float, camera_y: float, game_map: Optional[Map]):
    if not game_map or not game_map.tiles:
        arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (80, 160, 80))
        return

    map_w = len(game_map.tiles[0]) if game_map.tiles else 0
    map_h = len(game_map.tiles)

    vis_world_xmin = camera_x - SW / 2
    vis_world_xmax = camera_x + SW / 2
    vis_world_ymin = camera_y - SH / 2
    vis_world_ymax = camera_y + SH / 2

    start_tx = max(0, int(vis_world_xmin // TS) - 1)
    end_tx = min(map_w, int(vis_world_xmax // TS) + 2)
    start_ty = max(0, int((map_h - 1) - (vis_world_ymax // TS)) - 1)
    end_ty = min(map_h, int((map_h - 1) - (vis_world_ymin // TS)) + 2)

    for ty in range(start_ty, end_ty):
        if ty < 0 or ty >= map_h:
            continue
        row = game_map.tiles[ty]
        for tx in range(start_tx, end_tx):
            if tx < 0 or tx >= len(row):
                continue
            tid = row[tx]
            world_x, world_y = _map_to_world(tx, ty, map_h)
            sx, sy = _world_to_screen(world_x, world_y, camera_x, camera_y)
            left = sx - TS / 2
            bottom = sy - TS / 2
            _render_tile(tid, left, bottom, tx, ty, game_map, ty, tx)

    _draw_building_labels(camera_x, camera_y, game_map)
    _draw_lighting_overlay(camera_x, camera_y)


def _get_neighbor_tids(game_map, ty, tx):
    result = {}
    for dy, dx, name in [(-1, 0, "n"), (1, 0, "s"), (0, -1, "w"), (0, 1, "e")]:
        ny, nx = ty + dy, tx + dx
        if 0 <= ny < len(game_map.tiles) and 0 <= nx < len(game_map.tiles[ny]):
            result[name] = game_map.tiles[ny][nx]
        else:
            result[name] = -1
    return result


def _draw_lighting_overlay(camera_x, camera_y):
    if not _LIGHT_SOURCES or not VISUAL_CONFIG.get("glow_enabled", True):
        return
    for wx, wy, radius, color, intensity in _LIGHT_SOURCES:
        sx, sy = _world_to_screen(wx, wy, camera_x, camera_y)
        if -radius <= sx <= SW + radius and -radius <= sy <= SH + radius:
            steps = 5
            for i in range(steps):
                t = i / steps
                r = radius * (1 - t * 0.8)
                a = int(intensity * 60 * (1 - t))
                arcade.draw_circle_filled(sx, sy, r, (*color[:3], max(0, min(255, a))))


def _render_tile(tid: int, left: float, bottom: float, tx: int, ty: int,
                 game_map: Optional[Map] = None, row: int = 0, col: int = 0):
    cx = left + TS / 2
    cy = bottom + TS / 2
    palette = TILE_PALETTE.get(tid, TILE_PALETTE.get(0))
    base = palette["base"]
    detail = palette["detail"]
    accent = palette["accent"]
    seed = tx * 7 + ty * 13
    rng = random.Random(seed)

    if tid in WATER_TIDS:
        _render_water(tid, left, bottom, tx, ty, base, detail, accent, rng)
    elif tid in TREE_TIDS:
        _render_ground(tid, left, bottom, tx, ty, base, detail, accent, rng)
        _render_tree(left, bottom, cx, cy, rng, tid)
    elif tid == 3:
        _render_building_house(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 8:
        _render_building_tower(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 9:
        _render_building_gate(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 13:
        _render_building_wall(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 14:
        _render_building_stall(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 15:
        _render_building_tower(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 16:
        _render_building_wall(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 17:
        _render_building_house(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 18:
        _render_building_wall(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 19:
        _render_building_house(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 20:
        _render_building_wall(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 26:
        _render_building_altar(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid in (41, 49):
        _render_special_glow(tid, left, bottom, cx, cy, base, detail, accent, rng, tx)
    elif tid == 47:
        _render_building_prison(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 48:
        _render_building_arena(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid in ROAD_TIDS:
        _render_road(tid, left, bottom, tx, ty, base, detail, accent, rng)
    elif tid == 2:
        _render_wall_solid(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid in (39, 40):
        _render_snow(tid, left, bottom, tx, ty, base, detail, accent, rng)
    elif tid == 42:
        _render_swamp(left, bottom, cx, cy, base, detail, accent, rng)
    elif tid == 43:
        _render_mushroom(left, bottom, cx, cy, base, detail, accent, rng)
    else:
        _render_ground(tid, left, bottom, tx, ty, base, detail, accent, rng)

    if VISUAL_CONFIG["shadow_enabled"] and tid not in WATER_TIDS and tid not in SPECIAL_TIDS:
        arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, 2), (0, 0, 0, 12))


def _render_ground(tid, left, bottom, tx, ty, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _lighten(base, 8), _darken(base, 5), 4)
    for i in range(4):
        gx = left + rng.randint(4, TS - 4)
        gy = bottom + rng.randint(4, TS - 4)
        r = rng.uniform(1, 3)
        arcade.draw_circle_filled(gx, gy, r, detail)
    for i in range(3):
        gx = left + rng.randint(6, TS - 6)
        gy = bottom + rng.randint(6, TS - 6)
        gh = rng.randint(3, 10)
        lean = rng.randint(-2, 2)
        arcade.draw_line(gx, gy, gx + lean, gy - gh, detail, 1)
        arcade.draw_circle_filled(gx + lean, gy - gh, 1.5, accent)
    for i in range(rng.randint(0, 4)):
        fx = left + rng.randint(6, TS - 6)
        fy = bottom + rng.randint(6, TS - 6)
        fc = rng.choice([(255, 255, 120), (255, 180, 180), (180, 180, 255),
                         (255, 255, 255), (255, 200, 100)])
        petal_count = rng.randint(4, 6)
        for p in range(petal_count):
            angle = p * math.pi * 2 / petal_count
            px = fx + math.cos(angle) * 2
            py = fy + math.sin(angle) * 2
            arcade.draw_circle_filled(px, py, 1, fc)
        arcade.draw_circle_filled(fx, fy, 1, (255, 220, 80))
    highlight_y = bottom + TS - 2
    arcade.draw_line(left + 2, highlight_y, left + TS - 2, highlight_y,
                     _alpha(_lighten(base, 15), 30), 1)


def _render_water(tid, left, bottom, tx, ty, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _lighten(base, 10), _darken(base, 8), 4)
    wave = math.sin(_anim_time * 1.8 + tx * 0.6 + ty * 0.4)
    for i in range(6):
        wy = bottom + 5 + i * 10 + wave * 3 * (1 if i % 2 == 0 else -1)
        a = 50 + i * 12 + int(wave * 20)
        arcade.draw_line(left + 3, wy, left + TS - 3, wy,
                         _alpha(accent, max(0, min(255, a))), 1)
    for i in range(3):
        sx = left + rng.randint(8, TS - 8)
        sy = bottom + rng.randint(8, TS - 8)
        sparkle = int(abs(math.sin(_anim_time * 2.5 + sx * 0.1 + sy * 0.1)) * 140)
        if sparkle > 25:
            arcade.draw_circle_filled(sx, sy, 1.5, (255, 255, 255, sparkle))
    reflect_a = int(15 + 10 * math.sin(_anim_time * 1.2 + tx))
    arcade.draw_rect_filled(arcade.LBWH(left + 8, bottom + TS // 2 - 2, TS - 16, 4),
                            (255, 255, 255, reflect_a))
    shore_color = _lighten(base, 25)
    arcade.draw_line(left + 1, bottom + TS - 1, left + TS - 1, bottom + TS - 1,
                     _alpha(shore_color, 50), 2)
    arcade.draw_line(left + 1, bottom + 1, left + 1, bottom + TS - 1,
                     _alpha(shore_color, 30), 1)


def _render_tree(left, bottom, cx, cy, rng, tid=4):
    sway = math.sin(_anim_time * 1.2 + cx * 0.01) * 2
    trunk_w = 6
    trunk_h = 20
    arcade.draw_rect_filled(arcade.LBWH(cx - trunk_w // 2 + 1, bottom + 6, trunk_w - 2, trunk_h),
                            (90, 65, 35))
    arcade.draw_rect_filled(arcade.LBWH(cx - trunk_w // 2, bottom + 8, trunk_w, trunk_h - 4),
                            (75, 55, 30))
    for i in range(3):
        by = bottom + 10 + i * 6
        arcade.draw_line(cx - trunk_w // 2, by, cx + trunk_w // 2, by,
                         _alpha(_darken((90, 65, 35), 20), 40), 1)
    canopy_cx = cx + sway
    canopy_cy = cy + 8
    arcade.draw_circle_filled(canopy_cx - 9, canopy_cy - 5, 13, (35, 110, 30))
    arcade.draw_circle_filled(canopy_cx + 9, canopy_cy - 5, 13, (40, 120, 35))
    arcade.draw_circle_filled(canopy_cx, canopy_cy + 4, 15, (30, 100, 25))
    arcade.draw_circle_filled(canopy_cx - 6, canopy_cy + 6, 10, (45, 130, 40))
    arcade.draw_circle_filled(canopy_cx + 6, canopy_cy + 6, 10, (50, 135, 45))
    arcade.draw_circle_filled(canopy_cx, canopy_cy + 10, 9, (55, 140, 50))
    for i in range(4):
        lx = canopy_cx + rng.randint(-14, 14)
        ly = canopy_cy + rng.randint(-8, 14)
        arcade.draw_circle_filled(lx, ly, rng.uniform(1.5, 3.5), (60, 150, 55))
    light_x = canopy_cx - 4
    light_y = canopy_cy + 8
    arcade.draw_circle_filled(light_x, light_y, 5, (80, 160, 70, 35))
    arcade.draw_circle_filled(light_x + 2, light_y - 2, 3, (100, 180, 90, 25))
    if VISUAL_CONFIG["shadow_enabled"]:
        arcade.draw_ellipse_filled(cx + 3, bottom + 4, 18, 5,
                                   (0, 0, 0, VISUAL_CONFIG["shadow_alpha"] // 2))


def _render_road(tid, left, bottom, tx, ty, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _lighten(base, 5), _darken(base, 3), 3)
    for i in range(8):
        sx = left + rng.randint(3, TS - 3)
        sy = bottom + rng.randint(3, TS - 3)
        r = rng.uniform(0.5, 2)
        arcade.draw_circle_filled(sx, sy, r, detail)
    for i in range(4):
        sx = left + rng.randint(5, TS - 5)
        sy = bottom + rng.randint(5, TS - 5)
        arcade.draw_circle_filled(sx, sy, rng.uniform(1, 2.5), accent)
    if rng.random() < 0.3:
        wx = left + rng.randint(10, TS - 10)
        wy = bottom + rng.randint(10, TS - 10)
        arcade.draw_circle_filled(wx, wy, 1, (180, 160, 120))
        arcade.draw_line(wx - 2, wy, wx + 2, wy, (160, 140, 100), 1)
        arcade.draw_line(wx, wy - 2, wx, wy + 2, (160, 140, 100), 1)
    if rng.random() < 0.15:
        for i in range(3):
            lx = left + rng.randint(5, TS - 5)
            ly = bottom + rng.randint(5, TS - 5)
            arcade.draw_line(lx, ly, lx + rng.randint(-2, 2), ly - rng.randint(3, 6),
                             _darken(accent, 15), 1)


def _render_building_house(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (95, 85, 70))
    wall_color = base
    _draw_gradient_rect(left + 3, bottom + 3, TS - 6, TS - 10,
                        _lighten(wall_color, 8), _darken(wall_color, 5), 4)
    for i in range(3):
        by = bottom + 8 + i * 16
        arcade.draw_line(left + 5, by, left + TS - 5, by, _alpha(detail, 40), 1)
    roof_color = detail
    roof_peak = bottom + TS + 14
    arcade.draw_triangle_filled(left - 2, bottom + TS - 8, cx, roof_peak, left + TS + 2, bottom + TS - 8,
                                _darken(roof_color, 10))
    arcade.draw_triangle_filled(left, bottom + TS - 8, cx, roof_peak - 2, left + TS, bottom + TS - 8,
                                roof_color)
    arcade.draw_triangle_filled(left + 3, bottom + TS - 8, cx, roof_peak - 5, left + TS - 3, bottom + TS - 8,
                                _lighten(roof_color, 15))
    arcade.draw_line(left + 4, bottom + TS - 8, left + TS - 4, bottom + TS - 8,
                     _darken(roof_color, 20), 2)
    door_w = 10
    door_h = 16
    arcade.draw_rect_filled(arcade.LBWH(cx - door_w // 2, bottom + 5, door_w, door_h), (70, 50, 30))
    arcade.draw_rect_outline(arcade.LBWH(cx - door_w // 2, bottom + 5, door_w, door_h), (50, 35, 20), 1)
    arcade.draw_circle_filled(cx + 3, bottom + 5 + door_h // 2, 1, (200, 180, 80))
    for side in [-1, 1]:
        wx = cx + side * 14
        wy = bottom + TS - 22
        ww, wh = 7, 7
        arcade.draw_rect_filled(arcade.LBWH(wx - ww // 2, wy, ww, wh), (160, 190, 220, 120))
        arcade.draw_rect_outline(arcade.LBWH(wx - ww // 2, wy, ww, wh), (100, 80, 60), 1)
        arcade.draw_line(wx, wy, wx, wy + wh, (100, 80, 60), 1)
        arcade.draw_line(wx - ww // 2, wy + wh // 2, wx + ww // 2, wy + wh // 2, (100, 80, 60), 1)
    flicker = int(abs(math.sin(_anim_time * 3 + cx * 0.01)) * 15)
    arcade.draw_circle_filled(cx, bottom + 5 + door_h // 2 - 3, 2,
                              (255, 200, 100, 20 + flicker))


def _render_building_tower(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (80, 75, 65))
    _draw_gradient_rect(left + 8, bottom + 3, TS - 16, TS - 5,
                        _lighten(base, 6), _darken(base, 5), 4)
    for i in range(4):
        by = bottom + 8 + i * 12
        arcade.draw_line(left + 10, by, left + TS - 10, by, _alpha(detail, 50), 1)
    arcade.draw_rect_filled(arcade.LBWH(cx - 4, bottom + 6, 8, 14), (65, 45, 25))
    arcade.draw_rect_filled(arcade.LBWH(cx - 3, bottom + TS - 16, 6, 6), (160, 190, 220, 100))
    roof_color = detail
    arcade.draw_triangle_filled(left + 6, bottom + TS - 4, cx, bottom + TS + 16, left + TS - 6,
                                bottom + TS - 4, roof_color)
    arcade.draw_triangle_filled(left + 8, bottom + TS - 4, cx, bottom + TS + 13, left + TS - 8,
                                bottom + TS - 4, _lighten(roof_color, 12))
    for side in [-1, 1]:
        bx = cx + side * 5
        arcade.draw_rect_filled(arcade.LBWH(bx - 2, bottom + TS - 2, 4, 4), roof_color)
    flicker = int(abs(math.sin(_anim_time * 4 + cx * 0.02)) * 20)
    arcade.draw_circle_filled(cx, bottom + TS - 13, 2, (255, 200, 100, 15 + flicker))


def _render_building_gate(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), base)
    _draw_gradient_rect(left + 2, bottom + 2, TS - 4, TS - 4,
                        _lighten(base, 8), base, 3)
    gate_w = 18
    gate_h = TS - 8
    arcade.draw_rect_filled(arcade.LBWH(cx - gate_w // 2, bottom + 4, gate_w, gate_h), (50, 35, 20))
    arcade.draw_arc_outline(cx, bottom + 4 + gate_h, gate_w // 2, 8, (60, 45, 25), 0, 180, 2)
    for side in [-1, 1]:
        px = cx + side * (gate_w // 2 + 3)
        arcade.draw_rect_filled(arcade.LBWH(px - 2, bottom + 4, 4, gate_h), detail)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS - 4, TS, 4), detail)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS, TS, 6), _darken(detail, 15))
    for i in range(3):
        nail_x = cx - gate_w // 2 + 3 + i * 6
        arcade.draw_circle_filled(nail_x, bottom + 4 + gate_h // 2, 1, (160, 150, 120))


def _render_building_wall(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), base)
    _draw_gradient_rect(left + 2, bottom + 2, TS - 4, TS - 4,
                        _lighten(base, 6), base, 3)
    for row_i in range(4):
        by = bottom + 4 + row_i * 14
        offset = 8 if row_i % 2 == 1 else 0
        for col_i in range(-1, 4):
            bx = left + 4 + col_i * 16 + offset
            bw = 14
            if bx + bw > left + TS - 3:
                bw = left + TS - 3 - bx
            if bx < left + 3:
                bw -= (left + 3 - bx)
                bx = left + 3
            if bw > 0:
                arcade.draw_rect_filled(arcade.LBWH(bx, by, bw, 12), _lighten(base, 3))
                arcade.draw_rect_outline(arcade.LBWH(bx, by, bw, 12), _alpha(detail, 60), 1)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS - 2, TS, 4), detail)
    if rng.random() < 0.3:
        mx = left + rng.randint(10, TS - 10)
        my = bottom + rng.randint(10, TS - 10)
        arcade.draw_circle_filled(mx, my, 2, (100, 90, 70))


def _render_building_stall(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (90, 80, 65))
    _draw_gradient_rect(left + 4, bottom + 4, TS - 8, TS - 16,
                        _lighten(base, 5), base, 3)
    counter_y = bottom + TS - 18
    arcade.draw_rect_filled(arcade.LBWH(left + 2, counter_y, TS - 4, 6), detail)
    arcade.draw_rect_filled(arcade.LBWH(left + 2, counter_y + 6, TS - 4, 2), _darken(detail, 20))
    awning_color = rng.choice([(180, 60, 60), (60, 100, 180), (60, 140, 60), (180, 140, 40)])
    arcade.draw_triangle_filled(left, counter_y + 8, cx, counter_y + 22, left + TS, counter_y + 8,
                                _darken(awning_color, 10))
    arcade.draw_triangle_filled(left + 2, counter_y + 8, cx, counter_y + 19, left + TS - 2,
                                counter_y + 8, awning_color)
    for i in range(3):
        ix = left + 10 + i * 16
        iy = counter_y - 4
        item_c = rng.choice([(200, 180, 80), (180, 60, 60), (60, 140, 60)])
        arcade.draw_circle_filled(ix, iy, 3, item_c)
        arcade.draw_circle_filled(ix, iy, 1.5, _lighten(item_c, 30))
    for side in [-1, 1]:
        px = cx + side * 20
        arcade.draw_rect_filled(arcade.LBWH(px - 2, bottom + 4, 4, counter_y - 4), (80, 60, 40))


def _render_building_altar(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (70, 60, 55))
    _draw_gradient_rect(left + 4, bottom + 4, TS - 8, TS - 8,
                        _lighten(base, 5), base, 3)
    steps = 3
    for i in range(steps):
        sw = TS - 12 - i * 8
        sh = 4
        sx = cx - sw // 2
        sy = bottom + 6 + i * 6
        arcade.draw_rect_filled(arcade.LBWH(sx, sy, sw, sh), _lighten(base, i * 8))
        arcade.draw_rect_outline(arcade.LBWH(sx, sy, sw, sh), _alpha(detail, 80), 1)
    glow = int(abs(math.sin(_anim_time * 2)) * 50)
    arcade.draw_circle_filled(cx, cy + 4, 8, (*accent, 60 + glow))
    arcade.draw_circle_filled(cx, cy + 4, 5, (255, 220, 150, 50 + glow))
    arcade.draw_circle_filled(cx, cy + 4, 2, (255, 255, 200, 40 + glow))
    for side in [-1, 1]:
        lx = cx + side * 18
        ly = cy - 4
        flicker = int(abs(math.sin(_anim_time * 5 + side * 2)) * 30)
        arcade.draw_circle_filled(lx, ly + 8, 3, (255, 150, 50, 100 + flicker))
        arcade.draw_circle_filled(lx, ly + 10, 1.5, (255, 220, 100, 80 + flicker))
        arcade.draw_circle_filled(lx, ly + 11, 1, (255, 255, 200, 50 + flicker))


def _render_building_prison(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (60, 55, 55))
    _draw_gradient_rect(left + 3, bottom + 3, TS - 6, TS - 6,
                        _darken(base, 5), _darken(base, 15), 3)
    bar_spacing = 8
    for i in range(7):
        bx = left + 8 + i * bar_spacing
        arcade.draw_line(bx, bottom + 8, bx, bottom + TS - 8, (100, 100, 110), 2)
        arcade.draw_line(bx - 1, bottom + 8, bx - 1, bottom + TS - 8, (130, 130, 140, 40), 1)
    arcade.draw_line(left + 6, bottom + TS // 2, left + TS - 6, bottom + TS // 2, (100, 100, 110), 2)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS - 3, TS, 3), detail)


def _render_building_arena(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), (80, 70, 60))
    _draw_gradient_rect(left + 2, bottom + 2, TS - 4, TS - 4,
                        _lighten(base, 8), base, 3)
    arcade.draw_ellipse_outline(cx, cy, 24, 18, accent, 2)
    arcade.draw_line(cx - 2, cy - 2, cx + 2, cy + 2, accent, 1)
    arcade.draw_line(cx + 2, cy - 2, cx - 2, cy + 2, accent, 1)
    for side in [-1, 1]:
        sx = cx + side * 24
        arcade.draw_rect_filled(arcade.LBWH(sx - 2, bottom + 6, 4, TS - 12), detail)
    pulse = int(abs(math.sin(_anim_time * 2)) * 20)
    arcade.draw_circle_filled(cx, cy, 3, (*accent, 30 + pulse))


def _render_wall_solid(left, bottom, cx, cy, base, detail, accent, rng):
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), base)
    _draw_gradient_rect(left + 2, bottom + 2, TS - 4, TS - 4,
                        _lighten(base, 5), base, 3)
    for row_i in range(4):
        by = bottom + 3 + row_i * 15
        offset = 8 if row_i % 2 == 1 else 0
        for col_i in range(-1, 4):
            bx = left + 3 + col_i * 16 + offset
            bw = 14
            if bx + bw > left + TS - 2:
                bw = left + TS - 2 - bx
            if bx < left + 2:
                bw -= (left + 2 - bx)
                bx = left + 2
            if bw > 0:
                arcade.draw_rect_outline(arcade.LBWH(bx, by, bw, 13), _alpha(detail, 50), 1)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS - 3, TS, 3), _darken(base, 15))
    arcade.draw_rect_filled(arcade.LBWH(left, bottom + TS - 1, TS, 2), _darken(base, 25))


def _render_special_glow(tid, left, bottom, cx, cy, base, detail, accent, rng, tx):
    dark = (40, 35, 35) if tid == 41 else (55, 45, 40)
    arcade.draw_rect_filled(arcade.LBWH(left, bottom, TS, TS), dark)
    glow = int(abs(math.sin(_anim_time * 2.5 + tx * 0.7)) * 60)
    arcade.draw_rect_filled(arcade.LBWH(left + 4, bottom + 4, TS - 8, TS - 8), (*base, 130 + glow))
    glow_r = 10 if tid == 49 else 7
    arcade.draw_circle_filled(cx, cy, glow_r, (*accent, 60 + glow))
    arcade.draw_circle_filled(cx, cy, glow_r // 2, (255, 220, 150, 40 + glow))
    for i in range(6):
        angle = _anim_time * 1.5 + i * math.pi / 3
        px = cx + math.cos(angle) * (glow_r + 5)
        py = cy + math.sin(angle) * (glow_r + 5)
        arcade.draw_circle_filled(px, py, 1.5, (*accent, 40 + glow // 2))


def _render_snow(tid, left, bottom, tx, ty, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _lighten(base, 5), base, 3)
    for i in range(5):
        sx = left + rng.randint(3, TS - 3)
        sy = bottom + rng.randint(3, TS - 3)
        arcade.draw_circle_filled(sx, sy, rng.uniform(1, 3), detail)
    for i in range(3):
        sx = left + rng.randint(5, TS - 5)
        sy = bottom + rng.randint(5, TS - 5)
        sparkle = int(abs(math.sin(_anim_time * 2 + sx * 0.1)) * 100)
        if sparkle > 25:
            arcade.draw_circle_filled(sx, sy, 1.2, (255, 255, 255, sparkle))
    arcade.draw_line(left + 2, bottom + TS - 2, left + TS - 2, bottom + TS - 2,
                     _alpha(_lighten(base, 20), 40), 1)


def _render_swamp(left, bottom, cx, cy, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _darken(base, 5), _darken(base, 15), 3)
    for i in range(4):
        bx = left + rng.randint(5, TS - 5)
        by = bottom + rng.randint(5, TS - 5)
        r = rng.uniform(3, 7)
        arcade.draw_circle_filled(bx, by, r, detail)
        bubble = int(abs(math.sin(_anim_time * 1.5 + bx * 0.1)) * 40)
        if bubble > 20:
            arcade.draw_circle_outline(bx, by, r + 2, (*accent, bubble), 1)
    for i in range(2):
        gx = left + rng.randint(8, TS - 8)
        gy = bottom + rng.randint(8, TS - 8)
        arcade.draw_line(gx, gy, gx, gy - 8, accent, 1)
        arcade.draw_circle_filled(gx, gy - 8, 2, _lighten(accent, 20))


def _render_mushroom(left, bottom, cx, cy, base, detail, accent, rng):
    _draw_gradient_rect(left, bottom, TS, TS, _lighten(base, 5), base, 3)
    for i in range(3):
        mx = left + rng.randint(10, TS - 10)
        my = bottom + rng.randint(10, TS - 20)
        stem_h = rng.randint(6, 10)
        arcade.draw_rect_filled(arcade.LBWH(mx - 2, my, 4, stem_h), (200, 190, 170))
        cap_w = rng.randint(8, 14)
        cap_h = rng.randint(4, 7)
        cap_color = rng.choice([(200, 60, 60), (180, 140, 80), (160, 100, 60), (200, 180, 60)])
        arcade.draw_ellipse_filled(mx, my + stem_h, cap_w, cap_h, cap_color)
        arcade.draw_ellipse_filled(mx, my + stem_h, cap_w - 2, cap_h - 1, _lighten(cap_color, 15))
        for j in range(rng.randint(1, 3)):
            dx = mx + rng.randint(-cap_w // 3, cap_w // 3)
            dy = my + stem_h + rng.randint(-1, cap_h // 2)
            arcade.draw_circle_filled(dx, dy, 1.5, (255, 255, 255, 120))


def _draw_building_labels(camera_x: float, camera_y: float, game_map: Map):
    labels = game_map.labels if hasattr(game_map, 'labels') else []
    for label in labels:
        lx, ly, text, faction_key = label[0], label[1], label[2], label[3] if len(label) > 3 else "default"
        wx, wy = _map_to_world(lx, ly, len(game_map.tiles))
        sx, sy = _world_to_screen(wx, wy + 1.5, camera_x, camera_y)
        if 0 <= sx <= SW and 0 <= sy <= SH:
            bc = BUILDING_COLORS.get(faction_key, BUILDING_COLORS["default"])
            tw = len(text) * 10 + 24
            th = 22
            _draw_gradient_rect(sx - tw / 2, sy - th / 2, tw, th,
                                (*bc["roof"][:3], 220), (*_darken(bc["roof"], 20)[:3], 200), 3)
            arcade.draw_rect_outline(arcade.LBWH(sx - tw / 2, sy - th / 2, tw, th),
                                     (*bc["wall"], 230), 1)
            arcade.draw_line(sx - tw / 2 + 4, sy + th / 2 - 1, sx + tw / 2 - 4, sy + th / 2 - 1,
                             _alpha(_lighten(bc["roof"], 30), 60), 1)
            _draw_text(text, sx, sy, (255, 255, 255), 12, "center", "center")


# ──────────────────────────────────────────────
#  角色渲染
# ──────────────────────────────────────────────

CHAR_VISUAL = {
    "player": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "weapon": "sword"},
    "平阿四": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0, "hat": "trader"},
    "韦扬": {"hair": "hair_black", "cloth": "cloth_white", "skin": 0, "hat": "master", "weapon": "sword"},
    "于红儒": {"hair": "hair_black", "cloth": "cloth_red", "skin": 0, "weapon": "blade"},
    "钟央": {"hair": "hair_white", "cloth": "cloth_purple", "skin": 1, "weapon": "staff"},
    "何铁手": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "weapon": "whip"},
    "古松道人": {"hair": "hair_white", "cloth": "cloth_gray", "skin": 1, "hat": "taoist", "weapon": "staff"},
    "独孤求败": {"hair": "hair_white", "cloth": "cloth_black", "skin": 1, "hat": "master", "weapon": "sword"},
    "何裁缝": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0},
    "简英": {"hair": "hair_black", "cloth": "cloth_white", "skin": 0},
    "武师教头": {"hair": "hair_black", "cloth": "cloth_red", "skin": 0, "hat": "warrior", "weapon": "blade"},
    "春花娘": {"hair": "hair_brown", "cloth": "cloth_red", "skin": 0},
    "店小二": {"hair": "hair_black", "cloth": "cloth_gray", "skin": 0, "hat": "waiter"},
    "捕快": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "hat": "guard", "weapon": "blade"},
    "钱庄老板": {"hair": "hair_brown", "cloth": "cloth_gold", "skin": 0, "hat": "trader"},
    "药铺掌柜": {"hair": "hair_brown", "cloth": "cloth_green", "skin": 0, "hat": "trader"},
    "铁匠": {"hair": "hair_black", "cloth": "cloth_brown", "skin": 1, "hat": "blacksmith", "weapon": "hammer"},
    "浪人甲": {"hair": "hair_black", "cloth": "cloth_black", "skin": 1, "weapon": "blade"},
    "雪豹": {"hair": "hair_white", "cloth": "cloth_white", "skin": 1},
}


def _get_char_visual(name: str) -> dict:
    return CHAR_VISUAL.get(name, CHAR_VISUAL.get("player"))


def draw_character(sx: float, sy: float, name: str, facing: str = "down",
                   is_player: bool = False, npc_type: str = "normal",
                   faction: Faction = Faction.NONE, hp_ratio: float = 1.0,
                   has_quest: bool = False, is_master: bool = False):
    vis = _get_char_visual(name)
    skin_idx = vis.get("skin", 0)
    skin_color = CHAR_PALETTE["skin"][min(skin_idx, len(CHAR_PALETTE["skin"]) - 1)]
    hair_color = CHAR_PALETTE.get(vis.get("hair", "hair_black"), CHAR_PALETTE["hair_black"])
    cloth_color = CHAR_PALETTE.get(vis.get("cloth", "cloth_blue"), CHAR_PALETTE["cloth_blue"])
    cloth_light = _lighten(cloth_color, 25)
    cloth_dark = _darken(cloth_color, 25)
    cloth_vdark = _darken(cloth_color, 45)

    breathe = math.sin(_anim_time * 2.5 + hash(name) % 100 * 0.01) * 0.5

    if _hurt_flash > 0 and is_player:
        flash_a = int(_hurt_flash * 120)
        arcade.draw_circle_filled(sx, sy, 26, (255, 50, 50, flash_a))

    if VISUAL_CONFIG["shadow_enabled"]:
        shadow_a = VISUAL_CONFIG["shadow_alpha"]
        arcade.draw_ellipse_filled(sx + 2, sy - 16, 22, 8, (0, 0, 0, shadow_a))
        arcade.draw_ellipse_filled(sx + 2, sy - 15, 18, 5, (0, 0, 0, shadow_a // 3))

    body_y = sy + 2 + breathe
    head_y = sy + 20 + breathe

    leg_color = cloth_dark
    walk_offset = math.sin(_anim_time * 6) * 3 if is_player else math.sin(_anim_time * 3 + hash(name) % 50) * 1.5
    arcade.draw_rect_filled(arcade.LBWH(sx - 6, body_y - 20 + walk_offset, 5, 12), leg_color)
    arcade.draw_rect_filled(arcade.LBWH(sx + 1, body_y - 20 - walk_offset, 5, 12), leg_color)
    arcade.draw_rect_filled(arcade.LBWH(sx - 5, body_y - 20 + walk_offset, 3, 12), _lighten(leg_color, 8))
    arcade.draw_rect_filled(arcade.LBWH(sx + 2, body_y - 20 - walk_offset, 3, 12), _lighten(leg_color, 8))

    shoe_color = cloth_vdark
    arcade.draw_rect_filled(arcade.LBWH(sx - 7, body_y - 22 + walk_offset, 6, 3), shoe_color)
    arcade.draw_rect_filled(arcade.LBWH(sx + 1, body_y - 22 - walk_offset, 6, 3), shoe_color)

    _draw_gradient_rect(sx - 8, body_y - 10, 16, 18, cloth_light, cloth_dark, 3)
    arcade.draw_rect_filled(arcade.LBWH(sx - 6, body_y - 8, 12, 14), cloth_light)

    arcade.draw_rect_filled(arcade.LBWH(sx - 4, body_y + 6, 8, 3), cloth_light)
    arcade.draw_line(sx - 4, body_y + 6, sx + 4, body_y + 6, _lighten(cloth_light, 15), 1)

    if is_master:
        belt_color = CHAR_PALETTE.get("cloth_gold", (200, 170, 80))
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, body_y - 2, 16, 3), belt_color)
        arcade.draw_circle_filled(sx, body_y - 0.5, 2, _lighten(belt_color, 30))
        arcade.draw_circle_filled(sx, body_y - 0.5, 1, (255, 240, 200))
    else:
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, body_y - 2, 16, 2), cloth_dark)

    arm_swing = math.sin(_anim_time * 6) * 2 if is_player else 0
    arm_color = cloth_color
    arcade.draw_rect_filled(arcade.LBWH(sx - 11, body_y - 8 + arm_swing, 4, 14), arm_color)
    arcade.draw_rect_filled(arcade.LBWH(sx + 7, body_y - 8 - arm_swing, 4, 14), arm_color)
    arcade.draw_circle_filled(sx - 9, body_y - 9 + arm_swing, 2.5, skin_color)
    arcade.draw_circle_filled(sx + 9, body_y - 9 - arm_swing, 2.5, skin_color)

    weapon = vis.get("weapon")
    if weapon:
        _draw_weapon(sx, body_y, weapon, cloth_color)

    arcade.draw_circle_filled(sx, head_y, 9, skin_color)
    arcade.draw_circle_filled(sx - 1, head_y + 1, 7, _lighten(skin_color, 8))
    arcade.draw_ellipse_filled(sx, head_y + 6, 18, 9, hair_color)
    arcade.draw_ellipse_filled(sx, head_y + 2, 18, 4, hair_color)
    side_burn_w = 3
    arcade.draw_rect_filled(arcade.LBWH(sx - 9, head_y - 2, side_burn_w, 6), hair_color)
    arcade.draw_rect_filled(arcade.LBWH(sx + 9 - side_burn_w, head_y - 2, side_burn_w, 6), hair_color)

    hat_type = vis.get("hat")
    _draw_hat(sx, head_y, hat_type, cloth_color)

    eye_y = head_y + 1
    if facing in ("down", "left", "right"):
        ex_offset = -3 if facing == "left" else (3 if facing == "right" else 0)
        for side in [-1, 1]:
            ex = sx + side * 3 + ex_offset * 0.3
            arcade.draw_circle_filled(ex, eye_y, 2, (30, 25, 20))
            arcade.draw_circle_filled(ex, eye_y, 1.2, (50, 40, 30))
            arcade.draw_circle_filled(ex + 0.5, eye_y + 0.5, 0.6, (255, 255, 255, 150))
        if facing == "down":
            brow_y = eye_y + 3
            arcade.draw_line(sx - 4, brow_y, sx - 1, brow_y + 0.5, _darken(hair_color, 10), 1)
            arcade.draw_line(sx + 1, brow_y + 0.5, sx + 4, brow_y, _darken(hair_color, 10), 1)

    if is_player:
        glow_a = int(35 + 20 * math.sin(_anim_time * 3))
        arcade.draw_circle_outline(sx, sy + breathe, 24, (255, 200, 100, glow_a), 2)
        for i in range(3):
            angle = _anim_time * 1.5 + i * math.pi * 2 / 3
            px = sx + math.cos(angle) * 22
            py = sy + breathe + math.sin(angle) * 22
            arcade.draw_circle_filled(px, py, 1.5, (255, 200, 100, glow_a // 2))

    if faction != Faction.NONE:
        faction_colors = {
            Faction.BAGUA: (60, 60, 180), Faction.FLOWER: (180, 80, 150),
            Faction.HONGLIAN: (200, 50, 50), Faction.NAJA: (50, 150, 80),
            Faction.TAIJI: (180, 180, 180), Faction.XUESHAN: (150, 180, 220),
            Faction.XIAOYAO: (120, 180, 100),
        }
        fc = faction_colors.get(faction, (200, 200, 200))
        badge_x = sx + 10
        badge_y = body_y + 6
        arcade.draw_circle_filled(badge_x, badge_y, 4, _darken(fc, 20))
        arcade.draw_circle_filled(badge_x, badge_y, 3, fc)
        arcade.draw_circle_outline(badge_x, badge_y, 4, (255, 255, 255, 180), 1)
        arcade.draw_circle_filled(badge_x, badge_y, 1.5, (255, 255, 255, 200))

    if hp_ratio < 1.0:
        bar_w = 28
        bar_h = 4
        bar_x = sx - bar_w / 2
        bar_y = sy + 28 + breathe
        arcade.draw_rect_filled(arcade.LBWH(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2), (0, 0, 0, 120))
        arcade.draw_rect_filled(arcade.LBWH(bar_x, bar_y, bar_w, bar_h), (40, 12, 12))
        fill_w = max(1, int(bar_w * hp_ratio))
        hp_color = (80, 220, 80) if hp_ratio > 0.5 else ((220, 180, 40) if hp_ratio > 0.25 else (220, 50, 50))
        _draw_gradient_rect(bar_x, bar_y, fill_w, bar_h, _lighten(hp_color, 20), hp_color, 2)
        arcade.draw_rect_outline(arcade.LBWH(bar_x, bar_y, bar_w, bar_h), (0, 0, 0, 80), 1)

    if has_quest and VISUAL_CONFIG["quest_indicator"]:
        qy = sy + 34 + 3 * math.sin(_anim_time * 3) + breathe
        qx = sx
        arcade.draw_circle_filled(qx, qy + 2, 6, (255, 220, 50, 40))
        arcade.draw_text("!", qx, qy, (255, 220, 50), 14, font_name=FONT_LATIN,
                         anchor_x="center", anchor_y="center")

    if npc_type == "enemy":
        pulse = int(140 + 60 * math.sin(_anim_time * 4))
        arcade.draw_circle_outline(sx, sy, 22, (pulse, 30, 30, 70), 1)

    if is_master and not has_quest:
        glow = int(25 + 20 * math.sin(_anim_time * 2))
        arcade.draw_circle_outline(sx, sy, 24, (200, 180, 100, glow), 1)
        for i in range(4):
            angle = _anim_time + i * math.pi / 2
            px = sx + math.cos(angle) * 22
            py = sy + math.sin(angle) * 22
            arcade.draw_circle_filled(px, py, 1, (200, 180, 100, glow))

    if not is_player:
        name_bg_w = len(name) * 10 + 8
        name_bg_h = 14
        name_bg_x = sx - name_bg_w // 2
        name_bg_y = sy + 34 + breathe
        arcade.draw_rect_filled(arcade.LBWH(name_bg_x, name_bg_y - name_bg_h // 2,
                                            name_bg_w, name_bg_h), (0, 0, 0, 80))
        arcade.draw_text(name, sx, name_bg_y, (255, 255, 255, 200),
                         10, font_name=FONT, anchor_x="center", anchor_y="center")


def _draw_weapon(sx, body_y, weapon, cloth_color):
    if weapon == "sword":
        wx = sx + 12
        wy = body_y - 6
        arcade.draw_line(wx, wy, wx + 2, wy - 20, (190, 195, 205), 2)
        arcade.draw_line(wx + 1, wy, wx + 3, wy - 20, (220, 225, 235), 1)
        arcade.draw_line(wx - 3, wy, wx + 5, wy, (160, 140, 80), 2)
        arcade.draw_rect_filled(arcade.LBWH(wx - 1, wy, 3, 4), (120, 80, 40))
    elif weapon == "blade":
        wx = sx + 12
        wy = body_y - 4
        arcade.draw_line(wx, wy, wx + 3, wy - 18, (180, 185, 195), 3)
        arcade.draw_line(wx + 1, wy, wx + 4, wy - 18, (210, 215, 225), 1)
        arcade.draw_line(wx - 4, wy, wx + 6, wy, (160, 140, 80), 2)
        arcade.draw_rect_filled(arcade.LBWH(wx - 2, wy, 5, 3), (120, 80, 40))
    elif weapon == "staff":
        wx = sx + 11
        wy = body_y + 8
        arcade.draw_line(wx, wy, wx, wy - 28, (120, 90, 50), 2)
        arcade.draw_line(wx + 1, wy, wx + 1, wy - 28, (140, 110, 70), 1)
        arcade.draw_circle_filled(wx, wy - 28, 3, (200, 170, 80))
        arcade.draw_circle_filled(wx, wy - 28, 1.5, (255, 220, 120))
    elif weapon == "whip":
        wx = sx + 12
        wy = body_y - 4
        points = [(wx, wy), (wx + 4, wy - 6), (wx + 2, wy - 12), (wx + 6, wy - 16)]
        for i in range(len(points) - 1):
            arcade.draw_line(points[i][0], points[i][1], points[i + 1][0], points[i + 1][1],
                             (100, 70, 40), 2)
        arcade.draw_circle_filled(wx + 6, wy - 16, 1.5, (80, 50, 30))
    elif weapon == "hammer":
        wx = sx + 12
        wy = body_y - 4
        arcade.draw_line(wx, wy, wx, wy - 18, (100, 80, 50), 2)
        arcade.draw_rect_filled(arcade.LBWH(wx - 5, wy - 22, 10, 7), (130, 130, 140))
        arcade.draw_rect_filled(arcade.LBWH(wx - 4, wy - 21, 8, 5), (150, 150, 160))


def _draw_hat(sx, head_y, hat_type, cloth_color):
    if hat_type == "master":
        arcade.draw_rect_filled(arcade.LBWH(sx - 7, head_y + 9, 14, 5), cloth_color)
        arcade.draw_rect_filled(arcade.LBWH(sx - 9, head_y + 13, 18, 2), _lighten(cloth_color, 15))
        arcade.draw_circle_filled(sx, head_y + 14, 1.5, (200, 170, 80))
        arcade.draw_circle_filled(sx, head_y + 14, 0.8, (255, 240, 180))
    elif hat_type == "trader":
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, head_y + 8, 16, 6), cloth_color)
        arcade.draw_rect_filled(arcade.LBWH(sx - 9, head_y + 13, 18, 2), _darken(cloth_color, 15))
    elif hat_type == "guard":
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, head_y + 8, 16, 7), (130, 130, 145))
        arcade.draw_rect_filled(arcade.LBWH(sx - 9, head_y + 14, 18, 2), (150, 150, 165))
        arcade.draw_circle_filled(sx, head_y + 10, 2, (180, 160, 60))
        arcade.draw_circle_filled(sx, head_y + 10, 1, (220, 200, 100))
    elif hat_type == "taoist":
        arcade.draw_circle_filled(sx, head_y + 11, 8, cloth_color)
        arcade.draw_circle_filled(sx, head_y + 11, 6, _lighten(cloth_color, 10))
        arcade.draw_rect_filled(arcade.LBWH(sx - 1, head_y + 9, 2, 10), (200, 170, 80))
        arcade.draw_circle_filled(sx, head_y + 18, 2, (200, 170, 80))
    elif hat_type == "warrior":
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, head_y + 8, 16, 6), (140, 140, 155))
        arcade.draw_rect_filled(arcade.LBWH(sx - 9, head_y + 13, 18, 2), (160, 160, 175))
        for side in [-1, 1]:
            arcade.draw_rect_filled(arcade.LBWH(sx + side * 6 - 1, head_y + 6, 3, 4), (140, 140, 155))
    elif hat_type == "waiter":
        arcade.draw_rect_filled(arcade.LBWH(sx - 7, head_y + 8, 14, 5), cloth_color)
        arcade.draw_line(sx - 7, head_y + 10, sx + 7, head_y + 10, _darken(cloth_color, 15), 1)
    elif hat_type == "blacksmith":
        arcade.draw_rect_filled(arcade.LBWH(sx - 7, head_y + 8, 14, 4), cloth_color)
        arcade.draw_rect_filled(arcade.LBWH(sx - 8, head_y + 11, 16, 2), _darken(cloth_color, 20))


def draw_player(player: Player, camera_x: float, camera_y: float):
    sx, sy = _world_to_screen(player.position.x, player.position.y, camera_x, camera_y)
    if -40 <= sx <= SW + 40 and -40 <= sy <= SH + 40:
        draw_character(sx, sy, "player", is_player=True,
                       faction=player.faction,
                       hp_ratio=player.hp / player.max_hp if player.max_hp > 0 else 1.0)


def draw_npc(npc: NPC, camera_x: float, camera_y: float):
    sx, sy = _world_to_screen(npc.position.x, npc.position.y, camera_x, camera_y)
    if -40 <= sx <= SW + 40 and -40 <= sy <= SH + 40:
        hp_ratio = npc.hp / npc.max_hp if npc.max_hp > 0 else 1.0
        draw_character(sx, sy, npc.name, is_player=False,
                       npc_type=npc.npc_type.value,
                       faction=npc.faction,
                       hp_ratio=hp_ratio,
                       has_quest=npc.has_quests,
                       is_master=npc.is_master)


# ──────────────────────────────────────────────
#  HUD / UI
# ──────────────────────────────────────────────

def draw_hud(player: Player, game_time: float = 0):
    hud_h = 78
    _draw_gradient_rect(0, 0, SW, hud_h, (18, 24, 42), (8, 12, 24), 6)
    for i in range(3):
        a = 45 - i * 14
        arcade.draw_rect_outline(arcade.LBWH(i, i, SW - i * 2, hud_h - i * 2),
                                 (255, 200, 100, a), 1)
    arcade.draw_rect_filled(arcade.LBWH(0, hud_h - 1, SW, 2), (255, 200, 100, 60))
    arcade.draw_line(0, hud_h - 3, SW, hud_h - 3, (255, 200, 100, 20), 1)

    avatar_x = 14
    avatar_y = hud_h - 40
    avatar_s = 46
    _draw_gradient_rect(avatar_x, avatar_y, avatar_s, avatar_s,
                        (30, 38, 60), (20, 25, 42), 3)
    for i in range(3):
        a = 100 - i * 30
        arcade.draw_rect_outline(arcade.LBWH(avatar_x - i, avatar_y - i,
                                             avatar_s + i * 2, avatar_s + i * 2),
                                 (255, 200, 100, a), 1)
    skin = CHAR_PALETTE["skin"][0]
    hair = CHAR_PALETTE["hair_black"]
    cloth = CHAR_PALETTE.get("cloth_blue", CHAR_PALETTE["cloth_blue"])
    acx = avatar_x + avatar_s // 2
    acy = avatar_y + avatar_s // 2
    arcade.draw_circle_filled(acx, acy + 4, 10, skin)
    arcade.draw_ellipse_filled(acx, acy + 10, 20, 8, hair)
    _draw_gradient_rect(acx - 8, acy - 10, 16, 14, _lighten(cloth, 10), cloth, 2)
    faction_colors = {
        Faction.BAGUA: (60, 60, 180), Faction.FLOWER: (180, 80, 150),
        Faction.HONGLIAN: (200, 50, 50), Faction.NAJA: (50, 150, 80),
        Faction.TAIJI: (180, 180, 180), Faction.XUESHAN: (150, 180, 220),
        Faction.XIAOYAO: (120, 180, 100), Faction.NONE: (150, 150, 150),
    }
    fc = faction_colors.get(player.faction, (150, 150, 150))
    arcade.draw_circle_filled(acx + avatar_s // 2 - 5, acy + 8, 4, fc)
    arcade.draw_circle_outline(acx + avatar_s // 2 - 5, acy + 8, 4, (255, 255, 255, 150), 1)
    arcade.draw_circle_filled(acx + avatar_s // 2 - 5, acy + 8, 2, (255, 255, 255, 180))

    name_x = 70
    name_y = hud_h - 18
    _draw_text(player.name, name_x, name_y, COLORS["accent"], 18, "left", "center")
    faction_name = FACTION_NAMES[player.faction.value]
    _draw_text(faction_name, name_x, name_y - 22, (140, 150, 170), 11, "left", "center")
    _draw_text(f"Lv.{player.level}", name_x + 100, name_y, (200, 200, 200), 14, "left", "center")

    bar_x = 190
    bar_w = 210
    bar_h = 18
    hp_y = hud_h - 16
    _draw_bar(bar_x, hp_y, bar_w, bar_h, player.hp, player.max_hp,
              (60, 200, 60), (200, 180, 40), (220, 50, 50), (40, 15, 15), (80, 30, 30),
              "HP")

    mp_y = hud_h - 40
    _draw_bar(bar_x, mp_y, bar_w, bar_h, player.mp, player.max_mp,
              (60, 100, 220), (60, 100, 220), (60, 100, 220), (15, 20, 50), (30, 40, 80),
              "MP")

    exp_y = hud_h - 60
    exp_ratio = player.exp / player.exp_for_next_level if player.exp_for_next_level > 0 else 0
    arcade.draw_rect_filled(arcade.LBWH(bar_x - 1, exp_y - 1, bar_w + 2, 10), (0, 0, 0, 60))
    arcade.draw_rect_filled(arcade.LBWH(bar_x, exp_y, bar_w, 8), (20, 20, 30))
    exp_fill = max(1, int(bar_w * min(1.0, exp_ratio)))
    _draw_gradient_rect(bar_x, exp_y, exp_fill, 8, (220, 200, 80), (160, 140, 40), 2)
    arcade.draw_rect_outline(arcade.LBWH(bar_x, exp_y, bar_w, 8), (60, 50, 30), 1)
    _draw_text(f"EXP {player.exp}/{player.exp_for_next_level}", bar_x + bar_w / 2, exp_y + 4,
               (200, 190, 150), 8, "center", "center")

    info_x = 430
    icon_labels = [
        ("银两", f"{player.money}", COLORS["gold"], (255, 215, 0, 30)),
        ("道德", f"{player.daode}", (100, 220, 100) if player.daode >= 0 else (220, 100, 100),
         (100, 220, 100, 20) if player.daode >= 0 else (220, 100, 100, 20)),
        ("潜能", f"{player.pot}", (150, 180, 220), (150, 180, 220, 20)),
    ]
    for i, (label, val, color, bg_c) in enumerate(icon_labels):
        iy = hud_h - 14 - i * 20
        arcade.draw_rect_filled(arcade.LBWH(info_x - 2, iy - 8, 100, 16), bg_c)
        arcade.draw_rect_outline(arcade.LBWH(info_x - 2, iy - 8, 100, 16), (*color[:3], 40), 1)
        _draw_text(label, info_x + 2, iy, (120, 120, 130), 10, "left", "center")
        _draw_text(val, info_x + 40, iy, color, 13, "left", "center")

    str_x = info_x + 120
    attrs = [
        ("力", player.strength, (220, 150, 150)),
        ("敏", player.dexterity, (150, 220, 150)),
        ("智", player.intelligence, (150, 150, 220)),
        ("体", player.constitution, (220, 200, 150)),
    ]
    for i, (label, val, color) in enumerate(attrs):
        ax = str_x + i * 55
        arcade.draw_rect_filled(arcade.LBWH(ax - 2, hud_h - 24, 48, 18), (*color, 15))
        _draw_text(f"{label}", ax + 2, hud_h - 15, (100, 100, 110), 10, "left", "center")
        _draw_text(f"{val}", ax + 16, hud_h - 15, color, 14, "left", "center")

    hint_x = SW - 15
    hint_y = hud_h - 16
    hints = "[T]对话 [F]攻击 [E]使用 [B]背包 [K]技能 [Q]任务"
    _draw_text(hints, hint_x, hint_y, (80, 90, 110), 10, "right", "center")

    skill_x = SW - 15
    skill_y = hud_h - 40
    if player.skills:
        shown = player.skills[:4]
        for i, sk in enumerate(shown):
            sx = skill_x - (len(shown) - 1 - i) * 36
            _draw_gradient_rect(sx - 14, skill_y - 12, 28, 24,
                                (30, 40, 60), (15, 20, 35), 2)
            arcade.draw_rect_outline(arcade.LBWH(sx - 14, skill_y - 12, 28, 24),
                                     (80, 100, 140, 120), 1)
            type_colors = {0: (255, 150, 150), 1: (150, 200, 255), 2: (255, 180, 100),
                           3: (200, 150, 255), 4: (150, 255, 200)}
            tc = type_colors.get(sk.type, (200, 200, 200))
            name_char = sk.name[0] if sk.name else "?"
            _draw_text(name_char, sx, skill_y, tc, 12, "center", "center")
            _draw_text(f"{sk.level}", sx + 10, skill_y - 8, (180, 180, 180), 8, "left", "center")


def _draw_bar(x, y, w, h, current, maximum, color_high, color_mid, color_low, bg_color, border_color, label):
    arcade.draw_rect_filled(arcade.LBWH(x - 1, y - 1, w + 2, h + 2), (0, 0, 0, 80))
    arcade.draw_rect_filled(arcade.LBWH(x, y, w, h), bg_color)
    ratio = current / maximum if maximum > 0 else 0
    fill_w = max(1, int(w * ratio))
    color = color_high if ratio > 0.5 else (color_mid if ratio > 0.25 else color_low)
    _draw_gradient_rect(x, y, fill_w, h, _lighten(color, 20), color, 3)
    arcade.draw_rect_filled(arcade.LBWH(x, y + h - 3, fill_w, 3), _alpha(_lighten(color, 40), 50))
    arcade.draw_rect_outline(arcade.LBWH(x, y, w, h), border_color, 1)
    _draw_text(f"{label} {current}/{maximum}", x + w / 2, y + h / 2,
               (255, 255, 255), 10, "center", "center")


# ──────────────────────────────────────────────
#  小地图
# ──────────────────────────────────────────────

def draw_minimap(camera_x: float, camera_y: float, game_map: Optional[Map],
                 player: Player, npcs: list):
    if not VISUAL_CONFIG["minimap_enabled"] or not game_map:
        return
    mm_size = VISUAL_CONFIG["minimap_size"]
    mm_x = SW - mm_size - 15
    mm_y = SH - mm_size - 15
    mm_alpha = VISUAL_CONFIG["minimap_alpha"]

    _draw_gradient_rect(mm_x - 4, mm_y - 4, mm_size + 8, mm_size + 8,
                        (15, 22, 40), (5, 10, 20), 3)
    arcade.draw_rect_outline(arcade.LBWH(mm_x - 4, mm_y - 4, mm_size + 8, mm_size + 8),
                             (80, 90, 110, mm_alpha), 1)
    arcade.draw_rect_outline(arcade.LBWH(mm_x - 2, mm_y - 2, mm_size + 4, mm_size + 4),
                             (60, 70, 90, mm_alpha), 1)
    _draw_gradient_rect(mm_x, mm_y, mm_size, mm_size, (20, 28, 42), (12, 18, 28), 4)

    map_w = len(game_map.tiles[0]) if game_map.tiles else 1
    map_h = len(game_map.tiles) if game_map.tiles else 1
    scale_x = mm_size / map_w
    scale_y = mm_size / map_h

    step = max(1, int(1 / min(scale_x, scale_y)))
    for ty in range(0, map_h, step):
        for tx in range(0, len(game_map.tiles[ty]), step):
            tid = game_map.tiles[ty][tx]
            px = mm_x + tx * scale_x
            py = mm_y + (map_h - 1 - ty) * scale_y
            palette = TILE_PALETTE.get(tid, TILE_PALETTE.get(0))
            c = palette["base"]
            sw = max(1, scale_x * step)
            sh = max(1, scale_y * step)
            arcade.draw_rect_filled(arcade.LBWH(px, py, sw, sh), (*c, mm_alpha))

    for npc in npcs:
        nx = mm_x + (npc.position.x / (map_w * TS)) * mm_size
        ny = mm_y + (1 - npc.position.y / (map_h * TS)) * mm_size
        if npc.npc_type == NpcType.ENEMY:
            nc = (255, 60, 60, mm_alpha)
        elif npc.is_master:
            nc = (255, 220, 50, mm_alpha)
        else:
            nc = (100, 200, 255, mm_alpha)
        arcade.draw_circle_filled(nx, ny, 2, nc)

    px = mm_x + (player.position.x / (map_w * TS)) * mm_size
    py = mm_y + (1 - player.position.y / (map_h * TS)) * mm_size
    pulse = int(3 + math.sin(_anim_time * 3) * 1)
    arcade.draw_circle_filled(px, py, pulse, (255, 255, 255, mm_alpha))
    arcade.draw_circle_outline(px, py, pulse + 2, (255, 200, 100, mm_alpha), 1)

    _draw_text("地图", mm_x + mm_size // 2, mm_y - 10, (100, 110, 130, mm_alpha), 10, "center", "center")


# ──────────────────────────────────────────────
#  对话框
# ──────────────────────────────────────────────

def draw_dialog(text: str, sw: int, sh: int, title: str = "对话", dialog_type: str = "info"):
    global _dialog_text_full
    _dialog_text_full = text

    bw = sw - 80
    bh = 240
    x = 40
    y = 60

    arcade.draw_rect_filled(arcade.LBWH(x + 6, y - 6, bw, bh), (0, 0, 0, 50))
    arcade.draw_rect_filled(arcade.LBWH(x + 4, y - 4, bw, bh), (0, 0, 0, 30))

    type_colors = {
        "npc": (255, 200, 100), "combat": (255, 80, 80),
        "quest": (100, 200, 255), "info": (150, 180, 200),
        "encounter": (200, 100, 255),
    }
    border_color = type_colors.get(dialog_type, COLORS["accent"])

    _draw_gradient_rect(x, y, bw, bh, (18, 24, 42), (10, 14, 28), 6)

    for i in range(4):
        a = 40 - i * 10
        arcade.draw_rect_outline(arcade.LBWH(x + i, y + i, bw - i * 2, bh - i * 2),
                                 (*border_color, a), 1)

    header_h = 40
    _draw_gradient_rect(x + 2, y + bh - header_h - 2, bw - 4, header_h,
                        (*border_color[:3], 25), (*border_color[:3], 10), 3)
    arcade.draw_line(x + 2, y + bh - header_h - 2, x + bw - 2, y + bh - header_h - 2,
                     (*border_color, 80), 2)
    arcade.draw_line(x + 2, y + bh - header_h, x + bw - 2, y + bh - header_h,
                     (*border_color, 30), 1)

    avatar_size = 34
    avatar_x = x + 16
    avatar_y = y + bh - header_h // 2 - 2
    _draw_gradient_rect(avatar_x, avatar_y - avatar_size // 2, avatar_size, avatar_size,
                        (30, 38, 60), (20, 25, 42), 3)
    for i in range(2):
        a = 120 - i * 40
        arcade.draw_rect_outline(arcade.LBWH(avatar_x - i, avatar_y - avatar_size // 2 - i,
                                             avatar_size + i * 2, avatar_size + i * 2),
                                 (*border_color, a), 1)
    acx = avatar_x + avatar_size // 2
    acy = avatar_y
    skin_c = (220, 185, 155)
    hair_c = (30, 25, 25)
    if dialog_type == "combat":
        skin_c = (200, 160, 140)
        hair_c = (80, 30, 30)
    elif dialog_type == "quest":
        skin_c = (210, 190, 170)
        hair_c = (50, 40, 60)
    arcade.draw_circle_filled(acx, acy + 2, 7, skin_c)
    arcade.draw_ellipse_filled(acx, acy + 7, 14, 6, hair_c)
    arcade.draw_rect_filled(arcade.LBWH(acx - 6, acy - 9, 12, 11), border_color)
    arcade.draw_rect_filled(arcade.LBWH(acx - 4, acy - 7, 8, 7), _lighten(border_color, 15))
    for side in [-1, 1]:
        ex = acx + side * 2.5
        arcade.draw_circle_filled(ex, acy + 2, 1, (30, 25, 20))

    _draw_text(title, avatar_x + avatar_size + 12, y + bh - 22, border_color, 17, "left", "center")

    title_end = avatar_x + avatar_size + 12 + len(title) * 17 + 10
    arcade.draw_line(avatar_x + avatar_size + 10, y + bh - header_h + 4,
                     min(title_end, x + bw - 12), y + bh - header_h + 4,
                     (*border_color, 60), 1)
    dot_x = min(title_end, x + bw - 12)
    arcade.draw_circle_filled(dot_x, y + bh - header_h + 4, 2, (*border_color, 80))

    shown_text = text[:_dialog_chars_shown] if _dialog_chars_shown < len(text) else text
    text_y_start = y + bh - header_h - 16
    arcade.draw_text(shown_text, x + 24, text_y_start, COLORS["text"], 14,
                     font_name=FONT, width=bw - 48)

    if _dialog_chars_shown < len(text):
        cursor_x = x + 24
        cursor_y = text_y_start - 5
        blink = int(_anim_time * 3) % 2
        if blink:
            arcade.draw_rect_filled(arcade.LBWH(cursor_x, cursor_y, 8, 2), (*border_color, 150))

    if dialog_type == "encounter":
        enc_bg_x = x + bw // 2 - 120
        enc_bg_y = y + 8
        _draw_gradient_rect(enc_bg_x, enc_bg_y, 240, 28,
                            (*border_color[:3], 30), (*border_color[:3], 15), 2)
        arcade.draw_rect_outline(arcade.LBWH(enc_bg_x, enc_bg_y, 240, 28),
                                 (*border_color, 80), 1)
        _draw_text("[ Y 接受 | N 拒绝 ]", x + bw // 2, enc_bg_y + 14,
                   border_color, 13, "center", "center")
    else:
        _draw_text("[ 空格关闭 ]", x + bw - 20, y + 14, (70, 80, 100), 10, "right", "center")

    for i in range(3):
        deco_x = x + 10 + i * 8
        deco_y = y + bh - 6
        arcade.draw_circle_filled(deco_x, deco_y, 1.5, (*border_color, 40))
