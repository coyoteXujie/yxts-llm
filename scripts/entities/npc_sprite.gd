extends Node2D

class_name NpcSprite

@export var npc_id: String = ""

var npc_name: String = "???"
var npc_title: String = ""
var npc_type: String = "villager"
var npc_occupation: String = ""
var npc_faction: String = "neutral"

var _anim_col: int = 0
var _anim_timer: float = 0.0
var _current_dir: int = 0
var _sprite_type: int = 0  # 0=box, 1=single, 2=ink_walk, 3=ink_portrait

var _display_sprite: Sprite2D = null
var _name_label: Label = null
var _resolved_id: String = ""
var _resolved_name: String = ""

const NPC_VISUAL: Dictionary = {
	# 平安镇核心NPC
	"xiaoyaozi": {"sprite": "ink:player_xiaoyao_stand", "walk": "ink:player_xiaoyao_walk", "color": Color(0.85, 0.72, 0.45), "name_color": Color(0.94, 0.78, 0.28)},
	"daode_heshang": {"sprite": "ink:player_bagua_stand", "walk": "ink:player_bagua_walk", "color": Color(0.72, 0.80, 0.62), "name_color": Color(0.78, 0.88, 0.62)},
	"laofuzi": {"sprite": "single:char_05", "color": Color(0.80, 0.75, 0.60), "name_color": Color(0.90, 0.82, 0.55)},
	"cunzhang": {"sprite": "single:char_06", "color": Color(0.70, 0.65, 0.55), "name_color": Color(0.85, 0.75, 0.50)},
	"wang_tiejiang": {"sprite": "single:char_07", "color": Color(0.85, 0.55, 0.35), "name_color": Color(0.95, 0.60, 0.30)},
	"li_muxue": {"sprite": "ink:player_flower_stand", "walk": "ink:player_flower_walk", "color": Color(0.70, 0.50, 0.65), "name_color": Color(0.88, 0.55, 0.78)},
	"lin_yueru": {"sprite": "ink:player_honglian_stand", "walk": "ink:player_honglian_walk", "color": Color(0.80, 0.45, 0.42), "name_color": Color(0.95, 0.50, 0.48)},
	"hetieshou": {"sprite": "single:char_08", "color": Color(0.75, 0.65, 0.45), "name_color": Color(0.88, 0.72, 0.38)},
	"pingyizhi": {"sprite": "single:char_09", "color": Color(0.55, 0.75, 0.55), "name_color": Color(0.58, 0.88, 0.55)},
	"gelangtai": {"sprite": "fenghuang:fenghuang_actor_6", "color": Color(0.80, 0.70, 0.40), "name_color": Color(0.92, 0.78, 0.30)},
	"hexi": {"sprite": "fenghuang:fenghuang_actor_7", "color": Color(0.60, 0.70, 0.80), "name_color": Color(0.65, 0.78, 0.92)},
	"yuweng": {"sprite": "fenghuang:fenghuang_actor_10", "color": Color(0.55, 0.65, 0.75), "name_color": Color(0.60, 0.75, 0.88)},
	"laopopo": {"sprite": "fenghuang:fenghuang_actor_11", "color": Color(0.72, 0.62, 0.68), "name_color": Color(0.82, 0.65, 0.75)},
	"daxia": {"sprite": "ink:player_taiji_stand", "walk": "ink:player_taiji_walk", "color": Color(0.75, 0.72, 0.55), "name_color": Color(0.90, 0.85, 0.50)},
	"weapon_merchant": {"sprite": "fenghuang:fenghuang_actor_12", "color": Color(0.78, 0.55, 0.40), "name_color": Color(0.90, 0.58, 0.35)},
	"armor_merchant": {"sprite": "fenghuang:fenghuang_actor_14", "color": Color(0.55, 0.58, 0.78), "name_color": Color(0.58, 0.62, 0.90)},
	"medicine_merchant": {"sprite": "box:4", "color": Color(0.50, 0.75, 0.50), "name_color": Color(0.52, 0.88, 0.50)},
	"food_merchant": {"sprite": "box:3", "color": Color(0.78, 0.65, 0.42), "name_color": Color(0.90, 0.70, 0.35)},
	"book_merchant": {"sprite": "box:5", "color": Color(0.68, 0.62, 0.78), "name_color": Color(0.75, 0.68, 0.90)},
	"grocery_merchant": {"sprite": "box:1", "color": Color(0.65, 0.72, 0.55), "name_color": Color(0.70, 0.82, 0.58)},
	"black_market": {"sprite": "box:2", "color": Color(0.50, 0.45, 0.55), "name_color": Color(0.62, 0.52, 0.72)},
	"banker": {"sprite": "fenghuang:fenghuang_actor_15", "color": Color(0.82, 0.75, 0.42), "name_color": Color(0.95, 0.82, 0.30)},
	"gate_guard": {"sprite": "fenghuang:fenghuang_actor_16", "color": Color(0.65, 0.65, 0.72), "name_color": Color(0.72, 0.72, 0.82)},
	"patrol": {"sprite": "fenghuang:fenghuang_actor_17", "color": Color(0.60, 0.65, 0.70), "name_color": Color(0.68, 0.75, 0.82)},
	"imperial_guard": {"sprite": "fenghuang:fenghuang_actor_18", "color": Color(0.72, 0.60, 0.55), "name_color": Color(0.85, 0.62, 0.55)},
	"beggar": {"sprite": "box:0", "color": Color(0.60, 0.55, 0.45), "name_color": Color(0.72, 0.65, 0.50)},
	"storyteller": {"sprite": "fenghuang:fenghuang_actor_19", "color": Color(0.78, 0.72, 0.52), "name_color": Color(0.90, 0.80, 0.48)},
	"fortune_teller": {"sprite": "fenghuang:fenghuang_actor_20", "color": Color(0.62, 0.55, 0.78), "name_color": Color(0.70, 0.58, 0.90)},
	"wanderer": {"sprite": "fenghuang:fenghuang_actor_6", "color": Color(0.58, 0.68, 0.58), "name_color": Color(0.62, 0.78, 0.60)},
	"boxing_master": {"sprite": "ink:player_xueshan_stand", "walk": "ink:player_xueshan_walk", "color": Color(0.80, 0.50, 0.35), "name_color": Color(0.92, 0.52, 0.30)},
	"sword_master": {"sprite": "ink:player_naja_stand", "walk": "ink:player_naja_walk", "color": Color(0.55, 0.70, 0.82), "name_color": Color(0.55, 0.78, 0.95)},
	"knife_master": {"sprite": "fenghuang:fenghuang_actor_7", "color": Color(0.75, 0.58, 0.38), "name_color": Color(0.88, 0.60, 0.30)},
	"shuriken_master": {"sprite": "fenghuang:fenghuang_actor_10", "color": Color(0.58, 0.62, 0.78), "name_color": Color(0.60, 0.68, 0.90)},
	"inner_energy_master": {"sprite": "fenghuang:fenghuang_actor_11", "color": Color(0.72, 0.68, 0.82), "name_color": Color(0.80, 0.72, 0.95)},
	"qinggong_master": {"sprite": "fenghuang:fenghuang_actor_12", "color": Color(0.52, 0.78, 0.68), "name_color": Color(0.50, 0.90, 0.72)},
	# 临安、余杭、嘉兴、绍兴NPC
	"bukua": {"sprite": "fenghuang:fenghuang_actor_14", "color": Color(0.68, 0.62, 0.52), "name_color": Color(0.78, 0.68, 0.55)},
	"xiaocaifeng": {"sprite": "box:1", "color": Color(0.55, 0.72, 0.62), "name_color": Color(0.60, 0.82, 0.68)},
	"hecaifeng": {"sprite": "box:2", "color": Color(0.68, 0.55, 0.62), "name_color": Color(0.78, 0.60, 0.72)},
	"maihuanv": {"sprite": "box:3", "color": Color(0.58, 0.58, 0.68), "name_color": Color(0.65, 0.62, 0.80)},
	"tufu": {"sprite": "fenghuang:fenghuang_actor_15", "color": Color(0.78, 0.50, 0.40), "name_color": Color(0.90, 0.52, 0.35)},
	"chushi": {"sprite": "fenghuang:fenghuang_actor_16", "color": Color(0.62, 0.72, 0.52), "name_color": Color(0.68, 0.82, 0.58)},
	"gongzige": {"sprite": "fenghuang:fenghuang_actor_17", "color": Color(0.60, 0.60, 0.78), "name_color": Color(0.70, 0.65, 0.90)},
	"shutong": {"sprite": "fenghuang:fenghuang_actor_18", "color": Color(0.70, 0.65, 0.55), "name_color": Color(0.80, 0.72, 0.48)},
	"maoshiqi": {"sprite": "fenghuang:fenghuang_actor_19", "color": Color(0.78, 0.72, 0.42), "name_color": Color(0.90, 0.78, 0.35)},
	# 临安
	"linan_zhifu": {"sprite": "fenghuang:fenghuang_actor_20", "color": Color(0.65, 0.60, 0.55), "name_color": Color(0.75, 0.65, 0.50)},
	"linan_silk_merchant": {"sprite": "single:char_05", "color": Color(0.55, 0.65, 0.72), "name_color": Color(0.60, 0.75, 0.85)},
	"linan_boat_girl": {"sprite": "single:char_06", "color": Color(0.72, 0.55, 0.65), "name_color": Color(0.82, 0.60, 0.75)},
	"linan_scholar": {"sprite": "single:char_07", "color": Color(0.60, 0.72, 0.68), "name_color": Color(0.68, 0.82, 0.72)},
	"linan_songji": {"sprite": "single:char_08", "color": Color(0.78, 0.62, 0.52), "name_color": Color(0.88, 0.68, 0.45)},
	# 余杭
	"yuhang_tea_farmer": {"sprite": "single:char_09", "color": Color(0.55, 0.70, 0.55), "name_color": Color(0.60, 0.82, 0.58)},
	"yuhang_canal_boatman": {"sprite": "fenghuang:fenghuang_actor_6", "color": Color(0.65, 0.68, 0.58), "name_color": Color(0.72, 0.75, 0.50)},
	"yuhang_martial_instructor": {"sprite": "fenghuang:fenghuang_actor_7", "color": Color(0.70, 0.55, 0.50), "name_color": Color(0.82, 0.60, 0.45)},
	# 嘉兴
	"jiaxing_silk_merchant": {"sprite": "fenghuang:fenghuang_actor_10", "color": Color(0.58, 0.65, 0.72), "name_color": Color(0.62, 0.72, 0.85)},
	"jiaxing_lake_girl": {"sprite": "fenghuang:fenghuang_actor_11", "color": Color(0.62, 0.62, 0.68), "name_color": Color(0.72, 0.68, 0.78)},
	"jiaxing_scholar": {"sprite": "fenghuang:fenghuang_actor_12", "color": Color(0.58, 0.72, 0.62), "name_color": Color(0.65, 0.82, 0.68)},
	# 绍兴
	"shaoxing_wine_maker": {"sprite": "fenghuang:fenghuang_actor_14", "color": Color(0.75, 0.65, 0.55), "name_color": Color(0.88, 0.72, 0.48)},
	"shaoxing_wubeng_boatman": {"sprite": "fenghuang:fenghuang_actor_15", "color": Color(0.55, 0.62, 0.58), "name_color": Color(0.62, 0.72, 0.65)},
	"shaoxing_fisherman": {"sprite": "fenghuang:fenghuang_actor_16", "color": Color(0.68, 0.58, 0.62), "name_color": Color(0.78, 0.65, 0.72)},
	# 北岭山
	"beiling_hunter": {"sprite": "fenghuang:fenghuang_actor_17", "color": Color(0.62, 0.58, 0.52), "name_color": Color(0.72, 0.68, 0.58)},
	"beiling_herb_gatherer": {"sprite": "fenghuang:fenghuang_actor_18", "color": Color(0.55, 0.65, 0.55), "name_color": Color(0.60, 0.78, 0.62)},
	"beiling_hermit": {"sprite": "fenghuang:fenghuang_actor_19", "color": Color(0.68, 0.55, 0.68), "name_color": Color(0.78, 0.62, 0.78)},
	# 嵩山
	"songshan_shaolin_monk": {"sprite": "fenghuang:fenghuang_actor_20", "color": Color(0.62, 0.62, 0.58), "name_color": Color(0.72, 0.70, 0.62)},
	"songshan_climber": {"sprite": "single:char_05", "color": Color(0.55, 0.60, 0.68), "name_color": Color(0.60, 0.70, 0.80)},
	"songshan_taoist": {"sprite": "single:char_06", "color": Color(0.70, 0.55, 0.60), "name_color": Color(0.80, 0.62, 0.68)},
	# 洛水
	"luoshui_fisherman": {"sprite": "single:char_07", "color": Color(0.58, 0.65, 0.58), "name_color": Color(0.68, 0.75, 0.65)},
	"luoshui_washerwoman": {"sprite": "single:char_08", "color": Color(0.65, 0.58, 0.65), "name_color": Color(0.78, 0.65, 0.75)},
	"luoshui_scholar": {"sprite": "single:char_09", "color": Color(0.55, 0.68, 0.72), "name_color": Color(0.65, 0.78, 0.82)},
	# 黑风岭
	"blackwind_wolf": {"sprite": "fenghuang:fenghuang_actor_6", "color": Color(0.58, 0.45, 0.55), "name_color": Color(0.70, 0.52, 0.68)},
	"blackwind_sha": {"sprite": "fenghuang:fenghuang_actor_7", "color": Color(0.68, 0.48, 0.45), "name_color": Color(0.82, 0.52, 0.48)},
	"resurrection_grass": {"sprite": "fenghuang:fenghuang_actor_10", "color": Color(0.52, 0.68, 0.62), "name_color": Color(0.60, 0.80, 0.70)},
	# 黄河谷
	"huanghe_old_boatman": {"sprite": "fenghuang:fenghuang_actor_11", "color": Color(0.65, 0.55, 0.48), "name_color": Color(0.78, 0.62, 0.45)},
	"huanghe_water_bandit": {"sprite": "fenghuang:fenghuang_actor_12", "color": Color(0.55, 0.52, 0.58), "name_color": Color(0.68, 0.62, 0.70)},
	"huanghe_treasure_seeker": {"sprite": "fenghuang:fenghuang_actor_14", "color": Color(0.68, 0.62, 0.52), "name_color": Color(0.80, 0.70, 0.48)},
	# 秦岭
	"qinling_xueshan_disciple": {"sprite": "ink:player_xueshan_stand", "walk": "ink:player_xueshan_walk", "color": Color(0.58, 0.68, 0.78), "name_color": Color(0.65, 0.78, 0.90)},
	"qinling_herb_gatherer": {"sprite": "fenghuang:fenghuang_actor_15", "color": Color(0.55, 0.70, 0.55), "name_color": Color(0.60, 0.82, 0.60)},
	"qinling_hermit": {"sprite": "fenghuang:fenghuang_actor_16", "color": Color(0.62, 0.62, 0.68), "name_color": Color(0.72, 0.70, 0.80)},
	# 终南山
	"zhongnan_taoist": {"sprite": "fenghuang:fenghuang_actor_17", "color": Color(0.60, 0.68, 0.62), "name_color": Color(0.70, 0.78, 0.65)},
	"zhongnan_hermit": {"sprite": "fenghuang:fenghuang_actor_18", "color": Color(0.55, 0.60, 0.68), "name_color": Color(0.65, 0.70, 0.80)},
	"zhongnan_herb_gatherer": {"sprite": "fenghuang:fenghuang_actor_19", "color": Color(0.62, 0.58, 0.58), "name_color": Color(0.72, 0.68, 0.68)},
	# 中原
	"zhongyuan_honglian_member": {"sprite": "fenghuang:fenghuang_actor_20", "color": Color(0.75, 0.48, 0.45), "name_color": Color(0.90, 0.52, 0.48)},
	"zhongyuan_hunter": {"sprite": "single:char_05", "color": Color(0.62, 0.68, 0.58), "name_color": Color(0.72, 0.78, 0.60)},
	"zhongyuan_woodcutter": {"sprite": "single:char_06", "color": Color(0.68, 0.60, 0.52), "name_color": Color(0.80, 0.68, 0.48)},
	# 华山
	"huashan_disciple": {"sprite": "ink:player_flower_stand", "walk": "ink:player_flower_walk", "color": Color(0.70, 0.55, 0.70), "name_color": Color(0.82, 0.62, 0.82)},
	"huashan_swordsman": {"sprite": "ink:player_naja_stand", "walk": "ink:player_naja_walk", "color": Color(0.55, 0.62, 0.75), "name_color": Color(0.60, 0.72, 0.88)},
	"huashan_taoist": {"sprite": "single:char_07", "color": Color(0.65, 0.70, 0.62), "name_color": Color(0.75, 0.80, 0.68)},
	# 更多NPC
	"zhifu": {"sprite": "single:char_08", "color": Color(0.72, 0.65, 0.60), "name_color": Color(0.85, 0.75, 0.55)},
	"chanong": {"sprite": "single:char_09", "color": Color(0.55, 0.72, 0.58), "name_color": Color(0.62, 0.85, 0.62)},
	"shuxiu_master": {"sprite": "fenghuang:fenghuang_actor_6", "color": Color(0.68, 0.62, 0.68), "name_color": Color(0.78, 0.70, 0.78)},
	"jiusi_boss": {"sprite": "fenghuang:fenghuang_actor_7", "color": Color(0.75, 0.60, 0.52), "name_color": Color(0.88, 0.68, 0.48)},
	"youxia_rover": {"sprite": "ink:player_taiji_stand", "walk": "ink:player_taiji_walk", "color": Color(0.60, 0.70, 0.65), "name_color": Color(0.70, 0.80, 0.72)},
	"shudao_guide": {"sprite": "fenghuang:fenghuang_actor_10", "color": Color(0.58, 0.62, 0.68), "name_color": Color(0.68, 0.72, 0.78)},
	"mabang_trader": {"sprite": "fenghuang:fenghuang_actor_11", "color": Color(0.65, 0.60, 0.58), "name_color": Color(0.75, 0.70, 0.52)},
	"shanhuo_merchant": {"sprite": "fenghuang:fenghuang_actor_12", "color": Color(0.68, 0.55, 0.58), "name_color": Color(0.80, 0.62, 0.68)},
	"nongfu": {"sprite": "fenghuang:fenghuang_actor_14", "color": Color(0.60, 0.68, 0.55), "name_color": Color(0.70, 0.78, 0.58)},
	"monk_xindu": {"sprite": "fenghuang:fenghuang_actor_15", "color": Color(0.58, 0.58, 0.62), "name_color": Color(0.70, 0.65, 0.75)},
	"liang_merchant": {"sprite": "fenghuang:fenghuang_actor_16", "color": Color(0.68, 0.62, 0.55), "name_color": Color(0.80, 0.70, 0.48)},
	"huanong": {"sprite": "fenghuang:fenghuang_actor_17", "color": Color(0.55, 0.68, 0.62), "name_color": Color(0.65, 0.78, 0.68)},
	"shuxiu_girl": {"sprite": "fenghuang:fenghuang_actor_18", "color": Color(0.65, 0.58, 0.68), "name_color": Color(0.75, 0.65, 0.78)},
	"flower_merchant": {"sprite": "fenghuang:fenghuang_actor_19", "color": Color(0.60, 0.70, 0.55), "name_color": Color(0.70, 0.82, 0.60)},
	"zhandao_guard": {"sprite": "fenghuang:fenghuang_actor_20", "color": Color(0.62, 0.55, 0.62), "name_color": Color(0.72, 0.62, 0.75)},
}

