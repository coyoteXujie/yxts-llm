extends Node

enum Mode {
	MENU,
	CHARACTER_CREATION,
	EXPLORE,
	DIALOGUE,
	COMBAT,
	INVENTORY,
	JOURNAL,
	SHOP,
	CULTIVATION,
	MAP
}

var mode: Mode = Mode.EXPLORE
var player: Dictionary = {}
var inventory: Dictionary = {}
var equipment: Dictionary = {}
var learned_skills: Dictionary = {}
var active_quests: Dictionary = {}
var completed_quests: Array = []
var defeated_enemies: Array = []
var game_flags: Dictionary = {}
var region_state: Dictionary = {}
var active_quest: String = "初入平安镇"
var day := 1
var hour := 8.0
var weather := "晴朗"
var player_position := Vector2.ZERO
var current_region_id := ""
var current_region_name := "未知之地"
var current_tile := Vector2i.ZERO

const SAVE_PATH := "user://savegame.json"

func _ready() -> void:
	new_game()

func new_game(config: Dictionary = {}) -> void:
	var strength := int(config.get("strength", 15))
	var dexterity := int(config.get("dexterity", 15))
	var intelligence := int(config.get("intelligence", 15))
	var constitution := int(config.get("constitution", 15))
	player = {
		"name": str(config.get("name", "少侠")),
		"gender": str(config.get("gender", "male")),
		"level": 1,
		"exp": 0,
		"exp_next": 200,
		"pot": 20,
		"strength": strength,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"constitution": constitution,
		"hp": 70 + constitution * 4,
		"max_hp": 70 + constitution * 4,
		"mp": 25 + intelligence * 3,
		"max_mp": 25 + intelligence * 3,
		"attack": 6 + strength,
		"defense": 3 + int(dexterity * 0.6),
		"money": 100,
		"daode": 0,
		"faction": str(config.get("faction", "none"))
	}
	inventory = {
		"item_baozi": 2,
		"item_yao": 1
	}
	equipment = {
		"weapon": "",
		"armor": ""
	}
	learned_skills = {
		"kf_basic_bare": 1,
		"kf_basic_dodge": 1,
		"kf_basic_force": 1,
		"kf_basic_parry": 1
	}
	var start_faction := str(player.get("faction", "none"))
	if start_faction != "none":
		var start_skills := GameData.get_faction_skills(start_faction)
		if not start_skills.is_empty():
			learned_skills[str(start_skills[0])] = 1
	active_quests = {}
	completed_quests = []
	defeated_enemies = []
	game_flags = {}
	region_state = {}
	active_quest = "初入平安镇"
	day = 1
	hour = 8.0
	weather = "晴朗"
	player_position = Vector2(GameData.TILE_SIZE * 30.5, GameData.TILE_SIZE * 17.5)
	current_region_id = ""
	current_region_name = "未知之地"
	current_tile = Vector2i(30, 17)
	set_mode(Mode.EXPLORE)
	EventBus.player_changed.emit(player)
	EventBus.inventory_changed.emit(inventory)
	EventBus.quests_changed.emit()
	EventBus.time_changed.emit(day, hour, weather)

func set_mode(next_mode: Mode) -> void:
	if mode == next_mode:
		return
	mode = next_mode
	EventBus.mode_changed.emit(mode)

func can_explore() -> bool:
	return mode == Mode.EXPLORE

func update_current_region(region: Dictionary, tile: Vector2i) -> void:
	current_tile = tile
	if region.is_empty():
		if current_region_id != "":
			current_region_id = ""
			current_region_name = "未知之地"
			EventBus.region_changed.emit({}, {})
		return
	var region_id := str(region.get("id", ""))
	if region_id.is_empty():
		return
	var previous_region_id := current_region_id
	current_region_id = region_id
	current_region_name = str(region.get("name", region_id))
	var state := _ensure_region_state(region_id)
	var changed := previous_region_id != current_region_id
	var tile_key := "%d,%d" % [tile.x, tile.y]
	var visited: Array = state.get("visited", [])
	if not visited.has(tile_key):
		visited.append(tile_key)
		state["visited"] = visited
		_update_region_exploration(region, state)
		changed = true
	region_state[region_id] = state
	if changed:
		EventBus.region_changed.emit(region, state)

func _ensure_region_state(region_id: String) -> Dictionary:
	if not region_state.has(region_id):
		region_state[region_id] = {
			"discovered": true,
			"exploration": 5,
			"visited": []
		}
	var state: Dictionary = region_state[region_id]
	state["discovered"] = true
	if not state.has("visited") or typeof(state["visited"]) != TYPE_ARRAY:
		state["visited"] = []
	if not state.has("exploration"):
		state["exploration"] = 5
	return state

