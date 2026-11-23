extends Control
class_name InventoryPanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")

var item_list: ItemList
var item_preview: TextureRect
var summary_label: Label
var details: Label
var item_ids: Array[String] = []
var confirm_overlay: ColorRect
var sort_label: Label

var _sort_mode := "type"

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
	_hide_confirm()
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -246
	panel.offset_top = -274
	panel.offset_right = 246
	panel.offset_bottom = 274
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	box.add_child(title_row)

	var title := Label.new()
	title.text = "背包"
	UI_ART.apply_title(title)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	sort_label = Label.new()
	sort_label.text = "排序：类型"
	sort_label.mouse_filter = Control.MOUSE_FILTER_STOP
	sort_label.add_theme_font_size_override("font_size", 13)
	sort_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62))
	sort_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.70))
	sort_label.add_theme_constant_override("shadow_offset_x", 1)
	sort_label.add_theme_constant_override("shadow_offset_y", 1)
	sort_label.gui_input.connect(_on_sort_label_input)
	title_row.add_child(sort_label)

	summary_label = Label.new()
	summary_label.custom_minimum_size = Vector2(430, 28)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(summary_label, 14)
	box.add_child(summary_label)

	item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(430, 220)
	item_list.fixed_icon_size = Vector2i(36, 36)
	item_list.icon_mode = ItemList.ICON_MODE_LEFT
	item_list.item_selected.connect(_select_item)
	box.add_child(item_list)

	var detail_row := HBoxContainer.new()
	detail_row.custom_minimum_size = Vector2(430, 120)
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
	details.custom_minimum_size = Vector2(328, 116)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(details)
	detail_row.add_child(details)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var use_button := Button.new()
	use_button.text = "使用"
	UI_ART.apply_button(use_button)
	use_button.pressed.connect(_use_selected)
	actions.add_child(use_button)

	var discard_button := Button.new()
	discard_button.text = "丢弃"
	UI_ART.apply_button(discard_button)
	discard_button.pressed.connect(_discard_selected)
	actions.add_child(discard_button)

	var discard_all_button := Button.new()
	discard_all_button.text = "全部丢弃"
	UI_ART.apply_button(discard_all_button)
	discard_all_button.pressed.connect(_confirm_discard_all)
	actions.add_child(discard_all_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	UI_ART.apply_button(close_button)
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

	_build_confirmation_overlay()

func _build_confirmation_overlay() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.color = Color(0.025, 0.018, 0.012, 0.58)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.z_index = 120
	confirm_overlay.hide()
	add_child(confirm_overlay)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -200
	card.offset_top = -100
	card.offset_right = 200
	card.offset_bottom = 100
	card.add_theme_stylebox_override("panel", _panel_style())
	confirm_overlay.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.anchors_preset = Control.PRESET_FULL_RECT
	card.add_child(box)

	var ctitle := Label.new()
	ctitle.text = "确认操作"
	UI_ART.apply_title(ctitle)
	box.add_child(ctitle)

	var cbody := Label.new()
	cbody.name = "ConfirmBody"
	cbody.custom_minimum_size = Vector2(360, 60)
	cbody.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_ART.apply_body_label(cbody, 16)
	box.add_child(cbody)

	var cactions := HBoxContainer.new()
	cactions.alignment = BoxContainer.ALIGNMENT_CENTER
	cactions.add_theme_constant_override("separation", 12)
	box.add_child(cactions)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(120, 36)
	UI_ART.apply_button(cancel_button)
	cancel_button.pressed.connect(_hide_confirm)
	cactions.add_child(cancel_button)

	var accept_button := Button.new()
	accept_button.name = "ConfirmAccept"
	accept_button.text = "确认"
	accept_button.custom_minimum_size = Vector2(120, 36)
	UI_ART.apply_button(accept_button)
	accept_button.pressed.connect(_execute_confirm)
	cactions.add_child(accept_button)

func _confirm_internal_text() -> Label:
	for child in confirm_overlay.get_children():
		if child is PanelContainer:
			for c2 in child.get_children():
				if c2 is VBoxContainer:
					for c3 in c2.get_children():
						if c3 is Label and c3.name == "ConfirmBody":
							return c3
	return null

var _pending_confirm: Callable

func _on_sort_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cycle_sort_mode()

func _cycle_sort_mode() -> void:
	var modes := ["type", "name", "quantity"]
	var idx := modes.find(_sort_mode)
	_sort_mode = modes[(idx + 1) % modes.size()]
	if sort_label != null:
		var names := {"type": "类型", "name": "名称", "quantity": "数量"}
		sort_label.text = "排序：%s" % names[_sort_mode]
	_refresh()

func _sorted_item_ids() -> Array[String]:
	var ids := GameState.inventory.keys()
	match _sort_mode:
		"name":
			ids.sort_custom(func(a: String, b: String) -> bool:
				var ia := GameData.get_item(a)
				var ib := GameData.get_item(b)
				return str(ia.get("name", a)) < str(ib.get("name", b))
			)
		"quantity":
			ids.sort_custom(func(a: String, b: String) -> bool:
				return int(GameState.inventory.get(a, 0)) > int(GameState.inventory.get(b, 0))
			)
		_:
			ids.sort()
			ids.sort_custom(func(a: String, b: String) -> bool:
				var ia := GameData.get_item(a)
				var ib := GameData.get_item(b)
				var ta := _type_rank(str(ia.get("type", "")))
				var tb := _type_rank(str(ib.get("type", "")))
				if ta != tb:
					return ta < tb
				return str(ia.get("name", a)) < str(ib.get("name", b))
			)
	return ids

func _refresh() -> void:
	if item_list == null:
		return
	item_list.clear()
	item_ids.clear()
	if summary_label != null:
		summary_label.text = _inventory_summary_text()
	var ids := _sorted_item_ids()
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


func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(16, 14, 16, 14))

