extends RefCounted
class_name FastTravelSystem

var _state: Node

func _init(state: Node) -> void:
	_state = state

func set_map_target_region(region_id: String) -> void:
	if _state.map_target_region_id == region_id:
		return
	_state.map_target_region_id = region_id
	EventBus.map_target_changed.emit(_state.map_target_region_id)

func get_map_target_summary() -> String:
	if _state.map_target_region_id.is_empty():
		return ""
	var region := GameData.get_region(_state.map_target_region_id)
	if region.is_empty():
		return ""
	var region_name := str(region.get("name", _state.map_target_region_id))
	var label := "地图标记"
	var active_target_region: Dictionary = _state.get_active_quest_target_region()
	if not active_target_region.is_empty() and str(active_target_region.get("id", "")) == _state.map_target_region_id:
		label = "任务目标"
	if _state.map_target_region_id == _state.current_region_id:
		return "%s：已抵达%s" % [label, region_name]
	var plan := build_region_travel_plan(_state.map_target_region_id)
	var reason := str(plan.get("blocked_reason", ""))
	var route_summary := str(plan.get("route_summary", ""))
	var risk_label := str(plan.get("risk_label", ""))
	var travel_text := "%.1f时辰 · %d两" % [
		float(plan.get("hours", 0.0)),
		int(plan.get("fare", 0))
	]
	if not risk_label.is_empty():
		travel_text = "%s · %s" % [travel_text, risk_label]
	if not route_summary.is_empty():
		travel_text = "%s · %s" % [travel_text, route_summary]
	if reason.is_empty():
		return "%s：%s · 可驿路 %s" % [label, region_name, travel_text]
	if route_summary.is_empty():
		return "%s：%s · %s" % [label, region_name, reason]
	return "%s：%s · 路线 %s · %s" % [label, region_name, travel_text, reason]

func get_fast_travel_block_reason(region_id: String) -> String:
	if region_id.is_empty():
		return "未选择区域"
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return "区域不存在"
	if not _state.is_region_discovered(region_id):
		return "尚未发现该区域"
	var source_region := _current_travel_source_region()
	if source_region.is_empty():
		return "当前位置不在可识别区域"
	if region_id == str(source_region.get("id", "")):
		return "已经身在此处"
	var region_type := str(region.get("type", "wild"))
	if not _state.FAST_TRAVEL_REGION_TYPES.has(region_type):
		return "荒野区域暂不可快速前往，只能标记目的地"
	var exploration: int = _state.get_region_exploration(region_id)
	if exploration < _state.FAST_TRAVEL_MIN_EXPLORATION:
		return "探索度达到%d%%后解锁驿路" % _state.FAST_TRAVEL_MIN_EXPLORATION
	var fare := estimate_fast_travel_fare(region_id)
	if int(_state.player.get("money", 0)) < fare:
		return "驿路费用 %d 两，银两不足" % fare
	var access_msg := _check_region_access_rule(region_id)
	if not access_msg.is_empty():
		return access_msg
	return ""

func _check_region_access_rule(region_id: String) -> String:
	var rule := GameData.get_region_access_rule(region_id)
	if not rule.is_empty():
		var required_item := str(rule.get("required_item", ""))
		if not required_item.is_empty() and int(_state.inventory.get(required_item, 0)) <= 0:
			var item := GameData.get_item(required_item)
			var item_name := str(item.get("name", required_item))
			var note := str(rule.get("blocked_note", ""))
			if note.is_empty():
				return "需持%s方可通行" % item_name
			return note
		var required_quest := str(rule.get("required_quest", ""))
		if not required_quest.is_empty() and not _state.completed_quests.has(required_quest):
			var note := str(rule.get("blocked_note", ""))
			if note.is_empty():
				return "需完成相关任务后方可通行"
			return note
		var required_exploration := int(rule.get("required_source_exploration", 0))
		if required_exploration > 0:
			var source_region := _current_travel_source_region()
			var source_id := str(source_region.get("id", ""))
			if not source_id.is_empty():
				var source_exp: int = _state.get_region_exploration(source_id)
				if source_exp < required_exploration:
					var note := str(rule.get("blocked_note", ""))
					if note.is_empty():
						return "当前区域探索度需达%d%%（当前%d%%）" % [required_exploration, source_exp]
					return note
	var conn_block := _check_secret_connection_block(region_id)
	if not conn_block.is_empty():
		return conn_block
	return ""