func _update_region_exploration(region: Dictionary, state: Dictionary) -> void:
	var rect: Array = region.get("rect", [])
	var area := 64
	if rect.size() >= 4:
		area = max(1, int(rect[2]) * int(rect[3]))
	var target_tiles: int = max(8, int(area * 0.35))
	var visited_count := int((state.get("visited", []) as Array).size())
	var exploration: int = int(min(100, max(int(state.get("exploration", 0)), 5 + int(visited_count * 95 / target_tiles))))
	state["exploration"] = exploration

func get_region_state(region_id: String) -> Dictionary:
	return region_state.get(region_id, {})

func is_region_discovered(region_id: String) -> bool:
	return bool(region_state.get(region_id, {}).get("discovered", false))

func get_region_exploration(region_id: String) -> int:
	return int(region_state.get(region_id, {}).get("exploration", 0))

func advance_time(delta: float) -> void:
	if not can_explore():
		return
	hour += delta * 0.08
	if hour >= 24.0:
		hour -= 24.0
		day += 1
		_roll_weather()
	EventBus.time_changed.emit(day, hour, weather)

func _roll_weather() -> void:
	var options := ["晴朗", "多云", "细雨", "薄雾", "飞雪"]
	weather = options[randi_range(0, options.size() - 1)]

func damage_player(amount: int) -> int:
	var hp := int(player.get("hp", 0))
	var actual: int = int(min(amount, hp))
	player["hp"] = max(0, hp - actual)
	EventBus.player_changed.emit(player)
	return actual

func heal_player(amount: int) -> int:
	var hp := int(player.get("hp", 0))
	var max_hp := int(player.get("max_hp", 0))
	var actual: int = int(min(amount, max_hp - hp))
	player["hp"] = hp + actual
	EventBus.player_changed.emit(player)
	return actual

func restore_mp(amount: int) -> int:
	var mp := int(player.get("mp", 0))
	var max_mp := int(player.get("max_mp", 0))
	var actual: int = int(min(amount, max_mp - mp))
	player["mp"] = mp + actual
	EventBus.player_changed.emit(player)
	return actual

func spend_mp(amount: int) -> bool:
	var mp := int(player.get("mp", 0))
	if mp < amount:
		return false
	player["mp"] = mp - amount
	EventBus.player_changed.emit(player)
	return true

func reward_player(exp_amount: int, money_amount: int) -> void:
	player["exp"] = int(player.get("exp", 0)) + exp_amount
	player["pot"] = int(player.get("pot", 0)) + int(exp_amount * 0.35)
	player["money"] = int(player.get("money", 0)) + money_amount
	while int(player.get("exp", 0)) >= int(player.get("exp_next", 200)):
		player["exp"] = int(player["exp"]) - int(player["exp_next"])
		player["level"] = int(player.get("level", 1)) + 1
		player["exp_next"] = int(player.get("level", 1)) * 220
		player["max_hp"] = int(player.get("max_hp", 120)) + 18
		player["max_mp"] = int(player.get("max_mp", 60)) + 10
		player["attack"] = int(player.get("attack", 16)) + 3
		player["defense"] = int(player.get("defense", 8)) + 2
		player["hp"] = player["max_hp"]
		player["mp"] = player["max_mp"]
		EventBus.emit_toast("境界提升：等级 %d" % int(player["level"]))
	EventBus.player_changed.emit(player)

func learn_skill(skill_id: String, level_gain: int = 1) -> int:
	var next_level := int(learned_skills.get(skill_id, 0)) + level_gain
	learned_skills[skill_id] = next_level
	progress_quest("skill", skill_id, level_gain)
	EventBus.player_changed.emit(player)
	return next_level

func practice_skill(skill_id: String) -> bool:
	var current := int(learned_skills.get(skill_id, 0))
	if current <= 0:
		return false
	var cost: int = int(max(5, current * 3))
	if int(player.get("pot", 0)) < cost:
		EventBus.emit_toast("潜能不足")
		return false
	player["pot"] = int(player["pot"]) - cost
	learn_skill(skill_id, 1)
	EventBus.emit_toast("%s 提升到 %d 级" % [GameData.get_skill_name(skill_id), int(learned_skills[skill_id])])
	return true

func join_faction(faction_id: String) -> bool:
	if faction_id == "none":
		return false
	if str(player.get("faction", "none")) != "none" and str(player.get("faction", "none")) != faction_id:
		EventBus.emit_toast("你已有门派")
		return false
	player["faction"] = faction_id
	var skills := GameData.get_faction_skills(faction_id)
	if not skills.is_empty():
		learn_skill(str(skills[0]), 1)
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("拜入%s" % GameData.get_faction_name(faction_id))
	return true

