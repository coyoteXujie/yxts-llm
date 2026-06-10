extends Control
class_name CombatStage

const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const STAGE_BACKDROP_RENDERER := preload("res://scripts/shared/stage_backdrop_renderer.gd")

const PLAYER_STAGE_HEIGHT := 146.0
const ENEMY_STAGE_HEIGHT := 154.0
const COMBAT_STAGE_REFERENCE_HEIGHT := 334.0
const COMBAT_STAGE_ACTOR_MAX_SCALE := 1.68
const COMBAT_STAGE_MOTION_MAX_SCALE := 1.45
const COMBAT_STAGE_FOUNDATION_ENABLED := true
const COMBAT_STAGE_BACKGROUND_TEXTURE_ALPHA := 0.58
const COMBAT_STAGE_ASSET_LAYERS_ENABLED := true
const COMBAT_STAGE_BACKDROP_ALPHA := 0.96
const COMBAT_STAGE_MIDGROUND_ALPHA := 0.94
const COMBAT_STAGE_FLOOR_ALPHA := 0.92
const COMBAT_STAGE_FOREGROUND_ALPHA := 0.90
const COMBAT_ACTOR_FRAME_ANIMATION_ENABLED := true
const COMBAT_ACTOR_REQUIRED_ACTIONS := ["idle", "attack", "hurt", "down"]
const ACTOR_AFTERIMAGE_ALPHA := 0.22
const CONTACT_GLOW_ALPHA := 0.18
const DAMAGE_NUMBER_RISE := 28.0
const COMBAT_EVENT_DURATION := 0.48
const HIT_SHAKE_PIXELS := 5.5
const HEAVY_HIT_SHAKE_PIXELS := 8.0
const HIT_FREEZE_WINDOW := 0.17
const IMPACT_SPEED_LINE_COUNT := 9
const GROUND_CRACK_COUNT := 5
const ACTOR_LUNGE_PIXELS := 32.0
const ACTOR_WINDUP_PIXELS := 11.0
const ACTOR_RECOVER_PIXELS := 8.0
const ACTOR_HURT_RECOIL_PIXELS := 17.0
const ACTOR_ATTACK_STRETCH := 0.08
const ACTOR_HURT_SQUASH := 0.12
const HURT_FLASH_ALPHA := 0.42
const LOW_HP_STANCE_THRESHOLD := 0.30
const COMBAT_POSE_LINE_ALPHA := 0.28
const COMBAT_WEAPON_GLOW_ALPHA := 0.34
const ATTACK_TELEGRAPH_ALPHA := 0.24
const ATTACK_TRAIL_LAYER_COUNT := 5
const HEAVY_DAMAGE_THRESHOLD := 30
const COMBO_BURST_RING_COUNT := 4
const COMBAT_STAGE_SPECTATOR_COUNT := 10
const COMBAT_STAGE_DEPTH_PROP_COUNT := 8
const COMBAT_STAGE_FOREGROUND_OCCLUDER_COUNT := 6
const COMBAT_STAGE_FOOTWORK_TRAIL_COUNT := 5
const COMBAT_STAGE_BACK_RAIL_ALPHA := 0.26
const COMBAT_STAGE_FOREGROUND_PRESSURE_ALPHA := 0.24
const COMBAT_EVENT_AIR_CUT_COUNT := 6
const COMBAT_EVENT_AIR_CUT_ALPHA := 0.24
const COMBAT_EVENT_FOREGROUND_RIPPLE_COUNT := 5
const COMBAT_EVENT_FOREGROUND_RIPPLE_ALPHA := 0.22

var enemy: Dictionary = {}
var snapshot: Dictionary = {}
var player_texture: Texture2D
var enemy_texture: Texture2D
var player_frame_key := ""
var enemy_frame_key := ""
var player_action_frames: Dictionary = {}
var enemy_action_frames: Dictionary = {}
var player_frame_textures: Dictionary = {}
var enemy_frame_textures: Dictionary = {}
var background_texture: Texture2D
var combat_stage_assets: Dictionary = {}
var stage_backdrop_texture: Texture2D
var stage_midground_texture: Texture2D
var stage_floor_texture: Texture2D
var stage_foreground_texture: Texture2D
var current_region: Dictionary = {}
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
var event_shake_strength := 0.0
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
	event_shake_strength = 0.0
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
	event_shake_strength = 0.0
	queue_redraw()

func _refresh_assets() -> void:
	player_frame_key = "player_%s" % _player_sprite_key()
	enemy_frame_key = "npc_%s" % str(enemy.get("name", ""))
	player_texture = _load_player_texture()
	enemy_texture = _load_enemy_texture()
	current_region = GameData.get_region(GameState.current_region_id).duplicate(true)
	if current_region.is_empty():
		current_region = {"id": "", "type": "wild", "terrain": "plain"}
	terrain_key = str(current_region.get("terrain", "plain"))
	terrain_color = _terrain_color(terrain_key, str(current_region.get("type", "wild")))
	accent_color = GameData.get_faction_color(str(GameState.player.get("faction", "none"))).lightened(0.08)
	background_texture = _load_region_background()
	_refresh_combat_stage_assets()
	_refresh_combat_actor_frames()

func _player_sprite_key() -> String:
	var gender := str(GameState.player.get("gender", "male"))
	if gender != "female":
		gender = "male"
	var faction := str(GameState.player.get("faction", "none"))
	return "%s_%s" % [gender, faction]

func _load_player_texture() -> Texture2D:
	var key := _player_sprite_key()
	var path := str(PLAYER_SCRIPT.PLAYER_SPRITE_OVERRIDES.get(key, "res://assets/characters/player/player_%s.png" % key))
	var texture := GameData.load_texture(path, true)
	if texture == null and key != "male_none":
		texture = GameData.load_texture(str(PLAYER_SCRIPT.PLAYER_SPRITE_OVERRIDES.get("male_none", "res://assets/characters/player/player_male_none.png")), true)
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

func _refresh_combat_stage_assets() -> void:
	combat_stage_assets = GameData.get_combat_stage_assets(GameState.current_region_id)
	stage_backdrop_texture = _load_combat_stage_texture("backdrop")
	stage_midground_texture = _load_combat_stage_texture("midground")
	stage_floor_texture = _load_combat_stage_texture("floor")
	stage_foreground_texture = _load_combat_stage_texture("foreground")

func _load_combat_stage_texture(layer_name: String) -> Texture2D:
	var path := str(combat_stage_assets.get(layer_name, ""))
	if path.is_empty():
		return null
	return GameData.load_texture(path, true)

