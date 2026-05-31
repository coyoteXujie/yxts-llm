extends Control
class_name AtmosphereLayer

var weather := "晴朗"
var hour := 8.0
var region: Dictionary = {}
var phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.region_changed.connect(_on_region_changed)
	_on_time_changed(GameState.day, GameState.hour, GameState.weather)
	_on_region_changed(GameData.get_region(GameState.current_region_id), GameState.get_region_state(GameState.current_region_id))

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _on_time_changed(_day: int, next_hour: float, next_weather: String) -> void:
	hour = next_hour
	weather = next_weather
	queue_redraw()

func _on_region_changed(next_region: Dictionary, _state: Dictionary) -> void:
	region = next_region
	queue_redraw()

func _draw() -> void:
	var canvas := Rect2(Vector2.ZERO, size)
	if canvas.size.x <= 0.0 or canvas.size.y <= 0.0:
		return
	_draw_region_tint(canvas)
	_draw_time_tint(canvas)
	_draw_weather(canvas)
	_draw_region_motif(canvas)
	_draw_vignette(canvas)

func _draw_region_tint(canvas: Rect2) -> void:
	if region.is_empty():
		return
	var terrain := str(region.get("terrain", ""))
	var tint := Color(0.15, 0.13, 0.09, 0.035)
	if terrain.find("water") >= 0 or terrain.find("river") >= 0 or terrain.find("lake") >= 0 or terrain.find("canal") >= 0:
		tint = Color(0.10, 0.22, 0.28, 0.060)
	elif terrain.find("mountain") >= 0 or terrain.find("cliff") >= 0 or terrain.find("pass") >= 0:
		tint = Color(0.18, 0.18, 0.16, 0.060)
	elif terrain.find("forest") >= 0 or terrain.find("bamboo") >= 0 or terrain.find("garden") >= 0:
		tint = Color(0.08, 0.22, 0.12, 0.055)
	elif terrain.find("desert") >= 0 or terrain.find("plateau") >= 0:
		tint = Color(0.30, 0.20, 0.09, 0.060)
	elif terrain.find("snow") >= 0:
		tint = Color(0.18, 0.26, 0.34, 0.070)
	elif str(region.get("type", "")) == "city":
		tint = Color(0.26, 0.18, 0.08, 0.045)
	draw_rect(canvas, tint, true)

	var danger := int(region.get("danger", 0))
	if danger >= 3:
		draw_rect(canvas, Color(0.28, 0.05, 0.03, 0.018 * float(danger)), true)

func _region_theme() -> String:
	if region.is_empty():
		return "plain"
	var region_id := str(region.get("id", ""))
	var region_type := str(region.get("type", ""))
	var terrain := str(region.get("terrain", ""))
	if terrain.find("snow") >= 0 or region_id.find("xueshan") >= 0:
		return "snow_sect" if region_type == "sect" else "snow"
	if region_id.find("honglian") >= 0:
		return "flame_sect"
	if terrain.find("shadow") >= 0 or region_id.find("naja") >= 0:
		return "shadow_sect"
	if terrain.find("flower") >= 0 or region_id.find("flower") >= 0:
		return "flower_sect" if region_type == "sect" else "flower"
	if terrain.find("lake_palace") >= 0 or region_id.find("xiaoyao") >= 0:
		return "water_sect"
	if terrain.find("daoist") >= 0 or region_id.find("taiji") >= 0:
		return "daoist_sect"
	if region_type == "sect" or terrain == "sect":
		return "sect"
	if _is_water_terrain(terrain):
		return "water_city" if region_type == "city" else "water"
	if region_type == "city":
		return "city"
	if region_type == "town" or terrain.find("town") >= 0:
		return "town"
	if terrain.find("garden") >= 0:
		return "flower"
	if terrain.find("forest") >= 0 or terrain.find("bamboo") >= 0:
		return "forest"
	if terrain.find("desert") >= 0 or terrain.find("plateau") >= 0:
		return "desert"
	if terrain.find("spring") >= 0 or terrain.find("bath") >= 0:
		return "spring"
	if _is_mountain_terrain(terrain):
		return "mountain"
	if terrain.find("mound") >= 0:
		return "mound"
	if terrain.find("field") >= 0 or terrain.find("plain") >= 0 or terrain.find("town") >= 0:
		return "plain"
	return "plain"

