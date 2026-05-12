from .draw_utils import (SW, SH, TS, FONT, FONT_LATIN, set_anim_time, get_anim_time,
                         map_to_world, world_to_screen, draw_text,
                         lerp_color, lighten, darken, alpha, draw_gradient_rect)
from .tile_renderer import (draw_map, add_light_source, clear_light_sources,
                            invalidate_chunk_cache, WATER_TIDS, TREE_TIDS, BUILDING_TIDS,
                            ROAD_TIDS, WALL_TIDS, PLANT_TIDS, FLOWER_TIDS, COUNTER_TIDS,
                            DESK_TIDS, BENCH_TIDS, SHELF_TIDS, SCULPTURE_TIDS,
                            HILL_TIDS, STONE_TIDS)
from .char_renderer import (draw_character, get_appearance, Appearance, CharContext,
                            CHAR_VISUAL, FACTION_COLORS, WeaponLayer, HatLayer, RenderLayer)
from .hud_renderer import draw_hud
from .dialog_renderer import (draw_dialog, set_dialog_text, update_dialog_anim,
                              set_hurt_flash, get_hurt_flash)
from .minimap_renderer import draw_minimap
from .texture_gen import (apply_texture_noise, draw_water_tile, draw_grass_detail,
                           draw_road_detail, draw_soft_shadow, make_tile_texture)
from .post_process import get_post_processor, get_advanced_lights, get_env_particles, VolumetricLight
from .sprite_gen import (generate_tile_sprite, gen_character_sprite, gen_glass_panel, gen_hp_bar,
                          gen_grass_tile, gen_water_tile, gen_road_tile, gen_tree_tile,
                          gen_wall_tile, gen_building_tile, gen_flower_tile, gen_hill_tile)
from ..entities import Player, NPC
from .draw_utils import world_to_screen


def draw_player(player: Player, camera_x: float, camera_y: float):
    sx, sy = world_to_screen(player.position.x, player.position.y, camera_x, camera_y)
    if -40 <= sx <= SW + 40 and -40 <= sy <= SH + 40:
        draw_character(sx, sy, "player", is_player=True,
                       faction=player.faction,
                       hp_ratio=player.hp / player.max_hp if player.max_hp > 0 else 1.0,
                       hurt_flash=get_hurt_flash())


def draw_npc(npc: NPC, camera_x: float, camera_y: float):
    sx, sy = world_to_screen(npc.position.x, npc.position.y, camera_x, camera_y)
    if -40 <= sx <= SW + 40 and -40 <= sy <= SH + 40:
        hp_ratio = npc.hp / npc.max_hp if npc.max_hp > 0 else 1.0
        draw_character(sx, sy, npc.name, is_player=False,
                       npc_type=npc.npc_type.value,
                       faction=npc.faction,
                       hp_ratio=hp_ratio,
                       has_quest=npc.has_quests,
                       is_master=npc.is_master)
