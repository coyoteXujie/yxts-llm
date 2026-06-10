extends RefCounted
class_name StageBackdropRenderer

const StageVisualProfile = preload("res://scripts/shared/stage_visual_profile.gd")

const FAR_DEPTH_LAYER_COUNT := 5
const HORIZON_DETAIL_COUNT := 18
const FACADE_UNIT_COUNT := 10
const FLOOR_STROKE_COUNT := 46
const FLOOR_CHIP_COUNT := 34
const BACKDROP_LANTERN_COUNT := 9
const BACKDROP_BANNER_COUNT := 7

static func draw_stage_foundation(
	canvas: CanvasItem,
	size: Vector2,
	tile_size: int,
	region: Dictionary,
	visual_phase: float,
	palette: Dictionary
) -> void:
	if canvas == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var terrain := str(region.get("terrain", ""))
	var region_type := str(region.get("type", "wild"))
	var sky: Color = palette.get("sky", Color(0.26, 0.30, 0.28, 1.0))
	var far: Color = palette.get("far", Color(0.10, 0.12, 0.10, 1.0))
	var mid: Color = palette.get("mid", Color(0.16, 0.18, 0.13, 1.0))
	var floor_color: Color = palette.get("floor", Color(0.38, 0.32, 0.22, 1.0))
	var accent: Color = palette.get("accent", Color(0.82, 0.62, 0.32, 1.0))

	_draw_full_atmosphere(canvas, size, sky, far, mid, floor_color, accent, tile_size)
	_draw_far_depth(canvas, size, tile_size, terrain, region_type, far, mid, accent, visual_phase)
	if region_type == "city" or region_type == "town":
		_draw_city_backlot(canvas, size, tile_size, accent, visual_phase)
	elif region_type == "sect":
		_draw_sect_backlot(canvas, size, tile_size, accent, str(region.get("faction", "")), visual_phase)
	elif _terrain_has_water(terrain):
		_draw_water_backlot(canvas, size, tile_size, accent, visual_phase)
	elif _terrain_has_forest(terrain):
		_draw_forest_backlot(canvas, size, tile_size, accent, visual_phase)
	elif terrain.contains("snow"):
		_draw_snow_backlot(canvas, size, tile_size, accent)
	elif terrain.contains("desert"):
		_draw_desert_backlot(canvas, size, tile_size, accent)
	else:
		_draw_wild_backlot(canvas, size, tile_size, accent, visual_phase)
	_draw_stage_floor_foundation(canvas, size, tile_size, floor_color, accent, terrain, region_type)
	_draw_edge_depth(canvas, size, tile_size, accent)

static func _draw_full_atmosphere(canvas: CanvasItem, size: Vector2, sky: Color, far: Color, mid: Color, floor_color: Color, accent: Color, tile_size: int) -> void:
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.48)),
		_color_mix(_solid(sky, 1.0), Color(0.050, 0.060, 0.055, 1.0), 0.34),
		_color_mix(_solid(far, 1.0), Color(0.035, 0.035, 0.032, 1.0), 0.28)
	)
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, size.y * 0.32), Vector2(size.x, size.y * 0.36)),
		_color_mix(_solid(mid, 1.0), Color(0.020, 0.022, 0.020, 1.0), 0.22),
		_color_mix(_solid(floor_color, 1.0), Color(0.060, 0.045, 0.032, 1.0), 0.26)
	)
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, size.y * 0.56), Vector2(size.x, size.y * 0.44)),
		_color_mix(_solid(floor_color.lightened(0.09), 1.0), Color(0.070, 0.050, 0.036, 1.0), 0.18),
		_color_mix(_solid(floor_color.darkened(0.34), 1.0), Color(0.010, 0.008, 0.006, 1.0), 0.36)
	)
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, size.y * 0.39), Vector2(size.x, tile_size * 1.35)),
		Color(accent.r, accent.g, accent.b, 0.13),
		Color(accent.r, accent.g, accent.b, 0.0)
	)
	_draw_horizontal_gradient(
		canvas,
		Rect2(Vector2.ZERO, Vector2(size.x * 0.20, size.y)),
		Color(0.0, 0.0, 0.0, 0.34),
		Color(0.0, 0.0, 0.0, 0.0)
	)
	_draw_horizontal_gradient(
		canvas,
		Rect2(Vector2(size.x * 0.80, 0.0), Vector2(size.x * 0.20, size.y)),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.34)
	)

