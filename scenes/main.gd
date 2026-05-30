extends Node2D

var player: CharacterBody2D
var is_game_started: bool = false
var player_speed: float = 200.0
var _notification_tween: Tween
var _nearby_npcs: Array = []

var _menu_canvas: CanvasLayer
var _menu_items: Array = []
var _menu_index: int = 0
var _hud_canvas: CanvasLayer
var _hud_labels: Dictionary = {}
var _dialogue_canvas: CanvasLayer
var _dialogue_labels: Dictionary = {}
var _dialogue_active: bool = false
var _dialogue_queue: Array = []
var _dialogue_current_index: int = 0
var _auto_start_timer: float = 0.0
var _auto_start_delay: float = 8.0

var _quest_tracker_canvas: CanvasLayer
var _quest_tracker_label: Label
var _quest_objective_label: Label
var _quest_active: bool = false
var _current_quest_id: String = ""
var _vertical_quest_stage: int = 0

var _npc_dialogues: Dictionary = {}
var _game_flags: Dictionary = {}
var _player_stats: Dictionary = {
	"level": 1,
	"hp": 100,
	"max_hp": 100,
	"mp": 50,
	"max_mp": 50,
	"attack": 18,
	"defense": 8,
	"fortune": 12,
	"reputation": 0,
	"xp": 0,
	"gold": 100,
}
var _inventory: Dictionary = {
	"金疮药": 2,
	"粗布衣": 1,
}
var _current_scene_name: String = "pingan_town"
var _player_frame: int = 0
var _player_anim_timer: float = 0.0
var _player_dir: int = 0
var _entered_from_transition: bool = false
var _dialogue_complete_objective: String = ""
var _dialogue_complete_action: Callable
var _combat_canvas: CanvasLayer
var _combat_labels: Dictionary = {}
var _combat_active: bool = false
var _combat_enemy: Dictionary = {}
var _combat_log: Array[String] = []
var _combat_turn_locked: bool = false
var _combat_context: String = ""

const NPC_PORTRAITS: Dictionary = {
	"xiaoyaozi": "res://assets/ink_chars/npc_xiaoyaozi.jpg",
	"daode_heshang": "res://assets/ink_chars/npc_monk.jpg",
	"laofuzi": "res://assets/ink_chars/npc_scholar.jpg",
	"cunzhang": "res://assets/ink_chars/npc_villagechief.jpg",
	"wang_tiejiang": "res://assets/ink_chars/npc_blacksmith.jpg",
	"li_muxue": "res://assets/ink_chars/npc_mother.jpg",
	"lin_yueru": "res://assets/ink_chars/npc_linyueru.jpg",
	"hetieshou": "res://assets/ink_chars/npc_merchant.jpg",
	"pingyizhi": "res://assets/ink_chars/npc_herbalist.jpg",
	"gate_guard": "res://assets/ink_chars/npc_guard.jpg",
}
var _transitioning: bool = false

const COLOR_BG := Color(0.07, 0.07, 0.10, 1)
const COLOR_GOLD := Color(0.79, 0.66, 0.43, 1)
const COLOR_GOLD_BRIGHT := Color(0.94, 0.75, 0.25, 1)
const COLOR_TEXT := Color(0.96, 0.94, 0.91, 1)
const COLOR_TEXT_DIM := Color(0.63, 0.60, 0.53, 1)
const COLOR_HP := Color(0.75, 0.22, 0.17, 1)
const COLOR_MP := Color(0.16, 0.50, 0.73, 1)
const COLOR_PANEL := Color(0.10, 0.10, 0.18, 0.88)

const SCENE_INFO: Dictionary = {
	# 平安镇体系
	"pingan_town": {"name": "平安镇", "north": "zhongnan_mountain_foot", "east": "baqiao_town", "west": "wilderness_east", "south": "wilderness_south"},
	"zhongnan_mountain_foot": {"name": "终南山脚", "south": "pingan_town", "north": "shaolin_temple"},
	"baqiao_town": {"name": "灞桥镇", "west": "pingan_town", "east": "changan"},
	"wilderness_east": {"name": "中原密林", "east": "heifeng_ridge", "west": "pingan_town"},
	"heifeng_ridge": {"name": "黑风岭", "west": "wilderness_east"},
	"wilderness_south": {"name": "黄河古道", "north": "pingan_town"},
	"shaolin_temple": {"name": "少林寺", "south": "zhongnan_mountain_foot"},
	# 五大城池
	"changan": {"name": "长安城", "north": "lintong", "east": "luoyang", "south": "fengxiang", "west": "xianyang"},
	"luoyang": {"name": "洛阳城", "north": "qinghe", "east": "gongyi", "south": "yanshi", "west": "mengjin"},
	"linan": {"name": "临安城", "north": "yuhang", "east": "jiaxing", "south": "shaoxing"},
	"chengdu": {"name": "成都城", "north": "xindu", "south": "wenjiang", "west": "shuangliu"},
	"jiangling": {"name": "江陵城", "north": "dangyang", "east": "luoyang", "west": "yiling"},
	# 洛阳周边小镇
	"qinghe": {"name": "清河镇", "north": "beiling_mtn", "south": "luoyang", "east": "songshan_peak"},
	"gongyi": {"name": "巩义镇", "west": "luoyang", "east": "luoshui_river", "north": "songshan_peak"},
	"yanshi": {"name": "偃师镇", "north": "luoyang", "east": "yiluo_valley", "south": "yanshi_plain"},
	"mengjin": {"name": "孟津镇", "east": "luoyang", "north": "mengjin_ford", "west": "huanghe_valley"},
	# 长安周边小镇
	"fengxiang": {"name": "凤翔镇", "north": "changan", "south": "zhongnan_mtn"},
	"xianyang": {"name": "咸阳镇", "east": "changan", "west": "tongguan_pass", "north": "lintong_bath"},
	"weinan": {"name": "渭南镇", "west": "weihe_river", "south": "weihe_river"},
	"lintong": {"name": "临潼镇", "south": "changan", "north": "xianyang_mound", "east": "lintong_bath"},
	# 临安周边小镇
	"yuhang": {"name": "余杭镇", "south": "linan", "north": "jiaxing_canal", "west": "tianmu_mtn"},
	"jiaxing": {"name": "嘉兴镇", "west": "linan", "east": "taihu_lake", "south": "jiaxing_canal"},
	"shaoxing": {"name": "绍兴镇", "north": "linan", "south": "shaoxing_water", "east": "jiangnan_marsh"},
	# 成都周边小镇
	"shuangliu": {"name": "双流镇", "east": "chengdu", "west": "shudao_mtn", "south": "minjiang_river"},
	"xindu": {"name": "新都镇", "south": "chengdu", "north": "xindu_field", "west": "qingcheng_mtn"},
	"wenjiang": {"name": "温江镇", "north": "chengdu", "south": "wenjiang_garden", "east": "bashu_bamboo"},
	# 江陵周边小镇
	"yiling": {"name": "夷陵镇", "east": "jiangling", "west": "yiling_gap", "south": "three_gorges"},
	"dangyang": {"name": "当阳镇", "south": "jiangling", "north": "dangyang_plain", "west": "funiu_mtn"},
	# 洛阳周边野外
	"beiling_mtn": {"name": "北岭群山", "south": "qinghe", "east": "songshan_peak", "north": "bagua_sect"},
	"songshan_peak": {"name": "嵩山峰顶", "west": "beiling_mtn", "east": "taihang_range", "south": "gongyi"},
	"luoshui_river": {"name": "洛水河畔", "west": "gongyi", "east": "yanshi_plain", "south": "yiluo_valley"},
	"huanghe_valley": {"name": "黄河古道", "east": "mengjin_ford", "south": "zhongtiao_mtn", "west": "xianyang_mound"},
	"taihang_range": {"name": "太行山脉", "west": "mengjin_ford", "north": "zhongtiao_mtn", "east": "taiji_sect"},
	"yanshi_plain": {"name": "偃师原野", "north": "yanshi", "west": "luoshui_river", "south": "zhongyuan_for"},
	"mengjin_ford": {"name": "孟津渡口", "south": "mengjin", "west": "huanghe_valley", "east": "taihang_range"},
	"yiluo_valley": {"name": "伊洛河谷", "north": "yanshi", "west": "luoshui_river", "south": "zhongtiao_mtn"},
	"zhongtiao_mtn": {"name": "中条山脉", "north": "yiluo_valley", "east": "taihang_range", "south": "huanghe_valley"},
	# 长安周边野外
	"qinling_deep": {"name": "秦岭深处", "north": "longxi_desert", "east": "zhongnan_mtn", "south": "xueshan_sect"},
	"zhongnan_mtn": {"name": "终南山", "north": "fengxiang", "east": "huashan_cliff", "west": "qinling_deep"},
	"zhongyuan_for": {"name": "中原密林", "north": "yanshi_plain", "east": "honglian_sect", "west": "weihe_river"},
	"weihe_river": {"name": "渭河平原", "north": "weinan", "east": "zhongyuan_for", "west": "huashan_cliff", "south": "weinan"},
	"longxi_desert": {"name": "陇西荒漠", "north": "huanghe_valley", "east": "tongguan_pass", "south": "qinling_deep"},
	"huashan_cliff": {"name": "华山险峰", "east": "weihe_river", "south": "tongguan_pass", "west": "zhongnan_mtn"},
	"tongguan_pass": {"name": "潼关古道", "north": "longxi_desert", "east": "xianyang", "south": "huashan_cliff"},
	"lintong_bath": {"name": "临潼温泉", "west": "xianyang", "east": "xianyang_mound", "south": "lintong"},
	"xianyang_mound": {"name": "秦陵原", "north": "huanghe_valley", "south": "lintong", "west": "lintong_bath"},
	# 临安周边野外
	"jiangnan_marsh": {"name": "江南水泽", "west": "shaoxing", "south": "qiantang_tide", "north": "taihu_lake"},
	"wuyi_for": {"name": "武夷山林", "north": "huangshan_peak", "south": "flower_sect", "east": "qiantang_tide"},
	"dongting_lake": {"name": "洞庭湖畔", "east": "tianmu_mtn", "south": "xiaoyao_sect", "west": "three_gorges"},
	"qiantang_tide": {"name": "钱塘江潮", "north": "jiangnan_marsh", "east": "shaoxing_water", "south": "wuyi_for"},
	"tianmu_mtn": {"name": "天目山", "east": "yuhang", "south": "huangshan_peak", "west": "dongting_lake"},
	"taihu_lake": {"name": "太湖烟波", "west": "jiaxing", "south": "jiangnan_marsh", "north": "jiaxing_canal"},
	"huangshan_peak": {"name": "黄山云海", "north": "tianmu_mtn", "east": "qiantang_tide", "west": "wuyi_for"},
	"shaoxing_water": {"name": "绍兴水乡", "north": "shaoxing", "east": "jiangnan_marsh", "west": "qiantang_tide"},
	"jiaxing_canal": {"name": "嘉兴运河", "south": "yuhang", "east": "taihu_lake", "west": "tianmu_mtn"},
	# 成都周边野外
	"shudao_mtn": {"name": "蜀道群山", "east": "shuangliu", "north": "qingcheng_mtn", "west": "western_plateau"},
	"bashu_bamboo": {"name": "巴蜀竹海", "east": "minjiang_river", "north": "wenjiang", "south": "emei_sacred"},
	"emei_sacred": {"name": "峨眉圣山", "north": "bashu_bamboo", "east": "western_plateau", "south": "wenjiang_garden"},
	"qingcheng_mtn": {"name": "青城山", "south": "shudao_mtn", "east": "xindu", "north": "dujiang_weir"},
	"dujiang_weir": {"name": "都江古堰", "south": "qingcheng_mtn", "north": "minjiang_river", "east": "xindu_field"},
	"minjiang_river": {"name": "岷江河谷", "east": "bashu_bamboo", "north": "shuangliu", "south": "dujiang_weir"},
	"xindu_field": {"name": "新都平原", "south": "xindu", "west": "dujiang_weir", "north": "zhongnan_mtn"},
	"wenjiang_garden": {"name": "温江花田", "north": "wenjiang", "west": "emei_sacred", "south": "yiling_gap"},
	"western_plateau": {"name": "西岭高原", "east": "shudao_mtn", "west": "emei_sacred", "north": "qinling_deep"},
	# 江陵周边野外
	"funiu_mtn": {"name": "伏牛山", "east": "dangyang", "south": "naja_sect", "west": "shennongjia"},
	"wudang_peak": {"name": "武当山", "north": "dangyang_plain", "east": "hanjiang_river", "west": "taiji_sect"},
	"shennongjia": {"name": "神农架", "east": "funiu_mtn", "south": "daba_mtn", "west": "yiling_gap"},
	"three_gorges": {"name": "三峡险滩", "north": "yiling", "south": "yunmeng_marsh", "west": "daba_mtn"},
	"yiling_gap": {"name": "夷陵峡谷", "east": "yiling", "south": "daba_mtn", "west": "shennongjia"},
	"dangyang_plain": {"name": "当阳平原", "north": "yanshi_plain", "south": "dangyang", "west": "wudang_peak"},
	"yunmeng_marsh": {"name": "云梦泽", "north": "three_gorges", "east": "dongting_lake", "south": "hanjiang_river"},
	"hanjiang_river": {"name": "汉江", "west": "wudang_peak", "north": "yunmeng_marsh", "east": "dongting_lake"},
	"daba_mtn": {"name": "大巴山", "north": "shennongjia", "west": "three_gorges", "south": "yunmeng_marsh"},
	# 七大门派
	"bagua_sect": {"name": "八卦门", "south": "beiling_mtn"},
	"flower_sect": {"name": "百花谷", "north": "wuyi_for"},
	"honglian_sect": {"name": "红莲教", "east": "zhongyuan_for"},
	"naja_sect": {"name": "那迦派", "north": "funiu_mtn"},
	"taiji_sect": {"name": "太极门", "east": "wudang_peak"},
	"xueshan_sect": {"name": "雪山派", "north": "qinling_deep"},
	"xiaoyao_sect": {"name": "逍遥宫", "north": "dongting_lake"},
}

