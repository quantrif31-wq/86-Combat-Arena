extends SceneTree

func _init():
	var scene = load("res://scenes/player_juggernaut.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	print("--- PLAYER TREE ---")
	print_nodes(inst, 0)
	quit(0)

func print_nodes(n: Node, ind: int):
	print("  ".repeat(ind) + "- " + n.name + " (" + n.get_class() + ")")
	for c in n.get_children():
		print_nodes(c, ind + 1)