func _is_water_terrain(terrain: String) -> bool:
	return (
		terrain.find("water") >= 0
		or terrain.find("river") >= 0
		or terrain.find("lake") >= 0
		or terrain.find("canal") >= 0
		or terrain.find("marsh") >= 0
		or terrain.find("ford") >= 0
		or terrain.find("tide") >= 0
		or terrain.find("weir") >= 0
	)

func _is_mountain_terrain(terrain: String) -> bool:
	return (
		terrain.find("mountain") >= 0
		or terrain.find("cliff") >= 0
		or terrain.find("pass") >= 0
		or terrain.find("gorge") >= 0
		or terrain.find("valley") >= 0
	)

func _draw_time_tint(canvas: Rect2) -> void:
	if hour < 5.0 or hour >= 21.0:
		draw_rect(canvas, Color(0.02, 0.04, 0.10, 0.30), true)
	elif hour < 7.0:
		draw_rect(canvas, Color(0.42, 0.24, 0.12, 0.13), true)
	elif hour >= 18.0:
		draw_rect(canvas, Color(0.36, 0.16, 0.08, 0.16), true)
	elif hour >= 12.0 and hour < 15.0:
		draw_rect(canvas, Color(1.0, 0.88, 0.58, 0.035), true)

func _draw_weather(canvas: Rect2) -> void:
	match weather:
		"细雨":
			_draw_rain(canvas)
		"飞雪":
			_draw_snow(canvas)
		"薄雾":
			_draw_fog(canvas, 0.12)
		"多云":
			_draw_cloud_shadows(canvas)
		_:
			_draw_sun_wash(canvas)

func _draw_region_motif(canvas: Rect2) -> void:
	match _region_theme():
		"water_city":
			_draw_water_mist(canvas, 0.78)
			_draw_lantern_glows(canvas, 0.56)
		"water":
			_draw_water_mist(canvas, 1.0)
		"city":
			_draw_lantern_glows(canvas, 0.78)
		"town":
			_draw_town_market_motes(canvas)
		"mountain":
			_draw_mountain_clouds(canvas)
		"forest":
			_draw_leaf_drift(canvas, Color(0.44, 0.66, 0.32, 0.24), 54)
		"flower":
			_draw_flower_petals(canvas)
		"desert":
			_draw_sand_drift(canvas)
		"spring":
			_draw_spring_steam(canvas)
		"mound":
			_draw_mound_wisps(canvas)
		"snow":
			_draw_snow_glimmer(canvas, 0.72)
		"snow_sect":
			_draw_snow_glimmer(canvas, 1.0)
			_draw_sect_aura(canvas, Color(0.62, 0.82, 1.0, 0.10), Color(0.94, 0.98, 1.0, 0.34))
		"flame_sect":
			_draw_ember_drift(canvas)
			_draw_sect_aura(canvas, Color(0.88, 0.22, 0.08, 0.10), Color(1.0, 0.60, 0.24, 0.36))
		"shadow_sect":
			_draw_shadow_wisps(canvas)
			_draw_sect_aura(canvas, Color(0.12, 0.08, 0.18, 0.13), Color(0.58, 0.40, 0.88, 0.28))
		"flower_sect":
			_draw_flower_petals(canvas)
			_draw_sect_aura(canvas, Color(0.86, 0.40, 0.68, 0.10), Color(1.0, 0.82, 0.92, 0.32))
		"water_sect":
			_draw_water_mist(canvas, 0.88)
			_draw_sect_aura(canvas, Color(0.24, 0.58, 0.72, 0.10), Color(0.76, 0.96, 1.0, 0.30))
		"daoist_sect":
			_draw_mountain_clouds(canvas)
			_draw_sect_aura(canvas, Color(0.40, 0.58, 0.52, 0.10), Color(0.88, 0.92, 0.76, 0.28))
		"sect":
			_draw_sect_aura(canvas, Color(0.72, 0.56, 0.22, 0.08), Color(1.0, 0.86, 0.38, 0.28))
		_:
			_draw_plain_motes(canvas)

	var danger := int(region.get("danger", 0))
	if danger >= 4:
		_draw_danger_edges(canvas, float(danger))

