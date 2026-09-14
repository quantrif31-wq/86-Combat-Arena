extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_enemy.glb")
	var inst = packed.instantiate()
	print('=== IMPORTED ENEMY SCENE ===')
	var anim: AnimationPlayer = inst.get_node("AnimationPlayer")
	print('ANIMATIONS:', anim.get_animation_list())
	quit(0)
