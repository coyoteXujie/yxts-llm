extends Control
class_name PetPanel

## 灵宠面板 — 查看灵宠列表、出战配置、喂食与升级

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var tabs: TabContainer
var roster_container: VBoxContainer
var info_label: RichTextLabel
var container: PanelContainer
var current_detail_pet: String = ""
var detail_label: RichTextLabel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.pet_roster_changed.connect(_refresh)
	EventBus.pet_added.connect(_on_pet_changed)
	EventBus.pet_removed.connect(_on_pet_changed)

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.PET)

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
	title.text = "【灵宠】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI_ART.COLOR_GOLD)
	outer_box.add_child(title)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_box.add_child(tabs)

	# 灵宠列表页
	var roster_tab := ScrollContainer.new()
	roster_tab.name = "灵宠列表"
	roster_container = VBoxContainer.new()
	roster_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_tab.add_child(roster_container)
	tabs.add_child(roster_tab)

	# 详情/图鉴页
	var detail_tab := VBoxContainer.new()
	detail_tab.name = "详细"
	detail_label = RichTextLabel.new()
	detail_label.scroll_active = true
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tab.add_child(detail_label)
	var feed_btn := Button.new()
	feed_btn.text = "喂养丹药"
	feed_btn.pressed.connect(_feed_current_pet)
	detail_tab.add_child(feed_btn)
	var toggle_btn := Button.new()
	toggle_btn.text = "切换出战"
	toggle_btn.pressed.connect(_toggle_active)
	detail_tab.add_child(toggle_btn)
	tabs.add_child(detail_tab)

func _refresh() -> void:
	_refresh_roster()
	_refresh_detail()

func _refresh_roster() -> void:
	for child in roster_container.get_children():
		child.queue_free()

	var ps := get_node_or_null("/root/PetSystem")
	if ps == null:
		return
	
	var owned: Dictionary = ps.get_owned_pets()
	if owned.is_empty():
		var label := Label.new()
		label.text = "你还没有任何灵宠。\n灵宠可通过探索、购买、任务等方式获得。"
		roster_container.add_child(label)
		return
	
	for pid in owned.keys():
		var data: Dictionary = owned[pid]
		var def_data: Dictionary = ps.get_pet_def(pid)
		var name_str := str(def_data.get("name", pid))
		var lv := int(data.get("level", 1))
		var active: bool = ps.is_active(pid)
		var rarity := str(def_data.get("rarity", "common"))
		var rarity_color := Color.WHITE
		match rarity:
			"rare": rarity_color = Color.CORNFLOWER_BLUE
			"epic": rarity_color = Color.PURPLE
			"legendary": rarity_color = Color.GOLD
		
		var entry := HBoxContainer.new()
		var status_icon := Label.new()
		status_icon.text = "★" if active else "☆"
		status_icon.add_theme_color_override("font_color", Color.YELLOW if active else Color.GRAY)
		entry.add_child(status_icon)
		
		var name_label := Label.new()
		name_label.text = "%s (Lv.%d)" % [name_str, lv]
		name_label.add_theme_color_override("font_color", rarity_color)
		entry.add_child(name_label)
		
		var info_btn := Button.new()
		info_btn.text = "查看"
		var pid_capture: String = pid
		info_btn.pressed.connect(func() -> void:
			current_detail_pet = pid_capture
			_refresh_detail()
			tabs.current_tab = 1
		)
		entry.add_child(info_btn)
		
		roster_container.add_child(entry)

func _refresh_detail() -> void:
	var ps := get_node_or_null("/root/PetSystem")
	if ps == null:
		return

	if current_detail_pet.is_empty() or not ps.get_owned_pets().has(current_detail_pet):
		detail_label.text = "选择一只灵宠查看详情"
		return

	var data: Dictionary = ps.get_owned_pets()[current_detail_pet]
	var def_data: Dictionary = ps.get_pet_def(current_detail_pet)
	var name_str := str(def_data.get("name", current_detail_pet))
	var desc := str(def_data.get("description", ""))
	var lv := int(data.get("level", 1))
	var exp := int(data.get("exp", 0))
	var exp_needed := 100 * lv
	var stats: Dictionary = data.get("stats", {})
	var skills: Array = data.get("skills", [])
	var rarity := str(def_data.get("rarity", "common"))
	var active: bool = ps.is_active(current_detail_pet)

	var rarity_text := "普通"
	match rarity:
		"rare": rarity_text = "稀有"
		"epic": rarity_text = "史诗"
		"legendary": rarity_text = "传说"

	detail_label.text = "[b]%s[/b] (%s)\n" % [name_str, rarity_text]
	detail_label.text += "%s\n\n" % desc
	detail_label.text += "等级：%d  经验：%d/%d\n" % [lv, exp, exp_needed]
	detail_label.text += "状态：%s\n\n" % ("出战" if active else "休整")
	detail_label.text += "[b]属性[/b]\n"
	detail_label.text += "攻击：%d  防御：%d\n" % [int(stats.get("attack", 0)), int(stats.get("defense", 0))]
	detail_label.text += "速度：%d  灵力：%d\n\n" % [int(stats.get("speed", 0)), int(stats.get("spirit", 0))]
	detail_label.text += "[b]技能[/b]\n"
	for s in skills:
		if typeof(s) == TYPE_DICTIONARY:
			detail_label.text += "· %s（威力：%d）\n" % [str(s.get("name", "")), int(s.get("power", 0))]

func _feed_current_pet() -> void:
	if current_detail_pet.is_empty():
		EventBus.emit_toast("请先选择一只灵宠")
		return
	var ps := get_node_or_null("/root/PetSystem")
	if ps == null:
		return
	if ps.feed_pet(current_detail_pet):
		_refresh()

func _toggle_active() -> void:
	if current_detail_pet.is_empty():
		EventBus.emit_toast("请先选择一只灵宠")
		return
	var ps := get_node_or_null("/root/PetSystem")
	if ps == null:
		return
	var active: bool = not ps.is_active(current_detail_pet)
	ps.set_active(current_detail_pet, active)
	_refresh()

func _on_pet_changed(_id: String) -> void:
	if visible:
		_refresh()
