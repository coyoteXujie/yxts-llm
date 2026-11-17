extends Node2D
## 主控制脚本 — 协调游戏生命周期、UI 面板和系统模块

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const DIALOGUE_PANEL_SCRIPT := preload("res://scripts/ui/dialogue_panel.gd")
const COMBAT_PANEL_SCRIPT := preload("res://scripts/ui/combat_panel.gd")
const ATMOSPHERE_LAYER_SCRIPT := preload("res://scripts/ui/atmosphere_layer.gd")
const INK_WASH_POSTFX_SCRIPT := preload("res://scripts/ui/ink_wash_postfx.gd")
const WEATHER_OVERLAY_SCRIPT := preload("res://scripts/ui/weather_overlay.gd")
const OPENING_NARRATIVE_SCRIPT := preload("res://scripts/ui/opening_narrative_panel.gd")
const ENDING_CREDITS_SCRIPT := preload("res://scripts/ui/ending_credits_panel.gd")
const INK_SPLASH_SCRIPT := preload("res://scripts/ui/ink_splash_overlay.gd")
const INK_TRANSITION_SHADER := preload("res://shaders/ink_transition.gdshader")
const MAIN_MENU_SCRIPT := preload("res://scripts/ui/main_menu_panel.gd")
const CHARACTER_CREATION_SCRIPT := preload("res://scripts/ui/character_creation_panel.gd")
const INVENTORY_PANEL_SCRIPT := preload("res://scripts/ui/inventory_panel.gd")
const QUEST_PANEL_SCRIPT := preload("res://scripts/ui/quest_panel.gd")
const SHOP_PANEL_SCRIPT := preload("res://scripts/ui/shop_panel.gd")
const CULTIVATION_PANEL_SCRIPT := preload("res://scripts/ui/cultivation_panel.gd")
const FORGE_PANEL_SCRIPT := preload("res://scripts/ui/forge_panel.gd")
const WORLD_MAP_PANEL_SCRIPT := preload("res://scripts/ui/world_map_panel.gd")
const DISCOVERY_PANEL_SCRIPT := preload("res://scripts/ui/discovery_panel.gd")
const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")
const MAP_TRANSITION_MANAGER := preload("res://scripts/systems/map_transition_manager.gd")
const INTERACTION_MANAGER := preload("res://scripts/systems/interaction_manager.gd")

const NEW_GAME_STARTS_IN_LOCAL_TOWN := true

var world_map: Node
var local_area: Node
var active_map: Node
var player_actor: Node
var camera: Camera2D
var hud: Node
var dialogue_panel: Node
var combat_panel: Node
var combat_system: Node
var atmosphere_layer: Node
var main_menu_panel: Node
var character_creation_panel: Node
var inventory_panel: Node
var quest_panel: Node
var shop_panel: Node
var cultivation_panel: Node
var forge_panel: Node
var world_map_panel: Node
var discovery_panel: Node
var opening_narrative: Node
var ui_layer: CanvasLayer

var map_transition_mgr
var interaction_mgr

var game_started := false

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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player_actor.add_child(camera)
	camera.make_current()

	combat_system = COMBAT_SYSTEM_SCRIPT.new()
	add_child(combat_system)
	combat_system.combat_finished.connect(_on_combat_finished)

	_setup_layers_and_panels()

	# 初始化系统模块
	map_transition_mgr = MAP_TRANSITION_MANAGER.new()
	add_child(map_transition_mgr)
	map_transition_mgr.initialize(world_map, local_area, player_actor, camera)

	interaction_mgr = INTERACTION_MANAGER.new()
	add_child(interaction_mgr)
	interaction_mgr.setup_references(world_map, local_area, player_actor, hud,
		dialogue_panel, shop_panel, combat_panel, discovery_panel,
		combat_system, map_transition_mgr)

	# 信号连接
	AudioManager.play_bgm("main_menu")
	EventBus.mode_changed.connect(_on_mode_changed_bgm)
	EventBus.dialogue_requested.connect(_open_dialogue)
	EventBus.combat_requested.connect(_start_combat_from_data)
	EventBus.shop_requested.connect(_open_shop)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.map_target_changed.connect(_on_map_target_changed)
	main_menu_panel.new_game_requested.connect(_open_character_creation)
	main_menu_panel.continue_requested.connect(_continue_game)
	main_menu_panel.resume_requested.connect(_resume_from_menu)
	main_menu_panel.save_requested.connect(_save_from_menu)
	character_creation_panel.character_created.connect(_start_new_game)
	world_map_panel.focus_region_requested.connect(_mark_region_target)
	world_map_panel.fast_travel_requested.connect(_fast_travel_to_region)
	world_map_panel.clear_target_requested.connect(_clear_region_target)
	opening_narrative.narrative_finished.connect(_on_narrative_finished)

	# 墨滴开场动画 → 主菜单
	var ink_splash := INK_SPLASH_SCRIPT.new()
	ui_layer.add_child(ink_splash)
	ink_splash.splash_finished.connect(func():
		main_menu_panel.show_menu(false)
	)
	ink_splash.start_splash()

	# 水墨后处理（最顶层）
	var postfx_layer := CanvasLayer.new()
	postfx_layer.layer = 10
	add_child(postfx_layer)
	var ink_wash := INK_WASH_POSTFX_SCRIPT.new()
	postfx_layer.add_child(ink_wash)
	ink_wash.name = "InkWashPostFX"

