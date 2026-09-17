extends Control
class_name ParaRaidWaveform

var time: float = 0.0
var base_freq: float = 0.024
var sync_intensity: float = 1.0

func _process(delta: float) -> void:
	time += delta * 4.5
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var cy = h * 0.5
	
	if w <= 10.0 or h <= 10.0:
		return
		
	# 1. Subtle background grid
	var grid_col = Color(0.18, 0.35, 0.45, 0.25)
	var axis_col = Color(0.35, 0.55, 0.65, 0.45)
	
	# Horizontal centerline
	draw_line(Vector2(0, cy), Vector2(w, cy), axis_col, 1.0)
	
	# Horizontal upper/lower bounds
	draw_line(Vector2(0, cy - h * 0.35), Vector2(w, cy - h * 0.35), grid_col, 1.0)
	draw_line(Vector2(0, cy + h * 0.35), Vector2(w, cy + h * 0.35), grid_col, 1.0)
	
	# Vertical tick marks
	var step = 40.0
	for x in range(0, int(w), int(step)):
		draw_line(Vector2(x, cy - 4), Vector2(x, cy + 4), grid_col, 1.0)
		
	# 2. Compute Waveform Points
	var points = PackedVector2Array()
	var points_glow = PackedVector2Array()
	var num_pts = int(w / 3.0) + 1
	
	var amp = h * 0.32 * sync_intensity
	
	for i in range(num_pts):
		var x = float(i) * 3.0
		if x > w:
			x = w
			
		# Multi-harmonic brainwave calculation
		# Fundamental + 2nd Harmonic + Fast Modulation + Traveling Packet
		var envelope = sin((x / w) * PI) # Tapers smoothly at edges
		var phase = x * base_freq - time
		var w1 = sin(phase)
		var w2 = sin(phase * 2.3 + time * 0.5) * 0.42
		var w3 = sin(phase * 4.8 - time * 1.2) * 0.18
		
		# Occasional resonant spike
		var spike = exp(-pow((x - fmod(time * 65.0, w)) / 32.0, 2.0)) * 0.65
		
		var y = cy + (w1 + w2 + w3 + spike) * amp * envelope
		points.append(Vector2(x, y))
		
	# 3. Draw Soft Glowing Halo Line (Crimson / Coral Red)
	if points.size() >= 2:
		draw_polyline(points, Color(0.95, 0.22, 0.28, 0.35), 4.5, true)
		# 4. Draw Crisp Core Beam Line (Bright Cyan-White or Vivid Crimson)
		draw_polyline(points, Color(1.0, 0.85, 0.88, 0.95), 1.6, true)
		
	# 5. Draw Pulse Nodes (Nodes along the wave)
	var node_pulse = fmod(time * 50.0, w)
	var node_y = cy + sin(node_pulse * base_freq - time) * amp * sin((node_pulse / w) * PI)
	draw_circle(Vector2(node_pulse, node_y), 3.5, Color(1.0, 0.95, 0.95, 0.9))
	draw_arc(Vector2(node_pulse, node_y), 7.0, 0.0, TAU, 16, Color(0.95, 0.25, 0.3, 0.6), 1.5)
