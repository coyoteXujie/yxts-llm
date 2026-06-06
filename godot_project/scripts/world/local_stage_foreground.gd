extends Node2D
class_name LocalStageForeground

const TOP_EAVE_COUNT := 9
const FOREGROUND_MIST_BANDS := 4
const SIDE_OCCLUDER_COUNT := 7
const BOTTOM_OCCLUDER_COUNT := 10
const BOTTOM_OCCLUDER_ALPHA := 0.24
const HANGING_FOREGROUND_COUNT := 8
const HANGING_FOREGROUND_ALPHA := 0.28
const FRONT_SETPIECE_COUNT := 6
const FRONT_SETPIECE_ALPHA := 0.30

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
	_draw_hanging_foreground(accent, region_type, terrain)
	_draw_side_occluders(accent, region_type, terrain)
	_draw_front_setpieces(accent, region_type, terrain)
	_draw_bottom_occluders(accent, region_type, terrain)
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

func _draw_hanging_foreground(accent: Color, region_type: String, terrain: String) -> void:
	for i in range(HANGING_FOREGROUND_COUNT):
		var t := float(i) / float(maxi(1, HANGING_FOREGROUND_COUNT - 1))
		var x := lerpf(tile_size * 0.30, map_size.x - tile_size * 0.30, t)
		var sway := sin(visual_phase * 0.92 + float(i) * 0.77) * tile_size * 0.10
		var top_y := tile_size * (0.10 + float(i % 3) * 0.045)
		var alpha := HANGING_FOREGROUND_ALPHA * (0.70 + float(i % 3) * 0.12)
		if region_type == "city" or region_type == "town":
			_draw_hanging_sign(x + sway, top_y, accent, alpha, i)
		elif region_type == "sect":
			_draw_hanging_banner(x + sway, top_y, accent, alpha, i)
		elif _terrain_has_forest(terrain):
			_draw_near_branch(x + sway, top_y, accent, alpha, i)
		elif terrain.contains("snow"):
			_draw_near_icicle(x + sway, top_y, accent, alpha, i)
		else:
			_draw_near_tassel(x + sway, top_y, accent, alpha, i)

func _draw_hanging_sign(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var line_height := tile_size * (0.32 + float(index % 2) * 0.08)
	draw_line(Vector2(x, y), Vector2(x, y + line_height), Color(0.55, 0.36, 0.20, alpha * 0.92), 1.1)
	var rect := Rect2(Vector2(x - tile_size * 0.18, y + line_height), Vector2(tile_size * 0.36, tile_size * 0.20))
	draw_rect(rect, Color(0.10, 0.045, 0.024, alpha), true)
	draw_rect(rect.grow(-2.0), Color(accent.r, accent.g, accent.b, alpha * 0.34), true)
	if index % 2 == 0:
		draw_circle(Vector2(x + tile_size * 0.24, y + line_height + tile_size * 0.12), tile_size * 0.055, Color(1.0, 0.64, 0.22, alpha * 0.52))

func _draw_hanging_banner(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var h := tile_size * (0.62 + float(index % 3) * 0.12)
	var w := tile_size * 0.24
	draw_line(Vector2(x, y), Vector2(x, y + h + tile_size * 0.14), Color(0.03, 0.024, 0.018, alpha), 1.5)
	draw_polygon(PackedVector2Array([
		Vector2(x, y + tile_size * 0.12),
		Vector2(x + w, y + tile_size * 0.20),
		Vector2(x + w * 0.82, y + h),
		Vector2(x + w * 0.46, y + h - tile_size * 0.12),
		Vector2(x, y + h)
	]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.74),
		Color(0.020, 0.016, 0.012, alpha * 0.82),
		Color(0.045, 0.034, 0.024, alpha * 0.84),
		Color(0.020, 0.016, 0.012, alpha * 0.88)
	]))

