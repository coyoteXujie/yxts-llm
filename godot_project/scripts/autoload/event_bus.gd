extends Node

signal mode_changed(mode: int)
signal player_changed(player: Dictionary)
signal inventory_changed(inventory: Dictionary)
signal quests_changed()
signal quest_completed(summary: Dictionary)
signal world_events_changed(events: Array)
signal time_changed(day: int, hour: float, weather: String)
signal region_changed(region: Dictionary, state: Dictionary)
signal map_target_changed(region_id: String)
signal game_loaded(snapshot: Dictionary)
signal game_ending(epilogue: String)
signal toast_requested(text: String)
signal dialogue_requested(npc: Dictionary)
signal combat_requested(enemy: Dictionary)
signal shop_requested(npc: Dictionary)
signal postfx_settings_changed(params: Dictionary)

func emit_toast(text: String) -> void:
	toast_requested.emit(text)

func emit_quest_completed(summary: Dictionary) -> void:
	quest_completed.emit(summary)

func emit_dialogue_requested(npc: Dictionary) -> void:
	dialogue_requested.emit(npc)

func emit_combat_requested(enemy: Dictionary) -> void:
	combat_requested.emit(enemy)

func emit_shop_requested(npc: Dictionary) -> void:
	shop_requested.emit(npc)
