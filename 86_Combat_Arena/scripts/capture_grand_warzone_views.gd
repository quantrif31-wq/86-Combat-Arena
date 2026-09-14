extends SceneTree

var frame_count = 0
var main_scene = null

func _init():
	print("--- LAUNCHING SCREENSHOT CAPTURE FOR GRAND WARZONE ---")
	var scene_res = load("res://scenes/main_arena.tscn")
	if not scene_res:
		print("ERROR: Failed to load main_arena.tscn")
		quit(1)
		return
	main_scene = scene_res.instantiate()
	root.add_child(main_scene)

func _process(delta: float) -> bool:
	frame_count += 1
	
	# Wait for materials, lighting, shaders, and physics to stabilize
	if frame_count == 25:
		var img1 = root.get_viewport().get_texture().get_image()
		if img1:
			var p1 = r"C:\Users\suhai\.gemini\antigravity\brain\bca26e21-664d-4802-b554-27a502f0d8bf\grand_warzone_cockpit_view.png"
			img1.save_png(p1)
			print("Saved cockpit view screenshot to: ", p1)
			
		# Switch to Grand Panoramic Battlefield Camera
		var grand_cam = Camera3D.new()
		grand_cam.position = Vector3(0, 75.0, 220.0)
		grand_cam.look_at(Vector3(0, 8.0, -40.0), Vector3.UP)
		grand_cam.current = true
		grand_cam.fov = 70.0
		grand_cam.far = 3000.0
		main_scene.add_child(grand_cam)
		
		# Temporarily hide HUD canvas layer for clean cinematic landscape view
		var cl = main_scene.get_node_or_null("CanvasLayer")
		if cl:
			cl.visible = false

	if frame_count == 35:
		var img2 = root.get_viewport().get_texture().get_image()
		if img2:
			var p2 = r"C:\Users\suhai\.gemini\antigravity\brain\bca26e21-664d-4802-b554-27a502f0d8bf\grand_warzone_panoramic_view.png"
			img2.save_png(p2)
			print("Saved panoramic battlefield screenshot to: ", p2)
			
		quit(0)
		return true
		
	return false
