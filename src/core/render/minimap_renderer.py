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
        draw = ImageDraw.Draw(img)

        step = max(2, int(1 / min(scx, scy)))
        for ty in range(0, map_h, step):
            row = game_map.tiles[ty]
            for tx in range(0, len(row), step):
                tid = row[tx]
                c = (TILE_PALETTE.get(tid) or TILE_PALETTE.get(0) or {"base": (128, 128, 128)})["base"]
                px = int(tx * scx)
                py = int((map_h - 1 - ty) * scy)
                pw = max(1, int(scx * step))
                ph = max(1, int(scy * step))
                draw.rectangle([px, py, px + pw, py + ph], fill=(*c, ma))

        import arcade
        texture = arcade.Texture(img)
        return texture
    except ImportError:
        return None
