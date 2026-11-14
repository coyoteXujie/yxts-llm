extends RefCounted
class_name ShopInteriorRenderer

const RICH_SHOP_INTERIOR_ENABLED := true
const SHOP_INTERIOR_TEXTURE_PRIORITY := true
const SHOP_INTERIOR_TEXTURE_ALPHA := 1.0
const SHOP_INTERIOR_TEXTURE_PROCEDURAL_GOODS_ENABLED := false
const SHOP_INTERIOR_TEXTURE_SERVICE_ZONE_ALPHA := 0.18
const SHOP_INTERIOR_TEXTURE_LIGHT_ALPHA := 0.22
const SHOP_INTERIOR_TEXTURE_FOREGROUND_FRAME_ALPHA := 0.22
const SHOP_INTERIOR_BACK_WALL_RATIO := 0.48
const SHOP_INTERIOR_COUNTER_ALPHA := 0.92
const SHOP_INTERIOR_SHELF_ALPHA := 0.82
const SHOP_INTERIOR_THEME_PROP_ALPHA := 0.88
const SHOP_INTERIOR_LIGHT_ALPHA := 0.32
const SHOP_INTERIOR_SIGNBOARD_ALPHA := 0.78
const SHOP_INTERIOR_DEPTH_ARCH_ALPHA := 0.46
const SHOP_INTERIOR_SERVICE_ZONE_ALPHA := 0.34
const SHOP_INTERIOR_FLOOR_LANE_ALPHA := 0.24
const SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA := 0.48
const SHOP_INTERIOR_PERSPECTIVE_GUIDE_COUNT := 10
const SHOP_INTERIOR_DISPLAY_CLUSTER_COUNT := 6
const SHOP_INTERIOR_HANGING_DECOR_COUNT := 5
const SHOP_INTERIOR_COUNTER_ITEM_COUNT := 7
const SHOP_INTERIOR_FOREGROUND_PROP_COUNT := 8
const SHOP_INTERIOR_BACKGROUND_NPC_COUNT := 4
const SHOP_INTERIOR_BACKGROUND_NPC_ALPHA := 0.42

static func _draw_ellipse_poly(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	canvas.draw_polygon(points, colors)

static func _draw_stage_vertical_gradient(canvas: CanvasItem, rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]), PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

static func _draw_cover_texture(canvas: CanvasItem, texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale: float = maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var source_size := rect.size / scale
	var source_pos := (texture_size - source_size) * 0.5
	canvas.draw_texture_rect_region(texture, rect, Rect2(source_pos, source_size), modulate)

static func draw_shop_overlay(canvas: CanvasItem, size: Vector2, shop: Dictionary, shop_id: String, interior_texture: Texture2D, tile_size: int, map_width: int) -> void:
	var accent: Color = shop.get("accent", Color(0.80, 0.54, 0.28))
	if SHOP_INTERIOR_TEXTURE_PRIORITY and interior_texture != null:
		_draw_cover_texture(canvas, interior_texture, Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, SHOP_INTERIOR_TEXTURE_ALPHA))
		if RICH_SHOP_INTERIOR_ENABLED:
			_draw_shop_texture_overlay(canvas, tile_size, size, shop_id, accent)
		return
	if RICH_SHOP_INTERIOR_ENABLED:
		_draw_rich_shop_interior(canvas, tile_size, map_width, size, shop_id, accent)
		return
	_draw_legacy_shop_overlay(canvas, tile_size, map_width, size, accent)

static func _draw_shop_texture_overlay(canvas: CanvasItem, tile_size: int, size: Vector2, shop_id: String, accent: Color) -> void:
	var wall_bottom := size.y * SHOP_INTERIOR_BACK_WALL_RATIO
	_draw_shop_texture_service_lanes(canvas, tile_size, size, wall_bottom, accent)
	if SHOP_INTERIOR_TEXTURE_PROCEDURAL_GOODS_ENABLED:
		_draw_shop_counter_goods(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_texture_lighting(canvas, tile_size, size, wall_bottom, accent)
	_draw_shop_texture_foreground_frame(canvas, tile_size, size, accent)

static func _draw_shop_texture_service_lanes(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var service_center := Vector2(size.x * 0.50, wall_bottom + tile_size * 0.62)
	_draw_ellipse_poly(canvas, service_center, Vector2(size.x * 0.24, tile_size * 0.26), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_TEXTURE_SERVICE_ZONE_ALPHA * 0.28))
	var sides: Array[float] = [-1.0, 1.0]
	for side in sides:
		var start := Vector2(size.x * (0.50 + side * 0.16), wall_bottom + tile_size * 0.18)
		var end := Vector2(size.x * (0.50 + side * 0.36), size.y - tile_size * 0.48)
		canvas.draw_line(start, end, Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_TEXTURE_SERVICE_ZONE_ALPHA * 0.34), 1.2)

static func _draw_shop_texture_lighting(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(3):
		var x := size.x * (0.28 + float(i) * 0.22)
		_draw_ellipse_poly(canvas, Vector2(x, wall_bottom + tile_size * 0.05), Vector2(tile_size * 1.18, tile_size * 0.22), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_TEXTURE_LIGHT_ALPHA * 0.20))
	_draw_stage_vertical_gradient(canvas, Rect2(Vector2(0.0, 0.0), size), Color(0.0, 0.0, 0.0, 0.045), Color(0.0, 0.0, 0.0, SHOP_INTERIOR_TEXTURE_LIGHT_ALPHA))

static func _draw_shop_texture_foreground_frame(canvas: CanvasItem, tile_size: int, size: Vector2, accent: Color) -> void:
	canvas.draw_rect(Rect2(Vector2(0.0, tile_size * 0.26), Vector2(tile_size * 0.34, size.y - tile_size * 0.52)), Color(0.010, 0.006, 0.004, SHOP_INTERIOR_TEXTURE_FOREGROUND_FRAME_ALPHA), true)
	canvas.draw_rect(Rect2(Vector2(size.x - tile_size * 0.34, tile_size * 0.26), Vector2(tile_size * 0.34, size.y - tile_size * 0.52)), Color(0.010, 0.006, 0.004, SHOP_INTERIOR_TEXTURE_FOREGROUND_FRAME_ALPHA), true)
	var frame_x_positions: Array[float] = [tile_size * 1.10, size.x - tile_size * 1.10]
	for x in frame_x_positions:
		canvas.draw_line(Vector2(x, tile_size * 0.52), Vector2(x, size.y - tile_size * 0.46), Color(0.08, 0.042, 0.022, SHOP_INTERIOR_TEXTURE_FOREGROUND_FRAME_ALPHA * 0.74), 2.2)
		canvas.draw_line(Vector2(x, tile_size * 0.66), Vector2(x, size.y - tile_size * 0.72), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_TEXTURE_FOREGROUND_FRAME_ALPHA * 0.18), 1.0)

