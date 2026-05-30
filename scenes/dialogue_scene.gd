extends Node2D

@onready var name_label: Label = $CanvasLayer/DialoguePanel/NameLabel
@onready var text_label: RichTextLabel = $CanvasLayer/DialoguePanel/TextLabel
@onready var choice_container: VBoxContainer = $CanvasLayer/ChoiceContainer
@onready var continue_label: Label = $CanvasLayer/DialoguePanel/ContinueLabel

var choices: Array = []
var waiting_for_choice: bool = false

func _ready() -> void:
	DialogueSystem.dialogue_node_changed.connect(_on_dialogue_node_changed)
	DialogueSystem.choice_presented.connect(_on_choice_presented)
	DialogueSystem.dialogue_ended.connect(_on_dialogue_ended)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("confirm") or event.is_action_just_pressed("ui_accept"):
		if waiting_for_choice:
			return
		DialogueSystem.advance_dialogue()

func start_dialogue_with_npc(npc_id: String) -> void:
	DialogueSystem.start_dialogue(npc_id)

func _on_dialogue_node_changed(node_data: Dictionary) -> void:
	var speaker := node_data.get("speaker", "")
	var text := node_data.get("text", "")
	
	name_label.text = speaker
	text_label.text = text
	
	continue_label.visible = not waiting_for_choice
	choice_container.visible = waiting_for_choice

func _on_choice_presented(new_choices: Array) -> void:
	choices = new_choices
	waiting_for_choice = true
	
	for child in choice_container.get_children():
		child.queue_free()
	
	for i in range(choices.size()):
		var choice := choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", "")
		btn.pressed.connect(func(index=i): _on_choice_selected(index))
		choice_container.add_child(btn)
	
	continue_label.visible = false
	choice_container.visible = true

func _on_choice_selected(index: int) -> void:
	if index >= 0 and index < choices.size():
		waiting_for_choice = false
		DialogueSystem.select_choice(index)

func _on_dialogue_ended(npc_id: String) -> void:
	GameSystem.change_game_state(Constants.GameState.PLAYING)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
