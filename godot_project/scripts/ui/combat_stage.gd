extends Control
class_name CombatStage

var enemy: Dictionary = {}
var snapshot: Dictionary = {}
var player_texture: Texture2D
var enemy_texture: Texture2D
var background_texture: Texture2D
var terrain_key := "plain"
var terrain_color := Color(0.35, 0.34, 0.25)
var accent_color := Color(0.86, 0.65, 0.34)
var last_event_id := 0
var event_timer := 0.0
var event_kind := ""
var event_target := ""
var pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(true)

func _process(delta: float) -> void:
	pulse += delta
	if event_timer > 0.0:
		event_timer = maxf(0.0, event_timer - delta)
	queue_redraw()

func setup(enemy_data: Dictionary) -> void:
	enemy = enemy_data.duplicate(true)
	snapshot = {}
	last_event_id = 0
	event_timer = 0.0
	event_kind = ""
	event_target = ""
	_refresh_assets()
	queue_redraw()

func update_snapshot(new_snapshot: Dictionary) -> void:
	snapshot = new_snapshot.duplicate(true)
	_consume_latest_event()
	queue_redraw()

func clear() -> void:
	enemy = {}
	snapshot = {}
	event_timer = 0.0
	event_kind = ""
	event_target = ""
	queue_redraw()

func _refresh_assets() -> void:
	player_texture = _load_player_texture()
	enemy_texture = _load_enemy_texture()
	background_texture = _load_region_background()
	var region: Dictionary = GameData.get_region(GameState.current_region_id)
	terrain_key = str(region.get("terrain", "plain"))
	terrain_color = _terrain_color(terrain_key, str(region.get("type", "wild")))
	accent_color = GameData.get_faction_color(str(GameState.player.get("faction", "none"))).lightened(0.08)

func _load_player_texture() -> Texture2D:
	var gender := str(GameState.player.get("gender", "male"))
	if gender != "female":
		gender = "male"
	var faction := str(GameState.player.get("faction", "none"))
	var path := "res://assets/characters/player/player_%s_%s.png" % [gender, faction]
	var texture := GameData.load_texture(path, true)
	if texture == null:
		texture = GameData.load_texture("res://assets/characters/player/player_male_none.png", true)
	return texture

func _load_enemy_texture() -> Texture2D:
	var path := GameData.get_npc_sprite_path(str(enemy.get("name", "")))
	if path.is_empty():
		return null
	return GameData.load_texture(path, true)

func _load_region_background() -> Texture2D:
	var region_id := GameState.current_region_id
	if region_id.is_empty():
		return null
	var path := GameData.get_scene_background_path(region_id)
	if path.is_empty():
		return null
	return GameData.load_texture(path, true)

func _consume_latest_event() -> void:
	var events: Array = snapshot.get("events", [])
	if events.is_empty():
		return
	var latest: Dictionary = events[events.size() - 1]
	var event_id := int(latest.get("id", 0))
	if event_id <= last_event_id:
		return
	last_event_id = event_id
	event_kind = str(latest.get("kind", "damage"))
	event_target = str(latest.get("target", "enemy"))
	event_timer = 0.48

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 100.0 or rect.size.y < 80.0:
		return
	_draw_backplate(rect)
	_draw_background(rect)
	_draw_parallax_silhouette(rect)
	_draw_lane(rect)
	_draw_combatants(rect)
	_draw_foreground(rect)
	_draw_frame(rect)

func _draw_backplate(rect: Rect2) -> void:
	draw_rect(rect, Color(0.04, 0.035, 0.028, 0.92), true)

func _draw_background(rect: Rect2) -> void:
	if background_texture != null:
		_draw_cover_texture(background_texture, rect, Color(0.88, 0.86, 0.78, 0.78))
	else:
		draw_rect(rect, terrain_color.darkened(0.48), true)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.44)), terrain_color.darkened(0.24), true)
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.44), Vector2(rect.size.x, rect.size.y * 0.56)), terrain_color.darkened(0.06), true)
	draw_rect(rect, Color(0.04, 0.035, 0.028, 0.26), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.26)), Color(0.0, 0.0, 0.0, 0.18), true)
	var haze_alpha := 0.11 + sin(pulse * 0.55) * 0.025
	for index in range(5):
		var y := rect.position.y + rect.size.y * (0.16 + float(index) * 0.105)
		var width := rect.size.x * (0.55 + float(index % 2) * 0.16)
		var x := rect.position.x + fmod(pulse * (8.0 + index * 2.0) + float(index) * 91.0, rect.size.x + width) - width
		_draw_soft_band(Rect2(Vector2(x, y), Vector2(width, 16 + index * 3)), Color(0.92, 0.88, 0.76, haze_alpha))

