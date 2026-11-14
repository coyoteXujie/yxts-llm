extends RefCounted
class_name PanelAnim

const OPEN_DURATION := 0.18
const CLOSE_DURATION := 0.14
const OPEN_SCALE_FROM := Vector2(0.94, 0.94)
const CLOSE_SCALE_TO := Vector2(0.97, 0.97)
const OPEN_EASE := Tween.EASE_OUT
const OPEN_TRANS := Tween.TRANS_CUBIC
const CLOSE_EASE := Tween.EASE_IN
const CLOSE_TRANS := Tween.TRANS_QUAD

static func _kill_existing(control: Control) -> void:
	if control.has_meta("_panel_tween"):
		var old: Tween = control.get_meta("_panel_tween")
		if old != null and old.is_valid():
			old.kill()

static func _prepare_pivot(control: Control) -> void:
	var s := control.size
	if s.x < 1.0 or s.y < 1.0:
		s = DisplayServer.window_get_size()
	control.pivot_offset = s * 0.5

static func open(control: Control, duration: float = OPEN_DURATION) -> void:
	if control == null:
		return
	_kill_existing(control)
	control.show()
	_prepare_pivot(control)
	control.modulate.a = 0.0
	control.scale = OPEN_SCALE_FROM
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := control.create_tween()
	t.set_parallel(true)
	t.tween_property(control, "modulate:a", 1.0, duration).set_ease(OPEN_EASE).set_trans(Tween.TRANS_QUAD)
	t.tween_property(control, "scale", Vector2.ONE, duration).set_ease(OPEN_EASE).set_trans(OPEN_TRANS)
	control.set_meta("_panel_tween", t)

static func close(control: Control, duration: float = CLOSE_DURATION) -> void:
	if control == null or not control.visible:
		return
	_kill_existing(control)
	_prepare_pivot(control)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := control.create_tween()
	t.set_parallel(true)
	t.tween_property(control, "modulate:a", 0.0, duration).set_ease(CLOSE_EASE).set_trans(CLOSE_TRANS)
	t.tween_property(control, "scale", CLOSE_SCALE_TO, duration).set_ease(CLOSE_EASE).set_trans(CLOSE_TRANS)
	t.chain().tween_callback(func():
		control.hide()
		control.scale = Vector2.ONE
		control.modulate.a = 1.0)
	control.set_meta("_panel_tween", t)

static func fade_in(control: Control, duration: float = 0.22) -> void:
	if control == null:
		return
	_kill_existing(control)
	control.show()
	control.modulate.a = 0.0
	var t := control.create_tween()
	t.tween_property(control, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	control.set_meta("_panel_tween", t)

static func fade_out(control: Control, duration: float = 0.18) -> void:
	if control == null or not control.visible:
		return
	_kill_existing(control)
	var t := control.create_tween()
	t.tween_property(control, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.chain().tween_callback(func():
		control.hide()
		control.modulate.a = 1.0)
	control.set_meta("_panel_tween", t)
