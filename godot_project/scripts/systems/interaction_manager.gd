extends Node
class_name InteractionManager
## NPC/传送门交互与探索状态管理：提取自 main.gd
##
## 职责：
##   - NPC 交互与对话触发
##   - 传送门交互处理（商铺、地标、资源、线索等）
##   - 探索状态下 HUD 提示更新
##   - 环境 NPC 对话气泡
##   - 地标/线索的发现与奖励发放
##   - 快速旅行（fast travel）逻辑
##   - 存档/输入相关的回调代理

signal explore_actions_cleared()

## --- 外部引用（由 main.gd 在初始化时设置）---
var world_map: Node
var local_area: Node
var player_actor: Node
var hud: Node
var dialogue_panel: Node
var shop_panel: Node
var combat_panel: Node
var discovery_panel: Node
var combat_system: Node
var map_transition_manager: Node

## --- 常量 ---
const AMBIENT_NPC_INTERVAL := 6.8
const AMBIENT_NPC_RADIUS := 430.0
const POST_TRANSITION_RESET_DELAY := 1.2
const LANDMARK_EXPLORATION_GAIN := 8
const RESOURCE_EXPLORATION_GAIN := 3
const HIDDEN_CLUE_EXPLORATION_GAIN := 5
const ADVENTURE_CLUE_EXPLORATION_GAIN := 6
const ADVENTURE_AMBUSH_MIN_DANGER := 3

## --- 状态 ---
var focused_npc
var focused_portal: Dictionary = {}
var active_enemy_actor
var ambient_npc_timer := 2.0
var ambient_npc_round := 0
var pending_quest_summaries: Array[Dictionary] = []

func setup_references(p_world_map: Node, p_local_area: Node, p_player: Node, p_hud: Node,
		p_dialogue: Node, p_shop: Node, p_combat_panel: Node, p_discovery: Node,
		p_combat_system: Node, p_transition_mgr: Node) -> void:
	world_map = p_world_map
	local_area = p_local_area
	player_actor = p_player
	hud = p_hud
	dialogue_panel = p_dialogue
	shop_panel = p_shop
	combat_panel = p_combat_panel
	discovery_panel = p_discovery
	combat_system = p_combat_system
	map_transition_manager = p_transition_mgr

## 清除探索状态
func clear_explore_state() -> void:
	_clear_map_explore_state()
	if hud != null:
		hud.set_prompt("")

func _clear_map_explore_state() -> void:
	if world_map != null:
		if world_map.has_method("clear_highlights"):
			world_map.clear_highlights()
		if world_map.has_method("clear_ambient_lines"):
			world_map.clear_ambient_lines()
	if local_area != null:
		if local_area.has_method("clear_highlights"):
			local_area.clear_highlights()
		if local_area.has_method("clear_ambient_lines"):
			local_area.clear_ambient_lines()

## 更新探索上下文：聚焦最近的 NPC 和传送门
func update_explore_context(active_map: Node) -> void:
	_update_current_region(active_map)
	focused_npc = active_map.get_nearest_npc(player_actor.position, 92.0, true)
	if active_map.has_method("focus_actor"):
		active_map.focus_actor(focused_npc)
	focused_portal = {}
	if active_map.has_method("get_nearest_portal"):
		focused_portal = active_map.get_nearest_portal(player_actor.position, 80.0)
		if active_map.has_method("focus_portal"):
			active_map.focus_portal(focused_portal)

func _update_current_region(active_map: Node) -> void:
	var tile: Vector2i = active_map.world_to_tile(player_actor.position)
	var region: Dictionary = active_map.get_region_at_world_position(player_actor.position)
	if active_map == local_area and local_area.has_method("get_world_reference_tile"):
		tile = local_area.get_world_reference_tile(player_actor.position)
	GameState.update_current_region(region, tile)

