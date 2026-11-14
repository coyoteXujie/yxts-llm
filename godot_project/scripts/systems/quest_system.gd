extends RefCounted
class_name QuestSystem

var _state: Node

func _init(state: Node) -> void:
	_state = state

func accept_quest(quest_id: String) -> bool:
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return false
	var block_reason := get_quest_block_reason(quest_id)
	if not block_reason.is_empty():
		EventBus.emit_toast(block_reason)
		return false
	_state.active_quests[quest_id] = {"progress": {}}
	_state.active_quest = str(quest.get("title", quest_id))
	_sync_existing_objective_progress(quest_id)
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(_state.player)
	EventBus.emit_toast("接到任务：%s" % _state.active_quest)
	_check_quest_completion(quest_id)
	return true

func _start_quest_silently(quest_id: String) -> void:
	if _state.active_quests.has(quest_id) or _state.completed_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return
	_state.active_quests[quest_id] = {"progress": {}}
	_state.active_quest = str(quest.get("title", quest_id))
	_sync_existing_objective_progress(quest_id)

func can_accept_quest(quest_id: String) -> bool:
	return get_quest_block_reason(quest_id).is_empty()

func get_quest_block_reason(quest_id: String) -> String:
	if quest_id.is_empty():
		return "任务不存在"
	if _state.active_quests.has(quest_id):
		return "任务已经在进行中"
	if _state.completed_quests.has(quest_id):
		return "任务已经完成"
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return "任务不存在"
	var min_level := int(quest.get("min_level", 0))
	if min_level > 0 and int(_state.player.get("level", 1)) < min_level:
		return "等级达到 %d 后再来" % min_level
	var required_faction := str(quest.get("required_faction", ""))
	if not required_faction.is_empty() and str(_state.player.get("faction", "none")) != required_faction:
		return "需先拜入%s" % GameData.get_faction_name(required_faction)
	var required_completed: Array = quest.get("requires_completed", [])
	for required_id in required_completed:
		var required_quest_id := str(required_id)
		if not _state.completed_quests.has(required_quest_id):
			var required_quest := GameData.get_quest(required_quest_id)
			return "需先完成【%s】" % str(required_quest.get("title", required_quest_id))
	var required_flags: Array = quest.get("requires_flags", [])
	for flag in required_flags:
		if not bool(_state.game_flags.get(str(flag), false)):
			return "线索还不够"
	var min_daode := int(quest.get("min_daode", 0))
	if min_daode > 0 and int(_state.player.get("daode", 0)) < min_daode:
		return "正邪值需达到 %d" % min_daode
	var max_daode := int(quest.get("max_daode", 0))
	if max_daode < 0 and int(_state.player.get("daode", 0)) > max_daode:
		return "正邪值需降至 %d" % max_daode
	var daode := int(_state.player.get("daode", 0))
	var giver_name := str(quest.get("giver", ""))
	if not giver_name.is_empty():
		var giver_npc := GameData.get_npc_by_name(giver_name)
		if not giver_npc.is_empty():
			var giver_align: String = _state.get_faction_alignment(str(giver_npc.get("faction", "none")))
			if daode >= 50 and giver_align == "evil":
				return "正邪不两立，正派不接邪派委托"
			if daode <= -50 and giver_align == "good":
				return "正邪不两立，邪派不接正派委托"
	return ""

func progress_quest(kind: String, target: String, amount: int = 1) -> void:
	var changed := false
	for quest_id in _state.active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			if str(objective.get("type", "")) != kind:
				continue
			if str(objective.get("target", "")) != target:
				continue
			var key := _objective_key(objective)
			var progress: Dictionary = _state.active_quests[quest_id].get("progress", {})
			progress[key] = int(progress.get(key, 0)) + amount
			_state.active_quests[quest_id]["progress"] = progress
			changed = true
	if changed:
		var ids: Array = _state.active_quests.keys()
		for quest_id in ids:
			_check_quest_completion(str(quest_id))
		EventBus.quests_changed.emit()

