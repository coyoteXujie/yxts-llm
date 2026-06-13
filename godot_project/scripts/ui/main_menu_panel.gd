extends Control
class_name MainMenuPanel

signal new_game_requested()
signal continue_requested()

var continue_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func show_menu() -> void:
	continue_button.disabled = not GameState.has_save()
	show()
	GameState.set_mode(GameState.Mode.MENU)

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.04, 0.035, 0.94)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(390, 126)
	panel.size = Vector2(500, 468)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := Label.new()
	title.text = "白金英雄坛说"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Godot 江湖 Alpha"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	box.add_child(subtitle)

	var new_button := _menu_button("新的江湖")
	new_button.pressed.connect(func() -> void:
		hide()
		new_game_requested.emit()
	)
	box.add_child(new_button)

	continue_button = _menu_button("读取存档")
	continue_button.pressed.connect(func() -> void:
		hide()
		continue_requested.emit()
	)
	box.add_child(continue_button)

	var settings_button := _menu_button("设置")
	settings_button.pressed.connect(func() -> void:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -10.0 if AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) > -20.0 else 0.0)
		_show_settings_toast()
	)
	box.add_child(settings_button)

	var quit_button := _menu_button("退出")
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)

	var tips := Label.new()
	tips.text = "WASD 移动  T 交谈  F 战斗  B 背包  J 任务  K 修炼  M 地图  F5/F9 存读档"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_theme_font_size_override("font_size", 15)
	tips.add_theme_color_override("font_color", Color(0.62, 0.58, 0.50))
	box.add_child(tips)

func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 44)
	return button

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
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	return style

func _show_settings_toast() -> void:
	EventBus.emit_toast("设置功能开发中...")
