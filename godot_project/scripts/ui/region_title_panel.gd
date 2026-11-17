extends Control
class_name RegionTitlePanel

## 区域名称水墨浮现效果
## 进入新区域时，区域名称以水墨毛笔风格从中间放大浮现
## 配合幕布效果（墨水从中心扩散）

signal title_finished()

const FADE_DURATION := 0.8
const HOLD_DURATION := 1.5
const INK_COLOR := Color(0.05, 0.04, 0.03)
const PAPER_COLOR := Color(0.14, 0.11, 0.08)

var _title_label: Label
var _subtitle_label: Label
var _ink_overlay: ColorRect
var _tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	hide()

func _build() -> void:
	# 水墨幕布（从中心扩散的墨色）
	_ink_overlay = ColorRect.new()
	_ink_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ink_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_overlay.material = ShaderMaterial.new()
	_ink_overlay.material.shader = preload("res://shaders/ink_splash.gdshader")
	_ink_overlay.modulate.a = 0.0
	add_child(_ink_overlay)
	
	# 标题
	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_title_label.offset_top = -40.0
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	_title_label.modulate.a = 0.0
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)
	
	# 副标题
	_subtitle_label = Label.new()
	_subtitle_label.set_anchors_preset(Control.PRESET_CENTER)
	_subtitle_label.offset_top = 16.0
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 20)
	_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.64))
	_subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.70))
	_subtitle_label.add_theme_constant_override("shadow_offset_x", 1)
	_subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle_label.modulate.a = 0.0
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_label)

## 显示区域标题浮现动画
## title: 区域名称
## subtitle: 副标题（区域类型/描述）
func show_title(title: String, subtitle: String = "") -> void:
	_title_label.text = title
	_subtitle_label.text = subtitle if not subtitle.is_empty() else ""
	_subtitle_label.visible = not subtitle.is_empty()
	
	# 重置状态
	_title_label.modulate.a = 0.0
	_title_label.scale = Vector2(0.3, 0.3)
	_title_label.pivot_offset = _title_label.size * 0.5
	if _title_label.size.x < 1.0 or _title_label.size.y < 1.0:
		var window_size := DisplayServer.window_get_size()
		_title_label.pivot_offset = window_size * 0.5
	
	_subtitle_label.modulate.a = 0.0
	_ink_overlay.modulate.a = 0.0
	
	show()
	
	# 取消已有 tween
	if _tween != null and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_parallel(true)
	
	# 幕布淡入（墨水从中心扩散）
	_tween.tween_property(_ink_overlay, "modulate:a", 0.36, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if _ink_overlay.material is ShaderMaterial:
		_tween.tween_method(func(v): _ink_overlay.material.set_shader_parameter("progress", v), 0.0, 0.8, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 标题放大浮现（0.3→1.0 + ease_out_back 弹跳）
	_tween.tween_property(_title_label, "scale", Vector2.ONE, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.15)
	_tween.tween_property(_title_label, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_delay(0.15)
	
	# 副标题淡入
	_tween.tween_property(_subtitle_label, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT).set_delay(0.4)
	
	# 暂停
	_tween.chain().tween_interval(HOLD_DURATION)
	
	# 淡出
	_tween.set_parallel(true)
	_tween.tween_property(_title_label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	_tween.tween_property(_title_label, "scale", Vector2(0.8, 0.8), 0.4).set_ease(Tween.EASE_IN)
	_tween.tween_property(_subtitle_label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_delay(0.1)
	_tween.tween_property(_ink_overlay, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.1)
	
	_tween.chain().tween_callback(func():
		hide()
		title_finished.emit()
	)
