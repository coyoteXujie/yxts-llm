extends Node2D
class_name MapProp

var kind := ""
var tile_size := 48
var variant := 0
var prop_texture: Texture2D

func setup(new_kind: String, world_position: Vector2, new_tile_size: int, new_variant: int = 0, z_offset: int = 0, scale_factor: float = 1.0) -> void:
	kind = new_kind
	position = world_position
	tile_size = new_tile_size
	variant = new_variant
	scale = Vector2.ONE * scale_factor
	z_index = int(position.y) + z_offset
	prop_texture = GameData.load_texture("res://assets/world/props/prop_%s.png" % kind, true)
	queue_redraw()

func _draw() -> void:
	if prop_texture != null:
		_draw_texture_prop()
		return
	match kind:
		"roof":
			_draw_roof()
		"shop_roof":
			_draw_roof(Color(0.46, 0.18, 0.08), Color(0.78, 0.46, 0.18), true)
		"temple_roof":
			_draw_roof(Color(0.50, 0.32, 0.12), Color(0.88, 0.66, 0.30), true)
		"tree":
			_draw_tree()
		"bamboo":
			_draw_bamboo()
		"ridge":
			_draw_ridge()
		"gate":
			_draw_gate()
		"awning":
			_draw_awning()
		"shelf":
			_draw_shelf()
		"lantern":
			_draw_lantern()
		"market_stall":
			_draw_market_stall()
		"bridge_railing":
			_draw_bridge_railing()
		"stone_lantern":
			_draw_stone_lantern()
		"well":
			_draw_well()
		"boat":
			_draw_boat()
		"banner":
			_draw_banner()
		"flower_tree":
			_draw_flower_tree()
		"rock_cluster":
			_draw_rock_cluster()
		"shrine":
			_draw_shrine()

func _draw_texture_prop() -> void:
	var draw_scale := float(tile_size) / 96.0
	var size := Vector2(prop_texture.get_width(), prop_texture.get_height()) * draw_scale
	var top_left := Vector2(-size.x * 0.5, -size.y + float(tile_size) * 0.24)
	draw_texture_rect(prop_texture, Rect2(top_left, size), false)

func _draw_roof(base: Color = Color(0.30, 0.12, 0.06), highlight: Color = Color(0.68, 0.36, 0.17), has_sign: bool = false) -> void:
	var w := float(tile_size)
	var half := w * 0.54
	var top := -w * 0.94
	var eave_y := -w * 0.36
	_draw_ellipse_poly(Vector2(3, -5), Vector2(w * 0.46, w * 0.10), Color(0.0, 0.0, 0.0, 0.18))
	draw_polygon(PackedVector2Array([
		Vector2(-half, eave_y),
		Vector2(0, top),
		Vector2(half, eave_y),
		Vector2(half - 8, eave_y + 8),
		Vector2(-half + 8, eave_y + 8)
	]), PackedColorArray([
		base.darkened(0.18),
		highlight,
		base.darkened(0.12),
		base,
		base.darkened(0.04)
	]))
	draw_line(Vector2(-half + 5, eave_y + 2), Vector2(half - 5, eave_y + 2), Color(0.90, 0.62, 0.28, 0.36), 2.0)
	for i in range(4):
		var x := -half + 13.0 + float(i) * half * 0.52
		draw_line(Vector2(x, eave_y - 5), Vector2(x - 8, eave_y + 8), Color(0.18, 0.08, 0.04, 0.30), 1.3)
	if has_sign:
		draw_rect(Rect2(Vector2(-18, eave_y + 9), Vector2(36, 11)), Color(0.22, 0.10, 0.04, 0.78), true)
		draw_line(Vector2(-15, eave_y + 14), Vector2(15, eave_y + 14), Color(0.94, 0.70, 0.32, 0.45), 1.2)

