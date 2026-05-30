extends Entity
class_name Enemy
## 敌人类 - 游戏中的敌人实体
## 继承自Entity类，添加敌人特有的属性和AI行为

# 敌人类型分类
enum EnemyType {
	MELEE,      # 近战型
	RANGED,     # 远程型
	MAGIC,      # 魔法型
	BOSS,       # BOSS型
	ELITE       # 精英型
}

# AI行为模式枚举
enum AIBehavior {
	AGGRESSIVE,  # 主动攻击型
	DEFENSIVE,   # 防守反击型
	COWARDLY     # 胆小逃跑型
}

# 敌人分类标签
@export var enemy_type: EnemyType = EnemyType.MELEE
@export var enemy_class: String = ""  # 敌人职业/分类（如"哥布林"、"骷髅"等）
@export var description: String = ""  # 敌人描述

# 经验值奖励
@export var exp_reward: int = 50  # 击杀经验奖励

# 掉落表系统
@export var loot_table: Array[Dictionary] = []  # 掉落物品列表
@export var gold_drop_min: int = 0  # 金币掉落最小值
@export var gold_drop_max: int = 0  # 金币掉落最大值

# AI行为配置
@export var default_behavior: AIBehavior = AIBehavior.AGGRESSIVE
@export var aggro_range: float = 150.0  # 仇恨触发范围
@export var attack_range: float = 40.0  # 攻击范围
@export var lose_aggro_range: float = 300.0  # 失去仇恨范围
@export var chase_speed: float = 100.0  # 追击速度

# 战斗能力
@export var abilities: Array[Dictionary] = []  # 战斗技能列表
@export var ability_cooldowns: Dictionary = {}  # 技能冷却时间
@export var attack_cooldown: float = 1.0  # 攻击冷却时间
var current_attack_cooldown: float = 0.0  # 当前攻击冷却

# AI状态
var current_ai_behavior: AIBehavior = AIBehavior.AGGRESSIVE
var aggro_target: Node2D = null  # 仇恨目标
var is_aggroed: bool = false  # 是否进入战斗状态
var last_known_target_position: Vector2 = Vector2.ZERO  # 目标最后已知位置

# 巡逻相关
@export var patrol_enabled: bool = false  # 是否启用巡逻
@export var patrol_points: Array[Vector2i] = []  # 巡逻点列表
@export var patrol_speed: float = 50.0  # 巡逻速度
@export var idle_time: float = 2.0  # 巡逻点停留时间

var current_patrol_index: int = 0
var patrol_timer: float = 0.0
var is_idle: bool = false

# 移动和动画
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var detection_area: Area2D = $DetectionArea if has_node("DetectionArea") else null

# 信号定义
signal aggroed(target: Node2D)  # 进入战斗状态
signal deaggroed()  # 脱离战斗状态
signal loot_dropped(items: Array[Dictionary])  # 掉落物品
signal ability_used(ability: Dictionary)  # 使用技能

func _ready() -> void:
	super._ready()
	entity_type = EntityType.ENEMY
	current_ai_behavior = default_behavior
	
	# 初始化技能冷却
	for ability in abilities:
		if ability.has("id"):
			ability_cooldowns[ability["id"]] = 0.0
	
	# 连接检测区域信号
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	
	# 如果没有启用巡逻，设置为空闲
	if not patrol_enabled:
		is_idle = true

func _physics_process(delta: float) -> void:
	# 处理攻击冷却
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta
	
	# 更新技能冷却
	for ability_id in ability_cooldowns:
		if ability_cooldowns[ability_id] > 0:
			ability_cooldowns[ability_id] -= delta
	
	# AI行为处理
	if is_aggroed and aggro_target:
		_process_combat_ai(delta)
	elif patrol_enabled and not patrol_points.is_empty():
		_process_patrol(delta)
	else:
		_process_idle(delta)
	
	super._physics_process(delta)

## 处理空闲状态
## [param delta] 帧时间
func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	_update_idle_animation()

## 处理巡逻AI
## [param delta] 帧时间
func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		patrol_enabled = false
		is_idle = true
		return
	
	if is_idle:
		patrol_timer += delta
		if patrol_timer >= idle_time:
			patrol_timer = 0.0
			is_idle = false
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return
	
	# 移动到下一个巡逻点
	var target_pos: Vector2 = Vector2(patrol_points[current_patrol_index]) * 32
	var direction: Vector2 = (target_pos - global_position)
	
	if direction.length() > 5.0:
		direction = direction.normalized()
		velocity = direction * patrol_speed
		_update_patrol_animation(direction)
	else:
		velocity = Vector2.ZERO
		is_idle = true
		if sprite:
			sprite.play("idle")