## 更新 HUD 提示文本
func update_explore_prompt(active_map: Node) -> void:
	if focused_npc == null:
		if not focused_portal.is_empty():
			hud.set_prompt("E %s    B 背包  J 任务  K 修炼  M 地图" % _portal_prompt(focused_portal))
		else:
			var region := _current_region_for_entry(active_map)
			var enter_prompt := _region_enter_prompt(region)
			if not enter_prompt.is_empty():
				hud.set_prompt("%s    B 背包  J 任务  K 修炼  M 地图" % enter_prompt)
			else:
				hud.set_prompt("B 背包  J 任务  K 修炼  M 地图  F5/F9 存读档  Esc 菜单")
		return

	if focused_npc.is_enemy():
		hud.set_prompt("F 挑战 %s    T 观察" % str(focused_npc.data.get("name", "敌人")))
	else:
		hud.set_prompt("T 与 %s 交谈" % str(focused_npc.data.get("name", "NPC")))

## 处理探索中的交互输入（攻击/对话快捷键）
func handle_explore_actions() -> void:
	if focused_npc == null:
		return
	if Input.is_action_just_pressed("interact"):
		_open_dialogue(focused_npc.data)
	if focused_npc.is_enemy() and Input.is_action_just_pressed("attack"):
		active_enemy_actor = focused_npc
		combat_system.start(focused_npc.data)

## 处理主入口按键（E键进入区域/传送门）
func handle_enter_area(active_map: Node) -> void:
	if active_map == world_map:
		var region := _current_region_for_entry(active_map)
		if region.is_empty():
			EventBus.emit_toast("这里还不是可进入的区域")
			return
		if not _can_enter_region(region):
			EventBus.emit_toast("这片区域暂未开放内景")
			return
		map_transition_manager.enter_local_region(region)
		return
	if focused_portal.is_empty():
		EventBus.emit_toast("附近没有可进入的入口")
		return
	var portal_type := str(focused_portal.get("type", ""))
	match portal_type:
		"exit_world":
			map_transition_manager.return_to_world()
		"shop":
			map_transition_manager.enter_shop(focused_portal)
		"shop_service":
			_open_shop_service()
		"exit_area":
			map_transition_manager.exit_shop_to_area()
		"travel_region":
			map_transition_manager.travel_to_linked_region(focused_portal)
		"landmark":
			_inspect_landmark(focused_portal)
		"resource":
			_inspect_resource(focused_portal)
		"hidden_clue":
			_inspect_hidden_clue(focused_portal)
		"adventure_clue":
			_inspect_adventure_clue(focused_portal)
		"look":
			_inspect_roadside_event(focused_portal)
		_:
			EventBus.emit_toast("入口还没有接入")

## 环境 NPC 自动对话
func update_ambient_npc_lines(delta: float, active_map: Node) -> void:
	if active_map == null or player_actor == null or not active_map.has_method("get_nearby_npcs"):
		return
	ambient_npc_timer -= delta
	if ambient_npc_timer > 0.0:
		return
	ambient_npc_timer = AMBIENT_NPC_INTERVAL + float((ambient_npc_round * 17) % 9) * 0.22
	ambient_npc_round += 1
	var nearby: Array = active_map.get_nearby_npcs(player_actor.position, AMBIENT_NPC_RADIUS, false, 6)
	if nearby.is_empty():
		return
	var available: Array = []
	for actor in nearby:
		if not is_instance_valid(actor):
			continue
		if actor.has_method("has_active_ambient_line") and actor.has_active_ambient_line():
			continue
		available.append(actor)
	if available.is_empty():
		return
	var index: int = ambient_npc_round % available.size()
	var actor = available[index]
	var distance: float = player_actor.position.distance_to(actor.position)
	var line: String = LLMDirector.generate_ambient_npc_line(actor.data, distance, actor == focused_npc)
	if not line.is_empty() and actor.has_method("show_ambient_line"):
		actor.show_ambient_line(line)

