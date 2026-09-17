extends CharacterBody3D
class_name PlayerJuggernaut

signal hp_changed(current_hp: float, max_hp: float)
signal reload_progress(ratio: float)
signal fired_cannon()
signal died()
signal camera_mode_changed(is_fps: bool)
signal telemetry_updated(cannon_pitch_deg: float, turret_yaw_deg: float)
signal night_vision_toggled(active: bool)

@export var walk_speed: float = 8.0
@export var run_speed: float = 16.0
@export var mouse_sensitivity: float = 0.0025
@export var max_hp: float = 100.0
@export var cannon_cooldown: float = 1.8

var is_night_vision_active: bool = true
var is_headlight_active: bool = true

var current_hp: float = 100.0
var reload_timer: float = 0.0
var is_aiming: bool = false
var is_dead: bool = false
var is_fps_mode: bool = true
var is_free_looking: bool = false

var cam_pitch: float = 0.0
var current_cannon_pitch: float = 0.0
var current_turret_yaw: float = 0.0
var recoil_pitch: float = 0.0
var recoil_buffer: float = 0.0
var footstep_timer: float = 0.0

# Stationary & Steering Quadruped Turn State
var prev_yaw: float = 0.0
var smoothed_turn_rate: float = 0.0
var turn_latch_timer: float = 0.0
var current_turn_direction: float = 0.0

@onready var model_instance: Node3D = $ModelInstance
@onready var muzzle: Marker3D = $Muzzle
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var fps_camera: Camera3D = get_node_or_null("FPSCamera3D")
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var footstep_audio_player: AudioStreamPlayer3D = get_node_or_null("FootstepAudioPlayer3D")
@onready var headlight_l: SpotLight3D = get_node_or_null("TacticalHeadlightL")
@onready var headlight_r: SpotLight3D = get_node_or_null("TacticalHeadlightR")

@onready var anim_player: AnimationPlayer = get_node_or_null("ModelInstance/AnimationPlayer")
@onready var skeleton: Skeleton3D = get_node_or_null("ModelInstance/M1A4_Armature/Skeleton3D")
var turret_bone_idx: int = -1
var cannon_bone_idx: int = -1
var recoil_bone_idx: int = -1
var turret_rest_q: Quaternion = Quaternion.IDENTITY
var cannon_rest_q: Quaternion = Quaternion.IDENTITY
var recoil_rest_pos: Vector3 = Vector3.ZERO

var cannon_shell_scene = preload("res://scenes/cannon_shell.tscn")
var muzzle_flash_scene = preload("res://scenes/muzzle_flash_vfx.tscn")

var default_cam_fov: float = 80.0
var ads_cam_fov: float = 35.0

func _ready() -> void:
	current_hp = max_hp
	prev_yaw = rotation.y
	
	# Configure robust quadruped terrain navigation to completely eliminate sticking
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(60.0)
	floor_stop_on_slope = true
	safe_margin = 0.005
	wall_min_slide_angle = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hp_changed.emit(current_hp, max_hp)
	reload_progress.emit(1.0)
	
	# Bind Rigged Model Nodes
	if model_instance:
		anim_player = model_instance.get_node_or_null("AnimationPlayer")
		skeleton = model_instance.get_node_or_null("M1A4_Armature/Skeleton3D")
		
	if skeleton:
		turret_bone_idx = skeleton.find_bone("Turret")
		cannon_bone_idx = skeleton.find_bone("Cannon")
		recoil_bone_idx = skeleton.find_bone("Cannon_Recoil")
		if turret_bone_idx >= 0:
			turret_rest_q = skeleton.get_bone_rest(turret_bone_idx).basis.get_rotation_quaternion()
		if cannon_bone_idx >= 0:
			cannon_rest_q = skeleton.get_bone_rest(cannon_bone_idx).basis.get_rotation_quaternion()
		if recoil_bone_idx >= 0:
			recoil_rest_pos = skeleton.get_bone_rest(recoil_bone_idx).origin
		
	if anim_player:
		for anim_name in ["Walk", "Run", "Idle", "Turn_Left", "Turn_Right"]:
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")

	# Default to First-Person Cockpit view
	is_fps_mode = true
	is_free_looking = false
	# Optimized camera far plane (1200m provides full 800m corner-to-corner visibility without GPU depth-precision waste)
	if fps_camera:
		fps_camera.far = 1200.0
	if camera:
		camera.far = 1200.0
	if headlight_l:
		headlight_l.visible = is_headlight_active
	if headlight_r:
		headlight_r.visible = is_headlight_active
	update_camera_and_mesh_visibility()

