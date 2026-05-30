@tool
extends Node

## LPC图集生成工具 - 在Godot编辑器中运行
## 用法：
## 1. 将此脚本添加到场景中的节点
## 2. 在编辑器中运行场景
## 3. 图集将生成到 res://assets/sprites/chinese/lpc_generated/

const LPC_BASE_PATH = "res://assets/sprites/chinese/lpc_entry/lpc_entry/png/walkcycle/"
const OUTPUT_DIR = "res://assets/sprites/chinese/lpc_generated/"

const NPC_COMPONENT_MAP = {
	"AQING": {"body": "BODY_male", "head": "HEAD_robe_hood", "torso": "TORSO_leather_armor_shirt_white", "legs": "LEGS_pants_greenish", "feet": "FEET_shoes_brown", "belt": "BELT_leather"},
	"BOY": {"body": "BODY_male", "head": "HEAD_hair_blonde", "torso": "TORSO_chain_armor_torso", "legs": "LEGS_robe_skirt", "feet": "FEET_shoes_brown", "belt": "BELT_rope"},
	"BUKUAI": {"body": "BODY_male", "head": "HEAD_chain_armor_helmet", "torso": "TORSO_chain_armor_jacket_purple", "legs": "LEGS_plate_armor_pants", "feet": "FEET_plate_armor_shoes", "belt": "BELT_leather"},
	"DAODE": {"body": "BODY_male", "head": "HEAD_robe_hood", "torso": "TORSO_robe_shirt_brown", "legs": "LEGS_robe_skirt", "feet": "FEET_shoes_brown", "belt": "BELT_rope"},
	"DAXIA": {"body": "BODY_male", "head": "HEAD_chain_armor_helmet", "torso": "TORSO_chain_armor_jacket_purple", "legs": "LEGS_pants_greenish", "feet": "FEET_shoes_brown", "belt": "BELT_leather"},
}

const LPC_LAYER_ORDER = ["BODY", "FEET", "LEGS", "BELT", "TORSO", "HEAD"]

func _ready():
	_generate_all_atlases()

func _generate_all_atlases():
	print("=== LPC图集生成工具 ===")
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets/sprites/chinese/lpc_generated"):
		dir.make_dir_recursive("assets/sprites/chinese/lpc_generated")
		print("创建输出目录")
	
	var success_count = 0
	var fail_count = 0
	
	for npc_id in NPC_COMPONENT_MAP:
		var config = NPC_COMPONENT_MAP[npc_id]
		if _generate_atlas(npc_id, config):
			success_count += 1
		else:
			fail_count += 1
	
	print("\n=== 生成完成 ===")
	print("成功: %d" % success_count)
	print("失败: %d" % fail_count)

func _generate_atlas(npc_id: String, config: Dictionary) -> bool:
	print("\n生成: ", npc_id)
	
	var frame_width = 64
	var frame_count = 8
	var canvas_width = frame_width * frame_count
	var canvas_height = 64
	
	var final_image = Image.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	final_image.fill(Color(0, 0, 0, 0))
	
	for layer in LPC_LAYER_ORDER:
		var component = config.get(layer.to_lower(), "")
		if component.is_empty():
			continue
		
		var path = LPC_BASE_PATH + component + ".png"
		if not ResourceLoader.exists(path):
			print("  跳过(不存在): ", component)
			continue
		
		var tex = load(path)
		if not tex:
			continue
		
		var img = tex.get_image()
		if not img:
			continue
		
		final_image.blit_rect(img, Rect2i(0, 0, canvas_width, canvas_height), Vector2i.ZERO)
	
	var output_path = OUTPUT_DIR + npc_id.to_lower() + "_atlas.png"
	var error = final_image.save_png(output_path)
	
	if error == OK:
		print("  成功: ", output_path)
		return true
	else:
		print("  失败: ", error)
		return false
