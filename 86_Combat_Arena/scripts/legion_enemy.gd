extends CharacterBody3D
class_name LegionEnemy

signal hp_changed(current_hp: float, max_hp: float)
signal legion_died(unit: Node3D)
signal enemy_died()
signal shepherd_voice(text: String)

enum UnitType { AMEISE, GRAUWOLF, SHEPHERD }
enum State { ADVANCE, COMBAT, SIEGE_BASE, DEAD }

@export var unit_type: UnitType = UnitType.GRAUWOLF
@export var max_hp: float = 120.0
@export var combat_speed: float = 6.8
@export var fire_cooldown: float = 2.4
@export var attack_range: float = 140.0
@export var tactical_flank_dir: float = 0.0 # -1.0 for West flank, 0 for Center, 1.0 for East flank

var current_hp: float = 120.0
var current_state: State = State.ADVANCE
var is_dead: bool = false
var fire_timer: float = 1.0
var voice_timer: float = 5.0
var strafe_timer: float = 0.0
var strafe_dir: float = 1.0

var target_node: Node3D = null # Player, Ally, or BaseCore
var base_target_pos: Vector3 = Vector3(0, 0, 45) # Forward base location

var current_cannon_pitch: float = 0.0
var current_turret_yaw: float = 0.0
var recoil_pitch: float = 0.0
var recoil_buffer: float = 0.0
var prev_yaw: float = 0.0
var walk_phase: float = 0.0

@onready var model_instance: Node3D = $ModelInstance
@onready var muzzle: Marker3D = $Muzzle
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim_player: AnimationPlayer = null
@onready var skeleton: Skeleton3D = null
@onready var eye_light: OmniLight3D = get_node_or_null("SensorEyeLight")

var turret_bone_idx: int = -1
var cannon_bone_idx: int = -1
var recoil_bone_idx: int = -1
var turret_rest_q: Quaternion = Quaternion.IDENTITY
var cannon_rest_q: Quaternion = Quaternion.IDENTITY
var recoil_rest_pos: Vector3 = Vector3.ZERO

const MODEL_AMEISE = preload("res://assets/models/legion_ameise.glb")
const MODEL_GRAUWOLF = preload("res://assets/models/legion_grauwolf.glb")
const MODEL_SHEPHERD = preload("res://assets/models/legion_shepherd_dinosauria.glb")

const CANNON_SHELL_SCENE = preload("res://scenes/cannon_shell.tscn")
const MUZZLE_FLASH_SCENE = preload("res://scenes/muzzle_flash_vfx.tscn")
const EXPLOSION_VFX = preload("res://scenes/explosion_vfx.tscn")
const SMOKE_VFX = preload("res://scenes/wreck_smoke_vfx.tscn")

const SHEPHERD_WHISPERS = [
	"Undertaker... Tại sao ngươi lại từ chối cái chết?",
	"Mẹ ơi... ở đây lạnh quá... cứu con với...",
	"Gia nhập cùng chúng tôi... hỡi linh hồn không đầu...",
	"Tiêu diệt... quét sạch... toàn bộ rác rưởi 86...",
	"Ta tìm thấy ngươi rồi... Shin Nouzen..."
]

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	add_to_group("enemy")
	add_to_group("hostile")
	add_to_group("legion")
	add_to_group("damageable")
	
	# Configure type specific properties
	match unit_type:
		UnitType.AMEISE:
			max_hp = 85.0
			combat_speed = 8.5
			fire_cooldown = 1.8
			if eye_light:
				eye_light.light_color = Color(1.0, 0.4, 0.1)
				eye_light.light_energy = 2.5
		UnitType.GRAUWOLF:
			max_hp = 140.0
			combat_speed = 6.6
			fire_cooldown = 2.4
			if eye_light:
				eye_light.light_color = Color(1.0, 0.1, 0.1)
				eye_light.light_energy = 3.5
		UnitType.SHEPHERD:
			max_hp = 450.0
			combat_speed = 5.8
			fire_cooldown = 2.8
			scale = Vector3(1.35, 1.35, 1.35)
			if eye_light:
				eye_light.light_color = Color(1.0, 0.02, 0.05)
				eye_light.light_energy = 7.0
				eye_light.omni_range = 16.0
				
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	
	# Dynamic model instance replacement with authentic Legion GLBs
	if model_instance:
		model_instance.queue_free()
		
	var target_model_res: PackedScene = MODEL_GRAUWOLF
	match unit_type:
		UnitType.AMEISE:
			target_model_res = MODEL_AMEISE
			if muzzle:
				muzzle.position = Vector3(0, 1.25, -1.8)
		UnitType.GRAUWOLF:
			target_model_res = MODEL_GRAUWOLF
			if muzzle:
				muzzle.position = Vector3(0, 1.45, -2.1)
		UnitType.SHEPHERD:
			target_model_res = MODEL_SHEPHERD
			if muzzle:
				muzzle.position = Vector3(0, 2.35, -4.6)
				
	var new_model = target_model_res.instantiate()
	new_model.name = "ModelInstance"
	add_child(new_model)
	model_instance = new_model
	
	skeleton = model_instance.find_child("Skeleton3D", true, false)
	anim_player = model_instance.find_child("AnimationPlayer", true, false)
	
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
		anim_player.play("Run")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		move_and_slide()
		return
		
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0
		
	# Shepherd voice whispers
	if unit_type == UnitType.SHEPHERD:
		voice_timer -= delta
		if voice_timer <= 0.0:
			var whisper = SHEPHERD_WHISPERS[randi() % SHEPHERD_WHISPERS.size()]
			shepherd_voice.emit(whisper)
			voice_timer = randf_range(11.0, 16.0)
			
	_select_tactical_target()
	
	match current_state:
		State.ADVANCE:
			_process_advance(delta)
		State.COMBAT:
			_process_combat(delta)
		State.SIEGE_BASE:
			_process_siege_base(delta)
			
	move_and_slide()
	_update_turret_aim(delta)
	_update_animations(delta)

