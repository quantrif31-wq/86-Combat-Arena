extends StaticBody3D

var prop_type: String = "barrier"
var prop_idx: int = -1
var arena_manager_ref: Node = null

func take_hit(damage: float, shooter: Node, hit_pos: Vector3, impact_dir: Vector3) -> void:
	if arena_manager_ref:
		if prop_type == "barrier" and arena_manager_ref.has_method("shatter_barrier"):
			arena_manager_ref.shatter_barrier(prop_idx, hit_pos, impact_dir)
		elif prop_type == "ammo" and arena_manager_ref.has_method("detonate_ammo"):
			arena_manager_ref.detonate_ammo(prop_idx, hit_pos)
	queue_free()

func take_damage(damage: float, shooter: Node = null) -> void:
	take_hit(damage, shooter, global_position, Vector3.FORWARD)
