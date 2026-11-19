extends Node
## 后处理管理器 (Autoload)
##
## 管理 WorldEnvironment（环境光+glow）和全屏 ColorRect（水墨 shader），
## 替代旧 ColorRect+SCREEN_TEXTURE 方案。支持叠加多层后处理效果、环境光控制、glow/bloom 配置。
##
## Godot 4.7 移除了 Environment.post_process_material，改用 CanvasLayer+ColorRect 
## + SCREEN_TEXTURE 实现全屏后处理，由本管理器统一创建和维护。

## --- 环境引用 ---
var world_env: WorldEnvironment
var env: Environment

## --- 后处理层 ---
var _shader_material: ShaderMaterial
var _postfx_layer: CanvasLayer
var _color_rect: ColorRect

## 当前活跃的后处理层列表 (预留多层叠加)
var active_postfx_layers: Array[Dictionary] = []

func _ready() -> void:
	_setup_world_environment()
	_setup_color_rect()
	_load_settings_from_project()
	_setup_signals()

func _setup_world_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "PostFXWorldEnvironment"
	
	env = Environment.new()
	env.background_mode = Environment.BG_KEEP
	
	# 启用内置 Glow/Bloom
	env.glow_enabled = true
	env.glow_intensity = 0.15
	env.glow_strength = 0.6
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.85
	env.glow_hdr_scale = 1.0
	
	# 环境光基础设置
	env.ambient_light_color = Color(0.88, 0.82, 0.72, 1.0)
	env.ambient_light_energy = 0.70
	env.ambient_light_sky_contribution = 0.0
	
	world_env.environment = env
	add_child(world_env)

func _setup_color_rect() -> void:
	# 创建一个 CanvasLayer 覆盖在最顶层
	_postfx_layer = CanvasLayer.new()
	_postfx_layer.name = "PostFXLayer"
	_postfx_layer.layer = 100
	add_child(_postfx_layer)
	
	# 全屏 ColorRect 承载水墨 shader
	_color_rect = ColorRect.new()
	_color_rect.name = "InkWashColorRect"
	_color_rect.color = Color(1, 1, 1, 0)  # 全透明基底
	_color_rect.anchor_left = 0.0
	_color_rect.anchor_top = 0.0
	_color_rect.anchor_right = 1.0
	_color_rect.anchor_bottom = 1.0
	_color_rect.offset_left = 0
	_color_rect.offset_top = 0
	_color_rect.offset_right = 0
	_color_rect.offset_bottom = 0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 挂载水墨 shader
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = preload("res://shaders/ink_wash_postfx.gdshader")
	_color_rect.material = _shader_material
	
	_postfx_layer.add_child(_color_rect)
	
	# 注册后处理层
	active_postfx_layers.append({
		"name": "ink_wash",
		"shader": _shader_material,
		"enabled": true
	})

## 获取环境引用，供 LightingManager 等系统调节光照
func get_environment() -> Environment:
	return env

func get_world_environment() -> WorldEnvironment:
	return world_env

## 获取 shader 材质
func get_shader_material() -> ShaderMaterial:
	return _shader_material

func _setup_signals() -> void:
	EventBus.postfx_settings_changed.connect(_on_settings_changed)

func _load_settings_from_project() -> void:
	if _shader_material == null:
		return
	var keys := PackedStringArray([
		"intensity", "ink_bleed", "warm_tone", "paper_strength",
		"vignette_strength", "ink_spread", "brush_stroke",
		"bloom_intensity", "bloom_threshold", "film_grain"
	])
	var defaults := {
		"intensity": 0.85, "ink_bleed": 3.0, "warm_tone": 0.35, "paper_strength": 0.060,
		"vignette_strength": 0.55, "ink_spread": 0.30, "brush_stroke": 0.35,
		"bloom_intensity": 0.25, "bloom_threshold": 0.60, "film_grain": 0.035
	}
	var settings := {
		"intensity": "yxts/postfx/intensity",
		"ink_bleed": "yxts/postfx/ink_bleed",
		"warm_tone": "yxts/postfx/warm_tone",
		"paper_strength": "yxts/postfx/paper_strength",
		"vignette_strength": "yxts/postfx/vignette",
		"ink_spread": "yxts/postfx/ink_spread",
		"brush_stroke": "yxts/postfx/brush_stroke",
		"bloom_intensity": "yxts/postfx/bloom_intensity",
		"bloom_threshold": "yxts/postfx/bloom_threshold",
		"film_grain": "yxts/postfx/film_grain"
	}
	for key in keys:
		var path: String = settings[key]
		var default_value = defaults[key]
		_shader_material.set_shader_parameter(key, ProjectSettings.get_setting(path, default_value))

func _on_settings_changed(params: Dictionary) -> void:
	for key in params:
		if _shader_material != null:
			_shader_material.set_shader_parameter(key, params[key])

## 叠加新增后处理层（预留）
func add_postfx_layer(name: String, shader: Shader) -> bool:
	if _has_layer(name):
		return false
	var mat := ShaderMaterial.new()
	mat.shader = shader
	active_postfx_layers.append({
		"name": name,
		"shader": mat,
		"enabled": true
	})
	return true

func _has_layer(name: String) -> bool:
	for layer in active_postfx_layers:
		if str(layer.get("name", "")) == name:
			return true
	return false

func set_layer_enabled(name: String, enabled: bool) -> void:
	for layer in active_postfx_layers:
		if str(layer.get("name", "")) == name:
			layer["enabled"] = enabled

## 便捷调节
func set_shader_param(name: String, value) -> void:
	if _shader_material != null:
		_shader_material.set_shader_parameter(name, value)

func set_intensity(v: float) -> void:
	set_shader_param("intensity", clampf(v, 0.0, 1.0))

func set_warm_tone(v: float) -> void:
	set_shader_param("warm_tone", clampf(v, 0.0, 1.0))

func set_bloom(v: float) -> void:
	set_shader_param("bloom_intensity", clampf(v, 0.0, 1.0))

func set_film_grain(v: float) -> void:
	set_shader_param("film_grain", clampf(v, 0.0, 0.15))

func toggle_ink_wash(on: bool) -> void:
	set_shader_param("intensity", 0.85 if on else 0.0)

func _process(delta: float) -> void:
	if _shader_material != null:
		var t: Variant = _shader_material.get_shader_parameter("time")
		if typeof(t) == TYPE_FLOAT:
			_shader_material.set_shader_parameter("time", float(t) + delta)
		else:
			_shader_material.set_shader_parameter("time", 0.0)
