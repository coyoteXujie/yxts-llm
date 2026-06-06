extends Node2D
class_name NpcActor

var data: Dictionary = {}
var highlighted := false
var tile_size := 48
var name_label: Label
var ambient_panel: PanelContainer
var ambient_label: Label
var sprite_node: Sprite2D
var sprite_outline_node: Sprite2D
var sprite_rim_node: Sprite2D
var stage_pose_line_node: Line2D
var stage_weapon_glow_node: Line2D
var stage_torso_line_node: Line2D
var stage_sash_line_node: Line2D
var stage_front_limb_line_node: Line2D
var stage_back_limb_line_node: Line2D
var stage_guard_line_node: Line2D
var using_sprite_asset := false
var ambient_timer := 0.0
var visual_phase := 0.0
var sprite_base_scale := Vector2.ONE
var sprite_outline_base_scale := Vector2.ONE
var sprite_rim_base_scale := Vector2.ONE
var sprite_base_position := Vector2.ZERO
var sprite_outline_base_position := Vector2.ZERO
var sprite_rim_base_position := Vector2.ZERO

const USE_FULL_SPRITES_ON_MAP := true
const MAP_ACTOR_SCALE := 0.92
const BASE_SPRITE_HEIGHT := 118.0
const MASTER_SPRITE_HEIGHT := 146.0
const ENEMY_SPRITE_HEIGHT := 142.0
const STAGE_PRESENCE_SCALE := 1.38
const STAGE_MASTER_EXTRA_SCALE := 1.09
const STAGE_ENEMY_EXTRA_SCALE := 1.11
const STAGE_SPRITE_MIN_SCALE := 1.22
const STAGE_SPRITE_MAX_SCALE := 1.74
const CONTACT_GLOW_ALPHA := 0.115
const STAGE_RIM_ALPHA := 0.15
const STAGE_ROLE_CUE_ALPHA := 0.18
const STAGE_IDENTITY_MOTES := 6
const STAGE_POSE_LINE_ALPHA := 0.30
const STAGE_FOOT_ANCHOR_ALPHA := 0.22
const STAGE_GROUND_LOCK_ALPHA := 0.24
const STAGE_TORSO_LINE_ALPHA := 0.24
const STAGE_SASH_LINE_ALPHA := 0.22
const STAGE_WEAPON_GLOW_ALPHA := 0.24
const STAGE_LIMB_POSE_ALPHA := 0.27
const STAGE_STEP_SWEEP_ALPHA := 0.20
const STAGE_IDLE_GUARD_ALPHA := 0.18
const STAGE_ROLE_STANCE_SWAY_PIXELS := 2.8
const STAGE_ACTIVITY_CUE_ALPHA := 0.26
const STAGE_ACTIVITY_SWAY_PIXELS := 4.8
const STAGE_ACTIVITY_PROP_SCALE := 1.0
const STAGE_ACTIVITY_GLOW_ALPHA := 0.18
const STAGE_LANE_LOCK_ALPHA := 0.20
const STAGE_LANE_MAX_VISUAL_OFFSET := 22.0
const STAGE_FACING_CUE_ALPHA := 0.18
const AMBIENT_BUBBLE_WIDTH := 172.0

func setup(new_data: Dictionary, new_tile_size: int) -> void:
	data = new_data
	tile_size = new_tile_size
	name = str(data.get("name", "NPC"))
	position = Vector2((float(data.get("pos_x", 0)) + 0.5) * tile_size, (float(data.get("pos_y", 0)) + 0.5) * tile_size) + _visual_offset()
	z_index = int(position.y)
	if is_enemy():
		add_to_group("enemies")
	add_to_group("npcs")
	_ensure_label()
	_refresh_label_visibility()
	_refresh_sprite_asset()
	queue_redraw()

func _ready() -> void:
	set_process(true)
	if data.is_empty():
		z_index = int(position.y)
	_ensure_label()
	_refresh_label_visibility()
	if not data.is_empty():
		_refresh_sprite_asset()

func _process(delta: float) -> void:
	visual_phase += delta * _idle_motion_speed()
	_update_sprite_motion()
	queue_redraw()
	if ambient_panel != null and ambient_panel.visible:
		ambient_timer -= delta
		if ambient_timer <= 0.0:
			clear_ambient_line()
			return
		var fade := clampf(ambient_timer / 0.65, 0.0, 1.0)
		ambient_panel.modulate.a = fade if ambient_timer < 0.65 else 1.0

func is_enemy() -> bool:
	return str(data.get("npc_type", "normal")) == "enemy"

func is_master() -> bool:
	return bool(data.get("is_master", false)) or str(data.get("npc_type", "normal")) == "master"

func set_highlight(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	_refresh_label_visibility()
	queue_redraw()

func show_ambient_line(line: String, duration: float = 5.2) -> void:
	line = line.strip_edges()
	if line.is_empty():
		return
	_ensure_ambient_bubble()
	ambient_label.text = _trim_ambient_line(line)
	ambient_panel.position = _ambient_bubble_position()
	ambient_panel.modulate.a = 1.0
	ambient_panel.show()
	ambient_timer = duration

func clear_ambient_line() -> void:
	ambient_timer = 0.0
	if ambient_panel != null:
		ambient_panel.hide()

func has_active_ambient_line() -> bool:
	return ambient_panel != null and ambient_panel.visible and ambient_timer > 0.0

func _ensure_label() -> void:
	if name_label != null:
		name_label.text = str(data.get("name", "NPC"))
		return
	name_label = Label.new()
	name_label.text = str(data.get("name", "NPC"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-58, -78)
	name_label.size = Vector2(116, 22)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.89, 0.76))
	name_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.z_index = 3
	add_child(name_label)
	_refresh_label_visibility()

func _ensure_ambient_bubble() -> void:
	if ambient_panel != null:
		return
	ambient_panel = PanelContainer.new()
	ambient_panel.hide()
	ambient_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_panel.z_index = 5
	ambient_panel.custom_minimum_size = Vector2(AMBIENT_BUBBLE_WIDTH, 0)
	ambient_panel.add_theme_stylebox_override("panel", _ambient_bubble_style())
	add_child(ambient_panel)

	ambient_label = Label.new()
	ambient_label.custom_minimum_size = Vector2(AMBIENT_BUBBLE_WIDTH - 18.0, 0)
	ambient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ambient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ambient_label.add_theme_font_size_override("font_size", 13)
	ambient_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.78))
	ambient_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.025, 0.02, 0.82))
	ambient_label.add_theme_constant_override("shadow_offset_x", 1)
	ambient_label.add_theme_constant_override("shadow_offset_y", 1)
	ambient_panel.add_child(ambient_label)

func _ambient_bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.045, 0.035, 0.86)
	style.border_color = Color(0.78, 0.58, 0.32, 0.62)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _ambient_bubble_position() -> Vector2:
	var map_scale := _map_actor_scale()
	var y := -142.0 * map_scale
	if is_master():
		y -= 14.0
	return Vector2(-AMBIENT_BUBBLE_WIDTH * 0.5, y)

func _trim_ambient_line(line: String) -> String:
	if line.length() <= 34:
		return line
	return "%s..." % line.substr(0, 34)

func _refresh_label_visibility() -> void:
	if name_label == null:
		return
	name_label.visible = highlighted

func _visual_offset() -> Vector2:
	var npc_id := int(data.get("id", 0))
	var ox := float(((npc_id * 37) % 15) - 7)
	var oy := float(((npc_id * 53) % 11) - 5)
	if is_master() or is_enemy():
		oy *= 0.6
	return Vector2(ox, oy)

func _map_actor_scale() -> float:
	var value := float(data.get("map_actor_scale", 1.0))
	if _is_stage_actor():
		var scale := value * STAGE_PRESENCE_SCALE
		if is_master():
			scale *= STAGE_MASTER_EXTRA_SCALE
		elif is_enemy():
			scale *= STAGE_ENEMY_EXTRA_SCALE
		return clampf(scale, STAGE_SPRITE_MIN_SCALE, STAGE_SPRITE_MAX_SCALE)
	return clampf(value, 0.55, 1.25)

func _is_stage_actor() -> bool:
	return bool(data.get("stage_actor", false))

func _stage_lane_visual_offset() -> float:
	if not _is_stage_actor():
		return 0.0
	var strength := clampf(float(data.get("stage_lane_strength", 0.0)), 0.0, 1.0)
	return clampf(
		float(data.get("stage_lane_offset_y", 0.0)) * strength * 0.36,
		-STAGE_LANE_MAX_VISUAL_OFFSET,
		STAGE_LANE_MAX_VISUAL_OFFSET
	)

func _stage_facing_side() -> float:
	if data.has("stage_facing_side"):
		var side := float(data.get("stage_facing_side", 1.0))
		return -1.0 if side < 0.0 else 1.0
	return -1.0 if int(data.get("id", 0)) % 2 == 0 else 1.0

