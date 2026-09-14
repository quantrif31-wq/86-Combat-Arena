extends SceneTree

func _init() -> void:
	process_frame.connect(_render, CONNECT_ONE_SHOT)

func _render() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var light = DirectionalLight3D.new()
	light.rotation = Vector3(-0.7, 0.5, 0.0)
	root_node.add_child(light)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 3.0, 6.0)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.current = true
	root_node.add_child(cam)
	
	var model_scene = load("res://assets/models/m1a4_juggernaut_player.glb")
	var model = model_scene.instantiate()
	root_node.add_child(model)
	
	await process_frame
	await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/raw_model_view.png")
	print("Saved raw_model_view.png")
	quit(0)
