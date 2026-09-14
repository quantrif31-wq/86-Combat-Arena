extends SceneTree

var frame_count = 0
var total_time = 0.0
var max_frame_time = 0.0

func _init():
	print("--- BENCHMARKING NIGHT WARZONE PERFORMANCE ---")
	var scene_res = load("res://scenes/main_arena.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count > 10: # Skip first 10 frames for shader warm-up
		total_time += delta
		max_frame_time = maxf(max_frame_time, delta)
		
	if frame_count >= 130:
		var measured_frames = frame_count - 10
		var avg_delta = total_time / float(measured_frames)
		var avg_fps = 1.0 / avg_delta
		print("PERFORMANCE REPORT:")
		print("  - Measured Frames: ", measured_frames)
		print("  - Average FPS: ", int(avg_fps), " FPS")
		print("  - Average Frametime: ", "%.2f" % (avg_delta * 1000.0), " ms")
		print("  - Peak Frametime: ", "%.2f" % (max_frame_time * 1000.0), " ms")
		print("  - Static Objects in Scene: ", root.get_node("MainArena/Sector86_Grand_Warzone").get_child_count())
		print("--- BENCHMARK COMPLETE ---")
		quit(0)
		return true
	return false
