extends GameEntity
class_name PlayerEntity
## 实体层 - 玩家实体，通过组件组合功能

var _player_data: PlayerData

var health_comp: HealthComponent
var mana_comp: ManaComponent
var inventory_comp: InventoryComponent
var movement_comp: MovementComponent

func _init_components() -> void:
	health_comp = HealthComponent.new()
	add_component(health_comp)
	
	mana_comp = ManaComponent.new()
	add_component(mana_comp)
	
	inventory_comp = InventoryComponent.new()
	add_component(inventory_comp)
	
	movement_comp = MovementComponent.new()
	movement_comp.set_speed(Constants.PLAYER_MOVE_SPEED)
	add_component(movement_comp)

func set_player_data(data: PlayerData) -> void:
	_player_data = data
	_apply_data_to_components()

func _apply_data_to_components() -> void:
	if not _player_data:
		return
	
	health_comp.set_max_hp(_player_data.max_hp)
	health_comp.set_current_hp(_player_data.current_hp)
	
	mana_comp.set_max_mp(_player_data.max_mp)
	mana_comp.set_current_mp(_player_data.current_mp)

func _process(delta: float) -> void:
	_process_input(delta)
	for comp in components.values():
		if comp.is_enabled:
			comp.update(delta)

func _process_input(delta: float) -> void:
	if not _can_process_input():
		return
	
	var input_dir: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	movement_comp.set_direction(input_dir)
	position = movement_comp.move(position, delta)

func _can_process_input() -> bool:
	var game_state: int = GameSystem.get_game_state()
	if game_state == Constants.GameState.PLAYING:
		return true
	return false
