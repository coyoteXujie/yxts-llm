extends Node2D
class_name WorldMap

enum Tile {
	GRASS,
	ROAD,
	WATER,
	BUILDING,
	FOREST,
	COURTYARD,
	SECT,
	SNOW,
	BRIDGE,
	FIELD,
	MOUNTAIN,
	CITY,
	TOWN,
	VILLAGE,
	SHOP,
	TEMPLE,
	MARSH,
	DESERT,
	BAMBOO,
	CLIFF
}

const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const MAP_PROP_SCRIPT := preload("res://scripts/world/map_prop.gd")

const TILE_TEXTURE_PATHS := {
	Tile.GRASS: "res://assets/world/tiles/tile_grass.png",
	Tile.ROAD: "res://assets/world/tiles/tile_road.png",
	Tile.WATER: "res://assets/world/tiles/tile_water.png",
	Tile.BUILDING: "res://assets/world/tiles/tile_building.png",
	Tile.FOREST: "res://assets/world/tiles/tile_forest.png",
	Tile.COURTYARD: "res://assets/world/tiles/tile_courtyard.png",
	Tile.SECT: "res://assets/world/tiles/tile_sect.png",
	Tile.SNOW: "res://assets/world/tiles/tile_snow.png",
	Tile.BRIDGE: "res://assets/world/tiles/tile_bridge.png",
	Tile.FIELD: "res://assets/world/tiles/tile_field.png",
	Tile.MOUNTAIN: "res://assets/world/tiles/tile_mountain.png",
	Tile.CITY: "res://assets/world/tiles/tile_city.png",
	Tile.TOWN: "res://assets/world/tiles/tile_town.png",
	Tile.VILLAGE: "res://assets/world/tiles/tile_village.png",
	Tile.SHOP: "res://assets/world/tiles/tile_shop.png",
	Tile.TEMPLE: "res://assets/world/tiles/tile_temple.png",
	Tile.MARSH: "res://assets/world/tiles/tile_marsh.png",
	Tile.DESERT: "res://assets/world/tiles/tile_desert.png",
	Tile.BAMBOO: "res://assets/world/tiles/tile_bamboo.png",
	Tile.CLIFF: "res://assets/world/tiles/tile_cliff.png",
}

const LANDMARKS := [
	{"name": "八卦门", "tile": [23, 7], "size": 17, "color": [0.90, 0.78, 0.46]},
	{"name": "雪山派", "tile": [48, 6], "size": 17, "color": [0.82, 0.92, 1.00]},
	{"name": "洛阳城", "tile": [43, 18], "size": 20, "color": [0.96, 0.78, 0.42]},
	{"name": "平安镇", "tile": [30, 14], "size": 15, "color": [0.92, 0.82, 0.58]},
	{"name": "黄河古道", "tile": [58, 14], "size": 14, "color": [0.74, 0.86, 0.92]},
	{"name": "长安城", "tile": [20, 30], "size": 20, "color": [0.96, 0.78, 0.42]},
	{"name": "红莲教", "tile": [39, 34], "size": 17, "color": [1.00, 0.45, 0.32]},
	{"name": "太极门", "tile": [66, 31], "size": 17, "color": [0.88, 0.88, 0.82]},
	{"name": "那迦派", "tile": [80, 33], "size": 17, "color": [0.64, 0.86, 0.56]},
	{"name": "江陵城", "tile": [66, 39], "size": 20, "color": [0.96, 0.78, 0.42]},
	{"name": "成都城", "tile": [22, 53], "size": 20, "color": [0.96, 0.78, 0.42]},
	{"name": "临安城", "tile": [79, 54], "size": 20, "color": [0.96, 0.78, 0.42]},
	{"name": "逍遥宫", "tile": [83, 62], "size": 17, "color": [0.70, 0.90, 0.72]},
	{"name": "花间派", "tile": [88, 46], "size": 17, "color": [1.00, 0.70, 0.82]},
]

const WORLD_NPC_SCALE := 0.58
const WORLD_NPC_MIN_SPACING := 4
const TILE_VARIANT_COUNT := 4

var tile_size := GameData.TILE_SIZE
var map_width := GameData.MAP_WIDTH
var map_height := GameData.MAP_HEIGHT
var tiles: Array = []
var npc_nodes: Array = []
var landmark_labels: Array[Label] = []
var prop_nodes: Array[Node2D] = []
var tile_textures: Dictionary = {}
var target_region_id := ""
var world_npc_tiles: Array[Vector2i] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_tile_textures()
	generate_map()
	_build_depth_props()
	_build_landmark_labels()
	spawn_npcs()
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

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size * 0.5, tile.y * tile_size + tile_size * 0.5)

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / tile_size), floori(world_position.y / tile_size))

func get_region_at_world_position(world_position: Vector2) -> Dictionary:
	return GameData.get_region_at_tile(world_to_tile(world_position))

func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_width * tile_size, map_height * tile_size))

func set_target_region(region_id: String) -> void:
	target_region_id = region_id
	queue_redraw()

func get_region_entry_position(region_id: String) -> Vector2:
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return tile_to_world(Vector2i(30, 17))
	var center := _region_center_tile(region)
	var entry_tile := _find_walkable_tile_in_region(region, center)
	return tile_to_world(entry_tile)

func generate_map() -> void:
	tiles.clear()
	for y in range(map_height):
		var row: Array = []
		for _x in range(map_width):
			row.append(Tile.GRASS)
		tiles.append(row)

	_paint_world_biomes()
	_paint_rivers()
	_paint_regions()
	_paint_roads()
	_paint_bridges()

func _paint_world_biomes() -> void:
	_paint_mountain_biome(Rect2i(0, 0, 96, 8), Tile.GRASS, Tile.MOUNTAIN, 9)
	_rough_fill_rect(Rect2i(0, 8, 15, 10), Tile.FOREST)
	_paint_mountain_biome(Rect2i(38, 5, 20, 12), Tile.SNOW, Tile.MOUNTAIN, 7)
	_paint_mountain_biome(Rect2i(30, 31, 30, 6), Tile.GRASS, Tile.MOUNTAIN, 8)
	_rough_fill_rect(Rect2i(6, 39, 18, 11), Tile.DESERT)
	_rough_fill_rect(Rect2i(4, 55, 22, 17), Tile.BAMBOO)
	_rough_fill_rect(Rect2i(24, 54, 15, 14), Tile.FIELD)
	_rough_fill_rect(Rect2i(56, 31, 18, 9), Tile.FOREST)
	_rough_fill_rect(Rect2i(68, 38, 18, 13), Tile.MARSH)
	_rough_fill_rect(Rect2i(80, 42, 16, 12), Tile.FOREST)
	_rough_fill_rect(Rect2i(73, 55, 22, 15), Tile.MARSH)
	_paint_mountain_biome(Rect2i(47, 9, 9, 7), Tile.GRASS, Tile.CLIFF, 5)
	_rough_fill_rect(Rect2i(54, 58, 14, 9), Tile.FIELD)

