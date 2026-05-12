import arcade
import math
from typing import Tuple, List, Optional
from ..config import VISUAL_CONFIG, GAME_CONFIG

SW = GAME_CONFIG["screen_width"]
SH = GAME_CONFIG["screen_height"]


class VolumetricLight:
    def __init__(self, wx: float, wy: float, radius: float = 150,
                 color: Tuple = (255, 200, 100), intensity: float = 0.6,
                 god_rays: bool = False, ray_angle: float = -1.57):
        self.wx = wx
        self.wy = wy
        self.radius = radius
        self.color = color
        self.intensity = intensity
        self.god_rays = god_rays
        self.ray_angle = ray_angle


class AdvancedLightSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._lights: List[VolumetricLight] = []
            cls._instance._ambient = 0.75
            cls._instance._time = 0
        return cls._instance

    def add_light(self, light: VolumetricLight):
        self._lights.append(light)

    def clear(self):
        self._lights.clear()

    def update(self, dt: float):
        self._time += dt

    def draw(self, cam_x: float, cam_y: float, day_progress: float = 0.5):
        self._draw_ambient_lighting(day_progress)
        self._draw_point_lights(cam_x, cam_y)
        self._draw_god_rays(cam_x, cam_y, day_progress)

    def _draw_ambient_lighting(self, day_progress: float):
        if day_progress < 0.2:
            t = day_progress / 0.2
            a = int(80 * (1 - t))
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (10, 10, 40, a))
        elif day_progress > 0.8:
            t = (day_progress - 0.8) / 0.2
            a = int(80 * t)
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (10, 10, 40, a))

        if day_progress < 0.15 or day_progress > 0.85:
            night_t = 1.0 - min(day_progress, 1.0 - day_progress) / 0.15
            blue_a = int(30 * night_t)
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (20, 30, 80, blue_a))

    def _draw_point_lights(self, cam_x: float, cam_y: float):
        for light in self._lights:
            sx = light.wx - cam_x + SW / 2
            sy = light.wy - cam_y + SH / 2
            if sx < -light.radius * 2 or sx > SW + light.radius * 2:
                continue
            if sy < -light.radius * 2 or sy > SH + light.radius * 2:
                continue

            pulse = 1.0 + 0.05 * math.sin(self._time * 2 + hash(id(light)) % 100 * 0.01)
            effective_intensity = light.intensity * pulse

            layers = 8
            for i in range(layers):
                t = i / layers
                r = light.radius * (1 - t * 0.6)
                a = int(effective_intensity * 30 * (1 - t * t))
                a = max(0, min(255, a))
                c = light.color[:3]
                arcade.draw_circle_filled(sx, sy, r, (c[0], c[1], c[2], a))

            core_r = light.radius * 0.15
            core_a = int(effective_intensity * 80)
            core_a = max(0, min(255, core_a))
            bright = tuple(min(255, c + 60) for c in light.color[:3])
            arcade.draw_circle_filled(sx, sy, core_r, (bright[0], bright[1], bright[2], core_a))

    def _draw_god_rays(self, cam_x: float, cam_y: float, day_progress: float):
        if not 0.2 < day_progress < 0.8:
            return
        for light in self._lights:
            if not light.god_rays:
                continue
            sx = light.wx - cam_x + SW / 2
            sy = light.wy - cam_y + SH / 2
            if sx < -200 or sx > SW + 200 or sy < -200 or sy > SH + 200:
                continue

            ray_count = 5
            for i in range(ray_count):
                angle = light.ray_angle + (i - ray_count // 2) * 0.15
                length = light.radius * 2.5
                ex = sx + math.cos(angle) * length
                ey = sy + math.sin(angle) * length
                ray_width = light.radius * 0.3
                pulse = 0.7 + 0.3 * math.sin(self._time * 0.5 + i * 0.7)
                a = int(light.intensity * 15 * pulse)
                a = max(0, min(255, a))
                c = light.color[:3]
                perp_x = -math.sin(angle) * ray_width
                perp_y = math.cos(angle) * ray_width
                points = [
                    (sx + perp_x * 0.3, sy + perp_y * 0.3),
                    (sx - perp_x * 0.3, sy - perp_y * 0.3),
                    (ex - perp_x, ey - perp_y),
                    (ex + perp_x, ey + perp_y),
                ]
                arcade.draw_polygon_filled(points, (c[0], c[1], c[2], a))


class PostProcessor:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._bloom_enabled = True
            cls._instance._color_grading = True
            cls._instance._vignette_enabled = True
            cls._instance._bloom_intensity = 0.12
            cls._instance._warm_shift = 6
            cls._instance._saturation = 1.15
            cls._instance._brightness = 1.08
            cls._instance._contrast = 1.1
            cls._instance._vignette_intensity = 0.4
            cls._instance._chromatic_aberration = 0.5
            cls._instance._time = 0
        return cls._instance

    def update(self, dt: float):
        self._time += dt

    def draw_all(self, day_progress: float = 0.5):
        self._draw_color_grading(day_progress)
        self._draw_bloom()
        self._draw_vignette()

    def _draw_color_grading(self, day_progress: float):
        if not self._color_grading:
            return

        if day_progress < 0.25:
            dawn_t = day_progress / 0.25
            warm = int(15 * (1 - dawn_t))
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (warm, warm // 3, 0, warm))
        elif day_progress > 0.75:
            dusk_t = (day_progress - 0.75) / 0.25
            warm = int(12 * dusk_t)
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (warm, warm // 4, 0, warm))

        if self._warm_shift > 0:
            a = min(8, self._warm_shift)
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (a, a // 3, 0, a))

        if self._brightness > 1.0:
            b = int((self._brightness - 1.0) * 15)
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (b, b, b, b))

    def _draw_bloom(self):
        if not self._bloom_enabled:
            return
        intensity = self._bloom_intensity
        for i in range(4):
            t = i / 4
            r = int(min(255, 220 + 35 * t))
            g = int(min(255, 200 + 55 * t))
            b = int(min(255, 140 + 115 * t))
            a = int(intensity * 6 * (1 - t * t))
            a = max(0, min(255, a))
            arcade.draw_lrbt_rectangle_filled(0, SW, 0, SH, (r, g, b, a))

    def _draw_vignette(self):
        if not self._vignette_enabled:
            return
        cx, cy = SW // 2, SH // 2
        max_r = math.sqrt(cx * cx + cy * cy)
        steps = 8
        for i in range(steps):
            t = i / steps
            r = max_r * (0.4 + 0.6 * t)
            a = int(self._vignette_intensity * 200 * t * t * t)
            a = max(0, min(255, a))
            thickness = max(1, int(max_r / steps * 1.5))
            arcade.draw_circle_outline(cx, cy, r, (0, 0, 0, a), thickness)


class EnvironmentParticles:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._fireflies: List[dict] = []
            cls._instance._leaves: List[dict] = []
            cls._instance._fog_patches: List[dict] = []
            cls._instance._time = 0
            cls._instance._initialized = False
        return cls._instance

    def init(self, sw: int, sh: int):
        if self._initialized:
            return
        self._initialized = True
        import random
        for _ in range(15):
            self._fireflies.append({
                'x': random.randint(0, sw), 'y': random.randint(0, sh),
                'phase': random.random() * 6.28, 'speed': random.uniform(0.3, 0.8),
                'radius': random.uniform(2, 4), 'wander_x': random.uniform(-0.5, 0.5),
                'wander_y': random.uniform(-0.3, 0.3),
            })
        for _ in range(8):
            self._leaves.append({
                'x': random.randint(0, sw), 'y': random.randint(-20, sh),
                'vx': random.uniform(-0.5, 0.5), 'vy': random.uniform(0.3, 0.8),
                'rot': random.random() * 6.28, 'rot_speed': random.uniform(-0.02, 0.02),
                'size': random.randint(3, 6), 'color': random.choice([
                    (180, 120, 40), (200, 150, 50), (160, 100, 30), (140, 80, 20)
                ]),
            })
        for _ in range(5):
            self._fog_patches.append({
                'x': random.randint(0, sw), 'y': random.randint(0, sh),
                'radius': random.randint(60, 150), 'alpha': random.randint(8, 20),
                'vx': random.uniform(-0.2, 0.2), 'phase': random.random() * 6.28,
            })

    def update(self, dt: float, day_progress: float = 0.5):
        self._time += dt
        is_night = day_progress < 0.25 or day_progress > 0.75

        for f in self._fireflies:
            f['phase'] += dt * f['speed']
            f['x'] += f['wander_x'] + math.sin(self._time * 0.5 + f['phase']) * 0.3
            f['y'] += f['wander_y'] + math.cos(self._time * 0.3 + f['phase']) * 0.2
            if f['x'] < -20: f['x'] = SW + 20
            if f['x'] > SW + 20: f['x'] = -20
            if f['y'] < -20: f['y'] = SH + 20
            if f['y'] > SH + 20: f['y'] = -20

        for leaf in self._leaves:
            leaf['x'] += leaf['vx'] + math.sin(self._time + leaf['rot']) * 0.3
            leaf['y'] += leaf['vy']
            leaf['rot'] += leaf['rot_speed']
            if leaf['y'] > SH + 20:
                leaf['y'] = -20
                leaf['x'] = leaf['x'] % SW

        for fog in self._fog_patches:
            fog['x'] += fog['vx']
            fog['phase'] += dt * 0.1
            if fog['x'] < -fog['radius']: fog['x'] = SW + fog['radius']
            if fog['x'] > SW + fog['radius']: fog['x'] = -fog['radius']

    def draw(self, day_progress: float = 0.5):
        is_night = day_progress < 0.25 or day_progress > 0.75

        if is_night:
            for f in self._fireflies:
                glow = 0.5 + 0.5 * math.sin(f['phase'] * 3)
                a = int(180 * glow)
                r = f['radius'] * (0.8 + 0.4 * glow)
                arcade.draw_circle_filled(f['x'], f['y'], r + 4, (200, 255, 100, int(a * 0.2)))
                arcade.draw_circle_filled(f['x'], f['y'], r, (220, 255, 150, a))
                arcade.draw_circle_filled(f['x'], f['y'], r * 0.5, (255, 255, 200, min(255, a + 50)))

        for leaf in self._leaves:
            c = leaf['color']
            a = 180
            s = leaf['size']
            dx = int(math.cos(leaf['rot']) * s)
            dy = int(math.sin(leaf['rot']) * s)
            arcade.draw_line(leaf['x'] - dx, leaf['y'] - dy, leaf['x'] + dx, leaf['y'] + dy,
                              (c[0], c[1], c[2], a), 2)

        for fog in self._fog_patches:
            pulse = 0.8 + 0.2 * math.sin(fog['phase'])
            a = int(fog['alpha'] * pulse)
            r = fog['radius']
            arcade.draw_circle_filled(fog['x'], fog['y'], r, (200, 210, 220, a))


def get_advanced_lights() -> AdvancedLightSystem:
    return AdvancedLightSystem()


def get_post_processor() -> PostProcessor:
    return PostProcessor()


def get_env_particles() -> EnvironmentParticles:
    return EnvironmentParticles()
