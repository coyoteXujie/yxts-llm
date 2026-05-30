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
