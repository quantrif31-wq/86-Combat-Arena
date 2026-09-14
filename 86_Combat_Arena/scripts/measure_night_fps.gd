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
		var wz = root.get_node("MainArena/Sector86_Grand_Warzone")
		print("  - Static Objects in Scene: ", wz.get_child_count())
		var counts = {}
		var meshes = {}
		for c in wz.get_children():
			var p = c.name.split("_")[0]
			counts[p] = counts.get(p, 0) + 1
			if c is MeshInstance3D and c.mesh:
				if not meshes.has(p):
					meshes[p] = []
				if not meshes[p].has(c.mesh):
					meshes[p].append(c.mesh)
		for k in counts.keys():
			var m_count = meshes.get(k, []).size()
			print("    * ", k, ": ", counts[k], " (distinct meshes: ", m_count, ")")
		print("--- BENCHMARK COMPLETE ---")
		quit(0)
		return true
	return false