func toggle_night_vision() -> bool:
	is_night_vision_active = not is_night_vision_active
	night_vision_toggled.emit(is_night_vision_active)
	return is_night_vision_active

func toggle_headlights() -> bool:
	is_headlight_active = not is_headlight_active
	if headlight_l:
		headlight_l.visible = is_headlight_active
	if headlight_r:
		headlight_r.visible = is_headlight_active
	return is_headlight_active

func update_camera_and_mesh_visibility() -> void:
	var in_fps = is_fps_mode and not is_free_looking
	if fps_camera:
		fps_camera.current = in_fps
	if camera:
		camera.current = not in_fps
		
	# In FPS cockpit mode, hide the mecha model instance so no head or barrel obstructs the view.
	# The pilot views the battlefield cleanly through the cockpit visor and instruments.
	if model_instance:
		model_instance.visible = not in_fps
			
	camera_mode_changed.emit(in_fps)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			# Do NOT auto-capture on focus in; wait for explicit player click
			pass

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if is_dead or get_tree().paused:
		return
		
	# Release mouse on Escape
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		return

	# If mouse is NOT captured, require explicit left click to capture control
	# NEVER capture mouse on mere mouse movement!
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
		return

	# Right Mouse Button: Hold RMB to enter 3rd-person Free-Look
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_free_looking = event.pressed
		if spring_arm:
			spring_arm.rotation.y = 0.0
		update_camera_and_mesh_visibility()
		get_viewport().set_input_as_handled()
		return
		
	# Mouse look & aim (Only executes when mouse is captured)
	if event is InputEventMouseMotion:
			
		if not is_free_looking:
			# FIRST-PERSON MODE (Default):
			# Horizontal mouse steers the mecha body
			var mouse_steer_yaw = -event.relative.x * mouse_sensitivity
			rotate_y(mouse_steer_yaw)
			if abs(event.relative.x) > 0.8:
				current_turn_direction = signf(mouse_steer_yaw)
				turn_latch_timer = 0.35
				smoothed_turn_rate = mouse_steer_yaw / 0.016
			# Vertical mouse tilts camera and cannon
			cam_pitch = clampf(cam_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-45.0), deg_to_rad(30.0))
			if fps_camera:
				fps_camera.rotation.x = cam_pitch
			if spring_arm:
				spring_arm.rotation.x = cam_pitch
				spring_arm.rotation.y = 0.0
		else:
			# THIRD-PERSON FREE-LOOK MODE (Holding RMB):
			# DO NOT ROTATE THE MECHA BODY! Movement direction is 100% preserved!
			# Only orbit the 3rd person SpringArm3D freely around the mecha
			if spring_arm:
				spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
				spring_arm.rotation.x = clampf(spring_arm.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-60.0), deg_to_rad(35.0))
		
	# Keyboard Toggle Camera (V)
	if event.is_action_pressed("toggle_camera") and not event.is_echo() and not is_free_looking:
		is_fps_mode = not is_fps_mode
		update_camera_and_mesh_visibility()

	# Keyboard Toggle Night Vision Optics (N)
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_N:
		toggle_night_vision()
		get_viewport().set_input_as_handled()

	# Keyboard Toggle Tactical Headlights (L)
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_L:
		toggle_headlights()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if is_dead:
		move_and_slide()
		return
		
	# Cannon reload timer
	if reload_timer > 0.0:
		reload_timer -= delta
		reload_progress.emit(1.0 - clampf(reload_timer / cannon_cooldown, 0.0, 1.0))
	else:
		reload_progress.emit(1.0)
		
	# Fire input
	if Input.is_action_just_pressed("fire_cannon") and reload_timer <= 0.0:
		shoot_cannon()
		
	# Smooth Camera ADS Zoom
	var active_cam = fps_camera if (is_fps_mode and fps_camera) else camera
	if active_cam:
		var target_fov = ads_cam_fov if is_aiming else default_cam_fov
		active_cam.fov = lerpf(active_cam.fov, target_fov, 12.0 * delta)
		
	# Movement input (WASD)
	var forward_in = Input.get_axis("move_backward", "move_forward")
	var strafe_in = Input.get_axis("turn_left", "turn_right")
	var is_running = Input.is_action_pressed("run")
	var current_speed = run_speed if is_running else walk_speed

	var input_dir = Vector3(strafe_in, 0, -forward_in).normalized()
	var move_dir = (transform.basis * input_dir).normalized()
	
	var is_moving = move_dir.length() > 0.05
	
	var is_on_ground = is_on_floor()
	if not is_on_ground:
		velocity.y -= 24.0 * delta
	else:
		velocity.y = 0.0

	if is_moving:
		if is_on_ground:
			var floor_norm = get_floor_normal()
			# Slope Tangent Projection: Projects move_dir seamlessly along the terrain slope plane
			# This eliminates triangle edge snagging on concave terrain and hills!
			var slope_tangent = (move_dir - floor_norm * move_dir.dot(floor_norm)).normalized()
			velocity = slope_tangent * current_speed
		else:
			velocity.x = move_dir.x * current_speed
			velocity.z = move_dir.z * current_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if is_on_ground:
			velocity.y = 0.0

	move_and_slide()
	
	var horiz_vel = Vector2(velocity.x, velocity.z).length()
	
	# Track angular yaw velocity (for stationary quadruped pivot turning)
	var current_yaw = rotation.y
	var raw_yaw_delta = wrapf(current_yaw - prev_yaw, -PI, PI)
	prev_yaw = current_yaw
	
	var raw_turn_rate = raw_yaw_delta / maxf(delta, 0.0001)
	smoothed_turn_rate = lerpf(smoothed_turn_rate, raw_turn_rate, 14.0 * delta)
	
	# Mouse input occurs in discrete events; latch the turn state so the quadruped
	# legs execute complete, rhythmic stepping arcs during turns
	if abs(raw_yaw_delta) > 0.0015:
		current_turn_direction = signf(raw_yaw_delta)
		turn_latch_timer = 0.35
	elif turn_latch_timer > 0.0:
		turn_latch_timer -= delta
		
	# Dynamic chassis roll/lean into turns when running or steering
	if model_instance:
		var target_roll = 0.0
		if horiz_vel > 0.4:
			target_roll = clampf(-smoothed_turn_rate * 0.03, deg_to_rad(-5.0), deg_to_rad(5.0))
		model_instance.rotation.z = lerpf(model_instance.rotation.z, target_roll, 10.0 * delta)
	
	# Update Skeletal Walk / Run / Turn / Idle Animations
	update_animations(delta, horiz_vel, is_running)
	
	# Update 3D Aim Tracking for Cannon & Turret
	update_aim(delta)
	
	# Audio footsteps synchronized to motion and stationary pivot turning
	var is_pivoting = (turn_latch_timer > 0.0 or abs(smoothed_turn_rate) > 0.15) and current_turn_direction != 0.0
	if horiz_vel > 0.4:
		var step_interval = 0.30 if is_running else 0.48
		var anim_spd = anim_player.speed_scale if anim_player else 1.0
		footstep_timer -= delta * anim_spd
		if footstep_timer <= 0.0:
			footstep_timer = step_interval
			play_footstep()
	elif is_pivoting:
		var step_interval = 0.36
		var anim_spd = anim_player.speed_scale if anim_player else 1.0
		footstep_timer -= delta * anim_spd
		if footstep_timer <= 0.0:
			footstep_timer = step_interval
			play_footstep()
	else:
		footstep_timer = 0.0

