extends Node
class_name CombatComponent
## 战斗组件 - 可复用的战斗系统组件
## 提供通用的战斗属性和战斗计算功能

# 战斗属性
@export var attack_power: int = 10  ## 攻击力
@export var defense: int = 5  ## 防御力
@export var speed: int = 10  ## 速度（影响行动顺序）
@export var crit_rate: float = 0.05  ## 暴击率 (0-1)
@export var crit_damage: float = 1.5  ## 暴击伤害倍率
@export var accuracy: float = 0.95  ## 命中率 (0-1)
@export var evasion: float = 0.05  ## 闪避率 (0-1)

# 攻击范围
@export var attack_range: float = 40.0  ## 普通攻击范围
@export var skill_range: float = 100.0  ## 技能攻击范围

# 冷却时间管理
var ability_cooldowns: Dictionary = {}  ## 技能冷却时间
var attack_cooldown: float = 0.0  ## 普通攻击冷却
var current_attack_cooldown: float = 0.0  ## 当前攻击冷却计时

# 战斗状态
var is_in_combat: bool = false  ## 是否处于战斗状态
var combat_targets: Array[Node] = []  ## 当前战斗目标列表

# 战斗效果列表
var active_effects: Array[Dictionary] = []  ## 正在生效的战斗效果

# 伤害结果数据结构
class DamageResult:
	var damage: int = 0  ## 造成的伤害
	var is_critical: bool = false  ## 是否暴击
	var is_miss: bool = false  ## 是否闪避
	var damage_type: String = "physical"  ## 伤害类型
	var effects_applied: Array = []  ## 附加的效果

# 信号定义
signal attack_performed(result: DamageResult)  ## 攻击执行后
signal ability_used(ability_id: String, result: DamageResult)  ## 技能使用后
signal damage_dealt(target: Node, amount: int)  ## 造成伤害时
signal damage_taken(amount: int)  ## 受到伤害时
signal combat_started()  ## 进入战斗状态
signal combat_ended()  ## 结束战斗状态
signal effect_applied(effect: Dictionary)  ## 效果被应用
signal effect_removed(effect_id: String)  ## 效果被移除

func _ready() -> void:
	## 初始化战斗组件
	pass

func _physics_process(delta: float) -> void:
	## 更新冷却时间
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta
	
	for ability_id in ability_cooldowns:
		if ability_cooldowns[ability_id] > 0:
			ability_cooldowns[ability_id] -= delta
	
	## 更新战斗效果
	_update_effects(delta)

## 执行攻击
## [param target] 攻击目标
## [return] 攻击结果
func perform_attack(target: Node) -> DamageResult:
	var result = DamageResult.new()
	
	# 检查攻击冷却
	if current_attack_cooldown > 0:
		result.is_miss = true
		return result
	
	# 检查命中率
	if not _check_hit(target):
		result.is_miss = true
		attack_performed.emit(result)
		return result
	
	# 计算伤害
	result.damage = calculate_damage(target)
	result.is_critical = _roll_critical()
	
	if result.is_critical:
		result.damage = int(result.damage * crit_damage)
	
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(result.damage)
	
	# 设置冷却
	current_attack_cooldown = attack_cooldown
	
	# 发送信号
	attack_performed.emit(result)
	if target.has_method("take_damage"):
		damage_dealt.emit(target, result.damage)
	
	return result

## 计算伤害
## [param target] 目标
## [return] 计算后的伤害值
func calculate_damage(target: Node) -> int:
	var base_damage: int = attack_power
	
	# 获取目标防御力
	var target_defense: int = 0
	if target.has_method("get_defense"):
		target_defense = target.get_defense()
	
	# 伤害计算公式：伤害 = 攻击力 * (1 - 防御率)
	# 防御率 = 防御力 / (防御力 + 100)
	var damage_reduction: float = float(target_defense) / (float(target_defense) + 100.0)
	var final_damage: int = int(float(base_damage) * (1.0 - damage_reduction))
	
	# 确保至少造成1点伤害
	return maxi(1, final_damage)

## 检查是否命中
## [param target] 目标
## [return] 是否命中
func _check_hit(target: Node) -> bool:
	# 获取目标闪避率
	var target_evasion: float = evasion
	if target.has_method("get_evasion"):
		target_evasion = target.get_evasion()
	
	# 计算最终命中率
	var final_accuracy: float = accuracy * (1.0 - target_evasion)
	
	# 随机判定
	return randf() < final_accuracy

## 判定暴击
## [return] 是否暴击
func _roll_critical() -> bool:
	return randf() < crit_rate

