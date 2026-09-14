extends SceneTree

var frame_count = 0
var root_node = null

func _init():
	root_node = Node3D.new()
	root.add_child(root_node)
	
	var model_res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var model = model_res.instantiate()
	model.rotation.z = 270 * PI / 180.0
	root_node.add_child(model)
	
	# Camera behind looking over the unit
	var cam = Camera3D.new()
	root_node.add_child(cam)
	cam.position = Vector3(0, 3.5, 6.5)
	cam.look_at(Vector3(0, 1.0, -10.0), Vector3.UP)
	cam.current = true
	cam.fov = 65.0
	
	var light = DirectionalLight3D.new()
	root_node.add_child(light)
	light.rotation_degrees = Vector3(-45, 135, 0)
	light.light_energy = 1.8
	
	var env = WorldEnvironment.new()
	root_node.add_child(env)
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.28, 0.32)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.45, 0.5)
	env.environment = e

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 10:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\roll_test_270.png")
		quit(0)
		return true
	return false