const NPC_PORTRAITS: Dictionary = {
	"xiaoyaozi": "res://assets/ink_chars/npc_xiaoyaozi.jpg",
	"daode_heshang": "res://assets/ink_chars/npc_monk.jpg",
	"laofuzi": "res://assets/ink_chars/npc_scholar.jpg",
	"cunzhang": "res://assets/ink_chars/npc_villagechief.jpg",
	"wang_tiejiang": "res://assets/ink_chars/npc_blacksmith.jpg",
	"li_muxue": "res://assets/ink_chars/npc_limuxue.jpg",
	"lin_yueru": "res://assets/ink_chars/npc_linyueru.jpg",
	"hetieshou": "res://assets/ink_chars/npc_merchant.jpg",
	"pingyizhi": "res://assets/ink_chars/npc_herbalist.jpg",
	"gate_guard": "res://assets/ink_chars/npc_guard.jpg",
	"patrol": "res://assets/ink_chars/npc_guard.jpg",
	"imperial_guard": "res://assets/ink_chars/npc_guard.jpg",
	"beggar": "res://assets/ink_chars/npc_villager.jpg",
	"storyteller": "res://assets/ink_chars/npc_scholar.jpg",
	"fortune_teller": "res://assets/ink_chars/npc_villager.jpg",
	"gelangtai": "res://assets/ink_chars/npc_merchant.jpg",
	"laopopo": "res://assets/ink_chars/npc_mother.jpg",
	"medicine_merchant": "res://assets/ink_chars/npc_herbalist.jpg",
	"food_merchant": "res://assets/ink_chars/npc_villager.jpg",
	"book_merchant": "res://assets/ink_chars/npc_scholar.jpg",
	"banker": "res://assets/ink_chars/npc_merchant.jpg",
	"weapon_merchant": "res://assets/ink_chars/npc_blacksmith.jpg",
}