func spend_money(amount: int) -> bool:
	if int(player.get("money", 0)) < amount:
		EventBus.emit_toast("银两不足")
		return false
	player["money"] = int(player["money"]) - amount
	EventBus.player_changed.emit(player)
	return true

func add_money(amount: int) -> void:
	player["money"] = int(player.get("money", 0)) + amount
	EventBus.player_changed.emit(player)

func add_item(item_id: String, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	progress_quest("collect", item_id, count)
	EventBus.inventory_changed.emit(inventory)

func remove_item(item_id: String, count: int = 1) -> bool:
	if int(inventory.get(item_id, 0)) < count:
		return false
	inventory[item_id] = int(inventory[item_id]) - count
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	EventBus.inventory_changed.emit(inventory)
	return true

func use_item(item_id: String) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	var item_type := str(item.get("type", ""))
	if item_type == "weapon" or item_type == "armor":
		return equip_item(item_id)
	if item_type != "consumable":
		EventBus.emit_toast("这个物品不能直接使用")
		return false
	if not remove_item(item_id, 1):
		return false
	var effects: Dictionary = item.get("effects", {})
	var parts: Array[String] = []
	if effects.has("hp"):
		parts.append("气血 +%d" % heal_player(int(effects["hp"])))
	if effects.has("mp"):
		parts.append("内力 +%d" % restore_mp(int(effects["mp"])))
	if effects.has("pot"):
		player["pot"] = int(player.get("pot", 0)) + int(effects["pot"])
		parts.append("潜能 +%d" % int(effects["pot"]))
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("使用%s：%s" % [str(item.get("name", item_id)), "，".join(parts)])
	return true

func equip_item(item_id: String) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	var item_type := str(item.get("type", ""))
	var slot := ""
	if item_type == "weapon":
		slot = "weapon"
	elif item_type == "armor":
		slot = "armor"
	else:
		EventBus.emit_toast("无法装备")
		return false

	var old_item_id := str(equipment.get(slot, ""))
	if old_item_id == item_id:
		EventBus.emit_toast("已经装备%s" % str(item.get("name", item_id)))
		return true
	if not old_item_id.is_empty():
		_apply_equipment_stats(old_item_id, -1)
	equipment[slot] = item_id
	_apply_equipment_stats(item_id, 1)
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("装备%s" % str(item.get("name", item_id)))
	return true

func _apply_equipment_stats(item_id: String, direction: int) -> void:
	var item := GameData.get_item(item_id)
	var effects: Dictionary = item.get("effects", {})
	if effects.has("attack"):
		player["attack"] = int(player.get("attack", 0)) + int(effects["attack"]) * direction
	if effects.has("defense"):
		player["defense"] = int(player.get("defense", 0)) + int(effects["defense"]) * direction

func buy_item(item_id: String, price_override: int = -1) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	var price := int(item.get("price", 0))
	if price_override >= 0:
		price = price_override
	if not spend_money(price):
		return false
	add_item(item_id, 1)
	EventBus.emit_toast("买入%s" % str(item.get("name", item_id)))
	return true

func rest(cost: int = 12) -> bool:
	if not spend_money(cost):
		return false
	heal_player(int(player.get("max_hp", 100)))
	restore_mp(int(player.get("max_mp", 50)))
	hour += 4.0
	if hour >= 24.0:
		hour -= 24.0
		day += 1
		_roll_weather()
	EventBus.time_changed.emit(day, hour, weather)
	EventBus.emit_toast("休息完毕")
	return true

func accept_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return false
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return false
	active_quests[quest_id] = {"progress": {}}
	active_quest = str(quest.get("title", quest_id))
	_sync_existing_objective_progress(quest_id)
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(player)
	_check_quest_completion(quest_id)
	EventBus.emit_toast("接到任务：%s" % active_quest)
	return true

func progress_quest(kind: String, target: String, amount: int = 1) -> void:
	var changed := false
	for quest_id in active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			if str(objective.get("type", "")) != kind:
				continue
			if str(objective.get("target", "")) != target:
				continue
			var key := _objective_key(objective)
			var progress: Dictionary = active_quests[quest_id].get("progress", {})
			progress[key] = int(progress.get(key, 0)) + amount
			active_quests[quest_id]["progress"] = progress
			changed = true
	if changed:
		var ids := active_quests.keys()
		for quest_id in ids:
			_check_quest_completion(str(quest_id))
		EventBus.quests_changed.emit()

func _sync_existing_objective_progress(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	var objectives: Array = quest.get("objectives", [])
	var progress: Dictionary = active_quests[quest_id].get("progress", {})
	for objective in objectives:
		var key := _objective_key(objective)
		var kind := str(objective.get("type", ""))
		var target := str(objective.get("target", ""))
		if kind == "collect":
			progress[key] = int(inventory.get(target, 0))
		elif kind == "skill":
			progress[key] = int(learned_skills.get(target, 0))
	active_quests[quest_id]["progress"] = progress

func _check_quest_completion(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return
	var progress: Dictionary = active_quests[quest_id].get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var key := _objective_key(objective)
		var required := int(objective.get("count", 1))
		if int(progress.get(key, 0)) < required:
			return
	_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	var quest := GameData.get_quest(quest_id)
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	var rewards: Dictionary = quest.get("rewards", {})
	reward_player(int(rewards.get("exp", 0)), int(rewards.get("money", 0)))
	player["daode"] = int(player.get("daode", 0)) + int(rewards.get("daode", 0))
	var items: Dictionary = rewards.get("items", {})
	for item_id in items.keys():
		add_item(str(item_id), int(items[item_id]))
	if not active_quests.is_empty():
		var first_id := str(active_quests.keys()[0])
		active_quest = str(GameData.get_quest(first_id).get("title", first_id))
	else:
		active_quest = "自由探索江湖"
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("完成任务：%s" % str(quest.get("title", quest_id)))
	if quest_id == "q_hero_trial":
		game_flags["alpha_clear"] = true
		active_quest = "江湖初成"
		EventBus.player_changed.emit(player)
		EventBus.emit_toast("阶段通关：江湖初成")

func _objective_key(objective: Dictionary) -> String:
	return "%s:%s" % [str(objective.get("type", "")), str(objective.get("target", ""))]

func get_quest_status_lines() -> Array[String]:
	var lines: Array[String] = []
	if active_quests.is_empty():
		lines.append("暂无进行中的任务。")
	for quest_id in active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		lines.append("【进行中】%s" % str(quest.get("title", quest_id)))
		var progress: Dictionary = active_quests[quest_id].get("progress", {})
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			var key := _objective_key(objective)
			var current := int(progress.get(key, 0))
			var required := int(objective.get("count", 1))
			lines.append("  - %s %d/%d" % [str(objective.get("label", key)), min(current, required), required])
	if not completed_quests.is_empty():
		lines.append("")
		lines.append("已完成：")
		for quest_id in completed_quests:
			var quest := GameData.get_quest(str(quest_id))
			lines.append("  - %s" % str(quest.get("title", quest_id)))
	return lines

func mark_enemy_defeated(enemy_id: int) -> void:
	if not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)

func build_save_snapshot(position: Vector2) -> Dictionary:
	player_position = position
	return {
		"player": player,
		"inventory": inventory,
		"equipment": equipment,
		"learned_skills": learned_skills,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"defeated_enemies": defeated_enemies,
		"game_flags": game_flags,
		"region_state": region_state,
		"active_quest": active_quest,
		"day": day,
		"hour": hour,
		"weather": weather,
		"player_position": {"x": position.x, "y": position.y}
	}

func save_game(position: Vector2) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		EventBus.emit_toast("存档失败")
		return false
	file.store_string(JSON.stringify(build_save_snapshot(position), "\t"))
	EventBus.emit_toast("存档完成")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		EventBus.emit_toast("没有存档")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		EventBus.emit_toast("读档失败")
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		EventBus.emit_toast("存档损坏")
		return false
	_apply_snapshot(parsed)
	EventBus.game_loaded.emit(parsed)
	EventBus.emit_toast("读档完成")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _apply_snapshot(snapshot: Dictionary) -> void:
	player = snapshot.get("player", {})
	inventory = snapshot.get("inventory", {})
	equipment = snapshot.get("equipment", {"weapon": "", "armor": ""})
	learned_skills = snapshot.get("learned_skills", {})
	active_quests = snapshot.get("active_quests", {})
	completed_quests = snapshot.get("completed_quests", [])
	defeated_enemies = snapshot.get("defeated_enemies", [])
	game_flags = snapshot.get("game_flags", {})
	region_state = snapshot.get("region_state", {})
	active_quest = str(snapshot.get("active_quest", "自由探索江湖"))
	day = int(snapshot.get("day", 1))
	hour = float(snapshot.get("hour", 8.0))
	weather = str(snapshot.get("weather", "晴朗"))
	var pos: Dictionary = snapshot.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	current_tile = Vector2i(floori(player_position.x / GameData.TILE_SIZE), floori(player_position.y / GameData.TILE_SIZE))
	set_mode(Mode.EXPLORE)
	EventBus.player_changed.emit(player)
	EventBus.inventory_changed.emit(inventory)
	EventBus.quests_changed.emit()
	EventBus.time_changed.emit(day, hour, weather)
