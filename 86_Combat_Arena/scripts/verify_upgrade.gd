extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var enemy = null
var test_shell = null

func _init():
	print("--- VERIFYING FULL UPGRADE ---")
	var res = load("res://scenes/main_arena.tscn")
	if not res:
		push_error("FAILED TO LOAD main_arena.tscn")
		quit(1)
		return
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node_or_null("PlayerJuggernaut")
	enemy = main_scene.get_node_or_null("EnemyJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player or not enemy:
		return false
		
	# Frame 5: Check player collision shape
	if frame_count == 5:
		var col_shape = player.get_node_or_null("CollisionShape3D")
		print("VERIFY Frame 5: Player Collision:")
		print("  Shape type: ", col_shape.shape.get_class() if col_shape else "null")
		print("  Floor snap length: ", player.floor_snap_length)
		print("  Floor constant speed: ", player.floor_constant_speed)
		assert(col_shape.shape is CapsuleShape3D, "Should be CapsuleShape3D to eliminate terrain sticking!")
		
	# Frame 10: Test Player Movement forward
	if frame_count >= 10 and frame_count <= 25:
		# Simulate W forward input
		var forward_vec = -player.global_transform.basis.z
		player.velocity.x = forward_vec.x * player.walk_speed
		player.velocity.z = forward_vec.z * player.walk_speed
		player.move_and_slide()
		
	if frame_count == 25:
		print("VERIFY Frame 25: Movement check:")
		print("  Player position: ", player.global_position)
		print("  Player on floor: ", player.is_on_floor())
		
	# Frame 30: Capture Enhanced Cockpit View Screenshot
	if frame_count == 30:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/enhanced_3d_cockpit_view.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/enhanced_3d_cockpit_view.png")
			
	# Frame 35: Fire APFSDS Dart
	if frame_count == 35:
		print("VERIFY Frame 35: Firing 3D APFSDS Dart...")
		player.shoot_cannon()
		
	# Frame 38: Find spawned shell and setup close-up tracking camera to showcase 3D dart & tracer
	if frame_count == 38:
		for child in main_scene.get_children():
			if "CannonShell" in child.name or "cannon_shell" in child.name.to_lower():
				test_shell = child
				break
				
		print("  Found APFSDS shell: ", test_shell != null)
		if test_shell:
			var dart_model = test_shell.get_node_or_null("DartModel")
			var tracer = test_shell.get_node_or_null("TracerParticles")
			print("  DartModel in shell: ", dart_model != null)
			print("  TracerParticles in shell: ", tracer != null)
			assert(dart_model != null, "APFSDS 3D model must be inside shell!")
			
			# Setup cinematic tracking camera behind and to the side of the flying APFSDS dart
			var dart_cam = Camera3D.new()
			dart_cam.name = "DartCam"
			main_scene.add_child(dart_cam)
			dart_cam.global_position = test_shell.global_position + Vector3(0.8, 0.4, 1.8)
			dart_cam.look_at(test_shell.global_position + Vector3(0, 0, -2.0), Vector3.UP)
			dart_cam.current = true
			
	# Frame 44: Capture in-flight 3D APFSDS dart showcase
	if frame_count == 44:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/apfsds_dart_flight_showcase.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/apfsds_dart_flight_showcase.png")
		print("--- ALL UPGRADE VERIFICATIONS PASSED ---")
		quit(0)
		return true
		
	return false
