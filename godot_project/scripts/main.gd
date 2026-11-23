extends Node2D
## 主控制脚本 — 模块加载器
## 职责仅限：游戏对象创建、系统/面板注册、输入路由、生命周期桥接

const HUD_ALPHA_OPEN := 0.30
const HUD_ALPHA_CLOSED := 1.0

var _onboarding_shown: Dictionary = {}

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")
const INTERACTION_SCRIPT := preload("res://scripts/systems/interaction_manager.gd")
const MAP_TRANSITION_SCRIPT := preload("res://scripts/systems/map_transition_manager.gd")
const SECT_SYSTEM_SCRIPT := preload("res://scripts/systems/sect_system.gd")
const ACHIEVEMENT_SYSTEM_SCRIPT := preload("res://scripts/systems/achievement_system.gd")
const PET_SYSTEM_SCRIPT := preload("res://scripts/systems/pet_system.gd")
const INK_SPLASH_SCRIPT := preload("res://scripts/ui/ink_splash_overlay.gd")
const LIGHTING_MANAGER_SCRIPT := preload("res://scripts/systems/lighting_manager.gd")

const NEW_GAME_STARTS_IN_LOCAL_TOWN := true

var world_map: Node
var local_area: Node
var active_map: Node
var player_actor: Node
var camera: Camera2D
var game_started := false
var atmosphere_layer: Node

func _ready() -> void:
	randomize()
	_register_inputs()

	# ── 1. 游戏世界对象 ──
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

	# ── 2. UI 层级与面板注册 ──
	_setup_ui_layers()

	# ── 3. 系统注册（SystemManager） ──
	var combat_sys := COMBAT_SYSTEM_SCRIPT.new()
	add_child(combat_sys)
	SystemManager.register_system("combat", combat_sys)

	var sect_sys := SECT_SYSTEM_SCRIPT.new()
	sect_sys.name = "SectSystem"
	add_child(sect_sys)
	SystemManager.register_system("sect", sect_sys)

	var ach_sys := ACHIEVEMENT_SYSTEM_SCRIPT.new()
	ach_sys.name = "AchievementSystem"
	add_child(ach_sys)
	SystemManager.register_system("achievement", ach_sys)

	var pet_sys := PET_SYSTEM_SCRIPT.new()
	pet_sys.name = "PetSystem"
	add_child(pet_sys)
	SystemManager.register_system("pet", pet_sys)

	SystemManager.register_system("interaction", INTERACTION_SCRIPT.new())
	SystemManager.register_system("map_transition", MAP_TRANSITION_SCRIPT.new())

	var lighting_manager := LIGHTING_MANAGER_SCRIPT.new()
	add_child(lighting_manager)
	SystemManager.register_system("lighting", lighting_manager)

	SystemManager.init_all()

	# 桥接：为 InteractionManager 注入运行时节点引用
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction != null and interaction.has_method("setup_references"):
		interaction.call("setup_references", world_map, local_area, player_actor, _hud_node(),
			PanelManager.get_panel("dialogue"), PanelManager.get_panel("shop"),
			PanelManager.get_panel("combat"), PanelManager.get_panel("discovery"),
			combat_sys, SystemManager.get_system("map_transition"))

	var map_transition: Node = SystemManager.get_system("map_transition")
	if map_transition != null and map_transition.has_method("initialize"):
		map_transition.call("initialize", world_map, local_area, player_actor, camera)

	# 向 AtmosphereLayer 传递 lighting_manager 引用
	if atmosphere_layer != null and atmosphere_layer.has_method("set_lighting_manager"):
		atmosphere_layer.call("set_lighting_manager", lighting_manager)

	# ── 4. 信号连接 ──
	combat_sys.combat_finished.connect(_on_combat_finished)
	AudioManager.play_bgm("main_menu")
	EventBus.mode_changed.connect(_on_mode_changed_bgm)
	EventBus.mode_changed.connect(_on_mode_changed_hud)
	PanelManager.panel_opened.connect(_on_panel_opened_onboarding)
	EventBus.dialogue_requested.connect(func(npc): PanelManager.open_panel("dialogue", {"npc": npc}))
	EventBus.combat_requested.connect(_start_combat_from_data)
	EventBus.shop_requested.connect(func(npc): PanelManager.open_panel("shop", {"npc": npc}))
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.map_target_changed.connect(_on_map_target_changed)

	# ── 5. 墨滴开场 → 主菜单 ──
	var ink_splash := INK_SPLASH_SCRIPT.new()
	var ui_layer: Node = _ui_layer_node()
	ui_layer.add_child(ink_splash)
	ink_splash.splash_finished.connect(func():
		PanelManager.open_panel("main_menu", {"show_saved": false})
	)
	ink_splash.start_splash()

