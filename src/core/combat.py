import random
from typing import List, Optional, Dict
from .entities import Player, NPC, Skill, Faction, FACTION_NAMES, NpcType
from .event import EventType, dispatch
from .systems.perform import get_perform_system
from .systems.equipment import get_equipment_system
from .systems.cultivation import get_cultivation_system
from .systems.economy import get_economy_system


COMBAT_STANCES = {
    "normal": {"attack_mult": 1.0, "defense_mult": 1.0, "hit_mult": 1.0, "flee_mult": 1.0, "name": "普通"},
    "aggressive": {"attack_mult": 1.3, "defense_mult": 0.7, "hit_mult": 0.9, "flee_mult": 0.8, "name": "猛攻"},
    "defensive": {"attack_mult": 0.7, "defense_mult": 1.3, "hit_mult": 1.0, "flee_mult": 1.2, "name": "防御"},
    "balanced": {"attack_mult": 1.1, "defense_mult": 1.1, "hit_mult": 1.0, "flee_mult": 1.0, "name": "均衡"},
}

CRIT_CHANCE = 0.1
CRIT_MULTIPLIER = 1.8

SKILL_TYPE_ADVANTAGE = {
    0: 2,  # 拳脚 克 棍法
    1: 0,  # 剑法 克 拳脚
    2: 1,  # 刀法 克 剑法
    6: 2,  # 棍法 克 刀法
    3: 6,  # 内功 克 棍法
}

ELEMENT_ADVANTAGE_MSG = {
    (0, 2): "拳脚克制棍法！",
    (1, 0): "剑法克制拳脚！",
    (2, 1): "刀法克制剑法！",
    (6, 2): "棍法克制刀法！",
    (3, 6): "内功压制棍法！",
}


class CombatState:
    def __init__(self, player: Player, enemy: NPC):
        self.player = player
        self.enemy = enemy
        self.turn = "player"
        self.round = 1
        self.log = []
        self.stance = "normal"
        self.combo_count = 0
        self.player_buffs: List[Dict] = []
        self.enemy_buffs: List[Dict] = []
        self.enemy_skill_cooldown: Dict[str, float] = {}
        self.enemy_stance = "normal"
        self.player_defending = False

    def add_log(self, message: str):
        self.log.append(message)

    def set_stance(self, stance: str):
        if stance in COMBAT_STANCES:
            self.stance = stance


class EnemyAI:
    def __init__(self, enemy: NPC):
        self.enemy = enemy
        self._pattern_counter = 0
        self._aggressive_threshold = 0.7
        self._defensive_threshold = 0.3

    def decide_action(self, combat_state: CombatState) -> Dict:
        enemy = combat_state.enemy
        hp_ratio = enemy.hp / enemy.max_hp if enemy.max_hp > 0 else 1.0

        if hp_ratio < self._defensive_threshold:
            return self._defensive_action(combat_state)
        elif hp_ratio > self._aggressive_threshold:
            return self._aggressive_action(combat_state)
        else:
            return self._balanced_action(combat_state, hp_ratio)

    def _aggressive_action(self, combat_state: CombatState) -> Dict:
        self._pattern_counter += 1
        if self._pattern_counter % 3 == 0 and self.enemy.mp >= 20:
            return {"action": "skill", "stance": "aggressive"}
        if self._pattern_counter % 5 == 0 and self.enemy.mp >= 30:
            return {"action": "heavy_attack", "stance": "aggressive"}
        return {"action": "attack", "stance": "aggressive"}

    def _defensive_action(self, combat_state: CombatState) -> Dict:
        if self.enemy.mp >= 15 and random.random() < 0.4:
            return {"action": "skill", "stance": "defensive"}
        if random.random() < 0.3:
            return {"action": "defend", "stance": "defensive"}
        return {"action": "attack", "stance": "defensive"}

    def _balanced_action(self, combat_state: CombatState, hp_ratio: float) -> Dict:
        roll = random.random()
        if roll < 0.15 and self.enemy.mp >= 20:
            return {"action": "skill", "stance": "normal"}
        if roll < 0.25:
            return {"action": "heavy_attack", "stance": "balanced"}
        if roll < 0.35:
            return {"action": "defend", "stance": "normal"}
        return {"action": "attack", "stance": "normal"}


