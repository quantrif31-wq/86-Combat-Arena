extends Node3D
class_name WreckSmokeVFX

@onready var fire_light: OmniLight3D = get_node_or_null("FireLight")
var flicker_timer: float = 0.0

func _process(delta: float) -> void:
	flicker_timer += delta * 12.0
	if fire_light:
		fire_light.light_energy = 2.4 + sin(flicker_timer) * 0.6 + cos(flicker_timer * 1.7) * 0.4
