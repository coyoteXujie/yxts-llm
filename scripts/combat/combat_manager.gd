extends Node
## 战斗管理器单例 - 通过 Autoload 全局访问
## 管理回合制战斗的逻辑

enum CombatState {
	INACTIVE,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

signal combat_started
signal combat_ended(victory: bool, rewards: Dictionary)
signal turn_changed(current_combatant: Combatant)
signal action_executed(combatant: Combatant, action: Dictionary)
signal damage_dealt(target: Combatant, damage: int, is_critical: bool)

var _current_state: CombatState = CombatState.INACTIVE
var _combatants: Array[Combatant] = []
var _turn_order: Array[Combatant] = []
var _current_turn_index: int = 0
var _player: Node = null
var _combat_log: Array[String] = []

func get_current_state() -> CombatState:
	return _current_state

func get_combat_log() -> Array[String]:
	return _combat_log.duplicate()

func get_combatants() -> Array[Combatant]:
	return _combatants.duplicate()

func get_current_combatant() -> Combatant:
	if _turn_order.is_empty() or _current_turn_index >= _turn_order.size():
		return null
	return _turn_order[_current_turn_index]

func start_combat(enemies: Array, player: Node) -> void:
	if _current_state != CombatState.INACTIVE:
		push_warning("CombatManager: 尝试在非空闲状态开始战斗")
		return

	_player = player
	_combatants.clear()
	_turn_order.clear()
	_combat_log.clear()
	_current_turn_index = 0

	if player.has_method("get_combatant_data"):
		var player_combatant: Combatant = player.get_combatant_data()
		player_combatant.entity = player
		_combatants.append(player_combatant)
		_log_action("玩家加入了战斗")

	for enemy in enemies:
		if enemy.has_method("get_combatant_data"):
			var enemy_combatant: Combatant = enemy.get_combatant_data()
			enemy_combatant.entity = enemy
			_combatants.append(enemy_combatant)
			var enemy_name: String = enemy.get("entity_name") if enemy.has("entity_name") else "敌人"
			_log_action("%s加入了战斗" % enemy_name)

	_calculate_turn_order()
	_current_state = CombatState.PLAYER_TURN
	turn_changed.emit(get_current_combatant())
	combat_started.emit()
	_log_action("=== 战斗开始 ===")

func end_combat(victory: bool) -> void:
	if _current_state == CombatState.INACTIVE:
		return

	_current_state = CombatState.VICTORY if victory else CombatState.DEFEAT

	for combatant in _combatants:
		combatant.status_effects.clear()
		combatant.action_cooldowns.clear()

	var result_text: String = "=== 胜利！ ===" if victory else "=== 失败... ==="
	_log_action(result_text)

	combat_ended.emit(victory, {})

	await Engine.get_main_loop().process_frame
	_current_state = CombatState.INACTIVE
	_combatants.clear()
	_turn_order.clear()

func _calculate_turn_order() -> void:
	_turn_order = _combatants.duplicate()
	_turn_order.sort_custom(func(a: Combatant, b: Combatant) -> bool:
		var speed_a: float = a.entity.get("speed") if a.entity and a.entity.has("speed") else 10.0
		var speed_b: float = b.entity.get("speed") if b.entity and b.entity.has("speed") else 10.0
		return speed_a > speed_b
	)

func get_turn_order() -> Array[Combatant]:
	return _turn_order.duplicate()

func execute_turn(combatant: Combatant, action: Dictionary) -> void:
	if not _is_valid_combatant(combatant):
		return

	if _current_state != CombatState.PLAYER_TURN and _current_state != CombatState.ENEMY_TURN:
		return

	match action.get("type"):
		"skill":
			_execute_skill_action(combatant, action)
		"item":
			_execute_item_action(combatant, action)
		"flee":
			_execute_flee_action(combatant)
		"defend":
			_execute_defend_action(combatant)

