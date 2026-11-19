shader_type canvas_item;

// ─── 战斗 VFX：GPU 全屏特效层 ───
// 替代 CPU _draw_sword_qi / _draw_palm_wave / _draw_fire_burst 等全部 VFX
// ──────────────────────────────────

uniform int effect_type; // 0=none,1=blade,2=sword_qi,3=palm_wave,4=fire_burst,
                         // 5=poison_mist,6=ice_shards,7=shadow_strike,8=impact_arc,
                         // 9=combo_burst,10=ink_burst,11=air_cuts,12=speed_lines,
                         // 13=focus_ring,14=hit_sparks,15=impact_overlay

uniform vec2 start_pos;   // 起点 (UV 空间)
uniform vec2 end_pos;     // 终点 (UV 空间)
uniform vec4 tint_color : source_color = vec4(1.0, 0.78, 0.34, 1.0);
uniform float effect_alpha;
uniform float pulse_time;
uniform float event_life; // 0~1 事件生命周期
uniform float hit_freeze; // 打击定格 0~1
uniform float intensity;  // 强度系数
uniform float shake_strength;
uniform int is_heavy_hit;

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

// ─── 剑气 Sword Qi ───
vec4 draw_sword_qi(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	
	// 剑气光束：在 start→end 线的投影
	vec2 to_uv = uv - start;
	float proj = dot(to_uv, dir);
	float perp = abs(dot(to_uv, nml));
	float len = length(end - start);
	
	float beam = 1.0 - smoothstep(0.1, len + 0.04, proj);
	beam *= smoothstep(0.0, 0.1, proj);
	float beam_alpha = smoothstep(0.015, 0.0, perp) * 0.78;
	
	// 核心亮线
	float core = smoothstep(0.005, 0.0, perp) * 0.98;
	
	// 横向尾迹像素
	float glow = 0.22 * exp(-perp * 80.0);
	
	// 最终 alpha
	float alpha = max(beam_alpha, core) * effect_alpha;
	alpha += glow * effect_alpha;
	
	vec3 col = mix(vec3(0.72, 0.88, 1.0), tint_color.rgb, 0.3);
	col = mix(col, vec3(0.98, 0.98, 0.86), core * 0.7);
	
	return vec4(col * 0.85, alpha);
}

// ─── 掌风 Palm Wave ───
vec4 draw_palm_wave(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	// 波纹弧线
	float len = length(end - start);
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float t = 0.30 + fi * 0.17;
		vec2 center = mix(start, end, t);
		float dist = length(uv - center);
		float radius = 0.04 + fi * 0.02;
		float arc = 1.0 - abs(dist - radius) * 150.0;
		arc = smoothstep(0.0, 1.0, arc) * 0.30;
		
		// 只保留前进方向的半弧
		vec2 to_center = normalize(uv - center);
		float dot_dir = dot(to_center, dir);
		arc *= smoothstep(-0.7, 0.0, dot_dir) * smoothstep(-1.0, -0.7, dot_dir);
		
		col.rgb += tint_color.rgb * arc;
		col.a += arc;
	}
	
	// 冲击波圈
	float dist_end = length(uv - end);
	float impact = smoothstep(0.04, 0.0, dist_end) * 0.11;
	
	// 地面连线
	float perp = abs(dot(uv - start, nml));
	float beam = 1.0 - smoothstep(0.002, 0.015, perp);
	float beam_proj = dot(uv - start, dir);
	beam *= smoothstep(-0.01, 0.01, beam_proj);
	beam *= smoothstep(len + 0.01, len - 0.02, beam_proj);
	
	col.rgb += mix(vec3(0.95, 0.90, 0.62), tint_color.rgb, 0.3) * beam * 0.28;
	col.a += beam * 0.28 + impact;
	
	col.a *= effect_alpha;
	return col;
}

