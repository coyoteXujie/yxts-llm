extends Node
## 完整的战斗系统

signal combat_started()
signal combat_ended(victory: bool, rewards: Dictionary)
signal turn_changed(is_player_turn: bool)
signal combatant_hp_changed(target_id: String, current: int, max_hp: int)
signal combatant_mp_changed(target_id: String, current: int, max_mp: int)

var combat_state: int = Constants.CombatState.INACTIVE
var player_combatant: Dictionary = {}
var enemy_combatants: Array = []
var turn_order: Array = []
var current_turn_index: int = 0
var combat_log: Array = []
var battle_count: int = 0

func start_combat(player_data: Dictionary, enemies: Array) -> void:
	if combat_state != Constants.CombatState.INACTIVE:
		return
	
	battle_count += 1
	combat_log.clear()
	
	# 初始化玩家
	player_combatant = {
		"id": "player",
		"name": player_data.get("player_name", "玩家"),
		"level": player_data.get("level", 1),
		"max_hp": player_data.get("max_hp", 100),
		"current_hp": player_data.get("current_hp", 100),
		"max_mp": player_data.get("max_mp", 50),
		"current_mp": player_data.get("current_mp", 50),
		"attack": player_data.get("strength", 10) * 2,
		"defense": player_data.get("constitution", 10),
		"speed": player_data.get("dexterity", 10) * 2,
		"crit_chance": 0.1,
		"is_alive": true
	}
	
	# 初始化敌人
	enemy_combatants.clear()
	for enemy_data in enemies:
		enemy_combatants.append({
			"id": enemy_data.get("id", "enemy"),
			"name": enemy_data.get("name", "敌人"),
			"level": enemy_data.get("level", 1),
			"max_hp": enemy_data.get("max_hp", 50),
			"current_hp": enemy_data.get("current_hp", 50),
			"attack": enemy_data.get("attack", 8),
			"defense": enemy_data.get("defense", 5),
			"speed": enemy_data.get("speed", 10),
			"crit_chance": 0.05,
			"exp_reward": enemy_data.get("exp_reward", 50),
			"gold_reward": enemy_data.get("gold_reward", 20),
			"is_alive": true
		})
	
	# 决定行动顺序
	_initialize_turn_order()
	combat_state = Constants.CombatState.PLAYER_TURN
	
	# 发送事件
	combat_started.emit()
	EventBus.emit_combat_started()
	_log_action("战斗开始！")
	turn_changed.emit(true)

func _initialize_turn_order() -> void:
	turn_order.clear()
	turn_order.append("player")
	for i in range(enemy_combatants.size()):
		turn_order.append("enemy_%d" % i)
	
	# 按速度排序
	turn_order.sort_custom(func(a: String, b: String) -> bool:
		var speed_a := _get_combatant_speed(a)
		var speed_b := _get_combatant_speed(b)
		return speed_a > speed_b)
	
	current_turn_index = 0

func _get_combatant_speed(id: String) -> int:
	if id == "player":
		return player_combatant.get("speed", 10)
	for enemy in enemy_combatants:
		if enemy.get("id", "") == id:
			return enemy.get("speed", 10)
	return 10

func player_attack(target_id: String, skill_id: String = "normal_attack") -> void:
	if combat_state != Constants.CombatState.PLAYER_TURN:
		return
	
	var damage := 0
	var is_critical := false
	
	if skill_id == "normal_attack":
		var result := _calculate_damage(player_combatant, _get_combatant_by_id(target_id))
		damage = result[0]
		is_critical = result[1]
		_deal_damage(target_id, damage, is_critical)
		_log_action("%s 普通攻击 %s，造成 %d 点伤害！" % [player_combatant.get("name", "玩家"), _get_combatant_name(target_id), damage])
	elif skill_id == "power_strike":
		var result := _calculate_damage(player_combatant, _get_combatant_by_id(target_id), 1.5)
		damage = result[0]
		is_critical = result[1]
		_deal_damage(target_id, damage, is_critical)
		player_combatant["current_mp"] -= 10
		_log_action("%s 使用 力劈华山，造成 %d 点伤害！" % [player_combatant.get("name", "玩家"), damage])
	
	EventBus.skill_used.emit(skill_id)
	_next_turn()

func player_use_item(item_id: String) -> void:
	if combat_state != Constants.CombatState.PLAYER_TURN:
		return
	
	if item_id == "health_potion":
		var heal_amount := 30
		player_combatant["current_hp"] = min(player_combatant.get("current_hp", 100) + heal_amount, player_combatant.get("max_hp", 100))
		_log_action("%s 使用了金疮药，恢复了 %d 点生命！" % [player_combatant.get("name", "玩家"), heal_amount])
		EventBus.player_hp_changed.emit(player_combatant.get("current_hp", 100), player_combatant.get("max_hp", 100))
	
	_next_turn()

func player_flee() -> bool:
	if combat_state != Constants.CombatState.PLAYER_TURN:
		return false
	
	if Utils.random_chance(0.3):
		_log_action("逃跑成功！")
		end_combat(false, {})
		return true
	_log_action("逃跑失败！")
	_next_turn()
	return false

