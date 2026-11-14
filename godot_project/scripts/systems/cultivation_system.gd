extends RefCounted
class_name CultivationSystem

const INTERNAL_ARTS := {
	"ne_basic": {
		"name": "基础吐纳",
		"type": "internal",
		"desc": "入门内功，调和气血，夯实根基。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 2,
			"max_mp": 1,
			"attack": 0,
			"defense": 0,
			"speed": 0,
			"crit": 0.0,
			"dodge": 0.0,
			"mp_regen": 0
		}
	},
	"ne_hunyuan": {
		"name": "混元一气功",
		"type": "internal",
		"desc": "八卦门镇派内功，气走混元，攻防兼备。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 1,
			"max_mp": 2,
			"attack": 1,
			"defense": 0,
			"speed": 0,
			"crit": 0.001,
			"dodge": 0.0,
			"mp_regen": 1
		}
	},
	"ne_taiji": {
		"name": "太极神功",
		"type": "internal",
		"desc": "太极门无上心法，以柔克刚，生生不息。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 3,
			"max_mp": 1,
			"attack": 0,
			"defense": 1,
			"speed": 0,
			"crit": 0.0,
			"dodge": 0.0,
			"mp_regen": 1
		}
	},
	"ne_beiming": {
		"name": "北冥真气",
		"type": "internal",
		"desc": "逍遥派奇功，海纳百川，内力深不可测。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 0,
			"max_mp": 4,
			"attack": 0,
			"defense": 0,
			"speed": 0,
			"crit": 0.0,
			"dodge": 0.0,
			"mp_regen": 2
		}
	},
	"ne_xiaowuxiang": {
		"name": "小无相功",
		"type": "internal",
		"desc": "无形无相，兼容并蓄，可催动诸般武学。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 1,
			"max_mp": 2,
			"attack": 1,
			"defense": 0,
			"speed": 0,
			"crit": 0.001,
			"dodge": 0.001,
			"mp_regen": 1
		}
	},
	"ne_xueshang": {
		"name": "雪山内功",
		"type": "internal",
		"desc": "雪山派心法，寒气内敛，冰心护体。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 2,
			"max_mp": 1,
			"attack": 0,
			"defense": 1,
			"speed": 0,
			"crit": 0.0,
			"dodge": 0.0,
			"mp_regen": 0
		}
	},
	"ne_renshu": {
		"name": "任督心法",
		"type": "internal",
		"desc": "打通任督二脉的心法，练至高深可激发潜能。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 1,
			"max_mp": 1,
			"attack": 1,
			"defense": 0,
			"speed": 0,
			"crit": 0.002,
			"dodge": 0.0,
			"mp_regen": 1
		}
	},
	"ne_jiaoyi": {
		"name": "蕉叶心法",
		"type": "internal",
		"desc": "逍遥派轻灵心法，气息流转如风中蕉叶。",
		"max_level": 100,
		"bonuses": {
			"max_hp": 0,
			"max_mp": 2,
			"attack": 0,
			"defense": 0,
			"speed": 1,
			"crit": 0.0,
			"dodge": 0.001,
			"mp_regen": 1
		}
	}
}

const LIGHTNESS_ARTS := {
	"qg_basic": {
		"name": "基础身法",
		"type": "lightness",
		"desc": "江湖入门轻功，提气纵跃，闪避攻击。",
		"max_level": 100,
		"bonuses": {
			"speed": 0,
			"dodge": 0.001,
			"crit": 0.0,
			"flee": 0.0
		}
	},
	"qg_youlong": {
		"name": "游龙步",
		"type": "lightness",
		"desc": "八卦门步法，身如游龙，变化莫测。",
		"max_level": 100,
		"bonuses": {
			"speed": 1,
			"dodge": 0.002,
			"crit": 0.0,
			"flee": 0.003
		}
	},
	"qg_meihua": {
		"name": "梅花桩",
		"type": "lightness",
		"desc": "花间派步法，踏梅而行，身形飘忽。",
		"max_level": 100,
		"bonuses": {
			"speed": 0,
			"dodge": 0.003,
			"crit": 0.001,
			"flee": 0.002
		}
	},
	"qg_lingbo": {
		"name": "凌波微步",
		"type": "lightness",
		"desc": "逍遥派绝顶轻功，罗袜生尘，踏水无痕。",
		"max_level": 100,
		"bonuses": {
			"speed": 2,
			"dodge": 0.004,
			"crit": 0.001,
			"flee": 0.005
		}
	},
	"qg_taxue": {
		"name": "踏雪无痕",
		"type": "lightness",
		"desc": "雪山派轻功，踏雪无声，动如飘雪。",
		"max_level": 100,
		"bonuses": {
			"speed": 1,
			"dodge": 0.002,
			"crit": 0.0,
			"flee": 0.004
		}
	}
}

