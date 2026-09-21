extends "res://scripts/arena_manager.gd"
class_name ChapterMissionManager

# =============================================================================
# CHAPTER MISSION MANAGER: "A DAY IN SECTOR 86" (CAMPAIGN TEST CHAPTER)
#
# Authentic Novel Setting:
# - Phase 1: High Noon Assault (12:45) - Sunny sky, Legion scout probe
# - Intermission: Time-Skip Modal (13:10 -> 23:30) - Lore briefing & rest
# - Phase 2: Midnight Siege (23:30) - Starry night, NVG combat, Legion Shepherd
# - Forward Base (BaseCore) defense: If base is destroyed, mission fails
# - Rear Civilian Village (District 86) protected behind the base
# - Allied AI: Raiden (Wehrwolf) & Kurena (Gunslinger) with Para-RAID chatter
# =============================================================================

enum MissionPhase {
	PHASE_1_NOON,
	INTERMISSION,
	PHASE_2_MIDNIGHT,
	VICTORY,
	DEFEAT
}

const ALLIED_SCENE = preload("res://scenes/allied_juggernaut.tscn")
const LEGION_SCENE = preload("res://scenes/legion_enemy.tscn")
const SHEPHERD_SCENE = preload("res://scenes/legion_shepherd.tscn")

const SKY_DAY = preload("res://assets/environment/textures/schachen_forest_1k.hdr")
const SKY_NIGHT = preload("res://assets/environment/textures/dikhololo_night_1k.hdr")

const BaseAndVillageBuilderScript = preload("res://scripts/base_and_village_builder.gd")
const ProceduralAudioScript = preload("res://scripts/procedural_audio.gd")

@onready var chapter_hud: Control = ($CanvasLayer/ChapterHUD if has_node("CanvasLayer/ChapterHUD") else $CanvasLayer/CombatHUD)
@onready var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
@onready var sun_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D")

var current_mission_phase: MissionPhase = MissionPhase.PHASE_1_NOON
var base_core: Node3D = null

var active_legion_units: Array[CharacterBody3D] = []
var allied_units: Array[Node3D] = []
var shepherd_unit: CharacterBody3D = null

var is_mission_ended: bool = false
var phase_dialogue_tweens: Array[Tween] = []

func _ready() -> void:
	hud = chapter_hud
	
	# 1. Procedurally construct Forward Base and Rear Village
	base_core = BaseAndVillageBuilderScript.build_base_and_village(self)
	if base_core:
		base_core.base_damaged.connect(_on_base_damaged)
		base_core.base_destroyed.connect(_on_base_destroyed)
		chapter_hud.update_base_integrity(base_core.current_hp, base_core.max_hp)

	# 2. Setup standard battlefield snapping, destructibles, and MultiMeshes
	setup_battlefield_collisions()

	# 3. Bind player to HUD
	if chapter_hud and player:
		chapter_hud.bind_player(player)

	# 4. Connect Intermission proceed signal
	if chapter_hud:
		chapter_hud.proceed_to_phase_2_requested.connect(_on_proceed_to_phase_2)

	# 5. Spawn Allied Spearhead Bots
	_spawn_allied_squadron()

	# 6. Setup Ambient Audio
	if ambient_audio:
		ambient_audio.stream = ProceduralAudioScript.create_ambient_wind_sound()
		ambient_audio.play()

	# 7. Start Phase 1: High Noon Assault
	_start_phase_1_noon()

# =============================================================================
# ALLIED SQUADRON SPAWNER
# =============================================================================
func _spawn_allied_squadron() -> void:
	var gam = get_node_or_null("/root/GameAppManager")
	var player_pilot = gam.selected_pilot if gam else "undertaker"
	var all_pilots = ["undertaker", "wehrwolf", "gunslinger"]
	var ally_ids = []
	for p in all_pilots:
		if p != player_pilot:
			ally_ids.append(p)
			
	var spawn_coords = [
		Vector2(-14.0, 32.0),
		Vector2(16.0, 35.0)
	]
	
	for i in range(ally_ids.size()):
		var ally_id = ally_ids[i]
		var cfg = gam.get_pilot_config(ally_id) if gam else {}
		var ally = ALLIED_SCENE.instantiate()
		ally.name = "Allied_" + cfg.get("callsign", "WEHRWOLF")
		ally.callsign = cfg.get("callsign", "WEHRWOLF")
		ally.pilot_name = cfg.get("pilot_name", "Pilot")
		ally.max_hp = cfg.get("max_hp", 140.0)
		ally.combat_speed = cfg.get("speed", 7.2)
		ally.fire_cooldown = cfg.get("fire_cooldown", 2.2)
		
		if ally_id == "gunslinger":
			ally.guard_radius = 55.0
			ally.attack_range = 170.0
		elif ally_id == "undertaker":
			ally.guard_radius = 40.0
			ally.attack_range = 130.0
		else: # wehrwolf
			ally.guard_radius = 42.0
			ally.attack_range = 135.0
			
		var coord = spawn_coords[i % spawn_coords.size()]
		var a_y = get_ground_elevation(coord.x, coord.y)
		ally.position = Vector3(coord.x, a_y + 1.2, coord.y)
		ally.base_guard_pos = Vector3(coord.x, a_y, coord.y)
		add_child(ally)
		allied_units.append(ally)
		
		ally.hp_changed.connect(_on_ally_hp_changed)
		ally.radio_chatter_sent.connect(_on_radio_chatter)
		chapter_hud.update_allies_status(ally.callsign, ally.current_hp, ally.max_hp)

