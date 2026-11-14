#!/usr/bin/env python3
"""为朝廷技能生成 64x64 RGBA 图标 PNG。"""
import struct
import zlib
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "godot_project", "assets", "skills", "icons")

SKILLS = {
    "kf_qinna": {
        "name": "六合擒拿",
        "primary": (210, 180, 70),
        "secondary": (60, 40, 20),
        "pattern": "grab",
    },
    "kf_tiebu": {
        "name": "铁布衫",
        "primary": (140, 150, 160),
        "secondary": (50, 55, 60),
        "pattern": "shield",
    },
    "kf_shenxing": {
        "name": "神行百变",
        "primary": (120, 200, 100),
        "secondary": (30, 60, 30),
        "pattern": "wind",
    },
    "kf_anjian": {
        "name": "暗器手法",
        "primary": (180, 60, 60),
        "secondary": (50, 20, 20),
        "pattern": "dart",
    },
}


def _png_chunk(chunk_type: str, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + chunk_type.encode("ascii")
        + data
        + struct.pack(">I", zlib.crc32(chunk_type.encode("ascii") + data) & 0xFFFFFFFF)
    )


def _write_png(path: str, width: int, height: int, pixels: list) -> None:
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += struct.pack("BBBB", r, g, b, a)
    compressed = zlib.compress(raw, 9)
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = signature + _png_chunk("IHDR", ihdr) + _png_chunk("IDAT", compressed) + _png_chunk("IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def _lerp(c1, c2, t):
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )


def _gen_icon(skill_id: str, config: dict, size: int = 64) -> list:
    primary = config["primary"]
    secondary = config["secondary"]
    pattern = config["pattern"]
    pixels = []
    cx = size / 2.0
    cy = size / 2.0
    radius = size * 0.42
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist > radius + 2:
                pixels.append((0, 0, 0, 0))
                continue
            edge_t = max(0.0, min(1.0, (dist - radius + 2) / 4.0))
            base = _lerp(primary, secondary, edge_t)
            alpha = 255 if dist <= radius else int(255 * max(0.0, 1.0 - (dist - radius) / 2.0))
            r, g, b = base
            if pattern == "grab":
                t = abs(dy) / cy
                if abs(dx) < 3 and dy < -4:
                    r, g, b = _lerp((r, g, b), (255, 240, 200), 0.6)
                if abs(dx) < 2 and dy > 6:
                    r, g, b = _lerp((r, g, b), (255, 240, 200), 0.4)
                notch = abs(dx - cx * 0.3) < 2 and dy > 0 and dy < 12
                if notch:
                    r, g, b = secondary
            elif pattern == "shield":
                if abs(dx) < size * 0.22 and abs(dy) < size * 0.28:
                    inner = _lerp(primary, (220, 225, 235), 0.4)
                    r, g, b = inner
                if abs(dx) < 1 or abs(dy) < 1:
                    r, g, b = _lerp((r, g, b), secondary, 0.5)
            elif pattern == "wind":
                stripe = ((int(dy) % 6) < 2) and abs(dx) < size * 0.38
                if stripe:
                    r, g, b = _lerp((r, g, b), (240, 255, 230), 0.5)
                if abs(dx) < 2 and abs(dy) < 8:
                    r, g, b = _lerp((r, g, b), secondary, 0.6)
            elif pattern == "dart":
                if abs(dx + dy) < 3 and abs(dx - dy) < size * 0.35:
                    r, g, b = _lerp((r, g, b), (255, 230, 200), 0.6)
                if abs(dx - dy) < 3 and abs(dx + dy) < size * 0.35:
                    r, g, b = _lerp((r, g, b), (255, 230, 200), 0.6)
                if abs(dx) < 2 and abs(dy) < 6:
                    r, g, b = secondary
            pixels.append((r, g, b, alpha))
    return pixels


def main() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for skill_id, config in SKILLS.items():
        pixels = _gen_icon(skill_id, config)
        path = os.path.join(OUTPUT_DIR, f"{skill_id}.png")
        _write_png(path, 64, 64, pixels)
        print(f"generated: {path}")


if __name__ == "__main__":
    main()
