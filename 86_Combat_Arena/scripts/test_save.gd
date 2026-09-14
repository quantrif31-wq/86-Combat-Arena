extends SceneTree
func _init():
	var n = Node3D.new()
	n.name = "TestNode"
	n.rotation.z = PI / 2.0
	var scene = PackedScene.new()
	scene.pack(n)
	ResourceSaver.save(scene, "res://scenes/test_save.tscn")
	quit()
