import random
import logging
from typing import Dict, List, Optional, Set
from .script_system import get_script_db, StorylineType, Storyline, ScriptNode
from .event import EventType, dispatch

logger = logging.getLogger(__name__)


class ActiveWorldEvent:
    def __init__(self, storyline: Storyline, current_phase: str, start_day: int):
        self.storyline = storyline
        self.current_phase = current_phase
        self.start_day = start_day
        self.phase_start_day = start_day
        self.completed = False
        self.flags_set: Set[str] = set()

    def get_current_node(self) -> Optional[ScriptNode]:
        return self.storyline.nodes.get(self.current_phase)

    def advance_phase(self, next_phase: str, current_day: int):
        self.current_phase = next_phase
        self.phase_start_day = current_day

    def is_phase_expired(self, current_day: int) -> bool:
        node = self.get_current_node()
        if node and node.duration_days > 0:
            return (current_day - self.phase_start_day) >= node.duration_days
        return False


def apply_story_flags(player, flags: List[str]) -> None:
    if not flags:
        return
    if not hasattr(player, '_story_flags'):
        player._story_flags = []
    for flag in flags:
        if flag not in player._story_flags:
            player._story_flags.append(flag)


def apply_reward(player, reward: Dict) -> None:
    if not reward:
        return
    if "exp" in reward:
        player.add_exp(reward["exp"])
    if "money" in reward:
        player.add_money(reward["money"])
    if "daode" in reward:
        player.daode += reward["daode"]
    if "reputation" in reward and hasattr(player, 'reputation'):
        player.reputation += reward["reputation"]
    if "faction_rep" in reward and hasattr(player, 'faction_rep'):
        for faction_key, val in reward["faction_rep"].items():
            player.faction_rep[faction_key] = player.faction_rep.get(faction_key, 0) + val


def serialize_node(node: ScriptNode) -> Dict:
    return {
        "id": node.id,
        "title": node.title,
        "speaker": node.speaker,
        "dialogue": node.dialogue,
        "narration": node.narration,
        "type": node.node_type,
        "choices": node.choices,
        "next": node.next,
        "combat_enemy": node.combat_enemy,
        "reward": node.reward,
        "set_flags": node.set_flags,
        "objectives": node.objectives,
        "announcement": node.announcement,
        "world_changes": node.world_changes,
    }


STORYLINE_TYPE_EVENT_MAP = {
    StorylineType.ROMANCE: EventType.ROMANCE_COMPLETED,
    StorylineType.CROSS_FACTION: EventType.CROSS_FACTION_EVENT,
    StorylineType.DARK: EventType.DARK_STORYLINE_PROGRESS,
    StorylineType.PREQUEL: EventType.PREQUEL_UNLOCKED,
}


