extends Node

signal npc_line_ready(npc_name: String, line: String)
signal npc_line_failed(npc_name: String, reason: String)

const ENDPOINT_ENV := "YXT_LLM_ENDPOINT"
const API_KEY_ENV := "YXT_LLM_API_KEY"
const MODEL_ENV := "YXT_LLM_MODEL"
const DEFAULT_MODEL := "gpt-4.1-mini"

var endpoint := ""
var api_key := ""
var model := DEFAULT_MODEL

var _http: HTTPRequest
var _request_busy := false
var _pending_npc_name := ""

func _ready() -> void:
	endpoint = OS.get_environment(ENDPOINT_ENV)
	api_key = OS.get_environment(API_KEY_ENV)
	var env_model := OS.get_environment(MODEL_ENV)
	if not env_model.is_empty():
		model = env_model
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func configure_backend(config: Dictionary) -> void:
	endpoint = str(config.get("endpoint", endpoint))
	api_key = str(config.get("api_key", api_key))
	model = str(config.get("model", model))

func is_live_backend_configured() -> bool:
	return not endpoint.strip_edges().is_empty()

func generate_npc_line(npc_data: Dictionary, turn_index: int = 0) -> String:
	var npc_name := str(npc_data.get("name", "对方"))
	var hook := _npc_story_hook(npc_name, npc_data)
	var world := _world_line(npc_name, turn_index)
	var relation := _relation_line(npc_name)
	var lines: Array[String] = []
	if not hook.is_empty():
		lines.append("【心绪】%s" % hook)
	if not world.is_empty():
		lines.append("【风声】%s" % world)
	if not relation.is_empty() and turn_index % 2 == 1:
		lines.append("【旧识】%s" % relation)
	if lines.is_empty():
		return "【风声】江湖路远，今日也有新的传闻。"
	return "\n".join(lines.slice(0, 2))

func generate_ambient_npc_line(npc_data: Dictionary, distance_to_player: float = 0.0, emphasized: bool = false) -> String:
	var npc_name := str(npc_data.get("name", "路人"))
	if npc_name.is_empty():
		return ""
	var event_hint := _recent_event_hint()
	var quest := _active_quest_title()
	var weather_hint := _weather_hint()
	var relation := GameState.get_npc_relation_label(npc_name)
	var variants := _ambient_variants(npc_name, npc_data, event_hint, quest, weather_hint, relation)
	if variants.is_empty():
		return ""
	var seed_text := "%s:%s:%d:%d:%d" % [
		npc_name,
		GameState.current_region_id,
		GameState.day,
		int(GameState.hour * 10.0),
		int(distance_to_player)
	]
	var index: int = abs(hash(seed_text)) % variants.size()
	var line := str(variants[index]).strip_edges()
	if emphasized and not event_hint.is_empty():
		line = event_hint
	return _trim_ambient_line(line)

func request_live_npc_line(npc_data: Dictionary) -> bool:
	if not is_live_backend_configured() or _request_busy or _http == null:
		return false
	var npc_name := str(npc_data.get("name", ""))
	if npc_name.is_empty():
		return false
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not api_key.strip_edges().is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	var payload := {
		"model": model,
		"messages": build_prompt_messages(npc_data),
		"temperature": 0.75,
		"max_tokens": 140
	}
	_request_busy = true
	_pending_npc_name = npc_name
	var err := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		_request_busy = false
		_pending_npc_name = ""
		npc_line_failed.emit(npc_name, "请求失败：%d" % err)
		return false
	return true

func build_prompt_messages(npc_data: Dictionary) -> Array:
	return [
		{
			"role": "system",
			"content": "你是武侠开放世界 RPG 的 NPC 即兴导演。只输出 NPC 对玩家说的一到两句中文台词，不要解释，不要提到模型、系统或规则。"
		},
		{
			"role": "user",
			"content": JSON.stringify(_build_world_context(npc_data), "\t")
		}
	]

func _build_world_context(npc_data: Dictionary) -> Dictionary:
	var npc_name := str(npc_data.get("name", "NPC"))
	var memory: Dictionary = GameState.get_npc_memory(npc_name)
	return {
		"npc": {
			"name": npc_name,
			"description": str(npc_data.get("description", "")),
			"personality": str(npc_data.get("personality", "")),
			"faction": GameData.get_faction_name(str(npc_data.get("faction", "none"))),
			"relation": GameState.get_npc_relation_label(npc_name),
			"favor": int(memory.get("favor", 0)),
			"recent_memories": memory.get("memories", [])
		},
		"world": {
			"day": GameState.day,
			"hour": GameState.hour,
			"weather": GameState.weather,
			"region": GameState.current_region_name,
			"active_quest": _active_quest_title(),
			"completed_quests": _completed_quest_titles(5),
			"recent_events": GameState.get_recent_world_events(6)
		},
		"story_threads": _story_threads()
	}

