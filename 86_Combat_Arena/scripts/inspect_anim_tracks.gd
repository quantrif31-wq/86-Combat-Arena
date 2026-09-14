extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_rigged.glb")
	var inst = packed.instantiate()
	var anim_player: AnimationPlayer = inst.get_node("AnimationPlayer")
	var anim = anim_player.get_animation("Walk")
	print('Track count in Walk:', anim.get_track_count())
	for i in range(anim.get_track_count()):
		print('  Track ', i, ': ', anim.track_get_path(i))
	quit(0)
