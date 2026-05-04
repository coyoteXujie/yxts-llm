from enum import Enum
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Any


class Faction(Enum):
    NONE = 0
    BAGUA = 1
    FLOWER = 2
    HONGLIAN = 3
    NAJA = 4
    TAIJI = 5
    XUESHAN = 6
    XIAOYAO = 7


class NpcType(Enum):
    NORMAL = "normal"
    MASTER = "master"
    TRADER = "trader"
    QUEST_GIVER = "quest_giver"
    ENEMY = "enemy"


class SkillType(Enum):
    ATTACK = 0
    SWORD = 1
    DODGE = 2
    FORCE = 3
    PARRY = 4
    LITERACY = 5
    LOOKS = 6


class ItemType(Enum):
    CONSUMABLE = "consumable"
    WEAPON = "weapon"
    ARMOR = "armor"
    MATERIAL = "material"
    BOOK = "book"
    QUEST = "quest"


class QuestType(Enum):
    FETCH = "fetch"
    KILL = "kill"
    TALK = "talk"
    EXPLORE = "explore"
    DELIVER = "deliver"
    GUARD = "guard"


FACTION_NAMES = ["无门无派", "八卦门", "花间派", "红莲教", "那迦派", "太极门", "雪山派", "逍遥派"]
SKILL_TYPE_NAMES = ["拳脚", "剑法", "刀法", "内功", "躲闪", "招架", "棍法", "杖法", "鞭法", "识字", "容貌"]


@dataclass
class Position:
    x: float = 0.0
    y: float = 0.0

    def distance_to(self, other: 'Position') -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

    def __add__(self, other: 'Position') -> 'Position':
        return Position(self.x + other.x, self.y + other.y)


@dataclass
class Skill:
    id: str
    name: str
    type: int
    level: int = 1
    exp: int = 0
    damage: int = 0
    accuracy: float = 0.8
    description: str = ""

    def get_exp_for_next_level(self) -> int:
        return self.level * 100

    def add_exp(self, amount: int) -> bool:
        self.exp += amount
        needed = self.get_exp_for_next_level()
        if self.exp >= needed:
            self.exp -= needed
            self.level += 1
            self.damage += self.level
            return True
        return False


@dataclass
class Item:
    id: str
    name: str
    type: ItemType
    price: int = 0
    description: str = ""
    effects: Dict[str, int] = field(default_factory=dict)
    quantity: int = 1


@dataclass
class Player:
    name: str = "少侠"
    age: int = 14
    gender: str = "male"
    strength: int = 10
    dexterity: int = 10
    intelligence: int = 10
    constitution: int = 10
    hp: int = 100
    max_hp: int = 100
    mp: int = 50
    max_mp: int = 50
    attack: int = 10
    defense: int = 5
    level: int = 1
    exp: int = 0
    pot: int = 0
    daode: int = 0
    faction: Faction = Faction.NONE
    master_id: int = 0
    money: int = 100
    position: Position = field(default_factory=Position)
    skills: List[Skill] = field(default_factory=list)
    equip_skills: List[str] = field(default_factory=lambda: ["", "", "", ""])
    inventory: Dict[str, int] = field(default_factory=dict)
    equipment: Dict[str, str] = field(default_factory=dict)
    active_quests: List[str] = field(default_factory=list)
    completed_quests: List[str] = field(default_factory=list)
    status_effects: List[Dict] = field(default_factory=list)
    food: int = 100
    water: int = 100

    def add_exp(self, amount: int) -> bool:
        self.exp += amount
        exp_needed = self.exp_for_next_level
        if self.exp >= exp_needed:
            self.exp -= exp_needed
            self.level += 1
            self.max_hp += 10
            self.max_mp += 5
            self.hp = self.max_hp
            self.mp = self.max_mp
            self.attack += 2
            self.defense += 1
            return True
        return False

    @property
    def exp_for_next_level(self) -> int:
        return self.level * 200

    def add_money(self, amount: int) -> None:
        self.money += amount

    def take_damage(self, amount: int) -> int:
        actual = min(amount, self.hp)
        self.hp = max(0, self.hp - actual)
        return actual

    def heal(self, amount: int) -> int:
        old_hp = self.hp
        self.hp = min(self.max_hp, self.hp + amount)
        return self.hp - old_hp

    def restore_mp(self, amount: int) -> int:
        old_mp = self.mp
        self.mp = min(self.max_mp, self.mp + amount)
        return self.mp - old_mp

    def is_alive(self) -> bool:
        return self.hp > 0

    def add_item(self, item_id: str, count: int = 1) -> bool:
        self.inventory[item_id] = self.inventory.get(item_id, 0) + count
        return True

    def remove_item(self, item_id: str, count: int = 1) -> bool:
        if self.inventory.get(item_id, 0) >= count:
            self.inventory[item_id] -= count
            if self.inventory[item_id] <= 0:
                del self.inventory[item_id]
            return True
        return False

    def update_food_water(self, delta_time: float) -> None:
        self.food = max(0, self.food - delta_time * 0.01)
        self.water = max(0, self.water - delta_time * 0.015)

    def setup_attr(self) -> None:
        self.max_hp = 50 + self.constitution * 10 + (self.level - 1) * 10
        self.max_mp = 20 + self.intelligence * 5 + (self.level - 1) * 5
        self.attack = 5 + self.strength + (self.level - 1) * 2
        self.defense = 2 + self.dexterity // 2 + (self.level - 1) * 1

    def use_item(self, item: Item) -> str:
        result = ""
        if item.type == ItemType.CONSUMABLE:
            if "hp" in item.effects:
                heal = min(item.effects["hp"], self.max_hp - self.hp)
                self.hp += heal
                result += f"使用{item.name}，恢复了{heal}点生命值\n"
            if "mp" in item.effects:
                restore = min(item.effects["mp"], self.max_mp - self.mp)
                self.mp += restore
                result += f"使用{item.name}，恢复了{restore}点内力\n"
            self.remove_item(item.id)
        return result.strip()


