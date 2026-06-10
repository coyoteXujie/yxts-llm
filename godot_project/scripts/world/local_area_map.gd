extends Node2D
class_name LocalAreaMap

const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const MAP_PROP_SCRIPT := preload("res://scripts/world/map_prop.gd")
const STAGE_FOREGROUND_SCRIPT := preload("res://scripts/world/local_stage_foreground.gd")
const STAGE_POSTFX_SCRIPT := preload("res://scripts/world/local_stage_postfx.gd")
const STAGE_SCENE_SCRIPT := preload("res://scripts/world/local_stage_scene.gd")
const StageVisualProfile = preload("res://scripts/shared/stage_visual_profile.gd")
const STAGE_BACKDROP_RENDERER := preload("res://scripts/shared/stage_backdrop_renderer.gd")
const STAGE_SURFACE_DETAIL_RENDERER := preload("res://scripts/shared/stage_surface_detail_renderer.gd")

enum Tile {
	GRASS,
	ROAD,
	WATER,
	BUILDING,
	SHOP,
	WALL,
	GARDEN,
	FIELD,
	MOUNTAIN,
	BRIDGE,
	FLOOR,
	COUNTER,
	CARPET
}

const SHOP_DEFINITIONS := {
	"inn": {
		"name": "客栈",
		"keeper": "平阿四",
		"description": "客栈掌柜，管吃住，也最先听见江湖消息。",
		"sell_items": ["item_baozi", "item_chicken", "item_wine"],
		"can_rest": true,
		"accent": Color(0.86, 0.56, 0.26)
	},
	"medicine": {
		"name": "药铺",
		"keeper": "平一指",
		"description": "坐堂郎中，出售金创药、生肌散和小还丹。",
		"sell_items": ["item_yao", "item_shengji", "item_dan"],
		"accent": Color(0.42, 0.72, 0.46)
	},
	"blacksmith": {
		"name": "铁匠铺",
		"keeper": "铁匠",
		"description": "火炉旁的铁匠，出售刀剑与入门兵器。",
		"sell_items": ["item_sword", "item_blade", "item_dagger", "item_whip", "item_hetun_blade"],
		"accent": Color(0.82, 0.32, 0.20)
	},
	"tailor": {
		"name": "布庄",
		"keeper": "小裁缝",
		"description": "布庄裁缝，出售布衣、细布衣和丝绸衣。",
		"sell_items": ["item_cloth", "item_fine_cloth", "item_silk_cloth"],
		"accent": Color(0.72, 0.54, 0.82)
	},
	"market": {
		"name": "市集",
		"keeper": "小商贩",
		"description": "市集货郎，卖些吃食、花草和杂物。",
		"sell_items": ["item_tang_hulu", "item_white_doufu", "item_green_doufu", "item_meat", "item_fish", "item_red_flower", "item_tea_flower"],
		"accent": Color(0.90, 0.70, 0.28)
	},
	"teahouse": {
		"name": "茶肆",
		"keeper": "阿青",
		"description": "茶肆女主人，出售豆腐、清茶与街巷消息。",
		"sell_items": ["item_white_doufu", "item_green_doufu", "item_wine"],
		"accent": Color(0.58, 0.78, 0.62)
	}
}

const TILE_TEXTURE_PATHS := {
	Tile.GRASS: "res://assets/world/tiles/tile_grass.png",
	Tile.ROAD: "res://assets/world/tiles/tile_road.png",
	Tile.WATER: "res://assets/world/tiles/tile_water.png",
	Tile.BUILDING: "res://assets/world/tiles/tile_building.png",
	Tile.SHOP: "res://assets/world/tiles/tile_shop.png",
	Tile.WALL: "res://assets/world/tiles/tile_courtyard.png",
	Tile.GARDEN: "res://assets/world/tiles/tile_bamboo.png",
	Tile.FIELD: "res://assets/world/tiles/tile_field.png",
	Tile.MOUNTAIN: "res://assets/world/tiles/tile_mountain.png",
	Tile.BRIDGE: "res://assets/world/tiles/tile_bridge.png",
	Tile.FLOOR: "res://assets/world/tiles/tile_courtyard.png",
	Tile.COUNTER: "res://assets/world/tiles/tile_building.png",
	Tile.CARPET: "res://assets/world/tiles/tile_temple.png",
}

const LOCAL_NPC_SPACING_STEPS := [6, 5, 4, 3, 2, 1]
const LOCAL_NPC_ENTRY_CLEAR_RADIUS := 7
const LOCAL_NPC_SCALE := 1.0
const TILE_VARIANT_COUNT := 4
const LOCAL_PAINTERLY_SKIP_SCENE_TEXTURES := false
const LOCAL_PAINTERLY_TILE_OVERDRAW := 1.22
const LOCAL_USE_TILE_TEXTURES := false
const LOCAL_PAINTERLY_FORCE_TEXTURELESS_STAGE := (LOCAL_PAINTERLY_SKIP_SCENE_TEXTURES and not LOCAL_USE_TILE_TEXTURES)
const LOCAL_SIDE_VIEW_HIDE_TILE_GRID := true
const LOCAL_DYNAMIC_VISUALS_ENABLED := true
const LOCAL_PAINTED_STAGE_TEXTURE_PRIORITY := true
const LOCAL_STAGE_REDRAW_INTERVAL := 1.0 / 18.0
const LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_COUNT := 240
const LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_RADIUS_MIN := 0.72
const LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_RADIUS_MAX := 2.38
const LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_ALPHA := 0.032
const LOCAL_PAINTERLY_TILE_VARIATION := 0.24
const LOCAL_PAINTERLY_TILE_GRAIN_ALPHA := 0.12
const LOCAL_PAINTERLY_TILE_BLOB_COUNT := 4
const LOCAL_PAINTERLY_MELT_STROKE_COUNT := 170
const LOCAL_PAINTERLY_MELT_BLOB_COUNT := 60
const LOCAL_PAINTERLY_MELT_STROKE_ALPHA := 0.028
const LOCAL_PAINTERLY_MELT_BLOB_ALPHA := 0.024
const LOCAL_PAINTERLY_BUILDING_BLOCK_ALPHA := 0.11
const SIDE_VIEW_BACKDROP_ALPHA := 0.38
const SIDE_VIEW_PAINTED_BACKDROP_ALPHA := 0.86
const SIDE_VIEW_PAINTED_BACKDROP_SKY_BLEND := 0.18
const SIDE_VIEW_PAINTED_BACKDROP_FOOT_BLEND := 0.30
const SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA := 0.22
const SIDE_VIEW_PAINTED_MIDGROUND_LAYER_ALPHA := 0.96
const SIDE_VIEW_PAINTED_MIDGROUND_LAYER_FOG_ALPHA := 0.14
const SIDE_VIEW_PAINTED_MIDGROUND_LAYER_FOOT_ALPHA := 0.18
const SIDE_VIEW_PAINTED_FLOOR_LAYER_ALPHA := 0.94
const SIDE_VIEW_PAINTED_FLOOR_LAYER_FOOT_ALPHA := 0.22
const SIDE_VIEW_STAGE_LANE_ALPHA := 0.44
const SIDE_VIEW_FOREGROUND_ALPHA := 0.36
const SIDE_VIEW_STAGE_SCENE_Z := -3000
const SIDE_VIEW_FOREGROUND_OVERLAY_Z := 3350
const SIDE_VIEW_POSTFX_Z := 3220
const SIDE_VIEW_DEPTH_GUIDE_ALPHA := 0.18
const SIDE_VIEW_MIDGROUND_STRUCTURE_ALPHA := 0.46
const SIDE_VIEW_PLATFORM_EDGE_ALPHA := 0.42
const SIDE_VIEW_NEAR_PROP_COUNT := 14
const SIDE_VIEW_FLOOR_DETAIL_ALPHA := 0.16
const SIDE_VIEW_FLOOR_DETAIL_COUNT := 36
const SIDE_VIEW_PERSPECTIVE_EDGE_ALPHA := 0.18
const SIDE_VIEW_PARALLAX_LAYER_COUNT := 4
const SIDE_VIEW_BACKDROP_DETAIL_COUNT := 18
const SIDE_VIEW_PARALLAX_DRIFT := 0.28
const SIDE_VIEW_SETPIECE_COUNT := 12
const SIDE_VIEW_SETPIECE_ALPHA := 0.36
const SIDE_VIEW_SETPIECE_DEPTH_BANDS := 3
const SIDE_VIEW_STREET_FACADE_COUNT := 11
const SIDE_VIEW_STREET_FACADE_ALPHA := 0.44
const SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA := 0.36
const SIDE_VIEW_STREET_SIGN_COUNT := 8
const SIDE_VIEW_UPPER_WALKWAY_COUNT := 4
const SIDE_VIEW_UPPER_WALKWAY_ALPHA := 0.34
const SIDE_VIEW_STAIR_LINK_COUNT := 3
const SIDE_VIEW_BALCONY_LANTERN_COUNT := 7
const LOCAL_SCENE_BACKGROUND_WASH_BASE_ALPHA := 0.28
const LOCAL_SCENE_BACKGROUND_WASH_CITY_ALPHA := 0.34
const LOCAL_SCENE_BACKGROUND_WASH_SECT_ALPHA := 0.38
const LOCAL_SCENE_WASH_SIDE_VIEW_MULTIPLIER := 0.86
const LOCAL_PAINTERLY_STROKE_COUNT := StageVisualProfile.LOCAL_PAINTERLY_STROKE_COUNT
const LOCAL_PAINTERLY_STROKE_ALPHA := StageVisualProfile.LOCAL_PAINTERLY_STROKE_ALPHA
const LOCAL_PAINTERLY_DOT_COUNT := StageVisualProfile.LOCAL_PAINTERLY_DOT_COUNT
const LOCAL_PAINTERLY_DOT_ALPHA := StageVisualProfile.LOCAL_PAINTERLY_DOT_ALPHA
const LOCAL_BUILDING_EDGE_DECIMATION := StageVisualProfile.LOCAL_BUILDING_EDGE_DECIMATION
const LOCAL_BUILDING_EDGE_ALPHA := StageVisualProfile.LOCAL_BUILDING_EDGE_ALPHA
const LOCAL_BUILDING_EDGE_WIDTH := StageVisualProfile.LOCAL_BUILDING_EDGE_WIDTH
const LOCAL_BUILDING_SURFACE_STROKE_COUNT := StageVisualProfile.LOCAL_BUILDING_SURFACE_STROKE_COUNT
const LOCAL_BUILDING_SURFACE_DOT_COUNT := StageVisualProfile.LOCAL_BUILDING_SURFACE_DOT_COUNT
const LOCAL_BUILDING_SURFACE_ALPHA := StageVisualProfile.LOCAL_BUILDING_SURFACE_ALPHA
const LOCAL_BUILDING_SURFACE_SEED_BASE := StageVisualProfile.LOCAL_BUILDING_SURFACE_SEED_BASE
const LOCAL_BUILDING_SURFACE_LINE_JITTER := StageVisualProfile.LOCAL_BUILDING_SURFACE_LINE_JITTER
const LOCAL_BUILDING_FACADE_PILLAR_COUNT := StageVisualProfile.LOCAL_BUILDING_FACADE_PILLAR_COUNT
const LOCAL_BUILDING_FACADE_WINDOW_ROWS := StageVisualProfile.LOCAL_BUILDING_FACADE_WINDOW_ROWS
const LOCAL_BUILDING_FACADE_WINDOW_COLUMNS := StageVisualProfile.LOCAL_BUILDING_FACADE_WINDOW_COLUMNS
const LOCAL_BUILDING_FACADE_WINDOW_ALPHA := StageVisualProfile.LOCAL_BUILDING_FACADE_WINDOW_ALPHA
const LOCAL_BUILDING_FACADE_SHADOW_ALPHA := StageVisualProfile.LOCAL_BUILDING_FACADE_SHADOW_ALPHA
const LOCAL_BUILDING_FACADE_SEED_BASE := StageVisualProfile.LOCAL_BUILDING_FACADE_SEED_BASE
const LOCAL_BUILDING_FACADE_LINE_JITTER := StageVisualProfile.LOCAL_BUILDING_FACADE_LINE_JITTER
const LOCAL_SIDE_TILE_DETAIL_DECIMATION := StageVisualProfile.LOCAL_MAP_TILE_DETAIL_DECIMATION
const LOCAL_SIDE_TILE_TRANSITION_DECIMATION := StageVisualProfile.LOCAL_MAP_TILE_TRANSITION_DECIMATION
const LOCAL_SIDE_BUILDING_TILE_DECIMATION := StageVisualProfile.LOCAL_MAP_BUILDING_TILE_DECIMATION
const SIDE_VIEW_LIVING_ACTOR_COUNT := 12
const SIDE_VIEW_LIVING_ACTOR_ALPHA := 0.30
const SIDE_VIEW_LIVING_ACTOR_SPEED := 0.18
const SIDE_VIEW_LIVING_ACTION_ARC_COUNT := 7
const SIDE_VIEW_DIRECTOR_BAND_ALPHA := 0.24
const SIDE_VIEW_DEPTH_FOG_BAND_COUNT := 6
const SIDE_VIEW_PLATFORM_RIM_COUNT := 4
const SIDE_VIEW_STAGE_FOCUS_RAY_COUNT := 7
const SIDE_VIEW_STAGE_FOCUS_ALPHA := 0.16
const SIDE_VIEW_PLAY_LANE_COUNT := 5
const SIDE_VIEW_PLAY_LANE_ALPHA := 0.22
const SIDE_VIEW_PLAY_LANE_EDGE_ALPHA := 0.30
const SIDE_VIEW_LANE_DECAL_COUNT := 24
const SIDE_VIEW_LANE_SHADOW_COUNT := 5
const SIDE_VIEW_LANE_SHADOW_ALPHA := 0.24
const SIDE_VIEW_SIDE_EXIT_COUNT := 4
const SIDE_VIEW_SIDE_EXIT_ALPHA := 0.28
const SIDE_VIEW_TERRACE_BAND_COUNT := 5
const SIDE_VIEW_TERRACE_ALPHA := 0.34
const SIDE_VIEW_TERRACE_RAIL_ALPHA := 0.32
const SIDE_VIEW_TERRAIN_OCCLUDER_COUNT := 10
const SIDE_VIEW_TERRAIN_OCCLUDER_ALPHA := 0.30
const SIDE_VIEW_LANE_ANCHOR_FULL_DISTANCE := 18.0
const SIDE_VIEW_LANE_ANCHOR_MAX_DISTANCE := 92.0
const SIDE_VIEW_AMBIENT_SPEED := 0.82
const SIDE_VIEW_AMBIENT_PARTICLES := 32
const LOCAL_TOWN_SHOP_ENTRANCE_ALPHA := 0.82
const LOCAL_TOWN_SHOP_DOOR_GLOW_ALPHA := 0.34
const LOCAL_TOWN_SHOP_SIGN_WIDTH := 104.0
const LOCAL_TOWN_SHOP_SIGN_HEIGHT := 24.0
const RICH_SHOP_INTERIOR_ENABLED := true
const SHOP_INTERIOR_BACK_WALL_RATIO := 0.48
const SHOP_INTERIOR_COUNTER_ALPHA := 0.92
const SHOP_INTERIOR_SHELF_ALPHA := 0.82
const SHOP_INTERIOR_THEME_PROP_ALPHA := 0.88
const SHOP_INTERIOR_LIGHT_ALPHA := 0.32
const STAGE_DEPTH_TOP_RATIO := 0.48
const STAGE_DEPTH_BOTTOM_RATIO := 0.95
const STAGE_DEPTH_MIN_SCALE := 0.86
const STAGE_DEPTH_MAX_SCALE := 1.24

var tile_size := GameData.TILE_SIZE
var map_width := 64
var map_height := 42
var tiles: Array = []
var current_region: Dictionary = {}
var current_mode := "region"
var portals: Array = []
var portal_labels: Array[Label] = []
var title_label: Label
var npc_nodes: Array = []
var prop_nodes: Array[Node2D] = []
var highlighted_portal_id := ""
var active_shop_id := ""
var shop_return_tile := Vector2i.ZERO
var tile_textures: Dictionary = {}
var scene_background_texture: Texture2D
var scene_midground_layer_texture: Texture2D
var scene_floor_layer_texture: Texture2D
var occupied_npc_tiles: Array[Vector2i] = []
var side_view_stage_enabled := true
var stage_visual_phase := 0.0
var stage_redraw_accumulator := 0.0
var stage_scene_layer: Node2D
var stage_foreground_overlay: Node2D
var stage_postfx_overlay: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if LOCAL_USE_TILE_TEXTURES:
		_load_tile_textures()
	set_process(LOCAL_DYNAMIC_VISUALS_ENABLED)

func _process(delta: float) -> void:
	if not LOCAL_DYNAMIC_VISUALS_ENABLED:
		return
	if not visible or current_mode != "region" or not side_view_stage_enabled:
		return
	stage_visual_phase = fposmod(stage_visual_phase + delta * SIDE_VIEW_AMBIENT_SPEED, 10000.0)
	stage_redraw_accumulator += delta
	if stage_redraw_accumulator < LOCAL_STAGE_REDRAW_INTERVAL:
		return
	stage_redraw_accumulator = fposmod(stage_redraw_accumulator, LOCAL_STAGE_REDRAW_INTERVAL)
	_update_stage_foreground_phase()
	_update_stage_postfx_phase()
	if not _has_native_stage_scene():
		queue_redraw()

func _load_tile_textures() -> void:
	tile_textures.clear()
	for tile_id in TILE_TEXTURE_PATHS.keys():
		var path := str(TILE_TEXTURE_PATHS[tile_id])
		var variants: Array[Texture2D] = []
		var texture := GameData.load_texture(path, true)
		if texture != null:
			variants.append(texture)
		for variant in range(1, TILE_VARIANT_COUNT):
			var variant_path := path.replace(".png", "_v%d.png" % variant)
			var variant_texture := GameData.load_texture(variant_path, true)
			if variant_texture != null:
				variants.append(variant_texture)
		if not variants.is_empty():
			tile_textures[int(tile_id)] = variants

func _load_region_scene_background() -> void:
	scene_background_texture = null
	scene_midground_layer_texture = null
	scene_floor_layer_texture = null
	if LOCAL_PAINTERLY_FORCE_TEXTURELESS_STAGE:
		return
	var region_id := str(current_region.get("id", ""))
	var path := GameData.get_scene_background_path(region_id)
	if not path.is_empty():
		scene_background_texture = GameData.load_texture(path, true)
	var layer_path := GameData.get_stage_layer_path(region_id, "midground")
	if not layer_path.is_empty():
		scene_midground_layer_texture = GameData.load_texture(layer_path, true)
	var floor_layer_path := GameData.get_stage_layer_path(region_id, "floor")
	if not floor_layer_path.is_empty():
		scene_floor_layer_texture = GameData.load_texture(floor_layer_path, true)

func setup_region(region: Dictionary) -> void:
	if LOCAL_USE_TILE_TEXTURES and tile_textures.is_empty():
		_load_tile_textures()
	current_region = region.duplicate(true)
	current_mode = "region"
	side_view_stage_enabled = true
	stage_redraw_accumulator = LOCAL_STAGE_REDRAW_INTERVAL
	active_shop_id = ""
	_load_region_scene_background()
	highlighted_portal_id = ""
	occupied_npc_tiles.clear()
	_clear_npcs()
	_clear_depth_props()
	_clear_portal_labels()
	_configure_region_size()
	_generate_region_map()
	_build_depth_props()
	_update_stage_scene_layer(true)
	_update_stage_postfx_overlay(true)
	_update_stage_foreground_overlay(true)
	_spawn_region_npcs()
	_build_portal_labels()
	_update_title_label()
	queue_redraw()

func enter_shop(portal: Dictionary) -> void:
	if LOCAL_USE_TILE_TEXTURES and tile_textures.is_empty():
		_load_tile_textures()
	var shop_id := str(portal.get("shop_id", ""))
	if not SHOP_DEFINITIONS.has(shop_id):
		return
	active_shop_id = shop_id
	current_mode = "shop"
	side_view_stage_enabled = false
	scene_background_texture = null
	var tile_data: Array = portal.get("tile", [map_width / 2, map_height / 2])
	shop_return_tile = Vector2i(int(tile_data[0]), int(tile_data[1]))
	highlighted_portal_id = ""
	occupied_npc_tiles.clear()
	_clear_npcs()
	_clear_depth_props()
	_hide_stage_scene_layer()
	_hide_stage_postfx_overlay()
	_hide_stage_foreground_overlay()
	_clear_portal_labels()
	_configure_shop_size()
	_generate_shop_map(shop_id)
	_build_depth_props()
	_spawn_shopkeeper(shop_id)
	_build_portal_labels()
	_update_title_label()
	queue_redraw()

func exit_shop() -> Vector2:
	var return_tile := shop_return_tile
	setup_region(current_region)
	return tile_to_world(return_tile + Vector2i(0, 1))

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size * 0.5, tile.y * tile_size + tile_size * 0.5)

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / tile_size), floori(world_position.y / tile_size))

func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_width * tile_size, map_height * tile_size))

func get_actor_depth_scale(world_position: Vector2) -> float:
	if current_mode != "region" or not side_view_stage_enabled:
		return 1.0
	var rect := get_world_rect()
	if rect.size.y <= 0.0:
		return 1.0
	var top_y := rect.size.y * STAGE_DEPTH_TOP_RATIO
	var bottom_y := rect.size.y * STAGE_DEPTH_BOTTOM_RATIO
	var depth := clampf((world_position.y - top_y) / maxf(1.0, bottom_y - top_y), 0.0, 1.0)
	return lerpf(STAGE_DEPTH_MIN_SCALE, STAGE_DEPTH_MAX_SCALE, depth)

func is_side_view_stage_active() -> bool:
	return current_mode == "region" and side_view_stage_enabled

func get_stage_play_lane_y_positions() -> Array[float]:
	if not is_side_view_stage_active():
		return []
	return _stage_play_lane_centers(get_world_rect().size)

func get_stage_lane_anchor(world_position: Vector2) -> Dictionary:
	if not is_side_view_stage_active():
		return {}
	var centers := _stage_play_lane_centers(get_world_rect().size)
	if centers.is_empty():
		return {}
	var best_index := 0
	var best_y := float(centers[0])
	var best_distance := absf(world_position.y - best_y)
	for index in range(1, centers.size()):
		var lane_y := float(centers[index])
		var distance := absf(world_position.y - lane_y)
		if distance < best_distance:
			best_distance = distance
			best_y = lane_y
			best_index = index
	var falloff := maxf(1.0, SIDE_VIEW_LANE_ANCHOR_MAX_DISTANCE - SIDE_VIEW_LANE_ANCHOR_FULL_DISTANCE)
	var strength := 1.0 - maxf(0.0, best_distance - SIDE_VIEW_LANE_ANCHOR_FULL_DISTANCE) / falloff
	return {
		"lane_y": best_y,
		"offset_y": best_y - world_position.y,
		"distance": best_distance,
		"strength": clampf(strength, 0.0, 1.0),
		"index": best_index
	}

func get_stage_actor_facing_side(world_position: Vector2) -> float:
	if not is_side_view_stage_active():
		return 1.0
	return -1.0 if world_position.x > get_world_rect().size.x * 0.5 else 1.0

func get_region_at_world_position(_world_position: Vector2) -> Dictionary:
	return current_region

func get_world_reference_tile(_world_position: Vector2) -> Vector2i:
	var center: Array = current_region.get("center", [])
	if center.size() >= 2:
		return Vector2i(int(center[0]), int(center[1]))
	return Vector2i.ZERO

func get_entry_position(kind: String = "area") -> Vector2:
	if current_mode == "shop":
		return tile_to_world(Vector2i(map_width / 2, map_height - 4))
	if kind == "world":
		return tile_to_world(_find_nearest_walkable_tile(Vector2i(map_width / 2, map_height / 2 + 6)))
	var tile := Vector2i(map_width / 2, map_height / 2)
	match kind:
		"north":
			tile = Vector2i(map_width / 2, 7)
		"south":
			tile = Vector2i(map_width / 2, map_height - 7)
		"east":
			tile = Vector2i(map_width - 8, map_height / 2)
		"west":
			tile = Vector2i(8, map_height / 2)
	return tile_to_world(_find_nearest_walkable_tile(tile))

func is_position_walkable(world_position: Vector2) -> bool:
	return is_tile_walkable(world_to_tile(world_position))

func is_tile_walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_width or tile.y >= map_height:
		return false
	var tile_id := int(tiles[tile.y][tile.x])
	return tile_id != Tile.WATER and tile_id != Tile.BUILDING and tile_id != Tile.SHOP and tile_id != Tile.WALL and tile_id != Tile.COUNTER

func _find_nearest_walkable_tile(preferred: Vector2i) -> Vector2i:
	if is_tile_walkable(preferred):
		return preferred
	for radius in range(1, 12):
		for y in range(preferred.y - radius, preferred.y + radius + 1):
			for x in range(preferred.x - radius, preferred.x + radius + 1):
				if abs(x - preferred.x) != radius and abs(y - preferred.y) != radius:
					continue
				var tile := Vector2i(x, y)
				if is_tile_walkable(tile):
					return tile
	return preferred

func get_nearest_npc(world_position: Vector2, radius: float, include_enemies: bool = true):
	var best = null
	var best_distance := radius
	for actor in npc_nodes:
		if not is_instance_valid(actor):
			continue
		if actor.is_enemy() and not include_enemies:
			continue
		var distance := world_position.distance_to(actor.position)
		if distance <= best_distance:
			best = actor
			best_distance = distance
	return best

func get_nearby_npcs(world_position: Vector2, radius: float, include_enemies: bool = true, limit: int = 6) -> Array:
	var found: Array = []
	for actor in npc_nodes:
		if not is_instance_valid(actor):
			continue
		if actor.is_enemy() and not include_enemies:
			continue
		var distance := world_position.distance_to(actor.position)
		if distance <= radius:
			found.append({
				"actor": actor,
				"distance": distance
			})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
	)
	var result: Array = []
	for entry in found:
		result.append(entry.get("actor"))
		if result.size() >= limit:
			break
	return result

func clear_ambient_lines() -> void:
	for actor in npc_nodes:
		if is_instance_valid(actor) and actor.has_method("clear_ambient_line"):
			actor.clear_ambient_line()

func get_nearest_portal(world_position: Vector2, radius: float) -> Dictionary:
	var best := {}
	var best_distance := radius
	for portal in portals:
		var tile_data: Array = portal.get("tile", [0, 0])
		var pos := tile_to_world(Vector2i(int(tile_data[0]), int(tile_data[1])))
		var distance := world_position.distance_to(pos)
		if distance <= best_distance:
			best = portal
			best_distance = distance
	return best

func focus_portal(portal: Dictionary) -> void:
	var next_id := str(portal.get("id", ""))
	if highlighted_portal_id == next_id:
		return
	highlighted_portal_id = next_id
	for label in portal_labels:
		if not is_instance_valid(label):
			continue
		label.visible = label.name == highlighted_portal_id or current_mode == "shop" or str(label.name).begins_with("shop_") or str(label.name).begins_with("travel_") or str(label.name).begins_with("landmark_") or str(label.name).begins_with("resource_")
	queue_redraw()

func clear_highlights() -> void:
	for actor in npc_nodes:
		if is_instance_valid(actor):
			actor.set_highlight(false)
	focus_portal({})

func focus_actor(actor) -> void:
	for npc in npc_nodes:
		if is_instance_valid(npc):
			npc.set_highlight(npc == actor)

func unregister_npc(actor) -> void:
	npc_nodes.erase(actor)

func _configure_region_size() -> void:
	var region_type := str(current_region.get("type", "wild"))
	match region_type:
		"city":
			map_width = 80
			map_height = 54
		"town":
			map_width = 58
			map_height = 40
		"sect":
			map_width = 64
			map_height = 44
		_:
			map_width = 72
			map_height = 48

func _configure_shop_size() -> void:
	map_width = 28
	map_height = 18

func _reset_tiles(tile_id: int) -> void:
	tiles.clear()
	for y in range(map_height):
		var row: Array = []
		for _x in range(map_width):
			row.append(tile_id)
		tiles.append(row)

func _generate_region_map() -> void:
	portals.clear()
	var region_type := str(current_region.get("type", "wild"))
	match region_type:
		"city":
			_generate_city_region()
		"town":
			_generate_town_region()
		"sect":
			_generate_sect_region()
		_:
			_generate_wild_region()
	_add_exit_portal()
	_add_region_travel_portals()
	_add_landmark_portals()
	_add_resource_portals()

