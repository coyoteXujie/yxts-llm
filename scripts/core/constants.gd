extends Node
## 全局常量定义 - 游戏所有枚举和常量值

# ==================== 物品稀有度 ====================
enum ItemRarity {
	COMMON = 0,
	UNCOMMON = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4,
	MYTHIC = 5
}

func get_rarity_name(rarity: int) -> String:
	match rarity:
		ItemRarity.COMMON: return "普通"
		ItemRarity.UNCOMMON: return "优秀"
		ItemRarity.RARE: return "稀有"
		ItemRarity.EPIC: return "史诗"
		ItemRarity.LEGENDARY: return "传说"
		ItemRarity.MYTHIC: return "神话"
	return "未知"

func get_rarity_color(rarity: int) -> Color:
	match rarity:
		ItemRarity.COMMON: return Color(0.6, 0.6, 0.6)
		ItemRarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
		ItemRarity.RARE: return Color(0.2, 0.4, 1.0)
		ItemRarity.EPIC: return Color(0.6, 0.2, 0.8)
		ItemRarity.LEGENDARY: return Color(1.0, 0.6, 0.0)
		ItemRarity.MYTHIC: return Color(1.0, 0.2, 0.2)
	return Color.WHITE

# ==================== 派系 ====================
enum Faction {
	NONE = 0,
	BAGUA = 1,
	FLOWER = 2,
	HONGLIAN = 3,
	NAJA = 4,
	TAIJI = 5,
	XUESHAN = 6
}

func get_faction_name(faction: int) -> String:
	match faction:
		Faction.NONE: return "无门无派"
		Faction.BAGUA: return "八卦门"
		Faction.FLOWER: return "花间派"
		Faction.HONGLIAN: return "红莲教"
		Faction.NAJA: return "那迦派"
		Faction.TAIJI: return "太极门"
		Faction.XUESHAN: return "雪山派"
	return "未知"

func get_faction_color(faction: int) -> Color:
	match faction:
		Faction.NONE: return Color.WHITE
		Faction.BAGUA: return Color(0.8, 0.6, 0.4)
		Faction.FLOWER: return Color(1.0, 0.5, 0.7)
		Faction.HONGLIAN: return Color(0.9, 0.2, 0.2)
		Faction.NAJA: return Color(0.3, 0.8, 0.3)
		Faction.TAIJI: return Color(1.0, 1.0, 1.0)
		Faction.XUESHAN: return Color(0.8, 0.9, 1.0)
	return Color.WHITE

# ==================== 区域类型 ====================
enum ZoneType {
	CITY = 0,
	TOWN = 1,
	WILDERNESS = 2,
	DUNGEON = 3
}

# ==================== 天气 ====================
enum Weather {
	SUNNY = 0,
	CLOUDY = 1,
	RAIN = 2,
	STORM = 3,
	SNOW = 4,
	FOG = 5
}

func get_weather_name(weather: int) -> String:
	match weather:
		Weather.SUNNY: return "晴朗"
		Weather.CLOUDY: return "多云"
		Weather.RAIN: return "下雨"
		Weather.STORM: return "暴风雨"
		Weather.SNOW: return "大雪"
		Weather.FOG: return "大雾"
	return "未知"

# ==================== 昼夜 ====================
enum TimeOfDay {
	DAWN = 0,
	MORNING = 1,
	NOON = 2,
	AFTERNOON = 3,
	EVENING = 4,
	NIGHT = 5
}

func get_time_name(time: int) -> String:
	match time:
		TimeOfDay.DAWN: return "黎明"
		TimeOfDay.MORNING: return "早晨"
		TimeOfDay.NOON: return "正午"
		TimeOfDay.AFTERNOON: return "下午"
		TimeOfDay.EVENING: return "黄昏"
		TimeOfDay.NIGHT: return "夜晚"
	return "未知"

# ==================== 游戏状态 ====================
enum GameState {
	MENU = 0,
	CHARACTER_CREATION = 1,
	PLAYING = 2,
	PAUSED = 3,
	COMBAT = 4,
	DIALOGUE = 5,
	INVENTORY = 6,
	SKILLS = 7,
	MAP = 8,
	CUTSCENE = 9
}

