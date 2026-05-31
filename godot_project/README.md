# 白金英雄坛说 Godot

这是 Godot 4 版本的主工程。`Godot_v4/` 只作为本地引擎目录，游戏代码放在本目录。

## 运行

在仓库根目录执行：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --path godot_project
```

打开编辑器：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --editor --path godot_project
```

自动游玩 smoke test：

```bash
env HOME=/tmp/godot_home XDG_DATA_HOME=/tmp/godot_data XDG_CONFIG_HOME=/tmp/godot_config XDG_CACHE_HOME=/tmp/godot_cache \
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --headless --path godot_project --scene res://tests/playtest_smoke.tscn
```

## 当前玩法竖切

- 主菜单、角色创建、读档入口。
- WASD / 方向键：移动。
- T / Enter：与附近 NPC 交谈。
- E：进入当前城镇/门派/野外局部地图；在局部地图中进入商铺、出门或返回世界地图。
- F：挑战附近敌人。
- B：背包，使用药品或装备武器/防具。
- J：任务日志。
- K：修炼面板。
- M：世界地图。
- F5 / F9：快速存档 / 读档。
- Esc：关闭当前面板 / 打开主菜单。
- 对话面板支持闲谈、请教、任务、交易、拜师、住店。
- 战斗面板支持普通攻击、基本拳脚、调息和脱身。
- 当前有平安镇任务链、镇东敌人、采花大盗、阶段通关试炼，以及“洛阳旧火/暗影书信/七派风声”的主线开端。
- 当前 Godot 数据已扩展到 99 个 NPC：镇民/商人、四个已实装门派、红莲教、那迦派、雪山与镇外敌人，并加入苏梦瑶、陈天行、赵无极、玄机子、花如玉、烈火、蛇王、太极真人、冰魄、逍遥子等文档核心角色。
- 大地图按 `docs/02_map_design.md` 的 73 区域结构做了压缩版实现：五大城池、七大门派、主要城镇、黄河/长江/岷江/汉江、水乡湖泊、秦岭/雪山/山林/竹海/荒漠/乡村田地都在同一张可探索地图上。
- 已加入第一版转入转出流程：世界地图可进入城池、城镇、门派、野外的局部地图；局部地图内可进入客栈、药铺、铁匠铺、布庄、市集、茶肆等商铺内景，商铺掌柜沿用 NPC 交易/住店系统。
- 平安镇已作为起始镇落到大地图北洛阳区域；世界地图只显示敌人、野外/门派关键人物，城镇掌柜、村民、夫子、村长等会在进入局部地图后生成，避免世界层 NPC 堆在同一个城镇中心。
- `data/regions.json` 已登记 73 个结构化区域，玩家移动时会识别当前区域并记录探索度；HUD 会显示所在地、探索度和危险等级。
- M 键可打开世界地图面板，查看已发现区域、探索度、区域说明、区域背景图、NPC 标记、可接任务标记和当前任务目标。
- HUD 右上角有常驻小地图，显示当前区域、探索进度、玩家位置、任务目标和已标记目的地。
- `tools/generate_godot_art_assets.py` 已生成并接入第一批游戏内美术资源：20 张 48x48 地图瓦片、99 张 NPC 地图 sprite、41 张参考级 NPC archetype、99 张 NPC 对话头像、16 张玩家门派/性别 sprite、45 张角色拆件 PNG、22 张物品图标、41 张武学图标、73 张区域场景背景、8 张 UI 资源。
- 世界地图和局部地图现在都优先使用 `assets/world/tiles/` 的瓦片 PNG；局部地图额外叠加水岸、道路边缘、连续屋檐、城墙/灯笼、商铺招牌和室内陈设层，减少纯色方格感。
- 世界地图和局部地图加入第一版伪 2.5D 表现：地貌边缘过渡、`MapProp` 遮挡节点、建筑/门派/山体/树冠高度叠层、脚底 Y 轴排序、较远世界镜头和世界层 NPC 缩放。
- NPC 优先使用 `assets/characters/reference_map_sprites/` 的水墨 Q 版参考级透明 PNG，未覆盖时回退到组件化生成 sprite；姓名只在靠近/选中时显示，避免标签和角色互相遮挡。
- 对话面板已接入 `assets/characters/npc/portraits/` 的 NPC 头像；背包和商店已接入 `assets/items/icons/` 的物品图标；修炼和战斗面板已接入 `assets/skills/icons/` 的武学图标；世界地图面板已接入 `assets/world/scenes/` 的区域背景和 `assets/ui/` 的地图标记。
- 切换区域时会出现区域横幅，提示区域类型、危险等级和探索度。
- 战斗面板会显示敌人头像，并按玩家已学的攻击类武学生成可点击招式按钮。
- `assets/previews/` 下有瓦片、NPC、玩家、头像、物品图标、武学图标和场景背景资源预览图；旧 NPC 图集和切片源已清理，当前运行资源统一使用生成后的地图 sprite 和对话头像。

## 目录

- `scenes/main.tscn`：入口场景。
- `scripts/autoload/`：全局数据、状态和事件总线。
- `scripts/world/`：文档驱动的大地图、局部区域地图、商铺内景、可通行判定和 NPC 生成。
- `scripts/entities/`：玩家和 NPC 节点。
- `scripts/systems/`：战斗等规则系统。
- `scripts/ui/`：HUD、菜单、角色创建、对话、背包、任务、商店、修炼、世界地图和战斗面板。
- `data/npcs.json`：当前 Godot 版本使用的 NPC 数据。
- `data/npc_sprite_assets.json`：99 个 NPC 名称到当前地图 PNG sprite 的映射。
- `data/npc_portrait_assets.json`：99 个 NPC 名称到对话头像 PNG 的映射。
- `data/item_icon_assets.json`：22 个物品 ID 到图标 PNG 的映射。
- `data/skill_icon_assets.json`：41 个武学 ID 到图标 PNG 的映射。
- `data/scene_background_assets.json`：73 个区域 ID 到场景背景 PNG 的映射。
- `data/regions.json`：五城、十六镇、四十五野外、七门派的区域数据。
- `data/items.json`：物品、药品、武器、防具数据。
- `data/quests.json`：任务链数据。
- `assets/characters/reference_map_sprites/`：当前大地图优先使用的 41 个高精度水墨 Q 版 NPC archetype。
- `assets/characters/generated_map_sprites/`：组件化生成的 99 个 NPC sprite，作为参考级资源未覆盖时的回退资源。
- `assets/characters/npc/portraits/`：当前对话面板使用的 99 个 NPC 头像。
- `assets/characters/player/`：玩家不同性别/门派地图 sprite。
- `assets/characters/parts/`：头部、服装、道具等 45 个拆件 PNG。
- `assets/items/icons/`：物品图标。
- `assets/skills/icons/`：武学图标。
- `assets/world/scenes/`：区域场景背景。
- `assets/ui/`：水墨 UI 边框、按钮、状态条和地图标记资源。
- `assets/world/tiles/`：当前大地图使用的瓦片 PNG。
- `assets/previews/`：自动生成的资源预览图。
- `assets/generated_art_manifest.json`：本轮生成资源清单。
- `tools/generate_godot_art_assets.py`：批量生成地图瓦片、NPC/玩家地图 sprite、NPC 头像、物品图标、武学图标、区域背景、UI 和拆件资源。
- `tools/validate_godot_data.py`：校验区域数量、NPC/任务/商品/sprite 引用和坐标边界。
