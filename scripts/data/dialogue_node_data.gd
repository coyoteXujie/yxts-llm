class_name DialogueNodeData extends Resource
## 数据层 - 对话节点数据，纯数据定义

@export var node_id: String = ""
@export var speaker: String = ""
@export var speaker_portrait_path: String = ""

@export var dialogue_type: int = Constants.DialogueType.DIALOGUE
@export var dialogue_text: String = ""
@export var next_node_id: String = ""

@export var choices: Array[Dictionary] = []

@export var conditions: Dictionary = {}
@export var effects: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {
		"node_id": node_id,
		"speaker": speaker,
		"speaker_portrait_path": speaker_portrait_path,
		"dialogue_type": dialogue_type,
		"dialogue_text": dialogue_text,
		"next_node_id": next_node_id,
		"choices": choices.duplicate(),
		"conditions": conditions.duplicate(),
		"effects": effects.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	node_id = Utils.safe_string(data.get("node_id", ""))
	speaker = Utils.safe_string(data.get("speaker", ""))
	speaker_portrait_path = Utils.safe_string(data.get("speaker_portrait_path", ""))
	dialogue_type = Utils.safe_int(data.get("dialogue_type", Constants.DialogueType.DIALOGUE))
	dialogue_text = Utils.safe_string(data.get("dialogue_text", ""))
	next_node_id = Utils.safe_string(data.get("next_node_id", ""))
	choices = data.get("choices", []).duplicate()
	conditions = data.get("conditions", {}).duplicate()
	effects = data.get("effects", {}).duplicate()
