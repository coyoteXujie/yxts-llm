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
	MAP,
	DISCOVERY
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
var npc_memory: Dictionary = {}
var region_state: Dictionary = {}
var world_events: Array = []
var active_quest: String = "初入平安镇"
var day := 1
var hour := 8.0
var weather := "晴朗"
var player_position := Vector2.ZERO
var current_region_id := ""
var current_region_name := "未知之地"
var current_tile := Vector2i.ZERO
var map_target_region_id := ""

const SAVE_PATH := "user://savegame.json"
const FAST_TRAVEL_MIN_EXPLORATION := 25
const REGION_EXPLORATION_MILESTONES := [25, 50, 75, 100]
const REGION_EXPLORATION_MILESTONE_TITLES := {
	25: "初识此地",
	50: "路熟半城",
	75: "寻幽探隐",
	100: "一域尽览"
}
const REGION_EXPLORATION_MILESTONE_SEVERITY := {
	25: 2,
	50: 2,
	75: 3,
	100: 4
}
const FAST_TRAVEL_REGION_TYPES := {
	"city": true,
	"town": true,
	"sect": true
}
const TRAVEL_ROUTE_NEIGHBOR_LIMIT := 8
const FAST_TRAVEL_MIN_FARE := 3
const CORE_RUMOR_NPCS := [
	"苏梦瑶",
	"陈天行",
	"赵无极",
	"玄机子",
	"花如玉",
	"烈火",
	"蛇王",
	"太极真人",
	"冰魄",
	"逍遥子"
]
const STORY_QUEST_PRIORITY := [
	"q_intro_town",
	"q_clear_thugs",
	"q_flower_thief",
	"q_hero_trial"
]
const STORY_CHOICE_DEFINITIONS := [
	{
		"id": "choice_conclave_public",
		"group": "conclave_path",
		"flag": "story_conclave_public",
		"npcs": ["苏梦瑶", "太极真人"],
		"title": "公开断令",
		"description": "把断令证据交给七派公开夜议，换取正道信任，但也会惊动暗影司。",
		"requires_completed": ["q_main_broken_token"],
		"blocks_completed": ["q_main_wulin_conclave"],
		"region_id": "luoyang",
		"event_title": "断令公议",
		"event_description": "你主张公开断令证据，七派可信之人开始以明面名义聚拢。",
		"memory": "你主张公开断令证据，愿把七派信任放在明处。",
		"daode": 4,
		"money": 0,
		"items": {}
	},
	{
		"id": "choice_conclave_secret",
		"group": "conclave_path",
		"flag": "story_conclave_secret",
		"npcs": ["苏梦瑶", "陈天行"],
		"title": "暗查旧账",
		"description": "暂不公开断令，先沿苏家旧账暗查暗影司线人，可少惊动敌人但会让七派疑心更重。",
		"requires_completed": ["q_main_broken_token"],
		"blocks_completed": ["q_main_wulin_conclave"],
		"region_id": "changan",
		"event_title": "旧账暗查",
		"event_description": "你决定暂压断令，借陈天行旧账暗查暗影司线人。",
		"memory": "你选择暂压断令，沿苏家旧账暗中追查。",
		"daode": 1,
		"money": 80,
		"items": {"item_shengji": 1}
	},
	{
		"id": "choice_epilogue_mercy",
		"group": "epilogue_path",
		"flag": "story_epilogue_mercy",
		"npcs": ["苏梦瑶", "太极真人"],
		"title": "清算有度",
		"description": "封存旧案后只清点首恶和暗线证据，给被胁迫的小人物留一条改过路。",
		"requires_completed": ["q_main_old_case_closure"],
		"blocks_completed": ["q_main_epilogue_mercy", "q_main_epilogue_reckoning"],
		"region_id": "luoyang",
		"event_title": "清算有度",
		"event_description": "你决定把旧案清算压在首恶与铁证上，七派开始收束余波而不是扩大仇怨。",
		"memory": "你选择清算有度，愿给被胁迫的人留一条回头路。",
		"daode": 8,
		"money": 0,
		"items": {"item_dan": 1}
	},
	{
		"id": "choice_epilogue_reckoning",
		"group": "epilogue_path",
		"flag": "story_epilogue_reckoning",
		"npcs": ["陈天行", "赵无极"],
		"title": "追剿残影",
		"description": "趁暗影司总坛新破继续清剿残部，换来更干净的江湖，但会把许多旧怨翻到明面。",
		"requires_completed": ["q_main_old_case_closure"],
		"blocks_completed": ["q_main_epilogue_mercy", "q_main_epilogue_reckoning"],
		"region_id": "changan",
		"event_title": "追剿残影",
		"event_description": "你决定趁势追剿暗影司残部，武林盟与几路暗线开始连夜清查。",
		"memory": "你选择追剿残影，宁可翻出旧怨也不让暗影司残部蛰伏。",
		"daode": 2,
		"money": 160,
		"items": {"item_shengji": 1}
	}
]

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
	npc_memory = {}
	region_state = {}
	world_events = []
	active_quest = "初入平安镇"
	_start_quest_silently("q_intro_town")
	day = 1
	hour = 8.0
	weather = "晴朗"
	player_position = Vector2(GameData.TILE_SIZE * 30.5, GameData.TILE_SIZE * 17.5)
	current_region_id = ""
	current_region_name = "未知之地"
	current_tile = Vector2i(30, 17)
	map_target_region_id = ""
	append_world_event("story", "平安镇初闻", "你在平安镇醒来，江湖风声还只是客栈里的几句闲话。", "qinghe", 1)
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
	var discovered_before := region_state.has(region_id) and bool(region_state[region_id].get("discovered", false))
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
	if not discovered_before:
		_record_region_discovery(region)
	if changed:
		EventBus.region_changed.emit(region, state)

func _ensure_region_state(region_id: String) -> Dictionary:
	if not region_state.has(region_id):
		region_state[region_id] = {
			"discovered": true,
			"exploration": 5,
			"visited": [],
			"exploration_milestones": []
		}
	var state: Dictionary = region_state[region_id]
	state["discovered"] = true
	if not state.has("visited") or typeof(state["visited"]) != TYPE_ARRAY:
		state["visited"] = []
	if not state.has("exploration"):
		state["exploration"] = 5
	if not state.has("exploration_milestones") or typeof(state["exploration_milestones"]) != TYPE_ARRAY:
		state["exploration_milestones"] = []
	return state

func _update_region_exploration(region: Dictionary, state: Dictionary) -> void:
	var region_id := str(region.get("id", ""))
	var rect: Array = region.get("rect", [])
	var area := 64
	if rect.size() >= 4:
		area = max(1, int(rect[2]) * int(rect[3]))
	var target_tiles: int = max(8, int(area * 0.35))
	var visited_count := int((state.get("visited", []) as Array).size())
	var before := int(state.get("exploration", 0))
	var exploration: int = int(min(100, max(int(state.get("exploration", 0)), 5 + int(visited_count * 95 / target_tiles))))
	state["exploration"] = exploration
	_apply_region_exploration_milestones(region_id, region, before, exploration, state)

func get_region_state(region_id: String) -> Dictionary:
	return region_state.get(region_id, {})

