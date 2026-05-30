class_name SkillData extends Resource
## 数据层 - 技能数据，纯数据定义

@export var skill_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon_path: String = ""

@export var skill_type: int = Constants.SkillType.ATTACK
@export var target_type: int = Constants.SkillTarget.SINGLE

@export var base_damage: int = 10
@export var base_healing: int = 0
@export var mana_cost: int = 5
@export var cooldown: int = 2
@export var skill_range: float = 100.0

@export var damage_type: int = Constants.DamageType.PHYSICAL
@export var stat_multiplier: float = 1.0
@export var crit_multiplier: float = 1.5

@export var effects: Array[Dictionary] = []

@export var level_requirement: int = 1
@export var faction_requirement: int = Constants.Faction.NONE
@export var prerequisites: Array[String] = []

func to_dictionary() -> Dictionary:
	return {
		"skill_id": skill_id,
		"name": name,
		"description": description,
		"skill_type": skill_type,
		"target_type": target_type,
		"base_damage": base_damage,
		"base_healing": base_healing,
		"mana_cost": mana_cost,
		"cooldown": cooldown,
		"skill_range": skill_range,
		"damage_type": damage_type,
		"stat_multiplier": stat_multiplier,
		"crit_multiplier": crit_multiplier,
		"effects": effects.duplicate(),
		"level_requirement": level_requirement,
		"faction_requirement": faction_requirement,
		"prerequisites": prerequisites.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	skill_id = Utils.safe_string(data.get("skill_id", ""))
	name = Utils.safe_string(data.get("name", ""))
	description = Utils.safe_string(data.get("description", ""))
	skill_type = Utils.safe_int(data.get("skill_type", Constants.SkillType.ATTACK))
	target_type = Utils.safe_int(data.get("target_type", Constants.SkillTarget.SINGLE))
	base_damage = Utils.safe_int(data.get("base_damage", 10))
	base_healing = Utils.safe_int(data.get("base_healing", 0))
	mana_cost = Utils.safe_int(data.get("mana_cost", 5))
	cooldown = Utils.safe_int(data.get("cooldown", 2))
	skill_range = Utils.safe_float(data.get("skill_range", 100.0))
	damage_type = Utils.safe_int(data.get("damage_type", Constants.DamageType.PHYSICAL))
	stat_multiplier = Utils.safe_float(data.get("stat_multiplier", 1.0))
	crit_multiplier = Utils.safe_float(data.get("crit_multiplier", 1.5))
	effects = data.get("effects", []).duplicate()
	level_requirement = Utils.safe_int(data.get("level_requirement", 1))
	faction_requirement = Utils.safe_int(data.get("faction_requirement", Constants.Faction.NONE))
	prerequisites = data.get("prerequisites", []).duplicate()
