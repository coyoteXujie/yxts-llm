extends Node
class_name MapTransitionManager
## 地图转场管理：提取自 main.gd 的所有地图切换、镜头缩放、过渡动画逻辑
##
## 职责：
##   - 世界地图 ↔ 局部区域（城市/门派）的互相切换
##   - 商铺内景的进入/退出
##   - 区域间旅行（linked region 传送）
##   - 镜头缩放与平滑切换
##   - 水墨转场动画（Fade + Shader + Zoom punch）
##   - 存档时的地图上下文恢复
##
## 通信方式：通过直接操作 main.gd 传入的节点引用，同时通过 EventBus 发送通知信号。

signal transition_started()
signal transition_completed()

## --- 外部引用（由 main.gd 在初始化时设置）---
var world_map: Node
var local_area: Node
var player_actor: Node
var camera: Camera2D
var transition_overlay: ColorRect

## --- 常量 ---
const WORLD_CAMERA_ZOOM := Vector2(0.92, 0.92)
const LOCAL_CAMERA_ZOOM := Vector2(0.98, 0.98)
const WORLD_CAMERA_SMOOTHING_SPEED := 10.0
const LOCAL_CAMERA_SMOOTHING_ENABLED := false
const LOCAL_CAMERA_SMOOTHING_SPEED := 28.0
const POST_TRANSITION_RESET_DELAY := 1.2
const MAP_TRANSITION_FADE_SECONDS := 0.42
const MAP_TRANSITION_ZOOM_PUNCH := 1.035
const NEW_GAME_START_REGION_ID := "qinghe"
const ENTERABLE_REGION_TYPES := {
	"city": true,
	"town": true,
	"sect": true,
	"wild": true
}

## --- 状态 ---
var world_return_position := Vector2.ZERO

func initialize(p_world_map: Node, p_local_area: Node, p_player: Node, p_camera: Camera2D) -> void:
	world_map = p_world_map
	local_area = p_local_area
	player_actor = p_player
	camera = p_camera
	_setup_transition_overlay()

func _setup_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.name = "MapTransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.size = Vector2(1920, 1080)
	transition_overlay.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ink_transition.gdshader")
	mat.set_shader_parameter("progress", 1.0)
	transition_overlay.material = mat
	transition_overlay.hide()
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 8
	add_child(canvas_layer)
	canvas_layer.add_child(transition_overlay)

## 相机边界更新
func update_camera_limits(active_map: Node) -> void:
	if active_map == null or camera == null:
		return
	var rect: Rect2 = active_map.get_world_rect()
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)

## 应用镜头缩放策略
func apply_camera_zoom(active_map: Node) -> void:
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

## 清除地图节点的叠加状态
static func clear_map_node_state(map_node: Node) -> void:
	if map_node == null:
		return
	if map_node.has_method("clear_highlights"):
		map_node.clear_highlights()
	if map_node.has_method("clear_ambient_lines"):
		map_node.clear_ambient_lines()

## 切换玩家到目标地图（核心转场方法）
func transition_player_to_map(target_map: Node, position: Vector2, update_player_position: bool = false) -> void:
	transition_started.emit()
	player_actor.world_map = target_map
	player_actor.position = position
	player_actor.velocity = Vector2.ZERO
	player_actor.reset_physics_interpolation()
	if update_player_position:
		GameState.player_position = position
	apply_camera_zoom(target_map)
	if camera != null:
		camera.reset_smoothing()
	_play_map_transition_feedback()
	transition_completed.emit()

