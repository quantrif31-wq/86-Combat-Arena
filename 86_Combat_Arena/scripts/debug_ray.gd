extends SceneTree

func _init() -> void:
	process_frame.connect(_test, CONNECT_ONE_SHOT)

func _test() -> void:
	var arena = load('res://scenes/main_arena.tscn').instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	
	var player = arena.get_node('PlayerJuggernaut')
	var cam = player.camera
	print('Camera global pos:', cam.global_position)
	print('Camera forward:', -cam.global_transform.basis.z)
	
	var space_state = player.get_world_3d().direct_space_state
	var ray_origin = cam.global_position
	var ray_forward = -cam.global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_forward * 200.0, 1 | 2)
	query.exclude = [player]
	var hit = space_state.intersect_ray(query)
	print('Raycast hit:', hit)
	if hit:
		print('Hit collider:', hit.collider.name, ' at pos:', hit.position)
	quit(0)
