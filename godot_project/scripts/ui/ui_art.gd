extends RefCounted
class_name UiArt

const MAIN_MENU_BACKDROP := "res://assets/ui/main_menu_backdrop_v1.png"
const PANEL_INK := "res://assets/ui/panel_ink.png"
const BUTTON_GOLD := "res://assets/ui/button_gold.png"
const SLOT_ITEM := "res://assets/ui/slot_item.png"
const WORLD_MAP_BACKDROP := "res://assets/ui/world_map_backdrop_v1.png"

const COLOR_GOLD := Color(0.788, 0.663, 0.431)
const COLOR_GOLD_BRIGHT := Color(0.980, 0.860, 0.580)

# ── Shader 资源（加载后缓存） ──────────────────────────
var _panel_shader: Shader = null
var _button_shader: Shader = null
var _slot_shader: Shader = null

static func _get_panel_shader() -> Shader:
	var inst := _get_inst()
	if inst._panel_shader == null:
		inst._panel_shader = load("res://shaders/ui_panel.gdshader") as Shader
	return inst._panel_shader

static func _get_button_shader() -> Shader:
	var inst := _get_inst()
	if inst._button_shader == null:
		inst._button_shader = load("res://shaders/ui_button.gdshader") as Shader
	return inst._button_shader

static func _get_slot_shader() -> Shader:
	var inst := _get_inst()
	if inst._slot_shader == null:
		inst._slot_shader = load("res://shaders/ui_slot.gdshader") as Shader
	return inst._slot_shader

static func _get_inst() -> UiArt:
	var inst := Engine.get_singleton("UiArt") as UiArt
	if inst == null:
		inst = UiArt.new()
		# 注册为引擎单例以便跨场景复用
		# 如果没有自动加载，只能每次 new
	return inst


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

# ══════════════════════════════════════════════════════════════
# 旧接口 — StyleBoxFlat（纯色面板，当shader不可用时的fallback）
# ══════════════════════════════════════════════════════════════

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

# ══════════════════════════════════════════════════════════════
# 新接口 — 程序化shader面板背景（ColorRect + ShaderMaterial）
# ══════════════════════════════════════════════════════════════

## 创建水墨shader面板背景
## 替代 panel_ink.png 纹理的 StyleBoxTexture
## 添加到 parent 的最底层，返回 ColorRect
static func panel_shader_background(parent: Control, params: Dictionary = {}) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1.0, 1.0, 1.0, 1.0)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var mat := ShaderMaterial.new()
	mat.shader = _get_panel_shader()
	if mat.shader == null:
		# fallback：纯色背景
		rect.color = Color(0.070, 0.060, 0.044, 0.92)
		parent.add_child(rect)
		parent.move_child(rect, 0)
		return rect

	# 默认参数
	mat.set_shader_parameter("corner_radius", 0.06)
	mat.set_shader_parameter("border_width", 0.025)
	mat.set_shader_parameter("ink_intensity", 1.0)
	mat.set_shader_parameter("paper_color", Color(0.860, 0.800, 0.700, 1.0))
	mat.set_shader_parameter("ink_color", Color(0.045, 0.035, 0.025, 1.0))
	mat.set_shader_parameter("border_color", Color(0.66, 0.50, 0.24, 0.90))
	mat.set_shader_parameter("glow_color", Color(0.95, 0.75, 0.35, 0.50))
	mat.set_shader_parameter("bg_color", Color(0.070, 0.060, 0.044, 0.92))
	mat.set_shader_parameter("show_bg", true)

	for key in params:
		mat.set_shader_parameter(key, params[key])

	rect.material = mat
	parent.add_child(rect)
	parent.move_child(rect, 0)
	return rect

## 创建按钮shader材质
## 替代 button_gold.png 纹理的 StyleBoxTexture
## 返回 ShaderMaterial (需要设置到 button.material)
static func button_shader_material(params: Dictionary = {}) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_button_shader()
	if mat.shader == null:
		return mat  # 空材质，调用方回退

	mat.set_shader_parameter("corner_radius", 0.08)
	mat.set_shader_parameter("ink_intensity", 1.0)
	mat.set_shader_parameter("base_color", Color(0.220, 0.145, 0.060, 0.88))
	mat.set_shader_parameter("gold_color", Color(0.98, 0.72, 0.28, 0.88))
	mat.set_shader_parameter("border_ink", Color(0.045, 0.035, 0.025, 0.70))
	mat.set_shader_parameter("glow_color", Color(0.98, 0.84, 0.30, 0.35))

	for key in params:
		mat.set_shader_parameter(key, params[key])

	return mat

