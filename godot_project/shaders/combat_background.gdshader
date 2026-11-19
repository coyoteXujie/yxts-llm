shader_type canvas_item;

// ─── 战斗背景：GPU 程序化水墨风格 ───
// 替代: stage_backdrop_renderer.gd + _draw_background + _draw_parallax_silhouette
// ──────────────────────────────────────

uniform vec4 terrain_color : source_color = vec4(0.35, 0.34, 0.25, 1.0);
uniform vec4 accent_color : source_color = vec4(0.86, 0.65, 0.34, 1.0);
uniform float time;
uniform float pulse_time;
// terrain_type: 0=wild, 1=snow, 2=desert, 3=forest, 4=water, 5=city, 6=sect
uniform int terrain_type;
uniform float backdrop_alpha;

// ─── 噪声工具 ───
float hash21(vec2 p) {
	p = fract(p * vec2(443.8975, 397.2973));
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

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * smooth_noise(p);
		p = p * 2.0;
		a *= 0.5;
	}
	return v;
}

// ─── 调色板 ───
vec4 sky_color;
vec4 far_color;
vec4 mid_color;
vec4 floor_color;
vec4 accent;

void init_palette() {
	accent = accent_color;
	if (terrain_type == 1) { // snow
		sky_color = vec4(0.48, 0.58, 0.66, 0.38);
		far_color = vec4(0.34, 0.42, 0.50, 0.42);
		mid_color = vec4(0.52, 0.58, 0.62, 0.34);
		floor_color = vec4(0.58, 0.64, 0.66, 1.0);
		accent = vec4(0.70, 0.90, 1.0, 1.0);
	} else if (terrain_type == 2) { // desert
		sky_color = vec4(0.58, 0.46, 0.28, 0.36);
		far_color = vec4(0.46, 0.32, 0.18, 0.42);
		mid_color = vec4(0.63, 0.46, 0.24, 0.34);
		floor_color = vec4(0.56, 0.42, 0.24, 1.0);
		accent = vec4(0.95, 0.72, 0.36, 1.0);
	} else if (terrain_type == 3) { // forest
		sky_color = vec4(0.22, 0.34, 0.24, 0.34);
		far_color = vec4(0.06, 0.16, 0.08, 0.44);
		mid_color = vec4(0.12, 0.25, 0.12, 0.36);
		floor_color = vec4(0.26, 0.34, 0.20, 1.0);
		accent = vec4(0.50, 0.76, 0.38, 1.0);
	} else if (terrain_type == 4) { // water
		sky_color = vec4(0.27, 0.42, 0.47, 0.34);
		far_color = vec4(0.12, 0.22, 0.26, 0.42);
		mid_color = vec4(0.18, 0.32, 0.36, 0.34);
		floor_color = vec4(0.30, 0.39, 0.36, 1.0);
		accent = vec4(0.58, 0.82, 0.86, 1.0);
	} else if (terrain_type == 5 || terrain_type == 6) { // city / sect
		sky_color = vec4(0.29, 0.34, 0.31, 0.34);
		far_color = vec4(0.10, 0.12, 0.10, 0.42);
		mid_color = vec4(0.16, 0.18, 0.13, 0.36);
		floor_color = vec4(terrain_color.rgb * 1.1, 1.0);
	} else { // wild/plain
		sky_color = vec4(0.29, 0.34, 0.31, 0.34);
		far_color = vec4(0.10, 0.12, 0.10, 0.42);
		mid_color = vec4(0.16, 0.18, 0.13, 0.36);
		floor_color = vec4(terrain_color.rgb * 1.08, 1.0);
	}
}

// ─── 山脊线 ───
float mountain_profile(float x, float layer, float roughness) {
	float base = sin(x * 1.25 + layer * 2.0) * 0.42;
	float detail = smooth_noise(vec2(x * 3.0 + layer, layer * 1.7)) * 0.18;
	float fine = smooth_noise(vec2(x * 6.0 - layer, layer * 0.5 + time * 0.01)) * 0.06;
	return base + detail * roughness + fine * roughness * 0.5;
}

// ─── 屋顶剪影 ───
float roofline_profile(float x) {
	float r = 0.0;
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float cx = 0.17 + fi * 0.17;
		float w = 0.12 + mod(fi * 1.3, 0.04);
		float h = 0.04 + mod(fi * 0.7, 0.02);
		float roof = 1.0 - abs(x - cx) / w;
		roof = smoothstep(0.0, 1.0, roof);
		r = max(r, roof * h);
	}
	return r;
}

