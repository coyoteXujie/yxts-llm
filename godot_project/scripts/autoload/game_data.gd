extends Node

const TILE_SIZE := 48
const MAP_WIDTH := 96
const MAP_HEIGHT := 72

const FACTION_NAMES := {
	"none": "无门无派",
	"bagua": "八卦门",
	"flower": "花间派",
	"honglian": "红莲教",
	"naja": "那迦派",
	"taiji": "太极门",
	"xueshan": "雪山派",
	"xiaoyao": "逍遥派"
}

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
	"kf_lingbo": "凌波微步"
}

const FACTION_SKILLS := {
	"bagua": ["kf_bagua_blade", "kf_bagua_palm", "kf_bazhen", "kf_hunyuan", "kf_youlong"],
	"flower": ["kf_huafei", "kf_huatuan", "kf_liu", "kf_meihua", "kf_sanhua"],
	"honglian": ["kf_hexiang", "kf_jiaoyi", "kf_pifeng", "kf_taizu", "kf_tongji"],
	"naja": ["kf_renshu", "kf_wufa", "kf_wuying", "kf_yidao"],
	"taiji": ["kf_taiji_sword", "kf_taiji_fist", "kf_taiji_force", "kf_wanliu", "kf_xuanxu"],
	"xueshan": ["kf_taxue", "kf_xueshang", "kf_xueshan_sword", "kf_xueying"],
	"xiaoyao": ["kf_xiaoyao_you", "kf_beiming", "kf_liuyang", "kf_xiaowuxiang", "kf_lingbo"]
}

const ATTACK_SKILLS := {
	"kf_basic_bare": true,
	"kf_basic_sword": true,
	"kf_basic_blade": true,
	"kf_basic_club": true,
	"kf_bagua_blade": true,
	"kf_bagua_palm": true,
	"kf_bazhen": true,
	"kf_huafei": true,
	"kf_huatuan": true,
	"kf_liu": true,
	"kf_taiji_sword": true,
	"kf_taiji_fist": true,
	"kf_xuanxu": true,
	"kf_xueshang": true,
	"kf_xueshan_sword": true,
	"kf_xueying": true,
	"kf_pifeng": true,
	"kf_taizu": true,
	"kf_tongji": true,
	"kf_renshu": true,
	"kf_wufa": true,
	"kf_yidao": true,
	"kf_liuyang": true
}

const DIALOGUES := {
	"平阿四": ["客官住店还是打尖？平安镇消息，十有八九先到我这里。", "北边八卦门近日开山收徒，想拜师可以去看看。"],
	"阿青": ["豆腐刚出锅，白嫩得很。", "剑法不必争强，一口气顺了，招式自然顺。"],
	"老夫子": ["读书识字，是行走江湖的根。", "心浮则字乱，字乱则剑乱。"],
	"捕快": ["平安镇近来不太平，镇东常有流氓滋事。", "若要行侠，也要量力而为。"],
	"村长": ["少侠初到平安镇，先熟悉街市，再谈江湖。", "镇上的人各有难处，多问问总有线索。"],
	"道德和尚": ["善恶一念，拳脚无眼。", "你若心存侠义，贫僧可指点基本内功。"],
	"铁匠": ["刀剑要合手，太轻无力，太重碍身。", "出镇之前，最好备一件趁手兵刃。"],
	"大侠": ["江湖不是擂台，能救人才算本事。", "你若能平定镇东，再来找我试招。"],
		"苏梦瑶": ["我在洛阳等一个愿意听真相的人。", "苏家旧宅的大火不是意外，若你愿查，先去长安找陈天行。", "母亲留下的玉佩背面有半枚花纹，我怀疑它不是家徽，而是暗号。"],
		"陈天行": ["说书只是遮眼法，真正的故事藏在卷宗后面。", "苏家的火、暗影司的线、武林盟的沉默，这三件事不是巧合。", "如果有人盯上你，不要回头，先看路边茶盏有没有换过位置。"],
		"赵无极": ["洛阳城讲规矩，江湖人也不能例外。", "旧案若没有证据，贸然翻出来只会害人。", "武林盟不是铁板一块，有些卷宗我能给你看，有些只能等夜里。"],
		"玄机子": ["天机不可泄露，但阵眼可以指给有缘人。", "七派各守一角，若暗影司真动了手，先看谁的门规被破。", "密信上那一笔不像八卦门弟子写的，倒像有人故意学错。"],
		"花如玉": ["花会谢，人会变，只有旧疤不会自己消失。", "苏家的事，我知道一半，另一半在暗影司手里。", "你若闻到甜香，先闭气，再想谁想让你开口。"],
		"烈火": ["这世道若腐烂到根，便该烧出一条新路。", "别拿朝廷规矩压我，红莲教只认血债。", "暗影司若敢把手伸进红莲坛，我会让他们连影子都留不下。"],
		"蛇王": ["明处的刀最容易躲，暗处的眼最难防。", "你若追查暗影司，先学会分辨谁在看你。", "长安来的黑衣人换了三次靴底，说明他走的是水路，不是官道。"],
		"太极真人": ["事有阴阳，局有虚实。", "年轻人，查案也如推手，急进则露破绽。", "七派若要夜议，先要有人把最危险的那封信带上山。"],
		"冰魄": ["雪山不问俗世，但江湖寒意已经吹到山门。", "若你心不定，雪岭会先试你的胆。", "雪地不会说谎，脚印会告诉你来人是逃命，还是追杀。"],
		"逍遥子": ["人生得意须尽欢，可惜江湖总有人不让人尽欢。", "你若看不清局，不妨先离局远一点。", "暗线最怕旁观者，我站远些，反而看见他们藏得很近。"],
	"韦扬": ["八卦门重根基，刀掌步法缺一不可。", "入门先练游龙步，再谈八阵变化。"],
	"清照": ["花间武学讲究身法与气韵。", "心有杂念，花飞便失了灵动。"],
	"清虚道人": ["太极无胜负，只有虚实。", "来者若能守静，贫道自会指点。"],
	"白瑞德": ["雪山路寒，心不定者走不到山门。", "刀剑之外，最难修的是耐性。"],
	"流氓": ["看什么看？镇东这条路归我们管。"],
	"流氓头": ["敢管闲事，就留下买路钱。"],
	"采花大盗": ["你追不上我的轻功。"],
	"神秘人": ["你已经走到这里，就让我看看你的江湖分量。"]
}