static func _draw_far_depth(canvas: CanvasItem, size: Vector2, tile_size: int, terrain: String, region_type: String, far: Color, mid: Color, accent: Color, visual_phase: float) -> void:
	var horizon := size.y * 0.43
	for layer in range(FAR_DEPTH_LAYER_COUNT):
		var layer_t := float(layer) / float(maxi(1, FAR_DEPTH_LAYER_COUNT - 1))
		var drift := fposmod(visual_phase * tile_size * (0.012 + layer_t * 0.010), size.x + tile_size * 4.0) - tile_size * 2.0
		var y := horizon - tile_size * (2.45 - layer_t * 0.42)
		var layer_color := _color_mix(far, mid, layer_t * 0.48)
		layer_color.a = 0.24 + layer_t * 0.11
		_draw_mountain_ribbon(canvas, size, y, tile_size, drift, layer_t, layer_color)
	for i in range(HORIZON_DETAIL_COUNT):
		var seed := StageVisualProfile.tile_random(i * 17, int(size.x) + i * 11, 1301)
		var t := float(seed % 1000) / 999.0
		var x := lerpf(-tile_size * 0.6, size.x + tile_size * 0.6, t)
		var y := horizon - tile_size * (0.45 + float((seed / 7) % 6) * 0.08)
		var alpha := 0.18 + float(seed % 5) * 0.018
		if region_type == "city" or region_type == "town":
			_draw_distant_roof(canvas, x, y, tile_size, Color(0.040, 0.026, 0.016, alpha), accent)
		elif region_type == "sect":
			_draw_distant_pillar(canvas, x, y, tile_size, Color(0.035, 0.030, 0.022, alpha), accent)
		elif _terrain_has_water(terrain):
			_draw_distant_sail(canvas, x, y + tile_size * 0.32, tile_size, Color(0.040, 0.055, 0.050, alpha), accent)
		elif _terrain_has_forest(terrain):
			_draw_distant_bamboo(canvas, x, y + tile_size * 0.36, tile_size, Color(0.020, 0.070, 0.028, alpha + 0.05), accent)
		else:
			_draw_distant_stone(canvas, x, y + tile_size * 0.28, tile_size, Color(0.055, 0.050, 0.043, alpha), accent)

static func _draw_city_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color, visual_phase: float) -> void:
	var top_y := size.y * 0.335
	var base_y := size.y * 0.555
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, top_y - tile_size * 0.42), Vector2(size.x, tile_size * 3.3)),
		Color(0.020, 0.012, 0.008, 0.76),
		Color(0.004, 0.003, 0.002, 0.50)
	)
	var span := size.x / float(maxi(1, FACADE_UNIT_COUNT - 1))
	for i in range(FACADE_UNIT_COUNT):
		var x := float(i) * span - tile_size * 0.72
		var w := tile_size * (2.75 + float(i % 3) * 0.34)
		var h := tile_size * (1.72 + float((i + 1) % 4) * 0.20)
		var local_base := base_y + sin(float(i) * 0.81) * tile_size * 0.12
		var wall_alpha := 0.46 + float(i % 4) * 0.030
		_draw_shopfront_block(canvas, x, local_base, w, h, accent, wall_alpha, i, tile_size)
	_draw_city_roof_ribbon(canvas, size, top_y + tile_size * 0.18, tile_size, accent)
	for i in range(BACKDROP_LANTERN_COUNT):
		var t := float(i) / float(maxi(1, BACKDROP_LANTERN_COUNT - 1))
		var x := lerpf(size.x * 0.07, size.x * 0.93, t)
		var y := top_y + tile_size * (0.72 + float(i % 3) * 0.20)
		var pulse := 0.5 + sin(visual_phase * 1.2 + float(i) * 0.67) * 0.5
		canvas.draw_line(Vector2(x, y - tile_size * 0.42), Vector2(x, y), Color(0.64, 0.38, 0.16, 0.42), 1.2)
		canvas.draw_circle(Vector2(x, y), tile_size * 0.075, Color(1.0, 0.58, 0.18, 0.20 + pulse * 0.07))
		canvas.draw_circle(Vector2(x, y), tile_size * 0.14, Color(1.0, 0.42, 0.10, 0.045 + pulse * 0.025))

