extends SceneTree

func _init() -> void:
	process_frame.connect(_test, CONNECT_ONE_SHOT)

func _test() -> void:
	var arena = load("res://scenes/main_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	
	var player = arena.get_node("PlayerJuggernaut")
	print("Player global_position: ", player.global_position)
	print("Camera global_position: ", player.camera.global_position)
	print("Camera global forward: ", -player.camera.global_transform.basis.z)
	
	var target_pos = player.get_aim_target()
	print("Target pos: ", target_pos)
	
	var cannon_pivot = player.global_position + Vector3(0, 1.55, 0)
	var aim_dir = (target_pos - cannon_pivot).normalized()
	print("Aim dir: ", aim_dir)
	
	var local_aim = player.global_transform.basis.inverse() * aim_dir
	print("Local aim: ", local_aim)
	
	var target_pitch = atan2(local_aim.y, -local_aim.z)
	var target_yaw = atan2(-local_aim.x, -local_aim.z)
	print("Target pitch: ", rad_to_deg(target_pitch), " deg, Target yaw: ", rad_to_deg(target_yaw), " deg")
	
	var sk = player.skeleton
	var t_idx = player.turret_bone_idx
	var c_idx = player.cannon_bone_idx
	print("Turret bone idx: ", t_idx, " Cannon bone idx: ", c_idx)
	print("Turret bone rest: ", sk.get_bone_rest(t_idx))
	print("Cannon bone rest: ", sk.get_bone_rest(c_idx))
	quit(0)
