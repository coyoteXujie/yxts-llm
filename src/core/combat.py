import random
from typing import List, Optional, Dict
from .entities import Player, NPC, Skill


class CombatState:
    def __init__(self, player: Player, enemy: NPC):
        self.player = player
        self.enemy = enemy
        self.turn = "player"
        self.round = 1
        self.log = []

    def add_log(self, message: str):
        self.log.append(message)


class CombatSystem:
    def __init__(self):
        self.combat_state: Optional[CombatState] = None
        self.combat_log: List[str] = []

    def start_combat(self, player: Player, enemy: NPC) -> CombatState:
        self.combat_state = CombatState(player, enemy)
        self.combat_log = []
        self._add_combat_log(f"战斗开始！{player.name} VS {enemy.name}")
        return self.combat_state

    def _add_combat_log(self, message: str):
        self.combat_log.append(message)
        if self.combat_state:
            self.combat_state.add_log(message)

    def player_attack(self, skill: Optional[Skill] = None) -> Dict:
        if not self.combat_state or self.combat_state.turn != "player":
            return {"success": False, "message": "还没到你的回合"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        if skill:
            damage = self._calculate_damage(player.attack + skill.damage, enemy.defense, skill.accuracy)
        else:
            damage = self._calculate_damage(player.attack, enemy.defense, 0.8)

        if damage > 0:
            enemy.hp = max(0, enemy.hp - damage)
            message = f"{player.name}攻击{enemy.name}，造成{damage}点伤害！"
        else:
            message = f"{player.name}的攻击被{enemy.name}躲开了！"

        self._add_combat_log(message)
        self.combat_state.turn = "enemy"

        result = {"success": True, "message": message, "damage": damage, "enemy_hp": enemy.hp}
        
        if enemy.hp <= 0:
            result["victory"] = True
            result["exp_reward"] = enemy.exp_reward
            self._add_combat_log(f"胜利！{enemy.name}被击败！获得{enemy.exp_reward}经验")

        return result

    def enemy_attack(self) -> Dict:
        if not self.combat_state or self.combat_state.turn != "enemy":
            return {"success": False, "message": "还没到敌人回合"}

        player = self.combat_state.player
        enemy = self.combat_state.enemy

        damage = self._calculate_damage(enemy.attack, player.defense, 0.7)

        if damage > 0:
            player.hp = max(0, player.hp - damage)
            message = f"{enemy.name}攻击{player.name}，造成{damage}点伤害！"
        else:
            message = f"{enemy.name}的攻击被{player.name}躲开了！"

        self._add_combat_log(message)
        self.combat_state.turn = "player"
        self.combat_state.round += 1

        result = {"success": True, "message": message, "damage": damage, "player_hp": player.hp}
        
        if player.hp <= 0:
            result["defeat"] = True
            self._add_combat_log(f"失败！{player.name}被击败了...")

        return result

    def _calculate_damage(self, attack: int, defense: int, accuracy: float) -> int:
        if random.random() > accuracy:
            return 0
        
        base_damage = max(1, attack - defense // 2)
        variance = random.uniform(0.8, 1.2)
        return int(base_damage * variance)

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
        return self.player_attack(skill)

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

        flee_chance = 0.5 + (player.dexterity - enemy.dexterity) * 0.02
        
        if random.random() < flee_chance:
            self._add_combat_log(f"{player.name}成功逃离战斗！")
            self.combat_state = None
            return {"success": True, "message": "成功逃离战斗"}
        else:
            self._add_combat_log(f"{player.name}逃离失败！")
            self.combat_state.turn = "enemy"
            return {"success": False, "message": "逃离失败"}

    def get_combat_log(self) -> List[str]:
        return self.combat_log

    def is_in_combat(self) -> bool:
        return self.combat_state is not None

    def end_combat(self):
        self.combat_state = None
        self.combat_log = []