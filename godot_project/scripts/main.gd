extends Node2D

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
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
const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")

var world_map
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
var combat_system
var focused_npc
var active_enemy_actor

func _ready() -> void:
	randomize()
	_register_inputs()

	world_map = WORLD_MAP_SCRIPT.new()
	add_child(world_map)

	player_actor = PLAYER_SCRIPT.new()
	player_actor.world_map = world_map
	player_actor.position = GameState.player_position
	add_child(player_actor)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(1.08, 1.08)
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
		world_map.clear_highlights()
		hud.set_prompt("")
		return

	_update_current_region()

	focused_npc = world_map.get_nearest_npc(player_actor.position, 92.0, true)
	world_map.focus_actor(focused_npc)

	if focused_npc == null:
		hud.set_prompt("B 背包  J 任务  K 修炼  M 地图  F5/F9 存读档  Esc 菜单")
		return

	if focused_npc.is_enemy():
		hud.set_prompt("F 挑战 %s    T 观察" % str(focused_npc.data.get("name", "敌人")))
	else:
		hud.set_prompt("T 与 %s 交谈" % str(focused_npc.data.get("name", "NPC")))

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
	elif event.is_action_pressed("quick_save"):
		GameState.save_game(player_actor.position)
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
	player_actor.position = GameState.player_position
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
	world_map_panel.hide()

func _open_dialogue(npc: Dictionary) -> void:
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
	var reason := GameState.get_fast_travel_block_reason(region_id)
	if not reason.is_empty():
		EventBus.emit_toast(reason)
		return
	var destination: Vector2 = world_map.get_region_entry_position(region_id)
	if not world_map.is_position_walkable(destination):
		EventBus.emit_toast("目的地入口暂不可通行")
		return
	var travel_hours := GameState.apply_fast_travel_time(region_id)
	if travel_hours < 0.0:
		return
	player_actor.position = destination
	player_actor.velocity = Vector2.ZERO
	GameState.player_position = destination
	GameState.set_map_target_region("")
	world_map.set_target_region("")
	_update_current_region()
	_close_gameplay_panels()
	GameState.set_mode(GameState.Mode.EXPLORE)
	if camera != null:
		camera.reset_smoothing()
	EventBus.emit_toast("抵达%s，用时 %.1f 时辰" % [str(region.get("name", region_id)), travel_hours])

func _start_combat_from_data(enemy: Dictionary) -> void:
	active_enemy_actor = focused_npc
	combat_system.start(enemy)

func _on_game_loaded(_snapshot: Dictionary) -> void:
	player_actor.position = GameState.player_position
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
		world_map.unregister_npc(active_enemy_actor)
		active_enemy_actor.queue_free()
	active_enemy_actor = null

func _update_camera_limits() -> void:
	var rect: Rect2 = world_map.get_world_rect()
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)

func _update_current_region() -> void:
	var tile: Vector2i = world_map.world_to_tile(player_actor.position)
	var region: Dictionary = world_map.get_region_at_world_position(player_actor.position)
	GameState.update_current_region(region, tile)

func _register_inputs() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_T, KEY_ENTER])
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
