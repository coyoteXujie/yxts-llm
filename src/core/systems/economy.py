from typing import Dict, Optional
from ..entities import Player, Item, ItemType, Faction, FACTION_NAMES
from ..event import EventType, dispatch


ECONOMY_CONFIG = {
    "starting_money": 100,
    "max_money": 999999,
    "combat_money_base": 5,
    "combat_money_per_level": 2,
    "combat_money_cap_ratio": 0.1,
    "quest_money_base": 20,
    "quest_money_per_difficulty": 15,
    "sell_price_ratio": 0.5,
    "buy_price_ratio": 1.0,
    "inn_cost": 10,
    "inn_hp_restore": 1.0,
    "inn_mp_restore": 1.0,
    "training_cost_base": 10,
    "training_cost_per_level": 2,
    "donation_min": 100,
    "donation_rep_gain": 3,
    "death_money_penalty": 0.3,
    "food_cost": 3,
    "water_cost": 2,
}

FACTION_TAX_RATE = {
    Faction.NONE: 0.0,
    Faction.BAGUA: 0.05,
    Faction.FLOWER: 0.03,
    Faction.HONGLIAN: 0.08,
    Faction.NAJA: 0.10,
    Faction.TAIJI: 0.02,
    Faction.XUESHAN: 0.04,
    Faction.XIAOYAO: 0.0,
}


class EconomySystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def buy_item(self, player: Player, item: Item, seller_faction: Faction = Faction.NONE,
                 reputation_modifier: float = 1.0) -> Dict:
        base_price = item.price
        final_price = self._calculate_buy_price(base_price, reputation_modifier)

        tax_rate = FACTION_TAX_RATE.get(player.faction, 0)
        tax = int(final_price * tax_rate)
        total = final_price + tax

        if player.money < total:
            return {
                "success": False,
                "message": f"银两不足，需要{total}文（含税{tax}文）",
                "price": total,
            }

        player.money -= total
        player.add_item(item.id)

        dispatch(EventType.PLAYER_GOT_ITEM, {
            "item_name": item.name,
            "item_id": item.id,
            "count": 1,
        })

        return {
            "success": True,
            "message": f"购买了{item.name}，花费{total}文" +
                       (f"（含门派税{tax}文）" if tax > 0 else ""),
            "price": total,
            "tax": tax,
        }

    def sell_item(self, player: Player, item: Item, buyer_faction: Faction = Faction.NONE,
                  reputation_modifier: float = 1.0) -> Dict:
        if item.id not in player.inventory or player.inventory[item.id] <= 0:
            return {"success": False, "message": f"你没有{item.name}"}

        if item.type == ItemType.QUEST:
            return {"success": False, "message": "任务物品无法出售"}

        base_price = item.price
        sell_price = self._calculate_sell_price(base_price, reputation_modifier)

        player.remove_item(item.id)
        player.money += sell_price

        return {
            "success": True,
            "message": f"出售了{item.name}，获得{sell_price}文",
            "price": sell_price,
        }

    def _calculate_buy_price(self, base_price: int, reputation_modifier: float = 1.0) -> int:
        return max(1, int(base_price * ECONOMY_CONFIG["buy_price_ratio"] * reputation_modifier))

    def _calculate_sell_price(self, base_price: int, reputation_modifier: float = 1.0) -> int:
        return max(1, int(base_price * ECONOMY_CONFIG["sell_price_ratio"] * reputation_modifier))

    def get_combat_reward(self, enemy_level: int, enemy_money: int) -> Dict:
        base = ECONOMY_CONFIG["combat_money_base"] + enemy_level * ECONOMY_CONFIG["combat_money_per_level"]
        cap = int(enemy_money * ECONOMY_CONFIG["combat_money_cap_ratio"])
        money = min(base + cap, base * 3)
        return {"money": max(money, base)}

    def get_quest_reward(self, difficulty: int, quest_type: str = "") -> Dict:
        money = ECONOMY_CONFIG["quest_money_base"] + difficulty * ECONOMY_CONFIG["quest_money_per_difficulty"]
        return {"money": money}

    def inn_rest(self, player: Player) -> Dict:
        cost = ECONOMY_CONFIG["inn_cost"]
        if player.money < cost:
            return {"success": False, "message": f"银两不足，住店需要{cost}文"}

        player.money -= cost
        hp_restore = int(player.max_hp * ECONOMY_CONFIG["inn_hp_restore"])
        mp_restore = int(player.max_mp * ECONOMY_CONFIG["inn_mp_restore"])
        player.hp = min(player.max_hp, player.hp + hp_restore)
        player.mp = min(player.max_mp, player.mp + mp_restore)
        player.food = min(100, player.food + 30)
        player.water = min(100, player.water + 30)

        return {
            "success": True,
            "message": f"在客栈休息，花费{cost}文，恢复了体力",
            "hp_restored": hp_restore,
            "mp_restored": mp_restore,
            "cost": cost,
        }

    def donate_to_faction(self, player: Player, faction: Faction, amount: int) -> Dict:
        min_donation = ECONOMY_CONFIG["donation_min"]
        if amount < min_donation:
            return {"success": False, "message": f"最少捐赠{min_donation}文"}

        if player.money < amount:
            return {"success": False, "message": "银两不足"}

        player.money -= amount
        rep_gain = (amount // min_donation) * ECONOMY_CONFIG["donation_rep_gain"]

        return {
            "success": True,
            "message": f"向{FACTION_NAMES.get(faction, '未知门派')}捐赠{amount}文，获得{rep_gain}点声望",
            "rep_gain": rep_gain,
            "money_donated": amount,
        }

    def apply_death_penalty(self, player: Player) -> Dict:
        penalty_rate = ECONOMY_CONFIG["death_money_penalty"]
        penalty = int(player.money * penalty_rate)
        player.money -= penalty

        player.hp = int(player.max_hp * 0.3)
        player.mp = int(player.max_mp * 0.2)

        return {
            "money_lost": penalty,
            "message": f"你被击败了！损失{penalty}文银两",
        }

    def get_item_price_info(self, item: Item, reputation_modifier: float = 1.0) -> Dict:
        buy = self._calculate_buy_price(item.price, reputation_modifier)
        sell = self._calculate_sell_price(item.price, reputation_modifier)
        return {
            "name": item.name,
            "base_price": item.price,
            "buy_price": buy,
            "sell_price": sell,
        }


def get_economy_system() -> EconomySystem:
    return EconomySystem()
