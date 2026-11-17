extends Control
class_name DialoguePanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var npc_data: Dictionary = {}
var title_label: Label
var body_label: Label
var meta_label: Label
var action_hint_label: Label
var relation_label: Label
var favor_bar: ProgressBar
var memory_label: Label
var rumor_label: Label
var portrait_texture: TextureRect
var story_choice_box: HBoxContainer
var talk_button: Button
var teach_button: Button
var quest_button: Button
var story_button: Button
var shop_button: Button
var forge_button: Button
var join_button: Button
var rest_button: Button
var close_button: Button
var talk_index := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	if not LLMDirector.npc_line_ready.is_connected(_on_director_line_ready):
		LLMDirector.npc_line_ready.connect(_on_director_line_ready)

func show_npc(data: Dictionary) -> void:
	npc_data = data
	talk_index = 0
	var faction := GameData.get_faction_name(str(npc_data.get("faction", "none")))
	title_label.text = "%s  ·  %s" % [str(npc_data.get("name", "NPC")), faction]
	GameState.record_npc_interaction(npc_data, "talk")
	_update_meta()
	_set_portrait()
	_refresh_action_buttons()
	_clear_story_choice_buttons()
	_set_next_line()
	show()

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.05
	panel.anchor_top = 1.0
	panel.anchor_right = 0.95
	panel.anchor_bottom = 1.0
	panel.offset_left = 0
	panel.offset_top = -320
	panel.offset_right = 0
	panel.offset_bottom = -20
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(210, 250)
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	root.add_child(portrait_frame)

	portrait_texture = TextureRect.new()
	portrait_texture.custom_minimum_size = Vector2(198, 238)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_frame.add_child(portrait_texture)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(586, 0)
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
	UI_ART.apply_label_shadow(title_label)
	box.add_child(title_label)

	meta_label = Label.new()
	meta_label.custom_minimum_size = Vector2(560, 34)
	UI_ART.apply_body_label(meta_label, 15)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta_label)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(560, 126)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(body_label, 20)
	box.add_child(body_label)

	story_choice_box = HBoxContainer.new()
	story_choice_box.add_theme_constant_override("separation", 8)
	story_choice_box.hide()
	box.add_child(story_choice_box)

	action_hint_label = Label.new()
	action_hint_label.custom_minimum_size = Vector2(560, 22)
	action_hint_label.clip_text = true
	action_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_hint_label.add_theme_font_size_override("font_size", 14)
	action_hint_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62))
	UI_ART.apply_label_shadow(action_hint_label, 0.55)
	box.add_child(action_hint_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	talk_button = Button.new()
	talk_button.text = "闲谈"
	UI_ART.apply_button(talk_button)
	talk_button.pressed.connect(_talk)
	actions.add_child(talk_button)

	teach_button = Button.new()
	teach_button.text = "请教"
	UI_ART.apply_button(teach_button)
	teach_button.pressed.connect(_teach)
	actions.add_child(teach_button)

	quest_button = Button.new()
	quest_button.text = "任务"
	UI_ART.apply_button(quest_button)
	quest_button.pressed.connect(_quest)
	actions.add_child(quest_button)

	story_button = Button.new()
	story_button.text = "抉择"
	UI_ART.apply_button(story_button)
	story_button.pressed.connect(_story_choice)
	actions.add_child(story_button)

	shop_button = Button.new()
	shop_button.text = "交易"
	UI_ART.apply_button(shop_button)
	shop_button.pressed.connect(_shop)
	actions.add_child(shop_button)

	forge_button = Button.new()
	forge_button.text = "锻造"
	UI_ART.apply_button(forge_button)
	forge_button.pressed.connect(_open_forge)
	actions.add_child(forge_button)

	join_button = Button.new()
	join_button.text = "拜师"
	UI_ART.apply_button(join_button)
	join_button.pressed.connect(_join_faction)
	actions.add_child(join_button)

	rest_button = Button.new()
	rest_button.text = "住店"
	UI_ART.apply_button(rest_button)
	rest_button.pressed.connect(_rest)
	actions.add_child(rest_button)

	close_button = Button.new()
	close_button.text = "离开"
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

	var side_box := VBoxContainer.new()
	side_box.custom_minimum_size = Vector2(234, 250)
	side_box.add_theme_constant_override("separation", 9)
	root.add_child(side_box)

	var relation_title := Label.new()
	relation_title.text = "关系"
	relation_title.add_theme_font_size_override("font_size", 16)
	relation_title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.40))
	UI_ART.apply_label_shadow(relation_title, 0.55)
	side_box.add_child(relation_title)

	relation_label = Label.new()
	relation_label.custom_minimum_size = Vector2(224, 24)
	relation_label.add_theme_font_size_override("font_size", 15)
	relation_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72))
	relation_label.clip_text = true
	side_box.add_child(relation_label)

	favor_bar = ProgressBar.new()
	favor_bar.custom_minimum_size = Vector2(224, 14)
	favor_bar.min_value = 0
	favor_bar.max_value = 100
	favor_bar.show_percentage = false
	side_box.add_child(favor_bar)

	var memory_title := Label.new()
	memory_title.text = "近期记忆"
	memory_title.add_theme_font_size_override("font_size", 16)
	memory_title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.40))
	UI_ART.apply_label_shadow(memory_title, 0.55)
	side_box.add_child(memory_title)

	memory_label = Label.new()
	memory_label.custom_minimum_size = Vector2(224, 76)
	memory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_label.add_theme_font_size_override("font_size", 13)
	memory_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.67))
	side_box.add_child(memory_label)

	var rumor_title := Label.new()
	rumor_title.text = "江湖风声"
	rumor_title.add_theme_font_size_override("font_size", 16)
	rumor_title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.40))
	UI_ART.apply_label_shadow(rumor_title, 0.55)
	side_box.add_child(rumor_title)

	rumor_label = Label.new()
	rumor_label.custom_minimum_size = Vector2(224, 52)
	rumor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor_label.add_theme_font_size_override("font_size", 13)
	rumor_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.67))
	side_box.add_child(rumor_label)

