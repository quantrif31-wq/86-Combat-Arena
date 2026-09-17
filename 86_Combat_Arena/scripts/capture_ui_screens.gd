extends SceneTree

func _init() -> void:
	print("--- Capturing Modal Screenshots ---")
	call_deferred("_start_capture")

func _start_capture() -> void:
	var root_viewport = root
	
	# 1. Capture Briefing Modal
	var title_scene = load("res://scenes/title_screen.tscn").instantiate()
	root_viewport.add_child(title_scene)
	
	var curtain = title_scene.get_node_or_null("FadeCurtain")
	if curtain:
		curtain.visible = false
		
	var overlay = title_scene.get_node_or_null("ModalOverlay")
	var briefing = title_scene.get_node_or_null("ModalOverlay/ModalBriefing")
	if overlay and briefing:
		overlay.visible = true
		briefing.visible = true
		
	for i in range(10):
		await process_frame
		
	var tex = root_viewport.get_texture()
	var img = tex.get_image()
	if img:
		img.save_png("C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5/preview_briefing_modal.png")
		print("SUCCESS: Captured preview_briefing_modal.png")
		
	title_scene.queue_free()
	quit(0)
