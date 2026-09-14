extends SceneTree

var frame_count = 0
var main_scene = null
var player = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node_or_null("PlayerJuggernaut")
	
	# Hide old cockpit overlay
	var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
	if hud:
		if hud.has_node("CockpitOverlay"):
			hud.get_node("CockpitOverlay").visible = false
		if hud.has_node("CenterCrosshair"):
			hud.get_node("CenterCrosshair").visible = false
		if hud.has_node("TopLeft/VBox"):
			# keep Para-RAID header clean
			pass
			
		# Attach new anime cockpit visor overlay
		var visor_script = load("res://scratch/test_cockpit_view.gd")
		if not visor_script:
			visor_script = load("C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\scratch\test_cockpit_view.gd")
		var visor = Control.new()
		visor.name = "AnimeCockpitVisor"
		visor.set_script(visor_script)
		visor.set_anchors_preset(Control.PRESET_FULL_RECT)
		visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(visor)

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	# In FPS mode, hide the mecha model so the cannon barrel does not block the pilot view!
	if frame_count == 5:
		player.is_fps_mode = true
		if player.fps_camera:
			player.fps_camera.current = true
		if player.camera:
			player.camera.current = false
		if player.model_instance:
			player.model_instance.visible = false
			
	if frame_count == 15:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/preview_anime_cockpit.png")
			print("Saved preview_anime_cockpit.png successfully!")
		quit(0)
		return true
		
	return false
