import random
from typing import Dict, List, Optional
from .entities import NPC, Player, Faction, FACTION_NAMES, NpcType
from .llm_client import get_llm_client, FACTION_RELATIONS


class DialogueState:
    GREETING = "greeting"
    CHATTING = "chatting"
    TASK_OFFER = "task_offer"
    TASK_DETAIL = "task_detail"
    TEACH_OFFER = "teach_offer"
    TRADE = "trade"
    FAREWELL = "farewell"


class PlayerBehaviorTracker:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._data: Dict[str, Dict] = {}
        return cls._instance

    def get_behavior(self, player_name: str) -> Dict:
        if player_name not in self._data:
            self._data[player_name] = {
                "total_kills": 0,
                "quests_completed": 0,
                "good_deeds": 0,
                "bad_deeds": 0,
                "consecutive_kills": 0,
                "npc_interactions": {},
                "recent_activity": "",
                "total_dialogues": 0,
                "unique_npcs_talked": 0,
                "factions_helped": set(),
                "factions_harmed": set(),
                "highest_kill_streak": 0,
                "items_collected": 0,
                "distance_traveled": 0.0,
            }
        return self._data[player_name]

    def record_kill(self, player_name: str, npc: NPC) -> None:
        b = self.get_behavior(player_name)
        b["total_kills"] += 1
        b["consecutive_kills"] += 1
        b["highest_kill_streak"] = max(b["highest_kill_streak"], b["consecutive_kills"])
        b["recent_activity"] = f"击杀了{npc.name}"
        if npc.npc_type == NpcType.ENEMY:
            b["good_deeds"] += 1
        else:
            b["bad_deeds"] += 1
        if npc.faction != Faction.NONE:
            faction_name = FACTION_NAMES[npc.faction.value]
            if npc.npc_type == NpcType.ENEMY:
                b["factions_helped"].add(faction_name)
            else:
                b["factions_harmed"].add(faction_name)

    def record_quest_complete(self, player_name: str, quest_type: str, npc_faction: Faction) -> None:
        b = self.get_behavior(player_name)
        b["quests_completed"] += 1
        b["consecutive_kills"] = 0
        b["recent_activity"] = f"完成了{quest_type}类任务"
        if quest_type in ("kill", "guard"):
            b["good_deeds"] += 1
        if npc_faction != Faction.NONE:
            b["factions_helped"].add(FACTION_NAMES[npc_faction.value])

    def record_dialogue(self, player_name: str, npc_name: str, npc_faction: Faction) -> None:
        b = self.get_behavior(player_name)
        b["total_dialogues"] += 1
        if npc_name not in b["npc_interactions"]:
            b["npc_interactions"][npc_name] = 0
            b["unique_npcs_talked"] += 1
        b["npc_interactions"][npc_name] += 1
        b["consecutive_kills"] = 0
        b["recent_activity"] = f"与{npc_name}交谈"

    def record_item_collect(self, player_name: str, item_name: str) -> None:
        b = self.get_behavior(player_name)
        b["items_collected"] += 1
        b["recent_activity"] = f"获得了{item_name}"

    def get_encounter_score(self, player_name: str) -> float:
        b = self.get_behavior(player_name)
        score = 0.0
        score += b["total_kills"] * 0.5
        score += b["quests_completed"] * 2.0
        score += b["good_deeds"] * 1.5
        score += b["unique_npcs_talked"] * 0.8
        score += b["highest_kill_streak"] * 1.0
        score += len(b["factions_helped"]) * 3.0
        score -= b["bad_deeds"] * 0.5
        return score

    def should_trigger_encounter(self, player_name: str) -> bool:
        score = self.get_encounter_score(player_name)
        b = self.get_behavior(player_name)
        base_chance = min(0.15, score * 0.002)
        if b["good_deeds"] > 10:
            base_chance += 0.05
        if b["highest_kill_streak"] >= 5:
            base_chance += 0.03
        if b["unique_npcs_talked"] >= 10:
            base_chance += 0.02
        return random.random() < base_chance

    def get_behavior_summary(self, player_name: str) -> Dict:
        b = self.get_behavior(player_name)
        return {
            "total_kills": b["total_kills"],
            "quests_completed": b["quests_completed"],
            "good_deeds": b["good_deeds"],
            "bad_deeds": b["bad_deeds"],
            "consecutive_kills": b["consecutive_kills"],
            "recent_activity": b["recent_activity"],
            "unique_npcs_talked": b["unique_npcs_talked"],
            "highest_kill_streak": b["highest_kill_streak"],
            "items_collected": b["items_collected"],
        }


