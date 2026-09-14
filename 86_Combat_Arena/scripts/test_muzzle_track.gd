extends SceneTree

func _init():
	var res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = res.instantiate()
	inst.rotation.y = -PI / 2.0
	var cannon = inst.get_node("Cannon")
	
	var muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(1.65, 0.0, 0.12)
	cannon.add_child(muzzle)
	
	print("Muzzle global pos at rest: ", muzzle.global_position)
	# Tilt cannon up 20 degrees:
	cannon.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(20.0))
	print("Muzzle global pos tilted 20 deg up: ", muzzle.global_position)
	# Tilt cannon down 10 degrees:
	cannon.rotation = Vector3.ZERO
	cannon.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(-10.0))
	print("Muzzle global pos tilted 10 deg down: ", muzzle.global_position)
	quit(0)
