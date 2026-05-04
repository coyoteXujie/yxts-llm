import random
from typing import Dict, List, Optional
from .entities import Player, NPC, Faction, FACTION_NAMES
from .llm_client import get_llm_client
from .npc_brain import get_behavior_tracker
from .event import EventType, dispatch


ENCOUNTER_RARITY_COLORS = {
    "common": (200, 200, 200),
    "rare": (100, 200, 255),
    "epic": (200, 100, 255),
    "legendary": (255, 200, 50),
}

ENCOUNTER_RARITY_NAMES = {
    "common": "普通",
    "rare": "稀有",
    "epic": "史诗",
    "legendary": "传说",
}

TRIGGER_CONDITIONS = {
    "high_morality": {"min_daode": 50, "description": "侠义昭彰"},
    "low_morality": {"max_daode": -30, "description": "魔性觉醒"},
    "kill_streak": {"min_streak": 5, "description": "杀气冲天"},
    "many_quests": {"min_quests": 10, "description": "名声远扬"},
    "many_dialogues": {"min_dialogues": 20, "description": "人脉广阔"},
    "high_level": {"min_level": 20, "description": "实力超群"},
    "faction_ally": {"description": "门派恩泽"},
    "exploration": {"description": "奇遇探索"},
}


class Encounter:
    def __init__(self, title: str, description: str, encounter_type: str,
                 reward: Dict, rarity: str = "common", trigger_npc: str = "",
                 trigger_reason: str = ""):
        self.title = title
        self.description = description
        self.encounter_type = encounter_type
        self.reward = reward
        self.rarity = rarity
        self.trigger_npc = trigger_npc
        self.trigger_reason = trigger_reason
        self.accepted = False

    def get_rarity_color(self):
        return ENCOUNTER_RARITY_COLORS.get(self.rarity, (200, 200, 200))

    def get_rarity_name(self):
        return ENCOUNTER_RARITY_NAMES.get(self.rarity, "普通")

    def get_display_text(self) -> str:
        rarity_name = self.get_rarity_name()
        text = f"【{rarity_name}奇遇】{self.title}\n\n{self.description}\n\n"
        reward_parts = []
        if "exp" in self.reward:
            reward_parts.append(f"经验+{self.reward['exp']}")
        if "pot" in self.reward:
            reward_parts.append(f"潜能+{self.reward['pot']}")
        if "money" in self.reward:
            reward_parts.append(f"银两+{self.reward['money']}")
        if "daode" in self.reward:
            val = self.reward['daode']
            reward_parts.append(f"道德{'+' if val >= 0 else ''}{val}")
        if "item" in self.reward:
            reward_parts.append(f"获得物品")
        if "skill_exp" in self.reward:
            reward_parts.append(f"武功精进+{self.reward['skill_exp']}")
        if "hp" in self.reward:
            reward_parts.append(f"生命+{self.reward['hp']}")
        if "mp" in self.reward:
            reward_parts.append(f"内力+{self.reward['mp']}")
        if reward_parts:
            text += "奖励：" + " | ".join(reward_parts)
        return text


class EncounterManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._history: List[Encounter] = []
            cls._instance._cooldown: float = 0.0
            cls._instance._min_interval: float = 300.0
            cls._instance._pending: Optional[Encounter] = None
        return cls._instance

    def check_encounter(self, player: Player, npc: NPC = None, game_time: float = 0.0) -> Optional[Encounter]:
        if self._pending:
            return self._pending

        if game_time - self._cooldown < self._min_interval:
            return None

        tracker = get_behavior_tracker()
        if not tracker.should_trigger_encounter(player.name):
            return None

        trigger_reason = self._determine_trigger(player, npc)
        if not trigger_reason:
            return None

        encounter = self._generate_encounter(player, npc, trigger_reason)
        if encounter:
            self._pending = encounter
            self._cooldown = game_time
            return encounter

        return None

    def _determine_trigger(self, player: Player, npc: NPC = None) -> str:
        tracker = get_behavior_tracker()
        behavior = tracker.get_behavior_summary(player.name)
        reasons = []

        if player.daode >= 50:
            reasons.append(("high_morality", f"侠义之名远播"))
        if player.daode <= -30:
            reasons.append(("low_morality", f"魔性渐生"))
        if behavior.get("consecutive_kills", 0) >= 5:
            reasons.append(("kill_streak", f"连斩{behavior['consecutive_kills']}敌"))
        if behavior.get("quests_completed", 0) >= 10:
            reasons.append(("many_quests", f"完成{behavior['quests_completed']}个任务"))
        if behavior.get("unique_npcs_talked", 0) >= 15:
            reasons.append(("many_dialogues", f"结交{behavior['unique_npcs_talked']}位江湖人士"))
        if player.level >= 20:
            reasons.append(("high_level", f"等级达到{player.level}"))
        if npc and npc.faction != Faction.NONE and player.faction != Faction.NONE:
            if npc.faction == player.faction:
                reasons.append(("faction_ally", f"同门{FACTION_NAMES[npc.faction.value]}"))

        if not reasons:
            if random.random() < 0.1:
                reasons.append(("exploration", "机缘巧合"))
            else:
                return ""

        if npc:
            priority = []
            for r in reasons:
                if r[0] in ("faction_ally", "high_morality", "kill_streak"):
                    priority.append(r)
            if priority:
                chosen = random.choice(priority)
            else:
                chosen = random.choice(reasons)
        else:
            chosen = random.choice(reasons)

        return chosen[1]

    def _generate_encounter(self, player: Player, npc: NPC = None, trigger_reason: str = "") -> Optional[Encounter]:
        llm = get_llm_client()
        tracker = get_behavior_tracker()

        player_info = {
            "name": player.name,
            "level": player.level,
            "faction_name": FACTION_NAMES[player.faction.value],
            "daode": player.daode,
        }

        npc_info = None
        if npc:
            npc_info = npc.get_info_dict()

        behavior = tracker.get_behavior_summary(player.name)

        result = llm.generate_encounter(
            player_info=player_info,
            npc_info=npc_info,
            trigger_reason=trigger_reason,
            player_behavior=behavior,
        )

        if not result:
            return None

        encounter = Encounter(
            title=result.get("title", "奇遇"),
            description=result.get("description", "你遇到了一件不寻常的事。"),
            encounter_type=result.get("type", "stat_boost"),
            reward=result.get("reward", {}),
            rarity=result.get("rarity", "common"),
            trigger_npc=npc.name if npc else "",
            trigger_reason=trigger_reason,
        )

        return encounter

    def accept_encounter(self, player: Player, encounter: Encounter) -> str:
        encounter.accepted = True
        self._history.append(encounter)
        self._pending = None

        reward_text = self._apply_reward(player, encounter)

        dispatch(EventType.ENCOUNTER_TRIGGERED, {
            "title": encounter.title,
            "type": encounter.encounter_type,
            "rarity": encounter.rarity,
            "reward": encounter.reward,
        })

        return reward_text

    def decline_encounter(self, encounter: Encounter) -> None:
        self._pending = None

    def _apply_reward(self, player: Player, encounter: Encounter) -> str:
        reward = encounter.reward
        result_parts = [f"【{encounter.title}】"]

        if "exp" in reward:
            amount = reward["exp"]
            level_up = player.add_exp(amount)
            result_parts.append(f"获得经验 {amount}")
            if level_up:
                result_parts.append(f"升级到第{player.level}级！")

        if "pot" in reward:
            player.pot += reward["pot"]
            result_parts.append(f"获得潜能 {reward['pot']}")

        if "money" in reward:
            player.add_money(reward["money"])
            result_parts.append(f"获得银两 {reward['money']}")

        if "daode" in reward:
            player.daode += reward["daode"]
            result_parts.append(f"道德{'+' if reward['daode'] >= 0 else ''}{reward['daode']}")

        if "hp" in reward:
            healed = player.heal(reward["hp"])
            result_parts.append(f"恢复生命 {healed}")

        if "mp" in reward:
            restored = player.restore_mp(reward["mp"])
            result_parts.append(f"恢复内力 {restored}")

        if "item" in reward:
            item_id = reward["item"]
            player.add_item(item_id)
            result_parts.append(f"获得物品")

        if "skill_exp" in reward:
            if player.skills:
                for skill in player.skills[:3]:
                    leveled = skill.add_exp(reward["skill_exp"] // len(player.skills[:3]))
                    if leveled:
                        result_parts.append(f"{skill.name}提升到{skill.level}级！")
            result_parts.append(f"武功精进")

        return "\n".join(result_parts)

    def get_pending(self) -> Optional[Encounter]:
        return self._pending

    def get_history(self) -> List[Encounter]:
        return self._history

    def get_encounter_count(self) -> int:
        return len(self._history)


def get_encounter_manager() -> EncounterManager:
    return EncounterManager()
