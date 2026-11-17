extends RefCounted
class_name PanelAnim

## 统一面板动画入口
## 提供多种动画类型：缩放弹入、滑入/滑出、淡入淡出
## 支持 Toast、背景遮罩

## 动画类型枚举
enum EaseType {
	SCALE_FADE,    # 缩放弹入+淡入 (0.8→1.0 ease_out_back)
	SLIDE_LEFT,    # 从右向左滑入
	SLIDE_RIGHT,   # 从左向右滑入
	FADE_ONLY,     # 仅透明度变化
}

const OPEN_DURATION := 0.18
const CLOSE_DURATION := 0.14
const OPEN_SCALE_FROM := Vector2(0.80, 0.80)  # 从0.8弹入
const OPEN_SCALE_FROM_FADE := Vector2(0.94, 0.94)
const CLOSE_SCALE_TO := Vector2(0.90, 0.90)  # 缩小到0.9
const OPEN_EASE := Tween.EASE_OUT
const OPEN_TRANS := Tween.TRANS_CUBIC
const CLOSE_EASE := Tween.EASE_IN
const CLOSE_TRANS := Tween.TRANS_QUAD
const SLIDE_DISTANCE := 80.0

# Toast 常量
const TOAST_SLIDE_DURATION := 0.30
const TOAST_HOLD_DURATION := 2.0

# 遮罩常量
const MASK_COLOR := Color(0.0, 0.0, 0.0, 0.50)


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


## 统一打开面板入口
## anim_type: EaseType 枚举值，默认 SCALE_FADE
static func open_panel(control: Control, anim_type: EaseType = EaseType.SCALE_FADE, duration: float = OPEN_DURATION) -> void:
	if control == null:
		return
	match anim_type:
		EaseType.SCALE_FADE:
			_open_scale_fade(control, duration)
		EaseType.SLIDE_LEFT:
			_open_slide(control, 1.0, duration)
		EaseType.SLIDE_RIGHT:
			_open_slide(control, -1.0, duration)
		EaseType.FADE_ONLY:
			fade_in(control, duration)


## 统一关闭面板入口
## anim_type: EaseType 枚举值，默认 SCALE_FADE
static func close_panel(control: Control, anim_type: EaseType = EaseType.SCALE_FADE, duration: float = CLOSE_DURATION) -> void:
	if control == null or not control.visible:
		return
	match anim_type:
		EaseType.SCALE_FADE:
			_close_scale_fade(control, duration)
		EaseType.SLIDE_LEFT, EaseType.SLIDE_RIGHT:
			_close_slide(control, anim_type, duration)
		EaseType.FADE_ONLY:
			fade_out(control, duration)


## 缩放弹入动画 (0.8→1.0 + ease_out_back 弹跳)
static func _open_scale_fade(control: Control, duration: float) -> void:
	_kill_existing(control)
	control.show()
	_prepare_pivot(control)
	control.modulate.a = 0.0
	control.scale = OPEN_SCALE_FROM
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := control.create_tween()
	t.set_parallel(true)
	t.tween_property(control, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 使用 ease_out_back 实现弹跳效果
	t.tween_property(control, "scale", Vector2.ONE, duration * 1.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	control.set_meta("_panel_tween", t)


## 缩小淡出动画 (1.0→0.9 + 淡出)
static func _close_scale_fade(control: Control, duration: float) -> void:
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


## 滑入动画 (direction: 1 = 从右向左, -1 = 从左向右)
static func _open_slide(control: Control, direction: float, duration: float) -> void:
	_kill_existing(control)
	control.show()
	control.modulate.a = 1.0
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := control.create_tween()
	t.set_parallel(true)
	var start_pos := Vector2(direction * SLIDE_DISTANCE, 0.0)
	control.position = start_pos
	t.tween_property(control, "position", Vector2.ZERO, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(control, "modulate:a", 1.0, duration * 0.5).set_ease(Tween.EASE_OUT)
	control.set_meta("_panel_tween", t)


## 滑出动画
static func _close_slide(control: Control, anim_type: EaseType, duration: float) -> void:
	_kill_existing(control)
	control.modulate.a = 1.0
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dir := 1.0 if anim_type == EaseType.SLIDE_LEFT else -1.0
	var t := control.create_tween()
	t.set_parallel(true)
	t.tween_property(control, "position", Vector2(dir * SLIDE_DISTANCE * -1.0, 0.0), duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(control, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func():
		control.position = Vector2.ZERO
		control.hide()
		control.modulate.a = 1.0)
	control.set_meta("_panel_tween", t)


## 淡入 (保留原接口)
static func fade_in(control: Control, duration: float = 0.22) -> void:
	if control == null:
		return
	_kill_existing(control)
	control.show()
	control.modulate.a = 0.0
	var t := control.create_tween()
	t.tween_property(control, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	control.set_meta("_panel_tween", t)


## 淡出 (保留原接口)
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


# ── 兼容旧接口 ──────────────────────────────────────

static func open(control: Control, duration: float = OPEN_DURATION) -> void:
	open_panel(control, EaseType.SCALE_FADE, duration)

static func close(control: Control, duration: float = CLOSE_DURATION) -> void:
	close_panel(control, EaseType.SCALE_FADE, duration)


# ── Toast 通知动画 ─────────────────────────────────

## 创建一个 Toast 标签并播放从顶部滑入→暂停→滑出的动画
## control: 拥有此标签的父控件（负责创建和移除）
## 返回创建的 Label
static func show_toast(parent: Control, text: String, text_color: Color = Color(1.0, 0.88, 0.52)) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.offset_top = -30.0  # 从屏幕顶上方开始
	parent.add_child(label)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	# 滑入
	tween.tween_property(label, "offset_top", 24.0, TOAST_SLIDE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	# 暂停
	tween.chain().tween_interval(TOAST_HOLD_DURATION)
	# 滑出
	tween.tween_property(label, "modulate:a", 0.0, TOAST_SLIDE_DURATION).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(label, "offset_top", -40.0, TOAST_SLIDE_DURATION).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)
	return label


# ── 背景遮罩 ────────────────────────────────────────

## 创建并显示一个半透明黑色背景遮罩（带淡入动画）
## parent: 遮罩的父控件
## 返回创建的 ColorRect
static func show_mask(parent: Control, duration: float = 0.25) -> ColorRect:
	var mask := ColorRect.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.color = MASK_COLOR
	mask.modulate.a = 0.0
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.name = "PanelAnimMask"
	parent.add_child(mask)

	var tween := parent.create_tween()
	tween.tween_property(mask, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)
	return mask


## 淡出并移除遮罩
static func hide_mask(mask: ColorRect, duration: float = 0.20) -> void:
	if mask == null or not is_instance_valid(mask):
		return
	var tween := mask.create_tween()
	tween.tween_property(mask, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		if is_instance_valid(mask):
			mask.queue_free()
	)


# ── 开/关面板（含遮罩） ─────────────────────────────

## 打开面板并创建背景遮罩
static func open_panel_with_mask(control: Control, parent: Control,
		anim_type: EaseType = EaseType.SCALE_FADE,
		p_duration: float = OPEN_DURATION,
		mask_duration: float = 0.25) -> ColorRect:
	var mask := show_mask(parent, mask_duration)
	open_panel(control, anim_type, p_duration)
	return mask


## 关闭面板和遮罩
static func close_panel_with_mask(control: Control, mask: ColorRect,
		anim_type: EaseType = EaseType.SCALE_FADE,
		p_duration: float = CLOSE_DURATION,
		mask_duration: float = 0.20) -> void:
	hide_mask(mask, mask_duration)
	close_panel(control, anim_type, p_duration)
