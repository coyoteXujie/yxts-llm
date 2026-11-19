extends Node2D
class_name InkSplashEffect

## 三级水墨交互反馈系统
##
## 三级墨迹：
## - MICRO（微）：点击、按键反馈（小粒子，快速消散）
## - MID（中）：面板打开、NPC对话、道具拾取（中粒子，半秒消散）
## - MACRO（大）：技能释放、场景转场、重要事件（大粒子，全屏扩散）
##
## 保持与旧 API 的兼容性：splash_at()、is_active()、clear_splash()

# ── 粒子和颜色常量 ─────────────────────────────────────
enum SplashLevel { MICRO, MID, MACRO }

const INK_COLOR := Color(0.05, 0.04, 0.03)
const PAPER_COLOR := Color(0.88, 0.82, 0.72)

# ── 三级粒子参数 ────────────────────────────────────────
const LEVEL_CONFIG := {
	SplashLevel.MICRO: {
		"main_count": 4,
		"splash_count": 8,
		"lifetime": 0.4,
		"spread": 20.0,
		"main_radius": Vector2(2.0, 5.0),
		"splash_radius": Vector2(1.0, 2.5),
		"vel_range": Vector2(20.0, 60.0),
		"splash_vel_range": Vector2(30.0, 80.0),
		"damping": 0.92,
	},
	SplashLevel.MID: {
		"main_count": 10,
		"splash_count": 16,
		"lifetime": 0.7,
		"spread": 80.0,
		"main_radius": Vector2(3.0, 10.0),
		"splash_radius": Vector2(1.0, 4.0),
		"vel_range": Vector2(30.0, 100.0),
		"splash_vel_range": Vector2(50.0, 160.0),
		"damping": 0.95,
	},
	SplashLevel.MACRO: {
		"main_count": 24,
		"splash_count": 36,
		"lifetime": 1.2,
		"spread": 200.0,
		"main_radius": Vector2(6.0, 18.0),
		"splash_radius": Vector2(2.0, 6.0),
		"vel_range": Vector2(60.0, 180.0),
		"splash_vel_range": Vector2(80.0, 280.0),
		"damping": 0.96,
	},
}

const PARTICLE_LIFETIME := 1.2
const PARTICLE_COUNT := 16

var _particles: Array[Dictionary] = []
var _elapsed := 0.0
var _active := false
var _current_level := SplashLevel.MID

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_elapsed += delta
	var all_dead := true
	for p in _particles:
		var life := float(p.get("life", 0.0))
		if life <= 0.0:
			continue
		p["life"] = life - delta
		p["alpha"] = clampf(float(p.get("life", 0.0)) / float(p.get("max_life", 1.0)), 0.0, 1.0)
		p["pos"] = p["pos"] + p["vel"] * delta
		var damping := float(p.get("damping", 0.95))
		p["vel"] = p["vel"] * damping
		p["radius"] = float(p.get("radius", 4.0)) + delta * float(p.get("grow_rate", 6.0))
		all_dead = false

	if all_dead and _elapsed > 0.1:
		_active = false
		set_process(false)
		queue_redraw()
		return

	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	for p in _particles:
		var life := float(p.get("life", 0.0))
		if life <= 0.0:
			continue
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var radius := float(p.get("radius", 4.0))
		var alpha := float(p.get("alpha", 1.0))
		var is_splash := bool(p.get("is_splash", false))
		var ink_variation := float(p.get("ink_variation", 0.0))

		if is_splash:
			var splash_color := INK_COLOR
			splash_color.a = alpha * 0.7
			draw_circle(pos, maxf(1.0, radius * 0.3), splash_color)
		else:
			# 主体墨渍——带深浅变化
			var ink := INK_COLOR
			ink.r += ink_variation * 0.03
			ink.g += ink_variation * 0.02
			ink.b += ink_variation * 0.01
			ink.a = alpha * 0.50
			draw_circle(pos, radius, ink)
			# 边缘淡出
			var edge_color := PAPER_COLOR
			edge_color.a = alpha * 0.20
			draw_circle(pos, radius * 1.3, edge_color)

