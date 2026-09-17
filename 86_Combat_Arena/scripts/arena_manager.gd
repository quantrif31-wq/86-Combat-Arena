extends Node3D

@onready var player: CharacterBody3D = $PlayerJuggernaut
@onready var hud: Control = $CanvasLayer/CombatHUD
@onready var battlefield: Node3D = get_node_or_null("Sector86_Grand_Warzone") if has_node("Sector86_Grand_Warzone") else get_node_or_null("Sector86_Forest_Ruins")
@onready var props_root: Node3D = get_node_or_null("Props")
@onready var ambient_audio: AudioStreamPlayer = get_node_or_null("AmbientAudioPlayer")

var enemies: Array[CharacterBody3D] = []
var living_enemy_count: int = 0

# MultiMesh & Destructibles Registry
const DESTRUCTIBLE_TREE_SCENE = preload("res://scenes/destructible_tree.tscn")
const DESTRUCTIBLE_BARRIER_SCENE = preload("res://scenes/destructible_barrier.tscn")
const DESTRUCTIBLE_AMMO_SCENE = preload("res://scenes/destructible_ammo_box.tscn")


var pine_multimesh_inst: MultiMeshInstance3D = null
var pine_transforms: Array[Transform3D] = []
var pine_active: Array[bool] = []
var pine_shared_mesh: Mesh = null
var pine_bark_tex: Texture2D = null
var pine_needle_tex: Texture2D = null

var barrier_multimesh_inst: MultiMeshInstance3D = null
var barrier_transforms: Array[Transform3D] = []
var barrier_active: Array[bool] = []

var ammo_transforms: Array[Transform3D] = []
var ammo_active: Array[bool] = []
var ammo_nodes: Array[Node3D] = []

static func get_ground_elevation(x: float, z: float) -> float:
	var y = -z
	var n1 = sin(x * 0.015) * cos(y * 0.015) * 3.5
	var n2 = sin(x * 0.035 + 1.1) * sin(y * 0.035 + 0.7) * 2.0
	var elev = n1 + n2

	var dy = y - (-80.0)
	if absf(dy) < 35.0:
		var factor = 1.0 - (absf(dy) / 35.0)
		elev -= factor * factor * 5.8

	var dist_cit = sqrt(x * x + (y - 140.0) * (y - 140.0))
	if dist_cit < 95.0:
		var c_factor = 1.0 - (dist_cit / 95.0)
		elev += c_factor * 5.2

	var dist_fac = sqrt((x + 220.0) * (x + 220.0) + y * y)
	if dist_fac < 85.0:
		var f_factor = 1.0 - (dist_fac / 85.0)
		elev += f_factor * 2.5

	var dist_out = sqrt((x - 220.0) * (x - 220.0) + (y - 20.0) * (y - 20.0))
	if dist_out < 80.0:
		var o_factor = 1.0 - (dist_out / 80.0)
		elev += o_factor * 3.0

	var r = sqrt(x * x + y * y)
	if r > 300.0:
		var rim_t = minf(1.0, (r - 300.0) / 90.0)
		elev += rim_t * rim_t * 32.0

	return elev

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
		
	# Setup terrain snapping & collisions for all environment assets
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
		
	# =========================================================================
	# PASS 1: TERRAIN SNAPPING (ELIMINATE ALL FLOATING OBJECTS ON THE MAP)
	# =========================================================================
	_snap_all_props_to_terrain(target_root)
		
	# =========================================================================
	# PASS 2: OPTIMIZED MULTIMESH CONSOLIDATION & INTERACTIVE COLLISION SETUP
	# =========================================================================
	# 1. Consolidate 487 pine trees into 1 MultiMesh with breakable physics
	_optimize_pine_trees_multimesh(target_root)
	
	# 2. Consolidate 48 boulders into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "boulder", "Boulders_MultiMesh", "Boulders_CompoundCollider", "sphere", Vector3(2.2, 0, 0))
	
	# 3. Consolidate 40 fallen logs into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "fallen", "FallenLogs_MultiMesh", "FallenLogs_CompoundCollider", "box", Vector3(1.4, 1.2, 7.0))
	
	# 4. Consolidate 8 concrete barriers into 1 MultiMesh with destructible physics
	_optimize_barriers_multimesh(target_root)
	
	# 5. Consolidate 9 perimeter fences into 1 MultiMeshInstance3D
	_optimize_props_into_multimesh(target_root, "fence", "Fences_MultiMesh", "Fences_CompoundCollider", "box", Vector3(4.2, 2.8, 0.4))
		
	# =========================================================================
	# PASS 3: ARCHITECTURAL & ENVIRONMENT COLLISION & LOD SETUP
	# =========================================================================
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if child.is_queued_for_deletion() or "pine" in cname or "boulder" in cname or "fallen" in cname or "barrier" in cname or "fence" in cname or "multimesh" in cname or "compoundcollider" in cname or "colliders" in cname:
			continue
			
		var geom = child as GeometryInstance3D
		if geom:
			if "ammo" in cname:
				geom.visibility_range_end = 180.0
				geom.visibility_range_end_margin = 25.0
				geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			elif "rock" in cname or "pipe" in cname:
				geom.visibility_range_end = 260.0
				geom.visibility_range_end_margin = 30.0
				geom.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				geom.visibility_range_end = 0.0
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
		# Terrain Mesh
		if "terrain" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# Citadel Ruins
		elif ("ruin" in cname or "fort" in cname) and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# Factory Warehouses
		elif "factory" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# Viaduct Bridge
		elif ("bridge" in cname or "pier" in cname) and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# Cliff Faces
		elif "cliff" in cname and child is MeshInstance3D:
			child.create_trimesh_collision()
			_configure_static_body(child)
			
		# Pipeline Networks
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
			
		# Ammo Caches & Supply Crates (Interactive Destructibles)
		elif "ammo" in cname:
			_setup_destructible_ammo_box(child)