## 处理 pending quest summary
func try_show_pending_quest_summary() -> void:
	if pending_quest_summaries.is_empty():
		return
	if discovery_panel == null or not GameState.can_explore():
		return
	if discovery_panel.visible:
		return
	var summary: Dictionary = pending_quest_summaries.pop_front()
	var description_parts: Array[String] = []
	var description := str(summary.get("description", ""))
	if not description.is_empty():
		description_parts.append(description)
	var next_hint := str(summary.get("next_hint", summary.get("active_quest", "")))
	if not next_hint.is_empty():
		description_parts.append("下一步：%s" % next_hint)
	discovery_panel.show_discovery({
		"title": "任务完成：%s" % str(summary.get("title", "任务")),
		"region": str(summary.get("region_name", GameState.current_region_name)),
		"description": "\n".join(description_parts),
		"rewards": summary.get("reward_lines", [])
	})

## 快速旅行
func fast_travel_to_region(region_id: String, active_map: Node) -> void:
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return
	if active_map != world_map:
		map_transition_manager.switch_to_world_map(map_transition_manager.world_return_position)
	var reason := GameState.get_fast_travel_block_reason(region_id)
	if not reason.is_empty():
		EventBus.emit_toast(reason)
		return
	var destination: Vector2 = world_map.get_region_entry_position(region_id)
	if not world_map.is_position_walkable(destination):
		EventBus.emit_toast("目的地入口暂不可通行")
		return
	var travel_plan := GameState.build_region_travel_plan(region_id)
	var travel_hours := GameState.apply_fast_travel_time(region_id)
	if travel_hours < 0.0:
		return
	map_transition_manager.transition_player_to_map(world_map, destination, true)
	GameState.set_map_target_region("")
	if world_map.has_method("set_target_region"):
		world_map.set_target_region("")
	_update_current_region(world_map)
	_close_gameplay_panels()
	GameState.set_mode(GameState.Mode.EXPLORE)
	var fare := int(travel_plan.get("fare", 0))
	var fare_text := "，花费%d两" % fare if fare > 0 else ""
	EventBus.emit_toast("抵达%s，用时 %.1f 时辰%s" % [str(region.get("name", region_id)), travel_hours, fare_text])
	_handle_fast_travel_complication(GameState.resolve_fast_travel_risk(travel_plan))

func _handle_fast_travel_complication(complication: Dictionary) -> void:
	if complication.is_empty():
		return
	var toast := str(complication.get("toast", "旅途有变"))
	if not toast.is_empty():
		EventBus.emit_toast(toast)
	if str(complication.get("kind", "")) == "ambush":
		var enemy: Dictionary = complication.get("enemy", {})
		if not enemy.is_empty():
			active_enemy_actor = null
			combat_system.start(enemy)

## -- 传送门分析相关方法 --

func _can_enter_region(region: Dictionary) -> bool:
	var region_type := str(region.get("type", ""))
	var enterable := {
		"city": true,
		"town": true,
		"sect": true,
		"wild": true
	}
	return enterable.get(region_type, false)

func _current_region_for_entry(active_map: Node) -> Dictionary:
	if active_map != world_map:
		return {}
	return world_map.get_region_at_world_position(player_actor.position)

func _region_enter_prompt(region: Dictionary) -> String:
	if region.is_empty():
		return ""
	if not _can_enter_region(region):
		return ""
	return "E 进入%s" % str(region.get("name", "区域"))

func _portal_prompt(portal: Dictionary) -> String:
	var portal_type := str(portal.get("type", ""))
	if portal_type == "travel_region":
		var direction := str(portal.get("direction_label", "路"))
		var hours := float(portal.get("travel_hours", 0.0))
		var risk := str(portal.get("risk_label", ""))
		if hours > 0.0 and not risk.is_empty():
			return "%s（%s路 %.1f时辰，%s）" % [str(portal.get("label", "入口")), direction, hours, risk]
	if portal_type == "shop":
		return "%s%s（%s）" % [
			str(portal.get("action_label", "进入")),
			str(portal.get("shop_name", portal.get("label", "商铺"))),
			str(portal.get("interaction_hint", "商铺"))
		]
	if portal_type == "shop_service":
		return "%s%s（%s）" % [
			str(portal.get("action_label", "交谈")),
			str(portal.get("label", "柜台服务")),
			str(portal.get("interaction_hint", "交易"))
		]
	if portal_type == "landmark" or portal_type == "resource" or portal_type == "hidden_clue" or portal_type == "adventure_clue":
		var action := str(portal.get("action_label", "查看"))
		var hint := str(portal.get("interaction_hint", ""))
		if not hint.is_empty():
			return "%s%s（%s）" % [action, str(portal.get("label", "入口")), hint]
		return "%s%s" % [action, str(portal.get("label", "入口"))]
	return str(portal.get("label", "入口"))