	action_executed.emit(combatant, action)
	_advance_turn()

func _execute_skill_action(combatant: Combatant, action: Dictionary) -> void:
	var skill: Skill = action.get("skill")
	var targets: Array[Combatant] = action.get("targets", [])

	if not skill or not (skill is Skill):
		return

	if not skill.can_use(combatant):
		_log_action("%s无法使用技能%s" % [combatant.entity.get("entity_name") if combatant.entity else "未知", skill.name])
		return

	combatant.current_mp -= skill.mana_cost
	combatant.action_cooldowns[skill.skill_id] = skill.cooldown

	var results: Array = skill.execute(combatant, targets)

	for result in results:
		if result.has("damage"):
			var target: Combatant = result.get("target")
			var damage: int = result.get("damage")
			var is_critical: bool = result.get("critical", false)
			
			_apply_damage(target, damage, is_critical)
			damage_dealt.emit(target, damage, is_critical)
			
			var target_name: String = target.entity.get("entity_name") if target.entity else "目标"
			var attacker_name: String = combatant.entity.get("entity_name") if combatant.entity else "施法者"
			_log_action("%s对%s造成了%s点伤害" % [attacker_name, target_name, damage])
		
		if result.has("healing"):
			var target: Combatant = result.get("target")
			var healing: int = result.get("healing")
			target.current_hp = mini(target.current_hp + healing, target.max_hp)
			var target_name: String = target.entity.get("entity_name") if target.entity else "目标"
			_log_action("%s恢复了%s点HP" % [target_name, healing])
		
		if result.has("status_effects"):
			for effect_data in result.get("status_effects"):
				apply_status_effect(result.get("target"), effect_data)

func _execute_item_action(combatant: Combatant, action: Dictionary) -> void:
	var item_name: String = action.get("item_name", "物品")
	_log_action("%s使用了%s" % [combatant.entity.get("entity_name") if combatant.entity else "未知", item_name])

func _execute_flee_action(combatant: Combatant) -> void:
	_log_action("%s尝试逃跑" % [combatant.entity.get("entity_name") if combatant.entity else "未知"])
	var flee_chance: float = 0.5
	if randf() < flee_chance:
		_log_action("逃跑成功！")
		end_combat(false)
	else:
		_log_action("逃跑失败！")

func _execute_defend_action(combatant: Combatant) -> void:
	combatant.is_defending = true
	_log_action("%s进入防御姿态" % [combatant.entity.get("entity_name") if combatant.entity else "未知"])

func _apply_damage(target: Combatant, damage: int, is_critical: bool) -> void:
	var actual_damage: int = damage
	
	if target.is_defending:
		actual_damage = int(damage * 0.5)
		target.is_defending = false
	
	target.current_hp = maxi(target.current_hp - actual_damage, 0)
	
	if target.current_hp <= 0:
		_log_action("%s被击败了！" % [target.entity.get("entity_name") if target.entity else "目标"])
		_check_combat_end()

func calculate_damage(attacker: Combatant, defender: Combatant, skill: Skill) -> Dictionary:
	var base_damage: int = skill.damage if skill else 10
	var attack_stat: float = attacker.entity.get("attack") if attacker.entity and attacker.entity.has("attack") else 10.0
	var defense_stat: float = defender.entity.get("defense") if defender.entity and defender.entity.has("defense") else 5.0
	
	var damage: int = int((attack_stat * 2 - defense_stat) * base_damage / 20.0) + 5
	var variance: float = randf_range(0.9, 1.1)
	damage = int(damage * variance)
	
	var is_critical: bool = randf() < 0.1
	if is_critical:
		damage = int(damage * 1.5)

	return {
		"damage": maxi(damage, 1),
		"critical": is_critical
	}

func apply_status_effect(target: Combatant, effect_data: Dictionary) -> void:
	if not _is_valid_combatant(target):
		return

	var effect_name: String = effect_data.get("name", "未知效果")
	var effect_type: String = effect_data.get("type", "debuff")
	var effect_duration: int = effect_data.get("duration", 3)
	var effect_power: int = effect_data.get("power", 0)

