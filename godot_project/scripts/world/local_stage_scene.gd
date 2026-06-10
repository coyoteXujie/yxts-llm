extends Node2D
class_name LocalStageScene

const BACKDROP_ALPHA := 0.94
const MIDGROUND_ALPHA := 1.0
const FLOOR_ALPHA := 0.98
const BACKDROP_SCROLL_SCALE := Vector2(1.0, 1.0)
const MIDGROUND_SCROLL_SCALE := Vector2(1.0, 1.0)
const BACKDROP_AUTOSCROLL := Vector2.ZERO
const MIDGROUND_AUTOSCROLL := Vector2.ZERO
const STAGE_TEXTURE_RECT_OFFSET := Vector2(-0.08, 0.18)
const STAGE_TEXTURE_RECT_SIZE := Vector2(1.16, 0.86)

var current_region: Dictionary = {}
var map_size := Vector2.ZERO
var tile_size := 48
var active := false
var built_from_stage_layers := false
var parallax_layer_count := 0

func setup_region(region: Dictionary, new_map_size: Vector2, new_tile_size: int) -> void:
	current_region = region.duplicate(true)
	map_size = new_map_size
	tile_size = new_tile_size
	_rebuild_layers()

func _rebuild_layers() -> void:
	_clear_layers()
	active = false
	built_from_stage_layers = false
	parallax_layer_count = 0
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		hide()
		return

	var region_id := str(current_region.get("id", ""))
	var backdrop_texture := _load_texture(GameData.get_scene_background_path(region_id))
	var midground_texture := _load_texture(GameData.get_stage_layer_path(region_id, "midground"))
	var floor_texture := _load_texture(GameData.get_stage_layer_path(region_id, "floor"))
	if backdrop_texture == null and midground_texture == null and floor_texture == null:
		hide()
		return

	active = true
	built_from_stage_layers = midground_texture != null and floor_texture != null
	show()

	var stage_rect := _make_stage_texture_rect()
	if backdrop_texture != null:
		_add_parallax_sprite(
			"Backdrop",
			backdrop_texture,
			stage_rect,
			BACKDROP_SCROLL_SCALE,
			BACKDROP_AUTOSCROLL,
			BACKDROP_ALPHA,
			-30
		)
	if midground_texture != null:
		_add_parallax_sprite(
			"Midground",
			midground_texture,
			stage_rect,
			MIDGROUND_SCROLL_SCALE,
			MIDGROUND_AUTOSCROLL,
			MIDGROUND_ALPHA,
			-20
		)
	if floor_texture != null:
		_add_sprite_layer(
			"Floor",
			floor_texture,
			stage_rect,
			FLOOR_ALPHA,
			-10
		)

func _make_stage_texture_rect() -> Rect2:
	return Rect2(
		Vector2(map_size.x * STAGE_TEXTURE_RECT_OFFSET.x, map_size.y * STAGE_TEXTURE_RECT_OFFSET.y),
		Vector2(map_size.x * STAGE_TEXTURE_RECT_SIZE.x, map_size.y * STAGE_TEXTURE_RECT_SIZE.y)
	)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return GameData.load_texture(path, true)

func _add_parallax_sprite(layer_name: String, texture: Texture2D, rect: Rect2, scroll_scale: Vector2, autoscroll: Vector2, alpha: float, z: int) -> void:
	var parallax := Parallax2D.new()
	parallax.name = "%sParallax" % layer_name
	parallax.z_index = z
	parallax.scroll_scale = scroll_scale
	parallax.autoscroll = autoscroll
	parallax.follow_viewport = true
	parallax.repeat_size = Vector2.ZERO
	add_child(parallax)
	parallax_layer_count += 1

	var sprite := _make_sprite(layer_name, texture, rect, alpha)
	parallax.add_child(sprite)

func _add_sprite_layer(layer_name: String, texture: Texture2D, rect: Rect2, alpha: float, z: int) -> void:
	var holder := Node2D.new()
	holder.name = "%sLayer" % layer_name
	holder.z_index = z
	add_child(holder)
	holder.add_child(_make_sprite(layer_name, texture, rect, alpha))

func _make_sprite(layer_name: String, texture: Texture2D, rect: Rect2, alpha: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "%sSprite" % layer_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	var texture_size := texture.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		sprite.scale = Vector2(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	return sprite

func _clear_layers() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
