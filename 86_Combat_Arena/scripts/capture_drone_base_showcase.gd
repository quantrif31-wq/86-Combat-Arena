extends SceneTree

var frame_count: int = 0
var main_scene: Node = null
var cine_cam: Camera3D = null

const ARTIFACT_DIR = "C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5"

func _init() -> void:
	var scene_res = load("res://scenes/chapter_1_mission.tscn")
	if not scene_res:
		quit(1)
		return
	main_scene = scene_res.instantiate()
	root.add_child(main_scene)
	
	# Create elevated external cinematic camera
	cine_cam = Camera3D.new()
	cine_cam.name = "ThirdPersonCinematicCam"
	cine_cam.fov = 68.0
	cine_cam.far = 1200.0
	main_scene.add_child(cine_cam)
	
	# Elevated front-angle drone overlooking Base Core, hedgehogs, Allies, and Village behind
	cine_cam.position = Vector3(22.0, 14.0, -5.0)
	cine_cam.current = true
	
	# Disable HUD for pure cinematic shot
	var cl = main_scene.get_node_or_null("CanvasLayer")
	if cl:
		cl.visible = false

func _process(_delta: float) -> bool:
	frame_count += 1
	
	if frame_count <= 2:
		var ply = main_scene.get_node_or_null("PlayerJuggernaut")
		if ply:
			var cam1 = ply.get_node_or_null("FPSCamera3D")
			if cam1: cam1.current = false
			var cam2 = ply.get_node_or_null("SpringArm3D/Camera3D")
			if cam2: cam2.current = false
		cine_cam.make_current()
		cine_cam.position = Vector3(-25.0, 16.0, 10.0)
		cine_cam.look_at(Vector3(0.0, 6.0, 45.0), Vector3.UP)
	
	# Frame 25: Capture High Noon Base with allies and village
	if frame_count == 25:
		cine_cam.make_current()
		cine_cam.position = Vector3(-25.0, 16.0, 10.0)
		cine_cam.look_at(Vector3(0.0, 6.0, 45.0), Vector3.UP)
		var img1 = root.get_viewport().get_texture().get_image()
		if img1:
			var p1 = ARTIFACT_DIR + "/preview_chapter1_drone_base.png"
			img1.save_png(p1)
			print("PASS: Saved Drone Base preview to: ", p1)
			
		# Switch to Phase 2: Midnight Siege
		if main_scene.has_method("_on_proceed_to_phase_2"):
			main_scene._on_proceed_to_phase_2()
			
		# Position camera looking at Shepherd Boss
		var shep = main_scene.get("shepherd_unit")
		if shep:
			var s_pos = shep.global_position
			cine_cam.position = s_pos + Vector3(8.0, 3.5, 14.0)
			cine_cam.look_at(s_pos + Vector3(0.0, 1.8, 0.0), Vector3.UP)
		else:
			cine_cam.position = Vector3(8.0, 5.0, -215.0)
			cine_cam.look_at(Vector3(0.0, 2.8, -235.0), Vector3.UP)
		cine_cam.make_current()
			
	# Frame 50: Capture Midnight Shepherd Boss close-up with crimson eyes & aura
	if frame_count == 50:
		cine_cam.make_current()
		var img2 = root.get_viewport().get_texture().get_image()
		if img2:
			var p2 = ARTIFACT_DIR + "/preview_chapter1_drone_shepherd.png"
			img2.save_png(p2)
			print("PASS: Saved Drone Shepherd preview to: ", p2)
			
		quit(0)
		
	return false
