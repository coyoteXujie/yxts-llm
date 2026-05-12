from typing import Dict, List, Optional
from dataclasses import dataclass, field
from enum import Enum
from .entities import Player, Faction, FACTION_NAMES, NpcType


class FactionRank(Enum):
    OUTSIDER = "outsider"
    DISCIPLE = "disciple"
    CORE_DISCIPLE = "core_disciple"
    ELDER = "elder"
    MASTER = "master"


RANK_NAMES = {
    FactionRank.OUTSIDER: "外人",
    FactionRank.DISCIPLE: "弟子",
    FactionRank.CORE_DISCIPLE: "核心弟子",
    FactionRank.ELDER: "长老",
    FactionRank.MASTER: "掌门",
}

FACTION_RANK_TITLES = {
    Faction.BAGUA: {FactionRank.DISCIPLE: "八卦弟子", FactionRank.CORE_DISCIPLE: "八卦护法", FactionRank.ELDER: "八卦长老"},
    Faction.FLOWER: {FactionRank.DISCIPLE: "花间侍女", FactionRank.CORE_DISCIPLE: "花间仙子", FactionRank.ELDER: "花间长老"},
    Faction.HONGLIAN: {FactionRank.DISCIPLE: "红莲教众", FactionRank.CORE_DISCIPLE: "红莲护法", FactionRank.ELDER: "红莲长老"},
    Faction.NAJA: {FactionRank.DISCIPLE: "那迦忍众", FactionRank.CORE_DISCIPLE: "那迦上忍", FactionRank.ELDER: "那迦长老"},
    Faction.TAIJI: {FactionRank.DISCIPLE: "太极道童", FactionRank.CORE_DISCIPLE: "太极真人", FactionRank.ELDER: "太极长老"},
    Faction.XUESHAN: {FactionRank.DISCIPLE: "雪山弟子", FactionRank.CORE_DISCIPLE: "雪山剑客", FactionRank.ELDER: "雪山长老"},
    Faction.XIAOYAO: {FactionRank.DISCIPLE: "逍遥弟子", FactionRank.CORE_DISCIPLE: "逍遥散人", FactionRank.ELDER: "逍遥长老"},
}


@dataclass
class FactionTrial:
    id: str
    faction: Faction
    rank: FactionRank
    title: str
    description: str
    trial_type: str
    requirements: Dict = field(default_factory=dict)
    objectives: List[Dict] = field(default_factory=list)
    rewards: Dict = field(default_factory=dict)
    dialogue_before: str = ""
    dialogue_success: str = ""
    dialogue_failure: str = ""


