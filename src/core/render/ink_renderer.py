#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
水墨渲染引擎 - Ink Wash Rendering Engine
打造中国传统水墨画风格的画面效果

核心特性:
1. 笔触纹理 - 模拟毛笔笔触的粗细变化
2. 晕染效果 - 水墨晕开的自然过渡
3. 留白意境 - 中国画的留白美学
4. 干湿浓淡 - 水墨的四种变化
"""

import math
import random
from typing import Tuple, List, Optional, Dict
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance


class InkBrush:
    """水墨笔刷 - 模拟毛笔效果"""
    
    def __init__(self, size: int = 64):
        self.size = size
        self.scale = 2  # 超采样
        self.ss = size * self.scale
        
    def _clamp(self, v: int, lo: int = 0, hi: int = 255) -> int:
        return max(lo, min(hi, v))
    
    def draw_brush_stroke(self, draw: ImageDraw.ImageDraw,
                          x1: int, y1: int, x2: int, y2: int,
                          color: Tuple[int, int, int] = (30, 30, 30),
                          thickness: int = 4,
                          wetness: float = 0.5,
                          pressure: float = 1.0) -> None:
        """绘制一笔水墨笔触
        
        Args:
            draw: PIL ImageDraw对象
            x1, y1: 起点坐标
            x2, y2: 终点坐标
            color: 墨色 (RGB)
            thickness: 笔触粗细
            wetness: 湿度 0-1 (湿则晕染，干则飞白)
            pressure: 笔压 0-1 (影响粗细变化)
        """
        dx = x2 - x1
        dy = y2 - y1
        length = math.sqrt(dx * dx + dy * dy)
        if length < 1:
            return
            
        steps = int(length * 2)
        for i in range(steps):
            t = i / steps
            # 笔压变化 - 起笔轻，中段重，收笔轻
            pressure_curve = math.sin(t * math.pi) * pressure + 0.3
            current_thickness = int(thickness * pressure_curve)
            
            # 位置
            px = int(x1 + dx * t)
            py = int(y1 + dy * t)
            
            # 湿度影响透明度
            base_alpha = int(200 * wetness + 55 * (1 - wetness))
            
            # 绘制笔触点
            if current_thickness > 0:
                # 飞白效果 - 干笔时出现断续
                if wetness < 0.4 and random.random() < (0.4 - wetness):
                    continue
                    
                # 晕染效果 - 湿笔时边缘模糊
                if wetness > 0.6:
                    for layer in range(3):
                        layer_thickness = current_thickness + layer * 2
                        layer_alpha = base_alpha // (layer + 1)
                        draw.ellipse([
                            px - layer_thickness, py - layer_thickness,
                            px + layer_thickness, py + layer_thickness
                        ], fill=(*color, layer_alpha))
                else:
                    draw.ellipse([
                        px - current_thickness, py - current_thickness,
                        px + current_thickness, py + current_thickness
                    ], fill=(*color, base_alpha))
    
    def draw_ink_wash(self, draw: ImageDraw.ImageDraw,
                      cx: int, cy: int, radius: int,
                      color: Tuple[int, int, int] = (30, 30, 30),
                      density: float = 0.7,
                      wetness: float = 0.8) -> None:
        """绘制水墨晕染块
        
        Args:
            draw: PIL ImageDraw对象
            cx, cy: 中心点
            radius: 半径
            color: 墨色
            density: 墨色浓度 0-1
            wetness: 湿度 0-1
        """
        # 晕染层数
        layers = 5
        for layer in range(layers):
            layer_radius = int(radius * (1 + layer * 0.3))
            layer_alpha = int(150 * density * (1 - layer / layers) * wetness)
            
            # 随机偏移模拟自然晕染
            offset_x = random.randint(-3, 3) if wetness > 0.5 else 0
            offset_y = random.randint(-3, 3) if wetness > 0.5 else 0
            
            draw.ellipse([
                cx - layer_radius + offset_x, cy - layer_radius + offset_y,
                cx + layer_radius + offset_x, cy + layer_radius + offset_y
            ], fill=(*color, layer_alpha))


class InkTextureGenerator:
    """水墨纹理生成器"""
    
    def __init__(self, tile_size: int = 64):
        self.ts = tile_size
        self.scale = 2
        self.sts = tile_size * self.scale
        self.brush = InkBrush(tile_size)
        
    def _clamp(self, v: int) -> int:
        return max(0, min(255, v))
    
    def generate_ink_grass(self, seed: int = 0) -> Image.Image:
        """生成水墨风格的草地"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 底色 - 淡墨渲染
        base_color = (80, 120, 60)
        for y in range(0, self.sts, self.scale):
            for x in range(0, self.sts, self.scale):
                # 水墨晕染底色
                noise = rng.gauss(0, 15)
                c = tuple(self._clamp(int(base_color[i] + noise)) for i in range(3))
                alpha = int(rng.randint(180, 220))
                draw.rectangle([x, y, x + self.scale, y + self.scale], fill=(*c, alpha))
        
        # 水墨草叶 - 侧锋撇出
        for _ in range(25):
            gx = rng.randint(4, self.sts - 4)
            gy = rng.randint(self.sts // 3, self.sts - 4)
            gh = rng.randint(8, 20)
            lean = rng.randint(-6, 6)
            
            # 草叶颜色 - 浓墨或淡墨
            ink_density = rng.random()
            grass_color = (
                self._clamp(60 + int(40 * ink_density)),
                self._clamp(100 + int(30 * ink_density)),
                self._clamp(40 + int(30 * ink_density))
            )
            
            # 绘制草叶笔触
            x1, y1 = gx, gy
            x2, y2 = gx + lean, gy - gh
            self.brush.draw_brush_stroke(draw, x1, y1, x2, y2,
                                        color=grass_color,
                                        thickness=rng.randint(1, 3),
                                        wetness=rng.uniform(0.3, 0.6),
                                        pressure=rng.uniform(0.6, 1.0))
        
        # 留白效果 - 随机擦除一些区域
        for _ in range(5):
            wx = rng.randint(8, self.sts - 8)
            wy = rng.randint(8, self.sts - 8)
            wr = rng.randint(4, 8)
            draw.ellipse([wx - wr, wy - wr, wx + wr, wy + wr], fill=(0, 0, 0, 0))
        
        # 缩小并应用轻微模糊
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
        return img
    
    def generate_ink_water(self, seed: int = 0, anim_frame: int = 0) -> Image.Image:
        """生成水墨风格的水面"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 水面底色 - 淡墨渲染
        base_color = (50, 80, 120)
        for y in range(0, self.sts, self.scale):
            for x in range(0, self.sts, self.scale):
                # 水波光影
                wave = math.sin((x + anim_frame * 4) * 0.08) * 0.3 + \
                       math.sin((y + anim_frame * 3) * 0.06) * 0.2
                noise = rng.gauss(0, 10)
                c = tuple(self._clamp(int(base_color[i] + noise + int(wave * 20))) for i in range(3))
                alpha = int(self._clamp(int(180 + wave * 30)))
                draw.rectangle([x, y, x + self.scale, y + self.scale], fill=(*c, alpha))
        
        # 水墨水纹 - 中锋勾勒
        for i in range(4):
            wy = int((self.sts * (i + 1) / 5 + anim_frame * 2) % self.sts)
            wave_offset = int(math.sin(anim_frame * 0.2 + i) * 6)
            
            # 水纹颜色 - 淡墨
            wave_color = (70, 100, 140)
            
            # 绘制水纹线条
            for x in range(4, self.sts - 4, self.scale):
                offset = int(math.sin((x + wave_offset) * 0.15 + anim_frame * 0.1) * 3)
                alpha = int(rng.randint(40, 80))
                draw.rectangle([x, wy + offset, x + self.scale, wy + offset + self.scale],
                              fill=(*wave_color, alpha))
        
        # 留白 - 水面高光
        for _ in range(3):
            hx = rng.randint(16, self.sts - 16)
            hy = rng.randint(16, self.sts - 16)
            hr = rng.randint(6, 12)
            phase = anim_frame * 0.1 + rng.random() * 6.28
            alpha = int(30 + 20 * math.sin(phase))
            draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(200, 220, 240, alpha))
        
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        return img
    
    def generate_ink_stone_road(self, seed: int = 0) -> Image.Image:
        """生成水墨风格的石板路"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 石板底色 - 淡墨
        base_color = (140, 135, 125)
        draw.rectangle([0, 0, self.sts, self.sts], fill=(*base_color, 230))
        
        # 石板分块 - 浓墨勾勒
        stone_blocks = []
        for _ in range(6):
            sx = rng.randint(2, self.sts - 20)
            sy = rng.randint(2, self.sts - 16)
            sw = rng.randint(12, 24)
            sh = rng.randint(10, 18)
            stone_blocks.append((sx, sy, sw, sh))
            
            # 石板颜色变化
            stone_color = (
                self._clamp(base_color[0] + rng.randint(-15, 15)),
                self._clamp(base_color[1] + rng.randint(-15, 15)),
                self._clamp(base_color[2] + rng.randint(-15, 15))
            )
            draw.rectangle([sx, sy, sx + sw, sy + sh], fill=(*stone_color, 200))
            
            # 石板边缘 - 浓墨勾勒
            edge_color = (80, 75, 65)
            draw.rectangle([sx, sy, sx + sw, sy + sh], outline=(*edge_color, 150), width=1)
        
        # 石缝 - 焦墨细线
        for _ in range(8):
            fx = rng.randint(3, self.sts - 4)
            fy = rng.randint(3, self.sts - 4)
            fl = rng.randint(4, 10)
            angle = rng.random() * math.pi
            x1, y1 = fx, fy
            x2, y2 = int(fx + fl * math.cos(angle)), int(fy + fl * math.sin(angle))
            self.brush.draw_brush_stroke(draw, x1, y1, x2, y2,
                                        color=(60, 55, 45),
                                        thickness=1,
                                        wetness=0.3,
                                        pressure=0.5)
        
        # 留白 - 石面反光
        for _ in range(3):
            lx = rng.randint(8, self.sts - 8)
            ly = rng.randint(8, self.sts - 8)
            lr = rng.randint(3, 6)
            draw.ellipse([lx - lr, ly - lr, lx + lr, ly + lr], fill=(180, 175, 165, 60))
        
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
        return img
    
    def generate_ink_tree(self, tree_type: str = "pine", seed: int = 0) -> Image.Image:
        """生成水墨风格的树木
        
        Args:
            tree_type: 树木类型 - pine(松), willow(柳), bamboo(竹), plum(梅)
        """
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        cx, cy = self.sts // 2, self.sts // 2
        
        if tree_type == "pine":
            # 松树 - 浓墨树干，浓墨松针
            trunk_color = (70, 50, 30)
            needle_color = (40, 60, 30)
            
            # 树干 - 中锋勾勒
            trunk_bottom = cy + self.sts // 3
            trunk_top = cy - self.sts // 4
            self.brush.draw_brush_stroke(draw, cx, trunk_bottom, cx, trunk_top,
                                        color=trunk_color, thickness=5,
                                        wetness=0.6, pressure=0.8)
            
            # 松针 - 侧锋撇出
            for layer in range(3):
                layer_y = trunk_top + layer * 8
                layer_width = 20 + layer * 8
                for i in range(-3, 4):
                    angle = math.pi / 2 + i * 0.3
                    length = layer_width - abs(i) * 4
                    x1 = cx + i * 6
                    y1 = layer_y
                    x2 = int(x1 + length * math.cos(angle) * 0.5)
                    y2 = int(y1 + length * math.sin(angle) * 0.3)
                    self.brush.draw_brush_stroke(draw, x1, y1, x2, y2,
                                                color=needle_color,
                                                thickness=2,
                                                wetness=0.5,
                                                pressure=0.7)
                                                
        elif tree_type == "willow":
            # 柳树 - 淡墨树干，飘逸柳条
            trunk_color = (80, 65, 45)
            leaf_color = (60, 90, 50)
            
            # 树干
            self.brush.draw_brush_stroke(draw, cx, cy + self.sts // 3, cx, cy - self.sts // 6,
                                        color=trunk_color, thickness=4,
                                        wetness=0.7, pressure=0.8)
            
            # 柳条 - 细笔勾勒
            for i in range(8):
                angle = math.pi / 2 + (i - 4) * 0.15
                length = 30 + rng.randint(-5, 5)
                x1 = cx
                y1 = cy - self.sts // 6
                x2 = int(x1 + length * math.cos(angle))
                y2 = int(y1 + length * math.sin(angle) * 0.8)
                self.brush.draw_brush_stroke(draw, x1, y1, x2, y2,
                                            color=leaf_color,
                                            thickness=1,
                                            wetness=0.6,
                                            pressure=0.5)
                                            
        elif tree_type == "bamboo":
            # 竹子 - 浓墨竹竿，浓墨竹叶
            pole_color = (60, 80, 40)
            leaf_color = (50, 70, 35)
            
            # 竹竿
            for dx in [-8, 0, 8]:
                x = cx + dx
                self.brush.draw_brush_stroke(draw, x, self.sts - 8, x, 8,
                                            color=pole_color, thickness=3,
                                            wetness=0.5, pressure=0.9)
                # 竹节
                for j in range(3):
                    jy = 10 + j * 18
                    draw.rectangle([x - 3, jy, x + 3, jy + 2], fill=(*pole_color, 200))
            
            # 竹叶 - 侧锋撇出
            for _ in range(12):
                lx = cx + rng.choice([-8, 0, 8]) + rng.randint(-6, 6)
                ly = rng.randint(10, self.sts - 20)
                angle = rng.uniform(0.3, 2.8)
                length = rng.randint(8, 16)
                x2 = int(lx + length * math.cos(angle))
                y2 = int(ly + length * math.sin(angle))
                self.brush.draw_brush_stroke(draw, lx, ly, x2, y2,
                                            color=leaf_color,
                                            thickness=1,
                                            wetness=0.4,
                                            pressure=0.6)
        
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        return img
    
    def generate_ink_building(self, building_type: str = "house", seed: int = 0) -> Image.Image:
        """生成水墨风格的建筑"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 建筑颜色
        wall_color = (160, 145, 120)
        roof_color = (100, 60, 40)
        outline_color = (50, 40, 30)
        
        # 墙体 - 淡墨渲染
        wall_top = self.sts // 3
        wall_bottom = self.sts - 4
        draw.rectangle([8, wall_top, self.sts - 8, wall_bottom], fill=(*wall_color, 200))
        
        # 墙体轮廓 - 浓墨勾勒
        draw.rectangle([8, wall_top, self.sts - 8, wall_bottom], 
                      outline=(*outline_color, 180), width=2)
        
        # 屋顶 - 浓墨渲染
        roof_peak = wall_top - 8
        roof_left = 4
        roof_right = self.sts - 4
        
        # 屋顶轮廓
        roof_points = [
            (roof_left, wall_top + 2),
            (cx := self.sts // 2, roof_peak),
            (roof_right, wall_top + 2)
        ]
        draw.polygon(roof_points, fill=(*roof_color, 220))
        draw.line(roof_points[:2], fill=(*outline_color, 200), width=2)
        draw.line(roof_points[1:], fill=(*outline_color, 200), width=2)
        
        # 屋檐 - 细笔勾勒
        draw.line([roof_left - 2, wall_top + 4, roof_right + 2, wall_top + 4],
                 fill=(*outline_color, 150), width=1)
        
        # 门 - 留白
        door_w = self.sts // 4
        door_h = self.sts // 3
        door_x = cx - door_w // 2
        door_y = wall_bottom - door_h
        draw.rectangle([door_x, door_y, door_x + door_w, wall_bottom], 
                      fill=(40, 30, 20, 200))
        draw.rectangle([door_x, door_y, door_x + door_w, wall_bottom],
                      outline=(*outline_color, 150), width=1)
        
        # 窗 - 留白
        win_size = 8
        for wx_off in [-12, 12]:
            wx = cx + wx_off - win_size // 2
            wy = wall_top + 10
            draw.rectangle([wx, wy, wx + win_size, wy + win_size],
                          fill=(200, 210, 220, 150))
            draw.rectangle([wx, wy, wx + win_size, wy + win_size],
                          outline=(*outline_color, 100), width=1)
        
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        return img
    
    def generate_ink_mountain(self, mountain_type: str = "medium", seed: int = 0) -> Image.Image:
        """生成水墨风格的山峦"""
        rng = random.Random(seed)
        img = Image.new('RGBA', (self.sts, self.sts), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        cx, cy = self.sts // 2, self.sts - 8
        
        # 山形大小
        sizes = {
            "small": (18, 20),
            "medium": (28, 30),
            "large": (38, 40),
            "snow": (32, 35)
        }
        height, width = sizes.get(mountain_type, (28, 30))
        
        # 山体颜色 - 淡墨渲染
        mountain_color = (120, 115, 100)
        shadow_color = (80, 75, 65)
        highlight_color = (160, 155, 140)
        
        # 山体轮廓点
        peak_y = cy - height
        left_x = cx - width // 2
        right_x = cx + width // 2
        
        # 山体 - 水墨晕染
        mountain_points = [
            (left_x, cy),
            (cx, peak_y),
            (right_x, cy)
        ]
        draw.polygon(mountain_points, fill=(*mountain_color, 180))
        
        # 山体阴影 - 浓墨
        shadow_points = [
            (cx, peak_y),
            (right_x, cy),
            (cx + width // 4, cy)
        ]
        draw.polygon(shadow_points, fill=(*shadow_color, 100))
        
        # 山体轮廓 - 浓墨勾勒
        self.brush.draw_brush_stroke(draw, left_x, cy, cx, peak_y,
                                    color=(60, 55, 45), thickness=2,
                                    wetness=0.5, pressure=0.7)
        self.brush.draw_brush_stroke(draw, cx, peak_y, right_x, cy,
                                    color=(60, 55, 45), thickness=2,
                                    wetness=0.5, pressure=0.7)
        
        # 山体纹理 - 皴法
        for _ in range(6):
            tx = cx + rng.randint(-width // 3, width // 3)
            ty = peak_y + rng.randint(5, height - 5)
            tl = rng.randint(4, 10)
            angle = rng.uniform(0.8, 2.4)
            x2 = int(tx + tl * math.cos(angle))
            y2 = int(ty + tl * math.sin(angle))
            self.brush.draw_brush_stroke(draw, tx, ty, x2, y2,
                                        color=(90, 85, 75),
                                        thickness=1,
                                        wetness=0.4,
                                        pressure=0.5)
        
        # 雪山 - 留白
        if mountain_type == "snow":
            snow_points = [
                (cx - 8, peak_y + 10),
                (cx, peak_y),
                (cx + 8, peak_y + 10)
            ]
            draw.polygon(snow_points, fill=(240, 245, 250, 200))
        
        img = img.resize((self.ts, self.ts), Image.LANCZOS)
        return img


class InkPostProcessor:
    """水墨后处理器"""
    
    @staticmethod
    def apply_ink_wash_effect(img: Image.Image, 
                              intensity: float = 0.3) -> Image.Image:
        """应用水墨晕染效果"""
        # 轻微模糊模拟晕染
        img = img.filter(ImageFilter.GaussianBlur(radius=intensity * 1.5))
        
        # 降低饱和度 - 水墨风格
        enhancer = ImageEnhance.Color(img)
        img = enhancer.enhance(0.7)
        
        # 增加对比度 - 突出墨色层次
        enhancer = ImageEnhance.Contrast(img)
        img = enhancer.enhance(1.1)
        
        return img
    
    @staticmethod
    def add_paper_texture(img: Image.Image, 
                          texture_intensity: float = 0.1) -> Image.Image:
        """添加宣纸纹理"""
        width, height = img.size
        texture = Image.new('RGBA', (width, height), (255, 255, 255, 0))
        draw = ImageDraw.Draw(texture)
        
        rng = random.Random(42)
        for y in range(height):
            for x in range(width):
                if rng.random() < 0.3:
                    noise = rng.randint(-10, 10)
                    alpha = int(texture_intensity * 50 + noise)
                    alpha = max(0, min(255, alpha))
                    draw.point((x, y), fill=(255, 255, 240, alpha))
        
        return Image.alpha_composite(img, texture)


# 全局实例
_ink_generator = None


def get_ink_generator(tile_size: int = 64) -> InkTextureGenerator:
    """获取水墨纹理生成器实例"""
    global _ink_generator
    if _ink_generator is None:
        _ink_generator = InkTextureGenerator(tile_size)
    return _ink_generator
