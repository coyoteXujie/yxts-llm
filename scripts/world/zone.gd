extends Node2D
class_name Zone

# 区域唯一标识符
var id: String = ""
# 区域显示名称
var name: String = ""
# 区域详细描述
var description: String = ""
# 区域类型
var type: int = Constants.ZoneType.TOWN

# 区域内的NPC列表
var npcs: Array[Node] = []
# 区域内的敌人列表
var enemies: Array[Node] = []
# 建筑物和兴趣点列表
var buildings: Array[Dictionary] = []
# 通往其他区域的连接
var connections: Array[String] = []

# 背景音乐
var background_music: String = ""
var current_music_stream: AudioStreamPlayer = null
# 环境音效
var ambient_sounds: Array[Dictionary] = []
var ambient_stream: AudioStreamPlayer = null

# 区域状态
var is_loaded: bool = false
var is_visible: bool = true
var difficulty_level: int = 1

# 信号定义
signal npc_added(npc: Node)
signal npc_removed(npc: Node)
signal enemy_spawned(enemy: Node)
signal enemy_defeated(enemy: Node)
signal zone_cleared()
signal building_entered(building: Dictionary)
signal zone_loaded(zone: Zone)

func _ready() -> void:
    _setup_audio_players()

func _setup_audio_players() -> void:
    current_music_stream = AudioStreamPlayer.new()
    current_music_stream.bus = "Music"
    add_child(current_music_stream)
    
    ambient_stream = AudioStreamPlayer.new()
    ambient_stream.bus = "SFX"
    add_child(ambient_stream)

# 添加NPC到区域
func add_npc(npc: Node) -> void:
    if not npcs.has(npc):
        npcs.append(npc)
        npc_added.emit(npc)
        print("NPC进入区域: " + npc.name)
    else:
        push_warning("NPC已在区域内: " + str(npc))

# 从区域移除NPC
func remove_npc(npc: Node) -> bool:
    var index := npcs.find(npc)
    if index != -1:
        npcs.remove_at(index)
        npc_removed.emit(npc)
        print("NPC离开区域: " + npc.name)
        return true
    return false

# 获取区域内所有NPC
func get_npcs() -> Array[Node]:
    return npcs.duplicate()

# 按类型获取NPC
func get_npcs_by_type(npc_type: String) -> Array[Node]:
    var filtered: Array[Node] = []
    for npc in npcs:
        if npc.get("npc_type") == npc_type:
            filtered.append(npc)
    return filtered

# 生成敌人
func spawn_enemies(enemy_count: int = 5) -> void:
    for i in enemy_count:
        var enemy := _create_random_enemy()
        enemies.append(enemy)
        enemy_spawned.emit(enemy)
        print("生成敌人: " + enemy.name)
    
    print("区域生成 %d 个敌人" % enemy_count)

func _create_random_enemy() -> Node2D:
    var enemy := Node2D.new()
    enemy.name = "Enemy_" + str(randi())
    return enemy

# 移除敌人
func remove_enemy(enemy: Node) -> bool:
    var index := enemies.find(enemy)
    if index != -1:
        enemies.remove_at(index)
        enemy_defeated.emit(enemy)
        return true
    return false

# 获取所有敌人
func get_enemies() -> Array[Node]:
    return enemies.duplicate()

# 区域是否已清空
func is_cleared() -> bool:
    return enemies.is_empty()

# 添加建筑物/兴趣点
func add_building(building_data: Dictionary) -> void:
    if not building_data.has("id"):
        building_data["id"] = "building_" + str(buildings.size())
    buildings.append(building_data)
    print("添加建筑物: " + building_data.get("name", "未命名"))

# 移除建筑物
func remove_building(building_id: String) -> bool:
    for i in buildings.size():
        if buildings[i].get("id") == building_id:
            buildings.remove_at(i)
            return true
    return false

# 获取建筑物
func get_building(building_id: String) -> Dictionary:
    for building in buildings:
        if building.get("id") == building_id:
            return building
    return {}

# 获取所有建筑物
func get_buildings() -> Array[Dictionary]:
    return buildings.duplicate()

# 进入建筑物
func enter_building(building_id: String) -> bool:
    var building := get_building(building_id)
    if not building.is_empty():
        building_entered.emit(building)
        print("进入建筑物: " + building.get("name", "未知"))
        return true
    return false

# 添加区域连接
func add_connection(zone_id: String) -> void:
    if not connections.has(zone_id):
        connections.append(zone_id)
        print("添加区域连接: " + zone_id)

# 移除区域连接
func remove_connection(zone_id: String) -> bool:
    var index := connections.find(zone_id)
    if index != -1:
        connections.remove_at(index)
        return true
    return false

