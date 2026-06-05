extends Node
class_name CombatSystem

signal combat_started(enemy: Dictionary)
signal combat_changed(snapshot: Dictionary)
signal combat_finished(result: Dictionary)

const STATUS_LABELS := {
	"bleed": "流血",
	"poison": "中毒",
	"burn": "灼烧",
	"stun": "眩晕",
	"slow": "迟缓",
	"weaken": "虚弱",
	"vulnerable": "破绽",
	"guard": "守势"
}

const SKILL_PROFILES := {
	"kf_basic_bare": {"mp": 4, "bonus": 6, "variance": 7, "accuracy": 0.90, "crit": 0.05, "status": "vulnerable", "status_chance": 0.16, "status_turns": 1},
	"kf_basic_sword": {"mp": 5, "bonus": 9, "variance": 8, "accuracy": 0.88, "crit": 0.12},
	"kf_basic_blade": {"mp": 6, "bonus": 11, "variance": 10, "accuracy": 0.84, "crit": 0.08, "cooldown": 2, "status": "bleed", "status_chance": 0.22, "status_power": 5, "status_turns": 3},
	"kf_basic_club": {"mp": 5, "bonus": 8, "variance": 9, "accuracy": 0.84, "crit": 0.04, "status": "stun", "status_chance": 0.12, "status_turns": 1},
	"kf_bagua_blade": {"mp": 10, "bonus": 18, "variance": 12, "accuracy": 0.85, "crit": 0.10, "cooldown": 2, "armor_pierce": 0.20, "status": "bleed", "status_chance": 0.30, "status_power": 8, "status_turns": 3},
	"kf_bagua_palm": {"mp": 9, "bonus": 15, "variance": 8, "accuracy": 0.91, "crit": 0.08, "status": "vulnerable", "status_chance": 0.34, "status_turns": 2},
	"kf_bazhen": {"mp": 12, "bonus": 13, "variance": 6, "accuracy": 0.88, "crit": 0.05, "cooldown": 2, "status": "weaken", "status_chance": 0.38, "status_turns": 2},
	"kf_huafei": {"mp": 9, "bonus": 15, "variance": 9, "accuracy": 0.93, "crit": 0.16, "status": "bleed", "status_chance": 0.24, "status_power": 6, "status_turns": 3},
	"kf_huatuan": {"mp": 13, "bonus": 9, "variance": 6, "accuracy": 0.90, "crit": 0.10, "hits": 2, "cooldown": 2, "status": "slow", "status_chance": 0.22, "status_turns": 2},
	"kf_liu": {"mp": 8, "bonus": 13, "variance": 6, "accuracy": 0.95, "crit": 0.10},
	"kf_taiji_sword": {"mp": 11, "bonus": 16, "variance": 7, "accuracy": 0.90, "crit": 0.09, "armor_pierce": 0.18, "status": "vulnerable", "status_chance": 0.28, "status_turns": 2},
	"kf_taiji_fist": {"mp": 10, "bonus": 14, "variance": 5, "accuracy": 0.92, "crit": 0.05, "self_status": "guard", "self_status_turns": 1, "status": "weaken", "status_chance": 0.26, "status_turns": 2},
	"kf_xuanxu": {"mp": 12, "bonus": 18, "variance": 12, "accuracy": 0.84, "crit": 0.14, "cooldown": 2, "status": "bleed", "status_chance": 0.26, "status_power": 7, "status_turns": 3},
	"kf_xueshang": {"mp": 11, "bonus": 15, "variance": 8, "accuracy": 0.88, "crit": 0.08, "status": "slow", "status_chance": 0.38, "status_turns": 2},
	"kf_xueshan_sword": {"mp": 12, "bonus": 20, "variance": 13, "accuracy": 0.85, "crit": 0.16, "cooldown": 2, "status": "bleed", "status_chance": 0.22, "status_power": 8, "status_turns": 3},
	"kf_xueying": {"mp": 12, "bonus": 10, "variance": 8, "accuracy": 0.91, "crit": 0.14, "hits": 2, "status": "bleed", "status_chance": 0.24, "status_power": 6, "status_turns": 3},
	"kf_pifeng": {"mp": 10, "bonus": 18, "variance": 12, "accuracy": 0.84, "crit": 0.11, "cooldown": 2, "status": "bleed", "status_chance": 0.24, "status_power": 7, "status_turns": 3},
	"kf_taizu": {"mp": 8, "bonus": 14, "variance": 8, "accuracy": 0.90, "crit": 0.08, "status": "stun", "status_chance": 0.14, "status_turns": 1},
	"kf_tongji": {"mp": 14, "bonus": 10, "variance": 7, "accuracy": 0.87, "crit": 0.09, "hits": 2, "cooldown": 2, "status": "weaken", "status_chance": 0.30, "status_turns": 2},
	"kf_renshu": {"mp": 10, "bonus": 13, "variance": 9, "accuracy": 0.93, "crit": 0.18, "status": "poison", "status_chance": 0.30, "status_power": 7, "status_turns": 3},
	"kf_wufa": {"mp": 9, "bonus": 12, "variance": 7, "accuracy": 0.95, "crit": 0.10, "status": "slow", "status_chance": 0.36, "status_turns": 2},
	"kf_yidao": {"mp": 16, "bonus": 27, "variance": 16, "accuracy": 0.80, "crit": 0.22, "cooldown": 3, "armor_pierce": 0.30, "status": "bleed", "status_chance": 0.36, "status_power": 10, "status_turns": 3},
	"kf_liuyang": {"mp": 15, "bonus": 23, "variance": 10, "accuracy": 0.88, "crit": 0.12, "cooldown": 2, "status": "burn", "status_chance": 0.34, "status_power": 9, "status_turns": 3}
}

