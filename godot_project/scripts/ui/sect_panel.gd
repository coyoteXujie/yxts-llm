extends Control
class_name SectPanel

## 门派面板 — 查看门派信息、贡献、任务、功法

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var tabs: TabContainer
var info_label: RichTextLabel
var contribution_label: Label
var missions_label: RichTextLabel
var skills_label: RichTextLabel
var container: PanelContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.sect_changed.connect(_on_sect_changed)
	EventBus.sect_contribution_changed.connect(_on_contribution_changed)
	var ss := get_node_or_null("/root/SectSystem")
	if ss != null and ss.sect_missions_changed.is_connected(_refresh):
		pass
	if ss != null:
		ss.sect_missions_changed.connect(_refresh)

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.SECT)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	container = PanelContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -380
	container.offset_top = -280
	container.offset_right = 380
	container.offset_bottom = 280
	container.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(18, 14, 18, 14)))
	add_child(container)

	var outer_box := VBoxContainer.new()
	outer_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(outer_box)

	var title := Label.new()
	title.text = "【门派】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI_ART.COLOR_GOLD)
	outer_box.add_child(title)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_box.add_child(tabs)

	# 信息页
	var info_tab := VBoxContainer.new()
	info_tab.name = "门派信息"
	info_label = RichTextLabel.new()
	info_label.scroll_active = true
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_tab.add_child(info_label)
	tabs.add_child(info_tab)

	# 贡献页
	var contrib_tab := VBoxContainer.new()
	contrib_tab.name = "贡献"
	contribution_label = Label.new()
	contribution_label.add_theme_font_size_override("font_size", 18)
	contrib_tab.add_child(contribution_label)
	var contrib_btn := Button.new()
	contrib_btn.text = "查看可兑换物品"
	contrib_btn.pressed.connect(_show_contribution_items)
	contrib_tab.add_child(contrib_btn)
	tabs.add_child(contrib_tab)

	# 任务页
	var mission_tab := VBoxContainer.new()
	mission_tab.name = "门派任务"
	missions_label = RichTextLabel.new()
	missions_label.scroll_active = true
	missions_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mission_tab.add_child(missions_label)
	var accept_btn := Button.new()
	accept_btn.text = "接取任务"
	accept_btn.pressed.connect(_accept_mission)
	mission_tab.add_child(accept_btn)
	tabs.add_child(mission_tab)

	# 功法页
	var skill_tab := VBoxContainer.new()
	skill_tab.name = "功法"
	skills_label = RichTextLabel.new()
	skills_label.scroll_active = true
	skills_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_tab.add_child(skills_label)
	var learn_btn := Button.new()
	learn_btn.text = "兑换功法"
	learn_btn.pressed.connect(_unlock_skill)
	skill_tab.add_child(learn_btn)
	tabs.add_child(skill_tab)

func _refresh() -> void:
	var ss := get_node_or_null("/root/SectSystem")
	if ss == null:
		return
	if not ss.has_sect():
		info_label.text = "你尚未加入任何门派。\n\n[color=aqua]按 U 键查看可加入门派[/color]"
		info_label.text += "\n\n[b]可加入门派：[/b]\n"
		var all_sects: Dictionary = ss.get_all_sects()
		for sid in all_sects.keys():
			var sdata: Dictionary = all_sects[sid]
			info_label.text += "\n[color=yellow]%s[/color] — %s" % [str(sdata.get("name", "")), str(sdata.get("description", ""))]
		info_label.text += "\n\n加入条件：修为/任务/名声达标后即可加入"
		contribution_label.text = "未加入门派"
		missions_label.text = "未加入门派"
		skills_label.text = "未加入门派"
		return
	
	var sect: Dictionary = ss.current_sect_data
	var name_str := str(sect.get("name", ""))
	info_label.text = "[b]%s[/b]\n\n%s\n\n" % [name_str, str(sect.get("description", ""))]
	info_label.text += "等级：%d\n" % ss.level
	info_label.text += "已解锁功法���"
	var unlocked: Array = ss.unlocked_skills
	if unlocked.is_empty():
		info_label.text += " 无\n"
	else:
		for us in unlocked:
			var sname := GameData.get_skill_name(str(us))
			info_label.text += " %s" % sname
		info_label.text += "\n"
	
	contribution_label.text = "当前贡献：%d  门派等级：%d" % [ss.contribution, ss.level]
	
	# 任务
	var active: Array = ss.active_missions
	if active.is_empty():
		missions_label.text = "暂无进行中的门派任务\n\n"
	else:
		missions_label.text = "[b]进行中：[/b]\n"
		for am in active:
			var p := int(am.get("progress", 0))
			var c := int(am.get("count", 1))
			missions_label.text += "· %s (%d/%d)\n" % [str(am.get("title", "")), p, c]
	missions_label.text += "\n"
	var avail: Array = ss.get_missions()
	if avail.is_empty():
		missions_label.text += "无可接取任务"
	else:
		missions_label.text += "[b]可接取：[/b]\n"
		for am in avail:
			missions_label.text += "· %s（贡献+%d）\n" % [str(am.get("title", "")), int(am.get("reward_contribution", 0))]
	
	# 功法
	var avail_skills: Array = ss.get_available_skills()
	if avail_skills.is_empty():
		skills_label.text = "已解锁所有功法"
	else:
		skills_label.text = "[b]可兑换功法：[/b]\n"
		for as_info in avail_skills:
			var sid := str(as_info.get("skill_id", ""))
			var sname := GameData.get_skill_name(sid)
			var needed := int(as_info.get("needed_contribution", 0))
			skills_label.text += "· %s （需要%d贡献）\n" % [sname, needed]

func _on_sect_changed(_sect_id: String, _name: String) -> void:
	_refresh()

func _on_contribution_changed(_c: int) -> void:
	_refresh()

func _accept_mission() -> void:
	var ss := get_node_or_null("/root/SectSystem")
	if ss == null:
		return
	var avail: Array = ss.get_missions()
	if avail.is_empty():
		EventBus.emit_toast("没有可接取的任务")
		return
	var mid := str(avail[0].get("id", ""))
	ss.accept_mission(mid)

func _unlock_skill() -> void:
	var ss := get_node_or_null("/root/SectSystem")
	if ss == null:
		return
	var avail: Array = ss.get_available_skills()
	if avail.is_empty():
		EventBus.emit_toast("没有可兑换的功法")
		return
	var sid := str(avail[0].get("skill_id", ""))
	ss.unlock_skill(sid)
	_refresh()

func _show_contribution_items() -> void:
	var ss := get_node_or_null("/root/SectSystem")
	if ss == null or not ss.has_sect():
		return
	var items: Dictionary = ss.get_contribution_items()
	var text := "可兑换物品：\n"
	for item_id in items.keys():
		var cost := int(items[item_id])
		var item_data := GameData.get_item(str(item_id))
		var item_name := str(item_data.get("name", item_id))
		text += "· %s — %d贡献\n" % [item_name, cost]
	EventBus.emit_toast(text)
