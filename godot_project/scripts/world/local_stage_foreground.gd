extends Node2D
class_name LocalStageForeground

const TOP_EAVE_COUNT := 9
const FOREGROUND_MIST_BANDS := 4
const SIDE_OCCLUDER_COUNT := 7

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
	_draw_top_depth(accent, region_type, terrain)
	_draw_side_occluders(accent, region_type, terrain)
	_draw_foreground_mist(accent, terrain)
	_draw_bottom_vignette(accent)

func _draw_top_depth(accent: Color, region_type: String, terrain: String) -> void:
	if region_type == "city" or region_type == "town":
		_draw_hanging_eaves(accent)
	elif region_type == "sect":
		_draw_sect_arch(accent)
	elif _terrain_has_forest(terrain):
		_draw_canopy(accent)
	elif terrain.contains("snow"):
		_draw_frosted_branches(accent)
	else:
		_draw_rock_overhang(accent)

func _draw_hanging_eaves(accent: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size.x, tile_size * 0.76)), Color(0.025, 0.014, 0.008, 0.56), true)
	for i in range(TOP_EAVE_COUNT):
		var x := float(i) * map_size.x / float(TOP_EAVE_COUNT - 1) - tile_size * 0.55
		var w := tile_size * (1.8 + float(i % 3) * 0.36)
		var y := tile_size * (0.18 + float(i % 2) * 0.08)
		var roof := PackedVector2Array([
			Vector2(x, y + tile_size * 0.62),
			Vector2(x + w * 0.52, y),
			Vector2(x + w, y + tile_size * 0.62),
			Vector2(x + w * 0.88, y + tile_size * 0.84),
			Vector2(x + w * 0.10, y + tile_size * 0.84)
		])
		draw_polygon(roof, PackedColorArray([
			Color(0.05, 0.025, 0.014, 0.70),
			Color(accent.r, accent.g, accent.b, 0.36),
			Color(0.04, 0.020, 0.012, 0.70),
			Color(0.03, 0.016, 0.010, 0.72),
			Color(0.035, 0.018, 0.010, 0.72)
		]))
		if i % 2 == 0:
			var lamp := Vector2(x + w * 0.62, y + tile_size * 0.92)
			var pulse := 0.5 + sin(visual_phase * 2.1 + float(i)) * 0.5
			draw_line(lamp + Vector2(0.0, -tile_size * 0.32), lamp, Color(0.72, 0.48, 0.24, 0.42), 1.4)
			draw_circle(lamp, tile_size * 0.07, Color(1.0, 0.66, 0.24, 0.20 + pulse * 0.07))

func _draw_sect_arch(accent: Color) -> void:
	var center_x := map_size.x * 0.50
	var y := tile_size * 0.12
	var w := tile_size * 5.8
	draw_rect(Rect2(Vector2(0, 0), Vector2(map_size.x, tile_size * 0.52)), Color(0.022, 0.018, 0.014, 0.40), true)
	draw_polygon(PackedVector2Array([
		Vector2(center_x - w * 0.55, y + tile_size * 0.86),
		Vector2(center_x, y),
		Vector2(center_x + w * 0.55, y + tile_size * 0.86),
		Vector2(center_x + w * 0.45, y + tile_size * 1.08),
		Vector2(center_x - w * 0.45, y + tile_size * 1.08)
	]), PackedColorArray([
		Color(0.04, 0.030, 0.020, 0.62),
		Color(accent.r, accent.g, accent.b, 0.42),
		Color(0.04, 0.030, 0.020, 0.62),
		Color(0.025, 0.020, 0.016, 0.66),
		Color(0.025, 0.020, 0.016, 0.66)
	]))
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var x: float = center_x + side * w * 0.34
		draw_rect(Rect2(Vector2(x - tile_size * 0.12, y + tile_size * 0.72), Vector2(tile_size * 0.24, tile_size * 1.35)), Color(0.03, 0.024, 0.018, 0.58), true)

func _draw_canopy(accent: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size.x, tile_size * 0.38)), Color(0.006, 0.020, 0.010, 0.36), true)
	for i in range(16):
		var x := fposmod(float(i * 173) + sin(visual_phase * 0.45 + float(i)) * tile_size * 0.24, map_size.x + tile_size * 2.0) - tile_size
		var y := tile_size * (0.14 + float(i % 4) * 0.12)
		var radius := Vector2(tile_size * (0.52 + float(i % 3) * 0.12), tile_size * (0.22 + float(i % 2) * 0.06))
		_draw_ellipse(x, y, radius, Color(0.01, 0.07, 0.025, 0.34 + float(i % 3) * 0.035))
		draw_line(Vector2(x - radius.x * 0.35, y + radius.y * 0.22), Vector2(x + radius.x * 0.36, y - radius.y * 0.12), Color(accent.r, accent.g, accent.b, 0.12), 1.2)