@dataclass
class NPC:
    id: int
    name: str
    npc_type: NpcType = NpcType.NORMAL
    faction: Faction = Faction.NONE
    level: int = 1
    description: str = ""
    personality: str = "和蔼可亲"
    location: str = "平安镇"
    position: Position = field(default_factory=Position)
    strength: int = 10
    dexterity: int = 10
    intelligence: int = 10
    constitution: int = 10
    hp: int = 50
    max_hp: int = 50
    mp: int = 20
    max_mp: int = 20
    attack: int = 5
    defense: int = 5
    damage: int = 5
    money: int = 100
    exp_reward: int = 10
    dialogue_history: List[str] = field(default_factory=list)
    sell_items: List[str] = field(default_factory=list)
    buy_items: List[str] = field(default_factory=list)
    has_quests: bool = True
    is_master: bool = False
    teach_skills: List[str] = field(default_factory=list)
    join_requirement: Dict = field(default_factory=dict)

    def get_info_dict(self) -> Dict:
        return {
            "id": self.id,
            "name": self.name,
            "role": self.npc_type.value,
            "faction": self.faction.value,
            "faction_name": FACTION_NAMES[self.faction.value],
            "level": self.level,
            "description": self.description,
            "personality": self.personality,
            "location": self.location,
            "is_master": self.is_master,
            "has_quests": self.has_quests
        }


@dataclass
class Quest:
    task_id: str
    title: str
    description: str
    task_type: QuestType
    target: str
    count: int = 1
    current_count: int = 0
    reward: Dict[str, int] = field(default_factory=dict)
    difficulty: int = 1
    level_requirement: int = 1
    morality_requirement: int = 0
    time_limit: Optional[int] = None
    issuer_npc_id: int = 0
    issuer_npc_name: str = ""
    accepted: bool = False
    completed: bool = False
    failed: bool = False
    accepted_time: Optional[float] = None

    def is_available(self, player_level: int, player_morality: int) -> bool:
        return (not self.accepted and not self.completed and not self.failed and
                player_level >= self.level_requirement and
                abs(player_morality) >= self.morality_requirement)

    def update_progress(self, target: str, count: int = 1) -> bool:
        if self.target == target and not self.completed:
            self.current_count += count
            if self.current_count >= self.count:
                self.completed = True
                return True
        return False


@dataclass
class Map:
    id: str
    name: str
    width: int = 1000
    height: int = 1000
    tiles: List[List[int]] = field(default_factory=list)
    npcs: List[int] = field(default_factory=list)
    exits: Dict[str, Position] = field(default_factory=dict)
    description: str = ""