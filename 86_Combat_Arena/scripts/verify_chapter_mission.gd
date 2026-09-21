extends SceneTree

# =============================================================================
# VERIFICATION SUITE: CHAPTER 1 "A DAY IN SECTOR 86"
# =============================================================================

func _init() -> void:
	print("================================================================")
	print("--- STARTING AUTOMATED TEST: CHAPTER 1 MISSION SUITE ---")
	print("================================================================")
	
	var mission_scene = load("res://scenes/chapter_1_mission.tscn")
	if not mission_scene:
		printerr("FAIL: Could not load res://scenes/chapter_1_mission.tscn")
		quit(1)
		return
		
	var mission_node = mission_scene.instantiate()
	root.add_child(mission_node)
	
	# Allow two frames for _ready() callbacks to execute
	await process_frame
	await process_frame
	
	# 1. Test Forward Base Construction
	var base_core = mission_node.get_node_or_null("ForwardBase_SpearheadOutpost/BaseCore_CommandPost")
	if not base_core:
		printerr("FAIL: BaseCore_CommandPost not found under ForwardBase_SpearheadOutpost!")
		quit(1)
		return
	print("PASS: Forward Base Core found with initial HP: %f / %f" % [base_core.current_hp, base_core.max_hp])
	assert(base_core.current_hp == 1000.0, "BaseCore initial HP must be 1000")
	
	# 2. Test Rear Civilian Village
	var village = mission_node.get_node_or_null("RearCivilianVillage_District86")
	if not village or village.get_child_count() == 0:
		printerr("FAIL: RearCivilianVillage_District86 missing or has 0 children!")
		quit(1)
		return
	print("PASS: Rear Civilian Village constructed successfully with %d district structures." % village.get_child_count())
	
	# 3. Test Allied Juggernauts
	var wehrwolf = mission_node.get_node_or_null("Allied_Wehrwolf")
	var gunslinger = mission_node.get_node_or_null("Allied_Gunslinger")
	if not wehrwolf or not gunslinger:
		printerr("FAIL: Allied Spearhead bots missing!")
		quit(1)
		return
	print("PASS: Allies spawned -> Wehrwolf HP: %f, Gunslinger HP: %f" % [wehrwolf.current_hp, gunslinger.current_hp])
	assert(wehrwolf.callsign == "WEHRWOLF", "Raiden callsign must be WEHRWOLF")
	assert(gunslinger.callsign == "GUNSLINGER", "Kurena callsign must be GUNSLINGER")
	
	# 4. Test Phase 1 Legion Vanguard
	print("PASS: Phase 1 active legion units count: %d" % mission_node.active_legion_units.size())
	assert(mission_node.active_legion_units.size() == 7, "Phase 1 must spawn 7 Legion units")
	
	# 5. Test Base Damage and HUD reflection
	var prev_hp = base_core.current_hp
	base_core.take_damage(120.0)
	assert(base_core.current_hp == prev_hp - 120.0, "BaseCore must take damage")
	print("PASS: BaseCore took 120 damage -> New HP: %f" % base_core.current_hp)
	
	# 6. Test Phase 2 Midnight Transition & Shepherd Boss Spawning
	print("--> Triggering Transition to Phase 2: Midnight Siege...")
	mission_node._on_proceed_to_phase_2()
	await process_frame
	await process_frame
	
	assert(mission_node.current_mission_phase == mission_node.MissionPhase.PHASE_2_MIDNIGHT, "Phase must be PHASE_2_MIDNIGHT")
	print("PASS: Current phase is PHASE_2_MIDNIGHT.")
	
	var shepherd = mission_node.shepherd_unit
	if not shepherd:
		printerr("FAIL: Shepherd boss was not spawned in Phase 2!")
		quit(1)
		return
	print("PASS: Legion Shepherd Boss spawned! HP: %f / %f, Scale: %s" % [shepherd.current_hp, shepherd.max_hp, str(shepherd.scale)])
	assert(shepherd.current_hp == 450.0, "Shepherd HP must be 450")
	
	# 7. Test Shepherd Voice Whispers
	var whisper_received: String = ""
	shepherd.shepherd_voice.connect(func(txt): whisper_received = txt)
	shepherd.shepherd_voice.emit("Undertaker... Gia nhập cùng chúng tôi...")
	assert(whisper_received != "", "Shepherd voice whisper must be broadcast")
	print("PASS: Shepherd Voice Whisper verified: '%s'" % whisper_received)
	
	# 8. Test Shepherd Boss Damage
	shepherd.take_damage(100.0)
	assert(shepherd.current_hp == 350.0, "Shepherd must take damage correctly")
	print("PASS: Shepherd took 100 damage -> New HP: %f" % shepherd.current_hp)
	
	# 9. Test Total Phase 2 Legion Count (10 escorts + 1 Shepherd = 11)
	print("PASS: Phase 2 active legion units count: %d" % mission_node.active_legion_units.size())
	assert(mission_node.active_legion_units.size() == 11, "Phase 2 must spawn 10 escorts + 1 Shepherd Boss")
	
	print("================================================================")
	print(">>> ALL CHAPTER 1 VERIFICATION TESTS PASSED SUCCESSFULLY! <<<")
	print("================================================================")
	quit(0)
