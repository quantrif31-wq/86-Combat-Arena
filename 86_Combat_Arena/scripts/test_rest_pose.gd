extends SceneTree

var frame_count = 0
var scene_root = null

func _init():
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	# Load model
	var model_res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var model = model_res.instantiate()
	root_node.add_child(model)
	
	# Force rest pose (stop all animations)
	var anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		anim.stop()
		
	# Camera looking at model from 3/4 angle
	var cam = Camera3D.new()
	root_node.add_child(cam)
	cam.position = Vector3(5, 3, 5)
	cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	cam.current = true
	
	# Sun light
	var light = DirectionalLight3D.new()
	root_node.add_child(light)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 2.0
	
	var env = WorldEnvironment.new()
	root_node.add_child(env)
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.18, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.4, 0.4)
	env.environment = e

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 10:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\model_rest_pose.png")
		quit(0)
		return true
	return false
