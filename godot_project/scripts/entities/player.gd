extends CharacterBody2D
class_name PlayerActor

const SPEED := 190.0
const DRAW_SCALE := 1.0
const SPRITE_TARGET_HEIGHT := 118.0
const SPRITE_TARGET_WIDTH := 94.0
const LOCAL_STAGE_PRESENCE_SCALE := 1.22
const STEP_DUST_RADIUS := Vector2(10.0, 3.2)
const PLAYER_CONTACT_GLOW_ALPHA := 0.13
const PLAYER_FACTION_MOTES := 10
const PLAYER_STAGE_RIM_ALPHA := 0.20
const PLAYER_WEAPON_SILHOUETTE_ALPHA := 0.34
const PLAYER_CLOTH_LAYER_ALPHA := 0.28
const PLAYER_MOTION_AFTERIMAGE_ALPHA := 0.12
const PLAYER_GUARD_LINE_ALPHA := 0.22
const PLAYER_STAGE_FOOT_ANCHOR_ALPHA := 0.24
const PLAYER_STAGE_WEAPON_POSE_ALPHA := 0.34
const PLAYER_STAGE_SHOULDER_GLOW_ALPHA := 0.20
const PLAYER_STAGE_GROUND_LOCK_ALPHA := 0.28
const PLAYER_STAGE_STANCE_LINE_ALPHA := 0.26
const PLAYER_STAGE_RUN_RIBBON_ALPHA := 0.18
const PLAYER_STAGE_RUN_RIBBON_COUNT := 3
const PLAYER_STAGE_IDLE_FOCUS_ALPHA := 0.22
const PLAYER_STAGE_FACTION_SIGIL_ALPHA := 0.20
const PLAYER_STAGE_IDLE_CLOTH_SWAY_ALPHA := 0.24
const PLAYER_STAGE_POSE_RIG_ALPHA := 0.30
const PLAYER_STAGE_ARM_SWING_ALPHA := 0.28
const PLAYER_STAGE_STEP_ARC_ALPHA := 0.22
const PLAYER_STAGE_IDLE_GUARD_ALPHA := 0.18
const PLAYER_STAGE_READY_STANCE_ALPHA := 0.24
const PLAYER_STAGE_CENTERLINE_ALPHA := 0.24
const PLAYER_STAGE_LANE_LOCK_ALPHA := 0.20
const PLAYER_STAGE_LANE_MAX_VISUAL_OFFSET := 22.0
const STAGE_DEPTH_SCALE_MIN := 0.78
const STAGE_DEPTH_SCALE_MAX := 1.22

var movement_enabled := true
var world_map: Node = null
var facing := Vector2.DOWN
var walk_phase := 0.0
var sprite_texture: Texture2D
var sprite_key := ""
var stage_depth_scale := 1.0
var stage_lane_offset_y := 0.0
var stage_lane_lock_strength := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = int(position.y)
	if not EventBus.player_changed.is_connected(_on_player_changed):
		EventBus.player_changed.connect(_on_player_changed)
	_refresh_sprite_texture()
	_refresh_stage_depth_scale()
	set_process(true)

func _process(delta: float) -> void:
	_refresh_stage_depth_scale()
	_refresh_stage_lane_anchor()
	var moving := movement_enabled and velocity.length() > 1.0
	walk_phase += delta * (10.5 if moving else 1.45)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		_refresh_stage_depth_scale()
		_refresh_stage_lane_anchor()
		z_index = int(position.y)
		return

	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1.0
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1.0

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		facing = input_vector
		queue_redraw()

	var previous_position := position
	velocity = input_vector * SPEED
	move_and_slide()

	if world_map != null and not world_map.is_position_walkable(position):
		position = previous_position
		velocity = Vector2.ZERO
	_refresh_stage_depth_scale()
	_refresh_stage_lane_anchor()
	z_index = int(position.y)