func _draw_water_mist(canvas: Rect2, strength: float) -> void:
	for i in range(8):
		var y := fposmod(float(i * 83) + phase * (9.0 + float(i % 3) * 1.7), canvas.size.y + 80.0) - 40.0
		var x_shift := sin(phase * 0.31 + float(i) * 1.7) * 58.0
		var width := canvas.size.x * (0.36 + float(i % 3) * 0.11)
		var alpha := (0.040 + float(i % 2) * 0.014) * strength
		draw_rect(Rect2(Vector2(x_shift - 80.0, y), Vector2(width, 18.0)), Color(0.72, 0.86, 0.88, alpha), true)
		draw_line(Vector2(x_shift + 18.0, y + 14.0), Vector2(x_shift + width - 42.0, y + 10.0), Color(0.78, 0.92, 0.94, alpha * 1.35), 1.1)
	for i in range(18):
		var x := fposmod(float(i * 137) + phase * 24.0, canvas.size.x + 70.0) - 35.0
		var y := 92.0 + fposmod(float(i * 71), max(canvas.size.y - 160.0, 80.0))
		var flicker := 0.5 + sin(phase * 1.8 + float(i)) * 0.5
		draw_line(Vector2(x - 8.0, y), Vector2(x + 12.0, y - 2.0), Color(0.86, 0.96, 1.0, (0.075 + flicker * 0.030) * strength), 1.15)

func _draw_lantern_glows(canvas: Rect2, strength: float) -> void:
	for i in range(13):
		var x := fposmod(float(i * 173) + sin(phase * 0.45 + float(i)) * 18.0, canvas.size.x + 96.0) - 48.0
		var y := 66.0 + fposmod(float(i * 91), max(canvas.size.y - 132.0, 96.0))
		var pulse := 0.5 + sin(phase * 2.2 + float(i) * 0.8) * 0.5
		draw_circle(Vector2(x, y), 18.0 + pulse * 5.0, Color(1.0, 0.56, 0.20, 0.040 * strength))
		draw_circle(Vector2(x, y), 4.0, Color(1.0, 0.76, 0.32, 0.110 * strength))
		draw_line(Vector2(x, y - 12.0), Vector2(x, y - 22.0), Color(0.45, 0.24, 0.10, 0.18 * strength), 1.0)

func _draw_town_market_motes(canvas: Rect2) -> void:
	_draw_lantern_glows(canvas, 0.42)
	for i in range(26):
		var x := fposmod(float(i * 109) + phase * 12.0, canvas.size.x + 48.0) - 24.0
		var y := 84.0 + fposmod(float(i * 73), max(canvas.size.y - 144.0, 96.0))
		var alpha := 0.08 + sin(phase * 1.3 + float(i)) * 0.025
		draw_circle(Vector2(x, y), 1.8, Color(0.96, 0.78, 0.36, alpha))
		if i % 4 == 0:
			draw_line(Vector2(x - 9.0, y + 7.0), Vector2(x + 10.0, y + 5.0), Color(0.78, 0.62, 0.38, 0.075), 1.0)

