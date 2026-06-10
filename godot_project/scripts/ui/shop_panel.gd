extends Control
class_name ShopPanel

const MODE_BUY := "buy"
const MODE_SELL := "sell"

var npc_data: Dictionary = {}
var title_label: Label
var money_label: Label
var item_list: ItemList
var item_preview: TextureRect
var details: Label
var buy_mode_button: Button
var sell_mode_button: Button
var quantity_label: Label
var quantity_minus_button: Button
var quantity_plus_button: Button
var quantity_max_button: Button
var total_label: Label
var primary_button: Button
var item_ids: Array[String] = []
var shop_mode := MODE_BUY
var selected_item_id := ""
var selected_item_index := -1
var quantity := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	if not EventBus.player_changed.is_connected(_on_player_changed):
		EventBus.player_changed.connect(_on_player_changed)
	if not EventBus.inventory_changed.is_connected(_on_inventory_changed):
		EventBus.inventory_changed.connect(_on_inventory_changed)

func show_shop(data: Dictionary) -> void:
	npc_data = data
	shop_mode = MODE_BUY
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.SHOP)

func close_panel() -> void:
	hide()
	GameState.set_mode(GameState.Mode.EXPLORE)

func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(742, 88)
	panel.size = Vector2(492, 542)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	title_label = Label.new()
	title_label.text = "商店"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38))
	box.add_child(title_label)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 15)
	money_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.56))
	box.add_child(money_label)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	box.add_child(mode_row)

	buy_mode_button = Button.new()
	buy_mode_button.text = "买入"
	buy_mode_button.pressed.connect(func() -> void: _set_shop_mode(MODE_BUY))
	mode_row.add_child(buy_mode_button)

	sell_mode_button = Button.new()
	sell_mode_button.text = "出售"
	sell_mode_button.pressed.connect(func() -> void: _set_shop_mode(MODE_SELL))
	mode_row.add_child(sell_mode_button)

	item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(430, 232)
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
	details.custom_minimum_size = Vector2(328, 118)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	detail_row.add_child(details)

	var quantity_row := HBoxContainer.new()
	quantity_row.add_theme_constant_override("separation", 8)
	box.add_child(quantity_row)

	var quantity_title := Label.new()
	quantity_title.text = "数量"
	quantity_title.add_theme_font_size_override("font_size", 15)
	quantity_title.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62))
	quantity_row.add_child(quantity_title)

	quantity_minus_button = Button.new()
	quantity_minus_button.text = "-"
	quantity_minus_button.tooltip_text = "减少交易数量"
	quantity_minus_button.pressed.connect(func() -> void: _set_quantity(quantity - 1))
	quantity_row.add_child(quantity_minus_button)

	quantity_label = Label.new()
	quantity_label.custom_minimum_size = Vector2(42, 26)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.add_theme_font_size_override("font_size", 16)
	quantity_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.46))
	quantity_row.add_child(quantity_label)

	quantity_plus_button = Button.new()
	quantity_plus_button.text = "+"
	quantity_plus_button.tooltip_text = "增加交易数量"
	quantity_plus_button.pressed.connect(func() -> void: _set_quantity(quantity + 1))
	quantity_row.add_child(quantity_plus_button)

	quantity_max_button = Button.new()
	quantity_max_button.text = "最大"
	quantity_max_button.tooltip_text = "设为当前可交易最大数量"
	quantity_max_button.pressed.connect(func() -> void: _set_quantity(_max_quantity_for_selected()))
	quantity_row.add_child(quantity_max_button)

	total_label = Label.new()
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_font_size_override("font_size", 15)
	total_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.64))
	quantity_row.add_child(total_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	primary_button = Button.new()
	primary_button.text = "购买"
	primary_button.pressed.connect(_confirm_selected)
	actions.add_child(primary_button)

	var close_button := Button.new()
	close_button.text = "离开"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

func _refresh() -> void:
	if item_list == null:
		return
	item_list.clear()
	item_ids.clear()
	selected_item_id = ""
	selected_item_index = -1
	quantity = 1
	if title_label != null:
		title_label.text = _shop_title()
	_update_money_label()
	_update_mode_buttons()
	if shop_mode == MODE_SELL:
		_refresh_sell_items()
	else:
		_refresh_buy_items()
	details.text = "选择物品查看详情。"
	if item_preview != null:
		item_preview.texture = null
	_update_transaction_controls()

func _refresh_buy_items() -> void:
	var sell_items: Array = npc_data.get("sell_items", [])
	for item_id in sell_items:
		var item := GameData.get_item(str(item_id))
		item_ids.append(str(item_id))
		item_list.add_item("%s  %d两" % [str(item.get("name", item_id)), int(item.get("price", 0))], _load_item_icon(str(item_id)))

func _refresh_sell_items() -> void:
	var ids := GameState.inventory.keys()
	ids.sort()
	for item_id_value in ids:
		var item_id := str(item_id_value)
		var count := int(GameState.inventory.get(item_id, 0))
		if count <= 0:
			continue
		var item := GameData.get_item(item_id)
		item_ids.append(item_id)
		item_list.add_item(_sell_item_label(item_id, item, count), _load_item_icon(item_id))

func _select_item(index: int) -> void:
	if index < 0 or index >= item_ids.size():
		return
	var item_id := item_ids[index]
	var item := GameData.get_item(item_id)
	selected_item_id = item_id
	selected_item_index = index
	quantity = clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
	if shop_mode == MODE_SELL:
		details.text = _sell_item_detail(item_id, item)
	else:
		details.text = "%s\n%s\n类型：%s    价格：%d 两\n%s" % [
			str(item.get("name", item_id)),
			str(item.get("description", "")),
			_type_name(str(item.get("type", ""))),
			int(item.get("price", 0)),
			_format_effects(item)
	]
	if item_preview != null:
		item_preview.texture = _load_item_icon(item_id)
	_update_transaction_controls()

func _confirm_selected() -> void:
	if shop_mode == MODE_SELL:
		_sell_selected()
	else:
		_buy_selected()

func _buy_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		var item_id := item_ids[index]
		var buy_count := clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
		if GameState.buy_item(item_id, buy_count):
			_refresh()

func _sell_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		var item_id := item_ids[index]
		var sell_count := clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
		if GameState.sell_item(item_id, sell_count):
			_refresh()

func _set_shop_mode(next_mode: String) -> void:
	if shop_mode == next_mode:
		return
	shop_mode = next_mode
	_refresh()

func _shop_title() -> String:
	var shop_name := str(npc_data.get("shop_name", "商店"))
	var keeper := str(npc_data.get("name", "掌柜"))
	if shop_name.is_empty() or shop_name == "商店":
		return "%s的铺子" % keeper
	return "%s · %s" % [shop_name, keeper]

func _update_money_label() -> void:
	if money_label == null:
		return
	money_label.text = "银两：%d" % int(GameState.player.get("money", 0))

func _update_mode_buttons() -> void:
	if buy_mode_button != null:
		buy_mode_button.disabled = shop_mode == MODE_BUY
	if sell_mode_button != null:
		sell_mode_button.disabled = shop_mode == MODE_SELL
	_update_transaction_controls()

func _set_quantity(next_quantity: int) -> void:
	quantity = clampi(next_quantity, 1, maxi(1, _max_quantity_for_selected()))
	_update_transaction_controls()

func _max_quantity_for_selected() -> int:
	if selected_item_id.is_empty():
		return 1
	return _max_quantity_for(selected_item_id)

func _max_quantity_for(item_id: String) -> int:
	if item_id.is_empty():
		return 1
	if shop_mode == MODE_SELL:
		if _is_item_equipped(item_id):
			return 0
		return maxi(0, int(GameState.inventory.get(item_id, 0)))
	var price := _buy_price(item_id)
	if price <= 0:
		return 99
	return clampi(int(GameState.player.get("money", 0)) / price, 0, 99)

func _update_transaction_controls() -> void:
	var has_selection := not selected_item_id.is_empty()
	var max_quantity := _max_quantity_for_selected()
	var can_trade := has_selection and max_quantity > 0
	quantity = clampi(quantity, 1, maxi(1, max_quantity))
	if quantity_label != null:
		quantity_label.text = str(quantity)
	if quantity_minus_button != null:
		quantity_minus_button.disabled = not can_trade or quantity <= 1
	if quantity_plus_button != null:
		quantity_plus_button.disabled = not can_trade or quantity >= max_quantity
	if quantity_max_button != null:
		quantity_max_button.disabled = not can_trade or max_quantity <= 1
	if primary_button != null:
		primary_button.disabled = not can_trade
		var verb := "卖出" if shop_mode == MODE_SELL else "购买"
		primary_button.text = "%s x%d" % [verb, quantity] if can_trade else verb
	if total_label != null:
		total_label.text = _transaction_summary(selected_item_id, quantity, max_quantity)

func _transaction_summary(item_id: String, count: int, max_quantity: int) -> String:
	if item_id.is_empty():
		return "请选择物品"
	if max_quantity <= 0:
		if shop_mode == MODE_SELL and _is_item_equipped(item_id):
			return "已装备，不能出售"
		if shop_mode == MODE_BUY:
			return "银两不足"
		return "暂无可交易数量"
	var unit_price := _sell_price(item_id) if shop_mode == MODE_SELL else _buy_price(item_id)
	var verb := "收入" if shop_mode == MODE_SELL else "合计"
	return "%s：%d 两" % [verb, unit_price * count]

func _buy_price(item_id: String) -> int:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	return int(item.get("price", 0))

func _sell_price(item_id: String) -> int:
	return GameState.get_item_sell_price(item_id)

func _on_player_changed(_player: Dictionary) -> void:
	if visible:
		_refresh()

func _on_inventory_changed(_inventory: Dictionary) -> void:
	if visible:
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

func _sell_item_label(item_id: String, item: Dictionary, count: int) -> String:
	var equipped := "  已装备" if _is_item_equipped(item_id) else ""
	return "%s x%d  卖%d两%s" % [str(item.get("name", item_id)), count, GameState.get_item_sell_price(item_id), equipped]

func _sell_item_detail(item_id: String, item: Dictionary) -> String:
	var blocked := "\n已装备，不能出售" if _is_item_equipped(item_id) else ""
	return "%s\n%s\n类型：%s    出售价：%d 两\n%s%s" % [
		str(item.get("name", item_id)),
		str(item.get("description", "")),
		_type_name(str(item.get("type", ""))),
		GameState.get_item_sell_price(item_id),
		_format_effects(item),
		blocked
	]

func _is_item_equipped(item_id: String) -> bool:
	return GameState.equipment.values().has(item_id)

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
