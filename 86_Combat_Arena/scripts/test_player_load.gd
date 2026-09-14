extends SceneTree

func _init() -> void:
	var player_scene = load("res://scenes/player_juggernaut.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	print('Player instantiated successfully!')
	quit(0)
