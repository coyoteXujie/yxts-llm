class_name InventoryComponent extends BaseComponent
## 组件层 - 背包组件，完全独立！

signal inventory_changed()
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal item_used(item_id: String, quantity: int)

var _items: Array[Dictionary] = []
var _max_slots: int = 40
var _item_slots: Dictionary = {}

func set_max_slots(count: int) -> void:
	_max_slots = max(1, count)

func add_item(item_id: String, quantity: int = 1) -> int:
	var slot_idx: int = _find_slot_for_item(item_id)
	if slot_idx == -1:
		slot_idx = _find_empty_slot()
		if slot_idx == -1:
			return 0
		
		_items.append({
			"item_id": item_id,
			"quantity": 0,
			"slot": slot_idx
		})
		_item_slots[slot_idx] = _items.size() - 1
	
	var item: Dictionary = _items[_item_slots[slot_idx]]
	var item_data: ItemData = DataRegistry.get_item_data(item_id)
	var max_stack: int = item_data.max_stack if item_data else 99
	var can_add: int = min(quantity, max_stack - item.get("quantity", 0))
	
	item["quantity"] += can_add
	item_added.emit(item_id, can_add)
	inventory_changed.emit()
	return can_add

func remove_item(item_id: String, quantity: int = 1) -> int:
	var remaining: int = quantity
	
	for i in range(_items.size()):
		var item: Dictionary = _items[i]
		if item.get("item_id", "") != item_id:
			continue
		
		var in_slot: int = item.get("quantity", 0)
		var to_remove: int = min(in_slot, remaining)
		item["quantity"] -= to_remove
		remaining -= to_remove
		
		if item.get("quantity", 0) <= 0:
			var slot: int = item.get("slot", -1)
			if _item_slots.has(slot):
				_item_slots.erase(slot)
			_items.remove_at(i)
			i -= 1
		
		item_removed.emit(item_id, to_remove)
		if remaining <= 0:
			break
	
	inventory_changed.emit()
	return quantity - remaining

func has_item(item_id: String, min_quantity: int = 1) -> bool:
	return get_item_count(item_id) >= min_quantity

func get_item_count(item_id: String) -> int:
	var total: int = 0
	for item in _items:
		if item.get("item_id", "") == item_id:
			total += item.get("quantity", 0)
	return total

func get_item_at_slot(slot: int) -> Dictionary:
	if _item_slots.has(slot):
		var idx: int = _item_slots[slot]
		if idx >= 0 and idx < _items.size():
			return _items[idx]
	return {}

func use_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
	
	var removed: int = remove_item(item_id, quantity)
	if removed > 0:
		item_used.emit(item_id, removed)
	return true

func get_all_items() -> Array[Dictionary]:
	return _items.duplicate()

func get_total_items() -> int:
	return _items.size()

func get_used_slots() -> int:
	return _item_slots.size()

func get_free_slots() -> int:
	return _max_slots - _item_slots.size()

func clear() -> void:
	_items.clear()
	_item_slots.clear()
	inventory_changed.emit()

func _find_slot_for_item(item_id: String) -> int:
	for item in _items:
		if item.get("item_id", "") == item_id:
			var data: ItemData = DataRegistry.get_item_data(item_id)
			var max_stack: int = data.max_stack if data else 99
			if item.get("quantity", 0) < max_stack:
				return item.get("slot", -1)
	return -1

func _find_empty_slot() -> int:
	for slot in range(_max_slots):
		if not _item_slots.has(slot):
			return slot
	return -1
