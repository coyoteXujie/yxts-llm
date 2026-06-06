extends Control
class_name RegionMapCanvas

signal region_clicked(region_id: String)

var selected_region_id := ""
var route_plan: Dictionary = {}
var marker_npc: Texture2D
var marker_quest: Texture2D
var marker_target: Texture2D

func _ready() -> void:
	custom_minimum_size = Vector2(660, 318)
	mouse_filter = Control.MOUSE_FILTER_STOP
	marker_npc = GameData.load_texture("res://assets/ui/marker_npc.png")
	marker_quest = GameData.load_texture("res://assets/ui/marker_quest.png")
	marker_target = GameData.load_texture("res://assets/ui/marker_target.png")

func set_selected_region(region_id: String) -> void:
	selected_region_id = region_id
	queue_redraw()

func set_route_plan(plan: Dictionary) -> void:
	route_plan = plan.duplicate(true)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var region_id := _region_id_at_point(event.position)
		if region_id.is_empty():
			return
		set_selected_region(region_id)
		region_clicked.emit(region_id)
		accept_event()

func _draw() -> void:
	var canvas := Rect2(Vector2.ZERO, size)
	draw_rect(canvas, Color(0.07, 0.08, 0.065, 0.95), true)
	draw_rect(canvas, Color(0.55, 0.44, 0.25, 0.75), false, 2.0)

	for region in GameData.get_regions():
		_draw_region(region, canvas)

	_draw_route_overlay(canvas)
	_draw_npc_markers(canvas)
	_draw_quest_markers(canvas)
	_draw_player_marker(canvas)
	_draw_legend(canvas)

func _draw_region(region: Dictionary, canvas: Rect2) -> void:
	var region_id := str(region.get("id", ""))
	var rect := _scaled_rect(region, canvas)
	var discovered := GameState.is_region_discovered(region_id)
	var color := _region_color(str(region.get("type", "wild")), int(region.get("danger", 0)))
	color.a = 0.34 if discovered else 0.08
	var outline := color.lightened(0.32)
	outline.a = 0.75 if discovered else 0.18

	var region_type := str(region.get("type", "wild"))
	if region_type == "wild":
		draw_rect(rect, color, false, 1.0)
	else:
		draw_rect(rect, color, true)
		draw_rect(rect, outline, false, 1.5)

	if region_id == selected_region_id:
		draw_rect(rect.grow(2.0), Color(1.0, 0.82, 0.38, 0.95), false, 3.0)

	if discovered and (region_type == "city" or region_type == "sect" or region_type == "town"):
		var name := str(region.get("name", region_id))
		var label_pos := rect.get_center() - Vector2(min(name.length() * 4, 48), 7)
		draw_string(get_theme_default_font(), label_pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.94, 0.84, 0.58, 0.90))

func _draw_player_marker(canvas: Rect2) -> void:
	var scale := Vector2(canvas.size.x / float(GameData.MAP_WIDTH), canvas.size.y / float(GameData.MAP_HEIGHT))
	var pos := Vector2((float(GameState.current_tile.x) + 0.5) * scale.x, (float(GameState.current_tile.y) + 0.5) * scale.y)
	draw_circle(pos, 6.0, Color(1.0, 0.22, 0.18, 0.95))
	draw_arc(pos, 10.0, 0.0, TAU, 28, Color(1.0, 0.88, 0.54, 0.85), 2.0)

func _draw_route_overlay(canvas: Rect2) -> void:
	var route: Array = route_plan.get("route", [])
	if route.size() < 2:
		return
	var points: Array[Vector2] = []
	for region_id_value in route:
		var region_id := str(region_id_value)
		var region := GameData.get_region(region_id)
		if region.is_empty():
			continue
		points.append(_scaled_region_center(region, canvas))
	if points.size() < 2:
		return
	var risk_level := int(route_plan.get("risk_level", 1))
	var route_color := _route_color(risk_level)
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		draw_line(a + Vector2(0, 2), b + Vector2(0, 2), Color(0.02, 0.015, 0.01, 0.64), 7.0, true)
		draw_line(a, b, Color(route_color.r, route_color.g, route_color.b, 0.35), 7.0, true)
		draw_line(a, b, route_color, 3.0, true)
	for index in range(points.size()):
		var radius := 5.0 if index == 0 or index == points.size() - 1 else 3.6
		draw_circle(points[index], radius + 2.0, Color(0.02, 0.015, 0.01, 0.70))
		draw_circle(points[index], radius, route_color)
	var mid_point := points[int(points.size() / 2)]
	var label := "%s %.1f时辰 %d两" % [
		str(route_plan.get("risk_label", "")),
		float(route_plan.get("hours", 0.0)),
		int(route_plan.get("fare", 0))
	]
	draw_string(get_theme_default_font(), mid_point + Vector2(8, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.91, 0.64, 0.95))

func _draw_npc_markers(canvas: Rect2) -> void:
	for npc in GameData.get_npcs():
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		if not _tile_region_discovered(tile):
			continue
		var pos := _scaled_tile(tile, canvas)
		var important := bool(npc.get("has_quests", false)) or bool(npc.get("is_master", false))
		if important:
			_draw_marker_texture(marker_npc, pos, 14.0, Color(1, 1, 1, 0.92))
		else:
			draw_circle(pos, 2.3, Color(0.82, 0.78, 0.62, 0.58))

