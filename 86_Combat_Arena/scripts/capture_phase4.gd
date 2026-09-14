extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var enemy = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node_or_null("PlayerJuggernaut")
	enemy = main_scene.get_node_or_null("EnemyJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player or not enemy:
		return false
		
	# Frame 5: Deal lethal blow to enemy to spawn smoking wreck
	if frame_count == 5:
		enemy.take_damage(200.0)
		
	# Frame 10: Setup camera close to the smoking wreck
	if frame_count == 10:
		var wreck_cam = Camera3D.new()
		wreck_cam.name = "WreckCam"
		main_scene.add_child(wreck_cam)
		wreck_cam.global_position = enemy.global_position + Vector3(5.5, 3.2, 5.0)
		wreck_cam.look_at(enemy.global_position + Vector3(0, 0.8, 0), Vector3.UP)
		wreck_cam.current = true
		
	# Frame 20: Capture smoking wreck
	if frame_count == 20:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_wreck_smoke.png")
			print("Saved forest_ruins_wreck_smoke.png")
			
	# Frame 25: Setup Critical HP on Player in FPS mode
	if frame_count == 25:
		player.is_fps_mode = true
		if player.fps_camera:
			player.fps_camera.current = true
		player.take_damage(75.0) # Integrity 25/100
		var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
		if hud:
			hud.banner_box.visible = false # hide victory banner so warning is clearly visible
			if hud.cockpit_overlay:
				hud.cockpit_overlay.visible = true
				
	# Frame 32: Capture Critical HP cockpit HUD
	if frame_count == 32:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_critical_hp_hud.png")
			print("Saved forest_ruins_critical_hp_hud.png")
		quit(0)
		return true
		
	return false