func _check_secret_connection_block(region_id: String) -> String:
	var source_region := _current_travel_source_region()
	var source_id := str(source_region.get("id", ""))
	if source_id.is_empty():
		return ""
	var connections: Array[Dictionary] = GameData.get_region_connections(source_id)
	var has_normal_connection := false
	var secret_conn: Dictionary = {}
	for conn in connections:
		if str(conn.get("target", "")) != region_id:
			continue
		if str(conn.get("type", "")) != "secret":
			has_normal_connection = true
			continue
		secret_conn = conn
	if has_normal_connection or secret_conn.is_empty():
		return ""
	var required_quest := str(secret_conn.get("required_quest", ""))
	if not required_quest.is_empty() and not _state.completed_quests.has(required_quest):
		var note := str(secret_conn.get("note", ""))
		if note.is_empty():
			return "需完成相关任务后方可发现入口"
		return note
	var required_item := str(secret_conn.get("required_item", ""))
	if not required_item.is_empty() and int(_state.inventory.get(required_item, 0)) <= 0:
		var item := GameData.get_item(required_item)
		var item_name := str(item.get("name", required_item))
		var note := str(secret_conn.get("note", ""))
		if note.is_empty():
			return "需持%s方可通行" % item_name
		return note
	var required_exploration := int(secret_conn.get("required_source_exploration", 0))
	if required_exploration > 0:
		var source_exp: int = _state.get_region_exploration(source_id)
		if source_exp < required_exploration:
			var note := str(secret_conn.get("note", ""))
			if note.is_empty():
				return "当前区域探索度需达%d%%（当前%d%%）方可发现入口" % [required_exploration, source_exp]
			return note
	return ""

func can_fast_travel_to_region(region_id: String) -> bool:
	return get_fast_travel_block_reason(region_id).is_empty()

func get_roadside_travel_block_reason(region_id: String) -> String:
	var rule := GameData.get_region_access_rule(region_id)
	if rule.is_empty():
		return ""
	var required_item := str(rule.get("required_item", ""))
	if not required_item.is_empty() and int(_state.inventory.get(required_item, 0)) <= 0:
		var item := GameData.get_item(required_item)
		var item_name := str(item.get("name", required_item))
		var note := str(rule.get("blocked_note", ""))
		if note.is_empty():
			return "需持%s方可通行" % item_name
		return note
	var required_quest := str(rule.get("required_quest", ""))
	if not required_quest.is_empty() and not _state.completed_quests.has(required_quest):
		var note := str(rule.get("blocked_note", ""))
		if note.is_empty():
			return "需完成相关任务后方可通行"
		return note
	var required_exploration := int(rule.get("required_source_exploration", 0))
	if required_exploration > 0:
		var source_region := _current_travel_source_region()
		var source_id := str(source_region.get("id", ""))
		if not source_id.is_empty():
			var source_exp: int = _state.get_region_exploration(source_id)
			if source_exp < required_exploration:
				var note := str(rule.get("blocked_note", ""))
				if note.is_empty():
					return "当前区域探索度需达%d%%（当前%d%%）" % [required_exploration, source_exp]
				return note
	return _check_secret_connection_block(region_id)

func build_region_travel_plan(region_id: String) -> Dictionary:
	var target_region := GameData.get_region(region_id)
	var source_region := _current_travel_source_region()
	var source_id := str(source_region.get("id", ""))
	return _build_region_travel_plan_from_source(source_id, region_id, target_region, get_fast_travel_block_reason(region_id))