func _process(delta: float) -> void:
	GameState.advance_time(delta)
	player_actor.movement_enabled = GameState.can_explore()
	_update_camera_limits()
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction == null:
		return
	# pending_quest_summaries check
	if interaction.get("pending_quest_summaries") != null:
		var summaries: Array = interaction.get("pending_quest_summaries")
		if summaries != null and not summaries.is_empty() and GameState.can_explore():
			interaction.call("try_show_pending_quest_summary")
	if not GameState.can_explore():
		if interaction.has_method("clear_explore_state"):
			interaction.call("clear_explore_state")
		return
	if interaction.has_method("update_explore_context"):
		interaction.call("update_explore_context", active_map)
	if interaction.has_method("update_ambient_npc_lines"):
		interaction.call("update_ambient_npc_lines", delta, active_map)
	if interaction.has_method("update_explore_prompt"):
		interaction.call("update_explore_prompt", active_map)
	if interaction.has_method("handle_explore_actions"):
		interaction.call("handle_explore_actions")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	if not GameState.can_explore():
		return
	var action_panels := {
		"inventory": "inventory", "journal": "quest", "cultivation": "cultivation",
		"world_map": "world_map", "sect": "sect", "achievement": "achievement", "pet": "pet"
	}
	for action in action_panels:
		if event.is_action_pressed(action):
			PanelManager.close_all()
			PanelManager.open_panel(action_panels[action])
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("enter_area"):
		var interaction: Node = SystemManager.get_system("interaction")
		if interaction != null and interaction.has_method("handle_enter_area"):
			interaction.call("handle_enter_area", active_map)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_save"):
		_save_current_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_load"):
		GameState.load_game()
		get_viewport().set_input_as_handled()

func _handle_cancel() -> void:
	if GameState.mode == GameState.Mode.COMBAT:
		var combat_panel: Node = PanelManager.get_panel("combat")
		if combat_panel != null and combat_panel.has_method("is_result_visible") and combat_panel.call("is_result_visible"):
			combat_panel.call("close_result_panel")
		else:
			EventBus.emit_toast("战斗中无法打开菜单")
	elif GameState.mode == GameState.Mode.MENU:
		if game_started:
			_resume_from_menu()
		else:
			PanelManager.open_panel("main_menu", {"show_saved": false})
	elif GameState.mode == GameState.Mode.EXPLORE:
		PanelManager.open_panel("main_menu", {"show_saved": true})
	else:
		PanelManager.close_top_panel()

func _start_new_game(config: Dictionary) -> void:
	game_started = true
	GameState.new_game(config)
	var player_name: String = str(config.get("name", "少侠"))
	PanelManager.open_panel("narrative", {"player_name": player_name})
	world_map.call("reset_npcs")
	world_map.call("set_target_region", GameState.map_target_region_id)
	var map_transition: Node = SystemManager.get_system("map_transition")
	var started_in_town := false
	if NEW_GAME_STARTS_IN_LOCAL_TOWN and map_transition != null and map_transition.has_method("try_enter_new_game_start_region"):
		started_in_town = map_transition.call("try_enter_new_game_start_region")
	if not started_in_town and map_transition != null and map_transition.has_method("switch_to_world_map"):
		map_transition.call("switch_to_world_map", GameState.player_position)
	_update_current_region()
	PanelManager.close_all()
	EventBus.emit_toast("新的江湖开始")