func _setup_layers_and_panels() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 3
	add_child(ui_layer)

	var atm_layer_node := CanvasLayer.new()
	atm_layer_node.layer = 1
	add_child(atm_layer_node)
	atmosphere_layer = ATMOSPHERE_LAYER_SCRIPT.new()
	atm_layer_node.add_child(atmosphere_layer)

	var weather_layer_node := CanvasLayer.new()
	weather_layer_node.layer = 2
	add_child(weather_layer_node)
	var weather_overlay := WEATHER_OVERLAY_SCRIPT.new()
	weather_layer_node.add_child(weather_overlay)
	atmosphere_layer.weather_overlay = weather_overlay

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
	forge_panel = FORGE_PANEL_SCRIPT.new()
	ui_layer.add_child(forge_panel)
	world_map_panel = WORLD_MAP_PANEL_SCRIPT.new()
	ui_layer.add_child(world_map_panel)
	discovery_panel = DISCOVERY_PANEL_SCRIPT.new()
	ui_layer.add_child(discovery_panel)
	character_creation_panel = CHARACTER_CREATION_SCRIPT.new()
	ui_layer.add_child(character_creation_panel)
	main_menu_panel = MAIN_MENU_SCRIPT.new()
	ui_layer.add_child(main_menu_panel)
	opening_narrative = OPENING_NARRATIVE_SCRIPT.new()
	ui_layer.add_child(opening_narrative)

func _process(delta: float) -> void:
	GameState.advance_time(delta)
	player_actor.movement_enabled = GameState.can_explore()
	map_transition_mgr.update_camera_limits(active_map)

	if GameState.can_explore() and not interaction_mgr.pending_quest_summaries.is_empty():
		interaction_mgr.try_show_pending_quest_summary()

	if not GameState.can_explore():
		interaction_mgr.clear_explore_state()
		return

	interaction_mgr.update_explore_context(active_map)
	interaction_mgr.update_ambient_npc_lines(delta, active_map)
	interaction_mgr.update_explore_prompt(active_map)
	interaction_mgr.handle_explore_actions()

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
		interaction_mgr.handle_enter_area(active_map)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_save"):
		_save_current_game()
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
		GameState.Mode.FORGE:
			forge_panel.close_panel()
		GameState.Mode.MAP:
			world_map_panel.close_panel()
		GameState.Mode.DISCOVERY:
			discovery_panel.close_panel()
		GameState.Mode.COMBAT:
			if combat_panel != null and combat_panel.has_method("is_result_visible") and combat_panel.is_result_visible():
				combat_panel.close_result_panel()
			else:
				EventBus.emit_toast("战斗中无法打开菜单")
		GameState.Mode.MENU:
			if game_started:
				_resume_from_menu()
			else:
				main_menu_panel.show_menu(false)
		GameState.Mode.EXPLORE:
			main_menu_panel.show_menu(true)
		_:
			_close_gameplay_panels()
			GameState.set_mode(GameState.Mode.EXPLORE)

func _open_character_creation() -> void:
	character_creation_panel.show_panel()

func _continue_game() -> void:
	if not GameState.load_game():
		main_menu_panel.show_menu(game_started)

