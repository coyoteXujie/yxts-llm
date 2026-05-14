#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
战斗UI渲染器 - Combat UI Renderer
水墨风格的战斗界面

特色:
1. 水墨战斗场景背景
2. 角色立绘与状态条
3. 技能选择菜单
4. 战斗动画演出
"""

import math
import random
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from PIL import Image, ImageDraw, ImageFilter

from .combat_system import CombatPhase, Combatant, CombatAction, SKILLS_DATABASE


@dataclass
class CombatUIConfig:
    """战斗UI配置"""
    screen_width: int = 1440
    screen_height: int = 900
    
    # 玩家区域
    player_area_x: int = 100
    player_area_y: int = 500
    
    # 敌人区域
    enemy_area_x: int = 900
    enemy_area_y: int = 200
    
    # 菜单区域
    menu_x: int = 50
    menu_y: int = 700
    menu_width: int = 400
    menu_height: int = 180
    
    # 日志区域
    log_x: int = 500
    log_y: int = 700
    log_width: int = 440
    log_height: int = 180


class InkCombatRenderer:
    """水墨战斗渲染器"""
    
    def __init__(self, config: CombatUIConfig = None):
        self.config = config or CombatUIConfig()
        self.animation_frame = 0
        self.shake_offset = (0, 0)
        self.flash_alpha = 0
        
    def update(self, delta_time: float) -> None:
        """更新动画"""
        self.animation_frame += 1
        
        # 震动衰减
        if self.shake_offset != (0, 0):
            sx, sy = self.shake_offset
            self.shake_offset = (int(sx * 0.9), int(sy * 0.9))
            if abs(sx) < 1 and abs(sy) < 1:
                self.shake_offset = (0, 0)
                
        # 闪光衰减
        if self.flash_alpha > 0:
            self.flash_alpha = max(0, self.flash_alpha - 5)
            
    def trigger_shake(self, intensity: int = 10) -> None:
        """触发震动"""
        self.shake_offset = (random.randint(-intensity, intensity),
                            random.randint(-intensity, intensity))
        
    def trigger_flash(self) -> None:
        """触发闪光"""
        self.flash_alpha = 200
        
    def render_background(self, zone_type: str = "wilderness") -> Image.Image:
        """渲染战斗背景"""
        w, h = self.config.screen_width, self.config.screen_height
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 根据区域类型选择背景色调
        bg_colors = {
            "wilderness": (60, 80, 60),
            "city": (80, 70, 60),
            "town": (70, 75, 65),
            "sect": (65, 70, 80),
        }
        base_color = bg_colors.get(zone_type, (70, 70, 70))
        
        # 渐变背景
        for y in range(h):
            ratio = y / h
            c = tuple(int(base_color[i] * (0.6 + 0.4 * ratio)) for i in range(3))
            draw.line([(0, y), (w, y)], fill=(*c, 255))
            
        # 水墨晕染效果
        rng = random.Random(42)
        for _ in range(20):
            cx = rng.randint(0, w)
            cy = rng.randint(0, h)
            cr = rng.randint(50, 150)
            ca = rng.randint(20, 60)
            cc = tuple(int(base_color[i] * 0.8) for i in range(3))
            draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(*cc, ca))
            
        # 地面
        ground_y = int(h * 0.7)
        ground_color = tuple(int(base_color[i] * 0.7) for i in range(3))
        draw.rectangle([0, ground_y, w, h], fill=(*ground_color, 200))
        
        # 地面纹理
        for _ in range(30):
            gx = rng.randint(0, w)
            gy = rng.randint(ground_y, h)
            gl = rng.randint(10, 40)
            draw.line([(gx, gy), (gx + gl, gy)], fill=(*ground_color, 100), width=1)
            
        return img
        
    def render_combatant(self, combatant: Combatant, 
                        x: int, y: int,
                        is_enemy: bool = False) -> Image.Image:
        """渲染战斗单位"""
        # 角色大小
        char_w, char_h = 120, 180
        
        img = Image.new('RGBA', (char_w, char_h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 角色颜色
        if is_enemy:
            robe_color = (150, 60, 60)
            outline_color = (100, 40, 40)
        else:
            robe_color = (60, 80, 150)
            outline_color = (40, 60, 120)
            
        # 身体
        body_top = 40
        body_bottom = 140
        
        # 头部
        head_cx, head_cy = char_w // 2, 30
        head_r = 20
        draw.ellipse([head_cx - head_r, head_cy - head_r,
                     head_cx + head_r, head_cy + head_r],
                    fill=(230, 210, 190, 230))
        draw.ellipse([head_cx - head_r, head_cy - head_r,
                     head_cx + head_r, head_cy + head_r],
                    outline=(*outline_color, 150), width=2)
        
        # 身体
        body_points = [
            (char_w // 2 - 30, body_top),
            (char_w // 2 - 40, body_bottom),
            (char_w // 2 + 40, body_bottom),
            (char_w // 2 + 30, body_top),
        ]
        draw.polygon(body_points, fill=(*robe_color, 220))
        draw.polygon(body_points, outline=(*outline_color, 180), width=2)
        
        # 名字
        name_y = body_bottom + 10
        # (名字将在arcade中绘制)
        
        # HP条
        hp_bar_y = body_bottom + 30
        hp_bar_w = 80
        hp_bar_h = 8
        hp_bar_x = (char_w - hp_bar_w) // 2
        
        # HP条背景
        draw.rectangle([hp_bar_x, hp_bar_y, hp_bar_x + hp_bar_w, hp_bar_y + hp_bar_h],
                      fill=(60, 60, 60, 200))
        # HP条填充
        hp_fill = int(hp_bar_w * combatant.hp_percent)
        hp_color = (200, 60, 60) if combatant.hp_percent < 0.3 else (60, 200, 60)
        draw.rectangle([hp_bar_x, hp_bar_y, hp_bar_x + hp_fill, hp_bar_y + hp_bar_h],
                      fill=(*hp_color, 230))
        # HP条边框
        draw.rectangle([hp_bar_x, hp_bar_y, hp_bar_x + hp_bar_w, hp_bar_y + hp_bar_h],
                      outline=(200, 200, 200, 150), width=1)
        
        # MP条
        mp_bar_y = hp_bar_y + 12
        mp_bar_h = 4
        draw.rectangle([hp_bar_x, mp_bar_y, hp_bar_x + hp_bar_w, mp_bar_y + mp_bar_h],
                      fill=(60, 60, 60, 200))
        mp_fill = int(hp_bar_w * combatant.mp_percent)
        draw.rectangle([hp_bar_x, mp_bar_y, hp_bar_x + mp_fill, mp_bar_y + mp_bar_h],
                      fill=(60, 100, 200, 230))
                      
        # 状态效果
        if combatant.is_defending:
            # 防御光环
            draw.ellipse([10, 10, char_w - 10, char_h - 30],
                        outline=(100, 150, 255, 100), width=3)
                        
        if combatant.is_stunned:
            # 眩晕标记
            draw.text((char_w // 2 - 10, 5), "★", fill=(255, 200, 0, 230))
            
        return img
        
    def render_skill_menu(self, skills: List[str], selected: int = 0,
                         mp: int = 0) -> Image.Image:
        """渲染技能菜单"""
        w, h = self.config.menu_width, self.config.menu_height
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 背景 - 水墨风格
        draw.rectangle([0, 0, w, h], fill=(30, 35, 40, 220))
        draw.rectangle([0, 0, w, h], outline=(100, 100, 120, 200), width=2)
        
        # 标题
        draw.text((10, 5), "【武学招式】", fill=(220, 200, 160, 255))
        
        # 技能列表
        y = 35
        for i, skill_id in enumerate(skills[:6]):
            skill = SKILLS_DATABASE.get(skill_id)
            if not skill:
                continue
                
            # 选中高亮
            if i == selected:
                draw.rectangle([5, y - 2, w - 5, y + 22], fill=(60, 80, 100, 150))
                
            # 技能名称
            can_use = mp >= skill.mp_cost
            text_color = (220, 210, 190) if can_use else (100, 100, 100)
            draw.text((15, y), skill.name_zh, fill=(*text_color, 255))
            
            # 内力消耗
            mp_text = f"内力:{skill.mp_cost}"
            mp_color = (100, 150, 200) if can_use else (80, 80, 80)
            draw.text((w - 80, y), mp_text, fill=(*mp_color, 200))
            
            y += 25
            
        return img
        
    def render_action_menu(self, selected: int = 0) -> Image.Image:
        """渲染行动菜单"""
        w, h = 200, 150
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 背景
        draw.rectangle([0, 0, w, h], fill=(30, 35, 40, 220))
        draw.rectangle([0, 0, w, h], outline=(100, 100, 120, 200), width=2)
        
        actions = ["攻击", "武学", "物品", "防御", "逃跑"]
        
        y = 10
        for i, action in enumerate(actions):
            if i == selected:
                draw.rectangle([5, y - 2, w - 5, y + 22], fill=(60, 80, 100, 150))
            draw.text((20, y), action, fill=(220, 210, 190, 255))
            y += 26
            
        return img
        
    def render_battle_log(self, logs: List[str]) -> Image.Image:
        """渲染战斗日志"""
        w, h = self.config.log_width, self.config.log_height
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 背景
        draw.rectangle([0, 0, w, h], fill=(20, 25, 30, 200))
        draw.rectangle([0, 0, w, h], outline=(80, 80, 100, 180), width=1)
        
        # 日志文本
        y = h - 25
        for log in reversed(logs[-6:]):
            # 根据内容着色
            if "伤害" in log:
                color = (255, 150, 150)
            elif "胜利" in log:
                color = (150, 255, 150)
            elif "失败" in log:
                color = (255, 100, 100)
            else:
                color = (200, 200, 200)
                
            draw.text((10, y), log[:40], fill=(*color, 230))
            y -= 22
            if y < 10:
                break
                
        return img
        
    def render_damage_number(self, damage: int, x: int, y: int,
                            is_critical: bool = False) -> Image.Image:
        """渲染伤害数字"""
        text = str(damage)
        size = 32 if is_critical else 24
        w = len(text) * size // 2 + 20
        h = size + 10
        
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        color = (255, 50, 50) if damage > 0 else (50, 255, 50)
        
        # 阴影
        draw.text((3, 3), text, fill=(0, 0, 0, 150))
        # 主文字
        draw.text((0, 0), text, fill=(*color, 255))
        
        if is_critical:
            draw.text((len(text) * size // 4, -5), "暴击!", fill=(255, 200, 0, 255))
            
        return img
        
    def render_victory_screen(self, rewards: Dict) -> Image.Image:
        """渲染胜利画面"""
        w, h = 400, 300
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 背景
        draw.rectangle([0, 0, w, h], fill=(30, 50, 30, 230))
        draw.rectangle([0, 0, w, h], outline=(100, 200, 100, 200), width=3)
        
        # 标题
        draw.text((w // 2 - 50, 20), "战斗胜利!", fill=(200, 255, 200, 255))
        
        # 奖励
        y = 70
        if "exp" in rewards:
            draw.text((50, y), f"经验值: +{rewards['exp']}", fill=(220, 220, 150, 255))
            y += 30
        if "gold" in rewards:
            draw.text((50, y), f"银两: +{rewards['gold']}", fill=(220, 220, 150, 255))
            y += 30
        if "items" in rewards and rewards["items"]:
            draw.text((50, y), f"获得: {', '.join(rewards['items'])}", fill=(150, 220, 150, 255))
            
        return img
        
    def render_defeat_screen(self) -> Image.Image:
        """渲染失败画面"""
        w, h = 400, 200
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 背景
        draw.rectangle([0, 0, w, h], fill=(50, 30, 30, 230))
        draw.rectangle([0, 0, w, h], outline=(200, 100, 100, 200), width=3)
        
        # 标题
        draw.text((w // 2 - 50, 60), "战斗失败...", fill=(255, 150, 150, 255))
        draw.text((w // 2 - 80, 100), "将在最近城镇复活", fill=(200, 200, 200, 200))
        
        return img
