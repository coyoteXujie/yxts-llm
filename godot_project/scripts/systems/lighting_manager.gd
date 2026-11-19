extends Node
class_name LightingManager
## 2D 区域照明系统
##
## 管理 PointLight2D + DirectionalLight2D + LightOccluder2D，根据区域配置、
## 时段、门派气场调整动态光照。通过 PostFXManager 控制环境光，
## 通过子节点管理 2D 光源。
##
## 用法：main.gd 中初始化并设置当前区域

## --- 外部引用 ---
var world_env_node: WorldEnvironment

## --- 状态 ---
var current_region: Dictionary = {}
var previous_region: Dictionary = {}
var time_of_day: float = 0.5          # 0.0=子夜, 0.25=晨, 0.5=正午, 0.75=黄昏
var target_time_of_day: float = 0.5
var is_transitioning := false
var transition_progress := 1.0        # 1.0=完成

# 门派气场
var sect_aura_active := false
var sect_aura_color := Color(1.0, 0.86, 0.38, 0.28)
var sect_aura_intensity := 0.0
var target_sect_aura_intensity := 0.0

## 光源节点（不写类型标注以避免 Godot 4 泛型加载问题）
var ambient_light           # PointLight2D — 氛围主光
var sun_light               # PointLight2D — 太阳/月光
var sect_glow_light         # PointLight2D — 门派气场光晕
var _light_occluders: Array = []

## --- 常量 ---
const LIGHT_TRANSITION_SPEED := 2.0
const AURA_TRANSITION_SPEED := 1.5
const SECT_RING_COUNT := 3

## --- 颜色方案：门派气场 ---
const SECT_AURA_COLORS := {
	"snow_sect": Color(0.62, 0.82, 1.0, 0.28),
	"flame_sect": Color(1.0, 0.60, 0.24, 0.36),
	"shadow_sect": Color(0.58, 0.40, 0.88, 0.28),
	"flower_sect": Color(1.0, 0.82, 0.92, 0.32),
	"water_sect": Color(0.76, 0.96, 1.0, 0.30),
	"daoist_sect": Color(0.88, 0.92, 0.76, 0.28),
	"sect": Color(1.0, 0.86, 0.38, 0.28),
}

func _ready() -> void:
	# 如果未设置 world_env_node，从 PostFXManager 获取
	if world_env_node == null and PostFXManager.has_method("get_world_environment"):
		world_env_node = PostFXManager.get_world_environment()

	_setup_lights()

	# 连接信号
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.region_changed.connect(_on_region_changed)

## 初始化光源节点（使用 PointLight2D — Godot 4 2D 光照）
func _setup_lights() -> void:
	# 用一个 CanvasLayer 让光照覆盖游戏世界
	var light_layer := CanvasLayer.new()
	light_layer.name = "LightingLayer"
	light_layer.layer = 0
	add_child(light_layer)

	# 氛围主光（环境色）
	ambient_light = PointLight2D.new()
	ambient_light.name = "AmbientLight"
	ambient_light.enabled = true
	ambient_light.energy = 0.6
	ambient_light.shadow_enabled = false
	ambient_light.texture_scale = 10.0
	light_layer.add_child(ambient_light)

	# 太阳/月光
	sun_light = PointLight2D.new()
	sun_light.name = "SunLight"
	sun_light.enabled = true
	sun_light.energy = 0.8
	sun_light.shadow_enabled = false
	sun_light.texture_scale = 5.0
	light_layer.add_child(sun_light)

	# 门派气场光晕
	sect_glow_light = PointLight2D.new()
	sect_glow_light.name = "SectGlowLight"
	sect_glow_light.enabled = false
	sect_glow_light.energy = 0.3
	sect_glow_light.shadow_enabled = false
	sect_glow_light.texture_scale = 8.0
	light_layer.add_child(sect_glow_light)

## 获取 CanvasLayer 引用以供外部添加 occluder
func get_light_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer and child.name == "LightingLayer":
			return child
	return null

## 为地图瓦片添加遮光器
func add_occluder(rect: Rect2, color := Color(1, 1, 1, 1)) -> LightOccluder2D:
	var occluder := LightOccluder2D.new()
	var occluder_polygon := OccluderPolygon2D.new()
	var polygon := PackedVector2Array([
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.end.x, rect.position.y),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.position.x, rect.end.y)
	])
	occluder_polygon.polygon = polygon
	occluder_polygon.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
	occluder.occluder = occluder_polygon
	occluder.color = color

	var light_layer := get_light_layer()
	if light_layer != null:
		light_layer.add_child(occluder)

	_light_occluders.append(occluder)
	return occluder

## 清除所有遮光器
func clear_occluders() -> void:
	for occluder in _light_occluders:
		if is_instance_valid(occluder):
			occluder.queue_free()
	_light_occluders.clear()

## 设置当前区域（由 main.gd 在区域切换时调用）
func set_region(region: Dictionary) -> void:
	if region.is_empty():
		return
	previous_region = current_region.duplicate(true)
	current_region = region.duplicate(true)
	is_transitioning = true
	transition_progress = 0.0

## 设置门派气场
func set_sect_aura(active: bool, color: Color) -> void:
	sect_aura_active = active
	sect_aura_color = color
	target_sect_aura_intensity = 0.6 if active else 0.0

func _on_time_changed(_day: int, hour: float, _weather: String) -> void:
	target_time_of_day = hour / 24.0

func _on_region_changed(next_region: Dictionary, _state: Dictionary) -> void:
	set_region(next_region)