func _generate_city_region() -> void:
	_reset_tiles(Tile.GRASS)
	var profile := _region_profile()
	_fill_rect(Rect2i(5, 5, map_width - 10, map_height - 10), Tile.ROAD)
	_fill_rect(Rect2i(8, 8, map_width - 16, map_height - 16), Tile.GRASS)
	_paint_line([Vector2i(8, map_height / 2), Vector2i(map_width - 9, map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(map_width / 2, 8), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(14, 14), Vector2i(map_width - 14, map_height - 14)], Tile.ROAD, 1)
	_paint_city_street_grid(profile)
	_fill_rect(Rect2i(11, 10, 14, 8), Tile.GARDEN)
	_fill_rect(Rect2i(map_width - 27, 10, 16, 9), Tile.GARDEN if bool(profile.get("garden_city", false)) else Tile.BUILDING)
	_fill_rect(Rect2i(12, map_height - 20, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 27, map_height - 20, 15, 8), Tile.BUILDING)
	_place_shops(_shop_plan_for_region())
	_apply_city_identity(profile)

func _paint_city_street_grid(profile: Dictionary) -> void:
	for y in range(14, map_height - 12, 9):
		var offset := 1 if int(y / 9) % 2 == 0 else -2
		_paint_line([Vector2i(10, y), Vector2i(map_width / 2 - 7, y + offset), Vector2i(map_width - 11, y)], Tile.ROAD, 1)
	for x in range(17, map_width - 13, 13):
		var offset := 2 if int(x / 13) % 2 == 0 else -1
		_paint_line([Vector2i(x, 9), Vector2i(x + offset, map_height / 2 - 4), Vector2i(x, map_height - 9)], Tile.ROAD, 1)
	var district_tiles := [Tile.BUILDING, Tile.SHOP, Tile.GARDEN if bool(profile.get("garden_city", false)) else Tile.BUILDING]
	for index in range(6):
		var x := 11 + (index % 3) * 21
		var y := 11 + int(index / 3) * (map_height - 25)
		var tile_id: int = district_tiles[index % district_tiles.size()]
		_fill_rect(Rect2i(clampi(x, 10, map_width - 18), clampi(y, 10, map_height - 15), 9 + index % 2 * 3, 5), tile_id)
		_fill_rect(Rect2i(clampi(x + 2, 11, map_width - 16), clampi(y + 5, 12, map_height - 10), 4, 2), Tile.ROAD)

func _generate_town_region() -> void:
	var terrain := str(current_region.get("terrain", ""))
	var region_id := str(current_region.get("id", ""))
	_reset_tiles(Tile.FIELD)
	_fill_rect(Rect2i(4, 5, map_width - 8, map_height - 10), Tile.GRASS)
	_paint_line([Vector2i(4, map_height / 2), Vector2i(map_width - 5, map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(map_width / 2, 7), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 1)
	_paint_line([Vector2i(8, map_height - 9), Vector2i(map_width / 2 - 8, map_height / 2 + 3), Vector2i(map_width - 8, 10)], Tile.ROAD, 1)
	_fill_rect(Rect2i(map_width / 2 - 5, map_height / 2 - 3, 10, 6), Tile.ROAD)
	_fill_rect(Rect2i(7, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 19, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(8, map_height - 16, 14, 7), Tile.FIELD)
	_paint_town_hamlet_details(region_id, terrain)
	_place_shops(_shop_plan_for_region())
	_apply_town_identity()

func _paint_town_hamlet_details(region_id: String, terrain: String) -> void:
	for index in range(4):
		var x := 8 + (index % 2) * (map_width - 24)
		var y := 8 + int(index / 2) * (map_height - 22)
		_fill_rect(Rect2i(x, y, 7, 4), Tile.BUILDING)
		_fill_rect(Rect2i(x + 2, y + 4, 3, 2), Tile.ROAD)
	if region_id == "qinghe" or terrain.contains("starter"):
		_fill_rect(Rect2i(9, map_height / 2 + 6, 8, 5), Tile.GARDEN)
		_fill_rect(Rect2i(map_width - 18, map_height / 2 + 5, 10, 6), Tile.FIELD)
		_paint_line([Vector2i(10, map_height / 2 + 8), Vector2i(map_width / 2 - 8, map_height / 2 + 5)], Tile.ROAD, 1)
	elif terrain.contains("bath") or terrain.contains("spring"):
		_fill_rect(Rect2i(map_width - 18, map_height / 2 + 4, 10, 5), Tile.WATER)
		_fill_rect(Rect2i(map_width - 15, map_height / 2 + 5, 4, 2), Tile.BRIDGE)
	else:
		_fill_rect(Rect2i(map_width / 2 + 9, map_height - 13, 12, 6), Tile.FIELD)
		_fill_rect(Rect2i(8, map_height - 13, 9, 5), Tile.GARDEN)

func _generate_sect_region() -> void:
	_reset_tiles(Tile.GRASS)
	_fill_rect(Rect2i(7, 6, map_width - 14, map_height - 12), Tile.GARDEN)
	_paint_line([Vector2i(map_width / 2, 6), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(12, map_height / 2), Vector2i(map_width - 13, map_height / 2)], Tile.ROAD, 1)
	_fill_rect(Rect2i(map_width / 2 - 7, 8, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(12, map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 24, map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_apply_sect_identity()
	_place_shops(["medicine", "market"])

func _apply_sect_identity() -> void:
	var region_id := str(current_region.get("id", ""))
	var terrain := str(current_region.get("terrain", ""))
	_fill_rect(Rect2i(map_width / 2 - 9, map_height / 2 + 5, 18, 7), Tile.ROAD)
	if region_id == "flower_sect" or terrain.contains("flower"):
		_fill_rect(Rect2i(9, 8, 12, 9), Tile.GARDEN)
		_fill_rect(Rect2i(map_width - 22, map_height - 17, 12, 8), Tile.GARDEN)
		_paint_line([Vector2i(map_width - 11, 12), Vector2i(map_width / 2 + 8, map_height / 2 - 3)], Tile.ROAD, 1)
	elif region_id == "xueshan_sect" or terrain.contains("snow"):
		_fill_rect(Rect2i(8, 7, 14, 8), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 22, 8, 13, 8), Tile.MOUNTAIN)
		_paint_line([Vector2i(9, map_height - 10), Vector2i(map_width / 2 - 6, map_height / 2 + 8)], Tile.ROAD, 1)
	elif region_id == "xiaoyao_sect" or terrain.contains("lake"):
		_paint_line([Vector2i(10, map_height - 12), Vector2i(map_width / 2, map_height - 16), Vector2i(map_width - 10, map_height - 11)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(map_width / 2, map_height - 15))
	elif region_id == "honglian_sect":
		_fill_rect(Rect2i(map_width / 2 - 17, map_height / 2 - 10, 8, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width / 2 + 9, map_height / 2 - 10, 8, 6), Tile.MOUNTAIN)
	elif region_id == "naja_sect":
		_paint_line([Vector2i(8, 11), Vector2i(map_width / 2 - 7, map_height / 2 - 2), Vector2i(map_width - 9, 13)], Tile.ROAD, 1)
		_fill_rect(Rect2i(9, map_height - 15, 11, 7), Tile.MOUNTAIN)
	elif region_id == "taiji_sect" or terrain.contains("daoist"):
		_fill_rect(Rect2i(map_width / 2 - 12, map_height / 2 - 12, 24, 5), Tile.ROAD)
		_fill_rect(Rect2i(map_width / 2 - 12, map_height / 2 + 12, 24, 4), Tile.GARDEN)
	else:
		_fill_rect(Rect2i(10, map_height - 14, 12, 7), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 22, map_height - 14, 12, 7), Tile.GARDEN)

func _generate_wild_region() -> void:
	var terrain := str(current_region.get("terrain", "plain"))
	var base := Tile.GRASS
	if _terrain_has_water(terrain):
		base = Tile.GRASS
	elif terrain.contains("desert"):
		base = Tile.FIELD
	elif terrain.contains("plateau"):
		base = Tile.FIELD
	_reset_tiles(base)
	_paint_line([Vector2i(5, map_height / 2), Vector2i(map_width / 2, map_height / 2 - 3), Vector2i(map_width - 6, map_height / 2 + 2)], Tile.ROAD, 1)
	_apply_wild_identity(terrain)
	_fill_rect(Rect2i(map_width / 2 - 4, map_height / 2 - 8, 8, 5), Tile.BUILDING)
	_add_portal("wild_rest", "驿亭", "look", Vector2i(map_width / 2, map_height / 2 - 2), "")

func _apply_wild_identity(terrain: String) -> void:
	if _terrain_has_water(terrain):
		_paint_line([Vector2i(0, 14), Vector2i(map_width / 3, 18), Vector2i(map_width / 2, 16), Vector2i(map_width, 13)], Tile.WATER, 2)
		_paint_line([Vector2i(map_width / 2 + 9, 0), Vector2i(map_width / 2 + 6, 18), Vector2i(map_width / 2 + 12, map_height - 5)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(map_width / 2, 17))
		_set_bridge_patch(Vector2i(map_width / 2 + 9, map_height / 2 + 1))
		if terrain.contains("marsh"):
			_fill_rect(Rect2i(9, map_height - 15, 14, 8), Tile.GARDEN)
			_fill_rect(Rect2i(map_width - 22, 8, 13, 8), Tile.GARDEN)
	elif _terrain_has_forest(terrain):
		_fill_rect(Rect2i(7, 8, 14, 9), Tile.GARDEN)
		_fill_rect(Rect2i(map_width - 24, map_height - 16, 14, 9), Tile.GARDEN)
		_fill_rect(Rect2i(map_width / 2 + 9, 8, 12, 8), Tile.GARDEN)
		_paint_line([Vector2i(10, 12), Vector2i(map_width / 2, map_height / 2 - 4), Vector2i(map_width - 15, map_height - 12)], Tile.ROAD, 1)
	elif terrain.contains("desert"):
		_fill_rect(Rect2i(8, 8, 10, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 20, map_height - 13, 10, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width / 2 + 12, 10, 12, 5), Tile.FIELD)
		_paint_line([Vector2i(8, map_height - 10), Vector2i(map_width / 2 - 8, map_height / 2 + 6)], Tile.ROAD, 1)
	elif _terrain_has_mountain(terrain):
		_fill_rect(Rect2i(6, 6, 14, 8), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 22, 7, 14, 9), Tile.MOUNTAIN)
		_fill_rect(Rect2i(10, map_height - 14, 12, 7), Tile.MOUNTAIN)
		_paint_line([Vector2i(map_width / 2 - 15, 9), Vector2i(map_width / 2 + 8, map_height / 2 - 6), Vector2i(map_width - 11, map_height - 10)], Tile.ROAD, 1)
	else:
		_fill_rect(Rect2i(8, 8, 13, 7), Tile.FIELD)
		_fill_rect(Rect2i(map_width - 23, 9, 14, 7), Tile.FIELD)
		_fill_rect(Rect2i(10, map_height - 15, 12, 7), Tile.GARDEN)
		_paint_line([Vector2i(9, 12), Vector2i(map_width / 2 - 9, map_height / 2 + 5)], Tile.ROAD, 1)

func _apply_city_identity(profile: Dictionary) -> void:
	var region_id := str(current_region.get("id", ""))
	if bool(profile.get("water_city", false)):
		_paint_line([Vector2i(9, 20), Vector2i(26, 22), Vector2i(52, 20), Vector2i(map_width - 9, 23)], Tile.WATER, 1)
		_paint_line([Vector2i(24, 8), Vector2i(25, 27), Vector2i(22, map_height - 9)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(map_width / 2, 21))
		_set_bridge_patch(Vector2i(24, map_height / 2))
	elif region_id == "jiangling":
		_paint_line([Vector2i(4, 34), Vector2i(24, 32), Vector2i(48, 34), Vector2i(map_width - 4, 31)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(map_width / 2, 33))
		_set_bridge_patch(Vector2i(map_width - 17, 32))
	elif region_id == "chengdu":
		_fill_rect(Rect2i(9, 9, 14, 10), Tile.GARDEN)
		_fill_rect(Rect2i(map_width - 25, map_height - 21, 13, 9), Tile.FIELD)
		_fill_rect(Rect2i(map_width / 2 - 18, 9, 12, 7), Tile.GARDEN)
	elif region_id == "changan":
		_fill_rect(Rect2i(map_width / 2 - 4, 9, 8, 10), Tile.BUILDING)
		_paint_line([Vector2i(map_width / 2, 10), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 3)
	elif region_id == "luoyang":
		_fill_rect(Rect2i(map_width / 2 - 9, map_height / 2 - 6, 18, 12), Tile.ROAD)
		_fill_rect(Rect2i(map_width / 2 - 13, map_height / 2 - 10, 6, 5), Tile.SHOP)
		_fill_rect(Rect2i(map_width / 2 + 7, map_height / 2 + 5, 6, 5), Tile.SHOP)

func _apply_town_identity() -> void:
	var terrain := str(current_region.get("terrain", ""))
	if _terrain_has_water(terrain):
		_paint_line([Vector2i(5, map_height / 2 - 7), Vector2i(map_width / 2, map_height / 2 - 5), Vector2i(map_width - 5, map_height / 2 - 8)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(map_width / 2, map_height / 2 - 6))
	elif terrain.contains("garden") or terrain.contains("field") or terrain.contains("plain"):
		_fill_rect(Rect2i(7, map_height - 15, 14, 8), Tile.FIELD)
		_fill_rect(Rect2i(map_width - 21, map_height - 15, 13, 8), Tile.GARDEN)
	elif terrain.contains("mound") or terrain.contains("mountain") or terrain.contains("gorge"):
		_fill_rect(Rect2i(6, 6, 11, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 17, map_height - 13, 10, 6), Tile.MOUNTAIN)

func _terrain_has_water(terrain: String) -> bool:
	return terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("waterway") or terrain.contains("canal") or terrain.contains("ford") or terrain.contains("tide") or terrain.contains("weir") or terrain.contains("marsh") or terrain.contains("spring")

func _terrain_has_mountain(terrain: String) -> bool:
	return terrain.contains("mountain") or terrain.contains("peak") or terrain.contains("cliff") or terrain.contains("gorge") or terrain.contains("plateau") or terrain.contains("valley")

func _terrain_has_forest(terrain: String) -> bool:
	return terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden") or terrain.contains("field")

func _set_bridge_patch(center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 2, center.x + 3):
			_set_tile(x, y, Tile.BRIDGE)

func _place_shops(shop_ids: Array) -> void:
	var positions := [
		Vector2i(14, 15),
		Vector2i(map_width - 15, 15),
		Vector2i(14, map_height - 15),
		Vector2i(map_width - 15, map_height - 15),
		Vector2i(map_width / 2 - 9, 12),
		Vector2i(map_width / 2 + 10, map_height - 13)
	]
	for index in range(min(shop_ids.size(), positions.size())):
		_add_shop(str(shop_ids[index]), positions[index])

func _add_shop(shop_id: String, door_tile: Vector2i) -> void:
	if not SHOP_DEFINITIONS.has(shop_id):
		return
	_fill_rect(Rect2i(door_tile.x - 4, door_tile.y - 5, 8, 5), Tile.SHOP)
	_fill_rect(Rect2i(door_tile.x - 2, door_tile.y - 1, 4, 2), Tile.ROAD)
	var shop: Dictionary = SHOP_DEFINITIONS[shop_id]
	_add_portal("shop_%s_%d_%d" % [shop_id, door_tile.x, door_tile.y], "进入%s" % str(shop.get("name", "商铺")), "shop", door_tile, shop_id)

func _add_exit_portal() -> void:
	_paint_line([Vector2i(map_width / 2, map_height - 8), Vector2i(map_width / 2, map_height - 2)], Tile.ROAD, 2)
	_add_portal("exit_world", "返回世界", "exit_world", Vector2i(map_width / 2, map_height - 4), "")

func _add_landmark_portals() -> void:
	var landmarks := _landmarks_for_region()
	for index in range(landmarks.size()):
		var landmark: Dictionary = landmarks[index]
		var tile: Vector2i = landmark.get("tile", _landmark_tile(index))
		tile = _find_nearest_walkable_tile(tile)
		_paint_landmark_site(tile, str(landmark.get("kind", "notice")))
		var portal := {
			"id": "landmark_%s_%d" % [str(current_region.get("id", "region")), index],
			"label": str(landmark.get("label", "地标")),
			"type": "landmark",
			"tile": [tile.x, tile.y],
			"shop_id": "",
			"description": str(landmark.get("description", "")),
			"reward_item": str(landmark.get("reward_item", "")),
			"reward_money": int(landmark.get("reward_money", 0)),
			"reward_exp": int(landmark.get("reward_exp", 0)),
			"landmark_kind": str(landmark.get("kind", "notice"))
		}
		portals.append(portal)

func _add_resource_portals() -> void:
	var resources := _resources_for_region()
	for index in range(resources.size()):
		var resource: Dictionary = resources[index]
		var tile: Vector2i = resource.get("tile", _resource_tile(index))
		tile = _find_nearest_walkable_tile(tile)
		_paint_resource_site(tile, str(resource.get("kind", "cache")))
		portals.append({
			"id": "resource_%s_%d" % [str(current_region.get("id", "region")), index],
			"label": str(resource.get("label", "资源点")),
			"type": "resource",
			"tile": [tile.x, tile.y],
			"shop_id": "",
			"description": str(resource.get("description", "这里有一点可用的物资。")),
			"depleted_description": str(resource.get("depleted_description", "这里今日已经搜寻过，明日再来或许会有新的收获。")),
			"reward_item": str(resource.get("reward_item", "")),
			"reward_count": int(resource.get("reward_count", 1)),
			"reward_money": int(resource.get("reward_money", 0)),
			"reward_exp": int(resource.get("reward_exp", 0)),
			"resource_kind": str(resource.get("kind", "cache"))
		})

func _resources_for_region() -> Array:
	var region_type := str(current_region.get("type", "wild"))
	var terrain := str(current_region.get("terrain", ""))
	var resources: Array = []
	if region_type == "city":
		resources.append({"label": "街边食盒", "description": "街边摊贩收摊前分你一份热食。", "kind": "cache", "tile": Vector2i(map_width / 2 - 18, map_height / 2 + 8), "reward_item": "item_baozi"})
		resources.append({"label": "武馆药罐", "description": "武馆药罐里还有一点跌打药粉。", "kind": "herb", "tile": Vector2i(map_width / 2 + 16, map_height / 2 - 8), "reward_item": "item_yao"})
	elif region_type == "town":
		resources.append({"label": "田埂药草", "description": "田埂边长着几株常见药草，适合初行江湖的人练手采摘。", "kind": "herb", "tile": Vector2i(map_width - 12, map_height - 10), "reward_item": "item_red_flower"})
		resources.append({"label": "茶棚食盒", "description": "茶棚老板见你赶路，塞给你一个热包子。", "kind": "cache", "tile": Vector2i(12, map_height / 2 + 7), "reward_item": "item_baozi"})
	elif region_type == "sect":
		resources.append({"label": "练功药罐", "description": "演武坪旁备着跌打药，弟子们用后会及时补上。", "kind": "herb", "tile": Vector2i(map_width / 2 - 12, map_height / 2 + 9), "reward_item": "item_yao"})
		resources.append({"label": "香案供钱", "description": "香案上有几枚散钱，知客让你拿去添置路粮。", "kind": "coin", "tile": Vector2i(map_width / 2 + 12, 13), "reward_money": 3})
	else:
		resources.append({"label": "野草药坡", "description": "路边药坡长着几株常见药草。", "kind": "herb", "tile": Vector2i(12, 13), "reward_item": "item_red_flower"})
		resources.append({"label": "破棚食盒", "description": "破棚木桌下有个食盒，里面还有一个包子。", "kind": "cache", "tile": Vector2i(map_width / 2 - 8, map_height / 2 + 9), "reward_item": "item_baozi"})

	if _terrain_has_water(terrain):
		resources.append({"label": "河边鱼篓", "description": "河边鱼篓压在水草旁，里面还有一尾活鱼。", "kind": "fish", "tile": Vector2i(map_width - 12, map_height / 2 - 7), "reward_item": "item_fish"})
	elif _terrain_has_mountain(terrain):
		resources.append({"label": "山壁矿点", "description": "山壁露出一点矿脉，虽然不能锻成兵器，也能换些银两。", "kind": "ore", "tile": Vector2i(map_width - 13, 12), "reward_money": 5})
	elif _terrain_has_forest(terrain):
		resources.append({"label": "林下药草", "description": "林下潮湿，药草长得比镇外更好。", "kind": "herb", "tile": Vector2i(13, 13), "reward_item": "item_red_flower"})
	elif terrain.contains("desert") or terrain.contains("plateau"):
		resources.append({"label": "沙下旧钱", "description": "黄沙里露出铜色边角，拨开后找到几枚旧钱。", "kind": "coin", "tile": Vector2i(map_width - 16, map_height - 12), "reward_money": 5})
	return resources

func _landmarks_for_region() -> Array:
	var region_type := str(current_region.get("type", "wild"))
	var region_id := str(current_region.get("id", ""))
	var terrain := str(current_region.get("terrain", ""))
	match region_type:
		"city":
			return _city_landmarks(region_id)
		"town":
			return _town_landmarks(region_id, terrain)
		"sect":
			return _sect_landmarks(region_id)
		_:
			return _wild_landmarks(terrain)

func _city_landmarks(region_id: String) -> Array:
	match region_id:
		"luoyang":
			return [
				{"label": "苏家旧宅", "description": "墙根还有焦黑旧痕，洛阳旧火的线索并没有被岁月完全抹去。", "kind": "ruin", "tile": Vector2i(map_width / 2 - 15, map_height / 2 + 7), "reward_exp": 8},
				{"label": "天街武馆", "description": "木人桩排在院中，来往侠少在这里试拳脚。", "kind": "training", "tile": Vector2i(map_width / 2 + 16, map_height / 2 - 8), "reward_exp": 6}
			]
		"changan":
			return [
				{"label": "朱雀榜亭", "description": "榜文半新半旧，暗影司与朝廷密令的传闻混在市井闲谈里。", "kind": "notice", "tile": Vector2i(map_width / 2, 16), "reward_money": 4},
				{"label": "西市货栈", "description": "胡商、镖客和江湖客都在这里换消息。", "kind": "market", "tile": Vector2i(17, map_height / 2 + 10), "reward_item": "item_wine"}
			]
		"linan":
			return [
				{"label": "画舫码头", "description": "水雾贴着河面，船娘唱词里夹着花间旧事。", "kind": "dock", "tile": Vector2i(24, map_height / 2 + 6), "reward_item": "item_fish"},
				{"label": "烟雨廊桥", "description": "桥下水声不断，适合听风，也适合藏信。", "kind": "bridge", "tile": Vector2i(map_width / 2 + 12, 20), "reward_exp": 6}
			]
		"chengdu":
			return [
				{"label": "药市竹园", "description": "药香混着竹叶清气，巴蜀商贩在这里分拣药草。", "kind": "herb", "tile": Vector2i(17, 18), "reward_item": "item_yao"},
				{"label": "都江渠眼", "description": "水脉分流，老工匠说这里藏着天府气运。", "kind": "water", "tile": Vector2i(map_width - 20, map_height / 2 + 8), "reward_exp": 7}
			]
		"jiangling":
			return [
				{"label": "江防码头", "description": "战船旧缆还系在岸边，荆楚水路的消息从这里上岸。", "kind": "dock", "tile": Vector2i(map_width - 18, map_height / 2 + 9), "reward_item": "item_fish"},
				{"label": "旧战鼓台", "description": "鼓面龟裂，仍能想见当年兵家重镇的声势。", "kind": "training", "tile": Vector2i(18, map_height / 2 - 8), "reward_exp": 8}
			]
	return [
		{"label": "府衙告示", "description": "城中近来案牍渐多，江湖事也开始上了官府文书。", "kind": "notice", "tile": Vector2i(map_width / 2, 15), "reward_money": 3},
		{"label": "城中武馆", "description": "武馆开门纳客，门口木牌写着切磋点到为止。", "kind": "training", "tile": Vector2i(map_width - 18, map_height / 2), "reward_exp": 5}
	]

func _town_landmarks(region_id: String, terrain: String) -> Array:
	var result: Array = [
		{"label": "镇口告示", "description": "告示上写着近路、盗匪和失物，许多小任务会从这里冒头。", "kind": "notice", "tile": Vector2i(map_width / 2 - 9, 10), "reward_money": 2},
		{"label": "练武空场", "description": "空场地面被脚步磨亮，是镇上年轻人练拳脚的地方。", "kind": "training", "tile": Vector2i(map_width / 2 + 13, map_height / 2 + 7), "reward_exp": 4}
	]
	if region_id == "qinghe":
		result.append({"label": "老井茶棚", "description": "井水清冽，茶棚边常有赶路人歇脚。", "kind": "well", "tile": Vector2i(11, map_height / 2 + 8), "reward_item": "item_baozi"})
	elif _terrain_has_water(terrain):
		result.append({"label": "渡口鱼篓", "description": "渡口边搁着鱼篓，船家不介意你拿一尾小鱼充饥。", "kind": "dock", "tile": Vector2i(map_width - 11, map_height / 2 - 6), "reward_item": "item_fish"})
	elif terrain.contains("mound") or terrain.contains("bath"):
		result.append({"label": "旧碑残台", "description": "风化的碑文只剩几行，隐约提到一条古道。", "kind": "ruin", "tile": Vector2i(10, 10), "reward_exp": 5})
	else:
		result.append({"label": "田边药草", "description": "田埂旁长着几株常见药草，采下可作外伤药引。", "kind": "herb", "tile": Vector2i(map_width - 12, map_height - 11), "reward_item": "item_red_flower"})
	return result

func _sect_landmarks(region_id: String) -> Array:
	var sect_name := str(current_region.get("name", region_id))
	return [
		{"label": "演武坪", "description": "%s弟子在此晨练，步伐与呼吸自成章法。" % sect_name, "kind": "training", "tile": Vector2i(map_width / 2, map_height / 2 + 8), "reward_exp": 8},
		{"label": "祖师碑", "description": "碑前香灰未冷，门派戒律和前人名号刻得很深。", "kind": "shrine", "tile": Vector2i(map_width / 2, 12), "reward_exp": 6}
	]

func _wild_landmarks(terrain: String) -> Array:
	if _terrain_has_water(terrain):
		return [
			{"label": "浅滩鱼影", "description": "水草摇动，能看见几尾鱼贴着浅滩游过。", "kind": "water", "tile": Vector2i(map_width / 2 + 10, 17), "reward_item": "item_fish"},
			{"label": "河岸旧桩", "description": "旧木桩上有刀痕，像是有人在此等过船。", "kind": "dock", "tile": Vector2i(map_width / 2 - 12, 20), "reward_exp": 5}
		]
	if terrain.contains("mountain") or terrain.contains("peak") or terrain.contains("cliff") or terrain.contains("gorge") or terrain.contains("plateau"):
		return [
			{"label": "山壁石洞", "description": "洞口冷风外涌，石缝里藏着前人留下的伤药。", "kind": "cave", "tile": Vector2i(map_width - 15, 13), "reward_item": "item_yao"},
			{"label": "观云石台", "description": "站在石台上能远望山势，胸中郁气也散了些。", "kind": "ruin", "tile": Vector2i(15, map_height / 2 - 8), "reward_exp": 7}
		]
	if terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden"):
		return [
			{"label": "林下药坡", "description": "潮湿树影下生着药草，采摘时要避开毒虫。", "kind": "herb", "tile": Vector2i(13, 13), "reward_item": "item_red_flower"},
			{"label": "竹影小径", "description": "竹影斜落，风一吹像有许多人低声说话。", "kind": "shrine", "tile": Vector2i(map_width - 18, map_height - 13), "reward_exp": 6}
		]
	if terrain.contains("desert"):
		return [
			{"label": "古驿残碑", "description": "风沙掩住半截碑座，碑后压着几枚旧钱。", "kind": "ruin", "tile": Vector2i(16, 13), "reward_money": 8},
			{"label": "枯井营火", "description": "有人在枯井边宿过夜，灰烬尚有余温。", "kind": "well", "tile": Vector2i(map_width - 17, map_height - 13), "reward_item": "item_baozi"}
		]
	return [
		{"label": "野外茶棚", "description": "破旧茶棚还能遮风，木桌上刻着过路人的名字。", "kind": "well", "tile": Vector2i(map_width / 2 - 8, map_height / 2 + 8), "reward_item": "item_baozi"},
		{"label": "路边石龛", "description": "石龛里压着一张褪色黄符，像是在镇路。", "kind": "shrine", "tile": Vector2i(map_width / 2 + 14, map_height / 2 - 9), "reward_exp": 5}
	]

func _landmark_tile(index: int) -> Vector2i:
	var anchors := [
		Vector2i(map_width / 2 - 14, map_height / 2 - 9),
		Vector2i(map_width / 2 + 14, map_height / 2 + 9),
		Vector2i(12, map_height / 2 + 6),
		Vector2i(map_width - 13, map_height / 2 - 6)
	]
	return anchors[index % anchors.size()]

func _resource_tile(index: int) -> Vector2i:
	var anchors := [
		Vector2i(12, 12),
		Vector2i(map_width - 13, map_height - 11),
		Vector2i(map_width / 2 + 15, 13),
		Vector2i(map_width / 2 - 14, map_height - 12)
	]
	return anchors[index % anchors.size()]

func _paint_landmark_site(tile: Vector2i, kind: String) -> void:
	_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 5, 3), Tile.ROAD)
	match kind:
		"herb":
			_fill_rect(Rect2i(tile.x - 3, tile.y - 2, 6, 4), Tile.GARDEN)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		"training":
			_fill_rect(Rect2i(tile.x - 3, tile.y - 2, 7, 4), Tile.ROAD)
		"dock", "water", "bridge":
			_set_bridge_patch(tile)
		"ruin", "cave", "shrine":
			_fill_rect(Rect2i(tile.x - 3, tile.y - 2, 6, 4), Tile.MOUNTAIN if kind == "cave" else Tile.ROAD)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		"market":
			_fill_rect(Rect2i(tile.x - 3, tile.y - 2, 6, 4), Tile.SHOP)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		_:
			_set_tile(tile.x, tile.y, Tile.ROAD)

func _paint_resource_site(tile: Vector2i, kind: String) -> void:
	match kind:
		"herb", "flower":
			_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 4, 3), Tile.GARDEN)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		"fish":
			_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 5, 3), Tile.BRIDGE)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		"ore":
			_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 4, 3), Tile.MOUNTAIN)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		_:
			_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 4, 3), Tile.ROAD)

func _add_region_travel_portals() -> void:
	var region_id := str(current_region.get("id", ""))
	if region_id.is_empty():
		return
	var neighbors: Array = GameData.get_neighbor_regions(region_id, _travel_portal_limit())
	var direction_counts := {
		"north": 0,
		"south": 0,
		"east": 0,
		"west": 0
	}
	for neighbor in neighbors:
		if typeof(neighbor) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = neighbor
		var target_id := str(target.get("id", ""))
		if target_id.is_empty():
			continue
		var direction := _direction_to_region(target)
		var direction_index := int(direction_counts.get(direction, 0))
		direction_counts[direction] = direction_index + 1
		var tile := _travel_portal_tile(direction, direction_index)
		_paint_travel_path(tile, direction)
		_add_portal(
			"travel_%s" % target_id,
			"前往%s" % str(target.get("name", target_id)),
			"travel_region",
			tile,
			"",
			target_id,
			_opposite_direction(direction)
		)

func _travel_portal_limit() -> int:
	var region_type := str(current_region.get("type", "wild"))
	if region_type == "city":
		return 5
	if region_type == "wild":
		return 3
	return 4

func _direction_to_region(target: Dictionary) -> String:
	var source_center := _region_center(current_region)
	var target_center := _region_center(target)
	var delta := target_center - source_center
	if absf(delta.x) > absf(delta.y):
		return "east" if delta.x >= 0.0 else "west"
	return "south" if delta.y >= 0.0 else "north"

func _travel_portal_tile(direction: String, index: int) -> Vector2i:
	var offset := (index % 3 - 1) * 7
	match direction:
		"north":
			return Vector2i(clampi(map_width / 2 + offset, 8, map_width - 9), 6)
		"south":
			return Vector2i(clampi(map_width / 2 + offset, 8, map_width - 9), map_height - 6)
		"east":
			return Vector2i(map_width - 6, clampi(map_height / 2 + offset, 8, map_height - 9))
		"west":
			return Vector2i(6, clampi(map_height / 2 + offset, 8, map_height - 9))
	return Vector2i(map_width / 2, map_height - 6)

func _paint_travel_path(tile: Vector2i, direction: String) -> void:
	var inner := Vector2i(map_width / 2, map_height / 2)
	match direction:
		"north":
			inner = Vector2i(tile.x, min(tile.y + 8, map_height / 2))
		"south":
			inner = Vector2i(tile.x, max(tile.y - 8, map_height / 2))
		"east":
			inner = Vector2i(max(tile.x - 8, map_width / 2), tile.y)
		"west":
			inner = Vector2i(min(tile.x + 8, map_width / 2), tile.y)
	_paint_line([tile, inner, Vector2i(map_width / 2, map_height / 2)], Tile.ROAD, 1)
	_fill_rect(Rect2i(tile.x - 2, tile.y - 1, 5, 3), Tile.ROAD)

func _opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"
		"south":
			return "north"
		"east":
			return "west"
		"west":
			return "east"
	return "area"

func _region_center(region: Dictionary) -> Vector2:
	var center_data: Array = region.get("center", [])
	if center_data.size() >= 2:
		return Vector2(float(center_data[0]), float(center_data[1]))
	return Vector2.ZERO

func _add_portal(id: String, label: String, kind: String, tile: Vector2i, shop_id: String, target_region_id: String = "", entry_kind: String = "") -> void:
	var portal := {
		"id": id,
		"label": label,
		"type": kind,
		"tile": [tile.x, tile.y],
		"shop_id": shop_id
	}
	if not target_region_id.is_empty():
		portal["target_region_id"] = target_region_id
	if not entry_kind.is_empty():
		portal["entry_kind"] = entry_kind
	portals.append(portal)

func _generate_shop_map(shop_id: String) -> void:
	portals.clear()
	_reset_tiles(Tile.FLOOR)
	_fill_rect(Rect2i(0, 0, map_width, 1), Tile.WALL)
	_fill_rect(Rect2i(0, map_height - 1, map_width, 1), Tile.WALL)
	_fill_rect(Rect2i(0, 0, 1, map_height), Tile.WALL)
	_fill_rect(Rect2i(map_width - 1, 0, 1, map_height), Tile.WALL)
	_fill_rect(Rect2i(5, 4, map_width - 10, 3), Tile.COUNTER)
	_fill_rect(Rect2i(4, 8, 5, 5), Tile.CARPET)
	_fill_rect(Rect2i(map_width - 9, 8, 5, 5), Tile.CARPET)
	if shop_id == "blacksmith":
		_fill_rect(Rect2i(4, 4, 4, 4), Tile.WALL)
	elif shop_id == "medicine":
		_fill_rect(Rect2i(map_width - 8, 4, 4, 4), Tile.GARDEN)
	elif shop_id == "inn":
		_fill_rect(Rect2i(4, 10, 6, 3), Tile.COUNTER)
		_fill_rect(Rect2i(map_width - 10, 10, 6, 3), Tile.COUNTER)
	_add_portal("exit_area", "出门", "exit_area", Vector2i(map_width / 2, map_height - 3), "")

func _spawn_region_npcs() -> void:
	var region_id := str(current_region.get("id", ""))
	if region_id.is_empty():
		return
	var placed := 0
	occupied_npc_tiles.clear()
	for npc_data in GameData.get_npcs():
		var tile := Vector2i(int(npc_data.get("pos_x", -1)), int(npc_data.get("pos_y", -1)))
		var region := GameData.get_region_at_tile(tile)
		if str(region.get("id", "")) != region_id:
			continue
		var local_data: Dictionary = npc_data.duplicate(true)
		var local_tile := _local_npc_tile(local_data, placed)
		local_data["pos_x"] = local_tile.x
		local_data["pos_y"] = local_tile.y
		_spawn_npc(local_data)
		placed += 1
		if placed >= 14:
			break

func _spawn_shopkeeper(shop_id: String) -> void:
	var shop: Dictionary = SHOP_DEFINITIONS.get(shop_id, {})
	if shop.is_empty():
		return
	var keeper := {
		"id": 9300 + _shop_index(shop_id),
		"name": str(shop.get("keeper", "掌柜")),
		"npc_type": "normal",
		"faction": "none",
		"description": str(shop.get("description", "")),
		"personality": "精明、热情",
		"pos_x": map_width / 2,
		"pos_y": 6,
		"shop_name": str(shop.get("name", "商铺")),
		"shop_type": shop_id,
		"sell_items": shop.get("sell_items", []),
		"teach_skills": [],
		"can_rest": bool(shop.get("can_rest", false)),
		"use_map_sprite": true,
		"appearance": {
			"accent": _color_to_array(shop.get("accent", Color(0.86, 0.66, 0.34)))
		}
	}
	occupied_npc_tiles.clear()
	_spawn_npc(keeper)

func _shop_index(shop_id: String) -> int:
	var keys := SHOP_DEFINITIONS.keys()
	for index in range(keys.size()):
		if str(keys[index]) == shop_id:
			return index
	return 0