# =============================================================================
# ENVIRONMENT LIGHTING CONTROLLER
# =============================================================================
func _set_environment_lighting(is_night: bool) -> void:
	if not world_env or not world_env.environment:
		return
		
	var env = world_env.environment
	if is_night:
		if env.sky and env.sky.sky_material is PanoramaSkyMaterial:
			(env.sky.sky_material as PanoramaSkyMaterial).panorama = SKY_NIGHT
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.08, 0.12, 0.24, 1.0)
		env.ambient_light_energy = 0.65
		env.fog_enabled = true
		env.fog_light_color = Color(0.025, 0.05, 0.10, 1.0)
		env.fog_density = 0.00035
		
		if sun_light:
			sun_light.light_color = Color(0.68, 0.78, 0.98, 1.0)
			sun_light.light_energy = 0.48
			sun_light.rotation_degrees = Vector3(-35.0, 140.0, 0.0)
	else:
		if env.sky and env.sky.sky_material is PanoramaSkyMaterial:
			(env.sky.sky_material as PanoramaSkyMaterial).panorama = SKY_DAY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.55, 0.52, 0.48, 1.0)
		env.ambient_light_energy = 1.05
		env.fog_enabled = true
		env.fog_light_color = Color(0.68, 0.65, 0.60, 1.0)
		env.fog_density = 0.00015
		
		if sun_light:
			sun_light.light_color = Color(1.0, 0.96, 0.88, 1.0)
			sun_light.light_energy = 1.35
			sun_light.rotation_degrees = Vector3(-65.0, 25.0, 0.0) # High midday sun

# =============================================================================
# PHASE 1: HIGH NOON ASSAULT (12:45)
# =============================================================================
func _start_phase_1_noon() -> void:
	current_mission_phase = MissionPhase.PHASE_1_NOON
	_set_environment_lighting(false)
	
	if chapter_hud:
		chapter_hud.set_timeline("12:45 // HIGH NOON ASSAULT", false)
		chapter_hud.set_night_vision(false)
		
	# Daytime: Turn off player headlight initially
	if player:
		player.is_headlight_active = false
		if player.headlight_l: player.headlight_l.visible = false
		if player.headlight_r: player.headlight_r.visible = false

	# Clear any prior enemies
	active_legion_units.clear()

	# Spawn 7 Legion units (4 Ameise scouts + 3 Grauwolf assault)
	var spawn_configs = [
		# [type, x, z, flank_dir]
		[0, -140.0, -230.0, -1.0], # Ameise West Flank
		[1, -85.0,  -260.0, -0.5], # Grauwolf West Support
		[0, -35.0,  -240.0,  0.0], # Ameise Center-Left
		[1,   0.0,  -275.0,  0.0], # Grauwolf Center Spearhead
		[0,  35.0,  -240.0,  0.0], # Ameise Center-Right
		[1,  85.0,  -260.0,  0.5], # Grauwolf East Support
		[0, 140.0,  -230.0,  1.0], # Ameise East Flank
	]

	for i in range(spawn_configs.size()):
		var cfg = spawn_configs[i]
		var utype = cfg[0]
		var sx = cfg[1]
		var sz = cfg[2]
		var flank = cfg[3]
		var sy = get_ground_elevation(sx, sz)

		var unit = LEGION_SCENE.instantiate()
		unit.name = "Legion_Phase1_%d" % (i + 1)
		unit.unit_type = utype
		unit.tactical_flank_dir = flank
		unit.position = Vector3(sx, sy + 1.2, sz)
		unit.base_target_pos = base_core.global_position if base_core else Vector3(0, 0, 45)
		add_child(unit)
		active_legion_units.append(unit)
		
		unit.legion_died.connect(_on_phase_1_unit_died)

	chapter_hud.update_legion_counter(active_legion_units.size())
	if active_legion_units.size() > 0:
		chapter_hud.bind_enemy(active_legion_units[0])
		chapter_hud.set_all_enemies(active_legion_units)

	# Para-RAID Opening Narrative Sequence
	var tw = create_tween()
	phase_dialogue_tweens.append(tw)
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Undertaker, Spearhead Squadron! Frontline radar confirms a Legion scout vanguard advancing toward Outpost 01! Intercept immediately!"
		)
	)
	tw.tween_interval(4.5)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"WEHRWOLF (RAIDEN)",
			"Hmph, right in the middle of our lunch break. Typical Legion. Let's scrap 'em, Shin!"
		)
	)
	tw.tween_interval(4.2)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"GUNSLINGER (KURENA)",
			"Undertaker, covering your flank! Don't let them touch the base!"
		)
	)

