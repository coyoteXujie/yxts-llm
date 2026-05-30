extends Resource
class_name Skill

# 技能资源类 - 定义所有可用的技能

# 技能类型枚举
enum SkillType {
	ATTACK = 0,
	HEAL = 1,
	BUFF = 2,
	DEBUFF = 3
}

# 目标类型枚举
enum TargetType {
	SELF = 0,
	SINGLE = 1,
	ALL = 2
}

# 技能基础属性
@export var skill_id: String = ""
@export var name: String = "未知技能"
@export_multiline var description: String = ""

# 技能类型和目标
@export var type: SkillType = SkillType.ATTACK
@export var target_type: TargetType = TargetType.SINGLE

# 数值属性
@export var damage: int = 0
@export var healing: int = 0
@export var mana_cost: int = 0
@export var cooldown: int = 0

# 效果属性
@export var accuracy: float = 1.0
@export var critical_rate_bonus: float = 0.0

# 状态效果数组
@export var effects: Array[Dictionary] = []

# 动画和视觉配置
@export var animation_name: String = ""
@export var vfx_scene: String = ""
@export var sound_effect: String = ""

# 技能使用条件
@export var min_range: int = 0
@export var max_range: int = 10
@export var required_weapon_type: String = ""
@export var level_required: int = 1

func _init() -> void:
	if skill_id.is_empty():
		skill_id = "skill_" + str(hash(name))

# 检查技能是否可以使用
func can_use(combatant: Combatant) -> bool:
	if not is_instance_valid(combatant):
		return false
	
	if not combatant.is_alive():
		return false
	
	if combatant.current_mp < mana_cost:
		return false
	
	var skill_key: String = skill_id if not skill_id.is_empty() else str(get_instance_id())
	if combatant.action_cooldowns.has(skill_key):
		if combatant.action_cooldowns[skill_key] > 0:
			return false
	
	if required_weapon_type != "":
		if not combatant.entity.has("equipped_weapon"):
			return false
		var equipped: String = combatant.entity.get("equipped_weapon")
		if equipped != required_weapon_type:
			return false
	
	if level_required > 0:
		if combatant.entity.has("level"):
			if combatant.entity.level < level_required:
				return false
	
	return true

