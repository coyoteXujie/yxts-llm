extends Node2D

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const DIALOGUE_PANEL_SCRIPT := preload("res://scripts/ui/dialogue_panel.gd")
const COMBAT_PANEL_SCRIPT := preload("res://scripts/ui/combat_panel.gd")
const ATMOSPHERE_LAYER_SCRIPT := preload("res://scripts/ui/atmosphere_layer.gd")
const MAIN_MENU_SCRIPT := preload("res://scripts/ui/main_menu_panel.gd")
const CHARACTER_CREATION_SCRIPT := preload("res://scripts/ui/character_creation_panel.gd")
const INVENTORY_PANEL_SCRIPT := preload("res://scripts/ui/inventory_panel.gd")
const QUEST_PANEL_SCRIPT := preload("res://scripts/ui/quest_panel.gd")
const SHOP_PANEL_SCRIPT := preload("res://scripts/ui/shop_panel.gd")
const CULTIVATION_PANEL_SCRIPT := preload("res://scripts/ui/cultivation_panel.gd")
const WORLD_MAP_PANEL_SCRIPT := preload("res://scripts/ui/world_map_panel.gd")
const DISCOVERY_PANEL_SCRIPT := preload("res://scripts/ui/discovery_panel.gd")
const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")

const WORLD_CAMERA_ZOOM := Vector2(0.92, 0.92)
const LOCAL_CAMERA_ZOOM := Vector2(0.98, 0.98)
const WORLD_CAMERA_SMOOTHING_SPEED := 10.0
const LOCAL_CAMERA_SMOOTHING_ENABLED := false
const LOCAL_CAMERA_SMOOTHING_SPEED := 28.0
const NEW_GAME_STARTS_IN_LOCAL_TOWN := true
const NEW_GAME_START_REGION_ID := "qinghe"
const AMBIENT_NPC_INTERVAL := 6.8
const AMBIENT_NPC_RADIUS := 430.0
const POST_TRANSITION_RESET_DELAY := 1.2
const LANDMARK_EXPLORATION_GAIN := 8
const RESOURCE_EXPLORATION_GAIN := 3
const HIDDEN_CLUE_EXPLORATION_GAIN := 5
const ENTERABLE_REGION_TYPES := {
	"city": true,
	"town": true,
	"sect": true,
	"wild": true
}

var world_map
var local_area
var active_map
var player_actor
var camera: Camera2D
var hud
var dialogue_panel
var combat_panel
var atmosphere_layer
var main_menu_panel
var character_creation_panel
var inventory_panel
var quest_panel
var shop_panel
var cultivation_panel
var world_map_panel
var discovery_panel
var combat_system
var focused_npc
var focused_portal: Dictionary = {}
var active_enemy_actor
var world_return_position := Vector2.ZERO
var ambient_npc_timer := 2.0
var ambient_npc_round := 0

