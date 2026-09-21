extends Node
class_name BaseAndVillageBuilder

const FORT_SCENE = preload("res://assets/environment/models/modular_fort_01/modular_fort_01_1k.gltf")
const FACTORY_SCENE = preload("res://assets/environment/models/modular_factory_facade/modular_factory_facade_1k.gltf")
const FENCE_SCENE = preload("res://assets/environment/models/modular_chainlink_fence/modular_chainlink_fence_1k.gltf")
const PIER_SCENE = preload("res://assets/environment/models/modular_wooden_pier/modular_wooden_pier_1k.gltf")

const BaseCoreScript = preload("res://scripts/base_core.gd")
const ArenaManagerScript = preload("res://scripts/arena_manager.gd")

const HEDGEHOG_SCENE = preload("res://assets/models/prop_czech_hedgehog.glb")
const BARRIER_SCENE = preload("res://assets/models/prop_concrete_barrier.glb")
const AMMO_SCENE = preload("res://scenes/destructible_ammo_box.tscn")

# Cache extracted meshes from GLTF scenes
static var _fort_cache: Dictionary = {}
static var _factory_cache: Dictionary = {}
static var _fence_cache: Dictionary = {}
static var _pier_cache: Dictionary = {}

static func _init_cache() -> void:
	if _fort_cache.is_empty():
		_extract_meshes(FORT_SCENE.instantiate(), _fort_cache)
	if _factory_cache.is_empty():
		_extract_meshes(FACTORY_SCENE.instantiate(), _factory_cache)
	if _fence_cache.is_empty():
		_extract_meshes(FENCE_SCENE.instantiate(), _fence_cache)
	if _pier_cache.is_empty():
		_extract_meshes(PIER_SCENE.instantiate(), _pier_cache)

static func _extract_meshes(root_node: Node, target_dict: Dictionary) -> void:
	for child in root_node.get_children():
		if child is MeshInstance3D and child.mesh:
			target_dict[child.name] = child.mesh
	root_node.queue_free()

static func build_base_and_village(parent_node: Node3D) -> Node3D:
	_init_cache()
	
	var base_root = Node3D.new()
	base_root.name = "ForwardBase_SpearheadOutpost"
	parent_node.add_child(base_root)
	
	var village_root = Node3D.new()
	village_root.name = "RearCivilianVillage_District86"
	parent_node.add_child(village_root)
	
	var base_core = _build_forward_base(base_root)
	_build_rear_village(village_root)
	
	return base_core

