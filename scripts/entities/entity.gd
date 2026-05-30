extends CharacterBody2D
class_name Entity
## 基础实体类 - 所有游戏实体的基类
## 提供通用的属性、方法和信号

# 实体类型枚举
enum EntityType {
	PLAYER,  ## 玩家
	NPC,     ## NPC
	ENEMY    ## 敌人
}

# 唯一标识符
@export var entity_id: String = ""
@export var entity_name: String = "未知实体"
@export var entity_type: EntityType = EntityType.NPC

# 等级系统
@export var level: int = 1:
	set(value):
		level = max(1, value)

# 生命值属性
@export var max_hp: int = 100:
	set(value):
		max_hp = max(1, value)
		if hp > max_hp:
			hp = max_hp

var hp: int = 100:
	set(value):
		var old_hp = hp
		hp = clampi(value, 0, max_hp)
		if hp != old_hp:
			entity_hp_changed.emit(hp, max_hp)
			if hp <= 0:
				entity_died.emit()

# 魔法值属性
@export var max_mp: int = 50:
	set(value):
		max_mp = max(0, value)
		if mp > max_mp:
			mp = max_mp

var mp: int = 50:
	set(value):
		mp = clampi(value, 0, max_mp)

# 战斗属性
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10
@export var crit_rate: float = 0.05  ## 暴击率 0-1
@export var crit_damage: float = 1.5  ## 暴击伤害倍率

# 位置和移动
var grid_position: Vector2i = Vector2i.ZERO  ## 网格坐标
var world_position: Vector2 = global_position  ## 世界坐标
var facing_direction: Vector2 = Vector2.DOWN  ## 朝向方向

# 信号定义
signal entity_died  ## 实体死亡时发出
signal entity_hp_changed(new_hp: int, max_hp: int)  ## 生命值变化时发出
signal entity_hurt(hurt_amount: int)  ## 实体受伤时发出

func _ready() -> void:
	## 初始化实体
	add_to_group("entities")
	_update_grid_position()

func _physics_process(delta: float) -> void:
	## 物理处理 - 移动和碰撞
	move_and_slide()

func _process(delta: float) -> void:
	## 每帧处理
	_update_world_position()

## 受到伤害
## [param amount] 伤害值
## [return] 实际受到的伤害
func take_damage(amount: int) -> int:
	var actual_damage: int = mini(amount, hp)
	hp -= actual_damage
	entity_hurt.emit(actual_damage)
	return actual_damage

## 治疗
## [param amount] 治疗量
## [return] 实际治疗量
func heal(amount: int) -> int:
	var actual_heal: int = mini(amount, max_hp - hp)
	hp += actual_heal
	return actual_heal

## 检查是否死亡
## [return] 是否已死亡
func is_dead() -> bool:
	return hp <= 0

## 获取属性字典
## [return] 包含所有属性的字典
func get_stats() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_name": entity_name,
		"entity_type": entity_type,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage
	}

## 设置网格位置
## [param pos] 网格坐标
func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos
	global_position = Vector2(pos) * 32  # 假设网格大小为32

## 更新网格位置
func _update_grid_position() -> void:
	grid_position = Vector2i(global_position / 32)

## 更新世界位置
func _update_world_position() -> void:
	world_position = global_position

## 获取实体描述
## [return] 实体的描述信息
func get_description() -> String:
	return "%s [Lv.%d] HP: %d/%d" % [entity_name, level, hp, max_hp]

## 虚拟方法：初始化实体（子类可重写）
## [param data] 初始化数据
func initialize(data: Dictionary = {}) -> void:
	if data.has("entity_id"):
		entity_id = data["entity_id"]
	if data.has("entity_name"):
		entity_name = data["entity_name"]
	if data.has("level"):
		level = data["level"]
	if data.has("max_hp"):
		max_hp = data["max_hp"]
		hp = max_hp
	if data.has("max_mp"):
		max_mp = data["max_mp"]
		mp = max_mp
	if data.has("attack"):
		attack = data["attack"]
	if data.has("defense"):
		defense = data["defense"]
	if data.has("speed"):
		speed = data["speed"]
	if data.has("crit_rate"):
		crit_rate = data["crit_rate"]
	if data.has("crit_damage"):
		crit_damage = data["crit_damage"]

## 获取当前状态
## [return] 状态字典
func get_state() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_name": entity_name,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"position": global_position
	}
