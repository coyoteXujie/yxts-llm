from typing import Dict, List, Optional
from dataclasses import dataclass, field


@dataclass
class FactionLore:
    name: str
    history: str
    secret: str
    internal_conflict: str
    famous_technique: str
    founder_story: str
    current_crisis: str
    relationships: Dict[str, str] = field(default_factory=dict)


@dataclass
class CharacterLore:
    name: str
    faction: str
    background: str
    secret: str
    motivation: str
    famous_quote: str
    relationships: Dict[str, str] = field(default_factory=dict)


@dataclass
class LegendItem:
    name: str
    description: str
    history: str
    current_location: str
    power: str
    curse: str


@dataclass
class HistoricalEvent:
    name: str
    description: str
    year: str
    consequences: str
    related_factions: List[str] = field(default_factory=list)
    related_characters: List[str] = field(default_factory=list)


FACTION_LORES = {
    "bagua": FactionLore(
        name="八卦门",
        history=(
            "八卦门创于南宋末年，创始人董海川原为朝廷禁军教头，因不满朝廷腐败，"
            "携八卦掌法隐居山林。他以《易经》八卦之理融入武学，创出以柔克刚、"
            "以静制动的八卦掌法。门中弟子行走江湖，行侠仗义，被誉为'正道之盾'。"
            "然而门中一直流传着一个秘密——董海川当年并非自愿离朝，而是被卷入了一场宫廷阴谋..."
        ),
        secret=(
            "董海川当年护卫的，是一份记载前朝皇室宝藏的密图。这份密图被分成两半，"
            "一半藏在八卦门镇派之宝'混元珠'中，另一半下落不明。"
            "历代掌门只知道密图的存在，却从未找到过另一半。"
            "直到二十年前，有人声称发现了另一半密图的下落..."
        ),
        internal_conflict=(
            "掌门韦扬为人刚正，但大师兄简明暗中与朝廷有所往来，"
            "主张八卦门应重新为朝廷效力。二师兄简杰则坚持祖训，不与朝廷为伍。"
            "两派弟子暗中对立，门中暗流涌动。"
        ),
        famous_technique="混元一气——据说练至化境，可感应天地之气，预判对手招式",
        founder_story=(
            "董海川年轻时曾在皇宫中担任侍卫，亲眼目睹了靖康之耻的惨烈。"
            "他护送一位公主逃出皇宫，公主临终前将密图托付给他。"
            "此后他隐姓埋名，以卦象为号，创立八卦门。"
        ),
        current_crisis="简明近日频繁出入京城，门中弟子议论纷纷，有人说他已投靠朝廷",
        relationships={"taiji": "同源之谊", "honglian": "正邪对立", "flower": "互有往来"},
    ),
    "flower": FactionLore(
        name="花间派",
        history=(
            "花间派源于唐代，创始人公孙大娘是当时最负盛名的舞者。"
            "她将剑舞之美与杀伐之力融为一体，创出'花间剑舞'。"
            "花间派只收女弟子，门中武功以柔美见长，看似翩翩起舞，实则招招致命。"
            "江湖中流传：'花间一舞，百步之内无人可活。'"
        ),
        secret=(
            "花间派历代掌门都有一个不为人知的使命——守护一株'千年雪莲'。"
            "这株雪莲据说能起死回生，但每隔百年才会开花一次。"
            "开花之时，便是花间派最危险的时刻——无数人觊觎此花。"
            "现任掌门清照发现，雪莲已经开始发芽了..."
        ),
        internal_conflict=(
            "大弟子青红主张将雪莲献给朝廷，换取花间派的正统地位。"
            "隐娘则认为雪莲应留给天下苍生，而非一家一姓。"
            "清照左右为难，而雪莲开花的日期越来越近..."
        ),
        famous_technique="三花聚顶——以花为媒，聚天地灵气于一点，据说可令人脱胎换骨",
        founder_story=(
            "公孙大娘本是西域胡姬，被掳入长安为奴。"
            "她在宫中苦练剑舞，终于在一次宴会上以剑舞刺杀了暴虐的节度使，"
            "随后带着一群宫女逃出长安，在花间山建立了花间派。"
        ),
        current_crisis="雪莲即将开花，各方势力蠢蠢欲动，花间派面临前所未有的危机",
        relationships={"bagua": "互有往来", "taiji": "道法自然", "naja": "警惕提防"},
    ),
    "honglian": FactionLore(
        name="红莲教",
        history=(
            "红莲教并非邪教——至少最初不是。它起源于元末农民起义，"
            "创始人韩山童以'红莲'为号，号召天下受苦之人揭竿而起。"
            "起义失败后，残部退入深山，以'同击术'为核心武学，"
            "讲究众志成城、以弱胜强。门中弟子多为底层百姓，对权贵深恶痛绝。"
        ),
        secret=(
            "红莲教真正的镇教之宝不是武功，而是一份'万民书'——"
            "上面按着当年十万起义军的血手印，记载着每一位牺牲者的名字和遗愿。"
            "这份万民书是红莲教存在的根基，也是历代教主誓死守护之物。"
            "但二十年前，万民书被人偷走了一页..."
        ),
        internal_conflict=(
            "教主于红儒主张'以暴制暴'，认为只有推翻现有秩序才能拯救苍生。"
            "方长老则主张'以德服人'，认为滥杀无辜只会让红莲教沦为真正的邪教。"
            "两派之争在教中愈演愈烈，而韩长老——原朝廷命官——似乎另有图谋..."
        ),
        famous_technique="同击术——多人合力，功力叠加，据说百人同击可碎山裂石",
        founder_story=(
            "韩山童本是一介农夫，因不堪元朝暴政，在红莲寺中歃血为盟，"
            "率十万义军揭竿而起。起义失败后，他在绝境中悟出'同击术'——"
            "'一人之力有限，万人之力无穷。'这是他留给后人最后的遗言。"
        ),
        current_crisis="韩长老暗中联络朝廷，方长老发现后惨遭暗杀未遂，教中人心惶惶",
        relationships={"bagua": "正邪对立", "naja": "暗中合作", "xueshan": "互不相犯"},
    ),
    "naja": FactionLore(
        name="那迦派",
        history=(
            "那迦派源自东瀛，创始人是一位日本浪人，名叫藤原信纲。"
            "他在明初渡海来华，本是为了一部失传的兵法，却在中原武林中发现了更深的秘密。"
            "那迦派以忍术为核心，讲究隐忍、精准、一击必杀。"
            "门中弟子行事诡秘，不与中原武林往来，被江湖中人视为'异类'。"
        ),
        secret=(
            "藤原信纲来华的真正目的，是寻找传说中的'天照镜'——"
            "一面据说能映照未来的神镜。他相信天照镜就在中原某处。"
            "历代掌门都在暗中寻找天照镜，而现任掌门钟央似乎已经找到了线索..."
        ),
        internal_conflict=(
            "十三卫是那迦派中最强的忍者，但他对钟央的忠诚正在动摇。"
            "他发现钟央与中原朝廷有秘密交易，似乎在出卖那迦派的利益。"
            "美奈子则暗中调查十三卫的异常行为，门中疑云密布。"
        ),
        famous_technique="忍术——隐身、替身、幻术，据说练至化境可'分身有术'",
        founder_story=(
            "藤原信纲本是日本幕府的忍者，因任务失败被追杀。"
            "他逃到中原，被一位少林僧人救下。僧人告诉他：'忍，不是逃避，而是等待。'"
            "信纲深受启发，在那迦山建立门派，以'那迦'（龙神）为名，寓意蛰伏与觉醒。"
        ),
        current_crisis="钟央近日频繁出入京城，十三卫怀疑他已投靠朝廷，暗中联络门中弟子准备'清门'",
        relationships={"flower": "警惕提防", "honglian": "暗中合作", "taiji": "井水不犯河水"},
    ),
    "taiji": FactionLore(
        name="太极门",
        history=(
            "太极门是中原武林中历史最悠久的门派之一，创始人张三丰的传说家喻户晓。"
            "但鲜为人知的是，太极门真正的起源比张三丰更早——"
            "它源于武当山上一个更古老的道派，据说传承自先秦时期的方士。"
            "太极门以'道法自然'为宗旨，武功讲究以柔克刚、以慢打快。"
        ),
        secret=(
            "太极门地下藏有一座'太极古墓'，墓中据说埋藏着先秦方士的遗物——"
            "一部记载长生之术的《太一经》。历代掌门都知道古墓的存在，"
            "但祖训严禁开启。然而，古松道人近日发现古墓的封印出现了裂痕..."
        ),
        internal_conflict=(
            "清虚道人德高望重，但他有一个不为人知的秘密——他并非张三丰的嫡传弟子。"
            "真正的嫡传弟子在二十年前的一场大火中失踪，清虚是旁支接任的。"
            "古松道人是当年那场大火的唯一幸存者，他知道真相，却选择了沉默。"
        ),
        famous_technique="太极功——以意导气，以气运劲，据说练至化境可'四两拨千斤'",
        founder_story=(
            "张三丰少年时曾在少林寺学艺，后因不满少林寺的门户之见而出走。"
            "他在武当山观蛇鹤相争，悟出'以柔克刚'之理，创出太极拳法。"
            "但更深的真相是——他在武当山发现了一座古墓，从中得到了先秦方士的传承。"
        ),
        current_crisis="太极古墓封印裂痕扩大，古墓中似乎有异动，弟子们夜间常听到地下传来异响",
        relationships={"bagua": "同源之谊", "flower": "道法自然", "naja": "井水不犯河水"},
    ),
    "xueshan": FactionLore(
        name="雪山派",
        history=(
            "雪山派位于极北雪峰之上，创始人白万剑是中原人，因家族惨遭灭门，"
            "只身逃入雪山，在绝境中悟出'寒冰剑意'。"
            "雪山派弟子常年与严寒为伴，武功以寒冰之气为核心，"
            "招式凌厉如风雪，令人不寒而栗。"
        ),
        secret=(
            "白万剑家族被灭门的真相——凶手并非江湖中人，而是当朝宰相。"
            "白万剑逃入雪山后，发现了一份记载宰相通敌卖国的证据。"
            "这份证据就藏在雪山派的'冰封密室'中，历代掌门誓要等到时机成熟时公之于众。"
        ),
        internal_conflict=(
            "白瑞德是白万剑的后人，他一心想为家族报仇，但史婆婆认为复仇只会带来更多杀戮。"
            "大弟子万剑支持白瑞德，但二弟子万刃暗中与朝廷有所往来——"
            "他已被宰相收买，准备偷出密室中的证据销毁。"
        ),
        famous_technique="雪上霜——以内力凝结寒霜，据说练至化境可'一剑霜寒十四州'",
        founder_story=(
            "白万剑本是书香门第之后，父亲是朝廷命官。"
            "宰相为掩盖通敌之罪，灭白家满门。白万剑年仅十三，被忠仆藏在枯井中逃过一劫。"
            "他一路北逃，在雪山中差点冻死，却在生死之间悟出了'寒冰剑意'。"
        ),
        current_crisis="万刃近日行为反常，多次深夜出入冰封密室，白瑞德已开始怀疑",
        relationships={"honglian": "互不相犯", "xiaoyao": "远亲之谊", "bagua": "敬而远之"},
    ),
    "xiaoyao": FactionLore(
        name="逍遥派",
        history=(
            "逍遥派是江湖中最神秘的门派，没有人知道它的确切位置。"
            "传说创始人逍遥子是一位游历天下的奇人，他博采众长，"
            "将天下各派武学精华融会贯通，创出'逍遥游'心法。"
            "逍遥派弟子行走江湖，不问是非，不涉恩怨，看似逍遥自在，"
            "实则每个人都背负着不为人知的过去。"
        ),
        secret=(
            "逍遥子并非一个人，而是一个身份——每一代逍遥派掌门都叫'逍遥子'。"
            "真正的逍遥子是三百年前的一位大内密探，他奉命潜伏江湖，"
            "却在江湖中找到了真正的自由。他背叛了朝廷，创立了逍遥派。"
            "但朝廷从未放弃追杀——每一代逍遥子都在暗中与朝廷的密探斗争。"
        ),
        internal_conflict=(
            "现任逍遥子（即大侠）一直在暗中保护门派，但他发现了一个可怕的事实——"
            "朝廷的密探已经渗透到了逍遥派的核心。他不知道叛徒是谁，"
            "甚至不确定自己身边的人是否可信。"
        ),
        famous_technique="北冥神功——吸取他人内力为己用，据说练至化境可'吸尽天下内力'",
        founder_story=(
            "初代逍遥子本名已不可考，他原是大内密探头领，代号'影子'。"
            "他奉命潜伏江湖，刺探各派情报。但在江湖中，他第一次感受到了自由的滋味。"
            "他最终选择了背叛朝廷，带着搜集到的所有情报消失在了江湖中。"
            "那些情报，至今仍是逍遥派最大的底牌。"
        ),
        current_crisis="大侠发现门中有人与朝廷密探联络，但无法确定叛徒身份，人人自危",
        relationships={"xueshan": "远亲之谊", "flower": "惺惺相惜", "honglian": "暗中支持"},
    ),
}