func _select_tactical_target() -> void:
	# Prioritize closest target among: Player, Allies, BaseCore
	var candidates: Array[Node3D] = []
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and not p.get("is_dead"):
			candidates.append(p)
	for a in get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(a) and not a.get("is_dead"):
			candidates.append(a)
	for b in get_tree().get_nodes_in_group("base_target"):
		if is_instance_valid(b) and not b.get("is_destroyed"):
			candidates.append(b)
			
	var closest_dist = attack_range * 1.5
	var best: Node3D = null
	for c in candidates:
		var d = global_position.distance_to(c.global_position)
		if d < closest_dist:
			closest_dist = d
			best = c
			
	target_node = best
	if target_node:
		if target_node.is_in_group("base_target"):
			current_state = State.SIEGE_BASE
		else:
			current_state = State.COMBAT
	else:
		current_state = State.ADVANCE

func _process_advance(delta: float) -> void:
	# Advance south towards Forward Base with flank deviation
	var flank_offset = Vector3(tactical_flank_dir * 30.0, 0, 0)
	var move_target = base_target_pos + flank_offset
	var to_target = move_target - global_position
	to_target.y = 0
	
	if to_target.length() > 20.0:
		var dir = to_target.normalized()
		var target_yaw = atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 3.0 * delta)
		velocity.x = dir.x * combat_speed
		velocity.z = dir.z * combat_speed
	else:
		current_state = State.SIEGE_BASE

func _process_combat(delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		current_state = State.ADVANCE
		return
		
	var to_tgt = target_node.global_position - global_position
	to_tgt.y = 0
	var dist = to_tgt.length()
	var desired_dir = to_tgt.normalized()
	
	var target_yaw = atan2(-desired_dir.x, -desired_dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 3.2 * delta)
	
	# Strafe behavior
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_dir = -strafe_dir if randf() < 0.65 else strafe_dir
		strafe_timer = randf_range(1.5, 3.0)
		
	var side_dir = desired_dir.cross(Vector3.UP) * strafe_dir
	
	if dist > 55.0:
		velocity.x = (desired_dir.x * 0.75 + side_dir.x * 0.45) * combat_speed
		velocity.z = (desired_dir.z * 0.75 + side_dir.z * 0.45) * combat_speed
	elif dist < 25.0:
		velocity.x = (-desired_dir.x * 0.8 + side_dir.x * 0.5) * combat_speed
		velocity.z = (-desired_dir.z * 0.8 + side_dir.z * 0.5) * combat_speed
	else:
		velocity.x = side_dir.x * (combat_speed * 0.85)
		velocity.z = side_dir.z * (combat_speed * 0.85)
		
	# Shooting logic
	fire_timer -= delta
	if fire_timer <= 0.0 and dist <= attack_range:
		_fire_salvo()
		fire_timer = fire_cooldown + randf_range(-0.25, 0.35)

func _process_siege_base(delta: float) -> void:
	var to_base = base_target_pos - global_position
	to_base.y = 0
	var dist = to_base.length()
	var dir = to_base.normalized()
	
	var target_yaw = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 3.0 * delta)
	
	if dist > 40.0:
		velocity.x = dir.x * combat_speed
		velocity.z = dir.z * combat_speed
	else:
		# In bombardment range of the base: fire continuously at BaseCore
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		
	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire_salvo()
		fire_timer = fire_cooldown + randf_range(-0.2, 0.3)

func _fire_salvo() -> void:
	if not muzzle:
		return
		
	if audio_player:
		audio_player.pitch_scale = randf_range(0.92, 1.06)
		audio_player.play()
		
	_spawn_shell()
	
	# Shepherd fires double burst
	if unit_type == UnitType.SHEPHERD:
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(self) and not is_dead:
			if audio_player:
				audio_player.play()
			_spawn_shell()

