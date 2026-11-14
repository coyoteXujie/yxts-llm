extends ColorRect

# 水墨后处理全屏叠加层
# 挂载在 CanvasLayer 顶层，采样 SCREEN_TEXTURE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/ink_wash_postfx.gdshader")
	
	# 从项目设置加载初始值
	var settings := {
		intensity = ProjectSettings.get_setting("yxts/postfx/intensity", 0.85),
		ink_bleed = ProjectSettings.get_setting("yxts/postfx/ink_bleed", 3.0),
		warm_tone = ProjectSettings.get_setting("yxts/postfx/warm_tone", 0.35),
		paper_strength = ProjectSettings.get_setting("yxts/postfx/paper_strength", 0.060),
		vignette_strength = ProjectSettings.get_setting("yxts/postfx/vignette", 0.55),
	}
	for key in settings:
		material.set_shader_parameter(key, settings[key])
	
	# 听 setting 变更事件
	EventBus.postfx_settings_changed.connect(_on_settings_changed)

func set_shader_param(name: String, value) -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter(name, value)

func _on_settings_changed(params: Dictionary) -> void:
	for key in params:
		set_shader_param(key, params[key])

# 便捷调节方法
func set_intensity(v: float) -> void:
	set_shader_param("intensity", clamp(v, 0.0, 1.0))

func set_warm_tone(v: float) -> void:
	set_shader_param("warm_tone", clamp(v, 0.0, 1.0))

func set_ink_bleed(v: float) -> void:
	set_shader_param("ink_bleed", clamp(v, 0.0, 6.0))

func set_paper_strength(v: float) -> void:
	set_shader_param("paper_strength", clamp(v, 0.0, 0.15))

func set_vignette(v: float) -> void:
	set_shader_param("vignette_strength", clamp(v, 0.0, 1.0))

func toggle_on() -> void:
	set_shader_param("intensity", 0.85)

func toggle_off() -> void:
	set_shader_param("intensity", 0.0)
