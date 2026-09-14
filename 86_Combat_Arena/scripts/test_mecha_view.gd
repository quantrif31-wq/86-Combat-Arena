extends SceneTree

var frame_count = 0
var main_scene = null
var player = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	player = main_scene.get_node_or_null("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	if frame_count == 5:
		player.is_fps_mode = true
		player.is_free_looking = false
		player.model_instance.visible = true
		
		# Scale down cannon bone to invisible so it never obstructs the visor
		var skel = player.skeleton
		if skel and player.cannon_bone_idx >= 0:
			skel.set_bone_pose_scale(player.cannon_bone_idx, Vector3(0.0001, 0.0001, 0.0001))
		if skel and player.turret_bone_idx >= 0:
			skel.set_bone_pose_scale(player.turret_bone_idx, Vector3(0.0001, 0.0001, 0.0001))
			
		# Test camera position inside/above cockpit pod looking forward
		if player.fps_camera:
			player.fps_camera.current = true
			player.fps_camera.position = Vector3(0, 1.45, -0.75)
			player.fps_camera.rotation.x = deg_to_rad(-8.0) # Slight downward gaze so nose & blades are visible!
			
	if frame_count == 15:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/test_cockpit_mecha_view.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/test_cockpit_mecha_view.png")
		quit(0)
		return true
		
	return false
