extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func clamp(value: Variant, min_val: Variant, max_val: Variant) -> Variant:
	if value < min_val:
		return min_val
	if value > max_val:
		return max_val
	return value

func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * clamp(t, 0.0, 1.0)

func random_range_float(min_val: float, max_val: float) -> float:
	return _rng.randf_range(min_val, max_val)

func random_range_int(min_val: int, max_val: int) -> int:
	return _rng.range(min_val, max_val + 1)

func random_chance(chance: float) -> bool:
	return _rng.randf() < chance

func format_time(seconds: float) -> String:
	var hrs := int(seconds / 3600.0)
	var mins := int(fmod(seconds, 3600.0) / 60.0)
	var secs := int(fmod(seconds, 60.0))
	if hrs > 0:
		return "%02d:%02d:%02d" % [hrs, mins, secs]
	return "%02d:%02d" % [mins, secs]

func format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)

func distance_2d(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

func random_element(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[random_range_int(0, array.size() - 1)]

func shuffle_array(array: Array) -> Array:
	var result := array.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := random_range_int(0, i)
		var temp: Variant = result[i]
		result[i] = result[j]
		result[j] = temp
	return result

func safe_get(dictionary: Dictionary, key: String, default_value: Variant = null) -> Variant:
	if dictionary.has(key):
		return dictionary[key]
	return default_value

func safe_int(value: Variant, default_value: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		if value.is_valid_int():
			return value.to_int()
	return default_value

func safe_float(value: Variant, default_value: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String:
		if value.is_valid_float():
			return value.to_float()
	return default_value

func safe_string(value: Variant, default_value: String = "") -> String:
	if value is String:
		return value
	if value == null:
		return default_value
	return str(value)

func ease_value(value: float, curve: float = 2.0) -> float:
	if value < 0.5:
		return pow(value * 2.0, curve) / 2.0
	else:
		return 1.0 - pow(-2.0 * value + 2.0, curve) / 2.0

func lerp_color(color1: Color, color2: Color, t: float) -> Color:
	t = clamp(t, 0.0, 1.0)
	return Color(
		lerp(color1.r, color2.r, t),
		lerp(color1.g, color2.g, t),
		lerp(color1.b, color2.b, t),
		lerp(color1.a, color2.a, t)
	)

func angle_to_direction(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))

func direction_to_angle(direction: Vector2) -> float:
	return direction.angle()

func vector2_to_string(v: Vector2, _decimals: int = 2) -> String:
	return "(%.2f, %.2f)" % [v.x, v.y]

func interpolate_rotation(from: float, to: float, t: float) -> float:
	var diff := fmod(to - from + PI * 3.0, PI * 2.0) - PI
	return from + diff * clamp(t, 0.0, 1.0)

func is_point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

func get_direction_name(direction: Vector2) -> String:
	var angle := direction.angle()
	if abs(angle) < PI / 4:
		return "右"
	elif abs(angle) > PI * 3 / 4:
		return "左"
	elif angle > 0:
		return "下"
	return "上"

func get_ordinal(number: int) -> String:
	var suffix := "日"
	match number % 10:
		1:
			suffix = "初一"
		2:
			suffix = "初二"
		3:
			suffix = "初三"
		4:
			suffix = "初四"
		5:
			suffix = "初五"
		6:
			suffix = "初六"
		7:
			suffix = "初七"
		8:
			suffix = "初八"
		9:
			suffix = "初九"
		0:
			suffix = "初十"
	return "%d%s" % [number, suffix]
