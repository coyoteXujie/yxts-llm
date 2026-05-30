#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "godot_project" / "data"
MAP_WIDTH = 96
MAP_HEIGHT = 72


def load_json(name: str):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    npcs = load_json("npcs.json")
    items = load_json("items.json")
    quests = load_json("quests.json")
    regions = load_json("regions.json")
    sprite_assets = load_json("npc_sprite_assets.json")
    portrait_assets = load_json("npc_portrait_assets.json")
    item_icon_assets = load_json("item_icon_assets.json")
    scene_background_assets = load_json("scene_background_assets.json")

    item_ids = {item["id"] for item in items}
    npc_names = {npc["name"] for npc in npcs}
    region_ids = [region["id"] for region in regions]
    region_id_set = set(region_ids)
    skill_text = (ROOT / "godot_project" / "scripts" / "autoload" / "game_data.gd").read_text(encoding="utf-8")
    skill_ids = set(re.findall(r'"(kf_[a-zA-Z0-9_]+)"', skill_text))

    if len(region_ids) != len(set(region_ids)):
        errors.append("regions.json has duplicate ids")
    expected_counts = {"city": 5, "town": 16, "wild": 45, "sect": 7}
    for region_type, expected in expected_counts.items():
        actual = sum(1 for region in regions if region.get("type") == region_type)
        if actual != expected:
            errors.append(f"region type {region_type} count {actual}, expected {expected}")

    for region in regions:
        rect = region.get("rect", [])
        if len(rect) != 4:
            errors.append(f"region {region.get('id')} has invalid rect")
            continue
        x, y, width, height = map(int, rect)
        if width <= 0 or height <= 0:
            errors.append(f"region {region.get('id')} has non-positive size")
        if x < 0 or y < 0 or x + width > MAP_WIDTH or y + height > MAP_HEIGHT:
            errors.append(f"region {region.get('id')} rect out of map bounds: {rect}")

    for npc in npcs:
        x = int(npc.get("pos_x", -1))
        y = int(npc.get("pos_y", -1))
        if not (0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT):
            errors.append(f"npc {npc.get('name')} position out of bounds: {(x, y)}")
        for item_id in npc.get("sell_items", []):
            if item_id not in item_ids:
                errors.append(f"npc {npc.get('name')} sells missing item {item_id}")
        for skill_id in npc.get("teach_skills", []):
            if skill_id not in skill_ids:
                errors.append(f"npc {npc.get('name')} teaches missing skill {skill_id}")

    position_counts = Counter((int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1))) for npc in npcs)
    for position, count in position_counts.items():
        if count > 1:
            names = [npc.get("name", "") for npc in npcs if (int(npc.get("pos_x", -1)), int(npc.get("pos_y", -1))) == position]
            errors.append(f"npc position overlap at {position}: {', '.join(names)}")

    for quest in quests:
        giver = quest.get("giver", "")
        if giver and giver not in npc_names:
            errors.append(f"quest {quest.get('id')} has missing giver {giver}")
        for objective in quest.get("objectives", []):
            target = objective.get("target", "")
            kind = objective.get("type", "")
            if kind in {"talk", "kill"} and target not in npc_names:
                errors.append(f"quest {quest.get('id')} objective target missing npc {target}")
            if kind == "collect" and target not in item_ids:
                errors.append(f"quest {quest.get('id')} objective target missing item {target}")
            if kind == "skill" and target not in skill_ids:
                errors.append(f"quest {quest.get('id')} objective target missing skill {target}")
        for item_id in quest.get("rewards", {}).get("items", {}).keys():
            if item_id not in item_ids:
                errors.append(f"quest {quest.get('id')} rewards missing item {item_id}")

    for npc_name, sprite_path in sprite_assets.items():
        if npc_name not in npc_names:
            errors.append(f"sprite mapping references missing npc {npc_name}")
        asset_path = ROOT / "godot_project" / sprite_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"sprite path missing for {npc_name}: {sprite_path}")

    for npc_name, portrait_path in portrait_assets.items():
        if npc_name not in npc_names:
            errors.append(f"portrait mapping references missing npc {npc_name}")
        asset_path = ROOT / "godot_project" / portrait_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"portrait path missing for {npc_name}: {portrait_path}")

    for item_id, icon_path in item_icon_assets.items():
        if item_id not in item_ids:
            errors.append(f"item icon mapping references missing item {item_id}")
        asset_path = ROOT / "godot_project" / icon_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"item icon path missing for {item_id}: {icon_path}")

    for region_id, background_path in scene_background_assets.items():
        if region_id not in region_id_set:
            errors.append(f"scene background mapping references missing region {region_id}")
        asset_path = ROOT / "godot_project" / background_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"scene background path missing for {region_id}: {background_path}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(
        f"OK regions={len(regions)} npcs={len(npcs)} items={len(items)} quests={len(quests)} "
        f"sprites={len(sprite_assets)} portraits={len(portrait_assets)} icons={len(item_icon_assets)} scenes={len(scene_background_assets)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