	var new_effect: Dictionary = {
		"name": effect_name,
		"type": effect_type,
		"duration": effect_duration,
		"power": effect_power,
		"applied_turn": _current_turn_index
	}

	target.status_effects.append(new_effect)

	var target_name: String = target.entity.get("entity_name") if target.entity else "目标"
	_log_action("%s获得了状态效果: %s (持续%d回合)" % [target_name, effect_name, effect_duration])

func _process_status_effects(combatant: Combatant) -> void:
	var effects_to_remove: Array[int] = []

	for i: int in range(combatant.status_effects.size()):
		var effect: Dictionary = combatant.status_effects[i]
		
		match effect.get("type"):
			"poison":
				var poison_damage: int = effect.get("power", 5)
				combatant.current_hp = maxi(combatant.current_hp - poison_damage, 0)
				_log_action("%s受到%s点毒伤害" % [combatant.entity.get("entity_name") if combatant.entity else "单位", poison_damage])
			"burn":
				var burn_damage: int = effect.get("power", 3)
				combatant.current_hp = maxi(combatant.current_hp - burn_damage, 0)
				_log_action("%s受到%s点火伤害" % [combatant.entity.get("entity_name") if combatant.entity else "单位", burn_damage])
			"regen":
				var regen_amount: int = effect.get("power", 5)
				combatant.current_hp = mini(combatant.current_hp + regen_amount, combatant.max_hp)
				_log_action("%s恢复了%s点生命" % [combatant.entity.get("entity_name") if combatant.entity else "单位", regen_amount])
		
		effect["duration"] -= 1
		
		if effect["duration"] <= 0:
			effects_to_remove.append(i)

	for i: int in range(effects_to_remove.size() - 1, -1, -1):
		combatant.status_effects.remove_at(effects_to_remove[i])

func _advance_turn() -> void:
	var current: Combatant = get_current_combatant()
	if current:
		_process_status_effects(current)
	
	_check_combat_end()

	if _current_state == CombatState.VICTORY or _current_state == CombatState.DEFEAT:
		return

	_update_cooldowns()

	_current_turn_index += 1

	if _current_turn_index >= _turn_order.size():
		_current_turn_index = 0
		_calculate_turn_order()
		_log_action("--- 新的回合 ---")

	var next_combatant: Combatant = get_current_combatant()

	if next_combatant and next_combatant.entity and next_combatant.entity.has("entity_type"):
		_current_state = CombatState.PLAYER_TURN
	else:
		_current_state = CombatState.ENEMY_TURN

	turn_changed.emit(next_combatant)

func _update_cooldowns() -> void:
	for combatant in _combatants:
		var cooldowns_to_remove: Array[String] = []
		
		for skill_id: String in combatant.action_cooldowns:
			combatant.action_cooldowns[skill_id] -= 1
			
			if combatant.action_cooldowns[skill_id] <= 0:
				cooldowns_to_remove.append(skill_id)
		
		for skill_id: String in cooldowns_to_remove:
			combatant.action_cooldowns.erase(skill_id)

func _check_combat_end() -> void:
	var players_alive: bool = false
	var enemies_alive: bool = false

	for combatant in _combatants:
		if combatant.current_hp > 0:
			if combatant.entity and combatant.entity.has("entity_type"):
				players_alive = true
			else:
				enemies_alive = true

	if not enemies_alive:
		end_combat(true)
	elif not players_alive:
		end_combat(false)

func _is_valid_combatant(combatant: Combatant) -> bool:
	return combatant != null and is_instance_valid(combatant) and combatant.entity != null

func _log_action(message: String) -> void:
	_combat_log.append(message)

func get_skill_cooldown(combatant: Combatant, skill_id: String) -> int:
	if not combatant.action_cooldowns.has(skill_id):
		return 0
	return combatant.action_cooldowns[skill_id]
