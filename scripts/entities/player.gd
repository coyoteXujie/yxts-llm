extends Entity
class_name Player
## 玩家类 - 玩家控制的角色
## 继承自Entity类，添加玩家特有的属性和功能

# 玩家基础属性
@export var strength: int = 10      ## 力量 - 影响物理攻击力
@export var dexterity: int = 10     ## 敏捷 - 影响攻击速度和闪避
@export var intelligence: int = 10  ## 智力 - 影响魔法攻击力和魔法值
@export var constitution: int = 10   ## 体质 - 影响生命值和防御力

# 经验值系统
@export var current_exp: int = 0    ## 当前经验值
@export var exp_to_next_level: int = 100  ## 升级所需经验值

# 阵营系统
@export var faction: String = "neutral"  ## 当前阵营
@export var faction_relationships: Dictionary = {}  ## 阵营关系

# 装备槽位定义
enum EquipmentSlot {
	WEAPON,    ## 武器
	ARMOR,     ## 护甲
	HELMET,    ## 头盔
	ACCESSORY, ## 饰品
	BOOTS,     ## 靴子
	BELT       ## 腰带
}

var equipment: Dictionary = {
	EquipmentSlot.WEAPON: null,
	EquipmentSlot.ARMOR: null,
	EquipmentSlot.HELMET: null,
	EquipmentSlot.ACCESSORY: null,
	EquipmentSlot.BOOTS: null,
	EquipmentSlot.BELT: null
}  ## 已装备的物品

# 背包系统
@export var inventory: Array[Dictionary] = []  ## 背包物品列表
@export var max_inventory_size: int = 20  ## 背包最大容量

# 技能系统
@export var skill_slots: Array = [null, null, null, null]  ## 4个技能槽位
@export var learned_skills: Array[String] = []  ## 已学会的技能列表

# 角色精灵
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

# 移动参数
var move_speed: float = 200.0  ## 移动速度
var current_direction: Vector2 = Vector2.ZERO  ## 当前移动方向
var is_moving: bool = false  ## 是否在移动中

# 信号定义
signal exp_changed(current_exp: int, exp_to_next: int)  ## 经验值变化
signal level_up(new_level: int)  ## 升级
signal equipment_changed(slot: EquipmentSlot, item: Dictionary)  ## 装备变化
signal skill_learned(skill_id: String)  ## 技能学会
signal skill_used(skill_index: int)  ## 技能使用
signal faction_changed(new_faction: String)  ## 阵营变化

func _ready() -> void:
	super._ready()
	entity_type = EntityType.PLAYER
	
	# 初始化阵营关系
	if faction_relationships.is_empty():
		faction_relationships = {
		"neutral": 50,
		"friendly": 50,
		"hostile": -50
	}
	
	# 连接交互区域信号
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	
	# 初始化基础属性
	_calculate_derived_stats()

func _physics_process(delta: float) -> void:
	_handle_movement_input()
	_handle_interaction_input()
	super._physics_process(delta)

func _process(delta: float) -> void:
	_update_animation()

## 处理移动输入（WASD）
func _handle_movement_input() -> void:
	var input_direction: Vector2 = Vector2.ZERO
	
	# 获取WASD输入
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# 标准化方向向量
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		current_direction = input_direction
		is_moving = true
	else:
		is_moving = false
	
	# 设置移动速度
	velocity = input_direction * move_speed

## 处理交互输入（E键）
func _handle_interaction_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):  # E键通常映射到ui_accept
		try_interact()

## 更新角色动画
func _update_animation() -> void:
	if not sprite:
		return
	
	if is_moving:
		# 根据方向设置动画
		if current_direction.x > 0:
			sprite.play("walk_right")
			facing_direction = Vector2.RIGHT
		elif current_direction.x < 0:
			sprite.play("walk_left")
			facing_direction = Vector2.LEFT
		elif current_direction.y > 0:
			sprite.play("walk_down")
			facing_direction = Vector2.DOWN
		elif current_direction.y < 0:
			sprite.play("walk_up")
			facing_direction = Vector2.UP
	else:
		# 空闲动画
		if facing_direction == Vector2.RIGHT:
			sprite.play("idle_right")
		elif facing_direction == Vector2.LEFT:
			sprite.play("idle_left")
		elif facing_direction == Vector2.UP:
			sprite.play("idle_up")
		else:
			sprite.play("idle_down")