static func _draw_sect_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color, _faction: String, visual_phase: float) -> void:
	var center_x := size.x * 0.50
	var base_y := size.y * 0.56
	var hall_w := size.x * 0.50
	var hall_h := tile_size * 2.45
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(center_x - hall_w * 0.62, base_y - hall_h), Vector2(hall_w * 1.24, hall_h * 1.18)),
		Color(0.028, 0.024, 0.018, 0.72),
		Color(0.010, 0.008, 0.006, 0.60)
	)
	var roof := PackedVector2Array([
		Vector2(center_x - hall_w * 0.62, base_y - hall_h + tile_size * 0.58),
		Vector2(center_x, base_y - hall_h - tile_size * 0.42),
		Vector2(center_x + hall_w * 0.62, base_y - hall_h + tile_size * 0.58),
		Vector2(center_x + hall_w * 0.52, base_y - hall_h + tile_size * 0.96),
		Vector2(center_x - hall_w * 0.52, base_y - hall_h + tile_size * 0.96)
	])
	canvas.draw_polygon(roof, PackedColorArray([
		Color(0.030, 0.024, 0.018, 0.80),
		Color(accent.r, accent.g, accent.b, 0.48),
		Color(0.030, 0.024, 0.018, 0.80),
		Color(0.014, 0.011, 0.008, 0.84),
		Color(0.014, 0.011, 0.008, 0.84)
	]))
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var pillar_x := center_x + side * hall_w * 0.32
		canvas.draw_rect(Rect2(Vector2(pillar_x - tile_size * 0.13, base_y - hall_h + tile_size * 0.86), Vector2(tile_size * 0.26, hall_h * 0.78)), Color(0.020, 0.016, 0.012, 0.72), true)
	for step in range(5):
		var t := float(step) / 4.0
		var y := base_y - tile_size * (0.58 - t * 0.24)
		var inset := lerpf(size.x * 0.29, size.x * 0.18, t)
		canvas.draw_line(Vector2(inset, y), Vector2(size.x - inset, y - tile_size * 0.08), Color(accent.r, accent.g, accent.b, 0.18 + t * 0.05), 1.4 + t * 1.0)
	for i in range(BACKDROP_BANNER_COUNT):
		var t := float(i) / float(maxi(1, BACKDROP_BANNER_COUNT - 1))
		var x := lerpf(size.x * 0.12, size.x * 0.88, t)
		var sway := sin(visual_phase * 0.7 + float(i) * 0.6) * tile_size * 0.08
		_draw_banner(canvas, x + sway, base_y - tile_size * (1.70 + float(i % 2) * 0.12), tile_size, accent, 0.28 + float(i % 3) * 0.03)

static func _draw_water_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color, visual_phase: float) -> void:
	var water_y := size.y * 0.48
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, water_y - tile_size * 0.70), Vector2(size.x, tile_size * 2.25)),
		Color(0.060, 0.110, 0.120, 0.46),
		Color(0.016, 0.035, 0.038, 0.40)
	)
	for i in range(8):
		var y := water_y + tile_size * (0.12 + float(i) * 0.17)
		var drift := sin(visual_phase * 0.34 + float(i)) * tile_size * 0.35
		canvas.draw_line(Vector2(size.x * 0.06 + drift, y), Vector2(size.x * 0.94 + drift * 0.2, y - tile_size * 0.10), Color(accent.r, accent.g, accent.b, 0.11 + float(i % 3) * 0.018), 1.3)
	for i in range(5):
		var x := size.x * (0.13 + float(i) * 0.18)
		var y := water_y + tile_size * (0.50 + float(i % 2) * 0.16)
		_draw_distant_boat(canvas, x, y, tile_size, accent)