func _paint_mountain_biome(rect: Rect2i, base_tile: int, obstacle_tile: int, density: int) -> void:
	_rough_fill_rect(rect, base_tile)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var seed: int = _tile_seed(x, y)
			var ridge_band: bool = abs((y - rect.position.y) * 3 - (x - rect.position.x)) % 13 == 0
			var should_peak: bool = seed % density == 0 or (ridge_band and seed % 3 == 0)
			if should_peak:
				_set_tile(x, y, obstacle_tile)
				if seed % 5 == 0:
					_set_tile(x + 1, y, obstacle_tile)

func _paint_rivers() -> void:
	_paint_line([Vector2i(-2, 16), Vector2i(16, 15), Vector2i(36, 17), Vector2i(60, 15), Vector2i(98, 13)], Tile.WATER, 1, true)
	_paint_line([Vector2i(35, 21), Vector2i(43, 23), Vector2i(53, 22), Vector2i(61, 24)], Tile.WATER, 0, true)
	_paint_line([Vector2i(47, 49), Vector2i(61, 48), Vector2i(76, 50), Vector2i(98, 52)], Tile.WATER, 1, true)
	_paint_line([Vector2i(20, 51), Vector2i(19, 58), Vector2i(21, 71)], Tile.WATER, 0, true)
	_paint_line([Vector2i(66, 36), Vector2i(68, 43), Vector2i(73, 50)], Tile.WATER, 0, true)
	_fill_rect(Rect2i(77, 59, 13, 8), Tile.WATER)

func _paint_regions() -> void:
	_paint_city(Rect2i(35, 20, 18, 10), "luoyang")
	_paint_city(Rect2i(12, 31, 17, 10), "changan")
	_paint_city(Rect2i(14, 55, 18, 10), "chengdu")
	_paint_city(Rect2i(58, 40, 17, 10), "jiangling")
	_paint_city(Rect2i(73, 55, 18, 10), "linan")

	_paint_town(Rect2i(26, 13, 9, 7))
	_paint_town(Rect2i(51, 18, 7, 5))
	_paint_town(Rect2i(57, 14, 7, 5))
	_paint_town(Rect2i(72, 10, 7, 5))
	_paint_town(Rect2i(6, 31, 6, 5))
	_paint_town(Rect2i(18, 26, 7, 5))
	_paint_town(Rect2i(30, 34, 7, 5))
	_paint_town(Rect2i(8, 45, 7, 5))
	_paint_town(Rect2i(70, 52, 6, 5))
	_paint_town(Rect2i(84, 54, 7, 5))
	_paint_town(Rect2i(79, 47, 7, 5))
	_paint_town(Rect2i(12, 51, 6, 5))
	_paint_town(Rect2i(34, 55, 7, 5))
	_paint_town(Rect2i(34, 63, 7, 5))
	_paint_town(Rect2i(78, 47, 7, 5))
	_paint_town(Rect2i(50, 42, 7, 5))

	_paint_village(Rect2i(38, 44, 8, 5))
	_paint_village(Rect2i(6, 25, 8, 5))
	_paint_village(Rect2i(50, 58, 7, 5))
	_paint_village(Rect2i(83, 29, 7, 5))

	_paint_sect(Rect2i(20, 8, 8, 6), "bagua")
	_paint_sect(Rect2i(44, 7, 9, 6), "xueshan")
	_paint_sect(Rect2i(36, 34, 8, 6), "honglian")
	_paint_sect(Rect2i(63, 32, 8, 6), "taiji")
	_paint_sect(Rect2i(77, 34, 8, 6), "naja")
	_paint_sect(Rect2i(84, 47, 8, 6), "flower")
	_paint_sect(Rect2i(80, 61, 8, 5), "xiaoyao")

func _paint_roads() -> void:
	_paint_line([Vector2i(43, 25), Vector2i(34, 22), Vector2i(30, 17), Vector2i(24, 12)], Tile.ROAD, 1)
	_paint_line([Vector2i(43, 25), Vector2i(30, 29), Vector2i(21, 36)], Tile.ROAD, 1)
	_paint_line([Vector2i(20, 36), Vector2i(20, 47), Vector2i(23, 58)], Tile.ROAD, 1)
	_paint_line([Vector2i(44, 25), Vector2i(55, 31), Vector2i(66, 45)], Tile.ROAD, 1)
	_paint_line([Vector2i(66, 45), Vector2i(74, 51), Vector2i(82, 60)], Tile.ROAD, 1)
	_paint_line([Vector2i(53, 25), Vector2i(65, 35), Vector2i(80, 37)], Tile.ROAD, 1)
	_paint_line([Vector2i(23, 58), Vector2i(40, 58), Vector2i(65, 45)], Tile.ROAD, 1)
	_paint_line([Vector2i(43, 25), Vector2i(57, 16), Vector2i(78, 14), Vector2i(94, 12)], Tile.ROAD, 1)
	_paint_line([Vector2i(37, 37), Vector2i(43, 37), Vector2i(50, 34)], Tile.ROAD, 1)
	_paint_line([Vector2i(66, 35), Vector2i(66, 45)], Tile.ROAD, 1)
	_paint_line([Vector2i(82, 60), Vector2i(88, 50)], Tile.ROAD, 1)
	_paint_line([Vector2i(20, 36), Vector2i(11, 47)], Tile.ROAD, 1)

func _paint_bridges() -> void:
	for pos in [Vector2i(30, 16), Vector2i(57, 15), Vector2i(53, 22), Vector2i(66, 42), Vector2i(75, 50), Vector2i(82, 59), Vector2i(20, 58)]:
		_set_tile(pos.x, pos.y, Tile.BRIDGE)
		_set_tile(pos.x + 1, pos.y, Tile.BRIDGE)

