import random
from typing import Dict, List, Optional
from ..entities import Player, Faction
from ..event import EventType, dispatch


PERFORM_COOLDOWNS: Dict[str, float] = {}

PERFORM_MP_COST_BASE = 15
PERFORM_MP_COST_PER_LEVEL = 0.5

PERFORM_HIT_BONUS = 0.1
PERFORM_CRIT_CHANCE = 0.15
PERFORM_CRIT_MULTIPLIER = 1.5


class PerformSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._cooldowns: Dict[str, float] = {}
            cls._instance._global_cooldown: float = 0.0
        return cls._instance

    def update_cooldowns(self, delta_time: float):
        expired = []
        for key, remaining in self._cooldowns.items():
            self._cooldowns[key] = remaining - delta_time
            if self._cooldowns[key] <= 0:
                expired.append(key)
        for key in expired:
            del self._cooldowns[key]
        self._global_cooldown = max(0, self._global_cooldown - delta_time)

    def get_available_performs(self, player: Player, performs_db: Dict) -> List[Dict]:
        available = []
        for pf_id, pf in performs_db.items():
            faction_req = pf.get("faction", Faction.NONE)
            if faction_req != Faction.NONE and player.faction != faction_req:
                continue

            skill_id = pf.get("skill", "")
            skill = next((s for s in player.skills if s.id == skill_id), None)
            if not skill:
                continue

            level_req = pf.get("lvl", 999)
            if skill.level < level_req:
                continue

            cooldown_key = f"{player.name}_{pf_id}"
            if cooldown_key in self._cooldowns:
                continue

            mp_cost = self._calculate_mp_cost(pf)
            available.append({
                "id": pf_id,
                "name": pf["name"],
                "damage": pf["damage"],
                "desc": pf["desc"],
                "skill": skill_id,
                "skill_name": skill.name,
                "mp_cost": mp_cost,
                "level_req": level_req,
                "faction": faction_req,
            })
        return available

    def use_perform(self, player: Player, perform_id: str, performs_db: Dict,
                    enemy_defense: int = 0) -> Dict:
        pf = performs_db.get(perform_id)
        if not pf:
            return {"success": False, "message": "没有这个绝招"}

        faction_req = pf.get("faction", Faction.NONE)
        if faction_req != Faction.NONE and player.faction != faction_req:
            return {"success": False, "message": "你不是本门弟子，无法使用此绝招"}

        skill_id = pf.get("skill", "")
        skill = next((s for s in player.skills if s.id == skill_id), None)
        if not skill:
            return {"success": False, "message": "你还没有学会相关技能"}

        level_req = pf.get("lvl", 999)
        if skill.level < level_req:
            return {"success": False, "message": f"技能等级不足，需要{skill.name}达到{level_req}级"}

        cooldown_key = f"{player.name}_{perform_id}"
        if cooldown_key in self._cooldowns:
            remaining = self._cooldowns[cooldown_key]
            return {"success": False, "message": f"绝招冷却中，还需{remaining:.1f}秒"}

        if self._global_cooldown > 0:
            return {"success": False, "message": f"全局冷却中，还需{self._global_cooldown:.1f}秒"}

        mp_cost = self._calculate_mp_cost(pf)
        if player.mp < mp_cost:
            return {"success": False, "message": f"内力不足，需要{mp_cost}点内力"}

        player.mp -= mp_cost

        base_damage = pf["damage"]
        skill_bonus = skill.level * 0.3
        attack_bonus = player.attack * 0.2

        total_damage = base_damage + skill_bonus + attack_bonus

        hit_chance = 0.85 + PERFORM_HIT_BONUS
        if random.random() > hit_chance:
            self._set_cooldown(cooldown_key, 3.0)
            self._global_cooldown = 1.5
            return {
                "success": True,
                "message": f"你使出【{pf['name']}】，但被对手躲开了！",
                "damage": 0,
                "missed": True,
                "mp_cost": mp_cost,
            }

        is_crit = random.random() < PERFORM_CRIT_CHANCE
        if is_crit:
            total_damage = int(total_damage * PERFORM_CRIT_MULTIPLIER)

        defense_reduction = enemy_defense * 0.3
        final_damage = max(1, int(total_damage - defense_reduction))
        variance = random.uniform(0.9, 1.1)
        final_damage = int(final_damage * variance)

        cooldown_duration = 8.0 + pf["damage"] * 0.1
        self._set_cooldown(cooldown_key, cooldown_duration)
        self._global_cooldown = 2.0

        crit_text = "暴击！" if is_crit else ""
        dispatch(EventType.PERFORM_USED, {
            "perform_id": perform_id,
            "perform_name": pf["name"],
            "damage": final_damage,
            "is_crit": is_crit,
            "mp_cost": mp_cost,
        })

        return {
            "success": True,
            "message": f"你使出【{pf['name']}】！{crit_text}造成{final_damage}点伤害！",
            "damage": final_damage,
            "is_crit": is_crit,
            "mp_cost": mp_cost,
            "perform_name": pf["name"],
        }

    def _calculate_mp_cost(self, perform: Dict) -> int:
        base = PERFORM_MP_COST_BASE
        level_cost = perform.get("damage", 20) * PERFORM_MP_COST_PER_LEVEL
        return int(base + level_cost)

    def _set_cooldown(self, key: str, duration: float):
        self._cooldowns[key] = duration

    def get_cooldown_info(self, player: Player, performs_db: Dict) -> List[Dict]:
        info = []
        for pf_id, pf in performs_db.items():
            cooldown_key = f"{player.name}_{pf_id}"
            remaining = self._cooldowns.get(cooldown_key, 0)
            if remaining > 0:
                info.append({
                    "id": pf_id,
                    "name": pf["name"],
                    "remaining": remaining,
                })
        return info


def get_perform_system() -> PerformSystem:
    return PerformSystem()
