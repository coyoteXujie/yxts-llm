extends Control
class_name CombatStage

const PLAYER_STAGE_HEIGHT := 146.0
const ENEMY_STAGE_HEIGHT := 154.0
const ACTOR_AFTERIMAGE_ALPHA := 0.22
const CONTACT_GLOW_ALPHA := 0.18
const DAMAGE_NUMBER_RISE := 28.0

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
var event_source := ""
var event_amount := 0
var effect_style := "impact"
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
	event_source = ""
	event_amount = 0
	effect_style = "impact"
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
	event_source = ""
	event_amount = 0
	effect_style = "impact"
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
	event_source = str(latest.get("source", ""))
	event_amount = int(latest.get("amount", 0))
	effect_style = _effect_style(event_kind, event_source)
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
	var action_alpha := sin(impact * PI) if event_timer > 0.0 else 0.0
	var player_action := action_alpha if event_target == "enemy" else 0.0
	var enemy_action := action_alpha if event_target == "player" else 0.0
	var player_draw_foot := player_foot + Vector2(player_lunge + player_hurt, 0.0)
	var enemy_draw_foot := enemy_foot + Vector2(-enemy_lunge + enemy_hurt, 0.0)
	_draw_actor_shadow(player_draw_foot, 1.08 + player_action * 0.08)
	_draw_actor_shadow(enemy_draw_foot, 1.15 + enemy_action * 0.08)
	_draw_actor_contact_light(player_draw_foot, accent_color, 0.90 + player_action * 0.45, 1.0)
	_draw_actor_contact_light(enemy_draw_foot, Color(0.78, 0.18, 0.12), 0.82 + enemy_action * 0.45, 1.08)
	_draw_actor_afterimage(player_texture, player_draw_foot - Vector2(18.0 + player_lunge * 0.55, 0.0), PLAYER_STAGE_HEIGHT, accent_color.lightened(0.22), player_action)
	_draw_actor_afterimage(enemy_texture, enemy_draw_foot + Vector2(18.0 + enemy_lunge * 0.55, 0.0), ENEMY_STAGE_HEIGHT, Color(0.95, 0.32, 0.18), enemy_action)
	_draw_player_actor(player_draw_foot, player_action)
	_draw_enemy_actor(enemy_draw_foot, enemy_action)
	_draw_status_bars(player_foot, enemy_foot)
	_draw_action_effects(rect, player_foot, enemy_foot)

func _draw_player_actor(foot: Vector2, action_intensity: float = 0.0) -> void:
	if player_texture != null:
		_draw_actor_texture(player_texture, foot, PLAYER_STAGE_HEIGHT + action_intensity * 8.0, Color(1.0, 1.0, 1.0, 1.0), action_intensity)
	else:
		_draw_actor_fallback(foot, accent_color, "你")

func _draw_enemy_actor(foot: Vector2, action_intensity: float = 0.0) -> void:
	if enemy_texture != null:
		var tint := Color(1.0, 0.96, 0.91, 1.0)
		if event_timer > 0.0 and event_target == "enemy" and event_kind == "damage":
			tint = Color(1.0, 0.70, 0.58, 1.0)
		_draw_actor_texture(enemy_texture, foot, ENEMY_STAGE_HEIGHT + action_intensity * 8.0, tint, action_intensity)
	else:
		_draw_actor_fallback(foot, Color(0.62, 0.18, 0.14), str(enemy.get("name", "敌")))

func _draw_actor_texture(texture: Texture2D, foot: Vector2, target_height: float, tint: Color, action_intensity: float = 0.0) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var factor := target_height / texture_size.y
	var draw_size := texture_size * factor
	var top_left := foot - Vector2(draw_size.x * 0.5, draw_size.y + action_intensity * 5.0)
	var outline := Rect2(top_left - Vector2(3.0, 1.5), draw_size + Vector2(6.0, 5.0))
	draw_texture_rect(texture, outline, false, Color(0.0, 0.0, 0.0, 0.46 + action_intensity * 0.08))
	if action_intensity > 0.01:
		draw_texture_rect(texture, Rect2(top_left - Vector2(1.5, 1.5), draw_size), false, Color(tint.r, tint.g, tint.b, 0.12 * action_intensity))
	draw_texture_rect(texture, Rect2(top_left, draw_size), false, tint)
	var rim_alpha := 0.13 + action_intensity * 0.10
	draw_line(top_left + Vector2(draw_size.x * 0.20, draw_size.y * 0.12), top_left + Vector2(draw_size.x * 0.78, draw_size.y * 0.70), Color(1.0, 0.92, 0.62, rim_alpha), 1.8)

