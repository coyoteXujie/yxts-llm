import arcade
import math
from typing import Optional, Dict
from dataclasses import dataclass, field
from ..config import CHAR_PALETTE, VISUAL_CONFIG
from ..entities import Faction
from .draw_utils import (get_anim_time, lighten, darken, alpha, draw_gradient_rect, draw_text, FONT_LATIN)

FACTION_COLORS = {
    Faction.BAGUA: (60, 60, 180), Faction.FLOWER: (180, 80, 150),
    Faction.HONGLIAN: (200, 50, 50), Faction.NAJA: (50, 150, 80),
    Faction.TAIJI: (180, 180, 180), Faction.XUESHAN: (150, 180, 220),
    Faction.XIAOYAO: (120, 180, 100), Faction.NONE: (150, 150, 150),
}

PERSONA_COLORS = {
    "commoner": {"main": (160, 130, 80), "accent": (120, 90, 50)},
    "hero": {"main": (220, 230, 245), "accent": (50, 80, 180)},
    "warrior": {"main": (70, 85, 150), "accent": (170, 175, 190)},
    "master_warrior": {"main": (90, 50, 150), "accent": (255, 210, 50)},
    "guard": {"main": (139, 0, 0), "accent": (218, 165, 32)},
    "bandit": {"main": (74, 55, 40), "accent": (139, 0, 0)},
    "bandit_boss": {"main": (50, 35, 25), "accent": (200, 160, 40)},
    "merchant": {"main": (170, 125, 45), "accent": (210, 175, 75)},
    "rich_merchant": {"main": (218, 165, 32), "accent": (255, 240, 120)},
    "servant": {"main": (110, 100, 85), "accent": (150, 140, 125)},
    "elder": {"main": (145, 135, 120), "accent": (185, 175, 160)},
    "sage": {"main": (200, 190, 160), "accent": (180, 160, 100)},
    "immortal": {"main": (176, 196, 222), "accent": (147, 112, 219)},
    "girl": {"main": (185, 95, 165), "accent": (245, 175, 215)},
    "warrior_girl": {"main": (185, 55, 75), "accent": (225, 95, 115)},
    "fairy": {"main": (200, 160, 230), "accent": (255, 200, 255)},
    "assassin_girl": {"main": (50, 40, 55), "accent": (180, 40, 40)},
    "woman": {"main": (200, 80, 100), "accent": (240, 130, 150)},
    "old_woman": {"main": (160, 145, 155), "accent": (190, 175, 185)},
    "child": {"main": (80, 160, 80), "accent": (140, 220, 140)},
    "noble": {"main": (225, 185, 45), "accent": (255, 245, 135)},
    "wanderer": {"main": (80, 75, 65), "accent": (120, 115, 100)},
    "brute": {"main": (140, 70, 30), "accent": (180, 100, 40)},
    "dark_warrior": {"main": (100, 15, 15), "accent": (60, 5, 5)},
    "dark_master": {"main": (60, 10, 20), "accent": (140, 25, 25)},
    "monk": {"main": (190, 160, 60), "accent": (218, 165, 32)},
    "demon": {"main": (80, 10, 60), "accent": (180, 30, 80)},
}


@dataclass
class Appearance:
    skin_color: tuple = (235, 200, 170)
    hair_color: tuple = (30, 25, 25)
    cloth_color: tuple = (60, 80, 140)
    cloth_color2: Optional[tuple] = None
    weapon: Optional[str] = None
    hat: Optional[str] = None
    body_scale: float = 1.0
    gender: str = "male"
    beard: Optional[str] = None
    accessory: Optional[str] = None
    persona: str = "commoner"

    @property
    def skin_hi(self):
        return lighten(self.skin_color, 35)

    @property
    def skin_sh(self):
        return darken(self.skin_color, 30)

    @property
    def cloth_hi(self):
        return lighten(self.cloth_color, 40)

    @property
    def cloth_mid(self):
        return self.cloth_color

    @property
    def cloth_sh(self):
        return darken(self.cloth_color, 30)

    @property
    def cloth_ds(self):
        return darken(self.cloth_color, 50)

    @property
    def c2_hi(self):
        return lighten(self.cloth_color2, 30) if self.cloth_color2 else self.cloth_hi

    @property
    def c2_mid(self):
        return self.cloth_color2 if self.cloth_color2 else self.cloth_mid

    @property
    def c2_sh(self):
        return darken(self.cloth_color2, 25) if self.cloth_color2 else self.cloth_sh

    @property
    def pc(self):
        return PERSONA_COLORS.get(self.persona, PERSONA_COLORS["commoner"])

    @property
    def main_color(self):
        return self.pc["main"]

    @property
    def accent_color(self):
        return self.pc["accent"]


@dataclass
class CharContext:
    sx: float
    sy: float
    name: str = ""
    facing: str = "down"
    is_player: bool = False
    npc_type: str = "normal"
    faction: Faction = Faction.NONE
    hp_ratio: float = 1.0
    has_quest: bool = False
    is_master: bool = False
    hurt_flash: float = 0.0
    appearance: Appearance = field(default_factory=Appearance)

    @property
    def t(self):
        return get_anim_time()

    @property
    def breathe(self):
        return math.sin(self.t * 2.5 + hash(self.name) % 100 * 0.01) * 0.8

    @property
    def sc(self):
        return self.appearance.body_scale

    @property
    def body_y(self):
        return self.sy + 2 * self.sc + self.breathe

    @property
    def head_y(self):
        return self.sy + 22 * self.sc + self.breathe

    @property
    def walk_phase(self):
        return math.sin(self.t * 7) if self.is_player else math.sin(self.t * 3.5 + hash(self.name) % 50)


