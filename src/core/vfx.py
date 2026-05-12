import math
import random
from typing import List, Tuple, Optional
import arcade
from .config import VISUAL_CONFIG, WEATHER_TYPES, WEATHER_PARTICLE_COUNT, WEATHER_OVERLAY


class Particle:
    __slots__ = ['x', 'y', 'vx', 'vy', 'life', 'max_life', 'size', 'color', 'alpha', 'gravity', 'drag']

    def __init__(self, x, y, vx, vy, life, size, color, alpha=255, gravity=0, drag=1.0):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.life = life
        self.max_life = life
        self.size = size
        self.color = color
        self.alpha = alpha
        self.gravity = gravity
        self.drag = drag

    def update(self, dt):
        self.vy += self.gravity * dt
        self.vx *= self.drag
        self.vy *= self.drag
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.life -= dt

    @property
    def alive(self):
        return self.life > 0

    @property
    def progress(self):
        return 1.0 - max(0, self.life / self.max_life)


class DamageNumber:
    __slots__ = ['x', 'y', 'value', 'color', 'life', 'max_life', 'is_heal', 'is_crit']

    def __init__(self, x, y, value, color=(255, 80, 80), is_heal=False, is_crit=False):
        self.x = x
        self.y = y
        self.value = value
        self.color = color
        self.life = VISUAL_CONFIG["damage_number_duration"]
        self.max_life = self.life
        self.is_heal = is_heal
        self.is_crit = is_crit

    def update(self, dt):
        self.y += VISUAL_CONFIG["damage_number_rise_speed"] * dt
        self.life -= dt

    @property
    def alive(self):
        return self.life > 0

    @property
    def alpha(self):
        return int(255 * max(0, self.life / self.max_life))

    @property
    def scale(self):
        if self.is_crit:
            return 1.0 + 0.3 * math.sin(self.progress * math.pi)
        return 1.0 + 0.15 * math.sin(self.progress * math.pi)


class WeatherSystem:
    def __init__(self, sw, sh):
        self.sw = sw
        self.sh = sh
        self.current = "clear"
        self.particles: List[Particle] = []
        self.timer = 0
        self.change_interval = VISUAL_CONFIG["weather_change_interval"]
        self.wind = 0
        self.wind_target = 0
        self._transition_alpha = 0

    def update(self, dt):
        self.timer += dt
        if self.timer >= self.change_interval:
            self.timer = 0
            self._change_weather()

        self.wind += (self.wind_target - self.wind) * 0.02

        count = WEATHER_PARTICLE_COUNT.get(self.current, 0)
        while len(self.particles) < count:
            self._spawn_particle()

        alive = []
        for p in self.particles:
            p.update(dt)
            if p.alive and 0 <= p.x <= self.sw and -50 <= p.y <= self.sh + 50:
                alive.append(p)
        self.particles = alive

    def _change_weather(self):
        old = self.current
        while self.current == old:
            self.current = random.choice(WEATHER_TYPES)
        self.particles.clear()
        self.wind_target = random.uniform(-50, 50) if self.current in ("rain", "heavy_rain", "snow") else 0

    def _spawn_particle(self):
        if self.current == "rain":
            x = random.uniform(-50, self.sw + 50)
            y = random.uniform(self.sh, self.sh + 100)
            vx = self.wind + random.uniform(-10, 10)
            vy = random.uniform(-400, -300)
            self.particles.append(Particle(x, y, vx, vy, random.uniform(0.3, 0.8), 1, (180, 200, 230), 120, gravity=-20))
        elif self.current == "heavy_rain":
            x = random.uniform(-50, self.sw + 50)
            y = random.uniform(self.sh, self.sh + 100)
            vx = self.wind + random.uniform(-15, 15)
            vy = random.uniform(-600, -450)
            self.particles.append(Particle(x, y, vx, vy, random.uniform(0.2, 0.5), 2, (160, 180, 210), 150, gravity=-30))
        elif self.current == "snow":
            x = random.uniform(-50, self.sw + 50)
            y = random.uniform(self.sh, self.sh + 80)
            vx = self.wind + random.uniform(-20, 20)
            vy = random.uniform(-60, -30)
            self.particles.append(Particle(x, y, vx, vy, random.uniform(3, 7), random.uniform(2, 4), (230, 235, 245), 180, gravity=-5, drag=0.98))

    def draw(self):
        for p in self.particles:
            a = int(p.alpha * (1 - p.progress * 0.5))
            if p.size <= 1.5:
                arcade.draw_line(p.x, p.y, p.x + p.vx * 0.02, p.y + p.vy * 0.02, (*p.color[:3], min(255, a)))
            else:
                arcade.draw_circle_filled(p.x, p.y, p.size, (*p.color[:3], min(255, a)))

        overlay = WEATHER_OVERLAY.get(self.current)
        if overlay:
            arcade.draw_rect_filled(arcade.LBWH(0, 0, self.sw, self.sh), overlay)


