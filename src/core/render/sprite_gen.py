import math
import random
from typing import Tuple, List, Optional, Dict
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont

TS = 64
SPRITE_SCALE = 2
STS = TS * SPRITE_SCALE


def _clamp(v, lo=0, hi=255):
    return max(lo, min(hi, int(v)))


def _shade(color: Tuple, factor: float) -> Tuple:
    return tuple(_clamp(c * factor) for c in color[:3]) + (color[3] if len(color) > 3 else (255,))


def _highlight(color: Tuple, amount: int = 40) -> Tuple:
    return tuple(_clamp(c + amount) for c in color[:3]) + (color[3] if len(color) > 3 else (255,))


def _darken(color: Tuple, amount: int = 30) -> Tuple:
    return tuple(_clamp(c - amount) for c in color[:3]) + (color[3] if len(color) > 3 else (255,))


def _alpha_color(color: Tuple, alpha: int) -> Tuple:
    return color[:3] + (_clamp(alpha),)


def _add_pixel_noise(img: Image.Image, intensity: float = 0.04, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    result = img.copy()
    pixels = result.load()
    for y in range(0, img.height, SPRITE_SCALE):
        for x in range(0, img.width, SPRITE_SCALE):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            n = rng.gauss(0, intensity * 128)
            for dy in range(SPRITE_SCALE):
                for dx in range(SPRITE_SCALE):
                    px, py = x + dx, y + dy
                    if px < img.width and py < img.height:
                        pr, pg, pb, pa = pixels[px, py]
                        if pa > 0:
                            pixels[px, py] = (_clamp(pr + n), _clamp(pg + n), _clamp(pb + n), pa)
    return result


def _draw_rounded_rect(draw: ImageDraw.ImageDraw, bbox: List[int], radius: int, fill: Tuple = None, outline: Tuple = None, width: int = 0):
    x1, y1, x2, y2 = bbox
    r = min(radius, (x2 - x1) // 2, (y2 - y1) // 2)
    if fill:
        draw.rectangle([x1 + r, y1, x2 - r, y2], fill=fill)
        draw.rectangle([x1, y1 + r, x2, y2 - r], fill=fill)
        draw.pieslice([x1, y1, x1 + 2 * r, y1 + 2 * r], 180, 270, fill=fill)
        draw.pieslice([x2 - 2 * r, y1, x2, y1 + 2 * r], 270, 360, fill=fill)
        draw.pieslice([x1, y2 - 2 * r, x1 + 2 * r, y2], 90, 180, fill=fill)
        draw.pieslice([x2 - 2 * r, y2 - 2 * r, x2, y2], 0, 90, fill=fill)
    if outline:
        draw.arc([x1, y1, x1 + 2 * r, y1 + 2 * r], 180, 270, outline, width)
        draw.arc([x2 - 2 * r, y1, x2, y1 + 2 * r], 270, 360, outline, width)
        draw.arc([x1, y2 - 2 * r, x1 + 2 * r, y2], 90, 180, outline, width)
        draw.arc([x2 - 2 * r, y2 - 2 * r, x2, y2], 0, 90, outline, width)
        draw.line([x1 + r, y1, x2 - r, y1], outline, width)
        draw.line([x1 + r, y2, x2 - r, y2], outline, width)
        draw.line([x1, y1 + r, x1, y2 - r], outline, width)
        draw.line([x2, y1 + r, x2, y2 - r], outline, width)


def _draw_gradient_rect(draw: ImageDraw.ImageDraw, bbox: List[int], color_top: Tuple, color_bot: Tuple, steps: int = 16):
    x1, y1, x2, y2 = bbox
    h = y2 - y1
    for i in range(steps):
        t = i / max(1, steps - 1)
        c = tuple(_clamp(color_top[j] + (color_bot[j] - color_top[j]) * t) for j in range(3))
        a = _clamp(color_top[3] + (color_bot[3] - color_top[3]) * t) if len(color_top) > 3 else 255
        sy = y1 + int(h * i / steps)
        ey = y1 + int(h * (i + 1) / steps) + 1
        draw.rectangle([x1, sy, x2, ey], fill=c + (a,))


def _draw_radial_glow(img: Image.Image, cx: int, cy: int, radius: int, color: Tuple, intensity: float = 1.0) -> Image.Image:
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    layers = 8
    for i in range(layers):
        t = i / layers
        r = int(radius * (1 - t * 0.7))
        a = int(intensity * 60 * (1 - t * t))
        a = _clamp(a)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color[:3] + (a,))
    return Image.alpha_composite(img, overlay)


def _draw_soft_shadow_ellipse(draw: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, ry: int, alpha: int = 50):
    for i in range(5):
        t = i / 5
        erx = int(rx * (1 + t * 0.5))
        ery = int(ry * (1 + t * 0.3))
        ea = int(alpha * (1 - t * 0.7))
        draw.ellipse([cx - erx, cy - ery, cx + erx, cy + ery], fill=(0, 0, 0, ea))


# ==================== TILE SPRITES ====================

def gen_grass_tile(palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (76, 153, 0))
    detail = palette.get("detail", (60, 130, 0))
    accent = palette.get("accent", (90, 170, 20))

    for y in range(0, STS, SPRITE_SCALE):
        for x in range(0, STS, SPRITE_SCALE):
            n = rng.gauss(0, 12)
            c = tuple(_clamp(base[i] + n) for i in range(3))
            draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (255,))

    for _ in range(20):
        gx = rng.randint(4, STS - 4)
        gy = rng.randint(STS // 3, STS - 4)
        gh = rng.randint(6, 16)
        lean = rng.randint(-4, 4)
        shade = rng.choice([detail, accent, _highlight(base, 20)])
        shade_rgb = shade[:3]
        for dy in range(0, gh, SPRITE_SCALE):
            px = gx + int(lean * dy / gh)
            py = gy - dy
            draw.rectangle([px, py, px + SPRITE_SCALE - 1, py + SPRITE_SCALE - 1], fill=shade_rgb + (200,))

    for _ in range(5):
        fx = rng.randint(8, STS - 8)
        fy = rng.randint(8, STS - 8)
        fc = rng.choice([(255, 100, 100), (255, 200, 50), (200, 100, 255), (255, 150, 200), (100, 200, 255)])
        for dy in range(-2, 3, SPRITE_SCALE):
            for dx in range(-2, 3, SPRITE_SCALE):
                if dx * dx + dy * dy <= 5:
                    draw.rectangle([fx + dx, fy + dy, fx + dx + SPRITE_SCALE - 1, fy + dy + SPRITE_SCALE - 1],
                                    fill=fc + (180,))

    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_water_tile(palette: Dict, anim_frame: int = 0, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (40, 80, 160))
    detail = palette.get("detail", (60, 100, 180))
    deep = _darken(base, 40)
    shallow = _highlight(base, 30)

    for y in range(0, STS, SPRITE_SCALE):
        for x in range(0, STS, SPRITE_SCALE):
            wave = math.sin((x + anim_frame * 8) * 0.05) * 0.3 + math.sin((y + anim_frame * 5) * 0.07) * 0.2
            depth = 0.5 + wave * 0.5
            c = tuple(_clamp(deep[i] + (shallow[i] - deep[i]) * depth) for i in range(3))
            draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (230,))

    for i in range(8):
        wy = int((STS * (i + 1) / 9 + anim_frame * 3) % STS)
        wave_x = int(math.sin(anim_frame * 0.3 + i * 0.9) * 8)
        for x in range(4, STS - 4, SPRITE_SCALE):
            offset = int(math.sin((x + wave_x) * 0.1 + anim_frame * 0.2) * 3)
            draw.rectangle([x, wy + offset, x + SPRITE_SCALE - 1, wy + offset + SPRITE_SCALE - 1],
                            fill=_highlight(base, 50)[:3] + (60,))

    for _ in range(4):
        cx = rng.randint(16, STS - 16)
        cy = rng.randint(16, STS - 16)
        cr = rng.randint(6, 14)
        phase = anim_frame * 0.15 + rng.random() * 6.28
        for angle_i in range(12):
            a = angle_i / 12 * 6.28 + phase
            px = int(cx + math.cos(a) * cr * (0.5 + 0.5 * math.sin(phase * 2)))
            py = int(cy + math.sin(a) * cr * (0.5 + 0.5 * math.sin(phase * 2)))
            if 0 <= px < STS and 0 <= py < STS:
                draw.rectangle([px, py, px + SPRITE_SCALE - 1, py + SPRITE_SCALE - 1],
                                fill=(180, 220, 255, 40))

    img = _add_pixel_noise(img, 0.02, seed + anim_frame)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_road_tile(palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (140, 120, 90))
    detail = palette.get("detail", (120, 100, 70))

    for y in range(0, STS, SPRITE_SCALE):
        for x in range(0, STS, SPRITE_SCALE):
            n = rng.gauss(0, 8)
            c = tuple(_clamp(base[i] + n) for i in range(3))
            draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (255,))

    for _ in range(15):
        sx = rng.randint(2, STS - 2)
        sy = rng.randint(2, STS - 2)
        sc = _darken(detail, rng.randint(0, 20))[:3]
        draw.rectangle([sx, sy, sx + SPRITE_SCALE, sy + SPRITE_SCALE], fill=sc + (180,))

    for _ in range(4):
        cx = rng.randint(8, STS - 8)
        cy = rng.randint(8, STS - 8)
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if rng.random() < 0.6:
                    draw.rectangle([cx + dx * SPRITE_SCALE, cy + dy * SPRITE_SCALE,
                                     cx + dx * SPRITE_SCALE + SPRITE_SCALE - 1,
                                     cy + dy * SPRITE_SCALE + SPRITE_SCALE - 1],
                                    fill=_darken(base, 25)[:3] + (150,))

    img = _add_pixel_noise(img, 0.04, seed)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_tree_tile(tid: int, palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (34, 100, 34))
    detail = palette.get("detail", (50, 130, 50))
    accent = palette.get("accent", (80, 160, 40))
    trunk = (90, 60, 30)

    _draw_soft_shadow_ellipse(draw, STS // 2 + 4, STS - 8, 22, 8, alpha=45)

    tw = 6 * SPRITE_SCALE
    tx = STS // 2 - tw // 2
    for y in range(STS // 2, STS - 6, SPRITE_SCALE):
        n = rng.gauss(0, 5)
        tc = tuple(_clamp(trunk[i] + n) for i in range(3))
        draw.rectangle([tx, y, tx + tw, y + SPRITE_SCALE - 1], fill=tc + (255,))

    if tid == 51:
        layers = [(0, STS // 3, STS * 0.42, base),
                  (-4, STS // 4, STS * 0.35, detail),
                  (-8, STS // 6, STS * 0.25, accent)]
        for ox, oy, r, color in layers:
            cx, cy = STS // 2 + ox, STS // 2 + oy
            for y in range(int(cy - r), int(cy + r), SPRITE_SCALE):
                for x in range(int(cx - r), int(cx + r), SPRITE_SCALE):
                    dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
                    if dist < r:
                        shade = 1.0 - (dist / r) * 0.3
                        n = rng.gauss(0, 8)
                        c = tuple(_clamp(color[i] * shade + n) for i in range(3))
                        a = int(255 * (1 - (dist / r) ** 2 * 0.3))
                        draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (a,))
    else:
        cx, cy = STS // 2, STS // 3
        r = STS * 0.38
        for y in range(int(cy - r), int(cy + r), SPRITE_SCALE):
            for x in range(int(cx - r), int(cx + r), SPRITE_SCALE):
                dist = math.sqrt((x - cx) ** 2 + ((y - cy) * 1.3) ** 2)
                if dist < r:
                    shade = 1.0 - (dist / r) * 0.4
                    n = rng.gauss(0, 10)
                    c = tuple(_clamp(base[i] * shade + n) for i in range(3))
                    a = int(255 * (1 - (dist / r) ** 3 * 0.5))
                    draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (a,))

    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_wall_tile(palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (160, 150, 140))
    detail = palette.get("detail", (140, 130, 120))

    draw.rectangle([0, 0, STS, STS], fill=base + (255,))

    bh = 8 * SPRITE_SCALE
    bw = 16 * SPRITE_SCALE
    for row in range(0, STS, bh):
        offset = (bw // 2) if (row // bh) % 2 else 0
        for col in range(-bw, STS + bw, bw):
            x1 = max(0, col + offset)
            x2 = min(STS - 1, col + offset + bw - 1)
            y1 = row
            y2 = row + bh - 1
            if x2 <= x1 or y2 <= y1:
                continue
            n = rng.gauss(0, 6)
            bc = tuple(_clamp(detail[i] + n) for i in range(3))
            draw.rectangle([x1, y1, x2, y2], fill=bc + (255,))
            draw.rectangle([x1, y1, x2, y1 + SPRITE_SCALE - 1], fill=_darken(detail, 15)[:3] + (200,))
            if x1 > 0:
                draw.rectangle([x1, y1, x1 + SPRITE_SCALE - 1, y2], fill=_darken(detail, 10)[:3] + (180,))

    for _ in range(3):
        wx = rng.randint(4, STS - 12)
        wy = rng.randint(4, STS - 12)
        ww = rng.randint(6, 10) * SPRITE_SCALE
        wh = rng.randint(6, 10) * SPRITE_SCALE
        draw.rectangle([wx, wy, wx + ww, wy + wh], fill=_darken(base, 40)[:3] + (255,))
        draw.rectangle([wx + SPRITE_SCALE, wy + SPRITE_SCALE, wx + ww - SPRITE_SCALE, wy + wh - SPRITE_SCALE],
                        fill=(40, 50, 70, 200))

    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_building_tile(tid: int, palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (180, 160, 130))
    detail = palette.get("detail", (150, 130, 100))
    accent = palette.get("accent", (200, 180, 150))
    roof_color = (120, 50, 30)

    _draw_soft_shadow_ellipse(draw, STS // 2, STS - 4, 28, 6, alpha=40)

    wall_y = STS // 3
    _draw_gradient_rect(draw, [4, wall_y, STS - 4, STS - 4],
                         _highlight(base, 10)[:3] + (255,), _darken(base, 15)[:3] + (255,))

    for y in range(wall_y, STS - 4, SPRITE_SCALE * 2):
        for x in range(4, STS - 4, SPRITE_SCALE * 2):
            if rng.random() < 0.15:
                n = rng.gauss(0, 8)
                c = tuple(_clamp(detail[i] + n) for i in range(3))
                draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (150,))

    door_w = 10 * SPRITE_SCALE
    door_h = 14 * SPRITE_SCALE
    door_x = STS // 2 - door_w // 2
    door_y = STS - 4 - door_h
    _draw_rounded_rect(draw, [door_x, door_y, door_x + door_w, door_y + door_h],
                        3 * SPRITE_SCALE, fill=_darken(base, 50)[:3] + (255,))
    draw.rectangle([door_x + 2, door_y + 2, door_x + door_w - 2, door_y + door_h],
                    fill=(30, 20, 15, 220))
    draw.ellipse([door_x + door_w - 5 * SPRITE_SCALE, door_y + door_h // 2 - SPRITE_SCALE,
                   door_x + door_w - 3 * SPRITE_SCALE, door_y + door_h // 2 + SPRITE_SCALE],
                  fill=(200, 180, 50, 255))

    win_w = 6 * SPRITE_SCALE
    win_h = 6 * SPRITE_SCALE
    for wx_off in [-14, 14]:
        wx = STS // 2 + wx_off * SPRITE_SCALE - win_w // 2
        wy = wall_y + 6 * SPRITE_SCALE
        draw.rectangle([wx, wy, wx + win_w, wy + win_h], fill=(40, 50, 70, 230))
        glow_c = (255, 220, 120, 40)
        draw.rectangle([wx - 2, wy - 2, wx + win_w + 2, wy + win_h + 2], fill=glow_c)
        draw.line([wx + win_w // 2, wy, wx + win_w // 2, wy + win_h], fill=(80, 80, 80, 180), width=1)
        draw.line([wx, wy + win_h // 2, wx + win_w, wy + win_h // 2], fill=(80, 80, 80, 180), width=1)

    roof_pts = [(0, wall_y + 2), (STS // 2, 4), (STS, wall_y + 2)]
    draw.polygon(roof_pts, fill=roof_color + (255,))
    for y in range(4, wall_y + 2, SPRITE_SCALE * 2):
        t = (y - 4) / max(1, wall_y - 2)
        cx = STS // 2
        half_w = t * STS // 2
        n = rng.gauss(0, 5)
        rc = tuple(_clamp(roof_color[i] + n - 15) for i in range(3))
        draw.line([int(cx - half_w), y, int(cx + half_w), y], fill=rc + (200,), width=SPRITE_SCALE)
    draw.line([0, wall_y + 2, STS, wall_y + 2], fill=_darken(roof_color, 30)[:3] + (255,), width=SPRITE_SCALE * 2)

    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


def gen_flower_tile(palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = gen_grass_tile(palette, seed)
    img = img.resize((STS, STS), Image.LANCZOS)
    draw = ImageDraw.Draw(img)

    flower_colors = [(255, 100, 100), (255, 200, 50), (200, 100, 255), (255, 150, 200), (100, 200, 255)]
    for _ in range(rng.randint(3, 6)):
        fx = rng.randint(8, STS - 8)
        fy = rng.randint(8, STS - 8)
        fc = rng.choice(flower_colors)
        petal_r = rng.randint(3, 6) * SPRITE_SCALE
        for p in range(5):
            angle = p / 5 * 6.28 + rng.random()
            px = int(fx + math.cos(angle) * petal_r * 0.6)
            py = int(fy + math.sin(angle) * petal_r * 0.6)
            draw.ellipse([px - petal_r // 2, py - petal_r // 2, px + petal_r // 2, py + petal_r // 2],
                          fill=fc + (220,))
        center_r = petal_r // 3
        draw.ellipse([fx - center_r, fy - center_r, fx + center_r, fy + center_r],
                      fill=(255, 255, 100, 255))

    return img.resize((TS, TS), Image.LANCZOS)


def gen_hill_tile(palette: Dict, seed: int = 0) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (100, 140, 60))
    detail = palette.get("detail", (80, 120, 40))

    cx, cy = STS // 2, STS * 2 // 3
    rx, ry = STS // 2, STS // 3
    for y in range(cy - ry, STS, SPRITE_SCALE):
        for x in range(0, STS, SPRITE_SCALE):
            dist = math.sqrt(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2)
            if dist < 1.0:
                shade = 1.0 - dist * 0.35
                n = rng.gauss(0, 8)
                c = tuple(_clamp(base[i] * shade + n) for i in range(3))
                a = int(255 * (1 - dist ** 2 * 0.3))
                draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (a,))

    highlight_y = cy - ry // 2
    for x in range(cx - rx // 3, cx + rx // 3, SPRITE_SCALE):
        n = rng.gauss(0, 5)
        c = tuple(_clamp(_highlight(base, 25)[i] + n) for i in range(3))
        draw.rectangle([x, highlight_y, x + SPRITE_SCALE - 1, highlight_y + SPRITE_SCALE - 1], fill=c + (120,))

    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


TILE_GENERATORS = {}


def _register_generators():
    global TILE_GENERATORS
    TILE_GENERATORS = {
        0: gen_grass_tile,
        1: gen_road_tile,
        2: gen_water_tile,
        3: gen_building_tile,
        4: gen_tree_tile,
        5: gen_grass_tile,
        6: gen_road_tile,
    }


_register_generators()


def generate_tile_sprite(tid: int, palette: Dict, anim_frame: int = 0, seed: int = 0) -> Image.Image:
    gen_fn = TILE_GENERATORS.get(tid)
    if gen_fn:
        if tid == 2:
            return gen_fn(palette, anim_frame=anim_frame, seed=seed)
        if tid in (3, 4):
            return gen_fn(tid, palette, seed=seed)
        return gen_fn(palette, seed=seed)

    img = Image.new('RGBA', (STS, STS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = palette.get("base", (128, 128, 128))
    for y in range(0, STS, SPRITE_SCALE):
        for x in range(0, STS, SPRITE_SCALE):
            rng = random.Random(seed + x * 1000 + y)
            n = rng.gauss(0, 8)
            c = tuple(_clamp(base[i] + n) for i in range(3))
            draw.rectangle([x, y, x + SPRITE_SCALE - 1, y + SPRITE_SCALE - 1], fill=c + (255,))
    img = _add_pixel_noise(img, 0.03, seed)
    return img.resize((TS, TS), Image.LANCZOS)


# ==================== CHARACTER SPRITES ====================

def gen_character_sprite(skin_color: Tuple, hair_color: Tuple, cloth_color: Tuple,
                          cloth_color2: Tuple = None, weapon: str = None,
                          direction: str = "down", frame: int = 0,
                          body_scale: float = 1.0, gender: str = "male",
                          persona: str = "commoner") -> Image.Image:
    size = 48
    scale = 2
    ss = size * scale
    img = Image.new('RGBA', (ss, ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = ss // 2

    walk_offset = int(math.sin(frame * 1.2) * 2 * scale) if frame > 0 else 0
    breathe = int(math.sin(frame * 0.8) * scale * 0.5)

    shadow_y = ss - 4 * scale
    for i in range(3):
        t = i / 3
        sr = int(10 * scale * (1 + t * 0.3))
        sa = int(35 * (1 - t * 0.5))
        draw.ellipse([cx - sr, shadow_y - 3 * scale + i, cx + sr, shadow_y + 3 * scale + i],
                      fill=(0, 0, 0, sa))

    body_top = ss // 2 - 4 * scale + breathe
    body_bot = shadow_y - 2 * scale
    body_w = int(10 * scale * body_scale)
    body_h = body_bot - body_top

    _draw_gradient_rect(draw, [cx - body_w // 2, body_top, cx + body_w // 2, body_bot],
                         _highlight(cloth_color, 15)[:3] + (255,), _darken(cloth_color, 20)[:3] + (255,))

    if cloth_color2:
        belt_y = body_top + body_h // 3
        draw.rectangle([cx - body_w // 2, belt_y, cx + body_w // 2, belt_y + 2 * scale],
                         fill=cloth_color2 + (255,))

    leg_spread = 3 * scale
    leg_w = 3 * scale
    for side in [-1, 1]:
        lx = cx + side * leg_spread
        ly = body_bot
        lh = shadow_y - body_bot + 2 * scale
        leg_off = walk_offset * side
        draw.rectangle([lx - leg_w // 2 + leg_off, ly, lx + leg_w // 2 + leg_off, ly + lh],
                         fill=_darken(cloth_color, 30)[:3] + (255,))
        draw.rectangle([lx - leg_w // 2 + leg_off, ly + lh - 2 * scale,
                         lx + leg_w // 2 + leg_off, ly + lh],
                         fill=_darken(skin_color, 10)[:3] + (255,))

    arm_w = 3 * scale
    arm_h = body_h * 2 // 3
    for side in [-1, 1]:
        ax = cx + side * (body_w // 2 + arm_w // 2)
        ay = body_top + 2 * scale
        arm_swing = walk_offset * (-side) if frame > 0 else 0
        draw.rectangle([ax - arm_w // 2, ay + arm_swing, ax + arm_w // 2, ay + arm_h + arm_swing],
                         fill=_shade(cloth_color, 0.85)[:3] + (255,))
        draw.rectangle([ax - arm_w // 2, ay + arm_h + arm_swing - 2 * scale,
                         ax + arm_w // 2, ay + arm_h + arm_swing],
                         fill=skin_color + (255,))

    head_r = int(8 * scale * (0.95 if gender == "female" else 1.0))
    head_y = body_top - head_r + 2 * scale + breathe

    draw.ellipse([cx - head_r, head_y - head_r, cx + head_r, head_y + head_r],
                  fill=_darken(skin_color, 15)[:3] + (255,))
    draw.ellipse([cx - head_r + 2, head_y - head_r + 2, cx + head_r - 2, head_y + head_r - 2],
                  fill=skin_color + (255,))
    highlight_r = head_r * 2 // 3
    draw.ellipse([cx - highlight_r + 2, head_y - highlight_r, cx + highlight_r - 2, head_y + highlight_r // 2],
                  fill=_highlight(skin_color, 20)[:3] + (100,))

    if direction != "up":
        eye_y = head_y - 1 * scale
        for side in [-1, 1]:
            ex = cx + side * 3 * scale
            draw.ellipse([ex - 2 * scale, eye_y - 1 * scale, ex + 2 * scale, eye_y + 2 * scale],
                          fill=(255, 255, 255, 240))
            draw.ellipse([ex - 1 * scale, eye_y, ex + 1 * scale, eye_y + 1.5 * scale],
                          fill=(30, 20, 15, 255))
            draw.rectangle([ex, eye_y, ex + scale, eye_y + scale], fill=(255, 255, 255, 200))

        mouth_y = head_y + 4 * scale
        if persona in ("fierce", "dark_warrior", "dark_master"):
            draw.line([cx - 3 * scale, mouth_y, cx + 3 * scale, mouth_y], fill=(150, 30, 20, 200), width=scale)
        else:
            draw.arc([cx - 2 * scale, mouth_y - 1 * scale, cx + 2 * scale, mouth_y + 2 * scale],
                      0, 180, fill=(120, 60, 50, 180), width=scale)

    hair_top = head_y - head_r - 2 * scale
    if gender == "female":
        draw.ellipse([cx - head_r - 2 * scale, hair_top, cx + head_r + 2 * scale, head_y + head_r],
                      fill=hair_color + (255,))
        for side in [-1, 1]:
            hx = cx + side * (head_r + 1 * scale)
            draw.rectangle([hx - 3 * scale, head_y - 2 * scale, hx + 3 * scale, head_y + head_r + 4 * scale],
                             fill=hair_color + (230,))
    else:
        draw.ellipse([cx - head_r - 1 * scale, hair_top, cx + head_r + 1 * scale, head_y + 2 * scale],
                      fill=hair_color + (255,))

    if weapon and direction != "up":
        wx = cx + (body_w // 2 + 6 * scale) * (1 if direction == "right" else -1 if direction == "left" else 1)
        wy = body_top + 4 * scale
        weapon_colors = {
            "sword": (180, 190, 210), "blade": (200, 180, 160), "staff": (140, 100, 60),
            "whip": (100, 70, 40), "hammer": (150, 150, 160), "cleaver": (180, 180, 190), "fan": (200, 180, 220),
        }
        wc = weapon_colors.get(weapon, (180, 180, 180))
        if weapon == "sword":
            draw.line([wx, wy, wx, wy - 16 * scale], fill=wc + (255,), width=2 * scale)
            draw.line([wx - 3 * scale, wy, wx + 3 * scale, wy], fill=(160, 140, 50) + (255,), width=scale)
            draw.rectangle([wx - scale, wy - 16 * scale, wx + scale, wy - 14 * scale],
                             fill=_highlight(wc, 40)[:3] + (255,))
        elif weapon == "blade":
            draw.line([wx, wy, wx + 2 * scale, wy - 14 * scale], fill=wc + (255,), width=3 * scale)
            draw.line([wx - 2 * scale, wy, wx + 4 * scale, wy], fill=(160, 140, 50) + (255,), width=scale)
        elif weapon == "staff":
            draw.line([wx, wy + 4 * scale, wx, wy - 18 * scale], fill=wc + (255,), width=2 * scale)
            draw.ellipse([wx - 2 * scale, wy - 20 * scale, wx + 2 * scale, wy - 16 * scale],
                          fill=(200, 50, 50, 200))

    return img.resize((size, size), Image.LANCZOS)


# ==================== UI ELEMENTS ====================

def gen_glass_panel(w: int, h: int, base_color: Tuple = (20, 25, 40), alpha: int = 180,
                     border_color: Tuple = (100, 120, 180), radius: int = 8) -> Image.Image:
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_rounded_rect(draw, [0, 0, w - 1, h - 1], radius, fill=base_color[:3] + (alpha,))
    _draw_rounded_rect(draw, [0, 0, w - 1, h - 1], radius, fill=None, outline=border_color[:3] + (120,), width=2)
    highlight = _highlight(base_color, 30)[:3] + (40,)
    _draw_rounded_rect(draw, [2, 2, w - 3, h // 3], radius - 1, fill=highlight)
    return img


def gen_hp_bar(w: int, h: int, ratio: float, bar_color: Tuple = (50, 200, 50),
               bg_color: Tuple = (40, 40, 40)) -> Image.Image:
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_rounded_rect(draw, [0, 0, w - 1, h - 1], h // 2, fill=bg_color + (200,))
    fill_w = max(0, int((w - 4) * ratio))
    if fill_w > 0:
        _draw_rounded_rect(draw, [2, 2, 2 + fill_w, h - 3], (h - 4) // 2,
                            fill=bar_color + (255,))
        _draw_rounded_rect(draw, [2, 2, 2 + fill_w, h // 2], (h - 4) // 2,
                            fill=_highlight(bar_color, 40)[:3] + (80,))
    _draw_rounded_rect(draw, [0, 0, w - 1, h - 1], h // 2, outline=(80, 80, 80, 150), width=1)
    return img