func _sync_existing_objective_progress(quest_id: String) -> void:
	if not _state.active_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	var objectives: Array = quest.get("objectives", [])
	var progress: Dictionary = _state.active_quests[quest_id].get("progress", {})
	for objective in objectives:
		var key := _objective_key(objective)
		var kind := str(objective.get("type", ""))
		var target := str(objective.get("target", ""))
		if kind == "collect":
			progress[key] = int(_state.inventory.get(target, 0))
		elif kind == "skill":
			progress[key] = int(_state.learned_skills.get(target, 0))
	_state.active_quests[quest_id]["progress"] = progress

func sync_collect_objective_progress(item_id: String, check_completion: bool = true) -> void:
	var changed := false
	var ids_to_check: Array = []
	for quest_id in _state.active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		var objectives: Array = quest.get("objectives", [])
		for objective in objectives:
			if typeof(objective) != TYPE_DICTIONARY:
				continue
			if str(objective.get("type", "")) != "collect":
				continue
			if str(objective.get("target", "")) != item_id:
				continue
			var key := _objective_key(objective)
			var progress: Dictionary = _state.active_quests[quest_id].get("progress", {})
			var new_value: int = maxi(0, int(_state.inventory.get(item_id, 0)))
			if int(progress.get(key, 0)) == new_value:
				continue
			progress[key] = new_value
			_state.active_quests[quest_id]["progress"] = progress
			changed = true
			if check_completion and str(quest_id) not in ids_to_check:
				ids_to_check.append(str(quest_id))
	if not changed:
		return
	if check_completion:
		for quest_id in ids_to_check:
			_check_quest_completion(quest_id)
	EventBus.quests_changed.emit()

func _check_quest_completion(quest_id: String) -> void:
	if not _state.active_quests.has(quest_id):
		return
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return
	var progress: Dictionary = _state.active_quests[quest_id].get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var key := _objective_key(objective)
		var required := int(objective.get("count", 1))
		if int(progress.get(key, 0)) < required:
			return
	_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	var quest := GameData.get_quest(quest_id)
	_state.active_quests.erase(quest_id)
	_state.completed_quests.append(quest_id)
	var rewards: Dictionary = quest.get("rewards", {})
	_state.reward_player(int(rewards.get("exp", 0)), int(rewards.get("money", 0)))
	_state.change_daode(int(rewards.get("daode", 0)))
	var items: Dictionary = rewards.get("items", {})
	for item_id in items.keys():
		_state.add_item(str(item_id), int(items[item_id]))
	var skills: Dictionary = rewards.get("skills", {})
	for skill_id in skills.keys():
		_state.learn_skill(str(skill_id), int(skills[skill_id]))
	var quest_faction := str(quest.get("required_faction", ""))
	if not quest_faction.is_empty() and quest_faction != "none":
		_state.add_faction_reputation(quest_faction, 10)
	else:
		var giver_name := str(quest.get("giver", ""))
		if not giver_name.is_empty():
			var giver_npc := GameData.get_npc_by_name(giver_name)
			var giver_faction := str(giver_npc.get("faction", "none"))
			if not giver_faction.is_empty() and giver_faction != "none":
				_state.add_faction_reputation(giver_faction, 5)
	if not _state.active_quests.is_empty():
		var first_id := str(_state.active_quests.keys()[0])
		_state.active_quest = str(GameData.get_quest(first_id).get("title", first_id))
	else:
		_state.active_quest = str(quest.get("next_hint", "自由探索江湖"))
	_record_quest_world_event(quest_id, quest)
	EventBus.quests_changed.emit()
	EventBus.player_changed.emit(_state.player)
	EventBus.emit_toast("完成任务：%s" % str(quest.get("title", quest_id)))
	if quest_id == "q_hero_trial":
		_state.game_flags["alpha_clear"] = true
		_state.active_quest = "江湖初成"
		EventBus.player_changed.emit(_state.player)
		EventBus.emit_toast("阶段通关：江湖初成")
	EventBus.emit_quest_completed(_quest_completion_summary(quest_id, quest))
	if _state.EPILOGUE_QUEST_IDS.has(quest_id):
		_state.trigger_ending()

