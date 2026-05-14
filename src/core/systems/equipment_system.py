#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
装备打造系统 - Equipment and Crafting System
锻造、炼丹、制衣、烹饪

特色:
1. 装备系统 - 武器、防具、饰品
2. 锻造系统 - 打造兵器、强化升级
3. 炼丹系统 - 炼制丹药、提升品质
4. 制衣系统 - 缝制服装、镶嵌宝石
5. 烹饪系统 - 制作食物、临时增益
"""

import random
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum, auto


class EquipmentSlot(Enum):
    """装备槽位"""
    WEAPON = "weapon"       # 武器
    ARMOR = "armor"         # 防具
    HELMET = "helmet"       # 头盔
    ACCESSORY = "accessory" # 饰品
    BOOTS = "boots"         # 鞋子
    BELT = "belt"           # 腰带


class ItemType(Enum):
    """物品类型"""
    WEAPON = "weapon"
    ARMOR = "armor"
    ACCESSORY = "accessory"
    CONSUMABLE = "consumable"
    MATERIAL = "material"
    QUEST = "quest"
    BOOK = "book"


@dataclass
class Item:
    """物品"""
    id: str
    name: str
    description: str
    item_type: ItemType
    rarity: int = 1  # 1-5
    
    # 基础属性
    value: int = 0
    weight: float = 1.0
    stackable: bool = True
    max_stack: int = 99
    
    # 装备属性
    slot: Optional[EquipmentSlot] = None
    attack: int = 0
    defense: int = 0
    speed: int = 0
    hp_bonus: int = 0
    mp_bonus: int = 0
    
    # 特殊效果
    effects: List[str] = field(default_factory=list)
    
    # 强化等级
    enhance_level: int = 0
    max_enhance: int = 10


@dataclass
class Recipe:
    """配方"""
    id: str
    name: str
    result_item: str
    result_count: int = 1
    
    # 材料
    materials: Dict[str, int] = field(default_factory=dict)
    
    # 需求
    skill_required: str = ""
    skill_level: int = 1
    
    # 成功率
    base_success_rate: float = 0.8
    
    # 品质
    quality_range: Tuple[int, int] = (1, 3)


@dataclass
class CraftingSkill:
    """打造技能"""
    name: str
    level: int = 1
    exp: int = 0
    
    @property
    def exp_needed(self) -> int:
        return self.level * 100


# 材料数据库
MATERIALS: Dict[str, Item] = {
    "iron_ore": Item("iron_ore", "铁矿石", "炼铁的原料", ItemType.MATERIAL, value=10),
    "steel_ingot": Item("steel_ingot", "钢材", "精炼的钢材", ItemType.MATERIAL, rarity=2, value=50),
    "leather": Item("leather", "皮革", "制衣材料", ItemType.MATERIAL, value=15),
    "silk": Item("silk", "丝绸", "高级布料", ItemType.MATERIAL, rarity=2, value=40),
    "herb_common": Item("herb_common", "普通草药", "常见草药", ItemType.MATERIAL, value=5),
    "herb_rare": Item("herb_rare", "珍稀草药", "稀有草药", ItemType.MATERIAL, rarity=2, value=30),
    "herb_legendary": Item("herb_legendary", "灵芝", "传说中的灵药", ItemType.MATERIAL, rarity=4, value=200),
    "gem_small": Item("gem_small", "小宝石", "小型宝石", ItemType.MATERIAL, rarity=2, value=50),
    "gem_large": Item("gem_large", "大宝石", "大型宝石", ItemType.MATERIAL, rarity=3, value=150),
}

# 武器数据库
WEAPONS: Dict[str, Item] = {
    "wood_sword": Item("wood_sword", "木剑", "练习用的木剑", ItemType.WEAPON, 
                       slot=EquipmentSlot.WEAPON, attack=5, value=20),
    "iron_sword": Item("iron_sword", "铁剑", "普通的铁剑", ItemType.WEAPON,
                       slot=EquipmentSlot.WEAPON, attack=15, value=100),
    "steel_sword": Item("steel_sword", "钢剑", "精钢打造的长剑", ItemType.WEAPON,
                        rarity=2, slot=EquipmentSlot.WEAPON, attack=25, value=300),
    "bagua_blade": Item("bagua_blade", "八卦刀", "八卦门专用兵器", ItemType.WEAPON,
                        rarity=3, slot=EquipmentSlot.WEAPON, attack=40, value=800,
                        effects=["bagua_bonus"]),
}

# 丹药数据库
PILLS: Dict[str, Item] = {
    "minor_heal_pill": Item("minor_heal_pill", "金创药", "恢复少量气血", ItemType.CONSUMABLE,
                            value=30, effects=["heal_50"]),
    "major_heal_pill": Item("major_heal_pill", "小还丹", "恢复中量气血", ItemType.CONSUMABLE,
                            rarity=2, value=100, effects=["heal_150"]),
    "full_heal_pill": Item("full_heal_pill", "大还丹", "恢复全部气血", ItemType.CONSUMABLE,
                           rarity=4, value=500, effects=["heal_full"]),
    "mp_pill": Item("mp_pill", "归元丹", "恢复内力", ItemType.CONSUMABLE,
                    value=50, effects=["mp_100"]),
    "attack_boost_pill": Item("attack_boost_pill", "大力丸", "临时提升攻击力", ItemType.CONSUMABLE,
                              rarity=2, value=80, effects=["attack_boost_20_300"]),
}

# 配方数据库
RECIPES: Dict[str, Recipe] = {
    # 锻造配方
    "forge_iron_sword": Recipe(
        "forge_iron_sword", "锻造铁剑",
        "iron_sword",
        materials={"iron_ore": 5, "leather": 1},
        skill_required="blacksmith", skill_level=1,
        base_success_rate=0.9
    ),
    "forge_steel_sword": Recipe(
        "forge_steel_sword", "锻造钢剑",
        "steel_sword",
        materials={"steel_ingot": 3, "iron_ore": 2, "leather": 2},
        skill_required="blacksmith", skill_level=3,
        base_success_rate=0.7,
        quality_range=(2, 4)
    ),
    
    # 炼丹配方
    "alchemy_minor_heal": Recipe(
        "alchemy_minor_heal", "炼制金创药",
        "minor_heal_pill", result_count=3,
        materials={"herb_common": 2},
        skill_required="alchemy", skill_level=1,
        base_success_rate=0.95
    ),
    "alchemy_major_heal": Recipe(
        "alchemy_major_heal", "炼制小还丹",
        "major_heal_pill", result_count=2,
        materials={"herb_common": 3, "herb_rare": 1},
        skill_required="alchemy", skill_level=2,
        base_success_rate=0.8
    ),
    "alchemy_full_heal": Recipe(
        "alchemy_full_heal", "炼制大还丹",
        "full_heal_pill",
        materials={"herb_rare": 5, "herb_legendary": 1},
        skill_required="alchemy", skill_level=5,
        base_success_rate=0.5,
        quality_range=(3, 5)
    ),
    
    # 制衣配方
    "craft_leather_armor": Recipe(
        "craft_leather_armor", "缝制皮甲",
        "leather_armor",
        materials={"leather": 5},
        skill_required="tailor", skill_level=1,
        base_success_rate=0.9
    ),
}


class Inventory:
    """背包系统"""
    
    def __init__(self, max_slots: int = 50):
        self.max_slots = max_slots
        self.items: Dict[str, int] = {}  # item_id -> count
        self.equipped: Dict[EquipmentSlot, Optional[str]] = {slot: None for slot in EquipmentSlot}
        
    def add_item(self, item_id: str, count: int = 1) -> bool:
        """添加物品"""
        current = self.items.get(item_id, 0)
        self.items[item_id] = current + count
        return True
        
    def remove_item(self, item_id: str, count: int = 1) -> bool:
        """移除物品"""
        current = self.items.get(item_id, 0)
        if current < count:
            return False
        if current == count:
            del self.items[item_id]
        else:
            self.items[item_id] = current - count
        return True
        
    def get_count(self, item_id: str) -> int:
        """获取物品数量"""
        return self.items.get(item_id, 0)
        
    def equip(self, item_id: str) -> bool:
        """装备物品"""
        # 获取物品信息
        item = WEAPONS.get(item_id) or PILLS.get(item_id)
        if not item or not item.slot:
            return False
            
        if item_id not in self.items:
            return False
            
        # 卸下当前装备
        current = self.equipped[item.slot]
        if current:
            self.add_item(current)
            
        # 装备新物品
        self.equipped[item.slot] = item_id
        self.remove_item(item_id)
        
        return True
        
    def unequip(self, slot: EquipmentSlot) -> bool:
        """卸下装备"""
        item_id = self.equipped[slot]
        if not item_id:
            return False
            
        self.equipped[slot] = None
        self.add_item(item_id)
        return True
        
    def get_total_stats(self) -> Dict[str, int]:
        """获取装备总属性"""
        stats = {"attack": 0, "defense": 0, "speed": 0, "hp_bonus": 0, "mp_bonus": 0}
        
        for slot, item_id in self.equipped.items():
            if not item_id:
                continue
            item = WEAPONS.get(item_id)
            if item:
                stats["attack"] += item.attack
                stats["defense"] += item.defense
                stats["speed"] += item.speed
                stats["hp_bonus"] += item.hp_bonus
                stats["mp_bonus"] += item.mp_bonus
                
        return stats


class CraftingSystem:
    """打造系统"""
    
    def __init__(self):
        self.inventory = Inventory()
        
        # 技能等级
        self.skills: Dict[str, CraftingSkill] = {
            "blacksmith": CraftingSkill("锻造", 1),
            "alchemy": CraftingSkill("炼丹", 1),
            "tailor": CraftingSkill("制衣", 1),
            "cooking": CraftingSkill("烹饪", 1),
        }
        
    def can_craft(self, recipe_id: str) -> Tuple[bool, str]:
        """检查是否可以打造"""
        recipe = RECIPES.get(recipe_id)
        if not recipe:
            return False, "配方不存在"
            
        # 检查技能
        skill = self.skills.get(recipe.skill_required)
        if not skill or skill.level < recipe.skill_level:
            return False, f"需要{recipe.skill_required}等级{recipe.skill_level}"
            
        # 检查材料
        for mat_id, count in recipe.materials.items():
            if self.inventory.get_count(mat_id) < count:
                return False, f"材料不足: {mat_id}"
                
        return True, "可以打造"
        
    def craft(self, recipe_id: str) -> Tuple[bool, str, Optional[Item]]:
        """打造物品"""
        can_craft, msg = self.can_craft(recipe_id)
        if not can_craft:
            return False, msg, None
            
        recipe = RECIPES[recipe_id]
        
        # 消耗材料
        for mat_id, count in recipe.materials.items():
            self.inventory.remove_item(mat_id, count)
            
        # 计算成功率
        skill = self.skills[recipe.skill_required]
        success_rate = recipe.base_success_rate + (skill.level - recipe.skill_level) * 0.05
        success_rate = min(1.0, success_rate)
        
        if random.random() > success_rate:
            # 失败
            skill.exp += 10
            return False, "打造失败，材料已消耗", None
            
        # 成功
        # 计算品质
        min_q, max_q = recipe.quality_range
        quality = random.randint(min_q, max_q)
        
        # 获取结果物品
        result_item = WEAPONS.get(recipe.result_item) or PILLS.get(recipe.result_item)
        if result_item:
            # 创建副本并应用品质
            item = Item(
                result_item.id, result_item.name, result_item.description,
                result_item.item_type, rarity=quality,
                value=result_item.value * quality,
                slot=result_item.slot,
                attack=int(result_item.attack * (1 + (quality - 1) * 0.2)),
                defense=int(result_item.defense * (1 + (quality - 1) * 0.2)),
            )
        else:
            item = Item(recipe.result_item, recipe.result_item, "打造物品", ItemType.MATERIAL)
            
        # 添加到背包
        self.inventory.add_item(recipe.result_item, recipe.result_count)
        
        # 增加经验
        skill.exp += 20 + recipe.skill_level * 10
        if skill.exp >= skill.exp_needed:
            skill.level += 1
            skill.exp = 0
            
        return True, f"打造成功，获得{item.name}", item
        
    def enhance_equipment(self, item_id: str) -> Tuple[bool, str]:
        """强化装备"""
        item = WEAPONS.get(item_id)
        if not item:
            return False, "物品不存在"
            
        if item.enhance_level >= item.max_enhance:
            return False, "已达到最大强化等级"
            
        # 强化材料
        enhance_cost = {
            0: ("iron_ore", 5),
            1: ("iron_ore", 10),
            2: ("steel_ingot", 5),
            3: ("steel_ingot", 10),
            4: ("gem_small", 3),
        }
        
        level = item.enhance_level
        if level >= len(enhance_cost):
            mat_id, count = "gem_large", level - 3
        else:
            mat_id, count = enhance_cost[level]
            
        if self.inventory.get_count(mat_id) < count:
            return False, f"强化材料不足: {mat_id} x{count}"
            
        # 消耗材料
        self.inventory.remove_item(mat_id, count)
        
        # 成功率
        success_rate = 0.9 - level * 0.1
        
        if random.random() > success_rate:
            return False, "强化失败"
            
        # 成功
        item.enhance_level += 1
        item.attack = int(item.attack * 1.1)
        item.defense = int(item.defense * 1.1)
        
        return True, f"强化成功，当前+{item.enhance_level}"