static func _draw_legacy_shop_overlay(canvas: CanvasItem, tile_size: int, map_width: int, size: Vector2, accent: Color) -> void:
	canvas.draw_rect(Rect2(0, 0, size.x, tile_size * 2.0), Color(0.18, 0.10, 0.06, 0.48), true)
	canvas.draw_line(Vector2(tile_size, tile_size * 2.05), Vector2(size.x - tile_size, tile_size * 2.05), accent.darkened(0.25), 3.0)
	for x in range(3, map_width - 3, 5):
		var hanger := Vector2(x * tile_size + tile_size * 0.5, tile_size * 1.2)
		canvas.draw_line(hanger + Vector2(0, -10), hanger + Vector2(0, 8), Color(0.88, 0.70, 0.38, 0.45), 1.2)
		canvas.draw_circle(hanger + Vector2(0, 11), 4.0, accent.lightened(0.18))
	canvas.draw_rect(Rect2(Vector2(tile_size * 2, tile_size * 3), Vector2(size.x - tile_size * 4, tile_size * 0.34)), Color(0.86, 0.64, 0.34, 0.20), true)
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.025, 0.015, 0.25), false, 3.0)

static func _draw_rich_shop_interior(canvas: CanvasItem, tile_size: int, map_width: int, size: Vector2, shop_id: String, accent: Color) -> void:
	var wall_bottom := size.y * SHOP_INTERIOR_BACK_WALL_RATIO
	var floor_rect := Rect2(Vector2(0.0, wall_bottom), Vector2(size.x, size.y - wall_bottom))
	_draw_shop_wall(canvas, tile_size, map_width, size, wall_bottom, accent)
	_draw_shop_back_sign(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_hanging_decor(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_floor(canvas, tile_size, size, floor_rect, accent)
	_draw_shop_service_lanes(canvas, tile_size, size, wall_bottom, accent)
	_draw_shop_background_figures(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_counter(canvas, tile_size, size, wall_bottom, accent)
	_draw_shop_counter_goods(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_shelves(canvas, tile_size, size, wall_bottom, accent)
	_draw_shop_theme_props(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_display_clusters(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_foreground_merchandise(canvas, tile_size, size, wall_bottom, shop_id, accent)
	_draw_shop_lighting(canvas, tile_size, size, wall_bottom, accent)
	_draw_shop_foreground_frame(canvas, tile_size, size, accent)

static func _draw_shop_wall(canvas: CanvasItem, tile_size: int, map_width: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	_draw_stage_vertical_gradient(
		canvas,
		Rect2(Vector2.ZERO, Vector2(size.x, wall_bottom)),
		Color(0.22, 0.13, 0.075, 0.94),
		Color(0.39, 0.25, 0.145, 0.92)
	)
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, tile_size * 0.62)), Color(0.055, 0.032, 0.020, 0.72), true)
	for x in range(2, map_width - 1, 5):
		var beam_x := x * tile_size
		canvas.draw_rect(Rect2(Vector2(beam_x, tile_size * 0.10), Vector2(tile_size * 0.34, wall_bottom + tile_size * 0.26)), Color(0.13, 0.070, 0.038, 0.58), true)
		canvas.draw_line(Vector2(beam_x + tile_size * 0.08, tile_size * 0.72), Vector2(beam_x + tile_size * 0.12, wall_bottom - tile_size * 0.32), Color(0.72, 0.48, 0.24, 0.16), 1.1)
	for i in range(4):
		var y := tile_size * (1.00 + float(i) * 0.88)
		canvas.draw_line(Vector2(tile_size * 1.1, y), Vector2(size.x - tile_size * 1.1, y - tile_size * 0.10), Color(0.09, 0.050, 0.030, 0.36), 2.0)
		canvas.draw_line(Vector2(tile_size * 1.1, y + tile_size * 0.10), Vector2(size.x - tile_size * 1.1, y), Color(accent.r, accent.g, accent.b, 0.09), 1.0)
	canvas.draw_rect(Rect2(Vector2(tile_size * 1.0, wall_bottom - tile_size * 0.26), Vector2(size.x - tile_size * 2.0, tile_size * 0.22)), Color(0.08, 0.045, 0.025, 0.54), true)
	_draw_shop_depth_arches(canvas, tile_size, size, wall_bottom, accent)

static func _draw_shop_depth_arches(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var arch_alpha := SHOP_INTERIOR_DEPTH_ARCH_ALPHA
	for side in [-1.0, 1.0]:
		var x := size.x * (0.08 if side < 0.0 else 0.92)
		var pillar_w := tile_size * 0.38
		canvas.draw_rect(Rect2(Vector2(x - pillar_w * 0.5, tile_size * 0.54), Vector2(pillar_w, wall_bottom + tile_size * 0.52)), Color(0.055, 0.030, 0.018, arch_alpha), true)
		canvas.draw_line(Vector2(x + side * tile_size * 0.14, tile_size * 0.88), Vector2(size.x * 0.50, tile_size * 0.42), Color(accent.r, accent.g, accent.b, arch_alpha * 0.32), 3.0)
		canvas.draw_line(Vector2(x + side * tile_size * 0.42, wall_bottom - tile_size * 0.22), Vector2(size.x * 0.50, wall_bottom - tile_size * 0.64), Color(0.025, 0.014, 0.010, arch_alpha * 0.62), 2.6)
	for i in range(3):
		var y := tile_size * (0.64 + float(i) * 0.56)
		canvas.draw_line(Vector2(size.x * 0.10, y), Vector2(size.x * 0.90, y - tile_size * 0.10), Color(0.94, 0.68, 0.34, arch_alpha * 0.14), 1.0)

static func _draw_shop_back_sign(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	var center := Vector2(size.x * 0.50, wall_bottom - tile_size * 1.26)
	var sign_size := Vector2(tile_size * 4.55, tile_size * 0.78)
	var sign_rect := Rect2(center - sign_size * 0.5, sign_size)
	canvas.draw_rect(sign_rect.grow(tile_size * 0.14), Color(0.025, 0.014, 0.008, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.34), true)
	canvas.draw_rect(sign_rect, Color(0.16, 0.075, 0.030, SHOP_INTERIOR_SIGNBOARD_ALPHA), true)
	canvas.draw_rect(sign_rect.grow(-tile_size * 0.08), Color(accent.r * 0.42, accent.g * 0.34, accent.b * 0.22, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.72), true)
	for i in range(_shop_sign_stroke_count(shop_id)):
		var t := (float(i) + 0.5) / float(_shop_sign_stroke_count(shop_id))
		var x := lerpf(sign_rect.position.x + tile_size * 0.48, sign_rect.end.x - tile_size * 0.48, t)
		canvas.draw_line(Vector2(x, sign_rect.position.y + tile_size * 0.16), Vector2(x - tile_size * 0.16, sign_rect.end.y - tile_size * 0.14), Color(1.0, 0.82, 0.42, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.58), 1.6)
		if i % 2 == 0:
			canvas.draw_line(Vector2(x - tile_size * 0.16, sign_rect.position.y + tile_size * 0.43), Vector2(x + tile_size * 0.17, sign_rect.position.y + tile_size * 0.35), Color(0.98, 0.72, 0.34, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.38), 1.1)
	canvas.draw_line(sign_rect.position + Vector2(tile_size * 0.28, sign_rect.size.y + tile_size * 0.07), sign_rect.end - Vector2(tile_size * 0.28, -tile_size * 0.06), Color(0.0, 0.0, 0.0, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.30), 1.4)
	_draw_ellipse_poly(canvas, center + Vector2(0.0, tile_size * 0.62), Vector2(tile_size * 2.52, tile_size * 0.28), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_SIGNBOARD_ALPHA * 0.14))

static func _shop_sign_stroke_count(shop_id: String) -> int:
	match shop_id:
		"blacksmith":
			return 4
		"medicine":
			return 5
		"inn":
			return 3
		"tailor":
			return 4
		"teahouse":
			return 5
		_:
			return 6

static func _draw_shop_hanging_decor(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	for i in range(SHOP_INTERIOR_HANGING_DECOR_COUNT):
		var t := (float(i) + 0.5) / float(SHOP_INTERIOR_HANGING_DECOR_COUNT)
		var x := lerpf(size.x * 0.16, size.x * 0.84, t)
		var y := wall_bottom - tile_size * (1.92 + float(i % 2) * 0.18)
		canvas.draw_line(Vector2(x, tile_size * 0.72), Vector2(x, y - tile_size * 0.20), Color(0.82, 0.60, 0.34, 0.24), 1.0)
		match shop_id:
			"blacksmith":
				canvas.draw_line(Vector2(x - tile_size * 0.18, y - tile_size * 0.10), Vector2(x + tile_size * 0.22, y + tile_size * 0.28), Color(0.76, 0.76, 0.70, 0.50), 2.0)
				canvas.draw_line(Vector2(x + tile_size * 0.14, y - tile_size * 0.20), Vector2(x - tile_size * 0.12, y + tile_size * 0.26), Color(accent.r, accent.g, accent.b, 0.36), 1.4)
			"medicine":
				canvas.draw_line(Vector2(x, y - tile_size * 0.28), Vector2(x + tile_size * 0.06, y + tile_size * 0.30), Color(0.22, 0.44, 0.20, 0.52), 1.4)
				for leaf in range(3):
					canvas.draw_circle(Vector2(x + tile_size * (0.06 + leaf * 0.055), y - tile_size * (0.10 - leaf * 0.10)), 3.2, Color(accent.r, accent.g, accent.b, 0.42))
			"tailor":
				canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.16, y - tile_size * 0.30), Vector2(tile_size * 0.32, tile_size * 0.58)), Color(accent.r, accent.g, accent.b, 0.40), true)
				canvas.draw_line(Vector2(x - tile_size * 0.14, y), Vector2(x + tile_size * 0.16, y - tile_size * 0.18), Color(0.98, 0.82, 0.94, 0.36), 1.2)
			"inn", "teahouse":
				canvas.draw_circle(Vector2(x, y), tile_size * 0.13, Color(accent.r, accent.g, accent.b, 0.50))
				canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.11, y - tile_size * 0.04), Vector2(tile_size * 0.22, tile_size * 0.26)), Color(0.44, 0.20, 0.08, 0.58), true)
			_:
				canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.18, y - tile_size * 0.18), Vector2(tile_size * 0.36, tile_size * 0.28)), Color(0.20, 0.10, 0.05, 0.58), true)
				canvas.draw_circle(Vector2(x + tile_size * 0.12, y - tile_size * 0.24), 4.5, Color(accent.r, accent.g, accent.b, 0.44))

