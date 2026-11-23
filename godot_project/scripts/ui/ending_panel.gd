extends Control
class_name EndingPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")
const PANEL_ANIM := preload("res://scripts/ui/panel_anim.gd")

signal ng_plus_requested()

var title_label: Label
var body_label: Label
var decision_label: Label
var epitaph_label: Label
var ng_plus_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func show_ending(ending: Dictionary) -> void:
	title_label.text = str(ending.get("title", "江湖尾声"))
	body_label.text = str(ending.get("description", "你的江湖故事暂告一段落。"))
	decision_label.text = _build_decision_echo()
	epitaph_label.text = str(ending.get("epitaph", ""))
	if ng_plus_button != null:
		ng_plus_button.visible = GameState.has_ng_plus_snapshot()
	PANEL_ANIM.open(self)
	GameState.set_mode(GameState.Mode.ENDING)

func _build_decision_echo() -> String:
	var flags := GameState.game_flags
	var parts: Array[String] = []

	if flags.has("story_epilogue_mercy") and bool(flags["story_epilogue_mercy"]):
		parts.append("你选择了〈清算有度〉——封存旧案，\n只清点首恶和铁证，给被胁迫者留一条回头路。")
	elif flags.has("story_epilogue_reckoning") and bool(flags["story_epilogue_reckoning"]):
		parts.append("你选择了〈追剿残影〉——趁势清剿暗影司残部，\n宁可翻出旧怨，也不让暗处再蛰伏。")

	if flags.has("story_conclave_public") and bool(flags["story_conclave_public"]):
		parts.append("在武林夜议前，你选择公开断令证据，\n换取七派正道信任。")
	elif flags.has("story_conclave_secret") and bool(flags["story_conclave_secret"]):
		parts.append("在武林夜议前，你选择暂压断令，\n沿苏家旧账暗中追查。")
	elif flags.has("story_conclave_betray") and bool(flags["story_conclave_betray"]):
		parts.append("在武林夜议前，你选择倒戈投敌，\n把断令证据卖给了暗影司。")

	var daode := int(GameState.player.get("daode", 0))
	var daode_tier_label := ""
	if daode >= 80:
		daode_tier_label = "正气凛然"
	elif daode >= 50:
		daode_tier_label = "侠义心肠"
	elif daode >= 20:
		daode_tier_label = "行事端正"
	elif daode > -20:
		daode_tier_label = "中立"
	elif daode > -50:
		daode_tier_label = "行事偏激"
	elif daode > -80:
		daode_tier_label = "歹毒狠辣"
	else:
		daode_tier_label = "罪大恶极"
	parts.append("你最终的名望在江湖上被称为：「%s」（%+d）" % [daode_tier_label, daode])

	return "\n\n".join(parts)

func close_panel() -> void:
	PANEL_ANIM.close(self)
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.018, 0.014, 0.78)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(252, 118)
	panel.size = Vector2(776, 484)
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(40, 32, 40, 28)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_title(title_label)
	box.add_child(title_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(680, 1)
	divider.color = Color(0.72, 0.54, 0.24, 0.55)
	box.add_child(divider)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(688, 200)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(body_label, 20)
	box.add_child(body_label)

	decision_label = Label.new()
	decision_label.custom_minimum_size = Vector2(688, 96)
	decision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(decision_label, 16)
	decision_label.add_theme_color_override("font_color", Color(0.72, 0.64, 0.52))
	box.add_child(decision_label)

	epitaph_label = Label.new()
	epitaph_label.custom_minimum_size = Vector2(688, 48)
	epitaph_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epitaph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(epitaph_label, 18)
	epitaph_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.48))
	box.add_child(epitaph_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)

	var close_button := Button.new()
	close_button.text = "重归江湖"
	close_button.custom_minimum_size = Vector2(160, 44)
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

	ng_plus_button = Button.new()
	ng_plus_button.text = "开启新周目"
	ng_plus_button.custom_minimum_size = Vector2(160, 44)
	UI_ART.apply_button(ng_plus_button)
	ng_plus_button.visible = false
	ng_plus_button.pressed.connect(_on_ng_plus_pressed)
	actions.add_child(ng_plus_button)

func _on_ng_plus_pressed() -> void:
	ng_plus_requested.emit()
	PANEL_ANIM.close(self)


