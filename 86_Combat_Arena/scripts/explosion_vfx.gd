extends Node3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
var timer: float = 0.0

func _ready() -> void:
	if audio:
		audio.stream = ProceduralAudio.create_explosion_sound()
		audio.play()

func _process(delta: float) -> void:
	timer += delta
	if light:
		light.light_energy = maxf(0.0, 6.0 * (1.0 - timer / 0.4))
	if timer > 1.2:
		queue_free()
