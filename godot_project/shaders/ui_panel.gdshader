shader_type canvas_item;

// ── 水墨面板程序化Shader ─────────────────────────────
// 程序化生成水墨风格面板外框：不规则墨迹边缘 + 宣纸底纹 + 渗墨效果 + 金色内发光

uniform float corner_radius : hint_range(0.0, 0.25) = 0.06;
uniform float border_width : hint_range(0.0, 0.08) = 0.025;
uniform float ink_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 paper_color : source_color = vec4(0.860, 0.800, 0.700, 1.0);
uniform vec4 ink_color : source_color = vec4(0.045, 0.035, 0.025, 1.0);
uniform vec4 border_color : source_color = vec4(0.66, 0.50, 0.24, 0.90);
uniform vec4 glow_color : source_color = vec4(0.95, 0.75, 0.35, 0.50);
uniform vec4 bg_color : source_color = vec4(0.070, 0.060, 0.044, 0.92);
uniform bool show_bg = true;
uniform float border_noise_scale : hint_range(0.5, 5.0) = 2.5;
uniform float paper_noise_scale : hint_range(0.5, 10.0) = 6.0;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

// ── 噪声函数 ────────────────────────────────────────────
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

float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * smooth_noise(p);
		p = p * 2.0;
		a *= 0.5;
		if (i >= octaves) break;
	}
	return v;
}

// ── 有符号距离场：圆角矩形 ────────────────────────
float rounded_box_sdf(vec2 uv, vec2 size, float radius) {
	vec2 d = abs(uv) - size + radius;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

// ── 宣纸纹理 ─────────────────────────────────────────────
float paper_texture(vec2 uv) {
	float n1 = fbm(uv * paper_noise_scale + 0.5, 3);
	float n2 = fbm(uv * paper_noise_scale * 2.3 + 10.0, 2);
	float n3 = fbm(uv * paper_noise_scale * 4.7 + 20.0, 1);
	// 纤维感
	float fiber = sin(uv.x * 1200.0 + uv.y * 200.0) * 0.02;
	float fiber2 = sin(uv.y * 800.0 + uv.x * 300.0) * 0.015;
	return mix(n1, n2, 0.3) * 0.12 + n3 * 0.06 + fiber + fiber2;
}

// ── 墨迹边缘噪声 ──────────────────────────────────────
float ink_edge_noise(vec2 uv, float t) {
	float n = fbm(uv * border_noise_scale + vec2(3.0, 7.0) + t * 0.1, 3);
	// 额外细节
	float n2 = fbm(uv * border_noise_scale * 3.0 + vec2(13.0, 5.0) + t * 0.05, 2);
	return mix(n, n2, 0.3);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;

	float t = TIME + time_offset;
	vec2 size = vec2(0.5 * aspect, 0.5);

	// ── 圆角矩形SDF ─────────────────────────────────
	float radius = corner_radius * aspect;
	float sdf = rounded_box_sdf(uv, size, radius);

	// ── 墨迹边缘扰动 ─────────────────────────────────
	float edge_noise = ink_edge_noise(uv + 0.5, t);
	float edge_wobble = 0.015 * (edge_noise - 0.5) * 2.0 * ink_intensity;
	float edge_wobble2 = 0.008 * (fbm(uv * border_noise_scale * 1.5 + vec2(5.0, 11.0) + t * 0.08, 2) - 0.5) * 2.0;

	// ── 边框检测 ─────────────────────────────────────
	float border_sdf = abs(sdf) - border_width * 0.5;
	float border_edge = border_sdf + edge_wobble + edge_wobble2;

	// 边框抗锯齿
	float border_mask = 1.0 - smoothstep(-0.005, 0.005, border_edge);

	// ── 面板内部 ─────────────────────────────────────
	float interior = -sdf;
	float interior_edge = interior + edge_wobble + edge_wobble2;
	float interior_mask = smoothstep(-0.005, 0.005, interior_edge);

	// ── 渗墨效果（边缘羽化） ─────────────────────────
	float bleed = 0.0;
	if (interior_mask > 0.5) {
		float dist_to_edge = interior;
		float bleed_amount = 0.015 * ink_intensity;
		bleed = exp(-dist_to_edge * 60.0) * 0.15 * ink_intensity;
		bleed *= edge_noise * 0.8 + 0.4;
	}

	// ── 金色内发光 ──────────────────────────────────
	float glow = 0.0;
	if (interior_mask > 0.5) {
		float dist_to_edge = interior;
		glow = exp(-dist_to_edge * 80.0) * 0.4;
		glow *= 0.6 + 0.4 * sin(t * 0.5 + uv.x * 20.0 + uv.y * 15.0);
	}

	// ── 宣纸底纹 ─────────────────────────────────────
	float paper = paper_texture(uv + 0.5);
	vec3 paper_tint = paper_color.rgb + vec3(paper * 0.3);

	// ── 组合最终颜色 ─────────────────────────────────
	// 背景
	vec4 final_color = bg_color;
	if (!show_bg) {
		final_color.a = 0.0;
	}

	// 宣纸纹理覆盖内部
	if (interior_mask > 0.5) {
		vec3 base = mix(bg_color.rgb, paper_tint, 0.08);
		final_color.rgb = mix(final_color.rgb, base, 0.5);
	}

	// 渗墨
	final_color.rgb += bleed * ink_color.rgb;

	// 金色内发光
	final_color.rgb += glow * glow_color.rgb * glow_color.a;

	// 边框
	if (border_mask > 0.5) {
		// 墨色混合金边
		float gold_factor = 0.5 + 0.5 * sin(t * 0.3 + uv.x * 30.0 + uv.y * 20.0) * 0.3;
		vec3 border_final = mix(ink_color.rgb, border_color.rgb, gold_factor);
		float border_ink_bleed = edge_noise * 0.2;
		final_color.rgb = mix(final_color.rgb, border_final + vec3(border_ink_bleed * 0.1), border_mask);
		final_color.a = max(final_color.a, border_mask * border_color.a);
	}

	// 外部透明
	if (interior_mask < 0.5 && border_mask < 0.5) {
		final_color.a = 0.0;
	}

	COLOR = final_color;
}