func _draw() -> void:
	_refresh_sprite_texture()
	_refresh_stage_depth_scale()
	_refresh_stage_lane_anchor()
	var faction := str(GameState.player.get("faction", "none"))
	var robe := _robe_color(faction)
	var trim := GameData.get_faction_color(faction).lightened(0.18)
	var skin := Color(0.88, 0.73, 0.58)
	var ink := Color(0.08, 0.07, 0.06)
	var moving := velocity.length() > 1.0
	var stage_actor := _is_side_view_stage()
	var depth_scale := get_map_actor_visual_scale()
	var lane_visual_offset := get_stage_lane_visual_offset()
	var bob := (sin(walk_phase) * 3.2 if moving else sin(walk_phase) * 0.75) * depth_scale
	var lean := (clampf(facing.x, -1.0, 1.0) * 2.2 if moving else sin(walk_phase * 0.6) * 0.45) * depth_scale

	_draw_step_dust(moving, depth_scale)
	_draw_player_contact_glow(trim, depth_scale, moving, lane_visual_offset)
	_draw_player_idle_motes(trim, depth_scale)
	_draw_actor_shadow(Vector2(4 * depth_scale, 32 * depth_scale + lane_visual_offset * 0.82), Vector2(42, 13) * depth_scale, 1.0)
	if stage_actor:
		_draw_stage_player_ground_lock(trim, depth_scale, moving, lane_visual_offset)
	if sprite_texture != null:
		var texture_size := sprite_texture.get_size()
		var target_height := SPRITE_TARGET_HEIGHT * depth_scale
		var target_width := SPRITE_TARGET_WIDTH * depth_scale
		var factor: float = min(target_height / max(texture_size.y, 1.0), target_width / max(texture_size.x, 1.0))
		var breath := 1.0 + sin(walk_phase * 0.72) * (0.010 if moving else 0.018)
		var step_sway := absf(sin(walk_phase)) if moving else 0.0
		var draw_size := texture_size * factor * Vector2(1.0 + step_sway * 0.018, breath - step_sway * 0.006)
		var foot_y := 35.0 * depth_scale + bob + lane_visual_offset * 0.55
		var top_left := Vector2(-draw_size.x * 0.5 + lean, foot_y - draw_size.y)
		var facing_side := _facing_side()
		var outline_rect := Rect2(top_left - Vector2(2.5, 1.5), draw_size + Vector2(5.0, 5.0))
		draw_texture_rect(sprite_texture, outline_rect, false, Color(0.02, 0.018, 0.014, 0.58))
		if stage_actor:
			_draw_stage_player_run_ribbons(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_motion_afterimage(top_left, draw_size, trim, moving)
			_draw_stage_player_footwork(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_back_layers(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_pose_rig(top_left, draw_size, trim, moving, facing_side, false)
			_draw_stage_actor_sash(top_left, draw_size, trim, moving)
			_draw_stage_player_faction_sigil(top_left, draw_size, trim, moving, facing_side)
		draw_texture_rect(sprite_texture, Rect2(top_left, draw_size), false)
		if stage_actor:
			_draw_stage_player_pose_rig(top_left, draw_size, trim, moving, facing_side, true)
			_draw_stage_player_step_arcs(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_front_layers(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_idle_cloth_sway(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_ready_stance(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_weapon_pose(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_shoulder_glow(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_stance_lines(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_head_focus(top_left, draw_size, trim, moving, facing_side)
		_draw_sprite_rim_light(top_left, draw_size, trim, stage_actor)
		_draw_sprite_motion_accents(lean, foot_y, draw_size, trim, moving, stage_actor)
		var dir := facing.normalized()
		draw_line(Vector2(0, 4 * depth_scale + bob), dir * 18.0 * depth_scale + Vector2(0, bob), Color(1.0, 1.0, 1.0, 0.18), 1.8)
		return
	draw_set_transform(Vector2(0, bob + lane_visual_offset * 0.50), 0.0, Vector2.ONE * DRAW_SCALE * depth_scale)

	# Back sword and loose cloak give the player a more readable wuxia silhouette.
	draw_line(Vector2(16, -9), Vector2(29, -37), Color(0.78, 0.80, 0.76), 2.5)
	draw_line(Vector2(12, -4), Vector2(20, -12), trim.darkened(0.10), 3.0)
	draw_polygon(PackedVector2Array([
		Vector2(-17, -6),
		Vector2(17, -7),
		Vector2(22, 18),
		Vector2(7, 30),
		Vector2(-20, 21)
	]), PackedColorArray([
		robe.darkened(0.05),
		robe,
		robe.darkened(0.18),
		robe.darkened(0.10),
		robe.darkened(0.18)
	]))

	draw_polygon(PackedVector2Array([
		Vector2(-13, -9),
		Vector2(13, -9),
		Vector2(17, 23),
		Vector2(0, 33),
		Vector2(-17, 23)
	]), PackedColorArray([
		robe.lightened(0.07),
		robe,
		robe.darkened(0.16),
		robe.darkened(0.06),
		robe.darkened(0.12)
	]))
	draw_line(Vector2(-10, -3), Vector2(13, 15), trim, 2.5)
	draw_line(Vector2(9, -3), Vector2(-8, 18), trim.darkened(0.18), 1.8)
	draw_rect(Rect2(-13, 10, 26, 4), trim.darkened(0.22), true)

	var leg_offset := sin(walk_phase) * 2.0 if velocity.length() > 1.0 else 0.0
	draw_line(Vector2(-6, 23), Vector2(-9 - leg_offset, 36), ink, 4.0)
	draw_line(Vector2(6, 23), Vector2(9 + leg_offset, 36), ink, 4.0)
	draw_line(Vector2(-13, -2), Vector2(-25, 9), robe.darkened(0.08), 4.5)
	draw_line(Vector2(13, -2), Vector2(25, 8), robe.darkened(0.12), 4.5)
	draw_circle(Vector2(-27, 10), 3.0, skin)
	draw_circle(Vector2(27, 9), 3.0, skin)

	draw_circle(Vector2(0, -20), 10.5, skin)
	draw_arc(Vector2(0, -24), 10.5, PI, TAU, 18, ink, 4.0)
	draw_circle(Vector2(0, -35), 3.6, ink)
	draw_line(Vector2(0, -31), Vector2(0, -39), ink, 2.5)
	draw_circle(Vector2(-4, -21), 1.1, ink)
	draw_circle(Vector2(4, -21), 1.1, ink)
	draw_line(Vector2(-3, -14), Vector2(4, -14), Color(ink.r, ink.g, ink.b, 0.72), 1.2)

	var dir := facing.normalized()
	draw_line(Vector2(0, 2), dir * 16.0, Color(1.0, 1.0, 1.0, 0.16), 1.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _robe_color(faction: String) -> Color:
	match faction:
		"bagua":
			return Color(0.30, 0.28, 0.22)
		"flower":
			return Color(0.42, 0.22, 0.32)
		"honglian":
			return Color(0.45, 0.12, 0.10)
		"naja":
			return Color(0.14, 0.22, 0.17)
		"taiji":
			return Color(0.36, 0.37, 0.34)
		"xueshan":
			return Color(0.40, 0.50, 0.58)
		"xiaoyao":
			return Color(0.26, 0.42, 0.34)
		_:
			return Color(0.18, 0.27, 0.33)

func _on_player_changed(_player: Dictionary) -> void:
	_refresh_sprite_texture(true)
	queue_redraw()

func set_stage_depth_scale(value: float) -> void:
	var next_scale := clampf(value, STAGE_DEPTH_SCALE_MIN, STAGE_DEPTH_SCALE_MAX)
	if absf(stage_depth_scale - next_scale) < 0.001:
		return
	stage_depth_scale = next_scale
	queue_redraw()

func get_map_actor_visual_scale() -> float:
	return stage_depth_scale * (LOCAL_STAGE_PRESENCE_SCALE if _is_side_view_stage() else 1.0)

func get_stage_lane_visual_offset() -> float:
	if not _is_side_view_stage():
		return 0.0
	return clampf(
		stage_lane_offset_y * stage_lane_lock_strength * 0.38,
		-PLAYER_STAGE_LANE_MAX_VISUAL_OFFSET,
		PLAYER_STAGE_LANE_MAX_VISUAL_OFFSET
	)

func _refresh_stage_depth_scale() -> void:
	if world_map != null and world_map.has_method("get_actor_depth_scale"):
		set_stage_depth_scale(float(world_map.get_actor_depth_scale(position)))
	else:
		set_stage_depth_scale(1.0)

func _refresh_stage_lane_anchor() -> void:
	if world_map != null and world_map.has_method("get_stage_lane_anchor"):
		var anchor: Dictionary = world_map.call("get_stage_lane_anchor", position)
		stage_lane_offset_y = float(anchor.get("offset_y", 0.0))
		stage_lane_lock_strength = clampf(float(anchor.get("strength", 0.0)), 0.0, 1.0)
		return
	stage_lane_offset_y = 0.0
	stage_lane_lock_strength = 0.0

func _is_side_view_stage() -> bool:
	if world_map == null:
		return false
	if world_map.has_method("is_side_view_stage_active"):
		return bool(world_map.call("is_side_view_stage_active"))
	return false

func _facing_side() -> float:
	if absf(facing.x) > 0.20:
		return -1.0 if facing.x < 0.0 else 1.0
	if _is_side_view_stage() and world_map != null and world_map.has_method("get_stage_actor_facing_side"):
		return float(world_map.call("get_stage_actor_facing_side", position))
	return 1.0

func _refresh_sprite_texture(force: bool = false) -> void:
	var gender := str(GameState.player.get("gender", "male"))
	if gender != "female":
		gender = "male"
	var faction := str(GameState.player.get("faction", "none"))
	var key := "%s_%s" % [gender, faction]
	if not force and key == sprite_key:
		return
	sprite_key = key
	var path := "res://assets/characters/player/player_%s_%s.png" % [gender, faction]
	sprite_texture = GameData.load_texture(path, true)
	if sprite_texture == null:
		sprite_texture = GameData.load_texture("res://assets/characters/player/player_male_none.png", true)

func _draw_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
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
	var stretch := 1.0 + (1.0 - noon_factor) * 0.42
	var offset := Vector2(6.0 + (12.0 - hour) * 0.45, 2.0)
	_draw_shadow(center + offset, Vector2(radius.x * stretch, radius.y * 1.10), Color(0.0, 0.0, 0.0, 0.08 * strength))
	_draw_shadow(center + Vector2(2, 1), radius, Color(0.0, 0.0, 0.0, 0.20 * strength))
	_draw_shadow(center, radius * Vector2(0.58, 0.50), Color(0.0, 0.0, 0.0, 0.16 * strength))

func _draw_step_dust(moving: bool, depth_scale: float) -> void:
	if not moving:
		return
	var dir := facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var step := absf(sin(walk_phase))
	var side := Vector2(-dir.y, dir.x)
	var base := Vector2(2, 36) * depth_scale - dir * 15.0 * depth_scale
	var alpha := 0.10 + step * 0.10
	_draw_shadow(base + side * 7.0 * depth_scale, STEP_DUST_RADIUS * depth_scale * (0.8 + step * 0.45), Color(0.74, 0.64, 0.42, alpha))
	_draw_shadow(base - side * 6.0 * depth_scale + dir * 5.0 * depth_scale, STEP_DUST_RADIUS * depth_scale * (0.58 + (1.0 - step) * 0.35), Color(0.68, 0.58, 0.38, alpha * 0.72))

func _draw_stage_motion_afterimage(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool) -> void:
	if not moving or sprite_texture == null:
		return
	var dir := facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var step := absf(sin(walk_phase))
	var offset := -dir * clampf(draw_size.y * 0.055, 4.0, 9.0)
	var alpha := PLAYER_MOTION_AFTERIMAGE_ALPHA * (0.45 + step * 0.55)
	draw_texture_rect(sprite_texture, Rect2(top_left + offset, draw_size), false, Color(accent.r, accent.g, accent.b, alpha))

func _draw_stage_player_back_layers(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var flutter := sin(walk_phase * (1.45 if moving else 0.78))
	var cloak_color := accent.darkened(0.36)
	var shoulder := top_left + Vector2(draw_size.x * (0.50 + 0.12 * side), draw_size.y * 0.30)
	var hip := top_left + Vector2(draw_size.x * (0.46 + 0.10 * side), draw_size.y * 0.64)
	var hem_outer := top_left + Vector2(draw_size.x * (0.42 + 0.22 * side + flutter * 0.018), draw_size.y * 0.91)
	var hem_inner := top_left + Vector2(draw_size.x * (0.42 - 0.08 * side), draw_size.y * 0.84)
	draw_polygon(PackedVector2Array([shoulder, hip, hem_outer, hem_inner]), PackedColorArray([
		Color(cloak_color.r, cloak_color.g, cloak_color.b, PLAYER_CLOTH_LAYER_ALPHA * 0.72),
		Color(cloak_color.r, cloak_color.g, cloak_color.b, PLAYER_CLOTH_LAYER_ALPHA),
		Color(cloak_color.r, cloak_color.g, cloak_color.b, PLAYER_CLOTH_LAYER_ALPHA * 0.58),
		Color(cloak_color.r, cloak_color.g, cloak_color.b, PLAYER_CLOTH_LAYER_ALPHA * 0.46)
	]))
	var blade_base := top_left + Vector2(draw_size.x * (0.50 + 0.16 * side), draw_size.y * 0.36)
	var blade_tip := top_left + Vector2(draw_size.x * (0.56 + 0.30 * side), draw_size.y * 0.04)
	var blade_width := clampf(draw_size.x * 0.026, 2.0, 3.8)
	draw_line(blade_base, blade_tip, Color(0.86, 0.88, 0.80, PLAYER_WEAPON_SILHOUETTE_ALPHA), blade_width)
	draw_line(blade_base + Vector2(-3.5 * side, 3.5), blade_base + Vector2(5.0 * side, 12.0), Color(accent.r, accent.g, accent.b, PLAYER_WEAPON_SILHOUETTE_ALPHA * 0.80), blade_width * 1.12)

func _draw_stage_player_front_layers(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var flutter := sin(walk_phase * (1.60 if moving else 0.86))
	var waist_y := top_left.y + draw_size.y * 0.53
	var belt_left := top_left + Vector2(draw_size.x * 0.28, draw_size.y * 0.52)
	var belt_right := top_left + Vector2(draw_size.x * 0.72, draw_size.y * 0.52 + flutter * 1.6)
	var belt_width := clampf(draw_size.x * 0.030, 2.6, 4.6)
	draw_line(belt_left, belt_right, Color(accent.r, accent.g, accent.b, PLAYER_STAGE_RIM_ALPHA * 1.40), belt_width)
	var flap_top := top_left + Vector2(draw_size.x * (0.50 + 0.035 * side), draw_size.y * 0.54)
	var flap_low_a := top_left + Vector2(draw_size.x * (0.46 + 0.055 * side + flutter * 0.014), draw_size.y * 0.84)
	var flap_low_b := top_left + Vector2(draw_size.x * (0.57 + 0.085 * side + flutter * 0.018), draw_size.y * 0.80)
	var shadow_accent := accent.darkened(0.24)
	draw_polygon(PackedVector2Array([flap_top, flap_low_b, flap_low_a]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, PLAYER_CLOTH_LAYER_ALPHA * 0.92),
		Color(accent.r, accent.g, accent.b, PLAYER_CLOTH_LAYER_ALPHA * 0.44),
		Color(shadow_accent.r, shadow_accent.g, shadow_accent.b, PLAYER_CLOTH_LAYER_ALPHA * 0.62)
	]))
	var guard_start := Vector2(top_left.x + draw_size.x * (0.51 + 0.10 * side), waist_y - draw_size.y * 0.11)
	var guard_end := guard_start + Vector2(draw_size.x * 0.17 * side, draw_size.y * (0.08 + flutter * 0.010))
	draw_line(guard_start, guard_end, Color(1.0, 0.92, 0.62, PLAYER_GUARD_LINE_ALPHA), clampf(draw_size.x * 0.018, 1.5, 2.8))

func _draw_stage_player_footwork(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var step := sin(walk_phase) if moving else sin(walk_phase * 0.55) * 0.32
	var foot_y := top_left.y + draw_size.y * 0.965
	var center_x := top_left.x + draw_size.x * 0.50
	var spread := draw_size.x * (0.18 if moving else 0.145)
	var left := Vector2(center_x - spread + step * draw_size.x * 0.028, foot_y)
	var right := Vector2(center_x + spread - step * draw_size.x * 0.024, foot_y - draw_size.y * 0.012)
	var radius := Vector2(draw_size.x * 0.082, draw_size.y * 0.017)
	_draw_shadow(left, radius, Color(0.0, 0.0, 0.0, PLAYER_STAGE_FOOT_ANCHOR_ALPHA * 0.72))
	_draw_shadow(right, radius * Vector2(0.94, 0.90), Color(0.0, 0.0, 0.0, PLAYER_STAGE_FOOT_ANCHOR_ALPHA * 0.62))
	draw_line(left + Vector2(-radius.x * 0.48, 0.0), right + Vector2(radius.x * 0.42, -draw_size.y * 0.012), Color(accent.r, accent.g, accent.b, PLAYER_STAGE_FOOT_ANCHOR_ALPHA * 0.52), 1.2)
	if moving:
		var dust_side := Vector2(side * draw_size.x * 0.11, draw_size.y * 0.010)
		_draw_shadow(left - dust_side, radius * Vector2(1.28, 0.72), Color(0.72, 0.62, 0.42, PLAYER_STAGE_FOOT_ANCHOR_ALPHA * 0.30))

func _draw_stage_player_pose_rig(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float, front_layer: bool) -> void:
	var phase := sin(walk_phase * (1.15 if moving else 0.54))
	var counter := cos(walk_phase * (1.15 if moving else 0.54))
	var step := phase if moving else phase * 0.22
	var torso_top := top_left + Vector2(draw_size.x * (0.50 + side * 0.018), draw_size.y * 0.335)
	var torso_mid := top_left + Vector2(draw_size.x * (0.50 + side * (0.045 + step * 0.010)), draw_size.y * 0.510)
	var hip := top_left + Vector2(draw_size.x * (0.50 + side * (0.032 + step * 0.012)), draw_size.y * 0.650)
	var layer_alpha := PLAYER_STAGE_POSE_RIG_ALPHA if front_layer else PLAYER_STAGE_POSE_RIG_ALPHA * 0.52
	var line_width := clampf(draw_size.x * (0.017 if front_layer else 0.013), 1.2, 2.8)
	var body_color := Color(accent.r, accent.g, accent.b, layer_alpha)
	if front_layer:
		draw_line(torso_top, torso_mid, Color(1.0, 0.92, 0.62, PLAYER_STAGE_CENTERLINE_ALPHA * (0.70 + absf(counter) * 0.24)), line_width * 0.86)
		draw_line(torso_mid, hip, body_color, line_width)
	_draw_stage_player_pose_arm(top_left, draw_size, accent, moving, side, step, front_layer, line_width)
	_draw_stage_player_pose_leg(top_left, draw_size, accent, side, step, front_layer, line_width)
	if front_layer and not moving:
		_draw_stage_player_idle_guard_arc(torso_mid, draw_size, accent, phase)

func _draw_stage_player_pose_arm(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float, step: float, front_layer: bool, width: float) -> void:
	var side_sign := side if front_layer else -side
	var shoulder := top_left + Vector2(draw_size.x * (0.50 + side_sign * (0.145 if front_layer else 0.090)), draw_size.y * (0.365 if front_layer else 0.385))
	var reach := draw_size.x * ((0.185 if front_layer else 0.130) + absf(step) * (0.026 if moving else 0.010))
	var elbow := shoulder + Vector2(side_sign * reach, draw_size.y * (0.105 - step * (0.030 if front_layer else -0.018)))
	var hand := elbow + Vector2(side_sign * draw_size.x * (0.120 + step * 0.018), draw_size.y * (0.105 + absf(step) * 0.020))
	var alpha := PLAYER_STAGE_ARM_SWING_ALPHA * (0.95 if front_layer else 0.48) * (0.72 + absf(step) * 0.28)
	var arm_color := Color(accent.r, accent.g, accent.b, alpha)
	if not front_layer:
		arm_color = Color(0.025, 0.018, 0.012, alpha)
	draw_line(shoulder, elbow, arm_color, width)
	draw_line(elbow, hand, arm_color, width * 0.90)
	draw_circle(hand, clampf(draw_size.x * 0.016, 1.3, 2.5), Color(1.0, 0.90, 0.62, alpha * (0.78 if front_layer else 0.34)))
	if moving and front_layer:
		draw_line(hand - Vector2(side * draw_size.x * 0.08, -draw_size.y * 0.015), hand, Color(1.0, 0.82, 0.40, alpha * 0.46), width * 0.58)

func _draw_stage_player_pose_leg(top_left: Vector2, draw_size: Vector2, accent: Color, side: float, step: float, front_layer: bool, width: float) -> void:
	var side_sign := side if front_layer else -side
	var hip := top_left + Vector2(draw_size.x * (0.50 + side_sign * 0.070), draw_size.y * 0.650)
	var knee := top_left + Vector2(draw_size.x * (0.50 + side_sign * (0.145 + step * 0.040)), draw_size.y * (0.790 - absf(step) * 0.026))
	var foot := top_left + Vector2(draw_size.x * (0.50 + side_sign * (0.210 + step * 0.060)), draw_size.y * (0.962 - maxf(step, 0.0) * 0.022))
	var alpha := PLAYER_STAGE_POSE_RIG_ALPHA * (0.90 if front_layer else 0.42) * (0.70 + absf(step) * 0.30)
	var leg_color := Color(accent.r, accent.g, accent.b, alpha)
	if not front_layer:
		leg_color = Color(0.025, 0.018, 0.012, alpha)
	draw_line(hip, knee, leg_color, width)
	draw_line(knee, foot, leg_color, width * 0.92)
	_draw_shadow(foot + Vector2(0.0, draw_size.y * 0.010), Vector2(draw_size.x * 0.052, draw_size.y * 0.010), Color(0.0, 0.0, 0.0, alpha * 0.54))
	if front_layer:
		draw_line(foot - Vector2(side * draw_size.x * 0.030, draw_size.y * 0.004), foot + Vector2(side * draw_size.x * 0.070, -draw_size.y * 0.006), Color(1.0, 0.86, 0.46, alpha * 0.54), width * 0.54)

func _draw_stage_player_step_arcs(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.15 if moving else 0.54))
	var foot_y := top_left.y + draw_size.y * 0.950
	var center := top_left + Vector2(draw_size.x * (0.50 + side * 0.030), draw_size.y * 0.790)
	var radius := draw_size.x * (0.205 if moving else 0.145)
	var alpha := PLAYER_STAGE_STEP_ARC_ALPHA * ((0.86 + absf(phase) * 0.14) if moving else 0.44)
	var start_angle := PI * (0.17 if side > 0.0 else 0.02)
	var end_angle := PI * (0.90 if side > 0.0 else 0.76)
	draw_arc(center, radius, start_angle, end_angle, 24, Color(accent.r, accent.g, accent.b, alpha * 0.62), 1.2)
	if moving:
		for i in range(2):
			var trail_t := float(i) / 2.0
			var x := top_left.x + draw_size.x * (0.34 + trail_t * 0.30) - side * phase * draw_size.x * 0.035
			var y := foot_y - trail_t * draw_size.y * 0.026
			draw_line(Vector2(x, y), Vector2(x + side * draw_size.x * 0.105, y - draw_size.y * 0.010), Color(1.0, 0.86, 0.46, alpha * (0.44 - trail_t * 0.12)), 1.0)

func _draw_stage_player_idle_guard_arc(center: Vector2, draw_size: Vector2, accent: Color, phase: float) -> void:
	var radius := draw_size.x * (0.22 + absf(phase) * 0.014)
	var alpha := PLAYER_STAGE_IDLE_GUARD_ALPHA * (0.66 + absf(phase) * 0.28)
	draw_arc(center, radius, PI * 0.12, PI * 0.88, 28, Color(accent.r, accent.g, accent.b, alpha), 1.3)
	draw_arc(center + Vector2(0.0, draw_size.y * 0.045), radius * 0.72, PI * 1.10, PI * 1.78, 20, Color(1.0, 0.92, 0.62, alpha * 0.52), 1.0)

func _draw_stage_player_ready_stance(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	if moving:
		return
	var phase := sin(walk_phase * 0.72)
	var alpha := PLAYER_STAGE_READY_STANCE_ALPHA * (0.66 + absf(phase) * 0.24)
	var shoulder_back := top_left + Vector2(draw_size.x * (0.44 - side * 0.090), draw_size.y * 0.375)
	var shoulder_front := top_left + Vector2(draw_size.x * (0.54 + side * 0.075), draw_size.y * (0.385 + phase * 0.006))
	var back_hand := top_left + Vector2(draw_size.x * (0.43 - side * 0.160), draw_size.y * (0.520 - phase * 0.010))
	var front_hand := top_left + Vector2(draw_size.x * (0.58 + side * 0.225), draw_size.y * (0.448 + phase * 0.016))
	var hip := top_left + Vector2(draw_size.x * (0.50 + side * 0.028), draw_size.y * 0.660)
	var front_foot := top_left + Vector2(draw_size.x * (0.56 + side * 0.205), draw_size.y * 0.965)
	var back_foot := top_left + Vector2(draw_size.x * (0.44 - side * 0.165), draw_size.y * 0.970)
	draw_line(shoulder_back, back_hand, Color(0.024, 0.018, 0.014, alpha * 0.68), clampf(draw_size.x * 0.014, 1.0, 2.0))
	draw_line(shoulder_front, front_hand, Color(accent.r, accent.g, accent.b, alpha), clampf(draw_size.x * 0.018, 1.4, 2.6))
	draw_line(back_hand, front_hand, Color(1.0, 0.92, 0.62, alpha * 0.46), 1.0)
	draw_circle(back_hand, clampf(draw_size.x * 0.019, 1.5, 2.8), Color(1.0, 0.88, 0.58, alpha * 0.58))
	draw_circle(front_hand, clampf(draw_size.x * 0.024, 1.8, 3.4), Color(1.0, 0.90, 0.56, alpha * 0.92))
	draw_arc(front_hand - Vector2(side * draw_size.x * 0.030, draw_size.y * 0.010), draw_size.x * (0.070 + absf(phase) * 0.006), PI * 0.05, PI * 1.10, 18, Color(accent.r, accent.g, accent.b, alpha * 0.70), 1.0)
	draw_line(hip, front_foot, Color(accent.r, accent.g, accent.b, alpha * 0.38), clampf(draw_size.x * 0.010, 0.9, 1.5))
	draw_line(hip, back_foot, Color(0.020, 0.016, 0.012, alpha * 0.46), clampf(draw_size.x * 0.010, 0.9, 1.4))
	draw_line(back_foot, front_foot, Color(1.0, 0.82, 0.42, alpha * 0.34), 1.0)

func _draw_stage_player_weapon_pose(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.25 if moving else 0.68))
	var waist := top_left + Vector2(draw_size.x * (0.52 + 0.06 * side), draw_size.y * 0.55)
	var hand := waist + Vector2(draw_size.x * (0.23 + phase * 0.018) * side, draw_size.y * (0.06 + phase * 0.010))
	var tip := hand + Vector2(draw_size.x * (0.26 + (0.06 if moving else 0.02)) * side, -draw_size.y * (0.14 + phase * 0.016))
	var alpha := PLAYER_STAGE_WEAPON_POSE_ALPHA * (0.72 + absf(phase) * 0.24)
	draw_line(waist, hand, Color(accent.r, accent.g, accent.b, alpha * 0.70), clampf(draw_size.x * 0.020, 1.6, 3.0))
	draw_line(hand, tip, Color(0.96, 0.92, 0.76, alpha), clampf(draw_size.x * 0.014, 1.2, 2.2))
	draw_line(tip - Vector2(side * draw_size.x * 0.030, -draw_size.y * 0.010), tip + Vector2(side * draw_size.x * 0.048, draw_size.y * 0.022), Color(1.0, 0.86, 0.46, alpha * 0.48), 1.0)
	if moving:
		draw_line(hand - Vector2(side * draw_size.x * 0.08, -draw_size.y * 0.018), tip, Color(1.0, 0.78, 0.36, alpha * 0.30), 1.2)

func _draw_stage_player_shoulder_glow(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var pulse := 0.55 + sin(walk_phase * (1.4 if moving else 0.74)) * 0.45
	var shoulder_a := top_left + Vector2(draw_size.x * (0.36 + 0.08 * side), draw_size.y * 0.245)
	var shoulder_b := top_left + Vector2(draw_size.x * (0.58 + 0.10 * side), draw_size.y * 0.292)
	var hip := top_left + Vector2(draw_size.x * (0.55 + 0.05 * side), draw_size.y * 0.62)
	var alpha := PLAYER_STAGE_SHOULDER_GLOW_ALPHA * (0.55 + pulse * 0.38)
	draw_line(shoulder_a, shoulder_b, Color(1.0, 0.92, 0.62, alpha), clampf(draw_size.x * 0.014, 1.2, 2.0))
	draw_line(shoulder_b, hip, Color(accent.r, accent.g, accent.b, alpha * 0.72), clampf(draw_size.x * 0.011, 1.0, 1.8))

func _draw_stage_player_head_focus(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.05 if moving else 0.64))
	var head := top_left + Vector2(draw_size.x * (0.50 + side * (0.018 + phase * 0.006)), draw_size.y * 0.235)
	var gaze := head + Vector2(side * draw_size.x * 0.15, draw_size.y * (0.012 + phase * 0.008))
	var alpha := PLAYER_STAGE_IDLE_FOCUS_ALPHA * (0.58 + absf(phase) * 0.30)
	draw_line(head + Vector2(-side * draw_size.x * 0.030, -draw_size.y * 0.010), gaze, Color(1.0, 0.95, 0.72, alpha), clampf(draw_size.x * 0.010, 0.9, 1.6))
	draw_circle(gaze, clampf(draw_size.x * 0.018, 1.3, 2.4), Color(accent.r, accent.g, accent.b, alpha * 1.08))
	draw_line(head + Vector2(-side * draw_size.x * 0.045, draw_size.y * 0.030), head + Vector2(side * draw_size.x * 0.054, draw_size.y * 0.045), Color(0.05, 0.04, 0.035, alpha * 0.74), clampf(draw_size.x * 0.009, 0.8, 1.4))

func _draw_stage_player_idle_cloth_sway(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.28 if moving else 0.68))
	var alpha := PLAYER_STAGE_IDLE_CLOTH_SWAY_ALPHA * (0.54 + absf(phase) * 0.34)
	var sleeve_root := top_left + Vector2(draw_size.x * (0.52 + 0.13 * side), draw_size.y * 0.41)
	var sleeve_tip := sleeve_root + Vector2(side * draw_size.x * (0.18 + phase * 0.020), draw_size.y * (0.13 + phase * 0.016))
	var hem_root := top_left + Vector2(draw_size.x * (0.48 - 0.08 * side), draw_size.y * 0.72)
	var hem_tip := hem_root + Vector2(-side * draw_size.x * (0.18 + phase * 0.026), draw_size.y * 0.16)
	draw_line(sleeve_root, sleeve_tip, Color(accent.r, accent.g, accent.b, alpha), clampf(draw_size.x * 0.016, 1.3, 2.5))
	draw_line(sleeve_tip, sleeve_tip + Vector2(side * draw_size.x * 0.050, draw_size.y * 0.030), Color(1.0, 0.90, 0.58, alpha * 0.60), 1.0)
	draw_line(hem_root, hem_tip, Color(accent.r, accent.g, accent.b, alpha * 0.74), clampf(draw_size.x * 0.014, 1.1, 2.2))
	draw_line(hem_tip, hem_tip + Vector2(-side * draw_size.x * 0.060, draw_size.y * 0.028), Color(0.08, 0.055, 0.040, alpha * 0.56), 1.0)

func _draw_stage_player_faction_sigil(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var faction := str(GameState.player.get("faction", "none"))
	var phase := walk_phase * (1.02 if moving else 0.46)
	var pulse := 0.5 + sin(phase) * 0.5
	var alpha := PLAYER_STAGE_FACTION_SIGIL_ALPHA * (0.50 + pulse * 0.28)
	var center := top_left + Vector2(draw_size.x * (0.50 - side * 0.11), draw_size.y * 0.47)
	var radius := clampf(draw_size.x * 0.19, 14.0, 28.0)
	var sigil_color := accent
	if faction == "none":
		sigil_color = Color(0.92, 0.78, 0.42)
		draw_arc(center, radius, PI * 0.08, PI * 0.82, 32, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha * 0.72), 1.4)
		draw_line(center + Vector2(-side * radius * 0.34, -radius * 0.10), center + Vector2(side * radius * 0.38, radius * 0.16), Color(1.0, 0.90, 0.58, alpha * 0.58), 1.1)
		return
	match faction:
		"taiji":
			draw_arc(center, radius, 0.0, TAU, 36, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha), 1.4)
			draw_arc(center, radius * 0.52, -PI * 0.5, PI * 0.5, 20, Color(1.0, 0.95, 0.78, alpha * 0.62), 1.1)
		"flower":
			for i in range(5):
				var angle := phase * 0.22 + float(i) * TAU / 5.0
				draw_circle(center + Vector2(cos(angle), sin(angle) * 0.46) * radius * 0.42, 2.0, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha))
		"xueshan":
			for i in range(4):
				var angle := float(i) * PI * 0.25
				var arm := Vector2(cos(angle), sin(angle) * 0.55) * radius * 0.50
				draw_line(center - arm, center + arm, Color(0.82, 0.94, 1.0, alpha), 1.0)
		"honglian":
			draw_arc(center, radius * 0.72, PI * 0.10, PI * 1.05, 28, Color(1.0, 0.44, 0.22, alpha), 1.6)
			draw_line(center + Vector2(-side * radius * 0.18, radius * 0.14), center + Vector2(side * radius * 0.08, -radius * 0.44), Color(1.0, 0.82, 0.38, alpha * 0.70), 1.1)
		"naja":
			draw_arc(center, radius * 0.68, PI * 0.15, PI * 1.20, 28, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha), 1.4)
			draw_circle(center + Vector2(side * radius * 0.28, -radius * 0.12), 2.0, Color(0.42, 0.92, 0.46, alpha))
		"bagua":
			draw_arc(center, radius * 0.80, 0.0, TAU, 32, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha * 0.90), 1.2)
			for i in range(4):
				var p := center + Vector2(cos(float(i) * PI * 0.5), sin(float(i) * PI * 0.5) * 0.50) * radius * 0.48
				draw_line(p - Vector2(3.0, 0.0), p + Vector2(3.0, 0.0), Color(1.0, 0.90, 0.58, alpha * 0.62), 1.0)
		"xiaoyao":
			draw_arc(center, radius * 0.82, PI * 0.06, PI * 0.86, 28, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha), 1.5)
			draw_arc(center + Vector2(side * radius * 0.14, radius * 0.10), radius * 0.50, PI * 1.08, PI * 1.70, 18, Color(1.0, 0.94, 0.70, alpha * 0.52), 1.0)
		_:
			draw_arc(center, radius * 0.74, PI * 0.10, PI * 0.90, 28, Color(sigil_color.r, sigil_color.g, sigil_color.b, alpha), 1.3)

func _draw_stage_player_ground_lock(accent: Color, depth_scale: float, moving: bool, lane_offset_y: float = 0.0) -> void:
	var step := absf(sin(walk_phase)) if moving else 0.28 + sin(walk_phase * 0.55) * 0.08
	var center := Vector2(3.0, 36.0 * depth_scale + lane_offset_y)
	var alpha := PLAYER_STAGE_GROUND_LOCK_ALPHA * (0.52 + step * 0.26)
	if stage_lane_lock_strength > 0.02:
		var lane_alpha := PLAYER_STAGE_LANE_LOCK_ALPHA * stage_lane_lock_strength * (0.70 + step * 0.18)
		var raw_center := Vector2(3.0, 36.0 * depth_scale)
		draw_line(
			Vector2(-46.0, center.y - 1.8) * Vector2(depth_scale, 1.0),
			Vector2(50.0, center.y - 3.4) * Vector2(depth_scale, 1.0),
			Color(accent.r, accent.g, accent.b, lane_alpha),
			1.2 + depth_scale * 0.22
		)
		if absf(lane_offset_y) > 2.0:
			draw_line(raw_center, center, Color(1.0, 0.86, 0.48, lane_alpha * 0.36), 1.0)
	_draw_shadow(center, Vector2(34.0, 4.6) * depth_scale, Color(0.0, 0.0, 0.0, alpha))
	_draw_shadow(center + Vector2(0.0, 1.6 * depth_scale), Vector2(19.0, 2.2) * depth_scale, Color(accent.r, accent.g, accent.b, alpha * 0.32))
	draw_line(
		center + Vector2(-20.0, -1.4) * depth_scale,
		center + Vector2(22.0, -2.2 + step * 0.7) * depth_scale,
		Color(1.0, 0.86, 0.48, alpha * 0.34),
		1.2 + depth_scale * 0.28
	)

func _draw_stage_player_run_ribbons(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	if not moving:
		return
	var step := absf(sin(walk_phase))
	var waist := top_left + Vector2(draw_size.x * (0.50 - 0.08 * side), draw_size.y * 0.58)
	for i in range(PLAYER_STAGE_RUN_RIBBON_COUNT):
		var layer := float(i)
		var start := waist + Vector2(-side * draw_size.x * (0.08 + layer * 0.045), draw_size.y * (0.03 + layer * 0.028))
		var end := start + Vector2(-side * draw_size.x * (0.24 + layer * 0.065), draw_size.y * (0.030 + step * 0.030 + layer * 0.010))
		var alpha := PLAYER_STAGE_RUN_RIBBON_ALPHA * (0.82 - layer * 0.16) * (0.58 + step * 0.42)
		draw_line(start, end, Color(accent.r, accent.g, accent.b, alpha), clampf(draw_size.x * (0.017 - layer * 0.002), 1.1, 2.3))

func _draw_stage_player_stance_lines(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.05 if moving else 0.56))
	var alpha := PLAYER_STAGE_STANCE_LINE_ALPHA * (0.58 + absf(phase) * 0.28)
	var shoulder_back := top_left + Vector2(draw_size.x * (0.37 - 0.05 * side), draw_size.y * 0.31)
	var shoulder_front := top_left + Vector2(draw_size.x * (0.58 + 0.07 * side), draw_size.y * (0.34 + phase * 0.006))
	var hip := top_left + Vector2(draw_size.x * (0.49 + 0.04 * side), draw_size.y * 0.62)
	var front_knee := top_left + Vector2(draw_size.x * (0.57 + 0.12 * side + phase * 0.018), draw_size.y * 0.80)
	var back_knee := top_left + Vector2(draw_size.x * (0.42 - 0.08 * side - phase * 0.014), draw_size.y * 0.82)
	draw_line(shoulder_back, shoulder_front, Color(1.0, 0.92, 0.62, alpha * 0.82), clampf(draw_size.x * 0.011, 1.0, 1.8))
	draw_line(shoulder_front, hip, Color(accent.r, accent.g, accent.b, alpha), clampf(draw_size.x * 0.014, 1.1, 2.4))
	draw_line(hip, front_knee, Color(accent.r, accent.g, accent.b, alpha * 0.58), clampf(draw_size.x * 0.011, 1.0, 1.8))
	draw_line(hip, back_knee, Color(0.08, 0.07, 0.055, alpha * 0.46), clampf(draw_size.x * 0.010, 0.9, 1.6))

func _draw_sprite_motion_accents(lean: float, foot_y: float, draw_size: Vector2, trim: Color, moving: bool, stage_actor: bool = false) -> void:
	var waist_y := foot_y - draw_size.y * 0.46
	var flutter := sin(walk_phase * (1.3 if moving else 0.75))
	var accent_alpha := (0.34 if moving else 0.22) if stage_actor else (0.28 if moving else 0.18)
	var left := Vector2(-draw_size.x * 0.26 + lean, waist_y)
	var right := Vector2(draw_size.x * 0.26 + lean, waist_y + flutter * 1.8)
	draw_line(left, right, Color(trim.r, trim.g, trim.b, accent_alpha), 2.6 if stage_actor else 2.0)
	if moving:
		var trail := -facing.normalized() * 10.0
		draw_line(Vector2(lean, foot_y - draw_size.y * 0.20), Vector2(lean, foot_y - draw_size.y * 0.20) + trail, Color(1.0, 0.92, 0.62, 0.18), 1.8)
	elif stage_actor:
		var guard_y := foot_y - draw_size.y * 0.18
		draw_line(Vector2(-draw_size.x * 0.18 + lean, guard_y), Vector2(draw_size.x * 0.18 + lean, guard_y + flutter * 1.2), Color(1.0, 0.90, 0.58, 0.13), 1.6)

func _draw_stage_actor_sash(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool) -> void:
	var flutter := sin(walk_phase * (1.15 if moving else 0.72))
	var waist := top_left + Vector2(draw_size.x * 0.43, draw_size.y * 0.52)
	var tail_a := waist + Vector2(-draw_size.x * (0.30 + flutter * 0.025), draw_size.y * (0.10 + flutter * 0.012))
	var tail_b := waist + Vector2(-draw_size.x * (0.22 - flutter * 0.018), draw_size.y * (0.18 - flutter * 0.010))
	var sash_width := clampf(draw_size.x * 0.030, 2.4, 4.2)
	var shadow_accent := accent.darkened(0.16)
	draw_line(waist, tail_a, Color(accent.r, accent.g, accent.b, 0.24), sash_width)
	draw_line(waist + Vector2(draw_size.x * 0.04, draw_size.y * 0.035), tail_b, Color(shadow_accent.r, shadow_accent.g, shadow_accent.b, 0.18), sash_width * 0.75)

func _draw_player_contact_glow(accent: Color, depth_scale: float, moving: bool, lane_offset_y: float = 0.0) -> void:
	var pulse := 0.5 + sin(walk_phase * (1.7 if moving else 0.9)) * 0.5
	var center := Vector2(3.0 * depth_scale, 32.0 * depth_scale + lane_offset_y * 0.82)
	_draw_shadow(center, Vector2(38.0, 9.5) * depth_scale, Color(accent.r, accent.g, accent.b, PLAYER_CONTACT_GLOW_ALPHA * (0.55 + pulse * 0.25)))
	_draw_shadow(center + Vector2(0.0, 2.0 * depth_scale), Vector2(23.0, 4.8) * depth_scale, Color(1.0, 0.86, 0.50, PLAYER_CONTACT_GLOW_ALPHA * 0.55))

func _draw_player_idle_motes(accent: Color, depth_scale: float) -> void:
	var faction := str(GameState.player.get("faction", "none"))
	if faction == "none":
		return
	for i in range(PLAYER_FACTION_MOTES):
		var angle := walk_phase * 0.18 + float(i) * TAU / float(PLAYER_FACTION_MOTES)
		var radius := (22.0 + float(i % 4) * 5.0) * depth_scale
		var pos := Vector2(cos(angle) * radius, -18.0 * depth_scale + sin(angle) * radius * 0.36)
		var alpha := 0.045 + float(i % 3) * 0.012
		draw_circle(pos, (1.2 + float(i % 2) * 0.35) * depth_scale, Color(accent.r, accent.g, accent.b, alpha))

func _draw_sprite_rim_light(top_left: Vector2, draw_size: Vector2, accent: Color, stage_actor: bool = false) -> void:
	var rim_alpha := PLAYER_STAGE_RIM_ALPHA if stage_actor else PLAYER_STAGE_RIM_ALPHA * 0.80
	var left := top_left + Vector2(draw_size.x * 0.20, draw_size.y * 0.18)
	var right := top_left + Vector2(draw_size.x * 0.80, draw_size.y * 0.72)
	draw_line(left, right, Color(accent.r, accent.g, accent.b, rim_alpha), 1.8)
	draw_line(top_left + Vector2(draw_size.x * 0.22, draw_size.y * 0.05), top_left + Vector2(draw_size.x * 0.72, draw_size.y * 0.14), Color(1.0, 0.96, 0.78, rim_alpha * 0.62), 1.2)