const APPEARANCE_PRESETS := {
	"default": {
		"archetype": "townsperson",
		"build": "standard",
		"head": "oval",
		"hair": "topknot",
		"hat": "none",
		"outfit": "short_robe",
		"prop": "none",
		"motif": "none",
		"skin": [0.84, 0.68, 0.52],
		"primary": [0.54, 0.46, 0.34],
		"secondary": [0.24, 0.20, 0.16],
		"accent": [0.78, 0.62, 0.32]
	},
	"innkeeper": {
		"archetype": "innkeeper",
		"build": "round",
		"head": "round",
		"hair": "sideburns",
		"hat": "merchant_cap",
		"outfit": "merchant_robe",
		"prop": "abacus",
		"motif": "coin",
		"primary": [0.62, 0.36, 0.20],
		"secondary": [0.84, 0.68, 0.36],
		"accent": [0.96, 0.78, 0.34]
	},
	"waiter": {
		"archetype": "waiter",
		"build": "slim",
		"head": "round",
		"hair": "short",
		"hat": "cloth_cap",
		"outfit": "work_apron",
		"prop": "towel",
		"motif": "none",
		"primary": [0.44, 0.38, 0.28],
		"secondary": [0.86, 0.80, 0.64],
		"accent": [0.76, 0.58, 0.30]
	},
	"tofu_seller": {
		"archetype": "tofu_seller",
		"build": "graceful",
		"head": "soft",
		"hair": "long_tail",
		"hat": "none",
		"outfit": "plain_hanfu",
		"prop": "basket",
		"motif": "water",
		"primary": [0.78, 0.82, 0.72],
		"secondary": [0.45, 0.64, 0.58],
		"accent": [0.92, 0.88, 0.70]
	},
	"scholar": {
		"archetype": "scholar",
		"build": "thin",
		"head": "long",
		"hair": "beard",
		"hat": "scholar_hat",
		"outfit": "scholar_robe",
		"prop": "scroll",
		"motif": "book",
		"primary": [0.40, 0.48, 0.50],
		"secondary": [0.82, 0.78, 0.64],
		"accent": [0.62, 0.50, 0.28]
	},
	"constable": {
		"archetype": "constable",
		"build": "strong",
		"head": "square",
		"hair": "short",
		"hat": "constable_hat",
		"outfit": "official_uniform",
		"prop": "dao",
		"motif": "badge",
		"primary": [0.18, 0.28, 0.38],
		"secondary": [0.12, 0.12, 0.14],
		"accent": [0.78, 0.32, 0.22]
	},
	"elder": {
		"archetype": "elder",
		"build": "aged",
		"head": "aged",
		"hair": "white_beard",
		"hat": "soft_cap",
		"outfit": "elder_robe",
		"prop": "staff",
		"motif": "none",
		"primary": [0.45, 0.42, 0.30],
		"secondary": [0.70, 0.64, 0.48],
		"accent": [0.58, 0.48, 0.28]
	},
	"monk": {
		"archetype": "monk",
		"build": "solid",
		"head": "round",
		"hair": "bald",
		"hat": "monk_dots",
		"outfit": "monk_robe",
		"prop": "beads",
		"motif": "lotus",
		"primary": [0.72, 0.42, 0.20],
		"secondary": [0.52, 0.24, 0.12],
		"accent": [0.86, 0.70, 0.38]
	},
	"blacksmith": {
		"archetype": "blacksmith",
		"build": "broad",
		"head": "square",
		"hair": "headband",
		"hat": "headband",
		"outfit": "smith_apron",
		"prop": "hammer",
		"motif": "spark",
		"primary": [0.36, 0.28, 0.22],
		"secondary": [0.18, 0.16, 0.15],
		"accent": [0.84, 0.42, 0.18]
	},
	"wandering_hero": {
		"archetype": "wandering_hero",
		"build": "heroic",
		"head": "sharp",
		"hair": "high_topknot",
		"hat": "none",
		"outfit": "hero_robe",
		"prop": "sword",
		"motif": "wind",
		"primary": [0.28, 0.34, 0.42],
		"secondary": [0.12, 0.14, 0.18],
		"accent": [0.86, 0.72, 0.42]
	},
	"bagua_master": {
		"archetype": "bagua_master",
		"build": "master",
		"head": "square",
		"hair": "beard",
		"hat": "sect_crown",
		"outfit": "sect_robe",
		"prop": "blade",
		"motif": "bagua",
		"primary": [0.44, 0.43, 0.38],
		"secondary": [0.18, 0.17, 0.16],
		"accent": [0.82, 0.68, 0.38]
	},
	"flower_master": {
		"archetype": "flower_master",
		"build": "graceful",
		"head": "soft",
		"hair": "long_tail",
		"hat": "flower_pin",
		"outfit": "flowing_hanfu",
		"prop": "fan",
		"motif": "flower",
		"primary": [0.76, 0.40, 0.52],
		"secondary": [0.92, 0.72, 0.78],
		"accent": [0.98, 0.82, 0.48]
	},
	"taiji_master": {
		"archetype": "taiji_master",
		"build": "thin",
		"head": "long",
		"hair": "white_beard",
		"hat": "daoist_crown",
		"outfit": "daoist_robe",
		"prop": "whisk",
		"motif": "taiji",
		"primary": [0.78, 0.78, 0.72],
		"secondary": [0.20, 0.20, 0.20],
		"accent": [0.62, 0.68, 0.74]
	},
	"xueshan_master": {
		"archetype": "xueshan_master",
		"build": "strong",
		"head": "sharp",
		"hair": "hood",
		"hat": "snow_hood",
		"outfit": "fur_robe",
		"prop": "sword",
		"motif": "snow",
		"primary": [0.72, 0.82, 0.90],
		"secondary": [0.36, 0.46, 0.60],
		"accent": [0.94, 0.96, 0.98]
	},
	"town_trader": {
		"archetype": "town_trader",
		"build": "round",
		"head": "round",
		"hair": "sideburns",
		"hat": "merchant_cap",
		"outfit": "merchant_robe",
		"prop": "abacus",
		"motif": "coin",
		"primary": [0.48, 0.34, 0.24],
		"secondary": [0.68, 0.55, 0.34],
		"accent": [0.90, 0.70, 0.32]
	},
	"cook": {
		"archetype": "cook",
		"build": "strong",
		"head": "round",
		"hair": "short",
		"hat": "cloth_cap",
		"outfit": "work_apron",
		"prop": "club",
		"motif": "none",
		"primary": [0.54, 0.36, 0.24],
		"secondary": [0.88, 0.82, 0.64],
		"accent": [0.72, 0.44, 0.20]
	},
	"butcher": {
		"archetype": "butcher",
		"build": "broad",
		"head": "square",
		"hair": "headband",
		"hat": "headband",
		"outfit": "leather",
		"prop": "dao",
		"motif": "scar",
		"primary": [0.42, 0.22, 0.16],
		"secondary": [0.18, 0.14, 0.12],
		"accent": [0.82, 0.32, 0.20]
	},
	"flower_seller": {
		"archetype": "flower_seller",
		"build": "graceful",
		"head": "soft",
		"hair": "long_tail",
		"hat": "flower_pin",
		"outfit": "plain_hanfu",
		"prop": "basket",
		"motif": "flower",
		"primary": [0.72, 0.62, 0.70],
		"secondary": [0.45, 0.56, 0.48],
		"accent": [0.94, 0.68, 0.76]
	},
	"doctor": {
		"archetype": "doctor",
		"build": "thin",
		"head": "long",
		"hair": "beard",
		"hat": "scholar_hat",
		"outfit": "scholar_robe",
		"prop": "scroll",
		"motif": "lotus",
		"primary": [0.50, 0.58, 0.50],
		"secondary": [0.84, 0.80, 0.62],
		"accent": [0.58, 0.68, 0.42]
	},
	"poison_master": {
		"archetype": "poison_master",
		"build": "slim",
		"head": "sharp",
		"hair": "long_tail",
		"hat": "face_mask",
		"outfit": "night_suit",
		"prop": "dagger",
		"motif": "shadow",
		"primary": [0.10, 0.16, 0.12],
		"secondary": [0.18, 0.36, 0.22],
		"accent": [0.58, 0.82, 0.34]
	},
	"tailor": {
		"archetype": "tailor",
		"build": "slim",
		"head": "oval",
		"hair": "short",
		"hat": "soft_cap",
		"outfit": "work_apron",
		"prop": "scroll",
		"motif": "none",
		"primary": [0.50, 0.44, 0.58],
		"secondary": [0.76, 0.70, 0.62],
		"accent": [0.70, 0.58, 0.34]
	},
	"town_guard": {
		"archetype": "town_guard",
		"build": "strong",
		"head": "square",
		"hair": "short",
		"hat": "constable_hat",
		"outfit": "official_uniform",
		"prop": "dao",
		"motif": "badge",
		"primary": [0.16, 0.25, 0.33],
		"secondary": [0.10, 0.11, 0.13],
		"accent": [0.76, 0.30, 0.20]
	},
	"town_elder": {
		"archetype": "town_elder",
		"build": "aged",
		"head": "aged",
		"hair": "white_beard",
		"hat": "soft_cap",
		"outfit": "elder_robe",
		"prop": "staff",
		"motif": "none",
		"primary": [0.48, 0.43, 0.34],
		"secondary": [0.70, 0.62, 0.46],
		"accent": [0.60, 0.48, 0.28]
	},
	"noble": {
		"archetype": "noble",
		"build": "thin",
		"head": "long",
		"hair": "topknot",
		"hat": "scholar_hat",
		"outfit": "scholar_robe",
		"prop": "fan",
		"motif": "coin",
		"primary": [0.56, 0.46, 0.62],
		"secondary": [0.30, 0.26, 0.36],
		"accent": [0.88, 0.70, 0.34]
	},
	"child": {
		"archetype": "child",
		"build": "slim",
		"head": "round",
		"hair": "short",
		"hat": "cloth_cap",
		"outfit": "plain_hanfu",
		"prop": "none",
		"motif": "none",
		"primary": [0.58, 0.64, 0.52],
		"secondary": [0.32, 0.40, 0.32],
		"accent": [0.92, 0.68, 0.34]
	},
	"wanderer": {
		"archetype": "wanderer",
		"build": "standard",
		"head": "oval",
		"hair": "topknot",
		"hat": "none",
		"outfit": "plain_hanfu",
		"prop": "staff",
		"motif": "wind",
		"primary": [0.42, 0.46, 0.40],
		"secondary": [0.24, 0.26, 0.24],
		"accent": [0.72, 0.62, 0.38]
	},
	"swordsman_poet": {
		"archetype": "swordsman_poet",
		"build": "heroic",
		"head": "sharp",
		"hair": "high_topknot",
		"hat": "none",
		"outfit": "hero_robe",
		"prop": "sword",
		"motif": "wind",
		"primary": [0.42, 0.48, 0.62],
		"secondary": [0.12, 0.14, 0.18],
		"accent": [0.90, 0.78, 0.48]
	},
	"bagua_disciple": {
		"archetype": "bagua_disciple",
		"build": "strong",
		"head": "square",
		"hair": "topknot",
		"hat": "sect_crown",
		"outfit": "sect_robe",
		"prop": "blade",
		"motif": "bagua",
		"primary": [0.38, 0.37, 0.34],
		"secondary": [0.16, 0.15, 0.14],
		"accent": [0.76, 0.62, 0.34]
	},
	"flower_disciple": {
		"archetype": "flower_disciple",
		"build": "graceful",
		"head": "soft",
		"hair": "long_tail",
		"hat": "flower_pin",
		"outfit": "flowing_hanfu",
		"prop": "fan",
		"motif": "flower",
		"primary": [0.68, 0.42, 0.56],
		"secondary": [0.86, 0.66, 0.74],
		"accent": [0.96, 0.78, 0.46]
	},
	"honglian_master": {
		"archetype": "honglian_master",
		"build": "master",
		"head": "square",
		"hair": "high_topknot",
		"hat": "dark_crown",
		"outfit": "sect_robe",
		"prop": "great_blade",
		"motif": "lotus",
		"primary": [0.56, 0.08, 0.08],
		"secondary": [0.16, 0.08, 0.06],
		"accent": [0.96, 0.58, 0.24]
	},
	"honglian_disciple": {
		"archetype": "honglian_disciple",
		"build": "strong",
		"head": "rough",
		"hair": "headband",
		"hat": "headband",
		"outfit": "sect_robe",
		"prop": "club",
		"motif": "lotus",
		"primary": [0.52, 0.12, 0.10],
		"secondary": [0.22, 0.10, 0.08],
		"accent": [0.90, 0.50, 0.22]
	},
	"naja_master": {
		"archetype": "naja_master",
		"build": "slim",
		"head": "sharp",
		"hair": "masked",
		"hat": "face_mask",
		"outfit": "night_suit",
		"prop": "dagger",
		"motif": "shadow",
		"primary": [0.08, 0.10, 0.10],
		"secondary": [0.12, 0.26, 0.18],
		"accent": [0.50, 0.78, 0.42]
	},
	"naja_disciple": {
		"archetype": "naja_disciple",
		"build": "slim",
		"head": "sharp",
		"hair": "masked",
		"hat": "face_mask",
		"outfit": "night_suit",
		"prop": "dagger",
		"motif": "shadow",
		"primary": [0.10, 0.12, 0.12],
		"secondary": [0.16, 0.30, 0.20],
		"accent": [0.48, 0.68, 0.36]
	},
	"taiji_disciple": {
		"archetype": "taiji_disciple",
		"build": "thin",
		"head": "long",
		"hair": "topknot",
		"hat": "daoist_crown",
		"outfit": "daoist_robe",
		"prop": "whisk",
		"motif": "taiji",
		"primary": [0.70, 0.70, 0.66],
		"secondary": [0.18, 0.18, 0.18],
		"accent": [0.58, 0.64, 0.70]
	},
	"xueshan_disciple": {
		"archetype": "xueshan_disciple",
		"build": "strong",
		"head": "sharp",
		"hair": "hood",
		"hat": "snow_hood",
		"outfit": "fur_robe",
		"prop": "sword",
		"motif": "snow",
		"primary": [0.64, 0.76, 0.86],
		"secondary": [0.32, 0.44, 0.58],
		"accent": [0.92, 0.96, 1.0]
	},
	"thug": {
		"archetype": "thug",
		"build": "rough",
		"head": "square",
		"hair": "messy",
		"hat": "none",
		"outfit": "ragged",
		"prop": "club",
		"motif": "scar",
		"primary": [0.44, 0.18, 0.14],
		"secondary": [0.16, 0.12, 0.10],
		"accent": [0.72, 0.30, 0.18]
	},
	"bandit": {
		"archetype": "bandit",
		"build": "broad",
		"head": "rough",
		"hair": "messy",
		"hat": "bandit_wrap",
		"outfit": "leather",
		"prop": "dao",
		"motif": "scar",
		"primary": [0.36, 0.16, 0.12],
		"secondary": [0.12, 0.10, 0.08],
		"accent": [0.78, 0.26, 0.16]
	},
	"assassin": {
		"archetype": "assassin",
		"build": "slim",
		"head": "sharp",
		"hair": "masked",
		"hat": "face_mask",
		"outfit": "night_suit",
		"prop": "dagger",
		"motif": "shadow",
		"primary": [0.08, 0.08, 0.10],
		"secondary": [0.38, 0.08, 0.10],
		"accent": [0.82, 0.28, 0.22]
	},
	"boss": {
		"archetype": "boss",
		"build": "boss",
		"head": "sharp",
		"hair": "wild",
		"hat": "dark_crown",
		"outfit": "dark_armor",
		"prop": "great_blade",
		"motif": "dragon",
		"primary": [0.12, 0.10, 0.12],
		"secondary": [0.48, 0.08, 0.08],
		"accent": [0.95, 0.62, 0.24]
	}
}

