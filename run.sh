#!/bin/bash
set -e

echo "========================================"
echo "白金英雄坛说 - Linux"
echo "========================================"
echo ""

# 检查 Python 是否安装
if ! command -v python3 &> /dev/null; then
    echo "[错误] 未找到 Python 3，请先安装 Python 3.9 或更高版本"
    echo ""
    exit 1
fi

# 检查并创建虚拟环境
if [ ! -d "venv" ]; then
    echo "[信息] 创建虚拟环境..."
    python3 -m venv venv
fi

echo "[信息] 激活虚拟环境..."
source venv/bin/activate

echo "[信息] 检查并安装依赖..."
pip install -q -r requirements.txt

echo ""
echo "[信息] 启动游戏..."
echo "========================================"
echo ""

python3 main.py

echo ""
echo "[信息] 游戏已退出"
