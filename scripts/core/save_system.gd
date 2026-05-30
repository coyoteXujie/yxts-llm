extends Node
## 核心框架层 - 存档系统
## 仅负责持久化，不包含业务逻辑

signal save_started(slot: int)
signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_started(slot: int)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)
signal delete_completed(slot: int)

var _current_slot: int = -1
var _save_cache: Dictionary = {}

func _ready() -> void:
	_ensure_save_dir()

func save(slot: int, game_data: Dictionary) -> bool:
	if slot < 1 or slot > Constants.MAX_SAVE_SLOTS:
		return _fail_save(slot, "Invalid slot")

	save_started.emit(slot)
	game_data["save_version"] = Constants.SAVE_VERSION
	game_data["saved_at"] = Time.get_datetime_string_from_system()

	var save_path: String = _get_save_path(slot)
	var json: String = JSON.stringify(game_data, "  ")
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		return _fail_save(slot, str(FileAccess.get_open_error()))
	
	file.store_string(json)
	file.close()

	_save_metadata(slot, game_data)
	_current_slot = slot
	save_completed.emit(slot)
	_save_cache[slot] = game_data
	return true

func load(slot: int) -> Dictionary:
	if slot < 1 or slot > Constants.MAX_SAVE_SLOTS:
		load_failed.emit(slot, "Invalid slot")
		return {}

	if not has_save(slot):
		load_failed.emit(slot, "No save file")
		return {}

	load_started.emit(slot)
	var save_path: String = _get_save_path(slot)
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		load_failed.emit(slot, str(FileAccess.get_open_error()))
		return {}
	
	var json_str: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_str)
	if parse_result != OK:
		load_failed.emit(slot, "JSON parse failed")
		return {}

	var data: Dictionary = json.get_data()
	if not _validate_data(data):
		load_failed.emit(slot, "Data validation failed")
		return {}

	_current_slot = slot
	load_completed.emit(slot)
	_save_cache[slot] = data
	return data

func delete_save(slot: int) -> bool:
	if not has_save(slot):
		delete_completed.emit(slot)
		return true

	var save_path: String = _get_save_path(slot)
	var meta_path: String = _get_metadata_path(slot)
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(meta_path)

	if _save_cache.has(slot):
		_save_cache.erase(slot)

	delete_completed.emit(slot)
	return true

func has_save(slot: int) -> bool:
	if _save_cache.has(slot):
		return true
	return FileAccess.file_exists(_get_save_path(slot))

func get_save_info(slot: int) -> Dictionary:
	var meta_path: String = _get_metadata_path(slot)
	if not FileAccess.file_exists(meta_path):
		return {}
	
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_str: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_str) != OK:
		return {}

	return json.get_data()

func get_all_save_info() -> Array:
	var infos: Array = []
	for slot in range(1, Constants.MAX_SAVE_SLOTS + 1):
		infos.append(get_save_info(slot))
	return infos

func get_current_slot() -> int:
	return _current_slot

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(Constants.SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(Constants.SAVE_PATH)

func _get_save_path(slot: int) -> String:
	return Constants.SAVE_PATH + "save_%02d.sav" % slot

func _get_metadata_path(slot: int) -> String:
	return Constants.SAVE_PATH + "save_%02d.meta" % slot

func _save_metadata(slot: int, data: Dictionary) -> void:
	var meta: Dictionary = {
		"slot": slot,
		"version": Utils.safe_string(data.get("save_version", "1.0")),
		"saved_at": Utils.safe_string(data.get("saved_at", "")),
		"player_name": Utils.safe_string(data.get("player", {}).get("player_name", "Unknown")),
		"player_level": Utils.safe_int(data.get("player", {}).get("level", 1)),
		"play_time": Utils.safe_float(data.get("player", {}).get("play_time_seconds", 0.0))
	}

	var path: String = _get_metadata_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(meta, "  "))
		file.close()

func _validate_data(data: Dictionary) -> bool:
	if not data.has("save_version"):
		return false
	if not data.has("player"):
		return false
	return true

func _fail_save(slot: int, error_msg: String) -> bool:
	save_failed.emit(slot, error_msg)
	return false