const SCENE_FILES: Dictionary = {
	# 起始场景
	"pingan_town": "res://scenes/main.tscn",
	"zhongnan_mountain_foot": "res://scenes/zhongnan_mountain_foot.tscn",
	"baqiao_town": "res://scenes/baqiao_town.tscn",
	"wilderness_east": "res://scenes/wilderness_east.tscn",
	"heifeng_ridge": "res://scenes/heifeng_ridge.tscn",
	"wilderness_south": "res://scenes/wilderness_south.tscn",
	"shaolin_temple": "res://scenes/shaolin_temple.tscn",
	# 五大城池
	"changan": "res://scenes/changan.tscn",
	"luoyang": "res://scenes/luoyang.tscn",
	"linan": "res://scenes/linan.tscn",
	"chengdu": "res://scenes/chengdu.tscn",
	"jiangling": "res://scenes/jiangling.tscn",
	# 洛阳周边小镇
	"qinghe": "res://scenes/qinghe.tscn",
	"gongyi": "res://scenes/gongyi.tscn",
	"yanshi": "res://scenes/yanshi.tscn",
	"mengjin": "res://scenes/mengjin.tscn",
	# 长安周边小镇
	"fengxiang": "res://scenes/fengxiang.tscn",
	"xianyang": "res://scenes/xianyang.tscn",
	"weinan": "res://scenes/weinan.tscn",
	"lintong": "res://scenes/lintong.tscn",
	# 临安周边小镇
	"yuhang": "res://scenes/yuhang.tscn",
	"jiaxing": "res://scenes/jiaxing.tscn",
	"shaoxing": "res://scenes/shaoxing.tscn",
	# 成都周边小镇
	"shuangliu": "res://scenes/shuangliu.tscn",
	"xindu": "res://scenes/xindu.tscn",
	"wenjiang": "res://scenes/wenjiang.tscn",
	# 江陵周边小镇
	"yiling": "res://scenes/yiling.tscn",
	"dangyang": "res://scenes/dangyang.tscn",
	# 洛阳周边野外
	"beiling_mtn": "res://scenes/beiling_mtn.tscn",
	"songshan_peak": "res://scenes/songshan_peak.tscn",
	"luoshui_river": "res://scenes/luoshui_river.tscn",
	"huanghe_valley": "res://scenes/huanghe_valley.tscn",
	"taihang_range": "res://scenes/taihang_range.tscn",
	"yanshi_plain": "res://scenes/yanshi_plain.tscn",
	"mengjin_ford": "res://scenes/mengjin_ford.tscn",
	"yiluo_valley": "res://scenes/yiluo_valley.tscn",
	"zhongtiao_mtn": "res://scenes/zhongtiao_mtn.tscn",
	# 长安周边野外
	"qinling_deep": "res://scenes/qinling_deep.tscn",
	"zhongnan_mtn": "res://scenes/zhongnan_mtn.tscn",
	"zhongyuan_for": "res://scenes/zhongyuan_for.tscn",
	"weihe_river": "res://scenes/weihe_river.tscn",
	"longxi_desert": "res://scenes/longxi_desert.tscn",
	"huashan_cliff": "res://scenes/huashan_cliff.tscn",
	"tongguan_pass": "res://scenes/tongguan_pass.tscn",
	"lintong_bath": "res://scenes/lintong_bath.tscn",
	"xianyang_mound": "res://scenes/xianyang_mound.tscn",
	# 临安周边野外
	"jiangnan_marsh": "res://scenes/jiangnan_marsh.tscn",
	"wuyi_for": "res://scenes/wuyi_for.tscn",
	"dongting_lake": "res://scenes/dongting_lake.tscn",
	"qiantang_tide": "res://scenes/qiantang_tide.tscn",
	"tianmu_mtn": "res://scenes/tianmu_mtn.tscn",
	"taihu_lake": "res://scenes/taihu_lake.tscn",
	"huangshan_peak": "res://scenes/huangshan_peak.tscn",
	"shaoxing_water": "res://scenes/shaoxing_water.tscn",
	"jiaxing_canal": "res://scenes/jiaxing_canal.tscn",
	# 成都周边野外
	"shudao_mtn": "res://scenes/shudao_mtn.tscn",
	"bashu_bamboo": "res://scenes/bashu_bamboo.tscn",
	"emei_sacred": "res://scenes/emei_sacred.tscn",
	"qingcheng_mtn": "res://scenes/qingcheng_mtn.tscn",
	"dujiang_weir": "res://scenes/dujiang_weir.tscn",
	"minjiang_river": "res://scenes/minjiang_river.tscn",
	"xindu_field": "res://scenes/xindu_field.tscn",
	"wenjiang_garden": "res://scenes/wenjiang_garden.tscn",
	"western_plateau": "res://scenes/western_plateau.tscn",
	# 江陵周边野外
	"funiu_mtn": "res://scenes/funiu_mtn.tscn",
	"wudang_peak": "res://scenes/wudang_peak.tscn",
	"shennongjia": "res://scenes/shennongjia.tscn",
	"three_gorges": "res://scenes/three_gorges.tscn",
	"yiling_gap": "res://scenes/yiling_gap.tscn",
	"dangyang_plain": "res://scenes/dangyang_plain.tscn",
	"yunmeng_marsh": "res://scenes/yunmeng_marsh.tscn",
	"hanjiang_river": "res://scenes/hanjiang_river.tscn",
	"daba_mtn": "res://scenes/daba_mtn.tscn",
	# 七大门派
	"bagua_sect": "res://scenes/bagua_sect.tscn",
	"flower_sect": "res://scenes/flower_sect.tscn",
	"honglian_sect": "res://scenes/honglian_sect.tscn",
	"naja_sect": "res://scenes/naja_sect.tscn",
	"taiji_sect": "res://scenes/taiji_sect.tscn",
	"xueshan_sect": "res://scenes/xueshan_sect.tscn",
	"xiaoyao_sect": "res://scenes/xiaoyao_sect.tscn",
}

const REGION_DATA_ALIASES: Dictionary = {
	"wilderness_south": "huanghe_valley",
}

const ITEM_NAMES: Dictionary = {
	"item_huanghe_charm": "黄河平安符",
	"item_water_bandit_token": "水贼腰牌",
	"item_jinsuangyao": "金疮药",
	"item_resurrection_grass": "还魂草",
	"item_shadow_token": "影门令牌",
	"item_iron_sword": "铁剑",
	"item_coarse_cloth": "粗布衣",
}

const PINGAN_NPC_LAYOUT: Dictionary = {
	"li_muxue": Vector2(-420, -160),
	"cunzhang": Vector2(250, -190),
	"laofuzi": Vector2(430, -410),
	"wang_tiejiang": Vector2(-520, 170),
	"pingyizhi": Vector2(390, 180),
	"gelangtai": Vector2(610, 90),
	"daode_heshang": Vector2(120, -430),
	"xiaoyaozi": Vector2(-690, -420),
	"hexi": Vector2(650, 470),
	"yuweng": Vector2(850, 520),
	"laopopo": Vector2(-650, -40),
	"gate_guard": Vector2(30, 610),
	"patrol": Vector2(610, -20),
	"beggar": Vector2(-220, 150),
	"storyteller": Vector2(-120, 90),
	"daxia": Vector2(760, -280),
	"lin_yueru": Vector2(360, 420),
}

const PINGAN_AUTOSPAWN_IDS: Array[String] = ["lin_yueru"]

func _ready() -> void:
	var scene_state = get_node_or_null("/root/SceneState")
	if scene_state:
		_current_scene_name = scene_state.current_scene_name
		_entered_from_transition = scene_state.spawn_position_set or _current_scene_name != "pingan_town"
		_load_runtime_state(scene_state)
	if not _entered_from_transition:
		_current_scene_name = _infer_scene_name_from_root(_current_scene_name)
		_entered_from_transition = _current_scene_name != "pingan_town"
	_setup_tile_map()
	_init_dialogues()
	_build_menu()
	_build_hud()
	_build_dialogue_box()
	_build_quest_tracker()
	_build_combat_ui()
	_setup_player()
	_setup_npcs()
	_connect_signals()
	_setup_player_spawn()
	_update_direction_hints()
	_update_player_hud()
	if _entered_from_transition:
		_hide_menu()
	else:
		_show_menu()

func _load_runtime_state(scene_state: Node) -> void:
	if scene_state.game_flags.size() > 0:
		_game_flags = scene_state.game_flags.duplicate(true)
	if scene_state.player_stats.size() > 0:
		_player_stats = scene_state.player_stats.duplicate(true)
	if scene_state.inventory.size() > 0:
		_inventory = scene_state.inventory.duplicate(true)
	_current_quest_id = scene_state.current_quest_id
	_quest_active = scene_state.quest_active
	_vertical_quest_stage = scene_state.vertical_quest_stage

func _save_runtime_state() -> void:
	var scene_state = get_node_or_null("/root/SceneState")
	if not scene_state:
		return
	scene_state.game_flags = _game_flags.duplicate(true)
	scene_state.player_stats = _player_stats.duplicate(true)
	scene_state.inventory = _inventory.duplicate(true)
	scene_state.current_quest_id = _current_quest_id
	scene_state.quest_active = _quest_active
	scene_state.vertical_quest_stage = _vertical_quest_stage

func _infer_scene_name_from_root(fallback: String) -> String:
	var name_map: Dictionary = {
		"Main": "pingan_town",
		"WildernessSouth": "wilderness_south",
		"WildernessEast": "wilderness_east",
		"HeifengRidge": "heifeng_ridge",
	}
	if name_map.has(name):
		return name_map[name]
	var snake := ""
	for i in range(name.length()):
		var ch := name.substr(i, 1)
		if i > 0 and ch == ch.to_upper() and ch != ch.to_lower():
			snake += "_"
		snake += ch.to_lower()
	if SCENE_INFO.has(snake):
		return snake
	return fallback

func _setup_tile_map() -> void:
	var world_layer = get_node_or_null("WorldLayer")
	if not world_layer:
		world_layer = Node2D.new()
		world_layer.name = "WorldLayer"
		world_layer.z_index = -1
		add_child(world_layer)
		move_child(world_layer, 0)
	var tile_map_node = get_node_or_null("WorldLayer/SceneTileMap")
	if not tile_map_node:
		var tile_map_script = load("res://scripts/world/scene_tile_map.gd")
		tile_map_node = Node2D.new()
		tile_map_node.name = "SceneTileMap"
		if tile_map_script:
			tile_map_node.set_script(tile_map_script)
		world_layer.add_child(tile_map_node)
	if tile_map_node and tile_map_node.has_method("generate_map"):
		tile_map_node.setup(world_layer)
		var scene_type = _get_scene_type()
		tile_map_node.generate_map(scene_type, 50, 50, _current_scene_name)

