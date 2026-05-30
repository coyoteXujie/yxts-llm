extends Control
class_name MenuScreen
## UI层 - 主菜单界面

@onready var new_game_btn: Button = $VBox/NewGameBtn
@onready var load_game_btn: Button = $VBox/LoadGameBtn
@onready var settings_btn: Button = $VBox/SettingsBtn
@onready var quit_btn: Button = $VBox/QuitBtn

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	quit_btn.pressed.connect(_on_quit_game)
	
	_update_load_button()

func _update_load_button() -> void:
	pass

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")

func _on_load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_quit_game() -> void:
	get_tree().quit()
