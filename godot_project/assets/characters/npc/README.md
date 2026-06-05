# NPC Portrait Assets

当前目录只保留 Godot 运行时实际使用的 NPC 对话头像：

- `portraits/`：99 个 NPC 对话头像。
- `portraits_v2/`：核心主线 NPC 的高质量生成头像，优先用于剧情对话；当前已接入苏梦瑶、陈天行、赵无极、玄机子、花如玉、烈火、蛇王、太极真人、冰魄、逍遥子。
- `../../generated_map_sprites/`：99 个大地图 NPC 透明 sprite。

资源映射由以下数据文件维护：

- `data/npc_portrait_assets.json`
- `data/npc_sprite_assets.json`

旧 NPC 图集、切片 sprite 和生成 prompt 已清理，避免与当前统一风格资源混用。后续新增 NPC 美术时，优先扩展 `tools/generate_godot_art_assets.py`，再重新生成映射 JSON；主线关键角色可以先进入 `portraits_v2/`，确认风格后再批量替换。