CHAR_VISUAL = {
    "player": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "weapon": "sword", "body": 1.0, "gender": "male", "persona": "hero"},
    "平阿四": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0, "hat": "trader", "body": 1.0, "gender": "male", "persona": "merchant"},
    "店小二": {"hair": "hair_black", "cloth": "cloth_gray", "skin": 0, "hat": "waiter", "body": 0.85, "gender": "male", "persona": "servant"},
    "阎商": {"hair": "hair_brown", "cloth": "cloth_gold", "skin": 0, "hat": "trader", "body": 1.15, "gender": "male", "persona": "rich_merchant"},
    "葛朗台": {"hair": "hair_brown", "cloth": "cloth_gold", "cloth2": "cloth_red", "skin": 0, "hat": "trader", "body": 1.2, "gender": "male", "beard": "goatee", "persona": "rich_merchant"},
    "阿青": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "body": 0.75, "gender": "female", "persona": "girl"},
    "厨师": {"hair": "hair_black", "cloth": "cloth_white", "skin": 0, "hat": "waiter", "body": 1.1, "gender": "male", "accessory": "apron", "persona": "servant"},
    "屠夫": {"hair": "hair_black", "cloth": "cloth_brown", "cloth2": "cloth_red", "skin": 1, "weapon": "cleaver", "body": 1.4, "gender": "male", "persona": "brute"},
    "卖花女": {"hair": "hair_black", "cloth": "cloth_purple", "skin": 0, "body": 0.75, "gender": "female", "accessory": "flower_basket", "persona": "girl"},
    "小商贩": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0, "hat": "trader", "body": 0.9, "gender": "male", "persona": "merchant"},
    "平一指": {"hair": "hair_white", "cloth": "cloth_green", "skin": 1, "hat": "trader", "body": 0.8, "gender": "male", "beard": "long", "persona": "elder"},
    "何铁手": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "weapon": "whip", "body": 0.8, "gender": "female", "persona": "warrior_girl"},
    "何喜": {"hair": "hair_brown", "cloth": "cloth_green", "skin": 0, "body": 0.9, "gender": "male", "persona": "commoner"},
    "小裁缝": {"hair": "hair_black", "cloth": "cloth_purple", "skin": 0, "body": 0.75, "gender": "female", "persona": "girl"},
    "何裁缝": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0, "body": 0.9, "gender": "male", "persona": "commoner"},
    "捕快": {"hair": "hair_black", "cloth": "cloth_blue", "cloth2": "armor_iron", "skin": 0, "hat": "guard", "weapon": "blade", "body": 1.1, "gender": "male", "persona": "guard"},
    "巡捕": {"hair": "hair_black", "cloth": "cloth_blue", "cloth2": "armor_iron", "skin": 0, "hat": "guard", "weapon": "blade", "body": 1.15, "gender": "male", "persona": "guard"},
    "衙役": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "hat": "guard", "body": 1.05, "gender": "male", "persona": "guard"},
    "老夫子": {"hair": "hair_white", "cloth": "cloth_gray", "skin": 1, "hat": "master", "body": 0.85, "gender": "male", "beard": "long", "persona": "sage"},
    "村长": {"hair": "hair_white", "cloth": "cloth_brown", "skin": 1, "body": 0.9, "gender": "male", "beard": "short", "persona": "elder"},
    "老婆婆": {"hair": "hair_white", "cloth": "cloth_gray", "skin": 2, "body": 0.7, "gender": "female", "persona": "old_woman"},
    "妇人": {"hair": "hair_brown", "cloth": "cloth_red", "skin": 0, "body": 0.85, "gender": "female", "persona": "woman"},
    "公子哥": {"hair": "hair_black", "cloth": "cloth_gold", "cloth2": "cloth_white", "skin": 0, "weapon": "fan", "body": 1.0, "gender": "male", "persona": "noble"},
    "书童": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "body": 0.6, "gender": "male", "persona": "child"},
    "小童": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "body": 0.55, "gender": "male", "persona": "child"},
    "过路人": {"hair": "hair_brown", "cloth": "cloth_brown", "skin": 0, "body": 1.0, "gender": "male", "persona": "commoner"},
    "茅十七": {"hair": "hair_black", "cloth": "cloth_gray", "skin": 0, "weapon": "blade", "body": 1.0, "gender": "male", "persona": "wanderer"},
    "韦扬": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "cloth_blue", "skin": 0, "hat": "master", "weapon": "sword", "body": 1.1, "gender": "male", "persona": "master_warrior"},
    "简明": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "hat": "master", "weapon": "blade", "body": 1.1, "gender": "male", "persona": "master_warrior"},
    "简杰": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "weapon": "blade", "body": 1.0, "gender": "male", "persona": "warrior"},
    "简英": {"hair": "hair_black", "cloth": "cloth_blue", "skin": 0, "body": 0.8, "gender": "female", "persona": "warrior_girl"},
    "鲍振": {"hair": "hair_brown", "cloth": "cloth_blue", "skin": 0, "weapon": "blade", "body": 1.25, "gender": "male", "persona": "warrior"},
    "武师教头": {"hair": "hair_black", "cloth": "cloth_red", "cloth2": "armor_iron", "skin": 0, "hat": "warrior", "weapon": "blade", "body": 1.35, "gender": "male", "persona": "master_warrior"},
    "春花娘": {"hair": "hair_brown", "cloth": "cloth_red", "skin": 0, "body": 0.85, "gender": "female", "persona": "woman"},
    "护院武师": {"hair": "hair_black", "cloth": "cloth_blue", "cloth2": "armor_iron", "skin": 0, "weapon": "blade", "body": 1.2, "gender": "male", "persona": "warrior"},
    "清照": {"hair": "hair_black", "cloth": "cloth_purple", "cloth2": "cloth_white", "skin": 0, "hat": "master", "weapon": "sword", "body": 0.85, "gender": "female", "persona": "fairy"},
    "红拂女": {"hair": "hair_red", "cloth": "cloth_red", "skin": 0, "weapon": "whip", "body": 0.85, "gender": "female", "persona": "warrior_girl"},
    "公孙大娘": {"hair": "hair_black", "cloth": "cloth_purple", "skin": 0, "weapon": "sword", "body": 0.85, "gender": "female", "persona": "warrior_girl"},
    "青红": {"hair": "hair_black", "cloth": "cloth_purple", "skin": 0, "body": 0.75, "gender": "female", "persona": "girl"},
    "绿珠": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "body": 0.75, "gender": "female", "persona": "girl"},
    "雪涛": {"hair": "hair_white", "cloth": "cloth_white", "cloth2": "cloth_purple", "skin": 0, "body": 0.85, "gender": "female", "persona": "fairy"},
    "隐娘": {"hair": "hair_black", "cloth": "cloth_black", "skin": 0, "weapon": "blade", "body": 0.8, "gender": "female", "persona": "assassin_girl"},
    "王辞": {"hair": "hair_brown", "cloth": "cloth_purple", "skin": 0, "body": 1.0, "gender": "male", "persona": "commoner"},
    "于红儒": {"hair": "hair_black", "cloth": "cloth_red", "cloth2": "cloth_black", "skin": 0, "hat": "master", "weapon": "blade", "body": 1.15, "gender": "male", "persona": "dark_master"},
    "方长老": {"hair": "hair_white", "cloth": "cloth_red", "skin": 1, "weapon": "blade", "body": 1.0, "gender": "male", "beard": "short", "persona": "dark_warrior"},
    "韩长老": {"hair": "hair_white", "cloth": "cloth_red", "skin": 1, "body": 1.0, "gender": "male", "beard": "goatee", "persona": "dark_warrior"},
    "楚红灯": {"hair": "hair_black", "cloth": "cloth_red", "cloth2": "cloth_black", "skin": 0, "weapon": "blade", "body": 1.1, "gender": "male", "persona": "dark_warrior"},
    "崇儿": {"hair": "hair_black", "cloth": "cloth_red", "skin": 0, "body": 0.85, "gender": "male", "persona": "commoner"},
    "唐四儿": {"hair": "hair_brown", "cloth": "cloth_red", "skin": 0, "body": 0.9, "gender": "male", "persona": "commoner"},
    "白衣教众": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "cloth_red", "skin": 0, "weapon": "blade", "body": 1.0, "gender": "male", "persona": "dark_warrior"},
    "红衣教众": {"hair": "hair_black", "cloth": "cloth_red", "cloth2": "cloth_black", "skin": 0, "weapon": "blade", "body": 1.0, "gender": "male", "persona": "dark_warrior"},
    "钟央": {"hair": "hair_white", "cloth": "cloth_green", "cloth2": "cloth_gold", "skin": 1, "hat": "master", "weapon": "staff", "body": 0.95, "gender": "male", "beard": "long", "persona": "sage"},
    "十三卫": {"hair": "hair_black", "cloth": "cloth_green", "cloth2": "armor_iron", "skin": 0, "weapon": "blade", "body": 1.15, "gender": "male", "persona": "warrior"},
    "美奈子": {"hair": "hair_black", "cloth": "cloth_purple", "skin": 0, "body": 0.8, "gender": "female", "accessory": "veil", "persona": "fairy"},
    "藤王": {"hair": "hair_black", "cloth": "cloth_green", "cloth2": "armor_dark", "skin": 0, "weapon": "blade", "body": 1.25, "gender": "male", "persona": "dark_warrior"},
    "游敬": {"hair": "hair_brown", "cloth": "cloth_green", "skin": 0, "weapon": "staff", "body": 1.0, "gender": "male", "persona": "warrior"},
    "天井": {"hair": "hair_black", "cloth": "cloth_green", "skin": 0, "body": 1.15, "gender": "male", "persona": "warrior"},
    "孙三": {"hair": "hair_brown", "cloth": "cloth_green", "skin": 0, "body": 0.9, "gender": "male", "persona": "commoner"},
    "浪人甲": {"hair": "hair_black", "cloth": "cloth_black", "skin": 1, "weapon": "blade", "body": 1.1, "gender": "male", "persona": "bandit"},
    "清虚道人": {"hair": "hair_white", "cloth": "cloth_gray", "cloth2": "cloth_white", "skin": 1, "hat": "taoist", "weapon": "sword", "body": 1.0, "gender": "male", "beard": "long", "persona": "immortal"},
    "古松道人": {"hair": "hair_white", "cloth": "cloth_gray", "skin": 1, "hat": "taoist", "weapon": "staff", "body": 1.0, "gender": "male", "beard": "short", "persona": "immortal"},
    "仓月道人": {"hair": "hair_white", "cloth": "cloth_gray", "skin": 1, "hat": "taoist", "body": 0.95, "gender": "male", "beard": "goatee", "persona": "immortal"},
    "采药道人": {"hair": "hair_brown", "cloth": "cloth_gray", "cloth2": "cloth_green", "skin": 0, "hat": "taoist", "body": 0.9, "gender": "male", "persona": "immortal"},
    "知客道人": {"hair": "hair_black", "cloth": "cloth_gray", "skin": 0, "hat": "taoist", "body": 1.0, "gender": "male", "persona": "immortal"},
    "迎客道童": {"hair": "hair_black", "cloth": "cloth_gray", "skin": 0, "hat": "taoist", "body": 0.6, "gender": "male", "persona": "child"},
    "明月": {"hair": "hair_black", "cloth": "cloth_gray", "cloth2": "cloth_white", "skin": 0, "body": 0.8, "gender": "female", "persona": "fairy"},
    "清风": {"hair": "hair_black", "cloth": "cloth_gray", "cloth2": "cloth_white", "skin": 0, "body": 0.8, "gender": "female", "persona": "fairy"},
    "白瑞德": {"hair": "hair_white", "cloth": "cloth_white", "cloth2": "armor_steel", "skin": 1, "hat": "master", "weapon": "sword", "body": 1.15, "gender": "male", "beard": "short", "persona": "master_warrior"},
    "史婆婆": {"hair": "hair_white", "cloth": "cloth_white", "skin": 2, "body": 0.7, "gender": "female", "persona": "old_woman"},
    "万剑": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "armor_steel", "skin": 0, "weapon": "sword", "body": 1.15, "gender": "male", "persona": "warrior"},
    "万刃": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "armor_steel", "skin": 0, "weapon": "blade", "body": 1.1, "gender": "male", "persona": "warrior"},
    "万重": {"hair": "hair_brown", "cloth": "cloth_white", "cloth2": "armor_iron", "skin": 0, "weapon": "blade", "body": 1.3, "gender": "male", "persona": "warrior"},
    "万一": {"hair": "hair_black", "cloth": "cloth_white", "skin": 0, "body": 0.9, "gender": "male", "persona": "commoner"},
    "阿秀": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "cloth_blue", "skin": 0, "body": 0.75, "gender": "female", "persona": "girl"},
    "雪千柔": {"hair": "hair_white", "cloth": "cloth_white", "cloth2": "cloth_blue", "skin": 0, "weapon": "sword", "body": 0.8, "gender": "female", "persona": "fairy"},
    "流氓": {"hair": "hair_black", "cloth": "cloth_brown", "skin": 0, "weapon": "blade", "body": 1.05, "gender": "male", "persona": "bandit"},
    "流氓头": {"hair": "hair_black", "cloth": "cloth_black", "cloth2": "cloth_red", "skin": 0, "weapon": "blade", "body": 1.3, "gender": "male", "persona": "bandit_boss"},
    "独角大盗": {"hair": "hair_black", "cloth": "cloth_black", "cloth2": "armor_dark", "skin": 0, "hat": "bandit", "weapon": "blade", "body": 1.4, "gender": "male", "persona": "bandit_boss"},
    "采花大盗": {"hair": "hair_black", "cloth": "cloth_purple", "cloth2": "cloth_black", "skin": 0, "weapon": "fan", "body": 1.0, "gender": "male", "persona": "bandit"},
    "黑衣大盗": {"hair": "hair_black", "cloth": "cloth_black", "cloth2": "armor_dark", "skin": 0, "weapon": "blade", "body": 1.15, "gender": "male", "persona": "bandit"},
    "土匪甲": {"hair": "hair_brown", "cloth": "cloth_brown", "cloth2": "cloth_black", "skin": 0, "weapon": "blade", "body": 1.1, "gender": "male", "persona": "bandit"},
    "土匪头目": {"hair": "hair_black", "cloth": "cloth_black", "cloth2": "armor_iron", "skin": 0, "hat": "bandit", "weapon": "blade", "body": 1.35, "gender": "male", "persona": "bandit_boss"},
    "雪豹": {"hair": "hair_white", "cloth": "cloth_white", "cloth2": "armor_steel", "skin": 1, "weapon": "blade", "body": 1.2, "gender": "male", "persona": "bandit_boss"},
    "大侠": {"hair": "hair_black", "cloth": "cloth_white", "cloth2": "cloth_blue", "skin": 0, "hat": "master", "weapon": "sword", "body": 1.05, "gender": "male", "accessory": "cloak", "persona": "immortal"},
    "道德和尚": {"hair": "hair_white", "cloth": "cloth_gold", "cloth2": "cloth_red", "skin": 1, "body": 1.0, "gender": "male", "beard": "long", "persona": "monk"},
    "李白": {"hair": "hair_white", "cloth": "cloth_white", "cloth2": "cloth_blue", "skin": 1, "hat": "master", "weapon": "sword", "body": 1.0, "gender": "male", "beard": "long", "accessory": "cloak", "persona": "immortal"},
    "神秘人": {"hair": "hair_black", "cloth": "cloth_black", "cloth2": "armor_dark", "skin": 0, "weapon": "blade", "body": 1.1, "gender": "male", "accessory": "cloak", "persona": "dark_master"},
    "绣花女": {"hair": "hair_black", "cloth": "cloth_purple", "cloth2": "cloth_red", "skin": 0, "weapon": "whip", "body": 0.8, "gender": "female", "accessory": "veil", "persona": "assassin_girl"},
    "魔化和尚": {"hair": "hair_white", "cloth": "cloth_red", "cloth2": "cloth_black", "skin": 2, "weapon": "staff", "body": 1.35, "gender": "male", "persona": "demon"},
}