func _slot_style() -> StyleBox:
	return UI_ART.slot_texture_style()

func _inventory_summary_text() -> String:
	var item_kinds := 0
	var item_count := 0
	for raw_item_id in GameState.inventory.keys():
		var count := int(GameState.inventory.get(raw_item_id, 0))
		if count <= 0:
			continue
		item_kinds += 1
		item_count += count
	var damaged := 0
	for item_id in GameState.get_repairable_equipment_item_ids():
		if GameState.get_equipment_repair_cost(item_id) > 0:
			damaged += 1
	var repair_text := "装备完好" if damaged <= 0 else "受损装备 %d 件，可去铁匠铺修理" % damaged
	return "银两 %d  ·  物品 %d 类/%d 件  ·  %s" % [
		int(GameState.player.get("money", 0)),
		item_kinds,
		item_count,
		repair_text
	]

func _load_item_icon(item_id: String) -> Texture2D:
	var path := GameData.get_item_icon_path(item_id)
	if path.is_empty():
		return null
	return GameData.load_texture(path)

func _item_list_label(item_id: String, item: Dictionary, count: int) -> String:
	var label := "%s x%d" % [str(item.get("name", item_id)), count]
	var slot := _equipment_slot_for_item(item)
	if not slot.is_empty():
		label = "%s  耐久%d%%" % [label, GameState.get_equipment_durability(item_id)]
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
	var stat_line := _format_equipment_bonus(item_id) if current_id == item_id else _format_equipment_delta(item_id, current_id)
	var durability := GameState.get_equipment_durability(item_id)
	var repair_cost := GameState.get_equipment_repair_cost(item_id)
	var condition := GameState.get_equipment_condition_label(item_id)
	var effect_percent := int(round(GameState.get_equipment_durability_effect_factor(item_id) * 100.0))
	var durability_line := "耐久：%d/%d（%s，加成%d%%）" % [durability, GameState.EQUIPMENT_DURABILITY_MAX, condition, effect_percent]
	if repair_cost > 0:
		durability_line = "%s（铁匠修理 %d 两）" % [durability_line, repair_cost]
	return "\n%s\n当前%s：%s\n%s\n%s" % [
		status,
		slot_name,
		current_name,
		stat_line,
		durability_line
	]

