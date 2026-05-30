extends RefCounted
class_name Combatant

# 战斗者数据类 - 管理战斗中角色的所有相关数据

# 角色标识
var character_id: String = ""
var character_name: String = "未知角色"

# 实体引用（指向实际的角色节点）
var entity: Node = null

# 战斗属性
var max_hp: int = 100
var current_hp: int = 100
var max_mp: int = 50
var current_mp: int = 50

# 战斗状态
var is_defending: bool = false
var is_stunned: bool = false
var is_silenced: bool = false

# 位置和顺序
var position: Vector2i = Vector2i.ZERO
var turn_order_position: int = 0

# 状态效果数组
var status_effects: Array[Dictionary] = []

# 技能冷却时间字典
var action_cooldowns: Dictionary = {}

# 可用技能列表
var available_skills: Array[Skill] = []

# 可用物品列表
var available_items: Array = []

# 战斗AI配置（用于敌人）
var ai_behavior: String = "aggressive"
var ai_target_preference: String = "lowest_hp"

func _init() -> void:
	_init_default_values()

func _init_default_values() -> void:
	max_hp = 100
	current_hp = max_hp
	max_mp = 50
	current_mp = max_mp
	status_effects.clear()
	action_cooldowns.clear()
	available_skills.clear()
	available_items.clear()
	is_defending = false
	is_stunned = false
	is_silenced = false

# 是否是玩家角色
func is_players_turn() -> bool:
	if not entity:
		return false
	return entity.get("is_player") if entity.has("is_player") else false

# 是否可以行动
func can_act() -> bool:
	if not is_alive():
		return false
	if is_stunned:
		return false
	if is_silenced and available_skills.is_empty():
		return false
	if current_mp <= 0 and available_items.is_empty():
		return false
	return true

# 是否存活
func is_alive() -> bool:
	return current_hp > 0

# 获取当前速度
func get_speed() -> float:
	if entity and entity.has("speed"):
		return float(entity.get("speed"))
	return 10.0

# 获取攻击力
func get_attack() -> float:
	if entity and entity.has("attack"):
		return float(entity.get("attack"))
	return 20.0

# 获取防御力
func get_defense() -> float:
	if entity and entity.has("defense"):
		return float(entity.get("defense"))
	return 10.0

# 执行回合
func take_turn() -> Dictionary:
	if not can_act():
		return {
			"type": "skip",
			"reason": "无法行动" if not is_alive() else "被眩晕"
		}
	
	var action: Dictionary = choose_action()
	return action

# 选择行动（AI或玩家）
func choose_action() -> Dictionary:
	if is_players_turn():
		return _get_player_action()
	else:
		return _get_ai_action()

# 获取玩家行动（由UI系统调用）
func _get_player_action() -> Dictionary:
	return {
		"type": "wait",
		"combatant": self
	}

# AI行动选择逻辑
func _get_ai_action() -> Dictionary:
	match ai_behavior:
		"aggressive":
			return _ai_aggressive_action()
		"defensive":
			return _ai_defensive_action()
		"balanced":
			return _ai_balanced_action()
		"healer":
			return _ai_healer_action()
		_:
			return _ai_aggressive_action()

# 激进AI策略
func _ai_aggressive_action() -> Dictionary:
	var usable_skills: Array[Skill] = _get_usable_skills()
	
	if not usable_skills.is_empty():
		var best_skill: Skill = _select_best_attack_skill(usable_skills)
		if best_skill:
			return use_skill(best_skill)
	
	if not available_items.is_empty():
		return use_item(available_items[0])
	
	return _create_defend_action()

# 防守AI策略
func _ai_defensive_action() -> Dictionary:
	var health_percent: float = float(current_hp) / float(max_hp)
	
	if health_percent < 0.3 and not available_items.is_empty():
		return use_item(available_items[0])
	
	if health_percent < 0.5:
		var usable_skills: Array[Skill] = _get_usable_skills()
		var healing_skill: Skill = _find_healing_skill(usable_skills)
		if healing_skill:
			return use_skill(healing_skill)
	
	if health_percent > 0.7:
		var usable_skills: Array[Skill] = _get_usable_skills()
		var best_skill: Skill = _select_best_attack_skill(usable_skills)
		if best_skill:
			return use_skill(best_skill)
	
	return _create_defend_action()

