extends Control
class_name SkillPanel

signal skill_learned(skill: Dictionary)
signal skill_assigned(skill: Dictionary, slot_index: int)
signal skill_upgraded(skill: Dictionary)
signal skill_unlocked(skill: Dictionary)
signal skill_points_changed(points: int)

@export var main_skill_slots: int = 4
@export var skill_tree_columns: int = 3

@onready var main_slots_container: HBoxContainer = $Panel/MainSlotsContainer
@onready var skill_tree_container: ScrollContainer = $Panel/SkillTreeScroll/SkillTreeGrid
@onready var skill_points_label: Label = $Panel/SkillPointsLabel
@onready var skill_info_panel: PanelContainer = $SkillInfoPanel
@onready var skill_name_label: Label = $SkillInfoPanel/SkillName
@onready var skill_desc_label: Label = $SkillInfoPanel/SkillDescription
@onready var skill_cost_label: Label = $SkillInfoPanel/SkillCost

var assigned_slots: Array[int] = [-1, -1, -1, -1]
var learned_skills: Array[Dictionary] = []
var unlocked_skill_ids: Array[String] = []
var available_skill_points: int = 0
var is_open: bool = false
var current_selected_skill: Dictionary = {}

var skill_tree_by_faction: Dictionary = {}
var all_skills: Array[Dictionary] = []

func _ready() -> void:
    _initialize_skills()
    _setup_main_skill_slots()
    _setup_skill_tree()
    hide()

func _initialize_skills() -> void:
    _create_skill_trees()
    _populate_skill_tree()

func _create_skill_trees() -> void:
    var martial_skills: Array[Dictionary] = [
        {
            "id": "basic_attack",
            "name": "基础攻击",
            "description": "最基本的物理攻击技能",
            "cost": 0,
            "faction": "martial",
            "level_required": 1,
            "icon": null,
            "cooldown": 0.5,
            "damage": 10
        },
        {
            "id": "power_strike",
            "name": "强力打击",
            "description": "造成150%伤害的重击",
            "cost": 1,
            "faction": "martial",
            "level_required": 3,
            "requires": ["basic_attack"],
            "icon": null,
            "cooldown": 2.0,
            "damage": 25
        },
        {
            "id": "whirlwind",
            "name": "旋风斩",
            "description": "对周围所有敌人造成伤害",
            "cost": 2,
            "faction": "martial",
            "level_required": 5,
            "requires": ["power_strike"],
            "icon": null,
            "cooldown": 5.0,
            "damage": 40
        },
        {
            "id": "shield_bash",
            "name": "盾击",
            "description": "用盾牌击晕敌人",
            "cost": 1,
            "faction": "martial",
            "level_required": 2,
            "requires": [],
            "icon": null,
            "cooldown": 3.0,
            "stun_duration": 1.0
        }
    ]
    
    var mystic_skills: Array[Dictionary] = [
        {
            "id": "magic_missile",
            "name": "魔法飞弹",
            "description": "发射一枚魔法飞弹攻击敌人",
            "cost": 0,
            "faction": "mystic",
            "level_required": 1,
            "icon": null,
            "cooldown": 1.0,
            "damage": 8
        },
        {
            "id": "fireball",
            "name": "火球术",
            "description": "投掷一个爆炸的火球",
            "cost": 2,
            "faction": "mystic",
            "level_required": 4,
            "requires": ["magic_missile"],
            "icon": null,
            "cooldown": 4.0,
            "damage": 35
        },
        {
            "id": "ice_shard",
            "name": "冰刺术",
            "description": "发射冰刺攻击并减速敌人",
            "cost": 1,
            "faction": "mystic",
            "level_required": 3,
            "requires": ["magic_missile"],
            "icon": null,
            "cooldown": 2.5,
            "damage": 15,
            "slow_duration": 2.0
        },
        {
            "id": "lightning",
            "name": "雷电术",
            "description": "召唤雷电攻击",
            "cost": 3,
            "faction": "mystic",
            "level_required": 6,
            "requires": ["fireball"],
            "icon": null,
            "cooldown": 6.0,
            "damage": 60
        }
    ]
    
    var spiritual_skills: Array[Dictionary] = [
        {
            "id": "heal",
            "name": "治疗术",
            "description": "恢复自身或队友的生命值",
            "cost": 1,
            "faction": "spiritual",
            "level_required": 1,
            "icon": null,
            "cooldown": 3.0,
            "heal_amount": 30
        },
        {
            "id": "shield",
            "name": "护盾",
            "description": "为目标施加保护护盾",
            "cost": 2,
            "faction": "spiritual",
            "level_required": 3,
            "requires": ["heal"],
            "icon": null,
            "cooldown": 5.0,
            "shield_amount": 50
        },
        {
            "id": "purify",
            "name": "净化",
            "description": "移除目标身上的负面状态",
            "cost": 1,
            "faction": "spiritual",
            "level_required": 2,
            "requires": [],
            "icon": null,
            "cooldown": 4.0
        },
        {
            "id": "resurrection",
            "name": "复活",
            "description": "复活死亡的队友",
            "cost": 5,
            "faction": "spiritual",
            "level_required": 8,
            "requires": ["shield", "heal"],
            "icon": null,
            "cooldown": 30.0
        }
    ]
    
    skill_tree_by_faction = {
        "martial": martial_skills,
        "mystic": mystic_skills,
        "spiritual": spiritual_skills
    }
    
    for faction_skills in skill_tree_by_faction.values():
        all_skills.append_array(faction_skills)