# =============================================================================
# 1. FORWARD OPERATING BASE (TIỀN ĐỒN CĂN CỨ SPEARHEAD SQUADRON)
# Center: Z = 45, X = 0
# =============================================================================
static func _build_forward_base(root: Node3D) -> Node3D:
	var base_core = BaseCoreScript.new()
	base_core.name = "BaseCore_CommandPost"
	root.add_child(base_core)
	
	var center_x = 0.0
	var center_z = 45.0
	var gy = ArenaManagerScript.get_ground_elevation(center_x, center_z)
	base_core.position = Vector3(center_x, gy, center_z)
	
	# Command Core Collider
	var core_col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(18.0, 14.0, 18.0)
	core_col.shape = box
	core_col.position = Vector3(0, 7.0, 0)
	base_core.add_child(core_col)
	
	# 1. Central Radar Tower & Command Bunker
	var tower_mesh = _fort_cache.get("modular_fort_01_tower_round")
	if tower_mesh:
		var tower_inst = MeshInstance3D.new()
		tower_inst.mesh = tower_mesh
		tower_inst.scale = Vector3(2.2, 2.6, 2.2)
		base_core.add_child(tower_inst)
		
		# Radar Antenna on top
		var ant_pole = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.22
		cyl.height = 6.5
		ant_pole.mesh = cyl
		ant_pole.position = Vector3(0, 16.5, 0)
		base_core.add_child(ant_pole)
		
		var ant_dish = MeshInstance3D.new()
		var dish_mesh = SphereMesh.new()
		dish_mesh.radius = 1.4
		dish_mesh.height = 0.4
		ant_dish.mesh = dish_mesh
		ant_dish.position = Vector3(0, 19.5, 0)
		ant_dish.rotation_degrees = Vector3(30.0, 45.0, 0.0)
		base_core.add_child(ant_dish)
		
		# Pulsing radar beacon light
		var beacon = OmniLight3D.new()
		beacon.light_color = Color(0.2, 0.85, 1.0)
		beacon.light_energy = 2.5
		beacon.omni_range = 40.0
		beacon.position = Vector3(0, 20.0, 0)
		base_core.add_child(beacon)

	# 2. Left & Right Fortified Walls
	var wall_mesh = _fort_cache.get("modular_fort_01_wall_thick_straight_01")
	if wall_mesh:
		# Left Wall Rampart
		_spawn_static_fort_prop(root, wall_mesh, Vector3(-16.0, 0, 38.0), Vector3(0, 20, 0), Vector3(1.8, 1.8, 1.8))
		_spawn_static_fort_prop(root, wall_mesh, Vector3(-28.0, 0, 44.0), Vector3(0, 45, 0), Vector3(1.8, 1.8, 1.8))
		# Right Wall Rampart
		_spawn_static_fort_prop(root, wall_mesh, Vector3(16.0, 0, 38.0), Vector3(0, -20, 0), Vector3(1.8, 1.8, 1.8))
		_spawn_static_fort_prop(root, wall_mesh, Vector3(28.0, 0, 44.0), Vector3(0, -45, 0), Vector3(1.8, 1.8, 1.8))

	# 3. Base Front Gate
	var gate_mesh = _fort_cache.get("modular_fort_01_wall_thin_gate_01")
	if gate_mesh:
		_spawn_static_fort_prop(root, gate_mesh, Vector3(0.0, 0, 26.0), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))

	# 4. Anti-Tank Defense Line (Czech Hedgehogs)
	# Staggered in front of the gate at Z = 14 to 18
	var hedgehog_coords = [
		Vector3(-14, 0, 14), Vector3(-8, 0, 16), Vector3(-2, 0, 14),
		Vector3(4, 0, 17), Vector3(10, 0, 15), Vector3(16, 0, 17),
		Vector3(-22, 0, 19), Vector3(22, 0, 19)
	]
	for c in hedgehog_coords:
		var py = ArenaManagerScript.get_ground_elevation(c.x, c.z)
		var hg = HEDGEHOG_SCENE.instantiate() as Node3D
		root.add_child(hg)
		hg.global_position = Vector3(c.x, py + 0.1, c.z)
		hg.rotation_degrees.y = randf_range(0, 360)
		hg.scale = Vector3(1.4, 1.4, 1.4)
		_add_static_box_collider(hg, Vector3(2.4, 2.0, 2.4), Vector3(0, 1.0, 0))

	# 5. Concrete Road Barriers (Defensive Choke Points)
	var barrier_coords = [
		Vector3(-9.0, 0, 22.0), Vector3(9.0, 0, 22.0),
		Vector3(-18.0, 0, 27.0), Vector3(18.0, 0, 27.0)
	]
	for bpos in barrier_coords:
		var by = ArenaManagerScript.get_ground_elevation(bpos.x, bpos.z)
		var barr = BARRIER_SCENE.instantiate() as Node3D
		root.add_child(barr)
		barr.global_position = Vector3(bpos.x, by, bpos.z)
		barr.scale = Vector3(1.6, 1.6, 1.6)
		_add_static_box_collider(barr, Vector3(3.2, 1.6, 1.2), Vector3(0, 0.8, 0))

	# 6. Supply Ammo Crates Inside Base Courtyard
	var ammo_coords = [
		Vector3(-6.0, 0, 48.0), Vector3(6.0, 0, 48.0),
		Vector3(-12.0, 0, 52.0), Vector3(12.0, 0, 52.0)
	]
	for apos in ammo_coords:
		var ay = ArenaManagerScript.get_ground_elevation(apos.x, apos.z)
		var ammo = AMMO_SCENE.instantiate() as Node3D
		root.add_child(ammo)
		ammo.global_position = Vector3(apos.x, ay + 0.05, apos.z)

	# 7. Perimeter Security Wire Fence (Flanks)
	var fence_mesh = _fence_cache.get("modular_chainlink_fence")
	if fence_mesh:
		# West flank
		for i in range(5):
			var fz = 32.0 + i * 6.5
			var fx = -36.0
			_spawn_static_fort_prop(root, fence_mesh, Vector3(fx, 0, fz), Vector3(0, 90, 0), Vector3(1.6, 1.6, 1.6))
		# East flank
		for i in range(5):
			var fz = 32.0 + i * 6.5
			var fx = 36.0
			_spawn_static_fort_prop(root, fence_mesh, Vector3(fx, 0, fz), Vector3(0, 90, 0), Vector3(1.6, 1.6, 1.6))

	print("BASE BUILDER: Forward Operating Base constructed with Command Bunker, Radar, Barriers, and Czech Hedgehogs!")
	return base_core

