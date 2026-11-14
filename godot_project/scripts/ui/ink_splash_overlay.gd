extends ColorRect
class_name InkSplashOverlay

signal splash_finished()

const SPLASH_SHADER := preload("res://shaders/ink_splash.gdshader")
const SPLASH_DURATION := 1.5

var _progress: float = 0.0
var _shader_mat: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = SPLASH_SHADER
	material = _shader_mat
	# 全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color.WHITE  # 初始白色，shader覆盖

func start_splash() -> void:
	# headless/测试模式下跳过动画
	if DisplayServer.get_name() == "headless":
		splash_finished.emit()
		return
	show()
	_progress = 0.0
	_shader_mat.set_shader_parameter("progress", 0.0)
	var tween := create_tween()
	tween.tween_method(_update_progress, 0.0, 1.0, SPLASH_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func():
		var fade_tween := create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
		fade_tween.chain().tween_callback(func():
			hide()
			modulate.a = 1.0
			splash_finished.emit()
		)
	)

func _update_progress(val: float) -> void:
	_progress = val
	if _shader_mat:
		_shader_mat.set_shader_parameter("progress", val)
