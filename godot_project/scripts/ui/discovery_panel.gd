extends Control
class_name DiscoveryPanel

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
	panel.position = Vector2(308, 132)
	panel.size = Vector2(664, 420)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.80, 0.40))
	box.add_child(title_label)

	region_label = Label.new()
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label.add_theme_font_size_override("font_size", 16)
	region_label.add_theme_color_override("font_color", Color(0.70, 0.66, 0.56))
	box.add_child(region_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(580, 1)
	divider.color = Color(0.72, 0.54, 0.24, 0.45)
	box.add_child(divider)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(584, 168)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 20)
	body_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.74))
	box.add_child(body_label)

	rewards_label = Label.new()
	rewards_label.custom_minimum_size = Vector2(584, 44)
	rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.add_theme_font_size_override("font_size", 18)
	rewards_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.58))
	box.add_child(rewards_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(actions)

	var close_button := Button.new()
	close_button.text = "知道了"
	close_button.custom_minimum_size = Vector2(120, 40)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.070, 0.060, 0.045, 0.97)
	style.border_color = Color(0.66, 0.50, 0.24, 0.92)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 24
	return style

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
