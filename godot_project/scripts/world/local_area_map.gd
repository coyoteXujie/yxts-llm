extends Node2D
class_name LocalAreaMap

const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const MAP_PROP_SCRIPT := preload("res://scripts/world/map_prop.gd")

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
var occupied_npc_tiles: Array[Vector2i] = []

func _ready() -> void:
	_load_tile_textures()

func _load_tile_textures() -> void:
	tile_textures.clear()
	for tile_id in TILE_TEXTURE_PATHS.keys():
		var path := str(TILE_TEXTURE_PATHS[tile_id])
		var texture := GameData.load_texture(path)
		if texture != null:
			tile_textures[int(tile_id)] = texture

func setup_region(region: Dictionary) -> void:
	if tile_textures.is_empty():
		_load_tile_textures()
	current_region = region.duplicate(true)
	current_mode = "region"
	active_shop_id = ""
	highlighted_portal_id = ""
	occupied_npc_tiles.clear()
	_clear_npcs()
	_clear_depth_props()
	_clear_portal_labels()
	_configure_region_size()
	_generate_region_map()
	_build_depth_props()
	_spawn_region_npcs()
	_build_portal_labels()
	_update_title_label()
	queue_redraw()

func enter_shop(portal: Dictionary) -> void:
	if tile_textures.is_empty():
		_load_tile_textures()
	var shop_id := str(portal.get("shop_id", ""))
	if not SHOP_DEFINITIONS.has(shop_id):
		return
	active_shop_id = shop_id
	current_mode = "shop"
	var tile_data: Array = portal.get("tile", [map_width / 2, map_height / 2])
	shop_return_tile = Vector2i(int(tile_data[0]), int(tile_data[1]))
	highlighted_portal_id = ""
	occupied_npc_tiles.clear()
	_clear_npcs()
	_clear_depth_props()
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
		return tile_to_world(Vector2i(map_width / 2, map_height - 5))
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
		label.visible = label.name == highlighted_portal_id or current_mode == "shop" or str(label.name).begins_with("shop_") or str(label.name).begins_with("travel_")
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

