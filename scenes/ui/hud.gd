extends Control

@onready var player_name_label: Label = $TopLeft/PlayerInfo/VBox/NameLabel
@onready var level_label: Label = $TopLeft/PlayerInfo/VBox/LevelLabel
@onready var hp_bar: ProgressBar = $TopLeft/HPBar
@onready var hp_label: Label = $TopLeft/HPLabel
@onready var mp_bar: ProgressBar = $TopLeft/MPBar
@onready var mp_label: Label = $TopLeft/MPLabel
@onready var gold_label: Label = $TopLeft/GoldLabel
@onready var location_label: Label = $LocationLabel
@onready var time_label: Label = $TimeLabel

func _ready() -> void:
	_connect_signals()
	_update_ui()

func _connect_signals() -> void:
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_mp_changed.connect(_on_mp_changed)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.time_changed.connect(_on_time_changed)

func _process(delta: float) -> void:
	_update_time_display()

func _update_ui() -> void:
	var player_data := DataRegistry.get_player_data()
	if player_data:
		player_name_label.text = player_data.player_name
		level_label.text = "等级 %d" % player_data.level
		_update_hp_display(player_data.current_hp, player_data.max_hp)
		_update_mp_display(player_data.current_mp, player_data.max_mp)
		gold_label.text = "银两: %d" % player_data.gold

func _update_hp_display(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "生命: %d/%d" % [current, maximum]

func _update_mp_display(current: int, maximum: int) -> void:
	mp_bar.max_value = maximum
	mp_bar.value = current
	mp_label.text = "内力: %d/%d" % [current, maximum]

func _update_time_display() -> void:
	if AtmosphereSystem:
		var time_name := AtmosphereSystem.get_time_name()
		var weather_name := AtmosphereSystem.get_weather_name()
		time_label.text = "%s | %s" % [time_name, weather_name]

func _on_hp_changed(current: int, max_hp: int) -> void:
	_update_hp_display(current, max_hp)

func _on_mp_changed(current: int, max_mp: int) -> void:
	_update_mp_display(current, max_mp)

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "银两: %d" % amount

func _on_level_up(new_level: int) -> void:
	level_label.text = "等级 %d" % new_level

func _on_zone_entered(zone_id: String) -> void:
	location_label.text = zone_id

func _on_weather_changed(weather: int) -> void:
	_update_time_display()

func _on_time_changed(time: int) -> void:
	_update_time_display()