func _spawn_npc(npc_data: Dictionary) -> void:
	if current_mode == "region" and side_view_stage_enabled:
		var tile := Vector2i(int(npc_data.get("pos_x", map_width / 2)), int(npc_data.get("pos_y", map_height / 2)))
		var world_position := tile_to_world(tile)
		npc_data["map_actor_scale"] = get_actor_depth_scale(world_position) * LOCAL_NPC_SCALE
		npc_data["stage_actor"] = true
		npc_data["stage_facing_side"] = get_stage_actor_facing_side(world_position)
		var anchor := get_stage_lane_anchor(world_position)
		if not anchor.is_empty():
			npc_data["stage_lane_y"] = float(anchor.get("lane_y", world_position.y))
			npc_data["stage_lane_offset_y"] = float(anchor.get("offset_y", 0.0))
			npc_data["stage_lane_strength"] = float(anchor.get("strength", 0.0))
			npc_data["stage_lane_index"] = int(anchor.get("index", -1))
	var actor = NPC_SCRIPT.new()
	add_child(actor)
	actor.setup(npc_data, tile_size)
	npc_nodes.append(actor)

func _clear_npcs() -> void:
	for actor in npc_nodes:
		if is_instance_valid(actor):
			actor.queue_free()
	npc_nodes.clear()

func _build_depth_props() -> void:
	_clear_depth_props()
	var region_type := str(current_region.get("type", "wild"))
	var terrain := str(current_region.get("terrain", ""))
	for y in range(map_height):
		for x in range(map_width):
			var tile_id: int = int(tiles[y][x])
			var seed := _tile_seed(x, y)
			var pos := Vector2((float(x) + 0.5) * tile_size, (float(y) + 0.92) * tile_size)
			match tile_id:
				Tile.GARDEN:
					if (terrain.contains("flower") or terrain.contains("garden")) and seed % 13 == 0:
						_add_depth_prop("flower_tree", pos, seed, 0, 0.82)
					elif seed % 7 == 0:
						_add_depth_prop("bamboo", pos, seed, 0, 0.92)
					elif seed % 11 == 0:
						_add_depth_prop("tree", pos, seed, 0, 0.84)
				Tile.MOUNTAIN:
					if not _has_tile(x, y - 1, tile_id) and seed % 3 == 0:
						_add_depth_prop("ridge", pos, seed, 0, 0.95)
					elif seed % 19 == 0:
						_add_depth_prop("rock_cluster", pos + Vector2(0, 4), seed, 0, 0.82)
				Tile.SHOP:
					if not _has_tile(x, y - 1, tile_id):
						_add_depth_prop("shop_roof", pos, seed, 0, 0.90)
				Tile.BUILDING:
					if not _has_tile(x, y - 1, tile_id) and seed % 2 == 0:
						_add_depth_prop("roof", pos, seed, 0, 0.86)
				Tile.ROAD:
					if current_mode == "region" and region_type == "sect" and seed % 37 == 0:
						_add_depth_prop("stone_lantern", pos + Vector2(-8, 7), seed, 0, 0.78)
					elif current_mode == "region" and seed % 43 == 0:
						_add_depth_prop("lantern", pos + Vector2(-12, 8), seed, 0, 0.72)
					if current_mode == "region" and region_type == "town" and seed % 97 == 0:
						_add_depth_prop("well", pos + Vector2(0, 6), seed, 0, 0.76)
					if current_mode == "region" and region_type == "sect" and seed % 83 == 0:
						_add_depth_prop("banner", pos + Vector2(12, 7), seed, 0, 0.80)
				Tile.WATER:
					if current_mode == "region" and seed % 31 == 0:
						_add_depth_prop("boat", pos + Vector2(0, 8), seed, 0, 0.76)
				Tile.FIELD:
					if current_mode == "region" and terrain.contains("desert") and seed % 17 == 0:
						_add_depth_prop("rock_cluster", pos + Vector2(0, 5), seed, 0, 0.76)
					elif current_mode == "region" and region_type == "town" and seed % 47 == 0:
						_add_depth_prop("market_stall", pos + Vector2(0, 7), seed, 0, 0.62)
				Tile.BRIDGE:
					if current_mode == "region" and seed % 2 == 0:
						_add_depth_prop("bridge_railing", pos + Vector2(0, -4), seed, 0, 0.86)
				Tile.COUNTER:
					if current_mode == "shop" and not _has_tile(x, y - 1, tile_id) and seed % 4 == 0:
						_add_depth_prop("shelf", pos + Vector2(0, -4), seed, 0, 0.76)
				Tile.CARPET:
					if current_mode == "shop" and seed % 11 == 0:
						_add_depth_prop("market_stall", pos + Vector2(0, 6), seed, 0, 0.62)

func _add_depth_prop(kind: String, world_position: Vector2, seed: int, z_offset: int = 0, scale_factor: float = 1.0) -> void:
	var prop = MAP_PROP_SCRIPT.new()
	add_child(prop)
	var depth_scale := get_actor_depth_scale(world_position) if current_mode == "region" and side_view_stage_enabled else 1.0
	prop.setup(kind, world_position, tile_size, seed, z_offset, scale_factor * depth_scale)
	prop_nodes.append(prop)

func _clear_depth_props() -> void:
	for prop in prop_nodes:
		if is_instance_valid(prop):
			prop.queue_free()
	prop_nodes.clear()

func _ensure_stage_scene_layer() -> void:
	if stage_scene_layer != null and is_instance_valid(stage_scene_layer):
		return
	stage_scene_layer = STAGE_SCENE_SCRIPT.new()
	stage_scene_layer.z_index = SIDE_VIEW_STAGE_SCENE_Z
	stage_scene_layer.z_as_relative = false
	add_child(stage_scene_layer)

func _update_stage_scene_layer(force_visible: bool = false) -> void:
	if current_mode != "region" or not side_view_stage_enabled:
		_hide_stage_scene_layer()
		return
	_ensure_stage_scene_layer()
	stage_scene_layer.visible = force_visible or visible
	stage_scene_layer.call("setup_region", current_region, get_world_rect().size, tile_size)

func _hide_stage_scene_layer() -> void:
	if stage_scene_layer != null and is_instance_valid(stage_scene_layer):
		stage_scene_layer.hide()

func _has_native_stage_scene() -> bool:
	return stage_scene_layer != null and is_instance_valid(stage_scene_layer) and stage_scene_layer.visible and bool(stage_scene_layer.get("active"))

func _ensure_stage_foreground_overlay() -> void:
	if stage_foreground_overlay != null and is_instance_valid(stage_foreground_overlay):
		return
	stage_foreground_overlay = STAGE_FOREGROUND_SCRIPT.new()
	stage_foreground_overlay.z_index = SIDE_VIEW_FOREGROUND_OVERLAY_Z
	stage_foreground_overlay.z_as_relative = false
	add_child(stage_foreground_overlay)

func _update_stage_foreground_overlay(force_visible: bool = false) -> void:
	if current_mode != "region" or not side_view_stage_enabled:
		_hide_stage_foreground_overlay()
		return
	_ensure_stage_foreground_overlay()
	stage_foreground_overlay.visible = force_visible or visible
	stage_foreground_overlay.call("setup_region", current_region, get_world_rect().size, tile_size)
	_update_stage_foreground_phase()

func _update_stage_foreground_phase() -> void:
	if stage_foreground_overlay == null or not is_instance_valid(stage_foreground_overlay):
		return
	if not stage_foreground_overlay.visible:
		return
	stage_foreground_overlay.call("set_visual_phase", stage_visual_phase)

func _hide_stage_foreground_overlay() -> void:
	if stage_foreground_overlay != null and is_instance_valid(stage_foreground_overlay):
		stage_foreground_overlay.hide()

func _ensure_stage_postfx_overlay() -> void:
	if stage_postfx_overlay != null and is_instance_valid(stage_postfx_overlay):
		return
	stage_postfx_overlay = STAGE_POSTFX_SCRIPT.new()
	stage_postfx_overlay.z_index = SIDE_VIEW_POSTFX_Z
	stage_postfx_overlay.z_as_relative = false
	add_child(stage_postfx_overlay)

func _update_stage_postfx_overlay(force_visible: bool = false) -> void:
	if current_mode != "region" or not side_view_stage_enabled:
		_hide_stage_postfx_overlay()
		return
	_ensure_stage_postfx_overlay()
	stage_postfx_overlay.visible = force_visible or visible
	stage_postfx_overlay.call("setup_region", current_region, get_world_rect().size, tile_size)
	_update_stage_postfx_phase()

func _update_stage_postfx_phase() -> void:
	if stage_postfx_overlay == null or not is_instance_valid(stage_postfx_overlay):
		return
	if not stage_postfx_overlay.visible:
		return
	stage_postfx_overlay.call("set_visual_phase", stage_visual_phase)

func _hide_stage_postfx_overlay() -> void:
	if stage_postfx_overlay != null and is_instance_valid(stage_postfx_overlay):
		stage_postfx_overlay.hide()

func _build_portal_labels() -> void:
	_clear_portal_labels()
	for portal in portals:
		var tile_data: Array = portal.get("tile", [0, 0])
		var portal_type := str(portal.get("type", ""))
		var label := Label.new()
		label.name = str(portal.get("id", ""))
		label.text = str(portal.get("label", "入口"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = tile_to_world(Vector2i(int(tile_data[0]), int(tile_data[1]))) + Vector2(-68, -50)
		label.size = Vector2(136, 24)
		label.z_index = 3900
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.44))
		label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		if portal_type == "shop" or portal_type == "travel_region" or portal_type == "landmark" or portal_type == "resource":
			var board := StyleBoxFlat.new()
			if portal_type == "travel_region":
				board.bg_color = Color(0.08, 0.16, 0.12, 0.74)
				board.border_color = Color(0.72, 0.84, 0.52, 0.58)
			elif portal_type == "landmark":
				board.bg_color = Color(0.16, 0.12, 0.07, 0.72)
				board.border_color = Color(0.80, 0.68, 0.38, 0.56)
			elif portal_type == "resource":
				board.bg_color = Color(0.08, 0.14, 0.08, 0.70)
				board.border_color = Color(0.58, 0.76, 0.38, 0.52)
			else:
				board.bg_color = Color(0.24, 0.12, 0.06, 0.72)
				board.border_color = Color(0.86, 0.58, 0.25, 0.55)
			board.set_border_width_all(1)
			board.set_corner_radius_all(3)
			label.add_theme_stylebox_override("normal", board)
		label.visible = current_mode == "shop" or portal_type == "shop" or portal_type == "travel_region" or portal_type == "landmark" or portal_type == "resource"
		add_child(label)
		portal_labels.append(label)

func _clear_portal_labels() -> void:
	for label in portal_labels:
		if is_instance_valid(label):
			label.queue_free()
	portal_labels.clear()

func _local_npc_tile(npc_data: Dictionary, index: int) -> Vector2i:
	var source := Vector2i(int(npc_data.get("pos_x", map_width / 2)), int(npc_data.get("pos_y", map_height / 2)))
	var source_region := GameData.get_region_at_tile(source)
	var preferred := _scaled_world_tile_to_local(source, source_region)
	if current_mode == "region":
		preferred = _role_anchor(npc_data, index, preferred)
	return _claim_local_npc_tile(preferred, int(npc_data.get("id", index)), index)

func _role_anchor(npc_data: Dictionary, index: int, fallback: Vector2i) -> Vector2i:
	var npc_type := str(npc_data.get("npc_type", "normal"))
	if npc_type == "trader":
		return _merchant_anchor(index)
	if npc_type == "enemy":
		return _edge_anchor(index)
	if npc_type == "master" or bool(npc_data.get("is_master", false)):
		return _quiet_anchor(index)
	if bool(npc_data.get("has_quests", false)):
		return _story_anchor(index)
	var description := str(npc_data.get("description", ""))
	if description.contains("村长") or description.contains("夫子") or description.contains("捕快") or description.contains("郎中"):
		return _civic_anchor(index)
	if fallback.x <= 3 or fallback.y <= 3 or fallback.x >= map_width - 3 or fallback.y >= map_height - 3:
		return _civilian_anchor(index)
	return _civilian_anchor(index)

func _scaled_world_tile_to_local(source: Vector2i, source_region: Dictionary) -> Vector2i:
	if source_region.is_empty():
		return Vector2i(map_width / 2, map_height / 2)
	var rect_data: Array = source_region.get("rect", [])
	if rect_data.size() < 4:
		return Vector2i(map_width / 2, map_height / 2)
	var rect := Rect2i(int(rect_data[0]), int(rect_data[1]), int(rect_data[2]), int(rect_data[3]))
	var nx := float(source.x - rect.position.x) / float(max(1, rect.size.x - 1))
	var ny := float(source.y - rect.position.y) / float(max(1, rect.size.y - 1))
	return Vector2i(
		roundi(lerpf(8.0, float(map_width - 9), clamp(nx, 0.0, 1.0))),
		roundi(lerpf(8.0, float(map_height - 8), clamp(ny, 0.0, 1.0)))
	)

func _merchant_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(11, 15),
		Vector2i(map_width - 12, 15),
		Vector2i(11, map_height - 14),
		Vector2i(map_width - 12, map_height - 14),
		Vector2i(map_width / 2 - 15, 11),
		Vector2i(map_width / 2 + 15, map_height - 12),
		Vector2i(map_width / 2 - 21, map_height / 2 + 7),
		Vector2i(map_width / 2 + 21, map_height / 2 - 7)
	]
	return anchors[index % anchors.size()]

func _quiet_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(map_width / 2 - 19, map_height / 2 - 12),
		Vector2i(map_width / 2 + 19, map_height / 2 - 12),
		Vector2i(map_width / 2 - 21, map_height / 2 + 10),
		Vector2i(map_width / 2 + 21, map_height / 2 + 10),
		Vector2i(map_width / 2, 10)
	]
	return anchors[index % anchors.size()]

func _edge_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(map_width - 10, map_height / 2),
		Vector2i(9, map_height / 2),
		Vector2i(map_width / 2, 9),
		Vector2i(map_width / 2, map_height - 10),
		Vector2i(map_width - 12, map_height - 11),
		Vector2i(12, 11)
	]
	return anchors[index % anchors.size()]

func _story_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(map_width / 2 - 17, map_height / 2 - 10),
		Vector2i(map_width / 2 + 17, map_height / 2 - 10),
		Vector2i(map_width / 2 - 18, map_height / 2 + 10),
		Vector2i(map_width / 2 + 18, map_height / 2 + 10),
		Vector2i(10, map_height / 2 + 4),
		Vector2i(map_width - 11, map_height / 2 - 4)
	]
	return anchors[index % anchors.size()]

func _civic_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(map_width / 2 - 8, 12),
		Vector2i(map_width / 2 + 9, 12),
		Vector2i(map_width / 2 - 9, map_height / 2 - 3),
		Vector2i(map_width / 2 + 10, map_height / 2 + 3),
		Vector2i(13, map_height / 2),
		Vector2i(map_width - 14, map_height / 2)
	]
	return anchors[index % anchors.size()]

func _civilian_anchor(index: int) -> Vector2i:
	var anchors := [
		Vector2i(10, 10),
		Vector2i(map_width - 11, 10),
		Vector2i(9, map_height - 11),
		Vector2i(map_width - 10, map_height - 11),
		Vector2i(map_width / 2 - 23, map_height / 2 - 3),
		Vector2i(map_width / 2 + 23, map_height / 2 + 3),
		Vector2i(map_width / 2 - 8, map_height / 2 + 13),
		Vector2i(map_width / 2 + 9, map_height / 2 - 13)
	]
	return anchors[index % anchors.size()]

func _claim_local_npc_tile(preferred: Vector2i, npc_id: int, index: int) -> Vector2i:
	for min_spacing in LOCAL_NPC_SPACING_STEPS:
		for radius in range(0, 16):
			var candidates := _ring_candidates(preferred, radius, npc_id + index * 23)
			for tile in candidates:
				if is_tile_walkable(tile) and _is_local_npc_tile_clear(tile, min_spacing) and not _is_near_entry_tile(tile):
					occupied_npc_tiles.append(tile)
					return tile
	occupied_npc_tiles.append(preferred)
	return preferred

func _ring_candidates(center: Vector2i, radius: int, seed: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	if radius <= 0:
		candidates.append(center)
		return candidates
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if abs(x - center.x) != radius and abs(y - center.y) != radius:
				continue
			candidates.append(Vector2i(x, y))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var score_a: int = abs((a.x * 41 + a.y * 29 + seed) % 101)
		var score_b: int = abs((b.x * 41 + b.y * 29 + seed) % 101)
		return score_a < score_b
	)
	return candidates

func _is_local_npc_tile_clear(tile: Vector2i, min_spacing: int) -> bool:
	for used in occupied_npc_tiles:
		var dx := tile.x - used.x
		var dy := tile.y - used.y
		if dx * dx + dy * dy < min_spacing * min_spacing:
			return false
	return true

func _is_near_entry_tile(tile: Vector2i) -> bool:
	if current_mode != "region":
		return false
	var entry := world_to_tile(get_entry_position("world"))
	var dx := tile.x - entry.x
	var dy := tile.y - entry.y
	return dx * dx + dy * dy < LOCAL_NPC_ENTRY_CLEAR_RADIUS * LOCAL_NPC_ENTRY_CLEAR_RADIUS

func _shop_plan_for_region() -> Array:
	var region_type := str(current_region.get("type", "wild"))
	var region_id := str(current_region.get("id", ""))
	if region_type == "city":
		match region_id:
			"linan":
				return ["inn", "teahouse", "tailor", "market", "medicine", "blacksmith"]
			"chengdu":
				return ["inn", "medicine", "market", "blacksmith", "teahouse", "tailor"]
			"jiangling":
				return ["inn", "blacksmith", "medicine", "market", "tailor"]
			"changan":
				return ["inn", "blacksmith", "tailor", "medicine", "market"]
			_:
				return ["inn", "medicine", "blacksmith", "tailor", "market", "teahouse"]
	if region_type == "town":
		return ["inn", "market", "medicine", "blacksmith", "tailor"]
	return ["market", "medicine"]

func _region_profile() -> Dictionary:
	var region_id := str(current_region.get("id", ""))
	return {
		"water_city": region_id == "linan",
		"garden_city": region_id == "chengdu" or region_id == "linan"
	}

func _draw() -> void:
	if tiles.size() < map_height:
		return
	var is_side_view := current_mode == "region" and side_view_stage_enabled
	if is_side_view and LOCAL_SIDE_VIEW_HIDE_TILE_GRID:
		if not _has_native_stage_scene():
			_draw_side_view_stage()
	else:
		_draw_base_tiles(is_side_view)
		if not LOCAL_USE_TILE_TEXTURES:
			_draw_local_painterly_cohesion_pass()
			_draw_local_painterly_boundary_soften_pass()
		_draw_local_painterly_overlay(is_side_view)
		if not (LOCAL_PAINTERLY_SKIP_SCENE_TEXTURES and not LOCAL_USE_TILE_TEXTURES):
			_draw_scene_background_wash()
		_draw_side_view_stage()
	_draw_scene_overlay()
	_draw_portal_signs()
	_draw_portals()

func _draw_local_painterly_cohesion_pass() -> void:
	if map_width <= 0 or map_height <= 0:
		return
	var blend_phase := int(floor(stage_visual_phase * 7.0))
	for i in range(LOCAL_PAINTERLY_MELT_STROKE_COUNT):
		var seed_x := _tile_seed(i + 401, blend_phase + 33)
		var seed_y := _tile_seed(i * 17 + 7, blend_phase + 35)
		var width_span: int = max(1, map_width)
		var height_span: int = max(1, map_height)
		var tx := seed_x % width_span
		var ty := seed_y % height_span
		var base_color := _tile_color(_tile_id_at(tx, ty))
		var center := Vector2(float(tx), float(ty)) * tile_size + Vector2(
			tile_size * StageVisualProfile.tile_noise(seed_y, seed_x, 911),
			tile_size * StageVisualProfile.tile_noise(seed_x, seed_y, 912)
		)
		var angle := TAU * StageVisualProfile.tile_noise(seed_x + 3, seed_y + 5, 921)
		var dir := Vector2(cos(angle), sin(angle))
		var side := Vector2(-dir.y, dir.x)
		var len := tile_size * (1.9 + StageVisualProfile.tile_noise(seed_x + 4, seed_y + 8, 922) * 3.2)
		var width := tile_size * (0.36 + StageVisualProfile.tile_noise(seed_x + 9, seed_y + 11, 923) * 0.38)
		var p0 := center + dir * len * 0.62 + side * width
		var p1 := center + dir * len * 0.20 + side * (width * 0.38)
		var p2 := center - dir * len * 0.20 - side * (width * 0.30)
		var p3 := center - dir * len * 0.62 - side * width
		var wash := Color(base_color.r, base_color.g, base_color.b, LOCAL_PAINTERLY_MELT_STROKE_ALPHA)
		draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([wash, wash, wash, wash]))

	for i in range(LOCAL_PAINTERLY_MELT_BLOB_COUNT):
		var seed_x := _tile_seed(i + 511, blend_phase + 41)
		var seed_y := _tile_seed(i * 11 + 13, blend_phase + 43)
		var width_span: int = max(1, map_width)
		var height_span: int = max(1, map_height)
		var tx := seed_x % width_span
		var ty := seed_y % height_span
		var center := Vector2(float(tx), float(ty)) * tile_size + Vector2(
			tile_size * 0.16 + tile_size * StageVisualProfile.tile_noise(seed_x, seed_y, 941),
			tile_size * 0.16 + tile_size * StageVisualProfile.tile_noise(seed_y, seed_x, 942)
		)
		var base_color := _tile_color(_tile_id_at(tx, ty))
		var radius := tile_size * (0.48 + StageVisualProfile.tile_noise(seed_x + 1, seed_y + 1, 943) * 1.3)
		draw_circle(center, radius, Color(base_color.r, base_color.g, base_color.b, LOCAL_PAINTERLY_MELT_BLOB_ALPHA))

func _draw_local_painterly_boundary_soften_pass() -> void:
	if map_width <= 0 or map_height <= 0:
		return
	var phase := int(floor(stage_visual_phase * 4.0))
	for i in range(LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_COUNT):
		var seed_x: int = _tile_seed(i + 901, phase + 11)
		var seed_y: int = _tile_seed(i * 11 + 13, phase + 17)
		var width_span: int = max(1, map_width)
		var height_span: int = max(1, map_height)
		var tx: int = seed_x % width_span
		var ty: int = seed_y % height_span
		var nx: int = tx
		var ny: int = ty
		var step: int = StageVisualProfile.tile_random(seed_x, seed_y, 191) % 4
		if step == 0:
			nx = mini(tx + 1, map_width - 1)
		elif step == 1:
			nx = maxi(tx - 1, 0)
		elif step == 2:
			ny = mini(ty + 1, map_height - 1)
		else:
			ny = maxi(ty - 1, 0)
		var base_color := _tile_color(_tile_id_at(tx, ty))
		var near_color := _tile_color(_tile_id_at(nx, ny))
		var blend := base_color.lerp(near_color, 0.42 + StageVisualProfile.tile_noise(seed_y, seed_x, 201) * 0.36)
		var base_x := (float(tx) + StageVisualProfile.tile_noise(seed_x + 3, seed_y + 7, 211)) * tile_size
		var base_y := (float(ty) + StageVisualProfile.tile_noise(seed_y + 5, seed_x + 9, 223)) * tile_size
		var center := Vector2(base_x, base_y)
		var radius := tile_size * (LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_RADIUS_MIN + StageVisualProfile.tile_noise(seed_x + 5, seed_y + 11, 233) * (LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_RADIUS_MAX - LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_RADIUS_MIN))
		var alpha := LOCAL_PAINTERLY_TILE_BOUNDARY_SOFTEN_ALPHA * (0.55 + StageVisualProfile.tile_noise(seed_x + 9, seed_y + 13, 241) * 0.55)
		draw_circle(center, radius, Color(blend.r, blend.g, blend.b, alpha))

func _tile_id_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= map_width or y >= map_height:
		return Tile.GRASS
	if y >= tiles.size():
		return Tile.GRASS
	var row: Array = tiles[y] as Array
	if row.size() <= x or x < 0:
		return Tile.GRASS
	return int(row[x])

func _draw_local_painterly_overlay(is_side_view: bool) -> void:
	if not is_side_view or current_mode != "region":
		return
	var rect := get_world_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var density := maxf(1.0, 1.0 + stage_visual_phase * 0.0)
	for i in range(LOCAL_PAINTERLY_STROKE_COUNT):
		var phase_seed := int(density * 17.0) + i
		var seed_x := StageVisualProfile.tile_random(i, phase_seed, 111)
		var seed_y := StageVisualProfile.tile_random(phase_seed, i, 222)
		var x_index := int(seed_x % max(1, map_width))
		var y_index := int(seed_y % max(1, map_height))
		var start := Vector2(float(x_index), float(y_index)) * tile_size + Vector2(4.0, 4.0)
		var angle := TAU * StageVisualProfile.tile_noise(seed_x, seed_y, 333)
		var brush_len := tile_size * (1.4 + StageVisualProfile.tile_noise(seed_y, seed_x, 444) * 1.9)
		var jitter := Vector2(cos(angle), sin(angle)) * brush_len
		var color := Color(0.16, 0.10, 0.07, LOCAL_PAINTERLY_STROKE_ALPHA * (0.55 + StageVisualProfile.tile_noise(seed_x, seed_y, 555) * 0.45))
		draw_line(start, start + jitter, color, 1.0 + (float(phase_seed % 6) * 0.18))

	for i in range(LOCAL_PAINTERLY_DOT_COUNT):
		var phase_seed := int(density * 7.0) - i
		var seed_x := StageVisualProfile.tile_random(i * 31, phase_seed, 666)
		var seed_y := StageVisualProfile.tile_random(phase_seed, i * 17, 777)
		var x_index := int(seed_x % max(1, map_width))
		var y_index := int(seed_y % max(1, map_height))
		var center := Vector2(float(x_index), float(y_index)) * tile_size + Vector2(
			tile_size * 0.35,
			tile_size * 0.35
		)
		var radius := tile_size * (0.08 + StageVisualProfile.tile_noise(seed_y, seed_x, 888) * 0.09)
		var noise_alpha := LOCAL_PAINTERLY_DOT_ALPHA * (0.35 + StageVisualProfile.tile_noise(seed_x, seed_y, 999) * 0.5)
		draw_circle(center, radius, Color(0.09, 0.06, 0.03, noise_alpha))

func _draw_base_tiles(is_side_view: bool) -> void:
	for y in range(map_height):
		if y >= tiles.size():
			return
		var row: Array = tiles[y] as Array
		var row_width: int = min(map_width, row.size())
		if row_width <= 0:
			continue
		for x in range(row_width):
			var tile_id: int = int(row[x])
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			if LOCAL_USE_TILE_TEXTURES:
				var texture := _tile_texture(tile_id, x, y)
				if texture != null:
					draw_texture_rect(texture, rect, false)
					var tint := _tile_tint(tile_id)
					if tint.a > 0.0:
						draw_rect(rect, tint, true)
				else:
					draw_rect(rect, _tile_color(tile_id), true)
			else:
				_draw_local_painterly_tile_base(rect, tile_id, x, y)
				if _is_local_building_tile(tile_id):
					_draw_local_painterly_building_block(rect, tile_id, x, y)
			if LOCAL_USE_TILE_TEXTURES:
				if _should_draw_local_tile_transition(x, y, tile_id, is_side_view):
					_draw_tile_transition(rect, tile_id, x, y)
				if _should_draw_local_tile_detail(x, y, tile_id, is_side_view):
					_draw_tile_detail(rect, tile_id, x, y)
				if _should_draw_local_building_wireframe(tile_id, x, y, is_side_view):
					_draw_local_building_wireframe(rect, tile_id, x, y)
			if LOCAL_USE_TILE_TEXTURES and _is_local_building_tile(tile_id):
				_draw_local_building_surface_detail(rect, tile_id, x, y)

