import struct
import zlib
import os

def create_png(width, height, pixels_rgba):
    """Create PNG from raw RGBA data"""
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)
    
    signature = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_chunk = make_chunk(b'IHDR', ihdr)
    
    raw = b''
    row_bytes = width * 4
    for y in range(height):
        raw += b'\x00'
        row_start = y * row_bytes
        raw += pixels_rgba[row_start:row_start + row_bytes]
    
    idat_chunk = make_chunk(b'IDAT', zlib.compress(raw))
    iend_chunk = make_chunk(b'IEND', b'')
    
    return signature + ihdr_chunk + idat_chunk + iend_chunk

def draw_character(char_id, frame):
    """Draw a detailed Chinese wuxia style character (64x96, 4-direction idle animation)"""
    w, h = 64, 96
    pixels = bytearray([0] * (w * h * 4))
    
    def set_px(x, y, r, g, b, a=255):
        if 0 <= x < w and 0 <= y < h:
            idx = (y * w + x) * 4
            pixels[idx] = r
            pixels[idx+1] = g
            pixels[idx+2] = b
            pixels[idx+3] = a
    
    def fill_rect(x1, y1, x2, y2, color):
        r, g, b, a = color
        for y in range(max(0,y1), min(h,y2+1)):
            for x in range(max(0,x1), min(w,x2+1)):
                set_px(x, y, r, g, b, a)
    
    def draw_circle(cx, cy, radius, color):
        r, g, b, a = color
        for y in range(max(0,cy-radius), min(h,cy+radius+1)):
            for x in range(max(0,cx-radius), min(w,cx+radius+1)):
                if (x-cx)**2 + (y-cy)**2 <= radius*radius:
                    set_px(x, y, r, g, b, a)
    
    # Color palette based on character type
    palettes = [
        {"robe": (160, 40, 40, 255), "robe_light": (180, 60, 60, 255), "robe_dark": (120, 30, 30, 255), "trim": (200, 180, 60, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (100, 80, 60, 255)},  # Red robes
        {"robe": (60, 60, 140, 255), "robe_light": (80, 80, 170, 255), "robe_dark": (40, 40, 110, 255), "trim": (200, 200, 200, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (80, 60, 40, 255)},  # Blue robes
        {"robe": (80, 140, 80, 255), "robe_light": (100, 160, 100, 255), "robe_dark": (50, 110, 50, 255), "trim": (160, 120, 50, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (100, 80, 60, 255)},  # Green robes
        {"robe": (200, 170, 100, 255), "robe_light": (220, 190, 120, 255), "robe_dark": (170, 140, 70, 255), "trim": (100, 60, 30, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (100, 80, 60, 255)},  # Yellow robes
        {"robe": (160, 60, 160, 255), "robe_light": (180, 80, 180, 255), "robe_dark": (130, 40, 130, 255), "trim": (200, 180, 60, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (100, 80, 60, 255)},  # Purple robes
        {"robe": (70, 70, 70, 255), "robe_light": (90, 90, 90, 255), "robe_dark": (50, 50, 50, 255), "trim": (180, 180, 180, 255), "hair": (20, 15, 10, 255), "skin": (255, 225, 200, 255), "shoes": (60, 40, 30, 255), "pants": (80, 60, 40, 255)},  # Black robes
    ]
    
    P = palettes[char_id % len(palettes)]
    
    cx = 32
    bob = 1 if (frame % 2 == 1) else 0
    
    # Head (oval shape for proper human proportions)
    head_y = 12 + bob
    fill_rect(cx - 10, head_y, cx + 10, head_y + 16, P["skin"])
    draw_circle(cx, head_y + 6, 10, P["skin"])
    
    # Hair (top and sides of head)
    fill_rect(cx - 11, head_y - 2, cx + 11, head_y + 4, P["hair"])
    fill_rect(cx - 11, head_y + 4, cx - 9, head_y + 12, P["hair"])
    fill_rect(cx + 9, head_y + 4, cx + 11, head_y + 12, P["hair"])
    
    # Long flowing hair (Chinese style - long hair down the back)
    hair_offset = 2 if (frame == 1) else -2 if (frame == 3) else 0
    fill_rect(cx - 8, head_y + 14, cx + 8, head_y + 28 + hair_offset, P["hair"])
    fill_rect(cx - 6, head_y + 28 + hair_offset, cx + 6, head_y + 36 + hair_offset, P["hair"])
    
    # Eyes
    set_px(cx - 4, head_y + 8, 40, 30, 20, 255)
    set_px(cx + 4, head_y + 8, 40, 30, 20, 255)
    set_px(cx - 4, head_y + 9, 40, 30, 20, 255)
    set_px(cx + 4, head_y + 9, 40, 30, 20, 255)
    
    # Mouth (small line)
    fill_rect(cx - 2, head_y + 12, cx + 2, head_y + 12, (200, 140, 140, 255))
    
    # Neck
    fill_rect(cx - 4, head_y + 16, cx + 4, head_y + 20 + bob, P["skin"])
    
    # Body / Torso (wider for proper proportions)
    body_y = head_y + 20 + bob
    body_h = 28
    fill_rect(cx - 14, body_y, cx + 14, body_y + body_h, P["robe"])
    
    # Robe V-neck detail
    fill_rect(cx - 2, body_y, cx + 2, body_y + 12, P["robe_dark"])
    
    # Robe trim / collar
    fill_rect(cx - 14, body_y, cx - 12, body_y + body_h, P["trim"])
    fill_rect(cx + 12, body_y, cx + 14, body_y + body_h, P["trim"])
    
    # Belt / sash
    belt_y = body_y + 14
    fill_rect(cx - 15, belt_y, cx + 15, belt_y + 4, P["trim"])
    fill_rect(cx - 3, belt_y, cx + 3, belt_y + 4, P["robe_dark"])
    
    # Arms with flowing sleeves
    arm_wave = 3 if (frame % 2 == 1) else -3
    # Left arm
    fill_rect(cx - 22, body_y + 4 + arm_wave, cx - 14, body_y + 8 + arm_wave, P["robe"])
    fill_rect(cx - 20, body_y + 8 + arm_wave, cx - 14, body_y + 18 + arm_wave, P["robe_light"])
    # Right arm
    fill_rect(cx + 14, body_y + 4 - arm_wave, cx + 22, body_y + 8 - arm_wave, P["robe"])
    fill_rect(cx + 14, body_y + 8 - arm_wave, cx + 20, body_y + 18 - arm_wave, P["robe_light"])
    
    # Lower body / Skirt / Pants
    skirt_y = body_y + body_h
    fill_rect(cx - 14, skirt_y, cx + 14, skirt_y + 16, P["robe_dark"])
    
    # Legs
    leg_wave = 2 if (frame % 2 == 1) else -2
    fill_rect(cx - 10, skirt_y + 14, cx - 2, skirt_y + 28, P["pants"])
    fill_rect(cx + 2, skirt_y + 14, cx + 10, skirt_y + 28, P["pants"])
    
    # Shoes
    fill_rect(cx - 12, skirt_y + 26, cx - 2, skirt_y + 32, P["shoes"])
    fill_rect(cx + 2, skirt_y + 26, cx + 12, skirt_y + 32, P["shoes"])
    
    # Decorative elements
    fill_rect(cx - 6, body_y + 4, cx - 4, body_y + 10, P["trim"])
    
    return create_png(w, h, bytes(pixels))

output_dir = 'E:/yxts-llm/assets/sprites/chinese_chars'
os.makedirs(output_dir, exist_ok=True)

for char_id in range(6):
    for frame in range(4):
        png_data = draw_character(char_id, frame)
        filename = os.path.join(output_dir, f"char{char_id}_frame{frame}.png")
        with open(filename, 'wb') as f:
            f.write(png_data)
        print(f"Generated {filename}: {len(png_data)} bytes")

print("Done! Generated Chinese-style character sprites with 6 characters, 4 frames each")
