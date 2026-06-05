extends Control
class_name CombatPanel

const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")

var combat_system
var stage
var title_label: Label
var enemy_portrait: TextureRect
var enemy_bar: ProgressBar
var status_label: Label
var body_label: Label
var action_grid: GridContainer
var effect_label: Label
var last_snapshot: Dictionary = {}
var last_effect_event_id := 0
var effect_timer := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	set_process(true)

func _process(delta: float) -> void:
	if effect_label == null or not effect_label.visible:
		return
	effect_timer -= delta
	if effect_timer <= 0.0:
		effect_label.hide()
		return
	effect_label.modulate.a = clampf(effect_timer / 0.9, 0.0, 1.0)
	effect_label.position.y -= delta * 22.0

func set_combat_system(system) -> void:
	combat_system = system
	combat_system.combat_started.connect(_on_combat_started)
	combat_system.combat_changed.connect(_on_combat_changed)
	combat_system.combat_finished.connect(_on_combat_finished)

func _build() -> void:
	stage = COMBAT_STAGE_SCRIPT.new()
	stage.position = Vector2(24, 342)
	stage.size = Vector2(682, 334)
	add_child(stage)

	var panel := PanelContainer.new()
	panel.position = Vector2(730, 342)
	panel.size = Vector2(512, 334)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 12)
	box.add_child(enemy_row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(86, 86)
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	enemy_row.add_child(portrait_frame)

	enemy_portrait = TextureRect.new()
	enemy_portrait.custom_minimum_size = Vector2(72, 72)
	enemy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(enemy_portrait)

	var enemy_info := VBoxContainer.new()
	enemy_info.custom_minimum_size = Vector2(356, 86)
	enemy_info.add_theme_constant_override("separation", 7)
	enemy_row.add_child(enemy_info)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.70, 0.45))
	enemy_info.add_child(title_label)

	enemy_bar = ProgressBar.new()
	enemy_bar.show_percentage = false
	enemy_bar.custom_minimum_size = Vector2(350, 18)
	enemy_info.add_child(enemy_bar)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.80, 0.76, 0.66))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_info.add_child(status_label)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(450, 84)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.76))
	box.add_child(body_label)

	action_grid = GridContainer.new()
	action_grid.columns = 2
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(action_grid)

	effect_label = Label.new()
	effect_label.hide()
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.add_theme_font_size_override("font_size", 24)
	effect_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.015, 0.01, 0.86))
	effect_label.add_theme_constant_override("shadow_offset_x", 2)
	effect_label.add_theme_constant_override("shadow_offset_y", 2)
	effect_label.custom_minimum_size = Vector2(260, 40)
	add_child(effect_label)

func _on_combat_started(enemy: Dictionary) -> void:
	title_label.text = "遭遇：%s" % str(enemy.get("name", "敌人"))
	last_snapshot = {}
	last_effect_event_id = 0
	if effect_label != null:
		effect_label.hide()
	if stage != null:
		stage.setup(enemy)
	_set_enemy_portrait(enemy)
	_refresh_actions()
	show()

func _on_combat_changed(snapshot: Dictionary) -> void:
	last_snapshot = snapshot
	var enemy: Dictionary = snapshot.get("enemy", {})
	enemy_bar.max_value = max(1, int(enemy.get("max_hp", 1)))
	enemy_bar.value = max(0, int(enemy.get("hp", 0)))
	status_label.text = "敌方：%s    你：%s" % [
		str(snapshot.get("enemy_status_text", "无")),
		str(snapshot.get("player_status_text", "无"))
	]
	var lines: Array = snapshot.get("log", [])
	body_label.text = "\n".join(lines)
	if stage != null:
		stage.update_snapshot(snapshot)
	_play_latest_event(snapshot)
	_refresh_actions()

func _on_combat_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		EventBus.emit_toast("战斗胜利")
	elif bool(result.get("escaped", false)):
		EventBus.emit_toast("已脱离战斗")
	else:
		EventBus.emit_toast("战败，回客栈休养")
	if stage != null:
		stage.clear()
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

func _portrait_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.055, 0.94)
	style.border_color = Color(0.70, 0.32, 0.20, 0.82)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _set_enemy_portrait(enemy: Dictionary) -> void:
	if enemy_portrait == null:
		return
	var path := GameData.get_npc_portrait_path(str(enemy.get("name", "")))
	if path.is_empty():
		enemy_portrait.texture = null
		return
	enemy_portrait.texture = GameData.load_texture(path)