static func _draw_shop_floor(canvas: CanvasItem, tile_size: int, size: Vector2, floor_rect: Rect2, accent: Color) -> void:
	_draw_stage_vertical_gradient(
		canvas,
		floor_rect,
		Color(0.45, 0.32, 0.19, 0.90),
		Color(0.20, 0.12, 0.075, 0.94)
	)
	var top_y := floor_rect.position.y
	var bottom_y := floor_rect.end.y
	for i in range(9):
		var t := float(i) / 8.0
		var y := lerpf(top_y + tile_size * 0.15, bottom_y - tile_size * 0.44, t * t)
		canvas.draw_line(Vector2(tile_size * (0.8 - t * 0.7), y), Vector2(size.x - tile_size * (0.8 - t * 0.7), y - tile_size * 0.10), Color(0.09, 0.052, 0.032, 0.25), 1.2 + t * 1.8)
	for i in range(12):
		var t := float(i) / 11.0
		var x := lerpf(tile_size * 0.7, size.x - tile_size * 0.7, t)
		canvas.draw_line(Vector2(x, bottom_y), Vector2(lerpf(size.x * 0.44, size.x * 0.56, t), top_y + tile_size * 0.05), Color(0.12, 0.070, 0.045, 0.15), 1.0)
	for i in range(SHOP_INTERIOR_PERSPECTIVE_GUIDE_COUNT):
		var t := float(i) / float(maxi(1, SHOP_INTERIOR_PERSPECTIVE_GUIDE_COUNT - 1))
		var left := lerpf(size.x * 0.10, size.x * 0.38, t)
		var right := lerpf(size.x * 0.90, size.x * 0.62, t)
		var y := lerpf(bottom_y - tile_size * 0.54, top_y + tile_size * 0.52, t * t)
		canvas.draw_line(Vector2(left, y + tile_size * 0.12), Vector2(right, y - tile_size * 0.08), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_FLOOR_LANE_ALPHA * (1.0 - t * 0.38)), 1.1 + (1.0 - t) * 1.5)
	_draw_ellipse_poly(canvas, Vector2(size.x * 0.50, top_y + tile_size * 2.35), Vector2(size.x * 0.33, tile_size * 0.34), Color(accent.r, accent.g, accent.b, 0.10))
	canvas.draw_rect(Rect2(Vector2(0.0, size.y - tile_size * 1.05), Vector2(size.x, tile_size * 1.10)), Color(0.020, 0.014, 0.010, 0.38), true)

