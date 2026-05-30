extends Control
class_name CombatPanel

var combat_system
var title_label: Label
var enemy_bar: ProgressBar
var body_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func set_combat_system(system) -> void:
	combat_system = system
	combat_system.combat_started.connect(_on_combat_started)
	combat_system.combat_changed.connect(_on_combat_changed)
	combat_system.combat_finished.connect(_on_combat_finished)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(750, 372)
	panel.size = Vector2(492, 304)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.70, 0.45))
	box.add_child(title_label)

	enemy_bar = ProgressBar.new()
	enemy_bar.show_percentage = false
	enemy_bar.custom_minimum_size = Vector2(430, 18)
	box.add_child(enemy_bar)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(430, 138)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.76))
	box.add_child(body_label)

	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	box.add_child(actions)

	var attack_button := Button.new()
	attack_button.text = "普通攻击"
	attack_button.pressed.connect(func() -> void: combat_system.player_attack("normal"))
	actions.add_child(attack_button)

	var bare_button := Button.new()
	bare_button.text = "基本拳脚"
	bare_button.pressed.connect(func() -> void: combat_system.player_attack("bare"))
	actions.add_child(bare_button)

	var rest_button := Button.new()
	rest_button.text = "调息"
	rest_button.pressed.connect(func() -> void: combat_system.player_attack("force"))
	actions.add_child(rest_button)

	var flee_button := Button.new()
	flee_button.text = "脱身"
	flee_button.pressed.connect(func() -> void: combat_system.flee())
	actions.add_child(flee_button)

func _on_combat_started(enemy: Dictionary) -> void:
	title_label.text = "遭遇：%s" % str(enemy.get("name", "敌人"))
	show()

func _on_combat_changed(snapshot: Dictionary) -> void:
	var enemy: Dictionary = snapshot.get("enemy", {})
	enemy_bar.max_value = max(1, int(enemy.get("max_hp", 1)))
	enemy_bar.value = max(0, int(enemy.get("hp", 0)))
	var lines: Array = snapshot.get("log", [])
	body_label.text = "\n".join(lines)

func _on_combat_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		EventBus.emit_toast("战斗胜利")
	elif bool(result.get("escaped", false)):
		EventBus.emit_toast("已脱离战斗")
	else:
		EventBus.emit_toast("战败，回客栈休养")
	hide()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.052, 0.045, 0.94)
	style.border_color = Color(0.70, 0.32, 0.20, 0.88)
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
