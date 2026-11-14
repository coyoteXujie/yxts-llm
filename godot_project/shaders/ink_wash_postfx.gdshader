shader_type canvas_item;

// ─── 水墨后处理 Shader v3 ───
// 宣纸纤维 + 墨迹不连续（跳白/漏墨）+ 枯笔 + 晕染光墨
// 核心创新：纸张纤维物理导致墨迹不连续——不仅是"颜色压一层纸",
// 而是纸的纤维凹凸让墨在微观上"跳白"，实现真正的水墨肌理
// ──────────────────────────────────────────

uniform float intensity : hint_range(0.0, 1.0) = 0.85;
uniform float paper_strength : hint_range(0.0, 0.20) = 0.070;
uniform float ink_bleed : hint_range(0.0, 6.0) = 3.0;
uniform float warm_tone : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float saturation : hint_range(0.0, 2.0) = 0.75;
uniform float contrast : hint_range(0.5, 2.0) = 1.25;
uniform vec4 paper_color : source_color = vec4(0.88, 0.82, 0.72, 1.0);
uniform vec4 ink_color : source_color = vec4(0.05, 0.03, 0.01, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

// ── 噪声 ──
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

// ── 宣纸纤维纹理 ──
// 纸的帘纹 + 纤维团簇
float paper_fiber(vec2 uv) {
    // 帘纹（横竖交织的竹帘印）
    float curtain_h = smooth_noise(uv * vec2(1200.0, 80.0));
    float curtain_v = smooth_noise(uv * vec2(80.0, 1200.0));
    float curtain = smoothstep(0.3, 0.7, curtain_h * curtain_v);
    
    // 纤维团簇
    float cluster1 = smooth_noise(uv * 800.0);
    float cluster2 = smooth_noise(uv * 400.0);
    float cluster = cluster1 * 0.4 + cluster2 * 0.3;
    
    // 云母细闪
    float mica = smooth_noise(uv * 2000.0) * 0.15;
    
    return mix(cluster, curtain * 0.5, 0.3) + mica;
}

// ── 墨迹不连续（核心创新） ──
// 模拟墨水在宣纸纤维上的"跳白"——纤维凹凸让墨无法覆盖
// darker = more skipping (墨水越浓的地方越容易跳白,因为是湿的),
// 但实际上跳白在墨的边缘最多，中间较少。
// 这里的模型：纸纹起伏处墨彩被"推开"
float ink_jump_white(vec2 uv, float ink_density) {
    // 纸的微观起伏
    float micro = fbm(uv * 600.0 + vec2(0.183, 0.947));
    float macro = fbm(uv * 150.0);
    
    // 墨越浓（ink_density高），跳白越多——浓墨在纤维上更难渗透
    float skip_threshold = 0.5 + ink_density * 0.3 - micro * 0.3 - macro * 0.15;
    float skip = smoothstep(skip_threshold, skip_threshold + 0.15, 0.5 + 0.5 * fbm(uv * 300.0 + vec2(0.5, 0.5)));
    
    // 跳白幅度：亮区小，暗区大（亮处本来纸就显白）
    return skip * 0.08 * (0.3 + ink_density * 0.7);
}

// ── 枯笔效果 ──
// 在笔触边缘产生散墨、飞白
float dry_brush(vec2 uv, float edge_strength) {
    float n = fbm(uv * 200.0);
    // 模拟笔刷分离的纤毛
    float bristle = smooth_noise(uv * vec2(500.0, 30.0));
    bristle = smoothstep(0.4, 0.7, bristle);
    
    float dry = bristle * (1.0 - abs(n - 0.5) * 0.3);
    return dry * 0.04 * edge_strength;
}

// ── 墨色晕染（5-tap 十字采样） ──
vec3 ink_bleed_effect(vec2 uv, vec2 tex_size, vec3 color, float brightness) {
    vec2 step = 1.0 / tex_size * 2.0;
    vec2 offsets[4] = vec2[](vec2(step.x, 0.0), vec2(-step.x, 0.0),
                             vec2(0.0, step.y), vec2(0.0, -step.y));
    
    float bleed = brightness;
    float w_sum = 1.0;
    for (int i = 0; i < 4; i++) {
        vec3 s = texture(SCREEN_TEXTURE, uv + offsets[i]).rgb;
        float b = max(s.r, max(s.g, s.b));
        bleed += b * 0.6;
        w_sum += 0.6;
    }
    bleed /= w_sum;
    
    float bleed_strength = max(0.0, (bleed - brightness)) * ink_bleed;
    bleed_strength = clamp(bleed_strength, 0.0, 1.0);
    
    vec3 glow = vec3(1.0, 0.85, 0.55) * bleed * 0.8;
    vec3 result = mix(color, glow, bleed_strength * 0.35);
    result += glow * bleed_strength * 0.10;
    return result;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec4 screen = texture(SCREEN_TEXTURE, uv);
    vec3 color = screen.rgb;
    
    float brightness = max(color.r, max(color.g, color.b));
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    float ink_density = 1.0 - gray; // 墨色浓度
    
    // 1. 墨色晕染
    color = ink_bleed_effect(uv, tex_size, color, brightness);
    
    // 2. 暖色调
    color.r = mix(color.r, color.r * 1.06 + 0.03, warm_tone);
    color.g = mix(color.g, color.g * 1.02 + 0.02, warm_tone);
    color.b = mix(color.b, color.b * 0.88 + 0.01, warm_tone);
    
    // 3. 降饱和度
    color = mix(vec3(gray), color, saturation);
    
    // 4. 对比度
    color = (color - 0.5) * contrast + 0.5;
    color = clamp(color, 0.0, 1.0);
    
    // 5. 纸张纤维纹理（细肌理）
    float paper = paper_fiber(uv);
    float paper_mix = paper_strength * 0.5;
    color = mix(color, paper_color.rgb, paper_mix);
    color += (paper - 0.5) * paper_strength * 0.3;
    
    // 6. ★ 墨迹不连续 — 跳白/漏墨（核心创新）
    float skip = ink_jump_white(uv, ink_density);
    // 跳白 = 纸色透出
    color = mix(color, paper_color.rgb, skip * 0.5);
    // 跳白处产生微小的亮度变化（模拟纤维反光）
    color += skip * 0.03;
    
    // 7. ★ 枯笔飞白（边缘散墨）
    float edge = 0.0;
    // 算边缘
    vec2 step_px = 1.0 / tex_size;
    float ex = abs(texture(SCREEN_TEXTURE, uv + vec2(step_px.x, 0.0)).r - texture(SCREEN_TEXTURE, uv - vec2(step_px.x, 0.0)).r);
    float ey = abs(texture(SCREEN_TEXTURE, uv + vec2(0.0, step_px.y)).r - texture(SCREEN_TEXTURE, uv - vec2(0.0, step_px.y)).r);
    edge = max(ex, ey) * 3.0;
    edge = min(edge, 1.0) * ink_density;
    float dry = dry_brush(uv, edge);
    color = mix(color, paper_color.rgb * 0.6, dry);
    
    // 8. 渗墨暗角
    vec2 cen = uv - 0.5;
    float vx = 1.0 - abs(cen.x) * 0.7;
    float vy = 1.0 - abs(cen.y) * 0.9;
    float vignette = vx * vy;
    vignette = pow(vignette, 1.0 + vignette_strength * 0.8);
    color *= vignette;
    
    // 9. 焦墨保护
    color = mix(color, mix(ink_color.rgb, color, 0.7), ink_density * 0.06);
    
    color = clamp(color, 0.0, 1.0);
    
    COLOR = mix(screen, vec4(color, screen.a), intensity);
}
