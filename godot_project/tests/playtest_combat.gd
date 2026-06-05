extends Node

const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")
const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")

var failures: Array[String] = []
var combat_result: Dictionary = {}

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameState.new_game({
		"name": "战斗测试",
		"gender": "male",
		"faction": "none"
	})
	_check(GameState.active_quests.has("q_intro_town"), "新游戏应自动追踪初始任务")
	_check(GameState.get_recent_world_events(1).size() == 1, "新游戏应写入初始江湖传闻")
	_check(not GameState.can_accept_quest("q_clear_thugs"), "镇东除恶应被初始任务前置卡住")
	GameState.progress_quest("talk", "平阿四", 1)
	GameState.progress_quest("talk", "捕快", 1)
	_check(GameState.completed_quests.has("q_intro_town"), "完成两次拜访后应完成初始任务")
	_check(GameState.can_accept_quest("q_clear_thugs"), "初始任务完成后应解锁镇东除恶")
	_check(GameState.get_world_event_summary(3).find("平安镇") >= 0, "完成初始任务后应更新江湖传闻")
	_check(GameData.get_npc_portrait_path("苏梦瑶").find("portraits_v2") >= 0, "苏梦瑶应使用新生成主线头像")
	_check(GameData.get_npc_portrait_path("陈天行").find("portraits_v2") >= 0, "陈天行应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("陈天行")), "陈天行新头像文件应存在")
	_check(GameData.get_npc_portrait_path("赵无极").find("portraits_v2") >= 0, "赵无极应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("赵无极")), "赵无极新头像文件应存在")
	_check(GameData.get_npc_portrait_path("花如玉").find("portraits_v2") >= 0, "花如玉应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("花如玉")), "花如玉新头像文件应存在")
	_check(GameData.get_npc_portrait_path("烈火").find("portraits_v2") >= 0, "烈火应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("烈火")), "烈火新头像文件应存在")
	_check(GameData.get_npc_portrait_path("蛇王").find("portraits_v2") >= 0, "蛇王应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("蛇王")), "蛇王新头像文件应存在")
	_check(GameData.get_npc_portrait_path("太极真人").find("portraits_v2") >= 0, "太极真人应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("太极真人")), "太极真人新头像文件应存在")
	_check(GameData.get_npc_portrait_path("冰魄").find("portraits_v2") >= 0, "冰魄应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("冰魄")), "冰魄新头像文件应存在")
	_check(GameData.get_npc_portrait_path("逍遥子").find("portraits_v2") >= 0, "逍遥子应使用新生成主线头像")
	_check(FileAccess.file_exists(GameData.get_npc_portrait_path("逍遥子")), "逍遥子新头像文件应存在")
	var qinghe := GameData.get_region("qinghe")
	GameState.update_current_region(qinghe, Vector2i(0, 0))
	var stage = COMBAT_STAGE_SCRIPT.new()
	stage.size = Vector2(682, 334)
	add_child(stage)
	stage.setup(GameData.get_npc_by_name("流氓"))
	_check(stage.player_texture != null, "2.5D 战斗舞台应加载玩家 sprite")
	_check(stage.enemy_texture != null, "2.5D 战斗舞台应加载敌人 sprite")
	_check(stage.background_texture != null, "2.5D 战斗舞台应加载当前区域背景")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 1, "kind": "damage", "target": "enemy"}]
	})
	_check(stage.event_timer > 0.0, "2.5D 战斗舞台应响应战斗事件")
	stage.queue_free()
	var director_line := LLMDirector.generate_npc_line(GameData.get_npc_by_name("苏梦瑶"), 0)
	_check(director_line.find("【") >= 0 and director_line.length() > 20, "LLMDirector 离线台词应包含世界上下文")
	_check(JSON.stringify(LLMDirector.build_prompt_messages(GameData.get_npc_by_name("苏梦瑶"))).find("recent_events") >= 0, "LLM prompt 应带最近江湖传闻")

	GameState.player["level"] = 3
	GameState.completed_quests.append("q_main_sect_warnings")
	_check(GameState.can_accept_quest("q_main_shadow_watchers"), "七派风声后应解锁暗影眼线")
	GameState.accept_quest("q_main_shadow_watchers")
	GameState.progress_quest("talk", "烈火", 1)
	GameState.progress_quest("talk", "蛇王", 1)
	GameState.progress_quest("kill", "黑衣大盗", 1)
	_check(GameState.completed_quests.has("q_main_shadow_watchers"), "暗影眼线应能完成")
	_check(GameState.get_world_event_summary(5).find("暗影眼线") >= 0, "主线完成后应写入暗影眼线传闻")
	_check("\n".join(GameState.get_quest_status_lines()).find("江湖传闻") >= 0, "任务日志应显示江湖传闻")
	_check(GameState.can_accept_quest("q_main_broken_token"), "暗影眼线后应解锁断令归卷")
	GameState.accept_quest("q_main_broken_token")
	GameState.progress_quest("talk", "苏梦瑶", 1)
	GameState.progress_quest("talk", "赵无极", 1)
	_check(GameState.completed_quests.has("q_main_broken_token"), "断令归卷应能完成")
	GameState.player["level"] = 4
	_check(GameState.can_accept_quest("q_main_wulin_conclave"), "断令归卷后应解锁武林夜议")

	GameState.player["attack"] = 42
	GameState.player["defense"] = 24
	GameState.player["hp"] = 220
	GameState.player["max_hp"] = 220
	GameState.player["mp"] = 160
	GameState.player["max_mp"] = 160
	GameState.learned_skills["kf_basic_blade"] = 4

	var combat = COMBAT_SYSTEM_SCRIPT.new()
	add_child(combat)
	combat.combat_finished.connect(func(result: Dictionary) -> void:
		combat_result = result
	)
	var enemy := {
		"id": -1,
		"name": "测试流氓",
		"npc_type": "enemy",
		"combat_style": "brute",
		"level": 3,
		"hp": 75,
		"max_hp": 75,
		"mp": 0,
		"max_mp": 0,
		"attack": 8,
		"defense": 3,
		"money": 7,
		"exp_reward": 12,
		"loot": [{"item": "item_baozi", "chance": 1.0}]
	}
	var before_baozi := int(GameState.inventory.get("item_baozi", 0))
	combat.start(enemy)
	for _i in range(12):
		if not combat.active:
			break
		var cooldowns: Dictionary = combat.snapshot().get("cooldowns", {})
		var action_id := "kf_basic_blade"
		if int(cooldowns.get(action_id, 0)) > 0 or int(GameState.player.get("mp", 0)) < 8:
			action_id = "normal"
		combat.player_attack(action_id)
		await get_tree().process_frame
	_check(not combat.active, "测试战斗应在 12 回合内结束")
	_check(bool(combat_result.get("victory", false)), "测试战斗应胜利")
	_check(int(GameState.inventory.get("item_baozi", 0)) == before_baozi + 1, "胜利后应结算敌人掉落")
	_check(GameState.mode == GameState.Mode.EXPLORE, "战斗结束后应回到探索模式")

	if failures.is_empty():
		print("PLAYTEST_COMBAT_OK")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
