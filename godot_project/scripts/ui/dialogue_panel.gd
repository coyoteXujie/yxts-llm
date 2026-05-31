extends Control
class_name DialoguePanel

var npc_data: Dictionary = {}
var title_label: Label
var body_label: Label
var meta_label: Label
var portrait_texture: TextureRect
var talk_index := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()

func show_npc(data: Dictionary) -> void:
	npc_data = data
	talk_index = 0
	var faction := GameData.get_faction_name(str(npc_data.get("faction", "none")))
	title_label.text = "%s  ·  %s" % [str(npc_data.get("name", "NPC")), faction]
	GameState.record_npc_interaction(npc_data, "talk")
	_update_meta()
	_set_portrait()
	_set_next_line()
	show()

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(180, 408)
	panel.size = Vector2(920, 268)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	panel.add_child(root)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(170, 210)
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	root.add_child(portrait_frame)

	portrait_texture = TextureRect.new()
	portrait_texture.custom_minimum_size = Vector2(158, 198)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait_texture)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
	box.add_child(title_label)

	meta_label = Label.new()
	meta_label.add_theme_font_size_override("font_size", 15)
	meta_label.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta_label)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(680, 92)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 20)
	body_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	box.add_child(body_label)

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

func _talk() -> void:
	GameState.record_npc_interaction(npc_data, "talk")
	_update_meta()
	_set_next_line()

func _set_next_line() -> void:
	var lines := GameData.get_dialogue_lines(str(npc_data.get("name", "")))
	if lines.is_empty():
		body_label.text = "江湖路远，少侠保重。"
		return
	var line := str(lines[talk_index % lines.size()])
	if talk_index == 0:
		var memory_line := _opening_memory_line()
		if not memory_line.is_empty():
			line = "%s\n%s" % [memory_line, line]
	body_label.text = line
	talk_index += 1

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
	parts.append("关系：%s %d" % [GameState.get_npc_relation_label(npc_name), int(memory.get("favor", 0))])
	var memories: Array = memory.get("memories", [])
	if not memories.is_empty():
		parts.append("记忆：%s" % str(memories[memories.size() - 1]))
	meta_label.text = "  |  ".join(parts)

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
	var quests := GameData.get_quests_for_npc(str(npc_data.get("name", "")))
	if quests.is_empty():
		body_label.text = "%s 暂时没有事情托付给你。" % str(npc_data.get("name", "对方"))
		return
	for quest in quests:
		var quest_id := str(quest.get("id", ""))
		if GameState.completed_quests.has(quest_id):
			continue
		if GameState.active_quests.has(quest_id):
			body_label.text = "任务进行中：%s\n%s" % [str(quest.get("title", quest_id)), str(quest.get("description", ""))]
			return
		GameState.accept_quest(quest_id)
		GameState.record_npc_interaction(npc_data, "quest_accept")
		_update_meta()
		body_label.text = "接下任务：%s\n%s" % [str(quest.get("title", quest_id)), str(quest.get("description", ""))]
		return
	body_label.text = "%s 点点头：你已经帮了不少忙。" % str(npc_data.get("name", "对方"))

func _shop() -> void:
	var sell_items: Array = npc_data.get("sell_items", [])
	if sell_items.is_empty():
		body_label.text = "%s 不做买卖。" % str(npc_data.get("name", "对方"))
		return
	GameState.record_npc_interaction(npc_data, "trade")
	hide()
	EventBus.emit_shop_requested(npc_data)

func _join_faction() -> void:
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
	if str(npc_data.get("name", "")) != "平阿四" and not bool(npc_data.get("can_rest", false)):
		body_label.text = "这里不能住店休息。"
		return
	if GameState.rest(12):
		GameState.record_npc_interaction(npc_data, "rest")
		_update_meta()
		body_label.text = "你在客栈歇下，醒来时精神恢复。"
	else:
		body_label.text = "银两不足，住不了店。"

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
