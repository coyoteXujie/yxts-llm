# AGENTS.md

这是给 Codex / 自动化开发工具看的仓库说明。当前项目已经切换为 Godot 主工程，不再使用旧 Python/Pygame 运行链路。

## 工程入口

- 当前唯一可运行游戏工程：`godot_project/`
- Godot 项目配置：`godot_project/project.godot`
- 主场景：`godot_project/scenes/main.tscn`
- 主控制脚本：`godot_project/scripts/main.gd`
- 设计文档：`docs/`
- 数据与美术工具：`tools/`

`Godot_v4/` 是本机 Godot 引擎目录，已被 git 忽略，不要把其中二进制文件提交进仓库。

## 常用命令

运行游戏：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --path godot_project
```

打开编辑器：

```bash
./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --editor --path godot_project
```

校验 Godot 数据和资源映射：

```bash
conda run -n yxts python tools/validate_godot_data.py
```

头less 启动验证：

```bash
env HOME=/tmp/godot_home XDG_DATA_HOME=/tmp/godot_data XDG_CONFIG_HOME=/tmp/godot_config XDG_CACHE_HOME=/tmp/godot_cache ./Godot_v4/linux/Godot_v4.6.3-stable_linux.x86_64 --headless --path godot_project --quit-after 1
```

## 当前结构原则

- 根目录只保留仓库说明、协作说明、忽略规则、`godot_project/`、`docs/`、`tools/`。
- 不要重新创建根目录 `project.godot`、`main.py`、`requirements.txt`、`run.sh` 或旧 Python `src/`。
- 新的运行时资源应放在 `godot_project/assets/`。
- 新的运行数据应放在 `godot_project/data/`。
- 新的生成或校验脚本应放在 `tools/`。
- 设计目标写入 `docs/`，当前实现差距同步到 `docs/14_Godot实现差距审计.md`。

## 开发注意

- 修改 NPC、区域、任务、物品或资源映射后，必须运行 `tools/validate_godot_data.py`。
- 修改场景、脚本或资源路径后，必须跑一次 Godot 头less 启动验证。
- 不要提交 Godot 生成的 `.godot/`、`*.import`、`*.uid`、日志、截图或本地引擎文件。
