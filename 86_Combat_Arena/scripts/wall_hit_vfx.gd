extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	if audio_player:
		audio_player.stream = ProceduralAudio.create_wall_hit_sound()
		audio_player.play()
	if particles:
		particles.emitting = true
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(queue_free)

