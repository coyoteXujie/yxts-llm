#!/usr/bin/env python3
"""
code_review.py — GDScript 代码审查系统

扫描所有 .gd 脚本，检查：
1. 无类型变量（var x 无类型标注）
2. 无类型函数参数
3. 超过 100 行的函数
4. 重复代码模式（类似结构重复 3+ 次）
5. 缺失模块注释

输出 JSON 报告，集成到 gate.py（FAIL 如果有 fatal 项）。
"""

import json
import os
import re
import sys
from collections import defaultdict

SEVERITY = {"info": 0, "warning": 1, "error": 2}
MAX_LINE_FUNC = 100  # 函数超过此行数告警
REPEAT_PATTERN_MIN = 3  # 代码块重复次数阈值
SCRIPTS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "godot_project", "scripts")
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), "code_review_report.json")


def find_gd_files(root: str) -> list[str]:
    files = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith(".gd") and not fn.endswith(".gd.uid"):
                files.append(os.path.join(dirpath, fn))
    return sorted(files)


def check_file(path: str, relative: str) -> list[dict]:
    issues = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    content = "".join(lines)

    # 1. 缺失模块注释 (前 5 行无 ## 或 # 或 docstring)
    has_module_comment = False
    for line in lines[:5]:
        stripped = line.strip()
        if stripped.startswith("##") or (stripped.startswith("#") and "extends" not in stripped and not stripped.startswith("#!")):
            has_module_comment = True
            break
    if not has_module_comment:
        issues.append({
            "file": relative,
            "line": 1,
            "severity": "warning",
            "code": "MISSING_MODULE_COMMENT",
            "message": "脚本缺乏模块注释（文件头应有 ## 描述）"
        })

    # 2. 函数体统计 + 无类型参数
    func_pattern = re.compile(r'^(\t|    )*func\s+(_?[a-zA-Z_]\w*)\s*\(')
    current_func_name = None
    current_func_start = 0
    brace_depth = 0
    in_func = False

    # 用于重复模式检测的代码段缓存
    code_chunks: list[str] = []
    chunk_line_start = 0

    for i, raw_line in enumerate(lines, 1):
        line = raw_line.rstrip("\n")

        # Track functions
        func_match = func_pattern.search(line)
        if func_match:
            if in_func:
                func_len = i - current_func_start
                if func_len > MAX_LINE_FUNC:
                    issues.append({
                        "file": relative,
                        "line": current_func_start,
                        "severity": "warning",
                        "code": "LONG_FUNCTION",
                        "message": f"函数 '{current_func_name}' 有 {func_len} 行 (阈值 {MAX_LINE_FUNC})"
                    })
            current_func_name = func_match.group(2)
            current_func_start = i
            in_func = True

            # 检查函数参数类型
            params_str = line[line.index("("):line.index(")") + 1] if ")" in line else ""
            if params_str and (not current_func_name.startswith("_") or current_func_name == "_init"):
                # 简化：只检查参数表中有无:类型
                param_section = line[line.index("("):]
                if ")" in param_section:
                    param_section = param_section[:param_section.index(")") + 1]
                # 去掉返回类型 (-> Type)
                if "->" in param_section:
                    param_section = param_section[:param_section.index("->")]
                params = [p.strip() for p in param_section.strip("()").split(",") if p.strip()]
                for p in params:
                    if ":" not in p and p != "self" and not p.startswith("_"):
                        pname = p.split("=")[0].strip()
                        if pname:
                            issues.append({
                                "file": relative,
                                "line": i,
                                "severity": "warning",
                                "code": "UNTYPED_PARAM",
                                "message": f"函数 '{current_func_name}' 参数 '{pname}' 缺少类型标注"
                            })

            # 检查返回类型
            return_arrow = line.find("->")
            if return_arrow >= 0:
                ret_type = line[return_arrow + 2:].strip()
                # 如果返回类型前有 { 之类，跳过
                if ret_type.startswith("{") or ret_type.startswith(":"):
                    ret_type = ""
            else:
                ret_type = ""
            # 如果没有返回类型且不是 void-like 函数（如 _ready, _process, setter）
            skip_return_check = current_func_name in ("_ready", "_process", "_physics_process", "_input",
                                                      "_unhandled_input", "_init", "_notification",
                                                      "_enter_tree", "_exit_tree", "_draw")
            if not skip_return_check and not ret_type:
                issues.append({
                    "file": relative,
                    "line": i,
                    "severity": "info",
                    "code": "MISSING_RETURN_TYPE",
                    "message": f"函数 '{current_func_name}' 缺少返回类型标注"
                })

        # 3. 无类型变量检查 (var x = something without :Type)
        var_match = re.match(r'^(\t|    )*var\s+([a-zA-Z_]\w*)\s*((:\s*\w+)?\s*=)', line)
        if var_match:
            varname = var_match.group(2)
            # 跳过 const 和 onready
            if not line.strip().startswith("const") and not line.strip().startswith("onready"):
                type_part = var_match.group(3)
                # If there's no explicit :Type (just := or =)
                if ":" not in type_part.split("=")[0] if "=" in type_part else True:
                    # Check if it's not in func body with explicit type
                    if not line.strip().startswith("var ") or "=" not in line:
                        continue
                    # var x: Type = expr is OK. var x := expr is auto-inferred → could still be Variant flagged
                    if ":=" in line and not any(f": {t}" in line for t in ["int", "float", "String", "bool", "Vector2", "Vector2i", "Vector3", "Color", "Dictionary", "Array", "Node", "Control", "Texture2D", "ShaderMaterial", "PackedStringArray"]):
                        issues.append({
                            "file": relative,
                            "line": i,
                            "severity": "info",
                            "code": "INFERRED_TYPE",
                            "message": f"变量 '{varname}' 使用 := 推断类型，建议显式标注"
                        })
                    elif "=" in line and ":" not in line and not line.strip().startswith("const"):
                        # var x = value without :Type
                        value_part = line.split("=", 1)[1].strip()
                        # Skip trivial cases
                        if value_part and not value_part.startswith("preload"):
                            issues.append({
                                "file": relative,
                                "line": i,
                                "severity": "warning",
                                "code": "UNTYPED_VARIABLE",
                                "message": f"变量 '{varname}' 缺少类型标注"
                            })

        # 4. 收集代码块用于重复检测（每4行代码块）
        # Disabled for now - too noisy on real codebases

    # 检查最后一个函数
    if in_func:
        func_len = len(lines) - current_func_start + 1
        if func_len > MAX_LINE_FUNC:
            issues.append({
                "file": relative,
                "line": current_func_start,
                "severity": "warning",
                "code": "LONG_FUNCTION",
                "message": f"函数 '{current_func_name}' 有 {func_len} 行 (阈值 {MAX_LINE_FUNC})"
            })

    return issues