func _draw_local_painterly_tile_base(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	var base_color := _tile_color(tile_id)
	var bleed := base_color
	var neighbor_count := 0
	for offset in [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if ny >= 0 and ny < tiles.size() and nx >= 0 and nx < tiles[ny].size():
			bleed = bleed.lerp(_tile_color(_tile_id_at(nx, ny)), 0.12)
			neighbor_count += 1
	if neighbor_count > 0:
		bleed = bleed.lerp(base_color, 0.64)
	var soft_rect := rect.grow(tile_size * LOCAL_PAINTERLY_TILE_OVERDRAW)
	draw_rect(soft_rect, bleed, true)
	var jitter_x := StageVisualProfile.tile_offset(x, y, 401, tile_size * LOCAL_PAINTERLY_TILE_VARIATION)
	var jitter_y := StageVisualProfile.tile_offset(y, x, 402, tile_size * LOCAL_PAINTERLY_TILE_VARIATION)
	var vertices := PackedVector2Array([
		rect.position + Vector2(tile_size * 0.10 + jitter_x, tile_size * 0.10 + jitter_y),
		rect.position + Vector2(rect.size.x - tile_size * 0.06 + jitter_x * 0.8, tile_size * 0.04 - jitter_y * 0.2),
		rect.position + Vector2(rect.size.x - tile_size * 0.04 + jitter_x * 0.6, rect.size.y - tile_size * 0.04 + jitter_y),
		rect.position + Vector2(tile_size * 0.04 - jitter_x * 0.2, rect.size.y - tile_size * 0.08 - jitter_y)
	])
	var wash := Color(base_color.r * 0.90, base_color.g * 0.90, base_color.b * 0.90, LOCAL_PAINTERLY_TILE_GRAIN_ALPHA * 0.35)
	draw_polygon(vertices, PackedColorArray([wash, wash, wash, wash]))
	for i in range(LOCAL_PAINTERLY_TILE_BLOB_COUNT):
		var seed_x := StageVisualProfile.tile_random(x * 13 + i, y * 17 + i, 613)
		var seed_y := StageVisualProfile.tile_random(y * 17 + i, x * 13 + i, 617)
		var blob_center := rect.position + Vector2(float(seed_x % int(tile_size)), float(seed_y % int(tile_size)))
		var blob_radius := tile_size * (0.06 + StageVisualProfile.tile_noise(seed_x, seed_y, 619) * 0.12)
		var grain_color := Color(base_color.r, base_color.g, base_color.b, LOCAL_PAINTERLY_TILE_GRAIN_ALPHA * 0.45).lightened(0.06)
		draw_circle(blob_center, blob_radius, grain_color)

func _draw_local_painterly_building_block(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if _has_tile(x - 1, y, tile_id) and _has_tile(x + 1, y, tile_id) and _has_tile(x, y - 1, tile_id) and _has_tile(x, y + 1, tile_id):
		return
	var base_color := _local_building_wireframe_color(tile_id)
	var wall := Color(base_color.r * 0.84, base_color.g * 0.78, base_color.b * 0.70, LOCAL_PAINTERLY_BUILDING_BLOCK_ALPHA)
	var roof := Color(base_color.r * 1.20, base_color.g * 1.10, base_color.b * 1.05, LOCAL_PAINTERLY_BUILDING_BLOCK_ALPHA)
	var sway := StageVisualProfile.tile_noise(x, y, 881) * tile_size * 0.14
	var jitter := StageVisualProfile.tile_noise(y, x, 882) * tile_size * 0.18
	if not _has_tile(x, y - 1, tile_id):
		var roof_rect := Rect2(
			rect.position + Vector2(tile_size * 0.14 + sway * 0.18, tile_size * 0.05),
			Vector2(tile_size * 0.68 + sway * 0.20, tile_size * 0.16)
		)
		draw_rect(roof_rect, roof, true)
	if not _has_tile(x, y + 1, tile_id):
		var foot := rect.position.y + tile_size - tile_size * 0.22
		var foundation_rect := Rect2(
			Vector2(rect.position.x + jitter * 0.5, foot),
			Vector2(rect.size.x - jitter * 0.7, tile_size * 0.20)
		)
		draw_rect(foundation_rect, wall, true)
	if not _has_tile(x - 1, y, tile_id):
		draw_line(rect.position + Vector2(1.0, tile_size * 0.18), rect.position + Vector2(1.0, rect.size.y - 1.0), wall, 1.0)
	if not _has_tile(x + 1, y, tile_id):
		draw_line(rect.position + Vector2(rect.size.x - 1.0, tile_size * 0.18), rect.position + Vector2(rect.size.x - 1.0, rect.size.y - 1.0), wall, 1.0)

func _tile_texture(tile_id: int, x: int, y: int) -> Texture2D:
	var variants: Array = tile_textures.get(tile_id, [])
	if variants.is_empty():
		return null
	var index := _tile_seed(x, y) % variants.size()
	return variants[index]

func _should_draw_local_tile_transition(x: int, y: int, tile_id: int, is_stage_view: bool) -> bool:
	if not is_stage_view:
		return true
	var step := LOCAL_SIDE_TILE_TRANSITION_DECIMATION
	match tile_id:
		Tile.BUILDING, Tile.SHOP, Tile.COUNTER, Tile.CARPET, Tile.WALL:
			step = LOCAL_SIDE_BUILDING_TILE_DECIMATION
	return ((x + y) % step) == 0

func _should_draw_local_tile_detail(x: int, y: int, tile_id: int, is_stage_view: bool) -> bool:
	if not is_stage_view:
		return true
	var step := LOCAL_SIDE_TILE_DETAIL_DECIMATION
	match tile_id:
		Tile.BUILDING, Tile.SHOP, Tile.COUNTER, Tile.CARPET, Tile.WALL:
			step = 1
	return ((x * 11 + y * 17) % step) == 0

func _should_draw_local_building_wireframe(tile_id: int, x: int, y: int, is_side_view: bool) -> bool:
	if not _is_local_building_tile(tile_id):
		return false
	if not is_side_view:
		return true
	return ((x * 11 + y * 7 + tile_id) % LOCAL_BUILDING_EDGE_DECIMATION) == 0

func _is_local_building_tile(tile_id: int) -> bool:
	match tile_id:
		Tile.BUILDING, Tile.SHOP, Tile.COUNTER, Tile.CARPET, Tile.WALL:
			return true
		_:
			return false

func _local_building_wireframe_color(tile_id: int) -> Color:
	match tile_id:
		Tile.WALL, Tile.CARPET:
			return Color(0.36, 0.20, 0.10, LOCAL_BUILDING_EDGE_ALPHA)
		Tile.SHOP:
			return Color(0.46, 0.26, 0.09, LOCAL_BUILDING_EDGE_ALPHA)
		_:
			return Color(0.22, 0.12, 0.06, LOCAL_BUILDING_EDGE_ALPHA)

func _draw_local_building_wireframe(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if not _is_local_building_tile(tile_id):
		return
	var base := _local_building_wireframe_color(tile_id)
	var phase := StageVisualProfile.tile_noise(x, y, 444) * 0.5 - 0.25
	var width := maxf(0.8, LOCAL_BUILDING_EDGE_WIDTH + phase)
	var jitter := StageVisualProfile.tile_offset(x, y, 555, tile_size * StageVisualProfile.LOCAL_BUILDING_EDGE_NOISE * 2.0)
	var left := rect.position + Vector2(0.0, clamp(phase * 2.0, -tile_size * 0.15, tile_size * 0.15))
	var right := rect.position + Vector2(rect.size.x, clamp(phase * -2.0, -tile_size * 0.15, tile_size * 0.15))
	if not _has_tile(x, y - 1, tile_id):
		draw_line(left + Vector2(2.0, jitter), right + Vector2(-2.0, jitter), base, width)
	if not _has_tile(x + 1, y, tile_id):
		draw_line(rect.position + Vector2(rect.size.x - 1.5, 2.0) + Vector2(jitter * 0.3, 0.0), rect.position + Vector2(rect.size.x - 1.5, rect.size.y - 2.0) + Vector2(-jitter * 0.3, 0.0), base, width)
	if not _has_tile(x, y + 1, tile_id):
		draw_line(rect.position + Vector2(2.0, rect.size.y - 1.8), rect.position + Vector2(rect.size.x - 2.0, rect.size.y - 1.8), base, width)
	if not _has_tile(x - 1, y, tile_id):
		draw_line(rect.position + Vector2(2.0, 2.0), rect.position + Vector2(2.0, rect.size.y - 2.0), base, width)

func _draw_scene_background_wash() -> void:
	if current_mode != "region" or scene_background_texture == null or LOCAL_PAINTERLY_FORCE_TEXTURELESS_STAGE:
		return
	var alpha := LOCAL_SCENE_BACKGROUND_WASH_BASE_ALPHA
	var region_type := str(current_region.get("type", "wild"))
	if region_type == "city":
		alpha = LOCAL_SCENE_BACKGROUND_WASH_CITY_ALPHA
	elif region_type == "sect":
		alpha = LOCAL_SCENE_BACKGROUND_WASH_SECT_ALPHA
	if side_view_stage_enabled:
		alpha *= LOCAL_SCENE_WASH_SIDE_VIEW_MULTIPLIER
	draw_texture_rect(scene_background_texture, Rect2(Vector2.ZERO, get_world_rect().size), false, Color(1.0, 1.0, 1.0, alpha))

func _draw_side_view_stage() -> void:
	if not side_view_stage_enabled or current_mode != "region":
		return
	var rect := get_world_rect()
	var size := rect.size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var palette := _side_view_palette()
	var sky_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.58))
	var painted_stage_stack := _has_painted_stage_stack()
	if LOCAL_SIDE_VIEW_HIDE_TILE_GRID:
		STAGE_BACKDROP_RENDERER.draw_stage_foundation(self, size, tile_size, current_region, stage_visual_phase, palette)
		if _has_local_scene_background_texture():
			var backdrop_alpha := SIDE_VIEW_PAINTED_BACKDROP_ALPHA * (0.94 if painted_stage_stack else 0.72)
			_draw_cover_texture(scene_background_texture, Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, backdrop_alpha))
	else:
		if _has_local_scene_background_texture():
			_draw_side_view_painted_backdrop(size, palette)
			_draw_cover_texture(scene_background_texture, sky_rect, Color(1.0, 1.0, 1.0, SIDE_VIEW_BACKDROP_ALPHA * 0.42))
		else:
			_draw_side_view_painted_backdrop(size, palette)
		draw_rect(sky_rect, Color(0.02, 0.018, 0.015, 0.18), true)
	if not painted_stage_stack:
		_draw_side_view_silhouettes(size, palette)
		_draw_side_view_midground(size, palette)
	_draw_side_view_painted_midground_layer(size, palette)
	if not painted_stage_stack:
		_draw_side_view_street_facades(size, palette)
		_draw_side_view_upper_platforms(size, palette)
		_draw_side_view_setpiece_row(size, palette)
	_draw_side_view_ground(size, palette)
	_draw_side_view_painted_floor_layer(size, palette)
	_draw_side_view_director_pass(size, palette)
	_draw_side_view_living_silhouettes(size, palette)
	_draw_side_view_ambient(size, palette)
	_draw_side_view_foreground(size, palette)

func _draw_cover_texture(texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale: float = maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var source_size := rect.size / scale
	var source_pos := (texture_size - source_size) * 0.5
	draw_texture_rect_region(texture, rect, Rect2(source_pos, source_size), modulate)

func _draw_side_view_painted_backdrop(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var sky: Color = palette["sky"]
	var floor_color: Color = palette["floor"]
	if not _has_local_scene_background_texture():
		_draw_stage_vertical_gradient(
			Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.34)),
			Color(sky.r, sky.g, sky.b, SIDE_VIEW_PAINTED_BACKDROP_SKY_BLEND * 1.25),
			Color(sky.r, sky.g, sky.b, 0.0)
		)
		_draw_stage_vertical_gradient(
			Rect2(Vector2(0.0, size.y * 0.44), Vector2(size.x, size.y * 0.36)),
			Color(floor_color.r, floor_color.g, floor_color.b, 0.0),
			Color(floor_color.r, floor_color.g, floor_color.b, SIDE_VIEW_PAINTED_BACKDROP_FOOT_BLEND * 0.14)
		)
		_draw_stage_horizontal_gradient(
			Rect2(Vector2.ZERO, Vector2(size.x * 0.16, size.y)),
			Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA * 1.05),
			Color(0.0, 0.0, 0.0, 0.0)
		)
		_draw_stage_horizontal_gradient(
			Rect2(Vector2(size.x * 0.84, 0.0), Vector2(size.x * 0.16, size.y)),
			Color(0.0, 0.0, 0.0, 0.0),
			Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA * 1.05)
		)
		return
	_draw_cover_texture(scene_background_texture, Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, SIDE_VIEW_PAINTED_BACKDROP_ALPHA))
	_draw_stage_vertical_gradient(
		Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.30)),
		Color(sky.r, sky.g, sky.b, SIDE_VIEW_PAINTED_BACKDROP_SKY_BLEND),
		Color(sky.r, sky.g, sky.b, 0.0)
	)
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, size.y * 0.48), Vector2(size.x, size.y * 0.30)),
		Color(accent.r, accent.g, accent.b, 0.0),
		Color(accent.r, accent.g, accent.b, SIDE_VIEW_PAINTED_BACKDROP_FOOT_BLEND * 0.26)
	)
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, size.y * 0.70), Vector2(size.x, size.y * 0.30)),
		Color(floor_color.r, floor_color.g, floor_color.b, SIDE_VIEW_PAINTED_BACKDROP_FOOT_BLEND * 0.12),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_FOOT_BLEND)
	)
	_draw_stage_horizontal_gradient(
		Rect2(Vector2.ZERO, Vector2(size.x * 0.16, size.y)),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA),
		Color(0.0, 0.0, 0.0, 0.0)
	)
	_draw_stage_horizontal_gradient(
		Rect2(Vector2(size.x * 0.84, 0.0), Vector2(size.x * 0.16, size.y)),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA)
	)

func _draw_side_view_painted_midground_layer(size: Vector2, palette: Dictionary) -> void:
	if scene_midground_layer_texture == null or not _has_local_scene_stage_layer_texture():
		return
	var accent: Color = palette["accent"]
	var sky: Color = palette["sky"]
	var layer_rect := Rect2(
		Vector2(-size.x * 0.035, size.y * 0.215),
		Vector2(size.x * 1.07, size.y * 0.43)
	)
	draw_texture_rect(scene_midground_layer_texture, layer_rect, false, Color(1.0, 1.0, 1.0, SIDE_VIEW_PAINTED_MIDGROUND_LAYER_ALPHA))
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, layer_rect.position.y - tile_size * 0.25), Vector2(size.x, tile_size * 1.30)),
		Color(sky.r, sky.g, sky.b, SIDE_VIEW_PAINTED_MIDGROUND_LAYER_FOG_ALPHA),
		Color(sky.r, sky.g, sky.b, 0.0)
	)
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, layer_rect.position.y + layer_rect.size.y * 0.70), Vector2(size.x, layer_rect.size.y * 0.34)),
		Color(accent.r, accent.g, accent.b, 0.0),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_MIDGROUND_LAYER_FOOT_ALPHA)
	)
	_draw_stage_horizontal_gradient(
		Rect2(Vector2.ZERO, Vector2(size.x * 0.10, size.y)),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA * 0.62),
		Color(0.0, 0.0, 0.0, 0.0)
	)
	_draw_stage_horizontal_gradient(
		Rect2(Vector2(size.x * 0.90, 0.0), Vector2(size.x * 0.10, size.y)),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_BACKDROP_EDGE_ALPHA * 0.62)
	)

func _draw_side_view_painted_floor_layer(size: Vector2, palette: Dictionary) -> void:
	if scene_floor_layer_texture == null or not _has_local_scene_stage_layer_texture():
		return
	var accent: Color = palette["accent"]
	var floor_rect := Rect2(
		Vector2(-size.x * 0.035, size.y * 0.020),
		Vector2(size.x * 1.070, size.y * 1.035)
	)
	draw_texture_rect(scene_floor_layer_texture, floor_rect, false, Color(1.0, 1.0, 1.0, SIDE_VIEW_PAINTED_FLOOR_LAYER_ALPHA))
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, size.y * 0.50), Vector2(size.x, size.y * 0.24)),
		Color(accent.r, accent.g, accent.b, 0.0),
		Color(accent.r, accent.g, accent.b, SIDE_VIEW_PAINTED_FLOOR_LAYER_FOOT_ALPHA * 0.32)
	)
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, size.y * 0.72), Vector2(size.x, size.y * 0.28)),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, SIDE_VIEW_PAINTED_FLOOR_LAYER_FOOT_ALPHA)
	)

func _has_local_scene_background_texture() -> bool:
	return (scene_background_texture != null) and not LOCAL_PAINTERLY_FORCE_TEXTURELESS_STAGE

func _has_local_scene_stage_layer_texture() -> bool:
	return not LOCAL_PAINTERLY_FORCE_TEXTURELESS_STAGE

func is_painted_stage_stack_active() -> bool:
	if _has_native_stage_scene():
		return bool(stage_scene_layer.get("built_from_stage_layers"))
	return _has_painted_stage_stack()

func _has_painted_stage_stack() -> bool:
	return LOCAL_PAINTED_STAGE_TEXTURE_PRIORITY and scene_midground_layer_texture != null and scene_floor_layer_texture != null and _has_local_scene_stage_layer_texture()

func _draw_stage_vertical_gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

func _draw_stage_horizontal_gradient(rect: Rect2, left_color: Color, right_color: Color) -> void:
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([left_color, right_color, right_color, left_color]))

func _draw_side_view_silhouettes(size: Vector2, palette: Dictionary) -> void:
	var horizon := size.y * 0.44
	_draw_stage_mountain_band(size, horizon - tile_size * 1.35, 0.32, (palette["far"] as Color))
	_draw_stage_mountain_band(size, horizon - tile_size * 0.55, 0.18, (palette["mid"] as Color))
	_draw_stage_parallax_backdrop(size, horizon, palette)
	var region_type := str(current_region.get("type", "wild"))
	var terrain := str(current_region.get("terrain", ""))
	if region_type == "city" or region_type == "town":
		_draw_stage_roofline(size, horizon - tile_size * 1.06, palette["accent"] as Color)
	elif region_type == "sect":
		_draw_stage_gate(size, horizon - tile_size * 1.10, palette["accent"] as Color)
	elif _terrain_has_forest(terrain):
		_draw_stage_bamboo_edge(size, horizon - tile_size * 1.18, true, palette["accent"] as Color)
		_draw_stage_bamboo_edge(size, horizon - tile_size * 1.02, false, palette["accent"] as Color)
	elif _terrain_has_water(terrain):
		for i in range(4):
			var y := horizon + float(i) * tile_size * 0.36
			draw_line(Vector2(size.x * 0.08, y), Vector2(size.x * 0.92, y - tile_size * 0.12), Color(0.78, 0.92, 0.94, 0.18), 2.2)

func _draw_side_view_midground(size: Vector2, palette: Dictionary) -> void:
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var accent: Color = palette["accent"]
	var y := size.y * 0.455
	if region_type == "city" or region_type == "town":
		_draw_stage_city_facades(size, y, accent)
	elif region_type == "sect":
		_draw_stage_sect_steps(size, y, accent)
	elif _terrain_has_water(terrain):
		_draw_stage_pier(size, y, accent)
	elif _terrain_has_forest(terrain):
		_draw_stage_forest_trunks(size, y, accent)
	elif terrain.contains("snow"):
		_draw_stage_ice_ridge(size, y, accent)
	elif terrain.contains("desert"):
		_draw_stage_desert_markers(size, y, accent)
	elif _terrain_has_mountain(terrain):
		_draw_stage_rock_terrace(size, y, accent)
	else:
		_draw_stage_low_horizon_props(size, y, accent)

func _draw_stage_parallax_backdrop(size: Vector2, horizon: float, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var far: Color = palette["far"]
	for layer in range(SIDE_VIEW_PARALLAX_LAYER_COUNT):
		var t := float(layer) / float(maxi(1, SIDE_VIEW_PARALLAX_LAYER_COUNT - 1))
		var y := horizon - tile_size * (2.05 - t * 0.42)
		var drift := fposmod(stage_visual_phase * tile_size * SIDE_VIEW_PARALLAX_DRIFT * (0.10 + t * 0.06), size.x + tile_size * 5.0) - tile_size * 2.5
		var color := Color(accent.r, accent.g, accent.b, 0.035 + t * 0.020)
		_draw_stage_cloud_ribbon(size, y, drift, color)
	_draw_stage_distant_landmarks(size, horizon, Color(far.r, far.g, far.b, 0.28), accent)

func _draw_stage_cloud_ribbon(size: Vector2, y: float, drift: float, color: Color) -> void:
	var width := size.x * 0.30
	for i in range(4):
		var x := fposmod(drift + float(i) * size.x * 0.31, size.x + tile_size * 2.0) - tile_size
		var h := tile_size * (0.16 + float(i % 2) * 0.035)
		draw_rect(Rect2(Vector2(x, y + float(i % 3) * tile_size * 0.08), Vector2(width, h)), color, true)
		draw_line(Vector2(x + tile_size * 0.28, y + h), Vector2(x + width - tile_size * 0.32, y + h - tile_size * 0.06), Color(color.r, color.g, color.b, color.a * 1.4), 1.0)

func _draw_stage_distant_landmarks(size: Vector2, horizon: float, far_color: Color, accent: Color) -> void:
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	for i in range(SIDE_VIEW_BACKDROP_DETAIL_COUNT):
		var layer := i % SIDE_VIEW_PARALLAX_LAYER_COUNT
		var t := float(layer) / float(maxi(1, SIDE_VIEW_PARALLAX_LAYER_COUNT - 1))
		var speed := SIDE_VIEW_PARALLAX_DRIFT * (0.08 + t * 0.055)
		var x := fposmod(float(i * 211) - stage_visual_phase * tile_size * speed, size.x + tile_size * 2.0) - tile_size
		var y := horizon - tile_size * (0.95 - t * 0.30) + float((i * 7) % 5) * tile_size * 0.08
		var alpha := far_color.a * (0.42 + t * 0.48)
		var base := Color(far_color.r, far_color.g, far_color.b, alpha)
		if region_type == "city" or region_type == "town":
			_draw_stage_distant_roof(x, y, tile_size * (0.70 + float(i % 3) * 0.10), base, accent)
		elif region_type == "sect":
			_draw_stage_distant_pillar(x, y, base, accent)
		elif _terrain_has_water(terrain):
			_draw_stage_distant_sail(x, y + tile_size * 0.24, base, accent)
		elif _terrain_has_forest(terrain):
			draw_line(Vector2(x, y + tile_size * 0.54), Vector2(x + tile_size * 0.10, y - tile_size * (0.16 + t * 0.22)), base, 1.4 + t)
			draw_line(Vector2(x + tile_size * 0.08, y + tile_size * 0.12), Vector2(x + tile_size * 0.40, y - tile_size * 0.04), Color(accent.r, accent.g, accent.b, alpha * 0.44), 1.0)
		else:
			_draw_stage_distant_stone(x, y + tile_size * 0.26, base, accent)

func _draw_stage_distant_roof(x: float, y: float, width: float, color: Color, accent: Color) -> void:
	draw_rect(Rect2(Vector2(x + width * 0.18, y + tile_size * 0.24), Vector2(width * 0.64, tile_size * 0.42)), Color(color.r, color.g, color.b, color.a * 0.72), true)
	draw_polygon(PackedVector2Array([
		Vector2(x, y + tile_size * 0.28),
		Vector2(x + width * 0.50, y),
		Vector2(x + width, y + tile_size * 0.28),
		Vector2(x + width * 0.88, y + tile_size * 0.38),
		Vector2(x + width * 0.12, y + tile_size * 0.38)
	]), PackedColorArray([
		color,
		Color(accent.r, accent.g, accent.b, color.a * 0.48),
		color,
		Color(color.r, color.g, color.b, color.a * 0.88),
		Color(color.r, color.g, color.b, color.a * 0.88)
	]))

func _draw_stage_distant_pillar(x: float, y: float, color: Color, accent: Color) -> void:
	draw_rect(Rect2(Vector2(x, y), Vector2(tile_size * 0.10, tile_size * 0.72)), color, true)
	draw_line(Vector2(x - tile_size * 0.18, y + tile_size * 0.12), Vector2(x + tile_size * 0.36, y + tile_size * 0.08), Color(accent.r, accent.g, accent.b, color.a * 0.46), 1.2)

func _draw_stage_distant_sail(x: float, y: float, color: Color, accent: Color) -> void:
	draw_line(Vector2(x, y - tile_size * 0.42), Vector2(x, y + tile_size * 0.18), color, 1.1)
	draw_polygon(PackedVector2Array([
		Vector2(x + tile_size * 0.04, y - tile_size * 0.40),
		Vector2(x + tile_size * 0.44, y - tile_size * 0.10),
		Vector2(x + tile_size * 0.04, y + tile_size * 0.10)
	]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, color.a * 0.44),
		Color(color.r, color.g, color.b, color.a * 0.72),
		Color(color.r, color.g, color.b, color.a * 0.82)
	]))
	draw_line(Vector2(x - tile_size * 0.20, y + tile_size * 0.20), Vector2(x + tile_size * 0.48, y + tile_size * 0.16), Color(color.r, color.g, color.b, color.a * 0.74), 1.3)

func _draw_stage_distant_stone(x: float, y: float, color: Color, accent: Color) -> void:
	draw_polygon(PackedVector2Array([
		Vector2(x, y + tile_size * 0.25),
		Vector2(x + tile_size * 0.18, y - tile_size * 0.06),
		Vector2(x + tile_size * 0.58, y + tile_size * 0.02),
		Vector2(x + tile_size * 0.72, y + tile_size * 0.26)
	]), PackedColorArray([
		Color(color.r, color.g, color.b, color.a * 0.68),
		Color(accent.r, accent.g, accent.b, color.a * 0.30),
		color,
		Color(color.r, color.g, color.b, color.a * 0.78)
	]))

func _draw_stage_city_facades(size: Vector2, y: float, accent: Color) -> void:
	var wall_color := Color(0.055, 0.032, 0.020, SIDE_VIEW_MIDGROUND_STRUCTURE_ALPHA)
	draw_rect(Rect2(Vector2(0.0, y - tile_size * 0.86), Vector2(size.x, tile_size * 1.05)), Color(0.026, 0.016, 0.010, 0.24), true)
	for i in range(8):
		var w := tile_size * (1.40 + float(i % 3) * 0.28)
		var x := float(i) * size.x / 7.0 - tile_size * 0.46
		var h := tile_size * (0.80 + float((i + 1) % 3) * 0.16)
		var rect := Rect2(Vector2(x, y - h), Vector2(w, h))
		draw_rect(rect, wall_color, true)
		draw_rect(Rect2(rect.position + Vector2(tile_size * 0.10, tile_size * 0.16), Vector2(w - tile_size * 0.20, tile_size * 0.22)), Color(accent.r, accent.g, accent.b, 0.13), true)
		draw_line(Vector2(x, y), Vector2(x + w, y - tile_size * 0.04), Color(0.0, 0.0, 0.0, 0.25), 2.4)
		if i % 2 == 0:
			var sign := Rect2(Vector2(x + w * 0.34, y - h - tile_size * 0.22), Vector2(tile_size * 0.44, tile_size * 0.20))
			draw_rect(sign, Color(0.14, 0.055, 0.025, 0.62), true)
			draw_rect(sign.grow(-2.0), Color(accent.r, accent.g, accent.b, 0.22), true)
	for i in range(6):
		var pole_x := size.x * (0.10 + float(i) * 0.16)
		draw_line(Vector2(pole_x, y - tile_size * 0.82), Vector2(pole_x, y + tile_size * 0.20), Color(0.03, 0.020, 0.012, 0.38), 2.0)
		draw_circle(Vector2(pole_x + tile_size * 0.10, y - tile_size * 0.42), tile_size * 0.05, Color(1.0, 0.62, 0.22, 0.20))

func _draw_side_view_street_facades(size: Vector2, palette: Dictionary) -> void:
	var region_type := str(current_region.get("type", "wild"))
	if region_type == "city" or region_type == "town":
		_draw_stage_continuous_shopfronts(size, palette)
	elif region_type == "sect":
		_draw_stage_sect_hall_facade(size, palette)

func _draw_stage_continuous_shopfronts(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var base_y := size.y * 0.525
	var top_y := base_y - tile_size * 2.46
	draw_rect(Rect2(Vector2(0.0, top_y - tile_size * 0.26), Vector2(size.x, tile_size * 2.86)), Color(0.012, 0.008, 0.006, SIDE_VIEW_STREET_FACADE_ALPHA * 0.30), true)
	var unit_span := size.x / float(maxi(1, SIDE_VIEW_STREET_FACADE_COUNT - 1))
	for i in range(SIDE_VIEW_STREET_FACADE_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_STREET_FACADE_COUNT - 1))
		var x := lerpf(-tile_size * 1.18, size.x - tile_size * 0.26, t)
		var width := tile_size * (1.20 + float((i * 5) % 4) * 0.12)
		var height := tile_size * (1.42 + float((i * 7) % 5) * 0.13)
		var alpha := SIDE_VIEW_STREET_FACADE_ALPHA * (0.72 + float(i % 3) * 0.08)
		_draw_stage_shopfront_unit(x + unit_span * 0.05 * sin(float(i) * 1.41), base_y, width, height, accent, alpha, i)
	_draw_stage_street_roof_depth(size, base_y, accent)
	for i in range(SIDE_VIEW_STREET_SIGN_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_STREET_SIGN_COUNT - 1))
		var x := lerpf(tile_size * 0.42, size.x - tile_size * 0.42, t)
		var y := base_y - tile_size * (1.28 + float(i % 3) * 0.16)
		_draw_stage_street_hanging_sign(x, y, accent, SIDE_VIEW_STREET_FACADE_ALPHA * 0.78, i)

func _draw_stage_shopfront_unit(x: float, base_y: float, width: float, height: float, accent: Color, alpha: float, index: int) -> void:
	var side_depth := tile_size * (0.18 + float(index % 3) * 0.035)
	var top := base_y - height
	var wall_color := Color(0.045, 0.025, 0.014, alpha)
	var side_color := Color(0.022, 0.014, 0.009, alpha * 0.82)
	var trim_color := Color(accent.r, accent.g, accent.b, alpha * 0.25)
	var body := Rect2(Vector2(x, top), Vector2(width, height))
	draw_polygon(PackedVector2Array([
		body.position,
		body.position + Vector2(body.size.x, -side_depth * 0.18),
		body.position + body.size + Vector2(side_depth, -side_depth * 0.12),
		body.position + Vector2(0.0, body.size.y)
	]), PackedColorArray([
		wall_color.lightened(0.08),
		wall_color,
		side_color,
		wall_color.darkened(0.12)
	]))
	var roof_y := top - tile_size * 0.12
	draw_polygon(PackedVector2Array([
		Vector2(x - tile_size * 0.14, roof_y + tile_size * 0.32),
		Vector2(x + width * 0.50, roof_y - tile_size * 0.28),
		Vector2(x + width + tile_size * 0.22, roof_y + tile_size * 0.30),
		Vector2(x + width + side_depth, roof_y + tile_size * 0.48),
		Vector2(x - tile_size * 0.04, roof_y + tile_size * 0.54)
	]), PackedColorArray([
		Color(0.08, 0.038, 0.020, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.46),
		Color(0.06, 0.030, 0.018, alpha),
		Color(0.020, 0.012, 0.008, alpha * 0.95),
		Color(0.025, 0.014, 0.009, alpha * 0.95)
	]))
	var door_w := width * (0.28 + float(index % 2) * 0.08)
	var door_x := x + width * (0.36 + float((index + 1) % 3) * 0.06)
	draw_rect(Rect2(Vector2(door_x, base_y - height * 0.54), Vector2(door_w, height * 0.54)), Color(0.012, 0.008, 0.006, alpha * 0.78), true)
	draw_line(Vector2(door_x + door_w * 0.50, base_y - height * 0.50), Vector2(door_x + door_w * 0.50, base_y - tile_size * 0.10), Color(0.0, 0.0, 0.0, alpha * 0.36), 1.2)
	var window := Rect2(Vector2(x + width * 0.10, base_y - height * 0.70), Vector2(width * 0.28, height * 0.18))
	draw_rect(window, Color(accent.r, accent.g, accent.b, alpha * 0.15), true)
	draw_line(window.position + Vector2(window.size.x * 0.50, 0.0), window.position + Vector2(window.size.x * 0.50, window.size.y), Color(0.0, 0.0, 0.0, alpha * 0.24), 1.0)
	draw_line(Vector2(x, base_y - height * 0.34), Vector2(x + width + side_depth, base_y - height * 0.36), trim_color, 2.0)
	draw_line(Vector2(x + width + side_depth, top + tile_size * 0.20), Vector2(x + width + side_depth, base_y - tile_size * 0.10), Color(0.0, 0.0, 0.0, alpha * 0.26), 1.4)

func _draw_stage_street_roof_depth(size: Vector2, base_y: float, accent: Color) -> void:
	var roof_y := base_y - tile_size * 2.42
	draw_polygon(PackedVector2Array([
		Vector2(-tile_size * 0.50, roof_y + tile_size * 0.62),
		Vector2(size.x * 0.08, roof_y + tile_size * 0.26),
		Vector2(size.x * 0.92, roof_y + tile_size * 0.16),
		Vector2(size.x + tile_size * 0.60, roof_y + tile_size * 0.54),
		Vector2(size.x + tile_size * 0.35, roof_y + tile_size * 0.86),
		Vector2(-tile_size * 0.36, roof_y + tile_size * 0.98)
	]), PackedColorArray([
		Color(0.020, 0.012, 0.008, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA),
		Color(accent.r, accent.g, accent.b, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA * 0.40),
		Color(accent.r, accent.g, accent.b, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA * 0.34),
		Color(0.018, 0.011, 0.008, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA),
		Color(0.010, 0.007, 0.005, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA * 1.08),
		Color(0.012, 0.008, 0.006, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA * 1.04)
	]))
	for i in range(9):
		var t := float(i) / 8.0
		var x := lerpf(0.0, size.x, t)
		draw_line(Vector2(x, roof_y + tile_size * 0.50), Vector2(x + tile_size * 0.62, roof_y + tile_size * 0.83), Color(0.0, 0.0, 0.0, SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA * 0.34), 1.1)

func _draw_stage_street_hanging_sign(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var sway := sin(stage_visual_phase * 0.82 + float(index) * 0.67) * tile_size * 0.035
	draw_line(Vector2(x, y - tile_size * 0.38), Vector2(x + sway, y), Color(0.52, 0.34, 0.17, alpha * 0.90), 1.1)
	var sign_size := Vector2(tile_size * (0.38 + float(index % 3) * 0.06), tile_size * 0.22)
	var rect := Rect2(Vector2(x + sway - sign_size.x * 0.5, y), sign_size)
	draw_rect(rect, Color(0.11, 0.044, 0.022, alpha), true)
	draw_rect(rect.grow(-2.0), Color(accent.r, accent.g, accent.b, alpha * 0.34), true)
	if index % 2 == 0:
		var lamp := Vector2(x + sway + sign_size.x * 0.70, y + sign_size.y * 0.62)
		var pulse := 0.5 + sin(stage_visual_phase * 2.4 + float(index)) * 0.5
		draw_line(lamp + Vector2(0.0, -tile_size * 0.18), lamp, Color(0.72, 0.42, 0.18, alpha * 0.55), 1.0)
		draw_circle(lamp, tile_size * 0.055, Color(1.0, 0.66, 0.24, alpha * (0.36 + pulse * 0.16)))

func _draw_stage_sect_hall_facade(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var base_y := size.y * 0.525
	var center_x := size.x * 0.50
	var width := size.x * 0.54
	var height := tile_size * 2.20
	draw_rect(Rect2(Vector2(center_x - width * 0.50, base_y - height), Vector2(width, height)), Color(0.034, 0.026, 0.019, SIDE_VIEW_STREET_FACADE_ALPHA * 0.68), true)
	draw_polygon(PackedVector2Array([
		Vector2(center_x - width * 0.58, base_y - height + tile_size * 0.16),
		Vector2(center_x, base_y - height - tile_size * 0.58),
		Vector2(center_x + width * 0.58, base_y - height + tile_size * 0.16),
		Vector2(center_x + width * 0.48, base_y - height + tile_size * 0.44),
		Vector2(center_x - width * 0.48, base_y - height + tile_size * 0.44)
	]), PackedColorArray([
		Color(0.04, 0.030, 0.022, SIDE_VIEW_STREET_FACADE_ALPHA),
		Color(accent.r, accent.g, accent.b, SIDE_VIEW_STREET_FACADE_ALPHA * 0.48),
		Color(0.04, 0.030, 0.022, SIDE_VIEW_STREET_FACADE_ALPHA),
		Color(0.020, 0.016, 0.012, SIDE_VIEW_STREET_FACADE_ALPHA * 0.92),
		Color(0.020, 0.016, 0.012, SIDE_VIEW_STREET_FACADE_ALPHA * 0.92)
	]))
	for i in range(6):
		var t := float(i) / 5.0
		var x := lerpf(center_x - width * 0.42, center_x + width * 0.42, t)
		draw_rect(Rect2(Vector2(x - tile_size * 0.08, base_y - height * 0.66), Vector2(tile_size * 0.16, height * 0.66)), Color(0.018, 0.014, 0.010, SIDE_VIEW_STREET_FACADE_ALPHA * 0.78), true)
		draw_line(Vector2(x + tile_size * 0.06, base_y - height * 0.62), Vector2(x + tile_size * 0.06, base_y - tile_size * 0.14), Color(accent.r, accent.g, accent.b, SIDE_VIEW_STREET_FACADE_ALPHA * 0.16), 1.0)
	draw_arc(Vector2(center_x, base_y - tile_size * 0.20), tile_size * 2.15, PI * 0.08, PI * 0.92, 48, Color(accent.r, accent.g, accent.b, SIDE_VIEW_STREET_FACADE_ALPHA * 0.22), 2.0)

func _draw_side_view_upper_platforms(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var region_type := str(current_region.get("type", "wild"))
	var terrain := str(current_region.get("terrain", ""))
	var upper_y := size.y * 0.438
	var lower_y := size.y * 0.505
	var base_alpha := SIDE_VIEW_UPPER_WALKWAY_ALPHA
	if region_type == "city" or region_type == "town":
		_draw_stage_upper_city_balconies(size, upper_y, lower_y, accent, base_alpha)
	elif region_type == "sect":
		_draw_stage_upper_sect_terraces(size, upper_y, lower_y, accent, base_alpha)
	elif _terrain_has_water(terrain):
		_draw_stage_upper_boardwalk(size, upper_y + tile_size * 0.10, lower_y, accent, base_alpha)
	elif _terrain_has_forest(terrain):
		_draw_stage_upper_forest_walkway(size, upper_y, lower_y, accent, base_alpha)
	elif _terrain_has_mountain(terrain):
		_draw_stage_upper_rock_ledges(size, upper_y, lower_y, accent, base_alpha)
	else:
		_draw_stage_upper_low_platforms(size, upper_y, lower_y, accent, base_alpha)
	_draw_stage_stair_links(size, upper_y, lower_y, accent, base_alpha)
	_draw_stage_balcony_lanterns(size, upper_y, accent, base_alpha)

func _draw_stage_upper_city_balconies(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	var span := size.x / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT))
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var x := span * float(i) + tile_size * (0.20 + float(i % 2) * 0.22)
		var width := span * (0.80 + float((i + 1) % 3) * 0.08)
		var y := upper_y + sin(float(i) * 0.91) * tile_size * 0.035
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.34, accent, alpha * (0.82 + float(i % 2) * 0.10), i, "wood")
		var awning_y := y - tile_size * 0.36
		draw_polygon(PackedVector2Array([
			Vector2(x - tile_size * 0.18, awning_y + tile_size * 0.18),
			Vector2(x + width * 0.52, awning_y - tile_size * 0.18),
			Vector2(x + width + tile_size * 0.26, awning_y + tile_size * 0.17),
			Vector2(x + width + tile_size * 0.08, awning_y + tile_size * 0.33),
			Vector2(x, awning_y + tile_size * 0.35)
		]), PackedColorArray([
			Color(0.07, 0.032, 0.018, alpha * 0.76),
			Color(accent.r, accent.g, accent.b, alpha * 0.36),
			Color(0.06, 0.030, 0.016, alpha * 0.76),
			Color(0.018, 0.012, 0.008, alpha * 0.88),
			Color(0.022, 0.014, 0.009, alpha * 0.88)
		]))

func _draw_stage_upper_sect_terraces(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	var center_x := size.x * 0.50
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT - 1))
		var width := lerpf(size.x * 0.22, size.x * 0.46, 1.0 - absf(t - 0.5) * 1.4)
		var x := lerpf(size.x * 0.10, size.x * 0.66, t)
		var y := upper_y + tile_size * (0.08 + absf(t - 0.5) * 0.16)
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.30, accent, alpha * (0.76 + t * 0.12), i, "stone")
		draw_arc(Vector2(center_x, y + tile_size * 0.18), width * 0.44, PI * 0.08, PI * 0.92, 36, Color(accent.r, accent.g, accent.b, alpha * 0.22), 1.4)