const MERIDIANS := {
	"m_ren": {
		"name": "任脉",
		"desc": "阴脉之海，总任诸阴。打通后内力储备与恢复大增，乃修炼之门径。",
		"prereqs": [],
		"bonuses": {"max_mp": 8, "mp_regen": 1}
	},
	"m_du": {
		"name": "督脉",
		"desc": "阳脉之海，总督诸阳。打通后攻防俱进，脱胎换骨。",
		"prereqs": ["m_ren"],
		"bonuses": {"attack": 2, "defense": 1}
	},
	"m_chong": {
		"name": "冲脉",
		"desc": "十二经之海，气血汇聚。打通后生命力与恢复力显著增强。",
		"prereqs": ["m_ren", "m_du"],
		"bonuses": {"max_hp": 15, "hp_regen": 1}
	},
	"m_dai": {
		"name": "带脉",
		"desc": "环腰约束诸经。打通后身法灵活，闪避提升。",
		"prereqs": ["m_chong"],
		"bonuses": {"speed": 1, "dodge": 0.02}
	},
	"m_yangqiao": {
		"name": "阳跷脉",
		"desc": "主肢体运动，司阳气。打通后暴击率与暴击伤害大增。",
		"prereqs": ["m_du"],
		"bonuses": {"crit": 0.02, "crit_dmg": 0.05}
	},
	"m_yinqiao": {
		"name": "阴跷脉",
		"desc": "主肢体运动，司阴气。打通后反应敏捷，抗性提升。",
		"prereqs": ["m_du"],
		"bonuses": {"dodge": 0.02, "status_resist": 0.03}
	},
	"m_yangwei": {
		"name": "阳维脉",
		"desc": "维系诸阳经。打通后内力凝实，攻击锐利。",
		"prereqs": ["m_yangqiao"],
		"bonuses": {"attack": 3, "crit": 0.01}
	},
	"m_yinwei": {
		"name": "阴维脉",
		"desc": "维系诸阴经。打通后防御坚固，减伤显著。",
		"prereqs": ["m_yinqiao"],
		"bonuses": {"defense": 2, "resist": 2}
	}
}

const MERIDIAN_MAX_LEVEL := 9

const REALMS := [
	{
		"name": "初窥门径",
		"desc": "刚入门派，学习基础功法，根基未稳。",
		"mult": 1.0,
		"req_level": 0,
		"req_meridians": 0,
		"req_internal": 0,
		"req_meridian_max": 0
	},
	{
		"name": "小有所成",
		"desc": "功法初成，可独当一面。任督二脉已通，全属性提升一成。",
		"mult": 1.1,
		"req_level": 10,
		"req_meridians": 2,
		"req_internal": 5,
		"req_meridian_max": 0
	},
	{
		"name": "炉火纯青",
		"desc": "技艺纯熟，门派中坚。四脉贯通，全属性再进二成。",
		"mult": 1.2,
		"req_level": 25,
		"req_meridians": 4,
		"req_internal": 9,
		"req_meridian_max": 0
	},
	{
		"name": "登峰造极",
		"desc": "一派宗师，开宗立派。八脉俱通，全属性大增三成。",
		"mult": 1.3,
		"req_level": 45,
		"req_meridians": 8,
		"req_internal": 0,
		"req_meridian_max": 0
	},
	{
		"name": "天人合一",
		"desc": "超凡入圣，武道巅峰。八脉圆满，全属性登极五成。",
		"mult": 1.5,
		"req_level": 60,
		"req_meridians": 8,
		"req_internal": 0,
		"req_meridian_max": 8
	}
]

