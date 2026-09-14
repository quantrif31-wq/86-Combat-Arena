import bpy
import os
import math
import random
from mathutils import Vector, Euler, Matrix

print("=====================================================================")
print(" ASSEMBLING SECTOR 86: GRAND WARZONE MAP (800m x 800m ULTRA-RICH)   ")
print("=====================================================================")

models_dir = r"c:\86\86_Combat_Arena\assets\environment\models"
tex_dir = r"c:\86\86_Combat_Arena\assets\environment\textures\forest_ground_04"

ground_diff = os.path.join(tex_dir, "diff_1k.jpg")
ground_nor = os.path.join(tex_dir, "nor_gl_1k.jpg")
ground_arm = os.path.join(tex_dir, "arm_1k.jpg")

bpy.ops.wm.read_factory_settings(use_empty=True)

# -------------------------------------------------------------------------
# 1. HELPER: Import Asset Catalog cleanly
# -------------------------------------------------------------------------
def import_catalog(filepath, prefix):
    if not os.path.exists(filepath):
        print(f"WARNING: File not found: {filepath}")
        return []
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    after = set(bpy.data.objects)
    imported = list(after - before)
    mesh_objs = [o for o in imported if o.type == 'MESH']
    for o in mesh_objs:
        o.name = f"{prefix}_{o.name}"
        if o.parent:
            bpy.ops.object.select_all(action='DESELECT')
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
        o.parent = None
        o.matrix_parent_inverse.identity()
    return mesh_objs

# Import baseline models
fort_objs = import_catalog(os.path.join(models_dir, "modular_fort_01", "modular_fort_01_1k.gltf"), "Fort")
dead_tree_objs = import_catalog(os.path.join(models_dir, "dead_tree_trunk", "dead_tree_trunk_1k.gltf"), "DeadTree")
rock_moss_objs = import_catalog(os.path.join(models_dir, "rock_moss_set_01", "rock_moss_set_01_1k.gltf"), "RockMoss")
barrier_objs = import_catalog(os.path.join(models_dir, "concrete_road_barrier", "concrete_road_barrier_1k.gltf"), "Barrier")

# Import new Grand Warzone models
factory_objs = import_catalog(os.path.join(models_dir, "modular_factory_facade", "modular_factory_facade_1k.gltf"), "Factory")
fence_objs = import_catalog(os.path.join(models_dir, "modular_chainlink_fence", "modular_chainlink_fence_1k.gltf"), "Fence")
pipe_objs = import_catalog(os.path.join(models_dir, "modular_pipes", "modular_pipes_1k.gltf"), "Pipe")
pier_objs = import_catalog(os.path.join(models_dir, "modular_wooden_pier", "modular_wooden_pier_1k.gltf"), "Pier")
boulder_objs = import_catalog(os.path.join(models_dir, "boulder_01", "boulder_01_1k.gltf"), "Boulder")
cliff_objs = import_catalog(os.path.join(models_dir, "rock_face_01", "rock_face_01_1k.gltf"), "Cliff")
ammo_objs = import_catalog(os.path.join(models_dir, "ammo_box", "ammo_box_1k.gltf"), "Ammo")
barrier2_objs = import_catalog(os.path.join(models_dir, "concrete_road_barrier_02", "concrete_road_barrier_02_1k.gltf"), "Barrier2")

# Bake / join Pine Tree into single clean reference
pine_glb = os.path.join(models_dir, "pine_tree_game-ready.glb")
before_pine = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=pine_glb)
after_pine = set(bpy.data.objects)
pine_imported = list(after_pine - before_pine)
pine_meshes = [o for o in pine_imported if o.type == 'MESH']
if pine_meshes:
    bpy.ops.object.select_all(action='DESELECT')
    for o in pine_meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = pine_meshes[0]
    bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
    bpy.ops.object.join()
    pine_ref = bpy.context.active_object
    pine_ref.name = "Ref_Pine_Tree"
    pine_ref.parent = None
    pine_ref.matrix_parent_inverse.identity()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
else:
    pine_ref = None

# Catalog Fort components
fort_dict = {}
for o in fort_objs:
    for key in ['tower_round', 'stairs', 'thick_corner', 'thick_straight_01', 'thick_straight_02', 'gate', 'thin_straight_01', 'walkway_straight']:
        if key in o.name.lower():
            fort_dict[key] = o
            break

