extends Node2D
class_name NpcActor

var data: Dictionary = {}
var highlighted := false
var tile_size := 48
var name_label: Label
var sprite_node: Sprite2D
var sprite_outline_node: Sprite2D
var using_sprite_asset := false

const USE_FULL_SPRITES_ON_MAP := true
const MAP_ACTOR_SCALE := 0.78

func setup(new_data: Dictionary, new_tile_size: int) -> void:
	data = new_data
	tile_size = new_tile_size
	name = str(data.get("name", "NPC"))
	position = Vector2((float(data.get("pos_x", 0)) + 0.5) * tile_size, (float(data.get("pos_y", 0)) + 0.5) * tile_size) + _visual_offset()
	z_index = int(position.y)
	if is_enemy():
		add_to_group("enemies")
	add_to_group("npcs")
	_ensure_label()
	_refresh_label_visibility()
	_refresh_sprite_asset()
	queue_redraw()

func _ready() -> void:
	if data.is_empty():
		z_index = int(position.y)
	_ensure_label()
	_refresh_label_visibility()
	if not data.is_empty():
		_refresh_sprite_asset()

func is_enemy() -> bool:
	return str(data.get("npc_type", "normal")) == "enemy"

func is_master() -> bool:
	return bool(data.get("is_master", false)) or str(data.get("npc_type", "normal")) == "master"

func set_highlight(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	_refresh_label_visibility()
	queue_redraw()

func _ensure_label() -> void:
	if name_label != null:
		name_label.text = str(data.get("name", "NPC"))
		return
	name_label = Label.new()
	name_label.text = str(data.get("name", "NPC"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-58, -78)
	name_label.size = Vector2(116, 22)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.89, 0.76))
	name_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.02, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.z_index = 3
	add_child(name_label)
	_refresh_label_visibility()

func _refresh_label_visibility() -> void:
	if name_label == null:
		return
	name_label.visible = highlighted

func _visual_offset() -> Vector2:
	var npc_id := int(data.get("id", 0))
	var ox := float(((npc_id * 37) % 15) - 7)
	var oy := float(((npc_id * 53) % 11) - 5)
	if is_master() or is_enemy():
		oy *= 0.6
	return Vector2(ox, oy)

func _map_actor_scale() -> float:
	return clamp(float(data.get("map_actor_scale", 1.0)), 0.45, 1.15)

func _refresh_sprite_asset() -> void:
	if not bool(data.get("use_map_sprite", USE_FULL_SPRITES_ON_MAP)):
		_clear_sprite_asset()
		return
	var sprite_path := GameData.get_npc_sprite_path(str(data.get("name", "")))
	if sprite_path.is_empty():
		_clear_sprite_asset()
		return
	var texture := GameData.load_texture(sprite_path, true)
	if texture == null:
		_clear_sprite_asset()
		return
	if sprite_outline_node == null:
		sprite_outline_node = Sprite2D.new()
		sprite_outline_node.centered = true
		sprite_outline_node.z_index = 1
		sprite_outline_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite_outline_node.modulate = Color(0.02, 0.018, 0.014, 0.62)
		add_child(sprite_outline_node)
	if sprite_node == null:
		sprite_node = Sprite2D.new()
		sprite_node.centered = true
		sprite_node.z_index = 2
		sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite_node)
	sprite_outline_node.texture = texture
	sprite_node.texture = texture
	var texture_size: Vector2 = texture.get_size()
	var target_height := 82.0
	var target_width := 72.0
	if is_master():
		target_height = 90.0
		target_width = 78.0
	if is_enemy():
		target_height = 88.0
		target_width = 76.0
	if str(data.get("name", "")) == "神秘人":
		target_height = 94.0
		target_width = 82.0
	var map_scale := _map_actor_scale()
	target_height *= map_scale
	target_width *= map_scale
	var factor: float = min(target_height / max(texture_size.y, 1.0), target_width / max(texture_size.x, 1.0))
	sprite_outline_node.scale = Vector2.ONE * factor * 1.045
	sprite_outline_node.position = Vector2(0, -7 * map_scale + 1.2)
	sprite_outline_node.visible = true
	sprite_node.scale = Vector2.ONE * factor
	sprite_node.position = Vector2(0, -7 * map_scale)
	sprite_node.visible = true
	using_sprite_asset = true
	if name_label != null:
		name_label.z_index = 3

