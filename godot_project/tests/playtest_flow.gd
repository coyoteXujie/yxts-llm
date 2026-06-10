extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(4)

	main._start_new_game({
		"name": "流程测试",
		"gender": "male",
		"faction": "none"
	})
	await _frames(3)

	_check(GameState.mode == GameState.Mode.EXPLORE, "新游戏后应进入探索模式")
	_check(main.active_map == main.local_area, "新游戏应直接进入平安镇横版城镇")
	_check(main.player_actor != null and main.player_actor.world_map == main.local_area, "玩家新游戏后应绑定局部城镇地图")
	_check(not main.world_map.visible and main.local_area.visible, "新游戏首屏不应继续显示世界大地图")

	var qinghe := GameData.get_region("qinghe")
	_check(not qinghe.is_empty(), "测试区域 qinghe 应存在")
	if not qinghe.is_empty():
		_check(str(main.local_area.current_region.get("id", "")) == "qinghe", "新游戏首个局部城镇应为平安镇")
		_check(main.local_area.current_mode == "region", "进入平安镇后应处于区域模式")
		_check(main.local_area.npc_nodes.size() >= 8, "平安镇局部地图应有镇民")
		_check(_min_actor_distance(main.local_area.npc_nodes) >= GameData.TILE_SIZE * 2.4, "平安镇 NPC 仍然过于拥挤")
		var travel_portal := _first_portal(main.local_area, "travel_region")
		_check(not travel_portal.is_empty(), "平安镇应有通往相邻区域的路牌入口")
		var landmark_portal := _first_reward_landmark(main.local_area)
		_check(not landmark_portal.is_empty(), "平安镇应有带奖励的探索地标")
		if not landmark_portal.is_empty():
			var reward_item := str(landmark_portal.get("reward_item", ""))
			var before_landmark_item_count := int(GameState.inventory.get(reward_item, 0))
			main._inspect_landmark(landmark_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "探索地标应打开发现面板")
			_check(GameState.mode == GameState.Mode.DISCOVERY, "发现面板应切换到发现模式")
			_check(int(GameState.inventory.get(reward_item, 0)) == before_landmark_item_count + 1, "探索地标应发放一次性奖励")
			main.discovery_panel.close_panel()
			await _frames(1)
			main._inspect_landmark(landmark_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "重复探索也应展示发现面板")
			_check(int(GameState.inventory.get(reward_item, 0)) == before_landmark_item_count + 1, "重复探索同一地标不应重复发奖")
			main.discovery_panel.close_panel()
			await _frames(1)

		var resource_portal := _first_reward_resource(main.local_area)
		_check(not resource_portal.is_empty(), "平安镇应有每日资源点")
		if not resource_portal.is_empty():
			var resource_item := str(resource_portal.get("reward_item", ""))
			var before_resource_item_count := int(GameState.inventory.get(resource_item, 0))
			main._inspect_resource(resource_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "采集资源点应打开发现面板")
			_check(GameState.mode == GameState.Mode.DISCOVERY, "资源点面板应切换到发现模式")
			_check(int(GameState.inventory.get(resource_item, 0)) == before_resource_item_count + 1, "资源点应发放当日奖励")
			main.discovery_panel.close_panel()
			await _frames(1)
			main._inspect_resource(resource_portal)
			await _frames(1)
			_check(int(GameState.inventory.get(resource_item, 0)) == before_resource_item_count + 1, "同一天重复采集资源点不应重复发奖")
			main.discovery_panel.close_panel()
			await _frames(1)

		var shop_portal := _first_portal(main.local_area, "shop")
		_check(not shop_portal.is_empty(), "平安镇应有可进入商铺")
		if not shop_portal.is_empty():
			main._enter_shop(shop_portal)
			await _frames(3)
			_check(main.local_area.current_mode == "shop", "应能进入商铺内景")
			_check(main.local_area.npc_nodes.size() == 1, "商铺内应只生成掌柜")
			if main.local_area.npc_nodes.size() == 1:
				var keeper = main.local_area.npc_nodes[0]
				main._open_dialogue(keeper.data)
				await _frames(2)
				_check(GameState.mode == GameState.Mode.DIALOGUE, "应能与商铺掌柜对话")
				_check(main.dialogue_panel.visible, "对话面板应显示")
				main.dialogue_panel._shop()
				await _frames(2)
				_check(GameState.mode == GameState.Mode.SHOP, "点击交易后应进入商店模式")
				_check(main.shop_panel.visible, "商店面板应显示")
				_check(main.shop_panel.item_ids.size() > 0, "商店应加载商品列表")
				if main.shop_panel.item_ids.size() > 0:
					var item_id := str(main.shop_panel.item_ids[0])
					var before_count := int(GameState.inventory.get(item_id, 0))
					var before_money := int(GameState.player.get("money", 0))
					main.shop_panel.item_list.select(0)
					main.shop_panel._buy_selected()
					await _frames(1)
					_check(int(GameState.inventory.get(item_id, 0)) == before_count + 1, "购买后物品应进入背包")
					_check(int(GameState.player.get("money", 0)) < before_money, "购买后银两应减少")
				main.shop_panel.close_panel()
				await _frames(1)
			main._exit_shop_to_area()
			await _frames(2)
			_check(main.local_area.current_mode == "region", "出门后应回到局部区域")
		if not travel_portal.is_empty():
			var target_region_id := str(travel_portal.get("target_region_id", ""))
			main._travel_to_linked_region(travel_portal)
			await _frames(3)
			_check(main.active_map == main.local_area, "相邻区域转场后仍应停留在局部地图层")
			_check(str(main.local_area.current_region.get("id", "")) == target_region_id, "相邻区域转场应切换目标区域")
			_check(main.local_area.portals.size() >= 2, "目标区域应继续生成入口")
		main._return_to_world()
		await _frames(2)
		_check(main.active_map == main.world_map, "应能从局部地图返回世界地图")

	await _capture_snapshot()
	main.queue_free()

	if failures.is_empty():
		print("PLAYTEST_FLOW_OK")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		get_tree().quit(1)