func _paint_city(rect: Rect2i, city_id: String) -> void:
	_fill_rect(rect, Tile.CITY)
	_paint_line([Vector2i(rect.position.x + 1, rect.position.y + rect.size.y / 2), Vector2i(rect.end.x - 2, rect.position.y + rect.size.y / 2)], Tile.ROAD, 1)
	_paint_line([Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + 1), Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 2)], Tile.ROAD, 1)
	var market_tile := Tile.SHOP
	match city_id:
		"linan":
			market_tile = Tile.MARSH
		"chengdu":
			market_tile = Tile.FIELD
	for block in [
		Rect2i(rect.position.x + 2, rect.position.y + 1, 3, 2),
		Rect2i(rect.position.x + rect.size.x - 5, rect.position.y + 1, 3, 2),
		Rect2i(rect.position.x + 2, rect.position.y + rect.size.y - 3, 3, 2),
		Rect2i(rect.position.x + rect.size.x - 5, rect.position.y + rect.size.y - 3, 3, 2),
	]:
		_fill_rect(block, Tile.BUILDING)
	_fill_rect(Rect2i(rect.position.x + rect.size.x / 2 - 1, rect.position.y + rect.size.y / 2 - 1, 3, 3), market_tile)
	if city_id == "luoyang":
		_fill_rect(Rect2i(rect.position.x + 12, rect.position.y + 2, 3, 3), Tile.TEMPLE)

func _paint_town(rect: Rect2i) -> void:
	_fill_rect(rect, Tile.TOWN)
	_paint_line([Vector2i(rect.position.x, rect.position.y + rect.size.y / 2), Vector2i(rect.end.x - 1, rect.position.y + rect.size.y / 2)], Tile.ROAD, 0)
	_fill_rect(Rect2i(rect.position.x + 1, rect.position.y + 1, 2, 2), Tile.BUILDING)
	_fill_rect(Rect2i(rect.end.x - 3, rect.position.y + 1, 2, 2), Tile.SHOP)

func _paint_village(rect: Rect2i) -> void:
	_fill_rect(rect, Tile.VILLAGE)
	_paint_line([Vector2i(rect.position.x, rect.position.y + rect.size.y / 2), Vector2i(rect.end.x - 1, rect.position.y + rect.size.y / 2)], Tile.ROAD, 0)
	_fill_rect(Rect2i(rect.position.x + 1, rect.position.y + 1, 2, 2), Tile.BUILDING)
	_fill_rect(Rect2i(rect.end.x - 3, rect.end.y - 3, 2, 2), Tile.FIELD)

func _paint_sect(rect: Rect2i, sect_id: String) -> void:
	var ground := Tile.SECT
	if sect_id == "xueshan":
		ground = Tile.SNOW
	elif sect_id == "flower":
		ground = Tile.FOREST
	elif sect_id == "xiaoyao":
		ground = Tile.MARSH
	_fill_rect(rect, ground)
	_paint_line([Vector2i(rect.position.x + rect.size.x / 2, rect.position.y), Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)], Tile.ROAD, 0)
	_paint_line([Vector2i(rect.position.x + 1, rect.position.y + rect.size.y / 2), Vector2i(rect.end.x - 2, rect.position.y + rect.size.y / 2)], Tile.ROAD, 0)
	_fill_rect(Rect2i(rect.position.x + rect.size.x / 2 - 1, rect.position.y + 1, 3, 2), Tile.TEMPLE)

func _paint_line(points: Array, tile_id: int, radius: int = 0, preserve_water_as_bridge: bool = false) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		var start := Vector2(points[index].x, points[index].y)
		var end := Vector2(points[index + 1].x, points[index + 1].y)
		var steps: int = int(max(abs(end.x - start.x), abs(end.y - start.y)) * 3.0) + 1
		for step in range(steps + 1):
			var t := float(step) / float(max(steps, 1))
			var point := start.lerp(end, t)
			for ox in range(-radius, radius + 1):
				for oy in range(-radius, radius + 1):
					var tx := roundi(point.x) + ox
					var ty := roundi(point.y) + oy
					if preserve_water_as_bridge and _get_tile(tx, ty) == Tile.WATER:
						_set_tile(tx, ty, Tile.WATER)
					elif tile_id == Tile.ROAD and _get_tile(tx, ty) == Tile.WATER:
						_set_tile(tx, ty, Tile.BRIDGE)
					else:
						_set_tile(tx, ty, tile_id)

