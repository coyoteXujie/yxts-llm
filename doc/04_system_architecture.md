# 侠影江湖 — 系统架构设计文档

> **项目名称**：侠影江湖（Xiá Yǐng Jiāng Hú）
> **引擎版本**：Godot 4.4
> **文档版本**：v1.0
> **最后更新**：2026-05-14
> **核心原则**：高内聚 · 低耦合 · 数据驱动

---

## 目录

1. [架构总览](#1-架构总览)
2. [项目目录结构](#2-项目目录结构)
3. [核心架构模式](#3-核心架构模式)
4. [系统间通信](#4-系统间通信)
5. [战斗系统设计](#5-战斗系统设计)
6. [对话系统设计](#6-对话系统设计)
7. [存档系统设计](#7-存档系统设计)
8. [附录：关键类接口定义](#8-附录关键类接口定义)

---

## 1. 架构总览

### 1.1 设计哲学

侠影江湖采用**分层架构**与**模块化设计**，确保每个子系统职责单一、边界清晰。整体架构遵循以下核心原则：

| 原则 | 说明 |
|------|------|
| **高内聚** | 每个模块只负责一类功能，模块内部元素紧密关联 |
| **低耦合** | 模块之间通过信号/事件通信，避免硬依赖 |
| **数据驱动** | 游戏内容（NPC、物品、技能、剧情）由 JSON 数据文件定义，脚本只负责逻辑 |
| **单一职责** | 每个类只做一件事，职责变更时只需修改一处 |
| **开闭原则** | 对扩展开放（新增门派、技能、剧情），对修改关闭（不改动核心逻辑） |

### 1.2 系统分层

```
┌─────────────────────────────────────────────────┐
│                   表现层 (UI)                     │
│         HUD / 背包 / 技能面板 / 小地图             │
├─────────────────────────────────────────────────┤
│                   场景层 (Scenes)                  │
│      主菜单 / 角色创建 / 游戏世界 / 战斗 / 对话     │
├─────────────────────────────────────────────────┤
│                   逻辑层 (Scripts)                 │
│   核心管理器 / 实体系统 / 战斗系统 / 对话系统 / 子系统 │
├─────────────────────────────────────────────────┤
│                   数据层 (Data)                    │
│         JSON 数据文件 / Resource 资源文件           │
└─────────────────────────────────────────────────┘
```

- **表现层**：只负责渲染与用户交互，不包含业务逻辑
- **场景层**：组织节点树，挂载脚本，协调逻辑调用
- **逻辑层**：核心游戏逻辑，系统间通过 EventBus 通信
- **数据层**：纯数据定义，无逻辑代码，便于策划调整

---

## 2. 项目目录结构

### 2.1 完整目录树

```
project/
├── doc/                        # 设计文档
│   ├── 01_game_design.md           # 游戏设计文档
│   ├── 02_story_bible.md           # 故事设定集
│   ├── 03_art_style.md             # 美术风格指南
│   └── 04_system_architecture.md   # 系统架构文档（本文档）
│
├── scenes/                     # 场景文件（.tscn）
│   ├── main/                       # 主场景
│   │   └── main.tscn                   # 游戏入口场景
│   ├── menu/                       # 菜单场景
│   │   ├── main_menu.tscn              # 主菜单
│   │   ├── settings.tscn               # 设置界面
│   │   └── load_game.tscn              # 加载存档
│   ├── character_creation/         # 角色创建场景
│   │   ├── character_creator.tscn      # 角色创建器
│   │   └── faction_select.tscn         # 门派选择
│   ├── game_world/                 # 游戏世界场景
│   │   ├── overworld.tscn              # 大世界地图
│   │   ├── town/                       # 城镇场景
│   │   │   ├── luoyang.tscn                # 洛阳
│   │   │   ├── changan.tscn                # 长安
│   │   │   └── suzhou.tscn                 # 苏州
│   │   ├── dungeon/                     # 秘境场景
│   │   │   ├── cave.tscn                   # 洞穴
│   │   │   └── tower.tscn                  # 高塔
│   │   └── wilderness/                  # 荒野场景
│   ├── combat/                     # 战斗场景
│   │   └── combat_arena.tscn           # 战斗竞技场
│   └── dialogue/                   # 对话场景
│       └── dialogue_box.tscn           # 对话框UI
│
├── scripts/                    # GDScript 脚本（.gd）
│   ├── core/                       # 核心系统
│   │   ├── game_manager.gd             # 游戏管理器（单例）
│   │   ├── save_system.gd              # 存档系统（单例）
│   │   └── event_bus.gd                # 事件总线（信号中心，单例）
│   │
│   ├── entities/                   # 实体系统
│   │   ├── player.gd                   # 玩家控制器
│   │   ├── npc.gd                      # NPC 基类
│   │   └── enemy.gd                    # 敌人控制器
│   │
│   ├── world/                      # 世界系统
│   │   ├── world_map.gd                # 世界地图管理
│   │   ├── zone_manager.gd             # 区域管理
│   │   └── tile_data.gd                # 地块数据
│   │
│   ├── combat/                     # 战斗系统
│   │   ├── combat_manager.gd           # 战斗管理器
│   │   ├── skill_system.gd             # 技能系统
│   │   └── damage_calculator.gd        # 伤害计算
│   │
│   ├── dialogue/                   # 对话系统
│   │   ├── dialogue_manager.gd         # 对话管理器
│   │   ├── dialogue_parser.gd          # 对话解析器
│   │   └── story_engine.gd             # 故事引擎
│   │
│   ├── ui/                         # UI 系统
│   │   ├── hud.gd                      # HUD 控制器
│   │   ├── inventory_ui.gd             # 背包界面
│   │   ├── skill_panel.gd              # 技能面板
│   │   └── minimap.gd                  # 小地图
│   │
│   ├── data/                       # 数据层（Resource 子类）
│   │   ├── npc_data.gd                 # NPC 数据资源
│   │   ├── item_data.gd                # 物品数据资源
│   │   ├── skill_data.gd               # 技能数据资源
│   │   └── story_data.gd               # 故事数据资源
│   │
│   └── systems/                    # 游戏子系统
│       ├── faction_system.gd           # 门派系统
│       ├── quest_system.gd             # 任务系统
│       ├── economy_system.gd           # 经济系统
│       ├── cultivation_system.gd       # 修炼系统
│       └── reputation_system.gd        # 声望系统
│
├── resources/                   # 资源文件
│   ├── sprites/                    # 精灵图
│   │   ├── characters/                 # 角色精灵
│   │   ├── enemies/                    # 敌人精灵
│   │   └── effects/                    # 特效精灵
│   ├── tilesets/                   # 地块集
│   │   ├── overworld/                  # 大世界地块
│   │   └── indoor/                     # 室内地块
│   ├── audio/                      # 音频
│   │   ├── bgm/                        # 背景音乐
│   │   ├── sfx/                        # 音效
│   │   └── voice/                      # 语音
│   ├── fonts/                      # 字体
│   └── shaders/                    # 着色器
│
└── data/                        # JSON 数据文件
    ├── npcs.json                   # NPC 数据
    ├── items.json                  # 物品数据
    ├── skills.json                 # 技能数据
    └── stories/                    # 故事数据目录
        ├── main_quest.json             # 主线剧情
        ├── side_quest.json             # 支线任务
        └── faction_stories/            # 门派专属剧情
            ├── shaolin.json                # 少林
            ├── wudang.json                 # 武当
            └── emei.json                   # 峨眉
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
| `scripts/ui/` | 界面交互逻辑 | UI 只监听信号更新显示，不包含业务逻辑 |
| `scripts/data/` | 自定义 Resource 类，承载数据结构 | 纯数据定义，无副作用 |
| `scripts/systems/` | 游戏子系统（门派/任务/经济/修炼/声望） | 每个子系统独立运作，通过 EventBus 交互 |
| `resources/` | 美术/音频/着色器等资源 | 按类型分子目录，便于资源管理 |
| `data/` | JSON 数据文件，策划可编辑 | 数据与代码分离，支持热更新 |

### 2.3 Autoload（自动加载）配置

在 Godot 项目设置中注册以下 Autoload 单例：

| 名称 | 脚本路径 | 说明 |
|------|---------|------|
| `GameManager` | `scripts/core/game_manager.gd` | 游戏全局状态管理 |
| `SaveSystem` | `scripts/core/save_system.gd` | 存档读写管理 |
| `EventBus` | `scripts/core/event_bus.gd` | 全局信号中心 |
| `DialogueManager` | `scripts/dialogue/dialogue_manager.gd` | 对话系统管理 |
| `CombatManager` | `scripts/combat/combat_manager.gd` | 战斗系统管理 |
| `QuestSystem` | `scripts/systems/quest_system.gd` | 任务系统管理 |
| `FactionSystem` | `scripts/systems/faction_system.gd` | 门派系统管理 |
| `EconomySystem` | `scripts/systems/economy_system.gd` | 经济系统管理 |

---

## 3. 核心架构模式

### 3.1 单例模式（Singleton Pattern）

**适用对象**：全局管理器（GameManager、SaveSystem、EventBus）

**实现方式**：通过 Godot Autoload 机制注册为全局单例，脚本中通过类名直接访问。

```gdscript
# scripts/core/game_manager.gd
extends Node

enum GameState { MENU, PLAYING, COMBAT, DIALOGUE, PAUSED }

var current_state: GameState = GameState.MENU
var player_data: Dictionary = {}

signal game_state_changed(new_state: GameState)

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

# 游戏状态信号
signal game_state_changed(old_state, new_state)
signal game_paused
signal game_resumed

# 玩家信号
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_level_up(new_level: int)
signal player_died

# 战斗信号
signal combat_started(enemies: Array)
signal combat_ended(victory: bool, rewards: Dictionary)
signal turn_started(character: Node)
signal skill_used(caster: Node, skill: SkillData, targets: Array)
signal damage_dealt(source: Node, target: Node, amount: float, type: String)

# 对话信号
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal dialogue_choice_made(choice_id: String)
signal story_flag_set(flag_name: String, value: Variant)

# 任务信号
signal quest_accepted(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_index: int, progress: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

# 经济信号
signal gold_changed(amount: int)
signal item_acquired(item_id: String, count: int)
signal item_removed(item_id: String, count: int)

# 声望信号
signal reputation_changed(faction_id: String, delta: int)

# 世界信号
signal zone_entered(zone_id: String)
signal zone_exited(zone_id: String)
signal npc_interacted(npc_id: String)
```

**使用规范**：

```gdscript
# 发送方：不需要知道谁在监听
EventBus.player_hp_changed.emit(current_hp, max_hp)

# 接收方：在 _ready 中连接信号
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
         ┌──────────┐
    ┌────│   MENU   │────┐
    │    └──────────┘    │
    │         │          │
    ▼         ▼          ▼
┌────────┐ ┌──────────┐ ┌──────────────────┐
│PAUSED  │ │ PLAYING  │ │CHARACTER_CREATION│
└────────┘ └────┬─────┘ └──────────────────┘
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

enum AIState { IDLE, PATROL, CHASE, FLEE, INTERACT, COMBAT }

var ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0

func _physics_process(delta: float) -> void:
    match ai_state:
        AIState.IDLE:    _process_idle(delta)
        AIState.PATROL:  _process_patrol(delta)
        AIState.CHASE:   _process_chase(delta)
        AIState.FLEE:    _process_flee(delta)
        AIState.INTERACT: _process_interact(delta)
        AIState.COMBAT:  _process_combat(delta)

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
```

#### 3.3.3 战斗角色状态

```
┌─────────┐  回合开始  ┌──────────┐  选择技能  ┌──────────┐
│ WAITING  │───────────│ READY    │───────────│ ACTING   │
└─────────┘           └──────────┘           └────┬─────┘
     ▲                                            │
     │              回合结束                       ▼
     │           ┌──────────┐              ┌──────────┐
     └───────────│ COOLDOWN │◄─────────────│ RESOLVING│
                 └──────────┘              └──────────┘
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
signal died

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
```

```gdscript
# scripts/entities/components/movement_component.gd
extends Node
class_name MovementComponent

@export var speed: float = 200.0
@export var sprint_multiplier: float = 1.5
var is_sprinting: bool = false

func get_velocity(direction: Vector2) -> Vector2:
    var multiplier := sprint_multiplier if is_sprinting else 1.0
    return direction.normalized() * speed * multiplier
```

**实体组合示例**：

```
Player (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── CombatComponent (Node)
├── InventoryComponent (Node)
├── SkillComponent (Node)
└── Sprite2D
    └── AnimationPlayer

NPC (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── DialogueComponent (Node)
├── AIComponent (Node)
└── Sprite2D
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
```

#### 3.5.2 JSON 数据加载

```gdscript
# scripts/core/game_manager.gd 中的数据加载方法
var skill_database: Dictionary = {}
var item_database: Dictionary = {}
var npc_database: Dictionary = {}

func load_data() -> void:
    skill_database = _load_json("res://data/skills.json")
    item_database = _load_json("res://data/items.json")
    npc_database = _load_json("res://data/npcs.json")

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
```

**设计要点**：
- JSON 文件由策划维护，代码无需修改即可调整游戏内容
- Resource 类提供类型安全的运行时数据访问
- 数据加载在游戏启动时一次性完成，运行时只读取不写入

---

## 4. 系统间通信

### 4.1 通信方式总览

| 通信方式 | 适用场景 | 耦合度 | 示例 |
|---------|---------|--------|------|
| **EventBus 信号** | 跨系统、跨场景通信 | 低 | 战斗结束 → 任务系统更新进度 |
| **直接方法调用** | 父子节点、同一系统内部 | 中 | CombatManager 调用 DamageCalculator |
| **Resource 数据共享** | 只读数据传递 | 低 | 多系统读取同一 SkillData |
| **GameManager 全局状态** | 需要全局访问的共享状态 | 中 | 当前玩家等级、当前场景 |

### 4.2 通信规则

#### 规则一：跨系统必须通过 EventBus

```gdscript
# ✅ 正确：战斗系统通知任务系统
EventBus.combat_ended.emit(true, rewards)

# ❌ 错误：战斗系统直接调用任务系统
QuestSystem.complete_objective("kill_boss")  # 禁止！
```

#### 规则二：系统内部可直接调用

```gdscript
# ✅ 正确：CombatManager 内部调用伤害计算
var damage := DamageCalculator.calculate(skill, attacker, defender)
```

#### 规则三：UI 只监听信号，不主动查询

```gdscript
# ✅ 正确：HUD 监听信号更新显示
func _ready() -> void:
    EventBus.player_hp_changed.connect(_on_hp_changed)

# ❌ 错误：UI 每帧查询玩家状态
func _process(_delta: float) -> void:
    hp_bar.value = GameManager.player.hp / GameManager.player.max_hp  # 禁止！
```

#### 规则四：禁止循环依赖

```
# ❌ 禁止的循环依赖
A → B → C → A

# ✅ 正确：通过 EventBus 解耦
A → EventBus ← C
B → EventBus
```

### 4.3 系统依赖关系图

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
    └────────────────────────────────────────────┘
```

### 4.4 典型通信流程

#### 场景一：玩家击杀敌人 → 任务进度更新

```
1. CombatManager 检测敌人死亡
2. CombatManager → EventBus.combat_ended.emit(true, rewards)
3. QuestSystem 监听 combat_ended 信号
4. QuestSystem 内部更新击杀计数
5. QuestSystem → EventBus.quest_objective_updated.emit(quest_id, idx, progress)
6. HUD 监听 quest_objective_updated 信号，更新任务追踪UI
```

#### 场景二：NPC 对话触发战斗

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

#### 场景三：完成任务获得门派声望

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

---

## 5. 战斗系统设计

### 5.1 战斗流程

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────┐
│ 战斗触发  │────►│ 初始化战斗 │────►│ 回合排序(速度) │────►│ 回合循环  │
└──────────┘     └──────────┘     └──────────────┘     └────┬─────┘
                                                               │
                     ┌─────────────────────────────────────────┘
                     ▼
              ┌──────────────┐
              │ 当前角色行动  │
              └──────┬───────┘
                     │
         ┌───────────┼───────────┐
         ▼           ▼           ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐
    │ 使用技能 │ │ 使用物品 │ │ 防御/逃跑│
    └────┬────┘ └────┬────┘ └────┬────┘
         │           │           │
         ▼           ▼           ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ 伤害计算  │ │ 物品效果  │ │ 防御/逃跑 │
    └────┬─────┘ └────┬─────┘ └────┬─────┘
         │            │            │
         └────────────┼────────────┘
                      ▼
              ┌──────────────┐
              │ 状态效果结算  │
              └──────┬───────┘
                     │
              ┌──────▼───────┐
              │ 检查战斗结束  │
              └──┬───────┬───┘
                 │       │
          继续   ▼       ▼  结束
          ┌──────────┐ ┌──────────┐
          │ 下一角色  │ │ 战斗结算  │
          └──────────┘ └──────────┘
```

### 5.2 回合排序 — 速度制

每个角色拥有速度属性（`speed`），每回合按速度从高到低依次行动。

```gdscript
# scripts/combat/combat_manager.gd
extends Node

var turn_order: Array[Node] = []
var current_turn_index: int = 0

func sort_by_speed(characters: Array[Node]) -> Array[Node]:
    characters.sort_custom(func(a, b): return a.speed > b.speed)
    return characters

func start_combat(enemies: Array) -> void:
    var all_combatants: Array[Node] = []
    all_combatants.append(_get_player_party())
    all_combatants.append_array(enemies)
    turn_order = sort_by_speed(all_combatants)
    current_turn_index = 0
    _start_next_turn()

func _start_next_turn() -> void:
    if current_turn_index >= turn_order.size():
        current_turn_index = 0
        _apply_status_effects()
        turn_order = sort_by_speed(turn_order.filter(func(c): return not c.is_dead))

    if _check_combat_end():
        return

    var current_character := turn_order[current_turn_index]
    EventBus.turn_started.emit(current_character)

    if current_character.is_player_controlled:
        _wait_for_player_input()
    else:
        _execute_ai_turn(current_character)

    current_turn_index += 1
```

### 5.3 技能系统

#### 5.3.1 技能数据结构

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
            {
                "type": "defense_up",
                "value": 0.5,
                "duration": 3
            }
        ],
        "faction_requirement": "shaolin",
        "level_requirement": 10,
        "animation": "golden_bell"
    }
}
```

#### 5.3.2 技能冷却管理

```gdscript
# scripts/combat/skill_system.gd
extends Node

var cooldown_tracker: Dictionary = {}

func use_skill(caster: Node, skill_id: String, targets: Array) -> void:
    var skill_data := GameManager.get_skill(skill_id)
    if not _can_use_skill(caster, skill_data):
        return

    _apply_mp_cost(caster, skill_data.mp_cost)
    _set_cooldown(caster, skill_id, skill_data.cooldown)

    for target in targets:
        var result := DamageCalculator.calculate(skill_data, caster, target)
        target.take_damage(result.damage, result.element)
        _apply_status_effects(target, skill_data.status_effects)

    EventBus.skill_used.emit(caster, skill_data, targets)

func _can_use_skill(caster: Node, skill_data: Dictionary) -> bool:
    if caster.current_mp < skill_data.mp_cost:
        return false
    var key := str(caster.get_instance_id()) + "_" + skill_data.id
    if cooldown_tracker.get(key, 0) > 0:
        return false
    if skill_data.faction_requirement != "" and caster.faction != skill_data.faction_requirement:
        return false
    if caster.level < skill_data.level_requirement:
        return false
    return true

func _set_cooldown(caster: Node, skill_id: String, turns: int) -> void:
    var key := str(caster.get_instance_id()) + "_" + skill_id
    cooldown_tracker[key] = turns

func tick_cooldowns() -> void:
    for key in cooldown_tracker:
        if cooldown_tracker[key] > 0:
            cooldown_tracker[key] -= 1
```

### 5.4 伤害计算

```gdscript
# scripts/combat/damage_calculator.gd
extends Node
class_name DamageCalculator

enum ElementType { PHYSICAL, FIRE, ICE, POISON, INTERNAL }

const ELEMENT_MULTIPLIERS := {
    "fire_vs_ice": 1.5,
    "ice_vs_fire": 0.5,
    "internal_vs_physical": 1.3,
    "physical_vs_internal": 0.8,
}

static func calculate(skill_data: Dictionary, attacker: Node, defender: Node) -> Dictionary:
    var base_damage: float = skill_data.base_damage
    var attack_stat: float = attacker.get_attack_stat(skill_data.element)
    var defense_stat: float = defender.get_defense_stat(skill_data.element)

    var element_multiplier := _get_element_multiplier(skill_data.element, defender.element)
    var level_diff_modifier := 1.0 + (attacker.level - defender.level) * 0.05
    var variance := randf_range(0.9, 1.1)

    var final_damage := base_damage * (attack_stat / (attack_stat + defense_stat)) \
                         * element_multiplier * level_diff_modifier * variance

    if defender.is_defending:
        final_damage *= 0.5

    final_damage = max(1.0, floorf(final_damage))

    return {
        "damage": final_damage,
        "element": skill_data.element,
        "is_critical": randf() < attacker.critical_rate,
        "is_effective": element_multiplier > 1.0,
    }

static func _get_element_multiplier(attack_element: String, defender_element: String) -> float:
    var key := attack_element + "_vs_" + defender_element
    return ELEMENT_MULTIPLIERS.get(key, 1.0)
```

### 5.5 状态效果系统

```gdscript
# 状态效果类型定义
enum StatusType {
    POISON,       # 中毒 — 每回合扣除百分比生命
    BLEED,        # 流血 — 每回合扣除固定生命
    STUN,         # 眩晕 — 跳过回合
    BURN,         # 灼烧 — 每回合伤害，降低攻击
    FREEZE,       # 冰冻 — 跳过回合，受到攻击解除
    DEFENSE_UP,   # 防御提升
    DEFENSE_DOWN, # 防御降低
    ATTACK_UP,    # 攻击提升
    ATTACK_DOWN,  # 攻击降低
    SPEED_UP,     # 速度提升
    SPEED_DOWN,   # 速度降低
    REGENERATE,   # 回复 — 每回合回复生命
}

# 状态效果数据结构
class StatusEffect:
    var type: StatusType
    var value: float
    var duration: int       # 剩余回合数
    var source_id: String   # 施加者ID

    func tick() -> Dictionary:
        duration -= 1
        var result := {"type": type, "value": 0.0, "expired": duration <= 0}

        match type:
            StatusType.POISON:
                result.value = value  # 百分比伤害
            StatusType.BLEED:
                result.value = value  # 固定伤害
            StatusType.REGENERATE:
                result.value = -value # 负值表示回复
            StatusType.STUN, StatusType.FREEZE:
                result.value = 0.0

        return result
```

### 5.6 门派终极技能

每个门派拥有独特的终极技能，需要满足特定条件才能释放：

| 门派 | 终极技能 | 效果 | 释放条件 |
|------|---------|------|---------|
| 少林 | 金刚伏魔阵 | 对全体敌人造成大量内功伤害，自身获得3回合防御提升 | 内力 ≥ 80，生命 ≤ 30% |
| 武当 | 太极乾坤 | 反弹所有伤害2回合，回复30%内力 | 内力 ≥ 60，处于防御状态 |
| 峨眉 | 峨眉九阳功 | 回复全体队友50%生命，清除所有负面状态 | 内力 ≥ 70，有队友处于负面状态 |
| 丐帮 | 降龙十八掌 | 对单体造成巨额伤害，无视防御 | 内力 ≥ 90，连击3次后 |
| 唐门 | 暴雨梨花针 | 对全体敌人造成伤害并附加中毒3回合 | 内力 ≥ 50，目标 ≥ 2 |

```gdscript
# scripts/combat/skill_system.gd 中的终极技能检查
func can_use_ultimate(caster: Node, ultimate_id: String) -> bool:
    var ultimate := GameManager.get_skill(ultimate_id)
    match caster.faction:
        "shaolin":
            return caster.current_mp >= 80 and caster.hp_ratio <= 0.3
        "wudang":
            return caster.current_mp >= 60 and caster.is_defending
        "emei":
            return caster.current_mp >= 70 and _has_ally_with_debuff(caster)
        "gaibang":
            return caster.current_mp >= 90 and caster.consecutive_hits >= 3
        "tangmen":
            return caster.current_mp >= 50 and _count_living_enemies() >= 2
    return false
```

---

## 6. 对话系统设计

### 6.1 对话数据结构

对话系统采用 JSON 定义的树形结构，每个节点包含文本、选项和跳转逻辑。

```json
{
    "dialogue_001": {
        "npc_id": "npc_zhang_san",
        "npc_name": "张三",
        "nodes": {
            "start": {
                "text": "少侠，你来得正好！近日黑风寨的贼人愈发猖狂，你可愿意助我一臂之力？",
                "speaker": "npc",
                "next": "choice_1"
            },
            "choice_1": {
                "type": "choice",
                "text": "",
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
                "text": "好！少侠果然侠义心肠！这是黑风寨的地形图，请务必小心。",
                "speaker": "npc",
                "effects": [
                    {"type": "quest", "action": "accept", "quest_id": "quest_black_wind"},
                    {"type": "item", "action": "add", "item_id": "item_map_black_wind"},
                    {"type": "flag", "flag": "quest_black_wind_accepted", "value": true}
                ],
                "next": "end"
            },
            "consider": {
                "text": "也罢，少侠想清楚了再来找我便是。",
                "speaker": "npc",
                "next": "end"
            },
            "refuse": {
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

### 6.2 对话解析器

```gdscript
# scripts/dialogue/dialogue_parser.gd
extends Node
class_name DialogueParser

func parse_dialogue(json_data: Dictionary) -> DialogueTree:
    var tree := DialogueTree.new()
    tree.dialogue_id = json_data.get("dialogue_id", "")
    tree.npc_id = json_data.get("npc_id", "")
    tree.npc_name = json_data.get("npc_name", "")

    var nodes_data: Dictionary = json_data.get("nodes", {})
    for node_id in nodes_data:
        var node := _parse_node(node_id, nodes_data[node_id])
        tree.nodes[node_id] = node

    tree.start_node_id = "start"
    return tree

func _parse_node(node_id: String, data: Dictionary) -> DialogueNode:
    var node := DialogueNode.new()
    node.id = node_id
    node.type = data.get("type", "text")
    node.text = data.get("text", "")
    node.speaker = data.get("speaker", "npc")
    node.next_id = data.get("next", "")

    if data.has("options"):
        for opt_data in data.options:
            var option := _parse_option(opt_data)
            node.options.append(option)

    if data.has("effects"):
        for eff_data in data.effects:
            var effect := _parse_effect(eff_data)
            node.effects.append(effect)

    if data.has("conditions"):
        for cond_data in data.conditions:
            var condition := _parse_condition(cond_data)
            node.conditions.append(condition)

    return node

func _parse_option(data: Dictionary) -> DialogueOption:
    var option := DialogueOption.new()
    option.text = data.get("text", "")
    option.next_id = data.get("next", "")
    option.conditions = []
    option.effects = []

    if data.has("conditions"):
        for cond_data in data.conditions:
            option.conditions.append(_parse_condition(cond_data))
    if data.has("effects"):
        for eff_data in data.effects:
            option.effects.append(_parse_effect(eff_data))

    return option

func _parse_condition(data: Dictionary) -> DialogueCondition:
    var condition := DialogueCondition.new()
    condition.type = data.get("type", "")
    condition.params = data
    return condition

func _parse_effect(data: Dictionary) -> DialogueEffect:
    var effect := DialogueEffect.new()
    effect.type = data.get("type", "")
    effect.params = data
    return effect
```

### 6.3 条件分支系统

```gdscript
# scripts/dialogue/dialogue_manager.gd 中的条件评估
func evaluate_conditions(conditions: Array) -> bool:
    for condition in conditions:
        match condition.type:
            "flag":
                var flag_value := GameManager.get_story_flag(condition.params.get("flag", ""))
                if flag_value != condition.params.get("value", false):
                    return false
            "level":
                var player_level := GameManager.player_level
                if player_level < condition.params.get("min", 0):
                    return false
                if player_level > condition.params.get("max", 9999):
                    return false
            "faction":
                var player_faction := FactionSystem.get_player_faction()
                if player_faction != condition.params.get("faction", ""):
                    return false
            "reputation":
                var rep := ReputationSystem.get_reputation(condition.params.get("faction", ""))
                if rep < condition.params.get("min", 0):
                    return false
            "quest_state":
                var state := QuestSystem.get_quest_state(condition.params.get("quest_id", ""))
                if state != condition.params.get("state", ""):
                    return false
            "item":
                var has_item := GameManager.has_item(condition.params.get("item_id", ""))
                if has_item != condition.params.get("has", true):
                    return false
    return true
```

### 6.4 对话效果执行

```gdscript
# scripts/dialogue/dialogue_manager.gd 中的效果执行
func execute_effects(effects: Array) -> void:
    for effect in effects:
        match effect.type:
            "flag":
                GameManager.set_story_flag(effect.params.flag, effect.params.value)
                EventBus.story_flag_set.emit(effect.params.flag, effect.params.value)
            "quest":
                match effect.params.action:
                    "accept":
                        QuestSystem.accept_quest(effect.params.quest_id)
                    "complete":
                        QuestSystem.complete_quest(effect.params.quest_id)
                    "fail":
                        QuestSystem.fail_quest(effect.params.quest_id)
            "item":
                match effect.params.action:
                    "add":
                        GameManager.add_item(effect.params.item_id, effect.params.get("count", 1))
                    "remove":
                        GameManager.remove_item(effect.params.item_id, effect.params.get("count", 1))
            "reputation":
                ReputationSystem.change_reputation(effect.params.faction, effect.params.delta)
            "combat":
                EventBus.combat_started.emit(effect.params.enemies)
            "teleport":
                GameManager.teleport_player(effect.params.zone_id, effect.params.spawn_point)
            "skill":
                GameManager.unlock_skill(effect.params.skill_id)
```

### 6.5 故事引擎

```gdscript
# scripts/dialogue/story_engine.gd
extends Node

var story_flags: Dictionary = {}
var active_storylines: Array[String] = []

func set_flag(flag_name: String, value: Variant) -> void:
    story_flags[flag_name] = value
    _check_story_triggers(flag_name)

func get_flag(flag_name: String) -> Variant:
    return story_flags.get(flag_name, false)

func _check_story_triggers(flag_name: String) -> void:
    match flag_name:
        "met_zhang_san":
            if get_flag("met_zhang_san") and get_flag("explored_black_wind"):
                _trigger_storyline("black_wind_investigation")
        "black_wind_cleared":
            _trigger_storyline("shaolin_invitation")
            QuestSystem.unlock_quest("quest_shaolin_trial")
        "shaolin_trial_passed":
            _trigger_storyline("wudang_rivalry")
            FactionSystem.unlock_faction_perk("shaolin", "iron_body")

func _trigger_storyline(storyline_id: String) -> void:
    if storyline_id in active_storylines:
        return
    active_storylines.append(storyline_id)
    EventBus.story_flag_set.emit("storyline_" + storyline_id, true)
```

---

## 7. 存档系统设计

### 7.1 存档数据结构

```gdscript
# scripts/core/save_system.gd
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const MAX_SAVE_SLOTS := 10

class SaveData:
    var save_version: int = 1
    var timestamp: Dictionary = {}
    var play_time: float = 0.0
    var player_data: Dictionary = {}
    var world_data: Dictionary = {}
    var story_data: Dictionary = {}
    var quest_data: Dictionary = {}
    var npc_data: Dictionary = {}
    var economy_data: Dictionary = {}
    var reputation_data: Dictionary = {}

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

    var file_path := SAVE_DIR + "slot_%02d%s" % [slot, SAVE_EXTENSION]
    var file := FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        push_error("存档写入失败: " + file_path)
        return false

    var json_string := JSON.stringify(_save_data_to_dict(save_data), "\t")
    file.store_string(json_string)
    file.close()
    return true
```

### 7.2 各模块存档数据

#### 7.2.1 玩家数据

```gdscript
func _collect_player_data() -> Dictionary:
    return {
        "name": GameManager.player_name,
        "level": GameManager.player_level,
        "experience": GameManager.player_experience,
        "faction": FactionSystem.get_player_faction(),
        "position": {
            "zone_id": ZoneManager.current_zone_id,
            "x": GameManager.player_position.x,
            "y": GameManager.player_position.y,
        },
        "stats": {
            "hp": GameManager.player_current_hp,
            "max_hp": GameManager.player_max_hp,
            "mp": GameManager.player_current_mp,
            "max_mp": GameManager.player_max_mp,
            "attack": GameManager.player_attack,
            "defense": GameManager.player_defense,
            "speed": GameManager.player_speed,
            "critical_rate": GameManager.player_critical_rate,
        },
        "inventory": GameManager.player_inventory.serialize(),
        "equipment": GameManager.player_equipment.serialize(),
        "skills": GameManager.player_skills.serialize(),
        "cultivation_level": CultivationSystem.get_cultivation_level(),
    }
```

#### 7.2.2 世界数据

```gdscript
func _collect_world_data() -> Dictionary:
    return {
        "current_zone": ZoneManager.current_zone_id,
        "visited_zones": ZoneManager.visited_zones,
        "unlocked_zones": ZoneManager.unlocked_zones,
        "zone_states": ZoneManager.get_all_zone_states(),
        "world_events": WorldMap.get_active_events(),
    }
```

#### 7.2.3 故事数据

```gdscript
func _collect_story_data() -> Dictionary:
    return {
        "story_flags": StoryEngine.story_flags,
        "active_storylines": StoryEngine.active_storylines,
        "completed_storylines": StoryEngine.completed_storylines,
        "dialogue_history": DialogueManager.dialogue_history,
    }
```

#### 7.2.4 任务数据

```gdscript
func _collect_quest_data() -> Dictionary:
    return {
        "active_quests": QuestSystem.get_active_quests_data(),
        "completed_quests": QuestSystem.completed_quests,
        "failed_quests": QuestSystem.failed_quests,
        "quest_objectives": QuestSystem.get_all_objectives_progress(),
    }
```

#### 7.2.5 NPC 数据

```gdscript
func _collect_npc_data() -> Dictionary:
    return {
        "npc_states": ZoneManager.get_all_npc_states(),
        "npc_relationships": NPCManager.get_all_relationships(),
        "killed_npcs": CombatManager.killed_npcs,
        "recruited_npcs": NPCManager.recruited_npcs,
    }
```

### 7.3 存档加载

```gdscript
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
    var save_data := _dict_to_save_data(save_dict)

    _restore_player_data(save_data.player_data)
    _restore_world_data(save_data.world_data)
    _restore_story_data(save_data.story_data)
    _restore_quest_data(save_data.quest_data)
    _restore_npc_data(save_data.npc_data)
    _restore_economy_data(save_data.economy_data)
    _restore_reputation_data(save_data.reputation_data)

    GameManager.play_time = save_data.play_time
    GameManager.change_state(GameManager.GameState.PLAYING)
    return true
```

### 7.4 存档安全

| 措施 | 说明 |
|------|------|
| **版本号检查** | 存档包含 `save_version`，加载时校验兼容性 |
| **数据校验** | 加载后验证关键字段存在性和类型正确性 |
| **原子写入** | 先写入临时文件，成功后重命名，防止写入中断导致存档损坏 |
| **多槽位** | 支持10个存档槽位，降低误覆盖风险 |
| **自动存档** | 每次场景切换自动保存到独立槽位 |

```gdscript
func save_game_atomic(slot: int) -> bool:
    var temp_path := SAVE_DIR + "slot_%02d.tmp" % slot
    var final_path := SAVE_DIR + "slot_%02d%s" % [slot, SAVE_EXTENSION]

    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return false

    var json_string := JSON.stringify(_save_data_to_dict(_build_save_data()), "\t")
    file.store_string(json_string)
    file.close()

    if FileAccess.file_exists(final_path):
        DirAccess.remove_absolute(final_path)
    DirAccess.rename_absolute(temp_path, final_path)
    return true
```

---

## 8. 附录：关键类接口定义

### 8.1 GameManager

```gdscript
class_name GameManager

enum GameState { MENU, PLAYING, COMBAT, DIALOGUE, PAUSED }

func change_state(new_state: GameState) -> void
func get_story_flag(flag_name: String) -> Variant
func set_story_flag(flag_name: String, value: Variant) -> void
func has_item(item_id: String) -> bool
func add_item(item_id: String, count: int) -> void
func remove_item(item_id: String, count: int) -> void
func unlock_skill(skill_id: String) -> void
func teleport_player(zone_id: String, spawn_point: String) -> void
func load_data() -> void
func get_skill(skill_id: String) -> Dictionary
func get_item(item_id: String) -> Dictionary
```

### 8.2 EventBus

```gdscript
class_name EventBus

# 信号列表（见 3.2 节）
# 使用规范：
# - 发送方：EventBus.signal_name.emit(args)
# - 接收方：EventBus.signal_name.connect(callback)
# - 禁止在回调中 emit 同名信号
```

### 8.3 CombatManager

```gdscript
class_name CombatManager

func start_combat(enemies: Array) -> void
func end_combat(victory: bool) -> void
func use_skill(caster: Node, skill_id: String, targets: Array) -> void
func use_item(user: Node, item_id: String, targets: Array) -> void
func defend(character: Node) -> void
func flee(character: Node) -> bool
func get_turn_order() -> Array[Node]
func apply_status_effects() -> void
```

### 8.4 DialogueManager

```gdscript
class_name DialogueManager

func start_dialogue(dialogue_id: String) -> void
func advance() -> void
func choose_option(option_index: int) -> void
func end_dialogue() -> void
func evaluate_conditions(conditions: Array) -> bool
func execute_effects(effects: Array) -> void
```

### 8.5 SaveSystem

```gdscript
class_name SaveSystem

func save_game(slot: int) -> bool
func load_game(slot: int) -> bool
func delete_save(slot: int) -> bool
func get_save_info(slot: int) -> Dictionary
func has_save(slot: int) -> bool
func get_all_saves() -> Array[Dictionary]
```

### 8.6 QuestSystem

```gdscript
class_name QuestSystem

func accept_quest(quest_id: String) -> void
func complete_quest(quest_id: String) -> void
func fail_quest(quest_id: String) -> void
func unlock_quest(quest_id: String) -> void
func get_quest_state(quest_id: String) -> String
func get_active_quests() -> Array[String]
func update_objective(quest_id: String, objective_index: int, progress: int) -> void
```

### 8.7 FactionSystem

```gdscript
class_name FactionSystem

func get_player_faction() -> String
func join_faction(faction_id: String) -> bool
func leave_faction() -> void
func get_faction_perks(faction_id: String) -> Array
func unlock_faction_perk(faction_id: String, perk_id: String) -> void
func get_faction_skills(faction_id: String) -> Array[String]
```

### 8.8 ReputationSystem

```gdscript
class_name ReputationSystem

func get_reputation(faction_id: String) -> int
func change_reputation(faction_id: String, delta: int) -> void
func get_reputation_rank(faction_id: String) -> String
func is_hostile(faction_id: String) -> bool
func is_friendly(faction_id: String) -> bool
```

---

> **文档维护说明**：本文档应随项目迭代持续更新。任何架构变更需经团队评审后同步修改本文档，确保文档与代码保持一致。
