extends RefCounted
class_name WorldState

## 世界状态管理系统
##
## 功能：
## 1. 追踪区域状态（被摧毁/修复/封锁等）
## 2. 任务完成后区域产生永久变化
## 3. NPC 出现/消失基于剧情阶段
## 4. 世界时钟——特定时间触发事件

var _state: Node

func _init(state: Node) -> void:
	_state = state


# ============================================================
# 1. 区域状态管理
# ============================================================

## 获取区域完整状态
func get_region_state(region_id: String) -> Dictionary:
	return _state.get_region_state(region_id)


## 设置区域自定义状态字段
func set_region_state_field(region_id: String, key: String, value: Variant) -> void:
	if region_id.is_empty() or key.is_empty():
		return
	var state: Dictionary = _ensure_region_state(region_id)
	state[key] = value
	_state.region_state[region_id] = state


## 区域是否被封锁
func is_region_blocked(region_id: String) -> bool:
	var state: Dictionary = _state.get_region_state(region_id)
	return bool(state.get("blocked", false))


## 封锁/解锁区域
func set_region_blocked(region_id: String, blocked: bool, reason: String = "") -> void:
	if region_id.is_empty():
		return
	var state: Dictionary = _ensure_region_state(region_id)
	state["blocked"] = blocked
	if blocked and not reason.is_empty():
		state["block_reason"] = reason
	elif not blocked:
		state.erase("block_reason")
	_state.region_state[region_id] = state
	if blocked:
		_state.append_world_event("region_change", "区域封锁", "%s已被封锁。%s" % [_get_region_name(region_id), reason], region_id, 3)
	else:
		_state.append_world_event("region_change", "区域解封", "%s已恢复正常通行。" % _get_region_name(region_id), region_id, 2)


## 标记区域为已摧毁
func devastate_region(region_id: String, reason: String = "") -> void:
	if region_id.is_empty():
		return
	var state: Dictionary = _ensure_region_state(region_id)
	state["devastated"] = true
	state["blocked"] = true
	state["block_reason"] = "该区域已遭破坏，无法通行。"
	_state.region_state[region_id] = state
	var name_string: String = _get_region_name(region_id)
	_state.append_world_event("cataclysm", "%s被毁" % name_string, "%s遭遇大劫。%s" % [name_string, reason], region_id, 5)
	EventBus.emit_toast("噩耗：%s被毁！" % name_string)


## 修复已被摧毁的区域
func restore_region(region_id: String, new_description: String = "") -> void:
	if region_id.is_empty():
		return
	var state: Dictionary = _ensure_region_state(region_id)
	state["devastated"] = false
	state["blocked"] = false
	state.erase("block_reason")
	state["restored"] = true
	if not new_description.is_empty():
		state["restored_description"] = new_description
	_state.region_state[region_id] = state
	var name_string: String = _get_region_name(region_id)
	_state.append_world_event("region_change", "%s重建" % name_string, "%s在各方努力下开始重建。" % name_string, region_id, 3)


## 获取区域描述（含剧情变更）
func get_region_description(region_id: String) -> String:
	var region: Dictionary = GameData.get_region(region_id)
	if region.is_empty():
		return "未知之地"
	var base: String = str(region.get("description", ""))
	var state: Dictionary = _state.get_region_state(region_id)
	if state.is_empty():
		return base
	if bool(state.get("devastated", false)):
		return "此处已是一片废墟，昔日的繁华荡然无存。"
	if bool(state.get("blocked", false)):
		return "此路不通。" + str(state.get("block_reason", ""))
	if bool(state.get("restored", false)):
		var restored_string: String = str(state.get("restored_description", ""))
		if not restored_string.is_empty():
			return restored_string
	var mood_string: String = str(state.get("mood", ""))
	if not mood_string.is_empty():
		return "%s（现况：%s）" % [base, mood_string]
	return base


