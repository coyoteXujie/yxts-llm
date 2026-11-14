extends RefCounted
class_name UiTheme

const SONGTI_BOLD := "res://assets/fonts/songti_bold.ttf"
const SONGTI_REGULAR := "res://assets/fonts/songti_regular.ttf"
const HEITI_MEDIUM := "res://assets/fonts/heiti_medium.ttf"

const COLOR_GOLD := Color(0.788, 0.663, 0.431)
const COLOR_GOLD_BRIGHT := Color(0.980, 0.860, 0.580)
const COLOR_CINNABAR := Color(0.753, 0.224, 0.169)
const COLOR_INK_BG := Color(0.055, 0.045, 0.033, 0.94)
const COLOR_INK_BORDER := Color(0.663, 0.502, 0.243, 0.80)
const COLOR_TEXT_PRIMARY := Color(0.902, 0.863, 0.765)
const COLOR_TEXT_SECONDARY := Color(0.690, 0.690, 0.620)
const COLOR_TEXT_DISABLED := Color(0.510, 0.490, 0.420)
const COLOR_SHADOW := Color(0.0, 0.0, 0.0, 0.85)
## 控件体系 token：底/边三态与焦点金，全部从金墨主色推导
const COLOR_CONTROL_BG := Color(0.075, 0.066, 0.047, 0.88)
const COLOR_CONTROL_BG_HOVER := Color(0.115, 0.100, 0.066, 0.92)
const COLOR_CONTROL_BG_DOWN := Color(0.050, 0.045, 0.032, 0.95)
const COLOR_BORDER_DIM := Color(0.663, 0.502, 0.243, 0.42)
const COLOR_FOCUS_GOLD := Color(0.980, 0.860, 0.580, 0.65)
const COLOR_TAB_SELECTED := Color(0.130, 0.110, 0.072, 0.90)

const FONT_TITLE_SIZE := 26
const FONT_SECTION_SIZE := 18
const FONT_BODY_SIZE := 16
const FONT_UI_SIZE := 14
const FONT_SMALL_SIZE := 12
const FONT_MICRO_SIZE := 11

static var _title_font: FontFile
static var _body_font: FontFile
static var _ui_font: FontFile

static func title_font() -> FontFile:
	if _title_font == null:
		_title_font = load(SONGTI_BOLD) as FontFile
	return _title_font

static func body_font() -> FontFile:
	if _body_font == null:
		_body_font = load(SONGTI_REGULAR) as FontFile
	return _body_font

static func ui_font() -> FontFile:
	if _ui_font == null:
		_ui_font = load(HEITI_MEDIUM) as FontFile
	return _ui_font