func _get_region_data_key() -> String:
	return REGION_DATA_ALIASES.get(_current_scene_name, _current_scene_name)

func _get_scene_type() -> String:
	if _current_scene_name in ["changan", "luoyang", "linan", "chengdu", "jiangling"]:
		return "city"
	elif _current_scene_name.ends_with("_sect"):
		return "sect"
	elif _current_scene_name in ["wilderness_east", "wilderness_south", "heifeng_ridge"] or "_mtn" in _current_scene_name or "_river" in _current_scene_name or "_valley" in _current_scene_name or "_for" in _current_scene_name or "_plain" in _current_scene_name or "_desert" in _current_scene_name or "_marsh" in _current_scene_name or "_lake" in _current_scene_name:
		return "wilderness"
	else:
		return "town"

func _setup_player_spawn() -> void:
	var scene_state = get_node_or_null("/root/SceneState")
	if player and scene_state:
		var spawn = scene_state.get_spawn_position()
		if spawn != Vector2.ZERO:
			player.global_position = spawn
	if _entered_from_transition:
		_force_playing_after_transition()
	_check_for_scene_encounter()
	_check_vertical_slice_start()

func _force_playing_after_transition() -> void:
	_transitioning = false
	is_game_started = true
	if _menu_canvas:
		_menu_canvas.visible = false
	if _hud_canvas:
		_hud_canvas.visible = true

func _process(delta: float) -> void:
	if _combat_active:
		_poll_combat_input()
		return
	if _dialogue_active:
		_poll_dialogue_input()
		return
	if not is_game_started:
		_poll_menu_input()
		if DisplayServer.get_name() != "headless":
			_auto_start_timer += delta
			if _auto_start_timer >= _auto_start_delay:
				_start_new_game()
		return
	_poll_game_input(delta)
	_check_nearby_npcs()

func _init_dialogues() -> void:
	_npc_dialogues = {}
	if not NpcData:
		return
	var region_npcs: Array = NpcData.get_region_npcs(_get_region_data_key())
	if region_npcs.is_empty():
		region_npcs = NpcData.get_region_npcs("pingan_town")
	for npc in region_npcs:
		var npc_id: String = npc.get("id", "")
		var dialogues: Array = npc.get("dialogues", [])
		if not npc_id.is_empty() and dialogues.size() > 0:
			_npc_dialogues[npc_id] = {
				"name": npc.get("name", "???"),
				"title": npc.get("title", ""),
				"lines": dialogues
			}

func _poll_menu_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		_menu_index = (_menu_index - 1 + _menu_items.size()) % _menu_items.size()
		_update_menu_highlight()
		_auto_start_timer = 0.0
	elif Input.is_action_just_pressed("ui_down"):
		_menu_index = (_menu_index + 1) % _menu_items.size()
		_update_menu_highlight()
		_auto_start_timer = 0.0
	elif Input.is_action_just_pressed("ui_accept"):
		if _menu_items.size() > 0:
			_menu_items[_menu_index]["action"].call()
		_auto_start_timer = 0.0

func _poll_dialogue_input() -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
		_dialogue_current_index += 1
		if _dialogue_current_index >= _dialogue_queue.size():
			_close_dialogue()
		else:
			_show_dialogue_line()

func _poll_game_input(delta: float) -> void:
	if _transitioning:
		return
	
	var direction := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		player.global_position += direction * player_speed * delta
	_update_player_sprite(direction, delta)
	
	_check_scene_transition()
	
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("menu"):
		_toggle_menu()
	if Input.is_action_just_pressed("inventory"):
		_show_inventory_summary()
	if Input.is_action_just_pressed("quests"):
		_show_quest_summary()
	if Input.is_action_just_pressed("skills"):
		_show_notification("武学：基础拳脚 Lv.1 · 黄河线胜利后会开放第一本武学残页")

func _check_scene_transition() -> void:
	if not player or _transitioning:
		return
	
	var connections = SCENE_INFO.get(_current_scene_name, {})
	if connections.is_empty():
		return
	
	var pos = player.global_position
	var threshold = 650.0
	
	if pos.y < -threshold and connections.has("north"):
		_transition_to_scene(connections["north"], "south")
	elif pos.y > threshold and connections.has("south"):
		_transition_to_scene(connections["south"], "north")
	elif pos.x < -threshold and connections.has("west"):
		_transition_to_scene(connections["west"], "east")
	elif pos.x > threshold and connections.has("east"):
		_transition_to_scene(connections["east"], "west")

func _transition_to_scene(target_scene: String, spawn_direction: String = "") -> void:
	if _transitioning:
		return
	
	_transitioning = true
	_show_notification("正在前往 %s..." % SCENE_INFO.get(target_scene, {}).get("name", "未知区域"), 1.0)
	
	await get_tree().create_timer(0.5).timeout
	
	var scene_path = SCENE_FILES.get(target_scene, "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_show_notification("前路尚未开放")
		if player:
			player.global_position = player.global_position.clamp(Vector2(-560, -560), Vector2(560, 560))
		_transitioning = false
		return
	
	var scene_state = get_node_or_null("/root/SceneState")
	if scene_state:
		_save_runtime_state()
		scene_state.current_scene_name = target_scene
		match spawn_direction:
			"north":
				scene_state.set_spawn_position(Vector2(0, 500))
			"south":
				scene_state.set_spawn_position(Vector2(0, -500))
			"east":
				scene_state.set_spawn_position(Vector2(-500, 0))
			"west":
				scene_state.set_spawn_position(Vector2(500, 0))
			_:
				scene_state.set_spawn_position(Vector2.ZERO)
	
	var packed_scene = load(scene_path)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		_transitioning = false

func _check_for_scene_encounter() -> void:
	if _current_scene_name == "wilderness_south":
		return
	var encounter_system = null
	if Engine.has_meta("EncounterSystem"):
		encounter_system = Engine.get_meta("EncounterSystem")
	if encounter_system == null:
		encounter_system = get_node_or_null("/root/EncounterSystem")
	
	if encounter_system == null or player == null:
		return
	
	var player_level = 1
	if player.has_method("get_level"):
		player_level = player.get_level()
	
	var zone_type = "wilderness"
	if "town" in _current_scene_name:
		zone_type = "town"
	elif "sect" in _current_scene_name:
		zone_type = "sect"
	elif "city" in _current_scene_name or _current_scene_name in ["changan", "luoyang", "linan", "chengdu", "jiangling"]:
		zone_type = "city"
	
	var encounter = encounter_system.check_for_encounter(player_level, zone_type, _current_scene_name)
	if not encounter.is_empty():
		var encounter_type = encounter.get("type", "")
		match encounter_type:
			"random_npc":
				var npc_name = encounter.get("npc_type", "神秘人")
				_show_notification("你遇到了 %s" % npc_name, 2.0)
			"treasure":
				_show_notification("你发现了散落的宝物！", 2.0)
			"ambush":
				_show_notification("有埋伏！", 2.0)
			"merchant":
				var merchant_name = encounter.get("merchant_name", "商人")
				_show_notification("遇到行商 %s" % merchant_name, 2.0)
			"wounded_warrior":
				var warrior_name = encounter.get("warrior_name", "侠客")
				_show_notification("%s 身受重伤..." % warrior_name, 2.0)
			"special_event":
				var event_title = encounter.get("title", "奇遇")
				_show_notification("奇遇：%s" % event_title, 2.0)

func _check_vertical_slice_start() -> void:
	if _current_scene_name != "wilderness_south":
		_check_chapter_one_scene_progress()
		return
	if _game_flags.get("huanghe_quest_complete", false):
		return
	_start_huanghe_vertical_quest()

func _check_chapter_one_scene_progress() -> void:
	if _current_scene_name != "heifeng_ridge":
		return
	if _game_flags.get("chapter1_complete", false):
		return
	if _current_quest_id.is_empty():
		_start_chapter_one_tracking(false)
	var stage := int(_game_flags.get("chapter1_stage", 0))
	if stage >= 2 and stage < 3:
		_advance_chapter_one_stage(3)
		_complete_objective("visit_blackwind_ridge")
		_show_notification("已抵达黑风岭：寻找还魂草，也留意路上的异动", 3.0)

func _start_chapter_one_tracking(show_notice: bool = true) -> void:
	_quest_active = true
	_current_quest_id = "main_001_save_mother"
	_game_flags["chapter1_stage"] = maxi(int(_game_flags.get("chapter1_stage", 0)), 0)
	_quest_tracker_canvas.visible = true
	_update_quest_tracker()
	if show_notice:
		_show_notification("新任务：少年侠影", 2.2)

func _advance_chapter_one_stage(stage: int) -> void:
	_game_flags["chapter1_stage"] = maxi(int(_game_flags.get("chapter1_stage", 0)), stage)
	_update_quest_tracker()

func _start_huanghe_vertical_quest() -> void:
	if _quest_active and _current_quest_id == "huanghe_first_crossing":
		return
	_quest_active = true
	_current_quest_id = "huanghe_first_crossing"
	_vertical_quest_stage = int(_game_flags.get("huanghe_stage", 0))
	_quest_tracker_canvas.visible = true
	_update_quest_tracker()
	_show_notification("新任务：黄河古道", 2.2)

func _advance_huanghe_stage(stage: int) -> void:
	_vertical_quest_stage = maxi(_vertical_quest_stage, stage)
	_game_flags["huanghe_stage"] = _vertical_quest_stage
	_update_quest_tracker()

func _build_menu() -> void:
	_menu_canvas = CanvasLayer.new()
	_menu_canvas.name = "MenuCanvas"
	_menu_canvas.layer = 50
	add_child(_menu_canvas)

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(bg)

	var grad := ColorRect.new()
	grad.color = Color(0.10, 0.10, 0.14, 0.25)
	grad.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grad.offset_top = -220.0
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(grad)

	var title := Label.new()
	title.text = "侠 影 江 湖"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	title.add_theme_font_size_override("font_size", 96)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_right = 1.0
	title.offset_top = 100.0
	title.offset_bottom = 220.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "水墨武侠 · 开放世界RPG"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.50, 0.47, 0.40, 0.6))
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 224.0
	subtitle.offset_bottom = 244.0
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(subtitle)

	var line := ColorRect.new()
	line.color = COLOR_GOLD
	line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	line.anchor_left = 0.35
	line.anchor_right = 0.65
	line.offset_top = 260.0
	line.offset_bottom = 261.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(line)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -160.0
	vbox.offset_top = -40.0
	vbox.offset_right = 160.0
	vbox.offset_bottom = 160.0
	vbox.add_theme_constant_override("separation", 28)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(vbox)

	var items: Array = [
		{"text": "初入江湖", "action": _start_new_game},
		{"text": "继续征程", "action": _load_game},
		{"text": "江湖设定", "action": _show_settings},
		{"text": "退出游戏", "action": _quit_game},
	]

	for item in items:
		var lbl := Label.new()
		lbl.text = item["text"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)
		_menu_items.append({"label": lbl, "action": item["action"], "text": item["text"]})

	var hint := Label.new()
	hint.text = "↑↓ 选择 | Enter 确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.35, 0.33, 0.30, 0.7))
	hint.add_theme_font_size_override("font_size", 12)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.anchor_right = 1.0
	hint.offset_top = -45.0
	hint.offset_bottom = -30.0
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_canvas.add_child(hint)

	_update_menu_highlight()

func _update_menu_highlight() -> void:
	for i in range(_menu_items.size()):
		var lbl: Label = _menu_items[i]["label"]
		var base_text: String = _menu_items[i]["text"]
		if i == _menu_index:
			lbl.text = "▸ " + base_text
			lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
		else:
			lbl.text = base_text
			lbl.add_theme_color_override("font_color", Color(0.40, 0.38, 0.35, 1))