# ============================================================
# 2. NPC 存在管理
# ============================================================

## NPC 是否在当前剧情阶段可见
func is_npc_visible(npc_name: String) -> bool:
	if npc_name.is_empty():
		return false
	var npc: Dictionary = GameData.get_npc_by_name(npc_name)
	if npc.is_empty():
		return false
	var appears_after: Array = npc.get("appears_after", [])
	for flag in appears_after:
		if not bool(_state.game_flags.get(str(flag), false)):
			return false
	var disappears_after: Array = npc.get("disappears_after", [])
	for flag in disappears_after:
		if bool(_state.game_flags.get(str(flag), false)):
			return false
	return true


## 势力是否可见（势力全灭/解散）
func is_faction_active(faction_id: String) -> bool:
	if faction_id.is_empty():
		return true
	return not bool(_state.game_flags.get("faction_%s_destroyed" % faction_id, false))


## 标记势力已灭
func destroy_faction(faction_id: String) -> void:
	if faction_id.is_empty():
		return
	_state.game_flags["faction_%s_destroyed" % faction_id] = true
	var name_string: String = GameData.get_faction_name(faction_id)
	_state.append_world_event("faction", "%s覆灭" % name_string, "%s已在江湖中烟消云散，其势力范围将逐渐被其他势力接管。" % name_string, "", 5)
	EventBus.emit_toast("江湖剧变：%s覆灭！" % name_string)


## 获取当前区域活跃 NPC 列表
func get_active_npcs_for_region(region_id: String) -> Array[Dictionary]:
	if region_id.is_empty():
		return []
	var result: Array[Dictionary] = []
	for npc in GameData.get_npcs():
		if typeof(npc) != TYPE_DICTIONARY:
			continue
		var npc_region_string: String = _get_npc_region(npc)
		if npc_region_string != region_id:
			continue
		if is_npc_visible(str(npc.get("name", ""))):
			result.append(npc)
	return result


# ============================================================
# 3. 任务完成后的世界变化
# ============================================================

## 任务完成回调
func on_quest_completed(quest_id: String) -> void:
	if quest_id.is_empty():
		return
	match quest_id:
		"q_clear_thugs":
			set_region_state_field("qinghe", "safety", "improved")
			_state.append_world_event("world_change", "平安镇安靖", "镇东恶徒被清剿后，平安镇的百姓终于敢在夜间出门了。", "qinghe", 2)
		"q_main_shadow_citadel":
			_state.append_world_event("world_change", "暗影势力消退", "暗影司总坛覆灭的消息传遍江湖，各地暗桩纷纷撤离。长安城的暗处比从前干净了许多。", "changan", 4)
			set_region_state_field("changan", "shadow_activity", "collapsed")
		"q_west_treasure_4":
			set_region_state_field("west_region", "trade_route", "revived" if "west_region" in _state.region_state else "open")
			_state.append_world_event("world_change", "西域商路重开", "沙漠之心的谜题解开后，西域商路重新焕发生机。", "west_region", 3)
		"q_main_old_case_closure":
			set_region_state_field("luoyang", "mood", "安宁")
			_state.append_world_event("world_change", "洛阳安靖", "旧案终册落印后，洛阳城气氛明显舒缓。", "luoyang", 4)
			EventBus.emit_toast("历史被改写：洛阳旧案终于结案！")


# ============================================================
# 4. 世界时钟
# ============================================================

## 世界时钟推进（每小时调用一次）
func advance_world_clock(hours_passed: float) -> void:
	var old_day: int = _state.day
	var old_hour: float = _state.hour
	_state.hour += hours_passed
	while _state.hour >= 24.0:
		_state.hour -= 24.0
		_state.day += 1
	_on_time_change(old_day, old_hour, _state.day, _state.hour)