func _fill_rect(rect: Rect2i, tile_id: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_set_tile(x, y, tile_id)

func _rough_fill_rect(rect: Rect2i, tile_id: int, edge_width: int = 2) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var edge_distance: int = min(min(x - rect.position.x, rect.end.x - 1 - x), min(y - rect.position.y, rect.end.y - 1 - y))
			if edge_distance < edge_width and _tile_seed(x, y) % 4 == 0:
				continue
			_set_tile(x, y, tile_id)

func _set_tile(x: int, y: int, tile_id: int) -> void:
	if x < 0 or y < 0 or x >= map_width or y >= map_height:
		return
	tiles[y][x] = tile_id

func _get_tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= map_width or y >= map_height:
		return Tile.GRASS
	return int(tiles[y][x])

func is_position_walkable(world_position: Vector2) -> bool:
	var tile := world_to_tile(world_position)
	return is_tile_walkable(tile)

func is_tile_walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_width or tile.y >= map_height:
		return false
	var tile_id: int = tiles[tile.y][tile.x]
	return tile_id != Tile.WATER and tile_id != Tile.BUILDING and tile_id != Tile.MOUNTAIN and tile_id != Tile.CLIFF

func spawn_npcs() -> void:
	world_npc_tiles.clear()
	for npc_data in GameData.get_npcs():
		if GameState.defeated_enemies.has(int(npc_data.get("id", -1))):
			continue
		if not _should_spawn_npc_on_world(npc_data):
			continue
		var actor = NPC_SCRIPT.new()
		add_child(actor)
		var world_data: Dictionary = npc_data.duplicate(true)
		var tile := _world_npc_tile(world_data, world_npc_tiles.size())
		world_data["pos_x"] = tile.x
		world_data["pos_y"] = tile.y
		world_data["map_actor_scale"] = WORLD_NPC_SCALE
		actor.setup(world_data, tile_size)
		npc_nodes.append(actor)

func _build_depth_props() -> void:
	_clear_depth_props()
	for y in range(map_height):
		for x in range(map_width):
			var tile_id: int = int(tiles[y][x])
			var seed := _tile_seed(x, y)
			var pos := Vector2((float(x) + 0.5) * tile_size, (float(y) + 0.92) * tile_size)
			match tile_id:
				Tile.FOREST:
					if seed % 9 == 0:
						_add_depth_prop("tree", pos, seed, 0, 0.74)
				Tile.BAMBOO:
					if seed % 7 == 0:
						_add_depth_prop("bamboo", pos, seed, 0, 0.76)
				Tile.MOUNTAIN, Tile.CLIFF:
					if _get_tile(x, y - 1) != tile_id and seed % 5 == 0:
						_add_depth_prop("ridge", pos, seed, 0, 0.82)
				Tile.SHOP:
					if _get_tile(x, y - 1) != tile_id and seed % 2 == 0:
						_add_depth_prop("shop_roof", pos, seed, 0, 0.62)
				Tile.TEMPLE:
					if _get_tile(x, y - 1) != tile_id:
						_add_depth_prop("temple_roof", pos, seed, 0, 0.78)
				Tile.SECT:
					if _get_tile(x, y - 1) != tile_id and seed % 3 == 0:
						_add_depth_prop("gate", pos, seed, 0, 0.72)
				Tile.CITY, Tile.TOWN, Tile.VILLAGE, Tile.BUILDING:
					if _get_tile(x, y - 1) != tile_id and seed % 3 == 0:
						_add_depth_prop("roof", pos, seed, 0, 0.58)
					elif seed % 31 == 0:
						_add_depth_prop("awning", pos + Vector2(0, 8), seed, 0, 0.60)

func _add_depth_prop(kind: String, world_position: Vector2, seed: int, z_offset: int = 0, scale_factor: float = 1.0) -> void:
	var prop = MAP_PROP_SCRIPT.new()
	add_child(prop)
	prop.setup(kind, world_position, tile_size, seed, z_offset, scale_factor)
	prop_nodes.append(prop)

func _clear_depth_props() -> void:
	for prop in prop_nodes:
		if is_instance_valid(prop):
			prop.queue_free()
	prop_nodes.clear()

func _should_spawn_npc_on_world(npc_data: Dictionary) -> bool:
	var npc_type := str(npc_data.get("npc_type", "normal"))
	if npc_type == "enemy":
		return true
	var tile := Vector2i(int(npc_data.get("pos_x", 0)), int(npc_data.get("pos_y", 0)))
	var region := GameData.get_region_at_tile(tile)
	var region_type := str(region.get("type", "wild"))
	if region_type == "sect":
		return npc_type == "master" or bool(npc_data.get("is_master", false))
	if region_type == "wild":
		return npc_type == "master"
	return false

func _world_npc_tile(npc_data: Dictionary, index: int) -> Vector2i:
	var source := Vector2i(int(npc_data.get("pos_x", 0)), int(npc_data.get("pos_y", 0)))
	var region := GameData.get_region_at_tile(source)
	var preferred := source
	if not region.is_empty():
		preferred = _find_walkable_tile_in_region(region, source)
	return _claim_world_npc_tile(preferred, region, int(npc_data.get("id", index)), index)

func _claim_world_npc_tile(preferred: Vector2i, region: Dictionary, npc_id: int, index: int) -> Vector2i:
	for min_spacing in [WORLD_NPC_MIN_SPACING, 3, 2, 1]:
		for radius in range(0, 12):
			var candidates := _ring_candidates(preferred, radius, npc_id + index * 17)
			for tile in candidates:
				if not region.is_empty() and not _region_contains_tile(region, tile):
					continue
				if is_tile_walkable(tile) and _is_world_npc_tile_clear(tile, min_spacing):
					world_npc_tiles.append(tile)
					return tile
	world_npc_tiles.append(preferred)
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
		var score_a: int = abs((a.x * 37 + a.y * 19 + seed) % 97)
		var score_b: int = abs((b.x * 37 + b.y * 19 + seed) % 97)
		return score_a < score_b
	)
	return candidates

func _is_world_npc_tile_clear(tile: Vector2i, min_spacing: int) -> bool:
	for used in world_npc_tiles:
		var dx := tile.x - used.x
		var dy := tile.y - used.y
		if dx * dx + dy * dy < min_spacing * min_spacing:
			return false
	return true

func reset_npcs() -> void:
	for actor in npc_nodes:
		if is_instance_valid(actor):
			actor.queue_free()
	npc_nodes.clear()
	spawn_npcs()

func unregister_npc(actor) -> void:
	npc_nodes.erase(actor)

func apply_defeated_enemies() -> void:
	for actor in npc_nodes.duplicate():
		if not is_instance_valid(actor):
			continue
		if GameState.defeated_enemies.has(int(actor.data.get("id", -1))):
			unregister_npc(actor)
			actor.queue_free()

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

func clear_highlights() -> void:
	for actor in npc_nodes:
		if is_instance_valid(actor):
			actor.set_highlight(false)

func focus_actor(actor) -> void:
	for npc in npc_nodes:
		if is_instance_valid(npc):
			npc.set_highlight(npc == actor)

func _build_landmark_labels() -> void:
	for label in landmark_labels:
		if is_instance_valid(label):
			label.queue_free()
	landmark_labels.clear()
	for landmark in LANDMARKS:
		var pos_data: Array = landmark.get("tile", [0, 0])
		var label := Label.new()
		label.text = str(landmark.get("name", ""))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = tile_to_world(Vector2i(int(pos_data[0]), int(pos_data[1]))) + Vector2(-92, -16)
		label.size = Vector2(184, 28)
		label.z_index = 3900
		label.add_theme_font_size_override("font_size", int(landmark.get("size", 16)))
		label.add_theme_color_override("font_color", _array_color(landmark.get("color", [0.88, 0.76, 0.50]), Color(0.88, 0.76, 0.50)))
		label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
		landmark_labels.append(label)

func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile_id: int = tiles[y][x]
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var texture := _tile_texture(tile_id, x, y)
			if texture != null:
				draw_texture_rect(texture, rect, false)
			else:
				draw_rect(rect, _tile_color(tile_id), true)
			_draw_tile_transition(rect, tile_id, x, y)
			_draw_tile_detail(rect, tile_id, x, y)
			_draw_2_5d_tile_overlay(rect, tile_id, x, y)
	_draw_world_decoration_layer()
	_draw_region_overlays()
	_draw_target_region_overlay()

func _tile_texture(tile_id: int, x: int, y: int) -> Texture2D:
	var variants: Array = tile_textures.get(tile_id, [])
	if variants.is_empty():
		return null
	var index := _tile_seed(x, y) % variants.size()
	return variants[index]