func _build_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.name = "HUDCanvas"
	_hud_canvas.layer = 10
	add_child(_hud_canvas)

	var panel_bg := ColorRect.new()
	panel_bg.color = COLOR_PANEL
	panel_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_bg.offset_left = 12.0
	panel_bg.offset_top = 12.0
	panel_bg.offset_right = 252.0
	panel_bg.offset_bottom = 132.0
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(panel_bg)

	var name_lbl := Label.new()
	name_lbl.text = "李少侠"
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	name_lbl.offset_left = 22.0
	name_lbl.offset_top = 18.0
	name_lbl.offset_right = 130.0
	name_lbl.offset_bottom = 44.0
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(name_lbl)
	_hud_labels["name"] = name_lbl

	var level_lbl := Label.new()
	level_lbl.text = "Lv.1"
	level_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	level_lbl.add_theme_font_size_override("font_size", 13)
	level_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	level_lbl.offset_left = 130.0
	level_lbl.offset_top = 24.0
	level_lbl.offset_right = 244.0
	level_lbl.offset_bottom = 44.0
	level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(level_lbl)
	_hud_labels["level"] = level_lbl

	var hp_text := Label.new()
	hp_text.text = "气血 100/100"
	hp_text.add_theme_color_override("font_color", Color(0.85, 0.55, 0.50, 1))
	hp_text.add_theme_font_size_override("font_size", 11)
	hp_text.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_text.offset_left = 22.0
	hp_text.offset_top = 44.0
	hp_text.offset_right = 244.0
	hp_text.offset_bottom = 58.0
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(hp_text)
	_hud_labels["hp"] = hp_text

	var hp_bar_bg := ColorRect.new()
	hp_bar_bg.color = Color(0.25, 0.08, 0.06, 1)
	hp_bar_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_bar_bg.offset_left = 22.0
	hp_bar_bg.offset_top = 58.0
	hp_bar_bg.offset_right = 202.0
	hp_bar_bg.offset_bottom = 62.0
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(hp_bar_bg)

	var hp_bar := ColorRect.new()
	hp_bar.color = COLOR_HP
	hp_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_bar.offset_left = 22.0
	hp_bar.offset_top = 58.0
	hp_bar.offset_right = 202.0
	hp_bar.offset_bottom = 62.0
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(hp_bar)
	_hud_labels["hp_bar"] = hp_bar

	var mp_text := Label.new()
	mp_text.text = "内力 50/50"
	mp_text.add_theme_color_override("font_color", Color(0.50, 0.65, 0.85, 1))
	mp_text.add_theme_font_size_override("font_size", 11)
	mp_text.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mp_text.offset_left = 22.0
	mp_text.offset_top = 66.0
	mp_text.offset_right = 244.0
	mp_text.offset_bottom = 80.0
	mp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(mp_text)
	_hud_labels["mp"] = mp_text

	var mp_bar_bg := ColorRect.new()
	mp_bar_bg.color = Color(0.06, 0.15, 0.25, 1)
	mp_bar_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mp_bar_bg.offset_left = 22.0
	mp_bar_bg.offset_top = 80.0
	mp_bar_bg.offset_right = 202.0
	mp_bar_bg.offset_bottom = 84.0
	mp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(mp_bar_bg)

	var mp_bar := ColorRect.new()
	mp_bar.color = COLOR_MP
	mp_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mp_bar.offset_left = 22.0
	mp_bar.offset_top = 80.0
	mp_bar.offset_right = 202.0
	mp_bar.offset_bottom = 84.0
	mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(mp_bar)
	_hud_labels["mp_bar"] = mp_bar

	var gold_lbl := Label.new()
	gold_lbl.text = "银两 100"
	gold_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	gold_lbl.add_theme_font_size_override("font_size", 12)
	gold_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold_lbl.offset_left = 22.0
	gold_lbl.offset_top = 92.0
	gold_lbl.offset_right = 244.0
	gold_lbl.offset_bottom = 108.0
	gold_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(gold_lbl)
	_hud_labels["gold"] = gold_lbl

	var location_lbl := Label.new()
	location_lbl.text = _get_scene_display_name()
	location_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	location_lbl.add_theme_font_size_override("font_size", 11)
	location_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	location_lbl.offset_left = 22.0
	location_lbl.offset_top = 110.0
	location_lbl.offset_right = 244.0
	location_lbl.offset_bottom = 126.0
	location_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(location_lbl)
	_hud_labels["location"] = location_lbl

	var controls := Label.new()
	controls.text = "WASD 移动 | E 交互 | I 背包 | K 技能 | Q 任务 | Esc 菜单"
	controls.add_theme_color_override("font_color", Color(0.35, 0.33, 0.30, 0.7))
	controls.add_theme_font_size_override("font_size", 11)
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 12.0
	controls.offset_top = -28.0
	controls.offset_right = 700.0
	controls.offset_bottom = -12.0
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(controls)

	var interact_wrap := ColorRect.new()
	interact_wrap.color = Color(0.05, 0.05, 0.08, 0.6)
	interact_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	interact_wrap.offset_top = -92.0
	interact_wrap.offset_bottom = -62.0
	interact_wrap.visible = false
	interact_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(interact_wrap)
	_hud_labels["interact_bg"] = interact_wrap

	var interact := Label.new()
	interact.text = "按 E 交互"
	interact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	interact.add_theme_font_size_override("font_size", 20)
	interact.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	interact.offset_top = -90.0
	interact.offset_bottom = -65.0
	interact.visible = false
	interact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(interact)
	_hud_labels["interact"] = interact

	var direction_hints := HBoxContainer.new()
	direction_hints.name = "DirectionHints"
	direction_hints.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	direction_hints.offset_top = -55.0
	direction_hints.offset_bottom = -35.0
	direction_hints.add_theme_constant_override("separation", 20)
	direction_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(direction_hints)
	_hud_labels["direction_hints"] = direction_hints

	_update_direction_hints()

	_hud_canvas.visible = false

func _get_scene_display_name() -> String:
	var info = SCENE_INFO.get(_current_scene_name, {})
	return info.get("name", "平安镇")

func _update_direction_hints() -> void:
	var hints_container: HBoxContainer = _hud_labels.get("direction_hints")
	if not hints_container:
		return
	
	for child in hints_container.get_children():
		child.queue_free()
	
	var connections = SCENE_INFO.get(_current_scene_name, {})
	var dir_names = {"north": "北", "south": "南", "east": "东", "west": "西"}
	
	for dir in ["north", "south", "east", "west"]:
		if connections.has(dir):
			var lbl := Label.new()
			lbl.text = "%s → %s" % [dir_names.get(dir, dir), SCENE_INFO.get(connections[dir], {}).get("name", "???")]
			lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 1))
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hints_container.add_child(lbl)

func _build_dialogue_box() -> void:
	_dialogue_canvas = CanvasLayer.new()
	_dialogue_canvas.name = "DialogueCanvas"
	_dialogue_canvas.layer = 30
	add_child(_dialogue_canvas)

	var box_bg := ColorRect.new()
	box_bg.color = COLOR_PANEL
	box_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box_bg.offset_top = -160.0
	box_bg.offset_bottom = 0.0
	box_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_canvas.add_child(box_bg)

	var border_top := ColorRect.new()
	border_top.color = COLOR_GOLD
	border_top.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	border_top.offset_top = -161.0
	border_top.offset_bottom = -160.0
	border_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_canvas.add_child(border_top)

	var portrait_sprite := TextureRect.new()
	portrait_sprite.name = "PortraitSprite"
	portrait_sprite.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait_sprite.offset_left = 24.0
	portrait_sprite.offset_top = -152.0
	portrait_sprite.offset_right = 56.0
	portrait_sprite.offset_bottom = -120.0
	portrait_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_sprite.visible = false
	portrait_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_canvas.add_child(portrait_sprite)
	_dialogue_labels["portrait"] = portrait_sprite

	var name_lbl := Label.new()
	name_lbl.text = ""
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left = 64.0
	name_lbl.offset_top = -154.0
	name_lbl.offset_right = 500.0
	name_lbl.offset_bottom = -128.0
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_canvas.add_child(name_lbl)
	_dialogue_labels["name"] = name_lbl

	var text_lbl := Label.new()
	text_lbl.text = ""
	text_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	text_lbl.add_theme_font_size_override("font_size", 18)
	text_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	text_lbl.offset_left = 24.0
	text_lbl.offset_top = -118.0
	text_lbl.offset_right = -24.0
	text_lbl.offset_bottom = -28.0
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_canvas.add_child(text_lbl)
	_dialogue_labels["text"] = text_lbl

	var hint_lbl := Label.new()
	hint_lbl.text = "▼ 继续"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.36, 0.7))
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_lbl.offset_left = -120.0
	hint_lbl.offset_top = -22.0
	hint_lbl.offset_right = -20.0
	hint_lbl.offset_bottom = -6.0
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_canvas.add_child(hint_lbl)
	_dialogue_labels["hint"] = hint_lbl

	_dialogue_canvas.visible = false

func _build_quest_tracker() -> void:
	_quest_tracker_canvas = CanvasLayer.new()
	_quest_tracker_canvas.name = "QuestTrackerCanvas"
	_quest_tracker_canvas.layer = 25
	add_child(_quest_tracker_canvas)

	var panel_bg := ColorRect.new()
	panel_bg.color = COLOR_PANEL
	panel_bg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel_bg.offset_left = -264.0
	panel_bg.offset_top = 12.0
	panel_bg.offset_right = -12.0
	panel_bg.offset_bottom = 180.0
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker_canvas.add_child(panel_bg)

	var border_top := ColorRect.new()
	border_top.color = COLOR_GOLD
	border_top.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	border_top.offset_left = -264.0
	border_top.offset_top = 11.0
	border_top.offset_right = -12.0
	border_top.offset_bottom = 12.0
	border_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker_canvas.add_child(border_top)

	var quest_title := Label.new()
	quest_title.text = "当前任务"
	quest_title.add_theme_color_override("font_color", COLOR_GOLD)
	quest_title.add_theme_font_size_override("font_size", 14)
	quest_title.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_title.offset_left = -254.0
	quest_title.offset_top = 18.0
	quest_title.offset_right = -22.0
	quest_title.offset_bottom = 38.0
	quest_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker_canvas.add_child(quest_title)

	_quest_tracker_label = Label.new()
	_quest_tracker_label.text = "暂无任务"
	_quest_tracker_label.add_theme_color_override("font_color", COLOR_TEXT)
	_quest_tracker_label.add_theme_font_size_override("font_size", 15)
	_quest_tracker_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_tracker_label.offset_left = -254.0
	_quest_tracker_label.offset_top = 42.0
	_quest_tracker_label.offset_right = -22.0
	_quest_tracker_label.offset_bottom = 66.0
	_quest_tracker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker_canvas.add_child(_quest_tracker_label)

	_quest_objective_label = Label.new()
	_quest_objective_label.text = ""
	_quest_objective_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_quest_objective_label.add_theme_font_size_override("font_size", 13)
	_quest_objective_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_objective_label.offset_left = -254.0
	_quest_objective_label.offset_top = 70.0
	_quest_objective_label.offset_right = -22.0
	_quest_objective_label.offset_bottom = 172.0
	_quest_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker_canvas.add_child(_quest_objective_label)
	
	_quest_tracker_canvas.visible = false