var learned_internal: Dictionary = {}
var learned_lightness: Dictionary = {}
var active_internal: String = "ne_basic"
var active_lightness: String = "qg_basic"
var meridian_states: Dictionary = {}
var realm: int = 0
var qi_deviation: Dictionary = {}
var enlightenment_bonus: Dictionary = {}
var active_omen: Dictionary = {}

func learn_internal_art(art_id: String, level: int = 1) -> int:
	var data := get_internal_art_data(art_id)
	if data.is_empty():
		return 0
	var next_level := int(learned_internal.get(art_id, 0)) + level
	next_level = clampi(next_level, 1, int(data.get("max_level", 100)))
	learned_internal[art_id] = next_level
	if active_internal.is_empty():
		active_internal = art_id
	return next_level

func learn_lightness_art(art_id: String, level: int = 1) -> int:
	var data := get_lightness_art_data(art_id)
	if data.is_empty():
		return 0
	var next_level := int(learned_lightness.get(art_id, 0)) + level
	next_level = clampi(next_level, 1, int(data.get("max_level", 100)))
	learned_lightness[art_id] = next_level
	if active_lightness.is_empty():
		active_lightness = art_id
	return next_level

func set_active_internal_art(art_id: String) -> bool:
	if not learned_internal.has(art_id):
		return false
	if get_internal_art_data(art_id).is_empty():
		return false
	active_internal = art_id
	return true

func set_active_lightness_art(art_id: String) -> bool:
	if not learned_lightness.has(art_id):
		return false
	if get_lightness_art_data(art_id).is_empty():
		return false
	active_lightness = art_id
	return true

func practice_internal_art(art_id: String) -> bool:
	var current := int(learned_internal.get(art_id, 0))
	if current <= 0:
		return false
	var data := get_internal_art_data(art_id)
	var max_level := int(data.get("max_level", 100))
	if current >= max_level:
		return false
	learned_internal[art_id] = current + 1
	return true

func practice_lightness_art(art_id: String) -> bool:
	var current := int(learned_lightness.get(art_id, 0))
	if current <= 0:
		return false
	var data := get_lightness_art_data(art_id)
	var max_level := int(data.get("max_level", 100))
	if current >= max_level:
		return false
	learned_lightness[art_id] = current + 1
	return true

func get_internal_art_data(art_id: String) -> Dictionary:
	var data: Dictionary = INTERNAL_ARTS.get(art_id, {})
	return data.duplicate(true)

func get_lightness_art_data(art_id: String) -> Dictionary:
	var data: Dictionary = LIGHTNESS_ARTS.get(art_id, {})
	return data.duplicate(true)

func get_active_internal_level() -> int:
	return int(learned_internal.get(active_internal, 1))

func get_active_lightness_level() -> int:
	return int(learned_lightness.get(active_lightness, 1))

func get_practice_cost(art_id: String, is_internal: bool) -> int:
	var current := 0
	if is_internal:
		current = int(learned_internal.get(art_id, 0))
	else:
		current = int(learned_lightness.get(art_id, 0))
	return int(max(8, current * 4))

func get_meridian_data(meridian_id: String) -> Dictionary:
	var data: Dictionary = MERIDIANS.get(meridian_id, {})
	return data.duplicate(true)

func get_meridian_state(meridian_id: String) -> Dictionary:
	return meridian_states.get(meridian_id, {"opened": false, "level": 0})

func is_meridian_opened(meridian_id: String) -> bool:
	var state: Dictionary = meridian_states.get(meridian_id, {})
	return bool(state.get("opened", false))

func get_opened_meridian_count() -> int:
	var count := 0
	for meridian_id in MERIDIANS.keys():
		if is_meridian_opened(str(meridian_id)):
			count += 1
	return count

func can_open_meridian(meridian_id: String) -> bool:
	if not MERIDIANS.has(meridian_id):
		return false
	if is_meridian_opened(meridian_id):
		return false
	var data: Dictionary = MERIDIANS[meridian_id]
	var prereqs: Array = data.get("prereqs", [])
	for prereq in prereqs:
		if not is_meridian_opened(str(prereq)):
			return false
	return true

func get_meridian_open_cost() -> int:
	return 80 * (get_opened_meridian_count() + 1)

func open_meridian(meridian_id: String) -> bool:
	if not can_open_meridian(meridian_id):
		return false
	meridian_states[meridian_id] = {"opened": true, "level": 0}
	return true