func _draw_mountain_clouds(canvas: Rect2) -> void:
	for i in range(7):
		var y := 42.0 + fposmod(float(i * 77) + phase * 7.0, canvas.size.y * 0.62)
		var x := fposmod(float(i * 211) + phase * (12.0 + float(i % 2) * 3.0), canvas.size.x + 260.0) - 160.0
		var alpha := 0.038 + float(i % 3) * 0.009
		draw_rect(Rect2(Vector2(x, y), Vector2(canvas.size.x * 0.44, 24.0)), Color(0.76, 0.80, 0.76, alpha), true)
		draw_circle(Vector2(x + 34.0, y + 13.0), 28.0, Color(0.78, 0.82, 0.78, alpha * 0.9))
		draw_circle(Vector2(x + 122.0, y + 9.0), 36.0, Color(0.72, 0.76, 0.74, alpha * 0.75))

func _draw_leaf_drift(canvas: Rect2, color: Color, count: int) -> void:
	for i in range(count):
		var x := fposmod(float(i * 89) + phase * (20.0 + float(i % 5) * 3.0), canvas.size.x + 60.0) - 30.0
		var y := fposmod(float(i * 47) + sin(phase * 0.8 + float(i)) * 34.0, canvas.size.y + 40.0) - 20.0
		var sway := sin(phase * 1.4 + float(i) * 0.6) * 5.0
		draw_line(Vector2(x, y), Vector2(x + 5.0 + sway, y + 7.0), color, 1.35)
		draw_circle(Vector2(x + sway * 0.25, y + 3.0), 1.2, color)

func _draw_flower_petals(canvas: Rect2) -> void:
	_draw_leaf_drift(canvas, Color(0.96, 0.74, 0.78, 0.24), 36)
	for i in range(28):
		var x := fposmod(float(i * 127) + phase * 18.0, canvas.size.x + 50.0) - 25.0
		var y := fposmod(float(i * 61) + phase * (10.0 + float(i % 4)), canvas.size.y + 50.0) - 25.0
		var radius := 1.4 + float(i % 3) * 0.45
		draw_circle(Vector2(x, y), radius, Color(1.0, 0.86, 0.88, 0.23))

func _draw_sand_drift(canvas: Rect2) -> void:
	draw_rect(canvas, Color(0.32, 0.22, 0.10, 0.045), true)
	for i in range(42):
		var x := fposmod(float(i * 113) + phase * 56.0, canvas.size.x + 150.0) - 75.0
		var y := fposmod(float(i * 67) + phase * 10.0, canvas.size.y + 60.0) - 30.0
		var length := 24.0 + float(i % 5) * 8.0
		draw_line(Vector2(x, y), Vector2(x + length, y - 8.0), Color(0.88, 0.70, 0.42, 0.12), 1.0)

func _draw_spring_steam(canvas: Rect2) -> void:
	for i in range(10):
		var y := fposmod(float(i * 67) - phase * (13.0 + float(i % 3) * 2.0), canvas.size.y + 80.0) - 40.0
		var x := fposmod(float(i * 151) + sin(phase + float(i)) * 52.0, canvas.size.x + 120.0) - 60.0
		draw_circle(Vector2(x, y), 38.0 + float(i % 3) * 12.0, Color(0.92, 0.82, 0.68, 0.032))
		draw_rect(Rect2(Vector2(x - 38.0, y - 8.0), Vector2(92.0, 18.0)), Color(0.92, 0.86, 0.72, 0.042), true)

func _draw_mound_wisps(canvas: Rect2) -> void:
	for i in range(12):
		var x := fposmod(float(i * 149) + sin(phase * 0.6 + float(i)) * 35.0, canvas.size.x + 90.0) - 45.0
		var y := fposmod(float(i * 73) - phase * 12.0, canvas.size.y + 70.0) - 35.0
		draw_line(Vector2(x, y), Vector2(x + 24.0, y - 16.0), Color(0.56, 0.58, 0.52, 0.095), 1.1)
		draw_circle(Vector2(x + 28.0, y - 18.0), 8.0, Color(0.30, 0.34, 0.32, 0.045))