func _build_combat_ui() -> void:
	_combat_canvas = CanvasLayer.new()
	_combat_canvas.name = "CombatCanvas"
	_combat_canvas.layer = 40
	add_child(_combat_canvas)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.03, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(shade)

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.18, 0.92)
	style.set_corner_radius_all(8)
	style.border_width_bottom = 0
	style.border_width_top = 0
	style.border_width_left = 0
	style.border_width_right = 0
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -390.0
	panel.offset_top = -210.0
	panel.offset_right = 390.0
	panel.offset_bottom = 210.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(panel)

	var gold_line := ColorRect.new()
	gold_line.color = COLOR_GOLD
	gold_line.set_anchors_preset(Control.PRESET_CENTER)
	gold_line.offset_left = -390.0
	gold_line.offset_top = -210.0
	gold_line.offset_right = 390.0
	gold_line.offset_bottom = -209.0
	gold_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(gold_line)

	var title := Label.new()
	title.text = "遭遇战"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -360.0
	title.offset_top = -192.0
	title.offset_right = 360.0
	title.offset_bottom = -156.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(title)
	_combat_labels["title"] = title

	var enemy := Label.new()
	enemy.text = ""
	enemy.add_theme_color_override("font_color", COLOR_TEXT)
	enemy.add_theme_font_size_override("font_size", 18)
	enemy.set_anchors_preset(Control.PRESET_CENTER)
	enemy.offset_left = -350.0
	enemy.offset_top = -140.0
	enemy.offset_right = 350.0
	enemy.offset_bottom = -108.0
	enemy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(enemy)
	_combat_labels["enemy"] = enemy

	var player_info := Label.new()
	player_info.text = ""
	player_info.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	player_info.add_theme_font_size_override("font_size", 16)
	player_info.set_anchors_preset(Control.PRESET_CENTER)
	player_info.offset_left = -350.0
	player_info.offset_top = -108.0
	player_info.offset_right = 350.0
	player_info.offset_bottom = -76.0
	player_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(player_info)
	_combat_labels["player"] = player_info

	var log_bg := ColorRect.new()
	log_bg.color = Color(0.06, 0.06, 0.10, 0.6)
	log_bg.set_anchors_preset(Control.PRESET_CENTER)
	log_bg.offset_left = -360.0
	log_bg.offset_top = -58.0
	log_bg.offset_right = 360.0
	log_bg.offset_bottom = 130.0
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(log_bg)

	var log_lbl := Label.new()
	log_lbl.text = ""
	log_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	log_lbl.add_theme_font_size_override("font_size", 16)
	log_lbl.set_anchors_preset(Control.PRESET_CENTER)
	log_lbl.offset_left = -350.0
	log_lbl.offset_top = -52.0
	log_lbl.offset_right = 350.0
	log_lbl.offset_bottom = 124.0
	log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(log_lbl)
	_combat_labels["log"] = log_lbl

	var hint := Label.new()
	hint.text = "Enter 普攻 | K 内劲 | I 金疮药 | Esc 退让"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", COLOR_GOLD)
	hint.add_theme_font_size_override("font_size", 16)
	hint.set_anchors_preset(Control.PRESET_CENTER)
	hint.offset_left = -360.0
	hint.offset_top = 150.0
	hint.offset_right = 360.0
	hint.offset_bottom = 182.0
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_canvas.add_child(hint)
	_combat_labels["hint"] = hint

	_combat_canvas.visible = false

func _setup_player() -> void:
	player = get_node_or_null("PlayerLayer/Player")
	if not player:
		var player_layer = get_node_or_null("PlayerLayer")
		if not player_layer:
			player_layer = Node2D.new()
			player_layer.name = "PlayerLayer"
			player_layer.z_index = 10
			add_child(player_layer)
		player = CharacterBody2D.new()
		player.name = "Player"
		player_layer.add_child(player)
		var sprite := Sprite2D.new()
		sprite.name = "PlayerSprite"
		sprite.scale = Vector2(2.6, 2.6)
		player.add_child(sprite)
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 16.0
		collision.shape = shape
		player.add_child(collision)
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	if player:
		player.set_meta("type", "player")
		player.z_index = 20
		var camera: Camera2D = player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = true
			camera.make_current()
		_apply_player_texture()

func _apply_player_texture() -> void:
	if not player:
		return
	var sprite: Sprite2D = player.get_node_or_null("PlayerSprite")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "PlayerSprite"
		sprite.scale = Vector2(2.8, 2.8)
		player.add_child(sprite)
	var texture_path = "res://assets/ink_chars/player_xiaoyao_stand.png"
	if not ResourceLoader.exists(texture_path):
		texture_path = "res://assets/sprites/chinese_chars/char0_dir0_frame0.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.centered = true
		sprite.z_index = 2
		sprite.visible = true

func _update_player_sprite(direction: Vector2, delta: float) -> void:
	if not player:
		return
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			_player_dir = 2 if direction.x > 0 else 1
		else:
			_player_dir = 0 if direction.y > 0 else 3
		_player_anim_timer += delta
		if _player_anim_timer >= 0.3:
			_player_anim_timer = 0.0
			_player_frame = (_player_frame + 1) % 4
	else:
		_player_frame = 0
	
	var sprite: Sprite2D = player.get_node_or_null("PlayerSprite")
	if not sprite:
		return
	var is_walking := direction != Vector2.ZERO and _player_frame % 2 == 1
	if is_walking:
		var walk_path := "res://assets/ink_chars/player_xiaoyao_walk.png"
		if ResourceLoader.exists(walk_path):
			sprite.texture = load(walk_path)
		else:
			var box_path := "res://assets/sprites/chinese_chars/char0_dir%d_frame%d.png" % [_player_dir, _player_frame]
			if ResourceLoader.exists(box_path):
				sprite.texture = load(box_path)
	else:
		var stand_path := "res://assets/ink_chars/player_xiaoyao_stand.png"
		if ResourceLoader.exists(stand_path):
			sprite.texture = load(stand_path)
		else:
			var box_path := "res://assets/sprites/chinese_chars/char0_dir%d_frame0.png" % _player_dir
			if ResourceLoader.exists(box_path):
				sprite.texture = load(box_path)

func _setup_npcs() -> void:
	var npc_configs: Dictionary = {
		# 核心NPC
		"Xiaoyaozi": {"npc_id": "xiaoyaozi", "npc_name": "逍遥子"},
		"DaodeHeshang": {"npc_id": "daode_heshang", "npc_name": "道德和尚"},
		"Laofuzi": {"npc_id": "laofuzi", "npc_name": "老夫子"},
		"Cunzhang": {"npc_id": "cunzhang", "npc_name": "村长"},
		"WangTiejiang": {"npc_id": "wang_tiejiang", "npc_name": "王铁匠"},
		"LiMuxue": {"npc_id": "li_muxue", "npc_name": "李慕雪"},
		"Linyueru": {"npc_id": "lin_yueru", "npc_name": "林月如"},
		
		# 重要配角 (NPC-039到053)
		"Hetieshou": {"npc_id": "hetieshou", "npc_name": "何铁手"},
		"Gelangtai": {"npc_id": "gelangtai", "npc_name": "葛朗台"},
		"Pingyizhi": {"npc_id": "pingyizhi", "npc_name": "平一指"},
		"Bukua": {"npc_id": "bukua", "npc_name": "捕快"},
		"Hexi": {"npc_id": "hexi", "npc_name": "何喜"},
		"Xiaocaifeng": {"npc_id": "xiaocaifeng", "npc_name": "小裁缝"},
		"Hecaifeng": {"npc_id": "hecaifeng", "npc_name": "何裁缝"},
		"Maihuanv": {"npc_id": "maihuanv", "npc_name": "卖花女"},
		"Tufu": {"npc_id": "tufu", "npc_name": "屠夫"},
		"Chushi": {"npc_id": "chushi", "npc_name": "厨师"},
		"Gongzige": {"npc_id": "gongzige", "npc_name": "公子哥"},
		"Shutong": {"npc_id": "shutong", "npc_name": "书童"},
		"Laopopo": {"npc_id": "laopopo", "npc_name": "老婆婆"},
		"Maoshiqi": {"npc_id": "maoshiqi", "npc_name": "茅十七"},
		"Daxia": {"npc_id": "daxia", "npc_name": "大侠"},
		
		# 普通村民
		"Nongfu": {"npc_id": "nongfu", "npc_name": "老农"},
		"Yuweng": {"npc_id": "yuweng", "npc_name": "渔翁"},
		"Lieren": {"npc_id": "lieren", "npc_name": "猎人"},
		"Xiuniang": {"npc_id": "xiuniang", "npc_name": "绣娘"},
		"Fangniuwang": {"npc_id": "fangniuwang", "npc_name": "牧童"},
		
		# 商人
		"WeaponMerchant": {"npc_id": "weapon_merchant", "npc_name": "何铁手"},
		"ArmorMerchant": {"npc_id": "armor_merchant", "npc_name": "何裁缝"},
		"MedicineMerchant": {"npc_id": "medicine_merchant", "npc_name": "平一指"},
		"FoodMerchant": {"npc_id": "food_merchant", "npc_name": "平阿四"},
		"BookMerchant": {"npc_id": "book_merchant", "npc_name": "老夫子"},
		"GroceryMerchant": {"npc_id": "grocery_merchant", "npc_name": "小商贩"},
		"BlackMarket": {"npc_id": "black_market", "npc_name": "阎商"},
		"Banker": {"npc_id": "banker", "npc_name": "葛朗台"},
		
		# 守卫
		"GateGuard": {"npc_id": "gate_guard", "npc_name": "守卫甲"},
		"Patrol": {"npc_id": "patrol", "npc_name": "巡捕"},
		"ImperialGuard": {"npc_id": "imperial_guard", "npc_name": "禁军校尉"},
		
		# 武师
		"BoxingMaster": {"npc_id": "boxing_master", "npc_name": "铁拳张"},
		"SwordMaster": {"npc_id": "sword_master", "npc_name": "剑痴李"},
		"KnifeMaster": {"npc_id": "knife_master", "npc_name": "快刀王"},
		"ShurikenMaster": {"npc_id": "shuriken_master", "npc_name": "飞针孙"},
		"InnerEnergyMaster": {"npc_id": "inner_energy_master", "npc_name": "养气陈"},
		"QinggongMaster": {"npc_id": "qinggong_master", "npc_name": "燕子刘"},
		
		# 流浪者
		"Wanderer": {"npc_id": "wanderer", "npc_name": "过路人"},
		"Beggar": {"npc_id": "beggar", "npc_name": "乞儿"},
		"Storyteller": {"npc_id": "storyteller", "npc_name": "说书先生"},
		"FortuneTeller": {"npc_id": "fortune_teller", "npc_name": "算命瞎子"},
	}
	var npc_layers: Array = [get_node_or_null("NPCLayer"), get_node_or_null("NPCs")]
	for npc_layer in npc_layers:
		if not npc_layer:
			continue
		for npc in npc_layer.get_children():
			if npc is Node2D:
				var config: Dictionary = npc_configs.get(npc.name, {})
				if config.has("npc_id"):
					npc.set_meta("npc_id", config["npc_id"])
				if config.has("npc_name"):
					npc.set_meta("npc_name", config["npc_name"])
				if npc.has_meta("npc_id") or npc.get_child_count() > 0:
					npc.add_to_group("npcs")
	_apply_scene_npc_layout()
	_spawn_region_npcs_from_data()

func _apply_scene_npc_layout() -> void:
	if _current_scene_name != "pingan_town":
		return
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is Node2D and npc.has_meta("npc_id"):
			var npc_id := String(npc.get_meta("npc_id"))
			if PINGAN_NPC_LAYOUT.has(npc_id):
				npc.position = PINGAN_NPC_LAYOUT[npc_id]

func _spawn_region_npcs_from_data() -> void:
	if not NpcData:
		return
	var region_npcs: Array = NpcData.get_region_npcs(_get_region_data_key())
	if region_npcs.is_empty():
		return
	var npc_layer: Node2D = get_node_or_null("NPCLayer")
	if not npc_layer:
		npc_layer = Node2D.new()
		npc_layer.name = "NPCLayer"
		npc_layer.z_index = 15
		add_child(npc_layer)
	var existing_ids := {}
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is Node2D and npc.has_meta("npc_id"):
			existing_ids[String(npc.get_meta("npc_id"))] = true
	var npc_sprite_script = load("res://scripts/entities/npc_sprite.gd")
	var positions = _get_region_npc_positions(region_npcs.size())
	for i in range(region_npcs.size()):
		var npc_data: Dictionary = region_npcs[i]
		var npc_id: String = npc_data.get("id", "")
		if npc_id.is_empty() or existing_ids.has(npc_id):
			continue
		if not _should_autospawn_npc(npc_id):
			continue
		var holder := Node2D.new()
		holder.name = "NPC_" + npc_id
		holder.position = _get_autospawn_position(npc_id, i, positions)
		holder.set_meta("npc_id", npc_id)
		holder.set_meta("npc_name", npc_data.get("name", npc_id))
		holder.set_meta("npc_title", npc_data.get("title", ""))
		holder.add_to_group("npcs")
		npc_layer.add_child(holder)
		var sprite := Node2D.new()
		sprite.name = "Sprite"
		if npc_sprite_script:
			sprite.set_script(npc_sprite_script)
			sprite.set("npc_id", npc_id)
		holder.add_child(sprite)

func _should_autospawn_npc(npc_id: String) -> bool:
	if _current_scene_name == "pingan_town":
		return PINGAN_AUTOSPAWN_IDS.has(npc_id)
	return true