func _refresh_combat_actor_frames() -> void:
	player_action_frames = GameData.get_combat_actor_frames(player_frame_key)
	if player_action_frames.is_empty() and player_frame_key != "player_male_none":
		player_action_frames = GameData.get_combat_actor_frames("player_male_none")
	enemy_action_frames = GameData.get_combat_actor_frames(enemy_frame_key)
	player_frame_textures = _load_actor_frame_textures(player_action_frames)
	enemy_frame_textures = _load_actor_frame_textures(enemy_action_frames)

func _load_actor_frame_textures(action_frames: Dictionary) -> Dictionary:
	var textures := {}
	for action_name in action_frames.keys():
		var frame_paths: Array = action_frames.get(action_name, [])
		var loaded := []
		for frame_path in frame_paths:
			var texture := GameData.load_texture(str(frame_path), true)
			if texture != null:
				loaded.append(texture)
		textures[str(action_name)] = loaded
	return textures

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
	event_shake_strength = _event_shake_strength(event_kind, effect_style, event_amount)
	event_timer = COMBAT_EVENT_DURATION

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 100.0 or rect.size.y < 80.0:
		return
	var shake := _stage_shake_offset()
	draw_set_transform(shake, 0.0, Vector2.ONE)
	_draw_backplate(rect)
	_draw_background(rect)
	if stage_backdrop_texture == null:
		_draw_parallax_silhouette(rect)
	_draw_stage_back_life(rect)
	_draw_painted_midground(rect)
	_draw_lane(rect)
	_draw_painted_floor(rect)
	_draw_stage_mid_props(rect)
	_draw_combatants(rect)
	_draw_foreground(rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_impact_overlay(rect)
	_draw_frame(rect)

func _draw_backplate(rect: Rect2) -> void:
	draw_rect(rect, Color(0.04, 0.035, 0.028, 0.92), true)

func _draw_background(rect: Rect2) -> void:
	if COMBAT_STAGE_FOUNDATION_ENABLED:
		var palette := _stage_palette()
		var stage_tile_size := maxi(32, int(rect.size.y / 7.0))
		STAGE_BACKDROP_RENDERER.draw_stage_foundation(self, rect.size, stage_tile_size, current_region, pulse, palette)
	if stage_backdrop_texture != null and COMBAT_STAGE_ASSET_LAYERS_ENABLED:
		_draw_cover_texture(stage_backdrop_texture, rect, Color(1.0, 1.0, 1.0, COMBAT_STAGE_BACKDROP_ALPHA))
		if background_texture != null:
			_draw_cover_texture(background_texture, rect, Color(1.0, 1.0, 1.0, COMBAT_STAGE_BACKGROUND_TEXTURE_ALPHA * 0.16))
	elif background_texture != null:
		_draw_cover_texture(background_texture, rect, Color(1.0, 1.0, 1.0, COMBAT_STAGE_BACKGROUND_TEXTURE_ALPHA))
	elif not COMBAT_STAGE_FOUNDATION_ENABLED:
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

func _draw_painted_midground(rect: Rect2) -> void:
	_draw_combat_stage_texture_layer(stage_midground_texture, rect, COMBAT_STAGE_MIDGROUND_ALPHA)

func _draw_painted_floor(rect: Rect2) -> void:
	_draw_combat_stage_texture_layer(stage_floor_texture, rect, COMBAT_STAGE_FLOOR_ALPHA)

func _draw_combat_stage_texture_layer(texture: Texture2D, rect: Rect2, alpha: float) -> void:
	if not COMBAT_STAGE_ASSET_LAYERS_ENABLED or texture == null:
		return
	_draw_cover_texture(texture, rect, Color(1.0, 1.0, 1.0, alpha))

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

func _draw_stage_back_life(rect: Rect2) -> void:
	var ground_y := _ground_y(rect)
	var rail_y := ground_y - 64.0
	var rail_color := Color(0.02, 0.016, 0.012, COMBAT_STAGE_BACK_RAIL_ALPHA)
	draw_line(Vector2(rect.position.x + 30.0, rail_y), Vector2(rect.position.x + rect.size.x - 30.0, rail_y - 6.0), rail_color, 3.0)
	draw_line(Vector2(rect.position.x + 44.0, rail_y + 15.0), Vector2(rect.position.x + rect.size.x - 44.0, rail_y + 9.0), Color(accent_color.r, accent_color.g, accent_color.b, COMBAT_STAGE_BACK_RAIL_ALPHA * 0.54), 1.4)
	for i in range(COMBAT_STAGE_SPECTATOR_COUNT):
		var t := float(i) / float(maxi(1, COMBAT_STAGE_SPECTATOR_COUNT - 1))
		var x := lerpf(rect.position.x + rect.size.x * 0.08, rect.position.x + rect.size.x * 0.92, t)
		var bob := sin(pulse * 0.82 + float(i) * 0.73) * 1.4
		var y := rail_y + 13.0 + float(i % 3) * 2.4 + bob
		var alpha := 0.18 + float(i % 3) * 0.018
		_draw_stage_spectator(Vector2(x, y), 0.62 + float(i % 2) * 0.08, alpha)
	for i in range(4):
		var x := rect.position.x + rect.size.x * (0.16 + float(i) * 0.22)
		var top := rail_y - 42.0 - float(i % 2) * 7.0
		var sway := sin(pulse * 0.65 + float(i)) * 4.0
		draw_line(Vector2(x, rail_y + 11.0), Vector2(x, top), Color(0.05, 0.034, 0.020, 0.40), 2.0)
		draw_polygon(PackedVector2Array([
			Vector2(x, top + 2.0),
			Vector2(x + 24.0 + sway, top + 11.0),
			Vector2(x + 20.0 + sway, top + 42.0),
			Vector2(x, top + 34.0)
		]), PackedColorArray([
			Color(accent_color.r, accent_color.g, accent_color.b, 0.20),
			Color(accent_color.r, accent_color.g, accent_color.b, 0.13),
			Color(0.06, 0.035, 0.026, 0.22),
			Color(0.04, 0.026, 0.018, 0.24)
		]))

func _draw_stage_spectator(pos: Vector2, scale: float, alpha: float) -> void:
	var body_color := Color(0.018, 0.014, 0.010, alpha)
	var trim_color := Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.44)
	draw_circle(pos + Vector2(0.0, -15.0) * scale, 4.8 * scale, body_color.lightened(0.10))
	draw_line(pos + Vector2(0.0, -10.0) * scale, pos + Vector2(0.0, 10.0) * scale, body_color, 4.2 * scale)
	draw_line(pos + Vector2(-5.0, -4.0) * scale, pos + Vector2(5.0, 4.0) * scale, trim_color, 1.2 * scale)
	draw_line(pos + Vector2(-4.0, 10.0) * scale, pos + Vector2(-8.0, 18.0) * scale, body_color, 2.0 * scale)
	draw_line(pos + Vector2(4.0, 10.0) * scale, pos + Vector2(8.0, 18.0) * scale, body_color, 2.0 * scale)

