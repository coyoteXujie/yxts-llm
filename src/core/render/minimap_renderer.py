import math
from ..config import TILE_PALETTE, VISUAL_CONFIG
from ..entities import NpcType
from .draw_utils import (SW, SH, TS, get_anim_time, draw_text)

_minimap_texture = None
_minimap_dirty = True


def draw_minimap(camera_x, camera_y, game_map, player, npcs):
    if not VISUAL_CONFIG["minimap_enabled"] or not game_map:
        return
    import arcade

    ms = VISUAL_CONFIG["minimap_size"]
    ma = VISUAL_CONFIG["minimap_alpha"]
    mx = SW - ms - 15
    my = SH - ms - 15

    arcade.draw_rect_filled(arcade.LBWH(mx - 2, my - 2, ms + 4, ms + 4), (10, 16, 30, 220))
    arcade.draw_rect_outline(arcade.LBWH(mx - 2, my - 2, ms + 4, ms + 4), (60, 70, 90, ma), 1)

    global _minimap_texture, _minimap_dirty
    if _minimap_texture is None or _minimap_dirty:
        _minimap_texture = _render_minimap_to_texture(game_map, ms, ma)
        _minimap_dirty = False

    if _minimap_texture:
        arcade.draw_texture_rect(_minimap_texture, arcade.LBWH(mx, my, ms, ms))

    map_w = len(game_map.tiles[0]) if game_map.tiles else 1
    map_h = len(game_map.tiles) if game_map.tiles else 1
    if map_w <= 0 or map_h <= 0:
        return
    for npc in npcs:
        nx = mx + (npc.position.x / (map_w * TS)) * ms
        ny = my + (1 - npc.position.y / (map_h * TS)) * ms
        if nx < mx or nx > mx + ms or ny < my or ny > my + ms:
            continue
        if npc.npc_type == NpcType.ENEMY:
            nc = (255, 60, 60, ma)
        elif npc.is_master:
            nc = (255, 220, 50, ma)
        else:
            nc = (100, 200, 255, ma)
        arcade.draw_circle_filled(nx, ny, 2, nc)

    px = mx + (player.position.x / (map_w * TS)) * ms
    py = my + (1 - player.position.y / (map_h * TS)) * ms
    pulse = int(3 + math.sin(get_anim_time() * 3) * 1)
    arcade.draw_circle_filled(px, py, pulse, (255, 255, 255, ma))
    arcade.draw_circle_outline(px, py, pulse + 2, (255, 200, 100, ma), 1)

    draw_text("地图", mx + ms // 2, my - 10, (100, 110, 130), 10, "center", "center")


def _render_minimap_to_texture(game_map, ms, ma):
    try:
        from PIL import Image, ImageDraw
        map_w = len(game_map.tiles[0]) if game_map.tiles else 1
        map_h = len(game_map.tiles) if game_map.tiles else 1
        scx, scy = ms / map_w, ms / map_h

        img = Image.new('RGBA', (ms, ms), (16, 22, 36, 200))
        draw_img = ImageDraw.Draw(img)

        # 地形颜色映射
        terrain_colors = {
            0: (76, 140, 60, 200),       # 草地
            1: (180, 155, 105, 200),     # 土路
            2: (50, 90, 150, 220),       # 水域
            3: (170, 145, 110, 220),     # 建筑
            4: (70, 110, 45, 220),        # 森林
            5: (65, 120, 48, 200),       # 深草
            6: (200, 180, 140, 200),     # 沙地
            7: (130, 100, 60, 220),      # 桥梁
            8: (140, 125, 100, 220),     # 墙
            9: (160, 80, 70, 220),       # 商店
            10: (160, 155, 145, 220),    # 石板路
            11: (120, 140, 110, 200),    # 花园
            13: (100, 110, 90, 220),     # 客栈
            14: (180, 165, 140, 220),    # 寺庙
            16: (140, 90, 70, 220),      # 红屋顶
            17: (100, 110, 140, 220),    # 蓝屋顶
            18: (200, 180, 100, 220),    # 金屋顶
            20: (180, 160, 50, 240),     # 大门
            21: (80, 120, 160, 200),     # 井
            23: (200, 170, 50, 220),     # 宝箱
            25: (140, 130, 100, 220),    # 训练场
            26: (100, 155, 60, 220),     # 竹子
            39: (180, 200, 100, 200),    # 稻田
            51: (55, 105, 35, 220),      # 松树
            52: (65, 115, 45, 220),      # 柳树
            53: (70, 120, 48, 220),      # 竹树
            90: (150, 130, 110, 220),    # 民居
            93: (145, 130, 100, 200),    # 小山
            94: (150, 140, 120, 200),    # 中山
            95: (155, 148, 130, 200),    # 大山
            103: (155, 148, 135, 220),   # 石墙
            105: (40, 75, 130, 220),     # 湖泊
            106: (170, 145, 105, 200),   # 土路(新)
            107: (175, 165, 145, 200),   # 庭院
        }

        step = max(1, int(2 / min(scx, scy)))
        for ty in range(0, map_h, step):
            row = game_map.tiles[ty]
            for tx in range(0, len(row), step):
                tid = row[tx]
                c = terrain_colors.get(tid, TILE_PALETTE.get(tid, TILE_PALETTE.get(0, {"base": (128, 128, 128)}))["base"])
                if isinstance(c, tuple) and len(c) == 3:
                    c = (*c, 200)
                elif isinstance(c, tuple) and len(c) == 4:
                    pass
                else:
                    c_val = c.get("base", (128, 128, 128)) if isinstance(c, dict) else (128, 128, 128)
                    c = (*c_val, 200)
                px = int(tx * scx)
                py = int((map_h - 1 - ty) * scy)
                pw = max(1, int(scx * step))
                ph = max(1, int(scy * step))
                draw_img.rectangle([px, py, px + pw, py + ph], fill=c)

        import arcade
        texture = arcade.Texture(img)
        return texture
    except ImportError:
        return None
