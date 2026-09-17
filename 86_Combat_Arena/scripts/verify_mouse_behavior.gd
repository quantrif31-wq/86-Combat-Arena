extends SceneTree

# =============================================================================
# VERIFY MOUSE BEHAVIOR & CURSOR CONFINEMENT FIXES
# =============================================================================

func _init() -> void:
	print("=====================================================================")
	print("--- VERIFYING MOUSE CURSOR FREEDOM & FOCUS RELEASE SYSTEMS ---")
	print("=====================================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	# Test 1: Check Autoload GameAppManager
	print("\n[TEST 1] Testing GameAppManager Autoload Singleton...")
	var gam_script = load("res://scripts/game_app_manager.gd")
	assert(gam_script != null, "game_app_manager.gd failed to load!")
	var gam = gam_script.new()
	root.add_child(gam)
	
	# Simulate captured state
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Failed to set CAPTURED mode")
	
	# Simulate Focus Out notification on GameAppManager
	gam.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "GameAppManager failed to release mouse on FOCUS_OUT!")
	print("  -> PASSED: GameAppManager releases mouse immediately on NOTIFICATION_APPLICATION_FOCUS_OUT")
	
	# Simulate Window Focus Out
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gam.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "GameAppManager failed to release mouse on WINDOW_FOCUS_OUT!")
	print("  -> PASSED: GameAppManager releases mouse immediately on NOTIFICATION_WM_WINDOW_FOCUS_OUT")
	
	# Simulate Close Request
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gam.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "GameAppManager failed to release mouse on WM_CLOSE_REQUEST!")
	print("  -> PASSED: GameAppManager releases mouse immediately on NOTIFICATION_WM_CLOSE_REQUEST")
	gam.queue_free()

	# Test 2: Testing PlayerController Mouse Behavior
	print("\n[TEST 2] Testing PlayerController Mouse Hijacking Prevention...")
	var player_scene = load("res://scenes/player_juggernaut.tscn")
	assert(player_scene != null, "player_juggernaut.tscn failed to load!")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	for i in range(5):
		await process_frame
		
	# Ensure mouse can be set to visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Simulate mouse motion while mouse is visible - MUST NOT RE-CAPTURE!
	var motion_event = InputEventMouseMotion.new()
	motion_event.relative = Vector2(15.0, -10.0)
	player._input(motion_event)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "REGRESSION: Mouse motion hijacked and recaptured the mouse while visible!")
	print("  -> PASSED: Mouse movement while visible does NOT hijack/recapture the cursor!")
	
	# Simulate left-click to capture
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	player._input(click_event)
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "PlayerController failed to capture mouse on left click!")
	print("  -> PASSED: Left-click correctly captures mouse for combat control.")
	
	# Simulate Escape (ui_cancel)
	var esc_event = InputEventAction.new()
	esc_event.action = "ui_cancel"
	esc_event.pressed = true
	player._input(esc_event)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "PlayerController failed to release mouse on ui_cancel (Escape)!")
	print("  -> PASSED: Escape releases mouse to MOUSE_MODE_VISIBLE.")
	
	# Simulate exit tree
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.queue_free()
	for i in range(3):
		await process_frame
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "PlayerController failed to release mouse on exit tree!")
	print("  -> PASSED: PlayerController frees mouse on _exit_tree().")

	# Test 3: CombatHUD Pause and Return to Base
	print("\n[TEST 3] Testing CombatHUD Pause & Scene Return Mouse State...")
	var hud_scene = load("res://scenes/combat_hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	for i in range(3):
		await process_frame
		
	# Toggle pause
	hud.toggle_pause()
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "CombatHUD failed to make mouse visible on pause!")
	assert(is_paused(), "Tree should be paused!")
	print("  -> PASSED: Pausing releases mouse to MOUSE_MODE_VISIBLE.")
	
	# Toggle unpause
	hud.toggle_pause()
	assert(not is_paused(), "Tree should be unpaused!")
	
	# Free HUD
	hud.queue_free()
	for i in range(3):
		await process_frame
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Mouse not visible after HUD freed!")
	print("  -> PASSED: CombatHUD guarantees visible mouse on teardown.")

	print("\n=====================================================================")
	print(">>> ALL MOUSE CONFINEMENT & FREEDOM TESTS PASSED 100%! <<<")
	print("=====================================================================\n")
	quit(0)
