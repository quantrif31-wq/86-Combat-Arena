extends SceneTree

func _init() -> void:
	var packed = load("res://assets/models/m1a4_juggernaut_player.glb")
	var inst = packed.instantiate()
	root.add_child(inst)
	inst.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	
	var skel: Skeleton3D = inst.get_node("M1A4_Armature/Skeleton3D")
	var attach = BoneAttachment3D.new()
	attach.bone_name = "Cannon_Recoil"
	skel.add_child(attach)
	
	var muzzle = Marker3D.new()
	# In local space of attach, let's see where the barrel tip is
	attach.add_child(muzzle)
	muzzle.position = Vector3(0, 0, 2.5) # along barrel tip
	
	print('Attachment global position:', attach.global_position)
	print('Muzzle global position:', muzzle.global_position)
	
	quit(0)
