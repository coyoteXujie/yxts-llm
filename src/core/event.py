from enum import Enum
from typing import Dict, Callable, Any, List


class EventType(Enum):
    PLAYER_MOVED = "player_moved"
    PLAYER_KILLED_NPC = "player_killed_npc"
    PLAYER_GOT_ITEM = "player_got_item"
    PLAYER_TALKED_TO_NPC = "player_talked_to_npc"
    PLAYER_EXPLORED_AREA = "player_explored_area"
    PLAYER_LEVEL_UP = "player_level_up"
    QUEST_ACCEPTED = "quest_accepted"
    QUEST_PROGRESSED = "quest_progressed"
    QUEST_COMPLETED = "quest_completed"
    QUEST_FAILED = "quest_failed"
    NPC_INTERACTED = "npc_interacted"
    ENCOUNTER_TRIGGERED = "encounter_triggered"
    ENCOUNTER_ACCEPTED = "encounter_accepted"
    DIALOGUE_STATE_CHANGED = "dialogue_state_changed"
    PLAYER_BEHAVIOR_UPDATED = "player_behavior_updated"
    REPUTATION_CHANGED = "reputation_changed"
    SKILL_LEVEL_UP = "skill_level_up"
    SKILL_MASTERY_CHANGED = "skill_mastery_changed"
    ITEM_EQUIPPED = "item_equipped"
    ITEM_UNEQUIPPED = "item_unequipped"
    PERFORM_USED = "perform_used"
    PLAYER_DEFEATED = "player_defeated"
    PLAYER_REVIVED = "player_revived"
    PLAYER_JOINED_FACTION = "player_joined_faction"
    PLAYER_BETRAYED_FACTION = "player_betrayed_faction"
    WORLD_EVENT_TRIGGERED = "world_event_triggered"
    WORLD_EVENT_COMPLETED = "world_event_completed"
    WORLD_EVENT_PHASE_CHANGED = "world_event_phase_changed"
    ROMANCE_PROGRESS = "romance_progress"
    ROMANCE_COMPLETED = "romance_completed"
    CROSS_FACTION_EVENT = "cross_faction_event"
    DARK_STORYLINE_PROGRESS = "dark_storyline_progress"
    PREQUEL_UNLOCKED = "prequel_unlocked"


class Event:
    def __init__(self, event_type: EventType, data: Dict[str, Any] = None):
        self.type = event_type
        self.data = data or {}


class EventManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._listeners: Dict[EventType, List[Callable[[Event], None]]] = {}
        return cls._instance

    def add_listener(self, event_type: EventType, callback: Callable[[Event], None]) -> None:
        if event_type not in self._listeners:
            self._listeners[event_type] = []
        self._listeners[event_type].append(callback)

    def remove_listener(self, event_type: EventType, callback: Callable[[Event], None]) -> None:
        if event_type in self._listeners:
            self._listeners[event_type].remove(callback)

    def dispatch(self, event_type: EventType, data: Dict[str, Any] = None) -> None:
        event = Event(event_type, data)
        if event_type in self._listeners:
            for callback in self._listeners[event_type]:
                try:
                    callback(event)
                except Exception as e:
                    print(f"Event callback error: {e}")


def add_listener(event_type: EventType, callback: Callable[[Event], None]) -> None:
    EventManager().add_listener(event_type, callback)


def remove_listener(event_type: EventType, callback: Callable[[Event], None]) -> None:
    EventManager().remove_listener(event_type, callback)


def dispatch(event_type: EventType, data: Dict[str, Any] = None) -> None:
    EventManager().dispatch(event_type, data)