func _frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _first_portal(local_area, portal_type: String) -> Dictionary:
	for portal in local_area.portals:
		if str(portal.get("type", "")) == portal_type:
			return portal
	return {}

func _first_reward_landmark(local_area) -> Dictionary:
	for portal in local_area.portals:
		if str(portal.get("type", "")) == "landmark" and not str(portal.get("reward_item", "")).is_empty():
			return portal
	return {}

func _first_reward_resource(local_area) -> Dictionary:
	for portal in local_area.portals:
		if str(portal.get("type", "")) == "resource" and not str(portal.get("reward_item", "")).is_empty():
			return portal
	return {}

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

func _capture_snapshot() -> void:
	await _frames(2)
	if DisplayServer.get_name() == "headless":
		print("PLAYTEST_FLOW_CAPTURE_SKIPPED headless")
		return
	var image := get_viewport().get_texture().get_image()
	_check(image.get_width() >= 640 and image.get_height() >= 360, "自动游玩截图尺寸异常")
	_check(_image_has_variation(image), "自动游玩截图疑似空白")
	var error := image.save_png("user://playtest_flow.png")
	_check(error == OK, "自动游玩截图保存失败")

func _image_has_variation(image: Image) -> bool:
	if image.get_width() <= 0 or image.get_height() <= 0:
		return false
	var first := image.get_pixel(0, 0)
	var step_x: int = maxi(1, int(image.get_width() / 8))
	var step_y: int = maxi(1, int(image.get_height() / 8))
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var color := image.get_pixel(x, y)
			var diff := absf(color.r - first.r) + absf(color.g - first.g) + absf(color.b - first.b)
			if diff > 0.08:
				return true
	return false
