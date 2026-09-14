extends SceneTree

func _init():
	var n = Node3D.new()
	n.rotation = Vector3(0, PI / 2.0, 0)
	print("Transform for Y=PI/2: ", n.transform)
	n.rotation = Vector3(0, -PI / 2.0, 0)
	print("Transform for Y=-PI/2: ", n.transform)
	n.rotation = Vector3(0, PI, 0)
	print("Transform for Y=PI: ", n.transform)
	quit(0)
