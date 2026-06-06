extends Node2D
class_name LocalStagePostFx

const LIGHT_SHAFT_COUNT := 6
const LANE_FOCUS_ALPHA := 0.16
const AERIAL_HAZE_ALPHA := 0.18
const EDGE_VIGNETTE_ALPHA := 0.22

var current_region: Dictionary = {}
var map_size := Vector2.ZERO
var tile_size := 48
var visual_phase := 0.0

func setup_region(region: Dictionary, new_map_size: Vector2, new_tile_size: int) -> void:
	current_region = region.duplicate(true)
	map_size = new_map_size
	tile_size = new_tile_size
	queue_redraw()

func set_visual_phase(value: float) -> void:
	visual_phase = value
	queue_redraw()

func _draw() -> void:
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return
	var terrain := str(current_region.get("terrain", ""))
	var region_type := str(current_region.get("type", "wild"))
	var accent := _accent_color(region_type, terrain)
	_draw_aerial_haze(accent, terrain)
	_draw_focus_lane(accent)
	_draw_light_shafts(accent, region_type, terrain)
	_draw_depth_edges(accent, terrain)
	_draw_near_ground_haze(accent, terrain)

func _draw_aerial_haze(accent: Color, terrain: String) -> void:
	var haze := Color(accent.r, accent.g, accent.b, AERIAL_HAZE_ALPHA)
	if terrain.contains("snow"):
		haze = Color(0.78, 0.92, 1.0, AERIAL_HAZE_ALPHA + 0.04)
	elif terrain.contains("desert"):
		haze = Color(0.94, 0.72, 0.42, AERIAL_HAZE_ALPHA + 0.02)
	var horizon := map_size.y * 0.47
	_draw_vertical_gradient(Rect2(Vector2.ZERO, Vector2(map_size.x, horizon)), Color(haze.r, haze.g, haze.b, haze.a), Color(haze.r, haze.g, haze.b, haze.a * 0.18))
	_draw_vertical_gradient(Rect2(Vector2(0.0, horizon * 0.74), Vector2(map_size.x, map_size.y * 0.25)), Color(1.0, 0.96, 0.82, 0.055), Color(1.0, 0.96, 0.82, 0.0))

func _draw_focus_lane(accent: Color) -> void:
	var top_y := map_size.y * 0.51
	var bottom_y := map_size.y * 0.96
	var focus := PackedVector2Array([
		Vector2(map_size.x * 0.17, top_y),
		Vector2(map_size.x * 0.83, top_y - tile_size * 0.10),
		Vector2(map_size.x * 0.97, bottom_y),
		Vector2(map_size.x * 0.03, bottom_y)
	])
	draw_polygon(focus, PackedColorArray([
		Color(1.0, 0.92, 0.68, LANE_FOCUS_ALPHA * 0.38),
		Color(accent.r, accent.g, accent.b, LANE_FOCUS_ALPHA * 0.34),
		Color(0.0, 0.0, 0.0, LANE_FOCUS_ALPHA * 0.52),
		Color(0.0, 0.0, 0.0, LANE_FOCUS_ALPHA * 0.62)
	]))
	for i in range(3):
		var t := float(i) / 2.0
		var y := lerpf(top_y, bottom_y, t)
		var inset := lerpf(map_size.x * 0.17, map_size.x * 0.03, t)
		draw_line(Vector2(inset, y), Vector2(map_size.x - inset, y - tile_size * 0.10), Color(accent.r, accent.g, accent.b, 0.045 + t * 0.030), 1.0 + t)

func _draw_light_shafts(accent: Color, region_type: String, terrain: String) -> void:
	var base_alpha := 0.080
	if region_type == "sect":
		base_alpha = 0.105
	elif terrain.contains("snow"):
		base_alpha = 0.095
	elif terrain.contains("desert"):
		base_alpha = 0.070
	for i in range(LIGHT_SHAFT_COUNT):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x0 := map_size.x * (0.12 + float(i) * 0.13)
		var drift := sin(visual_phase * 0.34 + float(i) * 1.17) * tile_size * 0.32
		var top := Vector2(x0 + drift, tile_size * 0.05)
		var bottom := Vector2(x0 + side * tile_size * (2.2 + float(i % 3) * 0.35), map_size.y * (0.70 + float(i % 2) * 0.08))
		var width_top := tile_size * (0.18 + float(i % 3) * 0.04)
		var width_bottom := tile_size * (1.55 + float(i % 3) * 0.28)
		var alpha := base_alpha * (0.70 + float(i % 3) * 0.14)
		var shaft_color := Color(1.0, 0.88, 0.56, alpha)
		if terrain.contains("snow"):
			shaft_color = Color(0.82, 0.94, 1.0, alpha)
		elif _terrain_has_water(terrain):
			shaft_color = Color(0.60, 0.88, 0.94, alpha)
		elif region_type == "sect":
			shaft_color = Color(accent.r, accent.g, accent.b, alpha)
		draw_polygon(PackedVector2Array([
			top + Vector2(-width_top, 0.0),
			top + Vector2(width_top, 0.0),
			bottom + Vector2(width_bottom, 0.0),
			bottom + Vector2(-width_bottom, 0.0)
		]), PackedColorArray([
			Color(shaft_color.r, shaft_color.g, shaft_color.b, shaft_color.a * 0.62),
			Color(shaft_color.r, shaft_color.g, shaft_color.b, shaft_color.a * 0.52),
			Color(shaft_color.r, shaft_color.g, shaft_color.b, 0.0),
			Color(shaft_color.r, shaft_color.g, shaft_color.b, 0.0)
		]))

