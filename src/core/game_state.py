#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""游戏全局状态管理 - 轻量级状态提取"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class GameState:
    """游戏全局状态管理"""
    # 游戏阶段
    current_state: str = "menu"  # "menu", "char_creation", "playing"
    
    # 战斗状态
    in_combat: bool = False
    combat_phase: str = "none"
    combat_log: List[str] = field(default_factory=list)
    combat_menu_idx: int = 0
    combat_skill_idx: int = 0
    combat_enemy_idx: int = 0
    combat_rewards: Optional[Dict] = None
    combat_anim_timer: float = 0.0
    
    # UI面板状态
    show_dialog: bool = False
    show_inventory: bool = False
    show_skill_panel: bool = False
    show_journal: bool = False
    show_minimap: bool = True
    show_shop: bool = False
    show_craft: bool = False
    
    # 对话状态
    dialog_text: str = ""
    dialog_title: str = ""
    dialog_type: str = "info"
    current_npc_id: Optional[int] = None
    player_input_mode: bool = False
    player_input_text: str = ""
    dialogue_options: List[str] = field(default_factory=list)
    
    # 移动状态
    movement: Dict[str, bool] = field(default_factory=lambda: {
        "up": False, "down": False, "left": False, "right": False
    })
    
    # 剧情/奇遇
    story_active: bool = False
    story_choice_idx: int = 0
    pending_encounter: Optional[object] = None
    encounter_display: bool = False
    encounter_cooldown: float = 0.0
    
    def reset_combat(self):
        self.in_combat = False
        self.combat_phase = "none"
        self.combat_log = []
        self.combat_rewards = None
    
    def close_all_panels(self):
        self.show_dialog = False
        self.show_inventory = False
        self.show_skill_panel = False
        self.show_journal = False
