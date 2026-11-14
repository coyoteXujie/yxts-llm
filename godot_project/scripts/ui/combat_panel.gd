extends Control
class_name CombatPanel

const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")
const UI_ART := preload("res://scripts/ui/ui_art.gd")
const INK_BURST_SHADER := preload("res://shaders/ink_burst.gdshader")

const IMMERSIVE_STAGE_ENABLED := true
const COMBAT_STAGE_MARGIN := 0.0
const COMBAT_TOP_HUD_HEIGHT := 124.0
const COMBAT_BOTTOM_HUD_HEIGHT := 156.0
const COMBAT_ACTION_COLUMNS := 4
const COMBAT_ACTION_BUTTON_SIZE := Vector2(132, 44)
const STATUS_ORDER := ["bleed", "poison", "burn", "stun", "slow", "weaken", "vulnerable", "guard"]
const STATUS_CHIP_META := {
	"bleed": {"label": "流血", "short": "血", "color": Color(0.92, 0.18, 0.20)},
	"poison": {"label": "中毒", "short": "毒", "color": Color(0.40, 0.78, 0.26)},
	"burn": {"label": "灼烧", "short": "炎", "color": Color(1.00, 0.43, 0.18)},
	"stun": {"label": "眩晕", "short": "晕", "color": Color(0.56, 0.72, 1.00)},
	"slow": {"label": "迟缓", "short": "缓", "color": Color(0.35, 0.80, 0.88)},
	"weaken": {"label": "虚弱", "short": "弱", "color": Color(0.73, 0.48, 0.88)},
	"vulnerable": {"label": "破绽", "short": "破", "color": Color(1.00, 0.76, 0.30)},
	"guard": {"label": "守势", "short": "守", "color": Color(0.92, 0.78, 0.42)}
}

var combat_system
var stage
var title_label: Label
var enemy_portrait: TextureRect
var enemy_bar: ProgressBar
var player_bar: ProgressBar
var enemy_status_box: HBoxContainer
var player_status_box: HBoxContainer
var status_label: Label
var body_label: Label
var action_grid: GridContainer
var effect_label: Label
var result_panel: Control
var result_title_label: Label
var result_body_label: Label
var result_rewards_label: Label
var result_next_label: Label
var last_snapshot: Dictionary = {}
var last_effect_event_id := 0
var effect_timer := 0.0
var _ink_burst_overlay: ColorRect
var _ink_burst_tween: Tween

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

	enemy_status_box = HBoxContainer.new()
	enemy_status_box.add_theme_constant_override("separation", 6)
	enemy_status_box.custom_minimum_size = Vector2(520, 25)
	enemy_status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_info.add_child(enemy_status_box)

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

	player_status_box = HBoxContainer.new()
	player_status_box.alignment = BoxContainer.ALIGNMENT_END
	player_status_box.add_theme_constant_override("separation", 6)
	player_status_box.custom_minimum_size = Vector2(238, 25)
	player_box.add_child(player_status_box)

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

	# 墨爆裂叠加层
	_ink_burst_overlay = ColorRect.new()
	_ink_burst_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ink_burst_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var burst_mat := ShaderMaterial.new()
	burst_mat.shader = INK_BURST_SHADER
	burst_mat.set_shader_parameter("intensity", 0.0)
	_ink_burst_overlay.material = burst_mat
	_ink_burst_overlay.color = Color.BLACK
	add_child(_ink_burst_overlay)

	_build_result_panel()

func _on_combat_started(enemy: Dictionary) -> void:
	title_label.text = "遭遇：%s" % str(enemy.get("name", "敌人"))
	last_snapshot = {}
	last_effect_event_id = 0
	if effect_label != null:
		effect_label.hide()
	if result_panel != null:
		result_panel.hide()
	if stage != null:
		stage.setup(enemy)
	_set_enemy_portrait(enemy)
	_refresh_status_chips({})
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
	_refresh_status_chips(snapshot)
	var lines: Array = snapshot.get("log", [])
	body_label.text = "\n".join(lines)
	if stage != null:
		stage.update_snapshot(snapshot)
	_play_latest_event(snapshot)
	_refresh_actions()

func _on_combat_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		EventBus.emit_toast("战斗胜利")
		AudioManager.play_sfx("skill_unlock")
	elif bool(result.get("escaped", false)):
		EventBus.emit_toast("已脱离战斗")
	else:
		EventBus.emit_toast("战败，回客栈休养")
	_show_result_panel(result)

func close_result_panel() -> void:
	if result_panel != null:
		result_panel.hide()
	if stage != null:
		stage.clear()
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func is_result_visible() -> bool:
	return result_panel != null and result_panel.visible

