extends Control
class_name HudView

const MINIMAP_SCRIPT := preload("res://scripts/ui/minimap_canvas.gd")
const HUD_PROMPT_CHIP_MIN_WIDTH := 74.0
const HUD_PROMPT_PRIMARY_ALPHA := 0.88
const HUD_PROMPT_SECONDARY_ALPHA := 0.70

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var name_label: Label
var stats_label: Label
var equipment_label: Label
var quest_label: Label
var quest_hint_label: Label
var time_label: Label
var region_label: Label
var rumor_label: Label
var prompt_panel: PanelContainer
var prompt_box: HBoxContainer
var prompt_label: Label
var prompt_chips: Array[PanelContainer] = []
var last_prompt_text := ""
var toast_label: Label
var minimap
var region_banner_panel: PanelContainer
var region_banner_label: Label
var toast_timer := 0.0
var region_banner_timer := 0.0
var last_region_id := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_top_panel()
	_build_minimap()
	_build_prompt()
	_build_region_banner()
	_build_toast()
	EventBus.player_changed.connect(_on_player_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.quests_changed.connect(_on_quests_changed)
	EventBus.toast_requested.connect(show_toast)
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.region_changed.connect(_on_region_changed)
	EventBus.world_events_changed.connect(_on_world_events_changed)
	_on_player_changed(GameState.player)
	_on_time_changed(GameState.day, GameState.hour, GameState.weather)
	_on_region_changed(GameData.get_region(GameState.current_region_id), GameState.get_region_state(GameState.current_region_id))
	_on_world_events_changed(GameState.get_recent_world_events(1))

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		toast_label.modulate.a = min(1.0, toast_timer)
		if toast_timer <= 0.0:
			toast_label.hide()
	if region_banner_timer > 0.0:
		region_banner_timer -= delta
		region_banner_panel.modulate.a = min(1.0, region_banner_timer)
		if region_banner_timer <= 0.0:
			region_banner_panel.hide()

func set_prompt(text: String) -> void:
	if text == last_prompt_text:
		return
	last_prompt_text = text
	prompt_label.text = text
	if prompt_panel == null or prompt_box == null:
		prompt_label.visible = not text.is_empty()
		return
	var segments := _prompt_segments(text)
	_refresh_prompt_chips(segments)
	prompt_panel.visible = not text.is_empty()
	prompt_label.visible = segments.is_empty() and not text.is_empty()

func show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.show()
	toast_timer = 3.0

func _build_top_panel() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(16, 16)
	panel.size = Vector2(460, 226)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.050, 0.040, 0.72), Color(0.62, 0.48, 0.24, 0.55)))
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
	hp_bar.add_theme_stylebox_override("background", _bar_background())
	hp_bar.add_theme_stylebox_override("fill", _bar_fill(Color(0.64, 0.10, 0.08, 0.92), Color(0.94, 0.34, 0.22, 0.96)))
	box.add_child(hp_bar)

	mp_bar = ProgressBar.new()
	mp_bar.custom_minimum_size = Vector2(360, 18)
	mp_bar.show_percentage = false
	mp_bar.add_theme_stylebox_override("background", _bar_background())
	mp_bar.add_theme_stylebox_override("fill", _bar_fill(Color(0.08, 0.24, 0.54, 0.90), Color(0.32, 0.62, 0.96, 0.96)))
	box.add_child(mp_bar)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	box.add_child(stats_label)

	equipment_label = Label.new()
	equipment_label.add_theme_font_size_override("font_size", 14)
	equipment_label.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	box.add_child(equipment_label)

	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 15)
	quest_label.add_theme_color_override("font_color", Color(0.70, 0.86, 0.68))
	box.add_child(quest_label)

	quest_hint_label = Label.new()
	quest_hint_label.custom_minimum_size = Vector2(410, 20)
	quest_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_hint_label.add_theme_font_size_override("font_size", 14)
	quest_hint_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.42))
	box.add_child(quest_hint_label)

	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	box.add_child(time_label)

	region_label = Label.new()
	region_label.add_theme_font_size_override("font_size", 14)
	region_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.70))
	box.add_child(region_label)

	rumor_label = Label.new()
	rumor_label.custom_minimum_size = Vector2(410, 34)
	rumor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor_label.add_theme_font_size_override("font_size", 13)
	rumor_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.54))
	box.add_child(rumor_label)