func _resume_from_menu() -> void:
	if not game_started:
		PanelManager.open_panel("main_menu", {"show_saved": false})
		return
	PanelManager.close_all()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_combat_finished(result: Dictionary) -> void:
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction == null:
		return
	var enemy_actor: Node = interaction.get("active_enemy_actor") as Node
	if bool(result.get("victory", false)) and enemy_actor != null and is_instance_valid(enemy_actor):
		var enemy_data: Dictionary = enemy_actor.get("data") if enemy_actor.get("data") != null else {}
		var enemy_id: int = int(enemy_data.get("id", -1))
		GameState.mark_enemy_defeated(enemy_id)
		if active_map != null and active_map.has_method("unregister_npc"):
			active_map.call("unregister_npc", enemy_actor)
		enemy_actor.queue_free()
	interaction.set("active_enemy_actor", null)

func _on_quest_completed(summary: Dictionary) -> void:
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction != null:
		var summaries: Array = interaction.get("pending_quest_summaries")
		if summaries != null:
			summaries.append(summary.duplicate(true))
	call_deferred("_try_deferred_quest_pending")

func _try_deferred_quest_pending() -> void:
	if GameState.can_explore():
		var interaction: Node = SystemManager.get_system("interaction")
		if interaction != null and interaction.has_method("try_show_pending_quest_summary"):
			interaction.call("try_show_pending_quest_summary")

func _start_combat_from_data(enemy: Dictionary) -> void:
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction != null and interaction.has_method("clear_explore_state"):
		interaction.call("clear_explore_state")
	var combat_sys: Node = SystemManager.get_system("combat")
	if combat_sys != null and combat_sys.has_method("start"):
		combat_sys.call("start", enemy)

func _on_game_loaded(_snapshot: Dictionary) -> void:
	game_started = true
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction != null:
		var summaries: Array = interaction.get("pending_quest_summaries")
		if summaries != null:
			summaries.clear()
	world_map.call("reset_npcs")
	world_map.call("apply_defeated_enemies")
	world_map.call("set_target_region", GameState.map_target_region_id)
	var map_transition: Node = SystemManager.get_system("map_transition")
	if map_transition != null and map_transition.has_method("restore_loaded_map"):
		if not map_transition.call("restore_loaded_map", _snapshot) and map_transition.has_method("switch_to_world_map"):
			map_transition.call("switch_to_world_map", GameState.player_position)
	_update_current_region()
	PanelManager.close_all()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_mode_changed_bgm(next_mode: int) -> void:
	match next_mode:
		GameState.Mode.MENU:
			AudioManager.play_bgm("main_menu")
		GameState.Mode.COMBAT:
			AudioManager.play_bgm("combat")
		GameState.Mode.EXPLORE:
			AudioManager.play_bgm("explore", 0.5)

## HUD 透明度：面板打开时半透明
func _on_mode_changed_hud(next_mode: int) -> void:
	var hud_node: Node = _hud_node()
	if hud_node == null:
		return
	# 判断当前模式是否需要半透明HUD
	var overlay_modes := [
		GameState.Mode.INVENTORY, GameState.Mode.JOURNAL, GameState.Mode.SHOP,
		GameState.Mode.CULTIVATION, GameState.Mode.FORGE, GameState.Mode.MAP,
		GameState.Mode.SECT, GameState.Mode.ACHIEVEMENT, GameState.Mode.PET,
		GameState.Mode.DIALOGUE, GameState.Mode.COMBAT, GameState.Mode.MENU
	]
	var mode_is_overlay := overlay_modes.has(next_mode)
	var target := HUD_ALPHA_OPEN if mode_is_overlay else HUD_ALPHA_CLOSED
	var tween := hud_node.create_tween()
	tween.tween_property(hud_node, "modulate:a", target, 0.15).set_ease(Tween.EASE_OUT)

