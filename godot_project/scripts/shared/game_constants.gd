extends RefCounted
class_name GameConstants

## Faction identity maps
const FACTION_NAMES := {
	"none": "无门无派",
	"bagua": "八卦门",
	"flower": "花间派",
	"honglian": "红莲教",
	"naja": "那迦派",
	"taiji": "太极门",
	"xueshan": "雪山派",
	"xiaoyao": "逍遥派",
	"court": "朝廷",
	"beggar": "丐帮",
	"bandit": "山贼"
}

const FACTION_ALIASES := {
	"": "none",
	"无门无派": "none",
	"无": "none",
	"八卦门": "bagua",
	"花间派": "flower",
	"红莲教": "honglian",
	"那迦派": "naja",
	"太极门": "taiji",
	"雪山派": "xueshan",
	"逍遥派": "xiaoyao",
	"官府": "court",
	"朝廷": "court",
	"丐帮": "beggar",
	"山贼": "bandit"
}

const FACTION_ALIGNMENT := {
	"none": "neutral",
	"bagua": "good",
	"flower": "good",
	"honglian": "evil",
	"naja": "evil",
	"taiji": "good",
	"xueshan": "good",
	"xiaoyao": "neutral",
	"court": "good",
	"beggar": "good",
	"bandit": "evil"
}

const FACTION_COLORS := {
	"none": Color(0.75, 0.65, 0.50),
	"bagua": Color(0.55, 0.52, 0.45),
	"flower": Color(0.86, 0.48, 0.58),
	"honglian": Color(0.82, 0.22, 0.18),
	"naja": Color(0.25, 0.39, 0.29),
	"taiji": Color(0.82, 0.82, 0.78),
	"xueshan": Color(0.62, 0.76, 0.92),
	"xiaoyao": Color(0.50, 0.67, 0.55),
	"court": Color(0.34, 0.48, 0.62),
	"beggar": Color(0.62, 0.48, 0.30),
	"bandit": Color(0.62, 0.28, 0.22)
}

## Skill identity maps
const SKILL_NAMES := {
	"kf_basic_bare": "基本拳脚",
	"kf_basic_sword": "基本剑法",
	"kf_basic_blade": "基本刀法",
	"kf_basic_club": "基本棍法",
	"kf_basic_dodge": "基本轻功",
	"kf_basic_force": "基本内功",
	"kf_basic_parry": "基本招架",
	"kf_literate": "读书识字",
	"kf_bagua_blade": "八卦刀",
	"kf_bagua_palm": "八卦掌",
	"kf_bazhen": "八阵图",
	"kf_hunyuan": "混元一气",
	"kf_youlong": "游龙步法",
	"kf_huafei": "花飞剑法",
	"kf_huatuan": "花团锦簇",
	"kf_liu": "流水剑法",
	"kf_meihua": "梅花步法",
	"kf_sanhua": "三花聚顶",
	"kf_taiji_sword": "太极剑法",
	"kf_taiji_fist": "太极拳",
	"kf_taiji_force": "太极功",
	"kf_wanliu": "万柳身法",
	"kf_xuanxu": "玄虚刀法",
	"kf_taxue": "踏雪无痕",
	"kf_xueshang": "雪上霜",
	"kf_xueshan_sword": "雪山剑法",
	"kf_xueying": "雪影爪",
	"kf_hexiang": "鹤翔术",
	"kf_jiaoyi": "嫁衣神功",
	"kf_pifeng": "披风刀法",
	"kf_taizu": "太祖长拳",
	"kf_tongji": "同击术",
	"kf_renshu": "忍术",
	"kf_wufa": "雾法",
	"kf_wuying": "无影步",
	"kf_yidao": "一刀流",
	"kf_xiaoyao_you": "逍遥游",
	"kf_beiming": "北冥神功",
	"kf_liuyang": "天山六阳掌",
	"kf_xiaowuxiang": "小无相功",
	"kf_lingbo": "凌波微步",
	"kf_qinna": "六合擒拿",
	"kf_tiebu": "铁布衫",
	"kf_shenxing": "神行百变",
	"kf_anjian": "暗器手法"
}

## Rarity maps
const RARITY_ORDER := ["common", "uncommon", "rare", "epic", "legendary"]

const RARITY_NAMES := {
	"common": "凡品",
	"uncommon": "良品",
	"rare": "精品",
	"epic": "极品",
	"legendary": "传说"
}

const RARITY_COLORS := {
	"common": Color(0.78, 0.78, 0.78, 1.0),
	"uncommon": Color(0.40, 0.78, 0.42, 1.0),
	"rare": Color(0.36, 0.62, 0.96, 1.0),
	"epic": Color(0.68, 0.42, 0.96, 1.0),
	"legendary": Color(0.96, 0.72, 0.28, 1.0)
}

const RARITY_SELL_FACTORS := {
	"common": 0.42,
	"uncommon": 0.48,
	"rare": 0.58,
	"epic": 0.68,
	"legendary": 0.80
}

const RARITY_DROP_WEIGHTS := {
	"common": 100.0,
	"uncommon": 45.0,
	"rare": 16.0,
	"epic": 4.0,
	"legendary": 0.8
}