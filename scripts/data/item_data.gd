class_name ItemData extends Resource
## 数据层 - 物品数据，纯数据定义

@export var item_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon_path: String = ""

@export var item_type: int = Constants.ItemType.CONSUMABLE
@export var rarity: int = Constants.ItemRarity.COMMON
@export var level_requirement: int = 1
@export var max_stack: int = 99

@export var equip_slot: int = Constants.EquipmentSlot.ACCESSORY
@export var stats: Dictionary = {}

@export var consumable_effects: Array[Dictionary] = []
@export var value: int = 0
@export var is_tradable: bool = true
@export var is_destroyable: bool = true

func to_dictionary() -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"item_type": item_type,
		"rarity": rarity,
		"level_requirement": level_requirement,
		"max_stack": max_stack,
		"equip_slot": equip_slot,
		"stats": stats.duplicate(),
		"consumable_effects": consumable_effects.duplicate(),
		"value": value,
		"is_tradable": is_tradable,
		"is_destroyable": is_destroyable
	}

func from_dictionary(data: Dictionary) -> void:
	item_id = Utils.safe_string(data.get("item_id", ""))
	name = Utils.safe_string(data.get("name", ""))
	description = Utils.safe_string(data.get("description", ""))
	item_type = Utils.safe_int(data.get("item_type", Constants.ItemType.CONSUMABLE))
	rarity = Utils.safe_int(data.get("rarity", Constants.ItemRarity.COMMON))
	level_requirement = Utils.safe_int(data.get("level_requirement", 1))
	max_stack = Utils.safe_int(data.get("max_stack", 99))
	equip_slot = Utils.safe_int(data.get("equip_slot", Constants.EquipmentSlot.ACCESSORY))
	stats = data.get("stats", {}).duplicate()
	consumable_effects = data.get("consumable_effects", []).duplicate()
	value = Utils.safe_int(data.get("value", 0))
	is_tradable = data.get("is_tradable", true)
	is_destroyable = data.get("is_destroyable", true)