func _draw_stage_upper_boardwalk(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT - 1))
		var x := lerpf(size.x * 0.03, size.x * 0.78, t)
		var width := size.x * (0.18 + float(i % 2) * 0.035)
		var y := upper_y + sin(float(i) * 1.17) * tile_size * 0.055
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.24, accent, alpha * 0.82, i, "wood")
		for post in range(3):
			var px := x + width * float(post) / 2.0
			draw_line(Vector2(px, y - tile_size * 0.16), Vector2(px - tile_size * 0.08, y + tile_size * 0.52), Color(0.025, 0.018, 0.012, alpha * 0.82), 1.8)

func _draw_stage_upper_forest_walkway(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var x := lerpf(size.x * 0.04, size.x * 0.82, float(i) / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT - 1)))
		var width := size.x * 0.16
		var y := upper_y + tile_size * (0.03 + float(i % 2) * 0.10)
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.22, accent, alpha * 0.72, i, "bamboo")
		draw_line(Vector2(x - tile_size * 0.16, y - tile_size * 0.28), Vector2(x + width + tile_size * 0.10, y - tile_size * 0.18), Color(0.05, 0.13, 0.045, alpha * 0.76), 1.7)

func _draw_stage_upper_rock_ledges(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var x := lerpf(size.x * 0.02, size.x * 0.80, float(i) / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT - 1)))
		var width := size.x * (0.15 + float((i + 1) % 3) * 0.03)
		var y := upper_y + tile_size * (0.08 + float(i % 3) * 0.06)
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.28, accent, alpha * 0.76, i, "stone")

func _draw_stage_upper_low_platforms(size: Vector2, upper_y: float, _lower_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_UPPER_WALKWAY_COUNT):
		var x := lerpf(size.x * 0.05, size.x * 0.80, float(i) / float(maxi(1, SIDE_VIEW_UPPER_WALKWAY_COUNT - 1)))
		var width := size.x * 0.16
		var y := upper_y + tile_size * float(i % 2) * 0.08
		_draw_stage_upper_platform_unit(x, y, width, tile_size * 0.22, accent, alpha * 0.66, i, "stone")

func _draw_stage_upper_platform_unit(x: float, y: float, width: float, depth: float, accent: Color, alpha: float, index: int, material: String) -> void:
	var lift := tile_size * 0.12
	var front_color := Color(0.036, 0.024, 0.015, alpha)
	var top_color := Color(0.058, 0.038, 0.022, alpha * 0.92)
	if material == "stone":
		front_color = Color(0.038, 0.036, 0.030, alpha)
		top_color = Color(0.070, 0.064, 0.050, alpha * 0.88)
	elif material == "bamboo":
		front_color = Color(0.028, 0.070, 0.025, alpha)
		top_color = Color(0.060, 0.120, 0.044, alpha * 0.88)
	draw_polygon(PackedVector2Array([
		Vector2(x, y - lift),
		Vector2(x + width, y - lift - tile_size * 0.08),
		Vector2(x + width + tile_size * 0.32, y + depth),
		Vector2(x - tile_size * 0.24, y + depth + tile_size * 0.06)
	]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, alpha * 0.24),
		top_color,
		front_color.darkened(0.20),
		front_color
	]))
	draw_line(Vector2(x - tile_size * 0.10, y + depth * 0.44), Vector2(x + width + tile_size * 0.20, y + depth * 0.30), Color(0.0, 0.0, 0.0, alpha * 0.52), 2.0)
	for post in range(4):
		var t := float(post) / 3.0
		var px := lerpf(x + tile_size * 0.08, x + width - tile_size * 0.08, t)
		var py := y - lift - tile_size * 0.05 * t
		draw_line(Vector2(px, py - tile_size * 0.38), Vector2(px, py + depth * 0.42), Color(0.018, 0.012, 0.008, alpha * 0.82), 1.6)
		if post < 3:
			var nx := lerpf(x + tile_size * 0.08, x + width - tile_size * 0.08, float(post + 1) / 3.0)
			draw_line(Vector2(px, py - tile_size * 0.23), Vector2(nx, py - tile_size * 0.27), Color(accent.r, accent.g, accent.b, alpha * 0.24), 1.2)
	for plank in range(3):
		var t := (float(plank) + 0.5) / 3.0
		var px := lerpf(x + width * 0.06, x + width * 0.92, t)
		draw_line(Vector2(px, y - lift), Vector2(px + tile_size * 0.22, y + depth * 0.72), Color(0.0, 0.0, 0.0, alpha * (0.18 + float(index % 2) * 0.04)), 0.9)

func _draw_stage_stair_links(size: Vector2, upper_y: float, lower_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_STAIR_LINK_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_STAIR_LINK_COUNT - 1))
		var side := -1.0 if i % 2 == 0 else 1.0
		var top := Vector2(lerpf(size.x * 0.20, size.x * 0.78, t), upper_y + tile_size * 0.22)
		var bottom := top + Vector2(side * tile_size * (1.15 + float(i % 2) * 0.32), lower_y - upper_y + tile_size * 0.36)
		var width := tile_size * 0.36
		draw_polygon(PackedVector2Array([
			top + Vector2(-width, -tile_size * 0.04),
			top + Vector2(width, -tile_size * 0.08),
			bottom + Vector2(width * 0.86, tile_size * 0.06),
			bottom + Vector2(-width * 0.86, tile_size * 0.12)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, alpha * 0.20),
			Color(0.058, 0.040, 0.026, alpha * 0.78),
			Color(0.020, 0.014, 0.010, alpha * 0.88),
			Color(0.030, 0.020, 0.014, alpha * 0.84)
		]))
		for step in range(6):
			var st := float(step) / 5.0
			var a := top.lerp(bottom, st)
			draw_line(a + Vector2(-width * (1.0 - st * 0.20), 0.0), a + Vector2(width * (1.0 - st * 0.20), -tile_size * 0.04), Color(0.0, 0.0, 0.0, alpha * (0.30 + st * 0.22)), 1.0 + st)
		draw_line(top + Vector2(-width * 1.15, -tile_size * 0.30), bottom + Vector2(-width * 0.92, -tile_size * 0.10), Color(accent.r, accent.g, accent.b, alpha * 0.28), 1.3)

func _draw_stage_balcony_lanterns(size: Vector2, upper_y: float, accent: Color, alpha: float) -> void:
	for i in range(SIDE_VIEW_BALCONY_LANTERN_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_BALCONY_LANTERN_COUNT - 1))
		var x := lerpf(size.x * 0.08, size.x * 0.92, t) + sin(float(i) * 1.23) * tile_size * 0.18
		var y := upper_y + tile_size * (0.04 + float(i % 3) * 0.08)
		var sway := sin(stage_visual_phase * 0.78 + float(i) * 0.71) * tile_size * 0.035
		var lamp := Vector2(x + sway, y + tile_size * 0.24)
		var pulse := 0.5 + sin(stage_visual_phase * 2.2 + float(i) * 0.57) * 0.5
		draw_line(Vector2(x, y - tile_size * 0.18), lamp, Color(0.42, 0.25, 0.13, alpha * 0.70), 1.0)
		draw_circle(lamp, tile_size * (0.16 + pulse * 0.06), Color(1.0, 0.56, 0.18, alpha * 0.070))
		draw_rect(Rect2(lamp - Vector2(tile_size * 0.055, tile_size * 0.060), Vector2(tile_size * 0.11, tile_size * 0.13)), Color(0.92, 0.30, 0.16, alpha * 0.58), true)
		draw_circle(lamp, tile_size * 0.034, Color(accent.r, accent.g, accent.b, alpha * (0.50 + pulse * 0.18)))

func _draw_side_view_living_silhouettes(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var lane_top := size.y * 0.535
	var lane_bottom := size.y * 0.705
	for i in range(SIDE_VIEW_LIVING_ACTOR_COUNT):
		var lane := i % 3
		var lane_t := float(lane) / 2.0
		var scale := lerpf(0.52, 0.90, lane_t)
		var direction := 1.0 if i % 2 == 0 else -0.76
		var speed := SIDE_VIEW_LIVING_ACTOR_SPEED * (0.68 + float((i * 5) % 7) * 0.055)
		var drift := stage_visual_phase * tile_size * speed * direction
		var seed_x := float((i * 173 + 47) % 1000) / 1000.0
		var x := fposmod(seed_x * size.x + drift, size.x + tile_size * 2.4) - tile_size * 1.2
		var y := lerpf(lane_top, lane_bottom, lane_t) + sin(stage_visual_phase * 0.34 + float(i) * 0.79) * tile_size * 0.035
		var alpha := SIDE_VIEW_LIVING_ACTOR_ALPHA * (0.50 + lane_t * 0.46)
		var role := _stage_living_actor_role(region_type, terrain, i)
		_draw_stage_living_actor(Vector2(x, y), scale, accent, alpha, i, role)
	if region_type == "city" or region_type == "town":
		_draw_stage_window_watchers(size, accent)
	elif region_type == "sect":
		_draw_stage_training_arcs(size, accent)
	elif _terrain_has_water(terrain):
		_draw_stage_living_boats(size, accent)

func _stage_living_actor_role(region_type: String, terrain: String, index: int) -> String:
	if region_type == "city" or region_type == "town":
		match index % 5:
			0:
				return "porter"
			1:
				return "vendor"
			2:
				return "guard"
			3:
				return "wanderer"
			_:
				return "pedestrian"
	if region_type == "sect":
		return "disciple" if index % 3 != 0 else "meditate"
	if _terrain_has_water(terrain):
		return "boatman" if index % 2 == 0 else "traveler"
	if _terrain_has_forest(terrain):
		return "traveler" if index % 2 == 0 else "herbalist"
	if _terrain_has_mountain(terrain):
		return "guard" if index % 4 == 0 else "traveler"
	return "wanderer"

func _draw_stage_living_actor(pos: Vector2, scale: float, accent: Color, alpha: float, index: int, role: String) -> void:
	var bob := sin(stage_visual_phase * (1.2 + float(index % 3) * 0.14) + float(index) * 0.81) * tile_size * 0.018 * scale
	var foot := pos + Vector2(0.0, bob)
	var height := tile_size * 0.58 * scale
	var body_width := tile_size * 0.15 * scale
	var head_radius := tile_size * 0.052 * scale
	var shoulder := foot + Vector2(0.0, -height * 0.66)
	var head := foot + Vector2(0.0, -height * 0.92)
	var ink := Color(0.010, 0.008, 0.006, alpha)
	var cloth := Color(accent.r, accent.g, accent.b, alpha * 0.34)
	draw_line(foot + Vector2(-body_width * 1.25, tile_size * 0.05 * scale), foot + Vector2(body_width * 1.35, tile_size * 0.01 * scale), Color(0.0, 0.0, 0.0, alpha * 0.42), maxf(1.0, tile_size * 0.020 * scale))
	draw_polygon(PackedVector2Array([
		shoulder + Vector2(-body_width, -tile_size * 0.02 * scale),
		shoulder + Vector2(body_width * 0.92, -tile_size * 0.04 * scale),
		foot + Vector2(body_width * 0.82, -tile_size * 0.13 * scale),
		foot + Vector2(body_width * 0.25, 0.0),
		foot + Vector2(-body_width * 0.78, -tile_size * 0.08 * scale)
	]), PackedColorArray([
		cloth,
		ink.lightened(0.16),
		ink,
		Color(0.0, 0.0, 0.0, alpha * 0.92),
		ink
	]))
	draw_circle(head, head_radius, ink.lightened(0.10))
	draw_line(shoulder + Vector2(-body_width * 0.74, tile_size * 0.03 * scale), foot + Vector2(-body_width * 1.04, -height * 0.30), Color(0.0, 0.0, 0.0, alpha * 0.80), maxf(1.0, tile_size * 0.018 * scale))
	draw_line(shoulder + Vector2(body_width * 0.80, tile_size * 0.03 * scale), foot + Vector2(body_width * 1.08, -height * 0.34), Color(0.0, 0.0, 0.0, alpha * 0.76), maxf(1.0, tile_size * 0.018 * scale))
	draw_line(foot + Vector2(-body_width * 0.42, -height * 0.16), foot + Vector2(-body_width * 0.92, tile_size * 0.02 * scale), Color(0.0, 0.0, 0.0, alpha * 0.82), maxf(1.0, tile_size * 0.018 * scale))
	draw_line(foot + Vector2(body_width * 0.36, -height * 0.16), foot + Vector2(body_width * 0.88, tile_size * 0.01 * scale), Color(0.0, 0.0, 0.0, alpha * 0.76), maxf(1.0, tile_size * 0.018 * scale))
	match role:
		"porter":
			_draw_stage_actor_porter_prop(shoulder, body_width, scale, alpha)
		"vendor":
			_draw_stage_actor_vendor_prop(shoulder, body_width, accent, scale, alpha)
		"guard":
			_draw_stage_actor_weapon_prop(shoulder, body_width, accent, scale, alpha)
		"disciple":
			_draw_stage_actor_training_prop(shoulder, body_width, accent, scale, alpha, index)
		"meditate":
			_draw_stage_actor_meditation_prop(foot, accent, scale, alpha, index)
		"boatman":
			_draw_stage_actor_boat_oar(shoulder, body_width, scale, alpha)
		"herbalist":
			_draw_stage_actor_herb_prop(foot, body_width, accent, scale, alpha)
		"traveler", "wanderer":
			_draw_stage_actor_travel_prop(foot, body_width, scale, alpha)

func _draw_stage_actor_porter_prop(shoulder: Vector2, body_width: float, scale: float, alpha: float) -> void:
	var y := shoulder.y - tile_size * 0.03 * scale
	draw_line(shoulder + Vector2(-body_width * 2.6, 0.0), shoulder + Vector2(body_width * 2.9, -tile_size * 0.08 * scale), Color(0.0, 0.0, 0.0, alpha * 0.72), maxf(1.0, tile_size * 0.016 * scale))
	draw_circle(shoulder + Vector2(-body_width * 3.0, tile_size * 0.08 * scale), tile_size * 0.055 * scale, Color(0.33, 0.20, 0.10, alpha * 0.62))
	draw_circle(Vector2(shoulder.x + body_width * 3.1, y + tile_size * 0.13 * scale), tile_size * 0.052 * scale, Color(0.33, 0.20, 0.10, alpha * 0.58))

func _draw_stage_actor_vendor_prop(shoulder: Vector2, body_width: float, accent: Color, scale: float, alpha: float) -> void:
	var tray := shoulder + Vector2(body_width * 2.2, tile_size * 0.12 * scale)
	draw_line(shoulder + Vector2(body_width * 0.6, tile_size * 0.03 * scale), tray, Color(0.0, 0.0, 0.0, alpha * 0.76), maxf(1.0, tile_size * 0.016 * scale))
	draw_rect(Rect2(tray - Vector2(tile_size * 0.095, tile_size * 0.026) * scale, Vector2(tile_size * 0.19, tile_size * 0.052) * scale), Color(0.40, 0.23, 0.11, alpha * 0.64), true)
	draw_circle(tray + Vector2(tile_size * 0.03, -tile_size * 0.06) * scale, tile_size * 0.032 * scale, Color(accent.r, accent.g, accent.b, alpha * 0.50))

func _draw_stage_actor_weapon_prop(shoulder: Vector2, body_width: float, accent: Color, scale: float, alpha: float) -> void:
	var start := shoulder + Vector2(body_width * 1.2, tile_size * 0.06 * scale)
	var end := start + Vector2(tile_size * 0.25 * scale, -tile_size * 0.62 * scale)
	draw_line(start, end, Color(0.0, 0.0, 0.0, alpha * 0.84), maxf(1.0, tile_size * 0.014 * scale))
	draw_line(end - Vector2(tile_size * 0.06, -tile_size * 0.08) * scale, end + Vector2(tile_size * 0.07, tile_size * 0.04) * scale, Color(accent.r, accent.g, accent.b, alpha * 0.56), maxf(1.0, tile_size * 0.012 * scale))

func _draw_stage_actor_training_prop(shoulder: Vector2, body_width: float, accent: Color, scale: float, alpha: float, index: int) -> void:
	var hand := shoulder + Vector2(body_width * 1.8, tile_size * 0.08 * scale)
	var blade := hand + Vector2(tile_size * (0.34 + float(index % 2) * 0.08) * scale, -tile_size * 0.18 * scale)
	draw_line(hand, blade, Color(accent.r, accent.g, accent.b, alpha * 0.62), maxf(1.0, tile_size * 0.018 * scale))
	draw_arc(hand, tile_size * 0.25 * scale, -0.58, 0.42, 14, Color(accent.r, accent.g, accent.b, alpha * 0.28), maxf(1.0, tile_size * 0.010 * scale))

func _draw_stage_actor_meditation_prop(foot: Vector2, accent: Color, scale: float, alpha: float, index: int) -> void:
	var pulse := 0.5 + sin(stage_visual_phase * 1.6 + float(index)) * 0.5
	draw_arc(foot + Vector2(0.0, -tile_size * 0.16 * scale), tile_size * (0.20 + pulse * 0.035) * scale, PI * 0.06, PI * 0.94, 24, Color(accent.r, accent.g, accent.b, alpha * 0.30), maxf(1.0, tile_size * 0.012 * scale))

func _draw_stage_actor_boat_oar(shoulder: Vector2, body_width: float, scale: float, alpha: float) -> void:
	var start := shoulder + Vector2(-body_width * 0.8, tile_size * 0.04 * scale)
	var end := start + Vector2(-tile_size * 0.40 * scale, tile_size * 0.52 * scale)
	draw_line(start, end, Color(0.0, 0.0, 0.0, alpha * 0.70), maxf(1.0, tile_size * 0.014 * scale))
	draw_line(end, end + Vector2(tile_size * 0.12, tile_size * 0.03) * scale, Color(0.60, 0.38, 0.17, alpha * 0.52), maxf(1.0, tile_size * 0.018 * scale))

func _draw_stage_actor_herb_prop(foot: Vector2, body_width: float, accent: Color, scale: float, alpha: float) -> void:
	var basket := foot + Vector2(body_width * 1.7, -tile_size * 0.12 * scale)
	draw_circle(basket, tile_size * 0.070 * scale, Color(0.26, 0.18, 0.09, alpha * 0.62))
	draw_line(basket, basket + Vector2(tile_size * 0.08, -tile_size * 0.12) * scale, Color(accent.r, accent.g, accent.b, alpha * 0.46), maxf(1.0, tile_size * 0.012 * scale))
	draw_line(basket, basket + Vector2(-tile_size * 0.06, -tile_size * 0.10) * scale, Color(0.08, 0.18, 0.06, alpha * 0.52), maxf(1.0, tile_size * 0.012 * scale))

func _draw_stage_actor_travel_prop(foot: Vector2, body_width: float, scale: float, alpha: float) -> void:
	var bag := foot + Vector2(-body_width * 1.45, -tile_size * 0.29 * scale)
	draw_circle(bag, tile_size * 0.060 * scale, Color(0.22, 0.13, 0.07, alpha * 0.66))
	draw_line(bag + Vector2(tile_size * 0.03, -tile_size * 0.05) * scale, foot + Vector2(-body_width * 0.2, -tile_size * 0.45 * scale), Color(0.0, 0.0, 0.0, alpha * 0.50), maxf(1.0, tile_size * 0.010 * scale))

func _draw_stage_window_watchers(size: Vector2, accent: Color) -> void:
	for i in range(6):
		var t := float(i) / 5.0
		var x := lerpf(size.x * 0.08, size.x * 0.90, t) + sin(float(i) * 0.88) * tile_size * 0.28
		var y := size.y * (0.362 + float(i % 2) * 0.036)
		var pulse := 0.5 + sin(stage_visual_phase * 1.5 + float(i) * 0.7) * 0.5
		draw_rect(Rect2(Vector2(x - tile_size * 0.13, y - tile_size * 0.17), Vector2(tile_size * 0.26, tile_size * 0.25)), Color(0.02, 0.014, 0.010, SIDE_VIEW_LIVING_ACTOR_ALPHA * 0.42), true)
		draw_circle(Vector2(x, y - tile_size * 0.03), tile_size * 0.050, Color(0.0, 0.0, 0.0, SIDE_VIEW_LIVING_ACTOR_ALPHA * 0.58))
		draw_line(Vector2(x - tile_size * 0.06, y + tile_size * 0.05), Vector2(x + tile_size * 0.07, y + tile_size * 0.05), Color(accent.r, accent.g, accent.b, SIDE_VIEW_LIVING_ACTOR_ALPHA * (0.22 + pulse * 0.10)), 1.0)

func _draw_stage_training_arcs(size: Vector2, accent: Color) -> void:
	for i in range(SIDE_VIEW_LIVING_ACTION_ARC_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_LIVING_ACTION_ARC_COUNT - 1))
		var center := Vector2(lerpf(size.x * 0.14, size.x * 0.86, t), size.y * (0.51 + float(i % 2) * 0.08))
		var phase := sin(stage_visual_phase * 1.3 + float(i) * 0.74)
		draw_arc(center, tile_size * (0.32 + float(i % 3) * 0.035), -0.52 + phase * 0.05, 0.56 + phase * 0.05, 16, Color(accent.r, accent.g, accent.b, SIDE_VIEW_LIVING_ACTOR_ALPHA * 0.20), 1.2)

func _draw_stage_living_boats(size: Vector2, accent: Color) -> void:
	for i in range(4):
		var x := fposmod(float(i * 263) - stage_visual_phase * tile_size * 0.13, size.x + tile_size * 2.0) - tile_size
		var y := size.y * (0.575 + float(i % 2) * 0.052)
		var alpha := SIDE_VIEW_LIVING_ACTOR_ALPHA * 0.46
		draw_polygon(PackedVector2Array([
			Vector2(x - tile_size * 0.38, y),
			Vector2(x + tile_size * 0.54, y - tile_size * 0.04),
			Vector2(x + tile_size * 0.34, y + tile_size * 0.17),
			Vector2(x - tile_size * 0.26, y + tile_size * 0.18)
		]), PackedColorArray([
			Color(0.04, 0.026, 0.016, alpha),
			Color(accent.r, accent.g, accent.b, alpha * 0.34),
			Color(0.018, 0.012, 0.008, alpha * 1.06),
			Color(0.026, 0.016, 0.010, alpha)
		]))
		_draw_stage_living_actor(Vector2(x + tile_size * 0.08, y - tile_size * 0.02), 0.46, accent, SIDE_VIEW_LIVING_ACTOR_ALPHA * 0.48, i, "boatman")

func _draw_stage_sect_steps(size: Vector2, y: float, accent: Color) -> void:
	var center_x := size.x * 0.50
	for i in range(5):
		var t := float(i) / 4.0
		var width := lerpf(size.x * 0.34, size.x * 0.86, t)
		var step_y := y - tile_size * 0.18 + float(i) * tile_size * 0.18
		draw_polygon(PackedVector2Array([
			Vector2(center_x - width * 0.5, step_y),
			Vector2(center_x + width * 0.5, step_y - tile_size * 0.04),
			Vector2(center_x + width * 0.5 + tile_size * 0.16, step_y + tile_size * 0.14),
			Vector2(center_x - width * 0.5 - tile_size * 0.16, step_y + tile_size * 0.14)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, 0.09 + t * 0.04),
			Color(accent.r, accent.g, accent.b, 0.08 + t * 0.035),
			Color(0.0, 0.0, 0.0, 0.18 + t * 0.06),
			Color(0.0, 0.0, 0.0, 0.20 + t * 0.06)
		]))
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var pole_x := center_x + side * size.x * 0.28
		draw_line(Vector2(pole_x, y - tile_size * 1.34), Vector2(pole_x, y + tile_size * 0.45), Color(0.050, 0.038, 0.028, 0.50), 4.0)
		var banner := PackedVector2Array([
			Vector2(pole_x, y - tile_size * 1.22),
			Vector2(pole_x + side * tile_size * 0.74, y - tile_size * 1.02),
			Vector2(pole_x + side * tile_size * 0.62, y - tile_size * 0.48),
			Vector2(pole_x, y - tile_size * 0.60)
		])
		draw_polygon(banner, PackedColorArray([
			Color(accent.r, accent.g, accent.b, 0.30),
			Color(accent.r, accent.g, accent.b, 0.22),
			Color(0.02, 0.016, 0.012, 0.26),
			Color(0.02, 0.016, 0.012, 0.30)
		]))
	draw_arc(Vector2(center_x, y - tile_size * 0.12), tile_size * 2.7, PI * 0.08, PI * 0.92, 48, Color(accent.r, accent.g, accent.b, 0.14), 2.0)

func _draw_stage_pier(size: Vector2, y: float, accent: Color) -> void:
	for i in range(7):
		var t := float(i) / 6.0
		var left := lerpf(size.x * 0.18, size.x * 0.04, t)
		var right := lerpf(size.x * 0.82, size.x * 0.96, t)
		var py := y + tile_size * (0.10 + t * 0.46)
		draw_line(Vector2(left, py), Vector2(right, py - tile_size * 0.09), Color(0.06, 0.042, 0.026, 0.24 + t * 0.10), 2.0 + t * 1.8)
	for i in range(9):
		var x := size.x * (0.10 + float(i) * 0.10)
		var top := y - tile_size * (0.30 + float(i % 2) * 0.10)
		draw_line(Vector2(x, top), Vector2(x - tile_size * 0.10, y + tile_size * 0.82), Color(0.035, 0.026, 0.018, 0.36), 2.4)
		draw_circle(Vector2(x, top), tile_size * 0.045, Color(accent.r, accent.g, accent.b, 0.16))

func _draw_stage_forest_trunks(size: Vector2, y: float, accent: Color) -> void:
	for i in range(10):
		var x := fposmod(float(i * 269), size.x + tile_size * 2.0) - tile_size
		var height := tile_size * (1.55 + float(i % 4) * 0.34)
		var lean := sin(float(i) * 1.2) * tile_size * 0.20
		draw_line(Vector2(x, y + tile_size * 0.68), Vector2(x + lean, y - height), Color(0.006, 0.040, 0.015, 0.30 + float(i % 3) * 0.035), 4.0 + float(i % 3))
		draw_line(Vector2(x + lean, y - height * 0.54), Vector2(x + lean + tile_size * 0.72, y - height * 0.72), Color(accent.r, accent.g, accent.b, 0.12), 1.8)
	for i in range(7):
		var x := size.x * (0.08 + float(i) * 0.14)
		_draw_ellipse_poly(Vector2(x, y + tile_size * 0.52), Vector2(tile_size * 0.36, tile_size * 0.08), Color(accent.r, accent.g, accent.b, 0.08))

func _draw_stage_ice_ridge(size: Vector2, y: float, accent: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(Vector2(0.0, y + tile_size * 0.48))
	colors.append(Color(0.60, 0.75, 0.84, 0.22))
	for i in range(12):
		var x := size.x * float(i) / 11.0
		var peak := y - tile_size * (0.20 + float((i * 7) % 5) * 0.08)
		points.append(Vector2(x, peak))
		colors.append(Color(accent.r, accent.g, accent.b, 0.18 + float(i % 3) * 0.025))
	points.append(Vector2(size.x, y + tile_size * 0.48))
	colors.append(Color(0.35, 0.48, 0.58, 0.18))
	draw_polygon(points, colors)
	for i in range(8):
		var x := size.x * (0.06 + float(i) * 0.13)
		draw_line(Vector2(x, y - tile_size * 0.08), Vector2(x + tile_size * 0.42, y + tile_size * 0.24), Color(0.90, 0.98, 1.0, 0.18), 1.2)

func _draw_stage_desert_markers(size: Vector2, y: float, accent: Color) -> void:
	for i in range(6):
		var x := size.x * (0.10 + float(i) * 0.17)
		var h := tile_size * (0.70 + float(i % 3) * 0.22)
		draw_rect(Rect2(Vector2(x, y - h), Vector2(tile_size * 0.16, h + tile_size * 0.34)), Color(0.18, 0.11, 0.055, 0.30), true)
		draw_polygon(PackedVector2Array([
			Vector2(x - tile_size * 0.12, y - h),
			Vector2(x + tile_size * 0.08, y - h - tile_size * 0.18),
			Vector2(x + tile_size * 0.30, y - h),
			Vector2(x + tile_size * 0.26, y - h + tile_size * 0.08),
			Vector2(x - tile_size * 0.08, y - h + tile_size * 0.08)
		]), PackedColorArray([
			Color(0.22, 0.14, 0.07, 0.30),
			Color(accent.r, accent.g, accent.b, 0.20),
			Color(0.16, 0.10, 0.05, 0.30),
			Color(0.12, 0.08, 0.04, 0.32),
			Color(0.14, 0.09, 0.04, 0.32)
		]))
	_draw_stage_low_horizon_props(size, y + tile_size * 0.16, accent)

func _draw_stage_rock_terrace(size: Vector2, y: float, accent: Color) -> void:
	for i in range(9):
		var x := size.x * float(i) / 8.0 - tile_size * 0.35
		var w := tile_size * (0.70 + float(i % 3) * 0.20)
		var h := tile_size * (0.22 + float((i + 1) % 3) * 0.10)
		draw_polygon(PackedVector2Array([
			Vector2(x, y + tile_size * 0.32),
			Vector2(x + w * 0.22, y - h),
			Vector2(x + w, y - h * 0.48),
			Vector2(x + w * 1.15, y + tile_size * 0.30)
		]), PackedColorArray([
			Color(0.04, 0.038, 0.030, 0.30),
			Color(accent.r, accent.g, accent.b, 0.12),
			Color(0.07, 0.060, 0.045, 0.28),
			Color(0.02, 0.018, 0.014, 0.32)
		]))

func _draw_stage_low_horizon_props(size: Vector2, y: float, accent: Color) -> void:
	for i in range(8):
		var x := size.x * (0.06 + float(i) * 0.13)
		var height := tile_size * (0.28 + float(i % 3) * 0.08)
		_draw_ellipse_poly(Vector2(x, y + tile_size * 0.20), Vector2(tile_size * (0.30 + float(i % 2) * 0.08), tile_size * 0.08), Color(0.0, 0.0, 0.0, 0.12))
		draw_line(Vector2(x, y + tile_size * 0.18), Vector2(x + tile_size * 0.10, y - height), Color(accent.r, accent.g, accent.b, 0.12), 1.6)

func _draw_side_view_setpiece_row(size: Vector2, palette: Dictionary) -> void:
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var accent: Color = palette["accent"]
	var base_y := size.y * 0.565
	for band in range(SIDE_VIEW_SETPIECE_DEPTH_BANDS):
		var band_t := float(band) / float(maxi(1, SIDE_VIEW_SETPIECE_DEPTH_BANDS - 1))
		var y := base_y + tile_size * (-0.30 + band_t * 0.52)
		var band_alpha := SIDE_VIEW_SETPIECE_ALPHA * (0.42 + band_t * 0.42)
		var shadow := Color(0.0, 0.0, 0.0, band_alpha * 0.22)
		draw_line(Vector2(size.x * 0.05, y + tile_size * 0.18), Vector2(size.x * 0.95, y + tile_size * 0.08), shadow, 2.0 + band_t * 2.0)
		for i in range(SIDE_VIEW_SETPIECE_COUNT):
			if (i + band) % 2 == 1:
				continue
			var t := float(i) / float(maxi(1, SIDE_VIEW_SETPIECE_COUNT - 1))
			var drift := sin(stage_visual_phase * 0.18 + float(i) * 0.73 + float(band)) * tile_size * 0.035 * (1.0 - band_t * 0.34)
			var x := lerpf(-tile_size * 0.52, size.x + tile_size * 0.36, t) + drift
			var setpiece_scale := 0.74 + band_t * 0.28 + float((i * 7 + band) % 5) * 0.035
			var alpha := band_alpha * (0.72 + float(i % 3) * 0.08)
			if region_type == "city" or region_type == "town":
				_draw_stage_setpiece_shopfront(x, y, setpiece_scale, accent, alpha, i)
			elif region_type == "sect":
				_draw_stage_setpiece_pillar(x, y, setpiece_scale, accent, alpha, i)
			elif _terrain_has_water(terrain):
				_draw_stage_setpiece_dock(x, y, setpiece_scale, accent, alpha, i)
			elif _terrain_has_forest(terrain):
				_draw_stage_setpiece_tree(x, y, setpiece_scale, accent, alpha, i)
			elif terrain.contains("snow"):
				_draw_stage_setpiece_ice(x, y, setpiece_scale, accent, alpha, i)
			elif terrain.contains("desert"):
				_draw_stage_setpiece_canopy(x, y, setpiece_scale, accent, alpha, i)
			else:
				_draw_stage_setpiece_stone(x, y, setpiece_scale, accent, alpha, i)

func _draw_stage_setpiece_shopfront(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var width := tile_size * (1.02 + float(index % 3) * 0.14) * scale
	var height := tile_size * (0.96 + float((index + 1) % 3) * 0.13) * scale
	var wall := Rect2(Vector2(x - width * 0.50, y - height), Vector2(width, height))
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.11 * scale), Vector2(width * 0.42, tile_size * 0.070 * scale), Color(0.0, 0.0, 0.0, alpha * 0.32))
	draw_rect(wall, Color(0.045, 0.025, 0.014, alpha * 0.70), true)
	draw_rect(Rect2(wall.position + Vector2(width * 0.12, height * 0.36), Vector2(width * 0.76, height * 0.22)), Color(accent.r, accent.g, accent.b, alpha * 0.22), true)
	draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.62, y - height + tile_size * 0.14 * scale),
		Vector2(x, y - height - tile_size * 0.26 * scale),
		Vector2(x + width * 0.62, y - height + tile_size * 0.14 * scale),
		Vector2(x + width * 0.50, y - height + tile_size * 0.30 * scale),
		Vector2(x - width * 0.50, y - height + tile_size * 0.30 * scale)
	]), PackedColorArray([
		Color(0.08, 0.040, 0.022, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.42),
		Color(0.07, 0.035, 0.020, alpha),
		Color(0.025, 0.015, 0.010, alpha * 0.92),
		Color(0.025, 0.015, 0.010, alpha * 0.92)
	]))
	if index % 3 == 0:
		draw_circle(Vector2(x + width * 0.28, y - height * 0.44), tile_size * 0.055 * scale, Color(1.0, 0.58, 0.20, alpha * 0.48))

