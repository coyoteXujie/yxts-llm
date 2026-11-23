extends Node
class_name PetSystem

## 灵宠系统 — 管理灵宠的获取、养成、战斗支援

signal pet_added(pet_id: String)
signal pet_removed(pet_id: String)
signal pet_leveled_up(pet_id: String, level: int)
signal pet_active_changed(pet_id: String)
signal pet_roster_changed()

const MAX_PETS := 12
const MAX_ACTIVE_SLOTS := 3
const EXP_PER_LEVEL := 100
const FEED_AMOUNT := 5

# 所有灵宠定义
var _all_pets: Dictionary = {}
# 拥有的灵宠字典 key=pet_id, value={"id","level","exp","stats","skills","battle_cooldown"}
var owned_pets: Dictionary = {}
# 当前出战的灵宠ID列表
var active_pet_ids: Array = []
# 战斗回合计数器
var _battle_turn_counter: int = 0
var _last_skill_used: String = ""

func _ready() -> void:
	_load_pets()

func _load_pets() -> void:
	var file := FileAccess.open("res://data/pets.json", FileAccess.READ)
	if file == null:
		push_error("PetSystem: cannot open pets.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("PetSystem: pets.json is not an array")
		return
	for pet in parsed:
		if typeof(pet) == TYPE_DICTIONARY:
			var pid := str(pet.get("id", ""))
			if not pid.is_empty():
				_all_pets[pid] = pet

func get_all_pet_defs() -> Dictionary:
	return _all_pets.duplicate(true)

func get_pet_def(pet_id: String) -> Dictionary:
	return _all_pets.get(pet_id, {}).duplicate(true)

func get_owned_pets() -> Dictionary:
	return owned_pets.duplicate(true)

func has_pets() -> bool:
	return not owned_pets.is_empty()

func get_max_level() -> int:
	var max_lv := 0
	for pid in owned_pets.keys():
		var data: Dictionary = owned_pets[pid]
		max_lv = maxi(max_lv, int(data.get("level", 1)))
	return max_lv

func get_active_pets() -> Array:
	var result: Array = []
	for pid in active_pet_ids:
		if owned_pets.has(pid):
			var data: Dictionary = owned_pets[pid].duplicate(true)
			data["def"] = get_pet_def(pid)
			result.append(data)
	return result

func add_pet(pet_id: String) -> bool:
	if not _all_pets.has(pet_id):
		EventBus.emit_toast("没有这种灵宠")
		return false
	if owned_pets.size() >= MAX_PETS:
		EventBus.emit_toast("灵宠已满，无法继续收服")
		return false
	if owned_pets.has(pet_id):
		EventBus.emit_toast("你已经拥有这只灵宠了")
		return false
	var def_data: Dictionary = _all_pets[pet_id]
	var stats: Dictionary = def_data.get("base_stats", {}).duplicate(true)
	owned_pets[pet_id] = {
		"id": pet_id,
		"level": 1,
		"exp": 0,
		"stats": stats,
		"skills": def_data.get("skills", []).duplicate(true),
		"battle_cooldown": 0
	}
	EventBus.emit_toast("你获得了灵宠：%s！" % str(def_data.get("name", pet_id)))
	pet_added.emit(pet_id)
	pet_roster_changed.emit()
	
	# 自动编队
	if active_pet_ids.size() < MAX_ACTIVE_SLOTS:
		active_pet_ids.append(pet_id)
		pet_active_changed.emit(pet_id)
	
	_progress_achievement("get_pet")
	return true

func remove_pet(pet_id: String) -> void:
	if not owned_pets.has(pet_id):
		return
	active_pet_ids.erase(pet_id)
	owned_pets.erase(pet_id)
	pet_removed.emit(pet_id)
	pet_roster_changed.emit()

func set_active(pet_id: String, active: bool) -> void:
	if not owned_pets.has(pet_id):
		return
	if active:
		if not active_pet_ids.has(pet_id) and active_pet_ids.size() < MAX_ACTIVE_SLOTS:
			active_pet_ids.append(pet_id)
			pet_active_changed.emit(pet_id)
	else:
		active_pet_ids.erase(pet_id)
		pet_active_changed.emit(pet_id)

func is_active(pet_id: String) -> bool:
	return active_pet_ids.has(pet_id)

func feed_pet(pet_id: String) -> bool:
	if not owned_pets.has(pet_id):
		return false
	if not GameState.has_item("item_yao", 1):
		EventBus.emit_toast("没有丹药可以喂养")
		return false
	GameState.remove_item("item_yao", 1)
	var data: Dictionary = owned_pets[pet_id]
	data["exp"] = int(data.get("exp", 0)) + FEED_AMOUNT
	var level := int(data.get("level", 1))
	var exp_needed := EXP_PER_LEVEL * level
	while int(data.get("exp", 0)) >= exp_needed:
		data["exp"] = int(data["exp"]) - exp_needed
		level += 1
		data["level"] = level
		exp_needed = EXP_PER_LEVEL * level
		# 升级属性提升
		var stats: Dictionary = data.get("stats", {})
		stats["attack"] = int(stats.get("attack", 5)) + 1
		stats["defense"] = int(stats.get("defense", 5)) + 1
		stats["speed"] = int(stats.get("speed", 5)) + 1
		stats["spirit"] = int(stats.get("spirit", 5)) + 1
		data["stats"] = stats
		pet_leveled_up.emit(pet_id, level)
		EventBus.emit_toast("灵宠%s升到 %d 级！" % [get_pet_name(pet_id), level])
		_progress_achievement("pet_level", level)
	owned_pets[pet_id] = data
	pet_roster_changed.emit()
	return true

func get_pet_name(pet_id: String) -> String:
	var def_data: Dictionary = _all_pets.get(pet_id, {})
	return str(def_data.get("name", pet_id))

## 战斗支援 — 每2回合发动一次技能
func get_battle_bonus(stats: Dictionary = {}) -> Dictionary:
	## 返回战斗中灵宠的加成
	var attack_bonus := 0
	var defense_bonus := 0
	var active := get_active_pets()
	for pet_data in active:
		if typeof(pet_data) != TYPE_DICTIONARY:
			continue
		var pstats: Dictionary = pet_data.get("stats", {})
		var level := int(pet_data.get("level", 1))
		attack_bonus += int(pstats.get("attack", 0)) + int(level * 0.5)
		defense_bonus += int(pstats.get("defense", 0)) + int(level * 0.5)
	attack_bonus = maxi(0, attack_bonus)
	defense_bonus = maxi(0, defense_bonus)
	return {"attack_bonus": attack_bonus, "defense_bonus": defense_bonus}

func get_battle_skill_action(turn_count: int) -> Dictionary:
	## 灵宠技能支援（每2回合触发一次）
	if turn_count % 2 != 0:
		return {"active": false}
	var active := get_active_pets()
	if active.is_empty():
		return {"active": false}
	
	# 选择第一个出场灵宠的技能
	var pet_data: Dictionary = active[0]
	if typeof(pet_data) != TYPE_DICTIONARY:
		return {"active": false}
	var skills: Array = pet_data.get("skills", [])
	if skills.is_empty():
		return {"active": false}
	
	# 选择攻击或debuff类技能
	var chosen: Dictionary = {}
	for s in skills:
		if typeof(s) == TYPE_DICTIONARY:
			var stype := str(s.get("type", ""))
			if stype == "attack" or stype == "debuff":
				chosen = s
				break
	if chosen.is_empty():
		chosen = skills[0]
	
	var power := int(chosen.get("power", 8))
	var level := int(pet_data.get("level", 1))
	var actual_power := power + int(level * 0.8)
	var stype := str(chosen.get("type", "attack"))
	var sname := str(chosen.get("name", "灵宠技能"))
	var pname := get_pet_name(str(pet_data.get("id", "")))
	
	return {
		"active": true,
		"pet_name": pname,
		"skill_name": sname,
		"skill_type": stype,
		"power": actual_power,
		"pet_id": str(pet_data.get("id", ""))
	}

func save_state() -> Dictionary:
	return {
		"owned_pets": owned_pets.duplicate(true),
		"active_pet_ids": active_pet_ids.duplicate()
	}

func load_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	owned_pets = data.get("owned_pets", {}).duplicate(true)
	active_pet_ids = data.get("active_pet_ids", []).duplicate()

func _progress_achievement(target: String, value: int = 1) -> void:
	var achievement_system := get_node_or_null("/root/AchievementSystem")
	if achievement_system != null and achievement_system.has_method("notify_event"):
		achievement_system.notify_event(target, value)
