#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import struct
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "godot_project" / "data"
MAP_WIDTH = 96
MAP_HEIGHT = 72
MIN_STAGE_LAYER_WIDTH = 1280
MIN_STAGE_LAYER_HEIGHT = 720
MIN_SHOP_INTERIOR_WIDTH = 1280
MIN_SHOP_INTERIOR_HEIGHT = 800
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MIN_DETAILED_STAGE_LAYER_BYTES = {
    ("qinghe", "floor"): 70_000,
    ("qinghe", "midground"): 120_000,
    ("qinghe", "foreground"): 78_000,
    ("chengdu", "floor"): 70_000,
    ("chengdu", "midground"): 120_000,
    ("chengdu", "foreground"): 120_000,
    ("shudao_mtn", "floor"): 48_000,
    ("shudao_mtn", "midground"): 105_000,
    ("shudao_mtn", "foreground"): 175_000,
    ("dujiang_weir", "floor"): 90_000,
    ("dujiang_weir", "midground"): 75_000,
    ("dujiang_weir", "foreground"): 180_000,
    ("minjiang_river", "floor"): 95_000,
    ("minjiang_river", "midground"): 115_000,
    ("minjiang_river", "foreground"): 220_000,
    ("xindu_field", "floor"): 80_000,
    ("xindu_field", "midground"): 70_000,
    ("xindu_field", "foreground"): 125_000,
    ("wenjiang_garden", "floor"): 65_000,
    ("wenjiang_garden", "midground"): 90_000,
    ("wenjiang_garden", "foreground"): 140_000,
    ("western_plateau", "floor"): 30_000,
    ("western_plateau", "midground"): 115_000,
    ("western_plateau", "foreground"): 50_000,
    ("qingcheng_mtn", "floor"): 60_000,
    ("qingcheng_mtn", "midground"): 80_000,
    ("qingcheng_mtn", "foreground"): 130_000,
    ("emei_sacred", "floor"): 120_000,
    ("emei_sacred", "midground"): 120_000,
    ("emei_sacred", "foreground"): 190_000,
}


def load_json(name: str):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def resolve_asset_path(path: str) -> Path:
    return ROOT / "godot_project" / path.removeprefix("res://")


def read_png_info(path: Path) -> tuple[int, int, int] | None:
    with path.open("rb") as handle:
        if handle.read(8) != PNG_SIGNATURE:
            return None
        length_data = handle.read(4)
        if len(length_data) != 4:
            return None
        length = struct.unpack(">I", length_data)[0]
        chunk_type = handle.read(4)
        if chunk_type != b"IHDR" or length < 13:
            return None
        data = handle.read(length)
        if len(data) < 13:
            return None
        width, height, _bit_depth, color_type, _compression, _filter, _interlace = struct.unpack(">IIBBBBB", data[:13])
        return width, height, color_type


def _validate_region_shop_list(errors: list[str], owner: str, shops, allowed_shop_ids: set[str]) -> None:
    if not isinstance(shops, list):
        errors.append(f"region shop mapping for {owner} must be a list")
        return
    if not shops:
        errors.append(f"region shop mapping for {owner} must not be empty")
    if len(shops) > 6:
        errors.append(f"region shop mapping for {owner} has {len(shops)} shops, but the local map has 6 shop slots")
    seen: set[str] = set()
    for shop_id in shops:
        shop_key = str(shop_id)
        if shop_key not in allowed_shop_ids:
            errors.append(f"region shop mapping for {owner} references unknown shop {shop_key}")
        if shop_key in seen:
            errors.append(f"region shop mapping for {owner} repeats shop {shop_key}")
        seen.add(shop_key)


def _local_region_size(region_type: str) -> tuple[int, int]:
    if region_type == "city":
        return 80, 54
    if region_type == "town":
        return 58, 40
    if region_type == "sect":
        return 64, 44
    return 72, 48