func is_region_discovered(region_id: String) -> bool:
	return bool(region_state.get(region_id, {}).get("discovered", false))

func get_region_exploration(region_id: String) -> int:
	return int(region_state.get(region_id, {}).get("exploration", 0))

func get_region_exploration_title(region_id: String) -> String:
	return get_exploration_title_for_value(get_region_exploration(region_id))

func get_exploration_title_for_value(exploration: int) -> String:
	var result := "初到"
	for threshold in REGION_EXPLORATION_MILESTONES:
		var milestone := int(threshold)
		if exploration >= milestone:
			result = str(REGION_EXPLORATION_MILESTONE_TITLES.get(milestone, result))
	return result

func add_region_exploration(region_id: String, amount: int) -> int:
	if region_id.is_empty() or amount <= 0:
		return get_region_exploration(region_id)
	var state := _ensure_region_state(region_id)
	var before := int(state.get("exploration", 0))
	var after := clampi(before + amount, 5, 100)
	state["exploration"] = after
	_apply_region_exploration_milestones(region_id, GameData.get_region(region_id), before, after, state)
	region_state[region_id] = state
	if after != before and current_region_id == region_id:
		EventBus.region_changed.emit(GameData.get_region(region_id), state)
	return after

func _apply_region_exploration_milestones(region_id: String, region: Dictionary, before: int, after: int, state: Dictionary) -> void:
	if region_id.is_empty() or after <= before:
		return
	var achieved: Array = state.get("exploration_milestones", [])
	var changed := false
	for threshold in REGION_EXPLORATION_MILESTONES:
		var milestone := int(threshold)
		if after < milestone or before >= milestone:
			continue
		if achieved.has(milestone):
			continue
		achieved.append(milestone)
		changed = true
		_append_region_exploration_milestone_event(region_id, region, milestone, after)
	if changed:
		state["exploration_milestones"] = achieved

func _append_region_exploration_milestone_event(region_id: String, region: Dictionary, milestone: int, exploration: int) -> void:
	var region_name := str(region.get("name", region_id))
	var title := str(REGION_EXPLORATION_MILESTONE_TITLES.get(milestone, "探得新路"))
	var description := "%s探索度达到 %d%%，江湖人开始把你当作熟路人。" % [
		region_name,
		exploration
	]
	if milestone >= 75:
		description = "%s探索度达到 %d%%，隐秘小径和旧闻开始浮出水面。" % [
			region_name,
			exploration
		]
	if milestone >= 100:
		description = "%s一带的明路暗径都已记在心中，后续可承接更深层的隐藏事件。" % region_name
	append_world_event(
		"exploration",
		"%s·%s" % [region_name, title],
		description,
		region_id,
		int(REGION_EXPLORATION_MILESTONE_SEVERITY.get(milestone, 2))
	)

func append_world_event(kind: String, title: String, description: String, region_id: String = "", severity: int = 1) -> Dictionary:
	title = title.strip_edges()
	description = description.strip_edges()
	if title.is_empty() and description.is_empty():
		return {}
	for existing in world_events:
		if typeof(existing) != TYPE_DICTIONARY:
			continue
		if int(existing.get("day", -1)) == day and str(existing.get("title", "")) == title:
			return (existing as Dictionary).duplicate(true)
	var region_name := current_region_name
	if not region_id.is_empty():
		var region := GameData.get_region(region_id)
		if not region.is_empty():
			region_name = str(region.get("name", region_id))
	var event_id := "%d_%d_%d" % [day, int(hour * 100.0), abs(hash("%s:%s:%s" % [kind, title, description]))]
	var event := {
		"id": event_id,
		"kind": kind,
		"title": title,
		"description": description,
		"region_id": region_id,
		"region_name": region_name,
		"day": day,
		"hour": hour,
		"weather": weather,
		"severity": clampi(severity, 1, 5)
	}
	world_events.append(event)
	while world_events.size() > 30:
		world_events.remove_at(0)
	_spread_world_event_to_npc_memory(event)
	EventBus.world_events_changed.emit(get_recent_world_events(30))
	if severity >= 4:
		EventBus.emit_toast("江湖传闻：%s" % title)
	return event.duplicate(true)

func get_recent_world_events(max_count: int = 5) -> Array:
	var count: int = clampi(max_count, 0, world_events.size())
	var start: int = max(0, world_events.size() - count)
	var result: Array = []
	for index in range(start, world_events.size()):
		if typeof(world_events[index]) == TYPE_DICTIONARY:
			result.append((world_events[index] as Dictionary).duplicate(true))
	return result

func get_world_event_summary(max_count: int = 3) -> String:
	var parts: Array[String] = []
	for event in get_recent_world_events(max_count):
		var entry: Dictionary = event
		var title := str(entry.get("title", ""))
		var description := str(entry.get("description", ""))
		if description.length() > 34:
			description = "%s..." % description.substr(0, 34)
		if not title.is_empty() and not description.is_empty():
			parts.append("%s：%s" % [title, description])
		elif not title.is_empty():
			parts.append(title)
	if parts.is_empty():
		return "暂无新的江湖传闻"
	return "；".join(parts)

func _record_region_discovery(region: Dictionary) -> void:
	var region_id := str(region.get("id", ""))
	if region_id.is_empty():
		return
	var region_name := str(region.get("name", region_id))
	var region_type := str(region.get("type", "wild"))
	var danger := int(region.get("danger", 1))
	var severity := 1
	if region_type == "city" or region_type == "sect":
		severity = 2
	if danger >= 4:
		severity = 3
	var description := "你抵达%s，记下了这里的道路、人声与危险。" % region_name
	if region_type == "sect":
		description = "你踏入%s地界，山门规矩和江湖目光同时落在身上。" % region_name
	elif region_type == "city":
		description = "你抵达%s，城中消息如水脉般汇入江湖。" % region_name
	elif danger >= 4:
		description = "你发现%s，路上杀机比寻常荒野更重。" % region_name
	append_world_event("discovery", "发现%s" % region_name, description, region_id, severity)

func set_map_target_region(region_id: String) -> void:
	if map_target_region_id == region_id:
		return
	map_target_region_id = region_id
	EventBus.map_target_changed.emit(map_target_region_id)

func get_npc_memory(npc_name: String) -> Dictionary:
	if npc_name.is_empty():
		return _default_npc_memory()
	var state: Dictionary = npc_memory.get(npc_name, _default_npc_memory())
	return state.duplicate(true)

func get_npc_favor(npc_name: String) -> int:
	return int(get_npc_memory(npc_name).get("favor", 0))

func get_npc_relation_label(npc_name: String) -> String:
	var favor := get_npc_favor(npc_name)
	if favor <= -50:
		return "敌视"
	if favor < 0:
		return "疏远"
	if favor >= 90:
		return "挚友"
	if favor >= 70:
		return "知己"
	if favor >= 50:
		return "好友"
	if favor >= 30:
		return "朋友"
	if favor >= 10:
		return "认识"
	return "初识"