# Catalog Factory components
factory_dict = {}
for o in factory_objs:
    for key in ['wall_door_garage_double_01', 'wall_standard_standard_01', 'wall_standard_corner_large_01', 
                'wall_window_centered_large_01', 'wall_door_centered_large_01', 'crown_standard_standard_01']:
        if key in o.name.lower():
            factory_dict[key] = o
            break

# Catalog Pier/Bridge components
pier_dict = {}
for o in pier_objs:
    for key in ['section_01', 'planks', 'poles']:
        if key in o.name.lower():
            pier_dict[key] = o
            break

# Create Target Map Collection
map_coll = bpy.data.collections.new("Sector86_GrandMap")
bpy.context.scene.collection.children.link(map_coll)

def place_instance(src_obj, name, loc, rot_euler=(0,0,0), scale=(1,1,1)):
    if not src_obj:
        return None
    new_obj = src_obj.copy()
    new_obj.data = src_obj.data  # Linked duplicate (zero extra memory)
    new_obj.name = name
    new_obj.parent = None
    new_obj.matrix_parent_inverse.identity()
    new_obj.location = loc
    new_obj.rotation_euler = rot_euler
    new_obj.scale = scale
    map_coll.objects.link(new_obj)
    return new_obj

# -------------------------------------------------------------------------
# 2. TOPOGRAPHY ELEVATION MATH FUNCTION
# -------------------------------------------------------------------------
def get_terrain_elevation(x, y):
    # Base undulating terrain
    n1 = math.sin(x * 0.015) * math.cos(y * 0.015) * 3.5
    n2 = math.sin(x * 0.035 + 1.1) * math.sin(y * 0.035 + 0.7) * 2.0
    elev = n1 + n2

    # A. Dried River Ravine (centered along y = -80, width 45m, depth ~5.5m)
    ravine_y = -80.0
    dy = y - ravine_y
    if abs(dy) < 35.0:
        factor = 1.0 - (abs(dy) / 35.0)
        elev -= factor * factor * 5.8

    # B. Citadel Elevated Plateau (North, centered at x=0, y=140, radius 100m)
    dist_cit = math.sqrt(x*x + (y - 140.0)*(y - 140.0))
    if dist_cit < 95.0:
        c_factor = 1.0 - (dist_cit / 95.0)
        elev += c_factor * 5.2

    # C. Factory Terrace (West, x=-220, y=0, radius 85m)
    dist_fac = math.sqrt((x + 220.0)*(x + 220.0) + y*y)
    if dist_fac < 85.0:
        f_factor = 1.0 - (dist_fac / 85.0)
        elev += f_factor * 2.5

    # D. Trench & Outpost Ridge (East, x=220, y=20, radius 80m)
    dist_out = math.sqrt((x - 220.0)*(x - 220.0) + (y - 20.0)*(y - 20.0))
    if dist_out < 80.0:
        o_factor = 1.0 - (dist_out / 80.0)
        elev += o_factor * 3.0

    # E. Outer Perimeter Mountain Ridges (Boundary rim > 300m radius)
    r = math.sqrt(x*x + y*y)
    if r > 300.0:
        rim_t = min(1.0, (r - 300.0) / 90.0)
        elev += rim_t * rim_t * 32.0

    return elev

# -------------------------------------------------------------------------
# 3. GENERATE 800m x 800m VAST TERRAIN MESH
# -------------------------------------------------------------------------
print("Generating 800m x 800m Rolling Terrain...")
GRID_SIZE = 800.0
SUBS = 120

bpy.ops.mesh.primitive_grid_add(x_subdivisions=SUBS, y_subdivisions=SUBS, size=GRID_SIZE, location=(0, 0, 0))
terrain = bpy.context.active_object
terrain.name = "Terrain_Grand_Warzone"
terrain.parent = None
terrain.matrix_parent_inverse.identity()
for c in terrain.users_collection:
    c.objects.unlink(terrain)
map_coll.objects.link(terrain)

verts = terrain.data.vertices
for v in verts:
    v.co.z = get_terrain_elevation(v.co.x, v.co.y)

