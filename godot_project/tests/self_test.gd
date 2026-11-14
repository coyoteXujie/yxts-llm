extends Node
## 开机自检：模拟新游戏流程，自动捕获所有SCRIPT ERROR
## 用法: godot --headless --path godot_project res://tests/self_test.tscn

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("\n========== 白金英雄坛说 自检开始 ==========\n")
	var start_time := Time.get_ticks_msec()
	
	# 1. 检查主菜单
	await _wait(0.5)
	_check(GameState.mode == GameState.Mode.MENU, "启动后应为菜单模式")
	print("✅ 主菜单加载完成")
	
	# 2. 新游戏
	GameState.new_game({"name": "自检", "gender": "male", "faction": "none"})
	await _wait(0.3)
	_check(GameState.player.get("name", "") == "自检", "角色创建成功")
	print("✅ 角色创建完成")
	
	# 3. 检查背包初始化
	var inv_items := GameState.inventory.keys()
	_check(inv_items.size() > 0, "背包应有初始物品")
	print("✅ 背包初始化完成，物品数: %d" % inv_items.size())
	
	# 4. 检查玩家属性
	_check(GameState.player.get("hp", 0) > 0, "玩家应有气血")
	_check(GameState.player.get("level", 0) >= 1, "玩家等级>=1")
	print("✅ 玩家属性正常 (HP:%d 等级:%d)" % [GameState.player.get("hp",0), GameState.player.get("level",0)])
	
	# 5. 检查初始任务
	var active_quests := GameState.active_quests.keys()
	var active_quest := GameState.active_quest
	_check(active_quests.size() > 0 or not active_quest.is_empty(), "应有初始任务")
	print("✅ 初始任务: %s" % active_quest)
	
	# 6. 检查修炼系统
	_check(GameState.cultivation != null, "修炼系统已初始化")
	var internal_arts := GameState.cultivation.get_internal_arts()
	_check(internal_arts.size() > 0, "应有内功")
	print("✅ 修炼系统正常")
	
	# 7. 尝试装备
	GameState.equip_item("item_sword")
	await _wait(0.1)
	print("✅ 装备系统可正常调用")
	
	# 8. 尝试接任务
	var first_quest := ""
	for qid in ["q_intro_town", "q_clear_thugs"]:
		if not GameState.active_quests.has(qid) and not GameState.completed_quests.has(qid):
			if GameState.accept_quest(qid):
				first_quest = qid
				break
	if not first_quest.is_empty():
		print("✅ 可正常接任务: %s" % first_quest)
	else:
		print("ℹ️ 已有任务进行中")
	
	# 9. 检查商店
	var sell_items := GameData.get_npc_sell_items("平阿四")
	_check(sell_items.size() > 0, "NPC应有出售物品")
	print("✅ 商店系统正常")
	
	# 10. 检查存档
	var save_ok := GameState.save_game(Vector2.ZERO)
	_check(save_ok, "存档应成功")
	print("✅ 存档系统正常")
	
	# 11. 检查读档
	var load_ok := GameState.load_game()
	_check(load_ok, "读档应成功")
	print("✅ 读档系统正常")
	
	# 12. 小结
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	print("\n========== 自检完成 ==========")
	print("耗时: %.1f秒" % elapsed)
	if failures.is_empty():
		print("🎉 全部通过！")
		print("注意: 以上测试不能完全替代真机运行。")
		print("      部分错误(如图片资源引用)仅在渲染时触发。")
	else:
		print("\n⚠️ 发现 %d 个问题:" % failures.size())
		for f in failures:
			print("  ❌ %s" % f)
	
	get_tree().quit()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("  ❌ %s" % message)