// ─── 火焰 Fire Burst ───
vec4 draw_fire_burst(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec4 col = vec4(0.0);
	
	// 火焰粒子（基于噪声）
	float len = length(end - start);
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float t = 0.2 + fi * 0.12;
		vec2 base = mix(start, end, t);
		float angle = fi * 0.7 + pulse_time * 0.45;
		float r = 0.01 + mod(fi * 0.37, 0.02);
		vec2 offset = vec2(cos(angle), sin(angle) * 0.65) * r;
		vec2 center = base + offset;
		
		float dist = length(uv - center);
		float flame = exp(-dist * dist * 2000.0) * 0.25;
		float noise_val = smooth_noise(uv * 30.0 + pulse_time * 0.5 + fi);
		flame *= 0.5 + noise_val * 0.5;
		
		vec3 flame_col = mix(
			vec3(1.0, 0.33, 0.10),
			vec3(1.0, 0.76, 0.22),
			smooth_noise(uv * 20.0 + fi) * 0.5 + 0.5
		);
		col.rgb += flame_col * flame;
		col.a += flame;
	}
	
	// 终点爆炸圈
	float end_dist = length(uv - end);
	float burst = exp(-end_dist * end_dist * 600.0) * 0.30;
	col.rgb += vec3(1.0, 0.76, 0.22) * burst;
	col.a += burst;
	
	col.a *= effect_alpha;
	return col;
}

// ─── 毒雾 Poison Mist ───
vec4 draw_poison_mist(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	// FBM 噪声云
	float len = length(end - start);
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float t = fi / 4.0;
		vec2 center = mix(start, end, t) + nml * sin(t * PI * 2.0 + pulse_time) * 0.03;
		vec2 noise_uv = (uv - center) * 15.0 + vec2(pulse_time * 0.1, 0.0);
		float mist = fbm3(noise_uv);
		mist = smoothstep(0.3, 0.6, mist) * 0.15;
		float fade = 1.0 - smoothstep(0.04, 0.0, length(uv - center)) * 0.5;
		mist *= fade;
		col.rgb += vec3(0.42, 0.86, 0.26) * mist;
		col.a += mist;
	}
	
	// 连线
	float perp = abs(dot(uv - start, nml));
	float beam = 1.0 - smoothstep(0.0, 0.01, perp);
	float proj = dot(uv - start, dir);
	beam *= smoothstep(0.0, 0.02, proj);
	beam *= smoothstep(len, len - 0.01, proj);
	col.rgb += vec3(0.76, 1.0, 0.52) * beam * 0.24;
	col.a += beam * 0.24;
	
	col.a *= effect_alpha;
	return col;
}

// ─── 冰刺 Ice Shards ───
vec4 draw_ice_shards(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	float len = length(end - start);
	
	// 冰晶碎片
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float t = 0.20 + fi * 0.12;
		vec2 center = mix(start, end, t) + nml * float(int(fi) % 3 - 1) * 0.02;
		vec2 tip_dir = dir * (0.04 + mod(fi * 0.7, 0.015));
		vec2 tip = center + tip_dir;
		
		// 棱晶形状（菱形）
		vec2 local = uv - center;
		float proj_tip = dot(local, normalize(tip_dir));
		float perp = abs(dot(local, nml));
		float half_len = length(tip_dir);
		float shape = 1.0 - smoothstep(0.0, half_len, proj_tip);
		shape *= 1.0 - perp / (0.008 + 0.5 * (proj_tip / half_len) * 0.008);
		shape = smoothstep(0.0, 1.0, shape);
		
		float shine = smooth_noise(uv * 40.0 + fi) * 0.5 + 0.5;
		vec3 ice_col = mix(
			vec3(0.62, 0.88, 1.0),
			vec3(0.96, 1.0, 1.0),
			shine * 0.5
		);
		col.rgb += ice_col * shape * 0.35;
		col.a += shape * 0.35;
	}
	
	// 连线
	float perp = abs(dot(uv - start, nml));
	float beam = 1.0 - smoothstep(0.0, 0.004, perp);
	float proj = dot(uv - start, dir);
	beam *= smoothstep(-0.01, 0.01, proj);
	beam *= smoothstep(len + 0.01, len - 0.01, proj);
	col.rgb += vec3(0.90, 0.97, 1.0) * beam * 0.62;
	col.a += beam * 0.62;
	
	// 终点冰圈
	float end_dist = length(uv - end);
	float ring = abs(end_dist - 0.05) * 200.0;
	ring = exp(-ring * ring) * 0.26;
	col.rgb += vec3(0.74, 0.92, 1.0) * ring;
	col.a += ring;
	
	col.a *= effect_alpha;
	return col;
}