def _validate_region_point_list(
    errors: list[str],
    owner: str,
    points,
    item_ids: set[str],
    map_size: tuple[int, int],
    allowed_point_kinds: set[str],
) -> None:
    if not isinstance(points, list):
        errors.append(f"region point mapping for {owner} must be a list")
        return
    if not points:
        errors.append(f"region point mapping for {owner} must not be empty")
    for index, point in enumerate(points):
        point_owner = f"{owner}[{index}]"
        if not isinstance(point, dict):
            errors.append(f"region point {point_owner} must be an object")
            continue
        for required_key in ("label", "description", "kind", "tile"):
            if required_key not in point:
                errors.append(f"region point {point_owner} missing {required_key}")
        if str(point.get("kind", "")) not in allowed_point_kinds:
            errors.append(f"region point {point_owner} has unknown kind {point.get('kind')}")
        tile = point.get("tile", [])
        if not isinstance(tile, list) or len(tile) < 2:
            errors.append(f"region point {point_owner} tile must be [x, y]")
        else:
            x, y = int(tile[0]), int(tile[1])
            if x < 0 or y < 0 or x >= map_size[0] or y >= map_size[1]:
                errors.append(f"region point {point_owner} tile {tile} outside local map {map_size[0]}x{map_size[1]}")
        reward_item = str(point.get("reward_item", ""))
        if reward_item and reward_item not in item_ids:
            errors.append(f"region point {point_owner} references missing reward item {reward_item}")
        for reward_key in ("reward_money", "reward_exp", "reward_count"):
            if reward_key in point and not isinstance(point[reward_key], int):
                errors.append(f"region point {point_owner}.{reward_key} must be an integer")
        if int(point.get("reward_count", 1)) < 1:
            errors.append(f"region point {point_owner}.reward_count must be positive")


