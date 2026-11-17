extends Node
class_name AchievementSystem

## 成就/图鉴系统 — 跟踪玩家进度，解锁成就

signal achievement_unlocked(achievement_id: String, achievement_name: String)
signal achievement_progress_changed(achievement_id: String, progress: int, needed: int)

var achievements: Dictionary = {}
var unlocked: Array = []
var progress: Dictionary = {}

# 跟踪数据
var kill_count: int = 0
var elite_kills: int = 0
var boss_kills: int = 0
var discovered_regions: Array = []
var quests_completed_count: int = 0
var collected_items: Array = []
var total_money_earned: int = 0
var start_money: int = 0

func _ready() -> void:
	_load_achievements()
	_reset_tracking()

func _load_achievements() -> void:
	var file := FileAccess.open("res://data/achievements.json", FileAccess.READ)
	if file == null:
		push_error("AchievementSystem: cannot open achievements.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("AchievementSystem: achievements.json is not an array")
		return
	for ach in parsed:
		if typeof(ach) == TYPE_DICTIONARY:
			var aid := str(ach.get("id", ""))
			if not aid.is_empty():
				achievements[aid] = ach

func get_all_achievements() -> Dictionary:
	return achievements.duplicate(true)

func get_achievement(id: String) -> Dictionary:
	return achievements.get(id, {}).duplicate(true)

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func get_unlocked() -> Array:
	return unlocked.duplicate()

func get_progress(id: String) -> int:
	return progress.get(id, 0)

func load_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	unlocked = data.get("unlocked", []).duplicate()
	progress = data.get("progress", {}).duplicate()
	kill_count = int(data.get("kill_count", 0))
	elite_kills = int(data.get("elite_kills", 0))
	boss_kills = int(data.get("boss_kills", 0))
	discovered_regions = data.get("discovered_regions", []).duplicate()
	quests_completed_count = int(data.get("quests_completed_count", 0))
	collected_items = data.get("collected_items", []).duplicate()
	total_money_earned = int(data.get("total_money_earned", 0))

func save_state() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(),
		"progress": progress.duplicate(),
		"kill_count": kill_count,
		"elite_kills": elite_kills,
		"boss_kills": boss_kills,
		"discovered_regions": discovered_regions.duplicate(),
		"quests_completed_count": quests_completed_count,
		"collected_items": collected_items.duplicate(),
		"total_money_earned": total_money_earned
	}

func _reset_tracking() -> void:
	start_money = int(GameState.player.get("money", 0))

## 外部接口 — 各类系统通过此方法通知成就跟踪
func notify_event(event_type: String, value = 1, target: String = "") -> void:
	match event_type:
		"kill":
			kill_count += value
			_check_combat_achievements()
		"kill_elite":
			elite_kills += value
			_check_combat_achievements()
		"kill_boss":
			boss_kills += value
			_check_combat_achievements()
		"region_discover":
			if not discovered_regions.has(target):
				discovered_regions.append(target)
			_check_explore_achievements()
		"quest_complete":
			quests_completed_count += value
			_check_quest_achievements()
		"item_collect":
			if not collected_items.has(target):
				collected_items.append(target)
			_check_collect_achievements()
		"story_complete":
			_check_story_achievements(target)
		"player_level_up":
			_check_character_achievements()
		"skill_learned":
			_check_character_achievements()
		"money_change":
			total_money_earned = max(total_money_earned, int(GameState.player.get("money", 0)))
			_check_collect_achievements()
		"equip_full":
			_check_character_achievements()
		_:
			_check_story_achievements(str(value))

