# 侠影江湖 — 系统架构设计文档

> **项目名称**：侠影江湖（Xiá Yǐng Jiāng Hú）
> **引擎版本**：Godot 4.4
> **文档版本**：v2.0
> **最后更新**：2026-05-15
> **核心原则**：高内聚 · 低耦合 · 数据驱动

---

## 目录

1. [架构总览](#一架构总览)
2. [Godot项目目录结构](#二godot项目目录结构)
3. [核心架构模式](#三核心架构模式)
4. [系统详细设计](#四系统详细设计)
5. [数据文件格式](#五数据文件格式)
6. [通信规则](#六通信规则)

---

## 一、架构总览

### 1.1 设计理念

侠影江湖采用**分层架构**与**模块化设计**，确保每个子系统职责单一、边界清晰。整体架构遵循以下核心原则：

| 原则 | 说明 |
|------|------|
| **高内聚** | 每个模块只负责一类功能，模块内部元素紧密关联 |
| **低耦合** | 模块之间通过信号/事件通信，避免硬依赖 |
| **数据驱动** | 游戏内容（NPC、物品、技能、剧情）由 JSON 数据文件定义，脚本只负责逻辑 |
| **单一职责** | 每个类只做一件事，职责变更时只需修改一处 |
| **开闭原则** | 对扩展开放（新增门派、技能、剧情），对修改关闭（不改动核心逻辑） |

### 1.2 系统分层架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      表现层 (UI)                              │
│  HUD / 背包 / 技能面板 / 小地图 / 商店 / 任务追踪 / 设置       │
├─────────────────────────────────────────────────────────────┤
│                     场景层 (Scenes)                           │
│  主菜单 / 角色创建 / 游戏世界 / 战斗 / 对话 / 过场动画          │
├─────────────────────────────────────────────────────────────┤
│                     逻辑层 (Scripts)                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  GameManager  │  SaveSystem  │  EventBus  │              │ │
│  └───────────────┴──────────────┴────────────┘              │ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  WorldSystem  │  EntitySystem  │  CombatSystem  │        │ │
│  └───────────────┴───────────────┴───────────────┘          │ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  DialogueSystem  │  QuestSystem  │  UISystem  │          │ │
│  └──────────────────┴───────────────┴────────────┘          │ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  FactionSystem  │  EconomySystem  │  TimeWeatherSystem  │ │
│  └──────────────────┴─────────────────┴─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     数据层 (Data)                             │
│           JSON 数据文件 / Resource 资源文件                    │
└─────────────────────────────────────────────────────────────┘
```

- **表现层**：只负责渲染与用户交互，不包含业务逻辑
- **场景层**：组织节点树，挂载脚本，协调逻辑调用
- **逻辑层**：核心游戏逻辑，系统间通过 EventBus 通信
- **数据层**：纯数据定义，无逻辑代码，便于策划调整

---

## 二、Godot项目目录结构

### 2.1 完整目录树

```
project/
├── doc/                                    # 设计文档
│   ├── 01_game_design.md                   # 游戏设计文档
│   ├── 02_story_bible.md                   # 故事设定集
│   ├── 03_art_style.md                     # 美术风格指南
│   └── 06_system_architecture.md           # 系统架构文档（本文档）
│
├── scenes/                                 # 场景文件（.tscn）
│   ├── main/
│   │   └── main.tscn                       # 游戏入口场景
│   ├── menu/
│   │   ├── main_menu.tscn                  # 主菜单
│   │   ├── settings.tscn                   # 设置界面
│   │   └── load_game.tscn                  # 加载存档
│   ├── character_creation/
│   │   ├── character_creator.tscn          # 角色创建器
│   │   └── faction_select.tscn             # 门派选择
│   ├── game_world/
│   │   ├── overworld.tscn                  # 大世界地图
│   │   ├── town/
│   │   │   ├── luoyang.tscn                # 洛阳城
│   │   │   ├── changan.tscn                # 长安城
│   │   │   └── suzhou.tscn                 # 苏州城
│   │   ├── dungeon/
│   │   │   ├── black_wind_cave.tscn        # 黑风寨
│   │   │   └── shaolin_tower.tscn          # 少林塔
│   │   └── wilderness/
│   │       ├── forest.tscn                 # 森林
│   │       └── mountain.tscn               # 山脉
│   ├── combat/
│   │   └── combat_arena.tscn               # 战斗竞技场
│   ├── dialogue/
│   │   └── dialogue_box.tscn               # 对话框UI
│   └── ui/
│       ├── hud.tscn                        # HUD
│       ├── inventory_ui.tscn               # 背包界面
│       ├── skill_panel.tscn                # 技能面板
│       ├── quest_tracker.tscn              # 任务追踪
│       ├── shop_ui.tscn                    # 商店界面
│       └── minimap.tscn                    # 小地图
│
├── scripts/                                # GDScript 脚本（.gd）
│   ├── core/                               # 核心系统
│   │   ├── game_manager.gd                 # 游戏管理器（单例）
│   │   ├── save_system.gd                  # 存档系统（单例）
│   │   └── event_bus.gd                    # 事件总线（信号中心，单例）
│   │
│   ├── entities/                           # 实体系统
│   │   ├── player.gd                       # 玩家控制器
│   │   ├── npc.gd                          # NPC 基类
│   │   ├── enemy.gd                        # 敌人控制器
│   │   └── components/
│   │       ├── health_component.gd         # 生命值组件
│   │       ├── movement_component.gd       # 移动组件
│   │       ├── combat_component.gd         # 战斗组件
│   │       ├── inventory_component.gd      # 背包组件
│   │       ├── skill_component.gd          # 技能组件
│   │       ├── dialogue_component.gd       # 对话组件
│   │       └── ai_component.gd             # AI组件
│   │
│   ├── world/                              # 世界系统
│   │   ├── world_map.gd                    # 世界地图管理
│   │   ├── zone_manager.gd                 # 区域管理
│   │   ├── tile_data.gd                    # 地块数据
│   │   └── weather_manager.gd              # 天气管理
│   │
│   ├── combat/                             # 战斗系统
│   │   ├── combat_manager.gd               # 战斗管理器
│   │   ├── skill_system.gd                 # 技能系统
│   │   ├── damage_calculator.gd            # 伤害计算
│   │   └── status_effect_system.gd         # 状态效果系统
│   │
│   ├── dialogue/                           # 对话系统
│   │   ├── dialogue_manager.gd             # 对话管理器
│   │   ├── dialogue_parser.gd              # 对话解析器
│   │   └── story_engine.gd                 # 故事引擎
│   │
│   ├── quest/                              # 任务系统
│   │   ├── quest_manager.gd                # 任务管理器
│   │   ├── quest_tracker.gd                # 任务追踪
│   │   └── quest_reward.gd                 # 任务奖励
│   │
│   ├── ui/                                 # UI 系统
│   │   ├── hud_controller.gd               # HUD 控制器
│   │   ├── inventory_controller.gd         # 背包控制器
│   │   ├── skill_panel_controller.gd       # 技能面板控制器
│   │   ├── shop_controller.gd              # 商店控制器
│   │   └── ui_manager.gd                   # UI 管理器
│   │
│   ├── data/                               # 数据层（Resource 子类）
│   │   ├── npc_data.gd                     # NPC 数据资源
│   │   ├── item_data.gd                    # 物品数据资源
│   │   ├── skill_data.gd                   # 技能数据资源
│   │   ├── quest_data.gd                   # 任务数据资源
│   │   ├── dialogue_data.gd                # 对话数据资源
│   │   └── faction_data.gd                 # 门派数据资源
│   │
│   └── systems/                            # 游戏子系统
│       ├── faction_system.gd               # 门派系统
│       ├── reputation_system.gd            # 声望系统
│       ├── economy_system.gd               # 经济系统
│       ├── shop_system.gd                  # 商店系统
│       ├── time_system.gd                  # 时间系统
│       └── cultivation_system.gd           # 修炼系统
│
├── resources/                              # 资源文件
│   ├── sprites/
│   │   ├── characters/                     # 角色精灵
│   │   ├── enemies/                        # 敌人精灵
│   │   ├── items/                          # 物品精灵
│   │   ├── ui/                             # UI精灵
│   │   └── effects/                        # 特效精灵
│   ├── tilesets/
│   │   ├── overworld/                      # 大世界地块
│   │   ├── town/                           # 城镇地块
│   │   ├── dungeon/                        # 地牢地块
│   │   └── indoor/                         # 室内地块
│   ├── audio/
│   │   ├── bgm/                            # 背景音乐
│   │   ├── sfx/                            # 音效
│   │   └── voice/                          # 语音
│   ├── fonts/                              # 字体
│   ├── shaders/                            # 着色器
│   └── animations/                         # 动画资源
│
└── data/                                   # JSON 数据文件
    ├── npcs.json                           # NPC 数据
    ├── items.json                          # 物品数据
    ├── skills.json                         # 技能数据
    ├── quests.json                         # 任务数据
    ├── dialogues.json                      # 对话数据
    ├── factions.json                       # 门派数据
    └── stories/                            # 故事数据目录
        ├── main_story.json                 # 主线剧情
        ├── side_quests.json                # 支线任务
        └── faction_stories/                # 门派专属剧情
            ├── shaolin.json
            ├── wudang.json
            └── emei.json
```

### 2.2 目录职责说明

| 目录 | 职责 | 内聚性说明 |
|------|------|-----------|
| `scenes/` | 场景节点树组织，只做节点挂载与布局 | 同一功能场景归入同一子目录 |
| `scripts/core/` | 全局单例管理器，控制游戏生命周期 | 每个管理器职责单一且互不直接调用 |
| `scripts/entities/` | 游戏实体行为逻辑 | 实体只关心自身行为，通过信号通知外部 |
| `scripts/world/` | 世界地图与区域管理 | 世界相关逻辑集中管理 |
| `scripts/combat/` | 战斗相关全部逻辑 | 战斗系统自包含，不依赖对话/任务细节 |
| `scripts/dialogue/` | 对话与剧情逻辑 | 对话解析、分支、触发独立封装 |
| `scripts/quest/` | 任务系统逻辑 | 任务接受、进度、完成独立管理 |
| `scripts/ui/` | 界面交互逻辑 | UI 只监听信号更新显示，不包含业务逻辑 |
| `scripts/data/` | 自定义 Resource 类，承载数据结构 | 纯数据定义，无副作用 |
| `scripts/systems/` | 游戏子系统（门派/任务/经济等） | 每个子系统独立运作，通过 EventBus 交互 |
| `resources/` | 美术/音频/着色器等资源 | 按类型分子目录，便于资源管理 |
| `data/` | JSON 数据文件，策划可编辑 | 数据与代码分离，支持热更新 |

### 2.3 Autoload（自动加载）配置

在 Godot 项目设置中注册以下 Autoload 单例：

| 名称 | 脚本路径 | 说明 |
|------|---------|------|
| `GameManager` | `res://scripts/core/game_manager.gd` | 游戏全局状态管理 |
| `SaveSystem` | `res://scripts/core/save_system.gd` | 存档读写管理 |
| `EventBus` | `res://scripts/core/event_bus.gd` | 全局信号中心 |
| `DialogueManager` | `res://scripts/dialogue/dialogue_manager.gd` | 对话系统管理 |
| `CombatManager` | `res://scripts/combat/combat_manager.gd` | 战斗系统管理 |
| `QuestManager` | `res://scripts/quest/quest_manager.gd` | 任务系统管理 |
| `FactionSystem` | `res://scripts/systems/faction_system.gd` | 门派系统管理 |
| `EconomySystem` | `res://scripts/systems/economy_system.gd` | 经济系统管理 |
| `TimeSystem` | `res://scripts/systems/time_system.gd` | 时间系统管理 |

---

## 三、核心架构模式

### 3.1 单例模式（Singleton Pattern）

**适用对象**：全局管理器（GameManager、SaveSystem、EventBus）

**实现方式**：通过 Godot Autoload 机制注册为全局单例，脚本中通过类名直接访问。

```gdscript
# scripts/core/game_manager.gd
extends Node
class_name GameManager

enum GameState { MENU, CHARACTER_CREATION, PLAYING, COMBAT, DIALOGUE, PAUSED }

var current_state: GameState = GameState.MENU
var player_data: Dictionary = {}
var play_time: float = 0.0

signal game_state_changed(new_state: GameState)
signal play_time_updated(time: float)

func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        play_time += delta
        if fmod(play_time, 1.0) < delta:
            game_play_time_updated.emit(play_time)

func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    var old_state := current_state
    current_state = new_state
    game_state_changed.emit(new_state)
    EventBus.game_state_changed.emit(old_state, new_state)
```

**设计要点**：
- 单例只管理自身领域的状态，不越界调用其他单例的方法
- 状态变更通过信号通知，而非直接调用其他管理器
- 单例之间通过 EventBus 解耦，保持低耦合

### 3.2 观察者模式（Observer Pattern）— EventBus

**核心思想**：所有系统间通信通过 EventBus 的信号完成，发送方不需要知道接收方是谁。

```gdscript
# scripts/core/event_bus.gd
extends Node
class_name EventBus

# ==================== 游戏状态信号 ====================
signal game_state_changed(old_state, new_state)
signal game_paused()
signal game_resumed()

# ==================== 玩家信号 ====================
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_mp_changed(current_mp: float, max_mp: float)
signal player_level_up(new_level: int)
signal player_experience_gained(amount: int)
signal player_died()
signal player_moved(position: Vector2)

# ==================== 战斗信号 ====================
signal combat_started(enemies: Array)
signal combat_ended(victory: bool, rewards: Dictionary)
signal turn_started(character: Node)
signal turn_ended(character: Node)
signal skill_used(caster: Node, skill: Dictionary, targets: Array)
signal damage_dealt(source: Node, target: Node, amount: float, element: String)
signal character_died(character: Node)

# ==================== 对话信号 ====================
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal dialogue_choice_made(choice_id: String)
signal story_flag_set(flag_name: String, value: Variant)

# ==================== 任务信号 ====================
signal quest_accepted(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_index: int, progress: int)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)

# ==================== 经济信号 ====================
signal gold_changed(amount: int, delta: int)
signal item_acquired(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_equipped(item_id: String, slot: String)
signal item_unequipped(item_id: String, slot: String)

# ==================== 声望信号 ====================
signal reputation_changed(faction_id: String, delta: int, new_value: int)

# ==================== 世界信号 ====================
signal zone_entered(zone_id: String)
signal zone_exited(zone_id: String)
signal npc_interacted(npc_id: String)
signal weather_changed(weather_type: String)
signal time_of_day_changed(time_of_day: String)

# ==================== 门派信号 ====================
signal faction_joined(faction_id: String)
signal faction_perk_unlocked(faction_id: String, perk_id: String)
```

**使用规范**：

```gdscript
# ✅ 正确：发送方不需要知道谁在监听
EventBus.player_hp_changed.emit(current_hp, max_hp)

# ✅ 正确：接收方在 _ready 中连接信号
func _ready() -> void:
    EventBus.player_hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: float, maximum: float) -> void:
    hp_bar.value = current / maximum * 100
```

**设计要点**：
- 信号命名遵循 `模块_动作` 格式，清晰表达语义
- 信号参数必须类型明确，避免 Dictionary 滥用
- 严禁在信号回调中再次 emit 同一信号（防止循环）
- 需要跨系统通信时，**必须**通过 EventBus，禁止直接引用其他系统单例

### 3.3 状态机模式（State Machine Pattern）

**适用场景**：游戏全局状态、NPC AI 状态、战斗角色状态

#### 3.3.1 游戏状态机

```
         ┌────────────┐
    ┌────│   MENU     │────┐
    │    └────────────┘    │
    │         │            │
    ▼         ▼            ▼
┌────────┐ ┌────────────┐ ┌──────────────────┐
│PAUSED  │ │  PLAYING   │ │CHARACTER_CREATION│
└────────┘ └────┬───────┘ └──────────────────┘
    ▲      ┌────┴────┐
    │      ▼         ▼
    │  ┌────────┐ ┌────────┐
    └──│COMBAT  │ │DIALOGUE│
       └────────┘ └────────┘
```

#### 3.3.2 NPC AI 状态机

```gdscript
# scripts/entities/npc.gd
extends CharacterBody2D
class_name NPC

enum AIState { IDLE, PATROL, CHASE, FLEE, INTERACT, COMBAT }

var ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0

func _physics_process(delta: float) -> void:
    match ai_state:
        AIState.IDLE:
            _process_idle(delta)
        AIState.PATROL:
            _process_patrol(delta)
        AIState.CHASE:
            _process_chase(delta)
        AIState.FLEE:
            _process_flee(delta)
        AIState.INTERACT:
            _process_interact(delta)
        AIState.COMBAT:
            _process_combat(delta)

func transition_to(new_state: AIState) -> void:
    _exit_state(ai_state)
    ai_state = new_state
    _enter_state(new_state)

func _enter_state(state: AIState) -> void:
    match state:
        AIState.IDLE:
            state_timer = randf_range(2.0, 5.0)
            velocity = Vector2.ZERO
        AIState.PATROL:
            _pick_next_patrol_point()
        AIState.CHASE:
            _set_target(GameManager.player_position)
        AIState.FLEE:
            _set_flee_direction()

func _exit_state(state: AIState) -> void:
    pass

func _process_idle(delta: float) -> void:
    state_timer -= delta
    if state_timer <= 0:
        transition_to(AIState.PATROL)

func _process_patrol(delta: float) -> void:
    if patrol_points.is_empty():
        transition_to(AIState.IDLE)
        return
    var target := patrol_points[current_patrol_index]
    var direction := (target - global_position).normalized()
    velocity = direction * 50.0
    if global_position.distance_to(target) < 10.0:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
        transition_to(AIState.IDLE)
    move_and_slide()
```

#### 3.3.3 战斗角色状态

```
┌─────────┐  回合开始  ┌──────────┐  选择技能  ┌──────────┐
│ WAITING  │───────────│ READY    │───────────│ ACTING   │
└─────────┘           └──────────┘           └────┬─────┘
     ▲                                           │
     │              回合结束                     ▼
     │         ┌──────────┐             ┌──────────┐
     └─────────│ COOLDOWN │◄────────────│ RESOLVING│
               └──────────┘             └──────────┘
```

### 3.4 组件模式（Component Pattern）

**核心思想**：实体不通过继承扩展功能，而是通过组合组件实现。每个组件是一个独立节点，挂载到实体上。

```gdscript
# scripts/entities/components/health_component.gd
extends Node
class_name HealthComponent

@export var max_hp: float = 100.0
var current_hp: float

signal hp_changed(current: float, maximum: float)
signal died()

func _ready() -> void:
    current_hp = max_hp

func take_damage(amount: float) -> void:
    current_hp = max(0.0, current_hp - amount)
    hp_changed.emit(current_hp, max_hp)
    if current_hp <= 0.0:
        died.emit()

func heal(amount: float) -> void:
    current_hp = min(max_hp, current_hp + amount)
    hp_changed.emit(current_hp, max_hp)

func set_max_hp(new_max: float) -> void:
    var ratio := current_hp / max_hp
    max_hp = new_max
    current_hp = max_hp * ratio
    hp_changed.emit(current_hp, max_hp)
```

```gdscript
# scripts/entities/components/movement_component.gd
extends Node
class_name MovementComponent

@export var speed: float = 200.0
@export var sprint_multiplier: float = 1.5
var is_sprinting: bool = false
var owner: CharacterBody2D

func _ready() -> void:
    owner = get_parent()

func get_velocity(direction: Vector2) -> Vector2:
    var multiplier := sprint_multiplier if is_sprinting else 1.0
    return direction.normalized() * speed * multiplier

func move(direction: Vector2) -> void:
    owner.velocity = get_velocity(direction)
    owner.move_and_slide()
```

**实体组合示例**：

```
Player (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── CombatComponent (Node)
├── InventoryComponent (Node)
├── SkillComponent (Node)
├── Sprite2D
└── AnimationPlayer

NPC (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── DialogueComponent (Node)
├── AIComponent (Node)
├── Sprite2D
└── AnimationPlayer
```

**设计要点**：
- 组件之间不直接引用，通过拥有者实体或信号通信
- 组件可复用：玩家和 NPC 共享 HealthComponent、MovementComponent
- 新功能只需新增组件，不修改现有实体代码

### 3.5 数据驱动设计（Data-Driven Design）

**核心思想**：游戏内容由 JSON 数据文件定义，代码只负责加载和执行逻辑。

#### 3.5.1 自定义 Resource 类

```gdscript
# scripts/data/skill_data.gd
extends Resource
class_name SkillData

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: String = "attack"          # attack / defense / support / ultimate
@export var element: String = "physical"     # physical / fire / ice / poison / internal
@export var base_damage: float = 0.0
@export var mp_cost: float = 0.0
@export var cooldown: int = 0                 # 回合数
@export var target_type: String = "single"   # single / all / self
@export var status_effects: Array[Dictionary] = []
@export var faction_requirement: String = ""  # 空表示无门派限制
@export var level_requirement: int = 1
@export var animation: String = ""
```

```gdscript
# scripts/data/item_data.gd
extends Resource
class_name ItemData

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: String = "consumable"      # consumable / equipment / material / quest
@export var rarity: String = "common"        # common / uncommon / rare / epic / legendary
@export var stackable: bool = true
@export var max_stack: int = 99
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var effects: Array[Dictionary] = []
@export var icon: Texture2D = null
```

#### 3.5.2 JSON 数据加载

```gdscript
# scripts/core/game_manager.gd
var skill_database: Dictionary = {}
var item_database: Dictionary = {}
var npc_database: Dictionary = {}
var quest_database: Dictionary = {}

func load_all_data() -> void:
    skill_database = _load_json("res://data/skills.json")
    item_database = _load_json("res://data/items.json")
    npc_database = _load_json("res://data/npcs.json")
    quest_database = _load_json("res://data/quests.json")

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("数据文件不存在: " + path)
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var json := JSON.new()
    var err := json.parse(file.get_as_text())
    if err != OK:
        push_error("JSON 解析错误 %s: %s" % [path, json.get_error_message()])
        return {}
    return json.data

func get_skill(skill_id: String) -> Dictionary:
    return skill_database.get(skill_id, {})

func get_item(item_id: String) -> Dictionary:
    return item_database.get(item_id, {})

func get_npc(npc_id: String) -> Dictionary:
    return npc_database.get(npc_id, {})

func get_quest(quest_id: String) -> Dictionary:
    return quest_database.get(quest_id, {})
```

**设计要点**：
- JSON 文件由策划维护，代码无需修改即可调整游戏内容
- Resource 类提供类型安全的运行时数据访问
- 数据加载在游戏启动时一次性完成，运行时只读取不写入

---

## 四、系统详细设计

### 4.1 Game Manager（主游戏控制器）

#### 4.1.1 系统职责
- 管理游戏全局状态
- 协调各系统初始化和关闭
- 提供全局数据访问接口
- 管理游戏时间
- 处理场景切换

#### 4.1.2 数据结构

```gdscript
# scripts/core/game_manager.gd
var player_name: String = "少侠"
var player_level: int = 1
var player_experience: int = 0
var player_position: Vector2 = Vector2.ZERO
var player_current_hp: float = 100.0
var player_max_hp: float = 100.0
var player_current_mp: float = 50.0
var player_max_mp: float = 50.0
var player_attack: float = 10.0
var player_defense: float = 5.0
var player_speed: float = 10.0
var player_critical_rate: float = 0.05
var player_inventory: InventoryComponent
var player_equipment: Dictionary = {}
var player_skills: Array[String] = []
```

#### 4.1.3 核心类/函数

```gdscript
func _ready() -> void:
    load_all_data()

func change_game_state(new_state: GameState) -> void:
    change_state(new_state)

func get_player_data() -> Dictionary:
    return {
        "name": player_name,
        "level": player_level,
        "hp": player_current_hp,
        "max_hp": player_max_hp,
        "mp": player_current_mp,
        "max_mp": player_max_mp,
        "attack": player_attack,
        "defense": player_defense,
        "speed": player_speed
    }

func add_experience(amount: int) -> void:
    player_experience += amount
    var exp_required = _get_exp_required(player_level)
    while player_experience >= exp_required:
        player_experience -= exp_required
        player_level += 1
        _level_up()
        exp_required = _get_exp_required(player_level)
    EventBus.player_experience_gained.emit(amount)

func _level_up() -> void:
    player_max_hp += 10
    player_current_hp = player_max_hp
    player_max_mp += 5
    player_current_mp = player_max_mp
    player_attack += 2
    player_defense += 1
    EventBus.player_level_up.emit(player_level)

func _get_exp_required(level: int) -> int:
    return 100 * level * level
```

#### 4.1.4 与其他系统的接口
- 通过 EventBus 发送状态变更信号
- 为 SaveSystem 提供数据收集接口
- 为其他系统提供全局数据访问

#### 4.1.5 Godot节点结构

```
Main (Node)
├── GameManager (Autoload)
├── SaveSystem (Autoload)
├── EventBus (Autoload)
└── [其他场景]
```

---

### 4.2 Save/Load System（存档系统）

#### 4.2.1 系统职责
- 管理存档的保存和加载
- 收集各系统数据进行序列化
- 恢复各系统数据进行反序列化
- 管理存档槽位
- 提供存档版本兼容性检查

#### 4.2.2 数据结构

```gdscript
# scripts/core/save_system.gd
const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const MAX_SAVE_SLOTS := 10
const CURRENT_SAVE_VERSION := 2

class SaveData:
    var save_version: int = CURRENT_SAVE_VERSION
    var timestamp: Dictionary = {}
    var play_time: float = 0.0
    var player_data: Dictionary = {}
    var world_data: Dictionary = {}
    var story_data: Dictionary = {}
    var quest_data: Dictionary = {}
    var npc_data: Dictionary = {}
    var economy_data: Dictionary = {}
    var reputation_data: Dictionary = {}
    var faction_data: Dictionary = {}
    var time_data: Dictionary = {}
```

#### 4.2.3 核心类/函数

```gdscript
func save_game(slot: int) -> bool:
    var save_data := SaveData.new()
    save_data.timestamp = Time.get_datetime_dict_from_system()
    save_data.play_time = GameManager.play_time

    save_data.player_data = _collect_player_data()
    save_data.world_data = _collect_world_data()
    save_data.story_data = _collect_story_data()
    save_data.quest_data = _collect_quest_data()
    save_data.npc_data = _collect_npc_data()
    save_data.economy_data = _collect_economy_data()
    save_data.reputation_data = _collect_reputation_data()
    save_data.faction_data = _collect_faction_data()
    save_data.time_data = _collect_time_data()

    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)

    var file_path := SAVE_DIR + "slot_%02d%s" % [slot, SAVE_EXTENSION]
    var file := FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        push_error("存档写入失败: " + file_path)
        return false

    var json_string := JSON.stringify(_save_data_to_dict(save_data), "\t")
    file.store_string(json_string)
    file.close()
    return true

func load_game(slot: int) -> bool:
    var file_path := SAVE_DIR + "slot_%02d%s" % [slot, SAVE_EXTENSION]
    if not FileAccess.file_exists(file_path):
        push_error("存档不存在: " + file_path)
        return false

    var file := FileAccess.open(file_path, FileAccess.READ)
    var json := JSON.new()
    var err := json.parse(file.get_as_text())
    if err != OK:
        push_error("存档解析失败: " + file_path)
        return false

    var save_dict: Dictionary = json.data
    if save_dict.get("save_version", 0) > CURRENT_SAVE_VERSION:
        push_error("存档版本过高，不兼容")
        return false

    var save_data := _dict_to_save_data(save_dict)

    _restore_player_data(save_data.player_data)
    _restore_world_data(save_data.world_data)
    _restore_story_data(save_data.story_data)
    _restore_quest_data(save_data.quest_data)
    _restore_npc_data(save_data.npc_data)
    _restore_economy_data(save_data.economy_data)
    _restore_reputation_data(save_data.reputation_data)
    _restore_faction_data(save_data.faction_data)
    _restore_time_data(save_data.time_data)

    GameManager.play_time = save_data.play_time
    GameManager.change_state(GameManager.GameState.PLAYING)
    return true

func get_save_list() -> Array:
    var saves := []
    for i in range(MAX_SAVE_SLOTS):
        var file_path := SAVE_DIR + "slot_%02d%s" % [i, SAVE_EXTENSION]
        if FileAccess.file_exists(file_path):
            var file := FileAccess.open(file_path, FileAccess.READ)
            var json := JSON.new()
            json.parse(file.get_as_text())
            saves.append({
                "slot": i,
                "timestamp": json.data.get("timestamp", {}),
                "play_time": json.data.get("play_time", 0.0),
                "player_name": json.data.get("player_data", {}).get("name", "未知")
            })
    return saves
```

#### 4.2.4 与其他系统的接口
- 从 GameManager 获取玩家数据
- 从 WorldSystem 获取世界数据
- 从 QuestSystem 获取任务数据
- 从 FactionSystem 获取门派数据
- 通过 EventBus 通知存档完成

#### 4.2.5 Godot节点结构

```
SaveSystem (Node, Autoload)
```

---

### 4.3 Event Bus（事件总线）

#### 4.3.1 系统职责
- 定义所有全局信号
- 作为系统间通信的唯一中介
- 解耦发送方和接收方

#### 4.3.2 数据结构
见 3.2 节的信号定义

#### 4.3.3 核心类/函数
无函数，仅信号定义

#### 4.3.4 与其他系统的接口
所有系统都通过 EventBus 通信

#### 4.3.5 Godot节点结构

```
EventBus (Node, Autoload)
```

---

### 4.4 World System（世界地图、区域管理）

#### 4.4.1 系统职责
- 管理世界地图
- 管理区域加载和卸载
- 管理区域状态
- 管理天气和时间
- 管理世界事件

#### 4.4.2 数据结构

```gdscript
# scripts/world/zone_manager.gd
var current_zone_id: String = ""
var visited_zones: Array[String] = []
var unlocked_zones: Array[String] = []
var zone_states: Dictionary = {}
var zones: Dictionary = {}
```

#### 4.4.3 核心类/函数

```gdscript
func load_zone(zone_id: String) -> void:
    if current_zone_id != "":
        unload_zone(current_zone_id)
    current_zone_id = zone_id
    if zone_id not in visited_zones:
        visited_zones.append(zone_id)
    zone_states[zone_id] = zone_states.get(zone_id, {})
    var zone_scene = load("res://scenes/game_world/%s.tscn" % zone_id)
    if zone_scene:
        var zone_instance = zone_scene.instantiate()
        get_tree().root.add_child(zone_instance)
    EventBus.zone_entered.emit(zone_id)

func unload_zone(zone_id: String) -> void:
    var zone_node = get_tree().root.get_node_or_null(zone_id)
    if zone_node:
        zone_node.queue_free()
    EventBus.zone_exited.emit(zone_id)

func unlock_zone(zone_id: String) -> void:
    if zone_id not in unlocked_zones:
        unlocked_zones.append(zone_id)

func is_zone_unlocked(zone_id: String) -> bool:
    return zone_id in unlocked_zones

func get_zone_state(zone_id: String) -> Dictionary:
    return zone_states.get(zone_id, {})

func set_zone_state(zone_id: String, state: Dictionary) -> void:
    zone_states[zone_id] = state
```

#### 4.4.4 与其他系统的接口
- 通过 EventBus 通知区域变更
- 为 SaveSystem 提供区域数据
- 与 TimeWeatherSystem 协作

#### 4.4.5 Godot节点结构

```
WorldMap (Node2D)
├── ZoneManager (Node)
├── WeatherManager (Node)
├── TileMap
└── [区域实例]
```

---

### 4.5 Entity System（玩家、NPC、敌人）

#### 4.5.1 系统职责
- 管理所有游戏实体
- 处理实体创建和销毁
- 管理实体组件
- 处理实体交互

#### 4.5.2 数据结构

```gdscript
# scripts/entities/player.gd
extends CharacterBody2D
class_name Player

var health: HealthComponent
var movement: MovementComponent
var combat: CombatComponent
var inventory: InventoryComponent
var skills: SkillComponent

func _ready() -> void:
    health = get_node("HealthComponent")
    movement = get_node("MovementComponent")
    combat = get_node("CombatComponent")
    inventory = get_node("InventoryComponent")
    skills = get_node("SkillComponent")

    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
    var input_dir := Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        input_dir.x += 1
    if Input.is_action_pressed("ui_left"):
        input_dir.x -= 1
    if Input.is_action_pressed("ui_down"):
        input_dir.y += 1
    if Input.is_action_pressed("ui_up"):
        input_dir.y -= 1
    movement.move(input_dir)
    GameManager.player_position = global_position

func _on_hp_changed(current: float, maximum: float) -> void:
    GameManager.player_current_hp = current
    GameManager.player_max_hp = maximum
    EventBus.player_hp_changed.emit(current, maximum)

func _on_died() -> void:
    EventBus.player_died.emit()
```

#### 4.5.3 核心类/函数
见 3.4 节的组件定义

#### 4.5.4 与其他系统的接口
- 通过 EventBus 发送实体状态变更
- 与 CombatSystem 协作
- 与 DialogueSystem 协作

#### 4.5.5 Godot节点结构

```
Player (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── CombatComponent (Node)
├── InventoryComponent (Node)
├── SkillComponent (Node)
├── Sprite2D
├── CollisionShape2D
└── AnimationPlayer

NPC (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── DialogueComponent (Node)
├── AIComponent (Node)
├── Sprite2D
├── CollisionShape2D
└── AnimationPlayer
```

---

### 4.6 Combat System（回合制战斗）

#### 4.6.1 系统职责
- 管理战斗流程
- 管理回合顺序
- 处理技能使用
- 计算伤害
- 管理状态效果
- 判断战斗胜负

#### 4.6.2 数据结构

```gdscript
# scripts/combat/combat_manager.gd
var combatants: Array[Node] = []
var turn_order: Array[Node] = []
var current_turn_index: int = 0
var is_combat_active: bool = false
var combat_rewards: Dictionary = {}
```

#### 4.6.3 核心类/函数

```gdscript
func start_combat(enemies: Array) -> void:
    is_combat_active = true
    combatants = [GameManager.player]
    combatants.append_array(enemies)
    turn_order = sort_by_speed(combatants)
    current_turn_index = 0
    GameManager.change_state(GameManager.GameState.COMBAT)
    EventBus.combat_started.emit(enemies)
    _start_next_turn()

func sort_by_speed(characters: Array[Node]) -> Array[Node]:
    var sorted := characters.duplicate()
    sorted.sort_custom(func(a, b): return a.combat.speed > b.combat.speed)
    return sorted

func _start_next_turn() -> void:
    if not is_combat_active:
        return
    if current_turn_index >= turn_order.size():
        current_turn_index = 0
        _apply_all_status_effects()
        turn_order = sort_by_speed(turn_order.filter(func(c): return not c.health.current_hp <= 0))
    if _check_combat_end():
        return
    var current_character := turn_order[current_turn_index]
    EventBus.turn_started.emit(current_character)
    if current_character is Player:
        _wait_for_player_input()
    else:
        _execute_ai_turn(current_character)

func use_skill(caster: Node, skill_id: String, targets: Array) -> void:
    var skill_data := GameManager.get_skill(skill_id)
    if not _can_use_skill(caster, skill_data):
        return
    caster.combat.current_mp -= skill_data.mp_cost
    EventBus.player_mp_changed.emit(caster.combat.current_mp, caster.combat.max_mp)
    _set_cooldown(caster, skill_id, skill_data.cooldown)
    for target in targets:
        var damage_result := DamageCalculator.calculate(skill_data, caster, target)
        target.health.take_damage(damage_result.damage)
        EventBus.damage_dealt.emit(caster, target, damage_result.damage, skill_data.element)
        _apply_status_effects(target, skill_data.status_effects)
    EventBus.skill_used.emit(caster, skill_data, targets)
    _end_turn(caster)

func _end_turn(character: Node) -> void:
    EventBus.turn_ended.emit(character)
    current_turn_index += 1
    _start_next_turn()

func _check_combat_end() -> bool:
    var player_alive := false
    var enemies_alive := false
    for combatant in combatants:
        if combatant.health.current_hp > 0:
            if combatant is Player:
                player_alive = true
            else:
                enemies_alive = true
    if not player_alive or not enemies_alive:
        _end_combat(player_alive)
        return true
    return false

func _end_combat(victory: bool) -> void:
    is_combat_active = false
    if victory:
        combat_rewards = _calculate_rewards()
    GameManager.change_state(GameManager.GameState.PLAYING)
    EventBus.combat_ended.emit(victory, combat_rewards)
```

#### 4.6.4 与其他系统的接口
- 通过 EventBus 发送战斗事件
- 与 QuestSystem 协作（战斗任务）
- 与 EconomySystem 协作（战斗奖励）

#### 4.6.5 Godot节点结构

```
CombatArena (Node2D)
├── CombatManager (Node)
├── SkillSystem (Node)
├── DamageCalculator (Node)
├── StatusEffectSystem (Node)
├── PlayerBattleUI (Control)
├── EnemyBattleUI (Control)
└── [战斗实体]
```

---

### 4.7 Dialogue/Story System（对话与故事）

#### 4.7.1 系统职责
- 管理对话流程
- 解析对话数据
- 处理对话分支
- 管理故事标记
- 触发故事事件

#### 4.7.2 数据结构

```gdscript
# scripts/dialogue/dialogue_manager.gd
var current_dialogue: Dictionary = {}
var current_node_id: String = ""
var dialogue_history: Array[String] = []
```

#### 4.7.3 核心类/函数

```gdscript
func start_dialogue(npc_id: String) -> void:
    var npc_data := GameManager.get_npc(npc_id)
    if not npc_data:
        return
    var dialogue_id := npc_data.get("dialogue_id", "")
    if dialogue_id == "":
        return
    var dialogues_data := _load_json("res://data/dialogues.json")
    current_dialogue = dialogues_data.get(dialogue_id, {})
    if current_dialogue.is_empty():
        return
    current_node_id = "start"
    GameManager.change_state(GameManager.GameState.DIALOGUE)
    EventBus.dialogue_started.emit(npc_id)
    _process_current_node()

func _process_current_node() -> void:
    var node := current_dialogue.get("nodes", {}).get(current_node_id, {})
    if node.is_empty():
        _end_dialogue()
        return
    var node_type := node.get("type", "text")
    match node_type:
        "text":
            _show_text_node(node)
        "choice":
            _show_choice_node(node)
        "end":
            _end_dialogue()

func _show_text_node(node: Dictionary) -> void:
    var text := node.get("text", "")
    var speaker := node.get("speaker", "npc")
    _execute_effects(node.get("effects", []))
    var next_id := node.get("next", "")
    if next_id != "":
        current_node_id = next_id
        _process_current_node()
    else:
        _end_dialogue()

func _show_choice_node(node: Dictionary) -> void:
    var options := node.get("options", [])
    var valid_options := []
    for option in options:
        if _evaluate_conditions(option.get("conditions", [])):
            valid_options.append(option)
    _display_choices(valid_options)

func select_choice(option_index: int) -> void:
    var node := current_dialogue.get("nodes", {}).get(current_node_id, {})
    var options := node.get("options", [])
    if option_index < 0 or option_index >= options.size():
        return
    var option := options[option_index]
    _execute_effects(option.get("effects", []))
    EventBus.dialogue_choice_made.emit(option.get("id", ""))
    current_node_id = option.get("next", "")
    _process_current_node()

func _execute_effects(effects: Array) -> void:
    for effect in effects:
        match effect.get("type", ""):
            "flag":
                StoryEngine.set_flag(effect.get("flag", ""), effect.get("value", false))
            "quest":
                match effect.get("action", ""):
                    "accept":
                        QuestManager.accept_quest(effect.get("quest_id", ""))
                    "complete":
                        QuestManager.complete_quest(effect.get("quest_id", ""))
            "item":
                match effect.get("action", ""):
                    "add":
                        EconomySystem.add_item(effect.get("item_id", ""), effect.get("count", 1))
                    "remove":
                        EconomySystem.remove_item(effect.get("item_id", ""), effect.get("count", 1))
            "reputation":
                ReputationSystem.change_reputation(effect.get("faction", ""), effect.get("delta", 0))
            "combat":
                _end_dialogue()
                CombatManager.start_combat(effect.get("enemies", []))
            "teleport":
                _end_dialogue()
                ZoneManager.load_zone(effect.get("zone_id", ""))

func _evaluate_conditions(conditions: Array) -> bool:
    for condition in conditions:
        match condition.get("type", ""):
            "flag":
                var flag_value := StoryEngine.get_flag(condition.get("flag", ""))
                if flag_value != condition.get("value", false):
                    return false
            "level":
                if GameManager.player_level < condition.get("min", 0):
                    return false
            "faction":
                if FactionSystem.get_player_faction() != condition.get("faction", ""):
                    return false
            "reputation":
                if ReputationSystem.get_reputation(condition.get("faction", "")) < condition.get("min", 0):
                    return false
            "quest_state":
                if QuestManager.get_quest_state(condition.get("quest_id", "")) != condition.get("state", ""):
                    return false
    return true

func _end_dialogue() -> void:
    var npc_id := current_dialogue.get("npc_id", "")
    current_dialogue = {}
    current_node_id = ""
    GameManager.change_state(GameManager.GameState.PLAYING)
    EventBus.dialogue_ended.emit(npc_id)
```

#### 4.7.4 与其他系统的接口
- 通过 EventBus 发送对话事件
- 与 QuestSystem 协作（对话任务）
- 与 CombatSystem 协作（触发战斗）
- 与 StoryEngine 协作（故事标记）

#### 4.7.5 Godot节点结构

```
DialogueBox (Control)
├── DialogueManager (Node)
├── StoryEngine (Node)
├── DialogueParser (Node)
├── TextLabel (Label)
├── SpeakerLabel (Label)
├── ChoicesContainer (VBoxContainer)
└── [Choice Buttons]
```

---

### 4.8 Quest System（任务系统）

#### 4.8.1 系统职责
- 管理任务接受和完成
- 跟踪任务进度
- 发放任务奖励
- 管理任务状态

#### 4.8.2 数据结构

```gdscript
# scripts/quest/quest_manager.gd
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var failed_quests: Array[String] = []
```

#### 4.8.3 核心类/函数

```gdscript
func accept_quest(quest_id: String) -> void:
    if quest_id in active_quests or quest_id in completed_quests or quest_id in failed_quests:
        return
    var quest_data := GameManager.get_quest(quest_id)
    if not quest_data:
        return
    active_quests[quest_id] = {
        "quest_id": quest_id,
        "objectives": [],
        "progress": [],
        "accepted_time": Time.get_ticks_msec()
    }
    var objectives := quest_data.get("objectives", [])
    for obj in objectives:
        active_quests[quest_id]["objectives"].append(obj)
        active_quests[quest_id]["progress"].append(0)
    EventBus.quest_accepted.emit(quest_id)

func update_objective(quest_id: String, objective_index: int, delta: int) -> void:
    if quest_id not in active_quests:
        return
    var quest := active_quests[quest_id]
    if objective_index < 0 or objective_index >= quest["progress"].size():
        return
    quest["progress"][objective_index] += delta
    var objective := quest["objectives"][objective_index]
    var max_progress := objective.get("target", 1)
    quest["progress"][objective_index] = min(quest["progress"][objective_index], max_progress)
    EventBus.quest_objective_updated.emit(quest_id, objective_index, quest["progress"][objective_index])
    _check_quest_completion(quest_id)

func _check_quest_completion(quest_id: String) -> void:
    if quest_id not in active_quests:
        return
    var quest := active_quests[quest_id]
    var all_completed := true
    for i in range(quest["objectives"].size()):
        var objective := quest["objectives"][i]
        var progress := quest["progress"][i]
        if progress < objective.get("target", 1):
            all_completed = false
            break
    if all_completed:
        complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
    if quest_id not in active_quests:
        return
    var quest_data := GameManager.get_quest(quest_id)
    var rewards := quest_data.get("rewards", {})
    _give_rewards(rewards)
    completed_quests.append(quest_id)
    active_quests.erase(quest_id)
    EventBus.quest_completed.emit(quest_id, rewards)

func _give_rewards(rewards: Dictionary) -> void:
    var gold := rewards.get("gold", 0)
    var exp := rewards.get("exp", 0)
    var items := rewards.get("items", [])
    if gold > 0:
        EconomySystem.add_gold(gold)
    if exp > 0:
        GameManager.add_experience(exp)
    for item in items:
        EconomySystem.add_item(item.get("item_id", ""), item.get("count", 1))

func fail_quest(quest_id: String) -> void:
    if quest_id not in active_quests:
        return
    failed_quests.append(quest_id)
    active_quests.erase(quest_id)
    EventBus.quest_failed.emit(quest_id)

func get_quest_state(quest_id: String) -> String:
    if quest_id in completed_quests:
        return "completed"
    if quest_id in failed_quests:
        return "failed"
    if quest_id in active_quests:
        return "active"
    return "available"
```

#### 4.8.4 与其他系统的接口
- 通过 EventBus 发送任务事件
- 监听 CombatSystem 事件（击杀任务）
- 与 EconomySystem 协作（任务奖励）
- 与 DialogueSystem 协作（对话任务）

#### 4.8.5 Godot节点结构

```
QuestManager (Node, Autoload)
├── QuestTracker (Node)
└── QuestReward (Node)
```

---

### 4.9 UI System（HUD、背包、技能等）

#### 4.9.1 系统职责
- 管理所有UI界面
- 显示游戏信息
- 处理用户输入
- 更新UI状态

#### 4.9.2 数据结构

```gdscript
# scripts/ui/ui_manager.gd
var current_ui: Control = null
var ui_stack: Array[Control] = []
```

#### 4.9.3 核心类/函数

```gdscript
# scripts/ui/hud_controller.gd
extends Control

func _ready() -> void:
    EventBus.player_hp_changed.connect(_on_hp_changed)
    EventBus.player_mp_changed.connect(_on_mp_changed)
    EventBus.player_level_up.connect(_on_level_up)
    EventBus.gold_changed.connect(_on_gold_changed)
    EventBus.quest_objective_updated.connect(_on_quest_updated)

func _on_hp_changed(current: float, maximum: float) -> void:
    $HPBar.value = current / maximum * 100
    $HPBar/Label.text = "%d / %d" % [current, maximum]

func _on_mp_changed(current: float, maximum: float) -> void:
    $MPBar.value = current / maximum * 100
    $MPBar/Label.text = "%d / %d" % [current, maximum]

func _on_level_up(new_level: int) -> void:
    $LevelLabel.text = "等级: %d" % new_level

func _on_gold_changed(amount: int, delta: int) -> void:
    $GoldLabel.text = "银两: %d" % amount

func _on_quest_updated(quest_id: String, objective_index: int, progress: int) -> void:
    _update_quest_tracker()
```

```gdscript
# scripts/ui/inventory_controller.gd
extends Control

var inventory: InventoryComponent

func _ready() -> void:
    inventory = GameManager.player_inventory
    EventBus.item_acquired.connect(_on_item_acquired)
    EventBus.item_removed.connect(_on_item_removed)
    _refresh_inventory()

func _refresh_inventory() -> void:
    var container := $ItemContainer
    for child in container.get_children():
        child.queue_free()
    for i in range(inventory.slots.size()):
        var slot := inventory.slots[i]
        var slot_ui := preload("res://scenes/ui/inventory_slot.tscn").instantiate()
        slot_ui.slot_index = i
        if not slot.is_empty():
            slot_ui.set_item(slot.item_id, slot.count)
        container.add_child(slot_ui)

func _on_item_acquired(item_id: String, count: int) -> void:
    _refresh_inventory()

func _on_item_removed(item_id: String, count: int) -> void:
    _refresh_inventory()
```

#### 4.9.4 与其他系统的接口
- 只监听 EventBus 信号更新显示
- 不直接调用其他系统
- 通过 EventBus 发送用户操作事件

#### 4.9.5 Godot节点结构

```
UIManager (Control)
├── HUD (Control)
│   ├── HPBar (ProgressBar)
│   ├── MPBar (ProgressBar)
│   ├── LevelLabel (Label)
│   ├── GoldLabel (Label)
│   ├── QuestTracker (Control)
│   └── Minimap (Control)
├── InventoryUI (Control)
│   ├── ItemContainer (GridContainer)
│   └── ItemDetails (Control)
├── SkillPanel (Control)
│   ├── SkillList (VBoxContainer)
│   └── SkillDetails (Control)
├── ShopUI (Control)
│   ├── ShopItems (GridContainer)
│   └── PlayerInventory (GridContainer)
└── SettingsUI (Control)
```

---

### 4.10 Faction/Reputation System（门派声望）

#### 4.10.1 系统职责
- 管理玩家门派
- 管理门派声望
- 解锁门派技能
- 管理门派特权

#### 4.10.2 数据结构

```gdscript
# scripts/systems/faction_system.gd
var player_faction: String = ""
var faction_reputation: Dictionary = {}
var unlocked_perks: Dictionary = {}
```

#### 4.10.3 核心类/函数

```gdscript
func join_faction(faction_id: String) -> void:
    if player_faction != "":
        return
    player_faction = faction_id
    if faction_id not in faction_reputation:
        faction_reputation[faction_id] = 0
    EventBus.faction_joined.emit(faction_id)

func change_reputation(faction_id: String, delta: int) -> void:
    if faction_id not in faction_reputation:
        faction_reputation[faction_id] = 0
    faction_reputation[faction_id] += delta
    faction_reputation[faction_id] = clamp(faction_reputation[faction_id], -100, 100)
    EventBus.reputation_changed.emit(faction_id, delta, faction_reputation[faction_id])
    _check_perk_unlocks(faction_id)

func get_reputation(faction_id: String) -> int:
    return faction_reputation.get(faction_id, 0)

func get_player_faction() -> String:
    return player_faction

func _check_perk_unlocks(faction_id: String) -> void:
    var rep := get_reputation(faction_id)
    var faction_data := _get_faction_data(faction_id)
    var perks := faction_data.get("perks", [])
    for perk in perks:
        var perk_id := perk.get("id", "")
        var required_rep := perk.get("required_reputation", 0)
        if rep >= required_rep and perk_id not in unlocked_perks.get(faction_id, []):
            _unlock_perk(faction_id, perk_id)

func _unlock_perk(faction_id: String, perk_id: String) -> void:
    if faction_id not in unlocked_perks:
        unlocked_perks[faction_id] = []
    if perk_id not in unlocked_perks[faction_id]:
        unlocked_perks[faction_id].append(perk_id)
        EventBus.faction_perk_unlocked.emit(faction_id, perk_id)

func is_perk_unlocked(faction_id: String, perk_id: String) -> bool:
    return perk_id in unlocked_perks.get(faction_id, [])
```

#### 4.10.4 与其他系统的接口
- 通过 EventBus 发送声望变更
- 与 QuestSystem 协作（声望奖励）
- 与 DialogueSystem 协作（门派对话）

#### 4.10.5 Godot节点结构

```
FactionSystem (Node, Autoload)
└── ReputationSystem (Node)
```

---

### 4.11 Economy/Shop System（经济商店）

#### 4.11.1 系统职责
- 管理玩家金币
- 管理玩家背包
- 处理物品购买和出售
- 管理商店库存

#### 4.11.2 数据结构

```gdscript
# scripts/systems/economy_system.gd
var gold: int = 0
```

#### 4.11.3 核心类/函数

```gdscript
func add_gold(amount: int) -> void:
    gold += amount
    EventBus.gold_changed.emit(gold, amount)

func remove_gold(amount: int) -> bool:
    if gold < amount:
        return false
    gold -= amount
    EventBus.gold_changed.emit(gold, -amount)
    return true

func get_gold() -> int:
    return gold

func buy_item(shop_id: String, item_id: String, count: int) -> bool:
    var item_data := GameManager.get_item(item_id)
    if not item_data:
        return false
    var total_price := item_data.buy_price * count
    if gold < total_price:
        return false
    if not _shop_has_item(shop_id, item_id, count):
        return false
    if not GameManager.player_inventory.can_add_item(item_id, count):
        return false
    remove_gold(total_price)
    _remove_item_from_shop(shop_id, item_id, count)
    GameManager.player_inventory.add_item(item_id, count)
    EventBus.item_acquired.emit(item_id, count)
    return true

func sell_item(item_id: String, count: int) -> bool:
    var item_data := GameManager.get_item(item_id)
    if not item_data:
        return false
    if not GameManager.player_inventory.has_item(item_id, count):
        return false
    var total_price := item_data.sell_price * count
    GameManager.player_inventory.remove_item(item_id, count)
    add_gold(total_price)
    EventBus.item_removed.emit(item_id, count)
    return true
```

#### 4.11.4 与其他系统的接口
- 通过 EventBus 发送经济事件
- 与 QuestSystem 协作（任务奖励）
- 与 CombatSystem 协作（战斗奖励）

#### 4.11.5 Godot节点结构

```
EconomySystem (Node, Autoload)
└── ShopSystem (Node)
```

---

### 4.12 Time/Weather System（时间天气）

#### 4.12.1 系统职责
- 管理游戏时间
- 管理天气变化
- 触发时间相关事件

#### 4.12.2 数据结构

```gdscript
# scripts/systems/time_system.gd
var current_time: float = 0.0
var day: int = 1
var time_of_day: String = "morning"
var current_weather: String = "clear"
```

#### 4.12.3 核心类/函数

```gdscript
func _process(delta: float) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    current_time += delta * 10
    if current_time >= 240:
        current_time = 0
        day += 1
    var new_time_of_day = _get_time_of_day()
    if new_time_of_day != time_of_day:
        time_of_day = new_time_of_day
        EventBus.time_of_day_changed.emit(time_of_day)
    if randf() < 0.001:
        _change_weather()

func _get_time_of_day() -> String:
    if current_time < 60:
        return "night"
    elif current_time < 120:
        return "morning"
    elif current_time < 180:
        return "afternoon"
    else:
        return "evening"

func _change_weather() -> void:
    var weathers = ["clear", "cloudy", "rain", "snow", "storm"]
    var new_weather = weathers.pick_random()
    if new_weather != current_weather:
        current_weather = new_weather
        EventBus.weather_changed.emit(current_weather)
```

#### 4.12.4 与其他系统的接口
- 通过 EventBus 发送时间和天气变化
- 与 WorldSystem 协作（视觉效果）

#### 4.12.5 Godot节点结构

```
TimeSystem (Node, Autoload)
└── WeatherManager (Node)
```

---

## 五、数据文件格式

### 5.1 NPC 数据

```json
{
  "npc_001": {
    "id": "npc_001",
    "name": "张铁匠",
    "description": "洛阳城的铁匠，性格豪爽",
    "faction": "blacksmith_guild",
    "dialogue_id": "dialogue_001",
    "sprite": "res://assets/sprites/npcs/blacksmith.png",
    "position": {"x": 100, "y": 200},
    "zone_id": "luoyang",
    "shop_id": "shop_001"
  }
}
```

### 5.2 物品数据

```json
{
  "item_001": {
    "id": "item_001",
    "name": "铁剑",
    "description": "普通的铁制长剑",
    "type": "weapon",
    "subtype": "sword",
    "rarity": "common",
    "stackable": false,
    "max_stack": 1,
    "buy_price": 100,
    "sell_price": 30,
    "stats": {
      "attack": 10,
      "speed": 2
    },
    "icon": "res://assets/sprites/items/sword.png"
  },
  "item_002": {
    "id": "item_002",
    "name": "金疮药",
    "description": "恢复50点生命值",
    "type": "consumable",
    "rarity": "common",
    "stackable": true,
    "max_stack": 99,
    "buy_price": 20,
    "sell_price": 5,
    "effects": [
      {"type": "heal", "value": 50}
    ],
    "icon": "res://assets/sprites/items/potion.png"
  }
}
```

### 5.3 技能数据

```json
{
  "skill_001": {
    "id": "skill_001",
    "name": "太极拳",
    "description": "以柔克刚，化解敌方攻击并反击",
    "type": "attack",
    "element": "internal",
    "base_damage": 45,
    "mp_cost": 20,
    "cooldown": 0,
    "target_type": "single",
    "status_effects": [],
    "faction_requirement": "wudang",
    "level_requirement": 5,
    "animation": "tai_chi_fist"
  },
  "skill_002": {
    "id": "skill_002",
    "name": "金钟罩",
    "description": "少林绝学，大幅提升防御力",
    "type": "defense",
    "element": "internal",
    "base_damage": 0,
    "mp_cost": 35,
    "cooldown": 3,
    "target_type": "self",
    "status_effects": [
      {"type": "defense_up", "value": 0.5, "duration": 3}
    ],
    "faction_requirement": "shaolin",
    "level_requirement": 10,
    "animation": "golden_bell"
  }
}
```

### 5.4 任务数据

```json
{
  "quest_001": {
    "id": "quest_001",
    "name": "铲除黑风寨",
    "description": "帮助张铁匠消灭黑风寨的山贼",
    "type": "main",
    "objectives": [
      {"type": "kill", "target_id": "enemy_001", "target": 5, "description": "消灭5个山贼"},
      {"type": "talk", "target_id": "npc_001", "target": 1, "description": "回复张铁匠"}
    ],
    "rewards": {
      "gold": 500,
      "exp": 200,
      "items": [
        {"item_id": "item_001", "count": 1}
      ]
    },
    "prerequisites": [],
    "follow_up": "quest_002"
  }
}
```

### 5.5 对话数据

```json
{
  "dialogue_001": {
    "id": "dialogue_001",
    "npc_id": "npc_001",
    "npc_name": "张铁匠",
    "nodes": {
      "start": {
        "type": "text",
        "text": "少侠，你来得正好！近日黑风寨的贼人愈发猖狂，你可愿意助我一臂之力？",
        "speaker": "npc",
        "next": "choice_1"
      },
      "choice_1": {
        "type": "choice",
        "options": [
          {
            "text": "义不容辞，在下愿往！",
            "next": "accept_quest",
            "conditions": [
              {"type": "flag", "flag": "met_zhang_san", "value": true},
              {"type": "level", "min": 5}
            ]
          },
          {
            "text": "我需要考虑一下。",
            "next": "consider"
          },
          {
            "text": "此事与我无关。",
            "next": "refuse",
            "effects": [
              {"type": "reputation", "faction": "zhengdao", "delta": -5}
            ]
          }
        ]
      },
      "accept_quest": {
        "type": "text",
        "text": "好！少侠果然侠义心肠！这是黑风寨的地形图，请务必小心。",
        "speaker": "npc",
        "effects": [
          {"type": "quest", "action": "accept", "quest_id": "quest_001"},
          {"type": "item", "action": "add", "item_id": "item_map_black_wind"},
          {"type": "flag", "flag": "quest_black_wind_accepted", "value": true}
        ],
        "next": "end"
      },
      "consider": {
        "type": "text",
        "text": "也罢，少侠想清楚了再来找我便是。",
        "speaker": "npc",
        "next": "end"
      },
      "refuse": {
        "type": "text",
        "text": "哼，看来是我看错人了。",
        "speaker": "npc",
        "next": "end"
      },
      "end": {
        "type": "end"
      }
    }
  }
}
```

### 5.6 故事数据

```json
{
  "main_quest_001": {
    "id": "main_quest_001",
    "name": "初入江湖",
    "triggers": [
      {"type": "flag", "flag": "game_started", "value": true}
    ],
    "events": [
      {"type": "dialogue", "dialogue_id": "dialogue_intro"},
      {"type": "quest_unlock", "quest_id": "quest_001"}
    ]
  }
}
```

### 5.7 存档数据

```json
{
  "save_version": 2,
  "timestamp": {"year": 2026, "month": 5, "day": 15, "hour": 14, "minute": 30},
  "play_time": 3600.5,
  "player_data": {
    "name": "少侠",
    "level": 10,
    "experience": 2500,
    "faction": "wudang",
    "position": {"zone_id": "luoyang", "x": 150, "y": 200},
    "stats": {
      "hp": 500,
      "max_hp": 500,
      "mp": 200,
      "max_mp": 200,
      "attack": 50,
      "defense": 30,
      "speed": 15,
      "critical_rate": 0.1
    },
    "inventory": [],
    "equipment": {},
    "skills": ["skill_001", "skill_002"],
    "cultivation_level": 1
  },
  "world_data": {
    "current_zone": "luoyang",
    "visited_zones": ["luoyang", "chang'an"],
    "unlocked_zones": ["luoyang", "chang'an", "black_wind_cave"],
    "zone_states": {}
  },
  "story_data": {
    "story_flags": {"met_zhang_san": true, "quest_black_wind_accepted": true},
    "active_storylines": ["main_quest_001"],
    "completed_storylines": []
  },
  "quest_data": {
    "active_quests": {"quest_001": {"progress": [3, 0]}},
    "completed_quests": [],
    "failed_quests": []
  },
  "economy_data": {
    "gold": 1000
  },
  "reputation_data": {
    "zhengdao": 20,
    "wudang": 30
  },
  "time_data": {
    "day": 5,
    "current_time": 120,
    "weather": "clear"
  }
}
```

---

## 六、通信规则

### 6.1 通信方式总览

| 通信方式 | 适用场景 | 耦合度 | 示例 |
|---------|---------|--------|------|
| **EventBus 信号** | 跨系统、跨场景通信 | 低 | 战斗结束 → 任务系统更新进度 |
| **直接方法调用** | 父子节点、同一系统内部 | 中 | CombatManager 调用 DamageCalculator |
| **Resource 数据共享** | 只读数据传递 | 低 | 多系统读取同一 SkillData |
| **GameManager 全局状态** | 需要全局访问的共享状态 | 中 | 当前玩家等级、当前场景 |

### 6.2 通信规则详解

#### 规则一：跨系统必须通过 EventBus

✅ **正确**：
```gdscript
# CombatManager
EventBus.combat_ended.emit(true, rewards)
```

❌ **错误**：
```gdscript
# CombatManager
QuestManager.complete_objective("kill_boss")  # 禁止直接调用
```

#### 规则二：系统内部可直接调用

✅ **正确**：
```gdscript
# CombatManager
var damage := DamageCalculator.calculate(skill, attacker, defender)
```

#### 规则三：UI 只监听信号，不主动查询

✅ **正确**：
```gdscript
# HUDController
func _ready() -> void:
    EventBus.player_hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: float, maximum: float) -> void:
    hp_bar.value = current / maximum * 100
```

❌ **错误**：
```gdscript
# HUDController
func _process(_delta: float) -> void:
    hp_bar.value = GameManager.player.hp / GameManager.player.max_hp  # 禁止每帧查询
```

#### 规则四：禁止循环依赖

❌ **禁止**：
```
SystemA → SystemB → SystemC → SystemA
```

✅ **正确**：
```
SystemA → EventBus
SystemB → EventBus
SystemC → EventBus
```

### 6.3 系统依赖关系图

```
                    ┌────────────┐
                    │  EventBus  │ ◄── 全局信号中心，所有系统可访问
                    └─────┬──────┘
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐   ┌────▼─────┐   ┌─────▼──────┐
    │GameManager│   │SaveSystem│   │  各子系统    │
    │  (状态)   │   │ (存档)   │   │(门派/任务等) │
    └─────┬─────┘   └────┬─────┘   └─────┬──────┘
          │               │               │
    ┌─────▼───────────────▼───────────────▼──────┐
    │              场景层 (Scenes)                 │
    │  ┌─────────┐ ┌─────────┐ ┌──────────────┐ │
    │  │ 玩家实体 │ │ NPC实体 │ │  战斗场景     │ │
    │  └─────────┘ └─────────┘ └──────────────┘ │
    └─────────────────────────────────────────────┘
```

### 6.4 典型通信流程

#### 流程一：玩家击杀敌人 → 任务进度更新

```
1. CombatManager 检测敌人死亡
2. CombatManager → EventBus.combat_ended.emit(true, rewards)
3. QuestSystem 监听 combat_ended 信号
4. QuestSystem 内部更新击杀计数
5. QuestSystem → EventBus.quest_objective_updated.emit(quest_id, idx, progress)
6. HUD 监听 quest_objective_updated 信号，更新任务追踪UI
```

#### 流程二：NPC 对话触发战斗

```
1. 玩家与 NPC 交互
2. Player → EventBus.npc_interacted.emit(npc_id)
3. DialogueManager 监听 npc_interacted 信号
4. DialogueManager 加载对话树，显示对话框
5. 玩家选择对话选项
6. DialogueManager → EventBus.dialogue_choice_made.emit(choice_id)
7. DialogueManager 检测到战斗触发标记
8. DialogueManager → EventBus.combat_started.emit(enemies)
9. CombatManager 监听 combat_started 信号，进入战斗
```

#### 流程三：完成任务获得门派声望

```
1. QuestSystem 检测任务完成条件满足
2. QuestSystem → EventBus.quest_completed.emit(quest_id)
3. ReputationSystem 监听 quest_completed 信号
4. ReputationSystem 根据任务关联门派增加声望
5. ReputationSystem → EventBus.reputation_changed.emit(faction_id, delta)
6. FactionSystem 监听 reputation_changed 信号
7. FactionSystem 检查是否达到门派升级条件
8. HUD 监听 reputation_changed 信号，显示声望变化提示
```

### 6.5 信号命名规范

- 格式：`[系统名]_[动作]`
- 示例：
  - `player_hp_changed`
  - `combat_ended`
  - `quest_accepted`
  - `reputation_changed`

### 6.6 信号参数规范

- 参数必须类型明确
- 优先使用简单类型（int, float, String, bool）
- 复杂数据使用 Dictionary 或自定义 Resource
- 参数顺序按重要性排列

---

**文档结束**