func _draw_stage_setpiece_pillar(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var height := tile_size * (1.42 + float(index % 3) * 0.18) * scale
	var width := tile_size * 0.20 * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.10 * scale), Vector2(tile_size * 0.34 * scale, tile_size * 0.060 * scale), Color(0.0, 0.0, 0.0, alpha * 0.30))
	draw_rect(Rect2(Vector2(x - width * 0.5, y - height), Vector2(width, height)), Color(0.036, 0.030, 0.024, alpha), true)
	draw_rect(Rect2(Vector2(x - width * 1.20, y - height), Vector2(width * 2.40, tile_size * 0.14 * scale)), Color(accent.r, accent.g, accent.b, alpha * 0.30), true)
	draw_line(Vector2(x + width * 0.20, y - height + tile_size * 0.12 * scale), Vector2(x + width * 0.20, y - tile_size * 0.10 * scale), Color(accent.r, accent.g, accent.b, alpha * 0.20), 1.2)
	if index % 2 == 0:
		draw_polygon(PackedVector2Array([
			Vector2(x + width * 0.65, y - height * 0.84),
			Vector2(x + width * 3.1, y - height * 0.74),
			Vector2(x + width * 2.7, y - height * 0.46),
			Vector2(x + width * 0.65, y - height * 0.52)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, alpha * 0.50),
			Color(accent.r, accent.g, accent.b, alpha * 0.32),
			Color(0.018, 0.014, 0.010, alpha * 0.42),
			Color(0.018, 0.014, 0.010, alpha * 0.48)
		]))

func _draw_stage_setpiece_dock(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var h := tile_size * (0.92 + float(index % 3) * 0.13) * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.13 * scale), Vector2(tile_size * 0.40 * scale, tile_size * 0.050 * scale), Color(0.0, 0.0, 0.0, alpha * 0.24))
	draw_line(Vector2(x, y - h), Vector2(x - tile_size * 0.10 * scale, y + tile_size * 0.24 * scale), Color(0.035, 0.025, 0.016, alpha), 2.0 * scale)
	draw_line(Vector2(x - tile_size * 0.40 * scale, y - h * 0.70), Vector2(x + tile_size * 0.52 * scale, y - h * 0.78), Color(0.06, 0.046, 0.026, alpha * 0.86), 2.0 * scale)
	draw_line(Vector2(x - tile_size * 0.36 * scale, y - h * 0.40), Vector2(x + tile_size * 0.44 * scale, y - h * 0.48), Color(accent.r, accent.g, accent.b, alpha * 0.28), 1.2)
	if index % 4 == 0:
		draw_polygon(PackedVector2Array([
			Vector2(x + tile_size * 0.18 * scale, y - h * 1.10),
			Vector2(x + tile_size * 0.62 * scale, y - h * 0.88),
			Vector2(x + tile_size * 0.20 * scale, y - h * 0.62)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, alpha * 0.34),
			Color(0.78, 0.92, 0.94, alpha * 0.24),
			Color(0.20, 0.36, 0.38, alpha * 0.26)
		]))

func _draw_stage_setpiece_tree(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var height := tile_size * (1.26 + float(index % 4) * 0.18) * scale
	var lean := sin(float(index) * 1.13) * tile_size * 0.16 * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.10 * scale), Vector2(tile_size * 0.34 * scale, tile_size * 0.060 * scale), Color(0.0, 0.0, 0.0, alpha * 0.30))
	draw_line(Vector2(x, y), Vector2(x + lean, y - height), Color(0.006, 0.034, 0.014, alpha), 3.0 * scale)
	draw_line(Vector2(x + lean * 0.72, y - height * 0.62), Vector2(x + lean + tile_size * 0.56 * scale, y - height * 0.78), Color(accent.r, accent.g, accent.b, alpha * 0.34), 1.5)
	_draw_ellipse_poly(Vector2(x + lean + tile_size * 0.22 * scale, y - height * 0.86), Vector2(tile_size * 0.36 * scale, tile_size * 0.13 * scale), Color(0.02, 0.09, 0.032, alpha * 0.42))

func _draw_stage_setpiece_ice(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var height := tile_size * (0.78 + float(index % 3) * 0.15) * scale
	var width := tile_size * (0.52 + float((index + 1) % 3) * 0.09) * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.08 * scale), Vector2(width * 0.48, tile_size * 0.050 * scale), Color(0.0, 0.0, 0.0, alpha * 0.20))
	draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.45, y),
		Vector2(x - width * 0.10, y - height),
		Vector2(x + width * 0.42, y - height * 0.70),
		Vector2(x + width * 0.50, y + tile_size * 0.06 * scale)
	]), PackedColorArray([
		Color(0.56, 0.70, 0.78, alpha * 0.54),
		Color(0.86, 0.96, 1.0, alpha * 0.58),
		Color(accent.r, accent.g, accent.b, alpha * 0.42),
		Color(0.32, 0.42, 0.50, alpha * 0.46)
	]))
	draw_line(Vector2(x - width * 0.02, y - height * 0.82), Vector2(x + width * 0.24, y - height * 0.10), Color(1.0, 1.0, 1.0, alpha * 0.32), 1.0)

func _draw_stage_setpiece_canopy(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var width := tile_size * (0.90 + float(index % 3) * 0.14) * scale
	var height := tile_size * 0.84 * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.09 * scale), Vector2(width * 0.46, tile_size * 0.055 * scale), Color(0.0, 0.0, 0.0, alpha * 0.24))
	draw_line(Vector2(x - width * 0.36, y - height * 0.70), Vector2(x - width * 0.30, y), Color(0.12, 0.075, 0.034, alpha), 1.8)
	draw_line(Vector2(x + width * 0.36, y - height * 0.68), Vector2(x + width * 0.30, y), Color(0.12, 0.075, 0.034, alpha), 1.8)
	draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.50, y - height * 0.72),
		Vector2(x - width * 0.04, y - height * 0.98),
		Vector2(x + width * 0.52, y - height * 0.76),
		Vector2(x + width * 0.42, y - height * 0.60),
		Vector2(x - width * 0.42, y - height * 0.58)
	]), PackedColorArray([
		Color(0.18, 0.10, 0.045, alpha * 0.72),
		Color(accent.r, accent.g, accent.b, alpha * 0.38),
		Color(0.16, 0.09, 0.04, alpha * 0.72),
		Color(0.09, 0.055, 0.030, alpha * 0.82),
		Color(0.10, 0.060, 0.032, alpha * 0.84)
	]))

func _draw_stage_setpiece_stone(x: float, y: float, scale: float, accent: Color, alpha: float, index: int) -> void:
	var width := tile_size * (0.60 + float(index % 3) * 0.12) * scale
	var height := tile_size * (0.46 + float((index + 2) % 3) * 0.10) * scale
	_draw_ellipse_poly(Vector2(x, y + tile_size * 0.08 * scale), Vector2(width * 0.52, tile_size * 0.055 * scale), Color(0.0, 0.0, 0.0, alpha * 0.28))
	draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.52, y + tile_size * 0.02 * scale),
		Vector2(x - width * 0.20, y - height),
		Vector2(x + width * 0.42, y - height * 0.78),
		Vector2(x + width * 0.58, y - height * 0.08),
		Vector2(x + width * 0.12, y + tile_size * 0.08 * scale)
	]), PackedColorArray([
		Color(0.025, 0.023, 0.020, alpha * 0.90),
		Color(accent.r, accent.g, accent.b, alpha * 0.22),
		Color(0.060, 0.054, 0.044, alpha * 0.70),
		Color(0.018, 0.016, 0.014, alpha * 0.88),
		Color(0.030, 0.026, 0.021, alpha * 0.86)
	]))

func _draw_side_view_ground(size: Vector2, palette: Dictionary) -> void:
	var top_y := size.y * 0.48
	var bottom_y := size.y
	var floor_color: Color = palette["floor"]
	var painted_floor_active := _has_painted_stage_stack()
	var lane_alpha := SIDE_VIEW_STAGE_LANE_ALPHA * (0.38 if painted_floor_active else 1.0)
	var lane := PackedVector2Array([
		Vector2(size.x * 0.07, top_y),
		Vector2(size.x * 0.93, top_y),
		Vector2(size.x * 1.04, bottom_y + tile_size * 0.5),
		Vector2(size.x * -0.04, bottom_y + tile_size * 0.5)
	])
	draw_polygon(lane, PackedColorArray([
		_with_alpha(floor_color.lightened(0.10), lane_alpha),
		_with_alpha(floor_color.lightened(0.04), lane_alpha),
		_with_alpha(floor_color.darkened(0.32), lane_alpha + (0.03 if painted_floor_active else 0.08)),
		_with_alpha(floor_color.darkened(0.26), lane_alpha + (0.02 if painted_floor_active else 0.06))
	]))
	if painted_floor_active:
		_draw_stage_painted_floor_underlay(size, palette, top_y, bottom_y)
		return
	_draw_stage_terrain_terraces(size, palette, top_y, bottom_y)
	_draw_stage_play_lanes(size, palette, top_y, bottom_y)
	_draw_stage_lane_shadow_stack(size, palette, top_y, bottom_y)
	_draw_stage_depth_guides(size, palette)
	_draw_stage_perspective_edges(size, palette, top_y, bottom_y)
	_draw_stage_floor_material(size, palette, top_y, bottom_y)
	for i in range(11):
		var t := float(i) / 10.0
		var y := lerpf(top_y + tile_size * 0.22, bottom_y - tile_size * 0.36, t)
		var inset := lerpf(size.x * 0.11, size.x * -0.02, t)
		var right := size.x - inset
		draw_line(Vector2(inset, y), Vector2(right, y - tile_size * 0.10), Color(0.02, 0.018, 0.012, 0.12 + t * 0.11), 1.2 + t * 2.0)
	for i in range(8):
		var x := size.x * (0.14 + float(i) * 0.105)
		draw_line(Vector2(x, top_y + tile_size * 0.10), Vector2(x - size.x * 0.08, bottom_y), Color(0.0, 0.0, 0.0, 0.05), 1.2)
	_draw_ellipse_poly(Vector2(size.x * 0.50, top_y + tile_size * 1.22), Vector2(size.x * 0.38, tile_size * 0.46), Color((palette["accent"] as Color).r, (palette["accent"] as Color).g, (palette["accent"] as Color).b, 0.11))
	_draw_stage_platform_lip(size, palette, top_y, bottom_y)
	_draw_stage_side_exit_frames(size, palette, top_y, bottom_y)
	_draw_stage_near_terrain_occluders(size, palette, top_y, bottom_y)

