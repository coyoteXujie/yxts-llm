# CLAUDE.md

这是给 Claude Code / 自动化开发工具看的仓库说明。当前项目以 Godot 4 工程为主，不再使用旧 Python/Pygame 原型。

## 开工前必读

- 交付标准（"值 10 美元"的可验收定义 + 铁律）：`docs/17_交付标准与施工手册.md`
- 自迭代循环协议（每轮七步 + 任务队列 + 日志 + 禁止的 git 操作）：`docs/18_自迭代循环协议.md`
- 门禁裁判：`python3 tools/gate.py`（结果必须是 PASS，否则不算完成）

## 当前入口

- Godot 主工程：`godot_project/`
- 项目配置：`godot_project/project.godot`
- 主场景：`godot_project/scenes/main.tscn`
- 主脚本：`godot_project/scripts/main.gd`
- 设计文档：`docs/`
- 工具脚本：`tools/`

## 命令

运行游戏：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --path godot_project
```

打开 Godot 编辑器：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --editor --path godot_project
```

校验数据：

```bash
conda run -n yxts python tools/validate_godot_data.py
```

头less 启动验证：

```bash
env HOME=/tmp/godot_home XDG_DATA_HOME=/tmp/godot_data XDG_CONFIG_HOME=/tmp/godot_config XDG_CACHE_HOME=/tmp/godot_cache ./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --headless --path godot_project --quit-after 1
```

## 目录约定

- `godot_project/scripts/`：GDScript 游戏逻辑。
- `godot_project/data/`：NPC、区域、任务、物品和资源映射 JSON。
- `godot_project/assets/`：当前运行时美术资源。
- `docs/`：设计文档、Godot 架构和实现差距审计。
- `tools/`：资源生成与数据校验脚本。

不要恢复旧的根目录 `project.godot`、`main.py`、`requirements.txt`、`run.sh`、`src/`、`assets/`、`scripts/`、`scenes/`。
