import json
import random
import hashlib
import threading
import time
from typing import Dict, List, Optional, Callable, Any
from collections import OrderedDict
from .entities import QuestType


WORLD_SETTING = """
游戏背景：白金英雄坛说，中国古代武侠世界。
主要地点：平安镇（中心城镇）、八卦门（东北方）、花间派（东方）、红莲教（东南方）、那迦派（北方）、太极门（西北方）、雪山派（西南方）。
主要门派：武当派(太极门)、少林派(太极门分支)、丐帮(红莲教关联)、华山派(花间派关联)、雪山派、五毒教(何铁手)、逍遥派、红莲教。
NPC类型：村民、门派弟子、武林高手、商人、店小二、捕快、土匪、恶霸等。
常见任务：送信、收集物品、除恶、寻人、送货、拜师、切磋、门派任务。
物品类型：食物、药品、武器、装备、书籍、材料等。
奖励类型：银两、经验、潜能、声望、物品、装备、武功秘籍等。
江湖规矩：门派之间有恩怨，同门互助，异派相争。道德高者受正派尊敬，道德低者被正派排斥。
"""

TASK_CONSTRAINTS = """
难度等级1-5：
1级：简单，新手可完成，奖励少
2级：简单，适合10级以下
3级：中等，适合10-20级
4级：困难，适合20-30级
5级：非常困难，适合30级以上

奖励匹配难度：
难度1：银两10-50，经验10-50，潜能5-20
难度2：银两50-200，经验50-200，潜能20-50
难度3：银两200-1000，经验200-1000，潜能50-200
难度4：银两1000-5000，经验1000-5000，潜能200-1000
难度5：银两5000-20000，经验5000-20000，潜能1000-5000
"""

NPC_PERSONALITY_TEMPLATES = {
    "normal": {
        "tone": "平和友善",
        "style": "普通村民语气，偶尔提及江湖传闻",
        "concerns": ["生活安宁", "镇上安全", "家人健康"],
    },
    "trader": {
        "tone": "热情精明",
        "style": "商人语气，喜欢谈论买卖和货物",
        "concerns": ["生意兴隆", "货物质量", "客官满意"],
    },
    "master": {
        "tone": "威严深沉",
        "style": "武林高手语气，言简意赅，偶有指点",
        "concerns": ["武学传承", "门派兴衰", "弟子资质"],
    },
    "enemy": {
        "tone": "凶狠蛮横",
        "style": "恶人语气，威胁恐吓",
        "concerns": ["地盘利益", "自身安全", "报复仇怨"],
    },
    "quest_giver": {
        "tone": "急切恳切",
        "style": "有事相求的语气，描述困难",
        "concerns": ["麻烦解决", "报酬合理", "信任对方"],
    },
}

FACTION_RELATIONS = {
    "BAGUA": {"allies": ["TAIJI"], "enemies": ["HONGLIAN"], "neutral": ["FLOWER", "NAJA", "XUESHAN", "XIAOYAO"]},
    "FLOWER": {"allies": ["XUESHAN"], "enemies": ["NAJA"], "neutral": ["BAGUA", "HONGLIAN", "TAIJI", "XIAOYAO"]},
    "HONGLIAN": {"allies": ["NAJA"], "enemies": ["BAGUA", "TAIJI"], "neutral": ["FLOWER", "XUESHAN", "XIAOYAO"]},
    "NAJA": {"allies": ["HONGLIAN"], "enemies": ["FLOWER"], "neutral": ["BAGUA", "TAIJI", "XUESHAN", "XIAOYAO"]},
    "TAIJI": {"allies": ["BAGUA"], "enemies": ["HONGLIAN"], "neutral": ["FLOWER", "NAJA", "XUESHAN", "XIAOYAO"]},
    "XUESHAN": {"allies": ["FLOWER"], "enemies": [], "neutral": ["BAGUA", "HONGLIAN", "NAJA", "TAIJI", "XIAOYAO"]},
    "XIAOYAO": {"allies": [], "enemies": [], "neutral": ["BAGUA", "FLOWER", "HONGLIAN", "NAJA", "TAIJI", "XUESHAN"]},
    "NONE": {"allies": [], "enemies": [], "neutral": ["BAGUA", "FLOWER", "HONGLIAN", "NAJA", "TAIJI", "XUESHAN", "XIAOYAO"]},
}

