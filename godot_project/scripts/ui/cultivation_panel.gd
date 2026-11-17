extends Control
class_name CultivationPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var skill_list: ItemList
var skill_preview: TextureRect
var summary_label: Label
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
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -244
	panel.offset_top = -271
	panel.offset_right = 244
	panel.offset_bottom = 271
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "修炼"
	UI_ART.apply_title(title)
	box.add_child(title)

	summary_label = Label.new()
	summary_label.custom_minimum_size = Vector2(430, 34)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(summary_label, 14)
	box.add_child(summary_label)

	skill_list = ItemList.new()
	skill_list.custom_minimum_size = Vector2(430, 236)
	skill_list.fixed_icon_size = Vector2i(36, 36)
	skill_list.icon_mode = ItemList.ICON_MODE_LEFT
	skill_list.item_selected.connect(_select_skill)
	box.add_child(skill_list)

	var detail_row := HBoxContainer.new()
	detail_row.custom_minimum_size = Vector2(430, 124)
	detail_row.add_theme_constant_override("separation", 12)
	box.add_child(detail_row)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(88, 88)
	preview_frame.add_theme_stylebox_override("panel", _slot_style())
	detail_row.add_child(preview_frame)

	skill_preview = TextureRect.new()
	skill_preview.custom_minimum_size = Vector2(72, 72)
	skill_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_frame.add_child(skill_preview)

	details = Label.new()
	details.custom_minimum_size = Vector2(328, 118)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(details)
	detail_row.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var practice := Button.new()
	practice.text = "修炼"
	UI_ART.apply_button(practice)
	practice.pressed.connect(_practice_selected)
	actions.add_child(practice)

	var meditate := Button.new()
	meditate.text = "打坐"
	UI_ART.apply_button(meditate)
	meditate.pressed.connect(_meditate)
	actions.add_child(meditate)

	var close_button := Button.new()
	close_button.text = "关闭"
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _refresh() -> void:
	if skill_list == null:
		return
	skill_list.clear()
	skill_ids.clear()
	if summary_label != null:
		summary_label.text = _cultivation_summary_text()
	var ids := GameState.learned_skills.keys()
	ids.sort()
	for skill_id in ids:
		skill_ids.append(str(skill_id))
		skill_list.add_item("%s  Lv.%d" % [GameData.get_skill_name(str(skill_id)), int(GameState.learned_skills[skill_id])], _load_skill_icon(str(skill_id)))
	details.text = "潜能：%d\n选择武学后可消耗潜能修炼。" % int(GameState.player.get("pot", 0))
	if skill_preview != null:
		skill_preview.texture = null

func _select_skill(index: int) -> void:
	if index < 0 or index >= skill_ids.size():
		return
	var skill_id := skill_ids[index]
	var level := int(GameState.learned_skills.get(skill_id, 0))
	details.text = "%s\n当前等级：%d    下次消耗：%d\n%s" % [
		GameData.get_skill_name(skill_id),
		level,
		max(5, level * 3),
		GameData.get_skill_summary(skill_id)
	]
	if skill_preview != null:
		skill_preview.texture = _load_skill_icon(skill_id)

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

func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(16, 14, 16, 14))

func _slot_style() -> StyleBox:
	return UI_ART.slot_texture_style()

func _cultivation_summary_text() -> String:
	return "潜能 %d  ·  已学 %d 门  ·  门派 %s" % [
		int(GameState.player.get("pot", 0)),
		GameState.learned_skills.size(),
		GameData.get_faction_name(str(GameState.player.get("faction", "none")))
	]

func _load_skill_icon(skill_id: String) -> Texture2D:
	var path := GameData.get_skill_icon_path(skill_id)
	if path.is_empty():
		return null
	return GameData.load_texture(path)
