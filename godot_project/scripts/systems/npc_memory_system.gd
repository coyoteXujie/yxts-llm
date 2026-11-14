extends RefCounted
class_name NpcMemorySystem

var _state: Node

const CORE_RUMOR_NPCS := [
	"苏梦瑶",
	"陈天行",
	"赵无极",
	"玄机子",
	"花如玉",
	"烈火",
	"蛇王",
	"太极真人",
	"冰魄",
	"逍遥子"
]

func _init(state: Node) -> void:
	_state = state

func get_npc_memory(npc_name: String) -> Dictionary:
	if npc_name.is_empty():
		return _default_npc_memory()
	var state: Dictionary = _state.npc_memory.get(npc_name, _default_npc_memory())
	return state.duplicate(true)

func get_npc_favor(npc_name: String) -> int:
	return int(get_npc_memory(npc_name).get("favor", 0))

func get_npc_relation_label(npc_name: String) -> String:
	var favor := get_npc_favor(npc_name)
	if favor <= -50:
		return "敌视"
	if favor < 0:
		return "疏远"
	if favor >= 90:
		return "挚友"
	if favor >= 70:
		return "知己"
	if favor >= 50:
		return "好友"
	if favor >= 30:
		return "朋友"
	if favor >= 10:
		return "认识"
	return "初识"

func record_npc_interaction(npc_data: Dictionary, kind: String) -> Dictionary:
	var npc_name := str(npc_data.get("name", ""))
	if npc_name.is_empty():
		return _default_npc_memory()
	var state := _ensure_npc_memory(npc_name)
	var favor_delta := _npc_favor_delta(npc_data, kind)
	if kind == "talk":
		var daily_talk_day := int(state.get("daily_talk_day", 0))
		var daily_talks := int(state.get("daily_talks", 0))
		if daily_talk_day != _state.day:
			daily_talk_day = _state.day
			daily_talks = 0
		if daily_talks >= 3:
			favor_delta = 0
		state["daily_talk_day"] = daily_talk_day
		state["daily_talks"] = daily_talks + 1
		state["talk_count"] = int(state.get("talk_count", 0)) + 1
	if kind == "teach":
		if int(state.get("daily_teach_day", 0)) == _state.day:
			favor_delta = 0
		else:
			state["daily_teach_day"] = _state.day
	if kind == "trade":
		if int(state.get("daily_trade_day", 0)) == _state.day:
			favor_delta = 0
		else:
			state["daily_trade_day"] = _state.day
	state["favor"] = clampi(int(state.get("favor", 0)) + favor_delta, -100, 100)
	state["last_day"] = _state.day
	_append_npc_memory(state, _npc_memory_label(kind, favor_delta))
	_state.npc_memory[npc_name] = state
	return state.duplicate(true)

func _apply_story_choice_memory(choice: Dictionary) -> void:
	var memory_line := str(choice.get("memory", ""))
	if memory_line.is_empty():
		return
	var npcs: Array = choice.get("npcs", [])
	for npc_name_value in npcs:
		var npc_name := str(npc_name_value)
		if npc_name.is_empty():
			continue
		var state := _ensure_npc_memory(npc_name)
		_append_npc_memory(state, memory_line)
		state["favor"] = clampi(int(state.get("favor", 0)) + 4, -100, 100)
		_state.npc_memory[npc_name] = state

func _default_npc_memory() -> Dictionary:
	return {
		"favor": 0,
		"talk_count": 0,
		"last_day": 0,
		"daily_talk_day": 0,
		"daily_talks": 0,
		"memories": []
	}

func _ensure_npc_memory(npc_name: String) -> Dictionary:
	if not _state.npc_memory.has(npc_name) or typeof(_state.npc_memory[npc_name]) != TYPE_DICTIONARY:
		_state.npc_memory[npc_name] = _default_npc_memory()
	var state: Dictionary = _state.npc_memory[npc_name]
	if not state.has("memories") or typeof(state["memories"]) != TYPE_ARRAY:
		state["memories"] = []
	for key in ["favor", "talk_count", "last_day", "daily_talk_day", "daily_talks"]:
		if not state.has(key):
			state[key] = 0
	return state

func _npc_favor_delta(npc_data: Dictionary, kind: String) -> int:
	var base := 0
	match kind:
		"talk":
			base = 1
		"teach":
			base = 1
		"quest_accept":
			base = 3
		"trade":
			base = 1
		"join":
			base = 8
		"rest":
			base = 1
		_:
			base = 0
	if base == 0:
		return 0
	var personality := str(npc_data.get("personality", ""))
	if kind == "talk":
		if personality.contains("善") or personality.contains("温") or personality.contains("热情") or personality.contains("活泼"):
			base += 1
		elif personality.contains("冷") or personality.contains("阴") or personality.contains("沉默") or personality.contains("多疑"):
			base = max(0, base - 1)
	if bool(npc_data.get("is_master", false)) or str(npc_data.get("npc_type", "")) == "master":
		base = max(1, base)
	return base

func _npc_memory_label(kind: String, favor_delta: int) -> String:
	var suffix := ""
	if favor_delta > 0:
		suffix = "，好感+%d" % favor_delta
	match kind:
		"talk":
			return "与你交谈%s" % suffix
		"teach":
			return "指点武学%s" % suffix
		"quest_accept":
			return "托付任务%s" % suffix
		"trade":
			return "与你交易%s" % suffix
		"join":
			return "收你入门%s" % suffix
		"rest":
			return "安排住店%s" % suffix
		_:
			return "记住了你的行动%s" % suffix

func _append_npc_memory(state: Dictionary, text: String) -> void:
	if text.is_empty():
		return
	var memories: Array = state.get("memories", [])
	var stamped: String = "第%d日：%s" % [_state.day, text]
	if memories.is_empty() or str(memories[memories.size() - 1]) != stamped:
		memories.append(stamped)
	while memories.size() > 6:
		memories.remove_at(0)
	state["memories"] = memories

func _spread_world_event_to_npc_memory(event: Dictionary) -> void:
	var severity := int(event.get("severity", 1))
	if severity < 2:
		return
	var title := str(event.get("title", ""))
	if title.is_empty():
		return
	var targets := _world_event_memory_targets(event)
	var region_name := str(event.get("region_name", ""))
	for npc_name in targets:
		if str(npc_name).is_empty():
			continue
		var state := _ensure_npc_memory(str(npc_name))
		var source := "%s：" % region_name if not region_name.is_empty() else ""
		_append_npc_memory(state, "听闻%s%s" % [source, title])
		_state.npc_memory[str(npc_name)] = state

func _world_event_memory_targets(event: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	var severity := int(event.get("severity", 1))
	if severity >= 4:
		for npc_name in CORE_RUMOR_NPCS:
			targets.append(str(npc_name))
		return targets
	var count := 3 if severity == 2 else 5
	var offset: int = abs(hash("%s:%s:%d" % [
		str(event.get("title", "")),
		str(event.get("region_id", "")),
		_state.day
	])) % CORE_RUMOR_NPCS.size()
	for index in range(count):
		targets.append(str(CORE_RUMOR_NPCS[(offset + index) % CORE_RUMOR_NPCS.size()]))
	return targets
