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
		
	# Consolidate 520 pine trees into 1 single MultiMeshInstance3D (1 draw call instead of 520!)
	_optimize_pine_trees_multimesh(target_root)
		
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if "pine" in cname:
			continue
			
		var geom = child as GeometryInstance3D
		
		# =====================================================================
		# 1. GRAPHICS & PERFORMANCE OPTIMIZATION PASS (LOD DISTANCE & SHADOWS)
		# =====================================================================
		if geom:
			# Small props (ammo crates, fences, road barriers): Cull beyond 180m, no distant shadows
			if "fence" in cname or "ammo" in cname or "barrier" in cname:
				geom.visibility_range_end = 180.0
				geom.visibility_range_end_margin = 25.0
				geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				
			# Medium props (fallen logs, rock piles, pipeline sections, boulders): Cull beyond 260m
			elif "log" in cname or "dead" in cname or "rock" in cname or "boulder" in cname or "pipe" in cname:
				geom.visibility_range_end = 260.0
				geom.visibility_range_end_margin = 30.0
				geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				
			# Major Architectural POIs (Citadel towers, factory, bridge, canyon cliffs, terrain):
			# Fully visible across all 800m with moonlight shadows
			else:
				geom.visibility_range_end = 0.0
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
		# =====================================================================
		# 2. PHYSICS COLLISION OPTIMIZATION PASS (LAYER 1, MASK 0 FOR ZERO CPU OVERHEAD)
		# =====================================================================
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
			
		# 6. Pine trees: Trunk cylinder collider
		elif "pine" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.65
			cyl.height = 24.0
			col.shape = cyl
			col.position = Vector3(0, 12.0, 0)
			body.add_child(col)
			child.add_child(body)
			
		# 7. Concrete Barriers
		elif "barrier" in cname:
			var body = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			body.collision_mask = 0
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
			c.collision_mask = 0

func _optimize_pine_trees_multimesh(target_root: Node3D) -> void:
	var pine_nodes: Array[MeshInstance3D] = []
	var shared_mesh: Mesh = null
	
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if "pine" in cname and child is MeshInstance3D:
			pine_nodes.append(child)
			if not shared_mesh and child.mesh:
				shared_mesh = child.mesh
				
	if pine_nodes.size() == 0 or not shared_mesh:
		return
		
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = shared_mesh
	mm.instance_count = pine_nodes.size()
	
	var compound_body = StaticBody3D.new()
	compound_body.collision_layer = 1
	compound_body.collision_mask = 0
	compound_body.name = "PineTrees_CompoundCollider"
	
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 0.65
	cyl_shape.height = 24.0
	
	for i in range(pine_nodes.size()):
		var p_node = pine_nodes[i]
		mm.set_instance_transform(i, p_node.transform)
		
		# Collision shape matching tree trunk
		var col = CollisionShape3D.new()
		col.shape = cyl_shape
		col.transform = Transform3D(p_node.transform.basis, p_node.transform.origin + Vector3(0, 12.0, 0))
		compound_body.add_child(col)
		
		# Free individual node
		p_node.queue_free()
		
	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = "TheGreatConiferForest_MultiMesh"
	mm_inst.multimesh = mm
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target_root.add_child(mm_inst)
	target_root.add_child(compound_body)
	print("OPTIMIZATION: Successfully consolidated ", pine_nodes.size(), " pine trees into 1 MultiMeshInstance3D!")
