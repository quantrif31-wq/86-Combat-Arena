extends SceneTree

func _init() -> void:
	var path = "res://../M1A4_Juggernaut_GameReady/models/m1a4_juggernaut_animated.glb"
	# Or let's load it if it's imported
	print("Checking animated GLB...")
	var scene = load("res://assets/models/m1a4_juggernaut_player.glb")
	print("Player GLB: ", scene)
	quit(0)