static func _draw_shop_service_lanes(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var service_center := Vector2(size.x * 0.50, wall_bottom + tile_size * 1.72)
	_draw_ellipse_poly(canvas, service_center, Vector2(size.x * 0.25, tile_size * 0.34), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_SERVICE_ZONE_ALPHA * 0.34))
	_draw_ellipse_poly(canvas, Vector2(size.x * 0.50, size.y - tile_size * 1.46), Vector2(size.x * 0.34, tile_size * 0.26), Color(0.95, 0.78, 0.42, SHOP_INTERIOR_SERVICE_ZONE_ALPHA * 0.20))
	for side in [-1.0, 1.0]:
		var start := Vector2(size.x * 0.50 + side * tile_size * 1.25, size.y - tile_size * 1.16)
		var end := Vector2(size.x * 0.50 + side * tile_size * 0.52, wall_bottom + tile_size * 0.54)
		canvas.draw_line(start, end, Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_SERVICE_ZONE_ALPHA * 0.38), 1.8)
		canvas.draw_line(start + Vector2(side * tile_size * 0.18, tile_size * 0.08), end + Vector2(side * tile_size * 0.08, -tile_size * 0.02), Color(0.0, 0.0, 0.0, SHOP_INTERIOR_SERVICE_ZONE_ALPHA * 0.28), 1.2)

