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
	if not player:
		return false
		
	# Frame 10: Cockpit First-Person Perspective
	if frame_count == 10:
		player.is_fps_mode = true
		if player.fps_camera:
			player.fps_camera.current = true
		if player.camera:
			player.camera.current = false
		var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
		if hud and hud.cockpit_overlay:
			hud.cockpit_overlay.visible = true
			
	if frame_count == 14:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_fps_cockpit.png")
			print("Saved forest_ruins_fps_cockpit.png")
			
	# Frame 18: Third-Person Perspective behind Juggernaut
	if frame_count == 18:
		player.is_fps_mode = false
		if player.fps_camera:
			player.fps_camera.current = false
		if player.camera:
			player.camera.current = true
		if player.spring_arm:
			player.spring_arm.spring_length = 7.0
			player.spring_arm.position = Vector3(0, 1.8, 0)
			# Look slightly from right quarter angle (yaw 15 deg)
			player.spring_arm.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(15.0), 0.0)
		var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
		if hud and hud.cockpit_overlay:
			hud.cockpit_overlay.visible = false
			
	if frame_count == 24:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_tps_overview.png")
			print("Saved forest_ruins_tps_overview.png")
			
	# Frame 28: Cinematic Wide Angle Camera showing full battlefield & both mechas
	if frame_count == 28:
		var cine_cam = Camera3D.new()
		cine_cam.name = "CinematicShowcaseCamera"
		main_scene.add_child(cine_cam)
		# Place camera on eastern rampart elevation looking down diagonally across the courtyard
		cine_cam.position = Vector3(16.0, 7.0, 18.0)
		cine_cam.look_at(Vector3(-2.0, 1.0, 2.0), Vector3.UP)
		cine_cam.current = true
		
	if frame_count == 35:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_cinematic_combat.png")
			print("Saved forest_ruins_cinematic_combat.png")
		quit(0)
		return true
		
	return false
