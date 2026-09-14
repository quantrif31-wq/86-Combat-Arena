extends SceneTree

var frame_count = 0
var main_scene = null
var player = null
var cam_front = null
var cam_cockpit = null

func _init():
	var res = load("res://scenes/main_arena.tscn")
	main_scene = res.instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	player = main_scene.get_node_or_null("PlayerJuggernaut")

func _process(delta: float) -> bool:
	frame_count += 1
	if not player:
		return false
		
	if frame_count == 5:
		# Force model to be visible
		player.model_instance.visible = true
		
		# Hide the 2D HUD so we see the raw 3D mecha clearly
		var hud = main_scene.get_node_or_null("CanvasLayer/CombatHUD")
		if hud:
			hud.visible = false
			
		# Camera 1: Looking at the front of the Juggernaut from 4m away
		cam_front = Camera3D.new()
		cam_front.name = "CamFront"
		main_scene.add_child(cam_front)
		cam_front.global_position = player.global_position + Vector3(0, 1.8, -4.5)
		cam_front.look_at(player.global_position + Vector3(0, 1.2, 0), Vector3.UP)
		cam_front.current = true
		
	if frame_count == 10:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/juggernaut_front_inspect.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/juggernaut_front_inspect.png")
			
		# Camera 2: Placed at the cockpit canopy looking forward
		cam_front.current = false
		cam_cockpit = Camera3D.new()
		cam_cockpit.name = "CamCockpit"
		main_scene.add_child(cam_cockpit)
		cam_cockpit.global_position = player.global_position + Vector3(0, 1.35, -0.4)
		cam_cockpit.look_at(player.global_position + Vector3(0, 1.0, -10.0), Vector3.UP)
		cam_cockpit.current = true
		
	if frame_count == 15:
		var img = root.get_viewport().get_texture().get_image()
		if img:
			img.save_png("C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/juggernaut_cockpit_pos_inspect.png")
			print("SAVED: C:/Users/suhai/.gemini/antigravity/brain/4fd43609-ab4a-4a88-ad46-78e442aada1b/juggernaut_cockpit_pos_inspect.png")
		quit(0)
		return true
		
	return false
