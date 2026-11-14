extends RefCounted
class_name EconomySystem

var _state: Node

const TRADE_RECORD_LIMIT := 30

func _init(state: Node) -> void:
	_state = state

func record_trade_delivery(source_region_id: String, target_region_id: String, item_id: String, count: int, profit: int, clue_id: String = "", route_plan: Dictionary = {}) -> Dictionary:
	count = maxi(0, count)
	profit = maxi(0, profit)
	if item_id.is_empty() or count <= 0:
		return {}
	var source_region := GameData.get_region(source_region_id)
	var target_region := GameData.get_region(target_region_id)
	var item := GameData.get_item(item_id)
	var source_name := str(source_region.get("name", source_region_id if not source_region_id.is_empty() else "来路"))
	var target_name := str(target_region.get("name", target_region_id if not target_region_id.is_empty() else "目的地"))
	var item_name := str(item.get("name", item_id))
	if route_plan.is_empty():
		route_plan = build_trade_route_plan(source_region_id, target_region_id)
	var risk_level := int(route_plan.get("risk_level", 1))
	var reputation_gain := maxi(1, int(roundf(float(maxi(1, profit)) / 12.0))) + maxi(0, risk_level - 2)
	_state.trade_reputation += reputation_gain
	## 商誉赏金：结算前商誉档位越高，脚行回谢越厚（利润比例、单趟封顶）
	var reputation_bonus := _reputation_delivery_bonus(_state.trade_reputation - reputation_gain, profit)
	if reputation_bonus > 0:
		_state.add_money(reputation_bonus)
	var record := {
		"id": "%d_%d_%d" % [_state.day, int(_state.hour * 100.0), abs(hash("%s:%s:%s:%s" % [source_region_id, target_region_id, item_id, clue_id]))],
		"source_region_id": source_region_id,
		"source_region_name": source_name,
		"target_region_id": target_region_id,
		"target_region_name": target_name,
		"item_id": item_id,
		"item_name": item_name,
		"count": count,
		"profit": profit,
		"risk_level": risk_level,
		"risk_label": str(route_plan.get("risk_label", "")),
		"risk_bonus": int(route_plan.get("trade_risk_bonus", 0)),
		"route_summary": str(route_plan.get("route_summary", "")),
		"distance": float(route_plan.get("distance", 0.0)),
		"reputation_gain": reputation_gain,
		"reputation_total": _state.trade_reputation,
		"reputation_bonus": reputation_bonus,
		"clue_id": clue_id,
		"day": _state.day,
		"hour": _state.hour
	}
	_state.trade_records.append(record)
	while _state.trade_records.size() > TRADE_RECORD_LIMIT:
		_state.trade_records.remove_at(0)
	EventBus.quests_changed.emit()
	EventBus.world_events_changed.emit(_state.get_recent_world_events(30))
	return record.duplicate(true)

func _reputation_delivery_bonus(prior_rep: int, profit: int) -> int:
	## 商誉档位赏金：熟路货郎 10% / 行脚老手 20% / 商路名家 30%，单趟封顶 12 两
	if profit <= 0 or prior_rep < 15:
		return 0
	var rate := 0.10
	if prior_rep >= 80:
		rate = 0.30
	elif prior_rep >= 40:
		rate = 0.20
	return mini(12, int(floorf(float(profit) * rate)))

func build_trade_route_plan(source_region_id: String, target_region_id: String) -> Dictionary:
	var target_region := GameData.get_region(target_region_id)
	if target_region.is_empty():
		return {}
	var plan: Dictionary = _state._build_region_travel_plan_from_source(source_region_id, target_region_id, target_region, "")
	var risk_level := int(plan.get("risk_level", 1))
	var distance := float(plan.get("distance", 0.0))
	var risk_bonus := int(round(float(maxi(0, risk_level - 1)) * 3.0 + distance * 0.18))
	plan["trade_risk_bonus"] = maxi(0, risk_bonus)
	plan["trade_risk_note"] = _trade_route_risk_note(plan)
	return plan

func _trade_route_risk_note(plan: Dictionary) -> String:
	var route_summary := str(plan.get("route_summary", ""))
	var risk_label := str(plan.get("risk_label", "平稳"))
	var risk_bonus := int(plan.get("trade_risk_bonus", 0))
	if route_summary.is_empty():
		return "商路%s，风险补贴%d两。" % [risk_label, risk_bonus]
	return "商路：%s，%s，风险补贴%d两。" % [route_summary, risk_label, risk_bonus]

func get_trade_records(max_count: int = 6) -> Array:
	var count: int = _state.trade_records.size()
	if max_count > 0:
		count = clampi(max_count, 0, _state.trade_records.size())
	var start: int = max(0, _state.trade_records.size() - count)
	var result: Array = []
	for index in range(start, _state.trade_records.size()):
		if typeof(_state.trade_records[index]) == TYPE_DICTIONARY:
			result.append((_state.trade_records[index] as Dictionary).duplicate(true))
	return result

func get_trade_reputation_title() -> String:
	if _state.trade_reputation >= 80:
		return "商路名家"
	if _state.trade_reputation >= 40:
		return "行脚老手"
	if _state.trade_reputation >= 15:
		return "熟路货郎"
	if _state.trade_reputation > 0:
		return "初涉行商"
	return "未开商路"

func spend_money(amount: int) -> bool:
	if int(_state.player.get("money", 0)) < amount:
		EventBus.emit_toast("银两不足")
		return false
	_state.player["money"] = int(_state.player["money"]) - amount
	EventBus.player_changed.emit(_state.player)
	return true

func add_money(amount: int) -> void:
	_state.player["money"] = int(_state.player.get("money", 0)) + amount
	EventBus.player_changed.emit(_state.player)

func buy_item(item_id: String, count: int = 1, price_override: int = -1) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if count <= 0:
		return false
	var price := int(item.get("price", 0))
	if price_override >= 0:
		price = price_override
	var total_price := price * count
	if not spend_money(total_price):
		return false
	_state.add_item(item_id, count)
	if count > 1:
		EventBus.emit_toast("买入%s x%d" % [str(item.get("name", item_id)), count])
	else:
		EventBus.emit_toast("买入%s" % str(item.get("name", item_id)))
	return true

func sell_item(item_id: String, count: int = 1, price_override: int = -1) -> bool:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return false
	if count <= 0:
		return false
	if int(_state.inventory.get(item_id, 0)) < count:
		return false
	if _state.equipment.values().has(item_id):
		EventBus.emit_toast("已装备的物品不能出售")
		return false
	var price := price_override if price_override >= 0 else get_item_sell_price(item_id)
	if not _state.remove_item(item_id, count):
		return false
	_state.player["money"] = int(_state.player.get("money", 0)) + price * count
	EventBus.player_changed.emit(_state.player)
	EventBus.emit_toast("卖出%s，获得%d两" % [str(item.get("name", item_id)), price * count])
	return true

func get_item_sell_price(item_id: String) -> int:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	var base_price := int(item.get("price", 0))
	var rarity := str(item.get("rarity", "common"))
	var factor: float = float(GameData.RARITY_SELL_FACTORS.get(rarity, 0.42))
	return maxi(1, int(round(float(base_price) * factor)))