static func _draw_forest_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color, visual_phase: float) -> void:
	var base_y := size.y * 0.56
	for i in range(18):
		var t := float(i) / 17.0
		var x := lerpf(-tile_size * 0.8, size.x + tile_size * 0.8, t)
		var h := tile_size * (2.3 + float(i % 5) * 0.26)
		var sway := sin(visual_phase * 0.42 + float(i) * 0.4) * tile_size * 0.12
		canvas.draw_line(Vector2(x, base_y + tile_size * 0.18), Vector2(x + sway, base_y - h), Color(0.006, 0.040, 0.014, 0.46), 3.0 + float(i % 3) * 0.5)
		_draw_ellipse(canvas, Vector2(x + sway + tile_size * 0.18, base_y - h * 0.82), Vector2(tile_size * 0.55, tile_size * 0.16), Color(accent.r * 0.44, accent.g * 0.54, accent.b * 0.38, 0.24))

static func _draw_snow_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color) -> void:
	var ridge_y := size.y * 0.50
	for i in range(7):
		var x := float(i) * size.x / 6.0 - tile_size * 0.3
		var w := tile_size * (1.4 + float(i % 3) * 0.34)
		canvas.draw_polygon(PackedVector2Array([
			Vector2(x - w, ridge_y + tile_size * 0.32),
			Vector2(x, ridge_y - tile_size * (0.75 + float(i % 2) * 0.18)),
			Vector2(x + w, ridge_y + tile_size * 0.28)
		]), PackedColorArray([
			Color(0.10, 0.13, 0.15, 0.44),
			Color(0.72, 0.86, 0.94, 0.20),
			Color(0.05, 0.07, 0.09, 0.44)
		]))
		canvas.draw_line(Vector2(x - w * 0.22, ridge_y - tile_size * 0.18), Vector2(x + w * 0.40, ridge_y + tile_size * 0.14), Color(accent.r, accent.g, accent.b, 0.16), 1.1)

static func _draw_desert_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color) -> void:
	var dune_y := size.y * 0.53
	for i in range(5):
		var y := dune_y + float(i) * tile_size * 0.18
		var alpha := 0.20 - float(i) * 0.018
		canvas.draw_arc(Vector2(size.x * 0.52, y), size.x * (0.38 + float(i) * 0.08), PI * 1.03, PI * 1.94, 64, Color(accent.r, accent.g, accent.b, alpha), 2.0)
	for i in range(10):
		var x := lerpf(size.x * 0.06, size.x * 0.94, float(i) / 9.0)
		var y := dune_y + tile_size * (0.25 + float(i % 3) * 0.12)
		_draw_distant_stone(canvas, x, y, tile_size, Color(0.10, 0.070, 0.040, 0.22), accent)

static func _draw_wild_backlot(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color, visual_phase: float) -> void:
	var base_y := size.y * 0.55
	for i in range(9):
		var t := float(i) / 8.0
		var x := lerpf(size.x * 0.02, size.x * 0.95, t)
		var y := base_y + sin(visual_phase * 0.12 + float(i)) * tile_size * 0.05
		_draw_distant_stone(canvas, x, y, tile_size * (1.0 + float(i % 3) * 0.08), Color(0.050, 0.044, 0.036, 0.28), accent)

