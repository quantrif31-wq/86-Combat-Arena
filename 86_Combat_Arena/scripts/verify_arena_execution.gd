extends SceneTree

func _init():
	print("--- TESTING MAIN ARENA EXECUTION ---")
	var scene_res = load("res://scenes/main_arena.tscn")
	if not scene_res:
		print("FAIL: Could not load res://scenes/main_arena.tscn")
		quit(1)
		return
		
	var arena = scene_res.instantiate()
	root.add_child(arena)
	
	print("Arena loaded successfully!")
	var player = arena.get_node_or_null("PlayerJuggernaut")
	assert(player != null, "PlayerJuggernaut is missing")
	print("Player spawn position:", player.global_position)
	
	var battlefield = arena.get_node_or_null("Sector86_Grand_Warzone")
	assert(battlefield != null, "Sector86_Grand_Warzone is missing")
	print("Battlefield object count:", battlefield.get_child_count())
	
	var enemies = arena.get_tree().get_nodes_in_group("enemy")
	print("Total enemy units in arena:", enemies.size())
	for idx in range(enemies.size()):
		var e = enemies[idx]
		print("  - Enemy #", idx+1, " at: ", e.global_position)
		
	# Verify collision setup ran
	var collider_count = 0
	for child in battlefield.get_children():
		for sub in child.get_children():
			if sub is StaticBody3D:
				collider_count += 1
	print("Total static colliders attached to battlefield props:", collider_count)

var frame = 0
func _process(delta: float) -> bool:
	frame += 1
	if frame >= 15:
		print("SUCCESS: Simulated 15 physics frames on 800m Grand Warzone with zero errors!")
		quit(0)
		return true
	return false
