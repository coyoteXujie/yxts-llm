import struct
import zlib
import os

def create_png(width, height, pixels_rgba):
    """Create a PNG file from raw RGBA pixel data"""
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
    
    signature = b'\x89PNG\r\n\x1a\n'
    
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            idx = (y * width + x) * 4
            raw_data += struct.pack('BBBB', pixels_rgba[idx], pixels_rgba[idx+1], pixels_rgba[idx+2], pixels_rgba[idx+3])
    
    idat = make_chunk(b'IDAT', zlib.compress(raw_data))
    iend = make_chunk(b'IEND', b'')
    
    return signature + ihdr + idat + iend

def draw_chinese_character(char_id, frame, direction):
    """Draw a Chinese wuxia style character pixel art (32x48)"""
    width, height = 32, 48
    pixels = [0] * (width * height * 4)
    
    def set_pixel(x, y, r, g, b, a=255):
        if 0 <= x < width and 0 <= y < height:
            idx = (y * width + x) * 4
            pixels[idx] = r
            pixels[idx+1] = g
            pixels[idx+2] = b
            pixels[idx+3] = a
    
    def draw_rect(x1, y1, x2, y2, r, g, b, a=255):
        for y in range(y1, y2+1):
            for x in range(x1, x2+1):
                set_pixel(x, y, r, g, b, a)
    
    def draw_line(x1, y1, x2, y2, r, g, b, a=255):
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy
        while True:
            set_pixel(x1, y1, r, g, b, a)
            if x1 == x2 and y1 == y2:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x1 += sx
            if e2 < dx:
                err += dx
                y1 += sy

    skin_color = (255, 220, 195)
    hair_color = (30, 20, 15)
    
    if char_id == 0:
        robe_color = (180, 40, 40)
        robe_dark = (140, 30, 30)
        belt_color = (200, 180, 50)
    elif char_id == 1:
        robe_color = (60, 60, 140)
        robe_dark = (40, 40, 100)
        belt_color = (180, 180, 180)
    elif char_id == 2:
        robe_color = (80, 140, 80)
        robe_dark = (50, 100, 50)
        belt_color = (140, 100, 40)
    elif char_id == 3:
        robe_color = (200, 170, 100)
        robe_dark = (160, 130, 70)
        belt_color = (100, 60, 30)
    elif char_id == 4:
        robe_color = (160, 60, 160)
        robe_dark = (120, 40, 120)
        belt_color = (200, 180, 50)
    else:
        robe_color = (100, 100, 100)
        robe_dark = (70, 70, 70)
        belt_color = (150, 150, 150)

    head_x = 13
    head_y = 6
    head_w = 10
    head_h = 12

    draw_rect(head_x, head_y, head_x + head_w - 1, head_y + head_h - 1, *skin_color)
    draw_rect(head_x, head_y, head_x + head_w - 1, head_y + 3, *hair_color)
    draw_rect(head_x, head_y, head_x + 1, head_y + 6, *hair_color)
    draw_rect(head_x + head_w - 2, head_y, head_x + head_w - 1, head_y + 6, *hair_color)
    set_pixel(15, 13, 40, 30, 20)
    set_pixel(19, 13, 40, 30, 20)
    set_pixel(17, 15, 200, 140, 140)

    body_y = 18
    body_h = 14
    draw_rect(head_x - 2, body_y, head_x + head_w + 1, body_y + body_h - 1, *robe_color)
    draw_rect(15, body_y, 18, body_y + body_h - 1, *robe_dark)
    draw_rect(head_x - 1, body_y + 6, head_x + head_w, body_y + 8, *belt_color)

    sleeve_offset = 1 if frame % 2 == 0 else -1
    draw_rect(head_x - 5, body_y + sleeve_offset, head_x - 3, body_y + 5 + sleeve_offset, *robe_color)
    draw_rect(head_x + head_w + 2, body_y - sleeve_offset, head_x + head_w + 4, body_y + 5 - sleeve_offset, *robe_color)

    leg_y = body_y + body_h
    leg_h = 10
    draw_rect(head_x - 1, leg_y, head_x + 5, leg_y + leg_h - 1, *robe_dark)
    draw_rect(head_x + 6, leg_y, head_x + 12, leg_y + leg_h - 1, *robe_dark)
    draw_rect(head_x - 1, leg_y + leg_h, head_x + 5, leg_y + leg_h + 1, 80, 60, 40)
    draw_rect(head_x + 6, leg_y + leg_h, head_x + 12, leg_y + leg_h + 1, 80, 60, 40)

    return create_png(width, height, pixels)

os.makedirs('E:/yxts-llm/assets/sprites/chinese_chars', exist_ok=True)

for char_id in range(6):
    for direction in range(4):
        for frame in range(4):
            png_data = draw_chinese_character(char_id, frame, direction)
            filename = f'E:/yxts-llm/assets/sprites/chinese_chars/char{char_id}_dir{direction}_frame{frame}.png'
            with open(filename, 'wb') as f:
                f.write(png_data)

print("Generated Chinese-style character sprites successfully!")
for char_id in range(6):
    test_file = f'E:/yxts-llm/assets/sprites/chinese_chars/char{char_id}_dir0_frame0.png'
    size = os.path.getsize(test_file)
    print(f"  char{char_id}: {size} bytes")
