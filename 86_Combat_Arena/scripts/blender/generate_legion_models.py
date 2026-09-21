import bpy
import bmesh
import math
import os

OUTPUT_DIR = r"C:\86\86_Combat_Arena\assets\models"

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for collection in [bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.armatures]:
        for item in collection:
            collection.remove(item)

def create_pbr_material(name, base_color, metallic=0.8, roughness=0.3, emission_color=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = base_color
        bsdf.inputs['Metallic'].default_value = metallic
        bsdf.inputs['Roughness'].default_value = roughness
        if emission_color:
            bsdf.inputs['Emission Color'].default_value = emission_color
            bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def create_armature(name, bone_defs):
    arm_data = bpy.data.armatures.new(name + "_Armature")
    arm_obj = bpy.data.objects.new(name + "_Armature", arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    
    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = arm_data.edit_bones
    
    created_bones = {}
    for b_name, head, tail, parent_name in bone_defs:
        b = edit_bones.new(b_name)
        b.head = head
        b.tail = tail
        if parent_name and parent_name in created_bones:
            b.parent = created_bones[parent_name]
        created_bones[b_name] = b
        
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj

def assign_vertex_group(obj, vg_name):
    vg = obj.vertex_groups.new(name=vg_name)
    v_indices = [v.index for v in obj.data.vertices]
    if v_indices:
        vg.add(v_indices, 1.0, 'REPLACE')

# =============================================================================
# 1. LEGION AMEISE (SCOUT TYPE)
# 4 agile insectoid legs, low-slung beetle carapace, spherical compound sensor eye
# =============================================================================
def build_legion_ameise():
    clear_scene()
    print("Building Legion Ameise (Scout Type)...")
    
    mat_armor = create_pbr_material("Mat_Legion_Ameise_Armor", (0.16, 0.17, 0.20, 1.0), metallic=0.85, roughness=0.3)
    mat_detail = create_pbr_material("Mat_Legion_Ameise_Steel", (0.08, 0.09, 0.11, 1.0), metallic=0.92, roughness=0.25)
    mat_eye = create_pbr_material("Mat_Legion_Ameise_Sensor", (1.0, 0.5, 0.1, 1.0), metallic=0.1, roughness=0.1,
                                  emission_color=(1.0, 0.45, 0.05, 1.0), emission_strength=8.0)

    # Armature Bones
    bone_defs = [
        # name, head, tail, parent
        ("Root", (0, 0, 0), (0, 0, 0.4), None),
        ("Chassis", (0, 0, 0.4), (0, 0, 1.0), "Root"),
        ("Turret", (0, -0.2, 1.0), (0, -0.6, 1.2), "Chassis"),
        ("Cannon", (0, -0.6, 1.1), (0, -1.8, 1.1), "Turret"),
        ("Cannon_Recoil", (0, -0.8, 1.1), (0, -1.2, 1.1), "Cannon"),
        ("Leg_FL", (-0.8, -0.7, 0.9), (-1.5, -1.4, 0.0), "Chassis"),
        ("Leg_FR", (0.8, -0.7, 0.9), (1.5, -1.4, 0.0), "Chassis"),
        ("Leg_RL", (-0.8, 0.7, 0.9), (-1.5, 1.4, 0.0), "Chassis"),
        ("Leg_RR", (0.8, 0.7, 0.9), (1.5, 1.4, 0.0), "Chassis"),
    ]
    arm_obj = create_armature("Legion_Ameise", bone_defs)

    parts = []

    # Chassis: Aerodynamic insectoid carapace
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.9, depth=1.6, location=(0, 0.1, 0.9))
    chassis = bpy.context.active_object
    chassis.scale = (0.9, 1.3, 0.45)
    bpy.ops.object.transform_apply(scale=True)
    chassis.data.materials.append(mat_armor)
    assign_vertex_group(chassis, "Chassis")
    parts.append(chassis)

    # Sensor Turret: Dome head with multi-faceted camera array
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.42, location=(0, -0.65, 1.1))
    turret = bpy.context.active_object
    turret.scale = (1.1, 1.2, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    turret.data.materials.append(mat_detail)
    assign_vertex_group(turret, "Turret")
    parts.append(turret)

    # Compound Sensor Eyes (3 glowing lenses)
    for ex in [-0.22, 0.0, 0.22]:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.10, location=(ex, -1.05, 1.1))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_eye)
        assign_vertex_group(eye, "Turret")
        parts.append(eye)

    # Dual 14mm heavy machine guns
    for gx in [-0.38, 0.38]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=1.2, location=(gx, -1.2, 1.05))
        barrel = bpy.context.active_object
        barrel.rotation_euler = (math.radians(90), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        barrel.data.materials.append(mat_detail)
        assign_vertex_group(barrel, "Cannon")
        parts.append(barrel)

    # 4 Insectoid Legs
    leg_coords = [
        ("Leg_FL", (-0.8, -0.6, 0.85), (-1.4, -1.3, 0.0)),
        ("Leg_FR", (0.8, -0.6, 0.85), (1.4, -1.3, 0.0)),
        ("Leg_RL", (-0.8, 0.6, 0.85), (-1.4, 1.3, 0.0)),
        ("Leg_RR", (0.8, 0.6, 0.85), (1.4, 1.3, 0.0)),
    ]
    for bone_name, h_pos, t_pos in leg_coords:
        # Upper segment (Thigh)
        mid = ((h_pos[0] + t_pos[0]) * 0.5, (h_pos[1] + t_pos[1]) * 0.5, h_pos[2] + 0.3)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=1.1, location=((h_pos[0]+mid[0])*0.5, (h_pos[1]+mid[1])*0.5, (h_pos[2]+mid[2])*0.5))
        leg1 = bpy.context.active_object
        leg1.data.materials.append(mat_armor)
        assign_vertex_group(leg1, bone_name)
        parts.append(leg1)
        # Lower sharp spike (Tarsus)
        bpy.ops.mesh.primitive_cone_add(radius1=0.07, depth=1.2, location=((mid[0]+t_pos[0])*0.5, (mid[1]+t_pos[1])*0.5, (mid[2]+t_pos[2])*0.5))
        leg2 = bpy.context.active_object
        leg2.data.materials.append(mat_detail)
        assign_vertex_group(leg2, bone_name)
        parts.append(leg2)

    # Join all mesh parts
    bpy.context.view_layer.objects.active = parts[0]
    for p in parts[1:]:
        p.select_set(True)
    parts[0].select_set(True)
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = "Legion_Ameise_Mesh"

    # Parent mesh to armature
    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = arm_obj

    # Create Idle animation
    arm_obj.animation_data_create()
    act = bpy.data.actions.new(name="Idle")
    arm_obj.animation_data.action = act

    # Export to GLB
    out_path = os.path.join(OUTPUT_DIR, "legion_ameise.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Legion Ameise to", out_path)