func _resume_from_menu() -> void:
	if not game_started:
		main_menu_panel.show_menu(false)
		return
	main_menu_panel.hide()
	_close_gameplay_panels()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_mode_changed_bgm(next_mode: GameState.Mode) -> void:
	match next_mode:
		GameState.Mode.MENU:
			AudioManager.play_bgm("main_menu")
		GameState.Mode.COMBAT:
			AudioManager.play_bgm("combat")
		GameState.Mode.EXPLORE:
			AudioManager.play_bgm("explore", 0.5)

func _on_narrative_finished() -> void:
	main_menu_panel.hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _save_from_menu() -> void:
	if not game_started:
		return
	if _save_current_game():
		main_menu_panel.refresh_menu_state()

func _start_new_game(config: Dictionary) -> void:
	game_started = true
	GameState.new_game(config)
	opening_narrative.show_panel(str(config.get("name", "少侠")))
	world_map.reset_npcs()
	world_map.set_target_region(GameState.map_target_region_id)
	var started_in_town := false
	if NEW_GAME_STARTS_IN_LOCAL_TOWN:
		started_in_town = map_transition_mgr.try_enter_new_game_start_region()
	if not started_in_town:
		map_transition_mgr.switch_to_world_map(GameState.player_position)
	_update_current_region()
	_close_gameplay_panels()
	EventBus.emit_toast("新的江湖开始")

func _close_gameplay_panels() -> void:
	dialogue_panel.hide()
	combat_panel.hide()
	inventory_panel.hide()
	quest_panel.hide()
	shop_panel.hide()
	cultivation_panel.hide()
	forge_panel.hide()
	world_map_panel.hide()
	discovery_panel.hide()

func _open_dialogue(npc: Dictionary) -> void:
	interaction_mgr.clear_explore_state()
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

func _clear_region_target() -> void:
	if GameState.map_target_region_id.is_empty():
		EventBus.emit_toast("当前没有地图目的地")
		return
	GameState.set_map_target_region("")
	world_map.set_target_region("")
	EventBus.emit_toast("已清除地图目的地")

func _fast_travel_to_region(region_id: String) -> void:
	interaction_mgr.fast_travel_to_region(region_id, active_map)

func _start_combat_from_data(enemy: Dictionary) -> void:
	interaction_mgr.clear_explore_state()
	combat_system.start(enemy)

func _on_game_loaded(_snapshot: Dictionary) -> void:
	game_started = true
	interaction_mgr.pending_quest_summaries.clear()
	world_map.reset_npcs()
	world_map.apply_defeated_enemies()
	world_map.set_target_region(GameState.map_target_region_id)
	if not map_transition_mgr.restore_loaded_map(_snapshot):
		map_transition_mgr.switch_to_world_map(GameState.player_position)
	_update_current_region()
	_close_gameplay_panels()
	main_menu_panel.hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_map_target_changed(region_id: String) -> void:
	if world_map != null:
		world_map.set_target_region(region_id)

func _on_combat_finished(result: Dictionary) -> void:
	var enemy_actor: Node = interaction_mgr.active_enemy_actor
	if bool(result.get("victory", false)) and enemy_actor != null and is_instance_valid(enemy_actor):
		GameState.mark_enemy_defeated(int(enemy_actor.data.get("id", -1)))
		if active_map != null and active_map.has_method("unregister_npc"):
			active_map.unregister_npc(enemy_actor)
		enemy_actor.queue_free()
	interaction_mgr.active_enemy_actor = null

func _on_quest_completed(summary: Dictionary) -> void:
	interaction_mgr.pending_quest_summaries.append(summary.duplicate(true))
	call_deferred("_try_deferred_quest_pending")

func _try_deferred_quest_pending() -> void:
	if GameState.can_explore():
		interaction_mgr.try_show_pending_quest_summary()

func _on_game_ending(epilogue: String) -> void:
	var credits := ENDING_CREDITS_SCRIPT.new()
	ui_layer.add_child(credits)
	credits.show_credits(epilogue)

func _update_current_region() -> void:
	var tile: Vector2i = active_map.world_to_tile(player_actor.position)
	var region: Dictionary = active_map.get_region_at_world_position(player_actor.position)
	if active_map == local_area and local_area.has_method("get_world_reference_tile"):
		tile = local_area.get_world_reference_tile(player_actor.position)
	GameState.update_current_region(region, tile)

func _save_current_game() -> bool:
	var save_pos := map_transition_mgr.current_world_save_position(active_map)
	var save_ctx := map_transition_mgr.build_save_context(active_map)
	return GameState.save_game(save_pos, save_ctx)

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
