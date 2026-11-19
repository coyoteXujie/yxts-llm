extends Control
class_name OpeningNarrativePanel

## 开场叙事面板 — 12段+打字机效果+章节标记视觉效果
##
## 结构：
##   [章节标头] → 序章·青冥初雪 / 白银之兴 / 白金之乱 / 暗影司 / 铁剑传人
##   [叙事段落] → 12段推进
##   [打字机逐字] → 35ms/字
##   [视觉反馈] → 章节标记出现时背景闪烁

const UI_ART := preload("res://scripts/ui/ui_art.gd")
const PANEL_ANIM := preload("res://scripts/ui/panel_anim.gd")

signal narrative_finished()

var body_label: Label
var continue_button: Button
var progress_label: Label
var chapter_label: Label
var subtitle_label: Label
var current_index := 0
var paragraphs: Array[Dictionary] = []
var _backdrop: TextureRect
var _vignette: ColorRect
var _title_label: Label
var _panel_container: PanelContainer
var _chapter_separator: HSeparator
var _chapter_glow: ColorRect

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

func _build_paragraphs(player_name: String) -> Array[Dictionary]:
	return [
		# ====== 章节标记：序章·青冥初雪 ======
		{
			"type": "chapter_marker",
			"text": "序章 · 青冥初雪",
			"subtitle": "青冥山 · 十七年前"
		},
		# 1. 青冥山上 · 铁剑传人
		{
			"type": "narrative",
			"text": "你自幼随师父「青云老人」隐居青冥山深处习武。\n山中岁月寂静而漫长，你在晨雾中扎马、在暮色里练剑，\n师父偶尔点头赞许，偶尔轻声叹息，却从不提你的身世。"
		},
		# 2. 下山之日
		{
			"type": "narrative",
			"text": "下山那日，青冥山门前的银杏正黄。\n师父将一个布包放入你手中，布面磨得发白，边角染着洗不掉的血迹：\n「这把铁剑，当年为师初入江湖时用过。你拿着。」\n你打开布包，剑鞘已旧，剑刃却仍锋利如初，鞘上镌着一朵含苞的莲花。"
		},
		# 3. 师父的叮嘱
		{
			"type": "narrative",
			"text": "师父望向山下的方向，沉默良久才开口：\n「江湖不是山中，人心比拳脚更难防。记住——行侠仗义，先从眼前人起。」\n他又从怀中取出一枚半截玉佩，塞到你掌心：\n「这是你襁褓中所系。你若想弄清自己的来处，就去洛阳。」\n你低头看着那枚玉佩——花纹残缺，像是某种标记的一半。"
		},
		# 4. 师父的背影
		{
			"type": "narrative",
			"text": "「另一半在何处？」你问。\n师父没有回答，转身走向山门。\n青冥山的风吹起他灰白的衣角，你看见他肩头有一道很深的旧剑伤，那伤口的形状你后来才知道——是朝廷禁军的制式长剑留下的。\n你攥紧铁剑和玉佩，迈出了下山的第一步。"
		},
		# ====== 章节标记：白银之兴 ======
		{
			"type": "chapter_marker",
			"text": "白银之兴",
			"subtitle": "二十年前 · 江湖黄金时代"
		},
		# 5. 白银时代
		{
			"type": "narrative",
			"text": "二十年��的江湖，是另一番气象。\n彼时七派和睦，武林盟坐镇洛阳，\n更有白金世家富可敌国——据说他们掌握着一门失传的冶炼术，\n所铸兵器锋锐无匹，江湖人称「白金之利，可断金石」。\n白银的棋盘上，人人皆是棋手，无人甘当棋子。"
		},
		# 6. 白金世家
		{
			"type": "narrative",
			"text": "白金世家并不以武功见长，却以财力与情报网行走江湖。\n他们在每一座城池都有商铺，在每一条商路都有耳目。\n家主白鹤年性情豪爽，乐善好施，七派中有求必应。\n但树大招风——白金家手中的那卷冶炼秘谱，\n引来了朝堂与暗处的觊觎。白银时代的落日，正是从白金家的烽火开始的。"
		},
		# ====== 章节标记：白金之乱 ======
		{
			"type": "chapter_marker",
			"text": "白金之乱",
			"subtitle": "十年前 · 血流成河"
		},
		# 7. 灾变
		{
			"type": "narrative",
			"text": "一夜之间，白金家满门遇袭。\n洛阳城东的白金山庄火光冲天，烧了整整三日。\n七派援军赶到时，庄内已无活口，冶炼秘谱不知所踪。\n有人说凶手是朝廷的鹰犬，有人说是魔教的劫掠，\n也有人说——是七派中出了内鬼，里应外合。\n江湖的信任，在那场大火中烧成了灰烬。"
		},
		# 8. 乱后余波
		{
			"type": "narrative",
			"text": "白金之乱后，七派元气大伤，彼此猜忌日深。\n武林盟的号令不再如从前那般有力，\n洛阳城的夜市提早收摊，江湖人夜行都要带上刀。\n而在一片混乱的灰烬中，一个名为「暗影司」的神秘势力悄然浮现——\n他们不收徒弟、不建山门、不争虚名，只在暗处收买线人、窃取情报、布置棋子。\n等你回过神来，暗影司的网已经撒遍了中原。"
		},
		# ====== 章节标记：铁剑传人 ======
		{
			"type": "chapter_marker",
			"text": "铁剑传人",
			"subtitle": "现在 · 平安镇"
		},
		# 9. 平安镇
		{
			"type": "narrative",
			"text": "「白金之乱」已过去十年。\n你在青冥山上练剑的时间，足够让一代人忘记旧伤，\n也足够让暗处的人把棋子摆好。\n眼下，你只知道最近的平安镇不太平——\n流氓横行，采花大盗出没，百姓苦不堪言。\n师父说，行侠仗义先从眼前人起。"
		},
		# 10. 三件心事
		{
			"type": "narrative",
			"text": "你肩上有三件事：\n一是自证侠义，以手中铁剑在江湖立名。\n二是查清身世——那枚半截玉佩，究竟指向洛阳的何处。\n三是一桩旧账——如果你连白金之乱、暗影司和师父肩头的剑伤一同追问，\n那么这个江湖欠你的答案，恐怕不止一个。"
		},
		# 11. 推门
		{
			"type": "narrative",
			"text": "你推开了平安镇客栈的木门。\n门外的青石板路被夕阳照得发亮，\n有人正在街角说书，茶摊上坐着三三两两的行人，\n远处传来铁匠铺的叮当声——和青冥山的风声完全不同。\n这里没有山雾，没有暮鼓，只有人间烟火，和最真实的江湖。\n你攥紧了腰间的铁剑，踏上了青石板路。"
		},
		# 12. 终语
		{
			"type": "narrative",
			"text": "新的江湖，从这里开始。\n你想要的答案——\n洛阳的火、断令的花纹、\n师父的旧伤、暗影司的真面目——\n都藏在这条长路的深处。\n持剑者，莫回头。"
		}
	]