func update_animations(delta: float, horiz_vel: float, is_running: bool) -> void:
	if not anim_player:
		return
		
	if is_dead:
		if anim_player.current_animation != "Death":
			anim_player.play("Death", 0.2)
		return
		
	if horiz_vel > 0.4:
		if is_running:
			if anim_player.current_animation != "Run":
				anim_player.play("Run", 0.2)
			anim_player.speed_scale = clampf((horiz_vel / run_speed) * 1.3, 0.6, 2.0)
		else:
			if anim_player.current_animation != "Walk":
				anim_player.play("Walk", 0.2)
			anim_player.speed_scale = clampf((horiz_vel / walk_speed) * 1.1, 0.6, 1.8)
	else:
		# Stationary: check if pivoting / turning left or right
		var is_pivoting = (turn_latch_timer > 0.0 or abs(smoothed_turn_rate) > 0.15) and current_turn_direction != 0.0
		if is_pivoting:
			var target_anim = "Turn_Left" if current_turn_direction > 0.0 else "Turn_Right"
			if anim_player.current_animation != target_anim:
				anim_player.play(target_anim, 0.2)
			var turn_speed_scale = clampf(abs(smoothed_turn_rate) * 0.45, 0.8, 2.0)
			anim_player.speed_scale = turn_speed_scale
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle", 0.25)
			anim_player.speed_scale = 1.0

