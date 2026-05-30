class_name QuestData extends Resource
## 数据层 - 任务数据，纯数据定义

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var level_requirement: int = 1

@export var objectives: Array[Dictionary] = []
@export var rewards: Dictionary = {}

@export var npc_giver: String = ""
@export var prerequisites: Array[String] = []
@export var quest_chain: String = ""
@export var chain_order: int = 0

@export var time_limit: float = -1.0
@export var is_repeatable: bool = false
@export var repeat_cooldown: float = 0.0

@export var story_flags_required: Dictionary = {}
@export var story_flags_set_on_accept: Dictionary = {}
@export var story_flags_set_on_complete: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {
		"quest_id": quest_id,
		"title": title,
		"description": description,
		"level_requirement": level_requirement,
		"objectives": objectives.duplicate(),
		"rewards": rewards.duplicate(),
		"npc_giver": npc_giver,
		"prerequisites": prerequisites.duplicate(),
		"quest_chain": quest_chain,
		"chain_order": chain_order,
		"time_limit": time_limit,
		"is_repeatable": is_repeatable,
		"repeat_cooldown": repeat_cooldown,
		"story_flags_required": story_flags_required.duplicate(),
		"story_flags_set_on_accept": story_flags_set_on_accept.duplicate(),
		"story_flags_set_on_complete": story_flags_set_on_complete.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	quest_id = Utils.safe_string(data.get("quest_id", ""))
	title = Utils.safe_string(data.get("title", ""))
	description = Utils.safe_string(data.get("description", ""))
	level_requirement = Utils.safe_int(data.get("level_requirement", 1))
	objectives = data.get("objectives", []).duplicate()
	rewards = data.get("rewards", {}).duplicate()
	npc_giver = Utils.safe_string(data.get("npc_giver", ""))
	prerequisites = data.get("prerequisites", []).duplicate()
	quest_chain = Utils.safe_string(data.get("quest_chain", ""))
	chain_order = Utils.safe_int(data.get("chain_order", 0))
	time_limit = Utils.safe_float(data.get("time_limit", -1.0))
	is_repeatable = data.get("is_repeatable", false)
	repeat_cooldown = Utils.safe_float(data.get("repeat_cooldown", 0.0))
	story_flags_required = data.get("story_flags_required", {}).duplicate()
	story_flags_set_on_accept = data.get("story_flags_set_on_accept", {}).duplicate()
	story_flags_set_on_complete = data.get("story_flags_set_on_complete", {}).duplicate()