func _draw_stage_mid_props(rect: Rect2) -> void:
	var ground_y := _ground_y(rect)
	for i in range(COMBAT_STAGE_DEPTH_PROP_COUNT):
		var t := float(i) / float(maxi(1, COMBAT_STAGE_DEPTH_PROP_COUNT - 1))
		var x := lerpf(rect.position.x + 34.0, rect.position.x + rect.size.x - 38.0, t)
		var y := ground_y - 21.0 + float(i % 2) * 7.0
		if i % 3 == 0:
			_draw_stage_weapon_rack(Vector2(x, y), 0.76)
		elif i % 3 == 1:
			_draw_stage_floor_lantern(Vector2(x, y + 2.0), 0.68 + sin(pulse * 1.2 + float(i)) * 0.08)
		else:
			_draw_stage_battle_crate(Vector2(x, y + 11.0), 0.76)

func _draw_stage_weapon_rack(pos: Vector2, scale: float) -> void:
	var alpha := 0.23
	draw_line(pos + Vector2(-11.0, 20.0) * scale, pos + Vector2(-4.0, -20.0) * scale, Color(0.028, 0.018, 0.012, alpha), 2.0 * scale)
	draw_line(pos + Vector2(12.0, 20.0) * scale, pos + Vector2(4.0, -20.0) * scale, Color(0.028, 0.018, 0.012, alpha), 2.0 * scale)
	draw_line(pos + Vector2(-17.0, -9.0) * scale, pos + Vector2(17.0, -11.0) * scale, Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.68), 1.4 * scale)
	for i in range(3):
		var x := (-8.0 + float(i) * 8.0) * scale
		draw_line(pos + Vector2(x, 13.0 * scale), pos + Vector2(x + 7.0 * scale, -31.0 * scale), Color(0.78, 0.74, 0.58, alpha * 0.78), 1.1 * scale)

func _draw_stage_floor_lantern(pos: Vector2, scale: float) -> void:
	var alpha := 0.24
	draw_line(pos + Vector2(0.0, 11.0) * scale, pos + Vector2(0.0, -13.0) * scale, Color(0.05, 0.032, 0.018, alpha), 1.4 * scale)
	draw_circle(pos + Vector2(0.0, -3.0) * scale, 15.0 * scale, Color(1.0, 0.54, 0.16, 0.028))
	draw_rect(Rect2(pos + Vector2(-5.0, -9.0) * scale, Vector2(10.0, 12.0) * scale), Color(0.82, 0.24, 0.13, alpha * 0.80), true)
	draw_line(pos + Vector2(-5.0, -2.0) * scale, pos + Vector2(5.0, -2.0) * scale, Color(1.0, 0.82, 0.38, alpha), 1.0 * scale)

func _draw_stage_battle_crate(pos: Vector2, scale: float) -> void:
	var size := Vector2(26.0, 16.0) * scale
	var rect := Rect2(pos - size * 0.5, size)
	draw_rect(rect, Color(0.055, 0.036, 0.022, 0.24), true)
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.22), false, 1.1 * scale)
	draw_line(rect.position + Vector2(3.0, size.y * 0.5), rect.position + Vector2(size.x - 3.0, size.y * 0.45), Color(accent_color.r, accent_color.g, accent_color.b, 0.12), 1.0 * scale)

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
	var player_pose := _actor_pose("player", player_foot)
	var enemy_pose := _actor_pose("enemy", enemy_foot)
	var player_draw_foot: Vector2 = player_pose.get("foot", player_foot)
	var enemy_draw_foot: Vector2 = enemy_pose.get("foot", enemy_foot)
	var player_action := float(player_pose.get("action", 0.0))
	var enemy_action := float(enemy_pose.get("action", 0.0))
	var player_height := _scaled_stage_actor_height(PLAYER_STAGE_HEIGHT, rect)
	var enemy_height := _scaled_stage_actor_height(ENEMY_STAGE_HEIGHT, rect)
	var player_draw_texture := _actor_texture_for_pose("player", player_texture, player_pose)
	var enemy_draw_texture := _actor_texture_for_pose("enemy", enemy_texture, enemy_pose)
	var player_shadow_scale := 1.08 + player_action * 0.08 + float(player_pose.get("low_hp", 0.0)) * 0.04
	var enemy_shadow_scale := 1.15 + enemy_action * 0.08 + float(enemy_pose.get("low_hp", 0.0)) * 0.04
	_draw_combat_footwork_trails(rect, player_draw_foot, enemy_draw_foot, player_pose, enemy_pose)
	_draw_actor_shadow(player_draw_foot, player_shadow_scale)
	_draw_actor_shadow(enemy_draw_foot, enemy_shadow_scale)
	_draw_actor_contact_light(player_draw_foot, accent_color, 0.90 + player_action * 0.45, 1.0)
	_draw_actor_contact_light(enemy_draw_foot, Color(0.78, 0.18, 0.12), 0.82 + enemy_action * 0.45, 1.08)
	_draw_actor_afterimage(player_draw_texture, player_draw_foot + Vector2(float(player_pose.get("afterimage_x", 0.0)), 0.0), player_height, accent_color.lightened(0.22), float(player_pose.get("afterimage", 0.0)))
	_draw_actor_afterimage(enemy_draw_texture, enemy_draw_foot + Vector2(float(enemy_pose.get("afterimage_x", 0.0)), 0.0), enemy_height, Color(0.95, 0.32, 0.18), float(enemy_pose.get("afterimage", 0.0)))
	_draw_player_actor(player_pose, player_height, player_draw_texture)
	_draw_enemy_actor(enemy_pose, enemy_height, enemy_draw_texture)
	_draw_actor_combat_pose_lines(player_draw_foot, "player", player_pose, accent_color.lightened(0.12))
	_draw_actor_combat_pose_lines(enemy_draw_foot, "enemy", enemy_pose, Color(0.95, 0.28, 0.18))
	_draw_status_bars(player_foot, enemy_foot)
	_draw_action_effects(rect, player_foot, enemy_foot)

