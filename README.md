# 侠影江湖 - Godot 4.4 项目

## 项目概述

《侠影江湖》是一款基于 Godot 4.4 开发的宏大武侠开放世界 RPG 游戏。

### 技术栈

- **引擎**: Godot 4.4
- **语言**: GDScript
- **架构**: 高内聚、低耦合分层架构

---

## 项目结构

```
E:\yxts-llm\
├── project.godot              # Godot 项目配置
├── icon.svg                  # 游戏图标
│
├── scripts/                 # 所有游戏代码
│   ├── core/               # 核心框架
│   │   ├── constants.gd    # 全局常量
│   │   ├── utils.gd        # 工具函数
│   │   ├── event_bus.gd    # 事件总线
│   │   ├── save_system.gd  # 存档系统
│   │   ├── data_registry.gd # 数据注册表
│   │   └── state_machine.gd # 状态机
│   │
│   ├── components/          # 组件层
│   │   ├── base_component.gd
│   │   ├── health_component.gd
│   │   ├── mana_component.gd
│   │   ├── inventory_component.gd
│   │   └── movement_component.gd
│   │
│   ├── entities/           # 实体层
│   │   ├── game_entity.gd
│   │   └── player_entity.gd
│   │
│   ├── world/             # 世界层
│   │   └── world_manager.gd
│   │
│   ├── systems/           # 系统层
│   │   ├── game_system.gd
│   │   ├── combat_system.gd
│   │   ├── dialogue_system.gd
│   │   ├── quest_system.gd
│   │   ├── cultivation_system.gd
│   │   ├── economy_system.gd
│   │   ├── atmosphere_system.gd
│   │   ├── faction_system.gd
│   │   ├── vfx_system.gd
│   │   ├── encounter_system.gd
│   │   └── world_event_engine.gd
│   │
│   └── ui/               # UI层
│       └── hud.gd
│
├── scenes/                # 场景文件
│   ├── main.tscn         # 主场景
│   ├── main.gd           # 主脚本
│   └── ui/
│       ├── hud.tscn
│       └── hud.gd
│
├── doc/                  # 设计文档
│   ├── 01_worldview_and_factions.md
│   ├── 02_map_design.md
│   ├── 03_npc_design.md
│   ├── 04_items_equipment.md
│   ├── 05_story_quests.md
│   ├── 06_system_architecture.md
│   ├── 07_ui_design.md
│   └── 08_asset_prompts.md
│
├── src/                  # 原始Pygame代码
│   └── ...
│
├── doc/                  # 文档
└── README.md              # 本文件
```

---

## Autoload 系统

项目包含 16 个 Autoload 单例：

| 单例 | 用途 |
|------|------|
| `Constants` | 全局常量定义 |
| `Utils` | 工具函数库 |
| `EventBus` | 事件总线 |
| `SaveSystem` | 存档系统 |
| `DataRegistry` | 数据注册表 |
| `GameSystem` | 游戏主系统 |
| `WorldManager` | 世界管理 |
| `CombatSystem` | 战斗系统 |
| `DialogueSystem` | 对话系统 |
| `CultivationSystem` | 修炼系统 |
| `EconomySystem` | 经济系统 |
| `AtmosphereSystem` | 氛围系统 |
| `FactionSystem` | 派系系统 |
| `VFXSystem` | 视觉效果 |
| `EncounterSystem` | 遭遇系统 |
| `WorldEventEngine` | 世界事件引擎 |
| `QuestSystem` | 任务系统 |

---

## 核心系统

### 1. 游戏系统 (GameSystem)
- 游戏状态管理
- 主循环控制
- 场景切换

### 2. 战斗系统 (CombatSystem)
- 回合制战斗
- 技能释放
- 伤害计算

### 3. 对话系统 (DialogueSystem)
- 树形对话结构
- 选择分支
- 条件触发

### 4. 修炼系统 (CultivationSystem)
- 内功/外功/轻功
- 经脉系统
- 境界突破

### 5. 经济系统 (EconomySystem)
- 货币管理
- 商店交易
- 价格波动

### 6. 氛围系统 (AtmosphereSystem)
- 天气系统
- 昼夜循环
- 环境光照

### 7. 派系系统 (FactionSystem)
- 7大派系
- 声望管理
- 派系战争

### 8. 视觉效果 (VFXSystem)
- 粒子特效
- 屏幕震动
- 技能特效

### 9. 遭遇系统 (EncounterSystem)
- 随机事件
- 宝箱/伏击
- 商人遭遇

### 10. 世界事件引擎 (WorldEventEngine)
- 动态事件
- 节日活动
- 瘟疫/丰收

---

## 运行项目

### 1. 导入项目
1. 打开 Godot 4.4
2. 点击 "Import"
3. 选择 `E:\yxts-llm\project.godot`
4. 点击 "Import & Edit"

### 2. 运行游戏
1. 在编辑器中点击 "Run" (F5)
2. 或双击 `godot.exe` 打开项目后运行

### 3. 快捷键

| 按键 | 功能 |
|------|------|
| W/A/S/D | 移动 |
| E | 交互 |
| I | 背包 |
| K | 技能 |
| Q | 任务 |
| M | 地图 |
| J | 日志 |
| C | 修炼 |
| Esc | 菜单 |

---

## 设计文档

详细的设计文档位于 `doc/` 目录：

- **世界观与势力**: 5大城池、7大派系、历史背景
- **地图设计**: 城池→小镇→野外区域
- **NPC设计**: 60+核心NPC（含历史名人）
- **物品装备**: 400+物品、武器、防具
- **故事任务**: 主线5章+3结局、50+支线、30+奇遇
- **系统架构**: 高内聚低耦合设计详解
- **UI设计**: 14个界面、ASCII布局图
- **美术资源**: 350+ AI绘图Prompt

---

## 架构设计

### 分层架构

```
场景层 → UI层 → 系统层 → 世界层 → 实体层 → 组件层 → 核心层 → 数据层
```

### 通信方式

- **向下通信**: 直接方法调用
- **向上/横向通信**: EventBus 事件总线

---

## 性能优化

- ✅ 组件化设计，按需加载
- ✅ 事件驱动，避免轮询
- ✅ 数据驱动，易于扩展
- ✅ 分层架构，模块独立

---

## 开发进度

| 模块 | 状态 |
|------|------|
| 核心系统 | ✅ 完成 |
| 组件系统 | ✅ 完成 |
| 业务系统 | ✅ 完成 |
| UI系统 | ✅ 完成 |
| 场景系统 | ✅ 完成 |
| 美术资源 | ⏳ 进行中 |
| 音效系统 | ⏳ 进行中 |
| 剧情内容 | ✅ 完成 |

---

## 致谢

本项目参考了多款经典武侠游戏的设计理念，并融入了中国传统文化元素。

---

**版本**: 1.0.0  
**更新**: 2024年