func _setup_main_skill_slots() -> void:
    if main_slots_container:
        for i in main_skill_slots:
            var slot := _create_skill_slot(i)
            main_slots_container.add_child(slot)

func _setup_skill_tree() -> void:
    if skill_tree_container:
        var grid := GridContainer.new()
        grid.columns = skill_tree_columns
        skill_tree_container.add_child(grid)

func _create_skill_slot(slot_index: int) -> Control:
    var slot := PanelContainer.new()
    slot.custom_minimum_size = Vector2(80, 80)
    slot.set_meta("slot_index", slot_index)
    slot.set_meta("assigned_skill", {})
    
    var slot_number := Label.new()
    slot_number.text = str(slot_index + 1)
    slot_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    slot_number.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    slot_number.add_theme_color_override("font_color", Color.YELLOW)
    slot.add_child(slot_number)
    
    var skill_icon := TextureRect.new()
    skill_icon.visible = false
    skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    skill_icon.custom_minimum_size = Vector2(64, 64)
    slot.add_child(skill_icon)
    slot.set_meta("skill_icon", skill_icon)
    
    slot.gui_input.connect(_on_main_slot_input.bind(slot_index))
    
    return slot

func open() -> void:
    is_open = true
    show()
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)
    _update_skill_points_display()

func close() -> void:
    is_open = false
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    await tween.finished
    hide()

func learn_skill(skill_id: String) -> bool:
    if available_skill_points <= 0:
        push_warning("没有足够的技能点")
        return false
    
    var skill := _find_skill_by_id(skill_id)
    if skill.is_empty():
        push_warning("技能不存在: " + skill_id)
        return false
    
    if unlocked_skill_ids.has(skill_id):
        push_warning("技能已经学习过了")
        return false
    
    if not _can_learn_skill(skill):
        push_warning("无法学习该技能,前置条件未满足")
        return false
    
    var cost: int = skill.get("cost", 1)
    if available_skill_points < cost:
        push_warning("技能点不足,需要 %d 点" % cost)
        return false
    
    available_skill_points -= cost
    unlocked_skill_ids.append(skill_id)
    learned_skills.append(skill)
    
    _update_skill_points_display()
    _refresh_skill_tree()
    skill_learned.emit(skill)
    print("学会技能: " + skill["name"])
    
    return true