func _build_minimap() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -300
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = 222
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.042, 0.034, 0.72), Color(0.62, 0.48, 0.24, 0.55)))
	add_child(panel)

	minimap = MINIMAP_SCRIPT.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(minimap)

func _build_prompt() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.anchor_left = 0.0
	prompt_panel.anchor_right = 1.0
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = 16
	prompt_panel.offset_right = -16
	prompt_panel.offset_top = -76
	prompt_panel.offset_bottom = -18
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.040, 0.035, 0.028, 0.74), Color(0.66, 0.50, 0.24, 0.58)))
	add_child(prompt_panel)

	prompt_box = HBoxContainer.new()
	prompt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	prompt_box.add_theme_constant_override("separation", 8)
	prompt_panel.add_child(prompt_box)

	prompt_label = Label.new()
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
	prompt_box.add_child(prompt_label)
	prompt_label.hide()
	prompt_panel.hide()

func _build_region_banner() -> void:
	region_banner_panel = PanelContainer.new()
	region_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_banner_panel.anchor_left = 0.5
	region_banner_panel.anchor_right = 0.5
	region_banner_panel.offset_left = -230
	region_banner_panel.offset_right = 230
	region_banner_panel.offset_top = 76
	region_banner_panel.offset_bottom = 124
	region_banner_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.049, 0.038, 0.80), Color(0.78, 0.58, 0.26, 0.62)))
	add_child(region_banner_panel)

	region_banner_label = Label.new()
	region_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_banner_label.add_theme_font_size_override("font_size", 17)
	region_banner_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.50))
	region_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	region_banner_label.add_theme_constant_override("shadow_offset_x", 1)
	region_banner_label.add_theme_constant_override("shadow_offset_y", 2)
	region_banner_panel.add_child(region_banner_label)
	region_banner_panel.hide()

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
	_refresh_equipment_label()
	_refresh_quest_labels()

func _on_inventory_changed(_inventory: Dictionary) -> void:
	_refresh_equipment_label()

func _refresh_equipment_label() -> void:
	if equipment_label == null:
		return
	equipment_label.text = "装备：%s  %s" % [
		_equipment_status_part("weapon", "武"),
		_equipment_status_part("armor", "防")
	]

func _equipment_status_part(slot: String, short_name: String) -> String:
	var item_id := str(GameState.equipment.get(slot, ""))
	if item_id.is_empty():
		return "%s 无" % short_name
	var item := GameData.get_item(item_id)
	var durability := GameState.get_equipment_durability(item_id)
	var condition := GameState.get_equipment_condition_label(item_id)
	var repair_cost := GameState.get_equipment_repair_cost(item_id)
	var repair_text := "" if repair_cost <= 0 else "·修%d两" % repair_cost
	return "%s %s %d%%·%s%s" % [
		short_name,
		str(item.get("name", item_id)),
		durability,
		condition,
		repair_text
	]

func _on_quests_changed() -> void:
	_refresh_quest_labels()

func _refresh_quest_labels() -> void:
	if quest_label != null:
		quest_label.text = "当前目标：%s" % GameState.get_active_quest_tracker()
	if quest_hint_label != null:
		quest_hint_label.text = GameState.get_active_story_quest_hint()

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
	var danger_text := _danger_text(danger)
	var exploration := int(state.get("exploration", 0))
	var exploration_title := GameState.get_exploration_title_for_value(exploration)
	region_label.text = "所在地：%s  探索 %d%%·%s  %s" % [
		str(region.get("name", region.get("id", ""))),
		exploration,
		exploration_title,
		danger_text
	]
	var region_id := str(region.get("id", ""))
	if not region_id.is_empty() and region_id != last_region_id:
		last_region_id = region_id
		_show_region_banner(region, state)

func _on_world_events_changed(events: Array) -> void:
	if rumor_label == null:
		return
	if events.is_empty():
		rumor_label.text = "江湖传闻：暂无"
		return
	var latest: Dictionary = events[events.size() - 1]
	var title := str(latest.get("title", "传闻"))
	var description := str(latest.get("description", ""))
	if description.length() > 26:
		description = "%s..." % description.substr(0, 26)
	var suffix := ""
	if not description.is_empty():
		suffix = " · %s" % description
	rumor_label.text = "江湖传闻：%s%s" % [
		title,
		suffix
	]