func _draw_quest_markers(canvas: Rect2) -> void:
	var active_targets := _active_quest_targets()
	for target_name in active_targets.keys():
		var npc := GameData.get_npc_by_name(str(target_name))
		if npc.is_empty():
			continue
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		if not _tile_region_discovered(tile):
			continue
		_draw_marker_texture(marker_target, _scaled_tile(tile, canvas), 18.0, Color(1, 1, 1, 0.96))

	for quest in GameData.get_available_quests():
		var giver := str(quest.get("giver", ""))
		if giver.is_empty() or GameState.completed_quests.has(str(quest.get("id", ""))) or GameState.active_quests.has(str(quest.get("id", ""))):
			continue
		var npc := GameData.get_npc_by_name(giver)
		if npc.is_empty():
			continue
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		if not _tile_region_discovered(tile):
			continue
		var pos := _scaled_tile(tile, canvas)
		_draw_marker_texture(marker_quest, pos + Vector2(4, -4), 16.0, Color(1, 1, 1, 0.94))

func _active_quest_targets() -> Dictionary:
	var result := {}
	for quest_id in GameState.active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		var progress: Dictionary = GameState.active_quests[quest_id].get("progress", {})
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			var kind := str(objective.get("type", ""))
			if kind != "talk" and kind != "kill":
				continue
			var target := str(objective.get("target", ""))
			var key := "%s:%s" % [kind, target]
			if int(progress.get(key, 0)) >= int(objective.get("count", 1)):
				continue
			result[target] = true
	return result

func _draw_marker_star(pos: Vector2, color: Color) -> void:
	draw_circle(pos, 5.0, color)
	draw_line(pos + Vector2(-7, 0), pos + Vector2(7, 0), Color(1.0, 0.90, 0.55, 0.88), 1.5)
	draw_line(pos + Vector2(0, -7), pos + Vector2(0, 7), Color(1.0, 0.90, 0.55, 0.88), 1.5)

func _draw_marker_texture(texture: Texture2D, pos: Vector2, size_px: float, tint: Color) -> void:
	if texture == null:
		_draw_marker_star(pos, tint)
		return
	var rect := Rect2(pos - Vector2(size_px * 0.5, size_px * 0.5), Vector2(size_px, size_px))
	draw_texture_rect(texture, rect, false, tint)

func _draw_legend(canvas: Rect2) -> void:
	var base := Vector2(canvas.size.x - 168, canvas.size.y - 22)
	_draw_marker_texture(marker_npc, base, 13.0, Color(1, 1, 1, 0.86))
	draw_string(get_theme_default_font(), base + Vector2(8, 4), "NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.86, 0.80, 0.66))
	_draw_marker_texture(marker_target, base + Vector2(48, 0), 16.0, Color(1, 1, 1, 0.96))
	draw_string(get_theme_default_font(), base + Vector2(58, 4), "任务目标", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.86, 0.80, 0.66))
	_draw_marker_texture(marker_quest, base + Vector2(120, 0), 15.0, Color(1, 1, 1, 0.94))
	draw_string(get_theme_default_font(), base + Vector2(130, 4), "可接", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.86, 0.80, 0.66))

func _scaled_tile(tile: Vector2i, canvas: Rect2) -> Vector2:
	var scale := Vector2(canvas.size.x / float(GameData.MAP_WIDTH), canvas.size.y / float(GameData.MAP_HEIGHT))
	return Vector2((float(tile.x) + 0.5) * scale.x, (float(tile.y) + 0.5) * scale.y)

func _region_id_at_point(point: Vector2) -> String:
	if size.x <= 0.0 or size.y <= 0.0:
		return ""
	var tile := Vector2i(
		clampi(floori(point.x / size.x * float(GameData.MAP_WIDTH)), 0, GameData.MAP_WIDTH - 1),
		clampi(floori(point.y / size.y * float(GameData.MAP_HEIGHT)), 0, GameData.MAP_HEIGHT - 1)
	)
	var region := GameData.get_region_at_tile(tile)
	return str(region.get("id", ""))

func _tile_region_discovered(tile: Vector2i) -> bool:
	var region := GameData.get_region_at_tile(tile)
	if region.is_empty():
		return false
	return GameState.is_region_discovered(str(region.get("id", "")))

func _scaled_rect(region: Dictionary, canvas: Rect2) -> Rect2:
	var rect_data: Array = region.get("rect", [0, 0, 1, 1])
	var scale := Vector2(canvas.size.x / float(GameData.MAP_WIDTH), canvas.size.y / float(GameData.MAP_HEIGHT))
	return Rect2(
		Vector2(float(rect_data[0]) * scale.x, float(rect_data[1]) * scale.y),
		Vector2(max(2.0, float(rect_data[2]) * scale.x), max(2.0, float(rect_data[3]) * scale.y))
	)

func _scaled_region_center(region: Dictionary, canvas: Rect2) -> Vector2:
	return _scaled_rect(region, canvas).get_center()

func _route_color(risk_level: int) -> Color:
	if risk_level >= 5:
		return Color(0.95, 0.20, 0.16, 0.96)
	if risk_level >= 4:
		return Color(0.95, 0.44, 0.18, 0.96)
	if risk_level >= 3:
		return Color(0.92, 0.67, 0.24, 0.96)
	if risk_level >= 2:
		return Color(0.72, 0.80, 0.42, 0.94)
	return Color(0.50, 0.78, 0.48, 0.92)

func _region_color(region_type: String, danger: int) -> Color:
	match region_type:
		"city":
			return Color(0.72, 0.54, 0.30)
		"town":
			return Color(0.58, 0.48, 0.30)
		"sect":
			return Color(0.48, 0.62, 0.45)
		_:
			if danger >= 4:
				return Color(0.58, 0.24, 0.20)
			if danger >= 3:
				return Color(0.54, 0.36, 0.22)
			if danger >= 2:
				return Color(0.36, 0.48, 0.28)
			return Color(0.25, 0.42, 0.24)
