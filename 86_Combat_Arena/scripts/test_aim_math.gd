extends SceneTree

func _init() -> void:
	var player_scene = load("res://scenes/player_juggernaut.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Simulate looking up at 20 degrees
	var test_target = player.global_position + Vector3(0, 20.0, -50.0)
	var cannon_pivot = player.global_position + Vector3(0, 1.55, 0)
	var aim_dir = (test_target - cannon_pivot).normalized()
	var local_aim = player.global_transform.basis.inverse() * aim_dir
	var pitch = atan2(local_aim.y, -local_aim.z)
	var yaw = atan2(-local_aim.x, -local_aim.z)
	print('Target pitch (deg):', rad_to_deg(pitch), 'Target yaw (deg):', rad_to_deg(yaw))
	
	var skel: Skeleton3D = player.get_node("ModelInstance/M1A4_Armature/Skeleton3D")
	var cannon_idx = skel.find_bone("Cannon")
	var turret_idx = skel.find_bone("Turret")
	
	skel.set_bone_pose_rotation(cannon_idx, Quaternion(Vector3.RIGHT, -pitch))
	skel.set_bone_pose_rotation(turret_idx, Quaternion(Vector3.UP, yaw))
	print('Successfully set aiming bones!')
	
	quit(0)
