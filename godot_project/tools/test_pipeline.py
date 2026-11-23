#!/usr/bin/env python3
"""
游戏逻辑全链路测试脚本
========================

模拟验证核心链路：NPC对话 → 接任务 → 战斗 → 奖励 → 升级 → 章节推进
不需要实际 Godot 运行环境，通过 JSON 数据交叉引用 + 逻辑模拟完成。

测试流程：
1. 数据完整性验证（JSON 引用是否存在/一致）
2. 任务领取流程模拟（NPC ↔ 任务 ↔ 前提条件）
3. 战斗→奖励→升级流程模拟（kill 类型任务）
4. 章节推进条件检查
"""

import json
import os
import sys
from typing import Any, Dict, List, Optional, Set, Tuple

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")


def load_json(filename: str) -> Any:
    path = os.path.join(DATA_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# ═══════════════════════════════════════════════════════════════
#  1. 数据完整性验证
# ═══════════════════════════════════════════════════════════════

class DataIntegrityCheck:
    """验证所有 JSON 引用的完整性和一致性"""

    def __init__(self):
        self.npcs: List[Dict] = load_json("npcs.json")
        self.quests: List[Dict] = load_json("quests.json")
        self.items: List[Dict] = load_json("items.json")
        self.dialogues: Dict = load_json("dialogues.json")
        self.regions: List[Dict] = load_json("regions.json")
        self.story_chapters: List[Dict] = load_json("story_chapters.json")

        # 构建索引
        self.npc_by_name = {n["name"]: n for n in self.npcs}
        self.npc_by_id = {n["id"]: n for n in self.npcs}
        self.quest_by_id = {q["id"]: q for q in self.quests}
        self.item_by_id = {i["id"]: i for i in self.items}
        self.region_by_id = {r["id"]: r for r in self.regions}

        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.passes: List[str] = []

    def ok(self, msg: str):
        self.passes.append(msg)
        print(f"  ✓ {msg}")

    def err(self, msg: str):
        self.errors.append(msg)
        print(f"  ✗ ERROR: {msg}")

    def warn(self, msg: str):
        self.warnings.append(msg)
        print(f"  ⚠ WARNING: {msg}")

    def check_quest_npc_references(self):
        """验证 quests.json 中 giver 对应 npcs.json 中的 NPC"""
        print("\n--- 任务 ↔ NPC 关联检查 ---")
        for q in self.quests:
            qid = q["id"]
            giver = q.get("giver", "")
            if giver and giver not in self.npc_by_name:
                self.err(f"任务 [{qid}] 的 giver 为 '{giver}'，但 NPC 列表中找不到")
            else:
                self.ok(f"任务 [{qid}] → NPC [{giver}]")

    def check_quest_prerequisites(self):
        """验证 quests.json 中 requires_completed 的 quest_id 都存在"""
        print("\n--- 任务前置条件检查 ---")
        for q in self.quests:
            qid = q["id"]
            prereqs = q.get("requires_completed", [])
            for prereq in prereqs:
                if prereq not in self.quest_by_id:
                    self.err(f"任务 [{qid}] 的前置任务 '{prereq}' 不存在")
                else:
                    self.ok(f"任务 [{qid}] → 前置 [{prereq}] ✓")

    def check_quest_reward_items(self):
        """验证奖励物品 ID 都在 items.json 中存在"""
        print("\n--- 任务奖励物品检查 ---")
        for q in self.quests:
            qid = q["id"]
            rewards = q.get("rewards", {})
            items = rewards.get("items", {})
            if not items:
                continue
            for item_id in items:
                if item_id not in self.item_by_id:
                    self.err(f"任务 [{qid}] 奖励物品 '{item_id}' 不存在")
                else:
                    self.ok(f"任务 [{qid}] 奖励物品 [{item_id}] ✓")

    def check_quest_kill_targets(self):
        """验证 kill 类型任务的目标在 npcs.json 中存在"""
        print("\n--- 战斗目标检查 ---")
        for q in self.quests:
            qid = q["id"]
            for obj in q.get("objectives", []):
                if obj["type"] == "kill":
                    target = obj["target"]
                    if target not in self.npc_by_name:
                        self.err(f"任务 [{qid}] kill 目标 '{target}' 不是已知 NPC")
                    elif self.npc_by_name[target].get("npc_type") != "enemy":
                        self.warn(f"任务 [{qid}] kill 目标 '{target}' 不是 enemy 类型（类型={self.npc_by_name[target].get('npc_type')}）")
                    else:
                        self.ok(f"任务 [{qid}] kill 目标 [{target}] (enemy) ✓")

    def check_quest_talk_targets(self):
        """验证 talk 类型任务的目标在 npcs.json 中存在"""
        print("\n--- 对话目标检查 ---")
        for q in self.quests:
            qid = q["id"]
            for obj in q.get("objectives", []):
                if obj["type"] == "talk":
                    target = obj["target"]
                    if target not in self.npc_by_name:
                        self.err(f"任务 [{qid}] talk 目标 '{target}' 不是已知 NPC")
                    else:
                        self.ok(f"任务 [{qid}] talk 目标 [{target}] ✓")

    def check_collect_targets(self):
        """验证 collect 类型任务的目标物品在 items.json 中存在"""
        print("\n--- 收集目标检查 ---")
        for q in self.quests:
            qid = q["id"]
            for obj in q.get("objectives", []):
                if obj["type"] == "collect":
                    target = obj["target"]
                    if target not in self.item_by_id:
                        self.err(f"任务 [{qid}] collect 目标物品 '{target}' 不存在")
                    else:
                        self.ok(f"任务 [{qid}] collect 目标 [{target}] ✓")

    def check_dialogue_npcs(self):
        """验证 dialogues.json 中的 NPC 都在 npcs.json 中有对应"""
        print("\n--- 对话 ↔ NPC 关联检查 ---")
        for npc_name in self.dialogues:
            if npc_name not in self.npc_by_name:
                self.err(f"对话文件中有 NPC '{npc_name}'，但 npcs.json 中不存在")
            else:
                self.ok(f"对话 [{npc_name}] ✓")

    def check_story_chapter_quests(self):
        """验证章节中的 critical_quests 都存在"""
        print("\n--- 章节关键任务检查 ---")
        for ch in self.story_chapters:
            ch_id = ch["id"]
            for qid in ch.get("critical_quests", []):
                if qid not in self.quest_by_id:
                    self.err(f"章节 [{ch_id}] 关键任务 '{qid}' 不存在")
                else:
                    self.ok(f"章节 [{ch_id}] → 关键任务 [{qid}] ✓")

    def check_story_event_quests(self):
        """验证章节事件中引用的任务都存在"""
        print("\n--- 章节事件条件检查 ---")
        for ch in self.story_chapters:
            ch_id = ch["id"]
            for evt in ch.get("events", []):
                trigger = evt.get("trigger", {})
                if trigger.get("kind") == "quest_completed":
                    qid = trigger.get("id", "")
                    if qid not in self.quest_by_id:
                        self.err(f"章节 [{ch_id}] 事件 [{evt.get('id')}] 引用的任务 '{qid}' 不存在")
                    else:
                        self.ok(f"章节 [{ch_id}] 事件 [{evt.get('id')}] → 任务 [{qid}] ✓")

    def check_story_event_enemies(self):
        """验证章节 battle 类型事件中的 enemy 在 npcs.json 中存在"""
        print("\n--- 章节敌人检查 ---")
        for ch in self.story_chapters:
            ch_id = ch["id"]
            for evt in ch.get("events", []):
                if evt.get("type") != "battle":
                    continue
                enemy = evt.get("enemy", {})
                eid = enemy.get("id", "")
                if eid and eid not in self.npc_by_name:
                    self.err(f"章节 [{ch_id}] 事件 [{evt.get('id')}] 敌人 '{eid}' 不存在")
                else:
                    self.ok(f"章节 [{ch_id}] 事件 [{evt.get('id')}] → 敌人 [{eid}] ✓")
                for minion in enemy.get("minions", []):
                    if minion not in self.npc_by_name:
                        self.err(f"章节 [{ch_id}] 事件 [{evt.get('id')}] 小兵 '{minion}' 不存在")
                    else:
                        self.ok(f"章节 [{ch_id}] 事件 [{evt.get('id')}] → 小兵 [{minion}] ✓")

    def check_npc_regions(self):
        """验证 NPC 所在的区域 tile 坐标对应 regions.json"""
        print("\n--- NPC 区域位置检查 ---")
        for npc in self.npcs:
            name = npc.get("name", "")
            px, py = npc.get("pos_x", -1), npc.get("pos_y", -1)
            found_region = False
            for region in self.regions:
                tiles = region.get("tiles", [])
                for tile in tiles:
                    tx, ty = tile.get("pos_x", 0), tile.get("pos_y", 0)
                    if px == tx and py == ty:
                        found_region = True
                        self.ok(f"NPC [{name}] 在区域 [{region['id']}] ✓")
                        break
                if found_region:
                    break
            if not found_region:
                self.warn(f"NPC [{name}] 坐标 ({px},{py}) 不在任何区域 tile 中")

    def run(self) -> bool:
        print("=" * 60)
        print("  数据完整性验证")
        print("=" * 60)
        self.check_quest_npc_references()
        self.check_quest_prerequisites()
        self.check_quest_reward_items()
        self.check_quest_kill_targets()
        self.check_quest_talk_targets()
        self.check_collect_targets()
        self.check_dialogue_npcs()
        self.check_story_chapter_quests()
        self.check_story_event_quests()
        self.check_story_event_enemies()
        self.check_npc_regions()

        print("\n" + "=" * 60)
        print(f"  结果: {len(self.passes)} 通过, {len(self.warnings)} 警告, {len(self.errors)} 错误")
        print("=" * 60)
        if self.errors:
            print(f"\n  发现的 {len(self.errors)} 个错误:")
            for e in self.errors:
                print(f"    ✗ {e}")
        return len(self.errors) == 0


# ═══════════════════════════════════════════════════════════════
#  2. 全链路模拟
# ═══════════════════════════════════════════════════════════════

class GamePipelineSimulator:
    """
    模拟完整的游戏逻辑链路：
    对话 → 接任务 → 杀敌 → 奖励 → 升级 → 章节推进
    """

    def __init__(self, quests: List[Dict], npcs: List[Dict], items: List[Dict],
                 chapters: List[Dict], dialogues: Dict):
        self.quest_by_id = {q["id"]: q for q in quests}
        self.npc_by_name = {n["name"]: n for n in npcs}
        self.item_by_id = {i["id"]: i for i in items}
        self.chapters = chapters
        self.dialogues = dialogues

        # 玩家状态
        self.player = {
            "level": 1,
            "exp": 0,
            "hp": 100,
            "max_hp": 100,
            "mp": 50,
            "max_mp": 50,
            "attack": 10,
            "defense": 5,
            "money": 0,
            "daode": 0,
        }

        # 游戏状态
        self.completed_quests: Set[str] = set()
        self.active_quests: Dict[str, Dict] = {}  # quest_id -> {objectives progress}
        self.inventory: Dict[str, int] = {}
        self.game_flags: Set[str] = set()
        self.completed_chapters: Set[str] = set()

        self.log: List[str] = []

    def log_step(self, msg: str):
        self.log.append(msg)
        print(f"    📝 {msg}")

    def progress_quest(self, qtype: str, target: str, count: int = 1):
        """模拟 GameState.progress_quest"""
        completed_any = False
        for qid, progress in list(self.active_quests.items()):
            quest = self.quest_by_id[qid]
            changed = False
            for obj in quest.get("objectives", []):
                if obj["type"] == qtype and obj["target"] == target:
                    okey = f"{obj['type']}:{obj['target']}"
                    current = progress["objectives"].get(okey, 0)
                    new_val = min(current + count, obj["count"])
                    if new_val != current:
                        progress["objectives"][okey] = new_val
                        changed = True
            if changed:
                self._check_quest_completion(qid, progress, quest)

    def _check_quest_completion(self, qid: str, progress: Dict, quest: Dict):
        all_done = all(
            progress["objectives"].get(f"{o['type']}:{o['target']}", 0) >= o["count"]
            for o in quest.get("objectives", [])
        )
        if all_done:
            self._complete_quest(qid, quest)

    def _complete_quest(self, qid: str, quest: Dict):
        rewards = quest.get("rewards", {})
        self.completed_quests.add(qid)
        del self.active_quests[qid]

        # 发放奖励
        exp_gain = rewards.get("exp", 0)
        money_gain = rewards.get("money", 0)
        daode_gain = rewards.get("daode", 0)

        self.player["exp"] += exp_gain
        self.player["money"] += money_gain
        self.player["daode"] += daode_gain

        self.log_step(f"任务 [{qid}] 完成! 经验+{exp_gain}, 金钱+{money_gain}, 道德+{daode_gain}")

        # 物品奖励
        for item_id, count in rewards.get("items", {}).items():
            self.inventory[item_id] = self.inventory.get(item_id, 0) + count
            item_name = self.item_by_id.get(item_id, {}).get("name", item_id)
            self.log_step(f"  → 获得物品 [{item_name}] ×{count}")

        # 升级检查
        self._check_level_up()

        # 处理剧情事件（任务完成触发）
        self._process_story_events("quest_completed", qid)

        # 章节推进检查
        self._check_chapter_progress()

        # 触发子任务
        self._trigger_derived_quests(qid)

    def _check_level_up(self):
        """模拟升级逻辑（与 game_state.gd 一致）"""
        while True:
            exp_needed = 30 + (self.player["level"] - 1) * 28
            if self.player["exp"] >= exp_needed:
                self.player["exp"] -= exp_needed
                self.player["level"] += 1
                self.player["attack"] += 3
                self.player["defense"] += 2
                self.player["max_hp"] += 18
                self.player["max_mp"] += 10
                self.player["hp"] = self.player["max_hp"]
                self.player["mp"] = self.player["max_mp"]
                self.log_step(f"⬆ 升级! 达到 Lv.{self.player['level']} (atk={self.player['attack']}, def={self.player['defense']}, hp={self.player['max_hp']})")
            else:
                break

    def _check_chapter_progress(self):
        """检查是否有章节可以推进"""
        for ch in self.chapters:
            ch_id = ch["id"]
            if ch_id in self.completed_chapters:
                continue
            prereqs = ch.get("prerequisites", {})
            if prereqs.get("level", 0) > self.player["level"]:
                continue
            if prereqs.get("completed_chapters"):
                for pc in prereqs["completed_chapters"]:
                    if pc not in self.completed_chapters:
                        continue
            if prereqs.get("quest_completed"):
                if prereqs["quest_completed"] not in self.completed_quests:
                    continue
            # 检查 completion_trigger 中的 check_flags
            ct = ch.get("completion_trigger", {})
            flags = ct.get("check_flags", [])
            if flags and not all(f in self.game_flags for f in flags):
                continue
            self.completed_chapters.add(ch_id)
            self.log_step(f"📖 章节 [{ch_id}: {ch['title']}] 完成!")

    def _process_story_events(self, trigger_kind: str, trigger_id: str):
        """处理剧情事件触发"""
        for ch in self.chapters:
            for evt in ch.get("events", []):
                trigger = evt.get("trigger", {})
                if trigger.get("kind") == trigger_kind and trigger.get("id") == trigger_id:
                    # 设置事件 flag
                    for flag in evt.get("outcomes", {}).get("set_flags", []):
                        self.game_flags.add(flag)
                    self.log_step(f"📖 剧情事件 [{evt['id']}] 触发 -> 标记 {evt.get('outcomes', {}).get('set_flags', [])}")

    def _trigger_derived_quests(self, completed_qid: str):
        """完成后检查是否有新任务可接"""
        for quest in self.quest_by_id.values():
            qid = quest["id"]
            if qid in self.completed_quests or qid in self.active_quests:
                continue
            prereqs = quest.get("requires_completed", [])
            if completed_qid in prereqs and all(p in self.completed_quests for p in prereqs):
                self.accept_quest(qid)

    def accept_quest(self, qid: str) -> bool:
        """模拟 GameState.accept_quest"""
        if qid in self.completed_quests:
            return False
        if qid in self.active_quests:
            return False

        quest = self.quest_by_id.get(qid)
        if not quest:
            return False

        # 检查 block reasons
        prereqs = quest.get("requires_completed", [])
        for p in prereqs:
            if p not in self.completed_quests:
                return False  # 前置任务未完成

        self.active_quests[qid] = {"objectives": {}}
        self.log_step(f"📋 接受任务 [{qid}: {quest['title']}]")
        for obj in quest.get("objectives", []):
            okey = f"{obj['type']}:{obj['target']}"
            self.active_quests[qid]["objectives"][okey] = 0
            self.log_step(f"     → {obj['label']}: 0/{obj['count']}")
        return True

    def run_pipeline(self):
        print("\n" + "=" * 60)
        print("  全链路流程模拟")
        print("=" * 60)
        steps_success = 0
        steps_total = 0

        def step(num: int, label: str, ok: bool):
            nonlocal steps_success, steps_total
            steps_total += 1
            if ok:
                steps_success += 1
                print(f"    [{num}/{total_steps}] ✓ {label}")
            else:
                print(f"    [{num}/{total_steps}] ✗ {label}")

        total_steps = 8  # we'll count them below

        # Step 1: NPC对话 → 接受 q_intro_town
        step(1, "对话 NPC [村长] 并接受任务 [初入平安镇]", self.accept_quest("q_intro_town"))

        # Step 2: Talk to NPCs for q_intro_town objectives
        self.progress_quest("talk", "平阿四", 1)
        self.progress_quest("talk", "捕快", 1)
        step(2, "与 NPC [平阿四, 捕快] 对话完成任务", "q_intro_town" in self.completed_quests)

        # 确认 q_clear_thugs 已自动接收（因为 q_intro_town 是它的前置）
        step(3, "自动接收后续任务 [镇东除恶]", "q_clear_thugs" in self.active_quests)

        # Step 4: Kill targets for q_clear_thugs
        self.progress_quest("kill", "流氓", 1)
        self.progress_quest("kill", "流氓头", 1)
        step(4, "击杀 [流氓, 流氓头] 完成战斗目标", "q_clear_thugs" in self.completed_quests)

        # Step 5: 奖励检查
        reward_ok = (self.inventory.get("item_shengji", 0) >= 1 and
                     self.player["money"] >= 120 and
                     self.player["daode"] >= 3)
        step(5, "任务奖励正确发放 (生肌散+金钱+道德)", reward_ok)

        # Step 6: 升级检查（q_clear_thugs 160exp + q_intro_town 80exp = 240exp，Lv2需要 30+28=58）
        level_ok = self.player["level"] >= 2
        step(6, f"经验足够时自动升级 (当前 Lv.{self.player['level']})", level_ok)

        # Step 7: 属性增长检查
        stat_ok = (self.player["attack"] >= 13 and
                   self.player["defense"] >= 7 and
                   self.player["max_hp"] >= 118)
        step(7, "升级后属性正确增长 (atk+3, def+2, hp+18/level)", stat_ok)

        # Step 8: 章节推进检查
        chapter_ok = "prologue" in self.completed_chapters
        step(8, "序章章节推进完成", chapter_ok)

        print(f"\n  {'=' * 50}")
        print(f"  模拟结果: {steps_success}/{steps_total} 步骤通过")
        print(f"  {'=' * 50}")
        return steps_success == steps_total

    def print_state(self):
        print(f"\n  --- 最终玩家状态 ---")
        print(f"  等级: Lv.{self.player['level']}")
        print(f"  经验: {self.player['exp']}/{30 + (self.player['level']-1) * 28}")
        print(f"  属性: ATK={self.player['attack']} DEF={self.player['defense']} HP={self.player['max_hp']} MP={self.player['max_mp']}")
        print(f"  金钱: {self.player['money']}  道德: {self.player['daode']}")
        print(f"  背包: {self.inventory}")
        print(f"  已完成任务 ({len(self.completed_quests)}): {sorted(self.completed_quests)}")
        print(f"  激活任务 ({len(self.active_quests)}): {sorted(self.active_quests)}")
        print(f"  已完成章节: {sorted(self.completed_chapters)}")


# ═══════════════════════════════════════════════════════════════
#  3. 数据差异审计（额外检查：已有 validate 工具不覆盖的内容）
# ═══════════════════════════════════════════════════════════════

def audit_npc_quest_consistency():
    """审计：NPC 的 has_quests 标志与 quests.json 中 giver 的实际分布是否一致"""
    print("\n--- NPC has_quests 标志一致性审计 ---")
    npcs = load_json("npcs.json")
    quests = load_json("quests.json")

    givers: Dict[str, int] = {}
    for q in quests:
        g = q.get("giver", "")
        if g:
            givers[g] = givers.get(g, 0) + 1

    issues = 0
    for npc in npcs:
        name = npc["name"]
        has_quests = bool(npc.get("has_quests", False))
        actually_gives = givers.get(name, 0) > 0
        if has_quests and not actually_gives:
            print(f"  ⚠ NPC [{name}] 标注 has_quests=true 但在 quests.json 中不是任何任务的 giver")
            issues += 1
        elif not has_quests and actually_gives:
            print(f"  ⚠ NPC [{name}] 标注 has_quests=false 但作为 {givers[name]} 个任务的 giver")
            issues += 1

    if issues == 0:
        print("  ✓ 所有 NPC has_quests 标志与任务 giver 分布一致")
    else:
        print(f"  发现 {issues} 个不一致")


def audit_dialogue_npc_existence():
    """审计：所有 NPC 都有对话数据（或至少有 fallback）"""
    print("\n--- NPC 对话数据覆盖审计 ---")
    npcs = load_json("npcs.json")
    dialogues = load_json("dialogues.json")

    missing = []
    for npc in npcs:
        name = npc["name"]
        if name not in dialogues:
            missing.append(name)

    if missing:
        print(f"  以下 {len(missing)} 个 NPC 没有专属对话数据（将使用 fallback）:")
        for name in missing[:10]:
            print(f"    • {name}")
        if len(missing) > 10:
            print(f"    ... 还有 {len(missing) - 10} 个")
    else:
        print("  ✓ 所有 NPC 都有对话数据")


def audit_quest_length():
    """审计：任务链长度和复杂度"""
    print("\n--- 任务链复杂度审计 ---")
    quests = load_json("quests.json")
    quest_by_id = {q["id"]: q for q in quests}

    # 计算依赖深度
    def calc_depth(qid: str, visited: Set[str] = None) -> int:
        if visited is None:
            visited = set()
        if qid in visited:
            return 0  # 循环依赖，不计数
        visited.add(qid)
        q = quest_by_id.get(qid)
        if not q:
            return 0
        prereqs = q.get("requires_completed", [])
        if not prereqs:
            return 1
        return 1 + max(calc_depth(p, visited) for p in prereqs)

    depths = {q["id"]: calc_depth(q["id"]) for q in quests}
    max_depth = max(depths.values())
    print(f"  任务总数: {len(quests)}")
    print(f"  最大依赖深度: {max_depth}")
    print(f"  浅层任务 (深度1): {sum(1 for d in depths.values() if d == 1)}")
    print(f"  中层任务 (深度2): {sum(1 for d in depths.values() if d == 2)}")
    print(f"  深层任务 (深度3+): {sum(1 for d in depths.values() if d >= 3)}")


# ═══════════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════════

def main():
    print("=" * 60)
    print("  游戏逻辑全链路验证工具")
    print("  验证范围: 任务→对话→战斗→奖励→升级→章节推进")
    print("=" * 60)

    # 1. 数据完整性
    print("\n╔════════════════════════════════════════════╗")
    print("║  阶段 1: 数据完整性验证                    ║")
    print("╚════════════════════════════════════════════╝")
    check = DataIntegrityCheck()
    data_ok = check.run()

    # 2. 额外审计
    print("\n╔════════════════════════════════════════════╗")
    print("║  阶段 2: 数据一致性审计                    ║")
    print("╚════════════════════════════════════════════╝")
    audit_npc_quest_consistency()
    audit_dialogue_npc_existence()
    audit_quest_length()

    # 3. 全链路模拟
    print("\n╔════════════════════════════════════════════╗")
    print("║  阶段 3: 全链路流程模拟                    ║")
    print("╚════════════════════════════════════════════╝")
    sim = GamePipelineSimulator(
        quests=load_json("quests.json"),
        npcs=load_json("npcs.json"),
        items=load_json("items.json"),
        chapters=load_json("story_chapters.json"),
        dialogues=load_json("dialogues.json"),
    )
    pipeline_ok = sim.run_pipeline()
    sim.print_state()

    # 汇总
    print("\n" + "=" * 60)
    print("  最终结果汇总")
    print("=" * 60)
    print(f"  数据完整性: {'✓ PASS' if data_ok else '✗ FAIL'}")
    print(f"  有        效   任   务: {len(check.quest_by_id)}")
    print(f"  有        效   NPC:  {len(check.npc_by_name)}")
    print(f"  有        效   物   品: {len(check.item_by_id)}")
    print(f"  章               节: {len(check.story_chapters)}")
    print(f"  全链路模拟:     {'✓ PASS' if pipeline_ok else '✗ FAIL'}")
    print("=" * 60)

    return 0 if (data_ok and pipeline_ok) else 1


if __name__ == "__main__":
    sys.exit(main())