func _draw_tree() -> void:
	var shift := float((variant % 5) - 2)
	_draw_ellipse_poly(Vector2(4, 8), Vector2(17, 5), Color(0, 0, 0, 0.18))
	draw_line(Vector2(0, -33), Vector2(0, 12), Color(0.15, 0.08, 0.04, 0.74), 5.0)
	draw_line(Vector2(0, -20), Vector2(-15, -35), Color(0.15, 0.08, 0.04, 0.45), 2.2)
	draw_line(Vector2(0, -24), Vector2(17, -39), Color(0.15, 0.08, 0.04, 0.42), 2.0)
	_draw_ellipse_poly(Vector2(-13 + shift, -47), Vector2(24, 18), Color(0.04, 0.17, 0.08, 0.88))
	_draw_ellipse_poly(Vector2(12 + shift, -52), Vector2(25, 20), Color(0.07, 0.26, 0.12, 0.88))
	_draw_ellipse_poly(Vector2(1 + shift, -34), Vector2(27, 18), Color(0.10, 0.33, 0.16, 0.82))
	draw_line(Vector2(-30, -29), Vector2(26, -38), Color(0.52, 0.66, 0.34, 0.16), 1.4)

func _draw_bamboo() -> void:
	_draw_ellipse_poly(Vector2(3, 8), Vector2(18, 4), Color(0, 0, 0, 0.15))
	for i in range(5):
		var x := -18.0 + float(i) * 9.0
		var sway := float(((variant + i * 3) % 7) - 3)
		draw_line(Vector2(x, 10), Vector2(x + sway, -55), Color(0.08, 0.23, 0.08, 0.86), 2.0)
		for y in [-40.0, -27.0, -14.0]:
			draw_line(Vector2(x + sway * 0.45, y), Vector2(x + 13, y - 6), Color(0.37, 0.66, 0.28, 0.48), 1.5)
			draw_line(Vector2(x + sway * 0.35, y + 4), Vector2(x - 11, y), Color(0.28, 0.55, 0.23, 0.40), 1.2)

func _draw_ridge() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(5, 11), Vector2(w * 0.48, w * 0.10), Color(0, 0, 0, 0.18))
	draw_polygon(PackedVector2Array([
		Vector2(-w * 0.58, 10),
		Vector2(-w * 0.20, -w * 0.76),
		Vector2(w * 0.12, -w * 0.44),
		Vector2(w * 0.50, 9)
	]), PackedColorArray([
		Color(0.16, 0.16, 0.14, 0.78),
		Color(0.60, 0.58, 0.50, 0.78),
		Color(0.36, 0.35, 0.31, 0.76),
		Color(0.12, 0.12, 0.11, 0.75)
	]))
	draw_line(Vector2(-w * 0.20, -w * 0.76), Vector2(w * 0.50, 9), Color(0.07, 0.06, 0.05, 0.26), 2.0)

func _draw_gate() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(0, 13), Vector2(w * 0.42, 5), Color(0, 0, 0, 0.17))
	draw_line(Vector2(-w * 0.35, 8), Vector2(-w * 0.35, -w * 0.70), Color(0.22, 0.12, 0.06, 0.82), 5.0)
	draw_line(Vector2(w * 0.35, 8), Vector2(w * 0.35, -w * 0.70), Color(0.22, 0.12, 0.06, 0.82), 5.0)
	draw_polygon(PackedVector2Array([
		Vector2(-w * 0.54, -w * 0.63),
		Vector2(0, -w * 0.90),
		Vector2(w * 0.54, -w * 0.63),
		Vector2(w * 0.45, -w * 0.52),
		Vector2(-w * 0.45, -w * 0.52)
	]), PackedColorArray([
		Color(0.32, 0.14, 0.07, 0.86),
		Color(0.74, 0.50, 0.22, 0.86),
		Color(0.32, 0.14, 0.07, 0.86),
		Color(0.22, 0.10, 0.05, 0.86),
		Color(0.22, 0.10, 0.05, 0.86)
	]))
	draw_line(Vector2(-w * 0.38, -w * 0.49), Vector2(w * 0.38, -w * 0.49), Color(0.90, 0.72, 0.34, 0.40), 2.0)

