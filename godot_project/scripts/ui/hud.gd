extends Control
class_name HudView

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var name_label: Label
var stats_label: Label
var quest_label: Label
var time_label: Label
var region_label: Label
var prompt_label: Label
var toast_label: Label
var toast_timer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_top_panel()
	_build_prompt()
	_build_toast()
	EventBus.player_changed.connect(_on_player_changed)
	EventBus.toast_requested.connect(show_toast)
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.region_changed.connect(_on_region_changed)
	_on_player_changed(GameState.player)
	_on_time_changed(GameState.day, GameState.hour, GameState.weather)
	_on_region_changed(GameData.get_region(GameState.current_region_id), GameState.get_region_state(GameState.current_region_id))

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		toast_label.modulate.a = min(1.0, toast_timer)
		if toast_timer <= 0.0:
			toast_label.hide()

func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.show()
	toast_timer = 3.0

func _build_top_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(430, 150)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.075, 0.06, 0.86), Color(0.55, 0.44, 0.25, 0.75)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.56))
	box.add_child(name_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(360, 18)
	hp_bar.show_percentage = false
	box.add_child(hp_bar)

	mp_bar = ProgressBar.new()
	mp_bar.custom_minimum_size = Vector2(360, 18)
	mp_bar.show_percentage = false
	box.add_child(mp_bar)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	box.add_child(stats_label)

	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 15)
	quest_label.add_theme_color_override("font_color", Color(0.70, 0.86, 0.68))
	box.add_child(quest_label)

	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	box.add_child(time_label)

	region_label = Label.new()
	region_label.add_theme_font_size_override("font_size", 14)
	region_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.70))
	box.add_child(region_label)

func _build_prompt() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 642)
	panel.size = Vector2(560, 44)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.055, 0.045, 0.78), Color(0.45, 0.35, 0.19, 0.65)))
	add_child(panel)

	prompt_label = Label.new()
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
	panel.add_child(prompt_label)
	prompt_label.hide()

func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.position = Vector2(470, 24)
	toast_label.size = Vector2(500, 40)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 20)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52))
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	toast_label.add_theme_constant_override("shadow_offset_x", 1)
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(toast_label)
	toast_label.hide()

func _on_player_changed(player: Dictionary) -> void:
	var hp := int(player.get("hp", 0))
	var max_hp := int(player.get("max_hp", 1))
	var mp := int(player.get("mp", 0))
	var max_mp := int(player.get("max_mp", 1))
	name_label.text = "%s  等级 %d  %s" % [
		str(player.get("name", "少侠")),
		int(player.get("level", 1)),
		GameData.get_faction_name(str(player.get("faction", "none")))
	]
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.tooltip_text = "气血 %d/%d" % [hp, max_hp]
	mp_bar.max_value = max_mp
	mp_bar.value = mp
	mp_bar.tooltip_text = "内力 %d/%d" % [mp, max_mp]
	stats_label.text = "气血 %d/%d   内力 %d/%d   攻 %d 防 %d   潜能 %d   银两 %d" % [
		hp, max_hp, mp, max_mp,
		int(player.get("attack", 0)),
		int(player.get("defense", 0)),
		int(player.get("pot", 0)),
		int(player.get("money", 0))
	]
	quest_label.text = "当前目标：%s" % GameState.active_quest

func _on_time_changed(day: int, hour: float, weather: String) -> void:
	if time_label == null:
		return
	time_label.text = "第 %d 天  %02d:00  %s" % [day, int(hour), weather]

func _on_region_changed(region: Dictionary, state: Dictionary) -> void:
	if region_label == null:
		return
	if region.is_empty():
		region_label.text = "所在地：未知之地"
		return
	var danger := int(region.get("danger", 0))
	var danger_text := "安全"
	if danger >= 4:
		danger_text = "险地"
	elif danger >= 2:
		danger_text = "谨慎"
	region_label.text = "所在地：%s  探索 %d%%  %s" % [
		str(region.get("name", region.get("id", ""))),
		int(state.get("exploration", 0)),
		danger_text
	]

func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