var npcs: Array = []
var items: Dictionary = {}
var quests: Dictionary = {}
var npc_sprite_assets: Dictionary = {}
var npc_portrait_assets: Dictionary = {}
var item_icon_assets: Dictionary = {}
var skill_icon_assets: Dictionary = {}
var scene_background_assets: Dictionary = {}
var texture_cache: Dictionary = {}
var regions: Dictionary = {}
var region_order: Array[String] = []

func _ready() -> void:
	load_database()

func load_database() -> void:
	var npc_file := FileAccess.open("res://data/npcs.json", FileAccess.READ)
	if npc_file == null:
		npcs = _fallback_npcs()
	else:
		var parsed = JSON.parse_string(npc_file.get_as_text())
		if typeof(parsed) == TYPE_ARRAY:
			npcs = parsed
		else:
			npcs = _fallback_npcs()
	_load_items()
	_load_quests()
	_load_npc_sprite_assets()
	_load_npc_portrait_assets()
	_load_item_icon_assets()
	_load_skill_icon_assets()
	_load_scene_background_assets()
	_load_regions()

func _load_items() -> void:
	items.clear()
	var file := FileAccess.open("res://data/items.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			items[str(item.get("id", ""))] = item

func _load_quests() -> void:
	quests.clear()
	var file := FileAccess.open("res://data/quests.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		for quest in parsed:
			quests[str(quest.get("id", ""))] = quest

func _load_npc_sprite_assets() -> void:
	npc_sprite_assets.clear()
	var file := FileAccess.open("res://data/npc_sprite_assets.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for npc_name in parsed.keys():
		npc_sprite_assets[str(npc_name)] = str(parsed[npc_name])

func _load_npc_portrait_assets() -> void:
	npc_portrait_assets.clear()
	_load_asset_mapping("res://data/npc_portrait_assets.json", npc_portrait_assets)

func _load_item_icon_assets() -> void:
	item_icon_assets.clear()
	_load_asset_mapping("res://data/item_icon_assets.json", item_icon_assets)

func _load_skill_icon_assets() -> void:
	skill_icon_assets.clear()
	_load_asset_mapping("res://data/skill_icon_assets.json", skill_icon_assets)

func _load_scene_background_assets() -> void:
	scene_background_assets.clear()
	_load_asset_mapping("res://data/scene_background_assets.json", scene_background_assets)

func _load_asset_mapping(path: String, target: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for key in parsed.keys():
		target[str(key)] = str(parsed[key])

func _load_regions() -> void:
	regions.clear()
	region_order.clear()
	var file := FileAccess.open("res://data/regions.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return
	for region in parsed:
		if typeof(region) != TYPE_DICTIONARY:
			continue
		var region_id := str(region.get("id", ""))
		if region_id.is_empty():
			continue
		regions[region_id] = region
		region_order.append(region_id)

func get_npcs() -> Array:
	return npcs

func build_region_encounter_enemy(region: Dictionary) -> Dictionary:
	var region_id := str(region.get("id", "wild"))
	var danger := int(region.get("danger", 1))
	var terrain := str(region.get("terrain", ""))
	var candidates: Array[String] = []
	if terrain.contains("snow") or terrain.contains("mountain") or terrain.contains("cliff") or terrain.contains("gorge") or terrain.contains("plateau"):
		candidates = ["土匪甲", "雪豹"] if danger <= 3 else ["土匪头目", "独角大盗"]
	elif terrain.contains("forest") or terrain.contains("bamboo") or terrain.contains("marsh"):
		candidates = ["流氓头", "采花大盗"] if danger <= 3 else ["黑衣大盗", "独角大盗"]
	elif terrain.contains("river") or terrain.contains("lake") or terrain.contains("water") or terrain.contains("ford") or terrain.contains("canal"):
		candidates = ["流氓", "流氓头"] if danger <= 2 else ["采花大盗", "黑衣大盗"]
	elif danger >= 4:
		candidates = ["独角大盗", "黑衣大盗"]
	elif danger >= 3:
		candidates = ["流氓头", "采花大盗"]
	else:
		candidates = ["流氓"]
	var index: int = int(abs(hash(region_id)) % maxi(1, candidates.size()))
	var enemy: Dictionary = get_npc_by_name(candidates[index]).duplicate(true)
	if enemy.is_empty():
		enemy = get_npc_by_name("流氓").duplicate(true)
	if enemy.is_empty():
		return {}
	enemy["encounter"] = true
	enemy["source_region"] = region_id
	enemy["id"] = -100000 - abs(hash(region_id)) % 900000
	return enemy

func get_regions() -> Array:
	var result: Array = []
	for region_id in region_order:
		result.append(regions[region_id])
	return result

func get_region(region_id: String) -> Dictionary:
	return regions.get(region_id, {})

func get_neighbor_regions(region_id: String, max_count: int = 4) -> Array:
	var source: Dictionary = get_region(region_id)
	if source.is_empty():
		return []
	var scored: Array = []
	for candidate in get_regions():
		if typeof(candidate) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = candidate
		if str(target.get("id", "")) == region_id:
			continue
		var score: float = _region_link_score(source, target)
		if score >= 999999.0:
			continue
		scored.append({
			"region": target,
			"score": score
		})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) < float(b.get("score", 0.0))
	)
	var result: Array = []
	for entry in scored:
		result.append(entry.get("region", {}))
		if result.size() >= max_count:
			break
	return result

func get_region_at_tile(tile: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	var best_priority := -1
	var best_area := 999999
	for region_id in region_order:
		var region: Dictionary = regions[region_id]
		if not _region_contains_tile(region, tile):
			continue
		var priority := _region_priority(str(region.get("type", "wild")))
		var area := _region_area(region)
		if priority > best_priority or (priority == best_priority and area < best_area):
			best = region
			best_priority = priority
			best_area = area
	return best

func _region_contains_tile(region: Dictionary, tile: Vector2i) -> bool:
	var rect_data: Array = region.get("rect", [])
	if rect_data.size() < 4:
		return false
	var x := int(rect_data[0])
	var y := int(rect_data[1])
	var width := int(rect_data[2])
	var height := int(rect_data[3])
	return tile.x >= x and tile.y >= y and tile.x < x + width and tile.y < y + height

func _region_area(region: Dictionary) -> int:
	var rect_data: Array = region.get("rect", [])
	if rect_data.size() < 4:
		return 999999
	return max(1, int(rect_data[2]) * int(rect_data[3]))

func _region_link_score(source: Dictionary, target: Dictionary) -> float:
	var source_id := str(source.get("id", ""))
	var target_id := str(target.get("id", ""))
	var source_parent := str(source.get("parent", ""))
	var target_parent := str(target.get("parent", ""))
	var source_type := str(source.get("type", "wild"))
	var target_type := str(target.get("type", "wild"))
	var same_cluster := source_parent == target_parent and not source_parent.is_empty()
	var parent_link := source_parent == target_id or target_parent == source_id
	var city_spine := source_type == "city" and target_type == "city"
	if not same_cluster and not parent_link and not city_spine:
		return 999999.0
	var distance := _region_center(source).distance_to(_region_center(target))
	var type_weight := 0.0
	match target_type:
		"city":
			type_weight = 0.0
		"town":
			type_weight = 2.0
		"sect":
			type_weight = 3.5
		_:
			type_weight = 5.0
	if parent_link:
		type_weight -= 6.0
	if city_spine:
		type_weight += 24.0
	return maxf(0.0, distance + type_weight)

func _region_center(region: Dictionary) -> Vector2:
	var center_data: Array = region.get("center", [])
	if center_data.size() >= 2:
		return Vector2(float(center_data[0]), float(center_data[1]))
	var rect_data: Array = region.get("rect", [])
	if rect_data.size() >= 4:
		return Vector2(float(rect_data[0]) + float(rect_data[2]) * 0.5, float(rect_data[1]) + float(rect_data[3]) * 0.5)
	return Vector2.ZERO

func _region_priority(region_type: String) -> int:
	match region_type:
		"sect":
			return 50
		"city":
			return 45
		"town":
			return 40
		_:
			return 10

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_all_items() -> Dictionary:
	return items

func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

func get_available_quests() -> Array:
	var found: Array = []
	for quest_id in quests.keys():
		found.append(quests[quest_id])
	return found

func get_quests_for_npc(npc_name: String) -> Array:
	var found: Array = []
	for quest_id in quests.keys():
		var quest: Dictionary = quests[quest_id]
		if str(quest.get("giver", "")) == npc_name:
			found.append(quest)
	return found

func get_npc_sprite_path(npc_name: String) -> String:
	return str(npc_sprite_assets.get(npc_name, ""))

func get_npc_portrait_path(npc_name: String) -> String:
	return str(npc_portrait_assets.get(npc_name, ""))

func get_item_icon_path(item_id: String) -> String:
	return str(item_icon_assets.get(item_id, ""))

func get_skill_icon_path(skill_id: String) -> String:
	return str(skill_icon_assets.get(skill_id, ""))

func get_scene_background_path(region_id: String) -> String:
	return str(scene_background_assets.get(region_id, ""))

func load_texture(path: String, use_mipmaps: bool = false) -> Texture2D:
	if path.is_empty():
		return null
	var cache_key := "%s#mipmap" % path if use_mipmaps else path
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	var image := Image.new()
	if image.load(path) != OK:
		return null
	if use_mipmaps and not image.has_mipmaps():
		image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	texture_cache[cache_key] = texture
	return texture

func get_faction_skills(faction_id: String) -> Array:
	return FACTION_SKILLS.get(faction_id, [])

func is_attack_skill(skill_id: String) -> bool:
	return bool(ATTACK_SKILLS.get(skill_id, false))

func get_skill_summary(skill_id: String) -> String:
	if skill_id == "kf_literate":
		return "江湖阅历与任务线索相关。"
	if is_attack_skill(skill_id):
		return "可在战斗中作为招式使用，等级越高伤害越稳定。"
	if skill_id.find("force") >= 0 or skill_id.find("hunyuan") >= 0 or skill_id.find("jiaoyi") >= 0 or skill_id.find("beiming") >= 0 or skill_id.find("xiaowuxiang") >= 0:
		return "内功心法，当前主要提升修炼与调息表现。"
	if skill_id.find("dodge") >= 0 or skill_id.find("youlong") >= 0 or skill_id.find("meihua") >= 0 or skill_id.find("wanliu") >= 0 or skill_id.find("taxue") >= 0 or skill_id.find("wuying") >= 0 or skill_id.find("lingbo") >= 0 or skill_id.find("xiaoyao_you") >= 0:
		return "身法轻功，当前主要用于战斗脱身与后续探索扩展。"
	return "门派武学，后续可扩展为独立招式效果。"

func get_npc_appearance(npc_data: Dictionary) -> Dictionary:
	var preset_key := _appearance_preset_key(npc_data)
	var preset: Dictionary = APPEARANCE_PRESETS.get(preset_key, APPEARANCE_PRESETS["default"]).duplicate(true)
	if npc_data.has("appearance") and typeof(npc_data["appearance"]) == TYPE_DICTIONARY:
		var override: Dictionary = npc_data["appearance"]
		for key in override.keys():
			preset[key] = override[key]
	return preset

func _appearance_preset_key(npc_data: Dictionary) -> String:
	var npc_name := str(npc_data.get("name", ""))
	match npc_name:
		"平阿四":
			return "innkeeper"
		"店小二":
			return "waiter"
		"阿青":
			return "tofu_seller"
		"老夫子":
			return "scholar"
		"捕快":
			return "constable"
		"村长":
			return "elder"
		"道德和尚":
			return "monk"
		"铁匠":
			return "blacksmith"
		"大侠":
			return "wandering_hero"
		"苏梦瑶":
			return "flower_disciple"
		"陈天行":
			return "wandering_hero"
		"赵无极":
			return "constable"
		"玄机子":
			return "bagua_master"
		"花如玉":
			return "flower_master"
		"烈火":
			return "honglian_master"
		"蛇王":
			return "naja_master"
		"太极真人":
			return "taiji_master"
		"冰魄":
			return "xueshan_master"
		"逍遥子":
			return "wandering_hero"
		"阎商", "葛朗台", "小商贩":
			return "town_trader"
		"厨师":
			return "cook"
		"屠夫":
			return "butcher"
		"卖花女":
			return "flower_seller"
		"平一指":
			return "doctor"
		"何铁手":
			return "poison_master"
		"小裁缝", "何裁缝":
			return "tailor"
		"巡捕", "衙役":
			return "town_guard"
		"老婆婆", "妇人":
			return "town_elder"
		"公子哥":
			return "noble"
		"书童", "小童":
			return "child"
		"何喜", "过路人", "茅十七":
			return "wanderer"
		"李白":
			return "swordsman_poet"
		"韦扬":
			return "bagua_master"
		"清照":
			return "flower_master"
		"于红儒":
			return "honglian_master"
		"钟央":
			return "naja_master"
		"清虚道人":
			return "taiji_master"
		"白瑞德":
			return "xueshan_master"
		"流氓":
			return "thug"
		"流氓头":
			return "bandit"
		"独角大盗", "土匪甲", "土匪头目":
			return "bandit"
		"采花大盗":
			return "assassin"
		"黑衣大盗", "绣花女":
			return "assassin"
		"魔化和尚":
			return "boss"
		"雪豹":
			return "xueshan_disciple"
		"神秘人":
			return "boss"

	var faction_id := str(npc_data.get("faction", "none"))
	if bool(npc_data.get("is_master", false)):
		match faction_id:
			"bagua":
				return "bagua_master"
			"flower":
				return "flower_master"
			"honglian":
				return "honglian_master"
			"naja":
				return "naja_master"
			"taiji":
				return "taiji_master"
			"xueshan":
				return "xueshan_master"
			"xiaoyao":
				return "wandering_hero"
	match faction_id:
		"bagua":
			return "bagua_disciple"
		"flower":
			return "flower_disciple"
		"honglian":
			return "honglian_disciple"
		"naja":
			return "naja_disciple"
		"taiji":
			return "taiji_disciple"
		"xueshan":
			return "xueshan_disciple"
		"xiaoyao":
			return "wandering_hero"
	var npc_type := str(npc_data.get("npc_type", "normal"))
	if npc_type == "enemy":
		return "bandit"
	if npc_type == "trader":
		return "town_trader"
	return "default"

func get_faction_name(faction_id: String) -> String:
	return str(FACTION_NAMES.get(faction_id, FACTION_NAMES["none"]))

func get_faction_color(faction_id: String) -> Color:
	match faction_id:
		"bagua":
			return Color(0.55, 0.52, 0.45)
		"flower":
			return Color(0.86, 0.48, 0.58)
		"honglian":
			return Color(0.82, 0.22, 0.18)
		"naja":
			return Color(0.25, 0.39, 0.29)
		"taiji":
			return Color(0.82, 0.82, 0.78)
		"xueshan":
			return Color(0.62, 0.76, 0.92)
		"xiaoyao":
			return Color(0.50, 0.67, 0.55)
		_:
			return Color(0.75, 0.65, 0.50)

func get_skill_name(skill_id: String) -> String:
	return str(SKILL_NAMES.get(skill_id, skill_id))

func get_dialogue_lines(npc_name: String) -> Array:
	if DIALOGUES.has(npc_name):
		return DIALOGUES[npc_name]
	var npc := get_npc_by_name(npc_name)
	if npc.is_empty():
		return ["江湖路远，少侠保重。"]
	var faction_id := str(npc.get("faction", "none"))
	var npc_type := str(npc.get("npc_type", "normal"))
	if npc_type == "enemy":
		return ["此路不太平，想过去就凭本事。", "刀剑无眼，少侠可想好了？"]
	if bool(npc.get("is_master", false)):
		return ["%s讲究根基，急不得。" % get_faction_name(faction_id), "若你心志坚定，可以先从入门功夫练起。"]
	if npc_type == "trader":
		return ["小店货色不多，但都是行走江湖用得上的东西。", "出门在外，银两和伤药都别省。"]
	if faction_id != "none":
		return ["我是%s门下弟子，平日负责守山与演武。" % get_faction_name(faction_id), "掌门在正殿，有缘自会指点你。"]
	return ["平安镇虽小，江湖风声却不小。", "多问多看，少侠会少吃些亏。"]

func get_npc_by_name(npc_name: String) -> Dictionary:
	for npc in npcs:
		if str(npc.get("name", "")) == npc_name:
			return npc
	return {}

func _fallback_npcs() -> Array:
	return [
		{"id": 47, "name": "平阿四", "npc_type": "trader", "faction": "none", "description": "平安客栈掌柜", "level": 5, "hp": 80, "max_hp": 80, "attack": 10, "defense": 5, "damage": 5, "money": 200, "exp_reward": 30, "pos_x": 22, "pos_y": 22, "has_quests": true},
		{"id": 31, "name": "老夫子", "npc_type": "master", "faction": "none", "description": "私塾先生", "level": 20, "hp": 200, "max_hp": 200, "attack": 5, "defense": 5, "damage": 2, "money": 0, "exp_reward": 100, "pos_x": 28, "pos_y": 19, "is_master": true, "teach_skills": ["kf_literate"]},
		{"id": 21, "name": "流氓", "npc_type": "enemy", "faction": "none", "description": "镇上的小混混", "level": 4, "hp": 60, "max_hp": 60, "attack": 8, "defense": 3, "damage": 5, "money": 30, "exp_reward": 15, "pos_x": 43, "pos_y": 26}
	]
