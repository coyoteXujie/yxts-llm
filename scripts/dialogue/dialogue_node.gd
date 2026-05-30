extends Resource
class_name DialogueNode

# 对话节点资源 - 定义对话树中的单个节点

# 节点类型枚举
enum NodeType {
	NARRATION = 0,
	DIALOGUE = 1,
	CHOICE = 2,
	COMBAT = 3,
	END = 4
}

# 节点标识
@export var node_id: String = ""
@export var npc_id: String = ""

# 说话者信息
@export var speaker: String = ""
@export var speaker_portrait: String = ""

# 文本内容
@export_multiline var narration_text: String = ""
@export_multiline var dialogue_text: String = ""

# 分支选择（用于CHOICE类型）
@export var choices: Array[Dictionary] = []

# 线性下一个节点ID
@export var next_node_id: String = ""

# 条件判断（用于条件分支）
@export var conditions: Array[Dictionary] = []

# 节点效果（标志设置、物品给予、任务触发等）
@export var effects: Array[Dictionary] = []

# 节点类型
@export var type: NodeType = NodeType.DIALOGUE

# 显示配置
@export var show_name: bool = true
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 2.0

# 音频配置
@export var voice_line: String = ""
@export var text_sound: String = ""

# 动画配置
@export var enter_animation: String = "fade_in"
@export var exit_animation: String = "fade_out"

func _init() -> void:
	if node_id.is_empty():
		node_id = "node_" + str(hash(str(Time.get_ticks_msec())))

# 获取节点类型名称
func get_type_name() -> String:
	match type:
		NodeType.NARRATION:
			return "叙述"
		NodeType.DIALOGUE:
			return "对话"
		NodeType.CHOICE:
			return "选择"
		NodeType.COMBAT:
			return "战斗"
		NodeType.END:
			return "结束"
	return "未知"

# 检查是否是结束节点
func is_end_node() -> bool:
	return type == NodeType.END

# 检查是否需要等待玩家输入
func requires_input() -> bool:
	match type:
		NodeType.NARRATION:
			return not auto_advance
		NodeType.DIALOGUE:
			return not auto_advance
		NodeType.CHOICE:
			return true
		NodeType.COMBAT:
			return true
		NodeType.END:
			return false
	return true

# 获取显示文本
func get_display_text() -> String:
	if type == NodeType.NARRATION:
		return narration_text
	return dialogue_text

# 获取说话者名称
func get_speaker_name() -> String:
	if not show_name:
		return ""
	return speaker if not speaker.is_empty() else "旁白"

# 检查条件是否满足
func check_conditions() -> bool:
	if conditions.is_empty():
		return true
	
	for condition: Dictionary in conditions:
		if not _evaluate_single_condition(condition):
			return false
	
	return true

# 评估单个条件
func _evaluate_single_condition(condition: Dictionary) -> bool:
	var variable: String = condition.get("variable", "")
	var required_value: Variant = condition.get("value", null)
	var operator: String = condition.get("operator", "==")
	var use_quest_system: bool = condition.get("use_quest_system", false)
	
	if use_quest_system:
		return _check_quest_condition(variable, required_value, operator)
	
	return _check_variable_condition(variable, required_value, operator)

# 检查变量条件
func _check_variable_condition(variable: String, required_value: Variant, operator: String) -> bool:
	var dialogue_manager: Node = Engine.get_meta("DialogueManager")
	if not dialogue_manager:
		push_warning("DialogueNode: 找不到DialogueManager")
		return false
	
	var current_value: Variant = dialogue_manager.get_dialogue_variable(variable)
	
	if current_value == null:
		current_value = 0
	
	match operator:
		"==":
			return current_value == required_value
		"!=":
			return current_value != required_value
		">":
			return current_value > required_value
		">=":
			return current_value >= required_value
		"<":
			return current_value < required_value
		"<=":
			return current_value <= required_value
	
	return false

# 检查任务条件
func _check_quest_condition(quest_id: String, required_value: Variant, operator: String) -> bool:
	var quest_system: Node = Engine.get_meta("QuestSystem")
	if not quest_system:
		return false
	
	match operator:
		"active":
			return quest_system.is_quest_active(quest_id)
		"completed":
			return quest_system.is_quest_completed(quest_id)
		"progress":
			var progress: int = quest_system.get_quest_progress(quest_id)
			return progress >= required_value
	
	return false

# 获取有效选择数量
func get_valid_choice_count() -> int:
	if type != NodeType.CHOICE:
		return 0
	
	var valid_count: int = 0
	
	for choice: Dictionary in choices:
		if _is_choice_available(choice):
			valid_count += 1
	
	return valid_count

