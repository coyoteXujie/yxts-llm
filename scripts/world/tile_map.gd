extends TileMap
class_name GameTileMap

# 地形类型枚举
enum TerrainType {
    GRASS = 0,      # 草地
    WATER = 1,      # 水域
    ROAD = 2,       # 道路
    BUILDING = 3,   # 建筑物
    TREE = 4,       # 树木
    MOUNTAIN = 5,   # 山地
    SAND = 6,       # 沙地
    BRIDGE = 7,     # 桥梁
    WALL = 8,       # 墙壁
    FLOOR = 9       # 室内地板
}

# 可行走地形类型集合
const WALKABLE_TERRAINS := {
    TerrainType.GRASS,
    TerrainType.ROAD,
    TerrainType.BRIDGE,
    TerrainType.SAND,
    TerrainType.FLOOR
}

# 碰撞层定义
enum CollisionLayer {
    TERRAIN = 1,        # 地形碰撞层
    BUILDING = 2,       # 建筑物碰撞层
    OBJECT = 4,         # 物体碰撞层
    TRIGGER = 8         # 触发器碰撞层
}

# 瓦片集引用
@export var tile_set: TileSet = null
# 网格大小配置
@export var grid_size: Vector2i = Vector2i(32, 32)
# 地图尺寸（以瓦片为单位）
@export var map_size: Vector2i = Vector2i(100, 100)

# 内部状态
var current_terrain_data: Dictionary = {}
var current_zone: Zone = null

func _ready() -> void:
    _setup_tile_set()
    _generate_default_terrain()

func _setup_tile_set() -> void:
    if tile_set == null:
        tile_set = TileSet.new()
        _create_default_tileset()

func _create_default_tileset() -> void:
    var terrain_physics := PhysicsMaterial.new()
    terrain_physics.friction = 1.0
    terrain_physics.bounce = 0.0
    
    for terrain_type in TerrainType.values():
        var tile_name := TerrainType.keys()[terrain_type]
        print("创建地形瓦片: " + tile_name)

func _generate_default_terrain() -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var terrain: TerrainType
            if y < 5 or y > map_size.y - 5:
                terrain = TerrainType.WATER
            elif x == map_size.x / 2:
                terrain = TerrainType.ROAD
            else:
                terrain = TerrainType.GRASS
            current_terrain_data[Vector2i(x, y)] = terrain

# 根据世界坐标获取指定位置的瓦片数据
func get_tile_at(world_x: int, world_y: int) -> Variant:
    var tile_pos := local_to_map(Vector2i(world_x, world_y))
    return get_tile_tile_data(tile_pos)

func get_tile_tile_data(tile_pos: Vector2i) -> Variant:
    if current_terrain_data.has(tile_pos):
        return current_terrain_data[tile_pos]
    return null

# 判断指定位置是否可行走
func is_walkable(world_x: int, world_y: int) -> bool:
    var tile_pos := local_to_map(Vector2i(world_x, world_y))
    return is_tile_walkable(tile_pos)

func is_tile_walkable(tile_pos: Vector2i) -> bool:
    if not current_terrain_data.has(tile_pos):
        return false
    
    var terrain: TerrainType = current_terrain_data[tile_pos]
    return terrain in WALKABLE_TERRAINS

# 获取所有可行走的瓦片位置列表
func get_walkable_tiles() -> Array[Vector2i]:
    var walkable: Array[Vector2i] = []
    for tile_pos in current_terrain_data.keys():
        if is_tile_walkable(tile_pos):
            walkable.append(tile_pos)
    return walkable

# 设置指定位置的瓦片
func set_tile(world_x: int, world_y: int, terrain_type: TerrainType) -> void:
    var tile_pos := local_to_map(Vector2i(world_x, world_y))
    set_tile_at_position(tile_pos, terrain_type)

func set_tile_at_position(tile_pos: Vector2i, terrain_type: TerrainType) -> void:
    current_terrain_data[tile_pos] = terrain_type
    _update_tile_visual(tile_pos, terrain_type)

func _update_tile_visual(tile_pos: Vector2i, terrain_type: TerrainType) -> void:
    print("更新瓦片视觉: 位置 " + str(tile_pos) + " -> " + TerrainType.keys()[terrain_type])