func _clear_sprite_asset() -> void:
	using_sprite_asset = false
	if sprite_outline_node != null:
		sprite_outline_node.visible = false
	if sprite_node != null:
		sprite_node.visible = false

func _draw() -> void:
	var appearance := GameData.get_npc_appearance(data)
	var primary := _color(appearance.get("primary", [0.54, 0.46, 0.34]), Color(0.54, 0.46, 0.34))
	var secondary := _color(appearance.get("secondary", [0.24, 0.20, 0.16]), Color(0.24, 0.20, 0.16))
	var accent := _color(appearance.get("accent", [0.78, 0.62, 0.32]), Color(0.78, 0.62, 0.32))
	var ink := Color(0.07, 0.06, 0.05)

	if using_sprite_asset:
		var map_scale := _map_actor_scale()
		_draw_ground_marker(accent)
		_draw_actor_shadow(Vector2(3, 22 * map_scale), Vector2(17.0 * map_scale, 5.2 * map_scale), 0.92)
		_draw_aura(appearance, accent)
		if highlighted:
			draw_arc(Vector2.ZERO, 27.0 * map_scale, 0.0, TAU, 48, Color(0.95, 0.74, 0.28, 0.95), 2.4)
			draw_circle(Vector2(0, 27 * map_scale), 3.0, Color(0.95, 0.74, 0.28, 0.95))
		return

	var skin := _color(appearance.get("skin", [0.84, 0.68, 0.52]), Color(0.84, 0.68, 0.52))
	var scale := _build_scale(str(appearance.get("build", "standard"))) * MAP_ACTOR_SCALE * _map_actor_scale()

	_draw_ground_marker(accent)
	_draw_actor_shadow(Vector2(3, 20 * MAP_ACTOR_SCALE), Vector2(17.0 * max(scale.x, 1.0), 5.0 * max(scale.y, 0.9)), 0.82)

	draw_set_transform(Vector2.ZERO, 0.0, scale)
	_draw_aura(appearance, accent)
	_draw_prop_back(str(appearance.get("prop", "none")), secondary, accent, ink)
	_draw_legs(str(appearance.get("outfit", "short_robe")), secondary, ink)
	_draw_outfit(str(appearance.get("outfit", "short_robe")), primary, secondary, accent, ink)
	_draw_arms(str(appearance.get("outfit", "short_robe")), primary, secondary, skin, ink)
	_draw_head(str(appearance.get("head", "oval")), skin, ink)
	_draw_face(str(appearance.get("motif", "none")), ink)
	_draw_hair(str(appearance.get("hair", "topknot")), ink, secondary)
	_draw_hat(str(appearance.get("hat", "none")), primary, secondary, accent, ink)
	_draw_prop_front(str(appearance.get("prop", "none")), primary, secondary, accent, ink)
	_draw_motif(str(appearance.get("motif", "none")), accent, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if highlighted:
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color(0.95, 0.74, 0.28, 0.95), 2.4)
		draw_circle(Vector2(0, 27), 3.0, Color(0.95, 0.74, 0.28, 0.95))

func _draw_ground_marker(accent: Color) -> void:
	var map_scale := _map_actor_scale()
	var color := Color(accent.r, accent.g, accent.b, 0.20)
	if bool(data.get("has_quests", false)):
		color = Color(0.95, 0.72, 0.22, 0.34)
	elif is_master():
		color = Color(accent.r, accent.g, accent.b, 0.30)
	elif is_enemy():
		color = Color(0.76, 0.12, 0.09, 0.30)
	_draw_ellipse(Vector2(0, 26 * map_scale), Vector2(15 * map_scale, 4.5 * map_scale), color)
	if bool(data.get("has_quests", false)):
		draw_circle(Vector2(15 * map_scale, -38 * map_scale), 3.5, Color(0.98, 0.78, 0.28, 0.95))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)

func _draw_actor_shadow(center: Vector2, radius: Vector2, strength: float) -> void:
	var hour := float(GameState.hour)
	var noon_factor := clampf(1.0 - absf(hour - 12.0) / 8.0, 0.0, 1.0)
	var stretch := 1.0 + (1.0 - noon_factor) * 0.38
	var offset := Vector2(5.0 + (12.0 - hour) * 0.38, 1.8)
	_draw_ellipse(center + offset, Vector2(radius.x * stretch, radius.y * 1.10), Color(0.0, 0.0, 0.0, 0.070 * strength))
	_draw_ellipse(center + Vector2(1.5, 0.5), radius, Color(0.0, 0.0, 0.0, 0.18 * strength))
	_draw_ellipse(center, radius * Vector2(0.58, 0.48), Color(0.0, 0.0, 0.0, 0.13 * strength))

