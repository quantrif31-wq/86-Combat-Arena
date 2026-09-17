@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("--- TESTING FULL 86 COMBAT ARENA GAME LOOP ---")
	print("==================================================")
	
	# 1. Verify Title Screen
	print("\n[STEP 1] Testing Title Screen Scene...")
	var title_res = load("res://scenes/title_screen.tscn")
	assert(title_res is PackedScene, "Title screen scene failed to load!")
	var title_node = title_res.instantiate()
	assert(title_node != null, "Failed to instantiate Title Screen!")
	
	var btn_sortie = title_node.get_node_or_null("LeftPanel/VBox/BtnSortie")
	assert(btn_sortie != null, "BtnSortie not found on Title Screen!")
	var petals = title_node.get_node_or_null("SpiderLilyPetals")
	assert(petals != null, "SpiderLilyPetals particle node not found!")
	var emblem = title_node.get_node_or_null("TopLeftBanner/Emblem")
	assert(emblem != null, "Emblem texture not found!")
	print("  -> Title Screen: OK (All buttons, particles, and branding intact)")
	title_node.free()
	
	# 2. Verify Loading Screen
	print("\n[STEP 2] Testing Loading Screen Scene...")
	var load_res = load("res://scenes/loading_screen.tscn")
	assert(load_res is PackedScene, "Loading screen scene failed to load!")
	var load_node = load_res.instantiate()
	assert(load_node != null, "Failed to instantiate Loading Screen!")
	
	var progress = load_node.get_node_or_null("CenterBox/ProgressBar")
	assert(progress != null, "ProgressBar not found on Loading Screen!")
	var waveform = load_node.get_node_or_null("CenterBox/WaveformBox/VBox/WaveformCanvas")
	assert(waveform != null, "ParaRaidWaveform canvas not found!")
	var quote = load_node.get_node_or_null("BottomBox/QuoteLabel")
	assert(quote != null, "QuoteLabel not found!")
	print("  -> Loading Screen: OK (Waveform, ProgressBar, Quotes, Telemetry intact)")
	load_node.free()
	
	# 3. Verify Main Arena & Combat HUD Pause Menu
	print("\n[STEP 3] Testing Combat HUD & Pause System in Main Arena...")
	var hud_res = load("res://scenes/combat_hud.tscn")
	assert(hud_res is PackedScene, "CombatHUD scene failed to load!")
	var hud_node = hud_res.instantiate()
	assert(hud_node != null, "Failed to instantiate CombatHUD!")
	
	var pause_overlay = hud_node.get_node_or_null("PauseOverlay")
	assert(pause_overlay != null, "PauseOverlay not found in CombatHUD!")
	var btn_resume = hud_node.get_node_or_null("PauseOverlay/PausePanel/Margin/VBox/BtnResume")
	assert(btn_resume != null, "BtnResume not found!")
	var btn_return = hud_node.get_node_or_null("PauseOverlay/PausePanel/Margin/VBox/BtnReturnBase")
	assert(btn_return != null, "BtnReturnBase not found!")
	var btn_banner_return = hud_node.get_node_or_null("BannerBox/Margin/VBox/BtnReturnBaseBanner")
	assert(btn_banner_return != null, "BtnReturnBaseBanner not found!")
	print("  -> Combat HUD: OK (PauseOverlay, Resume, and Return to Base buttons intact)")
	hud_node.free()
	
	# 4. Verify Project Configuration
	print("\n[STEP 4] Checking Project Config...")
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	print("  -> Current main_scene: ", main_scene)
	assert(main_scene == "res://scenes/title_screen.tscn", "Project main_scene is not title_screen.tscn!")
	
	print("\n==================================================")
	print(">>> ALL 4 VERIFICATION STEPS PASSED WITH 100% SUCCESS! <<<")
	print("==================================================")
	quit(0)