func _refresh_sprite_asset() -> void:
	if not bool(data.get("use_map_sprite", USE_FULL_SPRITES_ON_MAP)):
		_clear_sprite_asset()
		return
	var sprite_path := GameData.get_npc_sprite_path(str(data.get("name", "")))
	if sprite_path.is_empty():
		_clear_sprite_asset()
		return
	var texture := GameData.load_texture(sprite_path, true)
	if texture == null:
		_clear_sprite_asset()
		return
	if sprite_outline_node == null:
		sprite_outline_node = Sprite2D.new()
		sprite_outline_node.centered = true
		sprite_outline_node.z_index = 1
		sprite_outline_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite_outline_node.modulate = Color(0.02, 0.018, 0.014, 0.62)
		add_child(sprite_outline_node)
	if sprite_node == null:
		sprite_node = Sprite2D.new()
		sprite_node.centered = true
		sprite_node.z_index = 2
		sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite_node)
	if sprite_rim_node == null:
		sprite_rim_node = Sprite2D.new()
		sprite_rim_node.centered = true
		sprite_rim_node.z_index = 3
		sprite_rim_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite_rim_node)
	if stage_torso_line_node == null:
		stage_torso_line_node = Line2D.new()
		stage_torso_line_node.z_index = 4
		stage_torso_line_node.width = 2.0
		stage_torso_line_node.antialiased = true
		stage_torso_line_node.visible = false
		add_child(stage_torso_line_node)
	if stage_sash_line_node == null:
		stage_sash_line_node = Line2D.new()
		stage_sash_line_node.z_index = 5
		stage_sash_line_node.width = 2.0
		stage_sash_line_node.antialiased = true
		stage_sash_line_node.visible = false
		add_child(stage_sash_line_node)
	if stage_back_limb_line_node == null:
		stage_back_limb_line_node = Line2D.new()
		stage_back_limb_line_node.z_index = 4
		stage_back_limb_line_node.width = 2.0
		stage_back_limb_line_node.antialiased = true
		stage_back_limb_line_node.visible = false
		add_child(stage_back_limb_line_node)
	if stage_front_limb_line_node == null:
		stage_front_limb_line_node = Line2D.new()
		stage_front_limb_line_node.z_index = 6
		stage_front_limb_line_node.width = 2.0
		stage_front_limb_line_node.antialiased = true
		stage_front_limb_line_node.visible = false
		add_child(stage_front_limb_line_node)
	if stage_guard_line_node == null:
		stage_guard_line_node = Line2D.new()
		stage_guard_line_node.z_index = 7
		stage_guard_line_node.width = 1.5
		stage_guard_line_node.antialiased = true
		stage_guard_line_node.visible = false
		add_child(stage_guard_line_node)
	if stage_weapon_glow_node == null:
		stage_weapon_glow_node = Line2D.new()
		stage_weapon_glow_node.z_index = 5
		stage_weapon_glow_node.width = 4.0
		stage_weapon_glow_node.antialiased = true
		stage_weapon_glow_node.visible = false
		add_child(stage_weapon_glow_node)
	if stage_pose_line_node == null:
		stage_pose_line_node = Line2D.new()
		stage_pose_line_node.z_index = 6
		stage_pose_line_node.width = 2.0
		stage_pose_line_node.antialiased = true
		stage_pose_line_node.visible = false
		add_child(stage_pose_line_node)
	sprite_outline_node.texture = texture
	sprite_node.texture = texture
	sprite_rim_node.texture = texture
	var texture_size: Vector2 = texture.get_size()
	var target_height := BASE_SPRITE_HEIGHT
	var target_width := 80.0
	if is_master():
		target_height = MASTER_SPRITE_HEIGHT
		target_width = 88.0
	if is_enemy():
		target_height = ENEMY_SPRITE_HEIGHT
		target_width = 86.0
	if str(data.get("name", "")) == "神秘人":
		target_height = 114.0
		target_width = 96.0
	var map_scale := _map_actor_scale()
	var appearance := GameData.get_npc_appearance(data)
	var accent := _color(appearance.get("accent", [0.78, 0.62, 0.32]), Color(0.78, 0.62, 0.32))
	var rim_color := _stage_role_color(accent)
	target_height *= map_scale
	target_width *= map_scale
	var factor: float = min(target_height / max(texture_size.y, 1.0), target_width / max(texture_size.x, 1.0))
	sprite_outline_base_scale = Vector2.ONE * factor * 1.05
	sprite_outline_base_position = Vector2(0, -9 * map_scale + 1.4)
	sprite_outline_node.scale = sprite_outline_base_scale
	sprite_outline_node.position = sprite_outline_base_position
	sprite_outline_node.visible = true
	sprite_base_scale = Vector2.ONE * factor
	sprite_base_position = Vector2(0, -9 * map_scale)
	sprite_node.scale = sprite_base_scale
	sprite_node.position = sprite_base_position
	sprite_node.visible = true
	sprite_rim_base_scale = Vector2.ONE * factor * 1.015
	sprite_rim_base_position = Vector2(1.4 * map_scale, -10.2 * map_scale)
	sprite_rim_node.scale = sprite_rim_base_scale
	sprite_rim_node.position = sprite_rim_base_position
	sprite_rim_node.modulate = Color(rim_color.r, rim_color.g, rim_color.b, STAGE_RIM_ALPHA)
	sprite_rim_node.visible = _is_stage_actor()
	using_sprite_asset = true
	if name_label != null:
		name_label.z_index = 8
		name_label.position = Vector2(-58, -100 * map_scale)
	_update_sprite_motion()

func _clear_sprite_asset() -> void:
	using_sprite_asset = false
	if sprite_outline_node != null:
		sprite_outline_node.visible = false
	if sprite_node != null:
		sprite_node.visible = false
	if sprite_rim_node != null:
		sprite_rim_node.visible = false
	if stage_pose_line_node != null:
		stage_pose_line_node.visible = false
	if stage_weapon_glow_node != null:
		stage_weapon_glow_node.visible = false
	if stage_torso_line_node != null:
		stage_torso_line_node.visible = false
	if stage_sash_line_node != null:
		stage_sash_line_node.visible = false
	if stage_front_limb_line_node != null:
		stage_front_limb_line_node.visible = false
	if stage_back_limb_line_node != null:
		stage_back_limb_line_node.visible = false
	if stage_guard_line_node != null:
		stage_guard_line_node.visible = false

func _draw() -> void:
	var appearance := GameData.get_npc_appearance(data)
	var primary := _color(appearance.get("primary", [0.54, 0.46, 0.34]), Color(0.54, 0.46, 0.34))
	var secondary := _color(appearance.get("secondary", [0.24, 0.20, 0.16]), Color(0.24, 0.20, 0.16))
	var accent := _color(appearance.get("accent", [0.78, 0.62, 0.32]), Color(0.78, 0.62, 0.32))
	var ink := Color(0.07, 0.06, 0.05)

	if using_sprite_asset:
		var map_scale := _map_actor_scale()
		var lane_offset := _stage_lane_visual_offset()
		_draw_ground_marker(accent, lane_offset)
		_draw_actor_shadow(Vector2(3, 25 * map_scale + lane_offset * 0.82), Vector2(23.0 * map_scale, 6.8 * map_scale), 0.96)
		_draw_stage_ground_lock(accent, map_scale, lane_offset)
		_draw_contact_light(accent, map_scale, lane_offset)
		_draw_stage_foot_anchors(accent, map_scale, lane_offset)
		_draw_aura(appearance, accent)
		_draw_stage_identity_cues(appearance, accent, map_scale)
		_draw_stage_activity_cue(accent, map_scale)
		if highlighted:
			draw_arc(Vector2.ZERO, 32.0 * map_scale, 0.0, TAU, 48, Color(0.95, 0.74, 0.28, 0.95), 2.4)
			draw_circle(Vector2(0, 31 * map_scale), 3.0, Color(0.95, 0.74, 0.28, 0.95))
		return

	var skin := _color(appearance.get("skin", [0.84, 0.68, 0.52]), Color(0.84, 0.68, 0.52))
	var scale := _build_scale(str(appearance.get("build", "standard"))) * MAP_ACTOR_SCALE * _map_actor_scale()

	_draw_ground_marker(accent)
	_draw_actor_shadow(Vector2(3, 20 * MAP_ACTOR_SCALE), Vector2(17.0 * max(scale.x, 1.0), 5.0 * max(scale.y, 0.9)), 0.82)
	_draw_contact_light(accent, _map_actor_scale())

	draw_set_transform(Vector2.ZERO, 0.0, scale)
	_draw_aura(appearance, accent)
	_draw_prop_back(str(appearance.get("prop", "none")), secondary, accent, ink)
	_draw_legs(str(appearance.get("outfit", "short_robe")), secondary, ink)
	_draw_outfit(str(appearance.get("outfit", "short_robe")), primary, secondary, accent, ink)
	_draw_arms(str(appearance.get("outfit", "short_robe")), primary, secondary, skin, ink)
	_draw_head(str(appearance.get("head", "oval")), skin, ink)
	_draw_face(str(appearance.get("motif", "none")), ink)
	_draw_hair(str(appearance.get("hair", "topknot")), ink, secondary)
	_draw_hat(str(appearance.get("hat", "none")), primary, secondary, accent, ink)
	_draw_prop_front(str(appearance.get("prop", "none")), primary, secondary, accent, ink)
	_draw_motif(str(appearance.get("motif", "none")), accent, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if highlighted:
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color(0.95, 0.74, 0.28, 0.95), 2.4)
		draw_circle(Vector2(0, 27), 3.0, Color(0.95, 0.74, 0.28, 0.95))

func _draw_ground_marker(accent: Color, lane_offset_y: float = 0.0) -> void:
	var map_scale := _map_actor_scale()
	var npc_id := int(data.get("id", 0))
	var pulse := 0.5 + 0.5 * sin(visual_phase + float(npc_id % 17) * 0.37)
	var marker_radius := Vector2(15 * map_scale, 4.5 * map_scale) * (1.0 + pulse * 0.05)
	var color := Color(accent.r, accent.g, accent.b, 0.18 + pulse * 0.05)
	if bool(data.get("has_quests", false)):
		color = Color(0.95, 0.72, 0.22, 0.30 + pulse * 0.10)
	elif is_master():
		color = Color(accent.r, accent.g, accent.b, 0.27 + pulse * 0.08)
	elif is_enemy():
		color = Color(0.76, 0.12, 0.09, 0.27 + pulse * 0.08)
	_draw_ellipse(Vector2(0, 26 * map_scale + lane_offset_y * 0.70), marker_radius, color)
	if bool(data.get("has_quests", false)):
		var quest_pos := Vector2(17 * map_scale, -50 * map_scale)
		draw_arc(quest_pos, 6.0 + pulse * 3.5, 0.0, TAU, 24, Color(0.98, 0.78, 0.28, 0.30 + pulse * 0.22), 1.2)
		draw_circle(quest_pos, 3.6 + pulse * 0.8, Color(0.98, 0.78, 0.28, 0.92))