func _on_phase_1_unit_died(unit: Node3D) -> void:
	if unit in active_legion_units:
		active_legion_units.erase(unit)
	
	chapter_hud.update_legion_counter(active_legion_units.size())
	
	# Check if Phase 1 is cleared
	if active_legion_units.is_empty() and current_mission_phase == MissionPhase.PHASE_1_NOON and not is_mission_ended:
		_complete_phase_1()

func _complete_phase_1() -> void:
	current_mission_phase = MissionPhase.INTERMISSION
	
	var tw = create_tween()
	phase_dialogue_tweens.append(tw)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Scout vanguard eliminated! Great work, Spearhead. But frontline sensors indicate a massive secondary wave gathering for nightfall..."
		)
	)
	tw.tween_interval(4.2)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"WEHRWOLF (RAIDEN)",
			"That was just their forward probe. If they hit us at noon, the real siege begins when the sun goes down."
		)
	)
	tw.tween_interval(4.0)
	tw.tween_callback(func():
		chapter_hud.show_intermission()
	)

# =============================================================================
# INTERMISSION -> PHASE 2 TRANSITION
# =============================================================================
func _on_proceed_to_phase_2() -> void:
	if is_mission_ended:
		return
	_start_phase_2_midnight()

# =============================================================================
# PHASE 2: MIDNIGHT SIEGE (23:30) & LEGION SHEPHERD BOSS
# =============================================================================
func _start_phase_2_midnight() -> void:
	current_mission_phase = MissionPhase.PHASE_2_MIDNIGHT
	_set_environment_lighting(true)

	if chapter_hud:
		chapter_hud.set_timeline("23:30 // MIDNIGHT SIEGE [NIGHT OPERATIONS]", true)
		chapter_hud.set_night_vision(true)

	# Nighttime: Turn on player headlights
	if player:
		player.is_headlight_active = true
		if player.headlight_l: player.headlight_l.visible = true
		if player.headlight_r: player.headlight_r.visible = true

	active_legion_units.clear()

	# 1. Spawn 10 Escort Legion Units in wide assault formation
	var midnight_spawns = [
		[-160.0, -250.0, 0], # Ameise Far West
		[-120.0, -270.0, 1], # Grauwolf West
		[ -80.0, -240.0, 0], # Ameise West-Center
		[ -45.0, -280.0, 1], # Grauwolf Center-Left
		[ -20.0, -250.0, 0], # Ameise Center
		[  20.0, -250.0, 0], # Ameise Center
		[  45.0, -280.0, 1], # Grauwolf Center-Right
		[  80.0, -240.0, 0], # Ameise East-Center
		[ 120.0, -270.0, 1], # Grauwolf East
		[ 160.0, -250.0, 0], # Ameise Far East
	]

	for i in range(midnight_spawns.size()):
		var cfg = midnight_spawns[i]
		var sx = cfg[0]
		var sz = cfg[1]
		var utype = cfg[2]
		var sy = get_ground_elevation(sx, sz)

		var unit = LEGION_SCENE.instantiate()
		unit.name = "Legion_Phase2_%d" % (i + 1)
		unit.unit_type = utype
		unit.position = Vector3(sx, sy + 1.2, sz)
		unit.base_target_pos = base_core.global_position if base_core else Vector3(0, 0, 45)
		add_child(unit)
		active_legion_units.append(unit)
		unit.legion_died.connect(_on_phase_2_unit_died)

	# 2. Spawn the Legendary Boss: Legion Shepherd ("Con Đầu Đàn")
	var b_x = 0.0
	var b_z = -235.0
	var b_y = get_ground_elevation(b_x, b_z)

	shepherd_unit = SHEPHERD_SCENE.instantiate()
	shepherd_unit.name = "Legion_Commander_Shepherd"
	shepherd_unit.position = Vector3(b_x, b_y + 1.5, b_z)
	shepherd_unit.base_target_pos = base_core.global_position if base_core else Vector3(0, 0, 45)
	add_child(shepherd_unit)
	active_legion_units.append(shepherd_unit)

	shepherd_unit.hp_changed.connect(_on_shepherd_hp_changed)
	shepherd_unit.shepherd_voice.connect(_on_shepherd_voice)
	shepherd_unit.legion_died.connect(_on_shepherd_died)

	chapter_hud.show_boss_bar("LEGION COMMANDER // SHEPHERD: THE NAMELESS REAPER", shepherd_unit.max_hp, shepherd_unit.max_hp)
	chapter_hud.update_legion_counter(active_legion_units.size())
	chapter_hud.bind_enemy(shepherd_unit)
	chapter_hud.set_all_enemies(active_legion_units)

	# Para-RAID Phase 2 Narrative Sequence (Novel-accurate chilling atmosphere)
	var tw = create_tween()
	phase_dialogue_tweens.append(tw)
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"SHEPHERD (GHOST VOICE)",
			"...Undertaker... Tại sao ngươi lại từ chối cái chết?... Gia nhập cùng chúng tôi...",
			true
		)
	)
	tw.tween_interval(4.5)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Shin! Undertaker! Can you hear that scream?! A massive Shepherd signal has breached the front! It's commanding the entire horde!",
			true
		)
	)
	tw.tween_interval(4.5)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"UNDERTAKER (SHIN)",
			"I hear it. The voice of a ghost trapped in cold steel. Everyone, protect the base. I'll cut off its head."
		)
	)
	tw.tween_interval(4.0)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"WEHRWOLF (RAIDEN)",
			"Don't take all the glory, Reaper! Gunslinger and I will hold the flanks!"
		)
	)