var enemy: Dictionary = {}
var log_lines: Array[String] = []
var combat_events: Array[Dictionary] = []
var player_statuses: Dictionary = {}
var enemy_statuses: Dictionary = {}
var player_cooldowns: Dictionary = {}
var enemy_flags: Dictionary = {}
var event_index := 0
var turn_count := 1
var active := false

func start(enemy_data: Dictionary) -> void:
	enemy = enemy_data.duplicate(true)
	enemy["hp"] = int(enemy.get("hp", enemy.get("max_hp", 50)))
	enemy["max_hp"] = max(1, int(enemy.get("max_hp", enemy.get("hp", 50))))
	enemy["mp"] = int(enemy.get("mp", enemy.get("max_mp", 0)))
	enemy["max_mp"] = int(enemy.get("max_mp", enemy.get("mp", 0)))
	log_lines = ["%s 拦住了去路。" % str(enemy.get("name", "敌人"))]
	combat_events.clear()
	player_statuses.clear()
	enemy_statuses.clear()
	player_cooldowns.clear()
	enemy_flags.clear()
	event_index = 0
	turn_count = 1
	active = true
	GameState.set_mode(GameState.Mode.COMBAT)
	combat_started.emit(enemy)
	combat_changed.emit(snapshot())

func player_attack(skill_id: String = "normal") -> void:
	if not active:
		return
	if skill_id == "force":
		_player_focus()
		return
	if not _process_turn_start("player"):
		if active:
			_enemy_turn()
		return

	var normalized_skill_id := _normalize_skill_id(skill_id)
	var level := 0
	if normalized_skill_id != "normal":
		if not GameData.is_attack_skill(normalized_skill_id):
			_append_log("%s 暂不能作为战斗招式。" % GameData.get_skill_name(normalized_skill_id))
			combat_changed.emit(snapshot())
			return
		level = int(GameState.learned_skills.get(normalized_skill_id, 0))
		if level <= 0:
			_append_log("你还没有掌握%s。" % GameData.get_skill_name(normalized_skill_id))
			combat_changed.emit(snapshot())
			return
		var cooldown := int(player_cooldowns.get(normalized_skill_id, 0))
		if cooldown > 0:
			_append_log("%s 还需要 %d 回合调匀气息。" % [GameData.get_skill_name(normalized_skill_id), cooldown])
			combat_changed.emit(snapshot())
			return

	var profile := _skill_profile(normalized_skill_id, level)
	var mp_cost := int(profile.get("mp", 0))
	if mp_cost > 0 and not GameState.spend_mp(mp_cost):
		_append_log("内力不足，招式使不出来。")
		combat_changed.emit(snapshot())
		return

	var skill_name := str(profile.get("name", "普通攻击"))
	var hit_chance := _player_hit_chance(profile, level)
	if randf() > hit_chance:
		_append_log("你使出%s，被%s避开。" % [skill_name, str(enemy.get("name", "敌人"))])
		_record_event("enemy", "miss", 0, "未中", skill_name)
		_set_cooldown(normalized_skill_id, int(profile.get("cooldown", 0)))
		_tick_cooldowns()
		_enemy_turn()
		return

	var hits: int = maxi(1, int(profile.get("hits", 1)))
	var total_damage := 0
	var crit_count := 0
	for _hit_index in range(hits):
		var damage := _player_hit_damage(profile, level)
		if randf() < _player_crit_chance(profile, level):
			damage = int(ceil(float(damage) * 1.55))
			crit_count += 1
		total_damage += damage
	enemy["hp"] = max(0, int(enemy.get("hp", 0)) - total_damage)
	var level_text := " Lv.%d" % level if level > 0 else ""
	var crit_text := "，会心 %d 次" % crit_count if crit_count > 0 else ""
	var hit_text := "，连击 %d 段" % hits if hits > 1 else ""
	_append_log("你使出%s%s%s，造成 %d 点伤害%s。" % [skill_name, level_text, hit_text, total_damage, crit_text])
	_record_event("enemy", "damage", total_damage, "-%d" % total_damage, skill_name)
	_apply_profile_status(profile, level, enemy_statuses, str(enemy.get("name", "敌人")))
	_apply_profile_self_status(profile)
	_set_cooldown(normalized_skill_id, int(profile.get("cooldown", 0)))

	if int(enemy.get("hp", 0)) <= 0:
		_finish(true)
		return

	_tick_cooldowns()
	_enemy_turn()