static func _draw_shop_background_figures(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	for i in range(SHOP_INTERIOR_BACKGROUND_NPC_COUNT):
		var t := (float(i) + 0.5) / float(SHOP_INTERIOR_BACKGROUND_NPC_COUNT)
		var x := lerpf(size.x * 0.22, size.x * 0.78, t) + sin(float(i) * 1.37) * tile_size * 0.18
		var y := wall_bottom - tile_size * (0.34 + float(i % 2) * 0.11)
		var scale := 0.70 + float(i % 3) * 0.06
		var side := -1.0 if i % 2 == 0 else 1.0
		var alpha := SHOP_INTERIOR_BACKGROUND_NPC_ALPHA * (0.72 + float(i % 2) * 0.18)
		_draw_shop_background_figure(canvas, tile_size, Vector2(x, y), scale, side, shop_id, accent, alpha, i)

static func _draw_shop_background_figure(canvas: CanvasItem, tile_size: int, pos: Vector2, scale: float, side: float, shop_id: String, accent: Color, alpha: float, index: int) -> void:
	var foot := pos
	var height := tile_size * 1.08 * scale
	var body_w := tile_size * 0.28 * scale
	var head := foot + Vector2(side * tile_size * 0.03 * scale, -height * 0.92)
	var shoulder := foot + Vector2(0.0, -height * 0.68)
	var hip := foot + Vector2(-side * tile_size * 0.03 * scale, -height * 0.23)
	var cloth := Color(accent.r * 0.62, accent.g * 0.58, accent.b * 0.50, alpha)
	var ink := Color(0.028, 0.018, 0.012, alpha * 0.96)
	_draw_ellipse_poly(canvas, foot + Vector2(0.0, tile_size * 0.06 * scale), Vector2(tile_size * 0.34, tile_size * 0.07) * scale, Color(0.0, 0.0, 0.0, alpha * 0.26))
	canvas.draw_polygon(PackedVector2Array([
		shoulder + Vector2(-body_w, -tile_size * 0.04 * scale),
		shoulder + Vector2(body_w * 0.88, -tile_size * 0.02 * scale),
		hip + Vector2(body_w * 0.74, tile_size * 0.06 * scale),
		foot + Vector2(body_w * 0.36, 0.0),
		foot + Vector2(-body_w * 0.72, -tile_size * 0.04 * scale),
		hip + Vector2(-body_w * 0.82, 0.0)
	]), PackedColorArray([
		cloth.lightened(0.12),
		cloth,
		ink.lightened(0.18),
		ink,
		ink.lightened(0.08),
		cloth.darkened(0.18)
	]))
	canvas.draw_circle(head, tile_size * 0.12 * scale, Color(0.12, 0.07, 0.045, alpha))
	canvas.draw_line(head + Vector2(-side * tile_size * 0.05 * scale, -tile_size * 0.08 * scale), head + Vector2(side * tile_size * 0.09 * scale, tile_size * 0.01 * scale), Color(0.02, 0.014, 0.010, alpha), 1.2)
	var hand := shoulder + Vector2(side * body_w * 1.60, height * 0.20)
	canvas.draw_line(shoulder + Vector2(side * body_w * 0.72, tile_size * 0.06 * scale), hand, Color(0.045, 0.030, 0.020, alpha), maxf(1.0, tile_size * 0.030 * scale))
	_draw_shop_background_figure_prop(canvas, tile_size, hand, scale, side, shop_id, accent, alpha, index)

static func _draw_shop_background_figure_prop(canvas: CanvasItem, tile_size: int, hand: Vector2, scale: float, side: float, shop_id: String, accent: Color, alpha: float, index: int) -> void:
	match shop_id:
		"blacksmith":
			var hammer_tip := hand + Vector2(side * tile_size * 0.24, -tile_size * 0.28) * scale
			canvas.draw_line(hand, hammer_tip, Color(0.78, 0.70, 0.56, alpha * 0.82), maxf(1.0, tile_size * 0.022 * scale))
			canvas.draw_rect(Rect2(hammer_tip - Vector2(tile_size * 0.11, tile_size * 0.04) * scale, Vector2(tile_size * 0.22, tile_size * 0.08) * scale), Color(0.12, 0.10, 0.08, alpha), true)
		"medicine":
			canvas.draw_rect(Rect2(hand + Vector2(side * tile_size * 0.02, -tile_size * 0.13) * scale, Vector2(tile_size * 0.10, tile_size * 0.18) * scale), Color(0.16, 0.34, 0.18, alpha * 0.84), true)
			canvas.draw_circle(hand + Vector2(side * tile_size * 0.14, -tile_size * 0.01) * scale, tile_size * 0.05 * scale, Color(accent.r, accent.g, accent.b, alpha * 0.58))
		"inn":
			canvas.draw_line(hand + Vector2(-side * tile_size * 0.18, tile_size * 0.02) * scale, hand + Vector2(side * tile_size * 0.22, -tile_size * 0.02) * scale, Color(0.42, 0.22, 0.10, alpha), maxf(1.0, tile_size * 0.020 * scale))
			canvas.draw_circle(hand + Vector2(side * tile_size * 0.12, -tile_size * 0.09) * scale, tile_size * 0.048 * scale, Color(0.86, 0.62, 0.30, alpha * 0.72))
		"tailor":
			var cloth_size := Vector2(tile_size * 0.30, tile_size * 0.22) * scale
			var cloth_pos := hand + Vector2(side * tile_size * 0.02, -tile_size * 0.16) * scale
			if side < 0.0:
				cloth_pos.x -= cloth_size.x
			canvas.draw_rect(Rect2(cloth_pos, cloth_size), Color(accent.r, accent.g, accent.b, alpha * 0.62), true)
		"teahouse":
			canvas.draw_circle(hand + Vector2(side * tile_size * 0.08, -tile_size * 0.04) * scale, tile_size * 0.075 * scale, Color(0.20, 0.12, 0.06, alpha * 0.88))
			canvas.draw_line(hand + Vector2(side * tile_size * 0.13, -tile_size * 0.06) * scale, hand + Vector2(side * tile_size * 0.24, -tile_size * 0.12) * scale, Color(0.90, 0.68, 0.36, alpha * 0.60), 1.0)
		_:
			canvas.draw_circle(hand + Vector2(side * tile_size * 0.08, -tile_size * 0.02) * scale, tile_size * 0.09 * scale, Color(0.32, 0.18, 0.08, alpha * 0.76))
			canvas.draw_circle(hand + Vector2(side * tile_size * 0.13, -tile_size * 0.11) * scale, tile_size * 0.034 * scale, Color(accent.r, accent.g, accent.b, alpha * (0.48 + float(index % 2) * 0.14)))

static func _draw_shop_counter(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var counter_rect := Rect2(Vector2(size.x * 0.13, wall_bottom - tile_size * 1.38), Vector2(size.x * 0.74, tile_size * 1.48))
	canvas.draw_rect(counter_rect.grow(5.0), Color(0.035, 0.020, 0.012, SHOP_INTERIOR_COUNTER_ALPHA * 0.36), true)
	canvas.draw_rect(counter_rect, Color(0.25, 0.13, 0.065, SHOP_INTERIOR_COUNTER_ALPHA), true)
	canvas.draw_rect(Rect2(counter_rect.position, Vector2(counter_rect.size.x, tile_size * 0.23)), Color(0.56, 0.32, 0.14, SHOP_INTERIOR_COUNTER_ALPHA * 0.82), true)
	canvas.draw_polygon(PackedVector2Array([
		counter_rect.position + Vector2(tile_size * 0.20, tile_size * 0.22),
		counter_rect.position + Vector2(counter_rect.size.x - tile_size * 0.20, tile_size * 0.18),
		counter_rect.end + Vector2(-tile_size * 0.42, tile_size * 0.34),
		counter_rect.end + Vector2(-counter_rect.size.x + tile_size * 0.42, tile_size * 0.30)
	]), PackedColorArray([
		Color(0.64, 0.38, 0.16, SHOP_INTERIOR_COUNTER_ALPHA * 0.48),
		Color(0.76, 0.48, 0.22, SHOP_INTERIOR_COUNTER_ALPHA * 0.42),
		Color(0.22, 0.10, 0.045, SHOP_INTERIOR_COUNTER_ALPHA * 0.30),
		Color(0.18, 0.08, 0.035, SHOP_INTERIOR_COUNTER_ALPHA * 0.34)
	]))
	for i in range(7):
		var x := counter_rect.position.x + counter_rect.size.x * (float(i) + 0.5) / 7.0
		canvas.draw_line(Vector2(x, counter_rect.position.y + tile_size * 0.18), Vector2(x - tile_size * 0.06, counter_rect.end.y - tile_size * 0.08), Color(0.08, 0.045, 0.026, 0.34), 1.2)
	canvas.draw_line(counter_rect.position + Vector2(tile_size * 0.28, tile_size * 0.44), counter_rect.position + Vector2(counter_rect.size.x - tile_size * 0.28, tile_size * 0.34), Color(accent.r, accent.g, accent.b, 0.30), 1.5)

static func _draw_shop_counter_goods(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	var top_y := wall_bottom - tile_size * 1.08
	for i in range(SHOP_INTERIOR_COUNTER_ITEM_COUNT):
		var t := (float(i) + 0.5) / float(SHOP_INTERIOR_COUNTER_ITEM_COUNT)
		var x := lerpf(size.x * 0.22, size.x * 0.78, t)
		var y := top_y - tile_size * (0.03 + float(i % 2) * 0.04)
		match shop_id:
			"blacksmith":
				canvas.draw_line(Vector2(x - tile_size * 0.20, y + tile_size * 0.10), Vector2(x + tile_size * 0.24, y - tile_size * 0.10), Color(0.78, 0.78, 0.72, 0.56), 2.0)
				canvas.draw_circle(Vector2(x - tile_size * 0.24, y + tile_size * 0.12), 2.6, Color(accent.r, accent.g, accent.b, 0.42))
			"medicine":
				canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.07, y - tile_size * 0.16), Vector2(tile_size * 0.14, tile_size * 0.22)), Color(0.30, 0.17, 0.08, 0.64), true)
				canvas.draw_circle(Vector2(x, y - tile_size * 0.18), 3.2, Color(accent.r, accent.g, accent.b, 0.44))
			"tailor":
				canvas.draw_line(Vector2(x - tile_size * 0.14, y + tile_size * 0.08), Vector2(x + tile_size * 0.17, y - tile_size * 0.10), Color(accent.r, accent.g, accent.b, 0.58), 3.0)
				canvas.draw_line(Vector2(x - tile_size * 0.12, y - tile_size * 0.02), Vector2(x + tile_size * 0.15, y + tile_size * 0.06), Color(0.96, 0.78, 0.90, 0.36), 1.2)
			"inn", "teahouse":
				canvas.draw_circle(Vector2(x, y), tile_size * 0.075, Color(0.42, 0.18, 0.08, 0.70))
				canvas.draw_circle(Vector2(x + tile_size * 0.08, y - tile_size * 0.05), tile_size * 0.040, Color(accent.r, accent.g, accent.b, 0.48))
			_:
				canvas.draw_rect(Rect2(Vector2(x - tile_size * 0.12, y - tile_size * 0.12), Vector2(tile_size * 0.24, tile_size * 0.18)), Color(0.28, 0.14, 0.06, 0.66), true)
				canvas.draw_circle(Vector2(x + tile_size * 0.06, y - tile_size * 0.16), 3.8, Color(accent.r, accent.g, accent.b, 0.46))