// ─── 暗影 Shadow Strike ───
vec4 draw_shadow_strike(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	float len = length(end - start);
	
	// 多重暗影斩击线
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float offset = (fi - 1.0) * 0.015;
		vec2 p_start = start + nml * offset + vec2(0.0, fi * 0.005);
		vec2 p_end = end + nml * offset - dir * fi * 0.01;
		
		float perp = abs(dot(uv - p_start, nml));
		float proj = dot(uv - p_start, dir);
		float beam = 1.0 - smoothstep(0.0, 0.008 - fi * 0.001, perp);
		beam *= smoothstep(-0.01, 0.01, proj);
		beam *= smoothstep(len - fi * 0.01, len - 0.01 - fi * 0.01, proj);
		beam *= (0.46 - fi * 0.08);
		
		col.rgb += vec3(0.18, 0.08, 0.26) * beam;
		col.a += beam;
	}
	
	// 核心亮线
	float perp = abs(dot(uv - start, nml));
	float core = 1.0 - smoothstep(0.0, 0.002, perp);
	float proj = dot(uv - start, dir);
	core *= smoothstep(-0.01, 0.01, proj);
	core *= smoothstep(len + 0.01, len - 0.01, proj);
	col.rgb += vec3(0.86, 0.70, 1.0) * core * 0.30;
	col.a += core * 0.30;
	
	col.a *= effect_alpha;
	return col;
}

// ─── 冲击光弧 Impact Arc ───
vec4 draw_impact_arc(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	// 弧线：经过 Bezier 中点的弧
	float len = length(end - start);
	vec2 mid = mix(start, end, 0.5) + vec2(0.03, -0.05);
	
	// 到曲线的距离（近似）
	float t = clamp(dot(uv - start, dir) / max(len, 0.001), 0.0, 1.0);
	vec2 point_on_line = mix(start, end, t);
	vec2 arc_offset = sin(t * PI) * (mid - mix(start, end, 0.5));
	vec2 nearest = point_on_line + arc_offset;
	float dist = length(uv - nearest);
	
	float arc = 1.0 - smoothstep(0.0, 0.012, dist);
	col.rgb += tint_color.rgb * arc * 0.80;
	col.a += arc * 0.80;
	
	// 高亮内弧
	float inner = 1.0 - smoothstep(0.0, 0.003, dist);
	col.rgb += vec3(1.0, 0.92, 0.70) * inner * 0.50;
	col.a += inner * 0.50;
	
	col.a *= effect_alpha;
	return col;
}

// ─── Combo Burst ───
vec4 draw_combo_burst(vec2 uv, vec2 center) {
	vec4 col = vec4(0.0);
	vec2 to_uv = uv - center;
	float dist = length(to_uv);
	float angle = atan(to_uv.y, to_uv.x);
	
	// 同心环
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float radius = 0.04 + fi * 0.025 + intensity * 0.01;
		float ring = abs(dist - radius) * 300.0;
		ring = exp(-ring * ring) * (0.24 / (fi + 1.0));
		float ring_angle = angle + fi * 0.12 + pulse_time * 0.24;
		col.rgb += tint_color.rgb * ring;
		col.a += ring;
	}
	
	// 辐射线条
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float a = fi * PI * 0.33 + pulse_time * 0.24;
		vec2 dir = vec2(cos(a), sin(a) * 0.62);
		float proj = dot(to_uv, dir);
		float perp = abs(dot(to_uv, vec2(-dir.y, dir.x)));
		float line = smoothstep(0.01, 0.0, perp);
		line *= smoothstep(-0.01, 0.02, proj);
		line *= smoothstep(0.08 + mod(fi * 1.3, 0.015), 0.02, proj);
		line *= 0.34;
		col.rgb += vec3(1.0, 0.90, 0.58) * line;
		col.a += line;
	}
	
	col.a *= effect_alpha;
	return col;
}