func _build_result_panel() -> void:
	result_panel = Control.new()
	result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	result_panel.hide()
	add_child(result_panel)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.012, 0.010, 0.54)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	result_panel.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -370.0
	panel.offset_top = -218.0
	panel.offset_right = 370.0
	panel.offset_bottom = 218.0
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(34, 26, 34, 26)))
	result_panel.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	result_title_label = Label.new()
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_title(result_title_label)
	box.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.custom_minimum_size = Vector2(650, 82)
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(result_body_label, 18)
	box.add_child(result_body_label)

	result_rewards_label = Label.new()
	result_rewards_label.custom_minimum_size = Vector2(650, 116)
	result_rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(result_rewards_label, 17)
	result_rewards_label.add_theme_color_override("font_color", Color(0.78, 0.93, 0.62))
	box.add_child(result_rewards_label)

	result_next_label = Label.new()
	result_next_label.custom_minimum_size = Vector2(650, 56)
	result_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(result_next_label, 16)
	result_next_label.add_theme_color_override("font_color", Color(0.86, 0.78, 0.60))
	box.add_child(result_next_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)

	var close_button := Button.new()
	close_button.text = "回到江湖"
	close_button.custom_minimum_size = Vector2(142, 42)
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_result_panel)
	actions.add_child(close_button)

func _show_result_panel(result: Dictionary) -> void:
	if result_panel == null:
		hide()
		GameState.set_mode(GameState.Mode.EXPLORE)
		return
	var enemy: Dictionary = result.get("enemy", {})
	var enemy_name := str(enemy.get("name", "敌人"))
	if bool(result.get("victory", false)):
		result_title_label.text = "战斗胜利"
		result_body_label.text = "击败 %s。\n气血 %d/%d  内力 %d/%d" % [
			enemy_name,
			int(result.get("player_hp", 0)),
			int(result.get("player_max_hp", 1)),
			int(result.get("player_mp", 0)),
			int(result.get("player_max_mp", 1))
		]
	elif bool(result.get("escaped", false)):
		result_title_label.text = "脱离战斗"
		result_body_label.text = "你从 %s 手下抽身，局势暂时缓了下来。" % enemy_name
	else:
		result_title_label.text = "战斗失利"
		result_body_label.text = "你被送回客栈休养。\n气血 %d/%d  内力 %d/%d" % [
			int(result.get("player_hp", 0)),
			int(result.get("player_max_hp", 1)),
			int(result.get("player_mp", 0)),
			int(result.get("player_max_mp", 1))
		]
	result_rewards_label.text = _result_reward_text(result)
	result_next_label.text = _result_next_text(result)
	result_panel.show()
	GameState.set_mode(GameState.Mode.COMBAT)

func _result_reward_text(result: Dictionary) -> String:
	if bool(result.get("victory", false)):
		var parts: Array[String] = []
		var exp_reward := int(result.get("exp_reward", 0))
		var money_delta := int(result.get("money_delta", result.get("money_reward", 0)))
		var pot_delta := int(result.get("pot_delta", 0))
		if exp_reward > 0:
			parts.append("阅历 +%d" % exp_reward)
		if pot_delta > 0:
			parts.append("潜能 +%d" % pot_delta)
		if money_delta > 0:
			parts.append("银两 +%d" % money_delta)
		var loot: Array = result.get("loot", [])
		if not loot.is_empty():
			parts.append("掉落：%s" % "、".join(loot))
		var level_before := int(result.get("level_before", 1))
		var level_after := int(result.get("level_after", level_before))
		if level_after > level_before:
			parts.append("等级 %d -> %d" % [level_before, level_after])
		var quests: Array = result.get("completed_quests", [])
		if not quests.is_empty():
			parts.append("完成任务：%s" % "、".join(quests))
		var wear_text := str(result.get("equipment_wear_text", ""))
		if not wear_text.is_empty():
			parts.append(wear_text)
		if parts.is_empty():
			return "已扫清阻碍。"
		return "\n".join(parts)
	if bool(result.get("escaped", false)):
		return "未结算战利。"
	return "客栈休养 4 时辰，气血与内力已恢复。"

func _result_next_text(result: Dictionary) -> String:
	var tracker := str(result.get("quest_tracker", ""))
	if tracker.is_empty():
		tracker = "下一步：自由探索江湖"
	return tracker

func _panel_style(_alpha: float = 0.94) -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(16, 14, 16, 14))

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
	UI_ART.apply_button(button)
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
	UI_ART.apply_button(button)
	var icon_path := GameData.get_skill_icon_path("kf_basic_dodge")
	if not icon_path.is_empty():
		button.icon = GameData.load_texture(icon_path)
		button.expand_icon = true
	button.pressed.connect(func() -> void:
		if combat_system != null:
			combat_system.flee()
	)
	action_grid.add_child(button)

func _refresh_status_chips(snapshot: Dictionary) -> void:
	if enemy_status_box == null or player_status_box == null:
		return
	_populate_status_box(enemy_status_box, snapshot.get("enemy_statuses", {}), false)
	_populate_status_box(player_status_box, snapshot.get("player_statuses", {}), true)