func _draw_near_branch(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var end := Vector2(x + tile_size * (0.50 + float(index % 3) * 0.16), y + tile_size * (0.18 + float(index % 2) * 0.08))
	draw_line(Vector2(x, y), end, Color(0.006, 0.036, 0.014, alpha + 0.08), 2.8)
	for j in range(3):
		var leaf := end + Vector2(tile_size * (0.12 + float(j) * 0.13), tile_size * (-0.12 + float(j % 2) * 0.11))
		_draw_ellipse(leaf.x, leaf.y, Vector2(tile_size * 0.12, tile_size * 0.040), Color(accent.r, accent.g, accent.b, alpha * 0.68))

func _draw_near_icicle(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var h := tile_size * (0.34 + float(index % 4) * 0.08)
	draw_polygon(PackedVector2Array([
		Vector2(x - tile_size * 0.06, y),
		Vector2(x + tile_size * 0.07, y + tile_size * 0.02),
		Vector2(x + tile_size * 0.01, y + h)
	]), PackedColorArray([
		Color(0.86, 0.96, 1.0, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.74),
		Color(0.72, 0.90, 1.0, alpha * 0.46)
	]))

func _draw_near_tassel(x: float, y: float, accent: Color, alpha: float, index: int) -> void:
	var h := tile_size * (0.34 + float(index % 3) * 0.08)
	draw_line(Vector2(x, y), Vector2(x + tile_size * 0.08, y + h), Color(accent.r, accent.g, accent.b, alpha), 1.2)
	draw_line(Vector2(x + tile_size * 0.04, y + h * 0.54), Vector2(x + tile_size * 0.22, y + h * 0.72), Color(0.02, 0.016, 0.012, alpha * 0.82), 1.0)

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

func _draw_front_setpieces(accent: Color, region_type: String, terrain: String) -> void:
	for i in range(FRONT_SETPIECE_COUNT):
		var t := float(i) / float(maxi(1, FRONT_SETPIECE_COUNT - 1))
		var side := -1.0 if i % 2 == 0 else 1.0
		var edge_x := tile_size * (0.18 + t * 0.42) if side < 0.0 else map_size.x - tile_size * (0.34 + t * 0.42)
		var y := map_size.y * (0.58 + float((i * 5) % 19) / 55.0)
		var scale := 0.82 + t * 0.42
		var alpha := FRONT_SETPIECE_ALPHA * (0.62 + t * 0.38)
		if region_type == "city" or region_type == "town":
			_draw_front_arch_post(edge_x, y, scale, accent, alpha, side, i)
		elif region_type == "sect":
			_draw_front_banner_pillar(edge_x, y, scale, accent, alpha, side, i)
		elif _terrain_has_water(terrain):
			_draw_front_dock_piling(edge_x, y, scale, accent, alpha, side, i)
		elif _terrain_has_forest(terrain):
			_draw_front_tree_trunk(edge_x, y, scale, accent, alpha, side, i)
		elif terrain.contains("snow"):
			_draw_front_frost_post(edge_x, y, scale, accent, alpha, side, i)
		else:
			_draw_front_rock_slab(edge_x, y, scale, accent, alpha, side, i)

func _draw_front_arch_post(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var height := tile_size * (1.56 + float(index % 3) * 0.22) * scale
	var width := tile_size * (0.20 + float(index % 2) * 0.04) * scale
	_draw_ellipse(x, y + tile_size * 0.05 * scale, Vector2(width * 1.15, tile_size * 0.055 * scale), Color(0.0, 0.0, 0.0, alpha * 0.42))
	draw_rect(Rect2(Vector2(x - width * 0.5, y - height), Vector2(width, height)), Color(0.018, 0.011, 0.007, alpha), true)
	draw_line(Vector2(x + side * width * 0.28, y - height + tile_size * 0.18 * scale), Vector2(x + side * width * 0.28, y - tile_size * 0.10 * scale), Color(accent.r, accent.g, accent.b, alpha * 0.18), 1.2)
	var beam_end := x - side * tile_size * (0.86 + float(index % 2) * 0.18) * scale
	draw_line(Vector2(x, y - height * 0.82), Vector2(beam_end, y - height * 0.92), Color(0.025, 0.015, 0.010, alpha * 0.86), 3.0 * scale)
	if index % 2 == 0:
		var lamp := Vector2(x - side * tile_size * 0.26 * scale, y - height * 0.58)
		var pulse := 0.5 + sin(visual_phase * 2.2 + float(index)) * 0.5
		draw_line(lamp + Vector2(0.0, -tile_size * 0.20 * scale), lamp, Color(0.72, 0.42, 0.20, alpha * 0.44), 1.0)
		draw_circle(lamp, tile_size * 0.060 * scale, Color(1.0, 0.58, 0.20, alpha * (0.36 + pulse * 0.18)))

func _draw_front_banner_pillar(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var height := tile_size * (1.80 + float(index % 3) * 0.18) * scale
	draw_rect(Rect2(Vector2(x - tile_size * 0.10 * scale, y - height), Vector2(tile_size * 0.20 * scale, height)), Color(0.020, 0.016, 0.012, alpha), true)
	draw_rect(Rect2(Vector2(x - tile_size * 0.28 * scale, y - height), Vector2(tile_size * 0.56 * scale, tile_size * 0.12 * scale)), Color(accent.r, accent.g, accent.b, alpha * 0.28), true)
	var banner_w := tile_size * 0.42 * scale
	draw_polygon(PackedVector2Array([
		Vector2(x, y - height * 0.86),
		Vector2(x - side * banner_w, y - height * 0.78),
		Vector2(x - side * banner_w * 0.82, y - height * 0.44),
		Vector2(x, y - height * 0.50)
	]), PackedColorArray([
		Color(accent.r, accent.g, accent.b, alpha * 0.80),
		Color(accent.r, accent.g, accent.b, alpha * 0.46),
		Color(0.015, 0.012, 0.009, alpha * 0.72),
		Color(0.018, 0.014, 0.010, alpha * 0.76)
	]))

func _draw_front_dock_piling(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var height := tile_size * (1.14 + float(index % 4) * 0.14) * scale
	_draw_ellipse(x, y + tile_size * 0.06 * scale, Vector2(tile_size * 0.24 * scale, tile_size * 0.055 * scale), Color(0.0, 0.0, 0.0, alpha * 0.34))
	draw_line(Vector2(x, y - height), Vector2(x - side * tile_size * 0.08 * scale, y + tile_size * 0.22 * scale), Color(0.020, 0.016, 0.010, alpha), 3.0 * scale)
	draw_line(Vector2(x - side * tile_size * 0.46 * scale, y - height * 0.66), Vector2(x + side * tile_size * 0.20 * scale, y - height * 0.76), Color(0.045, 0.034, 0.020, alpha * 0.86), 2.0 * scale)
	draw_line(Vector2(x - side * tile_size * 0.40 * scale, y - height * 0.46), Vector2(x + side * tile_size * 0.20 * scale, y - height * 0.56), Color(accent.r, accent.g, accent.b, alpha * 0.22), 1.0)

func _draw_front_tree_trunk(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var height := tile_size * (1.95 + float(index % 3) * 0.24) * scale
	var lean := side * tile_size * (0.16 + float(index % 2) * 0.08) * scale
	_draw_ellipse(x, y + tile_size * 0.08 * scale, Vector2(tile_size * 0.34 * scale, tile_size * 0.070 * scale), Color(0.0, 0.0, 0.0, alpha * 0.40))
	draw_line(Vector2(x, y + tile_size * 0.10 * scale), Vector2(x + lean, y - height), Color(0.004, 0.026, 0.010, alpha + 0.06), 5.0 * scale)
	draw_line(Vector2(x + lean * 0.55, y - height * 0.62), Vector2(x - side * tile_size * 0.72 * scale, y - height * 0.80), Color(0.005, 0.035, 0.012, alpha * 0.88), 2.0 * scale)
	_draw_ellipse(x - side * tile_size * 0.58 * scale, y - height * 0.84, Vector2(tile_size * 0.46 * scale, tile_size * 0.16 * scale), Color(accent.r * 0.22, accent.g * 0.40, accent.b * 0.20, alpha * 0.34))

func _draw_front_frost_post(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var height := tile_size * (1.24 + float(index % 3) * 0.18) * scale
	draw_line(Vector2(x, y), Vector2(x + side * tile_size * 0.10 * scale, y - height), Color(0.54, 0.70, 0.78, alpha * 0.72), 2.6 * scale)
	draw_polygon(PackedVector2Array([
		Vector2(x + side * tile_size * 0.08 * scale, y - height * 0.92),
		Vector2(x - side * tile_size * 0.24 * scale, y - height * 0.62),
		Vector2(x - side * tile_size * 0.10 * scale, y - height * 0.48)
	]), PackedColorArray([
		Color(0.86, 0.96, 1.0, alpha * 0.64),
		Color(accent.r, accent.g, accent.b, alpha * 0.34),
		Color(0.45, 0.58, 0.66, alpha * 0.52)
	]))

func _draw_front_rock_slab(x: float, y: float, scale: float, accent: Color, alpha: float, side: float, index: int) -> void:
	var width := tile_size * (0.52 + float(index % 3) * 0.10) * scale
	var height := tile_size * (0.76 + float((index + 1) % 3) * 0.13) * scale
	_draw_ellipse(x, y + tile_size * 0.06 * scale, Vector2(width * 0.56, tile_size * 0.065 * scale), Color(0.0, 0.0, 0.0, alpha * 0.38))
	draw_polygon(PackedVector2Array([
		Vector2(x - width * 0.46, y),
		Vector2(x - width * 0.28, y - height * 0.72),
		Vector2(x + width * 0.14, y - height),
		Vector2(x + width * 0.52, y - height * 0.18),
		Vector2(x + width * 0.22, y + tile_size * 0.06 * scale)
	]), PackedColorArray([
		Color(0.012, 0.010, 0.008, alpha),
		Color(accent.r, accent.g, accent.b, alpha * 0.18),
		Color(0.045, 0.040, 0.032, alpha * 0.70),
		Color(0.018, 0.016, 0.013, alpha * 0.94),
		Color(0.014, 0.012, 0.010, alpha)
	]))

func _draw_bottom_occluders(accent: Color, region_type: String, terrain: String) -> void:
	for i in range(BOTTOM_OCCLUDER_COUNT):
		var t := float(i) / float(maxi(1, BOTTOM_OCCLUDER_COUNT - 1))
		var seed := int(map_size.x) + i * 197
		var x := fposmod(float(seed * 29), map_size.x + tile_size * 1.4) - tile_size * 0.70
		var y := map_size.y * (0.865 + float((int(seed / 11) % 9)) * 0.012)
		var alpha := BOTTOM_OCCLUDER_ALPHA * (0.62 + t * 0.38)
		if region_type == "city" or region_type == "town":
			var w := tile_size * (0.34 + float(i % 3) * 0.08)
			var h := tile_size * (0.18 + float((i + 1) % 3) * 0.055)
			draw_rect(Rect2(Vector2(x, y - h), Vector2(w, h)), Color(0.035, 0.020, 0.012, alpha), true)
			draw_line(Vector2(x, y - h), Vector2(x + w, y - h - tile_size * 0.045), Color(accent.r, accent.g, accent.b, alpha * 0.58), 1.2)
		elif region_type == "sect":
			var stone_w := tile_size * (0.42 + float(i % 2) * 0.10)
			draw_polygon(PackedVector2Array([
				Vector2(x, y),
				Vector2(x + stone_w * 0.18, y - tile_size * 0.14),
				Vector2(x + stone_w, y - tile_size * 0.08),
				Vector2(x + stone_w * 1.10, y + tile_size * 0.08),
				Vector2(x + stone_w * 0.12, y + tile_size * 0.10)
			]), PackedColorArray([
				Color(0.018, 0.016, 0.013, alpha),
				Color(accent.r, accent.g, accent.b, alpha * 0.46),
				Color(0.030, 0.026, 0.020, alpha * 0.84),
				Color(0.012, 0.010, 0.008, alpha),
				Color(0.014, 0.012, 0.009, alpha)
			]))
		elif _terrain_has_forest(terrain):
			var height := tile_size * (0.32 + float(i % 4) * 0.08)
			draw_line(Vector2(x, map_size.y), Vector2(x + tile_size * 0.14, y - height), Color(0.004, 0.040, 0.015, alpha + 0.06), 2.0)
			draw_line(Vector2(x + tile_size * 0.14, y - height * 0.68), Vector2(x + tile_size * 0.46, y - height * 0.82), Color(accent.r, accent.g, accent.b, alpha * 0.54), 1.2)
		elif terrain.contains("snow"):
			_draw_ellipse(x + tile_size * 0.18, y, Vector2(tile_size * 0.24, tile_size * 0.065), Color(0.82, 0.94, 1.0, alpha * 0.72))
			draw_line(Vector2(x, y), Vector2(x + tile_size * 0.42, y - tile_size * 0.035), Color(1.0, 1.0, 1.0, alpha * 0.40), 1.0)
		else:
			_draw_ellipse(x + tile_size * 0.18, y, Vector2(tile_size * (0.18 + float(i % 3) * 0.04), tile_size * 0.052), Color(0.0, 0.0, 0.0, alpha))
			if i % 3 == 0:
				draw_line(Vector2(x + tile_size * 0.10, y), Vector2(x + tile_size * 0.24, y - tile_size * 0.20), Color(accent.r, accent.g, accent.b, alpha * 0.58), 1.2)

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
