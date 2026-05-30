extends Node
## 核心框架层 - 事件总线
## 所有模块通信的唯一通道，完全解耦！

signal player_level_up(new_level: int)
signal player_hp_changed(current: int, max: int)
signal player_mp_changed(current: int, max: int)
signal player_exp_changed(current: int, to_next: int)
signal player_gold_changed(amount: int)
signal player_faction_changed(faction: int, rank: int)

signal npc_interacted(npc_id: String)
signal npc_died(npc_id: String)
signal npc_spawned(npc_id: String)
signal npc_hostile_status_changed(npc_id: String, is_hostile: bool)

signal quest_accepted(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_progress_changed(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

signal item_picked_up(item_id: String, quantity: int)
signal item_consumed(item_id: String, quantity: int)
signal item_equipped(item_id: String, slot: int)
signal item_unequipped(item_id: String, slot: int)
signal item_sold(item_id: String, price: int, quantity: int)
signal item_bought(item_id: String, price: int, quantity: int)
signal inventory_changed()

signal skill_learned(skill_id: String)
signal skill_used(skill_id: String)
signal skill_cooldown_ended(skill_id: String)

signal combat_started()
signal combat_ended(victory: bool, rewards: Dictionary)
signal combat_turn_started(is_player_turn: bool)
signal combat_action_performed(data: Dictionary)
signal damage_dealt(target_id: String, amount: int, is_critical: bool)
signal healing_applied(target_id: String, amount: int)
signal status_effect_applied(target_id: String, effect: Dictionary)

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal dialogue_choice_made(choice_index: int, choice_text: String)
signal dialogue_variable_changed(name: String, value: Variant)

signal scene_loaded(scene_name: String)
signal scene_exited(scene_name: String)
signal zone_entered(zone_id: String)
signal zone_exited(zone_id: String)

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_failed(slot: int, error: String)

signal weather_changed(weather_type: int)
signal time_changed(time_of_day: int)
signal day_changed(day: int)

signal ui_panel_opened(panel_name: String)
signal ui_panel_closed(panel_name: String)
signal notification_shown(text: String, duration: float)
signal tooltip_shown(tooltip: Dictionary)
signal tooltip_hidden()

signal faction_reputation_changed(faction: int, old_rep: int, new_rep: int)
signal achievement_unlocked(achievement_id: String)
signal title_changed(new_title: String)

signal world_event_triggered(event_id: String, data: Dictionary)
signal special_encounter(encounter_type: String, data: Dictionary)
signal cutscene_started(cutscene_id: String)
signal cutscene_ended(cutscene_id: String)

signal game_state_changed(old_state: int, new_state: int)
signal game_paused()
signal game_resumed()
signal game_quit()

func emit_player_level_up(new_level: int) -> void:
	player_level_up.emit(new_level)

func emit_player_hp_changed(current: int, max: int) -> void:
	player_hp_changed.emit(current, max)

func emit_player_mp_changed(current: int, max: int) -> void:
	player_mp_changed.emit(current, max)

func emit_player_gold_changed(amount: int) -> void:
	player_gold_changed.emit(amount)

func emit_npc_interacted(npc_id: String) -> void:
	npc_interacted.emit(npc_id)

func emit_quest_accepted(quest_id: String) -> void:
	quest_accepted.emit(quest_id)

func emit_quest_updated(quest_id: String, objective_index: int) -> void:
	quest_updated.emit(quest_id, objective_index)

func emit_quest_completed(quest_id: String) -> void:
	quest_completed.emit(quest_id)

func emit_item_picked_up(item_id: String, quantity: int = 1) -> void:
	item_picked_up.emit(item_id, quantity)

func emit_combat_started() -> void:
	combat_started.emit()

func emit_combat_ended(victory: bool, rewards: Dictionary = {}) -> void:
	combat_ended.emit(victory, rewards)

func emit_dialogue_started(npc_id: String) -> void:
	dialogue_started.emit(npc_id)

func emit_dialogue_ended(npc_id: String) -> void:
	dialogue_ended.emit(npc_id)

func emit_zone_entered(zone_id: String) -> void:
	zone_entered.emit(zone_id)

func emit_ui_panel_opened(panel_name: String) -> void:
	ui_panel_opened.emit(panel_name)

func emit_ui_panel_closed(panel_name: String) -> void:
	ui_panel_closed.emit(panel_name)

func emit_notification(text: String, duration: float = 2.0) -> void:
	notification_shown.emit(text, duration)

func emit_game_state_changed(old_state: int, new_state: int) -> void:
	game_state_changed.emit(old_state, new_state)

func emit_game_paused() -> void:
	game_paused.emit()

func emit_game_resumed() -> void:
	game_resumed.emit()

func emit_dialogue_choice_made(choice_index: int, choice_text: String) -> void:
	dialogue_choice_made.emit(choice_index, choice_text)

func emit_skill_learned(skill_id: String) -> void:
	skill_learned.emit(skill_id)

func emit_item_equipped(item_id: String, slot: int) -> void:
	item_equipped.emit(item_id, slot)

func emit_game_quit() -> void:
	game_quit.emit()