func _talk() -> void:
	_clear_story_choice_buttons()
	GameState.record_npc_interaction(npc_data, "talk")
	_update_meta()
	_set_next_line()

func _set_next_line() -> void:
	_clear_story_choice_buttons()
	var lines := GameData.get_dialogue_lines(str(npc_data.get("name", "")))
	var director_line := LLMDirector.generate_npc_line(npc_data, talk_index)
	LLMDirector.request_live_npc_line(npc_data)
	if lines.is_empty():
		body_label.text = director_line if not director_line.is_empty() else "江湖路远，少侠保重。"
		talk_index += 1
		return
	var line := str(lines[talk_index % lines.size()])
	if not director_line.is_empty():
		line = "%s\n%s" % [director_line, line]
	if talk_index == 0:
		var memory_line := _opening_memory_line()
		if not memory_line.is_empty():
			line = "%s\n%s" % [memory_line, line]
	body_label.text = line
	talk_index += 1

func _on_director_line_ready(npc_name: String, line: String) -> void:
	if not visible or body_label == null:
		return
	if npc_name != str(npc_data.get("name", "")) or line.strip_edges().is_empty():
		return
	body_label.text = line.strip_edges()

func _update_meta() -> void:
	if meta_label == null:
		return
	var npc_name := str(npc_data.get("name", ""))
	var memory := GameState.get_npc_memory(npc_name)
	var parts: Array[String] = []
	var description := str(npc_data.get("description", ""))
	if not description.is_empty():
		parts.append(description)
	var personality := str(npc_data.get("personality", ""))
	if not personality.is_empty():
		parts.append("性格：%s" % personality)
	meta_label.text = "  |  ".join(parts)
	_update_relation_sidebar(npc_name, memory)