func _draw_tile_transition(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if tile_id == Tile.WATER:
		var shoreline := Color(0.86, 0.74, 0.48, 0.28)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, 0), Vector2(tile_size, 0), Vector2i(0, -1), shoreline, 2.0)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, tile_size), Vector2(tile_size, tile_size), Vector2i(0, 1), shoreline, 2.0)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, 0), Vector2(0, tile_size), Vector2i(-1, 0), shoreline, 2.0)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2i(1, 0), shoreline, 2.0)
	elif tile_id == Tile.ROAD:
		var road_edge := Color(0.30, 0.20, 0.10, 0.16)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, 0), Vector2(tile_size, 0), Vector2i(0, -1), road_edge, 1.2)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, tile_size), Vector2(tile_size, tile_size), Vector2i(0, 1), road_edge, 1.2)
	elif tile_id == Tile.SNOW or tile_id == Tile.DESERT or tile_id == Tile.BAMBOO or tile_id == Tile.FIELD or tile_id == Tile.MARSH:
		var soft_edge := Color(0.08, 0.06, 0.03, 0.10)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, 0), Vector2(tile_size, 0), Vector2i(0, -1), soft_edge, 1.2)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, tile_size), Vector2(tile_size, tile_size), Vector2i(0, 1), soft_edge, 1.2)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(0, 0), Vector2(0, tile_size), Vector2i(-1, 0), soft_edge, 1.2)
		_draw_edge_if_different(rect, x, y, tile_id, Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2i(1, 0), soft_edge, 1.2)

func _draw_edge_if_different(rect: Rect2, x: int, y: int, tile_id: int, start: Vector2, end: Vector2, offset: Vector2i, color: Color, width: float) -> void:
	var other := _get_tile(x + offset.x, y + offset.y)
	if other != tile_id and not (tile_id == Tile.WATER and other == Tile.BRIDGE):
		draw_line(rect.position + start, rect.position + end, color, width)

