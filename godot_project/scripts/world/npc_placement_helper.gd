extends RefCounted
class_name NpcPlacementHelper

## NPC 放置辅助工具：从 local_area_map.gd 中提取的 NPC 生成与定位逻辑

const LOCAL_NPC_SPACING_STEPS := [6, 5, 4, 3, 2, 1]
const LOCAL_NPC_ENTRY_CLEAR_RADIUS := 7

var map_width: int
var map_height: int
var tiles: Array
var current_region: Dictionary
var _occupied_npc_tiles: Array[Vector2i] = []

func _init(width: int, height: int, region_tiles: Array, region: Dictionary) -> void:
	map_width = width
	map_height = height
	tiles = region_tiles
	current_region = region
	_occupied_npc_tiles.clear()

func clear() -> void:
	_occupied_npc_tiles.clear()

## 计算 NPC 在局部地图中的出生瓦片位置
func get_npc_tile(npc_data: Dictionary, index: int) -> Vector2i:
	var role := str(npc_data.get("role", ""))
	var faction := str(npc_data.get("faction", ""))
	var fallback := Vector2i(map_width / 2 + index * 3, map_height - 4 - (index % 5))
	var preferred := _role_anchor(npc_data, index, fallback)
	return _claim_local_npc_tile(preferred, int(npc_data.get("id", index)), index)

## 获取 NPC 标记位置（用于小地图）
func get_npc_markers(npc_nodes: Array) -> Array:
	var markers: Array = []
	for actor in npc_nodes:
		if not is_instance_valid(actor):
			continue
		markers.append({
			"id": actor.data.get("id", 0),
			"name": actor.data.get("name", ""),
			"position": actor.position,
			"is_enemy": actor.is_enemy() if actor.has_method("is_enemy") else false,
			"is_important": _is_important_npc(actor.data),
			"is_quest_target": _is_quest_target(actor.data),
		})
	return markers

func _is_important_npc(npc_data: Dictionary) -> bool:
	var role := str(npc_data.get("role", ""))
	return role in ["掌门", "长老", "掌柜", "首领"]

func _is_quest_target(npc_data: Dictionary) -> bool:
	var npc_id := int(npc_data.get("id", -1))
	var npc_name := str(npc_data.get("name", ""))
	for quest_id in GameState.active_quests:
		var quest := GameData.get_quest(quest_id)
		if quest.is_empty():
			continue
		for obj in quest.get("objectives", []):
			if str(obj.get("type", "")) == "talk" and (str(obj.get("target", "")) == npc_name or int(obj.get("target_id", -1)) == npc_id):
				return true
	return false

## 按 NPC 角色分配锚点位置
func _role_anchor(npc_data: Dictionary, index: int, fallback: Vector2i) -> Vector2i:
	var role := str(npc_data.get("role", ""))
	var faction := str(npc_data.get("faction", ""))

	# 掌门 → 居中偏后
	if role in ["掌门", "长老"]:
		return _sect_anchor(index)

	# 掌柜 → 商铺入口附近
	if role == "掌柜" or npc_data.get("is_shop_keeper", false):
		return _merchant_anchor(index)

	# 敌人 → 边缘/外围
	if npc_data.get("is_enemy", false) or int(npc_data.get("attack", 0)) > 0:
		return _edge_anchor(index)

	# 任务 NPC → 显眼位置
	if role == "重要":
		return _story_anchor(index)

	# 服务类
	if role in ["衙役", "捕快", "守卫"]:
		return _civic_anchor(index)

	# 平民
	if role in ["路人", "农夫", "商贩", "行者", "书生", "医者", "工匠"]:
		return _civilian_anchor(index)

	# 安静角落
	if role in ["僧侣", "道士", "隐士", "乞丐"]:
		return _quiet_anchor(index)

	return fallback

func _merchant_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.36), int(map_height * 0.70))
	var offset := Vector2i((index % 3) * 7, (index / 3) * -3)
	return base + offset

func _quiet_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.54), int(map_height * 0.32))
	var offset := Vector2i((index % 4) * 3 - 6, (index / 4) * -2)
	return base + offset

func _edge_anchor(index: int) -> Vector2i:
	var side := index % 4
	var base: Vector2i
	match side:
		0: base = Vector2i(3, int(map_height * 0.35))
		1: base = Vector2i(map_width - 5, int(map_height * 0.40))
		2: base = Vector2i(int(map_width * 0.20), 3)
		_: base = Vector2i(int(map_width * 0.72), map_height - 5)
	var offset := Vector2i((index / 4) * 3, (index / 4) * 2)
	return base + offset

func _story_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.48), int(map_height * 0.52))
	var offset := Vector2i((index % 4) * 5 - 8, (index / 4) * -3)
	return base + offset

func _civic_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.26), int(map_height * 0.45))
	var offset := Vector2i((index % 3) * 8, (index / 3) * -2)
	return base + offset

func _civilian_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.50), int(map_height * 0.56))
	var offset := Vector2i((index % 6) * 5 - 12, (index / 6) * -2)
	return base + offset

func _sect_anchor(index: int) -> Vector2i:
	var base := Vector2i(int(map_width * 0.48), int(map_height * 0.22))
	var offset := Vector2i((index % 2) * 6 - 3, (index / 2) * -2)
	return base + offset

## 声明一个瓦片为 NPC 位置
func _claim_local_npc_tile(preferred: Vector2i, npc_id: int, index: int) -> Vector2i:
	for radius in LOCAL_NPC_SPACING_STEPS:
		var candidates := _ring_candidates(preferred, radius, npc_id + index)
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.distance_squared_to(preferred) < b.distance_squared_to(preferred))
		for tile_pos in candidates:
			if _is_local_npc_tile_clear(tile_pos, radius):
				var region_type := str(current_region.get("type", ""))
				if _is_near_entry_tile(tile_pos) and region_type != "shop":
					continue
				_occupied_npc_tiles.append(tile_pos)
				return tile_pos
	return preferred

func _ring_candidates(center: Vector2i, radius: int, seed: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var dst := maxi(abs(dx), abs(dy))
			if dst != radius and dst > 1:
				continue
			var tile_pos := center + Vector2i(dx, dy)
			if tile_pos.x < 1 or tile_pos.x >= map_width - 1 or tile_pos.y < 1 or tile_pos.y >= map_height - 1:
				continue
			if dst < radius and dst > 1:
				if ((dx + dy + seed) % 3) != 0:
					continue
			candidates.append(tile_pos)
	return candidates

func _is_local_npc_tile_clear(tile_pos: Vector2i, min_spacing: int) -> bool:
	for occupied in _occupied_npc_tiles:
		if occupied.distance_squared_to(tile_pos) < min_spacing * min_spacing:
			return false
	return _is_tile_walkable(tile_pos)

func _is_tile_walkable(tile_pos: Vector2i) -> bool:
	if tile_pos.x < 0 or tile_pos.y < 0 or tile_pos.x >= map_width or tile_pos.y >= map_height:
		return false
	var idx := tile_pos.y * map_width + tile_pos.x
	if idx < 0 or idx >= tiles.size():
		return false
	var tile_id := int(tiles[idx])
	return tile_id not in [2, 3, 8, 9]  # 水、建筑、山、墙壁不可走

func _is_near_entry_tile(tile_pos: Vector2i) -> bool:
	var cx := map_width / 2
	var cy := map_height - 3
	return abs(tile_pos.x - cx) < 4 and abs(tile_pos.y - cy) < 3