## 新手引导：首次打开面板时弹出工具提示
func _on_panel_opened_onboarding(panel_name: String) -> void:
	if _onboarding_shown.has(panel_name):
		return
	_onboarding_shown[panel_name] = true
	var hints := {
		"inventory": "按 B 打开背包 · 使用或丢弃物品 · 装备带属性的武器/防具",
		"quest": "按 J 打开任务 · 追踪目标 · 查看探索记录和传闻",
		"cultivation": "按 K 打开修炼 · 消耗潜能提升修为",
		"world_map": "按 M 打开地图 · 点击区域标记目的地或快速旅行",
		"sect": "按 U 打开门派 · 查看贡献与门派任务",
		"achievement": "按 Y 打开图鉴 · 查看成就与收集进度",
		"pet": "按 P 打开灵宠 · 出战、喂食与升级",
		"forge": "铁匠铺锻造装备 · 收集材料打造神兵",
	}
	var hint: String = hints.get(panel_name, "")
	if not hint.is_empty():
		EventBus.emit_toast("💡 " + hint)

func _on_map_target_changed(region_id: String) -> void:
	if world_map != null:
		world_map.call("set_target_region", region_id)

func _update_current_region() -> void:
	var tile: Vector2i = active_map.world_to_tile(player_actor.position)
	var region: Dictionary = active_map.get_region_at_world_position(player_actor.position)
	if active_map == local_area and local_area.has_method("get_world_reference_tile"):
		tile = local_area.call("get_world_reference_tile", player_actor.position)
	GameState.update_current_region(region, tile)

func _save_current_game() -> bool:
	var map_transition: Node = SystemManager.get_system("map_transition")
	if map_transition == null or not map_transition.has_method("current_world_save_position"):
		return false
	var save_pos: Vector2 = map_transition.call("current_world_save_position", active_map)
	if map_transition.has_method("build_save_context"):
		var save_ctx: Dictionary = map_transition.call("build_save_context", active_map)
		return GameState.save_game(save_pos, save_ctx)
	return GameState.save_game(save_pos, {})

func _update_camera_limits() -> void:
	var map_transition: Node = SystemManager.get_system("map_transition")
	if map_transition != null and map_transition.has_method("update_camera_limits"):
		map_transition.call("update_camera_limits", active_map)

# ── UI 层级与面板注册 ──

