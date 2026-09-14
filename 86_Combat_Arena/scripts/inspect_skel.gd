extends SceneTree

func _init():
	var scene = load("res://assets/models/m1a4_juggernaut_player.glb")
	if scene:
		var node = scene.instantiate()
		var skel = node.find_child("Skeleton3D", true, false) as Skeleton3D
		if skel:
			print("SKELETON FOUND! Bone count: ", skel.get_bone_count())
			for i in range(skel.get_bone_count()):
				var bname = skel.get_bone_name(i)
				var bpose = skel.get_bone_global_pose(i)
				print(i, ": ", bname, " pos: ", bpose.origin)
	quit()