# =============================================================================
# 2. LEGION GRAUWOLF (CLOSE COMBAT ASSAULT TYPE)
# Spidery predatory frame, dual high-frequency heavy blades, dorsal rocket pod
# =============================================================================
def build_legion_grauwolf():
    clear_scene()
    print("Building Legion Grauwolf (Assault Type)...")
    
    mat_armor = create_pbr_material("Mat_Legion_Grauwolf_Armor", (0.13, 0.14, 0.16, 1.0), metallic=0.9, roughness=0.28)
    mat_steel = create_pbr_material("Mat_Legion_Grauwolf_Steel", (0.06, 0.07, 0.08, 1.0), metallic=0.95, roughness=0.2)
    mat_blade = create_pbr_material("Mat_Legion_Blade_Edge", (0.75, 0.82, 0.9, 1.0), metallic=0.98, roughness=0.15)
    mat_eye = create_pbr_material("Mat_Legion_Grauwolf_Sensor", (0.9, 0.02, 0.05, 1.0), metallic=0.1, roughness=0.1,
                                  emission_color=(1.0, 0.02, 0.05, 1.0), emission_strength=9.0)

    bone_defs = [
        ("Root", (0, 0, 0), (0, 0, 0.4), None),
        ("Chassis", (0, 0, 0.4), (0, 0, 1.1), "Root"),
        ("Turret", (0, -0.3, 1.1), (0, -0.7, 1.2), "Chassis"),
        ("Cannon", (0, -0.7, 1.2), (0, -2.0, 1.2), "Turret"),
        ("Cannon_Recoil", (0, -0.9, 1.2), (0, -1.3, 1.2), "Cannon"),
        ("Leg_FL", (-0.9, -0.7, 0.9), (-1.7, -1.5, 0.0), "Chassis"),
        ("Leg_FR", (0.9, -0.7, 0.9), (1.7, -1.5, 0.0), "Chassis"),
        ("Leg_RL", (-0.9, 0.7, 0.9), (-1.7, 1.5, 0.0), "Chassis"),
        ("Leg_RR", (0.9, 0.7, 0.9), (1.7, 1.5, 0.0), "Chassis"),
    ]
    arm_obj = create_armature("Legion_Grauwolf", bone_defs)
    parts = []

    # Angular Heavy Assault Chassis
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.95))
    chassis = bpy.context.active_object
    chassis.scale = (1.4, 1.8, 0.55)
    bpy.ops.object.transform_apply(scale=True)
    chassis.data.materials.append(mat_armor)
    assign_vertex_group(chassis, "Chassis")
    parts.append(chassis)

    # Front Visor: Menacing horizontal slit eye
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.92, 0.95))
    eye = bpy.context.active_object
    eye.scale = (0.7, 0.08, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    eye.data.materials.append(mat_eye)
    assign_vertex_group(eye, "Chassis")
    parts.append(eye)

    # Dorsal Rocket Pod (6-tube launcher on rear upper chassis)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.35, 1.45))
    pod = bpy.context.active_object
    pod.scale = (0.75, 0.9, 0.38)
    pod.rotation_euler = (math.radians(-15), 0, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    pod.data.materials.append(mat_steel)
    assign_vertex_group(pod, "Chassis")
    parts.append(pod)

    # Dual High-Frequency Heavy Vibrating Blades (curved blades along flanks)
    for bx in [-1.15, 1.15]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.08, depth=2.8, location=(bx, -0.4, 1.2))
        blade = bpy.context.active_object
        blade.scale = (0.4, 1.0, 1.8)
        blade.rotation_euler = (math.radians(50 if bx < 0 else 50), math.radians(-15 if bx < 0 else 15), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        blade.data.materials.append(mat_blade)
        assign_vertex_group(blade, "Chassis")
        parts.append(blade)

    # Center Assault Cannon / Multi-barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.6, location=(0, -1.4, 1.15))
    gun = bpy.context.active_object
    gun.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    gun.data.materials.append(mat_steel)
    assign_vertex_group(gun, "Cannon")
    parts.append(gun)

    # 4 Heavy Segmented Legs
    leg_coords = [
        ("Leg_FL", (-1.0, -0.7, 0.9), (-1.7, -1.5, 0.0)),
        ("Leg_FR", (1.0, -0.7, 0.9), (1.7, -1.5, 0.0)),
        ("Leg_RL", (-1.0, 0.7, 0.9), (-1.7, 1.5, 0.0)),
        ("Leg_RR", (1.0, 0.7, 0.9), (1.7, 1.5, 0.0)),
    ]
    for bone_name, h_pos, t_pos in leg_coords:
        mid = ((h_pos[0] + t_pos[0]) * 0.5, (h_pos[1] + t_pos[1]) * 0.5, h_pos[2] + 0.4)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.3, location=((h_pos[0]+mid[0])*0.5, (h_pos[1]+mid[1])*0.5, (h_pos[2]+mid[2])*0.5))
        l1 = bpy.context.active_object
        l1.data.materials.append(mat_armor)
        assign_vertex_group(l1, bone_name)
        parts.append(l1)

        bpy.ops.mesh.primitive_cone_add(radius1=0.10, depth=1.3, location=((mid[0]+t_pos[0])*0.5, (mid[1]+t_pos[1])*0.5, (mid[2]+t_pos[2])*0.5))
        l2 = bpy.context.active_object
        l2.data.materials.append(mat_steel)
        assign_vertex_group(l2, bone_name)
        parts.append(l2)

    # Join and bind
    bpy.context.view_layer.objects.active = parts[0]
    for p in parts[1:]:
        p.select_set(True)
    parts[0].select_set(True)
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = "Legion_Grauwolf_Mesh"

    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = arm_obj

    arm_obj.animation_data_create()
    act = bpy.data.actions.new(name="Idle")
    arm_obj.animation_data.action = act

    out_path = os.path.join(OUTPUT_DIR, "legion_grauwolf.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Legion Grauwolf to", out_path)

# =============================================================================
# 3. LEGION SHEPHERD (DINOSAURIA HEAVY TANK COMMANDER)
# Massive 100t behemoth, colossal 155mm smoothbore gun, pulsing neural brain core
# =============================================================================
def build_legion_shepherd():
    clear_scene()
    print("Building Legion Shepherd (Dinosauria Boss)...")
    
    mat_armor = create_pbr_material("Mat_Shepherd_HeavyArmor", (0.11, 0.12, 0.14, 1.0), metallic=0.92, roughness=0.26)
    mat_steel = create_pbr_material("Mat_Shepherd_Tungsten", (0.05, 0.06, 0.07, 1.0), metallic=0.96, roughness=0.18)
    mat_neural = create_pbr_material("Mat_Shepherd_NeuralCore", (0.9, 0.05, 0.12, 1.0), metallic=0.2, roughness=0.1,
                                     emission_color=(1.0, 0.04, 0.1, 1.0), emission_strength=12.0)
    mat_optic = create_pbr_material("Mat_Shepherd_Optics", (1.0, 0.02, 0.05, 1.0), metallic=0.1, roughness=0.1,
                                    emission_color=(1.0, 0.02, 0.04, 1.0), emission_strength=10.0)

    bone_defs = [
        ("Root", (0, 0, 0), (0, 0, 0.6), None),
        ("Chassis", (0, 0, 0.6), (0, 0, 1.5), "Root"),
        ("Turret", (0, -0.2, 1.8), (0, -1.0, 2.0), "Chassis"),
        ("Cannon", (0, -1.0, 2.0), (0, -4.6, 2.0), "Turret"),
        ("Cannon_Recoil", (0, -1.4, 2.0), (0, -2.4, 2.0), "Cannon"),
        ("Leg_FL", (-1.6, -1.4, 1.2), (-2.8, -2.4, 0.0), "Chassis"),
        ("Leg_FR", (1.6, -1.4, 1.2), (2.8, -2.4, 0.0), "Chassis"),
        ("Leg_ML", (-1.9, 0.0, 1.2), (-3.2, 0.0, 0.0), "Chassis"),
        ("Leg_MR", (1.9, 0.0, 1.2), (3.2, 0.0, 0.0), "Chassis"),
        ("Leg_RL", (-1.6, 1.4, 1.2), (-2.8, 2.4, 0.0), "Chassis"),
        ("Leg_RR", (1.6, 1.4, 1.2), (2.8, 2.4, 0.0), "Chassis"),
    ]
    arm_obj = create_armature("Legion_Shepherd", bone_defs)
    parts = []

    # Massive Chobham Sloped Heavy Chassis
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.3))
    chassis = bpy.context.active_object
    chassis.scale = (2.6, 3.4, 0.9)
    bpy.ops.object.transform_apply(scale=True)
    chassis.data.materials.append(mat_armor)
    assign_vertex_group(chassis, "Chassis")
    parts.append(chassis)

    # Heavy Angled Sloped Skirts
    for sx in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sx, 0, 1.0))
        skirt = bpy.context.active_object
        skirt.scale = (0.4, 3.2, 0.7)
        bpy.ops.object.transform_apply(scale=True)
        skirt.data.materials.append(mat_steel)
        assign_vertex_group(skirt, "Chassis")
        parts.append(skirt)

    # Pulsing Neural Brain Core (Ghost of Dead Commander) on rear deck
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=16, radius=0.65, location=(0, 0.95, 2.05))
    core = bpy.context.active_object
    core.scale = (1.2, 1.1, 0.75)
    bpy.ops.object.transform_apply(scale=True)
    core.data.materials.append(mat_neural)
    assign_vertex_group(core, "Chassis")
    parts.append(core)

    # Protective Armored Cage around Neural Core
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.85, depth=0.6, location=(0, 0.95, 2.0))
    cage = bpy.context.active_object
    cage.data.materials.append(mat_steel)
    assign_vertex_group(cage, "Chassis")
    parts.append(cage)

    # Gigantic Heavy Rotating Turret
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, 2.15))
    turret = bpy.context.active_object
    turret.scale = (2.2, 2.5, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    turret.data.materials.append(mat_armor)
    assign_vertex_group(turret, "Turret")
    parts.append(turret)

    # Optical Targeting Sensors (Triple glowing crimson eyes on turret front)
    for ox, oz in [(-0.6, 2.2), (0.0, 2.35), (0.6, 2.2)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.14, depth=0.3, location=(ox, -1.7, oz))
        optic = bpy.context.active_object
        optic.rotation_euler = (math.radians(90), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        optic.data.materials.append(mat_optic)
        assign_vertex_group(optic, "Turret")
        parts.append(optic)

    # Colossal 155mm Smoothbore Main Gun Barrel (3.8 meters long!)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=3.8, location=(0, -3.2, 2.05))
    gun = bpy.context.active_object
    gun.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    gun.data.materials.append(mat_steel)
    assign_vertex_group(gun, "Cannon")
    parts.append(gun)

    # Heavy Slotted Muzzle Brake
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -5.1, 2.05))
    brake = bpy.context.active_object
    brake.scale = (0.55, 0.6, 0.45)
    bpy.ops.object.transform_apply(scale=True)
    brake.data.materials.append(mat_steel)
    assign_vertex_group(brake, "Cannon")
    parts.append(brake)

    # Dual Coaxial Autocannons on Turret Sides
    for cx in [-1.15, 1.15]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=1.6, location=(cx, -1.8, 2.3))
        coax = bpy.context.active_object
        coax.rotation_euler = (math.radians(90), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        coax.data.materials.append(mat_steel)
        assign_vertex_group(coax, "Turret")
        parts.append(coax)

    # 6 Massive Heavy Crawler Legs
    leg_coords = [
        ("Leg_FL", (-1.5, -1.3, 1.2), (-2.7, -2.4, 0.0)),
        ("Leg_FR", (1.5, -1.3, 1.2), (2.7, -2.4, 0.0)),
        ("Leg_ML", (-1.7, 0.0, 1.2), (-3.1, 0.0, 0.0)),
        ("Leg_MR", (1.7, 0.0, 1.2), (3.1, 0.0, 0.0)),
        ("Leg_RL", (-1.5, 1.3, 1.2), (-2.7, 2.4, 0.0)),
        ("Leg_RR", (1.5, 1.3, 1.2), (2.7, 2.4, 0.0)),
    ]
    for bone_name, h_pos, t_pos in leg_coords:
        mid = ((h_pos[0] + t_pos[0]) * 0.5, (h_pos[1] + t_pos[1]) * 0.5, h_pos[2] + 0.6)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=1.8, location=((h_pos[0]+mid[0])*0.5, (h_pos[1]+mid[1])*0.5, (h_pos[2]+mid[2])*0.5))
        l1 = bpy.context.active_object
        l1.data.materials.append(mat_armor)
        assign_vertex_group(l1, bone_name)
        parts.append(l1)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=((mid[0]+t_pos[0])*0.5, (mid[1]+t_pos[1])*0.5, (mid[2]+t_pos[2])*0.5))
        l2 = bpy.context.active_object
        l2.scale = (0.28, 0.28, 1.6)
        bpy.ops.object.transform_apply(scale=True)
        l2.data.materials.append(mat_steel)
        assign_vertex_group(l2, bone_name)
        parts.append(l2)

    # Join and bind
    bpy.context.view_layer.objects.active = parts[0]
    for p in parts[1:]:
        p.select_set(True)
    parts[0].select_set(True)
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = "Legion_Shepherd_Mesh"

    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = arm_obj

    arm_obj.animation_data_create()
    act = bpy.data.actions.new(name="Idle")
    arm_obj.animation_data.action = act

    out_path = os.path.join(OUTPUT_DIR, "legion_shepherd_dinosauria.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Legion Shepherd Dinosauria to", out_path)

if __name__ == "__main__":
    build_legion_ameise()
    build_legion_grauwolf()
    build_legion_shepherd()
    print(">>> ALL 3 LEGION MODELS GENERATED SUCCESSFULLY! <<<")
