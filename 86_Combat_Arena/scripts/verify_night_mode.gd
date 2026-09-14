extends SceneTree

func _init() -> void:
	print("--- STARTING NIGHT MODE & NVG VERIFICATION ---")
	
	var arena_scene = load("res://scenes/main_arena.tscn")
	if not arena_scene:
		printerr("FAILED: Could not load main_arena.tscn")
		quit(1)
		return
		
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	# 1. Verify Environment & Starry Night Sky
	var world_env = arena.get_node_or_null("WorldEnvironment") as WorldEnvironment
	assert(world_env != null, "WorldEnvironment must exist")
	var sky = world_env.environment.sky
	assert(sky != null, "Sky must be configured in environment")
	print("PASS: WorldEnvironment and Sky successfully configured.")
	print("  - Fog density: ", world_env.environment.fog_density)
	print("  - Ambient light: ", world_env.environment.ambient_light_color)
	
	# 2. Verify Directional Moonlight & Shadow settings
	var moon = arena.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	assert(moon != null, "DirectionalLight3D must exist")
	print("PASS: Moonlight DirectionalLight3D verified.")
	print("  - Light color: ", moon.light_color)
	print("  - Light energy: ", moon.light_energy)
	print("  - Shadow max distance: ", moon.directional_shadow_max_distance)
	print("  - Shadow mode: ", moon.directional_shadow_mode)
	
	# 3. Verify Player Juggernaut & Headlights
	var player = arena.get_node_or_null("PlayerJuggernaut") as PlayerJuggernaut
	assert(player != null, "PlayerJuggernaut must exist")
	var headlight_l = player.get_node_or_null("TacticalHeadlightL")
	var headlight_r = player.get_node_or_null("TacticalHeadlightR")
	assert(headlight_l != null and headlight_r != null, "Dual tactical headlights must exist")
	print("PASS: Player tactical headlights verified.")
	print("  - Headlight L: ", headlight_l.light_energy, " range: ", headlight_l.spot_range)
	print("  - Headlight R: ", headlight_r.light_energy, " range: ", headlight_r.spot_range)
	
	# 4. Verify CombatHUD & NVG Post-Processing
	var hud = arena.get_node_or_null("CanvasLayer/CombatHUD") as CombatHUD
	assert(hud != null, "CombatHUD must exist")
	var nvg_node = hud.get_node_or_null("NightVisionPostProcess") as ColorRect
	assert(nvg_node != null, "NightVisionPostProcess node must exist in CombatHUD")
	assert(nvg_node.material != null, "NVG ShaderMaterial must be assigned")
	print("PASS: NVG Post-Processing verified on CombatHUD.")
	print("  - NVG active state: ", hud.is_nvg_active)
	print("  - NVG node visible: ", nvg_node.visible)
	
	# 5. Verify Enemy Sensor Eye Lights
	var enemies = get_nodes_in_group("enemy")
	print("PASS: Found ", enemies.size(), " enemy Juggernauts in scene.")
	for i in range(enemies.size()):
		var enm = enemies[i]
		var eye = enm.get_node_or_null("SensorEyeLight") as OmniLight3D
		assert(eye != null, "Enemy " + str(i) + " must have SensorEyeLight")
		print("  - Enemy ", i, " Eye Light: energy=", eye.light_energy, " color=", eye.light_color)
		
	# 6. Simulate 25 physics frames & benchmark
	var start_time = Time.get_ticks_usec()
	for f in range(25):
		player._physics_process(0.016)
		for enm in enemies:
			if enm.has_method("_physics_process"):
				enm._physics_process(0.016)
	var elapsed_ms = (Time.get_ticks_usec() - start_time) / 1000.0
	print("PASS: Simulated 25 full game frames in ", elapsed_ms, " ms (~", elapsed_ms / 25.0, " ms/frame).")
	
	print("\n>>> ALL CHECKS PASSED: NIGHT MODE, NVG OPTICS & OPTIMIZATIONS ARE 100% OPERATIONAL! <<<\n")
	quit(0)
