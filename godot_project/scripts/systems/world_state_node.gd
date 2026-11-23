extends Node
class_name WorldStateNode

## 世界状态管理系统运行时节点 — 持久化 WorldState，连接 GameState 事件

var world_state  # WorldState — 动态类型避免 class_name 时序依赖

func _ready() -> void:
	world_state = WorldState.new(GameState)
	# 连接信号
	EventBus.quest_completed.connect(_on_quest_completed_ev)
	EventBus.time_changed.connect(_on_time_changed)

## 代理方法
func get_world_state() -> Node:
	return world_state

## 信号桥 — 任务完成事件
func _on_quest_completed_ev(summary: Dictionary) -> void:
	var quest_id := str(summary.get("quest_id", ""))
	if not quest_id.is_empty():
		world_state.on_quest_completed(quest_id)

## 信号桥 — 世界时钟变化
func _on_time_changed(day: int, hour: float, weather: String) -> void:
	# 当小时变化时触发世界时钟检查（由 main.gd 的 _process 中的 advance_time 驱动）
	pass  # 由 advance_world_clock 处理

## 从 GameState.advance_time 中调用的世界时钟推进
func advance_world_clock(hours_passed: float) -> void:
	world_state.advance_world_clock(hours_passed)

## 检查 NPC 是否在当前剧情阶段可见
func is_npc_visible(npc_name: String) -> bool:
	return world_state.is_npc_visible(npc_name)

## 获取区域描述（含剧情变更）
func get_region_description(region_id: String) -> String:
	return world_state.get_region_description(region_id)

## 获取区域当前氛围描述
func get_region_atmosphere(region_id: String) -> String:
	return world_state.get_region_atmosphere(region_id)

## 获取当前区域活跃 NPC 列表
func get_active_npcs_for_region(region_id: String) -> Array[Dictionary]:
	return world_state.get_active_npcs_for_region(region_id)

## 区域是否被封锁
func is_region_blocked(region_id: String) -> bool:
	return world_state.is_region_blocked(region_id)

## 设置区域封锁
func set_region_blocked(region_id: String, blocked: bool, reason: String = "") -> void:
	world_state.set_region_blocked(region_id, blocked, reason)

## 标记区域摧毁
func devastate_region(region_id: String, reason: String = "") -> void:
	world_state.devastate_region(region_id, reason)

## 修复区域
func restore_region(region_id: String, new_description: String = "") -> void:
	world_state.restore_region(region_id, new_description)

## 势力是否活跃
func is_faction_active(faction_id: String) -> bool:
	return world_state.is_faction_active(faction_id)

## 标记势力已灭
func destroy_faction(faction_id: String) -> void:
	world_state.destroy_faction(faction_id)