func _on_time_change(old_day: int, old_hour: float, new_day: int, new_hour: float) -> void:
	var current_hour: int = int(floor(new_hour))
	var old_hour_int: int = int(floor(old_hour))
	
	if current_hour == old_hour_int:
		return
	
	if current_hour == 23:
		_state.append_world_event("time", "夜色已深", "夜深了，街上的行人和酒客逐渐散去。", _state.current_region_id, 1)
	
	if current_hour == 5:
		_state.append_world_event("time", "黎明破晓", "东方既白，早市的摊贩开始摆出货物。", _state.current_region_id, 1)
	
	if current_hour == 12:
		_state.append_world_event("time", "日正中天", "正午的阳光下，江湖看起来比夜晚简单了许多。", _state.current_region_id, 1)
	
	_check_time_events(new_day, new_hour)


## 时间触发事件
func _check_time_events(day: int, hour: float) -> void:
	var current_hour: int = int(floor(hour))
	
	if day == 3 and current_hour == 20 and not bool(_state.game_flags.get("time_event_day3_mystery", false)):
		_state.game_flags["time_event_day3_mystery"] = true
		_state.record_adventure_clue("", "夜行人的邀约", "有人在平安镇客栈留了一封信，约你去镇外老槐树下见面。", "qinghe", "夜行人", "qinghe")
		EventBus.emit_toast("客栈桌上多了一封信...")
	
	if day == 7 and current_hour == 0 and not bool(_state.game_flags.get("time_event_day7_messenger", false)):
		if _state.current_region_id == "luoyang" or _state.current_region_id == "qinghe":
			_state.game_flags["time_event_day7_messenger"] = true
			_state.append_world_event("time", "暗影信使", "午夜时分，一个黑影在洛阳城头一闪而过。", "luoyang", 2)
	
	if day == 15 and current_hour == 6 and not bool(_state.game_flags.get("time_event_day15_omen", false)):
		if _state.completed_quests.has("q_main_broken_token"):
			_state.game_flags["time_event_day15_omen"] = true
			_state.append_world_event("time", "血月之兆", "清晨的天色异样地红，老农说这是血月将至的征兆。", _state.current_region_id, 3)


# ============================================================
# 5. 区域天气/氛围变化
# ============================================================

## 获取区域当前氛围描述
func get_region_atmosphere(region_id: String) -> String:
	if region_id.is_empty():
		return ""
	var state: Dictionary = _state.get_region_state(region_id)
	if state.is_empty():
		return ""
	var safety_string: String = str(state.get("safety", ""))
	var mood_string: String = str(state.get("mood", ""))
	var shadow_string: String = str(state.get("shadow_activity", ""))
	var parts: Array[String] = []
	if not mood_string.is_empty():
		parts.append("氛围：" + mood_string)
	if safety_string == "improved":
		parts.append("治安好转")
	elif safety_string == "dangerous":
		parts.append("危险区域")
	if shadow_string == "collapsed":
		parts.append("暗影势力消退")
	elif shadow_string == "active":
		parts.append("暗影活动频繁")
	if parts.is_empty():
		return ""
	return " | ".join(parts)


# ============================================================
# 6. 辅助方法
# ============================================================

func _ensure_region_state(region_id: String) -> Dictionary:
	if not _state.region_state.has(region_id):
		_state.region_state[region_id] = {"discovered": false, "exploration": 5, "visited": [], "exploration_milestones": []}
	var state: Dictionary = _state.region_state[region_id]
	return state


func _get_region_name(region_id: String) -> String:
	var region: Dictionary = GameData.get_region(region_id)
	return str(region.get("name", region_id))


func _get_npc_region(npc: Dictionary) -> String:
	var pos_x: int = int(npc.get("pos_x", -1))
	var pos_y: int = int(npc.get("pos_y", -1))
	if pos_x < 0 or pos_y < 0:
		return ""
	var tile: Vector2i = Vector2i(pos_x, pos_y)
	return str(GameData.get_region_at_tile(tile).get("id", ""))
