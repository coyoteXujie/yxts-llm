extends Node

const ITEM_DATABASE: Dictionary = {
	"item_iron_sword": {
		"name": "铁剑",
		"description": "普通的铁制长剑，江湖新人常用",
		"type": "weapon",
		"rarity": 1,
		"value": 100,
		"stats": {"attack": 10}
	},
	"item_coarse_cloth": {
		"name": "粗布衣",
		"description": "普通的粗布衣服",
		"type": "armor",
		"rarity": 1,
		"value": 50,
		"stats": {"defense": 5}
	},
	"item_resurrection_grass": {
		"name": "还魂草",
		"description": "传说中的灵草，能起死回生",
		"type": "quest",
		"rarity": 5,
		"value": 1000
	},
	"item_yijin_jing_fragment": {
		"name": "《易筋经》残页",
		"description": "少林寺绝学《易筋经》的残页",
		"type": "quest",
		"rarity": 4,
		"value": 500
	},
	"item_city_defense_fragment": {
		"name": "城防图残片",
		"description": "城池防御图纸的碎片",
		"type": "quest",
		"rarity": 3,
		"value": 200
	},
	"item_health_potion": {
		"name": "疗伤药",
		"description": "恢复生命值的药水",
		"type": "consumable",
		"rarity": 1,
		"value": 50,
		"effects": [{"hp": 50}]
	},
	"item_mana_potion": {
		"name": "内力药水",
		"description": "恢复内力的药水",
		"type": "consumable",
		"rarity": 1,
		"value": 75,
		"effects": [{"mp": 50}]
	},
	"item_taihu_pearl": {
		"name": "太湖明珠",
		"description": "太湖特产的光润明珠",
		"type": "quest",
		"rarity": 3,
		"value": 300
	},
	"item_palace_token": {
		"name": "皇宫令牌",
		"description": "进出皇宫的通行证",
		"type": "quest",
		"rarity": 2,
		"value": 150
	},
	"item_qinling_map": {
		"name": "秦陵地图",
		"description": "秦始皇陵的详细地图",
		"type": "quest",
		"rarity": 3,
		"value": 400
	},
	"item_huashan_sword": {
		"name": "华山令牌",
		"description": "华山派的入门令牌",
		"type": "quest",
		"rarity": 2,
		"value": 200
	},
	"item_tongguan_hero": {
		"name": "潼关英雄称号",
		"description": "守卫潼关的荣誉证明",
		"type": "quest",
		"rarity": 3,
		"value": 300
	},
	"item_hot_spring_token": {
		"name": "温泉令牌",
		"description": "使用温泉的凭证",
		"type": "quest",
		"rarity": 2,
		"value": 100
	},
	"item_antique_appraisal": {
		"name": "古董鉴定书",
		"description": "证明古董真伪的鉴定书",
		"type": "quest",
		"rarity": 2,
		"value": 200
	},
	"item_fish_harvest": {
		"name": "渔获",
		"description": "丰收的渔获",
		"type": "quest",
		"rarity": 1,
		"value": 80
	},
	"item_caravan_pass": {
		"name": "马帮通行证",
		"description": "马帮商队的通行证",
		"type": "quest",
		"rarity": 2,
		"value": 150
	},
	"item_wudang_sword_book": {
		"name": "武当剑法入门",
		"description": "武当派剑法入门秘籍",
		"type": "quest",
		"rarity": 3,
		"value": 500
	},
	"item_shennong_herbal": {
		"name": "神农本草",
		"description": "神农氏留下的医药典籍",
		"type": "quest",
		"rarity": 4,
		"value": 800
	},
	"item_yunmeng_token": {
		"name": "云梦令牌",
		"description": "云梦泽的通行令牌",
		"type": "quest",
		"rarity": 2,
		"value": 200
	},
	"item_dujiang_map": {
		"name": "都江堰图志",
		"description": "都江堰水利工程的详细记录",
		"type": "quest",
		"rarity": 3,
		"value": 400
	},
	"item_dragon_blessing": {
		"name": "龙王护符",
		"description": "长江龙王的祝福护符",
		"type": "quest",
		"rarity": 4,
		"value": 600
	},
	"item_shaolin_token": {
		"name": "少林令牌",
		"description": "少林寺的入门令牌",
		"type": "quest",
		"rarity": 3,
		"value": 400
	},
	"item_bagua_formation": {
		"name": "八卦阵图",
		"description": "八卦门的阵法秘籍",
		"type": "quest",
		"rarity": 4,
		"value": 600
	},
	"item_flower_secret": {
		"name": "花间秘辛",
		"description": "花间派的核心秘籍",
		"type": "quest",
		"rarity": 4,
		"value": 700
	},
	"item_taiji_manual": {
		"name": "太极功法",
		"description": "太极门的核心功法",
		"type": "quest",
		"rarity": 4,
		"value": 800
	},
	"item_xueshan_ice": {
		"name": "冰魄",
		"description": "雪山派的修炼材料",
		"type": "quest",
		"rarity": 4,
		"value": 700
	},
	"item_xiaoyao_treasure": {
		"name": "逍遥三宝",
		"description": "逍遥宫的至宝",
		"type": "quest",
		"rarity": 5,
		"value": 1000
	},
	"item_emei_incense": {
		"name": "峨眉香火",
		"description": "峨眉寺的香火",
		"type": "quest",
		"rarity": 2,
		"value": 150
	},
	"gold": {
		"name": "银两",
		"description": "通用的货币",
		"type": "currency",
		"rarity": 1,
		"value": 1
	}
}

func get_item_info(item_id: String) -> Dictionary:
	return ITEM_DATABASE.get(item_id, {
		"name": item_id,
		"description": "未知物品",
		"type": "misc",
		"rarity": 1,
		"value": 10
	})

func item_exists(item_id: String) -> bool:
	return ITEM_DATABASE.has(item_id)

func get_item_name(item_id: String) -> String:
	var info = get_item_info(item_id)
	return info.get("name", item_id)

func get_item_value(item_id: String) -> int:
	var info = get_item_info(item_id)
	return info.get("value", 10)

func get_item_rarity_name(rarity: int) -> String:
	match rarity:
		1: return "普通"
		2: return "优秀"
		3: return "稀有"
		4: return "史诗"
		5: return "传说"
		_: return "未知"
