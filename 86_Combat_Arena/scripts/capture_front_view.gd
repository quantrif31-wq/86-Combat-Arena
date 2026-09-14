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
		
	if frame_count == 15:
		if player:
			var rmb = InputEventMouseButton.new()
			rmb.button_index = MOUSE_BUTTON_RIGHT
			rmb.pressed = true
			player._input(rmb)
			# Orbit to front-quarter view (approx 135 degrees) to see the barrel length and muzzle clearly
			var motion = InputEventMouseMotion.new()
			motion.relative = Vector2(820, -30)
			player._input(motion)
			
	if frame_count == 28:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/cannon_barrel_front_view.png")
			print("Saved cannon_barrel_front_view.png")
			
		if player:
			player.shoot_cannon()
			
	if frame_count == 30:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/cannon_firing_front_view.png")
			print("Saved cannon_firing_front_view.png")
		quit(0)
		return true
	return false
