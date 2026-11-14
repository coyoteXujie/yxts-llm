extends RefCounted
class_name MapGenSystem

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

var _map: LocalAreaMap

func _init(map: LocalAreaMap) -> void:
	_map = map

func configure_region_size() -> void:
	var region_type := str(_map.current_region.get("type", "wild"))
	match region_type:
		"city":
			_map.map_width = 80
			_map.map_height = 54
		"town":
			_map.map_width = 58
			_map.map_height = 40
		"sect":
			_map.map_width = 64
			_map.map_height = 44
		_:
			_map.map_width = 72
			_map.map_height = 48

func configure_shop_size() -> void:
	_map.map_width = 28
	_map.map_height = 18

func _reset_tiles(tile_id: int) -> void:
	_map.tiles.clear()
	for y in range(_map.map_height):
		var row: Array = []
		for _x in range(_map.map_width):
			row.append(tile_id)
		_map.tiles.append(row)

func generate_region_map() -> void:
	_map.portals.clear()
	var region_type := str(_map.current_region.get("type", "wild"))
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
	_add_hidden_clue_portals()
	_add_adventure_clue_portals()

func _generate_city_region() -> void:
	_reset_tiles(Tile.GRASS)
	var profile := _map._region_profile()
	_fill_rect(Rect2i(5, 5, _map.map_width - 10, _map.map_height - 10), Tile.ROAD)
	_fill_rect(Rect2i(8, 8, _map.map_width - 16, _map.map_height - 16), Tile.GRASS)
	_paint_line([Vector2i(8, _map.map_height / 2), Vector2i(_map.map_width - 9, _map.map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(_map.map_width / 2, 8), Vector2i(_map.map_width / 2, _map.map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(14, 14), Vector2i(_map.map_width - 14, _map.map_height - 14)], Tile.ROAD, 1)
	_paint_city_street_grid(profile)
	_fill_rect(Rect2i(11, 10, 14, 8), Tile.GARDEN)
	_fill_rect(Rect2i(_map.map_width - 27, 10, 16, 9), Tile.GARDEN if bool(profile.get("garden_city", false)) else Tile.BUILDING)
	_fill_rect(Rect2i(12, _map.map_height - 20, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(_map.map_width - 27, _map.map_height - 20, 15, 8), Tile.BUILDING)
	_place_shops(_map._shop_plan_for_region())
	_apply_city_identity(profile)

func _paint_city_street_grid(profile: Dictionary) -> void:
	for y in range(14, _map.map_height - 12, 9):
		var offset := 1 if int(y / 9) % 2 == 0 else -2
		_paint_line([Vector2i(10, y), Vector2i(_map.map_width / 2 - 7, y + offset), Vector2i(_map.map_width - 11, y)], Tile.ROAD, 1)
	for x in range(17, _map.map_width - 13, 13):
		var offset := 2 if int(x / 13) % 2 == 0 else -1
		_paint_line([Vector2i(x, 9), Vector2i(x + offset, _map.map_height / 2 - 4), Vector2i(x, _map.map_height - 9)], Tile.ROAD, 1)
	var district_tiles := [Tile.BUILDING, Tile.SHOP, Tile.GARDEN if bool(profile.get("garden_city", false)) else Tile.BUILDING]
	for index in range(6):
		var x := 11 + (index % 3) * 21
		var y := 11 + int(index / 3) * (_map.map_height - 25)
		var tile_id: int = district_tiles[index % district_tiles.size()]
		_fill_rect(Rect2i(clampi(x, 10, _map.map_width - 18), clampi(y, 10, _map.map_height - 15), 9 + index % 2 * 3, 5), tile_id)
		_fill_rect(Rect2i(clampi(x + 2, 11, _map.map_width - 16), clampi(y + 5, 12, _map.map_height - 10), 4, 2), Tile.ROAD)

func _generate_town_region() -> void:
	var terrain := str(_map.current_region.get("terrain", ""))
	var region_id := str(_map.current_region.get("id", ""))
	_reset_tiles(Tile.FIELD)
	_fill_rect(Rect2i(4, 5, _map.map_width - 8, _map.map_height - 10), Tile.GRASS)
	_paint_line([Vector2i(4, _map.map_height / 2), Vector2i(_map.map_width - 5, _map.map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(_map.map_width / 2, 7), Vector2i(_map.map_width / 2, _map.map_height - 7)], Tile.ROAD, 1)
	_paint_line([Vector2i(8, _map.map_height - 9), Vector2i(_map.map_width / 2 - 8, _map.map_height / 2 + 3), Vector2i(_map.map_width - 8, 10)], Tile.ROAD, 1)
	_fill_rect(Rect2i(_map.map_width / 2 - 5, _map.map_height / 2 - 3, 10, 6), Tile.ROAD)
	_fill_rect(Rect2i(7, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(_map.map_width - 19, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(8, _map.map_height - 16, 14, 7), Tile.FIELD)
	_paint_town_hamlet_details(region_id, terrain)
	_place_shops(_map._shop_plan_for_region())
	_apply_town_identity()

func _paint_town_hamlet_details(region_id: String, terrain: String) -> void:
	var configured := GameData.get_region_layout_features(region_id)
	if not configured.is_empty():
		_apply_region_layout_features(configured)
		return
	for index in range(4):
		var x := 8 + (index % 2) * (_map.map_width - 24)
		var y := 8 + int(index / 2) * (_map.map_height - 22)
		_fill_rect(Rect2i(x, y, 7, 4), Tile.BUILDING)
		_fill_rect(Rect2i(x + 2, y + 4, 3, 2), Tile.ROAD)
	if region_id == "qinghe" or terrain.contains("starter"):
		_fill_rect(Rect2i(9, _map.map_height / 2 + 6, 8, 5), Tile.GARDEN)
		_fill_rect(Rect2i(_map.map_width - 18, _map.map_height / 2 + 5, 10, 6), Tile.FIELD)
		_paint_line([Vector2i(10, _map.map_height / 2 + 8), Vector2i(_map.map_width / 2 - 8, _map.map_height / 2 + 5)], Tile.ROAD, 1)
	elif terrain.contains("bath") or terrain.contains("spring"):
		_fill_rect(Rect2i(_map.map_width - 18, _map.map_height / 2 + 4, 10, 5), Tile.WATER)
		_fill_rect(Rect2i(_map.map_width - 15, _map.map_height / 2 + 5, 4, 2), Tile.BRIDGE)
	else:
		_fill_rect(Rect2i(_map.map_width / 2 + 9, _map.map_height - 13, 12, 6), Tile.FIELD)
		_fill_rect(Rect2i(8, _map.map_height - 13, 9, 5), Tile.GARDEN)

const TILE_NAME_TO_ID := {
	"grass": Tile.GRASS,
	"road": Tile.ROAD,
	"water": Tile.WATER,
	"building": Tile.BUILDING,
	"shop": Tile.SHOP,
	"wall": Tile.WALL,
	"garden": Tile.GARDEN,
	"field": Tile.FIELD,
	"mountain": Tile.MOUNTAIN,
	"bridge": Tile.BRIDGE,
	"floor": Tile.FLOOR,
	"counter": Tile.COUNTER,
	"carpet": Tile.CARPET
}

func _apply_region_layout_features(features: Array) -> void:
	for feature in features:
		if typeof(feature) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = feature
		var op := str(entry.get("op", ""))
		var tile_name := str(entry.get("tile", "road"))
		var tile_id: int = TILE_NAME_TO_ID.get(tile_name, Tile.ROAD)
		match op:
			"fill":
				var rect_data: Array = entry.get("rect", [])
				if rect_data.size() >= 4:
					_fill_rect(Rect2i(int(rect_data[0]), int(rect_data[1]), int(rect_data[2]), int(rect_data[3])), tile_id)
			"line":
				var points_data: Array = entry.get("points", [])
				if points_data.size() >= 2:
					var points: Array = []
					for point in points_data:
						if typeof(point) == TYPE_ARRAY and point.size() >= 2:
							points.append(Vector2i(int(point[0]), int(point[1])))
					if points.size() >= 2:
						_paint_line(points, tile_id, int(entry.get("width", 0)))
			"set":
				var pos_data: Array = entry.get("pos", [])
				if pos_data.size() >= 2:
					_set_tile(int(pos_data[0]), int(pos_data[1]), tile_id)
			"bridge_patch":
				var center_data: Array = entry.get("center", [])
				if center_data.size() >= 2:
					_set_bridge_patch(Vector2i(int(center_data[0]), int(center_data[1])))

func _generate_sect_region() -> void:
	_reset_tiles(Tile.GRASS)
	_fill_rect(Rect2i(7, 6, _map.map_width - 14, _map.map_height - 12), Tile.GARDEN)
	_paint_line([Vector2i(_map.map_width / 2, 6), Vector2i(_map.map_width / 2, _map.map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(12, _map.map_height / 2), Vector2i(_map.map_width - 13, _map.map_height / 2)], Tile.ROAD, 1)
	_fill_rect(Rect2i(_map.map_width / 2 - 7, 8, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(12, _map.map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_fill_rect(Rect2i(_map.map_width - 24, _map.map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_apply_sect_identity()
	_place_shops(_map._shop_plan_for_region())

func _apply_sect_identity() -> void:
	var region_id := str(_map.current_region.get("id", ""))
	var terrain := str(_map.current_region.get("terrain", ""))
	var configured := GameData.get_region_layout_features(region_id)
	if not configured.is_empty():
		_apply_region_layout_features(configured)
		return
	_fill_rect(Rect2i(_map.map_width / 2 - 9, _map.map_height / 2 + 5, 18, 7), Tile.ROAD)
	if region_id == "flower_sect" or terrain.contains("flower"):
		_fill_rect(Rect2i(9, 8, 12, 9), Tile.GARDEN)
		_fill_rect(Rect2i(_map.map_width - 22, _map.map_height - 17, 12, 8), Tile.GARDEN)
		_paint_line([Vector2i(_map.map_width - 11, 12), Vector2i(_map.map_width / 2 + 8, _map.map_height / 2 - 3)], Tile.ROAD, 1)
	elif region_id == "xueshan_sect" or terrain.contains("snow"):
		_fill_rect(Rect2i(8, 7, 14, 8), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width - 22, 8, 13, 8), Tile.MOUNTAIN)
		_paint_line([Vector2i(9, _map.map_height - 10), Vector2i(_map.map_width / 2 - 6, _map.map_height / 2 + 8)], Tile.ROAD, 1)
	elif region_id == "xiaoyao_sect" or terrain.contains("lake"):
		_paint_line([Vector2i(10, _map.map_height - 12), Vector2i(_map.map_width / 2, _map.map_height - 16), Vector2i(_map.map_width - 10, _map.map_height - 11)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(_map.map_width / 2, _map.map_height - 15))
	elif region_id == "honglian_sect":
		_fill_rect(Rect2i(_map.map_width / 2 - 17, _map.map_height / 2 - 10, 8, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width / 2 + 9, _map.map_height / 2 - 10, 8, 6), Tile.MOUNTAIN)
	elif region_id == "naja_sect":
		_paint_line([Vector2i(8, 11), Vector2i(_map.map_width / 2 - 7, _map.map_height / 2 - 2), Vector2i(_map.map_width - 9, 13)], Tile.ROAD, 1)
		_fill_rect(Rect2i(9, _map.map_height - 15, 11, 7), Tile.MOUNTAIN)
	elif region_id == "taiji_sect" or terrain.contains("daoist"):
		_fill_rect(Rect2i(_map.map_width / 2 - 12, _map.map_height / 2 - 12, 24, 5), Tile.ROAD)
		_fill_rect(Rect2i(_map.map_width / 2 - 12, _map.map_height / 2 + 12, 24, 4), Tile.GARDEN)
	else:
		_fill_rect(Rect2i(10, _map.map_height - 14, 12, 7), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width - 22, _map.map_height - 14, 12, 7), Tile.GARDEN)

func _generate_wild_region() -> void:
	var terrain := str(_map.current_region.get("terrain", "plain"))
	var base := Tile.GRASS
	if _map._terrain_has_water(terrain):
		base = Tile.GRASS
	elif terrain.contains("desert"):
		base = Tile.FIELD
	elif terrain.contains("plateau"):
		base = Tile.FIELD
	_reset_tiles(base)
	_paint_line([Vector2i(5, _map.map_height / 2), Vector2i(_map.map_width / 2, _map.map_height / 2 - 3), Vector2i(_map.map_width - 6, _map.map_height / 2 + 2)], Tile.ROAD, 1)
	_apply_wild_identity(terrain)
	_fill_rect(Rect2i(_map.map_width / 2 - 4, _map.map_height / 2 - 8, 8, 5), Tile.BUILDING)
	_add_portal("wild_rest", "驿亭", "look", Vector2i(_map.map_width / 2, _map.map_height / 2 - 2), "")

func _apply_wild_identity(terrain: String) -> void:
	var region_id := str(_map.current_region.get("id", ""))
	var configured := GameData.get_region_layout_features(region_id)
	if not configured.is_empty():
		_apply_region_layout_features(configured)
		return
	if _map._terrain_has_water(terrain):
		_paint_line([Vector2i(0, 14), Vector2i(_map.map_width / 3, 18), Vector2i(_map.map_width / 2, 16), Vector2i(_map.map_width, 13)], Tile.WATER, 2)
		_paint_line([Vector2i(_map.map_width / 2 + 9, 0), Vector2i(_map.map_width / 2 + 6, 18), Vector2i(_map.map_width / 2 + 12, _map.map_height - 5)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(_map.map_width / 2, 17))
		_set_bridge_patch(Vector2i(_map.map_width / 2 + 9, _map.map_height / 2 + 1))
		if terrain.contains("marsh"):
			_fill_rect(Rect2i(9, _map.map_height - 15, 14, 8), Tile.GARDEN)
			_fill_rect(Rect2i(_map.map_width - 22, 8, 13, 8), Tile.GARDEN)
	elif _map._terrain_has_forest(terrain):
		_fill_rect(Rect2i(7, 8, 14, 9), Tile.GARDEN)
		_fill_rect(Rect2i(_map.map_width - 24, _map.map_height - 16, 14, 9), Tile.GARDEN)
		_fill_rect(Rect2i(_map.map_width / 2 + 9, 8, 12, 8), Tile.GARDEN)
		_paint_line([Vector2i(10, 12), Vector2i(_map.map_width / 2, _map.map_height / 2 - 4), Vector2i(_map.map_width - 15, _map.map_height - 12)], Tile.ROAD, 1)
	elif terrain.contains("desert"):
		_fill_rect(Rect2i(8, 8, 10, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width - 20, _map.map_height - 13, 10, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width / 2 + 12, 10, 12, 5), Tile.FIELD)
		_paint_line([Vector2i(8, _map.map_height - 10), Vector2i(_map.map_width / 2 - 8, _map.map_height / 2 + 6)], Tile.ROAD, 1)
	elif _map._terrain_has_mountain(terrain):
		_fill_rect(Rect2i(6, 6, 14, 8), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width - 22, 7, 14, 9), Tile.MOUNTAIN)
		_fill_rect(Rect2i(10, _map.map_height - 14, 12, 7), Tile.MOUNTAIN)
		_paint_line([Vector2i(_map.map_width / 2 - 15, 9), Vector2i(_map.map_width / 2 + 8, _map.map_height / 2 - 6), Vector2i(_map.map_width - 11, _map.map_height - 10)], Tile.ROAD, 1)
	else:
		_fill_rect(Rect2i(8, 8, 13, 7), Tile.FIELD)
		_fill_rect(Rect2i(_map.map_width - 23, 9, 14, 7), Tile.FIELD)
		_fill_rect(Rect2i(10, _map.map_height - 15, 12, 7), Tile.GARDEN)
		_paint_line([Vector2i(9, 12), Vector2i(_map.map_width / 2 - 9, _map.map_height / 2 + 5)], Tile.ROAD, 1)

func _apply_city_identity(profile: Dictionary) -> void:
	var region_id := str(_map.current_region.get("id", ""))
	var configured := GameData.get_region_layout_features(region_id)
	if not configured.is_empty():
		_apply_region_layout_features(configured)
		return
	if bool(profile.get("water_city", false)):
		_paint_line([Vector2i(9, 20), Vector2i(26, 22), Vector2i(52, 20), Vector2i(_map.map_width - 9, 23)], Tile.WATER, 1)
		_paint_line([Vector2i(24, 8), Vector2i(25, 27), Vector2i(22, _map.map_height - 9)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(_map.map_width / 2, 21))
		_set_bridge_patch(Vector2i(24, _map.map_height / 2))
	elif region_id == "jiangling":
		_paint_line([Vector2i(4, 34), Vector2i(24, 32), Vector2i(48, 34), Vector2i(_map.map_width - 4, 31)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(_map.map_width / 2, 33))
		_set_bridge_patch(Vector2i(_map.map_width - 17, 32))
	elif region_id == "chengdu":
		_fill_rect(Rect2i(9, 9, 14, 10), Tile.GARDEN)
		_fill_rect(Rect2i(_map.map_width - 25, _map.map_height - 21, 13, 9), Tile.FIELD)
		_fill_rect(Rect2i(_map.map_width / 2 - 18, 9, 12, 7), Tile.GARDEN)
	elif region_id == "changan":
		_fill_rect(Rect2i(_map.map_width / 2 - 4, 9, 8, 10), Tile.BUILDING)
		_paint_line([Vector2i(_map.map_width / 2, 10), Vector2i(_map.map_width / 2, _map.map_height - 7)], Tile.ROAD, 3)
	elif region_id == "luoyang":
		_fill_rect(Rect2i(_map.map_width / 2 - 9, _map.map_height / 2 - 6, 18, 12), Tile.ROAD)
		_fill_rect(Rect2i(_map.map_width / 2 - 13, _map.map_height / 2 - 10, 6, 5), Tile.SHOP)
		_fill_rect(Rect2i(_map.map_width / 2 + 7, _map.map_height / 2 + 5, 6, 5), Tile.SHOP)

func _apply_town_identity() -> void:
	var region_id := str(_map.current_region.get("id", ""))
	var configured := GameData.get_region_layout_features(region_id)
	if not configured.is_empty():
		return
	var terrain := str(_map.current_region.get("terrain", ""))
	if _map._terrain_has_water(terrain):
		_paint_line([Vector2i(5, _map.map_height / 2 - 7), Vector2i(_map.map_width / 2, _map.map_height / 2 - 5), Vector2i(_map.map_width - 5, _map.map_height / 2 - 8)], Tile.WATER, 1)
		_set_bridge_patch(Vector2i(_map.map_width / 2, _map.map_height / 2 - 6))
	elif terrain.contains("garden") or terrain.contains("field") or terrain.contains("plain"):
		_fill_rect(Rect2i(7, _map.map_height - 15, 14, 8), Tile.FIELD)
		_fill_rect(Rect2i(_map.map_width - 21, _map.map_height - 15, 13, 8), Tile.GARDEN)
	elif terrain.contains("mound") or terrain.contains("mountain") or terrain.contains("gorge"):
		_fill_rect(Rect2i(6, 6, 11, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(_map.map_width - 17, _map.map_height - 13, 10, 6), Tile.MOUNTAIN)

func _set_bridge_patch(center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 2, center.x + 3):
			_set_tile(x, y, Tile.BRIDGE)

func _place_shops(shop_ids: Array) -> void:
	var positions := [
		Vector2i(14, 15),
		Vector2i(_map.map_width - 15, 15),
		Vector2i(14, _map.map_height - 15),
		Vector2i(_map.map_width - 15, _map.map_height - 15),
		Vector2i(_map.map_width / 2 - 9, 12),
		Vector2i(_map.map_width / 2 + 10, _map.map_height - 13)
	]
	for index in range(min(shop_ids.size(), positions.size())):
		_add_shop(str(shop_ids[index]), positions[index])

func _add_shop(shop_id: String, door_tile: Vector2i) -> void:
	if not _map.SHOP_DEFINITIONS.has(shop_id):
		return
	_fill_rect(Rect2i(door_tile.x - 4, door_tile.y - 5, 8, 5), Tile.SHOP)
	_fill_rect(Rect2i(door_tile.x - 2, door_tile.y - 1, 4, 2), Tile.ROAD)
	var shop: Dictionary = _map.SHOP_DEFINITIONS[shop_id]
	_add_portal(
		"shop_%s_%d_%d" % [shop_id, door_tile.x, door_tile.y],
		"进入%s" % str(shop.get("name", "商铺")),
		"shop",
		door_tile,
		shop_id,
		"",
		"",
		{
			"action_label": "进入",
			"interaction_hint": "商铺",
			"shop_name": str(shop.get("name", "商铺"))
		}
	)

func _add_exit_portal() -> void:
	_paint_line([Vector2i(_map.map_width / 2, _map.map_height - 8), Vector2i(_map.map_width / 2, _map.map_height - 2)], Tile.ROAD, 2)
	_add_portal("exit_world", "返回世界", "exit_world", Vector2i(_map.map_width / 2, _map.map_height - 4), "")

func _add_landmark_portals() -> void:
	var landmarks := _landmarks_for_region()
	for index in range(landmarks.size()):
		var landmark: Dictionary = landmarks[index]
		var tile: Vector2i = landmark.get("tile", _landmark_tile(index))
		tile = _map._find_nearest_walkable_tile(tile)
		_paint_landmark_site(tile, str(landmark.get("kind", "notice")))
		var portal := {
			"id": "landmark_%s_%d" % [str(_map.current_region.get("id", "region")), index],
			"label": str(landmark.get("label", "地标")),
			"type": "landmark",
			"tile": [tile.x, tile.y],
			"shop_id": "",
			"action_label": "探索",
			"interaction_hint": _landmark_kind_label(str(landmark.get("kind", "notice"))),
			"description": str(landmark.get("description", "")),
			"reward_item": str(landmark.get("reward_item", "")),
			"reward_money": int(landmark.get("reward_money", 0)),
			"reward_exp": int(landmark.get("reward_exp", 0)),
			"landmark_kind": str(landmark.get("kind", "notice"))
		}
		_map.portals.append(portal)

func _add_resource_portals() -> void:
	var resources := _resources_for_region()
	for index in range(resources.size()):
		var resource: Dictionary = resources[index]
		var tile: Vector2i = resource.get("tile", _resource_tile(index))
		tile = _map._find_nearest_walkable_tile(tile)
		_paint_resource_site(tile, str(resource.get("kind", "cache")))
		_map.portals.append({
			"id": "resource_%s_%d" % [str(_map.current_region.get("id", "region")), index],
			"label": str(resource.get("label", "资源点")),
			"type": "resource",
			"tile": [tile.x, tile.y],
			"shop_id": "",
			"action_label": "采集",
			"interaction_hint": _resource_kind_label(str(resource.get("kind", "cache"))),
			"description": str(resource.get("description", "这里有一点可用的物资。")),
			"depleted_description": str(resource.get("depleted_description", "这里今日已经搜寻过，明日再来或许会有新的收获。")),
			"reward_item": str(resource.get("reward_item", "")),
			"reward_count": int(resource.get("reward_count", 1)),
			"reward_money": int(resource.get("reward_money", 0)),
			"reward_exp": int(resource.get("reward_exp", 0)),
			"resource_kind": str(resource.get("kind", "cache"))
		})

func _add_hidden_clue_portals() -> void:
	var region_id := str(_map.current_region.get("id", ""))
	if region_id.is_empty():
		return
	if GameState.get_region_exploration(region_id) < GameState.FAST_TRAVEL_EXPERT_EXPLORATION:
		return
	var clue := _hidden_clue_for_region()
	var configured := _configured_region_points("hidden_clues")
	if not configured.is_empty():
		clue = configured[0]
	var tile: Vector2i = clue.get("tile", _hidden_clue_tile())
	tile = _map._find_nearest_walkable_tile(tile)
	var kind := str(clue.get("kind", "secret"))
	_paint_landmark_site(tile, kind)
	_map.portals.append({
		"id": "hidden_clue_%s" % region_id,
		"label": str(clue.get("label", "隐秘线索")),
		"type": "hidden_clue",
		"tile": [tile.x, tile.y],
		"shop_id": "",
		"action_label": "追查",
		"interaction_hint": _landmark_kind_label(kind),
		"description": str(clue.get("description", "你发现了一条被人刻意藏住的线索。")),
		"clue_hook": str(clue.get("clue_hook", "")),
		"reward_item": str(clue.get("reward_item", "")),
		"reward_money": int(clue.get("reward_money", 0)),
		"reward_exp": int(clue.get("reward_exp", 0)),
		"landmark_kind": kind
	})

func _add_adventure_clue_portals() -> void:
	var region_id := str(_map.current_region.get("id", ""))
	if region_id.is_empty():
		return
	var clues := GameState.get_unresolved_adventure_clues_for_region(region_id, 2)
	for index in range(clues.size()):
		var clue: Dictionary = clues[index]
		var clue_id := str(clue.get("id", ""))
		if clue_id.is_empty():
			continue
		var tile := _adventure_clue_tile(index)
		tile = _map._find_nearest_walkable_tile(tile)
		_paint_landmark_site(tile, "adventure")
		var title := str(clue.get("title", "奇遇线索"))
		var source_region := str(clue.get("region_name", ""))
		var source_text := "，旧线索从%s一路牵来" % source_region if not source_region.is_empty() else ""
		var description := "你在%s追到%s%s。痕迹没有散，反而指向了更深的人事。" % [
			str(_map.current_region.get("name", region_id)),
			title,
			source_text
		]
		var clue_source := str(clue.get("source", ""))
		var is_market_clue := clue_source == "market"
		if is_market_clue:
			description = _market_clue_portal_description(clue, region_id)
		var portal_label := _adventure_clue_label(title)
		var action_label := "追踪"
		var interaction_hint := "奇遇"
		var reward_money := 12
		var reward_exp := 16
		var landmark_kind := "adventure"
		var market_item_id := _market_clue_item_id(clue)
		var delivery_count := 0
		if is_market_clue:
			delivery_count = _market_delivery_count(clue)
			portal_label = _market_clue_label(title)
			action_label = "交货" if not market_item_id.is_empty() and delivery_count > 0 and int(GameState.inventory.get(market_item_id, 0)) >= delivery_count else "询价"
			interaction_hint = "行情"
			reward_money = _market_clue_reward_money(clue)
			reward_exp = 8
			landmark_kind = "market"
		_map.portals.append({
			"id": "adventure_clue_%s" % clue_id,
			"label": portal_label,
			"type": "adventure_clue",
			"tile": [tile.x, tile.y],
			"shop_id": "",
			"action_label": action_label,
			"interaction_hint": interaction_hint,
			"description": description,
			"clue_id": clue_id,
			"clue_source": clue_source,
			"market_item_id": market_item_id,
			"delivery_item_id": market_item_id,
			"delivery_count": delivery_count,
			"delivery_bonus_money": _market_delivery_bonus_money(clue) if is_market_clue else 0,
			"source_region_id": str(clue.get("region_id", "")),
			"source_region_name": source_region,
			"target_region_id": region_id,
			"reward_money": reward_money,
			"reward_exp": reward_exp,
			"landmark_kind": landmark_kind
		})

func _hidden_clue_for_region() -> Dictionary:
	var region_type := str(_map.current_region.get("type", "wild"))
	var terrain := str(_map.current_region.get("terrain", ""))
	var region_name := str(_map.current_region.get("name", "此地"))
	var tile := _hidden_clue_tile()
	match region_type:
		"city":
			return {
				"label": "暗巷旧印",
				"description": "%s背街墙角有一枚旧印，像是许多年前暗桩留下的联络记号。" % region_name,
				"clue_hook": "旧印指向城中旧衙档案与夜市黑账，后续可扩展为暗巷接头或黑市追踪。",
				"kind": "secret",
				"tile": tile + Vector2i(-8, 2),
				"reward_exp": 12,
				"reward_money": 8
			}
		"town":
			return {
				"label": "井底暗号",
				"description": "你从%s旧井边的苔痕里辨出暗号，线索指向一段被人刻意压下的旧事。" % region_name,
				"clue_hook": "井底暗号提到镇外旧路和失踪脚夫，后续可扩展为夜路奇遇或镇东余党线。",
				"kind": "secret",
				"tile": tile + Vector2i(-10, 5),
				"reward_item": "item_baozi",
				"reward_exp": 8
			}
		"sect":
			return {
				"label": "后山碑影",
				"description": "%s后山石碑背面有浅浅刀痕，似是门中前辈给后来人留下的提醒。" % region_name,
				"clue_hook": "碑影暗合门内旧招式与失传规矩，后续可扩展为门派试炼或旧人托付。",
				"kind": "secret",
				"tile": tile + Vector2i(7, -5),
				"reward_exp": 14
			}
	if _map._terrain_has_water(terrain):
		return {
			"label": "水边暗桩",
			"description": "%s水岸木桩下压着一枚旧铜钱，背面刻着难以公开的会面时辰。" % region_name,
			"clue_hook": "暗桩约定在夜潮回落后重查渡口，后续可扩展为水路接头或船帮伏线。",
			"kind": "secret",
			"tile": tile + Vector2i(8, -5),
			"reward_money": 12,
			"reward_exp": 8
		}
	if _map._terrain_has_mountain(terrain):
		return {
			"label": "崖壁刻痕",
			"description": "%s崖壁上有被风雨磨浅的剑痕，走势像一条通往隐路的标记。" % region_name,
			"clue_hook": "刻痕指向半山废道和旧日剑客，后续可扩展为山中秘径或崖上挑战。",
			"kind": "secret",
			"tile": tile + Vector2i(10, -6),
			"reward_exp": 12
		}
	if _map._terrain_has_forest(terrain):
		return {
			"label": "林中暗记",
			"description": "%s树皮上连着三处极轻的刀刻，只有熟路人才看得出它们在指向何处。" % region_name,
			"clue_hook": "暗记绕向林深处的药坡和临时营火，后续可扩展为采药奇遇或林中救援。",
			"kind": "secret",
			"tile": tile + Vector2i(-7, -6),
			"reward_item": "item_red_flower",
			"reward_exp": 8
		}
	if terrain.contains("desert"):
		return {
			"label": "沙下残符",
			"description": "%s风沙下露出半截残符，符纸边缘仍有暗影司常用的灰蜡。" % region_name,
			"clue_hook": "残符提到风停后的古驿地窖，后续可扩展为荒漠遗迹或暗影司残点。",
			"kind": "secret",
			"tile": tile + Vector2i(9, 4),
			"reward_money": 10,
			"reward_exp": 10
		}
	return {
		"label": "路边暗记",
		"description": "%s路旁石缝里藏着一枚折起的短笺，像是在等真正走熟这片地方的人。" % region_name,
		"clue_hook": "短笺指向旧茶棚后的无名岔路，后续可扩展为路边奇遇或隐士相逢。",
		"kind": "secret",
		"tile": tile,
		"reward_exp": 8
	}

func _resources_for_region() -> Array:
	var configured := _configured_region_points("resources")
	if not configured.is_empty():
		return configured
	var region_type := str(_map.current_region.get("type", "wild"))
	var terrain := str(_map.current_region.get("terrain", ""))
	var resources: Array = []
	if region_type == "city":
		resources.append({"label": "街边食盒", "description": "街边摊贩收摊前分你一份热食。", "kind": "cache", "tile": Vector2i(_map.map_width / 2 - 18, _map.map_height / 2 + 8), "reward_item": "item_baozi"})
		resources.append({"label": "武馆药罐", "description": "武馆药罐里还有一点跌打药粉。", "kind": "herb", "tile": Vector2i(_map.map_width / 2 + 16, _map.map_height / 2 - 8), "reward_item": "item_yao"})
	elif region_type == "town":
		resources.append({"label": "田埂药草", "description": "田埂边长着几株常见药草，适合初行江湖的人练手采摘。", "kind": "herb", "tile": Vector2i(_map.map_width - 12, _map.map_height - 10), "reward_item": "item_red_flower"})
		resources.append({"label": "茶棚食盒", "description": "茶棚老板见你赶路，塞给你一个热包子。", "kind": "cache", "tile": Vector2i(12, _map.map_height / 2 + 7), "reward_item": "item_baozi"})
	elif region_type == "sect":
		resources.append({"label": "练功药罐", "description": "演武坪旁备着跌打药，弟子们用后会及时补上。", "kind": "herb", "tile": Vector2i(_map.map_width / 2 - 12, _map.map_height / 2 + 9), "reward_item": "item_yao"})
		resources.append({"label": "香案供钱", "description": "香案上有几枚散钱，知客让你拿去添置路粮。", "kind": "coin", "tile": Vector2i(_map.map_width / 2 + 12, 13), "reward_money": 3})
	else:
		resources.append({"label": "野草药坡", "description": "路边药坡长着几株常见药草。", "kind": "herb", "tile": Vector2i(12, 13), "reward_item": "item_red_flower"})
		resources.append({"label": "破棚食盒", "description": "破棚木桌下有个食盒，里面还有一个包子。", "kind": "cache", "tile": Vector2i(_map.map_width / 2 - 8, _map.map_height / 2 + 9), "reward_item": "item_baozi"})

	if _map._terrain_has_water(terrain):
		resources.append({"label": "河边鱼篓", "description": "河边鱼篓压在水草旁，里面还有一尾活鱼。", "kind": "fish", "tile": Vector2i(_map.map_width - 12, _map.map_height / 2 - 7), "reward_item": "item_fish"})
	elif _map._terrain_has_mountain(terrain):
		resources.append({"label": "山壁矿点", "description": "山壁露出一点矿脉，虽然不能锻成兵器，也能换些银两。", "kind": "ore", "tile": Vector2i(_map.map_width - 13, 12), "reward_money": 5})
	elif _map._terrain_has_forest(terrain):
		resources.append({"label": "林下药草", "description": "林下潮湿，药草长得比镇外更好。", "kind": "herb", "tile": Vector2i(13, 13), "reward_item": "item_red_flower"})
	elif terrain.contains("desert") or terrain.contains("plateau"):
		resources.append({"label": "沙下旧钱", "description": "黄沙里露出铜色边角，拨开后找到几枚旧钱。", "kind": "coin", "tile": Vector2i(_map.map_width - 16, _map.map_height - 12), "reward_money": 5})
	return resources

func _landmarks_for_region() -> Array:
	var configured := _configured_region_points("landmarks")
	if not configured.is_empty():
		return configured
	var region_type := str(_map.current_region.get("type", "wild"))
	var region_id := str(_map.current_region.get("id", ""))
	var terrain := str(_map.current_region.get("terrain", ""))
	match region_type:
		"city":
			return _city_landmarks(region_id)
		"town":
			return _town_landmarks(region_id, terrain)
		"sect":
			return _sect_landmarks(region_id)
		_:
			return _wild_landmarks(terrain)

func _configured_region_points(point_type: String) -> Array:
	var region_id := str(_map.current_region.get("id", ""))
	var points := GameData.get_region_points(region_id, point_type)
	var result: Array = []
	for point in points:
		var normalized: Dictionary = point.duplicate(true)
		var tile_value = normalized.get("tile", [])
		if typeof(tile_value) == TYPE_ARRAY:
			var tile_data: Array = tile_value
			if tile_data.size() >= 2:
				normalized["tile"] = Vector2i(int(tile_data[0]), int(tile_data[1]))
		result.append(normalized)
	return result

func _city_landmarks(region_id: String) -> Array:
	match region_id:
		"luoyang":
			return [
				{"label": "苏家旧宅", "description": "墙根还有焦黑旧痕，洛阳旧火的线索并没有被岁月完全抹去。", "kind": "ruin", "tile": Vector2i(_map.map_width / 2 - 15, _map.map_height / 2 + 7), "reward_exp": 8},
				{"label": "天街武馆", "description": "木人桩排在院中，来往侠少在这里试拳脚。", "kind": "training", "tile": Vector2i(_map.map_width / 2 + 16, _map.map_height / 2 - 8), "reward_exp": 6}
			]
		"changan":
			return [
				{"label": "朱雀榜亭", "description": "榜文半新半旧，暗影司与朝廷密令的传闻混在市井闲谈里。", "kind": "notice", "tile": Vector2i(_map.map_width / 2, 16), "reward_money": 4},
				{"label": "西市货栈", "description": "胡商、镖客和江湖客都在这里换消息。", "kind": "market", "tile": Vector2i(17, _map.map_height / 2 + 10), "reward_item": "item_wine"}
			]
		"linan":
			return [
				{"label": "画舫码头", "description": "水雾贴着河面，船娘唱词里夹着花间旧事。", "kind": "dock", "tile": Vector2i(24, _map.map_height / 2 + 6), "reward_item": "item_fish"},
				{"label": "烟雨廊桥", "description": "桥下水声不断，适合听风，也适合藏信。", "kind": "bridge", "tile": Vector2i(_map.map_width / 2 + 12, 20), "reward_exp": 6}
			]
		"chengdu":
			return [
				{"label": "药市竹园", "description": "药香混着竹叶清气，巴蜀商贩在这里分拣药草。", "kind": "herb", "tile": Vector2i(17, 18), "reward_item": "item_yao"},
				{"label": "都江渠眼", "description": "水脉分流，老工匠说这里藏着天府气运。", "kind": "water", "tile": Vector2i(_map.map_width - 20, _map.map_height / 2 + 8), "reward_exp": 7}
			]
		"jiangling":
			return [
				{"label": "江防码头", "description": "战船旧缆还系在岸边，荆楚水路的消息从这里上岸。", "kind": "dock", "tile": Vector2i(_map.map_width - 18, _map.map_height / 2 + 9), "reward_item": "item_fish"},
				{"label": "旧战鼓台", "description": "鼓面龟裂，仍能想见当年兵家重镇的声势。", "kind": "training", "tile": Vector2i(18, _map.map_height / 2 - 8), "reward_exp": 8}
			]
	return [
		{"label": "府衙告示", "description": "城中近来案牍渐多，江湖事也开始上了官府文书。", "kind": "notice", "tile": Vector2i(_map.map_width / 2, 15), "reward_money": 3},
		{"label": "城中武馆", "description": "武馆开门纳客，门口木牌写着切磋点到为止。", "kind": "training", "tile": Vector2i(_map.map_width - 18, _map.map_height / 2), "reward_exp": 5}
	]

func _town_landmarks(region_id: String, terrain: String) -> Array:
	var result: Array = [
		{"label": "镇口告示", "description": "告示上写着近路、盗匪和失物，许多小任务会从这里冒头。", "kind": "notice", "tile": Vector2i(_map.map_width / 2 - 9, 10), "reward_money": 2},
		{"label": "练武空场", "description": "空场地面被脚步磨亮，是镇上年轻人练拳脚的地方。", "kind": "training", "tile": Vector2i(_map.map_width / 2 + 13, _map.map_height / 2 + 7), "reward_exp": 4}
	]
	if region_id == "qinghe":
		result.append({"label": "老井茶棚", "description": "井水清冽，茶棚边常有赶路人歇脚。", "kind": "well", "tile": Vector2i(11, _map.map_height / 2 + 8), "reward_item": "item_baozi"})
	elif _map._terrain_has_water(terrain):
		result.append({"label": "渡口鱼篓", "description": "渡口边搁着鱼篓，船家不介意你拿一尾小鱼充饥。", "kind": "dock", "tile": Vector2i(_map.map_width - 11, _map.map_height / 2 - 6), "reward_item": "item_fish"})
	elif terrain.contains("mound") or terrain.contains("bath"):
		result.append({"label": "旧碑残台", "description": "风化的碑文只剩几行，隐约提到一条古道。", "kind": "ruin", "tile": Vector2i(10, 10), "reward_exp": 5})
	else:
		result.append({"label": "田边药草", "description": "田埂旁长着几株常见药草，采下可作外伤药引。", "kind": "herb", "tile": Vector2i(_map.map_width - 12, _map.map_height - 11), "reward_item": "item_red_flower"})
	return result

func _sect_landmarks(region_id: String) -> Array:
	var sect_name := str(_map.current_region.get("name", region_id))
	return [
		{"label": "演武坪", "description": "%s弟子在此晨练，步伐与呼吸自成章法。" % sect_name, "kind": "training", "tile": Vector2i(_map.map_width / 2, _map.map_height / 2 + 8), "reward_exp": 8},
		{"label": "祖师碑", "description": "碑前香灰未冷，门派戒律和前人名号刻得很深。", "kind": "shrine", "tile": Vector2i(_map.map_width / 2, 12), "reward_exp": 6}
	]

func _wild_landmarks(terrain: String) -> Array:
	if _map._terrain_has_water(terrain):
		return [
			{"label": "浅滩鱼影", "description": "水草摇动，能看见几尾鱼贴着浅滩游过。", "kind": "water", "tile": Vector2i(_map.map_width / 2 + 10, 17), "reward_item": "item_fish"},
			{"label": "河岸旧桩", "description": "旧木桩上有刀痕，像是有人在此等过船。", "kind": "dock", "tile": Vector2i(_map.map_width / 2 - 12, 20), "reward_exp": 5}
		]
	if terrain.contains("mountain") or terrain.contains("peak") or terrain.contains("cliff") or terrain.contains("gorge") or terrain.contains("plateau"):
		return [
			{"label": "山壁石洞", "description": "洞口冷风外涌，石缝里藏着前人留下的伤药。", "kind": "cave", "tile": Vector2i(_map.map_width - 15, 13), "reward_item": "item_yao"},
			{"label": "观云石台", "description": "站在石台上能远望山势，胸中郁气也散了些。", "kind": "ruin", "tile": Vector2i(15, _map.map_height / 2 - 8), "reward_exp": 7}
		]
	if terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden"):
		return [
			{"label": "林下药坡", "description": "潮湿树影下生着药草，采摘时要避开毒虫。", "kind": "herb", "tile": Vector2i(13, 13), "reward_item": "item_red_flower"},
			{"label": "竹影小径", "description": "竹影斜落，风一吹像有许多人低声说话。", "kind": "shrine", "tile": Vector2i(_map.map_width - 18, _map.map_height - 13), "reward_exp": 6}
		]
	if terrain.contains("desert"):
		return [
			{"label": "古驿残碑", "description": "风沙掩住半截碑座，碑后压着几枚旧钱。", "kind": "ruin", "tile": Vector2i(16, 13), "reward_money": 8},
			{"label": "枯井营火", "description": "有人在枯井边宿过夜，灰烬尚有余温。", "kind": "well", "tile": Vector2i(_map.map_width - 17, _map.map_height - 13), "reward_item": "item_baozi"}
		]
	return [
		{"label": "野外茶棚", "description": "破旧茶棚还能遮风，木桌上刻着过路人的名字。", "kind": "well", "tile": Vector2i(_map.map_width / 2 - 8, _map.map_height / 2 + 8), "reward_item": "item_baozi"},
		{"label": "路边石龛", "description": "石龛里压着一张褪色黄符，像是在镇路。", "kind": "shrine", "tile": Vector2i(_map.map_width / 2 + 14, _map.map_height / 2 - 9), "reward_exp": 5}
	]

func _landmark_tile(index: int) -> Vector2i:
	var anchors := [
		Vector2i(_map.map_width / 2 - 14, _map.map_height / 2 - 9),
		Vector2i(_map.map_width / 2 + 14, _map.map_height / 2 + 9),
		Vector2i(12, _map.map_height / 2 + 6),
		Vector2i(_map.map_width - 13, _map.map_height / 2 - 6)
	]
	return anchors[index % anchors.size()]

func _resource_tile(index: int) -> Vector2i:
	var anchors := [
		Vector2i(12, 12),
		Vector2i(_map.map_width - 13, _map.map_height - 11),
		Vector2i(_map.map_width / 2 + 15, 13),
		Vector2i(_map.map_width / 2 - 14, _map.map_height - 12)
	]
	return anchors[index % anchors.size()]

func _hidden_clue_tile() -> Vector2i:
	return Vector2i(_map.map_width / 2 + 18, _map.map_height / 2 - 9)

func _adventure_clue_tile(index: int) -> Vector2i:
	var anchors := [
		Vector2i(_map.map_width / 2 - 20, _map.map_height / 2 - 8),
		Vector2i(_map.map_width / 2 + 20, _map.map_height / 2 + 6)
	]
	return anchors[index % anchors.size()]

func _adventure_clue_label(title: String) -> String:
	title = title.strip_edges()
	if title.is_empty():
		return "奇遇踪迹"
	title = title.replace("追查", "").strip_edges()
	if title.length() > 8:
		title = "%s..." % title.substr(0, 8)
	return title

func _market_clue_label(title: String) -> String:
	title = title.strip_edges()
	if title.is_empty():
		return "货价问询"
	title = title.replace("货价风声", "").strip_edges()
	if title.is_empty():
		return "货价问询"
	if title.length() > 6:
		return "%s..." % title.substr(0, 6)
	return title

func _market_clue_portal_description(clue: Dictionary, region_id: String) -> String:
	var target_region := GameData.get_region(region_id)
	var target_name := str(target_region.get("name", region_id))
	var source_name := str(clue.get("region_name", "来路"))
	var item_id := _market_clue_item_id(clue)
	var item := GameData.get_item(item_id)
	var item_name := str(item.get("name", item_id if not item_id.is_empty() else "这批货"))
	return "你在%s的货栈和掌柜对了价，%s传来的%s行情终于落到实处。若以后接入跑商委托，这里可以作为交割点。" % [
		target_name,
		source_name,
		item_name
	]

func _market_clue_reward_money(clue: Dictionary) -> int:
	var item_id := _market_clue_item_id(clue)
	var item := GameData.get_item(item_id)
	var base_price := int(item.get("price", 18))
	return clampi(int(roundf(float(base_price) * 0.75)), 8, 36)

func _market_delivery_bonus_money(clue: Dictionary) -> int:
	var item_id := _market_clue_item_id(clue)
	if item_id.is_empty():
		return 0
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	var base_price := int(item.get("price", 18))
	return clampi(int(roundf(float(base_price) * 0.72 * float(_market_delivery_count(clue)))), 10, 90)

func _market_delivery_count(clue: Dictionary) -> int:
	var item_id := _market_clue_item_id(clue)
	if item_id.is_empty():
		return 0
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	var base_price := int(item.get("price", 18))
	if base_price <= 10:
		return 4
	if base_price <= 20:
		return 3
	if base_price <= 60:
		return 2
	return 1

func _market_clue_item_id(clue: Dictionary) -> String:
	var clue_id := str(clue.get("id", ""))
	var item_pos := clue_id.find("item_")
	if item_pos < 0:
		return ""
	return clue_id.substr(item_pos)

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
		"secret":
			_fill_rect(Rect2i(tile.x - 3, tile.y - 2, 6, 4), Tile.ROAD)
			_fill_rect(Rect2i(tile.x - 1, tile.y - 1, 3, 2), Tile.MOUNTAIN)
			_set_tile(tile.x, tile.y, Tile.ROAD)
		"adventure":
			_fill_rect(Rect2i(tile.x - 4, tile.y - 2, 8, 4), Tile.ROAD)
			_fill_rect(Rect2i(tile.x - 1, tile.y - 1, 3, 2), Tile.GARDEN)
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
	var region_id := str(_map.current_region.get("id", ""))
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
		var travel_meta := _travel_portal_metadata(target, direction)
		_add_portal(
			"travel_%s" % target_id,
			"前往%s" % str(target.get("name", target_id)),
			"travel_region",
			tile,
			"",
			target_id,
			_opposite_direction(direction),
			travel_meta
		)

func _travel_portal_limit() -> int:
	var region_type := str(_map.current_region.get("type", "wild"))
	if region_type == "city":
		return 5
	if region_type == "wild":
		return 3
	return 4

func _direction_to_region(target: Dictionary) -> String:
	var source_center := _region_center(_map.current_region)
	var target_center := _region_center(target)
	var delta := target_center - source_center
	if absf(delta.x) > absf(delta.y):
		return "east" if delta.x >= 0.0 else "west"
	return "south" if delta.y >= 0.0 else "north"

func _travel_portal_tile(direction: String, index: int) -> Vector2i:
	var offset := (index % 3 - 1) * 7
	match direction:
		"north":
			return Vector2i(clampi(_map.map_width / 2 + offset, 8, _map.map_width - 9), 6)
		"south":
			return Vector2i(clampi(_map.map_width / 2 + offset, 8, _map.map_width - 9), _map.map_height - 6)
		"east":
			return Vector2i(_map.map_width - 6, clampi(_map.map_height / 2 + offset, 8, _map.map_height - 9))
		"west":
			return Vector2i(6, clampi(_map.map_height / 2 + offset, 8, _map.map_height - 9))
	return Vector2i(_map.map_width / 2, _map.map_height - 6)

func _paint_travel_path(tile: Vector2i, direction: String) -> void:
	var inner := Vector2i(_map.map_width / 2, _map.map_height / 2)
	match direction:
		"north":
			inner = Vector2i(tile.x, min(tile.y + 8, _map.map_height / 2))
		"south":
			inner = Vector2i(tile.x, max(tile.y - 8, _map.map_height / 2))
		"east":
			inner = Vector2i(max(tile.x - 8, _map.map_width / 2), tile.y)
		"west":
			inner = Vector2i(min(tile.x + 8, _map.map_width / 2), tile.y)
	_paint_line([tile, inner, Vector2i(_map.map_width / 2, _map.map_height / 2)], Tile.ROAD, 1)
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

func _travel_portal_metadata(target: Dictionary, direction: String) -> Dictionary:
	var distance := _local_route_distance(_map.current_region, target)
	var risk_level := clampi(maxi(int(_map.current_region.get("danger", 1)), int(target.get("danger", 1))), 1, 5)
	var hours := roundf(clampf(distance / 7.5 + float(risk_level) * 0.42, 0.5, 8.0) * 2.0) / 2.0
	return {
		"action_label": "前往",
		"interaction_hint": "驿路",
		"direction": direction,
		"direction_label": _travel_direction_label(direction),
		"travel_distance": distance,
		"travel_hours": hours,
		"risk_level": risk_level,
		"risk_label": _local_route_risk_label(risk_level)
	}

func _local_route_distance(source: Dictionary, target: Dictionary) -> float:
	if source.is_empty() or target.is_empty():
		return 0.0
	return roundf(_region_center(source).distance_to(_region_center(target)) * 10.0) / 10.0

func _travel_direction_label(direction: String) -> String:
	match direction:
		"north":
			return "北"
		"south":
			return "南"
		"east":
			return "东"
		"west":
			return "西"
	return "路"

func _local_route_risk_label(risk_level: int) -> String:
	if risk_level >= 5:
		return "极险"
	if risk_level >= 4:
		return "险路"
	if risk_level >= 3:
		return "危险"
	if risk_level >= 2:
		return "谨慎"
	return "平稳"

func _landmark_kind_label(kind: String) -> String:
	match kind:
		"notice":
			return "告示"
		"well":
			return "井台"
		"market":
			return "市井"
		"training":
			return "演武"
		"shrine":
			return "碑龛"
		"dock":
			return "渡口"
		"water":
			return "水边"
		"bridge":
			return "桥头"
		"ruin":
			return "遗迹"
		"cave":
			return "山洞"
		"herb":
			return "药坡"
		"secret":
			return "隐线"
		"adventure":
			return "奇遇"
	return "地标"

func _resource_kind_label(kind: String) -> String:
	match kind:
		"herb", "flower":
			return "药草"
		"cache":
			return "食盒"
		"coin":
			return "散钱"
		"fish":
			return "鱼获"
		"ore":
			return "矿石"
	return "物资"

func _add_portal(id: String, label: String, kind: String, tile: Vector2i, shop_id: String, target_region_id: String = "", entry_kind: String = "", metadata: Dictionary = {}) -> void:
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
	for key in metadata.keys():
		portal[key] = metadata[key]
	_map.portals.append(portal)

func generate_shop_map(shop_id: String) -> void:
	_map.portals.clear()
	_reset_tiles(Tile.FLOOR)
	_fill_rect(Rect2i(0, 0, _map.map_width, 1), Tile.WALL)
	_fill_rect(Rect2i(0, _map.map_height - 1, _map.map_width, 1), Tile.WALL)
	_fill_rect(Rect2i(0, 0, 1, _map.map_height), Tile.WALL)
	_fill_rect(Rect2i(_map.map_width - 1, 0, 1, _map.map_height), Tile.WALL)
	_fill_rect(Rect2i(5, 4, _map.map_width - 10, 3), Tile.COUNTER)
	_fill_rect(Rect2i(4, 8, 5, 5), Tile.CARPET)
	_fill_rect(Rect2i(_map.map_width - 9, 8, 5, 5), Tile.CARPET)
	if shop_id == "blacksmith":
		_fill_rect(Rect2i(4, 4, 4, 4), Tile.WALL)
	elif shop_id == "medicine":
		_fill_rect(Rect2i(_map.map_width - 8, 4, 4, 4), Tile.GARDEN)
	elif shop_id == "inn":
		_fill_rect(Rect2i(4, 10, 6, 3), Tile.COUNTER)
		_fill_rect(Rect2i(_map.map_width - 10, 10, 6, 3), Tile.COUNTER)
	var shop: Dictionary = _map.SHOP_DEFINITIONS.get(shop_id, {})
	_add_portal("shop_service", "柜台服务", "shop_service", shop_service_tile(), shop_id, "", "", {
		"action_label": "交谈",
		"shop_name": str(shop.get("name", "商铺")),
		"interaction_hint": _shop_service_hint(shop_id)
	})
	_add_portal("exit_area", "出门", "exit_area", Vector2i(_map.map_width / 2, _map.map_height - 3), "")

func shop_service_tile() -> Vector2i:
	return Vector2i(_map.map_width / 2, 8)

func _shop_service_hint(shop_id: String) -> String:
	match shop_id:
		"inn":
			return "交易/住店"
		"blacksmith":
			return "交易/修理"
		"medicine":
			return "药品/疗伤"
		"tailor":
			return "衣装/护具"
		"teahouse":
			return "茶水/消息"
		"market":
			return "买卖/行情"
	return "交易"

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
	if x < 0 or y < 0 or x >= _map.map_width or y >= _map.map_height:
		return
	if tile_id == Tile.ROAD and _map.tiles[y][x] == Tile.WATER:
		_map.tiles[y][x] = Tile.BRIDGE
	else:
		_map.tiles[y][x] = tile_id

