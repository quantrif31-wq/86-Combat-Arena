extends SceneTree

var frame_count = 0
var root_node = null

func _init():
	root_node = Node3D.new()
	root.add_child(root_node)
	
	# Load model
	var model_res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var model = model_res.instantiate()
	model.rotation.y = PI
	root_node.add_child(model)
	
	# Reset all pose bone transforms to exact identity/rest pose
	var skel = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel:
		for i in range(skel.get_bone_count()):
			skel.set_bone_pose_position(i, Vector3.ZERO)
			skel.set_bone_pose_rotation(i, Quaternion.IDENTITY)
			skel.set_bone_pose_scale(i, Vector3.ONE)
			
	var anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		anim.stop()
		
	# 3rd-person Camera directly behind Juggernaut
	var cam = Camera3D.new()
	root_node.add_child(cam)
	cam.position = Vector3(0, 2.2, 5.0)
	cam.look_at(Vector3(0, 1.4, -10.0), Vector3.UP)
	cam.current = true
	cam.fov = 70.0
	
	# Ground
	var ground = MeshInstance3D.new()
	var pmesh = PlaneMesh.new()
	pmesh.size = Vector2(40, 40)
	ground.mesh = pmesh
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.22, 0.21, 0.20)
	ground.material_override = gmat
	root_node.add_child(ground)
	
	# Sun light
	var light = DirectionalLight3D.new()
	root_node.add_child(light)
	light.rotation_degrees = Vector3(-40, 140, 0)
	light.light_energy = 1.6
	light.shadow_enabled = true
	
	var env = WorldEnvironment.new()
	root_node.add_child(env)
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.38, 0.42)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.45, 0.5)
	env.environment = e

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 10:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\juggernaut_player_view.png")
		quit(0)
		return true
	return false