func flee() -> void:
	if not active:
		return
	var dodge_level := int(GameState.learned_skills.get("kf_basic_dodge", 1))
	var chance := clampf(0.52 + float(dodge_level) * 0.01 + float(GameState.player.get("dexterity", 15)) * 0.006, 0.45, 0.86)
	if player_statuses.has("slow"):
		chance -= 0.18
	if randf() < chance:
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
		"active": active,
		"player_statuses": player_statuses.duplicate(true),
		"enemy_statuses": enemy_statuses.duplicate(true),
		"player_status_text": _status_text(player_statuses),
		"enemy_status_text": _status_text(enemy_statuses),
		"cooldowns": player_cooldowns.duplicate()
	}

func _player_focus() -> void:
	if int(player_cooldowns.get("force", 0)) > 0:
		_append_log("调息还需要 %d 回合。" % int(player_cooldowns.get("force", 0)))
		combat_changed.emit(snapshot())
		return
	if not _process_turn_start("player"):
		if active:
			_enemy_turn()
		return
	var hp_gain := GameState.heal_player(10 + int(GameState.learned_skills.get("kf_basic_force", 1)) * 3)
	var mp_gain := GameState.restore_mp(14 + int(GameState.learned_skills.get("kf_basic_force", 1)) * 4)
	_add_status(player_statuses, "guard", 1, 0)
	_append_log("你调匀内息，恢复气血 %d、内力 %d，并摆出守势。" % [hp_gain, mp_gain])
	_record_event("player", "heal", hp_gain, "气血 +%d" % hp_gain)
	_record_event("player", "mp", mp_gain, "内力 +%d" % mp_gain)
	player_cooldowns["force"] = 2
	_tick_cooldowns()
	_enemy_turn()