func _idle_motion_speed() -> float:
	if is_enemy():
		return 1.35
	if is_master():
		return 0.95
	return 1.10

func _update_sprite_motion() -> void:
	if not using_sprite_asset or sprite_node == null or sprite_outline_node == null:
		return
	var npc_id := int(data.get("id", 0))
	var phase := visual_phase + float(npc_id % 29) * 0.31
	var wave := sin(phase)
	var soft_step := sin(phase * 0.55)
	var stage_motion := 1.30 if _is_stage_actor() else 1.0
	var lane_offset := _stage_lane_visual_offset()
	var height_pulse := 1.0 + wave * ((0.015 if is_enemy() else 0.021) if _is_stage_actor() else (0.010 if is_enemy() else 0.014))
	var width_pulse := 1.0 - wave * (0.007 if _is_stage_actor() else 0.004)
	var float_y := wave * (0.36 if is_master() else 0.48) * stage_motion
	var sway_x := soft_step * (0.38 if is_master() else 0.55) * stage_motion
	var stance_roll := sin(phase * 0.37) * (0.014 if _is_stage_actor() else 0.003)
	sprite_node.scale = sprite_base_scale * Vector2(width_pulse, height_pulse)
	sprite_outline_node.scale = sprite_outline_base_scale * Vector2(width_pulse, height_pulse)
	sprite_node.position = sprite_base_position + Vector2(sway_x, float_y + lane_offset * 0.55)
	sprite_outline_node.position = sprite_outline_base_position + Vector2(sway_x, float_y + lane_offset * 0.55 + 0.25)
	sprite_node.rotation = stance_roll
	sprite_outline_node.rotation = stance_roll
	if sprite_rim_node != null:
		var rim_color := _stage_role_color(_color(GameData.get_npc_appearance(data).get("accent", [0.78, 0.62, 0.32]), Color(0.78, 0.62, 0.32)))
		var rim_alpha := STAGE_RIM_ALPHA * (0.68 + absf(wave) * 0.32)
		sprite_rim_node.scale = sprite_rim_base_scale * Vector2(width_pulse + 0.006, height_pulse + 0.004)
		sprite_rim_node.position = sprite_rim_base_position + Vector2(sway_x + 0.35 * stage_motion, float_y + lane_offset * 0.55 - 0.25)
		sprite_rim_node.rotation = stance_roll
		sprite_rim_node.modulate = Color(rim_color.r, rim_color.g, rim_color.b, rim_alpha)
		sprite_rim_node.visible = _is_stage_actor()
	_update_stage_pose_line(phase, wave, stage_motion, lane_offset * 0.55)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)

func _draw_actor_shadow(center: Vector2, radius: Vector2, strength: float) -> void:
	var hour := float(GameState.hour)
	var noon_factor := clampf(1.0 - absf(hour - 12.0) / 8.0, 0.0, 1.0)
	var stretch := 1.0 + (1.0 - noon_factor) * 0.38
	var offset := Vector2(5.0 + (12.0 - hour) * 0.38, 1.8)
	_draw_ellipse(center + offset, Vector2(radius.x * stretch, radius.y * 1.10), Color(0.0, 0.0, 0.0, 0.070 * strength))
	_draw_ellipse(center + Vector2(1.5, 0.5), radius, Color(0.0, 0.0, 0.0, 0.18 * strength))
	_draw_ellipse(center, radius * Vector2(0.58, 0.48), Color(0.0, 0.0, 0.0, 0.13 * strength))

func _draw_stage_ground_lock(accent: Color, map_scale: float, lane_offset_y: float = 0.0) -> void:
	if not _is_stage_actor():
		return
	var npc_id := int(data.get("id", 0))
	var pulse := 0.5 + sin(visual_phase * 1.18 + float(npc_id % 23) * 0.27) * 0.5
	var role_color := _stage_role_color(accent)
	var alpha := STAGE_GROUND_LOCK_ALPHA * (0.60 + pulse * 0.28)
	var center := Vector2(2.0 * map_scale, 30.0 * map_scale + lane_offset_y)
	if float(data.get("stage_lane_strength", 0.0)) > 0.02:
		var lane_alpha := STAGE_LANE_LOCK_ALPHA * clampf(float(data.get("stage_lane_strength", 0.0)), 0.0, 1.0) * (0.72 + pulse * 0.18)
		var raw_center := Vector2(2.0 * map_scale, 30.0 * map_scale)
		draw_line(
			Vector2(-36.0 * map_scale, center.y - 1.5),
			Vector2(39.0 * map_scale, center.y - 2.8),
			Color(role_color.r, role_color.g, role_color.b, lane_alpha),
			1.0 + map_scale * 0.18
		)
		if absf(lane_offset_y) > 2.0:
			draw_line(raw_center, center, Color(1.0, 0.84, 0.45, lane_alpha * 0.34), 1.0)
	_draw_ellipse(center, Vector2(31.0 * map_scale, 4.2 * map_scale), Color(0.0, 0.0, 0.0, alpha))
	_draw_ellipse(center + Vector2(0.0, 1.4 * map_scale), Vector2(17.0 * map_scale, 2.1 * map_scale), Color(role_color.r, role_color.g, role_color.b, alpha * 0.36))
	draw_line(
		center + Vector2(-19.0, -1.2) * map_scale,
		center + Vector2(21.0, -2.0 + pulse * 0.8) * map_scale,
		Color(1.0, 0.84, 0.45, alpha * 0.32),
		1.0 + map_scale * 0.18
	)

func _draw_stage_foot_anchors(accent: Color, map_scale: float, lane_offset_y: float = 0.0) -> void:
	if not _is_stage_actor():
		return
	var npc_id := int(data.get("id", 0))
	var phase := visual_phase * 0.88 + float(npc_id % 19) * 0.29
	var step := sin(phase)
	var y := 28.5 * map_scale + lane_offset_y
	var spread := (10.8 if is_enemy() else 9.2) * map_scale
	var radius := Vector2(7.5 * map_scale, 1.9 * map_scale)
	var left := Vector2(-spread + step * 1.6 * map_scale, y)
	var right := Vector2(spread - step * 1.2 * map_scale, y - 0.9 * map_scale)
	var role_color := _stage_role_color(accent)
	_draw_ellipse(left, radius, Color(0.0, 0.0, 0.0, STAGE_FOOT_ANCHOR_ALPHA * 0.74))
	_draw_ellipse(right, radius * Vector2(0.94, 0.90), Color(0.0, 0.0, 0.0, STAGE_FOOT_ANCHOR_ALPHA * 0.62))
	draw_line(left + Vector2(-radius.x * 0.36, 0.0), right + Vector2(radius.x * 0.36, -0.8 * map_scale), Color(role_color.r, role_color.g, role_color.b, STAGE_FOOT_ANCHOR_ALPHA * 0.72), 1.0 + map_scale * 0.16)
	draw_arc(Vector2(0.0, y - 6.0 * map_scale), 18.0 * map_scale, PI * 0.16, PI * 0.88, 24, Color(role_color.r, role_color.g, role_color.b, STAGE_STEP_SWEEP_ALPHA * (0.60 + absf(step) * 0.30)), 1.0 + map_scale * 0.12)

func _update_stage_pose_line(phase: float, wave: float, stage_motion: float, lane_offset_y: float = 0.0) -> void:
	if stage_pose_line_node == null:
		return
	if not using_sprite_asset or not _is_stage_actor():
		stage_pose_line_node.visible = false
		_hide_stage_pose_aux_lines()
		return
	var map_scale := _map_actor_scale()
	var appearance := GameData.get_npc_appearance(data)
	var accent := _color(appearance.get("accent", [0.78, 0.62, 0.32]), Color(0.78, 0.62, 0.32))
	var role_color := _stage_role_color(accent)
	var side := _stage_facing_side()
	var pose_base := sprite_base_position + Vector2(0.0, lane_offset_y)
	var shoulder := pose_base + Vector2(side * (13.5 + wave * 1.2) * map_scale, -31.0 * map_scale)
	var hand := pose_base + Vector2(side * (20.0 + sin(phase * 0.72) * 1.6) * map_scale, -5.5 * map_scale)
	var tip := hand + Vector2(side * (16.0 if is_enemy() else 11.0) * map_scale, (-15.0 if is_enemy() else -8.5) * map_scale)
	if is_master():
		shoulder = pose_base + Vector2(side * 12.0 * map_scale, -28.0 * map_scale)
		hand = pose_base + Vector2(side * (23.0 + wave * 1.2) * map_scale, -9.0 * map_scale)
		tip = hand + Vector2(side * 10.0 * map_scale, 5.0 * map_scale)
	elif bool(data.get("has_quests", false)):
		tip = hand + Vector2(side * 7.0 * map_scale, 9.0 * map_scale)
	stage_pose_line_node.points = PackedVector2Array([shoulder, hand, tip])
	stage_pose_line_node.width = clampf(2.0 * map_scale * stage_motion, 1.7, 3.8)
	stage_pose_line_node.default_color = Color(role_color.r, role_color.g, role_color.b, STAGE_POSE_LINE_ALPHA * (0.72 + absf(wave) * 0.28))
	stage_pose_line_node.visible = true
	if stage_weapon_glow_node != null:
		stage_weapon_glow_node.points = PackedVector2Array([hand, tip])
		stage_weapon_glow_node.width = clampf(4.2 * map_scale * stage_motion, 3.0, 7.2)
		stage_weapon_glow_node.default_color = Color(role_color.r, role_color.g, role_color.b, STAGE_WEAPON_GLOW_ALPHA * (0.58 + absf(wave) * 0.34))
		stage_weapon_glow_node.visible = true
	_update_stage_pose_aux_lines(phase, wave, stage_motion, role_color, side, map_scale, lane_offset_y)

