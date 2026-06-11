extends Control
class_name ShopPanel

const MODE_BUY := "buy"
const MODE_SELL := "sell"
const MODE_BUYBACK := "buyback"
const SHOP_BUY_PRICE_MIN_FACTOR := 0.80
const MARKET_PRICE_MIN_FACTOR := 0.70
const MARKET_PRICE_MAX_FACTOR := 1.30
const SHOP_BUY_PRICE_FACTORS := {
	"inn": 0.94,
	"medicine": 0.92,
	"blacksmith": 0.96,
	"tailor": 0.95,
	"market": 0.90,
	"teahouse": 0.93
}
const ITEM_TYPE_ORDER := {
	"consumable": 0,
	"weapon": 1,
	"armor": 2
}

var npc_data: Dictionary = {}
var title_label: Label
var money_label: Label
var item_list: ItemList
var item_preview: TextureRect
var details: Label
var buy_mode_button: Button
var sell_mode_button: Button
var buyback_mode_button: Button
var quantity_label: Label
var quantity_minus_button: Button
var quantity_plus_button: Button
var quantity_max_button: Button
var total_label: Label
var primary_button: Button
var confirm_overlay: Control
var confirm_title_label: Label
var confirm_body_label: Label
var confirm_accept_button: Button
var item_ids: Array[String] = []
var buyback_stock: Dictionary = {}
var buyback_prices: Dictionary = {}
var pending_transaction: Dictionary = {}
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
	buyback_stock.clear()
	buyback_prices.clear()
	pending_transaction.clear()
	if confirm_overlay != null:
		confirm_overlay.hide()
	_record_shop_market_clue()
	_refresh()
	show()
	GameState.set_mode(GameState.Mode.SHOP)

func close_panel() -> void:
	_hide_transaction_confirmation()
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

	buyback_mode_button = Button.new()
	buyback_mode_button.text = "回购"
	buyback_mode_button.pressed.connect(func() -> void: _set_shop_mode(MODE_BUYBACK))
	mode_row.add_child(buyback_mode_button)

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

	_build_confirmation_overlay()

