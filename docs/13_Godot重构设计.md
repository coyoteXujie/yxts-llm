# 白金英雄坛说 - Godot 重构设计

> 目标：以 Godot 4 工程作为后续主线实现。旧 pygame/Python 原型已完成迁移和清理，不再作为运行时依赖。

## 1. 工程边界

- `Godot_v4/`：本机 Godot 引擎目录，只放可执行文件，不放游戏代码。
- `godot_project/`：Godot 游戏工程，可直接用 Godot 打开。
- `docs/`：设计文档、实现差距审计和后续规划。
- `tools/`：当前 Godot 数据校验与美术资源生成工具。

## 2. 当前竖切目标

第一版不追求一次迁完全部系统，而是先做一个可玩的 Alpha 主循环：

1. 按 `docs/02_map_design.md` 压缩实现的世界大地图探索。
2. 玩家 WASD/方向键移动，镜头跟随。
3. NPC 和敌人由 JSON 数据生成，当前 Godot 数据已扩展到 99 个 NPC，并重排到五城、七派、野外区域。
4. `T` 交谈、向师父请教武学。
5. `F` 挑战敌人，进入简化回合战斗。
6. HUD 显示气血、内力、等级、银两和当前目标。
7. 主菜单、角色创建、任务日志、背包、商店、修炼、世界地图、存档读档。
8. 平安镇任务链到“英雄试炼”的阶段通关目标，并接入“洛阳旧火/暗影书信/七派风声”的主线开端。

这条竖切已包含背包、商店、任务、门派修炼、区域探索、带 NPC/任务标记的世界地图面板、存档读档和基础 NPC/地图/物品/UI 美术资源。后续重点转向更完整的门派剧情、战斗招式和 LLM 对话。

## 3. 目录结构

```text
godot_project/
├── project.godot
├── scenes/
│   └── main.tscn
├── data/
│   ├── npcs.json
│   ├── items.json
│   ├── quests.json
│   ├── npc_sprite_assets.json
│   ├── npc_portrait_assets.json
│   ├── item_icon_assets.json
│   ├── skill_icon_assets.json
│   ├── scene_background_assets.json
│   └── regions.json
├── assets/
│   ├── characters/
│   │   ├── generated_map_sprites/
│   │   ├── npc/portraits/
│   │   ├── player/
│   │   └── parts/
│   ├── items/icons/
│   ├── skills/icons/
│   ├── world/
│   │   ├── tiles/
│   │   └── scenes/
│   └── ui/
└── scripts/
    ├── autoload/
    │   ├── event_bus.gd
    │   ├── game_data.gd
    │   └── game_state.gd
    ├── entities/
    │   ├── player.gd
    │   └── npc.gd
    ├── systems/
    │   └── combat_system.gd
    ├── ui/
    │   ├── hud.gd
    │   ├── dialogue_panel.gd
    │   └── combat_panel.gd
    ├── world/
    │   ├── world_map.gd
    │   └── local_area_map.gd
    └── main.gd
```

## 4. 系统拆分

- `GameData`：加载 JSON、门派名、技能名、NPC 台词、区域数据等静态数据。
- `GameState`：保存玩家数值、当前模式、已学技能、当前目标和区域探索度。
- `EventBus`：跨系统信号，避免 UI、地图、战斗互相硬耦合。
- `WorldMap`：按地图文档程序化生成世界大图、处理可通行判定、NPC 生成和就近交互查询。
- `LocalAreaMap`：承接世界地图进入后的城镇/门派/野外局部地图和商铺内景，负责区域内商铺入口、可互动地标/资源点、相邻区域路牌、返回世界入口、局部 NPC 摆放、地貌差异化布局和内景碰撞。
- `DiscoveryPanel`：展示地标、资源点和后续奇遇事件的标题、所在地、正文和奖励列表，替代只靠 toast 承载探索反馈。
- `AtmosphereLayer`：承接昼夜、天气、危险度和区域地貌氛围，已按水乡、城市、城镇、山地、花林、荒漠、温泉、雪山、七派气场等主题绘制动态叠层。
- `regions.json`：记录 73 个区域的 ID、名称、类型、压缩世界坐标、危险等级和描述。
- `PlayerActor` / `NpcActor`：只负责表现、移动和自身数据引用；地图角色优先使用生成后的透明 PNG，未命中资源映射时再回退到拆件绘制。
- `CombatSystem`：独立战斗状态机，后续可替换为完整门派招式系统。
- `HudView` / `DialoguePanel` / `CombatPanel`：UI 单独维护，不混进地图逻辑。

