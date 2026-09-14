extends Node

func _ready() -> void:
	var arm = SpringArm3D.new()
	var cam = Camera3D.new()
	arm.add_child(cam)
	add_child(arm)
	
	arm.rotation.x = deg_to_rad(-25.0)
	print('Inside tree - Arm rot.x = -25 deg, cam forward:', -cam.global_transform.basis.z)
	
	arm.rotation.x = deg_to_rad(+25.0)
	print('Inside tree - Arm rot.x = +25 deg, cam forward:', -cam.global_transform.basis.z)
	
	get_tree().quit(0)