func _draw_2_5d_tile_overlay(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	if tile_id == Tile.BUILDING or tile_id == Tile.SHOP or tile_id == Tile.CITY or tile_id == Tile.TOWN or tile_id == Tile.VILLAGE or tile_id == Tile.TEMPLE or tile_id == Tile.SECT:
		var top_edge := _get_tile(x, y - 1) != tile_id
		var bottom_edge := _get_tile(x, y + 1) != tile_id
		var roof := Color(0.34, 0.14, 0.08, 0.36)
		var wall := Color(0.20, 0.11, 0.06, 0.24)
		if tile_id == Tile.SHOP:
			roof = Color(0.58, 0.26, 0.10, 0.38)
			wall = Color(0.50, 0.30, 0.16, 0.26)
		elif tile_id == Tile.SECT:
			roof = Color(0.55, 0.42, 0.18, 0.30)
			wall = Color(0.28, 0.24, 0.15, 0.22)
		draw_rect(Rect2(rect.position + Vector2(6, 10), rect.size - Vector2(8, 12)), Color(0.03, 0.02, 0.01, 0.08), true)
		if top_edge:
			draw_polygon(PackedVector2Array([
				rect.position + Vector2(2, 21),
				rect.position + Vector2(tile_size * 0.5, 5),
				rect.position + Vector2(tile_size - 2, 21),
				rect.position + Vector2(tile_size - 8, 27),
				rect.position + Vector2(8, 27)
			]), PackedColorArray([roof.darkened(0.16), roof.lightened(0.12), roof.darkened(0.10), roof, roof]))
		if bottom_edge:
			draw_rect(Rect2(rect.position + Vector2(7, 29), Vector2(tile_size - 14, 11)), wall, true)
	elif tile_id == Tile.MOUNTAIN or tile_id == Tile.CLIFF:
		if _get_tile(x, y - 1) != tile_id:
			draw_line(rect.position + Vector2(8, 38), rect.position + Vector2(24, 9), Color(0.70, 0.67, 0.55, 0.18), 2.0)
			draw_line(rect.position + Vector2(24, 9), rect.position + Vector2(42, 39), Color(0.08, 0.07, 0.06, 0.18), 2.0)

func _tile_color(tile_id: int) -> Color:
	match tile_id:
		Tile.ROAD:
			return Color(0.58, 0.50, 0.36)
		Tile.WATER:
			return Color(0.17, 0.34, 0.48)
		Tile.BUILDING:
			return Color(0.48, 0.31, 0.21)
		Tile.FOREST:
			return Color(0.17, 0.32, 0.18)
		Tile.COURTYARD:
			return Color(0.47, 0.43, 0.34)
		Tile.SECT:
			return Color(0.39, 0.43, 0.35)
		Tile.SNOW:
			return Color(0.72, 0.80, 0.86)
		Tile.BRIDGE:
			return Color(0.46, 0.31, 0.18)
		Tile.FIELD:
			return Color(0.42, 0.50, 0.25)
		Tile.MOUNTAIN:
			return Color(0.35, 0.37, 0.32)
		Tile.CITY:
			return Color(0.50, 0.45, 0.34)
		Tile.TOWN:
			return Color(0.47, 0.43, 0.32)
		Tile.VILLAGE:
			return Color(0.42, 0.48, 0.30)
		Tile.SHOP:
			return Color(0.56, 0.40, 0.28)
		Tile.TEMPLE:
			return Color(0.42, 0.36, 0.30)
		Tile.MARSH:
			return Color(0.22, 0.39, 0.34)
		Tile.DESERT:
			return Color(0.60, 0.50, 0.34)
		Tile.BAMBOO:
			return Color(0.25, 0.45, 0.25)
		Tile.CLIFF:
			return Color(0.40, 0.40, 0.37)
		_:
			return Color(0.32, 0.47, 0.27)

func _draw_tile_detail(rect: Rect2, tile_id: int, x: int, y: int) -> void:
	var seed := float((x * 31 + y * 17) % 19)
	match tile_id:
		Tile.GRASS:
			if (x * 7 + y * 11) % 4 == 0:
				draw_line(rect.position + Vector2(9 + seed, 30), rect.position + Vector2(12 + seed, 23), Color(0.54, 0.62, 0.35, 0.26), 1.2)
			if (x + y) % 6 == 0:
				draw_circle(rect.position + Vector2(30, 18 + seed * 0.3), 1.5, Color(0.48, 0.56, 0.30, 0.20))
		Tile.ROAD:
			draw_line(rect.position + Vector2(0, rect.size.y * 0.58), rect.position + Vector2(rect.size.x, rect.size.y * 0.43), Color(0.73, 0.65, 0.48, 0.34), 2.0)
			draw_line(rect.position + Vector2(0, rect.size.y * 0.30), rect.position + Vector2(rect.size.x, rect.size.y * 0.22), Color(0.33, 0.26, 0.17, 0.13), 1.0)
			draw_circle(rect.get_center() + Vector2(seed - 9.0, 8), 1.3, Color(0.30, 0.24, 0.16, 0.22))
		Tile.WATER:
			var offset := float((x * 13 + y * 7) % 17)
			draw_line(rect.position + Vector2(6, 18 + offset * 0.2), rect.position + Vector2(rect.size.x - 6, 14 + offset * 0.2), Color(0.62, 0.80, 0.90, 0.24), 2.0)
			draw_line(rect.position + Vector2(4, 32 - offset * 0.15), rect.position + Vector2(rect.size.x - 8, 28 - offset * 0.15), Color(0.09, 0.20, 0.28, 0.22), 1.3)
		Tile.BUILDING:
			draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size - Vector2(8, 10)), Color(0.33, 0.19, 0.12), false, 2.0)
			draw_line(rect.position + Vector2(4, 8), rect.position + Vector2(rect.size.x - 4, 8), Color(0.22, 0.12, 0.08, 0.55), 2.0)
		Tile.SHOP:
			draw_rect(Rect2(rect.position + Vector2(5, 8), rect.size - Vector2(10, 15)), Color(0.70, 0.48, 0.30, 0.55), true)
			draw_line(rect.position + Vector2(7, 13), rect.position + Vector2(rect.size.x - 7, 13), Color(0.86, 0.66, 0.34, 0.65), 2.0)
		Tile.TEMPLE:
			draw_polygon(PackedVector2Array([rect.position + Vector2(5, 15), rect.position + Vector2(24, 5), rect.position + Vector2(43, 15), rect.position + Vector2(38, 19), rect.position + Vector2(10, 19)]), PackedColorArray([Color(0.28, 0.18, 0.13), Color(0.70, 0.50, 0.27), Color(0.28, 0.18, 0.13), Color(0.36, 0.22, 0.14), Color(0.36, 0.22, 0.14)]))
			draw_rect(Rect2(rect.position + Vector2(13, 19), Vector2(22, 19)), Color(0.33, 0.25, 0.18), true)
		Tile.FOREST:
			draw_circle(rect.get_center() + Vector2(-7, 4), 9.0, Color(0.09, 0.22, 0.12, 0.65))
			draw_circle(rect.get_center() + Vector2(8, -3), 7.0, Color(0.13, 0.28, 0.15, 0.65))
			draw_line(rect.get_center() + Vector2(-2, 7), rect.get_center() + Vector2(-2, 15), Color(0.12, 0.08, 0.04, 0.38), 2.0)
		Tile.BAMBOO:
			for i in range(3):
				var bx := rect.position.x + 12 + i * 9
				draw_line(Vector2(bx, rect.position.y + 8), Vector2(bx - 2, rect.position.y + 38), Color(0.13, 0.28, 0.11, 0.78), 2.0)
				draw_line(Vector2(bx, rect.position.y + 18), Vector2(bx + 7, rect.position.y + 14), Color(0.34, 0.60, 0.28, 0.55), 1.5)
		Tile.MOUNTAIN, Tile.CLIFF:
			draw_polygon(PackedVector2Array([rect.position + Vector2(4, 39), rect.position + Vector2(22, 8), rect.position + Vector2(44, 39)]), PackedColorArray([Color(0.24, 0.24, 0.22, 0.72), Color(0.56, 0.55, 0.49, 0.75), Color(0.21, 0.21, 0.20, 0.72)]))
			draw_line(rect.position + Vector2(22, 8), rect.position + Vector2(28, 39), Color(0.12, 0.12, 0.11, 0.35), 1.5)
		Tile.SNOW:
			draw_line(rect.position + Vector2(10, 13), rect.position + Vector2(35, 34), Color(1, 1, 1, 0.20), 1.5)
			draw_circle(rect.position + Vector2(15 + seed, 24), 1.5, Color(1, 1, 1, 0.35))
		Tile.FIELD:
			for i in range(3):
				draw_line(rect.position + Vector2(3, 12 + i * 10), rect.position + Vector2(45, 7 + i * 10), Color(0.64, 0.68, 0.33, 0.35), 1.5)
		Tile.CITY, Tile.TOWN, Tile.VILLAGE:
			var roof := Color(0.35, 0.18, 0.12, 0.28)
			if tile_id == Tile.TOWN:
				roof = Color(0.30, 0.20, 0.13, 0.24)
			elif tile_id == Tile.VILLAGE:
				roof = Color(0.26, 0.22, 0.12, 0.20)
			draw_polygon(PackedVector2Array([
				rect.position + Vector2(9, 20),
				rect.position + Vector2(24, 11),
				rect.position + Vector2(39, 20),
				rect.position + Vector2(34, 24),
				rect.position + Vector2(14, 24)
			]), PackedColorArray([roof.darkened(0.1), roof.lightened(0.1), roof.darkened(0.1), roof, roof]))
			draw_rect(Rect2(rect.position + Vector2(14, 24), Vector2(20, 11)), Color(0.20, 0.14, 0.09, 0.16), true)
			if (x + y) % 3 == 0:
				draw_circle(rect.get_center(), 2.0, Color(0.72, 0.62, 0.42, 0.25))
		Tile.SECT:
			draw_arc(rect.get_center(), 13.0, 0, TAU, 24, Color(0.82, 0.68, 0.36, 0.23), 1.5)
		Tile.MARSH:
			draw_line(rect.position + Vector2(6, 20), rect.position + Vector2(42, 18), Color(0.42, 0.62, 0.56, 0.35), 2.0)
			draw_circle(rect.position + Vector2(16, 32), 3.0, Color(0.12, 0.25, 0.19, 0.45))
		Tile.DESERT:
			draw_line(rect.position + Vector2(2, 28), rect.position + Vector2(46, 22), Color(0.78, 0.66, 0.43, 0.38), 1.5)
			draw_line(rect.position + Vector2(10, 37), rect.position + Vector2(39, 33), Color(0.35, 0.27, 0.15, 0.18), 1.2)
		Tile.BRIDGE:
			for i in range(4):
				draw_line(rect.position + Vector2(8 + i * 8, 7), rect.position + Vector2(8 + i * 8, 41), Color(0.25, 0.14, 0.07, 0.55), 1.4)
			draw_line(rect.position + Vector2(5, 18), rect.position + Vector2(43, 18), Color(0.70, 0.48, 0.24, 0.55), 2.0)
			draw_line(rect.position + Vector2(5, 29), rect.position + Vector2(43, 29), Color(0.70, 0.48, 0.24, 0.55), 2.0)

