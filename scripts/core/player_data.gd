class_name PlayerData
extends Resource
## 玩家数据资源类 - 存储玩家所有相关数据

# 基础属性
@export var player_name: String = "无名勇士"
@export var level: int = 1
@export var exp: int = 0
@export var exp_to_next_level: int = 100

# 生命值和魔法值
@export var hp: int = 100
@export var max_hp: int = 100
@export var mp: int = 50
@export var max_mp: int = 50

# 金币
@export var gold: int = 0

# 角色属性
@export var strength: int = 10      # 力量
@export var dexterity: int = 10     # 敏捷
@export var intelligence: int = 10   # 智力
@export var constitution: int = 10  # 体质

# 位置和区域
@export var position: Vector2 = Vector2.ZERO
@export var current_zone: String = ""

# 派系
@export var faction: String = ""
@export var faction_rank: int = 0

# 装备数据 (装备槽位 -> 物品ID)
@export var equipment: Dictionary = {
	"head": "",
	"chest": "",
	"legs": "",
	"feet": "",
	"main_hand": "",
	"off_hand": "",
	"accessory1": "",
	"accessory2": ""
}

# 背包数据 (物品ID和数量)
@export var inventory: Array[Dictionary] = []

# 技能数据 (技能ID和等级)
@export var skills: Array[Dictionary] = []

# 派系声望 (派系ID -> 声望值)
@export var reputation: Dictionary = {}

# 剧情标志 (标志名称 -> 标志值)
@export var story_flags: Dictionary = {}

# 任务进度 (任务ID -> 任务进度数据)
@export var quest_progress: Dictionary = {}

# 已完成的任务列表
@export var completed_quests: Array[String] = []

# 创建新的玩家数据实例
static func create_default() -> PlayerData:
	var data := PlayerData.new()
	data._init_default_values()
	return data

## 初始化默认值
func _init_default_values() -> void:
	player_name = "无名勇士"
	level = 1
	exp = 0
	exp_to_next_level = 100
	hp = 100
	max_hp = 100
	mp = 50
	max_mp = 50
	gold = 0
	strength = 10
	dexterity = 10
	intelligence = 10
	constitution = 10
	position = Vector2.ZERO
	current_zone = ""
	faction = ""
	faction_rank = 0
	equipment = {
		"head": "",
		"chest": "",
		"legs": "",
		"feet": "",
		"main_hand": "",
		"off_hand": "",
		"accessory1": "",
		"accessory2": ""
	}
	inventory = []
	skills = []
	reputation = {}
	story_flags = {}
	quest_progress = {}
	completed_quests = []

## 获取属性值
func get_stat(stat_name: String) -> int:
	match stat_name:
		"strength":
			return strength
		"dexterity":
			return dexterity
		"intelligence":
			return intelligence
		"constitution":
			return constitution
		_:
			push_warning("PlayerData: 未知属性: " + stat_name)
			return 0

## 设置属性值
func set_stat(stat_name: String, value: int) -> void:
	match stat_name:
		"strength":
			strength = value
		"dexterity":
			dexterity = value
		"intelligence":
			intelligence = value
		"constitution":
			constitution = value
		_:
			push_warning("PlayerData: 未知属性: " + stat_name)

## 获取经验值所需
func get_exp_for_level(lvl: int) -> int:
	return int(pow(lvl, 2.0) * 100)

## 增加经验值
func add_exp(amount: int) -> bool:
	exp += amount
	var leveled_up := false
	
	while exp >= exp_to_next_level:
		exp -= exp_to_next_level
		level += 1
		exp_to_next_level = get_exp_for_level(level)
		leveled_up = true
		_on_level_up()
	
	return leveled_up

## 升级时调用
func _on_level_up() -> void:
	max_hp += 5
	max_mp += 2
	hp = max_hp
	mp = max_mp
	print("PlayerData: 升级到 " + str(level))

## 增加金币
func add_gold(amount: int) -> void:
	gold += max(0, amount)

## 消耗金币
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

## 检查是否有足够金币
func has_gold(amount: int) -> bool:
	return gold >= amount

## 获取生命值百分比
func get_hp_percentage() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)

## 获取魔法值百分比
func get_mp_percentage() -> float:
	if max_mp <= 0:
		return 0.0
	return float(mp) / float(max_mp)

