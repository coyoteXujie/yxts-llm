# Tools

当前只保留 Godot 主工程仍在使用的工具脚本。

## 数据校验

```bash
conda run -n yxts python tools/validate_godot_data.py
```

校验内容包括区域数量、NPC 坐标、任务目标、商品引用、sprite/头像/图标/场景背景资源路径。

## 美术资源生成

```bash
conda run -n yxts python tools/generate_godot_art_assets.py
```

生成或刷新 `godot_project/assets/` 下的地图瓦片、NPC 地图 sprite、NPC 头像、玩家 sprite、拆件、物品图标、武学图标、区域背景和 UI 资源，并同步相关映射 JSON。
