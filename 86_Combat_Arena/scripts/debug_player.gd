extends SceneTree

func _init() -> void:
	var arena = load('res://scenes/main_arena.tscn').instantiate()
	root.add_child(arena)
	var player = arena.get_node('PlayerJuggernaut')
	player._ready()
	print('Player skeleton after _ready():', player.skeleton)
	print('Player anim_player after _ready():', player.anim_player)
	if player.skeleton:
		print('Bone count:', player.skeleton.get_bone_count())
	quit(0)