func _open_dialogue(npc: Dictionary) -> void:
	_clear_map_explore_state()
	GameState.progress_quest("talk", str(npc.get("name", "")), 1)
	GameState.set_mode(GameState.Mode.DIALOGUE)
	dialogue_panel.show_npc(npc)

func _open_shop_service() -> void:
	if local_area == null or local_area.current_mode != "shop" or local_area.npc_nodes.is_empty():
		EventBus.emit_toast("柜台暂时没人")
		return
	_open_dialogue(local_area.npc_nodes[0].data)

## --- 地标/资源/线索 检查方法 ---

func _inspect_landmark(portal: Dictionary) -> void:
	var region_id := str(local_area.current_region.get("id", "region"))
	var portal_id := str(portal.get("id", "landmark"))
	var flag_key := "landmark_%s_%s" % [region_id, portal_id]
	var description := str(portal.get("description", "这里暂时没有更多线索。"))
	var already_seen := bool(GameState.game_flags.get(flag_key, false))
	if already_seen:
		_show_landmark_discovery(portal, description, [], true)
		return
	GameState.game_flags[flag_key] = true
	var reward_parts: Array[String] = []
	var item_id := str(portal.get("reward_item", ""))
	var reward_money := int(portal.get("reward_money", 0))
	var reward_exp := int(portal.get("reward_exp", 0))
	if not item_id.is_empty():
		GameState.add_item(item_id, 1)
		var item := GameData.get_item(item_id)
		reward_parts.append(str(item.get("name", item_id)))
	if reward_money > 0:
		GameState.add_money(reward_money)
		reward_parts.append("%d 两银子" % reward_money)
	if reward_exp > 0:
		GameState.reward_player(reward_exp, 0)
		reward_parts.append("%d 点阅历" % reward_exp)
	var exploration_after := GameState.add_region_exploration(region_id, LANDMARK_EXPLORATION_GAIN)
	reward_parts.append("探索度 +%d%%" % LANDMARK_EXPLORATION_GAIN)
	GameState.append_world_event(
		"discovery",
		"探得%s" % str(portal.get("label", "地标")),
		"你在%s发现了%s，区域探索推进到 %d%%。" % [
			str(local_area.current_region.get("name", region_id)),
			str(portal.get("label", "地标")),
			exploration_after
		],
		region_id,
		2
	)
	_show_landmark_discovery(portal, description, reward_parts, already_seen)

func _inspect_resource(portal: Dictionary) -> void:
	var region_id := str(local_area.current_region.get("id", "region"))
	var portal_id := str(portal.get("id", "resource"))
	var flag_key := "resource_%s_%s_last_day" % [region_id, portal_id]
	var last_day := int(GameState.game_flags.get(flag_key, 0))
	var already_seen := last_day == GameState.day
	if already_seen:
		_show_landmark_discovery(portal, str(portal.get("depleted_description", "这里今日已经搜寻过。")), [], true)
		return
	GameState.game_flags[flag_key] = GameState.day
	var reward_parts: Array[String] = []
	var item_id := str(portal.get("reward_item", ""))
	var reward_count := int(portal.get("reward_count", 1))
	var reward_money := int(portal.get("reward_money", 0))
	var reward_exp := int(portal.get("reward_exp", 0))
	if not item_id.is_empty():
		GameState.add_item(item_id, max(1, reward_count))
		var item := GameData.get_item(item_id)
		var item_name := str(item.get("name", item_id))
		if reward_count > 1:
			reward_parts.append("%s x%d" % [item_name, reward_count])
		else:
			reward_parts.append(item_name)
	if reward_money > 0:
		GameState.add_money(reward_money)
		reward_parts.append("%d 两银子" % reward_money)
	if reward_exp > 0:
		GameState.reward_player(reward_exp, 0)
		reward_parts.append("%d 点阅历" % reward_exp)
	GameState.add_region_exploration(region_id, RESOURCE_EXPLORATION_GAIN)
	reward_parts.append("探索度 +%d%%" % RESOURCE_EXPLORATION_GAIN)
	_show_landmark_discovery(portal, str(portal.get("description", "这里有一点可用的物资。")), reward_parts, false)

