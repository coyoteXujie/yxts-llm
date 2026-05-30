extends Node
## 完整的对话系统

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal dialogue_node_changed(node_data: Dictionary)
signal choice_presented(choices: Array)
signal dialogue_effect_triggered(effect_type: String, data: Dictionary)

var is_active: bool = false
var current_npc_id: String = ""
var current_node_index: int = 0
var current_dialogue_tree: Array = []
var dialogue_variables: Dictionary = {}
var default_dialogue_trees: Dictionary = {}

func _ready() -> void:
	_initialize_default_dialogues()

func _initialize_default_dialogues() -> void:
	# 简单的示例对话树
	default_dialogue_trees["village_elder"] = [
		{
			"id": "greeting",
			"speaker": "村长",
			"type": "dialogue",
			"text": "年轻人，欢迎来到我们的村子！",
			"next_node": "quest_offer"
		},
		{
			"id": "quest_offer",
			"speaker": "村长",
			"type": "choice",
			"text": "附近山贼作乱，你愿意帮忙吗？",
			"choices": [
				{"text": "没问题，交给我！", "next_node": "accept_quest"},
				{"text": "我还没准备好...", "next_node": "decline"}
			]
		},
		{
			"id": "accept_quest",
			"speaker": "村长",
			"type": "dialogue",
			"text": "太好了！这是 50 两银子，作为定金！",
			"effects": [
				{"type": "give_gold", "amount": 50},
				{"type": "accept_quest", "quest_id": "kill_bandits"}
			],
			"next_node": "end"
		},
		{
			"id": "decline",
			"speaker": "村长",
			"type": "dialogue",
			"text": "没关系，等你准备好了再来吧！",
			"next_node": "end"
		},
		{
			"id": "end",
			"type": "end"
		}
	]
	
	default_dialogue_trees["merchant"] = [
		{
			"id": "greeting",
			"speaker": "商人",
			"type": "dialogue",
			"text": "客官，要买些什么？",
			"choices": [
				{"text": "看看商品", "next_node": "shop"},
				{"text": "不了，谢谢", "next_node": "end"}
			]
		},
		{
			"id": "shop",
			"type": "shop",
			"next_node": "end"
		},
		{
			"id": "end",
			"type": "end"
		}
	]

func start_dialogue(npc_id: String, custom_tree: Array = []) -> void:
	if is_active:
		return
	
	current_npc_id = npc_id
	current_node_index = 0
	dialogue_variables.clear()
	
	if custom_tree.size() > 0:
		current_dialogue_tree = custom_tree.duplicate()
	else:
		current_dialogue_tree = default_dialogue_trees.get(npc_id, []).duplicate()
	
	if current_dialogue_tree.size() == 0:
		_create_default_dialogue()
	
	is_active = true
	dialogue_started.emit(npc_id)
	EventBus.emit_dialogue_started(npc_id)
	_process_current_node()

func _create_default_dialogue() -> void:
	current_dialogue_tree = [
		{
			"id": "default",
			"speaker": current_npc_id,
			"type": "dialogue",
			"text": "你好！",
			"next_node": "end"
		},
		{"id": "end", "type": "end"}
	]

func end_dialogue() -> void:
	if not is_active:
		return
	
	var old_npc_id := current_npc_id
	is_active = false
	current_npc_id = ""
	current_node_index = 0
	current_dialogue_tree.clear()
	
	dialogue_ended.emit(old_npc_id)
	EventBus.emit_dialogue_ended(old_npc_id)

func advance_dialogue() -> void:
	if not is_active:
		return
	
	var current_node := _get_current_node()
	if not current_node:
		end_dialogue()
		return
	
	var node_type: String = current_node.get("type", "dialogue")
	
	if node_type == "choice":
		return
	
	if current_node.has("next_node"):
		_jump_to_node_by_id(current_node.get("next_node", ""))
	else:
		_advance_to_next_node()
	
	_process_current_node()

func select_choice(choice_index: int) -> void:
	if not is_active:
		return
	
	var current_node := _get_current_node()
	if not current_node:
		return
	
	var choices: Array = current_node.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	
	var choice: Dictionary = choices[choice_index]
	var next_node_id: String = choice.get("next_node", "")
	
	EventBus.emit_dialogue_choice_made(choice_index, choice.get("text", ""))
	
	if not next_node_id.is_empty():
		_jump_to_node_by_id(next_node_id)
	else:
		_advance_to_next_node()
	
	_process_current_node()

func _process_current_node() -> void:
	var current_node := _get_current_node()
	if not current_node:
		end_dialogue()
		return
	
	if current_node.has("effects"):
		_apply_effects(current_node.get("effects", []))
	
	var node_type: String = current_node.get("type", "dialogue")
	
	if node_type == "end":
		end_dialogue()
		return
	
	if node_type == "choice":
		choice_presented.emit(current_node.get("choices", []))
	
	if node_type == "shop":
		dialogue_effect_triggered.emit("shop", {})
	
	dialogue_node_changed.emit(current_node.duplicate())

func _apply_effects(effects: Array) -> void:
	for effect in effects:
		var effect_type: String = effect.get("type", "")
		match effect_type:
			"give_gold":
				var amount: int = effect.get("amount", 0)
				RewardSystem.give_gold(amount)
				dialogue_effect_triggered.emit("give_gold", {"amount": amount})
			"give_item":
				var item_id: String = effect.get("item_id", "")
				var quantity: int = effect.get("quantity", 1)
				RewardSystem.give_item(item_id, quantity)
			"accept_quest":
				var quest_id: String = effect.get("quest_id", "")
				QuestSystem.start_quest(quest_id)
			"start_combat":
				var enemies: Array = effect.get("enemies", [])
				_apply_dialogue_effect_and_continue("start_combat", {"enemies": enemies})

func _get_current_node() -> Dictionary:
	if current_node_index < 0 or current_node_index >= current_dialogue_tree.size():
		return {}
	return current_dialogue_tree[current_node_index]

func _advance_to_next_node() -> void:
	current_node_index += 1

func _jump_to_node_by_id(node_id: String) -> void:
	for i in range(current_dialogue_tree.size()):
		if current_dialogue_tree[i].get("id", "") == node_id:
			current_node_index = i
			return
	current_node_index += 1

func _apply_dialogue_effect_and_continue(effect_type: String, data: Dictionary) -> void:
	dialogue_effect_triggered.emit(effect_type, data)

func set_variable(name: String, value: Variant) -> void:
	dialogue_variables[name] = value

func get_variable(name: String, default_value: Variant = null) -> Variant:
	return dialogue_variables.get(name, default_value)

func get_current_speaker() -> String:
	var node := _get_current_node()
	return node.get("speaker", "")

func get_current_text() -> String:
	var node := _get_current_node()
	return node.get("text", "")

func get_current_choices() -> Array:
	var node := _get_current_node()
	return node.get("choices", [])

func add_dialogue_tree(npc_id: String, tree: Array) -> void:
	default_dialogue_trees[npc_id] = tree.duplicate()

func has_dialogue_tree(npc_id: String) -> bool:
	return default_dialogue_trees.has(npc_id)
