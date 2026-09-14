extends SceneTree

var frame_count = 0
var main_scene = null
var player = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 15:
		# 1. Capture standard TPS view
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\combat_arena_gameplay.png")
			print("Saved TPS shot")
			
		# Switch to FPS mode
		if player:
			player.is_fps_mode = true
			if player.fps_camera:
				player.fps_camera.current = true
			if player.camera:
				player.camera.current = false
				
	if frame_count == 25:
		# 2. Capture FPS Cockpit view
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\combat_arena_fps_cockpit.png")
			print("Saved FPS shot")
			
		# Switch back to TPS and elevate cannon up
		if player:
			player.is_fps_mode = false
			if player.camera:
				player.camera.current = true
			if player.fps_camera:
				player.fps_camera.current = false
			player.spring_arm.rotation.x = deg_to_rad(-18.0)
			
	if frame_count == 35:
		# 3. Capture Elevated Cannon shot
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\combat_arena_cannon_elevated.png")
			print("Saved Elevated shot")
		quit(0)
		return true
	return false