func get_aim_target() -> Vector3:
	var active_cam = fps_camera if (is_fps_mode or is_free_looking) and fps_camera else camera
	if not active_cam:
		return global_position + (-global_transform.basis.z * 150.0)
		
	var ray_origin = active_cam.global_position
	var ray_forward = -active_cam.global_transform.basis.z
	var max_dist = 250.0
	var ray_end = ray_origin + ray_forward * max_dist
	
	var world = get_world_3d()
	if world and world.direct_space_state:
		var space_state = world.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1 | 2)
		query.exclude = [self]
		var hit = space_state.intersect_ray(query)
		if hit:
			return hit.position
	return ray_end

func update_aim(delta: float) -> void:
	var target_pos = get_aim_target()
	var cannon_pivot = global_position + (global_transform.basis * Vector3(0, 1.8427, 0))
	var aim_dir = (target_pos - cannon_pivot).normalized()
	
	# Convert aim direction into local body coordinate space
	var local_aim = global_transform.basis.inverse() * aim_dir
	
	# Calculate desired pitch (elevation/depression) & yaw (left/right traverse)
	var target_pitch = atan2(local_aim.y, -local_aim.z)
	var target_yaw = atan2(-local_aim.x, -local_aim.z)
	
	# Clamp to realistic combat limits
	target_pitch = clampf(target_pitch, deg_to_rad(-12.0), deg_to_rad(40.0))
	target_yaw = clampf(target_yaw, deg_to_rad(-40.0), deg_to_rad(40.0))
	
	# Smoothly interpolate towards target angles
	current_cannon_pitch = lerpf(current_cannon_pitch, target_pitch, 16.0 * delta)
	current_turret_yaw = lerpf(current_turret_yaw, target_yaw, 16.0 * delta)
	
	# Emit telemetry for cockpit HUD instruments
	telemetry_updated.emit(rad_to_deg(current_cannon_pitch), rad_to_deg(current_turret_yaw))
	
	# Recoil buffer recovery
	if recoil_pitch > 0.0:
		recoil_pitch = move_toward(recoil_pitch, 0.0, 12.0 * delta)
	if recoil_buffer > 0.0:
		recoil_buffer = move_toward(recoil_buffer, 0.0, 0.9 * delta)
		
	# Apply rigid aim to Skeleton3D bones (rest quaternion multiplication for zero distortion)
	if skeleton:
		if turret_bone_idx >= 0:
			skeleton.set_bone_pose_rotation(turret_bone_idx, turret_rest_q * Quaternion(Vector3.UP, current_turret_yaw))
			skeleton.set_bone_pose_scale(turret_bone_idx, Vector3.ONE)
			
		if cannon_bone_idx >= 0:
			skeleton.set_bone_pose_rotation(cannon_bone_idx, cannon_rest_q * Quaternion(Vector3.RIGHT, current_cannon_pitch + recoil_pitch))
			skeleton.set_bone_pose_scale(cannon_bone_idx, Vector3.ONE)
			
		if recoil_bone_idx >= 0:
			skeleton.set_bone_pose_position(recoil_bone_idx, recoil_rest_pos + Vector3(0, -recoil_buffer, 0))
			
	# Update Muzzle position & rotation: exactly attached to the tip of the physical cannon barrel
	if muzzle:
		var local_fwd = Basis(Vector3.UP, current_turret_yaw) * Basis(Vector3.RIGHT, current_cannon_pitch + recoil_pitch) * Vector3(0, 0, -1)
		var world_fwd = global_basis * local_fwd
		var muzzle_dist = 2.60 - recoil_buffer
		muzzle.global_position = cannon_pivot + world_fwd * muzzle_dist
		if is_inside_tree():
			muzzle.look_at(cannon_pivot + world_fwd * (muzzle_dist + 10.0), Vector3.UP)

