extends Control
class_name AchievementPanel

## 成就图鉴面板 — 分类展示成就、进度、已解锁标记；NPC/物品图鉴

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var tabs: TabContainer
var ach_container: VBoxContainer
var bestiary_npc_container: VBoxContainer
var bestiary_item_container: VBoxContainer
var container: PanelContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.ACHIEVEMENT)

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
	container.offset_left = -400
	container.offset_top = -280
	container.offset_right = 400
	container.offset_bottom = 280
	container.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(18, 14, 18, 14)))
	add_child(container)

	var outer_box := VBoxContainer.new()
	outer_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(outer_box)

	var title := Label.new()
	title.text = "【成就图鉴】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI_ART.COLOR_GOLD)
	outer_box.add_child(title)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_box.add_child(tabs)

	# 成就页
	var ach_tab := ScrollContainer.new()
	ach_tab.name = "成就"
	ach_container = VBoxContainer.new()
	ach_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_tab.add_child(ach_container)
	tabs.add_child(ach_tab)

	# NPC图鉴页
	var npc_tab := ScrollContainer.new()
	npc_tab.name = "NPC图鉴"
	bestiary_npc_container = VBoxContainer.new()
	bestiary_npc_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_tab.add_child(bestiary_npc_container)
	tabs.add_child(npc_tab)

	# 物品图鉴页
	var item_tab := ScrollContainer.new()
	item_tab.name = "物品图鉴"
	bestiary_item_container = VBoxContainer.new()
	bestiary_item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_tab.add_child(bestiary_item_container)
	tabs.add_child(item_tab)

func _refresh() -> void:
	_refresh_achievements()
	_refresh_npc_bestiary()
	_refresh_item_bestiary()

func _refresh_achievements() -> void:
	# 清空
	for child in ach_container.get_children():
		child.queue_free()
	
	var ach_sys := get_node_or_null("/root/AchievementSystem")
	if ach_sys == null:
		return
	
	var all_ach: Dictionary = ach_sys.get_all_achievements()
	var types := {
		"combat": "战斗",
		"explore": "探索",
		"character": "角色",
		"quest": "任务",
		"collect": "收集",
		"story": "剧情"
	}
	
	for type_id in ["combat", "explore", "character", "quest", "collect", "story"]:
		var type_label := Label.new()
		type_label.text = "【%s】" % str(types.get(type_id, type_id))
		type_label.add_theme_font_size_override("font_size", 16)
		type_label.add_theme_color_override("font_color", UI_ART.COLOR_GOLD)
		ach_container.add_child(type_label)
		
		for ach_id in all_ach.keys():
			var ach: Dictionary = all_ach[ach_id]
			if str(ach.get("type", "")) != type_id:
				continue
			var unlocked = ach_sys.is_unlocked(ach_id)
			var prog = ach_sys.get_progress(ach_id)
			var needed := int(ach.get("count", 1))
			var name_str := str(ach.get("name", ach_id))
			var desc := str(ach.get("description", ""))
			
			var entry := HBoxContainer.new()
			var icon := Label.new()
			icon.text = "🏆" if unlocked else "○"
			icon.add_theme_color_override("font_color", Color.GOLD if unlocked else Color.GRAY)
			entry.add_child(icon)
			
			var text := Label.new()
			if unlocked:
				text.text = "%s — %s [已完成]" % [name_str, desc]
				text.add_theme_color_override("font_color", Color.GOLDENROD)
			else:
				var pct := mini(int(float(prog) / float(needed) * 100), 100)
				text.text = "%s — %s (%d/%d, %d%%)" % [name_str, desc, prog, needed, pct]
				text.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			entry.add_child(text)
			ach_container.add_child(entry)

func _refresh_npc_bestiary() -> void:
	for child in bestiary_npc_container.get_children():
		child.queue_free()
	
	var ach_sys := get_node_or_null("/root/AchievementSystem")
	if ach_sys == null:
		return
	
	# 读取NPC list
	var npc_names: Array = ach_sys.get_all_npc_names()
	var known_npcs := GameState.npc_memory.keys()
	
	var count_label := Label.new()
	count_label.text = "已结识：%d / %d" % [known_npcs.size(), npc_names.size()]
	count_label.add_theme_font_size_override("font_size", 14)
	bestiary_npc_container.add_child(count_label)
	
	for nname in npc_names:
		var hbox := HBoxContainer.new()
		var icon := Label.new()
		var met := known_npcs.has(nname)
		icon.text = "◆" if met else "◇"
		icon.add_theme_color_override("font_color", Color.YELLOW_GREEN if met else Color.GRAY)
		hbox.add_child(icon)
		var label := Label.new()
		label.text = nname
		label.add_theme_color_override("font_color", Color.WHITE if met else Color.GRAY)
		hbox.add_child(label)
		bestiary_npc_container.add_child(hbox)

func _refresh_item_bestiary() -> void:
	for child in bestiary_item_container.get_children():
		child.queue_free()
	
	var ach_sys := get_node_or_null("/root/AchievementSystem")
	if ach_sys == null:
		return
	
	var item_names: Array = ach_sys.get_all_item_names()
	var collected: Dictionary = ach_sys.collected_items
	
	var count_label := Label.new()
	count_label.text = "已收集：%d / %d" % [collected.size(), item_names.size()]
	count_label.add_theme_font_size_override("font_size", 14)
	bestiary_item_container.add_child(count_label)
	
	for iname in item_names:
		var hbox := HBoxContainer.new()
		var icon := Label.new()
		var has = collected.has(iname)
		icon.text = "●" if has else "○"
		icon.add_theme_color_override("font_color", Color.AQUA if has else Color.GRAY)
		hbox.add_child(icon)
		var label := Label.new()
		label.text = iname
		label.add_theme_color_override("font_color", Color.WHITE if has else Color.GRAY)
		hbox.add_child(label)
		bestiary_item_container.add_child(hbox)

func _on_achievement_unlocked(_id: String, _name: String) -> void:
	if visible:
		_refresh()
