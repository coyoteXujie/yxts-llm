#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版游戏世界 v3.1 - 完整层级架构
5大城 → 16镇 → 45野外 → 7门派 = 73区域

层级关系: 城市数量 << 小镇数量 < 野外数量
每个城市辐射3-4个卫星镇,每个镇连接2-3个野外
门派散布于野外深处
"""

import random, math
from typing import List, Dict, Optional, Tuple
from .world import (
    GameWorld, MAP_W, MAP_H, TS, WALKABLE,
    T_GRASS, T_STONE_ROAD, T_GATE, T_WATER, T_BRIDGE,
    zone_col_to_x, zone_row_to_y,
    ZONE_NAMES, FACTION_NAMES, ALL_SKILLS, FACTION_SKILLS, PERFORMS, NPC_DIALOGUES
)
from .enhanced_map_generator import get_enhanced_map_generator
from .entities import Player, NPC, Map, Position, Skill, NpcType, Faction, Item, ItemType


# ==================== 区域清单 ====================
CITY_IDS = ["luoyang", "changan", "linan", "jiangling", "chengdu"]

TOWN_IDS = [
    # 洛阳4镇
    "qinghe", "gongyi", "yanshi", "mengjin",
    # 长安4镇
    "fengxiang", "xianyang", "weinan", "lintong",
    # 临安3镇
    "yuhang", "jiaxing", "shaoxing",
    # 成都3镇
    "shuangliu", "xindu", "wenjiang",
    # 江陵2镇
    "yiling", "dangyang",
]

WILD_IDS = [
    # 洛阳周边9野
    "beiling_mtn", "songshan_peak", "luoshui_river", "huanghe_valley",
    "taihang_range", "yanshi_plain", "mengjin_ford", "yiluo_valley", "zhongtiao_mtn",
    # 长安周边9野
    "qinling_deep", "zhongnan_mtn", "zhongyuan_for", "weihe_river",
    "longxi_desert", "huashan_cliff", "tongguan_pass", "lintong_bath", "xianyang_mound",
    # 临安周边9野
    "jiangnan_marsh", "wuyi_for", "dongting_lake", "qiantang_tide",
    "tianmu_mtn", "taihu_lake", "huangshan_peak", "shaoxing_water", "jiaxing_canal",
    # 成都周边9野
    "shudao_mtn", "bashu_bamboo", "emei_sacred", "qingcheng_mtn",
    "dujiang_weir", "minjiang_river", "xindu_field", "wenjiang_garden", "western_plateau",
    # 江陵周边9野
    "funiu_mtn", "wudang_peak", "shennongjia", "three_gorges",
    "yiling_gap", "dangyang_plain", "yunmeng_marsh", "hanjiang_river", "daba_mtn",
]

SECT_IDS = ["bagua_sect", "flower_sect", "honglian_sect", "naja_sect",
            "taiji_sect", "xueshan_sect", "xiaoyao_sect"]

ALL_ZONE_IDS = CITY_IDS + TOWN_IDS + WILD_IDS + SECT_IDS

# 区域中文名和描述
ZONE_META = {
    # === 5城 ===
    "luoyang": ("洛阳城", 50, 50, "大唐东都，九朝古都，石板路纵横，商铺云集。"),
    "changan": ("长安城", 50, 50, "大唐西京，皇城巍峨，万国来朝。丝绸之路的东方起点。"),
    "linan": ("临安城", 45, 45, "江南都城，烟雨楼台，西湖歌舞。水巷交错，桥连万家。"),
    "jiangling": ("江陵城", 40, 40, "荆楚重镇，扼守长江。自古兵家必争之地，城墙高筑。"),
    "chengdu": ("成都城", 45, 45, "蜀地天府，锦官城外。都江堰畔，物产丰饶。"),

    # === 16镇 ===
    "qinghe": ("清河镇", "洛阳北郊门户，通向北岭群山的古栈道起点。"),
    "gongyi": ("巩义镇", "洛阳东郊，洛水之畔的瓷器名镇。"),
    "yanshi": ("偃师镇", "洛阳东南，通往中原的古道驿站。"),
    "mengjin": ("孟津镇", "洛阳西北，黄河渡口重镇。"),
    "fengxiang": ("凤翔镇", "长安南郊，有凤来仪，通往巴蜀的要道。"),
    "xianyang": ("咸阳镇", "长安西郊，大秦旧都遗址。"),
    "weinan": ("渭南镇", "长安东郊，渭水之阳。"),
    "lintong": ("临潼镇", "长安东北，骊山脚下温泉水暖。"),
    "yuhang": ("余杭镇", "临安北郊，大运河畔稻花香。"),
    "jiaxing": ("嘉兴镇", "临安东郊，南湖之滨烟雨楼台。"),
    "shaoxing": ("绍兴镇", "临安东南，鉴湖水乡乌篷船。"),
    "shuangliu": ("双流镇", "成都西郊，二江汇流通往蜀道。"),
    "xindu": ("新都镇", "成都北郊，千年古刹桂湖香。"),
    "wenjiang": ("温江镇", "成都西郊，花团锦簇锦绣地。"),
    "yiling": ("夷陵镇", "江陵西郊，三峡门户江水湍急。"),
    "dangyang": ("当阳镇", "江陵北郊，长坂雄风犹在。"),

    # === 45野 ===
    "beiling_mtn": ("北岭群山", "洛阳以北，群山连绵古栈道。", "mountain"),
    "songshan_peak": ("嵩山峰顶", "中岳嵩山，少林钟声。", "mountain"),
    "luoshui_river": ("洛水河畔", "洛水悠悠，杨柳依依。", "river"),
    "huanghe_valley": ("黄河古道", "黄河之水天上来，苍茫辽阔。", "river"),
    "taihang_range": ("太行山脉", "纵贯南北，太行八陉。", "mountain"),
    "yanshi_plain": ("偃师原野", "一望无际的中原平原。", "forest"),
    "mengjin_ford": ("孟津渡口", "黄河古渡，舟楫往来。", "river"),
    "yiluo_valley": ("伊洛河谷", "伊洛二水交汇之地。", "river"),
    "zhongtiao_mtn": ("中条山脉", "晋南屏障，峰峦叠嶂。", "mountain"),

    "qinling_deep": ("秦岭深处", "巍巍秦岭，分界南北。", "mountain"),
    "zhongnan_mtn": ("终南山", "天下第一福地，隐士之乡。", "mountain"),
    "zhongyuan_for": ("中原密林", "中原腹地，古木参天。", "forest"),
    "weihe_river": ("渭河平原", "八百里秦川，沃野千里。", "river"),
    "longxi_desert": ("陇西荒漠", "大漠孤烟直，长河落日圆。", "river"),
    "huashan_cliff": ("华山险峰", "奇险天下第一山。", "mountain"),
    "tongguan_pass": ("潼关古道", "一夫当关万夫莫开。", "mountain"),
    "lintong_bath": ("临潼温泉", "骊山晚照，温泉水滑。", "forest"),
    "xianyang_mound": ("秦陵原", "秦皇陵寝，兵马俑阵。", "forest"),

    "jiangnan_marsh": ("江南水泽", "河网密布，芦苇荡中扁舟一叶。", "river"),
    "wuyi_for": ("武夷山林", "丹霞碧水，九曲溪畔茶香。", "bamboo"),
    "dongting_lake": ("洞庭湖畔", "八百里洞庭，烟波浩渺。", "river"),
    "qiantang_tide": ("钱塘江潮", "八月十八潮，壮观天下无。", "river"),
    "tianmu_mtn": ("天目山", "大树华盖闻九州。", "mountain"),
    "taihu_lake": ("太湖烟波", "三万六千顷，烟波浩渺。", "river"),
    "huangshan_peak": ("黄山云海", "五岳归来不看山。", "mountain"),
    "shaoxing_water": ("绍兴水乡", "乌篷船上，社戏声中。", "river"),
    "jiaxing_canal": ("嘉兴运河", "京杭大运河，千帆过尽。", "river"),

    "shudao_mtn": ("蜀道群山", "蜀道之难，难于上青天。", "mountain"),
    "bashu_bamboo": ("巴蜀竹海", "蜀南竹海，翠浪连天。", "bamboo"),
    "emei_sacred": ("峨眉圣山", "峨眉天下秀，金顶佛光。", "mountain"),
    "qingcheng_mtn": ("青城山", "青城天下幽，道教圣地。", "mountain"),
    "dujiang_weir": ("都江古堰", "千年水利，天府之源。", "river"),
    "minjiang_river": ("岷江河谷", "岷江滔滔，沃野千里。", "river"),
    "xindu_field": ("新都平原", "桂湖飘香，天府粮仓。", "forest"),
    "wenjiang_garden": ("温江花田", "花团锦簇，锦绣之地。", "forest"),
    "western_plateau": ("西岭高原", "窗含西岭千秋雪。", "mountain"),

    "funiu_mtn": ("伏牛山", "云雾缭绕，古寺钟声。", "mountain"),
    "wudang_peak": ("武当山", "亘古无双胜境。", "mountain"),
    "shennongjia": ("神农架", "原始森林，野人传说。", "forest"),
    "three_gorges": ("三峡险滩", "两岸猿声啼不住。", "river"),
    "yiling_gap": ("夷陵峡谷", "峡谷幽深，江水湍急。", "mountain"),
    "dangyang_plain": ("当阳平原", "长坂坡前，古战场。", "forest"),
    "yunmeng_marsh": ("云梦泽", "古云梦大泽，水草丰茂。", "river"),
    "hanjiang_river": ("汉江", "汉水悠悠，鱼米之乡。", "river"),
    "daba_mtn": ("大巴山", "巴山夜雨涨秋池。", "mountain"),

    # === 7派 ===
    "bagua_sect": ("八卦门", "BAGUA", "混元一气，立于北岭群山中。"),
    "flower_sect": ("百花谷", "FLOWER", "花间派驻地，百花缭乱，藏于武夷山中。"),
    "honglian_sect": ("红莲教", "HONGLIAN", "红莲教总坛，义字当先。居于中原密林。"),
    "naja_sect": ("那迦派", "NAJA", "那迦派驻地，隐忍如影。伏牛山深处。"),
    "taiji_sect": ("太极门", "TAIJI", "太极门道场，阴阳调和。武当山上松涛阵阵。"),
    "xueshan_sect": ("雪山派", "XUESHAN", "雪山派立于秦岭之巅，冰封万里。"),
    "xiaoyao_sect": ("逍遥宫", "XIAOYAO", "逍遥派驻于洞庭湖畔，飘渺无踪。"),
}


class EnhancedGameWorld(GameWorld):

    def __init__(self):
        self.enhanced_generator = get_enhanced_map_generator()
        super().__init__()

    def _init_all_zones(self):
        self.zones = {}

        for zid in CITY_IDS:
            name, w, h, desc = ZONE_META[zid]
            self.zones[zid] = self.enhanced_generator.generate_city(zid, name, w, h, desc)

        for zid in TOWN_IDS:
            name, desc = ZONE_META[zid]
            self.zones[zid] = self.enhanced_generator.generate_town(zid, name, 25, 25, desc)

        for zid in WILD_IDS:
            name, desc, terrain = ZONE_META[zid]
            self.zones[zid] = self.enhanced_generator.generate_wilderness(
                zid, name, 55, 55, terrain, desc
            )

        for zid in SECT_IDS:
            name, faction, desc = ZONE_META[zid]
            self.zones[zid] = self.enhanced_generator.generate_sect(
                zid, name, faction, 30, 30, desc
            )

        self._setup_zone_connections()

    def _setup_zone_connections(self):
        def pos_leave(w, h):
            return Position(zone_col_to_x(w // 2), zone_row_to_y(2, h))

        def connect(c, zid, **directions):
            c.setdefault(zid, {})
            for direction, target_id in directions.items():
                target = self.zones.get(target_id)
                if target:
                    c[zid][direction] = (target_id, pos_leave(target.width, target.height))

        c = {}

        # ===== 洛阳体系 (4镇 → 9野 → 八卦门) =====
        connect(c, "luoyang", north="qinghe", east="gongyi", south="yanshi", west="mengjin")
        connect(c, "qinghe", south="luoyang", north="beiling_mtn", east="songshan_peak")
        connect(c, "gongyi", west="luoyang", east="luoshui_river", north="songshan_peak")
        connect(c, "yanshi", north="luoyang", south="yanshi_plain", east="yiluo_valley")
        connect(c, "mengjin", east="luoyang", north="mengjin_ford", west="huanghe_valley")
        connect(c, "beiling_mtn", south="qinghe", north="bagua_sect", east="songshan_peak")
        connect(c, "songshan_peak", west="beiling_mtn", south="gongyi", east="taihang_range")
        connect(c, "luoshui_river", west="gongyi", south="yiluo_valley", east="yanshi_plain")
        connect(c, "yanshi_plain", north="yanshi", west="luoshui_river", south="zhongyuan_for")
        connect(c, "mengjin_ford", south="mengjin", west="huanghe_valley", east="taihang_range")
        connect(c, "yiluo_valley", west="luoshui_river", north="yanshi", south="zhongtiao_mtn")
        connect(c, "taihang_range", west="mengjin_ford", north="zhongtiao_mtn", east="taiji_sect")
        connect(c, "zhongtiao_mtn", south="yiluo_valley", east="taihang_range", north="huanghe_valley")
        connect(c, "huanghe_valley", east="mengjin_ford", south="zhongtiao_mtn", west="xianyang")
        connect(c, "bagua_sect", south="beiling_mtn")

        # ===== 长安体系 (4镇 → 9野 → 雪山派) =====
        connect(c, "changan", east="luoyang", south="fengxiang", west="xianyang",
                north="lintong", south_east="weinan")
        connect(c, "fengxiang", north="changan", south="zhongnan_mtn")
        connect(c, "xianyang", east="changan", west="tongguan_pass", north="lintong_bath")
        connect(c, "weinan", north_west="changan", south="weihe_river", east="huashan_cliff")
        connect(c, "lintong", south="changan", north="xianyang_mound", east="lintong_bath")
        connect(c, "qinling_deep", east="zhongnan_mtn", south="xueshan_sect", north="longxi_desert")
        connect(c, "zhongnan_mtn", north="fengxiang", west="qinling_deep", east="huashan_cliff")
        connect(c, "zhongyuan_for", north="yanshi_plain", west="weihe_river", east="honglian_sect")
        connect(c, "weihe_river", north="weinan", east="zhongyuan_for", west="huashan_cliff")
        connect(c, "longxi_desert", south="qinling_deep", east="tongguan_pass", north="huanghe_valley")
        connect(c, "huashan_cliff", west="zhongnan_mtn", north="weihe_river", south="tongguan_pass")
        connect(c, "tongguan_pass", east="xianyang", north="longxi_desert", south="huashan_cliff")
        connect(c, "lintong_bath", west="xianyang", south="lintong", east="xianyang_mound")
        connect(c, "xianyang_mound", south="lintong", west="lintong_bath", north="huanghe_valley")
        connect(c, "xueshan_sect", north="qinling_deep")

        # ===== 临安体系 (3镇 → 9野 → 百花谷+逍遥宫) =====
        connect(c, "linan", north="yuhang", east="jiaxing", south="shaoxing")
        connect(c, "yuhang", south="linan", north="jiaxing_canal", west="tianmu_mtn")
        connect(c, "jiaxing", west="linan", south="jiaxing_canal", east="taihu_lake")
        connect(c, "shaoxing", north="linan", south="shaoxing_water", east="jiangnan_marsh")
        connect(c, "jiangnan_marsh", west="shaoxing", south="qiantang_tide", north="taihu_lake")
        connect(c, "tianmu_mtn", east="yuhang", south="huangshan_peak", west="dongting_lake")
        connect(c, "taihu_lake", west="jiaxing", south="jiangnan_marsh", north="jiaxing_canal")
        connect(c, "huangshan_peak", north="tianmu_mtn", south="wuyi_for", east="qiantang_tide")
        connect(c, "shaoxing_water", north="shaoxing", west="qiantang_tide", east="jiangnan_marsh")
        connect(c, "jiaxing_canal", south="yuhang", east="taihu_lake", west="tianmu_mtn")
        connect(c, "dongting_lake", east="tianmu_mtn", south="xiaoyao_sect", west="three_gorges")
        connect(c, "qiantang_tide", north="jiangnan_marsh", east="shaoxing_water", south="wuyi_for")
        connect(c, "wuyi_for", north="huangshan_peak", south="flower_sect", east="qiantang_tide")
        connect(c, "flower_sect", north="wuyi_for")
        connect(c, "xiaoyao_sect", north="dongting_lake")

        # ===== 成都体系 (3镇 → 9野 → 无派) =====
        connect(c, "chengdu", west="shuangliu", north="xindu", south="wenjiang")
        connect(c, "shuangliu", east="chengdu", west="shudao_mtn", south="minjiang_river")
        connect(c, "xindu", south="chengdu", north="xindu_field", west="qingcheng_mtn")
        connect(c, "wenjiang", north="chengdu", south="wenjiang_garden", west="bashu_bamboo")
        connect(c, "shudao_mtn", east="shuangliu", north="qingcheng_mtn", west="western_plateau")
        connect(c, "qingcheng_mtn", south="shudao_mtn", east="xindu", north="dujiang_weir")
        connect(c, "dujiang_weir", south="qingcheng_mtn", north="minjiang_river", east="xindu_field")
        connect(c, "minjiang_river", east="bashu_bamboo", north="shuangliu", south="dujiang_weir")
        connect(c, "emei_sacred", north="bashu_bamboo", east="western_plateau", south="wenjiang_garden")
        connect(c, "bashu_bamboo", west="minjiang_river", north="wenjiang", south="emei_sacred")
        connect(c, "western_plateau", east="shudao_mtn", west="emei_sacred", north="qinling_deep")
        connect(c, "xindu_field", south="xindu", west="dujiang_weir", north="zhongnan_mtn")
        connect(c, "wenjiang_garden", north="wenjiang", west="emei_sacred", south="yiling_gap")

        # ===== 江陵体系 (2镇 → 9野 → 那迦派+太极门) =====
        connect(c, "jiangling", east="luoyang", west="yiling", north="dangyang")
        connect(c, "yiling", east="jiangling", west="yiling_gap", south="three_gorges")
        connect(c, "dangyang", south="jiangling", north="dangyang_plain", west="funiu_mtn")
        connect(c, "funiu_mtn", east="dangyang", south="naja_sect", west="shennongjia")
        connect(c, "wudang_peak", north="dangyang_plain", west="taiji_sect", east="hanjiang_river")
        connect(c, "shennongjia", east="funiu_mtn", south="daba_mtn", west="yiling_gap")
        connect(c, "three_gorges", north="yiling", south="yunmeng_marsh", west="daba_mtn")
        connect(c, "yiling_gap", east="yiling", south="daba_mtn", west="shennongjia")
        connect(c, "dangyang_plain", south="dangyang", west="wudang_peak", north="yanshi_plain")
        connect(c, "yunmeng_marsh", north="three_gorges", east="dongting_lake", south="hanjiang_river")
        connect(c, "hanjiang_river", west="wudang_peak", north="yunmeng_marsh", east="dongting_lake")
        connect(c, "daba_mtn", north="shennongjia", west="three_gorges", south="yunmeng_marsh")
        connect(c, "naja_sect", north="funiu_mtn")
        connect(c, "taiji_sect", east="wudang_peak")

        # 长安 → 洛阳 之间
        connect(c, "honglian_sect", west="zhongyuan_for")

        # 应用所有连接
        for zone_id, exits in c.items():
            if zone_id in self.zones:
                zone = self.zones[zone_id]
                zone.exits = {}
                zone.transitions = {}
                for direction, (target_id, entry_pos) in exits.items():
                    if target_id in self.zones:
                        zone.exits[direction] = entry_pos
                        zone.transitions[direction] = (target_id, entry_pos)

    def can_walk(self, x, y):
        cmap = self.current_map
        if not cmap:
            return False
        col = int(x // TS)
        row = cmap.height - 1 - int(y // TS)
        if row < 0 or row >= cmap.height or col < 0 or col >= cmap.width:
            return False
        return cmap.tiles[row][col] in WALKABLE

    def get_zone_hierarchy(self, zone_id):
        if zone_id in CITY_IDS: return "city"
        if zone_id in TOWN_IDS: return "town"
        if zone_id in WILD_IDS: return "wilderness"
        if zone_id in SECT_IDS: return "sect"
        return "unknown"

    def get_parent_city(self, zone_id):
        m = {
            "luoyang": "luoyang", "qinghe": "luoyang", "gongyi": "luoyang",
            "yanshi": "luoyang", "mengjin": "luoyang",
            "beiling_mtn": "luoyang", "songshan_peak": "luoyang", "luoshui_river": "luoyang",
            "yanshi_plain": "luoyang", "mengjin_ford": "luoyang", "yiluo_valley": "luoyang",
            "huanghe_valley": "luoyang", "taihang_range": "luoyang", "zhongtiao_mtn": "luoyang",
            "bagua_sect": "luoyang",
            "changan": "changan", "fengxiang": "changan", "xianyang": "changan",
            "weinan": "changan", "lintong": "changan",
            "qinling_deep": "changan", "zhongnan_mtn": "changan", "weihe_river": "changan",
            "longxi_desert": "changan", "huashan_cliff": "changan", "tongguan_pass": "changan",
            "lintong_bath": "changan", "xianyang_mound": "changan",
            "zhongyuan_for": "changan", "honglian_sect": "changan", "xueshan_sect": "changan",
            "linan": "linan", "yuhang": "linan", "jiaxing": "linan", "shaoxing": "linan",
            "jiangnan_marsh": "linan", "wuyi_for": "linan", "dongting_lake": "linan",
            "qiantang_tide": "linan", "tianmu_mtn": "linan", "taihu_lake": "linan",
            "huangshan_peak": "linan", "shaoxing_water": "linan", "jiaxing_canal": "linan",
            "flower_sect": "linan", "xiaoyao_sect": "linan",
            "chengdu": "chengdu", "shuangliu": "chengdu", "xindu": "chengdu", "wenjiang": "chengdu",
            "shudao_mtn": "chengdu", "bashu_bamboo": "chengdu", "emei_sacred": "chengdu",
            "qingcheng_mtn": "chengdu", "dujiang_weir": "chengdu", "minjiang_river": "chengdu",
            "xindu_field": "chengdu", "wenjiang_garden": "chengdu", "western_plateau": "chengdu",
            "jiangling": "jiangling", "yiling": "jiangling", "dangyang": "jiangling",
            "funiu_mtn": "jiangling", "wudang_peak": "jiangling", "shennongjia": "jiangling",
            "three_gorges": "jiangling", "yiling_gap": "jiangling", "dangyang_plain": "jiangling",
            "yunmeng_marsh": "jiangling", "hanjiang_river": "jiangling", "daba_mtn": "jiangling",
            "naja_sect": "jiangling", "taiji_sect": "jiangling",
        }
        return m.get(zone_id)


_enhanced_world = None

def get_enhanced_world() -> EnhancedGameWorld:
    global _enhanced_world
    if _enhanced_world is None:
        _enhanced_world = EnhancedGameWorld()
    return _enhanced_world
