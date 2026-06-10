extends Control
class_name CombatPanel

const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")

const IMMERSIVE_STAGE_ENABLED := true
const COMBAT_STAGE_MARGIN := 0.0
const COMBAT_TOP_HUD_HEIGHT := 94.0
const COMBAT_BOTTOM_HUD_HEIGHT := 156.0
const COMBAT_ACTION_COLUMNS := 4
const COMBAT_ACTION_BUTTON_SIZE := Vector2(132, 44)

var combat_system
var stage
var title_label: Label
var enemy_portrait: TextureRect
var enemy_bar: ProgressBar
var player_bar: ProgressBar
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
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.offset_left = COMBAT_STAGE_MARGIN
	stage.offset_top = COMBAT_STAGE_MARGIN
	stage.offset_right = -COMBAT_STAGE_MARGIN
	stage.offset_bottom = -COMBAT_STAGE_MARGIN
	add_child(stage)

	var top_panel := PanelContainer.new()
	top_panel.anchor_left = 0.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 28.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = -28.0
	top_panel.offset_bottom = 18.0 + COMBAT_TOP_HUD_HEIGHT
	top_panel.add_theme_stylebox_override("panel", _panel_style(0.78))
	add_child(top_panel)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top_panel.add_child(top_row)

	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 12)
	enemy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(enemy_row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(72, 72)
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	enemy_row.add_child(portrait_frame)

	enemy_portrait = TextureRect.new()
	enemy_portrait.custom_minimum_size = Vector2(58, 58)
	enemy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(enemy_portrait)

	var enemy_info := VBoxContainer.new()
	enemy_info.custom_minimum_size = Vector2(520, 72)
	enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_info.add_theme_constant_override("separation", 6)
	enemy_row.add_child(enemy_info)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.70, 0.45))
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	enemy_info.add_child(title_label)

	enemy_bar = ProgressBar.new()
	enemy_bar.show_percentage = false
	enemy_bar.custom_minimum_size = Vector2(520, 18)
	enemy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_info.add_child(enemy_bar)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.80, 0.76, 0.66))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	enemy_info.add_child(status_label)

	var player_box := VBoxContainer.new()
	player_box.custom_minimum_size = Vector2(238, 72)
	player_box.add_theme_constant_override("separation", 8)
	top_row.add_child(player_box)

	var player_title := Label.new()
	player_title.text = "我方状态"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	player_title.add_theme_font_size_override("font_size", 16)
	player_title.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	player_box.add_child(player_title)

	player_bar = ProgressBar.new()
	player_bar.show_percentage = false
	player_bar.custom_minimum_size = Vector2(238, 18)
	player_box.add_child(player_bar)

	var bottom_panel := PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 28.0
	bottom_panel.offset_top = -COMBAT_BOTTOM_HUD_HEIGHT - 24.0
	bottom_panel.offset_right = -28.0
	bottom_panel.offset_bottom = -24.0
	bottom_panel.add_theme_stylebox_override("panel", _panel_style(0.82))
	add_child(bottom_panel)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom_panel.add_child(bottom_row)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(580, 108)
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.76))
	bottom_row.add_child(body_label)

	action_grid = GridContainer.new()
	action_grid.columns = COMBAT_ACTION_COLUMNS
	action_grid.custom_minimum_size = Vector2(560, 108)
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	bottom_row.add_child(action_grid)

	effect_label = Label.new()
	effect_label.hide()
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.add_theme_font_size_override("font_size", 24)
	effect_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.015, 0.01, 0.86))
	effect_label.add_theme_constant_override("shadow_offset_x", 2)
	effect_label.add_theme_constant_override("shadow_offset_y", 2)
	effect_label.custom_minimum_size = Vector2(340, 44)
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
	if player_bar != null:
		player_bar.max_value = max(1, int(GameState.player.get("max_hp", 1)))
		player_bar.value = max(0, int(GameState.player.get("hp", player_bar.max_value)))
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

func _panel_style(alpha: float = 0.94) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.040, 0.034, alpha)
	style.border_color = Color(0.86, 0.50, 0.25, 0.62)
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
	style.bg_color = Color(0.08, 0.052, 0.040, 0.86)
	style.border_color = Color(0.86, 0.50, 0.25, 0.66)
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
	button.custom_minimum_size = COMBAT_ACTION_BUTTON_SIZE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 15)
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
	button.custom_minimum_size = COMBAT_ACTION_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 15)
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
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280, 720)
	if target == "player":
		return Vector2(viewport_size.x * 0.22, viewport_size.y * 0.46)
	return Vector2(viewport_size.x * 0.62, viewport_size.y * 0.42)
