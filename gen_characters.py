import struct
import zlib
import os

def create_png(width, height, pixels_rgba):
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
        r, g, b = color
        a = 255
        for y in range(max(0,y1), min(h,y2+1)):
            for x in range(max(0,x1), min(w,x2+1)):
                set_px(x, y, r, g, b, a)
    
    def draw_ellipse(cx, cy, rx, ry, color):
        r, g, b = color
        a = 255
        for y in range(max(0,cy-ry), min(h,cy+ry+1)):
            for x in range(max(0,cx-rx), min(w,cx+rx+1)):
                if ((x-cx)**2 / (rx**2 + 1)) + ((y-cy)**2 / (ry**2 + 1)) <= 1.0:
                    set_px(x, y, r, g, b, a)
    
    palettes = [
        {"robe": (160, 40, 40), "robe_light": (180, 60, 60), "robe_dark": (120, 30, 30), "trim": (200, 180, 60), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (100, 80, 60)},
        {"robe": (60, 60, 140), "robe_light": (80, 80, 170), "robe_dark": (40, 40, 110), "trim": (200, 200, 200), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (80, 60, 40)},
        {"robe": (80, 140, 80), "robe_light": (100, 160, 100), "robe_dark": (50, 110, 50), "trim": (160, 120, 50), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (100, 80, 60)},
        {"robe": (200, 170, 100), "robe_light": (220, 190, 120), "robe_dark": (170, 140, 70), "trim": (100, 60, 30), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (100, 80, 60)},
        {"robe": (160, 60, 160), "robe_light": (180, 80, 180), "robe_dark": (130, 40, 130), "trim": (200, 180, 60), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (100, 80, 60)},
        {"robe": (70, 70, 70), "robe_light": (90, 90, 90), "robe_dark": (50, 50, 50), "trim": (180, 180, 180), "hair": (20, 15, 10), "skin": (255, 225, 200), "shoes": (60, 40, 30), "pants": (80, 60, 40)},
    ]
    
    P = palettes[char_id % len(palettes)]
    cx = 32
    
    bob = 1 if (frame % 2 == 1) else 0
    arm_swing = 4 if (frame % 2 == 1) else -4
    leg_swing = 3 if (frame % 2 == 1) else -3
    
    # HEAD - proper oval shape
    head_cy = 16 + bob
    draw_ellipse(cx, head_cy, 12, 14, P["skin"])
    
    # HAIR - top of head with flowing sides
    draw_ellipse(cx, head_cy - 2, 13, 10, P["hair"])
    fill_rect(cx - 14, head_cy - 4, cx + 14, head_cy + 2, P["hair"])
    
    # Long flowing hair (Chinese style)
    hair_flow = 2 if (frame % 2 == 1) else -1
    fill_rect(cx - 12, head_cy + 10, cx + 12, head_cy + 24, P["hair"])
    fill_rect(cx - 10, head_cy + 24, cx + 10, head_cy + 34 + hair_flow, P["hair"])
    fill_rect(cx - 8, head_cy + 34 + hair_flow, cx + 8, head_cy + 40 + hair_flow, P["hair"])
    
    # FACE details
    # Eyes (with pupils)
    fill_rect(cx - 6, head_cy - 1, cx - 3, head_cy + 2, (255, 255, 255))
    fill_rect(cx + 3, head_cy - 1, cx + 6, head_cy + 2, (255, 255, 255))
    set_px(cx - 5, head_cy, 30, 20, 15, 255)
    set_px(cx + 5, head_cy, 30, 20, 15, 255)
    
    # Eyebrows
    fill_rect(cx - 7, head_cy - 4, cx - 3, head_cy - 3, P["hair"])
    fill_rect(cx + 3, head_cy - 4, cx + 7, head_cy - 3, P["hair"])
    
    # Nose
    set_px(cx, head_cy + 2, 230, 200, 180, 255)
    set_px(cx, head_cy + 3, 230, 200, 180, 255)
    
    # Mouth
    fill_rect(cx - 3, head_cy + 6, cx + 3, head_cy + 7, (200, 120, 120))
    
    # NECK
    fill_rect(cx - 4, head_cy + 14, cx + 4, head_cy + 18 + bob, P["skin"])
    
    # TORSO / BODY
    body_top = head_cy + 18 + bob
    body_bottom = body_top + 30
    
    # Main robe body
    fill_rect(cx - 16, body_top, cx + 16, body_bottom, P["robe"])
    
    # V-neck collar
    fill_rect(cx - 6, body_top, cx - 2, body_top + 10, P["skin"])
    fill_rect(cx + 2, body_top, cx + 6, body_top + 10, P["skin"])
    fill_rect(cx - 4, body_top, cx + 4, body_top + 6, P["robe_dark"])
    
    # Side trim
    fill_rect(cx - 16, body_top, cx - 14, body_bottom, P["trim"])
    fill_rect(cx + 14, body_top, cx + 16, body_bottom, P["trim"])
    
    # Belt / sash
    belt_y = body_top + 16
    fill_rect(cx - 17, belt_y, cx + 17, belt_y + 5, P["trim"])
    fill_rect(cx - 2, belt_y, cx + 2, belt_y + 5, P["robe_dark"])
    
    # ARMS with flowing sleeves
    left_arm_y = body_top + 6 + arm_swing
    right_arm_y = body_top + 6 - arm_swing
    
    # Left arm
    fill_rect(cx - 24, left_arm_y, cx - 16, left_arm_y + 6, P["robe"])
    fill_rect(cx - 22, left_arm_y + 6, cx - 16, left_arm_y + 20, P["robe_light"])
    # Right arm
    fill_rect(cx + 16, right_arm_y, cx + 24, right_arm_y + 6, P["robe"])
    fill_rect(cx + 16, right_arm_y + 6, cx + 22, right_arm_y + 20, P["robe_light"])
    
    # LOWER BODY - flowing skirt/robe
    skirt_top = body_bottom
    skirt_bottom = skirt_top + 18
    fill_rect(cx - 16, skirt_top, cx + 16, skirt_bottom, P["robe_dark"])
    fill_rect(cx - 16, skirt_top, cx - 14, skirt_bottom, P["trim"])
    fill_rect(cx + 14, skirt_top, cx + 16, skirt_bottom, P["trim"])
    
    # LEGS
    leg_top = skirt_bottom
    leg_bottom = leg_top + 14
    fill_rect(cx - 10 + leg_swing, leg_top, cx - 2 + leg_swing, leg_bottom, P["pants"])
    fill_rect(cx + 2 - leg_swing, leg_top, cx + 10 - leg_swing, leg_bottom, P["pants"])
    
    # SHOES
    shoe_top = leg_bottom
    shoe_bottom = shoe_top + 8
    fill_rect(cx - 12 + leg_swing, shoe_top, cx - 2 + leg_swing, shoe_bottom, P["shoes"])
    fill_rect(cx + 2 - leg_swing, shoe_top, cx + 12 - leg_swing, shoe_bottom, P["shoes"])
    
    # Decorative embroidery on robe
    fill_rect(cx - 4, body_top + 8, cx - 2, body_top + 14, P["trim"])
    fill_rect(cx + 2, body_top + 8, cx + 4, body_top + 14, P["trim"])
    
    return create_png(w, h, bytes(pixels))

output_dir = 'E:/yxts-llm/assets/sprites/chinese_chars'
os.makedirs(output_dir, exist_ok=True)

for char_id in range(6):
    for frame in range(4):
        png_data = draw_character(char_id, frame)
        filename = os.path.join(output_dir, f"char{char_id}_frame{frame}.png")
        with open(filename, 'wb') as f:
            f.write(png_data)
        size_kb = len(png_data) / 1024
        print(f"Generated {filename}: {size_kb:.1f}KB")

print(f"\nDone! Generated 24 sprites (6 characters x 4 frames)")
