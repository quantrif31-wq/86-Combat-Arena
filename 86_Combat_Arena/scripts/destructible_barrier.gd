extends Node3D
class_name DestructibleBarrier

const SFX_SHATTER = preload("res://assets/audio/concrete_shatter.wav")

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var dust_particles: CPUParticles3D = $DustParticles
@onready var chunk1: RigidBody3D = $Chunk1
@onready var chunk2: RigidBody3D = $Chunk2
@onready var chunk3: RigidBody3D = $Chunk3

func setup_shatter(hit_pos: Vector3, impact_dir: Vector3, barrier_tf: Transform3D) -> void:
	global_transform = barrier_tf
	
	audio_player.stream = SFX_SHATTER
	audio_player.global_position = hit_pos
	audio_player.pitch_scale = randf_range(0.95, 1.05)
	audio_player.play()
	
	dust_particles.global_position = hit_pos
	dust_particles.emitting = true
	
	var push = impact_dir.normalized()
	if push.length_squared() < 0.01:
		push = -Vector3.FORWARD
		
	var chunks = [chunk1, chunk2, chunk3]
	for idx in range(chunks.size()):
		var c = chunks[idx]
		if c:
			var rand_spread = Vector3(randf_range(-0.4, 0.4), randf_range(0.2, 0.6), randf_range(-0.4, 0.4))
			c.linear_velocity = (push + rand_spread) * randf_range(4.0, 8.5)
			c.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
			
	await get_tree().create_timer(3.0).timeout
	for c in chunks:
		if c:
			c.freeze = true
			c.collision_layer = 1
			c.collision_mask = 0