func _ready() -> void:
	randomize()
	_register_inputs()

	world_map = WORLD_MAP_SCRIPT.new()
	add_child(world_map)
	local_area = LOCAL_AREA_SCRIPT.new()
	local_area.hide()
	add_child(local_area)
	active_map = world_map

	player_actor = PLAYER_SCRIPT.new()
	player_actor.world_map = active_map
	player_actor.position = GameState.player_position
	add_child(player_actor)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = WORLD_CAMERA_SMOOTHING_SPEED
	camera.zoom = WORLD_CAMERA_ZOOM
	player_actor.add_child(camera)
	camera.make_current()

	combat_system = COMBAT_SYSTEM_SCRIPT.new()
	add_child(combat_system)
	combat_system.combat_finished.connect(_on_combat_finished)

	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)

	atmosphere_layer = ATMOSPHERE_LAYER_SCRIPT.new()
	ui_layer.add_child(atmosphere_layer)
	hud = HUD_SCRIPT.new()
	ui_layer.add_child(hud)
	dialogue_panel = DIALOGUE_PANEL_SCRIPT.new()
	ui_layer.add_child(dialogue_panel)
	combat_panel = COMBAT_PANEL_SCRIPT.new()
	ui_layer.add_child(combat_panel)
	combat_panel.set_combat_system(combat_system)
	inventory_panel = INVENTORY_PANEL_SCRIPT.new()
	ui_layer.add_child(inventory_panel)
	quest_panel = QUEST_PANEL_SCRIPT.new()
	ui_layer.add_child(quest_panel)
	shop_panel = SHOP_PANEL_SCRIPT.new()
	ui_layer.add_child(shop_panel)
	cultivation_panel = CULTIVATION_PANEL_SCRIPT.new()
	ui_layer.add_child(cultivation_panel)
	world_map_panel = WORLD_MAP_PANEL_SCRIPT.new()
	ui_layer.add_child(world_map_panel)
	world_map_panel.focus_region_requested.connect(_mark_region_target)
	world_map_panel.fast_travel_requested.connect(_fast_travel_to_region)
	discovery_panel = DISCOVERY_PANEL_SCRIPT.new()
	ui_layer.add_child(discovery_panel)
	character_creation_panel = CHARACTER_CREATION_SCRIPT.new()
	ui_layer.add_child(character_creation_panel)
	main_menu_panel = MAIN_MENU_SCRIPT.new()
	ui_layer.add_child(main_menu_panel)

	EventBus.dialogue_requested.connect(_open_dialogue)
	EventBus.combat_requested.connect(_start_combat_from_data)
	EventBus.shop_requested.connect(_open_shop)
	EventBus.game_loaded.connect(_on_game_loaded)
	main_menu_panel.new_game_requested.connect(_open_character_creation)
	main_menu_panel.continue_requested.connect(_continue_game)
	character_creation_panel.character_created.connect(_start_new_game)

	main_menu_panel.show_menu()

func _process(delta: float) -> void:
	GameState.advance_time(delta)
	player_actor.movement_enabled = GameState.can_explore()
	_update_camera_limits()

	if not GameState.can_explore():
		_clear_explore_state()
		return

	_update_explore_context()
	_update_ambient_npc_lines(delta)
	_update_explore_prompt()
	_handle_explore_actions()

func _clear_explore_state() -> void:
	_clear_map_explore_state()
	hud.set_prompt("")

func _clear_map_explore_state() -> void:
	if active_map == null:
		return
	if active_map.has_method("clear_highlights"):
		active_map.clear_highlights()
	if active_map.has_method("clear_ambient_lines"):
		active_map.clear_ambient_lines()

func _update_explore_context() -> void:
	_update_current_region()
	focused_npc = active_map.get_nearest_npc(player_actor.position, 92.0, true)
	active_map.focus_actor(focused_npc)
	focused_portal = {}
	if active_map.has_method("get_nearest_portal"):
		focused_portal = active_map.get_nearest_portal(player_actor.position, 80.0)
		active_map.focus_portal(focused_portal)

func _update_explore_prompt() -> void:
	if focused_npc == null:
		if not focused_portal.is_empty():
			hud.set_prompt("E %s    B 背包  J 任务  K 修炼  M 地图" % _portal_prompt(focused_portal))
		else:
			var region := _current_region_for_entry()
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

func _handle_explore_actions() -> void:
	if focused_npc == null:
		return
	if Input.is_action_just_pressed("interact"):
		_open_dialogue(focused_npc.data)
	if focused_npc.is_enemy() and Input.is_action_just_pressed("attack"):
		active_enemy_actor = focused_npc
		combat_system.start(focused_npc.data)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return

	if not GameState.can_explore():
		return

	if event.is_action_pressed("inventory"):
		_close_gameplay_panels()
		inventory_panel.show_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		_close_gameplay_panels()
		quest_panel.show_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cultivation"):
		_close_gameplay_panels()
		cultivation_panel.show_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("world_map"):
		_close_gameplay_panels()
		world_map_panel.show_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("enter_area"):
		_handle_enter_area()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_save"):
		GameState.save_game(_current_world_save_position())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_load"):
		GameState.load_game()
		get_viewport().set_input_as_handled()