func _prompt_segments(text: String) -> Array:
	var segments: Array = []
	var normalized := text.strip_edges()
	if normalized.is_empty():
		return segments
	var tokens := normalized.split(" ", false)
	var current_key := ""
	var current_words := PackedStringArray()
	for raw_token in tokens:
		var token := str(raw_token).strip_edges()
		if token.is_empty():
			continue
		if _is_prompt_key_token(token):
			if not current_key.is_empty() or not current_words.is_empty():
				segments.append({
					"key": current_key,
					"label": " ".join(current_words).strip_edges()
				})
			current_key = token
			current_words = PackedStringArray()
		else:
			current_words.append(token)
	if not current_key.is_empty() or not current_words.is_empty():
		segments.append({
			"key": current_key,
			"label": " ".join(current_words).strip_edges()
		})
	return segments

func _is_prompt_key_token(token: String) -> bool:
	match token:
		"E", "T", "F", "B", "J", "K", "M", "Esc", "F5/F9", "Enter":
			return true
	return false

func _refresh_prompt_chips(segments: Array) -> void:
	if prompt_box == null:
		return
	for chip in prompt_chips:
		if is_instance_valid(chip):
			prompt_box.remove_child(chip)
			chip.queue_free()
	prompt_chips.clear()
	if segments.is_empty():
		return
	for i in range(segments.size()):
		var segment: Dictionary = segments[i]
		var chip := _make_prompt_chip(str(segment.get("key", "")), str(segment.get("label", "")), i == 0)
		prompt_box.add_child(chip)
		prompt_chips.append(chip)

func _make_prompt_chip(key: String, label_text: String, primary: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.custom_minimum_size = Vector2(HUD_PROMPT_CHIP_MIN_WIDTH + clampf(float(label_text.length()) * 9.5, 28.0, 170.0), 32)
	chip.add_theme_stylebox_override("panel", _prompt_chip_style(primary))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 7)
	chip.add_child(row)

	var key_badge := PanelContainer.new()
	key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_badge.custom_minimum_size = Vector2(maxf(32.0, float(key.length()) * 9.0 + 18.0), 22)
	key_badge.add_theme_stylebox_override("panel", _prompt_key_style(primary))
	row.add_child(key_badge)

	var key_label := Label.new()
	key_label.text = key
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.58))
	key_badge.add_child(key_label)

	var value_label := Label.new()
	value_label.text = label_text
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_label.add_theme_font_size_override("font_size", 15 if primary else 14)
	value_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68) if primary else Color(0.78, 0.80, 0.72))
	row.add_child(value_label)
	return chip

func _show_region_banner(region: Dictionary, state: Dictionary) -> void:
	if region_banner_panel == null or region_banner_label == null:
		return
	region_banner_label.text = "进入 %s  ·  %s  ·  %s  ·  探索 %d%%" % [
		str(region.get("name", region.get("id", ""))),
		_region_type_name(str(region.get("type", "wild"))),
		_danger_text(int(region.get("danger", 0))),
		int(state.get("exploration", 0))
	]
	region_banner_panel.modulate.a = 1.0
	region_banner_panel.show()
	region_banner_timer = 2.6

func _region_type_name(region_type: String) -> String:
	match region_type:
		"city":
			return "城池"
		"town":
			return "小镇"
		"sect":
			return "门派"
		_:
			return "野外"

func _danger_text(danger: int) -> String:
	if danger >= 4:
		return "险地"
	if danger >= 3:
		return "危险"
	if danger >= 2:
		return "谨慎"
	return "安全"

func _prompt_chip_style(primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var alpha := HUD_PROMPT_PRIMARY_ALPHA if primary else HUD_PROMPT_SECONDARY_ALPHA
	style.bg_color = Color(0.075, 0.064, 0.044, alpha)
	style.border_color = Color(0.78, 0.56, 0.24, 0.72 if primary else 0.42)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _prompt_key_style(primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.14, 0.065, 0.90 if primary else 0.72)
	style.border_color = Color(0.95, 0.70, 0.30, 0.64 if primary else 0.38)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

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

func _bar_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.018, 0.014, 0.78)
	style.border_color = Color(0.44, 0.35, 0.20, 0.45)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _bar_fill(base: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base
	style.border_color = edge
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