FACTION_CLOTH_MAP = {
    Faction.BAGUA: "cloth_blue", Faction.FLOWER: "cloth_purple",
    Faction.HONGLIAN: "cloth_red", Faction.NAJA: "cloth_green",
    Faction.TAIJI: "cloth_gray", Faction.XUESHAN: "cloth_white",
    Faction.XIAOYAO: "cloth_gold",
}

FACTION_WEAPON_MAP = {
    Faction.BAGUA: "blade", Faction.FLOWER: "sword",
    Faction.HONGLIAN: "blade", Faction.NAJA: "staff",
    Faction.TAIJI: "sword", Faction.XUESHAN: "sword",
    Faction.XIAOYAO: "staff",
}

NPC_TYPE_VISUAL = {
    "master": {"hat": "master"}, "trader": {"hat": "trader"},
    "quest_giver": {"hat": "warrior"}, "enemy": {"weapon": "blade"},
}


def get_appearance(name: str, npc_type: str = "normal", faction: Faction = Faction.NONE) -> Appearance:
    vis = CHAR_VISUAL.get(name)
    if vis:
        skin_idx = vis.get("skin", 0)
        skin_color = CHAR_PALETTE["skin"][min(skin_idx, len(CHAR_PALETTE["skin"]) - 1)]
        hair_color = CHAR_PALETTE.get(vis.get("hair", 'hair_black'), CHAR_PALETTE['hair_black'])
        cloth_color = CHAR_PALETTE.get(vis.get('cloth', 'cloth_blue'), CHAR_PALETTE['cloth_blue'])
        cloth_color2 = CHAR_PALETTE.get(vis.get('cloth2')) if vis.get('cloth2') else None
        return Appearance(
            skin_color=skin_color, hair_color=hair_color, cloth_color=cloth_color,
            cloth_color2=cloth_color2, weapon=vis.get("weapon"), hat=vis.get("hat"),
            body_scale=vis.get("body", 1.0), gender=vis.get("gender", "male"),
            beard=vis.get("beard"), accessory=vis.get("accessory"),
            persona=vis.get("persona", "commoner"),
        )
    name_hash = hash(name) if name else 0
    skin_idx = abs(name_hash) % len(CHAR_PALETTE["skin"])
    skin_color = CHAR_PALETTE["skin"][skin_idx]
    hair_keys = ["hair_black", "hair_brown", "hair_white", "hair_red"]
    hair_color = CHAR_PALETTE[hair_keys[abs(name_hash) % len(hair_keys)]]
    cloth_key = FACTION_CLOTH_MAP.get(faction, "cloth_blue")
    cloth_color = CHAR_PALETTE.get(cloth_key, CHAR_PALETTE["cloth_blue"])
    weapon = FACTION_WEAPON_MAP.get(faction)
    hat = None
    type_vis = NPC_TYPE_VISUAL.get(npc_type, {})
    if "hat" in type_vis:
        hat = type_vis["hat"]
    if "weapon" in type_vis and not weapon:
        weapon = type_vis["weapon"]
    if faction == Faction.NONE and npc_type == "normal":
        cloth_keys = ["cloth_brown", "cloth_gray", "cloth_blue", "cloth_green"]
        cloth_color = CHAR_PALETTE[cloth_keys[abs(name_hash) % len(cloth_keys)]]
    return Appearance(skin_color=skin_color, hair_color=hair_color, cloth_color=cloth_color,
                      weapon=weapon, hat=hat, persona="commoner")


class RenderLayer:
    def render(self, ctx: CharContext):
        raise NotImplementedError


class ShadowLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if not VISUAL_CONFIG["shadow_enabled"]:
            return
        sa = VISUAL_CONFIG["shadow_alpha"]
        sx, sy = ctx.sx, ctx.sy - 18 * ctx.sc
        sw = int(24 * ctx.sc)
        for i in range(3):
            t = i / 3
            r = int(sw * (1 + t * 0.4))
            h = int(7 * (1 + t * 0.3))
            a = int(sa * (1 - t * 0.6))
            arcade.draw_ellipse_filled(sx + 3, sy, r, h, (0, 0, 0, a))


class HurtFlashLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if ctx.hurt_flash > 0 and ctx.is_player:
            a = int(ctx.hurt_flash * 100)
            arcade.draw_circle_filled(ctx.sx, ctx.sy, 28, (255, 40, 40, a))
            arcade.draw_circle_filled(ctx.sx, ctx.sy, 20, (255, 80, 60, a // 2))


class PersonaRenderer:
    PERSONAS = {}

    @classmethod
    def register(cls, name):
        def decorator(fn):
            cls.PERSONAS[name] = fn
            return fn
        return decorator

    def render(self, ctx: CharContext):
        p = ctx.appearance.persona
        fn = self.PERSONAS.get(p, self.PERSONAS.get("commoner"))
        if fn:
            fn(ctx)


def _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, hr=None):
    if hr is None:
        hr = 10 * sc
    arcade.draw_circle_filled(sx, hy, hr, skin_sh)
    arcade.draw_circle_filled(sx + 0.5, hy + 0.5, hr - 0.5, skin)
    arcade.draw_circle_filled(sx + 1, hy + 1, hr * 0.7, skin_hi)


def _draw_face_features(sx, hy, sc, eye_type, facing, mouth_type=None):
    ex_off = -2 if facing == "left" else (2 if facing == "right" else 0)
    for side in [-1, 1]:
        ex = sx + side * 3.5 * sc + ex_off * 0.3
        ey = hy + 1 * sc
        if eye_type == "fierce":
            arcade.draw_circle_filled(ex, ey, 3 * sc, (255, 255, 255))
            arcade.draw_circle_filled(ex + 0.3, ey + 0.2, 2 * sc, (200, 30, 20))
            arcade.draw_circle_filled(ex + 0.5, ey + 0.4, 0.8 * sc, (255, 200, 150))
        elif eye_type == "angry":
            arcade.draw_circle_filled(ex, ey, 2.8 * sc, (255, 255, 255))
            arcade.draw_circle_filled(ex + 0.3, ey + 0.2, 1.8 * sc, (50, 15, 5))
            arcade.draw_circle_filled(ex + 0.5, ey + 0.4, 0.8 * sc, (200, 180, 150))
        elif eye_type == "kind":
            arcade.draw_circle_filled(ex, ey, 2.5 * sc, (255, 255, 255))
            arcade.draw_circle_filled(ex + 0.3, ey + 0.2, 1.6 * sc, (50, 40, 30))
            arcade.draw_circle_filled(ex + 0.5, ey + 0.4, 0.7 * sc, (255, 255, 255, 200))
        else:
            arcade.draw_circle_filled(ex, ey, 2.5 * sc, (255, 255, 255, 220))
            arcade.draw_circle_filled(ex + 0.3, ey + 0.2, 1.8 * sc, (40, 30, 20))
            arcade.draw_circle_filled(ex + 0.5, ey + 0.4, 0.8 * sc, (255, 255, 255, 180))
    if facing == "down":
        brow_y = hy + 4 * sc
        for side in [-1, 1]:
            bx1 = sx + side * 1
            bx2 = sx + side * 5 * sc
            if eye_type in ("angry", "fierce"):
                arcade.draw_line(bx2, brow_y + 2, bx1, brow_y - 1, (40, 20, 10), 2.5)
            elif eye_type == "kind":
                arcade.draw_line(bx1, brow_y + 0.5, bx2, brow_y - 0.5, (80, 60, 40), 1.5)
            else:
                arcade.draw_line(bx1, brow_y + 0.5, bx2, brow_y - 0.5, (60, 40, 30), 1.5)
    if mouth_type:
        my = hy - 3 * sc
        if mouth_type == "fierce":
            arcade.draw_line(sx - 4 * sc, my, sx + 4 * sc, my, (150, 30, 20), 2.5)
            for side in [-1, 1]:
                fx = sx + side * 3 * sc
                arcade.draw_polygon_filled([(fx - 1.5, my), (fx + 1.5, my), (fx, my - 4 * sc)], (255, 255, 255))
        elif mouth_type == "angry":
            arcade.draw_line(sx - 3 * sc, my + 1, sx, my - 1, (120, 40, 30), 2)
            arcade.draw_line(sx, my - 1, sx + 3 * sc, my + 1, (120, 40, 30), 2)
        elif mouth_type == "kind":
            arcade.draw_line(sx - 3 * sc, my - 0.5, sx, my + 1.5, (160, 80, 60), 1.5)
            arcade.draw_line(sx, my + 1.5, sx + 3 * sc, my - 0.5, (160, 80, 60), 1.5)
        elif mouth_type == "smile":
            arcade.draw_line(sx - 3 * sc, my, sx, my + 2, (160, 80, 60), 1.5)
            arcade.draw_line(sx, my + 2, sx + 3 * sc, my, (160, 80, 60), 1.5)


def _draw_beard_fn(sx, hy, sc, beard, hair_color):
    if not beard:
        return
    bc = darken(hair_color, 15)
    bh = lighten(hair_color, 10)
    if beard == "short":
        arcade.draw_rect_filled(arcade.LBWH(sx - 4 * sc, hy - 5 * sc, int(8 * sc), int(4 * sc)), bc)
        arcade.draw_rect_filled(arcade.LBWH(sx - 3 * sc, hy - 4 * sc, int(6 * sc), int(2 * sc)), bh)
    elif beard == "goatee":
        arcade.draw_rect_filled(arcade.LBWH(sx - 2 * sc, hy - 7 * sc, int(4 * sc), int(6 * sc)), bc)
        arcade.draw_rect_filled(arcade.LBWH(sx - 1 * sc, hy - 6 * sc, int(2 * sc), int(4 * sc)), bh)
    elif beard == "long":
        arcade.draw_rect_filled(arcade.LBWH(sx - 5 * sc, hy - 10 * sc, int(10 * sc), int(12 * sc)), bc)
        arcade.draw_rect_filled(arcade.LBWH(sx - 4 * sc, hy - 9 * sc, int(8 * sc), int(10 * sc)), bh)
        arcade.draw_rect_filled(arcade.LBWH(sx - 3 * sc, hy - 8 * sc, int(6 * sc), int(6 * sc)), lighten(bh, 10))


def _hair_short(sx, hy, sc, hc):
    hh = lighten(hc, 20)
    arcade.draw_ellipse_filled(sx + 1, hy + 7 * sc, int(19 * sc), int(10 * sc), hc)
    arcade.draw_ellipse_filled(sx + 1, hy + 3 * sc, int(19 * sc), int(5 * sc), hc)
    arcade.draw_ellipse_filled(sx + 3, hy + 7 * sc, int(12 * sc), int(6 * sc), hh)


def _hair_long(sx, hy, sc, hc):
    hh = lighten(hc, 20)
    arcade.draw_ellipse_filled(sx + 1, hy + 7 * sc, int(19 * sc), int(10 * sc), hc)
    arcade.draw_ellipse_filled(sx + 1, hy + 3 * sc, int(19 * sc), int(5 * sc), hc)
    arcade.draw_ellipse_filled(sx + 3, hy + 7 * sc, int(12 * sc), int(6 * sc), hh)
    for side in [-1, 1]:
        bx = sx + side * 9 * sc
        arcade.draw_rect_filled(arcade.LBWH(bx - 1, hy - 6 * sc, 3, int(14 * sc)), hc)
        arcade.draw_rect_filled(arcade.LBWH(bx, hy - 5 * sc, 1, int(12 * sc)), hh)


def _hair_wild(sx, hy, sc, hc):
    hh = lighten(hc, 15)
    arcade.draw_ellipse_filled(sx, hy + 9 * sc, int(22 * sc), int(12 * sc), hc)
    arcade.draw_ellipse_filled(sx, hy + 5 * sc, int(21 * sc), int(7 * sc), hc)
    arcade.draw_ellipse_filled(sx + 2, hy + 9 * sc, int(14 * sc), int(8 * sc), hh)
    for side in [-1, 1]:
        bx = sx + side * 10 * sc
        for i in range(4):
            spike_y = hy + (8 - i * 3) * sc
            arcade.draw_line(bx, spike_y, bx + side * 5 * sc, spike_y + 4 * sc, hh, 2)


def _hair_immortal(sx, hy, sc, hc):
    hh = lighten(hc, 25)
    arcade.draw_ellipse_filled(sx, hy + 8 * sc, int(20 * sc), int(11 * sc), hc)
    arcade.draw_ellipse_filled(sx, hy + 4 * sc, int(20 * sc), int(6 * sc), hc)
    arcade.draw_ellipse_filled(sx + 2, hy + 8 * sc, int(13 * sc), int(7 * sc), hh)
    for side in [-1, 1]:
        bx = sx + side * 10 * sc
        arcade.draw_rect_filled(arcade.LBWH(bx - 1, hy - 10 * sc, 3, int(22 * sc)), hc)
        arcade.draw_rect_filled(arcade.LBWH(bx, hy - 9 * sc, 1, int(20 * sc)), hh)
        for i in range(5):
            wave_x = bx + side * math.sin(i * 1.2 + get_anim_time() * 0.5) * 3
            wave_y = hy - 10 * sc + i * 4
            arcade.draw_circle_filled(wave_x, wave_y, 2, (*hh, 100))


def _draw_aura(sx, sy, sc, color, radius=18, pulse_speed=2.0, particles=5):
    glow = int(100 + 80 * math.sin(get_anim_time() * pulse_speed))
    arcade.draw_circle_outline(sx, sy, radius * sc, (*color[:3], glow), 2.5)
    arcade.draw_circle_outline(sx, sy, (radius + 3) * sc, (*color[:3], glow // 2), 1.5)
    for i in range(particles):
        angle = get_anim_time() * 0.8 + i * math.pi * 2 / particles
        px = sx + math.cos(angle) * (radius - 2) * sc
        py = sy + math.sin(angle) * (radius - 2) * sc
        arcade.draw_circle_filled(px, py, 3, (*color[:3], glow))
        arcade.draw_circle_filled(px, py, 1.5, (*lighten(color, 50), min(255, glow + 40)))


def _draw_horns(sx, hy, sc, color=(200, 50, 50)):
    for side in [-1, 1]:
        hx = sx + side * 8 * sc
        hb = hy + 12 * sc
        ht = hy + 22 * sc
        arcade.draw_polygon_filled([(hx - side * 3, hb), (hx + side * 5, ht), (hx + side * 1, hb)], color)
        arcade.draw_polygon_filled([(hx - side * 2, hb + 2), (hx + side * 4, ht - 2), (hx + side * 1, hb + 2)], lighten(color, 40))


def _draw_halo(sx, hy, sc, color=(255, 220, 80)):
    halo_y = hy + 15 * sc
    glow = int(140 + 80 * math.sin(get_anim_time() * 1.5))
    arcade.draw_ellipse_filled(sx, halo_y, int(16 * sc), int(5 * sc), (*color, glow))
    arcade.draw_ellipse_filled(sx, halo_y + 1, int(14 * sc), int(4 * sc), (*lighten(color, 30), min(255, glow + 40)))
    arcade.draw_ellipse_outline(sx, halo_y, int(16 * sc), int(5 * sc), (*lighten(color, 20), min(255, glow + 20)), 2)


def _draw_cloud_base(sx, by, sc, color=(200, 220, 255)):
    cw = int(22 * sc)
    ch = int(6 * sc)
    arcade.draw_ellipse_filled(sx, by - 22 * sc, cw, ch, (*color, 80))
    arcade.draw_ellipse_filled(sx, by - 21 * sc, cw - 4, ch - 2, (*lighten(color, 20), 50))


def _draw_veil(sx, hy, sc, color):
    vc = lighten(color, 30)
    vw = int(18 * sc)
    vh = int(9 * sc)
    arcade.draw_rect_filled(arcade.LBWH(sx - vw // 2, hy - 4 * sc, vw, vh), (*vc, 150))
    arcade.draw_rect_filled(arcade.LBWH(sx - vw // 2 + 1, hy - 3 * sc, vw - 2, vh - 2), (*lighten(vc, 15), 110))


def _draw_apron(sx, by, sc):
    aw = int(14 * sc)
    ah = int(14 * sc)
    draw_gradient_rect(sx - aw // 2, by - 2, aw, ah, (240, 235, 230), (200, 195, 190), 3)
    arcade.draw_rect_filled(arcade.LBWH(sx - aw // 2 + 1, by - 1, aw - 2, ah - 2), (230, 225, 220))


def _draw_flower_basket(sx, by, sc):
    bx = sx + 10 * sc
    bby = by - 4 * sc
    arcade.draw_rect_filled(arcade.LBWH(bx - 4, bby - 6, 8, 8), (130, 90, 50))
    arcade.draw_rect_filled(arcade.LBWH(bx - 3, bby - 5, 6, 6), (160, 120, 70))
    for fx, fy, fc in [(-2, -7, (255, 100, 100)), (1, -8, (255, 180, 200)), (3, -6, (255, 255, 100))]:
        arcade.draw_circle_filled(bx + fx, bby + fy, 2, fc)


def _draw_cloak(sx, by, sc, color):
    cc = darken(color, 20)
    cw = int(30 * sc)
    ch = int(32 * sc)
    draw_gradient_rect(sx - cw // 2, by - ch // 2, cw, ch, darken(cc, 10), darken(cc, 30), 4)
    arcade.draw_rect_filled(arcade.LBWH(sx - cw // 2 + 2, by - ch // 2 + 2, cw - 4, ch - 4), cc)


def _draw_face_mask(sx, hy, sc, color=(50, 40, 35)):
    mw = int(16 * sc)
    mh = int(6 * sc)
    my = hy - 2 * sc
    arcade.draw_rect_filled(arcade.LBWH(sx - mw // 2, my - mh // 2, mw, mh), color)
    arcade.draw_rect_filled(arcade.LBWH(sx - mw // 2 + 1, my - mh // 2 + 1, mw - 2, mh - 2), lighten(color, 15))
    for side in [-1, 1]:
        ex = sx + side * 3.5 * sc
        ey = hy + 1 * sc
        arcade.draw_circle_filled(ex, ey, 3 * sc, (255, 255, 255))
        arcade.draw_circle_filled(ex + 0.3, ey + 0.2, 2 * sc, (200, 30, 20))
        arcade.draw_circle_filled(ex + 0.5, ey + 0.4, 0.8 * sc, (255, 200, 150))


def _draw_prayer_beads(sx, hy, sc, color=(200, 170, 80)):
    bead_y = hy - 2 * sc
    for i in range(7):
        angle = math.pi * 0.3 + i * math.pi * 0.4 / 6
        bx = sx + math.cos(angle) * 8 * sc - 4 * sc
        by = bead_y - math.sin(angle) * 3 * sc
        arcade.draw_circle_filled(bx, by, 1.5 * sc, color)
        arcade.draw_circle_filled(bx + 0.3, by + 0.3, 1 * sc, lighten(color, 30))


def _draw_hat_wings(sx, hy, sc, color=(218, 165, 32)):
    for side in [-1, 1]:
        wx = sx + side * 12 * sc
        wy = hy + 10 * sc
        arcade.draw_polygon_filled([
            (sx + side * 5 * sc, wy + 2),
            (wx, wy - 2),
            (wx, wy + 2),
            (sx + side * 5 * sc, wy + 4),
        ], color)
        arcade.draw_polygon_filled([
            (sx + side * 5 * sc, wy + 3),
            (wx - side * 1, wy - 1),
            (wx - side * 1, wy + 1),
            (sx + side * 5 * sc, wy + 5),
        ], lighten(color, 25))


def _draw_gold_belt(sx, by, sc, color=(218, 165, 32)):
    tw = int(22 * sc)
    arcade.draw_line(sx - tw // 2, by + 2, sx + tw // 2, by + 2, color, 4)
    arcade.draw_line(sx - tw // 2, by + 3, sx + tw // 2, by + 3, lighten(color, 20), 2)
    arcade.draw_circle_filled(sx, by + 2, 3.5 * sc, color)
    arcade.draw_circle_filled(sx + 0.5, by + 2.5, 2.5 * sc, lighten(color, 30))
    arcade.draw_circle_filled(sx + 1, by + 3, 1.5 * sc, (255, 245, 180))


def _draw_official_badge(sx, by, sc, color=(218, 165, 32)):
    bx = sx + 10 * sc
    by2 = by - 4
    arcade.draw_circle_filled(bx, by2, 5 * sc, darken(color, 20))
    arcade.draw_circle_filled(bx, by2, 4 * sc, color)
    arcade.draw_circle_filled(bx + 0.5, by2 + 0.5, 3 * sc, lighten(color, 20))
    arcade.draw_circle_filled(bx + 1, by2 + 1, 1.5 * sc, (255, 245, 180))
    arcade.draw_circle_outline(bx, by2, 5 * sc, (255, 240, 120), 1.5)


def _draw_scar(sx, hy, sc, side=1, size=1.0):
    scar_x = sx + side * 5 * sc
    scar_y = hy - 1 * sc
    h = int(6 * size)
    arcade.draw_line(scar_x, scar_y - h, scar_x + int(2 * size), scar_y + h, (200, 60, 50), max(2, int(2.5 * size)))
    arcade.draw_line(scar_x - 1, scar_y - h + 1, scar_x + int(2 * size) - 1, scar_y + h - 1, (240, 100, 80), max(1, int(1.5 * size)))


def _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=22, rh=34, flare=1.3, collar=False, skin=None, skin_sh=None):
    rw_i = int(rw * sc)
    rh_i = int(rh * sc)
    rb = by - rh_i // 2 + 4
    flare_w = int(rw_i * flare)
    draw_gradient_rect(sx - flare_w // 2, rb, flare_w, int(8 * sc), mc, mc_sh, 3)
    draw_gradient_rect(sx - rw_i // 2, rb + int(6 * sc), rw_i, rh_i - int(6 * sc), mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw_i // 2 + 2, rb + int(6 * sc) + 2, rw_i - 4, rh_i - int(6 * sc) - 4), mc)
    if collar and skin and skin_sh:
        collar_w = int(8 * sc)
        draw_gradient_rect(sx - collar_w // 2, rb + rh_i - int(6 * sc), collar_w, int(6 * sc), skin_sh, skin, 3)
    for fold_y in [by - 2, by + 5, by + 12]:
        arcade.draw_line(sx - rw_i // 2 + 3, fold_y, sx + rw_i // 2 - 3, fold_y, alpha(mc_sh, 40), 1)


def _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=22, hand_r=3):
    rw_i = int(rw * sc)
    for side in [-1, 1]:
        sleeve_x = sx + side * (rw_i // 2 + 1)
        sleeve_y = by - 2 * sc
        draw_gradient_rect(sleeve_x - 5, sleeve_y - 6, 10, 14, mc_hi, mc_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(sleeve_x - 4, sleeve_y - 5, 8, 12), mc)
        arcade.draw_circle_filled(sleeve_x, sleeve_y - 7, hand_r * sc, skin)


def _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=5, leg_w=6, leg_h=14, foot_w=7):
    for side, offset in [(-1, walk), (1, -walk)]:
        lx = sx + side * spread * sc
        ly = by - 10 * sc
        draw_gradient_rect(lx - leg_w // 2, ly - leg_h + offset, leg_w, leg_h, mc_sh, mc_ds, 3)
        arcade.draw_rect_filled(arcade.LBWH(lx - leg_w // 2 + 1, ly - leg_h + 2 + offset, leg_w - 2, leg_h - 4), mc)
        arcade.draw_rect_filled(arcade.LBWH(lx - foot_w // 2, by - int(24 * sc) + offset, foot_w, int(4 * sc)), mc_ds)


def _draw_arms(sx, by, sc, arm_color, arm_color_sh, skin, skin_hi, spread=12, arm_w=4, arm_h=16, hand_r=3, swing=0):
    for side, swing_dir in [(-1, 1), (1, -1)]:
        ax = sx + side * spread * sc
        ay = by - 6 * sc + swing * swing_dir
        draw_gradient_rect(ax - arm_w // 2, ay - 6, arm_w, arm_h, arm_color if isinstance(arm_color, tuple) else arm_color, arm_color_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(ax - arm_w // 2 + 1, ay - 5, arm_w - 2, arm_h - 2), arm_color)
        hand_y = ay - 7
        arcade.draw_circle_filled(ax, hand_y, hand_r * sc, skin)
        arcade.draw_circle_filled(ax + 0.5, hand_y + 0.5, hand_r * sc * 0.7, skin_hi)


@PersonaRenderer.register("commoner")
def _p_commoner(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk)
    tw, th = int(18 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=12, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "normal", ctx.facing)
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)


@PersonaRenderer.register("hero")
def _p_hero(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 25), darken(mc, 20)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=22, rh=34)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=22)
    arcade.draw_line(sx - int(11 * sc), by + 2, sx + int(11 * sc), by + 2, ac, 3)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)
    _draw_aura(sx, by, sc, (255, 220, 120), radius=16, pulse_speed=2.0, particles=4)


@PersonaRenderer.register("guard")
def _p_guard(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 20)
    ac_hi = lighten(ac, 25)
    rw, rh = int(24 * sc), int(28 * sc)
    rb = by - rh // 2 + 2
    draw_gradient_rect(sx - rw // 2, rb, rw, rh, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 2, rb + 2, rw - 4, rh - 4), mc)
    collar_w = int(8 * sc)
    draw_gradient_rect(sx - collar_w // 2, rb + rh - int(6 * sc), collar_w, int(6 * sc), skin_sh, skin, 3)
    ah = int(16 * sc)
    draw_gradient_rect(sx - rw // 2, by - ah // 2, rw, ah, ac_hi, darken(ac, 15), 3)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 1, by - ah // 2 + 1, rw - 2, ah - 2), ac)
    arcade.draw_line(sx - rw // 2 + 2, by - ah // 2 + 2, sx + rw // 2 - 2, by - ah // 2 + 2, ac_hi, 1.5)
    for side in [-1, 1]:
        ax = sx + side * 14 * sc
        ay = by - 4 * sc
        draw_gradient_rect(ax - 3, ay - 8, 6, 16, mc, mc_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(ax - 2, ay - 7, 4, 14), mc)
        arcade.draw_circle_filled(ax, ay - 9, 3 * sc, skin)
    _draw_gold_belt(sx, by, sc, ac)
    _draw_official_badge(sx, by, sc, ac)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    jaw_w = int(14 * sc)
    jaw_h = int(5 * sc)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2, int(hy - 5 * sc), jaw_w, jaw_h), skin)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2 + 1, int(hy - 4 * sc), jaw_w - 2, jaw_h - 2), skin_hi)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "angry", ctx.facing)


@PersonaRenderer.register("bandit")
def _p_bandit(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 25), darken(mc, 20), darken(mc, 40)
    hunch = 4 * sc
    hx = sx + hunch * 0.7
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx + hunch * 0.3, by, sc, mc, mc_sh, mc_ds, walk, spread=5)
    tw, th = int(20 * sc), int(18 * sc)
    torso_x = sx + hunch * 0.5
    draw_gradient_rect(torso_x - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(torso_x - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    for i in range(3):
        tear_x = torso_x + (i - 1) * 5 * sc
        tear_y = by + th // 2 - 3
        arcade.draw_line(tear_x, tear_y, tear_x + 2, tear_y + 4, mc_ds, 2)
    for side in [-1, 1]:
        ax = torso_x + side * 13 * sc
        ay = by - 5 * sc
        draw_gradient_rect(ax - 3, ay - 8, 6, 16, skin_hi, skin_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(ax - 2, ay - 7, 4, 14), skin)
        arcade.draw_circle_filled(ax, ay - 9, 3 * sc, skin)
        arcade.draw_circle_filled(ax + 0.5, ay - 8.5, 2 * sc, skin_hi)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_wild(hx, hy, sc, app.hair_color)
    _draw_face_mask(hx, hy, sc, darken(mc, 10))
    _draw_scar(hx, hy, sc, side=1, size=1.5)


@PersonaRenderer.register("bandit_boss")
def _p_bandit_boss(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 20), darken(mc, 20), darken(mc, 40)
    hunch = 4 * sc
    hx = sx + hunch * 0.7
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx + hunch * 0.3, by, sc, mc, mc_sh, mc_ds, walk, spread=6, leg_w=8, foot_w=9)
    tw, th = int(24 * sc), int(20 * sc)
    torso_x = sx + hunch * 0.5
    draw_gradient_rect(torso_x - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(torso_x - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    for side in [-1, 1]:
        ax = torso_x + side * 14 * sc
        ay = by - 5 * sc
        draw_gradient_rect(ax - 4, ay - 8, 8, 18, skin_hi, skin_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(ax - 3, ay - 7, 6, 16), skin)
        arcade.draw_circle_filled(ax, ay - 9, 3.5 * sc, skin)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_wild(hx, hy, sc, app.hair_color)
    _draw_face_mask(hx, hy, sc, darken(mc, 10))
    _draw_scar(hx, hy, sc, side=1, size=1.8)
    _draw_scar(hx, hy, sc, side=-1, size=1.2)
    _draw_aura(sx, by, sc, (200, 30, 30), radius=22, pulse_speed=3.0, particles=4)


@PersonaRenderer.register("monk")
def _p_monk(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 25), darken(mc, 20)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=20, rh=34, flare=1.4, collar=True, skin=skin, skin_sh=skin_sh)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=20)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    for i in range(6):
        dot_x = sx + (i - 2.5) * 2.5 * sc
        dot_y = hy + 8 * sc
        arcade.draw_circle_filled(dot_x, dot_y, 1.2 * sc, darken(skin, 40))
    _draw_prayer_beads(sx, hy, sc, ac)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)
    _draw_halo(sx, hy, sc, (255, 220, 80))


@PersonaRenderer.register("immortal")
def _p_immortal(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    float_off = 8 * math.sin(ctx.t * 1.5)
    by_f = by + float_off
    hy_f = hy + float_off
    rw, rh = int(22 * sc), int(42 * sc)
    rb = by_f - rh // 2 + 6
    flare_w = int(rw * 1.6)
    draw_gradient_rect(sx - flare_w // 2, rb, flare_w, int(10 * sc), mc, mc_sh, 3)
    draw_gradient_rect(sx - rw // 2, rb + int(8 * sc), rw, rh - int(8 * sc), mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 2, rb + int(8 * sc) + 2, rw - 4, rh - int(8 * sc) - 4), mc)
    t = ctx.t
    for i in range(4):
        fy = rb + 12 * sc + i * 7 * sc
        wave = math.sin(t * 1.5 + i * 0.8) * 2
        arcade.draw_line(sx - rw // 2 + 3 + wave, fy, sx + rw // 2 - 3 + wave, fy, alpha(mc_sh, 50), 1.5)
    for side in [-1, 1]:
        sleeve_x = sx + side * (rw // 2 + 4)
        sleeve_y = by_f - 2 * sc
        sw, sh = int(12 * sc), int(16 * sc)
        draw_gradient_rect(sleeve_x - sw // 2, sleeve_y - sh // 2, sw, sh, mc_hi, mc_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(sleeve_x - sw // 2 + 1, sleeve_y - sh // 2 + 1, sw - 2, sh - 2), mc)
        wave_off = math.sin(t * 1.2 + side) * 3
        arcade.draw_line(sleeve_x + side * 3 + wave_off, sleeve_y - sh // 2, sleeve_x + side * 8 + wave_off, sleeve_y - sh // 2 - 6, mc_sh, 2)
        arcade.draw_circle_filled(sleeve_x, sleeve_y - sh // 2 - 1, 3 * sc, skin)
    _draw_head(sx, hy_f, sc, skin, skin_hi, skin_sh, 9 * sc)
    _hair_immortal(sx, hy_f, sc, app.hair_color)
    _draw_face_features(sx, hy_f, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(sx, hy_f, sc, app.beard, app.hair_color)
    if app.accessory == "cloak":
        _draw_cloak(sx, by_f, sc, mc)
    _draw_aura(sx, hy_f + 2 * sc, sc, ac, radius=18, pulse_speed=2.0, particles=6)
    _draw_cloud_base(sx, by_f, sc, lighten(ac, 30))


@PersonaRenderer.register("sage")
def _p_sage(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=22, rh=36)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=22)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_immortal(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)
    _draw_aura(sx, by, sc, (220, 200, 120), radius=22, pulse_speed=1.5, particles=6)


@PersonaRenderer.register("warrior")
def _p_warrior(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=6, leg_w=8, foot_w=9)
    tw, th = int(22 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    if app.cloth_color2:
        ah = int(14 * sc)
        draw_gradient_rect(sx - tw // 2, by - ah // 2, tw, ah, lighten(ac, 25), darken(ac, 15), 3)
        arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 1, by - ah // 2 + 1, tw - 2, ah - 2), ac)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=14, arm_w=6, arm_h=18, hand_r=3.5, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    jaw_w = int(14 * sc)
    jaw_h = int(5 * sc)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2, int(hy - 5 * sc), jaw_w, jaw_h), skin)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2 + 1, int(hy - 4 * sc), jaw_w - 2, jaw_h - 2), skin_hi)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "angry", ctx.facing, "angry")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)


@PersonaRenderer.register("master_warrior")
def _p_master_warrior(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 20)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=24, rh=36)
    if app.cloth_color2:
        ah = int(14 * sc)
        rw_i = int(24 * sc)
        draw_gradient_rect(sx - rw_i // 2, by - ah // 2, rw_i, ah, lighten(ac, 25), darken(ac, 15), 3)
        arcade.draw_rect_filled(arcade.LBWH(sx - rw_i // 2 + 1, by - ah // 2 + 1, rw_i - 2, ah - 2), ac)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=24, hand_r=3.5)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    jaw_w = int(14 * sc)
    jaw_h = int(5 * sc)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2, int(hy - 5 * sc), jaw_w, jaw_h), skin)
    arcade.draw_rect_filled(arcade.LBWH(sx - jaw_w // 2 + 1, int(hy - 4 * sc), jaw_w - 2, jaw_h - 2), skin_hi)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "fierce", ctx.facing, "fierce")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)
    _draw_aura(sx, by, sc, (255, 200, 80), radius=20, pulse_speed=1.5, particles=6)


@PersonaRenderer.register("merchant")
def _p_merchant(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk)
    tw, th = int(18 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)


@PersonaRenderer.register("rich_merchant")
def _p_rich_merchant(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=24, rh=34)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=24)
    _draw_gold_belt(sx, by, sc, ac)
    arcade.draw_circle_filled(sx, by - 1, 5 * sc, lighten(ac, 30))
    arcade.draw_circle_filled(sx + 0.5, by - 0.5, 3.5 * sc, (255, 240, 180))
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "smile")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)


@PersonaRenderer.register("servant")
def _p_servant(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk)
    tw, th = int(18 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, swing=ctx.walk_phase)
    if app.accessory == "apron":
        _draw_apron(sx, by, sc)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")


@PersonaRenderer.register("elder")
def _p_elder(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    hunch = 3 * sc
    hx = sx + hunch * 0.7
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=20, rh=34)
    arcade.draw_rect_filled(arcade.LBWH(int(sx - 6 * sc), int(by + 3 * sc), int(12 * sc), int(4 * sc)), darken(mc, 25))
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=20, hand_r=2.5)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_short(hx, hy, sc, app.hair_color)
    _draw_face_features(hx, hy, sc, "kind", ctx.facing, "kind")
    _draw_beard_fn(hx, hy, sc, app.beard, app.hair_color)


@PersonaRenderer.register("girl")
def _p_girl(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 1.5
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=3, leg_w=5, leg_h=10, foot_w=6)
    rw, rh = int(16 * sc), int(22 * sc)
    rb = by - rh // 2
    flare_w = int(rw * 1.4)
    draw_gradient_rect(sx - flare_w // 2, rb, flare_w, int(8 * sc), mc, mc_sh, 3)
    draw_gradient_rect(sx - rw // 2, rb + int(6 * sc), rw, rh - int(6 * sc), mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 2, rb + int(6 * sc) + 2, rw - 4, rh - int(6 * sc) - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=10, arm_w=3, arm_h=12, hand_r=2.5)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_long(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "smile")
    if app.accessory == "flower_basket":
        _draw_flower_basket(sx, by, sc)


@PersonaRenderer.register("warrior_girl")
def _p_warrior_girl(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=4)
    tw, th = int(16 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=11, arm_w=4, arm_h=14, hand_r=2.5, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh)
    _hair_long(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "angry", ctx.facing, "angry")


@PersonaRenderer.register("fairy")
def _p_fairy(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    float_off = 6 * math.sin(ctx.t * 1.8)
    by_f = by + float_off
    hy_f = hy + float_off
    rw, rh = int(20 * sc), int(38 * sc)
    rb = by_f - rh // 2 + 6
    flare_w = int(rw * 1.5)
    draw_gradient_rect(sx - flare_w // 2, rb, flare_w, int(10 * sc), mc, mc_sh, 3)
    draw_gradient_rect(sx - rw // 2, rb + int(8 * sc), rw, rh - int(8 * sc), mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 2, rb + int(8 * sc) + 2, rw - 4, rh - int(8 * sc) - 4), mc)
    t = ctx.t
    for i in range(3):
        fy = rb + 10 * sc + i * 7 * sc
        wave = math.sin(t * 1.5 + i * 0.8) * 2
        arcade.draw_line(sx - rw // 2 + 3 + wave, fy, sx + rw // 2 - 3 + wave, fy, alpha(mc_sh, 50), 1.5)
    for side in [-1, 1]:
        sleeve_x = sx + side * (rw // 2 + 3)
        sleeve_y = by_f - 2 * sc
        sw, sh = int(10 * sc), int(14 * sc)
        draw_gradient_rect(sleeve_x - sw // 2, sleeve_y - sh // 2, sw, sh, mc_hi, mc_sh, 3)
        arcade.draw_rect_filled(arcade.LBWH(sleeve_x - sw // 2 + 1, sleeve_y - sh // 2 + 1, sw - 2, sh - 2), mc)
        arcade.draw_circle_filled(sleeve_x, sleeve_y - sh // 2 - 1, 3 * sc, skin)
    _draw_head(sx, hy_f, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_immortal(sx, hy_f, sc, app.hair_color)
    _draw_face_features(sx, hy_f, sc, "kind", ctx.facing, "kind")
    if app.accessory == "veil":
        _draw_veil(sx, hy_f, sc, mc)
    _draw_aura(sx, hy_f + 2 * sc, sc, (255, 180, 255), radius=15, pulse_speed=2.0, particles=5)
    _draw_cloud_base(sx, by_f, sc, lighten(ac, 30))


@PersonaRenderer.register("assassin_girl")
def _p_assassin_girl(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 20), darken(mc, 15), darken(mc, 35)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=3, leg_w=5, foot_w=6)
    tw, th = int(14 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=10, arm_w=3, arm_h=14, hand_r=2.5, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 9 * sc)
    _hair_long(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "fierce", ctx.facing)
    if app.accessory == "veil":
        _draw_veil(sx, hy, sc, mc)


@PersonaRenderer.register("woman")
def _p_woman(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 1.5
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=4, leg_w=5, leg_h=10)
    rw, rh = int(16 * sc), int(22 * sc)
    rb = by - rh // 2
    flare_w = int(rw * 1.3)
    draw_gradient_rect(sx - flare_w // 2, rb, flare_w, int(6 * sc), mc, mc_sh, 3)
    draw_gradient_rect(sx - rw // 2, rb + int(5 * sc), rw, rh - int(5 * sc), mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - rw // 2 + 2, rb + int(5 * sc) + 2, rw - 4, rh - int(5 * sc) - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=10, arm_w=3, arm_h=12, hand_r=2.5)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_long(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "kind")


@PersonaRenderer.register("old_woman")
def _p_old_woman(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    hunch = 3 * sc
    hx = sx + hunch * 0.7
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=18, rh=30)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=18, hand_r=2.5)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_short(hx, hy, sc, app.hair_color)
    _draw_face_features(hx, hy, sc, "kind", ctx.facing, "kind")


@PersonaRenderer.register("child")
def _p_child(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.5
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=3, leg_w=4, leg_h=8, foot_w=5)
    tw, th = int(12 * sc), int(14 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=8, arm_w=3, arm_h=10, hand_r=2)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 12 * sc)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "smile")


@PersonaRenderer.register("noble")
def _p_noble(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 20), darken(mc, 15)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=22, rh=34)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=22)
    _draw_gold_belt(sx, by, sc, ac)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 11 * sc)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "kind", ctx.facing, "smile")


@PersonaRenderer.register("wanderer")
def _p_wanderer(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 30), darken(mc, 25), darken(mc, 45)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk)
    tw, th = int(18 * sc), int(22 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "angry", ctx.facing, "angry")


@PersonaRenderer.register("brute")
def _p_brute(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 25), darken(mc, 20), darken(mc, 40)
    hunch = 3 * sc
    hx = sx + hunch * 0.7
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx + hunch * 0.3, by, sc, mc, mc_sh, mc_ds, walk, spread=6, leg_w=8, foot_w=9)
    tw, th = int(24 * sc), int(20 * sc)
    torso_x = sx + hunch * 0.5
    draw_gradient_rect(torso_x - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(torso_x - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    _draw_arms(torso_x, by, sc, skin, skin_sh, skin, skin_hi, spread=14, arm_w=8, arm_h=18, hand_r=3.5, swing=ctx.walk_phase)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    jaw_w = int(14 * sc)
    jaw_h = int(5 * sc)
    arcade.draw_rect_filled(arcade.LBWH(hx - jaw_w // 2, int(hy - 5 * sc), jaw_w, jaw_h), skin)
    _hair_short(hx, hy, sc, app.hair_color)
    _draw_face_features(hx, hy, sc, "fierce", ctx.facing, "fierce")
    _draw_scar(hx, hy, sc, side=-1, size=1.6)


@PersonaRenderer.register("dark_warrior")
def _p_dark_warrior(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 20), darken(mc, 20), darken(mc, 40)
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx, by, sc, mc, mc_sh, mc_ds, walk, spread=6, leg_w=8, foot_w=9)
    tw, th = int(22 * sc), int(20 * sc)
    draw_gradient_rect(sx - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    if app.cloth_color2:
        ah = int(14 * sc)
        draw_gradient_rect(sx - tw // 2, by - ah // 2, tw, ah, lighten(ac, 15), darken(ac, 10), 3)
        arcade.draw_rect_filled(arcade.LBWH(sx - tw // 2 + 1, by - ah // 2 + 1, tw - 2, ah - 2), ac)
    _draw_arms(sx, by, sc, mc, mc_sh, skin, skin_hi, spread=14, arm_w=6, arm_h=18, hand_r=3.5, swing=ctx.walk_phase)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_short(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "fierce", ctx.facing, "fierce")
    _draw_beard_fn(sx, hy, sc, app.beard, app.hair_color)
    _draw_aura(sx, by, sc, (180, 20, 20), radius=20, pulse_speed=2.5, particles=4)


@PersonaRenderer.register("dark_master")
def _p_dark_master(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh = lighten(mc, 15), darken(mc, 15)
    _draw_robe_body(sx, by, sc, mc, mc_hi, mc_sh, rw=24, rh=36)
    if app.cloth_color2:
        ah = int(14 * sc)
        rw_i = int(24 * sc)
        draw_gradient_rect(sx - rw_i // 2, by - ah // 2, rw_i, ah, lighten(ac, 15), darken(ac, 10), 3)
        arcade.draw_rect_filled(arcade.LBWH(sx - rw_i // 2 + 1, by - ah // 2 + 1, rw_i - 2, ah - 2), ac)
    _draw_robe_sleeves(sx, by, sc, mc, mc_hi, mc_sh, skin, rw=24, hand_r=3.5)
    _draw_head(sx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_wild(sx, hy, sc, app.hair_color)
    _draw_face_features(sx, hy, sc, "fierce", ctx.facing, "fierce")
    if app.accessory == "cloak":
        _draw_cloak(sx, by, sc, mc)
    _draw_aura(sx, by, sc, (200, 0, 0), radius=22, pulse_speed=2.0, particles=5)


@PersonaRenderer.register("demon")
def _p_demon(ctx):
    sx, by, hy = ctx.sx, ctx.body_y, ctx.head_y
    app, sc = ctx.appearance, ctx.sc
    mc, ac = app.main_color, app.accent_color
    skin, skin_hi, skin_sh = app.skin_color, app.skin_hi, app.skin_sh
    mc_hi, mc_sh, mc_ds = lighten(mc, 15), darken(mc, 15), darken(mc, 35)
    hunch = 3 * sc
    hx = sx + hunch * 0.7
    walk = ctx.walk_phase * 2.0
    _draw_legs(sx + hunch * 0.3, by, sc, mc, mc_sh, mc_ds, walk, spread=6, leg_w=8, foot_w=9)
    tw, th = int(24 * sc), int(20 * sc)
    torso_x = sx + hunch * 0.5
    draw_gradient_rect(torso_x - tw // 2, by - th // 2, tw, th, mc_hi, mc_sh, 5)
    arcade.draw_rect_filled(arcade.LBWH(torso_x - tw // 2 + 2, by - th // 2 + 2, tw - 4, th - 4), mc)
    ah = int(14 * sc)
    draw_gradient_rect(torso_x - tw // 2, by - ah // 2, tw, ah, lighten(ac, 10), darken(ac, 10), 3)
    arcade.draw_rect_filled(arcade.LBWH(torso_x - tw // 2 + 1, by - ah // 2 + 1, tw - 2, ah - 2), ac)
    _draw_arms(torso_x, by, sc, skin, skin_sh, skin, skin_hi, spread=14, arm_w=8, arm_h=18, hand_r=3.5, swing=ctx.walk_phase)
    _draw_head(hx, hy, sc, skin, skin_hi, skin_sh, 10 * sc)
    _hair_wild(hx, hy, sc, app.hair_color)
    _draw_face_features(hx, hy, sc, "fierce", ctx.facing, "fierce")
    _draw_horns(hx, hy, sc, (180, 50, 120))
    _draw_aura(sx, by, sc, (180, 30, 80), radius=24, pulse_speed=3.0, particles=6)


class WeaponLayer(RenderLayer):
    WEAPONS = {}

    @classmethod
    def register(cls, name):
        def decorator(fn):
            cls.WEAPONS[name] = fn
            return fn
        return decorator

    def render(self, ctx: CharContext):
        w = ctx.appearance.weapon
        if w and w in self.WEAPONS:
            self.WEAPONS[w](ctx)


def _metal_blade(x1, y1, x2, y2, width=2):
    arcade.draw_line(x1, y1, x2, y2, (160, 165, 175), width + 1)
    arcade.draw_line(x1 + 0.5, y1, x2 + 0.5, y2, (200, 205, 215), width)
    arcade.draw_line(x1 + 1, y1, x2 + 1, y2, (230, 235, 245), max(1, width - 1))


@WeaponLayer.register("sword")
def _sword(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 4
    _metal_blade(wx, wy, wx + 2, wy - 22, 2)
    arcade.draw_line(wx - 3, wy + 1, wx + 5, wy + 1, (180, 160, 80), 2)
    arcade.draw_rect_filled(arcade.LBWH(wx - 1, wy + 1, 3, 5), (100, 70, 35))
    arcade.draw_circle_filled(wx + 1, wy + 6, 1.5, (80, 60, 30))


@WeaponLayer.register("blade")
def _blade(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 2
    _metal_blade(wx, wy, wx + 3, wy - 20, 3)
    arcade.draw_line(wx - 4, wy + 1, wx + 6, wy + 1, (180, 160, 80), 2)
    arcade.draw_rect_filled(arcade.LBWH(wx - 2, wy + 1, 5, 4), (100, 70, 35))
    arcade.draw_circle_filled(wx, wy + 5, 2, (80, 60, 30))


@WeaponLayer.register("staff")
def _staff(ctx):
    wx, wy = ctx.sx + 12 * ctx.sc, ctx.body_y + 10
    arcade.draw_line(wx, wy, wx, wy - 30, (100, 70, 35), 3)
    arcade.draw_line(wx + 0.5, wy, wx + 0.5, wy - 30, (130, 95, 55), 2)
    arcade.draw_circle_filled(wx, wy - 30, 4, (200, 170, 80))
    arcade.draw_circle_filled(wx, wy - 30, 3, (230, 200, 120))
    glow = int(abs(math.sin(ctx.t * 2)) * 30)
    arcade.draw_circle_filled(wx, wy - 30, 6, (255, 220, 120, 15 + glow))


@WeaponLayer.register("whip")
def _whip(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 2
    arcade.draw_line(wx - 1, wy + 4, wx - 1, wy, (100, 70, 35), 3)
    pts = [(wx, wy), (wx + 5, wy - 7), (wx + 3, wy - 14), (wx + 7, wy - 18)]
    for i in range(len(pts) - 1):
        w = 2 - i * 0.3
        arcade.draw_line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], (90, 60, 30), max(1, int(w)))
    arcade.draw_circle_filled(wx + 7, wy - 18, 1.5, (70, 45, 25))


@WeaponLayer.register("hammer")
def _hammer(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 2
    arcade.draw_line(wx, wy + 6, wx, wy - 16, (100, 70, 35), 3)
    draw_gradient_rect(wx - 6, wy - 22, 12, 8, (150, 150, 165), (110, 110, 125), 3)
    arcade.draw_rect_filled(arcade.LBWH(wx - 5, wy - 21, 10, 6), (140, 140, 155))


@WeaponLayer.register("cleaver")
def _cleaver(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 2
    draw_gradient_rect(wx - 1, wy - 18, 8, 18, (170, 175, 185), (130, 135, 145), 3)
    arcade.draw_rect_filled(arcade.LBWH(wx, wy - 17, 6, 16), (160, 165, 175))
    arcade.draw_rect_filled(arcade.LBWH(wx - 2, wy, 4, 6), (100, 70, 35))


@WeaponLayer.register("fan")
def _fan(ctx):
    wx, wy = ctx.sx + 13 * ctx.sc, ctx.body_y - 6
    cc = ctx.appearance.cloth_color
    for angle_off in [-30, -15, 0, 15, 30]:
        rad = math.radians(angle_off - 90)
        ex = wx + math.cos(rad) * 12
        ey = wy + math.sin(rad) * 12
        arcade.draw_line(wx, wy, ex, ey, lighten(cc, 20), 1)
    arcade.draw_circle_filled(wx, wy, 3, darken(cc, 10))
    arcade.draw_circle_filled(wx + 0.5, wy + 0.5, 2, cc)
    arcade.draw_arc_outline(wx, wy - 6, 24, 24, lighten(cc, 30), 210, 330, 1)


class HatLayer(RenderLayer):
    HATS = {}

    @classmethod
    def register(cls, name):
        def decorator(fn):
            cls.HATS[name] = fn
            return fn
        return decorator

    def render(self, ctx: CharContext):
        h = ctx.appearance.hat
        if h and h in self.HATS:
            self.HATS[h](ctx)


@HatLayer.register("master")
def _hat_master(ctx):
    cc = ctx.appearance.accent_color
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 8 * sc, hy + 9 * sc, 16 * sc, 6 * sc, lighten(cc, 15), darken(cc, 10), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 7 * sc, hy + 10 * sc, 14 * sc, 4 * sc), cc)
    draw_gradient_rect(ctx.sx - 10 * sc, hy + 14 * sc, 20 * sc, 3 * sc, lighten(cc, 25), cc, 2)
    arcade.draw_circle_filled(ctx.sx, hy + 15 * sc, 2.5 * sc, (255, 240, 140))
    arcade.draw_circle_filled(ctx.sx + 0.3, hy + 15 * sc + 0.3, 1.5 * sc, (255, 255, 200))


@HatLayer.register("trader")
def _hat_trader(ctx):
    cc = ctx.appearance.main_color
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 9 * sc, hy + 8 * sc, 18 * sc, 7 * sc, lighten(cc, 10), darken(cc, 15), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 8 * sc, hy + 9 * sc, 16 * sc, 5 * sc), cc)
    draw_gradient_rect(ctx.sx - 10 * sc, hy + 14 * sc, 20 * sc, 3 * sc, darken(cc, 5), darken(cc, 20), 2)


@HatLayer.register("guard")
def _hat_guard(ctx):
    hy, sc = ctx.head_y, ctx.sc
    ac = ctx.appearance.accent_color
    draw_gradient_rect(ctx.sx - 9 * sc, hy + 8 * sc, 18 * sc, 8 * sc, (155, 155, 170), (110, 110, 125), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 8 * sc, hy + 9 * sc, 16 * sc, 6 * sc), (135, 135, 150))
    draw_gradient_rect(ctx.sx - 10 * sc, hy + 15 * sc, 20 * sc, 3 * sc, (165, 165, 180), (130, 130, 145), 2)
    arcade.draw_circle_filled(ctx.sx, hy + 11 * sc, 3.5 * sc, ac)
    arcade.draw_circle_filled(ctx.sx + 0.3, hy + 11 * sc + 0.3, 2.5 * sc, lighten(ac, 30))
    arcade.draw_circle_filled(ctx.sx + 0.5, hy + 11 * sc + 0.5, 1.5 * sc, (255, 250, 200))
    _draw_hat_wings(ctx.sx, hy, sc, ac)


@HatLayer.register("taoist")
def _hat_taoist(ctx):
    cc = ctx.appearance.main_color
    hy, sc = ctx.head_y, ctx.sc
    arcade.draw_circle_filled(ctx.sx, hy + 12 * sc, 9 * sc, darken(cc, 10))
    arcade.draw_circle_filled(ctx.sx, hy + 12 * sc, 8 * sc, cc)
    arcade.draw_circle_filled(ctx.sx + 1, hy + 13 * sc, 5 * sc, lighten(cc, 15))
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 1, hy + 10 * sc, 2, 11 * sc), (200, 170, 80))
    arcade.draw_circle_filled(ctx.sx, hy + 20 * sc, 2.5 * sc, (200, 170, 80))
    arcade.draw_circle_filled(ctx.sx + 0.3, hy + 20 * sc + 0.3, 1.5 * sc, (240, 220, 140))


@HatLayer.register("warrior")
def _hat_warrior(ctx):
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 9 * sc, hy + 8 * sc, 18 * sc, 7 * sc, (160, 160, 175), (120, 120, 135), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 8 * sc, hy + 9 * sc, 16 * sc, 5 * sc), (145, 145, 160))
    draw_gradient_rect(ctx.sx - 10 * sc, hy + 14 * sc, 20 * sc, 3 * sc, (175, 175, 190), (140, 140, 155), 2)
    for side in [-1, 1]:
        draw_gradient_rect(ctx.sx + side * 7 * sc - 2, hy + 6 * sc, 4, 5 * sc, (160, 160, 175), (120, 120, 135), 2)


@HatLayer.register("waiter")
def _hat_waiter(ctx):
    cc = ctx.appearance.main_color
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 8 * sc, hy + 8 * sc, 16 * sc, 6 * sc, lighten(cc, 10), darken(cc, 10), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 7 * sc, hy + 9 * sc, 14 * sc, 4 * sc), cc)
    arcade.draw_line(ctx.sx - 7 * sc, hy + 11 * sc, ctx.sx + 7 * sc, hy + 11 * sc, darken(cc, 20), 1)


@HatLayer.register("blacksmith")
def _hat_blacksmith(ctx):
    cc = ctx.appearance.main_color
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 8 * sc, hy + 8 * sc, 16 * sc, 5 * sc, lighten(cc, 5), darken(cc, 15), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 7 * sc, hy + 9 * sc, 14 * sc, 3 * sc), cc)
    draw_gradient_rect(ctx.sx - 9 * sc, hy + 12 * sc, 18 * sc, 3 * sc, darken(cc, 10), darken(cc, 25), 2)


@HatLayer.register("bandit")
def _hat_bandit(ctx):
    cc = ctx.appearance.main_color
    hy, sc = ctx.head_y, ctx.sc
    draw_gradient_rect(ctx.sx - 10 * sc, hy + 6 * sc, 20 * sc, 4 * sc, darken(cc, 15), darken(cc, 30), 3)
    arcade.draw_rect_filled(arcade.LBWH(ctx.sx - 9 * sc, hy + 7 * sc, 18 * sc, 2 * sc), darken(cc, 10))
    for side in [-1, 1]:
        draw_gradient_rect(ctx.sx + side * 8 * sc - 2, hy + 4 * sc, 4, 6 * sc, darken(cc, 15), darken(cc, 25), 2)


class FactionBadgeLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if ctx.faction == Faction.NONE:
            return
        fc = FACTION_COLORS.get(ctx.faction, (200, 200, 200))
        bx, by = ctx.sx + 11 * ctx.sc, ctx.body_y + 8
        arcade.draw_circle_filled(bx, by, 5, darken(fc, 30))
        arcade.draw_circle_filled(bx, by, 4, darken(fc, 15))
        arcade.draw_circle_filled(bx + 0.5, by + 0.5, 3, fc)
        arcade.draw_circle_filled(bx + 1, by + 1, 1.5, lighten(fc, 30))
        arcade.draw_circle_outline(bx, by, 5, (255, 255, 255, 150), 1)


class HpBarLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if ctx.hp_ratio >= 1.0:
            return
        bw, bh = 32, 5
        bx = ctx.sx - bw / 2
        by = ctx.sy + 30 * ctx.sc + ctx.breathe
        arcade.draw_rect_filled(arcade.LBWH(bx - 1, by - 1, bw + 2, bh + 2), (0, 0, 0, 140))
        arcade.draw_rect_filled(arcade.LBWH(bx, by, bw, bh), (30, 10, 10))
        fw = max(1, int(bw * ctx.hp_ratio))
        hc = (60, 200, 60) if ctx.hp_ratio > 0.5 else ((220, 180, 30) if ctx.hp_ratio > 0.25 else (220, 40, 40))
        draw_gradient_rect(bx, by, fw, bh, lighten(hc, 25), darken(hc, 10), 3)
        arcade.draw_rect_outline(arcade.LBWH(bx, by, bw, bh), (0, 0, 0, 100), 1)


class QuestIndicatorLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if not ctx.has_quest or not VISUAL_CONFIG["quest_indicator"]:
            return
        qy = ctx.sy + 36 * ctx.sc + 3 * math.sin(ctx.t * 3) + ctx.breathe
        arcade.draw_circle_filled(ctx.sx, qy + 2, 7, (255, 220, 50, 30))
        arcade.draw_circle_filled(ctx.sx, qy + 2, 5, (255, 220, 50, 50))
        arcade.draw_text("!", ctx.sx, qy, (255, 240, 80), 14, font_name=FONT_LATIN,
                         anchor_x="center", anchor_y="center")


class PlayerAuraLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if not ctx.is_player:
            return
        ga = int(30 + 18 * math.sin(ctx.t * 3))
        arcade.draw_circle_outline(ctx.sx, ctx.sy + ctx.breathe, 26, (255, 210, 120, ga), 2)
        arcade.draw_circle_outline(ctx.sx, ctx.sy + ctx.breathe, 28, (255, 200, 100, ga // 3), 1)
        for i in range(4):
            angle = ctx.t * 1.2 + i * math.pi / 2
            px = ctx.sx + math.cos(angle) * 24
            py = ctx.sy + ctx.breathe + math.sin(angle) * 24
            arcade.draw_circle_filled(px, py, 2, (255, 210, 120, ga))


class EnemyIndicatorLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if ctx.npc_type != "enemy":
            return
        pulse = int(120 + 60 * math.sin(ctx.t * 4))
        arcade.draw_circle_outline(ctx.sx, ctx.sy, 24, (pulse, 25, 25, 60), 1.5)
        arcade.draw_circle_outline(ctx.sx, ctx.sy, 26, (pulse, 25, 25, 25), 1)


class MasterAuraLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if not ctx.is_master or ctx.has_quest:
            return
        glow = int(20 + 18 * math.sin(ctx.t * 2))
        arcade.draw_circle_outline(ctx.sx, ctx.sy, 26, (210, 190, 110, glow), 1.5)
        arcade.draw_circle_outline(ctx.sx, ctx.sy, 28, (210, 190, 110, glow // 3), 1)
        for i in range(5):
            angle = ctx.t * 0.8 + i * math.pi * 2 / 5
            px = ctx.sx + math.cos(angle) * 24
            py = ctx.sy + math.sin(angle) * 24
            arcade.draw_circle_filled(px, py, 1.5, (210, 190, 110, glow))


class NameLabelLayer(RenderLayer):
    def render(self, ctx: CharContext):
        pass


class RimLightLayer(RenderLayer):
    def render(self, ctx: CharContext):
        if not VISUAL_CONFIG.get("glow_enabled", True):
            return
        t = get_anim_time()
        glow = int(15 + 8 * math.sin(t * 1.5 + hash(ctx.name) % 100 * 0.01))
        color = (255, 240, 200, glow)
        arcade.draw_circle_outline(ctx.sx, ctx.sy - 5 * ctx.sc, 22 * ctx.sc, color, 2)


_LAYERS = [
    HurtFlashLayer(),
    ShadowLayer(),
    PersonaRenderer(),
    WeaponLayer(),
    HatLayer(),
    FactionBadgeLayer(),
    HpBarLayer(),
    PlayerAuraLayer(),
    EnemyIndicatorLayer(),
    MasterAuraLayer(),
    QuestIndicatorLayer(),
    RimLightLayer(),
    NameLabelLayer(),
]


def draw_character(sx, sy, name="player", facing="down", is_player=False,
                   npc_type="normal", faction=Faction.NONE, hp_ratio=1.0,
                   has_quest=False, is_master=False, hurt_flash=0.0):
    ctx = CharContext(
        sx=sx, sy=sy, name=name, facing=facing, is_player=is_player,
        npc_type=npc_type, faction=faction, hp_ratio=hp_ratio,
        has_quest=has_quest, is_master=is_master, hurt_flash=hurt_flash,
        appearance=get_appearance(name, npc_type, faction),
    )
    for layer in _LAYERS:
        layer.render(ctx)
    _draw_ink_outline(ctx)


def _draw_ink_outline(ctx: CharContext):
    sc = ctx.sc
    ink_color = (45, 40, 35, 50)
    cx, cy = ctx.sx, ctx.sy
    body_top = cy + 2 * sc + ctx.breathe
    head_y = cy + 22 * sc + ctx.breathe
    hr = 10 * sc
    arcade.draw_circle_outline(cx, head_y, hr + 1, ink_color, 1.5)
    body_w = 10 * sc
    body_h = 16 * sc
    by_top = body_top - 2 * sc
    by_bot = body_top + body_h
    arcade.draw_lrbt_rectangle_outline(
        cx - body_w // 2 - 1, cx + body_w // 2 + 1,
        by_top, by_bot,
        ink_color, 1.5
    )