func _inspect_hidden_clue(portal: Dictionary) -> void:
	var region_id := str(local_area.current_region.get("id", "region"))
	var portal_id := str(portal.get("id", "hidden"))
	var flag_key := "hidden_clue_%s_%s" % [region_id, portal_id]
	var description := str(portal.get("description", "你发现了一条被人刻意藏住的线索。"))
	var already_seen := bool(GameState.game_flags.get(flag_key, false))
	if already_seen:
		_show_landmark_discovery(portal, description, [], true)
		return
	GameState.game_flags[flag_key] = true
	var reward_parts: Array[String] = []
	var item_id := str(portal.get("reward_item", ""))
	var reward_money := int(portal.get("reward_money", 0))
	var reward_exp := int(portal.get("reward_exp", 0))
	if not item_id.is_empty():
		GameState.add_item(item_id, 1)
		var item := GameData.get_item(item_id)
		reward_parts.append(str(item.get("name", item_id)))
	if reward_money > 0:
		GameState.add_money(reward_money)
		reward_parts.append("%d 两银子" % reward_money)
	if reward_exp > 0:
		GameState.reward_player(reward_exp, 0)
		reward_parts.append("%d 点阅历" % reward_exp)
	var exploration_after := GameState.add_region_exploration(region_id, HIDDEN_CLUE_EXPLORATION_GAIN)
	reward_parts.append("探索度 +%d%%" % HIDDEN_CLUE_EXPLORATION_GAIN)
	GameState.append_world_event(
		"hidden_clue",
		"隐线浮现：%s" % str(portal.get("label", "隐秘线索")),
		"你在%s追查到%s，区域探索推进到 %d%%。" % [
			str(local_area.current_region.get("name", region_id)),
			str(portal.get("label", "隐秘线索")),
			exploration_after
		],
		region_id,
		3
	)
	var clue_title := "追查%s" % str(portal.get("label", "隐秘线索"))
	var clue_description := str(portal.get("clue_hook", "这条线索还没有展开成正式任务，但已经记入任务日志的江湖页；后续可据此接入隐藏区域、奇遇 NPC 或伏击事件。"))
	if clue_description.is_empty():
		clue_description = "这条线索还没有展开成正式任务，但已经记入任务日志的江湖页；后续可据此接入隐藏区域、奇遇 NPC 或伏击事件。"
	var target_region_id := _hidden_clue_target_region_id(region_id)
	var clue := GameState.record_adventure_clue(
		"adventure_%s_%s" % [region_id, portal_id],
		clue_title,
		clue_description,
		region_id,
		str(portal.get("label", "隐秘线索")),
		target_region_id
	)
	if not clue.is_empty():
		reward_parts.append("奇遇线索已记录")
	_show_landmark_discovery(portal, description, reward_parts, false)

func _hidden_clue_target_region_id(region_id: String) -> String:
	var neighbors := GameData.get_neighbor_regions(region_id, 1)
	if neighbors.is_empty():
		return ""
	var target: Dictionary = neighbors[0]
	return str(target.get("id", ""))