static func _draw_stage_floor_foundation(canvas: CanvasItem, size: Vector2, tile_size: int, floor_color: Color, accent: Color, terrain: String, region_type: String) -> void:
	var top_y := size.y * 0.48
	var bottom_y := size.y + tile_size * 0.55
	var left_top := size.x * 0.085
	var right_top := size.x * 0.915
	canvas.draw_polygon(PackedVector2Array([
		Vector2(left_top, top_y),
		Vector2(right_top, top_y - tile_size * 0.08),
		Vector2(size.x * 1.05, bottom_y),
		Vector2(size.x * -0.05, bottom_y)
	]), PackedColorArray([
		Color(floor_color.r * 1.10, floor_color.g * 1.08, floor_color.b * 1.03, 0.98),
		Color(floor_color.r * 1.03, floor_color.g * 1.00, floor_color.b * 0.96, 0.98),
		Color(floor_color.r * 0.44, floor_color.g * 0.42, floor_color.b * 0.38, 1.0),
		Color(floor_color.r * 0.50, floor_color.g * 0.47, floor_color.b * 0.40, 1.0)
	]))
	for lane in range(6):
		var t := float(lane) / 5.0
		var y := lerpf(top_y + tile_size * 0.12, size.y - tile_size * 0.46, t)
		var inset := lerpf(size.x * 0.115, size.x * -0.020, t)
		var alpha := 0.15 + t * 0.10
		canvas.draw_line(Vector2(inset, y), Vector2(size.x - inset, y - tile_size * 0.10), Color(0.0, 0.0, 0.0, alpha), 1.5 + t * 2.2)
		canvas.draw_line(Vector2(inset + tile_size * 0.26, y - tile_size * 0.040), Vector2(size.x - inset - tile_size * 0.30, y - tile_size * 0.13), Color(accent.r, accent.g, accent.b, alpha * 0.44), 0.9 + t * 0.6)
	for i in range(FLOOR_STROKE_COUNT):
		var seed := StageVisualProfile.tile_random(i * 13, int(size.y) + i * 17, 2101)
		var t := float(seed % 1000) / 999.0
		var u := float((seed / 11) % 1000) / 999.0
		var y := lerpf(top_y + tile_size * 0.40, size.y - tile_size * 0.24, t)
		var inset := lerpf(size.x * 0.12, size.x * -0.03, t)
		var x := lerpf(inset + tile_size * 0.38, size.x - inset - tile_size * 0.38, u)
		var len := tile_size * (0.20 + float(seed % 7) * 0.035)
		var alpha := 0.050 + t * 0.055
		canvas.draw_line(Vector2(x, y), Vector2(x + len, y - tile_size * 0.035), Color(0.0, 0.0, 0.0, alpha), 0.8 + t * 0.8)
	for i in range(FLOOR_CHIP_COUNT):
		var seed := StageVisualProfile.tile_random(i * 23, int(size.x) + i * 9, 2201)
		var t := float(seed % 1000) / 999.0
		var u := float((seed / 7) % 1000) / 999.0
		var y := lerpf(top_y + tile_size * 0.55, size.y - tile_size * 0.18, t)
		var inset := lerpf(size.x * 0.12, size.x * -0.03, t)
		var x := lerpf(inset + tile_size * 0.30, size.x - inset - tile_size * 0.30, u)
		var chip_color := Color(accent.r, accent.g, accent.b, 0.040 + t * 0.040)
		if region_type == "city" or region_type == "town":
			canvas.draw_rect(Rect2(Vector2(x, y), Vector2(tile_size * 0.12, tile_size * 0.018)), Color(0.0, 0.0, 0.0, 0.055 + t * 0.040), true)
		elif _terrain_has_water(terrain):
			canvas.draw_line(Vector2(x - tile_size * 0.12, y), Vector2(x + tile_size * 0.16, y - tile_size * 0.025), chip_color, 0.9)
		else:
			_draw_ellipse(canvas, Vector2(x, y), Vector2(tile_size * 0.045, tile_size * 0.014), Color(0.0, 0.0, 0.0, 0.060 + t * 0.040))

static func _draw_edge_depth(canvas: CanvasItem, size: Vector2, tile_size: int, accent: Color) -> void:
	_draw_vertical_gradient(
		canvas,
		Rect2(Vector2(0.0, size.y * 0.86), Vector2(size.x, size.y * 0.14 + tile_size * 0.3)),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.42)
	)
	canvas.draw_line(Vector2(size.x * 0.06, size.y * 0.485), Vector2(size.x * 0.00, size.y * 0.97), Color(accent.r, accent.g, accent.b, 0.10), 1.4)
	canvas.draw_line(Vector2(size.x * 0.94, size.y * 0.475), Vector2(size.x * 1.00, size.y * 0.95), Color(accent.r, accent.g, accent.b, 0.10), 1.4)

