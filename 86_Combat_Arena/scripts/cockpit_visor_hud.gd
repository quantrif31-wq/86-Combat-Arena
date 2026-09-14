extends Control
class_name CockpitVisorHUD

var player_ref: CharacterBody3D = null
var enemy_ref: CharacterBody3D = null
var all_enemies: Array[CharacterBody3D] = []

var heading_deg: float = 0.0
var cannon_pitch_deg: float = 0.0
var cannon_yaw_deg: float = 0.0
var enemy_dist: float = 0.0
var enemy_bearing_rad: float = 0.0
var is_reloading: bool = false
var reload_ratio: float = 1.0

var pulse_timer: float = 0.0
var radar_sweep_angle: float = 0.0
var is_nvg_active: bool = true

func set_nvg_status(active: bool) -> void:
	is_nvg_active = active
	queue_redraw()

func set_all_enemies(list: Array[CharacterBody3D]) -> void:
	all_enemies = list

func get_sector_name() -> String:
	if not player_ref or not is_instance_valid(player_ref):
		return "SECTOR 86 // COMBAT ZONE"
	var p = player_ref.global_position
	# North is -Z, South is +Z, West is -X, East is +X
	if p.z < -60.0 and abs(p.x) < 130.0:
		return "SECTOR 86 // THE IRON CITADEL RUINS"
	elif p.x < -100.0:
		return "SECTOR 86 // HEAVY FOUNDRY & FACTORY RUINS"
	elif p.x > 100.0:
		return "SECTOR 86 // TRENCH & BUNKER REDOUBT"
	elif p.z > 50.0 and p.z < 110.0:
		return "SECTOR 86 // DRIED RAVINE & VIADUCT BRIDGE"
	elif p.z >= 110.0:
		return "SECTOR 86 // THE GREAT CONIFER FOREST"
	return "SECTOR 86 // NO MAN'S LAND"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	pulse_timer += delta * 4.0
	radar_sweep_angle = fmod(radar_sweep_angle + delta * 2.8, TAU)
	
	if player_ref and is_instance_valid(player_ref):
		var raw_yaw = rad_to_deg(player_ref.rotation.y)
		heading_deg = wrapf(-raw_yaw, 0.0, 360.0)
		cannon_pitch_deg = rad_to_deg(player_ref.current_cannon_pitch)
		cannon_yaw_deg = rad_to_deg(player_ref.current_turret_yaw)
		is_reloading = (player_ref.reload_timer > 0.0)
		reload_ratio = 1.0 - clampf(player_ref.reload_timer / player_ref.cannon_cooldown, 0.0, 1.0)
		
		var min_d: float = 999999.0
		var best_e: CharacterBody3D = null
		for e in all_enemies:
			if is_instance_valid(e) and not e.is_dead:
				var d = player_ref.global_position.distance_to(e.global_position)
				if d < min_d:
					min_d = d
					best_e = e
		if best_e:
			enemy_ref = best_e
		
	if player_ref and enemy_ref and is_instance_valid(enemy_ref):
		enemy_dist = player_ref.global_position.distance_to(enemy_ref.global_position)
		var to_enemy = enemy_ref.global_position - player_ref.global_position
		to_enemy.y = 0.0
		var local_to_enemy = player_ref.global_transform.basis.inverse() * to_enemy.normalized()
		enemy_bearing_rad = atan2(local_to_enemy.x, -local_to_enemy.z)
		
	queue_redraw()

