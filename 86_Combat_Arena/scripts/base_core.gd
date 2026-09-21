extends StaticBody3D
class_name BaseCore

signal base_damaged(current_hp: float, max_hp: float)
signal base_destroyed()

@export var max_hp: float = 1000.0
var current_hp: float = 1000.0
var is_destroyed: bool = false

var alarm_light: OmniLight3D = null
var smoke_vfx: Node3D = null
var fire_vfx: Node3D = null
var alarm_audio: AudioStreamPlayer3D = null

const EXPLOSION_VFX = preload("res://scenes/explosion_vfx.tscn")
const SMOKE_VFX = preload("res://scenes/wreck_smoke_vfx.tscn")

func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	add_to_group("damageable")
	add_to_group("base_target")
	current_hp = max_hp
	
	# Create flashing alarm beacon
	alarm_light = OmniLight3D.new()
	alarm_light.light_color = Color(1.0, 0.45, 0.1)
	alarm_light.light_energy = 0.0
	alarm_light.omni_range = 35.0
	alarm_light.position = Vector3(0, 14.0, 0)
	add_child(alarm_light)
	
	alarm_audio = AudioStreamPlayer3D.new()
	alarm_audio.unit_size = 25.0
	alarm_audio.max_distance = 250.0
	alarm_audio.volume_db = 0.0
	add_child(alarm_audio)

func _process(delta: float) -> void:
	if is_destroyed:
		return
		
	# Strobe alarm light if damaged below 70%
	if current_hp < max_hp * 0.70:
		var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		if alarm_light:
			alarm_light.light_energy = pulse * 4.0
	else:
		if alarm_light:
			alarm_light.light_energy = 0.5

func take_damage(dmg: float, _attacker: Node = null) -> void:
	if is_destroyed:
		return
		
	current_hp = maxf(0.0, current_hp - dmg)
	base_damaged.emit(current_hp, max_hp)
	
	# Spawn damage effects
	if current_hp <= max_hp * 0.5 and not smoke_vfx:
		smoke_vfx = SMOKE_VFX.instantiate()
		smoke_vfx.position = Vector3(0, 5.0, 0)
		add_child(smoke_vfx)
		
	if current_hp <= 0.0:
		is_destroyed = true
		_on_destroyed()

func take_hit(_hit_pos: Vector3, _dir: Vector3 = Vector3.ZERO) -> void:
	# Standard hit callback for cannon shells
	take_damage(50.0)

func _on_destroyed() -> void:
	var vfx = EXPLOSION_VFX.instantiate()
	get_parent().add_child(vfx)
	vfx.global_position = global_position + Vector3(0, 6.0, 0)
	base_destroyed.emit()
	print("[BaseCore] FORWARD BASE DESTROYED BY LEGION ASSAULT!")