func _actor_pose(side: String, base_foot: Vector2) -> Dictionary:
	var hp_ratio := _actor_hp_ratio(side)
	var low_hp := 0.0
	if hp_ratio > 0.0 and hp_ratio <= LOW_HP_STANCE_THRESHOLD:
		low_hp = clampf((LOW_HP_STANCE_THRESHOLD - hp_ratio) / LOW_HP_STANCE_THRESHOLD, 0.0, 1.0)
	var pose := {
		"foot": base_foot,
		"action": 0.0,
		"hurt": 0.0,
		"flash": 0.0,
		"scale_x": 1.0 + low_hp * 0.04,
		"scale_y": 1.0 - low_hp * 0.07,
		"lift": -low_hp * 3.0,
		"afterimage": 0.0,
		"afterimage_x": 0.0,
		"low_hp": low_hp,
		"frame_action": "idle",
		"frame_index": int(floor(pulse * 2.0)) % 2,
		"collapsed": false
	}
	if hp_ratio <= 0.0:
		pose["scale_x"] = 1.34
		pose["scale_y"] = 0.42
		pose["lift"] = 0.0
		pose["collapsed"] = true
		pose["frame_action"] = "down"
		pose["frame_index"] = 0
		pose["foot"] = base_foot + Vector2(0.0, 8.0)
		return pose
	if event_timer <= 0.0:
		return pose
	var hostile_event := event_kind == "damage" or event_kind == "phase" or event_kind == "stun" or event_kind == "miss"
	if not hostile_event:
		return pose
	var motion_scale := _stage_motion_scale()
	var attacker_side := "player" if event_target == "enemy" else "enemy"
	var elapsed := 1.0 - _event_life_ratio()
	var windup := _pose_window(elapsed, 0.16, 0.17)
	var drive := _pose_window(elapsed, 0.48, 0.27)
	var recover := _pose_window(elapsed, 0.78, 0.24)
	var hit_hold := _hit_freeze_alpha()
	if side == attacker_side:
		var direction := 1.0 if side == "player" else -1.0
		var lunge := drive * (ACTOR_LUNGE_PIXELS + hit_hold * 8.0) * motion_scale
		var windback := windup * ACTOR_WINDUP_PIXELS * motion_scale
		var settle := recover * ACTOR_RECOVER_PIXELS * motion_scale
		var attack_foot: Vector2 = pose["foot"]
		pose["foot"] = attack_foot + Vector2(direction * (lunge - windback - settle), (-drive * 4.0 + windup * 1.5) * motion_scale)
		pose["scale_x"] = float(pose["scale_x"]) + drive * ACTOR_ATTACK_STRETCH - windup * 0.03
		pose["scale_y"] = float(pose["scale_y"]) + windup * 0.05 - drive * 0.04
		pose["action"] = clampf(maxf(drive, windup * 0.55) + hit_hold * 0.20, 0.0, 1.0)
		pose["afterimage"] = clampf(drive + hit_hold * 0.35, 0.0, 1.0)
		pose["afterimage_x"] = -direction * (24.0 + lunge * 0.65)
		pose["frame_action"] = "attack"
		if drive > 0.34 or hit_hold > 0.20:
			pose["frame_index"] = 1
		elif recover > 0.36:
			pose["frame_index"] = 2
		else:
			pose["frame_index"] = 0
	elif event_kind != "miss" and side == event_target:
		var hurt_direction := -1.0 if side == "player" else 1.0
		var hurt_wave := sin(elapsed * PI * 3.0) * (1.0 - hit_hold) * 3.0 * motion_scale
		var hurt_foot: Vector2 = pose["foot"]
		pose["foot"] = hurt_foot + Vector2(hurt_direction * (hit_hold * ACTOR_HURT_RECOIL_PIXELS * motion_scale + hurt_wave), hit_hold * 2.5 * motion_scale)
		pose["scale_x"] = float(pose["scale_x"]) + hit_hold * ACTOR_HURT_SQUASH
		pose["scale_y"] = float(pose["scale_y"]) - hit_hold * ACTOR_HURT_SQUASH
		pose["hurt"] = hit_hold
		pose["flash"] = hit_hold
		pose["frame_action"] = "hurt"
		pose["frame_index"] = 0 if hit_hold > 0.34 else 1
	return pose

func _actor_hp_ratio(side: String) -> float:
	if side == "player":
		var player_max := maxi(1, int(GameState.player.get("max_hp", 1)))
		var player_hp := int(GameState.player.get("hp", player_max))
		return clampf(float(maxi(0, player_hp)) / float(player_max), 0.0, 1.0)
	var current_enemy: Dictionary = snapshot.get("enemy", enemy)
	var enemy_max := maxi(1, int(current_enemy.get("max_hp", enemy.get("max_hp", 1))))
	var enemy_hp := int(current_enemy.get("hp", enemy.get("hp", enemy_max)))
	return clampf(float(maxi(0, enemy_hp)) / float(enemy_max), 0.0, 1.0)

func _actor_tint(side: String, base: Color, pose: Dictionary) -> Color:
	var tint := base
	var flash := float(pose.get("flash", 0.0))
	if flash > 0.01:
		var flash_color := Color(1.0, 0.58, 0.44, 1.0) if side == "enemy" else Color(1.0, 0.66, 0.55, 1.0)
		tint = tint.lerp(flash_color, clampf(flash * 0.64, 0.0, 0.64))
	var low_hp := float(pose.get("low_hp", 0.0))
	if low_hp > 0.01:
		tint = tint.lerp(Color(0.78, 0.72, 0.66, 1.0), low_hp * 0.30)
	if bool(pose.get("collapsed", false)):
		tint = tint.darkened(0.28)
	return tint

func _draw_player_actor(pose: Dictionary, target_height: float, texture: Texture2D) -> void:
	var foot: Vector2 = pose.get("foot", Vector2.ZERO)
	var action_intensity := float(pose.get("action", 0.0))
	if texture != null:
		var tint := _actor_tint("player", Color(1.0, 1.0, 1.0, 1.0), pose)
		_draw_actor_texture(texture, foot, target_height + action_intensity * 8.0 * _stage_motion_scale(), tint, action_intensity, pose)
	else:
		_draw_actor_fallback(foot, accent_color, "你")

func _draw_enemy_actor(pose: Dictionary, target_height: float, texture: Texture2D) -> void:
	var foot: Vector2 = pose.get("foot", Vector2.ZERO)
	var action_intensity := float(pose.get("action", 0.0))
	if texture != null:
		var tint := _actor_tint("enemy", Color(1.0, 0.96, 0.91, 1.0), pose)
		_draw_actor_texture(texture, foot, target_height + action_intensity * 8.0 * _stage_motion_scale(), tint, action_intensity, pose)
	else:
		_draw_actor_fallback(foot, Color(0.62, 0.18, 0.14), str(enemy.get("name", "敌")))

