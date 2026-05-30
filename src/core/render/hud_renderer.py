import arcade
import math
from ..config import COLORS, CHAR_PALETTE, VISUAL_CONFIG
from ..entities import Player, Faction, FACTION_NAMES
from .draw_utils import (SW, SH, get_anim_time, lighten, darken, alpha,
                         draw_gradient_rect, draw_text)
from .char_renderer import FACTION_COLORS


def draw_hud(player: Player, game_time: float = 0, current_map=None,
             atmosphere=None, reputation=None, economy=None):
    hud_h = 100
    _draw_hud_background(hud_h)
    _draw_avatar(hud_h, player)
    _draw_name_info(hud_h, player)
    _draw_bars(hud_h, player)
    _draw_survival_bars(hud_h, player)
    _draw_atmosphere(hud_h, atmosphere)
    _draw_reputation(hud_h, reputation, economy)
    _draw_zone_indicator(hud_h, current_map)
    _draw_hints(hud_h)
    _draw_skill_bar(hud_h, player)


def _draw_hud_background(hud_h):
    draw_gradient_rect(0, 0, SW, hud_h, (55, 48, 38), (35, 30, 22), 8)
    arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, hud_h), (40, 35, 28, 80))
    arcade.draw_line(0, hud_h - 4, SW, hud_h - 4, (180, 155, 100, 8), 1)
    arcade.draw_line(0, hud_h - 2, SW, hud_h - 2, (180, 155, 100, 15), 1)
    arcade.draw_rect_filled(arcade.LBWH(0, hud_h - 1, SW, 2), (180, 155, 100, 50))
    for i in range(2):
        a = 30 - i * 12
        arcade.draw_rect_outline(arcade.LBWH(i, i, SW - i * 2, hud_h - i * 2), (180, 155, 100, a), 1)
    arcade.draw_line(0, 3, SW, 3, (120, 105, 80, 15), 1)


