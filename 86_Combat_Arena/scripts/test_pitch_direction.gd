extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	inst.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var cannon_idx = skel.find_bone("Cannon")
	
	# Test positive pitch rotation around Vector3.RIGHT
	var q_pos = Quaternion(Vector3.RIGHT, deg_to_rad(25.0))
	skel.set_bone_pose_rotation(cannon_idx, q_pos)
	
	# What direction is the barrel pointing now?
	# In rest, barrel points along +Z in bone space (which maps to -Z in world when body is rotated 180)
	var barrel_dir_rest = Vector3(0, 0, 1) # in bone rest
	var barrel_dir_tilted = q_pos * barrel_dir_rest
	print('Tilted barrel direction in bone space:', barrel_dir_tilted)
	
	quit(0)