class DayNightCycle:
    def __init__(self):
        self.time = 0.5
        self.speed = VISUAL_CONFIG["day_night_speed"]

    def update(self, dt):
        self.time = (self.time + self.speed * dt) % 1.0

    @property
    def hour(self):
        return self.time * 24

    @property
    def is_day(self):
        return 0.25 <= self.time <= 0.75

    @property
    def darkness(self):
        if 0.25 <= self.time <= 0.35:
            return 1.0 - (self.time - 0.25) / 0.1
        elif 0.35 < self.time < 0.65:
            return 0.0
        elif 0.65 <= self.time <= 0.75:
            return (self.time - 0.65) / 0.1
        else:
            return 1.0

    @property
    def tint(self):
        d = self.darkness
        if d <= 0:
            return (0, 0, 0, 0)
        if self.time < 0.25 or self.time > 0.75:
            r, g, b = 10, 10, 40
        elif self.time < 0.4:
            t = (self.time - 0.25) / 0.15
            r = int(40 * (1 - t))
            g = int(20 * (1 - t))
            b = int(30 * (1 - t))
            return (r, g, b, int(d * 80))
        elif self.time > 0.6:
            t = (self.time - 0.6) / 0.15
            r = int(60 * t)
            g = int(30 * t)
            b = int(20 * t)
            return (r, g, b, int(d * 100))
        else:
            r, g, b = 10, 10, 40
        return (r, g, b, int(d * 120))

    def draw(self, sw, sh):
        tint = self.tint
        if tint[3] > 0:
            arcade.draw_rect_filled(arcade.LBWH(0, 0, sw, sh), tint)


