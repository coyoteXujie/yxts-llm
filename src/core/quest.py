from typing import Dict, List, Optional
from .event import EventType, Event, add_listener, dispatch
from .entities import Quest, Player, NPC, QuestType


class QuestManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.active_quests: Dict[str, Quest] = {}
            cls._instance.completed_quests: List[Quest] = []
            cls._instance.failed_quests: List[Quest] = []
            cls._instance.available_quests: Dict[int, List[Quest]] = {}
            cls._instance._register_event_listeners()
        return cls._instance

    def _register_event_listeners(self):
        add_listener(EventType.PLAYER_KILLED_NPC, self._on_npc_killed)
        add_listener(EventType.PLAYER_GOT_ITEM, self._on_item_got)
        add_listener(EventType.PLAYER_TALKED_TO_NPC, self._on_npc_talked)
        add_listener(EventType.PLAYER_EXPLORED_AREA, self._on_area_explored)

    def _on_npc_killed(self, event: Event):
        npc_name = event.data.get("npc_name", "")
        count = event.data.get("count", 1)
        if npc_name:
            self.update_quest_progress(QuestType.KILL, {"target": npc_name, "count": count})

    def _on_item_got(self, event: Event):
        item_name = event.data.get("item_name", "")
        count = event.data.get("count", 1)
        if item_name:
            self.update_quest_progress(QuestType.FETCH, {"target": item_name, "count": count})

    def _on_npc_talked(self, event: Event):
        npc_name = event.data.get("npc_name", "")
        if npc_name:
            self.update_quest_progress(QuestType.TALK, {"target": npc_name, "count": 1})

    def _on_area_explored(self, event: Event):
        area_name = event.data.get("area_name", "")
        if area_name:
            self.update_quest_progress(QuestType.EXPLORE, {"target": area_name, "count": 1})

    def generate_quests_for_npc(self, npc: NPC, player: Player, count: int = 3) -> List[Quest]:
        from .llm_client import get_llm_client

        npc_id = npc.id
        if npc_id not in self.available_quests:
            self.available_quests[npc_id] = []

        existing_ids = [q.task_id for q in self.available_quests[npc_id]]
        needed = count - len(self.available_quests[npc_id])

        llm_client = get_llm_client()
        for _ in range(needed):
            task_template = llm_client.generate_task(npc.get_info_dict(), self._get_player_info(player), existing_ids)
            quest = Quest(
                task_id=task_template["task_id"],
                title=task_template["title"],
                description=task_template["description"],
                task_type=QuestType(task_template["task_type"]),
                target=task_template["target"],
                count=task_template["count"],
                reward=task_template["reward"],
                difficulty=task_template["difficulty"],
                level_requirement=task_template["level_requirement"],
                morality_requirement=task_template.get("morality_requirement", 0),
                time_limit=task_template.get("time_limit"),
                issuer_npc_id=npc_id,
                issuer_npc_name=npc.name
            )
            self.available_quests[npc_id].append(quest)
            existing_ids.append(quest.task_id)

        return self.available_quests[npc_id]

    def _get_player_info(self, player: Player) -> Dict:
        from .entities import FACTION_NAMES
        return {
            "name": player.name,
            "level": player.level,
            "faction": player.faction.value,
            "faction_name": FACTION_NAMES[player.faction.value],
            "daode": player.daode,
            "strength": player.strength,
            "dexterity": player.dexterity,
            "intelligence": player.intelligence,
            "constitution": player.constitution
        }

    def get_available_quests_for_npc(self, npc_id: int, player: Player) -> List[Quest]:
        quests = self.available_quests.get(npc_id, [])
        return [
            q for q in quests
            if q.is_available(player.level, player.daode)
        ]

    def accept_quest(self, quest: Quest, player: Player) -> bool:
        if quest.is_available(player.level, player.daode):
            quest.accepted = True
            quest.accepted_time = 0
            self.active_quests[quest.task_id] = quest
            player.active_quests.append(quest.task_id)
            dispatch(EventType.QUEST_ACCEPTED, {"quest_id": quest.task_id, "quest_title": quest.title})
            return True
        return False

    def update_quest_progress(self, quest_type: QuestType, data: Dict) -> bool:
        target = data.get("target", "")
        count = data.get("count", 1)
        
        for quest in self.active_quests.values():
            if quest.task_type == quest_type and quest.target == target:
                if quest.update_progress(target, count):
                    self._complete_quest(quest)
                    return True
        return False

    def _complete_quest(self, quest: Quest):
        del self.active_quests[quest.task_id]
        self.completed_quests.append(quest)
        dispatch(EventType.QUEST_COMPLETED, {"quest_id": quest.task_id, "quest_title": quest.title, "reward": quest.reward})

    def get_active_quests(self) -> List[Quest]:
        return list(self.active_quests.values())

    def get_player_quests(self, player: Player) -> Dict:
        active = []
        for q in self.active_quests.values():
            active.append({
                "task_id": q.task_id,
                "title": q.title,
                "description": q.description,
                "task_type": q.task_type.value,
                "target": q.target,
                "count": q.count,
                "current_count": q.current_count,
                "completed": q.completed,
                "issuer_npc_name": q.issuer_npc_name,
            })
        completed = []
        for q in self.completed_quests:
            completed.append({
                "task_id": q.task_id,
                "title": q.title,
                "issuer_npc_name": q.issuer_npc_name,
            })
        return {"active": active, "completed": completed}

    def get_completed_quests(self) -> List[Quest]:
        return self.completed_quests

    def get_quest_by_id(self, task_id: str) -> Optional[Quest]:
        return self.active_quests.get(task_id)

    def give_reward(self, player: Player, quest: Quest) -> str:
        result = f"完成任务【{quest.title}】获得奖励：\n"
        reward = quest.reward
        
        if "money" in reward:
            amount = reward["money"]
            player.add_money(amount)
            result += f"  - 银两: {amount}\n"
        
        if "exp" in reward:
            amount = reward["exp"]
            level_up = player.add_exp(amount)
            result += f"  - 经验: {amount}\n"
            if level_up:
                result += f"  \u5feb\u4e50\uff01\u4f60\u5347\u7ea7\u5230\u7b2c{player.level}级！\n"
        
        if "pot" in reward:
            player.pot += reward["pot"]
            result += f"  - 潜能: {reward['pot']}\n"
        
        if "daode" in reward:
            player.daode += reward["daode"]
            result += f"  - 道德: {reward['daode']}\n"
        
        return result.strip()


def get_quest_manager() -> QuestManager:
    return QuestManager()