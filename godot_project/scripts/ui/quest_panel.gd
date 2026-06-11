extends Control
class_name QuestPanel

var tabs: TabContainer
var quest_text: RichTextLabel
var rumor_text: RichTextLabel
var relation_text: RichTextLabel
var clue_focus_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.quests_changed.connect(_refresh)
	if not EventBus.world_events_changed.is_connected(_on_world_events_changed):
		EventBus.world_events_changed.connect(_on_world_events_changed)

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.JOURNAL)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(214, 92)
	panel.size = Vector2(760, 516)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "任务日志"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title)

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(700, 390)
	box.add_child(tabs)

	quest_text = _make_text_tab("任务")
	tabs.add_child(quest_text)
	rumor_text = _make_text_tab("江湖")
	tabs.add_child(rumor_text)
	relation_text = _make_text_tab("人物")
	tabs.add_child(relation_text)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	clue_focus_button = Button.new()
	clue_focus_button.text = "标记线索目的地"
	clue_focus_button.custom_minimum_size = Vector2(168, 38)
	clue_focus_button.pressed.connect(_mark_latest_adventure_clue_target)
	actions.add_child(clue_focus_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(120, 38)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _make_text_tab(tab_name: String) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.name = tab_name
	text.custom_minimum_size = Vector2(700, 360)
	text.fit_content = false
	text.bbcode_enabled = false
	text.add_theme_font_size_override("normal_font_size", 17)
	return text

func _refresh() -> void:
	if quest_text == null:
		return
	quest_text.text = "\n".join(GameState.get_quest_status_lines())
	rumor_text.text = "\n".join(_world_event_lines())
	relation_text.text = "\n".join(_relation_lines())
	_refresh_clue_focus_button()

func _on_world_events_changed(_events: Array) -> void:
	if visible:
		_refresh()

func _world_event_lines() -> Array[String]:
	var lines: Array[String] = []
	var clues := GameState.get_adventure_clues(8)
	if not clues.is_empty():
		lines.append("【奇遇线索】")
		for clue in clues:
			var clue_entry: Dictionary = clue
			var clue_region := str(clue_entry.get("region_name", ""))
			var clue_region_prefix := "%s · " % clue_region if not clue_region.is_empty() else ""
			var target_region := str(clue_entry.get("target_region_name", ""))
			var target_suffix := "（指向：%s）" % target_region if not target_region.is_empty() else ""
			var resolved_suffix := "（已追到）" if bool(clue_entry.get("resolved", false)) else ""
			lines.append("第%d日  %s%s%s%s" % [int(clue_entry.get("day", GameState.day)), clue_region_prefix, str(clue_entry.get("title", "未名线索")), target_suffix, resolved_suffix])
			var clue_description := str(clue_entry.get("description", ""))
			if not clue_description.is_empty():
				lines.append("  %s" % clue_description)
			var delivery_hint := _clue_delivery_hint(clue_entry)
			if not delivery_hint.is_empty():
				lines.append("  %s" % delivery_hint)
		lines.append("")
	var trade_records := GameState.get_trade_records(5)
	if not trade_records.is_empty():
		lines.append("【跑商履历】")
		lines.append("商誉：%s（%d）" % [GameState.get_trade_reputation_title(), GameState.trade_reputation])
		for trade_record in trade_records:
			var record: Dictionary = trade_record
			var source_name := str(record.get("source_region_name", "来路"))
			var target_name := str(record.get("target_region_name", "目的地"))
			var item_name := str(record.get("item_name", "货物"))
			lines.append("第%d日  %s -> %s  %s x%d  利%d两  商誉+%d" % [
				int(record.get("day", GameState.day)),
				source_name,
				target_name,
				item_name,
				int(record.get("count", 1)),
				int(record.get("profit", 0)),
				int(record.get("reputation_gain", 0))
			])
		lines.append("")
	lines.append("【江湖风声】")
	var events := GameState.get_recent_world_events(12)
	if events.is_empty():
		lines.append("暂无新的江湖传闻。")
		return lines
	for event in events:
		var entry: Dictionary = event
		var title := str(entry.get("title", "传闻"))
		var description := str(entry.get("description", ""))
		var region := str(entry.get("region_name", ""))
		var region_prefix := "%s · " % region if not region.is_empty() else ""
		lines.append("第%d日  %s%s" % [int(entry.get("day", GameState.day)), region_prefix, title])
		if not description.is_empty():
			lines.append("  %s" % description)
	return lines

func _clue_delivery_hint(clue: Dictionary) -> String:
	if str(clue.get("source", "")) != "market":
		return ""
	var item_id := _market_item_id_from_clue(str(clue.get("id", "")))
	if item_id.is_empty():
		return ""
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return ""
	var target_region := str(clue.get("target_region_name", ""))
	var target_text := "，前往%s交割" % target_region if not target_region.is_empty() else ""
	var resolved_text := "已交割" if bool(clue.get("resolved", false)) else "待交割"
	return "需带：%s%s（%s）" % [str(item.get("name", item_id)), target_text, resolved_text]

func _market_item_id_from_clue(clue_id: String) -> String:
	var item_pos := clue_id.find("item_")
	if item_pos < 0:
		return ""
	return clue_id.substr(item_pos)

func _latest_adventure_clue_with_target() -> Dictionary:
	var clues := GameState.get_adventure_clues(0)
	for index in range(clues.size() - 1, -1, -1):
		var clue: Dictionary = clues[index]
		if bool(clue.get("resolved", false)):
			continue
		var target_region_id := str(clue.get("target_region_id", ""))
		if not target_region_id.is_empty() and not GameData.get_region(target_region_id).is_empty():
			return clue
	return {}

func _refresh_clue_focus_button() -> void:
	if clue_focus_button == null:
		return
	var clue := _latest_adventure_clue_with_target()
	if clue.is_empty():
		clue_focus_button.text = "标记线索目的地"
		clue_focus_button.disabled = true
		clue_focus_button.tooltip_text = "暂无带目标区域的奇遇线索"
		return
	var target_region_name := str(clue.get("target_region_name", ""))
	if target_region_name.is_empty():
		target_region_name = str(GameData.get_region(str(clue.get("target_region_id", ""))).get("name", "目的地"))
	clue_focus_button.text = "标记：%s" % target_region_name
	clue_focus_button.disabled = false
	clue_focus_button.tooltip_text = "把最近奇遇线索标记到世界地图"

func _mark_latest_adventure_clue_target() -> void:
	var clue := _latest_adventure_clue_with_target()
	if clue.is_empty():
		EventBus.emit_toast("暂无可标记的奇遇线索")
		_refresh_clue_focus_button()
		return
	var target_region_id := str(clue.get("target_region_id", ""))
	var target_region_name := str(clue.get("target_region_name", ""))
	if target_region_name.is_empty():
		target_region_name = str(GameData.get_region(target_region_id).get("name", target_region_id))
	GameState.set_map_target_region(target_region_id)
	EventBus.emit_toast("已标记奇遇目的地：%s" % target_region_name)
	_refresh_clue_focus_button()

func _relation_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("【人物关系】")
	var names: Array = GameState.CORE_RUMOR_NPCS
	for npc_name_value in names:
		var npc_name := str(npc_name_value)
		var npc := GameData.get_npc_by_name(npc_name)
		if npc.is_empty():
			continue
		var memory := GameState.get_npc_memory(npc_name)
		var relation := GameState.get_npc_relation_label(npc_name)
		var favor := int(memory.get("favor", 0))
		var favor_text := "%d" % favor
		if favor >= 0:
			favor_text = "+%d" % favor
		var faction := GameData.get_faction_name(str(npc.get("faction", "none")))
		lines.append("%s  ·  %s  ·  %s %s" % [npc_name, faction, relation, favor_text])
		var memories: Array = memory.get("memories", [])
		if memories.is_empty():
			lines.append("  暂无特别记忆。")
		else:
			var start: int = max(0, memories.size() - 2)
			for index in range(start, memories.size()):
				lines.append("  %s" % str(memories[index]))
	return lines

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.068, 0.052, 0.95)
	style.border_color = Color(0.58, 0.46, 0.26, 0.86)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
