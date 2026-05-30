extends Control

const UI_COLORS = {
    "background": Color(0.102, 0.102, 0.18, 1),
    "panel_bg": Color(0.137, 0.137, 0.243, 0.95),
    "gold": Color(0.788, 0.663, 0.431),
    "gold_bright": Color(0.941, 0.753, 0.251),
    "text": Color(0.9, 0.85, 0.75),
    "text_dim": Color(0.6, 0.55, 0.5),
    "red": Color(0.753, 0.224, 0.169),
    "green": Color(0.18, 0.8, 0.443),
    "blue": Color(0.129, 0.588, 0.953),
}

func _ready():
    $VBox/NewGame.pressed.connect(_on_new_game)
    $VBox/LoadGame.pressed.connect(_on_load_game)
    $VBox/Settings.pressed.connect(_on_settings)
    $VBox/Quit.pressed.connect(_on_quit)

    _update_buttons()

func _update_buttons():
    pass

func _on_new_game():
    get_tree().change_scene_to_file("res://scenes/character_creation/character_creation.tscn")

func _on_load_game():
    get_tree().change_scene_to_file("res://scenes/game_world/game_world.tscn")

func _on_settings():
    pass

func _on_quit():
    get_tree().quit()