func _setup_ui_layers() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 3
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	var atm_layer_node := CanvasLayer.new()
	atm_layer_node.layer = 1
	add_child(atm_layer_node)
	var AtmosphereLayer := preload("res://scripts/ui/atmosphere_layer.gd")
	var atmosphere_layer := AtmosphereLayer.new()
	atm_layer_node.add_child(atmosphere_layer)
	self.atmosphere_layer = atmosphere_layer

	var weather_layer_node := CanvasLayer.new()
	weather_layer_node.layer = 2
	add_child(weather_layer_node)
	var WeatherOverlay := preload("res://scripts/ui/weather_overlay.gd")
	var weather_overlay := WeatherOverlay.new()
	weather_layer_node.add_child(weather_overlay)
	atmosphere_layer.weather_overlay = weather_overlay

	# 注册所有面板
	var panel_defs := {
		"hud": HUD_SCRIPT.new(),
		"dialogue": preload("res://scripts/ui/dialogue_panel.gd").new(),
		"combat": preload("res://scripts/ui/combat_panel.gd").new(),
		"inventory": preload("res://scripts/ui/inventory_panel.gd").new(),
		"quest": preload("res://scripts/ui/quest_panel.gd").new(),
		"shop": preload("res://scripts/ui/shop_panel.gd").new(),
		"cultivation": preload("res://scripts/ui/cultivation_panel.gd").new(),
		"forge": preload("res://scripts/ui/forge_panel.gd").new(),
		"world_map": preload("res://scripts/ui/world_map_panel.gd").new(),
		"discovery": preload("res://scripts/ui/discovery_panel.gd").new(),
		"character_creation": preload("res://scripts/ui/character_creation_panel.gd").new(),
		"main_menu": preload("res://scripts/ui/main_menu_panel.gd").new(),
		"narrative": preload("res://scripts/ui/opening_narrative_panel.gd").new(),
		"sect": preload("res://scripts/ui/sect_panel.gd").new(),
		"achievement": preload("res://scripts/ui/achievement_panel.gd").new(),
		"pet": preload("res://scripts/ui/pet_panel.gd").new()
	}
	for panel_name in panel_defs:
		var panel: Node = panel_defs[panel_name] as Node
		ui_layer.add_child(panel)
		PanelManager.register_panel(panel_name, panel)

	# 战斗面板需要额外引用
	var combat_panel: Node = PanelManager.get_panel("combat")
	var combat_sys: Node = SystemManager.get_system("combat")
	if combat_panel != null and combat_panel.has_method("set_combat_system") and combat_sys != null:
		combat_panel.call("set_combat_system", combat_sys)

	# 面板信号连接
	var main_menu: Node = PanelManager.get_panel("main_menu")
	main_menu.new_game_requested.connect(func(): PanelManager.open_panel("character_creation"))
	main_menu.continue_requested.connect(_on_continue_game)
	main_menu.resume_requested.connect(_resume_from_menu)
	main_menu.save_requested.connect(_on_save_from_menu)

	var char_create: Node = PanelManager.get_panel("character_creation")
	char_create.character_created.connect(_start_new_game)

	var world_map_panel: Node = PanelManager.get_panel("world_map")
	world_map_panel.focus_region_requested.connect(_on_focus_region)
	world_map_panel.fast_travel_requested.connect(_on_fast_travel)
	world_map_panel.clear_target_requested.connect(_on_clear_target)

	var narrative_panel: Node = PanelManager.get_panel("narrative")
	narrative_panel.narrative_finished.connect(_on_narrative_finished)

func _on_continue_game() -> void:
	if not GameState.load_game():
		PanelManager.open_panel("main_menu", {"show_saved": game_started})

func _on_save_from_menu() -> void:
	if not game_started:
		return
	if _save_current_game():
		var main_menu: Node = PanelManager.get_panel("main_menu")
		if main_menu != null and main_menu.has_method("refresh_menu_state"):
			main_menu.call("refresh_menu_state")

func _on_narrative_finished() -> void:
	var main_menu: Node = PanelManager.get_panel("main_menu")
	if main_menu != null:
		main_menu.hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _on_focus_region(region_id: String) -> void:
	var region: Dictionary = GameData.get_region(region_id)
	if region.is_empty():
		return
	GameState.set_map_target_region(region_id)
	world_map.call("set_target_region", region_id)
	PanelManager.close_all()
	EventBus.emit_toast("已标记目的地：%s" % str(region.get("name", region_id)))

func _on_clear_target() -> void:
	if GameState.map_target_region_id.is_empty():
		EventBus.emit_toast("当前没有地图目的地")
		return
	GameState.set_map_target_region("")
	world_map.call("set_target_region", "")
	EventBus.emit_toast("已清除地图目的地")

func _on_fast_travel(region_id: String) -> void:
	var interaction: Node = SystemManager.get_system("interaction")
	if interaction != null and interaction.has_method("fast_travel_to_region"):
		interaction.call("fast_travel_to_region", region_id, active_map)

# ── 辅助 ──

func _hud_node() -> Node:
	return PanelManager.get_panel("hud")

func _ui_layer_node() -> Node:
	for child in get_children():
		if child is CanvasLayer and child.name == "UILayer":
			return child
	return null

# ── 输入注册 ──

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
	_add_key_action("sect", [KEY_U])
	_add_key_action("achievement", [KEY_Y])
	_add_key_action("pet", [KEY_P])

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
