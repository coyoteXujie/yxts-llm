extends Entity
class_name NPC
## NPC类 - 非玩家角色
## 继承自Entity类，添加NPC特有的属性和功能

# NPC类型枚举
enum NPCType {
	NORMAL,      ## 普通NPC
	MASTER,      ## 师父/导师
	TRADER,      ## 商人
	QUEST_GIVER, ## 任务给予者
	ENEMY        ## 敌对NPC
}

# AI行为状态枚举
enum AIBehavior {
	IDLE,     ## 空闲状态
	PATROL,   ## 巡逻状态
	INTERACT, ## 交互状态
	FLEE      ## 逃跑状态
}

@export var npc_type: NPCType = NPCType.NORMAL  ## NPC类型
@export var npc_title: String = ""  ## NPC称号
@export var description: String = ""  ## NPC描述

# 对话系统
@export var dialogue_tree_path: String = ""  ## 对话树资源路径
var current_dialogue: Dictionary = {}  ## 当前对话数据

# 任务系统
@export var available_quests: Array[String] = []  ## 可接任务列表
@export var active_quests: Array[String] = []  ## 进行中的任务
@export var completed_quests: Array[String] = []  ## 已完成任务

# 商店系统
@export var has_shop: bool = false  ## 是否拥有商店
@export var shop_items: Array[Dictionary] = []  ## 商店商品列表
@export var shop_currency: String = "gold"  ## 商店货币类型
@export var buy_multiplier: float = 1.0  ## 购买价格倍率
@export var sell_multiplier: float = 0.5  ## 出售价格倍率

# 巡逻系统
@export var patrol_enabled: bool = false  ## 是否启用巡逻
@export var patrol_path: Array[Vector2i] = []  ## 巡逻路径点列表
@export var patrol_wait_time: float = 2.0  ## 巡逻等待时间
@export var patrol_speed: float = 50.0  ## 巡逻移动速度

var current_patrol_index: int = 0  ## 当前巡逻点索引
var is_patrol_waiting: bool = false  ## 是否在等待
var patrol_wait_timer: float = 0.0  ## 等待计时器

# AI系统
var current_behavior: AIBehavior = AIBehavior.IDLE  ## 当前AI行为
var aggro_target: Node2D = null  ## 仇恨目标
var interaction_target: Node2D = null  ## 交互目标

# 交互区域
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D if has_node("InteractionArea/CollisionShape2D") else null

# 移动相关
var move_target: Vector2 = Vector2.ZERO  ## 移动目标点
var is_moving: bool = false  ## 是否在移动中

# NPC精灵
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var talk_indicator: Sprite2D = $TalkIndicator if has_node("TalkIndicator") else null

# 信号定义
signal dialogue_started(npc: NPC, player: Player)  ## 对话开始
signal dialogue_ended(npc: NPC, player: Player)  ## 对话结束
signal quest_given(quest_id: String)  ## 任务给予
signal quest_completed(quest_id: String)  ## 任务完成
signal shop_opened(shop_items: Array)  ## 商店打开
signal behavior_changed(new_behavior: AIBehavior)  ## AI行为改变
signal interacted(interacting_player: Player)  ## NPC被交互

func _ready() -> void:
	super._ready()
	entity_type = EntityType.NPC
	
	# 连接交互区域信号
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	
	# 加载对话树
	_load_dialogue_tree()
	
	# 初始化巡逻
	if patrol_enabled and not patrol_path.is_empty():
		current_patrol_index = 0
		move_target = Vector2(patrol_path[0]) * 32

func _physics_process(delta: float) -> void:
	match current_behavior:
		AIBehavior.IDLE:
			_process_idle(delta)
		AIBehavior.PATROL:
			_process_patrol(delta)
		AIBehavior.FLEE:
			_process_flee(delta)
	
	super._physics_process(delta)

## 处理空闲状态
## [param delta] 帧时间
func _process_idle(delta: float) -> void:
	# 空闲时不做任何事
	pass

