extends Node
## 派系系统 - 门派关系、声望、敌对

signal reputation_changed(faction_id: int, old_rep: int, new_rep: int)
signal faction_joined(faction_id: int)
signal faction_left(faction_id: int)
signal rank_changed(faction_id: int, old_rank: int, new_rank: int)

var _faction_reputation: Dictionary = {}
var _player_faction: int = Constants.Faction.NONE
var _faction_ranks: Dictionary = {}

func _ready() -> void:
	_init_faction_ranks()

func _init_faction_ranks() -> void:
	for faction_id in range(Constants.Faction.size()):
		_faction_reputation[faction_id] = 0
		_faction_ranks[faction_id] = 0

func join_faction(faction_id: int) -> bool:
	if _player_faction != Constants.Faction.NONE:
		return false
	
	_player_faction = faction_id
	_faction_reputation[faction_id] = 100
	_faction_ranks[faction_id] = 1
	faction_joined.emit(faction_id)
	return true

func leave_faction() -> void:
	if _player_faction == Constants.Faction.NONE:
		return
	
	var old_faction: int = _player_faction
	_player_faction = Constants.Faction.NONE
	faction_left.emit(old_faction)

func get_player_faction() -> int:
	return _player_faction

func add_reputation(faction_id: int, amount: int) -> void:
	if not _faction_reputation.has(faction_id):
		return
	
	var old_rep: int = _faction_reputation[faction_id]
	var new_rep: int = clamp(old_rep + amount, -1000, 1000)
	
	_faction_reputation[faction_id] = new_rep
	
	var old_rank: int = _get_rank_from_reputation(old_rep)
	var new_rank: int = _get_rank_from_reputation(new_rep)
	_faction_ranks[faction_id] = new_rank
	
	reputation_changed.emit(faction_id, old_rep, new_rep)
	
	if old_rank != new_rank:
		rank_changed.emit(faction_id, old_rank, new_rank)

func get_reputation(faction_id: int) -> int:
	return _faction_reputation.get(faction_id, 0)

func get_rank(faction_id: int) -> int:
	return _faction_ranks.get(faction_id, 0)

func _get_rank_from_reputation(reputation: int) -> int:
	if reputation < 0: return 0
	if reputation < 100: return 1
	if reputation < 300: return 2
	if reputation < 600: return 3
	if reputation < 1000: return 4
	return 5

func get_rank_name(faction_id: int) -> String:
	var rank: int = get_rank(faction_id)
	match rank:
		0: return "敌对"
		1: return "外门弟子"
		2: return "内门弟子"
		3: return "核心弟子"
		4: return "长老"
		5: return "掌门"
	return "未知"

func is_hostile_to(faction_id: int) -> bool:
	return get_reputation(faction_id) < -200

func is_allied_with(faction_id: int) -> bool:
	return get_reputation(faction_id) > 300

func is_neutral_with(faction_id: int) -> bool:
	var rep: int = get_reputation(faction_id)
	return rep >= -100 and rep <= 100

func get_relationship_color(faction_id: int) -> Color:
	var rep: int = get_reputation(faction_id)
	if rep < -200: return Color.RED
	if rep < -50: return Color.ORANGE
	if rep < 50: return Color.WHITE
	if rep < 200: return Color.GREEN
	return Color.GOLD

func get_all_reputations() -> Dictionary:
	return _faction_reputation.duplicate()

func get_faction_color(faction_id: int) -> Color:
	match faction_id:
		Constants.Faction.BAGUA: return Color(0.8, 0.6, 0.4)
		Constants.Faction.FLOWER: return Color(1.0, 0.5, 0.7)
		Constants.Faction.HONGLIAN: return Color(0.9, 0.2, 0.2)
		Constants.Faction.NAJA: return Color(0.3, 0.8, 0.3)
		Constants.Faction.TAIJI: return Color(1.0, 1.0, 1.0)
		Constants.Faction.XUESHAN: return Color(0.8, 0.9, 1.0)
	return Color.WHITE

func get_faction_name(faction_id: int) -> String:
	match faction_id:
		Constants.Faction.NONE: return "无门无派"
		Constants.Faction.BAGUA: return "八卦门"
		Constants.Faction.FLOWER: return "花间派"
		Constants.Faction.HONGLIAN: return "红莲教"
		Constants.Faction.NAJA: return "那迦派"
		Constants.Faction.TAIJI: return "太极门"
		Constants.Faction.XUESHAN: return "雪山派"
	return "未知"

func to_dictionary() -> Dictionary:
	return {
		"player_faction": _player_faction,
		"reputations": _faction_reputation.duplicate(),
		"ranks": _faction_ranks.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	_player_faction = data.get("player_faction", Constants.Faction.NONE)
	_faction_reputation = data.get("reputations", {}).duplicate()
	_faction_ranks = data.get("ranks", {}).duplicate()