func _show_current_paragraph() -> void:
	if current_index >= paragraphs.size():
		return
	var entry := paragraphs[current_index]
	var entry_type := str(entry.get("type", "narrative"))
	var text := str(entry.get("text", ""))
	var subtitle := str(entry.get("subtitle", ""))
	
	var is_marker := entry_type == "chapter_marker"
	
	_title_label.visible = is_marker
	chapter_label.visible = is_marker
	subtitle_label.visible = is_marker
	body_label.visible = not is_marker
	progress_label.visible = not is_marker
	_chapter_separator.visible = is_marker
	_chapter_glow.visible = is_marker
	
	if is_marker:
		_title_label.text = text
		subtitle_label.text = subtitle
		_chapter_glow.modulate.a = 0.3
		# 章节标记出现时，闪烁背景
		if _chapter_glow.has_meta("glow_tween"):
			var old_tween: Tween = _chapter_glow.get_meta("glow_tween")
			old_tween.kill()
		var tween := create_tween()
		tween.set_parallel(false)
		tween.tween_property(_chapter_glow, "modulate:a", 0.6, 1.2).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_chapter_glow, "modulate:a", 0.15, 1.0).set_ease(Tween.EASE_OUT)
		_chapter_glow.set_meta("glow_tween", tween)
		continue_button.disabled = false
	else:
		# 打字机模式
		_full_text = text
		_typing_index = 0
		_is_typing = true
		body_label.text = ""
		continue_button.disabled = true
		_typing_timer.start()
	
	progress_label.text = "%d / %d" % [current_index + 1, paragraphs.size()]
	continue_button.text = "开始冒险" if current_index == paragraphs.size() - 1 else "继续"
	
	# 段落切换淡入
	if body_label.modulate.a > 0:
		body_label.modulate.a = 0.0
		_title_label.modulate.a = 0.0
		chapter_label.modulate.a = 0.0
		subtitle_label.modulate.a = 0.0
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(body_label, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_title_label, "modulate:a", 1.0, 0.40).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(chapter_label, "modulate:a", 1.0, 0.40).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)

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
	# 背景
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.texture = UI_ART.load_texture(UI_ART.MAIN_MENU_BACKDROP)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	
	# 章节标记全屏辉光
	_chapter_glow = ColorRect.new()
	_chapter_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chapter_glow.color = Color(0.95, 0.70, 0.30, 0.0)
	_chapter_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_glow.visible = false
	add_child(_chapter_glow)
	
	# 顶部暗化渐变
	var top_fade := TextureRect.new()
	top_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient_tex := GradientTexture2D.new()
	gradient_tex.fill = 1
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
	gradient_bottom.fill = 1
	gradient_bottom.gradient = Gradient.new()
	gradient_bottom.gradient.add_point(0.0, Color(0.0, 0.0, 0.0, 0.0))
	gradient_bottom.gradient.add_point(0.6, Color(0.0, 0.0, 0.0, 0.35))
	gradient_bottom.gradient.add_point(1.0, Color(0.0, 0.0, 0.0, 0.72))
	bottom_fade.texture = gradient_bottom
	add_child(bottom_fade)

	# 中间文字面板
	_panel_container = PanelContainer.new()
	_panel_container.position = Vector2(200, 250)
	_panel_container.size = Vector2(880, 420)
	_panel_container.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel_container)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_container.add_child(box)

	# 章节标记文字（居中大标题）
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.44))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.custom_minimum_size = Vector2(800, 60)
	_title_label.visible = false
	box.add_child(_title_label)

	# 章节子标题
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.80, 0.70, 0.55))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	subtitle_label.custom_minimum_size = Vector2(800, 40)
	subtitle_label.visible = false
	box.add_child(subtitle_label)

	# 章节分割线
	_chapter_separator = HSeparator.new()
	_chapter_separator.custom_minimum_size = Vector2(300, 2)
	_chapter_separator.add_theme_color_override("color", Color(0.80, 0.65, 0.35, 0.5))
	_chapter_separator.visible = false
	box.add_child(_chapter_separator)

	# 章节小标签 "CHAPTER"
	chapter_label = Label.new()
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.add_theme_font_size_override("font_size", 12)
	chapter_label.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	chapter_label.custom_minimum_size = Vector2(800, 20)
	chapter_label.text = "— 章 节 —"
	chapter_label.visible = false
	box.add_child(chapter_label)

	# 正文
	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(800, 200)
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
	return UI_ART.panel_texture_style(Vector4(40, 28, 40, 28))

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_continue()
	elif visible and event.is_action_pressed("ui_cancel"):
		_on_continue()