func _quest_completion_summary(quest_id: String, quest: Dictionary) -> Dictionary:
	var next_hint := str(quest.get("next_hint", _state.active_quest))
	if quest_id == "q_hero_trial":
		next_hint = _state.active_quest
	return {
		"quest_id": quest_id,
		"title": str(quest.get("title", quest_id)),
		"description": str(quest.get("description", "")),
		"reward_lines": get_quest_reward_lines(quest_id),
		"next_hint": next_hint,
		"region_id": _state.current_region_id,
		"region_name": _state.current_region_name,
		"active_quest": _state.active_quest
	}

func _record_quest_world_event(quest_id: String, quest: Dictionary) -> void:
	var quest_title := str(quest.get("title", quest_id))
	match quest_id:
		"q_intro_town":
			_state.append_world_event("quest", "平安镇有人问路", "客栈与衙门都记住了你的名字，镇东的麻烦开始浮出水面。", "qinghe", 2)
		"q_clear_thugs":
			_state.append_world_event("quest", "镇东恶徒受挫", "平安镇东路清静了些，但余党背后的线仍未断。", "qinghe", 3)
		"q_flower_thief":
			_state.append_world_event("quest", "采花大盗伏诛", "镇上传开消息，说有少侠追上了轻功了得的采花大盗。", "qinghe", 3)
		"q_hero_trial":
			_state.append_world_event("story", "江湖初成", "神秘人败退，洛阳旧案和暗影司的名字开始连在一起。", "luoyang", 4)
		"q_main_choose_path":
			_state.append_world_event("story", "择路江湖", "大侠指点你择一门派拜入，江湖的路开始有了方向。", "changan", 3)
		"q_main_faction_oath":
			_state.append_world_event("story", "门庭初定", "你已拜入门派，门中前辈嘱咐你先磨练基本功法，再出山追查洛阳旧案。", "changan", 3)
		"q_main_luoyang_ashes":
			_state.append_world_event("story", "洛阳旧火重燃", "苏家旧案重新被人提起，武林盟旧卷也不再安静。", "luoyang", 4)
		"q_main_shadow_letters":
			_state.append_world_event("story", "暗影书信现世", "两封密信牵出七派暗号，山门之间的信任有了裂纹。", "changan", 4)
		"q_main_sect_warnings":
			_state.append_world_event("story", "七派风声渐紧", "太极、雪山、逍遥都听见了暗影司的脚步，夜路开始不太平。", "wudang", 4)
		"q_main_shadow_watchers":
			_state.append_world_event("story", "暗影眼线暴露", "黑衣大盗带着半截密令败退，暗影司藏在路上的眼睛少了一只。", "changan", 4)
		"q_main_broken_token":
			_state.append_world_event("story", "断令归卷", "断令花纹与武林盟旧卷对上，七派夜议已有了真正的证据。", "luoyang", 4)
		"q_main_wulin_conclave":
			var conclave_detail := "七派可信之人开始合拢证据，暗影司幕后主使不再只是传闻。"
			if bool(_state.game_flags.get("story_conclave_public", false)):
				conclave_detail = "你先公开断令取信七派，夜议成局后，暗影司也不得不从暗处露出破绽。"
			elif bool(_state.game_flags.get("story_conclave_secret", false)):
				conclave_detail = "你先暗查旧账稳住线人，夜议成局时，暗影司几条暗线已被悄悄拔掉。"
			_state.append_world_event("story", "武林夜议成局", conclave_detail, "wudang", 5)
		"q_main_hidden_master":
			_state.append_world_event("story", "血月残印现世", "血月使者败退，暗影司旧账里第一次露出无面主事的名字。", "changan", 5)
		"q_main_blood_moon":
			_state.append_world_event("story", "无面账册归卷", "无面君失手，苏家账册把暗影司总坛方位推到了七派眼前。", "luoyang", 5)
		"q_main_shadow_citadel":
			_state.append_world_event("story", "影司总坛暂破", "暗影司影主败退，总坛暗道被封，江湖各派终于有了短暂喘息。", "daba_mtn", 5)
		"q_main_after_shadow":
			_state.append_world_event("story", "总坛余烬未灭", "苏梦瑶、陈天行与花间暗线开始清点暗影司残部，苏家旧账终于能翻到最后几页。", "luoyang", 5)
		"q_main_old_case_closure":
			_state.append_world_event("story", "旧案终册落印", "武林盟与七派共同落印，苏家旧案暂得收束；江湖尾声的路开始分岔。", "luoyang", 6)
		"q_main_epilogue_mercy":
			_state.append_world_event("story", "江湖留灯", "苏梦瑶与七派共同封存旧案，只清点首恶和铁证，几处被胁迫的暗线得以改过。", "luoyang", 6)
		"q_main_epilogue_reckoning":
			_state.append_world_event("story", "残影清剿", "陈天行与武林盟连夜清查暗影司残部，几条蛰伏多年的旧怨被翻到明面。", "changan", 6)
		_:
			_state.append_world_event("quest", "完成%s" % quest_title, "你办完了%s，附近江湖人多了一桩谈资。" % quest_title, _state.current_region_id, 2)

