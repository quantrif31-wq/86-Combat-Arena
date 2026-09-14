extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	inst.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var cannon_idx = skel.find_bone("Cannon")
	var recoil_idx = skel.find_bone("Cannon_Recoil")
	
	var cannon_global = inst.global_transform * skel.global_transform * skel.get_bone_global_pose(cannon_idx)
	var recoil_global = inst.global_transform * skel.global_transform * skel.get_bone_global_pose(recoil_idx)
	print('Cannon global transform origin:', cannon_global.origin)
	print('Cannon forward basis.z:', cannon_global.basis.z)
	print('Recoil global transform origin:', recoil_global.origin)
	print('Recoil forward basis.z:', recoil_global.basis.z)
	
	quit(0)