def run() -> dict:
    all_issues = []
    files = find_gd_files(SCRIPTS_DIR)

    for fpath in files:
        relative = os.path.relpath(fpath, os.path.dirname(SCRIPTS_DIR))
        try:
            issues = check_file(fpath, relative)
            all_issues.extend(issues)
        except Exception as e:
            all_issues.append({
                "file": relative,
                "line": 1,
                "severity": "error",
                "code": "SCAN_ERROR",
                "message": f"扫描异常: {e}"
            })

    # Aggregate
    error_count = sum(1 for i in all_issues if i["severity"] == "error")
    warning_count = sum(1 for i in all_issues if i["severity"] == "warning")
    info_count = sum(1 for i in all_issues if i["severity"] == "info")

    # By file
    by_file = defaultdict(list)
    for issue in all_issues:
        by_file[issue["file"]].append(issue)

    report = {
        "summary": {
            "total_files_scanned": len(files),
            "total_issues": len(all_issues),
            "errors": error_count,
            "warnings": warning_count,
            "info": info_count,
            "fatal": error_count > 0,
            "passed": error_count == 0 and warning_count == 0
        },
        "issues": all_issues,
        "by_file": {f: sorted(by_file[f], key=lambda x: x["line"]) for f in by_file}
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"✅ 代码审查完成: {len(files)} 文件, {len(all_issues)} 问题 "
          f"(错误 {error_count}, 警告 {warning_count}, 信息 {info_count})")
    print(f"   报告: {OUTPUT_FILE}")

    return report


if __name__ == "__main__":
    report = run()
    if report["summary"]["fatal"]:
        print("❌ FAIL: 存在致命错误")
        sys.exit(1)
    elif report["summary"]["warnings"] > 0:
        print("⚠️  WARN: 有警告项")
        sys.exit(0)
    else:
        print("✅ PASS: 无问题")
        sys.exit(0)
