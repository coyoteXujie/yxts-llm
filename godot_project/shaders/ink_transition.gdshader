shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.03, 0.02, 0.01, 1.0);

// 噪声
float hash21(vec2 p) {
	p = fract(p * vec2(443.8975, 397.2973));
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
	vec2 uv = UV;
	
	// 墨迹溶解：progress 0→1 时，墨从边缘向中心吞噬
	// 用多频噪声制造"墨水渗透"形态
	float n1 = fbm(uv * 4.0);
	float n2 = fbm(uv * 8.0 + 1.0);
	float n = mix(n1, n2, 0.4);
	
	// 墨迹圈：从外向中心扩散
	vec2 cen = uv - 0.5;
	float dist = length(cen);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	cen.x *= aspect;
	
	// 边缘优先扩散 + 噪声扰动
	float edge_factor = 1.0 - dist * 1.4;
	float threshold = smoothstep(0.0, 1.0, (progress - edge_factor + n * 0.2) * 1.5);
	
	// 加一点边缘渗光
	float glow = 0.06 * smoothstep(0.0, 0.15, progress) * (1.0 - abs(threshold - 0.5) * 2.0);
	
	vec4 col = mix(vec4(0.0, 0.0, 0.0, 0.0), ink_color, threshold);
	col.rgb += glow * vec3(0.35, 0.25, 0.10);
	
	COLOR = col;
}