void fragment() {
	init_palette();
	vec2 uv = UV;
	vec4 col = vec4(0.0);
	
	float horizon = 0.43;
	float ground_start = 0.48;
	
	// ─── 天空渐变 ───
	float sky_t = uv.y / horizon;
	float sky_alpha = clamp(1.0 - sky_t, 0.0, 1.0);
	vec3 sky_grad = mix(terrain_color.rgb * 0.28, sky_color.rgb, sky_t * 0.6);
	col.rgb += sky_grad * sky_alpha * backdrop_alpha;
	col.a += sky_alpha * 0.34;
	
	// ─── 水墨晕染纹理(天空层微纹) ───
	float ink_tex = fbm3(vec2(uv.x * 8.0, uv.y * 12.0 + time * 0.02));
	col.rgb += mix(vec3(0.0), vec3(0.04, 0.03, 0.02), ink_tex * (1.0 - uv.y)) * backdrop_alpha;
	
	// ─── 远山 (3层) ───
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float layer_t = fi / 2.0;
		float mtn_y = horizon - 0.08 - fi * 0.035;
		float roughness = 0.28 + fi * 0.06;
		float height = mountain_profile(uv.x * 1.5 + fi * 0.3, fi, roughness) * (0.12 - fi * 0.015);
		float mtn_alpha = smoothstep(mtn_y - height, mtn_y, uv.y) - smoothstep(mtn_y, mtn_y + 0.01, uv.y);
		mtn_alpha *= (0.30 + fi * 0.06) * backdrop_alpha;
		vec3 mtn_col = mix(far_color.rgb, mid_color.rgb, layer_t * 0.5);
		col.rgb += mtn_col * mtn_alpha * 0.6;
		col.a += mtn_alpha * 0.3;
	}
	
	// ─── 城市屋顶剪影 ───
	if (terrain_type == 5 || terrain_type == 6) {
		float roof_y = horizon - 0.10;
		float roof_h = roofline_profile(uv.x) * 0.06;
		float roof_alpha = smoothstep(roof_y - roof_h, roof_y, uv.y) - smoothstep(roof_y, roof_y + 0.01, uv.y);
		roof_alpha *= 0.55 * backdrop_alpha;
		col.rgb += vec3(0.04, 0.026, 0.016) * roof_alpha;
		// 屋顶金色勾边
		float edge = abs(uv.y - roof_y + roof_h * 0.5) * 40.0;
		float gold_edge = exp(-edge * edge) * 0.08 * backdrop_alpha;
		col.rgb += accent.rgb * gold_edge;
	}
	
	// ─── 森林竹影（forest 额外层次） ───
	if (terrain_type == 3) {
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			float bx = uv.x * 5.0 + fi * 0.7;
			float stalk = abs(fract(bx) - 0.5) * 2.0;
			float stalk_alpha = smoothstep(0.08, 0.0, stalk);
			float by = horizon + 0.02 + fi * 0.02;
			float bh = 0.12 + mod(fi * 1.1, 0.06);
			float stalk_vis = smoothstep(by - bh, by + 0.01, uv.y);
			stalk_vis *= smoothstep(by + 0.01, by - bh, uv.y);
			col.rgb += vec3(0.01, 0.05, 0.02) * stalk_alpha * stalk_vis * 0.35 * backdrop_alpha;
		}
	}
	
	// ─── 地板渐变 ───
	float floor_t = (uv.y - ground_start) / (1.0 - ground_start);
	float floor_mask = smoothstep(ground_start, ground_start + 0.01, uv.y);
	vec3 floor_grad = mix(floor_color.rgb * 0.85, floor_color.rgb * 0.35, floor_t);
	col.rgb += floor_grad * floor_mask * backdrop_alpha;
	col.a += floor_mask * 0.98 * backdrop_alpha;
	
	// 地板透视线
	float line_spacing = 0.08;
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float ly = ground_start + 0.04 + fi * 0.07;
		float line_w = 0.002 + fi * 0.004;
		float line_vis = 1.0 - abs(uv.y - ly) / line_w;
		line_vis = smoothstep(0.0, 1.0, line_vis);
		float lx_inset = fi * 0.015;
		float lx_edge = smoothstep(lx_inset, lx_inset + 0.02, uv.x) * smoothstep(1.0 - lx_inset, 1.0 - lx_inset - 0.02, uv.x);
		float line_alpha = line_vis * 0.12 * floor_mask * lx_edge * backdrop_alpha;
		col.rgb += vec3(0.0) * line_alpha;
	}
	
	// ─── 水墨晕染前景 ───
	float foreground_fog = fbm3(vec2(uv.x * 3.0, uv.y * 2.0 + time * 0.01));
	float fog_alpha = smoothstep(0.75, 1.0, uv.y) * 0.12 * foreground_fog * backdrop_alpha;
	col.rgb += vec3(0.90, 0.84, 0.70) * fog_alpha;
	
	// ─── 暗角 ───
	float vignette_x = 1.0 - abs(uv.x - 0.5) * 0.8;
	float vignette_y = 1.0 - abs(uv.y - 0.5) * 0.6;
	float vignette = clamp(vignette_x * vignette_y, 0.5, 1.0);
	vignette = 1.0 - (1.0 - vignette) * 0.35;
	col.rgb *= vignette;
	
	// ─── 底部地面深度 ───
	float depth_alpha = smoothstep(0.82, 1.0, uv.y) * 0.42 * backdrop_alpha;
	col.rgb = mix(col.rgb, vec3(0.0), depth_alpha);
	
	// ─── 氛围光（门派/地形 accent 色） ───
	float ambient = fbm3(vec2(uv.x * 2.0 + time * 0.005, uv.y * 1.5));
	float ambient_alpha = clamp(ambient * 0.08 * floor_mask, 0.0, 0.06) * backdrop_alpha;
	col.rgb += accent.rgb * ambient_alpha;
	
	col.a = clamp(col.a, 0.0, 1.0);
	COLOR = col;
}