func _objective_key(objective: Dictionary) -> String:
	return "%s:%s" % [str(objective.get("type", "")), str(objective.get("target", ""))]

func get_quest_status_lines() -> Array[String]:
	var lines: Array[String] = []
	var active_hint := get_active_story_quest_hint()
	if not active_hint.is_empty():
		lines.append(active_hint)
		lines.append("")
	if _state.active_quests.is_empty():
		lines.append("暂无进行中的任务。")
		if not _state.active_quest.is_empty():
			lines.append("线索：%s" % _state.active_quest)
	for quest_id in _state.active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		lines.append("【进行中】%s" % str(quest.get("title", quest_id)))
		var description := str(quest.get("description", ""))
		if not description.is_empty():
			lines.append("  %s" % description)
		for objective_line in get_quest_objective_lines(str(quest_id)):
			lines.append("  - %s" % objective_line)
	var clues: Array = _state.get_adventure_clues(4)
	if not clues.is_empty():
		lines.append("")
		lines.append("奇遇线索：")
		for clue in clues:
			var entry: Dictionary = clue
			var region := str(entry.get("region_name", ""))
			var region_prefix := "%s · " % region if not region.is_empty() else ""
			var target := str(entry.get("target_region_name", ""))
			var target_suffix := "（指向：%s）" % target if not target.is_empty() else ""
			var resolved_suffix := "（已追到）" if bool(entry.get("resolved", false)) else ""
			lines.append("  - %s%s%s%s：%s" % [
				region_prefix,
				str(entry.get("title", "未名线索")),
				target_suffix,
				resolved_suffix,
				str(entry.get("description", ""))
			])
	if not _state.completed_quests.is_empty():
		lines.append("")
		lines.append("已完成：")
		for quest_id in _state.completed_quests:
			var quest := GameData.get_quest(str(quest_id))
			lines.append("  - %s" % str(quest.get("title", quest_id)))
	var choice_lines: Array[String] = _state.get_story_choice_status_lines()
	if not choice_lines.is_empty():
		lines.append("")
		lines.append("剧情抉择：")
		for line in choice_lines:
			lines.append("  - %s" % line)
	var events: Array = _state.get_recent_world_events(5)
	if not events.is_empty():
		lines.append("")
		lines.append("江湖传闻：")
		for event in events:
			var entry: Dictionary = event
			lines.append("  - 第%d日 %s：%s" % [
				int(entry.get("day", _state.day)),
				str(entry.get("title", "传闻")),
				str(entry.get("description", ""))
			])
	return lines

func get_quest_objective_lines(quest_id: String, include_hints: bool = false) -> Array[String]:
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return []
	var quest_state: Dictionary = _state.active_quests.get(quest_id, {})
	var progress: Dictionary = quest_state.get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	var lines: Array[String] = []
	for objective in objectives:
		var objective_data: Dictionary = objective
		var key := _objective_key(objective_data)
		var current := int(progress.get(key, 0))
		var required := int(objective_data.get("count", 1))
		var progress_text := "完成" if current >= required else "%d/%d" % [min(current, required), required]
		var label := str(objective_data.get("label", key))
		if include_hints and current < required:
			var hint := _objective_hint(objective_data)
			if not hint.is_empty() and hint != label:
				label = "%s（%s）" % [label, hint]
		lines.append("%s %s" % [label, progress_text])
	return lines

