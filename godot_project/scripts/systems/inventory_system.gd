extends RefCounted
class_name InventorySystem

var _state: Node

const EQUIPMENT_DURABILITY_MAX := 100
const EQUIPMENT_REPAIR_PRICE_PER_MISSING_RATE := 0.004

func _init(state: Node) -> void:
	_state = state

func add_item(item_id: String, count: int = 1) -> void:
	if count <= 0:
		return
	_state.inventory[item_id] = int(_state.inventory.get(item_id, 0)) + count
	ensure_equipment_durability(item_id)
	_state.sync_collect_objective_progress(item_id)
	EventBus.inventory_changed.emit(_state.inventory)
	if AudioManager.has_sfx("item_pickup"):
		AudioManager.play_sfx("item_pickup")

func remove_item(item_id: String, count: int = 1) -> bool:
	if int(_state.inventory.get(item_id, 0)) < count:
		return false
	_state.inventory[item_id] = int(_state.inventory[item_id]) - count
	if int(_state.inventory[item_id]) <= 0:
		_state.inventory.erase(item_id)
		if is_equipment_item(item_id) and not _state.equipment.values().has(item_id):
			_state.equipment_durability.erase(item_id)
	_state.sync_collect_objective_progress(item_id, false)
	EventBus.inventory_changed.emit(_state.inventory)
	return true

func use_item(item_id: String) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	var item_type := str(item.get("type", ""))
	if item_type == "weapon" or item_type == "armor":
		return equip_item(item_id)
	if item_type != "consumable":
		EventBus.emit_toast("这个物品不能直接使用")
		return false
	if not remove_item(item_id, 1):
		return false
	var effects: Dictionary = item.get("effects", {})
	var parts: Array[String] = []
	if effects.has("hp"):
		parts.append("气血 +%d" % _state.heal_player(int(effects["hp"])))
	if effects.has("mp"):
		parts.append("内力 +%d" % _state.restore_mp(int(effects["mp"])))
	if effects.has("pot"):
		_state.player["pot"] = int(_state.player.get("pot", 0)) + int(effects["pot"])
		parts.append("潜能 +%d" % int(effects["pot"]))
	EventBus.player_changed.emit(_state.player)
	EventBus.emit_toast("使用%s：%s" % [str(item.get("name", item_id)), "，".join(parts)])
	return true

func equip_item(item_id: String) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if int(_state.inventory.get(item_id, 0)) <= 0:
		return false
	var slot := get_equipment_slot_for_item(item)
	if slot.is_empty():
		EventBus.emit_toast("无法装备")
		return false

	var old_item_id := str(_state.equipment.get(slot, ""))
	if old_item_id == item_id:
		EventBus.emit_toast("已经装备%s" % str(item.get("name", item_id)))
		return true
	if not old_item_id.is_empty():
		_state.inventory[old_item_id] = int(_state.inventory.get(old_item_id, 0)) + 1
	ensure_equipment_durability(item_id)
	_state.equipment[slot] = item_id
	_state.recalculate_player_stats()
	EventBus.emit_toast("装备%s" % str(item.get("name", item_id)))
	return true

func get_equipment_slot_for_item(item: Dictionary) -> String:
	return _equipment_slot_for_item(item)

func get_equipment_slot_for_item_id(item_id: String) -> String:
	return _equipment_slot_for_item(GameData.get_item(item_id))