# ══════════════════════════════════════════════════════════════
# 三级接口
# ══════════════════════════════════════════════════════════════

## 微量墨迹反馈——点击、按键、小交互
func splash_micro(center: Vector2) -> void:
	_splash_at_level(center, SplashLevel.MICRO)

## 中等墨迹反馈——面板打开、NPC对话、道具拾取
func splash_mid(center: Vector2) -> void:
	_splash_at_level(center, SplashLevel.MID)

## 大量墨迹反馈——技能释放、场景转场、重大事件
func splash_macro(center: Vector2) -> void:
	_splash_at_level(center, SplashLevel.MACRO)

# ══════════════════════════════════════════════════════════════
# 旧接口（兼容）
# ══════════════════════════════════════════════════════════════

## 在指定位置播放墨点飞溅效果（旧接口——默认MID级别）
## center: 中心位置（全局坐标）
## spread: 扩散范围（旧接口参数，新接口用级别控制）
func splash_at(center: Vector2, spread: float = 120.0) -> void:
	# 旧接口用spread判断级别
	if spread <= 40.0:
		_splash_at_level(center, SplashLevel.MICRO)
	elif spread >= 180.0:
		_splash_at_level(center, SplashLevel.MACRO)
	else:
		_splash_at_level(center, SplashLevel.MID)

func is_active() -> bool:
	return _active

## 清理所有粒子
func clear_splash() -> void:
	_particles.clear()
	_active = false
	set_process(false)
	queue_redraw()

# ── 内部实现 ────────────────────────────────────────────

func _splash_at_level(center: Vector2, level: SplashLevel) -> void:
	_particles.clear()
	_elapsed = 0.0
	_active = true
	_current_level = level

	var cfg: Dictionary = LEVEL_CONFIG[level]
	var main_count := int(cfg["main_count"])
	var splash_count := int(cfg["splash_count"])
	var lifetime := float(cfg["lifetime"])
	var spread := float(cfg["spread"])
	var main_radius := cfg["main_radius"] as Vector2
	var splash_radius := cfg["splash_radius"] as Vector2
	var vel_range := cfg["vel_range"] as Vector2
	var splash_vel_range := cfg["splash_vel_range"] as Vector2
	var damping := float(cfg["damping"])

	# 主体墨渍
	for i in range(main_count):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(2.0, spread * 0.6)
		var vel_mag := randf_range(vel_range.x, vel_range.y)
		_particles.append({
			"pos": center + Vector2(cos(angle), sin(angle)) * randf_range(0.0, dist * 0.3),
			"vel": Vector2(cos(angle), sin(angle)) * vel_mag,
			"radius": randf_range(main_radius.x, main_radius.y),
			"life": lifetime * randf_range(0.6, 1.0),
			"max_life": lifetime,
			"alpha": 1.0,
			"is_splash": false,
			"damping": damping,
			"grow_rate": 3.0 + lifetime * 3.0,
			"ink_variation": randf_range(-1.0, 1.0),
		})

	# 飞溅小墨点
	for i in range(splash_count):
		var angle := randf_range(0.0, TAU)
		var vel_mag := randf_range(splash_vel_range.x, splash_vel_range.y)
		_particles.append({
			"pos": center + Vector2(cos(angle), sin(angle)) * randf_range(0.0, 3.0),
			"vel": Vector2(cos(angle), sin(angle)) * vel_mag,
			"radius": randf_range(splash_radius.x, splash_radius.y),
			"life": lifetime * randf_range(0.35, 0.7),
			"max_life": lifetime,
			"alpha": 1.0,
			"is_splash": true,
			"damping": damping,
			"grow_rate": 1.0 + lifetime * 2.0,
			"ink_variation": randf_range(-0.5, 0.5),
		})

	set_process(true)
	queue_redraw()