func _populate_status_box(box: HBoxContainer, statuses_value, align_right: bool) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var statuses: Dictionary = statuses_value if statuses_value is Dictionary else {}
	var added := 0
	for status_id in STATUS_ORDER:
		if not statuses.has(status_id):
			continue
		_add_status_chip(box, status_id, statuses.get(status_id, {}))
		added += 1
	for raw_status_id in statuses.keys():
		var status_id := str(raw_status_id)
		if STATUS_ORDER.has(status_id):
			continue
		_add_status_chip(box, status_id, statuses.get(raw_status_id, {}))
		added += 1
	if added == 0:
		_add_empty_status_chip(box, align_right)

func _add_status_chip(box: HBoxContainer, status_id: String, status_value) -> void:
	var status: Dictionary = status_value if status_value is Dictionary else {}
	var meta: Dictionary = STATUS_CHIP_META.get(status_id, {})
	var label := str(meta.get("label", status_id))
	var short := str(meta.get("short", label.substr(0, 1)))
	var turns: int = maxi(1, int(status.get("turns", 1)))
	var power := int(status.get("power", 0))
	var color: Color = meta.get("color", Color(0.78, 0.76, 0.68))
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(58, 25)
	chip.tooltip_text = _status_tooltip(label, status_id, turns, power)
	chip.add_theme_stylebox_override("panel", _status_chip_style(color))
	box.add_child(chip)

	var text := Label.new()
	text.text = "%s %d" % [short, turns]
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78))
	UI_ART.apply_label_shadow(text, 0.62)
	chip.add_child(text)

func _add_empty_status_chip(box: HBoxContainer, align_right: bool) -> void:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(70 if align_right else 82, 25)
	chip.tooltip_text = "当前没有持续状态"
	chip.add_theme_stylebox_override("panel", _status_chip_style(Color(0.54, 0.50, 0.42), true))
	box.add_child(chip)

	var text := Label.new()
	text.text = "无状态"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.66, 0.63, 0.55))
	UI_ART.apply_label_shadow(text, 0.40)
	chip.add_child(text)

func _status_tooltip(label: String, status_id: String, turns: int, power: int) -> String:
	if ["bleed", "poison", "burn"].has(status_id) and power > 0:
		return "%s：剩余 %d 回合，每回合 %d 点气血损失" % [label, turns, power]
	if status_id == "guard":
		return "%s：剩余 %d 回合，降低下一次承受伤害" % [label, turns]
	if status_id == "vulnerable":
		return "%s：剩余 %d 回合，下一次受击更重" % [label, turns]
	if status_id == "weaken":
		return "%s：剩余 %d 回合，出招伤害降低" % [label, turns]
	if status_id == "slow":
		return "%s：剩余 %d 回合，命中和脱身受影响" % [label, turns]
	return "%s：剩余 %d 回合" % [label, turns]

func _status_chip_style(color: Color, muted: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var alpha := 0.20 if muted else 0.30
	style.bg_color = Color(color.r * 0.34, color.g * 0.26, color.b * 0.22, alpha + 0.18)
	style.border_color = Color(color.r, color.g, color.b, 0.36 if muted else 0.72)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style

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

	# 打击视觉特效
	var mat := _ink_burst_overlay.material as ShaderMaterial
	if mat != null:
		if kind == "damage":
			# 墨爆裂
			var is_player_hit := target == "player"
			mat.set_shader_parameter("intensity", 1.0)
			mat.set_shader_parameter("burst_color", Color(0.78, 0.05, 0.04, 0.7) if is_player_hit else Color(0.03, 0.02, 0.01, 0.6))
			if _ink_burst_tween != null:
				_ink_burst_tween.kill()
			_ink_burst_tween = create_tween()
			_ink_burst_tween.tween_method(func(v): mat.set_shader_parameter("intensity", v), 1.0, 0.0, 0.6).set_ease(Tween.EASE_OUT)
			# 屏幕震动
			_screen_shake(4.0 if is_player_hit else 2.5, 0.18)
		elif kind == "miss":
			mat.set_shader_parameter("intensity", 0.0)

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

func _screen_shake(amount: float, duration: float) -> void:
	var orig := position
	var shake_tween := create_tween()
	shake_tween.tween_method(func(v: Vector2): position = v, orig, orig + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount, duration * 0.15).set_ease(Tween.EASE_IN)
	shake_tween.tween_method(func(v: Vector2): position = v, orig, orig + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * 0.5, duration * 0.15).set_ease(Tween.EASE_IN)
	shake_tween.tween_method(func(v: Vector2): position = v, orig, orig + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * 0.3, duration * 0.15).set_ease(Tween.EASE_IN)
	shake_tween.tween_callback(func(): position = orig)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or result_panel == null or not result_panel.visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		close_result_panel()
		get_viewport().set_input_as_handled()