func _actor_texture_for_pose(side: String, fallback: Texture2D, pose: Dictionary) -> Texture2D:
	if not COMBAT_ACTOR_FRAME_ANIMATION_ENABLED:
		return fallback
	var frame_bank: Dictionary = player_frame_textures if side == "player" else enemy_frame_textures
	if frame_bank.is_empty():
		return fallback
	var action_name := str(pose.get("frame_action", "idle"))
	var frames: Array = frame_bank.get(action_name, [])
	if frames.is_empty() and action_name != "idle":
		frames = frame_bank.get("idle", [])
	if frames.is_empty():
		return fallback
	var frame_index := int(pose.get("frame_index", 0))
	return frames[abs(frame_index) % frames.size()]

func _draw_actor_texture(texture: Texture2D, foot: Vector2, target_height: float, tint: Color, action_intensity: float = 0.0, pose: Dictionary = {}) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale_x := maxf(0.24, float(pose.get("scale_x", 1.0)))
	var scale_y := maxf(0.24, float(pose.get("scale_y", 1.0)))
	var lift := float(pose.get("lift", 0.0))
	var collapsed := bool(pose.get("collapsed", false))
	var factor := maxf(24.0, target_height * scale_y) / texture_size.y
	var draw_size := Vector2(texture_size.x * factor * scale_x, texture_size.y * factor)
	var anchor_y := draw_size.y + action_intensity * 5.0 + lift
	if collapsed:
		anchor_y = draw_size.y * 0.54
	var top_left := foot - Vector2(draw_size.x * 0.5, anchor_y)
	var outline := Rect2(top_left - Vector2(3.0, 1.5), draw_size + Vector2(6.0, 5.0))
	draw_texture_rect(texture, outline, false, Color(0.0, 0.0, 0.0, 0.46 + action_intensity * 0.08))
	if action_intensity > 0.01:
		draw_texture_rect(texture, Rect2(top_left - Vector2(1.5, 1.5), draw_size), false, Color(tint.r, tint.g, tint.b, 0.12 * action_intensity))
	draw_texture_rect(texture, Rect2(top_left, draw_size), false, tint)
	var flash := float(pose.get("flash", 0.0))
	if flash > 0.01:
		draw_texture_rect(texture, Rect2(top_left - Vector2(2.0, 0.0), draw_size + Vector2(4.0, 0.0)), false, Color(1.0, 0.32, 0.18, HURT_FLASH_ALPHA * flash))
	var rim_alpha := 0.13 + action_intensity * 0.10
	if float(pose.get("low_hp", 0.0)) > 0.01:
		rim_alpha += 0.05
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

func _scaled_stage_actor_height(base_height: float, rect: Rect2) -> float:
	var scale := clampf(rect.size.y / COMBAT_STAGE_REFERENCE_HEIGHT, 1.0, COMBAT_STAGE_ACTOR_MAX_SCALE)
	return base_height * scale

func _stage_motion_scale() -> float:
	return clampf(size.y / COMBAT_STAGE_REFERENCE_HEIGHT, 1.0, COMBAT_STAGE_MOTION_MAX_SCALE)

func _draw_combat_footwork_trails(rect: Rect2, player_foot: Vector2, enemy_foot: Vector2, player_pose: Dictionary, enemy_pose: Dictionary) -> void:
	var player_intensity := clampf(float(player_pose.get("action", 0.0)) + float(player_pose.get("hurt", 0.0)) * 0.48 + float(player_pose.get("low_hp", 0.0)) * 0.24, 0.16, 1.0)
	var enemy_intensity := clampf(float(enemy_pose.get("action", 0.0)) + float(enemy_pose.get("hurt", 0.0)) * 0.48 + float(enemy_pose.get("low_hp", 0.0)) * 0.24, 0.16, 1.0)
	_draw_actor_footwork_trail(player_foot, 1.0, accent_color.lightened(0.12), player_intensity)
	_draw_actor_footwork_trail(enemy_foot, -1.0, Color(0.95, 0.28, 0.18), enemy_intensity)
	if event_timer > 0.0 and (event_kind == "damage" or event_kind == "phase" or event_kind == "stun"):
		var color := _event_color(event_kind, event_target)
		var alpha := sin(_event_life_ratio() * PI) * 0.26
		var y := _ground_y(rect) + 75.0
		draw_line(Vector2(player_foot.x, y), Vector2(enemy_foot.x, y - 7.0), Color(color.r, color.g, color.b, alpha), 5.0)
		draw_line(Vector2(player_foot.x, y + 3.0), Vector2(enemy_foot.x, y - 2.0), Color(1.0, 0.86, 0.44, alpha * 0.44), 1.4)

func _draw_actor_footwork_trail(foot: Vector2, direction: float, color: Color, intensity: float) -> void:
	for i in range(COMBAT_STAGE_FOOTWORK_TRAIL_COUNT):
		var t := float(i) / float(maxi(1, COMBAT_STAGE_FOOTWORK_TRAIL_COUNT - 1))
		var x := foot.x - direction * (18.0 + t * 34.0)
		var y := foot.y + 7.0 + t * 2.4
		var radius := Vector2(24.0 - t * 3.0, 4.5 - t * 0.35)
		var alpha := (0.11 - t * 0.012) * intensity
		_draw_ellipse(Vector2(x, y), radius, Color(color.r, color.g, color.b, alpha))
		draw_line(Vector2(x - direction * radius.x * 0.38, y - 1.0), Vector2(x + direction * radius.x * 0.42, y - 2.0), Color(1.0, 0.86, 0.45, alpha * 0.58), 1.0)

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

