extends Node3D

@onready var player: CharacterBody3D = $PlayerJuggernaut
@onready var enemy: CharacterBody3D = $EnemyJuggernaut
@onready var hud: Control = $CanvasLayer/CombatHUD
@onready var battlefield: Node3D = get_node_or_null("Sector86_Forest_Ruins")
@onready var props_root: Node3D = get_node_or_null("Props")
@onready var ambient_audio: AudioStreamPlayer = get_node_or_null("AmbientAudioPlayer")

func _ready() -> void:
	if hud and player:
		hud.bind_player(player)
	if hud and enemy:
		hud.bind_enemy(enemy)
		
	# Setup ambient battlefield audio
	if ambient_audio:
		ambient_audio.stream = ProceduralAudio.create_ambient_wind_sound()
		ambient_audio.play()
		
	# Setup static collisions for all environment assets
	setup_battlefield_collisions()

func setup_battlefield_collisions() -> void:
	var target_root = battlefield if battlefield else props_root
	if not target_root:
		return
		
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		
		# Terrain: Trimesh collision
		if "terrain" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
		# Citadel ruins: Trimesh concave collision for ramps, stairs, breached gates
		elif "ruin" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
		# Pine trees: Trunk cylinder collider (prevents walking through, allows shooting past foliage)
		elif "pine" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.55
			cyl.height = 16.0
			col.shape = cyl
			col.position = Vector3(0, 8.0, 0)
			body.add_child(col)
			child.add_child(body)
		# Concrete barriers
		elif "barrier" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.2, 1.2, 0.9)
			col.shape = box
			col.position = Vector3(0, 0.6, 0)
			body.add_child(col)
			child.add_child(body)
		# Fallen mossy logs
		elif "log" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.2, 1.0, 6.0)
			col.shape = box
			col.position = Vector3(0, 0.5, 0)
			body.add_child(col)
			child.add_child(body)
		# Mossy boulders
		elif "rock" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var sphere = SphereShape3D.new()
			sphere.radius = 1.4
			col.shape = sphere
			col.position = Vector3(0, 0.8, 0)
			body.add_child(col)
			child.add_child(body)
		# Legacy fallbacks
		elif "wall" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(5.2, 3.6, 1.2)
			col.shape = box
			col.position = Vector3(0, 1.8, 0)
			body.add_child(col)
			child.add_child(body)
		elif "hedgehog" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.6, 1.6, 1.6)
			col.shape = box
			col.position = Vector3(0, 0.8, 0)
			body.add_child(col)
			child.add_child(body)
		elif "crate" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.4, 1.2, 1.4)
			col.shape = box
			col.position = Vector3(0, 0.6, 0)
			body.add_child(col)
			child.add_child(body)

func _configure_static_body(parent_node: Node) -> void:
	for c in parent_node.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1
			c.collision_mask = 7
