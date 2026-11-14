#!/usr/bin/env bash
# ============================================================
# 白金英雄坛说 - 一键导出构建脚本
# 用法: ./tools/build.sh [macos|linux|windows|all]
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/godot_project"
BUILD_DIR="$PROJECT/builds"

# 自动检测 Godot 可执行文件
if [[ "$OSTYPE" == "darwin"* ]]; then
    GODOT="$ROOT/Godot_v4/MacOS/Godot.app/Contents/MacOS/Godot"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    GODOT="$ROOT/Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64"
else
    echo "❌ 不支持的操作系统: $OSTYPE"
    exit 1
fi

if [ ! -f "$GODOT" ]; then
    echo "❌ 未找到 Godot 可执行文件: $GODOT"
    echo "请将 Godot 4.7.x 放在 Godot_v4/ 目录下"
    exit 1
fi

echo "🎮 白金英雄坛说 - 导出构建工具"
echo "================================="
echo "Godot: $($GODOT --version 2>/dev/null || echo 'unknown')"
echo "项目: $PROJECT"
echo "输出: $BUILD_DIR"
echo ""

# 检查导出模板
TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates"
if [ -d "$TEMPLATE_DIR" ] && [ "$(ls -A "$TEMPLATE_DIR" 2>/dev/null)" ]; then
    echo "✅ 导出模板已安装"
else
    echo "⚠️  未检测到导出模板！"
    echo "   请下载 Godot 4.7.2 导出模板:"
    echo "   https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
    echo "   解压到: $TEMPLATE_DIR/4.7.2.stable/"
    echo ""
fi

# 运行数据验证
echo "🔍 运行数据验证..."
python3 "$ROOT/tools/validate_godot_data.py" || {
    echo "❌ 数据验证失败，请修复后重试"
    exit 1
}
echo "✅ 数据验证通过"

build_target() {
    local target="$1"
    local output_name="$2"
    echo ""
    echo "📦 导出 $target ..."
    mkdir -p "$BUILD_DIR"
    
    "$GODOT" --headless --path "$PROJECT" --export-release "$target" 2>&1 || {
        echo "⚠️  导出 $target 失败（可能是缺少导出模板）"
        return 1
    }
    
    if [ -f "$BUILD_DIR/$output_name" ] || [ -d "$BUILD_DIR/$output_name" ]; then
        echo "✅ $target 构建完成: $BUILD_DIR/$output_name"
    else
        echo "ℹ️  $target 构建完成，检查 $BUILD_DIR 目录"
    fi
}

TARGET="${1:-all}"

case "$TARGET" in
    macos)
        build_target "macOS" "白金英雄坛说.zip"
        ;;
    linux)
        build_target "Linux" "白金英雄坛说.x86_64"
        ;;
    windows)
        build_target "Windows" "白金英雄坛说.exe"
        ;;
    all)
        build_target "macOS" "白金英雄坛说.zip"
        build_target "Linux" "白金英雄坛说.x86_64"
        build_target "Windows" "白金英雄坛说.exe"
        ;;
    *)
        echo "用法: $0 [macos|linux|windows|all]"
        exit 1
        ;;
esac

echo ""
echo "🎉 构建完成！"
echo "构建输出目录: $BUILD_DIR"