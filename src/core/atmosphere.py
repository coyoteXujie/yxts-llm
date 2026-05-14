#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
天气昼夜系统 - Weather and Day-Night Cycle System
为水墨世界增添时间流逝和天气变化

特色:
1. 昼夜循环 - 晨曦、正午、黄昏、深夜
2. 天气变化 - 晴朗、细雨、飞雪、狂风、迷雾
3. 光影效果 - 随时间变化的色调和光照
4. 环境粒子 - 雨滴、雪花、落叶、花瓣
"""

import math
import random
from typing import Tuple, List, Dict, Optional
from dataclasses import dataclass
from enum import Enum, auto


class TimeOfDay(Enum):
    """时段"""
    DAWN = auto()      # 晨曦 (5:00-7:00)
    MORNING = auto()   # 上午 (7:00-11:00)
    NOON = auto()      # 正午 (11:00-14:00)
    AFTERNOON = auto() # 下午 (14:00-17:00)
    DUSK = auto()      # 黄昏 (17:00-19:00)
    EVENING = auto()   # 傍晚 (19:00-21:00)
    NIGHT = auto()     # 深夜 (21:00-5:00)


class WeatherType(Enum):
    """天气类型"""
    CLEAR = auto()     # 晴朗
    CLOUDY = auto()    # 多云
    RAIN = auto()      # 细雨
    HEAVY_RAIN = auto() # 暴雨
    SNOW = auto()      # 飞雪
    HEAVY_SNOW = auto() # 大雪
    WIND = auto()      # 狂风
    FOG = auto()       # 迷雾
    THUNDER = auto()   # 雷雨


@dataclass
class AtmosphereSettings:
    """氛围设置"""
    # 基础色调
    tint_color: Tuple[int, int, int] = (255, 255, 255)
    tint_intensity: float = 0.0
    
    # 光照
    ambient_light: float = 1.0
    sun_angle: float = 45.0  # 太阳角度
    
    # 雾效
    fog_color: Tuple[int, int, int] = (200, 200, 200)
    fog_density: float = 0.0
    
    # 对比度和饱和度
    contrast: float = 1.0
    saturation: float = 1.0
    
    # 特效
    bloom_intensity: float = 0.0
    vignette_intensity: float = 0.0


@dataclass
class ParticleConfig:
    """粒子配置"""
    particle_type: str = "none"  # none, rain, snow, leaf, petal
    density: float = 0.0
    speed: float = 1.0
    direction: float = 0.0  # 风向角度
    size_range: Tuple[float, float] = (1.0, 3.0)
    color: Tuple[int, int, int, int] = (255, 255, 255, 200)


class DayNightCycle:
    """昼夜循环系统"""
    
    # 各时段的氛围预设
    TIME_PRESETS = {
        TimeOfDay.DAWN: AtmosphereSettings(
            tint_color=(255, 200, 150),
            tint_intensity=0.3,
            ambient_light=0.6,
            sun_angle=15.0,
            fog_density=0.1,
            saturation=0.9,
            bloom_intensity=0.2,
        ),
        TimeOfDay.MORNING: AtmosphereSettings(
            tint_color=(255, 240, 220),
            tint_intensity=0.1,
            ambient_light=0.85,
            sun_angle=45.0,
            saturation=1.0,
        ),
        TimeOfDay.NOON: AtmosphereSettings(
            tint_color=(255, 255, 240),
            tint_intensity=0.05,
            ambient_light=1.0,
            sun_angle=90.0,
            contrast=1.05,
            bloom_intensity=0.1,
        ),
        TimeOfDay.AFTERNOON: AtmosphereSettings(
            tint_color=(255, 245, 220),
            tint_intensity=0.1,
            ambient_light=0.9,
            sun_angle=60.0,
            saturation=0.95,
        ),
        TimeOfDay.DUSK: AtmosphereSettings(
            tint_color=(255, 180, 100),
            tint_intensity=0.4,
            ambient_light=0.7,
            sun_angle=10.0,
            fog_density=0.05,
            saturation=0.85,
            bloom_intensity=0.3,
            vignette_intensity=0.1,
        ),
        TimeOfDay.EVENING: AtmosphereSettings(
            tint_color=(100, 120, 180),
            tint_intensity=0.35,
            ambient_light=0.5,
            sun_angle=-5.0,
            fog_density=0.08,
            saturation=0.7,
            vignette_intensity=0.15,
        ),
        TimeOfDay.NIGHT: AtmosphereSettings(
            tint_color=(50, 60, 100),
            tint_intensity=0.5,
            ambient_light=0.35,
            sun_angle=-30.0,
            fog_density=0.1,
            contrast=0.95,
            saturation=0.5,
            vignette_intensity=0.2,
        ),
    }
    
    def __init__(self, game_time: float = 8.0):
        """
        Args:
            game_time: 游戏时间 (小时, 0-24)
        """
        self.game_time = game_time  # 当前时间
        self.time_speed = 1.0       # 时间流速 (1 = 实时, 60 = 1分钟=1小时)
        
    def update(self, delta_time: float) -> None:
        """更新时间"""
        # 每秒流逝的游戏时间 (小时)
        hours_per_second = self.time_speed / 3600.0
        self.game_time += delta_time * hours_per_second * self.time_speed * 60
        
        # 循环到下一天
        if self.game_time >= 24.0:
            self.game_time -= 24.0
            
    def get_time_of_day(self) -> TimeOfDay:
        """获取当前时段"""
        hour = self.game_time
        
        if 5.0 <= hour < 7.0:
            return TimeOfDay.DAWN
        elif 7.0 <= hour < 11.0:
            return TimeOfDay.MORNING
        elif 11.0 <= hour < 14.0:
            return TimeOfDay.NOON
        elif 14.0 <= hour < 17.0:
            return TimeOfDay.AFTERNOON
        elif 17.0 <= hour < 19.0:
            return TimeOfDay.DUSK
        elif 19.0 <= hour < 21.0:
            return TimeOfDay.EVENING
        else:
            return TimeOfDay.NIGHT
            
    def get_atmosphere(self) -> AtmosphereSettings:
        """获取当前氛围设置"""
        tod = self.get_time_of_day()
        return self.TIME_PRESETS[tod]
        
    def get_time_string(self) -> str:
        """获取时间字符串"""
        hour = int(self.game_time)
        minute = int((self.game_time - hour) * 60)
        
        # 时辰名称
        time_names = {
            (23, 1): "子时",
            (1, 3): "丑时",
            (3, 5): "寅时",
            (5, 7): "卯时",
            (7, 9): "辰时",
            (9, 11): "巳时",
            (11, 13): "午时",
            (13, 15): "未时",
            (15, 17): "申时",
            (17, 19): "酉时",
            (19, 21): "戌时",
            (21, 23): "亥时",
        }
        
        for (start, end), name in time_names.items():
            if start <= hour < end or (start > end and (hour >= start or hour < end)):
                time_name = name
                break
        else:
            time_name = "子时"
            
        return f"{time_name} ({hour:02d}:{minute:02d})"


class WeatherSystem:
    """天气系统"""
    
    # 各天气的氛围预设
    WEATHER_PRESETS = {
        WeatherType.CLEAR: AtmosphereSettings(
            saturation=1.0,
        ),
        WeatherType.CLOUDY: AtmosphereSettings(
            tint_color=(220, 220, 230),
            tint_intensity=0.15,
            ambient_light=0.85,
            saturation=0.9,
        ),
        WeatherType.RAIN: AtmosphereSettings(
            tint_color=(180, 190, 210),
            tint_intensity=0.25,
            ambient_light=0.75,
            fog_density=0.08,
            saturation=0.8,
        ),
        WeatherType.HEAVY_RAIN: AtmosphereSettings(
            tint_color=(150, 160, 180),
            tint_intensity=0.35,
            ambient_light=0.6,
            fog_density=0.15,
            saturation=0.7,
            vignette_intensity=0.1,
        ),
        WeatherType.SNOW: AtmosphereSettings(
            tint_color=(240, 245, 255),
            tint_intensity=0.2,
            ambient_light=0.85,
            saturation=0.85,
        ),
        WeatherType.HEAVY_SNOW: AtmosphereSettings(
            tint_color=(230, 235, 255),
            tint_intensity=0.3,
            ambient_light=0.75,
            fog_density=0.2,
            saturation=0.7,
        ),
        WeatherType.WIND: AtmosphereSettings(
            tint_color=(230, 220, 200),
            tint_intensity=0.15,
            saturation=0.9,
        ),
        WeatherType.FOG: AtmosphereSettings(
            fog_color=(200, 200, 210),
            fog_density=0.4,
            ambient_light=0.7,
            saturation=0.6,
        ),
        WeatherType.THUNDER: AtmosphereSettings(
            tint_color=(120, 130, 160),
            tint_intensity=0.4,
            ambient_light=0.5,
            fog_density=0.12,
            saturation=0.65,
            vignette_intensity=0.15,
        ),
    }
    
    # 粒子配置
    PARTICLE_CONFIGS = {
        WeatherType.CLEAR: ParticleConfig(particle_type="none"),
        WeatherType.CLOUDY: ParticleConfig(particle_type="none"),
        WeatherType.RAIN: ParticleConfig(
            particle_type="rain",
            density=0.5,
            speed=8.0,
            direction=270.0,
            size_range=(1.0, 2.0),
            color=(180, 200, 255, 150),
        ),
        WeatherType.HEAVY_RAIN: ParticleConfig(
            particle_type="rain",
            density=1.0,
            speed=12.0,
            direction=260.0,
            size_range=(1.5, 3.0),
            color=(150, 180, 255, 180),
        ),
        WeatherType.SNOW: ParticleConfig(
            particle_type="snow",
            density=0.4,
            speed=2.0,
            direction=300.0,
            size_range=(2.0, 4.0),
            color=(255, 255, 255, 200),
        ),
        WeatherType.HEAVY_SNOW: ParticleConfig(
            particle_type="snow",
            density=1.0,
            speed=3.0,
            direction=290.0,
            size_range=(3.0, 6.0),
            color=(255, 255, 255, 220),
        ),
        WeatherType.WIND: ParticleConfig(
            particle_type="leaf",
            density=0.3,
            speed=6.0,
            direction=90.0,
            size_range=(3.0, 5.0),
            color=(180, 140, 80, 180),
        ),
        WeatherType.FOG: ParticleConfig(particle_type="none"),
        WeatherType.THUNDER: ParticleConfig(
            particle_type="rain",
            density=0.8,
            speed=10.0,
            direction=250.0,
            size_range=(1.5, 3.0),
            color=(140, 160, 200, 160),
        ),
    }
    
    def __init__(self, initial_weather: WeatherType = WeatherType.CLEAR):
        self.current_weather = initial_weather
        self.weather_duration = 0.0
        self.next_change_time = random.uniform(300, 600)  # 5-10分钟后变化
        self.transition_progress = 1.0  # 过渡进度
        self.previous_weather = initial_weather
        
    def update(self, delta_time: float) -> None:
        """更新天气"""
        self.weather_duration += delta_time
        
        # 检查是否需要变化天气
        if self.weather_duration >= self.next_change_time:
            self._change_weather()
            
        # 更新过渡
        if self.transition_progress < 1.0:
            self.transition_progress = min(1.0, self.transition_progress + delta_time * 0.5)
            
    def _change_weather(self) -> None:
        """变化天气"""
        self.previous_weather = self.current_weather
        
        # 根据当前天气决定下一个天气的概率
        transition_probs = {
            WeatherType.CLEAR: {
                WeatherType.CLEAR: 0.4,
                WeatherType.CLOUDY: 0.3,
                WeatherType.RAIN: 0.1,
                WeatherType.WIND: 0.1,
                WeatherType.FOG: 0.1,
            },
            WeatherType.CLOUDY: {
                WeatherType.CLEAR: 0.2,
                WeatherType.CLOUDY: 0.3,
                WeatherType.RAIN: 0.25,
                WeatherType.WIND: 0.15,
                WeatherType.FOG: 0.1,
            },
            WeatherType.RAIN: {
                WeatherType.CLOUDY: 0.3,
                WeatherType.RAIN: 0.3,
                WeatherType.HEAVY_RAIN: 0.2,
                WeatherType.THUNDER: 0.1,
                WeatherType.CLEAR: 0.1,
            },
            WeatherType.SNOW: {
                WeatherType.CLOUDY: 0.2,
                WeatherType.SNOW: 0.4,
                WeatherType.HEAVY_SNOW: 0.3,
                WeatherType.CLEAR: 0.1,
            },
        }
        
        probs = transition_probs.get(self.current_weather, {w: 1/len(WeatherType) for w in WeatherType})
        
        # 随机选择
        r = random.random()
        cumulative = 0.0
        for weather, prob in probs.items():
            cumulative += prob
            if r <= cumulative:
                self.current_weather = weather
                break
                
        self.weather_duration = 0.0
        self.next_change_time = random.uniform(300, 900)
        self.transition_progress = 0.0
        
    def get_atmosphere(self) -> AtmosphereSettings:
        """获取当前氛围设置"""
        return self.WEATHER_PRESETS[self.current_weather]
        
    def get_particle_config(self) -> ParticleConfig:
        """获取粒子配置"""
        return self.PARTICLE_CONFIGS[self.current_weather]
        
    def get_weather_name(self) -> str:
        """获取天气名称"""
        names = {
            WeatherType.CLEAR: "晴朗",
            WeatherType.CLOUDY: "多云",
            WeatherType.RAIN: "细雨",
            WeatherType.HEAVY_RAIN: "暴雨",
            WeatherType.SNOW: "飞雪",
            WeatherType.HEAVY_SNOW: "大雪",
            WeatherType.WIND: "狂风",
            WeatherType.FOG: "迷雾",
            WeatherType.THUNDER: "雷雨",
        }
        return names[self.current_weather]


class EnvironmentRenderer:
    """环境渲染器 - 处理天气和昼夜效果"""
    
    def __init__(self, screen_width: int, screen_height: int):
        self.width = screen_width
        self.height = screen_height
        self.particles: List[Dict] = []
        
    def update_particles(self, config: ParticleConfig, delta_time: float) -> None:
        """更新粒子"""
        if config.particle_type == "none":
            self.particles.clear()
            return
            
        # 计算需要的粒子数量
        target_count = int(config.density * 100)
        
        # 添加新粒子
        while len(self.particles) < target_count:
            particle = {
                "x": random.uniform(0, self.width),
                "y": random.uniform(-50, 0),
                "vx": config.speed * math.cos(math.radians(config.direction)) * random.uniform(0.8, 1.2),
                "vy": config.speed * math.sin(math.radians(config.direction)) * random.uniform(0.8, 1.2),
                "size": random.uniform(*config.size_range),
                "alpha": random.randint(150, 255),
            }
            self.particles.append(particle)
            
        # 更新现有粒子
        new_particles = []
        for p in self.particles:
            p["x"] += p["vx"] * delta_time * 60
            p["y"] += p["vy"] * delta_time * 60
            
            # 飘雪摆动
            if config.particle_type == "snow":
                p["x"] += math.sin(p["y"] * 0.02) * 0.5
                
            # 落叶旋转
            if config.particle_type == "leaf":
                p["x"] += math.sin(p["y"] * 0.05) * 2
                
            # 保留屏幕内的粒子
            if -50 < p["x"] < self.width + 50 and p["y"] < self.height + 50:
                new_particles.append(p)
                
        self.particles = new_particles
        
    def render_particles(self, config: ParticleConfig) -> List[Tuple]:
        """渲染粒子 - 返回绘制指令列表"""
        if config.particle_type == "none":
            return []
            
        draw_commands = []
        
        for p in self.particles:
            x, y = int(p["x"]), int(p["y"])
            size = p["size"]
            alpha = int(p["alpha"] * config.color[3] / 255)
            color = (*config.color[:3], alpha)
            
            if config.particle_type == "rain":
                # 雨滴 - 线条
                length = size * 4
                draw_commands.append(("line", x, y, x, y + length, color, 1))
                
            elif config.particle_type == "snow":
                # 雪花 - 圆形
                draw_commands.append(("circle", x, y, size, color))
                
            elif config.particle_type == "leaf":
                # 落叶 - 椭圆
                draw_commands.append(("ellipse", x - size, y - size/2, x + size, y + size/2, color))
                
        return draw_commands


class AtmosphereManager:
    """氛围管理器 - 整合昼夜和天气效果"""
    
    def __init__(self, screen_width: int, screen_height: int):
        self.day_night = DayNightCycle(game_time=8.0)  # 从早上8点开始
        self.weather = WeatherSystem()
        self.renderer = EnvironmentRenderer(screen_width, screen_height)
        
    def update(self, delta_time: float) -> None:
        """更新所有环境效果"""
        self.day_night.update(delta_time)
        self.weather.update(delta_time)
        
        particle_config = self.weather.get_particle_config()
        self.renderer.update_particles(particle_config, delta_time)
        
    def get_combined_atmosphere(self) -> AtmosphereSettings:
        """获取合并后的氛围设置"""
        tod_atmosphere = self.day_night.get_atmosphere()
        weather_atmosphere = self.weather.get_atmosphere()
        
        # 合并两个氛围设置
        combined = AtmosphereSettings()
        
        # 色调混合
        t1 = tod_atmosphere.tint_intensity
        t2 = weather_atmosphere.tint_intensity
        total_t = t1 + t2
        if total_t > 0:
            combined.tint_color = tuple(
                int((tod_atmosphere.tint_color[i] * t1 + weather_atmosphere.tint_color[i] * t2) / total_t)
                for i in range(3)
            )
            combined.tint_intensity = min(1.0, total_t)
            
        # 光照
        combined.ambient_light = tod_atmosphere.ambient_light * weather_atmosphere.ambient_light
        combined.sun_angle = tod_atmosphere.sun_angle
        
        # 雾效
        combined.fog_color = weather_atmosphere.fog_color
        combined.fog_density = max(tod_atmosphere.fog_density, weather_atmosphere.fog_density)
        
        # 对比度和饱和度
        combined.contrast = tod_atmosphere.contrast * weather_atmosphere.contrast
        combined.saturation = tod_atmosphere.saturation * weather_atmosphere.saturation
        
        # 特效
        combined.bloom_intensity = max(tod_atmosphere.bloom_intensity, weather_atmosphere.bloom_intensity)
        combined.vignette_intensity = max(tod_atmosphere.vignette_intensity, weather_atmosphere.vignette_intensity)
        
        return combined
        
    def get_status_text(self) -> str:
        """获取状态文本"""
        time_str = self.day_night.get_time_string()
        weather_str = self.weather.get_weather_name()
        return f"{time_str}  {weather_str}"
        
    def render_particles(self) -> List[Tuple]:
        """渲染粒子"""
        config = self.weather.get_particle_config()
        return self.renderer.render_particles(config)
