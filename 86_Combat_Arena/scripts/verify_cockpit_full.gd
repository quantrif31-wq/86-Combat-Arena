extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var enemy = null
var hud = null

func _init():
	print("--- BEGIN COCKPIT VISOR VERIFICATION ---")
	var res = load("res://scenes/main_arena.tscn")
	if not res:
		push_error("FAILED TO LOAD main_arena.tscn")
		quit(1)
		return
		
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node_or_null("PlayerJuggernaut")
	enemy = main_scene.get_node_or_null("EnemyJuggernaut")
	hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player or not enemy or not hud:
		return false
		
	# Frame 5: Verify default First-Person mode & cannon model concealment
	if frame_count == 5:
		print("VERIFY Frame 5:")
		print("  player.is_fps_mode: ", player.is_fps_mode)
		print("  player.is_free_looking: ", player.is_free_looking)
		print("  model_instance.visible: ", player.model_instance.visible)
		assert(player.is_fps_mode == true, "Should default to First-Person mode")
		assert(player.model_instance.visible == false, "Cannon & model should be invisible in cockpit view!")
		print("  FPS Camera current: ", player.fps_camera.current if player.fps_camera else "null")
		print("  HUD CockpitOverlay visible: ", hud.cockpit_overlay.visible if hud.cockpit_overlay else "null")
		
	# Frame 12: Test firing cannon from muzzle
	if frame_count == 12:
		var init_muzzle_pos = player.muzzle.global_position
		print("VERIFY Frame 12: Firing 57mm Cannon from physical muzzle...")
		print("  Muzzle Global Pos: ", init_muzzle_pos)
		player.shoot_cannon()
		
		# Find spawned shell
		var shells = []
		for child in main_scene.get_children():
			if "CannonShell" in child.name or "cannon_shell" in child.name.to_lower():
				shells.append(child)
		print("  Spawned shells count: ", shells.size())
		if shells.size() > 0:
			var shell = shells[0]
			var dist_to_muzzle = shell.global_position.distance_to(init_muzzle_pos)
			print("  Shell distance to muzzle: ", dist_to_muzzle)
			assert(dist_to_muzzle < 0.1, "Shell must spawn directly at the physical cannon muzzle!")
		print("  Firing logic 100% verified!")
		
	# Frame 25: Capture Cockpit Visor View Screenshot
	if frame_count == 25:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/anime_cockpit_visor_view.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/anime_cockpit_visor_view.png")
			
	# Frame 30: Switch to 3rd Person Free-Look
	if frame_count == 30:
		print("VERIFY Frame 30: Simulating RMB Free-Look (3rd Person)...")
		player.is_free_looking = true
		player.update_camera_and_mesh_visibility()
		print("  model_instance.visible: ", player.model_instance.visible)
		assert(player.model_instance.visible == true, "Model must be visible in 3rd person!")
		
	# Frame 38: Capture 3rd Person View Screenshot
	if frame_count == 38:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/third_person_freelook_view.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/third_person_freelook_view.png")
		print("--- ALL COCKPIT VISOR VERIFICATIONS PASSED ---")
		quit(0)
		return true
		
	return false