# =============================================================================
# 2. REAR ABANDONED VILLAGE (NGÔI LÀNG BỎ HOANG PHÍA SAU)
# Region: Z = 120 to 240, X = -80 to 80
# =============================================================================
static func _build_rear_village(root: Node3D) -> void:
	var wall_brick = _factory_cache.get("wall_standard_standard_01")
	var wall_window = _factory_cache.get("wall_window_centered_large_01")
	var wall_door = _factory_cache.get("wall_door_centered_large_01")
	var roof_trim = _factory_cache.get("cornice01_standard_standard_01")
	
	var plank_mesh = _pier_cache.get("modular_wooden_pier_planks")
	var pole_mesh = _pier_cache.get("modular_wooden_pier_poles")

	# Village Houses Layout (6 residential and farm buildings)
	var houses = [
		{"pos": Vector3(-35.0, 0, 135.0), "rot": 15.0, "type": "large"},   # Building 1: Village Townhall / Clinic
		{"pos": Vector3(38.0, 0, 142.0),  "rot": -25.0, "type": "medium"},  # Building 2: Mill / Storehouse
		{"pos": Vector3(-45.0, 0, 175.0), "rot": 40.0, "type": "medium"},  # Building 3: Residence 1
		{"pos": Vector3(42.0, 0, 180.0),  "rot": -15.0, "type": "large"},   # Building 4: Residence 2
		{"pos": Vector3(-28.0, 0, 215.0), "rot": -10.0, "type": "wooden"},  # Building 5: Farm Barn
		{"pos": Vector3(32.0, 0, 225.0),  "rot": 20.0, "type": "wooden"},   # Building 6: Homestead
	]

	for h in houses:
		var hp: Vector3 = h["pos"]
		var gy = ArenaManagerScript.get_ground_elevation(hp.x, hp.z)
		var rot_y: float = h["rot"]
		var htype: String = h["type"]
		
		var house_node = StaticBody3D.new()
		house_node.collision_layer = 1 | 4
		house_node.collision_mask = 0
		house_node.position = Vector3(hp.x, gy, hp.z)
		house_node.rotation_degrees.y = rot_y
		root.add_child(house_node)
		
		if htype == "large":
			# 2-story brick building
			_build_brick_house(house_node, wall_brick, wall_window, wall_door, roof_trim, 16.0, 12.0, 8.5)
		elif htype == "medium":
			# 1.5-story brick building
			_build_brick_house(house_node, wall_brick, wall_window, wall_door, roof_trim, 12.0, 10.0, 6.0)
		else:
			# Rustic wooden homestead / barn
			_build_wooden_homestead(house_node, plank_mesh, pole_mesh, 10.0, 8.0, 4.5)
			
		# Add a cozy rustic streetlamp outside each house
		var lamp = OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.85, 0.65)
		lamp.light_energy = 0.85
		lamp.omni_range = 14.0
		lamp.position = Vector3(0, 3.5, 6.0)
		house_node.add_child(lamp)

	# Village Road Wooden Fences along central trail
	if pole_mesh:
		for i in range(8):
			var fz = 120.0 + i * 14.0
			# Left fence
			var ly = ArenaManagerScript.get_ground_elevation(-12.0, fz)
			var lf = MeshInstance3D.new()
			lf.mesh = pole_mesh
			lf.position = Vector3(-12.0, ly, fz)
			lf.scale = Vector3(1.2, 1.2, 1.2)
			root.add_child(lf)
			# Right fence
			var ry = ArenaManagerScript.get_ground_elevation(12.0, fz)
			var rf = MeshInstance3D.new()
			rf.mesh = pole_mesh
			rf.position = Vector3(12.0, ry, fz)
			rf.scale = Vector3(1.2, 1.2, 1.2)
			root.add_child(rf)

	print("VILLAGE BUILDER: Rear Civilian Village constructed with 6 Buildings, Wooden Fences, and Lanterns!")

