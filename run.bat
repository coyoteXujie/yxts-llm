@echo off
chcp 65001 >nul
echo ========================================
echo 白金英雄坛说 - Windows
echo ========================================
echo.

:: 检查 Python 是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 Python，请先安装 Python 3.9 或更高版本
    echo.
    pause
    exit /b 1
)

:: 检查并安装依赖
if not exist "venv\" (
    echo [信息] 创建虚拟环境...
    python -m venv venv
    if errorlevel 1 (
        echo [错误] 虚拟环境创建失败
        pause
        exit /b 1
    )
)

echo [信息] 激活虚拟环境...
call venv\Scripts\activate.bat

echo [信息] 检查并安装依赖...
pip install -q -r requirements.txt

echo.
echo [信息] 启动游戏...
echo ========================================
echo.
python main.py

echo.
echo [信息] 游戏已退出
pause