func _enemy_turn() -> void:
	if not active:
		return
	if not _process_turn_start("enemy"):
		if active:
			turn_count += 1
			combat_changed.emit(snapshot())
		return
	_maybe_enter_boss_phase()
	if not active:
		return
	var action := _choose_enemy_action()
	match str(action.get("kind", "attack")):
		"heal":
			_enemy_heal(action)
		"guard":
			_enemy_guard(action)
		_:
			_enemy_attack(action)
	if not active:
		return
	turn_count += 1
	combat_changed.emit(snapshot())

func _choose_enemy_action() -> Dictionary:
	var style := str(enemy.get("combat_style", ""))
	if style.is_empty():
		style = _infer_enemy_style()
	var level := int(enemy.get("level", 1))
	var hp_ratio := float(enemy.get("hp", 1)) / float(max(1, int(enemy.get("max_hp", 1))))
	if hp_ratio <= 0.28 and int(enemy.get("mp", 0)) >= 12 and not bool(enemy_flags.get("healed", false)):
		return {"kind": "heal", "name": "吞药回气", "mp": 12, "amount": 24 + level * 4}
	if style == "boss" and turn_count % 4 == 0:
		return {"kind": "guard", "name": "凝神蓄势"}
	if style == "assassin":
		return {"kind": "attack", "name": "暗影连刺", "bonus": 5 + level, "hits": 2, "accuracy": 0.90, "status": "poison", "status_chance": 0.28, "status_power": 6 + int(level * 0.25), "status_turns": 3}
	if style == "beast":
		return {"kind": "attack", "name": "猛扑撕咬", "bonus": 4 + int(level * 0.7), "accuracy": 0.84, "status": "bleed", "status_chance": 0.24, "status_power": 5 + int(level * 0.2), "status_turns": 3}
	if style == "brute" or style == "bandit_boss":
		if turn_count % 3 == 0:
			return {"kind": "attack", "name": "重劈", "bonus": 8 + level, "accuracy": 0.78, "crit": 0.16, "status": "stun", "status_chance": 0.14, "status_turns": 1}
		return {"kind": "attack", "name": "蛮横挥击", "bonus": 4 + int(level * 0.5), "accuracy": 0.84}
	if style == "boss":
		return {"kind": "attack", "name": "连环杀招", "bonus": 8 + level, "hits": 2 if turn_count % 3 == 0 else 1, "accuracy": 0.86, "crit": 0.14, "status": "burn", "status_chance": 0.22, "status_power": 7 + int(level * 0.2), "status_turns": 3}
	return {"kind": "attack", "name": "反击", "bonus": 2 + int(level * 0.35), "accuracy": 0.86}

func _enemy_attack(action: Dictionary) -> void:
	var hits: int = maxi(1, int(action.get("hits", 1)))
	var total_damage := 0
	var any_hit := false
	var action_name := str(action.get("name", "反击"))
	for _index in range(hits):
		if randf() > _enemy_hit_chance(action):
			continue
		any_hit = true
		var damage := _enemy_hit_damage(action)
		if randf() < float(action.get("crit", 0.05)):
			damage = int(ceil(float(damage) * 1.45))
		total_damage += damage
	if not any_hit:
		_append_log("%s使出%s，被你避开。" % [str(enemy.get("name", "敌人")), action_name])
		_record_event("player", "miss", 0, "未中", action_name)
		return
	var actual := GameState.damage_player(total_damage)
	_append_log("%s使出%s，造成 %d 点伤害。" % [str(enemy.get("name", "敌人")), action_name, actual])
	_record_event("player", "damage", actual, "-%d" % actual, action_name)
	_apply_enemy_status(action)

	if int(GameState.player.get("hp", 0)) <= 0:
		_finish(false)

