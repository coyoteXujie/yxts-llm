extends RefCounted
class_name WorldMapGenSystem

## 世界地图生成器：从 world_map.gd 中提取的地图生成逻辑

enum Tile {
	GRASS, ROAD, WATER, BUILDING, FOREST, COURTYARD,
	SECT, SNOW, BRIDGE, FIELD, MOUNTAIN, CITY, TOWN,
	VILLAGE, SHOP, TEMPLE, MARSH, DESERT, BAMBOO, CLIFF
}

var map_width: int
var map_height: int
var tiles: Array

func _init(width: int, height: int) -> void:
	map_width = width
	map_height = height
	tiles = []

func generate() -> Array:
	"""生成完整世界地图瓦片数据，返回 tiles 二维数组"""
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
	return tiles

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
			var pseed: int = _tile_seed(x, y)
			var ridge_band: bool = abs((y - rect.position.y) * 3 - (x - rect.position.x)) % 13 == 0
			var should_peak: bool = pseed % density == 0 or (ridge_band and pseed % 3 == 0)
			if should_peak:
				_set_tile(x, y, obstacle_tile)
				if pseed % 5 == 0:
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

	for town_rect in [
		Rect2i(26, 13, 9, 7), Rect2i(51, 18, 7, 5), Rect2i(57, 14, 7, 5),
		Rect2i(72, 10, 7, 5), Rect2i(6, 31, 6, 5), Rect2i(18, 26, 7, 5),
		Rect2i(30, 34, 7, 5), Rect2i(8, 45, 7, 5), Rect2i(70, 52, 6, 5),
		Rect2i(84, 54, 7, 5), Rect2i(79, 47, 7, 5), Rect2i(12, 51, 6, 5),
		Rect2i(34, 55, 7, 5), Rect2i(34, 63, 7, 5), Rect2i(78, 47, 7, 5),
		Rect2i(50, 42, 7, 5),
	]:
		_paint_town(town_rect)

	for village_rect in [
		Rect2i(38, 44, 8, 5), Rect2i(6, 25, 8, 5),
		Rect2i(50, 58, 7, 5), Rect2i(83, 29, 7, 5),
	]:
		_paint_village(village_rect)

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
	for idx in range(points.size() - 1):
		var start := Vector2(points[idx].x, points[idx].y)
		var end := Vector2(points[idx + 1].x, points[idx + 1].y)
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

func _tile_seed(x: int, y: int) -> int:
	return (x * 374761393 + y * 668265263) % 2147483647