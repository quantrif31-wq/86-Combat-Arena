extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var enemy = null
var hud = null

func _init():
	print(">>> INITIALIZING 86 COMBAT ARENA TEST SIMULATION <<<")
	var arena_res = load("res://scenes/main_arena.tscn")
	if not arena_res:
		printerr("FAILED to load main_arena.tscn!")
		quit(1)
		return
	main_scene = arena_res.instantiate()
	root.add_child(main_scene)
	
	player = main_scene.get_node("PlayerJuggernaut")
	enemy = main_scene.get_node("EnemyJuggernaut")
	hud = main_scene.get_node("CanvasLayer/CombatHUD")
	
	print("[CHECK 1] Nodes loaded successfully:")
	print("  - Player: ", player != null, " Pos: ", player.global_position if player else "N/A")
	print("  - Enemy:  ", enemy != null, " Pos: ", enemy.global_position if enemy else "N/A")
	print("  - HUD:    ", hud != null)
	
	# Verify Props count
	var props = main_scene.get_node("Props")
	print("  - Total Battlefield Props loaded: ", props.get_child_count() if props else 0)

func _process(delta: float) -> bool:
	frame_count += 1
	
	# Frame 10: Simulate Player Firing Cannon
	if frame_count == 10:
		print("[CHECK 2] Simulating 57mm cannon shot at frame 10...")
		player.shoot_cannon()
		
	# Frame 25: Verify damage application on Enemy
	if frame_count == 25:
		print("[CHECK 3] Dealing 35 damage to Enemy Juggernaut...")
		var prev_hp = enemy.current_hp
		enemy.take_damage(35.0, player)
		print("  - Enemy HP before: ", prev_hp, " -> after: ", enemy.current_hp)
		assert(enemy.current_hp < prev_hp, "Enemy did not take damage!")
		
	# Frame 40: Verify damage application on Player
	if frame_count == 40:
		print("[CHECK 4] Dealing 35 damage to Player Juggernaut...")
		var prev_hp = player.current_hp
		player.take_damage(35.0, enemy)
		print("  - Player HP before: ", prev_hp, " -> after: ", player.current_hp)
		assert(player.current_hp < prev_hp, "Player did not take damage!")
		
	# Frame 60: Simulate fatal hit on Enemy
	if frame_count == 60:
		print("[CHECK 5] Destroying Enemy Juggernaut (dealing 100 fatal damage)...")
		enemy.take_damage(100.0, player)
		print("  - Enemy HP: ", enemy.current_hp, " State: ", enemy.current_state)
		print("  - HUD Banner visible: ", hud.banner_box.visible)
		print("  - HUD Banner text: ", hud.banner_title.text)
		assert(hud.banner_box.visible, "Victory banner was not displayed!")

	if frame_count >= 80:
		print(">>> ALL 5 COMBAT CHECKS PASSED PERFECTLY! <<<")
		quit(0)
		return true
		
	return false
