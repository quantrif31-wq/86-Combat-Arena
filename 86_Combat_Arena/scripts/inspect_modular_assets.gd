extends SceneTree

func _init() -> void:
	print("--- INSPECTING MODULAR ASSETS ---")
	var paths = [
		"res://assets/environment/models/modular_fort_01/modular_fort_01_1k.gltf"
	]
	for p in paths:
		var scene = load(p) as PackedScene
		if scene:
			var inst = scene.instantiate()
			print("\nAsset: ", p.get_file())
			for c in inst.get_children():
				print("  - ", c.name, " (", c.get_class(), ")")
			inst.queue_free()
	quit(0)
