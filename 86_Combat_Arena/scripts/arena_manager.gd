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
		
	# 1. Consolidate 487 pine trees into 1 MultiMeshInstance3D (1 draw call)
	_optimize_pine_trees_multimesh(target_root)
	
	# 2. Consolidate 48 boulders into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "boulder", "Boulders_MultiMesh", "Boulders_CompoundCollider", "sphere", Vector3(2.2, 0, 0))
	
	# 3. Consolidate 40 fallen logs into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "fallen", "FallenLogs_MultiMesh", "FallenLogs_CompoundCollider", "box", Vector3(1.4, 1.2, 7.0))
	
	# 4. Consolidate 8 concrete barriers into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "barrier", "Barriers_MultiMesh", "Barriers_CompoundCollider", "box", Vector3(3.6, 1.4, 1.2))
	
	# 5. Consolidate 9 perimeter fences into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "fence", "Fences_MultiMesh", "Fences_CompoundCollider", "box", Vector3(4.2, 2.8, 0.4))
		
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if child.is_queued_for_deletion() or "pine" in cname or "boulder" in cname or "fallen" in cname or "barrier" in cname or "fence" in cname or "multimesh" in cname or "compoundcollider" in cname:
			continue
			
		var geom = child as GeometryInstance3D
		
		# =====================================================================
		# 1. GRAPHICS & PERFORMANCE OPTIMIZATION PASS (LOD DISTANCE & SHADOWS)
		# =====================================================================
		if geom:
			# Small props (ammo crates): Cull beyond 180m, no distant shadows
			if "ammo" in cname:
				geom.visibility_range_end = 180.0
				geom.visibility_range_end_margin = 25.0
				geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				
			# Medium props (rock piles, pipeline sections): Cull beyond 260m
			elif "rock" in cname or "pipe" in cname:
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
			
		# 6. Industrial Pipeline Networks
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
			
		# 7. Ammo Caches & Supply Crates
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
		if "pine" in cname and child is MeshInstance3D and not child.is_queued_for_deletion():
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
	cyl_shape.radius = 0.55
	cyl_shape.height = 4.0
	
	for i in range(pine_nodes.size()):
		var p_node = pine_nodes[i]
		mm.set_instance_transform(i, p_node.transform)
		
		var col = CollisionShape3D.new()
		col.shape = cyl_shape
		col.transform = Transform3D(Basis(), Vector3(p_node.transform.origin.x, p_node.transform.origin.y + 2.0, p_node.transform.origin.z))
		compound_body.add_child(col)
		
		p_node.queue_free()
		
	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = "TheGreatConiferForest_MultiMesh"
	mm_inst.multimesh = mm
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target_root.add_child(mm_inst)
	target_root.add_child(compound_body)
	print("OPTIMIZATION: Successfully consolidated ", pine_nodes.size(), " pine trees into 1 MultiMeshInstance3D!")

func _optimize_props_into_multimesh(target_root: Node3D, name_filter: String, multimesh_name: String, collider_name: String, shape_type: String, shape_dims: Vector3) -> void:
	var nodes: Array[MeshInstance3D] = []
	var shared_mesh: Mesh = null
	
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if name_filter in cname and child is MeshInstance3D and not child.is_queued_for_deletion():
			nodes.append(child)
			if not shared_mesh and child.mesh:
				shared_mesh = child.mesh
				
	if nodes.size() == 0 or not shared_mesh:
		return
		
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = shared_mesh
	mm.instance_count = nodes.size()
	
	var compound_body = StaticBody3D.new()
	compound_body.collision_layer = 1
	compound_body.collision_mask = 0
	compound_body.name = collider_name
	
	var shape_res: Shape3D = null
	if shape_type == "sphere":
		var s = SphereShape3D.new()
		s.radius = shape_dims.x
		shape_res = s
	elif shape_type == "box":
		var b = BoxShape3D.new()
		b.size = shape_dims
		shape_res = b
		
	for i in range(nodes.size()):
		var n = nodes[i]
		mm.set_instance_transform(i, n.transform)
		
		if shape_res:
			var col = CollisionShape3D.new()
			col.shape = shape_res
			col.transform = n.transform
			compound_body.add_child(col)
			
		n.queue_free()
		
	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = multimesh_name
	mm_inst.multimesh = mm
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target_root.add_child(mm_inst)
	target_root.add_child(compound_body)
	print("OPTIMIZATION: Successfully consolidated ", nodes.size(), " ", name_filter, " props into ", multimesh_name, "!")
