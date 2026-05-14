#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
混合战斗系统 - Hybrid Combat System
大地图半即时探索 + 回合制战斗界面

特色:
1. 大地图探索 - 半即时移动、遇敌检测
2. 回合制战斗 - 策略性回合战斗
3. 战斗UI - 水墨风格战斗界面
4. 战斗动画 - 招式演出效果
"""

import math
import random
from typing import List, Dict, Optional, Tuple, Callable
from dataclasses import dataclass, field
from enum import Enum, auto


class CombatPhase(Enum):
    """战斗阶段"""
    NONE = auto()          # 非战斗状态
    INIT = auto()          # 战斗初始化
    PLAYER_TURN = auto()   # 玩家回合
    ENEMY_TURN = auto()    # 敌人回合
    ANIMATION = auto()     # 播放动画
    VICTORY = auto()       # 战斗胜利
    DEFEAT = auto()        # 战斗失败
    FLEE = auto()          # 逃跑


class ActionType(Enum):
    """行动类型"""
    ATTACK = auto()      # 普通攻击
    SKILL = auto()       # 武学招式
    ITEM = auto()        # 使用物品
    DEFEND = auto()      # 防御
    FLEE = auto()        # 逃跑


@dataclass
class Combatant:
    """战斗单位"""
    name: str
    max_hp: int
    hp: int
    max_mp: int
    mp: int
    attack: int
    defense: int
    speed: int
    is_player: bool = False
    faction: str = ""
    skills: List[str] = field(default_factory=list)
    buffs: List[Dict] = field(default_factory=list)
    
    # 战斗状态
    is_defending: bool = False
    is_stunned: bool = False
    
    @property
    def is_alive(self) -> bool:
        return self.hp > 0
        
    @property
    def hp_percent(self) -> float:
        return self.hp / self.max_hp if self.max_hp > 0 else 0
        
    @property
    def mp_percent(self) -> float:
        return self.mp / self.max_mp if self.max_mp > 0 else 0


@dataclass
class CombatAction:
    """战斗行动"""
    actor: Combatant
    action_type: ActionType
    target: Optional[Combatant] = None
    skill_name: str = ""
    damage: int = 0
    mp_cost: int = 0
    is_critical: bool = False
    is_hit: bool = True
    message: str = ""


@dataclass
class SkillData:
    """武学招式数据"""
    name: str
    name_zh: str
    description: str
    mp_cost: int
    damage_multiplier: float
    element: str = "physical"
    target_type: str = "single"  # single, all, self
    effect: Optional[str] = None
    effect_chance: float = 0.0
    animation: str = "slash"


# 武学招式数据库
SKILLS_DATABASE: Dict[str, SkillData] = {
    # 八卦门
    "bagua_zhang": SkillData("bagua_zhang", "八卦掌", "八卦门基础掌法，变化多端", 5, 1.2, "physical"),
    "hunyuan_yiqi": SkillData("hunyuan_yiqi", "混元一气", "八卦门绝学，浑厚内劲", 20, 2.0, "internal"),
    "bagua_daofa": SkillData("bagua_daofa", "八卦刀法", "八卦门刀法，走转劈砍", 15, 1.8, "physical"),
    
    # 百花谷
    "flower_sword": SkillData("flower_sword", "落花剑", "花间派剑法，飘逸如花", 8, 1.3, "physical"),
    "hundred_flowers": SkillData("hundred_flowers", "百花缭乱", "花间派绝学，漫天花雨", 25, 2.2, "physical", target_type="all"),
    "fragrance_palms": SkillData("fragrance_palms", "暗香掌", "花间派掌法，暗香袭人", 12, 1.5, "internal"),
    
    # 红莲教
    "red_lotus": SkillData("red_lotus", "红莲密咒", "红莲教秘术，炽热如莲", 10, 1.4, "fire"),
    "blood_blade": SkillData("blood_blade", "血刃", "红莲教刀法，嗜血狂斩", 18, 1.9, "physical"),
    "righteous_fist": SkillData("righteous_fist", "义拳", "红莲教拳法，义薄云天", 6, 1.1, "physical"),
    
    # 那迦派
    "shadow_strike": SkillData("shadow_strike", "影袭", "那迦派绝技，隐忍一击", 15, 2.0, "physical"),
    "ninja_blade": SkillData("ninja_blade", "忍刀", "那迦派刀法，无声无息", 8, 1.3, "physical"),
    "smoke_escape": SkillData("smoke_escape", "烟遁", "那迦派遁术，烟雾迷踪", 5, 0.5, "physical", effect="flee"),
    
    # 太极门
    "taiji_fist": SkillData("taiji_fist", "太极拳", "太极门拳法，以柔克刚", 8, 1.2, "internal"),
    "cloud_palms": SkillData("cloud_palms", "云手", "太极门掌法，连绵不绝", 12, 1.5, "internal"),
    "taiji_sword": SkillData("taiji_sword", "太极剑", "太极门剑法，圆转如意", 15, 1.7, "physical"),
    
    # 雪山派
    "snow_blade": SkillData("snow_blade", "雪山刀", "雪山派刀法，寒气逼人", 10, 1.4, "ice"),
    "frost_palms": SkillData("frost_palms", "寒冰掌", "雪山派掌法，冰封万里", 20, 1.8, "ice"),
    "avalanche": SkillData("avalanche", "雪崩", "雪山派绝学，天崩地裂", 30, 2.5, "ice"),
    
    # 逍遥派
    "xiaoyao_step": SkillData("xiaoyao_step", "凌波微步", "逍遥派轻功，飘渺无踪", 5, 0.8, "physical", effect="dodge"),
    "beiming_shengong": SkillData("beiming_shengong", "北冥神功", "逍遥派内功，吸人内力", 25, 1.5, "internal", effect="drain"),
    "liuyang_zhang": SkillData("liuyang_zhang", "六阳掌", "逍遥派掌法，纯阳至刚", 18, 2.0, "internal"),
    
    # 通用
    "basic_attack": SkillData("basic_attack", "普通攻击", "基础攻击", 0, 1.0, "physical"),
    "defend": SkillData("defend", "防御", "减少受到的伤害", 0, 0.0, "physical", target_type="self"),
}


class HybridCombatSystem:
    """混合战斗系统"""
    
    def __init__(self):
        self.phase = CombatPhase.NONE
        self.player: Optional[Combatant] = None
        self.enemies: List[Combatant] = []
        self.all_combatants: List[Combatant] = []
        self.turn_order: List[Combatant] = []
        self.current_turn_index: int = 0
        self.turn_count: int = 0
        
        # 行动队列
        self.action_queue: List[CombatAction] = []
        self.current_action: Optional[CombatAction] = None
        
        # 战斗日志
        self.battle_log: List[str] = []
        
        # 回调
        self.on_battle_end: Optional[Callable] = None
        self.on_action: Optional[Callable] = None
        
    def start_battle(self, player: Combatant, enemies: List[Combatant]) -> None:
        """开始战斗"""
        self.phase = CombatPhase.INIT
        self.player = player
        self.enemies = enemies
        self.all_combatants = [player] + enemies
        self.turn_count = 0
        self.battle_log = []
        self.action_queue = []
        
        # 计算行动顺序 (按速度排序)
        self.turn_order = sorted(self.all_combatants, key=lambda c: c.speed, reverse=True)
        self.current_turn_index = 0
        
        # 重置状态
        for c in self.all_combatants:
            c.is_defending = False
            c.is_stunned = False
            c.buffs = []
            
        self.battle_log.append(f"战斗开始！{player.name} 遭遇了 {', '.join(e.name for e in enemies)}")
        self.phase = CombatPhase.PLAYER_TURN if self.turn_order[0].is_player else CombatPhase.ENEMY_TURN
        
    def get_current_combatant(self) -> Optional[Combatant]:
        """获取当前行动者"""
        if self.current_turn_index < len(self.turn_order):
            return self.turn_order[self.current_turn_index]
        return None
        
    def player_action(self, action_type: ActionType, 
                     target: Optional[Combatant] = None,
                     skill_id: str = "") -> bool:
        """玩家行动"""
        if self.phase != CombatPhase.PLAYER_TURN:
            return False
            
        current = self.get_current_combatant()
        if not current or not current.is_player:
            return False
            
        action = self._execute_action(current, action_type, target, skill_id)
        if action:
            self.action_queue.append(action)
            self._process_action(action)
            self._next_turn()
            return True
        return False
        
    def enemy_ai_action(self) -> Optional[CombatAction]:
        """敌人AI行动"""
        if self.phase != CombatPhase.ENEMY_TURN:
            return None
            
        current = self.get_current_combatant()
        if not current or current.is_player:
            return None
            
        # 简单AI：随机选择攻击目标
        alive_targets = [c for c in self.all_combatants if c.is_player and c.is_alive]
        if not alive_targets:
            return None
            
        target = random.choice(alive_targets)
        
        # 随机选择技能
        available_skills = [s for s in current.skills if s in SKILLS_DATABASE]
        if available_skills and random.random() < 0.3:
            skill_id = random.choice(available_skills)
            action_type = ActionType.SKILL
        else:
            skill_id = "basic_attack"
            action_type = ActionType.ATTACK
            
        action = self._execute_action(current, action_type, target, skill_id)
        if action:
            self.action_queue.append(action)
            self._process_action(action)
            self._next_turn()
            return action
        return None
        
    def _execute_action(self, actor: Combatant, action_type: ActionType,
                       target: Optional[Combatant], skill_id: str) -> Optional[CombatAction]:
        """执行行动"""
        action = CombatAction(actor=actor, action_type=action_type, target=target)
        
        if action_type == ActionType.ATTACK:
            skill_id = "basic_attack"
            
        if action_type in (ActionType.ATTACK, ActionType.SKILL):
            skill = SKILLS_DATABASE.get(skill_id)
            if not skill:
                return None
                
            # 检查内力
            if actor.mp < skill.mp_cost:
                self.battle_log.append(f"{actor.name} 内力不足！")
                return None
                
            action.skill_name = skill.name_zh
            action.mp_cost = skill.mp_cost
            actor.mp -= skill.mp_cost
            
            if target:
                # 计算伤害
                base_damage = actor.attack * skill.damage_multiplier
                defense = target.defense * (2 if target.is_defending else 1)
                damage = max(1, int(base_damage - defense * 0.5))
                
                # 暴击判定
                if random.random() < 0.1:
                    damage = int(damage * 1.5)
                    action.is_critical = True
                    
                # 命中判定
                if random.random() < 0.05:
                    action.is_hit = False
                    damage = 0
                    
                action.damage = damage
                target.hp = max(0, target.hp - damage)
                
                # 生成消息
                if action.is_hit:
                    msg = f"{actor.name} 使用 {skill.name_zh} 对 {target.name} 造成 {damage} 点伤害"
                    if action.is_critical:
                        msg += " (暴击!)"
                else:
                    msg = f"{actor.name} 的 {skill.name_zh} 未命中 {target.name}"
                action.message = msg
                self.battle_log.append(msg)
                
                # 特殊效果
                if skill.effect and random.random() < skill.effect_chance:
                    self._apply_effect(skill.effect, target)
                    
        elif action_type == ActionType.DEFEND:
            actor.is_defending = True
            action.message = f"{actor.name} 进入防御姿态"
            self.battle_log.append(action.message)
            
        elif action_type == ActionType.FLEE:
            flee_chance = 0.3 + (actor.speed - sum(e.speed for e in self.enemies if e.is_alive) / max(1, len([e for e in self.enemies if e.is_alive]))) * 0.01
            if random.random() < flee_chance:
                self.phase = CombatPhase.FLEE
                action.message = f"{actor.name} 成功逃脱！"
            else:
                action.message = f"{actor.name} 逃跑失败！"
            self.battle_log.append(action.message)
            
        return action
        
    def _apply_effect(self, effect: str, target: Combatant) -> None:
        """应用特殊效果"""
        if effect == "stun":
            target.is_stunned = True
            self.battle_log.append(f"{target.name} 被击晕了！")
        elif effect == "drain":
            drain = int(target.max_mp * 0.1)
            target.mp = max(0, target.mp - drain)
            if self.player:
                self.player.mp = min(self.player.max_mp, self.player.mp + drain)
            self.battle_log.append(f"吸取了 {target.name} {drain} 点内力！")
            
    def _process_action(self, action: CombatAction) -> None:
        """处理行动结果"""
        # 检查战斗结束
        if self.player and not self.player.is_alive:
            self.phase = CombatPhase.DEFEAT
            self.battle_log.append("战斗失败...")
            if self.on_battle_end:
                self.on_battle_end(False)
        elif not any(e.is_alive for e in self.enemies):
            self.phase = CombatPhase.VICTORY
            self.battle_log.append("战斗胜利！")
            if self.on_battle_end:
                self.on_battle_end(True)
                
        if self.on_action:
            self.on_action(action)
            
    def _next_turn(self) -> None:
        """下一回合"""
        if self.phase in (CombatPhase.VICTORY, CombatPhase.DEFEAT, CombatPhase.FLEE):
            return
            
        # 清除防御状态
        current = self.get_current_combatant()
        if current:
            current.is_defending = False
            
        # 下一个行动者
        self.current_turn_index += 1
        if self.current_turn_index >= len(self.turn_order):
            self.current_turn_index = 0
            self.turn_count += 1
            # 重新计算行动顺序
            self.turn_order = sorted([c for c in self.all_combatants if c.is_alive],
                                    key=lambda c: c.speed, reverse=True)
            
        # 跳过已死亡的单位
        while self.current_turn_index < len(self.turn_order):
            if self.turn_order[self.current_turn_index].is_alive:
                break
            self.current_turn_index += 1
            
        # 设置阶段
        next_combatant = self.get_current_combatant()
        if next_combatant:
            self.phase = CombatPhase.PLAYER_TURN if next_combatant.is_player else CombatPhase.ENEMY_TURN
            
    def get_battle_rewards(self) -> Dict:
        """获取战斗奖励"""
        if self.phase != CombatPhase.VICTORY:
            return {}
            
        # 计算经验值和金钱
        total_exp = sum(e.max_hp // 2 + e.attack for e in self.enemies)
        total_gold = sum(random.randint(10, 50) for _ in self.enemies)
        
        # 掉落物品
        drops = []
        for enemy in self.enemies:
            if random.random() < 0.3:
                drops.append(random.choice(["金创药", "小还丹", "止血草"]))
                
        return {
            "exp": total_exp,
            "gold": total_gold,
            "items": drops,
        }


class EncounterSystem:
    """遇敌系统 - 大地图半即时探索"""
    
    def __init__(self, base_encounter_rate: float = 0.02):
        self.base_rate = base_encounter_rate
        self.last_encounter_time = 0.0
        self.min_interval = 3.0  # 最小遇敌间隔
        
    def check_encounter(self, zone_type: str, delta_time: float,
                       player_level: int = 1) -> Optional[List[Dict]]:
        """检查是否遇敌"""
        # 区域类型影响遇敌率
        zone_multipliers = {
            "wilderness": 1.5,
            "city": 0.3,
            "town": 0.5,
            "sect": 0.8,
        }
        multiplier = zone_multipliers.get(zone_type, 1.0)
        
        # 遇敌判定
        encounter_chance = self.base_rate * multiplier * delta_time * 60
        
        if random.random() < encounter_chance:
            return self._generate_enemies(zone_type, player_level)
        return None
        
    def _generate_enemies(self, zone_type: str, player_level: int) -> List[Dict]:
        """生成敌人"""
        # 敌人模板
        enemy_templates = {
            "wilderness": [
                {"name": "山贼", "hp": 80, "mp": 20, "atk": 15, "def": 8, "spd": 10},
                {"name": "野狼", "hp": 50, "mp": 0, "atk": 12, "def": 5, "spd": 15},
                {"name": "流寇", "hp": 100, "mp": 30, "atk": 18, "def": 10, "spd": 12},
            ],
            "city": [
                {"name": "恶霸", "hp": 60, "mp": 10, "atk": 10, "def": 6, "spd": 8},
            ],
            "town": [
                {"name": "小贼", "hp": 40, "mp": 5, "atk": 8, "def": 4, "spd": 12},
            ],
            "sect": [
                {"name": "叛徒", "hp": 120, "mp": 40, "atk": 20, "def": 12, "spd": 14},
                {"name": "仇家", "hp": 150, "mp": 50, "atk": 25, "def": 15, "spd": 16},
            ],
        }
        
        templates = enemy_templates.get(zone_type, enemy_templates["wilderness"])
        
        # 根据等级调整敌人数量和强度
        num_enemies = random.randint(1, min(3, 1 + player_level // 5))
        enemies = []
        
        for _ in range(num_enemies):
            template = random.choice(templates)
            level_scale = 1.0 + (player_level - 1) * 0.1
            enemy = {
                "name": template["name"],
                "max_hp": int(template["hp"] * level_scale),
                "hp": int(template["hp"] * level_scale),
                "max_mp": int(template["mp"] * level_scale),
                "mp": int(template["mp"] * level_scale),
                "attack": int(template["atk"] * level_scale),
                "defense": int(template["def"] * level_scale),
                "speed": template["spd"],
                "is_player": False,
                "skills": [],
            }
            enemies.append(enemy)
            
        return enemies
