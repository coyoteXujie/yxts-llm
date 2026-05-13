import math
import random
from typing import List, Optional, Dict
from .entities import Player, NPC, Map, Position, Skill, NpcType, Faction, Item, ItemType, FACTION_NAMES
from .combat import CombatSystem
from .npc_brain import get_npc_brain_manager, get_behavior_tracker
from .encounter import get_encounter_manager, Encounter
from .event import EventType, dispatch
from .systems.reputation import get_reputation_system
from .systems.cultivation import get_cultivation_system
from .systems.equipment import get_equipment_system
from .systems.perform import get_perform_system
from .systems.economy import get_economy_system
from .world_event_engine import get_world_event_engine, apply_story_flags, apply_reward, serialize_node, STORYLINE_TYPE_EVENT_MAP
from .script_system import get_script_db, StorylineType

MAP_W, MAP_H = 100, 80
TS = 64

T_GRASS = 0
T_DIRT_ROAD = 1
T_WATER = 2
T_BUILDING = 3
T_FOREST = 4
T_DARK_GRASS = 5
T_SAND = 6
T_BRIDGE = 7
T_WALL = 8
T_SHOP = 9
T_STONE_ROAD = 10
T_GARDEN = 11
T_HILL = 12
T_INN = 13
T_TEMPLE = 14
T_DOCK = 15
T_ROOF_RED = 16
T_ROOF_BLUE = 17
T_ROOF_GOLD = 18
T_FENCE = 19
T_GATE = 20
T_WELL = 21
T_TABLE = 22
T_CHEST = 23
T_ALTAR = 24
T_TRAINING = 25
T_BAMBOO = 26
T_WATERFALL = 27
T_CAVE = 28
T_TORCH = 29
T_SIGN = 30
T_FLOWER_BED = 31
T_POND = 32
T_STAIRS = 33
T_CARPET = 34
T_BOOKSHELF = 35
T_ANVIL = 36
T_CAMPFIRE = 37
T_GRAVE = 38
T_RICE_PADDY = 39
T_SNOW = 40
T_ICE = 41
T_LAVA = 42
T_SWAMP = 43
T_MUSHROOM = 44
T_RUIN = 45
T_BANNER = 46
T_THRONE = 47
T_PRISON = 48
T_ARENA = 49
T_PILLAR = 50
T_TREE_PINE = 51
T_TREE_WILLOW = 52
T_TREE_BAMBOO_VAR = 53
T_TREE_DEAD = 54
T_PLANT_GREEN = 55
T_PLANT_DARK = 56
T_PLANT_COLD = 57
T_PLANT_SNOW = 58
T_FLOWER_RED = 59
T_FLOWER_PINK = 60
T_FLOWER_WHITE = 61
T_FLOWER_SPECIAL1 = 62
T_FLOWER_SPECIAL2 = 63
T_COUNTER_WOOD = 64
T_COUNTER_HERB = 65
T_COUNTER_WEAPON = 66
T_COUNTER_MONEY = 67
T_COUNTER_INN = 68
T_DESK_WOOD = 69
T_DESK_STONE = 70
T_DESK_LARGE = 71
T_BENCH_WOOD = 72
T_BENCH_STONE = 73
T_BENCH_LONG = 74
T_SHELF_WOOD = 75
T_SHELF_BOOK = 76
T_SHELF_HERB = 77
T_SCULPTURE_LION = 78
T_SCULPTURE_BUDA = 79
T_SCULPTURE_WEAPON = 80
T_BARS = 81
T_BED = 82
T_STAGE = 83
T_BOTTLE = 84
T_BOOK_OBJ = 85
T_BROOM = 86
T_PAIL = 87
T_WOOD_LOG = 88
T_MAT = 89
T_DWELL = 90
T_BRICK = 91
T_FISH = 92
T_HILL_SMALL = 93
T_HILL_MEDIUM = 94
T_HILL_LARGE = 95
T_HILL_SNOW = 96
T_STONE_SMALL = 97
T_STONE_MEDIUM = 98
T_STONE_LARGE = 99
T_WALL_WHITE = 100
T_WALL_GRAY = 101
T_WALL_DARK = 102
T_WALL_STONE = 103
T_WALL_WOOD = 104
T_LAKE = 105
T_ROAD_DIRT = 106
T_COURTYARD = 107

WALKABLE = {
    T_GRASS, T_DIRT_ROAD, T_FOREST, T_DARK_GRASS, T_SAND, T_BRIDGE,
    T_STONE_ROAD, T_GARDEN, T_INN, T_TEMPLE, T_DOCK, T_SHOP,
    T_GATE, T_TRAINING, T_CAVE, T_STAIRS, T_CARPET,
    T_FLOWER_BED, T_RICE_PADDY, T_TORCH, T_SIGN, T_CAMPFIRE,
    T_SNOW, T_MUSHROOM, T_RUIN, T_ARENA, T_POND,
    T_ROAD_DIRT, T_COURTYARD,
    T_PLANT_GREEN, T_PLANT_DARK, T_PLANT_COLD, T_PLANT_SNOW,
    T_FLOWER_RED, T_FLOWER_PINK, T_FLOWER_WHITE, T_FLOWER_SPECIAL1, T_FLOWER_SPECIAL2,
    T_DESK_WOOD, T_DESK_STONE, T_DESK_LARGE,
    T_BENCH_WOOD, T_BENCH_STONE, T_BENCH_LONG,
    T_TABLE, T_MAT, T_BOTTLE, T_BOOK_OBJ, T_BROOM, T_PAIL, T_FISH, T_BRICK,
    T_STONE_SMALL, T_STONE_MEDIUM,
    T_WELL, T_CHEST, T_BOOKSHELF, T_ANVIL, T_BANNER, T_ALTAR,
    T_ICE, T_SWAMP, T_BED, T_STAGE, T_DWELL, T_PILLAR,
}


ALL_SKILLS = {
    "kf_basic_force": Skill(id="kf_basic_force", name="基本内功", type=3, level=1, damage=0, accuracy=0.95),
    "kf_basic_bare": Skill(id="kf_basic_bare", name="基本拳脚", type=0, level=1, damage=5, accuracy=0.85),
    "kf_basic_sword": Skill(id="kf_basic_sword", name="基本剑法", type=1, level=1, damage=7, accuracy=0.82),
    "kf_basic_blade": Skill(id="kf_basic_blade", name="基本刀法", type=2, level=1, damage=8, accuracy=0.80),
    "kf_basic_club": Skill(id="kf_basic_club", name="基本棍法", type=6, level=1, damage=6, accuracy=0.83),
    "kf_basic_staff": Skill(id="kf_basic_staff", name="基本杖法", type=7, level=1, damage=6, accuracy=0.82),
    "kf_basic_whip": Skill(id="kf_basic_whip", name="基本鞭法", type=8, level=1, damage=7, accuracy=0.80),
    "kf_basic_dodge": Skill(id="kf_basic_dodge", name="基本轻功", type=4, level=1, damage=0, accuracy=0.90),
    "kf_basic_parry": Skill(id="kf_basic_parry", name="基本招架", type=5, level=1, damage=0, accuracy=0.85),
    "kf_literate": Skill(id="kf_literate", name="读书识字", type=9, level=1, damage=0, accuracy=1.0),
    "kf_looks": Skill(id="kf_looks", name="容貌", type=10, level=1, damage=0, accuracy=1.0),
    "kf_bagua_blade": Skill(id="kf_bagua_blade", name="八卦刀", type=2, level=1, damage=15, accuracy=0.82),
    "kf_bagua_palm": Skill(id="kf_bagua_palm", name="八卦掌", type=0, level=1, damage=12, accuracy=0.85),
    "kf_bazhen": Skill(id="kf_bazhen", name="八阵图", type=0, level=1, damage=18, accuracy=0.80),
    "kf_hunyuan": Skill(id="kf_hunyuan", name="混元一气", type=3, level=1, damage=0, accuracy=0.95),
    "kf_youlong": Skill(id="kf_youlong", name="游龙步法", type=4, level=1, damage=0, accuracy=0.92),
    "kf_huafei": Skill(id="kf_huafei", name="花飞剑法", type=1, level=1, damage=14, accuracy=0.84),
    "kf_huatuan": Skill(id="kf_huatuan", name="花团锦簇", type=8, level=1, damage=12, accuracy=0.83),
    "kf_liu": Skill(id="kf_liu", name="流水剑法", type=1, level=1, damage=13, accuracy=0.85),
    "kf_meihua": Skill(id="kf_meihua", name="梅花步法", type=4, level=1, damage=0, accuracy=0.90),
    "kf_sanhua": Skill(id="kf_sanhua", name="三花聚顶", type=3, level=1, damage=0, accuracy=0.95),
    "kf_hexiang": Skill(id="kf_hexiang", name="鹤翔步法", type=4, level=1, damage=0, accuracy=0.90),
    "kf_jiaoyi": Skill(id="kf_jiaoyi", name="教义心法", type=3, level=1, damage=0, accuracy=0.95),
    "kf_pifeng": Skill(id="kf_pifeng", name="披风刀法", type=2, level=1, damage=14, accuracy=0.80),
    "kf_taizu": Skill(id="kf_taizu", name="太祖长拳", type=0, level=1, damage=9, accuracy=0.85),
    "kf_tongji": Skill(id="kf_tongji", name="同击术", type=0, level=1, damage=16, accuracy=0.82),
    "kf_renshu": Skill(id="kf_renshu", name="忍术", type=3, level=1, damage=0, accuracy=0.95),
    "kf_wufa": Skill(id="kf_wufa", name="无法拳", type=0, level=1, damage=13, accuracy=0.84),
    "kf_wuying": Skill(id="kf_wuying", name="无影步", type=4, level=1, damage=0, accuracy=0.92),
    "kf_yidao": Skill(id="kf_yidao", name="一刀斩", type=2, level=1, damage=20, accuracy=0.78),
    "kf_taiji_sword": Skill(id="kf_taiji_sword", name="太极剑法", type=1, level=1, damage=16, accuracy=0.85),
    "kf_taiji_fist": Skill(id="kf_taiji_fist", name="太极拳法", type=0, level=1, damage=14, accuracy=0.86),
    "kf_taiji_force": Skill(id="kf_taiji_force", name="太极功", type=3, level=1, damage=0, accuracy=0.95),
    "kf_wanliu": Skill(id="kf_wanliu", name="万柳身法", type=4, level=1, damage=0, accuracy=0.92),
    "kf_xuanxu": Skill(id="kf_xuanxu", name="玄虚刀法", type=2, level=1, damage=13, accuracy=0.82),
    "kf_taxue": Skill(id="kf_taxue", name="踏雪无痕", type=4, level=1, damage=0, accuracy=0.92),
    "kf_xueshang": Skill(id="kf_xueshang", name="雪上霜", type=3, level=1, damage=0, accuracy=0.95),
    "kf_xueshan_sword": Skill(id="kf_xueshan_sword", name="雪山剑法", type=1, level=1, damage=17, accuracy=0.83),
    "kf_xueying": Skill(id="kf_xueying", name="雪影爪", type=0, level=1, damage=10, accuracy=0.88),
    "kf_menghu": Skill(id="kf_menghu", name="猛虎拳", type=0, level=1, damage=15, accuracy=0.82),
    "kf_xi": Skill(id="kf_xi", name="西域心法", type=3, level=1, damage=0, accuracy=0.95),
    "kf_lingbo": Skill(id="kf_lingbo", name="凌波微步", type=4, level=1, damage=0, accuracy=0.93),
    "kf_beiming": Skill(id="kf_beiming", name="北冥神功", type=3, level=1, damage=0, accuracy=0.95),
    "kf_liuyun": Skill(id="kf_liuyun", name="流云剑法", type=1, level=1, damage=16, accuracy=0.84),
    "kf_xiaoyao_palm": Skill(id="kf_xiaoyao_palm", name="逍遥掌", type=0, level=1, damage=14, accuracy=0.85),
}

FACTION_SKILLS = {
    Faction.BAGUA: ["kf_bagua_blade", "kf_bagua_palm", "kf_bazhen", "kf_hunyuan", "kf_youlong"],
    Faction.FLOWER: ["kf_huafei", "kf_huatuan", "kf_liu", "kf_meihua", "kf_sanhua"],
    Faction.HONGLIAN: ["kf_hexiang", "kf_jiaoyi", "kf_pifeng", "kf_taizu", "kf_tongji"],
    Faction.NAJA: ["kf_renshu", "kf_wufa", "kf_wuying", "kf_yidao"],
    Faction.TAIJI: ["kf_taiji_sword", "kf_taiji_fist", "kf_taiji_force", "kf_wanliu", "kf_xuanxu"],
    Faction.XUESHAN: ["kf_taxue", "kf_xueshang", "kf_xueshan_sword", "kf_xueying"],
    Faction.XIAOYAO: ["kf_menghu", "kf_xi", "kf_lingbo", "kf_beiming", "kf_liuyun", "kf_xiaoyao_palm"],
}

PERFORMS = {
    "pf_daoying1": {"name": "刀影一", "faction": Faction.BAGUA, "skill": "kf_bagua_blade", "lvl": 20, "damage": 30, "desc": "刀光剑影，一击必杀"},
    "pf_daoying2": {"name": "刀影二", "faction": Faction.BAGUA, "skill": "kf_bagua_blade", "lvl": 60, "damage": 55, "desc": "刀影绝学，刀气纵横"},
    "pf_zhangdao1": {"name": "掌刀一", "faction": Faction.BAGUA, "skill": "kf_bagua_palm", "lvl": 25, "damage": 25, "desc": "掌中藏刀，虚实难辨"},
    "pf_zhangdao2": {"name": "掌刀二", "faction": Faction.BAGUA, "skill": "kf_bagua_palm", "lvl": 70, "damage": 50, "desc": "掌刀合一，刚柔并济"},
    "pf_luoying": {"name": "落英", "faction": Faction.FLOWER, "skill": "kf_huafei", "lvl": 20, "damage": 28, "desc": "落英缤纷，圈住对手"},
    "pf_liulang": {"name": "流浪", "faction": Faction.FLOWER, "skill": "kf_liu", "lvl": 30, "damage": 32, "desc": "流浪剑法，飘忽不定"},
    "pf_sanhua_pf": {"name": "三花聚顶", "faction": Faction.FLOWER, "skill": "kf_sanhua", "lvl": 60, "damage": 50, "desc": "三花聚顶，绚烂之色"},
    "pf_feizhi": {"name": "飞指", "faction": Faction.FLOWER, "skill": "kf_huafei", "lvl": 40, "damage": 35, "desc": "飞指暗器，百步穿杨"},
    "pf_honglian": {"name": "红莲", "faction": Faction.HONGLIAN, "skill": "kf_tongji", "lvl": 30, "damage": 35, "desc": "红莲密咒，增强战力"},
    "pf_leidong": {"name": "雷动", "faction": Faction.HONGLIAN, "skill": "kf_pifeng", "lvl": 40, "damage": 40, "desc": "雷动九天，增强攻击"},
    "pf_fenshen": {"name": "分身", "faction": Faction.HONGLIAN, "skill": "kf_tongji", "lvl": 70, "damage": 55, "desc": "分身术，影分身攻击"},
    "pf_anmu": {"name": "暗幕", "faction": Faction.NAJA, "skill": "kf_renshu", "lvl": 25, "damage": 20, "desc": "暗幕之术，致盲对手"},
    "pf_lianzhan": {"name": "连斩", "faction": Faction.NAJA, "skill": "kf_yidao", "lvl": 30, "damage": 38, "desc": "连斩三刀，势如破竹"},
    "pf_yidaozhan": {"name": "一刀斩", "faction": Faction.NAJA, "skill": "kf_yidao", "lvl": 80, "damage": 70, "desc": "一刀必杀，天下无双"},
    "pf_chan": {"name": "缠", "faction": Faction.NAJA, "skill": "kf_wufa", "lvl": 20, "damage": 22, "desc": "缠丝术，困敌制胜"},
    "pf_lian": {"name": "连", "faction": Faction.NAJA, "skill": "kf_wufa", "lvl": 50, "damage": 42, "desc": "连环攻击，绵绵不绝"},
    "pf_sanhuang": {"name": "三环", "faction": Faction.TAIJI, "skill": "kf_taiji_fist", "lvl": 25, "damage": 28, "desc": "太极三环，以柔克刚"},
    "pf_ji": {"name": "极", "faction": Faction.TAIJI, "skill": "kf_taiji_sword", "lvl": 40, "damage": 38, "desc": "太极极招，阴阳相生"},
    "pf_luanhuan": {"name": "乱环", "faction": Faction.TAIJI, "skill": "kf_taiji_fist", "lvl": 60, "damage": 52, "desc": "太极乱环诀，四两拨千斤"},
    "pf_yinyang": {"name": "阴阳", "faction": Faction.TAIJI, "skill": "kf_taiji_force", "lvl": 80, "damage": 65, "desc": "太极阴阳，两仪合璧"},
    "pf_zhen": {"name": "阵", "faction": Faction.TAIJI, "skill": "kf_taiji_sword", "lvl": 70, "damage": 55, "desc": "太极阵法，困敌于阵"},
    "pf_bingxin": {"name": "冰心", "faction": Faction.XUESHAN, "skill": "kf_xueshang", "lvl": 30, "damage": 32, "desc": "冰心诀，寒冰护体"},
    "pf_liuchu": {"name": "六出", "faction": Faction.XUESHAN, "skill": "kf_xueshan_sword", "lvl": 50, "damage": 45, "desc": "雪山六出剑，剑气如霜"},
    "pf_qinna": {"name": "擒拿", "faction": Faction.NONE, "skill": "kf_basic_bare", "lvl": 15, "damage": 18, "desc": "擒拿术，近身制敌"},
    "pf_huxiao": {"name": "虎啸", "faction": Faction.XIAOYAO, "skill": "kf_menghu", "lvl": 20, "damage": 28, "desc": "猛虎下山，虎啸山林"},
    "pf_liuyun_jian": {"name": "流云剑意", "faction": Faction.XIAOYAO, "skill": "kf_liuyun", "lvl": 30, "damage": 35, "desc": "流云无定，剑意如风"},
    "pf_beiming_xi": {"name": "北冥吸功", "faction": Faction.XIAOYAO, "skill": "kf_beiming", "lvl": 50, "damage": 45, "desc": "北冥有鱼，吸化万物"},
    "pf_xiaoyao_you": {"name": "逍遥游", "faction": Faction.XIAOYAO, "skill": "kf_lingbo", "lvl": 70, "damage": 58, "desc": "逍遥天地间，无拘无束"},
    "pf_zhetian": {"name": "遮天手", "faction": Faction.XIAOYAO, "skill": "kf_xiaoyao_palm", "lvl": 80, "damage": 68, "desc": "一掌遮天，天地变色"},
}