func _draw_actor_afterimage(texture: Texture2D, foot: Vector2, target_height: float, tint: Color, alpha: float) -> void:
	if texture == null or alpha <= 0.01:
		return
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var factor := target_height / texture_size.y
	var draw_size := texture_size * factor
	var top_left := foot - Vector2(draw_size.x * 0.5, draw_size.y)
	draw_texture_rect(texture, Rect2(top_left, draw_size), false, Color(tint.r, tint.g, tint.b, ACTOR_AFTERIMAGE_ALPHA * alpha))

func _draw_actor_fallback(foot: Vector2, color: Color, label: String) -> void:
	_draw_ellipse(foot - Vector2(0, 31), Vector2(22, 34), color.darkened(0.18))
	draw_circle(foot - Vector2(0, 83), 17.0, color.lightened(0.28))
	draw_line(foot - Vector2(21, 52), foot - Vector2(47, 28), color.darkened(0.22), 5.0)
	draw_line(foot + Vector2(21, -52), foot + Vector2(47, -28), color.darkened(0.22), 5.0)
	draw_string(ThemeDB.fallback_font, foot - Vector2(22, 116), label.left(2), HORIZONTAL_ALIGNMENT_CENTER, 44, 15, Color(0.95, 0.88, 0.70, 0.9))

func _draw_actor_shadow(foot: Vector2, scale: float) -> void:
	_draw_ellipse(foot + Vector2(4.0, 2.0), Vector2(46.0 * scale, 12.0 * scale), Color(0.0, 0.0, 0.0, 0.25))
	_draw_ellipse(foot + Vector2(1.0, 0.0), Vector2(30.0 * scale, 7.0 * scale), Color(0.0, 0.0, 0.0, 0.22))

func _draw_actor_contact_light(foot: Vector2, color: Color, intensity: float, scale: float) -> void:
	_draw_ellipse(foot + Vector2(0.0, 1.0), Vector2(56.0 * scale, 13.0 * scale), Color(color.r, color.g, color.b, CONTACT_GLOW_ALPHA * intensity))
	_draw_ellipse(foot + Vector2(0.0, 2.0), Vector2(30.0 * scale, 5.8 * scale), Color(1.0, 0.84, 0.46, CONTACT_GLOW_ALPHA * intensity * 0.40))

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
		_draw_focus_ring(start, color, alpha, effect_style)
		_draw_damage_number(start, event_amount, event_kind, color, alpha)
		return
	_draw_attack_ground_streak(start, finish, color, alpha)
	match effect_style:
		"blade":
			_draw_blade_slash(start, finish, color, alpha)
		"sword":
			_draw_sword_qi(start, finish, color, alpha)
		"palm":
			_draw_palm_wave(start, finish, color, alpha)
		"fire":
			_draw_fire_burst(start, finish, alpha)
		"poison":
			_draw_poison_mist(start, finish, alpha)
		"ice":
			_draw_ice_shards(start, finish, alpha)
		"shadow":
			_draw_shadow_strike(start, finish, alpha)
		_:
			_draw_impact_arc(start, finish, color, alpha)
	_draw_hit_sparks(finish, color, alpha)
	_draw_damage_number(finish, event_amount, event_kind, color, alpha)
	if event_kind == "phase" or event_kind == "stun":
		_draw_focus_ring(finish, color, alpha, effect_style)
	var fog_rect := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.72), Vector2(rect.size.x * 0.64, 22.0))
	_draw_soft_band(fog_rect, Color(color.r, color.g, color.b, 0.10 * alpha))

func _draw_attack_ground_streak(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var ground_start := start + Vector2(0.0, 88.0)
	var ground_finish := finish + Vector2(0.0, 90.0)
	var mid := ground_start.lerp(ground_finish, 0.55)
	_draw_ellipse(mid, Vector2(86.0, 13.0), Color(color.r, color.g, color.b, 0.08 * alpha))
	draw_line(ground_start, ground_finish, Color(1.0, 0.86, 0.45, 0.18 * alpha), 4.0)

func _draw_damage_number(center: Vector2, amount: int, kind: String, color: Color, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var text := "-%d" % maxi(0, amount)
	if kind == "heal" or kind == "mp":
		text = "+%d" % maxi(0, amount)
	elif kind == "guard":
		text = "GUARD"
	elif kind == "stun":
		text = "STUN"
	var life := 1.0 - clampf(event_timer / 0.48, 0.0, 1.0)
	var rise := life * DAMAGE_NUMBER_RISE
	var width := maxf(52.0, float(text.length()) * 12.0)
	var pos := center + Vector2(-width * 0.5, -46.0 - rise)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, width, 22, Color(0.02, 0.015, 0.01, 0.74 * alpha))
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, 22, Color(color.r, color.g, color.b, 0.95 * alpha))

