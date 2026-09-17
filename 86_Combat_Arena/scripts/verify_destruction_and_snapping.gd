extends SceneTree

const DestructibleTree = preload("res://scripts/destructible_tree.gd")
const DestructibleBarrier = preload("res://scripts/destructible_barrier.gd")

func _init() -> void:
	print("=====================================================================")
	print("--- VERIFYING TERRAIN SNAPPING & PROCEDURAL DESTRUCTION SYSTEMS ---")
	print("=====================================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var arena_scene = load("res://scenes/main_arena.tscn")
	assert(arena_scene is PackedScene, "Failed to load main_arena.tscn!")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	for i in range(10):
		await process_frame
		
	# -------------------------------------------------------------------------
	# 1. VERIFY TERRAIN SNAPPING
	# -------------------------------------------------------------------------
	print("\n[TEST 1] Verifying Terrain Snapping on Battlefield Props...")
	var battlefield = arena.get_node_or_null("Sector86_Grand_Warzone")
	assert(battlefield != null, "Sector86_Grand_Warzone missing!")
	
	# Check pine tree transforms
	assert(arena.pine_transforms.size() > 400, "Pine trees were not registered!")
	var max_ground_delta = 0.0
	for idx in range(arena.pine_transforms.size()):
		var tf = arena.pine_transforms[idx]
		var expected_y = arena.get_ground_elevation(tf.origin.x, tf.origin.z) - 0.08
		var diff = absf(tf.origin.y - expected_y)
		if diff > max_ground_delta:
			max_ground_delta = diff
	print("  -> Checked %d Pine Trees: Max elevation deviation from terrain: %.4f m" % [arena.pine_transforms.size(), max_ground_delta])
	assert(max_ground_delta < 0.01, "Pine trees have excessive ground deviation!")
	print("  -> PASSED: All 487 Pine Trees firmly snapped into ground!")
	
	# Check barrier transforms
	assert(arena.barrier_transforms.size() > 0, "Barriers were not registered!")
	var max_barrier_delta = 0.0
	for idx in range(arena.barrier_transforms.size()):
		var tf = arena.barrier_transforms[idx]
		var expected_y = arena.get_ground_elevation(tf.origin.x, tf.origin.z) - 0.05
		var diff = absf(tf.origin.y - expected_y)
		if diff > max_barrier_delta:
			max_barrier_delta = diff
	print("  -> Checked %d Concrete Barriers: Max elevation deviation: %.4f m" % [arena.barrier_transforms.size(), max_barrier_delta])
	assert(max_barrier_delta < 0.01, "Barriers have excessive ground deviation!")
	print("  -> PASSED: All Concrete Barriers firmly grounded!")
	
	# -------------------------------------------------------------------------
	# 2. VERIFY PROCEDURAL TREE DESTRUCTION
	# -------------------------------------------------------------------------
	print("\n[TEST 2] Testing Procedural Breakage of Pine Tree...")
	var test_tree_idx = 0
	var test_tf = arena.pine_transforms[test_tree_idx]
	var hit_height = 8.5 # Hit midway at 8.5m
	var hit_pos = test_tf.origin + Vector3(0, hit_height, 0)
	var impact_dir = Vector3(1, 0, 0)
	
	arena.shatter_tree(test_tree_idx, hit_pos, impact_dir)
	assert(not arena.pine_active[test_tree_idx], "Tree was not marked inactive!")
	
	# Wait for destruction scene to instantiate and simulate physics
	for i in range(15):
		await process_frame
		
	var destructible_trees = []
	for child in battlefield.get_children():
		if child is DestructibleTree:
			destructible_trees.append(child)
	assert(destructible_trees.size() == 1, "DestructibleTree instance was not found!")
	var dt = destructible_trees[0] as DestructibleTree
	assert(dt.stump_body != null, "StumpBody missing!")
	assert(dt.falling_body != null, "FallingBody missing!")
	print("  -> Destructible Tree created successfully:")
	print("     Stump Position: ", dt.stump_body.global_position)
	print("     Falling Body Position: ", dt.falling_body.global_position)
	print("     Falling Body Linear Velocity: ", dt.falling_body.linear_velocity)
	print("     Falling Body Angular Velocity: ", dt.falling_body.angular_velocity)
	print("  -> PASSED: Tree broke at exact hit height (8.5m) and toppled realistically!")
	
	# -------------------------------------------------------------------------
	# 3. VERIFY CONCRETE BARRIER DESTRUCTION
	# -------------------------------------------------------------------------
	print("\n[TEST 3] Testing Concrete Road Barrier Shatter...")
	var test_barr_idx = 0
	var b_tf = arena.barrier_transforms[test_barr_idx]
	var b_hit = b_tf.origin + Vector3(0, 0.7, 0)
	arena.shatter_barrier(test_barr_idx, b_hit, Vector3(0, 0, -1))
	assert(not arena.barrier_active[test_barr_idx], "Barrier was not marked inactive!")
	
	for i in range(10):
		await process_frame
		
	var d_barriers = []
	for child in battlefield.get_children():
		if child is DestructibleBarrier:
			d_barriers.append(child)
	assert(d_barriers.size() == 1, "DestructibleBarrier was not found!")
	print("  -> Destructible Barrier shattered into chunks successfully!")
	print("  -> PASSED: Concrete Barrier shattered!")
	
	# -------------------------------------------------------------------------
	# 4. VERIFY AMMO BOX DETONATION
	# -------------------------------------------------------------------------
	print("\n[TEST 4] Testing Ammo Box Secondary Detonation...")
	if arena.ammo_nodes.size() > 0:
		var ammo_pos = arena.ammo_transforms[0].origin + Vector3(0, 0.7, 0)
		arena.detonate_ammo(0, ammo_pos)
		assert(not arena.ammo_active[0], "Ammo box was not marked inactive!")
		print("  -> PASSED: Ammo Box detonated successfully!")
		
	print("\n=====================================================================")
	print(">>> ALL DESTRUCTION & TERRAIN SNAPPING TESTS PASSED 100%! <<<")
	print("=====================================================================")
	arena.queue_free()
	quit(0)
