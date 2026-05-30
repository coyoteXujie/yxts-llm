extends Node
## 游戏管理器单例 - 管理系统全局状态
## 通过 Autoload 自动加载，所有脚本通过 GameManager.xxx 访问

# 游戏状态枚举
enum GameState {
	MENU = 0,
	CHARACTER_CREATION = 1,
	PLAYING = 2,
	PAUSED = 3,
	COMBAT = 4,
	DIALOGUE = 5,
	INVENTORY = 6,
	SKILL_PANEL = 7,
	MAP = 8
}

# 玩家引用
var player: Node = null
var player_data: Resource = null

# 世界引用
var current_zone: Node = null

# 游戏状态
var game_state: GameState = GameState.MENU:
	set(value):
		var old_state := game_state
		game_state = value
		_emit_state_change(old_state, value)

# 状态栈（用于临时状态如对话、暂停）
var _state_stack: Array[GameState] = []

# 时间相关
var time_scale: float = 1.0
var is_paused: bool = false

# 信号定义
signal game_state_changed(old_state: GameState, new_state: GameState)
signal player_created(player_data: Resource)
signal zone_changed(zone_id: String)
signal game_paused
signal game_resumed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("GameManager: 游戏管理器已初始化")

func _process(delta: float) -> void:
	if is_paused:
		return
	_update_game_time(delta * time_scale)

func _update_game_time(_delta: float) -> void:
	pass

func _emit_state_change(old_state: GameState, new_state: GameState) -> void:
	game_state_changed.emit(old_state, new_state)

func start_new_game() -> void:
	game_state = GameState.CHARACTER_CREATION

func confirm_character_creation(data: Resource) -> void:
	player_data = data
	player_created.emit(player_data)
	change_state(GameState.PLAYING)

func change_state(new_state: GameState) -> void:
	game_state = new_state

func push_state(state: GameState) -> void:
	_state_stack.push_back(game_state)
	game_state = state

func pop_state() -> void:
	if not _state_stack.is_empty():
		game_state = _state_stack.pop_back()

func pause_game() -> void:
	is_paused = true
	push_state(GameState.PAUSED)
	game_paused.emit()

func resume_game() -> void:
	is_paused = false
	pop_state()
	game_resumed.emit()

func get_player() -> Node:
	return player

func get_player_data() -> Resource:
	return player_data

func get_world() -> Node:
	return current_zone

func set_player(node: Node) -> void:
	player = node

func set_zone(zone_node: Node) -> void:
	current_zone = zone_node

func is_playing() -> bool:
	return game_state == GameState.PLAYING

func is_in_combat() -> bool:
	return game_state == GameState.COMBAT

func is_in_dialogue() -> bool:
	return game_state == GameState.DIALOGUE

func can_player_move() -> bool:
	return game_state == GameState.PLAYING and not is_paused

func quit_game() -> void:
	get_tree().quit()
