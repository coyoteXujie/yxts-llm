extends Control
class_name InventoryPanel

var item_list: ItemList
var item_preview: TextureRect
var details: Label
var item_ids: Array[String] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	EventBus.inventory_changed.connect(func(_inventory: Dictionary) -> void: _refresh())

func show_panel() -> void:
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.INVENTORY)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(742, 82)
	panel.size = Vector2(492, 548)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "背包"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title)

	item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(430, 270)
	item_list.fixed_icon_size = Vector2i(36, 36)
	item_list.icon_mode = ItemList.ICON_MODE_LEFT
	item_list.item_selected.connect(_select_item)
	box.add_child(item_list)

	var detail_row := HBoxContainer.new()
	detail_row.custom_minimum_size = Vector2(430, 124)
	detail_row.add_theme_constant_override("separation", 12)
	box.add_child(detail_row)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(88, 88)
	preview_frame.add_theme_stylebox_override("panel", _slot_style())
	detail_row.add_child(preview_frame)

	item_preview = TextureRect.new()
	item_preview.custom_minimum_size = Vector2(72, 72)
	item_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_frame.add_child(item_preview)

	details = Label.new()
	details.custom_minimum_size = Vector2(328, 120)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	detail_row.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var use_button := Button.new()
	use_button.text = "使用"
	use_button.pressed.connect(_use_selected)
	actions.add_child(use_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _refresh() -> void:
	if item_list == null:
		return
	item_list.clear()
	item_ids.clear()
	var ids := GameState.inventory.keys()
	ids.sort()
	for item_id in ids:
		var count := int(GameState.inventory[item_id])
		var item := GameData.get_item(str(item_id))
		item_ids.append(str(item_id))
		item_list.add_item(_item_list_label(str(item_id), item, count), _load_item_icon(str(item_id)))
	details.text = "选择物品查看详情。"
	if item_preview != null:
		item_preview.texture = null

func _select_item(index: int) -> void:
	if index < 0 or index >= item_ids.size():
		return
	var item_id := item_ids[index]
	var item := GameData.get_item(item_id)
	details.text = "%s\n%s\n类型：%s    价格：%d\n%s%s" % [
		str(item.get("name", item_id)),
		str(item.get("description", "")),
		_type_name(str(item.get("type", ""))),
		int(item.get("price", 0)),
		_format_effects(item),
		_format_equipment_detail(item_id, item)
	]
	if item_preview != null:
		item_preview.texture = _load_item_icon(item_id)

func _use_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		GameState.use_item(item_ids[index])
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.068, 0.052, 0.95)
	style.border_color = Color(0.58, 0.46, 0.26, 0.86)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.085, 0.06, 0.92)
	style.border_color = Color(0.68, 0.53, 0.28, 0.88)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _load_item_icon(item_id: String) -> Texture2D:
	var path := GameData.get_item_icon_path(item_id)
	if path.is_empty():
		return null
	return GameData.load_texture(path)

func _item_list_label(item_id: String, item: Dictionary, count: int) -> String:
	var label := "%s x%d" % [str(item.get("name", item_id)), count]
	var slot := _equipment_slot_for_item(item)
	if not slot.is_empty() and str(GameState.equipment.get(slot, "")) == item_id:
		label = "%s  已装备" % label
	return label

func _format_effects(item: Dictionary) -> String:
	var effects: Dictionary = item.get("effects", {})
	var parts: Array[String] = []
	if effects.has("hp"):
		parts.append("气血 %+d" % int(effects["hp"]))
	if effects.has("mp"):
		parts.append("内力 %+d" % int(effects["mp"]))
	if effects.has("attack"):
		parts.append("攻击 %+d" % int(effects["attack"]))
	if effects.has("defense"):
		parts.append("防御 %+d" % int(effects["defense"]))
	if effects.has("pot"):
		parts.append("潜能 %+d" % int(effects["pot"]))
	if parts.is_empty():
		return "效果：无"
	return "效果：%s" % "，".join(parts)

func _format_equipment_detail(item_id: String, item: Dictionary) -> String:
	var slot := _equipment_slot_for_item(item)
	if slot.is_empty():
		return ""
	var slot_name := _equipment_slot_name(slot)
	var current_id := str(GameState.equipment.get(slot, ""))
	var current_name := "无"
	if not current_id.is_empty():
		var current_item := GameData.get_item(current_id)
		current_name = str(current_item.get("name", current_id))
	var status := "已装备：%s" % slot_name if current_id == item_id else "可装备到：%s" % slot_name
	var stat_line := _format_equipment_bonus(item) if current_id == item_id else _format_equipment_delta(item, GameData.get_item(current_id) if not current_id.is_empty() else {})
	return "\n%s\n当前%s：%s\n%s" % [
		status,
		slot_name,
		current_name,
		stat_line
	]

func _equipment_slot_for_item(item: Dictionary) -> String:
	match str(item.get("type", "")):
		"weapon":
			return "weapon"
		"armor":
			return "armor"
	return ""

func _equipment_slot_name(slot: String) -> String:
	match slot:
		"weapon":
			return "武器"
		"armor":
			return "防具"
	return "装备"

func _format_equipment_delta(next_item: Dictionary, current_item: Dictionary) -> String:
	var next_effects: Dictionary = next_item.get("effects", {})
	var current_effects: Dictionary = current_item.get("effects", {})
	var parts: Array[String] = []
	for stat in ["attack", "defense"]:
		var next_value := int(next_effects.get(stat, 0))
		var current_value := int(current_effects.get(stat, 0))
		var delta := next_value - current_value
		if delta == 0 and next_value == 0:
			continue
		var stat_name := "攻击" if stat == "attack" else "防御"
		if current_item.is_empty():
			parts.append("%s %+d" % [stat_name, next_value])
		else:
			parts.append("%s %+d" % [stat_name, delta])
	if parts.is_empty():
		return "更换变化：无"
	return "更换变化：%s" % "，".join(parts)

func _format_equipment_bonus(item: Dictionary) -> String:
	var effects: Dictionary = item.get("effects", {})
	var parts: Array[String] = []
	if effects.has("attack"):
		parts.append("攻击 %+d" % int(effects["attack"]))
	if effects.has("defense"):
		parts.append("防御 %+d" % int(effects["defense"]))
	if parts.is_empty():
		return "当前加成：无"
	return "当前加成：%s" % "，".join(parts)

func _type_name(item_type: String) -> String:
	match item_type:
		"consumable":
			return "消耗品"
		"weapon":
			return "武器"
		"armor":
			return "防具"
		_:
			return "物品"
