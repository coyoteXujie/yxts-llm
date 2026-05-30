extends Node
## 生命值组件 - 可复用的生命值管理系统
## 提供通用的生命值操作功能，可附加到任意节点

# 生命值属性
var current_hp: int = 100:
	set(value):
		var old_hp = current_hp
		current_hp = maxi(0, mini(value, max_hp))
		if current_hp != old_hp:
			hp_changed.emit(current_hp, max_hp)
			if current_hp <= 0 and old_hp > 0:
				died.emit()

var max_hp: int = 100:
	set(value):
		max_hp = maxi(1, value)
		if current_hp > max_hp:
			current_hp = max_hp

# 临时增益/减益效果
var temporary_max_hp_modifier: int = 0  ## 临时最大生命值修正
var damage_received_modifier: float = 1.0  ## 受到的伤害倍率
var healing_received_modifier: float = 1.0  ## 受到的治疗倍率

# 信号定义
signal hp_changed(new_hp: int, max_hp: int)  ## 生命值变化时发出
signal died  ## 死亡时发出
signal damaged(amount: int)  ## 受到伤害时发出
signal healed(amount: int)  ## 受到治疗时发出
signal revive(amount: int)  ## 复活时发出

func _ready() -> void:
	## 初始化组件
	hp_changed.emit(current_hp, max_hp)

## 获取当前最大生命值（包含临时修正）
## [return] 实际最大生命值
func get_effective_max_hp() -> int:
	return max_hp + temporary_max_hp_modifier

## 治疗
## [param amount] 治疗量
## [return] 是否成功治疗
func heal(amount: int) -> bool:
	if is_dead():
		return false
	
	var effective_amount: int = int(amount * healing_received_modifier)
	var old_hp: int = current_hp
	current_hp = mini(current_hp + effective_amount, get_effective_max_hp())
	var actual_heal: int = current_hp - old_hp
	
	if actual_heal > 0:
		healed.emit(actual_heal)
		return true
	return false

## 受到伤害
## [param amount] 伤害值
## [param ignore_defense] 是否忽略防御（默认为false）
## [return] 实际受到的伤害
func take_damage(amount: int, ignore_defense: bool = false) -> int:
	if is_dead():
		return 0
	
	# 计算实际伤害
	var actual_damage: int = int(amount * damage_received_modifier)
	
	# 如果未忽略防御，从拥有者节点获取防御值
	if not ignore_defense:
		var owner_node = get_owner()
		if owner_node and owner_node.has_method("get_defense"):
			var defense = owner_node.get_defense()
			actual_damage = maxi(1, actual_damage - defense)
	
	# 应用伤害
	var old_hp: int = current_hp
	current_hp = maxi(0, current_hp - actual_damage)
	var final_damage: int = old_hp - current_hp
	
	if final_damage > 0:
		damaged.emit(final_damage)
	
	return final_damage

## 检查是否死亡
## [return] 是否已死亡
func is_dead() -> bool:
	return current_hp <= 0

## 检查是否存活
## [return] 是否存活
func is_alive() -> bool:
	return current_hp > 0

## 获取生命值百分比
## [return] 0.0到1.0之间的生命值比例
func get_hp_percentage() -> float:
	var effective_max = get_effective_max_hp()
	if effective_max <= 0:
		return 0.0
	return float(current_hp) / float(effective_max)

## 获取生命值状态
## [return] 生命值状态字符串
func get_hp_status() -> String:
	var percentage = get_hp_percentage()
	if percentage >= 1.0:
		return "满血"
	elif percentage >= 0.75:
		return "良好"
	elif percentage >= 0.5:
		return "中等"
	elif percentage >= 0.25:
		return "危险"
	else:
		return "濒死"

## 设置生命值
## [param value] 生命值
## [param clamp_to_max] 是否限制在最大生命值范围内
func set_hp(value: int, clamp_to_max: bool = true) -> void:
	if clamp_to_max:
		current_hp = clampi(value, 0, get_effective_max_hp())
	else:
		current_hp = maxi(0, value)