# UV coordinates tiled across 800m
uv_layer = terrain.data.uv_layers.active
if not uv_layer:
    uv_layer = terrain.data.uv_layers.new(name="UVMap")
for poly in terrain.data.polygons:
    for loop_index in poly.loop_indices:
        v_idx = terrain.data.loops[loop_index].vertex_index
        v = terrain.data.vertices[v_idx]
        u = (v.co.x / GRID_SIZE + 0.5) * 80.0
        v_coord = (v.co.y / GRID_SIZE + 0.5) * 80.0
        uv_layer.data[loop_index].uv = (u, v_coord)

terrain.data.update()

# Terrain PBR Material
mat_terrain = bpy.data.materials.new(name="Mat_Forest_Ground_PBR")
nodes = mat_terrain.node_tree.nodes
links = mat_terrain.node_tree.links
bsdf = nodes.get("Principled BSDF")

if os.path.exists(ground_diff):
    tex_diff = nodes.new('ShaderNodeTexImage')
    tex_diff.image = bpy.data.images.load(ground_diff)
    links.new(tex_diff.outputs['Color'], bsdf.inputs['Base Color'])

if os.path.exists(ground_nor):
    tex_nor = nodes.new('ShaderNodeTexImage')
    tex_nor.image = bpy.data.images.load(ground_nor)
    tex_nor.image.colorspace_settings.name = 'Non-Color'
    node_normal_map = nodes.new('ShaderNodeNormalMap')
    node_normal_map.inputs['Strength'].default_value = 1.3
    links.new(tex_nor.outputs['Color'], node_normal_map.inputs['Color'])
    links.new(node_normal_map.outputs['Normal'], bsdf.inputs['Normal'])

if os.path.exists(ground_arm):
    tex_arm = nodes.new('ShaderNodeTexImage')
    tex_arm.image = bpy.data.images.load(ground_arm)
    tex_arm.image.colorspace_settings.name = 'Non-Color'
    sep_rgb = nodes.new('ShaderNodeSeparateColor')
    links.new(tex_arm.outputs['Color'], sep_rgb.inputs['Color'])
    links.new(sep_rgb.outputs['Green'], bsdf.inputs['Roughness'])
else:
    bsdf.inputs['Roughness'].default_value = 0.90

terrain.data.materials.append(mat_terrain)

# -------------------------------------------------------------------------
# 4. ZONE 1: THE IRON CITADEL RUINS (North Plateau: X: 0, Y: 140)
# -------------------------------------------------------------------------
print("Constructing Zone 1: The Iron Citadel Ruins...")
cit_x, cit_y = 0.0, 140.0
cit_z = get_terrain_elevation(cit_x, cit_y)

if 'tower_round' in fort_dict:
    place_instance(fort_dict['tower_round'], "Ruin_Tower_NW", (cit_x - 48.0, cit_y + 42.0, get_terrain_elevation(cit_x - 48.0, cit_y + 42.0)))
    place_instance(fort_dict['tower_round'], "Ruin_Tower_NE", (cit_x + 48.0, cit_y + 42.0, get_terrain_elevation(cit_x + 48.0, cit_y + 42.0)))
    place_instance(fort_dict['tower_round'], "Ruin_Tower_SW", (cit_x - 48.0, cit_y - 38.0, get_terrain_elevation(cit_x - 48.0, cit_y - 38.0)))
    place_instance(fort_dict['tower_round'], "Ruin_Tower_SE", (cit_x + 48.0, cit_y - 38.0, get_terrain_elevation(cit_x + 48.0, cit_y - 38.0)))

if 'thick_straight_01' in fort_dict:
    # Curtain walls
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_N_01", (cit_x - 22.0, cit_y + 44.0, cit_z), (0, 0, 0))
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_N_02", (cit_x + 22.0, cit_y + 44.0, cit_z), (0, 0, 0))
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_W_01", (cit_x - 51.0, cit_y + 12.0, cit_z), (0, 0, math.pi/2))
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_W_02", (cit_x - 51.0, cit_y - 12.0, cit_z), (0, 0, math.pi/2))
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_E_01", (cit_x + 51.0, cit_y + 12.0, cit_z), (0, 0, math.pi/2))
    place_instance(fort_dict['thick_straight_01'], "Ruin_Wall_E_02", (cit_x + 51.0, cit_y - 12.0, cit_z), (0, 0, math.pi/2))

