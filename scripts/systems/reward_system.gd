extends Node

signal reward_gained(reward_type: String, amount: int, description: String)
signal level_up(new_level: int)
signal skill_learned_signal(skill_id: String)

func give_exp(amount: int) -> Dictionary:
	var player_data := DataRegistry.get_player_data()
	player_data.exp += amount
	return {"exp_gained": amount}

func give_gold(amount: int) -> Dictionary:
	var player_data := DataRegistry.get_player_data()
	player_data.gold += amount
	EventBus.emit_player_gold_changed(player_data.gold)
	return {"gold_gained": amount}

func give_item(item_id: String, quantity: int = 1) -> Dictionary:
	EventBus.emit_item_picked_up(item_id, quantity)
	return {"item_id": item_id, "quantity": quantity}

func give_equipment(equipment: Dictionary) -> Dictionary:
	var equip_name: String = equipment.get("name", "装备")
	var slot: int = equipment.get("slot", 0)
	EventBus.emit_item_equipped(equip_name, slot)
	return {"equipment": equipment}

func give_skill(skill_id: String) -> Dictionary:
	var player_data := DataRegistry.get_player_data()
	var already_known := false
	for skill_entry in player_data.skills:
		if skill_entry.get("skill_id", "") == skill_id:
			already_known = true
			break
	if not already_known:
		player_data.skills.append({"skill_id": skill_id, "level": 1})
		skill_learned_signal.emit(skill_id)
		EventBus.emit_skill_learned(skill_id)
		return {"skill_id": skill_id, "learned": true}
	return {"skill_id": skill_id, "learned": false, "reason": "already_known"}

func give_reputation(faction_id: int, amount: int) -> Dictionary:
	FactionSystem.add_reputation(faction_id, amount)
	var faction_name: String = Constants.get_faction_name(faction_id)
	reward_gained.emit("reputation", amount, "%s 声望 +%d" % [faction_name, amount])
	return {"faction_id": faction_id, "amount": amount}

func give_combat_rewards(rewards: Dictionary) -> Dictionary:
	var results := {}
	if rewards.has("exp"):
		results["exp"] = give_exp(rewards.get("exp", 0))
	if rewards.has("gold"):
		results["gold"] = give_gold(rewards.get("gold", 0))
	if rewards.has("items"):
		results["items"] = []
		for item_id in rewards.get("items", []):
			results["items"].append(give_item(item_id, 1))
	return results

func give_quest_rewards(quest_data: Dictionary) -> Dictionary:
	var rewards: Dictionary = quest_data.get("rewards", {})
	return give_combat_rewards(rewards)

func create_dynamic_reward(base_value: int, difficulty_mod: float = 1.0) -> Dictionary:
	var exp_amount := int(base_value * difficulty_mod * (0.8 + Utils.random_range_float(0, 0.4)))
	var gold_amount := int(base_value * difficulty_mod * (0.5 + Utils.random_range_float(0, 0.5)))
	return {"exp": exp_amount, "gold": gold_amount}
