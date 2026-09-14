extends SceneTree

func _init() -> void:
	var s = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = s.instantiate()
	var sk: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	for b_name in ["Root", "Chassis", "Turret", "Cannon"]:
		var idx = sk.find_bone(b_name)
		var rest = sk.get_bone_rest(idx)
		print("Bone: ", b_name, " (idx ", idx, "):")
		print("   origin: ", rest.origin)
		print("   basis.x: ", rest.basis.x)
		print("   basis.y: ", rest.basis.y)
		print("   basis.z: ", rest.basis.z)
	quit(0)
