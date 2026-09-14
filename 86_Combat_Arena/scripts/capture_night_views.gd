extends SceneTree

var frame_count = 0
var main_scene = null

func _init():
	print("--- LAUNCHING SCREENSHOT CAPTURE FOR NIGHT MODE & NVG ---")
	var scene_res = load("res://scenes/main_arena.tscn")
	if not scene_res:
		print("ERROR: Failed to load main_arena.tscn")
		quit(1)
		return
	main_scene = scene_res.instantiate()
	root.add_child(main_scene)

func _process(delta: float) -> bool:
	frame_count += 1
	
	# Frame 25: Capture Cockpit View with NVG active (Default mode)
	if frame_count == 25:
		var img1 = root.get_viewport().get_texture().get_image()
		if img1:
			var p1 = r"C:\Users\suhai\.gemini\antigravity\brain\bca26e21-664d-4802-b554-27a502f0d8bf\night_vision_cockpit_view.png"
			img1.save_png(p1)
			print("Saved NVG cockpit screenshot to: ", p1)
			
		# Toggle NVG off on player/hud to capture natural moonlight night view
		var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
		if hud and hud.has_method("set_night_vision"):
			hud.set_night_vision(false)
			
	# Frame 35: Capture Cockpit View with NVG OFF (showing dark moonlit atmospheric night)
	if frame_count == 35:
		var img2 = root.get_viewport().get_texture().get_image()
		if img2:
			var p2 = r"C:\Users\suhai\.gemini\antigravity\brain\bca26e21-664d-4802-b554-27a502f0d8bf\night_moonlight_cockpit_view.png"
			img2.save_png(p2)
			print("Saved moonlit natural cockpit screenshot to: ", p2)
			
		# Switch to Grand Panoramic Battlefield Camera showing the starry night sky
		var grand_cam = Camera3D.new()
		main_scene.add_child(grand_cam)
		grand_cam.position = Vector3(0, 85.0, 240.0)
		grand_cam.look_at(Vector3(0, 10.0, -30.0), Vector3.UP)
		grand_cam.current = true
		grand_cam.fov = 72.0
		grand_cam.far = 1500.0
		
		# Hide HUD canvas layer for clean cinematic landscape view
		var cl = main_scene.get_node_or_null("CanvasLayer")
		if cl:
			cl.visible = false

	# Frame 45: Capture Panoramic Night Battlefield with Starry Sky
	if frame_count == 45:
		var img3 = root.get_viewport().get_texture().get_image()
		if img3:
			var p3 = r"C:\Users\suhai\.gemini\antigravity\brain\bca26e21-664d-4802-b554-27a502f0d8bf\night_battlefield_panoramic_view.png"
			img3.save_png(p3)
			print("Saved starry night panoramic screenshot to: ", p3)
			
		print("--- NIGHT VIEWS CAPTURE COMPLETE! ---")
		quit(0)
		return true
		
	return false