## 执行水墨转场动画
func _play_map_transition_feedback() -> void:
	if transition_overlay != null:
		transition_overlay.show()
		var mat := transition_overlay.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("progress", 0.85)
	var existing := get_tree().get_first_node_in_group("map_transition_tween")
	if existing != null and existing.has_method("is_valid") and existing.is_valid():
		existing.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	if transition_overlay != null:
		var mat := transition_overlay.material as ShaderMaterial
		if mat != null:
			tween.tween_method(func(v): mat.set_shader_parameter("progress", v), 0.85, 0.0, MAP_TRANSITION_FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.chain().tween_callback(func() -> void:
			if transition_overlay != null:
				transition_overlay.hide()
		)
	if camera != null:
		var target_zoom := camera.zoom
		camera.zoom = target_zoom * MAP_TRANSITION_ZOOM_PUNCH
		tween.tween_property(camera, "zoom", target_zoom, MAP_TRANSITION_FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## 从世界地图进入局部区域
func enter_local_region(region: Dictionary) -> void:
	world_return_position = player_actor.position
	world_map.hide()
	local_area.setup_region(region)
	local_area.show()
	transition_player_to_map(local_area, local_area.get_entry_position("world"))
	EventBus.emit_toast("进入%s" % str(region.get("name", "区域")))

## 从局部区域返回世界地图
func switch_to_world_map(position: Vector2) -> void:
	if local_area != null:
		local_area.hide()
		clear_map_node_state(local_area)
	if world_map != null:
		world_map.show()
	world_return_position = position
	transition_player_to_map(world_map, position, true)

## 从局部区域返回世界地图（保留已有 world_return_position）
func return_to_world() -> void:
	switch_to_world_map(world_return_position)

## 进入商铺内景
func enter_shop(portal: Dictionary) -> void:
	local_area.enter_shop(portal)
	transition_player_to_map(local_area, local_area.get_entry_position("shop"))

## 从商铺退出到街上
func exit_shop_to_area() -> void:
	transition_player_to_map(local_area, local_area.exit_shop())
	EventBus.emit_toast("回到街上")

## 通过传送门旅行到关联区域
func travel_to_linked_region(portal: Dictionary) -> void:
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
	transition_player_to_map(local_area, local_area.get_entry_position(str(portal.get("entry_kind", "area"))))
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

## 从存档快照恢复地图状态
func restore_loaded_map(snapshot: Dictionary) -> bool:
	var raw_context = snapshot.get("map_context", {})
	if typeof(raw_context) != TYPE_DICTIONARY:
		return false
	var context: Dictionary = raw_context
	if str(context.get("map", "world")) != "local":
		return false
	var region_id := str(context.get("region_id", ""))
	var region := GameData.get_region(region_id)
	if region.is_empty() or not _can_enter_region_type(region):
		return false
	world_return_position = _vector_from_save(context.get("world_position", {}), GameState.player_position)
	world_map.hide()
	local_area.setup_region(region)
	var mode := str(context.get("mode", "region"))
	if mode == "shop":
		var shop_id := str(context.get("shop_id", ""))
		if not shop_id.is_empty():
			var return_tile := _tile_from_save(context.get("shop_return_tile", {}), local_area.world_to_tile(local_area.get_entry_position("world")))
			local_area.enter_shop({
				"shop_id": shop_id,
				"tile": [return_tile.x, return_tile.y]
			})
	local_area.show()
	var fallback_kind := "shop" if local_area.current_mode == "shop" else "world"
	var local_position := _vector_from_save(context.get("local_position", {}), local_area.get_entry_position(fallback_kind))
	if not local_area.is_position_walkable(local_position):
		local_position = local_area.get_entry_position(fallback_kind)
	transition_player_to_map(local_area, local_position)
	return true

## 新游戏是否在城镇内开始
func try_enter_new_game_start_region() -> bool:
	var region := GameData.get_region(NEW_GAME_START_REGION_ID)
	if region.is_empty() or not _can_enter_region_type(region):
		return false
	world_return_position = world_map.get_region_entry_position(NEW_GAME_START_REGION_ID)
	world_map.hide()
	local_area.setup_region(region)
	local_area.show()
	transition_player_to_map(local_area, local_area.get_entry_position("world"))
	return true

## -- 存档辅助 --
func current_world_save_position(active_map: Node) -> Vector2:
	if active_map == world_map:
		return player_actor.position
	return world_return_position

func build_save_context(active_map: Node) -> Dictionary:
	var world_position := current_world_save_position(active_map)
	var context := {
		"map": "world",
		"world_position": _vector_to_save(world_position),
		"location_label": GameState.current_region_name
	}
	if active_map != local_area:
		return context
	var region_id := str(local_area.current_region.get("id", GameState.current_region_id))
	var region_name := str(local_area.current_region.get("name", GameState.current_region_name))
	var mode := str(local_area.current_mode)
	var mode_label := "商铺" if mode == "shop" else "街区"
	context["map"] = "local"
	context["region_id"] = region_id
	context["mode"] = mode
	context["local_position"] = _vector_to_save(player_actor.position)
	context["world_position"] = _vector_to_save(world_return_position)
	context["location_label"] = "%s · %s" % [region_name, mode_label]
	if mode == "shop":
		context["shop_id"] = str(local_area.active_shop_id)
		context["shop_return_tile"] = {
			"x": local_area.shop_return_tile.x,
			"y": local_area.shop_return_tile.y
		}
	return context

func _can_enter_region_type(region: Dictionary) -> bool:
	var region_type := str(region.get("type", ""))
	return ENTERABLE_REGION_TYPES.get(region_type, false)

static func _vector_to_save(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

static func _vector_from_save(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("x", fallback.x)), float(data.get("y", fallback.y)))

static func _tile_from_save(value: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = value
	return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))