func _draw_frosted_branches(accent: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size.x, tile_size * 0.46)), Color(0.015, 0.026, 0.034, 0.34), true)
	for i in range(11):
		var x := float(i) * map_size.x / 10.0 - tile_size * 0.2
		var branch_end := Vector2(x + tile_size * (0.72 + float(i % 3) * 0.16), tile_size * (0.35 + float(i % 2) * 0.12))
		draw_line(Vector2(x, 0.0), branch_end, Color(0.70, 0.84, 0.92, 0.28), 2.1)
		draw_line(branch_end, branch_end + Vector2(tile_size * 0.32, tile_size * 0.16), Color(accent.r, accent.g, accent.b, 0.22), 1.3)

func _draw_rock_overhang(accent: Color) -> void:
	var points := PackedVector2Array([
		Vector2(0, 0),
		Vector2(map_size.x, 0),
		Vector2(map_size.x, tile_size * 0.32),
		Vector2(map_size.x * 0.72, tile_size * 0.55),
		Vector2(map_size.x * 0.38, tile_size * 0.40),
		Vector2(map_size.x * 0.16, tile_size * 0.62),
		Vector2(0, tile_size * 0.44)
	])
	draw_polygon(points, PackedColorArray([
		Color(0.024, 0.022, 0.018, 0.46),
		Color(0.020, 0.018, 0.015, 0.48),
		Color(accent.r, accent.g, accent.b, 0.18),
		Color(0.030, 0.027, 0.021, 0.48),
		Color(0.026, 0.024, 0.020, 0.50),
		Color(0.032, 0.028, 0.021, 0.48),
		Color(0.024, 0.022, 0.018, 0.46)
	]))

func _draw_side_occluders(accent: Color, region_type: String, terrain: String) -> void:
	for i in range(SIDE_OCCLUDER_COUNT):
		var t := float(i) / float(maxi(1, SIDE_OCCLUDER_COUNT - 1))
		var y := lerpf(map_size.y * 0.36, map_size.y * 0.88, t)
		var height := tile_size * (1.10 + t * 1.85)
		var width := tile_size * (0.38 + t * 0.30)
		var left_alpha := 0.18 + t * 0.17
		var right_alpha := 0.14 + t * 0.14
		var left_x := tile_size * (0.12 + float(i % 2) * 0.10)
		var right_x := map_size.x - tile_size * (0.50 + float((i + 1) % 2) * 0.10)
		if region_type == "city" or region_type == "town" or region_type == "sect":
			draw_rect(Rect2(Vector2(left_x - width * 0.5, y - height), Vector2(width, height)), Color(0.020, 0.012, 0.008, left_alpha), true)
			draw_rect(Rect2(Vector2(right_x - width * 0.5, y - height * 0.92), Vector2(width, height * 0.92)), Color(0.020, 0.012, 0.008, right_alpha), true)
			draw_line(Vector2(left_x + width * 0.28, y - height), Vector2(left_x + width * 0.28, y), Color(accent.r, accent.g, accent.b, 0.08 + t * 0.06), 1.4)
		elif _terrain_has_forest(terrain):
			draw_line(Vector2(left_x, map_size.y), Vector2(left_x + tile_size * 0.18, y - height), Color(0.004, 0.030, 0.012, left_alpha + 0.08), 3.2 + t * 2.0)
			draw_line(Vector2(right_x, map_size.y), Vector2(right_x - tile_size * 0.18, y - height * 0.92), Color(0.004, 0.030, 0.012, right_alpha + 0.06), 3.0 + t * 1.7)

func _draw_foreground_mist(accent: Color, terrain: String) -> void:
	var base_color := Color(accent.r, accent.g, accent.b, 0.09)
	if terrain.contains("snow"):
		base_color = Color(0.82, 0.94, 1.0, 0.13)
	elif terrain.contains("desert"):
		base_color = Color(0.92, 0.72, 0.38, 0.11)
	for i in range(FOREGROUND_MIST_BANDS):
		var y := map_size.y * (0.70 + float(i) * 0.055)
		var h := tile_size * (0.26 + float(i) * 0.12)
		var x := fposmod(float(i * 277) + visual_phase * tile_size * (0.10 + float(i) * 0.025), map_size.x + tile_size * 5.0) - tile_size * 2.5
		var w := map_size.x * (0.55 + float(i) * 0.11)
		_draw_soft_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(base_color.r, base_color.g, base_color.b, base_color.a * (0.75 + float(i) * 0.15)))

func _draw_bottom_vignette(accent: Color) -> void:
	var y := map_size.y * 0.84
	_draw_soft_rect(Rect2(Vector2.ZERO + Vector2(0.0, y), Vector2(map_size.x, map_size.y - y)), Color(0.0, 0.0, 0.0, 0.20))
	_draw_soft_rect(Rect2(Vector2.ZERO + Vector2(0.0, y + tile_size * 0.40), Vector2(map_size.x, tile_size * 0.90)), Color(accent.r, accent.g, accent.b, 0.08))

func _draw_soft_rect(rect: Rect2, color: Color) -> void:
	var clear := Color(color.r, color.g, color.b, 0.0)
	draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([clear, clear, color, color]))

func _draw_ellipse(x: float, y: float, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(Vector2(x, y) + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)

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
