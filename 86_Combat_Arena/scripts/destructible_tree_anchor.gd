extends StaticBody3D

var tree_idx: int = -1
var arena_manager_ref: Node = null

func take_hit(damage: float, shooter: Node, hit_pos: Vector3, impact_dir: Vector3) -> void:
	if arena_manager_ref and arena_manager_ref.has_method("shatter_tree"):
		arena_manager_ref.shatter_tree(tree_idx, hit_pos, impact_dir)
	queue_free()

func take_damage(damage: float, shooter: Node = null) -> void:
	if arena_manager_ref and arena_manager_ref.has_method("shatter_tree"):
		arena_manager_ref.shatter_tree(tree_idx, global_position + Vector3.UP * 4.0, -global_transform.basis.z)
	queue_free()