static func _draw_mountain_ribbon(canvas: CanvasItem, size: Vector2, base_y: float, tile_size: int, drift: float, layer_t: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(Vector2(-tile_size * 1.5, size.y * 0.61))
	colors.append(color)
	var steps := 14
	for i in range(steps + 1):
		var x := size.x * float(i) / float(steps) + drift * (1.0 - layer_t * 0.42)
		var y := base_y - sin(float(i) * (1.25 + layer_t * 0.18) + layer_t * 2.0) * tile_size * (0.42 - layer_t * 0.10)
		points.append(Vector2(x, y))
		colors.append(color)
	points.append(Vector2(size.x + tile_size * 1.5, size.y * 0.61))
	colors.append(color)
	canvas.draw_polygon(points, colors)

static func _draw_shopfront_block(canvas: CanvasItem, x: float, base_y: float, width: float, height: float, accent: Color, alpha: float, index: int, tile_size: int) -> void:
	var wall := Rect2(Vector2(x, base_y - height), Vector2(width, height))
	canvas.draw_rect(wall, Color(0.028, 0.016, 0.010, alpha), true)
	_draw_vertical_gradient(canvas, wall, Color(accent.r, accent.g, accent.b, alpha * 0.18), Color(0.0, 0.0, 0.0, alpha * 0.34))
	var roof_y := base_y - height - tile_size * (0.08 + float(index % 2) * 0.045)
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.08, roof_y + tile_size * 0.36),
		Vector2(x + width * 0.48, roof_y),
		Vector2(x + width * 1.08, roof_y + tile_size * 0.36),
		Vector2(x + width * 1.00, roof_y + tile_size * 0.58),
		Vector2(x, roof_y + tile_size * 0.58)
	]), PackedColorArray([
		Color(0.050, 0.026, 0.014, alpha + 0.08),
		Color(accent.r, accent.g, accent.b, alpha * 0.42),
		Color(0.045, 0.024, 0.014, alpha + 0.08),
		Color(0.016, 0.010, 0.006, alpha + 0.10),
		Color(0.016, 0.010, 0.006, alpha + 0.10)
	]))
	for column in range(3):
		var px := x + width * (0.20 + float(column) * 0.30)
		canvas.draw_line(Vector2(px, base_y - height * 0.78), Vector2(px, base_y - tile_size * 0.14), Color(0.0, 0.0, 0.0, alpha * 0.50), 1.4)
	for row in range(2):
		var wy := base_y - height * (0.60 - float(row) * 0.24)
		canvas.draw_line(Vector2(x + width * 0.13, wy), Vector2(x + width * 0.86, wy - tile_size * 0.02), Color(accent.r, accent.g, accent.b, alpha * 0.16), 1.0)

static func _draw_city_roof_ribbon(canvas: CanvasItem, size: Vector2, y: float, tile_size: int, accent: Color) -> void:
	for i in range(8):
		var x := float(i) * size.x / 7.0 - tile_size * 0.9
		var w := tile_size * (2.1 + float(i % 3) * 0.28)
		canvas.draw_line(Vector2(x, y + tile_size * 0.72), Vector2(x + w, y + tile_size * 0.64), Color(0.0, 0.0, 0.0, 0.42), 3.4)
		canvas.draw_line(Vector2(x + tile_size * 0.12, y + tile_size * 0.56), Vector2(x + w - tile_size * 0.16, y + tile_size * 0.50), Color(accent.r, accent.g, accent.b, 0.16), 1.3)

static func _draw_distant_roof(canvas: CanvasItem, x: float, y: float, tile_size: int, color: Color, accent: Color) -> void:
	var w := tile_size * 0.98
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x - w * 0.58, y + tile_size * 0.22),
		Vector2(x, y - tile_size * 0.18),
		Vector2(x + w * 0.58, y + tile_size * 0.22),
		Vector2(x + w * 0.46, y + tile_size * 0.34),
		Vector2(x - w * 0.46, y + tile_size * 0.34)
	]), PackedColorArray([color, Color(accent.r, accent.g, accent.b, color.a * 0.76), color, color, color]))

static func _draw_distant_pillar(canvas: CanvasItem, x: float, y: float, tile_size: int, color: Color, accent: Color) -> void:
	canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.050, y - tile_size * 0.38), Vector2(tile_size * 0.10, tile_size * 0.72)), color, true)
	canvas.draw_line(Vector2(x - tile_size * 0.20, y - tile_size * 0.34), Vector2(x + tile_size * 0.20, y - tile_size * 0.34), Color(accent.r, accent.g, accent.b, color.a * 0.68), 1.1)