func _draw_stage_painted_floor_underlay(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	_draw_stage_vertical_gradient(
		Rect2(Vector2(0.0, top_y - tile_size * 0.36), Vector2(size.x, bottom_y - top_y + tile_size * 0.86)),
		Color(floor_color.r, floor_color.g, floor_color.b, 0.10),
		Color(0.0, 0.0, 0.0, 0.22)
	)
	draw_line(
		Vector2(size.x * 0.08, top_y + tile_size * 0.12),
		Vector2(size.x * 0.92, top_y + tile_size * 0.02),
		Color(accent.r, accent.g, accent.b, 0.10),
		1.2
	)
	_draw_ellipse_poly(
		Vector2(size.x * 0.50, top_y + tile_size * 1.18),
		Vector2(size.x * 0.34, tile_size * 0.34),
		Color(accent.r, accent.g, accent.b, 0.055)
	)

func _draw_stage_terrain_terraces(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	for i in range(SIDE_VIEW_TERRACE_BAND_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_TERRACE_BAND_COUNT - 1))
		var y := lerpf(top_y + tile_size * 0.18, bottom_y - tile_size * 1.72, 0.06 + t * 0.70)
		var face_y := y + tile_size * (0.26 + t * 0.18)
		var inset := lerpf(size.x * 0.18, size.x * -0.035, t)
		var right := size.x - inset
		var skew := tile_size * (0.18 + t * 0.16)
		var alpha := SIDE_VIEW_TERRACE_ALPHA * (0.52 + t * 0.40)
		var top_color := floor_color.lightened(0.12 - t * 0.05)
		var face_color := floor_color.darkened(0.24 + t * 0.10)
		draw_polygon(PackedVector2Array([
			Vector2(inset, y),
			Vector2(right, y - tile_size * 0.10),
			Vector2(right + skew, face_y - tile_size * 0.02),
			Vector2(inset - skew, face_y + tile_size * 0.06)
		]), PackedColorArray([
			Color(top_color.r, top_color.g, top_color.b, alpha * 0.54),
			Color(top_color.r, top_color.g, top_color.b, alpha * 0.46),
			Color(face_color.r, face_color.g, face_color.b, alpha * 0.72),
			Color(face_color.r, face_color.g, face_color.b, alpha * 0.80)
		]))
		draw_line(Vector2(inset + tile_size * 0.16, y + tile_size * 0.03), Vector2(right - tile_size * 0.12, y - tile_size * 0.08), Color(accent.r, accent.g, accent.b, alpha * 0.46), 1.2 + t * 1.2)
		draw_line(Vector2(inset - skew, face_y + tile_size * 0.06), Vector2(right + skew, face_y - tile_size * 0.02), Color(0.0, 0.0, 0.0, alpha * 0.70), 1.8 + t * 1.4)
		_draw_stage_terrain_band_detail(size, accent, floor_color, inset, right, y, face_y, t, i, region_type, terrain)

func _draw_stage_terrain_band_detail(_size: Vector2, accent: Color, floor_color: Color, left: float, right: float, y: float, face_y: float, t: float, index: int, region_type: String, terrain: String) -> void:
	var alpha := SIDE_VIEW_TERRACE_RAIL_ALPHA * (0.48 + t * 0.42)
	var span := maxf(tile_size, right - left)
	if region_type == "city" or region_type == "town":
		for post in range(5):
			var p := float(post) / 4.0
			var x := lerpf(left + span * 0.08, right - span * 0.08, p)
			var post_top := y - tile_size * (0.22 + float((post + index) % 2) * 0.08)
			draw_line(Vector2(x, post_top), Vector2(x - tile_size * 0.05, face_y + tile_size * 0.08), Color(0.020, 0.012, 0.008, alpha * 0.82), 1.5 + t)
			if post < 4:
				var nx := lerpf(left + span * 0.08, right - span * 0.08, float(post + 1) / 4.0)
				draw_line(Vector2(x, post_top + tile_size * 0.10), Vector2(nx, post_top + tile_size * 0.04), Color(accent.r, accent.g, accent.b, alpha * 0.32), 1.0)
	elif region_type == "sect":
		for step in range(4):
			var p := (float(step) + 0.5) / 4.0
			var x := lerpf(left + span * 0.18, right - span * 0.18, p)
			draw_line(Vector2(x - tile_size * 0.36, y + tile_size * (0.10 + p * 0.12)), Vector2(x + tile_size * 0.36, y + tile_size * (0.04 + p * 0.09)), Color(accent.r, accent.g, accent.b, alpha * 0.34), 1.1)
			draw_rect(Rect2(Vector2(x - tile_size * 0.16, face_y - tile_size * 0.02), Vector2(tile_size * 0.32, tile_size * 0.06)), Color(0.0, 0.0, 0.0, alpha * 0.34), true)
	elif _terrain_has_water(terrain):
		for plank in range(7):
			var p := float(plank) / 6.0
			var x := lerpf(left + tile_size * 0.30, right - tile_size * 0.30, p)
			draw_line(Vector2(x, y + tile_size * 0.04), Vector2(x + tile_size * 0.18, face_y + tile_size * 0.04), Color(0.0, 0.0, 0.0, alpha * 0.42), 1.0)
		draw_line(Vector2(left + tile_size * 0.20, y - tile_size * 0.12), Vector2(right - tile_size * 0.20, y - tile_size * 0.20), Color(accent.r, accent.g, accent.b, alpha * 0.34), 1.4)
	elif _terrain_has_forest(terrain):
		for root in range(5):
			var p := (float(root) + 0.5) / 5.0
			var x := lerpf(left + span * 0.05, right - span * 0.05, p)
			draw_line(Vector2(x, face_y + tile_size * 0.06), Vector2(x + sin(float(root + index)) * tile_size * 0.34, y - tile_size * 0.10), Color(0.018, 0.065, 0.022, alpha * 0.66), 1.2 + t * 0.8)
			_draw_ellipse_poly(Vector2(x + tile_size * 0.10, y - tile_size * 0.05), Vector2(tile_size * 0.12, tile_size * 0.030), Color(accent.r, accent.g, accent.b, alpha * 0.24))
	else:
		for chip in range(6):
			var p := float((chip * 3 + index) % 7) / 6.0
			var x := lerpf(left + tile_size * 0.46, right - tile_size * 0.46, p)
			var rock_alpha := alpha * (0.42 + float(chip % 3) * 0.10)
			_draw_ellipse_poly(Vector2(x, face_y - tile_size * (0.04 + float(chip % 2) * 0.03)), Vector2(tile_size * (0.055 + float(chip % 3) * 0.015), tile_size * 0.018), Color(0.0, 0.0, 0.0, rock_alpha))
			if terrain.contains("snow"):
				draw_line(Vector2(x - tile_size * 0.08, y - tile_size * 0.04), Vector2(x + tile_size * 0.12, y - tile_size * 0.08), Color(0.88, 0.96, 1.0, rock_alpha * 0.74), 0.9)
			elif terrain.contains("desert"):
				draw_line(Vector2(x - tile_size * 0.12, y + tile_size * 0.04), Vector2(x + tile_size * 0.16, y), Color(0.92, 0.70, 0.36, rock_alpha * 0.54), 0.9)
			else:
				draw_line(Vector2(x - tile_size * 0.10, y), Vector2(x + tile_size * 0.18, y - tile_size * 0.04), Color(floor_color.r, floor_color.g, floor_color.b, rock_alpha * 0.64), 0.9)

func _draw_stage_near_terrain_occluders(size: Vector2, palette: Dictionary, _top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	for i in range(SIDE_VIEW_TERRAIN_OCCLUDER_COUNT):
		var seed := _tile_seed(i + 101, int(size.y) + i * 17)
		var t := float(i) / float(maxi(1, SIDE_VIEW_TERRAIN_OCCLUDER_COUNT - 1))
		var x := fposmod(float(seed * 37), size.x + tile_size * 1.8) - tile_size * 0.9
		var y := lerpf(bottom_y - tile_size * 1.10, bottom_y - tile_size * 0.22, float(seed % 100) / 99.0)
		var scale := 0.78 + t * 0.34
		var alpha := SIDE_VIEW_TERRAIN_OCCLUDER_ALPHA * (0.54 + t * 0.36)
		if region_type == "city" or region_type == "town":
			var w := tile_size * (0.36 + float(seed % 4) * 0.06) * scale
			var h := tile_size * (0.18 + float(int(seed / 5) % 3) * 0.05) * scale
			draw_rect(Rect2(Vector2(x, y - h), Vector2(w, h)), Color(0.030, 0.018, 0.010, alpha), true)
			draw_line(Vector2(x, y - h), Vector2(x + w, y - h - tile_size * 0.04 * scale), Color(accent.r, accent.g, accent.b, alpha * 0.48), 1.1)
		elif region_type == "sect":
			_draw_ellipse_poly(Vector2(x + tile_size * 0.22 * scale, y), Vector2(tile_size * 0.26 * scale, tile_size * 0.050 * scale), Color(0.0, 0.0, 0.0, alpha * 0.52))
			draw_polygon(PackedVector2Array([
				Vector2(x, y),
				Vector2(x + tile_size * 0.16 * scale, y - tile_size * 0.16 * scale),
				Vector2(x + tile_size * 0.54 * scale, y - tile_size * 0.10 * scale),
				Vector2(x + tile_size * 0.62 * scale, y + tile_size * 0.08 * scale)
			]), PackedColorArray([
				Color(0.020, 0.018, 0.014, alpha),
				Color(accent.r, accent.g, accent.b, alpha * 0.38),
				Color(0.042, 0.036, 0.028, alpha * 0.84),
				Color(0.012, 0.010, 0.008, alpha)
			]))
		elif _terrain_has_water(terrain):
			var h := tile_size * (0.34 + float(seed % 3) * 0.05) * scale
			draw_line(Vector2(x, y - h), Vector2(x - tile_size * 0.04 * scale, y + tile_size * 0.08 * scale), Color(0.020, 0.014, 0.008, alpha), 2.2 * scale)
			draw_line(Vector2(x - tile_size * 0.32 * scale, y - h * 0.55), Vector2(x + tile_size * 0.38 * scale, y - h * 0.64), Color(accent.r, accent.g, accent.b, alpha * 0.28), 1.3)
		elif _terrain_has_forest(terrain):
			var h := tile_size * (0.46 + float(seed % 4) * 0.08) * scale
			draw_line(Vector2(x, y + tile_size * 0.08 * scale), Vector2(x + tile_size * 0.08 * scale, y - h), Color(0.006, 0.040, 0.014, alpha + 0.04), 2.6 * scale)
			_draw_ellipse_poly(Vector2(x + tile_size * 0.22 * scale, y - h * 0.72), Vector2(tile_size * 0.26 * scale, tile_size * 0.085 * scale), Color(accent.r * 0.34, accent.g * 0.48, accent.b * 0.30, alpha * 0.48))
		else:
			var w := tile_size * (0.30 + float(seed % 5) * 0.045) * scale
			var h := tile_size * (0.20 + float(int(seed / 7) % 4) * 0.045) * scale
			_draw_ellipse_poly(Vector2(x + w * 0.36, y), Vector2(w * 0.64, tile_size * 0.050 * scale), Color(0.0, 0.0, 0.0, alpha * 0.36))
			draw_polygon(PackedVector2Array([
				Vector2(x, y),
				Vector2(x + w * 0.24, y - h),
				Vector2(x + w, y - h * 0.62),
				Vector2(x + w * 1.10, y + tile_size * 0.06 * scale),
				Vector2(x + w * 0.20, y + tile_size * 0.08 * scale)
			]), PackedColorArray([
				Color(0.018, 0.016, 0.013, alpha),
				Color(accent.r, accent.g, accent.b, alpha * 0.30),
				Color(0.048, 0.042, 0.034, alpha * 0.72),
				Color(0.012, 0.010, 0.008, alpha),
				Color(0.014, 0.012, 0.010, alpha)
			]))

func _stage_play_lane_centers(size: Vector2) -> Array[float]:
	var centers: Array[float] = []
	var top_y := size.y * STAGE_DEPTH_TOP_RATIO
	var bottom_y := size.y * STAGE_DEPTH_BOTTOM_RATIO
	for i in range(SIDE_VIEW_PLAY_LANE_COUNT):
		var t := (float(i) + 0.5) / float(maxi(1, SIDE_VIEW_PLAY_LANE_COUNT))
		centers.append(lerpf(top_y, bottom_y, t))
	return centers

func _draw_stage_play_lanes(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	for i in range(SIDE_VIEW_PLAY_LANE_COUNT):
		var t0 := float(i) / float(SIDE_VIEW_PLAY_LANE_COUNT)
		var t1 := float(i + 1) / float(SIDE_VIEW_PLAY_LANE_COUNT)
		var y0 := lerpf(top_y, bottom_y, t0)
		var y1 := lerpf(top_y, bottom_y, t1)
		var inset0 := lerpf(size.x * 0.105, size.x * -0.035, t0)
		var inset1 := lerpf(size.x * 0.105, size.x * -0.035, t1)
		var lane_alpha := SIDE_VIEW_PLAY_LANE_ALPHA * (0.56 + t1 * 0.36)
		var lane_color := floor_color.lightened(0.08 if i % 2 == 0 else 0.02)
		draw_polygon(PackedVector2Array([
			Vector2(inset0, y0),
			Vector2(size.x - inset0, y0 - tile_size * 0.10),
			Vector2(size.x - inset1, y1 - tile_size * 0.12),
			Vector2(inset1, y1)
		]), PackedColorArray([
			Color(lane_color.r, lane_color.g, lane_color.b, lane_alpha * 0.52),
			Color(lane_color.r, lane_color.g, lane_color.b, lane_alpha * 0.44),
			Color(0.0, 0.0, 0.0, lane_alpha * 0.34),
			Color(0.0, 0.0, 0.0, lane_alpha * 0.46)
		]))
		var edge_alpha := SIDE_VIEW_PLAY_LANE_EDGE_ALPHA * (0.42 + t1 * 0.34)
		draw_line(Vector2(inset0 + tile_size * 0.18, y0 + tile_size * 0.02), Vector2(size.x - inset0 - tile_size * 0.18, y0 - tile_size * 0.08), Color(accent.r, accent.g, accent.b, edge_alpha * 0.48), 1.2 + t1 * 1.1)
		draw_line(Vector2(inset1, y1), Vector2(size.x - inset1, y1 - tile_size * 0.12), Color(0.0, 0.0, 0.0, edge_alpha), 1.8 + t1 * 1.4)
	_draw_stage_lane_decals(size, palette, top_y, bottom_y)

func _draw_stage_lane_decals(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	for i in range(SIDE_VIEW_LANE_DECAL_COUNT):
		var seed := _tile_seed(i + 83, int(size.x) + i * 19)
		var t := float(seed % 1000) / 999.0
		var lane_index := i % SIDE_VIEW_PLAY_LANE_COUNT
		var lane_t := (float(lane_index) + 0.5) / float(SIDE_VIEW_PLAY_LANE_COUNT)
		var y := lerpf(top_y, bottom_y, lane_t) + sin(float(seed) * 0.017) * tile_size * 0.10
		var inset := lerpf(size.x * 0.10, size.x * -0.03, lane_t)
		var x := lerpf(inset + tile_size * 0.54, size.x - inset - tile_size * 0.54, t)
		var width := tile_size * (0.18 + float(seed % 5) * 0.05)
		var alpha := SIDE_VIEW_PLAY_LANE_EDGE_ALPHA * (0.18 + lane_t * 0.18)
		if i % 4 == 0:
			_draw_ellipse_poly(Vector2(x, y + tile_size * 0.03), Vector2(width * 0.55, tile_size * 0.018), Color(0.0, 0.0, 0.0, alpha * 0.72))
			draw_circle(Vector2(x + width * 0.18, y), tile_size * 0.020, Color(accent.r, accent.g, accent.b, alpha * 0.82))
		else:
			draw_line(Vector2(x - width * 0.50, y), Vector2(x + width * 0.50, y - tile_size * 0.04), Color(0.0, 0.0, 0.0, alpha), 1.0 + lane_t * 0.8)

func _draw_stage_lane_shadow_stack(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	for i in range(SIDE_VIEW_LANE_SHADOW_COUNT):
		var lane_t := (float(i) + 0.5) / float(maxi(1, SIDE_VIEW_LANE_SHADOW_COUNT))
		var y := lerpf(top_y, bottom_y, lane_t)
		var inset := lerpf(size.x * 0.12, size.x * -0.035, lane_t)
		var right := size.x - inset
		var depth := tile_size * (0.13 + lane_t * 0.18)
		var alpha := SIDE_VIEW_LANE_SHADOW_ALPHA * (0.42 + lane_t * 0.46)
		draw_polygon(PackedVector2Array([
			Vector2(inset + tile_size * 0.20, y + tile_size * 0.05),
			Vector2(right - tile_size * 0.24, y - tile_size * 0.06),
			Vector2(right + tile_size * 0.20, y + depth),
			Vector2(inset - tile_size * 0.24, y + depth + tile_size * 0.08)
		]), PackedColorArray([
			Color(0.0, 0.0, 0.0, alpha * 0.30),
			Color(0.0, 0.0, 0.0, alpha * 0.26),
			Color(0.0, 0.0, 0.0, alpha * 0.68),
			Color(0.0, 0.0, 0.0, alpha * 0.72)
		]))
		draw_line(Vector2(inset + tile_size * 0.48, y + tile_size * 0.02), Vector2(right - tile_size * 0.52, y - tile_size * 0.08), Color(accent.r, accent.g, accent.b, alpha * 0.58), 1.0 + lane_t * 1.1)
		draw_line(Vector2(inset - tile_size * 0.10, y + depth + tile_size * 0.06), Vector2(right + tile_size * 0.10, y + depth - tile_size * 0.04), Color(0.0, 0.0, 0.0, alpha * 0.80), 1.4 + lane_t * 1.4)

func _draw_stage_side_exit_frames(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var centers := _stage_play_lane_centers(size)
	for i in range(mini(SIDE_VIEW_SIDE_EXIT_COUNT, centers.size())):
		var lane_y := centers[i]
		var t := clampf((lane_y - top_y) / maxf(1.0, bottom_y - top_y), 0.0, 1.0)
		var height := tile_size * (0.46 + t * 0.20)
		var width := tile_size * (0.58 + t * 0.14)
		var left_x := lerpf(size.x * 0.085, size.x * -0.025, t)
		var right_x := size.x - left_x
		var alpha := SIDE_VIEW_SIDE_EXIT_ALPHA * (0.52 + t * 0.28)
		_draw_stage_side_exit_frame(Vector2(left_x, lane_y), width, height, -1.0, accent, alpha)
		_draw_stage_side_exit_frame(Vector2(right_x, lane_y - tile_size * 0.10), width, height, 1.0, accent, alpha * 0.92)

func _draw_stage_side_exit_frame(pos: Vector2, width: float, height: float, dir: float, accent: Color, alpha: float) -> void:
	var post_color := Color(0.020, 0.014, 0.010, alpha)
	var glow := Color(accent.r, accent.g, accent.b, alpha * 0.42)
	var inner_x := pos.x + width * dir
	draw_line(pos + Vector2(0.0, -height * 0.78), pos + Vector2(0.0, height * 0.28), post_color, 3.0)
	draw_line(Vector2(inner_x, pos.y - height * 0.62), Vector2(inner_x, pos.y + height * 0.18), post_color, 2.0)
	draw_line(pos + Vector2(0.0, -height * 0.76), Vector2(inner_x, pos.y - height * 0.62), glow, 1.5)
	draw_line(pos + Vector2(0.0, height * 0.24), Vector2(inner_x, pos.y + height * 0.18), Color(0.0, 0.0, 0.0, alpha * 0.72), 1.5)
	_draw_ellipse_poly(pos + Vector2(width * 0.48 * dir, height * 0.34), Vector2(width * 0.62, height * 0.16), Color(0.0, 0.0, 0.0, alpha * 0.34))

func _draw_stage_perspective_edges(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var shadow := Color(0.0, 0.0, 0.0, SIDE_VIEW_PERSPECTIVE_EDGE_ALPHA)
	draw_line(Vector2(size.x * 0.07, top_y + tile_size * 0.08), Vector2(size.x * -0.025, bottom_y + tile_size * 0.10), shadow, 3.0)
	draw_line(Vector2(size.x * 0.93, top_y), Vector2(size.x * 1.025, bottom_y), shadow, 3.0)
	draw_line(Vector2(size.x * 0.10, top_y + tile_size * 0.18), Vector2(size.x * 0.015, bottom_y - tile_size * 0.46), Color(accent.r, accent.g, accent.b, SIDE_VIEW_PERSPECTIVE_EDGE_ALPHA * 0.62), 1.4)
	draw_line(Vector2(size.x * 0.90, top_y + tile_size * 0.10), Vector2(size.x * 0.985, bottom_y - tile_size * 0.55), Color(accent.r, accent.g, accent.b, SIDE_VIEW_PERSPECTIVE_EDGE_ALPHA * 0.52), 1.4)

func _draw_stage_floor_material(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	for i in range(SIDE_VIEW_FLOOR_DETAIL_COUNT):
		var seed := _tile_seed(i + 31, int(size.y) + i * 11)
		var t := float(seed % 997) / 996.0
		var u := float((int(seed / 7) % 991)) / 990.0
		var y := lerpf(top_y + tile_size * 0.34, bottom_y - tile_size * 0.34, t)
		var inset := lerpf(size.x * 0.12, size.x * -0.025, t)
		var x := lerpf(inset + tile_size * 0.40, size.x - inset - tile_size * 0.40, u)
		var alpha := SIDE_VIEW_FLOOR_DETAIL_ALPHA * (0.45 + t * 0.55)
		if i % 3 == 0:
			var length := tile_size * (0.18 + float(seed % 5) * 0.045)
			draw_line(Vector2(x, y), Vector2(x + length, y - tile_size * 0.035), Color(0.0, 0.0, 0.0, alpha), 1.0 + t * 1.2)
			var light_floor := floor_color.lightened(0.20)
			draw_line(Vector2(x + length * 0.22, y + tile_size * 0.035), Vector2(x + length * 0.72, y + tile_size * 0.005), Color(light_floor.r, light_floor.g, light_floor.b, alpha * 0.46), 0.8)
		else:
			var radius := Vector2(tile_size * (0.045 + float(seed % 4) * 0.012), tile_size * (0.014 + float(seed % 3) * 0.006))
			_draw_ellipse_poly(Vector2(x, y), radius, Color(0.0, 0.0, 0.0, alpha * 0.78))
			if i % 7 == 0:
				draw_circle(Vector2(x + tile_size * 0.035, y - tile_size * 0.018), tile_size * 0.018, Color(accent.r, accent.g, accent.b, alpha * 0.92))

func _draw_stage_platform_lip(size: Vector2, palette: Dictionary, top_y: float, bottom_y: float) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	var lip_top := bottom_y - tile_size * 1.28
	draw_polygon(PackedVector2Array([
		Vector2(size.x * -0.02, lip_top),
		Vector2(size.x * 1.02, lip_top - tile_size * 0.10),
		Vector2(size.x * 1.06, bottom_y + tile_size * 0.10),
		Vector2(size.x * -0.06, bottom_y + tile_size * 0.10)
	]), PackedColorArray([
		Color(floor_color.r, floor_color.g, floor_color.b, SIDE_VIEW_PLATFORM_EDGE_ALPHA * 0.45),
		Color(floor_color.r, floor_color.g, floor_color.b, SIDE_VIEW_PLATFORM_EDGE_ALPHA * 0.38),
		Color(0.015, 0.011, 0.008, SIDE_VIEW_PLATFORM_EDGE_ALPHA + 0.10),
		Color(0.020, 0.014, 0.010, SIDE_VIEW_PLATFORM_EDGE_ALPHA + 0.12)
	]))
	draw_line(Vector2(size.x * 0.02, lip_top), Vector2(size.x * 0.98, lip_top - tile_size * 0.10), Color(accent.r, accent.g, accent.b, 0.16), 2.2)
	for i in range(9):
		var t := float(i) / 8.0
		var x := lerpf(size.x * 0.06, size.x * 0.94, t)
		draw_line(Vector2(x, top_y + tile_size * 0.30), Vector2(x - size.x * 0.035, bottom_y), Color(0.0, 0.0, 0.0, 0.055), 1.0)
	for i in range(SIDE_VIEW_NEAR_PROP_COUNT):
		var seed := _tile_seed(i + 17, int(size.x) + i * 3)
		var x := fposmod(float(seed * 31), size.x + tile_size * 1.2) - tile_size * 0.6
		var y := lerpf(lip_top + tile_size * 0.06, bottom_y - tile_size * 0.16, float(i % 5) / 4.0)
		var radius := Vector2(tile_size * (0.10 + float(i % 3) * 0.035), tile_size * (0.028 + float(i % 2) * 0.012))
		_draw_ellipse_poly(Vector2(x, y), radius, Color(0.0, 0.0, 0.0, 0.10 + float(i % 3) * 0.018))
		if i % 4 == 0:
			draw_circle(Vector2(x + tile_size * 0.06, y - tile_size * 0.035), tile_size * 0.025, Color(accent.r, accent.g, accent.b, 0.15))

func _draw_stage_depth_guides(size: Vector2, palette: Dictionary) -> void:
	var top_y := size.y * STAGE_DEPTH_TOP_RATIO
	var bottom_y := size.y * STAGE_DEPTH_BOTTOM_RATIO
	var accent: Color = palette["accent"]
	var shadow := Color(0.01, 0.008, 0.006, SIDE_VIEW_DEPTH_GUIDE_ALPHA)
	for i in range(4):
		var t0 := float(i) / 4.0
		var t1 := float(i + 1) / 4.0
		var y0 := lerpf(top_y, bottom_y, t0)
		var y1 := lerpf(top_y, bottom_y, t1)
		var inset0 := lerpf(size.x * 0.13, size.x * -0.03, t0)
		var inset1 := lerpf(size.x * 0.13, size.x * -0.03, t1)
		var band_alpha := SIDE_VIEW_DEPTH_GUIDE_ALPHA * (0.32 + t1 * 0.52)
		draw_polygon(PackedVector2Array([
			Vector2(inset0, y0),
			Vector2(size.x - inset0, y0 - tile_size * 0.10),
			Vector2(size.x - inset1, y1 - tile_size * 0.10),
			Vector2(inset1, y1)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, band_alpha * 0.55),
			Color(accent.r, accent.g, accent.b, band_alpha * 0.40),
			Color(0.0, 0.0, 0.0, band_alpha * 0.44),
			Color(0.0, 0.0, 0.0, band_alpha * 0.58)
		]))
		var guide_y := lerpf(y0, y1, 0.62)
		var guide_inset := lerpf(inset0, inset1, 0.62)
		draw_line(Vector2(guide_inset, guide_y), Vector2(size.x - guide_inset, guide_y - tile_size * 0.10), shadow, 1.0 + t1 * 2.0)

func _draw_side_view_director_pass(size: Vector2, palette: Dictionary) -> void:
	_draw_stage_depth_fog_bands(size, palette)
	_draw_stage_platform_rim_stack(size, palette)
	_draw_stage_focus_rays(size, palette)
	_draw_stage_cinematic_masks(size, palette)

func _draw_stage_depth_fog_bands(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	for i in range(SIDE_VIEW_DEPTH_FOG_BAND_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_DEPTH_FOG_BAND_COUNT - 1))
		var y := lerpf(size.y * 0.43, size.y * 0.88, t)
		var drift := sin(stage_visual_phase * (0.32 + t * 0.08) + float(i) * 0.71) * tile_size * (0.70 + t * 0.40)
		var height := tile_size * (0.22 + t * 0.13)
		var inset := lerpf(size.x * 0.16, size.x * -0.02, t)
		var left := inset - tile_size * 1.2 + drift
		var right := size.x - inset + tile_size * 1.2 + drift * 0.36
		var alpha := 0.070 + t * 0.035
		if str(current_region.get("terrain", "")).contains("snow"):
			alpha += 0.025
		draw_polygon(PackedVector2Array([
			Vector2(left, y - height * 0.50),
			Vector2(right, y - height * 0.62),
			Vector2(right - tile_size * 0.44, y + height * 0.52),
			Vector2(left + tile_size * 0.28, y + height * 0.62)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, alpha * 0.18),
			Color(accent.r, accent.g, accent.b, alpha * 0.12),
			Color(accent.r, accent.g, accent.b, alpha),
			Color(accent.r, accent.g, accent.b, alpha * 0.88)
		]))
		draw_line(Vector2(left + tile_size * 0.62, y + height * 0.30), Vector2(right - tile_size * 0.80, y + height * 0.08), Color(1.0, 0.92, 0.72, alpha * 0.22), 1.0)

func _draw_stage_platform_rim_stack(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var floor_color: Color = palette["floor"]
	var top_y := size.y * STAGE_DEPTH_TOP_RATIO
	var bottom_y := size.y * STAGE_DEPTH_BOTTOM_RATIO
	for i in range(SIDE_VIEW_PLATFORM_RIM_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_PLATFORM_RIM_COUNT - 1))
		var y := lerpf(top_y + tile_size * 0.10, bottom_y - tile_size * 0.22, t)
		var inset := lerpf(size.x * 0.13, size.x * -0.015, t)
		var line_alpha := SIDE_VIEW_PLATFORM_EDGE_ALPHA * (0.28 + t * 0.30)
		draw_line(Vector2(inset, y), Vector2(size.x - inset, y - tile_size * 0.10), Color(0.0, 0.0, 0.0, line_alpha * 0.76), 2.4 + t * 2.0)
		draw_line(Vector2(inset + tile_size * 0.18, y - tile_size * 0.05), Vector2(size.x - inset - tile_size * 0.18, y - tile_size * 0.14), Color(accent.r, accent.g, accent.b, line_alpha * 0.72), 1.1 + t * 0.8)
		if i > 0:
			var shelf_depth := tile_size * (0.16 + t * 0.08)
			draw_polygon(PackedVector2Array([
				Vector2(inset, y),
				Vector2(size.x - inset, y - tile_size * 0.10),
				Vector2(size.x - inset + tile_size * 0.28, y + shelf_depth),
				Vector2(inset - tile_size * 0.20, y + shelf_depth + tile_size * 0.05)
			]), PackedColorArray([
				Color(floor_color.r, floor_color.g, floor_color.b, line_alpha * 0.18),
				Color(floor_color.r, floor_color.g, floor_color.b, line_alpha * 0.12),
				Color(0.0, 0.0, 0.0, line_alpha * 0.26),
				Color(0.0, 0.0, 0.0, line_alpha * 0.32)
			]))

func _draw_stage_focus_rays(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var top_y := size.y * 0.28
	var bottom_y := size.y * 0.96
	for i in range(SIDE_VIEW_STAGE_FOCUS_RAY_COUNT):
		var t := float(i) / float(maxi(1, SIDE_VIEW_STAGE_FOCUS_RAY_COUNT - 1))
		var center_x := lerpf(size.x * 0.12, size.x * 0.88, t)
		var target_x := lerpf(size.x * 0.26, size.x * 0.74, 1.0 - absf(t - 0.5) * 1.40)
		var sway := sin(stage_visual_phase * 0.22 + float(i) * 0.63) * tile_size * 0.28
		var top_width := tile_size * (0.12 + float(i % 3) * 0.035)
		var bottom_width := tile_size * (1.10 + float(i % 2) * 0.22)
		var alpha := SIDE_VIEW_STAGE_FOCUS_ALPHA * (0.35 + (1.0 - absf(t - 0.5) * 1.4) * 0.45)
		draw_polygon(PackedVector2Array([
			Vector2(center_x - top_width + sway, top_y),
			Vector2(center_x + top_width + sway, top_y),
			Vector2(target_x + bottom_width, bottom_y),
			Vector2(target_x - bottom_width, bottom_y + tile_size * 0.12)
		]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, alpha * 0.44),
			Color(1.0, 0.88, 0.56, alpha * 0.36),
			Color(1.0, 0.88, 0.56, 0.0),
			Color(accent.r, accent.g, accent.b, 0.0)
		]))

func _draw_stage_cinematic_masks(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	var top_h := tile_size * 0.52
	var bottom_h := tile_size * 0.84
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_h)), Color(0.008, 0.006, 0.004, SIDE_VIEW_DIRECTOR_BAND_ALPHA), true)
	draw_line(Vector2(0.0, top_h), Vector2(size.x, top_h - tile_size * 0.08), Color(accent.r, accent.g, accent.b, SIDE_VIEW_DIRECTOR_BAND_ALPHA * 0.30), 1.6)
	draw_rect(Rect2(Vector2(0.0, size.y - bottom_h), Vector2(size.x, bottom_h + tile_size * 0.20)), Color(0.006, 0.005, 0.004, SIDE_VIEW_DIRECTOR_BAND_ALPHA * 0.82), true)
	draw_line(Vector2(0.0, size.y - bottom_h), Vector2(size.x, size.y - bottom_h - tile_size * 0.10), Color(0.0, 0.0, 0.0, SIDE_VIEW_DIRECTOR_BAND_ALPHA * 0.80), 2.0)
	for i in range(5):
		var t := float(i) / 4.0
		var x := lerpf(size.x * 0.10, size.x * 0.90, t)
		draw_line(Vector2(x, size.y - bottom_h + tile_size * 0.12), Vector2(x - tile_size * 0.30, size.y + tile_size * 0.14), Color(accent.r, accent.g, accent.b, SIDE_VIEW_DIRECTOR_BAND_ALPHA * 0.12), 1.0)

func _draw_side_view_ambient(size: Vector2, palette: Dictionary) -> void:
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var accent: Color = palette["accent"]
	_draw_stage_drifting_mist(size, Color(accent.r, accent.g, accent.b, 0.095), 0.66)
	if region_type == "city" or region_type == "town":
		_draw_stage_lantern_glows(size, accent)
	if _terrain_has_water(terrain):
		_draw_stage_water_glints(size, accent)
	if terrain.contains("snow"):
		_draw_stage_snow_drift(size)
	elif terrain.contains("desert"):
		_draw_stage_sand_drift(size)
	elif _terrain_has_forest(terrain) or terrain.contains("flower") or terrain.contains("garden"):
		_draw_stage_leaf_drift(size, accent)
	if region_type == "sect":
		_draw_stage_sect_motes(size, accent)

func _draw_stage_drifting_mist(size: Vector2, color: Color, y_ratio: float) -> void:
	for i in range(8):
		var speed := tile_size * (0.16 + float(i % 3) * 0.035)
		var x := fposmod(float(i * 379) + stage_visual_phase * speed, size.x + tile_size * 8.0) - tile_size * 4.0
		var y := size.y * y_ratio + sin(stage_visual_phase * 0.42 + float(i) * 1.31) * tile_size * 0.44 + float(i % 4) * tile_size * 0.28
		var width := size.x * (0.22 + float(i % 4) * 0.055)
		var alpha := color.a * (0.55 + float(i % 3) * 0.16)
		draw_rect(Rect2(Vector2(x, y), Vector2(width, tile_size * 0.24)), Color(color.r, color.g, color.b, alpha), true)
		draw_line(Vector2(x + tile_size * 0.30, y + tile_size * 0.20), Vector2(x + width - tile_size * 0.42, y + tile_size * 0.12), Color(color.r, color.g, color.b, alpha * 1.38), 1.0)

func _draw_stage_lantern_glows(size: Vector2, accent: Color) -> void:
	for i in range(10):
		var x := fposmod(float(i * 337) + sin(stage_visual_phase * 0.56 + float(i)) * tile_size * 0.32, size.x + tile_size * 2.0) - tile_size
		var y := size.y * (0.31 + float((i * 7) % 19) / 100.0)
		var pulse := 0.5 + sin(stage_visual_phase * 2.7 + float(i) * 0.71) * 0.5
		draw_circle(Vector2(x, y), tile_size * (0.34 + pulse * 0.12), Color(1.0, 0.55, 0.18, 0.035))
		draw_circle(Vector2(x, y), tile_size * 0.075, Color(1.0, 0.77, 0.34, 0.15 + pulse * 0.08))
		draw_line(Vector2(x, y - tile_size * 0.24), Vector2(x, y - tile_size * 0.46), Color(accent.r, accent.g, accent.b, 0.16), 1.0)

func _draw_stage_water_glints(size: Vector2, accent: Color) -> void:
	for i in range(18):
		var x := fposmod(float(i * 241) + stage_visual_phase * tile_size * 0.48, size.x + tile_size * 2.0) - tile_size
		var y := size.y * (0.53 + float((i * 11) % 32) / 100.0)
		var blink := 0.5 + sin(stage_visual_phase * 2.1 + float(i) * 0.87) * 0.5
		var width := tile_size * (0.34 + float(i % 4) * 0.10)
		draw_line(Vector2(x, y), Vector2(x + width, y - tile_size * 0.055), Color(0.72, 0.96, 1.0, 0.055 + blink * 0.055), 1.3)
		if i % 5 == 0:
			draw_circle(Vector2(x + width * 0.45, y - tile_size * 0.02), 2.0, Color(accent.r, accent.g, accent.b, 0.14 + blink * 0.08))

func _draw_stage_snow_drift(size: Vector2) -> void:
	for i in range(SIDE_VIEW_AMBIENT_PARTICLES):
		var x := fposmod(float(i * 157) + sin(stage_visual_phase * 0.56 + float(i)) * tile_size * 0.34, size.x + tile_size * 1.5) - tile_size * 0.75
		var y := fposmod(float(i * 89) + stage_visual_phase * tile_size * (0.42 + float(i % 3) * 0.05), size.y * 0.62) + tile_size * 0.70
		var radius := 1.0 + float(i % 3) * 0.35
		draw_circle(Vector2(x, y), radius, Color(0.90, 0.97, 1.0, 0.18 + float(i % 4) * 0.025))

func _draw_stage_sand_drift(size: Vector2) -> void:
	for i in range(SIDE_VIEW_AMBIENT_PARTICLES):
		var x := fposmod(float(i * 181) + stage_visual_phase * tile_size * (0.62 + float(i % 5) * 0.04), size.x + tile_size * 1.8) - tile_size * 0.9
		var y := size.y * (0.54 + float((i * 13) % 38) / 100.0)
		var alpha := 0.055 + sin(stage_visual_phase * 1.4 + float(i)) * 0.018
		draw_line(Vector2(x, y), Vector2(x + tile_size * (0.26 + float(i % 4) * 0.08), y - tile_size * 0.07), Color(0.92, 0.72, 0.38, alpha), 1.0)

func _draw_stage_leaf_drift(size: Vector2, accent: Color) -> void:
	for i in range(SIDE_VIEW_AMBIENT_PARTICLES):
		var x := fposmod(float(i * 199) + stage_visual_phase * tile_size * (0.20 + float(i % 3) * 0.03), size.x + tile_size * 2.0) - tile_size
		var y := fposmod(float(i * 71) + sin(stage_visual_phase * 0.7 + float(i)) * tile_size * 0.42, size.y * 0.50) + size.y * 0.18
		var leaf_color := Color(accent.r, accent.g, accent.b, 0.11 + float(i % 5) * 0.014)
		draw_line(Vector2(x, y), Vector2(x + tile_size * 0.12, y + tile_size * 0.055), leaf_color, 1.4)

func _draw_stage_sect_motes(size: Vector2, accent: Color) -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.47)
	draw_arc(center, tile_size * (2.8 + sin(stage_visual_phase * 0.9) * 0.12), PI * 0.08, PI * 0.92, 48, Color(accent.r, accent.g, accent.b, 0.12), 2.0)
	for i in range(20):
		var angle := stage_visual_phase * 0.28 + float(i) * TAU / 20.0
		var radius := tile_size * (1.7 + float(i % 5) * 0.38)
		var pos := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.24)
		draw_circle(pos, 1.6 + float(i % 3) * 0.35, Color(accent.r, accent.g, accent.b, 0.15))

func _draw_side_view_foreground(size: Vector2, palette: Dictionary) -> void:
	var accent: Color = palette["accent"]
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, tile_size * 0.72)), Color(0.025, 0.018, 0.012, SIDE_VIEW_FOREGROUND_ALPHA), true)
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	if region_type == "city" or region_type == "town":
		for i in range(8):
			var x := float(i) * size.x / 7.0 - tile_size * 0.4
			draw_line(Vector2(x, tile_size * 0.06), Vector2(x + tile_size * 1.45, tile_size * 0.72), Color(0.02, 0.014, 0.010, 0.35), 4.0)
			draw_circle(Vector2(x + tile_size * 0.88, tile_size * 0.86), 4.0, Color(accent.r, accent.g, accent.b, 0.28))
	elif _terrain_has_forest(terrain):
		_draw_stage_bamboo_edge(size, size.y * 0.42, true, Color(0.02, 0.10, 0.05, 0.54))
		_draw_stage_bamboo_edge(size, size.y * 0.45, false, Color(0.02, 0.10, 0.05, 0.48))
	elif terrain.contains("snow"):
		for i in range(28):
			var x := fmod(float(i) * tile_size * 1.23 + float(_tile_seed(i, i + 5) % 97), size.x)
			var y := tile_size * 0.8 + float(_tile_seed(i + 3, i + 7) % int(max(1.0, size.y * 0.54)))
			draw_circle(Vector2(x, y), 1.4 + float(i % 3) * 0.4, Color(0.90, 0.96, 1.0, 0.22))
	else:
		_draw_stage_mist_band(size, size.y * 0.72, Color(0.90, 0.84, 0.70, 0.12))
	_draw_stage_mist_band(size, size.y * 0.82, Color(accent.r, accent.g, accent.b, 0.09))

func _side_view_palette() -> Dictionary:
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var sky := Color(0.29, 0.34, 0.31, 0.30)
	var far := Color(0.10, 0.12, 0.10, 0.34)
	var mid := Color(0.16, 0.18, 0.13, 0.30)
	var floor := Color(0.42, 0.36, 0.24, 1.0)
	var accent := Color(0.82, 0.62, 0.32, 1.0)
	if terrain.contains("snow"):
		sky = Color(0.48, 0.58, 0.66, 0.34)
		far = Color(0.34, 0.42, 0.50, 0.34)
		mid = Color(0.52, 0.58, 0.62, 0.28)
		floor = Color(0.58, 0.64, 0.66, 1.0)
		accent = Color(0.70, 0.90, 1.0, 1.0)
	elif terrain.contains("desert"):
		sky = Color(0.58, 0.46, 0.28, 0.32)
		far = Color(0.46, 0.32, 0.18, 0.34)
		mid = Color(0.63, 0.46, 0.24, 0.28)
		floor = Color(0.56, 0.42, 0.24, 1.0)
		accent = Color(0.95, 0.72, 0.36, 1.0)
	elif _terrain_has_water(terrain):
		sky = Color(0.27, 0.42, 0.47, 0.30)
		far = Color(0.12, 0.22, 0.26, 0.34)
		mid = Color(0.18, 0.32, 0.36, 0.28)
		floor = Color(0.30, 0.39, 0.36, 1.0)
		accent = Color(0.58, 0.82, 0.86, 1.0)
	elif _terrain_has_forest(terrain):
		sky = Color(0.22, 0.34, 0.24, 0.30)
		far = Color(0.06, 0.16, 0.08, 0.36)
		mid = Color(0.12, 0.25, 0.12, 0.30)
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

func _draw_stage_mountain_band(size: Vector2, base_y: float, roughness: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(Vector2(0, size.y * 0.62))
	colors.append(color)
	var steps := 12
	for i in range(steps + 1):
		var x := size.x * float(i) / float(steps)
		var y := base_y - sin(float(i) * 1.37 + float(_tile_seed(i, 3) % 13) * 0.11) * size.y * roughness * 0.16
		points.append(Vector2(x, y))
		colors.append(color)
	points.append(Vector2(size.x, size.y * 0.62))
	colors.append(color)
	draw_polygon(points, colors)

func _draw_stage_roofline(size: Vector2, y: float, accent: Color) -> void:
	var roof_color := Color(0.08, 0.045, 0.028, 0.48)
	for i in range(7):
		var x := float(i) * size.x * 0.17 - tile_size
		var w := tile_size * (2.0 + float(i % 3) * 0.35)
		var roof := PackedVector2Array([
			Vector2(x, y + tile_size * 0.64),
			Vector2(x + w * 0.50, y),
			Vector2(x + w, y + tile_size * 0.64),
			Vector2(x + w * 0.92, y + tile_size * 0.82),
			Vector2(x + w * 0.08, y + tile_size * 0.82)
		])
		draw_polygon(roof, PackedColorArray([roof_color, Color(accent.r, accent.g, accent.b, 0.34), roof_color, roof_color, roof_color]))
		draw_line(Vector2(x + tile_size * 0.12, y + tile_size * 0.78), Vector2(x + w - tile_size * 0.12, y + tile_size * 0.78), Color(0.0, 0.0, 0.0, 0.36), 3.2)

func _draw_stage_gate(size: Vector2, y: float, accent: Color) -> void:
	var center_x := size.x * 0.50
	var w := tile_size * 4.8
	draw_rect(Rect2(Vector2(center_x - w * 0.48, y + tile_size * 0.70), Vector2(tile_size * 0.34, tile_size * 2.0)), Color(0.08, 0.06, 0.045, 0.42), true)
	draw_rect(Rect2(Vector2(center_x + w * 0.16, y + tile_size * 0.70), Vector2(tile_size * 0.34, tile_size * 2.0)), Color(0.08, 0.06, 0.045, 0.42), true)
	draw_polygon(PackedVector2Array([
		Vector2(center_x - w * 0.55, y + tile_size * 0.72),
		Vector2(center_x, y),
		Vector2(center_x + w * 0.55, y + tile_size * 0.72),
		Vector2(center_x + w * 0.45, y + tile_size * 0.95),
		Vector2(center_x - w * 0.45, y + tile_size * 0.95)
	]), PackedColorArray([
		Color(0.06, 0.045, 0.035, 0.50),
		Color(accent.r, accent.g, accent.b, 0.34),
		Color(0.06, 0.045, 0.035, 0.50),
		Color(0.08, 0.06, 0.045, 0.50),
		Color(0.08, 0.06, 0.045, 0.50)
	]))

func _draw_stage_bamboo_edge(size: Vector2, top_y: float, left_side: bool, color: Color) -> void:
	var base_x := tile_size * 0.8 if left_side else size.x - tile_size * 0.8
	var dir := 1.0 if left_side else -1.0
	for i in range(9):
		var x := base_x + dir * float(i) * tile_size * 0.22
		var sway := sin(float(i) * 0.9) * tile_size * 0.18 * dir
		draw_line(Vector2(x, size.y), Vector2(x + sway, top_y - float(i % 3) * tile_size * 0.26), color, 2.4)
		draw_line(Vector2(x + sway * 0.45, top_y + tile_size * 0.55), Vector2(x + dir * tile_size * 0.62, top_y + tile_size * 0.30), _with_alpha(color.lightened(0.18), color.a * 0.75), 1.5)

func _draw_stage_mist_band(size: Vector2, y: float, color: Color) -> void:
	var band := Rect2(Vector2(0.0, y), Vector2(size.x, tile_size * 0.82))
	var clear := Color(color.r, color.g, color.b, 0.0)
	draw_polygon(PackedVector2Array([
		band.position,
		band.position + Vector2(band.size.x, 0.0),
		band.position + band.size,
		band.position + Vector2(0.0, band.size.y)
	]), PackedColorArray([clear, clear, color, color]))

func _draw_ellipse_poly(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _update_title_label() -> void:
	if title_label == null:
		title_label = Label.new()
		title_label.position = Vector2(22, 8)
		title_label.size = Vector2(420, 32)
		title_label.z_index = 3901
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.add_theme_color_override("font_color", Color(0.94, 0.80, 0.48, 0.90))
		title_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 0.94))
		title_label.add_theme_constant_override("shadow_offset_x", 1)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(title_label)
	var title := str(current_region.get("name", "局部地图"))
	if current_mode == "shop":
		var shop: Dictionary = SHOP_DEFINITIONS.get(active_shop_id, {})
		title = "%s · %s" % [str(current_region.get("name", "")), str(shop.get("name", "商铺"))]
	title_label.text = title

func _draw_portals() -> void:
	for portal in portals:
		var tile_data: Array = portal.get("tile", [0, 0])
		var pos := tile_to_world(Vector2i(int(tile_data[0]), int(tile_data[1])))
		var highlighted := str(portal.get("id", "")) == highlighted_portal_id
		var color := Color(0.92, 0.70, 0.28, 0.78)
		var portal_type := str(portal.get("type", ""))
		if portal_type == "travel_region":
			color = Color(0.72, 0.84, 0.46, 0.82)
		elif portal_type == "landmark":
			color = Color(0.98, 0.76, 0.32, 0.84)
		elif portal_type == "resource":
			color = Color(0.58, 0.86, 0.40, 0.82)
		elif portal_type == "exit_world" or portal_type == "exit_area":
			color = Color(0.56, 0.78, 0.98, 0.75)
		draw_arc(pos, 18.0 if highlighted else 14.0, 0.0, TAU, 32, color, 2.4 if highlighted else 1.6)
		draw_circle(pos, 4.2 if highlighted else 3.0, color)

func _draw_portal_signs() -> void:
	for portal in portals:
		if str(portal.get("type", "")) != "shop":
			continue
		var tile_data: Array = portal.get("tile", [0, 0])
		var pos := tile_to_world(Vector2i(int(tile_data[0]), int(tile_data[1])))
		var shop: Dictionary = SHOP_DEFINITIONS.get(str(portal.get("shop_id", "")), {})
		var accent: Color = shop.get("accent", Color(0.86, 0.58, 0.28))
		var highlighted := str(portal.get("id", "")) == highlighted_portal_id
		_draw_stage_shop_entrance(pos, accent, highlighted)

func _draw_stage_shop_entrance(pos: Vector2, accent: Color, highlighted: bool) -> void:
	var alpha := LOCAL_TOWN_SHOP_ENTRANCE_ALPHA * (1.16 if highlighted else 1.0)
	var glow_alpha := LOCAL_TOWN_SHOP_DOOR_GLOW_ALPHA * (1.42 if highlighted else 1.0)
	var door_rect := Rect2(pos + Vector2(-38, -82), Vector2(76, 72))
	var shadow_rect := Rect2(pos + Vector2(-50, -90), Vector2(100, 90))
	draw_rect(shadow_rect, Color(0.03, 0.018, 0.010, alpha * 0.20), true)
	draw_rect(door_rect, Color(0.08, 0.04, 0.02, alpha * 0.72), true)
	draw_rect(door_rect.grow(-4.0), Color(0.16, 0.08, 0.04, alpha * 0.48), true)
	draw_polygon(PackedVector2Array([
		pos + Vector2(-56, -82),
		pos + Vector2(0, -110),
		pos + Vector2(56, -82),
		pos + Vector2(47, -68),
		pos + Vector2(-47, -68)
	]), PackedColorArray([
		Color(0.18, 0.07, 0.03, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.72),
		Color(0.16, 0.06, 0.03, alpha),
		Color(0.09, 0.04, 0.02, alpha * 0.92),
		Color(0.12, 0.05, 0.025, alpha * 0.96)
	]))
	draw_line(pos + Vector2(-46, -67), pos + Vector2(46, -67), Color(0.95, 0.75, 0.36, alpha * 0.54), 2.0)
	draw_line(pos + Vector2(-38, -78), pos + Vector2(-38, -10), Color(0.82, 0.52, 0.24, alpha * 0.46), 2.0)
	draw_line(pos + Vector2(38, -78), pos + Vector2(38, -10), Color(0.82, 0.52, 0.24, alpha * 0.40), 2.0)
	_draw_stage_shop_lantern(pos + Vector2(-48, -58), accent, alpha)
	_draw_stage_shop_lantern(pos + Vector2(48, -58), accent, alpha * 0.92)
	var sign_rect := Rect2(pos + Vector2(-LOCAL_TOWN_SHOP_SIGN_WIDTH * 0.5, -96), Vector2(LOCAL_TOWN_SHOP_SIGN_WIDTH, LOCAL_TOWN_SHOP_SIGN_HEIGHT))
	draw_rect(sign_rect, Color(0.18, 0.08, 0.035, alpha * 0.96), true)
	draw_rect(sign_rect.grow(-2.0), Color(accent.r * 0.50, accent.g * 0.36, accent.b * 0.24, alpha * 0.80), true)
	for x_ratio in [0.26, 0.50, 0.74]:
		var x := sign_rect.position.x + sign_rect.size.x * float(x_ratio)
		draw_line(Vector2(x, sign_rect.position.y + 5.0), Vector2(x - 5.0, sign_rect.position.y + sign_rect.size.y - 5.0), Color(0.96, 0.78, 0.42, alpha * 0.42), 1.1)
	draw_circle(pos + Vector2(0, -30), 24.0, Color(accent.r, accent.g, accent.b, glow_alpha * 0.42))
	draw_circle(pos + Vector2(0, -6), 18.0, Color(1.0, 0.74, 0.32, glow_alpha * 0.28))

