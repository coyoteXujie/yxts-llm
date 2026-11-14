"""
生成游戏音频资产（占位用程序化生成）
- SFX: 简单的 WAV 音效（点击、命中、拾取等）
- BGM: 简单的环境循环音效
- Ambient: 天气环境音

依赖: 仅 Python 标准库
"""

import wave
import struct
import math
import random
import os
import json

# ─── 配置 ───────────────────────────────────────────────

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                          "godot_project", "assets", "audio")

SAMPLE_RATE = 44100
MAX_AMP = 12000  # 避免削波

MANIFEST_PATH = os.path.join(OUTPUT_DIR, "audio_manifest.json")


# ─── 工具函数 ───────────────────────────────────────────

def _ensure_dir(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)


def _write_wav(path: str, samples: list[float], amp: float = MAX_AMP) -> None:
    _ensure_dir(path)
    with wave.open(path, "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        for s in samples:
            s = max(-1.0, min(1.0, s))
            wav.writeframes(struct.pack("<h", int(s * amp)))


def _write_ogg_placeholder(path: str, duration: float, note_hz: float = 220,
                           style: str = "simple") -> None:
    """生成 WAV 作为占位 (Godot 支持 WAV, 此处使用 wav 扩展)"""
    # 把 .ogg 替换为 .wav 以便 Godot 识别
    wav_path = path.replace(".ogg", ".wav")
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = min(1.0, t * 2.0, (duration - t) * 2.0)
        if style == "simple":
            s = math.sin(t * note_hz * 2 * math.pi) * 0.3
            s += math.sin(t * note_hz * 1.5 * 2 * math.pi) * 0.15
        elif style == "drone":
            s = math.sin(t * note_hz * 2 * math.pi) * 0.2
            s += math.sin(t * note_hz * 2.01 * 2 * math.pi) * 0.2
            s += random.gauss(0, 0.02)
        elif style == "calm":
            s = math.sin(t * note_hz * 2 * math.pi) * 0.15
            s += math.sin(t * (note_hz + 5) * 2 * math.pi) * 0.1
            s += math.sin(t * note_hz * 0.5 * 2 * math.pi) * 0.08
        elif style == "tense":
            s = math.sin(t * note_hz * 2 * math.pi) * 0.25
            s += math.sin(t * note_hz * 1.01 * 2 * math.pi) * 0.25
            s += math.sin(t * (note_hz * 0.5 + random.uniform(-1, 1)) * 2 * math.pi) * 0.1
        else:
            s = 0
        samples.append(s * fade)
    _write_wav(wav_path, samples)


# ─── SFX 生成 ──────────────────────────────────────────

def gen_sfx_ui_hover() -> list[float]:
    """轻柔的悬停提示音"""
    n = int(SAMPLE_RATE * 0.08)
    return [math.sin(i * 600 * 2 * math.pi / SAMPLE_RATE) * 0.08 * (1 - i / n)
            for i in range(n)]


def gen_sfx_ui_click() -> list[float]:
    """清脆点击"""
    n = int(SAMPLE_RATE * 0.06)
    return [math.sin(i * 800 * 2 * math.pi / SAMPLE_RATE) * 0.12 * (1 - i / n)
            for i in range(n)]


def gen_sfx_ui_confirm() -> list[float]:
    """确认音，两个上升音符"""
    n = int(SAMPLE_RATE * 0.2)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = min(1.0, t * 10) * (1 - t / 0.2)
        hz = 500 + 400 * (i / n)
        samples.append(math.sin(t * hz * 2 * math.pi) * 0.15 * fade)
    return samples


def gen_sfx_ui_cancel() -> list[float]:
    """取消音，下降音"""
    n = int(SAMPLE_RATE * 0.15)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = (1 - t / 0.15)
        hz = 600 - 300 * (i / n)
        samples.append(math.sin(t * hz * 2 * math.pi) * 0.12 * fade)
    return samples


def gen_sfx_typewriter() -> list[float]:
    """打字机音效"""
    n = int(SAMPLE_RATE * 0.04)
    return [random.uniform(-0.06, 0.06) * (1 - i / n) for i in range(n)]


def gen_sfx_skill_unlock() -> list[float]:
    """技能解锁，上升琶音"""
    n = int(SAMPLE_RATE * 0.5)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = min(1.0, t * 8) * (1 - t / 0.5)
        hz = 400 + 800 * (i / n)
        s = math.sin(t * hz * 2 * math.pi) * 0.2 * fade
        s += math.sin(t * hz * 1.5 * 2 * math.pi) * 0.1 * fade
        samples.append(s)
    return samples


def gen_sfx_hammer() -> list[float]:
    """打铁声"""
    n = int(SAMPLE_RATE * 0.3)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = (1 - t / 0.3) ** 2
        s = math.sin(t * 200 * 2 * math.pi) * 0.25 * fade
        s += math.sin(t * 400 * 2 * math.pi) * 0.12 * fade
        samples.append(s)
    return samples


def gen_sfx_item_pickup() -> list[float]:
    """拾取物品"""
    n = int(SAMPLE_RATE * 0.15)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = min(1.0, t * 10) * (1 - t / 0.15)
        hz = 300 + 600 * (i / n)
        samples.append(math.sin(t * hz * 2 * math.pi) * 0.12 * fade)
    return samples


def gen_sfx_item_drop() -> list[float]:
    """丢弃物品"""
    n = int(SAMPLE_RATE * 0.12)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = (1 - t / 0.12)
        hz = 600 - 300 * (i / n)
        samples.append(math.sin(t * hz * 2 * math.pi) * 0.10 * fade)
    return samples


def gen_sfx_combat_hit() -> list[float]:
    """命中音，低频冲击"""
    n = int(SAMPLE_RATE * 0.2)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = (1 - t / 0.2) ** 3
        s = math.sin(t * 120 * 2 * math.pi) * 0.35 * fade
        s += math.sin(t * 180 * 2 * math.pi) * 0.2 * fade
        s += random.gauss(0, 0.02) * fade
        samples.append(s)
    return samples


def gen_sfx_combat_miss() -> list[float]:
    """闪避，风声"""
    n = int(SAMPLE_RATE * 0.15)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = (1 - t / 0.15)
        s = random.gauss(0, 0.04) * fade
        s += math.sin(t * 800 + 1200 * (i / n) * 2 * math.pi) * 0.06 * fade
        samples.append(s)
    return samples


def gen_sfx_error() -> list[float]:
    """错误提示，低沉嗡嗡"""
    n = int(SAMPLE_RATE * 0.3)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        fade = min(1.0, t * 20) * (1 - t / 0.3)
        s = math.sin(t * 100 * 2 * math.pi) * 0.2 * fade
        s += math.sin(t * 150 * 2 * math.pi) * 0.1 * fade
        samples.append(s)
    return samples


# ─── SFX 清单 ──────────────────────────────────────────

SFX_GENERATORS: dict[str, tuple] = {
    "ui_hover.wav": (gen_sfx_ui_hover, "UI 悬停"),
    "ui_click.wav": (gen_sfx_ui_click, "UI 点击"),
    "ui_confirm.wav": (gen_sfx_ui_confirm, "UI 确认"),
    "ui_cancel.wav": (gen_sfx_ui_cancel, "UI 取消"),
    "typewriter.wav": (gen_sfx_typewriter, "打字机"),
    "skill_unlock.wav": (gen_sfx_skill_unlock, "技能解锁"),
    "hammer.wav": (gen_sfx_hammer, "打铁"),
    "item_pickup.wav": (gen_sfx_item_pickup, "拾取物品"),
    "item_drop.wav": (gen_sfx_item_drop, "丢弃物品"),
    "combat_hit.wav": (gen_sfx_combat_hit, "命中"),
    "combat_miss.wav": (gen_sfx_combat_miss, "闪避"),
    "error.wav": (gen_sfx_error, "错误"),
}

# ─── BGM / Ambient 生成 ────────────────────────────────

BGM_SPECS: dict[str, tuple] = {
    "main_menu.wav": (18.0, 180, "calm"),      # 主菜单
    "explore.wav": (24.0, 120, "simple"),       # 探索
    "combat.wav": (16.0, 80, "tense"),          # 战斗
    "inn.wav": (20.0, 160, "drone"),            # 客栈
}

AMBIENT_SPECS: dict[str, tuple] = {
    "sunny.wav": (20.0, 400, "calm"),           # 晴朗
    "cloudy.wav": (20.0, 200, "drone"),         # 多云
    "rain.wav": (20.0, 100, "tense"),           # 雨
    "storm.wav": (16.0, 60, "tense"),           # 雷暴
    "snow.wav": (20.0, 300, "calm"),            # 雪
    "fog.wav": (20.0, 150, "drone"),            # 雾
}


# ─── 主流程 ────────────────────────────────────────────

def main() -> None:
    sfx_dir = os.path.join(OUTPUT_DIR, "sfx")
    bgm_dir = os.path.join(OUTPUT_DIR, "bgm")
    ambient_dir = os.path.join(OUTPUT_DIR, "ambient")

    generated: dict[str, list[str]] = {
        "sfx": [],
        "bgm": [],
        "ambient": [],
    }

    # --- SFX ---
    print("🎵 生成 SFX ...")
    for filename, (gen_func, desc) in SFX_GENERATORS.items():
        path = os.path.join(sfx_dir, filename)
        samples = gen_func()
        _write_wav(path, samples)
        generated["sfx"].append(filename)
        print(f"   ✓ {filename} ({desc})")

    # --- BGM ---
    print("\n🎵 生成 BGM ...")
    for filename, (duration, note_hz, style) in BGM_SPECS.items():
        path = os.path.join(bgm_dir, filename)
        _write_ogg_placeholder(path, duration, note_hz, style)
        generated["bgm"].append(filename)
        print(f"   ✓ {filename} ({duration}s, {note_hz}Hz, {style})")

    # --- Ambient ---
    print("\n🎵 生成 Ambient ...")
    for filename, (duration, note_hz, style) in AMBIENT_SPECS.items():
        path = os.path.join(ambient_dir, filename)
        _write_ogg_placeholder(path, duration, note_hz, style)
        generated["ambient"].append(filename)
        print(f"   ✓ {filename} ({duration}s, {note_hz}Hz, {style})")

    # --- 更新音频管理器路径 ---
    _patch_audio_manager_paths()

    # --- 写入清单 ---
    manifest = {
        "generated_at": "tools/generate_audio_assets.py",
        "count": {
            "sfx": len(generated["sfx"]),
            "bgm": len(generated["bgm"]),
            "ambient": len(generated["ambient"]),
        },
        "files": generated,
    }
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"\n✅ 音频清单已写入: {MANIFEST_PATH}")
    print(f"   共生成 {sum(len(v) for v in generated.values())} 个音频文件")


def _patch_audio_manager_paths() -> None:
    """更新 audio_manager.gd 中的路径从 .ogg 改为 .wav（因为我们生成的是 WAV）"""
    manager_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "godot_project", "scripts", "autoload", "audio_manager.gd"
    )
    # 路径已使用 .ogg 和 .wav 混合，我们生成的 BGM/Ambient 是 .wav 扩展
    # 不需要改代码，Godot 支持两种格式
    print("   ℹ audio_manager.gd 路径无需修改（Godot 支持 WAV/OGG）")


if __name__ == "__main__":
    main()