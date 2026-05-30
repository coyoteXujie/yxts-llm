class_name ManaComponent extends BaseComponent
## 组件层 - 魔力组件，完全独立！

signal mp_changed(current: int, max: int)
signal mana_exhausted()

var _max_mp: int = 50
var _current_mp: int = 50
var _mp_regen: float = 0.0
var _temporary_bonuses: Array[Dictionary] = []

func set_max_mp(value: int, update_current: bool = true) -> void:
	_max_mp = max(1, value)
	if update_current:
		_current_mp = _max_mp
	_notify_mp_change()

func get_max_mp() -> int:
	var bonus: int = _calculate_max_mp_bonus()
	return _max_mp + bonus

func set_current_mp(value: int) -> void:
	var old_mp: int = _current_mp
	_current_mp = Utils.clamp(value, 0, get_max_mp())
	
	if _current_mp <= 0 and old_mp > 0:
		mana_exhausted.emit()
	
	_notify_mp_change()

func get_current_mp() -> int:
	return _current_mp

func get_mp_percent() -> float:
	var max_m: int = get_max_mp()
	if max_m <= 0:
		return 0.0
	return float(_current_mp) / float(max_m)

func consume_mana(amount: int) -> bool:
	if _current_mp < amount:
		return false
	_current_mp -= amount
	_notify_mp_change()
	return true

func restore_mana(amount: int) -> int:
	var restored: int = min(amount, get_max_mp() - _current_mp)
	_current_mp += restored
	_notify_mp_change()
	return restored

func set_mp_regen(regen: float) -> void:
	_mp_regen = regen

func _on_update(delta: float) -> void:
	if _mp_regen > 0:
		var regen_amount: float = _mp_regen * delta
		if regen_amount >= 1.0:
			var int_amount: int = int(regen_amount)
			_current_mp = min(_current_mp + int_amount, get_max_mp())
			_notify_mp_change()

func reset() -> void:
	_current_mp = _max_mp
	_temporary_bonuses.clear()
	_notify_mp_change()

func _calculate_max_mp_bonus() -> int:
	var total: int = 0
	for bonus in _temporary_bonuses:
		if bonus.has("max_mp"):
			total += bonus.get("max_mp", 0)
	return total

func _notify_mp_change() -> void:
	mp_changed.emit(_current_mp, get_max_mp())