func _refresh_action_buttons() -> void:
	var available_actions: Array[String] = ["闲谈"]
	_set_button_state(talk_button, true, "换一句闲谈或听对方提起江湖风声")

	var teach_skills: Array = npc_data.get("teach_skills", [])
	var can_teach := not teach_skills.is_empty()
	_set_button_state(teach_button, can_teach, "可请教武学" if can_teach else "此人暂无可教武学")
	if can_teach:
		available_actions.append("请教")

	var quest_state := _quest_action_state()
	var quest_enabled := bool(quest_state.get("enabled", false))
	_set_button_state(quest_button, quest_enabled, str(quest_state.get("tooltip", "")))
	if quest_enabled:
		available_actions.append("任务")

	var story_choices := GameState.get_available_story_choices(str(npc_data.get("name", "")))
	var has_story_choice := not story_choices.is_empty()
	_set_button_state(story_button, has_story_choice, "可做剧情抉择" if has_story_choice else "暂无剧情抉择")
	if has_story_choice:
		available_actions.append("抉择")

	var sell_items: Array = npc_data.get("sell_items", [])
	var can_trade := not sell_items.is_empty()
	_set_button_state(shop_button, can_trade, "打开交易和修理服务" if can_trade else "此人不做买卖")
	if can_trade:
		available_actions.append("交易")

	var npc_name := str(npc_data.get("name", ""))
	var can_forge := can_trade and (npc_name.contains("铁匠") or str(npc_data.get("npc_type", "")) == "blacksmith")
	_set_button_state(forge_button, can_forge, "打开锻造面板" if can_forge else "此处不能锻造")
	if can_forge:
		available_actions.append("锻造")

	var join_state := _join_action_state()
	var join_enabled := bool(join_state.get("enabled", false))
	_set_button_state(join_button, join_enabled, str(join_state.get("tooltip", "")))
	if join_enabled:
		available_actions.append("拜师")

	var can_rest := _can_rest_here()
	_set_button_state(rest_button, can_rest, "住店休息并恢复状态" if can_rest else "这里不能住店")
	if can_rest:
		available_actions.append("住店")
	_set_button_state(close_button, true, "离开对话")

	if action_hint_label != null:
		action_hint_label.text = "可互动：%s" % " / ".join(available_actions)

func _set_button_state(button: Button, enabled: bool, tooltip: String) -> void:
	if button == null:
		return
	button.disabled = not enabled
	button.tooltip_text = tooltip

func _quest_action_state() -> Dictionary:
	var quests := GameData.get_quests_for_npc(str(npc_data.get("name", "")))
	if quests.is_empty():
		return {"enabled": false, "tooltip": "暂无可接任务"}
	var blocked_lines: Array[String] = []
	var completed_count := 0
	for quest in quests:
		var quest_data: Dictionary = quest
		var quest_id := str(quest_data.get("id", ""))
		if GameState.completed_quests.has(quest_id):
			completed_count += 1
			continue
		if GameState.active_quests.has(quest_id):
			return {"enabled": true, "tooltip": "任务进行中"}
		var block_reason := GameState.get_quest_block_reason(quest_id)
		if block_reason.is_empty():
			return {"enabled": true, "tooltip": "可接任务：%s" % str(quest_data.get("title", quest_id))}
		blocked_lines.append(block_reason)
	if completed_count >= quests.size():
		return {"enabled": false, "tooltip": "此人的委托已完成"}
	if not blocked_lines.is_empty():
		return {"enabled": true, "tooltip": "有任务线索，但条件未满足：%s" % str(blocked_lines[0])}
	return {"enabled": false, "tooltip": "暂无可推进任务"}

func _join_action_state() -> Dictionary:
	var faction_id := GameData.normalize_faction_id(str(npc_data.get("faction", "none")))
	if faction_id == "none" or not GameData.is_master_like_npc(npc_data):
		return {"enabled": false, "tooltip": "此人不是可拜师的门派掌门"}
	var player_faction := GameData.normalize_faction_id(str(GameState.player.get("faction", "none")))
	if player_faction != "none" and player_faction != faction_id:
		return {"enabled": false, "tooltip": "你已有门派，不能改拜%s" % GameData.get_faction_name(faction_id)}
	return {"enabled": true, "tooltip": "拜入%s并学习入门武学" % GameData.get_faction_name(faction_id)}

func _can_rest_here() -> bool:
	return str(npc_data.get("name", "")) == "平阿四" or bool(npc_data.get("can_rest", false))

func _update_relation_sidebar(npc_name: String, memory: Dictionary) -> void:
	if relation_label == null:
		return
	var relation := GameState.get_npc_relation_label(npc_name)
	var favor := int(memory.get("favor", 0))
	relation_label.text = "%s  %s" % [relation, _favor_tone(favor)]
	favor_bar.value = clampi(favor + 50, 0, 100)
	var memories: Array = memory.get("memories", [])
	var memory_lines: Array[String] = []
	var start: int = max(0, memories.size() - 3)
	for index in range(start, memories.size()):
		memory_lines.append(str(memories[index]))
	if memory_lines.is_empty():
		memory_label.text = "尚无特别记忆。"
	else:
		memory_label.text = "\n".join(memory_lines)
	rumor_label.text = _short_rumor_text()

