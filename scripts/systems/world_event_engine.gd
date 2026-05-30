extends Node
## 世界事件引擎 - 动态事件、派系战争、节日活动

signal world_event_triggered(event_id: String, event_data: Dictionary)
signal world_event_ended(event_id: String)
signal faction_war_started(faction1: int, faction2: int)
signal faction_war_ended(faction1: int, faction2: int)
signal festival_started(festival_id: String)
signal special_day_triggered(day_type: String)

var _active_events: Dictionary = {}
var _event_history: Array = []
var _faction_relations: Dictionary = {}
var _world_conditions: Dictionary = {}
var _scheduled_events: Array = []

func _ready() -> void:
	_init_faction_relations()

func _init_faction_relations() -> void:
	var factions: Array = [
		Constants.Faction.BAGUA,
		Constants.Faction.FLOWER,
		Constants.Faction.HONGLIAN,
		Constants.Faction.NAJA,
		Constants.Faction.TAIJI,
		Constants.Faction.XUESHAN
	]
	
	for f1 in factions:
		for f2 in factions:
			if f1 != f2:
				var key: String = str(f1) + "_" + str(f2)
				_faction_relations[key] = {
					"relation": 0,
					"is_war": false,
					"war_start_day": 0,
					"tension": 0
				}

func _process(delta: float) -> void:
	_update_world_events(delta)
	_check_scheduled_events()
	_update_faction_tensions(delta)

func _update_world_events(delta: float) -> void:
	var to_end: Array = []
	
	for event_id: String in _active_events:
		var event: Dictionary = _active_events[event_id]
		event["remaining_time"] -= delta
		
		if event.get("remaining_time", 0) <= 0:
			to_end.append(event_id)
	
	for event_id: String in to_end:
		_end_world_event(event_id)

func _update_faction_tensions(delta: float) -> void:
	for key: String in _faction_relations:
		var relation: Dictionary = _faction_relations[key]
		
		if relation.get("is_war", false):
			continue
		
		var tension: float = relation.get("tension", 0)
		
		tension += randf_range(-0.1, 0.2) * delta
		
		if tension >= 80 and not relation.get("is_war", false):
			_start_faction_war(key)
		
		relation["tension"] = clamp(tension, 0, 100)

func _check_scheduled_events() -> void:
	var current_day: int = 1
	if WorldManager and WorldManager.get("day_number") != null:
		current_day = WorldManager.day_number
	
	for scheduled: Dictionary in _scheduled_events:
		if scheduled.get("triggered", false):
			continue
		
		if current_day >= scheduled.get("day", 1):
			trigger_world_event(scheduled.get("event_id", ""))
			scheduled["triggered"] = true

func trigger_world_event(event_id: String) -> bool:
	if _active_events.has(event_id):
		return false
	
	var event: Dictionary = _get_event_template(event_id)
	if event.is_empty():
		return false
	
	event["id"] = event_id
	event["remaining_time"] = event.get("duration", 300)
	
	_active_events[event_id] = event
	world_event_triggered.emit(event_id, event)
	
	_apply_event_effects(event)
	
	return true

func _get_event_template(event_id: String) -> Dictionary:
	var events: Dictionary = {
		"moon_festival": {
			"name": "中秋明月夜",
			"description": "中秋佳节，月圆之夜，江湖各派共庆。",
			"duration": 600,
			"effects": {
				"shop_discount": 0.2,
				"reputation_gain": 1.5
			},
			"requirements": {"day_mod": 15}
		},
		"jianghu_convention": {
			"name": "华山论剑",
			"description": "五年一度的华山论剑即将开始，各派高手云集。",
			"duration": 900,
			"effects": {
				"player_exp": 2.0,
				"npc_spawn": ["sword_master", "martial_hero"]
			},
			"requirements": {"day_mod": 0}
		},
		"red_faction_uprising": {
			"name": "红莲教起义",
			"description": "红莲教高举义旗，宣称要推翻现有秩序！",
			"duration": 1200,
			"effects": {
				"faction_hostile": [Constants.Faction.HONGLIAN]
			},
			"requirements": {"min_day": 60}
		},
		"plague_outbreak": {
			"name": "瘟疫横行",
			"description": "一种神秘的瘟疫在民间蔓延...",
			"duration": 800,
			"effects": {
				"merchant_spawn_chance": 0.5,
				"player_hp_regen": -0.5
			},
			"requirements": {"min_day": 30}
		},
		"rare_herb_season": {
			"name": "灵草丰产",
			"description": "今年灵草丰收，是采集的好时机。",
			"duration": 500,
			"effects": {
				"herb_drop_chance": 2.0
			},
			"requirements": {}
		},
		"bandit_rampage": {
			"name": "山贼肆虐",
			"description": "山贼活动猖獗，商旅苦不堪言。",
			"duration": 600,
			"effects": {
				"ambush_chance": 2.0,
				"gold_drop": 1.5
			},
			"requirements": {}
		},
		"elder_appreciation": {
			"name": "尊老爱幼",
			"description": "武林前辈举办寿宴，广邀江湖人士。",
			"duration": 400,
			"effects": {
				"reputation_gain": 2.0,
				"quest_available": "elder_celebration"
			},
			"requirements": {}
		},
		"war_preparation": {
			"name": "战云密布",
			"description": "各派似乎在秘密调动人手，战争一触即发...",
			"duration": 700,
			"effects": {
				"faction_tension": 30,
				"item_price_weapon": 1.3
			},
			"requirements": {"min_day": 90}
		}
	}
	
	return events.get(event_id, {})