func _handle_cancel() -> void:
	match GameState.mode:
		GameState.Mode.DIALOGUE:
			dialogue_panel.close_panel()
		GameState.Mode.INVENTORY:
			inventory_panel.close_panel()
		GameState.Mode.JOURNAL:
			quest_panel.close_panel()
		GameState.Mode.SHOP:
			shop_panel.close_panel()
		GameState.Mode.CULTIVATION:
			cultivation_panel.close_panel()
		GameState.Mode.MAP:
			world_map_panel.close_panel()
		GameState.Mode.DISCOVERY:
			discovery_panel.close_panel()
		GameState.Mode.MENU:
			main_menu_panel.hide()
			GameState.set_mode(GameState.Mode.EXPLORE)
		GameState.Mode.EXPLORE:
			main_menu_panel.show_menu()
		_:
			_close_gameplay_panels()
			GameState.set_mode(GameState.Mode.EXPLORE)

func _open_character_creation() -> void:
	character_creation_panel.show_panel()

func _continue_game() -> void:
	GameState.load_game()

func _start_new_game(config: Dictionary) -> void:
	GameState.new_game(config)
	world_map.reset_npcs()
	world_map.set_target_region(GameState.map_target_region_id)
	var started_in_town := false
	if NEW_GAME_STARTS_IN_LOCAL_TOWN:
		started_in_town = _enter_new_game_start_region()
	if not started_in_town:
		_switch_to_world_map(GameState.player_position)
		_update_current_region()
	_close_gameplay_panels()
	EventBus.emit_toast("新的江湖开始")

func _enter_new_game_start_region() -> bool:
	var region := GameData.get_region(NEW_GAME_START_REGION_ID)
	if region.is_empty() or not _can_enter_region(region):
		return false
	world_return_position = world_map.get_region_entry_position(NEW_GAME_START_REGION_ID)
	world_map.hide()
	local_area.setup_region(region)
	local_area.show()
	_transition_player_to_map(local_area, local_area.get_entry_position("world"))
	_update_current_region()
	return true

func _close_gameplay_panels() -> void:
	dialogue_panel.hide()
	combat_panel.hide()
	inventory_panel.hide()
	quest_panel.hide()
	shop_panel.hide()
	cultivation_panel.hide()
	world_map_panel.hide()
	discovery_panel.hide()

func _open_dialogue(npc: Dictionary) -> void:
	_clear_map_explore_state()
	GameState.progress_quest("talk", str(npc.get("name", "")), 1)
	GameState.set_mode(GameState.Mode.DIALOGUE)
	dialogue_panel.show_npc(npc)

func _open_shop(npc: Dictionary) -> void:
	_close_gameplay_panels()
	shop_panel.show_shop(npc)

func _mark_region_target(region_id: String) -> void:
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return
	GameState.set_map_target_region(region_id)
	world_map.set_target_region(region_id)
	world_map_panel.close_panel()
	EventBus.emit_toast("已标记目的地：%s" % str(region.get("name", region_id)))

func _fast_travel_to_region(region_id: String) -> void:
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return
	if active_map != world_map:
		_switch_to_world_map(world_return_position)
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
	_transition_player_to_map(world_map, destination, true)
	GameState.set_map_target_region("")
	world_map.set_target_region("")
	_update_current_region()
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

func _start_combat_from_data(enemy: Dictionary) -> void:
	_clear_map_explore_state()
	active_enemy_actor = focused_npc
	combat_system.start(enemy)

func _on_game_loaded(_snapshot: Dictionary) -> void:
	_switch_to_world_map(GameState.player_position)
	world_map.reset_npcs()
	world_map.apply_defeated_enemies()
	world_map.set_target_region(GameState.map_target_region_id)
	_update_current_region()
	_close_gameplay_panels()
	main_menu_panel.hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_combat_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)) and active_enemy_actor != null and is_instance_valid(active_enemy_actor):
		GameState.mark_enemy_defeated(int(active_enemy_actor.data.get("id", -1)))
		if active_map != null and active_map.has_method("unregister_npc"):
			active_map.unregister_npc(active_enemy_actor)
		active_enemy_actor.queue_free()
	active_enemy_actor = null