NPC_DIALOGUES = {
    "平阿四": ["欢迎来到平安客栈！住店歇脚，一应俱全。", "江湖上最近风声紧，客官小心行事。", "听说八卦门的韦掌门在招弟子呢。"],
    "店小二": ["客官请坐！小的马上来！", "今天有新鲜的烧鸡和好酒！", "掌柜的说了，概不赊账！"],
    "阎商": ["盐价又涨了，这世道……", "做买卖讲究的是诚信，我这盐都是上好的。", "你若有丹药，我可以金甲相换。"],
    "葛朗台": ["钱庄的规矩，存取自如！", "一文钱难倒英雄汉，你说是不是？", "年轻人，要学会精打细算！"],
    "阿青": ["这豆腐又白又嫩，客官来一块？", "我师父说过，剑法如流水，绵绵不绝。", "越女剑法，讲究的是以柔克刚。"],
    "厨师": ["今天的烧鸡特别香！", "要肉吗？刚杀的新鲜！", "做菜和练武一样，火候最重要。"],
    "屠夫": ["要肉？上好的鲜肉！", "我这把菜刀，切肉如泥！", "别看我只是个屠夫，当年也是练过功夫的。"],
    "卖花女": ["公子，买朵花吧？", "这红花配公子，真是俊俏！", "茶花、红花，应有尽有。"],
    "小商贩": ["糖葫芦！又甜又酸的糖葫芦！", "小本生意，童叟无欺！", "客官来一串？"],
    "平一指": ["杀一人，医一人，这就是我的规矩。", "你的伤势……让我看看。", "生肌散、丹药，都是上好的。"],
    "何铁手": ["哼，五毒教的东西，你敢用吗？", "我这刀剑，淬了七七四十九种毒。", "当年袁承志教了我不少东西。"],
    "何喜": ["今天钓了条大鱼！", "给我三十条鱼，我送你一把清风剑。", "钓鱼和练功一样，需要耐心。"],
    "小裁缝": ["要做衣服吗？我手艺很好的！", "师傅教我量体裁衣，要细心。", "这布料是上好的丝绸。"],
    "何裁缝": ["老身做了一辈子衣服了。", "给我一副眼镜，我给你做最好的细布衣。", "眼睛不好使了，做针线活真费劲。"],
    "捕快": ["平安镇的治安，由我维护！", "最近采花大盗又出现了，大家小心。", "正义必将伸张！"],
    "巡捕": ["巡逻中，闲人避让！", "最近镇上不太平，晚上别乱走。", "有我在，宵小之辈休想作乱！"],
    "衙役": ["站住！什么人？", "衙门重地，闲人免进！", "有冤情？去里面报官。"],
    "老夫子": ["学而时习之，不亦说乎？", "读书识字，是习武的根本。", "年轻人，要多读书啊！"],
    "村长": ["平安镇百年来风调雨顺。", "最近镇上来了不少江湖人，不知是福是祸。", "有事尽管找我，我在这镇上住了几十年了。"],
    "老婆婆": ["我在这住了几十年了……", "年轻人，路要一步一步走。", "天黑了就早点回家。"],
    "妇人": ["哎呀，我的东西又丢了！", "最近镇上不太平，你可要小心。", "那个采花大盗，真是可恶！"],
    "公子哥": ["本公子要吃白豆腐！每次去集市都要带一包！", "钱？本公子有的是！", "这镇上真无聊。"],
    "书童": ["先生让我抄书，可我想学武……", "如果能有一支毛笔就好了。", "读书好累啊……"],
    "小童": ["哥哥姐姐，陪我玩嘛！", "我最爱吃糖葫芦了！", "爸爸很忙，一直找不到人玩。"],
    "过路人": ["请问，这镇上有客栈吗？", "我是路过的，不认识路。", "江湖险恶，到处都是是非。"],
    "韦扬": ["八卦门广收门徒，你可愿入门？", "混元一气，讲究的是内外兼修。", "八卦刀法，出神入化，方能克敌制胜。"],
    "简明": ["我是大师兄，有什么不懂的问我。", "八卦刀法，重在刀意。", "师父的混元一气已臻化境。"],
    "简杰": ["八阵图，变化无穷。", "师弟，练功要勤勉。", "我虽是二师兄，但刀法不输大师兄。"],
    "简英": ["八卦掌法，刚柔并济。", "游龙步法，身轻如燕。", "师父教导我们，习武先习德。"],
    "鲍振": ["八卦刀，讲究的是步法。", "我是新入门的弟子，还请多多指教。", "师父说我的刀法还差得远。"],
    "武师教头": ["八卦掌，走转连环！", "练功要扎马步，这是基本功。", "想学八卦掌？先跑三圈！"],
    "春花娘": ["八卦门也有女弟子呢。", "我虽是女子，但武功不输男儿。", "师父对我很好。"],
    "护院武师": ["八卦门重地，闲人止步！", "我负责守卫山门。", "想进八卦门？先过我这一关！"],
    "清照": ["花间派只收女弟子，你可知道？", "三花聚顶，是本派至高心法。", "花飞剑法，如落英缤纷。"],
    "红拂女": ["我是花间派弟子，花团锦簇是我的绝技。", "师父清照，才貌双全。", "花鞭虽柔，却可制敌。"],
    "公孙大娘": ["我是百花之母的传人。", "剑舞翩翩，如花似玉。", "花间派的武功，讲究以美制胜。"],
    "青红": ["花团锦簇，鞭法无双。", "我是花间派的大弟子。", "三花聚顶，我已小有成就。"],
    "绿珠": ["平一指调教过我，武功大有长进。", "梅花步法，轻灵飘逸。", "花间派是我的家。"],
    "雪涛": ["花飞剑法，剑走偏锋。", "师父说我天资聪颖。", "花间派的姐妹都很友善。"],
    "隐娘": ["……", "我是个神秘的人。", "有些事，不需要说出来。"],
    "王辞": ["容貌也是修行的一种。", "花飞剑法，我已有所悟。", "读书和练剑，缺一不可。"],
    "于红儒": ["红莲教以义字为先！", "同击术，是我毕生所悟。", "教众们，随我共赴大义！"],
    "方长老": ["老夫是红莲教的管事长老。", "教义心法，不可轻传。", "韩长老原在朝廷为官，后投奔我教。"],
    "韩长老": ["我原在朝廷为官，看不惯那贪官污吏。", "红莲教才是正道！", "太祖长拳，看似简单，实则精妙。"],
    "楚红灯": ["哼！谁敢小看红莲教！", "披风刀法，横扫千军！", "我要让天下人知道红莲教的厉害！"],
    "崇儿": ["同击术，讲究的是合力。", "鹤翔步法，轻功超群。", "师父于红儒，是我最敬佩的人。"],
    "唐四儿": ["独臂又如何？我一样能战斗！", "披风刀法，单手也能施展。", "红莲教给了我新的生活。"],
    "白衣教众": ["红莲教，义字当先！", "教主英明！", "愿为红莲教赴汤蹈火！"],
    "红衣教众": ["红莲教万岁！", "同击术，齐心协力！", "我们是最忠诚的教众！"],
    "钟央": ["那迦派，讲究的是隐忍和一击必杀。", "忍术，是本派的根本。", "我虽是小个子，但建立了那迦派。"],
    "十三卫": ["我是那迦派的十二卫，负责暗杀。", "忍术和一刀斩，是我的绝技。", "钟央掌门，是我的恩师。"],
    "美奈子": ["忍术，需要心如止水。", "一刀斩，快如闪电。", "那迦派的武功，来自东瀛。"],
    "藤王": ["无法拳，无招胜有招。", "忍术是我的强项。", "那迦派的弟子，都是精英。"],
    "游敬": ["无影步，来去无踪。", "一刀斩，是我毕生所修。", "钟央掌门武功盖世。"],
    "天井": ["忍术，需要日积月累。", "无影步，是我的看家本领。", "那迦派，是我唯一的家。"],
    "孙三": ["一刀斩，讲究的是时机。", "忍术，可以探查敌情。", "我跟随钟央掌门多年了。"],
    "浪人甲": ["唉，没能进入那迦派……", "我只是一个流浪的浪人。", "听说那迦派在招弟子？"],
    "清虚道人": ["太极之道，在于阴阳调和。", "太极功，是我毕生所修。", "道法自然，太极无极。"],
    "古松道人": ["太极拳法，以柔克刚。", "我是太极门的师叔。", "清虚掌门道行高深，令人敬佩。"],
    "仓月道人": ["玄虚刀法，虚实相生。", "太极功，需要静心修炼。", "我虽是师叔，但武功远不如掌门。"],
    "采药道人": ["我在后山采药多年。", "太极剑法，剑走轻灵。", "万柳身法，如柳絮飘飞。"],
    "知客道人": ["太极门欢迎有缘人。", "太极拳法，刚柔并济。", "想入门？先见掌门。"],
    "迎客道童": ["欢迎来到太极门！", "我负责迎客，也练太极拳。", "掌门在正殿，请随我来。"],
    "明月": ["我是太极门的弟子，叫明月。", "太极拳法，我还在学习。", "师父说我太傻了……"],
    "清风": ["我是清风，刚入门的小道士。", "太极剑法，好难学啊。", "万柳身法，我总是学不会。"],
    "白瑞德": ["雪山派，立于雪山之巅。", "雪上霜，是我毕生所悟。", "寒冰之气，可以伤敌于无形。"],
    "史婆婆": ["我是白瑞德的妻子，史婆婆。", "雪山剑法，剑气如霜。", "阿秀是我的弟子，很用功。"],
    "万剑": ["我是雪山派大弟子，万剑。", "雪山剑法，剑出如雪。", "踏雪无痕，轻功超群。"],
    "万刃": ["巡山总管万刃，在此！","雪山脚下，有我巡逻。", "雪影爪，爪如利刃。"],
    "万重": ["万重在此！", "雪上霜，寒气逼人。", "踏雪步法，是我的绝技。"],
    "万一": ["我是万一，雪山派弟子。", "雪山剑法，我已有所成。", "师父白瑞德，武功盖世。"],
    "阿秀": ["我是史婆婆的弟子，阿秀。", "雪山剑法，轻灵飘逸。", "踏雪步法，我练了好久。"],
    "雪千柔": ["我叫雪千柔，雪山派女弟子。", "雪影爪，爪法凌厉。", "雪山好冷啊……"],
    "流氓": ["嘿！把值钱的交出来！", "识相的赶紧滚！", "这地盘归我管！"],
    "流氓头": ["你敢跟我作对？", "这镇上我说了算！", "弟兄们，上！"],
    "独角大盗": ["独来独往，天下无敌！", "我的刀，从不留活口！", "你是什么东西，敢挡我的路？"],
    "采花大盗": ["嘿嘿，又来了个美人……", "我的轻功，你追不上！", "想抓我？做梦！"],
    "黑衣大盗": ["……", "你不该看到我的。", "死！"],
    "土匪甲": ["此路是我开，此树是我栽！", "留下买路财！", "不想死的就乖乖交钱！"],
    "土匪头目": ["我是这里的头！","弟兄们，给我上！", "你找死！"],
    "雪豹": ["嗷呜～～", "……", "嘶嘶……"],
    "大侠": ["我追查宝藏，一路追来。", "年轻人，武功高强不是目的。", "江湖路远，且行且珍惜。"],
    "道德和尚": ["色即是空，空即是色。", "施主，放下屠刀，立地成佛。", "善恶一念间，施主好自为之。"],
    "李白": ["人生得意须尽欢，莫使金樽空对月！", "天生我材必有用！", "将进酒，杯莫停！"],
    "茅十七": ["我是茅十八的哥哥，茅十七。", "太祖长拳，我也略知一二。", "江湖上，靠的是本事。"],
    "神秘人": ["……你是谁？", "屠龙刀，号令天下！", "你，不配知道我是谁。"],
    "绣花女": ["绣花针，也能杀人。", "你看到了不该看的东西。", "花飞和太极，我兼修两家。"],
    "魔化和尚": ["哈哈哈！善恶？那只是弱者的借口！", "太极功和雪影爪，我兼而有之！", "这个江湖，将由我来统治！"],
}


def row_to_y(row):
    return (MAP_H - 1 - row) * TS + TS // 2


def col_to_x(col):
    return col * TS + TS // 2


def yx_to_xy(col, row):
    return Position(col_to_x(col), row_to_y(row))


def zone_col_to_x(col):
    return col * TS + TS // 2


def zone_row_to_y(row, zone_h):
    return (zone_h - 1 - row) * TS + TS // 2


def zone_yx_to_xy(col, row, zone_h):
    return Position(zone_col_to_x(col), zone_row_to_y(row, zone_h))


ZONE_NAMES = {
    "luoyang": "洛阳城",
    "chang_an": "长安城",
    "lin_an": "临安城",
    "jiangling": "江陵城",
    "chengdu": "成都城",
    "qinghe": "清河镇",
    "fengxiang": "凤翔镇",
    "shuangliu": "双流镇",
    "yuhang": "余杭镇",
    "bagua_sect": "八卦门",
    "flower_sect": "百花谷",
    "honglian_sect": "红莲教",
    "naja_sect": "那迦派",
    "taiji_sect": "太极门",
    "xueshan_sect": "雪山派",
    "xiaoyao_sect": "逍遥宫",
    "north_wild": "北方荒野",
    "central_wild": "中原野外",
    "south_wild": "南方密林",
    "west_wild": "西部沙漠",
}