CHARACTER_LORES = {
    "韦扬": CharacterLore(
        name="韦扬", faction="bagua",
        background="八卦门掌门，为人刚正不阿，但内心藏着对先师的愧疚",
        secret="他知道密图的秘密，但从未告诉任何人——包括他的弟子",
        motivation="守护八卦门，等待密图另一半出现的时机",
        famous_quote="八卦之道，在于知止。不知止，则祸至。",
        relationships={"简明": "师徒，但已生嫌隙", "清虚道人": "故交"},
    ),
    "简明": CharacterLore(
        name="简明", faction="bagua",
        background="八卦门大师兄，武艺高强，但野心勃勃",
        secret="他已暗中投靠朝廷，密谋夺取掌门之位",
        motivation="他认为八卦门只有依附朝廷才能生存",
        famous_quote="天下大势，顺之者昌，逆之者亡。",
        relationships={"韦扬": "师徒，但已生嫌隙", "朝廷": "暗中效忠"},
    ),
    "清照": CharacterLore(
        name="清照", faction="flower",
        background="花间派掌门，外表清冷，内心温柔，对弟子如母如姐",
        secret="她已活了一百二十岁，靠的是雪莲的一瓣——但她从未告诉任何人",
        motivation="守护雪莲，守护花间派，等待雪莲开花之日",
        famous_quote="花开花落自有时，人来人往皆因缘。",
        relationships={"青红": "师徒，理念不合", "隐娘": "师徒，最信任的人"},
    ),
    "于红儒": CharacterLore(
        name="于红儒", faction="honglian",
        background="红莲教教主，出身贫苦，对权贵恨之入骨",
        secret="他的家人就是二十年前万民书被偷时牺牲的守卫者",
        motivation="找回万民书缺失的那一页，为家人报仇",
        famous_quote="天下苦人，皆我兄弟姐妹！",
        relationships={"方长老": "战友，但理念不合", "韩长老": "不信任"},
    ),
    "钟央": CharacterLore(
        name="钟央", faction="naja",
        background="那迦派掌门，沉默寡言，行事如风",
        secret="他已找到天照镜的线索，但代价是与朝廷达成交易",
        motivation="找到天照镜，完成历代掌门的夙愿",
        famous_quote="忍者，隐而不发，待时而动。",
        relationships={"十三卫": "最信任的部下，但已生疑心", "朝廷": "暗中交易"},
    ),
    "清虚道人": CharacterLore(
        name="清虚道人", faction="taiji",
        background="太极门掌门，仙风道骨，但内心有愧",
        secret="他不是嫡传弟子，真正嫡传弟子在二十年前的大火中失踪",
        motivation="守护太极门，弥补当年的过错",
        famous_quote="道法自然，无为而治。",
        relationships={"古松道人": "知道他秘密的人", "失踪的嫡传": "愧疚"},
    ),
    "白瑞德": CharacterLore(
        name="白瑞德", faction="xueshan",
        background="雪山派掌门，冷峻如冰，但内心燃烧着复仇之火",
        secret="他已找到当年灭门惨案的证据，但史婆婆阻止他复仇",
        motivation="为家族报仇，公布宰相通敌的证据",
        famous_quote="雪山顶上，只有两种人——活人和死人。",
        relationships={"史婆婆": "夫妻，但理念不合", "万刃": "师徒，但已生疑"},
    ),
    "大侠": CharacterLore(
        name="大侠", faction="xiaoyao",
        background="逍遥派掌门（逍遥子），行踪不定，看似逍遥，实则肩负重任",
        secret="他是当代逍遥子，背负着三百年前初代逍遥子的遗愿——对抗朝廷密探",
        motivation="找出门中的叛徒，保护逍遥派的秘密",
        famous_quote="逍遥天地间，何处不江湖？",
        relationships={"神秘人": "孪生兄弟，被屠龙刀腐蚀", "朝廷密探": "宿敌"},
    ),
    "神秘人": CharacterLore(
        name="神秘人", faction="none",
        background="大侠的孪生兄弟，原名已不可考，被屠龙刀的力量腐蚀了二十年",
        secret="他就是二十年前偷走万民书、制造太极门大火、盗取各门派碎片的人",
        motivation="重铸屠龙刀，以绝对力量终结江湖纷争——哪怕代价是自己的灵魂",
        famous_quote="这世上没有正邪，只有强弱。",
        relationships={"大侠": "孪生兄弟，生死相搏", "血月教": "幕后操纵者"},
    ),
    "绣花女": CharacterLore(
        name="绣花女", faction="none",
        background="来历不明的神秘女子，以绣花针为武器，兼修太极和花间武功",
        secret="她是二十年前太极门大火中失踪的嫡传弟子——清虚道人的师妹",
        motivation="她要找出当年大火的真相，为死去的师父报仇",
        famous_quote="这根针，穿得了丝绸，也穿得了咽喉。",
        relationships={"清虚道人": "师兄妹，但她认为他背叛了师父", "清照": "亦师亦友"},
    ),
    "道德和尚": CharacterLore(
        name="道德和尚", faction="none",
        background="少林高僧，善恶一念间，看似慈悲，实则内心挣扎",
        secret="他当年参与了围剿血月教的行动，知道各大门派分赃碎片的真相",
        motivation="赎罪——他要用余生来弥补当年的过错",
        famous_quote="善恶一念间，放下屠刀，立地成佛。",
        relationships={"神秘人": "知道他的真实身份", "各大掌门": "共同保守秘密"},
    ),
    "李白": CharacterLore(
        name="李白", faction="none",
        background="诗仙剑客，剑法超群，看似洒脱，实则心怀天下",
        secret="他是朝廷安插在江湖中的眼线——但他早已背叛了朝廷",
        motivation="在江湖与朝廷之间寻找平衡，阻止更大规模的冲突",
        famous_quote="十步杀一人，千里不留行。",
        relationships={"大侠": "挚友", "朝廷": "已背叛"},
    ),
}

