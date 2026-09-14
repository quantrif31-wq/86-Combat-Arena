extends SceneTree

func _init() -> void:
	var arena = load("res://scenes/main_arena.tscn").instantiate()
	root.add_child(arena)
	var player = arena.get_node("PlayerJuggernaut")
	var model = player.get_node("ModelInstance")
	var sk: Skeleton3D = player.skeleton
	var cannon_idx = player.cannon_bone_idx
	
	print("Player global transform: ", player.global_transform)
	print("ModelInstance transform: ", model.transform)
	print("ModelInstance global transform: ", model.global_transform)
	
	var cannon_pose = sk.get_bone_global_pose(cannon_idx)
	print("Cannon bone global pose: ", cannon_pose)
	var world_cannon_forward = (model.global_transform * cannon_pose).basis.z
	print("Cannon world basis.z: ", world_cannon_forward)
	print("Camera global transform: ", player.camera.global_transform)
	print("Camera forward: ", -player.camera.global_transform.basis.z)
	quit(0)
