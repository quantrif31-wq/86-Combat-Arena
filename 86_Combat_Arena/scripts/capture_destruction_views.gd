extends SceneTree

func _init() -> void:
	print("--- Capturing Battlefield Destruction Cinematic Screenshots ---")
	call_deferred("_start_capture")

func _start_capture() -> void:
	var arena_scene = load("res://scenes/main_arena.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	# Wait for terrain snapping and initialization
	for i in range(12):
		await process_frame
		
	# Free CanvasLayer so all 2D cockpit overlays and HUD are eliminated
	var canvas = arena.get_node_or_null("CanvasLayer")
	if canvas:
		canvas.queue_free()
		
	var player = arena.get_node_or_null("PlayerJuggernaut")
	if player:
		var fps_cam = player.get_node_or_null("FPSCamera3D")
		if fps_cam:
			fps_cam.current = false
		var tps_cam = player.find_child("Camera3D", true, false)
		if tps_cam and tps_cam is Camera3D:
			tps_cam.current = false
		player.visible = false
		
	# Find an optimal pine tree to shatter
	var tree_idx = 10
	if arena.pine_transforms.size() <= tree_idx:
		tree_idx = 0
	var tree_tf = arena.pine_transforms[tree_idx]
	print("DEBUG: tree scale: ", tree_tf.basis.get_scale(), " mesh AABB: ", arena.pine_shared_mesh.get_aabb())
	var hit_pos = tree_tf.origin + Vector3(0, 6.8, 0) # Hit trunk at 6.8m elevation
	var push_dir = Vector3(0.85, 0.1, 0.5).normalized()
	arena.shatter_tree(tree_idx, hit_pos, push_dir)
	
	# Add illumination light for dramatic battlefield photography
	var key_light = OmniLight3D.new()
	key_light.position = tree_tf.origin + Vector3(-8, 9, -10)
	key_light.light_color = Color(1.0, 0.92, 0.85)
	key_light.light_energy = 5.0
	key_light.omni_range = 45.0
	arena.add_child(key_light)
	
	# Drone Camera placed close to the shattered tree in clear line of sight
	var cam = Camera3D.new()
	cam.fov = 65.0
	arena.add_child(cam)
	cam.global_position = tree_tf.origin + Vector3(-6.5, 4.2, 7.5)
	cam.look_at(tree_tf.origin + Vector3(0, 3.8, 0), Vector3.UP)
	cam.current = true
	
	# Simulate 35 physics frames while trunk topples dramatically
	for i in range(35):
		await physics_frame
		await process_frame
		
	var d_tree = arena.get_node_or_null("DestructibleTree")
	if d_tree:
		print("DEBUG: Stump pos: ", d_tree.stump_mesh.global_position)
		print("DEBUG: Falling body pos: ", d_tree.falling_body.global_position, " rot: ", d_tree.falling_body.rotation_degrees)
	else:
		# Maybe DestructibleTree was added to Sector86_Grand_Warzone
		var found = arena.find_child("DestructibleTree", true, false)
		if found:
			print("DEBUG: Found d_tree in child: ", found.name, " falling pos: ", found.falling_body.global_position, " rot: ", found.falling_body.rotation_degrees)
		
	var tex = root.get_texture()
	var img = tex.get_image()
	if img:
		var out_path = "C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5/preview_destruction_drone.png"
		img.save_png(out_path)
		img.save_png("C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5/preview_tree_destruction.png")
		print("SUCCESS: Captured drone tree destruction screenshot to %s" % out_path)
		
	arena.queue_free()
	quit(0)