func _equipment_slot_for_item(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var item_type := str(item.get("type", ""))
	var explicit_slot := str(item.get("slot", ""))
	if item_type == "weapon":
		return "weapon"
	if item_type == "armor":
		if explicit_slot.is_empty() or explicit_slot == "body":
			return "armor"
		if explicit_slot == "head" or explicit_slot == "hands" or explicit_slot == "feet":
			return explicit_slot
	if item_type == "accessory":
		return "accessory"
	if explicit_slot == "hand":
		return "weapon"
	if explicit_slot == "body":
		return "armor"
	if explicit_slot == "head" or explicit_slot == "hands" or explicit_slot == "feet" or explicit_slot == "accessory":
		return explicit_slot
	return ""

const EQUIPMENT_SCALE_KEYS := ["attack", "defense", "max_hp", "max_mp", "speed", "crit", "dodge", "flee", "hp_regen", "mp_regen", "poison", "burn", "bleed", "stun", "mp_steal", "hp_steal"]

func _equipment_scaled_effects(item_id: String) -> Dictionary:
	var item := GameData.get_item(item_id)
	var effects: Dictionary = item.get("effects", {})
	var factor := get_equipment_durability_effect_factor(item_id)
	var scaled: Dictionary = {}
	for key in EQUIPMENT_SCALE_KEYS:
		if effects.has(key):
			var raw: Variant = effects[key]
			if key == "crit" or key == "dodge" or key == "flee":
				scaled[key] = float(raw) * factor
			else:
				scaled[key] = int(round(float(raw) * factor))
	return scaled

func get_equipment_scaled_effects(item_id: String) -> Dictionary:
	return _equipment_scaled_effects(item_id).duplicate(true)

func get_equipment_durability_effect_factor(item_id: String) -> float:
	var durability := get_equipment_durability(item_id)
	if durability >= 75:
		return 1.0
	if durability >= 50:
		return 0.85
	if durability >= 25:
		return 0.65
	if durability > 0:
		return 0.45
	return 0.25

func get_equipment_condition_label(item_id: String) -> String:
	var durability := get_equipment_durability(item_id)
	if durability >= 75:
		return "完好"
	if durability >= 50:
		return "磨损"
	if durability >= 25:
		return "受损"
	if durability > 0:
		return "残破"
	return "损坏"

func is_equipment_item(item_id: String) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	var item_type := str(item.get("type", ""))
	return item_type == "weapon" or item_type == "armor" or item_type == "accessory"

func ensure_equipment_durability(item_id: String) -> void:
	if item_id.is_empty() or not is_equipment_item(item_id):
		return
	var durability := int(_state.equipment_durability.get(item_id, EQUIPMENT_DURABILITY_MAX))
	_state.equipment_durability[item_id] = clampi(durability, 0, EQUIPMENT_DURABILITY_MAX)

func get_equipment_durability(item_id: String) -> int:
	if item_id.is_empty() or not is_equipment_item(item_id):
		return 0
	ensure_equipment_durability(item_id)
	return int(_state.equipment_durability.get(item_id, EQUIPMENT_DURABILITY_MAX))

func set_equipment_durability(item_id: String, value: int) -> void:
	if item_id.is_empty() or not is_equipment_item(item_id):
		return
	var equipped: bool = _state.equipment.values().has(item_id)
	var old_effects := _equipment_scaled_effects(item_id) if equipped else {}
	_state.equipment_durability[item_id] = clampi(value, 0, EQUIPMENT_DURABILITY_MAX)
	if equipped:
		var new_effects := _equipment_scaled_effects(item_id)
		if _equipment_effects_changed(old_effects, new_effects):
			_state.recalculate_player_stats()
	EventBus.inventory_changed.emit(_state.inventory)

func _equipment_effects_changed(old_effects: Dictionary, new_effects: Dictionary) -> bool:
	return int(old_effects.get("attack", 0)) != int(new_effects.get("attack", 0)) or int(old_effects.get("defense", 0)) != int(new_effects.get("defense", 0))

func damage_equipment(slot: String, amount: int) -> int:
	var item_id := str(_state.equipment.get(slot, ""))
	if item_id.is_empty() or amount <= 0:
		return get_equipment_durability(item_id)
	set_equipment_durability(item_id, get_equipment_durability(item_id) - amount)
	return get_equipment_durability(item_id)

func get_equipment_repair_cost(item_id: String) -> int:
	if item_id.is_empty() or not is_equipment_item(item_id):
		return 0
	var missing := EQUIPMENT_DURABILITY_MAX - get_equipment_durability(item_id)
	if missing <= 0:
		return 0
	var item := GameData.get_item(item_id)
	var base_price := int(item.get("price", 0))
	return maxi(1, int(ceil(float(base_price) * EQUIPMENT_REPAIR_PRICE_PER_MISSING_RATE * float(missing))))

func get_repairable_equipment_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw_item_id in _state.inventory.keys():
		var item_id := str(raw_item_id)
		if int(_state.inventory.get(raw_item_id, 0)) <= 0:
			continue
		if get_equipment_repair_cost(item_id) <= 0:
			continue
		ids.append(item_id)
	ids.sort()
	return ids

func get_all_equipment_repair_cost(item_ids: Array[String] = []) -> int:
	var ids := item_ids
	if ids.is_empty():
		ids = get_repairable_equipment_item_ids()
	var total := 0
	for item_id in ids:
		total += get_equipment_repair_cost(item_id)
	return total

func repair_equipment(item_id: String, cost_override: int = -1) -> bool:
	if item_id.is_empty() or not is_equipment_item(item_id):
		return false
	if int(_state.inventory.get(item_id, 0)) <= 0 and not _state.equipment.values().has(item_id):
		return false
	var missing := EQUIPMENT_DURABILITY_MAX - get_equipment_durability(item_id)
	if missing <= 0:
		EventBus.emit_toast("无需修理")
		return false
	var cost := get_equipment_repair_cost(item_id)
	if cost_override >= 0:
		cost = cost_override
	if cost <= 0:
		return false
	if not _state.spend_money(cost):
		return false
	set_equipment_durability(item_id, EQUIPMENT_DURABILITY_MAX)
	var item := GameData.get_item(item_id)
	EventBus.emit_toast("修理%s，花费%d两" % [str(item.get("name", item_id)), cost])
	return true

func repair_all_equipment(item_ids: Array[String] = []) -> bool:
	var ids := item_ids
	if ids.is_empty():
		ids = get_repairable_equipment_item_ids()
	var filtered_ids: Array[String] = []
	for item_id in ids:
		if get_equipment_repair_cost(item_id) > 0:
			filtered_ids.append(item_id)
	if filtered_ids.is_empty():
		EventBus.emit_toast("无需修理")
		return false
	var total_cost := get_all_equipment_repair_cost(filtered_ids)
	if total_cost <= 0:
		return false
	if not _state.spend_money(total_cost):
		return false
	for item_id in filtered_ids:
		set_equipment_durability(item_id, EQUIPMENT_DURABILITY_MAX)
	EventBus.emit_toast("修理全部装备，花费%d两" % total_cost)
	return true

const EQUIPMENT_SLOTS := ["weapon", "armor", "head", "hands", "feet", "accessory"]

func _normalize_equipment_slots() -> void:
	if typeof(_state.equipment) != TYPE_DICTIONARY:
		_state.equipment = {}
	for slot in EQUIPMENT_SLOTS:
		if not _state.equipment.has(slot):
			_state.equipment[slot] = ""
	var hand_item := str(_state.equipment.get("hand", ""))
	if not hand_item.is_empty() and str(_state.equipment.get("weapon", "")).is_empty():
		_state.equipment["weapon"] = hand_item
	_state.equipment.erase("hand")
	var body_item := str(_state.equipment.get("body", ""))
	if not body_item.is_empty() and str(_state.equipment.get("armor", "")).is_empty():
		_state.equipment["armor"] = body_item
	_state.equipment.erase("body")

func _normalize_equipment_durability() -> void:
	var normalized: Dictionary = {}
	for raw_item_id in _state.equipment_durability.keys():
		var item_id := str(raw_item_id)
		if not is_equipment_item(item_id):
			continue
		normalized[item_id] = clampi(int(_state.equipment_durability.get(raw_item_id, EQUIPMENT_DURABILITY_MAX)), 0, EQUIPMENT_DURABILITY_MAX)
	_state.equipment_durability = normalized
	for raw_item_id in _state.inventory.keys():
		var item_id := str(raw_item_id)
		if int(_state.inventory.get(raw_item_id, 0)) > 0:
			ensure_equipment_durability(item_id)
	for raw_item_id in _state.equipment.values():
		ensure_equipment_durability(str(raw_item_id))

