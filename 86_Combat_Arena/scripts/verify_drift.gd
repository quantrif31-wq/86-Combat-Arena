extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var initial_pos = Vector3.ZERO
var stopped_pos = Vector3.ZERO

func _init():
	print("--- BEGIN DRIFT VERIFICATION TEST ---")
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	player = main_scene.get_node_or_null("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	# Frame 10: Record initial stationary position
	if frame_count == 10:
		initial_pos = player.global_position
		print("Frame 10: Initial Stationary Position = ", initial_pos)
		print("  floor_stop_on_slope: ", player.floor_stop_on_slope)
		print("  is_on_floor: ", player.is_on_floor())
		
	# Frame 11-70 (60 frames / 1 full second idle on terrain)
	if frame_count == 70:
		var cur_pos = player.global_position
		var drift_dist = cur_pos.distance_to(initial_pos)
		print("Frame 70 (After 60 idle frames): Position = ", cur_pos)
		print("  Drift Distance: ", drift_dist)
		assert(drift_dist < 0.005, "Drift must be virtually zero when stationary! Drifted: %f" % drift_dist)
		print("  TEST 1 PASSED: Stationary drift is ZERO!")
		
	# Frame 71-100: Simulate WASD Forward Movement
	if frame_count > 70 and frame_count <= 100:
		var forward_vec = -player.global_transform.basis.z
		player.velocity.x = forward_vec.x * player.walk_speed
		player.velocity.z = forward_vec.z * player.walk_speed
		player.move_and_slide()
		
	# Frame 101: Stop input and record stopped position
	if frame_count == 101:
		stopped_pos = player.global_position
		var moved_dist = stopped_pos.distance_to(initial_pos)
		print("Frame 101: Moved successfully forward by: ", moved_dist, " meters")
		assert(moved_dist > 1.0, "Player must move freely without sticking!")
		print("  TEST 2 PASSED: Movement is smooth without sticking!")
		
	# Frame 102-140 (Stop input, check that body halts immediately)
	# Also simulate mouse rotation while stationary to verify aiming doesn't cause drift
	if frame_count > 101 and frame_count <= 140:
		player.rotate_y(deg_to_rad(1.0))
		
	if frame_count == 140:
		var final_pos = player.global_position
		var post_stop_drift = final_pos.distance_to(stopped_pos)
		print("Frame 140 (After stopping and mouse aim rotation): Position = ", final_pos)
		print("  Post-stop Drift Distance: ", post_stop_drift)
		assert(post_stop_drift < 0.005, "Must NOT drift after stopping or rotating! Drifted: %f" % post_stop_drift)
		print("  TEST 3 PASSED: Zero drift after stopping and during mouse aiming!")
		print("--- ALL DRIFT TESTS PASSED PERFECTLY ---")
		quit(0)
		return true
		
	return false
