extends RefCounted
class_name UiArt

const MAIN_MENU_BACKDROP := "res://assets/ui/main_menu_backdrop_v1.png"
const PANEL_INK := "res://assets/ui/panel_ink.png"
const BUTTON_GOLD := "res://assets/ui/button_gold.png"
const SLOT_ITEM := "res://assets/ui/slot_item.png"
const WORLD_MAP_BACKDROP := "res://assets/ui/world_map_backdrop_v1.png"

const COLOR_GOLD := Color(0.788, 0.663, 0.431)
const COLOR_GOLD_BRIGHT := Color(0.980, 0.860, 0.580)

static func load_texture(path: String, use_mipmaps: bool = true) -> Texture2D:
	if path.is_empty():
		return null
	return GameData.load_texture(path, use_mipmaps)

static func full_rect_texture(path: String, stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> TextureRect:
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch_mode
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.texture = load_texture(path, true)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func panel_style(bg: Color = Color(0.070, 0.060, 0.044, 0.92), border: Color = Color(0.66, 0.50, 0.24, 0.78), margins: Vector4 = Vector4(22, 18, 22, 18)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style

static func panel_texture_style(margins: Vector4 = Vector4(18, 14, 18, 14)) -> StyleBox:
	var texture := load_texture(PANEL_INK, true)
	if texture == null:
		return panel_style(Color(0.075, 0.068, 0.052, 0.95), Color(0.58, 0.46, 0.26, 0.86), margins)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	style.draw_center = true
	return style

static func button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func button_texture_style() -> StyleBox:
	var texture := load_texture(BUTTON_GOLD, true)
	if texture == null:
		return button_style(Color(0.22, 0.145, 0.060, 0.88), Color(0.82, 0.58, 0.22, 0.72))
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 10
	style.texture_margin_top = 8
	style.texture_margin_right = 10
	style.texture_margin_bottom = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.draw_center = true
	return style

static func slot_texture_style() -> StyleBox:
	var texture := load_texture(SLOT_ITEM, true)
	if texture == null:
		return panel_style(Color(0.10, 0.085, 0.06, 0.92), Color(0.68, 0.53, 0.28, 0.88), Vector4(8, 8, 8, 8))
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 10
	style.texture_margin_top = 10
	style.texture_margin_right = 10
	style.texture_margin_bottom = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.draw_center = true
	return style

static func apply_title(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	apply_label_shadow(label)

static func apply_body_label(label: Label, font_size: int = 16) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	apply_label_shadow(label, 0.55)

static func apply_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_texture_style())
	button.add_theme_stylebox_override("hover", button_style(Color(0.32, 0.205, 0.080, 0.95), Color(0.98, 0.72, 0.28, 0.88)))
	button.add_theme_stylebox_override("pressed", button_style(Color(0.16, 0.100, 0.044, 0.96), Color(0.66, 0.46, 0.18, 0.88)))
	button.add_theme_stylebox_override("disabled", button_style(Color(0.075, 0.065, 0.052, 0.78), Color(0.36, 0.30, 0.20, 0.58)))
	button.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.49, 0.42))
	# 音效接线（仅首次）
	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover)
	if not button.pressed.is_connected(_on_button_click):
		button.pressed.connect(_on_button_click)

static func _on_button_hover() -> void:
	AudioManager.play_sfx("ui_hover")

static func _on_button_click() -> void:
	AudioManager.play_sfx("ui_click")

static func apply_label_shadow(label: Label, alpha: float = 0.85) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, alpha))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