## 5. 后续建设顺序

1. 继续整理 `godot_project/data/`，让 NPC、区域、任务、物品和资源映射保持单一来源。
2. 扩展 `systems/combat_system.gd`，补齐门派招式、状态效果、日志和战斗表现。
3. 逐步拆出 `inventory_system.gd`、`quest_system.gd`、`cultivation_system.gd`，每个系统只暴露少量公共方法。
4. 地图从当前程序化绘制逐步替换为 TileMapLayer 和正式 TileSet。
5. 美术资产稳定后再继续推进水墨后处理、天气、昼夜、粒子和技能特效。

## 6. 设计原则

- Godot 工程内数据以 JSON/TRES 为单一来源，避免把 Python 代码当运行时依赖。
- 场景负责节点组织，系统脚本负责规则，UI 脚本负责展示。
- 每次只迁移一条完整玩家体验，不按文件机械翻译。
- 原型可先用程序化图形，等玩法稳定后再换正式素材。
- 关键探索链路使用 `res://tests/playtest_smoke.tscn` 和 `res://tests/playtest_flow.tscn` 做自动游玩测试：前者覆盖世界地图、局部地图、商铺内景、NPC 分布、碰撞、相邻区域入口、可互动地标和 2.5D 遮挡层基础检查；后者实例化主场景，自动跑新游戏、进入平安镇、探索地标、进入商铺、与掌柜对话、打开交易、购买商品、出门、通过相邻区域路牌转场并返回世界地图。

## 6.1 当前地图落地

- 地图尺寸：`96 x 72` tile，使用 `GameData.MAP_WIDTH/MAP_HEIGHT` 管理。
- 世界结构参考 `docs/02_map_design.md`：5 城、16 镇、45 野外、7 门派压缩到一张连续可走地图。
- 已实装地貌：官道、街市、商铺、城池、乡村、田地、山脉、雪山、森林、竹海、荒漠、沼泽、水乡、河流、湖泊、桥。
- 已实装地标标签：平安镇、洛阳、长安、成都、江陵、临安、八卦门、雪山派、红莲教、太极门、那迦派、花间派、逍遥宫等。
- 已实装区域识别：`data/regions.json` 登记 73 个区域，玩家移动时更新当前区域、探索度和危险等级。
- 已实装世界层 NPC 分层：大地图只显示敌人、野外/门派关键人物，并缩小世界层 sprite；城镇生活类 NPC 在进入对应局部地图后按区域坐标重排生成。
- 已实装世界地图面板：`M` 键打开，显示区域示意图、已发现区域、区域说明、NPC 标记、可接任务标记和当前任务目标。
- 已实装第一版转入转出：世界地图按 `E` 进入城池、城镇、门派、野外局部地图；局部地图中可进入客栈、药铺、铁匠铺、布庄、市集、茶肆等商铺内景，并可从内景返回区域街道、从区域返回世界地图，或通过相邻区域路牌直接转场到附近城池、城镇、野外和门派。
- 已实装第一批可互动地标/资源点：城池按地区特色生成旧宅、榜亭、码头、药市、战鼓台等；城镇、门派和野外按地形生成告示、练武场、山洞、药坡、浅滩、古碑等入口，首次探索通过发现面板展示正文和奖励，可获得少量物品、银两或阅历，并写入 `GameState.game_flags` 防止重复领取。
- 平安镇作为起始镇落在北洛阳区域，新手镇 NPC、洛阳主线 NPC、镇东敌人与门派 NPC 已分层摆放，避免开局人群全部堆在洛阳中心。

## 6.2 当前剧情与核心角色落地

- 已加入第一批文档核心 NPC：苏梦瑶、陈天行、赵无极、玄机子、花如玉、烈火、蛇王、太极真人、冰魄、逍遥子。
- 已加入主线开端任务：`q_main_luoyang_ashes`、`q_main_shadow_letters`、`q_main_sect_warnings`。
- 这些任务先承担“把玩家带到五城与七派”的作用，后续再扩展选择、分支后果、NPC 好感与暗影司主线。

## 7. 当前美术落地

