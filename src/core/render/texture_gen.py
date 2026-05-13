import math
import random
from typing import Tuple, List
from PIL import Image, ImageDraw, ImageFilter, ImageChops


def apply_texture_noise(img: Image.Image, intensity: float = 0.08, seed: int = 0) -> Image.Image:
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    from PIL import ImageOps
    rng = random.Random(seed)
    small_w = max(1, img.width // 8)
    small_h = max(1, img.height // 8)
    noise_small = Image.new('L', (small_w, small_h))
    npx = noise_small.load()
    for y in range(small_h):
        for x in range(small_w):
            npx[x, y] = rng.randint(0, 255)
    noise = noise_small.resize(img.size, Image.BILINEAR)
    noise = noise.filter(ImageFilter.GaussianBlur(radius=1.5))
    r, g, b, a = img.split()
    noise_shift = noise.point(lambda x: int((x - 128) * intensity))
    r = ImageChops.add(r, noise_shift)
    g = ImageChops.add(g, noise_shift)
    b = ImageChops.add(b, noise_shift)
    result = Image.merge('RGBA', (r, g, b, a))
    return result


def draw_gradient_rect(draw: ImageDraw.ImageDraw, bbox: List[int],
                        color_top: Tuple, color_bot: Tuple, steps: int = 8):
    x1, y1, x2, y2 = bbox
    h = y2 - y1
    for i in range(steps):
        t = i / max(1, steps - 1)
        r = int(color_top[0] + (color_bot[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_bot[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_bot[2] - color_top[2]) * t)
        a = color_top[3] if len(color_top) > 3 else 255
        sy = y1 + int(h * i / steps)
        ey = y1 + int(h * (i + 1) / steps) + 1
        draw.rectangle([x1, sy, x2, ey], fill=(r, g, b, a))


def draw_soft_shadow(draw: ImageDraw.ImageDraw, cx: int, cy: int, w: int, h: int,
                      alpha: int = 40):
    for i in range(3):
        t = i / 3
        sw = int(w * (1 + t * 0.3))
        sh = int(h * (1 + t * 0.3))
        a = int(alpha * (1 - t))
        draw.ellipse([cx - sw // 2, cy - sh // 2, cx + sw // 2, cy + sh // 2],
                      fill=(0, 0, 0, a))


def make_tile_texture(tid: int, ts: int, palette: dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (ts, ts), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (128, 128, 128))
    detail = palette.get("detail", (100, 100, 100))
    accent = palette.get("accent", (150, 150, 150))
    draw.rectangle([0, 0, ts, ts], fill=(*base, 255))
    for _ in range(ts * ts // 16):
        nx = rng.randint(0, ts - 1)
        ny = rng.randint(0, ts - 1)
        nv = rng.randint(-12, 12)
        c = tuple(max(0, min(255, base[i] + nv)) for i in range(3))
        draw.point([nx, ny], fill=(*c, 255))
    return img


def draw_water_tile(draw: ImageDraw.ImageDraw, px: int, py: int, ts: int,
                     base: Tuple, detail: Tuple, anim_offset: float = 0.0, seed: int = 0):
    rng = random.Random(seed)
    draw.rectangle([px, py, px + ts, py + ts], fill=(*base, 255))
    highlight = (min(255, base[0] + 50), min(255, base[1] + 50), min(255, base[2] + 60))
    for i in range(6):
        wy = py + int((ts * (i + 1) / 7 + anim_offset * 3) % ts)
        wave_offset = int(math.sin(anim_offset + i * 0.8) * 5)
        draw.line([px + 3 + wave_offset, wy, px + ts - 3 + wave_offset, wy],
                   fill=(*highlight, 50 + i * 5), width=1)
    for _ in range(rng.randint(2, 5)):
        sx = px + rng.randint(6, ts - 6)
        sy = py + rng.randint(6, ts - 6)
        sr = rng.randint(3, 8)
        draw.ellipse([sx - sr, sy - sr // 2, sx + sr, sy + sr // 2],
                      fill=(*highlight, 30))


def draw_grass_detail(draw: ImageDraw.ImageDraw, px: int, py: int, ts: int,
                       base: Tuple, detail: Tuple, seed: int = 0):
    rng = random.Random(seed)
    for _ in range(6):
        gx = px + rng.randint(4, ts - 4)
        gy = py + rng.randint(ts // 2, ts - 4)
        gh = rng.randint(4, 10)
        lean = rng.randint(-3, 3)
        draw.line([gx, gy, gx + lean, gy - gh], fill=(*detail, 180), width=1)
    for _ in range(2):
        dx = px + rng.randint(8, ts - 8)
        dy = py + rng.randint(8, ts - 8)
        dc = (min(255, base[0] + rng.randint(10, 30)),
              min(255, base[1] + rng.randint(10, 30)),
              min(255, base[2] + rng.randint(0, 10)))
        draw.ellipse([dx - 1, dy - 1, dx + 1, dy + 1], fill=(*dc, 120))


def draw_road_detail(draw: ImageDraw.ImageDraw, px: int, py: int, ts: int,
                      base: Tuple, detail: Tuple, seed: int = 0):
    rng = random.Random(seed)
    for _ in range(6):
        rx = px + rng.randint(2, ts - 2)
        ry = py + rng.randint(2, ts - 2)
        rs = rng.randint(1, 3)
        draw.ellipse([rx - rs, ry - rs, rx + rs, ry + rs],
                      fill=(*detail, 100))
    edge_c = (max(0, base[0] - 25), max(0, base[1] - 22), max(0, base[2] - 18))
    draw.rectangle([px + 1, py + 1, px + ts - 1, py + 2], fill=(*edge_c, 40))
    draw.rectangle([px + 1, py + ts - 2, px + ts - 1, py + ts - 1], fill=(*edge_c, 40))
    draw.rectangle([px + 1, py + 1, px + 2, py + ts - 1], fill=(*edge_c, 40))
    draw.rectangle([px + ts - 2, py + 1, px + ts - 1, py + ts - 1], fill=(*edge_c, 40))
