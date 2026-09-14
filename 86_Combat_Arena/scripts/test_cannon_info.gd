extends SceneTree

func _init():
	var res = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = res.instantiate()
	var cannon = inst.get_node("Cannon")
	print("Cannon position: ", cannon.position)
	print("Cannon rotation: ", cannon.rotation)
	quit(0)
