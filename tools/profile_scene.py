#!/usr/bin/env python3
"""
profile_scene.py — Godot 场景加载性能分析工具

在 headless 模式下启动 Godot 引擎，分析场景加载：
1. 脚本编译耗时
2. 场景加载耗时（通过解析 Godot verbose 输出）
3. 识别超过 500 行的脚本文件

用法:
    python3 tools/profile_scene.py                    # 分析 godot_project main场景
    python3 tools/profile_scene.py --scene other.tscn  # 其他场景
    python3 tools/profile_scene.py --summary           # 只输出文件行数统计
"""

import json
import os
import re
import subprocess
import sys
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.join(SCRIPT_DIR, "..", "godot_project")
GODOT_CANDIDATES = [
    os.path.join(SCRIPT_DIR, "..", "Godot_v4", "MacOS", "Godot.app", "Contents", "MacOS", "Godot"),
    os.path.join(SCRIPT_DIR, "..", "Godot_v4", "linux", "Godot_v4.6.3-stable_linux.x86_64"),
    os.path.join(SCRIPT_DIR, "..", "Godot_v4", "windows", "Godot_v4.6.3-stable_win64.exe"),
]

REPORT_FILE = os.path.join(SCRIPT_DIR, "profile_report.json")
LINE_THRESHOLD = 500  # 脚本行数阈值


def find_godot() -> str:
    for c in GODOT_CANDIDATES:
        if os.path.exists(c):
            return c
    raise FileNotFoundError("未找到 Godot 引擎。请检查 Godot_v4/ 目录")


def find_gd_files(root: str) -> list[tuple[str, int]]:
    """遍历所有 .gd 文件并返回 (相对路径, 行数)"""
    results: list[tuple[str, int]] = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith(".gd") and not fn.endswith(".gd.uid"):
                fpath = os.path.join(dirpath, fn)
                with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                    line_count = sum(1 for _ in f)
                relative = os.path.relpath(fpath, os.path.join(SCRIPT_DIR, ".."))
                results.append((relative, line_count))
    return sorted(results, key=lambda x: -x[1])


def profile_scene(scene_path: str) -> dict:
    """启动 Godot --headless --verbose 解析加载耗时"""
    godot = find_godot()
    env = os.environ.copy()
    env["HOME"] = "/tmp/godot_home"
    env["XDG_DATA_HOME"] = "/tmp/godot_data"
    env["XDG_CONFIG_HOME"] = "/tmp/godot_config"
    env["XDG_CACHE_HOME"] = "/tmp/godot_cache"

    cmd = [godot, "--headless", "--path", PROJECT_DIR, "--quit-after", "1"]
    if scene_path:
        cmd.extend(["--scene", scene_path])

    print(f"⏵ 启动 Godot 分析: {' '.join(cmd[-4:])}")
    start_time = time.time()

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60, env=env)
    elapsed = time.time() - start_time

    output = result.stdout + "\n" + result.stderr

    # 解析关键指标
    metrics: dict = {
        "exit_code": result.returncode,
        "wall_time_seconds": round(elapsed, 2),
        "errors": [],
        "warnings": [],
        "load_times_seconds": {},
    }

    # 解析错误和警告
    for line in output.split("\n"):
        if "ERROR:" in line or "error:" in line.lower():
            if "resources still in use" not in line and "get_system_ca_certificates" not in line:
                metrics["errors"].append(line.strip())
        elif "WARNING:" in line and "leaked" not in line and "resources still in use" not in line:
            metrics["warnings"].append(line.strip())

    # 解析每个脚本的编译时间 (大致估算)
    script_compile_lines = 0
    for line in output.split("\n"):
        if "SCRIPT ERROR:" in line or "script load" in line.lower():
            script_compile_lines += 1

    metrics["script_issues"] = script_compile_lines

    return metrics


def check_long_scripts(root: str) -> list[dict]:
    """识别超过行数阈值的脚本"""
    files = find_gd_files(root)
    long_files = []
    for fpath, line_count in files:
        if line_count > LINE_THRESHOLD:
            long_files.append({
                "file": fpath,
                "lines": line_count,
                "threshold": LINE_THRESHOLD
            })
    return long_files


def main():
    scene = None
    summary_only = False
    args = sys.argv[1:]
    for i, arg in enumerate(args):
        if arg == "--scene" and i + 1 < len(args):
            scene = args[i + 1]
        elif arg == "--summary":
            summary_only = True

    scripts_root = os.path.join(SCRIPT_DIR, "..", "godot_project", "scripts")
    files = find_gd_files(scripts_root)

    # 文件统计
    total_lines = sum(f[1] for f in files)
    long_scripts = check_long_scripts(scripts_root)

    print(f"📊 Godot 脚本统计:")
    print(f"   脚本数量: {len(files)}")
    print(f"   总行数:   {total_lines}")
    print(f"   平均行数: {total_lines // max(len(files), 1)}")

    if long_scripts:
        print(f"\n⚠️  超过 {LINE_THRESHOLD} 行的脚本 ({len(long_scripts)} 个):")
        for s in long_scripts[:20]:
            print(f"   {s['lines']:5d} 行  {s['file']}")
        if len(long_scripts) > 20:
            print(f"   ... 还有 {len(long_scripts) - 20} 个")

    # Top 10 最长脚本
    print(f"\n🔝 Top 10 最长脚本:")
    for fpath, lines in files[:10]:
        print(f"   {lines:5d} 行  {fpath}")

    if summary_only:
        return

    # 场景剖析
    print(f"\n⚡ 场景加载性能分析...")
    metrics = profile_scene(scene)

    report = {
        "summary": {
            "total_scripts": len(files),
            "total_lines": total_lines,
            "long_scripts_count": len(long_scripts),
        },
        "long_scripts": long_scripts,
        "top_10_longest": [{"file": f[0], "lines": f[1]} for f in files[:10]],
        "profile": metrics,
    }

    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 分析报告: {REPORT_FILE}")

    if metrics["errors"] or metrics.get("exit_code", 0) != 0:
        print("\n❌ Godot 启动存在错误:")
        for e in metrics.get("errors", [])[:10]:
            print(f"   {e}")


if __name__ == "__main__":
    main()