func record_npc_interaction(npc_data: Dictionary, kind: String) -> Dictionary:
	var npc_name := str(npc_data.get("name", ""))
	if npc_name.is_empty():
		return _default_npc_memory()
	var state := _ensure_npc_memory(npc_name)
	var favor_delta := _npc_favor_delta(npc_data, kind)
	if kind == "talk":
		var daily_talk_day := int(state.get("daily_talk_day", 0))
		var daily_talks := int(state.get("daily_talks", 0))
		if daily_talk_day != day:
			daily_talk_day = day
			daily_talks = 0
		if daily_talks >= 3:
			favor_delta = 0
		state["daily_talk_day"] = daily_talk_day
		state["daily_talks"] = daily_talks + 1
		state["talk_count"] = int(state.get("talk_count", 0)) + 1
	state["favor"] = clampi(int(state.get("favor", 0)) + favor_delta, -100, 100)
	state["last_day"] = day
	_append_npc_memory(state, _npc_memory_label(kind, favor_delta))
	npc_memory[npc_name] = state
	return state.duplicate(true)

func get_available_story_choices(npc_name: String = "") -> Array:
	var choices: Array = []
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		if not _story_choice_matches_npc(choice, npc_name):
			continue
		if not _story_choice_available(choice):
			continue
		choices.append(choice.duplicate(true))
	return choices

func choose_story_branch(choice_id: String) -> bool:
	var choice := _story_choice_by_id(choice_id)
	if choice.is_empty() or not _story_choice_available(choice):
		return false
	var group := str(choice.get("group", ""))
	var group_flag := _story_choice_group_flag(group)
	if not group.is_empty():
		game_flags[group_flag] = str(choice.get("id", ""))
	var flag := str(choice.get("flag", ""))
	if not flag.is_empty():
		game_flags[flag] = true
	var daode_delta := int(choice.get("daode", 0))
	if daode_delta != 0:
		player["daode"] = int(player.get("daode", 0)) + daode_delta
	var money_delta := int(choice.get("money", 0))
	if money_delta != 0:
		add_money(money_delta)
	var items: Dictionary = choice.get("items", {})
	for item_id in items.keys():
		add_item(str(item_id), int(items[item_id]))
	_apply_story_choice_memory(choice)
	append_world_event(
		"story_choice",
		str(choice.get("event_title", choice.get("title", "剧情抉择"))),
		str(choice.get("event_description", choice.get("description", ""))),
		str(choice.get("region_id", current_region_id)),
		4
	)
	EventBus.player_changed.emit(player)
	EventBus.quests_changed.emit()
	EventBus.emit_toast("剧情抉择：%s" % str(choice.get("title", choice_id)))
	return true

func get_story_choice_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		var flag := str(choice.get("flag", ""))
		if not flag.is_empty() and bool(game_flags.get(flag, false)):
			lines.append("%s：%s" % [str(choice.get("title", flag)), str(choice.get("description", ""))])
	return lines

func _story_choice_by_id(choice_id: String) -> Dictionary:
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		if str(choice.get("id", "")) == choice_id:
			return choice.duplicate(true)
	return {}

func _story_choice_matches_npc(choice: Dictionary, npc_name: String) -> bool:
	if npc_name.is_empty():
		return true
	var npcs: Array = choice.get("npcs", [])
	return npcs.has(npc_name)

func _story_choice_available(choice: Dictionary) -> bool:
	var group := str(choice.get("group", ""))
	if not group.is_empty() and not str(game_flags.get(_story_choice_group_flag(group), "")).is_empty():
		return false
	var flag := str(choice.get("flag", ""))
	if not flag.is_empty() and bool(game_flags.get(flag, false)):
		return false
	var required_completed: Array = choice.get("requires_completed", [])
	for quest_id in required_completed:
		if not completed_quests.has(str(quest_id)):
			return false
	var blocked_completed: Array = choice.get("blocks_completed", [])
	for quest_id in blocked_completed:
		if completed_quests.has(str(quest_id)):
			return false
	return true

func _story_choice_group_flag(group: String) -> String:
	return "story_choice_%s" % group

func _apply_story_choice_memory(choice: Dictionary) -> void:
	var memory_line := str(choice.get("memory", ""))
	if memory_line.is_empty():
		return
	var npcs: Array = choice.get("npcs", [])
	for npc_name_value in npcs:
		var npc_name := str(npc_name_value)
		if npc_name.is_empty():
			continue
		var state := _ensure_npc_memory(npc_name)
		_append_npc_memory(state, memory_line)
		state["favor"] = clampi(int(state.get("favor", 0)) + 4, -100, 100)
		npc_memory[npc_name] = state

func _default_npc_memory() -> Dictionary:
	return {
		"favor": 0,
		"talk_count": 0,
		"last_day": 0,
		"daily_talk_day": 0,
		"daily_talks": 0,
		"memories": []
	}

func _ensure_npc_memory(npc_name: String) -> Dictionary:
	if not npc_memory.has(npc_name) or typeof(npc_memory[npc_name]) != TYPE_DICTIONARY:
		npc_memory[npc_name] = _default_npc_memory()
	var state: Dictionary = npc_memory[npc_name]
	if not state.has("memories") or typeof(state["memories"]) != TYPE_ARRAY:
		state["memories"] = []
	for key in ["favor", "talk_count", "last_day", "daily_talk_day", "daily_talks"]:
		if not state.has(key):
			state[key] = 0
	return state

func _npc_favor_delta(npc_data: Dictionary, kind: String) -> int:
	var base := 0
	match kind:
		"talk":
			base = 1
		"teach":
			base = 1
		"quest_accept":
			base = 3
		"trade":
			base = 1
		"join":
			base = 8
		"rest":
			base = 1
		_:
			base = 0
	if base == 0:
		return 0
	var personality := str(npc_data.get("personality", ""))
	if kind == "talk":
		if personality.contains("善") or personality.contains("温") or personality.contains("热情") or personality.contains("活泼"):
			base += 1
		elif personality.contains("冷") or personality.contains("阴") or personality.contains("沉默") or personality.contains("多疑"):
			base = max(0, base - 1)
	if bool(npc_data.get("is_master", false)) or str(npc_data.get("npc_type", "")) == "master":
		base = max(1, base)
	return base

func _npc_memory_label(kind: String, favor_delta: int) -> String:
	var suffix := ""
	if favor_delta > 0:
		suffix = "，好感+%d" % favor_delta
	match kind:
		"talk":
			return "与你交谈%s" % suffix
		"teach":
			return "指点武学%s" % suffix
		"quest_accept":
			return "托付任务%s" % suffix
		"trade":
			return "与你交易%s" % suffix
		"join":
			return "收你入门%s" % suffix
		"rest":
			return "安排住店%s" % suffix
		_:
			return "记住了你的行动%s" % suffix

func _append_npc_memory(state: Dictionary, text: String) -> void:
	if text.is_empty():
		return
	var memories: Array = state.get("memories", [])
	var stamped := "第%d日：%s" % [day, text]
	if memories.is_empty() or str(memories[memories.size() - 1]) != stamped:
		memories.append(stamped)
	while memories.size() > 6:
		memories.remove_at(0)
	state["memories"] = memories

