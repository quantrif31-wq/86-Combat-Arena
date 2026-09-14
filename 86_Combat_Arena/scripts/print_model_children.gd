extends SceneTree

func _init() -> void:
	var arena = load('res://scenes/main_arena.tscn').instantiate()
	var player = arena.get_node('PlayerJuggernaut')
	var model = player.get_node('ModelInstance')
	print('ModelInstance children:')
	for c in model.get_children():
		print('  - ', c.name, ' (', c.get_class(), ')')
		for c2 in c.get_children():
			print('    -- ', c2.name, ' (', c2.get_class(), ')')
	quit(0)
