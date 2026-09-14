extends SceneTree

var frame_count = 0
var main_scene = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 25:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			var err = img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\combat_arena_gameplay.png")
			print("Screenshot save result: ", err)
		quit(0)
		return true
	return false
