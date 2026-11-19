shader_type canvas_item;

// ── 物品格子程序化Shader ──────────────────────────────
// 水墨边框 + 宣纸底纹 + 品质边框颜色叠加

uniform float corner_radius : hint_range(0.0, 0.2) = 0.08;
uniform float border_width : hint_range(0.0, 0.06) = 0.025;
uniform vec4 bg_color : source_color = vec4(0.10, 0.085, 0.06, 0.92);
uniform vec4 border_color : source_color = vec4(0.68, 0.53, 0.28, 0.88);
uniform vec4 quality_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float quality_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 icon_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool has_icon = false;
uniform vec4 paper_tint : source_color = vec4(0.860, 0.800, 0.700, 0.06);
uniform float noise_scale : hint_range(0.5, 5.0) = 2.0;

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

// ── 宣纸纹理 ─────────────────────────────────────────────
float paper_texture(vec2 uv) {
	float n1 = fbm(uv * noise_scale * 2.0 + 0.5);
	float n2 = fbm(uv * noise_scale * 5.0 + 10.0) * 0.3;
	float fiber = sin(uv.x * 900.0 + uv.y * 150.0) * 0.02;
	return n1 * 0.1 + n2 * 0.06 + fiber;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;

	vec2 size = vec2(0.5 * aspect, 0.5);
	float radius = corner_radius * aspect;

	// ── 圆角距离场 ───────────────────────────────────
	vec2 d = abs(uv) - size + radius;
	float sdf = min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;

	// ── 墨迹边缘扰动 ─────────────────────────────────
	float edge_noise = fbm(uv * noise_scale + vec2(2.0, 5.0));
	float edge_wobble = 0.008 * (edge_noise - 0.5) * 2.0;

	// ── 边框 ─────────────────────────────────────────
	float border_sdf = abs(sdf) - border_width * 0.5;
	float border_mask = 1.0 - smoothstep(-0.004, 0.004, border_sdf + edge_wobble);

	// ── 内部区域 ─────────────────────────────────────
	float interior = -sdf + edge_wobble;
	float interior_mask = smoothstep(-0.004, 0.004, interior);

	// ── 宣纸底纹 ─────────────────────────────────────
	float paper = paper_texture(uv + 0.5);

	// ── 组合 ─────────────────────────────────────────
	vec4 final_color = bg_color;

	// 宣纸纹理
	final_color.rgb += paper_tint.rgb * paper * 3.0;

	// 品质边框叠加
	vec3 border_final = border_color.rgb;
	if (quality_intensity > 0.01) {
		float q_glow = 0.5 + 0.5 * sin(TIME * 1.5 + uv.x * 30.0 + uv.y * 20.0);
		border_final = mix(border_final, quality_color.rgb, quality_intensity * (0.6 + 0.4 * q_glow));
	}

	// 边框绘制
	if (border_mask > 0.5) {
		final_color.rgb = mix(final_color.rgb, border_final, border_mask * border_color.a);
		final_color.a = max(final_color.a, border_mask * border_color.a);
	}

	// 外部透明
	if (interior_mask < 0.5 && border_mask < 0.5) {
		final_color.a = 0.0;
	}

	COLOR = final_color;
}
