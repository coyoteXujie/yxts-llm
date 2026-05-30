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

## 当前玩法竖切

- 主菜单、角色创建、读档入口。
- WASD / 方向键：移动。
- T / Enter：与附近 NPC 交谈。
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
- 平安镇已作为起始镇落到大地图北洛阳区域，玩家出生点、新手 NPC、镇东敌人和洛阳主线 NPC 不再挤在同一个城中心。
- `data/regions.json` 已登记 73 个结构化区域，玩家移动时会识别当前区域并记录探索度；HUD 会显示所在地、探索度和危险等级。
- M 键可打开世界地图面板，查看已发现区域、探索度、区域说明、区域背景图、NPC 标记、可接任务标记和当前任务目标。
- HUD 右上角有常驻小地图，显示当前区域、探索进度、玩家位置、任务目标和已标记目的地。
- `tools/generate_godot_art_assets.py` 已生成并接入第一批游戏内美术资源：20 张 48x48 地图瓦片、99 张 NPC 地图 sprite、99 张 NPC 对话头像、16 张玩家门派/性别 sprite、29 张角色拆件 PNG、22 张物品图标、41 张武学图标、73 张区域场景背景、8 张 UI 资源。
- 地图现在优先使用 `assets/world/tiles/` 的瓦片 PNG；NPC 和玩家优先使用生成后的透明 PNG sprite，姓名只在靠近/选中时显示，避免标签和角色互相遮挡。
- 对话面板已接入 `assets/characters/npc/portraits/` 的 NPC 头像；背包和商店已接入 `assets/items/icons/` 的物品图标；修炼和战斗面板已接入 `assets/skills/icons/` 的武学图标；世界地图面板已接入 `assets/world/scenes/` 的区域背景和 `assets/ui/` 的地图标记。
- 切换区域时会出现区域横幅，提示区域类型、危险等级和探索度。
- 战斗面板会显示敌人头像，并按玩家已学的攻击类武学生成可点击招式按钮。
- `assets/previews/` 下有瓦片、NPC、玩家、头像、物品图标、武学图标和场景背景资源预览图；旧 NPC 图集和切片源已清理，当前运行资源统一使用生成后的地图 sprite 和对话头像。

## 目录

- `scenes/main.tscn`：入口场景。
- `scripts/autoload/`：全局数据、状态和事件总线。
- `scripts/world/`：文档驱动的大地图生成、可通行判定、NPC 生成。
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
- `assets/characters/generated_map_sprites/`：当前大地图使用的 99 个统一风格 NPC sprite。
- `assets/characters/npc/portraits/`：当前对话面板使用的 99 个 NPC 头像。
- `assets/characters/player/`：玩家不同性别/门派地图 sprite。
- `assets/characters/parts/`：头部、服装、道具等拆件 PNG。
- `assets/items/icons/`：物品图标。
- `assets/skills/icons/`：武学图标。
- `assets/world/scenes/`：区域场景背景。
- `assets/ui/`：水墨 UI 边框、按钮、状态条和地图标记资源。
- `assets/world/tiles/`：当前大地图使用的瓦片 PNG。
- `assets/previews/`：自动生成的资源预览图。
- `assets/generated_art_manifest.json`：本轮生成资源清单。
- `tools/generate_godot_art_assets.py`：批量生成地图瓦片、NPC/玩家地图 sprite、NPC 头像、物品图标、武学图标、区域背景、UI 和拆件资源。
- `tools/validate_godot_data.py`：校验区域数量、NPC/任务/商品/sprite 引用和坐标边界。