func _build_confirmation_overlay() -> void:
	var overlay := ColorRect.new()
	confirm_overlay = overlay
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.025, 0.018, 0.012, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 120
	overlay.hide()
	add_child(overlay)

	var card := PanelContainer.new()
	card.position = Vector2(410, 210)
	card.size = Vector2(460, 230)
	card.add_theme_stylebox_override("panel", _panel_style())
	overlay.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	confirm_title_label = Label.new()
	confirm_title_label.text = "确认交易"
	confirm_title_label.add_theme_font_size_override("font_size", 24)
	confirm_title_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.36))
	box.add_child(confirm_title_label)

	confirm_body_label = Label.new()
	confirm_body_label.custom_minimum_size = Vector2(410, 108)
	confirm_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_body_label.add_theme_font_size_override("font_size", 17)
	confirm_body_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	box.add_child(confirm_body_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.pressed.connect(_hide_transaction_confirmation)
	actions.add_child(cancel_button)

	confirm_accept_button = Button.new()
	confirm_accept_button.text = "确认交易"
	confirm_accept_button.pressed.connect(_confirm_pending_transaction)
	actions.add_child(confirm_accept_button)

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
	elif shop_mode == MODE_BUYBACK:
		_refresh_buyback_items()
	else:
		_refresh_buy_items()
	details.text = "暂无可回购物品。" if shop_mode == MODE_BUYBACK and item_ids.is_empty() else "选择物品查看详情。"
	if item_preview != null:
		item_preview.texture = null
	_update_transaction_controls()

func _refresh_buy_items() -> void:
	var sell_items: Array = npc_data.get("sell_items", [])
	for item_id in _sorted_buy_item_ids(sell_items):
		var item := GameData.get_item(item_id)
		var price := _buy_price(item_id)
		var base_price := _base_item_price(item_id)
		item_ids.append(item_id)
		item_list.add_item("%s  %s" % [str(item.get("name", item_id)), _buy_price_label(price, base_price)], _load_item_icon(item_id))

func _refresh_sell_items() -> void:
	for item_id in _sorted_trade_item_ids(GameState.inventory.keys(), MODE_SELL):
		var count := int(GameState.inventory.get(item_id, 0))
		if count <= 0:
			continue
		var item := GameData.get_item(item_id)
		item_ids.append(item_id)
		item_list.add_item(_sell_item_label(item_id, item, count), _load_item_icon(item_id))

func _refresh_buyback_items() -> void:
	for item_id in _sorted_trade_item_ids(buyback_stock.keys(), MODE_BUYBACK):
		var count := int(buyback_stock.get(item_id, 0))
		if count <= 0:
			continue
		var item := GameData.get_item(item_id)
		item_ids.append(item_id)
		item_list.add_item(_buyback_item_label(item_id, item, count), _load_item_icon(item_id))

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
	elif shop_mode == MODE_BUYBACK:
		details.text = _buyback_item_detail(item_id, item)
	else:
		details.text = _buy_item_detail(item_id, item)
	if item_preview != null:
		item_preview.texture = _load_item_icon(item_id)
	_update_transaction_controls()

func _confirm_selected() -> void:
	_open_transaction_confirmation()

func _buy_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		var item_id := item_ids[index]
		var buy_count := clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
		_execute_buy(item_id, buy_count)

func _sell_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		var item_id := item_ids[index]
		var sell_count := clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
		_execute_sell(item_id, sell_count)

func _buyback_selected() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index >= 0 and index < item_ids.size():
		var item_id := item_ids[index]
		var buyback_count := clampi(quantity, 1, maxi(1, _max_quantity_for(item_id)))
		_execute_buyback(item_id, buyback_count)

func _set_shop_mode(next_mode: String) -> void:
	if shop_mode == next_mode:
		return
	_hide_transaction_confirmation()
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
	money_label.text = "银两：%d    行情：%s" % [int(GameState.player.get("money", 0)), _shop_market_summary()]

func _update_mode_buttons() -> void:
	if buy_mode_button != null:
		buy_mode_button.disabled = shop_mode == MODE_BUY
	if sell_mode_button != null:
		sell_mode_button.disabled = shop_mode == MODE_SELL
	if buyback_mode_button != null:
		buyback_mode_button.disabled = shop_mode == MODE_BUYBACK
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
	if shop_mode == MODE_BUYBACK:
		var stock := maxi(0, int(buyback_stock.get(item_id, 0)))
		var buyback_price := _buyback_price(item_id)
		if buyback_price <= 0:
			return stock
		return mini(stock, int(GameState.player.get("money", 0)) / buyback_price)
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
		var verb := _trade_verb()
		primary_button.text = "%s x%d" % [verb, quantity] if can_trade else verb
	if total_label != null:
		total_label.text = _transaction_summary(selected_item_id, quantity, max_quantity)

func _transaction_summary(item_id: String, count: int, max_quantity: int) -> String:
	if item_id.is_empty():
		return "请选择物品"
	if max_quantity <= 0:
		if shop_mode == MODE_SELL and _is_item_equipped(item_id):
			return "已装备，不能出售"
		if shop_mode == MODE_BUY or shop_mode == MODE_BUYBACK:
			return "银两不足"
		return "暂无可交易数量"
	var unit_price := _unit_price_for_mode(item_id)
	var verb := "收入" if shop_mode == MODE_SELL else "合计"
	return "%s：%d 两" % [verb, unit_price * count]

func _trade_verb() -> String:
	if shop_mode == MODE_SELL:
		return "卖出"
	if shop_mode == MODE_BUYBACK:
		return "回购"
	return "购买"

func _unit_price_for_mode(item_id: String) -> int:
	if shop_mode == MODE_SELL:
		return _sell_price(item_id)
	if shop_mode == MODE_BUYBACK:
		return _buyback_price(item_id)
	return _buy_price(item_id)

func _execute_buy(item_id: String, count: int) -> void:
	if GameState.buy_item(item_id, count, _buy_price(item_id)):
		_refresh()

func _execute_sell(item_id: String, count: int) -> void:
	var price := _sell_price(item_id)
	if GameState.sell_item(item_id, count, price):
		_add_buyback_stock(item_id, count, price)
		_refresh()

func _execute_buyback(item_id: String, count: int) -> void:
	var price := _buyback_price(item_id)
	if GameState.buy_item(item_id, count, price):
		_remove_buyback_stock(item_id, count)
		_refresh()

func _open_transaction_confirmation() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index < 0 or index >= item_ids.size():
		return
	var item_id := item_ids[index]
	var max_quantity := _max_quantity_for(item_id)
	if max_quantity <= 0:
		return
	var tx_count := clampi(quantity, 1, max_quantity)
	var unit_price := _unit_price_for_mode(item_id)
	pending_transaction = {
		"mode": shop_mode,
		"item_id": item_id,
		"count": tx_count,
		"unit_price": unit_price
	}
	var item := GameData.get_item(item_id)
	var verb := _trade_verb()
	var total_word := "收入" if shop_mode == MODE_SELL else "合计"
	if confirm_title_label != null:
		confirm_title_label.text = "确认%s" % verb
	if confirm_body_label != null:
		confirm_body_label.text = "%s %s x%d\n单价：%d 两\n%s：%d 两\n当前银两：%d" % [
			verb,
			str(item.get("name", item_id)),
			tx_count,
			unit_price,
			total_word,
			unit_price * tx_count,
			int(GameState.player.get("money", 0))
		]
	if confirm_accept_button != null:
		confirm_accept_button.text = "确认%s" % verb
	if confirm_overlay != null:
		confirm_overlay.show()

func _confirm_pending_transaction() -> void:
	if pending_transaction.is_empty():
		return
	var tx := pending_transaction.duplicate(true)
	_hide_transaction_confirmation()
	var mode := str(tx.get("mode", MODE_BUY))
	var item_id := str(tx.get("item_id", ""))
	var tx_count := int(tx.get("count", 1))
	if item_id.is_empty() or tx_count <= 0:
		return
	match mode:
		MODE_SELL:
			_execute_sell(item_id, tx_count)
		MODE_BUYBACK:
			_execute_buyback(item_id, tx_count)
		_:
			_execute_buy(item_id, tx_count)

func _hide_transaction_confirmation() -> void:
	pending_transaction.clear()
	if confirm_overlay != null:
		confirm_overlay.hide()

func _buy_price(item_id: String) -> int:
	var base_price := _base_item_price(item_id)
	if base_price <= 0:
		return 0
	return maxi(1, int(roundf(float(base_price) * _combined_buy_price_factor(item_id))))

func _base_item_price(item_id: String) -> int:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	return int(item.get("price", 0))

func _sell_price(item_id: String) -> int:
	var base_price := GameState.get_item_sell_price(item_id)
	if base_price <= 0:
		return 0
	return maxi(1, int(roundf(float(base_price) * _region_sell_price_factor(item_id))))

func _buyback_price(item_id: String) -> int:
	if buyback_prices.has(item_id):
		return int(buyback_prices.get(item_id, 0))
	return _sell_price(item_id)

func _add_buyback_stock(item_id: String, count: int, price: int) -> void:
	if item_id.is_empty() or count <= 0:
		return
	buyback_stock[item_id] = int(buyback_stock.get(item_id, 0)) + count
	buyback_prices[item_id] = price

func _remove_buyback_stock(item_id: String, count: int) -> void:
	if item_id.is_empty() or count <= 0:
		return
	buyback_stock[item_id] = int(buyback_stock.get(item_id, 0)) - count
	if int(buyback_stock.get(item_id, 0)) <= 0:
		buyback_stock.erase(item_id)
		buyback_prices.erase(item_id)

func _sorted_buy_item_ids(raw_ids: Array) -> Array[String]:
	return _sorted_trade_item_ids(raw_ids, MODE_BUY)

func _sorted_trade_item_ids(raw_ids: Array, mode: String) -> Array[String]:
	var entries: Array[Dictionary] = []
	for raw_id in raw_ids:
		var item_id := str(raw_id)
		var entry := _item_sort_entry(item_id, mode)
		if entry.is_empty():
			continue
		entries.append(entry)
	entries.sort_custom(Callable(self, "_compare_item_sort_entries"))
	var sorted_ids: Array[String] = []
	for entry in entries:
		sorted_ids.append(str(entry.get("item_id", "")))
	return sorted_ids

func _item_sort_entry(item_id: String, mode: String) -> Dictionary:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return {}
	return {
		"item_id": item_id,
		"name": str(item.get("name", item_id)),
		"type_rank": _item_type_rank(str(item.get("type", ""))),
		"unit_price": _sort_price_for_mode(item_id, mode),
		"equipped_rank": 1 if mode == MODE_SELL and _is_item_equipped(item_id) else 0
	}

func _compare_item_sort_entries(a: Dictionary, b: Dictionary) -> bool:
	var equipped_a := int(a.get("equipped_rank", 0))
	var equipped_b := int(b.get("equipped_rank", 0))
	if equipped_a != equipped_b:
		return equipped_a < equipped_b
	var type_a := int(a.get("type_rank", 99))
	var type_b := int(b.get("type_rank", 99))
	if type_a != type_b:
		return type_a < type_b
	var price_a := int(a.get("unit_price", 0))
	var price_b := int(b.get("unit_price", 0))
	if price_a != price_b:
		return price_a < price_b
	var name_a := str(a.get("name", ""))
	var name_b := str(b.get("name", ""))
	if name_a != name_b:
		return name_a < name_b
	return str(a.get("item_id", "")) < str(b.get("item_id", ""))

func _item_type_rank(item_type: String) -> int:
	return int(ITEM_TYPE_ORDER.get(item_type, 99))

func _sort_price_for_mode(item_id: String, mode: String) -> int:
	if mode == MODE_SELL:
		return _sell_price(item_id)
	if mode == MODE_BUYBACK:
		return _buyback_price(item_id)
	return _buy_price(item_id)

func _shop_type() -> String:
	var direct_id := str(npc_data.get("shop_id", ""))
	if not direct_id.is_empty():
		return direct_id
	return str(npc_data.get("shop_type", ""))

func _region_id() -> String:
	return str(npc_data.get("region_id", ""))

func _region_market() -> Dictionary:
	var region_id := _region_id()
	if region_id.is_empty():
		return {}
	return GameData.get_region_market(region_id)

func _shop_buy_price_factor() -> float:
	var factor := float(SHOP_BUY_PRICE_FACTORS.get(_shop_type(), 1.0))
	return clampf(factor, SHOP_BUY_PRICE_MIN_FACTOR, 1.0)

func _combined_buy_price_factor(item_id: String) -> float:
	return clampf(_shop_buy_price_factor() * _region_buy_price_factor(item_id), MARKET_PRICE_MIN_FACTOR, MARKET_PRICE_MAX_FACTOR)

func _region_buy_price_factor(item_id: String) -> float:
	return _region_price_factor(item_id, "buy_factor")

func _region_sell_price_factor(item_id: String) -> float:
	return _region_price_factor(item_id, "sell_factor")

func _region_price_factor(item_id: String, base_factor_key: String) -> float:
	var market := _region_market()
	if market.is_empty():
		return 1.0
	var factor := float(market.get(base_factor_key, 1.0))
	var shop_factors = market.get("shop_factors", {})
	if typeof(shop_factors) == TYPE_DICTIONARY:
		factor *= float(shop_factors.get(_shop_type(), 1.0))
	var item_factors = market.get("item_factors", {})
	if typeof(item_factors) == TYPE_DICTIONARY:
		factor *= float(item_factors.get(item_id, 1.0))
	return clampf(factor, MARKET_PRICE_MIN_FACTOR, MARKET_PRICE_MAX_FACTOR)

func _shop_discount_label() -> String:
	var factor := _shop_buy_price_factor()
	if factor >= 0.999:
		return "原价"
	return _format_discount_factor(factor)

func _shop_market_summary() -> String:
	var market := _region_market()
	var label := str(market.get("label", ""))
	var shop_label := _shop_discount_label()
	if label.is_empty():
		return shop_label
	return "%s · 本店%s" % [label, shop_label]

func _item_buy_market_label(item_id: String) -> String:
	var market := _region_market()
	var label := str(market.get("label", ""))
	var factor_label := _format_discount_factor(_combined_buy_price_factor(item_id))
	if label.is_empty():
		return factor_label
	return "%s · %s" % [label, factor_label]

func _record_shop_market_clue() -> void:
	var region_id := _region_id()
	var market := _region_market()
	if region_id.is_empty() or market.is_empty():
		return
	var feature := _market_feature_item(market)
	if feature.is_empty():
		return
	var item_id := str(feature.get("item_id", ""))
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return
	var region := GameData.get_region(region_id)
	var region_name := str(region.get("name", npc_data.get("region_name", region_id)))
	var item_name := str(item.get("name", item_id))
	var factor := float(feature.get("factor", 1.0))
	var condition := "货足价低" if factor < 1.0 else "稀缺价高"
	var target_region_id := _market_clue_target_region(region_id)
	var target_phrase := ""
	if not target_region_id.is_empty():
		var target_region := GameData.get_region(target_region_id)
		if not target_region.is_empty():
			target_phrase = "，去%s再问价也许有赚头" % str(target_region.get("name", target_region_id))
	var title := "%s货价风声" % region_name
	var description := "%s的掌柜说，%s一带%s%s%s。" % [
		str(npc_data.get("shop_name", "铺子")),
		region_name,
		item_name,
		condition,
		target_phrase
	]
	var clue_id := "market_%s_%s" % [region_id, item_id]
	GameState.record_adventure_clue(clue_id, title, description, region_id, "market", target_region_id)
	GameState.append_world_event("market", title, description, region_id, 2)

func _market_feature_item(market: Dictionary) -> Dictionary:
	var item_factors = market.get("item_factors", {})
	if typeof(item_factors) != TYPE_DICTIONARY:
		return {}
	var best_item_id := ""
	var best_factor := 1.0
	var best_delta := 0.0
	for raw_item_id in item_factors.keys():
		var item_id := str(raw_item_id)
		var factor := float(item_factors[raw_item_id])
		var delta := absf(1.0 - factor)
		if delta <= best_delta:
			continue
		best_delta = delta
		best_item_id = item_id
		best_factor = factor
	if best_item_id.is_empty() or best_delta < 0.05:
		return {}
	return {
		"item_id": best_item_id,
		"factor": best_factor
	}

func _market_clue_target_region(region_id: String) -> String:
	var region := GameData.get_region(region_id)
	if region.is_empty():
		return ""
	var parent_id := str(region.get("parent", ""))
	if not parent_id.is_empty() and parent_id != region_id and not GameData.get_region(parent_id).is_empty():
		return parent_id
	var neighbors := GameData.get_neighbor_regions(region_id, 1)
	if neighbors.is_empty():
		return ""
	var neighbor: Dictionary = neighbors[0] as Dictionary
	return str(neighbor.get("id", ""))

func _format_discount_factor(factor: float) -> String:
	var zhe := factor * 10.0
	if absf(zhe - roundf(zhe)) < 0.01:
		return "%d折" % int(roundf(zhe))
	return "%.1f折" % zhe

func _buy_price_label(price: int, base_price: int) -> String:
	if base_price > 0 and price != base_price:
		return "%d两（原%d）" % [price, base_price]
	return "%d两" % price

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
	return "%s x%d  卖%d两%s" % [str(item.get("name", item_id)), count, _sell_price(item_id), equipped]

func _buyback_item_label(item_id: String, item: Dictionary, count: int) -> String:
	return "%s x%d  回购%d两" % [str(item.get("name", item_id)), count, _buyback_price(item_id)]

func _sell_item_detail(item_id: String, item: Dictionary) -> String:
	var blocked := "\n已装备，不能出售" if _is_item_equipped(item_id) else ""
	var base_price := GameState.get_item_sell_price(item_id)
	var price := _sell_price(item_id)
	var market_line := ""
	if price != base_price:
		market_line = "\n本地回收行情：%s" % _format_discount_factor(_region_sell_price_factor(item_id))
	return "%s\n%s\n类型：%s    出售价：%d 两\n%s%s%s" % [
		str(item.get("name", item_id)),
		str(item.get("description", "")),
		_type_name(str(item.get("type", ""))),
		price,
		_format_effects(item),
		market_line,
		blocked
	]

func _buy_item_detail(item_id: String, item: Dictionary) -> String:
	var price := _buy_price(item_id)
	var base_price := _base_item_price(item_id)
	var market_line := ""
	if base_price > 0 and price < base_price:
		market_line = "\n本店行情：%s，已少收 %d 两。" % [_item_buy_market_label(item_id), base_price - price]
	elif base_price > 0 and price > base_price:
		market_line = "\n本店行情：%s，需多付 %d 两。" % [_item_buy_market_label(item_id), price - base_price]
	return "%s\n%s\n类型：%s    价格：%s\n%s%s" % [
		str(item.get("name", item_id)),
		str(item.get("description", "")),
		_type_name(str(item.get("type", ""))),
		_buy_price_label(price, base_price),
		_format_effects(item),
		market_line
	]

func _buyback_item_detail(item_id: String, item: Dictionary) -> String:
	return "%s\n刚刚卖出的物品，可按原出售价买回。\n类型：%s    回购价：%d 两\n%s" % [
		str(item.get("name", item_id)),
		_type_name(str(item.get("type", ""))),
		_buyback_price(item_id),
		_format_effects(item)
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