// ─── Ink Burst (墨爆裂) ───
vec4 draw_ink_burst(vec2 uv, vec2 center) {
	vec2 local = (uv - center) * 2.0;
	float d = length(local);
	
	float burst = 1.0 - smoothstep(0.0, 0.9, d);
	float ring = exp(-d * d * 10.0) * 0.6;
	
	float noise_val = fbm3(local * 6.0 + pulse_time * 0.1);
	float edge_wobble = 0.08 * (noise_val - 0.5);
	float burst_ink = 1.0 - smoothstep(0.0, 0.85 + edge_wobble, d);
	
	float dot_grid = smooth_noise(local * 20.0 + pulse_time * 0.05);
	float dots = smoothstep(0.2, 0.7, dot_grid) * (1.0 - smoothstep(0.3, 0.9, d)) * 0.3;
	
	float inner = smooth_noise(local * 12.0 + 1.0) * 0.10;
	
	float alpha = max(0.0, burst * 0.5 + burst_ink * 0.4 + ring + dots + inner);
	alpha *= effect_alpha;
	
	float glow = 0.08 * exp(-abs(d - 0.65) * 40.0) * effect_alpha * 0.6;
	
	vec3 ink_col = mix(vec3(0.03, 0.02, 0.01), tint_color.rgb, 0.2);
	vec3 glow_col = vec3(0.98, 0.88, 0.62);
	
	return vec4(ink_col + glow * glow_col, alpha);
}

// ─── Air Cuts ───
vec4 draw_air_cuts(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	float len = length(end - start);
	float heavy = is_heavy_hit > 0 ? 1.22 : 1.0;
	
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float t = 0.18 + fi * 0.11;
		vec2 center = mix(start, end, t);
		float stagger = (fi - 2.5) * (0.012 + intensity * 0.004);
		vec2 lift = vec2(0.0, -0.03 - sin(pulse_time * 2.0 + fi * 0.7) * 0.01 - t * 0.008);
		float length_cut = 0.04 + mod(fi * 1.3, 0.03) + intensity * 0.02;
		length_cut *= heavy;
		float skew = sin(pulse_time * 1.3 + fi) * 0.008;
		
		vec2 p0 = center - dir * length_cut * 0.5 + nml * stagger + lift + nml * skew;
		vec2 p1 = center + dir * length_cut * 0.5 + nml * stagger + lift - nml * skew * 0.4;
		
		// 线段距离
		vec2 seg_dir = normalize(p1 - p0);
		float seg_len = length(p1 - p0);
		float seg_proj = dot(uv - p0, seg_dir);
		float seg_perp = abs(dot(uv - p0, vec2(-seg_dir.y, seg_dir.x)));
		float seg = smoothstep(0.001, 0.0, seg_perp);
		seg *= smoothstep(-0.001, 0.001, seg_proj);
		seg *= smoothstep(seg_len + 0.001, seg_len - 0.001, seg_proj);
		
		float line_alpha = 0.24 * (0.92 - fi * 0.02) * heavy * effect_alpha;
		col.rgb += tint_color.rgb * seg * line_alpha;
		col.a += seg * line_alpha;
		
		// 每隔一条线加高亮
		if (int(i) % 2 == 0) {
			vec2 hp0 = p0 + nml * 0.005;
			vec2 hp1 = p1 + nml * 0.002;
			vec2 hseg_dir = normalize(hp1 - hp0);
			float hseg_perp = abs(dot(uv - hp0, vec2(-hseg_dir.y, hseg_dir.x)));
			float hseg = smoothstep(0.001, 0.0, hseg_perp);
			float hproj = dot(uv - hp0, hseg_dir);
			hseg *= smoothstep(-0.001, 0.001, hproj);
			hseg *= smoothstep(length(hp1 - hp0) + 0.001, length(hp1 - hp0) - 0.001, hproj);
			col.rgb += vec3(1.0, 0.95, 0.72) * hseg * line_alpha * 0.38;
			col.a += hseg * line_alpha * 0.38;
		}
	}
	
	return col;
}

