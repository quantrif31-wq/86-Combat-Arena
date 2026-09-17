extends Node3D
class_name DestructibleAmmoBox

const SFX_AMMO = preload("res://assets/audio/ammo_detonation.wav")
const EXPLOSION_VFX = preload("res://scenes/explosion_vfx.tscn")

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func setup_detonation(hit_pos: Vector3, box_tf: Transform3D) -> void:
	global_transform = box_tf
	
	audio_player.stream = SFX_AMMO
	audio_player.global_position = hit_pos
	audio_player.play()
	
	var vfx = EXPLOSION_VFX.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = hit_pos
	
	# Radial damage to nearby enemies and player
	var space = get_world_3d().direct_space_state
	for unit in get_tree().get_nodes_in_group("damageable"):
		if unit is CharacterBody3D:
			var d = unit.global_position.distance_to(hit_pos)
			if d < 6.5:
				var dmg = lerpf(45.0, 10.0, d / 6.5)
				unit.take_damage(dmg, self)
				
	await get_tree().create_timer(1.8).timeout
	queue_free()