const DEFAULT_VISUAL: Dictionary = {"sprite": "box:0", "color": Color(0.65, 0.62, 0.58), "name_color": Color(0.75, 0.70, 0.62)}

func _ready():
	_resolve_npc_id()
	_load_npc_data()
	_apply_identity()
	_setup_sprite()
	_setup_name_label()
	add_to_group("npcs")

func _process(delta):
	_anim_timer += delta
	if _anim_timer < 0.3:
		return
	_anim_timer = 0.0
	if _display_sprite and _display_sprite.texture:
		_anim_col = (_anim_col + 1) % 4
		_update_sprite_frame()

func _resolve_npc_id():
	_resolved_id = npc_id.to_lower().strip_edges()
	if _resolved_id.is_empty():
		_resolved_id = "beggar"
	var holder = get_parent()
	if holder and holder is Node2D and holder.has_meta("npc_name"):
		var parent_name = str(holder.get_meta("npc_name"))
		if not parent_name.is_empty() and parent_name != "???":
			npc_name = parent_name

func _load_npc_data():
	if _resolved_id.is_empty():
		return
	var npc_data = {}
	if NpcData and NpcData.has_method("get_npc_data"):
		npc_data = NpcData.get_npc_data(_resolved_id)
	if npc_data.is_empty():
		return
	npc_name = npc_data.get("name", npc_name)
	npc_title = npc_data.get("title", npc_title)
	npc_type = npc_data.get("type", npc_type)
	npc_occupation = npc_data.get("occupation", npc_occupation)
	npc_faction = npc_data.get("faction", npc_faction)

