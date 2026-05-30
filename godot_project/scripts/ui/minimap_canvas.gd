extends Control
class_name MinimapCanvas

var marker_target: Texture2D
var redraw_timer := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(256, 186)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_target = GameData.load_texture("res://assets/ui/marker_target.png")
	EventBus.region_changed.connect(func(_region: Dictionary, _state: Dictionary) -> void: queue_redraw())
	EventBus.quests_changed.connect(queue_redraw)
	EventBus.map_target_changed.connect(func(_region_id: String) -> void: queue_redraw())

func _process(delta: float) -> void:
	redraw_timer -= delta
	if redraw_timer <= 0.0:
		redraw_timer = 0.18
		queue_redraw()

func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, Color(0.045, 0.046, 0.038, 0.94), true)
	draw_rect(outer, Color(0.58, 0.46, 0.26, 0.82), false, 1.5)

	var title := _current_title()
	draw_string(get_theme_default_font(), Vector2(10, 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.92, 0.82, 0.58, 0.96))
	draw_string(get_theme_default_font(), Vector2(size.x - 48, 18), "M 舆图", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.68, 0.74, 0.70, 0.82))

	var map_rect := _fit_map_rect(Rect2(Vector2(10, 28), Vector2(size.x - 20, size.y - 40)))
	draw_rect(map_rect, Color(0.065, 0.075, 0.058, 0.95), true)
	draw_rect(map_rect, Color(0.30, 0.27, 0.18, 0.88), false, 1.0)

	for region in GameData.get_regions():
		_draw_region(region, map_rect)
	_draw_target_line(map_rect)
	_draw_quest_targets(map_rect)
	_draw_player_marker(map_rect)
	_draw_status_pips(map_rect)

func _current_title() -> String:
	if GameState.current_region_name.is_empty():
		return "未知之地"
	var exploration := GameState.get_region_exploration(GameState.current_region_id)
	return "%s  %d%%" % [_short_text(GameState.current_region_name, 8), exploration]

func _draw_region(region: Dictionary, map_rect: Rect2) -> void:
	var region_id := str(region.get("id", ""))
	var discovered := GameState.is_region_discovered(region_id)
	var is_current := region_id == GameState.current_region_id
	var is_target := region_id == GameState.map_target_region_id
	var rect := _scaled_rect(region, map_rect)
	var color := _region_color(str(region.get("type", "wild")), int(region.get("danger", 0)))
	if discovered:
		color.a = 0.42
	elif is_current or is_target:
		color.a = 0.30
	else:
		color.a = 0.055
	if str(region.get("type", "wild")) == "wild":
		draw_rect(rect, color, false, 1.0)
	else:
		draw_rect(rect, color, true)
	if discovered:
		draw_rect(rect, Color(color.r, color.g, color.b, 0.42), false, 1.0)
	if is_current:
		draw_rect(rect.grow(1.5), Color(1.0, 0.86, 0.44, 0.95), false, 2.0)
	if is_target:
		draw_rect(rect.grow(2.5), Color(0.46, 0.78, 1.0, 0.82), false, 1.8)

func _draw_target_line(map_rect: Rect2) -> void:
	if GameState.map_target_region_id.is_empty():
		return
	var region := GameData.get_region(GameState.map_target_region_id)
	if region.is_empty():
		return
	var player_pos := _scaled_tile(GameState.current_tile, map_rect)
	var target_pos := _scaled_tile(_region_center_tile(region), map_rect)
	draw_line(player_pos, target_pos, Color(0.50, 0.78, 1.0, 0.42), 1.5)
	_draw_target_marker(target_pos, 13.0, Color(0.62, 0.86, 1.0, 0.94))

func _draw_quest_targets(map_rect: Rect2) -> void:
	for target_name in _active_quest_targets().keys():
		var npc := GameData.get_npc_by_name(str(target_name))
		if npc.is_empty():
			continue
		var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
		var region := GameData.get_region_at_tile(tile)
		if not GameState.is_region_discovered(str(region.get("id", ""))):
			continue
		_draw_target_marker(_scaled_tile(tile, map_rect), 11.0, Color(1.0, 0.72, 0.26, 0.96))

