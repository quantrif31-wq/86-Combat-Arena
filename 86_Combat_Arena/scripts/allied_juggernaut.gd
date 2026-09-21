extends CharacterBody3D
class_name AlliedJuggernaut

signal hp_changed(callsign: String, current_hp: float, max_hp: float)
signal ally_died(callsign: String)
signal radio_chatter_sent(speaker: String, text: String, urgent: bool)

enum State { GUARD, ENGAGE, DEAD }

@export var callsign: String = "WEHRWOLF"
@export var pilot_name: String = "Raiden Shuga"
@export var max_hp: float = 140.0
@export var combat_speed: float = 7.0
@export var fire_cooldown: float = 2.5
@export var attack_range: float = 135.0
@export var guard_radius: float = 35.0
@export var base_guard_pos: Vector3 = Vector3(0, 0, 35)

var current_hp: float = 140.0
var current_state: State = State.GUARD
var is_dead: bool = false
var fire_timer: float = 1.0
var target_enemy: Node3D = null

# Kinematics & Bones
var current_cannon_pitch: float = 0.0
var current_turret_yaw: float = 0.0
var recoil_pitch: float = 0.0
var recoil_buffer: float = 0.0
var prev_yaw: float = 0.0
var turn_rate: float = 0.0

@onready var model_instance: Node3D = $ModelInstance
@onready var muzzle: Marker3D = $Muzzle
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim_player: AnimationPlayer = get_node_or_null("ModelInstance/AnimationPlayer")
@onready var skeleton: Skeleton3D = get_node_or_null("ModelInstance/M1A4_Armature/Skeleton3D")

var turret_bone_idx: int = -1
var cannon_bone_idx: int = -1
var recoil_bone_idx: int = -1
var turret_rest_q: Quaternion = Quaternion.IDENTITY
var cannon_rest_q: Quaternion = Quaternion.IDENTITY
var recoil_rest_pos: Vector3 = Vector3.ZERO

const CANNON_SHELL_SCENE = preload("res://scenes/cannon_shell.tscn")
const MUZZLE_FLASH_SCENE = preload("res://scenes/muzzle_flash_vfx.tscn")
const EXPLOSION_VFX = preload("res://scenes/explosion_vfx.tscn")
const SMOKE_VFX = preload("res://scenes/wreck_smoke_vfx.tscn")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 3
	add_to_group("allies")
	add_to_group("damageable")
	add_to_group("allied_target")
	
	current_hp = max_hp
	hp_changed.emit(callsign, current_hp, max_hp)
	
	if audio_player:
		audio_player.stream = ProceduralAudio.create_cannon_sound()
		
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
		for a in ["Walk", "Run", "Idle", "Turn_Left", "Turn_Right"]:
			if anim_player.has_animation(a):
				anim_player.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		move_and_slide()
		return
		
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0
		
	# Target search: find closest living hostile legion
	_update_target()
	
	match current_state:
		State.GUARD:
			_process_guard(delta)
		State.ENGAGE:
			_process_engage(delta)
			
	move_and_slide()
	_update_turret_aim(delta)
	_update_animations(delta)

func _update_target() -> void:
	if target_enemy and is_instance_valid(target_enemy):
		if target_enemy.has_method("is_dead_state") and target_enemy.is_dead_state():
			target_enemy = null
		elif global_position.distance_to(target_enemy.global_position) > attack_range * 1.2:
			target_enemy = null
			
	if not target_enemy:
		var enemies = get_tree().get_nodes_in_group("hostile")
		var closest_dist = attack_range
		var best_cand: Node3D = null
		for e in enemies:
			if is_instance_valid(e):
				if e.has_method("is_dead_state") and e.is_dead_state():
					continue
				var d = global_position.distance_to(e.global_position)
				if d < closest_dist:
					closest_dist = d
					best_cand = e
		target_enemy = best_cand
		if target_enemy:
			current_state = State.ENGAGE
		else:
			current_state = State.GUARD

func _process_guard(delta: float) -> void:
	# Return / patrol around guard post
	var to_guard = base_guard_pos - global_position
	to_guard.y = 0
	if to_guard.length() > 6.0:
		var move_dir = to_guard.normalized()
		var target_yaw = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 3.0 * delta)
		velocity.x = move_dir.x * (combat_speed * 0.5)
		velocity.z = move_dir.z * (combat_speed * 0.5)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

func _process_engage(delta: float) -> void:
	if not target_enemy or not is_instance_valid(target_enemy):
		current_state = State.GUARD
		return
		
	var to_target = target_enemy.global_position - global_position
	to_target.y = 0
	var dist = to_target.length()
	var desired_dir = to_target.normalized()
	
	# Turn towards enemy or maintain tactical distance (25m - 55m)
	var target_yaw = atan2(-desired_dir.x, -desired_dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 3.5 * delta)
	
	if dist > 45.0:
		velocity.x = desired_dir.x * combat_speed
		velocity.z = desired_dir.z * combat_speed
	elif dist < 22.0:
		# Back up slightly
		velocity.x = -desired_dir.x * (combat_speed * 0.7)
		velocity.z = -desired_dir.z * (combat_speed * 0.7)
	else:
		# Strafe left/right
		var side = desired_dir.cross(Vector3.UP).normalized()
		velocity.x = side.x * (combat_speed * 0.6)
		velocity.z = side.z * (combat_speed * 0.6)
		
	# Shooting logic
	fire_timer -= delta
	if fire_timer <= 0.0 and dist <= attack_range:
		_fire_cannon()
		fire_timer = fire_cooldown + randf_range(-0.3, 0.4)

