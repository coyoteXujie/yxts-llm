shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.04, 0.035, 0.025, 1.0);
uniform vec4 paper_color : source_color = vec4(0.14, 0.11, 0.08, 1.0);

// 简化噪声（gl_compatibility友好）
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

// 简化FBM（无mat2）
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
	vec2 uv = UV - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;
	
	// 墨滴扩散半径
	float radius = progress * 0.8;
	
	// 边缘噪声渗化
	float noise_val = fbm(uv * 6.0 + progress * 2.0);
	float edge_wobble = 0.06 * (noise_val - 0.5);
	float edge_width = 0.03 + 0.04 * (1.0 - progress);
	float dist = length(uv);
	
	float ink_mask = smoothstep(radius + edge_wobble + edge_width, radius + edge_wobble - edge_width, dist);
	
	// 内部微纹理
	float inner_noise = fbm(uv * 12.0 + 1.0) * 0.15;
	ink_mask = mix(ink_mask, ink_mask + inner_noise, 0.3 * smoothstep(0.0, radius * 0.5, dist));
	
	// 混合
	vec4 col = mix(paper_color, ink_color, ink_mask);
	
	// 边缘渗化光晕
	float glow = 0.08 * exp(-abs(dist - radius - edge_wobble) * 80.0);
	col.rgb += glow * vec3(0.3, 0.22, 0.12);
	
	COLOR = col;
}