func _enemy_heal(action: Dictionary) -> void:
	var cost := int(action.get("mp", 0))
	enemy["mp"] = max(0, int(enemy.get("mp", 0)) - cost)
	var max_hp := int(enemy.get("max_hp", 1))
	var amount: int = mini(int(action.get("amount", 20)), max_hp - int(enemy.get("hp", 0)))
	enemy["hp"] = int(enemy.get("hp", 0)) + max(0, amount)
	enemy_flags["healed"] = true
	_append_log("%s%s，恢复 %d 点气血。" % [str(enemy.get("name", "敌人")), str(action.get("name", "回气")), amount])
	_record_event("enemy", "heal", amount, "+%d" % amount, str(action.get("name", "回气")))

func _enemy_guard(action: Dictionary) -> void:
	_add_status(enemy_statuses, "guard", 1, 0)
	_append_log("%s%s，下一回合防守更严。" % [str(enemy.get("name", "敌人")), str(action.get("name", "守势"))])
	_record_event("enemy", "guard", 0, "守势", str(action.get("name", "守势")))

func _maybe_enter_boss_phase() -> void:
	var style := str(enemy.get("combat_style", ""))
	var max_hp := int(enemy.get("max_hp", 1))
	var hp_ratio := float(enemy.get("hp", 1)) / float(max(1, max_hp))
	var is_boss := style == "boss" or max_hp >= 500 or bool(enemy.get("has_quests", false))
	if not is_boss or bool(enemy_flags.get("phase_two", false)) or hp_ratio > 0.50:
		return
	enemy_flags["phase_two"] = true
	enemy["attack"] = int(enemy.get("attack", enemy.get("damage", 8))) + max(4, int(enemy.get("level", 1) * 0.35))
	_add_status(enemy_statuses, "guard", 1, 0)
	_append_log("%s气势陡变，攻势更急。" % str(enemy.get("name", "敌人")))
	_record_event("enemy", "phase", 0, "二阶段", str(enemy.get("name", "敌人")))

func _process_turn_start(actor: String) -> bool:
	var statuses: Dictionary = player_statuses if actor == "player" else enemy_statuses
	var target_name := "你" if actor == "player" else str(enemy.get("name", "敌人"))
	for status_id in ["bleed", "poison", "burn"]:
		if not statuses.has(status_id):
			continue
		var status: Dictionary = statuses.get(status_id, {})
		var damage: int = maxi(1, int(status.get("power", 4)))
		if actor == "player":
			damage = GameState.damage_player(damage)
			_record_event("player", "damage", damage, "-%d" % damage, _status_label(status_id))
		else:
			enemy["hp"] = max(0, int(enemy.get("hp", 0)) - damage)
			_record_event("enemy", "damage", damage, "-%d" % damage, _status_label(status_id))
		_append_log("%s受%s影响，损失 %d 点气血。" % [target_name, _status_label(status_id), damage])
		_decrement_status(statuses, status_id)
		if actor == "player" and int(GameState.player.get("hp", 0)) <= 0:
			_finish(false)
			return false
		if actor == "enemy" and int(enemy.get("hp", 0)) <= 0:
			_finish(true)
			return false
	if statuses.has("stun"):
		statuses.erase("stun")
		_append_log("%s被眩晕牵制，错过行动。" % target_name)
		_record_event(actor, "stun", 0, "眩晕", "")
		return false
	return true