func _hide_stage_pose_aux_lines() -> void:
	if stage_weapon_glow_node != null:
		stage_weapon_glow_node.visible = false
	if stage_torso_line_node != null:
		stage_torso_line_node.visible = false
	if stage_sash_line_node != null:
		stage_sash_line_node.visible = false
	if stage_front_limb_line_node != null:
		stage_front_limb_line_node.visible = false
	if stage_back_limb_line_node != null:
		stage_back_limb_line_node.visible = false
	if stage_guard_line_node != null:
		stage_guard_line_node.visible = false

func _update_stage_pose_aux_lines(phase: float, wave: float, stage_motion: float, role_color: Color, side: float, map_scale: float, lane_offset_y: float = 0.0) -> void:
	var pose_base := sprite_base_position + Vector2(0.0, lane_offset_y)
	if stage_torso_line_node != null:
		var shoulder_back := pose_base + Vector2(side * -7.5 * map_scale, -31.0 * map_scale)
		var shoulder_front := pose_base + Vector2(side * (12.5 + wave * 1.0) * map_scale, -28.0 * map_scale)
		var hip := pose_base + Vector2(side * (5.5 + sin(phase * 0.62) * 1.1) * map_scale, -2.0 * map_scale)
		stage_torso_line_node.points = PackedVector2Array([shoulder_back, shoulder_front, hip])
		stage_torso_line_node.width = clampf(1.7 * map_scale * stage_motion, 1.3, 3.0)
		stage_torso_line_node.default_color = Color(1.0, 0.90, 0.58, STAGE_TORSO_LINE_ALPHA * (0.58 + absf(wave) * 0.28))
		stage_torso_line_node.visible = true
	if stage_sash_line_node != null:
		var flutter := sin(phase * 0.82)
		var waist := pose_base + Vector2(0.0, 2.5 * map_scale)
		var left := waist + Vector2(-13.5 * map_scale, flutter * 1.1 * map_scale)
		var right := waist + Vector2(14.0 * map_scale, (-flutter * 1.2 - 0.5) * map_scale)
		var tail := waist + Vector2((-20.0 - absf(flutter) * 2.6) * side * map_scale, (7.5 + flutter * 1.2) * map_scale)
		stage_sash_line_node.points = PackedVector2Array([left, waist, right, tail])
		stage_sash_line_node.width = clampf(2.1 * map_scale * stage_motion, 1.6, 3.6)
		stage_sash_line_node.default_color = Color(role_color.r, role_color.g, role_color.b, STAGE_SASH_LINE_ALPHA * (0.68 + absf(flutter) * 0.26))
		stage_sash_line_node.visible = true
	_update_stage_limb_pose_lines(phase, wave, stage_motion, role_color, side, map_scale, lane_offset_y)

func _update_stage_limb_pose_lines(phase: float, wave: float, stage_motion: float, role_color: Color, side: float, map_scale: float, lane_offset_y: float = 0.0) -> void:
	var step := sin(phase * (1.02 if is_enemy() else 0.72))
	if is_master():
		step = sin(phase * 0.48) * 0.45
	var sway := sin(phase * 0.58) * STAGE_ROLE_STANCE_SWAY_PIXELS * map_scale
	var base := sprite_base_position + Vector2(0.0, lane_offset_y)
	var hip := base + Vector2(side * (4.0 + wave * 0.8) * map_scale, -1.0 * map_scale)
	var front_shoulder := base + Vector2(side * (13.5 + wave * 1.1) * map_scale, -28.5 * map_scale)
	var front_elbow := base + Vector2(side * (21.0 + step * 2.0) * map_scale, (-14.0 + step * 1.2) * map_scale)
	var front_hand := base + Vector2(side * (25.0 + step * 2.8) * map_scale, (-3.0 + absf(step) * 1.3) * map_scale)
	var front_knee := base + Vector2(side * (12.0 + step * 3.0) * map_scale, (13.0 - absf(step) * 1.2) * map_scale)
	var front_foot := base + Vector2(side * (17.0 + step * 4.0) * map_scale, (29.0 - maxf(step, 0.0) * 1.4) * map_scale)
	var back_shoulder := base + Vector2(-side * (8.5 + wave * 0.6) * map_scale, -29.5 * map_scale)
	var back_elbow := base + Vector2(-side * (14.5 - step * 1.6) * map_scale, (-15.5 - step * 0.8) * map_scale)
	var back_hand := base + Vector2(-side * (17.0 - step * 2.0) * map_scale, (-4.5 + absf(step) * 0.8) * map_scale)
	var back_knee := base + Vector2(-side * (9.5 - step * 2.2) * map_scale, (14.0 + absf(step) * 0.8) * map_scale)
	var back_foot := base + Vector2(-side * (13.5 - step * 3.2) * map_scale, 29.5 * map_scale)
	if is_enemy():
		front_hand += Vector2(side * 4.0, -3.0) * map_scale
		front_foot += Vector2(side * 2.0, -1.0) * map_scale
	elif is_master():
		front_shoulder.y += 2.0 * map_scale
		back_shoulder.y += 2.0 * map_scale
		front_hand.y += 3.0 * map_scale
	if stage_back_limb_line_node != null:
		stage_back_limb_line_node.points = PackedVector2Array([back_hand, back_elbow, back_shoulder, hip, back_knee, back_foot])
		stage_back_limb_line_node.width = clampf(1.45 * map_scale * stage_motion, 1.1, 2.7)
		stage_back_limb_line_node.default_color = Color(0.025, 0.018, 0.012, STAGE_LIMB_POSE_ALPHA * 0.58)
		stage_back_limb_line_node.visible = true
	if stage_front_limb_line_node != null:
		stage_front_limb_line_node.points = PackedVector2Array([front_hand, front_elbow, front_shoulder, hip, front_knee, front_foot])
		stage_front_limb_line_node.width = clampf(1.75 * map_scale * stage_motion, 1.3, 3.2)
		stage_front_limb_line_node.default_color = Color(role_color.r, role_color.g, role_color.b, STAGE_LIMB_POSE_ALPHA * (0.76 + absf(step) * 0.24))
		stage_front_limb_line_node.visible = true
	if stage_guard_line_node != null:
		stage_guard_line_node.points = _stage_guard_points(base + Vector2(sway * 0.08, -8.0 * map_scale), side, map_scale, step)
		stage_guard_line_node.width = clampf(1.45 * map_scale * stage_motion, 1.1, 2.7)
		stage_guard_line_node.default_color = Color(role_color.r, role_color.g, role_color.b, STAGE_IDLE_GUARD_ALPHA * (0.70 + absf(wave) * 0.30))
		stage_guard_line_node.visible = true

func _stage_guard_points(center: Vector2, side: float, map_scale: float, step: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if is_enemy():
		points.append(center + Vector2(-side * 26.0, 17.0) * map_scale)
		points.append(center + Vector2(side * 31.0, -3.0 + step * 1.4) * map_scale)
		points.append(center + Vector2(side * 21.0, 9.0) * map_scale)
		return points
	var start := PI * 0.10
	var end := PI * 0.90
	if is_master():
		start = -PI * 0.08
		end = PI * 1.08
	for i in range(18):
		var t := float(i) / 17.0
		var angle := lerpf(start, end, t)
		var rx := (30.0 if is_master() else 24.0) * map_scale
		var ry := (9.5 if is_master() else 7.2) * map_scale
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points

func _build_scale(build: String) -> Vector2:
	match build:
		"round":
			return Vector2(1.12, 0.98)
		"slim":
			return Vector2(0.86, 1.05)
		"thin":
			return Vector2(0.88, 1.10)
		"strong":
			return Vector2(1.10, 1.02)
		"broad":
			return Vector2(1.24, 0.98)
		"aged":
			return Vector2(0.92, 0.95)
		"graceful":
			return Vector2(0.92, 1.08)
		"heroic":
			return Vector2(1.04, 1.12)
		"master":
			return Vector2(1.05, 1.08)
		"rough":
			return Vector2(1.08, 0.96)
		"boss":
			return Vector2(1.28, 1.18)
		_:
			return Vector2.ONE

func _draw_aura(appearance: Dictionary, accent: Color) -> void:
	if is_master():
		draw_circle(Vector2(0, -1), 26.0, Color(accent.r, accent.g, accent.b, 0.11))
		draw_arc(Vector2(0, -1), 28.0, -0.2, PI + 0.2, 36, Color(accent.r, accent.g, accent.b, 0.22), 2.0)
	if is_enemy():
		draw_circle(Vector2(0, 1), 25.0, Color(0.70, 0.08, 0.06, 0.10))
	if str(appearance.get("motif", "none")) == "snow":
		draw_circle(Vector2(0, -4), 24.0, Color(0.80, 0.92, 1.0, 0.12))

func _draw_stage_identity_cues(_appearance: Dictionary, accent: Color, map_scale: float) -> void:
	if not _is_stage_actor():
		return
	var npc_id := int(data.get("id", 0))
	var phase := visual_phase * 1.15 + float(npc_id % 31) * 0.19
	var pulse := 0.5 + sin(phase) * 0.5
	var role_color := _stage_role_color(accent)
	var alpha := STAGE_ROLE_CUE_ALPHA * (0.70 + pulse * 0.30)
	var side := _stage_facing_side()
	_draw_stage_facing_cue(role_color, map_scale, side, pulse)
	if is_master():
		var center := Vector2(0.0, -2.0 * map_scale)
		draw_arc(center, 33.0 * map_scale, -0.25, PI + 0.25, 46, Color(role_color.r, role_color.g, role_color.b, alpha), 2.0)
		for i in range(STAGE_IDENTITY_MOTES):
			var angle := phase * 0.52 + float(i) * TAU / float(STAGE_IDENTITY_MOTES)
			var pos := center + Vector2(cos(angle) * 28.0 * map_scale, sin(angle) * 7.5 * map_scale)
			draw_circle(pos, 1.4 * map_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 1.25))
	elif is_enemy():
		var slash_y := 16.0 * map_scale
		draw_line(Vector2(-28.0 * map_scale, slash_y), Vector2(30.0 * map_scale, slash_y - 8.0 * map_scale), Color(role_color.r, role_color.g, role_color.b, alpha), 2.3)
		draw_line(Vector2(-20.0 * map_scale, slash_y + 6.0 * map_scale), Vector2(22.0 * map_scale, slash_y - 2.0 * map_scale), Color(role_color.r, role_color.g, role_color.b, alpha * 0.70), 1.5)
	elif bool(data.get("has_quests", false)):
		var cue_pos := Vector2(18.0 * map_scale, -55.0 * map_scale)
		draw_arc(cue_pos, (9.0 + pulse * 2.0) * map_scale, 0.0, TAU, 30, Color(role_color.r, role_color.g, role_color.b, alpha * 1.35), 1.5)
		draw_line(cue_pos + Vector2(-3.0, -4.0) * map_scale, cue_pos + Vector2(3.0, 4.0) * map_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 1.20), 1.4)
	else:
		draw_arc(Vector2(0.0, 18.0 * map_scale), 24.0 * map_scale, PI * 0.12, PI * 0.88, 28, Color(role_color.r, role_color.g, role_color.b, alpha * 0.50), 1.4)

