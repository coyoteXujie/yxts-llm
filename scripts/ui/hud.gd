extends Control
class_name MainHUD
## UI层 - HUD界面

@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: ProgressBar = $MPBar
@onready var gold_label: Label = $GoldLabel
@onready var level_label: Label = $LevelLabel
@onready var quest_tracker: VBoxContainer = $QuestTracker

func _ready() -> void:
	_connect_events()
	_update_all()

func _connect_events() -> void:
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_mp_changed.connect(_on_mp_changed)
	EventBus.player_gold_changed.connect(_on_gold_changed)

func _update_all() -> void:
	var data: PlayerData = DataRegistry.get_player_data()
	if data:
		hp_bar.max_value = data.max_hp
		hp_bar.value = data.current_hp
		mp_bar.max_value = data.max_mp
		mp_bar.value = data.current_mp
		gold_label.text = str(data.gold)
		level_label.text = "Lv. %d" % data.level

func _on_hp_changed(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current

func _on_mp_changed(current: int, max_mp: int) -> void:
	mp_bar.max_value = max_mp
	mp_bar.value = current

func _on_gold_changed(amount: int) -> void:
	var data: PlayerData = DataRegistry.get_player_data()
	if data:
		gold_label.text = str(data.gold)