func _player_hit_damage(profile: Dictionary, level: int) -> int:
	var player := GameState.player
	var base_attack := int(player.get("attack", 12))
	var defense := int(enemy.get("defense", 0))
	var pierce := clampf(float(profile.get("armor_pierce", 0.0)), 0.0, 0.8)
	var effective_defense := int(float(defense) * (1.0 - pierce))
	var variance: int = int(profile.get("variance", 7)) + mini(12, int(level / 5))
	var bonus := int(profile.get("bonus", 0)) + int(float(level) * float(profile.get("level_scale", 0.45)))
	var damage := int(max(1, base_attack + bonus + randi_range(0, max(1, variance)) - int(float(effective_defense) * 0.45)))
	if player_statuses.has("weaken"):
		damage = max(1, int(float(damage) * 0.75))
		_decrement_status(player_statuses, "weaken")
	if enemy_statuses.has("vulnerable"):
		damage = max(1, int(float(damage) * 1.25))
		_decrement_status(enemy_statuses, "vulnerable")
	if enemy_statuses.has("guard"):
		damage = max(1, int(float(damage) * 0.55))
		_decrement_status(enemy_statuses, "guard")
	return damage

func _enemy_hit_damage(action: Dictionary) -> int:
	var player_defense := int(GameState.player.get("defense", 6))
	var enemy_attack := int(enemy.get("attack", enemy.get("damage", 5)))
	var bonus := int(action.get("bonus", 0))
	var damage := int(max(1, enemy_attack + bonus + randi_range(0, 6) - int(float(player_defense) * 0.42)))
	if enemy_statuses.has("weaken"):
		damage = max(1, int(float(damage) * 0.75))
		_decrement_status(enemy_statuses, "weaken")
	if player_statuses.has("guard"):
		damage = max(1, int(float(damage) * 0.55))
		_decrement_status(player_statuses, "guard")
	return damage

func _player_hit_chance(profile: Dictionary, level: int) -> float:
	var chance := float(profile.get("accuracy", 0.88))
	chance += float(GameState.player.get("dexterity", 15)) * 0.004
	chance += min(0.12, float(level) * 0.0025)
	chance -= float(enemy.get("level", 1)) * 0.003
	if player_statuses.has("slow"):
		chance -= 0.12
		_decrement_status(player_statuses, "slow")
	return clampf(chance, 0.55, 0.97)

func _enemy_hit_chance(action: Dictionary) -> float:
	var chance := float(action.get("accuracy", 0.86))
	chance += float(enemy.get("level", 1)) * 0.002
	chance -= float(GameState.player.get("dexterity", 15)) * 0.003
	if enemy_statuses.has("slow"):
		chance -= 0.14
		_decrement_status(enemy_statuses, "slow")
	return clampf(chance, 0.48, 0.94)

func _player_crit_chance(profile: Dictionary, level: int) -> float:
	return clampf(float(profile.get("crit", 0.05)) + min(0.18, float(level) * 0.003), 0.02, 0.35)

func _apply_profile_status(profile: Dictionary, level: int, target_statuses: Dictionary, target_name: String) -> void:
	var status_id := str(profile.get("status", ""))
	if status_id.is_empty():
		return
	var chance: float = float(profile.get("status_chance", 0.0)) + minf(0.14, float(level) * 0.002)
	if randf() > chance:
		return
	var turns: int = maxi(1, int(profile.get("status_turns", 2)))
	var power := int(profile.get("status_power", 4 + int(level * 0.18)))
	_add_status(target_statuses, status_id, turns, power)
	_append_log("%s陷入%s。" % [target_name, _status_label(status_id)])

func _apply_profile_self_status(profile: Dictionary) -> void:
	var status_id := str(profile.get("self_status", ""))
	if status_id.is_empty():
		return
	_add_status(player_statuses, status_id, max(1, int(profile.get("self_status_turns", 1))), int(profile.get("self_status_power", 0)))
	_append_log("你进入%s。" % _status_label(status_id))

func _apply_enemy_status(action: Dictionary) -> void:
	var status_id := str(action.get("status", ""))
	if status_id.is_empty():
		return
	if randf() > float(action.get("status_chance", 0.0)):
		return
	_add_status(player_statuses, status_id, max(1, int(action.get("status_turns", 2))), int(action.get("status_power", 4)))
	_append_log("你陷入%s。" % _status_label(status_id))

