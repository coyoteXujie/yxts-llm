import random
from typing import Dict, List, Optional, Tuple
from ..entities import Player, Skill, Faction, FACTION_NAMES
from ..event import EventType, add_listener, dispatch


SKILL_MASTERY_TIERS = {
    (1, 19): "初学",
    (20, 49): "小成",
    (50, 79): "大成",
    (80, 99): "圆满",
    (100, 999): "化境",
}

SKILL_MASTERY_COLORS = {
    "初学": (180, 180, 180),
    "小成": (100, 200, 100),
    "大成": (80, 160, 255),
    "圆满": (200, 100, 255),
    "化境": (255, 215, 0),
}

BREAKTHROUGH_BASE_CHANCE = 0.3
BREAKTHROUGH_SKILL_BONUS = 0.005
BREAKTHROUGH_POT_COST = 10

BREAKTHROUGH_EFFECTS = {
    3: {
        "小成": {"mp_bonus": 20, "desc": "内功小成，内力上限+20"},
        "大成": {"mp_bonus": 50, "mp_regen_bonus": 1.0, "desc": "内功大成，内力上限+50，内力恢复+1"},
        "圆满": {"mp_bonus": 100, "mp_regen_bonus": 2.0, "desc": "内功圆满，内力上限+100，内力恢复+2"},
        "化境": {"mp_bonus": 200, "mp_regen_bonus": 3.0, "desc": "内功化境，内力上限+200，内力恢复+3"},
    },
    4: {
        "小成": {"dodge_bonus": 5, "desc": "轻功小成，闪避+5%"},
        "大成": {"dodge_bonus": 12, "speed_bonus": 10, "desc": "轻功大成，闪避+12%，移动速度+10"},
        "圆满": {"dodge_bonus": 20, "speed_bonus": 20, "desc": "轻功圆满，闪避+20%，移动速度+20"},
        "化境": {"dodge_bonus": 30, "speed_bonus": 30, "desc": "轻功化境，闪避+30%，移动速度+30"},
    },
    5: {
        "小成": {"parry_bonus": 5, "desc": "招架小成，格挡+5%"},
        "大成": {"parry_bonus": 12, "defense_bonus": 5, "desc": "招架大成，格挡+12%，防御+5"},
        "圆满": {"parry_bonus": 20, "defense_bonus": 10, "desc": "招架圆满，格挡+20%，防御+10"},
        "化境": {"parry_bonus": 30, "defense_bonus": 20, "desc": "招架化境，格挡+30%，防御+20"},
    },
}

TRAINING_EXP_BASE = 20
TRAINING_EXP_MASTERY_BONUS = {
    "初学": 1.0,
    "小成": 0.8,
    "大成": 0.6,
    "圆满": 0.4,
    "化境": 0.2,
}

INNER_FORCE_REGEN_RATES = {
    1: 0.5,
    20: 1.0,
    50: 2.0,
    80: 3.5,
    100: 5.0,
}

CULTIVATION_MEDITATION_EXP = 5
CULTIVATION_MEDITATION_MP_COST = 10
CULTIVATION_MEDITATION_INTERVAL = 2.0


def get_mastery_tier(level: int) -> str:
    for (lo, hi), name in SKILL_MASTERY_TIERS.items():
        if lo <= level <= hi:
            return name
    return "化境"


def get_mastery_color(tier: str) -> tuple:
    return SKILL_MASTERY_COLORS.get(tier, (180, 180, 180))


class CultivationSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._meditation_timer: float = 0.0
        return cls._instance

    def get_skill_exp_for_next_level(self, skill: Skill) -> int:
        tier = get_mastery_tier(skill.level)
        multiplier = {
            "初学": 1.0,
            "小成": 1.5,
            "大成": 2.5,
            "圆满": 4.0,
            "化境": 6.0,
        }.get(tier, 1.0)
        return int(skill.level * 100 * multiplier)

    def add_skill_exp(self, player: Player, skill_id: str, amount: int) -> Optional[Dict]:
        skill = next((s for s in player.skills if s.id == skill_id), None)
        if not skill:
            return None

        old_tier = get_mastery_tier(skill.level)
        old_level = skill.level

        skill.exp += amount
        needed = self.get_skill_exp_for_next_level(skill)

        leveled = False
        while skill.exp >= needed:
            skill.exp -= needed
            skill.level += 1
            skill.damage += max(1, skill.level // 5)
            leveled = True
            needed = self.get_skill_exp_for_next_level(skill)

        new_tier = get_mastery_tier(skill.level)

        if leveled:
            dispatch(EventType.SKILL_LEVEL_UP, {
                "skill_id": skill.id,
                "skill_name": skill.name,
                "old_level": old_level,
                "new_level": skill.level,
                "mastery_tier": new_tier,
            })

        if new_tier != old_tier:
            dispatch(EventType.SKILL_MASTERY_CHANGED, {
                "skill_id": skill.id,
                "skill_name": skill.name,
                "old_tier": old_tier,
                "new_tier": new_tier,
                "level": skill.level,
            })

        return {
            "skill_name": skill.name,
            "exp_gained": amount,
            "leveled": leveled,
            "old_level": old_level,
            "new_level": skill.level,
            "old_tier": old_tier,
            "new_tier": new_tier,
        }

    def attempt_breakthrough(self, player: Player, skill_id: str, use_pot: int = 0) -> Dict:
        skill = next((s for s in player.skills if s.id == skill_id), None)
        if not skill:
            return {"success": False, "message": "没有这个技能"}

        tier = get_mastery_tier(skill.level)
        if tier == "化境":
            return {"success": False, "message": "已达化境，无法突破"}

        threshold_levels = {"初学": 20, "小成": 50, "大成": 80, "圆满": 100}
        threshold = threshold_levels.get(tier, 999)
        if skill.level < threshold:
            return {"success": False, "message": f"技能等级不足，需要达到{threshold}级"}

        chance = BREAKTHROUGH_BASE_CHANCE
        chance += skill.level * BREAKTHROUGH_SKILL_BONUS

        if use_pot > 0:
            if player.pot < use_pot:
                return {"success": False, "message": f"潜能不足，需要{use_pot}点"}
            player.pot -= use_pot
            chance += use_pot * 0.02

        chance = min(0.95, chance)

        if random.random() < chance:
            old_tier = tier
            bonus_exp = skill.level * 10
            skill.exp += bonus_exp
            new_tier = get_mastery_tier(skill.level)

            breakthrough_effect = self._apply_breakthrough_effect(player, skill, new_tier)
            effect_msg = ""
            if breakthrough_effect:
                effect_msg = f" {breakthrough_effect['desc']}"

            dispatch(EventType.SKILL_MASTERY_CHANGED, {
                "skill_id": skill.id,
                "skill_name": skill.name,
                "old_tier": old_tier,
                "new_tier": new_tier,
                "level": skill.level,
                "breakthrough": True,
            })
            return {
                "success": True,
                "message": f"突破成功！{skill.name}从{old_tier}突破至{new_tier}！{effect_msg}",
                "old_tier": old_tier,
                "new_tier": new_tier,
                "bonus_exp": bonus_exp,
                "breakthrough_effect": breakthrough_effect,
            }
        else:
            skill.exp = max(0, skill.exp - skill.level * 5)
            return {
                "success": False,
                "message": f"突破失败！{skill.name}修为略有损失。",
                "old_tier": tier,
            }

    def train_with_master(self, player: Player, skill_id: str, master_npc) -> Dict:
        skill = next((s for s in player.skills if s.id == skill_id), None)
        if not skill:
            return {"success": False, "message": "没有这个技能"}

        if not master_npc:
            return {"success": False, "message": "没有师父指导，无法修炼"}

        if skill_id not in master_npc.teach_skills:
            return {"success": False, "message": f"{master_npc.name}不传授这门武功"}

        tier = get_mastery_tier(skill.level)
        mastery_mult = TRAINING_EXP_MASTERY_BONUS.get(tier, 1.0)

        base_exp = TRAINING_EXP_BASE
        master_bonus = master_npc.level * 0.5
        exp_gain = int(base_exp * mastery_mult + master_bonus)

        cost = int(10 + skill.level * 2)
        if player.money < cost:
            return {"success": False, "message": f"银两不足，需要{cost}文"}

        player.money -= cost
        result = self.add_skill_exp(player, skill_id, exp_gain)

        return {
            "success": True,
            "message": f"向{master_npc.name}学习{skill.name}，获得{exp_gain}点经验（花费{cost}文）",
            "exp_gain": exp_gain,
            "cost": cost,
            "result": result,
        }

    def use_pot_for_skill(self, player: Player, skill_id: str, pot_amount: int) -> Dict:
        if player.pot < pot_amount:
            return {"success": False, "message": f"潜能不足，需要{pot_amount}点"}

        skill = next((s for s in player.skills if s.id == skill_id), None)
        if not skill:
            return {"success": False, "message": "没有这个技能"}

        exp_gain = pot_amount * 15
        player.pot -= pot_amount
        result = self.add_skill_exp(player, skill_id, exp_gain)

        return {
            "success": True,
            "message": f"消耗{pot_amount}点潜能，{skill.name}获得{exp_gain}点经验",
            "exp_gain": exp_gain,
            "result": result,
        }

    def _apply_breakthrough_effect(self, player: Player, skill: Skill, new_tier: str) -> Optional[Dict]:
        type_effects = BREAKTHROUGH_EFFECTS.get(skill.type)
        if not type_effects:
            return None
        effect = type_effects.get(new_tier)
        if not effect:
            return None

        result = {"desc": effect.get("desc", "")}

        if "mp_bonus" in effect:
            player.max_mp += effect["mp_bonus"]
            player.mp += effect["mp_bonus"]
            result["mp_bonus"] = effect["mp_bonus"]

        if "mp_regen_bonus" in effect:
            result["mp_regen_bonus"] = effect["mp_regen_bonus"]

        if "dodge_bonus" in effect:
            result["dodge_bonus"] = effect["dodge_bonus"]

        if "speed_bonus" in effect:
            result["speed_bonus"] = effect["speed_bonus"]

        if "parry_bonus" in effect:
            result["parry_bonus"] = effect["parry_bonus"]

        if "defense_bonus" in effect:
            player.defense += effect["defense_bonus"]
            result["defense_bonus"] = effect["defense_bonus"]

        return result

    def get_inner_force_regen(self, player: Player) -> float:
        force_skill = next((s for s in player.skills if s.type == 3), None)
        if not force_skill:
            return 0.5

        level = force_skill.level
        regen = 0.5
        for threshold, rate in sorted(INNER_FORCE_REGEN_RATES.items()):
            if level >= threshold:
                regen = rate
        return regen

    def update_meditation(self, player: Player, delta_time: float) -> Optional[Dict]:
        self._meditation_timer += delta_time
        if self._meditation_timer < CULTIVATION_MEDITATION_INTERVAL:
            return None
        self._meditation_timer = 0.0

        if player.mp < CULTIVATION_MEDITATION_MP_COST:
            return None

        force_skill = next((s for s in player.skills if s.type == 3), None)
        if not force_skill:
            return None

        player.mp -= CULTIVATION_MEDITATION_MP_COST
        result = self.add_skill_exp(player, force_skill.id, CULTIVATION_MEDITATION_EXP)

        return result

    def get_player_cultivation_info(self, player: Player) -> Dict:
        skills_info = []
        for skill in player.skills:
            tier = get_mastery_tier(skill.level)
            needed = self.get_skill_exp_for_next_level(skill)
            skills_info.append({
                "id": skill.id,
                "name": skill.name,
                "level": skill.level,
                "exp": skill.exp,
                "exp_needed": needed,
                "mastery_tier": tier,
                "mastery_color": get_mastery_color(tier),
                "type": skill.type,
            })

        force_skill = next((s for s in player.skills if s.type == 3), None)
        inner_regen = self.get_inner_force_regen(player)

        return {
            "skills": skills_info,
            "inner_force_regen": inner_regen,
            "potential": player.pot,
            "total_skill_levels": sum(s.level for s in player.skills),
        }


def get_cultivation_system() -> CultivationSystem:
    return CultivationSystem()
