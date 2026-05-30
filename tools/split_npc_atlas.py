from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
NPC_ASSET_DIR = ROOT / "godot_project" / "assets" / "characters" / "npc"
ATLAS_DIR = NPC_ASSET_DIR / "atlases"
SPRITE_DIR = NPC_ASSET_DIR / "sprites"


@dataclass(frozen=True)
class AtlasSpec:
    source: str
    columns: int
    rows: int
    names: tuple[str, ...]
    slugs: tuple[str, ...]


ATLAS_SPECS = (
    AtlasSpec(
        source="npc_town_core_atlas.png",
        columns=4,
        rows=2,
        names=("平阿四", "店小二", "阿青", "老夫子", "捕快", "村长", "道德和尚", "铁匠"),
        slugs=(
            "ping_asi",
            "dian_xiaoer",
            "aqing",
            "lao_fuzi",
            "bukuai",
            "cunzhang",
            "daode_heshang",
            "tiejiang",
        ),
    ),
    AtlasSpec(
        source="npc_masters_core_atlas.png",
        columns=5,
        rows=1,
        names=("韦扬", "清照", "清虚道人", "白瑞德", "大侠"),
        slugs=("wei_yang", "qing_zhao", "qingxu_daoren", "bai_ruide", "daxia"),
    ),
    AtlasSpec(
        source="npc_enemies_core_atlas.png",
        columns=4,
        rows=1,
        names=("流氓", "流氓头", "采花大盗", "神秘人"),
        slugs=("liumang", "liumang_tou", "caihua_dadao", "shenmi_ren"),
    ),
    AtlasSpec(
        source="npc_town_extended_atlas.png",
        columns=4,
        rows=3,
        names=("阎商", "葛朗台", "厨师", "屠夫", "卖花女", "小商贩", "平一指", "何铁手", "何喜", "小裁缝", "何裁缝", "李白"),
        slugs=(
            "yan_shang",
            "gelangtai",
            "chushi",
            "tufu",
            "maihua_nv",
            "xiao_shangfan",
            "ping_yizhi",
            "he_tieshou",
            "he_xi",
            "xiao_caifeng",
            "he_caifeng",
            "li_bai",
        ),
    ),
    AtlasSpec(
        source="npc_sects_extended_atlas.png",
        columns=4,
        rows=3,
        names=("于红儒", "方长老", "楚红灯", "崇儿", "钟央", "十三卫", "美奈子", "浪人甲", "简明", "简杰", "红拂女", "隐娘"),
        slugs=(
            "yu_hongru",
            "fang_zhanglao",
            "chu_hongdeng",
            "chonger",
            "zhong_yang",
            "shisan_wei",
            "meinazi",
            "langren_jia",
            "jian_ming",
            "jian_jie",
            "hongfu_nv",
            "yin_niang",
        ),
    ),
    AtlasSpec(
        source="npc_sects_enemies_extended_atlas.png",
        columns=4,
        rows=3,
        names=("古松道人", "仓月道人", "采药道人", "知客道人", "史婆婆", "万剑", "万刃", "阿秀", "雪千柔", "独角大盗", "黑衣大盗", "魔化和尚"),
        slugs=(
            "gusong_daoren",
            "cangyue_daoren",
            "caiyao_daoren",
            "zhike_daoren",
            "shi_popo",
            "wan_jian",
            "wan_ren",
            "a_xiu",
            "xue_qianrou",
            "dujiao_dadao",
            "heiyi_dadao",
            "mohua_heshang",
        ),
    ),
)


def crop_cell(image: Image.Image, spec: AtlasSpec, index: int) -> Image.Image:
    row = index // spec.columns
    col = index % spec.columns
    left = round(col * image.width / spec.columns)
    right = round((col + 1) * image.width / spec.columns)
    top = round(row * image.height / spec.rows)
    bottom = round((row + 1) * image.height / spec.rows)
    cell = image.crop((left, top, right, bottom)).convert("RGBA")
    alpha = cell.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return cell
    pad = 18
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(cell.width, bbox[2] + pad)
    bottom = min(cell.height, bbox[3] + pad)
    return cell.crop((left, top, right, bottom))


def main() -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    for spec in ATLAS_SPECS:
        image = Image.open(ATLAS_DIR / spec.source).convert("RGBA")
        expected = spec.columns * spec.rows
        if expected != len(spec.names) or expected != len(spec.slugs):
            raise ValueError(f"{spec.source} grid does not match name list")
        for index, slug in enumerate(spec.slugs):
            sprite = crop_cell(image, spec, index)
            sprite.save(SPRITE_DIR / f"npc_{slug}.png")
            print(f"{spec.names[index]} -> npc_{slug}.png {sprite.width}x{sprite.height}")


if __name__ == "__main__":
    main()
