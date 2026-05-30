extends Node
class_name GameStateMachine
## 核心框架层 - 状态机基类
## 通用的有限状态机实现

signal state_changed(old_state: int, new_state: int)
signal state_enter(state: int)
signal state_exit(state: int)

var current_state: int = -1
var previous_state: int = -1
var state_stack: Array[int] = []
var state_transitions: Dictionary = {}
var state_callbacks: Dictionary = {}

func set_initial_state(state: int) -> void:
	if current_state == -1:
		current_state = state
		previous_state = state
		state_enter.emit(state)

func change_state(new_state: int) -> void:
	if current_state == new_state:
		return
	var old_state = current_state
	if can_transition(current_state, new_state):
		exit_state(current_state)
		previous_state = old_state
		current_state = new_state
		enter_state(new_state)
		state_changed.emit(old_state, new_state)

func push_state(new_state: int) -> void:
	if current_state != -1:
		state_stack.push_back(current_state)
	change_state(new_state)

func pop_state() -> void:
	if not state_stack.is_empty():
		var prev: int = state_stack.pop_back()
		change_state(prev)

func can_transition(from_state: int, to_state: int) -> bool:
	if not state_transitions.has(str(from_state)):
		return true
	var allowed: Array = state_transitions[str(from_state)]
	return allowed.is_empty() or allowed.has(to_state)

func set_transitions(transitions: Dictionary) -> void:
	state_transitions = transitions.duplicate()

func set_state_callbacks(callbacks: Dictionary) -> void:
	state_callbacks = callbacks.duplicate()

func enter_state(state: int) -> void:
	if state_callbacks.has("enter_" + str(state)):
		var cb: Callable = state_callbacks["enter_" + str(state)]
		cb.call()
	state_enter.emit(state)

func exit_state(state: int) -> void:
	if state_callbacks.has("exit_" + str(state)):
		var cb: Callable = state_callbacks["exit_" + str(state)]
		cb.call()
	state_exit.emit(state)

func update_state(delta: float) -> void:
	if state_callbacks.has("update_" + str(current_state)):
		var cb: Callable = state_callbacks["update_" + str(current_state)]
		cb.call(delta)

func get_state() -> int:
	return current_state

func is_in_state(state: int) -> bool:
	return current_state == state

func reset() -> void:
	state_stack.clear()
	current_state = -1
	previous_state = -1
