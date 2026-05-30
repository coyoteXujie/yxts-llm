extends Control
class_name WorldMapPanel

const MAP_CANVAS_SCRIPT := preload("res://scripts/ui/region_map_canvas.gd")

var region_list: ItemList
var scene_texture: TextureRect
var scene_caption: Label
var details: RichTextLabel
var map_canvas
var region_ids: Array[String] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.region_changed.connect(func(_region: Dictionary, _state: Dictionary) -> void: _refresh())

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
	panel.add_theme_stylebox_override("panel", _panel_style())
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
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	left.add_child(title)

	region_list = ItemList.new()
	region_list.custom_minimum_size = Vector2(300, 455)
	region_list.item_selected.connect(_select_region)
	left.add_child(region_list)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(682, 530)
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	map_canvas = MAP_CANVAS_SCRIPT.new()
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
	info_row.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(actions)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(118, 36)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _refresh() -> void:
	if region_list == null:
		return
	var selected_id: String = str(map_canvas.selected_region_id) if map_canvas != null else GameState.current_region_id
	region_list.clear()
	region_ids.clear()
	for region in GameData.get_regions():
		var region_id := str(region.get("id", ""))
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
	if region_id.is_empty():
		details.text = "尚未发现区域。"
		_set_scene_background("", "区域景象")
		return
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return
	var discovered := GameState.is_region_discovered(region_id)
	if map_canvas != null:
		map_canvas.set_selected_region(region_id)
	if not discovered:
		details.text = "未知区域\n继续探索世界后，区域名称、地貌和危险等级会逐步显现。"
		_set_scene_background("", "尚未发现")
		return
	var danger := int(region.get("danger", 0))
	var state := GameState.get_region_state(region_id)
	var extra := _region_detail_lines(region_id)
	details.text = "%s\n类型：%s    危险：%s    探索度：%d%%\n%s%s" % [
		str(region.get("name", region_id)),
		_type_name(str(region.get("type", "wild"))),
		_danger_name(danger),
		int(state.get("exploration", 0)),
		str(region.get("description", "")),
		extra
	]
	_set_scene_background(region_id, str(region.get("name", region_id)))

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
	if lines.is_empty():
		return ""
	return "\n" + "\n".join(lines)

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

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.068, 0.052, 0.97)
	style.border_color = Color(0.58, 0.46, 0.26, 0.90)
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
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

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
