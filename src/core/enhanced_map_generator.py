#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版地图生成器 - 打造丰富的武侠世界
包含：山脉、河流、森林、石板路、桥梁、各类建筑
"""

import random
import math
from typing import List, Tuple, Dict, Optional, Set
from .world import (
    MAP_W, MAP_H, TS,
    T_GRASS, T_DIRT_ROAD, T_WATER, T_BUILDING, T_FOREST, T_DARK_GRASS,
    T_SAND, T_BRIDGE, T_WALL, T_SHOP, T_STONE_ROAD, T_GARDEN, T_HILL,
    T_INN, T_TEMPLE, T_DOCK, T_ROOF_RED, T_ROOF_BLUE, T_ROOF_GOLD,
    T_FENCE, T_GATE, T_WELL, T_TABLE, T_CHEST, T_ALTAR, T_TRAINING,
    T_BAMBOO, T_WATERFALL, T_CAVE, T_SIGN, T_FLOWER_BED, T_POND,
    T_TREE_PINE, T_TREE_WILLOW, T_TREE_BAMBOO_VAR, T_TREE_DEAD,
    T_PLANT_GREEN, T_FLOWER_RED, T_FLOWER_PINK, T_FLOWER_WHITE,
    T_COUNTER_WOOD, T_COUNTER_HERB, T_COUNTER_WEAPON, T_COUNTER_INN,
    T_SHELF_WOOD, T_SHELF_BOOK, T_SHELF_HERB, T_SCULPTURE_LION, T_DWELL, T_WALL_STONE,
    T_LAKE, T_ROAD_DIRT, T_COURTYARD, T_HILL_SMALL, T_HILL_MEDIUM, T_HILL_LARGE,
    T_STONE_SMALL, T_STONE_MEDIUM, T_STONE_LARGE, T_WALL_WOOD,
    T_BENCH_WOOD, T_BENCH_LONG, T_DESK_WOOD, T_DESK_LARGE,
    zone_col_to_x, zone_row_to_y
)
from .entities import Map, Position


class TerrainGenerator:
    """地形生成器 - 创建自然地形特征"""
    
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height
        self.tiles = [[T_GRASS for _ in range(width)] for _ in range(height)]
        
    def generate_mountain_range(self, start_x: int, start_y: int, 
                                end_x: int, end_y: int, 
                                width: int = 3) -> None:
        """生成山脉范围"""
        dx = end_x - start_x
        dy = end_y - start_y
        dist = math.sqrt(dx*dx + dy*dy)
        steps = int(dist)
        
        for i in range(steps):
            t = i / steps if steps > 0 else 0
            cx = int(start_x + dx * t)
            cy = int(start_y + dy * t)
            
            # 创建山脉宽度
            for w in range(-width//2, width//2 + 1):
                for h in range(-width//2, width//2 + 1):
                    nx, ny = cx + w, cy + h
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        dist_from_center = math.sqrt(w*w + h*h)
                        if dist_from_center <= width/2:
                            # 根据高度选择地形
                            if dist_from_center < width/4:
                                self.tiles[ny][nx] = T_HILL_LARGE
                            elif dist_from_center < width/2:
                                self.tiles[ny][nx] = T_HILL_MEDIUM
                            else:
                                self.tiles[ny][nx] = T_HILL_SMALL
                                
    def generate_river(self, start_x: int, start_y: int,
                      end_x: int, end_y: int,
                      width: int = 2, meander: float = 0.3) -> List[Tuple[int, int]]:
        """生成蜿蜒的河流，返回桥梁位置列表"""
        bridge_positions = []
        dx = end_x - start_x
        dy = end_y - start_y
        steps = int(math.sqrt(dx*dx + dy*dy)) * 2
        
        points = []
        for i in range(steps + 1):
            t = i / steps if steps > 0 else 0
            # 添加蜿蜒效果
            offset = math.sin(t * math.pi * 3) * meander * self.width * 0.1
            cx = int(start_x + dx * t + offset)
            cy = int(start_y + dy * t)
            points.append((cx, cy))
            
        # 绘制河流
        for i, (cx, cy) in enumerate(points):
            for w in range(-width//2, width//2 + 1):
                for h in range(-width//2, width//2 + 1):
                    nx, ny = cx + w, cy + h
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        dist = math.sqrt(w*w + h*h)
                        if dist <= width/2:
                            # 河流中心深水，边缘浅水
                            if dist < width/3:
                                self.tiles[ny][nx] = T_WATER
                            else:
                                self.tiles[ny][nx] = T_LAKE
                                
            # 在特定位置添加桥梁
            if i % 15 == 7 and i > 5 and i < len(points) - 5:
                bridge_positions.append((cx, cy))
                
        return bridge_positions
        
    def generate_forest(self, center_x: int, center_y: int,
                       radius: int, density: float = 0.7) -> None:
        """生成森林区域"""
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                nx, ny = center_x + dx, center_y + dy
                if 0 <= nx < self.width and 0 <= ny < self.height:
                    dist = math.sqrt(dx*dx + dy*dy)
                    if dist <= radius:
                        # 根据距离中心决定密度
                        if random.random() < density * (1 - dist/radius * 0.5):
                            # 随机选择树木类型
                            tree_types = [T_TREE_PINE, T_TREE_WILLOW, T_TREE_BAMBOO_VAR, T_FOREST]
                            self.tiles[ny][nx] = random.choice(tree_types)
                            
    def generate_bamboo_grove(self, center_x: int, center_y: int,
                             radius: int) -> None:
        """生成竹林"""
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                nx, ny = center_x + dx, center_y + dy
                if 0 <= nx < self.width and 0 <= ny < self.height:
                    dist = math.sqrt(dx*dx + dy*dy)
                    if dist <= radius and random.random() < 0.8:
                        self.tiles[ny][nx] = T_BAMBOO
                        
    def generate_stone_road_network(self, key_points: List[Tuple[int, int]],
                                   road_width: int = 2) -> None:
        """生成石板路网络连接关键点"""
        for i in range(len(key_points) - 1):
            x1, y1 = key_points[i]
            x2, y2 = key_points[i + 1]
            self._draw_stone_road(x1, y1, x2, y2, road_width)
            
    def _draw_stone_road(self, x1: int, y1: int, x2: int, y2: int, width: int):
        """绘制石板路段"""
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy
        
        x, y = x1, y1
        while True:
            # 绘制道路宽度
            for w in range(-width//2, width//2 + 1):
                for h in range(-width//2, width//2 + 1):
                    nx, ny = x + w, y + h
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        # 不覆盖水域和建筑
                        if self.tiles[ny][nx] not in [T_WATER, T_LAKE, T_BUILDING, T_INN, T_TEMPLE, T_SHOP]:
                            self.tiles[ny][nx] = T_STONE_ROAD
                            
            if x == x2 and y == y2:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy
                
    def add_road_bridges(self, bridge_positions: List[Tuple[int, int]]) -> None:
        """在指定位置添加桥梁"""
        for bx, by in bridge_positions:
            if 0 <= bx < self.width and 0 <= by < self.height:
                self.tiles[by][bx] = T_BRIDGE
                
    def add_decorations(self, count: int = 50) -> None:
        """添加装饰性元素"""
        for _ in range(count):
            x = random.randint(2, self.width - 3)
            y = random.randint(2, self.height - 3)
            
            # 只在草地上添加装饰
            if self.tiles[y][x] == T_GRASS:
                decoration = random.choice([
                    T_STONE_SMALL, T_STONE_MEDIUM, T_FLOWER_RED,
                    T_FLOWER_PINK, T_FLOWER_WHITE, T_PLANT_GREEN,
                    T_WELL, T_SIGN
                ])
                self.tiles[y][x] = decoration
                
    def get_tiles(self) -> List[List[int]]:
        return self.tiles


class BuildingPlacer:
    """建筑放置器 - 在地图上放置各类建筑"""
    
    BUILDING_TYPES = {
        "tavern": {"name": "客栈", "tiles": T_INN, "roof": T_ROOF_RED, "size": (6, 8)},
        "blacksmith": {"name": "铁匠铺", "tiles": T_SHOP, "roof": T_ROOF_BLUE, "size": (5, 7)},
        "tailor": {"name": "裁缝铺", "tiles": T_SHOP, "roof": T_ROOF_BLUE, "size": (5, 6)},
        "herbalist": {"name": "药铺", "tiles": T_SHOP, "roof": T_ROOF_BLUE, "size": (5, 6)},
        "temple": {"name": "寺庙", "tiles": T_TEMPLE, "roof": T_ROOF_GOLD, "size": (8, 10)},
        "residence": {"name": "民居", "tiles": T_DWELL, "roof": T_ROOF_RED, "size": (5, 6)},
        "market": {"name": "集市", "tiles": T_SHOP, "roof": T_ROOF_BLUE, "size": (7, 9)},
        "training": {"name": "武馆", "tiles": T_TEMPLE, "roof": T_ROOF_RED, "size": (7, 9)},
    }
    
    def __init__(self, tiles: List[List[int]], width: int, height: int):
        self.tiles = tiles
        self.width = width
        self.height = height
        self.buildings = []
        
    def place_building(self, building_type: str, x: int, y: int,
                      entrance_x: int = None, entrance_y: int = None) -> bool:
        """放置单个建筑"""
        if building_type not in self.BUILDING_TYPES:
            return False
            
        info = self.BUILDING_TYPES[building_type]
        h, w = info["size"]
        
        # 检查空间是否足够
        if x + w > self.width or y + h > self.height:
            return False
            
        # 检查是否与其他建筑重叠
        for by in range(y, y + h):
            for bx in range(x, x + w):
                if self.tiles[by][bx] in [T_BUILDING, T_INN, T_TEMPLE, T_SHOP, T_DWELL, T_WALL]:
                    return False
                    
        # 放置建筑
        for by in range(y, y + h):
            for bx in range(x, x + w):
                if by == y or by == y + h - 1 or bx == x or bx == x + w - 1:
                    self.tiles[by][bx] = T_WALL
                else:
                    self.tiles[by][bx] = info["tiles"]
                    
        # 屋顶
        for bx in range(x, x + w):
            self.tiles[y][bx] = info["roof"]
            
        # 入口
        if entrance_x is None:
            entrance_x = x + w // 2
        if entrance_y is None:
            entrance_y = y + h - 1
            
        if 0 <= entrance_x < self.width and 0 <= entrance_y < self.height:
            self.tiles[entrance_y][entrance_x] = T_GATE
            
        # 添加内部装饰
        self._add_interior(building_type, x, y, w, h)
        
        self.buildings.append({
            "type": building_type,
            "name": info["name"],
            "x": x, "y": y,
            "width": w, "height": h,
            "entrance": (entrance_x, entrance_y)
        })
        
        return True
        
    def _add_interior(self, building_type: str, x: int, y: int, w: int, h: int):
        """添加建筑内部装饰"""
        interior_y = y + 2
        
        if building_type == "tavern":
            # 客栈：柜台、长凳
            self.tiles[interior_y][x + 2] = T_COUNTER_INN
            self.tiles[interior_y + 1][x + 2] = T_BENCH_LONG
            self.tiles[interior_y][x + w - 3] = T_TABLE
            
        elif building_type == "blacksmith":
            # 铁匠铺：铁砧、货架
            self.tiles[interior_y][x + 2] = T_COUNTER_WEAPON
            self.tiles[interior_y][x + w - 3] = T_SHELF_WOOD
            
        elif building_type == "tailor":
            # 裁缝铺：柜台、布料
            self.tiles[interior_y][x + 2] = T_COUNTER_WOOD
            self.tiles[interior_y][x + w - 3] = T_CHEST
            
        elif building_type == "herbalist":
            # 药铺：药柜
            self.tiles[interior_y][x + 2] = T_COUNTER_HERB
            self.tiles[interior_y][x + w - 3] = T_SHELF_HERB
            
        elif building_type == "temple":
            # 寺庙：祭坛、雕像
            self.tiles[interior_y][x + w//2] = T_ALTAR
            self.tiles[interior_y + 2][x + 2] = T_SCULPTURE_LION
            self.tiles[interior_y + 2][x + w - 3] = T_SCULPTURE_LION
            
        elif building_type == "training":
            # 武馆：训练场
            self.tiles[interior_y][x + 2] = T_TRAINING
            self.tiles[interior_y][x + w - 3] = T_TRAINING
            self.tiles[interior_y + 2][x + w//2] = T_CHEST
            
    def place_walled_compound(self, x: int, y: int, w: int, h: int,
                             gate_x: int = None, gate_y: int = None) -> bool:
        """放置带围墙的院落"""
        if x + w > self.width or y + h > self.height:
            return False
            
        # 围墙
        for by in range(y, y + h):
            for bx in range(x, x + w):
                if by == y or by == y + h - 1 or bx == x or bx == x + w - 1:
                    if self.tiles[by][bx] not in [T_BUILDING, T_INN, T_TEMPLE, T_SHOP]:
                        self.tiles[by][bx] = T_WALL_STONE
                        
        # 大门
        if gate_x is None:
            gate_x = x + w // 2
        if gate_y is None:
            gate_y = y + h - 1
            
        if 0 <= gate_x < self.width and 0 <= gate_y < self.height:
            self.tiles[gate_y][gate_x] = T_GATE
            
        return True
        
    def get_buildings(self) -> List[Dict]:
        return self.buildings


class EnhancedMapGenerator:
    """增强版地图生成器主类"""
    
    def __init__(self):
        self.zone_generators = {}
        
    def generate_city(self, zone_id: str, name: str, width: int = 40, 
                     height: int = 40, description: str = "") -> Map:
        """生成大型城市地图 - 丰富多样的布局"""
        terrain = TerrainGenerator(width, height)
        
        center_x, center_y = width // 2, height // 2
        
        # 城市基础布局 - 石板路网格
        # 主十字路
        main_road = [
            (center_x, 2),           # 北城门
            (center_x, center_y),     # 市中心
            (center_x, height - 3),   # 南城门
        ]
        terrain.generate_stone_road_network(main_road, road_width=3)
        
        # 东西主干道
        east_west = [
            (2, center_y),           # 西城门
            (center_x, center_y),     # 市中心
            (width - 3, center_y),    # 东城门
        ]
        terrain.generate_stone_road_network(east_west, road_width=3)
        
        # 次要街道 (构成街区)
        quarter_roads = []
        for qx in [width // 4, 3 * width // 4]:
            for qy in [height // 4, 3 * height // 4]:
                quarter_roads.append((qx, qy))
        terrain.generate_stone_road_network(quarter_roads, road_width=2)
        
        # 连接主要交叉口
        cross_points = quarter_roads + [(center_x, center_y)]
        terrain.generate_stone_road_network(cross_points, road_width=2)
        
        # 河流穿城
        river_start = (2, random.randint(height // 5, height // 3))
        river_end = (width - 3, random.randint(height * 2 // 3, height * 4 // 5))
        bridge_positions = terrain.generate_river(
            river_start[0], river_start[1],
            river_end[0], river_end[1],
            width=3, meander=0.25
        )
        terrain.add_road_bridges(bridge_positions)
        
        tiles = terrain.get_tiles()
        building_placer = BuildingPlacer(tiles, width, height)
        
        # 市中心 - 集市和重要建筑
        building_placer.place_building("market", center_x - 4, center_y - 4)
        
        # 城市四区各有主题建筑
        # 东北区 - 商业区: 客栈+铁匠铺
        ne_x = 3 * width // 4 - 3
        ne_y = height - 10
        building_placer.place_building("tavern", ne_x - 10, ne_y)
        building_placer.place_building("blacksmith", ne_x + 2, ne_y)
        
        # 西北区 - 文化区: 寺庙+裁缝铺
        nw_x = width // 4 - 8
        nw_y = height - 10
        building_placer.place_building("temple", nw_x - 2, nw_y - 2)
        building_placer.place_building("tailor", nw_x + 6, nw_y)
        
        # 东南区 - 武学+生活
        se_x = 3 * width // 4 - 3
        se_y = 5
        building_placer.place_building("training", se_x - 5, se_y)
        building_placer.place_building("herbalist", se_x + 6, se_y)
        
        # 西南区 - 药铺+民居
        sw_x = width // 4 - 8
        sw_y = 5
        building_placer.place_building("residence", sw_x, sw_y)
        building_placer.place_building("residence", sw_x + 8, sw_y + 2)
        
        # 添加更多民居
        residence_spots = [
            (center_x - 15, center_y + 10),
            (center_x + 3, center_y - 15),
            (3 * width // 4 + 2, height // 2 + 3),
            (width // 4 - 5, height // 2),
            (center_x + 12, 7),
            (width - 12, height - 12),
        ]
        for rx, ry in residence_spots:
            building_placer.place_building("residence", rx, ry)
            
        # 随机补充建筑
        for _ in range(4):
            bx = random.randint(5, width - 12)
            by = random.randint(5, height - 12)
            btype = random.choice(["residence", "residence", "residence"])
            building_placer.place_building(btype, bx, by)
            
        # 城墙
        for x in range(width):
            tiles[0][x] = T_WALL_STONE
            tiles[height-1][x] = T_WALL_STONE
        for y in range(height):
            tiles[y][0] = T_WALL_STONE
            tiles[y][width-1] = T_WALL_STONE
            
        # 四城门
        for gx, gy in [(center_x, 1), (center_x, height-2), (1, center_y), (width-2, center_y)]:
            tiles[gy][gx] = T_GATE
            if gx == center_x:
                tiles[gy][gx+1] = T_GATE
                tiles[gy][gx-1] = T_GATE
            else:
                tiles[gy+1][gx] = T_GATE
                tiles[gy-1][gx] = T_GATE
        
        # 添加装饰: 井、花坛、石头等
        for _ in range(40):
            dx = random.randint(3, width - 4)
            dy = random.randint(3, height - 4)
            if tiles[dy][dx] in (T_GRASS, T_DARK_GRASS, 0, 5):
                deco = random.choice([T_WELL, T_FLOWER_BED, T_STONE_SMALL, 
                                     T_STONE_MEDIUM, T_SIGN, T_PLANT_GREEN,
                                     T_FLOWER_RED, T_FLOWER_PINK])
                tiles[dy][dx] = deco
        
        # 创建标签
        labels = []
        for building in building_placer.get_buildings():
            labels.append((
                building["x"] + building["width"] // 2,
                building["y"] + building["height"],
                building["name"],
                "default",
                building["type"]
            ))
            
        return Map(
            id=zone_id,
            name=name,
            width=width,
            height=height,
            tiles=tiles,
            zone_type="city",
            description=description,
            labels=labels
        )
        
    def generate_town(self, zone_id: str, name: str, width: int = 25,
                     height: int = 25, description: str = "") -> Map:
        """生成小镇地图"""
        terrain = TerrainGenerator(width, height)
        
        center_x, center_y = width // 2, height // 2
        
        # 简单的十字道路
        key_points = [
            (center_x, 2),
            (center_x, height - 3),
            (2, center_y),
            (width - 3, center_y),
            (center_x, center_y),
        ]
        terrain.generate_stone_road_network(key_points, road_width=2)
        
        tiles = terrain.get_tiles()
        building_placer = BuildingPlacer(tiles, width, height)
        
        # 小镇建筑
        buildings = [
            ("tavern", center_x - 6, center_y - 6),
            ("blacksmith", center_x + 4, center_y - 6),
            ("herbalist", center_x - 6, center_y + 4),
        ]
        
        for btype, bx, by in buildings:
            building_placer.place_building(btype, bx, by)
            
        # 民居
        for i in range(4):
            rx = random.randint(3, width - 8)
            ry = random.randint(3, height - 8)
            building_placer.place_building("residence", rx, ry)
            
        # 围栏
        for x in range(width):
            tiles[0][x] = T_FENCE
            tiles[height-1][x] = T_FENCE
        for y in range(height):
            tiles[y][0] = T_FENCE
            tiles[y][width-1] = T_FENCE
            
        # 门
        tiles[0][center_x] = T_GATE
        tiles[height-1][center_x] = T_GATE
        tiles[center_y][0] = T_GATE
        tiles[center_y][width-1] = T_GATE
        
        terrain.add_decorations(15)
        
        labels = []
        for building in building_placer.get_buildings():
            labels.append((
                building["x"] + building["width"] // 2,
                building["y"] + building["height"],
                building["name"],
                "default",
                building["type"]
            ))
            
        return Map(
            id=zone_id,
            name=name,
            width=width,
            height=height,
            tiles=tiles,
            zone_type="town",
            description=description,
            labels=labels
        )
        
    def generate_sect(self, zone_id: str, name: str, faction: str,
                     width: int = 30, height: int = 30, description: str = "") -> Map:
        """生成门派地图"""
        terrain = TerrainGenerator(width, height)
        
        center_x, center_y = width // 2, height // 2
        
        # 根据门派特色生成地形
        if "山" in name or "雪山" in faction:
            # 雪山派 - 雪山地形
            terrain.generate_mountain_range(5, 5, width-5, height-5, width=6)
            base_tile = T_DARK_GRASS
        elif "花" in name or "百花" in faction:
            # 花间派 - 花园地形
            terrain.generate_forest(center_x, center_y, 8, density=0.5)
            base_tile = T_GARDEN
        else:
            base_tile = T_GRASS
            
        # 石板路通向主殿
        key_points = [
            (center_x, height - 3),  # 山门
            (center_x, center_y + 5),
            (center_x, center_y),    # 主殿
        ]
        terrain.generate_stone_road_network(key_points, road_width=3)
        
        tiles = terrain.get_tiles()
        building_placer = BuildingPlacer(tiles, width, height)
        
        # 主殿
        building_placer.place_building("temple", center_x - 5, center_y - 5)
        
        # 练武场
        building_placer.place_building("training", 5, center_y - 3)
        
        # 厢房
        building_placer.place_building("residence", width - 10, 5)
        building_placer.place_building("residence", width - 10, height - 10)
        
        # 围墙
        building_placer.place_walled_compound(0, 0, width, height, center_x, height-1)
        
        terrain.add_decorations(20)
        
        labels = []
        for building in building_placer.get_buildings():
            labels.append((
                building["x"] + building["width"] // 2,
                building["y"] + building["height"],
                building["name"],
                faction,
                building["type"]
            ))
            
        return Map(
            id=zone_id,
            name=name,
            width=width,
            height=height,
            tiles=tiles,
            zone_type="sect",
            description=description,
            labels=labels
        )
        
    def generate_wilderness(self, zone_id: str, name: str, 
                           width: int = 50, height: int = 50,
                           terrain_type: str = "forest",
                           description: str = "") -> Map:
        """生成野外地图"""
        terrain = TerrainGenerator(width, height)
        
        if terrain_type == "forest":
            # 森林 - 多树木
            terrain.generate_forest(width//4, height//4, 10)
            terrain.generate_forest(width*3//4, height//4, 8)
            terrain.generate_forest(width//2, height*3//4, 12)
            
        elif terrain_type == "mountain":
            # 山地 - 多山脉
            terrain.generate_mountain_range(5, 5, width//2, height//2, width=5)
            terrain.generate_mountain_range(width//2, height//2, width-5, height-5, width=4)
            
        elif terrain_type == "river":
            # 河流地带
            bridge_positions = terrain.generate_river(
                2, height//3, width-3, height//3*2, width=3
            )
            terrain.add_road_bridges(bridge_positions)
            terrain.generate_forest(width//4, height//4, 6)
            
        elif terrain_type == "bamboo":
            # 竹林
            terrain.generate_bamboo_grove(width//2, height//2, 15)
            
        # 添加小径
        key_points = [
            (width//4, height//4),
            (width//2, height//2),
            (width*3//4, height*3//4),
        ]
        terrain.generate_stone_road_network(key_points, road_width=1)
        
        terrain.add_decorations(40)
        
        tiles = terrain.get_tiles()
        
        return Map(
            id=zone_id,
            name=name,
            width=width,
            height=height,
            tiles=tiles,
            zone_type="wilderness",
            description=description
        )


# 全局生成器实例
_enhanced_generator = None


def get_enhanced_map_generator() -> EnhancedMapGenerator:
    """获取增强版地图生成器实例"""
    global _enhanced_generator
    if _enhanced_generator is None:
        _enhanced_generator = EnhancedMapGenerator()
    return _enhanced_generator
