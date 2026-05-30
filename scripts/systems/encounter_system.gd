extends Node
## 遭遇系统 - 随机事件、奇遇、NPC遭遇

signal encounter_started(encounter_type: String, data: Dictionary)
signal encounter_completed(encounter_type: String, rewards: Dictionary)
signal encounter_failed(encounter_type: String)
signal npc_encounter(npc_data: Dictionary)
signal treasure_encounter(treasure_data: Dictionary)
signal special_event(event_data: Dictionary)

enum EncounterType {
	RANDOM_NPC,
	TREASURE,
	AMBUSH,
	SPECIAL_EVENT,
	SCENE
}

var _encounter_cooldowns: Dictionary = {}
var _active_encounter: Dictionary = {}
var _encounter_pool: Array = []
var _special_encounters: Dictionary = {}

func _ready() -> void:
	_init_encounter_pool()

func _init_encounter_pool() -> void:
	_encounter_pool = [
		{"type": "random_npc", "weight": 30, "min_level": 1},
		{"type": "treasure", "weight": 20, "min_level": 1},
		{"type": "ambush", "weight": 15, "min_level": 3},
		{"type": "special_event", "weight": 10, "min_level": 1},
		{"type": "merchant", "weight": 15, "min_level": 1},
		{"type": "wounded_warrior", "weight": 10, "min_level": 5}
	]
	
	_special_encounters = {
		"master_appearance": {
			"id": "master_appearance",
			"type": "special_event",
			"title": "名师出现",
			"description": "一位神秘高手出现在你面前...",
			"requirements": {"min_level": 10, "no_faction": true},
			"outcomes": [
				{"type": "teach_skill", "skill_id": "secret_technique", "probability": 0.3},
				{"type": "give_item", "item_id": "ancient_scroll", "probability": 0.4},
				{"type": "gain_reputation", "faction_id": 1, "amount": 50, "probability": 0.3}
			]
		},
		"hidden_cultivation": {
			"id": "hidden_cultivation",
			"type": "special_event",
			"title": "隐世修炼",
			"description": "你发现了一处适合修炼的绝佳场所...",
			"requirements": {"min_level": 5},
			"outcomes": [
				{"type": "cultivation_boost", "amount": 500, "probability": 0.6},
				{"type": "breakthrough", "probability": 0.2},
				{"type": "discover_secret", "probability": 0.2}
			]
		},
		"ancient_ruins": {
			"id": "ancient_ruins",
			"type": "treasure",
			"title": "古墓遗迹",
			"description": "你发现了一座神秘的古代遗迹...",
			"requirements": {"zone_type": "wilderness"},
			"outcomes": [
				{"type": "treasure", "items": ["ancient_sword", "golden_needle"], "probability": 0.4},
				{"type": "trap", "damage": 50, "probability": 0.2},
				{"type": "cultivation_gain", "amount": 300, "probability": 0.4}
			]
		}
	}

func check_for_encounter(player_level: int, zone_type: String, zone_id: String) -> Dictionary:
	var roll: float = randf() * 100
	var cumulative: float = 0.0
	
	var total_weight: float = 0.0
	for encounter: Dictionary in _encounter_pool:
		if encounter.get("min_level", 1) <= player_level:
			total_weight += encounter.get("weight", 10)
	
	for encounter: Dictionary in _encounter_pool:
		if encounter.get("min_level", 1) > player_level:
			continue
		
		cumulative += encounter.get("weight", 10) / total_weight * 100
		
		if roll <= cumulative:
			var cooldown_key: String = encounter.get("type", "") + "_" + zone_id
			
			if _is_on_cooldown(cooldown_key):
				continue
			
			return _trigger_encounter(encounter, zone_id)
	
	return {}

func _trigger_encounter(encounter: Dictionary, zone_id: String) -> Dictionary:
	var encounter_type: String = encounter.get("type", "random_npc")
	var result: Dictionary = {
		"type": encounter_type,
		"zone_id": zone_id
	}
	
	match encounter_type:
		"random_npc":
			result.merge(_generate_npc_encounter())
		"treasure":
			result.merge(_generate_treasure_encounter())
		"ambush":
			result.merge(_generate_ambush_encounter())
		"merchant":
			result.merge(_generate_merchant_encounter())
		"wounded_warrior":
			result.merge(_generate_wounded_warrior_encounter())
		"special_event":
			result.merge(_trigger_special_event())
	
	_active_encounter = result
	encounter_started.emit(encounter_type, result)
	
	return result