FACTION_TRIALS = {
    Faction.BAGUA: [
        FactionTrial(
            id="bagua_trial_1", faction=Faction.BAGUA, rank=FactionRank.DISCIPLE,
            title="八卦入门·混元一气",
            description="修炼混元一气至10级，领悟八卦门基础内功",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_hunyuan": 10}},
            objectives=[{"desc": "将混元一气修炼至10级", "skill_id": "kf_hunyuan", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="八卦门讲究以柔克刚、以静制动。你若想入门，先修炼混元一气至10级，证明你有习武的根基。",
            dialogue_success="不错，你的内功根基已经打好了。从今日起，你就是八卦门的弟子！",
            dialogue_failure="你的内功还不够纯熟，继续修炼吧。",
        ),
        FactionTrial(
            id="bagua_trial_2", faction=Faction.BAGUA, rank=FactionRank.CORE_DISCIPLE,
            title="八卦升阶·八阵图",
            description="修炼八阵图至30级，击败八卦门大师兄",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_bazhen": 30}},
            objectives=[
                {"desc": "将八阵图修炼至30级", "skill_id": "kf_bazhen", "target_level": 30},
                {"desc": "击败大师兄简明", "npc_name": "简明", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "八卦护法"},
            dialogue_before="要成为核心弟子，你必须证明自己的实力。将八阵图修炼至30级，然后击败大师兄简明！",
            dialogue_success="你竟然击败了简明...好！从今日起，你就是八卦门护法！",
            dialogue_failure="你还不是简明的对手，继续修炼吧。",
        ),
        FactionTrial(
            id="bagua_trial_3", faction=Faction.BAGUA, rank=FactionRank.ELDER,
            title="八卦出师·掌门之战",
            description="修炼全部门派技能至50级，挑战掌门韦扬",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门韦扬", "npc_name": "韦扬", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "八卦长老"},
            dialogue_before="你已学有所成，但能否出师，要看你能否接下我三招！来吧！",
            dialogue_success="好！你已尽得八卦门真传，从今日起，你就是八卦门长老！",
            dialogue_failure="你还差得远呢，回去继续修炼吧。",
        ),
    ],
    Faction.FLOWER: [
        FactionTrial(
            id="flower_trial_1", faction=Faction.FLOWER, rank=FactionRank.DISCIPLE,
            title="花间入门·梅花三弄",
            description="修炼梅花三弄至10级，领悟花间派基础心法",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_meihua": 10}},
            objectives=[{"desc": "将梅花三弄修炼至10级", "skill_id": "kf_meihua", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="花间派讲究以花入道、以美养心。你若想入门，先修炼梅花三弄至10级。",
            dialogue_success="你的心法已有小成，从今日起，你就是花间派的侍女！",
            dialogue_failure="你的花间心法还不够纯熟，继续修炼吧。",
        ),
        FactionTrial(
            id="flower_trial_2", faction=Faction.FLOWER, rank=FactionRank.CORE_DISCIPLE,
            title="花间升阶·花团锦簇",
            description="修炼花团锦簇至30级，击败花间派大弟子",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_huatuan": 30}},
            objectives=[
                {"desc": "将花团锦簇修炼至30级", "skill_id": "kf_huatuan", "target_level": 30},
                {"desc": "击败大弟子青红", "npc_name": "青红", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "花间仙子"},
            dialogue_before="要成为核心弟子，你必须将花团锦簇修炼至30级，然后击败大弟子青红！",
            dialogue_success="好一朵出水的芙蓉！从今日起，你就是花间派仙子！",
            dialogue_failure="你的花间武学还不够精妙，继续修炼吧。",
        ),
        FactionTrial(
            id="flower_trial_3", faction=Faction.FLOWER, rank=FactionRank.ELDER,
            title="花间出师·三花聚顶",
            description="修炼三花聚顶至50级，挑战掌门清照",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门清照", "npc_name": "清照", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "花间长老"},
            dialogue_before="花间派的至高武学，你已窥得门径。但能否出师，要看你能否胜过我！",
            dialogue_success="你已领悟花间真谛，从今日起，你就是花间派长老！",
            dialogue_failure="花间之道，你尚未参透，继续修炼吧。",
        ),
    ],
    Faction.HONGLIAN: [
        FactionTrial(
            id="honglian_trial_1", faction=Faction.HONGLIAN, rank=FactionRank.DISCIPLE,
            title="红莲入门·太祖长拳",
            description="修炼太祖长拳至10级，证明你有加入红莲教的决心",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_taizu": 10}},
            objectives=[{"desc": "将太祖长拳修炼至10级", "skill_id": "kf_taizu", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="红莲教不问出身，只看实力！修炼太祖长拳至10级，证明你的决心！",
            dialogue_success="好！你够资格了。从今日起，你就是红莲教教众！",
            dialogue_failure="你的拳法还不够刚猛，继续修炼吧。",
        ),
        FactionTrial(
            id="honglian_trial_2", faction=Faction.HONGLIAN, rank=FactionRank.CORE_DISCIPLE,
            title="红莲升阶·同击术",
            description="修炼同击术至30级，击败方长老",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_tongji": 30}},
            objectives=[
                {"desc": "将同击术修炼至30级", "skill_id": "kf_tongji", "target_level": 30},
                {"desc": "击败方长老", "npc_name": "方长老", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "红莲护法"},
            dialogue_before="要成为核心弟子，将同击术修炼至30级，然后击败方长老！",
            dialogue_success="你的实力已得我认可！从今日起，你就是红莲教护法！",
            dialogue_failure="你还不够强，继续修炼吧。",
        ),
        FactionTrial(
            id="honglian_trial_3", faction=Faction.HONGLIAN, rank=FactionRank.ELDER,
            title="红莲出师·掌门之战",
            description="修炼全部门派技能至50级，挑战掌门于红儒",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门于红儒", "npc_name": "于红儒", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "红莲长老"},
            dialogue_before="你已练就一身红莲武学，但能否出师，要看你能否胜过我！",
            dialogue_success="好！从今日起，你就是红莲教长老！",
            dialogue_failure="你还差得远，继续修炼吧。",
        ),
    ],
    Faction.NAJA: [
        FactionTrial(
            id="naja_trial_1", faction=Faction.NAJA, rank=FactionRank.DISCIPLE,
            title="那迦入门·忍术",
            description="修炼忍术至10级，领悟那迦派基础",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_renshu": 10}},
            objectives=[{"desc": "将忍术修炼至10级", "skill_id": "kf_renshu", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="那迦派讲究隐忍和速度。修炼忍术至10级，证明你有成为忍者的素质。",
            dialogue_success="你已具备忍者的基本素质。从今日起，你就是那迦派忍众！",
            dialogue_failure="你的忍术还不够纯熟，继续修炼吧。",
        ),
        FactionTrial(
            id="naja_trial_2", faction=Faction.NAJA, rank=FactionRank.CORE_DISCIPLE,
            title="那迦升阶·无形剑",
            description="修炼无形剑至30级，击败十三卫",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_wuying": 30}},
            objectives=[
                {"desc": "将无形剑修炼至30级", "skill_id": "kf_wuying", "target_level": 30},
                {"desc": "击败十三卫", "npc_name": "十三卫", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "那迦上忍"},
            dialogue_before="要成为上忍，将无形剑修炼至30级，然后击败十三卫！",
            dialogue_success="你的忍术已臻化境！从今日起，你就是那迦派上忍！",
            dialogue_failure="你的忍术还不够精妙，继续修炼吧。",
        ),
        FactionTrial(
            id="naja_trial_3", faction=Faction.NAJA, rank=FactionRank.ELDER,
            title="那迦出师·掌门之战",
            description="修炼全部门派技能至50级，挑战掌门钟央",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门钟央", "npc_name": "钟央", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "那迦长老"},
            dialogue_before="你已掌握那迦派全部武学，但能否出师，要看你能否胜过我！",
            dialogue_success="你已超越了我！从今日起，你就是那迦派长老！",
            dialogue_failure="你还差得远，继续修炼吧。",
        ),
    ],
    Faction.TAIJI: [
        FactionTrial(
            id="taiji_trial_1", faction=Faction.TAIJI, rank=FactionRank.DISCIPLE,
            title="太极入门·太极功",
            description="修炼太极功至10级，领悟太极门基础心法",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_taiji_force": 10}},
            objectives=[{"desc": "将太极功修炼至10级", "skill_id": "kf_taiji_force", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="太极之道，以静制动。修炼太极功至10级，方可入门。",
            dialogue_success="道心初成。从今日起，你就是太极门道童！",
            dialogue_failure="你的道心还不够坚定，继续修炼吧。",
        ),
        FactionTrial(
            id="taiji_trial_2", faction=Faction.TAIJI, rank=FactionRank.CORE_DISCIPLE,
            title="太极升阶·太极剑法",
            description="修炼太极剑法至30级，击败古松道人",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_taiji_sword": 30}},
            objectives=[
                {"desc": "将太极剑法修炼至30级", "skill_id": "kf_taiji_sword", "target_level": 30},
                {"desc": "击败古松道人", "npc_name": "古松道人", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "太极真人"},
            dialogue_before="要成为真人，将太极剑法修炼至30级，然后击败古松道人！",
            dialogue_success="你的太极之道已入佳境！从今日起，你就是太极门真人！",
            dialogue_failure="你的剑法还不够圆润，继续修炼吧。",
        ),
        FactionTrial(
            id="taiji_trial_3", faction=Faction.TAIJI, rank=FactionRank.ELDER,
            title="太极出师·掌门之战",
            description="修炼全部门派技能至50级，挑战掌门清虚道人",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门清虚道人", "npc_name": "清虚道人", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "太极长老"},
            dialogue_before="你已领悟太极真谛，但能否出师，要看你能否胜过我！",
            dialogue_success="你已得太极真传！从今日起，你就是太极门长老！",
            dialogue_failure="太极之道无穷无尽，你尚未参透，继续修炼吧。",
        ),
    ],
    Faction.XUESHAN: [
        FactionTrial(
            id="xueshan_trial_1", faction=Faction.XUESHAN, rank=FactionRank.DISCIPLE,
            title="雪山入门·雪上霜",
            description="修炼雪上霜至10级，领悟雪山派基础内功",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_xueshang": 10}},
            objectives=[{"desc": "将雪上霜修炼至10级", "skill_id": "kf_xueshang", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="雪山派讲究以寒制敌。修炼雪上霜至10级，方可入门。",
            dialogue_success="你的寒冰之气已有小成。从今日起，你就是雪山派弟子！",
            dialogue_failure="你的寒冰之气还不够纯熟，继续修炼吧。",
        ),
        FactionTrial(
            id="xueshan_trial_2", faction=Faction.XUESHAN, rank=FactionRank.CORE_DISCIPLE,
            title="雪山升阶·雪山剑法",
            description="修炼雪山剑法至30级，击败万剑",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_xueshan_sword": 30}},
            objectives=[
                {"desc": "将雪山剑法修炼至30级", "skill_id": "kf_xueshan_sword", "target_level": 30},
                {"desc": "击败大弟子万剑", "npc_name": "万剑", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "雪山剑客"},
            dialogue_before="要成为核心弟子，将雪山剑法修炼至30级，然后击败大弟子万剑！",
            dialogue_success="你的剑法如雪山之巅的寒风！从今日起，你就是雪山派剑客！",
            dialogue_failure="你的剑法还不够凌厉，继续修炼吧。",
        ),
        FactionTrial(
            id="xueshan_trial_3", faction=Faction.XUESHAN, rank=FactionRank.ELDER,
            title="雪山出师·掌门之战",
            description="修炼全部门派技能至50级，挑战掌门白瑞德",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败掌门白瑞德", "npc_name": "白瑞德", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "雪山长老"},
            dialogue_before="你已练就一身雪山武学，但能否出师，要看你能否胜过我！",
            dialogue_success="你已超越雪山之巅！从今日起，你就是雪山派长老！",
            dialogue_failure="雪山之道，你尚未参透，继续修炼吧。",
        ),
    ],
    Faction.XIAOYAO: [
        FactionTrial(
            id="xiaoyao_trial_1", faction=Faction.XIAOYAO, rank=FactionRank.DISCIPLE,
            title="逍遥入门·北冥神功",
            description="修炼北冥神功至10级，领悟逍遥派基础",
            trial_type="skill_level",
            requirements={"level": 5, "skill_level": {"kf_beiming": 10}},
            objectives=[{"desc": "将北冥神功修炼至10级", "skill_id": "kf_beiming", "target_level": 10}],
            rewards={"exp": 200, "pot": 20, "faction_rep": 10},
            dialogue_before="逍遥派讲究无拘无束、博采众长。修炼北冥神功至10级，方可入门。",
            dialogue_success="你已初窥逍遥之道。从今日起，你就是逍遥派弟子！",
            dialogue_failure="你的逍遥之心还不够自在，继续修炼吧。",
        ),
        FactionTrial(
            id="xiaoyao_trial_2", faction=Faction.XIAOYAO, rank=FactionRank.CORE_DISCIPLE,
            title="逍遥升阶·凌波微步",
            description="修炼凌波微步至30级，击败门派高手",
            trial_type="skill_and_combat",
            requirements={"level": 15, "skill_level": {"kf_lingbo": 30}},
            objectives=[
                {"desc": "将凌波微步修炼至30级", "skill_id": "kf_lingbo", "target_level": 30},
                {"desc": "击败门派高手", "npc_name": "大侠", "type": "combat"},
            ],
            rewards={"exp": 800, "pot": 50, "faction_rep": 30, "title": "逍遥散人"},
            dialogue_before="要成为散人，将凌波微步修炼至30级，然后击败门派高手！",
            dialogue_success="你的逍遥之道已入佳境！从今日起，你就是逍遥派散人！",
            dialogue_failure="你的逍遥之道还不够自在，继续修炼吧。",
        ),
        FactionTrial(
            id="xiaoyao_trial_3", faction=Faction.XIAOYAO, rank=FactionRank.ELDER,
            title="逍遥出师·逍遥游",
            description="修炼全部门派技能至50级，挑战大侠",
            trial_type="boss_combat",
            requirements={"level": 30, "all_faction_skills": 50},
            objectives=[
                {"desc": "将所有门派技能修炼至50级", "type": "all_skills_50"},
                {"desc": "击败大侠", "npc_name": "大侠", "type": "boss_combat"},
            ],
            rewards={"exp": 3000, "pot": 200, "faction_rep": 100, "title": "逍遥长老"},
            dialogue_before="你已领悟逍遥真谛，但能否出师，要看你能否胜过这位大侠！",
            dialogue_success="你已得逍遥真传！从今日起，你就是逍遥派长老！",
            dialogue_failure="逍遥之道无穷无尽，你尚未参透，继续修炼吧。",
        ),
    ],
}


class FactionProgression:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._player_ranks: Dict[str, FactionRank] = {}
            cls._instance._completed_trials: Dict[str, List[str]] = {}
            cls._instance._active_trial: Dict[str, Optional[str]] = {}
        return cls._instance

    def get_rank(self, player_name: str) -> FactionRank:
        return self._player_ranks.get(player_name, FactionRank.OUTSIDER)

    def get_rank_title(self, player_name: str, faction: Faction) -> str:
        rank = self.get_rank(player_name)
        titles = FACTION_RANK_TITLES.get(faction, {})
        return titles.get(rank, RANK_NAMES.get(rank, "外人"))

    def get_current_trial(self, player: Player) -> Optional[FactionTrial]:
        if player.faction == Faction.NONE:
            return None
        player_key = player.name
        active_id = self._active_trial.get(player_key)
        if active_id:
            trials = FACTION_TRIALS.get(player.faction, [])
            for t in trials:
                if t.id == active_id:
                    return t
        rank = self.get_rank(player_key)
        trials = FACTION_TRIALS.get(player.faction, [])
        for t in trials:
            if t.rank == rank and t.id not in self._completed_trials.get(player_key, []):
                self._active_trial[player_key] = t.id
                return t
        return None

    def get_next_trial(self, player: Player) -> Optional[FactionTrial]:
        if player.faction == Faction.NONE:
            return None
        player_key = player.name
        rank = self.get_rank(player_key)
        trials = FACTION_TRIALS.get(player.faction, [])
        rank_order = [FactionRank.OUTSIDER, FactionRank.DISCIPLE, FactionRank.CORE_DISCIPLE, FactionRank.ELDER]
        current_idx = rank_order.index(rank) if rank in rank_order else 0
        next_idx = current_idx + 1
        if next_idx >= len(rank_order):
            return None
        next_rank = rank_order[next_idx]
        for t in trials:
            if t.rank == next_rank:
                return t
        return None

    def check_trial_progress(self, player: Player) -> Dict:
        trial = self.get_current_trial(player)
        if not trial:
            return {"has_trial": False}

        progress = []
        all_complete = True
        for obj in trial.objectives:
            if obj.get("type") == "all_skills_50":
                from .world import FACTION_SKILLS
                skill_ids = FACTION_SKILLS.get(player.faction, [])
                min_level = 999
                for sid in skill_ids:
                    skill = next((s for s in player.skills if s.id == sid), None)
                    if skill:
                        min_level = min(min_level, skill.level)
                    else:
                        min_level = 0
                done = min_level >= 50
                progress.append({"desc": obj["desc"], "current": min_level, "target": 50, "done": done})
                if not done:
                    all_complete = False
            elif "skill_id" in obj:
                skill = next((s for s in player.skills if s.id == obj["skill_id"]), None)
                current = skill.level if skill else 0
                done = current >= obj["target_level"]
                progress.append({"desc": obj["desc"], "current": current, "target": obj["target_level"], "done": done})
                if not done:
                    all_complete = False
            elif obj.get("type") in ("combat", "boss_combat"):
                progress.append({"desc": obj["desc"], "current": 0, "target": 1, "done": False, "requires_combat": True})
                all_complete = False

        return {
            "has_trial": True,
            "trial": trial,
            "progress": progress,
            "all_complete": all_complete,
        }

    def complete_trial(self, player: Player) -> Dict:
        trial = self.get_current_trial(player)
        if not trial:
            return {"success": False, "message": "没有进行中的门派试炼"}

        progress = self.check_trial_progress(player)
        if not progress.get("all_complete"):
            return {"success": False, "message": "试炼条件尚未满足"}

        player_key = player.name
        if player_key not in self._completed_trials:
            self._completed_trials[player_key] = []
        self._completed_trials[player_key].append(trial.id)

        rank_order = [FactionRank.OUTSIDER, FactionRank.DISCIPLE, FactionRank.CORE_DISCIPLE, FactionRank.ELDER]
        current_idx = rank_order.index(trial.rank) if trial.rank in rank_order else 0
        next_rank = rank_order[min(current_idx + 1, len(rank_order) - 1)]
        self._player_ranks[player_key] = next_rank

        if "exp" in trial.rewards:
            player.add_exp(trial.rewards["exp"])
        if "pot" in trial.rewards:
            player.pot += trial.rewards["pot"]
        if "faction_rep" in trial.rewards:
            fid = player.faction.value
            player.faction_rep[fid] = player.faction_rep.get(fid, 0) + trial.rewards["faction_rep"]

        self._active_trial[player_key] = None

        return {
            "success": True,
            "message": trial.dialogue_success,
            "new_rank": RANK_NAMES.get(next_rank, "未知"),
            "title": trial.rewards.get("title", ""),
            "rewards": trial.rewards,
        }

    def get_faction_info(self, player: Player) -> Dict:
        rank = self.get_rank(player.name)
        title = self.get_rank_title(player.name, player.faction)
        trial = self.get_current_trial(player)
        return {
            "faction": FACTION_NAMES.get(player.faction, "无门无派"),
            "rank": RANK_NAMES.get(rank, "外人"),
            "title": title,
            "current_trial": trial.title if trial else None,
            "trial_description": trial.description if trial else None,
        }


def get_faction_progression() -> FactionProgression:
    return FactionProgression()
