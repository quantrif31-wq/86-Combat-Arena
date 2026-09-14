extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	for name in anim.get_animation_list():
		var a = anim.get_animation(name)
		print(name, ' -> length: ', a.length, ', loop_mode: ', a.loop_mode)
	quit(0)
