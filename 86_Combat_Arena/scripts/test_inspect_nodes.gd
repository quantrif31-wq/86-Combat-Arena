extends SceneTree

func _init() -> void:
	var s = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = s.instantiate()
	var mesh_inst: MeshInstance3D = inst.get_node("M1A4_Armature/Skeleton3D/M1A4_Juggernaut_Mesh")
	print("Mesh AABB: ", mesh_inst.get_aabb())
	print("Global position of M1A4_Armature: ", inst.get_node("M1A4_Armature").position)
	print("Global rotation of M1A4_Armature: ", inst.get_node("M1A4_Armature").rotation)
	quit(0)
