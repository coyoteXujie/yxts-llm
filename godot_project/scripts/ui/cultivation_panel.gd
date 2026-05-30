extends Control
class_name CultivationPanel

var skill_list: ItemList
var details: Label
var skill_ids: Array[String] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.player_changed.connect(func(_player: Dictionary) -> void: _refresh())

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.CULTIVATION)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(746, 88)
	panel.size = Vector2(488, 542)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "修炼"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title)

	skill_list = ItemList.new()
	skill_list.custom_minimum_size = Vector2(430, 270)
	skill_list.item_selected.connect(_select_skill)
	box.add_child(skill_list)

	details = Label.new()
	details.custom_minimum_size = Vector2(430, 118)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	box.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var practice := Button.new()
	practice.text = "修炼"
	practice.pressed.connect(_practice_selected)
	actions.add_child(practice)

	var meditate := Button.new()
	meditate.text = "打坐"
	meditate.pressed.connect(_meditate)
	actions.add_child(meditate)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _refresh() -> void:
	if skill_list == null:
		return
	skill_list.clear()
	skill_ids.clear()
	for skill_id in GameState.learned_skills.keys():
		skill_ids.append(str(skill_id))
		skill_list.add_item("%s  Lv.%d" % [GameData.get_skill_name(str(skill_id)), int(GameState.learned_skills[skill_id])])
	details.text = "潜能：%d\n选择武学后可消耗潜能修炼。" % int(GameState.player.get("pot", 0))

func _select_skill(index: int) -> void:
	if index < 0 or index >= skill_ids.size():
		return
	var skill_id := skill_ids[index]
	var level := int(GameState.learned_skills.get(skill_id, 0))
	details.text = "%s\n当前等级：%d\n下次修炼消耗潜能：%d" % [
		GameData.get_skill_name(skill_id),
		level,
		max(5, level * 3)
	]

func _practice_selected() -> void:
	var selected := skill_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < skill_ids.size():
		GameState.practice_skill(skill_ids[index])
	_refresh()

func _meditate() -> void:
	GameState.restore_mp(30)
	GameState.heal_player(12)
	EventBus.emit_toast("打坐调息")

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
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