static func _draw_shop_shelves(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for side in [-1.0, 1.0]:
		var x := size.x * (0.16 if side < 0.0 else 0.84)
		var shelf := Rect2(Vector2(x - tile_size * 2.05, tile_size * 1.26), Vector2(tile_size * 4.10, wall_bottom - tile_size * 2.05))
		canvas.draw_rect(shelf, Color(0.12, 0.065, 0.035, SHOP_INTERIOR_SHELF_ALPHA), true)
		canvas.draw_rect(shelf, Color(0.80, 0.55, 0.28, SHOP_INTERIOR_SHELF_ALPHA * 0.38), false, 1.5)
		for row in range(3):
			var y := shelf.position.y + tile_size * (0.62 + float(row) * 1.02)
			canvas.draw_line(Vector2(shelf.position.x + tile_size * 0.18, y), Vector2(shelf.end.x - tile_size * 0.18, y - tile_size * 0.04), Color(0.62, 0.38, 0.18, SHOP_INTERIOR_SHELF_ALPHA * 0.64), 2.0)
			for col in range(4):
				var px := shelf.position.x + tile_size * (0.54 + float(col) * 0.86)
				var item_color := accent.lightened(0.10 + float((row + col) % 3) * 0.08)
				canvas.draw_circle(Vector2(px, y - tile_size * 0.20), 3.8 + float((row + col) % 2), Color(item_color.r, item_color.g, item_color.b, 0.55))

static func _draw_shop_theme_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	match shop_id:
		"blacksmith":
			_draw_shop_blacksmith_props(canvas, tile_size, size, wall_bottom, accent)
		"medicine":
			_draw_shop_medicine_props(canvas, tile_size, size, wall_bottom, accent)
		"inn":
			_draw_shop_inn_props(canvas, tile_size, size, wall_bottom, accent)
		"tailor":
			_draw_shop_tailor_props(canvas, tile_size, size, wall_bottom, accent)
		"market":
			_draw_shop_market_props(canvas, tile_size, size, wall_bottom, accent)
		"teahouse":
			_draw_shop_teahouse_props(canvas, tile_size, size, wall_bottom, accent)
		_:
			_draw_shop_market_props(canvas, tile_size, size, wall_bottom, accent)

static func _draw_shop_display_clusters(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	for i in range(SHOP_INTERIOR_DISPLAY_CLUSTER_COUNT):
		var side := -1.0 if i % 2 == 0 else 1.0
		var lane := float(i / 2)
		var x := size.x * (0.22 if side < 0.0 else 0.78) + side * lane * tile_size * 0.34
		var y := wall_bottom + tile_size * (0.72 + lane * 0.64)
		var base := Vector2(x, y)
		_draw_ellipse_poly(canvas, base + Vector2(0.0, tile_size * 0.22), Vector2(tile_size * 0.72, tile_size * 0.16), Color(0.0, 0.0, 0.0, 0.20))
		match shop_id:
			"blacksmith":
				canvas.draw_line(base + Vector2(-tile_size * 0.42, -tile_size * 0.18), base + Vector2(tile_size * 0.42, -tile_size * 0.38), Color(0.74, 0.74, 0.68, 0.54), 2.0)
				canvas.draw_line(base + Vector2(-tile_size * 0.22, -tile_size * 0.36), base + Vector2(tile_size * 0.34, tile_size * 0.06), Color(accent.r, accent.g, accent.b, 0.34), 1.4)
			"medicine":
				canvas.draw_circle(base + Vector2(-tile_size * 0.20, -tile_size * 0.16), tile_size * 0.14, Color(0.20, 0.42, 0.18, 0.58))
				canvas.draw_rect(Rect2(base + Vector2(tile_size * 0.02, -tile_size * 0.34), Vector2(tile_size * 0.25, tile_size * 0.38)), Color(accent.r, accent.g, accent.b, 0.38), true)
			"tailor":
				canvas.draw_line(base + Vector2(-tile_size * 0.26, -tile_size * 0.42), base + Vector2(tile_size * 0.20, tile_size * 0.10), Color(accent.r, accent.g, accent.b, 0.52), 4.2)
				canvas.draw_line(base + Vector2(tile_size * 0.04, -tile_size * 0.38), base + Vector2(tile_size * 0.42, tile_size * 0.08), Color(0.96, 0.78, 0.90, 0.36), 2.6)
			"inn", "teahouse":
				canvas.draw_circle(base + Vector2(-tile_size * 0.14, -tile_size * 0.16), tile_size * 0.16, Color(0.42, 0.18, 0.08, 0.68))
				canvas.draw_circle(base + Vector2(tile_size * 0.18, -tile_size * 0.20), tile_size * 0.10, Color(accent.r, accent.g, accent.b, 0.46))
			_:
				canvas.draw_rect(Rect2(base + Vector2(-tile_size * 0.26, -tile_size * 0.30), Vector2(tile_size * 0.52, tile_size * 0.34)), Color(0.30, 0.16, 0.07, 0.62), true)
				canvas.draw_circle(base + Vector2(tile_size * 0.04, -tile_size * 0.38), tile_size * 0.12, Color(accent.r, accent.g, accent.b, 0.46))

static func _draw_shop_foreground_merchandise(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, shop_id: String, accent: Color) -> void:
	var base_y := size.y - tile_size * 0.92
	for i in range(SHOP_INTERIOR_FOREGROUND_PROP_COUNT):
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i / 2)
		var x := size.x * (0.13 if side < 0.0 else 0.87) + side * row * tile_size * 0.42
		var y := base_y - tile_size * (0.16 * float(i % 3))
		var base := Vector2(x, y)
		_draw_ellipse_poly(canvas, base + Vector2(0.0, tile_size * 0.18), Vector2(tile_size * 0.48, tile_size * 0.12), Color(0.0, 0.0, 0.0, 0.24))
		match shop_id:
			"blacksmith":
				canvas.draw_rect(Rect2(base + Vector2(-tile_size * 0.25, -tile_size * 0.34), Vector2(tile_size * 0.50, tile_size * 0.34)), Color(0.13, 0.08, 0.05, 0.70), true)
				canvas.draw_line(base + Vector2(-tile_size * 0.18, -tile_size * 0.42), base + Vector2(tile_size * 0.26, -tile_size * 0.08), Color(0.74, 0.74, 0.68, 0.52), 2.0)
			"medicine":
				canvas.draw_circle(base + Vector2(0.0, -tile_size * 0.12), tile_size * 0.18, Color(0.23, 0.38, 0.16, 0.60))
				canvas.draw_line(base + Vector2(-tile_size * 0.10, -tile_size * 0.22), base + Vector2(tile_size * 0.12, -tile_size * 0.50), Color(accent.r, accent.g, accent.b, 0.42), 1.2)
			"tailor":
				canvas.draw_rect(Rect2(base + Vector2(-tile_size * 0.24, -tile_size * 0.40), Vector2(tile_size * 0.48, tile_size * 0.44)), Color(accent.r, accent.g, accent.b, 0.42), true)
				canvas.draw_line(base + Vector2(-tile_size * 0.20, -tile_size * 0.15), base + Vector2(tile_size * 0.20, -tile_size * 0.28), Color(0.96, 0.78, 0.90, 0.34), 1.1)
			"inn", "teahouse":
				canvas.draw_rect(Rect2(base + Vector2(-tile_size * 0.30, -tile_size * 0.18), Vector2(tile_size * 0.60, tile_size * 0.18)), Color(0.24, 0.12, 0.06, 0.66), true)
				canvas.draw_circle(base + Vector2(-tile_size * 0.12, -tile_size * 0.24), tile_size * 0.10, Color(0.42, 0.18, 0.08, 0.66))
				canvas.draw_circle(base + Vector2(tile_size * 0.14, -tile_size * 0.25), tile_size * 0.08, Color(accent.r, accent.g, accent.b, 0.46))
			_:
				canvas.draw_rect(Rect2(base + Vector2(-tile_size * 0.28, -tile_size * 0.26), Vector2(tile_size * 0.56, tile_size * 0.28)), Color(0.25, 0.13, 0.06, 0.68), true)
				canvas.draw_circle(base + Vector2(tile_size * 0.02, -tile_size * 0.34), tile_size * 0.11, Color(accent.r, accent.g, accent.b, 0.46))

static func _draw_shop_blacksmith_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var forge := Vector2(size.x * 0.76, wall_bottom + tile_size * 1.10)
	_draw_ellipse_poly(canvas, forge + Vector2(0, tile_size * 0.38), Vector2(tile_size * 1.50, tile_size * 0.26), Color(0.0, 0.0, 0.0, 0.30))
	canvas.draw_rect(Rect2(forge - Vector2(tile_size * 1.00, tile_size * 0.42), Vector2(tile_size * 2.00, tile_size * 0.86)), Color(0.14, 0.075, 0.045, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
	canvas.draw_circle(forge, tile_size * 0.40, Color(1.0, 0.30, 0.12, 0.40))
	canvas.draw_circle(forge, tile_size * 0.20, Color(1.0, 0.74, 0.24, 0.55))
	var anvil := Vector2(size.x * 0.30, wall_bottom + tile_size * 2.25)
	canvas.draw_rect(Rect2(anvil - Vector2(tile_size * 0.54, tile_size * 0.18), Vector2(tile_size * 1.08, tile_size * 0.34)), Color(0.18, 0.18, 0.17, 0.82), true)
	canvas.draw_line(anvil + Vector2(-tile_size * 0.62, -tile_size * 0.10), anvil + Vector2(tile_size * 0.76, -tile_size * 0.16), Color(0.70, 0.68, 0.58, 0.42), 2.0)
	for i in range(4):
		var x := size.x * (0.46 + float(i) * 0.055)
		canvas.draw_line(Vector2(x, tile_size * 1.50), Vector2(x + tile_size * 0.46, wall_bottom - tile_size * 0.30), Color(0.80, 0.82, 0.76, 0.42), 2.0)

static func _draw_shop_medicine_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	var cabinet := Rect2(Vector2(size.x * 0.37, tile_size * 1.20), Vector2(size.x * 0.26, wall_bottom - tile_size * 1.72))
	canvas.draw_rect(cabinet, Color(0.15, 0.08, 0.045, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
	for row in range(4):
		for col in range(5):
			var cell := Rect2(cabinet.position + Vector2(tile_size * (0.20 + col * 0.72), tile_size * (0.22 + row * 0.55)), Vector2(tile_size * 0.52, tile_size * 0.34))
			canvas.draw_rect(cell, Color(0.34, 0.20, 0.10, 0.74), true)
			canvas.draw_circle(cell.get_center() + Vector2(0.0, tile_size * 0.08), 1.6, Color(accent.r, accent.g, accent.b, 0.46))
	for i in range(6):
		var p := Vector2(size.x * (0.23 + float(i) * 0.09), wall_bottom + tile_size * (1.0 + float(i % 2) * 0.28))
		canvas.draw_line(p, p + Vector2(tile_size * 0.12, -tile_size * 0.54), Color(0.20, 0.42, 0.18, 0.58), 1.4)
		canvas.draw_circle(p + Vector2(tile_size * 0.10, -tile_size * 0.58), 4.5, Color(accent.r, accent.g, accent.b, 0.48))

static func _draw_shop_inn_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(3):
		var center := Vector2(size.x * (0.28 + float(i) * 0.22), wall_bottom + tile_size * (1.95 + float(i % 2) * 0.25))
		_draw_ellipse_poly(canvas, center, Vector2(tile_size * 0.72, tile_size * 0.20), Color(0.09, 0.050, 0.030, 0.42))
		canvas.draw_rect(Rect2(center - Vector2(tile_size * 0.62, tile_size * 0.18), Vector2(tile_size * 1.24, tile_size * 0.28)), Color(0.29, 0.16, 0.075, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
		canvas.draw_line(center + Vector2(-tile_size * 0.50, -tile_size * 0.13), center + Vector2(tile_size * 0.54, -tile_size * 0.18), Color(accent.r, accent.g, accent.b, 0.32), 1.2)
	for x in [size.x * 0.14, size.x * 0.86]:
		for j in range(2):
			var jar := Vector2(x + float(j) * tile_size * 0.38 * (-1.0 if x > size.x * 0.5 else 1.0), wall_bottom + tile_size * (2.70 + float(j) * 0.08))
			canvas.draw_circle(jar, tile_size * 0.20, Color(0.34, 0.13, 0.075, 0.76))
			canvas.draw_rect(Rect2(jar + Vector2(-tile_size * 0.11, -tile_size * 0.28), Vector2(tile_size * 0.22, tile_size * 0.16)), Color(0.52, 0.26, 0.11, 0.72), true)

static func _draw_shop_tailor_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(6):
		var x := size.x * (0.21 + float(i) * 0.105)
		var top := wall_bottom - tile_size * (0.20 + float(i % 2) * 0.12)
		canvas.draw_line(Vector2(x, top), Vector2(x + tile_size * 0.18, wall_bottom + tile_size * 1.58), Color(accent.r, accent.g, accent.b, 0.52), 5.0)
		canvas.draw_line(Vector2(x + tile_size * 0.16, top + tile_size * 0.10), Vector2(x + tile_size * 0.34, wall_bottom + tile_size * 1.62), Color(0.92, 0.74, 0.88, 0.34), 3.0)
	var stand := Vector2(size.x * 0.78, wall_bottom + tile_size * 1.54)
	canvas.draw_line(stand + Vector2(0, -tile_size * 1.08), stand, Color(0.16, 0.08, 0.05, 0.72), 2.0)
	canvas.draw_polygon(PackedVector2Array([stand + Vector2(0, -tile_size * 1.10), stand + Vector2(tile_size * 0.42, -tile_size * 0.40), stand + Vector2(0, tile_size * 0.10), stand + Vector2(-tile_size * 0.42, -tile_size * 0.40)]), PackedColorArray([Color(accent.r, accent.g, accent.b, 0.44), Color(accent.r, accent.g, accent.b, 0.30), Color(accent.r, accent.g, accent.b, 0.24), Color(accent.r, accent.g, accent.b, 0.30)]))

static func _draw_shop_market_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(8):
		var x := size.x * (0.17 + float(i % 4) * 0.19)
		var y := wall_bottom + tile_size * (1.35 + float(i / 4) * 1.18)
		var crate := Rect2(Vector2(x - tile_size * 0.36, y - tile_size * 0.20), Vector2(tile_size * 0.72, tile_size * 0.42))
		canvas.draw_rect(crate, Color(0.26, 0.14, 0.07, SHOP_INTERIOR_THEME_PROP_ALPHA), true)
		canvas.draw_line(crate.position + Vector2(tile_size * 0.08, tile_size * 0.10), crate.end - Vector2(tile_size * 0.08, tile_size * 0.14), Color(accent.r, accent.g, accent.b, 0.28), 1.0)
		canvas.draw_circle(Vector2(x, y - tile_size * 0.30), 5.0 + float(i % 3), Color(accent.r, accent.g, accent.b, 0.44))

static func _draw_shop_teahouse_props(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for i in range(2):
		var center := Vector2(size.x * (0.36 + float(i) * 0.28), wall_bottom + tile_size * 2.08)
		_draw_ellipse_poly(canvas, center, Vector2(tile_size * 0.72, tile_size * 0.18), Color(0.04, 0.028, 0.018, 0.35))
		canvas.draw_circle(center, tile_size * 0.34, Color(0.24, 0.13, 0.07, SHOP_INTERIOR_THEME_PROP_ALPHA * 0.92))
		canvas.draw_circle(center + Vector2(tile_size * 0.18, -tile_size * 0.07), tile_size * 0.09, Color(accent.r, accent.g, accent.b, 0.46))
	var screen := Rect2(Vector2(size.x * 0.13, tile_size * 1.20), Vector2(size.x * 0.18, wall_bottom - tile_size * 1.18))
	canvas.draw_rect(screen, Color(0.12, 0.085, 0.052, 0.68), true)
	for i in range(3):
		var x := screen.position.x + screen.size.x * float(i + 1) / 4.0
		canvas.draw_line(Vector2(x, screen.position.y + tile_size * 0.20), Vector2(x, screen.end.y - tile_size * 0.20), Color(accent.r, accent.g, accent.b, 0.24), 1.0)

static func _draw_shop_lighting(canvas: CanvasItem, tile_size: int, size: Vector2, wall_bottom: float, accent: Color) -> void:
	for x in [size.x * 0.24, size.x * 0.50, size.x * 0.76]:
		var y := tile_size * 1.06
		canvas.draw_line(Vector2(x, tile_size * 0.48), Vector2(x, y), Color(0.88, 0.70, 0.38, 0.38), 1.1)
		canvas.draw_circle(Vector2(x, y + tile_size * 0.18), tile_size * 0.14, Color(accent.r, accent.g, accent.b, 0.74))
		_draw_ellipse_poly(canvas, Vector2(x, wall_bottom + tile_size * 0.10), Vector2(tile_size * 1.28, tile_size * 0.24), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_LIGHT_ALPHA * 0.25))
	_draw_stage_vertical_gradient(canvas, Rect2(Vector2(0.0, 0.0), size), Color(0.0, 0.0, 0.0, 0.12), Color(0.0, 0.0, 0.0, 0.30))

static func _draw_shop_foreground_frame(canvas: CanvasItem, tile_size: int, size: Vector2, accent: Color) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.015, 0.010, 0.34), false, 4.0)
	canvas.draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(size.x, tile_size * 0.42)), Color(0.025, 0.015, 0.010, 0.66), true)
	canvas.draw_rect(Rect2(Vector2(0.0, size.y - tile_size * 0.38), Vector2(size.x, tile_size * 0.42)), Color(0.010, 0.007, 0.005, 0.54), true)
	canvas.draw_rect(Rect2(Vector2(0.0, tile_size * 0.28), Vector2(tile_size * 0.52, size.y - tile_size * 0.56)), Color(0.015, 0.009, 0.006, SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA), true)
	canvas.draw_rect(Rect2(Vector2(size.x - tile_size * 0.52, tile_size * 0.28), Vector2(tile_size * 0.52, size.y - tile_size * 0.56)), Color(0.015, 0.009, 0.006, SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA), true)
	for x in [tile_size * 0.82, size.x - tile_size * 0.82]:
		canvas.draw_line(Vector2(x, tile_size * 0.44), Vector2(x, size.y - tile_size * 0.30), Color(0.12, 0.065, 0.032, SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA * 0.92), 4.8)
		canvas.draw_line(Vector2(x + (tile_size * 0.10 if x < size.x * 0.5 else -tile_size * 0.10), tile_size * 0.66), Vector2(x + (tile_size * 0.10 if x < size.x * 0.5 else -tile_size * 0.10), size.y - tile_size * 0.72), Color(accent.r, accent.g, accent.b, SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA * 0.22), 1.2)
	canvas.draw_line(Vector2(tile_size * 0.55, tile_size * 0.58), Vector2(size.x - tile_size * 0.55, tile_size * 0.48), Color(accent.r, accent.g, accent.b, 0.18), 1.5)