# 是否连接到指定区域
func is_connected_to(zone_id: String) -> bool:
    return connections.has(zone_id)

# 设置背景音乐
func set_background_music(music_path: String) -> void:
    background_music = music_path
    if is_loaded:
        _load_and_play_music()

# 设置环境音效
func add_ambient_sound(sound_data: Dictionary) -> void:
    ambient_sounds.append(sound_data)
    if is_loaded:
        _play_ambient_sounds()

# 播放背景音乐
func play_music() -> void:
    if current_music_stream and not background_music.is_empty():
        _load_and_play_music()
        current_music_stream.play()

# 停止背景音乐
func stop_music() -> void:
    if current_music_stream:
        current_music_stream.stop()

# 播放环境音效
func play_ambient_sounds() -> void:
    _play_ambient_sounds()

# 停止环境音效
func stop_ambient_sounds() -> void:
    if ambient_stream:
        ambient_stream.stop()

func _load_and_play_music() -> void:
    if not background_music.is_empty():
        print("加载背景音乐: " + background_music)

func _play_ambient_sounds() -> void:
    for sound_data in ambient_sounds:
        print("播放环境音效: " + sound_data.get("name", "未知"))

# 加载区域
func load_zone() -> void:
    is_loaded = true
    _initialize_npcs()
    _initialize_enemies()
    _initialize_buildings()
    play_music()
    play_ambient_sounds()
    zone_loaded.emit(self)
    print("加载区域: " + name)

func _initialize_npcs() -> void:
    print("初始化区域内NPC...")

func _initialize_enemies() -> void:
    if type == Constants.ZoneType.DUNGEON or type == Constants.ZoneType.WILDERNESS:
        spawn_enemies(difficulty_level * 3)

func _initialize_buildings() -> void:
    print("初始化区域建筑物...")

# 清空区域
func clear() -> void:
    for npc in npcs:
        remove_npc(npc)
    
    for enemy in enemies:
        remove_enemy(enemy)
    
    buildings.clear()
    
    stop_music()
    stop_ambient_sounds()
    
    is_loaded = false
    zone_cleared.emit()
    print("清空区域: " + name)

# 获取区域状态摘要
func get_zone_summary() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "type": Constants.ZoneType.keys()[type],
        "npc_count": npcs.size(),
        "enemy_count": enemies.size(),
        "building_count": buildings.size(),
        "connections": connections.duplicate(),
        "is_cleared": is_cleared(),
        "difficulty": difficulty_level
    }

# 设置区域难度
func set_difficulty(level: int) -> void:
    difficulty_level = maxi(1, level)
    print("区域难度设置为: " + str(difficulty_level))

# 获取区域信息字符串
func get_info_text() -> String:
    var info := "【%s】\n" % name
    info += "%s\n\n" % description
    info += "类型: %s\n" % Constants.ZoneType.keys()[type]
    info += "NPC数量: %d\n" % npcs.size()
    info += "敌人数量: %d\n" % enemies.size()
    info += "建筑物数量: %d\n" % buildings.size()
    info += "连接区域: %s\n" % ", ".join(connections)
    return info

# 检查是否有敌人在附近
func has_nearby_enemies(position: Vector2, range: float = 100.0) -> bool:
    for enemy in enemies:
        if enemy is Node2D:
            var distance := enemy.global_position.distance_to(position)
            if distance <= range:
                return true
    return false

func get_enemies_in_range(position: Vector2, range: float = 100.0) -> Array[Node]:
    var enemies_in_range: Array[Node] = []
    for enemy in enemies:
        if enemy is Node2D:
            var distance := enemy.global_position.distance_to(position)
            if distance <= range:
                enemies_in_range.append(enemy)
    return enemies_in_range

# 保存区域状态
func save_zone_state() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "type": type,
        "description": description,
        "difficulty_level": difficulty_level,
        "is_loaded": is_loaded,
        "npc_count": npcs.size(),
        "enemy_count": enemies.size(),
        "buildings": buildings.duplicate(),
        "connections": connections.duplicate()
    }

# 从保存数据加载区域状态
func load_zone_state(state: Dictionary) -> void:
    if state.has("id"):
        id = state["id"]
    if state.has("name"):
        name = state["name"]
    if state.has("type"):
        type = state["type"]
    if state.has("description"):
        description = state["description"]
    if state.has("difficulty_level"):
        difficulty_level = state["difficulty_level"]
    if state.has("buildings"):
        buildings = state["buildings"]
    if state.has("connections"):
        connections = state["connections"]
    
    print("加载区域状态: " + name)
