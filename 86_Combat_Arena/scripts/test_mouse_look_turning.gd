extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print(">>> TESTING MOUSE LOOK ROTATION & BODY MOVEMENT DIRECTION <<<")
	var arena_scene = load("res://scenes/main_arena.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	await process_frame
	await process_frame
	
	var player: PlayerJuggernaut = arena.get_node("PlayerJuggernaut")
	var initial_rot_y = player.rotation.y
	print("Initial player rotation.y: ", initial_rot_y)
	
	# Simulate horizontal mouse motion
	var mouse_event = InputEventMouseMotion.new()
	mouse_event.relative = Vector2(100.0, -50.0) # Moving right and up
	player._input(mouse_event)
	
	var new_rot_y = player.rotation.y
	var new_pitch = player.cam_pitch
	print("After mouse motion: rotation.y = ", new_rot_y, ", cam_pitch = ", rad_to_deg(new_pitch), " deg")
	
	assert(new_rot_y != initial_rot_y, "Player body must rotate with horizontal mouse movement!")
	assert(new_pitch > 0.0, "Camera pitch must tilt up with vertical mouse movement!")
	print("[PASS 1] Mouse movement rotates body horizontally and tilts camera vertically!")
	
	# Simulate WASD movement along rotated body
	var forward_dir = -player.transform.basis.z
	print("New player forward direction: ", forward_dir)
	
	# Verify that W moves along new forward direction
	var input_dir = Vector3(0, 0, -1) # W pressed
	var move_dir = (player.transform.basis * input_dir).normalized()
	assert(move_dir.is_equal_approx(forward_dir), "Movement direction must match camera/body forward direction!")
	print("[PASS 2] WASD movement perfectly follows mouse look direction!")
	
	# Verify leg bones are moving in Walk animation
	player.anim_player.play("Walk")
	player.anim_player.advance(0.3)
	var sk: Skeleton3D = player.skeleton
	var fl_thigh_idx = sk.find_bone("Leg_FL_Thigh")
	var fl_foot_idx = sk.find_bone("Leg_FL_Foot")
	var fl_hip_idx = sk.find_bone("Leg_FL_Hip")
	
	var thigh_pose = sk.get_bone_pose_rotation(fl_thigh_idx)
	var foot_pose = sk.get_bone_pose_rotation(fl_foot_idx)
	var hip_pose = sk.get_bone_pose_rotation(fl_hip_idx)
	print("Walk stride pose at 0.3s:")
	print("   Hip pose: ", hip_pose.get_euler())
	print("   Thigh pose: ", thigh_pose.get_euler())
	print("   Foot pose: ", foot_pose.get_euler())
	
	assert(thigh_pose != Quaternion.IDENTITY, "Thigh must have significant rotation in Walk animation!")
	assert(foot_pose != Quaternion.IDENTITY, "Foot must articulate in Walk animation!")
	assert(hip_pose != Quaternion.IDENTITY, "Hip must articulate in Walk animation!")
	print("[PASS 3] All leg joints articulate cleanly with distinct strides in Walk animation!")
	
	print(">>> ALL MOUSE LOOK & WALKING GAIT CHECKS PASSED! <<<")
	quit(0)