func _get_autospawn_position(npc_id: String, index: int, positions: Array[Vector2]) -> Vector2:
	if _current_scene_name == "pingan_town" and PINGAN_NPC_LAYOUT.has(npc_id):
		return PINGAN_NPC_LAYOUT[npc_id]
	if positions.is_empty():
		return Vector2.ZERO
	return positions[index % positions.size()]

func _get_region_npc_positions(count: int) -> Array[Vector2]:
	if _current_scene_name == "pingan_town":
		return [
			Vector2(360, 420),
			Vector2(-540, 260),
			Vector2(540, -260),
		]
	if _current_scene_name == "wilderness_south" or _get_region_data_key() == "huanghe_valley":
		return [
			Vector2(-260, -80),
			Vector2(240, -20),
			Vector2(-120, 180),
			Vector2(320, 220),
			Vector2(-360, 260),
		]
	var positions: Array[Vector2] = []
	var radius := 220.0
	for i in range(maxi(count, 1)):
		var angle := TAU * float(i) / float(maxi(count, 1))
		positions.append(Vector2(cos(angle), sin(angle)) * radius)
	return positions

func _connect_signals() -> void:
	if not EventBus:
		return
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_mp_changed.connect(_on_mp_changed)
	EventBus.player_gold_changed.connect(_on_gold_changed)

func _check_nearby_npcs() -> void:
	_nearby_npcs.clear()
	var interact_hint: Label = _hud_labels.get("interact")
	var interact_bg: ColorRect = _hud_labels.get("interact_bg")
	if interact_hint:
		interact_hint.visible = false
	if interact_bg:
		interact_bg.visible = false
	if not player:
		return
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is Node2D:
			var dist: float = player.global_position.distance_to(npc.global_position)
			if dist < 80.0:
				_nearby_npcs.append(npc)
				if interact_hint:
					var npc_name: String = npc.get_meta("npc_name", "村民")
					interact_hint.text = "按 E 与 %s 对话" % npc_name
					interact_hint.visible = true
				if interact_bg:
					interact_bg.visible = true
				break

func _try_interact() -> void:
	if _nearby_npcs.size() > 0:
		var npc: Node2D = _nearby_npcs[0]
		var npc_id: String = npc.get_meta("npc_id", "villager")
		_start_task_driven_dialogue(npc_id)
	else:
		_show_notification("附近没有可交互的对象")

func _start_task_driven_dialogue(npc_id: String) -> void:
	if _try_chapter_one_story_dialogue(npc_id):
		return
	if _try_huanghe_story_dialogue(npc_id):
		return
	# 根据任务进度选择对话
	var objective_id: String = ""
	match npc_id:
		"li_muxue": # 李慕雪
			objective_id = "mother_talk_end"
		"daode_heshang": # 道德和尚
			objective_id = "herbalist_talk_quest"
	
	if not objective_id.is_empty():
		_start_npc_dialogue_with_objective(npc_id, objective_id)
	else:
		_start_dialogue(npc_id)

func _try_chapter_one_story_dialogue(npc_id: String) -> bool:
	if _game_flags.get("chapter1_complete", false):
		return false
	var stage := int(_game_flags.get("chapter1_stage", 0))
	if _current_quest_id.is_empty() and _current_scene_name == "pingan_town":
		_start_chapter_one_tracking()
	if _current_quest_id != "main_001_save_mother":
		return false
	if _current_scene_name == "pingan_town":
		if npc_id == "pingyizhi" and stage == 1:
			_start_custom_dialogue("平一指", [
				"平一指捻着药渣闻了闻，眉头越皱越紧。",
				"平一指：这不是寻常风寒，是旧年内伤被人用阴毒引发。",
				"平一指：还魂草确在黑风岭深处。你沿镇东密林走，翻过石碑，能见一处黑风寨。",
				"平一指：记住，草叶边缘带银纹，长在冷泉旁。摘错了，救不了人。"
			], "herbalist_talk_quest", Callable(self, "_on_chapter_one_herbalist_done"))
			return true
		if npc_id == "wang_tiejiang" and stage <= 2:
			_start_custom_dialogue("王铁匠", [
				"王铁匠放下铁锤，看了看你腰间那把旧剑。",
				"王铁匠：这是你爹的剑胚，没开锋却有骨气。去黑风岭，别硬拼，先看路。",
				"王铁匠：山贼怕官，也怕不要命的人。但你最好两样都别装。活着回来。"
			])
			return true
		if npc_id == "li_muxue" and stage >= 5 and _inventory.has("还魂草"):
			_start_custom_dialogue("李慕雪", [
				"你将还魂草碾入温水，李慕雪的气息一点点平稳下来。",
				"李慕雪：这是……影门令牌？孩子，你在黑风岭看见了什么？",
				"夜里，一位无尘道长来访，认出令牌上的暗纹。",
				"无尘道长：李慕白当年失踪，并非意外。若想知道真相，去洛阳，查影门旧案。",
				"李慕雪握住你的手：娘不拦你。只是这一次，你要为自己走。"
			], "mother_talk_end", Callable(self, "_complete_chapter_one"))
			return true
		if npc_id == "li_muxue" and stage < 5:
			_start_custom_dialogue("李慕雪", [
				"李慕雪强撑着坐起，声音很轻。",
				"李慕雪：若找不到还魂草，也不要把自己赔进去。你平安，比什么都重要。"
			])
			return true
	if _current_scene_name == "heifeng_ridge":
		if npc_id == "lin_yueru" and stage >= 3 and not _game_flags.get("lin_yueru_rescued", false):
			_start_custom_dialogue("林月如", [
				"林月如被三个地痞堵在山道旁，手里鞭子已经扬起，却被乱石逼住退路。",
				"林月如：喂！那边那个，你是看热闹的，还是来帮忙的？",
				"你没有回答，只把铁剑横在身前。地痞们骂骂咧咧围了上来。"
			], "", Callable(self, "_start_heifeng_ruffian_combat"))
			return true
		if npc_id == "blackwind_wolf" and _game_flags.get("lin_yueru_rescued", false) and not _game_flags.get("heifeng_wolf_defeated", false):
			_start_custom_dialogue("野狼", [
				"低吼声从松林里滚出来，两只野狼绕着冷泉打转。",
				"林月如压低声音：别怕，狼扑人前肩会先沉。你守正面，我断它后路。"
			], "", Callable(self, "_start_heifeng_wolf_combat"))
			return true
		if npc_id == "blackwind_sha" and _game_flags.get("heifeng_wolf_defeated", false) and not _game_flags.get("blackwind_sha_defeated", false):
			_start_custom_dialogue("黑风煞", [
				"黑风寨门前，黑风煞拎着开山斧，脚边散着镖旗和药篓。",
				"黑风煞：还魂草？小子，想从我黑风寨拿东西，先把命押下。",
				"他腰间一枚黑色令牌晃了一下，上面刻着你从未见过的影纹。"
			], "", Callable(self, "_start_heifeng_boss_combat"))
			return true
		if npc_id == "resurrection_grass" and _game_flags.get("blackwind_sha_defeated", false) and not _inventory.has("还魂草"):
			_start_custom_dialogue("冷泉还魂草", [
				"冷泉边，一株银纹药草在雾气里微微发亮。",
				"你按平一指所说，以布裹手，连根取下还魂草。",
				"草根下压着一枚旧令牌，背面刻着一个很浅的“影”字。"
			], "item_resurrection_grass", Callable(self, "_collect_resurrection_grass"))
			return true
	return false

func _on_chapter_one_herbalist_done() -> void:
	_advance_chapter_one_stage(2)
	_save_runtime_state()
	_show_notification("线索明确：从平安镇向东，穿过中原密林前往黑风岭", 3.0)

func _try_huanghe_story_dialogue(npc_id: String) -> bool:
	if _current_scene_name != "wilderness_south" or _current_quest_id != "huanghe_first_crossing":
		return false
	if npc_id == "huanghe_old_boatman":
		if _vertical_quest_stage <= 0:
			var fortune_roll := _roll_fortune()
			var lines: Array[String] = [
				"老艄公抬眼看了看天色，又看了看你的脚步。",
				"老艄公：少侠是从平安镇来的？这条古道今日水气重，像是要出事。",
				"老艄公：我见过许多初入江湖的人，敢往前走的不少，能记住退路的不多。",
			]
			if fortune_roll >= 16:
				lines.append("你衣角忽然被渡口木桩挂住，低头一看，竟拾到一枚旧平安符。")
				_add_item("黄河平安符", 1)
				_player_stats["fortune"] += 1
				lines.append("老艄公：这是机缘，也是提醒。拿着吧，河上人讲究一个平安。")
			else:
				lines.append("老艄公：前面有水贼踩点。若你一定要走，先把气息调匀。")
			_start_custom_dialogue("老艄公", lines, "huanghe_talk_boatman", Callable(self, "_on_huanghe_boatman_warning_done"))
			return true
		if _vertical_quest_stage >= 2 and not _game_flags.get("huanghe_quest_complete", false):
			_start_custom_dialogue("老艄公", [
				"老艄公望向河岸，见水贼已退，长长吐出一口气。",
				"老艄公：少侠今日没有逞凶，只是替行路人清了一块石头。",
				"老艄公：这点盘缠和药你拿着。江湖路长，别把每一仗都打成死仗。"
			], "huanghe_return_boatman", Callable(self, "_complete_huanghe_quest"))
			return true
	if npc_id == "huanghe_water_bandit":
		if _vertical_quest_stage >= 1 and not _game_flags.get("huanghe_bandit_defeated", false):
			_start_custom_dialogue("水上漂", [
				"水上漂：慢着！这渡口今日归我管。",
				"水上漂：看你不像镖局的人，留下买路钱，我可以当没见过你。",
				"你握紧拳，风从黄河上卷来，带着泥沙和铁锈味。"
			], "", Callable(self, "_start_huanghe_bandit_combat"))
			return true
	return false

func _on_huanghe_boatman_warning_done() -> void:
	_advance_huanghe_stage(1)
	_show_notification("机缘判定完成：前方水贼现身")

func _roll_fortune() -> int:
	return randi_range(1, 20) + int(float(_player_stats.get("fortune", 10)) / 4.0)

func _start_huanghe_bandit_combat() -> void:
	_combat_context = "huanghe_bandit"
	_combat_enemy = {
		"id": "huanghe_water_bandit",
		"name": "水上漂",
		"hp": 72,
		"max_hp": 72,
		"attack": 13,
		"defense": 5,
		"gold": 48,
		"xp": 80,
	}
	_combat_log = [
		"水上漂踏着湿滑木桩掠来，分水刺寒光一闪。",
		"这是第一场正式回合战：试着用普攻、内劲或金疮药。"
	]
	_combat_active = true
	_combat_turn_locked = false
	_combat_canvas.visible = true
	_update_combat_ui()

func _start_heifeng_ruffian_combat() -> void:
	_combat_context = "heifeng_ruffian"
	_combat_enemy = {
		"id": "heifeng_ruffian",
		"name": "地痞头目",
		"hp": 64,
		"max_hp": 64,
		"attack": 11,
		"defense": 4,
		"gold": 25,
		"xp": 60,
	}
	_combat_log = [
		"地痞头目抄起木棍冲来，身后两人虚张声势。",
		"林月如在侧翼牵制，你要撑住正面。"
	]
	_combat_active = true
	_combat_turn_locked = false
	_combat_canvas.visible = true
	_update_combat_ui()

func _start_heifeng_wolf_combat() -> void:
	_combat_context = "heifeng_wolf"
	_combat_enemy = {
		"id": "blackwind_wolf",
		"name": "黑风岭野狼",
		"hp": 78,
		"max_hp": 78,
		"attack": 14,
		"defense": 5,
		"gold": 0,
		"xp": 80,
	}
	_combat_log = [
		"野狼压低身形，绕着冷泉寻找破绽。",
		"这场战斗会考验药品和内力的使用节奏。"
	]
	_combat_active = true
	_combat_turn_locked = false
	_combat_canvas.visible = true
	_update_combat_ui()

func _start_heifeng_boss_combat() -> void:
	_combat_context = "heifeng_boss"
	_combat_enemy = {
		"id": "blackwind_sha",
		"name": "黑风煞",
		"hp": 128,
		"max_hp": 128,
		"attack": 18,
		"defense": 7,
		"gold": 70,
		"xp": 150,
	}
	_combat_log = [
		"黑风煞横斧拦路，山寨里火盆噼啪作响。",
		"这是第一章的关键战，胜后才能取得还魂草。"
	]
	_combat_active = true
	_combat_turn_locked = false
	_combat_canvas.visible = true
	_update_combat_ui()

