shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform bool nvg_enabled = true;
uniform float night_vision_gain : hint_range(0.5, 4.0) = 1.35;
uniform float gamma_exp : hint_range(0.3, 2.0) = 0.95;
uniform float noise_amount : hint_range(0.0, 0.2) = 0.032;
uniform float scanline_density : hint_range(100.0, 1200.0) = 480.0;
uniform float scanline_intensity : hint_range(0.0, 0.15) = 0.020;
uniform float vignette_radius : hint_range(0.4, 1.4) = 0.96;
uniform float vignette_softness : hint_range(0.05, 0.8) = 0.45;

// Military Gen-3 Phosphor Palette (Eye-Friendly Matte Jade - NO BLINDING WHITE GLARE)
uniform vec3 phosphor_dark : source_color = vec3(0.006, 0.035, 0.014);
uniform vec3 phosphor_mid : source_color = vec3(0.080, 0.380, 0.160);
uniform vec3 phosphor_bright : source_color = vec3(0.200, 0.620, 0.280);
uniform vec3 phosphor_hot : source_color = vec3(0.350, 0.760, 0.440);

void fragment() {
	vec3 src = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	if (!nvg_enabled) {
		COLOR = vec4(src, 1.0);
	} else {
		// 1. Calculate luminance from source
		float lum = dot(src, vec3(0.299, 0.587, 0.114));
		
		// 2. Real-world Dynamic Auto-Gating (prevents eye strain & overexposure)
		// When headlights, explosions, or moonlit reflections are bright, tube gain automatically compresses
		float auto_gate = 1.0 / (1.0 + pow(lum * 2.6, 1.35));
		float amplified_lum = pow(clamp(lum * night_vision_gain * auto_gate, 0.0, 1.0), gamma_exp);
		
		// 3. Dynamic quantum scintillation micro-grain noise (subtle photon micro-grain)
		float grain_time = fract(TIME * 20.0);
		vec2 noise_seed = SCREEN_UV + vec2(grain_time * 0.173, grain_time * 0.911);
		float grain = (fract(sin(dot(noise_seed, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * noise_amount;
		amplified_lum = clamp(amplified_lum + grain, 0.0, 1.0);
		
		// 4. Smooth 3-tier Military Phosphor Grading (Eye-Comfort Gen-3 PVS-14)
		vec3 nvg_color;
		if (amplified_lum < 0.35) {
			nvg_color = mix(phosphor_dark, phosphor_mid, amplified_lum / 0.35);
		} else if (amplified_lum < 0.72) {
			nvg_color = mix(phosphor_mid, phosphor_bright, (amplified_lum - 0.35) / 0.37);
		} else {
			nvg_color = mix(phosphor_bright, phosphor_hot, (amplified_lum - 0.72) / 0.28);
		}
		
		// 5. Subtle horizontal optic scanlines (calm, non-abrasive)
		float scanline = sin(SCREEN_UV.y * scanline_density) * scanline_intensity;
		nvg_color = clamp(nvg_color - scanline, vec3(0.0), vec3(1.0));
		
		// 6. Circular optical tube vignette with aspect ratio correction
		vec2 aspect_uv = (SCREEN_UV - vec2(0.5));
		aspect_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		float dist_from_center = length(aspect_uv);
		float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist_from_center);
		
		// Outer ocular housing border
		nvg_color *= vignette;
		
		COLOR = vec4(nvg_color, 1.0);
	}
}
