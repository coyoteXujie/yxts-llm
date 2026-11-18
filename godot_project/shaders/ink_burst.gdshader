shader_type canvas_item;

// ─── 墨爆裂特效 v2 ───
// 增强版：噪声渗化 + 飞溅墨点 + 边缘光晕 + 纹理感
// ────────────────────────────

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burst_color : source_color = vec4(0.03, 0.02, 0.01, 0.6);
uniform vec4 glow_color : source_color = vec4(0.98, 0.88, 0.62, 0.15);
uniform float time : hint_range(0.0, 10.0) = 0.0;

// 噪声
float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			   mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
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

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;
	float d = length(uv);

	// 主体墨爆裂圈
	float burst = 1.0 - smoothstep(0.0, 0.9, d);
	float ring = exp(-d * d * 10.0) * 0.6;

	// 噪声扰动边缘 — 墨汁渗化纹理
	float noise_val = fbm(uv * 6.0 + time * 0.1);
	float edge_wobble = 0.08 * (noise_val - 0.5);
	float burst_ink = 1.0 - smoothstep(0.0, 0.85 + edge_wobble, d);

	// 飞溅墨点 (噪声采样)
	float dot_grid = smooth_noise(uv * 20.0 + time * 0.05);
	float dots = smoothstep(0.2, 0.7, dot_grid) * (1.0 - smoothstep(0.3, 0.9, d)) * 0.3;

	// 内部纹理 — 模拟纸张纤维
	float inner = smooth_noise(uv * 12.0 + 1.0) * 0.10;
	
	// 组合
	float alpha = max(0.0, burst * 0.5 + burst_ink * 0.4 + ring + dots + inner);
	alpha *= intensity;

	// 边缘光晕
	float glow = 0.08 * exp(-abs(d - 0.65) * 40.0) * intensity * 0.6;

	vec4 col = vec4(burst_color.rgb, alpha);
	col.rgb += glow * glow_color.rgb;

	COLOR = col;
}
