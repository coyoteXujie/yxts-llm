# 白金英雄坛说 - Python重写版

![Python Version](https://img.shields.io/badge/Python-3.9+-blue)
![Arcade Version](https://img.shields.io/badge/Arcade-3.0-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

基于汇编语言经典游戏《白金英雄坛说》的Python重写版，采用现代化2D图形界面，支持NPC与LLM智能对话，动态任务系统和完整的武侠世界体验。

## 游戏特色

### 🎮 精美2D图形界面
- 现代游戏引擎渲染，支持60fps流畅运行
- 多样化地图场景：草地、道路、水域、建筑、树木等
- 精致的角色和NPC精灵设计
- 友好的HUD界面和状态栏显示

### 🗣️ NPC与LLM智能对话
- 支持与游戏中的NPC进行自然语言对话
- LLM驱动的动态对话生成
- NPC根据身份和性格给出不同的回应

### 📜 动态任务系统
- 根据玩家等级和行动动态生成任务
- 多种任务类型：收集、击杀、对话、探索、护送
- 完成任务获得经验值、金钱和装备奖励

### ⚔️ 完整战斗系统
- 回合制战斗
- 多种技能（拳脚、剑法、躲闪、内功、招架）
- 物品使用（药品、食物）
- 敌人追踪和战斗奖励

### 🏠 武侠世界
- 平安镇地图，可四处探索
- 时间系统（天数和小时）
- 多种NPC类型：村民、商人、师父、敌人
- 门派和道德值系统

## 安装与运行

### 环境要求
- **Python**: 3.9 或更高版本
- **Arcade**: 3.0 或更高版本

### 快速开始

#### 🐧 Linux / macOS
```bash
# 克隆仓库
git clone <repository-url>
cd yxts-llm

# 方式1：使用自动脚本（推荐）
chmod +x run.sh
./run.sh

# 方式2：手动安装
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 main.py
```

#### 🪟 Windows
```batch
# 克隆仓库
git clone <repository-url>
cd yxts-llm

# 方式1：使用自动脚本（推荐）
双击 run.bat

# 方式2：手动安装
python -m venv venv
venv\Scripts\activate.bat
pip install -r requirements.txt
python main.py
```

## 操作指南

### 主菜单
- **↑/↓**: 选择菜单项
- **Enter**: 确认选择
- **ESC**: 返回上级菜单

### 游戏内操作
| 按键 | 功能 |
|------|------|
| W / ↑ | 向北移动 |
| S / ↓ | 向南移动 |
| A / ← | 向西移动 |
| D / → | 向东移动 |
| T | 与附近NPC对话 |
| F | 攻击附近敌人 |
| B | 打开背包/商店 |
| Q | 查看任务列表 |
| ESC | 返回主菜单 |

### 角色创建
| 按键 | 功能 |
|------|------|
| 1 | 增加臂力 |
| 2 | 增加身法 |
| 3 | 增加悟性 |
| 4 | 增加根骨 |
| G | 切换性别 |
| Enter | 确认创建角色 |

## 游戏系统

### 属性系统
- **臂力**: 影响攻击力和负重量
- **身法**: 影响闪避率和逃跑成功率
- **悟性**: 影响技能学习效率和内力上限
- **根骨**: 影响生命上限和防御力

### 技能类型
- 拳脚、剑法、躲闪、内功、招架、识字、容貌

### 物品类型
- 消耗品（食物、药品）
- 装备（武器、防具）

### 门派系统
- 正派、邪派、中立
- 道德值影响可加入的门派

## 项目结构

```
yxts-llm/
├── main.py                    # 游戏入口
├── assets/                    # 资源目录
│   ├── tiles/                 # 瓦片资源
│   ├── sprites/               # 精灵资源
│   ├── ui/                    # UI资源
│   └── fonts/                 # 字体资源
└── src/core/
    ├── config.py              # 游戏配置
    ├── entities.py            # 核心实体类
    ├── world.py               # 游戏世界管理
    ├── game.py                # 主游戏逻辑
    ├── combat.py              # 战斗系统
    ├── quest.py               # 任务系统
    ├── llm_client.py          # LLM客户端
    ├── event.py               # 事件系统
    ├── renderer.py            # 渲染器
    └── window.py              # 游戏窗口
```

## LLM配置

游戏支持使用LLM生成动态对话和任务。配置文件位于 `src/core/llm_client.py`。

### 支持的LLM提供商
- OpenAI GPT
- DeepSeek
- Mock模式（用于测试）

### 配置方法
在 `src/core/llm_client.py` 中设置环境变量或直接修改配置。

## 开发计划

- [x] 核心游戏架构
- [x] 2D图形界面
- [x] 玩家角色系统
- [x] NPC系统
- [x] 战斗系统
- [x] 任务系统
- [x] LLM集成
- [ ] 音效系统
- [ ] 存档/读档功能
- [ ] 更多地图区域
- [ ] 装备系统完善
- [ ] 技能树系统

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

## 致谢

- 原版《白金英雄坛说》汇编代码
- Arcade游戏引擎
- 所有贡献者和测试者
