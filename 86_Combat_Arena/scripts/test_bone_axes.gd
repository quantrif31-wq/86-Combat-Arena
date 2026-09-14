extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_rigged.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var turret_idx = skel.find_bone("Turret")
	var cannon_idx = skel.find_bone("Cannon")
	
	# Rest pose transforms
	var turret_rest = skel.get_bone_rest(turret_idx)
	var cannon_rest = skel.get_bone_rest(cannon_idx)
	print('Turret rest:', turret_rest)
	print('Cannon rest:', cannon_rest)
	
	# Rotate Turret by 45 degrees yaw (left/right)
	var yaw_quat = Quaternion(Vector3.UP, deg_to_rad(45.0))
	skel.set_bone_pose_rotation(turret_idx, yaw_quat)
	
	# Rotate Cannon by 20 degrees pitch (up/down)
	var pitch_quat = Quaternion(Vector3.RIGHT, deg_to_rad(20.0))
	skel.set_bone_pose_rotation(cannon_idx, pitch_quat)
	
	print('Bones posed cleanly!')
	quit(0)