# ==================== 实体类型 ====================
enum EntityType {
	PLAYER = 0,
	NPC = 1,
	ENEMY = 2,
	OBJECT = 3
}

# ==================== NPC类型 ====================
enum NpcType {
	NORMAL = 0,
	TRADER = 1,
	QUEST_GIVER = 2,
	MASTER = 3,
	GUARD = 4,
	HOSTILE = 5
}

# ==================== 伤害类型 ====================
enum DamageType {
	PHYSICAL = 0,
	MAGICAL = 1,
	POISON = 2,
	FIRE = 3,
	ICE = 4
}

# ==================== 技能类型 ====================
enum SkillType {
	ATTACK = 0,
	HEAL = 1,
	BUFF = 2,
	DEBUFF = 3,
	UTILITY = 4
}

enum SkillTarget {
	SELF = 0,
	SINGLE = 1,
	ALL_ALLIES = 2,
	ALL_ENEMIES = 3,
	AREA = 4
}

# ==================== 物品类型 ====================
enum ItemType {
	WEAPON = 0,
	ARMOR = 1,
	ACCESSORY = 2,
	CONSUMABLE = 3,
	MATERIAL = 4,
	QUEST = 5
}

enum EquipmentSlot {
	HEAD = 0,
	BODY = 1,
	HANDS = 2,
	LEGS = 3,
	FEET = 4,
	ACCESSORY = 5,
	WEAPON = 6,
	SHIELD = 7
}

# ==================== 任务 ====================
enum QuestState {
	NOT_AVAILABLE = 0,
	AVAILABLE = 1,
	IN_PROGRESS = 2,
	COMPLETED = 3,
	FAILED = 4
}

enum QuestObjectiveType {
	KILL = 0,
	COLLECT = 1,
	TALK = 2,
	DELIVER = 3,
	VISIT = 4
}

# ==================== 对话类型 ====================
enum DialogueType {
	NARRATION = 0,
	DIALOGUE = 1,
	CHOICE = 2,
	COMBAT = 3,
	END = 4
}

# ==================== 战斗状态 ====================
enum CombatState {
	INACTIVE = 0,
	PLAYER_TURN = 1,
	ENEMY_TURN = 2,
	VICTORY = 3,
	DEFEAT = 4
}

# ==================== UI颜色 ====================
const UI_COLOR_BACKGROUND: Color = Color(0.1, 0.1, 0.18, 1)
const UI_COLOR_PANEL: Color = Color(0.14, 0.14, 0.24, 0.95)
const UI_COLOR_GOLD: Color = Color(0.79, 0.66, 0.43)
const UI_COLOR_GOLD_BRIGHT: Color = Color(0.94, 0.75, 0.25)
const UI_COLOR_TEXT: Color = Color(0.9, 0.85, 0.75)
const UI_COLOR_TEXT_DIM: Color = Color(0.6, 0.55, 0.5)
const UI_COLOR_RED: Color = Color(0.75, 0.22, 0.17)
const UI_COLOR_GREEN: Color = Color(0.18, 0.8, 0.44)
const UI_COLOR_BLUE: Color = Color(0.13, 0.59, 0.95)

# ==================== 游戏数值 ====================
const PLAYER_MOVE_SPEED: float = 200.0
const PLAYER_RUN_SPEED: float = 350.0
const BASE_ENEMY_AGGRO_RANGE: float = 250.0
const PLAYER_MAX_HP: int = 100
const PLAYER_MAX_MP: int = 50
const PLAYER_BASE_ATTACK: int = 10
const PLAYER_BASE_DEFENSE: int = 5

# ==================== 路径 ====================
const DATA_PATH: String = "res://data/"
const SAVE_PATH: String = "user://saves/"
const ASSET_PATH: String = "res://resources/"

# ==================== 存档 ====================
const MAX_SAVE_SLOTS: int = 10
const SAVE_VERSION: String = "1.0.0"