# 检查选择是否可用
func _is_choice_available(choice: Dictionary) -> bool:
	if not choice.has("conditions"):
		return true
	
	for condition: Dictionary in choice.get("conditions"):
		if not _evaluate_single_condition(condition):
			return false
	
	return true

# 获取可用的选择
func get_available_choices() -> Array[Dictionary]:
	if type != NodeType.CHOICE:
		return []
	
	var available: Array[Dictionary] = []
	
	for choice: Dictionary in choices:
		if _is_choice_available(choice):
			available.append(choice)
	
	return available

# 应用节点效果
func apply_effects() -> void:
	var dialogue_manager: Node = Engine.get_meta("DialogueManager")
	if not dialogue_manager:
		push_warning("DialogueNode: 找不到DialogueManager")
		return
	
	for effect: Dictionary in effects:
		_apply_single_effect(effect, dialogue_manager)

# 应用单个效果
func _apply_single_effect(effect: Dictionary, manager: Node) -> void:
	var effect_type: String = effect.get("type", "")
	
	match effect_type:
		"set_flag":
			var flag_name: String = effect.get("flag", "")
			var value: Variant = effect.get("value", true)
			manager.set_dialogue_variable(flag_name, value)
		
		"increment":
			var variable: String = effect.get("variable", "")
			var amount: int = effect.get("amount", 1)
			manager.add_to_variable(variable, amount)
		
		"decrement":
			var variable: String = effect.get("variable", "")
			var amount: int = effect.get("amount", 1)
			manager.add_to_variable(variable, -amount)
		
		"give_item":
			var item_id: String = effect.get("item_id", "")
			var amount: int = effect.get("amount", 1)
			_apply_give_item(item_id, amount)
		
		"remove_item":
			var item_id: String = effect.get("item_id", "")
			var amount: int = effect.get("amount", 1)
			_apply_remove_item(item_id, amount)
		
		"give_gold":
			var amount: int = effect.get("amount", 0)
			_apply_give_gold(amount)
		
		"give_exp":
			var amount: int = effect.get("amount", 0)
			_apply_give_exp(amount)
		
		"start_quest":
			var quest_id: String = effect.get("quest_id", "")
			_apply_start_quest(quest_id)
		
		"update_quest":
			var quest_id: String = effect.get("quest_id", "")
			var objective: int = effect.get("objective", 0)
			_apply_update_quest(quest_id, objective)
		
		"complete_quest":
			var quest_id: String = effect.get("quest_id", "")
			_apply_complete_quest(quest_id)
		
		"change_relationship":
			var target: String = effect.get("target", "")
			var amount: int = effect.get("amount", 0)
			_apply_change_relationship(target, amount)
		
		"play_sound":
			var sound_path: String = effect.get("sound_path", "")
			_apply_play_sound(sound_path)
		
		"teleport":
			var scene_path: String = effect.get("scene", "")
			var position: Vector2 = effect.get("position", Vector2.ZERO)
			_apply_teleport(scene_path, position)

# 给予物品
func _apply_give_item(item_id: String, amount: int) -> void:
	pass

# 移除物品
func _apply_remove_item(item_id: String, amount: int) -> void:
	pass

# 给予金币
func _apply_give_gold(amount: int) -> void:
	pass

# 给予经验
func _apply_give_exp(amount: int) -> void:
	pass

# 开始任务
func _apply_start_quest(quest_id: String) -> void:
	var quest_system: Node = Engine.get_meta("QuestSystem")
	if quest_system:
		quest_system.start_quest(quest_id)

# 更新任务
func _apply_update_quest(quest_id: String, objective: int) -> void:
	var quest_system: Node = Engine.get_meta("QuestSystem")
	if quest_system:
		quest_system.update_quest(quest_id, objective)

# 完成任务
func _apply_complete_quest(quest_id: String) -> void:
	var quest_system: Node = Engine.get_meta("QuestSystem")
	if quest_system:
		quest_system.complete_quest(quest_id)

# 改变关系
func _apply_change_relationship(target: String, amount: int) -> void:
	var dialogue_manager: Node = Engine.get_meta("DialogueManager")
	if dialogue_manager:
		dialogue_manager.set_dialogue_variable("relationship_" + target, amount)

# 播放声音
func _apply_play_sound(sound_path: String) -> void:
	if sound_path.is_empty():
		return
	
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.bus = "Master"
	Engine.get_main_loop().root.add_child(audio)
	
	if ResourceLoader.exists(sound_path):
		audio.stream = load(sound_path)
		audio.play()
		audio.finished.connect(func(): audio.queue_free())

