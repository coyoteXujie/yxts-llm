extends RefCounted
class_name AtmosphereSystem

var _state: Node

func _init(state: Node) -> void:
	_state = state

func advance_time(delta: float) -> void:
	if not _state.can_explore():
		return
	_state.hour += delta * 0.08
	if _state.hour >= 24.0:
		_state.hour -= 24.0
		_state.day += 1
		_state._advance_season_if_needed()
		_roll_weather()
		_run_daily_world_pulse()
	EventBus.time_changed.emit(_state.day, _state.hour, _state.weather)

func _roll_weather() -> void:
	var weights: Dictionary = _season_weather_weights()
	var pool: Array = []
	for weather_type in weights.keys():
		var w := int(weights[weather_type])
		for _i in range(w):
			pool.append(weather_type)
	if pool.is_empty():
		_state.weather = "晴朗"
	else:
		_state.weather = str(pool[randi_range(0, pool.size() - 1)])

func _season_weather_weights() -> Dictionary:
	match _state.season:
		"春":
			return {"晴朗": 3, "多云": 3, "细雨": 4, "薄雾": 3, "飞雪": 0, "雷暴": 1}
		"夏":
			return {"晴朗": 5, "多云": 3, "细雨": 2, "薄雾": 1, "飞雪": 0, "雷暴": 3}
		"秋":
			return {"晴朗": 4, "多云": 3, "细雨": 2, "薄雾": 3, "飞雪": 0, "雷暴": 1}
		"冬":
			return {"晴朗": 2, "多云": 2, "细雨": 1, "薄雾": 2, "飞雪": 5, "雷暴": 0}
		_:
			return {"晴朗": 3, "多云": 3, "细雨": 2, "薄雾": 2, "飞雪": 1, "雷暴": 1}

func _run_daily_world_pulse() -> void:
	var flag_key := "world_pulse_day_%d" % _state.day
	if bool(_state.game_flags.get(flag_key, false)):
		return
	_state.game_flags[flag_key] = true
	_state.process_pending_chain_events()
	_maybe_trigger_seasonal_event()
	var pulse_event: Dictionary = _build_daily_world_pulse_event()
	if pulse_event.is_empty():
		return
	_state.append_world_event(
		str(pulse_event.get("kind", "world_pulse")),
		str(pulse_event.get("title", "每日风声")),
		str(pulse_event.get("description", "")),
		str(pulse_event.get("region_id", _state.current_region_id)),
		int(pulse_event.get("severity", 2))
	)

func _build_daily_world_pulse_event() -> Dictionary:
	var region: Dictionary = _select_daily_pulse_region()
	if region.is_empty():
		return {}
	var region_id := str(region.get("id", _state.current_region_id))
	var region_name := str(region.get("name", _state.current_region_name))
	var danger := int(region.get("danger", 1))
	var stage: String = _state._current_story_stage()
	var selector: int = abs(hash("%d:%s:%s:%s" % [_state.day, region_id, _state.weather, stage])) % 4
	var title := ""
	var description := ""
	var severity := 2
	match selector:
		0:
			title = "%s驿路风声" % region_name
			description = "%s一带%s，脚夫说有陌生人沿着旧路打听%s。" % [region_name, _weather_world_phrase(), stage]
			severity = 2 + int(danger >= 3)
		1:
			title = "%s山门传书" % region_name
			description = "%s附近有人快马递信，信上反复提到%s。" % [region_name, stage]
			severity = 3 if stage.contains("暗影") or stage.contains("七派") else 2
		2:
			title = "%s夜里见影" % region_name
			description = "%s夜间多了几道不报姓名的脚印，客栈里都说这不像寻常盗匪。" % region_name
			severity = 3 + int(danger >= 4)
		_:
			title = "江湖天气转冷"
			description = "%s%s，商旅改了行程，也把%s的风声带到了路口。" % [region_name, _weather_world_phrase(), stage]
			severity = 2
	return {
		"kind": "world_pulse",
		"title": title,
		"description": description,
		"region_id": region_id,
		"severity": clampi(severity, 2, 4)
	}

func _select_daily_pulse_region() -> Dictionary:
	var candidates: Array = []
	for region_id in _state.region_state.keys():
		var state: Dictionary = _state.region_state.get(region_id, {})
		if not bool(state.get("discovered", false)):
			continue
		var region := GameData.get_region(str(region_id))
		if not region.is_empty():
			candidates.append(region)
	if not _state.current_region_id.is_empty():
		var current := GameData.get_region(_state.current_region_id)
		if not current.is_empty() and not candidates.has(current):
			candidates.append(current)
	if not _state.map_target_region_id.is_empty():
		var target := GameData.get_region(_state.map_target_region_id)
		if not target.is_empty() and not candidates.has(target):
			candidates.append(target)
	if candidates.is_empty():
		var fallback := GameData.get_region("qinghe")
		return fallback if not fallback.is_empty() else {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("danger", 1)) > int(b.get("danger", 1))
	)
	var limit: int = mini(candidates.size(), 6)
	var index: int = abs(hash("%d:%s:%s" % [_state.day, _state.weather, _state.active_quest])) % limit
	return (candidates[index] as Dictionary).duplicate(true)

func _weather_world_phrase() -> String:
	match _state.weather:
		"细雨":
			return "雨声压低"
		"薄雾":
			return "雾色很重"
		"飞雪":
			return "雪路难行"
		"多云":
			return "云影不散"
		"雷暴":
			return "雷声压顶"
		_:
			return "天色清明"

func _maybe_trigger_seasonal_event() -> void:
	var season_flag := "seasonal_event_%s_day_%d" % [_state.season, _state.day]
	if bool(_state.game_flags.get(season_flag, false)):
		return
	if randf() > 0.18:
		return
	_state.game_flags[season_flag] = true
	var region: Dictionary = _select_daily_pulse_region()
	var region_name := str(region.get("name", _state.current_region_name))
	var region_id := str(region.get("id", _state.current_region_id))
	var title := ""
	var description := ""
	var severity := 2
	match _state.season:
		"春":
			title = "%s春社祭典" % region_name
			description = "春社日近，%s的乡民备下酒食祭品，各路江湖人也趁此聚会切磋。" % region_name
			severity = 2
		"夏":
			title = "%s伏暑瘟疫" % region_name
			description = "盛夏酷热，%s一带出现热瘟迹象，药铺门前排起长队，有人趁乱高价倒卖药材。" % region_name
			severity = 3
		"秋":
			title = "%s中秋论剑" % region_name
			description = "中秋将近，%s有豪侠张罗论剑大会，四方好手闻讯而来，胜负赌注也随之水涨船高。" % region_name
			severity = 3
		"冬":
			title = "%s寒冬赈济" % region_name
			description = "天寒地冻，%s的流民增多，几家善堂开始施粥赈济，但也有人借机敛财。" % region_name
			severity = 2
		_:
			return
	_state.append_world_event("seasonal", title, description, region_id, severity)
