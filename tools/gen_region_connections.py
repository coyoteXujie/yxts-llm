#!/usr/bin/env python3
"""根据 regions.json 的中心坐标和地形自动生成区域连接图。

输出 data/region_connections.json，每个区域映射到一个连接列表，
每条连接包含 target / type / 可选 note 字段。
隐藏入口由 data/region_hidden_entrances.json 注入。
"""

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGIONS_PATH = os.path.join(ROOT, "godot_project", "data", "regions.json")
HIDDEN_PATH = os.path.join(ROOT, "godot_project", "data", "region_hidden_entrances.json")
OUTPUT_PATH = os.path.join(ROOT, "godot_project", "data", "region_connections.json")

MAX_NEIGHBORS = 6
MAX_DISTANCE = 30.0


def load_regions():
    with open(REGIONS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def region_center(region):
    center = region.get("center", [])
    if len(center) >= 2:
        return (float(center[0]), float(center[1]))
    rect = region.get("rect", [])
    if len(rect) >= 4:
        return (float(rect[0]) + float(rect[2]) * 0.5, float(rect[1]) + float(rect[3]) * 0.5)
    return (0.0, 0.0)


def distance(a, b):
    return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)


def infer_connection_type(source, target):
    source_terrain = str(source.get("terrain", ""))
    target_terrain = str(target.get("terrain", ""))
    target_type = str(target.get("type", "wild"))
    if "river" in target_terrain or "lake" in target_terrain or "waterway" in target_terrain or "canal" in target_terrain or "marsh" in target_terrain or "tide" in target_terrain or "ford" in target_terrain:
        return "water"
    if "mountain" in target_terrain or "cliff" in target_terrain or "gorge" in target_terrain or "plateau" in target_terrain or "pass" in target_terrain:
        return "mountain"
    if "forest" in target_terrain or "bamboo" in target_terrain:
        return "forest"
    if target_type == "city":
        return "road"
    if target_type == "town":
        return "road"
    if target_type == "sect":
        return "road"
    return "road"


def build_connections(regions):
    centers = {}
    for region in regions:
        rid = str(region.get("id", ""))
        centers[rid] = region_center(region)

    connections = {}
    for region in regions:
        rid = str(region.get("id", ""))
        scored = []
        for other in regions:
            oid = str(other.get("id", ""))
            if oid == rid:
                continue
            d = distance(centers[rid], centers[oid])
            if d > MAX_DISTANCE:
                continue
            scored.append((d, oid, other))
        scored.sort(key=lambda x: x[0])
        conns = []
        for d, oid, other in scored[:MAX_NEIGHBORS]:
            conn = {
                "target": oid,
                "type": infer_connection_type(region, other),
            }
            conns.append(conn)
        connections[rid] = conns

    return connections


def add_city_spine(connections):
    city_links = [
        ("luoyang", "jiangling"),
        ("luoyang", "changan"),
        ("jiangling", "chengdu"),
        ("jiangling", "linan"),
        ("changan", "chengdu"),
    ]
    for a, b in city_links:
        if a in connections:
            for c in connections[a]:
                if c["target"] == b:
                    break
            else:
                connections[a].append({"target": b, "type": "road", "note": "城际驿路"})
        if b in connections:
            for c in connections[b]:
                if c["target"] == a:
                    break
            else:
                connections[b].append({"target": a, "type": "road", "note": "城际驿路"})


def add_hidden_entrances(connections):
    if not os.path.exists(HIDDEN_PATH):
        return
    with open(HIDDEN_PATH, "r", encoding="utf-8") as f:
        hidden = json.load(f)
    for sect_id, entrances in hidden.items():
        if sect_id not in connections:
            connections[sect_id] = []
        for entrance in entrances:
            target_id = str(entrance.get("from", ""))
            if not target_id:
                continue
            secret_conn = {
                "target": target_id,
                "type": "secret",
                "note": str(entrance.get("note", "")),
                "required_quest": str(entrance.get("required_quest", "")),
                "required_source_exploration": int(entrance.get("required_source_exploration", 0)),
                "required_item": str(entrance.get("required_item", "")),
            }
            connections[sect_id].append(secret_conn)
            if target_id in connections:
                connections[target_id].append({
                    "target": sect_id,
                    "type": "secret",
                    "note": str(entrance.get("note", "")),
                    "required_quest": str(entrance.get("required_quest", "")),
                    "required_source_exploration": int(entrance.get("required_source_exploration", 0)),
                    "required_item": str(entrance.get("required_item", "")),
                })


def main():
    regions = load_regions()
    connections = build_connections(regions)
    add_city_spine(connections)
    add_hidden_entrances(connections)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(connections, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = sum(len(v) for v in connections.values())
    print(f"Generated {len(connections)} regions with {total} connections -> {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