def _draw_avatar(hud_h, player):
    ax, ay, asz = 14, hud_h - 42, 48
    draw_gradient_rect(ax - 2, ay - 2, asz + 4, asz + 4, (60, 52, 42), (40, 35, 28), 3)
    draw_gradient_rect(ax, ay, asz, asz, (75, 65, 52), (50, 42, 32), 4)
    arcade.draw_rect_filled(arcade.LBWH(ax + asz * 0.5, ay + asz * 0.5, asz * 0.5, asz * 0.5),
                            alpha(lighten((75, 65, 52), 10), 30))
    for i in range(3):
        a = 80 - i * 25
        arcade.draw_rect_outline(arcade.LBWH(ax - i, ay - i, asz + i * 2, asz + i * 2), (180, 155, 100, a), 1)
    skin = CHAR_PALETTE["skin"][0]
    hair = CHAR_PALETTE["hair_black"]
    cloth = CHAR_PALETTE.get("cloth_blue", CHAR_PALETTE["cloth_blue"])
    acx, acy = ax + asz // 2, ay + asz // 2
    arcade.draw_circle_filled(acx, acy + 4, 10, skin)
    arcade.draw_circle_filled(acx + 1, acy + 5, 7, lighten(skin, 12))
    arcade.draw_ellipse_filled(acx + 1, acy + 10, 20, 8, hair)
    arcade.draw_ellipse_filled(acx + 2, acy + 11, 12, 4, lighten(hair, 15))
    draw_gradient_rect(acx - 8, acy - 10, 16, 14, lighten(cloth, 15), cloth, 3)
    arcade.draw_rect_filled(arcade.LBWH(acx - 5, acy - 8, 4, 10), lighten(cloth, 20))
    fc = FACTION_COLORS.get(player.faction, (150, 150, 150))
    arcade.draw_circle_filled(acx + asz // 2 - 5, acy + 8, 4, darken(fc, 20))
    arcade.draw_circle_filled(acx + asz // 2 - 5, acy + 8, 3, fc)
    arcade.draw_circle_outline(acx + asz // 2 - 5, acy + 8, 4, (255, 255, 255, 120), 1)
    arcade.draw_circle_filled(acx + asz // 2 - 4, acy + 9, 1.5, (255, 255, 255, 150))


def _draw_name_info(hud_h, player):
    nx, ny = 72, hud_h - 18
    draw_text(player.name, nx, ny, COLORS["accent"], 18, "left", "center")
    faction_name = FACTION_NAMES.get(player.faction, '未知门派')
    draw_text(faction_name, nx, ny - 22, (140, 150, 170), 11, "left", "center")
    draw_text(f"Lv.{player.level}", nx + 100, ny, (200, 200, 200), 14, "left", "center")


def _draw_bars(hud_h, player):
    bx, bw, bh = 190, 210, 18
    _draw_bar(bx, hud_h - 16, bw, bh, player.hp, player.max_hp,
              (60, 200, 60), (200, 180, 40), (220, 50, 50), (40, 15, 15), (80, 30, 30), "HP")
    _draw_bar(bx, hud_h - 40, bw, bh, player.mp, player.max_mp,
              (60, 100, 220), (60, 100, 220), (60, 100, 220), (15, 20, 50), (30, 40, 80), "MP")
    ey = hud_h - 62
    exp_ratio = player.exp / player.exp_for_next_level if player.exp_for_next_level > 0 else 0
    arcade.draw_rect_filled(arcade.LBWH(bx - 1, ey - 1, bw + 2, 10), (0, 0, 0, 60))
    arcade.draw_rect_filled(arcade.LBWH(bx, ey, bw, 8), (20, 20, 30))
    ef = max(1, int(bw * min(1.0, exp_ratio)))
    draw_gradient_rect(bx, ey, ef, 8, (230, 210, 90), (160, 140, 40), 3)
    arcade.draw_rect_filled(arcade.LBWH(bx, ey + 5, ef, 3), alpha(lighten((230, 210, 90), 30), 40))
    arcade.draw_rect_outline(arcade.LBWH(bx, ey, bw, 8), (60, 50, 30), 1)
    draw_text(f"EXP {player.exp}/{player.exp_for_next_level}", bx + bw / 2, ey + 4, (200, 190, 150), 8, "center", "center")


def _draw_bar(x, y, w, h, current, maximum, c_high, c_mid, c_low, bg, border, label):
    arcade.draw_rect_filled(arcade.LBWH(x - 1, y - 1, w + 2, h + 2), (0, 0, 0, 80))
    draw_gradient_rect(x, y, w, h, lighten(bg, 5), darken(bg, 5), 3)
    ratio = current / maximum if maximum > 0 else 0
    fw = max(1, int(w * ratio))
    c = c_high if ratio > 0.5 else (c_mid if ratio > 0.25 else c_low)
    draw_gradient_rect(x, y, fw, h, lighten(c, 25), darken(c, 10), 4)
    arcade.draw_rect_filled(arcade.LBWH(x, y + h - 4, fw, 4), alpha(lighten(c, 35), 45))
    arcade.draw_rect_filled(arcade.LBWH(x, y + h - 2, fw, 2), alpha(lighten(c, 50), 25))
    arcade.draw_rect_outline(arcade.LBWH(x, y, w, h), border, 1)
    draw_text(f"{label} {current}/{maximum}", x + w / 2, y + h / 2, (255, 255, 255), 10, "center", "center")


def _draw_atmosphere(hud_h, atmosphere):
    """绘制时辰天气"""
    if atmosphere is None:
        return
    # 时间
    time_text = atmosphere.get_status_text()
    draw_text(time_text, SW - 240, hud_h - 16, (220, 210, 180), 12, "left", "center")
    # 天气图标颜色
    weather_colors = {
        "晴朗": (255, 220, 100), "多云": (200, 200, 210),
        "细雨": (150, 180, 220), "暴雨": (100, 130, 200),
        "飞雪": (240, 240, 255), "大雪": (220, 230, 255),
        "狂风": (200, 180, 150), "迷雾": (180, 180, 190),
        "雷雨": (120, 100, 180)
    }
    weather = atmosphere.weather.get_weather_name() if hasattr(atmosphere, 'weather') else ""
    wc = weather_colors.get(weather, (200, 200, 200))
    arcade.draw_circle_filled(SW - 260, hud_h - 10, 4, (*wc, 200))


def _draw_reputation(hud_h, reputation, economy):
    """绘制声望和金钱"""
    gold = economy.gold if economy else 0
    fame = reputation.fame if reputation else 0
    # 金钱
    draw_text(f"银两: {gold}", SW - 380, hud_h - 40, (220, 200, 100), 12, "left", "center")
    # 声望
    draw_text(f"声望: {fame}", SW - 380, hud_h - 60, (200, 180, 220), 11, "left", "center")
    # 正邪
    if reputation:
        alignment = reputation.alignment
        align_color = (100, 200, 100) if alignment > 0 else ((200, 100, 100) if alignment < 0 else (180, 180, 180))
        draw_text(f"正邪: {alignment:+d}", SW - 280, hud_h - 60, align_color, 11, "left", "center")


def _draw_survival_bars(hud_h, player):
    bx = 190
    bw = 100
    bh = 10
    food = getattr(player, 'food', 100)
    water = getattr(player, 'water', 100)
    food_y = hud_h - 58
    water_y = hud_h - 72

    for label, val, y, c_full, c_low in [
        ("食", food, food_y, (180, 140, 60), (180, 80, 40)),
        ("水", water, water_y, (80, 140, 200), (140, 60, 60)),
    ]:
        draw_text(label, bx - 14, y + bh // 2, (140, 130, 110), 10, "center", "center")
        arcade.draw_rect_filled(arcade.LBWH(bx, y, bw, bh), (20, 18, 15))
        fill = max(1, int(bw * val / 100))
        c = c_full if val > 30 else c_low
        draw_gradient_rect(bx, y, fill, bh, lighten(c, 20), darken(c, 10), 2)
        arcade.draw_rect_outline(arcade.LBWH(bx, y, bw, bh), (80, 70, 55), 1)
        draw_text(f"{int(val)}", bx + bw + 8, y + bh // 2, (160, 150, 130), 9, "left", "center")


def _draw_attributes(hud_h, player):
    ax = 550
    attrs = [
        ("力", player.strength, (220, 150, 150)),
        ("敏", player.dexterity, (150, 220, 150)),
        ("智", player.intelligence, (150, 150, 220)),
        ("体", player.constitution, (220, 200, 150)),
    ]
    for i, (label, val, color) in enumerate(attrs):
        x = ax + i * 55
        draw_gradient_rect(x - 2, hud_h - 24, 48, 18, (*color, 12), (*color, 6), 2)
        arcade.draw_rect_outline(arcade.LBWH(x - 2, hud_h - 24, 48, 18), (*color, 20), 1)
        draw_text(label, x + 2, hud_h - 15, (100, 100, 110), 10, "left", "center")
        draw_text(f"{val}", x + 16, hud_h - 15, color, 14, "left", "center")


def _draw_zone_indicator(hud_h, current_map):
    if not current_map:
        return
    zone_name = current_map.name
    zone_type = current_map.zone_type
    type_icons = {
        "city": "城", "town": "镇", "sect": "门", "wild": "野"
    }
    icon = type_icons.get(zone_type, "")
    zx = SW - 15
    zy = hud_h - 40
    tw = len(zone_name) * 12 + 50
    zx_start = zx - tw
    draw_gradient_rect(zx_start, zy - 10, tw, 20, (50, 42, 32, 180), (35, 30, 22, 180), 3)
    arcade.draw_rect_outline(arcade.LBWH(zx_start, zy - 10, tw, 20), (180, 155, 100, 40), 1)
    if icon:
        draw_text(f"〔{icon}〕", zx_start + 8, zy, (160, 140, 100), 11, "left", "center")
    draw_text(zone_name, zx_start + 30, zy, (200, 180, 130), 13, "left", "center")


def _draw_hints(hud_h):
    draw_text("[T]对话 [F]攻击 [E]使用 [B]背包 [K]技能 [R]休息 [P]声望 [G]装备", SW - 15, hud_h - 16, (70, 80, 100), 10, "right", "center")


def _draw_skill_bar(hud_h, player):
    if not player.skills:
        return
    sx, sy = SW - 15, hud_h - 42
    shown = player.skills[:4]
    for i, sk in enumerate(shown):
        x = sx - (len(shown) - 1 - i) * 36
        draw_gradient_rect(x - 14, sy - 12, 28, 24, (35, 45, 68), (15, 20, 35), 3)
        arcade.draw_rect_filled(arcade.LBWH(x - 12, sy - 10, 24, 20), (25, 32, 52))
        arcade.draw_rect_filled(arcade.LBWH(x - 10, sy - 8, 10, 16), alpha(lighten((25, 32, 52), 8), 50))
        arcade.draw_rect_outline(arcade.LBWH(x - 14, sy - 12, 28, 24), (80, 100, 140, 100), 1)
        tc = {0: (255, 150, 150), 1: (150, 200, 255), 2: (255, 180, 100), 3: (200, 150, 255), 4: (150, 255, 200)}.get(sk.type, (200, 200, 200))
        draw_text(sk.name[0] if sk.name else "?", x, sy, tc, 12, "center", "center")
        draw_text(f"{sk.level}", x + 10, sy - 8, (180, 180, 180), 8, "left", "center")