func _skill_profile(skill_id: String, level: int) -> Dictionary:
	if skill_id == "normal":
		return {"name": "普通攻击", "mp": 0, "bonus": 0, "variance": 6, "accuracy": 0.88, "crit": 0.04}
	var profile: Dictionary = SKILL_PROFILES.get(skill_id, {}).duplicate(true)
	if profile.is_empty():
		profile = {"mp": 5 + min(18, int(level / 8)), "bonus": 8 + int(level * 0.45), "variance": 8, "accuracy": 0.88, "crit": 0.08}
	profile["name"] = GameData.get_skill_name(skill_id)
	return profile

func _normalize_skill_id(skill_id: String) -> String:
	if skill_id == "bare":
		return "kf_basic_bare"
	return skill_id

func _infer_enemy_style() -> String:
	var name := str(enemy.get("name", ""))
	var personality := str(enemy.get("personality", ""))
	if name.contains("豹") or personality.contains("野兽"):
		return "beast"
	if name.contains("黑衣") or name.contains("采花") or personality.contains("阴"):
		return "assassin"
	if name.contains("头") or name.contains("大盗") or personality.contains("残暴"):
		return "brute"
	if int(enemy.get("max_hp", 0)) >= 500:
		return "boss"
	return "brawler"

func _add_status(statuses: Dictionary, status_id: String, turns: int, power: int) -> void:
	var current: Dictionary = statuses.get(status_id, {})
	current["turns"] = max(int(current.get("turns", 0)), turns)
	current["power"] = max(int(current.get("power", 0)), power)
	statuses[status_id] = current

func _decrement_status(statuses: Dictionary, status_id: String) -> void:
	if not statuses.has(status_id):
		return
	var current: Dictionary = statuses.get(status_id, {})
	current["turns"] = int(current.get("turns", 1)) - 1
	if int(current.get("turns", 0)) <= 0:
		statuses.erase(status_id)
	else:
		statuses[status_id] = current

func _status_text(statuses: Dictionary) -> String:
	var parts: Array[String] = []
	for status_id in statuses.keys():
		var status: Dictionary = statuses[status_id]
		parts.append("%s%d" % [_status_label(str(status_id)), int(status.get("turns", 1))])
	if parts.is_empty():
		return "无"
	return " / ".join(parts)

func _status_label(status_id: String) -> String:
	return str(STATUS_LABELS.get(status_id, status_id))

func _set_cooldown(skill_id: String, cooldown: int) -> void:
	if skill_id == "normal" or cooldown <= 0:
		return
	player_cooldowns[skill_id] = max(int(player_cooldowns.get(skill_id, 0)), cooldown)

func _tick_cooldowns() -> void:
	var expired: Array[String] = []
	for skill_id in player_cooldowns.keys():
		player_cooldowns[skill_id] = int(player_cooldowns[skill_id]) - 1
		if int(player_cooldowns[skill_id]) <= 0:
			expired.append(str(skill_id))
	for skill_id in expired:
		player_cooldowns.erase(skill_id)

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
		var loot_parts := GameState.grant_enemy_loot(enemy)
		var loot_text := ""
		if not loot_parts.is_empty():
			loot_text = "，掉落：%s" % "、".join(loot_parts)
		_append_log("战斗胜利，获得经验 %d、银两 %d%s。" % [exp_reward, money_reward, loot_text])
	elif escaped:
		pass
	else:
		_append_log("你败下阵来，被送回客栈休养。")
		GameState.heal_player(int(GameState.player.get("max_hp", 120)))
		GameState.restore_mp(int(GameState.player.get("max_mp", 60)))
		GameState.advance_hours(4.0)

	active = false
	player_statuses.clear()
	enemy_statuses.clear()
	player_cooldowns.clear()
	GameState.set_mode(GameState.Mode.EXPLORE)
	combat_changed.emit(snapshot())
	combat_finished.emit(result)

func _append_log(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > 7:
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
	while combat_events.size() > 10:
		combat_events.pop_front()
