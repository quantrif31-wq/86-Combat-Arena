extends CharacterBody3D
class_name EnemyJuggernaut

signal hp_changed(current_hp: float, max_hp: float)
signal enemy_died()

enum State { PATROL, ENGAGE, DEAD }

@export var max_hp: float = 120.0
@export var patrol_speed: float = 4.5
@export var combat_speed: float = 6.8
@export var turn_speed: float = 2.8
@export var fire_cooldown: float = 2.4
@export var attack_range: float = 60.0

var current_hp: float = 120.0
var current_state: State = State.PATROL
var fire_timer: float = 1.0
var strafe_timer: float = 0.0
var strafe_dir: float = 1.0
var target_player: Node3D = null

# Kinematics & Aim
var recoil_pitch: float = 0.0
var recoil_buffer: float = 0.0
var unstuck_timer: float = 0.0
var stuck_detector: float = 0.0
var unstuck_dir: Vector3 = Vector3.ZERO
var current_cannon_pitch: float = 0.0
var current_turret_yaw: float = 0.0
var prev_enemy_yaw: float = 0.0
var enemy_turn_rate: float = 0.0
var enemy_turn_latch: float = 0.0
var enemy_turn_dir: float = 0.0

var patrol_waypoints: Array[Vector3] = [
	Vector3(-12, 0, -18),
	Vector3(12, 0, -8),
	Vector3(0, 0, 8),
	Vector3(-10, 0, 4)
]
var current_waypoint_idx: int = 0

@onready var model_instance: Node3D = $ModelInstance
@onready var muzzle: Marker3D = $Muzzle
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var footstep_audio_player: AudioStreamPlayer3D = get_node_or_null("FootstepAudioPlayer3D")
var footstep_timer: float = 0.0

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

func _ready() -> void:
	current_hp = max_hp
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(60.0)
	floor_stop_on_slope = true
	safe_margin = 0.08
	prev_enemy_yaw = rotation.y
	hp_changed.emit(current_hp, max_hp)
	
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

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		move_and_slide()
		return
		
	# Find player if not assigned
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
			
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	match current_state:
		State.PATROL:
			process_patrol(delta)
		State.ENGAGE:
			process_engage(delta)

	move_and_slide()
	
	# Track angular yaw velocity (for stationary quadruped pivot turning)
	var cur_yaw = rotation.y
	var yaw_diff = wrapf(cur_yaw - prev_enemy_yaw, -PI, PI)
	prev_enemy_yaw = cur_yaw
	
	var raw_rate = yaw_diff / maxf(delta, 0.0001)
	enemy_turn_rate = lerpf(enemy_turn_rate, raw_rate, 12.0 * delta)
	if abs(yaw_diff) > 0.0015:
		enemy_turn_dir = signf(yaw_diff)
		enemy_turn_latch = 0.35
	elif enemy_turn_latch > 0.0:
		enemy_turn_latch -= delta

	# Update animations
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if anim_player:
		if h_speed > 0.4:
			var target_anim = "Run" if current_state == State.ENGAGE else "Walk"
			if anim_player.current_animation != target_anim:
				anim_player.play(target_anim, 0.2)
			anim_player.speed_scale = clampf(h_speed / (combat_speed if current_state == State.ENGAGE else patrol_speed), 0.5, 1.8)
			
			var step_interval = 0.32 if current_state == State.ENGAGE else 0.50
			footstep_timer -= delta * anim_player.speed_scale
			if footstep_timer <= 0.0:
				footstep_timer = step_interval
				play_footstep()
		else:
			var is_pivoting = (enemy_turn_latch > 0.0 or abs(enemy_turn_rate) > 0.15) and enemy_turn_dir != 0.0
			if is_pivoting:
				var target_anim = "Turn_Left" if enemy_turn_dir > 0.0 else "Turn_Right"
				if anim_player.current_animation != target_anim:
					anim_player.play(target_anim, 0.2)
				anim_player.speed_scale = clampf(abs(enemy_turn_rate) * 0.45, 0.8, 1.8)
				
				footstep_timer -= delta * anim_player.speed_scale
				if footstep_timer <= 0.0:
					footstep_timer = 0.38
					play_footstep()
			else:
				if anim_player.current_animation != "Idle":
					anim_player.play("Idle", 0.25)
				anim_player.speed_scale = 1.0
				footstep_timer = 0.0
			
	# Update 3D Aim & Cannon Bones
	update_ai_cannon_and_aim(delta)