## 尝试与附近对象交互
func try_interact() -> void:
	if not interaction_area:
		return
	
	var bodies: Array[Node2D] = interaction_area.get_overlapping_bodies()
	for body in bodies:
		if body is NPC:
			body.start_dialogue(self)
			return
		elif body.has_method("interact"):
			body.interact(self)
			return

## 交互区域检测
func _on_interaction_body_entered(body: Node2D) -> void:
	if body is NPC or body.has_method("interact"):
		# 显示交互提示
		pass

func _on_interaction_body_exited(body: Node2D) -> void:
	pass

## 装备物品
## [param item] 要装备的物品数据
## [param slot] 装备槽位
## [return] 是否成功装备
func equip_item(item: Dictionary, slot: EquipmentSlot) -> bool:
	if not _validate_item(item):
		return false
	
	# 卸下当前装备
	var old_item = equipment[slot]
	if old_item:
		unequip_item(slot)
	
	# 装备新物品
	equipment[slot] = item
	equipment_changed.emit(slot, item)
	
	# 从背包移除
	_remove_from_inventory(item)
	
	# 更新属性
	_calculate_derived_stats()
	return true

## 卸下装备
## [param slot] 要卸下的槽位
## [return] 卸下的物品
func unequip_item(slot: EquipmentSlot) -> Dictionary:
	var item = equipment[slot]
	if item:
		equipment[slot] = null
		equipment_changed.emit(slot, {})
		
		# 添加到背包
		if inventory.size() < max_inventory_size:
			inventory.append(item)
		else:
			# 背包已满，物品消失
			pass
		
		_calculate_derived_stats()
		return item
	return {}

## 使用物品
## [param item] 要使用的物品
## [return] 是否成功使用
func use_item(item: Dictionary) -> bool:
	if not _validate_item(item):
		return false
	
	var item_type = item.get("type", "")
	
	match item_type:
		"consumable":  # 消耗品
			_use_consumable(item)
			return true
		"equipment":  # 装备（直接装备）
			var slot = _get_equipment_slot(item)
			if slot != -1:
				return equip_item(item, slot as EquipmentSlot)
	
	return false

## 使用消耗品
## [param item] 消耗品数据
func _use_consumable(item: Dictionary) -> void:
	var effects = item.get("effects", {})
	
	if effects.has("hp"):
		heal(effects["hp"])
	if effects.has("mp"):
		mp = mini(mp + effects["mp"], max_mp)
	if effects.has("exp"):
		add_exp(effects["exp"])
	
	# 从背包移除
	_remove_from_inventory(item)

## 添加经验值
## [param amount] 要添加的经验值
func add_exp(amount: int) -> void:
	current_exp += amount
	exp_changed.emit(current_exp, exp_to_next_level)
	
	# 检查升级
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level_up()
		exp_to_next_level = _calculate_exp_for_level(level)

## 升级处理
func level_up() -> void:
	level += 1
	level_up.emit(level)
	
	# 提升属性
	strength += 2
	dexterity += 1
	intelligence += 1
	constitution += 2
	
	# 恢复生命值和魔法值
	max_hp += constitution * 5
	max_mp += intelligence * 3
	hp = max_hp
	mp = max_mp
	
	# 重新计算衍生属性
	_calculate_derived_stats()

## 学习技能
## [param skill_id] 技能ID
## [return] 是否成功学习
func learn_skill(skill_id: String) -> bool:
	if skill_id in learned_skills:
		return false  # 已经学会
	
	# 找到空槽位
	for i in range(skill_slots.size()):
		if skill_slots[i] == null:
			skill_slots[i] = skill_id
			learned_skills.append(skill_id)
			skill_learned.emit(skill_id)
			return true
	
	return false  # 槽位已满