func _draw_cover_texture(texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale: float = maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var source_size := rect.size / scale
	var source_pos := (texture_size - source_size) * 0.5
	draw_texture_rect_region(texture, rect, Rect2(source_pos, source_size), modulate)

func _draw_parallax_silhouette(rect: Rect2) -> void:
	var horizon := rect.position.y + rect.size.y * 0.50
	var far := terrain_color.darkened(0.38)
	var mid := terrain_color.darkened(0.22)
	if _is_snow_terrain():
		far = Color(0.34, 0.40, 0.45, 0.42)
		mid = Color(0.50, 0.56, 0.60, 0.36)
	elif _is_city_terrain():
		far = Color(0.10, 0.09, 0.08, 0.44)
		mid = Color(0.20, 0.13, 0.09, 0.42)
	elif _is_forest_terrain():
		far = Color(0.08, 0.14, 0.10, 0.45)
		mid = Color(0.12, 0.22, 0.14, 0.40)
	_draw_mountain_band(rect, horizon - 58.0, 0.34, far)
	_draw_mountain_band(rect, horizon - 28.0, 0.22, mid)
	if _is_city_terrain():
		_draw_roofline(rect, horizon - 78.0)
	elif _is_forest_terrain():
		_draw_bamboo_cluster(rect, horizon - 72.0, rect.position.x + rect.size.x * 0.12, Color(0.04, 0.12, 0.07, 0.42))
		_draw_bamboo_cluster(rect, horizon - 64.0, rect.position.x + rect.size.x * 0.82, Color(0.04, 0.12, 0.07, 0.36))

func _draw_mountain_band(rect: Rect2, base_y: float, roughness: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(Vector2(rect.position.x, rect.position.y + rect.size.y))
	colors.append(color)
	var steps := 9
	for i in range(steps + 1):
		var x := rect.position.x + rect.size.x * float(i) / float(steps)
		var y := base_y - sin(float(i) * 1.41 + pulse * 0.04) * rect.size.y * roughness * 0.18
		points.append(Vector2(x, y))
		colors.append(color)
	points.append(Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y))
	colors.append(color)
	draw_polygon(points, colors)

func _draw_roofline(rect: Rect2, y: float) -> void:
	var roof_color := Color(0.08, 0.055, 0.045, 0.55)
	for i in range(5):
		var x := rect.position.x + float(i) * rect.size.x * 0.24 - 30.0
		var roof := PackedVector2Array([
			Vector2(x, y + 28.0),
			Vector2(x + 66.0, y),
			Vector2(x + 144.0, y + 28.0),
			Vector2(x + 130.0, y + 36.0),
			Vector2(x + 11.0, y + 36.0)
		])
		draw_polygon(roof, PackedColorArray([roof_color, roof_color, roof_color, roof_color, roof_color]))
		draw_line(Vector2(x + 8.0, y + 34.0), Vector2(x + 136.0, y + 34.0), Color(0.0, 0.0, 0.0, 0.34), 4.0)

func _draw_bamboo_cluster(rect: Rect2, y: float, x: float, color: Color) -> void:
	for i in range(7):
		var stalk_x := x + float(i - 3) * 9.0
		var top := y - float((i * 13) % 26)
		draw_line(Vector2(stalk_x, rect.position.y + rect.size.y), Vector2(stalk_x + sin(float(i)) * 8.0, top), color, 2.0)
		draw_line(Vector2(stalk_x + 2.0, top + 28.0), Vector2(stalk_x + 24.0, top + 18.0), color, 1.3)
		draw_line(Vector2(stalk_x - 2.0, top + 42.0), Vector2(stalk_x - 22.0, top + 34.0), color, 1.3)

func _draw_lane(rect: Rect2) -> void:
	var ground_y := _ground_y(rect)
	var lane_color := terrain_color.lightened(0.12)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.22)
	var lane := PackedVector2Array([
		Vector2(rect.position.x + rect.size.x * 0.06, ground_y - 24.0),
		Vector2(rect.position.x + rect.size.x * 0.94, ground_y - 24.0),
		Vector2(rect.position.x + rect.size.x * 1.06, rect.position.y + rect.size.y + 10.0),
		Vector2(rect.position.x - rect.size.x * 0.06, rect.position.y + rect.size.y + 10.0)
	])
	draw_polygon(lane, PackedColorArray([lane_color.darkened(0.18), lane_color.darkened(0.10), lane_color.darkened(0.34), lane_color.darkened(0.30)]))
	for i in range(8):
		var y := ground_y + float(i) * 19.0
		var alpha := 0.18 - float(i) * 0.012
		draw_line(Vector2(rect.position.x + 44.0 + i * 8.0, y), Vector2(rect.position.x + rect.size.x - 64.0 - i * 6.0, y - 6.0), Color(0.0, 0.0, 0.0, alpha), 1.4)
	_draw_ellipse(Vector2(rect.position.x + rect.size.x * 0.50, ground_y + 56.0), Vector2(rect.size.x * 0.44, 30.0), shadow_color)
	_draw_ellipse(Vector2(rect.position.x + rect.size.x * 0.50, ground_y + 35.0), Vector2(rect.size.x * 0.32, 17.0), Color(accent_color.r, accent_color.g, accent_color.b, 0.08))

