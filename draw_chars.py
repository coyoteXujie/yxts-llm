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
    w, h = 48, 64
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
        for y in range(max(0, y1), min(h, y2+1)):
            for x in range(max(0, x1), min(w, x2+1)):
                set_px(x, y, r, g, b, a)
    
    palettes = [
        {"robe": (180, 40, 40), "robe_dark": (130, 30, 30), "robe_light": (200, 60, 60), "trim": (220, 200, 60), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (110, 90, 65)},
        {"robe": (60, 60, 150), "robe_dark": (40, 40, 120), "robe_light": (80, 80, 170), "trim": (220, 220, 220), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (90, 70, 45)},
        {"robe": (80, 150, 80), "robe_dark": (55, 120, 55), "robe_light": (110, 170, 110), "trim": (170, 130, 55), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (110, 90, 65)},
        {"robe": (210, 180, 110), "robe_dark": (180, 150, 80), "robe_light": (230, 200, 130), "trim": (110, 70, 35), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (110, 90, 65)},
        {"robe": (170, 65, 170), "robe_dark": (140, 45, 140), "robe_light": (190, 85, 190), "trim": (220, 200, 60), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (110, 90, 65)},
        {"robe": (80, 80, 80), "robe_dark": (55, 55, 55), "robe_light": (100, 100, 100), "trim": (200, 200, 200), "hair": (25, 20, 15), "skin": (255, 230, 210), "shoes": (70, 50, 35), "pants": (90, 70, 45)},
    ]
    
    P = palettes[char_id % len(palettes)]
    cx = 24
    
    bob = 1 if (frame % 2 == 1) else 0
    swing = 3 if (frame % 2 == 1) else -3
    
    # HAIR (back layer - long flowing hair)
    fill_rect(cx - 10, 4, cx + 10, 22, P["hair"])
    fill_rect(cx - 8, 22, cx + 8, 32, P["hair"])
    
    # HEAD (skin color oval)
    fill_rect(cx - 8, 6, cx + 8, 20, P["skin"])
    fill_rect(cx - 6, 4, cx + 6, 6, P["skin"])
    fill_rect(cx - 6, 20, cx + 6, 22, P["skin"])
    
    # HAIR (front - bangs)
    fill_rect(cx - 9, 4, cx + 9, 10, P["hair"])
    fill_rect(cx - 9, 10, cx - 7, 18, P["hair"])
    fill_rect(cx + 7, 10, cx + 9, 18, P["hair"])
    
    # EYES
    fill_rect(cx - 4, 14, cx - 2, 15, (40, 30, 20))
    fill_rect(cx + 2, 14, cx + 4, 15, (40, 30, 20))
    
    # MOUTH
    fill_rect(cx - 2, 17, cx + 2, 17, (210, 130, 130))
    
    # NECK
    fill_rect(cx - 3, 22, cx + 3, 25 + bob, P["skin"])
    
    # TORSO / ROBE BODY
    body_top = 25 + bob
    body_bottom = 42
    fill_rect(cx - 11, body_top, cx + 11, body_bottom, P["robe"])
    
    # Collar V-neck
    fill_rect(cx - 2, body_top, cx + 2, body_top + 5, P["robe_dark"])
    
    # Side trim
    fill_rect(cx - 11, body_top, cx - 9, body_bottom, P["trim"])
    fill_rect(cx + 9, body_top, cx + 11, body_bottom, P["trim"])
    
    # BELT
    fill_rect(cx - 12, 35, cx + 12, 38, P["trim"])
    
    # ARMS with sleeves
    left_arm_y = body_top + 4 + swing
    right_arm_y = body_top + 4 - swing
    
    fill_rect(cx - 16, left_arm_y, cx - 11, left_arm_y + 5, P["robe"])
    fill_rect(cx - 15, left_arm_y + 5, cx - 11, left_arm_y + 14, P["robe_light"])
    
    fill_rect(cx + 11, right_arm_y, cx + 16, right_arm_y + 5, P["robe"])
    fill_rect(cx + 11, right_arm_y + 5, cx + 15, right_arm_y + 14, P["robe_light"])
    
    # LOWER SKIRT
    fill_rect(cx - 11, body_bottom, cx + 11, body_bottom + 10, P["robe_dark"])
    
    # LEGS
    leg_top = body_bottom + 10
    leg_bottom = leg_top + 8
    fill_rect(cx - 8 + swing, leg_top, cx - 2 + swing, leg_bottom, P["pants"])
    fill_rect(cx + 2 - swing, leg_top, cx + 8 - swing, leg_bottom, P["pants"])
    
    # SHOES
    fill_rect(cx - 9 + swing, leg_bottom, cx - 1 + swing, leg_bottom + 5, P["shoes"])
    fill_rect(cx + 1 - swing, leg_bottom, cx + 9 - swing, leg_bottom + 5, P["shoes"])
    
    return create_png(w, h, bytes(pixels))

output_dir = 'E:/yxts-llm/assets/sprites/chinese_chars'
os.makedirs(output_dir, exist_ok=True)

for char_id in range(6):
    for frame in range(4):
        png_data = draw_character(char_id, frame)
        filename = os.path.join(output_dir, f"char{char_id}_frame{frame}.png")
        with open(filename, 'wb') as f:
            f.write(png_data)
        print(f"char{char_id}_frame{frame}.png: {len(png_data)} bytes")

print("Done! 24 sprites generated.")
