extends SceneTree

var frame_count: int = 0
var main_scene: Node = null
var title_scene: Node = null
var cine_cam: Camera3D = null

const ARTIFACT_DIR = "C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5"

func _init() -> void:
	print("--- LAUNCHING SCREENSHOT CAPTURE FOR CHAPTER 1 MISSION ---")
	var scene_res = load("res://scenes/chapter_1_mission.tscn")
	if not scene_res:
		printerr("ERROR: Failed to load chapter_1_mission.tscn")
		quit(1)
		return
	main_scene = scene_res.instantiate()
	root.add_child(main_scene)
	
	# Setup cinematic drone camera
	cine_cam = Camera3D.new()
	cine_cam.name = "CinematicDroneCamera"
	cine_cam.fov = 68.0
	cine_cam.far = 1200.0
	main_scene.add_child(cine_cam)
	
	# Position 1: Overlooking the Forward Base and Rear Village in High Noon
	cine_cam.position = Vector3(0.0, 32.0, -55.0)
	cine_cam.look_at(Vector3(0.0, 8.0, 75.0), Vector3.UP)
	cine_cam.current = true

func _process(_delta: float) -> bool:
	frame_count += 1
	
	# Frame 30: Capture High Noon Base with Radar tower, Outpost, hedgehogs, Raiden, Kurena
	if frame_count == 30:
		var img1 = root.get_viewport().get_texture().get_image()
		if img1:
			var p1 = ARTIFACT_DIR + r"\preview_chapter1_noon_base.png"
			img1.save_png(p1)
			print("PASS: Saved High Noon Base preview to: ", p1)
			
		# Now trigger Phase 2: Midnight Siege
		if main_scene.has_method("_on_proceed_to_phase_2"):
			main_scene._on_proceed_to_phase_2()
			print("--> Switched to Phase 2: Midnight Siege")
			
		# Re-position cinematic camera to focus on Shepherd Boss in the night
		var shep = main_scene.get("shepherd_unit")
		if shep:
			var s_pos = shep.global_position
			cine_cam.position = s_pos + Vector3(14.0, 5.5, 20.0)
			cine_cam.look_at(s_pos + Vector3(0.0, 2.0, 0.0), Vector3.UP)
		else:
			cine_cam.position = Vector3(0.0, 15.0, -180.0)
			cine_cam.look_at(Vector3(0.0, 5.0, -240.0), Vector3.UP)
			
	# Frame 60: Capture Midnight Siege with Legion Shepherd Boss & Red Aura
	if frame_count == 60:
		var img2 = root.get_viewport().get_texture().get_image()
		if img2:
			var p2 = ARTIFACT_DIR + r"\preview_chapter1_midnight_shepherd.png"
			img2.save_png(p2)
			print("PASS: Saved Midnight Shepherd preview to: ", p2)
			
		# Switch to Title Screen to capture updated menu with Chapter 1 button
		main_scene.queue_free()
		var title_res = load("res://scenes/title_screen.tscn")
		if title_res:
			title_scene = title_res.instantiate()
			root.add_child(title_scene)
			print("--> Instantiated Title Screen for menu capture")
			
	# Frame 90: Capture Title Screen with Chapter 1 Sortie Button
	if frame_count == 90:
		var img3 = root.get_viewport().get_texture().get_image()
		if img3:
			var p3 = ARTIFACT_DIR + r"\preview_title_with_chapter.png"
			img3.save_png(p3)
			print("PASS: Saved Title Screen with Chapter 1 preview to: ", p3)
			
		print("--- ALL PREVIEW SCREENSHOTS CAPTURED SUCCESSFULLY ---")
		quit(0)
		
	return false