func _apply_identity():
	set_meta("npc_id", _resolved_id)
	set_meta("npc_name", npc_name)
	set_meta("npc_title", npc_title)
	var holder = get_parent()
	if holder and holder is Node2D and holder.name not in ["NPCLayer", "NPCs"]:
		holder.set_meta("npc_id", _resolved_id)
		holder.set_meta("npc_name", npc_name)
		holder.set_meta("npc_title", npc_title)
		holder.add_to_group("npcs")

func _get_visual_config():
	if NPC_VISUAL.has(_resolved_id):
		return NPC_VISUAL[_resolved_id]
	var hash_val = _resolved_id.hash()
	var box_chars = [0, 1, 2, 3, 4, 5]
	var fenghuang_ids = [6, 7, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20]
	var all_sprites = []
	for c in box_chars:
		all_sprites.append("box:%d" % c)
	for f in fenghuang_ids:
		all_sprites.append("fenghuang:fenghuang_actor_%d" % f)
	all_sprites.append("single:char_05")
	all_sprites.append("single:char_06")
	all_sprites.append("single:char_07")
	all_sprites.append("single:char_08")
	all_sprites.append("single:char_09")
	var idx = abs(hash_val) % all_sprites.size()
	var palette = [
		Color(0.65, 0.62, 0.58), Color(0.58, 0.65, 0.60), Color(0.62, 0.58, 0.68),
		Color(0.70, 0.58, 0.52), Color(0.55, 0.62, 0.72), Color(0.72, 0.62, 0.55),
		Color(0.60, 0.70, 0.58), Color(0.68, 0.55, 0.65), Color(0.58, 0.68, 0.72),
		Color(0.72, 0.68, 0.52), Color(0.55, 0.72, 0.65), Color(0.65, 0.55, 0.72),
	]
	var name_palette = [
		Color(0.78, 0.72, 0.60), Color(0.62, 0.78, 0.65), Color(0.70, 0.62, 0.82),
		Color(0.82, 0.62, 0.55), Color(0.58, 0.72, 0.85), Color(0.85, 0.68, 0.58),
		Color(0.65, 0.82, 0.62), Color(0.80, 0.58, 0.75), Color(0.60, 0.78, 0.85),
		Color(0.85, 0.78, 0.55), Color(0.58, 0.85, 0.72), Color(0.75, 0.58, 0.85),
	]
	var color_idx = abs(hash_val) % palette.size()
	return {
		"sprite": all_sprites[idx],
		"color": palette[color_idx],
		"name_color": name_palette[color_idx]
	}