func _inspect_adventure_clue(portal: Dictionary) -> void:
	var region_id := str(local_area.current_region.get("id", "region"))
	var region_name := str(local_area.current_region.get("name", region_id))
	var clue_id := str(portal.get("clue_id", "")).strip_edges()
	var description := str(portal.get("description", "你追到这条线索的落点，事情终于接上了。"))
	if clue_id.is_empty():
		EventBus.emit_toast("这条奇遇线索缺少记录")
		return
	if GameState.is_adventure_clue_resolved(clue_id):
		_show_landmark_discovery(portal, description, [], true)
		return
	var is_market_portal := str(portal.get("clue_source", "")) == "market"
	if is_market_portal and not _can_deliver_market_clue(portal, clue_id):
		_show_landmark_discovery(portal, _market_delivery_missing_description(portal, clue_id), [], true)
		return
	var resolved_clue := GameState.resolve_adventure_clue(clue_id)
	if resolved_clue.is_empty():
		EventBus.emit_toast("这条奇遇线索已经散了")
		return
	var reward_parts: Array[String] = []
	var item_id := str(portal.get("reward_item", ""))
	var reward_money := int(portal.get("reward_money", 0))
	var reward_exp := int(portal.get("reward_exp", 0))
	if not item_id.is_empty():
		GameState.add_item(item_id, 1)
		var item := GameData.get_item(item_id)
		reward_parts.append(str(item.get("name", item_id)))
	if reward_money > 0:
		GameState.add_money(reward_money)
		reward_parts.append("%d 两银子" % reward_money)
	if reward_exp > 0:
		GameState.reward_player(reward_exp, 0)
		reward_parts.append("%d 点阅历" % reward_exp)
	var exploration_after := GameState.add_region_exploration(region_id, ADVENTURE_CLUE_EXPLORATION_GAIN)
	reward_parts.append("探索度 +%d%%" % ADVENTURE_CLUE_EXPLORATION_GAIN)
	if GameState.map_target_region_id == region_id:
		GameState.set_map_target_region("")
	var is_market_clue := str(resolved_clue.get("source", "")) == "market" or is_market_portal
	var aftermath: Dictionary = {}
	if is_market_clue:
		aftermath = _resolve_market_clue_aftermath(local_area.current_region, resolved_clue, portal)
	else:
		aftermath = _resolve_adventure_aftermath(local_area.current_region, resolved_clue, portal)
	var aftermath_description := str(aftermath.get("description", ""))
	if not aftermath_description.is_empty():
		description = "%s\n\n%s" % [description, aftermath_description]
	var aftermath_reward := str(aftermath.get("reward_label", ""))
	if not aftermath_reward.is_empty():
		reward_parts.append(aftermath_reward)
	var event_title := "奇遇落点：%s" % str(portal.get("label", "奇遇线索"))
	var event_description := "你在%s追到%s，区域探索推进到 %d%%。" % [
		region_name,
		str(resolved_clue.get("title", portal.get("label", "奇遇线索"))),
		exploration_after
	]
	if is_market_clue:
		event_title = "货价落点：%s" % str(portal.get("label", "货价线索"))
		event_description = "你在%s问实%s，区域探索推进到 %d%%。" % [
			region_name,
			str(resolved_clue.get("title", portal.get("label", "货价线索"))),
			exploration_after
		]
	GameState.append_world_event(
		"market" if is_market_clue else "adventure",
		event_title,
		event_description,
		region_id,
		2 if is_market_clue else 3
	)
	reward_parts.append("货价线索已落地" if is_market_clue else "奇遇线索已追到")
	if bool(aftermath.get("start_combat", false)):
		var enemy: Dictionary = aftermath.get("enemy", {})
		if not enemy.is_empty():
			active_enemy_actor = null
			var toast := str(aftermath.get("toast", "奇遇线索惊动了伏兵"))
			if not toast.is_empty():
				EventBus.emit_toast(toast)
			combat_system.start(enemy)
			return
	_show_landmark_discovery(portal, description, reward_parts, false)