## 创建物品格子shader材质
## 替代 slot_item.png 纹理的 StyleBoxTexture
## 返回 ShaderMaterial（设置到 slot panel/container 的 material）
static func slot_shader_material(params: Dictionary = {}) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_slot_shader()
	if mat.shader == null:
		return mat

	mat.set_shader_parameter("corner_radius", 0.08)
	mat.set_shader_parameter("border_width", 0.025)
	mat.set_shader_parameter("bg_color", Color(0.10, 0.085, 0.06, 0.92))
	mat.set_shader_parameter("border_color", Color(0.68, 0.53, 0.28, 0.88))
	mat.set_shader_parameter("paper_tint", Color(0.860, 0.800, 0.700, 0.06))

	for key in params:
		mat.set_shader_parameter(key, params[key])

	return mat

# ── 按钮shader状态更新辅助 ──────────────────────────────

## 将普通按钮切换为shader按钮（替换 StyleBoxTexture 方式）
## 应用后按钮使用程序化金色水墨按钮
static func apply_button_shader(button: Button) -> void:
	var mat := button_shader_material()
	if mat.shader == null:
		# fallback: 使用原有纹理方式
		apply_button(button)
		return

	button.material = mat
	# 初始状态
	mat.set_shader_parameter("state_hover", 0.0)
	mat.set_shader_parameter("state_pressed", 0.0)
	mat.set_shader_parameter("state_disabled", 0.0)

	# 移除原有 StyleBox 覆盖
	button.remove_theme_stylebox_override("normal")
	button.remove_theme_stylebox_override("hover")
	button.remove_theme_stylebox_override("pressed")
	button.remove_theme_stylebox_override("disabled")

	# 颜色
	button.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.49, 0.42))

	# 使用信号绑定方式连接
	_connect_shader_signals(button)

	# 初始 disabled 状态
	button.disabled_changed.connect(_on_shader_disabled.bind(button))
	_on_shader_disabled(button)

	# 音效
	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover)
	if not button.pressed.is_connected(_on_button_click):
		button.pressed.connect(_on_button_click)


# ── 使用信号绑定方式（传递button引用） ──────────────────

static func _connect_shader_signals(button: Button) -> void:
	button.mouse_entered.connect(_on_shader_hover.bind(button))
	button.mouse_exited.connect(_on_shader_exit.bind(button))
	button.button_down.connect(_on_shader_press.bind(button))
	button.button_up.connect(_on_shader_release.bind(button))
	button.pressed.connect(_on_shader_click.bind(button))

static func _on_shader_hover(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_hover", 1.0)

static func _on_shader_exit(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_hover", 0.0)
		mat.set_shader_parameter("state_pressed", 0.0)

static func _on_shader_press(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_pressed", 1.0)

static func _on_shader_release(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_pressed", 0.0)

static func _on_shader_click(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_pressed", 1.0)
		btn.get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(btn) and btn.material is ShaderMaterial:
				btn.material.set_shader_parameter("state_pressed", 0.0)
		, CONNECT_ONE_SHOT)

static func _on_shader_disabled(btn: Button) -> void:
	var mat := btn.material as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.set_shader_parameter("state_disabled", 1.0 if btn.disabled else 0.0)

# ══════════════════════════════════════════════════════════════
# 旧接口 — apply_button（保留，用于向后兼容）
# ══════════════════════════════════════════════════════════════

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

# ══════════════════════════════════════════════════════════════
# 标签样式
# ══════════════════════════════════════════════════════════════

static func apply_title(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	apply_label_shadow(label)

static func apply_body_label(label: Label, font_size: int = 16) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	apply_label_shadow(label, 0.55)

# ══════════════════════════════════════════════════════════════
# 便捷方法：创建带shader背景的面板容器
# ══════════════════════════════════════════════════════════════

## 创建带水墨shader背景的 PanelContainer
## 返回 PanelContainer（可直接 add_child）
## 替代 panel_texture_style() + PanelContainer 组合
static func make_shader_panel(size: Vector2, shader_params: Dictionary = {}) -> PanelContainer:
	var container := PanelContainer.new()
	container.size = size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 使用 StyleBoxFlat 作为基础（轻量），shader 背景覆盖在上面
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # 透明，由 shader 渲染
	container.add_theme_stylebox_override("panel", style)

	# 添加 shader 背景 ColorRect
	panel_shader_background(container, shader_params)

	return container