func _on_shepherd_hp_changed(curr: float, _max_v: float) -> void:
	if chapter_hud:
		chapter_hud.update_boss_hp(curr)

func _on_shepherd_voice(whisper_text: String) -> void:
	if not is_mission_ended and chapter_hud:
		chapter_hud.show_pararaid_message("SHEPHERD (GHOST VOICE)", whisper_text, true)

func _on_shepherd_died(_unit: Node3D) -> void:
	if chapter_hud:
		chapter_hud.hide_boss_bar()
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Shepherd core confirmed destroyed! Its neural network has collapsed!",
			true
		)
	_on_phase_2_unit_died(shepherd_unit)

func _on_phase_2_unit_died(unit: Node3D) -> void:
	if unit in active_legion_units:
		active_legion_units.erase(unit)
		
	chapter_hud.update_legion_counter(active_legion_units.size())

	# Victory when all Phase 2 units (including Shepherd) are wiped out
	if active_legion_units.is_empty() and current_mission_phase == MissionPhase.PHASE_2_MIDNIGHT and not is_mission_ended:
		_trigger_chapter_victory()

# =============================================================================
# VICTORY & DEFEAT HANDLERS
# =============================================================================
func _trigger_chapter_victory() -> void:
	is_mission_ended = true
	current_mission_phase = MissionPhase.VICTORY

	for tw in phase_dialogue_tweens:
		if tw and tw.is_valid():
			tw.kill()

	var tw = create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Undertaker... Spearhead Squadron... all hostile signatures neutralized! The base is saved! You survived!"
		)
	)
	tw.tween_interval(4.0)
	tw.tween_callback(func():
		chapter_hud.show_pararaid_message(
			"WEHRWOLF (RAIDEN)",
			"Heh. We survived another day in hell. Let's head back and get some sleep."
		)
	)
	tw.tween_interval(3.5)
	tw.tween_callback(func():
		chapter_hud.show_chapter_victory_banner()
	)

func _on_base_damaged(curr: float, max_v: float) -> void:
	if chapter_hud:
		chapter_hud.update_base_integrity(curr, max_v)
		
	if curr < max_v * 0.4 and not is_mission_ended:
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"Warning! Forward Base integrity is critically low! Prevent Legion units from breaching the perimeter!",
			true
		)

func _on_base_destroyed() -> void:
	if is_mission_ended:
		return
	is_mission_ended = true
	current_mission_phase = MissionPhase.DEFEAT

	for tw in phase_dialogue_tweens:
		if tw and tw.is_valid():
			tw.kill()

	if chapter_hud:
		chapter_hud.show_pararaid_message(
			"HANDLER ONE (LENA)",
			"The Forward Outpost has fallen! Legion units are breaking through toward the civilian village! Mission failure... all units fall back!",
			true
		)
		chapter_hud.show_defeat_banner(
			"BASE OVERRUN - SECTOR 86 FALLEN",
			"THE FORWARD BASE HAS BEEN DESTROYED.\nTHE REAR VILLAGE HAS FALLEN TO THE LEGION.\nPress [R] to Re-deploy or Return to Base"
		)

func _on_ally_hp_changed(callsign: String, curr_hp: float, max_hp: float) -> void:
	if chapter_hud:
		chapter_hud.update_allies_status(callsign, curr_hp, max_hp)

func _on_radio_chatter(speaker: String, text: String, urgent: bool) -> void:
	if not is_mission_ended and chapter_hud:
		chapter_hud.show_pararaid_message(speaker, text, urgent)
