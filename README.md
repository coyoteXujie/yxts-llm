# 白金英雄坛说 Godot 项目

这是当前可运行的 Godot 4 版本主仓库。旧 Python/Pygame 原型、早期 Godot 草稿目录和未接入的旧素材源已经清理，后续开发以 `godot_project/` 为唯一运行工程。

## 运行

在仓库根目录执行：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --path godot_project
```

打开编辑器：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --editor --path godot_project
```

`Godot_v4/` 是本机 Godot 引擎目录，已被 git 忽略，不作为游戏资源提交。

## 当前结构

```text
yxts-llm/
├── Godot_v4/              # 本地 Godot 可执行文件，git 忽略
├── godot_project/         # 当前游戏主工程
│   ├── project.godot
│   ├── scenes/            # Godot 场景
│   ├── scripts/           # GDScript 游戏逻辑
│   ├── data/              # NPC、区域、任务、物品与资源映射 JSON
│   └── assets/            # 当前运行时使用的美术资源
├── doc/                   # 设计文档和实现差距审计
└── tools/                 # 资产生成与数据校验工具
```

## 现状

- 大地图已实现五城、七派、乡村、野外、山脉、河湖、荒漠、竹海等 73 个区域。
- 当前有 99 个 NPC、10 个任务、22 个物品、41 个武学图标和 73 张区域背景占位图。
- NPC 地图 sprite、对话头像、玩家门派 sprite、物品图标、武学图标、地图瓦片和 UI 资源均已接入 Godot 工程。
- 玩法竖切包含移动、交谈、任务、商店、背包、修炼、战斗、世界地图、快速旅行、存档读档和基础时间天气氛围。

## 常用命令

```bash
conda run -n yxts python tools/validate_godot_data.py
```

```bash
env HOME=/tmp/godot_home XDG_DATA_HOME=/tmp/godot_data XDG_CONFIG_HOME=/tmp/godot_config XDG_CACHE_HOME=/tmp/godot_cache ./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --headless --path godot_project --quit-after 1
```

更多玩法和目录说明见 `godot_project/README.md`，设计目标和差距见 `doc/14_Godot实现差距审计.md`。