func _setup_sprite():
	var config = _get_visual_config()
	var sprite_key = config.get("sprite", "box:0")
	var tint = config.get("color", Color(1, 1, 1))
	var parts = sprite_key.split(":")
	var category = parts[0]
	var identifier = parts[1] if parts.size() > 1 else ""

	match category:
		"box":
			_sprite_type = 0
			var char_index = int(identifier)
			var path = "res://assets/sprites/chinese_chars/char%d_dir0_frame0.png" % char_index
			if ResourceLoader.exists(path):
				var sprite = Sprite2D.new()
				sprite.centered = true
				sprite.scale = Vector2(3.5, 3.5)
				sprite.z_index = 5
				sprite.texture = load(path)
				sprite.modulate = tint
				add_child(sprite)
				_display_sprite = sprite
		"single":
			_sprite_type = 1
			var path = "res://assets/sprites/chinese/%s.png" % identifier
			if ResourceLoader.exists(path):
				var sprite = Sprite2D.new()
				sprite.centered = true
				sprite.scale = Vector2(3.0, 3.0)
				sprite.z_index = 5
				sprite.texture = load(path)
				sprite.modulate = tint
				add_child(sprite)
				_display_sprite = sprite
		"ink":
			_sprite_type = 2
			var path = "res://assets/ink_chars/%s.png" % identifier
			if ResourceLoader.exists(path):
				var sprite = Sprite2D.new()
				sprite.centered = true
				sprite.scale = Vector2(2.5, 2.5)
				sprite.z_index = 5
				sprite.texture = load(path)
				sprite.modulate = tint
				add_child(sprite)
				_display_sprite = sprite
		"fenghuang":
			_sprite_type = 1
			var path = "res://assets/sprites/chinese/%s.png" % identifier
			if ResourceLoader.exists(path):
				var sprite = Sprite2D.new()
				sprite.centered = true
				sprite.scale = Vector2(3.0, 3.0)
				sprite.z_index = 5
				sprite.texture = load(path)
				sprite.modulate = tint
				add_child(sprite)
				_display_sprite = sprite

	if not _display_sprite:
		_sprite_type = 0
		var path = "res://assets/sprites/chinese_chars/char0_dir0_frame0.png"
		if ResourceLoader.exists(path):
			var sprite = Sprite2D.new()
			sprite.centered = true
			sprite.scale = Vector2(3.5, 3.5)
			sprite.z_index = 5
			sprite.texture = load(path)
			sprite.modulate = tint
			add_child(sprite)
			_display_sprite = sprite