func _draw_depth_edges(accent: Color, terrain: String) -> void:
	var edge := Color(0.0, 0.0, 0.0, EDGE_VIGNETTE_ALPHA)
	if terrain.contains("snow"):
		edge = Color(0.02, 0.05, 0.07, EDGE_VIGNETTE_ALPHA * 0.82)
	_draw_horizontal_gradient(Rect2(Vector2.ZERO, Vector2(map_size.x * 0.18, map_size.y)), edge, Color(edge.r, edge.g, edge.b, 0.0))
	_draw_horizontal_gradient(Rect2(Vector2(map_size.x * 0.82, 0.0), Vector2(map_size.x * 0.18, map_size.y)), Color(edge.r, edge.g, edge.b, 0.0), edge)
	_draw_vertical_gradient(Rect2(Vector2.ZERO, Vector2(map_size.x, map_size.y * 0.11)), Color(0.0, 0.0, 0.0, EDGE_VIGNETTE_ALPHA * 0.55), Color(0.0, 0.0, 0.0, 0.0))
	_draw_vertical_gradient(Rect2(Vector2(0.0, map_size.y * 0.86), Vector2(map_size.x, map_size.y * 0.14)), Color(accent.r, accent.g, accent.b, 0.02), Color(0.0, 0.0, 0.0, EDGE_VIGNETTE_ALPHA * 0.92))

func _draw_near_ground_haze(accent: Color, terrain: String) -> void:
	var color := Color(accent.r, accent.g, accent.b, 0.070)
	if terrain.contains("desert"):
		color = Color(0.92, 0.70, 0.40, 0.088)
	elif terrain.contains("snow"):
		color = Color(0.84, 0.94, 1.0, 0.092)
	for i in range(5):
		var y := map_size.y * (0.62 + float(i) * 0.055)
		var x := fposmod(float(i * 313) + visual_phase * tile_size * (0.08 + float(i) * 0.012), map_size.x + tile_size * 7.0) - tile_size * 3.5
		var width := map_size.x * (0.42 + float(i) * 0.10)
		_draw_soft_band(Rect2(Vector2(x, y), Vector2(width, tile_size * (0.22 + float(i) * 0.07))), Color(color.r, color.g, color.b, color.a * (0.7 + float(i) * 0.12)))

func _draw_vertical_gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

func _draw_horizontal_gradient(rect: Rect2, left_color: Color, right_color: Color) -> void:
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([left_color, right_color, right_color, left_color]))

func _draw_soft_band(rect: Rect2, color: Color) -> void:
	var clear := Color(color.r, color.g, color.b, 0.0)
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([clear, clear, color, color]))

func _accent_color(region_type: String, terrain: String) -> Color:
	if terrain.contains("snow"):
		return Color(0.70, 0.90, 1.0)
	if terrain.contains("desert"):
		return Color(0.95, 0.72, 0.36)
	if _terrain_has_water(terrain):
		return Color(0.58, 0.82, 0.86)
	if _terrain_has_forest(terrain):
		return Color(0.50, 0.76, 0.38)
	if region_type == "sect":
		return GameData.get_faction_color(str(current_region.get("faction", "none"))).lightened(0.20)
	if region_type == "city" or region_type == "town":
		return Color(0.92, 0.60, 0.28)
	return Color(0.82, 0.62, 0.32)

func _terrain_has_water(terrain: String) -> bool:
	return terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("waterway") or terrain.contains("canal") or terrain.contains("ford") or terrain.contains("tide") or terrain.contains("weir") or terrain.contains("marsh") or terrain.contains("spring")

func _terrain_has_forest(terrain: String) -> bool:
	return terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden") or terrain.contains("field") or terrain.contains("flower")