func _draw_awning() -> void:
	_draw_ellipse_poly(Vector2(2, 7), Vector2(19, 4), Color(0, 0, 0, 0.13))
	draw_polygon(PackedVector2Array([
		Vector2(-25, -17),
		Vector2(18, -25),
		Vector2(27, -14),
		Vector2(-16, -5)
	]), PackedColorArray([
		Color(0.48, 0.18, 0.10, 0.78),
		Color(0.86, 0.48, 0.20, 0.82),
		Color(0.56, 0.22, 0.12, 0.80),
		Color(0.38, 0.14, 0.08, 0.78)
	]))
	draw_line(Vector2(-17, -5), Vector2(-17, 13), Color(0.20, 0.10, 0.05, 0.62), 1.7)
	draw_line(Vector2(23, -14), Vector2(23, 10), Color(0.20, 0.10, 0.05, 0.62), 1.7)

func _draw_shelf() -> void:
	var w := float(tile_size)
	draw_rect(Rect2(Vector2(-w * 0.46, -w * 0.55), Vector2(w * 0.92, w * 0.38)), Color(0.22, 0.11, 0.05, 0.82), true)
	draw_line(Vector2(-w * 0.42, -w * 0.43), Vector2(w * 0.42, -w * 0.43), Color(0.82, 0.58, 0.28, 0.42), 2.0)
	draw_line(Vector2(-w * 0.42, -w * 0.28), Vector2(w * 0.42, -w * 0.28), Color(0.82, 0.58, 0.28, 0.34), 1.7)
	for i in range(5):
		var x := -w * 0.34 + float(i) * w * 0.17
		draw_circle(Vector2(x, -w * 0.36), 3.5, Color(0.72, 0.52, 0.26, 0.55))

func _draw_lantern() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(4, 10), Vector2(w * 0.22, 4), Color(0, 0, 0, 0.14))
	draw_line(Vector2(0, 10), Vector2(0, -w * 0.88), Color(0.18, 0.10, 0.05, 0.72), 2.4)
	draw_line(Vector2(0, -w * 0.74), Vector2(16, -w * 0.78), Color(0.20, 0.11, 0.05, 0.70), 2.0)
	draw_circle(Vector2(19, -w * 0.70), 8.0, Color(0.72, 0.18, 0.10, 0.82))
	draw_circle(Vector2(19, -w * 0.70), 4.3, Color(1.0, 0.74, 0.28, 0.42))
	draw_line(Vector2(19, -w * 0.61), Vector2(19, -w * 0.48), Color(0.92, 0.64, 0.28, 0.62), 1.3)

func _draw_market_stall() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(3, 9), Vector2(w * 0.43, 5), Color(0, 0, 0, 0.14))
	draw_rect(Rect2(Vector2(-w * 0.36, -w * 0.18), Vector2(w * 0.72, w * 0.26)), Color(0.28, 0.14, 0.06, 0.78), true)
	draw_polygon(PackedVector2Array([
		Vector2(-w * 0.46, -w * 0.35),
		Vector2(-w * 0.25, -w * 0.56),
		Vector2(w * 0.33, -w * 0.50),
		Vector2(w * 0.48, -w * 0.30),
		Vector2(w * 0.34, -w * 0.22),
		Vector2(-w * 0.38, -w * 0.25)
	]), PackedColorArray([
		Color(0.50, 0.18, 0.10, 0.86),
		Color(0.88, 0.50, 0.18, 0.90),
		Color(0.68, 0.24, 0.12, 0.88),
		Color(0.38, 0.14, 0.08, 0.88),
		Color(0.52, 0.20, 0.10, 0.86),
		Color(0.72, 0.32, 0.14, 0.86)
	]))
	for i in range(4):
		var x := -w * 0.22 + float(i) * w * 0.14
		draw_circle(Vector2(x, -w * 0.06), 3.8, Color(0.82, 0.58, 0.24, 0.62))
	draw_line(Vector2(-w * 0.36, -w * 0.22), Vector2(-w * 0.36, 8), Color(0.20, 0.10, 0.04, 0.62), 1.7)
	draw_line(Vector2(w * 0.36, -w * 0.22), Vector2(w * 0.36, 8), Color(0.20, 0.10, 0.04, 0.62), 1.7)

