extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	print('=== IMPORTED PLAYER SCENE ===')
	print_tree(inst, 0)
	quit(0)

func print_tree(n: Node, depth: int) -> void:
	print('  '.repeat(depth), '- ', n.name, ' (', n.get_class(), ')')
	if n is AnimationPlayer:
		print('  '.repeat(depth), '  ANIMATIONS: ', n.get_animation_list())
	for c in n.get_children():
		print_tree(c, depth + 1)