func assign_skill_slot(skill_id: String, slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= main_skill_slots:
        push_warning("无效的技能槽位索引")
        return false
    
    if not unlocked_skill_ids.has(skill_id):
        push_warning("尚未学习该技能")
        return false
    
    var skill := _find_skill_by_id(skill_id)
    if skill.is_empty():
        return false
    
    assigned_slots[slot_index] = _get_skill_index(skill_id)
    _refresh_main_slots()
    skill_assigned.emit(skill, slot_index)
    print("分配技能到槽位 %d: %s" % [slot_index, skill["name"]])
    
    return true

func upgrade_skill(skill_id: String) -> bool:
    var skill := _find_skill_by_id(skill_id)
    if skill.is_empty():
        return false
    
    if not learned_skills.has(skill):
        push_warning("尚未学习该技能")
        return false
    
    if available_skill_points <= 0:
        push_warning("没有足够的技能点进行升级")
        return false
    
    var upgrade_cost: int = skill.get("cost", 1)
    if available_skill_points < upgrade_cost:
        push_warning("技能点不足")
        return false
    
    available_skill_points -= upgrade_cost
    
    var current_level: int = skill.get("level", 1)
    skill["level"] = current_level + 1
    
    _update_skill_points_display()
    skill_upgraded.emit(skill)
    print("升级技能: " + skill["name"] + " (等级 %d)" % skill["level"])
    
    return true

func add_skill_points(points: int) -> void:
    available_skill_points += points
    _update_skill_points_display()
    skill_points_changed.emit(available_skill_points)
    print("获得 %d 技能点" % points)

func _find_skill_by_id(skill_id: String) -> Dictionary:
    for skill in all_skills:
        if skill["id"] == skill_id:
            return skill
    return {}

func _get_skill_index(skill_id: String) -> int:
    for i in all_skills.size():
        if all_skills[i]["id"] == skill_id:
            return i
    return -1

func _can_learn_skill(skill: Dictionary) -> bool:
    if skill.has("requires"):
        var requires: Array = skill["requires"]
        for req_skill_id in requires:
            if not unlocked_skill_ids.has(req_skill_id):
                return false
    
    if skill.has("level_required"):
        var required_level: int = skill["level_required"]
        var player_level: int = _get_player_level()
        if player_level < required_level:
            return false
    
    return true

func _get_player_level() -> int:
    return 1

func _update_skill_points_display() -> void:
    if skill_points_label:
        skill_points_label.text = "技能点: %d" % available_skill_points

func _populate_skill_tree() -> void:
    if not skill_tree_container:
        return
    
    for faction_name in skill_tree_by_faction.keys():
        var faction_panel := _create_faction_panel(faction_name, skill_tree_by_faction[faction_name])
        skill_tree_container.add_child(faction_panel)

func _create_faction_panel(faction_name: String, skills: Array[Dictionary]) -> VBoxContainer:
    var panel := VBoxContainer.new()
    
    var title := Label.new()
    title.text = _get_faction_display_name(faction_name)
    title.add_theme_color_override("font_color", Color.WHITE)
    panel.add_child(title)
    
    var grid := GridContainer.new()
    grid.columns = skill_tree_columns
    
    for skill in skills:
        var skill_button := _create_skill_button(skill)
        grid.add_child(skill_button)
    
    panel.add_child(grid)
    
    return panel

func _get_faction_display_name(faction: String) -> String:
    match faction:
        "martial": return "武技系"
        "mystic": return "秘法系"
        "spiritual": return "灵修系"
    return faction

func _create_skill_button(skill: Dictionary) -> Control:
    var button := Button.new()
    button.custom_minimum_size = Vector2(100, 100)
    button.text = skill["name"]
    button.set_meta("skill_id", skill["id"])
    button.set_meta("skill_data", skill)
    
    if unlocked_skill_ids.has(skill["id"]):
        button.add_theme_color_override("bg_color", Color.GREEN)
    elif _can_learn_skill(skill):
        button.add_theme_color_override("bg_color", Color.BLUE)
    else:
        button.add_theme_color_override("bg_color", Color.GRAY)
    
    button.pressed.connect(_on_skill_button_pressed.bind(skill))
    
    return button

func _refresh_skill_tree() -> void:
    for faction_panel in skill_tree_container.get_children():
        for child in faction_panel.get_children():
            if child is GridContainer:
                for skill_button in child.get_children():
                    if skill_button is Button:
                        var skill_id: String = skill_button.get_meta("skill_id")
                        var skill: Dictionary = skill_button.get_meta("skill_data")
                        
                        if unlocked_skill_ids.has(skill_id):
                            skill_button.add_theme_color_override("bg_color", Color.GREEN)
                            skill_button.disabled = false
                        elif _can_learn_skill(skill):
                            skill_button.add_theme_color_override("bg_color", Color.BLUE)
                            skill_button.disabled = false
                        else:
                            skill_button.add_theme_color_override("bg_color", Color.GRAY)
                            skill_button.disabled = true

func _refresh_main_slots() -> void:
    if not main_slots_container:
        return
    
    for i in main_slots_container.get_child_count():
        var slot: Control = main_slots_container.get_child(i)
        var skill_index: int = assigned_slots[i]
        
        if skill_index >= 0 and skill_index < all_skills.size():
            var skill: Dictionary = all_skills[skill_index]
            var skill_icon: TextureRect = slot.get_meta("skill_icon")
            if skill_icon:
                skill_icon.visible = true
                if skill.has("icon") and skill["icon"]:
                    skill_icon.texture = skill["icon"]
        else:
            var skill_icon: TextureRect = slot.get_meta("skill_icon")
            if skill_icon:
                skill_icon.visible = false

func _on_skill_button_pressed(skill: Dictionary) -> void:
    current_selected_skill = skill
    _show_skill_info(skill)

func _show_skill_info(skill: Dictionary) -> void:
    if skill_name_label:
        skill_name_label.text = skill["name"]
    
    if skill_desc_label:
        skill_desc_label.text = skill["description"]
    
    if skill_cost_label:
        var cost: int = skill.get("cost", 1)
        skill_cost_label.text = "消耗: %d 技能点" % cost
    
    if skill_info_panel:
        skill_info_panel.show()

func _on_main_slot_input(event: InputEvent, slot_index: int) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            if assigned_slots[slot_index] >= 0:
                assigned_slots[slot_index] = -1
                _refresh_main_slots()

func use_skill_in_slot(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= assigned_slots.size():
        return false
    
    var skill_index: int = assigned_slots[slot_index]
    if skill_index < 0 or skill_index >= all_skills.size():
        return false
    
    var skill: Dictionary = all_skills[skill_index]
    
    print("使用技能: " + skill["name"])
    
    if skill.has("damage"):
        print("造成伤害: " + str(skill["damage"]))
    
    if skill.has("heal_amount"):
        print("恢复生命: " + str(skill["heal_amount"]))
    
    return true

func get_assigned_skills() -> Array[Dictionary]:
    var skills: Array[Dictionary] = []
    for skill_index in assigned_slots:
        if skill_index >= 0 and skill_index < all_skills.size():
            skills.append(all_skills[skill_index])
        else:
            skills.append({})
    return skills

func get_learned_skills() -> Array[Dictionary]:
    return learned_skills.duplicate()

func get_unlocked_skill_count() -> int:
    return unlocked_skill_ids.size()

func get_available_skill_points() -> int:
    return available_skill_points

func reset_skill_tree() -> void:
    for i in assigned_slots.size():
        assigned_slots[i] = -1
    
    unlocked_skill_ids.clear()
    learned_skills.clear()
    
    _refresh_main_slots()
    _refresh_skill_tree()
    
    print("技能树已重置")