if 'gate' in fort_dict:
    place_instance(fort_dict['gate'], "Ruin_Gatehouse_South", (cit_x, cit_y - 40.0, cit_z), (0, 0, 0))

if 'stairs' in fort_dict and 'walkway_straight' in fort_dict:
    place_instance(fort_dict['stairs'], "Ruin_Stairs_East", (cit_x + 38.0, cit_y + 16.0, cit_z), (0, 0, -math.pi/2))
    place_instance(fort_dict['walkway_straight'], "Ruin_Walkway_East", (cit_x + 38.0, cit_y - 2.0, cit_z), (0, 0, -math.pi/2))
    place_instance(fort_dict['stairs'], "Ruin_Stairs_West", (cit_x - 38.0, cit_y + 16.0, cit_z), (0, 0, math.pi/2))

if 'thin_straight_01' in fort_dict:
    place_instance(fort_dict['thin_straight_01'], "Ruin_Cover_C_01", (cit_x - 14.0, cit_y + 14.0, cit_z), (0, 0, math.radians(45)))
    place_instance(fort_dict['thin_straight_01'], "Ruin_Cover_C_02", (cit_x + 16.0, cit_y + 10.0, cit_z), (0, 0, math.radians(-35)))
    place_instance(fort_dict['thin_straight_01'], "Ruin_Cover_C_03", (cit_x - 8.0, cit_y - 15.0, cit_z), (0, 0, math.radians(15)))
    place_instance(fort_dict['thin_straight_01'], "Ruin_Cover_C_04", (cit_x + 8.0, cit_y - 15.0, cit_z), (0, 0, math.radians(-15)))

# -------------------------------------------------------------------------
# 5. ZONE 2: SECTOR 86 HEAVY FACTORY RUINS (West: X: -220, Y: 0)
# -------------------------------------------------------------------------
print("Constructing Zone 2: Sector 86 Heavy Factory Complex...")
fac_x, fac_y = -220.0, 0.0
fac_z = get_terrain_elevation(fac_x, fac_y)

fac_wall = factory_dict.get('wall_standard_standard_01') or (factory_objs[0] if factory_objs else None)
fac_door = factory_dict.get('wall_door_garage_double_01') or fac_wall
fac_win = factory_dict.get('wall_window_centered_large_01') or fac_wall

# Main Warehouse Complex (45m x 30m)
hangar_parts = [
    (fac_door, "Factory_Hangar_Door_01", (fac_x - 15.0, fac_y - 16.0, fac_z), (0, 0, 0), (2.8, 2.8, 2.8)),
    (fac_door, "Factory_Hangar_Door_02", (fac_x + 15.0, fac_y - 16.0, fac_z), (0, 0, 0), (2.8, 2.8, 2.8)),
    (fac_wall, "Factory_Wall_N_01", (fac_x - 15.0, fac_y + 20.0, fac_z), (0, 0, 0), (2.8, 2.8, 2.8)),
    (fac_win,  "Factory_Wall_N_02", (fac_x + 15.0, fac_y + 20.0, fac_z), (0, 0, 0), (2.8, 2.8, 2.8)),
    (fac_wall, "Factory_Wall_W_01", (fac_x - 32.0, fac_y + 3.0, fac_z), (0, 0, math.pi/2), (2.8, 2.8, 2.8)),
    (fac_win,  "Factory_Wall_E_01", (fac_x + 32.0, fac_y + 3.0, fac_z), (0, 0, math.pi/2), (2.8, 2.8, 2.8))
]
for src, name, loc, rot, scl in hangar_parts:
    place_instance(src, name, loc, rot, scl)

# Secondary Storage Shed
ws_x, ws_y = fac_x + 55.0, fac_y + 40.0
ws_z = get_terrain_elevation(ws_x, ws_y)
place_instance(fac_wall, "Factory_Shed_Wall_01", (ws_x - 12.0, ws_y, ws_z), (0, 0, 0), (2.5, 2.5, 2.5))
place_instance(fac_win,  "Factory_Shed_Wall_02", (ws_x + 12.0, ws_y, ws_z), (0, 0, 0), (2.5, 2.5, 2.5))
place_instance(fac_door, "Factory_Shed_Door_01", (ws_x, ws_y - 15.0, ws_z), (0, 0, math.pi/2), (2.5, 2.5, 2.5))

