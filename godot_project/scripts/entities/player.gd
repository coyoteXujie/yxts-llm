extends CharacterBody2D
class_name PlayerActor

const SPEED := 190.0
const DRAW_SCALE := 1.0
const SPRITE_TARGET_HEIGHT := 112.0
const SPRITE_TARGET_WIDTH := 90.0
const STEP_DUST_RADIUS := Vector2(10.0, 3.2)
const PLAYER_CONTACT_GLOW_ALPHA := 0.13
const PLAYER_FACTION_MOTES := 10
const STAGE_DEPTH_SCALE_MIN := 0.78
const STAGE_DEPTH_SCALE_MAX := 1.22

var movement_enabled := true
var world_map: Node = null
var facing := Vector2.DOWN
var walk_phase := 0.0
var sprite_texture: Texture2D
var sprite_key := ""
var stage_depth_scale := 1.0

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
	var moving := movement_enabled and velocity.length() > 1.0
	walk_phase += delta * (10.5 if moving else 1.45)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		_refresh_stage_depth_scale()
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
	z_index = int(position.y)

func _draw() -> void:
	_refresh_sprite_texture()
	_refresh_stage_depth_scale()
	var faction := str(GameState.player.get("faction", "none"))
	var robe := _robe_color(faction)
	var trim := GameData.get_faction_color(faction).lightened(0.18)
	var skin := Color(0.88, 0.73, 0.58)
	var ink := Color(0.08, 0.07, 0.06)
	var moving := velocity.length() > 1.0
	var depth_scale := stage_depth_scale
	var bob := (sin(walk_phase) * 3.2 if moving else sin(walk_phase) * 0.75) * depth_scale
	var lean := (clampf(facing.x, -1.0, 1.0) * 2.2 if moving else sin(walk_phase * 0.6) * 0.45) * depth_scale

	_draw_step_dust(moving, depth_scale)
	_draw_player_contact_glow(trim, depth_scale, moving)
	_draw_player_idle_motes(trim, depth_scale)
	_draw_actor_shadow(Vector2(4 * depth_scale, 32 * depth_scale), Vector2(42, 13) * depth_scale, 1.0)
	if sprite_texture != null:
		var texture_size := sprite_texture.get_size()
		var target_height := SPRITE_TARGET_HEIGHT * depth_scale
		var target_width := SPRITE_TARGET_WIDTH * depth_scale
		var factor: float = min(target_height / max(texture_size.y, 1.0), target_width / max(texture_size.x, 1.0))
		var breath := 1.0 + sin(walk_phase * 0.72) * (0.010 if moving else 0.018)
		var step_sway := absf(sin(walk_phase)) if moving else 0.0
		var draw_size := texture_size * factor * Vector2(1.0 + step_sway * 0.018, breath - step_sway * 0.006)
		var foot_y := 35.0 * depth_scale + bob
		var top_left := Vector2(-draw_size.x * 0.5 + lean, foot_y - draw_size.y)
		var outline_rect := Rect2(top_left - Vector2(2.5, 1.5), draw_size + Vector2(5.0, 5.0))
		draw_texture_rect(sprite_texture, outline_rect, false, Color(0.02, 0.018, 0.014, 0.58))
		draw_texture_rect(sprite_texture, Rect2(top_left, draw_size), false)
		_draw_sprite_rim_light(top_left, draw_size, trim)
		_draw_sprite_motion_accents(lean, foot_y, draw_size, trim, moving)
		var dir := facing.normalized()
		draw_line(Vector2(0, 4 * depth_scale + bob), dir * 18.0 * depth_scale + Vector2(0, bob), Color(1.0, 1.0, 1.0, 0.18), 1.8)
		return
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE * DRAW_SCALE * depth_scale)

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

func _refresh_stage_depth_scale() -> void:
	if world_map != null and world_map.has_method("get_actor_depth_scale"):
		set_stage_depth_scale(float(world_map.get_actor_depth_scale(position)))
	else:
		set_stage_depth_scale(1.0)

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

func _draw_sprite_motion_accents(lean: float, foot_y: float, draw_size: Vector2, trim: Color, moving: bool) -> void:
	var waist_y := foot_y - draw_size.y * 0.46
	var flutter := sin(walk_phase * (1.3 if moving else 0.75))
	var accent_alpha := 0.28 if moving else 0.18
	var left := Vector2(-draw_size.x * 0.26 + lean, waist_y)
	var right := Vector2(draw_size.x * 0.26 + lean, waist_y + flutter * 1.8)
	draw_line(left, right, Color(trim.r, trim.g, trim.b, accent_alpha), 2.0)
	if moving:
		var trail := -facing.normalized() * 10.0
		draw_line(Vector2(lean, foot_y - draw_size.y * 0.20), Vector2(lean, foot_y - draw_size.y * 0.20) + trail, Color(1.0, 0.92, 0.62, 0.18), 1.8)

func _draw_player_contact_glow(accent: Color, depth_scale: float, moving: bool) -> void:
	var pulse := 0.5 + sin(walk_phase * (1.7 if moving else 0.9)) * 0.5
	var center := Vector2(3.0, 32.0) * depth_scale
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

func _draw_sprite_rim_light(top_left: Vector2, draw_size: Vector2, accent: Color) -> void:
	var left := top_left + Vector2(draw_size.x * 0.20, draw_size.y * 0.18)
	var right := top_left + Vector2(draw_size.x * 0.80, draw_size.y * 0.72)
	draw_line(left, right, Color(accent.r, accent.g, accent.b, 0.16), 1.8)
	draw_line(top_left + Vector2(draw_size.x * 0.22, draw_size.y * 0.05), top_left + Vector2(draw_size.x * 0.72, draw_size.y * 0.14), Color(1.0, 0.96, 0.78, 0.10), 1.2)