func play_footstep() -> void:
	if current_state == State.DEAD:
		return
	var player = footstep_audio_player if footstep_audio_player else audio_player
	if player:
		player.stream = ProceduralAudio.create_footstep_sound()
		player.play()

func process_patrol(delta: float) -> void:
	# Check if player is in visual range
	if target_player and is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist < attack_range:
			current_state = State.ENGAGE
			return

	var target_wp = patrol_waypoints[current_waypoint_idx]
	var to_wp = target_wp - global_position
	to_wp.y = 0

	if to_wp.length() < 3.0:
		current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
		return

	var move_dir = apply_obstacle_avoidance(to_wp.normalized())
	rotate_toward_direction(move_dir, delta)
	velocity.x = move_dir.x * patrol_speed
	velocity.z = move_dir.z * patrol_speed

func process_engage(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0
	var dist = to_player.length()

	# Unstuck emergency maneuver
	if unstuck_timer > 0.0:
		unstuck_timer -= delta
		velocity.x = unstuck_dir.x * combat_speed * 0.85
		velocity.z = unstuck_dir.z * combat_speed * 0.85
		rotate_toward_direction(-unstuck_dir, delta)
		return

	# Face player generally
	rotate_toward_direction(to_player.normalized(), delta)

	# Tactical Movement: Maintain 18m - 28m distance while strafing
	var desired_move = Vector3.ZERO
	if dist > 26.0:
		desired_move += to_player.normalized()
	elif dist < 16.0:
		desired_move -= to_player.normalized()

	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = randf_range(2.0, 4.5)
		strafe_dir = -strafe_dir if randf() > 0.35 else strafe_dir

	var right_vec = to_player.normalized().cross(Vector3.UP)
	desired_move += right_vec * (strafe_dir * 0.75)
	desired_move = desired_move.normalized()

	var final_dir = apply_obstacle_avoidance(desired_move)

	# Stuck detector
	var cur_vel_h = Vector2(velocity.x, velocity.z).length()
	if final_dir.length_squared() > 0.1 and cur_vel_h < 0.35:
		stuck_detector += delta
		if stuck_detector > 0.45:
			stuck_detector = 0.0
			unstuck_timer = 0.8
			unstuck_dir = (-transform.basis.z * 0.7 + right_vec * -strafe_dir * 0.7).normalized()
			strafe_dir = -strafe_dir
	else:
		stuck_detector = maxf(0.0, stuck_detector - delta)

	velocity.x = final_dir.x * combat_speed
	velocity.z = final_dir.z * combat_speed

	# Line-of-sight check before firing
	fire_timer -= delta
	if fire_timer <= 0.0 and dist <= attack_range:
		var has_los = has_clear_line_of_sight()
		if has_los:
			fire_timer = fire_cooldown + randf_range(-0.3, 0.4)
			shoot_at_target(target_player.global_position + Vector3(0, 1.2, 0))
		else:
			# Blocked by concrete wall: flank to find open angle
			strafe_dir = -strafe_dir
			strafe_timer = 1.8
			fire_timer = 0.4

func has_clear_line_of_sight() -> bool:
	if not target_player or not is_instance_valid(target_player):
		return false
	var space = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.55, 0)
	var target_pos = target_player.global_position + Vector3(0, 1.2, 0)
	var query = PhysicsRayQueryParameters3D.create(origin, target_pos, 1 | 2)
	query.exclude = [self]
	var hit = space.intersect_ray(query)
	if hit:
		if hit.collider == target_player or hit.collider.is_in_group("player"):
			return true
		return false
	return true

func apply_obstacle_avoidance(desired_dir: Vector3) -> Vector3:
	var space = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 0.9, 0)
	var avoidance_vec = Vector3.ZERO
	
	var ray_configs = [
		{"angle": 0.0, "dist": 8.0, "weight": 2.2},
		{"angle": deg_to_rad(25.0), "dist": 6.0, "weight": 1.6},
		{"angle": deg_to_rad(-25.0), "dist": 6.0, "weight": 1.6},
		{"angle": deg_to_rad(50.0), "dist": 4.0, "weight": 1.1},
		{"angle": deg_to_rad(-50.0), "dist": 4.0, "weight": 1.1}
	]
	
	for rc in ray_configs:
		var ray_dir = desired_dir.rotated(Vector3.UP, rc["angle"])
		var end_pos = origin + ray_dir * rc["dist"]
		var query = PhysicsRayQueryParameters3D.create(origin, end_pos, 1)
		query.exclude = [self]
		if target_player:
			query.exclude.append(target_player)
		var hit = space.intersect_ray(query)
		if hit and hit.collider != target_player and not hit.collider.is_in_group("player"):
			var normal = hit.normal
			normal.y = 0
			var dist_factor = 1.0 - clampf(origin.distance_to(hit.position) / rc["dist"], 0.0, 1.0)
			avoidance_vec += (normal.normalized() + normal.cross(Vector3.UP) * 0.5) * (dist_factor * rc["weight"])
			
	if avoidance_vec.length_squared() > 0.01:
		return (desired_dir + avoidance_vec * 2.2).normalized()
	return desired_dir