func _world_line(npc_name: String, turn_index: int) -> String:
	var region: String = GameState.current_region_name
	if region.is_empty() or region == "未知之地":
		region = "路上"
	var weather_hint := _weather_hint()
	var quest := _active_quest_title()
	var quest_hint := ""
	if quest.contains("洛阳") or quest.contains("暗影") or quest.contains("七派") or quest.contains("夜议"):
		quest_hint = "你追的那条线已经惊动了几处山门"
	elif quest.contains("镇东") or quest.contains("试炼"):
		quest_hint = "镇外的小乱也许只是大局露出的线头"
	elif not quest.is_empty():
		quest_hint = "眼前这桩事若办得干净，后面的路会亮一些"
	else:
		quest_hint = "没有任务牵着你时，消息反而最容易漏出来"
	var event_hint := _recent_event_hint()
	if not event_hint.is_empty():
		quest_hint = event_hint
	var variants := [
		"%s%s，有人从%s带来消息：%s。" % [region, weather_hint, _nearby_region_name(), quest_hint],
		"%s%s，脚店里传得最急的是%s。" % [region, weather_hint, quest_hint],
		"%s%s，%s听见风里有不寻常的脚步。" % [region, weather_hint, npc_name]
	]
	return variants[abs(hash("%s:%d:%s" % [npc_name, turn_index, quest])) % variants.size()]

func _ambient_variants(npc_name: String, npc_data: Dictionary, event_hint: String, quest: String, weather_hint: String, relation: String) -> Array[String]:
	var region := GameState.current_region_name
	if region.is_empty() or region == "未知之地":
		region = "路上"
	var lines: Array[String] = []
	if not event_hint.is_empty():
		lines.append(event_hint)
	match npc_name:
		"苏梦瑶":
			lines.append("苏家旧火还没灭，只是藏进了卷宗。")
			lines.append("玉佩上的半纹，迟早会指向暗影司。")
		"陈天行":
			lines.append("茶盏换了位置，说明有人刚来过。")
			lines.append("说书人最怕的不是冷场，是有人听懂了。")
		"赵无极":
			lines.append("没有证据的热血，只会烧到自己人。")
			lines.append("武林盟的旧卷，今晚不能再沉默。")
		"玄机子":
			lines.append("阵眼一动，七派都在局中。")
			lines.append("卦象不怕乱，只怕有人故意拨错。")
		"花如玉":
			lines.append("闻到甜香时，先闭气，再说话。")
			lines.append("花会骗人，旧疤不会。")
		"烈火":
			lines.append("暗影司敢伸手，就别怪火烧得太快。")
			lines.append("有些规矩烂了，就该烧干净。")
		"蛇王":
			lines.append("明处的刀容易躲，暗处的眼难防。")
			lines.append("水路来的脚印，和官道不一样。")
		"太极真人":
			lines.append("急进则露破绽，查案也如推手。")
			lines.append("越大的局，越要从轻处拨开。")
		"冰魄":
			lines.append("雪地不会说谎，脚印会。")
			lines.append("南边来的寒意，不是天上落的。")
		"逍遥子":
			lines.append("离局远一点，反而看得清谁在落子。")
			lines.append("酒盏放歪，是提醒你路也歪了。")
	var npc_type := str(npc_data.get("npc_type", "normal"))
	if npc_type == "enemy":
		lines.append("少侠若再近一步，就凭本事说话。")
	elif bool(npc_data.get("is_master", false)) or npc_type == "master":
		lines.append("%s%s，山门消息传得比风还快。" % [region, weather_hint])
	elif not quest.is_empty() and quest != "自由探索江湖":
		lines.append("近来都在传%s，少侠也听见了吧。" % quest)
	else:
		lines.append("%s%s，路上人声比昨日杂。" % [region, weather_hint])
	if relation == "好友" or relation == "知己" or relation == "挚友":
		lines.append("你来了，有些话便能说得更明白。")
	elif relation == "疏远" or relation == "敌视":
		lines.append("你我之间，还没到能交底的时候。")
	return lines

func _trim_ambient_line(line: String) -> String:
	line = line.replace("\n", " ").strip_edges()
	if line.length() <= 28:
		return line
	return "%s..." % line.substr(0, 28)

func _weather_hint() -> String:
	match GameState.weather:
		"细雨":
			return "正落着细雨"
		"薄雾":
			return "雾气压得很低"
		"飞雪":
			return "雪色遮住了远路"
		"多云":
			return "云影不散"
		_:
			return "天色尚明"

func _nearby_region_name() -> String:
	if not GameState.current_region_id.is_empty():
		var neighbors := GameData.get_neighbor_regions(GameState.current_region_id, 1)
		if not neighbors.is_empty():
			return str((neighbors[0] as Dictionary).get("name", "邻近山道"))
	return "邻近山道"

func _relation_line(npc_name: String) -> String:
	var memory: Dictionary = GameState.get_npc_memory(npc_name)
	var relation: String = GameState.get_npc_relation_label(npc_name)
	var talk_count := int(memory.get("talk_count", 0))
	if talk_count <= 1:
		return "%s还在掂量你是不是值得托付的人。" % npc_name
	if relation == "好友" or relation == "知己" or relation == "挚友":
		return "%s说话时少了几分试探，多了几分真意。" % npc_name
	if relation == "疏远" or relation == "敌视":
		return "%s记得你的冒犯，话里仍带着冷意。" % npc_name
	return "%s已经记住你来过，态度比初见时稳了一些。" % npc_name