func _draw_combatants(rect: Rect2) -> void:
	var ground_y := _ground_y(rect)
	var player_foot := Vector2(rect.position.x + rect.size.x * 0.28, ground_y + 40.0)
	var enemy_foot := Vector2(rect.position.x + rect.size.x * 0.72, ground_y + 35.0)
	var impact := clampf(event_timer / 0.48, 0.0, 1.0)
	var player_lunge := 0.0
	var enemy_lunge := 0.0
	var player_hurt := 0.0
	var enemy_hurt := 0.0
	if event_timer > 0.0 and event_target == "enemy":
		player_lunge = sin(impact * PI) * 18.0
		enemy_hurt = sin(impact * PI * 2.0) * 5.0
	elif event_timer > 0.0 and event_target == "player":
		enemy_lunge = sin(impact * PI) * 18.0
		player_hurt = sin(impact * PI * 2.0) * -5.0
	_draw_actor_shadow(player_foot + Vector2(player_lunge, 0.0), 1.05)
	_draw_actor_shadow(enemy_foot + Vector2(-enemy_lunge, 0.0), 1.12)
	_draw_player_actor(player_foot + Vector2(player_lunge + player_hurt, 0.0))
	_draw_enemy_actor(enemy_foot + Vector2(-enemy_lunge + enemy_hurt, 0.0))
	_draw_status_bars(player_foot, enemy_foot)
	_draw_action_effects(rect, player_foot, enemy_foot)

func _draw_player_actor(foot: Vector2) -> void:
	if player_texture != null:
		_draw_actor_texture(player_texture, foot, 128.0, Color(1.0, 1.0, 1.0, 1.0))
	else:
		_draw_actor_fallback(foot, accent_color, "你")

func _draw_enemy_actor(foot: Vector2) -> void:
	if enemy_texture != null:
		var tint := Color(1.0, 0.96, 0.91, 1.0)
		if event_timer > 0.0 and event_target == "enemy" and event_kind == "damage":
			tint = Color(1.0, 0.70, 0.58, 1.0)
		_draw_actor_texture(enemy_texture, foot, 136.0, tint)
	else:
		_draw_actor_fallback(foot, Color(0.62, 0.18, 0.14), str(enemy.get("name", "敌")))

func _draw_actor_texture(texture: Texture2D, foot: Vector2, target_height: float, tint: Color) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var factor := target_height / texture_size.y
	var draw_size := texture_size * factor
	var top_left := foot - Vector2(draw_size.x * 0.5, draw_size.y)
	var outline := Rect2(top_left - Vector2(3.0, 1.5), draw_size + Vector2(6.0, 5.0))
	draw_texture_rect(texture, outline, false, Color(0.0, 0.0, 0.0, 0.46))
	draw_texture_rect(texture, Rect2(top_left, draw_size), false, tint)

func _draw_actor_fallback(foot: Vector2, color: Color, label: String) -> void:
	_draw_ellipse(foot - Vector2(0, 31), Vector2(22, 34), color.darkened(0.18))
	draw_circle(foot - Vector2(0, 83), 17.0, color.lightened(0.28))
	draw_line(foot - Vector2(21, 52), foot - Vector2(47, 28), color.darkened(0.22), 5.0)
	draw_line(foot + Vector2(21, -52), foot + Vector2(47, -28), color.darkened(0.22), 5.0)
	draw_string(ThemeDB.fallback_font, foot - Vector2(22, 116), label.left(2), HORIZONTAL_ALIGNMENT_CENTER, 44, 15, Color(0.95, 0.88, 0.70, 0.9))

