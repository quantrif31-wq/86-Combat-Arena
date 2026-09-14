extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var fl_hip = skel.find_bone("Leg_FL_Hip")
	var fl_thigh = skel.find_bone("Leg_FL_Thigh")
	var walk_anim = anim.get_animation("Walk")
	walk_anim.loop_mode = Animation.LOOP_LINEAR
	anim.play("Walk")
	
	print('Testing 5 frames of Walk animation:')
	for i in range(5):
		anim.advance(0.2)
		var hip_pose = skel.get_bone_pose_rotation(fl_hip)
		var thigh_pose = skel.get_bone_pose_rotation(fl_thigh)
		print('  Time ', (i+1)*0.2, 's: Leg_FL_Hip rot = ', hip_pose, ', Thigh rot = ', thigh_pose)
		
	quit(0)
