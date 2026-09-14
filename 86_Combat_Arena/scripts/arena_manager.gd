extends Node3D

@onready var player: CharacterBody3D = $PlayerJuggernaut
@onready var hud: Control = $CanvasLayer/CombatHUD
@onready var battlefield: Node3D = get_node_or_null("Sector86_Grand_Warzone") if has_node("Sector86_Grand_Warzone") else get_node_or_null("Sector86_Forest_Ruins")
@onready var props_root: Node3D = get_node_or_null("Props")
@onready var ambient_audio: AudioStreamPlayer = get_node_or_null("AmbientAudioPlayer")

var enemies: Array[CharacterBody3D] = []
var living_enemy_count: int = 0

func _ready() -> void:
	if battlefield == null:
		battlefield = get_node_or_null("Sector86_Grand_Warzone")
	if battlefield == null:
		battlefield = get_node_or_null("Sector86_Forest_Ruins")

	# Gather all enemy units
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is CharacterBody3D:
			enemies.append(node)
			node.enemy_died.connect(_on_any_enemy_died)
	
	living_enemy_count = enemies.size()

	if hud and player:
		hud.bind_player(player)
		if enemies.size() > 0:
			hud.bind_enemy(enemies[0])
			hud.set_all_enemies(enemies)
		
	# Setup ambient battlefield audio
	if ambient_audio:
		ambient_audio.stream = ProceduralAudio.create_ambient_wind_sound()
		ambient_audio.play()
		
	# Setup static collisions for all environment assets
	setup_battlefield_collisions()

func _on_any_enemy_died() -> void:
	living_enemy_count -= 1
	if living_enemy_count <= 0:
		if hud and hud.has_method("show_victory_banner"):
			hud.show_victory_banner()

func setup_battlefield_collisions() -> void:
	var target_root = battlefield if battlefield else props_root
	if not target_root:
		return
		
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		
		# 1. Terrain Mesh: Trimesh concave collision for authentic walking
		if "terrain" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# 2. Citadel Ruins & Ancient Fort: Trimesh concave collision for ramps, stairs, breached gates
		elif ("ruin" in cname or "fort" in cname) and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# 3. Factory Facades & Industrial Warehouses: Trimesh concave collision for door openings and walls
		elif "factory" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# 4. Viaduct Bridge & Pier Crossing: Trimesh concave collision for walkable deck and support pillars
		elif ("bridge" in cname or "pier" in cname) and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# 5. Cliff Faces & Rock Walls: Trimesh collision for canyon walls
		elif "cliff" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# 6. Pine trees: Trunk cylinder collider (prevents walking through, allows shooting past needles)
		elif "pine" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.65
			cyl.height = 24.0
			col.shape = cyl
			col.position = Vector3(0, 12.0, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 7. Concrete Barriers (LOD0 and Road barriers)
		elif "barrier" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.6, 1.4, 1.2)
			col.shape = box
			col.position = Vector3(0, 0.7, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 8. Perimeter Chainlink Fences
		elif "fence" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(4.2, 2.8, 0.4)
			col.shape = box
			col.position = Vector3(0, 1.4, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 9. Industrial Pipeline Networks
		elif "pipe" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.9
			cyl.height = 5.0
			col.shape = cyl
			col.position = Vector3(0, 0.9, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 10. Giant Boulders & Mossy Rocks
		elif "boulder" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var sphere = SphereShape3D.new()
			sphere.radius = 2.4
			col.shape = sphere
			col.position = Vector3(0, 1.2, 0)
			body.add_child(col)
			child.add_child(body)
			
		elif "rock" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var sphere = SphereShape3D.new()
			sphere.radius = 1.5
			col.shape = sphere
			col.position = Vector3(0, 0.8, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 11. Fallen Mossy Logs
		elif "log" in cname or "dead" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.4, 1.2, 7.0)
			col.shape = box
			col.position = Vector3(0, 0.6, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 12. Ammo Caches & Supply Crates
		elif "ammo" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.2, 0.7, 0.7)
			col.shape = box
			col.position = Vector3(0, 0.35, 0)
			body.add_child(col)
			child.add_child(body)

func _configure_static_body(parent_node: Node) -> void:
	for c in parent_node.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1
			c.collision_mask = 7
