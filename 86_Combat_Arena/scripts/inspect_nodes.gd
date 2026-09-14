extends SceneTree

func _init():
	var res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = res.instantiate()
	print("--- NODE HIERARCHY ---")
	print_tree_node(inst, 0)
	quit(0)

func print_tree_node(node: Node, indent: int):
	var prefix = "  ".repeat(indent)
	var tr_str = ""
	if node is Node3D:
		tr_str = " pos=" + str(node.position) + " rot=" + str(node.rotation)
	print(prefix + "- " + node.name + " (" + node.get_class() + ")" + tr_str)
	for child in node.get_children():
		print_tree_node(child, indent + 1)