MOCK_TASKS = [
    {"task_id": "t1", "title": "送信", "description": "请帮我把这封信送到隔壁村王大爷家", "task_type": "deliver", "target": "王大爷", "count": 1, "reward": {"money": 30, "exp": 20}, "difficulty": 1, "level_requirement": 1},
    {"task_id": "t2", "title": "收集草药", "description": "我需要一些草药来治病，请帮我采3株回来", "task_type": "fetch", "target": "草药", "count": 3, "reward": {"money": 50, "exp": 30, "pot": 10}, "difficulty": 1, "level_requirement": 1},
    {"task_id": "t3", "title": "除暴安良", "description": "黑风岭有一伙强盗，请帮我除掉他们", "task_type": "kill", "target": "强盗", "count": 5, "reward": {"money": 200, "exp": 150, "pot": 50, "daode": 10}, "difficulty": 3, "level_requirement": 5},
    {"task_id": "t4", "title": "寻找失物", "description": "我的传家玉佩丢失了，可能在东边的树林里", "task_type": "fetch", "target": "玉佩", "count": 1, "reward": {"money": 100, "exp": 80}, "difficulty": 2, "level_requirement": 3},
    {"task_id": "t5", "title": "护送货物", "description": "帮我把这批货物护送到洛阳城", "task_type": "guard", "target": "货物", "count": 1, "reward": {"money": 500, "exp": 300, "pot": 100}, "difficulty": 4, "level_requirement": 15},
    {"task_id": "t6", "title": "探访故人", "description": "多年未见的老友住在太极门附近，替我去问候一声", "task_type": "talk", "target": "古松道人", "count": 1, "reward": {"money": 80, "exp": 60, "pot": 20}, "difficulty": 2, "level_requirement": 3},
    {"task_id": "t7", "title": "探索秘洞", "description": "听说黑森林深处有个神秘洞穴，替我去看看里面有什么", "task_type": "explore", "target": "神秘洞穴", "count": 1, "reward": {"money": 300, "exp": 200, "pot": 80}, "difficulty": 3, "level_requirement": 10},
    {"task_id": "t8", "title": "门派试炼", "description": "完成门派试炼，证明你的实力", "task_type": "kill", "target": "试炼傀儡", "count": 3, "reward": {"money": 150, "exp": 120, "pot": 40}, "difficulty": 2, "level_requirement": 5},
]

MOCK_DIALOGUES = {
    "default": [
        "这位少侠，看你气度不凡，将来必成大器！",
        "江湖险恶，少侠要多加小心啊。",
        "最近镇上不太平，听说有强人出没。",
        "平安镇虽小，但藏龙卧虎，不可小觑。",
        "天下风云出我辈，一入江湖岁月催。",
    ],
    "trader": [
        "客官要点什么？本店应有尽有！",
        "上好的药材，强身健体，要不要来一点？",
        "最近进货了一批上好的兵器，客官要不要看看？",
        "买卖公平，童叟无欺！",
    ],
    "master": [
        "年轻人，看你骨骼清奇，是块练武的好材料。",
        "习武者，以德为先，以技为后。",
        "江湖恩怨，非刀剑所能了结。",
        "武学之道，在于心诚。",
    ],
    "villager": [
        "这年头，能平平安安过日子就不错了。",
        "听说城外最近不太平，少侠出门小心。",
        "我们这小地方，难得见到像你这样的江湖人士。",
        "日子虽苦，但总有盼头。",
    ],
    "enemy": [
        "哼，又来一个找死的！",
        "识相的赶紧滚！",
        "你是什么东西，敢来我的地盘撒野？",
        "今天让你知道厉害！",
    ],
}

