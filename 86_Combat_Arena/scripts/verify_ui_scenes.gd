@tool
extends SceneTree

func _init() -> void:
	print("--- VERIFYING UI SCENES ---")
	
	# Test Title Screen
	print("1. Loading Title Screen scene...")
	var title_res = load("res://scenes/title_screen.tscn")
	if title_res is PackedScene:
		var inst = title_res.instantiate()
		print("SUCCESS: Title Screen instantiated successfully! Nodes: ", inst.get_child_count())
		inst.free()
	else:
		push_error("FAILED to load title_screen.tscn")
		quit(1)
		return
		
	# Test Loading Screen
	print("2. Loading Loading Screen scene...")
	var load_res = load("res://scenes/loading_screen.tscn")
	if load_res is PackedScene:
		var inst = load_res.instantiate()
		print("SUCCESS: Loading Screen instantiated successfully! Nodes: ", inst.get_child_count())
		inst.free()
	else:
		push_error("FAILED to load loading_screen.tscn")
		quit(1)
		return
		
	print("ALL UI SCENES VERIFIED SUCCESSFULLY!")
	quit(0)
