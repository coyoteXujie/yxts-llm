class_name PlayerData extends Resource
## 数据层 - 玩家数据，纯数据定义

@export var player_name: String = "无名侠客"
@export var level: int = 1
@export var exp: int = 0
@export var exp_to_next: int = 100
@export var gold: int = 0

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_mp: int = 50
@export var current_mp: int = 50

@export var strength: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10
@export var constitution: int = 10

@export var position: Vector2 = Vector2.ZERO
@export var current_zone: String = "pingan_town"
@export var faction: int = Constants.Faction.NONE
@export var faction_rank: int = 0

@export var equipment: Dictionary = {}
@export var inventory: Array[Dictionary] = []
@export var skills: Array[Dictionary] = []

@export var faction_reputation: Dictionary = {}
@export var story_flags: Dictionary = {}
@export var completed_quests: Array[String] = []
@export var active_quests: Array[Dictionary] = []

@export var play_time_seconds: float = 0.0
@export var enemies_killed: int = 0
@export var quests_completed: int = 0
@export var items_collected: int = 0
@export var distance_traveled: float = 0.0

func to_dictionary() -> Dictionary:
	return {
		"player_name": player_name,
		"level": level,
		"exp": exp,
		"exp_to_next": exp_to_next,
		"gold": gold,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_mp": max_mp,
		"current_mp": current_mp,
		"strength": strength,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"constitution": constitution,
		"position": {"x": position.x, "y": position.y},
		"current_zone": current_zone,
		"faction": faction,
		"faction_rank": faction_rank,
		"equipment": equipment.duplicate(),
		"inventory": inventory.duplicate(),
		"skills": skills.duplicate(),
		"faction_reputation": faction_reputation.duplicate(),
		"story_flags": story_flags.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"active_quests": active_quests.duplicate(),
		"play_time_seconds": play_time_seconds,
		"enemies_killed": enemies_killed,
		"quests_completed": quests_completed,
		"items_collected": items_collected,
		"distance_traveled": distance_traveled
	}

func from_dictionary(data: Dictionary) -> void:
	player_name = Utils.safe_string(data.get("player_name", "无名侠客"))
	level = Utils.safe_int(data.get("level", 1))
	exp = Utils.safe_int(data.get("exp", 0))
	exp_to_next = Utils.safe_int(data.get("exp_to_next", 100))
	gold = Utils.safe_int(data.get("gold", 0))
	max_hp = Utils.safe_int(data.get("max_hp", 100))
	current_hp = Utils.safe_int(data.get("current_hp", 100))
	max_mp = Utils.safe_int(data.get("max_mp", 50))
	current_mp = Utils.safe_int(data.get("current_mp", 50))
	strength = Utils.safe_int(data.get("strength", 10))
	dexterity = Utils.safe_int(data.get("dexterity", 10))
	intelligence = Utils.safe_int(data.get("intelligence", 10))
	constitution = Utils.safe_int(data.get("constitution", 10))
	
	var pos_data: Dictionary = data.get("position", {})
	position = Vector2(
		Utils.safe_float(pos_data.get("x", 0)),
		Utils.safe_float(pos_data.get("y", 0))
	)
	
	current_zone = Utils.safe_string(data.get("current_zone", "pingan_town"))
	faction = Utils.safe_int(data.get("faction", Constants.Faction.NONE))
	faction_rank = Utils.safe_int(data.get("faction_rank", 0))
	equipment = data.get("equipment", {}).duplicate()
	inventory = data.get("inventory", []).duplicate()
	skills = data.get("skills", []).duplicate()
	faction_reputation = data.get("faction_reputation", {}).duplicate()
	story_flags = data.get("story_flags", {}).duplicate()
	completed_quests = data.get("completed_quests", []).duplicate()
	active_quests = data.get("active_quests", []).duplicate()
	play_time_seconds = Utils.safe_float(data.get("play_time_seconds", 0))
	enemies_killed = Utils.safe_int(data.get("enemies_killed", 0))
	quests_completed = Utils.safe_int(data.get("quests_completed", 0))
	items_collected = Utils.safe_int(data.get("items_collected", 0))
	distance_traveled = Utils.safe_float(data.get("distance_traveled", 0))
