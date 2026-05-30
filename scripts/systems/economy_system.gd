extends Node
## 经济系统 - 货币、商店、交易、价格波动

signal gold_changed(amount: int)
signal item_sold(item_id: String, price: int, quantity: int)
signal item_bought(item_id: String, price: int, quantity: int)
signal price_updated(item_id: String, new_price: int)

var _player_gold: int = 100
var _market_prices: Dictionary = {}
var _price_multipliers: Dictionary = {}
var _supply_demand: Dictionary = {}

func _ready() -> void:
	_init_market_prices()

func _init_market_prices() -> void:
	var base_prices: Array = [
		{"item_id": "health_potion", "base_price": 50, "volatility": 0.1},
		{"item_id": "mana_potion", "base_price": 75, "volatility": 0.1},
		{"item_id": "iron_sword", "base_price": 200, "volatility": 0.05},
		{"item_id": "leather_armor", "base_price": 150, "volatility": 0.05},
		{"item_id": "herb", "base_price": 10, "volatility": 0.2},
		{"item_id": "iron_ore", "base_price": 30, "volatility": 0.15},
		{"item_id": "cloth", "base_price": 20, "volatility": 0.1}
	]
	
	for item in base_prices:
		var item_id: String = item.get("item_id", "")
		_market_prices[item_id] = {
			"base_price": item.get("base_price", 100),
			"current_price": item.get("base_price", 100),
			"volatility": item.get("volatility", 0.1),
			"supply": 100,
			"demand": 100
		}
		_price_multipliers[item_id] = 1.0

func add_gold(amount: int) -> void:
	if amount > 0:
		_player_gold += amount
		gold_changed.emit(_player_gold)

func remove_gold(amount: int) -> bool:
	if _player_gold < amount:
		return false
	_player_gold -= amount
	gold_changed.emit(_player_gold)
	return true

func get_gold() -> int:
	return _player_gold

func set_gold(amount: int) -> void:
	_player_gold = max(0, amount)
	gold_changed.emit(_player_gold)

func buy_item(item_id: String, quantity: int, price_override: int = -1) -> bool:
	var price: int
	if price_override > 0:
		price = price_override
	else:
		price = get_item_price(item_id) * quantity
	
	if not remove_gold(price):
		return false
	
	_update_demand(item_id, quantity)
	item_bought.emit(item_id, price, quantity)
	return true

func sell_item(item_id: String, quantity: int, price_override: int = -1) -> bool:
	var price: int
	if price_override > 0:
		price = price_override
	else:
		price = int(get_item_price(item_id) * 0.5) * quantity
	
	add_gold(price)
	_update_supply(item_id, quantity)
	item_sold.emit(item_id, price, quantity)
	return true

func get_item_price(item_id: String) -> int:
	if not _market_prices.has(item_id):
		return 100
	
	var data: Dictionary = _market_prices[item_id]
	var base: int = data.get("base_price", 100)
	var multiplier: float = _price_multipliers.get(item_id, 1.0)
	return int(base * multiplier)

func set_item_price(item_id: String, price: int) -> void:
	if not _market_prices.has(item_id):
		return
	_market_prices[item_id]["current_price"] = price
	price_updated.emit(item_id, price)

func apply_price_modifier(item_id: String, modifier: float, duration: float = 0.0) -> void:
	if not _price_multipliers.has(item_id):
		_price_multipliers[item_id] = 1.0
	
	_price_multipliers[item_id] *= modifier
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		_price_multipliers[item_id] /= modifier

func _update_demand(item_id: String, quantity: int) -> void:
	if not _market_prices.has(item_id):
		return
	
	var data: Dictionary = _market_prices[item_id]
	var demand: int = data.get("demand", 100)
	demand += quantity
	_market_prices[item_id]["demand"] = demand
	
	_recalculate_price(item_id)

func _update_supply(item_id: String, quantity: int) -> void:
	if not _market_prices.has(item_id):
		return
	
	var data: Dictionary = _market_prices[item_id]
	var supply: int = data.get("supply", 100)
	supply += quantity
	_market_prices[item_id]["supply"] = supply
	
	_recalculate_price(item_id)

func _recalculate_price(item_id: String) -> void:
	if not _market_prices.has(item_id):
		return
	
	var data: Dictionary = _market_prices[item_id]
	var base: float = float(data.get("base_price", 100))
	var supply: float = float(max(1, data.get("supply", 100)))
	var demand: float = float(max(1, data.get("demand", 100)))
	var volatility: float = data.get("volatility", 0.1)
	
	var ratio: float = demand / supply
	var variance: float = randf_range(-volatility, volatility)
	var multiplier: float = ratio * (1.0 + variance)
	
	multiplier = clampf(multiplier, 0.5, 2.0)
	_price_multipliers[item_id] = multiplier

func simulate_market() -> void:
	for item_id in _market_prices:
		var data: Dictionary = _market_prices[item_id]
		
		var supply_delta: int = randi() % 21 - 10
		var demand_delta: int = randi() % 21 - 10
		
		data["supply"] = clamp(data.get("supply", 100) + supply_delta, 10, 200)
		data["demand"] = clamp(data.get("demand", 100) + demand_delta, 10, 200)
	
	for item_id in _market_prices:
		_recalculate_price(item_id)

func get_market_info(item_id: String) -> Dictionary:
	if not _market_prices.has(item_id):
		return {}
	return _market_prices[item_id].duplicate()

func get_all_prices() -> Dictionary:
	var prices: Dictionary = {}
	for item_id in _market_prices:
		prices[item_id] = get_item_price(item_id)
	return prices

func to_dictionary() -> Dictionary:
	return {
		"gold": _player_gold,
		"market_prices": _market_prices.duplicate(true),
		"price_multipliers": _price_multipliers.duplicate()
	}

func from_dictionary(data: Dictionary) -> void:
	_player_gold = data.get("gold", 100)
	_market_prices = data.get("market_prices", {}).duplicate(true)
	_price_multipliers = data.get("price_multipliers", {}).duplicate()