# Industrial Pipeline network
pipe_src = pipe_objs[0] if pipe_objs else None
if pipe_src:
    pipe_locs = [
        ((fac_x - 30.0, fac_y + 16.0, fac_z), math.pi/2, 2.2),
        ((fac_x - 30.0, fac_y - 6.0, fac_z), math.pi/2, 2.2),
        ((fac_x + 34.0, fac_y + 16.0, fac_z), math.pi/2, 2.2),
        ((fac_x + 22.0, fac_y + 28.0, fac_z), 0.0, 2.2),
        ((ws_x, ws_y - 18.0, ws_z), 0.0, 2.2),
        ((ws_x + 15.0, ws_y + 10.0, ws_z), math.pi/2, 2.2)
    ]
    for idx, (ploc, yaw, pscl) in enumerate(pipe_locs):
        place_instance(pipe_src, f"Pipe_Industrial_{idx+1:02d}", ploc, (0, 0, yaw), (pscl, pscl, pscl))

# Perimeter Chainlink Fence
fence_src = fence_objs[0] if fence_objs else None
if fence_src:
    fence_locs = [
        ((fac_x - 50.0, fac_y - 35.0, fac_z), 0.0),
        ((fac_x - 22.0, fac_y - 35.0, fac_z), 0.0),
        ((fac_x + 22.0, fac_y - 35.0, fac_z), 0.0),
        ((fac_x + 50.0, fac_y - 35.0, fac_z), 0.0),
        ((fac_x - 62.0, fac_y - 12.0, fac_z), math.pi/2),
        ((fac_x - 62.0, fac_y + 16.0, fac_z), math.pi/2),
        ((fac_x - 62.0, fac_y + 44.0, fac_z), math.pi/2),
        ((fac_x + 62.0, fac_y - 12.0, fac_z), math.pi/2),
        ((fac_x + 62.0, fac_y + 16.0, fac_z), math.pi/2)
    ]
    for idx, (floc, fyaw) in enumerate(fence_locs):
        place_instance(fence_src, f"Fence_Perimeter_{idx+1:02d}", floc, (0, 0, fyaw), (1.6, 1.6, 1.6))

# -------------------------------------------------------------------------
# 6. ZONE 3: OUTPOST & TRENCH DEFENSE REDOUBT (East: X: 220, Y: 20)
# -------------------------------------------------------------------------
print("Constructing Zone 3: Forward Outpost & Trench Redoubt...")
out_x, out_y = 220.0, 20.0
out_z = get_terrain_elevation(out_x, out_y)

barrier2_src = barrier2_objs[0] if barrier2_objs else barrier_objs[0]
ammo_src = ammo_objs[0] if ammo_objs else None

if 'thick_straight_02' in fort_dict:
    place_instance(fort_dict['thick_straight_02'], "Outpost_Bunker_W_01", (out_x - 18.0, out_y + 12.0, out_z), (0, 0, math.radians(20)))
    place_instance(fort_dict['thick_straight_02'], "Outpost_Bunker_W_02", (out_x + 18.0, out_y + 12.0, out_z), (0, 0, math.radians(-20)))
    place_instance(fort_dict['thick_straight_01'], "Outpost_Bunker_Rear", (out_x, out_y + 26.0, out_z), (0, 0, 0))

# Heavy blast barriers forming fortified gun emplacements
b_locs = [
    ((out_x - 28.0, out_y - 12.0, out_z), math.radians(35)),
    ((out_x - 14.0, out_y - 18.0, out_z), math.radians(10)),
    ((out_x + 6.0,  out_y - 18.0, out_z), math.radians(-10)),
    ((out_x + 22.0, out_y - 12.0, out_z), math.radians(-35)),
    ((out_x - 10.0, out_y - 32.0, out_z), 0.0),
    ((out_x + 10.0, out_y - 32.0, out_z), 0.0),
    ((out_x - 35.0, out_y + 8.0,  out_z), math.pi/2),
    ((out_x + 35.0, out_y + 8.0,  out_z), math.pi/2)
]
for idx, (bloc, byaw) in enumerate(b_locs):
    place_instance(barrier2_src, f"Barrier_Outpost_{idx+1:02d}", bloc, (0, 0, byaw), (2.0, 2.0, 2.0))

