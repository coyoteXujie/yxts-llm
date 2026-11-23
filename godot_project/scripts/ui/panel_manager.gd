extends Node
## 统一面板管理器 — 面板注册、堆栈管理、动画编排
## 自动加载（在 project.godot 中注册），通过 PanelManager 全局访问
##
## 职责：
##   - 注册所有 UI 面板（中央化，不再分散在各处）
##   - 面板堆栈管理：打开/关闭/返回
##   - 动画统一调度（桥接 PanelAnim）
##   - 模态面板支持
##
## 使用方式（自动加载后全局可用）：
##   PanelManager.open_panel("inventory")
##   PanelManager.close_top_panel()
##   PanelManager.close_all()

## 面板栈条目：{ panel: Node, modal: bool }
var _stack: Array[Dictionary] = []

## 已注册面板：name -> Node
var _panels: Dictionary = {}

## 面板默认动画类型注册表
var _panel_anim_types: Dictionary = {}

signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)

# ── 面板注册 ─────────────────────────────────────────

## 注册一个面板到管理器
## anim_type: PanelAnim.EaseType 枚举值，用于打开/关闭动画
func register_panel(panel_name: String, panel: Node,
		anim_type: int = PanelAnim.EaseType.SCALE_FADE) -> void:
	_panels[panel_name] = panel
	_panel_anim_types[panel_name] = anim_type

## 批量注册面板
func register_panels(panel_map: Dictionary) -> void:
	for p_name in panel_map:
		var entry: Variant = panel_map[p_name]
		if entry is Array and entry.size() >= 2:
			register_panel(p_name, entry[0], entry[1])
		else:
			register_panel(p_name, entry)

## 获取已注册的面板节点
func get_panel(panel_name: String) -> Node:
	return _panels.get(panel_name, null) as Node

## 检查面板是否已注册
func has_panel(panel_name: String) -> bool:
	return _panels.has(panel_name)

# ── 面板打开 ─────────────────────────────────────────

## 打开面板（通用入口）
## data 中可传 "modal": true 使面板变为模态
func open_panel(panel_name: String, data: Dictionary = {}) -> void:
	var panel: Node = _panels.get(panel_name) as Node
	if panel == null:
		push_error("PanelManager: unknown panel '%s'" % panel_name)
		return

	var is_modal: bool = bool(data.get("modal", false))
	
	# 如果已打开同一面板，先关闭旧的
	if _is_on_stack(panel):
		_remove_from_stack(panel)

	# 调用面板的 show 方法（适配不同面板签名）
	_call_show_method(panel, panel_name, data)

	# 执行打开动画
	var anim_type: int = _panel_anim_types.get(panel_name, PanelAnim.EaseType.SCALE_FADE)
	if panel is Control:
		PanelAnim.open_panel(panel as Control, anim_type)

	# 推入栈
	_stack.append({"panel": panel, "modal": is_modal})
	panel_opened.emit(panel_name)

## 关闭顶层面板（堆栈返回）
func close_top_panel() -> void:
	if _stack.is_empty():
		return
	var entry: Dictionary = _stack.pop_back()
	var panel: Node = entry.get("panel") as Node
	if panel == null or not is_instance_valid(panel):
		return
	_call_close_method(panel)
	var panel_name: String = _find_panel_name(panel)
	if not panel_name.is_empty():
		panel_closed.emit(panel_name)

## 关闭所有打开的面板（替换 _close_gameplay_panels）
func close_all() -> void:
	while not _stack.is_empty():
		var entry: Dictionary = _stack.pop_back()
		var panel: Node = entry.get("panel") as Node
		if panel != null and is_instance_valid(panel):
			_call_close_method(panel)

## 检查面板是否打开
func is_panel_open(panel_name: String) -> bool:
	var panel: Node = _panels.get(panel_name) as Node
	if panel == null:
		return false
	return _is_on_stack(panel)

## 检查是否有模态面板打开
func is_modal_open() -> bool:
	for entry in _stack:
		if bool(entry.get("modal", false)):
			return true
	return false

# ── 内部方法 ───────────────────────────────────────

func _is_on_stack(panel: Node) -> bool:
	for entry in _stack:
		if entry.get("panel") == panel:
			return true
	return false

func _remove_from_stack(panel: Node) -> void:
	for i in range(_stack.size() - 1, -1, -1):
		if _stack[i].get("panel") == panel:
			_stack.remove_at(i)
			return

func _find_panel_name(panel: Node) -> String:
	for name in _panels:
		if _panels[name] == panel:
			return name
	return ""

## 智能调用面板的 show 方法（兼容不同面板接口）
func _call_show_method(panel: Node, panel_name: String, data: Dictionary) -> void:
	# 一些面板有专用 show 方法
	match panel_name:
		"dialogue":
			if panel.has_method("show_npc") and data.has("npc"):
				panel.call("show_npc", data["npc"])
				return
		"shop":
			if panel.has_method("show_shop") and data.has("npc"):
				panel.call("show_shop", data["npc"])
				return
		"discovery":
			if panel.has_method("show_discovery") and data.has("discovery_data"):
				panel.call("show_discovery", data["discovery_data"])
				return
		"main_menu":
			var show_saved: bool = bool(data.get("show_saved", false))
			if panel.has_method("show_menu"):
				panel.call("show_menu", show_saved)
				return
		"combat":
			if panel.has_method("show_panel"):
				panel.call("show_panel")
				return
		"narrative":
			if panel.has_method("show_panel") and data.has("player_name"):
				panel.call("show_panel", str(data["player_name"]))
				return
	
	# 默认 fallback：show_panel() → show()
	if panel.has_method("show_panel"):
		panel.call("show_panel")
	elif panel.has_method("show"):
		panel.call("show")

## 智能调用面板的 close 方法
func _call_close_method(panel: Node) -> void:
	if panel.has_method("close_panel"):
		panel.call("close_panel")
	elif panel.has_method("hide"):
		panel.call("hide")
	var anim_type: int = PanelAnim.EaseType.SCALE_FADE
	for name in _panels:
		if _panels[name] == panel:
			anim_type = _panel_anim_types.get(name, PanelAnim.EaseType.SCALE_FADE)
			break
	if panel is Control and panel.visible:
		PanelAnim.close_panel(panel as Control, anim_type)