MOCK_ENCOUNTERS = [
    {"title": "古墓奇缘", "description": "你在山洞深处发现了一座古墓，墓中藏有失传已久的武功秘籍！", "type": "skill_book", "reward": {"skill_exp": 500}},
    {"title": "仙人指路", "description": "一位白发老者突然出现，点了点你的额头，你感到一股暖流涌入丹田！", "type": "stat_boost", "reward": {"exp": 500, "pot": 200}},
    {"title": "宝箱现世", "description": "你无意中踢到了一块松动的地砖，下面竟然藏着一个宝箱！", "type": "item", "reward": {"money": 1000, "item": "item_dan"}},
    {"title": "高人传功", "description": "一位蒙面高手突然出手点你穴道，随后又解开了你的穴道，你发现自己功力大增！", "type": "level_up", "reward": {"exp": 1000}},
    {"title": "义士相救", "description": "你正陷入困境时，一位义士出手相救，临走时送了你一件宝物！", "type": "item", "reward": {"item": "item_gold_armor"}},
    {"title": "奇药现世", "description": "你在溪边发现了一株散发异香的奇草，服下后精神百倍！", "type": "heal", "reward": {"hp": 200, "mp": 100}},
]


class LRUCache:
    def __init__(self, max_size: int = 256):
        self._cache: OrderedDict = OrderedDict()
        self._max_size = max_size
        self._lock = threading.Lock()

    def get(self, key: str) -> Optional[Any]:
        with self._lock:
            if key in self._cache:
                self._cache.move_to_end(key)
                return self._cache[key]
        return None

    def put(self, key: str, value: Any) -> None:
        with self._lock:
            if key in self._cache:
                self._cache.move_to_end(key)
            self._cache[key] = value
            while len(self._cache) > self._max_size:
                self._cache.popitem(last=False)

    def clear(self) -> None:
        with self._lock:
            self._cache.clear()


class AsyncLLMManager:
    def __init__(self):
        self._queue: List[Dict] = []
        self._results: Dict[str, Any] = {}
        self._lock = threading.Lock()
        self._result_lock = threading.Lock()
        self._worker: Optional[threading.Thread] = None
        self._running = False
        self._request_counter = 0

    def start(self):
        if self._running:
            return
        self._running = True
        self._worker = threading.Thread(target=self._worker_loop, daemon=True)
        self._worker.start()

    def stop(self):
        self._running = False
        if self._worker:
            self._worker.join(timeout=2)

    def submit(self, request_id: str, func: Callable, callback: Optional[Callable] = None) -> None:
        with self._lock:
            self._queue.append({
                "id": request_id,
                "func": func,
                "callback": callback,
            })

    def get_result(self, request_id: str) -> Optional[Any]:
        with self._result_lock:
            return self._results.pop(request_id, None)

    def has_result(self, request_id: str) -> bool:
        with self._result_lock:
            return request_id in self._results

    def _worker_loop(self):
        while self._running:
            task = None
            with self._lock:
                if self._queue:
                    task = self._queue.pop(0)
            if task:
                try:
                    result = task["func"]()
                    with self._result_lock:
                        self._results[task["id"]] = result
                    if task["callback"]:
                        try:
                            task["callback"](task["id"], result)
                        except Exception:
                            pass
                except Exception:
                    with self._result_lock:
                        self._results[task["id"]] = None
            else:
                time.sleep(0.05)


