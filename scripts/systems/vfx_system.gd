extends Node
## 视觉效果系统 - 粒子、特效、屏幕效果

signal effect_started(effect_id: String)
signal effect_ended(effect_id: String)

var _active_effects: Dictionary = {}
var _screen_shake: Vector2 = Vector2.ZERO
var _screen_flash: Color = Color.TRANSPARENT
var _screen_flash_duration: float = 0.0
var _screen_flash_timer: float = 0.0

var _bloom_enabled: bool = true
var _vignette_enabled: bool = true
var _contrast: float = 1.0
var _saturation: float = 1.0

func _process(delta: float) -> void:
	_update_screen_flash(delta)
	_update_effects(delta)

func _update_screen_flash(delta: float) -> void:
	if _screen_flash_timer > 0:
		_screen_flash_timer -= delta
		if _screen_flash_timer <= 0:
			_screen_flash = Color.TRANSPARENT

func _update_effects(delta: float) -> void:
	var to_remove: Array = []
	
	for effect_id: String in _active_effects:
		var effect: Dictionary = _active_effects[effect_id]
		effect["timer"] -= delta
		
		if effect.get("timer", 0) <= 0:
			to_remove.append(effect_id)
	
	for effect_id: String in to_remove:
		_end_effect(effect_id)

func trigger_screen_shake(intensity: float, duration: float) -> void:
	_screen_shake = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "_screen_shake", Vector2.ZERO, duration)

func trigger_screen_flash(color: Color, duration: float) -> void:
	_screen_flash = color
	_screen_flash_duration = duration
	_screen_flash_timer = duration

func spawn_particle_effect(effect_id: String, position: Vector2, particle_type: String, count: int = 20) -> Dictionary:
	var effect_data: Dictionary = {
		"id": effect_id,
		"type": particle_type,
		"position": position,
		"count": count,
		"timer": 2.0,
		"particles": []
	}
	
	for i in range(count):
		effect_data["particles"].append({
			"offset": Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"velocity": Vector2(randf_range(-50, 50), randf_range(-100, -50)),
			"life": randf_range(0.5, 2.0),
			"size": randf_range(2, 8),
			"color": _get_particle_color(particle_type)
		})
	
	_active_effects[effect_id] = effect_data
	effect_started.emit(effect_id)
	
	return effect_data

func _get_particle_color(particle_type: String) -> Color:
	match particle_type:
		"fire": return Color(1.0, 0.5, 0.0, 0.8)
		"ice": return Color(0.5, 0.8, 1.0, 0.8)
		"lightning": return Color(0.9, 0.9, 1.0, 0.9)
		"poison": return Color(0.3, 0.6, 0.2, 0.7)
		"heal": return Color(0.2, 1.0, 0.3, 0.8)
		"dust": return Color(0.6, 0.5, 0.4, 0.5)
		"blood": return Color(0.8, 0.1, 0.1, 0.8)
		"sword": return Color(0.8, 0.8, 1.0, 0.9)
		"energy": return Color(0.5, 0.2, 1.0, 0.8)
	return Color.WHITE

func _end_effect(effect_id: String) -> void:
	if _active_effects.has(effect_id):
		_active_effects.erase(effect_id)
		effect_ended.emit(effect_id)

func trigger_hit_effect(position: Vector2, damage_type: String) -> void:
	match damage_type:
		"physical":
			spawn_particle_effect("hit_" + str(randi()), position, "dust", 10)
			trigger_screen_shake(5.0, 0.1)
		"fire":
			spawn_particle_effect("fire_hit_" + str(randi()), position, "fire", 15)
			trigger_screen_flash(Color(1.0, 0.3, 0.0, 0.3), 0.2)
		"ice":
			spawn_particle_effect("ice_hit_" + str(randi()), position, "ice", 15)
		"lightning":
			spawn_particle_effect("lightning_hit_" + str(randi()), position, "lightning", 20)
			trigger_screen_shake(10.0, 0.15)
		"poison":
			spawn_particle_effect("poison_hit_" + str(randi()), position, "poison", 12)
		"heal":
			spawn_particle_effect("heal_" + str(randi()), position, "heal", 20)
			trigger_screen_flash(Color(0.2, 1.0, 0.3, 0.2), 0.3)
		_:
			spawn_particle_effect("hit_" + str(randi()), position, "dust", 8)

func trigger_death_effect(position: Vector2) -> void:
	spawn_particle_effect("death_" + str(randi()), position, "blood", 30)
	trigger_screen_shake(15.0, 0.2)

func trigger_level_up_effect(position: Vector2) -> void:
	spawn_particle_effect("levelup_" + str(randi()), position, "heal", 50)
	trigger_screen_flash(Color(1.0, 0.9, 0.3, 0.4), 0.5)

func trigger_skill_effect(position: Vector2, skill_id: String) -> void:
	match skill_id:
		"sword_slash":
			spawn_particle_effect("sword_" + str(randi()), position, "sword", 30)
			trigger_screen_shake(8.0, 0.15)
		"fireball":
			spawn_particle_effect("fireball_" + str(randi()), position, "fire", 40)
			trigger_screen_flash(Color(1.0, 0.5, 0.0, 0.3), 0.3)
		"thunder_strike":
			spawn_particle_effect("thunder_" + str(randi()), position, "lightning", 60)
			trigger_screen_shake(20.0, 0.3)
			trigger_screen_flash(Color.WHITE, 0.1)
		"healing":
			spawn_particle_effect("healing_" + str(randi()), position, "heal", 50)
			trigger_screen_flash(Color(0.3, 1.0, 0.3, 0.2), 0.4)
		_:
			spawn_particle_effect("skill_" + str(randi()), position, "energy", 25)

func get_active_effects() -> Array:
	return _active_effects.keys()

func clear_all_effects() -> void:
	_active_effects.clear()

func get_screen_shake() -> Vector2:
	return _screen_shake

func get_screen_flash() -> Color:
	return _screen_flash

func set_post_process(bloom: bool = true, vignette: bool = true, contrast: float = 1.0, saturation: float = 1.0) -> void:
	_bloom_enabled = bloom
	_vignette_enabled = vignette
	_contrast = contrast
	_saturation = saturation

func to_dictionary() -> Dictionary:
	return {
		"active_effects": _active_effects.duplicate(true),
		"bloom_enabled": _bloom_enabled,
		"vignette_enabled": _vignette_enabled,
		"contrast": _contrast,
		"saturation": _saturation
	}

func from_dictionary(data: Dictionary) -> void:
	_active_effects = data.get("active_effects", {}).duplicate(true)
	_bloom_enabled = data.get("bloom_enabled", true)
	_vignette_enabled = data.get("vignette_enabled", true)
	_contrast = data.get("contrast", 1.0)
	_saturation = data.get("saturation", 1.0)