# 执行技能效果
func execute(caster: Combatant, targets: Array[Combatant]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	if not is_instance_valid(caster) or targets.is_empty():
		return results
	
	match type:
		SkillType.ATTACK:
			results = _execute_attack(caster, targets)
		SkillType.HEAL:
			results = _execute_heal(caster, targets)
		SkillType.BUFF:
			results = _execute_buff(caster, targets)
		SkillType.DEBUFF:
			results = _execute_debuff(caster, targets)
	
	return results

# 执行攻击技能
func _execute_attack(caster: Combatant, targets: Array[Combatant]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for target: Combatant in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		
		if randf() > accuracy:
			results.append({
				"target": target,
				"missed": true
			})
			continue
		
		var combat_manager: Node = Engine.get_meta("CombatManager")
		var damage_result: Dictionary
		
		if combat_manager:
			damage_result = combat_manager.calculate_damage(caster, target, self)
		else:
			damage_result = _calculate_damage_fallback(caster, target)
		
		results.append({
			"target": target,
			"damage": damage_result.get("damage", damage),
			"critical": damage_result.get("critical", false),
			"status_effects": _roll_status_effects()
		})
	
	return results

# 执行治疗技能
func _execute_heal(caster: Combatant, targets: Array[Combatant]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for target: Combatant in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		
		var heal_amount: int = healing
		
		if caster.entity and caster.entity.has("healing_power_bonus"):
			heal_amount += caster.entity.get("healing_power_bonus")
		
		heal_amount = mini(heal_amount, target.max_hp - target.current_hp)
		
		results.append({
			"target": target,
			"healing": heal_amount,
			"status_effects": []
		})
	
	return results

# 执行增益技能
func _execute_buff(caster: Combatant, targets: Array[Combatant]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for target: Combatant in targets:
		if not is_instance_valid(target):
			continue
		
		results.append({
			"target": target,
			"status_effects": effects.duplicate(true)
		})
	
	return results

# 执行减益技能
func _execute_debuff(caster: Combatant, targets: Array[Combatant]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for target: Combatant in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		
		if randf() > accuracy:
			results.append({
				"target": target,
				"missed": true,
				"status_effects": []
			})
			continue
		
		results.append({
			"target": target,
			"damage": damage if damage > 0 else 0,
			"status_effects": effects.duplicate(true)
		})
	
	return results

# 计算伤害（无战斗管理器时的后备方案）
func _calculate_damage_fallback(caster: Combatant, target: Combatant) -> Dictionary:
	var attack_stat: float = caster.get_attack()
	var defense_stat: float = target.get_defense()
	
	var base_damage: int = damage if damage > 0 else 10
	var calculated_damage: int = int((attack_stat * 2 - defense_stat) * base_damage / 20.0) + 5
	
	var variance: float = randf_range(0.9, 1.1)
	calculated_damage = int(calculated_damage * variance)
	
	var is_critical: bool = randf() < (0.1 + critical_rate_bonus)
	if is_critical:
		calculated_damage = int(calculated_damage * 1.5)
	
	return {
		"damage": maxi(calculated_damage, 1),
		"critical": is_critical
	}

# 判定状态效果触发
func _roll_status_effects() -> Array[Dictionary]:
	var triggered_effects: Array[Dictionary] = []
	
	for effect: Dictionary in effects:
		if effect.get("chance", 1.0) >= 1.0 or randf() < effect.get("chance", 0.0):
			triggered_effects.append(effect.duplicate(true))
	
	return triggered_effects

# 获取冷却剩余时间
func get_cooldown_remaining(combatant: Combatant) -> int:
	if not is_instance_valid(combatant):
		return 0
	
	var skill_key: String = skill_id if not skill_id.is_empty() else str(get_instance_id())
	
	if combatant.action_cooldowns.has(skill_key):
		return combatant.action_cooldowns[skill_key]
	
	return 0

# 获取技能图标路径
func get_icon_path() -> String:
	if not _icon_path.is_empty():
		return _icon_path
	return "res://assets/icons/skills/" + skill_id + ".png"

var _icon_path: String = ""

func set_icon_path(path: String) -> void:
	_icon_path = path

# 获取技能描述（带动态数据）
func get_formatted_description() -> String:
	var formatted: String = description
	
	formatted = formatted.replace("{damage}", str(damage))
	formatted = formatted.replace("{healing}", str(healing))
	formatted = formatted.replace("{mana_cost}", str(mana_cost))
	formatted = formatted.replace("{cooldown}", str(cooldown))
	formatted = formatted.replace("{accuracy}", str(int(accuracy * 100)) + "%")
	
	return formatted

# 获取目标类型描述
func get_target_type_description() -> String:
	match target_type:
		TargetType.SELF:
			return "自身"
		TargetType.SINGLE:
			return "单体"
		TargetType.ALL:
			return "全体"
	return "未知"

# 获取技能类型描述
func get_type_description() -> String:
	match type:
		SkillType.ATTACK:
			return "攻击"
		SkillType.HEAL:
			return "治疗"
		SkillType.BUFF:
			return "增益"
		SkillType.DEBUFF:
			return "减益"
	return "未知"

# 检查技能是否需要目标
func requires_target() -> bool:
	return target_type != TargetType.SELF

# 检查技能是否可指向自身
func can_target_self() -> bool:
	return target_type == TargetType.SELF

# 创建技能实例的工厂方法
static func create_attack_skill(
	p_skill_id: String,
	p_name: String,
	p_damage: int,
	p_mana_cost: int,
	p_target: TargetType = TargetType.SINGLE
) -> Skill:
	var skill: Skill = new()
	skill.skill_id = p_skill_id
	skill.name = p_name
	skill.type = SkillType.ATTACK
	skill.damage = p_damage
	skill.mana_cost = p_mana_cost
	skill.target_type = p_target
	return skill

static func create_healing_skill(
	p_skill_id: String,
	p_name: String,
	p_healing: int,
	p_mana_cost: int,
	p_target: TargetType = TargetType.SINGLE
) -> Skill:
	var skill: Skill = new()
	skill.skill_id = p_skill_id
	skill.name = p_name
	skill.type = SkillType.HEAL
	skill.healing = p_healing
	skill.mana_cost = p_mana_cost
	skill.target_type = p_target
	return skill

static func create_buff_skill(
	p_skill_id: String,
	p_name: String,
	p_effects: Array[Dictionary],
	p_mana_cost: int
) -> Skill:
	var skill: Skill = new()
	skill.skill_id = p_skill_id
	skill.name = p_name
	skill.type = SkillType.BUFF
	skill.effects = p_effects
	skill.mana_cost = p_mana_cost
	return skill

static func create_debuff_skill(
	p_skill_id: String,
	p_name: String,
	p_effects: Array[Dictionary],
	p_mana_cost: int,
	p_accuracy: float = 0.8
) -> Skill:
	var skill: Skill = new()
	skill.skill_id = p_skill_id
	skill.name = p_name
	skill.type = SkillType.DEBUFF
	skill.effects = p_effects
	skill.mana_cost = p_mana_cost
	skill.accuracy = p_accuracy
	return skill

# 克隆技能
func clone() -> Skill:
	var cloned: Skill = new()
	cloned.skill_id = skill_id
	cloned.name = name
	cloned.description = description
	cloned.type = type
	cloned.target_type = target_type
	cloned.damage = damage
	cloned.healing = healing
	cloned.mana_cost = mana_cost
	cloned.cooldown = cooldown
	cloned.accuracy = accuracy
	cloned.critical_rate_bonus = critical_rate_bonus
	cloned.effects = effects.duplicate(true)
	cloned.animation_name = animation_name
	cloned.vfx_scene = vfx_scene
	cloned.sound_effect = sound_effect
	cloned.min_range = min_range
	cloned.max_range = max_range
	cloned.required_weapon_type = required_weapon_type
	cloned.level_required = level_required
	cloned._icon_path = _icon_path
	return cloned