func _poll_combat_input() -> void:
	if _combat_turn_locked:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_player_combat_action("attack")
	elif Input.is_action_just_pressed("skills"):
		_player_combat_action("skill")
	elif Input.is_action_just_pressed("inventory"):
		_player_combat_action("item")
	elif Input.is_action_just_pressed("menu"):
		_player_combat_action("flee")

func _player_combat_action(action: String) -> void:
	if not _combat_active:
		return
	match action:
		"attack":
			var damage := _calculate_player_damage(1.0, 0)
			_apply_enemy_damage(damage)
			_add_combat_log("你稳住步伐击中%s，造成 %d 点伤害。" % [_combat_enemy.get("name", "敌人"), damage])
		"skill":
			if int(_player_stats.get("mp", 0)) < 12:
				_add_combat_log("内力不足，丹田一空，只能稳住身形。")
			else:
				_player_stats["mp"] = int(_player_stats.get("mp", 0)) - 12
				var damage := _calculate_player_damage(1.55, 4)
				_apply_enemy_damage(damage)
				_add_combat_log("你提起一口内劲，拳势压入河风，造成 %d 点伤害。" % damage)
		"item":
			if int(_inventory.get("金疮药", 0)) <= 0:
				_add_combat_log("包里已经没有金疮药。")
			else:
				_inventory["金疮药"] = int(_inventory.get("金疮药", 0)) - 1
				var healed = mini(36, int(_player_stats.get("max_hp", 100)) - int(_player_stats.get("hp", 100)))
				_player_stats["hp"] = int(_player_stats.get("hp", 100)) + healed
				_add_combat_log("你敷上一包金疮药，恢复 %d 点气血。" % healed)
		"flee":
			var flee_roll := _roll_fortune()
			if flee_roll >= 14:
				_add_combat_log("你借河岸雾气退开半步，水上漂没有追来。")
				_end_combat(false)
				return
			_add_combat_log("你想退走，脚下碎石一滑，被迫继续应战。")
	_update_player_hud()
	if int(_combat_enemy.get("hp", 0)) <= 0:
		_win_current_combat()
		return
	_enemy_combat_turn()

func _enemy_combat_turn() -> void:
	var damage = maxi(3, int(_combat_enemy.get("attack", 10)) + randi_range(-2, 4) - int(_player_stats.get("defense", 8)))
	_player_stats["hp"] = maxi(0, int(_player_stats.get("hp", 100)) - damage)
	_add_combat_log("%s抓住破绽反击，你受到 %d 点伤害。" % [_combat_enemy.get("name", "敌人"), damage])
	if int(_player_stats.get("hp", 0)) <= 0:
		_player_stats["hp"] = 1
		_player_stats["reputation"] = maxi(0, int(_player_stats.get("reputation", 0)) - 1)
		_add_combat_log("你险些倒下，被同伴拖出战圈。声望 -1。")
		_end_combat(false)
	_update_player_hud()
	_update_combat_ui()

func _calculate_player_damage(multiplier: float, bonus: int) -> int:
	var base = int(_player_stats.get("attack", 18)) + randi_range(1, 8) + bonus
	var reduced = base - int(_combat_enemy.get("defense", 0))
	return maxi(4, int(float(reduced) * multiplier))

func _apply_enemy_damage(amount: int) -> void:
	_combat_enemy["hp"] = maxi(0, int(_combat_enemy.get("hp", 0)) - amount)

func _add_combat_log(line: String) -> void:
	_combat_log.append(line)
	while _combat_log.size() > 5:
		_combat_log.pop_front()
	_update_combat_ui()

func _update_combat_ui() -> void:
	if not _combat_canvas:
		return
	var enemy_lbl: Label = _combat_labels.get("enemy")
	if enemy_lbl:
		enemy_lbl.text = "%s  气血: %d/%d" % [_combat_enemy.get("name", "敌人"), int(_combat_enemy.get("hp", 0)), int(_combat_enemy.get("max_hp", 0))]
	var player_lbl: Label = _combat_labels.get("player")
	if player_lbl:
		player_lbl.text = "李少侠  气血: %d/%d  内力: %d/%d  金疮药: %d" % [
			int(_player_stats.get("hp", 0)),
			int(_player_stats.get("max_hp", 0)),
			int(_player_stats.get("mp", 0)),
			int(_player_stats.get("max_mp", 0)),
			int(_inventory.get("金疮药", 0)),
		]
	var log_lbl: Label = _combat_labels.get("log")
	if log_lbl:
		log_lbl.text = "\n".join(_combat_log)

func _win_current_combat() -> void:
	match _combat_context:
		"huanghe_bandit":
			_win_huanghe_combat()
		"heifeng_ruffian":
			_win_heifeng_ruffian_combat()
		"heifeng_wolf":
			_win_heifeng_wolf_combat()
		"heifeng_boss":
			_win_heifeng_boss_combat()
		_:
			_end_combat(true)

func _win_huanghe_combat() -> void:
	_game_flags["huanghe_bandit_defeated"] = true
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + int(_combat_enemy.get("xp", 0))
	_player_stats["gold"] = int(_player_stats.get("gold", 0)) + int(_combat_enemy.get("gold", 0))
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 3
	_add_item("水贼腰牌", 1)
	_advance_huanghe_stage(2)
	_add_combat_log("水上漂败退，丢下一枚腰牌和些许银两。声望 +3。")
	_update_player_hud()
	await get_tree().create_timer(1.0).timeout
	_end_combat(true)
	_show_notification("战斗胜利：回老艄公处复命")

func _win_heifeng_ruffian_combat() -> void:
	_game_flags["lin_yueru_rescued"] = true
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + int(_combat_enemy.get("xp", 0))
	_player_stats["gold"] = int(_player_stats.get("gold", 0)) + int(_combat_enemy.get("gold", 0))
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 2
	_game_flags["lin_yueru_affinity"] = int(_game_flags.get("lin_yueru_affinity", 0)) + 20
	_advance_chapter_one_stage(4)
	_add_combat_log("地痞四散奔逃。林月如收起长鞭，嘴上不服，眼神却柔和了些。好感 +20。")
	_update_player_hud()
	_save_runtime_state()
	await get_tree().create_timer(1.0).timeout
	_end_combat(true)
	_show_notification("林月如加入同行：继续深入黑风岭，寻找冷泉", 3.0)

func _win_heifeng_wolf_combat() -> void:
	_game_flags["heifeng_wolf_defeated"] = true
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + int(_combat_enemy.get("xp", 0))
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 1
	_add_item("狼牙", 1)
	_add_combat_log("野狼退入林中，冷泉方向露出一条被踩出的窄路。")
	_update_player_hud()
	_save_runtime_state()
	await get_tree().create_timer(1.0).timeout
	_end_combat(true)
	_show_notification("道路打开：黑风寨就在冷泉之后", 2.5)

func _win_heifeng_boss_combat() -> void:
	_game_flags["blackwind_sha_defeated"] = true
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + int(_combat_enemy.get("xp", 0))
	_player_stats["gold"] = int(_player_stats.get("gold", 0)) + int(_combat_enemy.get("gold", 0))
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 6
	_add_item("黑风寨腰牌", 1)
	_advance_chapter_one_stage(5)
	_add_combat_log("黑风煞败退，山寨后方的冷泉无人看守。")
	_update_player_hud()
	_save_runtime_state()
	await get_tree().create_timer(1.0).timeout
	_end_combat(true)
	_show_notification("黑风煞已败：去冷泉边采还魂草", 3.0)

func _end_combat(victory: bool) -> void:
	_combat_active = false
	_combat_canvas.visible = false
	_combat_enemy.clear()
	_combat_log.clear()
	_combat_context = ""
	if not victory:
		_show_notification("你暂时脱离战斗，调整后可再战。")

func _complete_huanghe_quest() -> void:
	if _game_flags.get("huanghe_quest_complete", false):
		return
	_game_flags["huanghe_quest_complete"] = true
	_player_stats["gold"] = int(_player_stats.get("gold", 0)) + 80
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + 120
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 5
	_add_item("金疮药", 2)
	if _inventory.has("黄河平安符"):
		_player_stats["fortune"] = int(_player_stats.get("fortune", 0)) + 1
	_show_notification("任务完成：黄河古道 · 银两+80 声望+5 金疮药+2", 3.0)
	_update_player_hud()
	_update_quest_tracker()

func _collect_resurrection_grass() -> void:
	_add_item("还魂草", 1)
	_add_item("影门令牌", 1)
	_complete_objective("item_resurrection_grass")
	_save_runtime_state()
	_show_notification("获得：还魂草、影门令牌 · 回平安镇救母亲", 3.2)

func _complete_chapter_one() -> void:
	if _game_flags.get("chapter1_complete", false):
		return
	_game_flags["chapter1_complete"] = true
	_advance_chapter_one_stage(6)
	_player_stats["xp"] = int(_player_stats.get("xp", 0)) + 500
	_player_stats["gold"] = int(_player_stats.get("gold", 0)) + 100
	_player_stats["reputation"] = int(_player_stats.get("reputation", 0)) + 50
	if not _inventory.has("粗布衣"):
		_add_item("粗布衣", 1)
	_complete_objective("mother_talk_end")
	_save_runtime_state()
	_show_notification("第一章完成：母亲得救 · 声望+50 · 银两+100 · 下一站洛阳", 4.0)
	_update_player_hud()
	_update_quest_tracker()

func _add_item(item_name: String, amount: int = 1) -> void:
	_inventory[item_name] = int(_inventory.get(item_name, 0)) + amount
	_save_runtime_state()

func _show_inventory_summary() -> void:
	var parts: Array[String] = []
	for item_name in _inventory.keys():
		var amount := int(_inventory[item_name])
		if amount > 0:
			parts.append("%s x%d" % [item_name, amount])
	if parts.is_empty():
		_show_notification("背包空空如也")
	else:
		_show_notification("背包：" + "，".join(parts), 3.0)

func _show_quest_summary() -> void:
	if _current_quest_id in ["huanghe_first_crossing", "main_001_save_mother"]:
		_update_quest_tracker()
		_quest_tracker_canvas.visible = true
		_show_notification("已追踪：" + _quest_tracker_label.text)
	else:
		_show_notification("当前没有追踪任务")

func _update_player_hud() -> void:
	var hp = int(_player_stats.get("hp", 0))
	var max_hp = int(_player_stats.get("max_hp", 100))
	var mp = int(_player_stats.get("mp", 0))
	var max_mp = int(_player_stats.get("max_mp", 50))

	var hp_lbl: Label = _hud_labels.get("hp")
	if hp_lbl:
		hp_lbl.text = "气血 %d/%d" % [hp, max_hp]
	var hp_bar: ColorRect = _hud_labels.get("hp_bar")
	if hp_bar:
		var ratio = float(hp) / float(maxi(max_hp, 1))
		hp_bar.offset_right = hp_bar.offset_left + 180.0 * ratio

	var mp_lbl: Label = _hud_labels.get("mp")
	if mp_lbl:
		mp_lbl.text = "内力 %d/%d" % [mp, max_mp]
	var mp_bar: ColorRect = _hud_labels.get("mp_bar")
	if mp_bar:
		var ratio = float(mp) / float(maxi(max_mp, 1))
		mp_bar.offset_right = mp_bar.offset_left + 180.0 * ratio

	var gold_lbl: Label = _hud_labels.get("gold")
	if gold_lbl:
		gold_lbl.text = "银两 %d" % int(_player_stats.get("gold", 0))
	var level_lbl: Label = _hud_labels.get("level")
	if level_lbl:
		level_lbl.text = "Lv.%d · 声望%d · 气运%d" % [
			int(_player_stats.get("level", 1)),
			int(_player_stats.get("reputation", 0)),
			int(_player_stats.get("fortune", 0)),
		]

