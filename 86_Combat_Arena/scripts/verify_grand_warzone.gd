extends SceneTree

func _init():
	print("--- INSPECTING SECTOR86_GRAND_WARZONE.GLB ---")
	var res = load("res://assets/environment/sector86_grand_warzone.glb")
	if not res:
		print("ERROR: Failed to load glb!")
		quit(1)
		return
		
	var inst = res.instantiate()
	print("Total root children:", inst.get_child_count())
	var type_counts = {}
	var sample_names = []
	
	for child in inst.get_children():
		var t = child.get_class()
		type_counts[t] = type_counts.get(t, 0) + 1
		if sample_names.size() < 15:
			sample_names.append(child.name + " (" + t + ")")
			
	print("Child types:", type_counts)
	print("Sample children:")
	for s in sample_names:
		print("  *", s)
		
	quit(0)
