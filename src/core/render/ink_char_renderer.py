#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
水墨角色渲染器 - Ink Character Renderer
中国传统水墨画风格的角色绘制

特色:
1. 水墨人物轮廓 - 中锋勾勒
2. 衣袂飘动效果 - 侧锋渲染
3. 武器水墨风格 - 浓墨描绘
4. 动态笔触 - 随动作变化的笔触效果
"""

import math
import random
from typing import Tuple, List, Optional, Dict
from PIL import Image, ImageDraw, ImageFilter


class InkCharacterRenderer:
    """水墨角色渲染器"""
    
    def __init__(self, size: int = 64):
        self.size = size
        self.scale = 2
        self.ss = size * self.scale
        
    def _clamp(self, v: int) -> int:
        return max(0, min(255, v))
    
    def _draw_ink_line(self, draw: ImageDraw.ImageDraw,
                       x1: int, y1: int, x2: int, y2: int,
                       color: Tuple[int, int, int] = (30, 30, 30),
                       thickness: int = 2,
                       wetness: float = 0.6) -> None:
        """绘制水墨线条"""
        dx = x2 - x1
        dy = y2 - y1
        length = math.sqrt(dx * dx + dy * dy)
        if length < 1:
            return
            
        steps = int(length * 2)
        for i in range(steps):
            t = i / steps
            # 笔压变化
            pressure = math.sin(t * math.pi) * 0.5 + 0.5
            current_thickness = int(thickness * pressure)
            
            px = int(x1 + dx * t)
            py = int(y1 + dy * t)
            
            if current_thickness > 0:
                alpha = int(180 * wetness + 75)
                # 晕染效果
                if wetness > 0.5:
                    for layer in range(2):
                        lt = current_thickness + layer
                        la = alpha // (layer + 1)
                        draw.ellipse([px - lt, py - lt, px + lt, py + lt], fill=(*color, la))
                else:
                    draw.ellipse([px - current_thickness, py - current_thickness,
                                 px + current_thickness, py + current_thickness], fill=(*color, alpha))
    
    def _draw_ink_fill(self, draw: ImageDraw.ImageDraw,
                       points: List[Tuple[int, int]],
                       color: Tuple[int, int, int] = (100, 100, 100),
                       wetness: float = 0.7) -> None:
        """填充水墨区域"""
        if len(points) < 3:
            return
        alpha = int(150 * wetness + 50)
        draw.polygon(points, fill=(*color, alpha))
        # 轮廓
        outline_color = tuple(self._clamp(int(c * 0.6)) for c in color)
        for i in range(len(points)):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % len(points)]
            self._draw_ink_line(draw, x1, y1, x2, y2, outline_color, 1, wetness * 0.5)
    
    def generate_player_sprite(self, 
                               gender: str = "male",
                               faction: str = "BAGUA",
                               action: str = "stand",
                               direction: int = 0,
                               frame: int = 0,
                               seed: int = 0) -> Image.Image:
        """生成玩家角色水墨精灵
        
        Args:
            gender: 性别 male/female
            faction: 门派风格
            action: 动作 stand/walk/attack/hurt
            direction: 方向 0-7 (0=下, 2=左, 4=上, 6=右)
            frame: 动画帧
        """
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.ss, self.ss), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        cx, cy = self.ss // 2, self.ss // 2
        
        # 门派配色
        faction_colors = {
            "BAGUA": {"robe": (60, 50, 80), "sash": (180, 160, 60)},
            "FLOWER": {"robe": (180, 100, 140), "sash": (255, 220, 180)},
            "HONGLIAN": {"robe": (150, 40, 40), "sash": (200, 180, 60)},
            "NAJA": {"robe": (40, 60, 80), "sash": (100, 180, 140)},
            "TAIJI": {"robe": (240, 240, 240), "sash": (40, 40, 40)},
            "XUESHAN": {"robe": (220, 235, 250), "sash": (100, 150, 180)},
            "XIAOYAO": {"robe": (80, 140, 100), "sash": (200, 180, 100)},
        }
        colors = faction_colors.get(faction, faction_colors["BAGUA"])
        
        # 身体尺寸
        head_r = int(self.ss * 0.12)
        body_h = int(self.ss * 0.28)
        leg_h = int(self.ss * 0.22)
        arm_l = int(self.ss * 0.18)
        
        # 动作偏移
        walk_offset = 0
        if action == "walk":
            walk_offset = int(math.sin(frame * 0.5) * 4)
        elif action == "attack":
            walk_offset = int(math.sin(frame * 0.8) * 8)
        
        # === 头部 ===
        head_y = cy - body_h // 2 - head_r + walk_offset // 2
        # 头发 - 浓墨
        hair_color = (30, 25, 20) if gender == "male" else (25, 20, 15)
        hair_points = [
            (cx - head_r, head_y + head_r // 2),
            (cx, head_y - head_r),
            (cx + head_r, head_y + head_r // 2),
        ]
        self._draw_ink_fill(draw, hair_points, hair_color, 0.6)
        
        # 脸 - 淡墨留白
        face_color = (240, 220, 200)
        draw.ellipse([cx - head_r + 2, head_y - head_r + 4,
                     cx + head_r - 2, head_y + head_r + 2], fill=(*face_color, 200))
        # 脸轮廓
        self._draw_ink_line(draw, cx - head_r + 2, head_y, cx, head_y - head_r + 4, (80, 60, 50), 1, 0.4)
        self._draw_ink_line(draw, cx, head_y - head_r + 4, cx + head_r - 2, head_y, (80, 60, 50), 1, 0.4)
        
        # === 身体/衣袍 ===
        body_top = head_y + head_r
        body_bottom = body_top + body_h
        
        # 衣袍主体 - 水墨晕染
        robe_color = colors["robe"]
        robe_points = [
            (cx - self.ss // 6, body_top),
            (cx - self.ss // 5, body_bottom),
            (cx + self.ss // 5, body_bottom),
            (cx + self.ss // 6, body_top),
        ]
        self._draw_ink_fill(draw, robe_points, robe_color, 0.7)
        
        # 衣褶 - 中锋勾勒
        for i in range(-1, 2):
            fold_x = cx + i * 6
            self._draw_ink_line(draw, fold_x, body_top + 8, fold_x + i * 2, body_bottom - 4,
                               tuple(self._clamp(int(c * 0.7)) for c in robe_color), 1, 0.4)
        
        # 腰带
        sash_y = body_top + body_h // 2
        sash_color = colors["sash"]
        draw.rectangle([cx - self.ss // 5, sash_y - 2, cx + self.ss // 5, sash_y + 4], 
                      fill=(*sash_color, 200))
        
        # === 手臂 ===
        arm_color = tuple(self._clamp(int(c * 0.9)) for c in robe_color)
        # 左臂
        left_arm_points = [
            (cx - self.ss // 6, body_top + 4),
            (cx - self.ss // 4 - 4, body_top + arm_l // 2 + walk_offset),
            (cx - self.ss // 5, body_top + arm_l + walk_offset // 2),
        ]
        for i in range(len(left_arm_points) - 1):
            self._draw_ink_line(draw, left_arm_points[i][0], left_arm_points[i][1],
                               left_arm_points[i+1][0], left_arm_points[i+1][1],
                               arm_color, 3, 0.5)
        # 右臂
        right_arm_points = [
            (cx + self.ss // 6, body_top + 4),
            (cx + self.ss // 4 + 4, body_top + arm_l // 2 - walk_offset),
            (cx + self.ss // 5, body_top + arm_l - walk_offset // 2),
        ]
        for i in range(len(right_arm_points) - 1):
            self._draw_ink_line(draw, right_arm_points[i][0], right_arm_points[i][1],
                               right_arm_points[i+1][0], right_arm_points[i+1][1],
                               arm_color, 3, 0.5)
        
        # 手 - 淡墨
        hand_color = (230, 210, 190)
        left_hand_y = body_top + arm_l + walk_offset // 2
        right_hand_y = body_top + arm_l - walk_offset // 2
        draw.ellipse([cx - self.ss // 5 - 3, left_hand_y - 3,
                     cx - self.ss // 5 + 5, left_hand_y + 5], fill=(*hand_color, 180))
        draw.ellipse([cx + self.ss // 5 - 5, right_hand_y - 3,
                     cx + self.ss // 5 + 3, right_hand_y + 5], fill=(*hand_color, 180))
        
        # === 腿部 ===
        leg_top = body_bottom
        leg_color = tuple(self._clamp(int(c * 0.8)) for c in robe_color)
        
        # 行走动画
        left_leg_offset = walk_offset
        right_leg_offset = -walk_offset
        
        # 左腿
        self._draw_ink_line(draw, cx - 4, leg_top, cx - 6 + left_leg_offset, leg_top + leg_h,
                           leg_color, 4, 0.5)
        # 右腿
        self._draw_ink_line(draw, cx + 4, leg_top, cx + 6 + right_leg_offset, leg_top + leg_h,
                           leg_color, 4, 0.5)
        
        # 鞋 - 浓墨
        shoe_color = (40, 35, 30)
        left_foot_y = leg_top + leg_h
        right_foot_y = leg_top + leg_h
        draw.ellipse([cx - 10 + left_leg_offset, left_foot_y - 2,
                     cx + left_leg_offset, left_foot_y + 4], fill=(*shoe_color, 200))
        draw.ellipse([cx + right_leg_offset, right_foot_y - 2,
                     cx + 10 + right_leg_offset, right_foot_y + 4], fill=(*shoe_color, 200))
        
        # === 武器 (简化版) ===
        if action == "attack":
            # 剑 - 浓墨细线
            weapon_color = (180, 180, 190)
            weapon_x = cx + self.ss // 4 + 8
            weapon_y = right_hand_y
            # 剑身
            self._draw_ink_line(draw, weapon_x, weapon_y, weapon_x + 20, weapon_y - 15,
                               weapon_color, 2, 0.3)
            # 剑柄
            self._draw_ink_line(draw, weapon_x - 4, weapon_y + 4, weapon_x, weapon_y,
                               (100, 70, 50), 3, 0.5)
        
        # 缩小并应用效果
        img = img.resize((self.size, self.size), Image.LANCZOS)
        img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
        
        return img
    
    def generate_npc_sprite(self,
                           npc_type: str = "merchant",
                           action: str = "stand",
                           frame: int = 0,
                           seed: int = 0) -> Image.Image:
        """生成NPC水墨精灵"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.ss, self.ss), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        cx, cy = self.ss // 2, self.ss // 2
        
        # NPC类型配色
        npc_styles = {
            "merchant": {"robe": (150, 100, 60), "hat": True},
            "blacksmith": {"robe": (80, 60, 50), "hat": False, "apron": True},
            "herbalist": {"robe": (60, 100, 60), "hat": True},
            "guard": {"robe": (60, 60, 80), "hat": True, "armor": True},
            "monk": {"robe": (200, 160, 60), "hat": False},
            "scholar": {"robe": (180, 180, 200), "hat": True},
            "villager": {"robe": (120, 100, 80), "hat": False},
        }
        style = npc_styles.get(npc_type, npc_styles["villager"])
        
        # 基础尺寸
        head_r = int(self.ss * 0.11)
        body_h = int(self.ss * 0.26)
        leg_h = int(self.ss * 0.20)
        
        # 头部
        head_y = cy - body_h // 2 - head_r
        
        # 头发/帽子
        hair_color = (35, 30, 25)
        if style.get("hat"):
            # 帽子
            hat_points = [
                (cx - head_r - 2, head_y + 2),
                (cx, head_y - head_r - 4),
                (cx + head_r + 2, head_y + 2),
            ]
            self._draw_ink_fill(draw, hat_points, (60, 50, 40), 0.6)
        else:
            # 头发
            draw.ellipse([cx - head_r, head_y - head_r // 2, cx + head_r, head_y + head_r // 2],
                        fill=(*hair_color, 180))
        
        # 脸
        face_color = (235, 215, 195)
        draw.ellipse([cx - head_r + 3, head_y - head_r + 5, cx + head_r - 3, head_y + head_r],
                    fill=(*face_color, 200))
        
        # 身体
        body_top = head_y + head_r
        body_bottom = body_top + body_h
        
        robe_color = style["robe"]
        robe_points = [
            (cx - self.ss // 7, body_top),
            (cx - self.ss // 6, body_bottom),
            (cx + self.ss // 6, body_bottom),
            (cx + self.ss // 7, body_top),
        ]
        self._draw_ink_fill(draw, robe_points, robe_color, 0.7)
        
        # 围裙 (铁匠)
        if style.get("apron"):
            apron_color = (100, 80, 60)
            draw.rectangle([cx - self.ss // 8, body_top + 8, cx + self.ss // 8, body_bottom - 4],
                          fill=(*apron_color, 180))
        
        # 护甲 (守卫)
        if style.get("armor"):
            armor_color = (120, 120, 130)
            draw.rectangle([cx - self.ss // 9, body_top + 4, cx + self.ss // 9, body_top + body_h // 2],
                          fill=(*armor_color, 180))
        
        # 腿部
        leg_top = body_bottom
        leg_color = tuple(self._clamp(int(c * 0.75)) for c in robe_color)
        self._draw_ink_line(draw, cx - 4, leg_top, cx - 5, leg_top + leg_h, leg_color, 4, 0.5)
        self._draw_ink_line(draw, cx + 4, leg_top, cx + 5, leg_top + leg_h, leg_color, 4, 0.5)
        
        # 鞋
        shoe_y = leg_top + leg_h
        draw.ellipse([cx - 9, shoe_y - 2, cx - 1, shoe_y + 3], fill=(40, 35, 30, 200))
        draw.ellipse([cx + 1, shoe_y - 2, cx + 9, shoe_y + 3], fill=(40, 35, 30, 200))
        
        img = img.resize((self.size, self.size), Image.LANCZOS)
        return img


# 全局实例
_ink_char_renderer = None


def get_ink_char_renderer(size: int = 64) -> InkCharacterRenderer:
    global _ink_char_renderer
    if _ink_char_renderer is None:
        _ink_char_renderer = InkCharacterRenderer(size)
    return _ink_char_renderer
