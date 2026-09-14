extends SceneTree
func _init():
	var t1 = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 0, 0, 0)
	var t2 = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0)
	print(" t1 rotation: \, t1.basis.get_euler())
 print(\t2 rotation: \, t2.basis.get_euler())
 quit(0)