# 平衡AI策略
func _ai_balanced_action() -> Dictionary:
	var usable_skills: Array[Skill] = _get_usable_skills()
	
	if not usable_skills.is_empty():
		if randf() < 0.7:
			var best_skill: Skill = _select_best_attack_skill(usable_skills)
			if best_skill:
				return use_skill(best_skill)
		else:
			var healing_skill: Skill = _find_healing_skill(usable_skills)
			if healing_skill:
				return use_skill(healing_skill)
	
	if not available_items.is_empty() and randf() < 0.3:
		return use_item(available_items[0])
	
	return _create_defend_action()

# 治疗AI策略
func _ai_healer_action() -> Dictionary:
	var usable_skills: Array[Skill] = _get_usable_skills()
	var healing_skill: Skill = _find_healing_skill(usable_skills)
	
	if healing_skill:
		return use_skill(healing_skill)
	
	if not available_items.is_empty():
		return use_item(available_items[0])
	
	var attack_skill: Skill = _select_best_attack_skill(usable_skills)
	if attack_skill:
		return use_skill(attack_skill)
	
	return _create_defend_action()

# 获取可用的技能
func _get_usable_skills() -> Array[Skill]:
	var usable: Array[Skill] = []
	
	for skill: Skill in available_skills:
		if skill.can_use(self):
			var skill_id: String = skill.skill_id if skill.skill_id else str(skill.get_instance_id())
			if not action_cooldowns.has(skill_id) or action_cooldowns[skill_id] <= 0:
				usable.append(skill)
	
	return usable

# 选择最佳攻击技能
func _select_best_attack_skill(usable_skills: Array[Skill]) -> Skill:
	var attack_skills: Array[Skill] = []
	
	for skill: Skill in usable_skills:
		if skill.type == Skill.SkillType.ATTACK:
			attack_skills.append(skill)
	
	if attack_skills.is_empty():
		return null
	
	attack_skills.sort_custom(func(a: Skill, b: Skill) -> bool:
		return a.damage > b.damage
	)
	
	return attack_skills[0]

# 查找治疗技能
func _find_healing_skill(usable_skills: Array[Skill]) -> Skill:
	for skill: Skill in usable_skills:
		if skill.type == Skill.SkillType.HEAL:
			return skill
	return null

# 创建防御行动
func _create_defend_action() -> Dictionary:
	return {
		"type": "defend",
		"combatant": self
	}

# 使用技能
func use_skill(skill: Skill, targets: Array[Combatant] = []) -> Dictionary:
	if not skill.can_use(self):
		push_warning("Combatant: 无法使用技能 " + skill.name)
		return {
			"type": "none",
			"reason": "无法使用技能"
		}
	
	var selected_targets: Array[Combatant] = targets
	
	if selected_targets.is_empty():
		selected_targets = _select_targets_for_skill(skill)
	
	if selected_targets.is_empty():
		push_warning("Combatant: 没有有效的目标")
		return {
			"type": "none",
			"reason": "没有有效的目标"
		}
	
	return {
		"type": "skill",
		"skill": skill,
		"targets": selected_targets,
		"combatant": self
	}

# 为技能选择目标
func _select_targets_for_skill(skill: Skill) -> Array[Combatant]:
	var targets: Array[Combatant] = []
	var combat_manager: Node = Engine.get_meta("CombatManager")
	
	if not combat_manager:
		return targets
	
	var combatants: Array[Combatant] = combat_manager.get_combatants()
	
	match skill.target_type:
		Skill.TargetType.SELF:
			targets.append(self)
		Skill.TargetType.SINGLE:
			targets.append(_select_single_target(combatants, is_players_turn()))
		Skill.TargetType.ALL:
			for combatant: Combatant in combatants:
				if is_players_turn() and combatant.is_players_turn():
					continue
				elif not is_players_turn() and not combatant.is_players_turn():
					continue
				targets.append(combatant)
	
	return targets