func _draw_actor_shadow(foot: Vector2, scale: float) -> void:
	_draw_ellipse(foot + Vector2(4.0, 2.0), Vector2(46.0 * scale, 12.0 * scale), Color(0.0, 0.0, 0.0, 0.25))
	_draw_ellipse(foot + Vector2(1.0, 0.0), Vector2(30.0 * scale, 7.0 * scale), Color(0.0, 0.0, 0.0, 0.22))

func _draw_status_bars(player_foot: Vector2, enemy_foot: Vector2) -> void:
	_draw_bar(player_foot + Vector2(-54.0, -150.0), 108.0, int(GameState.player.get("hp", 0)), int(GameState.player.get("max_hp", 1)), Color(0.72, 0.18, 0.12), "你")
	var current_enemy: Dictionary = snapshot.get("enemy", enemy)
	_draw_bar(enemy_foot + Vector2(-56.0, -158.0), 112.0, int(current_enemy.get("hp", enemy.get("hp", 0))), int(current_enemy.get("max_hp", enemy.get("max_hp", 1))), Color(0.75, 0.22, 0.16), str(enemy.get("name", "敌人")))

func _draw_bar(pos: Vector2, width: float, value: int, max_value: int, color: Color, label: String) -> void:
	var safe_max := maxi(1, max_value)
	var ratio := clampf(float(maxi(0, value)) / float(safe_max), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(width, 8.0)), Color(0.04, 0.025, 0.02, 0.72), true)
	draw_rect(Rect2(pos + Vector2(1.0, 1.0), Vector2((width - 2.0) * ratio, 6.0)), color, true)
	draw_rect(Rect2(pos, Vector2(width, 8.0)), Color(0.92, 0.72, 0.38, 0.42), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -5), label.left(6), HORIZONTAL_ALIGNMENT_CENTER, width, 13, Color(0.93, 0.86, 0.72, 0.92))

func _draw_action_effects(rect: Rect2, player_foot: Vector2, enemy_foot: Vector2) -> void:
	if event_timer <= 0.0:
		return
	var impact := clampf(event_timer / 0.48, 0.0, 1.0)
	var alpha := sin(impact * PI)
	var start := player_foot - Vector2(-26.0, 82.0)
	var finish := enemy_foot - Vector2(35.0, 82.0)
	if event_target == "player":
		start = enemy_foot - Vector2(28.0, 86.0)
		finish = player_foot - Vector2(-32.0, 84.0)
	var color := _event_color(event_kind, event_target)
	if event_kind == "miss":
		_draw_miss_wisp(finish, alpha)
		return
	if event_kind == "heal" or event_kind == "mp" or event_kind == "guard":
		_draw_focus_ring(start, color, alpha)
		return
	var points := PackedVector2Array([
		start.lerp(finish, 0.22),
		start.lerp(finish, 0.50) + Vector2(16.0, -30.0),
		start.lerp(finish, 0.82),
		start.lerp(finish, 0.52) + Vector2(-8.0, 22.0)
	])
	draw_polyline(points, Color(color.r, color.g, color.b, 0.80 * alpha), 5.5, true)
	draw_polyline(points, Color(1.0, 0.92, 0.70, 0.50 * alpha), 2.0, true)
	for i in range(5):
		var spark_origin := finish + Vector2(cos(float(i) * 1.2) * 12.0, sin(float(i) * 1.2) * 10.0)
		draw_line(spark_origin, spark_origin + Vector2(18.0 - i * 4.0, -10.0 + i * 4.0), Color(color.r, color.g, color.b, 0.56 * alpha), 1.7)
	if event_kind == "phase" or event_kind == "stun":
		_draw_focus_ring(finish, color, alpha)
	var fog_rect := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.72), Vector2(rect.size.x * 0.64, 22.0))
	_draw_soft_band(fog_rect, Color(color.r, color.g, color.b, 0.10 * alpha))

func _draw_miss_wisp(center: Vector2, alpha: float) -> void:
	for i in range(4):
		var offset := Vector2(cos(float(i) * 1.5 + pulse) * 18.0, sin(float(i) * 1.8 + pulse) * 8.0)
		draw_arc(center + offset, 13.0 + i * 3.0, 0.2, PI * 1.4, 18, Color(0.82, 0.84, 0.86, 0.42 * alpha), 1.6)