func _generate_npc_encounter() -> Dictionary:
	var npc_types: Array = ["traveler", "hermit", "beggar", "cultivator", "merchant"]
	var npc_type: String = npc_types[randi() % npc_types.size()]
	
	return {
		"npc_type": npc_type,
		"dialogue": _get_npc_dialogue(npc_type),
		"can_interact": true,
		"rewards": {"reputation": randi() % 20}
	}

func _generate_treasure_encounter() -> Dictionary:
	var treasures: Array = [
		{"name": "散落的银两", "gold": randi() % 50 + 20, "probability": 0.5},
		{"name": "破损的秘籍", "skill_chance": 0.3, "probability": 0.3},
		{"name": "珍贵药材", "item": "rare_herb", "probability": 0.2}
	]
	
	var selected: Dictionary = treasures[randi() % treasures.size()]
	
	return {
		"treasure_name": selected.get("name", "未知宝物"),
		"gold": selected.get("gold", 0),
		"item": selected.get("item", ""),
		"skill_chance": selected.get("skill_chance", 0),
		"can_collect": true
	}

func _generate_ambush_encounter() -> Dictionary:
	var enemy_count: int = randi() % 3 + 1
	var enemies: Array = []
	
	for i in range(enemy_count):
		enemies.append({
			"type": "bandit",
			"level": randi() % 5 + 1,
			"hp": randi() % 50 + 30
		})
	
	return {
		"enemy_count": enemy_count,
		"enemies": enemies,
		"is_combat": true
	}

func _generate_merchant_encounter() -> Dictionary:
	return {
		"merchant_name": _get_random_merchant_name(),
		"inventory": _generate_merchant_inventory(),
		"can_trade": true,
		"buy_multiplier": 1.0,
		"sell_multiplier": 0.8
	}

func _generate_wounded_warrior_encounter() -> Dictionary:
	return {
		"warrior_name": _get_random_warrior_name(),
		"story": "这位武林人士身受重伤，似乎需要帮助...",
		"can_help": true,
		"help_rewards": {"reputation": 30, "gold": 100}
	}

func _trigger_special_event() -> Dictionary:
	var available_events: Array = []
	
	for event_id: String in _special_encounters:
		var event: Dictionary = _special_encounters[event_id]
		if _check_event_requirements(event.get("requirements", {})):
			available_events.append(event)
	
	if available_events.is_empty():
		return _generate_npc_encounter()
	
	var selected_event: Dictionary = available_events[randi() % available_events.size()]
	
	return {
		"event_id": selected_event.get("id", ""),
		"title": selected_event.get("title", ""),
		"description": selected_event.get("description", ""),
		"outcomes": selected_event.get("outcomes", []),
		"is_choice": true
	}

func _check_event_requirements(requirements: Dictionary) -> bool:
	if requirements.has("min_level"):
		var player_level: int = 1
		if has_meta("player_level"):
			player_level = get_meta("player_level")
		if player_level < requirements.get("min_level", 1):
			return false
	
	if requirements.has("no_faction"):
		var player_faction: int = Constants.Faction.NONE
		if has_meta("player_faction"):
			player_faction = get_meta("player_faction")
		if player_faction != Constants.Faction.NONE:
			return false
	
	return true

func _get_npc_dialogue(npc_type: String) -> String:
	var dialogues: Dictionary = {
		"traveler": ["江湖险恶，壮士多加小心。", "听闻前方有大事发生..."],
		"hermit": ["道法自然，顺其自然。", "名利如浮云，唯有修行是真。"],
		"beggar": ["行行好，给点银两吧...", "最近江湖不太平啊。"],
		"cultivator": ["修炼之道，贵在坚持。", "你的根骨不错，可愿随我修行？"],
		"merchant": ["我这里有上好的货物，要不要看看？", "各地的奇珍异宝，应有尽有。"]
	}
	
	var npc_dialogues: Array = dialogues.get(npc_type, ["..."])
	return npc_dialogues[randi() % npc_dialogues.size()]

