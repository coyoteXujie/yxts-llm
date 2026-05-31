extends CharacterBody2D
class_name PlayerActor

const SPEED := 190.0
const DRAW_SCALE := 0.86

var movement_enabled := true
var world_map: Node = null
var facing := Vector2.DOWN
var walk_phase := 0.0
var sprite_texture: Texture2D
var sprite_key := ""

func _ready() -> void:
	z_index = int(position.y)
	if not EventBus.player_changed.is_connected(_on_player_changed):
		EventBus.player_changed.connect(_on_player_changed)
	_refresh_sprite_texture()

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
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
		walk_phase += 0.18
		queue_redraw()

	var previous_position := position
	velocity = input_vector * SPEED
	move_and_slide()

	if world_map != null and not world_map.is_position_walkable(position):
		position = previous_position
		velocity = Vector2.ZERO
	z_index = int(position.y)

func _draw() -> void:
	_refresh_sprite_texture()
	var faction := str(GameState.player.get("faction", "none"))
	var robe := _robe_color(faction)
	var trim := GameData.get_faction_color(faction).lightened(0.18)
	var skin := Color(0.88, 0.73, 0.58)
	var ink := Color(0.08, 0.07, 0.06)
	var bob := sin(walk_phase) * 1.5 if velocity.length() > 1.0 else 0.0

	_draw_shadow(Vector2(3, 27), Vector2(30, 10), Color(0, 0, 0, 0.20))
	if sprite_texture != null:
		var texture_size := sprite_texture.get_size()
		var target_height := 74.0
		var target_width := 58.0
		var factor: float = min(target_height / max(texture_size.y, 1.0), target_width / max(texture_size.x, 1.0))
		var draw_size := texture_size * factor
		var top_left := Vector2(-draw_size.x * 0.5, 31.0 - draw_size.y + bob)
		draw_texture_rect(sprite_texture, Rect2(top_left, draw_size), false)
		var dir := facing.normalized()
		draw_line(Vector2(0, 2 + bob), dir * 16.0 + Vector2(0, bob), Color(1.0, 1.0, 1.0, 0.16), 1.8)
		return
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE * DRAW_SCALE)

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
	sprite_texture = GameData.load_texture(path)
	if sprite_texture == null:
		sprite_texture = GameData.load_texture("res://assets/characters/player/player_male_none.png")

func _draw_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)