func _draw_focus_ring(center: Vector2, color: Color, alpha: float) -> void:
	for i in range(3):
		draw_arc(center, 24.0 + i * 10.0, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.30 * alpha / float(i + 1)), 2.2)

func _draw_foreground(rect: Rect2) -> void:
	var bottom_fog := Color(0.90, 0.84, 0.70, 0.13 + sin(pulse * 0.7) * 0.025)
	_draw_soft_band(Rect2(rect.position + Vector2(0.0, rect.size.y * 0.78), Vector2(rect.size.x, 40.0)), bottom_fog)
	if _is_city_terrain():
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 16.0)), Color(0.05, 0.035, 0.025, 0.52), true)
		for i in range(7):
			var x := rect.position.x + float(i) * rect.size.x / 6.0 - 20.0
			draw_line(Vector2(x, rect.position.y + 3.0), Vector2(x + 42.0, rect.position.y + 26.0), Color(0.02, 0.016, 0.012, 0.45), 3.0)
	elif _is_snow_terrain():
		for i in range(20):
			var x := rect.position.x + fmod(float(i) * 47.0 + pulse * (9.0 + i % 4), rect.size.x)
			var y := rect.position.y + 18.0 + fmod(float(i * 31) + pulse * 13.0, rect.size.y * 0.74)
			draw_circle(Vector2(x, y), 1.2 + float(i % 3) * 0.5, Color(0.92, 0.96, 1.0, 0.30))
	elif terrain_key.contains("desert"):
		_draw_soft_band(Rect2(rect.position + Vector2(0, rect.size.y * 0.18), Vector2(rect.size.x, 28.0)), Color(0.92, 0.74, 0.45, 0.14))
	elif _is_forest_terrain():
		_draw_bamboo_cluster(rect, rect.position.y + rect.size.y * 0.40, rect.position.x + 28.0, Color(0.02, 0.09, 0.05, 0.46))
		_draw_bamboo_cluster(rect, rect.position.y + rect.size.y * 0.42, rect.position.x + rect.size.x - 34.0, Color(0.02, 0.09, 0.05, 0.42))

func _draw_frame(rect: Rect2) -> void:
	draw_rect(rect, Color(0.92, 0.65, 0.32, 0.46), false, 2.0)
	draw_rect(rect.grow(-3.0), Color(0.0, 0.0, 0.0, 0.28), false, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.08)), Color(0.0, 0.0, 0.0, 0.22), true)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.86), Vector2(rect.size.x, rect.size.y * 0.14)), Color(0.0, 0.0, 0.0, 0.20), true)

func _draw_soft_band(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	])
	var clear := Color(color.r, color.g, color.b, 0.0)
	draw_polygon(points, PackedColorArray([clear, clear, color, color]))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)

func _ground_y(rect: Rect2) -> float:
	return rect.position.y + rect.size.y * 0.64

func _event_color(kind: String, target: String) -> Color:
	match kind:
		"miss":
			return Color(0.74, 0.78, 0.82)
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
			return Color(1.0, 0.35, 0.22) if target == "player" else Color(1.0, 0.78, 0.34)

func _terrain_color(terrain: String, region_type: String) -> Color:
	if terrain.contains("snow"):
		return Color(0.46, 0.55, 0.60)
	if terrain.contains("desert"):
		return Color(0.58, 0.42, 0.24)
	if terrain.contains("forest") or terrain.contains("bamboo"):
		return Color(0.20, 0.31, 0.19)
	if terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("canal"):
		return Color(0.22, 0.34, 0.40)
	if region_type == "city" or region_type == "town" or terrain.contains("city") or terrain.contains("town"):
		return Color(0.40, 0.31, 0.22)
	if region_type == "sect" or terrain.contains("sect") or terrain.contains("temple"):
		return Color(0.36, 0.34, 0.28)
	return Color(0.34, 0.36, 0.24)

func _is_snow_terrain() -> bool:
	return terrain_key.contains("snow")

func _is_forest_terrain() -> bool:
	return terrain_key.contains("forest") or terrain_key.contains("bamboo") or terrain_key.contains("marsh")

func _is_city_terrain() -> bool:
	return terrain_key.contains("city") or terrain_key.contains("town") or terrain_key.contains("village") or terrain_key.contains("sect") or terrain_key.contains("temple")