func _draw_stage_facing_cue(role_color: Color, map_scale: float, side: float, pulse: float) -> void:
	var alpha := STAGE_FACING_CUE_ALPHA * (0.62 + pulse * 0.24)
	var head := Vector2(side * 4.0, -42.0) * map_scale
	if is_master():
		head.y += 2.0 * map_scale
	elif is_enemy():
		head.y += 3.0 * map_scale
	var gaze := head + Vector2(side * (16.0 + pulse * 4.0), 3.0 + pulse * 1.2) * map_scale
	draw_line(head, gaze, Color(1.0, 0.92, 0.62, alpha), 1.0 + map_scale * 0.08)
	draw_circle(gaze, 1.6 * map_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 1.18))

func _draw_stage_activity_cue(accent: Color, map_scale: float) -> void:
	if not _is_stage_actor():
		return
	var activity := _stage_activity_type()
	if activity.is_empty():
		return
	var npc_id := int(data.get("id", 0))
	var phase := visual_phase * 1.18 + float(npc_id % 37) * 0.23
	var pulse := 0.5 + sin(phase) * 0.5
	var sway := sin(phase * 0.83) * STAGE_ACTIVITY_SWAY_PIXELS
	var side := _stage_facing_side()
	var role_color := _stage_role_color(accent)
	var alpha := STAGE_ACTIVITY_CUE_ALPHA * (0.72 + pulse * 0.28)
	var hand := Vector2(side * (27.0 + sway) * map_scale, -7.0 * map_scale)
	var prop_scale := map_scale * STAGE_ACTIVITY_PROP_SCALE
	match activity:
		"service":
			_draw_activity_tray(hand, side, role_color, alpha, phase, prop_scale)
		"patrol":
			_draw_activity_lantern(hand, side, role_color, alpha, phase, prop_scale)
		"scroll":
			_draw_activity_scroll(hand, side, role_color, alpha, prop_scale)
		"herb":
			_draw_activity_herb_basket(hand, side, role_color, alpha, phase, prop_scale)
		"forge":
			_draw_activity_forge(hand, side, role_color, alpha, phase, prop_scale)
		"meditate":
			_draw_activity_meditate(role_color, alpha, phase, prop_scale)
		"threat":
			_draw_activity_threat(role_color, alpha, phase, prop_scale)
		_:
			_draw_activity_wander(hand, side, role_color, alpha, phase, prop_scale)

func _draw_activity_tray(hand: Vector2, side: float, role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var tray_center := hand + Vector2(side * 8.0, 8.0) * prop_scale
	draw_line(tray_center + Vector2(-13.0, 0.0) * prop_scale, tray_center + Vector2(14.0, -1.0) * prop_scale, Color(0.52, 0.32, 0.16, alpha * 1.15), 2.2 * prop_scale)
	draw_circle(tray_center + Vector2(-6.0, -3.0) * prop_scale, 3.0 * prop_scale, Color(0.92, 0.80, 0.55, alpha * 0.92))
	draw_circle(tray_center + Vector2(5.0, -3.5) * prop_scale, 2.7 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 0.78))
	for i in range(3):
		var x := (-6.0 + float(i) * 5.0) * prop_scale
		var rise := (6.0 + sin(phase + float(i)) * 1.8) * prop_scale
		draw_line(tray_center + Vector2(x, -7.0 * prop_scale), tray_center + Vector2(x + side * 2.0 * prop_scale, -7.0 * prop_scale - rise), Color(0.96, 0.90, 0.72, alpha * 0.36), 1.0 * prop_scale)

func _draw_activity_lantern(hand: Vector2, side: float, role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var pole_top := hand + Vector2(side * 4.0, -22.0) * prop_scale
	var pole_bottom := hand + Vector2(side * 9.0, 12.0) * prop_scale
	var lamp := hand + Vector2(side * 16.0, -13.0 + sin(phase) * 1.6) * prop_scale
	draw_line(pole_top, pole_bottom, Color(0.28, 0.19, 0.11, alpha * 0.96), 1.7 * prop_scale)
	draw_line(pole_top, lamp + Vector2(-side * 3.0, -4.0) * prop_scale, Color(0.32, 0.22, 0.13, alpha * 0.82), 1.2 * prop_scale)
	draw_circle(lamp, 12.0 * prop_scale, Color(1.0, 0.65, 0.24, STAGE_ACTIVITY_GLOW_ALPHA * 0.72))
	draw_rect(Rect2(lamp - Vector2(5.0, 6.0) * prop_scale, Vector2(10.0, 12.0) * prop_scale), Color(0.92, 0.34, 0.18, alpha * 0.88), true)
	draw_line(lamp + Vector2(-5.0, -1.0) * prop_scale, lamp + Vector2(5.0, -1.0) * prop_scale, Color(1.0, 0.86, 0.42, alpha), 1.2 * prop_scale)
	draw_circle(lamp, 2.3 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha))

func _draw_activity_scroll(hand: Vector2, side: float, role_color: Color, alpha: float, prop_scale: float) -> void:
	var scroll_pos := hand + Vector2(side * 9.0, 7.0) * prop_scale
	var rect := Rect2(scroll_pos - Vector2(7.0, 11.0) * prop_scale, Vector2(14.0, 22.0) * prop_scale)
	draw_rect(rect, Color(0.87, 0.76, 0.53, alpha * 0.94), true)
	draw_rect(rect, Color(0.36, 0.22, 0.12, alpha * 0.86), false, 1.1 * prop_scale)
	for i in range(3):
		var y := scroll_pos.y + (-5.0 + float(i) * 5.2) * prop_scale
		draw_line(Vector2(scroll_pos.x - 4.5 * prop_scale, y), Vector2(scroll_pos.x + 4.5 * prop_scale, y), Color(0.18, 0.12, 0.08, alpha * 0.58), 0.9 * prop_scale)
	draw_circle(scroll_pos + Vector2(side * 7.0, -11.0) * prop_scale, 2.1 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha))

func _draw_activity_herb_basket(hand: Vector2, side: float, role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var basket := hand + Vector2(side * 11.0, 12.0) * prop_scale
	_draw_ellipse(basket, Vector2(9.0, 4.2) * prop_scale, Color(0.42, 0.25, 0.12, alpha * 0.88))
	draw_arc(basket + Vector2(0.0, -1.5) * prop_scale, 8.5 * prop_scale, PI, TAU, 18, Color(0.62, 0.40, 0.18, alpha), 1.6 * prop_scale)
	for i in range(5):
		var angle := phase * 0.18 + float(i) * 0.92
		var leaf := basket + Vector2(cos(angle) * 6.0, -7.0 - absf(sin(angle)) * 4.0) * prop_scale
		draw_line(basket + Vector2(0.0, -3.0) * prop_scale, leaf, Color(0.28, 0.62, 0.28, alpha * 0.82), 1.1 * prop_scale)
		draw_circle(leaf, 1.6 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 0.64))

func _draw_activity_forge(hand: Vector2, side: float, role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var hammer_head := hand + Vector2(side * 13.0, -11.0 + sin(phase) * 2.4) * prop_scale
	var hammer_handle := hand + Vector2(side * 2.0, 9.0) * prop_scale
	draw_line(hammer_handle, hammer_head, Color(0.39, 0.24, 0.12, alpha), 2.4 * prop_scale)
	draw_rect(Rect2(hammer_head - Vector2(5.0, 3.0) * prop_scale, Vector2(10.0, 6.0) * prop_scale), Color(0.58, 0.56, 0.50, alpha), true)
	var spark_origin := hand + Vector2(side * 22.0, 8.0) * prop_scale
	for i in range(5):
		var angle := phase + float(i) * TAU / 5.0
		var spark := spark_origin + Vector2(cos(angle) * 8.0, sin(angle) * 5.0) * prop_scale
		draw_line(spark_origin, spark, Color(1.0, 0.58, 0.18, alpha * 0.86), 1.0 * prop_scale)
		draw_circle(spark, 1.2 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha))