func play_footstep() -> void:
	if is_dead:
		return
	var player = footstep_audio_player if footstep_audio_player else audio_player
	if player:
		player.stream = ProceduralAudio.create_footstep_sound()
		player.play()

func shoot_cannon() -> void:
	reload_timer = cannon_cooldown
	recoil_pitch = deg_to_rad(4.5)
	recoil_buffer = 0.22
	
	# Camera recoil bump
	spring_arm.rotation.x -= deg_to_rad(1.2)
	if fps_camera:
		fps_camera.rotation.x = spring_arm.rotation.x
		
	var target_pos = get_aim_target()
	
	# Spawn Muzzle Flash
	if muzzle_flash_scene and muzzle:
		var flash = muzzle_flash_scene.instantiate() as Node3D
		add_child(flash)
		flash.global_transform = muzzle.global_transform
		
	# Play Procedural Cannon Boom
	if audio_player:
		audio_player.stream = ProceduralAudio.create_cannon_sound()
		audio_player.play()
		
	# Spawn 57mm Shell
	if cannon_shell_scene and muzzle:
		var shell = cannon_shell_scene.instantiate() as Area3D
		var spawn_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if spawn_root:
			spawn_root.add_child(shell)
		elif get_tree() and get_tree().root:
			get_tree().root.add_child(shell)
			
		shell.shooter_node = self
		shell.global_transform = muzzle.global_transform
		
	fired_cannon.emit()

func take_damage(amount: float, attacker: Node = null) -> void:
	if is_dead:
		return
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	if audio_player:
		audio_player.stream = ProceduralAudio.create_hit_sound()
		audio_player.play()
		
	if current_hp <= 0.0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	if anim_player:
		anim_player.play("Death", 0.2)
		
	var spawn_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
	if spawn_root:
		var exp_scene = load("res://scenes/explosion_vfx.tscn")
		if exp_scene:
			var exp_inst = exp_scene.instantiate() as Node3D
			spawn_root.add_child(exp_inst)
			exp_inst.global_position = global_position + Vector3(0, 1.2, 0)
			
		var smoke_scene = load("res://scenes/wreck_smoke_vfx.tscn")
		if smoke_scene:
			var smoke_inst = smoke_scene.instantiate() as Node3D
			add_child(smoke_inst)
			smoke_inst.position = Vector3(0, 0.6, 0)
			
	if audio_player:
		audio_player.stream = ProceduralAudio.create_catastrophic_sound()
		audio_player.play()
		
	died.emit()