func get_meridian_train_cost(meridian_id: String) -> int:
	var state: Dictionary = get_meridian_state(meridian_id)
	var level := int(state.get("level", 0))
	return 12 + level * 5

func train_meridian(meridian_id: String) -> bool:
	if not is_meridian_opened(meridian_id):
		return false
	var state: Dictionary = get_meridian_state(meridian_id)
	var level := int(state.get("level", 0))
	if level >= MERIDIAN_MAX_LEVEL:
		return false
	meridian_states[meridian_id] = {"opened": true, "level": level + 1}
	return true

func get_meridian_bonuses() -> Dictionary:
	var bonuses := {
		"max_hp": 0, "max_mp": 0, "attack": 0, "defense": 0, "speed": 0,
		"mp_regen": 0, "hp_regen": 0, "resist": 0,
		"crit": 0.0, "dodge": 0.0, "flee": 0.0,
		"crit_dmg": 0.0, "status_resist": 0.0
	}
	for meridian_id in MERIDIANS.keys():
		if not is_meridian_opened(str(meridian_id)):
			continue
		var state: Dictionary = get_meridian_state(str(meridian_id))
		var level := int(state.get("level", 0))
		var data: Dictionary = MERIDIANS[meridian_id]
		var base_bonuses: Dictionary = data.get("bonuses", {})
		var mult := level + 1
		for key in ["max_hp", "max_mp", "attack", "defense", "speed", "mp_regen", "hp_regen", "resist"]:
			var per := int(base_bonuses.get(key, 0))
			if per != 0:
				bonuses[key] = int(bonuses.get(key, 0)) + per * mult
		for key in ["crit", "dodge", "flee", "crit_dmg", "status_resist"]:
			var per := float(base_bonuses.get(key, 0.0))
			if per != 0.0:
				bonuses[key] = float(bonuses.get(key, 0.0)) + per * mult
	return bonuses

func get_realm_data(index: int) -> Dictionary:
	var clamped := clampi(index, 0, REALMS.size() - 1)
	return REALMS[clamped].duplicate(true)

func get_realm_name() -> String:
	return str(REALMS[clampi(realm, 0, REALMS.size() - 1)].get("name", "初窥门径"))

func get_realm_multiplier() -> float:
	return float(REALMS[clampi(realm, 0, REALMS.size() - 1)].get("mult", 1.0))

func get_max_internal_level() -> int:
	var highest := 0
	for art_id in learned_internal.keys():
		highest = maxi(highest, int(learned_internal[art_id]))
	return highest

func get_maxed_meridian_count() -> int:
	var count := 0
	for meridian_id in MERIDIANS.keys():
		var state := get_meridian_state(str(meridian_id))
		if bool(state.get("opened", false)) and int(state.get("level", 0)) >= MERIDIAN_MAX_LEVEL:
			count += 1
	return count

func can_breakthrough(player_level: int) -> bool:
	var next_realm := realm + 1
	if next_realm >= REALMS.size():
		return false
	var data: Dictionary = REALMS[next_realm]
	if player_level < int(data.get("req_level", 0)):
		return false
	if get_opened_meridian_count() < int(data.get("req_meridians", 0)):
		return false
	var req_internal := int(data.get("req_internal", 0))
	if req_internal > 0 and get_max_internal_level() < req_internal:
		return false
	var req_meridian_max := int(data.get("req_meridian_max", 0))
	if req_meridian_max > 0 and get_maxed_meridian_count() < req_meridian_max:
		return false
	return true

func get_breakthrough_cost() -> int:
	return 120 * (realm + 1)

func get_breakthrough_progress(player_level: int) -> Dictionary:
	var next_realm := realm + 1
	if next_realm >= REALMS.size():
		return {"at_max": true}
	var data: Dictionary = REALMS[next_realm]
	return {
		"at_max": false,
		"name": str(data.get("name", "")),
		"desc": str(data.get("desc", "")),
		"mult": float(data.get("mult", 1.0)),
		"req_level": int(data.get("req_level", 0)),
		"req_meridians": int(data.get("req_meridians", 0)),
		"req_internal": int(data.get("req_internal", 0)),
		"req_meridian_max": int(data.get("req_meridian_max", 0)),
		"cur_level": player_level,
		"cur_meridians": get_opened_meridian_count(),
		"cur_internal": get_max_internal_level(),
		"cur_meridian_max": get_maxed_meridian_count(),
		"can_breakthrough": can_breakthrough(player_level)
	}