func _favor_tone(favor: int) -> String:
	if favor >= 70:
		return "愿意托底"
	if favor >= 30:
		return "语气熟络"
	if favor >= 10:
		return "略有信任"
	if favor < 0:
		return "仍有戒心"
	return "正在观望"

func _short_rumor_text() -> String:
	var events := GameState.get_recent_world_events(2)
	if events.is_empty():
		return "暂无新的江湖传闻。"
	var lines: Array[String] = []
	for event in events:
		var entry: Dictionary = event
		var title := str(entry.get("title", "传闻"))
		var region := str(entry.get("region_name", ""))
		if region.is_empty():
			lines.append(title)
		else:
			lines.append("%s：%s" % [region, title])
	return "\n".join(lines)

func _opening_memory_line() -> String:
	var npc_name := str(npc_data.get("name", ""))
	var memory := GameState.get_npc_memory(npc_name)
	var talk_count := int(memory.get("talk_count", 0))
	var relation := GameState.get_npc_relation_label(npc_name)
	if talk_count <= 1:
		return "【初识】对方还在观察你的来意。"
	if relation == "挚友" or relation == "知己":
		return "【%s】%s 对你已少了几分戒心。" % [relation, npc_name]
	if relation == "好友" or relation == "朋友":
		return "【%s】%s 认得你，语气比从前熟络。" % [relation, npc_name]
	if relation == "疏远" or relation == "敌视":
		return "【%s】%s 看你的眼神并不友善。" % [relation, npc_name]
	return "【%s】%s 记得你来过。" % [relation, npc_name]

func _set_portrait() -> void:
	if portrait_texture == null:
		return
	var path := GameData.get_npc_portrait_path(str(npc_data.get("name", "")))
	if path.is_empty():
		portrait_texture.texture = null
		return
	portrait_texture.texture = GameData.load_texture(path)

func _teach() -> void:
	_clear_story_choice_buttons()
	var skills: Array = npc_data.get("teach_skills", [])
	if skills.is_empty():
		body_label.text = "%s 摇了摇头：我没有可教你的武学。" % str(npc_data.get("name", "对方"))
		return
	var skill_id := str(skills[0])
	var level := GameState.learn_skill(skill_id, 1)
	GameState.record_npc_interaction(npc_data, "teach")
	_update_meta()
	body_label.text = "%s 指点了你一番，%s 提升到 %d 级。" % [
		str(npc_data.get("name", "对方")),
		GameData.get_skill_name(skill_id),
		level
	]
	EventBus.emit_toast("学会/提升：%s" % GameData.get_skill_name(skill_id))

func _quest() -> void:
	_clear_story_choice_buttons()
	var quests := GameData.get_quests_for_npc(str(npc_data.get("name", "")))
	if quests.is_empty():
		body_label.text = "%s 暂时没有事情托付给你。" % str(npc_data.get("name", "对方"))
		return
	var blocked_lines: Array[String] = []
	for quest in quests:
		var quest_id := str(quest.get("id", ""))
		if GameState.completed_quests.has(quest_id):
			continue
		if GameState.active_quests.has(quest_id):
			body_label.text = GameState.get_quest_brief_text(quest_id, "任务进行中")
			return
		var block_reason := GameState.get_quest_block_reason(quest_id)
		if not block_reason.is_empty():
			blocked_lines.append("【%s】%s" % [str(quest.get("title", quest_id)), block_reason])
			continue
		GameState.accept_quest(quest_id)
		GameState.record_npc_interaction(npc_data, "quest_accept")
		_update_meta()
		_refresh_action_buttons()
		body_label.text = GameState.get_quest_brief_text(quest_id, "接下任务")
		return
	if not blocked_lines.is_empty():
		body_label.text = "%s 沉吟片刻：眼下还不到时候。\n%s" % [
			str(npc_data.get("name", "对方")),
			"\n".join(blocked_lines.slice(0, 3))
		]
		return
	var completed_titles: Array[String] = []
	for quest in quests:
		var quest_id := str(quest.get("id", ""))
		if GameState.completed_quests.has(quest_id):
			completed_titles.append(str(quest.get("title", quest_id)))
	var completed_text := "、".join(completed_titles) if not completed_titles.is_empty() else "这些委托"
	body_label.text = "%s 点点头：%s已经办妥。\n%s" % [
		str(npc_data.get("name", "对方")),
		completed_text,
		GameState.get_active_story_quest_hint()
	]

