extends SceneTree

func _init() -> void:
	var arm = SpringArm3D.new()
	var cam = Camera3D.new()
	arm.add_child(cam)
	root.add_child(arm)
	
	arm.rotation.x = deg_to_rad(-25.0)
	print('Arm rot.x = -25 deg, cam forward:', -cam.global_transform.basis.z)
	
	arm.rotation.x = deg_to_rad(+25.0)
	print('Arm rot.x = +25 deg, cam forward:', -cam.global_transform.basis.z)
	
	quit(0)
