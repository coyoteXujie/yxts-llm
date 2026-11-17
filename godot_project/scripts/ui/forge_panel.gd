extends Control
class_name ForgePanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")
const PANEL_ANIM := preload("res://scripts/ui/panel_anim.gd")
const CRAFTING_SYSTEM := preload("res://scripts/systems/crafting_system.gd")

var _crafting
var _recipe_buttons: Array = []
var _recipe_list
var _detail_name
var _detail_desc
var _detail_materials
var _detail_btn
var _current_recipe_id := ""
var _status_label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	name = "ForgePanel"
	hide()
	_crafting = CRAFTING_SYSTEM.new()
	_build()

func show_panel() -> void:
	_refresh_list()
	PANEL_ANIM.open(self)
	GameState.set_mode(GameState.Mode.FORGE)

func close_panel() -> void:
	PANEL_ANIM.close(self)
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var shade = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.018, 0.014, 0.72)
	add_child(shade)

	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -500
	panel.offset_top = -290
	panel.offset_right = 500
	panel.offset_bottom = 290
	panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(24, 20, 24, 20)))
	add_child(panel)

	var root = HBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	# 左列配方列表
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(380, 0)
	left_panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(14, 12, 14, 12)))
	root.add_child(left_panel)

	var left_box = VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_box)

	var title = Label.new()
	title.text = "锻造图谱"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	left_box.add_child(title)

	_recipe_list = VBoxContainer.new()
	_recipe_list.add_theme_constant_override("separation", 4)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_list)
	left_box.add_child(scroll)

	# 右列详情
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(380, 0)
	right_panel.add_theme_stylebox_override("panel", UI_ART.panel_texture_style(Vector4(18, 16, 18, 16)))
	root.add_child(right_panel)

	var right_box = VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 12)
	right_panel.add_child(right_box)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 18)
	_detail_name.add_theme_color_override("font_color", Color(0.92, 0.82, 0.60))
	right_box.add_child(_detail_name)

	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_font_size_override("font_size", 14)
	_detail_desc.add_theme_color_override("font_color", Color(0.78, 0.74, 0.62))
	_detail_desc.custom_minimum_size = Vector2(0, 50)
	right_box.add_child(_detail_desc)

	_detail_materials = Label.new()
	_detail_materials.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_materials.add_theme_font_size_override("font_size", 14)
	_detail_materials.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	_detail_materials.custom_minimum_size = Vector2(0, 120)
	right_box.add_child(_detail_materials)

	_detail_btn = Button.new()
	_detail_btn.text = "锻造"
	_detail_btn.custom_minimum_size = Vector2(200, 42)
	_detail_btn.disabled = true
	UI_ART.apply_button(_detail_btn)
	_detail_btn.pressed.connect(_on_craft)
	right_box.add_child(_detail_btn)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.90, 0.70, 0.30))
	right_box.add_child(_status_label)

	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	right_box.add_child(actions)
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(160, 38)
	UI_ART.apply_button(close_btn)
	close_btn.pressed.connect(close_panel)
	actions.add_child(close_btn)

func _refresh_list() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()
	_recipe_buttons.clear()

	for recipe_data in _crafting.get_recipes():
		var rid = str(recipe_data.get("id", ""))
		var rname = str(recipe_data.get("name", ""))
		var check = _crafting.can_craft(rid)

		var btn = Button.new()
		btn.text = rname
		btn.custom_minimum_size = Vector2(340, 36)
		btn.add_theme_font_size_override("font_size", 14)
		if check.get("ok", false):
			btn.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
		else:
			btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
		btn.pressed.connect(func(): _select_recipe(rid))
		_recipe_list.add_child(btn)
		_recipe_buttons.append(btn)

func _select_recipe(recipe_id: String) -> void:
	_current_recipe_id = recipe_id
	var recipe = _crafting.get_recipe(recipe_id)
	if recipe.is_empty():
		return

	_detail_name.text = str(recipe.get("name", ""))
	_detail_desc.text = str(recipe.get("description", ""))

	var materials = recipe.get("materials", {})
	var lines: Array = []
	for mat_id in materials.keys():
		var need = int(materials[mat_id])
		var have = int(GameState.inventory.get(mat_id, 0))
		var item = GameData.get_item(mat_id)
		var mat_name = str(item.get("name", mat_id))
		var status = "✅" if have >= need else "❌"
		lines.append("%s %s x%d（持有 %d）" % [status, mat_name, need, have])
	_detail_materials.text = "\n".join(lines)

	var result_id = str(recipe.get("result_id", ""))
	var result_item = GameData.get_item(result_id)
	var result_name = str(result_item.get("name", result_id))
	_detail_materials.text += "\n\n产出：%s" % result_name

	var can = _crafting.can_craft(recipe_id)
	_detail_btn.disabled = not can.get("ok", false)
	_status_label.text = "" if can.get("ok", false) else str(can.get("reason", ""))

func _on_craft() -> void:
	if _current_recipe_id.is_empty():
		return
	var result = _crafting.craft(_current_recipe_id)
	if result.get("ok", false):
		_status_label.text = "✅ 锻造成功！获得 %s %s" % [result.get("quality", ""), result.get("item_name", "")]
		AudioManager.play_sfx("hammer")
		EventBus.inventory_changed.emit(GameState.inventory)
		_refresh_list()
		_select_recipe(_current_recipe_id)
	else:
		_status_label.text = "❌ %s" % result.get("reason", "锻造失败")