func get_fast_travel_block_reason(region_id: String) -> String:
	if region_id.is_empty():
		return "未选择区域"
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return "区域不存在"
	if not is_region_discovered(region_id):
		return "尚未发现该区域"
	var source_region := _current_travel_source_region()
	if source_region.is_empty():
		return "当前位置不在可识别区域"
	if region_id == str(source_region.get("id", "")):
		return "已经身在此处"
	var region_type := str(region.get("type", "wild"))
	if not FAST_TRAVEL_REGION_TYPES.has(region_type):
		return "荒野区域暂不可快速前往，只能标记目的地"
	var exploration := get_region_exploration(region_id)
	if exploration < FAST_TRAVEL_MIN_EXPLORATION:
		return "探索度达到%d%%后解锁驿路" % FAST_TRAVEL_MIN_EXPLORATION
	var fare := estimate_fast_travel_fare(region_id)
	if int(player.get("money", 0)) < fare:
		return "驿路费用 %d 两，银两不足" % fare
	return ""

func can_fast_travel_to_region(region_id: String) -> bool:
	return get_fast_travel_block_reason(region_id).is_empty()

func build_region_travel_plan(region_id: String) -> Dictionary:
	var target_region := GameData.get_region(region_id)
	var source_region := _current_travel_source_region()
	var source_id := str(source_region.get("id", ""))
	var route := _find_region_route(source_id, region_id)
	var route_names := _route_region_names(route)
	var distance := _route_distance(route)
	var hours := _estimate_route_hours(route, target_region)
	var risk_level := _route_risk_level(route)
	var fare := _estimate_route_fare(route, target_region)
	var blocked_reason := get_fast_travel_block_reason(region_id)
	return {
		"source_region_id": source_id,
		"target_region_id": region_id,
		"route": route,
		"route_names": route_names,
		"route_summary": " -> ".join(route_names),
		"distance": distance,
		"hours": hours,
		"fare": fare,
		"risk_level": risk_level,
		"risk_label": _route_risk_label(risk_level),
		"risk_note": _route_risk_note(risk_level),
		"blocked_reason": blocked_reason,
		"can_fast_travel": blocked_reason.is_empty()
	}

func estimate_fast_travel_hours(region_id: String) -> float:
	var target_region := GameData.get_region(region_id)
	if target_region.is_empty():
		return 0.0
	var source_region := _current_travel_source_region()
	var route := _find_region_route(str(source_region.get("id", "")), region_id)
	return _estimate_route_hours(route, target_region)

func estimate_fast_travel_fare(region_id: String) -> int:
	var target_region := GameData.get_region(region_id)
	if target_region.is_empty():
		return 0
	var source_region := _current_travel_source_region()
	var route := _find_region_route(str(source_region.get("id", "")), region_id)
	return _estimate_route_fare(route, target_region)

func apply_fast_travel_time(region_id: String) -> float:
	var reason := get_fast_travel_block_reason(region_id)
	if not reason.is_empty():
		EventBus.emit_toast(reason)
		return -1.0
	var plan := build_region_travel_plan(region_id)
	var travel_hours := float(plan.get("hours", estimate_fast_travel_hours(region_id)))
	var fare := int(plan.get("fare", 0))
	if fare > 0 and not spend_money(fare):
		return -1.0
	advance_hours(travel_hours)
	_record_fast_travel_event(plan)
	return travel_hours