func _draw() -> void:
	var rect = get_viewport_rect()
	var W = rect.size.x
	var H = rect.size.y
	if W < 10 or H < 10:
		return
		
	# Anime Visor Holographic Colors
	var cyan = Color(0.24, 0.90, 1.0, 0.92)
	var cyan_bright = Color(0.65, 0.98, 1.0, 1.0)
	var cyan_dim = Color(0.16, 0.72, 0.92, 0.45)
	var cyan_glow = Color(0.20, 0.85, 1.0, 0.18)
	
	# M1A4 JUGGERNAUT REALISTIC MATERIALS (Matching Desert Tan / Bone Armor & Dark Steel)
	var armor_tan_base = Color(0.68, 0.62, 0.48, 0.98)     # Weathered Desert Bone-Tan Armor
	var armor_tan_mid = Color(0.58, 0.52, 0.40, 1.0)      # Chipped Armor Shadow
	var armor_tan_highlight = Color(0.82, 0.76, 0.62, 1.0)# Sunlit Armor Edge
	var steel_dark = Color(0.14, 0.17, 0.22, 0.98)        # Manganese Structural Steel
	var steel_edge = Color(0.32, 0.40, 0.50, 1.0)         # Machined Beveled Steel
	var steel_highlight = Color(0.52, 0.64, 0.78, 1.0)    # Specular Steel Glint
	var hull_shadow = Color(0.04, 0.05, 0.07, 1.0)        # Deep Recess Shadow
	
	var font = ThemeDB.fallback_font
	var cx = W * 0.5
	
	# =========================================================================
	# 1. CANOPY GLASS CURVATURE & SUBTLE REFLECTION
	# =========================================================================
	var glare_c = Vector2(cx, -H * 0.35)
	var glare_r = H * 1.12
	draw_arc(glare_c, glare_r, deg_to_rad(65.0), deg_to_rad(115.0), 32, Color(0.35, 0.82, 1.0, 0.05), 16.0)
	draw_arc(glare_c, glare_r, deg_to_rad(72.0), deg_to_rad(108.0), 32, Color(0.65, 0.92, 1.0, 0.03), 3.0)

	# =========================================================================
	# 2. CANOPY A-PILLARS (LEFT & RIGHT DESERT-ARMORED BULKHEADS)
	# =========================================================================
	var pillar_w = W * 0.042
	# Left A-Pillar
	var left_pillar_pts = PackedVector2Array([
		Vector2(0, 0),
		Vector2(pillar_w * 0.65, 0),
		Vector2(pillar_w * 1.25, H * 0.74),
		Vector2(0, H * 0.74)
	])
	draw_colored_polygon(left_pillar_pts, steel_dark)
	# Armor trim on pillar
	var left_p_trim = PackedVector2Array([
		Vector2(0, 0),
		Vector2(pillar_w * 0.4, 0),
		Vector2(pillar_w * 0.8, H * 0.74),
		Vector2(0, H * 0.74)
	])
	draw_colored_polygon(left_p_trim, armor_tan_base)
	draw_polyline(PackedVector2Array([Vector2(pillar_w * 0.65, 0), Vector2(pillar_w * 1.25, H * 0.74)]), steel_edge, 2.5)
	draw_polyline(PackedVector2Array([Vector2(pillar_w * 0.55, 0), Vector2(pillar_w * 1.15, H * 0.74)]), cyan_dim, 1.2)
	
	# Right A-Pillar
	var right_pillar_pts = PackedVector2Array([
		Vector2(W, 0),
		Vector2(W - pillar_w * 0.65, 0),
		Vector2(W - pillar_w * 1.25, H * 0.74),
		Vector2(W, H * 0.74)
	])
	draw_colored_polygon(right_pillar_pts, steel_dark)
	var right_p_trim = PackedVector2Array([
		Vector2(W, 0),
		Vector2(W - pillar_w * 0.4, 0),
		Vector2(W - pillar_w * 0.8, H * 0.74),
		Vector2(W, H * 0.74)
	])
	draw_colored_polygon(right_p_trim, armor_tan_base)
	draw_polyline(PackedVector2Array([Vector2(W - pillar_w * 0.65, 0), Vector2(W - pillar_w * 1.25, H * 0.74)]), steel_edge, 2.5)
	draw_polyline(PackedVector2Array([Vector2(W - pillar_w * 0.55, 0), Vector2(W - pillar_w * 1.15, H * 0.74)]), cyan_dim, 1.2)

	# =========================================================================
	# 3. PHYSICAL COCKPIT TUB (DESERT ARMOR PLATING + BEVELED STEEL RIM)
	# =========================================================================
	var console_r = H * 0.18 # Center console dome radius
	var rim_y_side = H * 0.74
	var rim_y_center = H * 0.95
	var left_rim_end = Vector2(cx - console_r * 1.15, rim_y_center)
	var right_rim_end = Vector2(cx + console_r * 1.15, rim_y_center)
	
	# Layer 1: Ambient Occlusion Under-Rim Shadow
	var left_shadow = PackedVector2Array([
		Vector2(0, rim_y_side - 3),
		left_rim_end + Vector2(0, -3),
		Vector2(left_rim_end.x, H),
		Vector2(0, H)
	])
	draw_colored_polygon(left_shadow, hull_shadow)
	var right_shadow = PackedVector2Array([
		Vector2(W, rim_y_side - 3),
		right_rim_end + Vector2(0, -3),
		Vector2(right_rim_end.x, H),
		Vector2(W, H)
	])
	draw_colored_polygon(right_shadow, hull_shadow)
	
	# Layer 2: Main Cockpit Armor Deck (Desert Bone-Tan military armor)
	var left_deck = PackedVector2Array([
		Vector2(0, rim_y_side),
		left_rim_end,
		Vector2(left_rim_end.x, H),
		Vector2(0, H)
	])
	draw_colored_polygon(left_deck, armor_tan_base)
	var right_deck = PackedVector2Array([
		Vector2(W, rim_y_side),
		right_rim_end,
		Vector2(right_rim_end.x, H),
		Vector2(W, H)
	])
	draw_colored_polygon(right_deck, armor_tan_base)
	
	# Layer 3: Secondary Dark Steel Chamfer Trim
	var chamfer_in = 8.0
	var left_chamfer = PackedVector2Array([
		Vector2(0, rim_y_side + chamfer_in),
		left_rim_end + Vector2(0, chamfer_in * 0.5),
		Vector2(left_rim_end.x, H),
		Vector2(0, H)
	])
	draw_colored_polygon(left_chamfer, steel_dark)
	var right_chamfer = PackedVector2Array([
		Vector2(W, rim_y_side + chamfer_in),
		right_rim_end + Vector2(0, chamfer_in * 0.5),
		Vector2(right_rim_end.x, H),
		Vector2(W, H)
	])
	draw_colored_polygon(right_chamfer, steel_dark)
	
	# Layer 4: Beveled Machined Edge & Specular Glint
	draw_polyline(PackedVector2Array([Vector2(0, rim_y_side), left_rim_end]), steel_edge, 4.0)
	draw_polyline(PackedVector2Array([Vector2(0, rim_y_side + 1), left_rim_end + Vector2(0, 1)]), armor_tan_highlight, 1.5)
	draw_polyline(PackedVector2Array([Vector2(W, rim_y_side), right_rim_end]), steel_edge, 4.0)
	draw_polyline(PackedVector2Array([Vector2(W, rim_y_side + 1), right_rim_end + Vector2(0, 1)]), armor_tan_highlight, 1.5)
	
	# Glowing Cyan Fiber-Optic Canopy Rim Lighting
	draw_polyline(PackedVector2Array([Vector2(0, rim_y_side - 1.5), left_rim_end - Vector2(0, 1.5)]), cyan_glow, 6.0)
	draw_polyline(PackedVector2Array([Vector2(0, rim_y_side - 1.5), left_rim_end - Vector2(0, 1.5)]), cyan_dim, 2.5)
	draw_polyline(PackedVector2Array([Vector2(0, rim_y_side - 1.5), left_rim_end - Vector2(0, 1.5)]), cyan_bright, 1.0)
	draw_polyline(PackedVector2Array([Vector2(W, rim_y_side - 1.5), right_rim_end - Vector2(0, 1.5)]), cyan_glow, 6.0)
	draw_polyline(PackedVector2Array([Vector2(W, rim_y_side - 1.5), right_rim_end - Vector2(0, 1.5)]), cyan_dim, 2.5)
	draw_polyline(PackedVector2Array([Vector2(W, rim_y_side - 1.5), right_rim_end - Vector2(0, 1.5)]), cyan_bright, 1.0)
	
	# Stenciled Military Nomenclature on Armor
	draw_string(font, Vector2(30, H - 10), "SAN MAGNOLIA // M1A4 JUGGERNAUT | [N] NVG [L] LIGHTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.20, 0.24, 0.30, 0.9))
	draw_string(font, Vector2(W - 250, H - 10), "COAXIAL 57mm // APFSDS: LOADED", HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(0.20, 0.24, 0.30, 0.9))
	
	# 3D Countersunk Military Hex Bolts
	for i in range(5):
		var t = float(i + 1) / 6.0
		var p_l = Vector2(0, rim_y_side).lerp(left_rim_end, t) + Vector2(0, 12.0)
		var p_r = Vector2(W, rim_y_side).lerp(right_rim_end, t) + Vector2(0, 12.0)
		draw_circle(p_l + Vector2(0, 1), 4.2, hull_shadow)
		draw_circle(p_r + Vector2(0, 1), 4.2, hull_shadow)
		draw_circle(p_l, 4.0, steel_dark)
		draw_circle(p_r, 4.0, steel_dark)
		draw_circle(p_l, 2.6, Color(0.28, 0.36, 0.46))
		draw_circle(p_r, 2.6, Color(0.28, 0.36, 0.46))
		draw_circle(p_l + Vector2(-0.8, -0.8), 1.0, steel_highlight)
		draw_circle(p_r + Vector2(-0.8, -0.8), 1.0, steel_highlight)
		
	# =========================================================================
	# 4. CENTER ARCH DASHBOARD CONSOLE (OPTICAL SENSOR PROCESSOR HOUSING)
	# =========================================================================
	var dome_apex_y = H - console_r * 0.92
	var dome_segments = 36
	
	# Outer Armored Cowl in Desert Tan & Steel
	var dome_pts = PackedVector2Array()
	for i in range(dome_segments + 1):
		var ang = PI + (float(i) / float(dome_segments)) * PI
		dome_pts.append(Vector2(cx + cos(ang) * console_r * 1.18, H + sin(ang) * console_r * 0.92))
	dome_pts.append(Vector2(cx + console_r * 1.18, H))
	dome_pts.append(Vector2(cx - console_r * 1.18, H))
	draw_colored_polygon(dome_pts, armor_tan_base)
	
	# Outer Steel Cowl Rim
	var dome_rim = PackedVector2Array()
	for i in range(dome_segments + 1):
		var ang = PI + (float(i) / float(dome_segments)) * PI
		dome_rim.append(Vector2(cx + cos(ang) * console_r * 1.18, H + sin(ang) * console_r * 0.92))
	draw_polyline(dome_rim, steel_edge, 4.5)
	draw_polyline(dome_rim, steel_highlight, 1.5)
	
	# Recessed MFD Screen Glass (Sapphire Display)
	var mfd_c = Vector2(cx, H - console_r * 0.38)
	var mfd_r = console_r * 0.62
	var screen_pts = PackedVector2Array()
	for i in range(24 + 1):
		var ang = PI + (float(i) / 24.0) * PI
		screen_pts.append(Vector2(cx + cos(ang) * mfd_r, H + sin(ang) * mfd_r * 0.82))
	screen_pts.append(Vector2(cx + mfd_r, H))
	screen_pts.append(Vector2(cx - mfd_r, H))
	draw_colored_polygon(screen_pts, Color(0.01, 0.05, 0.09, 0.96))
	
	# Inner Glowing Cyan HUD Arc inside console
	var inner_hud_arc = PackedVector2Array()
	for i in range(dome_segments + 1):
		var ang = PI + (float(i) / float(dome_segments)) * PI
		inner_hud_arc.append(Vector2(cx + cos(ang) * console_r * 0.92, H + sin(ang) * console_r * 0.72))
	draw_polyline(inner_hud_arc, cyan_glow, 5.0)
	draw_polyline(inner_hud_arc, cyan, 2.0)
	
	# Radar MFD Dial inside display
	draw_arc(mfd_c, mfd_r * 0.90, PI, TAU, 24, cyan_dim, 1.2)
	draw_arc(mfd_c, mfd_r * 0.50, PI, TAU, 16, cyan_dim, 1.0)
	draw_line(mfd_c + Vector2(-mfd_r * 0.90, 0), mfd_c + Vector2(mfd_r * 0.90, 0), cyan_dim, 1.0)
	draw_line(mfd_c, mfd_c + Vector2(0, -mfd_r * 0.75), cyan_dim, 1.0)
	
	# Sweeping Radar Line with Gradient Fan
	var sweep_v = Vector2(cos(radar_sweep_angle), sin(radar_sweep_angle))
	if sweep_v.y < 0.0:
		draw_line(mfd_c, mfd_c + sweep_v * (mfd_r * 0.88), Color(0.3, 1.0, 0.7, 0.9), 2.0)
		for tr in range(1, 5):
			var a_tr = radar_sweep_angle - float(tr) * 0.08
			var sv_tr = Vector2(cos(a_tr), sin(a_tr))
			if sv_tr.y < 0.0:
				draw_line(mfd_c, mfd_c + sv_tr * (mfd_r * 0.88), Color(0.2, 0.9, 0.6, 0.5 - tr * 0.1), 1.2)
				
	# Juggernaut Weapon Status Indicator LEDs:
	# Left LED: Green/Cyan (OPTICS COAXIAL NOMINAL / NVG STATUS)
	var led_l = Vector2(cx - console_r * 0.98, H - console_r * 0.22)
	var led_col = Color(0.2, 1.0, 0.45, 0.95) if is_nvg_active else Color(0.2, 0.65, 0.85, 0.9)
	draw_circle(led_l, 3.5, led_col)
	draw_circle(led_l, 6.5, Color(led_col.r, led_col.g, led_col.b, 0.3))
	draw_string(font, led_l + Vector2(-42, 3), "NVG" if is_nvg_active else "OPTIC", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, led_col)
	
	# Right LED: Red/Cyan (57mm CANNON ARMED)
	var led_r = Vector2(cx + console_r * 0.98, H - console_r * 0.22)
	draw_circle(led_r, 3.5, Color(1.0, 0.3, 0.2, 0.95))
	draw_circle(led_r, 6.5, Color(1.0, 0.3, 0.2, 0.3))
	draw_string(font, led_r + Vector2(10, 3), "CANNON", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.4, 0.3, 0.9))
	
	# Keypad Grid (Lower console illuminated silicone keys)
	var key_w = 4.5
	var key_gap = 3.0
	var grid_cols = 6
	var grid_rows = 3
	var start_kx = cx - (grid_cols * (key_w + key_gap) - key_gap) * 0.5
	var start_ky = H - 24.0
	for r in range(grid_rows):
		for c in range(grid_cols):
			var kpos = Vector2(start_kx + c * (key_w + key_gap), start_ky + r * (key_w + key_gap))
			var bcol = Color(0.25, 0.55, 0.80, 0.9) if (c + r) % 2 == 0 else Color(0.15, 0.40, 0.65, 0.8)
			draw_rect(Rect2(kpos, Vector2(key_w, key_w)), bcol)
			
	# =========================================================================
	# 5. HOLOGRAPHIC VISOR: CENTRAL HORIZON COMPASS ARC & AIM RETICLE
	# =========================================================================
	var h_c = Vector2(cx, H * 0.98)
	var h_r = H * 0.55
	var max_a_deg = 46.0
	var gap_deg = 4.2
	
	var left_arc_pts = PackedVector2Array()
	var left_steps = 32
	for i in range(left_steps + 1):
		var a = deg_to_rad(-max_a_deg + (float(i) / left_steps) * (max_a_deg - gap_deg))
		left_arc_pts.append(Vector2(h_c.x + sin(a) * h_r, h_c.y - cos(a) * h_r))
	draw_polyline(left_arc_pts, cyan_glow, 5.0)
	draw_polyline(left_arc_pts, cyan, 2.0)
	
	var right_arc_pts = PackedVector2Array()
	var right_steps = 32
	for i in range(right_steps + 1):
		var a = deg_to_rad(gap_deg + (float(i) / right_steps) * (max_a_deg - gap_deg))
		right_arc_pts.append(Vector2(h_c.x + sin(a) * h_r, h_c.y - cos(a) * h_r))
	draw_polyline(right_arc_pts, cyan_glow, 5.0)
	draw_polyline(right_arc_pts, cyan, 2.0)
	
	for deg in range(5, 46, 3):
		for sgn in [-1.0, 1.0]:
			var a = deg_to_rad(sgn * float(deg))
			var p1 = Vector2(h_c.x + sin(a) * (h_r - 3.5), h_c.y - cos(a) * (h_r - 3.5))
			var p2 = Vector2(h_c.x + sin(a) * (h_r + 4.5), h_c.y - cos(a) * (h_r + 4.5))
			draw_line(p1, p2, cyan_dim, 1.2)
			
	var heading_str = "%05.2f" % heading_deg
	var apex_pos = Vector2(cx, h_c.y - h_r)
	
	# Tactical Sector Location & NVG Mode Banner
	var nvg_tag = "[OPTIC // NVG GEN-3: ACTIVE]" if is_nvg_active else "[OPTIC // DAYLIGHT FLIR: ACTIVE]"
	var nvg_col = Color(0.35, 1.0, 0.5, 0.95) if is_nvg_active else Color(0.35, 0.85, 1.0, 0.85)
	draw_string(font, apex_pos + Vector2(-180.0, -42.0), nvg_tag, HORIZONTAL_ALIGNMENT_CENTER, 360, 10, nvg_col)

	var sector_label = get_sector_name()
	draw_string(font, apex_pos + Vector2(-150.0, -26.0), sector_label, HORIZONTAL_ALIGNMENT_CENTER, 300, 12, cyan_bright)
	draw_line(apex_pos + Vector2(-110.0, -16.0), apex_pos + Vector2(110.0, -16.0), cyan_dim, 1.0)
	
	draw_string(font, apex_pos + Vector2(-22.0, -4.0), heading_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, cyan_bright)
	draw_line(apex_pos + Vector2(-28.0, -12.0), apex_pos + Vector2(-28.0, 1.0), cyan, 1.5)
	draw_line(apex_pos + Vector2(-28.0, -12.0), apex_pos + Vector2(-23.0, -12.0), cyan, 1.5)
	draw_line(apex_pos + Vector2(28.0, -12.0), apex_pos + Vector2(28.0, 1.0), cyan, 1.5)
	draw_line(apex_pos + Vector2(28.0, -12.0), apex_pos + Vector2(23.0, -12.0), cyan, 1.5)
	
	var left_bracket_pts = PackedVector2Array()
	for i in range(16):
		var a = deg_to_rad(-32.0 + (float(i) / 15.0) * 18.0)
		left_bracket_pts.append(Vector2(h_c.x + sin(a) * (h_r + 8.0), h_c.y - cos(a) * (h_r + 8.0)))
	draw_polyline(left_bracket_pts, cyan_dim, 1.5)
	
	var right_bracket_pts = PackedVector2Array()
	for i in range(16):
		var a = deg_to_rad(14.0 + (float(i) / 15.0) * 18.0)
		right_bracket_pts.append(Vector2(h_c.x + sin(a) * (h_r + 8.0), h_c.y - cos(a) * (h_r + 8.0)))
	draw_polyline(right_bracket_pts, cyan_dim, 1.5)
	
	var ret_c = Vector2(cx, H * 0.48)
	var v_start_y = H * 0.10
	var v_end_y = ret_c.y - 18.0
	var tick_y = v_start_y
	while tick_y < v_end_y:
		draw_line(Vector2(cx, tick_y), Vector2(cx, minf(tick_y + 8.0, v_end_y)), cyan_dim, 1.2)
		draw_line(Vector2(cx - 3.5, tick_y), Vector2(cx + 3.5, tick_y), cyan_dim, 1.0)
		tick_y += 16.0
		
	draw_line(ret_c + Vector2(-12, 0), ret_c + Vector2(-3, 0), cyan_bright, 1.8)
	draw_line(ret_c + Vector2(3, 0), ret_c + Vector2(12, 0), cyan_bright, 1.8)
	draw_line(ret_c + Vector2(0, -12), ret_c + Vector2(0, -3), cyan_bright, 1.8)
	draw_line(ret_c + Vector2(0, 3), ret_c + Vector2(0, 12), cyan_bright, 1.8)
	draw_circle(ret_c, 1.5, cyan_bright)
	
	var b_r = 34.0
	draw_arc(ret_c, b_r, deg_to_rad(145.0), deg_to_rad(215.0), 12, cyan, 1.6)
	draw_arc(ret_c, b_r, deg_to_rad(-35.0), deg_to_rad(35.0), 12, cyan, 1.6)
	draw_line(ret_c + Vector2(0, -b_r - 6), ret_c + Vector2(0, -b_r), cyan, 1.5)
	draw_line(ret_c + Vector2(0, b_r), ret_c + Vector2(0, b_r + 6), cyan, 1.5)
	
	# =========================================================================
	# 6. HOLOGRAPHIC VISOR: UPPER-RIGHT TACTICAL RADAR RING
	# =========================================================================
	var radar_c = Vector2(W * 0.81, H * 0.20)
	var r_outer = min(W, H) * 0.125
	var r_inner = min(W, H) * 0.088
	
	draw_arc(radar_c, r_inner, 0, TAU, 36, cyan_glow, 4.0)
	draw_arc(radar_c, r_inner, 0, TAU, 36, cyan, 1.5)
	
	var segments = 28
	for i in range(segments):
		if i % 2 == 0:
			var a1 = (float(i) / segments) * TAU
			var a2 = (float(i + 0.72) / segments) * TAU
			draw_arc(radar_c, r_outer, a1, a2, 4, cyan_dim, 1.5)
	
	for deg in range(0, 360, 30):
		var rad = deg_to_rad(float(deg))
		var p1 = radar_c + Vector2(cos(rad), sin(rad)) * (r_inner - 3.5)
		var p2 = radar_c + Vector2(cos(rad), sin(rad)) * (r_inner + 3.5)
		draw_line(p1, p2, cyan_dim, 1.2)
		
	draw_string(font, radar_c + Vector2(r_outer + 8.0, 4.0), "[SET]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, cyan)
	draw_string(font, radar_c + Vector2(-r_outer - 28.0, 4.0), "(S)", HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, cyan)
	draw_string(font, radar_c + Vector2(-26.0, r_outer + 18.0), "%05.2f m" % enemy_dist, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, cyan_bright)
	
	# Draw radar blips for all active hostile units
	var drawn_enemies = all_enemies if all_enemies.size() > 0 else ([enemy_ref] if enemy_ref else [])
	for enm in drawn_enemies:
		if enm and is_instance_valid(enm) and not enm.is_dead and player_ref:
			var to_e = enm.global_position - player_ref.global_position
			to_e.y = 0.0
			var dist_e = to_e.length()
			var local_e = player_ref.global_transform.basis.inverse() * to_e.normalized()
			var b_rad = atan2(local_e.x, -local_e.z)
			var dist_norm = clampf(dist_e / 450.0, 0.25, 1.0)
			var blip_pos = radar_c + Vector2(sin(b_rad), -cos(b_rad)) * (r_inner * dist_norm)
			var pulse_glow = 3.6 + sin(pulse_timer) * 0.9
			draw_circle(blip_pos, pulse_glow + 2.5, Color(1.0, 0.2, 0.2, 0.35))
			draw_circle(blip_pos, pulse_glow, Color(1.0, 0.3, 0.3, 0.95))
			draw_circle(blip_pos, 1.8, Color(1.0, 0.9, 0.9, 1.0))
		
	# =========================================================================
	# 7. HOLOGRAPHIC VISOR: LOWER-LEFT WEAPON & AMMO COMPUTER FAN
	# =========================================================================
	var ammo_c = Vector2(W * 0.20, H * 0.69)
	
	var fan_pts = PackedVector2Array([
		ammo_c + Vector2(-45, 24),
		ammo_c + Vector2(85, -28),
		ammo_c + Vector2(115, 16),
		ammo_c + Vector2(-12, 56)
	])
	draw_colored_polygon(fan_pts, Color(0.12, 0.75, 0.95, 0.08))
	draw_polyline(fan_pts, cyan_dim, 1.2)
	
	var ammo_text = "04" if not is_reloading else "--"
	var ammo_col = cyan_bright if not is_reloading else Color(1.0, 0.7, 0.2, 0.95)
	draw_string(font, ammo_c + Vector2(-36, -6), ammo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ammo_col)
	
	for s in range(6):
		var sp = ammo_c + Vector2(-30 + s * 15, 16)
		var s_pts = PackedVector2Array([
			sp + Vector2(0, 9),
			sp + Vector2(7, 9),
			sp + Vector2(7, 3),
			sp + Vector2(3.5, 0),
			sp + Vector2(0, 3)
		])
		var is_loaded = (not is_reloading or s < int(reload_ratio * 6))
		var scol = cyan if is_loaded else Color(0.40, 0.50, 0.60, 0.35)
		draw_colored_polygon(s_pts, scol)
		draw_polyline(s_pts, cyan_bright if is_loaded else cyan_dim, 1.0)
		
	draw_string(font, ammo_c + Vector2(86, -6), "0%", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, cyan)
	draw_arc(ammo_c + Vector2(96, -3), 16.0, deg_to_rad(-60.0), deg_to_rad(30.0), 8, cyan, 1.4)