class CombatSystem:
    def __init__(self):
        self.combat_state: Optional[CombatState] = None
        self.combat_log: List[str] = []
        self._performs_db = None
        self._items_db: Dict = {}
        self._enemy_ai: Optional[EnemyAI] = None

    def set_performs_db(self, performs_db: Dict):
        self._performs_db = performs_db

    def set_items_db(self, items_db: Dict):
        self._items_db = items_db

    def start_combat(self, player: Player, enemy: NPC) -> CombatState:
        self.combat_state = CombatState(player, enemy)
        self._enemy_ai = EnemyAI(enemy)
        self.combat_log = []
        self._add_combat_log(f"战斗开始！{player.name} VS {enemy.name}")
        return self.combat_state

    def _add_combat_log(self, message: str):
        self.combat_log.append(message)
        if self.combat_state:
            self.combat_state.add_log(message)

    def _get_stance(self) -> Dict:
        if self.combat_state:
            return COMBAT_STANCES.get(self.combat_state.stance, COMBAT_STANCES["normal"])
        return COMBAT_STANCES["normal"]

    def _get_enemy_stance(self) -> Dict:
        if self.combat_state:
            return COMBAT_STANCES.get(self.combat_state.enemy_stance, COMBAT_STANCES["normal"])
        return COMBAT_STANCES["normal"]

    def _get_total_attack(self, player: Player) -> int:
        equip_sys = get_equipment_system()
        base = equip_sys.get_total_attack(player, self._items_db)
        stance = self._get_stance()
        debuff = player.get_food_water_debuff()
        return int(base * stance["attack_mult"] * debuff["attack_mult"])

    def _get_total_defense(self, player: Player) -> int:
        equip_sys = get_equipment_system()
        base = equip_sys.get_total_defense(player, self._items_db)
        stance = self._get_stance()
        debuff = player.get_food_water_debuff()
        return int(base * stance["defense_mult"] * debuff["defense_mult"])

    def _check_element_advantage(self, attacker_skill_type: int, defender_skill_type: int) -> Optional[str]:
        if attacker_skill_type in SKILL_TYPE_ADVANTAGE:
            if SKILL_TYPE_ADVANTAGE[attacker_skill_type] == defender_skill_type:
                return ELEMENT_ADVANTAGE_MSG.get((attacker_skill_type, defender_skill_type))
        return None

    def player_attack(self, skill: Optional[Skill] = None) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        self.combat_state.player_defending = False

        total_attack = self._get_total_attack(player)
        enemy_defense = enemy.defense
        enemy_stance = self._get_enemy_stance()
        enemy_defense = int(enemy_defense * enemy_stance["defense_mult"])

        if skill:
            skill_mult = 1.0 + skill.level * 0.05
            attack_val = int(total_attack * skill_mult) + skill.damage
            accuracy = skill.accuracy
            advantage_msg = self._check_element_advantage(skill.type, 0)
            if advantage_msg:
                attack_val = int(attack_val * 1.2)
        else:
            attack_val = total_attack
            accuracy = 0.8
            advantage_msg = None

        stance = self._get_stance()
        accuracy *= stance["hit_mult"]

        damage, is_crit = self._calculate_damage(attack_val, enemy_defense, accuracy)

        self.combat_state.combo_count += 1
        combo_bonus = 0
        if self.combat_state.combo_count >= 3:
            combo_bonus = int(damage * 0.15 * (self.combat_state.combo_count - 2))
            damage += combo_bonus

        if damage > 0:
            enemy.hp = max(0, enemy.hp - damage)
            parts = []
            if is_crit:
                parts.append("暴击！")
            if combo_bonus > 0:
                parts.append(f"连击+{combo_bonus}")
            if advantage_msg:
                parts.append(advantage_msg)
            extra = "（" + "，".join(parts) + "）" if parts else ""
            message = f"{player.name}攻击{enemy.name}，造成{damage}点伤害！{extra}"
        else:
            self.combat_state.combo_count = 0
            message = f"{player.name}的攻击被{enemy.name}躲开了！"

        self._add_combat_log(message)
        self.combat_state.turn = "enemy"

        result = {"success": True, "message": message, "damage": damage, "enemy_hp": enemy.hp, "is_crit": is_crit}

        if enemy.hp <= 0:
            result["victory"] = True
            result.update(self._handle_victory(player, enemy))

        return result

    def use_skill(self, skill_id: str) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        player = self.combat_state.player
        skill = next((s for s in player.skills if s.id == skill_id), None)

        if not skill:
            return {"success": False, "message": "你没有这个技能"}

        mp_cost = skill.level * 2
        if player.mp < mp_cost:
            return {"success": False, "message": "内力不足"}

        player.mp -= mp_cost
        result = self.player_attack(skill)
        result["mp_cost"] = mp_cost
        result["skill_name"] = skill.name
        return result

    def player_defend(self) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        self.combat_state.player_defending = True
        player = self.combat_state.player
        cult_sys = get_cultivation_system()
        regen = cult_sys.get_inner_force_regen(player)
        mp_regen = int(regen * 3) + 5
        hp_regen = int(player.max_hp * 0.05)
        player.mp = min(player.max_mp, player.mp + mp_regen)
        player.hp = min(player.max_hp, player.hp + hp_regen)

        self._add_combat_log(f"{player.name}采取守势，恢复{hp_regen}生命、{mp_regen}内力")
        self.combat_state.turn = "enemy"
        return {
            "success": True,
            "message": f"采取守势，恢复{hp_regen}生命、{mp_regen}内力",
            "hp_regen": hp_regen,
            "mp_regen": mp_regen,
        }

    def use_perform(self, perform_id: str) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        if not self._performs_db:
            return {"success": False, "message": "绝招系统未初始化"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        self.combat_state.player_defending = False

        perform_sys = get_perform_system()
        result = perform_sys.use_perform(player, perform_id, self._performs_db, enemy.defense)

        if result["success"]:
            damage = result.get("damage", 0)
            if damage > 0:
                enemy.hp = max(0, enemy.hp - damage)
                self._add_combat_log(result["message"])

            self.combat_state.turn = "enemy"

            if enemy.hp <= 0:
                result["victory"] = True
                result.update(self._handle_victory(player, enemy))

        return result

    def set_stance(self, stance: str) -> Dict:
        if not self.combat_state:
            return {"success": False, "message": "不在战斗中"}

        if stance not in COMBAT_STANCES:
            return {"success": False, "message": "无效的战斗姿态"}

        self.combat_state.set_stance(stance)
        stance_name = COMBAT_STANCES[stance]["name"]
        self._add_combat_log(f"{self.combat_state.player.name}切换为【{stance_name}】姿态")
        return {"success": True, "message": f"切换为{stance_name}姿态", "stance": stance}

    def enemy_attack(self) -> Dict:
        if not self.combat_state or self.combat_state.turn != "enemy":
            return {"success": False, "message": "还没到敌人回合"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        if not self._enemy_ai:
            self._enemy_ai = EnemyAI(enemy)

        decision = self._enemy_ai.decide_action(self.combat_state)
        self.combat_state.enemy_stance = decision.get("stance", "normal")
        enemy_stance = self._get_enemy_stance()

        action = decision["action"]

        if action == "defend":
            return self._enemy_defend(enemy, player, enemy_stance)
        elif action == "skill":
            return self._enemy_skill_attack(enemy, player, enemy_stance)
        elif action == "heavy_attack":
            return self._enemy_heavy_attack(enemy, player, enemy_stance)
        else:
            return self._enemy_normal_attack(enemy, player, enemy_stance)

    def _enemy_normal_attack(self, enemy: NPC, player: Player, enemy_stance: Dict) -> Dict:
        total_defense = self._get_total_defense(player)
        if self.combat_state.player_defending:
            total_defense = int(total_defense * 1.5)

        enemy_attack_val = int(enemy.attack * enemy_stance["attack_mult"])
        accuracy = 0.7 * enemy_stance["hit_mult"]

        damage, is_crit = self._calculate_damage(enemy_attack_val, total_defense, accuracy)

        if damage > 0:
            player.hp = max(0, player.hp - damage)
            crit_text = "暴击！" if is_crit else ""
            message = f"{enemy.name}攻击{player.name}，造成{damage}点伤害！{crit_text}"
        else:
            message = f"{enemy.name}的攻击被{player.name}躲开了！"

        self._add_combat_log(message)
        self._end_enemy_turn(player)

        result = {"success": True, "message": message, "damage": damage, "player_hp": player.hp, "is_crit": is_crit, "enemy_action": "attack"}

        if player.hp <= 0:
            result["defeat"] = True
            result.update(self._handle_defeat(player, enemy))

        return result

    def _enemy_heavy_attack(self, enemy: NPC, player: Player, enemy_stance: Dict) -> Dict:
        total_defense = self._get_total_defense(player)
        if self.combat_state.player_defending:
            total_defense = int(total_defense * 1.5)

        enemy_attack_val = int(enemy.attack * enemy_stance["attack_mult"] * 1.5)
        accuracy = 0.55 * enemy_stance["hit_mult"]
        mp_cost = 15
        enemy.mp = max(0, enemy.mp - mp_cost)

        damage, is_crit = self._calculate_damage(enemy_attack_val, total_defense, accuracy)

        if damage > 0:
            player.hp = max(0, player.hp - damage)
            message = f"{enemy.name}使出全力一击！造成{damage}点伤害！"
        else:
            message = f"{enemy.name}全力一击落空了！"

        self._add_combat_log(message)
        self._end_enemy_turn(player)

        result = {"success": True, "message": message, "damage": damage, "player_hp": player.hp, "enemy_action": "heavy_attack"}

        if player.hp <= 0:
            result["defeat"] = True
            result.update(self._handle_defeat(player, enemy))

        return result

    def _enemy_skill_attack(self, enemy: NPC, player: Player, enemy_stance: Dict) -> Dict:
        total_defense = self._get_total_defense(player)
        if self.combat_state.player_defending:
            total_defense = int(total_defense * 1.5)

        skill_bonus = int(enemy.level * 1.5)
        enemy_attack_val = int((enemy.attack + skill_bonus) * enemy_stance["attack_mult"])
        accuracy = 0.75 * enemy_stance["hit_mult"]
        mp_cost = 20
        enemy.mp = max(0, enemy.mp - mp_cost)

        damage, is_crit = self._calculate_damage(enemy_attack_val, total_defense, accuracy)

        if damage > 0:
            player.hp = max(0, player.hp - damage)
            message = f"{enemy.name}使出绝技！造成{damage}点伤害！"
        else:
            message = f"{enemy.name}的绝技被{player.name}化解了！"

        self._add_combat_log(message)
        self._end_enemy_turn(player)

        result = {"success": True, "message": message, "damage": damage, "player_hp": player.hp, "enemy_action": "skill"}

        if player.hp <= 0:
            result["defeat"] = True
            result.update(self._handle_defeat(player, enemy))

        return result

    def _enemy_defend(self, enemy: NPC, player: Player, enemy_stance: Dict) -> Dict:
        hp_regen = int(enemy.max_hp * 0.05)
        mp_regen = 8
        enemy.hp = min(enemy.max_hp, enemy.hp + hp_regen)
        enemy.mp = min(enemy.max_mp, enemy.mp + mp_regen)

        message = f"{enemy.name}采取守势，恢复{hp_regen}生命"
        self._add_combat_log(message)
        self._end_enemy_turn(player)

        return {
            "success": True,
            "message": message,
            "damage": 0,
            "player_hp": player.hp,
            "enemy_action": "defend",
        }

    def _end_enemy_turn(self, player: Player):
        self.combat_state.turn = "player"
        self.combat_state.round += 1
        self._apply_inner_force_regen(player)

    def _apply_inner_force_regen(self, player: Player):
        cult_sys = get_cultivation_system()
        regen = cult_sys.get_inner_force_regen(player)
        if regen > 0 and player.mp < player.max_mp:
            player.mp = min(player.max_mp, player.mp + int(regen))

    def _calculate_damage(self, attack: int, defense: int, accuracy: float) -> tuple:
        if random.random() > accuracy:
            return 0, False

        reduction = defense * 0.6
        base_damage = max(1, attack - int(reduction))

        is_crit = random.random() < CRIT_CHANCE
        if is_crit:
            base_damage = int(base_damage * CRIT_MULTIPLIER)

        variance = random.uniform(0.85, 1.15)
        return int(base_damage * variance), is_crit

    def _handle_victory(self, player: Player, enemy: NPC) -> Dict:
        economy = get_economy_system()
        reward = economy.get_combat_reward(enemy.level, enemy.money)

        player.add_money(reward["money"])
        level_up = player.add_exp(enemy.exp_reward)
        player.total_kills += 1

        result_msg = f"胜利！{enemy.name}被击败！"
        result_msg += f" 获得{enemy.exp_reward}经验、{reward['money']}文银两"
        if level_up:
            result_msg += f" 升级到第{player.level}级！"
        self._add_combat_log(result_msg)

        dispatch(EventType.PLAYER_KILLED_NPC, {
            "npc_name": enemy.name,
            "npc_id": enemy.id,
            "npc_faction": enemy.faction.value,
            "npc_type": enemy.npc_type.value,
            "player_name": player.name,
            "exp_reward": enemy.exp_reward,
            "money_reward": reward["money"],
        })

        from .npc_brain import get_behavior_tracker
        tracker = get_behavior_tracker()
        tracker.record_kill(player.name, enemy)

        return {
            "exp_reward": enemy.exp_reward,
            "money_reward": reward["money"],
            "level_up": level_up,
        }

    def _handle_defeat(self, player: Player, enemy: NPC) -> Dict:
        economy = get_economy_system()
        penalty = economy.apply_death_penalty(player)
        player.total_deaths += 1

        self._add_combat_log(penalty["message"])

        dispatch(EventType.PLAYER_DEFEATED, {
            "player_name": player.name,
            "enemy_name": enemy.name,
            "money_lost": penalty["money_lost"],
        })

        return {
            "money_lost": penalty["money_lost"],
            "message": penalty["message"],
        }

    def use_item(self, item) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        player = self.combat_state.player
        result = player.use_item(item)

        if result:
            self._add_combat_log(result)
            self.combat_state.turn = "enemy"
            return {"success": True, "message": result}
        return {"success": False, "message": "使用物品失败"}

    def flee(self) -> Dict:
        if not self.combat_state:
            return {"success": False, "message": "不在战斗中"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        stance = self._get_stance()
        flee_chance = 0.5 + (player.dexterity - enemy.dexterity) * 0.02
        flee_chance *= stance["flee_mult"]

        if random.random() < flee_chance:
            self._add_combat_log(f"{player.name}成功逃离战斗！")
            self.combat_state = None
            return {"success": True, "message": "成功逃离战斗"}
        else:
            self._add_combat_log(f"{player.name}逃离失败！")
            self.combat_state.turn = "enemy"
            return {"success": False, "message": "逃离失败"}

    def get_available_performs(self) -> List[Dict]:
        if not self.combat_state or not self._performs_db:
            return []
        perform_sys = get_perform_system()
        return perform_sys.get_available_performs(self.combat_state.player, self._performs_db)

    def get_combat_info(self) -> Dict:
        if not self.combat_state:
            return {}
        state = self.combat_state
        stance = self._get_stance()
        enemy_stance = self._get_enemy_stance()
        return {
            "round": state.round,
            "turn": state.turn,
            "stance": state.stance,
            "stance_name": stance["name"],
            "enemy_stance_name": enemy_stance["name"],
            "combo_count": state.combo_count,
            "player_hp": state.player.hp,
            "player_max_hp": state.player.max_hp,
            "player_mp": state.player.mp,
            "player_max_mp": state.player.max_mp,
            "enemy_hp": state.enemy.hp,
            "enemy_max_hp": state.enemy.max_hp,
            "enemy_name": state.enemy.name,
            "player_defending": state.player_defending,
        }

    def get_combat_log(self) -> List[str]:
        return self.combat_log

    def is_in_combat(self) -> bool:
        return self.combat_state is not None

    def end_combat(self):
        self.combat_state = None
        self.combat_log = []