func _apply_event_effects(event: Dictionary) -> void:
	var effects: Dictionary = event.get("effects", {})
	
	for effect_key: String in effects:
		match effect_key:
			"faction_hostile":
				var factions: Array = effects.get("faction_hostile", [])
				for faction_id: int in factions:
					_set_faction_hostile(faction_id)
			"shop_discount":
				var discount: float = effects.get("shop_discount", 0)
				EconomySystem.apply_price_modifier("all", 1.0 - discount, event.get("duration", 300))

func _end_world_event(event_id: String) -> void:
	if not _active_events.has(event_id):
		return
	
	var event: Dictionary = _active_events[event_id]
	_active_events.erase(event_id)
	
	_event_history.append({
		"event_id": event_id,
		"event_name": event.get("name", ""),
		"end_day": WorldManager.day_number if WorldManager and WorldManager.get("day_number") != null else 0
	})
	
	world_event_ended.emit(event_id)

func _start_faction_war(relation_key: String) -> void:
	if not _faction_relations.has(relation_key):
		return
	
	var parts: Array = relation_key.split("_")
	if parts.size() < 2:
		return
	
	var faction1: int = int(parts[0])
	var faction2: int = int(parts[1])
	
	var relation: Dictionary = _faction_relations[relation_key]
	relation["is_war"] = true
	relation["war_start_day"] = WorldManager.day_number if WorldManager and WorldManager.get("day_number") != null else 0
	
	faction_war_started.emit(faction1, faction2)
	
	trigger_world_event("faction_war_" + relation_key)

func end_faction_war(relation_key: String, winner: int) -> void:
	if not _faction_relations.has(relation_key):
		return
	
	var relation: Dictionary = _faction_relations[relation_key]
	relation["is_war"] = false
	relation["tension"] = 20
	
	var parts: Array = relation_key.split("_")
	if parts.size() >= 2:
		faction_war_ended.emit(int(parts[0]), int(parts[1]))

func _set_faction_hostile(faction_id: int) -> void:
	var player_data: PlayerData = DataRegistry.get_player_data()
	if player_data.faction == faction_id:
		return
	
	FactionSystem.add_reputation(faction_id, -500)

func modify_faction_relation(faction1: int, faction2: int, amount: int) -> void:
	var key1: String = str(faction1) + "_" + str(faction2)
	var key2: String = str(faction2) + "_" + str(faction1)
	
	if _faction_relations.has(key1):
		_faction_relations[key1]["relation"] += amount
		_faction_relations[key1]["tension"] += amount * 0.5
	
	if _faction_relations.has(key2):
		_faction_relations[key2]["relation"] += amount
		_faction_relations[key2]["tension"] += amount * 0.5

func get_faction_relation(faction1: int, faction2: int) -> Dictionary:
	var key: String = str(faction1) + "_" + str(faction2)
	
	if _faction_relations.has(key):
		return _faction_relations[key].duplicate()
	
	return {"relation": 0, "is_war": false, "tension": 0}

func schedule_event(event_id: String, day: int) -> void:
	_scheduled_events.append({
		"event_id": event_id,
		"day": day,
		"triggered": false
	})

func get_active_events() -> Array:
	var active: Array = []
	for event_id: String in _active_events:
		active.append(_active_events[event_id].duplicate())
	return active

func get_event_history() -> Array:
	return _event_history.duplicate()

func is_faction_at_war(faction_id: int) -> bool:
	for key: String in _faction_relations:
		var relation: Dictionary = _faction_relations[key]
		if relation.get("is_war", false):
			var parts: Array = key.split("_")
			if parts.size() >= 2:
				if int(parts[0]) == faction_id or int(parts[1]) == faction_id:
					return true
	return false

func to_dictionary() -> Dictionary:
	return {
		"active_events": _active_events.duplicate(true),
		"event_history": _event_history.duplicate(),
		"faction_relations": _faction_relations.duplicate(true),
		"scheduled_events": _scheduled_events.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	_active_events = data.get("active_events", {}).duplicate(true)
	_event_history = data.get("event_history", []).duplicate()
	_faction_relations = data.get("faction_relations", {}).duplicate(true)
	_scheduled_events = data.get("scheduled_events", []).duplicate()