if ammo_src:
    ammo_locs = [
        (out_x - 12.0, out_y + 6.0, out_z + 0.3),
        (out_x - 10.2, out_y + 6.0, out_z + 0.3),
        (out_x - 11.0, out_y + 7.4, out_z + 0.3),
        (out_x + 14.0, out_y + 6.0, out_z + 0.3),
        (out_x + 15.8, out_y + 6.0, out_z + 0.3),
        (out_x + 14.8, out_y + 7.4, out_z + 0.3)
    ]
    for idx, aloc in enumerate(ammo_locs):
        place_instance(ammo_src, f"Ammo_Box_{idx+1:02d}", aloc, (0, 0, random.uniform(0, 3.14)), (2.2, 2.2, 2.2))

# -------------------------------------------------------------------------
# 7. ZONE 4: DRIED RAVINE & RUINED VIADUCT BRIDGE (Center: X: 0, Y: -80)
# -------------------------------------------------------------------------
print("Constructing Zone 4: Dried Ravine & Ruined Viaduct...")
rav_x, rav_y = 0.0, -80.0
bridge_src = pier_dict.get('section_01') or (pier_objs[0] if pier_objs else None)

if bridge_src:
    place_instance(bridge_src, "Bridge_Span_N", (rav_x, rav_y + 12.0, 0.5), (0, 0, math.pi/2), (3.0, 3.0, 3.0))
    place_instance(bridge_src, "Bridge_Span_S", (rav_x, rav_y - 12.0, 0.5), (0, 0, math.pi/2), (3.0, 3.0, 3.0))

cliff_src = cliff_objs[0] if cliff_objs else None
if cliff_src:
    cliff_locs = [
        # North bank
        ((-110.0, rav_y + 20.0, get_terrain_elevation(-110.0, rav_y + 20.0)), 0.0),
        ((-70.0,  rav_y + 22.0, get_terrain_elevation(-70.0,  rav_y + 22.0)), 0.0),
        ((-30.0,  rav_y + 23.0, get_terrain_elevation(-30.0,  rav_y + 23.0)), 0.0),
        ((35.0,   rav_y + 23.0, get_terrain_elevation(35.0,   rav_y + 23.0)), 0.0),
        ((80.0,   rav_y + 22.0, get_terrain_elevation(80.0,   rav_y + 22.0)), 0.0),
        ((125.0,  rav_y + 20.0, get_terrain_elevation(125.0,  rav_y + 20.0)), 0.0),
        # South bank
        ((-115.0, rav_y - 20.0, get_terrain_elevation(-115.0, rav_y - 20.0)), math.pi),
        ((-75.0,  rav_y - 22.0, get_terrain_elevation(-75.0,  rav_y - 22.0)), math.pi),
        ((-32.0,  rav_y - 23.0, get_terrain_elevation(-32.0,  rav_y - 23.0)), math.pi),
        ((32.0,   rav_y - 23.0, get_terrain_elevation(32.0,   rav_y - 23.0)), math.pi),
        ((75.0,   rav_y - 22.0, get_terrain_elevation(75.0,   rav_y - 22.0)), math.pi),
        ((120.0,  rav_y - 20.0, get_terrain_elevation(120.0,  rav_y - 20.0)), math.pi)
    ]
    for idx, (cloc, cyaw) in enumerate(cliff_locs):
        place_instance(cliff_src, f"Cliff_Ravine_{idx+1:02d}", cloc, (0, 0, cyaw), (4.5, 4.5, 4.5))

boulder_src = boulder_objs[0] if boulder_objs else None
if boulder_src:
    b_coords = [
        (-130.0, rav_y - 4.0), (-95.0, rav_y + 3.0), (-60.0, rav_y - 5.0), (-20.0, rav_y + 4.0),
        (20.0, rav_y - 4.0), (60.0, rav_y + 5.0), (95.0, rav_y - 3.0), (135.0, rav_y + 4.0)
    ]
    for idx, (bx, by) in enumerate(b_coords):
        bz = get_terrain_elevation(bx, by)
        s = random.uniform(2.5, 4.2)
        place_instance(boulder_src, f"Boulder_Ravine_{idx+1:02d}", (bx, by, bz), (0, 0, random.uniform(0, 6.28)), (s, s, s))