LEGEND_ITEMS = {
    "tulong": LegendItem(
        name="屠龙刀",
        description="号令天下的神兵，据说持有者可一统江湖",
        history=(
            "屠龙刀原为前朝皇室所铸，以天外陨铁为材，融入了铸剑师的毕生心血。"
            "元末天下大乱，屠龙刀流落江湖，引发了无数血腥争夺。"
            "二十年前，各大门派联手击败了持刀的血月教主，"
            "但无人能驾驭此刀，最终将其打碎，碎片分由各派保管。"
        ),
        current_location="碎片分散于七大门派之中",
        power="持刀者内力倍增，但心智会被刀中魔性侵蚀",
        curse="历代持刀者无一善终——刀的力量会放大持有者的欲望，直到吞噬其灵魂",
    ),
    "xiuhua": LegendItem(
        name="绣花针",
        description="看似普通却锋利无匹的暗器",
        history=(
            "绣花针原是花间派创始人公孙大娘的贴身之物，"
            "她以绣花针为暗器，百步之内取人首级。"
            "后来绣花针传给了太极门嫡传弟子，她在二十年前的大火中带着绣花针失踪。"
            "如今，绣花针再次出现在江湖中——持针者正是绣花女。"
        ),
        current_location="绣花女手中",
        power="以针代剑，可施展太极和花间两派武功，威力倍增",
        curse="绣花针会逐渐消磨使用者的情感，使其变得冷酷无情",
    ),
    "wanminshu": LegendItem(
        name="万民书",
        description="红莲教镇教之宝，十万起义军的血手印",
        history=(
            "万民书是红莲教存在的根基，上面按着十万起义军的血手印。"
            "每一个手印都代表一条牺牲的生命，每一个名字都承载着一份遗愿。"
            "二十年前，万民书被人偷走了一页——那一页上按着的是韩山童本人的手印。"
        ),
        current_location="红莲教总坛（缺失一页）",
        power="万民书本身无武力，但它是红莲教号召力的根源",
        curse="守护万民书的人会不断被过去的亡魂纠缠，夜不能寐",
    ),
    "tianzhaojing": LegendItem(
        name="天照镜",
        description="据说能映照未来的神镜",
        history=(
            "天照镜是日本皇室的三大神器之一，传说中它能映照出未来的景象。"
            "数百年前，天照镜在一次战乱中失踪，流落到了中原。"
            "那迦派创始人藤原信纲正是为了寻找天照镜才来到中原。"
        ),
        current_location="下落不明，钟央似乎已找到线索",
        power="据说能映照未来，但每次使用都会消耗使用者的寿命",
        curse="映照的越远，代价越大——有传言说上一位使用者已经'看到了自己的死期'",
    ),
}

