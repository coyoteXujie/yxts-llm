# -*- coding: utf-8 -*-
"""
shared_types.py - 全局共享类型定义 (SOURCE OF TRUTH)

本文件统一所有重复的枚举和基础数据类，其他模块应从此处导入。
"""

from enum import Enum, auto
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any, Tuple


# ============================================================================
# 势力/门派枚举 (from entities.py)
# ============================================================================

class Faction(Enum):
    NONE = 0
    BAGUA = 1
    FLOWER = 2
    HONGLIAN = 3
    NAJA = 4
    TAIJI = 5
    XUESHAN = 6
    XIAOYAO = 7


# ============================================================================
# NPC类型枚举 (from entities.py)
# ============================================================================

class NpcType(Enum):
    NORMAL = "normal"
    MASTER = "master"
    TRADER = "trader"
    QUEST_GIVER = "quest_giver"
    ENEMY = "enemy"


# ============================================================================
# 技能类型枚举 (from entities.py) -- 用于基础战斗技能分类
# ============================================================================

class SkillType(Enum):
    ATTACK = 0
    SWORD = 1
    BLADE = 2
    FORCE = 3
    DODGE = 4
    PARRY = 5
    STAFF = 6
    WAND = 7
    WHIP = 8
    LITERACY = 9
    LOOKS = 10


# ============================================================================
# 武学修炼类型枚举 (from cultivation_system.py, 原名为 SkillType, 重命名避免冲突)
# ============================================================================

class CultivationSkillType(Enum):
    INTERNAL = "internal"     # 内功
    EXTERNAL = "external"     # 外功
    LIGHTNESS = "lightness"   # 轻功
    ULTIMATE = "ultimate"     # 绝招


# ============================================================================
# 物品类型枚举 (from entities.py)
# ============================================================================

class ItemType(Enum):
    CONSUMABLE = "consumable"
    WEAPON = "weapon"
    ARMOR = "armor"
    MATERIAL = "material"
    BOOK = "book"
    QUEST = "quest"


# ============================================================================
# 任务类型枚举 (from entities.py)
# ============================================================================

class QuestType(Enum):
    FETCH = "fetch"
    KILL = "kill"
    TALK = "talk"
    EXPLORE = "explore"
    DELIVER = "deliver"
    GUARD = "guard"


# ============================================================================
# 装备槽位枚举 (from systems/equipment_system.py)
# ============================================================================

class EquipmentSlot(Enum):
    WEAPON = "weapon"         # 武器
    ARMOR = "armor"           # 防具
    HELMET = "helmet"         # 头盔
    ACCESSORY = "accessory"   # 饰品
    BOOTS = "boots"           # 鞋子
    BELT = "belt"             # 腰带


# ============================================================================
# 物品稀有度枚举 (from systems/economy_system.py)
# ============================================================================

class ItemRarity(Enum):
    COMMON = 1      # 普通
    UNCOMMON = 2    # 优秀
    RARE = 3        # 稀有
    EPIC = 4        # 史诗
    LEGENDARY = 5   # 传说


# ============================================================================
# 商店类型枚举 (from systems/economy_system.py)
# ============================================================================

class ShopType(Enum):
    GENERAL = "general"        # 杂货铺
    WEAPON = "weapon"          # 兵器铺
    ARMOR = "armor"            # 防具铺
    MEDICINE = "medicine"      # 药铺
    HERBAL = "herbal"          # 草药店
    FOOD = "food"              # 食肆
    TEAHOUSE = "teahouse"      # 茶馆
    INN = "inn"                # 客栈
    BLACKMARKET = "black"      # 黑市


# ============================================================================
# 势力名称映射 (from entities.py)
# ============================================================================

FACTION_NAMES = {
    Faction.NONE: "无门无派",
    Faction.BAGUA: "八卦门",
    Faction.FLOWER: "花间派",
    Faction.HONGLIAN: "红莲教",
    Faction.NAJA: "那迦派",
    Faction.TAIJI: "太极门",
    Faction.XUESHAN: "雪山派",
    Faction.XIAOYAO: "逍遥派",
}

SKILL_TYPE_NAMES = ["拳脚", "剑法", "刀法", "内功", "躲闪", "招架", "棍法", "杖法", "鞭法", "识字", "容貌"]


# ============================================================================
# 核心数据类 (from entities.py)
# ============================================================================

@dataclass
class Position:
    x: float = 0.0
    y: float = 0.0

    def distance_to(self, other: 'Position') -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

    def __add__(self, other: 'Position') -> 'Position':
        return Position(self.x + other.x, self.y + other.y)


@dataclass
class Skill:
    id: str
    name: str
    type: int
    level: int = 1
    exp: int = 0
    damage: int = 0
    accuracy: float = 0.8
    description: str = ""

    def get_exp_for_next_level(self) -> int:
        return self.level * 100

    def add_exp(self, amount: int) -> bool:
        self.exp += amount
        needed = self.get_exp_for_next_level()
        if self.exp >= needed:
            self.exp -= needed
            self.level += 1
            self.damage += self.level
            return True
        return False


@dataclass
class Item:
    """物品数据类 - 以 entities.py 版本为基础，附加装备兼容字段"""
    id: str
    name: str
    type: ItemType
    price: int = 0
    description: str = ""
    effects: Dict[str, int] = field(default_factory=dict)
    quantity: int = 1

    # 装备兼容字段 (backward compatible with equipment_system.py)
    rarity: Optional[int] = None
    weight: float = 1.0
    slot: Optional[EquipmentSlot] = None
    attack_bonus: int = 0
    defense_bonus: int = 0
    hp_bonus: int = 0
    mp_bonus: int = 0
    speed_bonus: int = 0
    enhance_level: int = 0
