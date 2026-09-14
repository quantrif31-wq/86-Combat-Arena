extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_rigged.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var turret_idx = skel.find_bone("Turret")
	var cannon_idx = skel.find_bone("Cannon")
	print('Turret bone index:', turret_idx, 'Cannon bone index:', cannon_idx)
	
	# Test setting rotation
	var q = Quaternion(Vector3.UP, deg_to_rad(30.0))
	skel.set_bone_pose_rotation(turret_idx, q)
	print('Set Turret rotation successfully! Pose rotation:', skel.get_bone_pose_rotation(turret_idx))
	
	# Test AnimationPlayer
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	print('Available animations:', anim.get_animation_list())
	anim.play("Walk")
	print('Playing Walk animation!')
	quit(0)
