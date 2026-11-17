extends Control
class_name DiscoveryPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var title_label: Label
var region_label: Label
var body_label: Label
var rewards_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func show_discovery(data: Dictionary) -> void:
	title_label.text = str(data.get("title", "有所发现"))
	region_label.text = str(data.get("region", ""))
	body_label.text = str(data.get("description", "这里暂时没有更多线索。"))
	var rewards: Array = data.get("rewards", [])
	if bool(data.get("already_seen", false)):
		rewards_label.text = "已探索过"
	elif rewards.is_empty():
		rewards_label.text = "已记录"
	else:
		rewards_label.text = "获得：%s" % "，".join(rewards)
	show()
	GameState.set_mode(GameState.Mode.DISCOVERY)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.018, 0.014, 0.48)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -332
	panel.offset_top = -210
	panel.offset_right = 332
	panel.offset_bottom = 210
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(36, 28, 36, 24)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_title(title_label)
	box.add_child(title_label)

	region_label = Label.new()
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(region_label, 16)
	region_label.add_theme_color_override("font_color", Color(0.70, 0.66, 0.56))
	box.add_child(region_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(580, 1)
	divider.color = Color(0.72, 0.54, 0.24, 0.45)
	box.add_child(divider)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(584, 168)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(body_label, 20)
	box.add_child(body_label)

	rewards_label = Label.new()
	rewards_label.custom_minimum_size = Vector2(584, 44)
	rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(rewards_label, 18)
	rewards_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.58))
	box.add_child(rewards_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(actions)

	var close_button := Button.new()
	close_button.text = "知道了"
	close_button.custom_minimum_size = Vector2(120, 40)
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