# 获取指定范围内的所有瓦片
func get_tiles_in_area(start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
    var tiles: Array[Vector2i] = []
    var min_x := mini(start_pos.x, end_pos.x)
    var max_x := maxi(start_pos.x, end_pos.x)
    var min_y := mini(start_pos.y, end_pos.y)
    var max_y := maxi(start_pos.y, end_pos.y)
    
    for x in range(min_x, max_x + 1):
        for y in range(min_y, max_y + 1):
            tiles.append(Vector2i(x, y))
    return tiles

# 计算路径（简单版本）
func calculate_path(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var current: Vector2i = from_pos
    
    while current != to_pos:
        var dx := signi(to_pos.x - current.x)
        var dy := signi(to_pos.y - current.y)
        
        var next_pos := current + Vector2i(dx, dy)
        
        if is_tile_walkable(next_pos):
            current = next_pos
            path.append(current)
        else:
            var alt_x := current + Vector2i(dx, 0)
            var alt_y := current + Vector2i(0, dy)
            
            if is_tile_walkable(alt_x):
                current = alt_x
                path.append(current)
            elif is_tile_walkable(alt_y):
                current = alt_y
                path.append(current)
            else:
                break
    
    return path

# 获取地形类型名称
func get_terrain_name(terrain_type: TerrainType) -> String:
    if terrain_type in TerrainType.values():
        return TerrainType.keys()[terrain_type]
    return "UNKNOWN"

# 检查位置是否在地图范围内
func is_in_map_bounds(tile_pos: Vector2i) -> bool:
    return tile_pos.x >= 0 and tile_pos.x < map_size.x and tile_pos.y >= 0 and tile_pos.y < map_size.y

# 清除所有瓦片
func clear_all_tiles() -> void:
    current_terrain_data.clear()
    clear()

# 加载区域时初始化瓦片地图
func _on_zone_loaded(zone: Zone) -> void:
    current_zone = zone
    print("加载区域瓦片: " + zone.name)
    _generate_zone_terrain(zone)

func _generate_zone_terrain(zone: Zone) -> void:
    match zone.type:
        Constants.ZoneType.TOWN:
            _generate_town_terrain()
        Constants.ZoneType.CITY:
            _generate_city_terrain()
        Constants.ZoneType.WILDERNESS:
            _generate_wilderness_terrain()
        Constants.ZoneType.DUNGEON:
            _generate_dungeon_terrain()

func _generate_town_terrain() -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var terrain: TerrainType
            if x < 10 or x > map_size.x - 10:
                terrain = TerrainType.ROAD
            elif y < 10 or y > map_size.y - 10:
                terrain = TerrainType.ROAD
            else:
                terrain = TerrainType.GRASS
            current_terrain_data[Vector2i(x, y)] = terrain

func _generate_city_terrain() -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var terrain: TerrainType
            if (x % 15 < 3) or (y % 15 < 3):
                terrain = TerrainType.ROAD
            else:
                terrain = TerrainType.BUILDING
            current_terrain_data[Vector2i(x, y)] = terrain

func _generate_wilderness_terrain() -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var terrain: TerrainType
            var noise := randf()
            if noise < 0.1:
                terrain = TerrainType.WATER
            elif noise < 0.2:
                terrain = TerrainType.TREE
            elif noise < 0.3:
                terrain = TerrainType.MOUNTAIN
            else:
                terrain = TerrainType.GRASS
            current_terrain_data[Vector2i(x, y)] = terrain

func _generate_dungeon_terrain() -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var terrain: TerrainType
            if x == 0 or x == map_size.x - 1 or y == 0 or y == map_size.y - 1:
                terrain = TerrainType.WALL
            elif (x % 10 == 0) and (y % 10 == 0):
                terrain = TerrainType.WALL
            else:
                terrain = TerrainType.FLOOR
            current_terrain_data[Vector2i(x, y)] = terrain

# 保存瓦片数据
func save_tile_data() -> Dictionary:
    var save_data: Dictionary = {
        "terrain_data": {},
        "map_size": {
            "x": map_size.x,
            "y": map_size.y
        }
    }
    
    for pos in current_terrain_data.keys():
        var key := str(pos.x) + "," + str(pos.y)
        save_data["terrain_data"][key] = current_terrain_data[pos]
    
    return save_data

# 加载瓦片数据
func load_tile_data(save_data: Dictionary) -> void:
    current_terrain_data.clear()
    
    if save_data.has("map_size"):
        map_size = Vector2i(save_data["map_size"]["x"], save_data["map_size"]["y"])
    
    if save_data.has("terrain_data"):
        for key in save_data["terrain_data"]:
            var parts := key.split(",")
            var pos := Vector2i(int(parts[0]), int(parts[1]))
            var terrain: TerrainType = save_data["terrain_data"][key]
            current_terrain_data[pos] = terrain
