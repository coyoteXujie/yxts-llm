extends Node
## 业务系统层 - 游戏主系统

signal game_started()
signal game_stopped()

var _game_state_machine: GameStateMachine
var _current_state: int = Constants.GameState.MENU

func _ready() -> void:
	_init_state_machine()

func _init_state_machine() -> void:
	_game_state_machine = GameStateMachine.new()
	add_child(_game_state_machine)
	
	var callbacks: Dictionary = {
		"enter_" + str(Constants.GameState.PLAYING): _on_enter_playing,
		"exit_" + str(Constants.GameState.PLAYING): _on_exit_playing,
		"enter_" + str(Constants.GameState.DIALOGUE): _on_enter_dialogue,
		"exit_" + str(Constants.GameState.DIALOGUE): _on_exit_dialogue,
		"enter_" + str(Constants.GameState.COMBAT): _on_enter_combat,
		"exit_" + str(Constants.GameState.COMBAT): _on_exit_combat
	}
	_game_state_machine.set_state_callbacks(callbacks)
	
	_game_state_machine.set_initial_state(Constants.GameState.MENU)
	_game_state_machine.state_changed.connect(_on_game_state_changed)

func change_game_state(new_state: int) -> void:
	var old_state: int = _current_state
	_current_state = new_state
	_game_state_machine.change_state(new_state)

func get_game_state() -> int:
	return _current_state

func is_playing() -> bool:
	return _current_state == Constants.GameState.PLAYING

func is_paused() -> bool:
	return _current_state == Constants.GameState.PAUSED

func is_in_dialogue() -> bool:
	return _current_state == Constants.GameState.DIALOGUE

func is_in_combat() -> bool:
	return _current_state == Constants.GameState.COMBAT

func start_new_game() -> void:
	game_started.emit()
	change_game_state(Constants.GameState.PLAYING)

func load_game(slot: int) -> void:
	var data: Dictionary = SaveSystem.load(slot)
	if data:
		_load_game_data(data)
		game_started.emit()
		change_game_state(Constants.GameState.PLAYING)

func save_game(slot: int) -> void:
	var data: Dictionary = _gather_save_data()
	SaveSystem.save(slot, data)

func pause_game() -> void:
	if _current_state == Constants.GameState.PLAYING:
		_game_state_machine.push_state(Constants.GameState.PAUSED)
		EventBus.emit_game_paused()

func resume_game() -> void:
	if _current_state == Constants.GameState.PAUSED:
		_game_state_machine.pop_state()
		EventBus.emit_game_resumed()

func quit_game() -> void:
	game_stopped.emit()
	EventBus.emit_game_quit()
	get_tree().quit()

func _on_enter_playing() -> void:
	pass

func _on_exit_playing() -> void:
	pass

func _on_enter_dialogue() -> void:
	pass

func _on_exit_dialogue() -> void:
	pass

func _on_enter_combat() -> void:
	pass

func _on_exit_combat() -> void:
	pass

func _on_game_state_changed(old_state: int, new_state: int) -> void:
	EventBus.emit_game_state_changed(old_state, new_state)

func _gather_save_data() -> Dictionary:
	var player_data: PlayerData = DataRegistry.get_player_data()
	return {
		"player": player_data.to_dictionary(),
		"world": {},
		"quests": player_data.active_quests.duplicate(),
		"story_flags": player_data.story_flags.duplicate()
	}

func _load_game_data(data: Dictionary) -> void:
	if not data.has("player"):
		return
	
	var player_dict: Dictionary = data["player"]
	var player_data: PlayerData = PlayerData.new()
	player_data.from_dictionary(player_dict)
	DataRegistry.set_player_data(player_data)