func _draw_world_decoration_layer() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile_id: int = tiles[y][x]
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var seed := _tile_seed(x, y)
			match tile_id:
				Tile.FOREST:
					if seed % 7 == 0:
						_draw_tree_cluster(rect, seed)
				Tile.BAMBOO:
					if seed % 5 == 0:
						_draw_bamboo_cluster(rect, seed)
				Tile.WATER:
					if seed % 29 == 0:
						_draw_boat(rect, seed)
					elif seed % 11 == 0:
						_draw_water_plants(rect, seed)
				Tile.MARSH:
					if seed % 4 == 0:
						_draw_reeds(rect, seed)
				Tile.CITY, Tile.TOWN, Tile.VILLAGE:
					if seed % 6 == 0:
						_draw_street_life(rect, tile_id, seed)
				Tile.ROAD:
					if seed % 33 == 0:
						_draw_signpost(rect, seed)
				Tile.FIELD:
					if seed % 6 == 0:
						_draw_field_detail(rect, seed)
				Tile.MOUNTAIN, Tile.CLIFF:
					if seed % 5 == 0:
						_draw_rock_detail(rect, seed)
				Tile.DESERT:
					if seed % 7 == 0:
						_draw_desert_detail(rect, seed)
				Tile.SNOW:
					if seed % 6 == 0:
						_draw_snow_detail(rect, seed)
				Tile.SECT:
					if seed % 4 == 0:
						_draw_sect_detail(rect, seed)

func _tile_seed(x: int, y: int) -> int:
	return abs((x * 928371 + y * 689287 + x * y * 37) % 9973)

func _seed_offset(seed: int, range_px: float) -> Vector2:
	return Vector2(float((seed * 17) % 100) / 100.0 - 0.5, float((seed * 31) % 100) / 100.0 - 0.5) * range_px

func _draw_tree_cluster(rect: Rect2, seed: int) -> void:
	var base := rect.get_center() + _seed_offset(seed, 18.0)
	draw_line(base + Vector2(0, 7), base + Vector2(0, 18), Color(0.13, 0.08, 0.04, 0.58), 3.0)
	draw_circle(base + Vector2(-8, 1), 10.5, Color(0.05, 0.18, 0.09, 0.76))
	draw_circle(base + Vector2(6, -4), 11.5, Color(0.08, 0.26, 0.12, 0.78))
	draw_circle(base + Vector2(2, 7), 9.0, Color(0.10, 0.32, 0.16, 0.70))
	draw_line(base + Vector2(-12, 12), base + Vector2(13, 7), Color(0.44, 0.56, 0.30, 0.20), 1.4)

func _draw_bamboo_cluster(rect: Rect2, seed: int) -> void:
	var base := rect.position + Vector2(12 + seed % 9, 7)
	for i in range(4):
		var x := base.x + float(i * 8)
		var sway := float(((seed + i * 19) % 7) - 3)
		draw_line(Vector2(x, base.y), Vector2(x + sway, base.y + 39), Color(0.09, 0.24, 0.08, 0.78), 2.3)
		draw_line(Vector2(x + sway * 0.3, base.y + 15), Vector2(x + 8, base.y + 10), Color(0.38, 0.66, 0.28, 0.46), 1.8)
		draw_line(Vector2(x + sway * 0.2, base.y + 25), Vector2(x - 7, base.y + 21), Color(0.30, 0.56, 0.23, 0.42), 1.4)

func _draw_boat(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 12.0)
	draw_polygon(PackedVector2Array([
		center + Vector2(-15, 3),
		center + Vector2(13, -2),
		center + Vector2(17, 3),
		center + Vector2(3, 9),
		center + Vector2(-13, 8)
	]), PackedColorArray([
		Color(0.25, 0.13, 0.06, 0.68),
		Color(0.48, 0.30, 0.14, 0.72),
		Color(0.30, 0.16, 0.08, 0.70),
		Color(0.18, 0.10, 0.05, 0.72),
		Color(0.35, 0.20, 0.10, 0.70)
	]))
	draw_line(center + Vector2(-8, -1), center + Vector2(15, -8), Color(0.82, 0.74, 0.52, 0.38), 1.4)

func _draw_water_plants(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 20.0)
	for i in range(3):
		var pos := center + Vector2(float(i * 7 - 8), float((seed + i * 13) % 5))
		draw_circle(pos, 3.2, Color(0.24, 0.46, 0.28, 0.38))
		draw_line(pos + Vector2(-6, 5), pos + Vector2(6, 4), Color(0.66, 0.84, 0.78, 0.20), 1.1)

func _draw_reeds(rect: Rect2, seed: int) -> void:
	var base := rect.position + Vector2(7 + seed % 16, 33)
	for i in range(5):
		var x := base.x + float(i * 4)
		draw_line(Vector2(x, base.y + 4), Vector2(x + float((seed + i) % 5 - 2), base.y - 13 - float(i % 3)), Color(0.17, 0.30, 0.16, 0.60), 1.5)
		draw_circle(Vector2(x + 1, base.y - 12), 1.8, Color(0.64, 0.52, 0.30, 0.50))

func _draw_street_life(rect: Rect2, tile_id: int, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 14.0)
	var awning := Color(0.72, 0.35, 0.22, 0.34)
	if tile_id == Tile.CITY:
		awning = Color(0.84, 0.56, 0.25, 0.38)
	elif tile_id == Tile.VILLAGE:
		awning = Color(0.54, 0.44, 0.24, 0.30)
	draw_polygon(PackedVector2Array([
		center + Vector2(-14, -4),
		center + Vector2(10, -8),
		center + Vector2(15, -2),
		center + Vector2(-9, 3)
	]), PackedColorArray([awning.darkened(0.1), awning.lightened(0.1), awning, awning.darkened(0.05)]))
	draw_line(center + Vector2(-9, 3), center + Vector2(-9, 15), Color(0.20, 0.12, 0.06, 0.45), 1.5)
	draw_line(center + Vector2(12, 0), center + Vector2(12, 13), Color(0.20, 0.12, 0.06, 0.45), 1.5)
	if seed % 2 == 0:
		draw_circle(center + Vector2(18, 8), 2.2, Color(0.95, 0.70, 0.28, 0.55))

func _draw_signpost(rect: Rect2, seed: int) -> void:
	var base := rect.get_center() + _seed_offset(seed, 12.0)
	draw_line(base + Vector2(0, -12), base + Vector2(0, 14), Color(0.23, 0.13, 0.06, 0.62), 2.0)
	draw_polygon(PackedVector2Array([
		base + Vector2(0, -11),
		base + Vector2(17, -8),
		base + Vector2(12, -2),
		base + Vector2(0, -4)
	]), PackedColorArray([
		Color(0.64, 0.45, 0.22, 0.58),
		Color(0.78, 0.56, 0.28, 0.60),
		Color(0.56, 0.36, 0.18, 0.60),
		Color(0.48, 0.30, 0.16, 0.60)
	]))