func _update_camera_limits() -> void:
	if active_map == null or camera == null:
		return
	var rect: Rect2 = active_map.get_world_rect()
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)

func _update_current_region() -> void:
	var tile: Vector2i = active_map.world_to_tile(player_actor.position)
	var region: Dictionary = active_map.get_region_at_world_position(player_actor.position)
	if active_map == local_area and local_area.has_method("get_world_reference_tile"):
		tile = local_area.get_world_reference_tile(player_actor.position)
	GameState.update_current_region(region, tile)

func _update_ambient_npc_lines(delta: float) -> void:
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

func _current_region_for_entry() -> Dictionary:
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
	if portal_type == "landmark" or portal_type == "resource" or portal_type == "hidden_clue":
		var action := str(portal.get("action_label", "查看"))
		var hint := str(portal.get("interaction_hint", ""))
		if not hint.is_empty():
			return "%s%s（%s）" % [action, str(portal.get("label", "入口")), hint]
		return "%s%s" % [action, str(portal.get("label", "入口"))]
	return str(portal.get("label", "入口"))

func _handle_enter_area() -> void:
	if active_map == world_map:
		var region := _current_region_for_entry()
		if region.is_empty():
			EventBus.emit_toast("这里还不是可进入的区域")
			return
		if not _can_enter_region(region):
			EventBus.emit_toast("这片区域暂未开放内景")
			return
		_enter_local_region(region)
		return
	if focused_portal.is_empty():
		EventBus.emit_toast("附近没有可进入的入口")
		return
	var portal_type := str(focused_portal.get("type", ""))
	match portal_type:
		"exit_world":
			_return_to_world()
		"shop":
			_enter_shop(focused_portal)
		"exit_area":
			_exit_shop_to_area()
		"travel_region":
			_travel_to_linked_region(focused_portal)
		"landmark":
			_inspect_landmark(focused_portal)
		"resource":
			_inspect_resource(focused_portal)
		"hidden_clue":
			_inspect_hidden_clue(focused_portal)
		"look":
			_inspect_roadside_event(focused_portal)
		_:
			EventBus.emit_toast("入口还没有接入")

func _can_enter_region(region: Dictionary) -> bool:
	var region_type := str(region.get("type", ""))
	return ENTERABLE_REGION_TYPES.get(region_type, false)

func _enter_local_region(region: Dictionary) -> void:
	world_return_position = player_actor.position
	world_map.hide()
	local_area.setup_region(region)
	local_area.show()
	_transition_player_to_map(local_area, local_area.get_entry_position("world"))
	_update_current_region()
	EventBus.emit_toast("进入%s" % str(region.get("name", "区域")))

func _enter_shop(portal: Dictionary) -> void:
	local_area.enter_shop(portal)
	_transition_player_to_map(local_area, local_area.get_entry_position("shop"))
	EventBus.emit_toast(str(portal.get("label", "进入商铺")))

func _exit_shop_to_area() -> void:
	_transition_player_to_map(local_area, local_area.exit_shop())
	EventBus.emit_toast("回到街上")

func _return_to_world() -> void:
	_switch_to_world_map(world_return_position)
	_update_current_region()
	EventBus.emit_toast("返回世界地图")