## 处理巡逻状态
## [param delta] 帧时间
func _process_patrol(delta: float) -> void:
	if patrol_path.is_empty():
		current_behavior = AIBehavior.IDLE
		return
	
	if is_patrol_waiting:
		patrol_wait_timer += delta
		if patrol_wait_timer >= patrol_wait_time:
			is_patrol_waiting = false
			patrol_wait_timer = 0.0
			# 移动到下一个巡逻点
			current_patrol_index = (current_patrol_index + 1) % patrol_path.size()
			move_target = Vector2(patrol_path[current_patrol_index]) * 32
		return
	
	# 移动到目标点
	var direction: Vector2 = (move_target - global_position)
	if direction.length() > 5.0:
		direction = direction.normalized()
		velocity = direction * patrol_speed
		_update_patrol_animation(direction)
	else:
		velocity = Vector2.ZERO
		is_patrol_waiting = true
		if sprite:
			sprite.play("idle")

## 处理逃跑状态
## [param delta] 帧时间
func _process_flee(delta: float) -> void:
	if not aggro_target:
		current_behavior = AIBehavior.IDLE
		return
	
	# 获取逃跑方向（远离威胁）
	var flee_direction: Vector2 = (global_position - aggro_target.global_position).normalized()
	velocity = flee_direction * patrol_speed * 2.0  # 逃跑速度加倍
	
	# 更新动画
	if sprite:
		if flee_direction.x > 0.3:
			sprite.play("walk_right")
		elif flee_direction.x < -0.3:
			sprite.play("walk_left")
		elif flee_direction.y > 0.3:
			sprite.play("walk_down")
		elif flee_direction.y < -0.3:
			sprite.play("walk_up")

## 更新巡逻动画
## [param direction] 移动方向
func _update_patrol_animation(direction: Vector2) -> void:
	if not sprite:
		return
	
	if direction.x > 0.3:
		sprite.play("walk_right")
		facing_direction = Vector2.RIGHT
	elif direction.x < -0.3:
		sprite.play("walk_left")
		facing_direction = Vector2.LEFT
	elif direction.y > 0.3:
		sprite.play("walk_down")
		facing_direction = Vector2.DOWN
	elif direction.y < -0.3:
		sprite.play("walk_up")
		facing_direction = Vector2.UP

## 开始对话
## [param player] 触发对话的玩家
func start_dialogue(player: Player) -> void:
	interaction_target = player
	set_behavior(AIBehavior.INTERACT)
	
	dialogue_started.emit(self, player)
	
	# 显示对话提示
	if talk_indicator:
		talk_indicator.visible = true
	
	# 加载对话数据
	if not dialogue_tree_path.is_empty():
		var dialogue_resource = load(dialogue_tree_path)
		if dialogue_resource:
			current_dialogue = dialogue_resource
	
	# 打开对话UI（需要与UI系统集成）
	_open_dialogue_ui()

## 打开对话UI
func _open_dialogue_ui() -> void:
	# 这里应该打开对话UI
	# 实际实现取决于UI系统
	pass

## 结束对话
## [param player] 结束对话的玩家
func end_dialogue(player: Player) -> void:
	interaction_target = null
	set_behavior(AIBehavior.IDLE)
	
	dialogue_ended.emit(self, player)
	
	# 隐藏对话提示
	if talk_indicator:
		talk_indicator.visible = false

## 给予任务
## [param quest_id] 任务ID
## [param player] 接收任务的玩家
## [return] 是否成功给予任务
func give_quest(quest_id: String, player: Player) -> bool:
	# 检查任务是否可接
	if quest_id in active_quests or quest_id in completed_quests:
		return false
	
	# 添加到进行中任务
	active_quests.append(quest_id)
	quest_given.emit(quest_id)
	return true

## 完成任务
## [param quest_id] 任务ID
## [param player] 完成任务的玩家
## [return] 是否成功完成任务
func complete_quest(quest_id: String, player: Player) -> bool:
	if quest_id not in active_quests:
		return false
	
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	quest_completed.emit(quest_id)
	return true

## 打开商店
## [param player] 打开商店的玩家
func open_shop(player: Player) -> void:
	if not has_shop:
		return
	
	shop_opened.emit(shop_items)

