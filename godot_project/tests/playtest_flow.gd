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
	_check(main.hud.region_label.text.contains("探索") and main.hud.region_label.text.contains("·"), "HUD 所在地区域栏应显示探索阶段")
	var prompt_segments: Array = main.hud._prompt_segments("E 探索古井（井台）    B 背包  J 任务  K 修炼  M 地图")
	_check(prompt_segments.size() == 5 and str((prompt_segments[0] as Dictionary).get("key", "")) == "E" and str((prompt_segments[0] as Dictionary).get("label", "")).contains("探索"), "HUD 应把探索提示解析为快捷键分段")
	main.hud.set_prompt("E 探索古井（井台）    B 背包  J 任务  K 修炼  M 地图")
	_check(main.hud.prompt_panel.visible and not main.hud.prompt_label.visible, "HUD 底部提示应显示分段快捷栏而不是单行长文本")
	if main.hud.prompt_chips.size() > 0:
		var primary_prompt_chip: PanelContainer = main.hud.prompt_chips[0]
		_check(main.hud.prompt_chips.size() == 5 and primary_prompt_chip.custom_minimum_size.x >= 74.0, "HUD 快捷栏应生成稳定尺寸的操作 chip")
		main.hud.set_prompt("E 探索古井（井台）    B 背包  J 任务  K 修炼  M 地图")
		_check(main.hud.prompt_chips.size() == 5 and main.hud.prompt_chips[0] == primary_prompt_chip, "HUD 相同提示不应每帧重建快捷栏 chip")
	else:
		_check(false, "HUD 快捷栏应生成操作 chip")

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
			_check(main._portal_prompt(landmark_portal).contains("探索") and main._portal_prompt(landmark_portal).contains("（"), "地标靠近提示应展示探索动作和类型")
			var reward_item := str(landmark_portal.get("reward_item", ""))
			var before_landmark_item_count := int(GameState.inventory.get(reward_item, 0))
			var before_landmark_exploration := GameState.get_region_exploration("qinghe")
			var before_landmark_event_count := GameState.world_events.size()
			main._inspect_landmark(landmark_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "探索地标应打开发现面板")
			_check(GameState.mode == GameState.Mode.DISCOVERY, "发现面板应切换到发现模式")
			_check(int(GameState.inventory.get(reward_item, 0)) == before_landmark_item_count + 1, "探索地标应发放一次性奖励")
			_check(GameState.get_region_exploration("qinghe") >= before_landmark_exploration + 8, "首次探索地标应推进区域探索度")
			_check(GameState.world_events.size() > before_landmark_event_count and GameState.get_world_event_summary(2).contains(str(landmark_portal.get("label", ""))), "首次探索地标应写入江湖发现传闻")
			main.discovery_panel.close_panel()
			await _frames(1)
			var after_landmark_exploration := GameState.get_region_exploration("qinghe")
			var after_landmark_event_count := GameState.world_events.size()
			main._inspect_landmark(landmark_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "重复探索也应展示发现面板")
			_check(int(GameState.inventory.get(reward_item, 0)) == before_landmark_item_count + 1, "重复探索同一地标不应重复发奖")
			_check(GameState.get_region_exploration("qinghe") == after_landmark_exploration and GameState.world_events.size() == after_landmark_event_count, "重复探索同一地标不应重复推进探索度或传闻")
			main.discovery_panel.close_panel()
			await _frames(1)

		var resource_portal := _first_reward_resource(main.local_area)
		_check(not resource_portal.is_empty(), "平安镇应有每日资源点")
		if not resource_portal.is_empty():
			_check(main._portal_prompt(resource_portal).contains("采集") and main._portal_prompt(resource_portal).contains("（"), "资源点靠近提示应展示采集动作和类型")
			var resource_item := str(resource_portal.get("reward_item", ""))
			var before_resource_item_count := int(GameState.inventory.get(resource_item, 0))
			var before_resource_exploration := GameState.get_region_exploration("qinghe")
			main._inspect_resource(resource_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "采集资源点应打开发现面板")
			_check(GameState.mode == GameState.Mode.DISCOVERY, "资源点面板应切换到发现模式")
			_check(int(GameState.inventory.get(resource_item, 0)) == before_resource_item_count + 1, "资源点应发放当日奖励")
			_check(GameState.get_region_exploration("qinghe") >= before_resource_exploration + 3, "首次采集资源点应推进区域探索度")
			main.discovery_panel.close_panel()
			await _frames(1)
			var after_resource_exploration := GameState.get_region_exploration("qinghe")
			main._inspect_resource(resource_portal)
			await _frames(1)
			_check(int(GameState.inventory.get(resource_item, 0)) == before_resource_item_count + 1, "同一天重复采集资源点不应重复发奖")
			_check(GameState.get_region_exploration("qinghe") == after_resource_exploration, "同一天重复采集资源点不应重复推进探索度")
			main.discovery_panel.close_panel()
			await _frames(1)

		GameState.region_state["qinghe"] = {"discovered": true, "exploration": 75, "visited": [], "exploration_milestones": [25, 50, 75]}
		main.local_area.setup_region(qinghe)
		await _frames(2)
		var hidden_clue_portal := _first_portal(main.local_area, "hidden_clue")
		_check(not hidden_clue_portal.is_empty(), "探索达到寻幽探隐后平安镇应出现隐藏线索入口")
		if not hidden_clue_portal.is_empty():
			_check(main._portal_prompt(hidden_clue_portal).contains("追查") and main._portal_prompt(hidden_clue_portal).contains("隐线"), "隐藏线索靠近提示应展示追查动作和隐线类型")
			var before_hidden_exploration := GameState.get_region_exploration("qinghe")
			var before_hidden_event_count := GameState.world_events.size()
			main._inspect_hidden_clue(hidden_clue_portal)
			await _frames(1)
			_check(main.discovery_panel.visible, "追查隐藏线索应打开发现面板")
			_check(GameState.mode == GameState.Mode.DISCOVERY, "隐藏线索面板应切换到发现模式")
			_check(GameState.get_region_exploration("qinghe") >= before_hidden_exploration + 5, "首次追查隐藏线索应推进区域探索度")
			_check(GameState.world_events.size() > before_hidden_event_count and GameState.get_world_event_summary(1).contains(str(hidden_clue_portal.get("label", ""))), "首次追查隐藏线索应写入江湖传闻")
			var hidden_clues_after_first := GameState.get_adventure_clues(4)
			_check(hidden_clues_after_first.size() == 1 and JSON.stringify(hidden_clues_after_first).contains(str(hidden_clue_portal.get("label", ""))), "首次追查隐藏线索应记录可延展的奇遇线索")
			_check(not str((hidden_clues_after_first[0] as Dictionary).get("target_region_id", "")).is_empty(), "隐藏奇遇线索应记录后续指向区域")
			main.discovery_panel.close_panel()
			await _frames(1)
			main.quest_panel.show_panel()
			await _frames(1)
			_check(main.quest_panel.rumor_text.text.contains("奇遇线索") and main.quest_panel.rumor_text.text.contains(str(hidden_clue_portal.get("label", ""))) and main.quest_panel.rumor_text.text.contains("指向"), "任务日志江湖页应展示追查到的奇遇线索和指向区域")
			_check(main.quest_panel.quest_text.text.contains("奇遇线索") and main.quest_panel.quest_text.text.contains(str(hidden_clue_portal.get("label", ""))) and main.quest_panel.quest_text.text.contains("指向"), "任务页应把奇遇线索作为带区域指向的后续行动记录")
			main.quest_panel.close_panel()
			await _frames(1)
			var after_hidden_exploration := GameState.get_region_exploration("qinghe")
			var after_hidden_event_count := GameState.world_events.size()
			var after_hidden_clue_count := GameState.get_adventure_clues(0).size()
			main._inspect_hidden_clue(hidden_clue_portal)
			await _frames(1)
			_check(GameState.get_region_exploration("qinghe") == after_hidden_exploration and GameState.world_events.size() == after_hidden_event_count, "重复追查隐藏线索不应重复推进探索度或传闻")
			_check(GameState.get_adventure_clues(0).size() == after_hidden_clue_count, "重复追查隐藏线索不应重复记录奇遇线索")
			main.discovery_panel.close_panel()
			await _frames(1)

		var shop_portal := _first_portal(main.local_area, "shop")
		_check(not shop_portal.is_empty(), "平安镇应有可进入商铺")
		if not shop_portal.is_empty():
			_check(main._portal_prompt(shop_portal).contains("进入") and main._portal_prompt(shop_portal).contains("商铺"), "商铺靠近提示应展示进入动作和商铺类型")
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
					main.shop_panel._select_item(0)
					main.shop_panel._set_quantity(2)
					var unit_buy_price := int(GameData.get_item(item_id).get("price", 0))
					_check(main.shop_panel.quantity_label.text == "2" and main.shop_panel.primary_button.text.contains("x2"), "商店购买应支持数量选择和按钮预览")
					_check(main.shop_panel.total_label.text.contains(str(unit_buy_price * 2)), "商店购买应显示批量合计价格")
					main.shop_panel._confirm_selected()
					await _frames(1)
					_check(main.shop_panel.confirm_overlay.visible and main.shop_panel.confirm_body_label.text.contains("合计"), "商店购买应先弹出交易确认")
					_check(int(GameState.inventory.get(item_id, 0)) == before_count and int(GameState.player.get("money", 0)) == before_money, "交易确认前不应改变背包或银两")
					main.shop_panel._confirm_pending_transaction()
					await _frames(1)
					_check(int(GameState.inventory.get(item_id, 0)) == before_count + 2, "批量购买后物品应进入背包")
					_check(int(GameState.player.get("money", 0)) == before_money - unit_buy_price * 2, "批量购买后银两应按合计减少")
					var money_after_buy := int(GameState.player.get("money", 0))
					main.shop_panel._set_shop_mode("sell")
					await _frames(1)
					var sell_index: int = main.shop_panel.item_ids.find(item_id)
					_check(sell_index >= 0 and main.shop_panel.item_list.get_item_text(sell_index).contains("卖"), "商店出售页应列出背包物品和出售价")
					if sell_index >= 0:
						main.shop_panel.item_list.select(sell_index)
						main.shop_panel._select_item(sell_index)
						main.shop_panel._set_quantity(2)
						_check(main.shop_panel.quantity_label.text == "2" and main.shop_panel.total_label.text.contains(str(GameState.get_item_sell_price(item_id) * 2)), "商店出售应支持批量数量和收入预览")
						main.shop_panel._confirm_selected()
						await _frames(1)
						_check(main.shop_panel.confirm_overlay.visible and main.shop_panel.confirm_body_label.text.contains("收入"), "商店出售应先弹出交易确认")
						_check(int(GameState.inventory.get(item_id, 0)) == before_count + 2 and int(GameState.player.get("money", 0)) == money_after_buy, "出售确认前不应改变背包或银两")
						main.shop_panel._confirm_pending_transaction()
						await _frames(1)
						_check(int(GameState.inventory.get(item_id, 0)) == before_count, "出售后物品数量应减少")
						_check(int(GameState.player.get("money", 0)) == money_after_buy + GameState.get_item_sell_price(item_id) * 2, "批量出售后应按出售价增加银两")
						var money_after_sell := int(GameState.player.get("money", 0))
						main.shop_panel._set_shop_mode("buyback")
						await _frames(1)
						var buyback_index: int = main.shop_panel.item_ids.find(item_id)
						_check(buyback_index >= 0 and main.shop_panel.item_list.get_item_text(buyback_index).contains("回购"), "商店回购页应列出刚卖出的物品")
						if buyback_index >= 0:
							main.shop_panel.item_list.select(buyback_index)
							main.shop_panel._select_item(buyback_index)
							main.shop_panel._set_quantity(2)
							_check(main.shop_panel.primary_button.text.contains("回购") and main.shop_panel.total_label.text.contains(str(GameState.get_item_sell_price(item_id) * 2)), "商店回购应显示数量和合计")
							main.shop_panel._confirm_selected()
							await _frames(1)
							_check(main.shop_panel.confirm_overlay.visible and main.shop_panel.confirm_title_label.text.contains("回购"), "商店回购应先弹出交易确认")
							_check(int(GameState.inventory.get(item_id, 0)) == before_count and int(GameState.player.get("money", 0)) == money_after_sell, "回购确认前不应改变背包或银两")
							main.shop_panel._confirm_pending_transaction()
							await _frames(1)
							_check(int(GameState.inventory.get(item_id, 0)) == before_count + 2, "回购后物品应回到背包")
							_check(int(GameState.player.get("money", 0)) == money_after_sell - GameState.get_item_sell_price(item_id) * 2, "回购后应按回购价扣银两")
							main.shop_panel._set_shop_mode("buyback")
							await _frames(1)
							_check(main.shop_panel.item_ids.find(item_id) < 0, "回购完成后对应回购库存应清空")
					GameState.add_item("item_sword", 1)
					GameState.equip_item("item_sword")
					var equipped_sword_count := int(GameState.inventory.get("item_sword", 0))
					var money_before_equipped_sell := int(GameState.player.get("money", 0))
					main.shop_panel._set_shop_mode("sell")
					await _frames(1)
					var equipped_index: int = main.shop_panel.item_ids.find("item_sword")
					_check(equipped_index >= 0 and main.shop_panel.item_list.get_item_text(equipped_index).contains("已装备"), "商店出售页应标识已装备物品")
					if equipped_index >= 0:
						main.shop_panel.item_list.select(equipped_index)
						main.shop_panel._sell_selected()
						await _frames(1)
						_check(int(GameState.inventory.get("item_sword", 0)) == equipped_sword_count and int(GameState.player.get("money", 0)) == money_before_equipped_sell, "已装备物品不应被出售")
				main.shop_panel.close_panel()
				await _frames(1)
			main._exit_shop_to_area()
			await _frames(2)
			_check(main.local_area.current_mode == "region", "出门后应回到局部区域")
		if not travel_portal.is_empty():
			var target_region_id := str(travel_portal.get("target_region_id", ""))
			var before_travel_time := float(GameState.day) * 24.0 + GameState.hour
			var before_event_count := GameState.world_events.size()
			main._travel_to_linked_region(travel_portal)
			await _frames(3)
			_check(main.active_map == main.local_area, "相邻区域转场后仍应停留在局部地图层")
			_check(str(main.local_area.current_region.get("id", "")) == target_region_id, "相邻区域转场应切换目标区域")
			_check(main.local_area.portals.size() >= 2, "目标区域应继续生成入口")
			_check(float(GameState.day) * 24.0 + GameState.hour > before_travel_time, "相邻区域转场应推进路程时间")
			_check(GameState.world_events.size() > before_event_count, "相邻区域转场应写入行路事件")
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