HISTORICAL_EVENTS = [
    HistoricalEvent(
        name="靖康之变",
        description="金兵南下，北宋灭亡。董海川护卫公主逃出皇宫，公主临终托付密图",
        year="约120年前",
        consequences="八卦门创立，密图成为门中最大秘密",
        related_factions=["bagua"],
        related_characters=["董海川"],
    ),
    HistoricalEvent(
        name="红莲起义",
        description="韩山童率十万义军揭竿而起，最终失败",
        year="约80年前",
        consequences="红莲教成立，万民书成为镇教之宝",
        related_factions=["honglian"],
        related_characters=["韩山童"],
    ),
    HistoricalEvent(
        name="屠龙刀之乱",
        description="血月教主持屠龙刀横行江湖，各大门派联手围剿",
        year="20年前",
        consequences="屠龙刀被打碎，碎片分由各派保管；血月教覆灭；太极门大火；万民书被偷",
        related_factions=["bagua", "flower", "honglian", "naja", "taiji", "xueshan", "xiaoyao"],
        related_characters=["神秘人", "道德和尚", "清虚道人", "绣花女"],
    ),
    HistoricalEvent(
        name="太极门大火",
        description="太极门嫡传弟子在一场神秘大火中失踪，清虚道人接任掌门",
        year="20年前",
        consequences="太极门嫡传断绝；清虚道人心中有愧；绣花女（嫡传弟子）幸存但下落不明",
        related_factions=["taiji"],
        related_characters=["清虚道人", "绣花女", "古松道人"],
    ),
    HistoricalEvent(
        name="万民书失窃",
        description="红莲教镇教之宝万民书被偷走一页，守卫者全部牺牲",
        year="20年前",
        consequences="于红儒家人牺牲；红莲教人心不稳；韩长老暗中投靠朝廷",
        related_factions=["honglian"],
        related_characters=["于红儒", "韩长老"],
    ),
]