func _build_region_travel_plan_from_source(source_id: String, region_id: String, target_region: Dictionary, blocked_reason: String = "") -> Dictionary:
	var route := TravelPlanner.find_region_route(source_id, region_id, _state.current_tile)
	var route_names := TravelPlanner.route_region_names(route)
	var distance := TravelPlanner.route_distance(route, _state.current_tile)
	var hours := _estimate_route_hours(route, target_region)
	var risk_level := _travel_risk_level(route, target_region)
	var fare := _estimate_route_fare(route, target_region)
	var familiarity_note := _travel_familiarity_note(target_region)
	return {
		"source_region_id": source_id,
		"target_region_id": region_id,
		"route": route,
		"route_names": route_names,
		"route_summary": " -> ".join(route_names),
		"distance": distance,
		"hours": hours,
		"fare": fare,
		"risk_level": risk_level,
		"risk_label": TravelPlanner.route_risk_label(risk_level),
		"risk_note": TravelPlanner.route_risk_note(risk_level),
		"familiarity_note": familiarity_note,
		"familiarity_discount": _travel_familiarity_discount(target_region),
		"familiarity_risk_reduction": _travel_familiarity_risk_reduction(target_region),
		"blocked_reason": blocked_reason,
		"can_fast_travel": blocked_reason.is_empty()
	}

func estimate_fast_travel_hours(region_id: String) -> float:
	var target_region := GameData.get_region(region_id)
	if target_region.is_empty():
		return 0.0
	var source_region := _current_travel_source_region()
	var route := TravelPlanner.find_region_route(str(source_region.get("id", "")), region_id, _state.current_tile)
	return _estimate_route_hours(route, target_region)

func estimate_fast_travel_fare(region_id: String) -> int:
	var target_region := GameData.get_region(region_id)
	if target_region.is_empty():
		return 0
	var source_region := _current_travel_source_region()
	var route := TravelPlanner.find_region_route(str(source_region.get("id", "")), region_id, _state.current_tile)
	return _estimate_route_fare(route, target_region)

func apply_fast_travel_time(region_id: String) -> float:
	var reason := get_fast_travel_block_reason(region_id)
	if not reason.is_empty():
		EventBus.emit_toast(reason)
		return -1.0
	var plan := build_region_travel_plan(region_id)
	var travel_hours := float(plan.get("hours", estimate_fast_travel_hours(region_id)))
	var fare := int(plan.get("fare", 0))
	if fare > 0 and not _state.spend_money(fare):
		return -1.0
	_state.advance_hours(travel_hours)
	_record_fast_travel_event(plan)
	return travel_hours

