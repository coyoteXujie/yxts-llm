extends Control
class_name QuestPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var tabs: TabContainer
var summary_label: Label
var quest_text: RichTextLabel
var rumor_text: RichTextLabel
var relation_text: RichTextLabel
var quest_focus_button: Button
var clue_focus_button: Button
var clear_target_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.quests_changed.connect(_refresh)
	if not EventBus.world_events_changed.is_connected(_on_world_events_changed):
		EventBus.world_events_changed.connect(_on_world_events_changed)
	EventBus.map_target_changed.connect(func(_region_id: String) -> void:
		if visible:
			_refresh()
	)

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.JOURNAL)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -380
	panel.offset_top = -258
	panel.offset_right = 380
	panel.offset_bottom = 258
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(18, 14, 18, 14)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "任务日志"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	UI_ART.apply_label_shadow(title)
	box.add_child(title)

	summary_label = Label.new()
	summary_label.custom_minimum_size = Vector2(700, 48)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.64))
	UI_ART.apply_label_shadow(summary_label, 0.62)
	box.add_child(summary_label)

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(700, 342)
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

	quest_focus_button = Button.new()
	quest_focus_button.text = "标记任务目标"
	quest_focus_button.custom_minimum_size = Vector2(168, 38)
	UI_ART.apply_button(quest_focus_button)
	quest_focus_button.pressed.connect(_mark_active_quest_target)
	actions.add_child(quest_focus_button)

	clue_focus_button = Button.new()
	clue_focus_button.text = "标记线索目的地"
	clue_focus_button.custom_minimum_size = Vector2(168, 38)
	UI_ART.apply_button(clue_focus_button)
	clue_focus_button.pressed.connect(_mark_latest_adventure_clue_target)
	actions.add_child(clue_focus_button)

	clear_target_button = Button.new()
	clear_target_button.text = "清除目的地"
	clear_target_button.custom_minimum_size = Vector2(142, 38)
	UI_ART.apply_button(clear_target_button)
	clear_target_button.pressed.connect(_clear_map_target)
	actions.add_child(clear_target_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(120, 38)
	UI_ART.apply_button(close_button)
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
	if summary_label != null:
		summary_label.text = _quest_summary_text()
	quest_text.text = "\n".join(GameState.get_quest_status_lines())
	rumor_text.text = "\n".join(_world_event_lines())
	relation_text.text = "\n".join(_relation_lines())
	_refresh_quest_focus_button()
	_refresh_clue_focus_button()
	_refresh_clear_target_button()

func _quest_summary_text() -> String:
	var tracker := GameState.get_active_quest_tracker()
	var hint := GameState.get_active_story_quest_hint()
	var region_name := GameState.current_region_name
	if tracker.is_empty():
		tracker = "自由探索江湖"
	if hint.is_empty():
		hint = "下一步：打开地图寻找任务标记，或与附近 NPC 交谈。"
	var target_summary := GameState.get_map_target_summary()
	var target_text := "地图目的地：未标记" if target_summary.is_empty() else target_summary
	return "当前：%s\n%s  ·  所在地：%s\n%s" % [tracker, hint, region_name, target_text]

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
			var risk_label := str(record.get("risk_label", ""))
			var risk_suffix := "  %s" % risk_label if not risk_label.is_empty() else ""
			lines.append("第%d日  %s -> %s  %s x%d  利%d两  商誉+%d%s" % [
				int(record.get("day", GameState.day)),
				source_name,
				target_name,
				item_name,
				int(record.get("count", 1)),
				int(record.get("profit", 0)),
				int(record.get("reputation_gain", 0)),
				risk_suffix
			])
		lines.append("")
	lines.append("【江湖风声】")
	var events := GameState.get_recent_world_events(24)
	if events.is_empty():
		lines.append("暂无新的江湖传闻。")
		return lines

	# Group events by kind for better readability
	var story_events: Array[Dictionary] = []
	var quest_events: Array[Dictionary] = []
	var other_events: Array[Dictionary] = []
	for event in events:
		var kind := str(event.get("kind", ""))
		if kind == "story" or kind == "story_choice":
			story_events.append(event)
		elif kind == "quest":
			quest_events.append(event)
		else:
			other_events.append(event)

	var has_story := not story_events.is_empty()
	var has_quest := not quest_events.is_empty()
	var has_other := not other_events.is_empty()

	# Story events first (main thread)
	if has_story:
		if has_quest or has_other:
			lines.append("── 主线风声 ──")
		for event in story_events:
			lines.append(_format_world_event(event, true))
		if has_quest or has_other:
			lines.append("")

	# Quest events
	if has_quest:
		if has_story or has_other:
			lines.append("── 江湖轶事 ──")
		for event in quest_events:
			lines.append(_format_world_event(event, false))
		if has_story or has_other:
			lines.append("")

	# Other events (travel, market, seasonal, discovery)
	if has_other:
		if has_story or has_quest:
			lines.append("── 四方见闻 ──")
		for event in other_events:
			lines.append(_format_world_event(event, false))

	return lines

func _format_world_event(event: Dictionary, is_story: bool) -> String:
	var title := str(event.get("title", "传闻"))
	var description := str(event.get("description", ""))
	var region := str(event.get("region_name", ""))
	var region_prefix := "%s · " % region if not region.is_empty() else ""
	var day_str := "第%d日" % int(event.get("day", GameState.day))
	var line := "%s  %s%s" % [day_str, region_prefix, title]

	# Add more literary descriptions for key story events
	if is_story and not description.is_empty():
		line += "\n  %s" % _story_event_literary_touch(title, description)
	elif not description.is_empty():
		line += "\n  %s" % description
	return line

func _story_event_literary_touch(title: String, description: String) -> String:
	var enriched := {
		"平安镇初闻": "你在平安镇醒来，客栈檐角的铜铃在风里轻响。\n江湖风声还只是几句闲话，但暗处的影子已经动了。",
		"江湖初成": "神秘人败退时留下了一句话——「洛阳的旧火，烧了十五年还没灭。」\n洛阳旧案和暗影司的名字，第一次连在了一起。",
		"洛阳旧火重燃": "苏家旧宅遗址的焦木下，\n有人发现了一块刻着残月的玉佩。\n武林盟的旧卷不再安静，有人连夜翻开了泛黄的纸页。",
		"暗影书信现世": "两封密信被截获，信上的暗号与七派门规如出一辙。\n山门之间的信任，第一次有了裂纹。\n是谁在替暗影司传信？",
		"七派风声渐紧": "太极、雪山、逍遥都听见了暗处的脚步声。\n夜路开始不太平，有人在暗处说：\n「七派里，有暗影司的眼睛。」",
		"暗影眼线暴露": "黑衣大盗败退时，腰间掉下半截密令。\n暗影司藏在路上的眼睛，少了一只。",
		"断令归卷": "断令的花纹与武林盟旧卷的落款严丝合缝。\n七派夜议，终于有了拿得出手的证据。\n有人开始紧张了。",
		"武林夜议成局": description,
		"血月残印现世": "血月使者败退，暗影司的旧账里第一次露出一个名字——\n「无面主事」。没有人见过他的脸，\n但他留下的每一道残印，都指向同一条路。",
		"无面账册归卷": "无面君失手，苏家账册落入你手。\n账册最后一页画着一幅地形图——\n暗影司总坛的方位，终于浮出水面。",
		"影司总坛暂破": "暗影司影主败退，总坛暗道被七派合力封堵。\n江湖各派，终于有了短暂的喘息。\n但余烬未灭，暗处的火种还在燃烧。",
		"总坛余烬未灭": "苏梦瑶、陈天行与花间暗线开始清点暗影司残部。\n苏家旧账，终于能翻到最后几页了。",
		"旧案终册落印": "武林盟与七派共同落印，苏家旧案暂得收束。\n卷宗封面上多了一行小字：\n「此案见证者——%s。江湖有眼，公道在人心。」" % GameState.player.get("name", "无名少侠"),
		"江湖留灯": "你选择封存旧案。\n苏梦瑶在苏家旧宅的废墟上，点了一盏灯。\n她说：有些伤疤不必揭开，但要让后人记得这里曾经亮过。",
		"残影清剿": "你选择追剿到底。\n陈天行放下说书人的醒木，拿起了剑。\n他说：故事还没讲完——暗处的影子，一个都不能留。",
		"清算有度": "七派共同封存旧案，只清点首恶和铁证。\n几处被胁迫的暗线得以改过，\n江湖在这一夜，少了一场血雨腥风。",
		"追剿残影": "武林盟连夜清查暗影司残部，\n几条蛰伏多年的旧怨被翻到明面。\n有人在暗处说：旧案虽了，但新的账册，才刚刚翻开。"
	}
	if enriched.has(title):
		return enriched[title]
	return description

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
	var count := _market_delivery_count_for_item(item_id)
	var count_text := " x%d" % count if count > 1 else ""
	return "需带：%s%s%s（%s）" % [str(item.get("name", item_id)), count_text, target_text, resolved_text]

func _market_item_id_from_clue(clue_id: String) -> String:
	var item_pos := clue_id.find("item_")
	if item_pos < 0:
		return ""
	return clue_id.substr(item_pos)

func _market_delivery_count_for_item(item_id: String) -> int:
	if item_id.is_empty():
		return 0
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	var base_price := int(item.get("price", 18))
	if base_price <= 10:
		return 4
	if base_price <= 20:
		return 3
	if base_price <= 60:
		return 2
	return 1

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

func _refresh_clear_target_button() -> void:
	if clear_target_button == null:
		return
	var target_region_id := GameState.map_target_region_id
	if target_region_id.is_empty():
		clear_target_button.text = "清除目的地"
		clear_target_button.disabled = true
		clear_target_button.tooltip_text = "当前没有地图目的地"
		return
	var target_region := GameData.get_region(target_region_id)
	var target_name := str(target_region.get("name", target_region_id)) if not target_region.is_empty() else target_region_id
	clear_target_button.text = "清除：%s" % target_name
	clear_target_button.disabled = false
	clear_target_button.tooltip_text = "清除当前地图目的地"

func _refresh_quest_focus_button() -> void:
	if quest_focus_button == null:
		return
	var region := GameState.get_active_quest_target_region()
	if region.is_empty():
		quest_focus_button.text = "标记任务目标"
		quest_focus_button.disabled = true
		quest_focus_button.tooltip_text = "当前任务暂无可标记区域"
		return
	var region_name := str(region.get("name", region.get("id", "目标")))
	quest_focus_button.text = "任务：%s" % region_name
	quest_focus_button.disabled = false
	var target_label := GameState.get_active_quest_target_label()
	quest_focus_button.tooltip_text = "把%s标记到世界地图" % target_label if not target_label.is_empty() else "把当前任务目标标记到世界地图"

func _mark_active_quest_target() -> void:
	var region := GameState.get_active_quest_target_region()
	if region.is_empty():
		EventBus.emit_toast("当前任务暂无可标记区域")
		_refresh_quest_focus_button()
		return
	var region_id := str(region.get("id", ""))
	var region_name := str(region.get("name", region_id))
	GameState.set_map_target_region(region_id)
	EventBus.emit_toast("已标记任务目标：%s" % region_name)
	_refresh_quest_focus_button()
	_refresh_clear_target_button()

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
	_refresh_clear_target_button()

func _clear_map_target() -> void:
	if GameState.map_target_region_id.is_empty():
		EventBus.emit_toast("当前没有地图目的地")
		_refresh_clear_target_button()
		return
	GameState.set_map_target_region("")
	EventBus.emit_toast("已清除地图目的地")
	_refresh_clear_target_button()

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


