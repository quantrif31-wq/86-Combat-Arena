extends Node3D
class_name DestructibleTree

const SLICE_SHADER = preload("res://shaders/tree_slice.gdshader")
const SFX_SNAP = preload("res://assets/audio/tree_snap.wav")
const SFX_IMPACT = preload("res://assets/audio/tree_fall_impact.wav")

@onready var stump_body: StaticBody3D = $StumpBody
@onready var stump_mesh: MeshInstance3D = $StumpBody/StumpMesh
@onready var stump_col: CollisionShape3D = $StumpBody/StumpCollision
@onready var stump_cap: MeshInstance3D = $StumpBody/StumpCap

@onready var falling_body: RigidBody3D = $FallingBody
@onready var falling_mesh: MeshInstance3D = $FallingBody/FallingMesh
@onready var falling_col: CollisionShape3D = $FallingBody/FallingCollision
@onready var falling_cap: MeshInstance3D = $FallingBody/FallingCap
@onready var falling_audio: AudioStreamPlayer3D = $FallingBody/FallingAudio

@onready var snap_audio: AudioStreamPlayer3D = $SnapAudio
@onready var splinter_particles: CPUParticles3D = $SplinterParticles

var has_impacted: bool = false
var lifetime_timer: float = 0.0

func setup_shatter(hit_pos: Vector3, impact_dir: Vector3, tree_tf: Transform3D, tree_mesh: Mesh, bark_tex: Texture2D, needle_tex: Texture2D) -> void:
	# Unscaled root so physics bodies have clean identity scale
	global_position = tree_tf.origin
	global_basis = Basis()
	
	var rot_basis = tree_tf.basis.orthonormalized()
	var scale_vec = tree_tf.basis.get_scale()
	var total_h = 75.0 * scale_vec.y
	
	# Calculate local hit height along tree mesh Y
	var local_hit_y = (hit_pos.y - tree_tf.origin.y) / maxf(scale_vec.y, 0.01)
	local_hit_y = clampf(local_hit_y, 3.5, 68.0)
	var split_h = local_hit_y * scale_vec.y
	var remain_h = total_h - split_h
	
	# ==========================================
	# 1. SETUP STUMP (Static grounded base)
	# ==========================================
	stump_body.basis = rot_basis
	stump_body.position = Vector3.ZERO
	
	stump_mesh.mesh = tree_mesh
	stump_mesh.basis = Basis().scaled(scale_vec)
	stump_mesh.position = Vector3.ZERO
	
	var mat_stump_bark = ShaderMaterial.new()
	mat_stump_bark.shader = SLICE_SHADER
	mat_stump_bark.set_shader_parameter("albedo_texture", bark_tex)
	mat_stump_bark.set_shader_parameter("clip_height", local_hit_y)
	mat_stump_bark.set_shader_parameter("invert_clip", false)
	mat_stump_bark.set_shader_parameter("alpha_scissor", 0.0)
	
	var mat_stump_leaf = ShaderMaterial.new()
	mat_stump_leaf.shader = SLICE_SHADER
	mat_stump_leaf.set_shader_parameter("albedo_texture", needle_tex)
	mat_stump_leaf.set_shader_parameter("clip_height", local_hit_y)
	mat_stump_leaf.set_shader_parameter("invert_clip", false)
	mat_stump_leaf.set_shader_parameter("alpha_scissor", 0.5)
	
	stump_mesh.set_surface_override_material(0, mat_stump_bark)
	stump_mesh.set_surface_override_material(1, mat_stump_leaf)
	
	# Stump collider
	var stump_shape = CylinderShape3D.new()
	stump_shape.radius = 0.65 * scale_vec.x
	stump_shape.height = maxf(split_h, 0.8)
	stump_col.shape = stump_shape
	stump_col.position = Vector3(0, split_h * 0.5, 0)
	
	# Splinter wood cap at stump break point
	var cap_mesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.55 * scale_vec.x
	cap_mesh.bottom_radius = 0.58 * scale_vec.x
	cap_mesh.height = 0.35
	stump_cap.mesh = cap_mesh
	stump_cap.position = Vector3(0, split_h, 0)
	
	# ==========================================
	# 2. SETUP FALLING TOP (Dynamic toppling RigidBody)
	# ==========================================
	falling_body.basis = rot_basis
	falling_body.position = rot_basis * Vector3(0, split_h, 0)
	
	falling_mesh.mesh = tree_mesh
	falling_mesh.basis = Basis().scaled(scale_vec)
	falling_mesh.position = Vector3(0, -split_h, 0)
	
	var mat_fall_bark = ShaderMaterial.new()
	mat_fall_bark.shader = SLICE_SHADER
	mat_fall_bark.set_shader_parameter("albedo_texture", bark_tex)
	mat_fall_bark.set_shader_parameter("clip_height", local_hit_y)
	mat_fall_bark.set_shader_parameter("invert_clip", true)
	mat_fall_bark.set_shader_parameter("alpha_scissor", 0.0)
	
	var mat_fall_leaf = ShaderMaterial.new()
	mat_fall_leaf.shader = SLICE_SHADER
	mat_fall_leaf.set_shader_parameter("albedo_texture", needle_tex)
	mat_fall_leaf.set_shader_parameter("clip_height", local_hit_y)
	mat_fall_leaf.set_shader_parameter("invert_clip", true)
	mat_fall_leaf.set_shader_parameter("alpha_scissor", 0.5)
	
	falling_mesh.set_surface_override_material(0, mat_fall_bark)
	falling_mesh.set_surface_override_material(1, mat_fall_leaf)
	
	# Falling collider along the remaining trunk
	var fall_shape = CylinderShape3D.new()
	fall_shape.radius = 0.55 * scale_vec.x
	fall_shape.height = maxf(remain_h * 0.75, 2.0)
	falling_col.shape = fall_shape
	falling_col.position = Vector3(0, remain_h * 0.4, 0)
	
	falling_cap.mesh = cap_mesh
	falling_cap.position = Vector3(0, 0, 0)
	
	# Physics impulse and torque
	var push = impact_dir.normalized()
	if push.length_squared() < 0.01:
		push = -Vector3.FORWARD
		
	falling_body.mass = 320.0
	falling_body.gravity_scale = 1.6
	falling_body.collision_layer = 4
	falling_body.collision_mask = 1 # Collides only with ground!
	
	var torque_axis = push.cross(Vector3.UP).normalized()
	falling_body.linear_velocity = push * 3.2 + Vector3.UP * 0.6
	falling_body.angular_velocity = torque_axis * 1.6
	
	# ==========================================
	# 3. AUDIO & SPLINTER EFFECTS
	# ==========================================
	snap_audio.stream = SFX_SNAP
	snap_audio.global_position = hit_pos
	snap_audio.pitch_scale = randf_range(0.92, 1.08)
	snap_audio.play()
	
	splinter_particles.global_position = hit_pos
	splinter_particles.emitting = true

func _physics_process(delta: float) -> void:
	lifetime_timer += delta
	
	# Check for ground impact sound
	if not has_impacted and lifetime_timer > 0.8:
		if falling_body and (falling_body.linear_velocity.length() < 1.5 or lifetime_timer > 2.8):
			has_impacted = true
			if falling_audio:
				falling_audio.stream = SFX_IMPACT
				falling_audio.pitch_scale = randf_range(0.94, 1.06)
				falling_audio.play()
				
	# Freeze physics after 3.8s to maintain 60 FPS on low-end machines
	if lifetime_timer >= 3.8 and falling_body and not falling_body.freeze:
		falling_body.freeze = true
		falling_body.collision_layer = 1
		falling_body.collision_mask = 0
		set_physics_process(false)