class GameWorld:
    def __init__(self):
        self.player: Player = Player()
        self.zones: Dict[str, Map] = {}
        self.current_zone_id: str = "luoyang"
        self.npcs: List[NPC] = []
        self.items: Dict[str, Item] = {}
        self.game_time: float = 0.0
        self.game_hour: int = 8
        self.game_day: int = 1
        self._prev_hour: int = 8
        self.is_paused: bool = False

        self.combat_system = CombatSystem()
        self.game_state: str = "normal"

        self.reputation_system = get_reputation_system()
        self.cultivation_system = get_cultivation_system()
        self.equipment_system = get_equipment_system()
        self.perform_system = get_perform_system()
        self.economy_system = get_economy_system()
        self.world_event_engine = get_world_event_engine()
        self.script_db = get_script_db()

        self._init_all_items()
        self._init_all_zones()
        self._init_all_npcs()
        self._assign_npcs_to_zones()

        self.combat_system.set_performs_db(PERFORMS)
        self.combat_system.set_items_db(self.items)

        cmap = self.zones[self.current_zone_id]
        self.player.position = Position(zone_col_to_x(20), zone_row_to_y(20, cmap.height))
        self._init_player_skills()

    @property
    def current_map(self) -> Optional[Map]:
        return self.zones.get(self.current_zone_id)

    def change_zone(self, zone_id: str, entry_point: Position):
        if zone_id not in self.zones:
            return
        self.current_zone_id = zone_id
        self.player.position.x = entry_point.x
        self.player.position.y = entry_point.y
        cmap = self.current_map
        if cmap:
            for npc in self.npcs:
                if hasattr(npc, '_patrol_origin'):
                    del npc._patrol_origin
                if hasattr(npc, '_patrol_target'):
                    npc._patrol_target = None
                if hasattr(npc, '_patrol_timer'):
                    del npc._patrol_timer
                if hasattr(npc, '_patrol_state'):
                    del npc._patrol_state

    def set_player(self, player: Player):
        self.player = player
        cmap = self.zones.get(self.current_zone_id)
        if cmap:
            self.player.position = Position(zone_col_to_x(20), zone_row_to_y(20, cmap.height))
        self._init_player_skills()

    def _init_player_skills(self):
        base_skills = [
            Skill(id="kf_basic_bare", name="基本拳脚", type=0, level=10, exp=0, damage=5, accuracy=0.85),
            Skill(id="kf_basic_sword", name="基本剑法", type=1, level=5, exp=0, damage=7, accuracy=0.82),
            Skill(id="kf_basic_blade", name="基本刀法", type=2, level=5, exp=0, damage=8, accuracy=0.80),
            Skill(id="kf_basic_dodge", name="基本轻功", type=4, level=10, exp=0, damage=0, accuracy=0.90),
            Skill(id="kf_basic_force", name="基本内功", type=3, level=5, exp=0, damage=3, accuracy=0.95),
            Skill(id="kf_basic_parry", name="基本招架", type=5, level=10, exp=0, damage=0, accuracy=0.85),
            Skill(id="kf_literate", name="读书识字", type=9, level=5, exp=0, damage=0, accuracy=1.0),
            Skill(id="kf_basic_club", name="基本棍法", type=6, level=5, exp=0, damage=6, accuracy=0.83),
        ]
        self.player.skills = list(base_skills)
        self.player.equip_skills = ["kf_basic_bare", "kf_basic_dodge", "kf_basic_force", "kf_basic_parry"]
        self.player.setup_attr()
        self.player.hp = self.player.max_hp
        self.player.mp = self.player.max_mp

    def _place_building(self, tiles, r1, r2, c1, c2, interior, entrance_row, entrance_cols, roof=T_ROOF_RED):
        for r in range(r1, r2 + 1):
            for c in range(c1, c2 + 1):
                if r == r1 or r == r2 or c == c1 or c == c2:
                    tiles[r][c] = T_WALL
                else:
                    tiles[r][c] = interior
        for c in range(c1 + 1, c2):
            tiles[r1][c] = roof
        for c in entrance_cols:
            tiles[entrance_row][c] = T_GATE

    def _init_all_npcs(self):
        from .data_loader import load_npcs
        loaded = load_npcs()
        if loaded:
            self.npcs = loaded
            return
        npcs = [
            NPC(id=47, name="平阿四", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="忠厚老实", description="平安客栈掌柜，消息灵通",
                level=5, strength=8, dexterity=8, intelligence=12, constitution=10,
                hp=80, max_hp=80, mp=40, max_mp=40, attack=10, defense=5, damage=5, money=200, exp_reward=30,
                sell_items=["item_baozi", "item_chicken", "item_wine"],
                position=yx_to_xy(15, 28), has_quests=True),
            NPC(id=35, name="店小二", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="机灵勤快", description="客栈伙计",
                level=3, strength=6, dexterity=10, intelligence=8, constitution=6,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=5, defense=3, damage=3, money=50, exp_reward=15,
                position=yx_to_xy(16, 25), has_quests=False),
            NPC(id=37, name="阎商", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="精明利落", description="盐商，精打细算",
                level=5, strength=6, dexterity=8, intelligence=15, constitution=6,
                hp=60, max_hp=60, mp=30, max_mp=30, attack=8, defense=4, damage=4, money=500, exp_reward=25,
                sell_items=["item_dan"],
                position=yx_to_xy(22, 14), has_quests=True),
            NPC(id=11, name="葛朗台", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="吝啬刻薄", description="钱庄掌柜",
                level=8, strength=5, dexterity=6, intelligence=18, constitution=8,
                hp=70, max_hp=70, mp=40, max_mp=40, attack=6, defense=6, damage=4, money=5000, exp_reward=20,
                position=yx_to_xy(30, 21), has_quests=True),
            NPC(id=1, name="阿青", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="天真善良", description="越女剑传人，卖豆腐为生",
                level=15, strength=16, dexterity=24, intelligence=25, constitution=21,
                hp=370, max_hp=370, mp=200, max_mp=200, attack=30, defense=15, damage=12, money=1000, exp_reward=50,
                sell_items=["item_white_doufu", "item_green_doufu"],
                position=yx_to_xy(8, 14), has_quests=True),
            NPC(id=5, name="厨师", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="豪爽热情", description="酒楼大厨",
                level=5, strength=28, dexterity=21, intelligence=24, constitution=21,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=15, defense=8, damage=8, money=100, exp_reward=15,
                position=yx_to_xy(15, 25), has_quests=True),
            NPC(id=34, name="屠夫", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="粗犷豪放", description="卖肉的屠夫",
                level=6, strength=30, dexterity=15, intelligence=10, constitution=25,
                hp=350, max_hp=350, mp=0, max_mp=0, attack=18, defense=10, damage=10, money=200, exp_reward=20,
                sell_items=["item_meat", "item_chicken"],
                position=yx_to_xy(22, 18), has_quests=False),
            NPC(id=9, name="卖花女", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="温柔可人", description="卖花的姑娘",
                level=2, strength=5, dexterity=10, intelligence=12, constitution=6,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=3, defense=2, damage=1, money=80, exp_reward=8,
                sell_items=["item_red_flower", "item_tea_flower"],
                position=yx_to_xy(22, 24), has_quests=False),
            NPC(id=27, name="小商贩", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="热情吆喝", description="街边小贩",
                level=2, strength=8, dexterity=10, intelligence=10, constitution=8,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=3, defense=2, damage=2, money=50, exp_reward=8,
                sell_items=["item_tang_hulu"],
                position=yx_to_xy(23, 16), has_quests=False),
            NPC(id=26, name="平一指", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="医术高明", description="名医，杀一人医一人",
                level=10, strength=8, dexterity=12, intelligence=20, constitution=10,
                hp=100, max_hp=100, mp=60, max_mp=60, attack=8, defense=5, damage=3, money=300, exp_reward=30,
                sell_items=["item_yao", "item_shengji", "item_dan"],
                position=yx_to_xy(30, 16), has_quests=True),
            NPC(id=19, name="何铁手", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="阴险毒辣", description="五毒教主，师从袁承志",
                level=20, strength=18, dexterity=22, intelligence=20, constitution=16,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=35, defense=15, damage=15, money=2000, exp_reward=80,
                sell_items=["item_blade", "item_dagger", "item_whip", "item_hetun_blade"],
                position=yx_to_xy(16, 21), has_quests=True),
            NPC(id=20, name="何喜", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="悠闲自在", description="渔夫，喜欢钓鱼",
                level=3, strength=10, dexterity=8, intelligence=8, constitution=10,
                hp=40, max_hp=40, mp=10, max_mp=10, attack=4, defense=3, damage=2, money=30, exp_reward=8,
                sell_items=["item_diaogan", "item_fish"],
                position=yx_to_xy(4, 30), has_quests=True),
            NPC(id=29, name="小裁缝", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="心灵手巧", description="裁缝铺小师傅",
                level=4, strength=6, dexterity=14, intelligence=10, constitution=6,
                hp=40, max_hp=40, mp=20, max_mp=20, attack=4, defense=3, damage=2, money=100, exp_reward=10,
                sell_items=["item_cloth", "item_fine_cloth"],
                position=yx_to_xy(8, 18), has_quests=False),
            NPC(id=30, name="何裁缝", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="老练细心", description="做了一辈子衣服的老裁缝",
                level=6, strength=6, dexterity=10, intelligence=12, constitution=8,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=4, defense=3, damage=2, money=150, exp_reward=12,
                sell_items=["item_cloth", "item_fine_cloth", "item_silk_cloth"],
                position=yx_to_xy(9, 19), has_quests=True),
            NPC(id=3, name="捕快", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="刚正不阿", description="平安镇捕快",
                level=12, strength=27, dexterity=25, intelligence=28, constitution=29,
                hp=370, max_hp=370, mp=200, max_mp=200, attack=25, defense=15, damage=10, money=1500, exp_reward=40,
                position=yx_to_xy(40, 25), has_quests=True),
            NPC(id=33, name="巡捕", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="尽职尽责", description="城里巡逻官",
                level=14, strength=25, dexterity=25, intelligence=28, constitution=27,
                hp=350, max_hp=350, mp=200, max_mp=200, attack=22, defense=14, damage=9, money=1200, exp_reward=35,
                position=yx_to_xy(39, 26), has_quests=False),
            NPC(id=14, name="衙役", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="威严守纪", description="衙门守卫",
                level=10, strength=22, dexterity=20, intelligence=15, constitution=22,
                hp=300, max_hp=300, mp=100, max_mp=100, attack=18, defense=12, damage=8, money=500, exp_reward=25,
                position=yx_to_xy(41, 24), has_quests=False),
            NPC(id=31, name="老夫子", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="博学多才", description="私塾先生，读书识字180级",
                level=20, strength=8, dexterity=6, intelligence=30, constitution=8,
                hp=200, max_hp=200, mp=300, max_mp=300, attack=5, defense=5, damage=2, money=0, exp_reward=100,
                position=yx_to_xy(9, 28), is_master=True,
                teach_skills=["kf_literate"], has_quests=True),
            NPC(id=6, name="村长", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="德高望重", description="平安镇村长",
                level=10, strength=29, dexterity=25, intelligence=21, constitution=21,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=15, defense=10, damage=8, money=100, exp_reward=30,
                position=yx_to_xy(37, 18), has_quests=True),
            NPC(id=15, name="老婆婆", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="慈祥温和", description="住了几十年的老居民",
                level=3, strength=6, dexterity=8, intelligence=10, constitution=8,
                hp=40, max_hp=40, mp=10, max_mp=10, attack=3, defense=2, damage=1, money=20, exp_reward=8,
                position=yx_to_xy(8, 22), has_quests=False),
            NPC(id=10, name="妇人", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="忧心忡忡", description="富家妇人，常丢东西",
                level=2, strength=5, dexterity=6, intelligence=10, constitution=6,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=2, defense=1, damage=1, money=500, exp_reward=8,
                position=yx_to_xy(37, 19), has_quests=True),
            NPC(id=13, name="公子哥", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="趾高气扬", description="富家公子，爱吃白豆腐",
                level=3, strength=8, dexterity=10, intelligence=12, constitution=8,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=5, defense=3, damage=3, money=2000, exp_reward=10,
                position=yx_to_xy(23, 22), has_quests=True),
            NPC(id=28, name="书童", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="文质彬彬", description="私塾学童，想学武",
                level=3, strength=5, dexterity=8, intelligence=20, constitution=5,
                hp=30, max_hp=30, mp=20, max_mp=20, attack=3, defense=2, damage=1, money=20, exp_reward=10,
                position=yx_to_xy(8, 28), has_quests=True),
            NPC(id=2, name="小童", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="天真活泼", description="镇上的小孩，爱吃糖葫芦",
                level=1, strength=5, dexterity=8, intelligence=6, constitution=5,
                hp=20, max_hp=20, mp=0, max_mp=0, attack=2, defense=1, damage=1, money=5, exp_reward=3,
                position=yx_to_xy(9, 23), has_quests=True),
            NPC(id=16, name="过路人", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="疲惫迷茫", description="不知从何而来的旅人",
                level=1, strength=6, dexterity=6, intelligence=8, constitution=6,
                hp=25, max_hp=25, mp=5, max_mp=5, attack=2, defense=1, damage=1, money=30, exp_reward=5,
                position=yx_to_xy(22, 26), has_quests=False),
            NPC(id=17, name="茅十七", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="江湖老练", description="茅十八的哥哥",
                level=12, strength=20, dexterity=25, intelligence=15, constitution=18,
                hp=280, max_hp=280, mp=80, max_mp=80, attack=20, defense=12, damage=8, money=200, exp_reward=40,
                position=yx_to_xy(30, 31), has_quests=True),

            NPC(id=48, name="韦扬", npc_type=NpcType.MASTER, faction=Faction.BAGUA,
                personality="威严深沉", description="八卦门掌门，混元一气250级",
                level=40, strength=25, dexterity=22, intelligence=20, constitution=25,
                hp=800, max_hp=800, mp=500, max_mp=500, attack=90, defense=50, damage=35, money=0, exp_reward=1500,
                position=yx_to_xy(61, 5), is_master=True,
                teach_skills=["kf_bagua_blade", "kf_bagua_palm", "kf_bazhen", "kf_hunyuan", "kf_youlong"],
                has_quests=True),
            NPC(id=44, name="简明", npc_type=NpcType.MASTER, faction=Faction.BAGUA,
                personality="刚毅果决", description="八卦门大师兄，八卦刀出神入化",
                level=25, strength=20, dexterity=18, intelligence=15, constitution=18,
                hp=500, max_hp=500, mp=250, max_mp=250, attack=50, defense=30, damage=20, money=0, exp_reward=500,
                position=yx_to_xy(62, 8), is_master=True,
                teach_skills=["kf_bagua_blade", "kf_bagua_palm"],
                has_quests=False),
            NPC(id=43, name="简杰", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="沉稳内敛", description="八卦门二师兄，八阵图高手",
                level=22, strength=18, dexterity=16, intelligence=18, constitution=16,
                hp=420, max_hp=420, mp=200, max_mp=200, attack=40, defense=25, damage=16, money=50, exp_reward=350,
                position=yx_to_xy(60, 7), has_quests=False),
            NPC(id=45, name="简英", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="英气勃发", description="八卦门三师兄",
                level=20, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=380, max_hp=380, mp=180, max_mp=180, attack=35, defense=22, damage=14, money=30, exp_reward=280,
                position=yx_to_xy(63, 7), has_quests=False),
            NPC(id=46, name="鲍振", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="勤勉好学", description="八卦门弟子，刀法不错",
                level=12, strength=14, dexterity=12, intelligence=10, constitution=14,
                hp=250, max_hp=250, mp=100, max_mp=100, attack=22, defense=14, damage=10, money=20, exp_reward=120,
                position=yx_to_xy(61, 9), has_quests=False),
            NPC(id=49, name="武师教头", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="严厉刚正", description="八卦门武师教头",
                level=15, strength=18, dexterity=16, intelligence=12, constitution=18,
                hp=320, max_hp=320, mp=120, max_mp=120, attack=28, defense=18, damage=12, money=50, exp_reward=180,
                position=yx_to_xy(62, 10), has_quests=False),
            NPC(id=50, name="春花娘", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="温柔坚韧", description="八卦门女弟子",
                level=10, strength=10, dexterity=14, intelligence=12, constitution=10,
                hp=200, max_hp=200, mp=80, max_mp=80, attack=15, defense=10, damage=6, money=30, exp_reward=60,
                position=yx_to_xy(60, 9), has_quests=False),
            NPC(id=51, name="护院武师", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="老实忠厚", description="八卦门护院",
                level=8, strength=14, dexterity=10, intelligence=8, constitution=14,
                hp=180, max_hp=180, mp=60, max_mp=60, attack=14, defense=10, damage=6, money=20, exp_reward=40,
                position=yx_to_xy(59, 5), has_quests=False),

            NPC(id=57, name="清照", npc_type=NpcType.MASTER, faction=Faction.FLOWER,
                personality="清雅脱俗", description="花间派掌门，三花聚顶250级",
                level=40, strength=15, dexterity=28, intelligence=25, constitution=18,
                hp=700, max_hp=700, mp=600, max_mp=600, attack=75, defense=40, damage=30, money=0, exp_reward=1500,
                position=yx_to_xy(64, 20), is_master=True,
                teach_skills=["kf_huafei", "kf_huatuan", "kf_liu", "kf_meihua", "kf_sanhua"],
                has_quests=True),
            NPC(id=53, name="红拂女", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="英姿飒爽", description="花间派弟子，花团锦簇高手",
                level=18, strength=14, dexterity=22, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=150, max_mp=150, attack=30, defense=18, damage=12, money=100, exp_reward=200,
                position=yx_to_xy(63, 21), has_quests=False),
            NPC(id=55, name="公孙大娘", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="端庄大方", description="百花之母的传人",
                level=22, strength=16, dexterity=20, intelligence=18, constitution=16,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=38, defense=22, damage=15, money=80, exp_reward=300,
                position=yx_to_xy(57, 22), has_quests=False),
            NPC(id=56, name="青红", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="热情似火", description="花间派大弟子",
                level=20, strength=14, dexterity=20, intelligence=16, constitution=14,
                hp=350, max_hp=350, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=60, exp_reward=250,
                position=yx_to_xy(65, 23), has_quests=False),
            NPC(id=58, name="绿珠", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="温婉可人", description="花间派弟子，经平一指调教",
                level=16, strength=12, dexterity=18, intelligence=14, constitution=12,
                hp=260, max_hp=260, mp=130, max_mp=130, attack=25, defense=16, damage=10, money=40, exp_reward=160,
                position=yx_to_xy(63, 22), has_quests=False),
            NPC(id=59, name="雪涛", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="冷静沉着", description="花间派弟子",
                level=15, strength=12, dexterity=16, intelligence=14, constitution=12,
                hp=240, max_hp=240, mp=120, max_mp=120, attack=22, defense=14, damage=9, money=30, exp_reward=140,
                position=yx_to_xy(65, 25), has_quests=False),
            NPC(id=60, name="隐娘", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="神秘莫测", description="花间派神秘弟子",
                level=20, strength=14, dexterity=22, intelligence=16, constitution=14,
                hp=340, max_hp=340, mp=170, max_mp=170, attack=30, defense=18, damage=12, money=0, exp_reward=220,
                position=yx_to_xy(57, 20), has_quests=True),
            NPC(id=61, name="王辞", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="才貌双全", description="花间派弟子，容貌180级",
                level=18, strength=12, dexterity=18, intelligence=20, constitution=12,
                hp=280, max_hp=280, mp=160, max_mp=160, attack=26, defense=16, damage=10, money=50, exp_reward=180,
                position=yx_to_xy(60, 26), has_quests=False),

            NPC(id=79, name="于红儒", npc_type=NpcType.MASTER, faction=Faction.HONGLIAN,
                personality="刚烈如火", description="红莲教掌门，同击术250级",
                level=40, strength=28, dexterity=18, intelligence=15, constitution=28,
                hp=900, max_hp=900, mp=400, max_mp=400, attack=85, defense=55, damage=35, money=0, exp_reward=1500,
                position=yx_to_xy(61, 38), is_master=True,
                teach_skills=["kf_hexiang", "kf_jiaoyi", "kf_pifeng", "kf_taizu", "kf_tongji"],
                has_quests=True),
            NPC(id=72, name="方长老", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="老谋深算", description="红莲教管事长老",
                level=22, strength=18, dexterity=15, intelligence=18, constitution=18,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=35, defense=25, damage=15, money=200, exp_reward=300,
                position=yx_to_xy(63, 38), has_quests=True),
            NPC(id=73, name="韩长老", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="愤世嫉俗", description="原在朝廷为官，后投奔红莲教",
                level=18, strength=14, dexterity=14, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=150, max_mp=150, attack=25, defense=18, damage=10, money=100, exp_reward=180,
                position=yx_to_xy(60, 39), has_quests=False),
            NPC(id=74, name="楚红灯", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="暴躁易怒", description="红莲教弟子，满脸怒气",
                level=16, strength=16, dexterity=12, intelligence=10, constitution=16,
                hp=280, max_hp=280, mp=120, max_mp=120, attack=24, defense=16, damage=10, money=50, exp_reward=150,
                position=yx_to_xy(64, 40), has_quests=False),
            NPC(id=75, name="崇儿", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="刚毅坚定", description="红莲教女弟子，武功不凡",
                level=20, strength=16, dexterity=20, intelligence=14, constitution=16,
                hp=360, max_hp=360, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=30, exp_reward=240,
                position=yx_to_xy(62, 41), has_quests=False),
            NPC(id=76, name="唐四儿", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="坚韧不拔", description="独臂英雄",
                level=18, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=40, exp_reward=200,
                position=yx_to_xy(59, 39), has_quests=False),
            NPC(id=77, name="白衣教众", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="忠诚", description="红莲教白衣教众",
                level=8, strength=10, dexterity=8, intelligence=8, constitution=10,
                hp=150, max_hp=150, mp=50, max_mp=50, attack=12, defense=8, damage=5, money=10, exp_reward=30,
                position=yx_to_xy(60, 38), has_quests=False),
            NPC(id=78, name="红衣教众", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="狂热", description="红莲教红衣教众",
                level=10, strength=12, dexterity=10, intelligence=8, constitution=12,
                hp=180, max_hp=180, mp=60, max_mp=60, attack=15, defense=10, damage=6, money=15, exp_reward=40,
                position=yx_to_xy(63, 42), has_quests=False),

            NPC(id=92, name="钟央", npc_type=NpcType.MASTER, faction=Faction.NAJA,
                personality="沉默寡言", description="那迦派掌门，忍术250级",
                level=40, strength=22, dexterity=25, intelligence=22, constitution=20,
                hp=750, max_hp=750, mp=500, max_mp=500, attack=80, defense=45, damage=30, money=0, exp_reward=1500,
                position=yx_to_xy(79, 6), is_master=True,
                teach_skills=["kf_renshu", "kf_wufa", "kf_wuying", "kf_yidao"],
                has_quests=True),
            NPC(id=80, name="十三卫", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="冷酷无情", description="那迦派高手，负责暗杀",
                level=20, strength=18, dexterity=20, intelligence=12, constitution=16,
                hp=350, max_hp=350, mp=150, max_mp=150, attack=35, defense=20, damage=15, money=50, exp_reward=250,
                position=yx_to_xy(80, 8), has_quests=False),
            NPC(id=81, name="美奈子", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="沉静如水", description="那迦派女弟子",
                level=18, strength=14, dexterity=18, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=160, max_mp=160, attack=28, defense=16, damage=12, money=30, exp_reward=180,
                position=yx_to_xy(78, 5), has_quests=False),
            NPC(id=82, name="藤王", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="桀骜不驯", description="那迦派弟子",
                level=16, strength=16, dexterity=16, intelligence=12, constitution=14,
                hp=280, max_hp=280, mp=130, max_mp=130, attack=26, defense=16, damage=11, money=40, exp_reward=160,
                position=yx_to_xy(82, 8), has_quests=False),
            NPC(id=83, name="游敬", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="沉默寡言", description="那迦派弟子",
                level=18, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=30, exp_reward=190,
                position=yx_to_xy(79, 10), has_quests=False),
            NPC(id=84, name="天井", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="机敏灵活", description="那迦派弟子",
                level=14, strength=14, dexterity=16, intelligence=12, constitution=14,
                hp=240, max_hp=240, mp=110, max_mp=110, attack=22, defense=14, damage=9, money=20, exp_reward=120,
                position=yx_to_xy(81, 11), has_quests=False),
            NPC(id=85, name="孙三", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="精明干练", description="那迦派弟子",
                level=14, strength=14, dexterity=14, intelligence=14, constitution=14,
                hp=240, max_hp=240, mp=110, max_mp=110, attack=22, defense=14, damage=9, money=20, exp_reward=120,
                position=yx_to_xy(80, 12), has_quests=False),
            NPC(id=86, name="浪人甲", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="落魄失意", description="没能进入那迦派的浪人",
                level=8, strength=12, dexterity=14, intelligence=8, constitution=10,
                hp=160, max_hp=160, mp=50, max_mp=50, attack=14, defense=8, damage=5, money=10, exp_reward=40,
                position=yx_to_xy(73, 8), has_quests=False),

            NPC(id=99, name="清虚道人", npc_type=NpcType.MASTER, faction=Faction.TAIJI,
                personality="仙风道骨", description="太极门掌门，太极功250级",
                level=45, strength=20, dexterity=22, intelligence=28, constitution=22,
                hp=850, max_hp=850, mp=700, max_mp=700, attack=85, defense=55, damage=30, money=0, exp_reward=2000,
                position=yx_to_xy(79, 20), is_master=True,
                teach_skills=["kf_taiji_sword", "kf_taiji_fist", "kf_taiji_force", "kf_wanliu", "kf_xuanxu"],
                has_quests=True),
            NPC(id=95, name="古松道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="沉稳内敛", description="太极门师叔",
                level=25, strength=18, dexterity=16, intelligence=20, constitution=18,
                hp=450, max_hp=450, mp=250, max_mp=250, attack=40, defense=30, damage=15, money=0, exp_reward=400,
                position=yx_to_xy(81, 22), has_quests=False),
            NPC(id=96, name="仓月道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="深藏不露", description="太极门师叔",
                level=22, strength=16, dexterity=18, intelligence=20, constitution=16,
                hp=400, max_hp=400, mp=220, max_mp=220, attack=35, defense=25, damage=14, money=0, exp_reward=320,
                position=yx_to_xy(80, 20), has_quests=False),
            NPC(id=97, name="采药道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="淡泊名利", description="太极门前辈师叔",
                level=18, strength=14, dexterity=16, intelligence=18, constitution=14,
                hp=320, max_hp=320, mp=180, max_mp=180, attack=28, defense=18, damage=11, money=0, exp_reward=200,
                position=yx_to_xy(83, 24), has_quests=False),
            NPC(id=98, name="知客道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="和蔼可亲", description="太极门弟子",
                level=14, strength=12, dexterity=14, intelligence=14, constitution=12,
                hp=240, max_hp=240, mp=120, max_mp=120, attack=20, defense=14, damage=8, money=20, exp_reward=120,
                position=yx_to_xy(79, 24), has_quests=False),
            NPC(id=100, name="迎客道童", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="热情好客", description="太极门弟子",
                level=10, strength=10, dexterity=12, intelligence=10, constitution=10,
                hp=180, max_hp=180, mp=80, max_mp=80, attack=15, defense=10, damage=6, money=10, exp_reward=60,
                position=yx_to_xy(80, 25), has_quests=False),
            NPC(id=101, name="明月", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="憨厚老实", description="太极门弟子，傻乎乎的",
                level=8, strength=8, dexterity=10, intelligence=8, constitution=10,
                hp=150, max_hp=150, mp=60, max_mp=60, attack=12, defense=8, damage=5, money=5, exp_reward=40,
                position=yx_to_xy(81, 24), has_quests=False),
            NPC(id=102, name="清风", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="勤勉好学", description="太极门入门弟子",
                level=6, strength=6, dexterity=8, intelligence=8, constitution=6,
                hp=100, max_hp=100, mp=40, max_mp=40, attack=8, defense=6, damage=3, money=5, exp_reward=20,
                position=yx_to_xy(83, 25), has_quests=False),

            NPC(id=108, name="白瑞德", npc_type=NpcType.MASTER, faction=Faction.XUESHAN,
                personality="冷峻如冰", description="雪山派掌门，雪上霜250级",
                level=42, strength=24, dexterity=26, intelligence=18, constitution=24,
                hp=800, max_hp=800, mp=500, max_mp=500, attack=90, defense=45, damage=35, money=0, exp_reward=1800,
                position=yx_to_xy(79, 39), is_master=True,
                teach_skills=["kf_taxue", "kf_xueshang", "kf_xueshan_sword", "kf_xueying"],
                has_quests=True),
            NPC(id=109, name="史婆婆", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="严厉慈爱", description="白瑞德的妻子",
                level=22, strength=18, dexterity=18, intelligence=16, constitution=18,
                hp=380, max_hp=380, mp=200, max_mp=200, attack=35, defense=22, damage=14, money=30, exp_reward=300,
                position=yx_to_xy(81, 42), has_quests=False),
            NPC(id=110, name="万剑", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="锐气逼人", description="雪山派大弟子",
                level=20, strength=18, dexterity=20, intelligence=14, constitution=18,
                hp=360, max_hp=360, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=20, exp_reward=250,
                position=yx_to_xy(80, 38), has_quests=False),
            NPC(id=111, name="万刃", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="刚毅果敢", description="雪山派巡山总管",
                level=18, strength=16, dexterity=16, intelligence=12, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=15, exp_reward=200,
                position=yx_to_xy(82, 38), has_quests=False),
            NPC(id=112, name="万重", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="稳重踏实", description="雪山派弟子",
                level=16, strength=14, dexterity=14, intelligence=12, constitution=16,
                hp=280, max_hp=280, mp=130, max_mp=130, attack=24, defense=16, damage=10, money=10, exp_reward=160,
                position=yx_to_xy(79, 44), has_quests=False),
            NPC(id=113, name="万一", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="谨慎小心", description="雪山派弟子",
                level=16, strength=14, dexterity=16, intelligence=12, constitution=14,
                hp=270, max_hp=270, mp=130, max_mp=130, attack=24, defense=15, damage=10, money=10, exp_reward=160,
                position=yx_to_xy(81, 44), has_quests=False),
            NPC(id=107, name="阿秀", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="温柔坚韧", description="雪山派女弟子，史婆婆的弟子",
                level=14, strength=10, dexterity=16, intelligence=14, constitution=10,
                hp=220, max_hp=220, mp=110, max_mp=110, attack=20, defense=12, damage=8, money=15, exp_reward=100,
                position=yx_to_xy(80, 42), has_quests=False),
            NPC(id=114, name="雪千柔", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="柔弱似水", description="雪山派女弟子",
                level=8, strength=8, dexterity=10, intelligence=10, constitution=8,
                hp=140, max_hp=140, mp=60, max_mp=60, attack=10, defense=8, damage=4, money=10, exp_reward=40,
                position=yx_to_xy(83, 44), has_quests=False),

            NPC(id=21, name="流氓", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="欺软怕硬", description="镇上的小混混",
                level=4, strength=12, dexterity=10, intelligence=5, constitution=10,
                hp=60, max_hp=60, mp=0, max_mp=0, attack=8, defense=3, damage=5, money=30, exp_reward=15,
                position=yx_to_xy(46, 44), has_quests=False),
            NPC(id=22, name="流氓头", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶神恶煞", description="流氓头子",
                level=7, strength=16, dexterity=12, intelligence=8, constitution=14,
                hp=100, max_hp=100, mp=20, max_mp=20, attack=15, defense=6, damage=8, money=100, exp_reward=30,
                position=yx_to_xy(48, 46), has_quests=False),
            NPC(id=8, name="独角大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="残暴无情", description="臭名昭著的大盗",
                level=12, strength=33, dexterity=18, intelligence=20, constitution=22,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=25, defense=12, damage=15, money=10000, exp_reward=80,
                position=yx_to_xy(50, 55), has_quests=False),
            NPC(id=4, name="采花大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="阴险狡诈", description="采花大盗，轻功了得",
                level=15, strength=18, dexterity=28, intelligence=22, constitution=24,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=22, defense=10, damage=12, money=10000, exp_reward=100,
                position=yx_to_xy(52, 58), has_quests=False),
            NPC(id=18, name="黑衣大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="冷酷无情", description="神秘黑衣人，来去无踪",
                level=18, strength=22, dexterity=25, intelligence=18, constitution=20,
                hp=400, max_hp=400, mp=100, max_mp=100, attack=30, defense=15, damage=18, money=5000, exp_reward=120,
                position=yx_to_xy(54, 62), has_quests=False),
            NPC(id=23, name="土匪甲", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶悍蛮横", description="雪山脚下的土匪",
                level=10, strength=20, dexterity=12, intelligence=8, constitution=16,
                hp=200, max_hp=200, mp=0, max_mp=0, attack=18, defense=8, damage=10, money=500, exp_reward=50,
                position=yx_to_xy(74, 50), has_quests=False),
            NPC(id=24, name="土匪头目", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="残暴嗜血", description="土匪头目",
                level=15, strength=24, dexterity=16, intelligence=12, constitution=20,
                hp=350, max_hp=350, mp=50, max_mp=50, attack=28, defense=14, damage=15, money=2000, exp_reward=100,
                position=yx_to_xy(76, 52), has_quests=False),
            NPC(id=25, name="雪豹", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶猛野兽", description="雪山上的猛兽",
                level=12, strength=22, dexterity=20, intelligence=5, constitution=20,
                hp=280, max_hp=280, mp=0, max_mp=0, attack=22, defense=10, damage=12, money=0, exp_reward=60,
                position=yx_to_xy(84, 48), has_quests=False),

            NPC(id=7, name="大侠", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="侠肝义胆", description="武功高强的游侠，追查宝藏",
                level=35, strength=20, dexterity=20, intelligence=26, constitution=21,
                hp=620, max_hp=620, mp=1200, max_mp=1200, attack=80, defense=40, damage=30, money=0, exp_reward=1000,
                position=yx_to_xy(40, 55), is_master=True,
                teach_skills=["kf_basic_bare", "kf_basic_sword", "kf_basic_blade", "kf_basic_club"],
                has_quests=True),
            NPC(id=12, name="道德和尚", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="慈悲为怀", description="少林高僧，善恶一念间",
                level=25, strength=20, dexterity=15, intelligence=30, constitution=25,
                hp=500, max_hp=500, mp=300, max_mp=300, attack=50, defense=40, damage=20, money=0, exp_reward=500,
                position=yx_to_xy(8, 20), is_master=True,
                teach_skills=["kf_basic_force", "kf_basic_parry"], has_quests=True),
            NPC(id=32, name="李白", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="豪放不羁", description="诗仙剑客，剑法超群",
                level=30, strength=20, dexterity=25, intelligence=30, constitution=20,
                hp=600, max_hp=600, mp=400, max_mp=400, attack=70, defense=35, damage=25, money=0, exp_reward=800,
                position=yx_to_xy(40, 48), is_master=True,
                teach_skills=["kf_basic_sword", "kf_huafei"], has_quests=True),

            NPC(id=120, name="神秘人", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="神秘莫测", description="手持屠龙刀的神秘人，集多门派武功于一身",
                level=50, strength=30, dexterity=25, intelligence=28, constitution=28,
                hp=2000, max_hp=2000, mp=1500, max_mp=1500, attack=120, defense=60, damage=50, money=0, exp_reward=5000,
                position=yx_to_xy(55, 70), has_quests=True),
            NPC(id=121, name="绣花女", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="冷艳绝伦", description="使用绣花针的神秘女子，兼修太极和花间武功",
                level=55, strength=22, dexterity=35, intelligence=30, constitution=22,
                hp=1800, max_hp=1800, mp=2000, max_mp=2000, attack=110, defense=55, damage=45, money=0, exp_reward=6000,
                position=yx_to_xy(58, 72), has_quests=True),
            NPC(id=122, name="魔化和尚", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="癫狂邪恶", description="道德和尚的黑暗面，兼修雪山和太极武功",
                level=60, strength=35, dexterity=28, intelligence=32, constitution=35,
                hp=2500, max_hp=2500, mp=2000, max_mp=2000, attack=140, defense=70, damage=60, money=0, exp_reward=8000,
                position=yx_to_xy(48, 72), has_quests=True),
        ]
        self.npcs = list(npcs)
        for npc in self.npcs:
            npc._death_time = 0

    def _assign_npcs_to_zones(self):
        from .data_loader import load_npcs
        loaded = load_npcs()
        if loaded:
            self.npcs = loaded
            for npc in self.npcs:
                npc._death_time = 0

        NPC_ZONE_MAP = {
            "平阿四": ("luoyang", 7, 5), "店小二": ("luoyang", 7, 7),
            "阎商": ("luoyang", 14, 5), "葛朗台": ("luoyang", 25, 5),
            "阿青": ("luoyang", 14, 24), "厨师": ("luoyang", 7, 24),
            "屠夫": ("luoyang", 14, 24), "卖花女": ("luoyang", 24, 24),
            "小商贩": ("luoyang", 16, 24), "平一指": ("luoyang", 16, 5),
            "何铁手": ("luoyang", 14, 16), "何喜": ("lin_an", 13, 5),
            "小裁缝": ("chengdu", 14, 5), "何裁缝": ("chengdu", 14, 24),
            "捕快": ("chang_an", 25, 5), "巡捕": ("chang_an", 25, 24),
            "衙役": ("chang_an", 25, 24), "老夫子": ("luoyang", 25, 15),
            "村长": ("qinghe", 14, 10), "老婆婆": ("luoyang", 24, 5),
            "妇人": ("qinghe", 14, 5), "公子哥": ("luoyang", 24, 25),
            "书童": ("luoyang", 25, 15), "小童": ("luoyang", 24, 10),
            "过路人": ("fengxiang", 10, 10), "茅十七": ("jiangling", 15, 10),
            "韦扬": ("bagua_sect", 8, 12), "简明": ("bagua_sect", 6, 8),
            "简杰": ("bagua_sect", 6, 7), "简英": ("bagua_sect", 6, 16),
            "鲍振": ("bagua_sect", 9, 8), "武师教头": ("bagua_sect", 9, 16),
            "春花娘": ("bagua_sect", 9, 7), "护院武师": ("bagua_sect", 3, 7),
            "清照": ("flower_sect", 6, 17), "红拂女": ("flower_sect", 8, 17),
            "公孙大娘": ("flower_sect", 6, 8), "青红": ("flower_sect", 8, 20),
            "绿珠": ("flower_sect", 8, 10), "雪涛": ("flower_sect", 10, 20),
            "隐娘": ("flower_sect", 6, 10), "王辞": ("flower_sect", 10, 8),
            "于红儒": ("honglian_sect", 8, 12), "方长老": ("honglian_sect", 6, 8),
            "韩长老": ("honglian_sect", 6, 16), "楚红灯": ("honglian_sect", 10, 8),
            "崇儿": ("honglian_sect", 10, 16), "唐四儿": ("honglian_sect", 10, 10),
            "白衣教众": ("honglian_sect", 14, 8), "红衣教众": ("honglian_sect", 14, 16),
            "钟央": ("naja_sect", 8, 12), "十三卫": ("naja_sect", 6, 8),
            "美奈子": ("naja_sect", 6, 16), "藤王": ("naja_sect", 10, 8),
            "游敬": ("naja_sect", 10, 16), "天井": ("naja_sect", 14, 8),
            "孙三": ("naja_sect", 14, 16), "浪人甲": ("north_wild", 15, 15),
            "清虚道人": ("taiji_sect", 8, 12), "古松道人": ("taiji_sect", 6, 8),
            "仓月道人": ("taiji_sect", 6, 16), "采药道人": ("taiji_sect", 10, 8),
            "知客道人": ("taiji_sect", 10, 16), "迎客道童": ("taiji_sect", 14, 8),
            "明月": ("taiji_sect", 14, 16), "清风": ("taiji_sect", 18, 8),
            "白瑞德": ("xueshan_sect", 8, 12), "史婆婆": ("xueshan_sect", 6, 8),
            "万剑": ("xueshan_sect", 6, 16), "万刃": ("xueshan_sect", 10, 8),
            "万重": ("xueshan_sect", 10, 16), "万一": ("xueshan_sect", 14, 8),
            "阿秀": ("xueshan_sect", 14, 16), "雪千柔": ("xueshan_sect", 18, 8),
            "流氓": ("central_wild", 15, 15), "流氓头": ("central_wild", 18, 18),
            "独角大盗": ("south_wild", 15, 15), "采花大盗": ("south_wild", 12, 12),
            "黑衣大盗": ("south_wild", 18, 18), "土匪甲": ("west_wild", 15, 15),
            "土匪头目": ("west_wild", 18, 18), "雪豹": ("north_wild", 20, 20),
            "大侠": ("central_wild", 15, 15), "道德和尚": ("luoyang", 5, 5),
            "李白": ("chang_an", 5, 5), "神秘人": ("west_wild", 20, 20),
            "绣花女": ("south_wild", 20, 20), "魔化和尚": ("west_wild", 15, 10),
        }

        for npc in self.npcs:
            info = NPC_ZONE_MAP.get(npc.name)
            if info:
                zone_id, row, col = info
                zm = self.zones.get(zone_id)
                if zm:
                    npc.position = zone_yx_to_xy(col, row, zm.height)
                    npc.location = ZONE_NAMES.get(zone_id, zone_id)

    def _init_all_items(self):
        from .data_loader import load_items
        loaded = load_items()
        if loaded:
            self.items = loaded
            return
        items = [
            Item(id="item_baozi", name="包子", type=ItemType.CONSUMABLE, price=5, description="一笼热气腾腾的大包子", effects={"hp": 20, "food": 30}),
        ]
        self.items = {item.id: item for item in items}

    def _init_all_zones(self):
        self.zones = {}

        def mk(w, h, base=T_GRASS):
            return [[base for _ in range(w)] for _ in range(h)]

        def wborder(t, w, h, wt=T_WALL_STONE):
            for c in range(w):
                t[0][c] = wt
                t[h - 1][c] = wt
            for r in range(h):
                t[r][0] = wt
                t[r][w - 1] = wt

        def zfill(t, r1, r2, c1, c2, tid, w, h):
            for r in range(max(0, r1), min(h, r2)):
                for c in range(max(0, c1), min(w, c2)):
                    t[r][c] = tid

        def zgate_h(t, row, col):
            t[row][col] = T_GATE
            t[row][col + 1] = T_GATE

        def zgate_v(t, row, col):
            t[row][col] = T_GATE
            t[row + 1][col] = T_GATE

        def zroad_h(t, row, c1, c2, w, tid=T_STONE_ROAD, wd=2):
            for r in range(row, min(row + wd, h)):
                for c in range(max(0, c1), min(w, c2)):
                    t[r][c] = tid

        def zroad_v(t, col, r1, r2, h, tid=T_STONE_ROAD, wd=2):
            for c in range(col, min(col + wd, w)):
                for r in range(max(0, r1), min(h, r2)):
                    t[r][c] = tid

        # ========== luoyang 洛阳城 (40x40) ==========
        w, h = 40, 40
        t = mk(w, h)
        wborder(t, w, h)
        zgate_h(t, 0, 19)
        zgate_h(t, h - 1, 19)
        zgate_v(t, 19, 0)
        zgate_v(t, 19, w - 1)
        zfill(t, 18, 22, 1, w - 1, T_STONE_ROAD, w, h)
        zfill(t, 1, h - 1, 18, 22, T_STONE_ROAD, w, h)
        self._place_building(t, 3, 8, 3, 10, T_INN, 8, [5, 6], T_ROOF_RED)
        t[5][5] = T_BENCH_LONG
        t[5][8] = T_TABLE
        t[6][6] = T_BED
        self._place_building(t, 3, 8, 13, 18, T_TEMPLE, 8, [15, 16], T_ROOF_GOLD)
        t[5][15] = T_DESK_LARGE
        t[6][16] = T_BANNER
        self._place_building(t, 3, 8, 22, 30, T_SHOP, 8, [25, 26], T_ROOF_BLUE)
        t[5][24] = T_COUNTER_WOOD
        t[5][28] = T_SHELF_WOOD
        self._place_building(t, 10, 16, 3, 10, T_SHOP, 16, [5, 6], T_ROOF_BLUE)
        t[12][5] = T_COUNTER_HERB
        t[12][8] = T_SHELF_HERB
        self._place_building(t, 10, 16, 22, 30, T_SHOP, 10, [25, 26], T_ROOF_BLUE)
        t[12][24] = T_COUNTER_WEAPON
        t[12][28] = T_SHELF_WOOD
        self._place_building(t, 22, 28, 3, 10, T_DWELL, 22, [5, 6], T_ROOF_RED)
        t[24][5] = T_DESK_WOOD
        t[24][8] = T_BENCH_WOOD
        self._place_building(t, 22, 28, 22, 30, T_DWELL, 22, [25, 26], T_ROOF_RED)
        t[24][25] = T_DESK_WOOD
        t[24][28] = T_BENCH_WOOD
        self._place_building(t, 22, 28, 13, 18, T_TEMPLE, 28, [15, 16], T_ROOF_RED)
        t[24][15] = T_DESK_LARGE
        t[26][15] = T_BENCH_LONG
        zfill(t, 30, 37, 5, 15, T_GARDEN, w, h)
        zfill(t, 30, 37, 25, 35, T_COURTYARD, w, h)
        t[33][8] = T_FLOWER_RED
        t[33][12] = T_FLOWER_PINK
        t[33][28] = T_WELL
        t[33][32] = T_POND
        t[20][10] = T_SIGN
        t[20][30] = T_SIGN
        self.zones["luoyang"] = Map(id="luoyang", name="洛阳城", width=w, height=h, tiles=t, zone_type="city", description="大唐东都，繁华似锦")

        # ========== chang_an 长安城 (40x40) ==========
        w, h = 40, 40
        t = mk(w, h)
        wborder(t, w, h)
        zgate_h(t, 0, 19)
        zgate_h(t, h - 1, 19)
        zgate_v(t, 19, 0)
        zgate_v(t, 19, w - 1)
        zfill(t, 18, 22, 1, w - 1, T_STONE_ROAD, w, h)
        zfill(t, 1, h - 1, 18, 22, T_STONE_ROAD, w, h)
        self._place_building(t, 3, 10, 3, 12, T_TEMPLE, 10, [6, 7], T_ROOF_GOLD)
        t[5][5] = T_THRONE
        t[6][6] = T_PILLAR
        t[6][9] = T_PILLAR
        t[8][5] = T_BANNER
        t[8][10] = T_BANNER
        self._place_building(t, 3, 8, 22, 30, T_SHOP, 8, [25, 26], T_ROOF_BLUE)
        t[5][24] = T_COUNTER_WOOD
        t[5][28] = T_SHELF_WOOD
        self._place_building(t, 12, 17, 3, 10, T_INN, 17, [5, 6], T_ROOF_RED)
        t[14][5] = T_COUNTER_INN
        t[14][8] = T_BENCH_LONG
        self._place_building(t, 12, 17, 22, 30, T_SHOP, 12, [25, 26], T_ROOF_BLUE)
        t[14][24] = T_COUNTER_HERB
        t[14][28] = T_SHELF_HERB
        self._place_building(t, 22, 28, 3, 10, T_DWELL, 22, [5, 6], T_ROOF_RED)
        self._place_building(t, 22, 28, 22, 30, T_DWELL, 22, [25, 26], T_ROOF_RED)
        zfill(t, 30, 37, 5, 15, T_GARDEN, w, h)
        t[33][8] = T_FLOWER_RED
        t[33][12] = T_FLOWER_WHITE
        zfill(t, 30, 37, 25, 35, T_COURTYARD, w, h)
        t[33][28] = T_WELL
        t[20][10] = T_SIGN
        self.zones["chang_an"] = Map(id="chang_an", name="长安城", width=w, height=h, tiles=t, zone_type="city", description="大唐西京，皇城巍峨")

        # ========== lin_an 临安城 (35x35) ==========
        w, h = 35, 35
        t = mk(w, h)
        wborder(t, w, h)
        zgate_h(t, 0, 16)
        zgate_h(t, h - 1, 16)
        zgate_v(t, 16, 0)
        zgate_v(t, 16, w - 1)
        zfill(t, 15, 19, 1, w - 1, T_STONE_ROAD, w, h)
        zfill(t, 1, h - 1, 15, 19, T_STONE_ROAD, w, h)
        zfill(t, 5, 10, 3, 8, T_WATER, w, h)
        zfill(t, 10, 14, 3, 8, T_LAKE, w, h)
        t[8][5] = T_BRIDGE
        t[9][5] = T_BRIDGE
        t[12][5] = T_DOCK
        self._place_building(t, 3, 8, 20, 28, T_SHOP, 8, [23, 24], T_ROOF_BLUE)
        t[5][22] = T_COUNTER_WOOD
        t[5][26] = T_SHELF_WOOD
        self._place_building(t, 10, 15, 20, 28, T_INN, 15, [23, 24], T_ROOF_RED)
        t[12][22] = T_COUNTER_INN
        t[12][26] = T_BENCH_LONG
        self._place_building(t, 20, 26, 3, 10, T_DWELL, 20, [5, 6], T_ROOF_RED)
        self._place_building(t, 20, 26, 20, 28, T_TEMPLE, 20, [23, 24], T_ROOF_GOLD)
        t[22][23] = T_DESK_LARGE
        t[24][23] = T_ALTAR
        zfill(t, 27, 33, 5, 14, T_GARDEN, w, h)
        t[30][8] = T_FLOWER_PINK
        t[30][12] = T_FLOWER_SPECIAL1
        t[17][8] = T_SIGN
        self.zones["lin_an"] = Map(id="lin_an", name="临安城", width=w, height=h, tiles=t, zone_type="city", description="江南水乡，烟雨朦胧")

        # ========== jiangling 江陵城 (35x35) ==========
        w, h = 35, 35
        t = mk(w, h)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 16)
        zgate_h(t, h - 1, 16)
        zgate_v(t, 16, 0)
        zgate_v(t, 16, w - 1)
        zfill(t, 15, 19, 1, w - 1, T_STONE_ROAD, w, h)
        zfill(t, 1, h - 1, 15, 19, T_STONE_ROAD, w, h)
        self._place_building(t, 3, 10, 3, 12, T_TEMPLE, 10, [6, 7], T_ROOF_RED)
        t[5][5] = T_DESK_LARGE
        t[6][6] = T_BANNER
        t[6][9] = T_BANNER
        t[8][5] = T_SCULPTURE_LION
        t[8][10] = T_SCULPTURE_LION
        self._place_building(t, 3, 8, 20, 28, T_SHOP, 8, [23, 24], T_ROOF_BLUE)
        t[5][22] = T_COUNTER_WEAPON
        t[5][26] = T_SHELF_WOOD
        self._place_building(t, 12, 17, 3, 10, T_INN, 17, [5, 6], T_ROOF_RED)
        t[14][5] = T_COUNTER_INN
        self._place_building(t, 12, 17, 20, 28, T_SHOP, 12, [23, 24], T_ROOF_BLUE)
        t[14][22] = T_COUNTER_HERB
        self._place_building(t, 20, 26, 3, 10, T_DWELL, 20, [5, 6], T_ROOF_RED)
        self._place_building(t, 20, 26, 20, 28, T_DWELL, 20, [23, 24], T_ROOF_RED)
        zfill(t, 27, 33, 5, 14, T_COURTYARD, w, h)
        zfill(t, 27, 33, 20, 30, T_COURTYARD, w, h)
        t[30][8] = T_ANVIL
        t[30][25] = T_WELL
        self.zones["jiangling"] = Map(id="jiangling", name="江陵城", width=w, height=h, tiles=t, zone_type="city", description="军事重镇，固若金汤")

        # ========== chengdu 成都城 (35x35) ==========
        w, h = 35, 35
        t = mk(w, h)
        wborder(t, w, h)
        zgate_h(t, 0, 16)
        zgate_h(t, h - 1, 16)
        zgate_v(t, 16, 0)
        zgate_v(t, 16, w - 1)
        zfill(t, 15, 19, 1, w - 1, T_STONE_ROAD, w, h)
        zfill(t, 1, h - 1, 15, 19, T_STONE_ROAD, w, h)
        self._place_building(t, 3, 8, 3, 10, T_INN, 8, [5, 6], T_ROOF_RED)
        t[5][5] = T_COUNTER_INN
        t[5][8] = T_BENCH_LONG
        self._place_building(t, 3, 8, 20, 28, T_SHOP, 8, [23, 24], T_ROOF_BLUE)
        t[5][22] = T_COUNTER_HERB
        t[5][26] = T_SHELF_HERB
        self._place_building(t, 10, 16, 3, 10, T_SHOP, 16, [5, 6], T_ROOF_BLUE)
        t[12][5] = T_COUNTER_WOOD
        self._place_building(t, 10, 16, 20, 28, T_TEMPLE, 10, [23, 24], T_ROOF_GOLD)
        t[12][23] = T_DESK_LARGE
        t[14][23] = T_ALTAR
        self._place_building(t, 20, 26, 3, 10, T_DWELL, 20, [5, 6], T_ROOF_RED)
        self._place_building(t, 20, 26, 20, 28, T_DWELL, 20, [23, 24], T_ROOF_RED)
        zfill(t, 27, 33, 3, 14, T_GARDEN, w, h)
        t[30][5] = T_FLOWER_SPECIAL1
        t[30][10] = T_FLOWER_SPECIAL2
        zfill(t, 27, 33, 20, 30, T_RICE_PADDY, w, h)
        t[17][10] = T_SIGN
        self.zones["chengdu"] = Map(id="chengdu", name="成都城", width=w, height=h, tiles=t, zone_type="city", description="蜀地天府，物产丰饶")

        # ========== qinghe 清河镇 (20x20) ==========
        w, h = 20, 20
        t = mk(w, h)
        for c in range(w):
            t[0][c] = T_FENCE
            t[h - 1][c] = T_FENCE
        for r in range(h):
            t[r][0] = T_FENCE
            t[r][w - 1] = T_FENCE
        zgate_h(t, 0, 9)
        zgate_h(t, h - 1, 9)
        zfill(t, 9, 11, 1, w - 1, T_ROAD_DIRT, w, h)
        zfill(t, 1, h - 1, 9, 11, T_ROAD_DIRT, w, h)
        self._place_building(t, 2, 6, 2, 6, T_INN, 6, [3, 4], T_ROOF_RED)
        t[4][3] = T_COUNTER_INN
        self._place_building(t, 2, 6, 13, 18, T_SHOP, 6, [15], T_ROOF_BLUE)
        t[4][15] = T_COUNTER_WOOD
        self._place_building(t, 12, 16, 2, 6, T_DWELL, 12, [3, 4], T_ROOF_RED)
        self._place_building(t, 12, 16, 13, 18, T_DWELL, 12, [15], T_ROOF_BLUE)
        t[17][5] = T_WELL
        t[17][14] = T_TREE_WILLOW
        t[3][10] = T_SIGN
        self.zones["qinghe"] = Map(id="qinghe", name="清河镇", width=w, height=h, tiles=t, zone_type="town", description="洛阳北郊的小镇，连接城与野")

        # ========== fengxiang 凤翔镇 (20x20) ==========
        w, h = 20, 20
        t = mk(w, h)
        for c in range(w):
            t[0][c] = T_FENCE
            t[h - 1][c] = T_FENCE
        for r in range(h):
            t[r][0] = T_FENCE
            t[r][w - 1] = T_FENCE
        zgate_h(t, 0, 9)
        zgate_h(t, h - 1, 9)
        zfill(t, 9, 11, 1, w - 1, T_ROAD_DIRT, w, h)
        zfill(t, 1, h - 1, 9, 11, T_ROAD_DIRT, w, h)
        self._place_building(t, 2, 6, 2, 6, T_SHOP, 6, [3, 4], T_ROOF_BLUE)
        t[4][3] = T_COUNTER_HERB
        self._place_building(t, 2, 6, 13, 18, T_INN, 6, [15], T_ROOF_RED)
        t[4][15] = T_COUNTER_INN
        self._place_building(t, 12, 16, 2, 6, T_DWELL, 12, [3, 4], T_ROOF_RED)
        self._place_building(t, 12, 16, 13, 18, T_DWELL, 12, [15], T_ROOF_BLUE)
        t[17][5] = T_TREE_PINE
        t[17][14] = T_WELL
        self.zones["fengxiang"] = Map(id="fengxiang", name="凤翔镇", width=w, height=h, tiles=t, zone_type="town", description="长安南郊的小镇，通往中原")

        # ========== shuangliu 双流镇 (20x20) ==========
        w, h = 20, 20
        t = mk(w, h)
        for c in range(w):
            t[0][c] = T_FENCE
            t[h - 1][c] = T_FENCE
        for r in range(h):
            t[r][0] = T_FENCE
            t[r][w - 1] = T_FENCE
        zgate_v(t, 9, 0)
        zgate_v(t, 9, w - 1)
        zgate_h(t, 0, 9)
        zfill(t, 9, 11, 1, w - 1, T_ROAD_DIRT, w, h)
        zfill(t, 1, h - 1, 9, 11, T_ROAD_DIRT, w, h)
        self._place_building(t, 2, 6, 2, 6, T_SHOP, 6, [3, 4], T_ROOF_BLUE)
        t[4][3] = T_COUNTER_WOOD
        self._place_building(t, 2, 6, 13, 18, T_DWELL, 6, [15], T_ROOF_RED)
        self._place_building(t, 12, 16, 2, 6, T_INN, 12, [3, 4], T_ROOF_RED)
        t[14][3] = T_COUNTER_INN
        self._place_building(t, 12, 16, 13, 18, T_DWELL, 12, [15], T_ROOF_BLUE)
        t[17][10] = T_WELL
        self.zones["shuangliu"] = Map(id="shuangliu", name="双流镇", width=w, height=h, tiles=t, zone_type="town", description="成都附近的小镇，通往沙漠")

        # ========== yuhang 余杭镇 (20x20) ==========
        w, h = 20, 20
        t = mk(w, h)
        for c in range(w):
            t[0][c] = T_FENCE
            t[h - 1][c] = T_FENCE
        for r in range(h):
            t[r][0] = T_FENCE
            t[r][w - 1] = T_FENCE
        zgate_h(t, h - 1, 9)
        zgate_v(t, 9, 0)
        zfill(t, 9, 11, 1, w - 1, T_ROAD_DIRT, w, h)
        zfill(t, 1, h - 1, 9, 11, T_ROAD_DIRT, w, h)
        zfill(t, 2, 6, 2, 6, T_WATER, w, h)
        t[4][3] = T_BRIDGE
        t[5][3] = T_BRIDGE
        self._place_building(t, 2, 6, 13, 18, T_SHOP, 6, [15], T_ROOF_BLUE)
        t[4][15] = T_COUNTER_WOOD
        self._place_building(t, 12, 16, 2, 6, T_INN, 12, [3, 4], T_ROOF_RED)
        t[14][3] = T_COUNTER_INN
        self._place_building(t, 12, 16, 13, 18, T_DWELL, 12, [15], T_ROOF_BLUE)
        t[17][10] = T_WELL
        t[3][10] = T_TREE_WILLOW
        self.zones["yuhang"] = Map(id="yuhang", name="余杭镇", width=w, height=h, tiles=t, zone_type="town", description="临安北郊水乡小镇")

        # ========== bagua_sect 八卦门 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_DARK_GRASS)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_RED)
        t[6][7] = T_TRAINING
        t[6][17] = T_TRAINING
        t[8][11] = T_PILLAR
        t[8][13] = T_PILLAR
        t[9][8] = T_BANNER
        t[9][16] = T_BANNER
        t[10][11] = T_CARPET
        t[10][12] = T_CARPET
        t[11][7] = T_SHELF_BOOK
        t[11][17] = T_SHELF_BOOK
        t[13][9] = T_SCULPTURE_LION
        t[13][15] = T_SCULPTURE_LION
        t[14][11] = T_CHEST
        t[14][12] = T_CHEST
        t[16][7] = T_PLANT_DARK
        t[16][17] = T_PLANT_DARK
        t[18][11] = T_FLOWER_RED
        t[18][13] = T_FLOWER_RED
        for r in range(5, 20):
            t[r][5] = T_PLANT_GREEN
            t[r][20] = T_PLANT_GREEN
        self.zones["bagua_sect"] = Map(id="bagua_sect", name="八卦门", width=w, height=h, tiles=t, zone_type="sect", description="八卦门派，混元一气")

        # ========== flower_sect 百花谷 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_GARDEN)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        zfill(t, 8, 12, 7, 12, T_LAKE, w, h)
        t[10][9] = T_BRIDGE
        t[11][9] = T_BRIDGE
        self._place_building(t, 4, 10, 14, 22, T_TEMPLE, 4, [17], T_ROOF_BLUE)
        t[6][16] = T_FLOWER_SPECIAL1
        t[6][19] = T_FLOWER_SPECIAL2
        t[7][17] = T_DESK_WOOD
        t[8][17] = T_CHEST
        t[13][7] = T_FLOWER_SPECIAL1
        t[13][10] = T_FLOWER_SPECIAL2
        t[13][14] = T_FLOWER_SPECIAL1
        t[15][8] = T_FLOWER_RED
        t[15][11] = T_FLOWER_PINK
        t[15][16] = T_FLOWER_WHITE
        t[17][7] = T_FLOWER_SPECIAL2
        t[17][17] = T_FLOWER_SPECIAL1
        t[19][9] = T_FLOWER_RED
        t[19][15] = T_FLOWER_PINK
        t[21][11] = T_FLOWER_SPECIAL1
        t[21][13] = T_FLOWER_SPECIAL2
        for r in range(5, 22):
            t[r][5] = T_FLOWER_SPECIAL2
            t[r][20] = T_FLOWER_SPECIAL1
        self.zones["flower_sect"] = Map(id="flower_sect", name="百花谷", width=w, height=h, tiles=t, zone_type="sect", description="百花之谷，花飞剑法")

        # ========== honglian_sect 红莲教 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_DARK_GRASS)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_RED)
        t[6][7] = T_TRAINING
        t[6][17] = T_TRAINING
        t[8][11] = T_ALTAR
        t[8][12] = T_ALTAR
        t[9][9] = T_BANNER
        t[9][14] = T_BANNER
        for r in range(7, 11):
            t[r][11] = T_CARPET
            t[r][12] = T_CARPET
        t[11][11] = T_CHEST
        t[11][12] = T_CHEST
        t[13][7] = T_STONE_SMALL
        t[13][17] = T_STONE_SMALL
        t[15][9] = T_HILL_MEDIUM
        t[15][15] = T_TREE_WILLOW
        t[17][11] = T_FLOWER_RED
        t[17][12] = T_FLOWER_RED
        t[19][7] = T_TORCH
        t[19][17] = T_TORCH
        t[21][11] = T_PLANT_DARK
        t[21][13] = T_PLANT_DARK
        self.zones["honglian_sect"] = Map(id="honglian_sect", name="红莲教", width=w, height=h, tiles=t, zone_type="sect", description="红莲圣教，义字当先")

        # ========== naja_sect 那迦派 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_SAND)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_GOLD)
        t[6][7] = T_TRAINING
        t[6][17] = T_TRAINING
        t[7][9] = T_SCULPTURE_LION
        t[7][15] = T_SCULPTURE_LION
        t[8][11] = T_CHEST
        t[8][12] = T_CHEST
        for r in range(5, 11):
            t[r][11] = T_CARPET
            t[r][12] = T_CARPET
        t[10][9] = T_TORCH
        t[10][15] = T_TORCH
        t[11][7] = T_PILLAR
        t[11][17] = T_PILLAR
        t[13][9] = T_SHELF_BOOK
        t[13][15] = T_SHELF_BOOK
        t[15][7] = T_TREE_DEAD
        t[15][17] = T_TREE_DEAD
        t[17][11] = T_STONE_MEDIUM
        t[17][12] = T_STONE_MEDIUM
        t[19][9] = T_TREE_PINE
        t[19][15] = T_TREE_PINE
        t[21][11] = T_STONE_SMALL
        t[21][13] = T_STONE_SMALL
        self.zones["naja_sect"] = Map(id="naja_sect", name="那迦派", width=w, height=h, tiles=t, zone_type="sect", description="那迦隐派，忍术无双")

        # ========== taiji_sect 太极门 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_DARK_GRASS)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_GOLD)
        t[6][7] = T_ALTAR
        t[6][17] = T_SHELF_BOOK
        t[7][9] = T_BARS
        t[7][15] = T_BARS
        t[8][11] = T_CHEST
        t[8][12] = T_CHEST
        for r in range(5, 11):
            t[r][11] = T_CARPET
            t[r][12] = T_CARPET
        t[10][9] = T_DESK_LARGE
        t[10][15] = T_BENCH_STONE
        t[11][7] = T_TORCH
        t[11][17] = T_TORCH
        t[13][9] = T_PLANT_COLD
        t[13][15] = T_PLANT_COLD
        t[15][7] = T_BOTTLE
        t[15][17] = T_BOOK_OBJ
        t[17][9] = T_BARS
        t[17][15] = T_BARS
        t[19][11] = T_STONE_MEDIUM
        t[19][12] = T_STONE_MEDIUM
        t[21][7] = T_PLANT_COLD
        t[21][17] = T_PLANT_COLD
        self.zones["taiji_sect"] = Map(id="taiji_sect", name="太极门", width=w, height=h, tiles=t, zone_type="sect", description="太极道门，阴阳调和")

        # ========== xueshan_sect 雪山派 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_SNOW)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_RED)
        t[6][7] = T_TRAINING
        t[6][17] = T_TRAINING
        t[7][9] = T_BARS
        t[7][15] = T_BARS
        t[8][11] = T_CHEST
        t[8][12] = T_CHEST
        t[9][7] = T_PLANT_SNOW
        t[9][17] = T_PLANT_SNOW
        t[10][9] = T_WALL_STONE
        t[10][15] = T_WALL_STONE
        t[11][11] = T_SHELF_HERB
        t[11][12] = T_SHELF_HERB
        t[13][7] = T_TORCH
        t[13][17] = T_TORCH
        t[14][9] = T_STONE_MEDIUM
        t[14][15] = T_STONE_MEDIUM
        t[15][11] = T_FLOWER_WHITE
        t[15][12] = T_FLOWER_WHITE
        t[17][7] = T_HILL_SNOW
        t[17][17] = T_HILL_SNOW
        t[19][9] = T_STONE_SMALL
        t[19][15] = T_STONE_SMALL
        t[21][7] = T_ICE
        t[21][17] = T_ICE
        self.zones["xueshan_sect"] = Map(id="xueshan_sect", name="雪山派", width=w, height=h, tiles=t, zone_type="sect", description="雪山之巅，寒冰剑气")

        # ========== xiaoyao_sect 逍遥宫 (25x25) ==========
        w, h = 25, 25
        t = mk(w, h, T_DARK_GRASS)
        wborder(t, w, h, T_WALL_STONE)
        zgate_h(t, 0, 11)
        zfill(t, 1, h - 1, 11, 14, T_STONE_ROAD, w, h)
        self._place_building(t, 4, 12, 5, 20, T_TEMPLE, 4, [11, 12], T_ROOF_GOLD)
        t[6][7] = T_TRAINING
        t[6][17] = T_TRAINING
        t[7][9] = T_PILLAR
        t[7][15] = T_PILLAR
        t[8][11] = T_CARPET
        t[8][12] = T_CARPET
        t[9][7] = T_BANNER
        t[9][17] = T_BANNER
        t[10][11] = T_CHEST
        t[10][12] = T_CHEST
        t[11][9] = T_DESK_LARGE
        t[11][15] = T_BENCH_STONE
        zfill(t, 13, 16, 7, 12, T_POND, w, h)
        t[14][9] = T_BRIDGE
        t[15][9] = T_BRIDGE
        t[17][7] = T_BAMBOO
        t[17][17] = T_BAMBOO
        t[19][9] = T_TREE_WILLOW
        t[19][15] = T_TREE_WILLOW
        t[21][11] = T_FLOWER_SPECIAL1
        t[21][13] = T_FLOWER_SPECIAL2
        self.zones["xiaoyao_sect"] = Map(id="xiaoyao_sect", name="逍遥宫", width=w, height=h, tiles=t, zone_type="sect", description="逍遥仙宫，凌波微步")

        # ========== north_wild 北方荒野 (30x30) ==========
        w, h = 30, 30
        t = mk(w, h, T_FOREST)
        zfill(t, 0, 5, 0, w, T_FOREST, w, h)
        zfill(t, h - 5, h, 0, w, T_DARK_GRASS, w, h)
        zfill(t, 0, h, 0, 5, T_FOREST, w, h)
        zfill(t, 0, h, w - 5, w, T_FOREST, w, h)
        zfill(t, 8, 22, 8, 22, T_GRASS, w, h)
        zfill(t, 10, 20, 10, 20, T_DARK_GRASS, w, h)
        zfill(t, 13, 17, 13, 17, T_ROAD_DIRT, w, h)
        t[0][14] = T_GATE
        t[0][15] = T_GATE
        t[h - 1][14] = T_GATE
        t[h - 1][15] = T_GATE
        t[14][w - 1] = T_GATE
        t[15][w - 1] = T_GATE
        t[14][0] = T_GATE
        t[15][0] = T_GATE
        t[5][10] = T_TREE_PINE
        t[5][20] = T_TREE_PINE
        t[8][15] = T_HILL_MEDIUM
        t[12][8] = T_STONE_LARGE
        t[12][22] = T_STONE_MEDIUM
        t[18][10] = T_TREE_WILLOW
        t[18][20] = T_TREE_DEAD
        t[22][12] = T_HILL_SMALL
        t[22][18] = T_STONE_SMALL
        t[25][8] = T_TREE_PINE
        t[25][22] = T_TREE_PINE
        self.zones["north_wild"] = Map(id="north_wild", name="北方荒野", width=w, height=h, tiles=t, zone_type="wild", description="北方莽莽，林海雪原")

        # ========== central_wild 中原野外 (30x30) ==========
        w, h = 30, 30
        t = mk(w, h, T_GRASS)
        zfill(t, 0, 5, 0, w, T_DARK_GRASS, w, h)
        zfill(t, h - 5, h, 0, w, T_DARK_GRASS, w, h)
        zfill(t, 5, 25, 5, 25, T_GRASS, w, h)
        zfill(t, 10, 20, 10, 20, T_DARK_GRASS, w, h)
        zfill(t, 13, 17, 12, 18, T_ROAD_DIRT, w, h)
        t[0][14] = T_GATE
        t[0][15] = T_GATE
        t[h - 1][14] = T_GATE
        t[h - 1][15] = T_GATE
        t[14][0] = T_GATE
        t[15][0] = T_GATE
        t[14][w - 1] = T_GATE
        t[15][w - 1] = T_GATE
        t[5][8] = T_RUIN
        t[5][9] = T_RUIN
        t[8][20] = T_TREE_PINE
        t[10][5] = T_STONE_MEDIUM
        t[12][15] = T_HILL_MEDIUM
        t[15][10] = T_TREE_WILLOW
        t[15][20] = T_STONE_SMALL
        t[18][8] = T_RUIN
        t[18][9] = T_RUIN
        t[20][18] = T_HILL_SMALL
        t[22][12] = T_TREE_PINE
        t[25][10] = T_STONE_LARGE
        self.zones["central_wild"] = Map(id="central_wild", name="中原野外", width=w, height=h, tiles=t, zone_type="wild", description="中原大地，草原废墟")

        # ========== south_wild 南方密林 (30x30) ==========
        w, h = 30, 30
        t = mk(w, h, T_FOREST)
        zfill(t, 5, 25, 5, 25, T_FOREST, w, h)
        zfill(t, 10, 20, 10, 20, T_GRASS, w, h)
        zfill(t, 13, 17, 13, 17, T_ROAD_DIRT, w, h)
        zfill(t, 20, 25, 5, 12, T_SWAMP, w, h)
        t[0][14] = T_GATE
        t[0][15] = T_GATE
        t[h - 1][14] = T_GATE
        t[h - 1][15] = T_GATE
        t[14][0] = T_GATE
        t[15][0] = T_GATE
        t[14][w - 1] = T_GATE
        t[15][w - 1] = T_GATE
        t[5][8] = T_CAVE
        t[8][22] = T_TREE_WILLOW
        t[10][12] = T_MUSHROOM
        t[12][18] = T_STONE_MEDIUM
        t[15][10] = T_TREE_PINE
        t[15][20] = T_MUSHROOM
        t[18][8] = T_CAVE
        t[22][15] = T_SWAMP
        t[25][10] = T_TREE_DEAD
        t[25][20] = T_HILL_MEDIUM
        self.zones["south_wild"] = Map(id="south_wild", name="南方密林", width=w, height=h, tiles=t, zone_type="wild", description="南方瘴气，密林沼泽")

        # ========== west_wild 西部沙漠 (30x30) ==========
        w, h = 30, 30
        t = mk(w, h, T_SAND)
        zfill(t, 5, 25, 5, 25, T_SAND, w, h)
        zfill(t, 10, 20, 10, 20, T_SAND, w, h)
        zfill(t, 13, 17, 12, 18, T_ROAD_DIRT, w, h)
        zfill(t, 3, 8, 20, 27, T_LAKE, w, h)
        t[0][14] = T_GATE
        t[0][15] = T_GATE
        t[h - 1][14] = T_GATE
        t[h - 1][15] = T_GATE
        t[14][0] = T_GATE
        t[15][0] = T_GATE
        t[14][w - 1] = T_GATE
        t[15][w - 1] = T_GATE
        t[5][8] = T_HILL_LARGE
        t[8][22] = T_STONE_MEDIUM
        t[10][12] = T_HILL_MEDIUM
        t[12][18] = T_STONE_SMALL
        t[15][8] = T_STONE_SMALL
        t[15][22] = T_HILL_SMALL
        t[18][10] = T_STONE_LARGE
        t[20][20] = T_HILL_MEDIUM
        t[22][5] = T_STONE_MEDIUM
        t[25][15] = T_HILL_LARGE
        self.zones["west_wild"] = Map(id="west_wild", name="西部沙漠", width=w, height=h, tiles=t, zone_type="wild", description="西部大漠，黄沙漫天")

        # ========== 设置 transitions ==========
        z = self.zones

        def zpos(zone_id, row, col):
            zm = z[zone_id]
            return Position(zone_col_to_x(col), zone_row_to_y(row, zm.height))

        # luoyang: south→qinghe, west→central_wild
        z["luoyang"].exits["south"] = zpos("luoyang", 39, 20)
        z["luoyang"].transitions["south"] = ("qinghe", zpos("qinghe", 1, 10))
        z["luoyang"].exits["west"] = zpos("luoyang", 20, 0)
        z["luoyang"].transitions["west"] = ("central_wild", zpos("central_wild", 15, 1))

        # chang_an: south→fengxiang, east→central_wild
        z["chang_an"].exits["south"] = zpos("chang_an", 39, 20)
        z["chang_an"].transitions["south"] = ("fengxiang", zpos("fengxiang", 1, 10))
        z["chang_an"].exits["east"] = zpos("chang_an", 20, 39)
        z["chang_an"].transitions["east"] = ("central_wild", zpos("central_wild", 15, 28))

        # lin_an: north→yuhang, west→south_wild
        z["lin_an"].exits["north"] = zpos("lin_an", 0, 17)
        z["lin_an"].transitions["north"] = ("yuhang", zpos("yuhang", 18, 10))
        z["lin_an"].exits["west"] = zpos("lin_an", 17, 0)
        z["lin_an"].transitions["west"] = ("south_wild", zpos("south_wild", 15, 28))

        # jiangling: north→central_wild, south→south_wild
        z["jiangling"].exits["north"] = zpos("jiangling", 0, 17)
        z["jiangling"].transitions["north"] = ("central_wild", zpos("central_wild", 28, 15))
        z["jiangling"].exits["south"] = zpos("jiangling", 34, 17)
        z["jiangling"].transitions["south"] = ("south_wild", zpos("south_wild", 1, 15))

        # chengdu: east→shuangliu, north→west_wild
        z["chengdu"].exits["east"] = zpos("chengdu", 17, 34)
        z["chengdu"].transitions["east"] = ("shuangliu", zpos("shuangliu", 10, 1))
        z["chengdu"].exits["north"] = zpos("chengdu", 0, 17)
        z["chengdu"].transitions["north"] = ("west_wild", zpos("west_wild", 28, 15))

        # qinghe: north→luoyang, south→north_wild
        z["qinghe"].exits["north"] = zpos("qinghe", 0, 10)
        z["qinghe"].transitions["north"] = ("luoyang", zpos("luoyang", 38, 20))
        z["qinghe"].exits["south"] = zpos("qinghe", 19, 10)
        z["qinghe"].transitions["south"] = ("north_wild", zpos("north_wild", 1, 15))

        # fengxiang: north→chang_an, south→central_wild
        z["fengxiang"].exits["north"] = zpos("fengxiang", 0, 10)
        z["fengxiang"].transitions["north"] = ("chang_an", zpos("chang_an", 38, 20))
        z["fengxiang"].exits["south"] = zpos("fengxiang", 19, 10)
        z["fengxiang"].transitions["south"] = ("central_wild", zpos("central_wild", 1, 15))

        # shuangliu: west→chengdu, north→west_wild
        z["shuangliu"].exits["west"] = zpos("shuangliu", 10, 0)
        z["shuangliu"].transitions["west"] = ("chengdu", zpos("chengdu", 17, 33))
        z["shuangliu"].exits["north"] = zpos("shuangliu", 0, 10)
        z["shuangliu"].transitions["north"] = ("west_wild", zpos("west_wild", 28, 15))

        # yuhang: south→lin_an, west→south_wild
        z["yuhang"].exits["south"] = zpos("yuhang", 19, 10)
        z["yuhang"].transitions["south"] = ("lin_an", zpos("lin_an", 1, 17))
        z["yuhang"].exits["west"] = zpos("yuhang", 10, 0)
        z["yuhang"].transitions["west"] = ("south_wild", zpos("south_wild", 15, 28))

        # bagua_sect: gate→north_wild
        z["bagua_sect"].exits["gate"] = zpos("bagua_sect", 0, 12)
        z["bagua_sect"].transitions["gate"] = ("north_wild", zpos("north_wild", 28, 15))

        # flower_sect: gate→south_wild
        z["flower_sect"].exits["gate"] = zpos("flower_sect", 0, 12)
        z["flower_sect"].transitions["gate"] = ("south_wild", zpos("south_wild", 28, 15))

        # honglian_sect: gate→south_wild, back→central_wild
        z["honglian_sect"].exits["gate"] = zpos("honglian_sect", 0, 12)
        z["honglian_sect"].transitions["gate"] = ("south_wild", zpos("south_wild", 1, 15))
        z["honglian_sect"].exits["back"] = zpos("honglian_sect", 14, 12)
        z["honglian_sect"].transitions["back"] = ("central_wild", zpos("central_wild", 28, 15))

        # naja_sect: gate→north_wild
        z["naja_sect"].exits["gate"] = zpos("naja_sect", 0, 12)
        z["naja_sect"].transitions["gate"] = ("north_wild", zpos("north_wild", 15, 28))

        # taiji_sect: gate→west_wild
        z["taiji_sect"].exits["gate"] = zpos("taiji_sect", 0, 12)
        z["taiji_sect"].transitions["gate"] = ("west_wild", zpos("west_wild", 1, 15))

        # xueshan_sect: gate→west_wild
        z["xueshan_sect"].exits["gate"] = zpos("xueshan_sect", 0, 12)
        z["xueshan_sect"].transitions["gate"] = ("west_wild", zpos("west_wild", 15, 1))

        # xiaoyao_sect: gate→north_wild
        z["xiaoyao_sect"].exits["gate"] = zpos("xiaoyao_sect", 0, 12)
        z["xiaoyao_sect"].transitions["gate"] = ("north_wild", zpos("north_wild", 15, 1))

        # north_wild: south→qinghe, bagua→bagua_sect, naja→naja_sect, xiaoyao→xiaoyao_sect, central→central_wild
        z["north_wild"].exits["south"] = zpos("north_wild", 29, 15)
        z["north_wild"].transitions["south"] = ("qinghe", zpos("qinghe", 18, 10))
        z["north_wild"].exits["bagua"] = zpos("north_wild", 28, 15)
        z["north_wild"].transitions["bagua"] = ("bagua_sect", zpos("bagua_sect", 1, 12))
        z["north_wild"].exits["naja"] = zpos("north_wild", 15, 29)
        z["north_wild"].transitions["naja"] = ("naja_sect", zpos("naja_sect", 1, 12))
        z["north_wild"].exits["xiaoyao"] = zpos("north_wild", 15, 0)
        z["north_wild"].transitions["xiaoyao"] = ("xiaoyao_sect", zpos("xiaoyao_sect", 1, 12))
        z["north_wild"].exits["central"] = zpos("north_wild", 0, 15)
        z["north_wild"].transitions["central"] = ("central_wild", zpos("central_wild", 1, 15))

        # central_wild: north→fengxiang, east→luoyang, west→chang_an, south→jiangling, honglian→honglian_sect, north_wild→north_wild
        z["central_wild"].exits["north"] = zpos("central_wild", 0, 15)
        z["central_wild"].transitions["north"] = ("fengxiang", zpos("fengxiang", 18, 10))
        z["central_wild"].exits["east"] = zpos("central_wild", 15, 29)
        z["central_wild"].transitions["east"] = ("luoyang", zpos("luoyang", 20, 1))
        z["central_wild"].exits["west"] = zpos("central_wild", 15, 0)
        z["central_wild"].transitions["west"] = ("chang_an", zpos("chang_an", 20, 38))
        z["central_wild"].exits["south"] = zpos("central_wild", 29, 15)
        z["central_wild"].transitions["south"] = ("jiangling", zpos("jiangling", 1, 17))
        z["central_wild"].exits["honglian"] = zpos("central_wild", 29, 15)
        z["central_wild"].transitions["honglian"] = ("honglian_sect", zpos("honglian_sect", 1, 12))
        z["central_wild"].exits["north_wild"] = zpos("central_wild", 0, 15)
        z["central_wild"].transitions["north_wild"] = ("north_wild", zpos("north_wild", 28, 15))

        # south_wild: north→jiangling, east→lin_an, flower→flower_sect, honglian→honglian_sect, yuhang→yuhang
        z["south_wild"].exits["north"] = zpos("south_wild", 0, 15)
        z["south_wild"].transitions["north"] = ("jiangling", zpos("jiangling", 33, 17))
        z["south_wild"].exits["east"] = zpos("south_wild", 15, 29)
        z["south_wild"].transitions["east"] = ("lin_an", zpos("lin_an", 17, 1))
        z["south_wild"].exits["flower"] = zpos("south_wild", 0, 15)
        z["south_wild"].transitions["flower"] = ("flower_sect", zpos("flower_sect", 1, 12))
        z["south_wild"].exits["honglian"] = zpos("south_wild", 0, 15)
        z["south_wild"].transitions["honglian"] = ("honglian_sect", zpos("honglian_sect", 1, 12))
        z["south_wild"].exits["yuhang"] = zpos("south_wild", 15, 0)
        z["south_wild"].transitions["yuhang"] = ("yuhang", zpos("yuhang", 10, 19))

        # west_wild: south→chengdu, taiji→taiji_sect, xueshan→xueshan_sect, east→shuangliu
        z["west_wild"].exits["south"] = zpos("west_wild", 29, 15)
        z["west_wild"].transitions["south"] = ("chengdu", zpos("chengdu", 1, 17))
        z["west_wild"].exits["taiji"] = zpos("west_wild", 0, 15)
        z["west_wild"].transitions["taiji"] = ("taiji_sect", zpos("taiji_sect", 1, 12))
        z["west_wild"].exits["xueshan"] = zpos("west_wild", 15, 0)
        z["west_wild"].transitions["xueshan"] = ("xueshan_sect", zpos("xueshan_sect", 1, 12))
        z["west_wild"].exits["east"] = zpos("west_wild", 15, 29)
        z["west_wild"].transitions["east"] = ("shuangliu", zpos("shuangliu", 1, 10))

    def update(self, delta_time: float):
        if self.is_paused:
            return
        self.game_time += delta_time
        self.game_hour = (8 + int(self.game_time // 3600)) % 24
        if self.game_hour == 8 and self._prev_hour == 7:
            self.game_day += 1
            self.world_event_engine.reset_daily_check()
            self._check_world_events()
            self._check_expired_events()
        self._prev_hour = self.game_hour
        self.player.update_food_water(delta_time)
        self.player.play_time += delta_time
        self._update_npc_patrol(delta_time)
        self.perform_system.update_cooldowns(delta_time)
        self._update_inner_force_regen(delta_time)
        self._update_meditation(delta_time)

    def _check_world_events(self):
        flags = {f: True for f in getattr(self.player, '_story_flags', [])}
        triggered = self.world_event_engine.check_and_trigger(self.game_day, flags)
        for event in triggered:
            dispatch(EventType.WORLD_EVENT_TRIGGERED, event)

    def _check_expired_events(self):
        expired = self.world_event_engine.check_expired_phases(self.game_day)
        for event in expired:
            dispatch(EventType.WORLD_EVENT_PHASE_CHANGED, event)

    def _update_inner_force_regen(self, delta_time: float):
        if self.combat_system.is_in_combat():
            return
        regen = self.cultivation_system.get_inner_force_regen(self.player)
        if regen > 0 and self.player.mp < self.player.max_mp:
            self.player.mp = min(self.player.max_mp, self.player.mp + regen * delta_time * 0.1)

    def _update_meditation(self, delta_time: float):
        if self.combat_system.is_in_combat():
            return
        if self.player.mp < 10:
            return
        result = self.cultivation_system.update_meditation(self.player, delta_time)
        if result and result.get("leveled"):
            pass

    def _update_npc_patrol(self, delta_time):
        if self.current_map is None:
            return
        import random
        cam_x = self.player.position.x
        cam_y = self.player.position.y
        active_range = 1500
        for npc in self.npcs:
            dx = npc.position.x - cam_x
            dy = npc.position.y - cam_y
            if dx * dx + dy * dy > active_range * active_range:
                continue
            if not hasattr(npc, '_patrol_timer'):
                npc._patrol_timer = random.uniform(0, 5)
                npc._patrol_origin = Position(npc.position.x, npc.position.y)
                npc._patrol_target = None
                npc._patrol_state = "idle"
            npc._patrol_timer -= delta_time
            if npc._patrol_timer <= 0:
                npc._patrol_timer = self._get_npc_next_action_delay(npc)
                self._choose_npc_patrol_target(npc)
            if npc._patrol_target:
                dx = npc._patrol_target.x - npc.position.x
                dy = npc._patrol_target.y - npc.position.y
                dist = math.sqrt(dx * dx + dy * dy)
                speed = self._get_npc_speed(npc) * delta_time
                if dist > 2:
                    npc.position.x += (dx / dist) * speed
                    npc.position.y += (dy / dist) * speed
                else:
                    npc._patrol_target = None

    def _get_npc_next_action_delay(self, npc: NPC) -> float:
        if npc.npc_type == NpcType.ENEMY:
            return random.uniform(1.5, 4)
        elif npc.npc_type == NpcType.TRADER:
            return random.uniform(5, 12)
        elif npc.npc_type == NpcType.MASTER:
            return random.uniform(4, 10)
        else:
            return random.uniform(3, 8)

    def _get_npc_speed(self, npc: NPC) -> float:
        if npc.npc_type == NpcType.ENEMY:
            return 40
        elif npc.npc_type == NpcType.TRADER:
            return 20
        elif npc.npc_type == NpcType.MASTER:
            return 25
        else:
            return 30

    def _choose_npc_patrol_target(self, npc: NPC):
        ox, oy = npc._patrol_origin.x, npc._patrol_origin.y
        if npc.npc_type == NpcType.ENEMY:
            radius = 80
            angle = random.uniform(0, 2 * math.pi)
            dist = random.uniform(20, radius)
        elif npc.npc_type == NpcType.TRADER:
            radius = 25
            angle = random.uniform(0, 2 * math.pi)
            dist = random.uniform(0, radius)
        elif npc.npc_type == NpcType.MASTER:
            radius = 20
            angle = random.uniform(0, 2 * math.pi)
            dist = random.uniform(0, radius)
        else:
            radius = 40
            angle = random.uniform(0, 2 * math.pi)
            dist = random.uniform(0, radius)
        nx = ox + math.cos(angle) * dist
        ny = oy + math.sin(angle) * dist
        cmap = self.current_map
        if cmap is None:
            return
        col = int(nx // TS)
        row = cmap.height - 1 - int(ny // TS)
        if 0 <= row < cmap.height and 0 <= col < cmap.width:
            if cmap.tiles[row][col] in WALKABLE:
                npc._patrol_target = Position(nx, ny)

    def use_item(self, player: Player, item_id: str) -> str:
        item = self.items.get(item_id)
        if not item:
            return "没有这个物品"
        if item_id not in player.inventory or player.inventory[item_id] <= 0:
            return f"你没有{item.name}"
        if item.type != ItemType.CONSUMABLE:
            return f"{item.name}不能使用"
        result = player.use_item(item)
        return result if result else f"使用了{item.name}"

    def get_npc_by_id(self, npc_id: int) -> Optional[NPC]:
        return next((npc for npc in self.npcs if npc.id == npc_id), None)

    def get_npc_by_name(self, name: str) -> Optional[NPC]:
        return next((npc for npc in self.npcs if npc.name == name), None)

    def get_item_by_id(self, item_id: str) -> Optional[Item]:
        return self.items.get(item_id)

    def get_nearby_npc(self, position: Position, radius: float = 150) -> Optional[NPC]:
        nearest = None
        nearest_dist = radius
        for npc in self.npcs:
            if npc.npc_type.value == "enemy":
                continue
            dist = npc.position.distance_to(position)
            if dist <= nearest_dist:
                nearest = npc
                nearest_dist = dist
        return nearest

    def get_nearby_enemy(self, position: Position, radius: float = 150) -> Optional[NPC]:
        nearest = None
        nearest_dist = radius
        for npc in self.npcs:
            if npc.npc_type.value != "enemy":
                continue
            if hasattr(npc, '_death_time') and npc._death_time > 0:
                if self.game_time - npc._death_time < 120:
                    continue
                npc.hp = npc.max_hp
                npc.mp = npc.max_mp
                npc._death_time = 0
            if npc.hp <= 0:
                continue
            dist = npc.position.distance_to(position)
            if dist <= nearest_dist:
                nearest = npc
                nearest_dist = dist
        return nearest

    def start_combat(self, player: Player, enemy: NPC) -> str:
        combat = self.combat_system.start_combat(player, enemy)
        if combat:
            return f"你与 {enemy.name} 展开了激战！"
        return "战斗无法开始"

    def talk_to_npc(self, player: Player, npc: NPC, player_input: str = "") -> Dict:
        brain_mgr = get_npc_brain_manager()
        brain = brain_mgr.get_brain(npc)
        result = brain.talk(player, player_input, self.game_hour)

        tracker = get_behavior_tracker()
        tracker.record_dialogue(player.name, npc.name, npc.faction)

        dispatch(EventType.PLAYER_TALKED_TO_NPC, {
            "npc_name": npc.name,
            "npc_id": npc.id,
            "dialogue_state": result.get("state", ""),
        })

        encounter_mgr = get_encounter_manager()
        encounter = encounter_mgr.check_encounter(player, npc, self.game_time)
        if encounter:
            result["encounter"] = encounter

        return result

    def request_npc_quest(self, player: Player, npc: NPC) -> Optional[Dict]:
        brain_mgr = get_npc_brain_manager()
        brain = brain_mgr.get_brain(npc)
        tracker = get_behavior_tracker()
        behavior = tracker.get_behavior_summary(player.name)
        return brain.request_quest(player, behavior)

    def check_encounter(self, player: Player, npc: NPC = None) -> Optional[Encounter]:
        encounter_mgr = get_encounter_manager()
        return encounter_mgr.check_encounter(player, npc, self.game_time)

    def accept_encounter(self, player: Player, encounter: Encounter) -> str:
        encounter_mgr = get_encounter_manager()
        return encounter_mgr.accept_encounter(player, encounter)

    def update_time(self):
        pass

    def can_walk(self, wx, wy):
        if self.current_map is None:
            return False
        cmap = self.current_map
        col = int(wx // TS)
        row = cmap.height - 1 - int(wy // TS)
        if col < 0 or col >= cmap.width or row < 0 or row >= cmap.height:
            return False
        tid = cmap.tiles[row][col]
        return tid in WALKABLE

    def buy_item(self, player: Player, item_id: str, seller_npc: NPC = None) -> Dict:
        item = self.items.get(item_id)
        if not item:
            return {"success": False, "message": "物品不存在"}

        seller_faction = seller_npc.faction if seller_npc else Faction.NONE
        rep_modifier = self.reputation_system.get_modifier(player, seller_faction, "shop_discount")

        result = self.economy_system.buy_item(player, item, seller_faction, rep_modifier)
        return result

    def sell_item(self, player: Player, item_id: str, buyer_npc: NPC = None) -> Dict:
        if item_id not in player.inventory or player.inventory[item_id] <= 0:
            return {"success": False, "message": "你没有这个物品"}

        item = self.items.get(item_id)
        if not item:
            return {"success": False, "message": "物品信息不存在"}

        buyer_faction = buyer_npc.faction if buyer_npc else Faction.NONE
        rep_modifier = self.reputation_system.get_modifier(player, buyer_faction, "sell_markup")

        result = self.economy_system.sell_item(player, item, buyer_faction, rep_modifier)
        return result

    def equip_item(self, player: Player, item_id: str) -> Dict:
        return self.equipment_system.equip_item(player, item_id, self.items)

    def unequip_item(self, player: Player, slot: str) -> Dict:
        return self.equipment_system.unequip_item(player, slot, self.items)

    def train_skill(self, player: Player, skill_id: str, master_npc: NPC) -> Dict:
        return self.cultivation_system.train_with_master(player, skill_id, master_npc)

    def attempt_breakthrough(self, player: Player, skill_id: str, use_pot: int = 0) -> Dict:
        return self.cultivation_system.attempt_breakthrough(player, skill_id, use_pot)

    def use_pot_for_skill(self, player: Player, skill_id: str, pot_amount: int) -> Dict:
        return self.cultivation_system.use_pot_for_skill(player, skill_id, pot_amount)

    def join_faction(self, player: Player, faction: Faction) -> Dict:
        if player.faction != Faction.NONE:
            return {"success": False, "message": f"你已是{FACTION_NAMES.get(player.faction, '未知门派')}弟子"}

        if not self.reputation_system.can_join_faction(player, faction):
            return {"success": False, "message": f"你在{FACTION_NAMES.get(faction, '未知门派')}的声望不足，无法加入"}

        player.faction = faction
        self.reputation_system.on_join_faction(player, faction)

        faction_skills = FACTION_SKILLS.get(faction, [])
        for skill_id in faction_skills:
            if not any(s.id == skill_id for s in player.skills):
                if skill_id in ALL_SKILLS:
                    new_skill = Skill(
                        id=ALL_SKILLS[skill_id].id,
                        name=ALL_SKILLS[skill_id].name,
                        type=ALL_SKILLS[skill_id].type,
                        level=1, exp=0,
                        damage=ALL_SKILLS[skill_id].damage,
                        accuracy=ALL_SKILLS[skill_id].accuracy,
                    )
                    player.skills.append(new_skill)

        dispatch(EventType.PLAYER_JOINED_FACTION, {
            "faction": faction.value,
            "faction_name": FACTION_NAMES.get(faction, '未知门派'),
        })

        return {
            "success": True,
            "message": f"你加入了{FACTION_NAMES.get(faction, '未知门派')}！习得了门派武功",
            "faction": faction.value,
            "new_skills": faction_skills,
        }

    def betray_faction(self, player: Player) -> Dict:
        if player.faction == Faction.NONE:
            return {"success": False, "message": "你没有门派"}

        old_faction = player.faction
        self.reputation_system.on_betray_faction(player, old_faction)
        player.faction = Faction.NONE

        dispatch(EventType.PLAYER_BETRAYED_FACTION, {
            "old_faction": old_faction.value,
            "old_faction_name": FACTION_NAMES.get(old_faction, '未知门派'),
        })

        return {
            "success": True,
            "message": f"你背叛了{FACTION_NAMES.get(old_faction, '未知门派')}！声望大幅下降",
        }

    def inn_rest(self, player: Player) -> Dict:
        return self.economy_system.inn_rest(player)

    def donate_to_faction(self, player: Player, faction: Faction, amount: int) -> Dict:
        result = self.economy_system.donate_to_faction(player, faction, amount)
        if result["success"]:
            rep_gain = result["rep_gain"]
            self.reputation_system.add_reputation(player, faction, rep_gain)
        return result

    def get_player_status(self, player: Player) -> Dict:
        rep_info = self.reputation_system.get_all_reputations(player)
        cult_info = self.cultivation_system.get_player_cultivation_info(player)
        equip_stats = self.equipment_system.get_equipment_stats(player, self.items)

        return {
            "reputation": rep_info,
            "cultivation": cult_info,
            "equipment": equip_stats,
            "money": player.money,
            "level": player.level,
            "faction": FACTION_NAMES.get(player.faction, '未知门派'),
            "kills": player.total_kills,
            "deaths": player.total_deaths,
            "play_time": player.play_time,
        }

    def get_romance_storylines(self) -> List[Dict]:
        storylines = self.script_db.get_romance_storylines()
        return [{"id": s.id, "title": s.title, "character": s.character,
                 "description": s.description, "prerequisites": s.prerequisites}
                for s in storylines]

    def get_cross_faction_storylines(self) -> List[Dict]:
        storylines = self.script_db.get_cross_faction_storylines()
        return [{"id": s.id, "title": s.title, "factions": s.factions,
                 "description": s.description, "prerequisites": s.prerequisites}
                for s in storylines]

    def get_prequel_storylines(self) -> List[Dict]:
        storylines = self.script_db.get_prequel_storylines()
        return [{"id": s.id, "title": s.title, "description": s.description,
                 "prerequisites": s.prerequisites}
                for s in storylines]

    def get_dark_storylines(self) -> List[Dict]:
        storylines = self.script_db.get_dark_storylines()
        return [{"id": s.id, "title": s.title, "description": s.description,
                 "prerequisites": s.prerequisites}
                for s in storylines]

    def get_active_world_events(self) -> List[Dict]:
        return self.world_event_engine.get_active_events()

    def get_storyline_node(self, storyline_id: str, node_id: str) -> Optional[Dict]:
        storyline = self.script_db.get_storyline(storyline_id)
        if not storyline:
            return None
        node = storyline.nodes.get(node_id)
        return serialize_node(node) if node else None

    def advance_storyline(self, storyline_id: str, current_node_id: str, player: Player) -> Dict:
        storyline = self.script_db.get_storyline(storyline_id)
        if not storyline:
            return {"success": False, "message": "剧情不存在"}
        current_node = storyline.nodes.get(current_node_id)
        if not current_node:
            return {"success": False, "message": "当前节点不存在"}

        apply_story_flags(player, current_node.set_flags)
        apply_reward(player, current_node.reward)

        next_id = current_node.next
        if not next_id:
            event_type = STORYLINE_TYPE_EVENT_MAP.get(
                storyline.storyline_type, EventType.STORY_NODE_ENTERED
            )
            dispatch(event_type, {"storyline_id": storyline_id, "node_id": current_node_id})
            return {"success": True, "message": "剧情完成", "completed": True}

        next_node = storyline.nodes.get(next_id)
        return {
            "success": True,
            "message": "剧情推进",
            "next_node_id": next_id,
            "next_node": serialize_node(next_node) if next_node else None,
        }

    def make_storyline_choice(self, storyline_id: str, current_node_id: str,
                              choice_index: int, player: Player) -> Dict:
        storyline = self.script_db.get_storyline(storyline_id)
        if not storyline:
            return {"success": False, "message": "剧情不存在"}
        current_node = storyline.nodes.get(current_node_id)
        if not current_node or current_node.node_type != "choice":
            return {"success": False, "message": "当前节点无法选择"}
        if choice_index < 0 or choice_index >= len(current_node.choices):
            return {"success": False, "message": "无效选择"}

        choice = current_node.choices[choice_index]
        if "morality_change" in choice:
            player.daode += choice["morality_change"]

        apply_story_flags(player, current_node.set_flags)

        next_id = choice.get("next", "")
        if not next_id:
            return {"success": True, "message": "选择完成", "completed": True}

        next_node = storyline.nodes.get(next_id)
        return {
            "success": True,
            "message": "选择已做出",
            "next_node_id": next_id,
            "next_node": serialize_node(next_node) if next_node else None,
        }

    def advance_world_event(self, event_id: str, player: Player) -> Dict:
        node = self.world_event_engine.get_event_node(event_id)
        if not node:
            return {"success": False, "message": "事件不存在或已结束"}
        next_phase = node.next
        return self.world_event_engine.advance_event(event_id, next_phase, self.game_day, player)

    def make_world_event_choice(self, event_id: str, choice_index: int, player: Player) -> Dict:
        return self.world_event_engine.make_choice(event_id, choice_index, self.game_day, player)
