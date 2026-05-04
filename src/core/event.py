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
    NPC_INTERACTED = "npc_interacted"
    ENCOUNTER_TRIGGERED = "encounter_triggered"
    ENCOUNTER_ACCEPTED = "encounter_accepted"
    DIALOGUE_STATE_CHANGED = "dialogue_state_changed"
    PLAYER_BEHAVIOR_UPDATED = "player_behavior_updated"


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