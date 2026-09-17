@tool
extends SceneTree

func _init() -> void:
	print("--- Processing UI Assets for 86 Combat Arena ---")
	var brain_dir = "C:/Users/suhai/.gemini/antigravity/brain/948eace8-5344-40e2-a688-527a51c5a7a5/"
	
	DirAccess.make_dir_recursive_absolute("c:/86/86_Combat_Arena/assets/ui")
	
	# 1. Title Screen Art
	var title_img = Image.load_from_file(brain_dir + "title_art_86_wide_1789660563457.jpg")
	if title_img:
		title_img.save_png("c:/86/86_Combat_Arena/assets/ui/title_art_86_wide.png")
		print("Saved title_art_86_wide.png (", title_img.get_width(), "x", title_img.get_height(), ")")
		
	# 2. Loading Screen Art
	var loading_img = Image.load_from_file(brain_dir + "loading_art_pararaid_1789660580051.jpg")
	if loading_img:
		loading_img.save_png("c:/86/86_Combat_Arena/assets/ui/loading_art_pararaid.png")
		print("Saved loading_art_pararaid.png (", loading_img.get_width(), "x", loading_img.get_height(), ")")
		
	# 3. Spider Lily Petal (make black transparent)
	var petal_img = Image.load_from_file(brain_dir + "spider_lily_petal_1789660595884.jpg")
	if petal_img:
		petal_img.convert(Image.FORMAT_RGBA8)
		var w = petal_img.get_width()
		var h = petal_img.get_height()
		for y in range(h):
			for x in range(w):
				var col = petal_img.get_pixel(x, y)
				var brightness = max(col.r, max(col.g, col.b))
				if brightness < 0.08:
					petal_img.set_pixel(x, y, Color(0, 0, 0, 0))
				elif brightness < 0.25:
					var alpha = (brightness - 0.08) / 0.17
					petal_img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
		petal_img.save_png("c:/86/86_Combat_Arena/assets/ui/spider_lily_petal.png")
		print("Saved spider_lily_petal.png with alpha cutout")
		
	# 4. Undertaker Emblem (make white transparent, keep black emblem / make it white-with-alpha)
	var emblem_img = Image.load_from_file(brain_dir + "undertaker_emblem_1789660620952.jpg")
	if emblem_img:
		emblem_img.convert(Image.FORMAT_RGBA8)
		var w = emblem_img.get_width()
		var h = emblem_img.get_height()
		for y in range(h):
			for x in range(w):
				var col = emblem_img.get_pixel(x, y)
				var darkness = 1.0 - (col.r * 0.299 + col.g * 0.587 + col.b * 0.114)
				if darkness < 0.2:
					emblem_img.set_pixel(x, y, Color(0, 0, 0, 0))
				else:
					var a = clampf((darkness - 0.2) / 0.3, 0.0, 1.0)
					emblem_img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
		emblem_img.save_png("c:/86/86_Combat_Arena/assets/ui/undertaker_emblem.png")
		print("Saved undertaker_emblem.png as transparent white stencil")
		
	print("Asset processing complete.")
	quit()