func _story_choice() -> void:
	var choices := GameState.get_available_story_choices(str(npc_data.get("name", "")))
	if choices.is_empty():
		_clear_story_choice_buttons()
		body_label.text = "%s 低声道：眼下还没有必须落子的抉择。" % str(npc_data.get("name", "对方"))
		return
	_clear_story_choice_buttons()
	var lines: Array[String] = ["这一步会改变后续江湖风声。"]
	for choice in choices:
		var choice_data: Dictionary = choice
		var choice_id := str(choice_data.get("id", ""))
		var button := Button.new()
		button.text = str(choice_data.get("title", "抉择"))
		button.tooltip_text = str(choice_data.get("description", ""))
		UI_ART.apply_button(button)
		button.pressed.connect(func() -> void:
			_choose_story_choice(choice_id)
		)
		story_choice_box.add_child(button)
		lines.append("【%s】%s" % [str(choice_data.get("title", "")), str(choice_data.get("description", ""))])
	story_choice_box.show()
	body_label.text = "\n".join(lines)

func _choose_story_choice(choice_id: String) -> void:
	if choice_id.is_empty():
		return
	var accepted := GameState.choose_story_branch(choice_id)
	_clear_story_choice_buttons()
	_update_meta()
	if accepted:
		body_label.text = "你做出了抉择。\n%s" % GameState.get_world_event_summary(1)
	else:
		body_label.text = "这一步已经无从更改。"

func _shop() -> void:
	_clear_story_choice_buttons()
	var sell_items: Array = npc_data.get("sell_items", [])
	if sell_items.is_empty():
		body_label.text = "%s 不做买卖。" % str(npc_data.get("name", "对方"))
		return
	GameState.record_npc_interaction(npc_data, "trade")
	hide()
	EventBus.emit_shop_requested(npc_data)

func _open_forge() -> void:
	_clear_story_choice_buttons()
	hide()
	EventBus.emit_toast("你走到铁砧前，准备开炉锻造")
	if Engine.get_main_loop() != null and Engine.get_main_loop().root.has_node("/root/Main/ForgePanel"):
		Engine.get_main_loop().root.get_node("/root/Main/ForgePanel").show_panel()
	else:
		# Fallback: try to find ForgePanel anywhere in the scene tree
		var main: Node = Engine.get_main_loop().root.get_node("/root/Main") if Engine.get_main_loop() != null else null
		if main != null and main.has_node("ForgePanel"):
			main.get_node("ForgePanel").show_panel()
		else:
			EventBus.emit_toast("锻造面板未加载")

func _join_faction() -> void:
	_clear_story_choice_buttons()
	var faction_id := GameData.normalize_faction_id(str(npc_data.get("faction", "none")))
	if faction_id == "none" or not GameData.is_master_like_npc(npc_data):
		body_label.text = "%s 不是可拜师的门派掌门。" % str(npc_data.get("name", "对方"))
		return
	if GameState.join_faction(faction_id):
		GameState.record_npc_interaction(npc_data, "join")
		_update_meta()
		_refresh_action_buttons()
		body_label.text = "你拜入%s门下。" % GameData.get_faction_name(faction_id)
	else:
		body_label.text = "拜师未成。"

func _rest() -> void:
	_clear_story_choice_buttons()
	if not _can_rest_here():
		body_label.text = "这里不能住店休息。"
		return
	if GameState.rest(12):
		GameState.record_npc_interaction(npc_data, "rest")
		_update_meta()
		_refresh_action_buttons()
		body_label.text = "你在客栈歇下，醒来时精神恢复。"
	else:
		body_label.text = "银两不足，住不了店。"

func _clear_story_choice_buttons() -> void:
	if story_choice_box == null:
		return
	for child in story_choice_box.get_children():
		child.queue_free()
	story_choice_box.hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()

func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(18, 14, 18, 14))

func _portrait_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(6, 6, 6, 6))
