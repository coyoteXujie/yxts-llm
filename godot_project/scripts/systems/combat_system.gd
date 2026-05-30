extends Node
class_name CombatSystem

signal combat_started(enemy: Dictionary)
signal combat_changed(snapshot: Dictionary)
signal combat_finished(result: Dictionary)

var enemy: Dictionary = {}
var log_lines: Array[String] = []
var combat_events: Array[Dictionary] = []
var event_index := 0
var active := false

func start(enemy_data: Dictionary) -> void:
	enemy = enemy_data.duplicate(true)
	enemy["hp"] = int(enemy.get("hp", enemy.get("max_hp", 50)))
	enemy["max_hp"] = int(enemy.get("max_hp", enemy.get("hp", 50)))
	log_lines = ["%s 拦住了去路。" % str(enemy.get("name", "敌人"))]
	combat_events.clear()
	event_index = 0
	active = true
	GameState.set_mode(GameState.Mode.COMBAT)
	combat_started.emit(enemy)
	combat_changed.emit(snapshot())

func player_attack(skill_id: String = "normal") -> void:
	if not active:
		return

	var skill_name := "普通攻击"
	var mp_cost := 0
	var bonus := 0
	var level := 0
	match skill_id:
		"bare":
			skill_name = "基本拳脚"
			mp_cost = 4
			bonus = 6
		"force":
			skill_name = "调息"
			GameState.restore_mp(12)
			GameState.heal_player(8)
			_append_log("你调匀内息，恢复少许气血。")
			_record_event("player", "heal", 8, "气血 +8")
			_record_event("player", "mp", 12, "内力 +12")
			_enemy_turn()
			return
		_:
			if skill_id != "normal":
				if not GameData.is_attack_skill(skill_id):
					_append_log("%s 暂不能作为战斗招式。" % GameData.get_skill_name(skill_id))
					combat_changed.emit(snapshot())
					return
				level = int(GameState.learned_skills.get(skill_id, 0))
				if level <= 0:
					_append_log("你还没有掌握%s。" % GameData.get_skill_name(skill_id))
					combat_changed.emit(snapshot())
					return
				skill_name = GameData.get_skill_name(skill_id)
				mp_cost = 5 + min(18, int(level / 8))
				bonus = 8 + int(level * 0.45)

	if mp_cost > 0 and not GameState.spend_mp(mp_cost):
		_append_log("内力不足，招式使不出来。")
		combat_changed.emit(snapshot())
		return

	var player := GameState.player
	var base_attack := int(player.get("attack", 12))
	var defense := int(enemy.get("defense", 0))
	var variance: int = 7 + min(10, int(level / 5))
	var damage: int = int(max(1, base_attack + bonus + randi_range(0, variance) - int(defense * 0.45)))
	enemy["hp"] = max(0, int(enemy.get("hp", 0)) - damage)
	if level > 0:
		_append_log("你使出%s Lv.%d，造成 %d 点伤害。" % [skill_name, level, damage])
	else:
		_append_log("你使出%s，造成 %d 点伤害。" % [skill_name, damage])
	_record_event("enemy", "damage", damage, "-%d" % damage, skill_name)

	if int(enemy.get("hp", 0)) <= 0:
		_finish(true)
		return

	_enemy_turn()

func flee() -> void:
	if not active:
		return
	if randf() < 0.65:
		_append_log("你抽身后撤，脱离了战斗。")
		_finish(false, true)
	else:
		_append_log("你试图脱身，但被对方缠住。")
		_enemy_turn()

func snapshot() -> Dictionary:
	return {
		"enemy": enemy,
		"log": log_lines.duplicate(),
		"events": combat_events.duplicate(true),
		"active": active
	}

func _enemy_turn() -> void:
	if not active:
		return
	var player_defense := int(GameState.player.get("defense", 6))
	var enemy_attack := int(enemy.get("attack", enemy.get("damage", 5)))
	var damage: int = int(max(1, enemy_attack + randi_range(0, 5) - int(player_defense * 0.4)))
	var actual: int = GameState.damage_player(damage)
	_append_log("%s 反击，造成 %d 点伤害。" % [str(enemy.get("name", "敌人")), actual])
	_record_event("player", "damage", actual, "-%d" % actual, str(enemy.get("name", "敌人")))

	if int(GameState.player.get("hp", 0)) <= 0:
		_finish(false)
		return

	combat_changed.emit(snapshot())

func _finish(victory: bool, escaped: bool = false) -> void:
	var result := {
		"victory": victory,
		"escaped": escaped,
		"enemy": enemy
	}
	if victory:
		var exp_reward := int(enemy.get("exp_reward", 10))
		var money_reward := int(enemy.get("money", 0))
		GameState.reward_player(exp_reward, money_reward)
		GameState.progress_quest("kill", str(enemy.get("name", "")), 1)
		_append_log("战斗胜利，获得经验 %d、银两 %d。" % [exp_reward, money_reward])
	elif escaped:
		pass
	else:
		_append_log("你败下阵来，被送回客栈休养。")
		GameState.heal_player(int(GameState.player.get("max_hp", 120)))

	active = false
	GameState.set_mode(GameState.Mode.EXPLORE)
	combat_changed.emit(snapshot())
	combat_finished.emit(result)

func _append_log(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > 6:
		log_lines.pop_front()

func _record_event(target: String, kind: String, amount: int, label: String, source: String = "") -> void:
	event_index += 1
	combat_events.append({
		"id": event_index,
		"target": target,
		"kind": kind,
		"amount": amount,
		"label": label,
		"source": source
	})
	while combat_events.size() > 8:
		combat_events.pop_front()
