## LPC 预组合图集生成工具

本工具提供两种方式生成NPC图集：

### 方式一：运行时动态组合（推荐）

NPC sprite系统已在 `res://scripts/entities/npc_sprite.gd` 中实现运行时动态加载和组合LPC部件。

**优点：**
- 无需预生成文件
- 灵活组合任意部件
- 支持5,400+种组合

**使用方式：**
在场景文件中为NpcSprite节点设置`npc_id`属性即可。

### 方式二：预烘焙图集（性能优化）

如果需要预先组合PNG图集文件（减少运行时加载），可以使用以下GDScript工具：

```gdscript
# 在Godot编辑器中通过 场景 -> 运行当前场景 执行
# 或在编辑器菜单：项目 -> 工具 -> 生成LPC图集

extends EditorScript

const LPC_BASE_PATH = "res://assets/sprites/chinese/lpc_entry/lpc_entry/png/walkcycle/"
const OUTPUT_DIR = "res://assets/sprites/chinese/lpc_generated/"

func _run() -> void:
	print("=== LPC图集生成工具 ===")
	
	# 确保输出目录存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets/sprites/chinese/lpc_generated"):
		dir.make_dir_recursive("assets/sprites/chinese/lpc_generated")
	
	# 获取NPC组件映射
	var npc_sprite_script = load("res://scripts/entities/npc_sprite.gd")
	var component_map = npc_sprite_script.get("NPC_COMPONENT_MAP")
	
	var success_count = 0
	var fail_count = 0
	
	for npc_id in component_map:
		var config = component_map[npc_id]
		if _generate_atlas(npc_id, config):
			success_count += 1
		else:
			fail_count += 1
	
	print("\n=== 生成完成 ===")
	print("成功: %d" % success_count)
	print("失败: %d" % fail_count)

func _generate_atlas(npc_id: String, config: Dictionary) -> bool:
	print("生成: ", npc_id)
	
	var layer_order = ["BODY", "FEET", "LEGS", "BELT", "TORSO", "HEAD", "HANDS", "WEAPON"]
	var frame_width = 64
	var frame_count = 8
	var canvas_width = frame_width * frame_count
	var canvas_height = 64
	
	var final_image = Image.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for layer in layer_order:
		var component = config.get(layer.to_lower(), "")
		if component.is_empty():
			continue
		
		var path = LPC_BASE_PATH + component + ".png"
		if not ResourceLoader.exists(path):
			continue
		
		var tex = load(path)
		if not tex:
			continue
		
		var img = tex.get_image()
		if img:
			final_image.blit_rect(img, Rect2i(0, 0, canvas_width, canvas_height), Vector2i.ZERO)
	
	var output_path = OUTPUT_DIR + npc_id.to_lower() + "_atlas.png"
	var error = final_image.save_png(output_path)
	
	if error == OK:
		print("  -> ", output_path)
		return true
	return false
```

### NPC组件配置示例

每个NPC可配置以下部件：
- `body`: 身体基础 (BODY_male, BODY_skeleton)
- `head`: 头部装备 (HEAD_robe_hood, HEAD_hair_blonde, HEAD_plate_armor_helmet, etc.)
- `torso`: 躯干装备 (TORSO_leather_armor_shirt_white, TORSO_chain_armor_torso, etc.)
- `legs`: 腿部装备 (LEGS_pants_greenish, LEGS_robe_skirt, LEGS_plate_armor_pants)
- `feet`: 脚部装备 (FEET_shoes_brown, FEET_plate_armor_shoes)
- `belt`: 腰带 (BELT_leather, BELT_rope)

### PixelSRPG-Forge素材整合

已下载的素材位于 `res://assets/sprites/chinese/pixel_sprg_forge/`：

**角色素材：**
- Priest角色 (3种造型 × 2变体 × 4帧)
  - 路径: `dungeon/2D Pixel Dungeon Asset Pack/Character_animation/priests_idle/`
  
**怪物素材：**
- Skeleton, Vampire, Skull等 (每种多个版本)
  - 路径: `dungeon/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/`
  - 路径: `monster/monster/` (更多怪物类型)

**使用方法：**
这些素材是16x16像素的idle动画，适合作为特殊NPC或敌人的待机动画。
