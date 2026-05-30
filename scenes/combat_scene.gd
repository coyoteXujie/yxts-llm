extends Node2D

var selected_enemy_id: String = ""
var is_waiting_input: bool = false

@onready var turn_info_label: Label = $CanvasLayer/TopBar/TurnInfo
@onready var player_hp_bar: ProgressBar = $CanvasLayer/PlayerArea/PlayerHPBar
@onready var player_name_label: Label = $CanvasLayer/PlayerArea/PlayerName
@onready var enemy_list_container: VBoxContainer = $CanvasLayer/EnemyArea/EnemyList
@onready var log_container: VBoxContainer = $CanvasLayer/LogPanel/LogScroll/LogVBox
@onready var attack_btn: Button = $CanvasLayer/ActionButtons/AttackBtn
@onready var skill_btn: Button = $CanvasLayer/ActionButtons/SkillBtn
@onready var item_btn: Button = $CanvasLayer/ActionButtons/ItemBtn
@onready var flee_btn: Button = $CanvasLayer/ActionButtons/FleeBtn
@onready var result_panel: Panel = $CanvasLayer/ResultPanel
@onready var result_title: Label = $CanvasLayer/ResultPanel/ResultVBox/ResultTitle
@onready var result_info: Label = $CanvasLayer/ResultPanel/ResultVBox/ResultInfo
@onready var result_btn: Button = $CanvasLayer/ResultPanel/ResultVBox/ResultBtn

func _ready() -> void:
	attack_btn.pressed.connect(_on_attack_pressed)
	skill_btn.pressed.connect(_on_skill_pressed)
	item_btn.pressed.connect(_on_item_pressed)
	flee_btn.pressed.connect(_on_flee_pressed)
	result_btn.pressed.connect(_on_result_pressed)
	
	CombatSystem.combat_started.connect(_on_combat_started)
	CombatSystem.combat_ended.connect(_on_combat_ended)
	CombatSystem.turn_changed.connect(_on_turn_changed)
	CombatSystem.combatant_hp_changed.connect(_on_combatant_hp_changed)

func start_demo_combat() -> void:
	var player_data := DataRegistry.get_player_data()
	var enemies := [
		{
			"id": "bandit_1",
			"name": "山贼头目",
			"level": 2,
			"max_hp": 60,
			"current_hp": 60,
			"attack": 12,
			"defense": 6,
			"speed": 8,
			"exp_reward": 80,
			"gold_reward": 35
		}
	]
	CombatSystem.start_combat(player_data, enemies)

func _on_combat_started() -> void:
	_update_ui()
	_clear_log()
	_add_log("战斗开始！")

func _on_combat_ended(victory: bool, rewards: Dictionary) -> void:
	_set_result(victory, rewards)
	if victory:
		RewardSystem.give_combat_rewards(rewards)

func _on_turn_changed(is_player_turn: bool) -> void:
	_update_ui()
	is_waiting_input = is_player_turn
	
	if is_player_turn:
		turn_info_label.text = "你的回合"
		_enable_actions(true)
	else:
		turn_info_label.text = "敌人回合"
		_enable_actions(false)

func _on_combatant_hp_changed(target_id: String, current: int, max_hp: int) -> void:
	_update_ui()
	
	if current <= 0:
		_add_log("%s 被击败了！" % _get_combatant_name(target_id))

func _on_attack_pressed() -> void:
	if not is_waiting_input:
		return
	_select_enemy_if_needed()
	if selected_enemy_id == "":
		return
	CombatSystem.player_attack(selected_enemy_id, "normal_attack")
	is_waiting_input = false

func _on_skill_pressed() -> void:
	if not is_waiting_input:
		return
	_select_enemy_if_needed()
	if selected_enemy_id == "":
		return
	CombatSystem.player_attack(selected_enemy_id, "power_strike")
	is_waiting_input = false

func _on_item_pressed() -> void:
	if not is_waiting_input:
		return
	CombatSystem.player_use_item("health_potion")
	is_waiting_input = false

func _on_flee_pressed() -> void:
	if not is_waiting_input:
		return
	CombatSystem.player_flee()
	is_waiting_input = false

func _on_result_pressed() -> void:
	GameSystem.change_game_state(Constants.GameState.PLAYING)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _select_enemy_if_needed() -> void:
	var enemies := CombatSystem.get_enemies()
	for enemy in enemies:
		if enemy.get("is_alive", false):
			selected_enemy_id = enemy.get("id", "enemy")
			break

func _get_combatant_name(id: String) -> String:
	if id == "player":
		return "玩家"
	var enemies := CombatSystem.get_enemies()
	for enemy in enemies:
		if enemy.get("id", "") == id:
			return enemy.get("name", "敌人")
	return "未知"

func _update_ui() -> void:
	var player := CombatSystem.get_player_combatant()
	if player:
		player_name_label.text = player.get("name", "玩家")
		player_hp_bar.max_value = player.get("max_hp", 100)
		player_hp_bar.value = player.get("current_hp", 100)
	
	_update_enemy_list()
	_update_log()

func _update_enemy_list() -> void:
	for child in enemy_list_container.get_children():
		child.queue_free()
	
	var enemies := CombatSystem.get_enemies()
	for enemy in enemies:
		var enemy_btn := Button.new()
		enemy_btn.text = "%s (%d/%d HP)" % [enemy.get("name", "敌人"), enemy.get("current_hp", 50), enemy.get("max_hp", 50)]
		enemy_btn.disabled = not enemy.get("is_alive", false)
		enemy_btn.pressed.connect(func(enemy_id=enemy.get("id", "")):
			selected_enemy_id = enemy_id)
		enemy_list_container.add_child(enemy_btn)

func _update_log() -> void:
	var log := CombatSystem.get_combat_log()
	_clear_log()
	for text in log:
		_add_log(text)

func _clear_log() -> void:
	for child in log_container.get_children():
		child.queue_free()

func _add_log(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.theme_override_colors.font_color = Color(0.9, 0.85, 0.75)
	log_container.add_child(label)

func _enable_actions(enabled: bool) -> void:
	attack_btn.disabled = not enabled
	skill_btn.disabled = not enabled
	item_btn.disabled = not enabled
	flee_btn.disabled = not enabled

func _set_result(victory: bool, rewards: Dictionary) -> void:
	result_panel.visible = true
	
	if victory:
		result_title.text = "胜利！"
		var exp := rewards.get("exp", 0)
		var gold := rewards.get("gold", 0)
		var items := rewards.get("items", [])
		result_info.text = "获得：%d 经验，%d 银两" % [exp, gold]
		if items.size() > 0:
			result_info.text += "\n物品：%s" % String(", ".join(items))
	else:
		result_title.text = "失败..."
		result_info.text = "你被击败了，下次再来吧！"
	
	_enable_actions(false)