## 处理战斗AI
## [param delta] 帧时间
func _process_combat_ai(delta: float) -> void:
	# 检查目标是否有效
	if not aggro_target or not is_instance_valid(aggro_target):
		_clear_aggro()
		return
	
	# 检查是否超出仇恨范围
	var distance_to_target: float = global_position.distance_to(aggro_target.global_position)
	if distance_to_target > lose_aggro_range:
		_clear_aggro()
		return
	
	# 根据AI行为模式处理
	match current_ai_behavior:
		AIBehavior.AGGRESSIVE:
			_process_aggressive_behavior(distance_to_target)
		AIBehavior.DEFENSIVE:
			_process_defensive_behavior(distance_to_target)
		AIBehavior.COWARDLY:
			_process_cowardly_behavior(distance_to_target)

## 处理主动攻击行为
## [param distance] 与目标的距离
func _process_aggressive_behavior(distance: float) -> void:
	if distance > attack_range:
		# 追击目标
		var direction: Vector2 = (aggro_target.global_position - global_position).normalized()
		velocity = direction * chase_speed
		_update_chase_animation(direction)
	else:
		# 停止移动，准备攻击
		velocity = Vector2.ZERO
		_attack_target(aggro_target)

## 处理防守反击行为
## [param distance] 与目标的距离
func _process_defensive_behavior(distance: float) -> void:
	var safe_distance: float = attack_range * 1.5
	
	if distance < safe_distance:
		# 目标太近，后退
		var direction: Vector2 = (global_position - aggro_target.global_position).normalized()
		velocity = direction * chase_speed * 0.8
		_update_chase_animation(direction)
	elif distance > safe_distance * 2:
		# 目标太远，前进
		var direction: Vector2 = (aggro_target.global_position - global_position).normalized()
		velocity = direction * chase_speed * 0.5
		_update_chase_animation(direction)
	else:
		# 在安全距离内，等待时机
		velocity = Vector2.ZERO
		# 偶尔进行攻击
		if randf() < 0.3:
			_attack_target(aggro_target)

## 处理胆小逃跑行为
## [param distance] 与目标的距离
func _process_cowardly_behavior(distance: float) -> void:
	var flee_distance: float = attack_range * 2.0
	
	if distance < flee_distance:
		# 逃跑
		var flee_direction: Vector2 = (global_position - aggro_target.global_position).normalized()
		velocity = flee_direction * chase_speed * 1.5
		_update_chase_animation(flee_direction)
	elif distance < lose_aggro_range * 0.8:
		# 保持距离观望
		var direction: Vector2 = (global_position - aggro_target.global_position).normalized()
		velocity = direction * chase_speed * 0.3
		_update_chase_animation(direction)
	else:
		# 太远了，停止移动
		velocity = Vector2.ZERO

## 攻击目标
## [param target] 攻击目标
func _attack_target(target: Node2D) -> void:
	if current_attack_cooldown > 0:
		return
	
	# 检查是否有技能可用
	var available_ability = _get_available_ability()
	if available_ability:
		_use_ability(available_ability, target)
		return
	
	# 普通攻击
	if target.has_method("take_damage"):
		var damage: int = calculate_damage(target)
		target.take_damage(damage)
		current_attack_cooldown = attack_cooldown

## 计算对目标的伤害
## [param target] 目标实体
## [return] 造成的伤害值
func calculate_damage(target: Node2D) -> int:
	var base_damage: int = attack
	
	# 暴击判定
	var is_crit: bool = randf() < crit_rate
	if is_crit:
		base_damage = int(base_damage * crit_damage)
	
	# 减伤（简化计算）
	var damage_reduction: float = target.defense / (target.defense + 100.0)
	base_damage = int(base_damage * (1.0 - damage_reduction))
	
	return maxi(1, base_damage)

## 获取可用的技能
## [return] 可用的技能数据，没有则返回null
func _get_available_ability() -> Dictionary:
	for ability in abilities:
		var ability_id = ability.get("id", "")
		if ability_id in ability_cooldowns and ability_cooldowns[ability_id] <= 0:
			return ability
	return {}

## 使用技能
## [param ability] 技能数据
## [param target] 目标
func _use_ability(ability: Dictionary, target: Node2D) -> void:
	var ability_id = ability.get("id", "")
	var cooldown = ability.get("cooldown", 1.0)
	var damage = ability.get("damage", attack)
	var range = ability.get("range", attack_range)
	
	# 检查是否在技能范围内
	var distance: float = global_position.distance_to(target.global_position)
	if distance > range:
		return
	
	# 造成技能伤害
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# 设置冷却
	ability_cooldowns[ability_id] = cooldown
	ability_used.emit(ability)

