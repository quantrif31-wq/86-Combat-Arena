extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_rigged.glb")
	if not packed:
		print("FAILED to load m1a4_juggernaut_rigged.glb")
		quit(1)
		return
	var inst = packed.instantiate()
	print("=== RIGGED GLB NODE TREE ===")
	print_nodes(inst, 0)
	quit(0)

func print_nodes(n: Node, depth: int) -> void:
	var prefix = "  ".repeat(depth)
	print(prefix, "- ", n.name, " (", n.get_class(), ")")
	if n is AnimationPlayer:
		var anim_list = n.get_animation_list()
		print(prefix, "  [ANIMATIONS]: ", anim_list)
	elif n is Skeleton3D:
		print(prefix, "  [BONES COUNT]: ", n.get_bone_count())
		for i in range(min(5, n.get_bone_count())):
			print(prefix, "    Bone ", i, ": ", n.get_bone_name(i))
	for c in n.get_children():
		print_nodes(c, depth + 1)
