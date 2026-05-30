# 侠影江湖 - 高内聚、低耦合架构说明

## 🎯 架构理念

这个项目采用了**分层架构**和**组件系统**，严格遵循**高内聚、低耦合**的设计原则。

---

## 📦 依赖关系 (严格单向)

```
场景层 (scenes/)
    ↓
UI表现层 (ui/)
    ↓
业务系统层 (systems/)
    ↓
世界层 (world/)
    ↓
实体层 (entities/)
    ↓
组件层 (components/)
    ↓
核心框架层 (core/)
    ↓
数据模型层 (data/)
    ↓
基础设施层 (constants.gd, utils.gd)
```

### 核心通信规则
- 向下通信：直接方法调用
- 向上/横向通信：**EventBus** 事件总线
- 绝对禁止：循环依赖

---

## 📁 目录结构

```
E:\yxts-llm\
├── project.godot              # Godot 项目配置
├── icon.svg                  # 游戏图标
├── doc/                      # 设计文档
│   ├── 01_worldview_and_factions.md
│   ├── 02_map_design.md
│   ├── 03_npc_design.md
│   ├── 04_items_equipment.md
│   ├── 05_story_quests.md
│   ├── 06_system_architecture.md
│   ├── 07_ui_design.md
│   └── 08_asset_prompts.md
│
├── scripts/
│   ├── constants.gd           # 基础设施层：全局常量
│   ├── utils.gd              # 基础设施层：工具函数
│   │
│   ├── data/                 # 数据模型层：纯数据结构
│   │   ├── player_data.gd
│   │   ├── npc_data.gd
│   │   ├── skill_data.gd
│   │   ├── item_data.gd
│   │   ├── quest_data.gd
│   │   └── dialogue_node_data.gd
│   │
│   ├── core/                 # 核心框架层：基础功能
│   │   ├── event_bus.gd         # 事件总线
│   │   ├── save_system.gd       # 存档系统
│   │   ├── data_registry.gd     # 数据注册表
│   │   └── state_machine.gd     # 状态机
│   │
│   ├── components/           # 组件层：可复用功能模块
│   │   ├── base_component.gd
│   │   ├── health_component.gd
│   │   ├── mana_component.gd
│   │   ├── inventory_component.gd
│   │   └── movement_component.gd
│   │
│   ├── entities/            # 实体层：游戏对象容器
│   │   ├── game_entity.gd
│   │   └── player_entity.gd
│   │
│   ├── world/               # 世界层：地图和区域
│   │   └── world_manager.gd
│   │
│   ├── systems/             # 业务系统层：游戏逻辑
│   │   ├── game_system.gd
│   │   ├── combat_system.gd
│   │   └── dialogue_system.gd
│   │
│   └── ui/                  # UI表现层：只依赖系统层
│       ├── hud.gd
│       ├── inventory_panel.gd
│       └── menu_screen.gd
│
└── scenes/
    └── main_scene.tscn      # 主场景
```

---

## 🎯 核心设计原则

### 1️⃣ 数据驱动
- 所有游戏数据在 `data/` 层定义
- 纯数据对象，无业务逻辑
- 便于序列化、存档、编辑器编辑

### 2️⃣ 组件系统
- 功能拆分为独立组件
- 组件间无依赖，通过实体协调
- 便于扩展和复用

### 3️⃣ 事件总线
- 所有跨层通信通过事件
- 松耦合，无直接依赖
- 全局订阅/发布模式

### 4️⃣ 状态机
- 游戏状态管理
- 定义清晰的状态转换规则
- 便于扩展

---

## 📋 关键模块说明

### EventBus (事件总线)
```gdscript
# 发送事件
EventBus.emit_player_level_up(10)

# 监听事件
EventBus.player_level_up.connect(_on_level_up)
```

### Component (组件)
```gdscript
var health_comp: HealthComponent = HealthComponent.new()
player.add_component(health_comp)

health_comp.take_damage(50)
health_comp.heal(30)
```

### Data (数据)
```gdscript
var player_data: PlayerData = PlayerData.new()
player_data.player_name = "无名侠客"
player_data.gold = 100
```

---

## 🏆 优点

| 特性 | 说明 |
|------|------|
| ✅ 高内聚 | 每个模块职责单一明确 |
| ✅ 低耦合 | 依赖关系清晰，无循环 |
| ✅ 可测试 | 每个模块可独立测试 |
| ✅ 可扩展 | 添加新功能不影响旧代码 |
| ✅ 易维护 | 代码结构清晰，定位问题快 |

---

## 🚀 运行项目

1. 打开 Godot 4.4
2. 导入 `E:\yxts-llm\project.godot`
3. 点击运行

---

## 📚 参考设计文档

查看 `doc/` 目录下的详细设计文档，包含：
- 世界观与势力设计
- 地图设计
- NPC 设计
- 物品装备设计
- 故事任务设计
- UI 设计
- 美术资源 Prompt
