#!/usr/bin/env python3
"""Generate all new game content: regions, NPCs, enemies, items, quests, connections, and dialogues."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "godot_project" / "data"
SCRIPT = ROOT / "godot_project" / "scripts" / "systems"

def load_json(name: str):
    return json.loads((DATA / name).read_text(encoding="utf-8"))

def save_json(name: str, data):
    path = DATA / name
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  wrote {path}")

# ── Load existing data ──────────────────────────────────────────────
regions = load_json("regions.json")
npcs = load_json("npcs.json")
items = load_json("items.json")
quests = load_json("quests.json")
region_points = load_json("region_points.json")
region_connections = load_json("region_connections.json")
region_shops = load_json("region_shops.json")
region_market = load_json("region_market_modifiers.json")

existing_region_ids = {r["id"] for r in regions}
existing_npc_names = {n["name"] for n in npcs}
existing_item_ids = {i["id"] for i in items}
existing_npc_ids = {n.get("id") for n in npcs if n.get("id")}

print(f"Loaded: {len(regions)} regions, {len(npcs)} NPCs, {len(items)} items, {len(quests)} quests")

# ═══════════════════════════════════════════════════════════════════
# 1. NEW REGIONS (all wild - 10 regions)
# ═══════════════════════════════════════════════════════════════════
new_regions = [
    {"id": "desert_road", "name": "沙漠古道", "type": "wild", "parent": "changan",
     "rect": [0, 31, 14, 8], "center": [7, 35], "danger": 3, "terrain": "desert",
     "description": "西域商旅必经的荒凉古道，黄沙中埋藏着无数旧物。"},
    {"id": "longmen_inn", "name": "龙门客栈", "type": "wild", "parent": "changan",
     "rect": [0, 39, 6, 6], "center": [3, 42], "danger": 3, "terrain": "oasis",
     "description": "西域荒漠中的绿洲客栈，鱼龙混杂，消息四通八达。"},
    {"id": "flame_valley", "name": "火焰谷", "type": "wild", "parent": "luoyang",
     "rect": [36, 0, 10, 8], "center": [41, 4], "danger": 4, "terrain": "volcanic",
     "description": "地火奔涌的灼热峡谷，寻常武者难以久留。"},
    {"id": "ice_cave", "name": "寒冰洞", "type": "wild", "parent": "luoyang",
     "rect": [46, 0, 8, 7], "center": [50, 3], "danger": 4, "terrain": "ice_cave",
     "description": "万年寒冰封冻的洞穴，深处藏有上古遗物。"},
    {"id": "mojiao_branch", "name": "魔教分舵", "type": "wild", "parent": "jiangling",
     "rect": [34, 39, 8, 8], "center": [38, 43], "danger": 3, "terrain": "fortress",
     "description": "魔教在江南的隐秘据点，戒备森严。"},
    {"id": "mojiao_base", "name": "魔教总坛", "type": "wild", "parent": "jiangling",
     "rect": [34, 47, 8, 8], "center": [38, 51], "danger": 5, "terrain": "fortress",
     "description": "魔教核心巢穴，护法坐镇，机关重重。"},
    {"id": "yaowang_valley", "name": "药王谷", "type": "wild", "parent": "chengdu",
     "rect": [0, 44, 6, 6], "center": [3, 47], "danger": 2, "terrain": "valley",
     "description": "隐于群山间的灵药山谷，奇花异草遍地。"},
    {"id": "painting_world", "name": "画中仙境", "type": "wild", "parent": "linan",
     "rect": [52, 0, 6, 8], "center": [55, 4], "danger": 1, "terrain": "mystic",
     "description": "神秘画卷中的世外仙境，山水如墨，岁月静好。"},
    {"id": "tianji_pavilion", "name": "天机阁秘境", "type": "wild", "parent": "changan",
     "rect": [86, 16, 8, 6], "center": [90, 19], "danger": 4, "terrain": "mountain",
     "description": "天机阁的隐蔽洞府，传闻藏有绝���武学。"},
    {"id": "wanshou_mtn", "name": "万兽山", "type": "wild", "parent": "jiangling",
     "rect": [86, 22, 8, 6], "center": [90, 25], "danger": 3, "terrain": "forest",
     "description": "百兽聚集的深山密林，灵兽与凶兽并存。"},
]

# ═══════════════════════════════════════════════════════════════════
# 2. NEW ITEMS (quest items, consumables, equipment)
# ═══════════════════════════════════════════════════════════════════
new_items = [
    # Quest items - 西域秘宝 chain
    {"id": "item_ancient_map", "name": "西域古地图", "type": "quest", "price": 0,
     "description": "一张泛黄的羊皮古地图，标记着西域秘境的位置。", "effects": {}},
    {"id": "item_map_frag_1", "name": "地图碎片·日", "type": "quest", "price": 0,
     "description": "古地图的三分之一，上面绘有太阳标记。", "effects": {}},
    {"id": "item_map_frag_2", "name": "地图碎片·月", "type": "quest", "price": 0,
     "description": "古地图的三分之一，上面绘有月亮标记。", "effects": {}},
    {"id": "item_map_frag_3", "name": "地图碎片·星", "type": "quest", "price": 0,
     "description": "古地图的三分之一，上面绘有星辰标记。", "effects": {}},
    {"id": "item_secret_key", "name": "秘境钥匙", "type": "quest", "price": 0,
     "description": "融合三块碎片后形成的完整密钥，可打开秘境之门。", "effects": {}},
    {"id": "item_desert_gem", "name": "沙漠之心", "type": "accessory", "price": 2000,
     "description": "西域秘境的至宝，一颗会散发温热光芒的宝石。",
     "effects": {"attack": 15, "defense": 10, "hp_max": 50}, "slot": "accessory", "rarity": "legendary"},
    # Quest items - 魔教暗影 chain
    {"id": "item_mojiao_letter", "name": "魔教密信", "type": "quest", "price": 0,
     "description": "截获的魔教密信，上面写有暗号指令。", "effects": {}},
    {"id": "item_mojiao_token", "name": "魔教令牌", "type": "quest", "price": 0,
     "description": "魔教弟子令牌，可在分舵通行。", "effects": {}},
    {"id": "item_evidence_list", "name": "阴谋证据", "type": "quest", "price": 0,
     "description": "魔教与朝廷官员勾结的证据文书。", "effects": {}},
    # Quest items - 药王谷 chain
    {"id": "item_herb_xuelian", "name": "雪莲花", "type": "material", "price": 80,
     "description": "生长在高山雪线之上的珍稀药材。", "effects": {}},
    {"id": "item_herb_huoling", "name": "火灵芝", "type": "material", "price": 100,
     "description": "火山地热带的罕见灵芝，药性极热。", "effects": {}},
    {"id": "item_herb_longxu", "name": "龙须草", "type": "material", "price": 60,
     "description": "形如龙须的灵草，是多种丹药的药引。", "effects": {}},
    {"id": "item_dan_formula", "name": "九转玉露丹方", "type": "quest", "price": 0,
     "description": "药王谷秘传的丹药配方，可炼出顶级疗伤药。", "effects": {}},
    # Quest items - 神偷 chain
    {"id": "item_thief_note", "name": "神偷留书", "type": "quest", "price": 0,
     "description": "神偷留在案发现场的嘲讽字条。", "effects": {}},
    {"id": "item_stolen_vase", "name": "失窃玉瓶", "type": "quest", "price": 0,
     "description": "被神偷盗走的羊脂玉瓶，价值连城。", "effects": {}},
    {"id": "item_stolen_ring", "name": "翡翠戒指", "type": "quest", "price": 0,
     "description": "被神偷盗走的翡翠戒指，是某位富商的传家宝。", "effects": {}},
    {"id": "item_stolen_scroll", "name": "名家字画", "type": "quest", "price": 0,
     "description": "被神偷盗走的古画，落款是前朝大家。", "effects": {}},
    # Quest items - 画中仙境 chain
    {"id": "item_mystery_scroll", "name": "神秘画卷", "type": "quest", "price": 0,
     "description": "一幅古旧的山水画卷，展开时隐隐有流光转动。", "effects": {}},
    {"id": "item_painting_brush", "name": "画仙笔", "type": "quest", "price": 0,
     "description": "画中仙境遗留的仙笔，蕴含一丝造化之力。", "effects": {}},
    # New consumables
    {"id": "item_huiqi_dan", "name": "回气丹", "type": "consumable", "price": 50,
     "description": "快速恢复内力的丹药。", "effects": {"mp": 50}},
    {"id": "item_bazhen_dan", "name": "八珍玉露", "type": "consumable", "price": 150,
     "description": "八种珍药炼制的大补丹，大幅恢复气血。", "effects": {"hp": 200, "mp": 50}},
]

# New equipment items for reward
new_equipment = [
    {"id": "item_desert_blade", "name": "沙漠弯刀", "type": "weapon", "price": 800,
     "description": "西域工匠打造的弯刀，刀身带有月牙纹路。",
     "effects": {"attack": 28, "speed": 5}, "weapon_type": "blade", "slot": "hand", "rarity": "rare"},
    {"id": "item_frost_sword", "name": "寒冰剑", "type": "weapon", "price": 1000,
     "description": "寒冰洞深处的冰晶铸剑，剑身寒气逼人。",
     "effects": {"attack": 30, "mp_max": 30}, "weapon_type": "sword", "slot": "hand", "rarity": "rare"},
    {"id": "item_mojiao_armor", "name": "魔教玄铁甲", "type": "armor", "price": 900,
     "description": "魔教精英的制式铠甲，以玄铁打造。",
     "effects": {"defense": 25, "hp_max": 60}, "slot": "body", "rarity": "rare"},
    {"id": "item_mojiao_ring", "name": "暗影指环", "type": "accessory", "price": 600,
     "description": "魔教护法的贴身饰物，蕴含阴寒之力。",
     "effects": {"attack": 12, "mp_steal": 3}, "slot": "accessory", "rarity": "rare"},
    {"id": "item_yaowang_robe", "name": "药王袍", "type": "armor", "price": 700,
     "description": "药王谷传人的采药袍，以百草药汁浸染。",
     "effects": {"defense": 18, "hp_max": 80}, "slot": "body", "rarity": "rare"},
    # Drop items from new enemies
    {"id": "item_scorpion_poison", "name": "蝎毒囊", "type": "material", "price": 30,
     "description": "沙漠蝎的毒囊，可用于炼毒制药。", "effects": {}},
    {"id": "item_ice_essence", "name": "冰魄精华", "type": "material", "price": 50,
     "description": "从冰魄蛇体内取出的寒晶，蕴含纯阴之力。", "effects": {}},
    {"id": "item_spider_silk", "name": "毒蛛丝", "type": "material", "price": 25,
     "description": "毒蛛吐出的坚韧丝线，可织入护甲。", "effects": {}},
    {"id": "item_stone_core", "name": "石傀儡核心", "type": "material", "price": 80,
     "description": "石傀儡的能量核心，坚硬无比。", "effects": {}},
    {"id": "item_bat_blood", "name": "血蝠精血", "type": "material", "price": 20,
     "description": "血蝠的纯净精血，可入药。", "effects": {}},
    {"id": "item_sword_spirit", "name": "剑意残魂", "type": "material", "price": 100,
     "description": "剑灵消散后残留的剑意精华。", "effects": {}},
]

# ═══════════════════════════════════════════════════════════════════
# 3. NEW NPCS (story NPCs + enemies)
# ═══════════════════════════════════════════════════════════════════
new_npcs_story = [
    {"id": 319, "name": "西域商人", "npc_type": "trader", "faction": "none",
     "personality": "精明圆滑", "description": "从西域而来的行脚商人，手里有不少稀罕物件，也知晓许多西域秘闻。",
     "level": 10, "hp": 150, "max_hp": 150, "mp": 60, "max_mp": 60,
     "attack": 12, "defense": 8, "damage": 6, "money": 1500, "exp_reward": 40,
     "sell_items": ["item_huiqi_dan", "item_ancient_map"],
     "pos_x": 3, "pos_y": 42, "has_quests": True},

    {"id": 320, "name": "药童", "npc_type": "normal", "faction": "none",
     "personality": "胆小善良", "description": "药王谷老医师的小徒弟，背着竹筐在山谷间采药。",
     "level": 5, "hp": 80, "max_hp": 80, "mp": 40, "max_mp": 40,
     "attack": 6, "defense": 4, "damage": 3, "money": 80, "exp_reward": 20,
     "pos_x": 3, "pos_y": 47, "has_quests": True,
     "title": "采药学徒"},

    {"id": 321, "name": "神偷", "npc_type": "normal", "faction": "none",
     "personality": "狡猾自负", "description": "江湖上赫赫有名的盗贼，轻功绝世，专盗富户珍藏。",
     "level": 20, "hp": 350, "max_hp": 350, "mp": 200, "max_mp": 200,
     "attack": 35, "defense": 18, "damage": 18, "money": 500, "exp_reward": 200,
     "pos_x": 44, "pos_y": 25, "has_quests": True,
     "title": "江湖第一神偷"},

    {"id": 322, "name": "卧底", "npc_type": "normal", "faction": "none",
     "personality": "沉稳隐忍", "description": "潜伏在魔教的正派卧底，掌握魔教内部情报。",
     "level": 15, "hp": 240, "max_hp": 240, "mp": 120, "max_mp": 120,
     "attack": 22, "defense": 14, "damage": 12, "money": 200, "exp_reward": 100,
     "pos_x": 66, "pos_y": 45, "has_quests": True},

    {"id": 323, "name": "秘境守护者", "npc_type": "master", "faction": "none",
     "personality": "沉默威严", "description": "西域秘境的守护者，世代守卫秘境入口，考验每一个进入者的资格。",
     "level": 22, "hp": 600, "max_hp": 600, "mp": 200, "max_mp": 200,
     "attack": 50, "defense": 30, "damage": 28, "money": 300, "exp_reward": 250,
     "pos_x": 7, "pos_y": 35, "teach_skills": [], "has_quests": False,
     "title": "秘境守门人"},
]

new_enemies = [
    {"id": 324, "name": "沙漠蝎", "npc_type": "enemy", "faction": "none",
     "personality": "凶悍", "description": "沙漠中常见的毒蝎，体型巨大，尾钩含剧毒。",
     "level": 8, "hp": 200, "max_hp": 200, "mp": 30, "max_mp": 30,
     "attack": 22, "defense": 10, "speed": 8, "damage": 12,
     "exp_reward": 50, "money": 15,
     "combat_style": "beast",
     "loot": [{"item": "item_scorpion_poison", "chance": 40}],
     "spawn_regions": ["desert_road", "longxi_desert"],
     "spawn_rate": 0.4},

    {"id": 325, "name": "冰魄蛇", "npc_type": "enemy", "faction": "none",
     "personality": "阴冷", "description": "栖息于万年寒冰中的灵蛇，吐息能冻结血脉。",
     "level": 14, "hp": 320, "max_hp": 320, "mp": 80, "max_mp": 80,
     "attack": 32, "defense": 14, "speed": 12, "damage": 18,
     "exp_reward": 90, "money": 25,
     "combat_style": "assassin",
     "loot": [{"item": "item_ice_essence", "chance": 35}],
     "spawn_regions": ["ice_cave", "xueshan_sect"],
     "spawn_rate": 0.35},

    {"id": 326, "name": "魔教精英", "npc_type": "enemy", "faction": "none",
     "personality": "凶狠", "description": "魔教精心培养的精英弟子，武艺精湛，纪律严明。",
     "level": 12, "hp": 280, "max_hp": 280, "mp": 60, "max_mp": 60,
     "attack": 28, "defense": 16, "speed": 8, "damage": 16,
     "exp_reward": 80, "money": 30,
     "combat_style": "brawler",
     "loot": [{"item": "item_mojiao_armor", "chance": 5}, {"item": "item_huiqi_dan", "chance": 20}],
     "spawn_regions": ["mojiao_branch", "mojiao_base"],
     "spawn_rate": 0.45},

    {"id": 327, "name": "毒蛛", "npc_type": "enemy", "faction": "none",
     "personality": "凶残", "description": "密林深处的巨型毒蜘蛛，蛛丝坚韧如钢，毒液致命。",
     "level": 6, "hp": 150, "max_hp": 150, "mp": 40, "max_mp": 40,
     "attack": 18, "defense": 8, "speed": 10, "damage": 10,
     "exp_reward": 40, "money": 10,
     "combat_style": "assassin",
     "loot": [{"item": "item_spider_silk", "chance": 45}],
     "spawn_regions": ["shennongjia", "bashu_bamboo", "wanshou_mtn"],
     "spawn_rate": 0.4},

    {"id": 328, "name": "石傀儡", "npc_type": "enemy", "faction": "none",
     "personality": "机械", "description": "由上古机关术驱动的石人傀儡，力大无穷，不知疼痛。",
     "level": 18, "hp": 500, "max_hp": 500, "mp": 0, "max_mp": 0,
     "attack": 40, "defense": 30, "speed": 4, "damage": 25,
     "exp_reward": 140, "money": 40,
     "combat_style": "brute",
     "loot": [{"item": "item_stone_core", "chance": 30}],
     "spawn_regions": ["tianji_pavilion", "flame_valley"],
     "spawn_rate": 0.3},

    {"id": 329, "name": "血蝠", "npc_type": "enemy", "faction": "none",
     "personality": "嗜血", "description": "群居于阴暗洞穴的血红色蝙蝠，喜食鲜血。",
     "level": 4, "hp": 100, "max_hp": 100, "mp": 20, "max_mp": 20,
     "attack": 14, "defense": 4, "speed": 14, "damage": 8,
     "exp_reward": 25, "money": 5,
     "combat_style": "beast",
     "loot": [{"item": "item_bat_blood", "chance": 50}],
     "spawn_regions": ["ice_cave", "zhongtiao_mtn", "taihang_range"],
     "spawn_rate": 0.5},

    {"id": 330, "name": "剑灵", "npc_type": "enemy", "faction": "none",
     "personality": "孤高", "description": "古剑中孕育的剑意之灵，无形无质，剑招凌厉。",
     "level": 12, "hp": 250, "max_hp": 250, "mp": 100, "max_mp": 100,
     "attack": 36, "defense": 10, "speed": 14, "damage": 20,
     "exp_reward": 100, "money": 20,
     "combat_style": "assassin",
     "loot": [{"item": "item_sword_spirit", "chance": 25}],
     "spawn_regions": ["painting_world", "tianji_pavilion"],
     "spawn_rate": 0.25},

    {"id": 331, "name": "魔教护法", "npc_type": "enemy", "faction": "none",
     "personality": "暴戾", "description": "魔教左护法，武功高强，是教主的左膀右臂。",
     "level": 22, "hp": 800, "max_hp": 800, "mp": 200, "max_mp": 200,
     "attack": 55, "defense": 28, "speed": 10, "damage": 30,
     "exp_reward": 300, "money": 100,
     "combat_style": "boss",
     "loot": [{"item": "item_mojiao_ring", "chance": 40}],
     "spawn_regions": ["mojiao_base"],
     "spawn_rate": 0.15},

    {"id": 332, "name": "魔教密探", "npc_type": "enemy", "faction": "none",
     "personality": "狡猾", "description": "潜伏在城镇中的魔教密探，善于伪装和暗杀。",
     "level": 10, "hp": 220, "max_hp": 220, "mp": 60, "max_mp": 60,
     "attack": 24, "defense": 12, "speed": 12, "damage": 14,
     "exp_reward": 60, "money": 20,
     "combat_style": "assassin",
     "loot": [{"item": "item_mojiao_letter", "chance": 15}],
     "spawn_regions": ["qinghe", "luoyang", "changan", "chengdu"],
     "spawn_rate": 0.2},
]

all_new_npcs = new_npcs_story + new_enemies

# ═══════════════════════════════════════════════════════════════════
# 4. NEW QUESTS
# ═══════════════════════════════════════════════════════════════════
new_quests = [
    # ── Chain 1: 西域秘宝 (4 quests) ──
    {
        "id": "q_west_treasure_1",
        "title": "西域古图",
        "giver": "西域商人",
        "description": "西域商人在龙门客栈展示了一张古老的西域地图，但只有三分之一。商人请你帮忙凑齐另外两块碎片：一块在沙漠蝎出没的古道深处，一块在龙门客栈的地下黑市。",
        "next_hint": "三块碎片凑齐后回龙门客栈找商人拼合地图。",
        "objectives": [
            {"type": "talk", "target": "西域商人", "count": 1, "label": "向西域商人接取古图"},
            {"type": "collect", "target": "item_map_frag_1", "count": 1, "label": "击败沙漠蝎取得第一块碎片"},
            {"type": "kill", "target": "沙漠蝎", "count": 2, "label": "在沙漠古道搜寻碎片线索"}
        ],
        "rewards": {"exp": 200, "money": 100, "daode": 3, "items": {"item_ancient_map": 1}}
    },
    {
        "id": "q_west_treasure_2",
        "title": "碎片之谜",
        "giver": "西域商人",
        "description": "西域商人发现古地图需要三块碎片合一才能显示秘境位置。第二块碎片据说在火焰谷的火山口附近，第三块碎片则在寒冰洞的深处。",
        "requires_completed": ["q_west_treasure_1"],
        "next_hint": "集齐三块碎片后找到西域商人拼合。",
        "objectives": [
            {"type": "collect", "target": "item_map_frag_2", "count": 1, "label": "在火焰谷找到碎片·月"},
            {"type": "collect", "target": "item_map_frag_3", "count": 1, "label": "在寒冰洞找到碎片·星"}
        ],
        "rewards": {"exp": 300, "money": 150, "daode": 4, "items": {"item_secret_key": 1}}
    },
    {
        "id": "q_west_treasure_3",
        "title": "秘境之门",
        "giver": "西域商人",
        "description": "三块碎片拼合后形成了一把秘境钥匙。西域商人指引你前往沙漠古道深处的一处隐秘入口。你必须击败守门的秘境守护者才能进入。",
        "requires_completed": ["q_west_treasure_2"],
        "min_level": 4,
        "next_hint": "带着秘境钥匙前往沙漠古道深处的秘境入口。",
        "objectives": [
            {"type": "talk", "target": "秘境守护者", "count": 1, "label": "在秘境入口遇到守护者"},
            {"type": "kill", "target": "秘境守护者", "count": 1, "label": "击败秘境守护者"}
        ],
        "rewards": {"exp": 400, "money": 200, "daode": 5, "items": {"item_dan": 2}}
    },
    {
        "id": "q_west_treasure_4",
        "title": "西域秘宝",
        "giver": "西域商人",
        "description": "击败守护者后，秘境深处藏着一件上古至宝——沙漠之心。西域商人让你将宝物带回龙门客栈，完成这趟西域寻宝之旅。",
        "requires_completed": ["q_west_treasure_3"],
        "min_level": 5,
        "objectives": [
            {"type": "collect", "target": "item_desert_gem", "count": 1, "label": "取得沙漠之心"},
            {"type": "talk", "target": "西域商人", "count": 1, "label": "回龙门客栈复命"}
        ],
        "rewards": {"exp": 600, "money": 400, "daode": 6, "items": {"item_desert_gem": 1, "item_desert_blade": 1}}
    },

    # ── Chain 2: 魔教暗影 (6 quests) ──
    {
        "id": "q_mojiao_1",
        "title": "魔教踪迹",
        "giver": "赵德",
        "description": "洛阳捕头赵德发现近日城中出现了形迹可疑之人，疑似魔教密探。他请你帮忙在洛阳城内外打探消息，找到那名密探。",
        "next_hint": "在洛阳城中寻找魔教密探的线索。",
        "objectives": [
            {"type": "talk", "target": "赵德", "count": 1, "label": "接受赵德的委托"},
            {"type": "kill", "target": "魔教密探", "count": 1, "label": "击败魔教密探并缴获密信"}
        ],
        "rewards": {"exp": 180, "money": 100, "daode": 3, "items": {"item_mojiao_letter": 1}}
    },
    {
        "id": "q_mojiao_2",
        "title": "暗流追踪",
        "giver": "赵无极",
        "description": "赵无极辨认出密信上的暗号指向长安和成都两地的魔教据点。他让你分别前往长安和成都调查，找到更多线索。",
        "requires_completed": ["q_mojiao_1"],
        "min_level": 2,
        "next_hint": "前往长安和成都调查魔教线索。",
        "objectives": [
            {"type": "talk", "target": "陈天行", "count": 1, "label": "在长安向陈天行请教魔教消息"},
            {"type": "talk", "target": "烈火", "count": 1, "label": "在成都附近拜访烈火打探消息"}
        ],
        "rewards": {"exp": 240, "money": 120, "daode": 3, "items": {"item_dan": 1}}
    },
    {
        "id": "q_mojiao_3",
        "title": "卧底接头",
        "giver": "陈天行",
        "description": "陈天行告诉你魔教内部有一位正派卧底，可以接头获取情报。但接头需小心行事——卧底约定在江陵城外的伏牛山碰面。",
        "requires_completed": ["q_mojiao_2"],
        "next_hint": "前往伏牛山与卧底接头。",
        "objectives": [
            {"type": "talk", "target": "卧底", "count": 1, "label": "在伏牛山与卧底接头"},
            {"type": "kill", "target": "魔教精英", "count": 1, "label": "击败跟踪而来的魔教精英"}
        ],
        "rewards": {"exp": 320, "money": 160, "daode": 4, "items": {"item_mojiao_token": 1, "item_shengji": 1}}
    },
    {
        "id": "q_mojiao_4",
        "title": "魔教阴谋",
        "giver": "卧底",
        "description": "卧底告知魔教正与朝廷中的贪官勾结，密谋颠覆武林盟。你需要前往魔教分舵搜集更多证据。卧底给了你一块魔教令牌用于混入分舵。",
        "requires_completed": ["q_mojiao_3"],
        "min_level": 3,
        "next_hint": "前往魔教分舵搜集阴谋证据。",
        "objectives": [
            {"type": "collect", "target": "item_evidence_list", "count": 1, "label": "从魔教分舵窃取阴谋证据"},
            {"type": "kill", "target": "魔教精英", "count": 2, "label": "击败守卫分舵的魔教精英"}
        ],
        "rewards": {"exp": 450, "money": 250, "daode": 5, "items": {"item_evidence_list": 1, "item_mojiao_armor": 1}}
    },
    {
        "id": "q_mojiao_5",
        "title": "攻打分舵",
        "giver": "卧底",
        "description": "证据到手后，卧底建议你联合武林盟的力量攻打魔教分舵。赵无极愿意提供人手，但需要你先清除分舵外围的守卫。",
        "requires_completed": ["q_mojiao_4"],
        "min_level": 4,
        "next_hint": "带领武林盟弟子攻打魔教分舵。",
        "objectives": [
            {"type": "talk", "target": "赵无极", "count": 1, "label": "请赵无极调派武林盟人手"},
            {"type": "kill", "target": "魔教精英", "count": 3, "label": "清除魔教分舵守卫"}
        ],
        "rewards": {"exp": 600, "money": 400, "daode": 6, "items": {"item_shengji": 2}}
    },
    {
        "id": "q_mojiao_6",
        "title": "决战护法",
        "giver": "卧底",
        "description": "分舵被破后，魔教护法震怒，亲自坐镇总坛。卧底传来消息，护法放话要让武林盟血债血偿。你必须前往魔教总坛，与护法决一死战。",
        "requires_completed": ["q_mojiao_5"],
        "min_level": 5,
        "objectives": [
            {"type": "kill", "target": "魔教护法", "count": 1, "label": "击败魔教护法"},
            {"type": "talk", "target": "赵德", "count": 1, "label": "回洛阳向赵德复命"}
        ],
        "rewards": {"exp": 800, "money": 600, "daode": 8, "items": {"item_mojiao_ring": 1, "item_dan": 3}}
    },

    # ── Side A: 药王谷传人 (4 quests) ──
    {
        "id": "q_yaowang_1",
        "title": "采药初试",
        "giver": "药童",
        "description": "药童在山谷中采药时不慎摔伤了腿，他请你帮忙采集三种珍稀药材：雪莲花、火灵芝和龙须草。",
        "next_hint": "在各地采集三种药材。",
        "objectives": [
            {"type": "collect", "target": "item_herb_xuelian", "count": 1, "label": "采集雪莲花"},
            {"type": "collect", "target": "item_herb_huoling", "count": 1, "label": "采集火灵芝"},
            {"type": "collect", "target": "item_herb_longxu", "count": 1, "label": "采集龙须草"}
        ],
        "rewards": {"exp": 150, "money": 80, "daode": 2}
    },
    {
        "id": "q_yaowang_2",
        "title": "试药考验",
        "giver": "药童",
        "description": "药童感激你的帮助，但他说药王谷的规矩是外人必须亲身试药才能获得信任。他调配了一副猛药，请你服下考验体质。",
        "requires_completed": ["q_yaowang_1"],
        "next_hint": "服下药童调配的汤药接受考验。",
        "objectives": [
            {"type": "collect", "target": "item_bazhen_dan", "count": 1, "label": "试服药童调配的八珍玉露"}
        ],
        "rewards": {"exp": 200, "money": 100, "daode": 3, "items": {"item_yaowang_robe": 1}}
    },
    {
        "id": "q_yaowang_3",
        "title": "药谷除害",
        "giver": "药童",
        "description": "药童告诉你山谷附近来了一群毒蛛，威胁到了药田的安全。他请你帮忙清除毒蛛，保护药王谷的灵药。",
        "requires_completed": ["q_yaowang_2"],
        "objectives": [
            {"type": "kill", "target": "毒蛛", "count": 3, "label": "清除药王谷附近的毒蛛"}
        ],
        "rewards": {"exp": 250, "money": 120, "daode": 4}
    },
    {
        "id": "q_yaowang_4",
        "title": "丹方传承",
        "giver": "药童",
        "description": "药童被你的诚心打动，将药王谷秘传的九转玉露丹方赠予你。他希望你用此丹方造福武林，悬壶济世。",
        "requires_completed": ["q_yaowang_3"],
        "objectives": [
            {"type": "talk", "target": "药童", "count": 1, "label": "接受药王谷丹方传承"}
        ],
        "rewards": {"exp": 350, "money": 200, "daode": 5, "items": {"item_dan_formula": 1, "item_yaowang_robe": 1}}
    },

    # ── Side B: 神偷遗物 (4 quests) ──
    {
        "id": "q_thief_1",
        "title": "连环失窃",
        "giver": "赵德",
        "description": "洛阳接连发生多起盗窃案，富商们的珍藏接连失窃。赵德请你协助调查，现场发现了一张神偷留书。",
        "next_hint": "调查盗窃案现场，追踪神偷的线索。",
        "objectives": [
            {"type": "talk", "target": "赵德", "count": 1, "label": "向赵德了解案情"},
            {"type": "collect", "target": "item_thief_note", "count": 1, "label": "找到神偷留书"}
        ],
        "rewards": {"exp": 120, "money": 80, "daode": 2}
    },
    {
        "id": "q_thief_2",
        "title": "神偷踪迹",
        "giver": "陈天行",
        "description": '陈天行认出神偷留书的字迹——这是十年前便已销声匿迹的\u201c鬼手\u201d的记号。他告诉你神偷可能会在长安出现，因为那里有几件值得出手的宝物。',
        "requires_completed": ["q_thief_1"],
        "next_hint": "前往长安寻找神偷的踪迹。",
        "objectives": [
            {"type": "talk", "target": "陈天行", "count": 1, "label": "请陈天行分析神偷线索"},
            {"type": "talk", "target": "王铁山", "count": 1, "label": "向铁匠王铁山打听失物销赃去向"}
        ],
        "rewards": {"exp": 180, "money": 100, "daode": 3}
    },
    {
        "id": "q_thief_3",
        "title": "追回失物",
        "giver": "陈天行",
        "description": "陈天行查到了神偷在长安销赃的渠道。有三件失物——玉瓶、翡翠戒指和名家字画——分别流入了不同的买家手中。请你去找回这些失物作为神偷的罪证。",
        "requires_completed": ["q_thief_2"],
        "next_hint": "追回三件失窃宝物。",
        "objectives": [
            {"type": "collect", "target": "item_stolen_vase", "count": 1, "label": "追回失窃玉瓶"},
            {"type": "collect", "target": "item_stolen_ring", "count": 1, "label": "追回翡翠戒指"},
            {"type": "collect", "target": "item_stolen_scroll", "count": 1, "label": "追回名家字画"}
        ],
        "rewards": {"exp": 250, "money": 150, "daode": 4, "items": {"item_dan": 1}}
    },
    {
        "id": "q_thief_4",
        "title": "最终对决",
        "giver": "赵德",
        "description": "赵德根据失物追回的线索锁定了神偷的藏身之处——洛阳东市的一座旧宅。他请你一起去抓捕神偷，但神偷的武功不容小觑。",
        "requires_completed": ["q_thief_3"],
        "min_level": 3,
        "objectives": [
            {"type": "kill", "target": "神偷", "count": 1, "label": "击败神偷"},
            {"type": "talk", "target": "赵德", "count": 1, "label": "将神偷交给赵德法办"}
        ],
        "rewards": {"exp": 400, "money": 300, "daode": 5, "items": {"item_fine_cloth": 1, "item_shengji": 1}}
    },

    # ── Side C: 画中仙境 (3 quests) ──
    {
        "id": "q_painting_1",
        "title": "神秘画卷",
        "giver": "逍遥子",
        "description": "逍遥子在游历时得到一幅古画，画中景致栩栩如生，隐隐有灵气流转。他请你帮忙研究这幅画的来历，或许与画中仙境有关。",
        "next_hint": "寻找关于神秘画卷的线索。",
        "objectives": [
            {"type": "talk", "target": "逍遥子", "count": 1, "label": "从逍遥子处接下画卷"},
            {"type": "talk", "target": "玄机子", "count": 1, "label": "请玄机子鉴定画卷阵法纹路"}
        ],
        "rewards": {"exp": 100, "money": 60, "daode": 2, "items": {"item_mystery_scroll": 1}}
    },
    {
        "id": "q_painting_2",
        "title": "画中天地",
        "giver": "逍遥子",
        "description": "玄机子发现这幅画是一件上古法器，可以用内力激活进入画中世界。逍遥子鼓励你一试——但画中世界虽然美丽，也可能暗藏玄机。",
        "requires_completed": ["q_painting_1"],
        "next_hint": "激活画卷，进入画中仙境探索。",
        "objectives": [
            {"type": "explore", "target": "painting_world", "count": 1, "label": "进入画中仙境探索"},
            {"type": "collect", "target": "item_painting_brush", "count": 1, "label": "在画中仙境找到画仙笔"}
        ],
        "rewards": {"exp": 200, "money": 100, "daode": 3}
    },
    {
        "id": "q_painting_3",
        "title": "画外之境",
        "giver": "逍遥子",
        "description": "你在画中仙境找到了一支画仙笔，这笔蕴含一丝造化之力。逍遥子说此笔可以画出通往秘境的门户，但需要领悟画中意境才能发挥其真正力量。",
        "requires_completed": ["q_painting_2"],
        "objectives": [
            {"type": "talk", "target": "逍遥子", "count": 1, "label": "向逍遥子请教画中意境"},
            {"type": "collect", "target": "item_painting_brush", "count": 1, "label": "领悟画仙笔的用法"}
        ],
        "rewards": {"exp": 300, "money": 150, "daode": 4, "items": {"item_painting_brush": 1}}
    },
]

# ═══════════════════════════════════════════════════════════════════
# 5. REGION CONNECTIONS
# ═══════════════════════════════════════════════════════════════════
new_connections = {
    "desert_road": [
        {"target": "changan", "type": "road"},
        {"target": "longmen_inn", "type": "road"},
        {"target": "yaowang_valley", "type": "mountain"},
        {"target": "flame_valley", "type": "secret"},
    ],
    "longmen_inn": [
        {"target": "desert_road", "type": "road"},
        {"target": "longxi_desert", "type": "road"},
        {"target": "yaowang_valley", "type": "road"},
    ],
    "flame_valley": [
        {"target": "desert_road", "type": "secret"},
        {"target": "ice_cave", "type": "mountain"},
        {"target": "songshan_peak", "type": "mountain"},
    ],
    "ice_cave": [
        {"target": "flame_valley", "type": "mountain"},
        {"target": "xueshan_sect", "type": "road"},
        {"target": "beiling_mtn", "type": "mountain"},
    ],
    "mojiao_branch": [
        {"target": "qinling_deep", "type": "secret"},
        {"target": "mojiao_base", "type": "road"},
        {"target": "dangyang_plain", "type": "road"},
    ],
    "mojiao_base": [
        {"target": "mojiao_branch", "type": "road"},
        {"target": "shennongjia", "type": "mountain"},
        {"target": "daba_mtn", "type": "secret"},
    ],
    "yaowang_valley": [
        {"target": "longmen_inn", "type": "road"},
        {"target": "desert_road", "type": "mountain"},
        {"target": "shudao_mtn", "type": "mountain"},
        {"target": "qingcheng_mtn", "type": "road"},
    ],
    "painting_world": [
        {"target": "huashan_cliff", "type": "secret"},
        {"target": "zhongtiao_mtn", "type": "mountain"},
    ],
    "tianji_pavilion": [
        {"target": "taihang_range", "type": "secret"},
        {"target": "mengjin_ford", "type": "mountain"},
        {"target": "zhongtiao_mtn", "type": "road"},
    ],
    "wanshou_mtn": [
        {"target": "mengjin_ford", "type": "road"},
        {"target": "taihang_range", "type": "forest"},
        {"target": "mengjin", "type": "road"},
    ],
}

# Also add reverse connections to existing regions
reverse_connections = {
    "changan": [{"target": "desert_road", "type": "road"}],
    "longxi_desert": [{"target": "longmen_inn", "type": "road"}],
    "songshan_peak": [{"target": "flame_valley", "type": "mountain"}],
    "xueshan_sect": [{"target": "ice_cave", "type": "road"}],
    "beiling_mtn": [{"target": "ice_cave", "type": "mountain"}],
    "qinling_deep": [{"target": "mojiao_branch", "type": "secret"}],
    "dangyang_plain": [{"target": "mojiao_branch", "type": "road"}],
    "shennongjia": [{"target": "mojiao_base", "type": "mountain"}],
    "daba_mtn": [{"target": "mojiao_base", "type": "secret"}],
    "shudao_mtn": [{"target": "yaowang_valley", "type": "mountain"}],
    "qingcheng_mtn": [{"target": "yaowang_valley", "type": "road"}],
    "huashan_cliff": [{"target": "painting_world", "type": "secret"}],
    "zhongtiao_mtn": [
        {"target": "painting_world", "type": "mountain"},
        {"target": "tianji_pavilion", "type": "road"},
    ],
    "taihang_range": [
        {"target": "tianji_pavilion", "type": "secret"},
        {"target": "wanshou_mtn", "type": "forest"},
    ],
    "mengjin_ford": [
        {"target": "tianji_pavilion", "type": "mountain"},
        {"target": "wanshou_mtn", "type": "road"},
    ],
    "mengjin": [{"target": "wanshou_mtn", "type": "road"}],
    # Add to connections that go TO new regions, avoid dupes
}

# ═══════════════════════════════════════════════════════════════════
# 6. REGION POINTS
# ═══════════════════════════════════════════════════════════════════
# Helper to create region points
def landmark(label, desc, kind, tile, reward_item=None):
    p = {"label": label, "description": desc, "kind": kind, "tile": tile}
    if reward_item:
        p["reward_item"] = reward_item
    return p

def resource(label, desc, kind, tile, reward_item=None, reward_count=1):
    p = {"label": label, "description": desc, "kind": kind, "tile": tile, "reward_count": reward_count}
    if reward_item:
        p["reward_item"] = reward_item
        p["reward_item"] = reward_item
    return p

new_region_points = {
    "desert_road": {
        "landmarks": [
            landmark("古道界碑", "风化已久的界碑，刻着模糊的西域文字", "ruin", [3, 2]),
            landmark("枯井", "一口已经干涸的古井，井底似乎有东西", "well", [8, 5]),
            landmark("秘境入口", "被巨石遮挡的入口，需要钥匙才能打开", "cave", [12, 3]),
        ],
        "resources": [
            resource("沙漠蝎巢穴", "沙漠蝎的出没之地", "herb", [6, 4], "item_scorpion_poison"),
        ]
    },
    "longmen_inn": {
        "landmarks": [
            landmark("龙门客栈", "西域最大的客栈，人来人往", "notice", [3, 3]),
            landmark("地下黑市", "客栈地下的秘密交易市场", "market", [5, 4]),
            landmark("水井", "绿洲中唯一的水源", "well", [1, 2]),
        ],
        "resources": [
            resource("商人摊位", "西域商人的固定摊位", "coin", [3, 3]),
        ]
    },
    "flame_valley": {
        "landmarks": [
            landmark("火山口", "喷涌着地火的巨大火山口", "cave", [5, 4]),
            landmark("熔岩池", "翻涌的岩浆散发着炙热", "water", [8, 2]),
        ],
        "resources": [
            resource("火灵芝生长地", "极热之地生长的珍稀药草", "herb", [9, 6], "item_herb_huoling"),
        ]
    },
    "ice_cave": {
        "landmarks": [
            landmark("冰晶大厅", "寒气最盛的洞窟中央大厅", "ruin", [4, 3]),
            landmark("上古祭坛", "冰封的祭坛上似乎刻有文字", "shrine", [6, 5]),
        ],
        "resources": [
            resource("寒冰水晶", "从洞壁上凝结的寒冰结晶", "herb", [7, 2], "item_ice_essence"),
        ]
    },
    "mojiao_branch": {
        "landmarks": [
            landmark("分舵大门", "魔教分舵的正门，有精英弟子把守", "notice", [4, 4]),
            landmark("议事厅", "魔教头目议事的大厅，墙上有地图", "ruin", [2, 2]),
        ],
        "resources": [
            resource("魔教仓库", "存放物资的库房", "cache", [6, 6]),
        ]
    },
    "mojiao_base": {
        "landmarks": [
            landmark("总坛大门", "巨大的黑铁大门，上面镶有魔教徽记", "notice", [4, 4]),
            landmark("护法大殿", "魔教护法的座殿，阴气森森", "shrine", [6, 3]),
        ],
        "resources": [
            resource("总坛宝库", "魔教积攒多年的珍宝", "cache", [2, 6], "item_mojiao_ring"),
        ]
    },
    "yaowang_valley": {
        "landmarks": [
            landmark("药王庐", "药童居住的茅庐，门口晒着药草", "notice", [3, 3]),
            landmark("百草园", "种植着各种珍稀药材的药圃", "herb", [5, 4]),
        ],
        "resources": [
            resource("药田", "生长着各种灵草的田野", "herb", [1, 2], "item_herb_xuelian"),
            resource("龙须草丛", "龙须草密集生长的地方", "herb", [4, 5], "item_herb_longxu"),
        ]
    },
    "painting_world": {
        "landmarks": [
            landmark("画中亭台", "仙境中央的亭台楼阁，云雾缭绕", "shrine", [3, 4]),
            landmark("墨色瀑布", "如同水墨画般的银白瀑布", "water", [5, 2]),
        ],
        "resources": [
            resource("画仙遗物", "画仙留下的笔砚", "cache", [2, 5], "item_painting_brush"),
        ]
    },
    "tianji_pavilion": {
        "landmarks": [
            landmark("天机阁", "隐藏在山崖上的古阁", "ruin", [4, 3]),
            landmark("藏书洞", "堆满古籍的隐秘洞窟", "cave", [6, 5]),
        ],
        "resources": [
            resource("古卷", "散落的古籍残页", "cache", [3, 2]),
        ]
    },
    "wanshou_mtn": {
        "landmarks": [
            landmark("兽王洞", "百兽之王的巢穴", "cave", [4, 3]),
            landmark("万兽崖", "可以俯瞰整片山林的崖顶", "notice", [6, 5]),
        ],
        "resources": [
            resource("灵兽果", "灵兽喜爱的奇异果实", "herb", [2, 4]),
        ]
    },
}

# ═══════════════════════════════════════════════════════════════════
# 7. REGION SHOPS (add for new regions that are like towns)
# ═══════════════════════════════════════════════════════════════════
# longmen_inn gets shops since it's an oasis settlement
new_region_shops = {
    "longmen_inn": ["inn", "market"],
}

# ═══════════════════════════════════════════════════════════════════
# 8. REGION MARKET MODIFIERS
# ═══════════════════════════════════════════════════════════════════
new_region_market = {
    "desert_road": {"label": "古道市集", "buy_factor": 1.20, "sell_factor": 0.80},
    "longmen_inn": {"label": "龙门黑市", "buy_factor": 1.10, "sell_factor": 0.85},
    "mojiao_branch": {"label": "魔教配给", "buy_factor": 0.80, "sell_factor": 1.30},
    "mojiao_base": {"label": "魔教内库", "buy_factor": 0.75, "sell_factor": 1.40},
}

# ═══════════════════════════════════════════════════════════════════
# NOW APPLY ALL CHANGES
# ═══════════════════════════════════════════════════════════════════

# 1. Append new regions
for r in new_regions:
    if r["id"] not in existing_region_ids:
        regions.append(r)
        print(f"  + region: {r['id']} ({r['name']})")
    else:
        print(f"  SKIP region {r['id']} (exists)")
save_json("regions.json", regions)

# 2. Append new items
new_all_items = items[:]
for item in new_items + new_equipment:
    if item["id"] not in existing_item_ids:
        new_all_items.append(item)
        print(f"  + item: {item['id']} ({item['name']})")
    else:
        print(f"  SKIP item {item['id']} (exists)")
save_json("items.json", new_all_items)

# 3. Append new NPCs
new_all_npcs_list = npcs[:]
for npc in all_new_npcs:
    npc_id = npc.get("id")
    if npc_id not in existing_npc_ids:
        new_all_npcs_list.append(npc)
        print(f"  + npc: id={npc.get('id')} {npc.get('name')} ({npc.get('npc_type')})")
    else:
        print(f"  SKIP npc id={npc_id} (exists)")
save_json("npcs.json", new_all_npcs_list)

# 4. Append new quests
existing_quest_ids = {q["id"] for q in quests}
new_all_quests = quests[:]
for q in new_quests:
    if q["id"] not in existing_quest_ids:
        new_all_quests.append(q)
        print(f"  + quest: {q['id']} ({q['title']})")
    else:
        print(f"  SKIP quest {q['id']} (exists)")
save_json("quests.json", new_all_quests)

# 5. Append region connections
# For new region entries
for region_id, conns in new_connections.items():
    if region_id not in region_connections:
        region_connections[region_id] = []
    existing_targets = {c["target"] for c in region_connections[region_id]}
    for conn in conns:
        if conn["target"] not in existing_targets:
            region_connections[region_id].append(conn)
            existing_targets.add(conn["target"])

# Add reverse connections to existing regions
for region_id, conns in reverse_connections.items():
    if region_id not in region_connections:
        region_connections[region_id] = []
    existing_targets = {c["target"] for c in region_connections[region_id]}
    for conn in conns:
        if conn["target"] not in existing_targets:
            region_connections[region_id].append(conn)
            existing_targets.add(conn["target"])

print(f"  updated region_connections.json with {sum(len(v) for v in new_connections.values())} new connections")
save_json("region_connections.json", region_connections)

# 6. Append region points
for region_id, points in new_region_points.items():
    if region_id not in region_points:
        region_points[region_id] = {"landmarks": [], "resources": []}
    entry = region_points[region_id]
    for point_type in ("landmarks", "resources"):
        for pt in points.get(point_type, []):
            existing_labels = {p.get("label") for p in entry.get(point_type, [])}
            if pt["label"] not in existing_labels:
                entry.setdefault(point_type, []).append(pt)

print(f"  updated region_points.json with new entries")
save_json("region_points.json", region_points)

# 7. Update region shops
for region_id, shops in new_region_shops.items():
    if region_id not in region_shops:
        region_shops[region_id] = shops
        print(f"  + shops for {region_id}: {shops}")
save_json("region_shops.json", region_shops)

# 8. Update region market
for region_id, market in new_region_market.items():
    if region_id not in region_market:
        region_market[region_id] = market
        print(f"  + market for {region_id}")
save_json("region_market_modifiers.json", region_market)

print("\n✅ All data files generated successfully!")
print(f"\nSummary:")
print(f"  Regions: {len(regions)} (was {len(existing_region_ids)}, +{len(new_regions)})")
print(f"  Items: {len(new_all_items)} (was {len(items)}, +{len(new_items) + len(new_equipment)})")
print(f"  NPCs: {len(new_all_npcs_list)} (was {len(npcs)}, +{len(all_new_npcs)})")
print(f"  Quests: {len(new_all_quests)} (was {len(quests)}, +{len(new_quests)})")
