import json
import os
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum


class StoryChapter(Enum):
    PROLOGUE = "prologue"
    CHAPTER1 = "chapter1"
    CHAPTER2 = "chapter2"
    CHAPTER3 = "chapter3"
    CHAPTER4 = "chapter4"
    CHAPTER5 = "chapter5"
    EPILOGUE = "epilogue"


class StoryNodeType(Enum):
    DIALOGUE = "dialogue"
    COMBAT = "combat"
    EXPLORE = "explore"
    CHOICE = "choice"
    QUEST = "quest"
    FACTION_JOIN = "faction_join"
    FACTION_PROMOTE = "faction_promote"
    BOSS_FIGHT = "boss_fight"
    REVELATION = "revelation"
    ENDING = "ending"
    NARRATION = "narration"
    ANNOUNCEMENT = "announcement"
    RESOLUTION = "resolution"


@dataclass
class StoryChoice:
    text: str
    next_node: str
    morality_change: int = 0
    faction_change: Dict[str, int] = field(default_factory=dict)
    requirement: Optional[Dict] = None


@dataclass
class StoryNode:
    id: str
    chapter: str
    title: str
    node_type: StoryNodeType
    speaker: str = ""
    dialogue: str = ""
    choices: List[StoryChoice] = field(default_factory=list)
    next_node: Optional[str] = None
    target_npc: Optional[str] = None
    target_area: Optional[str] = None
    combat_enemy: Optional[str] = None
    reward: Dict = field(default_factory=dict)
    requirement: Optional[Dict] = None
    on_complete: Optional[str] = None
    morality_requirement: Optional[int] = None
    faction_requirement: Optional[str] = None
    level_requirement: int = 1


@dataclass
class StoryState:
    current_chapter: str = "prologue"
    current_node: str = "prologue_1"
    completed_nodes: List[str] = field(default_factory=list)
    story_flags: Dict[str, bool] = field(default_factory=dict)
    choices_made: Dict[str, str] = field(default_factory=dict)
    chapter_completed: List[str] = field(default_factory=list)