func _snap_all_props_to_terrain(target_root: Node3D) -> void:
	var snapped_count = 0
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if "terrain" in cname or "bridge" in cname:
			continue
			
		var pos = child.transform.origin
		var ground_y = get_ground_elevation(pos.x, pos.z)
		var sink = 0.0
		if "pine" in cname:
			sink = 0.08
		elif "boulder" in cname:
			sink = 0.35
		elif "fallen" in cname:
			sink = 0.10
		elif "barrier" in cname:
			sink = 0.05
		elif "fence" in cname:
			sink = 0.05
		elif "ammo" in cname:
			sink = -0.02
		elif "pipe" in cname:
			sink = -0.06
		elif "ruin" in cname or "fort" in cname:
			sink = 0.25
		elif "factory" in cname:
			sink = 0.25
		elif "cliff" in cname:
			sink = 0.40
			
		child.transform.origin.y = ground_y - sink
		snapped_count += 1
	print("TERRAIN SNAPPING: Successfully snapped ", snapped_count, " props firmly into ground terrain!")

# =========================================================================
# DESTRUCTIBLE PINE TREES SYSTEM
# =========================================================================
func _optimize_pine_trees_multimesh(target_root: Node3D) -> void:
	var pine_nodes: Array[MeshInstance3D] = []
	pine_shared_mesh = null
	
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if "pine" in cname and child is MeshInstance3D and not child.is_queued_for_deletion():
			pine_nodes.append(child)
			if not pine_shared_mesh and child.mesh:
				pine_shared_mesh = child.mesh
				var m = child.mesh
				if m.get_surface_count() > 0:
					var mat0 = m.surface_get_material(0) as StandardMaterial3D
					if mat0:
						pine_bark_tex = mat0.albedo_texture
				if m.get_surface_count() > 1:
					var mat1 = m.surface_get_material(1) as StandardMaterial3D
					if mat1:
						pine_needle_tex = mat1.albedo_texture
						
	if pine_nodes.size() == 0 or not pine_shared_mesh:
		return
		
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = pine_shared_mesh
	mm.instance_count = pine_nodes.size()
	
	pine_transforms.clear()
	pine_active.clear()
	
	var collider_holder = Node3D.new()
	collider_holder.name = "PineTrees_DestructibleColliders"
	target_root.add_child(collider_holder)
	
	for i in range(pine_nodes.size()):
		var p_node = pine_nodes[i]
		mm.set_instance_transform(i, p_node.transform)
		pine_transforms.append(p_node.transform)
		pine_active.append(true)
		
		# Individual StaticBody3D with take_hit callback
		var s_body = StaticBody3D.new()
		s_body.name = "TreeAnchor_%d" % i
		s_body.collision_layer = 1 | 4
		s_body.collision_mask = 0
		
		var scale_y = p_node.transform.basis.get_scale().y
		var scale_x = p_node.transform.basis.get_scale().x
		var tree_h = 75.0 * scale_y
		
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 0.65 * scale_x
		cyl.height = tree_h
		col.shape = cyl
		col.position = Vector3(0, tree_h * 0.5, 0)
		s_body.add_child(col)
		s_body.global_transform = Transform3D(p_node.transform.basis, p_node.transform.origin)
		
		# Store tree metadata on static body script
		s_body.set_script(preload("res://scripts/destructible_tree_anchor.gd"))
		s_body.set("tree_idx", i)
		s_body.set("arena_manager_ref", self)
		
		collider_holder.add_child(s_body)
		p_node.queue_free()
		
	pine_multimesh_inst = MultiMeshInstance3D.new()
	pine_multimesh_inst.name = "TheGreatConiferForest_MultiMesh"
	pine_multimesh_inst.multimesh = mm
	pine_multimesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target_root.add_child(pine_multimesh_inst)
	print("OPTIMIZATION & DESTRUCTION: Configured ", pine_nodes.size(), " pine trees with dynamic breakable physics!")