func _draw_bridge_railing() -> void:
	var w := float(tile_size)
	draw_line(Vector2(-w * 0.48, -w * 0.20), Vector2(w * 0.48, -w * 0.28), Color(0.36, 0.20, 0.08, 0.78), 3.0)
	draw_line(Vector2(-w * 0.48, -w * 0.04), Vector2(w * 0.48, -w * 0.12), Color(0.70, 0.46, 0.22, 0.56), 2.0)
	for i in range(5):
		var x := -w * 0.42 + float(i) * w * 0.21
		draw_line(Vector2(x, -w * 0.32), Vector2(x, w * 0.08), Color(0.22, 0.12, 0.05, 0.70), 1.8)

func _draw_stone_lantern() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(3, 10), Vector2(w * 0.24, 4), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(Vector2(-7, -18), Vector2(14, 27)), Color(0.42, 0.40, 0.34, 0.82), true)
	draw_rect(Rect2(Vector2(-14, -27), Vector2(28, 10)), Color(0.34, 0.32, 0.28, 0.86), true)
	draw_polygon(PackedVector2Array([
		Vector2(-18, -27),
		Vector2(0, -41),
		Vector2(18, -27)
	]), PackedColorArray([
		Color(0.22, 0.20, 0.18, 0.86),
		Color(0.60, 0.56, 0.46, 0.88),
		Color(0.26, 0.24, 0.21, 0.86)
	]))
	draw_circle(Vector2(0, -21), 4.5, Color(1.0, 0.74, 0.34, 0.28))

func _draw_well() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(4, 10), Vector2(w * 0.34, 5), Color(0, 0, 0, 0.16))
	_draw_ellipse_poly(Vector2(0, -8), Vector2(w * 0.30, w * 0.16), Color(0.26, 0.22, 0.18, 0.86))
	_draw_ellipse_poly(Vector2(0, -12), Vector2(w * 0.22, w * 0.10), Color(0.05, 0.10, 0.12, 0.82))
	draw_line(Vector2(-w * 0.32, -11), Vector2(-w * 0.32, -42), Color(0.22, 0.12, 0.06, 0.74), 3.0)
	draw_line(Vector2(w * 0.32, -11), Vector2(w * 0.32, -42), Color(0.22, 0.12, 0.06, 0.74), 3.0)
	draw_line(Vector2(-w * 0.36, -42), Vector2(w * 0.36, -42), Color(0.24, 0.13, 0.06, 0.78), 3.2)

func _draw_boat() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(4, 8), Vector2(w * 0.42, 5), Color(0, 0, 0, 0.12))
	draw_polygon(PackedVector2Array([
		Vector2(-w * 0.48, -12),
		Vector2(-w * 0.24, 8),
		Vector2(w * 0.36, 8),
		Vector2(w * 0.52, -10),
		Vector2(w * 0.24, -18),
		Vector2(-w * 0.34, -18)
	]), PackedColorArray([
		Color(0.20, 0.10, 0.04, 0.84),
		Color(0.42, 0.24, 0.10, 0.86),
		Color(0.36, 0.19, 0.08, 0.86),
		Color(0.16, 0.08, 0.04, 0.84),
		Color(0.62, 0.40, 0.20, 0.82),
		Color(0.56, 0.34, 0.16, 0.82)
	]))
	draw_line(Vector2(-w * 0.22, -3), Vector2(w * 0.22, -4), Color(0.78, 0.56, 0.30, 0.40), 1.8)