func _check_combat_achievements() -> void:
	var checks := [
		{"id": "ach_kill_10", "val": kill_count},
		{"id": "ach_kill_50", "val": kill_count},
		{"id": "ach_kill_100", "val": kill_count},
		{"id": "ach_kill_elite", "val": elite_kills},
		{"id": "ach_kill_boss", "val": boss_kills},
		{"id": "ach_defeat_snake", "val": 1 if _is_flag("defeated_snake_king") else 0},
		{"id": "ach_defeat_blaze", "val": 1 if _is_flag("defeated_blaze") else 0}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

func _check_explore_achievements() -> void:
	var discovered_count := discovered_regions.size()
	var checks := [
		{"id": "ach_explore_5", "val": discovered_count},
		{"id": "ach_explore_15", "val": discovered_count},
		{"id": "ach_explore_30", "val": discovered_count}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

	# Check all_cities
	var cities := ["luoyang", "changan", "linan", "chengdu", "qinghe"]
	var all_found := true
	for city in cities:
		if not discovered_regions.has(city):
			all_found = false
			break
	if all_found:
		_try_unlock("ach_explore_all_cities", 1)

func _check_quest_achievements() -> void:
	var checks := [
		{"id": "ach_quest_5", "val": quests_completed_count},
		{"id": "ach_quest_15", "val": quests_completed_count},
		{"id": "ach_quest_30", "val": quests_completed_count}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

func _check_collect_achievements() -> void:
	var items_count := collected_items.size()
	var checks := [
		{"id": "ach_collect_10", "val": items_count},
		{"id": "ach_collect_30", "val": items_count},
		{"id": "ach_collect_60", "val": items_count},
		{"id": "ach_money_1000", "val": total_money_earned},
		{"id": "ach_money_5000", "val": total_money_earned}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

func _check_story_achievements(quest_id: String) -> void:
	var completed := GameState.completed_quests
	var checks := [
		{"id": "ach_story_intro", "val": 1 if completed.has("q_intro_town") else 0},
		{"id": "ach_story_thugs", "val": 1 if completed.has("q_clear_thugs") else 0},
		{"id": "ach_story_flower", "val": 1 if completed.has("q_flower_thief") else 0},
		{"id": "ach_story_trial", "val": 1 if completed.has("q_hero_trial") else 0},
		{"id": "ach_faction_join", "val": 1 if _is_flag("joined_sect") else 0},
		{"id": "ach_sect_contribute_500", "val": _get_sect_contrib()},
		{"id": "ach_pet_get", "val": 1 if _has_pet() else 0},
		{"id": "ach_pet_level_5", "val": _get_max_pet_level()}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

func _check_character_achievements() -> void:
	var player := GameState.player
	var level := int(player.get("level", 1))
	var skill_count := GameState.learned_skills.size()
	var daode := int(player.get("daode", 0))
	var has_weapon := not str(GameState.equipment.get("weapon", "")).is_empty()
	var has_armor := not str(GameState.equipment.get("armor", "")).is_empty()
	var checks := [
		{"id": "ach_level_5", "val": level},
		{"id": "ach_level_10", "val": level},
		{"id": "ach_level_20", "val": level},
		{"id": "ach_skill_5", "val": skill_count},
		{"id": "ach_skill_15", "val": skill_count},
		{"id": "ach_daode_50", "val": daode},
		{"id": "ach_equip_full", "val": 1 if has_weapon and has_armor else 0}
	]
	for check in checks:
		_try_unlock(str(check["id"]), int(check["val"]))

func _try_unlock(ach_id: String, current_value: int) -> void:
	if unlocked.has(ach_id):
		return
	var ach: Dictionary = achievements.get(ach_id, {})
	if ach.is_empty():
		return
	var needed := int(ach.get("count", 1))
	progress[ach_id] = current_value
	achievement_progress_changed.emit(ach_id, current_value, needed)
	if current_value >= needed:
		_unlock(ach_id, ach)

func _unlock(ach_id: String, ach: Dictionary) -> void:
	unlocked.append(ach_id)
	var name_str := str(ach.get("name", ach_id))
	EventBus.emit_toast("🏆 成就解锁：「%s」" % name_str)
	achievement_unlocked.emit(ach_id, name_str)
	_grant_reward(ach.get("reward", {}))

func _grant_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		return
	var exp := int(reward.get("exp", 0))
	var money := int(reward.get("money", 0))
	var item := str(reward.get("item", ""))
	if exp > 0 or money > 0:
		GameState.reward_player(exp, money)
	if not item.is_empty():
		GameState.add_item(item, 1)

func _is_flag(flag: String) -> bool:
	return bool(GameState.game_flags.get(flag, false))

func _get_sect_contrib() -> int:
	var sect_system := get_node_or_null("/root/SectSystem")
	if sect_system != null:
		return sect_system.contribution
	return 0

func _has_pet() -> bool:
	var pet_system := get_node_or_null("/root/PetSystem")
	if pet_system != null:
		return pet_system.has_pets()
	return false

func _get_max_pet_level() -> int:
	var pet_system := get_node_or_null("/root/PetSystem")
	if pet_system != null:
		return pet_system.get_max_level()
	return 0

## 图鉴数据
func get_discovered_region_count() -> int:
	return discovered_regions.size()

func get_all_npc_names() -> Array:
	var npcs = []
	var file := FileAccess.open("res://data/npcs.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_ARRAY:
			for npc in parsed:
				if typeof(npc) == TYPE_DICTIONARY:
					npcs.append(str(npc.get("name", "")))
	return npcs

func get_all_item_names() -> Array:
	var items = []
	var file := FileAccess.open("res://data/items.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_ARRAY:
			for item in parsed:
				if typeof(item) == TYPE_DICTIONARY:
					items.append(str(item.get("name", "")))
	return items

func try_conditional_unlock(ach_id: String, value: int) -> void:
	_try_unlock(ach_id, value)
