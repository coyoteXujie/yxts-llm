extends CharacterBody2D
class_name PlayerActor

const StageVisualProfile = preload("res://scripts/shared/stage_visual_profile.gd")

const SPEED := 190.0
const DRAW_SCALE := 1.0
const SPRITE_TARGET_HEIGHT := StageVisualProfile.STAGE_SIDE_VIEW_ENTITY_HEIGHT
const SPRITE_TARGET_WIDTH := StageVisualProfile.STAGE_SIDE_VIEW_PLAYER_WIDTH
const STAGE_PRESENCE_SCALE := StageVisualProfile.STAGE_ACTOR_SCALE
const STAGE_ACTOR_SCALE_BIAS := StageVisualProfile.PLAYER_STAGE_SCALE_BIAS
const LOCAL_STAGE_PRESENCE_SCALE := STAGE_PRESENCE_SCALE
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
const PLAYER_STAGE_BREATH_AURA_RINGS := 3
const PLAYER_STAGE_BREATH_AURA_ALPHA := 0.18
const PLAYER_STAGE_CENTERLINE_ALPHA := 0.24
const PLAYER_STAGE_LANE_LOCK_ALPHA := 0.20
const PLAYER_STAGE_LANE_MAX_VISUAL_OFFSET := 22.0
const PLAYER_STAGE_HEAD_TURN_ALPHA := 0.20
const PLAYER_STAGE_WEIGHT_SHIFT_ALPHA := 0.22
const PLAYER_STAGE_SIDE_INPUT_DEADZONE := 0.20
const PLAYER_STAGE_TURN_ACCENT_ALPHA := 0.24
const PLAYER_STAGE_TURN_ACCENT_DURATION := 0.18
const PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED := true
const PLAYER_STAGE_TURN_BLEND_SPEED := 8.5
const PLAYER_STAGE_TURN_SETTLE_SPEED := 5.2
const PLAYER_STAGE_TURN_SQUASH_MIN := 0.78
const PLAYER_STAGE_TURN_BODY_SLIDE := 13.0
const PLAYER_STAGE_SIDE_PROFILE_ALPHA := 0.24
const PLAYER_STAGE_SIDE_PROFILE_SHADOW_ALPHA := 0.18
const PLAYER_STAGE_DIRECTIONAL_WEAPON_ALPHA := 0.32
const PLAYER_STAGE_RUN_STRIDE_ALPHA := 0.28
const PLAYER_SPRITE_SOURCE_FACES_LEFT := false
const STAGE_DEPTH_SCALE_MIN := 0.78
const STAGE_DEPTH_SCALE_MAX := 1.22
const PLAYER_SPRITE_OVERRIDES := {
	"male_none": "res://assets/characters/player/player_male_none_stage_v2.png"
}

