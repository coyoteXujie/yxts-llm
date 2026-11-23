extends Node
class_name StorySystemNode

## 叙事引擎运行时节点 — 持久化 StorySystem，连接 GameState 事件

var story_system: StorySystem

func _ready() -> void:
	story_system = StorySystem.new(GameState)
	# 监听���键 GameState 事件
	EventBus.quest_completed.connect(_on_quest_completed_ev)
	EventBus.player_changed.connect(_on_player_changed)

## 代理方法 — 暴露 StorySystem 的核心接口
func get_story_system() -> StorySystem:
	return story_system

## 进入新区域时触发剧情
func on_region_enter(region_id: String) -> void:
	story_system.on_region_enter(region_id)

## 完成任务时触发剧情+世界变化
func on_quest_completed(quest_id: String) -> void:
	story_system.on_quest_completed(quest_id)
	# 检查章节自动推进
	_check_chapter_progression()

## 与 NPC 对话时触发
func on_npc_talk(npc_name: String) -> void:
	story_system.on_npc_talk(npc_name)

## 获得物品时触发
func on_item_obtained(item_id: String) -> void:
	story_system.on_item_obtained(item_id)

## 战斗胜利时触发
func on_battle_won(enemy_id: String) -> void:
	story_system.on_battle_won(enemy_id)

## 等级提升 → 检查章节推进
func on_level_up(new_level: int) -> void:
	_check_chapter_progression()

## 信号桥 — EventBus.quest_completed 携带 summary
func _on_quest_completed_ev(summary: Dictionary) -> void:
	var quest_id := str(summary.get("quest_id", ""))
	if not quest_id.is_empty():
		on_quest_completed(quest_id)

## 信号桥 — EventBus.player_changed 检查等级变化
var _last_known_level := 1
func _on_player_changed(player_data: Dictionary) -> void:
	var new_level := int(player_data.get("level", 1))
	if new_level > _last_known_level:
		on_level_up(new_level)
	_last_known_level = new_level

## 检查章节是否应当推进
func _check_chapter_progression() -> void:
	var current_chapter := story_system.get_current_active_chapter()
	if current_chapter.is_empty():
		return
	var cid := str(current_chapter.get("id", ""))
	if cid.is_empty():
		return
	# 检查当前章节是否已完成
	if story_system._is_chapter_completed(cid):
		return
	# 如果不是第一事件触发的章节，且游戏尚未推进到该章节，显示开场叙事
	var chapter_completed_flag := "chapter_%s_completed" % cid
	if not GameState.game_flags.get(chapter_completed_flag, false):
		# 仅当已有已完成章节时（即正在推进新章节）
		var completed_ids := story_system.get_completed_chapter_ids()
		if completed_ids.size() > 0:
			_show_chapter_transition(current_chapter)

## 显示章节过渡叙事
func _show_chapter_transition(chapter: Dictionary) -> void:
	var title := str(chapter.get("title", ""))
	var narrative := str(chapter.get("opening_narrative", ""))
	if narrative.is_empty():
		return
	# 使用叙事面板显示章节过渡（复用 opening_narrative_panel）
	var narrative_panel: Variant = PanelManager.get_panel("narrative")
	if narrative_panel != null and narrative_panel.has_method("show_chapter_transition"):
		narrative_panel.call("show_chapter_transition", title, narrative)
	elif narrative_panel != null and narrative_panel.has_method("show_panel"):
		# fallback：通过 toast 通知
		EventBus.emit_toast("━━━ %s ━━━" % title)
		EventBus.emit_toast(narrative.substr(0, 120) + "…")
