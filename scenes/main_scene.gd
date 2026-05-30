extends Node2D

@onready var main_menu: Control = $CanvasLayer/MainMenu
@onready var hud: Control = $CanvasLayer/HUD
@onready var inventory_panel: Control = $CanvasLayer/InventoryPanel
@onready var new_game_btn: Button = $CanvasLayer/MainMenu/VBox/NewGameBtn
@onready var load_game_btn: Button = $CanvasLayer/MainMenu/VBox/LoadGameBtn
@onready var quit_btn: Button = $CanvasLayer/MainMenu/VBox/QuitBtn

var player: PlayerEntity
var world: Node2D

func _ready() -> void:
	_connect_ui_events()
	show_main_menu()

func _connect_ui_events() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	quit_btn.pressed.connect(_on_quit_game)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()

func _on_new_game() -> void:
	GameSystem.start_new_game()
	show_game()

func _on_load_game() -> void:
	GameSystem.load_game(1)
	show_game()

func _on_quit_game() -> void:
	GameSystem.quit_game()

func show_main_menu() -> void:
	main_menu.visible = true
	hud.visible = false
	inventory_panel.visible = false
	GameSystem.change_game_state(Constants.GameState.MENU)

func show_game() -> void:
	main_menu.visible = false
	hud.visible = true
	inventory_panel.visible = false
	GameSystem.change_game_state(Constants.GameState.PLAYING)

func _toggle_inventory() -> void:
	if inventory_panel.visible:
		inventory_panel.visible = false
	else:
		inventory_panel.visible = true