static func _draw_distant_sail(canvas: CanvasItem, x: float, y: float, tile_size: int, color: Color, accent: Color) -> void:
	canvas.draw_line(Vector2(x, y - tile_size * 0.42), Vector2(x, y + tile_size * 0.26), color, 1.3)
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x + tile_size * 0.03, y - tile_size * 0.36),
		Vector2(x + tile_size * 0.42, y - tile_size * 0.02),
		Vector2(x + tile_size * 0.03, y + tile_size * 0.12)
	]), PackedColorArray([Color(accent.r, accent.g, accent.b, color.a * 0.70), color, color]))

static func _draw_distant_bamboo(canvas: CanvasItem, x: float, y: float, tile_size: int, color: Color, accent: Color) -> void:
	canvas.draw_line(Vector2(x, y + tile_size * 0.35), Vector2(x + tile_size * 0.08, y - tile_size * 0.48), color, 1.4)
	canvas.draw_line(Vector2(x + tile_size * 0.05, y - tile_size * 0.22), Vector2(x + tile_size * 0.32, y - tile_size * 0.34), Color(accent.r, accent.g, accent.b, color.a * 0.52), 1.0)

static func _draw_distant_stone(canvas: CanvasItem, x: float, y: float, tile_size: float, color: Color, accent: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x - tile_size * 0.34, y + tile_size * 0.20),
		Vector2(x - tile_size * 0.08, y - tile_size * 0.38),
		Vector2(x + tile_size * 0.34, y + tile_size * 0.18)
	]), PackedColorArray([color, Color(accent.r, accent.g, accent.b, color.a * 0.56), color]))

static func _draw_distant_boat(canvas: CanvasItem, x: float, y: float, tile_size: int, accent: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x - tile_size * 0.50, y),
		Vector2(x + tile_size * 0.46, y - tile_size * 0.04),
		Vector2(x + tile_size * 0.28, y + tile_size * 0.18),
		Vector2(x - tile_size * 0.34, y + tile_size * 0.20)
	]), PackedColorArray([
		Color(0.030, 0.018, 0.010, 0.34),
		Color(accent.r, accent.g, accent.b, 0.18),
		Color(0.014, 0.010, 0.006, 0.36),
		Color(0.018, 0.012, 0.008, 0.36)
	]))
	canvas.draw_line(Vector2(x, y - tile_size * 0.42), Vector2(x, y + tile_size * 0.04), Color(0.0, 0.0, 0.0, 0.24), 1.1)

static func _draw_banner(canvas: CanvasItem, x: float, y: float, tile_size: int, accent: Color, alpha: float) -> void:
	canvas.draw_line(Vector2(x, y - tile_size * 0.20), Vector2(x, y + tile_size * 0.74), Color(0.0, 0.0, 0.0, alpha), 1.4)
	canvas.draw_polygon(PackedVector2Array([
		Vector2(x, y),
		Vector2(x + tile_size * 0.34, y + tile_size * 0.10),
		Vector2(x + tile_size * 0.24, y + tile_size * 0.72),
		Vector2(x + tile_size * 0.11, y + tile_size * 0.58),
		Vector2(x, y + tile_size * 0.70)
	]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.72),
		Color(0.020, 0.014, 0.010, alpha * 0.82),
		Color(0.040, 0.028, 0.018, alpha),
		Color(0.016, 0.012, 0.008, alpha)
	]))

static func _draw_vertical_gradient(canvas: CanvasItem, rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

static func _draw_horizontal_gradient(canvas: CanvasItem, rect: Rect2, left_color: Color, right_color: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([left_color, right_color, right_color, left_color]))

static func _draw_ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	canvas.draw_polygon(points, colors)

static func _solid(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

static func _color_mix(a: Color, b: Color, weight: float) -> Color:
	return a.lerp(b, clampf(weight, 0.0, 1.0))

static func _terrain_has_water(terrain: String) -> bool:
	return terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("waterway") or terrain.contains("canal") or terrain.contains("ford") or terrain.contains("tide") or terrain.contains("weir") or terrain.contains("marsh") or terrain.contains("spring")

static func _terrain_has_forest(terrain: String) -> bool:
	return terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("garden") or terrain.contains("field") or terrain.contains("flower")