func _recent_event_hint() -> String:
	var events: Array = GameState.get_recent_world_events(3)
	if events.is_empty():
		return ""
	var event: Dictionary = events[events.size() - 1]
	var title := str(event.get("title", ""))
	var description := str(event.get("description", ""))
	if title.is_empty():
		return description
	if description.is_empty():
		return title
	return "%s，%s" % [title, description]

func _npc_story_hook(npc_name: String, npc_data: Dictionary) -> String:
	match npc_name:
		"苏梦瑶":
			return "她指尖按住玉佩，提到苏家旧火时声音很轻，眼神却没有退。"
		"陈天行":
			return "他说书卷里少了一页，少的正是暗影司最怕别人看见的名字。"
		"赵无极":
			return "他提醒你证据比热血难得，武林盟的门槛下也埋着旧灰。"
		"玄机子":
			return "他把八卦盘转过半圈，说阵眼若动，七派谁都不能置身局外。"
		"花如玉":
			return "她笑意温柔，袖中香气却像毒针一样提醒你别信表象。"
		"烈火":
			return "他听见暗影司三字便冷笑，像要把旧账连同规矩一并烧掉。"
		"蛇王":
			return "他没有看你，只看屋檐阴影，说那里常有第二双眼睛。"
		"太极真人":
			return "他让你先收住急气，越大的局越要从最轻的一掌推开。"
		"冰魄":
			return "她说雪山已经听见南边的风，寒意不是从天上来的。"
		"逍遥子":
			return "他仍像在玩笑，却把酒盏推到地图边缘，点住一条暗路。"
	var personality := str(npc_data.get("personality", ""))
	if personality.contains("善") or personality.contains("温"):
		return "%s看你的神色温和了些，愿意多说半句。" % npc_name
	if personality.contains("冷") or personality.contains("阴"):
		return "%s把话藏得很深，只露出一点可追的线头。" % npc_name
	return ""

func _active_quest_title() -> String:
	if GameState.active_quests.is_empty():
		return GameState.active_quest
	for quest_id in GameState.active_quests.keys():
		var quest := GameData.get_quest(str(quest_id))
		return str(quest.get("title", quest_id))
	return GameState.active_quest

func _completed_quest_titles(max_count: int) -> Array[String]:
	var titles: Array[String] = []
	var start: int = max(0, GameState.completed_quests.size() - max_count)
	for index in range(start, GameState.completed_quests.size()):
		var quest_id := str(GameState.completed_quests[index])
		var quest := GameData.get_quest(quest_id)
		titles.append(str(quest.get("title", quest_id)))
	return titles

func _story_threads() -> Array[String]:
	var threads: Array[String] = []
	if GameState.completed_quests.has("q_hero_trial"):
		threads.append("平安镇试炼后，洛阳旧火线索开启。")
	if GameState.completed_quests.has("q_main_shadow_letters"):
		threads.append("暗影书信牵出七派暗号。")
	if GameState.completed_quests.has("q_main_shadow_watchers"):
		threads.append("暗影司眼线已经暴露，断令需要对证。")
	var event_summary: String = GameState.get_world_event_summary(3)
	if not event_summary.is_empty():
		threads.append("近期传闻：%s" % event_summary)
	if threads.is_empty():
		threads.append("玩家仍在平安镇周边建立名声。")
	return threads

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc_name := _pending_npc_name
	_request_busy = false
	_pending_npc_name = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		npc_line_failed.emit(npc_name, "响应异常：%d/%d" % [result, response_code])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		npc_line_failed.emit(npc_name, "响应不是 JSON")
		return
	var line := _extract_response_line(parsed)
	if line.is_empty():
		npc_line_failed.emit(npc_name, "响应没有台词")
		return
	npc_line_ready.emit(npc_name, line)

func _extract_response_line(parsed: Dictionary) -> String:
	var choices: Array = parsed.get("choices", [])
	if not choices.is_empty() and typeof(choices[0]) == TYPE_DICTIONARY:
		var first: Dictionary = choices[0]
		var message: Dictionary = first.get("message", {})
		var content := str(message.get("content", ""))
		if content.is_empty():
			content = str(first.get("text", ""))
		return _sanitize_line(content)
	return _sanitize_line(str(parsed.get("text", parsed.get("content", ""))))

func _sanitize_line(raw: String) -> String:
	var line := raw.strip_edges().replace("\r\n", "\n").replace("\r", "\n")
	if line.is_empty():
		return ""
	var kept: Array[String] = []
	for part in line.split("\n", false):
		var text := str(part).strip_edges()
		if text.is_empty():
			continue
		kept.append(text)
		if kept.size() >= 2:
			break
	return "\n".join(kept)
