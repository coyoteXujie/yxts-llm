extends Node

var current_scene_name: String = "pingan_town"
var spawn_position: Vector2 = Vector2.ZERO
var spawn_position_set: bool = false
var game_flags: Dictionary = {}
var player_stats: Dictionary = {}
var inventory: Dictionary = {}
var current_quest_id: String = ""
var quest_active: bool = false
var vertical_quest_stage: int = 0

func get_spawn_position() -> Vector2:
	if spawn_position_set:
		spawn_position_set = false
		return spawn_position
	return Vector2.ZERO

func set_spawn_position(pos: Vector2) -> void:
	spawn_position = pos
	spawn_position_set = true
