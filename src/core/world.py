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


class GameWorld:
    def __init__(self):
        self.player: Player = Player()
        self.current_map: Optional[Map] = None
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
        self._init_default_map()
        self._init_all_npcs()

        self.combat_system.set_performs_db(PERFORMS)
        self.combat_system.set_items_db(self.items)

        self.player.position = Position(col_to_x(25), row_to_y(31))
        self._init_player_skills()

    def set_player(self, player: Player):
        self.player = player
        self.player.position = Position(col_to_x(25), row_to_y(31))
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

    def _init_default_map(self):
        tiles = [[T_GRASS for _ in range(MAP_W)] for _ in range(MAP_H)]

        def road_h(row, c1, c2, width=2):
            for r in range(row, row + width):
                if 0 <= r < MAP_H:
                    for c in range(c1, c2):
                        if 0 <= c < MAP_W:
                            tiles[r][c] = T_STONE_ROAD

        def road_v(col, r1, r2, width=2):
            for c in range(col, col + width):
                if 0 <= c < MAP_W:
                    for r in range(r1, r2):
                        if 0 <= r < MAP_H:
                            tiles[r][c] = T_STONE_ROAD

        def dirt_road_h(row, c1, c2, width=2):
            for r in range(row, row + width):
                if 0 <= r < MAP_H:
                    for c in range(c1, c2):
                        if 0 <= c < MAP_W:
                            tiles[r][c] = T_ROAD_DIRT

        def dirt_road_v(col, r1, r2, width=2):
            for c in range(col, col + width):
                if 0 <= c < MAP_W:
                    for r in range(r1, r2):
                        if 0 <= r < MAP_H:
                            tiles[r][c] = T_ROAD_DIRT

        def fill(r1, r2, c1, c2, tid):
            for r in range(r1, r2):
                for c in range(c1, c2):
                    if 0 <= r < MAP_H and 0 <= c < MAP_W:
                        tiles[r][c] = tid

        def place_shop(r1, r2, c1, c2, counter_tid, entrance_row, entrance_cols, roof=T_ROOF_BLUE):
            self._place_building(tiles, r1, r2, c1, c2, T_SHOP, entrance_row, entrance_cols, roof)
            mid_r = (r1 + r2) // 2
            mid_c = (c1 + c2) // 2
            tiles[mid_r][mid_c] = counter_tid
            if mid_r + 1 <= r2 - 1:
                tiles[mid_r + 1][mid_c] = counter_tid

        def place_house(r1, r2, c1, c2, entrance_row, entrance_cols, roof=T_ROOF_RED):
            self._place_building(tiles, r1, r2, c1, c2, T_INN, entrance_row, entrance_cols, roof)
            mid_r = (r1 + r2) // 2
            mid_c = (c1 + c2) // 2
            tiles[mid_r][c1 + 1] = T_DESK_WOOD
            tiles[mid_r][c2 - 1] = T_BENCH_WOOD

        # ===== 西侧河流 =====
        fill(0, MAP_H, 0, 3, T_WATER)
        fill(25, 40, 3, 5, T_LAKE)

        # ===== 平安镇 (col 5-48, row 10-50) =====

        # --- 中央大街 (东西向) ---
        road_h(30, 5, 48, 3)
        tiles[31][25] = T_WELL
        tiles[30][10] = T_SIGN
        tiles[30][44] = T_SIGN
        tiles[31][47] = T_SIGN

        # --- 市场街 / Road1 (南北向, col 20-25) ---
        road_v(22, 11, 30, 4)

        # 杂货铺 (Shop1)
        place_shop(12, 16, 13, 19, T_COUNTER_WOOD, 16, [16], T_ROOF_BLUE)
        tiles[14][15] = T_SHELF_WOOD
        tiles[14][17] = T_SHELF_WOOD

        # 药铺 (Shop2)
        place_shop(12, 16, 27, 33, T_COUNTER_HERB, 16, [30], T_ROOF_BLUE)
        tiles[14][28] = T_SHELF_HERB
        tiles[14][32] = T_SHELF_HERB

        # 兵器铺 (Shop3)
        place_shop(17, 21, 13, 19, T_COUNTER_WEAPON, 21, [16], T_ROOF_RED)
        tiles[19][15] = T_SHELF_WOOD
        tiles[19][17] = T_SHELF_WOOD

        # 钱庄 (Shop4)
        place_shop(17, 21, 27, 33, T_COUNTER_MONEY, 21, [30], T_ROOF_GOLD)
        tiles[19][28] = T_SHELF_WOOD
        tiles[19][32] = T_SHELF_WOOD

        # 客栈 (Shop5)
        place_shop(22, 27, 13, 19, T_COUNTER_INN, 27, [15, 16], T_ROOF_RED)
        tiles[24][14] = T_BENCH_LONG
        tiles[24][17] = T_BENCH_LONG
        tiles[25][15] = T_DESK_LARGE
        tiles[25][16] = T_DESK_LARGE

        # 民居2 (Dwell2)
        self._place_building(tiles, 22, 27, 27, 33, T_DWELL, 27, [30], T_ROOF_BLUE)
        tiles[24][29] = T_DESK_WOOD
        tiles[24][31] = T_BENCH_WOOD

        # 市场街水平连接路 (建筑入口 → 市场街)
        road_h(16, 16, 22, 1)
        road_h(16, 25, 30, 1)
        road_h(21, 16, 22, 1)
        road_h(21, 25, 30, 1)
        road_h(27, 15, 22, 1)
        road_h(27, 25, 30, 1)

        # 市场街装饰柱
        for r in range(12, 29, 3):
            tiles[r][21] = T_PILLAR
            tiles[r][25] = T_PILLAR

        # --- 衙门街 / Road2 (南北向, col 38-42) ---
        road_v(40, 22, 30, 3)
        self._place_building(tiles, 22, 28, 36, 44, T_TEMPLE, 28, [39, 40], T_ROOF_RED)
        tiles[24][38] = T_DESK_LARGE
        tiles[24][42] = T_DESK_LARGE
        tiles[25][37] = T_SHELF_HERB
        tiles[25][43] = T_SHELF_HERB
        tiles[26][40] = T_BENCH_LONG
        road_h(28, 36, 40, 1)
        road_h(28, 42, 44, 1)

        # --- 民居区 (西侧) ---
        # House1 (阿青/卖豆腐)
        place_house(11, 15, 5, 11, 15, [8], T_ROOF_RED)
        tiles[12][6] = T_FLOWER_RED
        tiles[12][10] = T_FLOWER_RED
        tiles[13][8] = T_BENCH_WOOD
        road_h(15, 8, 22, 1)

        # House1A (裁缝铺)
        place_house(16, 20, 5, 11, 20, [8], T_ROOF_BLUE)
        tiles[17][6] = T_FLOWER_PINK
        tiles[17][10] = T_FLOWER_PINK
        tiles[18][8] = T_BENCH_WOOD
        road_h(20, 8, 22, 1)

        # House1B (老婆婆/小童)
        place_house(21, 25, 5, 11, 25, [8], T_ROOF_RED)
        tiles[22][6] = T_BENCH_WOOD
        tiles[22][10] = T_DESK_WOOD
        tiles[23][8] = T_WALL_WOOD
        road_h(25, 8, 22, 1)

        # House2 (客栈后院)
        self._place_building(tiles, 11, 15, 34, 40, T_INN, 15, [37], T_ROOF_RED)
        tiles[12][36] = T_BED
        tiles[12][38] = T_SHELF_WOOD
        tiles[13][37] = T_CHEST
        road_h(15, 25, 37, 1)

        # House2A (妇人/村长)
        place_house(16, 20, 34, 40, 20, [37], T_ROOF_BLUE)
        tiles[18][36] = T_DESK_WOOD
        tiles[18][38] = T_BENCH_WOOD
        road_h(20, 25, 37, 1)

        # --- 武馆 ---
        self._place_building(tiles, 24, 29, 5, 13, T_TEMPLE, 24, [8, 9], T_ROOF_GOLD)
        tiles[25][7] = T_SCULPTURE_WEAPON
        tiles[25][11] = T_SCULPTURE_WEAPON
        tiles[26][9] = T_STAGE
        tiles[27][7] = T_DESK_WOOD
        tiles[27][11] = T_BENCH_LONG
        tiles[28][9] = T_CARPET
        fill(27, 29, 6, 12, T_CARPET)
        road_h(24, 8, 22, 1)

        # --- 花园 ---
        fill(23, 26, 5, 12, T_GARDEN)
        tiles[24][6] = T_FLOWER_RED
        tiles[24][8] = T_FLOWER_PINK
        tiles[24][10] = T_FLOWER_WHITE
        tiles[25][7] = T_FLOWER_SPECIAL1
        tiles[25][9] = T_FLOWER_SPECIAL2
        tiles[23][7] = T_PLANT_GREEN
        tiles[23][10] = T_PLANT_GREEN

        # --- 码头 ---
        fill(28, 35, 3, 6, T_DOCK)
        tiles[31][3] = T_BRIDGE
        tiles[31][4] = T_BRIDGE
        tiles[32][3] = T_BRIDGE
        tiles[32][4] = T_BRIDGE

        # --- 南部民居 ---
        place_house(35, 39, 6, 12, 35, [9], T_ROOF_RED)
        place_house(35, 39, 14, 20, 35, [17], T_ROOF_BLUE)
        place_house(35, 39, 22, 28, 35, [25], T_ROOF_RED)
        road_h(34, 6, 29, 2)
        road_v(9, 34, 39, 2)
        road_v(17, 34, 39, 2)
        road_v(25, 34, 39, 2)

        # --- 南部农田 ---
        fill(42, 50, 6, 16, T_RICE_PADDY)
        fill(42, 50, 16, 26, T_DARK_GRASS)
        tiles[46][21] = T_POND
        road_v(23, 39, 50, 2)

        # --- 铁匠铺 ---
        self._place_building(tiles, 35, 39, 30, 35, T_SHOP, 35, [32], T_ROOF_BLUE)
        tiles[37][32] = T_ANVIL
        tiles[37][33] = T_SHELF_WOOD
        road_h(35, 25, 32, 1)

        # --- 平一指医馆 ---
        self._place_building(tiles, 35, 39, 37, 43, T_SHOP, 35, [40], T_ROOF_BLUE)
        tiles[37][39] = T_COUNTER_HERB
        tiles[37][41] = T_SHELF_HERB
        road_h(35, 40, 44, 1)

        # ===== 连接道路：平安镇 → 各门派 =====
        # 东西向主路
        road_h(30, 48, 55, 3)

        # 通往八卦门/花间派
        road_v(53, 8, 18, 3)
        road_h(10, 53, 60, 3)
        road_v(53, 18, 28, 3)
        road_h(20, 53, 60, 3)

        # 通往红莲教
        road_v(53, 30, 40, 3)
        road_h(36, 53, 60, 3)

        # 通往那迦/太极
        road_h(30, 55, 72, 3)
        road_v(70, 8, 18, 3)
        road_h(10, 70, 76, 3)
        road_v(70, 18, 30, 3)
        road_h(20, 70, 76, 3)

        # 通往雪山
        road_v(70, 35, 50, 3)
        road_h(40, 70, 76, 3)

        # ===== 小径 (Path) 装饰 =====
        # Path2 区域 (col 48-54, row 18-28) - 装饰在道路两侧
        tiles[18][49] = T_TREE_WILLOW
        tiles[19][55] = T_TREE_WILLOW
        tiles[21][49] = T_PLANT_GREEN
        tiles[22][55] = T_PLANT_GREEN
        tiles[24][49] = T_TREE_PINE
        tiles[25][55] = T_TREE_PINE
        tiles[27][49] = T_BRICK
        for r in range(19, 28):
            tiles[r][48] = T_PLANT_GREEN

        # Path1 区域 (col 48-54, row 30-40) - 装饰在道路两侧
        tiles[30][49] = T_TREE_PINE
        tiles[31][55] = T_TREE_PINE
        tiles[33][49] = T_STONE_MEDIUM
        tiles[34][55] = T_STONE_MEDIUM
        tiles[36][49] = T_TREE_WILLOW
        tiles[37][55] = T_TREE_WILLOW
        tiles[39][49] = T_PLANT_GREEN
        tiles[39][55] = T_STONE_SMALL

        # Path3 区域 (col 54-60, row 30-40) - 装饰在道路两侧
        tiles[31][56] = T_STONE_MEDIUM
        tiles[32][56] = T_STONE_MEDIUM
        tiles[34][56] = T_PLANT_GREEN
        tiles[35][56] = T_PLANT_GREEN
        tiles[37][56] = T_PLANT_GREEN
        tiles[38][56] = T_PLANT_GREEN

        # Path5 区域 (col 48-54, row 40-50) - 装饰在道路两侧
        tiles[41][49] = T_TREE_WILLOW
        tiles[42][55] = T_HILL_MEDIUM
        tiles[44][49] = T_TREE_PINE
        tiles[45][55] = T_PLANT_GREEN
        tiles[47][49] = T_PLANT_GREEN
        tiles[48][55] = T_STONE_SMALL

        # Path6 区域 (col 54-60, row 8-18) → 八卦门 - 装饰在道路两侧
        for r in range(9, 17):
            tiles[r][54] = T_PLANT_GREEN
            tiles[r][59] = T_PLANT_GREEN
        tiles[9][56] = T_TREE_PINE
        tiles[13][56] = T_TREE_PINE
        tiles[11][56] = T_PLANT_DARK

        # Path7 区域 (col 54-60, row 40-50) → 花间派 - 装饰在道路两侧
        tiles[41][55] = T_PLANT_GREEN
        tiles[42][55] = T_PLANT_GREEN
        tiles[43][55] = T_PLANT_GREEN
        tiles[44][55] = T_PLANT_GREEN
        tiles[45][55] = T_PLANT_GREEN
        tiles[46][55] = T_PLANT_GREEN
        tiles[47][55] = T_PLANT_GREEN
        tiles[48][55] = T_PLANT_GREEN

        # Path4 区域 (col 66-72, row 8-18) → 那迦派 - 湖泊移到道路外
        for r in range(9, 17):
            tiles[r][66] = T_PLANT_GREEN
        tiles[10][68] = T_PLANT_GREEN
        tiles[12][69] = T_PLANT_GREEN
        tiles[14][67] = T_PLANT_GREEN
        fill(10, 14, 87, 92, T_LAKE)

        # Path9 区域 (col 70-76, row 40-50) → 雪山派
        tiles[41][72] = T_STONE_MEDIUM
        tiles[42][74] = T_STONE_MEDIUM
        tiles[43][71] = T_HILL_SNOW
        tiles[44][73] = T_PLANT_SNOW
        tiles[45][72] = T_PLANT_SNOW
        tiles[46][74] = T_PLANT_SNOW
        tiles[47][71] = T_PLANT_SNOW
        tiles[48][73] = T_HILL_SNOW

        # ===== 八卦门 (col 60-70, row 3-16) =====
        fill(3, 17, 56, 72, T_DARK_GRASS)
        self._place_building(tiles, 3, 12, 61, 69, T_TEMPLE, 3, [64, 65], T_ROOF_RED)
        tiles[5][62] = T_TRAINING
        tiles[5][68] = T_TRAINING
        tiles[6][64] = T_PILLAR
        tiles[6][65] = T_PILLAR
        tiles[7][62] = T_SHELF_BOOK
        tiles[7][68] = T_SHELF_BOOK
        tiles[8][64] = T_CHEST
        tiles[9][62] = T_PLANT_DARK
        tiles[9][68] = T_PLANT_DARK
        tiles[10][63] = T_BANNER
        tiles[10][67] = T_BANNER
        tiles[11][64] = T_CARPET
        tiles[11][65] = T_CARPET
        for r in range(4, 11):
            tiles[r][61] = T_PLANT_GREEN
            tiles[r][69] = T_PLANT_GREEN
        tiles[13][62] = T_PLANT_DARK
        tiles[13][68] = T_PLANT_DARK
        tiles[14][64] = T_SCULPTURE_LION
        tiles[14][65] = T_SCULPTURE_LION
        tiles[15][63] = T_FLOWER_RED
        tiles[15][67] = T_FLOWER_RED
        road_v(64, 12, 18, 2)

        # ===== 花间派 (col 60-70, row 18-28) =====
        fill(18, 28, 56, 72, T_GARDEN)
        fill(21, 25, 61, 65, T_LAKE)
        self._place_building(tiles, 18, 25, 66, 70, T_TEMPLE, 18, [68], T_ROOF_BLUE)
        tiles[20][68] = T_FLOWER_SPECIAL1
        tiles[21][67] = T_FLOWER_SPECIAL2
        tiles[21][69] = T_FLOWER_SPECIAL1
        tiles[22][68] = T_DESK_WOOD
        tiles[23][67] = T_FLOWER_SPECIAL2
        tiles[23][69] = T_FLOWER_SPECIAL2
        tiles[24][68] = T_CHEST
        tiles[26][61] = T_FLOWER_SPECIAL1
        tiles[26][63] = T_FLOWER_SPECIAL2
        tiles[26][65] = T_FLOWER_SPECIAL1
        tiles[27][62] = T_FLOWER_RED
        tiles[27][64] = T_FLOWER_PINK
        tiles[27][66] = T_FLOWER_WHITE
        for r in range(19, 27):
            tiles[r][56] = T_FLOWER_SPECIAL2
            tiles[r][71] = T_FLOWER_SPECIAL1
        road_v(68, 25, 28, 2)

        # ===== 红莲教 (col 60-70, row 33-48) =====
        fill(33, 48, 56, 72, T_DARK_GRASS)
        tiles[33][61] = T_HILL_LARGE
        tiles[34][63] = T_HILL_MEDIUM
        tiles[34][68] = T_TREE_WILLOW
        tiles[35][61] = T_TREE_WILLOW
        tiles[35][65] = T_TREE_WILLOW
        tiles[35][69] = T_STONE_MEDIUM
        tiles[36][62] = T_STONE_SMALL
        tiles[36][66] = T_STONE_MEDIUM
        self._place_building(tiles, 37, 44, 61, 69, T_TEMPLE, 37, [64, 65], T_ROOF_RED)
        tiles[38][62] = T_TRAINING
        tiles[38][68] = T_TRAINING
        tiles[39][64] = T_ALTAR
        tiles[40][63] = T_BANNER
        tiles[40][66] = T_BANNER
        for r in range(38, 43):
            tiles[r][64] = T_CARPET
            tiles[r][65] = T_CARPET
        tiles[42][64] = T_CHEST
        tiles[42][65] = T_CHEST
        tiles[45][62] = T_STONE_SMALL
        tiles[45][68] = T_STONE_SMALL
        tiles[46][61] = T_HILL_MEDIUM
        tiles[46][69] = T_TREE_WILLOW
        tiles[47][64] = T_FLOWER_RED
        tiles[47][65] = T_FLOWER_RED
        road_v(64, 44, 48, 2)

        # ===== 那迦派 (col 72-88, row 3-16) =====
        fill(3, 17, 72, 88, T_SAND)
        self._place_building(tiles, 3, 12, 74, 86, T_TEMPLE, 3, [79, 80], T_ROOF_GOLD)
        tiles[5][76] = T_TRAINING
        tiles[5][84] = T_TRAINING
        tiles[6][78] = T_SCULPTURE_LION
        tiles[6][82] = T_SCULPTURE_LION
        tiles[7][79] = T_CHEST
        tiles[7][80] = T_CHEST
        tiles[8][76] = T_TREE_DEAD
        tiles[8][84] = T_TREE_DEAD
        tiles[9][78] = T_PILLAR
        tiles[9][82] = T_PILLAR
        for r in range(4, 11):
            tiles[r][79] = T_CARPET
            tiles[r][80] = T_CARPET
        tiles[10][77] = T_TORCH
        tiles[10][83] = T_TORCH
        tiles[11][76] = T_TREE_PINE
        tiles[11][84] = T_TREE_PINE
        tiles[12][78] = T_SHELF_BOOK
        tiles[12][82] = T_SHELF_BOOK
        tiles[13][79] = T_SCULPTURE_LION
        tiles[13][80] = T_SCULPTURE_LION
        tiles[14][76] = T_STONE_MEDIUM
        tiles[14][84] = T_STONE_MEDIUM
        tiles[15][78] = T_TREE_DEAD
        tiles[15][82] = T_TREE_DEAD
        road_v(79, 12, 18, 2)

        # ===== 太极门 (col 72-88, row 18-30) =====
        fill(18, 30, 72, 88, T_DARK_GRASS)
        self._place_building(tiles, 18, 27, 74, 86, T_TEMPLE, 18, [79, 80], T_ROOF_GOLD)
        tiles[20][76] = T_ALTAR
        tiles[20][84] = T_SHELF_BOOK
        tiles[21][78] = T_BARS
        tiles[21][82] = T_BARS
        tiles[22][79] = T_CHEST
        tiles[22][80] = T_CHEST
        tiles[23][76] = T_TORCH
        tiles[23][84] = T_TORCH
        for r in range(19, 26):
            tiles[r][79] = T_CARPET
            tiles[r][80] = T_CARPET
        tiles[24][78] = T_DESK_LARGE
        tiles[24][82] = T_BENCH_STONE
        tiles[25][76] = T_PLANT_COLD
        tiles[25][84] = T_PLANT_COLD
        tiles[26][78] = T_BOTTLE
        tiles[26][82] = T_BOOK_OBJ
        tiles[28][76] = T_BARS
        tiles[28][84] = T_BARS
        tiles[29][79] = T_STONE_MEDIUM
        tiles[29][80] = T_STONE_MEDIUM
        road_v(79, 27, 30, 2)

        # ===== 雪山派 (col 72-88, row 35-55) =====
        fill(35, 55, 72, 90, T_SNOW)
        self._place_building(tiles, 36, 46, 74, 86, T_TEMPLE, 36, [79, 80], T_ROOF_RED)
        tiles[38][76] = T_TRAINING
        tiles[38][84] = T_TRAINING
        tiles[39][78] = T_BARS
        tiles[39][82] = T_BARS
        tiles[40][79] = T_CHEST
        tiles[40][80] = T_CHEST
        tiles[41][76] = T_PLANT_SNOW
        tiles[41][84] = T_PLANT_SNOW
        tiles[42][78] = T_WALL_STONE
        tiles[42][82] = T_WALL_STONE
        tiles[43][79] = T_SHELF_HERB
        tiles[43][80] = T_SHELF_HERB
        tiles[44][76] = T_TORCH
        tiles[44][84] = T_TORCH
        tiles[45][78] = T_STONE_MEDIUM
        tiles[45][82] = T_STONE_MEDIUM
        tiles[46][79] = T_FLOWER_WHITE
        tiles[46][80] = T_FLOWER_WHITE
        tiles[47][76] = T_HILL_SNOW
        tiles[47][84] = T_HILL_SNOW
        tiles[48][78] = T_STONE_SMALL
        tiles[48][82] = T_STONE_SMALL
        tiles[49][75] = T_STONE_LARGE
        tiles[49][85] = T_STONE_LARGE
        tiles[50][79] = T_PLANT_SNOW
        tiles[50][80] = T_PLANT_SNOW
        tiles[51][77] = T_HILL_SNOW
        tiles[51][83] = T_HILL_SNOW
        tiles[52][79] = T_STONE_MEDIUM
        tiles[52][80] = T_STONE_MEDIUM
        tiles[53][76] = T_ICE
        tiles[53][84] = T_ICE
        road_v(79, 46, 55, 2)

        # ===== 野外区域 =====
        # 北部森林
        fill(0, 5, 8, 20, T_FOREST)
        fill(0, 5, 42, 52, T_FOREST)
        fill(0, 3, 67, 72, T_FOREST)
        fill(0, 3, 88, 100, T_FOREST)

        # 东北野外
        fill(0, 3, 88, 100, T_FOREST)
        fill(3, 8, 90, 100, T_FOREST)

        # 中部野外
        fill(42, 55, 40, 55, T_DARK_GRASS)
        fill(45, 55, 45, 55, T_FOREST)

        # 南部野外
        fill(55, 70, 40, 60, T_FOREST)
        fill(60, 68, 45, 55, T_CAVE)
        fill(55, 70, 60, 72, T_HILL_LARGE)
        fill(62, 70, 65, 72, T_SAND)

        # 东南野外
        fill(68, 78, 40, 60, T_FOREST)
        fill(70, 76, 44, 56, T_RUIN)

        # 西南野外
        fill(56, 65, 0, 5, T_FOREST)
        fill(50, 60, 5, 15, T_DARK_GRASS)
        fill(52, 58, 8, 14, T_MUSHROOM)

        # 东部野外
        fill(56, 65, 90, 100, T_FOREST)
        fill(42, 50, 90, 100, T_SAND)

        # 沼泽
        fill(60, 70, 5, 15, T_SWAMP)

        # 野外装饰
        tiles[45][48] = T_TREE_PINE
        tiles[46][50] = T_TREE_WILLOW
        tiles[47][52] = T_TREE_PINE
        tiles[48][46] = T_HILL_MEDIUM
        tiles[49][48] = T_STONE_LARGE
        tiles[50][50] = T_TREE_DEAD
        tiles[51][46] = T_TREE_WILLOW
        tiles[52][48] = T_HILL_SMALL
        tiles[53][50] = T_STONE_MEDIUM
        tiles[55][42] = T_TREE_PINE
        tiles[56][44] = T_TREE_PINE
        tiles[57][46] = T_STONE_SMALL
        tiles[58][42] = T_TREE_DEAD
        tiles[59][44] = T_HILL_MEDIUM
        tiles[60][46] = T_TREE_WILLOW
        tiles[62][48] = T_STONE_LARGE
        tiles[63][50] = T_TREE_PINE
        tiles[65][42] = T_HILL_LARGE
        tiles[66][44] = T_TREE_DEAD
        tiles[68][46] = T_STONE_MEDIUM

        # 河边装饰
        tiles[5][5] = T_TREE_WILLOW
        tiles[10][5] = T_TREE_WILLOW
        tiles[15][5] = T_PLANT_GREEN
        tiles[20][5] = T_TREE_PINE
        tiles[40][5] = T_TREE_PINE
        tiles[45][5] = T_PLANT_GREEN
        tiles[50][4] = T_FISH
        tiles[55][4] = T_FISH

        # ===== 最终道路重铺 (确保所有路径畅通) =====
        # 主路
        road_h(30, 5, 48, 3)
        # 市场街
        road_v(22, 11, 30, 4)
        # 衙门街
        road_v(40, 22, 30, 3)
        # 连接路: 建筑 → 市场街
        road_h(16, 16, 22, 1)
        road_h(16, 25, 30, 1)
        road_h(21, 16, 22, 1)
        road_h(21, 25, 30, 1)
        road_h(27, 15, 22, 1)
        road_h(27, 25, 30, 1)
        # 连接路: 民居 → 市场街
        road_h(15, 8, 22, 1)
        road_h(20, 8, 22, 1)
        road_h(25, 8, 22, 1)
        road_h(15, 25, 37, 1)
        road_h(20, 25, 37, 1)
        # 武馆连接
        road_h(24, 8, 22, 1)
        # 衙门连接
        road_h(28, 36, 40, 1)
        road_h(28, 42, 44, 1)
        # 南部道路
        road_h(34, 6, 29, 2)
        road_v(9, 34, 39, 2)
        road_v(17, 34, 39, 2)
        road_v(25, 34, 39, 2)
        # 铁匠铺/医馆连接
        road_h(35, 25, 32, 1)
        road_h(35, 40, 44, 1)
        # 东西向主路延伸
        road_h(30, 48, 55, 3)
        # 八卦门连接 (穿过建筑到入口)
        road_v(53, 8, 18, 3)
        road_h(10, 53, 65, 3)
        road_v(53, 18, 28, 3)
        road_h(20, 53, 69, 3)
        # 红莲教连接
        road_v(53, 30, 40, 3)
        road_h(36, 53, 65, 3)
        # 那迦/太极连接
        road_h(30, 55, 72, 3)
        road_v(70, 8, 18, 3)
        road_h(10, 70, 80, 3)
        road_v(70, 18, 30, 3)
        road_h(20, 70, 80, 3)
        # 雪山连接
        road_v(70, 35, 50, 3)
        road_h(40, 70, 80, 3)
        # 门派内部道路
        road_v(64, 12, 18, 2)
        road_v(68, 25, 28, 2)
        road_v(64, 44, 48, 2)
        road_v(79, 12, 18, 2)
        road_v(79, 27, 30, 2)
        road_v(79, 46, 55, 2)

        self.current_map = Map(
            id="map_wuxia_world",
            name="武侠世界",
            width=MAP_W,
            height=MAP_H,
            tiles=tiles,
            description="一个宏大的武侠世界，八大门派鼎立，江湖风云变幻"
        )

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
        col = int(nx // TS)
        row = MAP_H - 1 - int(ny // TS)
        if 0 <= row < MAP_H and 0 <= col < MAP_W:
            if self.current_map.tiles[row][col] in WALKABLE:
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
        col = int(wx // TS)
        row = MAP_H - 1 - int(wy // TS)
        if col < 0 or col >= MAP_W or row < 0 or row >= MAP_H:
            return False
        tid = self.current_map.tiles[row][col]
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
