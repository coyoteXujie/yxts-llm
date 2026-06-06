extends Control
class_name DialoguePanel

var npc_data: Dictionary = {}
var title_label: Label
var body_label: Label
var meta_label: Label
var relation_label: Label
var favor_bar: ProgressBar
var memory_label: Label
var rumor_label: Label
var portrait_texture: TextureRect
var story_choice_box: HBoxContainer
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
	_clear_story_choice_buttons()
	_set_next_line()
	show()

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(84, 366)
	panel.size = Vector2(1112, 330)
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
	box.add_child(title_label)

	meta_label = Label.new()
	meta_label.custom_minimum_size = Vector2(560, 34)
	meta_label.add_theme_font_size_override("font_size", 15)
	meta_label.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta_label)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(560, 126)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 20)
	body_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	box.add_child(body_label)

	story_choice_box = HBoxContainer.new()
	story_choice_box.add_theme_constant_override("separation", 8)
	story_choice_box.hide()
	box.add_child(story_choice_box)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var talk_button := Button.new()
	talk_button.text = "闲谈"
	talk_button.pressed.connect(_talk)
	actions.add_child(talk_button)

	var teach_button := Button.new()
	teach_button.text = "请教"
	teach_button.pressed.connect(_teach)
	actions.add_child(teach_button)

	var quest_button := Button.new()
	quest_button.text = "任务"
	quest_button.pressed.connect(_quest)
	actions.add_child(quest_button)

	var story_button := Button.new()
	story_button.text = "抉择"
	story_button.pressed.connect(_story_choice)
	actions.add_child(story_button)

	var shop_button := Button.new()
	shop_button.text = "交易"
	shop_button.pressed.connect(_shop)
	actions.add_child(shop_button)

	var join_button := Button.new()
	join_button.text = "拜师"
	join_button.pressed.connect(_join_faction)
	actions.add_child(join_button)

	var rest_button := Button.new()
	rest_button.text = "住店"
	rest_button.pressed.connect(_rest)
	actions.add_child(rest_button)

	var close_button := Button.new()
	close_button.text = "离开"
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
			body_label.text = "任务进行中：%s\n%s" % [str(quest.get("title", quest_id)), str(quest.get("description", ""))]
			return
		var block_reason := GameState.get_quest_block_reason(quest_id)
		if not block_reason.is_empty():
			blocked_lines.append("【%s】%s" % [str(quest.get("title", quest_id)), block_reason])
			continue
		GameState.accept_quest(quest_id)
		GameState.record_npc_interaction(npc_data, "quest_accept")
		_update_meta()
		body_label.text = "接下任务：%s\n%s" % [str(quest.get("title", quest_id)), str(quest.get("description", ""))]
		return
	if not blocked_lines.is_empty():
		body_label.text = "%s 沉吟片刻：眼下还不到时候。\n%s" % [
			str(npc_data.get("name", "对方")),
			"\n".join(blocked_lines.slice(0, 3))
		]
		return
	body_label.text = "%s 点点头：你已经帮了不少忙。" % str(npc_data.get("name", "对方"))

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

func _join_faction() -> void:
	_clear_story_choice_buttons()
	var faction_id := str(npc_data.get("faction", "none"))
	if faction_id == "none" or not bool(npc_data.get("is_master", false)):
		body_label.text = "%s 不是可拜师的门派掌门。" % str(npc_data.get("name", "对方"))
		return
	if GameState.join_faction(faction_id):
		GameState.record_npc_interaction(npc_data, "join")
		_update_meta()
		body_label.text = "你拜入%s门下。" % GameData.get_faction_name(faction_id)
	else:
		body_label.text = "拜师未成。"

func _rest() -> void:
	_clear_story_choice_buttons()
	if str(npc_data.get("name", "")) != "平阿四" and not bool(npc_data.get("can_rest", false)):
		body_label.text = "这里不能住店休息。"
		return
	if GameState.rest(12):
		GameState.record_npc_interaction(npc_data, "rest")
		_update_meta()
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

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.068, 0.052, 0.94)
	style.border_color = Color(0.66, 0.52, 0.28, 0.86)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _portrait_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.040, 0.032, 0.94)
	style.border_color = Color(0.66, 0.52, 0.28, 0.82)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