- `tools/generate_godot_art_assets.py` 生成第一批 Godot 可直接使用的 2D 美术资源：20 张地图瓦片、99 张 NPC 地图 sprite、41 张参考级 NPC archetype、99 张 NPC 对话头像、16 张玩家门派/性别 sprite、45 张角色拆件 PNG、22 张物品图标、41 张武学图标、73 张区域场景背景、8 张 UI 资源。
- `godot_project/assets/world/tiles/` 保存当前世界地图和局部地图实际使用的 48x48 瓦片 PNG；道路、水面、建筑、商铺、桥、竹林、山体等瓦片已强化为更接近国风仙侠地图的表现。
- `WorldMap` 已加入第一版伪 2.5D 表现：地貌边缘过渡、建筑/门派/山体高度叠层、`MapProp` 遮挡节点、世界层角色缩放和较远镜头，后续再逐步替换为正式 TileMapLayer/TileSet。
- `LocalAreaMap` 已从单一十字路模板推进到分类型布局：五城会生成多层街巷和街区，镇子会生成村舍、田地和中心空场，野外按水系/山地/林地/荒漠/平原生成河道、桥、山脊、林坡和驿亭，门派按七派气质生成庭院、水榭、雪岭、碑场或旗幡空间。
- `MapProp` 已补井、石灯、小船、旗幡、花树、石堆、碑龛等程序化 2.5D 道具，并由局部地图按地貌自动摆放。
- `AtmosphereLayer` 已加入地域主题动态氛围：临安/江陵水系有雾带与水光，城池/镇子有灯晕和市集微光，山地有云带，花间/花田有花瓣，荒漠有风沙，雪山有寒光，各门派有对应气场。
- `LocalAreaMap` 在瓦片之上叠加局部环境层：水岸/道路边缘、连续屋檐、城墙轮廓、灯笼点缀、商铺招牌、商铺内景陈设和可遮挡树冠/屋檐层，避免局部城镇继续呈现纯色方格块。
- `godot_project/assets/world/scenes/` 保存 73 个区域的 640x360 场景背景占位图，当前已接入世界地图区域详情，用于后续切场景或对话背景。
- `godot_project/assets/characters/reference_map_sprites/` 保存当前大地图优先使用的 41 个高精度水墨 Q 版 NPC archetype，由参考图抠图后转为透明 PNG。
- `godot_project/assets/characters/generated_map_sprites/` 保存组件化生成的 99 个 NPC sprite，作为参考级资源未覆盖时的回退资源。
- `godot_project/assets/characters/npc/portraits/` 保存当前对话面板实际使用的 99 个 NPC 头像。
- `godot_project/assets/characters/player/` 保存玩家不同门派/性别 sprite。
- `godot_project/assets/characters/parts/` 保存头部、发型/帽子、服饰、道具等 45 个拆件源资源，生成 NPC sprite 时按组件组合。
- `godot_project/assets/items/icons/` 保存当前 22 个物品的 64x64 图标，当前已接入背包和商店。
- `godot_project/assets/skills/icons/` 保存当前 41 个武学的 64x64 图标，当前已接入修炼面板和战斗按钮。
- `godot_project/assets/ui/` 保存面板、按钮、物品槽、气血/内力条、NPC/任务/目标标记等基础 UI PNG，当前地图标记已接入世界地图面板。
- `godot_project/data/npc_sprite_assets.json` 管理 99 个 NPC 到当前地图 sprite 的映射。
- `godot_project/data/npc_portrait_assets.json` 管理 99 个 NPC 到对话头像的映射。
- `godot_project/data/item_icon_assets.json` 管理 22 个物品到图标的映射。
- `godot_project/data/skill_icon_assets.json` 管理 41 个武学到图标的映射。
- `godot_project/data/scene_background_assets.json` 管理 73 个区域到场景背景的映射。
- 旧的 `godot_project/assets/characters/npc/atlases/`、`sprites/` 和 prompt 源已清理，避免与当前统一风格 NPC 资源混用。
- 地图 NPC 与玩家优先使用生成后的透明 PNG；姓名标签只在靠近/选中时显示；对话面板已接入 NPC 头像；背包/商店已接入物品图标；修炼/战斗已接入武学图标；世界地图已接入区域背景和标记资源。
- 当前生成资源是可运行的统一风格占位资产，不等同于最终 900+ 高精度立绘、战斗姿态、技能特效和正式 TileSet。
- `docs/12_美术资产Prompt.md` 记录 NPC 拆件规范和当前资源状态。
