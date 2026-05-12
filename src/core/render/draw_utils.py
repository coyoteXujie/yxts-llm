import arcade
import math
from typing import Optional, Tuple
from ..config import GAME_CONFIG, VISUAL_CONFIG

SW = GAME_CONFIG["screen_width"]
SH = GAME_CONFIG["screen_height"]
TS = GAME_CONFIG["tile_size"]

FONT = "SimHei"
FONT_LATIN = "Arial"

_text_cache = {}
_anim_time = 0.0


def set_anim_time(t: float):
    global _anim_time
    _anim_time = t


def get_anim_time() -> float:
    return _anim_time


def map_to_world(tx: int, ty: int, map_h: int) -> Tuple[float, float]:
    return tx * TS + TS / 2, (map_h - 1 - ty) * TS + TS / 2


def world_to_screen(wx: float, wy: float, cam_x: float, cam_y: float) -> Tuple[float, float]:
    return wx - cam_x + SW / 2, wy - cam_y + SH / 2


def draw_text(text, x, y, color, size, anchor_x="left", anchor_y="center", width=None):
    w = width if width else 0
    key = (text, int(x), int(y), color, size, anchor_x, anchor_y, w)
    if key not in _text_cache:
        t = arcade.Text(text, x, y, color, size, font_name=FONT,
                        anchor_x=anchor_x, anchor_y=anchor_y, width=w)
        _text_cache[key] = t
    _text_cache[key].draw()


def lerp_color(c1, c2, t):
    n = min(len(c1), len(c2))
    return tuple(int(a + (b - a) * t) for a, b in zip(c1[:n], c2[:n]))


def lighten(c, amount=30):
    return tuple(min(255, v + amount) for v in c[:3])


def darken(c, amount=30):
    return tuple(max(0, v - amount) for v in c[:3])


def alpha(c, a):
    return (*c[:3], a)


def draw_gradient_rect(x, y, w, h, color_top, color_bot, steps=3):
    step_h = h / steps
    for i in range(steps):
        t = i / max(1, steps - 1)
        c = lerp_color(color_top, color_bot, t)
        arcade.draw_rect_filled(arcade.LBWH(x, y + h - (i + 1) * step_h, w, step_h + 1), c)