static func _flat_style(bg: Color, border: Color, border_width: int = 1, radius: int = 3, margins: Vector4 = Vector4(14, 8, 14, 8)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style

static func build_theme() -> Theme:
	var theme := Theme.new()
	var tf := title_font()
	var bf := body_font()
	var uf := ui_font()
	theme.default_font = uf
	theme.set_font("font", "Label", uf)
	theme.set_font("font", "Button", uf)
	theme.set_font("font", "LineEdit", uf)
	theme.set_font("font", "TextEdit", uf)
	theme.set_font("font", "ItemList", uf)
	theme.set_font("font", "RichTextLabel", uf)
	theme.set_font("font", "TabBar", uf)
	theme.set_font("font", "TabContainer", uf)
	theme.set_font("font", "OptionButton", uf)
	theme.set_font("font", "SpinBox", uf)
	theme.set_font("font", "ProgressBar", uf)
	theme.set_font("font", "Window", uf)
	theme.set_font_size("font_size", "Label", FONT_UI_SIZE)
	theme.set_font_size("font_size", "Button", FONT_UI_SIZE)
	theme.set_font_size("font_size", "LineEdit", FONT_UI_SIZE)
	theme.set_font_size("font_size", "TextEdit", FONT_BODY_SIZE)
	theme.set_font_size("font_size", "ItemList", FONT_UI_SIZE)
	theme.set_font_size("font_size", "RichTextLabel", FONT_BODY_SIZE)
	theme.set_font_size("font_size", "OptionButton", FONT_UI_SIZE)
	theme.set_font_size("font_size", "SpinBox", FONT_UI_SIZE)
	theme.set_font_size("font_size", "TabBar", FONT_UI_SIZE)
	theme.set_font_size("font_size", "TabContainer", FONT_UI_SIZE)
	theme.set_color("font_color", "Label", COLOR_TEXT_PRIMARY)
	theme.set_color("font_color", "Button", COLOR_GOLD_BRIGHT)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.92, 0.68))
	theme.set_color("font_pressed_color", "Button", COLOR_GOLD)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DISABLED)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT_PRIMARY)
	theme.set_color("font_color", "TextEdit", COLOR_TEXT_PRIMARY)
	theme.set_color("font_color", "ItemList", COLOR_TEXT_PRIMARY)
	theme.set_color("font_color", "RichTextLabel", COLOR_TEXT_PRIMARY)
	theme.set_color("font_color", "OptionButton", COLOR_TEXT_PRIMARY)
	theme.set_color("font_selected_color", "ItemList", COLOR_GOLD_BRIGHT)
	theme.set_color("font_hover_color", "ItemList", COLOR_GOLD_BRIGHT)
	theme.set_color("font_hover_color", "TabBar", COLOR_GOLD_BRIGHT)
	theme.set_color("font_selected_color", "TabBar", COLOR_GOLD_BRIGHT)
	## 按钮四态：金边墨底，悬浮提亮、按下沉稳、禁用去光
	theme.set_stylebox("normal", "Button", _flat_style(COLOR_CONTROL_BG, COLOR_BORDER_DIM, 1, 3))
	theme.set_stylebox("hover", "Button", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_FOCUS_GOLD, 1, 3))
	theme.set_stylebox("pressed", "Button", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_GOLD, 1, 3))
	theme.set_stylebox("disabled", "Button", _flat_style(Color(0.05, 0.05, 0.04, 0.6), Color(0.40, 0.36, 0.26, 0.25), 1, 3))
	theme.set_stylebox("focus", "Button", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_FOCUS_GOLD, 1, 3))
	## 下拉钮与按钮同宗
	theme.set_stylebox("normal", "OptionButton", _flat_style(COLOR_CONTROL_BG, COLOR_BORDER_DIM, 1, 3))
	theme.set_stylebox("hover", "OptionButton", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_FOCUS_GOLD, 1, 3))
	theme.set_stylebox("pressed", "OptionButton", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_GOLD, 1, 3))
	theme.set_stylebox("disabled", "OptionButton", _flat_style(Color(0.05, 0.05, 0.04, 0.6), Color(0.40, 0.36, 0.26, 0.25), 1, 3))
	theme.set_stylebox("focus", "OptionButton", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_FOCUS_GOLD, 1, 3))
	## 输入框：墨底金边，聚焦时金满
	theme.set_stylebox("normal", "LineEdit", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_BORDER_DIM, 1, 3, Vector4(12, 7, 12, 7)))
	theme.set_stylebox("focus", "LineEdit", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_FOCUS_GOLD, 1, 3, Vector4(12, 7, 12, 7)))
	theme.set_stylebox("read_only", "LineEdit", _flat_style(Color(0.04, 0.04, 0.03, 0.5), Color(0.40, 0.36, 0.26, 0.2), 1, 3, Vector4(12, 7, 12, 7)))
	## 页签：选中金底微亮，未选收进墨里
	var tab_selected := _flat_style(COLOR_TAB_SELECTED, COLOR_GOLD, 1, 3, Vector4(16, 8, 16, 8))
	tab_selected.border_width_bottom = 2
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_selected", "TabBar", tab_selected)
	theme.set_stylebox("tab_hovered", "TabContainer", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_BORDER_DIM, 1, 3, Vector4(16, 8, 16, 8)))
	theme.set_stylebox("tab_hovered", "TabBar", _flat_style(COLOR_CONTROL_BG_HOVER, COLOR_BORDER_DIM, 1, 3, Vector4(16, 8, 16, 8)))
	theme.set_stylebox("tab_unselected", "TabContainer", _flat_style(Color(0, 0, 0, 0), Color(0.663, 0.502, 0.243, 0.22), 1, 3, Vector4(16, 8, 16, 8)))
	theme.set_stylebox("tab_unselected", "TabBar", _flat_style(Color(0, 0, 0, 0), Color(0.663, 0.502, 0.243, 0.22), 1, 3, Vector4(16, 8, 16, 8)))
	theme.set_stylebox("panel", "TabContainer", _flat_style(COLOR_CONTROL_BG, COLOR_BORDER_DIM, 1, 3))
	## 列表与文本域：面板底收墨、焦点金边
	theme.set_stylebox("panel", "ItemList", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_BORDER_DIM, 1, 3, Vector4(10, 8, 10, 8)))
	theme.set_stylebox("focus", "ItemList", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_FOCUS_GOLD, 1, 3, Vector4(10, 8, 10, 8)))
	theme.set_stylebox("normal", "TextEdit", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_BORDER_DIM, 1, 3, Vector4(10, 8, 10, 8)))
	theme.set_stylebox("focus", "TextEdit", _flat_style(COLOR_CONTROL_BG_DOWN, COLOR_FOCUS_GOLD, 1, 3, Vector4(10, 8, 10, 8)))
	## 进度条：墨底金填充（面板各自覆写红绿血蓝时不受此影响）
	theme.set_stylebox("background", "ProgressBar", _flat_style(Color(0.03, 0.027, 0.02, 0.9), Color(0.40, 0.36, 0.26, 0.4), 1, 2, Vector4.ZERO))
	theme.set_stylebox("fill", "ProgressBar", _flat_style(Color(0.72, 0.60, 0.36, 0.95), Color(0, 0, 0, 0), 0, 2, Vector4.ZERO))
	## 提示框：深墨金边，不再引擎默认亮白
	theme.set_stylebox("panel", "TooltipPanel", _flat_style(COLOR_INK_BG, COLOR_INK_BORDER, 1, 2, Vector4(10, 7, 10, 7)))
	return theme

static func apply_title_font(label: Label) -> void:
	label.add_theme_font_override("font", title_font())

static func apply_body_font(label: Label) -> void:
	label.add_theme_font_override("font", body_font())

static func apply_heading_font(label: Label) -> void:
	label.add_theme_font_override("font", title_font())

static func make_title_rule(width_px: int = 120) -> HSeparator:
	## 面板标题下的金线：一条克制的一象素金，给深蓝夜色里的标题一个支点
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(width_px, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := StyleBoxLine.new()
	line.color = Color(COLOR_GOLD, 0.55)
	line.thickness = 1
	sep.add_theme_stylebox_override("separator", line)
	return sep
