extends Node
class_name SectSystem

## 门派系统 — 管理门派的加入、贡献、任务等

signal sect_changed(sect_id: String, sect_name: String)
signal sect_contribution_changed(contribution: int)
signal sect_missions_changed(missions: Array)
signal sect_skill_unlocked(skill_id: String)

var current_sect_id: String = ""
var current_sect_data: Dictionary = {}
var contribution: int = 0
var level: int = 1
var active_missions: Array = []
var completed_missions: Array = []
var unlocked_skills: Array = []

var _all_sects: Dictionary = {}
var _mission_timer: float = 0.0

func _ready() -> void:
	_load_sects()

func _load_sects() -> void:
	var file := FileAccess.open("res://data/sects.json", FileAccess.READ)
	if file == null:
		push_error("SectSystem: cannot open sects.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("SectSystem: sects.json is not an array")
		return
	for sect in parsed:
		if typeof(sect) == TYPE_DICTIONARY:
			var sect_id := str(sect.get("id", ""))
			if not sect_id.is_empty():
				_all_sects[sect_id] = sect

func get_all_sects() -> Dictionary:
	return _all_sects.duplicate(true)

func get_sect(sect_id: String) -> Dictionary:
	return _all_sects.get(sect_id, {}).duplicate(true)

func get_sect_name(sect_id: String) -> String:
	var sect: Dictionary = _all_sects.get(sect_id, {})
	return str(sect.get("name", sect_id))

func has_sect() -> bool:
	return not current_sect_id.is_empty()

func join_sect(sect_id: String) -> bool:
	if has_sect():
		EventBus.emit_toast("你已经加入了门派，不能改投他派")
		return false
	if not _all_sects.has(sect_id):
		EventBus.emit_toast("该门派不存在")
		return false
	var sect: Dictionary = _all_sects[sect_id]
	if not _check_join_condition(sect):
		return false
	current_sect_id = sect_id
	current_sect_data = sect.duplicate(true)
	contribution = 0
	level = 1
	active_missions = []
	completed_missions = []
	unlocked_skills = []
	EventBus.emit_toast("你加入了%s！" % str(sect.get("name", sect_id)))
	sect_changed.emit(current_sect_id, str(sect.get("name", sect_id)))
	sect_contribution_changed.emit(contribution)
	_progress_achievement("join_sect")
	return true

func leave_sect() -> void:
	if not has_sect():
		return
	var name := str(current_sect_data.get("name", ""))
	current_sect_id = ""
	current_sect_data = {}
	contribution = 0
	level = 1
	active_missions = []
	completed_missions = []
	unlocked_skills = []
	EventBus.emit_toast("你离开了%s" % name)
	sect_changed.emit("", "")

func add_contribution(amount: int) -> void:
	if not has_sect():
		return
	if amount <= 0:
		return
	contribution += amount
	var old_level := level
	level = maxi(1, 1 + int(contribution / 200))
	sect_contribution_changed.emit(contribution)
	if level > old_level:
		EventBus.emit_toast("你在%s的等级提升到 %d！" % [str(current_sect_data.get("name", "")), level])

func _check_join_condition(sect: Dictionary) -> bool:
	var condition: Dictionary = sect.get("join_condition", {})
	var cult := int(condition.get("cultivation", 0))
	var rep := int(condition.get("reputation", 0))
	var daode := int(condition.get("daode", 0))
	var quest_id := str(condition.get("quest", ""))
	var player := GameState.player
	var player_level := int(player.get("level", 1))
	if cult > 0 and player_level < cult:
		EventBus.emit_toast("修为不足，需要达到%d级才能加入" % cult)
		return false
	if rep > 0 and int(GameState.trade_reputation) < rep:
		EventBus.emit_toast("声望不足，需要%d声望才能加入" % rep)
		return false
	if daode != 0:
		var player_daode := int(player.get("daode", 0))
		if daode > 0 and player_daode < daode:
			EventBus.emit_toast("道德不足，需要%d道德才能加入" % daode)
			return false
		if daode < 0 and player_daode > daode:
			EventBus.emit_toast("道德过高，该门派不收正派人士")
			return false
	if not quest_id.is_empty() and not GameState.completed_quests.has(quest_id):
		var qdata := GameData.get_quest(quest_id)
		EventBus.emit_toast("需要先完成任务「%s」才能加入" % str(qdata.get("title", quest_id)))
		return false
	return true

func get_missions() -> Array:
	if not has_sect():
		return []
	var mission_defs: Array = current_sect_data.get("missions", [])
	var available: Array = []
	for mdef in mission_defs:
		var mid := str(mdef.get("id", ""))
		if completed_missions.has(mid):
			continue
		var is_active := false
		for am in active_missions:
			if str(am.get("id", "")) == mid:
				is_active = true
				break
		if not is_active:
			available.append(mdef.duplicate(true))
	return available

func accept_mission(mission_id: String) -> bool:
	if not has_sect():
		return false
	var missions: Array = current_sect_data.get("missions", [])
	for m in missions:
		if str(m.get("id", "")) == mission_id:
			if completed_missions.has(mission_id):
				EventBus.emit_toast("该任务已完成")
				return false
			for am in active_missions:
				if str(am.get("id", "")) == mission_id:
					EventBus.emit_toast("该任务已接取")
					return false
			active_missions.append(m.duplicate(true))
			sect_missions_changed.emit(active_missions)
			EventBus.emit_toast("接受了门派任务：%s" % str(m.get("title", "")))
			return true
	EventBus.emit_toast("未找到该任务")
	return false

func progress_mission(type: String, target: String, count: int = 1) -> void:
	if not has_sect() or active_missions.is_empty():
		return
	var completed: Array = []
	for am in active_missions:
		if str(am.get("type", "")) != type:
			continue
		var am_target := str(am.get("target", ""))
		if am_target != "any" and am_target != target and type == "kill":
			continue
		if am_target != "any" and am_target != target and type == "collect":
			continue
		am["progress"] = int(am.get("progress", 0)) + count
		var need := int(am.get("count", 1))
		if int(am.get("progress", 0)) >= need:
			completed.append(am)
	for am in completed:
		var mid := str(am.get("id", ""))
		active_missions.erase(am)
		completed_missions.append(mid)
		var reward_contrib := int(am.get("reward_contribution", 0))
		var reward_exp := int(am.get("reward_exp", 0))
		var reward_money := int(am.get("reward_money", 0))
		if reward_contrib > 0:
			add_contribution(reward_contrib)
		if reward_exp > 0 or reward_money > 0:
			GameState.reward_player(reward_exp, reward_money)
		EventBus.emit_toast("完成门派任务：%s 获得贡献+%d" % [str(am.get("title", "")), reward_contrib])
	if not completed.is_empty():
		sect_missions_changed.emit(active_missions)

func get_available_skills() -> Array:
	if not has_sect():
		return []
	var result: Array = []
	var contrib_skills: Dictionary = current_sect_data.get("contribution_skills", {})
	for skill_id in contrib_skills.keys():
		if unlocked_skills.has(skill_id):
			continue
		var needed := int(contrib_skills[skill_id])
		result.append({"skill_id": skill_id, "needed_contribution": needed})
	return result

func unlock_skill(skill_id: String) -> bool:
	if not has_sect():
		return false
	if unlocked_skills.has(skill_id):
		EventBus.emit_toast("该功法已解锁")
		return false
	var contrib_skills: Dictionary = current_sect_data.get("contribution_skills", {})
	if not contrib_skills.has(skill_id):
		EventBus.emit_toast("该门派没有此功法")
		return false
	var needed := int(contrib_skills[skill_id])
	if contribution < needed:
		EventBus.emit_toast("贡献不足，需要%d贡献" % needed)
		return false
	unlocked_skills.append(skill_id)
	GameState.learned_skills[skill_id] = 1
	var skill_name := ""
	var snames: Dictionary = current_sect_data.get("skill_names", {})
	if snames.has(skill_id):
		skill_name = str(snames[skill_id])
	else:
		skill_name = GameData.get_skill_name(skill_id)
	EventBus.emit_toast("你学会了%s！" % skill_name)
	sect_skill_unlocked.emit(skill_id)
	return true

func get_contribution_items() -> Dictionary:
	if not has_sect():
		return {}
	return current_sect_data.get("contribution_items", {})

func save_state() -> Dictionary:
	return {
		"sect_id": current_sect_id,
		"contribution": contribution,
		"level": level,
		"active_missions": active_missions.duplicate(true),
		"completed_missions": completed_missions.duplicate(),
		"unlocked_skills": unlocked_skills.duplicate()
	}

func load_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_sect_id = str(data.get("sect_id", ""))
	contribution = int(data.get("contribution", 0))
	level = int(data.get("level", 1))
	active_missions = data.get("active_missions", []).duplicate(true)
	completed_missions = data.get("completed_missions", []).duplicate()
	unlocked_skills = data.get("unlocked_skills", []).duplicate()
	if not current_sect_id.is_empty():
		current_sect_data = _all_sects.get(current_sect_id, {}).duplicate(true)

func _progress_achievement(target: String) -> void:
	var achievement_system := get_node_or_null("/root/AchievementSystem")
	if achievement_system != null and achievement_system.has_method("notify_event"):
		achievement_system.notify_event(target, 1)
