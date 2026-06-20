extends Control
class_name MainMenuPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

signal new_game_requested()
signal continue_requested()
signal resume_requested()
signal save_requested()

var resume_button: Button
var save_button: Button
var continue_button: Button
var settings_button: Button
var save_summary_label: Label
var can_resume_game := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func show_menu(can_resume: bool = false) -> void:
	can_resume_game = can_resume
	_refresh_action_state()
	show()
	GameState.set_mode(GameState.Mode.MENU)

func refresh_menu_state() -> void:
	_refresh_action_state()

func _build() -> void:
	var backdrop := UI_ART.full_rect_texture(UI_ART.MAIN_MENU_BACKDROP)
	add_child(backdrop)

	var global_shade := ColorRect.new()
	global_shade.color = Color(0.018, 0.017, 0.014, 0.22)
	global_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	global_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(global_shade)

	var menu_shade := ColorRect.new()
	menu_shade.color = Color(0.018, 0.014, 0.010, 0.48)
	menu_shade.anchor_left = 0.0
	menu_shade.anchor_right = 0.48
	menu_shade.anchor_top = 0.0
	menu_shade.anchor_bottom = 1.0
	menu_shade.offset_right = 32
	menu_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(74, 74)
	panel.size = Vector2(500, 572)
	panel.add_theme_stylebox_override("panel", UI_ART.panel_style(Color(0.060, 0.048, 0.034, 0.82), Color(0.74, 0.52, 0.23, 0.72), Vector4(34, 30, 34, 30)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "白金英雄坛说"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.80, 0.36))
	UI_ART.apply_label_shadow(title)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "一局可继续成长的江湖"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.78, 0.60))
	UI_ART.apply_label_shadow(subtitle, 0.70)
	box.add_child(subtitle)

	save_summary_label = Label.new()
	save_summary_label.custom_minimum_size = Vector2(420, 92)
	save_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_summary_label.add_theme_font_size_override("font_size", 15)
	save_summary_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.70))
	UI_ART.apply_label_shadow(save_summary_label, 0.65)
	box.add_child(save_summary_label)

	resume_button = _menu_button("返回江湖")
	resume_button.pressed.connect(func() -> void:
		hide()
		resume_requested.emit()
	)
	box.add_child(resume_button)

	var new_button := _menu_button("新的江湖")
	new_button.pressed.connect(func() -> void:
		hide()
		new_game_requested.emit()
	)
	box.add_child(new_button)

	continue_button = _menu_button("继续江湖")
	continue_button.pressed.connect(func() -> void:
		hide()
		continue_requested.emit()
	)
	box.add_child(continue_button)

	save_button = _menu_button("保存当前")
	save_button.pressed.connect(func() -> void:
		save_requested.emit()
	)
	box.add_child(save_button)

	settings_button = _menu_button("声音：开启")
	settings_button.pressed.connect(func() -> void:
		_toggle_master_audio()
	)
	box.add_child(settings_button)

	var quit_button := _menu_button("退出")
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)

	var tips := Label.new()
	tips.text = "WASD 移动  T 交谈  F 战斗  B 背包  J 任务  K 修炼  M 地图"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_theme_font_size_override("font_size", 15)
	tips.add_theme_color_override("font_color", Color(0.70, 0.66, 0.55))
	box.add_child(tips)

func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 44)
	button.add_theme_font_size_override("font_size", 17)
	UI_ART.apply_button(button)
	return button

func _show_settings_toast() -> void:
	EventBus.emit_toast("声音已%s" % ("关闭" if _is_master_audio_muted() else "开启"))

func _refresh_action_state() -> void:
	if resume_button != null:
		resume_button.visible = can_resume_game
	if save_button != null:
		save_button.visible = can_resume_game
	if continue_button != null:
		continue_button.disabled = not GameState.has_save()
		continue_button.text = "读取存档" if can_resume_game else "继续江湖"
	if settings_button != null:
		settings_button.text = "声音：%s" % ("关闭" if _is_master_audio_muted() else "开启")
	_refresh_save_summary()

func _toggle_master_audio() -> void:
	var bus := _master_bus_index()
	if bus < 0:
		return
	var muted := not AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, muted)
	_refresh_action_state()
	_show_settings_toast()

func _is_master_audio_muted() -> bool:
	var bus := _master_bus_index()
	return bus >= 0 and AudioServer.is_bus_mute(bus)

func _master_bus_index() -> int:
	return AudioServer.get_bus_index("Master")

func _refresh_save_summary() -> void:
	if save_summary_label == null:
		return
	if not GameState.has_save():
		save_summary_label.text = "尚无存档\n开局目标：在平安镇找到线索，完成第一场除恶战斗，打开江湖主线。"
		return
	var summary := GameState.get_save_summary()
	if summary.is_empty():
		save_summary_label.text = "存档可读取\n摘要暂不可用，继续后将在游戏内恢复状态。"
		return
	save_summary_label.text = "%s  等级%d  %s\n第%d天 %02d:00  %s  ·  %s\n进行中 %d  已完成 %d\n%s" % [
		str(summary.get("player_name", "少侠")),
		int(summary.get("level", 1)),
		str(summary.get("faction", "无门无派")),
		int(summary.get("day", 1)),
		int(summary.get("hour", 8)),
		str(summary.get("weather", "晴朗")),
		str(summary.get("region_name", "未知之地")),
		int(summary.get("active_count", 0)),
		int(summary.get("completed_count", 0)),
		str(summary.get("active_quest", "自由探索江湖"))
	]