func _generate_city_region() -> void:
	_reset_tiles(Tile.GRASS)
	var profile := _region_profile()
	_fill_rect(Rect2i(5, 5, map_width - 10, map_height - 10), Tile.ROAD)
	_fill_rect(Rect2i(8, 8, map_width - 16, map_height - 16), Tile.GRASS)
	_paint_line([Vector2i(8, map_height / 2), Vector2i(map_width - 9, map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(map_width / 2, 8), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(14, 14), Vector2i(map_width - 14, map_height - 14)], Tile.ROAD, 1)
	_fill_rect(Rect2i(11, 10, 14, 8), Tile.GARDEN)
	_fill_rect(Rect2i(map_width - 27, 10, 16, 9), Tile.GARDEN if bool(profile.get("garden_city", false)) else Tile.BUILDING)
	_fill_rect(Rect2i(12, map_height - 20, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 27, map_height - 20, 15, 8), Tile.BUILDING)
	_place_shops(_shop_plan_for_region())
	_apply_city_identity(profile)

func _generate_town_region() -> void:
	_reset_tiles(Tile.FIELD)
	_fill_rect(Rect2i(4, 5, map_width - 8, map_height - 10), Tile.GRASS)
	_paint_line([Vector2i(4, map_height / 2), Vector2i(map_width - 5, map_height / 2)], Tile.ROAD, 2)
	_paint_line([Vector2i(map_width / 2, 7), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 1)
	_fill_rect(Rect2i(7, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 19, 8, 12, 7), Tile.BUILDING)
	_fill_rect(Rect2i(8, map_height - 16, 14, 7), Tile.FIELD)
	_place_shops(_shop_plan_for_region())
	_apply_town_identity()

func _generate_sect_region() -> void:
	_reset_tiles(Tile.MOUNTAIN if str(current_region.get("terrain", "")).contains("snow") else Tile.GRASS)
	_fill_rect(Rect2i(7, 6, map_width - 14, map_height - 12), Tile.GARDEN)
	_paint_line([Vector2i(map_width / 2, 6), Vector2i(map_width / 2, map_height - 7)], Tile.ROAD, 2)
	_paint_line([Vector2i(12, map_height / 2), Vector2i(map_width - 13, map_height / 2)], Tile.ROAD, 1)
	_fill_rect(Rect2i(map_width / 2 - 7, 8, 14, 8), Tile.BUILDING)
	_fill_rect(Rect2i(12, map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_fill_rect(Rect2i(map_width - 24, map_height / 2 - 5, 12, 9), Tile.BUILDING)
	_place_shops(["medicine", "market"])

func _generate_wild_region() -> void:
	var terrain := str(current_region.get("terrain", "plain"))
	var base := Tile.GRASS
	if terrain.contains("mountain") or terrain.contains("peak") or terrain.contains("cliff") or terrain.contains("gorge") or terrain.contains("plateau"):
		base = Tile.MOUNTAIN
	elif _terrain_has_water(terrain):
		base = Tile.GRASS
	elif terrain.contains("desert"):
		base = Tile.FIELD
	_reset_tiles(base)
	_paint_line([Vector2i(5, map_height / 2), Vector2i(map_width / 2, map_height / 2 - 3), Vector2i(map_width - 6, map_height / 2 + 2)], Tile.ROAD, 1)
	if _terrain_has_water(terrain):
		_paint_line([Vector2i(0, 14), Vector2i(map_width / 2, 18), Vector2i(map_width, 13)], Tile.WATER, 2)
		_set_tile(map_width / 2, 17, Tile.BRIDGE)
		_set_tile(map_width / 2 + 1, 17, Tile.BRIDGE)
	if terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden"):
		_fill_rect(Rect2i(7, 8, 12, 8), Tile.GARDEN)
		_fill_rect(Rect2i(map_width - 22, map_height - 15, 12, 8), Tile.GARDEN)
	if terrain.contains("desert"):
		_fill_rect(Rect2i(8, 8, 10, 6), Tile.MOUNTAIN)
		_fill_rect(Rect2i(map_width - 20, map_height - 13, 10, 6), Tile.MOUNTAIN)
	_fill_rect(Rect2i(map_width / 2 - 4, map_height / 2 - 8, 8, 5), Tile.BUILDING)
	_add_portal("wild_rest", "驿亭", "look", Vector2i(map_width / 2, map_height / 2 - 2), "")

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
	return terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("canal") or terrain.contains("ford") or terrain.contains("tide") or terrain.contains("weir") or terrain.contains("marsh") or terrain.contains("spring")

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
	for y in range(map_height):
		for x in range(map_width):
			var tile_id: int = int(tiles[y][x])
			var seed := _tile_seed(x, y)
			var pos := Vector2((float(x) + 0.5) * tile_size, (float(y) + 0.92) * tile_size)
			match tile_id:
				Tile.GARDEN:
					if seed % 7 == 0:
						_add_depth_prop("bamboo", pos, seed, 0, 0.92)
					elif seed % 11 == 0:
						_add_depth_prop("tree", pos, seed, 0, 0.84)
				Tile.MOUNTAIN:
					if not _has_tile(x, y - 1, tile_id) and seed % 3 == 0:
						_add_depth_prop("ridge", pos, seed, 0, 0.95)
				Tile.SHOP:
					if not _has_tile(x, y - 1, tile_id):
						_add_depth_prop("shop_roof", pos, seed, 0, 0.90)
				Tile.BUILDING:
					if not _has_tile(x, y - 1, tile_id) and seed % 2 == 0:
						_add_depth_prop("roof", pos, seed, 0, 0.86)
				Tile.ROAD:
					if current_mode == "region" and seed % 43 == 0:
						_add_depth_prop("lantern", pos + Vector2(-12, 8), seed, 0, 0.72)
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
	prop.setup(kind, world_position, tile_size, seed, z_offset, scale_factor)
	prop_nodes.append(prop)

func _clear_depth_props() -> void:
	for prop in prop_nodes:
		if is_instance_valid(prop):
			prop.queue_free()
	prop_nodes.clear()

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
		if portal_type == "shop" or portal_type == "travel_region":
			var board := StyleBoxFlat.new()
			if portal_type == "travel_region":
				board.bg_color = Color(0.08, 0.16, 0.12, 0.74)
				board.border_color = Color(0.72, 0.84, 0.52, 0.58)
			else:
				board.bg_color = Color(0.24, 0.12, 0.06, 0.72)
				board.border_color = Color(0.86, 0.58, 0.25, 0.55)
			board.set_border_width_all(1)
			board.set_corner_radius_all(3)
			label.add_theme_stylebox_override("normal", board)
		label.visible = current_mode == "shop" or portal_type == "shop" or portal_type == "travel_region"
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
	for y in range(map_height):
		if y >= tiles.size() or (tiles[y] as Array).size() < map_width:
			return
		for x in range(map_width):
			var tile_id: int = tiles[y][x]
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var texture: Texture2D = tile_textures.get(tile_id, null)
			if texture != null:
				draw_texture_rect(texture, rect, false)
				var tint := _tile_tint(tile_id)
				if tint.a > 0.0:
					draw_rect(rect, tint, true)
			else:
				draw_rect(rect, _tile_color(tile_id), true)
			_draw_tile_transition(rect, tile_id, x, y)
			_draw_tile_detail(rect, tile_id, x, y)
	_draw_scene_overlay()
	_draw_portal_signs()
	_draw_portals()

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
		var sign_rect := Rect2(pos + Vector2(-34, -78), Vector2(68, 18))
		draw_rect(sign_rect, Color(0.20, 0.10, 0.05, 0.88), true)
		draw_rect(sign_rect.grow(-2), accent.darkened(0.32), true)
		draw_line(sign_rect.position + Vector2(7, 3), sign_rect.position + Vector2(7, 18), Color(0.92, 0.76, 0.44, 0.55), 1.4)
		draw_line(sign_rect.position + Vector2(61, 3), sign_rect.position + Vector2(61, 18), Color(0.92, 0.76, 0.44, 0.55), 1.4)

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
	draw_rect(Rect2(0, 0, size.x, tile_size * 2.0), Color(0.18, 0.10, 0.06, 0.48), true)
	draw_line(Vector2(tile_size, tile_size * 2.05), Vector2(size.x - tile_size, tile_size * 2.05), accent.darkened(0.25), 3.0)
	for x in range(3, map_width - 3, 5):
		var hanger := Vector2(x * tile_size + tile_size * 0.5, tile_size * 1.2)
		draw_line(hanger + Vector2(0, -10), hanger + Vector2(0, 8), Color(0.88, 0.70, 0.38, 0.45), 1.2)
		draw_circle(hanger + Vector2(0, 11), 4.0, accent.lightened(0.18))
	draw_rect(Rect2(Vector2(tile_size * 2, tile_size * 3), Vector2(size.x - tile_size * 4, tile_size * 0.34)), Color(0.86, 0.64, 0.34, 0.20), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.025, 0.015, 0.25), false, 3.0)

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