func _spawn_shell() -> void:
	var flash = MUZZLE_FLASH_SCENE.instantiate() as Node3D
	get_parent().add_child(flash)
	flash.global_position = muzzle.global_position
	flash.global_rotation = muzzle.global_rotation
	
	var shell = CANNON_SHELL_SCENE.instantiate() as Node3D
	get_parent().add_child(shell)
	shell.global_position = muzzle.global_position
	
	var fire_dir = -muzzle.global_transform.basis.z.normalized()
	if target_node and is_instance_valid(target_node):
		var aim_pt = target_node.global_position + Vector3(0, 1.2, 0)
		fire_dir = (aim_pt - muzzle.global_position).normalized()
	elif base_target_pos:
		fire_dir = ((base_target_pos + Vector3(0, 3, 0)) - muzzle.global_position).normalized()
		
	shell.set("direction", fire_dir)
	shell.set("shooter", self)
	recoil_buffer = 0.20

func _update_turret_aim(delta: float) -> void:
	if not skeleton or turret_bone_idx < 0 or current_state == State.DEAD:
		return
		
	var target_yaw = 0.0
	var target_pitch = 0.0
	var aim_world = target_node.global_position if (target_node and is_instance_valid(target_node)) else base_target_pos
	
	var local_tgt = to_local(aim_world)
	target_yaw = atan2(local_tgt.x, local_tgt.z)
	target_yaw = clampf(target_yaw, deg_to_rad(-80.0), deg_to_rad(80.0))
	
	var dist_h = Vector2(local_tgt.x, local_tgt.z).length()
	target_pitch = atan2(-local_tgt.y, dist_h)
	target_pitch = clampf(target_pitch, deg_to_rad(-16.0), deg_to_rad(28.0))
	
	current_turret_yaw = lerp_angle(current_turret_yaw, target_yaw, 4.5 * delta)
	current_cannon_pitch = lerp_angle(current_cannon_pitch, target_pitch, 4.5 * delta)
	
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
	if current_state == State.DEAD:
		return
	var h_speed = Vector2(velocity.x, velocity.z).length()
	
	# Procedural spider leg stepping kinematics
	if skeleton and h_speed > 0.3:
		walk_phase += delta * (combat_speed * 2.4)
		var leg_angle_1 = sin(walk_phase) * deg_to_rad(20.0)
		var leg_angle_2 = -sin(walk_phase) * deg_to_rad(20.0)
		
		# Group 1 legs
		for b_name in ["Leg_FL", "Leg_RR", "Leg_L1", "Leg_R2", "Leg_L3", "Leg_R4"]:
			var b = skeleton.find_bone(b_name)
			if b >= 0:
				var rest_q = skeleton.get_bone_rest(b).basis.get_rotation_quaternion()
				skeleton.set_bone_pose_rotation(b, rest_q * Quaternion(Vector3.RIGHT, leg_angle_1))
		# Group 2 legs
		for b_name in ["Leg_FR", "Leg_RL", "Leg_R1", "Leg_L2", "Leg_R3", "Leg_L4"]:
			var b = skeleton.find_bone(b_name)
			if b >= 0:
				var rest_q = skeleton.get_bone_rest(b).basis.get_rotation_quaternion()
				skeleton.set_bone_pose_rotation(b, rest_q * Quaternion(Vector3.RIGHT, leg_angle_2))
	
	# Animate Shepherd Neural Core pulsing
	if skeleton and unit_type == UnitType.SHEPHERD:
		var core_idx = skeleton.find_bone("Neural_Core")
		if core_idx >= 0:
			var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.12
			skeleton.set_bone_pose_scale(core_idx, Vector3(pulse, pulse, pulse))
			
	if anim_player:
		if h_speed > 0.3:
			if anim_player.current_animation != "Run":
				anim_player.play("Run", 0.2)
			anim_player.speed_scale = clampf(h_speed / combat_speed, 0.6, 1.7)
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle", 0.25)
			anim_player.speed_scale = 1.0

func take_damage(amount: float, attacker: Node = null) -> void:
	if is_dead:
		return
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0.0:
		die()

func take_hit(hit_pos: Vector3, dir: Vector3 = Vector3.ZERO) -> void:
	take_damage(40.0)

func is_dead_state() -> bool:
	return is_dead

func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	velocity = Vector3.ZERO
	
	if eye_light:
		eye_light.visible = false
		
	var vfx = EXPLOSION_VFX.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = global_position + Vector3(0, 1.2, 0)
	
	if unit_type == UnitType.SHEPHERD:
		vfx.scale = Vector3(2.5, 2.5, 2.5)
		shepherd_voice.emit("Undertaker... Ngươi cũng sẽ không thể thoát khỏi số phận này...")
		
	var smoke = SMOKE_VFX.instantiate() as Node3D
	add_child(smoke)
	smoke.position = Vector3(0, 1.0, 0)
	
	legion_died.emit(self)
	enemy_died.emit()
	print("[LegionEnemy] Unit %s destroyed!" % UnitType.keys()[unit_type])
