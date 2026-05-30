extends Node

# 任务系统 - 管理游戏中所有任务的追踪和完成

# 任务状态枚举
enum QuestState {
	NOT_STARTED = 0,
	ACTIVE = 1,
	COMPLETED = 2,
	FAILED = 3
}

# 任务目标类型枚举
enum ObjectiveType {
	KILL = 0,
	COLLECT = 1,
	TALK = 2,
	VISIT = 3,
	ESCORT = 4,
	DEFEND = 5,
	DELIVER = 6
}

# 信号定义
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal objective_completed(quest_id: String, objective_index: int)
signal quest_tracked_changed(quest_id: String)

# 私有变量
var _active_quests: Dictionary = {}
var _completed_quests: Array[String] = []
var _failed_quests: Array[String] = []
var _tracked_quest_id: String = ""

# 任务定义数据
var _quest_definitions: Dictionary = {}

# 单例实例
static var instance: Node = null

func _init() -> void:
	if instance == null:
		instance = self
	else:
		push_warning("QuestSystem: 尝试创建多个实例，已忽略")

func _ready() -> void:
	if Engine.has_meta("QuestSystem_Initialized"):
		return
	Engine.set_meta("QuestSystem_Initialized", true)
	_load_quest_definitions()
	_connect_signals()

func _connect_signals() -> void:
	pass

func _load_quest_definitions() -> void:
	# 主线任务（5章）
	_define_main_quests()
	# 洛阳区域支线任务（10条）
	_define_luoyang_quests()
	# 长安区域支线任务（10条）
	_define_changan_quests()
	# 临安区域支线任务（10条）
	_define_linan_quests()
	# 成都区域支线任务（10条）
	_define_chengdu_quests()
	# 江陵区域支线任务（10条）
	_define_jiangling_quests()
	# 门派任务（10条）
	_define_sect_quests()
	
	# 加载外部任务文件（可选）
	var quest_folder: String = "res://data/quests/"
	if DirAccess.dir_exists_absolute(quest_folder):
		var dir: DirAccess = DirAccess.open(quest_folder)
		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			
			while not file_name.is_empty():
				if file_name.ends_with(".tres"):
					var quest_path: String = quest_folder + file_name
					var quest_data: Resource = load(quest_path)
					
					if quest_data:
						_register_quest_definition(quest_data)
				
				file_name = dir.get_next()
			
			dir.list_dir_end()

func _define_main_quests() -> void:
	# 第一章：初入江湖 - 主线任务1：救治母亲
	var quest_1_data: Dictionary = {
		"quest_id": "main_001_save_mother",
		"title": "第一章：初入江湖",
		"description": "母亲身患奇疾，只有传说中的还魂草能救她。踏上寻找还魂草的征程吧！",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "mother_talk_start",
				"description": "与母亲对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "herbalist_talk_quest",
				"description": "向王药师询问还魂草的下落",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_blackwind_ridge",
				"description": "前往黑风岭",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_resurrection_grass",
				"description": "收集还魂草",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "mother_talk_end",
				"description": "返回平安镇，用还魂草救治母亲",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 100},
			{"type": "item", "item_id": "item_iron_sword", "amount": 1},
			{"type": "item", "item_id": "item_coarse_cloth", "amount": 1},
			{"type": "flag", "flag": "chapter1_complete", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(quest_1_data)

	# 第二章：江湖风云 - 主线任务2：身世之谜
	var quest_2_data: Dictionary = {
		"quest_id": "main_002",
		"title": "第二章：江湖风云",
		"description": "母亲得救后，你在黑风岭遭遇神秘人，得知自己身世之谜。前往洛阳和嵩山打探消息，揭开尘封的往事。",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "wang_yaoshi_farewell",
				"description": "与王药师道别",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_luoyang_city",
				"description": "前往洛阳城打探消息",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "luoyang_prefect_talk",
				"description": "与洛阳太守交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_songshan",
				"description": "前往嵩山",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "shaolin_abbot_talk",
				"description": "与少林方丈交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_yijin_jing_fragment",
				"description": "收集《易筋经》残页",
				"amount": 3
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1000},
			{"type": "gold", "amount": 200},
			{"type": "flag", "flag": "chapter2_complete", "value": true},
			{"type": "flag", "flag": "shaolin_sect_unlocked", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(quest_2_data)

	# 第三章：门派恩怨 - 主线任务3：红莲阴谋
	var quest_3_data: Dictionary = {
		"quest_id": "main_003",
		"title": "第三章：门派恩怨",
		"description": "揭露红莲教阴谋，被卷入江湖纷争。深入中原密林，调查红莲教的秘密。",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "shaolin_abbot_farewell",
				"description": "与少林方丈道别",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_central_plains_forest",
				"description": "前往中原密林",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_honglian_disciple",
				"description": "击败红莲教徒",
				"amount": 5
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_honglian_secret_base",
				"description": "找到红莲教秘密据点",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "investigate_honglian_elder",
				"description": "调查红莲教长老",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "deliver_intelligence_to_shaolin",
				"description": "将情报送回少林寺",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 2000},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "chapter3_complete", "value": true},
			{"type": "flag", "flag": "fame", "value": 50}
		],
		"prerequisites": [{"type": "quest_completed", "quest_id": "main_002"}],
		"repeatable": false
	}
	add_custom_quest(quest_3_data)

	# 第四章：天下大势 - 主线任务4：风云变幻
	var quest_4_data: Dictionary = {
		"quest_id": "main_004",
		"title": "第四章：天下大势",
		"description": "得知朝廷与江湖的阴谋，五大城池暗流涌动。前往长安觐见皇帝，调查洛阳的变故。",
		"objectives": [
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_changan_city",
				"description": "前往长安城",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "emperor_secret_talk",
				"description": "与皇帝密谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_occupied_luoyang",
				"description": "调查洛阳（此时洛阳已被攻占）",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "surviving_luoyang_prefect_talk",
				"description": "与残存的洛阳太守对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_city_defense_fragment",
				"description": "收集城防图残片",
				"amount": 5
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "deliver_city_defense_to_linan",
				"description": "将城防图送往临安",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 3000},
			{"type": "gold", "amount": 1000},
			{"type": "flag", "flag": "chapter4_complete", "value": true},
			{"type": "flag", "flag": "special_skill_unlocked", "value": true}
		],
		"prerequisites": [{"type": "quest_completed", "quest_id": "main_003"}],
		"repeatable": false
	}
	add_custom_quest(quest_4_data)

	# 第五章：终极对决 - 主线任务5：讨伐红莲
	var quest_5_data: Dictionary = {
		"quest_id": "main_005",
		"title": "第五章：终极对决",
		"description": "讨伐红莲教，揭露幕后黑手。直捣红莲教总坛，与教主进行最终决战。",
		"objectives": [
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_honglian_headquarters",
				"description": "前往红莲教总坛",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_honglian_guardian",
				"description": "击败红莲教护法",
				"amount": 3
			},
			{
				"type": ObjectiveType.TALK,
				"target": "confront_honglian_leader",
				"description": "与红莲教主对峙",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_honglian_leader",
				"description": "最终决战，击败红莲教主",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "return_to_changan",
				"description": "回到长安复命",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "deliver_honglian_head_to_emperor",
				"description": "将红莲教主首级献给皇帝",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 10000},
			{"type": "gold", "amount": 5000},
			{"type": "flag", "flag": "chapter5_complete", "value": true},
			{"type": "flag", "flag": "title_jianghu_supreme", "value": true}
		],
		"prerequisites": [{"type": "quest_completed", "quest_id": "main_004"}],
		"repeatable": false
	}