func _draw_snow_glimmer(canvas: Rect2, strength: float) -> void:
	draw_rect(canvas, Color(0.10, 0.16, 0.22, 0.050 * strength), true)
	for i in range(44):
		var x := fposmod(float(i * 131) + sin(phase * 0.7 + float(i)) * 20.0, canvas.size.x + 50.0) - 25.0
		var y := fposmod(float(i * 59) + phase * (7.0 + float(i % 4)), canvas.size.y + 50.0) - 25.0
		var alpha := (0.13 + sin(phase * 2.0 + float(i)) * 0.04) * strength
		draw_line(Vector2(x - 4.0, y), Vector2(x + 4.0, y), Color(0.92, 0.98, 1.0, alpha), 1.0)
		draw_line(Vector2(x, y - 4.0), Vector2(x, y + 4.0), Color(0.92, 0.98, 1.0, alpha), 1.0)

func _draw_sect_aura(canvas: Rect2, wash: Color, spark: Color) -> void:
	draw_rect(canvas, wash, true)
	var center := Vector2(canvas.size.x * 0.52, canvas.size.y * 0.55)
	for i in range(4):
		var radius := 82.0 + float(i) * 46.0 + sin(phase * 0.7 + float(i)) * 5.0
		draw_arc(center, radius, phase * 0.22 + float(i), phase * 0.22 + float(i) + PI * 1.38, 96, spark, 1.25, true)
	for i in range(18):
		var angle := phase * (0.26 + float(i % 3) * 0.03) + float(i) * TAU / 18.0
		var radius := 80.0 + float(i % 5) * 34.0
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		if canvas.has_point(point):
			draw_circle(point, 2.0 + float(i % 3) * 0.45, spark)

func _draw_ember_drift(canvas: Rect2) -> void:
	for i in range(40):
		var x := fposmod(float(i * 97) + sin(phase * 1.2 + float(i)) * 20.0, canvas.size.x + 60.0) - 30.0
		var y := fposmod(float(i * 43) - phase * (22.0 + float(i % 5) * 3.0), canvas.size.y + 50.0) - 25.0
		var alpha := 0.16 + sin(phase * 1.8 + float(i)) * 0.05
		draw_circle(Vector2(x, y), 1.5 + float(i % 3) * 0.5, Color(1.0, 0.46, 0.16, alpha))

func _draw_shadow_wisps(canvas: Rect2) -> void:
	draw_rect(canvas, Color(0.03, 0.02, 0.05, 0.075), true)
	for i in range(16):
		var x := fposmod(float(i * 151) + phase * 10.0, canvas.size.x + 130.0) - 65.0
		var y := fposmod(float(i * 79) + sin(phase * 0.7 + float(i)) * 40.0, canvas.size.y + 80.0) - 40.0
		draw_rect(Rect2(Vector2(x, y), Vector2(118.0, 10.0)), Color(0.18, 0.12, 0.26, 0.060), true)
		draw_line(Vector2(x + 12.0, y + 9.0), Vector2(x + 94.0, y - 12.0), Color(0.28, 0.18, 0.36, 0.085), 1.1)

func _draw_plain_motes(canvas: Rect2) -> void:
	if hour < 7.0 or hour >= 18.0:
		return
	for i in range(24):
		var x := fposmod(float(i * 157) + phase * 6.0, canvas.size.x + 40.0) - 20.0
		var y := fposmod(float(i * 83) + sin(phase * 0.5 + float(i)) * 14.0, canvas.size.y + 40.0) - 20.0
		draw_circle(Vector2(x, y), 1.4, Color(1.0, 0.86, 0.46, 0.11))