func breakthrough(player_data: Dictionary = {}) -> Dictionary:
	## 突破：条件满足时检查内力是否充足，不足有走火入魔风险
	if realm + 1 >= REALMS.size():
		return {"success": false, "reason": "at_max"}
	var next_realm := realm + 1
	var req_data: Dictionary = REALMS[next_realm]
	var max_mp := int(player_data.get("max_mp", 1))
	var cur_mp := int(player_data.get("mp", 0))
	var mp_ratio := float(cur_mp) / float(maxi(1, max_mp))
	## 内力低于 30% 时有走火入魔风险
	if mp_ratio < 0.3:
		var fail_chance := (0.3 - mp_ratio) / 0.3 * 0.6
		if randf() < fail_chance:
			var severity := 1
			if mp_ratio < 0.1:
				severity = 3
			elif mp_ratio < 0.2:
				severity = 2
			qi_deviation = {
				"severity": severity,
				"penalty_mult": 1.0 - 0.1 * severity,
				"expire_day": int(player_data.get("day", 1)) + severity * 3,
				"reason": "强行冲关"
			}
			return {
				"success": false,
				"reason": "qi_deviation",
				"severity": severity,
				"omen": str(req_data.get("omen", ""))
			}
	realm = clampi(realm + 1, 0, REALMS.size() - 1)
	var omen := _generate_breakthrough_omen(realm)
	var hours := int(omen.get("hours", 0))
	var expire_day := int(player_data.get("day", 0)) + int(ceil(float(hours) / 24.0))
	omen["expire_day"] = expire_day
	active_omen = omen.duplicate(true)
	return {
		"success": true,
		"reason": "ok",
		"old_realm": realm - 1,
		"new_realm": realm,
		"omen": omen
	}

func _generate_breakthrough_omen(new_realm: int) -> Dictionary:
	## 天象变化：按境界生成对应天象和临时 buff
	match new_realm:
		1:
			return {"type": "祥云笼罩", "desc": "异香扑鼻，修炼效率提升", "buff": "cultivation_exp", "mult": 1.2, "hours": 6}
		2:
			return {"type": "霞光万丈", "desc": "百鸟来朝，战力提升", "buff": "combat_power", "mult": 1.15, "hours": 18}
		3:
			return {"type": "雷劫降临", "desc": "地涌金莲，名望翻倍", "buff": "fame_gain", "mult": 2.0, "hours": 24}
		4:
			return {"type": "天地共鸣", "desc": "日月同辉，永久增益", "buff": "permanent", "mult": 1.1, "hours": 0}
		_:
			return {}

func has_qi_deviation() -> bool:
	return not qi_deviation.is_empty()

func get_qi_deviation_penalty() -> float:
	if qi_deviation.is_empty():
		return 1.0
	return float(qi_deviation.get("penalty_mult", 1.0))

func clear_qi_deviation() -> void:
	qi_deviation.clear()

func tick_qi_deviation(current_day: int) -> bool:
	## 每天检查走火入魔是否恢复，返回是否已清除
	if qi_deviation.is_empty():
		return false
	if current_day >= int(qi_deviation.get("expire_day", 0)):
		qi_deviation.clear()
		return true
	return false

func get_active_omen() -> Dictionary:
	return active_omen.duplicate(true)

func tick_omen(current_day: int) -> bool:
	## 每天检查天象 buff 是否过期，返回是否已过期清除
	if active_omen.is_empty():
		return false
	var expire_day := int(active_omen.get("expire_day", 0))
	if expire_day > 0 and current_day >= expire_day:
		active_omen.clear()
		return true
	return false

func clear_omen() -> void:
	active_omen.clear()

