extends Node
## 世界层 - 世界管理器

signal zone_loaded(zone_id: String)
signal zone_unloaded(zone_id: String)
signal weather_changed(weather: int)
signal time_changed(time: int)

var current_zone_id: String = ""
var day_number: int = 1
var weather: int = Constants.Weather.SUNNY
var time_of_day: int = Constants.TimeOfDay.NOON

func load_zone(zone_id: String) -> void:
	if zone_id == current_zone_id:
		return
	
	if not current_zone_id.is_empty():
		unload_current_zone()
	
	current_zone_id = zone_id
	zone_loaded.emit(zone_id)

func unload_current_zone() -> void:
	if not current_zone_id.is_empty():
		zone_unloaded.emit(current_zone_id)
		current_zone_id = ""

func get_current_zone() -> String:
	return current_zone_id

func change_weather(new_weather: int) -> void:
	if weather == new_weather:
		return
	weather = new_weather
	weather_changed.emit(weather)
	EventBus.weather_changed.emit(weather)

func advance_time() -> void:
	time_of_day = (time_of_day + 1) % 6
	time_changed.emit(time_of_day)
	EventBus.time_changed.emit(time_of_day)
