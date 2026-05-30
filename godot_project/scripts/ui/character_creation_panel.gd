extends Control
class_name CharacterCreationPanel

signal character_created(config: Dictionary)

var name_edit: LineEdit
var gender_select: OptionButton
var faction_select: OptionButton
var strength_box: SpinBox
var dexterity_box: SpinBox
var intelligence_box: SpinBox
var constitution_box: SpinBox
var message_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func show_panel() -> void:
	_reset_values()
	show()
	GameState.set_mode(GameState.Mode.CHARACTER_CREATION)

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.04, 0.035, 0.90)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(360, 74)
	panel.size = Vector2(560, 572)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "创建角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "姓名"
	name_edit.text = "少侠"
	box.add_child(_field_row("姓名", name_edit))

	gender_select = OptionButton.new()
	gender_select.add_item("男", 0)
	gender_select.add_item("女", 1)
	box.add_child(_field_row("性别", gender_select))

	faction_select = OptionButton.new()
	faction_select.add_item("无门无派", 0)
	faction_select.add_item("八卦门", 1)
	faction_select.add_item("花间派", 2)
	faction_select.add_item("太极门", 3)
	faction_select.add_item("雪山派", 4)
	box.add_child(_field_row("出身", faction_select))

	strength_box = _attr_box()
	dexterity_box = _attr_box()
	intelligence_box = _attr_box()
	constitution_box = _attr_box()
	box.add_child(_field_row("臂力", strength_box))
	box.add_child(_field_row("身法", dexterity_box))
	box.add_child(_field_row("悟性", intelligence_box))
	box.add_child(_field_row("根骨", constitution_box))

	message_label = Label.new()
	message_label.text = "四项属性总和最多 70。"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	box.add_child(message_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	var confirm := Button.new()
	confirm.text = "开始"
	confirm.custom_minimum_size = Vector2(150, 42)
	confirm.pressed.connect(_confirm)
	actions.add_child(confirm)

	var reset := Button.new()
	reset.text = "重置"
	reset.custom_minimum_size = Vector2(120, 42)
	reset.pressed.connect(_reset_values)
	actions.add_child(reset)

func _field_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(88, 34)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70))
	row.add_child(label)
	control.custom_minimum_size = Vector2(320, 34)
	row.add_child(control)
	return row

func _attr_box() -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 8
	box.max_value = 25
	box.step = 1
	box.value = 15
	return box

func _reset_values() -> void:
	if name_edit == null:
		return
	name_edit.text = "少侠"
	gender_select.selected = 0
	faction_select.selected = 0
	strength_box.value = 15
	dexterity_box.value = 15
	intelligence_box.value = 15
	constitution_box.value = 15
	message_label.text = "四项属性总和最多 70。"

func _confirm() -> void:
	var total := int(strength_box.value + dexterity_box.value + intelligence_box.value + constitution_box.value)
	if total > 70:
		message_label.text = "属性总和为 %d，超过 70。" % total
		return
	var factions := ["none", "bagua", "flower", "taiji", "xueshan"]
	var genders := ["male", "female"]
	var config := {
		"name": name_edit.text.strip_edges() if not name_edit.text.strip_edges().is_empty() else "少侠",
		"gender": genders[gender_select.selected],
		"faction": factions[faction_select.selected],
		"strength": int(strength_box.value),
		"dexterity": int(dexterity_box.value),
		"intelligence": int(intelligence_box.value),
		"constitution": int(constitution_box.value)
	}
	hide()
	character_created.emit(config)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.06, 0.98)
	style.border_color = Color(0.60, 0.46, 0.24, 0.90)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style
