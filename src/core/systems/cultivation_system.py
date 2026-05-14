#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
武学修炼系统 - Martial Arts Cultivation System
深度武学体系，包含内功、外功、轻功、绝招

特色:
1. 内功修炼 - 内力上限、恢复速度、属性加成
2. 外功招式 - 各门派武学、招式熟练度
3. 轻功身法 - 移动速度、闪避、特殊移动
4. 绝招系统 - 强力技能、冷却机制
5. 经脉系统 - 督力打通、永久加成
"""

import math
import random
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum, auto


class Meridian(Enum):
    """经脉"""
    REN = "ren"           # 任脉
    DU = "du"             # 督脉
    CHONG = "chong"       # 冲脉
    DAI = "dai"           # 带脉
    YANGQIAO = "yangqiao" # 阳跷脉
    YINQIAO = "yinqiao"   # 阴跷脉
    YANGWEI = "yangwei"   # 阳维脉
    YINWEI = "yinwei"     # 阴维脉


class SkillType(Enum):
    """武学类型"""
    INTERNAL = "internal"   # 内功
    EXTERNAL = "external"   # 外功
    LIGHTNESS = "lightness" # 轻功
    ULTIMATE = "ultimate"   # 绝招


@dataclass
class MeridianState:
    """经脉状态"""
    meridian: Meridian
    is_open: bool = False
    level: int = 0        # 督通层数 (0-9)
    progress: float = 0.0  # 当前层进度
    
    @property
    def bonus(self) -> Dict[str, int]:
        """获取经脉加成"""
        if not self.is_open:
            return {}
            
        # 各经脉的加成效果
        bonuses = {
            Meridian.REN: {"max_mp": 10, "mp_regen": 1},
            Meridian.DU: {"attack": 2, "defense": 1},
            Meridian.CHONG: {"max_hp": 20, "hp_regen": 1},
            Meridian.DAI: {"speed": 1, "dodge": 2},
            Meridian.YANGQIAO: {"critical": 2, "critical_damage": 5},
            Meridian.YINQIAO: {"counter": 3, "parry": 2},
            Meridian.YANGWEI: {"internal_damage": 3, "skill_damage": 2},
            Meridian.YINWEI: {"resistance": 2, "status_resist": 3},
        }
        
        base = bonuses.get(self.meridian, {})
        return {k: v * (self.level + 1) for k, v in base.items()}


@dataclass
class MartialSkill:
    """武学技能"""
    id: str
    name: str
    description: str
    skill_type: SkillType
    faction: str           # 所属门派
    
    # 属性
    level: int = 1         # 当前等级
    max_level: int = 10    # 最大等级
    proficiency: float = 0.0  # 熟练度
    
    # 消耗
    mp_cost: int = 0
    hp_cost: int = 0
    
    # 效果
    damage_base: int = 0
    damage_scale: float = 1.0
    cooldown: float = 0.0
    
    # 特殊效果
    effects: List[str] = field(default_factory=list)
    
    # 需求
    requirements: Dict[str, int] = field(default_factory=dict)
    
    @property
    def damage(self) -> int:
        """计算伤害"""
        return int(self.damage_base + self.damage_scale * self.level * 10)
        
    @property
    def is_mastered(self) -> bool:
        """是否精通"""
        return self.level >= self.max_level
        
    def can_level_up(self, player_stats: Dict[str, int]) -> bool:
        """是否可以升级"""
        if self.level >= self.max_level:
            return False
        for stat, value in self.requirements.items():
            if player_stats.get(stat, 0) < value:
                return False
        return True


@dataclass
class InternalArt:
    """内功心法"""
    id: str
    name: str
    description: str
    faction: str
    
    level: int = 1
    max_level: int = 9
    
    # 内力属性
    mp_base: int = 100
    mp_per_level: int = 20
    mp_regen: float = 1.0
    
    # 属性加成
    hp_bonus: int = 0
    attack_bonus: int = 0
    defense_bonus: int = 0
    speed_bonus: int = 0
    
    # 特殊效果
    effects: List[str] = field(default_factory=list)
    
    @property
    def max_mp(self) -> int:
        return self.mp_base + self.mp_per_level * self.level
        
    @property
    def total_bonus(self) -> Dict[str, int]:
        return {
            "max_mp": self.max_mp,
            "mp_regen": int(self.mp_regen * self.level),
            "max_hp": self.hp_bonus * self.level,
            "attack": self.attack_bonus * self.level,
            "defense": self.defense_bonus * self.level,
            "speed": self.speed_bonus * self.level,
        }


@dataclass
class LightnessArt:
    """轻功身法"""
    id: str
    name: str
    description: str
    faction: str
    
    level: int = 1
    max_level: int = 9
    
    # 移动属性
    speed_base: float = 1.0
    speed_per_level: float = 0.1
    
    # 闪避
    dodge_base: int = 5
    dodge_per_level: int = 2
    
    # 特殊能力
    can_water_walk: bool = False
    can_wall_run: bool = False
    can_double_jump: bool = False
    
    @property
    def speed(self) -> float:
        return self.speed_base + self.speed_per_level * self.level
        
    @property
    def dodge(self) -> int:
        return self.dodge_base + self.dodge_per_level * self.level


# 内功心法数据库
INTERNAL_ARTS: Dict[str, InternalArt] = {
    "hunyuan_gong": InternalArt(
        "hunyuan_gong", "混元功", "八卦门基础内功，中正平和",
        "BAGUA", mp_base=120, mp_regen=1.2, attack_bonus=2
    ),
    "bagua_neigong": InternalArt(
        "bagua_neigong", "八卦内功", "八卦门进阶内功，变化无穷",
        "BAGUA", level=1, max_level=9, mp_base=150, mp_regen=1.5,
        attack_bonus=3, defense_bonus=2, effects=["bagua_aura"]
    ),
    "flower_heart": InternalArt(
        "flower_heart", "花心诀", "花间派内功，如花绽放",
        "FLOWER", mp_base=100, mp_regen=1.3, speed_bonus=2
    ),
    "honglian_jue": InternalArt(
        "honglian_jue", "红莲诀", "红莲教内功，炽热如火",
        "HONGLIAN", mp_base=130, mp_regen=1.4, attack_bonus=4
    ),
    "naja_jue": InternalArt(
        "naja_jue", "那迦诀", "那迦派内功，隐忍如影",
        "NAJA", mp_base=110, mp_regen=1.2, speed_bonus=3
    ),
    "taiji_gong": InternalArt(
        "taiji_gong", "太极功", "太极门内功，阴阳调和",
        "TAIJI", mp_base=140, mp_regen=1.6, defense_bonus=3, hp_bonus=10
    ),
    "xueshan_gong": InternalArt(
        "xueshan_gong", "雪山功", "雪山派内功，寒冰入体",
        "XUESHAN", mp_base=120, mp_regen=1.3, defense_bonus=2
    ),
    "beiming_shengong": InternalArt(
        "beiming_shengong", "北冥神功", "逍遥派绝学，吸人内力",
        "XIAOYAO", mp_base=200, mp_regen=2.0, mp_per_level=30,
        effects=["drain_mp", "limitless_mp"]
    ),
}

# 轻功数据库
LIGHTNESS_ARTS: Dict[str, LightnessArt] = {
    "bagua_step": LightnessArt(
        "bagua_step", "八卦步", "八卦门轻功，走转腾挪",
        "BAGUA", speed_base=1.1, dodge_base=8
    ),
    "flower_dance": LightnessArt(
        "flower_dance", "花舞步", "花间派轻功，飘逸如花",
        "FLOWER", speed_base=1.2, dodge_base=10, can_double_jump=True
    ),
    "shadow_step": LightnessArt(
        "shadow_step", "影步", "那迦派轻功，无声无息",
        "NAJA", speed_base=1.15, dodge_base=12, can_water_walk=True
    ),
    "lingbo_weibu": LightnessArt(
        "lingbo_weibu", "凌波微步", "逍遥派绝学，飘渺无踪",
        "XIAOYAO", speed_base=1.3, dodge_base=15,
        can_water_walk=True, can_double_jump=True, can_wall_run=True
    ),
    "snow_drift": LightnessArt(
        "snow_drift", "踏雪无痕", "雪山派轻功，踏雪而行",
        "XUESHAN", speed_base=1.1, dodge_base=8, can_water_walk=True
    ),
}


class CultivationSystem:
    """修炼系统"""
    
    def __init__(self):
        # 经脉
        self.meridians: Dict[Meridian, MeridianState] = {
            m: MeridianState(m) for m in Meridian
        }
        
        # 内功
        self.internal_art: Optional[InternalArt] = None
        self.internal_arts_known: Set[str] = set()
        
        # 轻功
        self.lightness_art: Optional[LightnessArt] = None
        self.lightness_arts_known: Set[str] = set()
        
        # 外功招式
        self.skills: Dict[str, MartialSkill] = {}
        
        # 修炼经验
        self.cultivation_exp: int = 0
        self.cultivation_level: int = 1
        
    def learn_internal_art(self, art_id: str) -> bool:
        """学习内功"""
        if art_id not in INTERNAL_ARTS:
            return False
            
        art = INTERNAL_ARTS[art_id]
        
        # 检查是否已学习
        if art_id in self.internal_arts_known:
            return False
            
        self.internal_arts_known.add(art_id)
        
        # 如果没有装备内功，自动装备
        if self.internal_art is None:
            self.internal_art = InternalArt(
                art.id, art.name, art.description, art.faction,
                mp_base=art.mp_base, mp_regen=art.mp_regen,
                attack_bonus=art.attack_bonus, defense_bonus=art.defense_bonus,
                speed_bonus=art.speed_bonus, hp_bonus=art.hp_bonus,
                effects=art.effects.copy()
            )
            
        return True
        
    def equip_internal_art(self, art_id: str) -> bool:
        """装备内功"""
        if art_id not in self.internal_arts_known:
            return False
            
        art = INTERNAL_ARTS[art_id]
        self.internal_art = InternalArt(
            art.id, art.name, art.description, art.faction,
            level=self.internal_art.level if self.internal_art and self.internal_art.id == art_id else 1,
            mp_base=art.mp_base, mp_regen=art.mp_regen,
            attack_bonus=art.attack_bonus, defense_bonus=art.defense_bonus,
            speed_bonus=art.speed_bonus, hp_bonus=art.hp_bonus,
            effects=art.effects.copy()
        )
        return True
        
    def learn_lightness_art(self, art_id: str) -> bool:
        """学习轻功"""
        if art_id not in LIGHTNESS_ARTS:
            return False
            
        if art_id in self.lightness_arts_known:
            return False
            
        self.lightness_arts_known.add(art_id)
        
        if self.lightness_art is None:
            art = LIGHTNESS_ARTS[art_id]
            self.lightness_art = LightnessArt(
                art.id, art.name, art.description, art.faction,
                speed_base=art.speed_base, dodge_base=art.dodge_base,
                can_water_walk=art.can_water_walk,
                can_wall_run=art.can_wall_run,
                can_double_jump=art.can_double_jump
            )
            
        return True
        
    def learn_skill(self, skill: MartialSkill) -> bool:
        """学习武学招式"""
        if skill.id in self.skills:
            return False
            
        self.skills[skill.id] = skill
        return True
        
    def upgrade_skill(self, skill_id: str) -> bool:
        """升级武学招式"""
        skill = self.skills.get(skill_id)
        if not skill:
            return False
            
        if skill.level >= skill.max_level:
            return False
            
        # 消耗修炼经验
        cost = skill.level * 100
        if self.cultivation_exp < cost:
            return False
            
        self.cultivation_exp -= cost
        skill.level += 1
        return True
        
    def upgrade_internal_art(self) -> bool:
        """升级内功"""
        if not self.internal_art:
            return False
            
        if self.internal_art.level >= self.internal_art.max_level:
            return False
            
        cost = self.internal_art.level * 200
        if self.cultivation_exp < cost:
            return False
            
        self.cultivation_exp -= cost
        self.internal_art.level += 1
        return True
        
    def open_meridian(self, meridian: Meridian) -> bool:
        """打通经脉"""
        state = self.meridians[meridian]
        
        if state.is_open:
            return False
            
        # 检查前置经脉
        prerequisites = {
            Meridian.DU: [Meridian.REN],
            Meridian.CHONG: [Meridian.REN, Meridian.DU],
            Meridian.DAI: [Meridian.CHONG],
            Meridian.YANGQIAO: [Meridian.DU],
            Meridian.YINQIAO: [Meridian.DU],
            Meridian.YANGWEI: [Meridian.YANGQIAO],
            Meridian.YINWEI: [Meridian.YINQIAO],
        }
        
        for pre in prerequisites.get(meridian, []):
            if not self.meridians[pre].is_open:
                return False
                
        # 消耗修炼经验
        cost = 500 * (len([m for m in self.meridians.values() if m.is_open]) + 1)
        if self.cultivation_exp < cost:
            return False
            
        self.cultivation_exp -= cost
        state.is_open = True
        state.level = 0
        state.progress = 0.0
        
        return True
        
    def train_meridian(self, meridian: Meridian, exp: float) -> bool:
        """修炼经脉"""
        state = self.meridians[meridian]
        
        if not state.is_open:
            return False
            
        if state.level >= 9:
            return False
            
        state.progress += exp
        
        # 升级
        if state.progress >= 1.0:
            state.level += 1
            state.progress = 0.0
            return True
            
        return False
        
    def get_total_stats(self) -> Dict[str, int]:
        """获取总属性加成"""
        stats = {}
        
        # 内功加成
        if self.internal_art:
            for k, v in self.internal_art.total_bonus.items():
                stats[k] = stats.get(k, 0) + v
                
        # 轻功加成
        if self.lightness_art:
            stats["speed"] = stats.get("speed", 0) + int(self.lightness_art.speed * 10)
            stats["dodge"] = stats.get("dodge", 0) + self.lightness_art.dodge
            
        # 经脉加成
        for state in self.meridians.values():
            for k, v in state.bonus.items():
                stats[k] = stats.get(k, 0) + v
                
        return stats
        
    def add_cultivation_exp(self, exp: int) -> None:
        """增加修炼经验"""
        self.cultivation_exp += exp
        
        # 检查升级
        exp_needed = self.cultivation_level * 1000
        while self.cultivation_exp >= exp_needed:
            self.cultivation_exp -= exp_needed
            self.cultivation_level += 1
            exp_needed = self.cultivation_level * 1000
            
    def get_available_skills(self) -> List[MartialSkill]:
        """获取可用技能"""
        return [s for s in self.skills.values() if s.level > 0]