func _draw_banner() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(2, 12), Vector2(w * 0.18, 4), Color(0, 0, 0, 0.14))
	draw_line(Vector2(-8, 12), Vector2(-8, -w * 1.02), Color(0.20, 0.10, 0.04, 0.78), 2.8)
	draw_polygon(PackedVector2Array([
		Vector2(-7, -w * 0.92),
		Vector2(24, -w * 0.84),
		Vector2(18, -w * 0.56),
		Vector2(-7, -w * 0.62)
	]), PackedColorArray([
		Color(0.52, 0.08, 0.06, 0.86),
		Color(0.86, 0.32, 0.14, 0.88),
		Color(0.48, 0.10, 0.07, 0.86),
		Color(0.62, 0.16, 0.08, 0.86)
	]))
	draw_line(Vector2(-4, -w * 0.77), Vector2(17, -w * 0.72), Color(0.94, 0.70, 0.34, 0.40), 1.4)

func _draw_flower_tree() -> void:
	var shift := float((variant % 5) - 2)
	_draw_ellipse_poly(Vector2(5, 9), Vector2(19, 5), Color(0, 0, 0, 0.15))
	draw_line(Vector2(0, -30), Vector2(0, 12), Color(0.18, 0.09, 0.05, 0.74), 4.4)
	draw_line(Vector2(0, -18), Vector2(-16, -34), Color(0.18, 0.09, 0.05, 0.45), 2.0)
	draw_line(Vector2(0, -21), Vector2(16, -38), Color(0.18, 0.09, 0.05, 0.42), 2.0)
	_draw_ellipse_poly(Vector2(-11 + shift, -45), Vector2(24, 17), Color(0.58, 0.26, 0.36, 0.78))
	_draw_ellipse_poly(Vector2(13 + shift, -48), Vector2(24, 18), Color(0.82, 0.46, 0.54, 0.76))
	_draw_ellipse_poly(Vector2(0 + shift, -32), Vector2(27, 18), Color(0.70, 0.34, 0.42, 0.74))
	for i in range(5):
		var x := -20.0 + float(i) * 9.0
		draw_circle(Vector2(x + shift, -36.0 + float((variant + i) % 7)), 2.1, Color(1.0, 0.82, 0.86, 0.50))

func _draw_rock_cluster() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(3, 11), Vector2(w * 0.34, 5), Color(0, 0, 0, 0.17))
	for i in range(4):
		var x := -w * 0.24 + float(i) * w * 0.16
		var h := 13.0 + float((variant + i) % 4) * 5.0
		draw_polygon(PackedVector2Array([
			Vector2(x - 10, 8),
			Vector2(x, -h),
			Vector2(x + 12, 7)
		]), PackedColorArray([
			Color(0.18, 0.18, 0.16, 0.78),
			Color(0.54, 0.52, 0.46, 0.78),
			Color(0.28, 0.27, 0.24, 0.78)
		]))

func _draw_shrine() -> void:
	var w := float(tile_size)
	_draw_ellipse_poly(Vector2(2, 10), Vector2(w * 0.26, 4), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(Vector2(-14, -28), Vector2(28, 36)), Color(0.34, 0.32, 0.28, 0.84), true)
	draw_rect(Rect2(Vector2(-18, -33), Vector2(36, 7)), Color(0.22, 0.20, 0.18, 0.86), true)
	draw_line(Vector2(-8, -16), Vector2(8, -16), Color(0.74, 0.64, 0.42, 0.32), 1.4)
	draw_line(Vector2(-6, -7), Vector2(6, -7), Color(0.74, 0.64, 0.42, 0.24), 1.2)

func _draw_ellipse_poly(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)