class StoryEngine:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._nodes: Dict[str, StoryNode] = {}
            cls._instance._state = StoryState()
            cls._instance._loaded = False
            cls._instance._on_story_event = None
        return cls._instance

    def set_story_event_callback(self, callback: Callable):
        self._on_story_event = callback

    def load_story(self):
        if self._loaded:
            return
        self._build_main_story()
        self._loaded = True

    def _build_main_story(self):
        nodes = []

        nodes.extend(self._build_prologue())
        nodes.extend(self._build_chapter1())
        nodes.extend(self._build_chapter2())
        nodes.extend(self._build_chapter3())
        nodes.extend(self._build_chapter4())
        nodes.extend(self._build_chapter5())
        nodes.extend(self._build_epilogue())

        for node in nodes:
            self._nodes[node.id] = node

    def _build_prologue(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="prologue_1", chapter="prologue", title="风雨平安镇",
                node_type=StoryNodeType.DIALOGUE,
                speaker="村长", dialogue=(
                    "年轻人，你终于醒了。昨夜风雨大作，你倒在镇外官道上，浑身是伤。\n"
                    "是我让捕快把你抬回来的。你叫什么名字？从哪里来？\n"
                    "...罢了，看你这身打扮，怕是又是一个被江湖风波卷进来的苦命人。\n\n"
                    "如今天下不太平。二十年前那场屠龙刀之乱后，江湖看似平静，实则暗流涌动。\n"
                    "各门各派表面和气，私下里却勾心斗角。朝廷也盯上了江湖，到处安插眼线。\n"
                    "你若要在这江湖中活下去，就得学些本事。"
                ),
                next_node="prologue_2"
            ),
            StoryNode(
                id="prologue_2", chapter="prologue", title="初识江湖",
                node_type=StoryNodeType.DIALOGUE,
                speaker="村长", dialogue=(
                    "镇上有不少能人异士。老夫子教人读书识字，大侠传授剑法，道德和尚修禅悟道。\n"
                    "对了，还有个卖豆腐的阿青——别看她只是个卖豆腐的，她的剑法...啧啧。\n\n"
                    "不过你要小心，镇外也不太平。流氓、大盗、黑衣人，越来越多了。\n"
                    "有人说，是二十年前那场乱子的余波还没平息...\n"
                    "你先在镇上安顿下来，学些防身之术吧。"
                ),
                next_node="prologue_3"
            ),
            StoryNode(
                id="prologue_3", chapter="prologue", title="路见不平",
                node_type=StoryNodeType.COMBAT,
                speaker="阿青", dialogue=(
                    "救命啊——！这些流氓抢我的豆腐！\n"
                    "别看我只是卖豆腐的，我...我也能打！\n"
                    "但是他们人太多了...少侠，你能帮帮我吗？"
                ),
                target_npc="流氓", combat_enemy="流氓",
                next_node="prologue_4", reward={"exp": 30, "money": 50, "daode": 5}
            ),
            StoryNode(
                id="prologue_4", chapter="prologue", title="豆腐西施",
                node_type=StoryNodeType.DIALOGUE,
                speaker="阿青", dialogue=(
                    "多谢少侠出手相救！我阿青虽然只是个卖豆腐的，但也知道知恩图报。\n"
                    "这笼豆腐送你——对了，你刚来镇上，我告诉你一些事吧。\n\n"
                    "二十年前，江湖上出了一件大事。有个叫'血月教'的邪派，\n"
                    "他们的教主得到了一把叫'屠龙刀'的神兵，横行天下，无人能挡。\n"
                    "后来七大派联手才把他打败，但屠龙刀太危险了，没人能驾驭，\n"
                    "最后只能把它打碎，碎片分给各派保管。\n\n"
                    "但最近...镇上来了很多陌生人，总觉得又要出事了。"
                ),
                next_node="prologue_5"
            ),
            StoryNode(
                id="prologue_5", chapter="prologue", title="月下剑影",
                node_type=StoryNodeType.DIALOGUE,
                speaker="大侠", dialogue=(
                    "你刚才那一战，我看到了。不错，有胆识。\n\n"
                    "我姓什么不重要，江湖上的人都叫我'大侠'——虽然我觉得自己配不上这个称呼。\n"
                    "我正在追查一件事：最近江湖上出现了很多黑衣人，\n"
                    "他们似乎在寻找屠龙刀碎片的下落。更蹊跷的是——\n"
                    "他们用的武功，竟然兼通各派之长。这不可能，除非...\n\n"
                    "除非有人在暗中收集各派武学。\n\n"
                    "你若有意，可以加入门派深造。各派虽然各有心思，\n"
                    "但学些本事总是好的。等你入了门派，回来找我，\n"
                    "我有更重要的事要告诉你。"
                ),
                next_node="prologue_6"
            ),
            StoryNode(
                id="prologue_6", chapter="prologue", title="踏上征途",
                node_type=StoryNodeType.QUEST,
                speaker="大侠", dialogue=(
                    "去吧，去各门派看看。八卦门在西北，花间派在正南，\n"
                    "红莲教在东南，那迦派在东北，太极门在正北，雪山派在西北雪峰。\n"
                    "每个门派都有自己的故事和秘密，选择一个适合你的。\n\n"
                    "记住：门派只是起点，不是终点。真正的高手，不拘一格。\n"
                    "还有——小心你身边的人。这江湖中，最危险的不是敌人，\n"
                    "而是你以为可以信任的人。"
                ),
                next_node="chapter1_1",
                on_complete="prologue_done",
                requirement={"faction": "any"}
            ),
        ]

    def _build_chapter1(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="chapter1_1", chapter="chapter1", title="门中暗流",
                node_type=StoryNodeType.DIALOGUE,
                speaker="大侠", dialogue=(
                    "你已加入门派，很好。但我有一事相告——\n\n"
                    "近日江湖上出现了许多黑衣人，他们武功诡异，兼通各派之长。\n"
                    "我追查已久，发现他们与二十年前被剿灭的'血月教'有关。\n"
                    "但更让我不安的是——这些黑衣人似乎对各派的内情了如指掌。\n\n"
                    "这意味着...各派之中，有内鬼。"
                ),
                next_node="chapter1_2", level_requirement=5
            ),
            StoryNode(
                id="chapter1_2", chapter="chapter1", title="黑衣人现身",
                node_type=StoryNodeType.COMBAT,
                speaker="黑衣大盗", dialogue=(
                    "哼，又一个多管闲事的。\n"
                    "你以为你那点三脚猫的功夫能挡住我？\n"
                    "我劝你识相点，别管不该管的事！\n\n"
                    "...等等，你身上的气息...有意思。"
                ),
                combat_enemy="黑衣大盗", target_npc="黑衣大盗",
                next_node="chapter1_3", reward={"exp": 100, "money": 200}
            ),
            StoryNode(
                id="chapter1_3", chapter="chapter1", title="密信之谜",
                node_type=StoryNodeType.DIALOGUE,
                speaker="大侠", dialogue=(
                    "你从黑衣人身上搜到了一封信？让我看看...\n\n"
                    "'碎片分散于七大门派之中，集齐碎片者可重铸神兵。\n"
                    "第三块碎片已得，第四块指日可待。'\n\n"
                    "他们已经在收集碎片了！而且——'第三块碎片已得'，\n"
                    "这意味着已经有两个门派的碎片被盗了！\n\n"
                    "更可怕的是这封信的笔迹...我好像在哪里见过。\n"
                    "不，不可能...那个人已经死了二十年了。\n\n"
                    "你先回门派，努力修炼，提升你在门派中的地位。\n"
                    "只有成为核心弟子，掌门才会告诉你碎片的秘密。\n"
                    "我们必须抢在黑衣人之前保护好碎片！"
                ),
                next_node="chapter1_4"
            ),
            StoryNode(
                id="chapter1_4", chapter="chapter1", title="门派升阶",
                node_type=StoryNodeType.FACTION_PROMOTE,
                speaker="大侠", dialogue=(
                    "回到门派，努力修炼吧。门派试炼不仅考验武功，更考验心性。\n\n"
                    "对了，我查了一下那封信的笔迹——\n"
                    "它和二十年前血月教主的笔迹...一模一样。\n"
                    "但血月教主当年明明已经死了，七大派掌门亲眼确认的。\n\n"
                    "除非...当年死的不是他本人。\n"
                    "这个念头让我不寒而栗。"
                ),
                next_node="chapter2_1",
                on_complete="chapter1_done",
                requirement={"faction_rank": "core_disciple"}
            ),
        ]

    def _build_chapter2(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="chapter2_1", chapter="chapter2", title="掌门之秘",
                node_type=StoryNodeType.DIALOGUE,
                speaker="掌门", dialogue=(
                    "你已证明了自己的忠诚，是时候告诉你一个秘密了。\n\n"
                    "我门中确实藏有一块屠龙刀碎片，代代相传，由掌门亲自守护。\n"
                    "但近日，我发现有人在暗中窥探碎片——此人竟是我门中之人！\n\n"
                    "更让我心寒的是，此人与二十年前的那场大火有关。\n"
                    "太极门的大火、红莲教万民书的失窃、碎片的被盗...都是同一个人干的。\n"
                    "而这个人——我以为他早就死了。"
                ),
                next_node="chapter2_2", level_requirement=10
            ),
            StoryNode(
                id="chapter2_2", chapter="chapter2", title="内鬼追踪",
                node_type=StoryNodeType.CHOICE,
                speaker="掌门", dialogue="你打算如何追查内鬼？这关系到整个门派的安危。",
                choices=[
                    StoryChoice(text="暗中调查，不打草惊蛇——知己知彼，百战不殆", next_node="chapter2_3a", morality_change=5),
                    StoryChoice(text="当众质问，逼内鬼现身——光明正大，方为正道", next_node="chapter2_3b", morality_change=-5),
                ]
            ),
            StoryNode(
                id="chapter2_3a", chapter="chapter2", title="暗中调查",
                node_type=StoryNodeType.EXPLORE,
                speaker="掌门", dialogue=(
                    "好，你暗中调查。我给你三天的期限。\n\n"
                    "注意门中弟子近日的异常举动，尤其是深夜出入之人。\n"
                    "还有——注意那些与外人来往频繁的弟子。\n"
                    "二十年前，就是有人被收买，才导致了那场灾难。"
                ),
                target_area="faction_hall",
                next_node="chapter2_4", reward={"exp": 200}
            ),
            StoryNode(
                id="chapter2_3b", chapter="chapter2", title="当众质问",
                node_type=StoryNodeType.COMBAT,
                speaker="内鬼", dialogue=(
                    "哼，既然被你发现了，那就别怪我不客气！\n\n"
                    "你以为你门派是什么好东西？二十年前，\n"
                    "你们也不过是分赃的强盗罢了！\n"
                    "碎片我已到手，你们来迟了！\n\n"
                    "血月教万岁！哈哈哈哈——"
                ),
                combat_enemy="内鬼",
                next_node="chapter2_4", reward={"exp": 300, "money": 500}
            ),
            StoryNode(
                id="chapter2_4", chapter="chapter2", title="碎片被盗",
                node_type=StoryNodeType.DIALOGUE,
                speaker="大侠", dialogue=(
                    "不好！无论你如何追查，碎片还是被抢走了！\n\n"
                    "据情报，碎片被送往了一个叫'血月谷'的地方——\n"
                    "那里是二十年前血月教的总坛遗址，如今似乎有人在那里活动。\n\n"
                    "但更让我震惊的是——我查到了那个内鬼的身份。\n"
                    "他不是别人，正是...我的孪生兄弟。\n\n"
                    "二十年前，他被屠龙刀的力量腐蚀，我以为他已经死了。\n"
                    "没想到他不仅活着，还在暗中操纵一切。\n"
                    "那些黑衣人、血月教的死灰复燃、碎片的被盗...都是他一手策划的。\n\n"
                    "我必须告诉你真相——关于我的身份，关于逍遥派的秘密。"
                ),
                next_node="chapter2_5"
            ),
            StoryNode(
                id="chapter2_5", chapter="chapter2", title="逍遥之秘",
                node_type=StoryNodeType.DIALOGUE,
                speaker="大侠", dialogue=(
                    "我不是什么'大侠'。我是逍遥派当代掌门——逍遥子。\n\n"
                    "逍遥派三百年来一直有一个使命：对抗朝廷的密探组织'暗影司'。\n"
                    "初代逍遥子就是从暗影司叛逃出来的。\n"
                    "而我的兄弟...他被暗影司抓走了，被屠龙刀的力量控制了心智。\n\n"
                    "他现在自称'血月教主'，但那不是他——那只是刀的傀儡。\n"
                    "我一直在寻找拯救他的方法，但时间不多了。\n"
                    "如果碎片全部被收集，屠龙刀重铸，他就真的回不来了。\n\n"
                    "去与其他门派接触，争取他们的支持吧。\n"
                    "只有各大门派联手，才能对抗暗影司和血月教。"
                ),
                next_node="chapter3_1",
                on_complete="chapter2_done",
                requirement={"level": 15, "faction_rep_any": 20}
            ),
        ]

    def _build_chapter3(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="chapter3_1", chapter="chapter3", title="血月谷之战",
                node_type=StoryNodeType.DIALOGUE,
                speaker="逍遥子", dialogue=(
                    "时机已到！各大门派已同意联手进攻血月谷。\n\n"
                    "但我要先告诉你一件事——\n"
                    "血月教主是我的兄弟。如果可以，我不想杀他。\n"
                    "但如果他已经被屠龙刀完全控制...那就只能由我来亲手了结。\n\n"
                    "你作为先锋，率队突入谷中。\n"
                    "记住，我们的目标是夺回碎片，不是杀戮。"
                ),
                next_node="chapter3_2", level_requirement=20
            ),
            StoryNode(
                id="chapter3_2", chapter="chapter3", title="血月谷入口",
                node_type=StoryNodeType.COMBAT,
                speaker="血月教守卫", dialogue="来者何人！血月谷乃禁地，擅闯者——死！",
                combat_enemy="血月教守卫",
                next_node="chapter3_3", reward={"exp": 500, "money": 300}
            ),
            StoryNode(
                id="chapter3_3", chapter="chapter3", title="谷中真相",
                node_type=StoryNodeType.REVELATION,
                speaker="神秘人", dialogue=(
                    "哈哈哈...你以为血月教是邪教？天真！\n\n"
                    "二十年前，是各大门派联手抢夺了屠龙刀，将其打碎分赃！\n"
                    "他们不是什么正道，不过是分赃的强盗罢了！\n"
                    "太极门的大火，是为了掩盖嫡传弟子发现真相的事实！\n"
                    "红莲教万民书的失窃，是为了抹去起义军的记忆！\n\n"
                    "而我——我只是想把碎片重新拼起来，\n"
                    "用屠龙刀的力量，终结这个虚伪的江湖！\n\n"
                    "而你——你不过是那些伪君子的棋子罢了！"
                ),
                next_node="chapter3_4"
            ),
            StoryNode(
                id="chapter3_4", chapter="chapter3", title="信仰动摇",
                node_type=StoryNodeType.CHOICE,
                speaker="内心", dialogue=(
                    "神秘人的话让你动摇了...二十年前的事，真的是这样吗？\n"
                    "道德和尚一直沉默不语，逍遥子的表情也变得复杂...\n"
                    "你选择相信谁？"
                ),
                choices=[
                    StoryChoice(
                        text="我相信逍遥子——即使过去有错，也不能用暴力纠正",
                        next_node="chapter3_5a", morality_change=10
                    ),
                    StoryChoice(
                        text="也许...血月教说的有道理——这个江湖确实虚伪",
                        next_node="chapter3_5b", morality_change=-15,
                        faction_change={"all": -5}
                    ),
                    StoryChoice(
                        text="我要自己查明真相——不被任何人左右",
                        next_node="chapter3_5c", morality_change=5
                    ),
                ]
            ),
            StoryNode(
                id="chapter3_5a", chapter="chapter3", title="正道之路",
                node_type=StoryNodeType.COMBAT,
                speaker="神秘人", dialogue=(
                    "执迷不悟！那就用刀来说话吧！\n\n"
                    "你以为你是正义的？正义不过是强者给弱者编造的故事！"
                ),
                combat_enemy="神秘人",
                next_node="chapter4_1a", reward={"exp": 800, "daode": 20}
            ),
            StoryNode(
                id="chapter3_5b", chapter="chapter3", title="暗道之路",
                node_type=StoryNodeType.DIALOGUE,
                speaker="神秘人", dialogue=(
                    "你愿意听我说？好...跟我来，我带你看一样东西。\n\n"
                    "这是二十年前的盟约——各大门派联手屠龙、分赃碎片的证据！\n"
                    "上面有七大派掌门的手印！\n\n"
                    "还有这封——暗影司给各大门派的密信，\n"
                    "命令他们消灭血月教，夺取屠龙刀。\n"
                    "你以为那些掌门是自愿联手的？他们不过是朝廷的走狗！"
                ),
                next_node="chapter4_1b", reward={"exp": 500, "daode": -20}
            ),
            StoryNode(
                id="chapter3_5c", chapter="chapter3", title="独行之路",
                node_type=StoryNodeType.DIALOGUE,
                speaker="道德和尚", dialogue=(
                    "阿弥陀佛...你要自己查？好，老衲告诉你一些事。\n\n"
                    "二十年前，我确实参与了围剿血月教的行动。\n"
                    "当时我们以为血月教是邪教，但战后我才发现——\n"
                    "血月教主不过是一个被屠龙刀控制的可怜人。\n\n"
                    "而各大门派...确实分了碎片。这一点，我无法否认。\n"
                    "但碎片分散，总好过一把完整的屠龙刀落入一人之手。\n"
                    "那把刀的力量...会吞噬任何人的灵魂。\n\n"
                    "无论你查到什么，都不要迷失自己。\n"
                    "记住——侠之大者，为国为民。"
                ),
                next_node="chapter4_1c", reward={"exp": 600}
            ),
        ]

    def _build_chapter4(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="chapter4_1a", chapter="chapter4", title="正道集结",
                node_type=StoryNodeType.DIALOGUE,
                speaker="逍遥子", dialogue=(
                    "你击败了神秘人，夺回了碎片。但他逃了——而且他的话让我无法释怀。\n\n"
                    "他说的是事实。二十年前，各大门派确实分了碎片。\n"
                    "但那是因为屠龙刀太危险了——它会吞噬持有者的灵魂。\n"
                    "碎片分散，至少保证了没有人能再被那把刀控制。\n\n"
                    "各大门派决定召开武林大会，商议对策。\n"
                    "你作为夺回碎片的英雄，将代表门派出席！\n\n"
                    "但我要提醒你——武林大会上，各方势力暗流涌动。\n"
                    "朝廷的人、暗影司的密探、各派的内鬼...谁都不能完全信任。"
                ),
                next_node="chapter4_2", level_requirement=25
            ),
            StoryNode(
                id="chapter4_1b", chapter="chapter4", title="暗流涌动",
                node_type=StoryNodeType.DIALOGUE,
                speaker="神秘人", dialogue=(
                    "你看到了真相。现在，你有一个选择——\n\n"
                    "加入我们，一起重铸屠龙刀，推翻那些伪君子的统治！\n"
                    "有了屠龙刀的力量，我们可以建立一个真正公平的江湖！\n\n"
                    "或者...你也可以带着这个秘密回到你的门派。\n"
                    "但你觉得他们会放过你吗？知道太多的人，通常活不长。"
                ),
                next_node="chapter4_2", level_requirement=25
            ),
            StoryNode(
                id="chapter4_1c", chapter="chapter4", title="真相大白",
                node_type=StoryNodeType.DIALOGUE,
                speaker="道德和尚", dialogue=(
                    "阿弥陀佛...你查到了真相。\n\n"
                    "是的，二十年前的事，确实是我们做错了。\n"
                    "但屠龙刀的力量太危险了，无论谁持有它，都会被力量腐蚀。\n"
                    "碎片不能重铸，那把刀...不该存在于世。\n\n"
                    "然而——有人不这么想。武林大会上，一切都会揭晓。\n"
                    "你准备好了吗？"
                ),
                next_node="chapter4_2", level_requirement=25
            ),
            StoryNode(
                id="chapter4_2", chapter="chapter4", title="武林大会",
                node_type=StoryNodeType.DIALOGUE,
                speaker="村长", dialogue=(
                    "武林大会在平安镇召开！各大门派掌门齐聚一堂。\n\n"
                    "韦扬掌门、清照掌门、于红儒教主、钟央掌门、\n"
                    "清虚道人、白瑞德掌门...还有逍遥子，\n"
                    "二十年来他第一次以真面目出现在众人面前。\n\n"
                    "但就在大会进行时——绣花女出现了！\n\n"
                    "她手持绣花针，以一敌百！\n"
                    "她的武功...竟然兼修太极和花间两派！\n"
                    "她不是来抢碎片的——她是来找一个人报仇的！\n"
                    "她要找的人是...清虚道人！"
                ),
                next_node="chapter4_3"
            ),
            StoryNode(
                id="chapter4_3", chapter="chapter4", title="绣花女的真相",
                node_type=StoryNodeType.DIALOGUE,
                speaker="绣花女", dialogue=(
                    "清虚！二十年了，你终于肯面对我了吗？\n\n"
                    "我是太极门嫡传弟子——二十年前那场大火中'失踪'的人！\n"
                    "大火不是意外，是你放的！\n"
                    "因为你不是嫡传弟子，你怕师父把掌门之位传给我！\n\n"
                    "我侥幸逃生，被花间派清照掌门救下。\n"
                    "二十年来，我苦修太极和花间两派武功，\n"
                    "就是为了今天——当着天下英雄的面，揭穿你的真面目！\n\n"
                    "清虚！你有什么话说？！"
                ),
                next_node="chapter4_4"
            ),
            StoryNode(
                id="chapter4_4", chapter="chapter4", title="清虚的忏悔",
                node_type=StoryNodeType.DIALOGUE,
                speaker="清虚道人", dialogue=(
                    "...你说的没错。大火是我放的。\n\n"
                    "二十年来，我每天都在噩梦中惊醒。\n"
                    "我以为你死了，我以为我犯下了不可饶恕的罪。\n"
                    "但我不后悔——因为如果我不这么做，\n"
                    "太极门会在嫡传弟子的手中走向毁灭。\n"
                    "他知道了太极古墓的秘密，他想打开古墓！\n\n"
                    "那座古墓里的东西...比屠龙刀更危险。\n\n"
                    "但现在，这些都不重要了。\n"
                    "碎片散落一地，武林大会一片混乱——\n"
                    "而真正的危险，才刚刚开始。"
                ),
                next_node="chapter4_5"
            ),
            StoryNode(
                id="chapter4_5", chapter="chapter4", title="最终抉择",
                node_type=StoryNodeType.CHOICE,
                speaker="逍遥子", dialogue=(
                    "碎片散落一地，所有人都在看着你。\n\n"
                    "神秘人——我的兄弟——正在远处注视着这一切。\n"
                    "他在等你做决定。我也在等。\n\n"
                    "现在，所有碎片都在你面前。你必须选择——"
                ),
                choices=[
                    StoryChoice(
                        text="重铸屠龙刀——我要用这力量终结一切纷争",
                        next_node="chapter5_1a", morality_change=0
                    ),
                    StoryChoice(
                        text="销毁碎片——这力量不该存在于世",
                        next_node="chapter5_1b", morality_change=20
                    ),
                    StoryChoice(
                        text="将碎片分还各门派——没有人该独占这份力量",
                        next_node="chapter5_1c", morality_change=10
                    ),
                ]
            ),
        ]

    def _build_chapter5(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="chapter5_1a", chapter="chapter5", title="屠龙重铸",
                node_type=StoryNodeType.DIALOGUE,
                speaker="逍遥子", dialogue=(
                    "你选择了重铸屠龙刀...\n\n"
                    "碎片在你手中缓缓聚合，天空中电闪雷鸣。\n"
                    "刀成之日，天地变色！一股磅礴的力量涌入你的体内——\n"
                    "但同时，你感到一股黑暗的力量正在侵蚀你的心智...\n\n"
                    "逍遥子的兄弟——神秘人——缓缓走来：\n"
                    "'终于...终于重铸了...哥哥，我等了二十年...'\n\n"
                    "他的眼中闪过一丝清明，但随即被黑暗吞噬：\n"
                    "'不...不对...这力量...它在控制我...'\n\n"
                    "他变成了魔化和尚——屠龙刀的力量彻底吞噬了他。\n"
                    "你必须战胜他，才能从刀的魔性中挣脱！"
                ),
                next_node="chapter5_boss_a", level_requirement=30
            ),
            StoryNode(
                id="chapter5_boss_a", chapter="chapter5", title="心魔之战",
                node_type=StoryNodeType.BOSS_FIGHT,
                speaker="魔化和尚", dialogue=(
                    "哈哈哈...你以为你能驾驭屠龙刀？\n"
                    "多少英雄豪杰，最终都倒在了这把刀下！\n\n"
                    "你以为你是正义的？正义不过是强者编造的故事！\n"
                    "你以为你在救人？你只是在满足自己的虚荣！\n\n"
                    "来吧，让我看看你的意志——\n"
                    "是否比这把刀更锋利！"
                ),
                combat_enemy="魔化和尚",
                next_node="epilogue_a", reward={"exp": 5000}
            ),
            StoryNode(
                id="chapter5_1b", chapter="chapter5", title="碎刀销毁",
                node_type=StoryNodeType.DIALOGUE,
                speaker="道德和尚", dialogue=(
                    "你选择销毁碎片...这是最艰难的选择。\n\n"
                    "你运起全身内力，将碎片一一击碎。\n"
                    "碎片碎裂的声音如同龙吟，天地为之震动。\n\n"
                    "但就在最后一块碎片即将碎裂之时——\n"
                    "神秘人出现了！他不能容忍碎片被毁！\n\n"
                    "'不——！二十年的心血，你一念之间就要毁掉？！'\n"
                    "他的眼中满是疯狂和绝望：\n"
                    "'你不懂...只有屠龙刀的力量，才能对抗暗影司...'\n"
                    "'只有重铸神兵，才能终结这个乱世...'\n\n"
                    "他向你冲来——你必须击败他，才能完成碎刀！"
                ),
                next_node="chapter5_boss_b", level_requirement=30
            ),
            StoryNode(
                id="chapter5_boss_b", chapter="chapter5", title="最后的战斗",
                node_type=StoryNodeType.BOSS_FIGHT,
                speaker="神秘人", dialogue=(
                    "我不会让你毁掉它！\n\n"
                    "二十年了...二十年了...\n"
                    "我被暗影司抓走，被屠龙刀控制，\n"
                    "我做了那么多违心的事...\n\n"
                    "但至少...至少让我完成这一件事...\n"
                    "让我重铸屠龙刀...让我用它的力量...\n"
                    "终结暗影司...终结这个虚伪的江湖...\n\n"
                    "为什么...为什么连这都不让我做..."
                ),
                combat_enemy="神秘人",
                next_node="epilogue_b", reward={"exp": 5000}
            ),
            StoryNode(
                id="chapter5_1c", chapter="chapter5", title="碎片归还",
                node_type=StoryNodeType.DIALOGUE,
                speaker="逍遥子", dialogue=(
                    "你选择将碎片还给各门派，维持武林平衡。\n\n"
                    "你一块一块地将碎片交还到各派掌门手中：\n"
                    "韦扬接过碎片，沉默不语。\n"
                    "清照微微点头，眼中含泪。\n"
                    "于红儒握紧碎片，咬紧牙关。\n"
                    "钟央面无表情，但手在颤抖。\n"
                    "清虚双手合十，念了一声佛号。\n"
                    "白瑞德冷冷地收下，转身离去。\n\n"
                    "但就在最后一块碎片交出之时——\n"
                    "神秘人摘下面具，竟然是...逍遥子的面容！\n\n"
                    "不——那是逍遥子的孪生兄弟！\n"
                    "他已经被屠龙刀的力量腐蚀了二十年，\n"
                    "他不能容忍碎片被分散——他要重铸屠龙刀！\n"
                    "即使代价是自己的灵魂！"
                ),
                next_node="chapter5_boss_c", level_requirement=30
            ),
            StoryNode(
                id="chapter5_boss_c", chapter="chapter5", title="终极对决",
                node_type=StoryNodeType.BOSS_FIGHT,
                speaker="神秘人", dialogue=(
                    "我等了二十年，就是为了这一刻！\n\n"
                    "碎片不能分散，必须重铸！\n"
                    "只有屠龙刀才能终结这乱世！\n"
                    "只有绝对的力量，才能带来绝对的和平！\n\n"
                    "哥哥...对不起...\n"
                    "但这条路，我必须走到底...\n\n"
                    "挡我者——死！"
                ),
                combat_enemy="神秘人",
                next_node="epilogue_c", reward={"exp": 5000}
            ),
        ]

    def _build_epilogue(self) -> List[StoryNode]:
        return [
            StoryNode(
                id="epilogue_a", chapter="epilogue", title="屠龙之主",
                node_type=StoryNodeType.ENDING,
                speaker="旁白", dialogue=(
                    "你战胜了心魔，成为了屠龙刀的主人。\n\n"
                    "逍遥子的兄弟——那个被刀控制了二十年的人——\n"
                    "在生命的最后一刻，终于恢复了清明。\n"
                    "他看着逍遥子，微笑着闭上了眼睛：\n"
                    "'哥哥...对不起...谢谢你...'\n\n"
                    "武林中，无人敢与你争锋。但你知道，\n"
                    "力量越大，责任越重。\n"
                    "你立下誓言：屠龙刀只用于守护，永不用于征服。\n\n"
                    "但每到深夜，你仍能听到刀的低语...\n"
                    "它在等待...等待你松懈的那一刻...\n\n"
                    "——结局A：屠龙之主——\n"
                    "——'权力是最好的仆人，却是最坏的主人。'——"
                ),
                reward={"title": "屠龙之主", "daode": 50}
            ),
            StoryNode(
                id="epilogue_b", chapter="epilogue", title="天下太平",
                node_type=StoryNodeType.ENDING,
                speaker="旁白", dialogue=(
                    "碎片被销毁，屠龙刀永远消失在了历史中。\n\n"
                    "神秘人——逍遥子的兄弟——在战败后力竭倒地。\n"
                    "逍遥子抱着他，二十年来第一次流泪：\n"
                    "'你为什么不告诉我...你为什么一个人扛了二十年...'\n"
                    "'因为...我不想让你也...被卷进来...'\n"
                    "他微笑着，终于释然。\n\n"
                    "你放弃了无上的力量，选择了最艰难的道路——\n"
                    "用双手，而非神兵，守护这片江湖。\n\n"
                    "多年后，江湖中流传着一个故事：\n"
                    "有一个人，面对可以号令天下的力量，选择了放弃。\n"
                    "不是因为软弱，而是因为——\n"
                    "真正的强大，是能够拒绝诱惑。\n\n"
                    "——结局B：天下太平——\n"
                    "——'侠之大者，为国为民。'——"
                ),
                reward={"title": "天下太平", "daode": 100}
            ),
            StoryNode(
                id="epilogue_c", chapter="epilogue", title="武林盟主",
                node_type=StoryNodeType.ENDING,
                speaker="旁白", dialogue=(
                    "碎片归还各门派，武林恢复了平衡。\n\n"
                    "神秘人战败后，屠龙刀的魔性终于从他体内消散。\n"
                    "他恢复了记忆，看着逍遥子：\n"
                    "'哥哥...我回来了...'\n"
                    "逍遥子紧紧抱住他：'欢迎回家。'\n\n"
                    "各大门派推举你为武林盟主，\n"
                    "你以公正和智慧，维持着江湖的秩序。\n\n"
                    "这不是一个英雄的时代，而是一个和平的时代。\n"
                    "没有屠龙刀，没有血月教，没有暗影司——\n"
                    "只有一群普通人，努力让这个世界变得更好。\n\n"
                    "多年后的一个清晨，你站在平安镇的城墙上，\n"
                    "看着朝阳升起。阿青在远处叫卖豆腐，\n"
                    "捕快在街上巡逻，孩子们在追逐嬉戏。\n\n"
                    "你微笑着，心想：\n"
                    "这才是江湖最好的模样。\n\n"
                    "——结局C：武林盟主——\n"
                    "——'江湖不远，就在人间。'——"
                ),
                reward={"title": "武林盟主", "daode": 80}
            ),
        ]

    def get_current_node(self) -> Optional[StoryNode]:
        return self._nodes.get(self._state.current_node)

    def can_progress(self, player) -> Optional[str]:
        node = self.get_current_node()
        if not node:
            return None
        req = node.requirement or {}
        if "level" in req and player.level < req["level"]:
            return f"需要达到{req['level']}级"
        if "faction" in req:
            if req["faction"] == "any" and player.faction.value == "none":
                return "需要加入一个门派"
        if node.level_requirement > player.level:
            return f"需要达到{node.level_requirement}级"
        if node.morality_requirement is not None:
            if node.morality_requirement > 0 and player.daode < node.morality_requirement:
                return f"需要道德值达到{node.morality_requirement}"
            if node.morality_requirement < 0 and player.daode > node.morality_requirement:
                return f"需要道德值低于{node.morality_requirement}"
        if node.faction_requirement and player.faction.value != node.faction_requirement:
            return f"需要加入{node.faction_requirement}门派"
        return None

    def advance(self, player, choice_index: Optional[int] = None) -> Dict:
        node = self.get_current_node()
        if not node:
            return {"success": False, "message": "没有当前剧情节点"}

        block_reason = self.can_progress(player)
        if block_reason:
            return {"success": False, "message": block_reason}

        self._state.completed_nodes.append(node.id)

        if node.node_type == StoryNodeType.CHOICE and choice_index is not None:
            choice = node.choices[choice_index]
            self._state.choices_made[node.id] = choice.text
            player.daode += choice.morality_change
            for faction, change in choice.faction_change.items():
                if faction == "all":
                    for f in player.faction_rep:
                        player.faction_rep[f] = player.faction_rep.get(f, 0) + change
                else:
                    player.faction_rep[int(faction)] = player.faction_rep.get(int(faction), 0) + change
            next_id = choice.next_node
        else:
            next_id = node.next_node

        if node.on_complete:
            self._state.story_flags[node.on_complete] = True

        if node.reward:
            self._apply_reward(player, node.reward)

        if node.chapter not in self._state.chapter_completed:
            next_node = self._nodes.get(next_id) if next_id else None
            if next_node and next_node.chapter != node.chapter:
                self._state.chapter_completed.append(node.chapter)

        if next_id:
            self._state.current_node = next_id
            self._state.current_chapter = self._nodes[next_id].chapter

        if self._on_story_event:
            self._on_story_event("advance", node, choice_index)

        result = {
            "success": True,
            "node_id": node.id,
            "node_type": node.node_type.value,
            "chapter": node.chapter,
            "title": node.title,
        }
        if node.node_type == StoryNodeType.ENDING:
            result["ending"] = True
            result["ending_title"] = node.title
        return result

    def _apply_reward(self, player, reward: Dict):
        if "exp" in reward:
            player.add_exp(reward["exp"])
        if "money" in reward:
            player.add_money(reward["money"])
        if "daode" in reward:
            player.daode += reward["daode"]
        if "pot" in reward:
            player.pot += reward["pot"]
        if "skill_exp" in reward:
            from .systems.cultivation import get_cultivation_system
            cult = get_cultivation_system()
            for skill_id, exp in reward["skill_exp"].items():
                cult.add_skill_exp(player, skill_id, exp)

    def get_story_info(self) -> Dict:
        node = self.get_current_node()
        return {
            "current_chapter": self._state.current_chapter,
            "current_node": self._state.current_node,
            "current_title": node.title if node else "",
            "chapters_completed": len(self._state.chapter_completed),
            "total_chapters": 7,
            "story_flags": dict(self._state.story_flags),
            "choices_made": len(self._state.choices_made),
        }

    def get_state(self) -> StoryState:
        return self._state

    def set_state(self, state: StoryState):
        self._state = state

    def is_story_complete(self) -> bool:
        node = self.get_current_node()
        return node is not None and node.node_type == StoryNodeType.ENDING and node.id in self._state.completed_nodes


def get_story_engine() -> StoryEngine:
    engine = StoryEngine()
    engine.load_story()
    return engine
