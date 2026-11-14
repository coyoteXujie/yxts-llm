extends Control
class_name WorldMapPanel

const MAP_CANVAS_SCRIPT := preload("res://scripts/ui/region_map_canvas.gd")
const UI_ART := preload("res://scripts/ui/ui_art.gd")
const REGION_FILTERS := [
	{"id": "all", "label": "全部", "tooltip": "显示所有已记录区域"},
	{"id": "settlement", "label": "城镇", "tooltip": "只显示城池和小镇"},
	{"id": "sect", "label": "门派", "tooltip": "只显示门派驻地"},
	{"id": "wild", "label": "野外", "tooltip": "只显示山林、水路和险地"},
	{"id": "interest", "label": "线索", "tooltip": "只显示任务、目的地或关键人物相关区域"}
]

signal focus_region_requested(region_id: String)
signal fast_travel_requested(region_id: String)
signal clear_target_requested()

var region_list: ItemList
var target_summary_label: Label
var scene_texture: TextureRect
var scene_caption: Label
var details: RichTextLabel
var map_canvas
var focus_button: Button
var travel_button: Button
var clear_target_button: Button
var filter_buttons: Dictionary = {}
var region_ids: Array[String] = []
var selected_region_id := ""
var active_region_filter := "all"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.region_changed.connect(func(_region: Dictionary, _state: Dictionary) -> void: _refresh())
	EventBus.map_target_changed.connect(func(_region_id: String) -> void: _refresh())

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.MAP)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(110, 58)
	panel.size = Vector2(1060, 594)
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(18, 16, 18, 16)))
	add_child(panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	panel.add_child(root)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 530)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)

	var title := Label.new()
	title.text = "江湖舆图"
	UI_ART.apply_title(title)
	left.add_child(title)

	target_summary_label = Label.new()
	target_summary_label.custom_minimum_size = Vector2(300, 42)
	target_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(target_summary_label, 14)
	left.add_child(target_summary_label)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 5)
	left.add_child(filter_row)
	for filter_data in REGION_FILTERS:
		var filter_id := str(filter_data.get("id", "all"))
		var button := Button.new()
		button.text = str(filter_data.get("label", filter_id))
		button.tooltip_text = str(filter_data.get("tooltip", ""))
		button.toggle_mode = true
		button.clip_text = true
		button.custom_minimum_size = Vector2(54, 30)
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_set_region_filter.bind(filter_id))
		UI_ART.apply_button(button)
		filter_buttons[filter_id] = button
		filter_row.add_child(button)

	region_list = ItemList.new()
	region_list.custom_minimum_size = Vector2(300, 363)
	region_list.item_selected.connect(_select_region)
	region_list.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(8, 8, 8, 8)))
	region_list.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	region_list.add_theme_color_override("font_selected_color", Color(1.0, 0.88, 0.50))
	left.add_child(region_list)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(682, 530)
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	map_canvas = MAP_CANVAS_SCRIPT.new()
	map_canvas.region_clicked.connect(_select_region_by_id)
	right.add_child(map_canvas)

	var info_row := HBoxContainer.new()
	info_row.custom_minimum_size = Vector2(660, 126)
	info_row.add_theme_constant_override("separation", 12)
	right.add_child(info_row)

	var scene_frame := PanelContainer.new()
	scene_frame.custom_minimum_size = Vector2(224, 124)
	scene_frame.add_theme_stylebox_override("panel", _scene_style())
	info_row.add_child(scene_frame)

	var scene_box := VBoxContainer.new()
	scene_box.add_theme_constant_override("separation", 4)
	scene_frame.add_child(scene_box)

	scene_texture = TextureRect.new()
	scene_texture.custom_minimum_size = Vector2(208, 88)
	scene_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_box.add_child(scene_texture)

	scene_caption = Label.new()
	scene_caption.text = "区域景象"
	scene_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_caption.add_theme_font_size_override("font_size", 13)
	scene_caption.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58))
	scene_box.add_child(scene_caption)

	details = RichTextLabel.new()
	details.custom_minimum_size = Vector2(424, 124)
	details.fit_content = false
	details.bbcode_enabled = false
	details.add_theme_font_size_override("normal_font_size", 16)
	details.add_theme_color_override("default_color", Color(0.90, 0.86, 0.76))
	info_row.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	right.add_child(actions)

	focus_button = Button.new()
	focus_button.text = "标记目的地"
	focus_button.custom_minimum_size = Vector2(132, 36)
	focus_button.pressed.connect(_request_focus_region)
	UI_ART.apply_button(focus_button)
	actions.add_child(focus_button)

	travel_button = Button.new()
	travel_button.text = "快速前往"
	travel_button.custom_minimum_size = Vector2(132, 36)
	travel_button.pressed.connect(_request_fast_travel)
	UI_ART.apply_button(travel_button)
	actions.add_child(travel_button)

	clear_target_button = Button.new()
	clear_target_button.text = "清除目的地"
	clear_target_button.custom_minimum_size = Vector2(132, 36)
	clear_target_button.pressed.connect(_request_clear_target)
	UI_ART.apply_button(clear_target_button)
	actions.add_child(clear_target_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(118, 36)
	close_button.pressed.connect(close_panel)
	UI_ART.apply_button(close_button)
	actions.add_child(close_button)

func _refresh() -> void:
	if region_list == null:
		return
	_refresh_target_summary_label()
	_update_filter_buttons()
	var selected_id := selected_region_id
	if selected_id.is_empty() and not GameState.map_target_region_id.is_empty():
		selected_id = GameState.map_target_region_id
	if selected_id.is_empty() and map_canvas != null:
		selected_id = str(map_canvas.selected_region_id)
	if selected_id.is_empty():
		selected_id = GameState.current_region_id
	region_list.clear()
	region_ids.clear()
	for region in GameData.get_regions():
		var region_id := str(region.get("id", ""))
		if not _region_matches_filter(region_id, region):
			continue
		region_ids.append(region_id)
		var discovered := GameState.is_region_discovered(region_id)
		var type_name := _type_name(str(region.get("type", "wild")))
		var text := "???  [%s]" % type_name
		if discovered:
			text = "%s  %d%%  [%s]" % [
				str(region.get("name", region_id)),
				GameState.get_region_exploration(region_id),
				type_name
			]
		region_list.add_item(text)
		if region_id == selected_id:
			region_list.select(region_ids.size() - 1)
	if region_ids.is_empty():
		selected_region_id = ""
		details.text = "没有符合当前筛选的区域。"
		_set_scene_background("", "区域景象")
		_set_route_plan({})
		_update_action_buttons("")
		return
	if selected_id.is_empty() or not region_ids.has(selected_id):
		selected_id = region_ids[0]
	if selected_id.is_empty():
		selected_id = GameState.current_region_id
	_select_region_by_id(selected_id)
	if map_canvas != null:
		map_canvas.queue_redraw()

func _select_region(index: int) -> void:
	if index < 0 or index >= region_ids.size():
		return
	_select_region_by_id(region_ids[index])

func _select_region_by_id(region_id: String) -> void:
	selected_region_id = region_id
	if region_id.is_empty():
		details.text = "尚未发现区域。"
		_set_scene_background("", "区域景象")
		_set_route_plan({})
		_update_action_buttons("")
		return
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return
	var discovered := GameState.is_region_discovered(region_id)
	if map_canvas != null:
		map_canvas.set_selected_region(region_id)
	_select_region_list_item(region_id)
	if not discovered:
		details.text = "未知区域\n继续探索世界后，区域名称、地貌和危险等级会逐步显现。"
		_set_scene_background("", "尚未发现")
		_set_route_plan({})
		_update_action_buttons(region_id)
		return
	var danger := int(region.get("danger", 0))
	var state := GameState.get_region_state(region_id)
	var extra := _region_detail_lines(region_id)
	var exploration := int(state.get("exploration", 0))
	var exploration_title := GameState.get_exploration_title_for_value(exploration)
	details.text = "%s\n类型：%s    危险：%s    探索：%d%%·%s\n%s%s" % [
		str(region.get("name", region_id)),
		_type_name(str(region.get("type", "wild"))),
		_danger_name(danger),
		exploration,
		exploration_title,
		str(region.get("description", "")),
		extra
	]
	_set_scene_background(region_id, str(region.get("name", region_id)))
	_set_route_plan(GameState.build_region_travel_plan(region_id))
	_update_action_buttons(region_id)

func _set_region_filter(filter_id: String) -> void:
	if not _is_valid_filter(filter_id):
		filter_id = "all"
	if active_region_filter == filter_id:
		_update_filter_buttons()
		return
	active_region_filter = filter_id
	selected_region_id = ""
	_refresh()

func _is_valid_filter(filter_id: String) -> bool:
	for filter_data in REGION_FILTERS:
		if str(filter_data.get("id", "")) == filter_id:
			return true
	return false

func _update_filter_buttons() -> void:
	for filter_id in filter_buttons.keys():
		var button := filter_buttons[filter_id] as Button
		if button == null:
			continue
		button.button_pressed = str(filter_id) == active_region_filter

func _region_matches_filter(region_id: String, region: Dictionary) -> bool:
	match active_region_filter:
		"settlement":
			return ["city", "town"].has(str(region.get("type", "wild")))
		"sect":
			return str(region.get("type", "wild")) == "sect"
		"wild":
			return not ["city", "town", "sect"].has(str(region.get("type", "wild")))
		"interest":
			return _region_has_interest(region_id)
	return true

func _region_has_interest(region_id: String) -> bool:
	if region_id.is_empty():
		return false
	if region_id == GameState.map_target_region_id:
		return true
	for entry in GameState.get_active_quest_target_entries():
		if str((entry as Dictionary).get("region_id", "")) == region_id:
			return true
	for npc in GameData.get_npcs():
		if not bool(npc.get("has_quests", false)) and not bool(npc.get("is_master", false)):
			continue
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		var npc_region := GameData.get_region_at_tile(tile)
		if str(npc_region.get("id", "")) == region_id:
			return true
	return false

func _select_region_list_item(region_id: String) -> void:
	if region_list == null:
		return
	for index in range(region_ids.size()):
		if region_ids[index] == region_id:
			region_list.select(index)
			region_list.ensure_current_is_visible()
			return

func _region_detail_lines(region_id: String) -> String:
	var npc_names: Array[String] = []
	var quest_names: Array[String] = []
	for npc in GameData.get_npcs():
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		var region := GameData.get_region_at_tile(tile)
		if str(region.get("id", "")) != region_id:
			continue
		if bool(npc.get("has_quests", false)) or bool(npc.get("is_master", false)):
			npc_names.append(str(npc.get("name", "")))
	for quest in GameData.get_available_quests():
		var quest_id := str(quest.get("id", ""))
		if GameState.completed_quests.has(quest_id):
			continue
		var giver := GameData.get_npc_by_name(str(quest.get("giver", "")))
		if giver.is_empty():
			continue
		var giver_region := GameData.get_region_at_tile(Vector2i(int(giver.get("pos_x", -1)), int(giver.get("pos_y", -1))))
		if str(giver_region.get("id", "")) == region_id:
			quest_names.append(str(quest.get("title", quest_id)))
	var lines: Array[String] = []
	if not npc_names.is_empty():
		lines.append("要人：%s" % "、".join(npc_names.slice(0, 6)))
	if not quest_names.is_empty():
		lines.append("线索：%s" % "、".join(quest_names.slice(0, 4)))
	var travel_line := _fast_travel_line(region_id)
	if not travel_line.is_empty():
		lines.append(travel_line)
	if lines.is_empty():
		return ""
	return "\n" + "\n".join(lines)

func _fast_travel_line(region_id: String) -> String:
	var plan := GameState.build_region_travel_plan(region_id)
	var reason := str(plan.get("blocked_reason", ""))
	var route_summary := str(plan.get("route_summary", ""))
	var risk_label := str(plan.get("risk_label", ""))
	var fare := int(plan.get("fare", 0))
	var familiarity_note := str(plan.get("familiarity_note", ""))
	var note_suffix := " %s" % familiarity_note if not familiarity_note.is_empty() else ""
	if reason.is_empty():
		return "驿路：可快速前往，约 %.1f 时辰，%d 两，%s。路线：%s。%s" % [
			float(plan.get("hours", 0.0)),
			fare,
			risk_label,
			route_summary,
			note_suffix
		]
	if not route_summary.is_empty() and GameState.is_region_discovered(region_id):
		return "驿路：%s。路线：%s，约%d两，%s。%s" % [reason, route_summary, fare, risk_label, note_suffix]
	return "驿路：%s。" % reason

func _update_action_buttons(region_id: String) -> void:
	if focus_button == null or travel_button == null or clear_target_button == null:
		return
	var region := GameData.get_region(region_id)
	var discovered := not region.is_empty() and GameState.is_region_discovered(region_id)
	var is_current_target := not region_id.is_empty() and region_id == GameState.map_target_region_id
	focus_button.text = "已标记目的地" if is_current_target else "标记目的地"
	focus_button.disabled = not discovered or is_current_target
	if is_current_target:
		focus_button.tooltip_text = "该区域已是当前地图目的地"
	else:
		focus_button.tooltip_text = "在大地图上标记该区域" if discovered else "尚未发现区域"
	clear_target_button.disabled = GameState.map_target_region_id.is_empty()
	if clear_target_button.disabled:
		clear_target_button.tooltip_text = "当前没有地图目的地"
	else:
		clear_target_button.tooltip_text = "清除当前地图目的地"
	var plan := GameState.build_region_travel_plan(region_id)
	var reason := str(plan.get("blocked_reason", ""))
	travel_button.disabled = not reason.is_empty()
	if reason.is_empty():
		var familiarity_note := str(plan.get("familiarity_note", ""))
		travel_button.tooltip_text = "约 %.1f 时辰；%d 两；%s；%s" % [
			float(plan.get("hours", 0.0)),
			int(plan.get("fare", 0)),
			str(plan.get("risk_label", "")),
			str(plan.get("route_summary", ""))
		]
		if not familiarity_note.is_empty():
			travel_button.tooltip_text = "%s；%s" % [travel_button.tooltip_text, familiarity_note]
	else:
		travel_button.tooltip_text = reason

func _refresh_target_summary_label() -> void:
	if target_summary_label == null:
		return
	var summary := GameState.get_map_target_summary()
	if summary.is_empty():
		target_summary_label.text = "地图目的地：未标记"
		return
	target_summary_label.text = summary

func _request_focus_region() -> void:
	if selected_region_id.is_empty() or not GameState.is_region_discovered(selected_region_id):
		EventBus.emit_toast("尚未发现该区域")
		return
	focus_region_requested.emit(selected_region_id)

func _request_clear_target() -> void:
	if GameState.map_target_region_id.is_empty():
		EventBus.emit_toast("当前没有地图目的地")
		_refresh()
		return
	clear_target_requested.emit()

func _request_fast_travel() -> void:
	if selected_region_id.is_empty():
		return
	var reason := GameState.get_fast_travel_block_reason(selected_region_id)
	if not reason.is_empty():
		EventBus.emit_toast(reason)
		return
	fast_travel_requested.emit(selected_region_id)

func _set_route_plan(plan: Dictionary) -> void:
	if map_canvas != null and map_canvas.has_method("set_route_plan"):
		map_canvas.set_route_plan(plan)

func _type_name(region_type: String) -> String:
	match region_type:
		"city":
			return "城池"
		"town":
			return "小镇"
		"sect":
			return "门派"
		_:
			return "野外"

func _danger_name(danger: int) -> String:
	if danger >= 4:
		return "险地"
	if danger >= 3:
		return "危险"
	if danger >= 2:
		return "谨慎"
	return "安全"

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()

func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(18, 16, 18, 16))

func _scene_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	style.border_color = Color(0.58, 0.46, 0.26, 0.80)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _set_scene_background(region_id: String, caption: String) -> void:
	if scene_caption != null:
		scene_caption.text = caption
	if scene_texture == null:
		return
	if region_id.is_empty():
		scene_texture.texture = null
		return
	var path := GameData.get_scene_background_path(region_id)
	if path.is_empty():
		scene_texture.texture = null
		return
	scene_texture.texture = GameData.load_texture(path)
