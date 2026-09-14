extends SceneTree

func _init():
	var scene = load("res://assets/models/m1a4_juggernaut_player.glb")
	if scene:
		var node = scene.instantiate()
		print("ROOT: ", node.name, " [", node.get_class(), "]")
		print_tree(node, 0)
	quit()

func print_tree(n: Node, d: int):
	var pad = ""
	for i in range(d): pad += "  "
	print(pad, "+ ", n.name, " (", n.get_class(), ")")
	if n is AnimationPlayer:
		print(pad, "  >> ANIMATIONS: ", n.get_animation_list())
	for c in n.get_children():
		print_tree(c, d + 1)