def main() -> int:
    errors: list[str] = []
    npcs = load_json("npcs.json")
    items = load_json("items.json")
    quests = load_json("quests.json")
    regions = load_json("regions.json")
    sprite_assets = load_json("npc_sprite_assets.json")
    portrait_assets = load_json("npc_portrait_assets.json")
    item_icon_assets = load_json("item_icon_assets.json")
    skill_icon_assets = load_json("skill_icon_assets.json")
    scene_background_assets = load_json("scene_background_assets.json")
    stage_layer_assets = load_json("stage_layer_assets.json")
    shop_interior_assets = load_json("shop_interior_assets.json")
    combat_stage_assets = load_json("combat_stage_assets.json")
    combat_actor_frames = load_json("combat_actor_frames.json")
    region_shop_assets = load_json("region_shops.json")
    region_point_assets = load_json("region_points.json")

    item_ids = {item["id"] for item in items}
    npc_names = {npc["name"] for npc in npcs}
    region_ids = [region["id"] for region in regions]
    region_id_set = set(region_ids)
    regions_by_id = {region["id"]: region for region in regions}
    allowed_shop_ids = {"inn", "medicine", "blacksmith", "tailor", "market", "teahouse"}
    allowed_point_kinds = {
        "notice", "well", "market", "training", "shrine", "dock", "water", "bridge",
        "ruin", "cave", "herb", "flower", "cache", "coin", "fish", "ore",
    }
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
        center = region.get("center", [])
        if len(center) != 2:
            errors.append(f"region {region.get('id')} has invalid center")
        else:
            cx, cy = map(int, center)
            if not (0 <= cx < MAP_WIDTH and 0 <= cy < MAP_HEIGHT):
                errors.append(f"region {region.get('id')} center out of map bounds: {center}")
            if not (x <= cx < x + width and y <= cy < y + height):
                errors.append(f"region {region.get('id')} center outside rect: center={center} rect={rect}")

    for npc in npcs:
        x = int(npc.get("pos_x", -1))
        y = int(npc.get("pos_y", -1))
        if not (0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT):
            errors.append(f"npc {npc.get('name')} position out of bounds: {(x, y)}")
        if not str(npc.get("personality", "")).strip():
            errors.append(f"npc {npc.get('name')} missing personality")
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
        for skill_id in quest.get("rewards", {}).get("skills", {}).keys():
            if skill_id not in skill_ids:
                errors.append(f"quest {quest.get('id')} rewards missing skill {skill_id}")

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

    for skill_id, icon_path in skill_icon_assets.items():
        if skill_id not in skill_ids:
            errors.append(f"skill icon mapping references missing skill {skill_id}")
        asset_path = ROOT / "godot_project" / icon_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"skill icon path missing for {skill_id}: {icon_path}")
    for skill_id in skill_ids:
        if skill_id not in skill_icon_assets:
            errors.append(f"skill {skill_id} missing icon mapping")

    for region_id, background_path in scene_background_assets.items():
        if region_id not in region_id_set:
            errors.append(f"scene background mapping references missing region {region_id}")
        asset_path = ROOT / "godot_project" / background_path.removeprefix("res://")
        if not asset_path.exists():
            errors.append(f"scene background path missing for {region_id}: {background_path}")

    if not isinstance(shop_interior_assets, dict):
        errors.append("shop_interior_assets.json must be an object")
    else:
        missing_shop_interiors = allowed_shop_ids - set(shop_interior_assets.keys())
        if missing_shop_interiors:
            errors.append(f"shop interior assets missing shops: {', '.join(sorted(missing_shop_interiors))}")
        for shop_id, asset_path_text in shop_interior_assets.items():
            if shop_id not in allowed_shop_ids:
                errors.append(f"shop interior mapping references unknown shop {shop_id}")
            resolved_path = resolve_asset_path(str(asset_path_text))
            if not resolved_path.exists():
                errors.append(f"shop interior path missing for {shop_id}: {asset_path_text}")
                continue
            png_info = read_png_info(resolved_path)
            if png_info is None:
                errors.append(f"shop interior path for {shop_id} is not a valid PNG: {asset_path_text}")
                continue
            width, height, _color_type = png_info
            if width < MIN_SHOP_INTERIOR_WIDTH or height < MIN_SHOP_INTERIOR_HEIGHT:
                errors.append(
                    f"shop interior {shop_id} resolution {width}x{height}, "
                    f"expected at least {MIN_SHOP_INTERIOR_WIDTH}x{MIN_SHOP_INTERIOR_HEIGHT}"
                )

    if not isinstance(region_shop_assets, dict):
        errors.append("region_shops.json must be an object")
    else:
        default_shops = region_shop_assets.get("_defaults", {})
        if not isinstance(default_shops, dict):
            errors.append("region_shops.json _defaults must be an object")
        else:
            for region_type, shops in default_shops.items():
                if region_type not in {"city", "town", "sect"}:
                    errors.append(f"region_shops.json has unknown default region type {region_type}")
                _validate_region_shop_list(errors, f"_defaults.{region_type}", shops, allowed_shop_ids)
        for region_id, shops in region_shop_assets.items():
            if region_id == "_defaults":
                continue
            if region_id not in region_id_set:
                errors.append(f"region shop mapping references missing region {region_id}")
            _validate_region_shop_list(errors, str(region_id), shops, allowed_shop_ids)

    if not isinstance(region_point_assets, dict):
        errors.append("region_points.json must be an object")
    else:
        for region_id, entry in region_point_assets.items():
            if region_id not in region_id_set:
                errors.append(f"region point mapping references missing region {region_id}")
                continue
            if not isinstance(entry, dict):
                errors.append(f"region point mapping for {region_id} must be an object")
                continue
            unknown_sections = set(entry.keys()) - {"landmarks", "resources"}
            if unknown_sections:
                errors.append(f"region point mapping for {region_id} has unknown sections: {', '.join(sorted(unknown_sections))}")
            map_size = _local_region_size(str(regions_by_id[region_id].get("type", "wild")))
            for point_type in ("landmarks", "resources"):
                if point_type not in entry:
                    errors.append(f"region point mapping for {region_id} missing {point_type}")
                    continue
                _validate_region_point_list(
                    errors,
                    f"{region_id}.{point_type}",
                    entry[point_type],
                    item_ids,
                    map_size,
                    allowed_point_kinds,
                )

    allowed_stage_layers = {"floor", "midground", "foreground"}
    required_stage_layers = {"floor", "midground", "foreground"}
    for region_id, layers in stage_layer_assets.items():
        if region_id not in region_id_set:
            errors.append(f"stage layer mapping references missing region {region_id}")
        if not isinstance(layers, dict):
            errors.append(f"stage layer mapping for {region_id} must be an object")
            continue
        missing_layers = required_stage_layers - set(layers.keys())
        if missing_layers:
            errors.append(f"stage layer mapping for {region_id} missing layers: {', '.join(sorted(missing_layers))}")
        layer_sizes: dict[str, tuple[int, int]] = {}
        for layer_name, layer_path in layers.items():
            if layer_name not in allowed_stage_layers:
                errors.append(f"stage layer mapping for {region_id} has unknown layer {layer_name}")
            resolved_path = resolve_asset_path(str(layer_path))
            if not resolved_path.exists():
                errors.append(f"stage layer path missing for {region_id}.{layer_name}: {layer_path}")
                continue
            minimum_bytes = MIN_DETAILED_STAGE_LAYER_BYTES.get((str(region_id), str(layer_name)))
            if minimum_bytes is not None and resolved_path.stat().st_size < minimum_bytes:
                errors.append(
                    f"stage layer {region_id}.{layer_name} is too small for the detailed DNF stage asset: "
                    f"{resolved_path.stat().st_size} bytes, expected at least {minimum_bytes}"
                )
            png_info = read_png_info(resolved_path)
            if png_info is None:
                errors.append(f"stage layer path for {region_id}.{layer_name} is not a valid PNG: {layer_path}")
                continue
            width, height, color_type = png_info
            if width < MIN_STAGE_LAYER_WIDTH or height < MIN_STAGE_LAYER_HEIGHT:
                errors.append(
                    f"stage layer {region_id}.{layer_name} resolution {width}x{height}, "
                    f"expected at least {MIN_STAGE_LAYER_WIDTH}x{MIN_STAGE_LAYER_HEIGHT}"
                )
            if color_type not in {4, 6}:
                errors.append(f"stage layer {region_id}.{layer_name} must include alpha channel: {layer_path}")
            layer_sizes[layer_name] = (width, height)
        if len(set(layer_sizes.values())) > 1:
            size_desc = ", ".join(f"{name}={size[0]}x{size[1]}" for name, size in sorted(layer_sizes.items()))
            errors.append(f"stage layers for {region_id} must share the same source size: {size_desc}")
        background_path = scene_background_assets.get(region_id, "")
        if layer_sizes and background_path:
            resolved_background = resolve_asset_path(str(background_path))
            if resolved_background.exists():
                background_info = read_png_info(resolved_background)
                if background_info is None:
                    errors.append(f"scene background for layered stage {region_id} is not a valid PNG: {background_path}")
                else:
                    background_size = (background_info[0], background_info[1])
                    expected_size = next(iter(layer_sizes.values()))
                    if background_size != expected_size:
                        errors.append(
                            f"scene background for layered stage {region_id} must match stage layer size: "
                            f"background={background_size[0]}x{background_size[1]} layers={expected_size[0]}x{expected_size[1]}"
                        )

    allowed_combat_stage_layers = {"backdrop", "midground", "floor", "foreground"}
    for region_id, layers in combat_stage_assets.items():
        if region_id not in region_id_set:
            errors.append(f"combat stage mapping references missing region {region_id}")
        if not isinstance(layers, dict):
            errors.append(f"combat stage mapping for {region_id} must be an object")
            continue
        missing_layers = allowed_combat_stage_layers - set(layers.keys())
        if missing_layers:
            errors.append(f"combat stage mapping for {region_id} missing layers: {', '.join(sorted(missing_layers))}")
        for layer_name, layer_path in layers.items():
            if layer_name not in allowed_combat_stage_layers:
                errors.append(f"combat stage mapping for {region_id} has unknown layer {layer_name}")
            asset_path = ROOT / "godot_project" / str(layer_path).removeprefix("res://")
            if not asset_path.exists():
                errors.append(f"combat stage layer path missing for {region_id}.{layer_name}: {layer_path}")

    required_actor_actions = {"idle", "attack", "hurt", "down"}
    for actor_key, actions in combat_actor_frames.items():
        if not isinstance(actions, dict):
            errors.append(f"combat actor frame mapping for {actor_key} must be an object")
            continue
        missing_actions = required_actor_actions - set(actions.keys())
        if missing_actions:
            errors.append(f"combat actor frame mapping for {actor_key} missing actions: {', '.join(sorted(missing_actions))}")
        for action_name, frames in actions.items():
            if action_name not in required_actor_actions:
                errors.append(f"combat actor frame mapping for {actor_key} has unknown action {action_name}")
            if not isinstance(frames, list) or not frames:
                errors.append(f"combat actor frame mapping for {actor_key}.{action_name} must be a non-empty list")
                continue
            for frame_path in frames:
                asset_path = ROOT / "godot_project" / str(frame_path).removeprefix("res://")
                if not asset_path.exists():
                    errors.append(f"combat actor frame path missing for {actor_key}.{action_name}: {frame_path}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(
        f"OK regions={len(regions)} npcs={len(npcs)} items={len(items)} quests={len(quests)} "
        f"sprites={len(sprite_assets)} portraits={len(portrait_assets)} icons={len(item_icon_assets)} skill_icons={len(skill_icon_assets)} "
        f"scenes={len(scene_background_assets)} stage_layers={len(stage_layer_assets)} region_shops={len(region_shop_assets)} region_points={len(region_point_assets)} "
        f"shop_interiors={len(shop_interior_assets)} combat_stages={len(combat_stage_assets)} combat_actor_frames={len(combat_actor_frames)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