// ─── Speed Lines ───
vec4 draw_speed_lines(vec2 uv, vec2 start, vec2 end) {
	if (hit_freeze <= 0.01) return vec4(0.0);
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	vec2 center = mix(start, end, 0.58);
	
	for (int i = 0; i < 9; i++) {
		float fi = float(i);
		float spread = (fi - 4.0) * 0.03;
		float length_line = 0.08 + mod(fi * 1.1, 0.05);
		
		vec2 origin = center - dir * (0.07 + mod(fi * 0.3, 0.02)) + nml * spread;
		vec2 end_line = origin + dir * length_line + nml * sin(pulse_time + fi) * 0.005;
		
		vec2 sdir = normalize(end_line - origin);
		float slen = length(end_line - origin);
		float proj = dot(uv - origin, sdir);
		float perp = abs(dot(uv - origin, vec2(-sdir.y, sdir.x)));
		float line = smoothstep(0.002, 0.0, perp);
		line *= smoothstep(-0.001, 0.001, proj);
		line *= smoothstep(slen + 0.001, slen - 0.001, proj);
		
		float line_alpha = (0.10 + mod(fi, 3.0) * 0.035) * effect_alpha * hit_freeze;
		col.rgb += vec3(1.0, 0.94, 0.70) * line * line_alpha;
		col.a += line * line_alpha;
	}
	
	return col;
}

// ─── Focus Ring ───
vec4 draw_focus_ring(vec2 uv, vec2 center) {
	vec2 to_center = uv - center;
	float dist = length(to_center);
	vec4 col = vec4(0.0);
	
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float radius = 0.04 + fi * 0.015;
		float ring = abs(dist - radius) * 250.0;
		ring = exp(-ring * ring) * (0.30 / (fi + 1.0));
		col.rgb += tint_color.rgb * ring;
		col.a += ring;
	}
	
	col.a *= effect_alpha;
	return col;
}

// ─── Hit Sparks ───
vec4 draw_hit_sparks(vec2 uv, vec2 center) {
	vec4 col = vec4(0.0);
	int spark_count = 7;
	
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float angle = fi * 1.2;
		vec2 origin = center + vec2(cos(angle) * 0.02, sin(angle) * 0.015);
		float len_spark = 0.03 + mod(fi * 0.5, 0.015);
		vec2 end_spark = origin + vec2(len_spark - fi * 0.004, -0.015 + fi * 0.006);
		
		vec2 sdir = normalize(end_spark - origin);
		float slen = length(end_spark - origin);
		float proj = dot(uv - origin, sdir);
		float perp = abs(dot(uv - origin, vec2(-sdir.y, sdir.x)));
		float line = smoothstep(0.002, 0.0, perp);
		line *= smoothstep(-0.001, 0.001, proj);
		line *= smoothstep(slen + 0.001, slen - 0.001, proj);
		
		col.rgb += tint_color.rgb * line * 0.56;
		col.a += line * 0.56;
	}
	
	col.a *= effect_alpha;
	return col;
}

// ─── Overlay ───
vec4 draw_impact_overlay(vec2 uv) {
	float hold = hit_freeze;
	if (hold <= 0.01) return vec4(0.0);
	
	vec4 col = vec4(0.0);
	
	// 全屏淡色
	col.rgb += vec3(1.0, 0.92, 0.68) * 0.055 * hold;
	col.a += 0.055 * hold;
	
	// 冲击波圈：在事件位置 (end_pos)
	vec2 to_center = uv - end_pos;
	float dist = length(to_center);
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float radius = 0.07 + fi * 0.04;
		float ring = abs(dist - radius) * 180.0;
		ring = exp(-ring * ring) * (0.16 * hold / (fi + 1.0));
		col.rgb += tint_color.rgb * ring;
		col.a += ring;
	}
	
	return col;
}

