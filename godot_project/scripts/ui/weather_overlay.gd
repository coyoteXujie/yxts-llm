extends ColorRect
class_name WeatherOverlay

# GPU 驱动的天气/氛围粒子层
# 挂载在 CanvasLayer 中，在 atmosphere_layer 和 HUD 之间

var _shader_material: ShaderMaterial
var _current_weather := "晴朗"
var _current_theme := "plain"
var _sect_aura := false
var _sect_color := Color(1.0, 0.86, 0.38, 0.28)
var _hour := 8.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = preload("res://shaders/ink_weather.gdshader")
	material = _shader_material

func set_weather(weather: String) -> void:
	if _shader_material == null:
		return
	_current_weather = weather
	match weather:
		"细雨":
			_shader_material.set_shader_parameter("weather_type", 1.0)
		"飞雪":
			_shader_material.set_shader_parameter("weather_type", 2.0)
		"薄雾":
			_shader_material.set_shader_parameter("weather_type", 3.0)
		"多云":
			_shader_material.set_shader_parameter("weather_type", 4.0)
		_:
			if _current_theme == "desert":
				_shader_material.set_shader_parameter("weather_type", 5.0)
			elif _current_theme in ["flower", "flower_sect"]:
				_shader_material.set_shader_parameter("weather_type", 6.0)
			else:
				_shader_material.set_shader_parameter("weather_type", 0.0)

func set_region_theme(theme: String) -> void:
	_current_theme = theme
	# 根据地貌增加/减少粒子密度
	var density := 1.0
	match theme:
		"forest", "flower", "flower_sect":
			density = 1.4
		"desert":
			density = 1.6
		"water_city", "city":
			density = 0.6
		"snow", "snow_sect":
			density = 1.2
		"flame_sect":
			density = 1.3
		_:
			density = 1.0
	
	if _shader_material:
		_shader_material.set_shader_parameter("particle_density", density)

func set_sect_aura(has_aura: bool, color: Color) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("sect_aura", 1.0 if has_aura else 0.0)
		_shader_material.set_shader_parameter("sect_color", color)