## 设置巡逻路径
## [param path] 巡逻路径点列表
func set_patrol_path(path: Array[Vector2i]) -> void:
	patrol_path = path
	if not path.is_empty():
		patrol_enabled = true
		current_patrol_index = 0
		move_target = Vector2(path[0]) * 32

## 开始巡逻
func start_patrol() -> void:
	if not patrol_path.is_empty():
		patrol_enabled = true
		set_behavior(AIBehavior.PATROL)

## 停止巡逻
func stop_patrol() -> void:
	patrol_enabled = false
	set_behavior(AIBehavior.IDLE)
	velocity = Vector2.ZERO

## 设置AI行为
## [param behavior] 新的AI行为
func set_behavior(behavior: AIBehavior) -> void:
	if current_behavior != behavior:
		current_behavior = behavior
		behavior_changed.emit(behavior)

## 设置仇恨目标
## [param target] 仇恨目标节点
func set_aggro_target(target: Node2D) -> void:
	aggro_target = target
	if target:
		set_behavior(AIBehavior.FLEE)

## 获取商店商品列表
## [return] 商店商品列表
func get_shop_items() -> Array[Dictionary]:
	return shop_items

## 购买物品
## [param item_index] 商品索引
## [param player] 购买的玩家
## [return] 是否成功购买
func buy_item(item_index: int, player: Player) -> bool:
	if item_index < 0 or item_index >= shop_items.size():
		return false
	
	var item = shop_items[item_index]
	var price = int(item.get("price", 0) * buy_multiplier)
	
	# 检查玩家货币（假设玩家有货币系统）
	if player.has_method("spend_currency"):
		if not player.spend_currency(shop_currency, price):
			return false
	else:
		# 使用默认货币检查
		if not player.has_method("inventory"):
			return false
	
	# 添加物品到玩家背包
	if player.add_to_inventory(item):
		return true
	
	return false

## 出售物品
## [param item] 要出售的物品
## [param player] 出售物品的玩家
## [return] 获得的金币
func sell_item(item: Dictionary, player: Player) -> int:
	var price = int(item.get("price", 0) * sell_multiplier)
	
	# 从玩家背包移除物品
	player._remove_from_inventory(item)
	
	# 给玩家货币（假设玩家有货币系统）
	if player.has_method("add_currency"):
		player.add_currency(shop_currency, price)
	
	return price

## 交互区域检测
func _on_interaction_body_entered(body: Node2D) -> void:
	if body is Player:
		interacted.emit(body)
		if talk_indicator:
			talk_indicator.visible = true

func _on_interaction_body_exited(body: Node2D) -> void:
	if body is Player:
		if talk_indicator:
			talk_indicator.visible = false

## 加载对话树
func _load_dialogue_tree() -> void:
	if dialogue_tree_path.is_empty():
		return
	
	var dialogue_resource = load(dialogue_tree_path)
	if dialogue_resource:
		current_dialogue = dialogue_resource

## 获取NPC状态
## [return] 状态字典
func get_state() -> Dictionary:
	var state = super.get_state()
	state["npc_type"] = npc_type
	state["npc_title"] = npc_title
	state["description"] = description
	state["available_quests"] = available_quests
	state["active_quests"] = active_quests
	state["completed_quests"] = completed_quests
	state["has_shop"] = has_shop
	state["patrol_enabled"] = patrol_enabled
	state["patrol_path"] = patrol_path
	state["current_behavior"] = current_behavior
	return state

## 获取NPC显示名称
## [return] 显示名称（包含称号）
func get_display_name() -> String:
	if npc_title.is_empty():
		return entity_name
	return "%s [%s]" % [entity_name, npc_title]

## 检查是否有可接任务
## [param player] 玩家对象
## [return] 是否有可接任务
func has_available_quest(player: Player) -> bool:
	for quest_id in available_quests:
		if quest_id not in active_quests and quest_id not in completed_quests:
			return true
	return false

## 获取可接任务列表
## [param player] 玩家对象
## [return] 可接任务ID列表
func get_available_quest_list(player: Player) -> Array[String]:
	var available: Array[String] = []
	for quest_id in available_quests:
		if quest_id not in active_quests and quest_id not in completed_quests:
			available.append(quest_id)
	return available
