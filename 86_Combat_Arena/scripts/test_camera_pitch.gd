extends SceneTree

func _init() -> void:
	var cam = Camera3D.new()
	# Initial forward: (0, 0, -1)
	print('Initial forward:', -cam.transform.basis.z)
	
	# Rotate X by -30 deg (negative)
	cam.rotation.x = deg_to_rad(-30.0)
	print('Negative rotation.x (-30 deg) forward:', -cam.transform.basis.z)
	
	# Rotate X by +30 deg (positive)
	cam.rotation.x = deg_to_rad(+30.0)
	print('Positive rotation.x (+30 deg) forward:', -cam.transform.basis.z)
	
	quit(0)