## 使用技能
## [param ability_id] 技能ID
## [param target] 目标
## [param ability_data] 技能数据
## [return] 使用结果
func use_ability(ability_id: String, target: Node, ability_data: Dictionary) -> DamageResult:
	var result = DamageResult.new()
	
	# 检查冷却
	if ability_id in ability_cooldowns and ability_cooldowns[ability_id] > 0:
		result.is_miss = true
		return result
	
	# 消耗魔法值（如果有）
	var owner = get_owner()
	if owner and ability_data.has("mp_cost"):
		if owner.has_method("get_mp") and owner.get("mp", 0) < ability_data["mp_cost"]:
			result.is_miss = true
			return result
		if owner.has_method("set_mp"):
			owner.set("mp", owner.get("mp") - ability_data["mp_cost"])
	
	# 检查范围
	var ability_range: float = ability_data.get("range", skill_range)
	var distance: float = owner.global_position.distance_to(target.global_position) if owner else 0.0
	if distance > ability_range:
		result.is_miss = true
		return result
	
	# 计算伤害
	result.damage_type = ability_data.get("damage_type", "physical")
	result.damage = ability_data.get("damage", 0)
	
	# 如果有攻击力加成
	var attack_bonus: float = ability_data.get("attack_scaling", 0.0)
	if attack_bonus > 0:
		result.damage += int(attack_power * attack_bonus)
	
	# 暴击判定
	result.is_critical = _roll_critical()
	if result.is_critical:
		result.damage = int(result.damage * crit_damage)
	
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(result.damage)
	
	# 应用效果
	if ability_data.has("effects"):
		for effect in ability_data["effects"]:
			apply_effect(effect)
			result.effects_applied.append(effect)
	
	# 设置冷却
	var cooldown: float = ability_data.get("cooldown", 1.0)
	ability_cooldowns[ability_id] = cooldown
	
	# 发送信号
	ability_used.emit(ability_id, result)
	damage_dealt.emit(target, result.damage)
	
	return result

## 应用效果
## [param effect] 效果数据
func apply_effect(effect: Dictionary) -> void:
	var effect_id: String = effect.get("id", str(hash(effect)))
	var duration: float = effect.get("duration", 0.0)
	var effect_type: String = effect.get("type", "")
	
	# 创建效果数据
	var effect_data: Dictionary = {
		"id": effect_id,
		"type": effect_type,
		"duration": duration,
		"remaining_time": duration,
		"effect": effect
	}
	
	active_effects.append(effect_data)
	effect_applied.emit(effect)
	
	# 立即应用效果
	_apply_effect_instant(effect)

## 立即应用效果
## [param effect] 效果数据
func _apply_effect_instant(effect: Dictionary) -> void:
	var owner = get_owner()
	if not owner:
		return
	
	var effect_type: String = effect.get("type", "")
	
	match effect_type:
		"buff_attack":
			if owner.has_method("add_temporary_attack"):
				owner.add_temporary_attack(effect.get("value", 0))
		"buff_defense":
			if owner.has_method("add_temporary_defense"):
				owner.add_temporary_defense(effect.get("value", 0))
		"debuff":
			if owner.has_method("apply_debuff"):
				owner.apply_debuff(effect.get("value", 0))
		"heal_over_time":
			# 立即治疗一次
			if owner.has_method("heal"):
				owner.heal(effect.get("tick_amount", 0))

## 更新效果
## [param delta] 帧时间
func _update_effects(delta: float) -> void:
	var effects_to_remove: Array = []
	
	for effect_data in active_effects:
		if effect_data["remaining_time"] > 0:
			effect_data["remaining_time"] -= delta
			
			# 处理周期性效果
			var effect = effect_data["effect"]
			if effect.has("tick_interval"):
				var tick_interval: float = effect["tick_interval"]
				var elapsed: float = effect.get("elapsed", 0.0)
				effect_data["elapsed"] = elapsed + delta
				
				if effect_data["elapsed"] >= tick_interval:
					effect_data["elapsed"] = 0.0
					_apply_periodic_effect(effect)
			
			# 检查效果结束
			if effect_data["remaining_time"] <= 0:
				effects_to_remove.append(effect_data)
				_remove_effect(effect)
	
	# 移除已结束的效果
	for effect_data in effects_to_remove:
		active_effects.erase(effect_data)

## 应用周期性效果
## [param effect] 效果数据
func _apply_periodic_effect(effect: Dictionary) -> void:
	var owner = get_owner()
	if not owner:
		return
	
	match effect.get("type", ""):
		"heal_over_time":
			if owner.has_method("heal"):
				owner.heal(effect.get("tick_amount", 0))
		"damage_over_time":
			if owner.has_method("take_damage"):
				owner.take_damage(effect.get("tick_amount", 0))

