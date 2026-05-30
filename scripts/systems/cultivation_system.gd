extends Node
## 修炼系统 - 内功、外功、轻功、绝招、经脉

signal skill_learned(skill_id: String)
signal skill_leveled_up(skill_id: String, level: int)
signal skill_mastered(skill_id: String)
signal meridian_opened(meridian_id: String)
signal cultivation_breakthrough(realm: int)

enum SkillType {
	INTERNAL,
	EXTERNAL,
	LIGHTNESS,
	ULTIMATE
}

enum Meridian {
	REN,
	DU,
	CHONG,
	DAI,
	YANGQIAO,
	YINQIAO,
	YANGWEI,
	YINWEI
}

enum Realm {
	MORTAL,
	QI_GATHERER,
	QI_CONDENSER,
	QI_MASTER,
	QI_GRANDMASTER,
	INNER_ORIGIN,
	TRANSFORMATION,
	ASCENSION,
	IMMORTAL
}

var _player_skills: Dictionary = {}
var _player_internal_art: Dictionary = {}
var _meridians: Dictionary = {}
var _current_realm: int = Realm.MORTAL
var _cultivation_xp: float = 0.0
var _xp_to_next_realm: float = 1000.0

func _ready() -> void:
	_init_meridians()

func _init_meridians() -> void:
	for meridian_id in range(Meridian.size()):
		_meridians[meridian_id] = {
			"is_open": false,
			"level": 0,
			"progress": 0.0
		}

func learn_skill(skill_data: Dictionary) -> bool:
	var skill_id: String = skill_data.get("skill_id", "")
	if _player_skills.has(skill_id):
		return false
	
	_player_skills[skill_id] = {
		"skill_id": skill_id,
		"name": skill_data.get("name", ""),
		"type": skill_data.get("type", SkillType.EXTERNAL),
		"level": 1,
		"proficiency": 0.0,
		"mastered": false
	}
	
	skill_learned.emit(skill_id)
	return true

func level_up_skill(skill_id: String, amount: int = 1) -> bool:
	if not _player_skills.has(skill_id):
		return false
	
	var skill: Dictionary = _player_skills[skill_id]
	var current_level: int = skill.get("level", 1)
	var max_level: int = skill.get("max_level", 10)
	
	if current_level >= max_level:
		return false
	
	skill["level"] = current_level + amount
	skill_leveled_up.emit(skill_id, skill["level"])
	
	if skill["level"] >= max_level:
		skill["mastered"] = true
		skill_mastered.emit(skill_id)
	
	return true

func add_proficiency(skill_id: String, amount: float) -> void:
	if not _player_skills.has(skill_id):
		return
	
	var skill: Dictionary = _player_skills[skill_id]
	var prof: float = skill.get("proficiency", 0.0) + amount
	
	while prof >= 100.0:
		prof -= 100.0
		level_up_skill(skill_id)
	
	skill["proficiency"] = prof

func set_internal_art(art_data: Dictionary) -> bool:
	var art_id: String = art_data.get("id", "")
	if art_id.is_empty():
		return false
	
	_player_internal_art = {
		"id": art_id,
		"name": art_data.get("name", ""),
		"level": 1,
		"max_mp_bonus": art_data.get("mp_bonus", 0),
		"hp_bonus": art_data.get("hp_bonus", 0),
		"attack_bonus": art_data.get("attack_bonus", 0),
		"defense_bonus": art_data.get("defense_bonus", 0)
	}
	
	return true

func cultivate(amount: float) -> Dictionary:
	var result: Dictionary = {}
	_cultivation_xp += amount
	
	if _cultivation_xp >= _xp_to_next_realm:
		var overflow: float = _cultivation_xp - _xp_to_next_realm
		_breakthrough()
		_cultivation_xp = overflow
		result["breakthrough"] = true
	
	return result

func _breakthrough() -> void:
	if _current_realm >= Realm.IMMORTAL:
		return
	
	_current_realm += 1
	_xp_to_next_realm *= 1.5
	cultivation_breakthrough.emit(_current_realm)

func open_meridian(meridian_id: int) -> bool:
	if meridian_id < 0 or meridian_id >= Meridian.size():
		return false
	
	var meridian: Dictionary = _meridians[meridian_id]
	if meridian.get("is_open", false):
		return false
	
	meridian["is_open"] = true
	meridian["level"] = 1
	meridian_opened.emit(str(meridian_id))
	
	return true

func get_meridian_bonus() -> Dictionary:
	var total_bonus: Dictionary = {}
	
	for meridian_id in _meridians:
		var meridian: Dictionary = _meridians[meridian_id]
		if meridian.get("is_open", false):
			var level: int = meridian.get("level", 0)
			var bonus: Dictionary = _get_meridian_base_bonus(meridian_id)
			for key: String in bonus:
				if not total_bonus.has(key):
					total_bonus[key] = 0
				total_bonus[key] += bonus.get(key, 0) * level
	
	return total_bonus

func _get_meridian_base_bonus(meridian_id: int) -> Dictionary:
	match meridian_id:
		Meridian.REN:
			return {"max_mp": 10, "mp_regen": 1}
		Meridian.DU:
			return {"attack": 2, "defense": 1}
		Meridian.CHONG:
			return {"max_hp": 20, "hp_regen": 1}
		Meridian.DAI:
			return {"speed": 1, "dodge": 2}
		Meridian.YANGQIAO:
			return {"critical": 2, "critical_damage": 5}
		Meridian.YINQIAO:
			return {"counter": 3, "parry": 2}
		Meridian.YANGWEI:
			return {"internal_damage": 3, "skill_damage": 2}
		Meridian.YINWEI:
			return {"resistance": 2, "status_resist": 3}
	return {}

func get_realm_name() -> String:
	match _current_realm:
		Realm.MORTAL: return "凡人"
		Realm.QI_GATHERER: return "聚气境"
		Realm.QI_CONDENSER: return "凝气境"
		Realm.QI_MASTER: return "化气境"
		Realm.QI_GRANDMASTER: return "大乘境"
		Realm.INNER_ORIGIN: return "元婴境"
		Realm.TRANSFORMATION: return "蜕变境"
		Realm.ASCENSION: return "飞升境"
		Realm.IMMORTAL: return "仙人"
	return "未知"

func get_current_realm() -> int:
	return _current_realm

func get_cultivation_progress() -> float:
	return _cultivation_xp / _xp_to_next_realm

func get_all_skills() -> Dictionary:
	return _player_skills.duplicate()

func has_skill(skill_id: String) -> bool:
	return _player_skills.has(skill_id)

func get_internal_art() -> Dictionary:
	return _player_internal_art.duplicate()

func to_dictionary() -> Dictionary:
	return {
		"skills": _player_skills.duplicate(),
		"internal_art": _player_internal_art.duplicate(),
		"meridians": _meridians.duplicate(true),
		"realm": _current_realm,
		"cultivation_xp": _cultivation_xp,
		"xp_to_next_realm": _xp_to_next_realm
	}

func from_dictionary(data: Dictionary) -> void:
	_player_skills = data.get("skills", {}).duplicate()
	_player_internal_art = data.get("internal_art", {}).duplicate()
	_meridians = data.get("meridians", {}).duplicate(true)
	_current_realm = data.get("realm", Realm.MORTAL)
	_cultivation_xp = data.get("cultivation_xp", 0.0)
	_xp_to_next_realm = data.get("xp_to_next_realm", 1000.0)