func get_total_bonuses() -> Dictionary:
	var bonuses := {
		"max_hp": 0,
		"max_mp": 0,
		"attack": 0,
		"defense": 0,
		"speed": 0,
		"crit": 0.0,
		"dodge": 0.0,
		"flee": 0.0,
		"mp_regen": 0,
		"hp_regen": 0,
		"resist": 0,
		"crit_dmg": 0.0,
		"status_resist": 0.0
	}
	# 内功加成按激活内功计算；已学会但未激活的内功保留 10% 被动加成
	for art_id in learned_internal.keys():
		var level := int(learned_internal.get(art_id, 0))
		var data := INTERNAL_ARTS.get(art_id, {}) as Dictionary
		var art_bonuses: Dictionary = data.get("bonuses", {})
		var factor := 1.0 if art_id == active_internal else 0.1
		_bonuses_add(bonuses, art_bonuses, level, factor)

	for art_id in learned_lightness.keys():
		var level := int(learned_lightness.get(art_id, 0))
		var data := LIGHTNESS_ARTS.get(art_id, {}) as Dictionary
		var art_bonuses: Dictionary = data.get("bonuses", {})
		var factor := 1.0 if art_id == active_lightness else 0.1
		_bonuses_add(bonuses, art_bonuses, level, factor)

	_merge_meridian_bonuses(bonuses)
	_merge_enlightenment_bonuses(bonuses)
	return bonuses

func _merge_enlightenment_bonuses(total: Dictionary) -> void:
	for key in ["max_hp", "max_mp", "attack", "defense", "speed", "mp_regen", "hp_regen", "resist"]:
		total[key] = int(total.get(key, 0)) + int(enlightenment_bonus.get(key, 0))
	for key in ["crit", "dodge", "flee", "crit_dmg", "status_resist"]:
		total[key] = float(total.get(key, 0.0)) + float(enlightenment_bonus.get(key, 0.0))

func _merge_meridian_bonuses(total: Dictionary) -> void:
	var meridian := get_meridian_bonuses()
	for key in ["max_hp", "max_mp", "attack", "defense", "speed", "mp_regen", "hp_regen", "resist"]:
		total[key] = int(total.get(key, 0)) + int(meridian.get(key, 0))
	for key in ["crit", "dodge", "flee", "crit_dmg", "status_resist"]:
		total[key] = float(total.get(key, 0.0)) + float(meridian.get(key, 0.0))

func _bonuses_add(total: Dictionary, art_bonuses: Dictionary, level: int, factor: float) -> void:
	for key in ["max_hp", "max_mp", "attack", "defense", "speed", "mp_regen"]:
		var per_level := int(art_bonuses.get(key, 0))
		if per_level != 0:
			total[key] = int(total.get(key, 0)) + int(round(float(per_level * level) * factor))
	for key in ["crit", "dodge", "flee"]:
		var per_level := float(art_bonuses.get(key, 0.0))
		if per_level != 0.0:
			total[key] = float(total.get(key, 0.0)) + per_level * level * factor