func _draw_field_detail(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 18.0)
	draw_circle(center, 6.5, Color(0.74, 0.63, 0.27, 0.30))
	draw_line(center + Vector2(-7, 5), center + Vector2(7, -5), Color(0.86, 0.76, 0.34, 0.28), 2.0)
	if seed % 3 == 0:
		draw_line(center + Vector2(13, -7), center + Vector2(13, 12), Color(0.20, 0.12, 0.06, 0.55), 1.5)
		draw_line(center + Vector2(5, -2), center + Vector2(21, -2), Color(0.66, 0.47, 0.22, 0.42), 1.4)

func _draw_rock_detail(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 18.0)
	draw_polygon(PackedVector2Array([
		center + Vector2(-11, 8),
		center + Vector2(-4, -7),
		center + Vector2(10, -3),
		center + Vector2(14, 8)
	]), PackedColorArray([
		Color(0.18, 0.18, 0.16, 0.46),
		Color(0.55, 0.54, 0.48, 0.44),
		Color(0.28, 0.28, 0.26, 0.50),
		Color(0.13, 0.13, 0.12, 0.42)
	]))

func _draw_desert_detail(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 22.0)
	draw_arc(center, 18.0, deg_to_rad(200.0), deg_to_rad(340.0), 22, Color(0.86, 0.70, 0.42, 0.34), 2.0)
	if seed % 4 == 0:
		draw_line(center + Vector2(8, 9), center + Vector2(13, -8), Color(0.25, 0.16, 0.08, 0.42), 1.3)
		draw_line(center + Vector2(12, -1), center + Vector2(22, -6), Color(0.25, 0.16, 0.08, 0.34), 1.1)

func _draw_snow_detail(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 18.0)
	draw_circle(center, 6.5, Color(1.0, 1.0, 1.0, 0.28))
	draw_circle(center + Vector2(7, 3), 3.5, Color(0.70, 0.82, 0.92, 0.20))
	draw_line(center + Vector2(-9, -2), center + Vector2(9, 2), Color(1.0, 1.0, 1.0, 0.18), 1.2)

func _draw_sect_detail(rect: Rect2, seed: int) -> void:
	var center := rect.get_center() + _seed_offset(seed, 10.0)
	draw_line(center + Vector2(-8, -12), center + Vector2(-8, 13), Color(0.20, 0.12, 0.06, 0.52), 1.6)
	draw_line(center + Vector2(8, -12), center + Vector2(8, 13), Color(0.20, 0.12, 0.06, 0.52), 1.6)
	draw_polygon(PackedVector2Array([
		center + Vector2(-8, -12),
		center + Vector2(8, -12),
		center + Vector2(8, -2),
		center + Vector2(-8, -2)
	]), PackedColorArray([
		Color(0.78, 0.56, 0.24, 0.35),
		Color(0.88, 0.66, 0.32, 0.40),
		Color(0.62, 0.42, 0.18, 0.35),
		Color(0.52, 0.34, 0.14, 0.32)
	]))

func _draw_region_overlays() -> void:
	for region in GameData.get_regions():
		var region_type := str(region.get("type", "wild"))
		if region_type != "city" and region_type != "town" and region_type != "sect":
			continue
		var data: Array = region.get("rect", [])
		if data.size() < 4:
			continue
		var rect := Rect2(float(data[0]) * tile_size, float(data[1]) * tile_size, float(data[2]) * tile_size, float(data[3]) * tile_size)
		var color := Color(0.82, 0.68, 0.36, 0.28)
		if region_type == "sect":
			color = Color(0.72, 0.84, 0.52, 0.28)
		elif region_type == "town":
			color = Color(0.72, 0.60, 0.40, 0.20)
		draw_rect(rect.grow(-3.0), color, false, 2.0)
		if region_type == "city":
			draw_rect(rect.grow(-6.0), Color(0.15, 0.10, 0.06, 0.20), false, 1.2)

func _draw_target_region_overlay() -> void:
	if target_region_id.is_empty():
		return
	var region := GameData.get_region(target_region_id)
	if region.is_empty():
		return
	var rect_data: Array = region.get("rect", [])
	if rect_data.size() < 4:
		return
	var rect := Rect2(float(rect_data[0]) * tile_size, float(rect_data[1]) * tile_size, float(rect_data[2]) * tile_size, float(rect_data[3]) * tile_size)
	var center := rect.get_center()
	draw_rect(rect.grow(5.0), Color(1.0, 0.78, 0.28, 0.95), false, 4.0)
	draw_rect(rect.grow(9.0), Color(1.0, 0.92, 0.56, 0.32), false, 1.5)
	draw_arc(center, 19.0, 0.0, TAU, 32, Color(1.0, 0.86, 0.42, 0.92), 2.5)
	draw_line(center + Vector2(-25, 0), center + Vector2(25, 0), Color(1.0, 0.92, 0.56, 0.70), 2.0)
	draw_line(center + Vector2(0, -25), center + Vector2(0, 25), Color(1.0, 0.92, 0.56, 0.70), 2.0)

func _find_walkable_tile_in_region(region: Dictionary, preferred: Vector2i) -> Vector2i:
	if _region_contains_tile(region, preferred) and is_tile_walkable(preferred):
		return preferred
	var rect := _region_rect(region)
	var max_radius: int = max(rect.size.x, rect.size.y) + 4
	for radius in range(1, max_radius + 1):
		for y in range(preferred.y - radius, preferred.y + radius + 1):
			for x in range(preferred.x - radius, preferred.x + radius + 1):
				if abs(x - preferred.x) != radius and abs(y - preferred.y) != radius:
					continue
				var tile := Vector2i(x, y)
				if _region_contains_tile(region, tile) and is_tile_walkable(tile):
					return tile
	return preferred

func _region_center_tile(region: Dictionary) -> Vector2i:
	var center_data: Array = region.get("center", [])
	if center_data.size() >= 2:
		return Vector2i(int(center_data[0]), int(center_data[1]))
	var rect := _region_rect(region)
	return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

func _region_rect(region: Dictionary) -> Rect2i:
	var rect_data: Array = region.get("rect", [])
	if rect_data.size() < 4:
		return Rect2i(0, 0, map_width, map_height)
	return Rect2i(int(rect_data[0]), int(rect_data[1]), int(rect_data[2]), int(rect_data[3]))

func _region_contains_tile(region: Dictionary, tile: Vector2i) -> bool:
	var rect := _region_rect(region)
	return tile.x >= rect.position.x and tile.y >= rect.position.y and tile.x < rect.end.x and tile.y < rect.end.y

func _array_color(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_ARRAY and value.size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]) if value.size() >= 4 else 1.0)
	return fallback
