extends Control
class_name EndingCreditsPanel

const FONT_SIZE_TITLE := 38
const FONT_SIZE_SUBTITLE := 22
const FONT_SIZE_BODY := 17
const SCROLL_DURATION := 28.0
const FADE_DURATION := 2.0

var _credits_label: Label
var _scroll_tween: Tween
var _is_closing := false

func show_credits(epilogue: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0

	# 墨底背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.012, 0.010, 0.008, 1.0)
	add_child(bg)

	# 滚动文本
	_credits_label = Label.new()
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_label.add_theme_font_size_override("font_size", 17)
	_credits_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	_credits_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_credits_label.add_theme_constant_override("shadow_offset_x", 1)
	_credits_label.add_theme_constant_override("shadow_offset_y", 1)
	_credits_label.size = Vector2(560, 6000)
	_credits_label.position = Vector2(
		(get_viewport_rect().size.x - 560) * 0.5,
		get_viewport_rect().size.y
	)
	add_child(_credits_label)
	_credits_label.text = _build_credits_text(epilogue)

	show()

	# 淡入
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_IN)

	# 滚动
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(_credits_label, "position:y", -_credits_label.size.y, SCROLL_DURATION).set_ease(Tween.EASE_OUT).set_delay(FADE_DURATION)
	_scroll_tween.chain().tween_callback(_on_scroll_complete)

func _build_credits_text(epilogue: String) -> String:
	var epilogue_title := "江湖留灯" if epilogue == "mercy" else "残影清剿"
	var epilogue_line := "你选择与苏梦瑶一起，为江湖留一盏灯。" if epilogue == "mercy" else "你选择与陈天行一起，清剿暗影司残部。"

	var npc_epilogues := _build_npc_epilogues(epilogue)

	return """[center][b]白金英雄坛说[/b]



—— 终章 · %s ——



%s



%s



• 制 作 •

白金英雄坛说开发组



• 策 划 •

白金工作室



• 剧 本 •

苏梦瑶、陈天行、花如玉
太极真人、玄机子、无面君



• 武 学 设 计 •

八卦门、雪山派、太极门
红莲教、花间派、逍遥宫、那迦派



• 美术 & 程序 •

Godot Engine 4.6



• 音 乐 •

平安镇晨曲 · 洛阳旧火
暗影书信 · 七派夜议
江湖留灯 · 残影清剿



• 特 别 鸣 谢 •

洛阳武林盟
七派掌门会
平安镇全体乡亲



江湖路远，后会有期。



© 2025 白金英雄坛说开发组
按任意键返回主菜单[/center]""" % [epilogue_title, epilogue_line, npc_epilogues]

func _build_npc_epilogues(epilogue: String) -> String:
	if epilogue == "mercy":
		return (
			"\n\n\n— 江湖留灯 · 故人余音 —\n\n"
			+ "苏梦瑶\n将苏家旧宅遗址改建为一座无名茶寮，\n专收无处可去的孤儿。\n花间派的姐妹们轮流来帮忙，\n茶寮的灯，每晚都亮到深夜。\n\n"
			+ "陈天行\n放下说书人的醒木，为旧案写下一部完整的《暗影录》，\n藏于武林盟书阁。\n他说：有些故事不是用来讲的，是用来提醒后人的。\n\n"
			+ "赵无极\n带着武林盟的手令巡游七派，\n督办旧案善后。\n他在一份密报里写道：\n「江湖欠苏家一个公道，今日总算还了。」"
		)
	else:
		return (
			"\n\n\n— 残影清剿 · 余烬归处 —\n\n"
			+ "苏梦瑶\n随武林盟连夜清查暗影司残部，\n在最后一条暗线落网后，\n她独自回到苏家旧宅遗址，\n烧了一炷香，什么也没说。\n\n"
			+ "陈天行\n以说书人的身份游走南北，\n将暗影司的覆灭编成新书。\n他说：\n「要让百姓知道江湖的黑夜是谁点亮的，也得知道谁曾走在黑暗里。」\n\n"
			+ "赵无极\n带队收押暗影司余党，\n在总坛暗道里找到了一卷旧信——\n信中提及了更深处的势力。\n他将那卷信锁进了武林盟的铁柜。\n卷宗名册上只写了四个字：待查。"
		)

func _input(event: InputEvent) -> void:
	if not visible or _is_closing:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		_close_credits()
		get_viewport().set_input_as_handled()

func _close_credits() -> void:
	if _is_closing:
		return
	_is_closing = true
	if _scroll_tween != null:
		_scroll_tween.kill()
	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_out.chain().tween_callback(_on_closed)

func _on_scroll_complete() -> void:
	_close_credits()

func _on_closed() -> void:
	queue_free()
	GameState.set_mode(GameState.Mode.MENU)
