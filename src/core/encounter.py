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
                 trigger_reason: str = "", choices: List[Dict] = None,
                 trigger_area: str = ""):
        self.title = title
        self.description = description
        self.encounter_type = encounter_type
        self.reward = reward
        self.rarity = rarity
        self.trigger_npc = trigger_npc
        self.trigger_reason = trigger_reason
        self.accepted = False
        self.choices = choices or []
        self.trigger_area = trigger_area

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

    def check_area_encounter(self, player: Player, area_name: str, game_time: float = 0.0) -> Optional[Encounter]:
        if self._pending:
            return self._pending
        if game_time - self._cooldown < self._min_interval:
            return None

        area_encounter = self._generate_area_encounter(player, area_name)
        if area_encounter:
            self._pending = area_encounter
            self._cooldown = game_time
            return area_encounter
        return None

    def _generate_area_encounter(self, player: Player, area_name: str) -> Optional[Encounter]:
        area_encounters = self._get_area_encounter_pool(area_name, player)
        if not area_encounters:
            return None
        weights = []
        for e in area_encounters:
            rarity_weight = {"common": 10, "rare": 3, "epic": 1, "legendary": 0.2}
            weights.append(rarity_weight.get(e.rarity, 1))
        import random
        chosen = random.choices(area_encounters, weights=weights, k=1)[0]
        return chosen

    def _get_area_encounter_pool(self, area_name: str, player: Player) -> List[Encounter]:
        pool = []
        if "雪" in area_name or "山" in area_name:
            pool.append(Encounter(
                title="冰洞秘宝", description="你在雪山深处发现了一个隐蔽的冰洞，洞中似乎有微光闪烁...",
                encounter_type="choice", rarity="rare",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "进入冰洞探索", "reward": {"exp": 300, "pot": 30, "daode": 5}, "risk": 0.2},
                    {"text": "在洞口观察", "reward": {"exp": 100}, "risk": 0},
                    {"text": "离开，太危险了", "reward": {}, "risk": 0},
                ]
            ))
            pool.append(Encounter(
                title="雪中送炭", description="一个受伤的旅人倒在雪地中，奄奄一息...",
                encounter_type="choice", rarity="common",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "施以援手", "reward": {"exp": 150, "daode": 15, "money": 200}, "risk": 0},
                    {"text": "视而不见", "reward": {"daode": -10}, "risk": 0},
                ]
            ))
        if "镇" in area_name or "城" in area_name:
            pool.append(Encounter(
                title="街头比武", description="一群人围在一起，原来是有人在摆擂台比武！胜者有赏！",
                encounter_type="choice", rarity="common",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "上台比武", "reward": {"exp": 200, "money": 300}, "risk": 0.3},
                    {"text": "在旁观看", "reward": {"exp": 30}, "risk": 0},
                ]
            ))
            pool.append(Encounter(
                title="神秘商人", description="一个蒙面商人向你招手：'少侠，要不要看看好东西？'",
                encounter_type="choice", rarity="rare",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "看看他的商品", "reward": {"money": -200, "item": "item_dan"}, "risk": 0.1},
                    {"text": "婉言谢绝", "reward": {}, "risk": 0},
                ]
            ))
        if "林" in area_name or "谷" in area_name:
            pool.append(Encounter(
                title="古墓奇缘", description="密林深处，你发现了一座被藤蔓覆盖的古墓...",
                encounter_type="choice", rarity="epic",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "推开石门进入", "reward": {"exp": 500, "pot": 80, "skill_exp": 100}, "risk": 0.4},
                    {"text": "在墓外搜索", "reward": {"exp": 100, "money": 100}, "risk": 0.1},
                    {"text": "标记后离开", "reward": {}, "risk": 0},
                ]
            ))
        if "河" in area_name or "湖" in area_name or "水" in area_name:
            pool.append(Encounter(
                title="河中浮尸", description="河面上漂来一具'尸体'，走近一看，人还在动！",
                encounter_type="choice", rarity="rare",
                reward={}, trigger_area=area_name,
                choices=[
                    {"text": "跳入水中救人", "reward": {"exp": 200, "daode": 20, "item": "item_baodian"}, "risk": 0.15},
                    {"text": "在岸边拉他上来", "reward": {"exp": 100, "daode": 10}, "risk": 0},
                ]
            ))
        pool.append(Encounter(
            title="路遇高人", description="一位白发老者拦住你的去路：'年轻人，我看你骨骼惊奇...'",
            encounter_type="choice", rarity="epic",
            reward={}, trigger_area=area_name,
            choices=[
                {"text": "虚心请教", "reward": {"exp": 400, "pot": 50}, "risk": 0},
                {"text": "警惕后退", "reward": {}, "risk": 0},
                {"text": "这是骗子吧？", "reward": {"daode": -5}, "risk": 0},
            ]
        ))
        return pool

    def accept_encounter_choice(self, player: Player, encounter: Encounter, choice_index: int) -> str:
        if choice_index < 0 or choice_index >= len(encounter.choices):
            return "无效选择"

        choice = encounter.choices[choice_index]
        import random

        risk = choice.get("risk", 0)
        if risk > 0 and random.random() < risk:
            damage = int(player.max_hp * risk * 0.5)
            player.hp = max(1, player.hp - damage)
            encounter.accepted = True
            self._history.append(encounter)
            self._pending = None
            return f"你遭遇了危险！损失了{damage}点生命值！"

        reward = choice.get("reward", {})
        encounter.reward = reward
        encounter.accepted = True
        self._history.append(encounter)
        self._pending = None

        reward_text = self._apply_reward(player, encounter)

        dispatch(EventType.ENCOUNTER_TRIGGERED, {
            "title": encounter.title,
            "type": encounter.encounter_type,
            "rarity": encounter.rarity,
            "reward": reward,
            "choice": choice.get("text", ""),
        })

        return reward_text

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
                reasons.append(("faction_ally", f"同门{FACTION_NAMES.get(npc.faction, '未知门派')}"))

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
            "faction_name": FACTION_NAMES.get(player.faction, '未知门派'),
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