func _resolve_market_clue_aftermath(region: Dictionary, clue: Dictionary, portal: Dictionary) -> Dictionary:
	var region_id := str(region.get("id", "region"))
	var region_name := str(region.get("name", region_id))
	var source_region_name := str(clue.get("region_name", "来路"))
	var item_id := _market_clue_item_id_from_clue(str(clue.get("id", "")))
	if item_id.is_empty():
		item_id = str(portal.get("market_item_id", ""))
	var item := GameData.get_item(item_id)
	var item_name := str(item.get("name", item_id if not item_id.is_empty() else "这批货"))
	var delivery_count := _market_delivery_count(portal)
	var delivery_bonus := int(portal.get("delivery_bonus_money", 0))
	var trade_route_plan := GameState.build_trade_route_plan(str(clue.get("region_id", "")), region_id)
	var trade_risk_bonus := int(trade_route_plan.get("trade_risk_bonus", 0))
	var total_trade_bonus := delivery_bonus + trade_risk_bonus
	var delivered := false
	if not item_id.is_empty() and delivery_count > 0 and GameState.remove_item(item_id, delivery_count):
		delivered = true
		if total_trade_bonus > 0:
			GameState.add_money(total_trade_bonus)
	if delivered:
		GameState.record_trade_delivery(
			str(clue.get("region_id", "")),
			region_id,
			item_id,
			delivery_count,
			total_trade_bonus,
			str(clue.get("id", "")),
			trade_route_plan
		)
	var count_text := " x%d" % delivery_count if delivery_count > 1 else ""
	var route_note := str(trade_route_plan.get("trade_risk_note", ""))
	var route_suffix := "\n%s" % route_note if not route_note.is_empty() else ""
	var description := "跑商回响：%s的脚行收下了%s%s，确认%s传来的行情不虚；后续可以在这里扩展为交割、倒卖或黑市压价事件。%s" % [
		region_name,
		item_name,
		count_text,
		source_region_name,
		route_suffix
	]
	GameState.append_world_event(
		"market",
		"%s货价落定" % region_name,
		"你把%s的%s行情追到%s，并交割%s%s，确认两地价差可做文章。%s" % [
			source_region_name,
			item_name,
			region_name,
			item_name,
			count_text,
			route_note
		],
		region_id,
		2
	)
	var delivery_label := "交割%s%s" % [item_name, count_text]
	if total_trade_bonus > 0:
		delivery_label = "%s，赚%d两" % [delivery_label, total_trade_bonus]
	return {
		"kind": "market",
		"description": description,
		"reward_label": delivery_label
	}

func _market_clue_item_id_from_clue(clue_id: String) -> String:
	var item_pos := clue_id.find("item_")
	if item_pos < 0:
		return ""
	return clue_id.substr(item_pos)

func _can_deliver_market_clue(portal: Dictionary, clue_id: String) -> bool:
	var item_id := _market_delivery_item_id(portal, clue_id)
	var count := _market_delivery_count(portal)
	if item_id.is_empty() or count <= 0:
		return true
	return int(GameState.inventory.get(item_id, 0)) >= count

func _market_delivery_missing_description(portal: Dictionary, clue_id: String) -> String:
	var item_id := _market_delivery_item_id(portal, clue_id)
	var count := _market_delivery_count(portal)
	var item := GameData.get_item(item_id)
	var item_name := str(item.get("name", item_id if not item_id.is_empty() else "货物"))
	var target_region_name := str(local_area.current_region.get("name", "此地"))
	var count_text := " x%d" % count if count > 1 else ""
	return "%s的脚行说，光问价还不算交割；带来%s%s，才能把这条货价线索落成一笔跑商买卖。" % [
		target_region_name,
		item_name,
		count_text
	]

func _market_delivery_item_id(portal: Dictionary, clue_id: String) -> String:
	var item_id := str(portal.get("delivery_item_id", ""))
	if item_id.is_empty():
		item_id = str(portal.get("market_item_id", ""))
	if item_id.is_empty():
		item_id = _market_clue_item_id_from_clue(clue_id)
	return item_id

func _market_delivery_count(portal: Dictionary) -> int:
	return maxi(0, int(portal.get("delivery_count", 1)))

