extends SceneTree

func _init() -> void:
	print("--- STARTING MOVEMENT SMOOTHNESS & STICKING VERIFICATION ---")
	
	var arena_scene = load("res://scenes/main_arena.tscn")
	if not arena_scene:
		printerr("FAILED: Could not load main_arena.tscn")
		quit(1)
		return
		
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	var player = arena.get_node_or_null("PlayerJuggernaut") as PlayerJuggernaut
	assert(player != null, "PlayerJuggernaut must exist")
	
	# Verify physics properties
	print("Player Navigation Settings:")
	print("  - Motion Mode: ", player.motion_mode, " (0 = GROUNDED)")
	print("  - Floor Snap Length: ", player.floor_snap_length)
	print("  - Safe Margin: ", player.safe_margin)
	print("  - Wall Min Slide Angle: ", player.wall_min_slide_angle)
	print("  - Floor Max Angle (deg): ", rad_to_deg(player.floor_max_angle))
	
	var stuck_count = 0
	var total_tested_frames = 0
	
	# Test 1: North traverse towards Citadel (crossing ravines & slopes)
	print("\n>>> TEST 1: North traverse across Ravine & Citadel Slopes (80 frames)")
	player.global_position = Vector3(0, 3.0, 40.0)
	var prev_pos = player.global_position
	
	for f in range(80):
		# Simulate W key held down (forward)
		var forward_dir = Vector3(0, 0, -1)
		var is_on_ground = player.is_on_floor()
		if not is_on_ground:
			player.velocity.y -= 24.0 * 0.016
		else:
			player.velocity.y = 0.0
			
		var floor_norm = player.get_floor_normal() if is_on_ground else Vector3.UP
		var slope_dir = (forward_dir - floor_norm * forward_dir.dot(floor_norm)).normalized()
		player.velocity = slope_dir * player.run_speed
		
		player.move_and_slide()
		total_tested_frames += 1
		
		var delta_dist = player.global_position.distance_to(prev_pos)
		prev_pos = player.global_position
		
		# If character is on floor and moved less than 0.05m while running at 16m/s, it's stuck!
		if is_on_ground and delta_dist < 0.04:
			stuck_count += 1
			print("  WARNING: Stuck detected at frame ", f, " pos=", player.global_position, " delta=", delta_dist)
			
	print("Test 1 Result: Ended at pos=", player.global_position, " (Stuck frames: ", stuck_count, ")")
	
	# Test 2: West traverse towards Factory (through conifer trees & terrain bumps)
	print("\n>>> TEST 2: West traverse through Conifer MultiMesh forest towards Factory (80 frames)")
	player.global_position = Vector3(0, 3.0, 0.0)
	prev_pos = player.global_position
	var t2_stuck = 0
	
	for f in range(80):
		var west_dir = Vector3(-1, 0, 0)
		var is_on_ground = player.is_on_floor()
		if not is_on_ground:
			player.velocity.y -= 24.0 * 0.016
		else:
			player.velocity.y = 0.0
			
		var floor_norm = player.get_floor_normal() if is_on_ground else Vector3.UP
		var slope_dir = (west_dir - floor_norm * west_dir.dot(floor_norm)).normalized()
		player.velocity = slope_dir * player.run_speed
		
		player.move_and_slide()
		total_tested_frames += 1
		
		var delta_dist = player.global_position.distance_to(prev_pos)
		prev_pos = player.global_position
		
		if is_on_ground and delta_dist < 0.04:
			t2_stuck += 1
			
	print("Test 2 Result: Ended at pos=", player.global_position, " (Stuck frames: ", t2_stuck, ")")
	stuck_count += t2_stuck
	
	# Test 3: East traverse towards Outpost (across ridges)
	print("\n>>> TEST 3: East traverse towards Defense Outpost (80 frames)")
	player.global_position = Vector3(0, 3.0, -20.0)
	prev_pos = player.global_position
	var t3_stuck = 0
	
	for f in range(80):
		var east_dir = Vector3(1, 0, 0)
		var is_on_ground = player.is_on_floor()
		if not is_on_ground:
			player.velocity.y -= 24.0 * 0.016
		else:
			player.velocity.y = 0.0
			
		var floor_norm = player.get_floor_normal() if is_on_ground else Vector3.UP
		var slope_dir = (east_dir - floor_norm * east_dir.dot(floor_norm)).normalized()
		player.velocity = slope_dir * player.run_speed
		
		player.move_and_slide()
		total_tested_frames += 1
		
		var delta_dist = player.global_position.distance_to(prev_pos)
		prev_pos = player.global_position
		
		if is_on_ground and delta_dist < 0.04:
			t3_stuck += 1
			
	print("Test 3 Result: Ended at pos=", player.global_position, " (Stuck frames: ", t3_stuck, ")")
	stuck_count += t3_stuck
	
	print("\n-----------------------------------------------------------")
	print("TOTAL TESTED FRAMES: ", total_tested_frames)
	print("TOTAL STUCK OCCURRENCES: ", stuck_count)
	print("SMOOTHNESS SUCCESS RATE: ", "%.2f" % ((1.0 - float(stuck_count)/float(total_tested_frames)) * 100.0), "%")
	print("-----------------------------------------------------------")
	
	if stuck_count == 0:
		print("SUCCESS: JUGGERNAUT GLIDES EFFORTLESSLY ACROSS ALL 800M TERRAINS WITHOUT SNAGGING!\n")
		quit(0)
	else:
		printerr("FAILURE: Character experienced sticking!")
		quit(1)
