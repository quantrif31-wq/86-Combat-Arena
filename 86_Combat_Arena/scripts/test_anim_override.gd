extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_rigged.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var turret_idx = skel.find_bone("Turret")
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	anim.play("Walk")
	
	# Advance animation by 0.5s
	anim.advance(0.5)
	print('Turret rotation after 0.5s of Walk:', skel.get_bone_pose_rotation(turret_idx))
	
	quit(0)