## 设置仇恨目标
## [param target] 仇恨目标
func set_aggro_target(target: Node2D) -> void:
	if target == aggro_target:
		return
	
	aggro_target = target
	is_aggroed = true
	last_known_target_position = target.global_position
	aggroed.emit(target)
	
	# 停止巡逻
	patrol_enabled = false
	is_idle = false

## 清除仇恨
func _clear_aggro() -> void:
	aggro_target = null
	is_aggroed = false
	deaggroed.emit()
	
	# 恢复巡逻
	if patrol_enabled:
		is_idle = false

## 掉落物品
## [return] 掉落的物品列表
func drop_loot() -> Array[Dictionary]:
	var dropped_items: Array[Dictionary] = []
	
	# 根据掉落表随机掉落
	for loot_entry in loot_table:
		var drop_chance: float = loot_entry.get("chance", 0.0)
		if randf() < drop_chance:
			var item: Dictionary = loot_entry.get("item", {})
			if not item.is_empty():
				dropped_items.append(item)
	
	# 计算金币掉落
	var gold_amount: int = randi_range(gold_drop_min, gold_drop_max)
	if gold_amount > 0:
		dropped_items.append({
			"id": "gold",
			"name": "金币",
			"type": "currency",
			"amount": gold_amount
		})
	
	loot_dropped.emit(dropped_items)
	return dropped_items

## 被动触发仇恨（检测到玩家）
## [param body] 进入检测区域的物体
func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player and not is_aggroed:
		set_aggro_target(body)

func _on_detection_body_exited(body: Node2D) -> void:
	if body == aggro_target:
		_clear_aggro()

## 更新动画
func _update_idle_animation() -> void:
	if not sprite:
		return
	if facing_direction == Vector2.RIGHT:
		sprite.play("idle_right")
	elif facing_direction == Vector2.LEFT:
		sprite.play("idle_left")
	elif facing_direction == Vector2.UP:
		sprite.play("idle_up")
	else:
		sprite.play("idle_down")

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

func _update_chase_animation(direction: Vector2) -> void:
	if not sprite:
		return
	if direction.x > 0.3:
		sprite.play("chase_right")
	elif direction.x < -0.3:
		sprite.play("chase_left")
	elif direction.y > 0.3:
		sprite.play("chase_down")
	elif direction.y < -0.3:
		sprite.play("chase_up")

## 添加掉落物品到掉落表
## [param item] 物品数据
## [param chance] 掉落概率(0-1)
## [param min_quantity] 最小数量
## [param max_quantity] 最大数量
func add_to_loot_table(item: Dictionary, chance: float, min_quantity: int = 1, max_quantity: int = 1) -> void:
	loot_table.append({
		"item": item,
		"chance": chance,
		"min_quantity": min_quantity,
		"max_quantity": max_quantity
	})

## 获取敌人状态
## [return] 状态字典
func get_state() -> Dictionary:
	var state = super.get_state()
	state["enemy_type"] = enemy_type
	state["enemy_class"] = enemy_class
	state["exp_reward"] = exp_reward
	state["current_ai_behavior"] = current_ai_behavior
	state["is_aggroed"] = is_aggroed
	return state

## 初始化敌人
## [param data] 初始化数据
func initialize(data: Dictionary = {}) -> void:
	super.initialize(data)
	
	if data.has("enemy_type"):
		enemy_type = data["enemy_type"]
	if data.has("enemy_class"):
		enemy_class = data["enemy_class"]
	if data.has("exp_reward"):
		exp_reward = data["exp_reward"]
	if data.has("loot_table"):
		loot_table = data["loot_table"]
	if data.has("gold_drop_min"):
		gold_drop_min = data["gold_drop_min"]
	if data.has("gold_drop_max"):
		gold_drop_max = data["gold_drop_max"]
	if data.has("abilities"):
		abilities = data["abilities"]
	if data.has("default_behavior"):
		default_behavior = data["default_behavior"]
		current_ai_behavior = default_behavior

## 获取敌人描述
## [return] 敌人描述信息
func get_description() -> String:
	var type_str: String = ""
	match enemy_type:
		EnemyType.MELEE: type_str = "近战型"
		EnemyType.RANGED: type_str = "远程型"
		EnemyType.MAGIC: type_str = "魔法型"
		EnemyType.BOSS: type_str = "BOSS"
		EnemyType.ELITE: type_str = "精英"
	
	return "%s [%s] %s" % [entity_name, type_str, description]
