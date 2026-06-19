extends Control
class_name CharacterCreationPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

const FACTION_IDS := ["none", "bagua", "flower", "honglian", "naja", "taiji", "xueshan", "xiaoyao"]
const GENDER_IDS := ["male", "female"]
const FACTION_DESCRIPTIONS := {
	"none": "无门无派开局更自由，只带基础拳脚、轻功、内功和招架。",
	"bagua": "八卦门重步法与刀掌变化，开局习得八卦刀。",
	"flower": "花间派重身法与剑意，开局习得花飞剑法。",
	"honglian": "红莲教刚烈直进，开局习得鹤翔术。",
	"naja": "那迦派偏暗器身法与奇诡路数，开局习得忍术。",
	"taiji": "太极门守中带攻，开局习得太极剑法。",
	"xueshan": "雪山派刀剑凌厉，开局习得踏雪无痕。",
	"xiaoyao": "逍遥派重内功与身法，开局习得逍遥游。"
}

signal character_created(config: Dictionary)

var name_edit: LineEdit
var gender_select: OptionButton
var faction_select: OptionButton
var strength_box: SpinBox
var dexterity_box: SpinBox
var intelligence_box: SpinBox
var constitution_box: SpinBox
var preview_texture: TextureRect
var summary_label: Label
var message_label: Label
var confirm_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func show_panel() -> void:
	_reset_values()
	show()
	GameState.set_mode(GameState.Mode.CHARACTER_CREATION)

func _build() -> void:
	var backdrop := UI_ART.full_rect_texture(UI_ART.MAIN_MENU_BACKDROP)
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.018, 0.015, 0.012, 0.54)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(228, 68)
	panel.size = Vector2(824, 588)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	panel.add_child(root)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(452, 0)
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)

	var title := Label.new()
	title.text = "创建角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	UI_ART.apply_label_shadow(title)
	box.add_child(title)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "姓名"
	name_edit.text = "少侠"
	box.add_child(_field_row("姓名", name_edit))

	gender_select = OptionButton.new()
	gender_select.add_item("男", 0)
	gender_select.add_item("女", 1)
	gender_select.item_selected.connect(func(_index: int) -> void: _refresh_preview())
	box.add_child(_field_row("性别", gender_select))

	faction_select = OptionButton.new()
	for faction_index in range(FACTION_IDS.size()):
		faction_select.add_item(GameData.get_faction_name(str(FACTION_IDS[faction_index])), faction_index)
	faction_select.item_selected.connect(func(_index: int) -> void: _refresh_preview())
	box.add_child(_field_row("出身", faction_select))

	strength_box = _attr_box()
	dexterity_box = _attr_box()
	intelligence_box = _attr_box()
	constitution_box = _attr_box()
	for attr_box in [strength_box, dexterity_box, intelligence_box, constitution_box]:
		attr_box.value_changed.connect(func(_value: float) -> void: _refresh_summary())
	box.add_child(_field_row("臂力", strength_box))
	box.add_child(_field_row("身法", dexterity_box))
	box.add_child(_field_row("悟性", intelligence_box))
	box.add_child(_field_row("根骨", constitution_box))

	message_label = Label.new()
	message_label.text = "四项属性总和最多 70。"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	UI_ART.apply_label_shadow(message_label, 0.55)
	box.add_child(message_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	confirm_button = Button.new()
	confirm_button.text = "开始"
	confirm_button.custom_minimum_size = Vector2(150, 42)
	UI_ART.apply_button(confirm_button)
	confirm_button.pressed.connect(_confirm)
	actions.add_child(confirm_button)

	var reset := Button.new()
	reset.text = "重置"
	reset.custom_minimum_size = Vector2(120, 42)
	UI_ART.apply_button(reset)
	reset.pressed.connect(_reset_values)
	actions.add_child(reset)

	var preview_box := VBoxContainer.new()
	preview_box.custom_minimum_size = Vector2(290, 0)
	preview_box.add_theme_constant_override("separation", 12)
	root.add_child(preview_box)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(260, 310)
	preview_frame.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(10, 10, 10, 10)))
	preview_box.add_child(preview_frame)

	preview_texture = TextureRect.new()
	preview_texture.custom_minimum_size = Vector2(238, 288)
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	preview_frame.add_child(preview_texture)

	summary_label = Label.new()
	summary_label.custom_minimum_size = Vector2(270, 190)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(summary_label, 15)
	preview_box.add_child(summary_label)

func _field_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(88, 34)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70))
	UI_ART.apply_label_shadow(label, 0.52)
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
	_refresh_preview()
	_refresh_summary()

func _confirm() -> void:
	var total := int(strength_box.value + dexterity_box.value + intelligence_box.value + constitution_box.value)
	if total > 70:
		message_label.text = "属性总和为 %d，超过 70。" % total
		return
	var config := {
		"name": name_edit.text.strip_edges() if not name_edit.text.strip_edges().is_empty() else "少侠",
		"gender": str(GENDER_IDS[clampi(gender_select.selected, 0, GENDER_IDS.size() - 1)]),
		"faction": str(FACTION_IDS[clampi(faction_select.selected, 0, FACTION_IDS.size() - 1)]),
		"strength": int(strength_box.value),
		"dexterity": int(dexterity_box.value),
		"intelligence": int(intelligence_box.value),
		"constitution": int(constitution_box.value)
	}
	hide()
	character_created.emit(config)

func _refresh_preview() -> void:
	if preview_texture == null:
		return
	var gender := str(GENDER_IDS[clampi(gender_select.selected, 0, GENDER_IDS.size() - 1)])
	var faction := str(FACTION_IDS[clampi(faction_select.selected, 0, FACTION_IDS.size() - 1)])
	var path := _player_preview_path(gender, faction)
	preview_texture.texture = GameData.load_texture(path, true)
	_refresh_summary()

func _refresh_summary() -> void:
	var total := int(strength_box.value + dexterity_box.value + intelligence_box.value + constitution_box.value)
	var remaining := 70 - total
	if confirm_button != null:
		confirm_button.disabled = total > 70
	if message_label != null:
		if total > 70:
			message_label.text = "属性总和为 %d，超过 70。" % total
		else:
			message_label.text = "属性总和 %d/70，剩余 %d 点。" % [total, remaining]
	if summary_label == null:
		return
	var faction := str(FACTION_IDS[clampi(faction_select.selected, 0, FACTION_IDS.size() - 1)])
	var start_skills := GameData.get_faction_skills(faction)
	var skill_text := "基础拳脚" if start_skills.is_empty() else GameData.get_skill_name(str(start_skills[0]))
	var hp := 70 + int(constitution_box.value) * 4
	var mp := 25 + int(intelligence_box.value) * 3
	var attack := 6 + int(strength_box.value)
	var defense := 3 + int(float(dexterity_box.value) * 0.6)
	summary_label.text = "%s\n%s\n起始武学：%s\n气血 %d  内力 %d\n攻击 %d  防御 %d" % [
		GameData.get_faction_name(faction),
		str(FACTION_DESCRIPTIONS.get(faction, "")),
		skill_text,
		hp,
		mp,
		attack,
		defense
	]

func _player_preview_path(gender: String, faction: String) -> String:
	if gender == "male" and faction == "none":
		return "res://assets/characters/player/player_male_none_stage_v2.png"
	return "res://assets/characters/player/player_%s_%s.png" % [gender, faction]

func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(30, 24, 30, 24))
