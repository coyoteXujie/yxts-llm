import os

GAME_CONFIG = {
    "screen_width": 1440,
    "screen_height": 900,
    "screen_title": "白金英雄坛说",
    "fps": 60,
    "tile_size": 64,
    "map_width": 20,
    "map_height": 12,
    "camera_speed": 5,
    "player_speed": 3,
    "zoom_level": 1.0,
}

COLORS = {
    "background": (20, 30, 50),
    "ground": (80, 120, 80),
    "water": (60, 100, 180),
    "road": (100, 90, 80),
    "building": (130, 100, 80),
    "text": (255, 255, 255),
    "text_dark": (180, 180, 180),
    "accent": (255, 200, 100),
    "border": (100, 100, 100),
    "health": (255, 100, 100),
    "mana": (100, 150, 255),
    "gold": (255, 215, 0),
}

UI_CONFIG = {
    "hud_height": 80,
    "panel_width": 200,
    "text_size": 18,
    "title_size": 24,
    "button_size": (120, 40),
    "padding": 10,
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
TILES_DIR = os.path.join(ASSETS_DIR, "tiles")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
UI_DIR = os.path.join(ASSETS_DIR, "ui")
FONTS_DIR = os.path.join(ASSETS_DIR, "fonts")

VISUAL_CONFIG = {
    "shadow_enabled": True,
    "shadow_alpha": 40,
    "shadow_offset_x": 3,
    "shadow_offset_y": 5,
    "day_night_enabled": True,
    "day_night_speed": 0.003,
    "weather_enabled": True,
    "weather_change_interval": 180,
    "vignette_enabled": True,
    "vignette_intensity": 0.3,
    "ambient_particles": True,
    "ambient_particle_count": 30,
    "water_animation": True,
    "water_animation_speed": 0.02,
    "torch_flicker": True,
    "torch_flicker_speed": 5.0,
    "screen_shake_enabled": True,
    "screen_shake_decay": 0.9,
    "transition_duration": 0.5,
    "glow_enabled": True,
    "glow_intensity": 0.6,
    "fog_of_war": False,
    "minimap_enabled": True,
    "minimap_size": 160,
    "minimap_alpha": 180,
    "damage_number_enabled": True,
    "damage_number_duration": 1.2,
    "damage_number_rise_speed": 40,
    "footprint_enabled": True,
    "footprint_duration": 3.0,
    "npc_indicator": True,
    "quest_indicator": True,
    "interaction_radius_visual": False,
}

WEATHER_TYPES = ["clear", "cloudy", "rain", "heavy_rain", "snow", "fog", "mist"]

WEATHER_PARTICLE_COUNT = {
    "clear": 0,
    "cloudy": 0,
    "rain": 80,
    "heavy_rain": 200,
    "snow": 60,
    "fog": 0,
    "mist": 0,
}

WEATHER_OVERLAY = {
    "clear": None,
    "cloudy": (200, 200, 210, 15),
    "rain": (100, 110, 130, 25),
    "heavy_rain": (60, 70, 90, 45),
    "snow": (200, 210, 230, 20),
    "fog": (180, 185, 195, 60),
    "mist": (170, 175, 185, 35),
}

TILE_PALETTE = {
    0: {"base": (76, 153, 0), "detail": (60, 130, 0), "accent": (90, 170, 20)},
    1: {"base": (50, 100, 170), "detail": (40, 80, 150), "accent": (80, 140, 200)},
    2: {"base": (140, 120, 90), "detail": (120, 100, 70), "accent": (160, 140, 110)},
    3: {"base": (160, 140, 110), "detail": (140, 120, 90), "accent": (180, 160, 130)},
    4: {"base": (139, 90, 43), "detail": (120, 75, 35), "accent": (160, 110, 60)},
    5: {"base": (180, 175, 160), "detail": (160, 155, 140), "accent": (200, 195, 180)},
    6: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    7: {"base": (70, 130, 70), "detail": (55, 110, 55), "accent": (85, 150, 85)},
    8: {"base": (90, 70, 50), "detail": (75, 55, 40), "accent": (110, 90, 70)},
    9: {"base": (200, 50, 50), "detail": (170, 40, 40), "accent": (230, 70, 70)},
    10: {"base": (180, 160, 100), "detail": (160, 140, 80), "accent": (200, 180, 120)},
    11: {"base": (100, 140, 100), "detail": (80, 120, 80), "accent": (120, 160, 120)},
    12: {"base": (150, 130, 100), "detail": (130, 110, 80), "accent": (170, 150, 120)},
    13: {"base": (60, 100, 60), "detail": (45, 80, 45), "accent": (75, 120, 75)},
    14: {"base": (110, 90, 70), "detail": (90, 75, 55), "accent": (130, 110, 90)},
    15: {"base": (170, 165, 150), "detail": (150, 145, 130), "accent": (190, 185, 170)},
    16: {"base": (80, 60, 40), "detail": (65, 45, 30), "accent": (100, 80, 60)},
    17: {"base": (120, 100, 80), "detail": (100, 80, 60), "accent": (140, 120, 100)},
    18: {"base": (90, 80, 70), "detail": (70, 60, 50), "accent": (110, 100, 90)},
    19: {"base": (160, 140, 100), "detail": (140, 120, 80), "accent": (180, 160, 120)},
    20: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    21: {"base": (80, 120, 80), "detail": (60, 100, 60), "accent": (100, 140, 100)},
    22: {"base": (60, 100, 60), "detail": (45, 80, 45), "accent": (75, 120, 75)},
    23: {"base": (140, 120, 90), "detail": (120, 100, 70), "accent": (160, 140, 110)},
    24: {"base": (200, 190, 160), "detail": (180, 170, 140), "accent": (220, 210, 180)},
    25: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    26: {"base": (180, 50, 50), "detail": (150, 40, 40), "accent": (210, 70, 70)},
    27: {"base": (50, 50, 150), "detail": (40, 40, 130), "accent": (70, 70, 170)},
    28: {"base": (150, 130, 100), "detail": (130, 110, 80), "accent": (170, 150, 120)},
    29: {"base": (100, 140, 100), "detail": (80, 120, 80), "accent": (120, 160, 120)},
    30: {"base": (120, 100, 80), "detail": (100, 80, 60), "accent": (140, 120, 100)},
    31: {"base": (80, 120, 80), "detail": (60, 100, 60), "accent": (100, 140, 100)},
    32: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    33: {"base": (60, 100, 60), "detail": (45, 80, 45), "accent": (75, 120, 75)},
    34: {"base": (140, 120, 90), "detail": (120, 100, 70), "accent": (160, 140, 110)},
    35: {"base": (180, 160, 100), "detail": (160, 140, 80), "accent": (200, 180, 120)},
    36: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    37: {"base": (80, 120, 80), "detail": (60, 100, 60), "accent": (100, 140, 100)},
    38: {"base": (60, 100, 60), "detail": (45, 80, 45), "accent": (75, 120, 75)},
    39: {"base": (200, 210, 230), "detail": (180, 190, 210), "accent": (220, 230, 250)},
    40: {"base": (220, 230, 250), "detail": (200, 210, 230), "accent": (240, 250, 255)},
    41: {"base": (200, 80, 30), "detail": (180, 60, 20), "accent": (230, 100, 50)},
    42: {"base": (80, 100, 60), "detail": (60, 80, 40), "accent": (100, 120, 80)},
    43: {"base": (140, 100, 80), "detail": (120, 80, 60), "accent": (160, 120, 100)},
    44: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    45: {"base": (160, 140, 100), "detail": (140, 120, 80), "accent": (180, 160, 120)},
    46: {"base": (180, 160, 120), "detail": (160, 140, 100), "accent": (200, 180, 140)},
    47: {"base": (80, 80, 90), "detail": (60, 60, 70), "accent": (100, 100, 110)},
    48: {"base": (100, 80, 60), "detail": (80, 65, 45), "accent": (120, 100, 80)},
    49: {"base": (180, 50, 50), "detail": (150, 40, 40), "accent": (210, 70, 70)},
}

BUILDING_COLORS = {
    "default": {"wall": (160, 130, 100), "roof": (140, 60, 40), "door": (100, 70, 40), "window": (180, 200, 220)},
    "BAGUA": {"wall": (140, 120, 100), "roof": (60, 60, 80), "door": (80, 60, 40), "window": (160, 180, 200)},
    "FLOWER": {"wall": (160, 140, 120), "roof": (180, 80, 100), "door": (100, 70, 40), "window": (200, 180, 200)},
    "HONGLIAN": {"wall": (150, 110, 90), "roof": (180, 40, 40), "door": (90, 60, 35), "window": (200, 160, 160)},
    "NAJA": {"wall": (130, 120, 110), "roof": (60, 80, 60), "door": (80, 70, 50), "window": (160, 200, 180)},
    "TAIJI": {"wall": (170, 160, 150), "roof": (80, 80, 80), "door": (100, 80, 60), "window": (180, 200, 220)},
    "XUESHAN": {"wall": (190, 190, 200), "roof": (100, 120, 160), "door": (110, 90, 70), "window": (200, 220, 240)},
    "XIAOYAO": {"wall": (150, 160, 140), "roof": (120, 140, 100), "door": (90, 80, 60), "window": (180, 200, 180)},
}

CHAR_PALETTE = {
    "skin": [(235, 200, 170), (220, 185, 155), (200, 165, 130), (180, 140, 110)],
    "hair_black": (30, 25, 25),
    "hair_brown": (80, 50, 30),
    "hair_white": (220, 215, 210),
    "hair_red": (160, 50, 30),
    "cloth_white": (240, 235, 230),
    "cloth_black": (35, 30, 35),
    "cloth_blue": (60, 80, 140),
    "cloth_red": (180, 50, 40),
    "cloth_green": (60, 120, 60),
    "cloth_purple": (100, 60, 120),
    "cloth_gold": (200, 170, 80),
    "cloth_gray": (120, 115, 110),
    "cloth_brown": (130, 90, 50),
    "armor_iron": (140, 140, 150),
    "armor_steel": (170, 175, 185),
    "armor_gold": (220, 190, 80),
    "armor_dark": (60, 55, 65),
}
