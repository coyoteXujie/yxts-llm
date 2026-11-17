extends Control
class_name OpeningNarrativePanel

const UI_ART := preload("res://scripts/ui/ui_art.gd")
const PANEL_ANIM := preload("res://scripts/ui/panel_anim.gd")

signal narrative_finished()

var body_label: Label
var continue_button: Button
var progress_label: Label
var current_index := 0
var paragraphs: Array[String] = []
var _backdrop: TextureRect
var _vignette: ColorRect
var _title_label: Label
var _panel: PanelContainer

# 打字机状态
var _typing_index := 0
var _full_text := ""
var _typing_timer: Timer
var _is_typing := false

const TYPING_INTERVAL := 0.035  # 35ms 每字，适配中文阅读

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()
	_setup_typing_timer()

func _setup_typing_timer() -> void:
	_typing_timer = Timer.new()
	_typing_timer.wait_time = TYPING_INTERVAL
	_typing_timer.one_shot = false
	_typing_timer.timeout.connect(_on_typing_tick)
	add_child(_typing_timer)

func _on_typing_tick() -> void:
	if _typing_index >= _full_text.length():
		_typing_timer.stop()
		_is_typing = false
		body_label.text = _full_text
		continue_button.disabled = false
		return
	# 逐字追加 + 打字机音效（每2字播一次，避免太密）
	_typing_index += 1
	body_label.text = _full_text.left(_typing_index)
	if _typing_index % 2 == 0:
		AudioManager.play_sfx("typewriter")

func show_panel(player_name: String) -> void:
	paragraphs = _build_paragraphs(player_name)
	current_index = 0
	_show_current_paragraph()
	PANEL_ANIM.fade_in(self)
	GameState.set_mode(GameState.Mode.MENU)
	# 在 headless/测试模式下叙事立即结束
	if DisplayServer.get_name() == "headless":
		narrative_finished.emit()

func _build_paragraphs(player_name: String) -> Array[String]:
	return [
		"序章 · 下山",
		"你自幼随师父「青云老人」隐居青冥山深处习武。\n山中岁月寂静，你在晨雾中扎马、在暮色里练剑，\n师父偶尔点头，偶尔轻叹，却从不提你的身世。",
		"下山那日，师父站在青冥山门之下，\n将一个布包放入你手中：\n「这把铁剑，当年为师初入江湖时用过。你拿着。」",
		"你打开布包，剑鞘已旧，剑刃却仍锋利。\n师父望向山下的方向，沉声说道：\n「江湖不是山中，人心比拳脚更难防。记住——行侠仗义，先从眼前人起。」",
		"「那枚玉佩……是你襁褓中所系。\n你若想弄清自己的来处，就去洛阳。」\n师父转身走回山门，你未能看见他的神情。",
		"「白金之乱」已过去十余年，\n七派元气大伤，武林盟威望不再，\n而暗处有一股势力——人称「暗影司」——正悄然收拢残局。",
		"眼下，你只知道平安镇近来不太平——\n流氓横行，采花大盗出没，百姓苦不堪言。\n师父说先从眼前人起，那便如此。",
		"你推门踏入平安镇的青石板路。\n新的江湖，从这里开始。"
	]

func _show_current_paragraph() -> void:
	if current_index >= paragraphs.size():
		return
	var text := paragraphs[current_index]
	var is_title := current_index == 0
	
	_title_label.visible = is_title
	body_label.visible = not is_title
	progress_label.visible = not is_title
	
	if is_title:
		_title_label.text = text
	else:
		# 打字机模式：清空文字，启动逐字显示
		_full_text = text
		_typing_index = 0
		_is_typing = true
		body_label.text = ""
		continue_button.disabled = true
		_typing_timer.start()
	
	progress_label.text = "%d / %d" % [current_index + 1, paragraphs.size()]
	continue_button.text = "踏入江湖" if current_index == paragraphs.size() - 1 else "继续"
	
	# 段落切换淡入
	if body_label.modulate.a > 0:
		body_label.modulate.a = 0.0
		_title_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body_label, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.40).set_ease(Tween.EASE_OUT)

func _on_continue() -> void:
	# 如果正在打字，点击后立刻显示全文
	if _is_typing:
		_typing_timer.stop()
		_is_typing = false
		body_label.text = _full_text
		continue_button.disabled = false
		return
	
	current_index += 1
	if current_index >= paragraphs.size():
		PANEL_ANIM.fade_out(self)
		await get_tree().create_timer(0.25).timeout
		narrative_finished.emit()
	else:
		_show_current_paragraph()

func _build() -> void:
	# 背景：主菜单水墨场景
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.texture = UI_ART.load_texture(UI_ART.MAIN_MENU_BACKDROP)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	
	# 顶部暗化渐变（从上往下）
	var top_fade := TextureRect.new()
	top_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient_tex := GradientTexture2D.new()
	gradient_tex.fill = 1  # FILL_TOP_TO_BOTTOM
	gradient_tex.gradient = Gradient.new()
	gradient_tex.gradient.add_point(0.0, Color(0.0, 0.0, 0.0, 0.72))
	gradient_tex.gradient.add_point(0.5, Color(0.0, 0.0, 0.0, 0.35))
	gradient_tex.gradient.add_point(1.0, Color(0.0, 0.0, 0.0, 0.0))
	top_fade.texture = gradient_tex
	add_child(top_fade)
	
	# 底部暗化渐变
	var bottom_fade := TextureRect.new()
	bottom_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient_bottom := GradientTexture2D.new()
	gradient_bottom.fill = 1  # FILL_TOP_TO_BOTTOM
	gradient_bottom.gradient = Gradient.new()
	gradient_bottom.gradient.add_point(0.0, Color(0.0, 0.0, 0.0, 0.0))
	gradient_bottom.gradient.add_point(0.6, Color(0.0, 0.0, 0.0, 0.35))
	gradient_bottom.gradient.add_point(1.0, Color(0.0, 0.0, 0.0, 0.72))
	bottom_fade.texture = gradient_bottom
	add_child(bottom_fade)

	# 中间文字面板
	var panel := PanelContainer.new()
	panel.position = Vector2(200, 315)
	panel.size = Vector2(880, 340)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)

	# 标题（用于 "序章 · 下山"）
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.44))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.custom_minimum_size = Vector2(800, 200)
	_title_label.visible = false
	box.add_child(_title_label)

	# 正文字体
	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(800, 180)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_ART.apply_body_label(body_label, 20)
	body_label.visible = false
	box.add_child(body_label)

	# 进度
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	progress_label.visible = false
	box.add_child(progress_label)

	# 按钮
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)

	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(200, 46)
	continue_button.add_theme_font_size_override("font_size", 17)
	UI_ART.apply_button(continue_button)
	continue_button.pressed.connect(_on_continue)
	actions.add_child(continue_button)

func _panel_style() -> StyleBox:
	return UI_ART.panel_texture_style(Vector4(40, 28, 40, 24))

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_continue()
	elif visible and event.is_action_pressed("ui_cancel"):
		_on_continue()