func _draw_player_marker(map_rect: Rect2) -> void:
	var pos := _scaled_tile(GameState.current_tile, map_rect)
	draw_circle(pos, 5.0, Color(1.0, 0.22, 0.18, 0.96))
	draw_arc(pos, 8.5, 0.0, TAU, 28, Color(1.0, 0.92, 0.58, 0.88), 1.8)
	draw_circle(pos, 1.8, Color(1.0, 0.96, 0.82, 0.96))

func _draw_status_pips(map_rect: Rect2) -> void:
	var base := map_rect.position + Vector2(8, map_rect.size.y - 10)
	draw_circle(base, 2.5, Color(1.0, 0.22, 0.18, 0.95))
	draw_string(get_theme_default_font(), base + Vector2(7, 4), "你", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.78, 0.64, 0.88))
	_draw_target_marker(base + Vector2(40, 0), 9.0, Color(1.0, 0.72, 0.26, 0.92))
	draw_string(get_theme_default_font(), base + Vector2(48, 4), "目标", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.78, 0.64, 0.88))
	if not GameState.map_target_region_id.is_empty():
		draw_circle(base + Vector2(94, 0), 3.5, Color(0.50, 0.78, 1.0, 0.90))
		draw_string(get_theme_default_font(), base + Vector2(103, 4), "标记", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.78, 0.64, 0.88))

func _draw_target_marker(pos: Vector2, size_px: float, tint: Color) -> void:
	if marker_target != null:
		var rect := Rect2(pos - Vector2(size_px * 0.5, size_px * 0.5), Vector2(size_px, size_px))
		draw_texture_rect(marker_target, rect, false, tint)
		return
	draw_circle(pos, size_px * 0.33, tint)
	draw_line(pos + Vector2(-size_px * 0.5, 0), pos + Vector2(size_px * 0.5, 0), Color(1.0, 0.90, 0.55, 0.88), 1.2)
	draw_line(pos + Vector2(0, -size_px * 0.5), pos + Vector2(0, size_px * 0.5), Color(1.0, 0.90, 0.55, 0.88), 1.2)

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

func _scaled_tile(tile: Vector2i, map_rect: Rect2) -> Vector2:
	var scale := Vector2(map_rect.size.x / float(GameData.MAP_WIDTH), map_rect.size.y / float(GameData.MAP_HEIGHT))
	return map_rect.position + Vector2((float(tile.x) + 0.5) * scale.x, (float(tile.y) + 0.5) * scale.y)

func _fit_map_rect(available: Rect2) -> Rect2:
	var aspect := float(GameData.MAP_WIDTH) / float(GameData.MAP_HEIGHT)
	var width := available.size.x
	var height := width / aspect
	if height > available.size.y:
		height = available.size.y
		width = height * aspect
	var origin := available.position + Vector2((available.size.x - width) * 0.5, (available.size.y - height) * 0.5)
	return Rect2(origin, Vector2(width, height))

func _scaled_rect(region: Dictionary, map_rect: Rect2) -> Rect2:
	var rect_data: Array = region.get("rect", [0, 0, 1, 1])
	var scale := Vector2(map_rect.size.x / float(GameData.MAP_WIDTH), map_rect.size.y / float(GameData.MAP_HEIGHT))
	return Rect2(
		map_rect.position + Vector2(float(rect_data[0]) * scale.x, float(rect_data[1]) * scale.y),
		Vector2(max(2.0, float(rect_data[2]) * scale.x), max(2.0, float(rect_data[3]) * scale.y))
	)

func _region_center_tile(region: Dictionary) -> Vector2i:
	var center: Array = region.get("center", [])
	if center.size() >= 2:
		return Vector2i(int(center[0]), int(center[1]))
	var rect: Array = region.get("rect", [])
	if rect.size() >= 4:
		return Vector2i(int(rect[0]) + int(rect[2]) / 2, int(rect[1]) + int(rect[3]) / 2)
	return GameState.current_tile

func _region_color(region_type: String, danger: int) -> Color:
	match region_type:
		"city":
			return Color(0.76, 0.56, 0.28)
		"town":
			return Color(0.60, 0.46, 0.28)
		"sect":
			return Color(0.42, 0.62, 0.46)
		_:
			if danger >= 4:
				return Color(0.70, 0.22, 0.18)
			if danger >= 3:
				return Color(0.62, 0.38, 0.18)
			if danger >= 2:
				return Color(0.36, 0.52, 0.30)
			return Color(0.26, 0.48, 0.28)

func _short_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars) + "..."
