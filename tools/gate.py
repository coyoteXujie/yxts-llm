#!/usr/bin/env python3
"""发布门禁：一条命令判定当前仓库是否达到可交付状态。

这是给"自动迭代"用的裁判。规则只有一条：
    门禁不绿 = 没完成。禁止用文字描述代替门禁结果。

用法:
    python3 tools/gate.py            # 完整门禁（含 Godot 启动与流程测试）
    python3 tools/gate.py --quick    # 只跑静态检查，跳过 Godot

退出码: 0 = 硬性检查全部通过; 1 = 存在硬性失败
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GODOT_CANDIDATES = [
    "Godot_v4/MacOS/Godot.app/Contents/MacOS/Godot",
    "Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64",
]

# 三层舞台背景合计低于此字节数，视为纯色占位图，不允许出现在正式内容里。
PLACEHOLDER_MIN_BYTES = 100_000

# 已知的环境噪声，不算游戏问题。
BENIGN_ERROR_KEYS = [
    "get_system_ca_certificates",  # macOS 沙箱内读取系统证书失败
    "resources still in use",      # headless 退出时资源驻留，已计入leak警告
]

HARD: list[str] = []
WARN: list[str] = []
INFO: list[str] = []


def hard(msg: str) -> None:
    HARD.append(msg)


def warn(msg: str) -> None:
    WARN.append(msg)


def info(msg: str) -> None:
    INFO.append(msg)


def godot_binary() -> str | None:
    for rel in GODOT_CANDIDATES:
        p = REPO / rel
        if p.is_file():
            return str(p)
    return None


def godot_env() -> dict[str, str]:
    env = dict(os.environ)
    env.update(
        {
            "HOME": "/tmp/godot_gate_home",
            "XDG_DATA_HOME": "/tmp/godot_gate_data",
            "XDG_CONFIG_HOME": "/tmp/godot_gate_config",
            "XDG_CACHE_HOME": "/tmp/godot_gate_cache",
        }
    )
    return env


def run(cmd: list[str], timeout: int, env: dict[str, str] | None = None):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(REPO),
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
        )
        return proc.returncode, proc.stdout + proc.stderr, False
    except subprocess.TimeoutExpired as exc:
        out = (exc.stdout or "") + (exc.stderr or "")
        if isinstance(out, bytes):
            out = out.decode("utf-8", "replace")
        return None, out, True


# ---------------------------------------------------------------- 检查项


def check_data() -> None:
    code, out, timed_out = run([sys.executable, "tools/validate_godot_data.py"], timeout=180)
    tail = out.strip().splitlines()[-1] if out.strip() else "(无输出)"
    if timed_out:
        hard(f"数据校验超时：tools/validate_godot_data.py")
    elif code != 0 or not out.strip().startswith("OK"):
        hard("数据校验未通过：tools/validate_godot_data.py 退出码 %s" % code)
        print(out.rstrip())
    else:
        info(f"数据校验通过：{tail}")


def check_stage_placeholders() -> None:
    path = REPO / "godot_project/data/stage_layer_assets.json"
    if not path.is_file():
        hard("缺少 godot_project/data/stage_layer_assets.json")
        return

    mapping = json.loads(path.read_text(encoding="utf-8"))
    placeholders: list[tuple[str, int]] = []
    missing: list[str] = []

    for region, layers in mapping.items():
        total = 0
        for layer in ("floor", "midground", "foreground"):
            res_path = layers.get(layer)
            if not res_path:
                missing.append(f"{region}.{layer} 未配置")
                continue
            fs_path = REPO / res_path.replace("res://", "godot_project/")
            if not fs_path.is_file():
                missing.append(f"{region}.{layer} 文件不存在: {res_path}")
                continue
            total += fs_path.stat().st_size
        if total and total < PLACEHOLDER_MIN_BYTES:
            placeholders.append((region, total))

    if missing:
        hard("舞台背景配置有 %d 处问题，例如：%s" % (len(missing), "; ".join(missing[:5])))

    if placeholders:
        placeholders.sort(key=lambda item: item[1])
        sample = ", ".join(f"{r}({s // 1024}KB)" for r, s in placeholders[:12])
        hard(
            "有 %d/%d 个区域的舞台背景是纯色占位图（三层合计 < %dKB）：%s%s"
            % (
                len(placeholders),
                len(mapping),
                PLACEHOLDER_MIN_BYTES // 1000,
                sample,
                " ..." if len(placeholders) > 12 else "",
            )
        )
    else:
        info(f"舞台背景无占位图：{len(mapping)} 个区域全部达标")


def check_batch_artifacts() -> None:
    """批量生成脚本的产物不允许进入正式内容。"""
    banned_patterns = ("*_batch_v1.png", "*_v3.png")
    hits: list[str] = []
    roots = [REPO / "godot_project/assets/world/scenes", REPO / "godot_project/assets/world/stage_layers"]
    for root in roots:
        if not root.is_dir():
            continue
        for pattern in banned_patterns:
            hits.extend(sorted(p.name for p in root.glob(pattern)))

    if hits:
        warn(
            "发现 %d 个批量生成产物仍在 assets 里（应先确认无引用再删除）：%s"
            % (len(hits), ", ".join(hits[:8]))
        )


def check_git() -> None:
    code, out, _ = run(["git", "status", "--porcelain"], timeout=60)
    if code != 0:
        warn("无法读取 git 状态")
        return

    modified = [line for line in out.splitlines() if line[:2].strip() and not line.startswith("??")]
    untracked = [line for line in out.splitlines() if line.startswith("??")]

    if len(modified) > 5:
        warn(
            "工作区有 %d 个已跟踪文件被修改（铁律：单轮 ≤ 5）。应立刻按明确路径分类提交。"
            % len(modified)
        )
    if len(untracked) > 50:
        warn("有 %d 条未跟踪条目，需要清理成可提交状态。" % len(untracked))

    risky = [line for line in modified if "README.md" in line or "14_Godot" in line]
    if risky:
        warn("正在修改进度描述文件（README.md / docs/14）：进度数字必须由脚本生成，禁止手写。")

    info(f"git 工作区：已修改 {len(modified)} 个文件，未跟踪 {len(untracked)} 条")


def _scan_errors(label: str, output: str) -> None:
    lines = output.splitlines()
    real: list[str] = []
    leaks = 0

    for idx, line in enumerate(lines):
        if "SCRIPT ERROR" in line:
            real.append(line.strip())
            continue
        if line.startswith("ERROR:"):
            context = " ".join(lines[idx : idx + 3])
            if any(key in context for key in BENIGN_ERROR_KEYS):
                continue
            real.append(line.strip())
        if "instances were leaked" in line or "resources still in use" in line:
            leaks += 1

    if real:
        hard("%s出现 %d 处错误：" % (label, len(real)))
        for line in real[:6]:
            print("    " + line)
    if leaks:
        warn("%s存在 %d 处退出时资源/对象泄漏（ObjectDB leaked）。" % (label, leaks))


def check_headless_boot() -> None:
    binary = godot_binary()
    if not binary:
        hard("找不到 Godot 可执行文件，无法做启动验证（请修正 AGENTS.md 里的引擎路径）")
        return

    code, out, timed_out = run(
        [binary, "--headless", "--path", "godot_project", "--quit-after", "1"],
        timeout=180,
        env=godot_env(),
    )
    if timed_out:
        hard("headless 启动超时（超过 180 秒未退出）")
        return
    if code != 0:
        hard(f"headless 启动退出码异常：{code}")
    _scan_errors("headless 启动", out)
    if code == 0:
        info("headless 启动完成")


def check_flow_test() -> None:
    binary = godot_binary()
    scene = REPO / "godot_project/tests/playtest_flow.tscn"
    if not binary:
        return
    if not scene.is_file():
        warn("缺少 tests/playtest_flow.tscn，跳过头less 流程测试")
        return

    started = time.time()
    code, out, timed_out = run(
        [binary, "--headless", "--path", "godot_project", "res://tests/playtest_flow.tscn"],
        timeout=240,
        env=godot_env(),
    )
    elapsed = time.time() - started

    if timed_out:
        hard(
            "流程测试 %d 秒未结束（当前已知：headless 下挂死）。"
            "这是最高优先级缺陷，修好之前任何「验证通过」都不成立。" % int(elapsed)
        )
        return
    if code != 0:
        hard(f"流程测试退出码异常：{code}")
    if "FAIL" in out or "失败" in out:
        hard("流程测试报告了失败项，见上方输出")
        print(out[-4000:])
    elif code == 0:
        info(f"流程测试通过（耗时 {elapsed:.1f}s）")


# ---------------------------------------------------------------- 入口


def main() -> int:
    parser = argparse.ArgumentParser(description="发布门禁")
    parser.add_argument("--quick", action="store_true", help="跳过 Godot 相关检查")
    args = parser.parse_args()

    print("=" * 68)
    print("白金英雄坛说 · 发布门禁")
    print("=" * 68)

    check_data()
    check_stage_placeholders()
    check_batch_artifacts()
    check_git()
    if not args.quick:
        check_headless_boot()
        check_flow_test()
    else:
        info("--quick：已跳过 headless 启动与流程测试")

    if INFO:
        print("\n[通过]")
        for line in INFO:
            print("  - " + line)
    if WARN:
        print("\n[警告]")
        for line in WARN:
            print("  - " + line)
    if HARD:
        print("\n[硬性失败]")
        for line in HARD:
            print("  - " + line)

    print("\n" + "-" * 68)
    if HARD:
        print(f"门禁结果: FAIL（{len(HARD)} 项硬性失败 / {len(WARN)} 项警告）")
        print("不许把 FAIL 描述成完成。修到 PASS 再汇报。")
        return 1
    print(f"门禁结果: PASS（{len(WARN)} 项警告）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