func _setup_name_label():
	var config = _get_visual_config()
	var name_color = config.get("name_color", Color(0.79, 0.66, 0.43, 1))

	_name_label = Label.new()
	_name_label.name = "NPCNameLabel"
	var display_name = npc_name if npc_name != "???" else _resolved_id
	_name_label.text = display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", name_color)
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.z_index = 10
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg = ColorRect.new()
	bg.name = "NameBg"
	bg.color = Color(0.04, 0.04, 0.06, 0.65)
	bg.z_index = 9
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.position = Vector2(-40, -58)
	bg.size = Vector2(80, 20)
	add_child(bg)

	_name_label.position = Vector2(-40, -58)
	_name_label.size = Vector2(80, 20)
	add_child(_name_label)

func _update_sprite_frame():
	if not _display_sprite:
		return

	match _sprite_type:
		0:
			var config = _get_visual_config()
			var parts = config.get("sprite", "box:0").split(":")
			var char_index = int(parts[1]) if parts.size() > 1 else 0
			var path = "res://assets/sprites/chinese_chars/char%d_dir%d_frame%d.png" % [char_index, _current_dir, _anim_col]
			if ResourceLoader.exists(path):
				_display_sprite.texture = load(path)
		2:
			var config = _get_visual_config()
			var walk_key = config.get("walk", "")
			if not walk_key.is_empty():
				var walk_parts = walk_key.split(":")
				if walk_parts.size() > 1:
					var is_walking = _anim_col % 2 == 1
					var base_key = config.get("sprite", "").split(":")[1] if config.get("sprite", "").split(":").size() > 1 else ""
					var walk_id = walk_parts[1]
					if is_walking and not walk_id.is_empty():
						var path = "res://assets/ink_chars/%s.png" % walk_id
						if ResourceLoader.exists(path):
							_display_sprite.texture = load(path)
					elif not base_key.is_empty():
						var path = "res://assets/ink_chars/%s.png" % base_key
						if ResourceLoader.exists(path):
							_display_sprite.texture = load(path)

func set_direction(dir: int):
	_current_dir = clamp(dir, 0, 3)
	_update_sprite_frame()

func get_portrait_path():
	if NPC_PORTRAITS.has(_resolved_id):
		return NPC_PORTRAITS[_resolved_id]
	return ""

func set_display_name(new_name: String):
	if _name_label:
		_name_label.text = new_name