func _process(delta: float) -> void:
	# 平滑过渡 time_of_day
	time_of_day = move_toward(time_of_day, target_time_of_day, delta * 0.5)

	# 更新环境光
	_update_ambient_light(delta)
	_update_sun_light(delta)
	_update_sect_glow(delta)

	# 过渡进度
	if is_transitioning:
		transition_progress = move_toward(transition_progress, 1.0, delta * LIGHT_TRANSITION_SPEED)
		if transition_progress >= 0.99:
			transition_progress = 1.0
			is_transitioning = false

## 更新环境光：根据时段和区域地形
func _update_ambient_light(_delta: float) -> void:
	var env := _get_environment()
	if env == null:
		return

	# 基础环境光根据时段变化
	var base_energy := 0.45
	var base_color := Color(0.88, 0.82, 0.72)

	# 时段因子
	var day_factor := _daylight_curve(time_of_day)

	# 正午暖色，夜晚冷色
	var energy := base_energy * (0.5 + day_factor * 0.8)
	var color := Color(
		base_color.r * (0.8 + day_factor * 0.4),
		base_color.g * (0.7 + day_factor * 0.4),
		base_color.b * (0.5 + day_factor * 0.6)
	)

	# 区域地形影响
	if not current_region.is_empty():
		var terrain := str(current_region.get("terrain", ""))
		if terrain.contains("snow"):
			color = color.lerp(Color(0.78, 0.88, 1.0), 0.3)
			energy *= 1.15
		elif terrain.contains("desert"):
			color = color.lerp(Color(1.0, 0.82, 0.56), 0.2)
			energy *= 1.1
		elif _terrain_has_water(terrain):
			color = color.lerp(Color(0.68, 0.84, 0.90), 0.2)
		elif terrain.contains("forest"):
			color = color.lerp(Color(0.56, 0.72, 0.48), 0.15)
			energy *= 0.9

	# 应用到 WorldEnvironment
	env.ambient_light_color = color
	env.ambient_light_energy = energy

	# 也更新 PointLight2D 氛围光
	if ambient_light != null and is_instance_valid(ambient_light):
		ambient_light.color = color
		ambient_light.energy = energy * 0.3

## 更新太阳/月光
func _update_sun_light(_delta: float) -> void:
	if sun_light == null or not is_instance_valid(sun_light):
		return

	var day_factor := _daylight_curve(time_of_day)

	# 太阳位置：从左到右移动
	var sun_angle := lerpf(-PI * 0.5, PI * 0.5, day_factor)
	sun_light.position = Vector2(cos(sun_angle) * 200, -sin(sun_angle) * 150)

	# 日光能量
	var energy := 0.15 + day_factor * 0.85
	var color := Color(1.0, 0.92, 0.78)

	if day_factor < 0.2:
		# 夜晚：月光
		color = Color(0.54, 0.60, 0.78)
		energy = 0.25 * (day_factor / 0.2)
	elif day_factor < 0.35:
		# 黎明：日出暖光
		var dawn_t := (day_factor - 0.2) / 0.15
		color = Color(1.0, 0.5 + dawn_t * 0.42, 0.2 + dawn_t * 0.58)
	elif day_factor > 0.75:
		# 黄昏：日落暖光
		var dusk_t := (day_factor - 0.75) / 0.25
		color = Color(1.0, 0.65 + (1.0 - dusk_t) * 0.27, 0.4 + (1.0 - dusk_t) * 0.38)

	sun_light.color = color
	sun_light.energy = energy * 0.6

## 更新门派气场光晕
func _update_sect_glow(_delta: float) -> void:
	if sect_glow_light == null or not is_instance_valid(sect_glow_light):
		return

	sect_aura_intensity = move_toward(sect_aura_intensity, target_sect_aura_intensity, _delta * AURA_TRANSITION_SPEED)

	if sect_aura_intensity < 0.01:
		sect_glow_light.enabled = false
		return

	sect_glow_light.enabled = true
	sect_glow_light.color = sect_aura_color
	sect_glow_light.energy = sect_aura_intensity * 0.4

	# 轻微脉动
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.1
	sect_glow_light.texture_scale = 8.0 * pulse

## 获取 Environment 引用
func _get_environment() -> Environment:
	if world_env_node != null and is_instance_valid(world_env_node):
		return world_env_node.environment
	return null

## 时段曲线: 0.0 (子夜) → 0.5 (正午) → 1.0 (子夜)
func _daylight_curve(t: float) -> float:
	var day_angle := t * TAU
	var height := sin(day_angle - PI * 0.5)
	return clampf((height + 1.0) * 0.5, 0.0, 1.0)

## 从 atmosphere_layer 获取的 theme 字符串推导门派气场
func resolve_sect_theme_aura(theme: String) -> Dictionary:
	var color: Color = SECT_AURA_COLORS.get(theme, Color(1.0, 0.86, 0.38, 0.28))
	var active := SECT_AURA_COLORS.has(theme)
	return {"active": active, "color": color}

## 便捷方法：由 AtmosphereLayer 调用同步 aura
func apply_atmosphere_aura(theme: String) -> void:
	var aura := resolve_sect_theme_aura(theme)
	set_sect_aura(aura["active"], aura["color"])

static func _terrain_has_water(terrain: String) -> bool:
	return terrain.contains("river") or terrain.contains("lake") \
		or terrain.contains("water") or terrain.contains("canal") \
		or terrain.contains("marsh") or terrain.contains("spring") \
		or terrain.contains("ford") or terrain.contains("tide")
