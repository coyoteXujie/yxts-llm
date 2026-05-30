extends Node

class_name SceneManager

signal scene_changed(scene_name: String)

const SCENE_PREFIX = "res://scenes/"

var _current_scene: String = "main"
var _scene_history: Array[String] = []

const SCENE_CONNECTIONS: Dictionary = {
	"main": {"north": "zhongnan_mountain", "east": "ba_qiao", "west": "wilderness_east", "south": "wilderness_south"},
	"zhongnan_mountain": {"south": "main", "north": "shaolin_temple"},
	"ba_qiao": {"west": "main"},
	"wilderness_east": {"east": "main"},
	"wilderness_south": {"north": "main"},
	"shaolin_temple": {"south": "zhongnan_mountain"},
}

func _ready() -> void:
	pass

func change_scene(scene_name: String, direction: String = "") -> void:
	if not SCENE_CONNECTIONS.has(_current_scene):
		push_warning("当前场景无连接配置: ", _current_scene)
		return
	
	var connections = SCENE_CONNECTIONS[_current_scene]
	if direction and connections.has(direction):
		var target = connections[direction]
		if target == scene_name:
			_load_scene(scene_name)
			return
	
	if scene_name in SCENE_CONNECTIONS:
		_load_scene(scene_name)
	else:
		push_warning("场景不存在: ", scene_name)

func _load_scene(scene_name: String) -> void:
	var scene_path = SCENE_PREFIX + scene_name + ".tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("场景文件不存在: ", scene_path)
		return
	
	_scene_history.append(_current_scene)
	_current_scene = scene_name
	
	var packed_scene = load(scene_path)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
		scene_changed.emit(scene_name)

func go_back() -> void:
	if _scene_history.size() > 0:
		var prev_scene = _scene_history.pop_back()
		_load_scene(prev_scene)

func get_current_scene() -> String:
	return _current_scene

func get_connections() -> Dictionary:
	return SCENE_CONNECTIONS.get(_current_scene, {})
