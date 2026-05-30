extends Node
## 氛围系统 - 天气、昼夜、光照、环境音效

signal weather_changed(weather: int)
signal time_changed(time_of_day: int)
signal day_changed(day_number: int)
signal ambient_changed(intensity: float)

enum Weather {
	SUNNY,
	CLOUDY,
	RAIN,
	STORM,
	SNOW,
	FOG,
	MIST
}

enum TimeOfDay {
	DAWN,
	MORNING,
	NOON,
	AFTERNOON,
	EVENING,
	NIGHT,
	DEEP_NIGHT
}

var current_weather: int = Weather.SUNNY
var time_of_day: int = TimeOfDay.NOON
var day_number: int = 1
var _time_elapsed: float = 0.0
var _weather_duration: float = 300.0
var _current_weather_timer: float = 0.0

var _weather_intensity: float = 1.0
var _ambient_intensity: float = 1.0
var _fog_enabled: bool = false
var _fog_density: float = 0.0

func _ready() -> void:
	_update_ambient_for_time()

func _process(delta: float) -> void:
	_time_elapsed += delta
	_current_weather_timer += delta
	
	if _current_weather_timer >= _weather_duration:
		_change_weather()

func _change_weather() -> void:
	_current_weather_timer = 0.0
	_weather_duration = randf_range(120.0, 600.0)
	
	var possible_weather: Array = [Weather.SUNNY, Weather.CLOUDY]
	
	if time_of_day >= TimeOfDay.NIGHT or time_of_day <= TimeOfDay.DAWN:
		possible_weather.append(Weather.FOG)
	elif time_of_day == TimeOfDay.MORNING or time_of_day == TimeOfDay.EVENING:
		possible_weather.append(Weather.MIST)
	else:
		possible_weather.append_array([Weather.RAIN, Weather.STORM])
		if day_number > 30:
			possible_weather.append(Weather.SNOW)
	
	var new_weather: int = possible_weather[randi() % possible_weather.size()]
	set_weather(new_weather)

func set_weather(weather: int) -> void:
	if current_weather == weather:
		return
	
	current_weather = weather
	_weather_intensity = 1.0
	_apply_weather_effects()
	weather_changed.emit(weather)

func _apply_weather_effects() -> void:
	match current_weather:
		Weather.SUNNY:
			_weather_intensity = 1.0
			_fog_enabled = false
			_fog_density = 0.0
		Weather.CLOUDY:
			_weather_intensity = 0.8
			_fog_enabled = false
		Weather.RAIN:
			_weather_intensity = 0.6
			_fog_enabled = true
			_fog_density = 0.3
		Weather.STORM:
			_weather_intensity = 0.4
			_fog_enabled = true
			_fog_density = 0.5
		Weather.SNOW:
			_weather_intensity = 0.5
			_fog_enabled = true
			_fog_density = 0.4
		Weather.FOG:
			_weather_intensity = 0.3
			_fog_enabled = true
			_fog_density = 0.7
		Weather.MIST:
			_weather_intensity = 0.7
			_fog_enabled = true
			_fog_density = 0.4

func advance_time(delta_seconds: float) -> void:
	_time_elapsed += delta_seconds
	
	var old_time: int = time_of_day
	var time_slots: int = TimeOfDay.size()
	var time_per_slot: float = 300.0
	
	var new_time: int = int(_time_elapsed / time_per_slot) % time_slots
	
	if new_time != time_of_day:
		time_of_day = new_time
		time_changed.emit(time_of_day)
		_update_ambient_for_time()
	
	var new_day: int = int(_time_elapsed / (time_per_slot * time_slots)) + 1
	if new_day != day_number:
		day_number = new_day
		day_changed.emit(day_number)

func _update_ambient_for_time() -> void:
	match time_of_day:
		TimeOfDay.DAWN:
			_ambient_intensity = 0.4
		TimeOfDay.MORNING:
			_ambient_intensity = 0.7
		TimeOfDay.NOON:
			_ambient_intensity = 1.0
		TimeOfDay.AFTERNOON:
			_ambient_intensity = 0.8
		TimeOfDay.EVENING:
			_ambient_intensity = 0.5
		TimeOfDay.NIGHT:
			_ambient_intensity = 0.2
		TimeOfDay.DEEP_NIGHT:
			_ambient_intensity = 0.1
	
	_ambient_intensity *= _weather_intensity
	ambient_changed.emit(_ambient_intensity)

func get_weather_name() -> String:
	match current_weather:
		Weather.SUNNY: return "晴朗"
		Weather.CLOUDY: return "多云"
		Weather.RAIN: return "下雨"
		Weather.STORM: return "暴风雨"
		Weather.SNOW: return "大雪"
		Weather.FOG: return "大雾"
		Weather.MIST: return "薄雾"
	return "未知"

func get_time_name() -> String:
	match time_of_day:
		TimeOfDay.DAWN: return "黎明"
		TimeOfDay.MORNING: return "早晨"
		TimeOfDay.NOON: return "正午"
		TimeOfDay.AFTERNOON: return "下午"
		TimeOfDay.EVENING: return "黄昏"
		TimeOfDay.NIGHT: return "夜晚"
		TimeOfDay.DEEP_NIGHT: return "深夜"
	return "未知"

func is_night() -> bool:
	return time_of_day >= TimeOfDay.NIGHT

func is_day() -> bool:
	return time_of_day >= TimeOfDay.DAWN and time_of_day <= TimeOfDay.AFTERNOON

func get_ambient_color() -> Color:
	var base: Color
	
	if is_night():
		base = Color(0.1, 0.1, 0.2)
	elif time_of_day == TimeOfDay.DAWN:
		base = Color(1.0, 0.6, 0.4)
	elif time_of_day == TimeOfDay.EVENING:
		base = Color(0.8, 0.4, 0.3)
	else:
		base = Color(1.0, 1.0, 0.9)
	
	return base * _ambient_intensity

func is_rain_weather() -> bool:
	return current_weather in [Weather.RAIN, Weather.STORM]

func is_winter_time() -> bool:
	return day_number % 365 in range(300, 365) or day_number % 365 in range(0, 60)

func get_weather_particle_count() -> int:
	match current_weather:
		Weather.RAIN: return 200
		Weather.STORM: return 500
		Weather.SNOW: return 300
		Weather.FOG: return 100
		Weather.MIST: return 50
	return 0

func to_dictionary() -> Dictionary:
	return {
		"weather": current_weather,
		"time_of_day": time_of_day,
		"day_number": day_number,
		"time_elapsed": _time_elapsed,
		"weather_duration": _weather_duration,
		"weather_timer": _current_weather_timer,
		"ambient_intensity": _ambient_intensity
	}

func from_dictionary(data: Dictionary) -> void:
	current_weather = data.get("weather", Weather.SUNNY)
	time_of_day = data.get("time_of_day", TimeOfDay.NOON)
	day_number = data.get("day_number", 1)
	_time_elapsed = data.get("time_elapsed", 0.0)
	_weather_duration = data.get("weather_duration", 300.0)
	_current_weather_timer = data.get("weather_timer", 0.0)
	_ambient_intensity = data.get("ambient_intensity", 1.0)
