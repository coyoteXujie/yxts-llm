shader_type canvas_item;

// ── 水墨金色按钮程序化Shader ─────────────────────────
// 水墨笔触边缘 + 做旧金箔纹理 + 状态光晕（hover/pressed/disabled）

uniform float corner_radius : hint_range(0.0, 0.2) = 0.08;
uniform float ink_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 base_color : source_color = vec4(0.220, 0.145, 0.060, 0.88);
uniform vec4 gold_color : source_color = vec4(0.98, 0.72, 0.28, 0.88);
uniform vec4 border_ink : source_color = vec4(0.045, 0.035, 0.025, 0.70);
uniform vec4 glow_color : source_color = vec4(0.98, 0.84, 0.30, 0.35);
uniform vec4 hover_tint : source_color = vec4(0.08, 0.05, 0.02, 0.0);
uniform vec4 pressed_tint : source_color = vec4(0.0, 0.0, 0.0, 0.20);
uniform float state_hover : hint_range(0.0, 1.0) = 0.0;
uniform float state_pressed : hint_range(0.0, 1.0) = 0.0;
uniform float state_disabled : hint_range(0.0, 1.0) = 0.0;

// ── 噪声 ────────────────────────────────────────────────
float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * smooth_noise(p);
		p = p * 2.0;
		a *= 0.5;
	}
	return v;
}

// ── 做旧金箔纹理 ────────────────────────────────────────
float gold_texture(vec2 uv) {
	float n1 = fbm(uv * 5.0 + 0.5);
	float n2 = fbm(uv * 12.0 + 5.0) * 0.3;
	float scratch = sin(uv.x * 800.0 + uv.y * 200.0) * sin(uv.y * 600.0 + uv.x * 300.0) * 0.04;
	float speckle = fbm(uv * 30.0 + 50.0) * 0.08;
	return n1 * 0.15 + n2 * 0.1 + scratch + speckle;
}

// ── 墨笔触纹理 ──────────────────────────────────────────
float ink_brush(vec2 uv, float t) {
	float n1 = fbm(uv * 3.0 + vec2(1.0, 2.0) + t * 0.05);
	float n2 = fbm(uv * 6.0 + vec2(10.0, 20.0) + t * 0.03);
	float streak = sin(uv.x * 100.0 + uv.y * 40.0 + n1 * 5.0) * 0.06;
	return n1 * 0.3 + n2 * 0.15 + streak;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;

	float t = TIME;
	vec2 size = vec2(0.5 * aspect, 0.5);
	float radius = corner_radius * aspect;

	// ── 圆角距离场 ───────────────────────────────────
	vec2 d = abs(uv) - size + radius;
	float sdf = min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;

	// ── 墨笔触边缘 ───────────────────────────────────
	float brush = ink_brush(uv + 0.5, t);
	float edge_wobble = 0.012 * (brush - 0.5) * 2.0 * ink_intensity;

	// ── 内部区域 ─────────────────────────────────────
	float interior = -sdf + edge_wobble;
	float interior_mask = smoothstep(-0.004, 0.004, interior);

	// ── 边框墨迹 ─────────────────────────────────────
	float border_dist = abs(sdf) - 0.018;
	float border_wobble = 0.01 * (fbm(uv * 4.0 + vec2(7.0, 3.0) + t * 0.05) - 0.5) * 2.0;
	float border_mask = 1.0 - smoothstep(-0.004, 0.004, border_dist + border_wobble + edge_wobble);

	// ── 基础颜色 ─────────────────────────────────────
	vec3 base = base_color.rgb;

	// 做旧金箔纹理
	float gold_tex = gold_texture(uv + 0.5);
	vec3 gold_base = gold_color.rgb + vec3(gold_tex * 0.5);
	vec3 bg_color = mix(base, gold_base, 0.3);

	// ── 状态叠加 ─────────────────────────────────────
	float active = 1.0 - state_disabled;

	// Hover
	vec3 state_color = bg_color;
	float hover_glow = 0.0;
	if (state_hover > 0.5 && state_disabled < 0.5) {
		// 金色光晕增强
		hover_glow = 0.3 + 0.2 * sin(t * 2.0 + uv.x * 15.0 + uv.y * 10.0);
		state_color = mix(bg_color, gold_color.rgb + vec3(gold_tex * 0.3), 0.15 + hover_glow * 0.1);
	}

	// Pressed
	if (state_pressed > 0.5) {
		state_color = mix(state_color, state_color * 0.7, 0.3);
	}

	// Disabled
	if (state_disabled > 0.5) {
		float desat = dot(state_color, vec3(0.299, 0.587, 0.114));
		state_color = mix(state_color, vec3(desat), 0.5);
		state_color = mix(state_color, vec3(0.1), 0.3);
	}

	// ── 内发光 ─────────────────────────────────────
	float glow = 0.0;
	if (interior_mask > 0.5 && state_disabled < 0.5) {
		float dist_to_edge = -sdf;
		glow = exp(-dist_to_edge * 70.0) * 0.35;
		glow *= 0.7 + 0.3 * sin(t * 0.8 + uv.x * 25.0 + uv.y * 18.0);
		if (state_hover > 0.5) {
			glow *= 1.5;
		}
	}

	// ── 组合 ─────────────────────────────────────────
	vec4 final_color = vec4(state_color * active, base_color.a * active);

	// 金箔变化
	final_color.rgb += gold_tex * 0.15;

	// 发光
	final_color.rgb += glow * glow_color.rgb * glow_color.a * 1.5;

	// 边框
	if (border_mask > 0.5 && state_disabled < 0.5) {
		vec3 border_col = mix(border_ink.rgb, gold_color.rgb, 0.4 + 0.3 * gold_tex);
		final_color.rgb = mix(final_color.rgb, border_col, border_mask);
		final_color.a = max(final_color.a, border_mask * border_ink.a);
	}

	// 外部透明
	if (interior_mask < 0.5 && border_mask < 0.5) {
		final_color.a = 0.0;
	}

	COLOR = final_color;
}
