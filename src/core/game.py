import time
from typing import Dict, Optional
from .world import GameWorld
from .llm_client import get_llm_client
from .quest import get_quest_manager, Quest
from .event import dispatch, EventType


class Game:
    def __init__(self):
        self.world = GameWorld()
        self.running = True
        self.current_state = "menu"
        
        self._register_event_listeners()
    
    def _register_event_listeners(self):
        def on_quest_completed(event):
            quest_title = event.data.get("quest_title", "")
            print(f"\n\u597d\u6d3b\uff01\u4efb\u52a1【{quest_title}】\u5df2\u5b8c\u6210\uff01")
        
        from .event import add_listener, EventType
        add_listener(EventType.QUEST_COMPLETED, on_quest_completed)

    def start(self):
        self.running = True
        self._main_menu()
    
    def _main_menu(self):
        print("=" * 60)
        print("          白金英雄坛说")
        print("=" * 60)
        print("1. 开始新游戏")
        print("2. 读取存档")
        print("3. 退出游戏")
        print("=" * 60)
        
        choice = input("请输入选择: ")
        
        if choice == "1":
            self._create_character()
        elif choice == "2":
            print("读取存档功能开发中...")
            self._main_menu()
        elif choice == "3":
            self.running = False
        else:
            print("无效选择，请重新输入")
            self._main_menu()
    
    def _create_character(self):
        print("\n=== 创建角色 ===")
        name = input("请输入角色名称: ")
        if name:
            self.world.player.name = name
        
        print("\n请选择性别:")
        print("1. 男")
        print("2. 女")
        gender_choice = input("请输入选择: ")
        self.world.player.gender = "male" if gender_choice == "1" else "female"
        
        print("\n请分配属性点（每项1-15，建议平均分配）:")
        self.world.player.strength = self._get_attribute_input("臂力", 1, 15, 10)
        self.world.player.dexterity = self._get_attribute_input("身法", 1, 15, 10)
        self.world.player.intelligence = self._get_attribute_input("悟性", 1, 15, 10)
        self.world.player.constitution = self._get_attribute_input("根骨", 1, 15, 10)
        
        self.world.player.setup_attr()
        print("\n角色创建完成！")
        print(f"姓名: {self.world.player.name}")
        print(f"等级: {self.world.player.level}")
        print(f"生命: {self.world.player.hp}/{self.world.player.max_hp}")
        print(f"内力: {self.world.player.mp}/{self.world.player.max_mp}")
        print(f"攻击: {self.world.player.attack}")
        print(f"防御: {self.world.player.defense}")
        input("按回车键开始游戏...")
        
        self.current_state = "playing"
        self._game_loop()
    
    def _get_attribute_input(self, attr_name: str, min_val: int, max_val: int, default: int) -> int:
        while True:
            try:
                value = int(input(f"{attr_name} ({min_val}-{max_val}): "))
                if min_val <= value <= max_val:
                    return value
                print(f"请输入{min_val}到{max_val}之间的数值")
            except ValueError:
                print("请输入有效数字")
    
    def _game_loop(self):
        while self.running and self.current_state == "playing":
            self._print_status()
            self._handle_input()
            self.world.update(0.1)
    
    def _print_status(self):
        player = self.world.player
        print(f"\n【{player.name}】等级:{player.level} 生命:{player.hp}/{player.max_hp} 内力:{player.mp}/{player.max_mp}")
        print(f"臂力:{player.strength} 身法:{player.dexterity} 悟性:{player.intelligence} 根骨:{player.constitution}")
        print(f"金钱:{player.money} 潜能:{player.pot} 道德:{player.daode}")
        print(f"位置: ({int(player.position.x)}, {int(player.position.y)})")
        print(f"时间: 第{self.world.game_day}天 {self.world.game_hour:02d}:00")
    
    def _handle_input(self):
        print("\n=== 操作菜单 ===")
        print("移动: n(北) s(南) e(东) w(西)")
        print("交互: t(对话) f(战斗) b(背包) q(任务)")
        print("其他: m(地图) h(帮助) x(退出)")
        
        choice = input("请输入操作: ").lower()
        
        if choice in ['n', 's', 'e', 'w']:
            self._move(choice)
        elif choice == 't':
            self._talk_to_npc()
        elif choice == 'f':
            self._start_combat()
        elif choice == 'b':
            self._open_inventory()
        elif choice == 'q':
            self._show_quests()
        elif choice == 'm':
            self._show_map()
        elif choice == 'h':
            self._show_help()
        elif choice == 'x':
            self._confirm_exit()
        else:
            print("无效操作，请重新输入")
    
    def _move(self, direction: str):
        dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
        self.world.move_player(dir_map[direction])
        
        nearby_npcs = self.world.get_npcs_nearby(self.world.player.position, radius=40)
        if nearby_npcs:
            print(f"\n附近发现: {', '.join(npc.name for npc in nearby_npcs)}")

    def _talk_to_npc(self):
        nearby_npcs = self.world.get_npcs_nearby(self.world.player.position, radius=40)
        
        if not nearby_npcs:
            print("附近没有可以对话的人")
            return
        
        print("\n附近的人:")
        for i, npc in enumerate(nearby_npcs):
            print(f"{i+1}. {npc.name} - {npc.description}")
        
        try:
            choice = int(input("选择对话对象: ")) - 1
            if 0 <= choice < len(nearby_npcs):
                self._dialogue_with_npc(nearby_npcs[choice])
            else:
                print("无效选择")
        except ValueError:
            print("请输入数字")

    def _dialogue_with_npc(self, npc):
        print(f"\n你走近{npc.name}...")
        
        dispatch(EventType.PLAYER_TALKED_TO_NPC, {"npc_name": npc.name, "npc_id": npc.id})
        
        llm_client = get_llm_client()
        player_info = {
            "name": self.world.player.name,
            "level": self.world.player.level,
            "faction": self.world.player.faction.value,
            "faction_name": self.world.player.faction.name,
            "daode": self.world.player.daode,
            "strength": self.world.player.strength,
            "dexterity": self.world.player.dexterity,
            "intelligence": self.world.player.intelligence,
            "constitution": self.world.player.constitution
        }
        
        response = llm_client.generate_dialogue_response(npc.get_info_dict(), player_info)
        print(response)
        
        if npc.has_quests:
            self._show_npc_quests(npc)
    
    def _show_npc_quests(self, npc):
        quest_manager = get_quest_manager()
        quest_manager.generate_quests_for_npc(npc, self.world.player, count=2)
        available_quests = quest_manager.get_available_quests_for_npc(npc.id, self.world.player)
        
        if available_quests:
            print(f"\n{npc.name}有以下任务可以接取:")
            for i, quest in enumerate(available_quests):
                print(f"\n{i+1}. 【{quest.title}】")
                print(f"   难度: {'★' * quest.difficulty}{'☆' * (5 - quest.difficulty)}")
                print(f"   要求等级: {quest.level_requirement}")
                print(f"   {quest.description}")
                print(f"   奖励: 银两{quest.reward.get('money', 0)} 经验{quest.reward.get('exp', 0)}")
            
            try:
                choice = int(input("\n选择要接取的任务编号（0跳过）: "))
                if 0 < choice <= len(available_quests):
                    selected = available_quests[choice - 1]
                    if quest_manager.accept_quest(selected, self.world.player):
                        print(f"\n已接取任务【{selected.title}】")
                    else:
                        print("接取任务失败")
            except ValueError:
                pass

    def _start_combat(self):
        nearby_npcs = self.world.get_npcs_nearby(self.world.player.position, radius=40)
        enemies = [npc for npc in nearby_npcs if npc.npc_type == 'enemy']
        
        if not enemies:
            print("附近没有敌人")
            return
        
        print("\n附近的敌人:")
        for i, enemy in enumerate(enemies):
            print(f"{i+1}. {enemy.name} - 等级{enemy.level}")
        
        try:
            choice = int(input("选择要攻击的敌人: ")) - 1
            if 0 <= choice < len(enemies):
                self._combat_loop(enemies[choice])
            else:
                print("无效选择")
        except ValueError:
            print("请输入数字")

    def _combat_loop(self, enemy):
        self.world.start_combat(enemy)
        print(f"\n=== 战斗开始 ===")
        
        while self.world.is_in_combat():
            for log in self.world.get_combat_log()[-3:]:
                print(log)
            
            player = self.world.player
            enemy = self.world.combat_system.combat_state.enemy
            print(f"\n{player.name}: {player.hp}/{player.max_hp} HP | {player.mp}/{player.max_mp} MP")
            print(f"{enemy.name}: {enemy.hp}/{enemy.max_hp} HP")
            
            print("\n战斗操作:")
            print("a. 普通攻击")
            print("s. 使用技能")
            print("i. 使用物品")
            print("f. 逃跑")
            
            choice = input("选择操作: ").lower()
            
            if choice == 'a':
                result = self.world.combat_system.player_attack()
                print(result["message"])
                if result.get("victory"):
                    self._handle_victory(result)
                    break
                elif not result["success"]:
                    print(result["message"])
            elif choice == 's':
                self._use_skill_in_combat()
            elif choice == 'i':
                self._use_item_in_combat()
            elif choice == 'f':
                result = self.world.combat_system.flee()
                print(result["message"])
                if result["success"]:
                    break
            
            if self.world.is_in_combat():
                enemy_result = self.world.combat_system.enemy_attack()
                print(enemy_result["message"])
                if enemy_result.get("defeat"):
                    self._handle_defeat()
                    break
    
    def _use_skill_in_combat(self):
        player = self.world.player
        attack_skills = [s for s in player.skills if s.type in [0, 1]]
        
        if not attack_skills:
            print("没有可用的攻击技能")
            return
        
        print("\n可用技能:")
        for i, skill in enumerate(attack_skills):
            mp_cost = skill.level * 2
            print(f"{i+1}. {skill.name} (等级{skill.level}) - 消耗{mp_cost}内力")
        
        try:
            choice = int(input("选择技能: ")) - 1
            if 0 <= choice < len(attack_skills):
                result = self.world.combat_system.use_skill(attack_skills[choice].id)
                print(result["message"])
                if result.get("victory"):
                    self._handle_victory(result)
        except ValueError:
            print("请输入数字")

    def _use_item_in_combat(self):
        player = self.world.player
        
        if not player.inventory:
            print("背包是空的")
            return
        
        print("\n背包物品:")
        items = []
        for item_id, count in player.inventory.items():
            item = self.world.get_item_by_id(item_id)
            if item:
                items.append(item)
                print(f"{len(items)}. {item.name} x{count}")
        
        if not items:
            print("没有可用的物品")
            return
        
        try:
            choice = int(input("选择物品: ")) - 1
            if 0 <= choice < len(items):
                result = self.world.combat_system.use_item(items[choice])
                print(result["message"])
        except ValueError:
            print("请输入数字")

    def _handle_victory(self, result):
        exp_reward = result.get("exp_reward", 0)
        print(f"\n胜利！获得{exp_reward}经验")
        level_up = self.world.player.add_exp(exp_reward)
        if level_up:
            print(f"\u5feb\u4e50\uff01\u4f60\u5347\u7ea7\u5230\u7b2c{self.world.player.level}级！")
        
        dispatch(EventType.PLAYER_KILLED_NPC, {"npc_name": self.world.combat_system.combat_state.enemy.name})
        
        self.world.combat_system.end_combat()

    def _handle_defeat(self):
        print("\n你被击败了...")
        self.world.player.hp = self.world.player.max_hp // 2
        self.world.player.mp = self.world.player.max_mp // 2
        self.world.combat_system.end_combat()

    def _open_inventory(self):
        player = self.world.player
        
        print("\n=== 背包 ===")
        print(f"金钱: {player.money} 两")
        
        if player.inventory:
            print("\n物品:")
            for item_id, count in player.inventory.items():
                item = self.world.get_item_by_id(item_id)
                if item:
                    print(f"  {item.name} x{count} - {item.description}")
        else:
            print("\n背包是空的")
        
        self._buy_from_shop()
    
    def _buy_from_shop(self):
        nearby_npcs = self.world.get_npcs_nearby(self.world.player.position, radius=40)
        traders = [npc for npc in nearby_npcs if npc.npc_type == 'trader']
        
        if traders:
            print(f"\n附近的商店: {', '.join(t.name for t in traders)}")
            try:
                buy = input("是否要购买物品？(y/n): ").lower()
                if buy == 'y':
                    trader = traders[0]
                    print(f"\n{trader.name}的商店:")
                    for i, item_id in enumerate(trader.sell_items):
                        item = self.world.get_item_by_id(item_id)
                        if item:
                            print(f"{i+1}. {item.name} - {item.price}两 - {item.description}")
                    
                    choice = int(input("\n选择要购买的物品编号: ")) - 1
                    if 0 <= choice < len(trader.sell_items):
                        item_id = trader.sell_items[choice]
                        item = self.world.get_item_by_id(item_id)
                        if item and self.world.player.money >= item.price:
                            self.world.player.add_money(-item.price)
                            self.world.player.add_item(item_id)
                            print(f"购买成功！已获得{item.name}")
                        else:
                            print("购买失败")
            except ValueError:
                pass

    def _show_quests(self):
        quest_manager = get_quest_manager()
        active_quests = quest_manager.get_active_quests()
        completed_quests = quest_manager.get_completed_quests()
        
        print("\n=== 任务 ===")
        
        if active_quests:
            print("\n进行中的任务:")
            for i, quest in enumerate(active_quests):
                progress = f"{quest.current_count}/{quest.count}"
                print(f"\n{i+1}. 【{quest.title}】")
                print(f"   {quest.description}")
                print(f"   进度: {progress}")
                
                nearby_npc = self.world.get_npc_by_id(quest.issuer_npc_id)
                if nearby_npc:
                    distance = self.world.player.position.distance_to(nearby_npc.position)
                    if distance < 40:
                        print("   \u63d0\u793a: 任务发布者就在附近，可以交付任务")
        else:
            print("\n没有进行中的任务")
        
        if completed_quests:
            print(f"\n已完成任务: {len(completed_quests)}个")

    def _show_map(self):
        print(f"\n=== 当前地图: {self.world.current_map.name} ===")
        print(self.world.current_map.description)
        print(f"\n出口: {', '.join(self.world.current_map.exits.keys())}")
        
        player = self.world.player
        print(f"\n你的位置: ({int(player.position.x)}, {int(player.position.y)})")
        
        nearby_npcs = self.world.get_npcs_nearby(player.position, radius=100)
        if nearby_npcs:
            print("\n附近的人物:")
            for npc in nearby_npcs:
                dist = int(player.position.distance_to(npc.position))
                print(f"  {npc.name} - 距离{dist}")

    def _show_help(self):
        print("\n=== 帮助 ===")
        print("移动指令:")
        print("  n - 向北")
        print("  s - 向南")
        print("  e - 向东")
        print("  w - 向西")
        print("\n交互指令:")
        print("  t - 对话（靠近NPC后使用）")
        print("  f - 战斗（靠近敌人后使用）")
        print("  b - 打开背包/商店")
        print("  q - 查看任务")
        print("  m - 查看地图")
        print("  h - 显示帮助")
        print("  x - 退出游戏")
        print("\n战斗指令:")
        print("  a - 普通攻击")
        print("  s - 使用技能")
        print("  i - 使用物品")
        print("  f - 逃跑")
        input("\n按回车键继续...")

    def _confirm_exit(self):
        confirm = input("确定要退出游戏吗？(y/n): ").lower()
        if confirm == 'y':
            self.running = False
            print("游戏结束，感谢游玩！")