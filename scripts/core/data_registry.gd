extends Node
## 核心框架层 - 数据注册表
## 负责加载和缓存游戏数据，所有数据只读

var _player_data: PlayerData
var _npc_data_cache: Dictionary = {}
var _skill_data_cache: Dictionary = {}
var _item_data_cache: Dictionary = {}
var _quest_data_cache: Dictionary = {}
var _dialogue_cache: Dictionary = {}

func _ready() -> void:
	_load_default_player_data()

func get_player_data() -> PlayerData:
	return _player_data

func set_player_data(data: PlayerData) -> void:
	_player_data = data

func get_npc_data(npc_id: String) -> NpcData:
	if _npc_data_cache.has(npc_id):
		return _npc_data_cache[npc_id]
	return _load_npc_data(npc_id)

func get_skill_data(skill_id: String) -> SkillData:
	if _skill_data_cache.has(skill_id):
		return _skill_data_cache[skill_id]
	return _load_skill_data(skill_id)

func get_item_data(item_id: String) -> ItemData:
	if _item_data_cache.has(item_id):
		return _item_data_cache[item_id]
	return _load_item_data(item_id)

func get_quest_data(quest_id: String) -> QuestData:
	if _quest_data_cache.has(quest_id):
		return _quest_data_cache[quest_id]
	return _load_quest_data(quest_id)

func get_dialogue_tree(npc_id: String) -> Array[DialogueNodeData]:
	if _dialogue_cache.has(npc_id):
		return _dialogue_cache[npc_id]
	return _load_dialogue_tree(npc_id)

func cache_npc_data(data: NpcData) -> void:
	_npc_data_cache[data.npc_id] = data

func cache_skill_data(data: SkillData) -> void:
	_skill_data_cache[data.skill_id] = data

func cache_item_data(data: ItemData) -> void:
	_item_data_cache[data.item_id] = data

func cache_quest_data(data: QuestData) -> void:
	_quest_data_cache[data.quest_id] = data

func cache_dialogue_tree(npc_id: String, tree: Array[DialogueNodeData]) -> void:
	_dialogue_cache[npc_id] = tree

func _load_default_player_data() -> void:
	_player_data = PlayerData.new()
	_player_data.player_name = "无名侠客"
	_player_data.level = 1
	_player_data.exp = 0
	_player_data.exp_to_next = 100
	_player_data.gold = 100
	_player_data.max_hp = 100
	_player_data.current_hp = 100
	_player_data.max_mp = 50
	_player_data.current_mp = 50
	_player_data.strength = 10
	_player_data.dexterity = 10
	_player_data.intelligence = 10
	_player_data.constitution = 10
	_player_data.faction = Constants.Faction.NONE
	_player_data.faction_rank = 0

func _load_npc_data(npc_id: String) -> NpcData:
	var data: NpcData = NpcData.new()
	data.npc_id = npc_id
	data.entity_name = npc_id
	_npc_data_cache[npc_id] = data
	return data

func _load_skill_data(skill_id: String) -> SkillData:
	var data: SkillData = SkillData.new()
	data.skill_id = skill_id
	data.name = skill_id
	_skill_data_cache[skill_id] = data
	return data

func _load_item_data(item_id: String) -> ItemData:
	var data: ItemData = ItemData.new()
	data.item_id = item_id
	data.name = item_id
	_item_data_cache[item_id] = data
	return data

func _load_quest_data(quest_id: String) -> QuestData:
	var data: QuestData = QuestData.new()
	data.quest_id = quest_id
	data.title = quest_id
	_quest_data_cache[quest_id] = data
	return data

func _load_dialogue_tree(npc_id: String) -> Array[DialogueNodeData]:
	return []