func _resolve_adventure_aftermath(region: Dictionary, clue: Dictionary, portal: Dictionary) -> Dictionary:
	var region_id := str(region.get("id", "region"))
	var region_name := str(region.get("name", region_id))
	var region_type := str(region.get("type", "wild"))
	var danger := int(region.get("danger", 1))
	var clue_title := str(clue.get("title", portal.get("label", "奇遇线索")))
	if (region_type == "wild" or danger >= 4) and danger >= ADVENTURE_AMBUSH_MIN_DANGER:
		var enemy: Dictionary = GameData.build_region_encounter_enemy(region)
		if not enemy.is_empty():
			enemy["adventure_encounter"] = true
			GameState.append_world_event(
				"adventure",
				"奇遇伏兵：%s" % region_name,
				"你循着%s追到%s，暗处伏兵被惊动，退路被截住。" % [clue_title, region_name],
				region_id,
				4
			)
			return {
				"kind": "ambush",
				"start_combat": true,
				"enemy": enemy,
				"reward_label": "惊动伏兵",
				"toast": "%s附近有伏兵" % region_name
			}
	if region_type == "city" or region_type == "town":
		var street_description := "奇遇余波：街边茶摊有人补出半句旧话，线索背后还有人情债。"
		GameState.append_world_event(
			"adventure",
			"市井回声：%s" % region_name,
			"你循着%s追到%s，市井口风松动，露出一段旧日人情。" % [clue_title, region_name],
			region_id,
			2
		)
		return {
			"kind": "rumor",
			"description": street_description,
			"reward_label": "市井情报已记"
		}
	if region_type == "sect":
		var sect_description := "奇遇余波：山门弟子认出旧暗记，留下一个可供后续门派事件延展的名字。"
		GameState.append_world_event(
			"adventure",
			"山门旧约：%s" % region_name,
			"你循着%s追到%s，门中旧约被重新提起。" % [clue_title, region_name],
			region_id,
			3
		)
		return {
			"kind": "sect",
			"description": sect_description,
			"reward_label": "山门线索已记"
		}
	var wild_description := "奇遇余波：野路上留有新鲜脚印，像是有人刚刚撤离。"
	GameState.append_world_event(
		"adventure",
		"野路回声：%s" % region_name,
		"你循着%s追到%s，野路脚印尚新，后续仍可接入救援、伏击或隐士相逢。" % [clue_title, region_name],
		region_id,
		2
	)
	return {
		"kind": "wild",
		"description": wild_description,
		"reward_label": "野路踪迹已记"
	}

func _inspect_roadside_event(portal: Dictionary) -> void:
	var region: Dictionary = local_area.current_region
	var region_id := str(region.get("id", "region"))
	var flag_key := "roadside_%s_last_day" % region_id
	var already_seen := int(GameState.game_flags.get(flag_key, 0)) == GameState.day
	if already_seen:
		EventBus.emit_toast("今日已经在此歇过脚，继续赶路吧")
		return
	GameState.game_flags[flag_key] = GameState.day
	GameState.advance_hours(0.5)
	var danger := int(region.get("danger", 1))
	var region_type := str(region.get("type", "wild"))
	if region_type == "wild" and danger >= 3:
		var enemy := GameData.build_region_encounter_enemy(region)
		if not enemy.is_empty():
			active_enemy_actor = null
			EventBus.emit_toast("%s附近有埋伏" % str(region.get("name", "驿亭")))
			combat_system.start(enemy)
			return
	var hp_gain := GameState.heal_player(12 + danger * 2)
	var mp_gain := GameState.restore_mp(10 + danger * 2)
	var rewards: Array[String] = []
	if hp_gain > 0:
		rewards.append("气血 +%d" % hp_gain)
	if mp_gain > 0:
		rewards.append("内力 +%d" % mp_gain)
	_show_landmark_discovery({
		"label": str(portal.get("label", "驿亭")),
	}, "你在%s歇脚半个时辰，顺手向过路人打听了附近动静。" % str(portal.get("label", "驿亭")), rewards, false)

func _show_landmark_discovery(portal: Dictionary, description: String, rewards: Array[String], already_seen: bool) -> void:
	if discovery_panel == null:
		EventBus.emit_toast(description)
		return
	discovery_panel.show_discovery({
		"title": str(portal.get("label", "有所发现")),
		"region": str(local_area.current_region.get("name", "")),
		"description": description,
		"rewards": rewards,
		"already_seen": already_seen
	})

func _close_gameplay_panels() -> void:
	PanelManager.close_all()
