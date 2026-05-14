#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
剧情系统 - Story System
深度剧情引擎，包含主线、支线、奇遇

特色:
1. 主线剧情 - 分章节推进、分支选择
2. 门派支线 - 各门派专属剧情
3. 随机奇遇 - 机缘事件、意外收获
4. NPC羁绊 - 好感度、师徒、情缘
5. 过场演出 - 剧情动画、对话演出
"""

import json
import random
from typing import List, Dict, Optional, Callable, Any
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path


class StoryPhase(Enum):
    """剧情阶段"""
    PROLOGUE = "prologue"       # 序章
    CHAPTER_1 = "chapter_1"     # 第一章
    CHAPTER_2 = "chapter_2"     # 第二章
    CHAPTER_3 = "chapter_3"     # 第三章
    CHAPTER_4 = "chapter_4"     # 第四章
    CHAPTER_5 = "chapter_5"     # 第五章
    EPILOGUE = "epilogue"       # 终章
    POST_GAME = "post_game"     # 结局后


class QuestStatus(Enum):
    """任务状态"""
    LOCKED = "locked"       # 未解锁
    AVAILABLE = "available" # 可接取
    ACTIVE = "active"       # 进行中
    COMPLETED = "completed" # 已完成
    FAILED = "failed"       # 已失败


@dataclass
class StoryChoice:
    """剧情选择"""
    id: str
    text: str
    effects: Dict[str, Any] = field(default_factory=dict)
    next_node: str = ""
    requirements: Dict[str, Any] = field(default_factory=dict)


@dataclass
class StoryNode:
    """剧情节点"""
    id: str
    text: str
    speaker: str = ""
    background: str = ""
    choices: List[StoryChoice] = field(default_factory=list)
    next_node: str = ""
    effects: Dict[str, Any] = field(default_factory=dict)
    is_end: bool = False


@dataclass
class Quest:
    """任务"""
    id: str
    name: str
    description: str
    status: QuestStatus = QuestStatus.LOCKED
    
    # 任务目标
    objectives: List[Dict] = field(default_factory=list)
    current_progress: Dict[str, int] = field(default_factory=dict)
    
    # 奖励
    rewards: Dict[str, int] = field(default_factory=dict)
    
    # 前置任务
    prerequisites: List[str] = field(default_factory=list)
    
    # 所属章节/门派
    chapter: str = ""
    faction: str = ""
    
    def is_complete(self) -> bool:
        """检查是否完成"""
        for obj in self.objectives:
            obj_id = obj.get("id", "")
            required = obj.get("count", 1)
            current = self.current_progress.get(obj_id, 0)
            if current < required:
                return False
        return True


@dataclass
class Encounter:
    """奇遇事件"""
    id: str
    name: str
    description: str
    rarity: int = 1  # 1-5, 越高越稀有
    
    # 触发条件
    conditions: Dict[str, Any] = field(default_factory=dict)
    
    # 选项
    choices: List[Dict] = field(default_factory=list)
    
    # 是否一次性
    one_time: bool = False
    triggered: bool = False


# 主线剧情数据
MAIN_STORY: Dict[str, StoryNode] = {
    "start": StoryNode(
        "start",
        "江湖传言，白金英雄坛的传说正在重现...",
        speaker="旁白",
        next_node="intro_1"
    ),
    "intro_1": StoryNode(
        "intro_1",
        "少年，你终于醒了。你在山脚下昏迷了三天三夜。",
        speaker="老者",
        background="village",
        next_node="intro_2"
    ),
    "intro_2": StoryNode(
        "intro_2",
        "这里是清河镇，你身上带着一本残破的武功秘籍，却记不起自己的来历。",
        speaker="老者",
        background="village",
        choices=[
            StoryChoice("ask_book", "请问这本秘籍是...", next_node="intro_book"),
            StoryChoice("ask_self", "我是谁...", next_node="intro_self"),
        ]
    ),
    "intro_book": StoryNode(
        "intro_book",
        "这本秘籍...似乎是八卦门的混元一气诀残卷。你与八卦门有什么渊源？",
        speaker="老者",
        next_node="choose_faction"
    ),
    "intro_self": StoryNode(
        "intro_self",
        "你身上没有半点信物，只有这本秘籍。或许找回秘籍的来历，就能找回你的过去。",
        speaker="老者",
        next_node="choose_faction"
    ),
    "choose_faction": StoryNode(
        "choose_faction",
        "江湖风云再起，各大门派都在寻找传人。你打算如何开始你的江湖之路？",
        speaker="旁白",
        choices=[
            StoryChoice("bagua", "前往八卦门", effects={"faction": "BAGUA"}, next_node="faction_bagua"),
            StoryChoice("flower", "前往百花谷", effects={"faction": "FLOWER"}, next_node="faction_flower"),
            StoryChoice("honglian", "前往红莲教", effects={"faction": "HONGLIAN"}, next_node="faction_honglian"),
            StoryChoice("wander", "独自闯荡", effects={"faction": "none"}, next_node="wander_start"),
        ]
    ),
    "faction_bagua": StoryNode(
        "faction_bagua",
        "八卦门位于清河镇北，以八卦掌、混元一气闻名江湖。",
        speaker="旁白",
        effects={"quest": "join_bagua"},
        is_end=True
    ),
    "faction_flower": StoryNode(
        "faction_flower",
        "百花谷隐于南方密林，花间派弟子皆是女子，武学飘逸如花。",
        speaker="旁白",
        effects={"quest": "join_flower"},
        is_end=True
    ),
    "faction_honglian": StoryNode(
        "faction_honglian",
        "红莲教总坛在长安城外，以义字当先，教众遍布江湖。",
        speaker="旁白",
        effects={"quest": "join_honglian"},
        is_end=True
    ),
    "wander_start": StoryNode(
        "wander_start",
        "你决定独自闯荡江湖，不依附任何门派。这条路更加艰难，却也更加自由。",
        speaker="旁白",
        effects={"fame": 10},
        is_end=True
    ),
}

# 门派支线任务
FACTION_QUESTS: Dict[str, List[Quest]] = {
    "BAGUA": [
        Quest(
            "bagua_intro", "拜入八卦门", "前往八卦门，拜见掌门",
            objectives=[{"id": "visit_sect", "type": "location", "target": "bagua_sect", "count": 1}],
            rewards={"exp": 100, "gold": 50, "reputation": 50},
            faction="BAGUA"
        ),
        Quest(
            "bagua_training", "八卦门试炼", "完成八卦门的入门试炼",
            prerequisites=["bagua_intro"],
            objectives=[
                {"id": "learn_skill", "type": "skill", "target": "bagua_zhang", "count": 1},
                {"id": "defeat_enemy", "type": "combat", "target": "any", "count": 3},
            ],
            rewards={"exp": 200, "gold": 100, "skill": "hunyuan_yiqi"},
            faction="BAGUA"
        ),
        Quest(
            "bagua_secret", "混元秘辛", "探查混元一气诀的秘密",
            prerequisites=["bagua_training"],
            objectives=[
                {"id": "find_clue", "type": "item", "target": "secret_letter", "count": 1},
                {"id": "talk_npc", "type": "dialog", "target": "elder_zhang", "count": 1},
            ],
            rewards={"exp": 500, "gold": 300, "item": "hunyuan_manual"},
            faction="BAGUA"
        ),
    ],
    "FLOWER": [
        Quest(
            "flower_intro", "百花谷入门", "前往百花谷，求见谷主",
            objectives=[{"id": "visit_sect", "type": "location", "target": "flower_sect", "count": 1}],
            rewards={"exp": 100, "gold": 50, "reputation": 50},
            faction="FLOWER"
        ),
        Quest(
            "flower_garden", "百花试炼", "在百花阵中找到出口",
            prerequisites=["flower_intro"],
            objectives=[{"id": "complete_puzzle", "type": "puzzle", "target": "flower_maze", "count": 1}],
            rewards={"exp": 200, "gold": 100, "skill": "flower_sword"},
            faction="FLOWER"
        ),
    ],
}

# 随机奇遇
RANDOM_ENCOUNTERS: List[Encounter] = [
    Encounter(
        "wounded_traveler", "受伤的旅人",
        "路边躺着一个受伤的旅人，似乎遭遇了山贼。",
        rarity=1,
        choices=[
            {"text": "施以援手", "effects": {"alignment": 5, "gold": -20, "item": "traveler_gift"}},
            {"text": "询问情况", "effects": {"info": "bandit_location"}},
            {"text": "置之不理", "effects": {"alignment": -2}},
        ]
    ),
    Encounter(
        "hidden_cache", "隐秘的宝箱",
        "在草丛中发现了一个隐秘的宝箱。",
        rarity=2,
        conditions={"luck": 10},
        choices=[
            {"text": "打开宝箱", "effects": {"gold": 100, "item": "random_treasure"}},
            {"text": "小心检查陷阱", "effects": {"gold": 80, "exp": 20}},
        ]
    ),
    Encounter(
        "martial_duel", "江湖切磋",
        "一位武林人士向你发起切磋邀请。",
        rarity=1,
        choices=[
            {"text": "接受切磋", "effects": {"combat": "duel", "fame": 5}},
            {"text": "婉言拒绝", "effects": {}},
        ]
    ),
    Encounter(
        "mysterious_hermit", "隐世高人",
        "深山中遇到一位隐世高人，似乎愿意指点你一二。",
        rarity=4,
        conditions={"fame": 100},
        choices=[
            {"text": "请教武学", "effects": {"exp": 200, "skill_exp": 50}},
            {"text": "请教内功", "effects": {"mp_bonus": 20}},
        ],
        one_time=True
    ),
    Encounter(
        "ancient_tomb", "古墓入口",
        "发现了一座古墓的入口，似乎隐藏着不为人知的秘密。",
        rarity=3,
        conditions={"luck": 20},
        choices=[
            {"text": "进入探索", "effects": {"location": "ancient_tomb"}},
            {"text": "标记位置离开", "effects": {"map_marker": "tomb"}},
        ],
        one_time=True
    ),
    Encounter(
        "bandit_ambush", "山贼伏击",
        "一伙山贼突然冲了出来！",
        rarity=1,
        choices=[
            {"text": "迎战", "effects": {"combat": "bandits"}},
            {"text": "交出财物", "effects": {"gold": -50}},
            {"text": "逃跑", "effects": {"hp": -20}},
        ]
    ),
    Encounter(
        "rare_herb", "珍稀草药",
        "发现了一株珍稀的草药。",
        rarity=2,
        conditions={"location": "wilderness"},
        choices=[
            {"text": "采集", "effects": {"item": "rare_herb"}},
            {"text": "仔细辨认", "effects": {"item": "identified_herb", "exp": 10}},
        ]
    ),
    Encounter(
        "beggar_request", "乞丐求助",
        "一个乞丐向你讨要食物。",
        rarity=1,
        choices=[
            {"text": "给予食物", "effects": {"alignment": 3, "gold": -5}},
            {"text": "询问消息", "effects": {"info": "city_rumor"}},
            {"text": "无视", "effects": {"alignment": -1}},
        ]
    ),
]


class StoryEngine:
    """剧情引擎"""
    
    def __init__(self):
        self.current_phase = StoryPhase.PROLOGUE
        self.current_node: Optional[StoryNode] = None
        self.story_flags: Dict[str, Any] = {}
        
        # 任务
        self.quests: Dict[str, Quest] = {}
        self.active_quests: List[str] = []
        
        # 已触发奇遇
        self.triggered_encounters: Set[str] = set()
        
        # 回调
        self.on_story_event: Optional[Callable] = None
        
        # 加载任务
        self._load_quests()
        
    def _load_quests(self) -> None:
        """加载任务"""
        for faction, quests in FACTION_QUESTS.items():
            for quest in quests:
                self.quests[quest.id] = quest
                
    def start_story(self, start_node: str = "start") -> None:
        """开始剧情"""
        self.current_node = MAIN_STORY.get(start_node)
        if self.current_node and self.on_story_event:
            self.on_story_event("node", self.current_node)
            
    def advance_story(self, choice_id: Optional[str] = None) -> Optional[StoryNode]:
        """推进剧情"""
        if not self.current_node:
            return None
            
        # 处理选择
        if choice_id and self.current_node.choices:
            for choice in self.current_node.choices:
                if choice.id == choice_id:
                    # 应用效果
                    self._apply_effects(choice.effects)
                    # 跳转到下一节点
                    if choice.next_node:
                        self.current_node = MAIN_STORY.get(choice.next_node)
                        break
            else:
                return None
        elif self.current_node.next_node:
            self.current_node = MAIN_STORY.get(self.current_node.next_node)
        else:
            return None
            
        # 应用节点效果
        if self.current_node:
            self._apply_effects(self.current_node.effects)
            if self.on_story_event:
                self.on_story_event("node", self.current_node)
                
        return self.current_node
        
    def _apply_effects(self, effects: Dict[str, Any]) -> None:
        """应用效果"""
        for key, value in effects.items():
            if key == "flag":
                self.story_flags[value] = True
            elif key == "quest":
                self.activate_quest(value)
            elif key == "faction":
                self.story_flags["player_faction"] = value
            elif key == "fame":
                self.story_flags["fame"] = self.story_flags.get("fame", 0) + value
                
            if self.on_story_event:
                self.on_story_event("effect", {key: value})
                
    def activate_quest(self, quest_id: str) -> bool:
        """激活任务"""
        quest = self.quests.get(quest_id)
        if not quest:
            return False
            
        # 检查前置
        for pre_id in quest.prerequisites:
            pre_quest = self.quests.get(pre_id)
            if not pre_quest or pre_quest.status != QuestStatus.COMPLETED:
                return False
                
        quest.status = QuestStatus.ACTIVE
        self.active_quests.append(quest_id)
        
        if self.on_story_event:
            self.on_story_event("quest_start", quest)
            
        return True
        
    def update_quest_progress(self, objective_type: str, target: str, count: int = 1) -> None:
        """更新任务进度"""
        for quest_id in self.active_quests:
            quest = self.quests.get(quest_id)
            if not quest:
                continue
                
            for obj in quest.objectives:
                if obj.get("type") == objective_type and obj.get("target") == target:
                    obj_id = obj.get("id", "")
                    quest.current_progress[obj_id] = quest.current_progress.get(obj_id, 0) + count
                    
                    if self.on_story_event:
                        self.on_story_event("quest_progress", {
                            "quest": quest,
                            "objective": obj_id,
                            "progress": quest.current_progress[obj_id]
                        })
                        
            # 检查完成
            if quest.is_complete():
                self.complete_quest(quest_id)
                
    def complete_quest(self, quest_id: str) -> bool:
        """完成任务"""
        quest = self.quests.get(quest_id)
        if not quest or quest.status != QuestStatus.ACTIVE:
            return False
            
        quest.status = QuestStatus.COMPLETED
        if quest_id in self.active_quests:
            self.active_quests.remove(quest_id)
            
        if self.on_story_event:
            self.on_story_event("quest_complete", quest)
            
        return True
        
    def check_random_encounter(self, conditions: Dict[str, Any]) -> Optional[Encounter]:
        """检查随机奇遇"""
        # 过滤可用奇遇
        available = []
        for encounter in RANDOM_ENCOUNTERS:
            # 检查是否已触发
            if encounter.one_time and encounter.id in self.triggered_encounters:
                continue
                
            # 检查条件
            can_trigger = True
            for cond_key, cond_value in encounter.conditions.items():
                if conditions.get(cond_key, 0) < cond_value:
                    can_trigger = False
                    break
                    
            if can_trigger:
                # 稀有度影响概率
                weight = 1.0 / encounter.rarity
                available.append((encounter, weight))
                
        if not available:
            return None
            
        # 加权随机选择
        total_weight = sum(w for _, w in available)
        r = random.random() * total_weight
        
        cumulative = 0.0
        for encounter, weight in available:
            cumulative += weight
            if r <= cumulative:
                if encounter.one_time:
                    self.triggered_encounters.add(encounter.id)
                return encounter
                
        return None
        
    def trigger_encounter_choice(self, encounter: Encounter, choice_index: int) -> Dict[str, Any]:
        """执行奇遇选择"""
        if choice_index >= len(encounter.choices):
            return {}
            
        choice = encounter.choices[choice_index]
        effects = choice.get("effects", {})
        
        # 标记已触发
        if encounter.one_time:
            self.triggered_encounters.add(encounter.id)
            
        if self.on_story_event:
            self.on_story_event("encounter", {
                "encounter": encounter,
                "choice": choice
            })
            
        return effects
        
    def get_faction_quests(self, faction: str) -> List[Quest]:
        """获取门派任务"""
        return [q for q in self.quests.values() if q.faction == faction]
        
    def get_available_quests(self) -> List[Quest]:
        """获取可接取任务"""
        return [q for q in self.quests.values() if q.status == QuestStatus.AVAILABLE]
        
    def get_active_quests(self) -> List[Quest]:
        """获取进行中任务"""
        return [self.quests[qid] for qid in self.active_quests if qid in self.quests]
