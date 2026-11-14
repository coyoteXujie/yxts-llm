extends RefCounted
class_name TravelPlanner

const TRAVEL_ROUTE_NEIGHBOR_LIMIT := 8

static func region_center_tile(region: Dictionary, fallback_tile: Vector2i) -> Vector2i:
	var center_data: Array = region.get("center", [])
	if center_data.size() >= 2:
		return Vector2i(int(center_data[0]), int(center_data[1]))
	var rect: Array = region.get("rect", [])
	if rect.size() >= 4:
		return Vector2i(int(rect[0]) + int(rect[2]) / 2, int(rect[1]) + int(rect[3]) / 2)
	return fallback_tile

static func region_center_distance(source: Dictionary, target: Dictionary, fallback_tile: Vector2i) -> float:
	var source_tile := region_center_tile(source, fallback_tile)
	var target_tile := region_center_tile(target, fallback_tile)
	return Vector2(float(source_tile.x), float(source_tile.y)).distance_to(Vector2(float(target_tile.x), float(target_tile.y)))

static func region_travel_edge_cost(source: Dictionary, target: Dictionary, fallback_tile: Vector2i) -> float:
	var distance := region_center_distance(source, target, fallback_tile)
	var target_type := str(target.get("type", "wild"))
	var danger := float(target.get("danger", 1))
	var type_cost := 0.0
	match target_type:
		"city":
			type_cost = 0.0
		"town":
			type_cost = 0.7
		"sect":
			type_cost = 1.0
		_:
			type_cost = 1.8
	var connection_penalty := _connection_type_penalty(str(source.get("id", "")), str(target.get("id", "")))
	return distance + danger * 1.35 + type_cost + connection_penalty

static func _connection_type_penalty(source_id: String, target_id: String) -> float:
	var connections: Array[Dictionary] = GameData.get_region_connections(source_id)
	for conn in connections:
		if str(conn.get("target", "")) == target_id:
			match str(conn.get("type", "road")):
				"water":
					return 0.6
				"mountain":
					return 1.8
				"forest":
					return 0.9
				"secret":
					return 3.0
			return 0.0
	return 0.0

static func find_region_route(source_id: String, target_id: String, fallback_tile: Vector2i) -> Array[String]:
	var route: Array[String] = []
	if source_id.is_empty() or target_id.is_empty():
		if not source_id.is_empty():
			route.append(source_id)
		if not target_id.is_empty() and target_id != source_id:
			route.append(target_id)
		return route
	if source_id == target_id:
		return [source_id]
	var open: Array[String] = [source_id]
	var costs: Dictionary = {}
	costs[source_id] = 0.0
	var came_from: Dictionary = {}
	var visited: Dictionary = {}
	while not open.is_empty():
		open.sort_custom(func(a: String, b: String) -> bool:
			return float(costs.get(a, INF)) < float(costs.get(b, INF))
		)
		var current_id := str(open.pop_front())
		if bool(visited.get(current_id, false)):
			continue
		visited[current_id] = true
		if current_id == target_id:
			break
		var current_region := GameData.get_region(current_id)
		for neighbor in GameData.get_neighbor_regions(current_id, TRAVEL_ROUTE_NEIGHBOR_LIMIT):
			if typeof(neighbor) != TYPE_DICTIONARY:
				continue
			var next_region: Dictionary = neighbor
			var next_id := str(next_region.get("id", ""))
			if next_id.is_empty() or bool(visited.get(next_id, false)):
				continue
			var next_cost := float(costs.get(current_id, 0.0)) + region_travel_edge_cost(current_region, next_region, fallback_tile)
			if not costs.has(next_id) or next_cost < float(costs.get(next_id, INF)):
				costs[next_id] = next_cost
				came_from[next_id] = current_id
				if not open.has(next_id):
					open.append(next_id)
	if not costs.has(target_id):
		return [source_id, target_id]
	var reversed: Array[String] = []
	var cursor := target_id
	var guard := 0
	while guard < 128:
		reversed.append(cursor)
		if cursor == source_id:
			break
		if not came_from.has(cursor):
			break
		cursor = str(came_from[cursor])
		guard += 1
	for index in range(reversed.size() - 1, -1, -1):
		route.append(reversed[index])
	return route

static func route_distance(route: Array[String], fallback_tile: Vector2i) -> float:
	if route.size() <= 1:
		return 0.0
	var distance := 0.0
	for index in range(route.size() - 1):
		distance += region_center_distance(GameData.get_region(route[index]), GameData.get_region(route[index + 1]), fallback_tile)
	return roundf(distance * 10.0) / 10.0

static func route_region_names(route: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for region_id in route:
		var region := GameData.get_region(region_id)
		if region.is_empty():
			continue
		names.append(str(region.get("name", region_id)))
	return names

static func route_risk_label(risk_level: int) -> String:
	if risk_level >= 5:
		return "极险"
	if risk_level >= 4:
		return "险路"
	if risk_level >= 3:
		return "危险"
	if risk_level >= 2:
		return "谨慎"
	return "平稳"

static func route_risk_note(risk_level: int) -> String:
	if risk_level >= 5:
		return "天气和地势都不利，路上很可能遭遇伏击。"
	if risk_level >= 4:
		return "路段险峻，最好备足伤药。"
	if risk_level >= 3:
		return "沿途有盗匪和暗哨传闻。"
	if risk_level >= 2:
		return "官道可行，但仍需留心。"
	return "多为熟路，适合赶路。"