func _travel_to_linked_region(portal: Dictionary) -> void:
	var target_id := str(portal.get("target_region_id", ""))
	var target_region := GameData.get_region(target_id)
	if target_region.is_empty():
		EventBus.emit_toast("这条路暂时走不通")
		return
	var source_name := str(local_area.current_region.get("name", GameState.current_region_name)) if local_area != null else GameState.current_region_name
	var travel_hours := float(portal.get("travel_hours", 0.0))
	var risk_label := str(portal.get("risk_label", ""))
	if travel_hours > 0.0:
		GameState.advance_hours(travel_hours)
	world_return_position = world_map.get_region_entry_position(target_id)
	local_area.setup_region(target_region)
	local_area.show()
	_transition_player_to_map(local_area, local_area.get_entry_position(str(portal.get("entry_kind", "area"))))
	_update_current_region()
	if travel_hours > 0.0:
		GameState.append_world_event(
			"travel",
			"山路抵达%s" % str(target_region.get("name", target_id)),
			"你从%s沿%s赶到%s，用去%.1f时辰，路况%s。" % [
				source_name,
				str(portal.get("direction_label", "道路")),
				str(target_region.get("name", target_id)),
				travel_hours,
				risk_label if not risk_label.is_empty() else "平稳"
			],
			target_id,
			clampi(int(portal.get("risk_level", 1)), 1, 3)
		)
	EventBus.emit_toast("抵达%s%s" % [str(target_region.get("name", target_id)), " · %.1f时辰" % travel_hours if travel_hours > 0.0 else ""])

func _inspect_landmark(portal: Dictionary) -> void:
	var region_id := str(local_area.current_region.get("id", "region"))
	var portal_id := str(portal.get("id", "landmark"))
	var flag_key := "landmark_%s_%s" % [region_id, portal_id]
	var description := str(portal.get("description", "这里暂时没有更多线索。"))
	var already_seen := bool(GameState.game_flags.get(flag_key, false))
	var reward_parts: Array[String] = []
	var item_id := str(portal.get("reward_item", ""))
	var reward_money := int(portal.get("reward_money", 0))
	var reward_exp := int(portal.get("reward_exp", 0))
	if bool(GameState.game_flags.get(flag_key, false)):
		_show_landmark_discovery(portal, description, [], true)
		return
	GameState.game_flags[flag_key] = true
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
	_show_landmark_discovery(portal, description, reward_parts, false)

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

func _switch_to_world_map(position: Vector2) -> void:
	if local_area != null:
		local_area.hide()
		_clear_map_node_state(local_area)
	if world_map != null:
		world_map.show()
	world_return_position = position
	_transition_player_to_map(world_map, position, true)

func _clear_map_node_state(map_node: Node) -> void:
	if map_node == null:
		return
	if map_node.has_method("clear_highlights"):
		map_node.clear_highlights()
	if map_node.has_method("clear_ambient_lines"):
		map_node.clear_ambient_lines()

func _transition_player_to_map(target_map: Node, position: Vector2, update_player_position: bool = false) -> void:
	_clear_map_explore_state()
	active_map = target_map
	player_actor.world_map = target_map
	player_actor.position = position
	player_actor.velocity = Vector2.ZERO
	if update_player_position:
		GameState.player_position = position
	focused_portal = {}
	ambient_npc_timer = POST_TRANSITION_RESET_DELAY
	_apply_camera_zoom()
	if camera != null:
		camera.reset_smoothing()

func _current_world_save_position() -> Vector2:
	if active_map == world_map:
		return player_actor.position
	return world_return_position

func _apply_camera_zoom() -> void:
	if camera == null:
		return
	if active_map == world_map:
		camera.zoom = WORLD_CAMERA_ZOOM
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = WORLD_CAMERA_SMOOTHING_SPEED
	else:
		camera.zoom = LOCAL_CAMERA_ZOOM
		camera.position_smoothing_enabled = LOCAL_CAMERA_SMOOTHING_ENABLED
		camera.position_smoothing_speed = LOCAL_CAMERA_SMOOTHING_SPEED

func _register_inputs() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_T, KEY_ENTER])
	_add_key_action("enter_area", [KEY_E])
	_add_key_action("attack", [KEY_F])
	_add_key_action("inventory", [KEY_B])
	_add_key_action("journal", [KEY_J])
	_add_key_action("cultivation", [KEY_K])
	_add_key_action("world_map", [KEY_M])
	_add_key_action("quick_save", [KEY_F5])
	_add_key_action("quick_load", [KEY_F9])
	_add_key_action("ui_cancel", [KEY_ESCAPE])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var already_exists := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == key:
				already_exists = true
				break
		if already_exists:
			continue
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action_name, key_event)