def get_faction_lore(faction_key: str) -> Optional[FactionLore]:
    return FACTION_LORES.get(faction_key)


def get_character_lore(name: str) -> Optional[CharacterLore]:
    return CHARACTER_LORES.get(name)


def get_legend_item(item_key: str) -> Optional[LegendItem]:
    return LEGEND_ITEMS.get(item_key)


def get_historical_events() -> List[HistoricalEvent]:
    return HISTORICAL_EVENTS


def get_all_lore_summary() -> Dict:
    return {
        "factions": {k: v.name for k, v in FACTION_LORES.items()},
        "characters": {k: v.name for k, v in CHARACTER_LORES.items()},
        "legend_items": {k: v.name for k, v in LEGEND_ITEMS.items()},
        "historical_events": [e.name for e in HISTORICAL_EVENTS],
    }


def get_faction_relationship(faction1: str, faction2: str) -> str:
    lore = FACTION_LORES.get(faction1)
    if lore:
        return lore.relationships.get(faction2, "无特别关系")
    return "无特别关系"


def get_rumors_for_npc(npc_name: str, player_faction: str = "") -> List[str]:
    rumors = []
    for char_name, lore in CHARACTER_LORES.items():
        if char_name == npc_name:
            continue
        if npc_name in lore.relationships:
            relation = lore.relationships[npc_name]
            if "嫌隙" in relation or "不信任" in relation or "疑" in relation:
                rumors.append(f"听说{char_name}和{npc_name}之间似乎有些不对劲...")
            if "师徒" in relation:
                rumors.append(f"{char_name}和{npc_name}是师徒关系。")
            if "夫妻" in relation:
                rumors.append(f"{char_name}和{npc_name}是夫妻。")

    for event in HISTORICAL_EVENTS:
        if npc_name in event.related_characters:
            rumors.append(f"二十年前的那场大事，{npc_name}似乎也牵涉其中...")

    for item_key, item in LEGEND_ITEMS.items():
        if npc_name in item.history:
            rumors.append(f"有传言说，{item.name}和{npc_name}有些渊源...")

    if player_faction:
        faction_lore = FACTION_LORES.get(player_faction)
        if faction_lore and faction_lore.current_crisis:
            rumors.append(faction_lore.current_crisis)

    return rumors[:5]
