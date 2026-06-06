extends Node

const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/systems/combat_system.gd")
const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")
const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const DIALOGUE_PANEL_SCRIPT := preload("res://scripts/ui/dialogue_panel.gd")
const QUEST_PANEL_SCRIPT := preload("res://scripts/ui/quest_panel.gd")

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
	var event_count_before_pulse := GameState.get_recent_world_events(30).size()
	GameState.advance_hours(16.5)
	_check(GameState.day == 2, "跨天推进应进入第二日")
	var pulse_events_json := JSON.stringify(GameState.get_recent_world_events(8))
	_check(GameState.get_recent_world_events(30).size() > event_count_before_pulse, "跨天应生成每日江湖风声")
	_check(pulse_events_json.find("world_pulse") >= 0, "每日江湖风声应标记为 world_pulse")
	var rumor_reached_npc := false
	for npc_name in ["苏梦瑶", "陈天行", "赵无极", "玄机子", "花如玉", "烈火", "蛇王", "太极真人", "冰魄", "逍遥子"]:
		if JSON.stringify(GameState.get_npc_memory(str(npc_name))).find("听闻") >= 0:
			rumor_reached_npc = true
			break
	_check(rumor_reached_npc, "每日江湖风声应写入部分核心 NPC 记忆")
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
	_run_faction_questline_checks()
	GameState.new_game({
		"name": "战斗测试",
		"gender": "male",
		"faction": "none"
	})
	var qinghe := GameData.get_region("qinghe")
	GameState.update_current_region(qinghe, Vector2i(0, 0))
	var stage = COMBAT_STAGE_SCRIPT.new()
	stage.size = Vector2(682, 334)
	add_child(stage)
	stage.setup(GameData.get_npc_by_name("流氓"))
	_check(stage.player_texture != null, "2.5D 战斗舞台应加载玩家 sprite")
	_check(stage.enemy_texture != null, "2.5D 战斗舞台应加载敌人 sprite")
	_check(stage.background_texture != null, "2.5D 战斗舞台应加载当前区域背景")
	_check(COMBAT_STAGE_SCRIPT.PLAYER_STAGE_HEIGHT >= 140.0, "2.5D 战斗舞台玩家不应继续偏小")
	_check(COMBAT_STAGE_SCRIPT.ENEMY_STAGE_HEIGHT >= 148.0, "2.5D 战斗舞台敌人不应继续偏小")
	_check(COMBAT_STAGE_SCRIPT.ACTOR_AFTERIMAGE_ALPHA > 0.16, "2.5D 战斗舞台应保留出招残影")
	_check(COMBAT_STAGE_SCRIPT.CONTACT_GLOW_ALPHA > 0.12, "2.5D 战斗舞台应保留脚下接触光")
	_check(COMBAT_STAGE_SCRIPT.HIT_SHAKE_PIXELS >= 5.0, "2.5D 战斗舞台命中应保留屏幕震动强度")
	_check(COMBAT_STAGE_SCRIPT.IMPACT_SPEED_LINE_COUNT >= 8, "2.5D 战斗舞台命中应绘制速度线")
	_check(COMBAT_STAGE_SCRIPT.GROUND_CRACK_COUNT >= 5, "2.5D 战斗舞台重击应绘制地面裂纹")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 1, "kind": "damage", "target": "enemy", "source": "普通攻击", "amount": 10}]
	})
	_check(stage.event_timer > 0.0, "2.5D 战斗舞台应响应战斗事件")
	_check(stage.effect_style == "impact", "普通攻击应使用基础命中特效")
	_check(stage.event_shake_strength >= COMBAT_STAGE_SCRIPT.HIT_SHAKE_PIXELS, "伤害事件应触发命中震动")
	stage.event_timer = COMBAT_STAGE_SCRIPT.COMBAT_EVENT_DURATION * 0.5
	_check(stage._hit_freeze_alpha() > 0.80, "伤害事件命中点应产生短暂停顿强调")
	_check(stage._stage_shake_offset().length() > 0.0, "伤害事件命中点应产生舞台偏移")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 2, "kind": "damage", "target": "enemy", "source": "雪山剑法", "amount": 28}]
	})
	_check(stage.effect_style == "ice", "雪山剑法应触发冰雪剑气特效")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 3, "kind": "damage", "target": "enemy", "source": "天山六阳掌", "amount": 36}]
	})
	_check(stage.effect_style == "fire", "天山六阳掌应触发火焰掌风特效")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 4, "kind": "damage", "target": "enemy", "source": "忍术", "amount": 18}]
	})
	_check(stage.effect_style == "poison", "忍术应触发毒雾特效")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 5, "kind": "damage", "target": "enemy", "source": "八卦刀", "amount": 24}]
	})
	_check(stage.effect_style == "blade", "八卦刀应触发刀光特效")
	stage.update_snapshot({
		"enemy": GameData.get_npc_by_name("流氓"),
		"events": [{"id": 6, "kind": "heal", "target": "enemy", "source": "回气", "amount": 12}]
	})
	_check(stage.event_shake_strength == 0.0, "治疗/回气事件不应触发命中震动")
	stage.queue_free()
	var director_line := LLMDirector.generate_npc_line(GameData.get_npc_by_name("苏梦瑶"), 0)
	_check(director_line.find("【") >= 0 and director_line.length() > 20, "LLMDirector 离线台词应包含世界上下文")
	_check(JSON.stringify(LLMDirector.build_prompt_messages(GameData.get_npc_by_name("苏梦瑶"))).find("recent_events") >= 0, "LLM prompt 应带最近江湖传闻")
	var dialogue_panel = DIALOGUE_PANEL_SCRIPT.new()
	add_child(dialogue_panel)
	dialogue_panel.show_npc(GameData.get_npc_by_name("苏梦瑶"))
	_check(dialogue_panel.relation_label.text.length() > 2, "对话面板应显示 NPC 关系摘要")
	_check(dialogue_panel.memory_label.text.find("第") >= 0, "对话面板应显示 NPC 近期记忆")
	_check(dialogue_panel.rumor_label.text.length() > 4, "对话面板应显示江湖风声")
	dialogue_panel.queue_free()
	var quest_panel = QUEST_PANEL_SCRIPT.new()
	add_child(quest_panel)
	quest_panel.show_panel()
	_check(quest_panel.tabs.get_tab_count() == 3, "任务日志应有任务/江湖/人物三页")
	_check(quest_panel.rumor_text.text.find("江湖风声") >= 0, "任务日志江湖页应显示传闻")
	_check(quest_panel.relation_text.text.find("苏梦瑶") >= 0 and quest_panel.relation_text.text.find("人物关系") >= 0, "任务日志人物页应显示核心 NPC 关系")
	quest_panel.queue_free()
	var ambient_line := LLMDirector.generate_ambient_npc_line(GameData.get_npc_by_name("蛇王"), 80.0, true)
	_check(ambient_line.length() > 6 and ambient_line.find("【") < 0, "地图 NPC 气泡应生成短环境台词")
	var npc_actor = NPC_SCRIPT.new()
	add_child(npc_actor)
	npc_actor.setup(GameData.get_npc_by_name("蛇王"), GameData.TILE_SIZE)
	npc_actor.show_ambient_line(ambient_line, 1.0)
	_check(npc_actor.has_active_ambient_line(), "NPC 应能显示地图环境气泡")
	npc_actor.clear_ambient_line()
	_check(not npc_actor.has_active_ambient_line(), "NPC 应能清除地图环境气泡")
	npc_actor.queue_free()

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