# Helper to assemble a multi-wall brick house
static func _build_brick_house(parent: StaticBody3D, wall_mesh: Mesh, win_mesh: Mesh, door_mesh: Mesh, _roof: Mesh, w: float, d: float, h: float) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(w, h, d)
	col.shape = box
	col.position = Vector3(0, h * 0.5, 0)
	parent.add_child(col)
	
	# Visual walls facade
	if wall_mesh and win_mesh and door_mesh:
		# Front facade with door
		var f_door = MeshInstance3D.new()
		f_door.mesh = door_mesh
		f_door.position = Vector3(0, 0, d * 0.5)
		f_door.scale = Vector3(w / 8.0, h / 5.0, 1.0)
		parent.add_child(f_door)
		
		# Back facade with window
		var b_win = MeshInstance3D.new()
		b_win.mesh = win_mesh
		b_win.position = Vector3(0, 0, -d * 0.5)
		b_win.rotation_degrees.y = 180.0
		b_win.scale = Vector3(w / 8.0, h / 5.0, 1.0)
		parent.add_child(b_win)
		
		# Side walls
		var l_wall = MeshInstance3D.new()
		l_wall.mesh = wall_mesh
		l_wall.position = Vector3(-w * 0.5, 0, 0)
		l_wall.rotation_degrees.y = 90.0
		l_wall.scale = Vector3(d / 8.0, h / 5.0, 1.0)
		parent.add_child(l_wall)
		
		var r_wall = MeshInstance3D.new()
		r_wall.mesh = wall_mesh
		r_wall.position = Vector3(w * 0.5, 0, 0)
		r_wall.rotation_degrees.y = -90.0
		r_wall.scale = Vector3(d / 8.0, h / 5.0, 1.0)
		parent.add_child(r_wall)

# Helper to assemble a rustic wooden barn
static func _build_wooden_homestead(parent: StaticBody3D, plank_mesh: Mesh, pole_mesh: Mesh, w: float, d: float, h: float) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(w, h, d)
	col.shape = box
	col.position = Vector3(0, h * 0.5, 0)
	parent.add_child(col)
	
	if plank_mesh:
		var roof = MeshInstance3D.new()
		roof.mesh = plank_mesh
		roof.position = Vector3(0, h * 0.9, 0)
		roof.scale = Vector3(w * 0.3, 1.0, d * 0.3)
		parent.add_child(roof)
		
	if pole_mesh:
		# Corner support posts
		for cx in [-w * 0.45, w * 0.45]:
			for cz in [-d * 0.45, d * 0.45]:
				var p = MeshInstance3D.new()
				p.mesh = pole_mesh
				p.position = Vector3(cx, 0, cz)
				p.scale = Vector3(1.2, h / 3.0, 1.2)
				parent.add_child(p)

static func _spawn_static_fort_prop(root: Node3D, mesh: Mesh, pos: Vector3, rot_deg: Vector3, scale_vec: Vector3) -> void:
	var gy = ArenaManagerScript.get_ground_elevation(pos.x, pos.z)
	var body = StaticBody3D.new()
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	body.position = Vector3(pos.x, gy, pos.z)
	body.rotation_degrees = rot_deg
	root.add_child(body)
	
	var inst = MeshInstance3D.new()
	inst.mesh = mesh
	inst.scale = scale_vec
	body.add_child(inst)
	
	var aabb = mesh.get_aabb()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = aabb.size * scale_vec
	col.shape = box
	col.position = (aabb.position + aabb.size * 0.5) * scale_vec
	body.add_child(col)

static func _add_static_box_collider(node: Node3D, size: Vector3, offset: Vector3) -> void:
	var body = StaticBody3D.new()
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	node.add_child(body)
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col.shape = box
	col.position = offset
	body.add_child(col)
