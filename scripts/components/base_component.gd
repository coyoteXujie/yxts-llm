class_name BaseComponent extends RefCounted
## 组件层 - 基类组件，所有组件的父类

var owner: Node
var is_initialized: bool = false
var is_enabled: bool = true

func init(owner_node: Node) -> void:
	owner = owner_node
	is_initialized = true
	_on_init()

func _on_init() -> void:
	pass

func update(delta: float) -> void:
	if not is_enabled:
		return
	_on_update(delta)

func _on_update(delta: float) -> void:
	pass

func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	if is_enabled:
		_on_enabled()
	else:
		_on_disabled()

func _on_enabled() -> void:
	pass

func _on_disabled() -> void:
	pass

func reset() -> void:
	_on_reset()

func _on_reset() -> void:
	pass