func _build_scale(build: String) -> Vector2:
	match build:
		"round":
			return Vector2(1.12, 0.98)
		"slim":
			return Vector2(0.86, 1.05)
		"thin":
			return Vector2(0.88, 1.10)
		"strong":
			return Vector2(1.10, 1.02)
		"broad":
			return Vector2(1.24, 0.98)
		"aged":
			return Vector2(0.92, 0.95)
		"graceful":
			return Vector2(0.92, 1.08)
		"heroic":
			return Vector2(1.04, 1.12)
		"master":
			return Vector2(1.05, 1.08)
		"rough":
			return Vector2(1.08, 0.96)
		"boss":
			return Vector2(1.28, 1.18)
		_:
			return Vector2.ONE

func _draw_aura(appearance: Dictionary, accent: Color) -> void:
	if is_master():
		draw_circle(Vector2(0, -1), 26.0, Color(accent.r, accent.g, accent.b, 0.11))
		draw_arc(Vector2(0, -1), 28.0, -0.2, PI + 0.2, 36, Color(accent.r, accent.g, accent.b, 0.22), 2.0)
	if is_enemy():
		draw_circle(Vector2(0, 1), 25.0, Color(0.70, 0.08, 0.06, 0.10))
	if str(appearance.get("motif", "none")) == "snow":
		draw_circle(Vector2(0, -4), 24.0, Color(0.80, 0.92, 1.0, 0.12))

func _draw_legs(outfit: String, secondary: Color, ink: Color) -> void:
	if outfit == "flowing_hanfu" or outfit == "daoist_robe" or outfit == "fur_robe":
		draw_polygon(PackedVector2Array([Vector2(-11, 21), Vector2(0, 33), Vector2(-14, 36)]), PackedColorArray([secondary, secondary.darkened(0.12), secondary]))
		draw_polygon(PackedVector2Array([Vector2(11, 21), Vector2(0, 33), Vector2(14, 36)]), PackedColorArray([secondary, secondary.darkened(0.12), secondary]))
	else:
		draw_line(Vector2(-7, 21), Vector2(-9, 36), ink, 4.0)
		draw_line(Vector2(7, 21), Vector2(9, 36), ink, 4.0)

