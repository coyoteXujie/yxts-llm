import json
import os
from typing import Dict, List
from .entities import NPC, Item, NpcType, Faction, ItemType, Position

_DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")


def _get_npc_type(type_str: str) -> NpcType:
    mapping = {
        "normal": NpcType.NORMAL,
        "master": NpcType.MASTER,
        "trader": NpcType.TRADER,
        "quest_giver": NpcType.QUEST_GIVER,
        "enemy": NpcType.ENEMY,
    }
    return mapping.get(type_str, NpcType.NORMAL)


def _get_faction(faction_str: str) -> Faction:
    mapping = {
        "none": Faction.NONE,
        "bagua": Faction.BAGUA,
        "flower": Faction.FLOWER,
        "honglian": Faction.HONGLIAN,
        "naja": Faction.NAJA,
        "taiji": Faction.TAIJI,
        "xueshan": Faction.XUESHAN,
        "xiaoyao": Faction.XIAOYAO,
    }
    return mapping.get(faction_str, Faction.NONE)


def _get_item_type(type_str: str) -> ItemType:
    mapping = {
        "consumable": ItemType.CONSUMABLE,
        "weapon": ItemType.WEAPON,
        "armor": ItemType.ARMOR,
        "material": ItemType.MATERIAL,
        "book": ItemType.BOOK,
        "quest": ItemType.QUEST,
    }
    return mapping.get(type_str, ItemType.CONSUMABLE)


def load_items() -> Dict[str, Item]:
    path = os.path.join(_DATA_DIR, "items.json")
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    items = {}
    for d in data:
        item = Item(
            id=d["id"],
            name=d["name"],
            type=_get_item_type(d["type"]),
            price=d.get("price", 0),
            description=d.get("description", ""),
            effects=d.get("effects", {}),
        )
        items[item.id] = item
    return items


def load_npcs() -> List[NPC]:
    path = os.path.join(_DATA_DIR, "npcs.json")
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    npcs = []
    for d in data:
        pos = Position(
            x=d.get("pos_x", 0) * 64 + 32,
            y=d.get("pos_y", 0) * 64 + 32,
        )
        npc = NPC(
            id=d["id"],
            name=d["name"],
            npc_type=_get_npc_type(d.get("npc_type", "normal")),
            faction=_get_faction(d.get("faction", "none")),
            personality=d.get("personality", ""),
            description=d.get("description", ""),
            level=d.get("level", 1),
            strength=d.get("strength", 10),
            dexterity=d.get("dexterity", 10),
            intelligence=d.get("intelligence", 10),
            constitution=d.get("constitution", 10),
            hp=d.get("hp", 100),
            max_hp=d.get("max_hp", 100),
            mp=d.get("mp", 0),
            max_mp=d.get("max_mp", 0),
            attack=d.get("attack", 5),
            defense=d.get("defense", 5),
            damage=d.get("damage", 5),
            money=d.get("money", 0),
            exp_reward=d.get("exp_reward", 10),
            position=pos,
            sell_items=d.get("sell_items", []),
            is_master=d.get("is_master", False),
            teach_skills=d.get("teach_skills", []),
            has_quests=d.get("has_quests", False),
        )
        npcs.append(npc)
    return npcs
