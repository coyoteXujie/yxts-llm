extends Node2D
class_name InkSplashEffect

## 程序化墨点飞溅粒子系统
## 不依赖外部资源，全部用 draw_circle/draw_line 绘制水墨粒子

const PARTICLE_COUNT := 16
const PARTICLE_LIFETIME := 1.2
const INK_COLOR := Color(0.05, 0.04, 0.03)
const PAPER_COLOR := Color(0.88, 0.82, 0.72)

var _particles: Array[Dictionary] = []
var _elapsed := 0.0
var _active := false

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
		p["vel"] = p["vel"] * 0.96  # 阻尼
		# 粒子扩散半径增长
		p["radius"] = float(p.get("radius", 4.0)) + delta * 6.0
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
		
		if is_splash:
			# 飞溅小墨点
			var splash_color := INK_COLOR
			splash_color.a = alpha * 0.7
			draw_circle(pos, maxf(1.0, radius * 0.3), splash_color)
		else:
			# 主体墨渍
			var ink_color := INK_COLOR
			ink_color.a = alpha * 0.50
			draw_circle(pos, radius, ink_color)
			# 边缘淡出
			var edge_color := PAPER_COLOR
			edge_color.a = alpha * 0.20
			draw_circle(pos, radius * 1.3, edge_color)

## 在指定位置播放墨点飞溅效果
## center: 中心位置（全局坐标）
## spread: 扩散范围
func splash_at(center: Vector2, spread: float = 120.0) -> void:
	_particles.clear()
	_elapsed = 0.0
	_active = true
	
	# 主体墨渍粒子
	for i in range(PARTICLE_COUNT):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(8.0, spread)
		var vel_mag := randf_range(40.0, 120.0)
		var p := {
			"pos": center + Vector2(cos(angle), sin(angle)) * randf_range(0.0, 10.0),
			"vel": Vector2(cos(angle), sin(angle)) * vel_mag,
			"radius": randf_range(4.0, 14.0),
			"life": PARTICLE_LIFETIME * randf_range(0.6, 1.0),
			"max_life": PARTICLE_LIFETIME,
			"alpha": 1.0,
			"is_splash": false,
		}
		_particles.append(p)
	
	# 飞溅小墨点
	for i in range(PARTICLE_COUNT * 2):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(4.0, spread * 0.7)
		var vel_mag := randf_range(60.0, 200.0)
		var p := {
			"pos": center + Vector2(cos(angle), sin(angle)) * randf_range(0.0, 5.0),
			"vel": Vector2(cos(angle), sin(angle)) * vel_mag,
			"radius": randf_range(1.5, 4.0),
			"life": PARTICLE_LIFETIME * randf_range(0.4, 0.8),
			"max_life": PARTICLE_LIFETIME,
			"alpha": 1.0,
			"is_splash": true,
		}
		_particles.append(p)
	
	set_process(true)
	queue_redraw()

func is_active() -> bool:
	return _active

## 清理所有粒子
func clear_splash() -> void:
	_particles.clear()
	_active = false
	set_process(false)
	queue_redraw()
