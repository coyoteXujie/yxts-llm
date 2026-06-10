extends RefCounted
class_name StageSurfaceDetailRenderer

const StageVisualProfile = preload("res://scripts/shared/stage_visual_profile.gd")

static func draw_building_surface_detail(
	canvas: CanvasItem,
	rect: Rect2,
	base_color: Color,
	x: int,
	y: int,
	stroke_count: int,
	dot_count: int,
	alpha: float,
	seed_base: int,
	line_jitter: float,
	noise_scale: float = StageVisualProfile.WORLD_BUILDING_SURFACE_NOISE_SCALE
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var safe_strokes := maxi(0, stroke_count)
	var safe_dots := maxi(0, dot_count)
	var base := Color(base_color.r, base_color.g, base_color.b)

	for i in range(safe_strokes):
		var phase := float(i) / float(max(1, safe_strokes))
		var line_y := rect.position.y + rect.size.y * (0.14 + phase * 0.74 + StageVisualProfile.tile_noise(x + i, y + i * 3, seed_base + 1) * noise_scale)
		var line_start_x := rect.position.x + rect.size.x * (0.12 + StageVisualProfile.tile_noise(x + i * 3, y, seed_base + 2) * 0.76)
		var line_end_x := rect.position.x + rect.size.x * (0.12 + StageVisualProfile.tile_noise(x + i * 5, y + 9, seed_base + 3) * 0.76)
		var jitter := (StageVisualProfile.tile_noise(x + 13, y + i * 17, seed_base + 4) - 0.5) * line_jitter
		var stroke_alpha := alpha * (0.82 + (1.0 - phase) * 0.26)
		canvas.draw_line(
			Vector2(line_start_x, line_y),
			Vector2(line_end_x, line_y + jitter),
			Color(base.r, base.g, base.b, stroke_alpha),
			0.75 + phase * 0.18
		)

	for i in range(safe_dots):
		var x_ratio := 0.20 + StageVisualProfile.tile_noise(x + i * 9, y + i * 13, seed_base + 10) * 0.60
		var y_ratio := 0.18 + StageVisualProfile.tile_noise(y + i * 11, x + i * 17, seed_base + 11) * 0.62
		var radius := 1.0 + StageVisualProfile.tile_noise(x + i, y + 3, seed_base + 12) * 1.0
		var glow := 0.32 + StageVisualProfile.tile_noise(x + 27, y + i * 4, seed_base + 13) * 0.44
		canvas.draw_circle(
			rect.position + Vector2(
				clampf(rect.size.x * x_ratio, 0.0, rect.size.x),
				clampf(rect.size.y * y_ratio, 0.0, rect.size.y)
			),
			radius,
			Color(base.r, base.g, base.b, alpha * glow)
		)

	var weather_hint := StageVisualProfile.tile_noise(x + seed_base, y + seed_base, seed_base + 20)
	if weather_hint > 0.68:
		var seam_count := 1 if safe_strokes < 2 else 2
		for i in range(seam_count):
			var sx := rect.position.x + rect.size.x * (0.16 + float(i) * 0.34 + StageVisualProfile.tile_noise(x + i * 2, y + seed_base + i, seed_base + 21) * 0.04)
			var sy := rect.position.y + rect.size.y * (0.26 + float(i) * 0.24 + StageVisualProfile.tile_noise(y + i * 5, x + seed_base, seed_base + 22) * 0.14)
			var ex := sx + rect.size.x * (0.10 + StageVisualProfile.tile_noise(x + i * 4, y + seed_base + 5, seed_base + 23) * 0.16)
			var ey := sy + rect.size.y * (-0.05 + StageVisualProfile.tile_noise(x + i * 6, y + seed_base + 7, seed_base + 24) * 0.12)
			canvas.draw_line(
				Vector2(sx, sy),
				Vector2(ex, ey),
				Color(base.r, base.g, base.b, alpha * 0.35),
				1.06
			)


static func draw_building_facade_detail(
	canvas: CanvasItem,
	rect: Rect2,
	base_color: Color,
	x: int,
	y: int,
	pillar_count: int,
	window_rows: int,
	window_columns: int,
	window_alpha: float,
	shadow_alpha: float,
	seed_base: int,
	line_jitter: float,
	noise_scale: float = StageVisualProfile.WORLD_BUILDING_FACADE_NOISE_SCALE
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var safe_columns := maxi(1, window_columns)
	var safe_rows := maxi(1, window_rows)
	var safe_pillars := maxi(1, pillar_count)
	var base := Color(base_color.r, base_color.g, base_color.b)
	var inset_x := maxf(2.0, rect.size.x * 0.07)
	var inset_y_top := maxf(2.0, rect.size.y * 0.15)
	var inset_y_bottom := maxf(1.6, rect.size.y * 0.09)
	var eave_y := rect.position.y + inset_y_top + StageVisualProfile.tile_noise(x + seed_base, y - seed_base, seed_base + 1) * rect.size.y * 0.05
	var eave_left := rect.position.x + inset_x
	var eave_right := rect.position.x + rect.size.x - inset_x
	var eave_warp := line_jitter * 0.04
	for i in range(2):
		var phase := float(i) * 0.58
		canvas.draw_line(
			Vector2(
				eave_left + rect.size.x * 0.02 * phase,
				eave_y + phase * 2.0 + StageVisualProfile.tile_noise(x + i * 7, y, seed_base + 4) * eave_warp
			),
			Vector2(
				eave_right + rect.size.x * -0.02 * phase,
				eave_y + phase * 1.5 + StageVisualProfile.tile_noise(x + i * 9, y + seed_base, seed_base + 5) * eave_warp
			),
			Color(base.r, base.g, base.b, shadow_alpha * 0.85),
			1.2 + phase
		)

	var spacing := rect.size.x / float(safe_pillars + 1)
	for i in range(safe_pillars):
		var px := rect.position.x + spacing * float(i + 1) + StageVisualProfile.tile_noise(x + i * 13, y + i, seed_base + 6) * rect.size.x * 0.05
		var top_y := rect.position.y + inset_y_top + 2.5
		var bottom_y := rect.position.y + rect.size.y - inset_y_bottom - StageVisualProfile.tile_noise(x + i * 17, y + seed_base + i, seed_base + 7) * rect.size.y * 0.02
		var bend := (StageVisualProfile.tile_noise(x + i * 19, y + i * 5, seed_base + 8) - 0.5) * line_jitter * 0.1
		canvas.draw_line(
			Vector2(px, top_y),
			Vector2(px + bend, bottom_y),
			Color(base.r, base.g, base.b, window_alpha * 1.3),
			1.0 + i % 2 * 0.4
		)

	var base_band_y := rect.position.y + rect.size.y - inset_y_bottom
	for row in range(safe_rows):
		var row_y := rect.position.y + rect.size.y * (0.28 + float(row) * 0.38 / float(safe_rows))
		var row_amp := rect.size.y * 0.014 * (1.0 + StageVisualProfile.tile_noise(x + row * 3, y + row + seed_base, seed_base + 9) * 1.2)
		var row_sway := (StageVisualProfile.tile_noise(x + row * 11, y, seed_base + 10) - 0.5) * noise_scale * rect.size.x * 0.7
		var row_window_h := rect.size.y * 0.10
		for col in range(safe_columns):
			var window_seed := StageVisualProfile.tile_noise(x + row * 7 + col * 11, y + col * 5, seed_base + 20)
			if window_seed < 0.18:
				continue
			var col_x := rect.position.x + inset_x + rect.size.x * (0.24 + float(col) * 0.52 / float(safe_columns))
			var window_w := rect.size.x * (0.15 + StageVisualProfile.tile_noise(x + row * 5, y + col * 7, seed_base + 11) * 0.10)
			var window_h := rect.size.y * (0.10 + StageVisualProfile.tile_noise(x + col * 9, y + row * 2, seed_base + 12) * 0.11)
			var window_rect := Rect2(
				Vector2(col_x - window_w * 0.5 + row_sway, row_y + row_amp * (col % 2)),
				Vector2(window_w, window_h)
			)
			row_window_h = window_h
			if window_rect.position.y <= base_band_y - window_h:
				var tint := base_color.darkened(0.08 + StageVisualProfile.tile_noise(x + col * 3, y + row * 13, seed_base + 13) * 0.12)
				canvas.draw_rect(window_rect, Color(tint.r, tint.g, tint.b, window_alpha), false, 1.0)
				var cross_alpha := window_alpha * (0.6 + window_seed * 0.8)
				canvas.draw_line(window_rect.position + Vector2(window_w * 0.5, 0.0), window_rect.position + Vector2(window_w * 0.5, window_h), Color(tint.r, tint.g, tint.b, cross_alpha), 0.8)
				canvas.draw_line(window_rect.position + Vector2(0.0, window_h * 0.5), window_rect.position + Vector2(window_w, window_h * 0.5), Color(tint.r, tint.g, tint.b, cross_alpha * 0.8), 0.7)
			if row == safe_rows - 1:
				var ledge := row_y + row_window_h * 0.95
				canvas.draw_line(
					Vector2(rect.position.x + inset_x, ledge + row_amp * 0.4),
					Vector2(eave_right - 1.0, ledge + row_amp * 0.2),
					Color(base.r, base.g, base.b, shadow_alpha * 0.7),
					1.0
				)

	var base_shade_top := rect.position.y + rect.size.y - inset_y_bottom * 0.2
	for i in range(3):
		var sx := rect.position.x + inset_x + rect.size.x * (float(i) * 0.22 + StageVisualProfile.tile_noise(x + i * 7, y + seed_base + i, seed_base + 14) * 0.02)
		var ex := rect.position.x + rect.size.x - inset_x - rect.size.x * (0.14 - i * 0.03)
		var shade_alpha := shadow_alpha * (0.95 - float(i) * 0.22)
		canvas.draw_line(
			Vector2(sx, base_shade_top + float(i) * 1.2),
			Vector2(ex, base_shade_top + float(i) * 1.5),
			Color(base.r, base.g, base.b, shade_alpha),
			1.0 + float(i) * 0.2
		)