func _draw_stage_shop_lantern(pos: Vector2, accent: Color, alpha: float) -> void:
	draw_line(pos + Vector2(0, -13), pos + Vector2(0, -3), Color(0.84, 0.64, 0.34, alpha * 0.52), 1.0)
	draw_circle(pos, 7.2, Color(0.80, 0.18, 0.10, alpha * 0.82))
	draw_circle(pos + Vector2(1.4, -0.8), 3.4, Color(accent.r, accent.g, accent.b, alpha * 0.56))
	draw_line(pos + Vector2(0, 7.0), pos + Vector2(0, 14.0), Color(0.92, 0.56, 0.24, alpha * 0.54), 1.0)

func _draw_scene_overlay() -> void:
	if current_mode == "shop":
		_draw_shop_overlay()
	else:
		_draw_region_overlay()

func _draw_region_overlay() -> void:
	var size := get_world_rect().size
	var region_type := str(current_region.get("type", "wild"))
	var terrain := str(current_region.get("terrain", ""))
	if region_type == "city":
		var wall_rect := Rect2(Vector2(5 * tile_size, 5 * tile_size), Vector2((map_width - 10) * tile_size, (map_height - 10) * tile_size))
		draw_rect(wall_rect, Color(0.52, 0.34, 0.17, 0.34), false, 5.0)
		for x in range(12, map_width - 12, 7):
			var north := tile_to_world(Vector2i(x, map_height / 2 - 4))
			var south := tile_to_world(Vector2i(x, map_height / 2 + 4))
			draw_circle(north, 3.0, Color(0.95, 0.54, 0.22, 0.42))
			draw_circle(south, 3.0, Color(0.95, 0.54, 0.22, 0.36))
	elif region_type == "town":
		draw_line(Vector2(4 * tile_size, 6 * tile_size), Vector2((map_width - 4) * tile_size, 5 * tile_size), Color(0.86, 0.72, 0.48, 0.24), 2.0)
		draw_line(Vector2(4 * tile_size, (map_height - 5) * tile_size), Vector2((map_width - 4) * tile_size, (map_height - 6) * tile_size), Color(0.34, 0.24, 0.13, 0.20), 2.0)
	elif region_type == "sect":
		draw_arc(Vector2(size.x * 0.5, size.y * 0.20), tile_size * 2.2, PI, TAU, 32, Color(0.92, 0.86, 0.62, 0.28), 3.0)
	else:
		if terrain.contains("mountain") or terrain.contains("peak") or terrain.contains("cliff"):
			for x in range(6, map_width - 6, 9):
				var p := tile_to_world(Vector2i(x, 7 + (x % 5)))
				draw_line(p + Vector2(-24, 20), p + Vector2(0, -18), Color(0.20, 0.19, 0.16, 0.24), 2.0)
				draw_line(p + Vector2(0, -18), p + Vector2(27, 23), Color(0.66, 0.62, 0.52, 0.20), 2.0)
		if _terrain_has_water(terrain):
			draw_line(Vector2(0, 14 * tile_size), Vector2(size.x, 13 * tile_size), Color(0.72, 0.86, 0.88, 0.16), 4.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.03, 0.015, 0.18), false, 3.0)

func _draw_shop_overlay() -> void:
	var size := get_world_rect().size
	var shop: Dictionary = SHOP_DEFINITIONS.get(active_shop_id, {})
	var accent: Color = shop.get("accent", Color(0.80, 0.54, 0.28))
	if RICH_SHOP_INTERIOR_ENABLED:
		_draw_rich_shop_interior(size, active_shop_id, accent)
		return
	_draw_legacy_shop_overlay(size, accent)

func _draw_legacy_shop_overlay(size: Vector2, accent: Color) -> void:
	draw_rect(Rect2(0, 0, size.x, tile_size * 2.0), Color(0.18, 0.10, 0.06, 0.48), true)
	draw_line(Vector2(tile_size, tile_size * 2.05), Vector2(size.x - tile_size, tile_size * 2.05), accent.darkened(0.25), 3.0)
	for x in range(3, map_width - 3, 5):
		var hanger := Vector2(x * tile_size + tile_size * 0.5, tile_size * 1.2)
		draw_line(hanger + Vector2(0, -10), hanger + Vector2(0, 8), Color(0.88, 0.70, 0.38, 0.45), 1.2)
		draw_circle(hanger + Vector2(0, 11), 4.0, accent.lightened(0.18))
	draw_rect(Rect2(Vector2(tile_size * 2, tile_size * 3), Vector2(size.x - tile_size * 4, tile_size * 0.34)), Color(0.86, 0.64, 0.34, 0.20), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.025, 0.015, 0.25), false, 3.0)

func _draw_rich_shop_interior(size: Vector2, shop_id: String, accent: Color) -> void:
	var wall_bottom := size.y * SHOP_INTERIOR_BACK_WALL_RATIO
	var floor_rect := Rect2(Vector2(0.0, wall_bottom), Vector2(size.x, size.y - wall_bottom))
	_draw_shop_wall(size, wall_bottom, accent)
	_draw_shop_floor(size, floor_rect, accent)
	_draw_shop_counter(size, wall_bottom, accent)
	_draw_shop_shelves(size, wall_bottom, accent)
	_draw_shop_theme_props(size, wall_bottom, shop_id, accent)
	_draw_shop_lighting(size, wall_bottom, accent)
	_draw_shop_foreground_frame(size, accent)

func _draw_shop_wall(size: Vector2, wall_bottom: float, accent: Color) -> void:
	_draw_stage_vertical_gradient(
		Rect2(Vector2.ZERO, Vector2(size.x, wall_bottom)),
		Color(0.22, 0.13, 0.075, 0.94),
		Color(0.39, 0.25, 0.145, 0.92)
	)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, tile_size * 0.62)), Color(0.055, 0.032, 0.020, 0.72), true)
	for x in range(2, map_width - 1, 5):
		var beam_x := x * tile_size
		draw_rect(Rect2(Vector2(beam_x, tile_size * 0.10), Vector2(tile_size * 0.34, wall_bottom + tile_size * 0.26)), Color(0.13, 0.070, 0.038, 0.58), true)
		draw_line(Vector2(beam_x + tile_size * 0.08, tile_size * 0.72), Vector2(beam_x + tile_size * 0.12, wall_bottom - tile_size * 0.32), Color(0.72, 0.48, 0.24, 0.16), 1.1)
	for i in range(4):
		var y := tile_size * (1.00 + float(i) * 0.88)
		draw_line(Vector2(tile_size * 1.1, y), Vector2(size.x - tile_size * 1.1, y - tile_size * 0.10), Color(0.09, 0.050, 0.030, 0.36), 2.0)
		draw_line(Vector2(tile_size * 1.1, y + tile_size * 0.10), Vector2(size.x - tile_size * 1.1, y), Color(accent.r, accent.g, accent.b, 0.09), 1.0)
	draw_rect(Rect2(Vector2(tile_size * 1.0, wall_bottom - tile_size * 0.26), Vector2(size.x - tile_size * 2.0, tile_size * 0.22)), Color(0.08, 0.045, 0.025, 0.54), true)

func _draw_shop_floor(size: Vector2, floor_rect: Rect2, accent: Color) -> void:
	_draw_stage_vertical_gradient(
		floor_rect,
		Color(0.45, 0.32, 0.19, 0.90),
		Color(0.20, 0.12, 0.075, 0.94)
	)
	var top_y := floor_rect.position.y
	var bottom_y := floor_rect.end.y
	for i in range(9):
		var t := float(i) / 8.0
		var y := lerpf(top_y + tile_size * 0.15, bottom_y - tile_size * 0.44, t * t)
		draw_line(Vector2(tile_size * (0.8 - t * 0.7), y), Vector2(size.x - tile_size * (0.8 - t * 0.7), y - tile_size * 0.10), Color(0.09, 0.052, 0.032, 0.25), 1.2 + t * 1.8)
	for i in range(12):
		var t := float(i) / 11.0
		var x := lerpf(tile_size * 0.7, size.x - tile_size * 0.7, t)
		draw_line(Vector2(x, bottom_y), Vector2(lerpf(size.x * 0.44, size.x * 0.56, t), top_y + tile_size * 0.05), Color(0.12, 0.070, 0.045, 0.15), 1.0)
	_draw_ellipse_poly(Vector2(size.x * 0.50, top_y + tile_size * 2.35), Vector2(size.x * 0.33, tile_size * 0.34), Color(accent.r, accent.g, accent.b, 0.10))
	draw_rect(Rect2(Vector2(0.0, size.y - tile_size * 1.05), Vector2(size.x, tile_size * 1.10)), Color(0.020, 0.014, 0.010, 0.38), true)

func _draw_shop_counter(size: Vector2, wall_bottom: float, accent: Color) -> void:
	var counter_rect := Rect2(Vector2(size.x * 0.13, wall_bottom - tile_size * 1.38), Vector2(size.x * 0.74, tile_size * 1.48))
	draw_rect(counter_rect.grow(5.0), Color(0.035, 0.020, 0.012, SHOP_INTERIOR_COUNTER_ALPHA * 0.36), true)
	draw_rect(counter_rect, Color(0.25, 0.13, 0.065, SHOP_INTERIOR_COUNTER_ALPHA), true)
	draw_rect(Rect2(counter_rect.position, Vector2(counter_rect.size.x, tile_size * 0.23)), Color(0.56, 0.32, 0.14, SHOP_INTERIOR_COUNTER_ALPHA * 0.82), true)
	for i in range(7):
		var x := counter_rect.position.x + counter_rect.size.x * (float(i) + 0.5) / 7.0
		draw_line(Vector2(x, counter_rect.position.y + tile_size * 0.18), Vector2(x - tile_size * 0.06, counter_rect.end.y - tile_size * 0.08), Color(0.08, 0.045, 0.026, 0.34), 1.2)
	draw_line(counter_rect.position + Vector2(tile_size * 0.28, tile_size * 0.44), counter_rect.position + Vector2(counter_rect.size.x - tile_size * 0.28, tile_size * 0.34), Color(accent.r, accent.g, accent.b, 0.30), 1.5)

func _draw_shop_shelves(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for side in [-1.0, 1.0]:
		var x := size.x * (0.16 if side < 0.0 else 0.84)
		var shelf := Rect2(Vector2(x - tile_size * 2.05, tile_size * 1.26), Vector2(tile_size * 4.10, wall_bottom - tile_size * 2.05))
		draw_rect(shelf, Color(0.12, 0.065, 0.035, SHOP_INTERIOR_SHELF_ALPHA), true)
		draw_rect(shelf, Color(0.80, 0.55, 0.28, SHOP_INTERIOR_SHELF_ALPHA * 0.38), false, 1.5)
		for row in range(3):
			var y := shelf.position.y + tile_size * (0.62 + float(row) * 1.02)
			draw_line(Vector2(shelf.position.x + tile_size * 0.18, y), Vector2(shelf.end.x - tile_size * 0.18, y - tile_size * 0.04), Color(0.62, 0.38, 0.18, SHOP_INTERIOR_SHELF_ALPHA * 0.64), 2.0)
			for col in range(4):
				var px := shelf.position.x + tile_size * (0.54 + float(col) * 0.86)
				var item_color := accent.lightened(0.10 + float((row + col) % 3) * 0.08)
				draw_circle(Vector2(px, y - tile_size * 0.20), 3.8 + float((row + col) % 2), Color(item_color.r, item_color.g, item_color.b, 0.55))

func _draw_shop_theme_props(size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	match shop_id:
		"blacksmith":
			_draw_shop_blacksmith_props(size, wall_bottom, accent)
		"medicine":
			_draw_shop_medicine_props(size, wall_bottom, accent)
		"inn":
			_draw_shop_inn_props(size, wall_bottom, accent)
		"tailor":
			_draw_shop_tailor_props(size, wall_bottom, accent)
		"market":
			_draw_shop_market_props(size, wall_bottom, accent)
		"teahouse":
			_draw_shop_teahouse_props(size, wall_bottom, accent)
		_:
			_draw_shop_market_props(size, wall_bottom, accent)

func _draw_shop_blacksmith_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	var forge := Vector2(size.x * 0.76, wall_bottom + tile_size * 1.10)
	_draw_ellipse_poly(forge + Vector2(0, tile_size * 0.38), Vector2(tile_size * 1.50, tile_size * 0.26), Color(0.0, 0.0, 0.0, 0.30))
	draw_rect(Rect2(forge - Vector2(tile_size * 1.00, tile_size * 0.42), Vector2(tile_size * 2.00, tile_size * 0.86)), Color(0.14, 0.075, 0.045, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
	draw_circle(forge, tile_size * 0.40, Color(1.0, 0.30, 0.12, 0.40))
	draw_circle(forge, tile_size * 0.20, Color(1.0, 0.74, 0.24, 0.55))
	var anvil := Vector2(size.x * 0.30, wall_bottom + tile_size * 2.25)
	draw_rect(Rect2(anvil - Vector2(tile_size * 0.54, tile_size * 0.18), Vector2(tile_size * 1.08, tile_size * 0.34)), Color(0.18, 0.18, 0.17, 0.82), true)
	draw_line(anvil + Vector2(-tile_size * 0.62, -tile_size * 0.10), anvil + Vector2(tile_size * 0.76, -tile_size * 0.16), Color(0.70, 0.68, 0.58, 0.42), 2.0)
	for i in range(4):
		var x := size.x * (0.46 + float(i) * 0.055)
		draw_line(Vector2(x, tile_size * 1.50), Vector2(x + tile_size * 0.46, wall_bottom - tile_size * 0.30), Color(0.80, 0.82, 0.76, 0.42), 2.0)

func _draw_shop_medicine_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	var cabinet := Rect2(Vector2(size.x * 0.37, tile_size * 1.20), Vector2(size.x * 0.26, wall_bottom - tile_size * 1.72))
	draw_rect(cabinet, Color(0.15, 0.08, 0.045, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
	for row in range(4):
		for col in range(5):
			var cell := Rect2(cabinet.position + Vector2(tile_size * (0.20 + col * 0.72), tile_size * (0.22 + row * 0.55)), Vector2(tile_size * 0.52, tile_size * 0.34))
			draw_rect(cell, Color(0.34, 0.20, 0.10, 0.74), true)
			draw_circle(cell.get_center() + Vector2(0.0, tile_size * 0.08), 1.6, Color(accent.r, accent.g, accent.b, 0.46))
	for i in range(6):
		var p := Vector2(size.x * (0.23 + float(i) * 0.09), wall_bottom + tile_size * (1.0 + float(i % 2) * 0.28))
		draw_line(p, p + Vector2(tile_size * 0.12, -tile_size * 0.54), Color(0.20, 0.42, 0.18, 0.58), 1.4)
		draw_circle(p + Vector2(tile_size * 0.10, -tile_size * 0.58), 4.5, Color(accent.r, accent.g, accent.b, 0.48))

func _draw_shop_inn_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(3):
		var center := Vector2(size.x * (0.28 + float(i) * 0.22), wall_bottom + tile_size * (1.95 + float(i % 2) * 0.25))
		_draw_ellipse_poly(center, Vector2(tile_size * 0.72, tile_size * 0.20), Color(0.09, 0.050, 0.030, 0.42))
		draw_rect(Rect2(center - Vector2(tile_size * 0.62, tile_size * 0.18), Vector2(tile_size * 1.24, tile_size * 0.28)), Color(0.29, 0.16, 0.075, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
		draw_line(center + Vector2(-tile_size * 0.50, -tile_size * 0.13), center + Vector2(tile_size * 0.54, -tile_size * 0.18), Color(accent.r, accent.g, accent.b, 0.32), 1.2)
	for x in [size.x * 0.14, size.x * 0.86]:
		for j in range(2):
			var jar := Vector2(x + float(j) * tile_size * 0.38 * (-1.0 if x > size.x * 0.5 else 1.0), wall_bottom + tile_size * (2.70 + float(j) * 0.08))
			draw_circle(jar, tile_size * 0.20, Color(0.34, 0.13, 0.075, 0.76))
			draw_rect(Rect2(jar + Vector2(-tile_size * 0.11, -tile_size * 0.28), Vector2(tile_size * 0.22, tile_size * 0.16)), Color(0.52, 0.26, 0.11, 0.72), true)

func _draw_shop_tailor_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(6):
		var x := size.x * (0.21 + float(i) * 0.105)
		var top := wall_bottom - tile_size * (0.20 + float(i % 2) * 0.12)
		draw_line(Vector2(x, top), Vector2(x + tile_size * 0.18, wall_bottom + tile_size * 1.58), Color(accent.r, accent.g, accent.b, 0.52), 5.0)
		draw_line(Vector2(x + tile_size * 0.16, top + tile_size * 0.10), Vector2(x + tile_size * 0.34, wall_bottom + tile_size * 1.62), Color(0.92, 0.74, 0.88, 0.34), 3.0)
	var stand := Vector2(size.x * 0.78, wall_bottom + tile_size * 1.54)
	draw_line(stand + Vector2(0, -tile_size * 1.08), stand, Color(0.16, 0.08, 0.05, 0.72), 2.0)
	draw_polygon(PackedVector2Array([stand + Vector2(0, -tile_size * 1.10), stand + Vector2(tile_size * 0.42, -tile_size * 0.40), stand + Vector2(0, tile_size * 0.10), stand + Vector2(-tile_size * 0.42, -tile_size * 0.40)]), PackedColorArray([Color(accent.r, accent.g, accent.b, 0.44), Color(accent.r, accent.g, accent.b, 0.30), Color(accent.r, accent.g, accent.b, 0.24), Color(accent.r, accent.g, accent.b, 0.30)]))

func _draw_shop_market_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(8):
		var x := size.x * (0.17 + float(i % 4) * 0.19)
		var y := wall_bottom + tile_size * (1.35 + float(i / 4) * 1.18)
		var crate := Rect2(Vector2(x - tile_size * 0.36, y - tile_size * 0.20), Vector2(tile_size * 0.72, tile_size * 0.42))
		draw_rect(crate, Color(0.26, 0.14, 0.07, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
		draw_line(crate.position + Vector2(tile_size * 0.08, tile_size * 0.10), crate.end - Vector2(tile_size * 0.08, tile_size * 0.14), Color(accent.r, accent.g, accent.b, 0.28), 1.0)
		draw_circle(Vector2(x, y - tile_size * 0.30), 5.0 + float(i % 3), Color(accent.r, accent.g, accent.b, 0.44))

func _draw_shop_teahouse_props(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(2):
		var center := Vector2(size.x * (0.36 + float(i) * 0.28), wall_bottom + tile_size * 2.08)
		_draw_ellipse_poly(center, Vector2(tile_size * 0.72, tile_size * 0.18), Color(0.04, 0.028, 0.018, 0.35))
		draw_circle(center, tile_size * 0.34, Color(0.24, 0.13, 0.07, SHOP_INTERIOR_THEME_PROP_ALPHA * 0.92))
		draw_circle(center + Vector2(tile_size * 0.18, -tile_size * 0.07), tile_size * 0.09, Color(accent.r, accent.g, accent.b, 0.46))
	var screen := Rect2(Vector2(size.x * 0.13, tile_size * 1.20), Vector2(size.x * 0.18, wall_bottom - tile_size * 1.18))
	draw_rect(screen, Color(0.12, 0.085, 0.052, 0.68), true)
	for i in range(3):
		var x := screen.position.x + screen.size.x * float(i + 1) / 4.0
		draw_line(Vector2(x, screen.position.y + tile_size * 0.20), Vector2(x, screen.end.y - tile_size * 0.20), Color(accent.r, accent.g, accent.b, 0.24), 1.0)

func _draw_shop_lighting(size: Vector2, wall_bottom: float, accent: Color) -> void:
	for x in [size.x * 0.24, size.x * 0.50, size.x * 0.76]:
		var y := tile_size * 1.06
		draw_line(Vector2(x, tile_size * 0.48), Vector2(x, y), Color(0.88, 0.70, 0.38, 0.38), 1.1)
		draw_circle(Vector2(x, y + tile_size * 0.18), tile_size * 0.14, Color(accent.r, accent.g, accent.b, 0.74))
		_draw_ellipse_poly(Vector2(x, wall_bottom + tile_size * 0.10), Vector2(tile_size * 1.28, tile_size * 0.24), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_LIGHT_ALPHA * 0.25))
	_draw_stage_vertical_gradient(Rect2(Vector2(0.0, 0.0), size), Color(0.0, 0.0, 0.0, 0.12), Color(0.0, 0.0, 0.0, 0.30))

func _draw_shop_foreground_frame(size: Vector2, accent: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.015, 0.010, 0.34), false, 4.0)
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(size.x, tile_size * 0.42)), Color(0.025, 0.015, 0.010, 0.66), true)
	draw_rect(Rect2(Vector2(0.0, size.y - tile_size * 0.38), Vector2(size.x, tile_size * 0.42)), Color(0.010, 0.007, 0.005, 0.54), true)
	draw_line(Vector2(tile_size * 0.55, tile_size * 0.58), Vector2(size.x - tile_size * 0.55, tile_size * 0.48), Color(accent.r, accent.g, accent.b, 0.18), 1.5)

func _draw_tile_detail(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	var seed := (x * 31 + y * 17) % 19
	match tile_id:
		Tile.ROAD:
			draw_line(rect.position + Vector2(0, 28), rect.position + Vector2(48, 20), Color(0.78, 0.68, 0.48, 0.25), 1.6)
			if (x + y) % 5 == 0:
				draw_circle(rect.get_center() + Vector2(seed - 8, 6), 1.5, Color(0.24, 0.18, 0.12, 0.24))
		Tile.WATER:
			draw_line(rect.position + Vector2(5, 18), rect.position + Vector2(43, 15), Color(0.72, 0.88, 0.94, 0.24), 2.0)
			draw_line(rect.position + Vector2(7, 32), rect.position + Vector2(41, 29), Color(0.08, 0.18, 0.26, 0.22), 1.4)
		Tile.BUILDING, Tile.SHOP:
			if not _has_tile(x, y - 1, tile_id):
				draw_polygon(PackedVector2Array([rect.position + Vector2(0, 22), rect.position + Vector2(24, 6), rect.position + Vector2(48, 22), rect.position + Vector2(42, 28), rect.position + Vector2(6, 28)]), PackedColorArray([Color(0.32, 0.15, 0.08, 0.58), Color(0.72, 0.40, 0.20, 0.64), Color(0.32, 0.15, 0.08, 0.58), Color(0.40, 0.22, 0.12, 0.58), Color(0.40, 0.22, 0.12, 0.58)]))
				if tile_id == Tile.SHOP:
					draw_rect(Rect2(rect.position + Vector2(8, 29), Vector2(32, 5)), Color(0.92, 0.68, 0.28, 0.45), true)
			elif not _has_tile(x, y + 1, tile_id):
				draw_rect(Rect2(rect.position + Vector2(5, 34), Vector2(38, 5)), Color(0.22, 0.10, 0.06, 0.30), true)
		Tile.GARDEN:
			draw_circle(rect.get_center() + Vector2(-6, 2), 9.0, Color(0.13, 0.34, 0.16, 0.38))
			draw_circle(rect.get_center() + Vector2(7, -4), 7.0, Color(0.28, 0.48, 0.20, 0.34))
		Tile.FIELD:
			for i in range(3):
				draw_line(rect.position + Vector2(5, 13 + i * 9), rect.position + Vector2(43, 8 + i * 9), Color(0.70, 0.70, 0.34, 0.28), 1.4)
		Tile.MOUNTAIN:
			if not _has_tile(x, y - 1, tile_id) or (x + y) % 4 == 0:
				draw_polygon(PackedVector2Array([rect.position + Vector2(5, 40), rect.position + Vector2(24, 9), rect.position + Vector2(43, 40)]), PackedColorArray([Color(0.22, 0.22, 0.20, 0.55), Color(0.54, 0.52, 0.46, 0.55), Color(0.18, 0.18, 0.17, 0.55)]))
		Tile.FLOOR:
			if (x + y) % 4 == 0:
				draw_line(rect.position + Vector2(4, 34), rect.position + Vector2(44, 29), Color(0.48, 0.38, 0.24, 0.16), 1.2)
		Tile.COUNTER:
			draw_rect(Rect2(rect.position + Vector2(3, 8), Vector2(42, 27)), Color(0.30, 0.17, 0.09, 0.70), true)
			draw_line(rect.position + Vector2(4, 13), rect.position + Vector2(44, 13), Color(0.82, 0.58, 0.28, 0.45), 2.0)
		Tile.CARPET:
			draw_rect(Rect2(rect.position + Vector2(6, 8), Vector2(36, 30)), Color(0.40, 0.13, 0.10, 0.42), true)
			draw_rect(Rect2(rect.position + Vector2(9, 11), Vector2(30, 24)), Color(0.72, 0.45, 0.20, 0.18), false, 1.0)
		Tile.BRIDGE:
			draw_line(rect.position + Vector2(5, 18), rect.position + Vector2(43, 18), Color(0.68, 0.45, 0.22, 0.72), 3.0)
			draw_line(rect.position + Vector2(5, 29), rect.position + Vector2(43, 29), Color(0.68, 0.45, 0.22, 0.72), 3.0)

func _draw_local_building_surface_detail(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if not _is_local_building_tile(tile_id):
		return
	var base := _local_building_wireframe_color(tile_id)
	STAGE_SURFACE_DETAIL_RENDERER.draw_building_surface_detail(
		self,
		rect,
		base,
		x,
		y,
		LOCAL_BUILDING_SURFACE_STROKE_COUNT,
		LOCAL_BUILDING_SURFACE_DOT_COUNT,
		LOCAL_BUILDING_SURFACE_ALPHA,
		LOCAL_BUILDING_SURFACE_SEED_BASE,
		LOCAL_BUILDING_SURFACE_LINE_JITTER,
		StageVisualProfile.LOCAL_BUILDING_SURFACE_NOISE_SCALE
	)
	STAGE_SURFACE_DETAIL_RENDERER.draw_building_facade_detail(
		self,
		rect,
		base,
		x,
		y,
		LOCAL_BUILDING_FACADE_PILLAR_COUNT,
		LOCAL_BUILDING_FACADE_WINDOW_ROWS,
		LOCAL_BUILDING_FACADE_WINDOW_COLUMNS,
		LOCAL_BUILDING_FACADE_WINDOW_ALPHA,
		LOCAL_BUILDING_FACADE_SHADOW_ALPHA,
		LOCAL_BUILDING_FACADE_SEED_BASE,
		LOCAL_BUILDING_FACADE_LINE_JITTER,
		StageVisualProfile.LOCAL_BUILDING_FACADE_NOISE_SCALE
	)

func _tile_color(tile_id: int) -> Color:
	match tile_id:
		Tile.ROAD:
			return Color(0.54, 0.47, 0.34)
		Tile.WATER:
			return Color(0.14, 0.33, 0.45)
		Tile.BUILDING:
			return Color(0.40, 0.28, 0.18)
		Tile.SHOP:
			return Color(0.56, 0.37, 0.20)
		Tile.WALL:
			return Color(0.22, 0.18, 0.14)
		Tile.GARDEN:
			return Color(0.24, 0.40, 0.22)
		Tile.FIELD:
			return Color(0.40, 0.49, 0.25)
		Tile.MOUNTAIN:
			return Color(0.34, 0.35, 0.30)
		Tile.BRIDGE:
			return Color(0.42, 0.27, 0.14)
		Tile.FLOOR:
			return Color(0.46, 0.38, 0.25)
		Tile.COUNTER:
			return Color(0.31, 0.20, 0.12)
		Tile.CARPET:
			return Color(0.42, 0.18, 0.13)
		_:
			return Color(0.30, 0.45, 0.27)

func _tile_tint(tile_id: int) -> Color:
	match tile_id:
		Tile.ROAD:
			return Color(0.86, 0.72, 0.46, 0.12)
		Tile.WATER:
			return Color(0.08, 0.25, 0.36, 0.10)
		Tile.BUILDING:
			return Color(0.28, 0.13, 0.07, 0.10)
		Tile.SHOP:
			return Color(0.70, 0.34, 0.12, 0.08)
		Tile.WALL:
			return Color(0.16, 0.10, 0.06, 0.22)
		Tile.GARDEN:
			return Color(0.08, 0.26, 0.12, 0.08)
		Tile.FIELD:
			return Color(0.72, 0.62, 0.28, 0.08)
		Tile.MOUNTAIN:
			return Color(0.16, 0.15, 0.13, 0.12)
		Tile.FLOOR:
			return Color(0.62, 0.45, 0.25, 0.16)
		Tile.COUNTER:
			return Color(0.18, 0.08, 0.03, 0.20)
		Tile.CARPET:
			return Color(0.48, 0.10, 0.06, 0.18)
		_:
			return Color.TRANSPARENT

func _draw_tile_transition(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if tile_id == Tile.WATER:
		_draw_edge_if_missing(rect, x, y, Tile.WATER, Vector2(0, 0), Vector2(tile_size, 0), Vector2i(0, -1), Color(0.84, 0.74, 0.50, 0.26), 2.0)
		_draw_edge_if_missing(rect, x, y, Tile.WATER, Vector2(0, tile_size), Vector2(tile_size, tile_size), Vector2i(0, 1), Color(0.84, 0.74, 0.50, 0.22), 2.0)
		_draw_edge_if_missing(rect, x, y, Tile.WATER, Vector2(0, 0), Vector2(0, tile_size), Vector2i(-1, 0), Color(0.84, 0.74, 0.50, 0.22), 2.0)
		_draw_edge_if_missing(rect, x, y, Tile.WATER, Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2i(1, 0), Color(0.84, 0.74, 0.50, 0.22), 2.0)
	elif tile_id == Tile.ROAD:
		var edge_color := Color(0.30, 0.20, 0.10, 0.16)
		_draw_edge_if_missing(rect, x, y, Tile.ROAD, Vector2(0, 0), Vector2(tile_size, 0), Vector2i(0, -1), edge_color, 1.2)
		_draw_edge_if_missing(rect, x, y, Tile.ROAD, Vector2(0, tile_size), Vector2(tile_size, tile_size), Vector2i(0, 1), edge_color, 1.2)
		_draw_edge_if_missing(rect, x, y, Tile.ROAD, Vector2(0, 0), Vector2(0, tile_size), Vector2i(-1, 0), edge_color, 1.2)
		_draw_edge_if_missing(rect, x, y, Tile.ROAD, Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2i(1, 0), edge_color, 1.2)
	elif tile_id == Tile.GARDEN or tile_id == Tile.FIELD:
		if not _has_tile(x, y - 1, tile_id):
			draw_line(rect.position, rect.position + Vector2(tile_size, 0), Color(0.16, 0.28, 0.10, 0.16), 1.0)

func _draw_edge_if_missing(rect: Rect2, x: int, y: int, tile_id: int, start: Vector2, end: Vector2, offset: Vector2i, color: Color, width: float) -> void:
	if not _has_tile(x + offset.x, y + offset.y, tile_id):
		draw_line(rect.position + start, rect.position + end, color, width)

func _has_tile(x: int, y: int, tile_id: int) -> bool:
	if x < 0 or y < 0 or x >= map_width or y >= map_height:
		return false
	return int(tiles[y][x]) == tile_id

func _tile_seed(x: int, y: int) -> int:
	return abs((x * 928371 + y * 689287 + x * y * 37) % 9973)

func _paint_line(points: Array, tile_id: int, radius: int = 0) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		var start := Vector2(points[index].x, points[index].y)
		var end := Vector2(points[index + 1].x, points[index + 1].y)
		var steps := int(max(abs(end.x - start.x), abs(end.y - start.y)) * 3.0) + 1
		for step in range(steps + 1):
			var t := float(step) / float(max(steps, 1))
			var point := start.lerp(end, t)
			for ox in range(-radius, radius + 1):
				for oy in range(-radius, radius + 1):
					_set_tile(roundi(point.x) + ox, roundi(point.y) + oy, tile_id)

func _fill_rect(rect: Rect2i, tile_id: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_set_tile(x, y, tile_id)

func _set_tile(x: int, y: int, tile_id: int) -> void:
	if x < 0 or y < 0 or x >= map_width or y >= map_height:
		return
	if tile_id == Tile.ROAD and tiles[y][x] == Tile.WATER:
		tiles[y][x] = Tile.BRIDGE
	else:
		tiles[y][x] = tile_id

func _color_to_array(color: Color) -> Array:
	return [color.r, color.g, color.b]
