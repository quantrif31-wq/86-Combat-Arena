extends SceneTree
func _init():
	var n = Node3D.new()
	n.rotation.z = PI / 2.0
	print("TRANSFORM FOR PI/2: ", n.transform)
	quit()