var movement_enabled := true
var world_map: Node = null
var facing := Vector2.DOWN
var walk_phase := 0.0
var sprite_texture: Texture2D
var sprite_key := ""
var stage_depth_scale := 1.0
var stage_lane_offset_y := 0.0
var stage_lane_lock_strength := 0.0
var lateral_facing_side := 1.0
var has_lateral_facing_side := false
var turn_accent_timer := 0.0
var turn_accent_side := 1.0
var visual_facing_side := 1.0
var visual_facing_initialized := false
var stage_turn_progress := 0.0
var stage_turn_from_side := 1.0
var stage_turn_to_side := 1.0

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
	_update_stage_visual_facing(delta)
	var moving := movement_enabled and velocity.length() > 1.0
	walk_phase += delta * (10.5 if moving else 1.45)
	if turn_accent_timer > 0.0:
		turn_accent_timer = maxf(0.0, turn_accent_timer - delta)
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
		_update_lateral_facing(input_vector)
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
		var facing_side := _stage_draw_facing_side() if stage_actor else _facing_side()
		if stage_actor and PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
			var original_width := draw_size.x
			draw_size.x *= get_stage_pose_width_scale(moving)
			top_left.x += (original_width - draw_size.x) * 0.5 + get_stage_pose_x_offset(original_width, facing_side)
		var outline_rect := Rect2(top_left - Vector2(2.5, 1.5), draw_size + Vector2(5.0, 5.0))
		_draw_oriented_sprite_texture(sprite_texture, outline_rect, facing_side, Color(0.02, 0.018, 0.014, 0.58))
		if stage_actor:
			_draw_stage_player_directional_pose_layers(top_left, draw_size, trim, moving, facing_side, false)
			_draw_stage_player_run_ribbons(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_motion_afterimage(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_footwork(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_weight_shift(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_back_layers(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_pose_rig(top_left, draw_size, trim, moving, facing_side, false)
			_draw_stage_actor_sash(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_faction_sigil(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_breath_aura(top_left, draw_size, trim, moving, facing_side)
		_draw_oriented_sprite_texture(sprite_texture, Rect2(top_left, draw_size), facing_side)
		if stage_actor:
			_draw_stage_player_directional_pose_layers(top_left, draw_size, trim, moving, facing_side, true)
			_draw_stage_player_pose_rig(top_left, draw_size, trim, moving, facing_side, true)
			_draw_stage_player_step_arcs(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_front_layers(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_idle_cloth_sway(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_ready_stance(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_weapon_pose(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_shoulder_glow(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_stance_lines(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_head_focus(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_head_turn(top_left, draw_size, trim, moving, facing_side)
			_draw_stage_player_turn_accent(top_left, draw_size, trim, facing_side)
		_draw_sprite_rim_light(top_left, draw_size, trim, stage_actor, facing_side)
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
	return stage_depth_scale * (LOCAL_STAGE_PRESENCE_SCALE * STAGE_ACTOR_SCALE_BIAS if _is_side_view_stage() else 1.0)

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
	if absf(facing.x) > PLAYER_STAGE_SIDE_INPUT_DEADZONE:
		return -1.0 if facing.x < 0.0 else 1.0
	if has_lateral_facing_side:
		return lateral_facing_side
	if _is_side_view_stage() and world_map != null and world_map.has_method("get_stage_actor_facing_side"):
		return float(world_map.call("get_stage_actor_facing_side", position))
	return 1.0

func _update_lateral_facing(input_vector: Vector2) -> void:
	if absf(input_vector.x) <= PLAYER_STAGE_SIDE_INPUT_DEADZONE:
		return
	var previous_side := lateral_facing_side if has_lateral_facing_side else _facing_side()
	var next_side := -1.0 if input_vector.x < 0.0 else 1.0
	if not has_lateral_facing_side or absf(next_side - lateral_facing_side) > 0.01:
		turn_accent_timer = PLAYER_STAGE_TURN_ACCENT_DURATION
		turn_accent_side = next_side
		_begin_stage_turn(previous_side, next_side)
	lateral_facing_side = next_side
	has_lateral_facing_side = true

func _begin_stage_turn(previous_side: float, next_side: float) -> void:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return
	var from_side := -1.0 if previous_side < 0.0 else 1.0
	var to_side := -1.0 if next_side < 0.0 else 1.0
	if absf(from_side - to_side) <= 0.01:
		return
	stage_turn_from_side = from_side
	stage_turn_to_side = to_side
	stage_turn_progress = 1.0
	if not visual_facing_initialized:
		visual_facing_side = from_side
		visual_facing_initialized = true

func _update_stage_visual_facing(delta: float) -> void:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return
	var target_side := _facing_side()
	target_side = -1.0 if target_side < 0.0 else 1.0
	if not visual_facing_initialized:
		visual_facing_side = target_side
		visual_facing_initialized = true
	if absf(target_side - _stage_draw_facing_side()) > 0.01 and stage_turn_progress <= 0.0:
		_begin_stage_turn(_stage_draw_facing_side(), target_side)
	var step := maxf(delta * PLAYER_STAGE_TURN_BLEND_SPEED, 0.0)
	visual_facing_side = move_toward(visual_facing_side, target_side, step)
	if absf(visual_facing_side) < 0.05:
		visual_facing_side = target_side * 0.05
	if stage_turn_progress > 0.0:
		stage_turn_progress = maxf(0.0, stage_turn_progress - delta * PLAYER_STAGE_TURN_SETTLE_SPEED)

func _stage_draw_facing_side() -> float:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return _facing_side()
	if stage_turn_progress > 0.01:
		return stage_turn_to_side
	if not visual_facing_initialized:
		return _facing_side()
	if absf(visual_facing_side) < 0.05:
		return _facing_side()
	return -1.0 if visual_facing_side < 0.0 else 1.0

func get_stage_turn_strength() -> float:
	return clampf(stage_turn_progress, 0.0, 1.0)

func get_stage_pose_width_scale(moving: bool = false) -> float:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return 1.0
	var turn_strength := get_stage_turn_strength()
	var stride_bonus := absf(sin(walk_phase)) * 0.018 if moving else 0.0
	var width_scale := 1.0 - turn_strength * (1.0 - PLAYER_STAGE_TURN_SQUASH_MIN) + stride_bonus
	return clampf(width_scale, PLAYER_STAGE_TURN_SQUASH_MIN, 1.04)

func get_stage_pose_x_offset(draw_width: float, side: float) -> float:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return 0.0
	var turn_strength := get_stage_turn_strength()
	var side_amount := clampf(absf(visual_facing_side), 0.0, 1.0)
	var turn_slide := PLAYER_STAGE_TURN_BODY_SLIDE * turn_strength
	var profile_slide := draw_width * 0.018 * (1.0 - side_amount)
	return side * (turn_slide - profile_slide)

func _should_mirror_sprite_for_side(side: float) -> bool:
	var desired_side := -1.0 if side < 0.0 else 1.0
	var source_side := -1.0 if PLAYER_SPRITE_SOURCE_FACES_LEFT else 1.0
	return absf(desired_side - source_side) > 0.01

func _draw_oriented_sprite_texture(texture: Texture2D, rect: Rect2, side: float, modulate: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	if texture == null:
		return
	if not _should_mirror_sprite_for_side(side):
		draw_texture_rect(texture, rect, false, modulate)
		return
	draw_set_transform(rect.position + Vector2(rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(texture, Rect2(Vector2.ZERO, rect.size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _refresh_sprite_texture(force: bool = false) -> void:
	var gender := str(GameState.player.get("gender", "male"))
	if gender != "female":
		gender = "male"
	var faction := str(GameState.player.get("faction", "none"))
	var key := "%s_%s" % [gender, faction]
	if not force and key == sprite_key:
		return
	sprite_key = key
	var path := str(PLAYER_SPRITE_OVERRIDES.get(key, "res://assets/characters/player/player_%s_%s.png" % [gender, faction]))
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

func _draw_stage_motion_afterimage(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	if not moving or sprite_texture == null:
		return
	var dir := facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var step := absf(sin(walk_phase))
	var offset := -dir * clampf(draw_size.y * 0.055, 4.0, 9.0)
	offset.x -= side * clampf(draw_size.x * 0.026, 2.0, 5.5)
	var alpha := PLAYER_MOTION_AFTERIMAGE_ALPHA * (0.45 + step * 0.55)
	_draw_oriented_sprite_texture(sprite_texture, Rect2(top_left + offset, draw_size), side, Color(accent.r, accent.g, accent.b, alpha))

func _draw_stage_player_directional_pose_layers(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float, front_layer: bool) -> void:
	if not PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED:
		return
	var turn_strength := get_stage_turn_strength()
	var phase := sin(walk_phase * (1.34 if moving else 0.62))
	var side_amount := clampf(absf(visual_facing_side), 0.0, 1.0)
	var shoulder := top_left + Vector2(draw_size.x * (0.50 + side * (0.135 + phase * 0.006)), draw_size.y * 0.335)
	var hip := top_left + Vector2(draw_size.x * (0.50 + side * (0.045 + phase * 0.010)), draw_size.y * 0.635)
	var foot := top_left + Vector2(draw_size.x * (0.50 + side * (0.210 + phase * 0.024)), draw_size.y * 0.958)
	if not front_layer:
		var rear_alpha := PLAYER_STAGE_SIDE_PROFILE_SHADOW_ALPHA * (0.66 + turn_strength * 0.58)
		var rear_shoulder := top_left + Vector2(draw_size.x * (0.50 - side * 0.120), draw_size.y * 0.360)
		var rear_hip := top_left + Vector2(draw_size.x * (0.48 - side * 0.095), draw_size.y * 0.660)
		var rear_hem := top_left + Vector2(draw_size.x * (0.47 - side * (0.185 + phase * 0.018)), draw_size.y * 0.925)
		draw_polygon(PackedVector2Array([rear_shoulder, rear_hip, rear_hem, top_left + Vector2(draw_size.x * (0.50 - side * 0.020), draw_size.y * 0.790)]), PackedColorArray([
			Color(0.020, 0.016, 0.012, rear_alpha * 0.78),
			Color(0.020, 0.016, 0.012, rear_alpha),
			Color(0.020, 0.016, 0.012, rear_alpha * 0.62),
			Color(accent.r, accent.g, accent.b, rear_alpha * 0.42)
		]))
		if turn_strength > 0.02:
			var old_side := stage_turn_from_side
			var old_shoulder := top_left + Vector2(draw_size.x * (0.50 + old_side * 0.18), draw_size.y * 0.325)
			var old_foot := top_left + Vector2(draw_size.x * (0.50 + old_side * 0.245), draw_size.y * 0.945)
			draw_line(old_foot, old_shoulder, Color(accent.r, accent.g, accent.b, PLAYER_STAGE_TURN_ACCENT_ALPHA * turn_strength * 0.50), clampf(draw_size.x * 0.011, 1.0, 1.8))
			draw_arc(old_shoulder, draw_size.x * 0.13, -PI * 0.28, PI * 0.64, 18, Color(1.0, 0.88, 0.52, PLAYER_STAGE_TURN_ACCENT_ALPHA * turn_strength * 0.58), 1.2)
		return

	var profile_alpha := PLAYER_STAGE_SIDE_PROFILE_ALPHA * (0.58 + side_amount * 0.20 + turn_strength * 0.34)
	var chest := top_left + Vector2(draw_size.x * (0.50 + side * (0.095 + phase * 0.010)), draw_size.y * 0.475)
	var front_hand := top_left + Vector2(draw_size.x * (0.50 + side * (0.295 + phase * 0.026)), draw_size.y * (0.505 + phase * 0.010))
	var back_hand := top_left + Vector2(draw_size.x * (0.50 - side * 0.135), draw_size.y * (0.535 - phase * 0.008))
	draw_line(shoulder, chest, Color(1.0, 0.90, 0.58, profile_alpha * 0.78), clampf(draw_size.x * 0.012, 1.0, 1.9))
	draw_line(chest, hip, Color(accent.r, accent.g, accent.b, profile_alpha), clampf(draw_size.x * 0.014, 1.1, 2.2))
	draw_line(chest, front_hand, Color(accent.r, accent.g, accent.b, profile_alpha * 0.92), clampf(draw_size.x * 0.016, 1.2, 2.5))
	draw_line(back_hand, chest, Color(0.030, 0.022, 0.016, profile_alpha * 0.70), clampf(draw_size.x * 0.012, 0.9, 1.8))
	var weapon_tip := front_hand + Vector2(side * draw_size.x * (0.270 + turn_strength * 0.060), -draw_size.y * (0.155 + phase * 0.014))
	draw_line(front_hand, weapon_tip, Color(0.96, 0.92, 0.74, PLAYER_STAGE_DIRECTIONAL_WEAPON_ALPHA * (0.72 + turn_strength * 0.22)), clampf(draw_size.x * 0.012, 1.0, 2.0))
	draw_line(weapon_tip - Vector2(side * draw_size.x * 0.040, -draw_size.y * 0.012), weapon_tip + Vector2(side * draw_size.x * 0.050, draw_size.y * 0.024), Color(1.0, 0.82, 0.36, PLAYER_STAGE_DIRECTIONAL_WEAPON_ALPHA * 0.46), 1.0)
	var head := top_left + Vector2(draw_size.x * (0.50 + side * (0.042 + turn_strength * 0.018)), draw_size.y * 0.225)
	draw_arc(head + Vector2(side * draw_size.x * 0.012, draw_size.y * 0.006), draw_size.x * 0.060, -PI * 0.40, PI * 0.50, 18, Color(1.0, 0.90, 0.60, profile_alpha * 0.66), 1.0)
	draw_line(head, head + Vector2(side * draw_size.x * 0.125, draw_size.y * (0.010 + phase * 0.004)), Color(1.0, 0.95, 0.72, profile_alpha * 0.62), 1.0)
	if moving:
		var stride_alpha := PLAYER_STAGE_RUN_STRIDE_ALPHA * (0.62 + absf(phase) * 0.28)
		draw_line(hip, foot, Color(accent.r, accent.g, accent.b, stride_alpha * 0.70), clampf(draw_size.x * 0.011, 0.9, 1.7))
		for index in range(2):
			var layer := float(index)
			var start := foot - Vector2(side * draw_size.x * (0.080 + layer * 0.050), draw_size.y * (0.010 + layer * 0.014))
			var end := start + Vector2(side * draw_size.x * (0.180 + layer * 0.045), -draw_size.y * (0.018 + layer * 0.010))
			draw_line(start, end, Color(1.0, 0.84, 0.40, stride_alpha * (0.54 - layer * 0.14)), 1.0)

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

func _draw_stage_player_weight_shift(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.18 if moving else 0.56))
	var support_side := side
	if moving and phase < 0.0:
		support_side = -side
	var foot_y := top_left.y + draw_size.y * 0.972
	var support := Vector2(top_left.x + draw_size.x * (0.50 + support_side * (0.160 + absf(phase) * 0.024)), foot_y - maxf(phase, 0.0) * draw_size.y * 0.010)
	var counter := Vector2(top_left.x + draw_size.x * (0.50 - support_side * (0.132 + absf(phase) * 0.018)), foot_y + draw_size.y * 0.006)
	var hip := top_left + Vector2(draw_size.x * (0.50 + support_side * (0.028 + phase * 0.010)), draw_size.y * 0.655)
	var alpha := PLAYER_STAGE_WEIGHT_SHIFT_ALPHA * (0.66 + absf(phase) * 0.28)
	_draw_shadow(support + Vector2(0.0, draw_size.y * 0.006), Vector2(draw_size.x * 0.082, draw_size.y * 0.012), Color(accent.r, accent.g, accent.b, alpha * 0.42))
	_draw_shadow(counter + Vector2(0.0, draw_size.y * 0.010), Vector2(draw_size.x * 0.060, draw_size.y * 0.009), Color(0.0, 0.0, 0.0, alpha * 0.34))
	draw_line(hip, support, Color(1.0, 0.90, 0.58, alpha * 0.64), clampf(draw_size.x * 0.009, 0.9, 1.5))
	draw_line(counter, support, Color(accent.r, accent.g, accent.b, alpha * 0.52), 1.0)
	draw_arc(support - Vector2(support_side * draw_size.x * 0.010, draw_size.y * 0.012), draw_size.x * 0.080, PI * 0.08, PI * 0.90, 18, Color(accent.r, accent.g, accent.b, alpha * 0.58), 1.0)

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

func _draw_stage_player_head_turn(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var phase := sin(walk_phase * (1.02 if moving else 0.52))
	var head := top_left + Vector2(draw_size.x * (0.50 + side * (0.028 + phase * 0.008)), draw_size.y * (0.224 + phase * 0.004))
	var alpha := PLAYER_STAGE_HEAD_TURN_ALPHA * (0.64 + absf(phase) * 0.30)
	var radius := draw_size.x * 0.055
	draw_arc(head + Vector2(side * draw_size.x * 0.010, draw_size.y * 0.010), radius, -PI * 0.42, PI * 0.48, 18, Color(accent.r, accent.g, accent.b, alpha * 0.72), 1.0)
	var brow_start := head + Vector2(-side * draw_size.x * 0.018, -draw_size.y * 0.008)
	var brow_end := head + Vector2(side * draw_size.x * 0.070, -draw_size.y * (0.018 + phase * 0.004))
	draw_line(brow_start, brow_end, Color(0.05, 0.038, 0.030, alpha * 0.95), clampf(draw_size.x * 0.008, 0.8, 1.2))
	var eye := head + Vector2(side * draw_size.x * 0.060, draw_size.y * 0.006)
	draw_circle(eye, clampf(draw_size.x * 0.010, 0.9, 1.5), Color(1.0, 0.92, 0.62, alpha * 0.92))
	var chin := head + Vector2(side * draw_size.x * 0.040, draw_size.y * 0.050)
	draw_line(chin, chin + Vector2(side * draw_size.x * 0.050, draw_size.y * 0.020), Color(0.05, 0.04, 0.034, alpha * 0.58), 0.9)

func _draw_stage_player_turn_accent(top_left: Vector2, draw_size: Vector2, accent: Color, side: float) -> void:
	if turn_accent_timer <= 0.0:
		return
	var progress := 1.0 - clampf(turn_accent_timer / PLAYER_STAGE_TURN_ACCENT_DURATION, 0.0, 1.0)
	var pulse := sin(progress * PI)
	var active_side := turn_accent_side if absf(turn_accent_side) > 0.01 else side
	var alpha := PLAYER_STAGE_TURN_ACCENT_ALPHA * pulse
	var shoulder := top_left + Vector2(draw_size.x * (0.50 + active_side * 0.18), draw_size.y * 0.34)
	var hip := top_left + Vector2(draw_size.x * (0.50 - active_side * 0.08), draw_size.y * 0.62)
	var foot := top_left + Vector2(draw_size.x * (0.50 + active_side * 0.24), draw_size.y * 0.955)
	var weapon_tip := shoulder + Vector2(active_side * draw_size.x * (0.26 + progress * 0.08), -draw_size.y * (0.15 + progress * 0.04))
	draw_arc(shoulder, draw_size.x * (0.13 + progress * 0.035), -PI * 0.34, PI * 0.60, 18, Color(1.0, 0.92, 0.58, alpha * 0.78), 1.5)
	draw_line(hip, shoulder, Color(accent.r, accent.g, accent.b, alpha * 0.72), clampf(draw_size.x * 0.013, 1.0, 2.2))
	draw_line(shoulder, weapon_tip, Color(0.96, 0.92, 0.76, alpha), clampf(draw_size.x * 0.012, 1.0, 2.0))
	draw_line(foot - Vector2(active_side * draw_size.x * 0.10, draw_size.y * 0.006), foot + Vector2(active_side * draw_size.x * 0.12, -draw_size.y * 0.012), Color(1.0, 0.82, 0.38, alpha * 0.62), 1.1)

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

func _draw_stage_player_breath_aura(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	if moving:
		return
	var faction := str(GameState.player.get("faction", "none"))
	var phase := sin(walk_phase * 0.62)
	var center := top_left + Vector2(draw_size.x * (0.50 + side * 0.024), draw_size.y * 0.620)
	for i in range(PLAYER_STAGE_BREATH_AURA_RINGS):
		var layer := float(i) / float(maxi(1, PLAYER_STAGE_BREATH_AURA_RINGS - 1))
		var radius := draw_size.x * (0.225 + layer * 0.070 + phase * 0.006)
		var y_offset := draw_size.y * (-0.020 + layer * 0.045)
		var alpha := PLAYER_STAGE_BREATH_AURA_ALPHA * (0.62 - layer * 0.13 + absf(phase) * 0.12)
		var ring_center := center + Vector2(side * draw_size.x * (0.014 + layer * 0.012), y_offset)
		draw_arc(ring_center, radius, PI * (0.06 + layer * 0.035), PI * (0.92 - layer * 0.025), 30, Color(accent.r, accent.g, accent.b, alpha), 1.1 + layer * 0.4)
		draw_arc(ring_center + Vector2(-side * draw_size.x * 0.020, draw_size.y * 0.050), radius * (0.68 - layer * 0.06), PI * 1.08, PI * 1.78, 24, Color(1.0, 0.92, 0.62, alpha * 0.48), 0.9)
	_draw_stage_player_faction_breath_detail(faction, center, draw_size, accent, side, phase)

func _draw_stage_player_faction_breath_detail(faction: String, center: Vector2, draw_size: Vector2, accent: Color, side: float, phase: float) -> void:
	var alpha := PLAYER_STAGE_BREATH_AURA_ALPHA * (0.72 + absf(phase) * 0.22)
	match faction:
		"taiji":
			draw_arc(center, draw_size.x * 0.22, PI * 0.02, PI * 1.04, 32, Color(accent.r, accent.g, accent.b, alpha * 0.74), 1.3)
			draw_arc(center + Vector2(side * draw_size.x * 0.030, draw_size.y * 0.026), draw_size.x * 0.145, PI * 1.02, PI * 1.92, 24, Color(1.0, 0.95, 0.78, alpha * 0.52), 1.0)
		"flower":
			for i in range(5):
				var angle := walk_phase * 0.18 + float(i) * TAU / 5.0
				var pos := center + Vector2(cos(angle), sin(angle) * 0.46) * draw_size.x * 0.185
				draw_circle(pos, clampf(draw_size.x * 0.014, 1.1, 2.0), Color(accent.r, accent.g, accent.b, alpha * 0.72))
		"xueshan":
			for i in range(4):
				var angle := float(i) * PI * 0.25
				var arm := Vector2(cos(angle), sin(angle) * 0.48) * draw_size.x * 0.155
				draw_line(center - arm, center + arm, Color(0.82, 0.94, 1.0, alpha * 0.70), 0.9)
		"honglian":
			for i in range(3):
				var x := center.x + side * draw_size.x * (-0.11 + float(i) * 0.095)
				var low := center.y + draw_size.y * 0.090
				var high := center.y - draw_size.y * (0.050 + float(i % 2) * 0.030 + absf(phase) * 0.014)
				draw_line(Vector2(x, low), Vector2(x + side * draw_size.x * 0.040, high), Color(1.0, 0.40, 0.16, alpha * 0.70), 1.2)
				draw_line(Vector2(x + side * draw_size.x * 0.030, low - draw_size.y * 0.030), Vector2(x - side * draw_size.x * 0.012, high + draw_size.y * 0.026), Color(1.0, 0.82, 0.38, alpha * 0.42), 0.8)
		"naja":
			var last := center + Vector2(-side * draw_size.x * 0.18, draw_size.y * 0.035)
			for i in range(1, 7):
				var t := float(i) / 6.0
				var pos := center + Vector2(lerpf(-side * draw_size.x * 0.18, side * draw_size.x * 0.18, t), sin(t * TAU + phase) * draw_size.y * 0.030)
				draw_line(last, pos, Color(accent.r, accent.g, accent.b, alpha * 0.66), 1.1)
				last = pos
		"bagua":
			for i in range(4):
				var angle := float(i) * PI * 0.5 + phase * 0.08
				var pos := center + Vector2(cos(angle), sin(angle) * 0.52) * draw_size.x * 0.18
				draw_line(pos - Vector2(side * draw_size.x * 0.030, 0.0), pos + Vector2(side * draw_size.x * 0.030, 0.0), Color(1.0, 0.90, 0.58, alpha * 0.64), 1.0)
		"xiaoyao":
			for i in range(3):
				var layer := float(i)
				var start := center + Vector2(-side * draw_size.x * (0.18 - layer * 0.035), draw_size.y * (0.050 + layer * 0.030))
				var end := start + Vector2(side * draw_size.x * (0.26 + layer * 0.030), -draw_size.y * (0.050 + absf(phase) * 0.020))
				draw_line(start, end, Color(accent.r, accent.g, accent.b, alpha * (0.68 - layer * 0.12)), 1.0)
		_:
			draw_line(center + Vector2(-side * draw_size.x * 0.18, draw_size.y * 0.06), center + Vector2(side * draw_size.x * 0.18, -draw_size.y * 0.02), Color(1.0, 0.90, 0.58, alpha * 0.48), 1.0)

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

func _draw_stage_actor_sash(top_left: Vector2, draw_size: Vector2, accent: Color, moving: bool, side: float) -> void:
	var flutter := sin(walk_phase * (1.15 if moving else 0.72))
	var waist := top_left + Vector2(draw_size.x * (0.50 - 0.10 * side), draw_size.y * 0.52)
	var tail_a := waist + Vector2(-side * draw_size.x * (0.30 + flutter * 0.025), draw_size.y * (0.10 + flutter * 0.012))
	var tail_b := waist + Vector2(-side * draw_size.x * (0.22 - flutter * 0.018), draw_size.y * (0.18 - flutter * 0.010))
	var sash_width := clampf(draw_size.x * 0.030, 2.4, 4.2)
	var shadow_accent := accent.darkened(0.16)
	draw_line(waist, tail_a, Color(accent.r, accent.g, accent.b, 0.24), sash_width)
	draw_line(waist + Vector2(side * draw_size.x * 0.04, draw_size.y * 0.035), tail_b, Color(shadow_accent.r, shadow_accent.g, shadow_accent.b, 0.18), sash_width * 0.75)

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

func _draw_sprite_rim_light(top_left: Vector2, draw_size: Vector2, accent: Color, stage_actor: bool = false, side: float = 1.0) -> void:
	var rim_alpha := PLAYER_STAGE_RIM_ALPHA if stage_actor else PLAYER_STAGE_RIM_ALPHA * 0.80
	var back := top_left + Vector2(draw_size.x * (0.50 - side * 0.28), draw_size.y * 0.18)
	var front := top_left + Vector2(draw_size.x * (0.50 + side * 0.30), draw_size.y * 0.72)
	draw_line(back, front, Color(accent.r, accent.g, accent.b, rim_alpha), 1.8)
	draw_line(
		top_left + Vector2(draw_size.x * (0.50 - side * 0.26), draw_size.y * 0.05),
		top_left + Vector2(draw_size.x * (0.50 + side * 0.22), draw_size.y * 0.14),
		Color(1.0, 0.96, 0.78, rim_alpha * 0.62),
		1.2
	)