class NPCBrain:
    MAX_HISTORY = 10

    def __init__(self, npc: NPC):
        self.npc = npc
        self.dialogue_history: List[Dict] = []
        self.state = DialogueState.GREETING
        self.relationship: Dict[str, int] = {}
        self.player_input_buffer: str = ""
        self._pending_task: Optional[Dict] = None
        self._greeted_players: set = set()

    def get_npc_info(self) -> Dict:
        return self.npc.get_info_dict()

    def get_player_info(self, player: Player, game_hour: int = 12) -> Dict:
        return {
            "name": player.name,
            "level": player.level,
            "faction": player.faction.value,
            "faction_name": FACTION_NAMES[player.faction.value],
            "daode": player.daode,
            "strength": player.strength,
            "dexterity": player.dexterity,
            "intelligence": player.intelligence,
            "constitution": player.constitution,
            "hour": game_hour,
        }

    def _add_to_history(self, role: str, content: str) -> None:
        self.dialogue_history.append({"role": role, "content": content})
        if len(self.dialogue_history) > self.MAX_HISTORY:
            self.dialogue_history = self.dialogue_history[-self.MAX_HISTORY:]

    def _get_relationship_modifier(self, player: Player) -> str:
        player_name = player.name
        rel = self.relationship.get(player_name, 0)
        if rel >= 20:
            return "非常友好"
        elif rel >= 10:
            return "友好"
        elif rel >= 0:
            return "中立"
        elif rel >= -10:
            return "冷淡"
        else:
            return "敌视"

    def _get_faction_attitude(self, player: Player) -> str:
        if self.npc.faction == Faction.NONE or player.faction == Faction.NONE:
            return "neutral"
        npc_faction_key = None
        for f in FACTION_RELATIONS:
            if self.npc.faction.name == f:
                npc_faction_key = f
                break
        if not npc_faction_key:
            return "neutral"
        rels = FACTION_RELATIONS[npc_faction_key]
        player_faction_name = player.faction.name
        if player_faction_name in rels["allies"]:
            return "friendly"
        if player_faction_name in rels["enemies"]:
            return "hostile"
        return "neutral"

    def talk(self, player: Player, player_input: str = "", game_hour: int = 12) -> Dict:
        llm = get_llm_client()
        npc_info = self.get_npc_info()
        player_info = self.get_player_info(player, game_hour)

        faction_attitude = self._get_faction_attitude(player)
        relationship = self._get_relationship_modifier(player)

        context = [
            f"与玩家关系：{relationship}",
            f"门派态度：{faction_attitude}",
        ]

        if player.name not in self._greeted_players:
            self._greeted_players.add(player.name)
            self.state = DialogueState.GREETING
            player_input = ""

        if player_input:
            self._add_to_history("player", player_input)
            self.state = self._determine_next_state(player_input)

        response_text = llm.generate_dialogue(
            npc_info=npc_info,
            player_info=player_info,
            player_input=player_input,
            context=context,
            dialogue_history=self.dialogue_history,
        )

        self._add_to_history("npc", response_text)

        self.relationship[player.name] = self.relationship.get(player.name, 0) + 1

        result = {
            "text": response_text,
            "state": self.state,
            "npc_name": self.npc.name,
            "can_quest": self.npc.has_quests,
            "can_teach": self.npc.is_master and bool(self.npc.teach_skills),
            "can_trade": self.npc.npc_type == NpcType.TRADER and bool(self.npc.sell_items),
            "faction_attitude": faction_attitude,
        }

        if self.state == DialogueState.TASK_OFFER and self.npc.has_quests:
            result["quest_hint"] = self._generate_quest_hint(player)

        if self.state == DialogueState.TEACH_OFFER and self.npc.is_master:
            result["teach_hint"] = self._generate_teach_hint(player)

        return result

    def _determine_next_state(self, player_input: str) -> str:
        task_keywords = ['任务', '帮忙', '委托', '差事', '事做', '活干']
        learn_keywords = ['学武', '拜师', '武功', '传授', '教我', '学艺']
        trade_keywords = ['买', '卖', '东西', '货物', '价格', '交易']
        bye_keywords = ['再见', '告辞', '走了', '下次', '留步']
        gossip_keywords = ['传闻', '消息', '最近', '发生', '江湖']

        if any(k in player_input for k in bye_keywords):
            return DialogueState.FAREWELL
        if any(k in player_input for k in task_keywords):
            return DialogueState.TASK_OFFER
        if any(k in player_input for k in learn_keywords):
            return DialogueState.TEACH_OFFER
        if any(k in player_input for k in trade_keywords):
            return DialogueState.TRADE
        if any(k in player_input for k in gossip_keywords):
            return DialogueState.CHATTING
        return DialogueState.CHATTING

    def _generate_quest_hint(self, player: Player) -> str:
        if self.npc.npc_type == NpcType.MASTER:
            hints = [
                "我这里正好有个门派任务需要人手。",
                "师门有一事相托，不知你愿不愿意？",
                "最近门中有些麻烦，需要弟子出力。",
            ]
        elif self.npc.npc_type == NpcType.TRADER:
            hints = [
                "我这有一笔买卖，需要人帮忙。",
                "客官若是有空，帮我跑趟腿如何？",
                "有批货需要护送，报酬从优。",
            ]
        else:
            hints = [
                "我有一事相求，不知大侠可否帮忙？",
                "最近遇到了些麻烦，想请人帮忙。",
                "有件事一直搁在心里，想找个可靠的人。",
            ]
        return random.choice(hints)

    def _generate_teach_hint(self, player: Player) -> str:
        if not self.npc.teach_skills:
            return ""
        skill_names = []
        from .world import ALL_SKILLS
        for sid in self.npc.teach_skills[:3]:
            if sid in ALL_SKILLS:
                skill_names.append(ALL_SKILLS[sid].name)
        if skill_names:
            return f"我可以传授你{', '.join(skill_names)}等武功。"
        return "我可以教你一些武功。"

    def request_quest(self, player: Player, player_behavior: Dict = None) -> Optional[Dict]:
        if not self.npc.has_quests:
            return None

        llm = get_llm_client()
        npc_info = self.get_npc_info()
        player_info = self.get_player_info(player)

        task = llm.generate_task(
            npc_info=npc_info,
            player_info=player_info,
            existing_tasks=[],
            player_behavior=player_behavior,
        )

        self._pending_task = task
        self.state = DialogueState.TASK_DETAIL

        return task

    def reset_state(self) -> None:
        self.state = DialogueState.GREETING
        self.player_input_buffer = ""


class NPCBrainManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._brains: Dict[int, NPCBrain] = {}
        return cls._instance

    def get_brain(self, npc: NPC) -> NPCBrain:
        if npc.id not in self._brains:
            self._brains[npc.id] = NPCBrain(npc)
        return self._brains[npc.id]

    def get_all_brains(self) -> Dict[int, NPCBrain]:
        return self._brains

    def reset_all(self) -> None:
        self._brains.clear()


def get_npc_brain_manager() -> NPCBrainManager:
    return NPCBrainManager()


def get_behavior_tracker() -> PlayerBehaviorTracker:
    return PlayerBehaviorTracker()
