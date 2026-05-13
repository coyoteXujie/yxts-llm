import arcade
from ..config import COLORS, VISUAL_CONFIG
from .draw_utils import (SW, SH, get_anim_time, lighten, darken, alpha,
                         draw_gradient_rect, draw_text)

_chars_shown = 999
_text_full = ""
_timer = 0.0
_hurt_flash = 0.0

TYPE_COLORS = {
    "npc": (180, 155, 100), "combat": (190, 85, 75),
    "quest": (120, 160, 180), "info": (150, 140, 125),
    "encounter": (160, 120, 150),
}


def set_dialog_text(text: str):
    global _text_full, _chars_shown, _timer
    if text != _text_full:
        _text_full = text
        _chars_shown = 0
        _timer = 0.0


def update_dialog_anim(dt: float):
    global _chars_shown, _timer
    if _chars_shown < len(_text_full):
        _timer += dt
        _chars_shown = min(len(_text_full), int(_timer * 28))


def set_hurt_flash(v: float):
    global _hurt_flash
    _hurt_flash = v


def get_hurt_flash() -> float:
    return _hurt_flash


def draw_dialog(text: str, sw: int, sh: int, title: str = "对话", dialog_type: str = "info"):
    global _text_full
    _text_full = text

    bw, bh = sw - 80, 250
    x, y = 40, 55
    t = get_anim_time()
    bc = TYPE_COLORS.get(dialog_type, COLORS["accent"])

    arcade.draw_rect_filled(arcade.LBWH(x + 8, y - 8, bw, bh), (0, 0, 0, 40))
    arcade.draw_rect_filled(arcade.LBWH(x + 5, y - 5, bw, bh), (0, 0, 0, 25))

    draw_gradient_rect(x, y, bw, bh, (55, 48, 38), (35, 30, 22), 8)
    arcade.draw_rect_filled(arcade.LBWH(x, y, bw, bh), (40, 35, 28, 50))
    arcade.draw_rect_filled(arcade.LBWH(x + bw * 0.5, y, bw * 0.5, bh), alpha(lighten((55, 48, 38), 5), 20))

    for i in range(4):
        a = 35 - i * 9
        arcade.draw_rect_outline(arcade.LBWH(x + i, y + i, bw - i * 2, bh - i * 2), (*bc, a), 1)

    hh = 42
    draw_gradient_rect(x + 2, y + bh - hh - 2, bw - 4, hh, (*bc[:3], 20), (*bc[:3], 8), 4)
    arcade.draw_rect_filled(arcade.LBWH(x + bw * 0.5, y + bh - hh - 2, bw * 0.5 - 2, hh),
                            alpha(lighten(bc[:3], 5), 8))
    arcade.draw_line(x + 2, y + bh - hh - 2, x + bw - 2, y + bh - hh - 2, (*bc, 70), 2)
    arcade.draw_line(x + 2, y + bh - hh, x + bw - 2, y + bh - hh, (*bc, 25), 1)

    _draw_dialog_avatar(x, y, bh, hh, bc, dialog_type)
    draw_text(title, x + 16 + 36 + 14, y + bh - 22, bc, 17, "left", "center")

    te = x + 16 + 36 + 14 + len(title) * 17 + 10
    arcade.draw_line(x + 16 + 36 + 12, y + bh - hh + 5, min(te, x + bw - 14), y + bh - hh + 5, (*bc, 50), 1)
    arcade.draw_circle_filled(min(te, x + bw - 14), y + bh - hh + 5, 2, (*bc, 70))

    shown = text[:_chars_shown] if _chars_shown < len(text) else text
    ty_start = y + bh - hh - 18
    arcade.draw_text(shown, x + 26, ty_start, COLORS["text"], 14, font_name="SimHei", width=bw - 52)

    if _chars_shown < len(text):
        blink = int(t * 3) % 2
        if blink:
            arcade.draw_rect_filled(arcade.LBWH(x + 26, ty_start - 5, 8, 2), (*bc, 140))

    if dialog_type == "encounter":
        ex = x + bw // 2 - 125
        ey = y + 10
        draw_gradient_rect(ex, ey, 250, 30, (*bc[:3], 25), (*bc[:3], 12), 3)
        arcade.draw_rect_filled(arcade.LBWH(ex + 125, ey, 125, 30), alpha(lighten(bc[:3], 5), 8))
        arcade.draw_rect_outline(arcade.LBWH(ex, ey, 250, 30), (*bc, 70), 1)
        draw_text("[ Y 接受 | N 拒绝 ]", x + bw // 2, ey + 15, bc, 13, "center", "center")
    else:
        draw_text("[ 空格关闭 ]", x + bw - 22, y + 16, (60, 70, 90), 10, "right", "center")

    for i in range(3):
        arcade.draw_circle_filled(x + 12 + i * 8, y + bh - 7, 1.5, (*bc, 35))


def _draw_dialog_avatar(x, y, bh, hh, bc, dtype):
    asz = 36
    ax = x + 16
    ay = y + bh - hh // 2 - 2
    draw_gradient_rect(ax - 2, ay - asz // 2 - 2, asz + 4, asz + 4, (60, 52, 42), (40, 35, 28), 3)
    draw_gradient_rect(ax, ay - asz // 2, asz, asz, (75, 65, 52), (50, 42, 32), 4)
    arcade.draw_rect_filled(arcade.LBWH(ax + asz * 0.5, ay - asz // 2, asz * 0.5, asz),
                            alpha(lighten((75, 65, 52), 8), 25))
    for i in range(2):
        a = 100 - i * 35
        arcade.draw_rect_outline(arcade.LBWH(ax - i, ay - asz // 2 - i, asz + i * 2, asz + i * 2), (*bc, a), 1)
    acx, acy = ax + asz // 2, ay
    skin = (225, 190, 160)
    hair = (30, 25, 25)
    if dtype == "combat":
        skin, hair = (200, 160, 140), (80, 30, 30)
    elif dtype == "quest":
        skin, hair = (210, 190, 170), (50, 40, 60)
    arcade.draw_circle_filled(acx, acy + 2, 7, darken(skin, 10))
    arcade.draw_circle_filled(acx + 0.5, acy + 2.5, 6.5, skin)
    arcade.draw_circle_filled(acx + 1, acy + 3, 4, lighten(skin, 15))
    arcade.draw_ellipse_filled(acx + 0.5, acy + 7, 14, 6, hair)
    arcade.draw_ellipse_filled(acx + 1.5, acy + 8, 9, 3, lighten(hair, 12))
    draw_gradient_rect(acx - 6, acy - 9, 12, 11, lighten(bc, 10), darken(bc, 10), 3)
    arcade.draw_rect_filled(arcade.LBWH(acx - 4, acy - 7, 4, 7), lighten(bc, 15))
    for side in [-1, 1]:
        arcade.draw_circle_filled(acx + side * 2.5, acy + 2, 1, (30, 25, 20))
        arcade.draw_circle_filled(acx + side * 2.5 + 0.3, acy + 2.3, 0.5, (255, 255, 255, 120))
