import json
import os
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class StorylineType(Enum):
    MAIN = "main"
    FACTION = "faction"
    CHARACTER = "character"
    SIDE = "side"
    HIDDEN = "hidden"
    ROMANCE = "romance"
    CROSS_FACTION = "cross_faction"
    WORLD_EVENT = "world_event"
    PREQUEL = "prequel"
    DARK = "dark"


@dataclass
class ScriptNode:
    id: str
    title: str
    speaker: str = ""
    dialogue: str = ""
    node_type: str = "dialogue"
    choices: List[Dict] = field(default_factory=list)
    next: str = ""
    combat_enemy: str = ""
    target_npc: str = ""
    target_area: str = ""
    reward: Dict = field(default_factory=dict)
    requirements: Dict = field(default_factory=dict)
    set_flags: List[str] = field(default_factory=list)
    check_flags: List[str] = field(default_factory=list)
    morality_change: int = 0
    faction_change: Dict = field(default_factory=dict)
    on_enter: str = ""
    on_exit: str = ""
    narration: str = ""
    objectives: List[str] = field(default_factory=list)
    announcement: str = ""
    duration_days: int = 0
    world_changes: List[str] = field(default_factory=list)


@dataclass
class WorldEventTrigger:
    random: bool = True
    min_day: int = 1
    probability: float = 0.1
    season: str = ""
    flags: List[str] = field(default_factory=list)


@dataclass
class Storyline:
    id: str
    title: str
    storyline_type: StorylineType
    description: str = ""
    faction: str = ""
    character: str = ""
    start_node: str = ""
    nodes: Dict[str, ScriptNode] = field(default_factory=dict)
    prerequisites: Dict = field(default_factory=dict)
    chapter: str = ""
    factions: List[str] = field(default_factory=list)
    trigger: Optional[WorldEventTrigger] = None


