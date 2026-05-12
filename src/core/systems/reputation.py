from typing import Dict, Optional
from ..entities import Faction, FACTION_NAMES, Player, NPC, NpcType
from ..event import EventType, add_listener, dispatch


REPUTATION_TIERS = {
    -100: "死敌",
    -50: "敌对",
    -10: "冷淡",
    10: "中立",
    50: "友好",
    80: "崇敬",
    100: "崇拜",
}

REPUTATION_TIER_COLORS = {
    "死敌": (200, 50, 50),
    "敌对": (220, 100, 80),
    "冷淡": (180, 160, 140),
    "中立": (200, 200, 200),
    "友好": (100, 200, 100),
    "崇敬": (80, 180, 255),
    "崇拜": (255, 215, 0),
}

REPUTATION_MODIFIERS = {
    "shop_discount": {
        "死敌": 2.0,
        "敌对": 1.5,
        "冷淡": 1.2,
        "中立": 1.0,
        "友好": 0.9,
        "崇敬": 0.8,
        "崇拜": 0.7,
    },
    "sell_markup": {
        "死敌": 0.3,
        "敌对": 0.5,
        "冷淡": 0.7,
        "中立": 0.8,
        "友好": 0.9,
        "崇敬": 1.0,
        "崇拜": 1.1,
    },
    "quest_exp_bonus": {
        "死敌": 0.0,
        "敌对": 0.5,
        "冷淡": 0.8,
        "中立": 1.0,
        "友好": 1.2,
        "崇敬": 1.5,
        "崇拜": 2.0,
    },
}

REPUTATION_GAIN = {
    "kill_enemy_of_faction": 5,
    "kill_faction_npc": -15,
    "complete_faction_quest": 10,
    "donate_to_faction": 3,
    "help_faction_npc": 2,
    "betray_faction": -30,
    "join_faction": 20,
    "faction_ally_bonus": 3,
    "faction_enemy_penalty": -3,
}

FACTION_REPUTATION_DECAY_RATE = 0.01


class ReputationSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._factions = list(Faction)
            cls._instance._register_events()
        return cls._instance

    def _register_events(self):
        add_listener(EventType.PLAYER_KILLED_NPC, self._on_npc_killed)
        add_listener(EventType.QUEST_COMPLETED, self._on_quest_completed)

    def _on_npc_killed(self, event):
        npc_faction = event.data.get("npc_faction")
        npc_type = event.data.get("npc_type", "")
        player_name = event.data.get("player_name", "")
        if npc_faction is None or npc_faction == Faction.NONE.value:
            return
        faction = Faction(npc_faction)
        if npc_type == "enemy":
            for f in self._get_enemy_factions(faction):
                self._apply_reputation_change(player_name, f, REPUTATION_GAIN["kill_enemy_of_faction"])
        else:
            self._apply_reputation_change(player_name, faction, REPUTATION_GAIN["kill_faction_npc"])
            for ally in self._get_ally_factions(faction):
                self._apply_reputation_change(player_name, ally, REPUTATION_GAIN["faction_enemy_penalty"])

    def _on_quest_completed(self, event):
        issuer_faction = event.data.get("issuer_faction")
        player_name = event.data.get("player_name", "")
        if issuer_faction is not None and issuer_faction != Faction.NONE.value:
            faction = Faction(issuer_faction)
            self._apply_reputation_change(player_name, faction, REPUTATION_GAIN["complete_faction_quest"])

    def _get_ally_factions(self, faction: Faction) -> list:
        from ..llm_client import FACTION_RELATIONS
        key = faction.name
        if key in FACTION_RELATIONS:
            allies = FACTION_RELATIONS[key].get("allies", [])
            return [Faction[a] for a in allies if a in Faction.__members__]
        return []

    def _get_enemy_factions(self, faction: Faction) -> list:
        from ..llm_client import FACTION_RELATIONS
        key = faction.name
        if key in FACTION_RELATIONS:
            enemies = FACTION_RELATIONS[key].get("enemies", [])
            return [Faction[e] for e in enemies if e in Faction.__members__]
        return []

    def _apply_reputation_change(self, player_name: str, faction: Faction, amount: int):
        pass

    def get_reputation(self, player: Player, faction: Faction) -> int:
        return player.faction_rep.get(faction.value, 0)

    def set_reputation(self, player: Player, faction: Faction, value: int):
        player.faction_rep[faction.value] = max(-100, min(100, value))

    def add_reputation(self, player: Player, faction: Faction, amount: int) -> int:
        current = self.get_reputation(player, faction)
        new_val = max(-100, min(100, current + amount))
        player.faction_rep[faction.value] = new_val
        old_tier = self.get_tier(current)
        new_tier = self.get_tier(new_val)
        if old_tier != new_tier:
            direction = "提升" if amount > 0 else "下降"
            dispatch(EventType.REPUTATION_CHANGED, {
                "faction": faction.value,
                "faction_name": FACTION_NAMES.get(faction, '未知门派'),
                "old_tier": old_tier,
                "new_tier": new_tier,
                "direction": direction,
            })
        return new_val - current

    def get_tier(self, reputation: int) -> str:
        tier = "中立"
        for threshold, name in REPUTATION_TIERS.items():
            if reputation >= threshold:
                tier = name
        return tier

    def get_tier_color(self, tier: str) -> tuple:
        return REPUTATION_TIER_COLORS.get(tier, (200, 200, 200))

    def get_modifier(self, player: Player, faction: Faction, modifier_type: str) -> float:
        rep = self.get_reputation(player, faction)
        tier = self.get_tier(rep)
        modifiers = REPUTATION_MODIFIERS.get(modifier_type, {})
        return modifiers.get(tier, 1.0)

    def get_shop_price(self, player: Player, faction: Faction, base_price: int) -> int:
        modifier = self.get_modifier(player, faction, "shop_discount")
        return max(1, int(base_price * modifier))

    def get_sell_price(self, player: Player, faction: Faction, base_price: int) -> int:
        modifier = self.get_modifier(player, faction, "sell_markup")
        return max(1, int(base_price * modifier))

    def can_join_faction(self, player: Player, faction: Faction) -> bool:
        if player.faction != Faction.NONE:
            return False
        rep = self.get_reputation(player, faction)
        return rep >= 10

    def can_learn_skill(self, player: Player, faction: Faction) -> bool:
        if player.faction == faction:
            return True
        rep = self.get_reputation(player, faction)
        return rep >= 50

    def get_faction_attitude_toward_player(self, npc: NPC, player: Player) -> str:
        if npc.faction == Faction.NONE:
            return "neutral"
        rep = self.get_reputation(player, npc.faction)
        if rep >= 50:
            return "friendly"
        elif rep >= 10:
            return "warm"
        elif rep >= -10:
            return "neutral"
        elif rep >= -50:
            return "cold"
        else:
            return "hostile"

    def get_all_reputations(self, player: Player) -> Dict[int, Dict]:
        result = {}
        for faction in Faction:
            if faction == Faction.NONE:
                continue
            rep = self.get_reputation(player, faction)
            tier = self.get_tier(rep)
            result[faction.value] = {
                "name": FACTION_NAMES.get(faction, '未知门派'),
                "value": rep,
                "tier": tier,
                "color": self.get_tier_color(tier),
            }
        return result

    def on_join_faction(self, player: Player, faction: Faction):
        self.add_reputation(player, faction, REPUTATION_GAIN["join_faction"])
        for ally in self._get_ally_factions(faction):
            self.add_reputation(player, ally, REPUTATION_GAIN["faction_ally_bonus"])
        for enemy in self._get_enemy_factions(faction):
            self.add_reputation(player, enemy, REPUTATION_GAIN["faction_enemy_penalty"])

    def on_betray_faction(self, player: Player, faction: Faction):
        self.add_reputation(player, faction, REPUTATION_GAIN["betray_faction"])
        for ally in self._get_ally_factions(faction):
            self.add_reputation(player, ally, -10)


def get_reputation_system() -> ReputationSystem:
    return ReputationSystem()
