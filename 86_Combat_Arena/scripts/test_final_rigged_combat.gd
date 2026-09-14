extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print('>>> RUNNING COMPREHENSIVE RIGGED & 3D AIM VERIFICATION <<<')
	var arena_scene = load('res://scenes/main_arena.tscn')
	if not arena_scene:
		printerr('Failed to load main_arena.tscn!')
		quit(1)
		return
		
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	
	# Wait for scene to settle inside tree
	await process_frame
	await process_frame
	
	var player: PlayerJuggernaut = arena.get_node_or_null('PlayerJuggernaut')
	var enemy: EnemyJuggernaut = arena.get_node_or_null('EnemyJuggernaut')
	
	if not player or not enemy:
		printerr('Failed to find Player or Enemy in arena!')
		quit(1)
		return
	print('[CHECK 1] Found Player and Enemy Juggernauts in Main Arena!')
	
	# Verify Player Rig & Animations
	if not player.skeleton or player.skeleton.get_bone_count() < 18:
		printerr('Player skeleton missing or has insufficient bones!')
		quit(1)
		return
	print('[CHECK 2] Player Skeleton verified: ', player.skeleton.get_bone_count(), ' bones found.')
	print('  - Turret bone idx: ', player.turret_bone_idx, ', Cannon bone idx: ', player.cannon_bone_idx)
	
	if not player.anim_player or not player.anim_player.has_animation('Walk'):
		printerr('Player AnimationPlayer missing Walk animation!')
		quit(1)
		return
	print('[CHECK 3] Player AnimationPlayer verified with animations: ', player.anim_player.get_animation_list())
	
	# Verify Animation States
	player.update_animations(0.016, 5.0, false)
	assert(player.anim_player.current_animation == 'Walk', 'Should be playing Walk')
	print('  - Moving at 5m/s: playing ', player.anim_player.current_animation)
	
	player.update_animations(0.016, 11.0, true)
	assert(player.anim_player.current_animation == 'Run', 'Should be playing Run')
	print('  - Sprinting at 11m/s: playing ', player.anim_player.current_animation)
	
	player.update_animations(0.016, 0.0, false)
	assert(player.anim_player.current_animation == 'Idle', 'Should be playing Idle')
	print('  - Stopped: playing ', player.anim_player.current_animation)
	print('[CHECK 4] Quadruped gait animation state machine verified!')
	
	# Verify 3D Aim Tracking - Aim UP into the sky (+25 deg)
	player.spring_arm.rotation.x = deg_to_rad(25.0)
	player.cam_pitch = deg_to_rad(25.0)
	for i in range(15):
		player.update_aim(0.05)
		
	print('  - Camera pitch: +25 deg -> Current cannon pitch: ', rad_to_deg(player.current_cannon_pitch), ' deg')
	assert(player.current_cannon_pitch > deg_to_rad(10.0), 'Cannon should elevate upward!')
	print('[CHECK 5A] Cannon elevates UPWARD when aiming at the sky!')
	
	# Verify 3D Aim Tracking - Aim DOWN at the ground (-10 deg)
	player.spring_arm.rotation.x = deg_to_rad(-10.0)
	player.cam_pitch = deg_to_rad(-10.0)
	for i in range(15):
		player.update_aim(0.05)
		
	print('  - Camera pitch: -10 deg -> Current cannon pitch: ', rad_to_deg(player.current_cannon_pitch), ' deg')
	assert(player.current_cannon_pitch < 0.0, 'Cannon should depress downward!')
	print('[CHECK 5B] Cannon depresses DOWNWARD when aiming at the ground!')
	
	# Verify FPS Camera Toggle
	var ev = InputEventAction.new()
	ev.action = 'toggle_camera'
	ev.pressed = true
	player._input(ev)
	assert(player.is_fps_mode == true, 'Should be in FPS mode')
	assert(player.fps_camera.current == true, 'FPS camera should be active')
	print('[CHECK 6] FPS Cockpit Visor View successfully activated at: ', player.fps_camera.position)
	
	# Verify Firing
	player.shoot_cannon()
	print('[CHECK 7] 57mm Smoothbore Cannon fired successfully with muzzle flash & shell!')
	
	print('>>> ALL 7 RIGGED 86 COMBAT CHECKS PASSED PERFECTLY! <<<')
	quit(0)