func _refresh_actions() -> void:
	if action_grid == null:
		return
	for child in action_grid.get_children():
		action_grid.remove_child(child)
		child.queue_free()
	_add_action_button("普通攻击", "normal", "kf_basic_bare")
	var learned := _learned_attack_skills()
	for skill_id in learned.slice(0, 3):
		_add_action_button(GameData.get_skill_name(skill_id), skill_id, skill_id)
	_add_action_button("调息", "force", "kf_basic_force")
	_add_flee_button()

func _learned_attack_skills() -> Array[String]:
	var result: Array[String] = []
	for skill_id in GameState.learned_skills.keys():
		var id := str(skill_id)
		if GameData.is_attack_skill(id):
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return int(GameState.learned_skills.get(a, 0)) > int(GameState.learned_skills.get(b, 0))
	)
	return result

func _add_action_button(label: String, action_id: String, icon_skill_id: String) -> void:
	var button := Button.new()
	var cooldown := _cooldown_for_action(action_id)
	if cooldown > 0:
		button.text = "%s CD%d" % [label, cooldown]
		button.disabled = true
	else:
		button.text = label
	button.custom_minimum_size = Vector2(218, 38)
	button.clip_text = true
	var icon_path := GameData.get_skill_icon_path(icon_skill_id)
	if not icon_path.is_empty():
		button.icon = GameData.load_texture(icon_path)
		button.expand_icon = true
	button.pressed.connect(func() -> void:
		if combat_system != null:
			combat_system.player_attack(action_id)
	)
	action_grid.add_child(button)

func _cooldown_for_action(action_id: String) -> int:
	var cooldowns: Dictionary = last_snapshot.get("cooldowns", {})
	if action_id == "force":
		return int(cooldowns.get("force", 0))
	return int(cooldowns.get(action_id, 0))

func _add_flee_button() -> void:
	var button := Button.new()
	button.text = "脱身"
	button.custom_minimum_size = Vector2(218, 38)
	var icon_path := GameData.get_skill_icon_path("kf_basic_dodge")
	if not icon_path.is_empty():
		button.icon = GameData.load_texture(icon_path)
		button.expand_icon = true
	button.pressed.connect(func() -> void:
		if combat_system != null:
			combat_system.flee()
	)
	action_grid.add_child(button)

func _play_latest_event(snapshot: Dictionary) -> void:
	if effect_label == null:
		return
	var events: Array = snapshot.get("events", [])
	if events.is_empty():
		return
	var latest: Dictionary = events[events.size() - 1]
	var event_id := int(latest.get("id", 0))
	if event_id <= last_effect_event_id:
		return
	last_effect_event_id = event_id
	var kind := str(latest.get("kind", ""))
	var target := str(latest.get("target", "enemy"))
	var label := str(latest.get("label", ""))
	var source := str(latest.get("source", ""))
	if label.is_empty():
		label = _effect_label_for_kind(kind)
	effect_label.text = "%s  %s" % [source, label] if not source.is_empty() else label
	effect_label.add_theme_color_override("font_color", _effect_color(kind, target))
	effect_label.position = _effect_position(target)
	effect_label.modulate.a = 1.0
	effect_timer = 0.9
	effect_label.show()

func _effect_label_for_kind(kind: String) -> String:
	match kind:
		"miss":
			return "未中"
		"heal":
			return "回气"
		"mp":
			return "内力"
		"guard":
			return "守势"
		"phase":
			return "气势陡变"
		"stun":
			return "眩晕"
		_:
			return "命中"

func _effect_color(kind: String, target: String) -> Color:
	match kind:
		"damage":
			return Color(1.0, 0.35, 0.22) if target == "player" else Color(1.0, 0.78, 0.34)
		"miss":
			return Color(0.74, 0.76, 0.80)
		"heal":
			return Color(0.42, 0.95, 0.56)
		"mp":
			return Color(0.42, 0.70, 1.0)
		"guard":
			return Color(0.95, 0.78, 0.42)
		"phase":
			return Color(0.92, 0.45, 1.0)
		"stun":
			return Color(0.64, 0.82, 1.0)
		_:
			return Color(0.92, 0.86, 0.70)

func _effect_position(target: String) -> Vector2:
	if target == "player":
		return Vector2(146, 488)
	return Vector2(458, 462)