# 传送
func _apply_teleport(scene_path: String, position: Vector2) -> void:
	if scene_path.is_empty():
		return
	
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("DialogueNode: 传送失败 - " + scene_path)

# 创建叙述类型节点
static func create_narration(
	p_narration_text: String,
	p_next: String = "",
	p_effects: Array = []
) -> DialogueNode:
	var node: DialogueNode = new()
	node.type = NodeType.NARRATION
	node.narration_text = p_narration_text
	node.next_node_id = p_next
	node.effects = Array(p_effects)
	node.show_name = false
	return node

# 创建对话类型节点
static func create_dialogue(
	p_speaker: String,
	p_text: String,
	p_portrait: String = "",
	p_next: String = "",
	p_effects: Array = []
) -> DialogueNode:
	var node: DialogueNode = new()
	node.type = NodeType.DIALOGUE
	node.speaker = p_speaker
	node.dialogue_text = p_text
	node.speaker_portrait = p_portrait
	node.next_node_id = p_next
	node.effects = Array(p_effects)
	return node

# 创建选择类型节点
static func create_choice(
	p_speaker: String,
	p_text: String,
	p_choices: Array[Dictionary],
	p_portrait: String = ""
) -> DialogueNode:
	var node: DialogueNode = new()
	node.type = NodeType.CHOICE
	node.speaker = p_speaker
	node.dialogue_text = p_text
	node.speaker_portrait = p_portrait
	node.choices = p_choices
	return node

# 创建战斗类型节点
static func create_combat(
	p_enemy_id: String,
	p_next: String = "",
	p_effects: Array = []
) -> DialogueNode:
	var node: DialogueNode = new()
	node.type = NodeType.COMBAT
	node.narration_text = "战斗开始！"
	node.effects = Array(p_effects)
	node.next_node_id = p_next
	return node

# 创建结束节点
static func create_end(
	p_text: String = "对话结束",
	p_effects: Array = []
) -> DialogueNode:
	var node: DialogueNode = new()
	node.type = NodeType.END
	node.narration_text = p_text
	node.effects = Array(p_effects)
	return node

# 克隆节点
func clone() -> DialogueNode:
	var cloned: DialogueNode = new()
	cloned.node_id = node_id
	cloned.npc_id = npc_id
	cloned.speaker = speaker
	cloned.speaker_portrait = speaker_portrait
	cloned.narration_text = narration_text
	cloned.dialogue_text = dialogue_text
	cloned.choices = choices.duplicate(true)
	cloned.next_node_id = next_node_id
	cloned.conditions = conditions.duplicate(true)
	cloned.effects = effects.duplicate(true)
	cloned.type = type
	cloned.show_name = show_name
	cloned.auto_advance = auto_advance
	cloned.auto_advance_delay = auto_advance_delay
	cloned.voice_line = voice_line
	cloned.text_sound = text_sound
	cloned.enter_animation = enter_animation
	cloned.exit_animation = exit_animation
	return cloned

# 添加选择选项
func add_choice(text: String, next_node: String, conditions: Array = [], effects: Array = []) -> void:
	var choice: Dictionary = {
		"text": text,
		"next_node": next_node,
		"conditions": Array(conditions),
		"effects": Array(effects)
	}
	choices.append(choice)

# 添加条件
func add_condition(
	variable: String,
	value: Variant,
	operator: String = "==",
	use_quest_system: bool = false
) -> void:
	var condition: Dictionary = {
		"variable": variable,
		"value": value,
		"operator": operator,
		"use_quest_system": use_quest_system
	}
	conditions.append(condition)

# 添加效果
func add_effect(effect_type: String, properties: Dictionary) -> void:
	var effect: Dictionary = properties.duplicate()
	effect["type"] = effect_type
	effects.append(effect)

# 获取节点摘要信息
func get_summary() -> String:
	var summary: String = "[%s] %s" % [get_type_name(), node_id]
	if not speaker.is_empty():
		summary += " - %s" % speaker
	return summary

# 验证节点完整性
func validate() -> bool:
	if node_id.is_empty():
		push_error("DialogueNode: 节点ID不能为空")
		return false
	
	if type == NodeType.CHOICE and choices.is_empty():
		push_warning("DialogueNode: 选择节点没有任何选项 - " + node_id)
	
	if type != NodeType.END and type != NodeType.CHOICE and next_node_id.is_empty():
		push_warning("DialogueNode: 非结束/选择节点没有设置下一个节点 - " + node_id)
	
	return true
