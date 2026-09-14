extends Node3D

var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer > 0.15:
		queue_free()