func _draw_activity_meditate(role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var center := Vector2(0.0, 1.0 * prop_scale)
	draw_arc(center, 35.0 * prop_scale, -0.18, PI + 0.18, 46, Color(role_color.r, role_color.g, role_color.b, alpha * 0.78), 1.8 * prop_scale)
	draw_arc(center + Vector2(0.0, 3.0) * prop_scale, 24.0 * prop_scale, PI * 0.08, PI * 0.92, 32, Color(0.96, 0.86, 0.52, alpha * 0.36), 1.2 * prop_scale)
	for i in range(6):
		var angle := phase * 0.46 + float(i) * TAU / 6.0
		var pos := center + Vector2(cos(angle) * 30.0, sin(angle) * 8.0) * prop_scale
		draw_circle(pos, 1.4 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 0.92))

func _draw_activity_threat(role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var lift := sin(phase * 0.76) * 2.0 * prop_scale
	draw_line(Vector2(-33.0, 11.0) * prop_scale, Vector2(34.0, -7.0) * prop_scale + Vector2(0.0, lift), Color(role_color.r, role_color.g, role_color.b, alpha * 1.05), 2.4 * prop_scale)
	draw_line(Vector2(-24.0, 22.0) * prop_scale, Vector2(23.0, 4.0) * prop_scale + Vector2(0.0, lift), Color(1.0, 0.76, 0.44, alpha * 0.48), 1.4 * prop_scale)
	draw_circle(Vector2(24.0, 2.0) * prop_scale + Vector2(0.0, lift), 3.0 * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 0.96))

func _draw_activity_wander(hand: Vector2, side: float, role_color: Color, alpha: float, phase: float, prop_scale: float) -> void:
	var satchel := hand + Vector2(side * 10.0, 12.0) * prop_scale
	_draw_ellipse(satchel, Vector2(6.0, 8.0) * prop_scale, Color(0.35, 0.22, 0.12, alpha * 0.82))
	draw_line(satchel + Vector2(-side * 3.5, -8.0) * prop_scale, satchel + Vector2(side * 5.0, 7.0) * prop_scale, Color(role_color.r, role_color.g, role_color.b, alpha * 0.78), 1.2 * prop_scale)
	var tassel_start := satchel + Vector2(side * 5.5, 5.0) * prop_scale
	var tassel_end := tassel_start + Vector2(side * (5.0 + sin(phase) * 2.0), 7.0) * prop_scale
	draw_line(tassel_start, tassel_end, Color(0.96, 0.82, 0.42, alpha * 0.72), 1.2 * prop_scale)

func _stage_activity_type() -> String:
	var explicit_activity := str(data.get("stage_activity", "")).strip_edges()
	if not explicit_activity.is_empty():
		return explicit_activity
	if is_enemy():
		return "threat"
	if is_master():
		return "meditate"
	var shop_type := str(data.get("shop_type", ""))
	match shop_type:
		"apothecary":
			return "herb"
		"blacksmith":
			return "forge"
		"inn", "tea_house", "market", "cloth_shop":
			return "service"
	var npc_name := str(data.get("name", ""))
	if _npc_name_in(npc_name, ["平阿四", "店小二", "小商贩", "阿青", "小裁缝", "掌柜", "布庄掌柜", "茶博士"]):
		return "service"
	if _npc_name_in(npc_name, ["捕快", "巡捕", "衙役", "赵无极"]):
		return "patrol"
	if _npc_name_in(npc_name, ["老夫子", "书童", "知客道人", "王辞", "李白"]):
		return "scroll"
	if _npc_name_in(npc_name, ["平一指", "采药道人", "药铺掌柜"]):
		return "herb"
	if _npc_name_in(npc_name, ["铁匠", "铁匠铺掌柜"]):
		return "forge"
	if bool(data.get("has_quests", false)):
		return "scroll"
	return "wander"

func _npc_name_in(npc_name: String, names: Array) -> bool:
	return names.has(npc_name)

func _stage_role_color(accent: Color) -> Color:
	if is_enemy():
		return Color(0.95, 0.16, 0.10)
	if is_master():
		return accent.lightened(0.32)
	if bool(data.get("has_quests", false)):
		return Color(1.0, 0.76, 0.24)
	return accent.lightened(0.12)

func _draw_contact_light(accent: Color, map_scale: float, lane_offset_y: float = 0.0) -> void:
	var npc_id := int(data.get("id", 0))
	var pulse := 0.5 + sin(visual_phase * 1.4 + float(npc_id % 23) * 0.27) * 0.5
	var alpha := CONTACT_GLOW_ALPHA * (0.60 + pulse * 0.24)
	if is_enemy():
		accent = Color(0.82, 0.13, 0.08)
	elif is_master():
		alpha *= 1.18
	_draw_ellipse(Vector2(1.5 * map_scale, 27.0 * map_scale + lane_offset_y * 0.82), Vector2(26.0 * map_scale, 6.5 * map_scale), Color(accent.r, accent.g, accent.b, alpha))
	_draw_ellipse(Vector2(0.0, 28.5 * map_scale + lane_offset_y * 0.82), Vector2(14.0 * map_scale, 3.2 * map_scale), Color(1.0, 0.82, 0.44, alpha * 0.42))

func _draw_legs(outfit: String, secondary: Color, ink: Color) -> void:
	if outfit == "flowing_hanfu" or outfit == "daoist_robe" or outfit == "fur_robe":
		draw_polygon(PackedVector2Array([Vector2(-11, 21), Vector2(0, 33), Vector2(-14, 36)]), PackedColorArray([secondary, secondary.darkened(0.12), secondary]))
		draw_polygon(PackedVector2Array([Vector2(11, 21), Vector2(0, 33), Vector2(14, 36)]), PackedColorArray([secondary, secondary.darkened(0.12), secondary]))
	else:
		draw_line(Vector2(-7, 21), Vector2(-9, 36), ink, 4.0)
		draw_line(Vector2(7, 21), Vector2(9, 36), ink, 4.0)