func _draw_actor_combat_pose_lines(foot: Vector2, side: String, pose: Dictionary, color: Color) -> void:
	if bool(pose.get("collapsed", false)):
		return
	var direction := 1.0 if side == "player" else -1.0
	var action := float(pose.get("action", 0.0))
	var hurt := float(pose.get("hurt", 0.0))
	var low_hp := float(pose.get("low_hp", 0.0))
	var pulse_alpha := 0.56 + sin(pulse * 2.0 + (0.0 if side == "player" else 0.8)) * 0.12
	var stance_alpha := COMBAT_POSE_LINE_ALPHA * clampf(0.55 + action * 0.62 + hurt * 0.34 + low_hp * 0.22, 0.0, 1.18) * pulse_alpha
	var shoulder := foot + Vector2(direction * 16.0, -108.0)
	var hand := foot + Vector2(direction * (35.0 + action * 24.0 - hurt * 7.0), -69.0 + action * 5.0)
	var tip := hand + Vector2(direction * (36.0 + action * 32.0), -20.0 + action * 4.0)
	var hip := foot + Vector2(direction * 10.0, -54.0)
	draw_line(shoulder, hand, Color(color.r, color.g, color.b, stance_alpha), 2.0 + action * 1.3)
	draw_line(shoulder, hip, Color(1.0, 0.90, 0.62, stance_alpha * 0.54), 1.3)
	draw_line(hand, tip, Color(1.0, 0.92, 0.64, COMBAT_WEAPON_GLOW_ALPHA * clampf(0.42 + action * 0.70, 0.0, 1.0)), 1.6 + action * 1.1)
	if action > 0.05:
		var normal := Vector2(-direction * 0.16, -0.98)
		draw_line(hand - normal * 7.0, tip + normal * 8.0, Color(color.r, color.g, color.b, COMBAT_WEAPON_GLOW_ALPHA * action * 0.42), 4.0)

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
	var impact := _event_life_ratio()
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
	_draw_attack_telegraph(start, finish, color, alpha)
	_draw_attack_ground_streak(start, finish, color, alpha)
	_draw_event_air_cuts(start, finish, color, alpha)
	_draw_event_foreground_ripples(rect, start, finish, color, alpha)
	_draw_impact_speed_lines(rect, start, finish, color, alpha)
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
	if _is_heavy_hit():
		_draw_combo_burst(finish, color, alpha)
	_draw_hit_sparks(finish, color, alpha)
	_draw_ground_cracks(finish + Vector2(0.0, 86.0), color, alpha)
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

