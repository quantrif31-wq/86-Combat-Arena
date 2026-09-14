extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var root_bone = skel.find_bone("Root")
	var chassis_bone = skel.find_bone("Chassis")
	var cannon_bone = skel.find_bone("Cannon")
	print('Cannon bone rest pose location:', skel.get_bone_rest(cannon_bone).origin)
	print('Cannon bone global pose:', skel.get_bone_global_pose(cannon_bone))
	
	# Where is Sensor_Optics (front of head)?
	var sensor_bone = skel.find_bone("Sensor_Optics")
	print('Sensor optics global pose:', skel.get_bone_global_pose(sensor_bone))
	
	# Where is Rear leg vs Front leg?
	var fl_hip = skel.find_bone("Leg_FL_Hip")
	var rl_hip = skel.find_bone("Leg_RL_Hip")
	print('Front-Left Hip global pose origin:', skel.get_bone_global_pose(fl_hip).origin)
	print('Rear-Left Hip global pose origin:', skel.get_bone_global_pose(rl_hip).origin)
	quit(0)
