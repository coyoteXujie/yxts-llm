class_name MovementComponent extends BaseComponent
## 组件层 - 移动组件，完全独立！

signal moved(position: Vector2)
signal direction_changed(new_dir: Vector2)
signal started_moving()
signal stopped_moving()

var _speed: float = 200.0
var _direction: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _can_move: bool = true

func set_speed(speed: float) -> void:
	_speed = speed

func get_speed() -> float:
	return _speed

func set_direction(dir: Vector2) -> void:
	if dir.is_zero_approx():
		if _is_moving:
			_is_moving = false
			stopped_moving.emit()
		return
	
	var new_dir: Vector2 = dir.normalized()
	if not new_dir.is_equal_approx(_direction):
		_direction = new_dir
		direction_changed.emit(_direction)
	
	if not _is_moving:
		_is_moving = true
		started_moving.emit()

func get_direction() -> Vector2:
	return _direction

func is_moving() -> bool:
	return _is_moving

func set_can_move(can: bool) -> void:
	_can_move = can
	if not can and _is_moving:
		_is_moving = false
		stopped_moving.emit()

func move(current_pos: Vector2, delta: float) -> Vector2:
	if not _can_move or _is_moving:
		return current_pos
	
	var movement: Vector2 = _direction * _speed * delta
	var new_pos: Vector2 = current_pos + movement
	
	if not movement.is_zero_approx():
		moved.emit(new_pos)
	
	return new_pos

func stop() -> void:
	set_direction(Vector2.ZERO)

func reset() -> void:
	_direction = Vector2.ZERO
	_is_moving = false
	_can_move = true