func resolve_fast_travel_risk(plan: Dictionary) -> Dictionary:
	var risk_level := int(plan.get("risk_level", 1))
	if risk_level < 3:
		return {}
	var target_id := str(plan.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		return {}
	var chance := clampf(0.10 + float(risk_level - 3) * 0.16, 0.10, 0.48)
	if randf() > chance:
		return {}
	var target_name := str(target_region.get("name", target_id))
	var selector: int = int(abs(hash("%d:%s:%s:%s" % [day, target_id, weather, str(plan.get("route_summary", ""))])) % 3)
	if risk_level >= 4 and selector == 0:
		var enemy: Dictionary = GameData.build_region_encounter_enemy(target_region)
		if not enemy.is_empty():
			var ambush_title := "%s驿路遇伏" % target_name
			var ambush_description := "你刚抵达%s，暗处有人趁旅途疲惫截住去路。" % target_name
			append_world_event("travel_risk", ambush_title, ambush_description, target_id, mini(risk_level, 4))
			return {
				"kind": "ambush",
				"title": ambush_title,
				"description": ambush_description,
				"enemy": enemy,
				"toast": "%s，准备迎战" % ambush_title
			}
	var delay_hours := 0.5 + float(risk_level - 2) * 0.25
	advance_hours(delay_hours)
	var damage := risk_level * 5 + randi_range(0, 6)
	var hp := int(player.get("hp", 0))
	var actual_damage: int = damage_player(mini(damage, maxi(0, hp - 1)))
	var delay_title := "%s驿路受阻" % target_name
	var delay_description := "你在%s附近遇到险路和盘查，耽搁%.1f时辰，气血损耗%d点。" % [target_name, delay_hours, actual_damage]
	append_world_event("travel_risk", delay_title, delay_description, target_id, mini(risk_level, 4))
	return {
		"kind": "delay",
		"title": delay_title,
		"description": delay_description,
		"delay_hours": delay_hours,
		"damage": actual_damage,
		"toast": "%s：耽搁%.1f时辰，气血-%d" % [delay_title, delay_hours, actual_damage]
	}

func advance_hours(hours_to_add: float) -> void:
	hour += maxf(hours_to_add, 0.0)
	while hour >= 24.0:
		hour -= 24.0
		day += 1
		_roll_weather()
		_run_daily_world_pulse()
	EventBus.time_changed.emit(day, hour, weather)

func _region_center_tile(region: Dictionary) -> Vector2i:
	var center_data: Array = region.get("center", [])
	if center_data.size() >= 2:
		return Vector2i(int(center_data[0]), int(center_data[1]))
	var rect: Array = region.get("rect", [])
	if rect.size() >= 4:
		return Vector2i(int(rect[0]) + int(rect[2]) / 2, int(rect[1]) + int(rect[3]) / 2)
	return current_tile

func _current_travel_source_region() -> Dictionary:
	var region := GameData.get_region(current_region_id)
	if not region.is_empty():
		return region
	var tile_region := GameData.get_region_at_tile(current_tile)
	if not tile_region.is_empty():
		return tile_region
	return {}

func _find_region_route(source_id: String, target_id: String) -> Array[String]:
	var route: Array[String] = []
	if source_id.is_empty() or target_id.is_empty():
		if not source_id.is_empty():
			route.append(source_id)
		if not target_id.is_empty() and target_id != source_id:
			route.append(target_id)
		return route
	if source_id == target_id:
		return [source_id]
	var open: Array[String] = [source_id]
	var costs: Dictionary = {}
	costs[source_id] = 0.0
	var came_from: Dictionary = {}
	var visited: Dictionary = {}
	while not open.is_empty():
		open.sort_custom(func(a: String, b: String) -> bool:
			return float(costs.get(a, INF)) < float(costs.get(b, INF))
		)
		var current_id := str(open.pop_front())
		if bool(visited.get(current_id, false)):
			continue
		visited[current_id] = true
		if current_id == target_id:
			break
		var current_region := GameData.get_region(current_id)
		for neighbor in GameData.get_neighbor_regions(current_id, TRAVEL_ROUTE_NEIGHBOR_LIMIT):
			if typeof(neighbor) != TYPE_DICTIONARY:
				continue
			var next_region: Dictionary = neighbor
			var next_id := str(next_region.get("id", ""))
			if next_id.is_empty() or bool(visited.get(next_id, false)):
				continue
			var next_cost := float(costs.get(current_id, 0.0)) + _region_travel_edge_cost(current_region, next_region)
			if not costs.has(next_id) or next_cost < float(costs.get(next_id, INF)):
				costs[next_id] = next_cost
				came_from[next_id] = current_id
				if not open.has(next_id):
					open.append(next_id)
	if not costs.has(target_id):
		return [source_id, target_id]
	var reversed: Array[String] = []
	var cursor := target_id
	var guard := 0
	while guard < 128:
		reversed.append(cursor)
		if cursor == source_id:
			break
		if not came_from.has(cursor):
			break
		cursor = str(came_from[cursor])
		guard += 1
	for index in range(reversed.size() - 1, -1, -1):
		route.append(reversed[index])
	return route

func _region_travel_edge_cost(source: Dictionary, target: Dictionary) -> float:
	var distance := _region_center_distance(source, target)
	var target_type := str(target.get("type", "wild"))
	var danger := float(target.get("danger", 1))
	var type_cost := 0.0
	match target_type:
		"city":
			type_cost = 0.0
		"town":
			type_cost = 0.7
		"sect":
			type_cost = 1.0
		_:
			type_cost = 1.8
	return distance + danger * 1.35 + type_cost

func _region_center_distance(source: Dictionary, target: Dictionary) -> float:
	var source_tile := _region_center_tile(source)
	var target_tile := _region_center_tile(target)
	return Vector2(float(source_tile.x), float(source_tile.y)).distance_to(Vector2(float(target_tile.x), float(target_tile.y)))

func _route_distance(route: Array[String]) -> float:
	if route.size() <= 1:
		return 0.0
	var distance := 0.0
	for index in range(route.size() - 1):
		distance += _region_center_distance(GameData.get_region(route[index]), GameData.get_region(route[index + 1]))
	return roundf(distance * 10.0) / 10.0

func _estimate_route_hours(route: Array[String], target_region: Dictionary) -> float:
	if target_region.is_empty():
		return 0.0
	var distance := _route_distance(route)
	if distance <= 0.0:
		var source_region := _current_travel_source_region()
		distance = _region_center_distance(source_region, target_region)
	var risk_level := _route_risk_level(route)
	if route.is_empty():
		risk_level = int(target_region.get("danger", 1))
	var relay_cost: float = maxf(0.0, float(route.size() - 2)) * 0.35
	var hours := clampf(distance / 7.5 + float(risk_level) * 0.45 + relay_cost, 1.0, 16.0)
	return roundf(hours * 2.0) / 2.0

func _estimate_route_fare(route: Array[String], target_region: Dictionary) -> int:
	if target_region.is_empty():
		return 0
	var hours := _estimate_route_hours(route, target_region)
	var risk_level := _route_risk_level(route)
	if route.is_empty():
		risk_level = int(target_region.get("danger", 1))
	var relay_count: int = maxi(0, route.size() - 2)
	var fare := int(round(hours * 1.6 + float(risk_level) * 2.0 + float(relay_count) * 1.5))
	return maxi(FAST_TRAVEL_MIN_FARE, fare)

func _route_risk_level(route: Array[String]) -> int:
	var risk := 1
	for region_id in route:
		var region := GameData.get_region(region_id)
		if region.is_empty():
			continue
		risk = maxi(risk, int(region.get("danger", 1)))
		var terrain := str(region.get("terrain", ""))
		if (weather == "飞雪" and (terrain.contains("mountain") or terrain.contains("cliff") or terrain.contains("plateau"))) or (weather == "细雨" and (terrain.contains("river") or terrain.contains("lake") or terrain.contains("marsh") or terrain.contains("gorge"))) or (weather == "薄雾" and int(region.get("danger", 1)) >= 3):
			risk = maxi(risk, int(region.get("danger", 1)) + 1)
	return clampi(risk, 1, 5)

func _route_risk_label(risk_level: int) -> String:
	if risk_level >= 5:
		return "极险"
	if risk_level >= 4:
		return "险路"
	if risk_level >= 3:
		return "危险"
	if risk_level >= 2:
		return "谨慎"
	return "平稳"

func _route_risk_note(risk_level: int) -> String:
	if risk_level >= 5:
		return "天气和地势都不利，路上很可能遭遇伏击。"
	if risk_level >= 4:
		return "路段险峻，最好备足伤药。"
	if risk_level >= 3:
		return "沿途有盗匪和暗哨传闻。"
	if risk_level >= 2:
		return "官道可行，但仍需留心。"
	return "多为熟路，适合赶路。"

func _route_region_names(route: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for region_id in route:
		var region := GameData.get_region(region_id)
		if region.is_empty():
			continue
		names.append(str(region.get("name", region_id)))
	return names

func _record_fast_travel_event(plan: Dictionary) -> void:
	var target_id := str(plan.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		return
	var target_name := str(target_region.get("name", target_id))
	var source_name := current_region_name
	var source_region := GameData.get_region(str(plan.get("source_region_id", "")))
	if not source_region.is_empty():
		source_name = str(source_region.get("name", source_name))
	var route_summary := str(plan.get("route_summary", ""))
	var risk_note := str(plan.get("risk_note", ""))
	var fare := int(plan.get("fare", 0))
	var fare_text := "，花费%d两" % fare if fare > 0 else ""
	var description := "你从%s沿驿路赶到%s，用去%.1f时辰%s。" % [source_name, target_name, float(plan.get("hours", 0.0)), fare_text]
	if not route_summary.is_empty():
		description = "你按%s路线赶到%s，用去%.1f时辰%s。" % [route_summary, target_name, float(plan.get("hours", 0.0)), fare_text]
	if not risk_note.is_empty():
		description = "%s%s" % [description, risk_note]
	append_world_event("travel", "驿路抵达%s" % target_name, description, target_id, clampi(int(plan.get("risk_level", 1)), 1, 3))

func advance_time(delta: float) -> void:
	if not can_explore():
		return
	hour += delta * 0.08
	if hour >= 24.0:
		hour -= 24.0
		day += 1
		_roll_weather()
		_run_daily_world_pulse()
	EventBus.time_changed.emit(day, hour, weather)

func _roll_weather() -> void:
	var options := ["晴朗", "多云", "细雨", "薄雾", "飞雪"]
	weather = options[randi_range(0, options.size() - 1)]

func _run_daily_world_pulse() -> void:
	var flag_key := "world_pulse_day_%d" % day
	if bool(game_flags.get(flag_key, false)):
		return
	game_flags[flag_key] = true
	var pulse_event: Dictionary = _build_daily_world_pulse_event()
	if pulse_event.is_empty():
		return
	append_world_event(
		str(pulse_event.get("kind", "world_pulse")),
		str(pulse_event.get("title", "每日风声")),
		str(pulse_event.get("description", "")),
		str(pulse_event.get("region_id", current_region_id)),
		int(pulse_event.get("severity", 2))
	)

func _build_daily_world_pulse_event() -> Dictionary:
	var region: Dictionary = _select_daily_pulse_region()
	if region.is_empty():
		return {}
	var region_id := str(region.get("id", current_region_id))
	var region_name := str(region.get("name", current_region_name))
	var danger := int(region.get("danger", 1))
	var stage := _current_story_stage()
	var selector: int = abs(hash("%d:%s:%s:%s" % [day, region_id, weather, stage])) % 4
	var title := ""
	var description := ""
	var severity := 2
	match selector:
		0:
			title = "%s驿路风声" % region_name
			description = "%s一带%s，脚夫说有陌生人沿着旧路打听%s。" % [region_name, _weather_world_phrase(), stage]
			severity = 2 + int(danger >= 3)
		1:
			title = "%s山门传书" % region_name
			description = "%s附近有人快马递信，信上反复提到%s。" % [region_name, stage]
			severity = 3 if stage.contains("暗影") or stage.contains("七派") else 2
		2:
			title = "%s夜里见影" % region_name
			description = "%s夜间多了几道不报姓名的脚印，客栈里都说这不像寻常盗匪。" % region_name
			severity = 3 + int(danger >= 4)
		_:
			title = "江湖天气转冷"
			description = "%s%s，商旅改了行程，也把%s的风声带到了路口。" % [region_name, _weather_world_phrase(), stage]
			severity = 2
	return {
		"kind": "world_pulse",
		"title": title,
		"description": description,
		"region_id": region_id,
		"severity": clampi(severity, 2, 4)
	}

func _select_daily_pulse_region() -> Dictionary:
	var candidates: Array = []
	for region_id in region_state.keys():
		var state: Dictionary = region_state.get(region_id, {})
		if not bool(state.get("discovered", false)):
			continue
		var region := GameData.get_region(str(region_id))
		if not region.is_empty():
			candidates.append(region)
	if not current_region_id.is_empty():
		var current := GameData.get_region(current_region_id)
		if not current.is_empty() and not candidates.has(current):
			candidates.append(current)
	if not map_target_region_id.is_empty():
		var target := GameData.get_region(map_target_region_id)
		if not target.is_empty() and not candidates.has(target):
			candidates.append(target)
	if candidates.is_empty():
		var fallback := GameData.get_region("qinghe")
		return fallback if not fallback.is_empty() else {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("danger", 1)) > int(b.get("danger", 1))
	)
	var limit: int = mini(candidates.size(), 6)
	var index: int = abs(hash("%d:%s:%s" % [day, weather, active_quest])) % limit
	return (candidates[index] as Dictionary).duplicate(true)

func _current_story_stage() -> String:
	if completed_quests.has("q_main_epilogue_mercy"):
		return "江湖留灯"
	if completed_quests.has("q_main_epilogue_reckoning"):
		return "残影清剿"
	if bool(game_flags.get("story_epilogue_mercy", false)):
		return "江湖留灯"
	if bool(game_flags.get("story_epilogue_reckoning", false)):
		return "残影清剿"
	if completed_quests.has("q_main_old_case_closure"):
		return "旧案终册"
	if completed_quests.has("q_main_after_shadow"):
		return "总坛余烬"
	if completed_quests.has("q_main_shadow_citadel"):
		return "影司总坛余波"
	if completed_quests.has("q_main_blood_moon"):
		return "影司总坛"
	if completed_quests.has("q_main_hidden_master"):
		return "血月残印"
	if completed_quests.has("q_main_wulin_conclave"):
		return "暗影司幕后主使"
	if completed_quests.has("q_main_broken_token"):
		return "七派夜议"
	if completed_quests.has("q_main_shadow_watchers"):
		return "断令和暗影眼线"
	if completed_quests.has("q_main_shadow_letters"):
		return "七派暗号"
	if completed_quests.has("q_hero_trial"):
		return "洛阳旧案"
	if not active_quest.is_empty() and active_quest != "初入平安镇":
		return active_quest
	return "平安镇新来的少侠"

func _weather_world_phrase() -> String:
	match weather:
		"细雨":
			return "雨声压低"
		"薄雾":
			return "雾色很重"
		"飞雪":
			return "雪路难行"
		"多云":
			return "云影不散"
		_:
			return "天色清明"

func _spread_world_event_to_npc_memory(event: Dictionary) -> void:
	var severity := int(event.get("severity", 1))
	if severity < 2:
		return
	var title := str(event.get("title", ""))
	if title.is_empty():
		return
	var targets := _world_event_memory_targets(event)
	var region_name := str(event.get("region_name", ""))
	for npc_name in targets:
		if str(npc_name).is_empty():
			continue
		var state := _ensure_npc_memory(str(npc_name))
		var source := "%s：" % region_name if not region_name.is_empty() else ""
		_append_npc_memory(state, "听闻%s%s" % [source, title])
		npc_memory[str(npc_name)] = state

func _world_event_memory_targets(event: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	var severity := int(event.get("severity", 1))
	if severity >= 4:
		for npc_name in CORE_RUMOR_NPCS:
			targets.append(str(npc_name))
		return targets
	var count := 3 if severity == 2 else 5
	var offset: int = abs(hash("%s:%s:%d" % [
		str(event.get("title", "")),
		str(event.get("region_id", "")),
		day
	])) % CORE_RUMOR_NPCS.size()
	for index in range(count):
		targets.append(str(CORE_RUMOR_NPCS[(offset + index) % CORE_RUMOR_NPCS.size()]))
	return targets

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

func grant_enemy_loot(enemy_data: Dictionary) -> Array[String]:
	var awarded: Array[String] = []
	var loot_entries: Array = enemy_data.get("loot", [])
	if loot_entries.is_empty():
		loot_entries = _default_enemy_loot(enemy_data)
	for entry in loot_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var chance := float(entry.get("chance", 1.0))
		if randf() > chance:
			continue
		var item_id := str(entry.get("item", ""))
		if GameData.get_item(item_id).is_empty():
			continue
		var min_count := int(entry.get("min", entry.get("count", 1)))
		var max_count := int(entry.get("max", entry.get("count", min_count)))
		var count := randi_range(max(1, min_count), max(max_count, min_count))
		add_item(item_id, count)
		var item_name := str(GameData.get_item(item_id).get("name", item_id))
		if count > 1:
			awarded.append("%s x%d" % [item_name, count])
		else:
			awarded.append(item_name)
	return awarded

func _default_enemy_loot(enemy_data: Dictionary) -> Array:
	var name := str(enemy_data.get("name", ""))
	var style := str(enemy_data.get("combat_style", ""))
	if style == "beast" or name.contains("豹") or name.contains("兽"):
		return [{"item": "item_meat", "chance": 0.85}]
	if style == "assassin" or name.contains("盗"):
		return [
			{"item": "item_dagger", "chance": 0.22},
			{"item": "item_yao", "chance": 0.45}
		]
	if style == "boss" or name.contains("神秘") or name.contains("头目"):
		return [
			{"item": "item_dan", "chance": 0.55},
			{"item": "item_shengji", "chance": 0.40}
		]
	if name.contains("流氓") or style == "brawler":
		return [
			{"item": "item_baozi", "chance": 0.45},
			{"item": "item_wine", "chance": 0.20}
		]
	return [{"item": "item_yao", "chance": 0.25}]

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

func buy_item(item_id: String, count: int = 1, price_override: int = -1) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if count <= 0:
		return false
	var price := int(item.get("price", 0))
	if price_override >= 0:
		price = price_override
	var total_price := price * count
	if not spend_money(total_price):
		return false
	add_item(item_id, count)
	if count > 1:
		EventBus.emit_toast("买入%s x%d" % [str(item.get("name", item_id)), count])
	else:
		EventBus.emit_toast("买入%s" % str(item.get("name", item_id)))
	return true

func sell_item(item_id: String, count: int = 1, price_override: int = -1) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if count <= 0:
		return false
	if int(inventory.get(item_id, 0)) < count:
		return false
	if equipment.values().has(item_id):
		EventBus.emit_toast("已装备的物品不能出售")
		return false
	var price := price_override if price_override >= 0 else get_item_sell_price(item_id)
	if not remove_item(item_id, count):
		return false
	player["money"] = int(player.get("money", 0)) + price * count
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("卖出%s，获得%d两" % [str(item.get("name", item_id)), price * count])
	return true

func get_item_sell_price(item_id: String) -> int:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	return maxi(1, int(round(float(item.get("price", 0)) * 0.45)))

func rest(cost: int = 12) -> bool:
	if not spend_money(cost):
		return false
	heal_player(int(player.get("max_hp", 100)))
	restore_mp(int(player.get("max_mp", 50)))
	advance_hours(4.0)
	EventBus.emit_toast("休息完毕")
	return true

func accept_quest(quest_id: String) -> bool:
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return false
	var block_reason := get_quest_block_reason(quest_id)
	if not block_reason.is_empty():
		EventBus.emit_toast(block_reason)
		return false
	active_quests[quest_id] = {"progress": {}}
	active_quest = str(quest.get("title", quest_id))
	_sync_existing_objective_progress(quest_id)
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(player)
	_check_quest_completion(quest_id)
	EventBus.emit_toast("接到任务：%s" % active_quest)
	return true

func _start_quest_silently(quest_id: String) -> void:
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return
	active_quests[quest_id] = {"progress": {}}
	active_quest = str(quest.get("title", quest_id))
	_sync_existing_objective_progress(quest_id)

func can_accept_quest(quest_id: String) -> bool:
	return get_quest_block_reason(quest_id).is_empty()

func get_quest_block_reason(quest_id: String) -> String:
	if quest_id.is_empty():
		return "任务不存在"
	if active_quests.has(quest_id):
		return "任务已经在进行中"
	if completed_quests.has(quest_id):
		return "任务已经完成"
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return "任务不存在"
	var min_level := int(quest.get("min_level", 0))
	if min_level > 0 and int(player.get("level", 1)) < min_level:
		return "等级达到 %d 后再来" % min_level
	var required_faction := str(quest.get("required_faction", ""))
	if not required_faction.is_empty() and str(player.get("faction", "none")) != required_faction:
		return "需先拜入%s" % GameData.get_faction_name(required_faction)
	var required_completed: Array = quest.get("requires_completed", [])
	for required_id in required_completed:
		var required_quest_id := str(required_id)
		if not completed_quests.has(required_quest_id):
			var required_quest := GameData.get_quest(required_quest_id)
			return "需先完成【%s】" % str(required_quest.get("title", required_quest_id))
	var required_flags: Array = quest.get("requires_flags", [])
	for flag in required_flags:
		if not bool(game_flags.get(str(flag), false)):
			return "线索还不够"
	return ""

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
	var skills: Dictionary = rewards.get("skills", {})
	for skill_id in skills.keys():
		learn_skill(str(skill_id), int(skills[skill_id]))
	if not active_quests.is_empty():
		var first_id := str(active_quests.keys()[0])
		active_quest = str(GameData.get_quest(first_id).get("title", first_id))
	else:
		active_quest = str(quest.get("next_hint", "自由探索江湖"))
	_record_quest_world_event(quest_id, quest)
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(player)
	EventBus.emit_toast("完成任务：%s" % str(quest.get("title", quest_id)))
	if quest_id == "q_hero_trial":
		game_flags["alpha_clear"] = true
		active_quest = "江湖初成"
		EventBus.player_changed.emit(player)
		EventBus.emit_toast("阶段通关：江湖初成")

func _record_quest_world_event(quest_id: String, quest: Dictionary) -> void:
	var quest_title := str(quest.get("title", quest_id))
	match quest_id:
		"q_intro_town":
			append_world_event("quest", "平安镇有人问路", "客栈与衙门都记住了你的名字，镇东的麻烦开始浮出水面。", "qinghe", 2)
		"q_clear_thugs":
			append_world_event("quest", "镇东恶徒受挫", "平安镇东路清静了些，但余党背后的线仍未断。", "qinghe", 3)
		"q_flower_thief":
			append_world_event("quest", "采花大盗伏诛", "镇上传开消息，说有少侠追上了轻功了得的采花大盗。", "qinghe", 3)
		"q_hero_trial":
			append_world_event("story", "江湖初成", "神秘人败退，洛阳旧案和暗影司的名字开始连在一起。", "luoyang", 4)
		"q_main_luoyang_ashes":
			append_world_event("story", "洛阳旧火重燃", "苏家旧案重新被人提起，武林盟旧卷也不再安静。", "luoyang", 4)
		"q_main_shadow_letters":
			append_world_event("story", "暗影书信现世", "两封密信牵出七派暗号，山门之间的信任有了裂纹。", "changan", 4)
		"q_main_sect_warnings":
			append_world_event("story", "七派风声渐紧", "太极、雪山、逍遥都听见了暗影司的脚步，夜路开始不太平。", "wudang", 4)
		"q_main_shadow_watchers":
			append_world_event("story", "暗影眼线暴露", "黑衣大盗带着半截密令败退，暗影司藏在路上的眼睛少了一只。", "changan", 4)
		"q_main_broken_token":
			append_world_event("story", "断令归卷", "断令花纹与武林盟旧卷对上，七派夜议已有了真正的证据。", "luoyang", 4)
		"q_main_wulin_conclave":
			var conclave_detail := "七派可信之人开始合拢证据，暗影司幕后主使不再只是传闻。"
			if bool(game_flags.get("story_conclave_public", false)):
				conclave_detail = "你先公开断令取信七派，夜议成局后，暗影司也不得不从暗处露出破绽。"
			elif bool(game_flags.get("story_conclave_secret", false)):
				conclave_detail = "你先暗查旧账稳住线人，夜议成局时，暗影司几条暗线已被悄悄拔掉。"
			append_world_event("story", "武林夜议成局", conclave_detail, "wudang", 5)
		"q_main_hidden_master":
			append_world_event("story", "血月残印现世", "血月使者败退，暗影司旧账里第一次露出无面主事的名字。", "changan", 5)
		"q_main_blood_moon":
			append_world_event("story", "无面账册归卷", "无面君失手，苏家账册把暗影司总坛方位推到了七派眼前。", "luoyang", 5)
		"q_main_shadow_citadel":
			append_world_event("story", "影司总坛暂破", "暗影司影主败退，总坛暗道被封，江湖各派终于有了短暂喘息。", "daba_mtn", 5)
		"q_main_after_shadow":
			append_world_event("story", "总坛余烬未灭", "苏梦瑶、陈天行与花间暗线开始清点暗影司残部，苏家旧账终于能翻到最后几页。", "luoyang", 5)
		"q_main_old_case_closure":
			append_world_event("story", "旧案终册落印", "武林盟与七派共同落印，苏家旧案暂得收束；江湖尾声的路开始分岔。", "luoyang", 6)
		"q_main_epilogue_mercy":
			append_world_event("story", "江湖留灯", "苏梦瑶与七派共同封存旧案，只清点首恶和铁证，几处被胁迫的暗线得以改过。", "luoyang", 6)
		"q_main_epilogue_reckoning":
			append_world_event("story", "残影清剿", "陈天行与武林盟连夜清查暗影司残部，几条蛰伏多年的旧怨被翻到明面。", "changan", 6)
		_:
			append_world_event("quest", "完成%s" % quest_title, "你办完了%s，附近江湖人多了一桩谈资。" % quest_title, current_region_id, 2)

func _objective_key(objective: Dictionary) -> String:
	return "%s:%s" % [str(objective.get("type", "")), str(objective.get("target", ""))]

func get_quest_status_lines() -> Array[String]:
	var lines: Array[String] = []
	var active_hint := get_active_story_quest_hint()
	if not active_hint.is_empty():
		lines.append(active_hint)
		lines.append("")
	if active_quests.is_empty():
		lines.append("暂无进行中的任务。")
		if not active_quest.is_empty():
			lines.append("线索：%s" % active_quest)
	for quest_id in active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		lines.append("【进行中】%s" % str(quest.get("title", quest_id)))
		var description := str(quest.get("description", ""))
		if not description.is_empty():
			lines.append("  %s" % description)
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
	var choice_lines := get_story_choice_status_lines()
	if not choice_lines.is_empty():
		lines.append("")
		lines.append("剧情抉择：")
		for line in choice_lines:
			lines.append("  - %s" % line)
	var events := get_recent_world_events(5)
	if not events.is_empty():
		lines.append("")
		lines.append("江湖传闻：")
		for event in events:
			var entry: Dictionary = event
			lines.append("  - 第%d日 %s：%s" % [
				int(entry.get("day", day)),
				str(entry.get("title", "传闻")),
				str(entry.get("description", ""))
			])
	return lines

func get_active_quest_tracker() -> String:
	if active_quests.is_empty():
		return active_quest
	for quest_id in active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		var progress: Dictionary = active_quests[quest_id].get("progress", {})
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			var key := _objective_key(objective)
			var current := int(progress.get(key, 0))
			var required := int(objective.get("count", 1))
			if current < required:
				return "%s：%s %d/%d" % [
					str(quest.get("title", quest_id)),
					str(objective.get("label", key)),
					min(current, required),
					required
				]
		return str(quest.get("title", quest_id))
	return active_quest

func get_active_story_quest_hint() -> String:
	var quest_id := _primary_active_quest_id()
	if quest_id.is_empty():
		if active_quest.is_empty() or active_quest == "自由探索江湖":
			return "下一步：打开任务日志查看可接线索，或去地图寻找任务标记。"
		return "下一步：%s" % active_quest
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return ""
	var objective := _first_incomplete_objective(quest_id)
	if objective.is_empty():
		return "下一步：%s 目标已达成，等待任务结算。" % str(quest.get("title", quest_id))
	var label := str(objective.get("label", _objective_key(objective)))
	var detail := _objective_hint(objective)
	if detail.is_empty():
		detail = label
	return "下一步：%s · %s" % [str(quest.get("title", quest_id)), detail]

func _primary_active_quest_id() -> String:
	for quest_id in active_quests.keys():
		var id := str(quest_id)
		if id.begins_with("q_main_"):
			return id
	for story_id in STORY_QUEST_PRIORITY:
		if active_quests.has(story_id):
			return story_id
	if active_quests.is_empty():
		return ""
	return str(active_quests.keys()[0])

func _first_incomplete_objective(quest_id: String) -> Dictionary:
	if not active_quests.has(quest_id):
		return {}
	var quest := GameData.get_quest(quest_id)
	var quest_state: Dictionary = active_quests.get(quest_id, {})
	var progress: Dictionary = quest_state.get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var objective_data: Dictionary = objective
		var key := _objective_key(objective_data)
		var current := int(progress.get(key, 0))
		var required := int(objective_data.get("count", 1))
		if current < required:
			return objective_data
	return {}

func _objective_hint(objective: Dictionary) -> String:
	var kind := str(objective.get("type", ""))
	var target := str(objective.get("target", ""))
	var label := str(objective.get("label", _objective_key(objective)))
	match kind:
		"talk":
			return _target_action_hint(target, "找%s交谈" % target)
		"kill":
			return _target_action_hint(target, "击败%s" % target)
		"collect":
			return "%s；可从商铺、掉落或探索中取得" % label
		"skill":
			return "%s；打开修炼面板提升对应武学" % label
		_:
			return label

func _target_action_hint(target: String, action_text: String) -> String:
	var region := _target_region(target)
	if region.is_empty():
		return action_text
	var region_id := str(region.get("id", ""))
	var region_name := str(region.get("name", region_id))
	if region_id == current_region_id:
		return "在%s%s" % [region_name, action_text]
	return "前往%s%s" % [region_name, action_text]

func _target_region(target: String) -> Dictionary:
	var npc := GameData.get_npc_by_name(target)
	if npc.is_empty():
		return {}
	var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
	if tile.x < 0 or tile.y < 0:
		return {}
	return GameData.get_region_at_tile(tile)

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
			"npc_memory": npc_memory,
			"region_state": region_state,
			"world_events": world_events,
			"active_quest": active_quest,
		"day": day,
		"hour": hour,
		"weather": weather,
		"map_target_region_id": map_target_region_id,
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
	npc_memory = snapshot.get("npc_memory", {})
	region_state = snapshot.get("region_state", {})
	world_events = snapshot.get("world_events", [])
	active_quest = str(snapshot.get("active_quest", "自由探索江湖"))
	day = int(snapshot.get("day", 1))
	hour = float(snapshot.get("hour", 8.0))
	weather = str(snapshot.get("weather", "晴朗"))
	map_target_region_id = str(snapshot.get("map_target_region_id", ""))
	var pos: Dictionary = snapshot.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	current_tile = Vector2i(floori(player_position.x / GameData.TILE_SIZE), floori(player_position.y / GameData.TILE_SIZE))
	set_mode(Mode.EXPLORE)
	EventBus.player_changed.emit(player)
	EventBus.inventory_changed.emit(inventory)
	EventBus.quests_changed.emit()
	EventBus.world_events_changed.emit(get_recent_world_events(30))
	EventBus.time_changed.emit(day, hour, weather)
	EventBus.map_target_changed.emit(map_target_region_id)