func serialize() -> Dictionary:
	return {
		"learned_internal": learned_internal.duplicate(true),
		"learned_lightness": learned_lightness.duplicate(true),
		"active_internal": active_internal,
		"active_lightness": active_lightness,
		"meridian_states": meridian_states.duplicate(true),
		"realm": realm,
		"qi_deviation": qi_deviation.duplicate(true),
		"enlightenment_bonus": enlightenment_bonus.duplicate(true),
		"active_omen": active_omen.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	learned_internal = data.get("learned_internal", {}) if typeof(data.get("learned_internal")) == TYPE_DICTIONARY else {}
	learned_lightness = data.get("learned_lightness", {}) if typeof(data.get("learned_lightness")) == TYPE_DICTIONARY else {}
	active_internal = str(data.get("active_internal", "ne_basic"))
	active_lightness = str(data.get("active_lightness", "qg_basic"))
	var raw_meridians = data.get("meridian_states", {})
	meridian_states = raw_meridians.duplicate(true) if typeof(raw_meridians) == TYPE_DICTIONARY else {}
	realm = clampi(int(data.get("realm", 0)), 0, REALMS.size() - 1)
	var raw_qi = data.get("qi_deviation", {})
	qi_deviation = raw_qi.duplicate(true) if typeof(raw_qi) == TYPE_DICTIONARY else {}
	var raw_enlight = data.get("enlightenment_bonus", {})
	enlightenment_bonus = raw_enlight.duplicate(true) if typeof(raw_enlight) == TYPE_DICTIONARY else {}
	var raw_omen = data.get("active_omen", {})
	active_omen = raw_omen.duplicate(true) if typeof(raw_omen) == TYPE_DICTIONARY else {}
	_normalize()

func _normalize() -> void:
	if learned_internal.is_empty():
		learned_internal["ne_basic"] = 1
	if learned_lightness.is_empty():
		learned_lightness["qg_basic"] = 1
	if not learned_internal.has(active_internal):
		active_internal = str(learned_internal.keys()[0])
	if not learned_lightness.has(active_lightness):
		active_lightness = str(learned_lightness.keys()[0])

func reset() -> void:
	learned_internal.clear()
	learned_lightness.clear()
	meridian_states.clear()
	active_internal = "ne_basic"
	active_lightness = "qg_basic"
	learned_internal["ne_basic"] = 1
	learned_lightness["qg_basic"] = 1
	realm = 0
	qi_deviation.clear()
	enlightenment_bonus.clear()
	active_omen.clear()

const ENLIGHTENMENT_EVENTS := {
	"mountain": {"name": "观山悟道", "desc": "山峰雄奇，悟得刚猛之意", "mp": 50, "exp": 1000, "attack": 10, "chance": 0.05},
	"water": {"name": "观水悟道", "desc": "流水不息，悟得绵长之劲", "mp": 0, "exp": 800, "mp_regen": 2, "chance": 0.05},
	"cloud": {"name": "观云悟道", "desc": "云卷云舒，悟得轻灵之姿", "mp": 0, "exp": 600, "speed": 5, "chance": 0.05},
	"star": {"name": "观星悟道", "desc": "星辰运转，悟得命理之机", "mp": 0, "exp": 1200, "crit": 0.03, "chance": 0.03},
	"combat": {"name": "战斗悟道", "desc": "生死之间，悟得杀伐之决", "mp": 0, "exp": 1500, "attack": 10, "chance": 0.02},
	"despair": {"name": "绝境悟道", "desc": "命悬一线，悟得破釜之志", "mp": 0, "exp": 2000, "max_hp": 50, "chance": 0.01}
}

func try_enlightenment(context: Dictionary) -> Dictionary:
	## 悟道事件触发：context.terrain / context.in_combat / context.hp_ratio
	var terrain := str(context.get("terrain", ""))
	var in_combat := bool(context.get("in_combat", false))
	var hp_ratio := float(context.get("hp_ratio", 1.0))
	var event_id := ""
	if in_combat and hp_ratio < 0.1:
		event_id = "despair"
	elif in_combat:
		event_id = "combat"
	else:
		var category := _terrain_enlightenment_category(terrain)
		event_id = category
	var event_data: Dictionary = ENLIGHTENMENT_EVENTS.get(event_id, {})
	if event_data.is_empty():
		return {}
	var chance := float(event_data.get("chance", 0.0))
	if randf() > chance:
		return {}
	return {"id": event_id, "data": event_data}

func _terrain_enlightenment_category(terrain: String) -> String:
	## 将原始地貌归类为悟道事件类型
	var t := terrain.to_lower()
	if t.contains("mountain") or t.contains("cliff") or t.contains("gorge") or t.contains("pass") or t.contains("mound") or t.contains("plateau") or t.contains("peak"):
		return "mountain"
	if t.contains("river") or t.contains("water") or t.contains("lake") or t.contains("canal") or t.contains("ford") or t.contains("marsh") or t.contains("spring") or t.contains("sea"):
		return "water"
	if t.contains("forest") or t.contains("bamboo") or t.contains("cloud") or t.contains("peak") or t.contains("valley") or t.contains("garden"):
		return "cloud"
	return "star"

func apply_enlightenment(event_id: String) -> Dictionary:
	## 应用悟道事件加成到 enlightenment_bonus（永久累积）
	var event_data: Dictionary = ENLIGHTENMENT_EVENTS.get(event_id, {})
	if event_data.is_empty():
		return {}
	for key in ["attack", "max_hp", "speed", "mp_regen"]:
		var val := int(event_data.get(key, 0))
		if val != 0:
			enlightenment_bonus[key] = int(enlightenment_bonus.get(key, 0)) + val
	for key in ["crit"]:
		var val := float(event_data.get(key, 0.0))
		if val != 0.0:
			enlightenment_bonus[key] = float(enlightenment_bonus.get(key, 0.0)) + val
	return event_data