## 恢复生命值
func heal_hp(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

## 恢复魔法值
func heal_mp(amount: int) -> void:
	mp = mini(mp + amount, max_mp)

## 受到伤害
func take_damage(amount: int) -> int:
	var actual_damage := mini(amount, hp)
	hp -= actual_damage
	
	if hp <= 0:
		hp = 0
		EventBus.player_hp_changed.emit(0, max_hp)
	
	return actual_damage

## 使用魔法值
func use_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		return true
	return false

## 检查是否有足够魔法值
func has_mp(amount: int) -> bool:
	return mp >= amount

## 设置剧情标志
func set_story_flag(flag_name: String, value: Variant) -> void:
	story_flags[flag_name] = value

## 获取剧情标志
func get_story_flag(flag_name: String, default_value: Variant = null) -> Variant:
	return story_flags.get(flag_name, default_value)

## 检查剧情标志是否存在
func has_story_flag(flag_name: String) -> bool:
	return story_flags.has(flag_name)

## 添加物品到背包
func add_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		push_warning("PlayerData: 无效的物品数量: " + str(quantity))
		return false
	
	for item in inventory:
		if item.get("item_id") == item_id:
			item["quantity"] += quantity
			EventBus.emit_item_picked_up(item_id)
			return true
	
	inventory.append({"item_id": item_id, "quantity": quantity})
	EventBus.emit_item_picked_up(item_id)
	return true

## 从背包移除物品
func remove_from_inventory(item_id: String, quantity: int = 1) -> bool:
	for i in range(inventory.size()):
		var item: Dictionary = inventory[i]
		if item.get("item_id") == item_id:
			var current_quantity: int = item.get("quantity", 0)
			if current_quantity >= quantity:
				if current_quantity == quantity:
					inventory.remove_at(i)
				else:
					item["quantity"] = current_quantity - quantity
				return true
			else:
				push_warning("PlayerData: 物品数量不足")
				return false
	
	push_warning("PlayerData: 背包中没有物品: " + item_id)
	return false

## 检查背包中是否有物品
func has_in_inventory(item_id: String, quantity: int = 1) -> bool:
	for item in inventory:
		if item.get("item_id") == item_id:
			return item.get("quantity", 0) >= quantity
	return false

## 获取物品数量
func get_item_quantity(item_id: String) -> int:
	for item in inventory:
		if item.get("item_id") == item_id:
			return item.get("quantity", 0)
	return 0

## 装备物品
func equip_item(item_id: String, slot: String) -> bool:
	if not equipment.has(slot):
		push_warning("PlayerData: 无效的装备槽位: " + slot)
		return false
	
	var old_item_id: String = equipment[slot]
	equipment[slot] = item_id
	
	EventBus.item_equipped.emit(item_id, -1)
	if not old_item_id.is_empty():
		add_to_inventory(old_item_id, 1)
	
	return true

## 卸下装备
func unequip_item(slot: String) -> bool:
	if not equipment.has(slot):
		push_warning("PlayerData: 无效的装备槽位: " + slot)
		return false
	
	var item_id: String = equipment[slot]
	if item_id.is_empty():
		return false
	
	equipment[slot] = ""
	add_to_inventory(item_id, 1)
	EventBus.item_unequipped.emit(item_id, -1)
	return true

## 获取已装备的物品ID
func get_equipped_item(slot: String) -> String:
	return equipment.get(slot, "")

## 添加技能
func add_skill(skill_id: String, skill_level: int = 1) -> void:
	for skill in skills:
		if skill.get("skill_id") == skill_id:
			skill["level"] = skill_level
			return
	
	skills.append({"skill_id": skill_id, "level": skill_level})
	EventBus.emit_skill_learned(skill_id)

## 提升技能等级
func level_up_skill(skill_id: String) -> void:
	for skill in skills:
		if skill.get("skill_id") == skill_id:
			skill["level"] += 1
			EventBus.skill_learned.emit(skill_id)
			return
	
	add_skill(skill_id, 1)

## 获取技能等级
func get_skill_level(skill_id: String) -> int:
	for skill in skills:
		if skill.get("skill_id") == skill_id:
			return skill.get("level", 0)
	return 0

## 检查是否拥有技能
func has_skill(skill_id: String) -> bool:
	for skill in skills:
		if skill.get("skill_id") == skill_id:
			return true
	return false

## 修改派系声望
func modify_faction_reputation(faction_id: String, amount: int) -> void:
	var old_rep: int = reputation.get(faction_id, 0)
	var new_rep: int = maxi(old_rep + amount, -100)
	new_rep = mini(new_rep, 100)
	reputation[faction_id] = new_rep
	
	EventBus.faction_reputation_changed.emit(faction_id, old_rep, new_rep)

## 设置派系声望
func set_faction_reputation(faction_id: String, value: int) -> void:
	var clamped_value := clampi(value, -100, 100)
	var old_rep: int = reputation.get(faction_id, 0)
	reputation[faction_id] = clamped_value
	
	EventBus.emit_faction_reputation_changed(faction_id, old_rep, clamped_value)

## 获取派系声望
func get_faction_reputation(faction_id: String) -> int:
	return reputation.get(faction_id, 0)

## 获取派系声望等级
func get_faction_reputation_rank(faction_id: String) -> int:
	var rep: int = get_faction_reputation(faction_id)
	
	if rep >= 90:
		return 5
	elif rep >= 70:
		return 4
	elif rep >= 40:
		return 3
	elif rep >= 10:
		return 2
	elif rep >= -10:
		return 1
	else:
		return 0

## 开始任务
func start_quest(quest_id: String) -> void:
	if not quest_progress.has(quest_id):
		quest_progress[quest_id] = {
			"status": "active",
			"progress": 0,
			"objectives": {}
		}
		EventBus.quest_accepted.emit(quest_id)

## 更新任务进度
func update_quest_progress(quest_id: String, objective_id: String, progress: float) -> void:
	if quest_progress.has(quest_id):
		var quest_data: Dictionary = quest_progress[quest_id]
		quest_data["progress"] = progress
		if not quest_data.has("objectives"):
			quest_data["objectives"] = {}
		quest_data["objectives"][objective_id] = progress
		EventBus.quest_progress_changed.emit(quest_id, -1)

## 完成任务
func complete_quest(quest_id: String) -> void:
	if quest_progress.has(quest_id):
		quest_progress.erase(quest_id)
		completed_quests.append(quest_id)
		EventBus.emit_quest_completed(quest_id)

## 检查任务是否已完成
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## 检查任务是否在进行中
func is_quest_active(quest_id: String) -> bool:
	return quest_progress.has(quest_id)

## 转换为字典
func to_dictionary() -> Dictionary:
	return {
		"player_name": player_name,
		"level": level,
		"exp": exp,
		"exp_to_next_level": exp_to_next_level,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"gold": gold,
		"strength": strength,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"constitution": constitution,
		"position": position,
		"current_zone": current_zone,
		"faction": faction,
		"faction_rank": faction_rank,
		"equipment": equipment,
		"inventory": inventory,
		"skills": skills,
		"reputation": reputation,
		"story_flags": story_flags,
		"quest_progress": quest_progress,
		"completed_quests": completed_quests
	}

## 从字典创建
static func from_dictionary(data: Dictionary) -> PlayerData:
	var player_data := PlayerData.new()
	
	player_data.player_name = data.get("player_name", "无名勇士")
	player_data.level = data.get("level", 1)
	player_data.exp = data.get("exp", 0)
	player_data.exp_to_next_level = data.get("exp_to_next_level", 100)
	player_data.hp = data.get("hp", 100)
	player_data.max_hp = data.get("max_hp", 100)
	player_data.mp = data.get("mp", 50)
	player_data.max_mp = data.get("max_mp", 50)
	player_data.gold = data.get("gold", 0)
	player_data.strength = data.get("strength", 10)
	player_data.dexterity = data.get("dexterity", 10)
	player_data.intelligence = data.get("intelligence", 10)
	player_data.constitution = data.get("constitution", 10)
	player_data.position = data.get("position", Vector2.ZERO)
	player_data.current_zone = data.get("current_zone", "")
	player_data.faction = data.get("faction", "")
	player_data.faction_rank = data.get("faction_rank", 0)
	player_data.equipment = data.get("equipment", {})
	player_data.inventory = data.get("inventory", [])
	player_data.skills = data.get("skills", [])
	player_data.reputation = data.get("reputation", {})
	player_data.story_flags = data.get("story_flags", {})
	player_data.quest_progress = data.get("quest_progress", {})
	player_data.completed_quests = data.get("completed_quests", [])
	
	return player_data