class LLMClient:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, api_type: str = "mock", api_key: str = "", base_url: str = "", model: str = ""):
        if hasattr(self, '_initialized') and self._initialized:
            return
        self.api_type = api_type
        self.api_key = api_key
        self.base_url = base_url
        self.model = model
        self.client = None
        self._init_client()
        self._cache = LRUCache(512)
        self._async_manager = AsyncLLMManager()
        self._async_manager.start()
        self._initialized = True

    def _init_client(self):
        if self.api_type in ("openai", "deepseek", "qwen"):
            try:
                from openai import OpenAI
                if self.api_type == "deepseek":
                    base_url = self.base_url or "https://api.deepseek.com/v1"
                    model = self.model or "deepseek-chat"
                elif self.api_type == "qwen":
                    base_url = self.base_url or "https://dashscope.aliyuncs.com/compatible-mode/v1"
                    model = self.model or "qwen-plus"
                else:
                    base_url = self.base_url or "https://api.openai.com/v1"
                    model = self.model or "gpt-3.5-turbo"
                self.client = OpenAI(api_key=self.api_key, base_url=base_url)
                self.model = model
            except ImportError:
                self.api_type = "mock"
        elif self.api_type == "local":
            self.api_type = "mock"

    def _make_cache_key(self, prefix: str, **kwargs) -> str:
        data = json.dumps(kwargs, sort_keys=True, ensure_ascii=False)
        h = hashlib.md5(data.encode()).hexdigest()[:12]
        return f"{prefix}:{h}"

    def _call_llm(self, system_prompt: str, user_prompt: str, temperature: float = 0.7, max_tokens: int = 500, json_mode: bool = False) -> Optional[str]:
        if not self.client:
            return None
        try:
            kwargs = {
                "model": self.model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": temperature,
                "max_tokens": max_tokens,
                "timeout": 15,
            }
            if json_mode:
                kwargs["response_format"] = {"type": "json_object"}
            response = self.client.chat.completions.create(**kwargs)
            return response.choices[0].message.content.strip()
        except Exception:
            return None

    def generate_dialogue(self, npc_info: Dict, player_info: Dict, player_input: str = "",
                          context: List[str] = None, dialogue_history: List[Dict] = None) -> str:
        cache_key = self._make_cache_key("dlg", npc_id=npc_info.get("id", 0),
                                         input=player_input[:50],
                                         hist_len=len(dialogue_history or []),
                                         p_lvl=player_info.get("level", 1))
        cached = self._cache.get(cache_key)
        if cached:
            return cached

        if self.api_type != "mock" and self.client:
            result = self._generate_llm_dialogue(npc_info, player_info, player_input, context, dialogue_history)
            if result:
                self._cache.put(cache_key, result)
                return result

        result = self._generate_mock_dialogue(npc_info, player_info, player_input)
        self._cache.put(cache_key, result)
        return result

    def _generate_llm_dialogue(self, npc_info: Dict, player_info: Dict, player_input: str,
                                context: List[str], dialogue_history: List[Dict]) -> Optional[str]:
        npc_role = npc_info.get("role", "normal")
        personality_template = NPC_PERSONALITY_TEMPLATES.get(npc_role, NPC_PERSONALITY_TEMPLATES["normal"])

        faction_name = npc_info.get("faction_name", "无门无派")
        player_faction = player_info.get("faction_name", "无门无派")
        relation_desc = self._get_faction_relation_desc(faction_name, player_faction)

        history_str = ""
        if dialogue_history:
            recent = dialogue_history[-6:]
            for h in recent:
                role = h.get("role", "npc")
                content = h.get("content", "")
                if role == "player":
                    history_str += f"玩家说：{content}\n"
                else:
                    history_str += f"{npc_info.get('name', 'NPC')}说：{content}\n"

        context_str = "\n".join(context[-3:] if context else [])

        system_prompt = f"""你是武侠世界中的NPC角色【{npc_info.get('name', '路人')}】。
{WORLD_SETTING}

你的身份信息：
- 姓名：{npc_info.get('name', '路人')}
- 身份：{npc_info.get('description', '普通人')}
- 门派：{faction_name}
- 性格：{npc_info.get('personality', '和蔼可亲')}
- 说话风格：{personality_template['style']}
- 关心的事：{', '.join(personality_template['concerns'])}
- 与玩家门派关系：{relation_desc}

规则：
1. 严格扮演你的角色，用符合身份的语气说话
2. 回复要简短（1-3句话），像真实对话
3. 根据与玩家门派的关系调整态度
4. 可以提及江湖传闻或自己的经历
5. 如果玩家问任务，可以给出相关线索
6. 绝不要跳出角色"""

        history_section = f"对话历史：\n{history_str}" if history_str else ""
        context_section = f"环境信息：{context_str}" if context_str else ""
        player_action = f"说：{player_input}" if player_input else "走近了你"

        user_prompt = f"""玩家信息：{player_info.get('name', '少侠')}，等级{player_info.get('level', 1)}，{player_faction}
当前时间：{'白天' if 6 <= player_info.get('hour', 12) <= 18 else '夜晚'}
当前地点：{npc_info.get('location', '平安镇')}

{history_section}
{context_section}

玩家{player_action}"""

        result = self._call_llm(system_prompt, user_prompt, temperature=0.8, max_tokens=200)
        if result:
            return f"【{npc_info.get('name', '路人')}】{result}"
        return None

    def _get_faction_relation_desc(self, npc_faction: str, player_faction: str) -> str:
        if npc_faction == "无门无派" or player_faction == "无门无派":
            return "无特殊关系"
        npc_key = None
        for f in FACTION_RELATIONS:
            if f in npc_faction.upper():
                npc_key = f
                break
        if not npc_key:
            return "无特殊关系"
        rels = FACTION_RELATIONS[npc_key]
        player_upper = player_faction.upper()
        if any(a in player_upper for a in rels["allies"]):
            return "友邦门派，态度友善"
        if any(e in player_upper for e in rels["enemies"]):
            return "敌对门派，态度警惕"
        return "中立门派，态度平和"

    def _generate_mock_dialogue(self, npc_info: Dict, player_info: Dict, player_input: str) -> str:
        name = npc_info.get('name', '路人')
        role = npc_info.get('role', 'normal')
        personality = npc_info.get('personality', '和蔼可亲')

        if player_input:
            keywords_task = ['任务', '帮忙', '需要', '求助', '请问', '打听', '委托']
            keywords_learn = ['学武', '拜师', '武功', '传授', '教我']
            keywords_trade = ['买', '卖', '东西', '货物', '价格']
            keywords_gossip = ['传闻', '消息', '最近', '发生']

            if any(k in player_input for k in keywords_task):
                responses = [
                    f"正好，我确实有一件事想请你帮忙。最近{random.choice(['镇外出现了一伙强人', '有人丢失了重要物品', '有位故人需要探访'])}……",
                    f"你来得正好！我正愁找不到人帮忙呢。",
                    f"嗯，确实有件事……不过不知道你有没有这个本事。",
                ]
                return f"【{name}】{random.choice(responses)}"
            elif any(k in player_input for k in keywords_learn):
                responses = [
                    "想学武功？先让我看看你的资质如何。",
                    "我门派的武功，不是谁都能学的。不过你……倒是有几分天赋。",
                    "习武之路漫漫，你可做好了准备？",
                ]
                return f"【{name}】{random.choice(responses)}"
            elif any(k in player_input for k in keywords_trade):
                responses = [
                    "客官好眼光！这可是上好的货色。",
                    "买卖嘛，价格好商量。",
                    "这东西可不便宜，不过物有所值！",
                ]
                return f"【{name}】{random.choice(responses)}"
            elif any(k in player_input for k in keywords_gossip):
                responses = [
                    f"最近{random.choice(['听说八卦门在招弟子', '红莲教的人又在搞事了', '有位大侠路过平安镇', '黑森林里出现了异象'])}……",
                    "江湖上的消息嘛，我倒是听到一些风声……",
                    "这事儿说来话长，你且听我慢慢道来。",
                ]
                return f"【{name}】{random.choice(responses)}"

            context_responses = [
                f"嗯，{player_input}……这倒是个有趣的话题。",
                f"关于这个嘛，{random.choice(['我略知一二', '我也有所耳闻', '这事儿不好说'])}。",
                f"你说的{player_input}，让我想起了{random.choice(['一段往事', '一个故人', '一句老话'])}……",
            ]
            return f"【{name}】{random.choice(context_responses)}"

        if role == 'trader':
            dialogues = MOCK_DIALOGUES['trader']
        elif role == 'master':
            dialogues = MOCK_DIALOGUES['master']
        elif role == 'enemy':
            dialogues = MOCK_DIALOGUES['enemy']
        elif role == 'normal':
            dialogues = MOCK_DIALOGUES['villager']
        else:
            dialogues = MOCK_DIALOGUES['default']

        return f"【{name}】{random.choice(dialogues)}"

    def generate_task(self, npc_info: Dict, player_info: Dict, existing_tasks: List[str] = None,
                      player_behavior: Dict = None) -> Dict:
        cache_key = self._make_cache_key("task", npc_id=npc_info.get("id", 0),
                                         p_lvl=player_info.get("level", 1),
                                         p_daode=player_info.get("daode", 0),
                                         behavior_hash=str(sorted((player_behavior or {}).items()))[:50])
        cached = self._cache.get(cache_key)
        if cached:
            return cached

        if self.api_type != "mock" and self.client:
            result = self._generate_llm_task(npc_info, player_info, existing_tasks, player_behavior)
            if result:
                self._cache.put(cache_key, result)
                return result

        result = self._generate_mock_task(npc_info, player_info, existing_tasks, player_behavior)
        self._cache.put(cache_key, result)
        return result

    def _generate_llm_task(self, npc_info: Dict, player_info: Dict, existing_tasks: List[str],
                            player_behavior: Dict) -> Optional[Dict]:
        behavior_str = ""
        if player_behavior:
            kills = player_behavior.get("total_kills", 0)
            quests_done = player_behavior.get("quests_completed", 0)
            behavior_str = f"""
玩家行为数据：
- 击杀数：{kills}
- 完成任务数：{quests_done}
- 善行：{player_behavior.get("good_deeds", 0)}
- 恶行：{player_behavior.get("bad_deeds", 0)}
- 最近活动：{player_behavior.get("recent_activity", '无')}"""

        system_prompt = f"""你是武侠游戏任务设计师，生成符合世界观的任务。
{WORLD_SETTING}
{TASK_CONSTRAINTS}

任务要贴合NPC的身份和性格，考虑玩家与NPC门派的关系。"""

        user_prompt = f"""NPC信息：
- 姓名：{npc_info.get('name', '路人')}
- 身份：{npc_info.get('role', '普通村民')}
- 门派：{npc_info.get('faction_name', '无门无派')}
- 位置：{npc_info.get('location', '平安镇')}
- 性格：{npc_info.get('personality', '普通')}
- 描述：{npc_info.get('description', '')}

玩家信息：
- 姓名：{player_info.get('name', '少侠')}
- 等级：{player_info.get('level', 1)}
- 门派：{player_info.get('faction_name', '无门无派')}
- 道德值：{player_info.get('daode', 0)}
{behavior_str}

已存在的任务ID：{existing_tasks or []}

请生成一个适合当前玩家等级和NPC身份的任务，返回JSON格式：
{{
    "task_id": "唯一标识符",
    "title": "任务标题(4-8字)",
    "description": "任务描述(20-50字，要有武侠风格)",
    "task_type": "任务类型(fetch/kill/talk/explore/deliver/guard)",
    "target": "目标名称",
    "count": 目标数量,
    "reward": {{"money": 银两, "exp": 经验, "pot": 潜能, "daode": 道德值(可选)}},
    "difficulty": 难度等级(1-5),
    "level_requirement": 等级要求
}}"""

        result = self._call_llm(system_prompt, user_prompt, temperature=0.8, max_tokens=400, json_mode=True)
        if result:
            try:
                parsed = json.loads(result)
                return self._parse_task_result(parsed)
            except json.JSONDecodeError:
                pass
        return None

    def _generate_mock_task(self, npc_info: Dict, player_info: Dict, existing_tasks: List[str],
                             player_behavior: Dict) -> Dict:
        existing_tasks = existing_tasks or []
        available = [t for t in MOCK_TASKS if t["task_id"] not in existing_tasks]

        if not available:
            task = random.choice(MOCK_TASKS).copy()
            task["task_id"] = f"{task['task_id']}_{random.randint(100, 999)}"
        else:
            task = random.choice(available).copy()

        player_level = player_info.get('level', 1)
        npc_role = npc_info.get('role', 'normal')

        if npc_role == "master":
            difficulty = min(5, max(2, player_level // 5 + 1))
            task["task_type"] = random.choice(["kill", "explore", "talk"])
            task["title"] = random.choice(["门派试炼", "武学考验", "师门任务", "历练修行"])
        elif npc_role == "trader":
            difficulty = min(3, max(1, player_level // 8 + 1))
            task["task_type"] = random.choice(["fetch", "deliver", "guard"])
            task["title"] = random.choice(["商队委托", "货物运送", "材料收集"])
        elif npc_role == "enemy":
            difficulty = min(5, max(3, player_level // 4 + 1))
            task["task_type"] = "kill"
            task["title"] = random.choice(["除恶务尽", "斩妖除魔", "替天行道"])
        else:
            difficulty = min(5, max(1, player_level // 5 + 1))

        task["difficulty"] = difficulty
        task["level_requirement"] = max(1, player_level - 2)

        scaling_factor = difficulty
        task["reward"]["money"] = int(task["reward"].get("money", 0) * scaling_factor)
        task["reward"]["exp"] = int(task["reward"].get("exp", 0) * scaling_factor)
        task["reward"]["pot"] = int(task["reward"].get("pot", 0) * scaling_factor)

        if player_behavior:
            good = player_behavior.get("good_deeds", 0)
            if good > 5:
                task["reward"]["daode"] = task["reward"].get("daode", 0) + 5

        return task

    def _parse_task_result(self, result: Dict) -> Dict:
        return {
            "task_id": result.get("task_id", f"task_{random.randint(1000, 9999)}"),
            "title": result.get("title", "未知任务"),
            "description": result.get("description", "暂无描述"),
            "task_type": result.get("task_type", "fetch"),
            "target": result.get("target", "目标"),
            "count": result.get("count", 1),
            "reward": result.get("reward", {"money": 10, "exp": 10}),
            "difficulty": result.get("difficulty", 1),
            "level_requirement": result.get("level_requirement", 1),
            "morality_requirement": result.get("morality_requirement", 0),
            "time_limit": result.get("time_limit"),
        }

    def generate_encounter(self, player_info: Dict, npc_info: Dict = None,
                           trigger_reason: str = "", player_behavior: Dict = None) -> Optional[Dict]:
        cache_key = self._make_cache_key("enc", p_lvl=player_info.get("level", 1),
                                         p_daode=player_info.get("daode", 0),
                                         reason=trigger_reason[:30])
        cached = self._cache.get(cache_key)
        if cached:
            return cached

        if self.api_type != "mock" and self.client:
            result = self._generate_llm_encounter(player_info, npc_info, trigger_reason, player_behavior)
            if result:
                self._cache.put(cache_key, result)
                return result

        result = self._generate_mock_encounter(player_info, trigger_reason, player_behavior)
        if result:
            self._cache.put(cache_key, result)
        return result

    def _generate_llm_encounter(self, player_info: Dict, npc_info: Dict, trigger_reason: str,
                                 player_behavior: Dict) -> Optional[Dict]:
        behavior_str = ""
        if player_behavior:
            behavior_str = f"""
玩家行为：
- 击杀数：{player_behavior.get("total_kills", 0)}
- 完成任务：{player_behavior.get("quests_completed", 0)}
- 善行：{player_behavior.get("good_deeds", 0)}
- 恶行：{player_behavior.get("bad_deeds", 0)}
- 连续战斗：{player_behavior.get("consecutive_kills", 0)}"""

        npc_str = ""
        if npc_info:
            npc_str = f"触发NPC：{npc_info.get('name', '')}（{npc_info.get('faction_name', '无门无派')}）"

        system_prompt = f"""你是武侠游戏奇遇设计师。奇遇是玩家在江湖中遇到的特殊事件，如同武侠小说中的奇遇桥段。
{WORLD_SETTING}

奇遇类型：
- skill_book: 获得武功秘籍
- stat_boost: 属性提升
- item: 获得稀有物品
- level_up: 功力大增
- heal: 伤势痊愈
- faction_event: 门派特殊事件
- master_appear: 隐世高人出现

奇遇要有武侠小说的韵味，描述要生动。奖励要合理，不能太离谱。"""

        user_prompt = f"""玩家：{player_info.get('name', '少侠')}，等级{player_info.get('level', 1)}，{player_info.get('faction_name', '无门无派')}
道德值：{player_info.get('daode', 0)}
{npc_str}
触发原因：{trigger_reason}
{behavior_str}

请生成一个奇遇事件，返回JSON格式：
{{
    "title": "奇遇标题(4-6字)",
    "description": "奇遇描述(30-80字，要有武侠小说风格，生动描绘场景)",
    "type": "奇遇类型",
    "reward": {{"exp": 经验值, "pot": 潜能值, "money": 银两, "item": "物品id(可选)", "skill_exp": 技能经验(可选), "daode": 道德变化(可选)}},
    "rarity": "稀有度(common/rare/epic/legendary)"
}}"""

        result = self._call_llm(system_prompt, user_prompt, temperature=0.9, max_tokens=400, json_mode=True)
        if result:
            try:
                parsed = json.loads(result)
                parsed.setdefault("rarity", "common")
                return parsed
            except json.JSONDecodeError:
                pass
        return None

    def _generate_mock_encounter(self, player_info: Dict, trigger_reason: str,
                                  player_behavior: Dict) -> Optional[Dict]:
        encounter = random.choice(MOCK_ENCOUNTERS).copy()

        player_level = player_info.get("level", 1)
        daode = player_info.get("daode", 0)

        if daode > 50:
            rare_encounters = [
                {"title": "仙人托梦", "description": "夜半时分，你在梦中得到仙人指点，醒来后感觉功力精进！",
                 "type": "stat_boost", "reward": {"exp": player_level * 100, "pot": player_level * 20}, "rarity": "rare"},
                {"title": "侠义昭彰", "description": "你的善行传遍江湖，正派人士纷纷前来结交！",
                 "type": "faction_event", "reward": {"daode": 20, "exp": player_level * 50}, "rarity": "rare"},
            ]
            if random.random() < 0.3:
                encounter = random.choice(rare_encounters).copy()

        if player_behavior and player_behavior.get("consecutive_kills", 0) >= 5:
            encounter = {
                "title": "杀气冲天", "description": "你杀气太重，引来了一位神秘剑客的注意！他似乎想考验你的实力。",
                 "type": "master_appear", "reward": {"exp": player_level * 150, "pot": player_level * 30}, "rarity": "epic",
            }

        for key in ("exp", "pot", "money"):
            if key in encounter.get("reward", {}):
                encounter["reward"][key] = int(encounter["reward"][key] * (1 + player_level * 0.1))

        encounter.setdefault("rarity", "common")
        return encounter

    def generate_dialogue_async(self, npc_info: Dict, player_info: Dict, player_input: str = "",
                                 context: List[str] = None, dialogue_history: List[Dict] = None,
                                 callback: Callable = None) -> str:
        request_id = f"dlg_{npc_info.get('id', 0)}_{int(time.time() * 1000)}"

        mock_result = self._generate_mock_dialogue(npc_info, player_info, player_input)

        if self.api_type != "mock" and self.client:
            def llm_call():
                result = self._generate_llm_dialogue(npc_info, player_info, player_input, context, dialogue_history)
                return result

            self._async_manager.submit(request_id, llm_call, callback)

        return mock_result

    def check_async_result(self, request_id: str) -> Optional[str]:
        if self._async_manager.has_result(request_id):
            return self._async_manager.get_result(request_id)
        return None

    def shutdown(self):
        self._async_manager.stop()
        self._cache.clear()


def get_llm_client() -> LLMClient:
    return LLMClient()


def init_llm_client(api_type: str = "mock", api_key: str = "", base_url: str = "", model: str = "") -> None:
    LLMClient(api_type, api_key, base_url, model)
