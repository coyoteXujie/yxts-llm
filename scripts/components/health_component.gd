class_name HealthComponent extends BaseComponent
## 组件层 - 生命组件，完全独立！

signal hp_changed(current: int, max: int)
signal died()
signal damaged(amount: int)
signal healed(amount: int)

var _max_hp: int = 100
var _current_hp: int = 100
var _damage_reduction: float = 0.0
var _healing_bonus: float = 0.0
var _is_dead: bool = false
var _is_invulnerable: bool = false
var _temporary_bonuses: Array[Dictionary] = []

func set_max_hp(value: int, update_current: bool = true) -> void:
	_max_hp = max(1, value)
	if update_current:
		_current_hp = _max_hp
	_notify_hp_change()

func get_max_hp() -> int:
	var bonus: int = _calculate_max_hp_bonus()
	return _max_hp + bonus

func set_current_hp(value: int) -> void:
	var old_hp: int = _current_hp
	_current_hp = Utils.clamp(value, 0, get_max_hp())
	
	if _current_hp <= 0 and not _is_dead:
		_on_die()
	elif old_hp > 0 and _current_hp <= 0:
		_on_die()
	
	_notify_hp_change()

func get_current_hp() -> int:
	return _current_hp

func get_hp_percent() -> float:
	var max_h: int = get_max_hp()
	if max_h <= 0:
		return 0.0
	return float(_current_hp) / float(max_h)

func is_dead() -> bool:
	return _is_dead

func set_invulnerable(invulnerable: bool) -> void:
	_is_invulnerable = invulnerable

func take_damage(amount: int, damage_type: int = Constants.DamageType.PHYSICAL) -> int:
	if _is_dead or _is_invulnerable:
		return 0
	
	var actual_damage: int = amount
	if _damage_reduction > 0:
		actual_damage = int(float(actual_damage) * (1.0 - _damage_reduction))
	
	actual_damage = max(0, actual_damage)
	_current_hp -= actual_damage
	
	damaged.emit(actual_damage)
	_notify_hp_change()
	
	if _current_hp <= 0:
		_on_die()
	
	return actual_damage

func heal(amount: int) -> int:
	if _is_dead or amount <= 0:
		return 0
	
	var actual_heal: int = int(float(amount) * (1.0 + _healing_bonus))
	var hp_before: int = _current_hp
	
	_current_hp = min(_current_hp + actual_heal, get_max_hp())
	actual_heal = _current_hp - hp_before
	
	if actual_heal > 0:
		healed.emit(actual_heal)
		_notify_hp_change()
	
	return actual_heal

func revive(percent: float = 0.5) -> void:
	if not _is_dead:
		return
	_is_dead = false
	_current_hp = int(float(get_max_hp()) * percent)
	_notify_hp_change()

func set_damage_reduction(reduction: float) -> void:
	_damage_reduction = Utils.clamp(reduction, 0.0, 0.99)

func set_healing_bonus(bonus: float) -> void:
	_healing_bonus = bonus

func add_temporary_bonus(bonus: Dictionary) -> void:
	_temporary_bonuses.append(bonus)

func clear_temporary_bonuses() -> void:
	_temporary_bonuses.clear()

func reset() -> void:
	_is_dead = false
	_current_hp = _max_hp
	_damage_reduction = 0.0
	_healing_bonus = 0.0
	_temporary_bonuses.clear()
	_notify_hp_change()

func _calculate_max_hp_bonus() -> int:
	var total: int = 0
	for bonus in _temporary_bonuses:
		if bonus.has("max_hp"):
			total += bonus.get("max_hp", 0)
	return total

func _notify_hp_change() -> void:
	hp_changed.emit(_current_hp, get_max_hp())

func _on_die() -> void:
	_is_dead = true
	_current_hp = 0
	died.emit()
	_notify_hp_change()