func _draw_outfit(outfit: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match outfit:
		"merchant_robe":
			_draw_robe(primary, secondary, accent, 18.0, 24.0)
			draw_rect(Rect2(-11, 6, 22, 4), accent, true)
			draw_circle(Vector2(0, 12), 3.0, accent.lightened(0.2))
		"work_apron":
			_draw_tunic(primary, secondary, 16.0, 23.0)
			draw_rect(Rect2(-10, -2, 20, 24), secondary.lightened(0.34), true)
			draw_line(Vector2(-8, -1), Vector2(8, 21), ink, 1.5)
		"plain_hanfu":
			_draw_robe(primary, secondary, accent, 16.0, 28.0)
			draw_line(Vector2(-10, 1), Vector2(13, 16), accent, 2.0)
		"scholar_robe":
			_draw_robe(primary, secondary, accent, 14.0, 29.0)
			draw_rect(Rect2(-13, 4, 26, 3), accent.darkened(0.08), true)
			draw_line(Vector2(0, -3), Vector2(0, 22), secondary.lightened(0.18), 1.4)
		"official_uniform":
			_draw_tunic(primary, secondary, 18.0, 26.0)
			draw_rect(Rect2(-12, -2, 24, 8), secondary, true)
			draw_rect(Rect2(-6, 6, 12, 10), accent.darkened(0.10), false, 2.0)
		"elder_robe":
			_draw_robe(primary, secondary, accent, 15.0, 25.0)
			draw_line(Vector2(-10, 12), Vector2(10, 12), accent.darkened(0.10), 2.0)
		"monk_robe":
			_draw_robe(primary, secondary, accent, 17.0, 28.0)
			draw_polygon(PackedVector2Array([Vector2(-16, -6), Vector2(7, -2), Vector2(-4, 20), Vector2(-18, 17)]), PackedColorArray([secondary, secondary.lightened(0.06), secondary, secondary.darkened(0.10)]))
		"smith_apron":
			_draw_tunic(primary, secondary, 19.0, 24.0)
			draw_rect(Rect2(-12, -4, 24, 28), secondary.darkened(0.08), true)
			draw_line(Vector2(-10, 8), Vector2(10, 8), accent, 2.0)
		"hero_robe":
			_draw_robe(primary, secondary, accent, 17.0, 30.0)
			draw_line(Vector2(-14, -3), Vector2(14, 16), accent, 2.3)
			draw_arc(Vector2(0, 6), 20.0, 0.2, 2.6, 18, Color(accent.r, accent.g, accent.b, 0.40), 2.0)
		"sect_robe":
			_draw_robe(primary, secondary, accent, 18.0, 30.0)
			draw_rect(Rect2(-14, 7, 28, 4), accent, true)
			draw_line(Vector2(-13, -2), Vector2(13, 18), accent.darkened(0.05), 2.0)
		"flowing_hanfu":
			_draw_robe(primary, secondary, accent, 15.0, 32.0)
			draw_arc(Vector2(-7, 10), 19.0, -0.3, 1.4, 20, Color(accent.r, accent.g, accent.b, 0.38), 2.0)
			draw_arc(Vector2(9, 13), 21.0, 1.7, 3.4, 20, Color(accent.r, accent.g, accent.b, 0.30), 2.0)
		"daoist_robe":
			_draw_robe(primary, secondary, accent, 16.0, 31.0)
			draw_circle(Vector2(0, 9), 7.0, secondary)
			draw_arc(Vector2(0, 9), 7.0, -PI / 2.0, PI / 2.0, 18, primary, 2.0)
		"fur_robe":
			_draw_robe(primary, secondary, accent, 19.0, 31.0)
			draw_arc(Vector2(-10, -2), 9.0, 0.0, TAU, 18, accent, 2.3)
			draw_arc(Vector2(10, -2), 9.0, 0.0, TAU, 18, accent, 2.3)
		"ragged":
			_draw_tunic(primary, secondary, 17.0, 22.0)
			draw_line(Vector2(-11, 16), Vector2(-3, 24), ink, 1.6)
			draw_line(Vector2(5, 14), Vector2(13, 21), ink, 1.6)
		"leather":
			_draw_tunic(primary, secondary, 20.0, 25.0)
			draw_rect(Rect2(-12, 2, 24, 8), secondary, true)
			draw_circle(Vector2(-6, 6), 2.0, accent)
			draw_circle(Vector2(6, 6), 2.0, accent)
		"night_suit":
			_draw_tunic(primary, secondary, 15.0, 26.0)
			draw_rect(Rect2(-13, -7, 26, 9), secondary, true)
		"dark_armor":
			_draw_tunic(primary, secondary, 22.0, 30.0)
			draw_rect(Rect2(-14, -2, 28, 21), secondary.darkened(0.10), true)
			draw_line(Vector2(-12, 4), Vector2(12, 4), accent, 2.0)
			draw_line(Vector2(-10, 13), Vector2(10, 13), accent.darkened(0.12), 2.0)
		_:
			_draw_tunic(primary, secondary, 16.0, 24.0)

func _draw_robe(primary: Color, secondary: Color, accent: Color, half_width: float, height: float) -> void:
	draw_polygon(PackedVector2Array([
		Vector2(-half_width, -8),
		Vector2(half_width, -8),
		Vector2(half_width + 5, height),
		Vector2(0, height + 8),
		Vector2(-half_width - 5, height)
	]), PackedColorArray([primary.lightened(0.05), primary, primary.darkened(0.13), secondary.darkened(0.05), primary.darkened(0.08)]))
	draw_line(Vector2(-half_width + 4, -2), Vector2(half_width - 3, height - 2), accent, 2.0)

func _draw_tunic(primary: Color, secondary: Color, half_width: float, height: float) -> void:
	draw_polygon(PackedVector2Array([
		Vector2(-half_width, -7),
		Vector2(half_width, -7),
		Vector2(half_width - 2, height),
		Vector2(-half_width + 2, height)
	]), PackedColorArray([primary.lightened(0.05), primary, primary.darkened(0.13), primary.darkened(0.08)]))
	draw_rect(Rect2(-half_width + 3, 8, half_width * 2.0 - 6, 4), secondary, true)

func _draw_arms(outfit: String, primary: Color, secondary: Color, skin: Color, ink: Color) -> void:
	var sleeve_width := 4.0
	if outfit == "flowing_hanfu" or outfit == "daoist_robe":
		sleeve_width = 6.0
	draw_line(Vector2(-13, -1), Vector2(-25, 9), primary.darkened(0.05), sleeve_width)
	draw_line(Vector2(13, -1), Vector2(25, 8), primary.darkened(0.10), sleeve_width)
	draw_circle(Vector2(-27, 10), 3.0, skin)
	draw_circle(Vector2(27, 9), 3.0, skin)
	if outfit == "official_uniform" or outfit == "dark_armor":
		draw_line(Vector2(-14, -1), Vector2(-25, 9), ink, 1.5)
		draw_line(Vector2(14, -1), Vector2(25, 8), ink, 1.5)

func _draw_head(head: String, skin: Color, ink: Color) -> void:
	match head:
		"square":
			draw_polygon(PackedVector2Array([Vector2(-10, -28), Vector2(10, -28), Vector2(11, -16), Vector2(7, -9), Vector2(-7, -9), Vector2(-11, -16)]), PackedColorArray([skin, skin, skin.darkened(0.05), skin.darkened(0.08), skin.darkened(0.08), skin.darkened(0.05)]))
		"long":
			draw_circle(Vector2(0, -20), 10.0, skin)
			draw_rect(Rect2(-8, -20, 16, 11), skin.darkened(0.02), true)
		"aged":
			draw_circle(Vector2(0, -20), 9.5, skin.darkened(0.05))
			draw_line(Vector2(-6, -18), Vector2(6, -18), Color(ink.r, ink.g, ink.b, 0.35), 1.0)
			draw_line(Vector2(-4, -15), Vector2(5, -15), Color(ink.r, ink.g, ink.b, 0.30), 1.0)
		"sharp":
			draw_polygon(PackedVector2Array([Vector2(0, -31), Vector2(11, -22), Vector2(7, -11), Vector2(0, -7), Vector2(-7, -11), Vector2(-11, -22)]), PackedColorArray([skin.lightened(0.05), skin, skin.darkened(0.05), skin.darkened(0.08), skin.darkened(0.05), skin]))
		"soft":
			draw_circle(Vector2(0, -20), 10.5, skin.lightened(0.04))
		"rough":
			draw_polygon(PackedVector2Array([Vector2(-10, -27), Vector2(9, -29), Vector2(12, -18), Vector2(5, -8), Vector2(-7, -10), Vector2(-12, -18)]), PackedColorArray([skin, skin.darkened(0.03), skin.darkened(0.06), skin.darkened(0.10), skin.darkened(0.08), skin]))
		_:
			draw_circle(Vector2(0, -20), 10.0, skin)

func _draw_face(motif: String, ink: Color) -> void:
	draw_circle(Vector2(-4, -21), 1.1, ink)
	draw_circle(Vector2(4, -21), 1.1, ink)
	draw_line(Vector2(-3, -14), Vector2(4, -14), Color(ink.r, ink.g, ink.b, 0.70), 1.2)
	if motif == "scar":
		draw_line(Vector2(5, -26), Vector2(-3, -16), Color(0.70, 0.12, 0.10), 1.5)
	elif motif == "shadow":
		draw_rect(Rect2(-9, -22, 18, 6), Color(0.02, 0.02, 0.025), true)
		draw_circle(Vector2(-4, -20), 1.0, Color(0.86, 0.18, 0.12))
		draw_circle(Vector2(4, -20), 1.0, Color(0.86, 0.18, 0.12))

func _draw_hair(hair: String, ink: Color, secondary: Color) -> void:
	match hair:
		"short":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
		"topknot":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_circle(Vector2(0, -33), 3.8, ink)
		"high_topknot":
			draw_arc(Vector2(0, -24), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(0, -31), Vector2(0, -40), ink, 3.0)
			draw_circle(Vector2(0, -40), 3.2, ink)
		"long_tail":
			draw_arc(Vector2(0, -23), 10.5, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(8, -18), Vector2(13, 2), ink, 3.0)
		"sideburns":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(-9, -20), Vector2(-12, -10), ink, 2.5)
			draw_line(Vector2(9, -20), Vector2(12, -10), ink, 2.5)
		"beard":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(-3, -13), Vector2(-2, -4), secondary.lightened(0.45), 2.0)
			draw_line(Vector2(3, -13), Vector2(2, -4), secondary.lightened(0.45), 2.0)
		"white_beard":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, Color(0.88, 0.86, 0.80), 4.0)
			draw_line(Vector2(-4, -13), Vector2(-5, -1), Color(0.88, 0.86, 0.80), 2.2)
			draw_line(Vector2(4, -13), Vector2(5, -1), Color(0.88, 0.86, 0.80), 2.2)
			draw_line(Vector2(0, -13), Vector2(0, 2), Color(0.94, 0.92, 0.86), 2.0)
		"bald":
			draw_arc(Vector2(0, -24), 9.0, PI + 0.2, TAU - 0.2, 14, Color(0.48, 0.32, 0.20, 0.20), 1.5)
		"headband":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
		"messy":
			draw_line(Vector2(-9, -28), Vector2(-3, -34), ink, 3.0)
			draw_line(Vector2(-4, -30), Vector2(2, -36), ink, 3.0)
			draw_line(Vector2(3, -30), Vector2(10, -34), ink, 3.0)
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 16, ink, 3.0)
		"wild":
			for i in range(7):
				var x := -12.0 + i * 4.0
				var lean := -2.0 if i % 2 == 0 else 2.0
				draw_line(Vector2(x, -25), Vector2(x + lean, -38 - abs(3 - i)), ink, 2.5)
			draw_arc(Vector2(0, -23), 11.0, PI, TAU, 18, ink, 4.0)
		"masked":
			draw_rect(Rect2(-10, -24, 20, 8), ink, true)
		"hood":
			draw_arc(Vector2(0, -23), 12.0, PI, TAU, 20, secondary, 5.0)

