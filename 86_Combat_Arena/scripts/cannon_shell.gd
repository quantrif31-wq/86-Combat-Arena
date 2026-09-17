extends Area3D
class_name CannonShell

@export var speed: float = 125.0
@export var damage: float = 35.0
@export var max_lifetime: float = 3.5

var shooter_node: Node = null
var current_lifetime: float = 0.0
var explosion_scene: PackedScene = preload("res://scenes/explosion_vfx.tscn")
var wall_hit_scene: PackedScene = preload("res://scenes/wall_hit_vfx.tscn")

@onready var dart_model: Node3D = get_node_or_null("DartModel")
var prev_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	prev_pos = global_position

func _physics_process(delta: float) -> void:
	# Rifling spin along flight axis
	if dart_model:
		dart_model.rotate_z(28.0 * delta)
		
	var forward = -transform.basis.z
	var move_vec = forward * speed * delta
	var next_pos = global_position + move_vec
	
	# Continuous collision raycast sweep to prevent hypersonic tunneling
	var world = get_world_3d()
	if world and world.direct_space_state:
		var space = world.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position, next_pos, 1 | 2)
		var exclude_list = [self]
		if shooter_node:
			exclude_list.append(shooter_node)
		query.exclude = exclude_list
		var hit = space.intersect_ray(query)
		if hit:
			var col = hit.collider
			var is_dmg = col != null and (col.has_method("take_damage") or col.has_method("take_hit"))
			detonate(hit.position, is_dmg)
			if col != null:
				if col.has_method("take_hit"):
					col.take_hit(damage, shooter_node, hit.position, forward)
				elif col.has_method("take_damage"):
					col.take_damage(damage, shooter_node)
			return
			
	global_position = next_pos
	prev_pos = global_position
	
	current_lifetime += delta
	if current_lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter_node:
		return
	var forward = -transform.basis.z
	var is_damageable = body.has_method("take_damage") or body.has_method("take_hit")
	detonate(global_position, is_damageable)
	if body.has_method("take_hit"):
		body.take_hit(damage, shooter_node, global_position, forward)
	elif body.has_method("take_damage"):
		body.take_damage(damage, shooter_node)

func _on_area_entered(area: Area3D) -> void:
	if area == shooter_node or area.get_parent() == shooter_node:
		return
	var forward = -transform.basis.z
	var target = area if (area.has_method("take_damage") or area.has_method("take_hit")) else area.get_parent()
	var is_damageable = target != null and (target.has_method("take_damage") or target.has_method("take_hit"))
	detonate(global_position, is_damageable)
	if target != null:
		if target.has_method("take_hit"):
			target.take_hit(damage, shooter_node, global_position, forward)
		elif target.has_method("take_damage"):
			target.take_damage(damage, shooter_node)

func detonate(pos: Vector3, is_unit: bool = true) -> void:
	var vfx_scene = explosion_scene if is_unit else wall_hit_scene
	if vfx_scene:
		var vfx_inst = vfx_scene.instantiate() as Node3D
		var spawn_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if spawn_root:
			spawn_root.add_child(vfx_inst)
		elif get_tree() and get_tree().root:
			get_tree().root.add_child(vfx_inst)
		vfx_inst.global_position = pos
	queue_free()