func resolve_fast_travel_risk(plan: Dictionary) -> Dictionary:
	var risk_level := int(plan.get("risk_level", 1))
	if risk_level < 3:
		return {}
	var target_id := str(plan.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		return {}
	var chance := clampf(0.10 + float(risk_level - 3) * 0.16, 0.10, 0.48)
	if randf() > chance:
		return {}
	var target_name := str(target_region.get("name", target_id))
	var selector: int = int(abs(hash("%d:%s:%s:%s" % [_state.day, target_id, _state.weather, str(plan.get("route_summary", ""))])) % 3)
	if risk_level >= 4 and selector == 0:
		var enemy: Dictionary = GameData.build_region_encounter_enemy(target_region)
		if not enemy.is_empty():
			var ambush_title := "%s驿路遇伏" % target_name
			var ambush_description := "你刚抵达%s，暗处有人趁旅途疲惫截住去路。" % target_name
			_state.append_world_event("travel_risk", ambush_title, ambush_description, target_id, mini(risk_level, 4))
			return {
				"kind": "ambush",
				"title": ambush_title,
				"description": ambush_description,
				"enemy": enemy,
				"toast": "%s，准备迎战" % ambush_title
			}
	if risk_level >= 5 and selector == 1:
		var formation_data := GameData.build_formation_encounter(target_region)
		if not formation_data.enemies.is_empty():
			var ambush_title := "%s驿路遇伏兵结阵" % target_name
			var ambush_description := "你刚抵达%s，数名伏兵结阵拦路。" % target_name
			_state.append_world_event("travel_risk", ambush_title, ambush_description, target_id, mini(risk_level, 4))
			return {
				"kind": "formation_ambush",
				"title": ambush_title,
				"description": ambush_description,
				"enemies": formation_data.enemies,
				"formation_type": formation_data.formation_type,
				"toast": "%s，准备迎战" % ambush_title
			}
	var delay_hours := 0.5 + float(risk_level - 2) * 0.25
	_state.advance_hours(delay_hours)
	var damage := risk_level * 5 + randi_range(0, 6)
	var hp := int(_state.player.get("hp", 0))
	var actual_damage: int = _state.damage_player(mini(damage, maxi(0, hp - 1)))
	var delay_title := "%s驿路受阻" % target_name
	var delay_description := "你在%s附近遇到险路和盘查，耽搁%.1f时辰，气血损耗%d点。" % [target_name, delay_hours, actual_damage]
	_state.append_world_event("travel_risk", delay_title, delay_description, target_id, mini(risk_level, 4))
	return {
		"kind": "delay",
		"title": delay_title,
		"description": delay_description,
		"delay_hours": delay_hours,
		"damage": actual_damage,
		"toast": "%s：耽搁%.1f时辰，气血-%d" % [delay_title, delay_hours, actual_damage]
	}

func _current_travel_source_region() -> Dictionary:
	var region := GameData.get_region(_state.current_region_id)
	if not region.is_empty():
		return region
	var tile_region := GameData.get_region_at_tile(_state.current_tile)
	if not tile_region.is_empty():
		return tile_region
	return {}

## 旅行途中的非战斗遭遇：发现隐藏地点、NPC邂逅、天气影响
func resolve_travel_encounter(plan: Dictionary) -> Dictionary:
	var target_id := str(plan.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		return {}
	var risk_level := int(plan.get("risk_level", 1))
	var route_names: Array = plan.get("route_names", [])
	var target_name := str(target_region.get("name", target_id))
	var seed_str := "%d:%s:%s:%s" % [_state.day, target_id, _state.weather, str(plan.get("route_summary", ""))]
	var roll: int = abs(hash(seed_str)) % 100
	if roll < 12 and route_names.size() >= 2:
		return _encounter_hidden_spot(target_id, target_name, target_region)
	if roll < 22 and risk_level <= 3:
		return _encounter_wandering_npc(target_id, target_name, route_names)
	if roll < 32 and not _state.weather.is_empty() and _state.weather != "晴朗":
		return _encounter_weather_effect(target_id, target_name, target_region)
	return {}

func _encounter_hidden_spot(target_id: String, target_name: String, target_region: Dictionary) -> Dictionary:
	var terrain := str(target_region.get("terrain", ""))
	var spot_types := {
		"mountain": "山腰处现一古拙石碑，碑文漫漶，似是前人留记。",
		"forest": "林深处有废弃药庐，墙角尚余几株草药。",
		"waterway": "水道转角藏着一座半塌的水神小庙。",
		"desert": "沙丘间露出半截石柱，依稀是丝路旧驿。",
		"cliff": "崖壁上凿有栈道残迹，可供歇脚远眺。",
		"plateau": "高原风口有一处牧人遗留的石圈。",
		"gorge": "峡谷深处有一方天然石台，避风遮雨。"
	}
	var note := str(spot_types.get(terrain, "道旁有一处不起眼的旧迹，值得一探。"))
	var discovery_title := "%s途遇旧迹" % target_name
	var herb_gain := randi_range(1, 2) if randf() < 0.5 else 0
	var money_gain := randi_range(3, 12) if herb_gain == 0 and randf() < 0.4 else 0
	var desc := note
	if herb_gain > 0:
		_state.add_item("item_yao", herb_gain)
		desc = "%s你细看之下，拾得草药×%d。" % [note, herb_gain]
	if money_gain > 0:
		_state.add_money(money_gain)
		desc = "%s石缝中藏有银两×%d。" % [note, money_gain]
	_state.append_world_event("travel_discovery", discovery_title, desc, target_id, 1)
	var toast := "%s" % discovery_title
	if herb_gain > 0:
		toast = "%s：草药+%d" % [discovery_title, herb_gain]
	elif money_gain > 0:
		toast = "%s：银两+%d" % [discovery_title, money_gain]
	return {
		"kind": "discovery",
		"title": discovery_title,
		"description": desc,
		"toast": toast
	}

func _encounter_wandering_npc(target_id: String, target_name: String, route_names: Array) -> Dictionary:
	var pass_name := str(route_names[maxi(0, route_names.size() / 2 - 1)]) if route_names.size() > 1 else target_name
	var npc_types := [
		{"title": "途经%s遇行商".replace("%s", pass_name), "desc": "一名行商正歇脚整理货担，见你经过，点头致意。", "money": randi_range(2, 8), "rep": 0},
		{"title": "途经%s遇游方郎中".replace("%s", pass_name), "desc": "一位游方郎中正在路边采药，顺手递给你一包草药。", "money": 0, "item": "item_yao", "item_count": 1},
		{"title": "途经%s遇江湖客".replace("%s", pass_name), "desc": "一名佩刀江湖客与你同行一段，聊起前方路况。", "money": 0, "rep": 0, "info": true}
	]
	var pick: Dictionary = npc_types[abs(hash("%s:%s:%d" % [target_id, pass_name, _state.day])) % npc_types.size()]
	var encounter_title := str(pick.get("title", "途遇路人"))
	var desc := str(pick.get("desc", ""))
	var toast := encounter_title
	var money_gain := int(pick.get("money", 0))
	if money_gain > 0:
		_state.add_money(money_gain)
		desc = "%s他递来银两×%d以作路资。" % [desc, money_gain]
		toast = "%s：银两+%d" % [encounter_title, money_gain]
	var item_id := str(pick.get("item", ""))
	if not item_id.is_empty():
		_state.add_item(item_id, int(pick.get("item_count", 1)))
		var item := GameData.get_item(item_id)
		var item_name := str(item.get("name", item_id))
		toast = "%s：%s+%d" % [encounter_title, item_name, int(pick.get("item_count", 1))]
	_state.append_world_event("travel_npc", encounter_title, desc, target_id, 1)
	return {
		"kind": "npc_encounter",
		"title": encounter_title,
		"description": desc,
		"toast": toast
	}

func _encounter_weather_effect(target_id: String, target_name: String, target_region: Dictionary) -> Dictionary:
	var weather: String = _state.weather
	var weather_effects := {
		"飞雪": {"title": "风雪阻路", "desc": "大雪封山，你不得不绕行避风，多耗了些时辰。", "delay": 0.5, "damage": 4},
		"细雨": {"title": "雨后路滑", "desc": "雨后泥泞难行，脚步放慢，好在无大碍。", "delay": 0.3, "damage": 0},
		"薄雾": {"title": "雾中迷途", "desc": "浓雾遮蔽方向，你走了些弯路才找到正道。", "delay": 0.4, "damage": 0},
		"阴霾": {"title": "天色阴沉", "desc": "阴云低垂令人心绪沉重，赶路时格外疲惫。", "delay": 0.2, "damage": 2}
	}
	var effect: Dictionary = weather_effects.get(weather, {"title": "天候影响", "desc": "天气变化影响了行程。", "delay": 0.3, "damage": 0})
	var weather_title := str(effect.get("title", "天候影响")) + "·" + target_name
	var desc := str(effect.get("desc", ""))
	var delay_hours := float(effect.get("delay", 0.3))
	if delay_hours > 0.0:
		_state.advance_hours(delay_hours)
	var damage := int(effect.get("damage", 0))
	var actual_damage := 0
	if damage > 0:
		var hp := int(_state.player.get("hp", 0))
		actual_damage = _state.damage_player(mini(damage, maxi(0, hp - 1)))
		desc = "%s气血损耗%d点。" % [desc, actual_damage]
	_state.append_world_event("travel_weather", weather_title, desc, target_id, 2)
	var toast := "%s" % weather_title
	if actual_damage > 0:
		toast = "%s：耽搁%.1f时辰，气血-%d" % [weather_title, delay_hours, actual_damage]
	else:
		toast = "%s：耽搁%.1f时辰" % [weather_title, delay_hours]
	return {
		"kind": "weather",
		"title": weather_title,
		"description": desc,
		"delay_hours": delay_hours,
		"damage": actual_damage,
		"toast": toast
	}

func _estimate_route_hours(route: Array[String], target_region: Dictionary) -> float:
	if target_region.is_empty():
		return 0.0
	var distance := TravelPlanner.route_distance(route, _state.current_tile)
	if distance <= 0.0:
		var source_region := _current_travel_source_region()
		distance = TravelPlanner.region_center_distance(source_region, target_region, _state.current_tile)
	var risk_level := _travel_risk_level(route, target_region)
	var relay_cost: float = maxf(0.0, float(route.size() - 2)) * 0.35
	var hours := clampf(distance / 7.5 + float(risk_level) * 0.45 + relay_cost, 1.0, 16.0)
	var familiarity_discount := _travel_familiarity_discount(target_region)
	if familiarity_discount > 0.0:
		hours = maxf(1.0, hours * (1.0 - familiarity_discount * 0.45))
	return roundf(hours * 2.0) / 2.0

func _estimate_route_fare(route: Array[String], target_region: Dictionary) -> int:
	if target_region.is_empty():
		return 0
	var hours := _estimate_route_hours(route, target_region)
	var risk_level := _travel_risk_level(route, target_region)
	var relay_count: int = maxi(0, route.size() - 2)
	var fare := int(round(hours * 1.6 + float(risk_level) * 2.0 + float(relay_count) * 1.5))
	var familiarity_discount := _travel_familiarity_discount(target_region)
	if familiarity_discount > 0.0:
		fare = int(round(float(fare) * (1.0 - familiarity_discount)))
	return maxi(_state.FAST_TRAVEL_MIN_FARE, fare)

func _travel_familiarity_discount(target_region: Dictionary) -> float:
	var exploration := _target_region_exploration(target_region)
	if exploration >= _state.FAST_TRAVEL_MASTER_EXPLORATION:
		return 0.25
	if exploration >= _state.FAST_TRAVEL_EXPERT_EXPLORATION:
		return 0.18
	if exploration >= _state.FAST_TRAVEL_FAMILIAR_EXPLORATION:
		return 0.10
	return 0.0

func _travel_familiarity_risk_reduction(target_region: Dictionary) -> int:
	var exploration := _target_region_exploration(target_region)
	if exploration >= _state.FAST_TRAVEL_EXPERT_EXPLORATION:
		return 1
	return 0

func _travel_familiarity_note(target_region: Dictionary) -> String:
	var exploration := _target_region_exploration(target_region)
	if exploration < _state.FAST_TRAVEL_FAMILIAR_EXPLORATION:
		return ""
	return "熟路加成：%s，驿路耗费和路况风险降低。" % _state.get_exploration_title_for_value(exploration)

func _target_region_exploration(target_region: Dictionary) -> int:
	var region_id := str(target_region.get("id", ""))
	if region_id.is_empty():
		return 0
	return _state.get_region_exploration(region_id)

func _travel_risk_level(route: Array[String], target_region: Dictionary) -> int:
	var risk_level := _route_risk_level(route)
	if route.is_empty():
		risk_level = int(target_region.get("danger", 1))
	var reduction := _travel_familiarity_risk_reduction(target_region)
	return clampi(risk_level - reduction, 1, 5)

func _route_risk_level(route: Array[String]) -> int:
	var risk := 1
	for region_id in route:
		var region := GameData.get_region(region_id)
		if region.is_empty():
			continue
		risk = maxi(risk, int(region.get("danger", 1)))
		var terrain := str(region.get("terrain", ""))
		if (_state.weather == "飞雪" and (terrain.contains("mountain") or terrain.contains("cliff") or terrain.contains("plateau"))) or (_state.weather == "细雨" and (terrain.contains("river") or terrain.contains("lake") or terrain.contains("marsh") or terrain.contains("gorge"))) or (_state.weather == "薄雾" and int(region.get("danger", 1)) >= 3):
			risk = maxi(risk, int(region.get("danger", 1)) + 1)
	return clampi(risk, 1, 5)

func _record_fast_travel_event(plan: Dictionary) -> void:
	var target_id := str(plan.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		return
	var target_name := str(target_region.get("name", target_id))
	var source_name: String = _state.current_region_name
	var source_region := GameData.get_region(str(plan.get("source_region_id", "")))
	if not source_region.is_empty():
		source_name = str(source_region.get("name", source_name))
	var route_summary := str(plan.get("route_summary", ""))
	var risk_note := str(plan.get("risk_note", ""))
	var fare := int(plan.get("fare", 0))
	var fare_text := "，花费%d两" % fare if fare > 0 else ""
	var description := "你从%s沿驿路赶到%s，用去%.1f时辰%s。" % [source_name, target_name, float(plan.get("hours", 0.0)), fare_text]
	if not route_summary.is_empty():
		description = "你按%s路线赶到%s，用去%.1f时辰%s。" % [route_summary, target_name, float(plan.get("hours", 0.0)), fare_text]
	if not risk_note.is_empty():
		description = "%s%s" % [description, risk_note]
	_state.append_world_event("travel", "驿路抵达%s" % target_name, description, target_id, clampi(int(plan.get("risk_level", 1)), 1, 3))