func _draw_miss_wisp(center: Vector2, alpha: float) -> void:
	for i in range(4):
		var offset := Vector2(cos(float(i) * 1.5 + pulse) * 18.0, sin(float(i) * 1.8 + pulse) * 8.0)
		draw_arc(center + offset, 13.0 + i * 3.0, 0.2, PI * 1.4, 18, Color(0.82, 0.84, 0.86, 0.42 * alpha), 1.6)

func _draw_focus_ring(center: Vector2, color: Color, alpha: float, style: String = "focus") -> void:
	for i in range(3):
		draw_arc(center, 24.0 + i * 10.0, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.30 * alpha / float(i + 1)), 2.2)
	if style == "guard":
		for i in range(4):
			var angle := float(i) * PI * 0.5 + pulse * 0.6
			var a := center + Vector2(cos(angle), sin(angle)) * 25.0
			var b := center + Vector2(cos(angle + 0.56), sin(angle + 0.56)) * 34.0
			draw_line(a, b, Color(0.96, 0.82, 0.42, 0.38 * alpha), 2.0)

func _draw_impact_arc(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var points := PackedVector2Array([
		start.lerp(finish, 0.22),
		start.lerp(finish, 0.50) + Vector2(16.0, -30.0),
		start.lerp(finish, 0.82),
		start.lerp(finish, 0.52) + Vector2(-8.0, 22.0)
	])
	draw_polyline(points, Color(color.r, color.g, color.b, 0.80 * alpha), 5.5, true)
	draw_polyline(points, Color(1.0, 0.92, 0.70, 0.50 * alpha), 2.0, true)

func _draw_blade_slash(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var center := start.lerp(finish, 0.62)
	for i in range(3):
		var spread := float(i - 1) * 13.0
		var points := PackedVector2Array([
			start.lerp(finish, 0.16 + i * 0.05) + normal * (30.0 + spread),
			center + normal * (4.0 + spread * 0.35) + Vector2(0.0, -30.0 + i * 5.0),
			finish + normal * (-27.0 + spread * 0.25)
		])
		draw_polyline(points, Color(color.r, color.g, color.b, 0.66 * alpha / float(i + 1)), 7.0 - i * 1.5, true)
	draw_line(start + normal * 20.0, finish - normal * 17.0, Color(1.0, 0.96, 0.78, 0.58 * alpha), 2.2)

func _draw_sword_qi(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var beam_start := start.lerp(finish, 0.18)
	var beam_end := finish + dir * 22.0
	for i in range(3):
		var offset := normal * float(i - 1) * 6.0
		draw_line(beam_start + offset, beam_end + offset * 0.35, Color(0.72, 0.88, 1.0, 0.22 * alpha), 8.0 - i * 1.8)
	draw_line(beam_start, beam_end, Color(0.98, 0.98, 0.86, 0.78 * alpha), 2.0)
	for i in range(5):
		var t := float(i) / 4.0
		var p := beam_start.lerp(beam_end, t)
		draw_line(p - normal * (10.0 + t * 7.0), p + normal * (8.0 + t * 6.0), Color(color.r, color.g, color.b, 0.26 * alpha), 1.3)

func _draw_palm_wave(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	for i in range(4):
		var center := start.lerp(finish, 0.30 + float(i) * 0.17)
		var radius := 18.0 + float(i) * 8.0
		draw_arc(center, radius, -0.7, 0.7, 28, Color(color.r, color.g, color.b, 0.30 * alpha), 2.1)
		draw_line(center - normal * radius * 0.52, center + normal * radius * 0.52, Color(0.96, 0.92, 0.72, 0.13 * alpha), 1.2)
	draw_circle(finish, 22.0, Color(color.r, color.g, color.b, 0.11 * alpha))
	draw_line(start + dir * 24.0, finish - dir * 18.0, Color(0.95, 0.90, 0.62, 0.28 * alpha), 3.0)

func _draw_fire_burst(start: Vector2, finish: Vector2, alpha: float) -> void:
	var fire := Color(1.0, 0.33, 0.10, 1.0)
	var gold := Color(1.0, 0.76, 0.22, 1.0)
	_draw_impact_arc(start, finish, fire, alpha)
	for i in range(9):
		var angle := float(i) * TAU / 9.0 + pulse * 0.45
		var length := 16.0 + float((i * 7) % 13)
		var origin := finish + Vector2(cos(angle), sin(angle) * 0.65) * 10.0
		draw_line(origin, origin + Vector2(cos(angle), sin(angle)) * length, Color(gold.r, gold.g, gold.b, 0.50 * alpha), 2.0)
		draw_circle(origin + Vector2(cos(angle), sin(angle)) * length, 2.0, Color(fire.r, fire.g, fire.b, 0.34 * alpha))

func _draw_poison_mist(start: Vector2, finish: Vector2, alpha: float) -> void:
	var poison := Color(0.42, 0.86, 0.26, 1.0)
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	for i in range(8):
		var t := float(i) / 7.0
		var center := start.lerp(finish, t) + normal * sin(t * PI * 2.0 + pulse) * 16.0
		var radius := Vector2(15.0 + float(i % 3) * 5.0, 6.0 + float(i % 2) * 4.0)
		_draw_ellipse(center, radius, Color(poison.r, poison.g, poison.b, 0.13 * alpha))
	draw_line(start, finish, Color(0.76, 1.0, 0.52, 0.24 * alpha), 2.0)

func _draw_ice_shards(start: Vector2, finish: Vector2, alpha: float) -> void:
	var ice := Color(0.62, 0.88, 1.0, 1.0)
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	draw_line(start, finish, Color(0.90, 0.97, 1.0, 0.62 * alpha), 2.4)
	for i in range(7):
		var t := 0.20 + float(i) * 0.10
		var center := start.lerp(finish, t) + normal * float((i % 3) - 1) * 10.0
		var tip := center + dir * (18.0 + float(i % 2) * 7.0)
		var shard := PackedVector2Array([center - normal * 4.0, tip, center + normal * 5.0, center - dir * 8.0])
		draw_polygon(shard, PackedColorArray([
			Color(ice.r, ice.g, ice.b, 0.10 * alpha),
			Color(0.96, 1.0, 1.0, 0.54 * alpha),
			Color(ice.r, ice.g, ice.b, 0.18 * alpha),
			Color(0.35, 0.62, 0.78, 0.08 * alpha)
		]))
	draw_arc(finish, 25.0, 0.0, TAU, 36, Color(0.74, 0.92, 1.0, 0.26 * alpha), 1.8)

func _draw_shadow_strike(start: Vector2, finish: Vector2, alpha: float) -> void:
	var shadow := Color(0.18, 0.08, 0.26, 1.0)
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	for i in range(4):
		var offset := normal * float(i - 1) * 8.0 + Vector2(0.0, float(i) * 3.0)
		draw_line(start + offset, finish + offset - dir * float(i) * 6.0, Color(shadow.r, shadow.g, shadow.b, 0.46 * alpha), 5.2 - i * 0.7)
	draw_line(start, finish, Color(0.86, 0.70, 1.0, 0.30 * alpha), 1.6)

func _draw_hit_sparks(finish: Vector2, color: Color, alpha: float) -> void:
	var spark_count := 7 if event_amount >= 30 else 5
	for i in range(spark_count):
		var spark_origin := finish + Vector2(cos(float(i) * 1.2) * 12.0, sin(float(i) * 1.2) * 10.0)
		var length := 16.0 + float((i * 5) % 9)
		draw_line(spark_origin, spark_origin + Vector2(length - i * 3.0, -10.0 + i * 4.0), Color(color.r, color.g, color.b, 0.56 * alpha), 1.7)

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

func _effect_style(kind: String, source: String) -> String:
	if kind == "heal" or kind == "mp":
		return "focus"
	if kind == "guard":
		return "guard"
	if kind == "miss":
		return "miss"
	if kind == "phase":
		return "shadow"
	if kind == "stun":
		return "palm"
	var text := source.to_lower()
	if source.is_empty() or source.contains("普通"):
		return "impact"
	if source.contains("雪") or source.contains("冰") or source.contains("霜"):
		return "ice"
	if source.contains("火") or source.contains("炎") or source.contains("阳") or source.contains("莲"):
		return "fire"
	if source.contains("毒") or source.contains("忍") or source.contains("雾"):
		return "poison"
	if source.contains("影") or source.contains("暗"):
		return "shadow"
	if source.contains("剑"):
		return "sword"
	if source.contains("刀") or source.contains("劈") or source.contains("斩"):
		return "blade"
	if source.contains("掌") or source.contains("拳") or source.contains("击") or source.contains("爪"):
		return "palm"
	if text.contains("blade"):
		return "blade"
	if text.contains("sword"):
		return "sword"
	if text.contains("palm") or text.contains("fist"):
		return "palm"
	return "impact"

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