func _start_dialogue(npc_id: String) -> void:
	var dialogue_data: Dictionary = _npc_dialogues.get(npc_id, {})
	if dialogue_data.is_empty():
		_show_notification("此人似乎无话可说...")
		return
	_dialogue_queue = dialogue_data.get("lines", [])
	if _dialogue_queue.is_empty():
		return
	_dialogue_current_index = 0
	_dialogue_active = true
	var name_lbl: Label = _dialogue_labels.get("name")
	if name_lbl:
		name_lbl.text = dialogue_data.get("name", "???")
	
	var portrait_sprite: TextureRect = _dialogue_labels.get("portrait")
	if portrait_sprite:
		var portrait_path: String = NPC_PORTRAITS.get(npc_id, "")
		if portrait_path and not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
			var tex: Resource = load(portrait_path)
			if tex:
				portrait_sprite.texture = tex
				portrait_sprite.visible = true
			else:
				portrait_sprite.visible = false
		else:
			portrait_sprite.visible = false
	
	_dialogue_canvas.visible = true
	_show_dialogue_line()

func _start_custom_dialogue(speaker_name: String, lines: Array, objective_id: String = "", on_complete: Callable = Callable()) -> void:
	_dialogue_queue = lines
	if _dialogue_queue.is_empty():
		return
	_dialogue_current_index = 0
	_dialogue_active = true
	_dialogue_complete_objective = objective_id
	_dialogue_complete_action = on_complete
	var name_lbl: Label = _dialogue_labels.get("name")
	if name_lbl:
		name_lbl.text = speaker_name
	var portrait_sprite: TextureRect = _dialogue_labels.get("portrait")
	if portrait_sprite:
		portrait_sprite.visible = false
	_dialogue_canvas.visible = true
	_show_dialogue_line()

func _show_dialogue_line() -> void:
	if _dialogue_current_index >= _dialogue_queue.size():
		_close_dialogue()
		return
	var text_lbl: Label = _dialogue_labels.get("text")
	if text_lbl:
		text_lbl.text = _dialogue_queue[_dialogue_current_index]
	var hint_lbl: Label = _dialogue_labels.get("hint")
	if hint_lbl:
		if _dialogue_current_index >= _dialogue_queue.size() - 1:
			hint_lbl.text = "▼ Enter 结束对话"
		else:
			hint_lbl.text = "▼ Enter 继续"

func _close_dialogue() -> void:
	_dialogue_active = false
	_dialogue_canvas.visible = false
	_dialogue_queue = []
	_dialogue_current_index = 0
	if not _dialogue_complete_objective.is_empty():
		_complete_objective(_dialogue_complete_objective)
		_dialogue_complete_objective = ""
	if _dialogue_complete_action.is_valid():
		var action := _dialogue_complete_action
		_dialogue_complete_action = Callable()
		action.call()

func _toggle_menu() -> void:
	if _menu_canvas.visible:
		_hide_menu()
	else:
		_show_menu()

func _show_notification(message: String, duration: float = 2.5) -> void:
	var notif_canvas: CanvasLayer = get_node_or_null("NotifCanvas")
	if not notif_canvas:
		notif_canvas = CanvasLayer.new()
		notif_canvas.name = "NotifCanvas"
		notif_canvas.layer = 100
		add_child(notif_canvas)

	var notification: Label = notif_canvas.get_node_or_null("Notification")
	if not notification:
		notification = Label.new()
		notification.name = "Notification"
		notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notification.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
		notification.add_theme_font_size_override("font_size", 24)
		notification.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		notification.offset_top = -60.0
		notification.offset_bottom = -30.0
		notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
		notif_canvas.add_child(notification)

	notification.text = message
	notification.visible = true
	notification.modulate.a = 1.0
	if _notification_tween and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification_tween = create_tween()
	_notification_tween.tween_property(notification, "modulate:a", 0.0, 0.5).set_delay(duration)
	_notification_tween.tween_callback(func(): notification.visible = false)

func _start_new_game() -> void:
	if is_game_started:
		return
	_hide_menu()
	# 开始第一章主线任务
	_start_chapter_one_tracking()
	_start_chapter_one()
	_show_notification("平安镇 — 你的江湖之路，由此开始")

func _start_chapter_one() -> void:
	# 触发与母亲的开场对话（延迟一小段时间）
	await get_tree().create_timer(0.5).timeout
	_start_custom_dialogue("李慕雪", [
		"孩子，你终于醒了……娘这几日总梦见你父亲站在门外，衣上全是风雪。",
		"平一指说，若要救这怪病，只有黑风岭深处的还魂草可用。",
		"娘不愿你冒险，可你若一定要去，就带上你父亲留下的铁剑。",
		"记住，江湖不是逞强的地方。救人时要有胆，退让时也要有胆。"
	], "mother_talk_start", Callable(self, "_on_chapter_one_mother_start_done"))

func _on_chapter_one_mother_start_done() -> void:
	if not _inventory.has("铁剑"):
		_add_item("铁剑", 1)
	_advance_chapter_one_stage(1)
	_save_runtime_state()
	_show_notification("获得：铁剑 · 去药铺找平一指确认还魂草线索", 3.0)

func _update_quest_tracker() -> void:
	if _current_quest_id == "main_001_save_mother":
		_quest_tracker_canvas.visible = true
		_quest_tracker_label.text = "少年侠影"
		var stage := int(_game_flags.get("chapter1_stage", 0))
		var obj_text := ""
		if _game_flags.get("chapter1_complete", false):
			obj_text = "[✓] 母亲得救\n[✓] 影门令牌现世\n[>] 前往洛阳追查父亲旧案"
		elif stage <= 0:
			obj_text = "[>] 与李慕雪对话\n[ ] 向平一指询问还魂草\n[ ] 前往黑风岭"
		elif stage == 1:
			obj_text = "[✓] 与李慕雪对话\n[>] 向平一指询问还魂草\n[ ] 从镇东出发前往黑风岭"
		elif stage == 2:
			obj_text = "[✓] 确认还魂草线索\n[>] 穿过中原密林，抵达黑风岭\n[ ] 救下林月如"
		elif stage == 3:
			obj_text = "[✓] 抵达黑风岭\n[>] 救下被地痞围困的林月如\n[ ] 深入冷泉"
		elif stage == 4:
			obj_text = "[✓] 林月如同行\n[>] 击退冷泉野狼\n[ ] 挑战黑风煞"
		elif stage == 5 and not _inventory.has("还魂草"):
			obj_text = "[✓] 黑风煞已败\n[>] 在冷泉采集还魂草\n[ ] 回平安镇救母亲"
		else:
			obj_text = "[✓] 获得还魂草与影门令牌\n[>] 返回平安镇，与李慕雪对话\n[ ] 开启第二章"
		_quest_objective_label.text = obj_text + "\n\n平安镇声望: %d  林月如好感: %d" % [
			int(_player_stats.get("reputation", 0)),
			int(_game_flags.get("lin_yueru_affinity", 0)),
		]
		return
	if _current_quest_id == "huanghe_first_crossing":
		_quest_tracker_canvas.visible = true
		_quest_tracker_label.text = "黄河古道"
		var obj_text := ""
		if _game_flags.get("huanghe_quest_complete", false):
			obj_text = "[✓] 向老艄公交还渡口人情\n奖励已领取，黄河古道暂时恢复通行。"
		elif _vertical_quest_stage <= 0:
			obj_text = "[>] 与老艄公交谈，打听渡口异动\n[ ] 击退水贼\n[ ] 回老艄公处领取谢礼"
		elif _vertical_quest_stage == 1:
			obj_text = "[✓] 与老艄公交谈\n[>] 找到水上漂并击退水贼\n[ ] 回老艄公处领取谢礼"
		else:
			obj_text = "[✓] 与老艄公交谈\n[✓] 击退水贼\n[>] 回老艄公处领取谢礼"
		_quest_objective_label.text = obj_text + "\n\n声望: %d  气运: %d" % [int(_player_stats.get("reputation", 0)), int(_player_stats.get("fortune", 0))]
		return
	var quest_system = null
	if Engine.has_meta("QuestSystem"):
		quest_system = Engine.get_meta("QuestSystem")
	if quest_system == null:
		quest_system = get_node_or_null("/root/QuestSystem")
	
	if quest_system == null:
		if _current_quest_id.is_empty():
			_quest_tracker_label.text = "暂无任务"
			_quest_objective_label.text = ""
		else:
			_quest_tracker_label.text = "初入江湖"
			_quest_objective_label.text = "> 与李慕雪对话"
		return
	
	var active_quests = quest_system.get_active_quests()
	if active_quests.is_empty():
		_quest_tracker_label.text = "暂无任务"
		_quest_objective_label.text = ""
		return
	
	var tracked_quest_id = quest_system.get_tracked_quest()
	var quest_to_show = null
	
	if not tracked_quest_id.is_empty():
		for quest in active_quests:
			if quest.get("quest_id") == tracked_quest_id:
				quest_to_show = quest
				break
	
	if quest_to_show == null and not active_quests.is_empty():
		quest_to_show = active_quests[0]
	
	if quest_to_show:
		var title = quest_to_show.get("title", "未知任务")
		_quest_tracker_label.text = title
		
		var objectives = quest_to_show.get("objectives", [])
		var current_obj = quest_to_show.get("current_objective", 0)
		var progress = quest_to_show.get("progress", 0)
		var total = quest_to_show.get("total_objectives", 0)
		
		var obj_text = ""
		for i in range(mini(objectives.size(), 4)):
			var obj = objectives[i] if i < objectives.size() else {}
			var obj_desc = obj.get("description", "")
			var is_completed = i < progress
			var is_current = i == current_obj
			
			if is_completed:
				obj_text += "[✓] " + obj_desc + "\n"
			elif is_current:
				obj_text += "[>] " + obj_desc + "\n"
			else:
				obj_text += "[ ] " + obj_desc + "\n"
		
		obj_text += "\n进度: %d/%d" % [progress, total]
		_quest_objective_label.text = obj_text
	else:
		_quest_tracker_label.text = "暂无任务"
		_quest_objective_label.text = ""

func _complete_objective(target_id: String) -> void:
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("trigger_objective"):
		quest_system.trigger_objective(target_id)
	_update_quest_tracker()

func _start_npc_dialogue_with_objective(npc_id: String, objective_id: String) -> void:
	var dialogue_data: Dictionary = _npc_dialogues.get(npc_id, {})
	if dialogue_data.is_empty():
		return
	_dialogue_queue = dialogue_data.get("lines", [])
	if _dialogue_queue.is_empty():
		return
	_dialogue_current_index = 0
	_dialogue_active = true
	var name_lbl: Label = _dialogue_labels.get("name")
	if name_lbl:
		name_lbl.text = dialogue_data.get("name", "???")
	_dialogue_complete_objective = objective_id
	_dialogue_complete_action = Callable()
	_dialogue_canvas.visible = true
	_show_dialogue_line()

func _load_game() -> void:
	_show_notification("存档功能开发中...")

func _show_settings() -> void:
	_show_notification("江湖设定功能开发中...")

func _quit_game() -> void:
	get_tree().quit()

func _on_player_level_up(new_level: int) -> void:
	_show_notification("恭喜！升级到 %d 级！" % new_level)
	var lbl: Label = _hud_labels.get("level")
	if lbl:
		lbl.text = "Lv.%d" % new_level

func _on_hp_changed(current: int, max_hp: int) -> void:
	var lbl: Label = _hud_labels.get("hp")
	if lbl:
		lbl.text = "气血 %d/%d" % [current, max_hp]
	var bar: ColorRect = _hud_labels.get("hp_bar")
	if bar:
		var ratio = float(current) / float(maxi(max_hp, 1))
		bar.offset_right = bar.offset_left + 180.0 * ratio

func _on_mp_changed(current: int, max_mp: int) -> void:
	var lbl: Label = _hud_labels.get("mp")
	if lbl:
		lbl.text = "内力 %d/%d" % [current, max_mp]
	var bar: ColorRect = _hud_labels.get("mp_bar")
	if bar:
		var ratio = float(current) / float(maxi(max_mp, 1))
		bar.offset_right = bar.offset_left + 180.0 * ratio

func _on_gold_changed(amount: int) -> void:
	var lbl: Label = _hud_labels.get("gold")
	if lbl:
		lbl.text = "银两 %d" % amount

func _show_menu() -> void:
	_menu_canvas.visible = true
	_hud_canvas.visible = false
	is_game_started = false
	_menu_index = 0
	_auto_start_timer = 0.0
	_update_menu_highlight()

func _hide_menu() -> void:
	_menu_canvas.visible = false
	_hud_canvas.visible = true
	is_game_started = true