// ─── Blade Slash ───
vec4 draw_blade_slash(vec2 uv, vec2 start, vec2 end) {
	vec2 dir = normalize(end - start);
	vec2 nml = vec2(-dir.y, dir.x);
	vec4 col = vec4(0.0);
	
	vec2 center = mix(start, end, 0.62);
	
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float spread = (fi - 1.0) * 0.025;
		
		vec2 p0 = mix(start, end, 0.16 + fi * 0.05) + nml * (0.055 + spread);
		vec2 p1 = center + nml * (0.007 + spread * 0.35) + vec2(0.0, -0.045 + fi * 0.008);
		vec2 p2 = end + nml * (-0.05 + spread * 0.25);
		
		// 分段绘制 polyline 近似
		vec2 p0p1 = p1 - p0;
		float len01 = length(p0p1);
		vec2 d01 = normalize(p0p1);
		vec2 p1p2 = p2 - p1;
		float len12 = length(p1p2);
		vec2 d12 = normalize(p1p2);
		
		float perp01 = abs(dot(uv - p0, vec2(-d01.y, d01.x)));
		float proj01 = dot(uv - p0, d01);
		float s01 = smoothstep(0.01 - fi * 0.002, 0.0, perp01);
		s01 *= smoothstep(-0.001, 0.001, proj01);
		s01 *= smoothstep(len01 + 0.001, len01 - 0.001, proj01);
		
		float perp12 = abs(dot(uv - p1, vec2(-d12.y, d12.x)));
		float proj12 = dot(uv - p1, d12);
		float s12 = smoothstep(0.01 - fi * 0.002, 0.0, perp12);
		s12 *= smoothstep(-0.001, 0.001, proj12);
		s12 *= smoothstep(len12 + 0.001, len12 - 0.001, proj12);
		
		float alpha = (0.66 / (fi + 1.0));
		col.rgb += tint_color.rgb * (s01 + s12) * alpha;
		col.a += (s01 + s12) * alpha;
	}
	
	// 高亮刀锋
	float perp = abs(dot(uv - start + nml * 0.04, nml));
	float core = 1.0 - smoothstep(0.0, 0.003, perp);
	float proj = dot(uv - start, dir);
	core *= smoothstep(0.0, 0.02, proj);
	core *= smoothstep(length(end - start), length(end - start) - 0.02, proj);
	col.rgb += vec3(1.0, 0.96, 0.78) * core * 0.58;
	col.a += core * 0.58;
	
	return col * effect_alpha;
}

void fragment() {
	vec4 col = vec4(0.0);
	
	if (effect_type == 0) {
		COLOR = vec4(0.0);
		return;
	}
	
	if (effect_type == 1) {
		col = draw_blade_slash(UV, start_pos, end_pos);
	} else if (effect_type == 2) {
		col = draw_sword_qi(UV, start_pos, end_pos);
	} else if (effect_type == 3) {
		col = draw_palm_wave(UV, start_pos, end_pos);
	} else if (effect_type == 4) {
		col = draw_fire_burst(UV, start_pos, end_pos);
	} else if (effect_type == 5) {
		col = draw_poison_mist(UV, start_pos, end_pos);
	} else if (effect_type == 6) {
		col = draw_ice_shards(UV, start_pos, end_pos);
	} else if (effect_type == 7) {
		col = draw_shadow_strike(UV, start_pos, end_pos);
	} else if (effect_type == 8) {
		col = draw_impact_arc(UV, start_pos, end_pos);
	} else if (effect_type == 9) {
		col = draw_combo_burst(UV, end_pos);
	} else if (effect_type == 10) {
		col = draw_ink_burst(UV, end_pos);
	} else if (effect_type == 11) {
		col = draw_air_cuts(UV, start_pos, end_pos);
	} else if (effect_type == 12) {
		col = draw_speed_lines(UV, start_pos, end_pos);
	} else if (effect_type == 13) {
		col = draw_focus_ring(UV, end_pos);
	} else if (effect_type == 14) {
		col = draw_hit_sparks(UV, end_pos);
	} else if (effect_type == 15) {
		col = draw_impact_overlay(UV);
	}
	
	COLOR = col;
}
