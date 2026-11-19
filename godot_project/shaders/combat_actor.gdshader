shader_type canvas_item;

// ─── 战斗角色渲染 ───
// 替代 CPU draw_texture_rect + 手写残影/闪白/边缘发光
// ──────────────────────

uniform float hurt_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hurt_flash_color : source_color = vec4(1.0, 0.58, 0.44, 0.42);
uniform float rim_glow : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_glow_color : source_color = vec4(1.0, 0.92, 0.62, 1.0);
uniform float pulse_time;

// 残影效果
uniform float afterimage : hint_range(0.0, 1.0) = 0.0;
uniform vec2 afterimage_offset = vec2(-24.0, 0.0);
uniform float afterimage_alpha : hint_range(0.0, 1.0) = 0.22;

// 淡出/低血量效果
uniform float low_hp_fade : hint_range(0.0, 1.0) = 0.0;
uniform vec4 low_hp_tint : source_color = vec4(0.78, 0.72, 0.66, 1.0);

// 动作强度（影响边缘发光）
uniform float action_intensity : hint_range(0.0, 1.0) = 0.0;

// 整体色调
uniform vec4 tint_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// 读取原始纹理
	vec4 tex = texture(TEXTURE, UV);
	vec4 col = tex * tint_modulate;
	
	// 如果完全没有 alpha（无纹理区域），直接丢弃
	if (tex.a < 0.01) {
		COLOR = vec4(0.0);
		return;
	}
	
	// ─── 受击闪白 ───
	if (hurt_flash > 0.01) {
		vec3 flash = mix(col.rgb, hurt_flash_color.rgb, clamp(hurt_flash * 0.64, 0.0, 0.64));
		col.rgb = flash;
	}
	
	// ─── 低血量褪色 ───
	if (low_hp_fade > 0.01) {
		col.rgb = mix(col.rgb, low_hp_tint.rgb, low_hp_fade * 0.30);
	}
	
	// ─── 边缘发光（水墨金边） ───
	float rim_alpha = 0.13 + action_intensity * 0.10 + low_hp_fade * 0.05;
	if (rim_glow > 0.01 || rim_alpha > 0.01) {
		// 对 UV 进行 Sobel-like 边缘检测
		vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
		vec2 pixel = 1.0 / tex_size;
		
		float alpha_center = tex.a;
		float alpha_right = texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a;
		float alpha_up = texture(TEXTURE, UV + vec2(0.0, pixel.y)).a;
		float alpha_left = texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a;
		float alpha_down = texture(TEXTURE, UV - vec2(0.0, pixel.y)).a;
		
		float edge_x = abs(alpha_right - alpha_left);
		float edge_y = abs(alpha_up - alpha_down);
		float edge = max(edge_x, edge_y);
		
		// 只有边缘像素才有发光
		float glow = smoothstep(0.3, 0.8, edge) * rim_alpha * rim_glow_color.a;
		col.rgb += rim_glow_color.rgb * glow;
	}
	
	// ─── 保留原纹理的 alpha ───
	// 实际 alpha 来自纹理，残影是单独的绘制调用
	col.a = tex.a * tint_modulate.a;
	
	COLOR = col;
}