func update_ai_cannon_and_aim(delta: float) -> void:
	var target_pos = global_position + (-global_transform.basis.z * 50.0)
	if target_player and is_instance_valid(target_player):
		target_pos = target_player.global_position + Vector3(0, 1.2, 0)
		
	var cannon_pivot = global_position + (global_transform.basis * Vector3(0, 1.8427, 0))
	var aim_dir = (target_pos - cannon_pivot).normalized()
	var local_aim = global_transform.basis.inverse() * aim_dir
	
	var target_pitch = clampf(atan2(local_aim.y, -local_aim.z), deg_to_rad(-12.0), deg_to_rad(35.0))
	var target_yaw = clampf(atan2(-local_aim.x, -local_aim.z), deg_to_rad(-35.0), deg_to_rad(35.0))
	
	current_cannon_pitch = lerpf(current_cannon_pitch, target_pitch, 8.0 * delta)
	current_turret_yaw = lerpf(current_turret_yaw, target_yaw, 8.0 * delta)
	
	if recoil_pitch > 0.0:
		recoil_pitch = move_toward(recoil_pitch, 0.0, 10.0 * delta)
	if recoil_buffer > 0.0:
		recoil_buffer = move_toward(recoil_buffer, 0.0, 0.7 * delta)
		
	if skeleton:
		if turret_bone_idx >= 0:
			skeleton.set_bone_pose_rotation(turret_bone_idx, turret_rest_q * Quaternion(Vector3.UP, current_turret_yaw))
		if cannon_bone_idx >= 0:
			skeleton.set_bone_pose_rotation(cannon_bone_idx, cannon_rest_q * Quaternion(Vector3.RIGHT, current_cannon_pitch + recoil_pitch))
		if recoil_bone_idx >= 0:
			skeleton.set_bone_pose_position(recoil_bone_idx, recoil_rest_pos + Vector3(0, -recoil_buffer, 0))
			
	if muzzle:
		var local_fwd = Basis(Vector3.UP, current_turret_yaw) * Basis(Vector3.RIGHT, current_cannon_pitch + recoil_pitch) * Vector3(0, 0, -1)
		var world_fwd = global_basis * local_fwd
		var muzzle_dist = 2.60 - recoil_buffer
		muzzle.global_position = cannon_pivot + world_fwd * muzzle_dist
		muzzle.look_at(cannon_pivot + world_fwd * (muzzle_dist + 10.0), Vector3.UP)

func rotate_toward_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

func shoot_at_target(aim_target: Vector3) -> void:
	recoil_pitch = deg_to_rad(4.0)
	recoil_buffer = 0.20
	
	if muzzle_flash_scene and muzzle:
		var flash = muzzle_flash_scene.instantiate() as Node3D
		add_child(flash)
		flash.global_transform = muzzle.global_transform
		
	if audio_player:
		audio_player.stream = ProceduralAudio.create_cannon_sound()
		audio_player.play()
		
	if cannon_shell_scene and muzzle:
		var shell = cannon_shell_scene.instantiate() as Area3D
		var spawn_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if spawn_root:
			spawn_root.add_child(shell)
		elif get_tree() and get_tree().root:
			get_tree().root.add_child(shell)
		shell.shooter_node = self
		shell.global_transform = muzzle.global_transform

func take_damage(amount: float, attacker: Node = null) -> void:
	if current_state == State.DEAD:
		return
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	if attacker and is_instance_valid(attacker):
		target_player = attacker
		current_state = State.ENGAGE
		
	if audio_player:
		audio_player.stream = ProceduralAudio.create_hit_sound()
		audio_player.play()
		
	if current_hp <= 0.0:
		die()

func die() -> void:
	current_state = State.DEAD
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
		
	enemy_died.emit()
