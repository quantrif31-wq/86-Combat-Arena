import bpy
import bmesh
import math
import os

SOURCE_GLB = r"C:\86\86_Combat_Arena\assets\models\m1a4_juggernaut_player.glb"
OUTPUT_DIR = r"C:\86\86_Combat_Arena\assets\models"

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for collection in [bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.armatures]:
        for item in collection:
            collection.remove(item)

def load_base_juggernaut():
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=SOURCE_GLB)
    arm_obj = None
    mesh_obj = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            arm_obj = obj
        elif obj.type == 'MESH':
            mesh_obj = obj
    return arm_obj, mesh_obj

def create_pbr_material(name, base_color, metallic=0.9, roughness=0.25, emission_color=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = base_color
        bsdf.inputs['Metallic'].default_value = metallic
        bsdf.inputs['Roughness'].default_value = roughness
        if emission_color:
            bsdf.inputs['Emission Color'].default_value = emission_color
            bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def attach_to_bone(part_obj, arm_obj, bone_name):
    part_obj.parent = arm_obj
    part_obj.parent_type = 'BONE'
    part_obj.parent_bone = bone_name

# =============================================================================
# 1. SHIN NOUZEN [UNDERTAKER]
# Dual high-frequency blades on flanks, Undertaker headless skeleton emblem
# =============================================================================
def build_undertaker():
    arm_obj, mesh_obj = load_base_juggernaut()
    print("Building Shin Nouzen [Undertaker] Custom Juggernaut...")
    
    mat_blade_steel = create_pbr_material("Mat_HF_Blade_Steel", (0.85, 0.88, 0.92, 1.0), metallic=0.98, roughness=0.15)
    mat_blade_glow = create_pbr_material("Mat_HF_Blade_Glow", (0.2, 0.85, 1.0, 1.0), metallic=0.1, roughness=0.1,
                                         emission_color=(0.2, 0.85, 1.0, 1.0), emission_strength=8.0)
    mat_emblem = create_pbr_material("Mat_Undertaker_Emblem", (0.95, 0.15, 0.2, 1.0), metallic=0.3, roughness=0.4,
                                     emission_color=(0.8, 0.1, 0.15, 1.0), emission_strength=3.0)

    # 1. Dual High-Frequency Vibrating Blades on Chassis Flanks
    # In Godot/Blender, Shin's blades sit alongside the cockpit and extend forward for high-speed slicing
    for side in [-1.0, 1.0]:
        # Blade Mount Arm
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.85, -0.4, 1.15))
        mount = bpy.context.active_object
        mount.scale = (0.08, 0.45, 0.12)
        bpy.ops.object.transform_apply(scale=True)
        mount.data.materials.append(mat_blade_steel)
        attach_to_bone(mount, arm_obj, "Chassis")

        # Long Curved Razor Blade (2.6m reach)
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=2.6, location=(side * 0.95, -1.5, 1.1))
        blade = bpy.context.active_object
        blade.scale = (0.25, 1.0, 0.8)
        blade.rotation_euler = (math.radians(82), math.radians(side * -8), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        blade.data.materials.append(mat_blade_steel)
        attach_to_bone(blade, arm_obj, "Chassis")

        # High-Frequency Vibrating Energy Edge
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.95, -1.6, 1.08))
        edge = bpy.context.active_object
        edge.scale = (0.02, 2.5, 0.04)
        edge.rotation_euler = (math.radians(82), math.radians(side * -8), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        edge.data.materials.append(mat_blade_glow)
        attach_to_bone(edge, arm_obj, "Chassis")

    # 2. Undertaker Emblem (The Headless Skeleton Reaper with Shovel)
    # Modeled as a prominent stylized crimson crest on the cockpit canopy
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.24, depth=0.04, location=(0, -0.75, 1.48))
    emblem = bpy.context.active_object
    emblem.rotation_euler = (math.radians(45), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    emblem.data.materials.append(mat_emblem)
    attach_to_bone(emblem, arm_obj, "Chassis")

    out_path = os.path.join(OUTPUT_DIR, "m1a4_undertaker.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Undertaker Juggernaut to", out_path)

# =============================================================================
# 2. RAIDEN SHUGA [WEHRWOLF]
# Heavy armored frontal hip skirts, dual 12.7mm turret autocannons, Wehrwolf mark
# =============================================================================
def build_wehrwolf():
    arm_obj, mesh_obj = load_base_juggernaut()
    print("Building Raiden Shuga [Wehrwolf] Custom Juggernaut...")
    
    mat_armor = create_pbr_material("Mat_Wehrwolf_HeavyPlate", (0.35, 0.38, 0.40, 1.0), metallic=0.92, roughness=0.35)
    mat_gun = create_pbr_material("Mat_Wehrwolf_Autocannon", (0.10, 0.11, 0.12, 1.0), metallic=0.95, roughness=0.2)
    mat_emblem = create_pbr_material("Mat_Wehrwolf_Emblem", (0.2, 0.75, 1.0, 1.0), metallic=0.4, roughness=0.3,
                                     emission_color=(0.1, 0.6, 0.9, 1.0), emission_strength=2.5)

    # 1. Heavy Frontal Hip Armor Skirts (left and right)
    for side in [-1.0, 1.0]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.78, -0.95, 1.0))
        skirt = bpy.context.active_object
        skirt.scale = (0.28, 0.65, 0.55)
        skirt.rotation_euler = (math.radians(25), math.radians(side * -15), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        skirt.data.materials.append(mat_armor)
        attach_to_bone(skirt, arm_obj, "Chassis")

    # 2. Dual 12.7mm Secondary Autocannons on Turret Flanks
    # Attached directly to the Turret bone so they aim with the main gun!
    for side in [-1.0, 1.0]:
        # Gun Pod Housing
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.55, -0.4, 1.85))
        pod = bpy.context.active_object
        pod.scale = (0.16, 0.55, 0.22)
        bpy.ops.object.transform_apply(scale=True)
        pod.data.materials.append(mat_armor)
        attach_to_bone(pod, arm_obj, "Turret")

        # Twin Autocannon Barrels
        for dy in [-0.04, 0.04]:
            bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.95, location=(side * 0.55, -0.85, 1.85 + dy))
            barrel = bpy.context.active_object
            barrel.rotation_euler = (math.radians(90), 0, 0)
            bpy.ops.object.transform_apply(rotation=True)
            barrel.data.materials.append(mat_gun)
            attach_to_bone(barrel, arm_obj, "Turret")

    # 3. Iron Werewolf Personal Emblem
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.24, depth=0.04, location=(0, -0.75, 1.48))
    emblem = bpy.context.active_object
    emblem.rotation_euler = (math.radians(45), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    emblem.data.materials.append(mat_emblem)
    attach_to_bone(emblem, arm_obj, "Chassis")

    out_path = os.path.join(OUTPUT_DIR, "m1a4_wehrwolf.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Wehrwolf Juggernaut to", out_path)

# =============================================================================
# 3. KURENA KUKUMILA [GUNSLINGER]
# Extended long-barrel 57mm sniper cannon, top sniper optic scope pod, Gunslinger mark
# =============================================================================
def build_gunslinger():
    arm_obj, mesh_obj = load_base_juggernaut()
    print("Building Kurena Kukumila [Gunslinger] Custom Juggernaut...")
    
    mat_barrel = create_pbr_material("Mat_Gunslinger_LongBarrel", (0.18, 0.20, 0.22, 1.0), metallic=0.95, roughness=0.22)
    mat_optic = create_pbr_material("Mat_Gunslinger_OpticLens", (0.1, 0.85, 0.45, 1.0), metallic=0.1, roughness=0.1,
                                    emission_color=(0.15, 0.95, 0.45, 1.0), emission_strength=7.0)
    mat_emblem = create_pbr_material("Mat_Gunslinger_Emblem", (1.0, 0.85, 0.2, 1.0), metallic=0.4, roughness=0.3,
                                     emission_color=(0.9, 0.75, 0.15, 1.0), emission_strength=2.5)

    # 1. Extended Long-Barrel 57mm Sniper Cannon (+1.6 meters extension)
    # Attached to Cannon_Recoil bone so it recoils with fire!
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=1.6, location=(0, -2.4, 1.84))
    ext_barrel = bpy.context.active_object
    ext_barrel.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    ext_barrel.data.materials.append(mat_barrel)
    attach_to_bone(ext_barrel, arm_obj, "Cannon_Recoil")

    # 4-Port Slotted Sniper Muzzle Brake
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.42, location=(0, -3.3, 1.84))
    brake = bpy.context.active_object
    brake.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    brake.data.materials.append(mat_barrel)
    attach_to_bone(brake, arm_obj, "Cannon_Recoil")

    # 2. Top-Mounted Long-Range Sniper Optic Sensor Pod (Periscope Scope)
    # Attached to Turret bone
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.28, -0.6, 2.18))
    pod = bpy.context.active_object
    pod.scale = (0.24, 0.75, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    pod.data.materials.append(mat_barrel)
    attach_to_bone(pod, arm_obj, "Turret")

    # Forward Optic Lens (Green high-gain sniper lens)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=0.15, location=(0.28, -1.0, 2.18))
    lens = bpy.context.active_object
    lens.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    lens.data.materials.append(mat_optic)
    attach_to_bone(lens, arm_obj, "Turret")

    # 3. Gunslinger Personal Emblem (The Sniper Lynx)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.24, depth=0.04, location=(0, -0.75, 1.48))
    emblem = bpy.context.active_object
    emblem.rotation_euler = (math.radians(45), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    emblem.data.materials.append(mat_emblem)
    attach_to_bone(emblem, arm_obj, "Chassis")

    out_path = os.path.join(OUTPUT_DIR, "m1a4_gunslinger.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', export_yup=True)
    print("SUCCESS: Exported Gunslinger Juggernaut to", out_path)

if __name__ == "__main__":
    build_undertaker()
    build_wehrwolf()
    build_gunslinger()
    print(">>> ALL 3 SQUAD JUGGERNAUT MODELS GENERATED SUCCESSFULLY! <<<")
