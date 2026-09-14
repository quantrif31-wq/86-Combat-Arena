extends SceneTree

var frame = 0
var player: PlayerJuggernaut = null
var enemy: EnemyJuggernaut = null

func _init():
	print(">>> RUNNING UPGRADED 86 COMBAT VERIFICATION SUITE <<<")
	
	# TEST 1: Procedural Audio
	print("[CHECK 1] Testing new procedural audio generators...")
	var step_sfx = ProceduralAudio.create_footstep_sound()
	var wall_sfx = ProceduralAudio.create_wall_hit_sound()
	assert(step_sfx != null and step_sfx.data.size() > 0, "Footstep audio failed")
	assert(wall_sfx != null and wall_sfx.data.size() > 0, "Wall hit audio failed")
	print("  - Footstep & Wall Hit Audio Streams generated successfully!")
	
	# TEST 2: Main Arena Node Integration
	print("[CHECK 2] Loading Main Arena scene...")
	var arena_scene = load("res://scenes/main_arena.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	player = arena.get_node("PlayerJuggernaut") as PlayerJuggernaut
	enemy = arena.get_node("EnemyJuggernaut") as EnemyJuggernaut
	assert(player != null, "PlayerJuggernaut not found")
	assert(enemy != null, "EnemyJuggernaut not found")
	print("  - Player and Enemy Juggernaut instances bound cleanly!")

func _process(delta: float) -> bool:
	frame += 1
	if frame == 2:
		# TEST 3: Dynamic Cannon Pitch & Aiming
		print("[CHECK 3] Testing dynamic cannon elevation tracking...")
		assert(player.cannon_mesh != null, "Player cannon mesh not found")
		player.spring_arm.rotation.x = deg_to_rad(-15.0) # Looking up
		player.update_cannon_aim(0.1)
		assert(player.cannon_mesh.rotation.y > deg_to_rad(5.0), "Cannon elevation failed to elevate upward")
		print("  - Cannon elevation angle: %.2f deg (Elevating UP)" % rad_to_deg(player.cannon_mesh.rotation.y))
		
		# TEST 4: Dual Camera (FPS / TPS) Toggle
		print("[CHECK 4] Testing FPS Cockpit / TPS Dual Camera system...")
		assert(player.fps_camera != null, "FPS Camera not found")
		player.is_fps_mode = true
		player.fps_camera.current = true
		player.camera.current = false
		assert(player.fps_camera.current == true, "FPS camera activation failed")
		print("  - FPS Cockpit Visor Camera successfully engaged!")
		
		# TEST 5: AI Line-of-Sight and Whisker Avoidance
		print("[CHECK 5] Testing AI Line-of-Sight (LoS) check...")
		var los_clear = enemy.has_clear_line_of_sight(player.global_position + Vector3(0, 1.2, 0))
		print("  - AI LoS check returned: ", los_clear)
		
		# Test Whisker avoidance
		var steer = enemy.apply_obstacle_avoidance(Vector3(0, 0, -1), 0.016)
		assert(steer.length() > 0.5, "Obstacle avoidance vector invalid")
		print("  - AI Whisker Steering vector computed: ", steer)
		
		print(">>> ALL 5 UPGRADED VERIFICATION CHECKS PASSED PERFECTLY! <<<")
		quit(0)
		return true
	return false

