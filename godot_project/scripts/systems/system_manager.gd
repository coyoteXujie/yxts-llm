extends Node
## 统一系统管理器 — 系统注册、依赖注入、生命周期管理
## 自动加载（在 project.godot 中注册），通过 SystemManager 全局访问
##
## 职责：
##   - 注册系统模块，按名称索引
##   - 自动依赖解析（系统声明依赖，自动按序初始化）
##   - 生命周期：init() → start() → stop()
##   - 替换 main.gd 中的分散初始化
##
## 使用方式（自动加载后全局可用）：
##   SystemManager.register_system("combat", combat_node, ["game_state"])
##   SystemManager.init_all()
##   SystemManager.start_all()
##   var combat := SystemManager.get_system("combat")

signal system_registered(name: String)
signal system_init_started(name: String)
signal system_init_completed(name: String)
signal system_started(name: String)
signal system_stopped(name: String)

## 系统定义：{ name, node, deps, state }
enum SystemState {
	UNINITIALIZED,
	INITIALIZED,
	STARTED,
	STOPPED,
	FAILED
}

var _systems: Dictionary = {}  # name -> { node, deps, state }

# ── 注册 ─────────────────────────────────────────────

## 注册一个系统模块
## name: 唯一标识名
## node: 系统节点实例
## dependencies: 依赖的其他系统名称列表
func register_system(name: String, node: Node, dependencies: Array[String] = []) -> void:
	assert(not _systems.has(name), "SystemManager: duplicate system '%s'" % name)
	_systems[name] = {
		"node": node,
		"deps": dependencies.duplicate(),
		"state": SystemState.UNINITIALIZED
	}
	system_registered.emit(name)

## 批量注册系统
func register_systems(system_map: Dictionary) -> void:
	for s_name in system_map:
		var entry = system_map[s_name]
		if entry is Array and entry.size() >= 2:
			register_system(s_name, entry[0], entry[1])
		else:
			register_system(s_name, entry)

## 获取已注册的系统节点
func get_system(name: String) -> Node:
	var entry: Dictionary = _systems.get(name, {})
	if entry.is_empty():
		return null
	return entry.get("node") as Node

## 获取系统状态
func get_system_state(name: String) -> int:
	var entry: Dictionary = _systems.get(name, {})
	if entry.is_empty():
		return SystemState.UNINITIALIZED
	return entry.get("state", SystemState.UNINITIALIZED) as int

## 检查系统是否存在
func has_system(name: String) -> bool:
	return _systems.has(name)

# ── 生命周期：init → start → stop ──────────────────

## 初始化所有系统（按依赖拓扑排序）
func init_all() -> void:
	var order: Array[String] = _resolve_dependency_order()
	for name in order:
		_init_system(name)

## 启动所有已初始化的系统
func start_all() -> void:
	for s_name in _systems:
		_start_system(s_name)

## 停止所有系统（反向顺序）
func stop_all() -> void:
	var order: Array[String] = _resolve_dependency_order()
	order.reverse()
	for name in order:
		_stop_system(name)

## 初始化单个系统
func init_system(name: String) -> bool:
	if not _systems.has(name):
		push_error("SystemManager: unknown system '%s'" % name)
		return false
	return _init_system(name)

## 启动单个系统
func start_system(name: String) -> bool:
	if not _systems.has(name):
		push_error("SystemManager: unknown system '%s'" % name)
		return false
	return _start_system(name)

# ── 内部方法 ───────────────────────────────────────

func _init_system(name: String) -> bool:
	var entry: Dictionary = _systems[name]
	if entry.get("state", SystemState.UNINITIALIZED) != SystemState.UNINITIALIZED:
		return true

	system_init_started.emit(name)

	# 自动注入依赖引用
	_inject_dependencies(name, entry)

	# 调用系统的 init 方法（如果有）
	var node: Node = entry.get("node") as Node
	if node != null and node.has_method("init"):
		node.call("init")

	entry["state"] = SystemState.INITIALIZED
	system_init_completed.emit(name)
	return true

func _start_system(name: String) -> bool:
	var entry: Dictionary = _systems[name]
	if entry.get("state", SystemState.UNINITIALIZED) == SystemState.STARTED:
		return true
	if entry.get("state", SystemState.UNINITIALIZED) == SystemState.UNINITIALIZED:
		_init_system(name)

	var node: Node = entry.get("node") as Node
	if node != null and node.has_method("start"):
		node.call("start")

	entry["state"] = SystemState.STARTED
	system_started.emit(name)
	return true

func _stop_system(name: String) -> void:
	var entry: Dictionary = _systems[name]
	if entry.get("state", SystemState.UNINITIALIZED) != SystemState.STARTED:
		return

	var node: Node = entry.get("node") as Node
	if node != null and node.has_method("stop"):
		node.call("stop")

	entry["state"] = SystemState.STOPPED
	system_stopped.emit(name)

## 拓扑排序依赖解析（Kahn 算法）
func _resolve_dependency_order() -> Array[String]:
	var names: Array[String] = []
	for s_name in _systems:
		names.append(s_name)

	var in_degree: Dictionary = {}  # name -> int
	var graph: Dictionary = {}      # name -> Array[String]
	var queue: Array[String] = []
	var order: Array[String] = []

	# 初始化图
	for s_name in names:
		in_degree[s_name] = 0
		graph[s_name] = []

	# 建图：a 依赖 b → b → a
	for s_name in names:
		var entry: Dictionary = _systems[s_name]
		var deps: Array = entry.get("deps", [])
		for dep in deps:
			var dep_str: String = str(dep)
			if not _systems.has(dep_str):
				push_warning("SystemManager: system '%s' depends on unknown '%s'" % [s_name, dep_str])
				continue
			graph[dep_str].append(s_name)
			in_degree[s_name] = in_degree.get(s_name, 0) + 1

	# Kahn
	for s_name in names:
		if in_degree.get(s_name, 0) == 0:
			queue.push_back(s_name)

	while not queue.is_empty():
		var current: String = queue.pop_front()
		order.append(current)
		for neighbor in graph.get(current, []):
			in_degree[neighbor] = in_degree.get(neighbor, 0) - 1
			if in_degree[neighbor] == 0:
				queue.push_back(neighbor)

	if order.size() != names.size():
		push_error("SystemManager: circular dependency detected among systems")

	return order

## 自动解析依赖注入
func _inject_dependencies(name: String, entry: Dictionary) -> void:
	var node: Node = entry.get("node") as Node
	if node == null:
		return
	for dep_name in entry.get("deps", []):
		var dep_str: String = str(dep_name)
		var dep_entry: Dictionary = _systems.get(dep_str, {})
		if dep_entry.is_empty():
			# 尝试在 autoload 中查找
			var autoload: Node = _find_autoload(dep_str)
			if autoload != null:
				node.set(dep_str, autoload)
			continue
		var dep_node: Node = dep_entry.get("node") as Node
		if dep_node != null:
			node.set(dep_str, dep_node)

func _find_autoload(name: String) -> Node:
	# 遍历根节点查找 autoload（通常以大写开头）
	for child in get_tree().root.get_children():
		if child.name == name:
			return child
	# 在场景根节点查找
	if get_tree().current_scene != null:
		for child in get_tree().current_scene.get_children():
			if child.name == name:
				return child
	return null