func shatter_tree(idx: int, hit_pos: Vector3, impact_dir: Vector3) -> void:
	if idx < 0 or idx >= pine_transforms.size() or not pine_active[idx]:
		return
	pine_active[idx] = false
	
	# Hide instance from MultiMesh
	var hidden_tf = Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -999, 0))
	pine_multimesh_inst.multimesh.set_instance_transform(idx, hidden_tf)
	
	# Spawn dynamic destructible tree
	var tree_tf = pine_transforms[idx]
	var d_tree = DESTRUCTIBLE_TREE_SCENE.instantiate()
	var spawn_root = battlefield if battlefield else self
	spawn_root.add_child(d_tree)
	d_tree.setup_shatter(hit_pos, impact_dir, tree_tf, pine_shared_mesh, pine_bark_tex, pine_needle_tex)

# =========================================================================
# DESTRUCTIBLE ROAD BARRIERS SYSTEM
# =========================================================================
func _optimize_barriers_multimesh(target_root: Node3D) -> void:
	var barrier_nodes: Array[MeshInstance3D] = []
	var shared_mesh: Mesh = null
	
	for child in target_root.get_children():
		var cname = child.name.to_lower()
		if "barrier" in cname and child is MeshInstance3D and not child.is_queued_for_deletion():
			barrier_nodes.append(child)
			if not shared_mesh and child.mesh:
				shared_mesh = child.mesh
				
	if barrier_nodes.size() == 0 or not shared_mesh:
		return
		
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = shared_mesh
	mm.instance_count = barrier_nodes.size()
	
	barrier_transforms.clear()
	barrier_active.clear()
	
	var col_holder = Node3D.new()
	col_holder.name = "Barriers_DestructibleColliders"
	target_root.add_child(col_holder)
	
	for i in range(barrier_nodes.size()):
		var b_node = barrier_nodes[i]
		mm.set_instance_transform(i, b_node.transform)
		barrier_transforms.append(b_node.transform)
		barrier_active.append(true)
		
		var s_body = StaticBody3D.new()
		s_body.name = "BarrierAnchor_%d" % i
		s_body.collision_layer = 1 | 4
		s_body.collision_mask = 0
		
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(3.6, 1.4, 1.2)
		col.shape = box
		col.position = Vector3(0, 0.7, 0)
		s_body.add_child(col)
		s_body.global_transform = Transform3D(b_node.transform.basis, b_node.transform.origin)
		
		s_body.set_script(preload("res://scripts/destructible_prop_anchor.gd"))
		s_body.set("prop_type", "barrier")
		s_body.set("prop_idx", i)
		s_body.set("arena_manager_ref", self)
		
		col_holder.add_child(s_body)
		b_node.queue_free()
		
	barrier_multimesh_inst = MultiMeshInstance3D.new()
	barrier_multimesh_inst.name = "Barriers_MultiMesh"
	barrier_multimesh_inst.multimesh = mm
	barrier_multimesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target_root.add_child(barrier_multimesh_inst)
	print("OPTIMIZATION & DESTRUCTION: Configured ", barrier_nodes.size(), " concrete road barriers!")

func shatter_barrier(idx: int, hit_pos: Vector3, impact_dir: Vector3) -> void:
	if idx < 0 or idx >= barrier_transforms.size() or not barrier_active[idx]:
		return
	barrier_active[idx] = false
	
	var hidden_tf = Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -999, 0))
	barrier_multimesh_inst.multimesh.set_instance_transform(idx, hidden_tf)
	
	var b_tf = barrier_transforms[idx]
	var d_barr = DESTRUCTIBLE_BARRIER_SCENE.instantiate()
	var spawn_root = battlefield if battlefield else self
	spawn_root.add_child(d_barr)
	d_barr.setup_shatter(hit_pos, impact_dir, b_tf)

# =========================================================================
# DESTRUCTIBLE AMMO CRATES SYSTEM
# =========================================================================
func _setup_destructible_ammo_box(child: Node3D) -> void:
	var idx = ammo_nodes.size()
	ammo_nodes.append(child)
	ammo_transforms.append(child.transform)
	ammo_active.append(true)
	
	var body = StaticBody3D.new()
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.2, 1.4, 2.2)
	col.shape = box
	col.position = Vector3(0, 0.7, 0)
	body.add_child(col)
	
	body.set_script(preload("res://scripts/destructible_prop_anchor.gd"))
	body.set("prop_type", "ammo")
	body.set("prop_idx", idx)
	body.set("arena_manager_ref", self)
	
	child.add_child(body)

func detonate_ammo(idx: int, hit_pos: Vector3) -> void:
	if idx < 0 or idx >= ammo_nodes.size() or not ammo_active[idx]:
		return
	ammo_active[idx] = false
	
	var node = ammo_nodes[idx]
	var b_tf = ammo_transforms[idx]
	if is_instance_valid(node):
		node.visible = false
		node.queue_free()
		
	var d_ammo = DESTRUCTIBLE_AMMO_SCENE.instantiate()
	var spawn_root = battlefield if battlefield else self
	spawn_root.add_child(d_ammo)
	d_ammo.setup_detonation(hit_pos, b_tf)

# =========================================================================
# GENERIC MULTIMESH CONSOLIDATION HELPER
# =========================================================================
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

func _configure_static_body(mesh_node: Node) -> void:
	for c in mesh_node.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1
			c.collision_mask = 0
