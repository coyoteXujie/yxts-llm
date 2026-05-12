import math
import random
from typing import Tuple, List
from PIL import Image, ImageDraw, ImageFilter, ImageChops


def generate_noise(w: int, h: int, scale: float = 1.0, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('L', (w, h), 128)
    pixels = img.load()
    for y in range(h):
        for x in range(w):
            pixels[x, y] = rng.randint(0, 255)
    if scale != 1.0:
        sw, sh = max(1, int(w / scale)), max(1, int(h / scale))
        small = img.resize((sw, sh), Image.BILINEAR)
        img = small.resize((w, h), Image.BILINEAR)
    return img


def generate_perlin_noise(w: int, h: int, octaves: int = 4, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    result = Image.new('L', (w, h), 0)
    for octave in range(octaves):
        freq = 2 ** octave
        amp = 1.0 / (2 ** octave)
        gw = max(2, int(w * freq / 32) + 2)
        gh = max(2, int(h * freq / 32) + 2)
        grid = [[rng.random() for _ in range(gw)] for _ in range(gh)]
        layer = Image.new('L', (w, h), 0)
        lp = layer.load()
        for y in range(h):
            for x in range(w):
                gx = x * (gw - 1) / w
                gy = y * (gh - 1) / w
                ix, iy = int(gx), int(gy)
                fx, fy = gx - ix, gy - iy
                fx = fx * fx * (3 - 2 * fx)
                fy = fy * fy * (3 - 2 * fy)
                ix2 = min(ix + 1, gw - 1)
                iy2 = min(iy + 1, gh - 1)
                v = (grid[iy][ix] * (1 - fx) * (1 - fy) +
                     grid[iy][ix2] * fx * (1 - fy) +
                     grid[iy2][ix] * (1 - fx) * fy +
                     grid[iy2][ix2] * fx * fy)
                lp[x, y] = int(v * 255 * amp)
        result = ImageChops.add(result, layer)
    return result


def apply_texture_noise(img: Image.Image, intensity: float = 0.08, seed: int = 0) -> Image.Image:
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    noise = generate_noise(img.width, img.height, scale=3.0, seed=seed)
    noise = noise.filter(ImageFilter.GaussianBlur(radius=1))
    result = img.copy()
    pixels = result.load()
    npixels = noise.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            n = (npixels[x, y] - 128) / 128.0 * intensity
            r = max(0, min(255, int(r * (1 + n))))
            g = max(0, min(255, int(g * (1 + n))))
            b = max(0, min(255, int(b * (1 + n))))
            pixels[x, y] = (r, g, b, a)
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


def draw_radial_gradient(img: Image.Image, cx: int, cy: int, radius: int,
                          color_center: Tuple, color_edge: Tuple) -> Image.Image:
    result = img.copy()
    pixels = result.load()
    for y in range(max(0, cy - radius), min(img.height, cy + radius)):
        for x in range(max(0, cx - radius), min(img.width, cx + radius)):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist > radius:
                continue
            t = dist / radius
            t = t * t
            r = int(color_center[0] + (color_edge[0] - color_center[0]) * t)
            g = int(color_center[1] + (color_edge[1] - color_center[1]) * t)
            b = int(color_center[2] + (color_edge[2] - color_center[2]) * t)
            a = int(color_center[3] + (color_edge[3] - color_center[3]) * t) if len(color_center) > 3 else 255
            pr, pg, pb, pa = pixels[x, y]
            alpha = a / 255.0
            nr = int(pr * (1 - alpha) + r * alpha)
            ng = int(pg * (1 - alpha) + g * alpha)
            nb = int(pb * (1 - alpha) + b * alpha)
            pixels[x, y] = (nr, ng, nb, pa)
    return result


def create_bloom(img: Image.Image, radius: float = 8.0, threshold: int = 180,
                  intensity: float = 0.4) -> Image.Image:
    bright = img.copy()
    pixels = bright.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            lum = (r * 0.299 + g * 0.587 + b * 0.114)
            if lum < threshold:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                scale = (lum - threshold) / (255 - threshold)
                pixels[x, y] = (int(r * scale), int(g * scale), int(b * scale), int(a * scale * intensity))
    bright = bright.filter(ImageFilter.GaussianBlur(radius=radius))
    result = ImageChops.screen(img, bright) if img.mode == 'RGB' else img
    if img.mode == 'RGBA':
        result = Image.alpha_composite(img, bright)
    return result


def draw_soft_shadow(draw: ImageDraw.ImageDraw, cx: int, cy: int, w: int, h: int,
                      alpha: int = 40):
    for i in range(4):
        t = i / 4
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

    for _ in range(ts * ts // 8):
        nx = rng.randint(0, ts - 1)
        ny = rng.randint(0, ts - 1)
        nv = rng.randint(-12, 12)
        c = tuple(max(0, min(255, base[i] + nv)) for i in range(3))
        draw.point([nx, ny], fill=(*c, 255))

    img = apply_texture_noise(img, intensity=0.06, seed=seed + tid * 100)
    return img


def draw_water_tile(draw: ImageDraw.ImageDraw, px: int, py: int, ts: int,
                     base: Tuple, detail: Tuple, anim_offset: float = 0.0, seed: int = 0):
    rng = random.Random(seed)
    draw.rectangle([px, py, px + ts, py + ts], fill=(*base, 255))

    for i in range(5):
        wy = py + int((ts * (i + 1) / 6 + anim_offset * 3) % ts)
        wave_offset = int(math.sin(anim_offset + i * 0.8) * 4)
        alpha_val = 40 + i * 8
        draw.line([px + 4 + wave_offset, wy, px + ts - 4 + wave_offset, wy],
                   fill=(*detail, alpha_val), width=1)

    for _ in range(3):
        sx = px + rng.randint(8, ts - 8)
        sy = py + rng.randint(8, ts - 8)
        sr = rng.randint(2, 5)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr],
                      fill=(*detail, 25))

    for i in range(3):
        hy = py + int(ts * (0.3 + i * 0.25))
        hx_off = int(math.sin(anim_offset * 2 + i) * 6)
        draw.line([px + 8 + hx_off, hy, px + ts - 8 + hx_off, hy],
                   fill=(min(255, detail[0] + 60), min(255, detail[1] + 60),
                         min(255, detail[2] + 60), 50), width=1)


def draw_grass_detail(draw: ImageDraw.ImageDraw, px: int, py: int, ts: int,
                       base: Tuple, detail: Tuple, seed: int = 0):
    rng = random.Random(seed)
    for _ in range(8):
        gx = px + rng.randint(4, ts - 4)
        gy = py + rng.randint(ts // 2, ts - 4)
        gh = rng.randint(4, 10)
        lean = rng.randint(-3, 3)
        draw.line([gx, gy, gx + lean, gy - gh], fill=(*detail, 180), width=1)

    for _ in range(3):
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

    for _ in range(3):
        rx = px + rng.randint(4, ts - 4)
        ry = py + rng.randint(4, ts - 4)
        draw.rectangle([rx, ry, rx + 1, ry + 1], fill=(*detail, 80))