func _draw_outfit(outfit: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match outfit:
		"merchant_robe":
			_draw_robe(primary, secondary, accent, 18.0, 24.0)
			draw_rect(Rect2(-11, 6, 22, 4), accent, true)
			draw_circle(Vector2(0, 12), 3.0, accent.lightened(0.2))
		"work_apron":
			_draw_tunic(primary, secondary, 16.0, 23.0)
			draw_rect(Rect2(-10, -2, 20, 24), secondary.lightened(0.34), true)
			draw_line(Vector2(-8, -1), Vector2(8, 21), ink, 1.5)
		"plain_hanfu":
			_draw_robe(primary, secondary, accent, 16.0, 28.0)
			draw_line(Vector2(-10, 1), Vector2(13, 16), accent, 2.0)
		"scholar_robe":
			_draw_robe(primary, secondary, accent, 14.0, 29.0)
			draw_rect(Rect2(-13, 4, 26, 3), accent.darkened(0.08), true)
			draw_line(Vector2(0, -3), Vector2(0, 22), secondary.lightened(0.18), 1.4)
		"official_uniform":
			_draw_tunic(primary, secondary, 18.0, 26.0)
			draw_rect(Rect2(-12, -2, 24, 8), secondary, true)
			draw_rect(Rect2(-6, 6, 12, 10), accent.darkened(0.10), false, 2.0)
		"elder_robe":
			_draw_robe(primary, secondary, accent, 15.0, 25.0)
			draw_line(Vector2(-10, 12), Vector2(10, 12), accent.darkened(0.10), 2.0)
		"monk_robe":
			_draw_robe(primary, secondary, accent, 17.0, 28.0)
			draw_polygon(PackedVector2Array([Vector2(-16, -6), Vector2(7, -2), Vector2(-4, 20), Vector2(-18, 17)]), PackedColorArray([secondary, secondary.lightened(0.06), secondary, secondary.darkened(0.10)]))
		"smith_apron":
			_draw_tunic(primary, secondary, 19.0, 24.0)
			draw_rect(Rect2(-12, -4, 24, 28), secondary.darkened(0.08), true)
			draw_line(Vector2(-10, 8), Vector2(10, 8), accent, 2.0)
		"hero_robe":
			_draw_robe(primary, secondary, accent, 17.0, 30.0)
			draw_line(Vector2(-14, -3), Vector2(14, 16), accent, 2.3)
			draw_arc(Vector2(0, 6), 20.0, 0.2, 2.6, 18, Color(accent.r, accent.g, accent.b, 0.40), 2.0)
		"sect_robe":
			_draw_robe(primary, secondary, accent, 18.0, 30.0)
			draw_rect(Rect2(-14, 7, 28, 4), accent, true)
			draw_line(Vector2(-13, -2), Vector2(13, 18), accent.darkened(0.05), 2.0)
		"flowing_hanfu":
			_draw_robe(primary, secondary, accent, 15.0, 32.0)
			draw_arc(Vector2(-7, 10), 19.0, -0.3, 1.4, 20, Color(accent.r, accent.g, accent.b, 0.38), 2.0)
			draw_arc(Vector2(9, 13), 21.0, 1.7, 3.4, 20, Color(accent.r, accent.g, accent.b, 0.30), 2.0)
		"daoist_robe":
			_draw_robe(primary, secondary, accent, 16.0, 31.0)
			draw_circle(Vector2(0, 9), 7.0, secondary)
			draw_arc(Vector2(0, 9), 7.0, -PI / 2.0, PI / 2.0, 18, primary, 2.0)
		"fur_robe":
			_draw_robe(primary, secondary, accent, 19.0, 31.0)
			draw_arc(Vector2(-10, -2), 9.0, 0.0, TAU, 18, accent, 2.3)
			draw_arc(Vector2(10, -2), 9.0, 0.0, TAU, 18, accent, 2.3)
		"ragged":
			_draw_tunic(primary, secondary, 17.0, 22.0)
			draw_line(Vector2(-11, 16), Vector2(-3, 24), ink, 1.6)
			draw_line(Vector2(5, 14), Vector2(13, 21), ink, 1.6)
		"leather":
			_draw_tunic(primary, secondary, 20.0, 25.0)
			draw_rect(Rect2(-12, 2, 24, 8), secondary, true)
			draw_circle(Vector2(-6, 6), 2.0, accent)
			draw_circle(Vector2(6, 6), 2.0, accent)
		"night_suit":
			_draw_tunic(primary, secondary, 15.0, 26.0)
			draw_rect(Rect2(-13, -7, 26, 9), secondary, true)
		"dark_armor":
			_draw_tunic(primary, secondary, 22.0, 30.0)
			draw_rect(Rect2(-14, -2, 28, 21), secondary.darkened(0.10), true)
			draw_line(Vector2(-12, 4), Vector2(12, 4), accent, 2.0)
			draw_line(Vector2(-10, 13), Vector2(10, 13), accent.darkened(0.12), 2.0)
		_:
			_draw_tunic(primary, secondary, 16.0, 24.0)

func _draw_robe(primary: Color, secondary: Color, accent: Color, half_width: float, height: float) -> void:
	draw_polygon(PackedVector2Array([
		Vector2(-half_width, -8),
		Vector2(half_width, -8),
		Vector2(half_width + 5, height),
		Vector2(0, height + 8),
		Vector2(-half_width - 5, height)
	]), PackedColorArray([primary.lightened(0.05), primary, primary.darkened(0.13), secondary.darkened(0.05), primary.darkened(0.08)]))
	draw_line(Vector2(-half_width + 4, -2), Vector2(half_width - 3, height - 2), accent, 2.0)

func _draw_tunic(primary: Color, secondary: Color, half_width: float, height: float) -> void:
	draw_polygon(PackedVector2Array([
		Vector2(-half_width, -7),
		Vector2(half_width, -7),
		Vector2(half_width - 2, height),
		Vector2(-half_width + 2, height)
	]), PackedColorArray([primary.lightened(0.05), primary, primary.darkened(0.13), primary.darkened(0.08)]))
	draw_rect(Rect2(-half_width + 3, 8, half_width * 2.0 - 6, 4), secondary, true)

func _draw_arms(outfit: String, primary: Color, secondary: Color, skin: Color, ink: Color) -> void:
	var sleeve_width := 4.0
	if outfit == "flowing_hanfu" or outfit == "daoist_robe":
		sleeve_width = 6.0
	draw_line(Vector2(-13, -1), Vector2(-25, 9), primary.darkened(0.05), sleeve_width)
	draw_line(Vector2(13, -1), Vector2(25, 8), primary.darkened(0.10), sleeve_width)
	draw_circle(Vector2(-27, 10), 3.0, skin)
	draw_circle(Vector2(27, 9), 3.0, skin)
	if outfit == "official_uniform" or outfit == "dark_armor":
		draw_line(Vector2(-14, -1), Vector2(-25, 9), ink, 1.5)
		draw_line(Vector2(14, -1), Vector2(25, 8), ink, 1.5)

func _draw_head(head: String, skin: Color, ink: Color) -> void:
	match head:
		"square":
			draw_polygon(PackedVector2Array([Vector2(-10, -28), Vector2(10, -28), Vector2(11, -16), Vector2(7, -9), Vector2(-7, -9), Vector2(-11, -16)]), PackedColorArray([skin, skin, skin.darkened(0.05), skin.darkened(0.08), skin.darkened(0.08), skin.darkened(0.05)]))
		"long":
			draw_circle(Vector2(0, -20), 10.0, skin)
			draw_rect(Rect2(-8, -20, 16, 11), skin.darkened(0.02), true)
		"aged":
			draw_circle(Vector2(0, -20), 9.5, skin.darkened(0.05))
			draw_line(Vector2(-6, -18), Vector2(6, -18), Color(ink.r, ink.g, ink.b, 0.35), 1.0)
			draw_line(Vector2(-4, -15), Vector2(5, -15), Color(ink.r, ink.g, ink.b, 0.30), 1.0)
		"sharp":
			draw_polygon(PackedVector2Array([Vector2(0, -31), Vector2(11, -22), Vector2(7, -11), Vector2(0, -7), Vector2(-7, -11), Vector2(-11, -22)]), PackedColorArray([skin.lightened(0.05), skin, skin.darkened(0.05), skin.darkened(0.08), skin.darkened(0.05), skin]))
		"soft":
			draw_circle(Vector2(0, -20), 10.5, skin.lightened(0.04))
		"rough":
			draw_polygon(PackedVector2Array([Vector2(-10, -27), Vector2(9, -29), Vector2(12, -18), Vector2(5, -8), Vector2(-7, -10), Vector2(-12, -18)]), PackedColorArray([skin, skin.darkened(0.03), skin.darkened(0.06), skin.darkened(0.10), skin.darkened(0.08), skin]))
		_:
			draw_circle(Vector2(0, -20), 10.0, skin)

func _draw_face(motif: String, ink: Color) -> void:
	draw_circle(Vector2(-4, -21), 1.1, ink)
	draw_circle(Vector2(4, -21), 1.1, ink)
	draw_line(Vector2(-3, -14), Vector2(4, -14), Color(ink.r, ink.g, ink.b, 0.70), 1.2)
	if motif == "scar":
		draw_line(Vector2(5, -26), Vector2(-3, -16), Color(0.70, 0.12, 0.10), 1.5)
	elif motif == "shadow":
		draw_rect(Rect2(-9, -22, 18, 6), Color(0.02, 0.02, 0.025), true)
		draw_circle(Vector2(-4, -20), 1.0, Color(0.86, 0.18, 0.12))
		draw_circle(Vector2(4, -20), 1.0, Color(0.86, 0.18, 0.12))

func _draw_hair(hair: String, ink: Color, secondary: Color) -> void:
	match hair:
		"short":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
		"topknot":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_circle(Vector2(0, -33), 3.8, ink)
		"high_topknot":
			draw_arc(Vector2(0, -24), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(0, -31), Vector2(0, -40), ink, 3.0)
			draw_circle(Vector2(0, -40), 3.2, ink)
		"long_tail":
			draw_arc(Vector2(0, -23), 10.5, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(8, -18), Vector2(13, 2), ink, 3.0)
		"sideburns":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(-9, -20), Vector2(-12, -10), ink, 2.5)
			draw_line(Vector2(9, -20), Vector2(12, -10), ink, 2.5)
		"beard":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
			draw_line(Vector2(-3, -13), Vector2(-2, -4), secondary.lightened(0.45), 2.0)
			draw_line(Vector2(3, -13), Vector2(2, -4), secondary.lightened(0.45), 2.0)
		"white_beard":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, Color(0.88, 0.86, 0.80), 4.0)
			draw_line(Vector2(-4, -13), Vector2(-5, -1), Color(0.88, 0.86, 0.80), 2.2)
			draw_line(Vector2(4, -13), Vector2(5, -1), Color(0.88, 0.86, 0.80), 2.2)
			draw_line(Vector2(0, -13), Vector2(0, 2), Color(0.94, 0.92, 0.86), 2.0)
		"bald":
			draw_arc(Vector2(0, -24), 9.0, PI + 0.2, TAU - 0.2, 14, Color(0.48, 0.32, 0.20, 0.20), 1.5)
		"headband":
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 18, ink, 4.0)
		"messy":
			draw_line(Vector2(-9, -28), Vector2(-3, -34), ink, 3.0)
			draw_line(Vector2(-4, -30), Vector2(2, -36), ink, 3.0)
			draw_line(Vector2(3, -30), Vector2(10, -34), ink, 3.0)
			draw_arc(Vector2(0, -23), 10.0, PI, TAU, 16, ink, 3.0)
		"wild":
			for i in range(7):
				var x := -12.0 + i * 4.0
				var lean := -2.0 if i % 2 == 0 else 2.0
				draw_line(Vector2(x, -25), Vector2(x + lean, -38 - abs(3 - i)), ink, 2.5)
			draw_arc(Vector2(0, -23), 11.0, PI, TAU, 18, ink, 4.0)
		"masked":
			draw_rect(Rect2(-10, -24, 20, 8), ink, true)
		"hood":
			draw_arc(Vector2(0, -23), 12.0, PI, TAU, 20, secondary, 5.0)