func _run_faction_questline_checks() -> void:
	var lines := [
		{"faction": "bagua", "entry": "q_bagua_entry", "entry_skill": "kf_bagua_blade", "quests": ["q_bagua_entry", "q_bagua_patrol", "q_bagua_array_trial"], "final_skill": "kf_hunyuan"},
		{"faction": "flower", "entry": "q_flower_entry", "entry_skill": "kf_huafei", "quests": ["q_flower_entry", "q_flower_whispers", "q_flower_thief_trace"], "final_skill": "kf_sanhua"},
		{"faction": "honglian", "entry": "q_honglian_entry", "entry_skill": "kf_hexiang", "quests": ["q_honglian_entry", "q_honglian_embers", "q_honglian_oath"], "final_skill": "kf_tongji"},
		{"faction": "naja", "entry": "q_naja_entry", "entry_skill": "kf_renshu", "quests": ["q_naja_entry", "q_naja_scout", "q_naja_shadow"], "final_skill": "kf_yidao"},
		{"faction": "taiji", "entry": "q_taiji_entry", "entry_skill": "kf_taiji_sword", "quests": ["q_taiji_entry", "q_taiji_medicine", "q_taiji_balance"], "final_skill": "kf_xuanxu"},
		{"faction": "xueshan", "entry": "q_xueshan_entry", "entry_skill": "kf_taxue", "quests": ["q_xueshan_entry", "q_xueshan_patrol", "q_xueshan_ice"], "final_skill": "kf_xueying"},
		{"faction": "xiaoyao", "entry": "q_xiaoyao_entry", "entry_skill": "kf_xiaoyao_you", "quests": ["q_xiaoyao_entry", "q_xiaoyao_old_route", "q_xiaoyao_beiming"], "final_skill": "kf_xiaowuxiang"}
	]
	GameState.new_game({"name": "门派限制测试", "gender": "male", "faction": "none"})
	_check(not GameState.can_accept_quest("q_flower_entry"), "未拜入门派不应接花间入门任务")
	for line in lines:
		var faction_id := str(line.get("faction", "none"))
		GameState.new_game({"name": "门派任务测试", "gender": "male", "faction": faction_id})
		GameState.player["level"] = 8
		_check(GameState.can_accept_quest(str(line.get("entry", ""))), "%s 入门任务应可接" % GameData.get_faction_name(faction_id))
		for quest_id_value in line.get("quests", []):
			var quest_id := str(quest_id_value)
			_check(GameState.accept_quest(quest_id), "应能接取门派任务 %s" % quest_id)
			_fulfill_quest_objectives(quest_id)
			_check(GameState.completed_quests.has(quest_id), "门派任务应能完成 %s" % quest_id)
		_check(int(GameState.learned_skills.get(str(line.get("entry_skill", "")), 0)) >= 2, "%s 入门武学应练到 2 级" % GameData.get_faction_name(faction_id))
		_check(int(GameState.learned_skills.get(str(line.get("final_skill", "")), 0)) >= 1, "%s 任务线应奖励最终武学" % GameData.get_faction_name(faction_id))

func _fulfill_quest_objectives(quest_id: String) -> void:
	var quest := GameData.get_quest(quest_id)
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var kind := str(objective.get("type", ""))
		var target := str(objective.get("target", ""))
		var required := int(objective.get("count", 1))
		if kind == "skill":
			var current := int(GameState.learned_skills.get(target, 0))
			if current < required:
				GameState.learn_skill(target, required - current)
		elif kind == "collect":
			GameState.add_item(target, required)
		else:
			GameState.progress_quest(kind, target, required)
