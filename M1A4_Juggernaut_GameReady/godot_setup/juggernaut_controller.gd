extends CharacterBody3D
class_name M1A4Juggernaut

## M1A4 Juggernaut Controller for Godot 4
## Integrates quadruped locomotion, 57mm cannon firing, and animation states.

@export var walk_speed: float = 6.0
@export var run_speed: float = 12.0
@export var rotation_speed: float = 2.5
@export var gravity: float = 9.8

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var armature: Node3D = $M1A4_Armature

enum State { IDLE, WALK, RUN, ATTACK, HIT, DEATH }
var current_state: State = State.IDLE
var is_locked_animation: bool = false

func _ready() -> void:
	if anim_player:
		if anim_player.has_animation(Idle):
			anim_player.get_animation(Idle).loop_mode = Animation.LOOP_LINEAR
		if anim_player.has_animation(Walk):
			anim_player.get_animation(Walk).loop_mode = Animation.LOOP_LINEAR
		if anim_player.has_animation(Run):
			anim_player.get_animation(Run).loop_mode = Animation.LOOP_LINEAR
		if anim_player.has_animation(Turn_Left):
			anim_player.get_animation(Turn_Left).loop_mode = Animation.LOOP_LINEAR
		if anim_player.has_animation(Turn_Right):
			anim_player.get_animation(Turn_Right).loop_mode = Animation.LOOP_LINEAR
		play_anim(Idle)

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(ui_accept) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		fire_cannon()

	if is_locked_animation:
		move_and_slide()
		return

	var input_dir := Input.get_vector(ui_left, ui_right, ui_up, ui_down)
	var is_running := Input.is_key_pressed(KEY_SHIFT)

	if input_dir.x != 0.0:
		rotate_y(-input_dir.x * rotation_speed * delta)

	var direction := (transform.basis * Vector3(0, 0, input_dir.y)).normalized()
	var target_speed := run_speed if is_running else walk_speed

	if direction.length() > 0.1:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
		if is_running:
			current_state = State.RUN
			play_anim(Run)
		else:
			current_state = State.WALK
			play_anim(Walk)
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed)
		velocity.z = move_toward(velocity.z, 0, target_speed)
		if input_dir.x < 0:
			play_anim(Turn_Left)
		elif input_dir.x > 0:
			play_anim(Turn_Right)
		else:
			current_state = State.IDLE
			play_anim(Idle)

	move_and_slide()

func fire_cannon() -> void:
	if is_locked_animation:
		return
	is_locked_animation = true
	current_state = State.ATTACK
	play_anim(Attack_Fire)
	await anim_player.animation_finished
	is_locked_animation = false
	current_state = State.IDLE
	play_anim(Idle)

func take_damage() -> void:
	if current_state == State.DEATH:
		return
	is_locked_animation = true
	current_state = State.HIT
	play_anim(Hit_React)
	await anim_player.animation_finished
	is_locked_animation = false
	play_anim(Idle)

func die() -> void:
	current_state = State.DEATH
	is_locked_animation = true
	play_anim(Death)

func play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name, 0.2)