func _fire_cannon() -> void:
	if not muzzle:
		return
		
	if audio_player:
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()
		
	# Muzzle Flash VFX
	var flash = MUZZLE_FLASH_SCENE.instantiate() as Node3D
	get_parent().add_child(flash)
	flash.global_position = muzzle.global_position
	flash.global_rotation = muzzle.global_rotation
	
	# Launch 57mm Shell towards target
	var shell = CANNON_SHELL_SCENE.instantiate() as Node3D
	get_parent().add_child(shell)
	shell.global_position = muzzle.global_position
	
	var fire_dir = -muzzle.global_transform.basis.z.normalized()
	if target_enemy and is_instance_valid(target_enemy):
		var aim_pt = target_enemy.global_position + Vector3(0, 1.2, 0)
		var lead_offset = Vector3.ZERO
		if target_enemy is CharacterBody3D:
			var t_vel = target_enemy.velocity
			var flight_time = muzzle.global_position.distance_to(aim_pt) / 380.0
			lead_offset = t_vel * flight_time
		fire_dir = ((aim_pt + lead_offset) - muzzle.global_position).normalized()
		
	shell.set("direction", fire_dir)
	shell.set("shooter", self)
	
	# Recoil animation
	recoil_buffer = 0.18

func _update_turret_aim(delta: float) -> void:
	if not skeleton or turret_bone_idx < 0:
		return
		
	var target_yaw = 0.0
	var target_pitch = 0.0
	if target_enemy and is_instance_valid(target_enemy) and current_state != State.DEAD:
		var local_target = to_local(target_enemy.global_position)
		target_yaw = atan2(local_target.x, local_target.z)
		target_yaw = clampf(target_yaw, deg_to_rad(-85.0), deg_to_rad(85.0))
		
		var dist_h = Vector2(local_target.x, local_target.z).length()
		target_pitch = atan2(-local_target.y, dist_h)
		target_pitch = clampf(target_pitch, deg_to_rad(-18.0), deg_to_rad(30.0))
		
	current_turret_yaw = lerp_angle(current_turret_yaw, target_yaw, 5.0 * delta)
	current_cannon_pitch = lerp_angle(current_cannon_pitch, target_pitch, 5.0 * delta)
	
	# Apply to bones
	var q_turret = Quaternion(Vector3.UP, current_turret_yaw)
	skeleton.set_bone_pose_rotation(turret_bone_idx, turret_rest_q * q_turret)
	
	if cannon_bone_idx >= 0:
		var q_cannon = Quaternion(Vector3.RIGHT, -current_cannon_pitch)
		skeleton.set_bone_pose_rotation(cannon_bone_idx, cannon_rest_q * q_cannon)
		
	if recoil_bone_idx >= 0:
		if recoil_buffer > 0.0:
			recoil_buffer -= delta
			skeleton.set_bone_pose_position(recoil_bone_idx, recoil_rest_pos + Vector3(0, 0, 0.45))
		else:
			skeleton.set_bone_pose_position(recoil_bone_idx, recoil_rest_pos)

func _update_animations(delta: float) -> void:
	if not anim_player or current_state == State.DEAD:
		return
		
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if h_speed > 0.4:
		var anim = "Run" if current_state == State.ENGAGE else "Walk"
		if anim_player.current_animation != anim:
			anim_player.play(anim, 0.2)
		anim_player.speed_scale = clampf(h_speed / combat_speed, 0.5, 1.6)
	else:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle", 0.25)
		anim_player.speed_scale = 1.0

func take_damage(amount: float, attacker: Node = null) -> void:
	if is_dead:
		return
		
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(callsign, current_hp, max_hp)
	
	# Send chatter if critically damaged
	if current_hp < max_hp * 0.35 and current_hp > 0.0:
		radio_chatter_sent.emit(callsign, "Armor integrity compromised! Undertaker, watch your back!", true)
		
	if current_hp <= 0.0:
		die()

func take_hit(hit_pos: Vector3, dir: Vector3 = Vector3.ZERO) -> void:
	take_damage(35.0)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	velocity = Vector3.ZERO
	
	var vfx = EXPLOSION_VFX.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = global_position + Vector3(0, 1.2, 0)
	
	var smoke = SMOKE_VFX.instantiate() as Node3D
	add_child(smoke)
	smoke.position = Vector3(0, 1.0, 0)
	
	radio_chatter_sent.emit(callsign, "Signal lost... Undertaker... keep moving forward...", true)
	ally_died.emit(callsign)
	print("[AlliedJuggernaut] %s KIA in Sector 86!" % callsign)