func _define_linan_quests() -> void:
	# 临安区域支线任务1：太湖明珠
	var linan_001_data: Dictionary = {
		"quest_id": "linan_001",
		"title": "太湖明珠",
		"description": "太湖中出现水怪，渔民损失惨重",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "fisherman_talk", "description": "与渔夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_taihu_lake", "description": "前往太湖", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "taihu_dragon", "description": "击败太湖蛟龙", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "governor_talk_reward", "description": "回报知府", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 500},
			{"type": "item", "item_id": "taihu_pearl", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_001_data)

	# 临安区域支线任务2：钱塘潮魂
	var linan_002_data: Dictionary = {
		"quest_id": "linan_002",
		"title": "钱塘潮魂",
		"description": "钱塘江潮水异常，疑似有妖孽作祟",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "tide_watcher_talk", "description": "与观潮人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_qiantang_river", "description": "钱塘江畔", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "tide_god", "description": "击败潮神", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "river_god_talk", "description": "安抚江神", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 700},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "qiantang_token", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_002_data)

	# 临安区域支线任务3：武夷茶香
	var linan_003_data: Dictionary = {
		"quest_id": "linan_003",
		"title": "武夷茶香",
		"description": "武夷山茶农的顶级茶叶被偷",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "tea_farmer_talk", "description": "与茶农交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_wuyi_mountain", "description": "武夷山林", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "tea_thief", "description": "击败窃贼", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_top_tea", "description": "追回茶叶", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "tea_farmer_deliver", "description": "还给茶农", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "top_grade_tea", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_003_data)

	# 临安区域支线任务4：洞庭水寇
	var linan_004_data: Dictionary = {
		"quest_id": "linan_004",
		"title": "洞庭水寇",
		"description": "洞庭湖上水寇横行，渔民苦不堪言",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "dongting_fisherman_talk", "description": "与渔民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_dongting_lake", "description": "洞庭湖畔", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "water_bandit_leader", "description": "击败水寇头目", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "fisherman_thanks", "description": "渔民感谢", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "water_bandit_trophy", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_004_data)

	# 临安区域支线任务5：花间秘事
	var linan_005_data: Dictionary = {
		"quest_id": "linan_005",
		"title": "花间秘事",
		"description": "花间派弟子求助，师妹被神秘人掳走",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "huajian_disciple_talk", "description": "与花间派弟子交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_trace_clues", "description": "追查线索", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "kidnapper", "description": "击败绑架者", "amount": 1},
			{"type": ObjectiveType.ESCORT, "target": "escort_junior_sister", "description": "护送师妹回百花谷", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 350},
			{"type": "flag", "flag": "huajian_faction_reputation", "value": 40}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_005_data)

	# 临安区域支线任务6：逍遥游
	var linan_006_data: Dictionary = {
		"quest_id": "linan_006",
		"title": "逍遥游",
		"description": "逍遥宫广招弟子，需要通过考验",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "xiaoyao_disciple_talk", "description": "与逍遥派弟子交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_xiaoyao_trial", "description": "接受考验", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "trial_taker", "description": "击败考验者", "amount": 3},
			{"type": ObjectiveType.TALK, "target": "xiaoyao_leader_talk", "description": "拜见掌门", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 800},
			{"type": "gold", "amount": 500},
			{"type": "item", "item_id": "xiaoyao_qualification", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_006_data)

	# 临安区域支线任务7：嘉兴丝绸
	var linan_007_data: Dictionary = {
		"quest_id": "linan_007",
		"title": "嘉兴丝绸",
		"description": "嘉兴丝绸商人的丝绸在运河中被劫",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "silk_merchant_talk", "description": "与丝绸商人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_jiaxing_canal", "description": "嘉兴运河", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "river_pirate", "description": "击败河盗", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_silk", "description": "追回丝绸", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "silk_merchant_deliver", "description": "还给商人", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 450},
			{"type": "gold", "amount": 600},
			{"type": "item", "item_id": "silk_merchant_reward", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_007_data)

	# 临安区域支线任务8：乌篷船歌
	var linan_008_data: Dictionary = {
		"quest_id": "linan_008",
		"title": "乌篷船歌",
		"description": "绍兴乌篷船夫们组织赛船大会，邀请侠士参加",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "boatman_talk", "description": "与船夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_shaoxing_water_town", "description": "前往绍兴水乡", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "attend_boat_race", "description": "参加赛船", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "winning_girl_talk", "description": "与获胜船娘交谈", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 300},
			{"type": "gold", "amount": 200},
			{"type": "item", "item_id": "wupeng_boat_model", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_008_data)

	# 临安区域支线任务9：天目奇松
	var linan_009_data: Dictionary = {
		"quest_id": "linan_009",
		"title": "天目奇松",
		"description": "天目山古树被虫害侵蚀，需要救治",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "tianmu_monk_talk", "description": "与禅寺僧人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_tianmu_mountain", "description": "天目山", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_herbal_medicine", "description": "采集药材", "amount": 5},
			{"type": ObjectiveType.DELIVER, "target": "prepare_pesticide", "description": "配制杀虫剂", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 250},
			{"type": "item", "item_id": "tianmu_old_tree_map", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_009_data)

	# 临安区域支线任务10：黄山云海
	var linan_010_data: Dictionary = {
		"quest_id": "linan_010",
		"title": "黄山云海",
		"description": "黄山画师寻求云海奇景，用于创作传世名画",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "painter_talk", "description": "与画师交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_huangshan_cloud_sea", "description": "黄山云海", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "wait_for_cloud_sea", "description": "等待云海", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_cloud_spirit_stone", "description": "收集云海灵石", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "deliver_to_painter", "description": "交给画师", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "cloud_sea_painting", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(linan_010_data)

func _define_luoyang_quests() -> void:
	# 洛阳区域支线任务1：洛阳失踪案
	var luoyang_001_data: Dictionary = {
		"quest_id": "luoyang_001",
		"title": "洛阳失踪案",
		"description": "洛阳城中接连有人失踪，太守焦急万分",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "luoyang_governor_talk", "description": "与太守对话", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_luoyang_district", "description": "调查城区", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "kill_traffickers", "description": "击败人贩子", "amount": 3},
			{"type": ObjectiveType.TALK, "target": "luoyang_governor_report", "description": "回报太守", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 300},
			{"type": "gold", "amount": 100},
			{"type": "flag", "flag": "luoyang_001_complete", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_001_data)

	# 洛阳区域支线任务2：铁匠的委托
	var luoyang_002_data: Dictionary = {
		"quest_id": "luoyang_002",
		"title": "铁匠的委托",
		"description": "铁匠老张需要珍稀矿石打造神兵",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "blacksmith_zhang_talk", "description": "与铁匠交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_taihang_mountain", "description": "前往太行山脉", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_dark_iron_ore", "description": "收集玄铁矿", "amount": 5},
			{"type": ObjectiveType.DELIVER, "target": "deliver_to_blacksmith", "description": "送回铁匠铺", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 200},
			{"type": "gold", "amount": 150},
			{"type": "item", "item_id": "item_blacksmith_weapon", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_002_data)

	# 洛阳区域支线任务3：河神传说
	var luoyang_003_data: Dictionary = {
		"quest_id": "luoyang_003",
		"title": "河神传说",
		"description": "洛水河畔祭祀河神，但河神实际上是水怪",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "village_elder_talk", "description": "与村民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_luoshui_riverside", "description": "前往洛水河畔", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "kill_luoshui_water_monster", "description": "击败洛水水怪", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "village_elder_truth", "description": "告知村民真相", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 200},
			{"type": "item", "item_id": "item_luoshui_pearl", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_003_data)

	# 洛阳区域支线任务4：少林武僧的烦恼
	var luoyang_004_data: Dictionary = {
		"quest_id": "luoyang_004",
		"title": "少林武僧的烦恼",
		"description": "少林武僧在嵩山修炼时丢失了戒牒",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "shaolin_monk_talk", "description": "与武僧交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_songshan", "description": "搜索嵩山", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_monks_certificate", "description": "找到戒牒", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "deliver_to_monk", "description": "还给武僧", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 350},
			{"type": "gold", "amount": 100},
			{"type": "flag", "flag": "shaolin_reputation", "value": 20}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_004_data)

	# 洛阳区域支线任务5：渡口危机
	var luoyang_005_data: Dictionary = {
		"quest_id": "luoyang_005",
		"title": "渡口危机",
		"description": "孟津渡口被水贼占据，商人无法过河",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "ferryman_talk", "description": "与渡口艄公交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_mengjin_ferry", "description": "前往孟津渡口", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "kill_pirate_leader", "description": "击败水贼头目", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "ferryman_restore", "description": "恢复渡口秩序", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 300},
			{"type": "flag", "flag": "fame_reputation", "value": 30}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_005_data)

	# 洛阳区域支线任务6：矿工的血泪
	var luoyang_006_data: Dictionary = {
		"quest_id": "luoyang_006",
		"title": "矿工的血泪",
		"description": "中条山脉矿洞坍塌，被困矿工需要救援",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "miner_family_talk", "description": "与矿工家属交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_zhongtiao_mountain", "description": "前往中条山脉", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "rescue_trapped_miner", "description": "救出被困矿工", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "miner_family_report", "description": "回报矿工家属", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 450},
			{"type": "gold", "amount": 200},
			{"type": "flag", "flag": "miners_gratitude", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_006_data)

	# 洛阳区域支线任务7：琴音怨
	var luoyang_007_data: Dictionary = {
		"quest_id": "luoyang_007",
		"title": "琴音怨",
		"description": "洛阳城中每晚传来凄婉琴声，原来是一位悲伤的乐师",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "sad_musician_talk", "description": "与乐师交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_her_lover_grave", "description": "找到她思念之人的坟墓", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_grave_flowers", "description": "采集墓前鲜花", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "deliver_flowers_to_musician", "description": "送给乐师", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 300},
			{"type": "gold", "amount": 150},
			{"type": "item", "item_id": "item_luoshen_music_score", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_007_data)

	# 洛阳区域支线任务8：巩义窑变
	var luoyang_008_data: Dictionary = {
		"quest_id": "luoyang_008",
		"title": "巩义窑变",
		"description": "巩义镇的瓷器工艺失传，需要找回秘方",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "porcelain_craftsman_talk", "description": "与瓷器匠人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_ancient_tomb", "description": "古墓探索", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "item_ancient_porcelain_recipe", "description": "找到古瓷秘方", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "deliver_recipe_to_craftsman", "description": "交给匠人", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 250},
			{"type": "item", "item_id": "item_gongyi_porcelain", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_008_data)

	# 洛阳区域支线任务9：北岭猎户的困境
	var luoyang_009_data: Dictionary = {
		"quest_id": "luoyang_009",
		"title": "北岭猎户的困境",
		"description": "北岭猎户被猛虎威胁，无法下山",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "northern_hunter_talk", "description": "与猎户交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "visit_northern_ridge", "description": "深入北岭", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "kill_white_tiger", "description": "击败白额猛虎", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "hunter_help_down", "description": "帮助猎户下山", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "item_tiger_pelt", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_009_data)

	# 洛阳区域支线任务10：偃师古道
	var luoyang_010_data: Dictionary = {
		"quest_id": "luoyang_010",
		"title": "偃师古道",
		"description": "偃师古道上出现山贼，需要护送商队",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "caravan_leader_talk", "description": "与商队领队交谈", "amount": 1},
			{"type": ObjectiveType.ESCORT, "target": "escort_caravan_to_weinan", "description": "护送商队至渭南", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "weinan_merchant_talk", "description": "与渭南商人交谈", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 350},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "caravan_reward", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(luoyang_010_data)

func _define_sect_quests() -> void:
	# 少林寺 - 禅武合一（sect_001）
	var sect_001_data: Dictionary = {
		"quest_id": "sect_001",
		"title": "禅武合一",
		"description": "方丈考验你的武艺和佛心",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "shaolin_abbot_talk",
				"description": "与方丈对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "shaolin_monk",
				"description": "击败武僧",
				"amount": 3
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "buddhist_sutra_copy",
				"description": "抄写佛经",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "shaolin_abbot_talk_pass",
				"description": "通过考验",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1000},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "sect_shaolin_joined", "value": true}
		],
		"prerequisites": ["main_001"],
		"repeatable": false
	}
	add_custom_quest(sect_001_data)
	
	# 八卦门 - 阵法奥秘（sect_002）
	var sect_002_data: Dictionary = {
		"quest_id": "sect_002",
		"title": "阵法奥秘",
		"description": "八卦门主传授阵法之道",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "bagua_master_talk",
				"description": "与门主对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "bagua_formation_field",
				"description": "前往阵法场",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "bagua_symbol",
				"description": "收集八卦符",
				"amount": 8
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "bagua_symbols",
				"description": "激活阵法",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 800},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "item_bagua_map", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_002_data)
	
	# 百花谷 - 花间秘辛（sect_003）
	var sect_003_data: Dictionary = {
		"quest_id": "sect_003",
		"title": "花间秘辛",
		"description": "花间派主考验你的暗器和幻术",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "huajian_master_talk",
				"description": "与派主对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "huajian_disciple",
				"description": "击败花间弟子",
				"amount": 3
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "sleep_powder",
				"description": "配制迷香",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "huajian_master_recognize",
				"description": "派主认可",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 900},
			{"type": "gold", "amount": 450},
			{"type": "flag", "flag": "sect_huajian_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_003_data)
	
	# 红莲教 - 深入虎穴（sect_004）
	var sect_004_data: Dictionary = {
		"quest_id": "sect_004",
		"title": "深入虎穴",
		"description": "红莲教需要新人完成试炼",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "honglian_guardian_talk",
				"description": "与护教使者对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "honglian_enemy",
				"description": "击败敌人",
				"amount": 5
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "sacrifice_offering",
				"description": "献上祭品",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "honglian_guardian_accept",
				"description": "成为教徒",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1200},
			{"type": "gold", "amount": 600},
			{"type": "flag", "flag": "sect_honglian_joined", "value": true}
		],
		"prerequisites": ["main_003"],
		"repeatable": false
	}
	add_custom_quest(sect_004_data)
	
	# 那迦派 - 忍者之道（sect_005）
	var sect_005_data: Dictionary = {
		"quest_id": "sect_005",
		"title": "忍者之道",
		"description": "那迦派考验忍者的隐匿和刺杀能力",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "naga_master_talk",
				"description": "与派主对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "assassination_target",
				"description": "完成刺杀任务",
				"amount": 3
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "secret_passage",
				"description": "潜入密道",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "naga_master_recognize",
				"description": "派主认可",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1000},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "sect_naga_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_005_data)
	
	# 太极门 - 阴阳之道（sect_006）
	var sect_006_data: Dictionary = {
		"quest_id": "sect_006",
		"title": "阴阳之道",
		"description": "太极门主传授太极功法",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "taiji_master_talk",
				"description": "与掌门对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "taiji_meditation",
				"description": "感悟太极",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "taiji_disciple",
				"description": "击败太极弟子",
				"amount": 3
			},
			{
				"type": ObjectiveType.TALK,
				"target": "taiji_master_teach",
				"description": "传授功法",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1100},
			{"type": "gold", "amount": 550},
			{"type": "flag", "flag": "sect_taiji_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_006_data)
	
	# 雪山派 - 冰封之巅（sect_007）
	var sect_007_data: Dictionary = {
		"quest_id": "sect_007",
		"title": "冰封之巅",
		"description": "雪山派在极寒之地修炼，需要考验",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "xueshan_master_talk",
				"description": "与掌门对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "xueshan_mountain",
				"description": "攀登雪山",
				"amount": 1
			},
			{
				"type": ObjectiveType.DEFEND,
				"target": "cold_wind",
				"description": "抵御寒风",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "ice_soul",
				"description": "收集冰魄",
				"amount": 5
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "ice_souls",
				"description": "献给掌门",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1200},
			{"type": "gold", "amount": 700},
			{"type": "flag", "flag": "sect_xueshan_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_007_data)
	
	# 逍遥宫 - 无拘无束（sect_008）
	var sect_008_data: Dictionary = {
		"quest_id": "sect_008",
		"title": "无拘无束",
		"description": "逍遥宫收徒讲究缘分",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "xiaoyao_master_talk",
				"description": "与派主对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "xiaoyao_treasure_1",
				"description": "寻找逍遥三宝（地点1）",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "xiaoyao_treasure_2",
				"description": "寻找逍遥三宝（地点2）",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "xiaoyao_treasure_3",
				"description": "寻找逍遥三宝（地点3）",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "xiaoyao_treasures",
				"description": "收集宝物",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "xiaoyao_master",
				"description": "献给派主",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1300},
			{"type": "gold", "amount": 800},
			{"type": "flag", "flag": "sect_xiaoyao_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_008_data)
	
	# 峨眉派 - 普度众生（sect_009）
	var sect_009_data: Dictionary = {
		"quest_id": "sect_009",
		"title": "普度众生",
		"description": "峨眉派注重慈悲为怀",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "emei_abbot_talk",
				"description": "与住持对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "rescue_injured",
				"description": "救助伤者",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "mountain_bandit",
				"description": "击败山贼",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "emei_abbot_recognize",
				"description": "住持认可",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 900},
			{"type": "gold", "amount": 450},
			{"type": "flag", "flag": "sect_emei_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_009_data)
	
	# 华山派 - 剑出华山（sect_010）
	var sect_010_data: Dictionary = {
		"quest_id": "sect_010",
		"title": "剑出华山",
		"description": "华山论剑是武林盛事",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "huashan_disciple_talk",
				"description": "与华山弟子对话",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "sword_duel_opponent",
				"description": "击败论剑对手",
				"amount": 5
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "huashan_duel_platform",
				"description": "前往论剑台",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "huashan_master_recognize",
				"description": "华山掌门认可",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 1000},
			{"type": "gold", "amount": 600},
			{"type": "flag", "flag": "sect_huashan_joined", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(sect_010_data)

func _define_changan_quests() -> void:
	var changan_001_data: Dictionary = {
		"quest_id": "changan_001",
		"title": "皇宫疑云",
		"description": "皇宫中出现可疑人物，需要调查",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "changan_guard_talk",
				"description": "与皇帝侍卫交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_palace_patrol",
				"description": "在皇宫巡逻",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_suspicious_letter",
				"description": "找到可疑信件",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "deliver_letter_guard",
				"description": "交给侍卫",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "item_palace_token", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_001_data)

	var changan_002_data: Dictionary = {
		"quest_id": "changan_002",
		"title": "凤翔古道",
		"description": "凤翔镇古道上驿站废弃，商人苦不堪言",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "merchant_talk",
				"description": "与商人交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_fengxiang_station",
				"description": "前往凤翔驿站",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "repair_station_facility",
				"description": "修复驿站设施（对话）",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "notify_merchant",
				"description": "通知商人",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 350},
			{"type": "item", "item_id": "item_station_repair_fee", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_002_data)

	var changan_003_data: Dictionary = {
		"quest_id": "changan_003",
		"title": "秦陵探险",
		"description": "考古学者在咸阳研究秦陵，发现盗墓贼踪迹",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "archaeologist_talk",
				"description": "与考古学者交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_qinling_site",
				"description": "前往秦陵原",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_tomb_robber",
				"description": "击败盗墓贼",
				"amount": 4
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_stolen_artifact",
				"description": "追回被盗文物",
				"amount": 1
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "deliver_artifact_scholar",
				"description": "交给学者",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "item_qinling_map", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_003_data)

	var changan_004_data: Dictionary = {
		"quest_id": "changan_004",
		"title": "华山论剑",
		"description": "华山即将举办论剑大会，各派高手云集",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "huashan_disciple_invite",
				"description": "华山弟子邀请",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_huashan_peak",
				"description": "前往华山险峰",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_martial_expert",
				"description": "击败各派高手",
				"amount": 5
			},
			{
				"type": ObjectiveType.TALK,
				"target": "huashan_master_talk",
				"description": "与华山掌门交谈",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 800},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "huashan_faction_relation", "value": 50}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_004_data)

	var changan_005_data: Dictionary = {
		"quest_id": "changan_005",
		"title": "潼关烽火",
		"description": "潼关遭遇敌军袭击，守关将士紧缺",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "tongguan_soldier_talk",
				"description": "与守关将士交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_tongguan_pass",
				"description": "前往潼关古道",
				"amount": 1
			},
			{
				"type": ObjectiveType.DEFEND,
				"target": "defend_tongguan_pass",
				"description": "坚守关口",
				"amount": 3
			},
			{
				"type": ObjectiveType.TALK,
				"target": "veteran_talk",
				"description": "与老兵交谈",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 700},
			{"type": "gold", "amount": 600},
			{"type": "flag", "flag": "tongguan_hero_title", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_005_data)

	var changan_006_data: Dictionary = {
		"quest_id": "changan_006",
		"title": "临潼温泉",
		"description": "临潼温泉有神奇疗效，但被恶霸霸占",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "hotspring_steward_talk",
				"description": "与温泉管事交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_lintong_hotspring",
				"description": "调查温泉",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_local_bully",
				"description": "击败恶霸",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "restore_hotspring_order",
				"description": "恢复温泉秩序",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "item_hotspring_token", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_006_data)

	var changan_007_data: Dictionary = {
		"quest_id": "changan_007",
		"title": "咸阳古董",
		"description": "古董商声称有件稀世珍宝，但需要验证真伪",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "antique_dealer_talk",
				"description": "与古董商交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_antique_shop",
				"description": "查看古董",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_appraisal_material",
				"description": "收集鉴定材料",
				"amount": 3
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "complete_appraisal",
				"description": "完成鉴定",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 350},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "item_antique_appraisal_cert", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_007_data)

	var changan_008_data: Dictionary = {
		"quest_id": "changan_008",
		"title": "渭河渔歌",
		"description": "渭河渔民遭受水怪侵扰，无法正常捕鱼",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "fisherman_talk",
				"description": "与渔夫交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_weihe_plain",
				"description": "前往渭河平原",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_water_monster",
				"description": "击败水怪",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "report_fisherman",
				"description": "回报渔夫",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 250},
			{"type": "item", "item_id": "item_big_fish_harvest", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_008_data)

	var changan_009_data: Dictionary = {
		"quest_id": "changan_009",
		"title": "沙漠商队",
		"description": "陇西沙漠中商队失踪，需要搜寻",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "missing_caravan_family_talk",
				"description": "与失踪商队家属交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_longxi_desert",
				"description": "前往陇西荒漠",
				"amount": 1
			},
			{
				"type": ObjectiveType.KILL,
				"target": "enemy_bandit",
				"description": "击败马贼",
				"amount": 1
			},
			{
				"type": ObjectiveType.ESCORT,
				"target": "escort_caravan_changan",
				"description": "护送商队回长安",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 800},
			{"type": "flag", "flag": "guild_thanks", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_009_data)

	var changan_010_data: Dictionary = {
		"quest_id": "changan_010",
		"title": "终南捷径",
		"description": "传闻终南山中有隐士掌握长生秘诀",
		"objectives": [
			{
				"type": ObjectiveType.TALK,
				"target": "taoist_temple_monk_talk",
				"description": "与道观道士交谈",
				"amount": 1
			},
			{
				"type": ObjectiveType.VISIT,
				"target": "visit_zhongnan_mountain",
				"description": "攀登终南山",
				"amount": 1
			},
			{
				"type": ObjectiveType.TALK,
				"target": "hermit_visit",
				"description": "拜访隐士",
				"amount": 1
			},
			{
				"type": ObjectiveType.COLLECT,
				"target": "item_heavenly_treasure",
				"description": "收集天材地宝",
				"amount": 3
			},
			{
				"type": ObjectiveType.DELIVER,
				"target": "offer_hermit",
				"description": "献给隐士",
				"amount": 1
			}
		],
		"rewards": [
			{"type": "experience", "amount": 700},
			{"type": "gold", "amount": 500},
			{"type": "flag", "flag": "hermit_guidance", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(changan_010_data)

func _define_chengdu_quests() -> void:
	var chengdu_001_data: Dictionary = {
		"quest_id": "chengdu_001",
		"title": "峨眉金顶",
		"description": "峨眉派邀请武林人士参加佛光法会",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "emei_disciple_talk", "description": "与峨眉弟子交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "emei_sacred_mountain", "description": "前往峨眉圣山", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "attend_ceremony", "description": "参加法会", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "head_monks_talk", "description": "与住持交谈", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "emei_incense", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_001_data)
	
	var chengdu_002_data: Dictionary = {
		"quest_id": "chengdu_002",
		"title": "蜀道天险",
		"description": "蜀道栈道年久失修，行人坠落",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "injured_passenger_talk", "description": "与受伤行人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "shudao_mountains", "description": "前往蜀道群山", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "repair_plank_road", "description": "修复栈道", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "report_to_passenger", "description": "回报行人", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 350},
			{"type": "flag", "flag": "shudao_pass_free", "value": true}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_002_data)
	
	var chengdu_003_data: Dictionary = {
		"quest_id": "chengdu_003",
		"title": "熊猫危机",
		"description": "巴蜀竹海的大熊猫被偷猎者威胁",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "bamboo_farmer_talk", "description": "与竹农交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "bashu_bamboo_sea", "description": "前往巴蜀竹海", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "poachers", "description": "击败偷猎者", "amount": 1},
			{"type": ObjectiveType.ESCORT, "target": "escort_panda", "description": "护送熊猫回安全地带", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 450},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "panda_token", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_003_data)
	
	var chengdu_004_data: Dictionary = {
		"quest_id": "chengdu_004",
		"title": "都江古堰",
		"description": "都江堰出现险情，需要紧急修复",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "water_manager_talk", "description": "与水利管事交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "dujiang_ancient_weir", "description": "前往都江古堰", "amount": 1},
			{"type": ObjectiveType.DEFEND, "target": "defeat_water_monster", "description": "击退来袭水怪", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "assist_repair", "description": "协助修复堤坝", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 500},
			{"type": "item", "item_id": "dujiang_record", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_004_data)
	
	var chengdu_005_data: Dictionary = {
		"quest_id": "chengdu_005",
		"title": "青城问道",
		"description": "青城山道士研究长生之术，需要材料",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "taoist_talk", "description": "与道士交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "qingcheng_mountain", "description": "前往青城山", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "lingzhi_mushroom", "description": "采集灵芝", "amount": 5},
			{"type": ObjectiveType.DELIVER, "target": "deliver_lingzhi", "description": "交给道士", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 250},
			{"type": "item", "item_id": "qingcheng_elixir", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_005_data)
	
	var chengdu_006_data: Dictionary = {
		"quest_id": "chengdu_006",
		"title": "西岭雪崩",
		"description": "西岭高原发生雪崩，有旅人被困",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "tibetan_talk", "description": "与藏民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "xiling_plateau", "description": "前往西岭高原", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "rescue_trapped", "description": "救出被困旅人", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "celebrate_with_tibetan", "description": "与藏民庆祝", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "snow_mountain_guide", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_006_data)
	
	var chengdu_007_data: Dictionary = {
		"quest_id": "chengdu_007",
		"title": "新都丰收",
		"description": "新都平原丰收在即，但野猪泛滥",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "farmer_talk", "description": "与农夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "xindu_plains", "description": "前往新都平原", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "wild_boars", "description": "驱逐野猪", "amount": 6},
			{"type": ObjectiveType.TALK, "target": "help_harvest", "description": "帮助收割", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 350},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "bountiful_harvest", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_007_data)
	
	var chengdu_008_data: Dictionary = {
		"quest_id": "chengdu_008",
		"title": "岷江船歌",
		"description": "岷江河谷船夫被水妖困扰",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "fisherman_talk", "description": "与渔夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "min_river_valley", "description": "前往岷江河谷", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "water_demon", "description": "击败水妖", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "silkworm_lady_talk", "description": "与蚕娘交谈", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 250},
			{"type": "item", "item_id": "min_brocade", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_008_data)
	
	var chengdu_009_data: Dictionary = {
		"quest_id": "chengdu_009",
		"title": "温江花会",
		"description": "温江花田举办花会，需要保护花农",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "flower_farmer_talk", "description": "与花农交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "wenjiang_flower_field", "description": "前往温江花田", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "trouble_bully", "description": "击败捣乱恶霸", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "attend_flower_festival", "description": "参加花会", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 300},
			{"type": "gold", "amount": 350},
			{"type": "item", "item_id": "wenjiang_flower_seed", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_009_data)
	
	var chengdu_010_data: Dictionary = {
		"quest_id": "chengdu_010",
		"title": "双流马帮",
		"description": "双流镇马帮商队被山贼劫持",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "caravan_leader_talk", "description": "与马帮领队交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "shudao_mountains", "description": "前往蜀道群山", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "mountain_bandits", "description": "击败山贼", "amount": 1},
			{"type": ObjectiveType.ESCORT, "target": "escort_to_chengdu", "description": "护送商队到成都", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 550},
			{"type": "gold", "amount": 600},
			{"type": "item", "item_id": "caravan_pass", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(chengdu_010_data)

func _define_jiangling_quests() -> void:
	var jiangling_001_data: Dictionary = {
		"quest_id": "jiangling_001",
		"title": "武当问道",
		"description": "武当山广招天下英豪，考验心性",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "wudang_disciple_talk", "description": "与武当弟子交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "wudang_mountain", "description": "前往武当山", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "accept_trial", "description": "接受问心考验", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "pass_trial", "description": "通过考验", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 700},
			{"type": "gold", "amount": 500},
			{"type": "item", "item_id": "wudang_sword_manual", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_001_data)
	
	var jiangling_002_data: Dictionary = {
		"quest_id": "jiangling_002",
		"title": "三峡纤夫",
		"description": "三峡险滩纤夫们急需帮助",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "old_trackman_talk", "description": "与老纤夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "three_gorges_rapids", "description": "前往三峡险滩", "amount": 1},
			{"type": ObjectiveType.ESCORT, "target": "assist_tracking", "description": "协助拉纤过滩", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "trackman_thanks", "description": "纤夫感谢", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 400},
			{"type": "gold", "amount": 350},
			{"type": "item", "item_id": "three_gorges_map", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_002_data)
	
	var jiangling_003_data: Dictionary = {
		"quest_id": "jiangling_003",
		"title": "神农采药",
		"description": "神农架采药人需要珍稀药材",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "herb_gatherer_talk", "description": "与采药人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "shennongjia", "description": "前往神农架", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "nine_leaf_lingzhi", "description": "采集九叶灵芝", "amount": 3},
			{"type": ObjectiveType.DELIVER, "target": "deliver_herb", "description": "交给采药人", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 500},
			{"type": "item", "item_id": "shennong_herbal", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_003_data)
	
	var jiangling_004_data: Dictionary = {
		"quest_id": "jiangling_004",
		"title": "云梦仙子",
		"description": "云梦泽传说有仙子出没",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "fisherman_talk", "description": "与渔民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "yunmeng_ze", "description": "前往云梦泽", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "find_fairy", "description": "寻找仙子", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "fairy_dialogue", "description": "仙子对话", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "yunmeng_token", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_004_data)
	
	var jiangling_005_data: Dictionary = {
		"quest_id": "jiangling_005",
		"title": "汉江渡口",
		"description": "汉江渡口被水贼封锁",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "boatman_talk", "description": "与船夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "han_river_bank", "description": "前往汉江河畔", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "water_bandits", "description": "击败水贼", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "restore_order", "description": "恢复渡口秩序", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 450},
			{"type": "gold", "amount": 300},
			{"type": "item", "item_id": "ferry_right", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_005_data)
	
	var jiangling_006_data: Dictionary = {
		"quest_id": "jiangling_006",
		"title": "当阳英魂",
		"description": "当阳古战场常有冤魂作祟",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "graveyard_keeper_talk", "description": "与守墓人交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "dangyang_plains", "description": "前往当阳平原", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "wrong_souls", "description": "超度冤魂", "amount": 3},
			{"type": ObjectiveType.TALK, "target": "keeper_thanks", "description": "守墓人感谢", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 350},
			{"type": "item", "item_id": "dangyang_hero_sword", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_006_data)
	
	var jiangling_007_data: Dictionary = {
		"quest_id": "jiangling_007",
		"title": "伏牛宝藏",
		"description": "伏牛山传说有古墓宝藏",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "woodcutter_talk", "description": "与樵夫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "funiu_mountain", "description": "前往伏牛山", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "tomb_guardians", "description": "击败墓穴守卫", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "treasure_box", "description": "找到宝藏", "amount": 1},
			{"type": ObjectiveType.DELIVER, "target": "give_part_to_woodcutter", "description": "部分交给樵夫", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 600},
			{"type": "gold", "amount": 800},
			{"type": "item", "item_id": "funiu_secret_map", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_007_data)
	
	var jiangling_008_data: Dictionary = {
		"quest_id": "jiangling_008",
		"title": "夷陵峡谷",
		"description": "夷陵峡谷发现稀有矿石",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "guard_talk", "description": "与守卫交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "yiling_gorge", "description": "前往夷陵峡谷", "amount": 1},
			{"type": ObjectiveType.COLLECT, "target": "精金矿", "description": "采集精金矿", "amount": 5},
			{"type": ObjectiveType.DELIVER, "target": "deliver_ore", "description": "交给守卫", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 450},
			{"type": "gold", "amount": 400},
			{"type": "item", "item_id": "精金矿石", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_008_data)
	
	var jiangling_009_data: Dictionary = {
		"quest_id": "jiangling_009",
		"title": "大巴猎户",
		"description": "大巴山猎户被猛兽威胁",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "mountain_folk_talk", "description": "与山民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "daba_mountain", "description": "前往大巴山", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "black_bear", "description": "击败黑熊", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "folk_grateful", "description": "山民感激", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 500},
			{"type": "gold", "amount": 350},
			{"type": "item", "item_id": "beast_fur_coat", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_009_data)
	
	var jiangling_010_data: Dictionary = {
		"quest_id": "jiangling_010",
		"title": "长江龙王",
		"description": "江陵渔民祭拜长江龙王，但龙王已被妖魔取代",
		"objectives": [
			{"type": ObjectiveType.TALK, "target": "old_fisherman_talk", "description": "与老渔民交谈", "amount": 1},
			{"type": ObjectiveType.VISIT, "target": "jiangling_dock", "description": "前往江陵码头", "amount": 1},
			{"type": ObjectiveType.KILL, "target": "fake_dragon_king", "description": "击败假龙王", "amount": 1},
			{"type": ObjectiveType.TALK, "target": "worship_real_dragon", "description": "渔民祭拜真龙王", "amount": 1}
		],
		"rewards": [
			{"type": "experience", "amount": 700},
			{"type": "gold", "amount": 600},
			{"type": "item", "item_id": "dragon_king_amulet", "amount": 1}
		],
		"prerequisites": [],
		"repeatable": false
	}
	add_custom_quest(jiangling_010_data)

func _register_quest_definition(quest_data: Resource) -> void:
	if quest_data.get("quest_id") == null:
		return
	
	_quest_definitions[quest_data.quest_id] = quest_data

# 开始任务
func start_quest(quest_id: String) -> bool:
	if not _quest_definitions.has(quest_id):
		push_error("QuestSystem: 找不到任务定义 - " + quest_id)
		return false
	
	if _active_quests.has(quest_id):
		push_warning("QuestSystem: 任务已在进行中 - " + quest_id)
		return false
	
	if _completed_quests.has(quest_id):
		push_warning("QuestSystem: 任务已完成，无法再次开始 - " + quest_id)
		return false
	
	var quest_data: Resource = _quest_definitions[quest_id]
	
	if not _check_quest_prerequisites(quest_data):
		push_warning("QuestSystem: 任务前置条件不满足 - " + quest_id)
		return false
	
	var quest_entry: Dictionary = {
		"quest_id": quest_id,
		"state": QuestState.ACTIVE,
		"current_objective": 0,
		"objective_progress": {},
		"started_at": Time.get_ticks_msec(),
		"completed_objectives": [],
		"tracked": false
	}
	
	for i: int in range(_get_objective_count(quest_data)):
		quest_entry.objective_progress[i] = 0
	
	_active_quests[quest_id] = quest_entry
	
	quest_started.emit(quest_id)
	_update_tracked_quest(quest_id)
	
	return true

# 检查任务前置条件
func _check_quest_prerequisites(quest_data: Resource) -> bool:
	if quest_data.get("prerequisites") == null:
		return true
	
	var prerequisites: Array = quest_data.prerequisites
	
	if prerequisites.size() > 0:
		var first_item = prerequisites[0]
		if first_item is String:
			for prereq_quest_id: String in prerequisites:
				if not _completed_quests.has(prereq_quest_id):
					return false
			return true
	
	for prereq: Dictionary in prerequisites:
		var prereq_type: String = prereq.get("type", "")
		
		match prereq_type:
			"quest_completed":
				var required_quest: String = prereq.get("quest_id", "")
				if not _completed_quests.has(required_quest):
					return false
			
			"quest_active":
				var required_quest: String = prereq.get("quest_id", "")
				if not _active_quests.has(required_quest):
					return false
			
			"item_owned":
				var item_id: String = prereq.get("item_id", "")
				var amount: int = prereq.get("amount", 1)
				if not _check_player_has_item(item_id, amount):
					return false
			
			"flag_set":
				var flag_name: String = prereq.get("flag", "")
				var flag_value: bool = prereq.get("value", true)
				if not _check_flag(flag_name, flag_value):
					return false
	
	return true

# 检查玩家是否拥有物品
func _check_player_has_item(item_id: String, amount: int) -> bool:
	var inventory_system: Node = Engine.get_meta("InventorySystem")
	if not inventory_system:
		return false
	return inventory_system.has_item(item_id, amount)

# 检查标志
func _check_flag(flag_name: String, expected_value: bool) -> bool:
	var dialogue_manager: Node = Engine.get_meta("DialogueManager")
	if not dialogue_manager:
		return false
	return dialogue_manager.has_flag(flag_name) == expected_value

# 获取任务定义
func _get_quest_definition(quest_id: String) -> Resource:
	return _quest_definitions.get(quest_id, null)

# 获取目标数量
func _get_objective_count(quest_data: Resource) -> int:
	if quest_data.get("objectives") != null:
		return quest_data.objectives.size()
	return 0

# 更新任务进度
func update_quest(quest_id: String, objective_index: int, progress_amount: int = 1) -> void:
	if not _active_quests.has(quest_id):
		push_warning("QuestSystem: 任务不在进行中 - " + quest_id)
		return
	
	var quest_data: Resource = _get_quest_definition(quest_id)
	if not quest_data or quest_data.get("objectives") == null:
		return
	
	if objective_index < 0 or objective_index >= quest_data.objectives.size():
		push_error("QuestSystem: 无效的目标索引 - " + str(objective_index))
		return
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	var objectives: Array = quest_data.objectives
	var objective: Dictionary = objectives[objective_index]
	
	var current_progress: int = quest_entry.objective_progress.get(objective_index, 0)
	var target_amount: int = objective.get("amount", 1)
	var new_progress: int = current_progress + progress_amount
	
	quest_entry.objective_progress[objective_index] = mini(new_progress, target_amount)
	
	quest_updated.emit(quest_id, objective_index)
	
	if quest_entry.objective_progress[objective_index] >= target_amount:
		_complete_objective(quest_id, objective_index)

# 完成单个目标
func _complete_objective(quest_id: String, objective_index: int) -> void:
	if not _active_quests.has(quest_id):
		return
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	
	if quest_entry.completed_objectives.has(objective_index):
		return
	
	quest_entry.completed_objectives.append(objective_index)
	
	objective_completed.emit(quest_id, objective_index)
	
	var quest_data: Resource = _get_quest_definition(quest_id)
	if quest_data and quest_data.get("objectives") != null:
		if quest_entry.completed_objectives.size() >= quest_data.objectives.size():
			complete_quest(quest_id)

# 完成任务
func complete_quest(quest_id: String) -> void:
	if not _active_quests.has(quest_id):
		push_warning("QuestSystem: 任务不在进行中 - " + quest_id)
		return
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	quest_entry["state"] = QuestState.COMPLETED
	quest_entry["completed_at"] = Time.get_ticks_msec()
	
	_completed_quests.append(quest_id)
	
	if _tracked_quest_id == quest_id:
		_tracked_quest_id = ""
	
	_apply_quest_rewards(quest_id)
	
	_active_quests.erase(quest_id)
	
	quest_completed.emit(quest_id)

# 失败任务
func fail_quest(quest_id: String) -> void:
	if not _active_quests.has(quest_id):
		push_warning("QuestSystem: 任务不在进行中 - " + quest_id)
		return
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	quest_entry["state"] = QuestState.FAILED
	quest_entry["failed_at"] = Time.get_ticks_msec()
	
	_failed_quests.append(quest_id)
	
	if _tracked_quest_id == quest_id:
		_tracked_quest_id = ""
	
	_active_quests.erase(quest_id)
	
	quest_failed.emit(quest_id)

# 应用任务奖励
func _apply_quest_rewards(quest_id: String) -> void:
	var quest_data: Resource = _get_quest_definition(quest_id)
	if not quest_data or quest_data.get("rewards") == null:
		return
	
	var rewards: Array = quest_data.rewards
	
	for reward: Dictionary in rewards:
		var reward_type: String = reward.get("type", "")
		
		match reward_type:
			"experience":
				var amount: int = reward.get("amount", 0)
				_give_experience(amount)
			
			"gold":
				var amount: int = reward.get("amount", 0)
				_give_gold(amount)
			
			"item":
				var item_id: String = reward.get("item_id", "")
				var amount: int = reward.get("amount", 1)
				_give_item(item_id, amount)
			
			"flag":
				var flag_name: String = reward.get("flag", "")
				var value: Variant = reward.get("value", true)
				_set_flag(flag_name, value)

# 给予经验
func _give_experience(amount: int) -> void:
	var player: Node = _get_player_node()
	if player and player.has_method("add_experience"):
		player.add_experience(amount)

# 给予金币
func _give_gold(amount: int) -> void:
	var inventory_system: Node = Engine.get_meta("InventorySystem")
	if inventory_system and inventory_system.has_method("add_gold"):
		inventory_system.add_gold(amount)

# 给予物品
func _give_item(item_id: String, amount: int) -> void:
	var inventory_system: Node = Engine.get_meta("InventorySystem")
	if inventory_system and inventory_system.has_method("add_item"):
		inventory_system.add_item(item_id, amount)

# 设置标志
func _set_flag(flag_name: String, value: Variant) -> void:
	var dialogue_manager: Node = Engine.get_meta("DialogueManager")
	if dialogue_manager and dialogue_manager.has_method("set_flag"):
		dialogue_manager.set_flag(flag_name, value)

# 获取玩家节点
func _get_player_node() -> Node:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		return scene_tree.root.get_node_or_null("Main/Player")
	return null

# 检查任务是否进行中
func is_quest_active(quest_id: String) -> bool:
	return _active_quests.has(quest_id)

# 检查任务是否已完成
func is_quest_completed(quest_id: String) -> bool:
	return _completed_quests.has(quest_id)

# 检查任务是否失败
func is_quest_failed(quest_id: String) -> bool:
	return _failed_quests.has(quest_id)

# 获取任务进度
func get_quest_progress(quest_id: String) -> int:
	if _active_quests.has(quest_id):
		var quest_entry: Dictionary = _active_quests[quest_id]
		return quest_entry.completed_objectives.size()
	elif _completed_quests.has(quest_id):
		var quest_data: Resource = _get_quest_definition(quest_id)
		if quest_data and quest_data.get("objectives") != null:
			return quest_data.objectives.size()
		return 1
	return 0

func get_quest_total_objectives(quest_id: String) -> int:
	var quest_data: Resource = _get_quest_definition(quest_id)
	if quest_data and quest_data.get("objectives") != null:
		return quest_data.objectives.size()
	return 0

# 获取任务详细信息
func get_quest_details(quest_id: String) -> Dictionary:
	if not _active_quests.has(quest_id):
		return {}
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	var quest_data: Resource = _get_quest_definition(quest_id)
	
	var details: Dictionary = {
		"quest_id": quest_id,
		"state": quest_entry.state,
		"current_objective": quest_entry.current_objective,
		"progress": get_quest_progress(quest_id),
		"total_objectives": get_quest_total_objectives(quest_id)
	}
	
	if quest_data:
		var title_val = quest_data.get("title")
		details["title"] = title_val if title_val != null else "未知任务"
		var desc_val = quest_data.get("description")
		details["description"] = desc_val if desc_val != null else ""
		var obj_val = quest_data.get("objectives")
		details["objectives"] = obj_val if obj_val != null else []
	
	return details

# 检查是否可以接受任务
func can_accept_quest(quest_id: String) -> bool:
	if _active_quests.has(quest_id):
		return false
	
	if _completed_quests.has(quest_id):
		return false
	
	if not _quest_definitions.has(quest_id):
		return false
	
	var quest_data: Resource = _quest_definitions[quest_id]
	return _check_quest_prerequisites(quest_data)

# 获取当前任务列表
func get_active_quests() -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	
	for quest_id: String in _active_quests.keys():
		quests.append(get_quest_details(quest_id))
	
	return quests

# 获取已完成任务列表
func get_completed_quests() -> Array[String]:
	return _completed_quests.duplicate()

# 获取失败任务列表
func get_failed_quests() -> Array[String]:
	return _failed_quests.duplicate()

# 设置追踪任务
func set_tracked_quest(quest_id: String) -> void:
	if not quest_id.is_empty() and not _active_quests.has(quest_id):
		push_warning("QuestSystem: 无法追踪未进行的任务 - " + quest_id)
		return
	
	if not _tracked_quest_id.is_empty() and _active_quests.has(_tracked_quest_id):
		_active_quests[_tracked_quest_id].tracked = false
	
	_tracked_quest_id = quest_id
	
	if _active_quests.has(quest_id):
		_active_quests[quest_id].tracked = true
	
	quest_tracked_changed.emit(quest_id)

# 获取追踪任务ID
func get_tracked_quest() -> String:
	return _tracked_quest_id

# 获取追踪任务详情
func get_tracked_quest_details() -> Dictionary:
	if _tracked_quest_id.is_empty():
		return {}
	return get_quest_details(_tracked_quest_id)

# 更新追踪任务
func _update_tracked_quest(new_quest_id: String) -> void:
	if _tracked_quest_id.is_empty():
		set_tracked_quest(new_quest_id)

# 获取特定目标进度
func get_objective_progress(quest_id: String, objective_index: int) -> int:
	if not _active_quests.has(quest_id):
		return 0
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	return quest_entry.objective_progress.get(objective_index, 0)

# 获取特定目标详情
func get_objective_details(quest_id: String, objective_index: int) -> Dictionary:
	var quest_data: Resource = _get_quest_definition(quest_id)
	if not quest_data or quest_data.get("objectives") == null:
		return {}
	
	var objectives: Array = quest_data.objectives
	if objective_index < 0 or objective_index >= objectives.size():
		return {}
	
	var objective: Dictionary = objectives[objective_index]
	var current_progress: int = get_objective_progress(quest_id, objective_index)
	
	return {
		"index": objective_index,
		"description": objective.get("description", ""),
		"type": objective.get("type", ObjectiveType.KILL),
		"target": objective.get("target", ""),
		"amount": objective.get("amount", 1),
		"current_progress": current_progress,
		"completed": current_progress >= objective.get("amount", 1)
	}

# 检查特定目标是否完成
func is_objective_completed(quest_id: String, objective_index: int) -> bool:
	if not _active_quests.has(quest_id):
		return false
	
	var quest_entry: Dictionary = _active_quests[quest_id]
	return quest_entry.completed_objectives.has(objective_index)

# 触发任务目标更新
func trigger_objective(target_id: String, amount: int = 1) -> void:
	for quest_id: String in _active_quests.keys():
		var quest_data: Resource = _get_quest_definition(quest_id)
		if not quest_data or quest_data.get("objectives") == null:
			continue
		
		var objectives: Array = quest_data.objectives
		
		for i: int in range(objectives.size()):
			var objective: Dictionary = objectives[i]
			
			if quest_entry_has_target(_active_quests[quest_id], i):
				continue
			
			var objective_target: String = objective.get("target", "")
			
			if objective_target == target_id:
				var objective_type: ObjectiveType = objective.get("type", ObjectiveType.KILL)
				
				match objective_type:
					ObjectiveType.KILL:
						update_quest(quest_id, i, amount)
					ObjectiveType.COLLECT:
						if _check_player_has_item(target_id, amount):
							update_quest(quest_id, i, amount)
					ObjectiveType.VISIT:
						update_quest(quest_id, i, amount)
					ObjectiveType.TALK, ObjectiveType.DELIVER, ObjectiveType.ESCORT, ObjectiveType.DEFEND:
						update_quest(quest_id, i, amount)

func quest_entry_has_target(quest_entry: Dictionary, objective_index: int) -> bool:
	return quest_entry.completed_objectives.has(objective_index)

# 添加自定义任务（程序生成任务）
func add_custom_quest(quest_data: Dictionary) -> bool:
	var quest_id: String = quest_data.get("quest_id", "")
	if quest_id.is_empty():
		push_error("QuestSystem: 自定义任务需要quest_id")
		return false
	
	if _quest_definitions.has(quest_id):
		push_warning("QuestSystem: 任务ID已存在 - " + quest_id)
		return false
	
	var quest_resource: Resource = _create_quest_resource(quest_data)
	_quest_definitions[quest_id] = quest_resource
	
	return true

# 创建任务资源
func _create_quest_resource(data: Dictionary) -> Resource:
	var quest: Resource = Resource.new()
	quest.set("quest_id", data.get("quest_id", ""))
	quest.set("title", data.get("title", "自定义任务"))
	quest.set("description", data.get("description", ""))
	quest.set("objectives", Array(data.get("objectives", [])))
	quest.set("rewards", Array(data.get("rewards", [])))
	quest.set("prerequisites", Array(data.get("prerequisites", [])))
	quest.set("repeatable", data.get("repeatable", false))
	return quest

# 移除自定义任务
func remove_custom_quest(quest_id: String) -> void:
	if _quest_definitions.has(quest_id):
		_quest_definitions.erase(quest_id)
	
	if _active_quests.has(quest_id):
		_active_quests.erase(quest_id)
	
	if _completed_quests.has(quest_id):
		_completed_quests.erase(quest_id)

# 重置任务系统
func reset_quests() -> void:
	_active_quests.clear()
	_completed_quests.clear()
	_failed_quests.clear()
	_tracked_quest_id = ""

# 保存任务数据
func save_quest_data() -> Dictionary:
	return {
		"active_quests": _active_quests.duplicate(true),
		"completed_quests": _completed_quests.duplicate(),
		"failed_quests": _failed_quests.duplicate(),
		"tracked_quest_id": _tracked_quest_id
	}

# 加载任务数据
func load_quest_data(data: Dictionary) -> void:
	if data.has("active_quests"):
		_active_quests = data.active_quests.duplicate(true)
	
	if data.has("completed_quests"):
		_completed_quests.assign(data.completed_quests)
	
	if data.has("failed_quests"):
		_failed_quests.assign(data.failed_quests)
	
	if data.has("tracked_quest_id"):
		set_tracked_quest(data.tracked_quest_id)

# 获取任务统计信息
func get_quest_statistics() -> Dictionary:
	return {
		"active_count": _active_quests.size(),
		"completed_count": _completed_quests.size(),
		"failed_count": _failed_quests.size(),
		"total_definitions": _quest_definitions.size()
	}