class ScriptDatabase:
    _instance = None

    def __init__(self):
        self._storylines: Dict[str, Storyline] = {}
        self._loaded = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._storylines = {}
            cls._instance._loaded = False
        return cls._instance

    def load_all(self):
        if self._loaded:
            return
        self._load_builtin_storylines()
        self._load_json_storylines()
        self._loaded = True
        logger.info(f"剧本数据库加载完成: {len(self._storylines)}条剧情线, "
                     f"{sum(len(s.nodes) for s in self._storylines.values())}个节点")

    STORYLINE_FILES = {
        "main_story.json", "side_quests.json", "faction_lines.json",
        "character_lines.json", "hidden_lines.json", "romance_lines.json",
        "cross_faction_lines.json", "world_events.json", "prequel_story.json",
        "dark_storylines.json",
    }

    def _load_json_storylines(self):
        data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "scripts")
        if not os.path.exists(data_dir):
            return
        for filename in os.listdir(data_dir):
            if filename.endswith(".json") and filename in self.STORYLINE_FILES:
                path = os.path.join(data_dir, filename)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    if isinstance(data, list):
                        for item in data:
                            storyline = self._parse_storyline(item)
                            if storyline:
                                self._storylines[storyline.id] = storyline
                    elif isinstance(data, dict):
                        storyline = self._parse_storyline(data)
                        if storyline:
                            self._storylines[storyline.id] = storyline
                except Exception as e:
                    logger.warning(f"加载剧本文件失败: {filename}, error={e}")

    def _parse_storyline(self, data: Dict) -> Optional[Storyline]:
        try:
            stype = StorylineType(data.get("type", "side"))
            trigger = None
            if "trigger" in data:
                td = data["trigger"]
                trigger = WorldEventTrigger(
                    random=td.get("random", True),
                    min_day=td.get("min_day", 1),
                    probability=td.get("probability", 0.1),
                    season=td.get("season", ""),
                    flags=td.get("flags", []),
                )
            storyline = Storyline(
                id=data["id"],
                title=data["title"],
                storyline_type=stype,
                description=data.get("description", ""),
                faction=data.get("faction", ""),
                character=data.get("character", ""),
                start_node=data.get("start_node", ""),
                prerequisites=data.get("prerequisites", {}),
                chapter=data.get("chapter", ""),
                factions=data.get("factions", []),
                trigger=trigger,
            )
            node_list = data.get("nodes", data.get("phases", []))
            for nd in node_list:
                node = ScriptNode(
                    id=nd["id"],
                    title=nd.get("title", ""),
                    speaker=nd.get("speaker", ""),
                    dialogue=nd.get("dialogue", ""),
                    node_type=nd.get("type", "dialogue"),
                    choices=nd.get("choices", []),
                    next=nd.get("next", ""),
                    combat_enemy=nd.get("combat_enemy", ""),
                    target_npc=nd.get("target_npc", ""),
                    target_area=nd.get("target_area", ""),
                    reward=nd.get("reward", {}),
                    requirements=nd.get("requirements", {}),
                    set_flags=nd.get("set_flags", []),
                    check_flags=nd.get("check_flags", []),
                    morality_change=nd.get("morality_change", 0),
                    faction_change=nd.get("faction_change", {}),
                    on_enter=nd.get("on_enter", ""),
                    on_exit=nd.get("on_exit", ""),
                    narration=nd.get("narration", ""),
                    objectives=nd.get("objectives", []),
                    announcement=nd.get("announcement", ""),
                    duration_days=nd.get("duration_days", 0),
                    world_changes=nd.get("world_changes", []),
                )
                storyline.nodes[node.id] = node
            return storyline
        except Exception as e:
            logger.warning(f"解析剧情失败: {e}, data_id={data.get('id', 'unknown')}")
            return None

    def _load_builtin_storylines(self):
        pass

    def get_storyline(self, storyline_id: str) -> Optional[Storyline]:
        return self._storylines.get(storyline_id)

    def get_storylines_by_type(self, stype: StorylineType) -> List[Storyline]:
        return [s for s in self._storylines.values() if s.storyline_type == stype]

    def get_storylines_by_faction(self, faction: str) -> List[Storyline]:
        return [s for s in self._storylines.values() if s.faction == faction]

    def get_storylines_by_character(self, character: str) -> List[Storyline]:
        return [s for s in self._storylines.values() if s.character == character]

    def get_romance_storylines(self) -> List[Storyline]:
        return self.get_storylines_by_type(StorylineType.ROMANCE)

    def get_cross_faction_storylines(self) -> List[Storyline]:
        return self.get_storylines_by_type(StorylineType.CROSS_FACTION)

    def get_world_event_storylines(self) -> List[Storyline]:
        return self.get_storylines_by_type(StorylineType.WORLD_EVENT)

    def get_prequel_storylines(self) -> List[Storyline]:
        return self.get_storylines_by_type(StorylineType.PREQUEL)

    def get_dark_storylines(self) -> List[Storyline]:
        return self.get_storylines_by_type(StorylineType.DARK)

    def get_storylines_involving_faction(self, faction: str) -> List[Storyline]:
        return [s for s in self._storylines.values() if faction in s.factions or s.faction == faction]

    def get_available_storylines(self, player, flags: Dict[str, bool]) -> List[Storyline]:
        available = []
        for s in self._storylines.values():
            if self._check_prerequisites(s, player, flags):
                available.append(s)
        return available

    def _check_prerequisites(self, storyline: Storyline, player, flags: Dict[str, bool]) -> bool:
        prereq = storyline.prerequisites
        if not prereq:
            return True
        if "level" in prereq and player.level < prereq["level"]:
            return False
        if "faction" in prereq:
            if prereq["faction"] == "any" and player.faction.value == "none":
                return False
            elif prereq["faction"] != "any" and player.faction.value != prereq["faction"]:
                return False
        if "morality_min" in prereq and player.daode < prereq["morality_min"]:
            return False
        if "morality_max" in prereq and player.daode > prereq["morality_max"]:
            return False
        if "flags" in prereq:
            for flag in prereq["flags"]:
                if not flags.get(flag, False):
                    return False
        return True

    def get_all_storylines_info(self) -> List[Dict]:
        return [
            {
                "id": s.id,
                "title": s.title,
                "type": s.storyline_type.value,
                "description": s.description,
                "node_count": len(s.nodes),
                "faction": s.faction,
                "character": s.character,
            }
            for s in self._storylines.values()
        ]


def get_script_db() -> ScriptDatabase:
    db = ScriptDatabase()
    db.load_all()
    return db


CHARACTER_NAME_MAP = {
    "aqing": ["阿青"],
    "xiuhua": ["绣花女", "林素心"],
    "qinghong": ["青红"],
    "huowu": ["火舞"],
    "wanjian": ["万剑"],
    "weiyang": ["韦扬"],
    "yuhongru": ["于红儒"],
    "qingzhao": ["清照"],
    "zhongyang": ["钟央"],
    "bairuide": ["白瑞德"],
    "xiaoyaozi": ["逍遥子"],
    "gusong": ["古松道人"],
    "laofuzi": ["老夫子"],
    "daode": ["道德和尚"],
}


def get_character_names(character_id: str) -> List[str]:
    return CHARACTER_NAME_MAP.get(character_id, [character_id])