# -------------------------------------------------------------------------
# 8. ZONE 5: THE GREAT CONIFER FOREST (520 Strategic Pine Trees across 800m)
# -------------------------------------------------------------------------
print("Planting The Great Conifer Forest (520 trees across 800m)...")
random.seed(8686)

tree_locs = []

# Cluster A: Deep West Forest (x: -370 to -120, y: -350 to 350)
for _ in range(150):
    tx = random.uniform(-370, -110)
    ty = random.uniform(-350, 350)
    # Avoid factory footprint
    if not (abs(tx - fac_x) < 70 and abs(ty - fac_y) < 60):
        tree_locs.append((tx, ty))

# Cluster B: Deep East Forest (x: 110 to 370, y: -350 to 350)
for _ in range(150):
    tx = random.uniform(110, 370)
    ty = random.uniform(-350, 350)
    # Avoid outpost footprint
    if not (abs(tx - out_x) < 55 and abs(ty - out_y) < 55):
        tree_locs.append((tx, ty))

# Cluster C: South Wilderness (x: -280 to 280, y: -370 to -140)
for _ in range(130):
    tx = random.uniform(-280, 280)
    ty = random.uniform(-370, -140)
    tree_locs.append((tx, ty))

# Cluster D: Far North Mountain Pines (x: -300 to 300, y: 210 to 370)
for _ in range(90):
    tx = random.uniform(-300, 300)
    ty = random.uniform(210, 370)
    # Avoid citadel footprint
    if not (abs(tx - cit_x) < 75 and abs(ty - cit_y) < 75):
        tree_locs.append((tx, ty))

if pine_ref:
    for idx, (tx, ty) in enumerate(tree_locs):
        tz = get_terrain_elevation(tx, ty)
        s = random.uniform(0.24, 0.40) # Heights ~17m to 28m
        rot_z = random.uniform(0, math.pi * 2)
        place_instance(pine_ref, f"Pine_Tree_{idx+1:03d}", (tx, ty, tz), (0, 0, rot_z), (s, s, s))

# -------------------------------------------------------------------------
# 9. SCATTER DEADWOOD LOGS & MOSSY BOULDERS ACROSS THE WOODS
# -------------------------------------------------------------------------
print("Scattering Fallen Logs & Mossy Boulders...")
dead_src = dead_tree_objs[0] if dead_tree_objs else None
if dead_src:
    for i in range(40):
        lx = random.uniform(-330, 330)
        ly = random.uniform(-330, 330)
        lz = get_terrain_elevation(lx, ly)
        place_instance(dead_src, f"Fallen_Log_{i+1:02d}", (lx, ly, lz), (0, 0, random.uniform(0, 6.28)), (2.8, 2.8, 2.8))

if boulder_src:
    for i in range(40):
        bx = random.uniform(-340, 340)
        by = random.uniform(-340, 340)
        bz = get_terrain_elevation(bx, by)
        s = random.uniform(2.0, 3.6)
        place_instance(boulder_src, f"Boulder_Wilderness_{i+1:02d}", (bx, by, bz), (0, 0, random.uniform(0, 6.28)), (s, s, s))

# -------------------------------------------------------------------------
# 10. EXPORT MASTER GRAND WARZONE GLB
# -------------------------------------------------------------------------
map_objects = set(map_coll.objects)
for o in list(bpy.data.objects):
    if o not in map_objects:
        bpy.data.objects.remove(o, do_unlink=True)

out_glb = r"c:\86\86_Combat_Arena\assets\environment\sector86_grand_warzone.glb"
print(f"\nExporting Grand Warzone battlefield ({len(map_coll.objects)} objects) to:\n{out_glb}...")

bpy.ops.export_scene.gltf(
    filepath=out_glb,
    export_format='GLB',
    use_selection=False,
    export_yup=True,
    export_apply=False,
    export_materials='EXPORT'
)

print("\n=====================================================================")
print(" MASTER GRAND WARZONE MAP (800m x 800m) EXPORTED SUCCESSFULLY!")
print("=====================================================================")
