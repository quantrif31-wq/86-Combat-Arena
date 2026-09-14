extends SceneTree

var frame_count = 0
var main_scene = null
var player = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	player = main_scene.get_node_or_null("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	# Frame 12: Trigger 57mm Cannon Fire
	if frame_count == 12:
		player.fire_cannon()
		
	# Frame 14: Projectile in mid-air with muzzle flash
	if frame_count == 14:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/forest_ruins_cannon_fire.png")
			print("Saved forest_ruins_cannon_fire.png")
		quit(0)
		return true
		
	return false