## 设置最大生命值
## [param value] 最大生命值
## [param keep_ratio] 是否保持当前生命值比例
func set_max_hp(value: int, keep_ratio: bool = true) -> void:
	var old_max_hp = max_hp
	max_hp = maxi(1, value)
	
	if keep_ratio and old_max_hp > 0:
		current_hp = int((float(current_hp) / float(old_max_hp)) * max_hp)
	else:
		current_hp = mini(current_hp, max_hp)

## 添加临时最大生命值修正
## [param amount] 修正值（正数增加，负数减少）
func add_temporary_max_hp_modifier(amount: int) -> void:
	temporary_max_hp_modifier += amount
	# 确保生命值不超过新的最大生命值
	if current_hp > get_effective_max_hp():
		current_hp = get_effective_max_hp()

## 设置伤害接收倍率
## [param modifier] 伤害倍率（小于1减少伤害，大于1增加伤害）
func set_damage_modifier(modifier: float) -> void:
	damage_received_modifier = clampf(modifier, 0.0, 10.0)

## 设置治疗接收倍率
## [param modifier] 治疗倍率（小于1减少治疗效果，大于1增加治疗效果）
func set_healing_modifier(modifier: float) -> void:
	healing_received_modifier = clampf(modifier, 0.0, 10.0)

## 复活
## [param hp_amount] 复活时的生命值
## [return] 是否成功复活
func revive(hp_amount: int = -1) -> bool:
	if is_alive():
		return false
	
	if hp_amount < 0:
		hp_amount = get_effective_max_hp()
	
	current_hp = mini(hp_amount, get_effective_max_hp())
	revive.emit(current_hp)
	return true

## 完全恢复生命值
func full_restore() -> void:
	current_hp = get_effective_max_hp()

## 造成纯粹伤害（不经过任何计算）
## [param amount] 伤害值
## [return] 实际伤害值
func deal_pure_damage(amount: int) -> int:
	if is_dead():
		return 0
	
	var old_hp = current_hp
	current_hp = maxi(0, current_hp - amount)
	var damage = old_hp - current_hp
	
	if damage > 0:
		damaged.emit(damage)
	
	return damage

## 造成百分比伤害
## [param percentage] 百分比（0.0到1.0）
## [return] 实际伤害值
func deal_percentage_damage(percentage: float) -> int:
	if is_dead():
		return 0
	
	var damage = int(current_hp * clampf(percentage, 0.0, 1.0))
	return take_damage(damage, true)

## 获取属性字典
## [return] 包含所有属性的字典
func get_stats() -> Dictionary:
	return {
		"current_hp": current_hp,
		"max_hp": max_hp,
		"effective_max_hp": get_effective_max_hp(),
		"hp_percentage": get_hp_percentage(),
		"hp_status": get_hp_status(),
		"is_dead": is_dead(),
		"temporary_max_hp_modifier": temporary_max_hp_modifier,
		"damage_modifier": damage_received_modifier,
		"healing_modifier": healing_received_modifier
	}

## 获取当前状态
## [return] 状态字典
func get_state() -> Dictionary:
	return {
		"current_hp": current_hp,
		"max_hp": max_hp,
		"temporary_max_hp_modifier": temporary_max_hp_modifier,
		"damage_received_modifier": damage_received_modifier,
		"healing_received_modifier": healing_received_modifier
	}

## 加载状态
## [param state] 状态字典
func load_state(state: Dictionary) -> void:
	if state.has("current_hp"):
		current_hp = state["current_hp"]
	if state.has("max_hp"):
		max_hp = state["max_hp"]
	if state.has("temporary_max_hp_modifier"):
		temporary_max_hp_modifier = state["temporary_max_hp_modifier"]
	if state.has("damage_received_modifier"):
		damage_received_modifier = state["damage_received_modifier"]
	if state.has("healing_received_modifier"):
		healing_received_modifier = state["healing_received_modifier"]

## 重置所有临时效果
func reset_temporary_effects() -> void:
	temporary_max_hp_modifier = 0
	damage_received_modifier = 1.0
	healing_received_modifier = 1.0
