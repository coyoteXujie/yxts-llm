import json
import os
from typing import Dict, Optional
from .entities import Player, Skill, Faction, Position

_SAVE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "saves")


def _ensure_save_dir():
    os.makedirs(_SAVE_DIR, exist_ok=True)


def save_game(player: Player, slot: int = 1) -> Dict:
    _ensure_save_dir()
    data = {
        "name": player.name,
        "age": player.age,
        "gender": player.gender,
        "strength": player.strength,
        "dexterity": player.dexterity,
        "intelligence": player.intelligence,
        "constitution": player.constitution,
        "hp": player.hp,
        "max_hp": player.max_hp,
        "mp": player.mp,
        "max_mp": player.max_mp,
        "attack": player.attack,
        "defense": player.defense,
        "level": player.level,
        "exp": player.exp,
        "pot": player.pot,
        "daode": player.daode,
        "faction": player.faction.value,
        "master_id": player.master_id,
        "money": player.money,
        "position": {"x": player.position.x, "y": player.position.y},
        "skills": [
            {
                "id": s.id, "name": s.name, "type": s.type,
                "level": s.level, "damage": s.damage,
                "accuracy": s.accuracy, "exp": s.exp,
            }
            for s in player.skills
        ],
        "equip_skills": player.equip_skills,
        "inventory": player.inventory,
        "equipment": player.equipment,
        "active_quests": player.active_quests,
        "completed_quests": player.completed_quests,
        "food": player.food,
        "water": player.water,
        "faction_rep": {str(k): v for k, v in player.faction_rep.items()},
        "total_kills": player.total_kills,
        "total_deaths": player.total_deaths,
        "play_time": player.play_time,
    }
    path = os.path.join(_SAVE_DIR, f"save_{slot}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return {"success": True, "message": f"存档成功（槽位{slot}）", "slot": slot}


def load_game(slot: int = 1) -> Optional[Player]:
    path = os.path.join(_SAVE_DIR, f"save_{slot}.json")
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    player = Player()
    player.name = data.get("name", "少侠")
    player.age = data.get("age", 14)
    player.gender = data.get("gender", "male")
    player.strength = data.get("strength", 10)
    player.dexterity = data.get("dexterity", 10)
    player.intelligence = data.get("intelligence", 10)
    player.constitution = data.get("constitution", 10)
    player.hp = data.get("hp", 100)
    player.max_hp = data.get("max_hp", 100)
    player.mp = data.get("mp", 50)
    player.max_mp = data.get("max_mp", 50)
    player.attack = data.get("attack", 10)
    player.defense = data.get("defense", 5)
    player.level = data.get("level", 1)
    player.exp = data.get("exp", 0)
    player.pot = data.get("pot", 0)
    player.daode = data.get("daode", 0)
    player.faction = Faction(data.get("faction", "none"))
    player.master_id = data.get("master_id", 0)
    player.money = data.get("money", 100)
    pos_data = data.get("position", {})
    player.position = Position(x=pos_data.get("x", 0), y=pos_data.get("y", 0))
    player.skills = []
    for sd in data.get("skills", []):
        player.skills.append(Skill(
            id=sd["id"], name=sd["name"], type=sd.get("type", 0),
            level=sd.get("level", 1), damage=sd.get("damage", 0),
            accuracy=sd.get("accuracy", 0.8), exp=sd.get("exp", 0),
        ))
    player.equip_skills = data.get("equip_skills", [])
    player.inventory = data.get("inventory", {})
    player.equipment = data.get("equipment", {})
    player.active_quests = data.get("active_quests", [])
    player.completed_quests = data.get("completed_quests", [])
    player.food = data.get("food", 100)
    player.water = data.get("water", 100)
    player.faction_rep = {int(k): v for k, v in data.get("faction_rep", {}).items()}
    player.total_kills = data.get("total_kills", 0)
    player.total_deaths = data.get("total_deaths", 0)
    player.play_time = data.get("play_time", 0.0)
    return player


def list_saves() -> Dict[int, Dict]:
    result = {}
    if not os.path.exists(_SAVE_DIR):
        return result
    for i in range(1, 4):
        path = os.path.join(_SAVE_DIR, f"save_{i}.json")
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                result[i] = {
                    "name": data.get("name", "未知"),
                    "level": data.get("level", 1),
                    "faction": data.get("faction", "none"),
                    "play_time": data.get("play_time", 0),
                }
            except Exception:
                result[i] = {"name": "损坏", "level": 0, "faction": "none", "play_time": 0}
    return result


def delete_save(slot: int = 1) -> bool:
    path = os.path.join(_SAVE_DIR, f"save_{slot}.json")
    if os.path.exists(path):
        os.remove(path)
        return True
    return False