# 选择单个目标
func _select_single_target(combatants: Array[Combatant], target_players: bool) -> Combatant:
	var valid_targets: Array[Combatant] = []
	
	for combatant: Combatant in combatants:
		if combatant.is_alive():
			if target_players and combatant.is_players_turn():
				valid_targets.append(combatant)
			elif not target_players and not combatant.is_players_turn():
				valid_targets.append(combatant)
	
	if valid_targets.is_empty():
		return null
	
	match ai_target_preference:
		"lowest_hp":
			valid_targets.sort_custom(func(a: Combatant, b: Combatant) -> bool:
				return float(a.current_hp) / float(a.max_hp) < float(b.current_hp) / float(b.max_hp)
			)
		"highest_hp":
			valid_targets.sort_custom(func(a: Combatant, b: Combatant) -> bool:
				return float(a.current_hp) / float(a.max_hp) > float(b.current_hp) / float(b.max_hp)
			)
		"random":
			valid_targets.shuffle()
	
	return valid_targets[0]

# 使用物品
func use_item(item: Resource, targets: Array[Combatant] = []) -> Dictionary:
	if available_items.find(item) == -1:
		push_warning("Combatant: 物品不在可用列表中")
		return {
			"type": "none",
			"reason": "物品不可用"
		}
	
	var selected_targets: Array[Combatant] = targets
	
	if selected_targets.is_empty():
		selected_targets.append(self)
	
	return {
		"type": "item",
		"item": item,
		"targets": selected_targets,
		"combatant": self
	}

# 逃跑
func flee() -> Dictionary:
	var combat_manager: Node = Engine.get_meta("CombatManager")
	
	if not combat_manager:
		push_warning("Combatant: 无法获取战斗管理器")
		return {
			"type": "none",
			"reason": "系统错误"
		}
	
	return {
		"type": "flee",
		"combatant": self
	}

# 受到伤害
func take_damage(amount: int, is_critical: bool = false) -> int:
	var actual_damage: int = amount
	
	if is_defending:
		actual_damage = int(actual_damage * 0.5)
	
	current_hp = maxi(current_hp - actual_damage, 0)
	is_defending = false
	
	return actual_damage

# 受到治疗
func receive_healing(amount: int) -> int:
	var actual_healing: int = mini(amount, max_hp - current_hp)
	current_hp += actual_healing
	return actual_healing

# 消耗MP
func consume_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		return true
	return false

# 添加状态效果
func add_status_effect(effect: Dictionary) -> void:
	status_effects.append(effect.duplicate(true))

# 移除状态效果
func remove_status_effect(effect_name: String) -> bool:
	for i: int in range(status_effects.size()):
		if status_effects[i].get("name") == effect_name:
			status_effects.remove_at(i)
			return true
	return false

# 检查是否有特定状态效果
func has_status_effect(effect_name: String) -> bool:
	for effect: Dictionary in status_effects:
		if effect.get("name") == effect_name:
			return true
	return false

# 设置技能冷却
func set_skill_cooldown(skill_id: String, cooldown: int) -> void:
	action_cooldowns[skill_id] = cooldown

# 获取技能冷却剩余时间
func get_skill_cooldown_remaining(skill_id: String) -> int:
	if action_cooldowns.has(skill_id):
		return action_cooldowns[skill_id]
	return 0

# 重置回合状态
func reset_turn_state() -> void:
	is_defending = false

# 获取状态效果信息
func get_status_effects_info() -> Array[Dictionary]:
	return status_effects.duplicate()

# 获取生命值百分比
func get_hp_percentage() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

# 获取魔法值百分比
func get_mp_percentage() -> float:
	if max_mp <= 0:
		return 0.0
	return float(current_mp) / float(max_mp)

# 检查是否可以逃跑
func can_flee() -> bool:
	return is_alive() and can_act()

# 从实体初始化战斗者数据
func initialize_from_entity(source_entity: Node) -> void:
	entity = source_entity
	
	if source_entity.has("character_id"):
		character_id = source_entity.character_id
	if source_entity.has("character_name"):
		character_name = source_entity.character_name
	if source_entity.has("max_hp"):
		max_hp = source_entity.max_hp
	if source_entity.has("current_hp"):
		current_hp = source_entity.current_hp
	if source_entity.has("max_mp"):
		max_mp = source_entity.max_mp
	if source_entity.has("current_mp"):
		current_mp = source_entity.current_mp

# 同步数据到实体
func sync_to_entity() -> void:
	if not entity:
		return
	
	if entity.has("current_hp"):
		entity.current_hp = current_hp
	if entity.has("current_mp"):
		entity.current_mp = current_mp