## 移除效果
## [param effect] 效果数据
func _remove_effect(effect_data: Dictionary) -> void:
	var effect = effect_data["effect"]
	var effect_id = effect_data["id"]
	
	# 移除临时属性加成
	var owner = get_owner()
	if owner:
		match effect.get("type", ""):
			"buff_attack":
				if owner.has_method("remove_temporary_attack"):
					owner.remove_temporary_attack(effect.get("value", 0))
			"buff_defense":
				if owner.has_method("remove_temporary_defense"):
					owner.remove_temporary_defense(effect.get("value", 0))
	
	effect_removed.emit(effect_id)

## 获取技能冷却时间
## [param ability_id] 技能ID
## [return] 剩余冷却时间
func get_ability_cooldown(ability_id: String) -> float:
	return ability_cooldowns.get(ability_id, 0.0)

## 检查技能是否可用
## [param ability_id] 技能ID
## [return] 是否可用
func is_ability_ready(ability_id: String) -> bool:
	return ability_cooldowns.get(ability_id, 0.0) <= 0.0

## 重置技能冷却
## [param ability_id] 技能ID
func reset_ability_cooldown(ability_id: String) -> void:
	ability_cooldowns[ability_id] = 0.0

## 获取攻击范围
## [param is_skill] 是否为技能范围
## [return] 攻击范围
func get_attack_range(is_skill: bool = false) -> float:
	return skill_range if is_skill else attack_range

## 检查目标是否在攻击范围内
## [param target] 目标节点
## [param is_skill] 是否检查技能范围
## [return] 是否在范围内
func is_target_in_range(target: Node, is_skill: bool = false) -> bool:
	var owner = get_owner()
	if not owner:
		return false
	
	var range: float = get_attack_range(is_skill)
	var distance: float = owner.global_position.distance_to(target.global_position)
	return distance <= range

## 获取所有活动效果
## [return] 活动效果列表
func get_active_effects() -> Array:
	return active_effects.duplicate()

## 清除所有效果
func clear_all_effects() -> void:
	for effect_data in active_effects:
		_remove_effect(effect_data)
	active_effects.clear()

## 进入战斗状态
func enter_combat() -> void:
	if not is_in_combat:
		is_in_combat = true
		combat_started.emit()

## 退出战斗状态
func exit_combat() -> void:
	if is_in_combat:
		is_in_combat = false
		combat_ended.emit()

## 添加战斗目标
## [param target] 目标
func add_combat_target(target: Node) -> void:
	if target not in combat_targets:
		combat_targets.append(target)
		enter_combat()

## 移除战斗目标
## [param target] 目标
func remove_combat_target(target: Node) -> void:
	combat_targets.erase(target)
	if combat_targets.is_empty():
		exit_combat()

## 设置属性值
## [param stat] 属性名
## [param value] 属性值
func set_stat(stat: String, value: float) -> void:
	match stat:
		"attack_power":
			attack_power = int(value)
		"defense":
			defense = int(value)
		"speed":
			speed = int(value)
		"crit_rate":
			crit_rate = clampf(value, 0.0, 1.0)
		"crit_damage":
			crit_damage = value
		"accuracy":
			accuracy = clampf(value, 0.0, 1.0)
		"evasion":
			evasion = clampf(value, 0.0, 1.0)

## 获取属性值
## [param stat] 属性名
## [return] 属性值
func get_stat(stat: String) -> float:
	match stat:
		"attack_power":
			return attack_power
		"defense":
			return defense
		"speed":
			return speed
		"crit_rate":
			return crit_rate
		"crit_damage":
			return crit_damage
		"accuracy":
			return accuracy
		"evasion":
			return evasion
	return 0.0

## 获取所有属性
## [return] 属性字典
func get_all_stats() -> Dictionary:
	return {
		"attack_power": attack_power,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,
		"accuracy": accuracy,
		"evasion": evasion
	}

## 获取当前状态
## [return] 状态字典
func get_state() -> Dictionary:
	return {
		"attack_power": attack_power,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,
		"accuracy": accuracy,
		"evasion": evasion,
		"current_attack_cooldown": current_attack_cooldown,
		"ability_cooldowns": ability_cooldowns.duplicate(true),
		"active_effects": active_effects.duplicate(true)
	}

## 加载状态
## [param state] 状态字典
func load_state(state: Dictionary) -> void:
	if state.has("attack_power"):
		attack_power = state["attack_power"]
	if state.has("defense"):
		defense = state["defense"]
	if state.has("speed"):
		speed = state["speed"]
	if state.has("crit_rate"):
		crit_rate = state["crit_rate"]
	if state.has("crit_damage"):
		crit_damage = state["crit_damage"]
	if state.has("accuracy"):
		accuracy = state["accuracy"]
	if state.has("evasion"):
		evasion = state["evasion"]
	if state.has("current_attack_cooldown"):
		current_attack_cooldown = state["current_attack_cooldown"]
	if state.has("ability_cooldowns"):
		ability_cooldowns = state["ability_cooldowns"]
