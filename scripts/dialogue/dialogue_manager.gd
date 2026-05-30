extends Node
## 对话管理器单例 - 通过 Autoload 全局访问
## 处理游戏中所有对话逻辑

enum DialogueType {
	NARRATION,
	DIALOGUE,
	CHOICE,
	COMBAT,
	END
}

signal dialogue_started(npc_id: String)
signal dialogue_finished(npc_id: String)
signal node_changed(node: DialogueNode)
signal choice_made(choice_index: int, choice_text: String)
signal dialogue_variable_changed(variable_name: String, value: Variant)

var _current_npc_id: String = ""
var _current_node: DialogueNode = null
var _dialogue_history: Array[Dictionary] = []
var _is_active: bool = false
var _waiting_for_choice: bool = false
var _dialogue_variables: Dictionary = {}
var _loaded_dialogue_trees: Dictionary = {}

func _ready() -> void:
	_init_default_variables()

func _init_default_variables() -> void:
	_dialogue_variables["player_fame"] = 0
	_dialogue_variables["current_quest"] = ""
	_dialogue_variables["visited_count"] = {}
	_dialogue_variables["relationship"] = {}

func start_dialogue(npc_id: String) -> bool:
	if _is_active:
		return false

	var dialogue_tree: DialogueNode = _get_dialogue_tree_for_npc(npc_id)

	if not dialogue_tree:
		push_warning("DialogueManager: 找不到NPC %s 的对话树" % npc_id)
		return false

	_current_npc_id = npc_id
	_current_node = dialogue_tree
	_is_active = true
	_waiting_for_choice = false
	_dialogue_history.clear()

	_increment_visit_count(npc_id)
	_add_to_history("system", "对话开始: " + npc_id)

	dialogue_started.emit(npc_id)
	_process_current_node()

	return true

func _get_dialogue_tree_for_npc(npc_id: String) -> DialogueNode:
	if _loaded_dialogue_trees.has(npc_id):
		return _loaded_dialogue_trees[npc_id]
	return null

func _increment_visit_count(npc_id: String) -> void:
	var visits: int = _dialogue_variables.get("visited_count", {}).get(npc_id, 0)
	if not _dialogue_variables.has("visited_count"):
		_dialogue_variables["visited_count"] = {}
	_dialogue_variables["visited_count"][npc_id] = visits + 1

func _process_current_node() -> void:
	if not _current_node:
		return

	_add_to_history(_current_node.speaker, _current_node.dialogue_text)

	match _current_node.type:
		DialogueType.NARRATION:
			_process_narration()
		DialogueType.DIALOGUE:
			_process_dialogue()
		DialogueType.CHOICE:
			_process_choice()
		DialogueType.COMBAT:
			_process_combat()
		DialogueType.END:
			_process_end()

func _process_narration() -> void:
	if not _current_node.next_node_id.is_empty():
		_advance_to_node(_current_node.next_node_id)
	else:
		end_dialogue()

func _process_dialogue() -> void:
	if not _current_node.next_node_id.is_empty():
		_advance_to_node(_current_node.next_node_id)
	else:
		end_dialogue()

func _process_choice() -> void:
	_waiting_for_choice = true
	node_changed.emit(_current_node)

func _process_combat() -> void:
	if not _current_node.next_node_id.is_empty():
		_advance_to_node(_current_node.next_node_id)
	else:
		end_dialogue()

func _process_end() -> void:
	end_dialogue()

func _advance_to_node(node_id: String) -> void:
	var next_node: DialogueNode = _find_node_by_id(node_id)

	if not next_node:
		end_dialogue()
		return

	_current_node = next_node
	node_changed.emit(_current_node)
	_process_current_node()

func _find_node_by_id(node_id: String) -> DialogueNode:
	if _current_node and _current_node.node_id == node_id:
		return _current_node
	if _loaded_dialogue_trees.has(node_id):
		return _loaded_dialogue_trees[node_id]
	return null

func advance_dialogue() -> void:
	if not _is_active:
		return

	if _waiting_for_choice:
		return

	if _current_node.type == DialogueType.CHOICE:
		return

	if not _current_node.next_node_id.is_empty():
		_advance_to_node(_current_node.next_node_id)
	else:
		end_dialogue()

func make_choice(choice_index: int) -> void:
	if not _is_active or not _waiting_for_choice:
		return

	if _current_node.choices.is_empty() or choice_index >= _current_node.choices.size():
		return

	var selected_choice: Dictionary = _current_node.choices[choice_index]
	var choice_text: String = selected_choice.get("text", "")

	choice_made.emit(choice_index, choice_text)
	_add_to_history("player", choice_text)

	_waiting_for_choice = false

	var next_node_id: String = selected_choice.get("next_node", "")
	if next_node_id.is_empty():
		end_dialogue()
	else:
		_advance_to_node(next_node_id)

func end_dialogue() -> void:
	if not _is_active:
		return

	_is_active = false
	_waiting_for_choice = false
	_current_node = null

	dialogue_finished.emit(_current_npc_id)
	_add_to_history("system", "对话结束")

	_current_npc_id = ""

func is_dialogue_active() -> bool:
	return _is_active

func get_current_node() -> DialogueNode:
	return _current_node

func get_current_npc_id() -> String:
	return _current_npc_id

func get_dialogue_history() -> Array[Dictionary]:
	return _dialogue_history.duplicate()

func get_current_choices() -> Array[Dictionary]:
	if not _current_node or _current_node.type != DialogueType.CHOICE:
		return []
	return _current_node.choices.duplicate()

func is_waiting_for_choice() -> bool:
	return _waiting_for_choice

func set_dialogue_variable(variable_name: String, value: Variant) -> void:
	_dialogue_variables[variable_name] = value
	dialogue_variable_changed.emit(variable_name, value)

func get_dialogue_variable(variable_name: String, default_value: Variant = null) -> Variant:
	return _dialogue_variables.get(variable_name, default_value)

func add_to_variable(variable_name: String, amount: int) -> void:
	var current: int = _dialogue_variables.get(variable_name, 0)
	set_dialogue_variable(variable_name, current + amount)

func get_visit_count(npc_id: String) -> int:
	return _dialogue_variables.get("visited_count", {}).get(npc_id, 0)

func _add_to_history(speaker: String, text: String) -> void:
	_dialogue_history.append({
		"speaker": speaker,
		"text": text,
		"timestamp": Time.get_ticks_msec()
	})

func load_dialogue_tree(npc_id: String, tree: DialogueNode) -> void:
	_loaded_dialogue_trees[npc_id] = tree

func reset_dialogue_variables() -> void:
	_dialogue_variables.clear()
	_init_default_variables()
