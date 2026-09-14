extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var enemy = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	player = main_scene.get_node_or_null("PlayerJuggernaut")
	enemy = main_scene.get_node_or_null("EnemyJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	# Frame 10: Player fires cannon in FPS mode
	if frame_count == 10:
		print("Firing in FPS mode...")
		player.shoot_cannon()
		
	# Frame 12: Capture muzzle flash and projectile flight right after firing
	if frame_count == 12:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/fps_cannon_firing_test.png")
			print("SAVED FIRING: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/fps_cannon_firing_test.png")
		quit(0)
		return true
		
	return false