func _get_random_merchant_name() -> String:
	var names: Array = ["李掌柜", "王商人", "赵掌柜", "钱老板", "孙商人"]
	return names[randi() % names.size()]

func _get_random_warrior_name() -> String:
	var names: Array = ["无名侠客", "落魄剑客", "负伤高手", "逃亡武者"]
	return names[randi() % names.size()]

func _generate_merchant_inventory() -> Array:
	var items: Array = [
		{"item_id": "health_potion", "price": 50, "stock": 5},
		{"item_id": "mana_potion", "price": 75, "stock": 3},
		{"item_id": "iron_sword", "price": 200, "stock": 1}
	]
	return items

func _is_on_cooldown(cooldown_key: String) -> bool:
	if not _encounter_cooldowns.has(cooldown_key):
		return false
	
	var last_time: float = _encounter_cooldowns[cooldown_key]
	var current_time: float = Time.get_ticks_msec() / 1000.0
	return current_time - last_time < 60.0

func _set_cooldown(cooldown_key: String) -> void:
	_encounter_cooldowns[cooldown_key] = Time.get_ticks_msec() / 1000.0

func resolve_encounter(choice: String, outcome_index: int = 0) -> Dictionary:
	if _active_encounter.is_empty():
		return {}
	
	var result: Dictionary = {
		"success": false,
		"rewards": {},
		"message": ""
	}
	
	match _active_encounter.get("type", ""):
		"treasure":
			result = _resolve_treasure_encounter(choice)
		"ambush":
			result = _resolve_ambush_encounter(choice)
		"special_event":
			result = _resolve_special_event(outcome_index)
	
	_active_encounter.clear()
	
	if result.get("success", false):
		encounter_completed.emit(_active_encounter.get("type", ""), result.get("rewards", {}))
	else:
		encounter_failed.emit(_active_encounter.get("type", ""))
	
	return result

func _resolve_treasure_encounter(choice: String) -> Dictionary:
	if choice == "collect":
		var rewards: Dictionary = {
			"gold": _active_encounter.get("gold", 0),
			"items": [_active_encounter.get("item", "")] if _active_encounter.has("item") else []
		}
		return {
			"success": true,
			"rewards": rewards,
			"message": "你获得了宝物！"
		}
	return {"success": false, "message": "你选择放弃。", "rewards": {}}

func _resolve_ambush_encounter(choice: String) -> Dictionary:
	if choice == "fight":
		return {
			"success": true,
			"rewards": {"exp": 100, "gold": randi() % 50},
			"message": "你击退了袭击者！"
		}
	elif choice == "flee":
		return {
			"success": true,
			"rewards": {},
			"message": "你成功逃脱了！"
		}
	return {"success": false, "message": "逃跑失败！", "rewards": {}}

func _resolve_special_event(outcome_index: int) -> Dictionary:
	var outcomes: Array = _active_encounter.get("outcomes", [])
	
	if outcome_index < 0 or outcome_index >= outcomes.size():
		return {"success": false, "message": "无效选择。", "rewards": {}}
	
	var outcome: Dictionary = outcomes[outcome_index]
	var reward_type: String = outcome.get("type", "")
	
	var result: Dictionary = {"success": true, "rewards": {}, "message": ""}
	
	match reward_type:
		"cultivation_boost":
			result["rewards"]["cultivation"] = outcome.get("amount", 100)
			result["message"] = "你的修为有所提升！"
		"breakthrough":
			result["rewards"]["breakthrough"] = true
			result["message"] = "你突破了境界！"
		"gain_reputation":
			result["rewards"]["reputation"] = outcome.get("amount", 50)
			result["message"] = "你的声望提升了！"
		"treasure":
			result["rewards"]["items"] = outcome.get("items", [])
			result["message"] = "你获得了宝物！"
	
	return result

func get_active_encounter() -> Dictionary:
	return _active_encounter.duplicate()

func clear_encounter() -> void:
	_active_encounter.clear()
