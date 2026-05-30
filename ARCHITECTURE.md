# 侠影江湖 - 高内聚低耦合架构文档

## 分层架构设计

### 1. 基础设施层 (Infrastructure Layer)
**职责**：工具类、常量、类型定义
**依赖**：无
**包含文件**：
- `constants.gd` - 全局常量
- `utils.gd` - 通用工具函数
- `types.gd` - 类型定义

---

### 2. 数据模型层 (Data Model Layer)
**职责**：纯数据定义，无业务逻辑
**依赖**：基础设施层
**包含文件**：
- `data/player_data.gd` - 玩家数据
- `data/npc_data.gd` - NPC数据
- `data/skill_data.gd` - 技能数据
- `data/item_data.gd` - 物品数据
- `data/quest_data.gd` - 任务数据

---

### 3. 核心框架层 (Core Framework Layer)
**职责**：游戏核心框架
**依赖**：数据模型层
**包含文件**：
- `core/event_bus.gd` - 全局事件总线
- `core/save_system.gd` - 存档系统
- `core/state_machine.gd` - 状态机基类

---

### 4. 组件层 (Component Layer)
**职责**：可复用的功能组件
**依赖**：核心框架层
**包含文件**：
- `components/health_component.gd` - 生命组件
- `components/combat_component.gd` - 战斗组件
- `components/inventory_component.gd` - 背包组件
- `components/movement_component.gd` - 移动组件

---

### 5. 实体层 (Entity Layer)
**职责**：游戏实体的组织
**依赖**：组件层
**包含文件**：
- `entities/entity.gd` - 基类实体
- `entities/player.gd` - 玩家实体
- `entities/npc.gd` - NPC实体
- `entities/enemy.gd` - 敌人实体

---

### 6. 游戏世界层 (World Layer)
**职责**：世界管理、地图加载
**依赖**：实体层
**包含文件**：
- `world/world_manager.gd` - 世界管理
- `world/tile_map.gd` - 地图
- `world/zone.gd` - 区域

---

### 7. 业务系统层 (Game Systems Layer)
**职责**：游戏逻辑系统
**依赖**：世界层、核心层
**包含文件**：
- `systems/combat_system.gd` - 战斗系统
- `systems/dialogue_system.gd` - 对话系统
- `systems/quest_system.gd` - 任务系统
- `systems/game_system.gd` - 游戏流程系统

---

### 8. UI表现层 (Presentation Layer)
**职责**：UI界面
**依赖**：业务系统层、数据层
**包含文件**：
- `ui/hud.gd` - HUD
- `ui/inventory_panel.gd` - 背包界面
- `ui/skill_panel.gd` - 技能界面
- `ui/dialogue_panel.gd` - 对话界面

---

### 9. 场景层 (Scene Layer)
**职责**：场景组织
**依赖**：所有下层
**包含文件**：
- `scenes/main/main.tscn`
- `scenes/menu/menu.tscn`

---

## 模块通信方式

### 事件驱动
所有模块之间通过 `EventBus` 通信，不直接调用。

### 依赖注入
高层模块通过构造函数或属性注入需要的依赖。