func _draw_danger_edges(canvas: Rect2, danger: float) -> void:
	var alpha: float = min(0.10, 0.022 * danger)
	for i in range(5):
		var y := fposmod(float(i * 137) + phase * 19.0, canvas.size.y + 70.0) - 35.0
		draw_line(Vector2(0.0, y), Vector2(canvas.size.x, y - 26.0), Color(0.46, 0.05, 0.03, alpha), 1.25)

func _draw_rain(canvas: Rect2) -> void:
	draw_rect(canvas, Color(0.06, 0.10, 0.13, 0.13), true)
	for i in range(105):
		var x := fposmod(float(i * 73) + phase * 220.0, canvas.size.x + 90.0) - 45.0
		var y := fposmod(float(i * 41) + phase * 350.0, canvas.size.y + 80.0) - 40.0
		draw_line(Vector2(x, y), Vector2(x - 11.0, y + 28.0), Color(0.74, 0.86, 0.92, 0.30), 1.15)
	for i in range(8):
		var y_band := fposmod(float(i * 91) + phase * 12.0, canvas.size.y + 80.0) - 40.0
		draw_rect(Rect2(Vector2(0, y_band), Vector2(canvas.size.x, 22)), Color(0.58, 0.70, 0.76, 0.035), true)

func _draw_snow(canvas: Rect2) -> void:
	draw_rect(canvas, Color(0.12, 0.18, 0.24, 0.11), true)
	for i in range(85):
		var x := fposmod(float(i * 97) + sin(phase + float(i)) * 28.0, canvas.size.x + 50.0) - 25.0
		var y := fposmod(float(i * 53) + phase * (24.0 + float(i % 5) * 4.0), canvas.size.y + 60.0) - 30.0
		var radius := 1.1 + float(i % 4) * 0.35
		draw_circle(Vector2(x, y), radius, Color(1.0, 1.0, 1.0, 0.34))
	_draw_fog(canvas, 0.055)

func _draw_fog(canvas: Rect2, alpha: float) -> void:
	for i in range(7):
		var y := fposmod(float(i * 93) + phase * 9.0, canvas.size.y + 90.0) - 45.0
		var x_shift := sin(phase * 0.35 + float(i)) * 42.0
		draw_rect(Rect2(Vector2(x_shift - 60.0, y), Vector2(canvas.size.x + 120.0, 34.0)), Color(0.82, 0.84, 0.76, alpha), true)

func _draw_cloud_shadows(canvas: Rect2) -> void:
	for i in range(5):
		var x := fposmod(float(i * 287) + phase * 18.0, canvas.size.x + 260.0) - 160.0
		var y := 70.0 + float(i * 93 % 420)
		draw_circle(Vector2(x, y), 90.0, Color(0.03, 0.04, 0.04, 0.045))
		draw_circle(Vector2(x + 70.0, y + 20.0), 110.0, Color(0.03, 0.04, 0.04, 0.038))

func _draw_sun_wash(canvas: Rect2) -> void:
	if hour >= 7.0 and hour < 17.5:
		var center := Vector2(canvas.size.x * 0.78, canvas.size.y * 0.12)
		for i in range(5):
			draw_circle(center, 90.0 + float(i) * 50.0, Color(1.0, 0.86, 0.46, 0.018 - float(i) * 0.002))

func _draw_vignette(canvas: Rect2) -> void:
	var edge_alpha := 0.16
	if hour < 6.0 or hour >= 20.0:
		edge_alpha = 0.26
	draw_rect(Rect2(Vector2.ZERO, Vector2(canvas.size.x, 42)), Color(0, 0, 0, edge_alpha), true)
	draw_rect(Rect2(Vector2(0, canvas.size.y - 48), Vector2(canvas.size.x, 48)), Color(0, 0, 0, edge_alpha), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(48, canvas.size.y)), Color(0, 0, 0, edge_alpha * 0.82), true)
	draw_rect(Rect2(Vector2(canvas.size.x - 48, 0), Vector2(48, canvas.size.y)), Color(0, 0, 0, edge_alpha * 0.82), true)