func _equipment_slot_for_item(item: Dictionary) -> String:
	if GameState.has_method("get_equipment_slot_for_item"):
		return str(GameState.get_equipment_slot_for_item(item))
	return str(item.get("slot", ""))

func _equipment_slot_name(slot: String) -> String:
	match slot:
		"weapon":
			return "武器"
		"armor":
			return "防具"
		"head":
			return "头盔"
		"hands":
			return "护腕"
		"feet":
			return "靴子"
		"accessory":
			return "饰品"
	return "装备"

func _format_equipment_delta(next_item_id: String, current_item_id: String) -> String:
	var next_effects := GameState.get_equipment_scaled_effects(next_item_id)
	var current_effects := GameState.get_equipment_scaled_effects(current_item_id) if not current_item_id.is_empty() else {}
	var parts: Array[String] = []
	for stat in ["attack", "defense"]:
		var next_value := int(next_effects.get(stat, 0))
		var current_value := int(current_effects.get(stat, 0))
		var delta := next_value - current_value
		if current_item_id.is_empty() and next_value == 0:
			continue
		if not current_item_id.is_empty() and delta == 0:
			continue
		var stat_name := "攻击" if stat == "attack" else "防御"
		if current_item_id.is_empty():
			parts.append("%s %+d" % [stat_name, next_value])
		else:
			parts.append("%s %+d" % [stat_name, delta])
	if parts.is_empty():
		return "更换变化：无"
	return "更换变化：%s" % "，".join(parts)

func _format_equipment_bonus(item_id: String) -> String:
	var effects := GameState.get_equipment_scaled_effects(item_id)
	var parts: Array[String] = []
	if effects.has("attack"):
		parts.append("攻击 %+d" % int(effects["attack"]))
	if effects.has("defense"):
		parts.append("防御 %+d" % int(effects["defense"]))
	if parts.is_empty():
		return "当前加成：无"
	return "当前加成：%s" % "，".join(parts)

func _type_rank(item_type: String) -> int:
	match item_type:
		"consumable":
			return 0
		"weapon":
			return 1
		"armor":
			return 2
		"head":
			return 3
		"hands":
			return 4
		"feet":
			return 5
		"accessory":
			return 6
	return 99

func _discard_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index < 0 or index >= item_ids.size():
		return
	var item_id := item_ids[index]
	var item := GameData.get_item(item_id)
	var count := int(GameState.inventory.get(item_id, 0))
	var item_name := str(item.get("name", item_id))
	if count <= 1:
		_pending_confirm = func():
			GameState.remove_item(item_id, 1)
			_refresh()
		var body := _confirm_internal_text()
		if body != null:
			body.text = "丢弃 %s 吗？\n此操作不可撤销。" % item_name
		confirm_overlay.show()
	else:
		_pending_confirm = func():
			GameState.remove_item(item_id, 1)
			_refresh()
		var body := _confirm_internal_text()
		if body != null:
			body.text = "丢弃 1 个 %s 吗？\n当前持有 %d 个。此操作不可撤销。" % [item_name, count]
		confirm_overlay.show()

func _confirm_discard_all() -> void:
	var has_discardable := false
	for item_id in GameState.inventory.keys():
		if not GameState.is_equipment_item(item_id) and int(GameState.inventory.get(item_id, 0)) > 0:
			has_discardable = true
			break
	if not has_discardable:
		EventBus.emit_toast("没有可丢弃的非装备物品")
		return
	_pending_confirm = func():
		for item_id in GameState.inventory.keys():
			var count := int(GameState.inventory.get(item_id, 0))
			if count > 0 and not GameState.is_equipment_item(item_id):
				GameState.remove_item(item_id, count)
		_refresh()
	var body := _confirm_internal_text()
	if body != null:
		body.text = "丢弃所有非装备物品吗？\n此操作不可撤销。"
	confirm_overlay.show()

func _hide_confirm() -> void:
	_pending_confirm = Callable()
	if confirm_overlay != null:
		confirm_overlay.hide()

func _execute_confirm() -> void:
	var cb = _pending_confirm
	_hide_confirm()
	if cb:
		cb.call()

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