func _draw_hat(hat: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match hat:
		"merchant_cap":
			draw_rect(Rect2(-10, -33, 20, 6), secondary, true)
			draw_arc(Vector2(0, -31), 11.0, PI, TAU, 16, accent, 2.0)
		"cloth_cap":
			draw_arc(Vector2(0, -30), 11.0, PI, TAU, 16, secondary.lightened(0.20), 4.0)
			draw_line(Vector2(7, -30), Vector2(14, -25), secondary.lightened(0.20), 3.0)
		"scholar_hat":
			draw_rect(Rect2(-11, -35, 22, 5), ink, true)
			draw_rect(Rect2(-6, -40, 12, 7), secondary.darkened(0.12), true)
		"constable_hat":
			draw_rect(Rect2(-13, -35, 26, 5), ink, true)
			draw_polygon(PackedVector2Array([Vector2(-8, -35), Vector2(8, -35), Vector2(4, -43), Vector2(-4, -43)]), PackedColorArray([secondary, secondary, secondary.darkened(0.10), secondary.darkened(0.10)]))
			draw_circle(Vector2(0, -37), 2.3, accent)
		"soft_cap":
			draw_arc(Vector2(0, -31), 10.0, PI, TAU, 16, secondary, 4.0)
		"monk_dots":
			for x in [-4, 0, 4]:
				draw_circle(Vector2(x, -26), 0.9, Color(0.38, 0.20, 0.10))
		"headband":
			draw_line(Vector2(-10, -26), Vector2(10, -26), accent, 3.0)
			draw_line(Vector2(9, -26), Vector2(16, -22), accent, 2.0)
		"sect_crown":
			draw_rect(Rect2(-8, -36, 16, 5), accent.darkened(0.10), true)
			draw_polygon(PackedVector2Array([Vector2(-5, -36), Vector2(0, -43), Vector2(5, -36)]), PackedColorArray([accent, accent.lightened(0.18), accent]))
		"flower_pin":
			draw_circle(Vector2(8, -31), 3.0, accent)
			draw_circle(Vector2(11, -29), 2.0, primary.lightened(0.25))
			draw_circle(Vector2(6, -28), 2.0, primary.lightened(0.25))
		"daoist_crown":
			draw_line(Vector2(-9, -35), Vector2(9, -35), ink, 3.0)
			draw_line(Vector2(0, -35), Vector2(0, -44), ink, 2.5)
			draw_circle(Vector2(0, -44), 2.5, accent)
		"snow_hood":
			draw_arc(Vector2(0, -24), 13.0, PI, TAU, 20, accent, 5.0)
			draw_line(Vector2(-11, -23), Vector2(-14, -12), accent, 3.0)
			draw_line(Vector2(11, -23), Vector2(14, -12), accent, 3.0)
		"bandit_wrap":
			draw_line(Vector2(-11, -28), Vector2(11, -25), accent.darkened(0.15), 4.0)
			draw_line(Vector2(9, -25), Vector2(15, -20), accent.darkened(0.15), 2.5)
		"face_mask":
			draw_rect(Rect2(-10, -19, 20, 7), secondary, true)
		"dark_crown":
			draw_rect(Rect2(-12, -36, 24, 5), secondary.darkened(0.25), true)
			draw_polygon(PackedVector2Array([Vector2(-10, -36), Vector2(-5, -45), Vector2(0, -36), Vector2(5, -45), Vector2(10, -36)]), PackedColorArray([secondary, accent, secondary, accent, secondary]))

func _draw_prop_back(prop: String, secondary: Color, accent: Color, ink: Color) -> void:
	if prop == "sword":
		draw_line(Vector2(17, -9), Vector2(29, -36), Color(0.76, 0.78, 0.76), 2.2)
		draw_line(Vector2(14, -5), Vector2(22, -12), accent, 2.8)
	elif prop == "great_blade":
		draw_line(Vector2(20, 14), Vector2(33, -39), Color(0.72, 0.72, 0.68), 4.0)
		draw_line(Vector2(18, 14), Vector2(24, 2), accent.darkened(0.15), 4.0)
	elif prop == "staff":
		draw_line(Vector2(-27, -23), Vector2(-22, 34), Color(0.40, 0.25, 0.13), 3.0)
	elif prop == "dao" or prop == "blade":
		draw_line(Vector2(19, -6), Vector2(32, -24), Color(0.74, 0.76, 0.72), 3.0)
		draw_line(Vector2(16, -4), Vector2(22, -10), accent, 2.8)

func _draw_prop_front(prop: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match prop:
		"abacus":
			draw_rect(Rect2(-27, 3, 14, 10), Color(0.42, 0.25, 0.12), false, 1.6)
			draw_line(Vector2(-25, 7), Vector2(-15, 7), accent, 1.0)
			draw_circle(Vector2(-22, 5), 1.2, accent)
			draw_circle(Vector2(-18, 9), 1.2, accent)
		"towel":
			draw_line(Vector2(-24, 8), Vector2(-17, 25), Color(0.92, 0.88, 0.76), 4.0)
			draw_line(Vector2(-19, 24), Vector2(-12, 19), Color(0.92, 0.88, 0.76), 3.0)
		"basket":
			draw_arc(Vector2(-23, 13), 9.0, PI, TAU, 16, accent.darkened(0.15), 2.0)
			draw_rect(Rect2(-31, 12, 16, 10), Color(0.52, 0.34, 0.16), false, 1.6)
			draw_line(Vector2(-29, 17), Vector2(-16, 17), accent.darkened(0.20), 1.0)
		"scroll":
			draw_rect(Rect2(17, 2, 11, 21), Color(0.86, 0.78, 0.56), true)
			draw_line(Vector2(17, 6), Vector2(28, 6), ink, 1.0)
			draw_line(Vector2(17, 17), Vector2(28, 17), ink, 1.0)
		"beads":
			for i in range(8):
				var angle := -0.2 + i * 0.42
				draw_circle(Vector2(cos(angle) * 10.0, 0 + sin(angle) * 8.0), 1.5, accent.darkened(0.20))
		"hammer":
			draw_line(Vector2(21, 12), Vector2(31, 0), Color(0.42, 0.26, 0.14), 3.0)
			draw_rect(Rect2(27, -5, 12, 7), Color(0.46, 0.44, 0.42), true)
		"fan":
			draw_polygon(PackedVector2Array([Vector2(22, 10), Vector2(35, -4), Vector2(38, 11)]), PackedColorArray([accent, primary.lightened(0.25), accent.lightened(0.1)]))
			draw_line(Vector2(22, 10), Vector2(36, 0), ink, 1.0)
			draw_line(Vector2(22, 10), Vector2(37, 7), ink, 1.0)
		"whisk":
			draw_line(Vector2(22, 6), Vector2(34, -8), Color(0.44, 0.32, 0.18), 2.0)
			for i in range(5):
				draw_line(Vector2(34, -8), Vector2(42, -13 + i * 3), Color(0.86, 0.84, 0.76), 1.2)
		"club":
			draw_line(Vector2(22, 14), Vector2(32, -4), Color(0.36, 0.20, 0.10), 5.0)
		"dagger":
			draw_line(Vector2(22, 10), Vector2(33, 0), Color(0.78, 0.80, 0.76), 2.2)
			draw_line(Vector2(19, 12), Vector2(24, 7), accent, 2.0)

func _draw_motif(motif: String, accent: Color, ink: Color) -> void:
	match motif:
		"coin":
			draw_circle(Vector2(0, 11), 4.0, accent)
			draw_rect(Rect2(-1.5, 9.5, 3, 3), ink.darkened(0.2), true)
		"water":
			draw_arc(Vector2(0, 10), 7.0, 0.1, PI - 0.1, 16, accent, 1.6)
			draw_arc(Vector2(3, 13), 5.0, PI, TAU, 16, accent, 1.4)
		"book":
			draw_rect(Rect2(-6, 7, 12, 8), accent.darkened(0.1), false, 1.4)
			draw_line(Vector2(0, 7), Vector2(0, 15), accent, 1.2)
		"badge":
			draw_polygon(PackedVector2Array([Vector2(0, 4), Vector2(6, 9), Vector2(3, 16), Vector2(-3, 16), Vector2(-6, 9)]), PackedColorArray([accent, accent.darkened(0.05), accent.darkened(0.15), accent.darkened(0.15), accent.darkened(0.05)]))
		"lotus":
			draw_circle(Vector2(0, 12), 2.4, accent)
			draw_arc(Vector2(-4, 12), 4.0, -0.8, 0.8, 12, accent, 1.3)
			draw_arc(Vector2(4, 12), 4.0, PI - 0.8, PI + 0.8, 12, accent, 1.3)
		"spark":
			draw_line(Vector2(0, 8), Vector2(0, 16), accent, 1.6)
			draw_line(Vector2(-4, 12), Vector2(4, 12), accent, 1.6)
		"wind":
			draw_arc(Vector2(0, 9), 10.0, 0.0, PI * 1.2, 20, accent, 1.5)
		"bagua":
			draw_arc(Vector2(0, 11), 7.0, 0.0, TAU, 24, accent, 1.7)
			draw_line(Vector2(-5, 11), Vector2(5, 11), accent, 1.2)
			draw_line(Vector2(0, 6), Vector2(0, 16), accent, 1.2)
		"flower":
			for angle in [0.0, 1.26, 2.52, 3.78, 5.04]:
				draw_circle(Vector2(cos(angle) * 4.0, 11 + sin(angle) * 4.0), 2.0, accent.lightened(0.12))
			draw_circle(Vector2(0, 11), 1.8, accent.darkened(0.20))
		"taiji":
			draw_circle(Vector2(0, 11), 6.0, accent)
			draw_arc(Vector2(0, 11), 6.0, -PI / 2.0, PI / 2.0, 18, ink, 2.0)
			draw_circle(Vector2(0, 8), 1.3, ink)
			draw_circle(Vector2(0, 14), 1.3, accent.lightened(0.35))
		"snow":
			draw_line(Vector2(-5, 11), Vector2(5, 11), accent, 1.2)
			draw_line(Vector2(0, 6), Vector2(0, 16), accent, 1.2)
			draw_line(Vector2(-4, 7), Vector2(4, 15), accent, 1.2)
			draw_line(Vector2(4, 7), Vector2(-4, 15), accent, 1.2)
		"dragon":
			draw_arc(Vector2(-1, 11), 8.0, -0.8, 2.7, 22, accent, 2.0)
			draw_circle(Vector2(6, 7), 1.8, accent.lightened(0.2))

func _color(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_ARRAY and value.size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]) if value.size() >= 4 else 1.0)
	return fallback