func get_quest_reward_lines(quest_id: String) -> Array[String]:
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return []
	var rewards: Dictionary = quest.get("rewards", {})
	var lines: Array[String] = []
	var exp_reward := int(rewards.get("exp", 0))
	var money_reward := int(rewards.get("money", 0))
	var daode_reward := int(rewards.get("daode", 0))
	if exp_reward > 0:
		lines.append("阅历 +%d" % exp_reward)
	if money_reward > 0:
		lines.append("银两 +%d" % money_reward)
	if daode_reward != 0:
		lines.append("道德 %+d" % daode_reward)
	var items: Dictionary = rewards.get("items", {})
	for item_id in items.keys():
		var item := GameData.get_item(str(item_id))
		var item_name := str(item.get("name", item_id))
		lines.append("%s x%d" % [item_name, int(items[item_id])])
	var skills: Dictionary = rewards.get("skills", {})
	for skill_id in skills.keys():
		lines.append("%s +%d" % [GameData.get_skill_name(str(skill_id)), int(skills[skill_id])])
	return lines

func get_quest_brief_text(quest_id: String, state_label: String = "任务") -> String:
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return "任务不存在"
	var lines: Array[String] = ["%s：%s" % [state_label, str(quest.get("title", quest_id))]]
	var description := str(quest.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var objective_lines := get_quest_objective_lines(quest_id, true)
	if not objective_lines.is_empty():
		lines.append("目标：%s" % "；".join(objective_lines))
	var reward_lines := get_quest_reward_lines(quest_id)
	if not reward_lines.is_empty():
		lines.append("奖励：%s" % "，".join(reward_lines))
	var next_hint := str(quest.get("next_hint", ""))
	if not next_hint.is_empty():
		lines.append("后续：%s" % next_hint)
	return "\n".join(lines)

func get_active_quest_tracker() -> String:
	if _state.active_quests.is_empty():
		return _state.active_quest
	var quest_id := _primary_active_quest_id()
	if quest_id.is_empty():
		return _state.active_quest
	var quest := GameData.get_quest(quest_id)
	var progress: Dictionary = _state.active_quests[quest_id].get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var key := _objective_key(objective)
		var current := int(progress.get(key, 0))
		var required := int(objective.get("count", 1))
		if current < required:
			return "%s：%s %d/%d" % [
				str(quest.get("title", quest_id)),
				str(objective.get("label", key)),
				min(current, required),
				required
			]
	return str(quest.get("title", quest_id))

func get_active_story_quest_hint() -> String:
	var quest_id := _primary_active_quest_id()
	if quest_id.is_empty():
		if _state.active_quest.is_empty() or _state.active_quest == "自由探索江湖":
			return "下一步：打开任务日志查看可接线索，或去地图寻找任务标记。"
		return "下一步：%s" % _state.active_quest
	var quest := GameData.get_quest(quest_id)
	if quest.is_empty():
		return ""
	var objective := _first_incomplete_objective(quest_id)
	if objective.is_empty():
		return "下一步：%s 目标已达成，等待任务结算。" % str(quest.get("title", quest_id))
	var label := str(objective.get("label", _objective_key(objective)))
	var detail := _objective_hint(objective)
	if detail.is_empty():
		detail = label
	return "下一步：%s · %s" % [str(quest.get("title", quest_id)), detail]

func _primary_active_quest_id() -> String:
	for quest_id in _state.active_quests.keys():
		var id := str(quest_id)
		if id.begins_with("q_main_"):
			return id
	for story_id in _state.STORY_QUEST_PRIORITY:
		if _state.active_quests.has(story_id):
			return story_id
	if _state.active_quests.is_empty():
		return ""
	return str(_state.active_quests.keys()[0])

func get_active_quest_target_region() -> Dictionary:
	var quest_id := _primary_active_quest_id()
	if quest_id.is_empty():
		return {}
	var objective := _first_incomplete_objective(quest_id)
	if objective.is_empty():
		return {}
	var kind := str(objective.get("type", ""))
	if kind != "talk" and kind != "kill":
		return {}
	return _target_region(str(objective.get("target", "")))

func get_active_quest_target_entries() -> Array:
	var entries: Array = []
	for quest_id_value in _state.active_quests.keys():
		var quest_id := str(quest_id_value)
		var quest := GameData.get_quest(quest_id)
		if quest.is_empty():
			continue
		var quest_state: Dictionary = _state.active_quests.get(quest_id, {})
		var progress: Dictionary = quest_state.get("progress", {})
		var objectives: Array = quest.get("objectives", [])
		for objective_value in objectives:
			if typeof(objective_value) != TYPE_DICTIONARY:
				continue
			var objective: Dictionary = objective_value
			var kind := str(objective.get("type", ""))
			if kind != "talk" and kind != "kill":
				continue
			var key := _objective_key(objective)
			var current := int(progress.get(key, 0))
			var required := int(objective.get("count", 1))
			if current >= required:
				continue
			var target := str(objective.get("target", ""))
			var npc := GameData.get_npc_by_name(target)
			var tile := Vector2i(-1, -1)
			if not npc.is_empty():
				tile = Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
			var region := _target_region(target)
			var region_id := str(region.get("id", ""))
			entries.append({
				"quest_id": quest_id,
				"quest_title": str(quest.get("title", quest_id)),
				"kind": kind,
				"target": target,
				"label": str(objective.get("label", key)),
				"current": current,
				"required": required,
				"tile": tile,
				"region_id": region_id,
				"region_name": str(region.get("name", region_id))
			})
	return entries

func get_quest_target_npc_names() -> Array:
	var names: Array = []
	for entry in get_active_quest_target_entries():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var target := str((entry as Dictionary).get("target", ""))
		if not target.is_empty():
			names.append(target)
	return names

func get_active_quest_target_label() -> String:
	var quest_id := _primary_active_quest_id()
	if quest_id.is_empty():
		return ""
	var quest := GameData.get_quest(quest_id)
	var objective := _first_incomplete_objective(quest_id)
	var region := get_active_quest_target_region()
	if quest.is_empty() or objective.is_empty() or region.is_empty():
		return ""
	return "%s · %s" % [
		str(quest.get("title", quest_id)),
		str(objective.get("label", _objective_key(objective)))
	]

func _first_incomplete_objective(quest_id: String) -> Dictionary:
	if not _state.active_quests.has(quest_id):
		return {}
	var quest := GameData.get_quest(quest_id)
	var quest_state: Dictionary = _state.active_quests.get(quest_id, {})
	var progress: Dictionary = quest_state.get("progress", {})
	var objectives: Array = quest.get("objectives", [])
	for objective in objectives:
		var objective_data: Dictionary = objective
		var key := _objective_key(objective_data)
		var current := int(progress.get(key, 0))
		var required := int(objective_data.get("count", 1))
		if current < required:
			return objective_data
	return {}

func _objective_hint(objective: Dictionary) -> String:
	var kind := str(objective.get("type", ""))
	var target := str(objective.get("target", ""))
	var label := str(objective.get("label", _objective_key(objective)))
	match kind:
		"talk":
			return _target_action_hint(target, "找%s交谈" % target)
		"kill":
			return _target_action_hint(target, "击败%s" % target)
		"collect":
			return "%s；可从商铺、掉落或探索中取得" % label
		"skill":
			return "%s；打开修炼面板提升对应武学" % label
		_:
			return label

func _target_action_hint(target: String, action_text: String) -> String:
	var region := _target_region(target)
	if region.is_empty():
		return action_text
	var region_id := str(region.get("id", ""))
	var region_name := str(region.get("name", region_id))
	if region_id == _state.current_region_id:
		return "在%s%s" % [region_name, action_text]
	return "前往%s%s" % [region_name, action_text]

func _target_region(target: String) -> Dictionary:
	var npc := GameData.get_npc_by_name(target)
	if npc.is_empty():
		return {}
	var tile := Vector2i(int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1)))
	return _state.get_region_for_map_tile(tile)