func _draw_attack_telegraph(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var elapsed := 1.0 - _event_life_ratio()
	var windup := _pose_window(elapsed, 0.18, 0.22)
	var hit_hold := _hit_freeze_alpha()
	var trail_alpha := clampf(alpha * 0.38 + windup * 0.54 + hit_hold * 0.18, 0.0, 1.0)
	if trail_alpha <= 0.02:
		return
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var intensity := _event_intensity()
	_draw_focus_ring(start, color, ATTACK_TELEGRAPH_ALPHA * trail_alpha * 0.72, effect_style)
	for i in range(ATTACK_TRAIL_LAYER_COUNT):
		var t := float(i) / float(maxi(1, ATTACK_TRAIL_LAYER_COUNT - 1))
		var from := start.lerp(finish, 0.08 + t * 0.22)
		var to := start.lerp(finish, 0.48 + t * 0.36)
		var offset := normal * sin(pulse * 1.8 + float(i) * 0.82) * (5.0 + t * 9.0)
		var line_alpha := ATTACK_TELEGRAPH_ALPHA * trail_alpha * (0.70 - t * 0.08) * intensity
		draw_line(from + offset, to - offset * 0.30, Color(color.r, color.g, color.b, line_alpha), 2.8 + t * 1.1)
		draw_line(from + offset * 0.45, to - offset * 0.15, Color(1.0, 0.92, 0.62, line_alpha * 0.42), 1.0)

func _draw_event_air_cuts(start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var delta := finish - start
	if delta.length_squared() <= 0.001:
		return
	var hit_hold := _hit_freeze_alpha()
	var elapsed := 1.0 - _event_life_ratio()
	var pressure := clampf(alpha * 0.46 + hit_hold * 0.46 + _pose_window(elapsed, 0.34, 0.28) * 0.22, 0.0, 1.0)
	if pressure <= 0.02:
		return
	var dir := delta.normalized()
	var normal := Vector2(-dir.y, dir.x)
	var intensity := _event_intensity()
	var heavy_bonus := 1.22 if _is_heavy_hit() else 1.0
	for i in range(COMBAT_EVENT_AIR_CUT_COUNT):
		var t := float(i) / float(maxi(1, COMBAT_EVENT_AIR_CUT_COUNT - 1))
		var cut_center := start.lerp(finish, 0.18 + t * 0.68)
		var stagger := normal * (float(i) - float(COMBAT_EVENT_AIR_CUT_COUNT - 1) * 0.5) * (6.2 + intensity * 1.8)
		var lift := Vector2(0.0, -18.0 - sin(pulse * 2.0 + float(i) * 0.7) * 6.0 - t * 5.0)
		var length := (26.0 + float((i * 13) % 21) + intensity * 12.0) * heavy_bonus
		var sweep := dir * length
		var skew := normal * sin(pulse * 1.3 + float(i)) * 5.0
		var p0 := cut_center - sweep * 0.5 + stagger + lift + skew
		var p1 := cut_center + sweep * 0.5 + stagger + lift - skew * 0.4
		var line_alpha := COMBAT_EVENT_AIR_CUT_ALPHA * pressure * (0.92 - t * 0.10) * heavy_bonus
		draw_line(p0, p1, Color(color.r, color.g, color.b, line_alpha), 1.6 + intensity * 0.55 + float(i % 2) * 0.45)
		if i % 2 == 0:
			draw_line(p0 + normal * 3.0, p1 + normal * 1.0, Color(1.0, 0.95, 0.72, line_alpha * 0.38), 0.9)

func _draw_event_foreground_ripples(rect: Rect2, start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var hit_hold := _hit_freeze_alpha()
	var elapsed := 1.0 - _event_life_ratio()
	var ripple_alpha := clampf(alpha * 0.34 + hit_hold * 0.58 + _pose_window(elapsed, 0.50, 0.24) * 0.20, 0.0, 1.0)
	if ripple_alpha <= 0.02:
		return
	var direction := 1.0 if finish.x >= start.x else -1.0
	var intensity := _event_intensity()
	var life := 1.0 - _event_life_ratio()
	var y_base := rect.position.y + rect.size.y * 0.765
	var travel := direction * life * rect.size.x * 0.10
	for i in range(COMBAT_EVENT_FOREGROUND_RIPPLE_COUNT):
		var t := float(i) / float(maxi(1, COMBAT_EVENT_FOREGROUND_RIPPLE_COUNT - 1))
		var center_x := start.lerp(finish, 0.52 + (t - 0.5) * 0.18).x + travel + direction * (float(i) - 2.0) * 13.0
		center_x = clampf(center_x, rect.position.x + 52.0, rect.position.x + rect.size.x - 52.0)
		var band_y := y_base + t * 14.0 + sin(pulse * 1.4 + float(i)) * 2.0
		var width := rect.size.x * (0.20 + intensity * 0.035) + float(i) * 24.0
		var height := 5.0 + float(i % 3) * 2.0 + hit_hold * 2.0
		var shear := direction * (34.0 + intensity * 12.0 + float(i) * 4.0)
		var band_alpha := COMBAT_EVENT_FOREGROUND_RIPPLE_ALPHA * ripple_alpha * (0.95 - t * 0.10)
		var points := PackedVector2Array([
			Vector2(center_x - width * 0.5, band_y),
			Vector2(center_x + width * 0.5, band_y - 6.0),
			Vector2(center_x + width * 0.5 + shear, band_y + height),
			Vector2(center_x - width * 0.5 + shear * 0.35, band_y + height + 5.0)
		])
		draw_polygon(points, PackedColorArray([
			Color(color.r, color.g, color.b, band_alpha * 0.18),
			Color(1.0, 0.90, 0.58, band_alpha * 0.32),
			Color(color.r, color.g, color.b, band_alpha * 0.25),
			Color(0.08, 0.045, 0.025, band_alpha * 0.20)
		]))
		draw_line(points[0], points[1], Color(1.0, 0.86, 0.46, band_alpha * 0.46), 1.0 + t * 0.5)

func _draw_combo_burst(center: Vector2, color: Color, alpha: float) -> void:
	var hit_hold := _hit_freeze_alpha()
	var burst_alpha := clampf(maxf(alpha * 0.54, hit_hold), 0.0, 1.0)
	if burst_alpha <= 0.02:
		return
	var intensity := _event_intensity()
	for i in range(COMBO_BURST_RING_COUNT):
		var radius := 24.0 + float(i) * 15.0 + intensity * 6.0
		draw_arc(center, radius, -0.42 + float(i) * 0.12, TAU - 0.42, 56, Color(color.r, color.g, color.b, 0.24 * burst_alpha / float(i + 1)), 2.2)
	for i in range(COMBO_BURST_RING_COUNT + 2):
		var angle := float(i) * TAU / float(COMBO_BURST_RING_COUNT + 2) + pulse * 0.24
		var dir := Vector2(cos(angle), sin(angle) * 0.62)
		var inner := center + dir * (12.0 + intensity * 4.0)
		var outer := center + dir * (44.0 + float(i % 3) * 9.0 + intensity * 8.0)
		draw_line(inner, outer, Color(1.0, 0.90, 0.58, 0.34 * burst_alpha), 1.8)

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
	var life := 1.0 - _event_life_ratio()
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

func _draw_impact_speed_lines(rect: Rect2, start: Vector2, finish: Vector2, color: Color, alpha: float) -> void:
	var hit_hold := _hit_freeze_alpha()
	if alpha <= 0.02 or hit_hold <= 0.01:
		return
	var dir := (finish - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var center := start.lerp(finish, 0.58)
	for i in range(IMPACT_SPEED_LINE_COUNT):
		var spread := (float(i) - float(IMPACT_SPEED_LINE_COUNT - 1) * 0.5) * 13.5
		var length := 42.0 + float((i * 11) % 28)
		var origin := center - dir * (38.0 + float(i % 3) * 11.0) + normal * spread
		var end := origin + dir * length + normal * sin(pulse + float(i)) * 3.0
		var line_alpha := (0.10 + float(i % 3) * 0.035) * alpha * hit_hold
		draw_line(origin, end, Color(1.0, 0.94, 0.70, line_alpha), 1.4 + float(i % 2) * 0.7)
		if rect.has_point(end):
			draw_circle(end, 1.2, Color(color.r, color.g, color.b, line_alpha * 1.3))

func _draw_ground_cracks(center: Vector2, color: Color, alpha: float) -> void:
	var hit_hold := _hit_freeze_alpha()
	if alpha <= 0.02 or hit_hold <= 0.01:
		return
	for i in range(GROUND_CRACK_COUNT):
		var angle := -0.78 + float(i) * 0.39 + sin(pulse * 0.8 + float(i)) * 0.04
		var length := 18.0 + float((i * 9) % 17) + event_shake_strength * 1.6
		var start := center + Vector2(cos(angle), sin(angle) * 0.38) * 7.0
		var end := start + Vector2(cos(angle), sin(angle) * 0.46) * length
		draw_line(start + Vector2(1.0, 1.5), end + Vector2(1.0, 1.5), Color(0.0, 0.0, 0.0, 0.24 * alpha * hit_hold), 2.4)
		draw_line(start, end, Color(color.r, color.g, color.b, 0.20 * alpha * hit_hold), 1.5)

func _draw_impact_overlay(rect: Rect2) -> void:
	if event_timer <= 0.0 or event_shake_strength <= 0.0:
		return
	var hit_hold := _hit_freeze_alpha()
	if hit_hold <= 0.01:
		return
	var color := _event_color(event_kind, event_target)
	draw_rect(rect, Color(1.0, 0.92, 0.68, 0.055 * hit_hold), true)
	var center_x := rect.position.x + rect.size.x * (0.72 if event_target == "enemy" else 0.28)
	var center := Vector2(center_x, rect.position.y + rect.size.y * 0.50)
	for i in range(4):
		var radius := 44.0 + float(i) * 28.0
		draw_arc(center, radius, -0.35, TAU - 0.35, 64, Color(color.r, color.g, color.b, 0.16 * hit_hold / float(i + 1)), 2.0)

func _draw_foreground(rect: Rect2) -> void:
	var bottom_fog := Color(0.90, 0.84, 0.70, 0.13 + sin(pulse * 0.7) * 0.025)
	_draw_soft_band(Rect2(rect.position + Vector2(0.0, rect.size.y * 0.78), Vector2(rect.size.x, 40.0)), bottom_fog)
	_draw_stage_foreground_pressure(rect)
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
	_draw_combat_stage_texture_layer(stage_foreground_texture, rect, COMBAT_STAGE_FOREGROUND_ALPHA)

func _draw_stage_foreground_pressure(rect: Rect2) -> void:
	var alpha := COMBAT_STAGE_FOREGROUND_PRESSURE_ALPHA
	for i in range(COMBAT_STAGE_FOREGROUND_OCCLUDER_COUNT):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := rect.position.x + (rect.size.x * (0.035 + float(i / 2) * 0.028) if side < 0.0 else rect.size.x * (0.965 - float(i / 2) * 0.028))
		var y0 := rect.position.y + rect.size.y * (0.08 + float(i % 3) * 0.035)
		var y1 := rect.position.y + rect.size.y * (0.93 - float(i % 2) * 0.05)
		var width := 6.0 + float(i % 3) * 2.0
		draw_line(Vector2(x, y0), Vector2(x + side * 16.0, y1), Color(0.014, 0.010, 0.007, alpha * (0.76 - float(i) * 0.045)), width)
		draw_line(Vector2(x + side * 2.5, y0 + 24.0), Vector2(x + side * 20.0, y0 + 74.0), Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.30), 1.4)
	for i in range(3):
		var x := rect.position.x + rect.size.x * (0.22 + float(i) * 0.28)
		var y := rect.position.y + 1.0
		var sway := sin(pulse * 0.7 + float(i) * 0.8) * 7.0
		draw_polygon(PackedVector2Array([
			Vector2(x, y),
			Vector2(x + 34.0 + sway, y + 4.0),
			Vector2(x + 29.0 + sway, y + 28.0),
			Vector2(x - 3.0, y + 23.0)
		]), PackedColorArray([
			Color(0.036, 0.022, 0.014, alpha * 0.88),
			Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.38),
			Color(0.018, 0.012, 0.008, alpha * 0.78),
			Color(0.028, 0.018, 0.011, alpha * 0.82)
		]))

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

func _event_life_ratio() -> float:
	return clampf(event_timer / COMBAT_EVENT_DURATION, 0.0, 1.0)

func _hit_freeze_alpha() -> float:
	if event_timer <= 0.0 or event_shake_strength <= 0.0:
		return 0.0
	var distance := absf(_event_life_ratio() - 0.50)
	return clampf(1.0 - distance / HIT_FREEZE_WINDOW, 0.0, 1.0)

func _pose_window(value: float, center: float, radius: float) -> float:
	return clampf(1.0 - absf(value - center) / maxf(0.001, radius), 0.0, 1.0)

func _stage_shake_offset() -> Vector2:
	var hit_hold := _hit_freeze_alpha()
	if hit_hold <= 0.01:
		return Vector2.ZERO
	var strength := event_shake_strength * hit_hold
	var direction := 1.0 if event_target == "enemy" else -1.0
	return Vector2(
		sin(pulse * 82.0 + float(last_event_id) * 1.7) * strength * direction,
		cos(pulse * 73.0 + float(last_event_id) * 0.9) * strength * 0.42
	)

func _event_shake_strength(kind: String, style: String, amount: int) -> float:
	if kind != "damage" and kind != "phase" and kind != "stun":
		return 0.0
	var strength := HIT_SHAKE_PIXELS
	if amount >= HEAVY_DAMAGE_THRESHOLD or kind == "phase" or kind == "stun":
		strength = HEAVY_HIT_SHAKE_PIXELS
	match style:
		"fire", "blade", "palm", "shadow":
			strength *= 1.12
		"poison", "ice":
			strength *= 0.88
		_:
			strength *= 1.0
	return strength

func _event_intensity() -> float:
	if event_kind == "phase" or event_kind == "stun":
		return 1.22
	if event_kind != "damage":
		return 0.0
	var amount_ratio := float(maxi(0, event_amount)) / float(maxi(1, HEAVY_DAMAGE_THRESHOLD))
	return clampf(0.62 + amount_ratio * 0.50, 0.62, 1.34)

func _is_heavy_hit() -> bool:
	return event_kind == "phase" or event_kind == "stun" or (event_kind == "damage" and event_amount >= HEAVY_DAMAGE_THRESHOLD)

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

func _stage_palette() -> Dictionary:
	var region_type := str(current_region.get("type", "wild"))
	var sky := Color(0.29, 0.34, 0.31, 0.34)
	var far := Color(0.10, 0.12, 0.10, 0.42)
	var mid := Color(0.16, 0.18, 0.13, 0.36)
	var floor := terrain_color.lightened(0.08)
	var accent := accent_color
	if terrain_key.contains("snow"):
		sky = Color(0.48, 0.58, 0.66, 0.38)
		far = Color(0.34, 0.42, 0.50, 0.42)
		mid = Color(0.52, 0.58, 0.62, 0.34)
		floor = Color(0.58, 0.64, 0.66, 1.0)
		accent = Color(0.70, 0.90, 1.0, 1.0)
	elif terrain_key.contains("desert"):
		sky = Color(0.58, 0.46, 0.28, 0.36)
		far = Color(0.46, 0.32, 0.18, 0.42)
		mid = Color(0.63, 0.46, 0.24, 0.34)
		floor = Color(0.56, 0.42, 0.24, 1.0)
		accent = Color(0.95, 0.72, 0.36, 1.0)
	elif terrain_key.contains("river") or terrain_key.contains("lake") or terrain_key.contains("water") or terrain_key.contains("canal") or terrain_key.contains("ford"):
		sky = Color(0.27, 0.42, 0.47, 0.34)
		far = Color(0.12, 0.22, 0.26, 0.42)
		mid = Color(0.18, 0.32, 0.36, 0.34)
		floor = Color(0.30, 0.39, 0.36, 1.0)
		accent = Color(0.58, 0.82, 0.86, 1.0)
	elif terrain_key.contains("forest") or terrain_key.contains("bamboo") or terrain_key.contains("garden") or terrain_key.contains("field"):
		sky = Color(0.22, 0.34, 0.24, 0.34)
		far = Color(0.06, 0.16, 0.08, 0.44)
		mid = Color(0.12, 0.25, 0.12, 0.36)
		floor = Color(0.26, 0.34, 0.20, 1.0)
		accent = Color(0.50, 0.76, 0.38, 1.0)
	elif region_type == "sect":
		floor = Color(0.38, 0.34, 0.27, 1.0)
		accent = GameData.get_faction_color(str(current_region.get("faction", "none"))).lightened(0.20)
	elif region_type == "city" or region_type == "town":
		floor = Color(0.44, 0.34, 0.22, 1.0)
		accent = Color(0.92, 0.60, 0.28, 1.0)
	return {
		"sky": sky,
		"far": far,
		"mid": mid,
		"floor": floor,
		"accent": accent
	}

func _is_snow_terrain() -> bool:
	return terrain_key.contains("snow")

func _is_forest_terrain() -> bool:
	return terrain_key.contains("forest") or terrain_key.contains("bamboo") or terrain_key.contains("marsh")

func _is_city_terrain() -> bool:
	return terrain_key.contains("city") or terrain_key.contains("town") or terrain_key.contains("village") or terrain_key.contains("sect") or terrain_key.contains("temple")
