#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完整的游戏功能测试脚本
测试所有核心系统：实体、战斗、经济、装备、任务等
"""
import sys
import os
from pathlib import Path

# 添加项目路径
sys.path.insert(0, str(Path(__file__).parent))

print("=" * 70)
print("🎮 侠影江湖 - 完整游戏测试")
print("=" * 70)
print()

def test_entities():
    """测试实体模块（玩家、食物/水分）"""
    print("📦 1. 测试实体模块...")
    from src.core.entities import Player, Item, Faction
    import time

    # 测试玩家初始化
    p = Player("测试侠客", 0, 0, 0, Faction.NONE, 20, 20, 20, 20)
    print(f"  ✅ 玩家创建: {p.name}")
    assert p.name == "测试侠客"
    assert p.hp == p.max_hp
    assert p.mp == p.max_mp
    assert p.food == 100.0
    assert p.water == 100.0

    # 测试食物/水分下降（修复后的核心 Bug 验证）
    initial_food = p.food
    initial_water = p.water
    # 模拟 1 秒时间流逝（60 帧，每帧 1/60 秒）
    for _ in range(60):
        p.update_food_water(1 / 60)
    delta_food = initial_food - p.food
    delta_water = initial_water - p.water

    print(f"  食物初始: {initial_food:.2f}, 1秒后: {p.food:.2f}, 下降: {delta_food:.4f}")
    print(f"  水分初始: {initial_water:.2f}, 1秒后: {p.water:.2f}, 下降: {delta_water:.4f}")

    # 验证下降速率正常（应该是 0.01/秒 和 0.015/秒）
    assert 0.008 < delta_food < 0.012, f"食物下降不正常: {delta_food}"
    assert 0.013 < delta_water < 0.017, f"水分下降不正常: {delta_water}"

    # 测试吃东西/喝水
    p.food = 50.0
    p.water = 50.0
    p.eat(20)
    p.drink(20)
    assert p.food == 70.0
    assert p.water == 70.0

    print("  ✅ 实体模块测试通过!")
    return True

def test_quest():
    """测试任务系统"""
    print("\n📜 2. 测试任务系统...")
    from src.core.quest import Quest, QuestStatus

    q = Quest("任务测试", "这是一个测试任务", 100, "测试物品")
    assert q.status == QuestStatus.ACTIVE
    q.complete()
    assert q.status == QuestStatus.COMPLETED
    print("  ✅ 任务系统测试通过!")
    return True

def test_economy():
    """测试经济系统"""
    print("\n💰 3. 测试经济系统...")
    from src.core.systems.economy import EconomySystem
    from src.core.entities import Player, Item

    economy = EconomySystem()
    p = Player("测试侠客", 0, 0, 0)
    p.gold = 100

    # 测试交易
    item = Item("测试物品", 10, 5, "测试物品")
    p.inventory.append(item)

    # 出售物品
    gold_before = p.gold
    economy.sell_item(p, item)
    assert p.gold == gold_before + item.sell_price
    assert item not in p.inventory

    # 购买物品（需要重新添加）
    p.gold = 200
    economy.buy_item(p, item)
    assert p.gold == 200 - item.buy_price
    assert item in p.inventory

    print("  ✅ 经济系统测试通过!")
    return True

def test_equipment():
    """测试装备系统"""
    print("\n⚔️  4. 测试装备系统...")
    from src.core.systems.equipment import EquipmentSystem
    from src.core.entities import Player, Equipment, EquipmentSlot, Faction

    p = Player("测试侠客", 0, 0, 0, Faction.NONE, 20, 20, 20, 20)
    equip_system = EquipmentSystem()

    # 测试装备武器
    weapon = Equipment(
        "测试钢剑", 100, 50, "一把好剑", EquipmentSlot.WEAPON,
        stats={"attack": 10, "strength": 2}
    )

    # 装备
    old_atk = p.total_attack
    equip_system.equip(p, weapon)
    assert weapon in p.equipment.values()
    assert p.equipment[EquipmentSlot.WEAPON] == weapon
    new_atk = p.total_attack
    assert new_atk > old_atk

    # 脱装备
    equip_system.unequip(p, EquipmentSlot.WEAPON)
    assert EquipmentSlot.WEAPON not in p.equipment
    assert p.total_attack == old_atk

    print("  ✅ 装备系统测试通过!")
    return True

def test_combat():
    """测试战斗系统"""
    print("\n⚔️  5. 测试战斗系统...")
    from src.core.combat_system import CombatSystem
    from src.core.entities import Player, Enemy, Faction

    p = Player("测试侠客", 0, 0, 0, Faction.NONE, 25, 25, 25, 25)
    e = Enemy("测试敌人", 0, 0, 0, 100, 10, 5, 5, 5)

    combat = CombatSystem()

    # 测试攻击
    p_old_hp = p.hp
    e_old_hp = e.hp

    combat.player_attack(p, e)
    assert e.hp < e_old_hp

    combat.enemy_attack(e, p)
    assert p.hp < p_old_hp

    print("  ✅ 战斗系统测试通过!")
    return True

def test_cultivation():
    """测试修炼系统"""
    print("\n🌟 6. 测试修炼系统...")
    from src.core.systems.cultivation_system import CultivationSystem
    from src.core.entities import Player, Faction

    p = Player("测试侠客", 0, 0, 0, Faction.NONE, 20, 20, 20, 20)
    cult = CultivationSystem()

    # 测试获取经验
    old_lvl = p.level
    cult.gain_experience(p, 50)
    assert p.exp == 50

    # 测试升级（需要足够经验）
    cult.gain_experience(p, 1000)
    assert p.level > old_lvl

    print("  ✅ 修炼系统测试通过!")
    return True

def test_world():
    """测试世界系统"""
    print("\n🌍 7. 测试世界系统...")
    from src.core.enhanced_world import get_enhanced_world

    w = get_enhanced_world()
    assert w is not None
    assert w.player is not None

    # 测试 NPC 存在
    assert len(w.npcs) > 0

    # 测试地图生成
    assert w.map_data is not None

    print("  ✅ 世界系统测试通过!")
    return True

def test_data_loader():
    """测试数据加载"""
    print("\n📊 8. 测试数据加载...")
    from src.core.data_loader import DataLoader

    loader = DataLoader()

    # 测试物品加载
    items = loader.load_items()
    assert len(items) > 0, "没有加载到任何物品"
    print(f"  加载物品: {len(items)} 个")

    # 测试 NPC 加载
    npcs = loader.load_npcs()
    assert len(npcs) > 0, "没有加载到任何 NPC"
    print(f"  加载 NPC: {len(npcs)} 个")

    # 测试剧情加载
    main_story = loader.load_main_story()
    assert main_story is not None, "没有加载到主剧情"
    print(f"  加载主剧情: {len(main_story) if isinstance(main_story, (list, dict)) else 'OK'}")

    print("  ✅ 数据加载测试通过!")
    return True

def run_tests():
    """运行所有测试"""
    tests = [
        ("实体模块", test_entities),
        ("任务系统", test_quest),
        ("经济系统", test_economy),
        ("装备系统", test_equipment),
        ("战斗系统", test_combat),
        ("修炼系统", test_cultivation),
        ("世界系统", test_world),
        ("数据加载", test_data_loader)
    ]

    results = []
    for name, func in tests:
        try:
            ok = func()
            results.append((name, ok))
        except Exception as e:
            print(f"  ❌ 测试失败: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))

    print()
    print("=" * 70)
    print("📊 测试结果摘要")
    print("=" * 70)
    for name, ok in results:
        print(f"  {'✅' if ok else '❌'} {name}")
    print(f"  总计: {sum(1 for _, ok in results if ok)}/{len(results)} 测试通过")
    print("=" * 70)

    return all(ok for _, ok in results)

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
