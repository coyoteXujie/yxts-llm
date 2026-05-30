extends CharacterBody2D
class_name GameEntity
## 实体层 - 基类实体，组件容器

signal entity_ready(entity: GameEntity)
signal entity_removed(entity: GameEntity)

var entity_id: String
var entity_name: String
var entity_type: int = Constants.EntityType.NPC

var components: Dictionary = {}

func _ready() -> void:
	_init_components()
	entity_ready.emit(self)

func _process(delta: float) -> void:
	for comp in components.values():
		if comp.is_enabled:
			comp.update(delta)

func add_component(comp: BaseComponent) -> void:
	if not comp or not is_instance_valid(comp):
		return
	comp.init(self)
	var comp_name: String = comp.get_class()
	components[comp_name] = comp

func get_component(comp_type: Variant) -> BaseComponent:
	if comp_type is String:
		return components.get(comp_type, null)
	elif comp_type is GDScript:
		var comp_name: String = comp_type.get("class_name", "")
		return components.get(comp_name, null)
	return null

func has_component(comp_type: Variant) -> bool:
	return get_component(comp_type) != null

func remove_component(comp: BaseComponent) -> void:
	for key in components:
		if components[key] == comp:
			components.erase(key)
			break

func get_position() -> Vector2:
	return position

func set_position(pos: Vector2) -> void:
	position = pos
