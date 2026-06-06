extends Node

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const WORLD_MAP_PANEL_SCRIPT := preload("res://scripts/ui/world_map_panel.gd")

const WORLD_TILE_WATER := 2
const WORLD_TILE_BUILDING := 3
const WORLD_TILE_MOUNTAIN := 10
const LOCAL_TILE_WATER := 2
const LOCAL_TILE_MOUNTAIN := 8

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	_ensure_input_actions()
	GameState.new_game({
		"name": "自动测试",
		"gender": "male",
		"faction": "none"
	})

	var test_root := Node2D.new()
	add_child(test_root)

	var world_map = WORLD_MAP_SCRIPT.new()
	test_root.add_child(world_map)
	await get_tree().process_frame

	_check(world_map.npc_nodes.size() >= 12 and world_map.npc_nodes.size() <= 32, "世界层 NPC 数量应保持稀疏，当前=%d" % world_map.npc_nodes.size())
	_check(world_map.prop_nodes.size() > 20, "世界地图应生成 2.5D 遮挡节点")
	_check(_textured_prop_count(world_map.prop_nodes) > 20, "世界地图 2.5D 道具应加载 PNG 资源")
	_check(world_map.is_position_walkable(GameState.player_position), "玩家出生点应可通行")
	_check(not world_map.is_tile_walkable(_first_tile_with_id(world_map, WORLD_TILE_WATER)), "世界地图水面应不可通行")
	_check(not world_map.is_tile_walkable(_first_tile_with_id(world_map, WORLD_TILE_BUILDING)), "世界地图建筑应不可通行")
	_check(_tile_ratio(world_map, WORLD_TILE_MOUNTAIN) < 0.18, "世界地图不应被山峰瓦片铺满")
	_check(_texture_variant_count(world_map, WORLD_TILE_WATER) >= 4, "世界地图应加载多变体水面瓦片")
	_check(_actors_use_y_sort(world_map.npc_nodes), "世界层 NPC 应按脚底 Y 坐标排序")

	var player = PLAYER_SCRIPT.new()
	player.world_map = world_map
	player.position = GameState.player_position
	test_root.add_child(player)
	await get_tree().process_frame
	_check(player.z_index == int(player.position.y), "玩家应按脚底 Y 坐标排序")
	_check(PLAYER_SCRIPT.SPRITE_TARGET_HEIGHT >= 110.0, "玩家地图角色显示不应继续偏小")
	_check(PLAYER_SCRIPT.LOCAL_STAGE_PRESENCE_SCALE >= 1.15, "玩家局部横版舞台应叠加额外角色存在感缩放")
	_check(PLAYER_SCRIPT.PLAYER_CONTACT_GLOW_ALPHA > 0.08, "玩家脚下应保留接触光表现")
	_check(PLAYER_SCRIPT.STEP_DUST_RADIUS.x >= 8.0, "玩家移动应保留脚步尘表现参数")
	_check(PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MAX > PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MIN, "玩家应支持局部舞台深度缩放")
	_check(NPC_SCRIPT.BASE_SPRITE_HEIGHT >= 100.0, "NPC 地图贴图基础高度不应继续偏小")
	_check(NPC_SCRIPT.STAGE_PRESENCE_SCALE >= 1.15, "NPC 局部横版舞台应叠加额外角色存在感缩放")
	_check(NPC_SCRIPT.STAGE_SPRITE_MIN_SCALE >= 1.10, "NPC 局部横版舞台应保留最低视觉体量")
	_check(NPC_SCRIPT.CONTACT_GLOW_ALPHA > 0.08, "NPC 脚下应保留接触光表现")

	var local_area = LOCAL_AREA_SCRIPT.new()
	test_root.add_child(local_area)
	await get_tree().process_frame
	local_area.setup_region(GameData.get_region("qinghe"))
	await get_tree().process_frame

	_check(local_area.npc_nodes.size() >= 8, "平安镇局部地图应生成镇民 NPC，当前=%d" % local_area.npc_nodes.size())
	_check(local_area.scene_background_texture != null, "局部地图应加载区域水墨氛围背景")
	_check(local_area.side_view_stage_enabled and LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_LANE_ALPHA >= 0.40, "局部地图应启用横版舞台式视觉层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_AMBIENT_PARTICLES >= 24, "局部横版舞台应保留动态氛围粒子")
	_check(local_area.stage_foreground_overlay != null and local_area.stage_foreground_overlay.visible, "局部横版舞台应创建真实前景遮挡层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_FOREGROUND_OVERLAY_Z >= 3000, "局部横版舞台前景遮挡层应绘制在角色前方")
	_check(local_area.is_side_view_stage_active(), "局部地图应能向角色暴露横版舞台状态")
	var previous_stage_phase: float = local_area.stage_visual_phase
	var previous_overlay_phase: float = float(local_area.stage_foreground_overlay.get("visual_phase"))
	local_area._process(1.0)
	_check(local_area.stage_visual_phase > previous_stage_phase, "局部横版舞台动效时钟应持续推进")
	_check(float(local_area.stage_foreground_overlay.get("visual_phase")) > previous_overlay_phase, "局部横版舞台前景遮挡层应同步动效时钟")
	var stage_rect: Rect2 = local_area.get_world_rect()
	var back_scale: float = local_area.get_actor_depth_scale(Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_TOP_RATIO))
	var front_scale: float = local_area.get_actor_depth_scale(Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_BOTTOM_RATIO))
	_check(front_scale - back_scale >= 0.25, "局部舞台应按前后排缩放角色")
	_check(local_area.prop_nodes.size() > 0, "平安镇局部地图应生成 2.5D 遮挡节点")
	_check(_textured_prop_count(local_area.prop_nodes) > 0, "平安镇 2.5D 道具应加载 PNG 资源")
	_check(_max_textured_actor_height(local_area.npc_nodes) >= 115.0, "局部地图 NPC 贴图显示不应继续偏小")
	_check(_actor_depth_scale_range(local_area.npc_nodes) >= 0.10, "局部 NPC 应按舞台前后排产生大小差异")
	_check(_actors_marked_stage(local_area.npc_nodes), "局部地图 NPC 应标记为横版舞台角色")
	_check(_actors_have_idle_motion(local_area.npc_nodes), "局部地图 NPC 应有待机轻微动态")
	_check(_texture_variant_count(local_area, LOCAL_TILE_MOUNTAIN) >= 4, "局部地图应加载多变体山体瓦片")
	_check(_min_actor_distance(local_area.npc_nodes) >= GameData.TILE_SIZE * 1.35, "平安镇 NPC 间距过近")
	_check(_actors_use_y_sort(local_area.npc_nodes), "局部地图 NPC 应按脚底 Y 坐标排序")
	_check(GameData.get_neighbor_regions("qinghe", 4).size() >= 3, "平安镇应能计算相邻区域")
	var travel_plan := GameState.build_region_travel_plan("luoyang")
	_check((travel_plan.get("route", []) as Array).size() >= 2, "平安镇到洛阳应能生成驿路路线")
	_check(float(travel_plan.get("hours", 0.0)) >= 1.0, "驿路路线应给出有效耗时")
	_check(not str(travel_plan.get("risk_label", "")).is_empty(), "驿路路线应给出风险等级")
	_check(int(travel_plan.get("fare", 0)) >= 3, "驿路路线应给出有效旅费")
	GameState.update_current_region(GameData.get_region("qinghe"), Vector2i(30, 16))
	GameState.region_state["luoyang"] = {"discovered": true, "exploration": 30, "visited": []}
	var previous_time := float(GameState.day) * 24.0 + GameState.hour
	var previous_money := int(GameState.player.get("money", 0))
	var previous_event_count := GameState.world_events.size()
	var travel_hours := GameState.apply_fast_travel_time("luoyang")
	_check(travel_hours >= 1.0, "满足条件后应能应用快速旅行")
	_check(float(GameState.day) * 24.0 + GameState.hour > previous_time, "快速旅行应推进时间")
	_check(int(GameState.player.get("money", 0)) == previous_money - int(travel_plan.get("fare", 0)), "快速旅行应扣除驿路费用")
	_check(GameState.world_events.size() > previous_event_count, "快速旅行应写入旅行事件")
	_check(GameState.resolve_fast_travel_risk(travel_plan).is_empty(), "低风险驿路不应触发旅途后果")
	player.world_map = local_area
	player.position = Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_BOTTOM_RATIO)
	player._refresh_stage_depth_scale()
	_check(player.stage_depth_scale > 1.08, "玩家在局部地图前景站位应明显放大")
	_check(player.get_map_actor_visual_scale() > player.stage_depth_scale, "玩家局部横版地图应在景深外叠加舞台角色缩放")
	player.world_map = world_map
	player.position = GameState.player_position
	player._refresh_stage_depth_scale()
	var map_panel = WORLD_MAP_PANEL_SCRIPT.new()
	add_child(map_panel)
	map_panel.show_panel()
	map_panel._select_region_by_id("luoyang")
	await get_tree().process_frame
	_check((map_panel.map_canvas.route_plan.get("route", []) as Array).size() >= 2, "世界地图面板应把选中区域的驿路线传给地图画布")
	map_panel.close_panel()
	map_panel.queue_free()
	_check(not _first_portal(local_area, "travel_region").is_empty(), "平安镇应生成相邻区域转场入口")
	_check(_portal_count(local_area, "landmark") >= 3, "平安镇应生成可互动地标")
	_check(_portal_count(local_area, "resource") >= 2, "平安镇应生成每日资源点")

	var shop_portal := _first_portal(local_area, "shop")
	_check(not shop_portal.is_empty(), "平安镇应存在可进入商铺")
	if not shop_portal.is_empty():
		local_area.enter_shop(shop_portal)
		await get_tree().process_frame
		_check(local_area.npc_nodes.size() == 1, "商铺内应生成 1 名掌柜")
		_check(local_area.scene_background_texture == null, "商铺内景不应继续叠加区域背景")
		_check(local_area.stage_foreground_overlay == null or not local_area.stage_foreground_overlay.visible, "商铺内景不应显示局部横版前景遮挡层")
		_check(not _first_portal(local_area, "exit_area").is_empty(), "商铺内应有出门入口")
		if local_area.npc_nodes.size() > 0:
			var keeper_data: Dictionary = local_area.npc_nodes[0].data
			_check((keeper_data.get("sell_items", []) as Array).size() > 0, "商铺掌柜应带商品列表")

	local_area.setup_region(GameData.get_region("linan"))
	await get_tree().process_frame
	_check(not local_area.is_tile_walkable(_first_tile_with_id(local_area, LOCAL_TILE_WATER)), "临安局部水面应不可通行")

	local_area.setup_region(GameData.get_region("emei_sacred"))
	await get_tree().process_frame
	_check(_tile_ratio(local_area, LOCAL_TILE_MOUNTAIN) < 0.32, "山地区域不应被山峰瓦片铺满")
	_check(local_area.is_position_walkable(local_area.get_entry_position("world")), "山地区域入口应可通行")

	test_root.queue_free()
	if failures.is_empty():
		print("PLAYTEST_SMOKE_OK")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ensure_input_actions() -> void:
	for action_name in ["move_right", "move_left", "move_down", "move_up"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _first_tile_with_id(map_node, tile_id: int) -> Vector2i:
	for y in range(map_node.map_height):
		for x in range(map_node.map_width):
			if int(map_node.tiles[y][x]) == tile_id:
				return Vector2i(x, y)
	return Vector2i.ZERO

func _first_portal(local_area, portal_type: String) -> Dictionary:
	for portal in local_area.portals:
		if str(portal.get("type", "")) == portal_type:
			return portal
	return {}

func _portal_count(local_area, portal_type: String) -> int:
	var count := 0
	for portal in local_area.portals:
		if str(portal.get("type", "")) == portal_type:
			count += 1
	return count

func _tile_ratio(map_node, tile_id: int) -> float:
	var count := 0
	var total: int = max(1, int(map_node.map_width) * int(map_node.map_height))
	for y in range(map_node.map_height):
		for x in range(map_node.map_width):
			if int(map_node.tiles[y][x]) == tile_id:
				count += 1
	return float(count) / float(total)

func _texture_variant_count(map_node, tile_id: int) -> int:
	var variants = map_node.tile_textures.get(tile_id, [])
	if typeof(variants) == TYPE_ARRAY:
		return (variants as Array).size()
	return 0

func _textured_prop_count(nodes: Array) -> int:
	var count := 0
	for prop in nodes:
		if is_instance_valid(prop) and prop.prop_texture != null:
			count += 1
	return count

func _max_textured_actor_height(nodes: Array) -> float:
	var max_height := 0.0
	for actor in nodes:
		if not is_instance_valid(actor) or actor.sprite_node == null or actor.sprite_node.texture == null:
			continue
		var texture_size: Vector2 = actor.sprite_node.texture.get_size()
		max_height = maxf(max_height, texture_size.y * actor.sprite_node.scale.y)
	return max_height

func _actor_depth_scale_range(nodes: Array) -> float:
	var min_scale := INF
	var max_scale := -INF
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not actor.data.has("map_actor_scale"):
			continue
		var actor_scale := float(actor.data.get("map_actor_scale", 1.0))
		min_scale = minf(min_scale, actor_scale)
		max_scale = maxf(max_scale, actor_scale)
	if min_scale == INF:
		return 0.0
	return max_scale - min_scale

func _actors_have_idle_motion(nodes: Array) -> bool:
	for actor in nodes:
		if is_instance_valid(actor) and actor.visual_phase > 0.0:
			return true
	return false

func _actors_marked_stage(nodes: Array) -> bool:
	if nodes.is_empty():
		return false
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			return false
	return true

func _actors_use_y_sort(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if actor.z_index != int(actor.position.y):
			return false
	return true

func _min_actor_distance(nodes: Array) -> float:
	var min_distance := INF
	for i in range(nodes.size()):
		var a = nodes[i]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, nodes.size()):
			var b = nodes[j]
			if not is_instance_valid(b):
				continue
			min_distance = min(min_distance, a.position.distance_to(b.position))
	if min_distance == INF:
		return 999999.0
	return min_distance
