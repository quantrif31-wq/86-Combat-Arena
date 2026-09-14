extends SceneTree

var frame_count = 0
var main_scene = null
var player = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if player:
		player.update_animations(delta, 0.0, false)
		player.update_aim(delta)
		
	if frame_count == 25:
		if player:
			player.shoot_cannon()
			
	if frame_count == 26:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/cannon_fps_firing_view.png")
			print("Saved cannon_fps_firing_view.png")
		quit(0)
		return true
	return false
