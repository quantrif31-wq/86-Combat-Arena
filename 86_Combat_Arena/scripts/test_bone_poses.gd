extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	
	print('--- CHECKING REST POSITIONS ---')
	var cannon_idx = skel.find_bone("Cannon")
	var recoil_idx = skel.find_bone("Cannon_Recoil")
	var sensor_idx = skel.find_bone("Sensor_Optics")
	print('Cannon bone global pose:', skel.get_bone_global_pose(cannon_idx))
	print('Cannon_Recoil bone global pose:', skel.get_bone_global_pose(recoil_idx))
	print('Sensor_Optics bone global pose:', skel.get_bone_global_pose(sensor_idx))
	
	quit(0)
