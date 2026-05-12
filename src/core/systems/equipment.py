from typing import Dict, List, Optional, Tuple
from ..entities import Player, Item, ItemType
from ..event import EventType, dispatch


EQUIPMENT_SLOTS = {
    "weapon": "武器",
    "armor": "防具",
    "accessory": "饰品",
}

EQUIPMENT_SLOT_MAP = {
    ItemType.WEAPON: "weapon",
    ItemType.ARMOR: "armor",
    ItemType.BOOK: "accessory",
}

WEAPON_STAT_BONUSES = {
    "attack": 1.0,
    "dexterity": 0.3,
}

ARMOR_STAT_BONUSES = {
    "defense": 1.0,
    "constitution": 0.2,
}

ACCESSORY_STAT_BONUSES = {
    "intelligence": 0.5,
    "mp": 0.5,
}


class EquipmentSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def equip_item(self, player: Player, item_id: str, items_db: Dict[str, Item]) -> Dict:
        item = items_db.get(item_id)
        if not item:
            return {"success": False, "message": "物品不存在"}

        if item_id not in player.inventory or player.inventory[item_id] <= 0:
            return {"success": False, "message": f"你没有{item.name}"}

        slot = EQUIPMENT_SLOT_MAP.get(item.type)
        if not slot:
            return {"success": False, "message": f"{item.name}无法装备"}

        old_item_id = player.equipment.get(slot)
        if old_item_id:
            self._unequip_internal(player, slot, items_db)

        player.equipment[slot] = item_id
        player.remove_item(item_id)

        self._apply_equip_bonuses(player, item, equip=True)

        dispatch(EventType.ITEM_EQUIPPED, {
            "item_id": item_id,
            "item_name": item.name,
            "slot": slot,
            "slot_name": EQUIPMENT_SLOTS[slot],
        })

        return {
            "success": True,
            "message": f"装备了{item.name}",
            "slot": slot,
            "item_name": item.name,
        }

    def unequip_item(self, player: Player, slot: str, items_db: Dict[str, Item]) -> Dict:
        if slot not in EQUIPMENT_SLOTS:
            return {"success": False, "message": "无效的装备槽位"}

        item_id = player.equipment.get(slot)
        if not item_id:
            return {"success": False, "message": "该槽位没有装备"}

        item = items_db.get(item_id)
        if not item:
            return {"success": False, "message": "装备数据异常"}

        self._unequip_internal(player, slot, items_db)

        return {
            "success": True,
            "message": f"卸下了{item.name}",
            "slot": slot,
            "item_name": item.name,
        }

    def _unequip_internal(self, player: Player, slot: str, items_db: Dict[str, Item]):
        item_id = player.equipment.get(slot)
        if not item_id:
            return

        item = items_db.get(item_id)
        if item:
            self._apply_equip_bonuses(player, item, equip=False)

        del player.equipment[slot]
        player.add_item(item_id)

    def _apply_equip_bonuses(self, player: Player, item: Item, equip: bool):
        sign = 1 if equip else -1

        if item.type == ItemType.WEAPON:
            for stat, mult in WEAPON_STAT_BONUSES.items():
                if stat in item.effects:
                    val = int(item.effects[stat] * mult) * sign
                    if stat == "attack":
                        player.attack += val
        elif item.type == ItemType.ARMOR:
            for stat, mult in ARMOR_STAT_BONUSES.items():
                if stat in item.effects:
                    val = int(item.effects[stat] * mult) * sign
                    if stat == "defense":
                        player.defense += val
        elif item.type == ItemType.BOOK:
            for stat, mult in ACCESSORY_STAT_BONUSES.items():
                if stat in item.effects:
                    val = int(item.effects[stat] * mult) * sign
                    if stat == "mp":
                        player.max_mp += val
                    elif stat == "intelligence":
                        player.intelligence += val

    def get_equipment_stats(self, player: Player, items_db: Dict[str, Item]) -> Dict:
        stats = {
            "attack_bonus": 0,
            "defense_bonus": 0,
            "mp_bonus": 0,
            "equipped": {},
        }
        for slot, item_id in player.equipment.items():
            item = items_db.get(item_id)
            if item:
                stats["equipped"][slot] = {
                    "id": item_id,
                    "name": item.name,
                    "effects": item.effects,
                }
                if item.type == ItemType.WEAPON and "attack" in item.effects:
                    stats["attack_bonus"] += int(item.effects["attack"] * WEAPON_STAT_BONUSES["attack"])
                elif item.type == ItemType.ARMOR and "defense" in item.effects:
                    stats["defense_bonus"] += int(item.effects["defense"] * ARMOR_STAT_BONUSES["defense"])
                elif item.type == ItemType.BOOK:
                    if "mp" in item.effects:
                        stats["mp_bonus"] += int(item.effects["mp"] * ACCESSORY_STAT_BONUSES["mp"])
        return stats

    def get_total_attack(self, player: Player, items_db: Dict[str, Item]) -> int:
        bonus = 0
        weapon_id = player.equipment.get("weapon")
        if weapon_id:
            item = items_db.get(weapon_id)
            if item and "attack" in item.effects:
                bonus += int(item.effects["attack"] * WEAPON_STAT_BONUSES["attack"])
        return player.attack + bonus

    def get_total_defense(self, player: Player, items_db: Dict[str, Item]) -> int:
        bonus = 0
        armor_id = player.equipment.get("armor")
        if armor_id:
            item = items_db.get(armor_id)
            if item and "defense" in item.effects:
                bonus += int(item.effects["defense"] * ARMOR_STAT_BONUSES["defense"])
        return player.defense + bonus

    def can_equip(self, item: Item) -> bool:
        return item.type in EQUIPMENT_SLOT_MAP

    def get_slot_for_item(self, item: Item) -> Optional[str]:
        return EQUIPMENT_SLOT_MAP.get(item.type)


def get_equipment_system() -> EquipmentSystem:
    return EquipmentSystem()