func _calculate_damage(attacker: Dictionary, defender: Dictionary, multiplier: float = 1.0) -> Array:
	var base_damage: float = attacker.get("attack", 10) * multiplier
	var defense: float = defender.get("defense", 5)
	var damage: int = max(1, int(base_damage - defense * 0.5))
	var is_critical: bool = Utils.random_chance(attacker.get("crit_chance", 0.1))
	
	if is_critical:
		damage = int(damage * 1.5)
	
	return [damage, is_critical]

func _deal_damage(target_id: String, damage: int, is_critical: bool) -> void:
	var target := _get_combatant_by_id(target_id)
	if not target:
		return
	
	target["current_hp"] = max(0, target.get("current_hp", 100) - damage)
	
	combatant_hp_changed.emit(target_id, target.get("current_hp", 100), target.get("max_hp", 100))
	EventBus.damage_dealt.emit(target_id, damage, is_critical)
	
	if target.get("current_hp", 100) <= 0:
		target["is_alive"] = false
		_log_action("%s 被击败了！" % target.get("name", "敌人"))
		_check_victory()

func _heal(target_id: String, amount: int) -> void:
	var target := _get_combatant_by_id(target_id)
	if not target:
		return
	
	target["current_hp"] = min(target.get("current_hp", 100) + amount, target.get("max_hp", 100))
	combatant_hp_changed.emit(target_id, target.get("current_hp", 100), target.get("max_hp", 100))
	EventBus.healing_applied.emit(target_id, amount)

func _get_combatant_by_id(id: String) -> Dictionary:
	if id == "player":
		return player_combatant
	for enemy in enemy_combatants:
		if enemy.get("id", "") == id:
			return enemy
	return {}

func _get_combatant_name(id: String) -> String:
	var combatant := _get_combatant_by_id(id)
	return combatant.get("name", "未知")

func _check_victory() -> void:
	# 检查玩家是否死亡
	if not player_combatant.get("is_alive", true):
		end_combat(false, {})
		return
	
	# 检查是否所有敌人都死亡
	var all_dead := true
	for enemy in enemy_combatants:
		if enemy.get("is_alive", false):
			all_dead = false
			break
	
	if all_dead:
		var rewards := _calculate_rewards()
		end_combat(true, rewards)

func _calculate_rewards() -> Dictionary:
	var total_exp := 0
	var total_gold := 0
	var items := []
	
	for enemy in enemy_combatants:
		total_exp += enemy.get("exp_reward", 50)
		total_gold += enemy.get("gold_reward", 20)
		if Utils.random_chance(0.3):
			items.append("health_potion")
	
	return {
		"exp": total_exp,
		"gold": total_gold,
		"items": items
	}

func _next_turn() -> void:
	if combat_state == Constants.CombatState.INACTIVE:
		return
	
	# 跳过死亡的角色
	var max_tries := turn_order.size()
	var tries := 0
	
	while tries < max_tries:
		current_turn_index = (current_turn_index + 1) % turn_order.size()
		var current_id: String = turn_order[current_turn_index]
		var current := _get_combatant_by_id(current_id)
		
		if current.get("is_alive", true):
			break
		tries += 1
	
	var current_id: String = turn_order[current_turn_index]
	var is_player_turn: bool = current_id == "player"
	
	if is_player_turn:
		combat_state = Constants.CombatState.PLAYER_TURN
		turn_changed.emit(true)
	else:
		combat_state = Constants.CombatState.ENEMY_TURN
		turn_changed.emit(false)
		await get_tree().create_timer(0.5).timeout
		_run_enemy_turn(current_id)

func _run_enemy_turn(enemy_id: String) -> void:
	if combat_state == Constants.CombatState.INACTIVE:
		return
	
	var enemy := _get_combatant_by_id(enemy_id)
	var result := _calculate_damage(enemy, player_combatant)
	var damage: int = result[0]
	var is_critical: bool = result[1]
	_deal_damage("player", damage, is_critical)
	_log_action("%s 攻击 %s，造成 %d 点伤害！" % [enemy.get("name", "敌人"), player_combatant.get("name", "玩家"), damage])
	_next_turn()

func end_combat(victory: bool, rewards: Dictionary) -> void:
	if combat_state == Constants.CombatState.INACTIVE:
		return
	
	combat_state = Constants.CombatState.INACTIVE
	combat_ended.emit(victory, rewards)
	EventBus.combat_ended.emit(victory, rewards)
	
	if victory:
		_log_action("战斗胜利！获得 %d 经验，%d 银两。" % [rewards.get("exp", 0), rewards.get("gold", 0)])
		for item in rewards.get("items", []):
			EventBus.item_picked_up.emit(item, 1)
	else:
		_log_action("战斗失败...")

func _log_action(text: String) -> void:
	combat_log.append(text)

func get_combat_log() -> Array:
	return combat_log.duplicate()

func is_player_turn() -> bool:
	return combat_state == Constants.CombatState.PLAYER_TURN

func is_in_combat() -> bool:
	return combat_state != Constants.CombatState.INACTIVE

func get_player_combatant() -> Dictionary:
	return player_combatant.duplicate()

func get_enemies() -> Array:
	return enemy_combatants.duplicate()