func _draw_hat(hat: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match hat:
		"merchant_cap":
			draw_rect(Rect2(-10, -33, 20, 6), secondary, true)
			draw_arc(Vector2(0, -31), 11.0, PI, TAU, 16, accent, 2.0)
		"cloth_cap":
			draw_arc(Vector2(0, -30), 11.0, PI, TAU, 16, secondary.lightened(0.20), 4.0)
			draw_line(Vector2(7, -30), Vector2(14, -25), secondary.lightened(0.20), 3.0)
		"scholar_hat":
			draw_rect(Rect2(-11, -35, 22, 5), ink, true)
			draw_rect(Rect2(-6, -40, 12, 7), secondary.darkened(0.12), true)
		"constable_hat":
			draw_rect(Rect2(-13, -35, 26, 5), ink, true)
			draw_polygon(PackedVector2Array([Vector2(-8, -35), Vector2(8, -35), Vector2(4, -43), Vector2(-4, -43)]), PackedColorArray([secondary, secondary, secondary.darkened(0.10), secondary.darkened(0.10)]))
			draw_circle(Vector2(0, -37), 2.3, accent)
		"soft_cap":
			draw_arc(Vector2(0, -31), 10.0, PI, TAU, 16, secondary, 4.0)
		"monk_dots":
			for x in [-4, 0, 4]:
				draw_circle(Vector2(x, -26), 0.9, Color(0.38, 0.20, 0.10))
		"headband":
			draw_line(Vector2(-10, -26), Vector2(10, -26), accent, 3.0)
			draw_line(Vector2(9, -26), Vector2(16, -22), accent, 2.0)
		"sect_crown":
			draw_rect(Rect2(-8, -36, 16, 5), accent.darkened(0.10), true)
			draw_polygon(PackedVector2Array([Vector2(-5, -36), Vector2(0, -43), Vector2(5, -36)]), PackedColorArray([accent, accent.lightened(0.18), accent]))
		"flower_pin":
			draw_circle(Vector2(8, -31), 3.0, accent)
			draw_circle(Vector2(11, -29), 2.0, primary.lightened(0.25))
			draw_circle(Vector2(6, -28), 2.0, primary.lightened(0.25))
		"daoist_crown":
			draw_line(Vector2(-9, -35), Vector2(9, -35), ink, 3.0)
			draw_line(Vector2(0, -35), Vector2(0, -44), ink, 2.5)
			draw_circle(Vector2(0, -44), 2.5, accent)
		"snow_hood":
			draw_arc(Vector2(0, -24), 13.0, PI, TAU, 20, accent, 5.0)
			draw_line(Vector2(-11, -23), Vector2(-14, -12), accent, 3.0)
			draw_line(Vector2(11, -23), Vector2(14, -12), accent, 3.0)
		"bandit_wrap":
			draw_line(Vector2(-11, -28), Vector2(11, -25), accent.darkened(0.15), 4.0)
			draw_line(Vector2(9, -25), Vector2(15, -20), accent.darkened(0.15), 2.5)
		"face_mask":
			draw_rect(Rect2(-10, -19, 20, 7), secondary, true)
		"dark_crown":
			draw_rect(Rect2(-12, -36, 24, 5), secondary.darkened(0.25), true)
			draw_polygon(PackedVector2Array([Vector2(-10, -36), Vector2(-5, -45), Vector2(0, -36), Vector2(5, -45), Vector2(10, -36)]), PackedColorArray([secondary, accent, secondary, accent, secondary]))

func _draw_prop_back(prop: String, secondary: Color, accent: Color, ink: Color) -> void:
	if prop == "sword":
		draw_line(Vector2(17, -9), Vector2(29, -36), Color(0.76, 0.78, 0.76), 2.2)
		draw_line(Vector2(14, -5), Vector2(22, -12), accent, 2.8)
	elif prop == "great_blade":
		draw_line(Vector2(20, 14), Vector2(33, -39), Color(0.72, 0.72, 0.68), 4.0)
		draw_line(Vector2(18, 14), Vector2(24, 2), accent.darkened(0.15), 4.0)
	elif prop == "staff":
		draw_line(Vector2(-27, -23), Vector2(-22, 34), Color(0.40, 0.25, 0.13), 3.0)
	elif prop == "dao" or prop == "blade":
		draw_line(Vector2(19, -6), Vector2(32, -24), Color(0.74, 0.76, 0.72), 3.0)
		draw_line(Vector2(16, -4), Vector2(22, -10), accent, 2.8)

func _draw_prop_front(prop: String, primary: Color, secondary: Color, accent: Color, ink: Color) -> void:
	match prop:
		"abacus":
			draw_rect(Rect2(-27, 3, 14, 10), Color(0.42, 0.25, 0.12), false, 1.6)
			draw_line(Vector2(-25, 7), Vector2(-15, 7), accent, 1.0)
			draw_circle(Vector2(-22, 5), 1.2, accent)
			draw_circle(Vector2(-18, 9), 1.2, accent)
		"towel":
			draw_line(Vector2(-24, 8), Vector2(-17, 25), Color(0.92, 0.88, 0.76), 4.0)
			draw_line(Vector2(-19, 24), Vector2(-12, 19), Color(0.92, 0.88, 0.76), 3.0)
		"basket":
			draw_arc(Vector2(-23, 13), 9.0, PI, TAU, 16, accent.darkened(0.15), 2.0)
			draw_rect(Rect2(-31, 12, 16, 10), Color(0.52, 0.34, 0.16), false, 1.6)
			draw_line(Vector2(-29, 17), Vector2(-16, 17), accent.darkened(0.20), 1.0)
		"scroll":
			draw_rect(Rect2(17, 2, 11, 21), Color(0.86, 0.78, 0.56), true)
			draw_line(Vector2(17, 6), Vector2(28, 6), ink, 1.0)
			draw_line(Vector2(17, 17), Vector2(28, 17), ink, 1.0)
		"beads":
			for i in range(8):
				var angle := -0.2 + i * 0.42
				draw_circle(Vector2(cos(angle) * 10.0, 0 + sin(angle) * 8.0), 1.5, accent.darkened(0.20))
		"hammer":
			draw_line(Vector2(21, 12), Vector2(31, 0), Color(0.42, 0.26, 0.14), 3.0)
			draw_rect(Rect2(27, -5, 12, 7), Color(0.46, 0.44, 0.42), true)
		"fan":
			draw_polygon(PackedVector2Array([Vector2(22, 10), Vector2(35, -4), Vector2(38, 11)]), PackedColorArray([accent, primary.lightened(0.25), accent.lightened(0.1)]))
			draw_line(Vector2(22, 10), Vector2(36, 0), ink, 1.0)
			draw_line(Vector2(22, 10), Vector2(37, 7), ink, 1.0)
		"whisk":
			draw_line(Vector2(22, 6), Vector2(34, -8), Color(0.44, 0.32, 0.18), 2.0)
			for i in range(5):
				draw_line(Vector2(34, -8), Vector2(42, -13 + i * 3), Color(0.86, 0.84, 0.76), 1.2)
		"club":
			draw_line(Vector2(22, 14), Vector2(32, -4), Color(0.36, 0.20, 0.10), 5.0)
		"dagger":
			draw_line(Vector2(22, 10), Vector2(33, 0), Color(0.78, 0.80, 0.76), 2.2)
			draw_line(Vector2(19, 12), Vector2(24, 7), accent, 2.0)

func _draw_motif(motif: String, accent: Color, ink: Color) -> void:
	match motif:
		"coin":
			draw_circle(Vector2(0, 11), 4.0, accent)
			draw_rect(Rect2(-1.5, 9.5, 3, 3), ink.darkened(0.2), true)
		"water":
			draw_arc(Vector2(0, 10), 7.0, 0.1, PI - 0.1, 16, accent, 1.6)
			draw_arc(Vector2(3, 13), 5.0, PI, TAU, 16, accent, 1.4)
		"book":
			draw_rect(Rect2(-6, 7, 12, 8), accent.darkened(0.1), false, 1.4)
			draw_line(Vector2(0, 7), Vector2(0, 15), accent, 1.2)
		"badge":
			draw_polygon(PackedVector2Array([Vector2(0, 4), Vector2(6, 9), Vector2(3, 16), Vector2(-3, 16), Vector2(-6, 9)]), PackedColorArray([accent, accent.darkened(0.05), accent.darkened(0.15), accent.darkened(0.15), accent.darkened(0.05)]))
		"lotus":
			draw_circle(Vector2(0, 12), 2.4, accent)
			draw_arc(Vector2(-4, 12), 4.0, -0.8, 0.8, 12, accent, 1.3)
			draw_arc(Vector2(4, 12), 4.0, PI - 0.8, PI + 0.8, 12, accent, 1.3)
		"spark":
			draw_line(Vector2(0, 8), Vector2(0, 16), accent, 1.6)
			draw_line(Vector2(-4, 12), Vector2(4, 12), accent, 1.6)
		"wind":
			draw_arc(Vector2(0, 9), 10.0, 0.0, PI * 1.2, 20, accent, 1.5)
		"bagua":
			draw_arc(Vector2(0, 11), 7.0, 0.0, TAU, 24, accent, 1.7)
			draw_line(Vector2(-5, 11), Vector2(5, 11), accent, 1.2)
			draw_line(Vector2(0, 6), Vector2(0, 16), accent, 1.2)
		"flower":
			for angle in [0.0, 1.26, 2.52, 3.78, 5.04]:
				draw_circle(Vector2(cos(angle) * 4.0, 11 + sin(angle) * 4.0), 2.0, accent.lightened(0.12))
			draw_circle(Vector2(0, 11), 1.8, accent.darkened(0.20))
		"taiji":
			draw_circle(Vector2(0, 11), 6.0, accent)
			draw_arc(Vector2(0, 11), 6.0, -PI / 2.0, PI / 2.0, 18, ink, 2.0)
			draw_circle(Vector2(0, 8), 1.3, ink)
			draw_circle(Vector2(0, 14), 1.3, accent.lightened(0.35))
		"snow":
			draw_line(Vector2(-5, 11), Vector2(5, 11), accent, 1.2)
			draw_line(Vector2(0, 6), Vector2(0, 16), accent, 1.2)
			draw_line(Vector2(-4, 7), Vector2(4, 15), accent, 1.2)
			draw_line(Vector2(4, 7), Vector2(-4, 15), accent, 1.2)
		"dragon":
			draw_arc(Vector2(-1, 11), 8.0, -0.8, 2.7, 22, accent, 2.0)
			draw_circle(Vector2(6, 7), 1.8, accent.lightened(0.2))

func _color(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_ARRAY and value.size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]) if value.size() >= 4 else 1.0)
	return fallback
