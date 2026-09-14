shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform bool nvg_enabled = true;
uniform float night_vision_gain : hint_range(0.5, 4.0) = 1.65;
uniform float clarity_sharpness : hint_range(0.0, 1.5) = 0.65;
uniform float contrast_boost : hint_range(0.5, 2.0) = 1.25;
uniform float noise_amount : hint_range(0.0, 0.1) = 0.018;
uniform float scanline_density : hint_range(100.0, 1200.0) = 480.0;
uniform float scanline_intensity : hint_range(0.0, 0.1) = 0.010;
uniform float vignette_radius : hint_range(0.5, 1.5) = 1.08;
uniform float vignette_softness : hint_range(0.05, 0.8) = 0.28;

// Modern High-Clarity Military Phosphor (Crisp, High Contrast, Eye-Gentle)
uniform vec3 phosphor_dark : source_color = vec3(0.012, 0.045, 0.022);
uniform vec3 phosphor_mid : source_color = vec3(0.180, 0.580, 0.320);
uniform vec3 phosphor_bright : source_color = vec3(0.380, 0.880, 0.520);
uniform vec3 phosphor_hot : source_color = vec3(0.600, 0.960, 0.720);

void fragment() {
	if (!nvg_enabled) {
		COLOR = textureLod(screen_texture, SCREEN_UV, 0.0);
	} else {
		vec2 texel = SCREEN_PIXEL_SIZE * 1.2;
		
		// 1. Center sample & 4-tap cross kernel for unsharp masking (Clarity / High Definition)
		vec3 c_rgb = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
		vec3 n_rgb = textureLod(screen_texture, SCREEN_UV + vec2(0.0, -texel.y), 0.0).rgb;
		vec3 s_rgb = textureLod(screen_texture, SCREEN_UV + vec2(0.0, texel.y), 0.0).rgb;
		vec3 e_rgb = textureLod(screen_texture, SCREEN_UV + vec2(texel.x, 0.0), 0.0).rgb;
		vec3 w_rgb = textureLod(screen_texture, SCREEN_UV + vec2(-texel.x, 0.0), 0.0).rgb;
		
		const vec3 L_WEIGHT = vec3(0.299, 0.587, 0.114);
		float lum_c = dot(c_rgb, L_WEIGHT);
		float lum_n = dot(n_rgb, L_WEIGHT);
		float lum_s = dot(s_rgb, L_WEIGHT);
		float lum_e = dot(e_rgb, L_WEIGHT);
		float lum_w = dot(w_rgb, L_WEIGHT);
		
		// Optical clarity unsharp mask
		float laplacian = 4.0 * lum_c - (lum_n + lum_s + lum_e + lum_w);
		float sharp_lum = clamp(lum_c + laplacian * clarity_sharpness, 0.0, 1.0);
		
		// 2. Dynamic Auto-Gating (gentle photocathode protection against overexposure)
		float auto_gate = 1.0 / (1.0 + pow(sharp_lum * 2.2, 1.4));
		float amplified = clamp(sharp_lum * night_vision_gain * auto_gate, 0.0, 1.0);
		
		// 3. Sigmoidal Contrast S-Curve (Crisp tone separation - eliminates muddiness / "trong và rõ")
		float centered = amplified - 0.35;
		float s_curve = 0.35 + sign(centered) * pow(abs(centered) / 0.65, 1.0 / contrast_boost) * 0.65;
		amplified = clamp(mix(amplified, s_curve, 0.55), 0.0, 1.0);
		
		// 4. Subtle quantum scintillation micro-grain (fine & gentle)
		float grain_time = fract(TIME * 18.0);
		vec2 noise_seed = SCREEN_UV + vec2(grain_time * 0.173, grain_time * 0.911);
		float grain = (fract(sin(dot(noise_seed, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * noise_amount;
		amplified = clamp(amplified + grain, 0.0, 1.0);
		
		// 5. 3-tier High-Definition Phosphor Palette
		vec3 nvg_color;
		if (amplified < 0.40) {
			nvg_color = mix(phosphor_dark, phosphor_mid, amplified / 0.40);
		} else if (amplified < 0.80) {
			nvg_color = mix(phosphor_mid, phosphor_bright, (amplified - 0.40) / 0.40);
		} else {
			nvg_color = mix(phosphor_bright, phosphor_hot, (amplified - 0.80) / 0.20);
		}
		
		// 6. Faint cathode scanlines (subtle optic texture)
		float scanline = sin(SCREEN_UV.y * scanline_density) * scanline_intensity;
		nvg_color = clamp(nvg_color - scanline, vec3(0.0), vec3(1.0));
		
		// 7. Wide ocular vignette
		vec2 aspect_uv = (SCREEN_UV - vec2(0.5));
		aspect_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		float dist = length(aspect_uv);
		float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist);
		nvg_color *= vignette;
		
		COLOR = vec4(nvg_color, 1.0);
	}
}
