import math
import random
from typing import List, Optional, Dict
from .entities import Player, NPC, Map, Position, Skill, NpcType, Faction, Item, ItemType, FACTION_NAMES
from .combat import CombatSystem
from .npc_brain import get_npc_brain_manager, get_behavior_tracker
from .encounter import get_encounter_manager, Encounter
from .event import EventType, dispatch

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

WALKABLE = {
    T_GRASS, T_DIRT_ROAD, T_FOREST, T_DARK_GRASS, T_SAND, T_BRIDGE,
    T_SHOP, T_STONE_ROAD, T_GARDEN, T_INN, T_TEMPLE, T_DOCK,
    T_ROOF_RED, T_ROOF_BLUE, T_ROOF_GOLD, T_GATE, T_TRAINING,
    T_BAMBOO, T_CAVE, T_STAIRS, T_CARPET, T_FLOWER_BED,
    T_RICE_PADDY, T_TORCH, T_SIGN, T_CAMPFIRE, T_SNOW,
    T_MUSHROOM, T_RUIN, T_ARENA, T_POND,
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
}

FACTION_SKILLS = {
    Faction.BAGUA: ["kf_bagua_blade", "kf_bagua_palm", "kf_bazhen", "kf_hunyuan", "kf_youlong"],
    Faction.FLOWER: ["kf_huafei", "kf_huatuan", "kf_liu", "kf_meihua", "kf_sanhua"],
    Faction.HONGLIAN: ["kf_hexiang", "kf_jiaoyi", "kf_pifeng", "kf_taizu", "kf_tongji"],
    Faction.NAJA: ["kf_renshu", "kf_wufa", "kf_wuying", "kf_yidao"],
    Faction.TAIJI: ["kf_taiji_sword", "kf_taiji_fist", "kf_taiji_force", "kf_wanliu", "kf_xuanxu"],
    Faction.XUESHAN: ["kf_taxue", "kf_xueshang", "kf_xueshan_sword", "kf_xueying"],
    Faction.XIAOYAO: ["kf_menghu", "kf_xi", "kf_basic_sword", "kf_basic_dodge"],
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
        self.is_paused: bool = False

        self.combat_system = CombatSystem()
        self.game_state: str = "normal"

        self._init_all_items()
        self._init_default_map()
        self._init_all_npcs()

        self.player.position = Position(col_to_x(25), row_to_y(40))

    def set_player(self, player: Player):
        self.player = player
        self.player.position = Position(col_to_x(25), row_to_y(40))
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
        npcs = [
            NPC(id=47, name="平阿四", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="忠厚老实", description="平安客栈掌柜，消息灵通",
                level=5, strength=8, dexterity=8, intelligence=12, constitution=10,
                hp=80, max_hp=80, mp=40, max_mp=40, attack=10, defense=5, damage=5, money=200, exp_reward=30,
                sell_items=["item_baozi", "item_chicken", "item_wine"],
                position=yx_to_xy(8, 8), has_quests=True),
            NPC(id=35, name="店小二", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="机灵勤快", description="客栈伙计",
                level=3, strength=6, dexterity=10, intelligence=8, constitution=6,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=5, defense=3, damage=3, money=50, exp_reward=15,
                position=yx_to_xy(10, 9), has_quests=False),
            NPC(id=37, name="阎商", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="精明利落", description="盐商，精打细算",
                level=5, strength=6, dexterity=8, intelligence=15, constitution=6,
                hp=60, max_hp=60, mp=30, max_mp=30, attack=8, defense=4, damage=4, money=500, exp_reward=25,
                sell_items=["item_dan"],
                position=yx_to_xy(30, 8), has_quests=True),
            NPC(id=11, name="葛朗台", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="吝啬刻薄", description="钱庄掌柜",
                level=8, strength=5, dexterity=6, intelligence=18, constitution=8,
                hp=70, max_hp=70, mp=40, max_mp=40, attack=6, defense=6, damage=4, money=5000, exp_reward=20,
                position=yx_to_xy(19, 7), has_quests=True),
            NPC(id=1, name="阿青", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="天真善良", description="越女剑传人，卖豆腐为生",
                level=15, strength=16, dexterity=24, intelligence=25, constitution=21,
                hp=370, max_hp=370, mp=200, max_mp=200, attack=30, defense=15, damage=12, money=1000, exp_reward=50,
                sell_items=["item_white_doufu", "item_green_doufu"],
                position=yx_to_xy(44, 9), has_quests=True),
            NPC(id=5, name="厨师", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="豪爽热情", description="酒楼大厨",
                level=5, strength=28, dexterity=21, intelligence=24, constitution=21,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=15, defense=8, damage=8, money=100, exp_reward=15,
                position=yx_to_xy(38, 9), has_quests=True),
            NPC(id=34, name="屠夫", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="粗犷豪放", description="卖肉的屠夫",
                level=6, strength=30, dexterity=15, intelligence=10, constitution=25,
                hp=350, max_hp=350, mp=0, max_mp=0, attack=18, defense=10, damage=10, money=200, exp_reward=20,
                sell_items=["item_meat", "item_chicken"],
                position=yx_to_xy(40, 17), has_quests=False),
            NPC(id=9, name="卖花女", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="温柔可人", description="卖花的姑娘",
                level=2, strength=5, dexterity=10, intelligence=12, constitution=6,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=3, defense=2, damage=1, money=80, exp_reward=8,
                sell_items=["item_red_flower", "item_tea_flower"],
                position=yx_to_xy(19, 17), has_quests=False),
            NPC(id=27, name="小商贩", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="热情吆喝", description="街边小贩",
                level=2, strength=8, dexterity=10, intelligence=10, constitution=8,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=3, defense=2, damage=2, money=50, exp_reward=8,
                sell_items=["item_tang_hulu"],
                position=yx_to_xy(25, 19), has_quests=False),
            NPC(id=26, name="平一指", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="医术高明", description="名医，杀一人医一人",
                level=10, strength=8, dexterity=12, intelligence=20, constitution=10,
                hp=100, max_hp=100, mp=60, max_mp=60, attack=8, defense=5, damage=3, money=300, exp_reward=30,
                sell_items=["item_yao", "item_shengji", "item_dan"],
                position=yx_to_xy(38, 17), has_quests=True),
            NPC(id=19, name="何铁手", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="阴险毒辣", description="五毒教主，师从袁承志",
                level=20, strength=18, dexterity=22, intelligence=20, constitution=16,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=35, defense=15, damage=15, money=2000, exp_reward=80,
                sell_items=["item_blade", "item_dagger", "item_whip", "item_hetun_blade"],
                position=yx_to_xy(52, 9), has_quests=True),
            NPC(id=20, name="何喜", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="悠闲自在", description="渔夫，喜欢钓鱼",
                level=3, strength=10, dexterity=8, intelligence=8, constitution=10,
                hp=40, max_hp=40, mp=10, max_mp=10, attack=4, defense=3, damage=2, money=30, exp_reward=8,
                sell_items=["item_diaogan", "item_fish"],
                position=yx_to_xy(5, 2), has_quests=True),
            NPC(id=29, name="小裁缝", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="心灵手巧", description="裁缝铺小师傅",
                level=4, strength=6, dexterity=14, intelligence=10, constitution=6,
                hp=40, max_hp=40, mp=20, max_mp=20, attack=4, defense=3, damage=2, money=100, exp_reward=10,
                sell_items=["item_cloth", "item_fine_cloth"],
                position=yx_to_xy(19, 17), has_quests=False),
            NPC(id=30, name="何裁缝", npc_type=NpcType.TRADER, faction=Faction.NONE,
                personality="老练细心", description="做了一辈子衣服的老裁缝",
                level=6, strength=6, dexterity=10, intelligence=12, constitution=8,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=4, defense=3, damage=2, money=150, exp_reward=12,
                sell_items=["item_cloth", "item_fine_cloth", "item_silk_cloth"],
                position=yx_to_xy(20, 16), has_quests=True),
            NPC(id=3, name="捕快", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="刚正不阿", description="平安镇捕快",
                level=12, strength=27, dexterity=25, intelligence=28, constitution=29,
                hp=370, max_hp=370, mp=200, max_mp=200, attack=25, defense=15, damage=10, money=1500, exp_reward=40,
                position=yx_to_xy(25, 30), has_quests=True),
            NPC(id=33, name="巡捕", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="尽职尽责", description="城里巡逻官",
                level=14, strength=25, dexterity=25, intelligence=28, constitution=27,
                hp=350, max_hp=350, mp=200, max_mp=200, attack=22, defense=14, damage=9, money=1200, exp_reward=35,
                position=yx_to_xy(35, 30), has_quests=False),
            NPC(id=14, name="衙役", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="威严守纪", description="衙门守卫",
                level=10, strength=22, dexterity=20, intelligence=15, constitution=22,
                hp=300, max_hp=300, mp=100, max_mp=100, attack=18, defense=12, damage=8, money=500, exp_reward=25,
                position=yx_to_xy(30, 30), has_quests=False),
            NPC(id=31, name="老夫子", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="博学多才", description="私塾先生，读书识字180级",
                level=20, strength=8, dexterity=6, intelligence=30, constitution=8,
                hp=200, max_hp=200, mp=300, max_mp=300, attack=5, defense=5, damage=2, money=0, exp_reward=100,
                position=yx_to_xy(7, 26), is_master=True,
                teach_skills=["kf_literate"], has_quests=True),
            NPC(id=6, name="村长", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="德高望重", description="平安镇村长",
                level=10, strength=29, dexterity=25, intelligence=21, constitution=21,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=15, defense=10, damage=8, money=100, exp_reward=30,
                position=yx_to_xy(25, 25), has_quests=True),
            NPC(id=15, name="老婆婆", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="慈祥温和", description="住了几十年的老居民",
                level=3, strength=6, dexterity=8, intelligence=10, constitution=8,
                hp=40, max_hp=40, mp=10, max_mp=10, attack=3, defense=2, damage=1, money=20, exp_reward=8,
                position=yx_to_xy(15, 25), has_quests=False),
            NPC(id=10, name="妇人", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="忧心忡忡", description="富家妇人，常丢东西",
                level=2, strength=5, dexterity=6, intelligence=10, constitution=6,
                hp=30, max_hp=30, mp=10, max_mp=10, attack=2, defense=1, damage=1, money=500, exp_reward=8,
                position=yx_to_xy(22, 18), has_quests=True),
            NPC(id=13, name="公子哥", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="趾高气扬", description="富家公子，爱吃白豆腐",
                level=3, strength=8, dexterity=10, intelligence=12, constitution=8,
                hp=50, max_hp=50, mp=20, max_mp=20, attack=5, defense=3, damage=3, money=2000, exp_reward=10,
                position=yx_to_xy(35, 17), has_quests=True),
            NPC(id=28, name="书童", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="文质彬彬", description="私塾学童，想学武",
                level=3, strength=5, dexterity=8, intelligence=20, constitution=5,
                hp=30, max_hp=30, mp=20, max_mp=20, attack=3, defense=2, damage=1, money=20, exp_reward=10,
                position=yx_to_xy(9, 26), has_quests=True),
            NPC(id=2, name="小童", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="天真活泼", description="镇上的小孩，爱吃糖葫芦",
                level=1, strength=5, dexterity=8, intelligence=6, constitution=5,
                hp=20, max_hp=20, mp=0, max_mp=0, attack=2, defense=1, damage=1, money=5, exp_reward=3,
                position=yx_to_xy(22, 26), has_quests=True),
            NPC(id=16, name="过路人", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="疲惫迷茫", description="不知从何而来的旅人",
                level=1, strength=6, dexterity=6, intelligence=8, constitution=6,
                hp=25, max_hp=25, mp=5, max_mp=5, attack=2, defense=1, damage=1, money=30, exp_reward=5,
                position=yx_to_xy(40, 25), has_quests=False),
            NPC(id=17, name="茅十七", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="江湖老练", description="茅十八的哥哥",
                level=12, strength=20, dexterity=25, intelligence=15, constitution=18,
                hp=280, max_hp=280, mp=80, max_mp=80, attack=20, defense=12, damage=8, money=200, exp_reward=40,
                position=yx_to_xy(45, 25), has_quests=True),

            NPC(id=48, name="韦扬", npc_type=NpcType.MASTER, faction=Faction.BAGUA,
                personality="威严深沉", description="八卦门掌门，混元一气250级",
                level=40, strength=25, dexterity=22, intelligence=20, constitution=25,
                hp=800, max_hp=800, mp=500, max_mp=500, attack=90, defense=50, damage=35, money=0, exp_reward=1500,
                position=yx_to_xy(60, 8), is_master=True,
                teach_skills=["kf_bagua_blade", "kf_bagua_palm", "kf_bazhen", "kf_hunyuan", "kf_youlong"],
                has_quests=True),
            NPC(id=44, name="简明", npc_type=NpcType.MASTER, faction=Faction.BAGUA,
                personality="刚毅果决", description="八卦门大师兄，八卦刀出神入化",
                level=25, strength=20, dexterity=18, intelligence=15, constitution=18,
                hp=500, max_hp=500, mp=250, max_mp=250, attack=50, defense=30, damage=20, money=0, exp_reward=500,
                position=yx_to_xy(62, 10), is_master=True,
                teach_skills=["kf_bagua_blade", "kf_bagua_palm"],
                has_quests=False),
            NPC(id=43, name="简杰", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="沉稳内敛", description="八卦门二师兄，八阵图高手",
                level=22, strength=18, dexterity=16, intelligence=18, constitution=16,
                hp=420, max_hp=420, mp=200, max_mp=200, attack=40, defense=25, damage=16, money=50, exp_reward=350,
                position=yx_to_xy(58, 10), has_quests=False),
            NPC(id=45, name="简英", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="英气勃发", description="八卦门三师兄",
                level=20, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=380, max_hp=380, mp=180, max_mp=180, attack=35, defense=22, damage=14, money=30, exp_reward=280,
                position=yx_to_xy(63, 9), has_quests=False),
            NPC(id=46, name="鲍振", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="勤勉好学", description="八卦门弟子，刀法不错",
                level=12, strength=14, dexterity=12, intelligence=10, constitution=14,
                hp=250, max_hp=250, mp=100, max_mp=100, attack=22, defense=14, damage=10, money=20, exp_reward=120,
                position=yx_to_xy(60, 12), has_quests=False),
            NPC(id=49, name="武师教头", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="严厉刚正", description="八卦门武师教头",
                level=15, strength=18, dexterity=16, intelligence=12, constitution=18,
                hp=320, max_hp=320, mp=120, max_mp=120, attack=28, defense=18, damage=12, money=50, exp_reward=180,
                position=yx_to_xy(61, 11), has_quests=False),
            NPC(id=50, name="春花娘", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="温柔坚韧", description="八卦门女弟子",
                level=10, strength=10, dexterity=14, intelligence=12, constitution=10,
                hp=200, max_hp=200, mp=80, max_mp=80, attack=15, defense=10, damage=6, money=30, exp_reward=60,
                position=yx_to_xy(57, 11), has_quests=False),
            NPC(id=51, name="护院武师", npc_type=NpcType.NORMAL, faction=Faction.BAGUA,
                personality="老实忠厚", description="八卦门护院",
                level=8, strength=14, dexterity=10, intelligence=8, constitution=14,
                hp=180, max_hp=180, mp=60, max_mp=60, attack=14, defense=10, damage=6, money=20, exp_reward=40,
                position=yx_to_xy(56, 8), has_quests=False),

            NPC(id=57, name="清照", npc_type=NpcType.MASTER, faction=Faction.FLOWER,
                personality="清雅脱俗", description="花间派掌门，三花聚顶250级",
                level=40, strength=15, dexterity=28, intelligence=25, constitution=18,
                hp=700, max_hp=700, mp=600, max_mp=600, attack=75, defense=40, damage=30, money=0, exp_reward=1500,
                position=yx_to_xy(60, 20), is_master=True,
                teach_skills=["kf_huafei", "kf_huatuan", "kf_liu", "kf_meihua", "kf_sanhua"],
                has_quests=True),
            NPC(id=53, name="红拂女", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="英姿飒爽", description="花间派弟子，花团锦簇高手",
                level=18, strength=14, dexterity=22, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=150, max_mp=150, attack=30, defense=18, damage=12, money=100, exp_reward=200,
                position=yx_to_xy(62, 22), has_quests=False),
            NPC(id=55, name="公孙大娘", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="端庄大方", description="百花之母的传人",
                level=22, strength=16, dexterity=20, intelligence=18, constitution=16,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=38, defense=22, damage=15, money=80, exp_reward=300,
                position=yx_to_xy(58, 22), has_quests=False),
            NPC(id=56, name="青红", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="热情似火", description="花间派大弟子",
                level=20, strength=14, dexterity=20, intelligence=16, constitution=14,
                hp=350, max_hp=350, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=60, exp_reward=250,
                position=yx_to_xy(64, 22), has_quests=False),
            NPC(id=58, name="绿珠", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="温婉可人", description="花间派弟子，经平一指调教",
                level=16, strength=12, dexterity=18, intelligence=14, constitution=12,
                hp=260, max_hp=260, mp=130, max_mp=130, attack=25, defense=16, damage=10, money=40, exp_reward=160,
                position=yx_to_xy(60, 24), has_quests=False),
            NPC(id=59, name="雪涛", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="冷静沉着", description="花间派弟子",
                level=15, strength=12, dexterity=16, intelligence=14, constitution=12,
                hp=240, max_hp=240, mp=120, max_mp=120, attack=22, defense=14, damage=9, money=30, exp_reward=140,
                position=yx_to_xy(62, 24), has_quests=False),
            NPC(id=60, name="隐娘", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="神秘莫测", description="花间派神秘弟子",
                level=20, strength=14, dexterity=22, intelligence=16, constitution=14,
                hp=340, max_hp=340, mp=170, max_mp=170, attack=30, defense=18, damage=12, money=0, exp_reward=220,
                position=yx_to_xy(56, 20), has_quests=True),
            NPC(id=61, name="王辞", npc_type=NpcType.NORMAL, faction=Faction.FLOWER,
                personality="才貌双全", description="花间派弟子，容貌180级",
                level=18, strength=12, dexterity=18, intelligence=20, constitution=12,
                hp=280, max_hp=280, mp=160, max_mp=160, attack=26, defense=16, damage=10, money=50, exp_reward=180,
                position=yx_to_xy(58, 24), has_quests=False),

            NPC(id=79, name="于红儒", npc_type=NpcType.MASTER, faction=Faction.HONGLIAN,
                personality="刚烈如火", description="红莲教掌门，同击术250级",
                level=40, strength=28, dexterity=18, intelligence=15, constitution=28,
                hp=900, max_hp=900, mp=400, max_mp=400, attack=85, defense=55, damage=35, money=0, exp_reward=1500,
                position=yx_to_xy(60, 35), is_master=True,
                teach_skills=["kf_hexiang", "kf_jiaoyi", "kf_pifeng", "kf_taizu", "kf_tongji"],
                has_quests=True),
            NPC(id=72, name="方长老", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="老谋深算", description="红莲教管事长老",
                level=22, strength=18, dexterity=15, intelligence=18, constitution=18,
                hp=400, max_hp=400, mp=200, max_mp=200, attack=35, defense=25, damage=15, money=200, exp_reward=300,
                position=yx_to_xy(62, 37), has_quests=True),
            NPC(id=73, name="韩长老", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="愤世嫉俗", description="原在朝廷为官，后投奔红莲教",
                level=18, strength=14, dexterity=14, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=150, max_mp=150, attack=25, defense=18, damage=10, money=100, exp_reward=180,
                position=yx_to_xy(58, 37), has_quests=False),
            NPC(id=74, name="楚红灯", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="暴躁易怒", description="红莲教弟子，满脸怒气",
                level=16, strength=16, dexterity=12, intelligence=10, constitution=16,
                hp=280, max_hp=280, mp=120, max_mp=120, attack=24, defense=16, damage=10, money=50, exp_reward=150,
                position=yx_to_xy(64, 37), has_quests=False),
            NPC(id=75, name="崇儿", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="刚毅坚定", description="红莲教女弟子，武功不凡",
                level=20, strength=16, dexterity=20, intelligence=14, constitution=16,
                hp=360, max_hp=360, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=30, exp_reward=240,
                position=yx_to_xy(60, 37), has_quests=False),
            NPC(id=76, name="唐四儿", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="坚韧不拔", description="独臂英雄",
                level=18, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=40, exp_reward=200,
                position=yx_to_xy(56, 35), has_quests=False),
            NPC(id=77, name="白衣教众", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="忠诚", description="红莲教白衣教众",
                level=8, strength=10, dexterity=8, intelligence=8, constitution=10,
                hp=150, max_hp=150, mp=50, max_mp=50, attack=12, defense=8, damage=5, money=10, exp_reward=30,
                position=yx_to_xy(58, 35), has_quests=False),
            NPC(id=78, name="红衣教众", npc_type=NpcType.NORMAL, faction=Faction.HONGLIAN,
                personality="狂热", description="红莲教红衣教众",
                level=10, strength=12, dexterity=10, intelligence=8, constitution=12,
                hp=180, max_hp=180, mp=60, max_mp=60, attack=15, defense=10, damage=6, money=15, exp_reward=40,
                position=yx_to_xy(64, 35), has_quests=False),

            NPC(id=92, name="钟央", npc_type=NpcType.MASTER, faction=Faction.NAJA,
                personality="沉默寡言", description="那迦派掌门，忍术250级",
                level=40, strength=22, dexterity=25, intelligence=22, constitution=20,
                hp=750, max_hp=750, mp=500, max_mp=500, attack=80, defense=45, damage=30, money=0, exp_reward=1500,
                position=yx_to_xy(80, 8), is_master=True,
                teach_skills=["kf_renshu", "kf_wufa", "kf_wuying", "kf_yidao"],
                has_quests=True),
            NPC(id=80, name="十三卫", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="冷酷无情", description="那迦派高手，负责暗杀",
                level=20, strength=18, dexterity=20, intelligence=12, constitution=16,
                hp=350, max_hp=350, mp=150, max_mp=150, attack=35, defense=20, damage=15, money=50, exp_reward=250,
                position=yx_to_xy(82, 10), has_quests=False),
            NPC(id=81, name="美奈子", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="沉静如水", description="那迦派女弟子",
                level=18, strength=14, dexterity=18, intelligence=16, constitution=14,
                hp=300, max_hp=300, mp=160, max_mp=160, attack=28, defense=16, damage=12, money=30, exp_reward=180,
                position=yx_to_xy(78, 10), has_quests=False),
            NPC(id=82, name="藤王", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="桀骜不驯", description="那迦派弟子",
                level=16, strength=16, dexterity=16, intelligence=12, constitution=14,
                hp=280, max_hp=280, mp=130, max_mp=130, attack=26, defense=16, damage=11, money=40, exp_reward=160,
                position=yx_to_xy(84, 10), has_quests=False),
            NPC(id=83, name="游敬", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="沉默寡言", description="那迦派弟子",
                level=18, strength=16, dexterity=18, intelligence=14, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=30, exp_reward=190,
                position=yx_to_xy(80, 12), has_quests=False),
            NPC(id=84, name="天井", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="机敏灵活", description="那迦派弟子",
                level=14, strength=14, dexterity=16, intelligence=12, constitution=14,
                hp=240, max_hp=240, mp=110, max_mp=110, attack=22, defense=14, damage=9, money=20, exp_reward=120,
                position=yx_to_xy(82, 12), has_quests=False),
            NPC(id=85, name="孙三", npc_type=NpcType.NORMAL, faction=Faction.NAJA,
                personality="精明干练", description="那迦派弟子",
                level=14, strength=14, dexterity=14, intelligence=14, constitution=14,
                hp=240, max_hp=240, mp=110, max_mp=110, attack=22, defense=14, damage=9, money=20, exp_reward=120,
                position=yx_to_xy(78, 12), has_quests=False),
            NPC(id=86, name="浪人甲", npc_type=NpcType.NORMAL, faction=Faction.NONE,
                personality="落魄失意", description="没能进入那迦派的浪人",
                level=8, strength=12, dexterity=14, intelligence=8, constitution=10,
                hp=160, max_hp=160, mp=50, max_mp=50, attack=14, defense=8, damage=5, money=10, exp_reward=40,
                position=yx_to_xy(75, 5), has_quests=False),

            NPC(id=99, name="清虚道人", npc_type=NpcType.MASTER, faction=Faction.TAIJI,
                personality="仙风道骨", description="太极门掌门，太极功250级",
                level=45, strength=20, dexterity=22, intelligence=28, constitution=22,
                hp=850, max_hp=850, mp=700, max_mp=700, attack=85, defense=55, damage=30, money=0, exp_reward=2000,
                position=yx_to_xy(80, 22), is_master=True,
                teach_skills=["kf_taiji_sword", "kf_taiji_fist", "kf_taiji_force", "kf_wanliu", "kf_xuanxu"],
                has_quests=True),
            NPC(id=95, name="古松道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="沉稳内敛", description="太极门师叔",
                level=25, strength=18, dexterity=16, intelligence=20, constitution=18,
                hp=450, max_hp=450, mp=250, max_mp=250, attack=40, defense=30, damage=15, money=0, exp_reward=400,
                position=yx_to_xy(82, 24), has_quests=False),
            NPC(id=96, name="仓月道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="深藏不露", description="太极门师叔",
                level=22, strength=16, dexterity=18, intelligence=20, constitution=16,
                hp=400, max_hp=400, mp=220, max_mp=220, attack=35, defense=25, damage=14, money=0, exp_reward=320,
                position=yx_to_xy(78, 24), has_quests=False),
            NPC(id=97, name="采药道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="淡泊名利", description="太极门前辈师叔",
                level=18, strength=14, dexterity=16, intelligence=18, constitution=14,
                hp=320, max_hp=320, mp=180, max_mp=180, attack=28, defense=18, damage=11, money=0, exp_reward=200,
                position=yx_to_xy(84, 24), has_quests=False),
            NPC(id=98, name="知客道人", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="和蔼可亲", description="太极门弟子",
                level=14, strength=12, dexterity=14, intelligence=14, constitution=12,
                hp=240, max_hp=240, mp=120, max_mp=120, attack=20, defense=14, damage=8, money=20, exp_reward=120,
                position=yx_to_xy(80, 26), has_quests=False),
            NPC(id=100, name="迎客道童", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="热情好客", description="太极门弟子",
                level=10, strength=10, dexterity=12, intelligence=10, constitution=10,
                hp=180, max_hp=180, mp=80, max_mp=80, attack=15, defense=10, damage=6, money=10, exp_reward=60,
                position=yx_to_xy(82, 26), has_quests=False),
            NPC(id=101, name="明月", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="憨厚老实", description="太极门弟子，傻乎乎的",
                level=8, strength=8, dexterity=10, intelligence=8, constitution=10,
                hp=150, max_hp=150, mp=60, max_mp=60, attack=12, defense=8, damage=5, money=5, exp_reward=40,
                position=yx_to_xy(78, 26), has_quests=False),
            NPC(id=102, name="清风", npc_type=NpcType.NORMAL, faction=Faction.TAIJI,
                personality="勤勉好学", description="太极门入门弟子",
                level=6, strength=6, dexterity=8, intelligence=8, constitution=6,
                hp=100, max_hp=100, mp=40, max_mp=40, attack=8, defense=6, damage=3, money=5, exp_reward=20,
                position=yx_to_xy(84, 26), has_quests=False),

            NPC(id=108, name="白瑞德", npc_type=NpcType.MASTER, faction=Faction.XUESHAN,
                personality="冷峻如冰", description="雪山派掌门，雪上霜250级",
                level=42, strength=24, dexterity=26, intelligence=18, constitution=24,
                hp=800, max_hp=800, mp=500, max_mp=500, attack=90, defense=45, damage=35, money=0, exp_reward=1800,
                position=yx_to_xy(80, 40), is_master=True,
                teach_skills=["kf_taxue", "kf_xueshang", "kf_xueshan_sword", "kf_xueying"],
                has_quests=True),
            NPC(id=109, name="史婆婆", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="严厉慈爱", description="白瑞德的妻子",
                level=22, strength=18, dexterity=18, intelligence=16, constitution=18,
                hp=380, max_hp=380, mp=200, max_mp=200, attack=35, defense=22, damage=14, money=30, exp_reward=300,
                position=yx_to_xy(82, 42), has_quests=False),
            NPC(id=110, name="万剑", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="锐气逼人", description="雪山派大弟子",
                level=20, strength=18, dexterity=20, intelligence=14, constitution=18,
                hp=360, max_hp=360, mp=180, max_mp=180, attack=32, defense=20, damage=13, money=20, exp_reward=250,
                position=yx_to_xy(78, 42), has_quests=False),
            NPC(id=111, name="万刃", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="刚毅果敢", description="雪山派巡山总管",
                level=18, strength=16, dexterity=16, intelligence=12, constitution=16,
                hp=320, max_hp=320, mp=150, max_mp=150, attack=28, defense=18, damage=12, money=15, exp_reward=200,
                position=yx_to_xy(84, 42), has_quests=False),
            NPC(id=112, name="万重", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="稳重踏实", description="雪山派弟子",
                level=16, strength=14, dexterity=14, intelligence=12, constitution=16,
                hp=280, max_hp=280, mp=130, max_mp=130, attack=24, defense=16, damage=10, money=10, exp_reward=160,
                position=yx_to_xy(80, 44), has_quests=False),
            NPC(id=113, name="万一", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="谨慎小心", description="雪山派弟子",
                level=16, strength=14, dexterity=16, intelligence=12, constitution=14,
                hp=270, max_hp=270, mp=130, max_mp=130, attack=24, defense=15, damage=10, money=10, exp_reward=160,
                position=yx_to_xy(82, 44), has_quests=False),
            NPC(id=107, name="阿秀", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="温柔坚韧", description="雪山派女弟子，史婆婆的弟子",
                level=14, strength=10, dexterity=16, intelligence=14, constitution=10,
                hp=220, max_hp=220, mp=110, max_mp=110, attack=20, defense=12, damage=8, money=15, exp_reward=100,
                position=yx_to_xy(78, 44), has_quests=False),
            NPC(id=114, name="雪千柔", npc_type=NpcType.NORMAL, faction=Faction.XUESHAN,
                personality="柔弱似水", description="雪山派女弟子",
                level=8, strength=8, dexterity=10, intelligence=10, constitution=8,
                hp=140, max_hp=140, mp=60, max_mp=60, attack=10, defense=8, damage=4, money=10, exp_reward=40,
                position=yx_to_xy(84, 44), has_quests=False),

            NPC(id=21, name="流氓", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="欺软怕硬", description="镇上的小混混",
                level=4, strength=12, dexterity=10, intelligence=5, constitution=10,
                hp=60, max_hp=60, mp=0, max_mp=0, attack=8, defense=3, damage=5, money=30, exp_reward=15,
                position=yx_to_xy(12, 19), has_quests=False),
            NPC(id=22, name="流氓头", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶神恶煞", description="流氓头子",
                level=7, strength=16, dexterity=12, intelligence=8, constitution=14,
                hp=100, max_hp=100, mp=20, max_mp=20, attack=15, defense=6, damage=8, money=100, exp_reward=30,
                position=yx_to_xy(8, 19), has_quests=False),
            NPC(id=8, name="独角大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="残暴无情", description="臭名昭著的大盗",
                level=12, strength=33, dexterity=18, intelligence=20, constitution=22,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=25, defense=12, damage=15, money=10000, exp_reward=80,
                position=yx_to_xy(45, 55), has_quests=False),
            NPC(id=4, name="采花大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="阴险狡诈", description="采花大盗，轻功了得",
                level=15, strength=18, dexterity=28, intelligence=22, constitution=24,
                hp=320, max_hp=320, mp=0, max_mp=0, attack=22, defense=10, damage=12, money=10000, exp_reward=100,
                position=yx_to_xy(48, 58), has_quests=False),
            NPC(id=18, name="黑衣大盗", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="冷酷无情", description="神秘黑衣人，来去无踪",
                level=18, strength=22, dexterity=25, intelligence=18, constitution=20,
                hp=400, max_hp=400, mp=100, max_mp=100, attack=30, defense=15, damage=18, money=5000, exp_reward=120,
                position=yx_to_xy(50, 62), has_quests=False),
            NPC(id=23, name="土匪甲", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶悍蛮横", description="雪山脚下的土匪",
                level=10, strength=20, dexterity=12, intelligence=8, constitution=16,
                hp=200, max_hp=200, mp=0, max_mp=0, attack=18, defense=8, damage=10, money=500, exp_reward=50,
                position=yx_to_xy(70, 50), has_quests=False),
            NPC(id=24, name="土匪头目", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="残暴嗜血", description="土匪头目",
                level=15, strength=24, dexterity=16, intelligence=12, constitution=20,
                hp=350, max_hp=350, mp=50, max_mp=50, attack=28, defense=14, damage=15, money=2000, exp_reward=100,
                position=yx_to_xy(72, 52), has_quests=False),
            NPC(id=25, name="雪豹", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="凶猛野兽", description="雪山上的猛兽",
                level=12, strength=22, dexterity=20, intelligence=5, constitution=20,
                hp=280, max_hp=280, mp=0, max_mp=0, attack=22, defense=10, damage=12, money=0, exp_reward=60,
                position=yx_to_xy(84, 47), has_quests=False),

            NPC(id=7, name="大侠", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="侠肝义胆", description="武功高强的游侠，追查宝藏",
                level=35, strength=20, dexterity=20, intelligence=26, constitution=21,
                hp=620, max_hp=620, mp=1200, max_mp=1200, attack=80, defense=40, damage=30, money=0, exp_reward=1000,
                position=yx_to_xy(35, 55), is_master=True,
                teach_skills=["kf_basic_bare", "kf_basic_sword", "kf_basic_blade", "kf_basic_club"],
                has_quests=True),
            NPC(id=12, name="道德和尚", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="慈悲为怀", description="少林高僧，善恶一念间",
                level=25, strength=20, dexterity=15, intelligence=30, constitution=25,
                hp=500, max_hp=500, mp=300, max_mp=300, attack=50, defense=40, damage=20, money=0, exp_reward=500,
                position=yx_to_xy(7, 20), is_master=True,
                teach_skills=["kf_basic_force", "kf_basic_parry"], has_quests=True),
            NPC(id=32, name="李白", npc_type=NpcType.MASTER, faction=Faction.NONE,
                personality="豪放不羁", description="诗仙剑客，剑法超群",
                level=30, strength=20, dexterity=25, intelligence=30, constitution=20,
                hp=600, max_hp=600, mp=400, max_mp=400, attack=70, defense=35, damage=25, money=0, exp_reward=800,
                position=yx_to_xy(35, 48), is_master=True,
                teach_skills=["kf_basic_sword", "kf_huafei"], has_quests=True),

            NPC(id=120, name="神秘人", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="神秘莫测", description="手持屠龙刀的神秘人，集多门派武功于一身",
                level=50, strength=30, dexterity=25, intelligence=28, constitution=28,
                hp=2000, max_hp=2000, mp=1500, max_mp=1500, attack=120, defense=60, damage=50, money=0, exp_reward=5000,
                position=yx_to_xy(50, 70), has_quests=True),
            NPC(id=121, name="绣花女", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="冷艳绝伦", description="使用绣花针的神秘女子，兼修太极和花间武功",
                level=55, strength=22, dexterity=35, intelligence=30, constitution=22,
                hp=1800, max_hp=1800, mp=2000, max_mp=2000, attack=110, defense=55, damage=45, money=0, exp_reward=6000,
                position=yx_to_xy(55, 72), has_quests=True),
            NPC(id=122, name="魔化和尚", npc_type=NpcType.ENEMY, faction=Faction.NONE,
                personality="癫狂邪恶", description="道德和尚的黑暗面，兼修雪山和太极武功",
                level=60, strength=35, dexterity=28, intelligence=32, constitution=35,
                hp=2500, max_hp=2500, mp=2000, max_mp=2000, attack=140, defense=70, damage=60, money=0, exp_reward=8000,
                position=yx_to_xy(45, 72), has_quests=True),
        ]
        self.npcs = list(npcs)

    def _init_all_items(self):
        items = [
            Item(id="item_baozi", name="包子", type=ItemType.CONSUMABLE, price=5, description="一笼热气腾腾的大包子", effects={"hp": 20, "food": 30}),
            Item(id="item_chicken", name="烧鸡", type=ItemType.CONSUMABLE, price=12, description="一只香喷喷的烧鸡", effects={"hp": 35, "food": 40}),
            Item(id="item_meat", name="鲜肉", type=ItemType.CONSUMABLE, price=8, description="上好的鲜肉", effects={"hp": 25, "food": 30}),
            Item(id="item_tang_hulu", name="糖葫芦", type=ItemType.CONSUMABLE, price=3, description="一串可口的糖葫芦", effects={"hp": 10}),
            Item(id="item_white_doufu", name="白豆腐", type=ItemType.CONSUMABLE, price=3, description="白白嫩嫩的豆腐", effects={"hp": 10}),
            Item(id="item_green_doufu", name="臭豆腐", type=ItemType.CONSUMABLE, price=5, description="闻着臭吃着香", effects={"hp": 15}),
            Item(id="item_butter_tea", name="酥油茶", type=ItemType.CONSUMABLE, price=10, description="雪山特产，滋补品", effects={"hp": 20, "mp": 10}),
            Item(id="item_wine", name="美酒", type=ItemType.CONSUMABLE, price=10, description="香醇的美酒", effects={"hp": 10, "mp": 10}),
            Item(id="item_yao", name="药", type=ItemType.CONSUMABLE, price=15, description="普通草药", effects={"hp": 30}),
            Item(id="item_shengji", name="生肌散", type=ItemType.CONSUMABLE, price=40, description="疗伤良药", effects={"hp": 60}),
            Item(id="item_dan", name="丹", type=ItemType.CONSUMABLE, price=100, description="珍贵丹药", effects={"hp": 150, "mp": 80}),
            Item(id="item_herb", name="草药", type=ItemType.CONSUMABLE, price=15, description="新鲜草药", effects={"hp": 30}),
            Item(id="item_potion_hp", name="金疮药", type=ItemType.CONSUMABLE, price=50, description="疗伤圣药", effects={"hp": 100}),
            Item(id="item_potion_mp", name="内力丹", type=ItemType.CONSUMABLE, price=80, description="恢复内力的丹药", effects={"mp": 50}),
            Item(id="item_water", name="清水", type=ItemType.CONSUMABLE, price=3, description="普通的清水", effects={}),
            Item(id="item_red_flower", name="红花", type=ItemType.CONSUMABLE, price=5, description="鲜艳的红花", effects={}),
            Item(id="item_tea_flower", name="茶花", type=ItemType.CONSUMABLE, price=8, description="美丽的茶花", effects={}),
            Item(id="item_fish", name="鱼", type=ItemType.CONSUMABLE, price=5, description="新鲜的鱼", effects={"hp": 15, "food": 20}),
            Item(id="item_blade", name="刀", type=ItemType.WEAPON, price=200, description="普通的刀", effects={"attack": 10}),
            Item(id="item_dagger", name="匕首", type=ItemType.WEAPON, price=150, description="锋利的匕首", effects={"attack": 8}),
            Item(id="item_whip", name="鞭", type=ItemType.WEAPON, price=180, description="皮鞭", effects={"attack": 9}),
            Item(id="item_long_sword", name="长剑", type=ItemType.WEAPON, price=250, description="铁制长剑", effects={"attack": 12}),
            Item(id="item_kitchen_knife", name="菜刀", type=ItemType.WEAPON, price=50, description="厨师的菜刀", effects={"attack": 6}),
            Item(id="item_gui_blade", name="鬼头刀", type=ItemType.WEAPON, price=800, description="凶悍的鬼头大刀", effects={"attack": 20}),
            Item(id="item_gold_blade", name="金刀", type=ItemType.WEAPON, price=1500, description="金光闪闪的宝刀", effects={"attack": 25}),
            Item(id="item_qingfeng_sword", name="清风剑", type=ItemType.WEAPON, price=2000, description="轻灵飘逸的宝剑", effects={"attack": 28}),
            Item(id="item_tie_sword", name="铁剑", type=ItemType.WEAPON, price=300, description="精铁打造的长剑", effects={"attack": 15}),
            Item(id="item_tie_guai", name="铁拐", type=ItemType.WEAPON, price=350, description="铁制拐杖", effects={"attack": 14}),
            Item(id="item_gang_zhang", name="钢杖", type=ItemType.WEAPON, price=400, description="精钢禅杖", effects={"attack": 16}),
            Item(id="item_hetun_blade", name="河豚刀", type=ItemType.WEAPON, price=1200, description="剧毒之刀", effects={"attack": 22}),
            Item(id="item_flower_whip", name="花鞭", type=ItemType.WEAPON, price=600, description="花间派独门软鞭", effects={"attack": 18}),
            Item(id="item_fuchen", name="拂尘", type=ItemType.WEAPON, price=500, description="道家拂尘", effects={"attack": 14}),
            Item(id="item_fan", name="扇子", type=ItemType.WEAPON, price=200, description="铁骨折扇", effects={"attack": 10}),
            Item(id="item_flower_fan", name="花扇", type=ItemType.WEAPON, price=800, description="花间派独门兵器", effects={"attack": 16}),
            Item(id="item_xiao", name="箫", type=ItemType.WEAPON, price=300, description="碧玉洞箫", effects={"attack": 12}),
            Item(id="item_needle", name="针", type=ItemType.WEAPON, price=100, description="银针暗器", effects={"attack": 8}),
            Item(id="item_rope", name="绳", type=ItemType.WEAPON, price=50, description="普通绳索", effects={"attack": 4}),
            Item(id="item_staff", name="杖", type=ItemType.WEAPON, price=250, description="木杖", effects={"attack": 10}),
            Item(id="item_chufe_sword", name="楚飞剑", type=ItemType.WEAPON, price=2500, description="名匠所铸宝剑", effects={"attack": 30}),
            Item(id="item_ningbi_sword", name="凝碧剑", type=ItemType.WEAPON, price=3000, description="碧绿如玉的宝剑", effects={"attack": 32}),
            Item(id="item_xi_jian", name="细剑", type=ItemType.WEAPON, price=1800, description="纤细锋利的剑", effects={"attack": 26}),
            Item(id="item_red_fuchen", name="红拂尘", type=ItemType.WEAPON, price=700, description="花间派拂尘", effects={"attack": 18}),
            Item(id="item_tulong", name="屠龙刀", type=ItemType.WEAPON, price=50000, description="号令天下的神兵", effects={"attack": 50}),
            Item(id="item_xiuhua", name="绣花针", type=ItemType.WEAPON, price=30000, description="看似普通却锋利无匹", effects={"attack": 45}),
            Item(id="item_cloth", name="布衣", type=ItemType.ARMOR, price=50, description="普通粗布衣服", effects={"defense": 5}),
            Item(id="item_fine_cloth", name="细布", type=ItemType.ARMOR, price=120, description="精制细布衣服", effects={"defense": 8}),
            Item(id="item_black_cloth", name="黑衣", type=ItemType.ARMOR, price=200, description="夜行衣", effects={"defense": 10}),
            Item(id="item_pink_cloth", name="粉衣", type=ItemType.ARMOR, price=150, description="粉色丝绸衣", effects={"defense": 7}),
            Item(id="item_night_cloth", name="夜行衣", type=ItemType.ARMOR, price=300, description="黑色夜行衣", effects={"defense": 12}),
            Item(id="item_taoist_cloth", name="道袍", type=ItemType.ARMOR, price=400, description="太极门道袍", effects={"defense": 15}),
            Item(id="item_martial_cloth", name="武服", type=ItemType.ARMOR, price=350, description="武士劲装", effects={"defense": 13}),
            Item(id="item_baipao", name="白袍", type=ItemType.ARMOR, price=500, description="雪白长袍", effects={"defense": 16}),
            Item(id="item_choupao", name="绸袍", type=ItemType.ARMOR, price=600, description="丝绸长袍", effects={"defense": 18}),
            Item(id="item_snow_baipao", name="雪山白袍", type=ItemType.ARMOR, price=800, description="雪山派独门白袍", effects={"defense": 22}),
            Item(id="item_pifeng", name="披风", type=ItemType.ARMOR, price=450, description="红莲教披风", effects={"defense": 14}),
            Item(id="item_gold_armor", name="金甲", type=ItemType.ARMOR, price=3000, description="金丝软甲", effects={"defense": 30}),
            Item(id="item_silver_armor", name="银甲", type=ItemType.ARMOR, price=2000, description="银丝软甲", effects={"defense": 25}),
            Item(id="item_xiangmo_pao", name="降魔袍", type=ItemType.ARMOR, price=1500, description="少林降魔袍", effects={"defense": 24}),
            Item(id="item_nihong_yuyi", name="霓虹羽衣", type=ItemType.ARMOR, price=5000, description="花间派至宝", effects={"defense": 35}),
            Item(id="item_baopi", name="豹皮", type=ItemType.ARMOR, price=300, description="雪豹皮甲", effects={"defense": 12}),
            Item(id="item_silk_cloth", name="丝绸", type=ItemType.ARMOR, price=250, description="上等丝绸衣", effects={"defense": 10}),
            Item(id="item_fancy_skirt", name="罗裙", type=ItemType.ARMOR, price=400, description="精美罗裙", effects={"defense": 12}),
            Item(id="item_skirt", name="裙子", type=ItemType.ARMOR, price=200, description="普通裙子", effects={"defense": 6}),
            Item(id="item_fcloth", name="女装", type=ItemType.ARMOR, price=350, description="精致女装", effects={"defense": 11}),
            Item(id="item_fshoes", name="丝鞋", type=ItemType.ARMOR, price=150, description="丝绸鞋", effects={"defense": 3}),
            Item(id="item_shoes", name="花鞋", type=ItemType.ARMOR, price=80, description="绣花鞋", effects={"defense": 2}),
            Item(id="item_beixin", name="背心", type=ItemType.ARMOR, price=100, description="皮背心", effects={"defense": 6}),
            Item(id="item_glasses", name="眼镜", type=ItemType.ARMOR, price=60, description="老花眼镜", effects={"defense": 1}),
            Item(id="item_eye_patch", name="眼罩", type=ItemType.ARMOR, price=50, description="黑色眼罩", effects={"defense": 1}),
            Item(id="item_hand_book", name="拳经", type=ItemType.BOOK, price=500, description="拳脚功夫秘籍", effects={}),
            Item(id="item_blade_book", name="刀谱", type=ItemType.BOOK, price=600, description="刀法秘籍", effects={}),
            Item(id="item_force_book", name="内功心法", type=ItemType.BOOK, price=800, description="内功修炼秘籍", effects={}),
            Item(id="item_yellow_paper", name="黄纸", type=ItemType.BOOK, price=100, description="泛黄的古纸", effects={}),
            Item(id="item_diaogan", name="钓竿", type=ItemType.MATERIAL, price=30, description="竹制钓竿", effects={}),
            Item(id="item_brush", name="毛笔", type=ItemType.MATERIAL, price=20, description="狼毫毛笔", effects={}),
            Item(id="item_yulou", name="鱼篓", type=ItemType.MATERIAL, price=25, description="竹编鱼篓", effects={}),
            Item(id="item_meijiu", name="美酒", type=ItemType.MATERIAL, price=50, description="陈年佳酿", effects={}),
            Item(id="item_baodian", name="宝典", type=ItemType.BOOK, price=5000, description="武林至宝，记载绝世武功", effects={}),
            Item(id="item_sanjiao", name="三角", type=ItemType.MATERIAL, price=15, description="铁制三角", effects={}),
            Item(id="item_skin_belt", name="皮带", type=ItemType.ARMOR, price=80, description="牛皮腰带", effects={"defense": 2}),
        ]
        self.items = {item.id: item for item in items}

    def _init_default_map(self):
        tiles = [[T_GRASS for _ in range(MAP_W)] for _ in range(MAP_H)]

        for x in range(MAP_W):
            tiles[39][x] = T_DIRT_ROAD
            tiles[40][x] = T_DIRT_ROAD
        for y in range(MAP_H):
            tiles[y][24] = T_DIRT_ROAD
            tiles[y][25] = T_DIRT_ROAD

        for y in range(20, 50):
            tiles[y][12] = T_STONE_ROAD
            tiles[y][13] = T_STONE_ROAD
        for y in range(20, 50):
            tiles[y][36] = T_STONE_ROAD
            tiles[y][37] = T_STONE_ROAD
        for x in range(12, 38):
            tiles[20][x] = T_STONE_ROAD
            tiles[21][x] = T_STONE_ROAD

        for y in range(MAP_H):
            tiles[y][0] = T_WATER
            tiles[y][1] = T_WATER
        tiles[39][0] = T_BRIDGE
        tiles[39][1] = T_BRIDGE
        tiles[40][0] = T_BRIDGE
        tiles[40][1] = T_BRIDGE

        for y in range(0, 4):
            for x in range(2, 7):
                tiles[y][x] = T_DOCK

        self._place_building(tiles, 5, 12, 4, 13, T_INN, 12, [8, 9], T_ROOF_RED)
        for y in range(9, 14):
            for x in range(4, 14):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_GARDEN
        tiles[10][8] = T_WELL
        tiles[11][10] = T_FLOWER_BED

        self._place_building(tiles, 5, 9, 16, 21, T_SHOP, 9, [18], T_ROOF_BLUE)
        self._place_building(tiles, 5, 12, 27, 34, T_SHOP, 12, [30, 31], T_ROOF_RED)
        self._place_building(tiles, 5, 9, 36, 41, T_SHOP, 9, [38], T_ROOF_BLUE)
        self._place_building(tiles, 5, 10, 42, 47, T_SHOP, 10, [44, 45], T_ROOF_RED)

        for y in range(0, 4):
            for x in range(8, 14):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST
        for y in range(0, 5):
            for x in range(42, 50):
                tiles[y][x] = T_HILL
        for y in range(2, 6):
            for x in range(38, 42):
                tiles[y][x] = T_WATER

        self._place_building(tiles, 15, 22, 4, 10, T_TEMPLE, 15, [7], T_ROOF_GOLD)
        tiles[18][7] = T_ALTAR
        tiles[20][7] = T_CARPET
        self._place_building(tiles, 15, 21, 16, 21, T_SHOP, 15, [18], T_ROOF_RED)
        self._place_building(tiles, 15, 21, 27, 34, T_SHOP, 15, [30, 31], T_ROOF_BLUE)
        tiles[18][30] = T_TABLE
        tiles[19][33] = T_CHEST
        self._place_building(tiles, 15, 21, 36, 41, T_SHOP, 15, [38], T_ROOF_RED)
        tiles[18][38] = T_ANVIL

        self._place_building(tiles, 24, 32, 4, 10, T_TEMPLE, 24, [7], T_ROOF_GOLD)
        tiles[28][7] = T_ALTAR
        for y in range(26, 31):
            tiles[y][7] = T_CARPET
        tiles[27][5] = T_BOOKSHELF
        tiles[27][9] = T_BOOKSHELF

        self._place_building(tiles, 24, 32, 16, 21, T_SHOP, 24, [18], T_ROOF_BLUE)
        self._place_building(tiles, 24, 32, 27, 34, T_SHOP, 24, [30, 31], T_ROOF_RED)
        tiles[28][30] = T_TRAINING
        tiles[28][32] = T_TRAINING
        tiles[30][33] = T_CHEST

        self._place_building(tiles, 24, 32, 36, 41, T_SHOP, 24, [38], T_ROOF_BLUE)
        tiles[28][38] = T_BOOKSHELF
        tiles[28][40] = T_TABLE

        for y in range(26, 30):
            for x in range(42, 48):
                tiles[y][x] = T_BAMBOO

        for y in range(33, 40):
            for x in range(4, 11):
                tiles[y][x] = T_DARK_GRASS
        for y in range(33, 40):
            for x in range(12, 18):
                tiles[y][x] = T_RICE_PADDY
        for y in range(33, 40):
            for x in range(22, 28):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_GARDEN
        tiles[36][24] = T_POND
        tiles[35][25] = T_FLOWER_BED

        tiles[25][25] = T_SIGN
        tiles[21][25] = T_SIGN
        tiles[37][25] = T_SIGN
        tiles[25][13] = T_SIGN
        tiles[25][37] = T_SIGN
        tiles[12][25] = T_CAMPFIRE
        tiles[32][25] = T_CAMPFIRE

        for y in range(5, 15):
            tiles[y][50] = T_STONE_ROAD
            tiles[y][51] = T_STONE_ROAD
        for y in range(5, 15):
            tiles[y][68] = T_STONE_ROAD
            tiles[y][69] = T_STONE_ROAD

        self._place_building(tiles, 5, 14, 54, 66, T_TEMPLE, 14, [59, 60], T_ROOF_RED)
        tiles[8][58] = T_TRAINING
        tiles[8][62] = T_TRAINING
        tiles[10][64] = T_CHEST
        tiles[12][58] = T_BANNER
        tiles[12][62] = T_BANNER

        for y in range(0, 5):
            for x in range(52, 68):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST
        for y in range(5, 15):
            for x in range(52, 68):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_DARK_GRASS

        for y in range(15, 28):
            tiles[y][50] = T_STONE_ROAD
            tiles[y][51] = T_STONE_ROAD
        for y in range(15, 28):
            tiles[y][68] = T_STONE_ROAD
            tiles[y][69] = T_STONE_ROAD

        self._place_building(tiles, 15, 28, 54, 66, T_TEMPLE, 15, [59, 60], T_ROOF_BLUE)
        tiles[18][58] = T_TRAINING
        tiles[18][62] = T_TRAINING
        tiles[20][64] = T_CHEST
        tiles[22][58] = T_FLOWER_BED
        tiles[22][62] = T_FLOWER_BED
        for y in range(16, 27):
            for x in range(54, 67):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_GARDEN
        tiles[24][60] = T_POND

        for y in range(28, 42):
            tiles[y][50] = T_STONE_ROAD
            tiles[y][51] = T_STONE_ROAD
        for y in range(28, 42):
            tiles[y][68] = T_STONE_ROAD
            tiles[y][69] = T_STONE_ROAD

        self._place_building(tiles, 28, 40, 54, 66, T_TEMPLE, 28, [59, 60], T_ROOF_RED)
        tiles[32][58] = T_TRAINING
        tiles[32][62] = T_TRAINING
        tiles[34][64] = T_CHEST
        tiles[36][58] = T_ALTAR
        tiles[36][62] = T_BANNER
        for y in range(30, 39):
            tiles[y][60] = T_CARPET

        for y in range(5, 15):
            tiles[y][74] = T_STONE_ROAD
            tiles[y][75] = T_STONE_ROAD
        for y in range(5, 15):
            tiles[y][90] = T_STONE_ROAD
            tiles[y][91] = T_STONE_ROAD

        self._place_building(tiles, 5, 14, 76, 88, T_TEMPLE, 14, [81, 82], T_ROOF_GOLD)
        tiles[8][80] = T_TRAINING
        tiles[8][84] = T_TRAINING
        tiles[10][86] = T_CHEST
        tiles[12][80] = T_TORCH
        tiles[12][84] = T_TORCH
        for y in range(6, 13):
            tiles[y][82] = T_CARPET

        for y in range(15, 28):
            tiles[y][74] = T_STONE_ROAD
            tiles[y][75] = T_STONE_ROAD
        for y in range(15, 28):
            tiles[y][90] = T_STONE_ROAD
            tiles[y][91] = T_STONE_ROAD

        self._place_building(tiles, 15, 28, 76, 88, T_TEMPLE, 15, [81, 82], T_ROOF_GOLD)
        tiles[18][80] = T_ALTAR
        tiles[18][84] = T_BOOKSHELF
        tiles[20][86] = T_CHEST
        tiles[22][80] = T_TORCH
        tiles[22][84] = T_TORCH
        for y in range(16, 27):
            tiles[y][82] = T_CARPET

        for y in range(35, 50):
            tiles[y][74] = T_STONE_ROAD
            tiles[y][75] = T_STONE_ROAD

        self._place_building(tiles, 35, 48, 76, 88, T_TEMPLE, 35, [81, 82], T_ROOF_RED)
        tiles[38][80] = T_TRAINING
        tiles[38][84] = T_TRAINING
        tiles[40][86] = T_CHEST
        tiles[42][80] = T_TORCH
        tiles[42][84] = T_TORCH
        for y in range(36, 47):
            for x in range(76, 89):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_SNOW

        for y in range(50, 60):
            for x in range(76, 90):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_SNOW
        for y in range(55, 60):
            for x in range(80, 88):
                tiles[y][x] = T_SNOW

        for y in range(42, 55):
            for x in range(40, 55):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_DARK_GRASS
        for y in range(45, 55):
            for x in range(45, 55):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST

        for y in range(55, 70):
            for x in range(40, 60):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST
        for y in range(60, 68):
            for x in range(45, 55):
                tiles[y][x] = T_CAVE

        for y in range(55, 70):
            for x in range(60, 75):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_HILL
        for y in range(62, 70):
            for x in range(65, 72):
                tiles[y][x] = T_SAND

        for y in range(68, 78):
            for x in range(40, 60):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST
        for y in range(70, 76):
            for x in range(44, 56):
                tiles[y][x] = T_RUIN

        for y in range(0, 5):
            for x in range(52, 58):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST
        for y in range(0, 5):
            for x in range(68, 76):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_FOREST

        for y in range(56, 60):
            for x in range(0, 8):
                tiles[y][x] = T_FOREST
        for y in range(56, 60):
            for x in range(92, 100):
                tiles[y][x] = T_FOREST

        for y in range(42, 50):
            for x in range(56, 66):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_DARK_GRASS
        for y in range(44, 50):
            for x in range(58, 64):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_MUSHROOM

        for y in range(42, 50):
            for x in range(90, 100):
                if tiles[y][x] == T_GRASS:
                    tiles[y][x] = T_SAND

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
        if self.game_hour == 8 and self.game_time > 3600:
            self.game_day += 1
        self.player.update_food_water(delta_time)
        self._update_npc_patrol(delta_time)

    def _update_npc_patrol(self, delta_time):
        import random
        for npc in self.npcs:
            if not hasattr(npc, '_patrol_timer'):
                npc._patrol_timer = random.uniform(0, 5)
                npc._patrol_origin = Position(npc.position.x, npc.position.y)
                npc._patrol_target = None
            npc._patrol_timer -= delta_time
            if npc._patrol_timer <= 0:
                npc._patrol_timer = random.uniform(3, 8)
                if npc.npc_type.value == "enemy":
                    radius = 60
                elif npc.npc_type.value == "master":
                    radius = 20
                else:
                    radius = 40
                ox, oy = npc._patrol_origin.x, npc._patrol_origin.y
                angle = random.uniform(0, 2 * math.pi)
                dist = random.uniform(0, radius)
                nx = ox + math.cos(angle) * dist
                ny = oy + math.sin(angle) * dist
                col = int(nx // TS)
                row = MAP_H - 1 - int(ny // TS)
                if 0 <= row < MAP_H and 0 <= col < MAP_W:
                    if self.current_map.tiles[row][col] in WALKABLE:
                        npc._patrol_target = Position(nx, ny)
            if npc._patrol_target:
                dx = npc._patrol_target.x - npc.position.x
                dy = npc._patrol_target.y - npc.position.y
                dist = math.sqrt(dx * dx + dy * dy)
                if dist > 2:
                    speed = 30 * delta_time
                    npc.position.x += (dx / dist) * speed
                    npc.position.y += (dy / dist) * speed
                else:
                    npc._patrol_target = None

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

    def get_nearby_npc(self, position: Position, radius: float = 80) -> Optional[NPC]:
        for npc in self.npcs:
            if npc.npc_type.value != "enemy" and npc.position.distance_to(position) <= radius:
                return npc
        return None

    def get_nearby_enemy(self, position: Position, radius: float = 80) -> Optional[NPC]:
        for npc in self.npcs:
            if npc.npc_type.value == "enemy" and npc.position.distance_to(position) <= radius:
                return npc
        return None

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
        col = int(wx // TS)
        row = MAP_H - 1 - int(wy // TS)
        if col < 0 or col >= MAP_W or row < 0 or row >= MAP_H:
            return False
        tid = self.current_map.tiles[row][col]
        return tid in WALKABLE
