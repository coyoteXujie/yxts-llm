extends Node

const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const BUS_AMBIENT := "Ambient"

const DEFAULT_BGM_VOLUME := 0.7
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_AMBIENT_VOLUME := 0.5
const DEFAULT_CROSSFADE := 2.0
const SFX_POOL_SIZE := 8
const FADE_FLOOR_DB := -60.0

const BGM_PATHS := {
	"main_menu": "res://assets/audio/bgm/main_menu.wav",
	"explore": "res://assets/audio/bgm/explore.wav",
	"combat": "res://assets/audio/bgm/combat.wav",
	"inn": "res://assets/audio/bgm/inn.wav",
}

const SFX_PATHS := {
	"ui_hover": "res://assets/audio/sfx/ui_hover.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.wav",
	"ui_cancel": "res://assets/audio/sfx/ui_cancel.wav",
	"typewriter": "res://assets/audio/sfx/typewriter.wav",
	"skill_unlock": "res://assets/audio/sfx/skill_unlock.wav",
	"hammer": "res://assets/audio/sfx/hammer.wav",
	"item_pickup": "res://assets/audio/sfx/item_pickup.wav",
	"item_drop": "res://assets/audio/sfx/item_drop.wav",
	"combat_hit": "res://assets/audio/sfx/combat_hit.wav",
	"combat_miss": "res://assets/audio/sfx/combat_miss.wav",
	"error": "res://assets/audio/sfx/error.wav",
}

const AMBIENT_PATHS := {
	"sunny": "res://assets/audio/ambient/sunny.wav",
	"cloudy": "res://assets/audio/ambient/cloudy.wav",
	"rain": "res://assets/audio/ambient/rain.wav",
	"storm": "res://assets/audio/ambient/storm.wav",
	"snow": "res://assets/audio/ambient/snow.wav",
	"fog": "res://assets/audio/ambient/fog.wav",
}

var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_tween: Tween
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor := 0
var _ambient_player: AudioStreamPlayer
var _ambient_tween: Tween
var _cached_streams: Dictionary = {}
var _bgm_volume := DEFAULT_BGM_VOLUME
var _sfx_volume := DEFAULT_SFX_VOLUME
var _ambient_volume := DEFAULT_AMBIENT_VOLUME
var _master_muted := false
var _current_bgm_key := ""
var _current_bgm_index := 0

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"

func _ready() -> void:
	_setup_buses()
	_setup_players()
	_load_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_master_muted = bool(cfg.get_value(SETTINGS_SECTION, "master_muted", false))
	_bgm_volume = clampf(float(cfg.get_value(SETTINGS_SECTION, "bgm_volume", DEFAULT_BGM_VOLUME)), 0.0, 1.0)
	_sfx_volume = clampf(float(cfg.get_value(SETTINGS_SECTION, "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	_ambient_volume = clampf(float(cfg.get_value(SETTINGS_SECTION, "ambient_volume", DEFAULT_AMBIENT_VOLUME)), 0.0, 1.0)
	var master_idx := AudioServer.get_bus_index(BUS_MASTER)
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, _master_muted)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_BGM), linear_to_db(_bgm_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), linear_to_db(_sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), linear_to_db(_ambient_volume))

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SETTINGS_SECTION, "master_muted", _master_muted)
	cfg.set_value(SETTINGS_SECTION, "bgm_volume", _bgm_volume)
	cfg.set_value(SETTINGS_SECTION, "sfx_volume", _sfx_volume)
	cfg.set_value(SETTINGS_SECTION, "ambient_volume", _ambient_volume)
	cfg.save(SETTINGS_PATH)

func _setup_buses() -> void:
	_ensure_bus(BUS_BGM, BUS_MASTER)
	_ensure_bus(BUS_SFX, BUS_MASTER)
	_ensure_bus(BUS_AMBIENT, BUS_MASTER)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_BGM), linear_to_db(_bgm_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), linear_to_db(_sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), linear_to_db(_ambient_volume))

func _ensure_bus(bus_name: String, send_to: String) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), send_to)

func _setup_players() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_BGM
		add_child(player)
		_bgm_players.append(player)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

func play_bgm(key: String, fade: float = DEFAULT_CROSSFADE) -> void:
	if key == _current_bgm_key and _bgm_players[_current_bgm_index].playing:
		return
	var stream := _load_stream(BGM_PATHS.get(key, ""))
	if stream == null:
		return
	var next_index := 1 - _current_bgm_index
	var next_player := _bgm_players[next_index]
	var prev_player := _bgm_players[_current_bgm_index]
	next_player.stream = stream
	next_player.volume_db = FADE_FLOOR_DB
	next_player.play()
	if _bgm_tween != null:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	_bgm_tween.tween_property(next_player, "volume_db", 0.0, fade)
	if prev_player.playing:
		_bgm_tween.tween_property(prev_player, "volume_db", FADE_FLOOR_DB, fade)
	_bgm_tween.chain().tween_callback(prev_player.stop)
	_current_bgm_index = next_index
	_current_bgm_key = key

func stop_bgm(fade: float = DEFAULT_CROSSFADE) -> void:
	var player := _bgm_players[_current_bgm_index]
	if not player.playing:
		_current_bgm_key = ""
		return
	if _bgm_tween != null:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(player, "volume_db", FADE_FLOOR_DB, fade)
	_bgm_tween.tween_callback(player.stop)
	_bgm_tween.tween_callback(func() -> void: _current_bgm_key = "")

func play_sfx(key: String) -> void:
	var stream := _load_stream(SFX_PATHS.get(key, ""))
	if stream == null:
		return
	var player := _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	player.play()

func play_ambient(key: String, fade: float = 1.0) -> void:
	var stream := _load_stream(AMBIENT_PATHS.get(key, ""))
	if stream == null:
		stop_ambient(fade)
		return
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
	_ambient_player.stream = stream
	_ambient_player.volume_db = FADE_FLOOR_DB
	_ambient_player.play()
	if _ambient_tween != null:
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", 0.0, fade)

func stop_ambient(fade: float = 1.0) -> void:
	if not _ambient_player.playing:
		return
	if _ambient_tween != null:
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", FADE_FLOOR_DB, fade)
	_ambient_tween.tween_callback(_ambient_player.stop)

func _load_stream(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if _cached_streams.has(path):
		return _cached_streams[path]
	var stream := load(path)
	if stream is AudioStream:
		_cached_streams[path] = stream
		return stream
	return null

func set_master_muted(muted: bool) -> void:
	_master_muted = muted
	var idx := AudioServer.get_bus_index(BUS_MASTER)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)
	_save_settings()

func is_master_muted() -> bool:
	return _master_muted

func get_bgm_volume() -> float:
	return _bgm_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func get_ambient_volume() -> float:
	return _ambient_volume

func toggle_master_muted() -> bool:
	set_master_muted(not _master_muted)
	return _master_muted

func set_bgm_volume(vol: float) -> void:
	_bgm_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_BGM)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_bgm_volume))
	_save_settings()

func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_SFX)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_sfx_volume))
	_save_settings()

func set_ambient_volume(vol: float) -> void:
	_ambient_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_AMBIENT)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_ambient_volume))
	_save_settings()

func has_bgm(key: String) -> bool:
	return ResourceLoader.exists(BGM_PATHS.get(key, ""))

func has_sfx(key: String) -> bool:
	return ResourceLoader.exists(SFX_PATHS.get(key, ""))

func has_ambient(key: String) -> bool:
	return ResourceLoader.exists(AMBIENT_PATHS.get(key, ""))