class WorldEventEngine:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._active_events: Dict[str, ActiveWorldEvent] = {}
            cls._instance._completed_events: Set[str] = set()
            cls._instance._checked_today: bool = False
            cls._instance._last_check_day: int = 0
        return cls._instance

    def check_and_trigger(self, game_day: int, flags: Dict[str, bool]) -> List[Dict]:
        if game_day == self._last_check_day and self._checked_today:
            return []
        self._last_check_day = game_day
        self._checked_today = True

        triggered = []
        script_db = get_script_db()

        for event_storyline in script_db.get_world_event_storylines():
            if event_storyline.id in self._completed_events:
                continue
            if event_storyline.id in self._active_events:
                continue
            if not event_storyline.trigger:
                continue
            if game_day < event_storyline.trigger.min_day:
                continue
            if event_storyline.trigger.flags:
                if not all(flags.get(f, False) for f in event_storyline.trigger.flags):
                    continue
            if event_storyline.trigger.season:
                pass
            if random.random() < event_storyline.trigger.probability:
                active = ActiveWorldEvent(
                    storyline=event_storyline,
                    current_phase=event_storyline.start_node,
                    start_day=game_day,
                )
                self._active_events[event_storyline.id] = active
                node = active.get_current_node()
                announcement = node.announcement or node.narration if node else ""
                triggered.append({
                    "event_id": event_storyline.id,
                    "title": event_storyline.title,
                    "description": event_storyline.description,
                    "announcement": announcement,
                })
                dispatch(EventType.WORLD_EVENT_TRIGGERED, {
                    "event_id": event_storyline.id,
                    "title": event_storyline.title,
                })
                logger.info(f"世界事件触发: {event_storyline.title}")

        return triggered

    def get_active_events(self) -> List[Dict]:
        result = []
        for eid, active in self._active_events.items():
            node = active.get_current_node()
            result.append({
                "event_id": eid,
                "title": active.storyline.title,
                "current_phase": active.current_phase,
                "phase_title": node.title if node else "",
                "phase_type": node.node_type if node else "",
            })
        return result

    def get_event_node(self, event_id: str) -> Optional[ScriptNode]:
        active = self._active_events.get(event_id)
        return active.get_current_node() if active else None

    def _complete_event(self, event_id: str, active: ActiveWorldEvent) -> Dict:
        active.completed = True
        self._completed_events.add(event_id)
        del self._active_events[event_id]
        dispatch(EventType.WORLD_EVENT_COMPLETED, {
            "event_id": event_id,
            "title": active.storyline.title,
        })
        logger.info(f"世界事件完成: {active.storyline.title}")
        return {"success": True, "message": "事件已完成", "completed": True}

    def advance_event(self, event_id: str, next_phase: str, game_day: int, player=None) -> Dict:
        active = self._active_events.get(event_id)
        if not active:
            return {"success": False, "message": "事件不存在"}

        old_node = active.get_current_node()
        if old_node:
            apply_story_flags(player, old_node.set_flags)
            apply_reward(player, old_node.reward)

        if not next_phase:
            return self._complete_event(event_id, active)

        active.advance_phase(next_phase, game_day)
        new_node = active.get_current_node()

        if new_node and new_node.node_type == "resolution":
            apply_story_flags(player, new_node.set_flags)
            apply_reward(player, new_node.reward)
            return self._complete_event(event_id, active)

        dispatch(EventType.WORLD_EVENT_PHASE_CHANGED, {
            "event_id": event_id,
            "title": active.storyline.title,
            "phase": next_phase,
        })

        return {
            "success": True,
            "message": "事件推进",
            "phase": next_phase,
            "phase_title": new_node.title if new_node else "",
        }

    def check_expired_phases(self, game_day: int) -> List[Dict]:
        expired = []
        for eid, active in list(self._active_events.items()):
            if active.is_phase_expired(game_day):
                node = active.get_current_node()
                if node and node.next:
                    result = self.advance_event(eid, node.next, game_day)
                    expired.append({
                        "event_id": eid,
                        "title": active.storyline.title,
                        "auto_advanced": True,
                        "new_phase": result.get("phase", ""),
                    })
        return expired

    def make_choice(self, event_id: str, choice_index: int, game_day: int, player=None) -> Dict:
        active = self._active_events.get(event_id)
        if not active:
            return {"success": False, "message": "事件不存在"}
        node = active.get_current_node()
        if not node or node.node_type != "choice":
            return {"success": False, "message": "当前阶段无法选择"}
        if choice_index < 0 or choice_index >= len(node.choices):
            return {"success": False, "message": "无效选择"}

        choice = node.choices[choice_index]
        if player and "morality_change" in choice:
            player.daode += choice["morality_change"]

        next_phase = choice.get("next", "")
        return self.advance_event(event_id, next_phase, game_day, player)

    def reset_daily_check(self):
        self._checked_today = False

    def get_completed_events(self) -> List[str]:
        return list(self._completed_events)

    def is_event_active(self, event_id: str) -> bool:
        return event_id in self._active_events

    def is_event_completed(self, event_id: str) -> bool:
        return event_id in self._completed_events


def get_world_event_engine() -> WorldEventEngine:
    return WorldEventEngine()