class VFXManager:
    def __init__(self, sw, sh):
        self.sw = sw
        self.sh = sh
        self.weather = WeatherSystem(sw, sh)
        self.day_night = DayNightCycle()
        self.particles: List[Particle] = []
        self.damage_numbers: List[DamageNumber] = []
        self.screen_shake_x = 0
        self.screen_shake_y = 0
        self.screen_shake_intensity = 0
        self.ambient_timer = 0

    def update(self, dt):
        if VISUAL_CONFIG["weather_enabled"]:
            self.weather.update(dt)
        if VISUAL_CONFIG["day_night_enabled"]:
            self.day_night.update(dt)

        alive = []
        for p in self.particles:
            p.update(dt)
            if p.alive:
                alive.append(p)
        self.particles = alive

        alive_dn = []
        for dn in self.damage_numbers:
            dn.update(dt)
            if dn.alive:
                alive_dn.append(dn)
        self.damage_numbers = alive_dn

        if self.screen_shake_intensity > 0.5:
            self.screen_shake_x = random.uniform(-1, 1) * self.screen_shake_intensity
            self.screen_shake_y = random.uniform(-1, 1) * self.screen_shake_intensity
            self.screen_shake_intensity *= VISUAL_CONFIG["screen_shake_decay"]
        else:
            self.screen_shake_x = 0
            self.screen_shake_y = 0
            self.screen_shake_intensity = 0

        if VISUAL_CONFIG["ambient_particles"]:
            self.ambient_timer += dt
            if self.ambient_timer > 0.3 and len(self.particles) < VISUAL_CONFIG["ambient_particle_count"]:
                self.ambient_timer = 0
                self._spawn_ambient()

    def _spawn_ambient(self):
        x = random.uniform(0, self.sw)
        y = random.uniform(0, self.sh)
        if self.day_night.is_day:
            color = (255, 255, 200)
            size = random.uniform(1, 2)
        else:
            color = (150, 200, 255)
            size = random.uniform(1, 3)
        self.particles.append(Particle(
            x, y, random.uniform(-5, 5), random.uniform(-10, -3),
            random.uniform(2, 5), size, color, 80, gravity=-2, drag=0.99
        ))

    def add_damage_number(self, x, y, value, is_heal=False, is_crit=False):
        if not VISUAL_CONFIG["damage_number_enabled"]:
            return
        color = (80, 255, 80) if is_heal else ((255, 255, 50) if is_crit else (255, 80, 80))
        self.damage_numbers.append(DamageNumber(x, y, value, color, is_heal, is_crit))

    def add_screen_shake(self, intensity=5):
        if VISUAL_CONFIG["screen_shake_enabled"]:
            self.screen_shake_intensity = max(self.screen_shake_intensity, intensity)

    def spawn_hit_particles(self, x, y, color=(255, 200, 100), count=8):
        for _ in range(count):
            angle = random.uniform(0, math.pi * 2)
            speed = random.uniform(30, 100)
            self.particles.append(Particle(
                x, y,
                math.cos(angle) * speed, math.sin(angle) * speed,
                random.uniform(0.2, 0.5), random.uniform(1, 3),
                color, 200, gravity=50, drag=0.95
            ))

    def spawn_heal_particles(self, x, y, count=6):
        for _ in range(count):
            self.particles.append(Particle(
                x + random.uniform(-15, 15), y,
                random.uniform(-5, 5), random.uniform(20, 60),
                random.uniform(0.5, 1.0), random.uniform(2, 4),
                (80, 255, 120), 180, gravity=-10, drag=0.98
            ))

    def spawn_levelup_particles(self, x, y, count=30):
        for _ in range(count):
            angle = random.uniform(0, math.pi * 2)
            speed = random.uniform(50, 150)
            self.particles.append(Particle(
                x, y,
                math.cos(angle) * speed, math.sin(angle) * speed,
                random.uniform(0.5, 1.5), random.uniform(2, 5),
                (255, 215, 0), 220, gravity=-30, drag=0.96
            ))

    def spawn_quest_particles(self, x, y, count=12):
        for _ in range(count):
            angle = random.uniform(0, math.pi * 2)
            speed = random.uniform(20, 60)
            self.particles.append(Particle(
                x, y,
                math.cos(angle) * speed, math.sin(angle) * speed,
                random.uniform(0.3, 0.8), random.uniform(2, 4),
                (100, 200, 255), 200, gravity=-20, drag=0.97
            ))

    def draw_particles(self):
        for p in self.particles:
            a = int(p.alpha * (1 - p.progress * 0.3))
            a = max(0, min(255, a))
            arcade.draw_circle_filled(p.x, p.y, p.size, (*p.color[:3], a))

    def draw_damage_numbers(self):
        for dn in self.damage_numbers:
            a = dn.alpha
            s = dn.scale
            size = int(16 * s)
            prefix = "+" if dn.is_heal else "-"
            text = f"{prefix}{dn.value}"
            if dn.is_crit:
                text = f"✦{text}✦"
            arcade.draw_text(text, dn.x, dn.y, (*dn.color[:3], a),
                             size, font_name="SimHei", anchor_x="center", anchor_y="center")

    def draw_weather(self):
        if VISUAL_CONFIG["weather_enabled"]:
            self.weather.draw()

    def draw_day_night(self):
        if VISUAL_CONFIG["day_night_enabled"]:
            self.day_night.draw(self.sw, self.sh)

    def draw_vignette(self):
        if not VISUAL_CONFIG["vignette_enabled"]:
            return
        intensity = VISUAL_CONFIG["vignette_intensity"]
        cx, cy = self.sw / 2, self.sh / 2
        max_r = math.sqrt(cx * cx + cy * cy)
        steps = 4
        for i in range(steps):
            t = i / steps
            r = max_r * (0.6 + 0.4 * t)
            alpha = int(intensity * 255 * t * t)
            alpha = min(255, max(0, alpha))
            arcade.draw_circle_outline(cx, cy, r, (0, 0, 0, alpha), max_r * 0.15)

    def get_camera_offset(self):
        return self.screen_shake_x, self.screen_shake_y