## 使用技能
## [param slot_index] 技能槽索引
## [param target] 目标
func use_skill(slot_index: int, target: Node = null) -> bool:
	if slot_index < 0 or slot_index >= skill_slots.size():
		return false
	
	var skill_id = skill_slots[slot_index]
	if not skill_id:
		return false
	
	# 消耗魔法值（假设有技能数据）
	var skill_data = _get_skill_data(skill_id)
	if not skill_data:
		return false
	
	var mp_cost = skill_data.get("mp_cost", 0)
	if mp < mp_cost:
		return false  # 魔法值不足
	
	mp -= mp_cost
	skill_used.emit(slot_index)
	
	# 执行技能效果
	_execute_skill(skill_id, target)
	return true

## 执行技能效果
## [param skill_id] 技能ID
## [param target] 目标
func _execute_skill(skill_id: String, target: Node) -> void:
	# 这里是技能系统的占位实现
	# 实际实现需要技能系统支持
	pass

## 获取技能数据
## [param skill_id] 技能ID
## [return] 技能数据字典
func _get_skill_data(skill_id: String) -> Dictionary:
	return {}

## 改变阵营
## [param new_faction] 新阵营ID
func change_faction(new_faction: String) -> void:
	faction = new_faction
	faction_changed.emit(faction)

## 计算衍生属性
func _calculate_derived_stats() -> void:
	# 基础属性计算
	attack = strength * 2 + 10
	defense = constitution * 1.5 + 5
	max_hp = constitution * 10 + 100
	max_mp = intelligence * 5 + 50
	
	# 装备加成
	for item in equipment.values():
		if item and item is Dictionary:
			attack += item.get("attack_bonus", 0)
			defense += item.get("defense_bonus", 0)
			max_hp += item.get("hp_bonus", 0)
			max_mp += item.get("mp_bonus", 0)
	
	# 确保生命值和魔法值不超过最大值
	hp = mini(hp, max_hp)
	mp = mini(mp, max_mp)

## 验证物品是否有效
## [param item] 物品数据
## [return] 是否有效
func _validate_item(item: Dictionary) -> bool:
	return item.has("id") and item.has("type")

## 从背包移除物品
## [param item] 要移除的物品
func _remove_from_inventory(item: Dictionary) -> void:
	var index = inventory.find(item)
	if index >= 0:
		inventory.remove_at(index)

## 获取装备槽位类型
## [param item] 物品数据
## [return] 装备槽位索引，-1表示无效
func _get_equipment_slot(item: Dictionary) -> int:
	var equip_type = item.get("equip_type", "")
	match equip_type:
		"weapon":
			return EquipmentSlot.WEAPON
		"armor":
			return EquipmentSlot.ARMOR
		"helmet":
			return EquipmentSlot.HELMET
		"accessory":
			return EquipmentSlot.ACCESSORY
		"boots":
			return EquipmentSlot.BOOTS
		"belt":
			return EquipmentSlot.BELT
	return -1

## 计算指定等级所需经验值
## [param target_level] 目标等级
## [return] 所需经验值
func _calculate_exp_for_level(target_level: int) -> int:
	return int(100 * pow(1.5, target_level - 1))

## 获取物品栏中指定槽位的物品
## [param slot] 装备槽位
## [return] 装备的物品数据
func get_equipment(slot: EquipmentSlot) -> Dictionary:
	return equipment.get(slot, {})

## 获取所有装备
## [return] 所有装备的字典
func get_all_equipment() -> Dictionary:
	return equipment.duplicate()

## 添加物品到背包
## [param item] 要添加的物品
## [return] 是否成功添加
func add_to_inventory(item: Dictionary) -> bool:
	if inventory.size() >= max_inventory_size:
		return false
	inventory.append(item)
	return true

## 获取玩家状态
## [return] 完整的状态字典
func get_state() -> Dictionary:
	var state = super.get_state()
	state["strength"] = strength
	state["dexterity"] = dexterity
	state["intelligence"] = intelligence
	state["constitution"] = constitution
	state["current_exp"] = current_exp
	state["exp_to_next_level"] = exp_to_next_level
	state["faction"] = faction
	state["equipment"] = equipment
	state["inventory"] = inventory
	state["skill_slots"] = skill_slots
	state["learned_skills"] = learned_skills
	return state
