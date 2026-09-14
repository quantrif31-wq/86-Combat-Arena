extends SceneTree

var frame_count = 0
var main_scene = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	
	var player = main_scene.get_node("PlayerJuggernaut")
	if player:
		# Force ADS aiming
		player.is_aiming = true
		player.camera.fov = 30.0

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 20:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(r"C:\Users\suhai\.gemini\antigravity\brain\4fd43609-ab4a-4a88-ad46-78e442aada1b\combat_arena_ads_scope.png")
		quit(0)
		return true
	return false
