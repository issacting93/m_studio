"""
M-STUDIO cloth simulation pipeline.
Replaces garment_tool dependency with native Blender cloth + sewing springs.

Workflow:
1. Convert pattern curves → triangulated mesh
2. Join all pieces into one mesh (preserving UV islands)
3. Add sewing springs as loose edges between matching boundary vertices
4. Add cloth modifier with sewing enabled
5. Create collision mannequin
6. Simulate
"""

import math

import bmesh
import bpy
from mathutils import Vector

from . import fabric_presets


# ---------------------------------------------------------------------------
# 1. Curves → Mesh
# ---------------------------------------------------------------------------

def curves_to_mesh(objects, target_edge_length=0.005):
    """
    Convert curve objects to triangulated mesh objects.

    Args:
        objects: dict[str, bpy.types.Object] — curve objects from import
        target_edge_length: target edge length in Blender units (meters)

    Returns:
        dict[str, bpy.types.Object] — mesh objects (same names)
    """
    mesh_objects = {}

    for name, obj in objects.items():
        # Select and convert
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target="MESH")

        # Subdivide for cloth sim resolution
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")

        # Subdivide until edges are near target length
        for _ in range(6):
            bm = bmesh.from_edit_mesh(obj.data)
            max_edge = max((e.calc_length() for e in bm.edges), default=0)
            bm.free()
            if max_edge <= target_edge_length * 2:
                break
            bpy.ops.mesh.subdivide(number_cuts=1)

        # Triangulate
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.quads_convert_to_tris()

        bpy.ops.object.mode_set(mode="OBJECT")

        # Assign UV from XY coordinates (pattern piece = UV island)
        _assign_pattern_uv(obj)

        mesh_objects[name] = obj

    return mesh_objects


def _assign_pattern_uv(obj):
    """Assign UV coordinates from XY vertex positions (normalized to piece bounds)."""
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active.data

    # Compute bounds
    xs = [v.co.x for v in mesh.vertices]
    ys = [v.co.y for v in mesh.vertices]
    if not xs or not ys:
        return
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)
    w = x_max - x_min or 1.0
    h = y_max - y_min or 1.0

    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            v = mesh.vertices[mesh.loops[loop_idx].vertex_index]
            uv_layer[loop_idx].uv = (
                (v.co.x - x_min) / w,
                (v.co.y - y_min) / h,
            )


# ---------------------------------------------------------------------------
# 2. Join + Sewing Springs
# ---------------------------------------------------------------------------

def join_and_sew(mesh_objects, sewings):
    """
    Join mesh pieces into one object and add sewing springs as loose edges.

    Args:
        mesh_objects: dict[str, bpy.types.Object]
        sewings: list of sewing dicts from sewing_map.get_sewings()

    Returns:
        bpy.types.Object — the joined garment mesh
    """
    if not mesh_objects:
        return None

    # Track which vertices belong to which piece (before join)
    piece_boundaries = {}
    for name, obj in mesh_objects.items():
        piece_boundaries[name] = _get_boundary_segments(obj)

    # Join all pieces into one mesh
    bpy.ops.object.select_all(action="DESELECT")
    first_obj = None
    for name, obj in mesh_objects.items():
        obj.select_set(True)
        if first_obj is None:
            first_obj = obj
    bpy.context.view_layer.objects.active = first_obj
    bpy.ops.object.join()
    garment = first_obj

    # Add sewing springs as loose edges
    bm = bmesh.new()
    bm.from_mesh(garment.data)
    bm.verts.ensure_lookup_table()

    sewing_count = 0
    for sewing in sewings:
        source = sewing["source"]
        target = sewing["target"]
        from_seg = sewing["from_seg"]
        to_seg = sewing["to_seg"]
        flip = sewing.get("flip", False)

        if source not in piece_boundaries or target not in piece_boundaries:
            continue

        source_verts = piece_boundaries[source].get(from_seg, [])
        target_verts = piece_boundaries[target].get(to_seg, [])

        if not source_verts or not target_verts:
            continue

        if flip:
            target_verts = list(reversed(target_verts))

        # Sample matching pairs along both edges
        pairs = _match_boundary_verts(source_verts, target_verts, bm)
        for v1, v2 in pairs:
            if v1 != v2:
                try:
                    bm.edges.new([v1, v2])
                    sewing_count += 1
                except ValueError:
                    pass  # edge already exists

    bm.to_mesh(garment.data)
    bm.free()
    garment.data.update()

    garment.name = "MSTUDIO_Garment"
    return garment


def _get_boundary_segments(obj):
    """
    Get boundary vertex world positions organized by segment index.
    For a 4-point rectangular piece: seg 0=bottom, 1=right, 2=top, 3=left.

    Returns dict[segment_index, list[(world_x, world_y, world_z, vert_index_global)]]
    """
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()

    # Find boundary edges (edges with only one face)
    boundary_verts = set()
    for e in bm.edges:
        if len(e.link_faces) <= 1:
            for v in e.verts:
                boundary_verts.add(v.index)

    # Compute bounding box
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)
    w = x_max - x_min or 1.0
    h = y_max - y_min or 1.0

    # Classify boundary vertices into segments by position
    segments = {0: [], 1: [], 2: [], 3: []}
    tolerance = 0.15  # fraction of dimension

    for vi in boundary_verts:
        v = bm.verts[vi]
        nx = (v.co.x - x_min) / w  # 0-1 normalized
        ny = (v.co.y - y_min) / h

        # World position for later matching
        world_pos = obj.matrix_world @ v.co

        if ny < tolerance:  # bottom
            segments[0].append((world_pos.x, world_pos.y, world_pos.z, vi))
        elif nx > 1 - tolerance:  # right
            segments[1].append((world_pos.x, world_pos.y, world_pos.z, vi))
        elif ny > 1 - tolerance:  # top
            segments[2].append((world_pos.x, world_pos.y, world_pos.z, vi))
        elif nx < tolerance:  # left
            segments[3].append((world_pos.x, world_pos.y, world_pos.z, vi))

    # Sort each segment by position along its edge
    segments[0].sort(key=lambda p: p[0])  # bottom: left to right
    segments[1].sort(key=lambda p: p[1])  # right: bottom to top
    segments[2].sort(key=lambda p: p[0])  # top: left to right
    segments[3].sort(key=lambda p: p[1])  # left: bottom to top

    bm.free()
    return segments


def _match_boundary_verts(source_verts, target_verts, bm):
    """
    Match vertices from two boundary segments for sewing.
    Uses uniform sampling to create matching pairs even when vertex counts differ.
    """
    pairs = []
    n = min(len(source_verts), len(target_verts))
    if n == 0:
        return pairs

    # Sample at matching intervals
    for i in range(n):
        si = int(i * len(source_verts) / n)
        ti = int(i * len(target_verts) / n)
        sv = source_verts[min(si, len(source_verts) - 1)]
        tv = target_verts[min(ti, len(target_verts) - 1)]

        # Get bmesh verts by index
        try:
            bv1 = bm.verts[sv[3]]  # index stored in position 3
            bv2 = bm.verts[tv[3]]
            pairs.append((bv1, bv2))
        except (IndexError, KeyError):
            continue

    return pairs


# ---------------------------------------------------------------------------
# 3. Cloth Simulation Setup
# ---------------------------------------------------------------------------

def setup_cloth(garment, fabric_id="ripstop70"):
    """
    Add cloth modifier with sewing springs enabled.

    Args:
        garment: the joined garment mesh object
        fabric_id: fabric preset ID from M-STUDIO
    """
    preset = fabric_presets.get_preset(fabric_id)

    # Remove existing cloth modifiers
    for mod in list(garment.modifiers):
        if mod.type == "CLOTH":
            garment.modifiers.remove(mod)

    cloth = garment.modifiers.new(name="Cloth", type="CLOTH")
    s = cloth.settings

    # Fabric physics
    s.mass = preset["mass"]
    s.tension_stiffness = preset["tension_stiffness"]
    s.compression_stiffness = preset["compression_stiffness"]
    s.shear_stiffness = preset["shear_stiffness"]
    s.bending_stiffness = preset["bending_stiffness"]
    s.tension_damping = preset["tension_damping"]
    s.compression_damping = preset["compression_damping"]
    s.shear_damping = preset["shear_damping"]
    s.bending_damping = preset["bending_damping"]
    s.air_damping = preset["air_damping"]

    # Sewing springs
    s.use_sewing_springs = True
    s.sewing_force_max = preset.get("sewing_force", 20.0)

    # Simulation quality
    s.quality = 12
    s.time_scale = 1.0

    # Collision settings
    cloth.collision_settings.use_collision = True
    cloth.collision_settings.collision_quality = 5
    cloth.collision_settings.distance_min = 0.002

    return cloth


# ---------------------------------------------------------------------------
# 4. Mannequin
# ---------------------------------------------------------------------------

def create_mannequin(measurements=None, scale=0.01):
    """
    Create a simple collision mannequin.

    Args:
        measurements: dict with bodyWidth, bodyLength etc. (cm)
        scale: cm to Blender units
    """
    body_w = (measurements or {}).get("bodyWidth", 52) * scale
    body_h = (measurements or {}).get("bodyLength", 70) * scale
    shoulder_w = (measurements or {}).get("shoulderWidth", 46) * scale

    # Torso cylinder
    bpy.ops.mesh.primitive_cylinder_add(
        radius=body_w / 2 * 0.6,
        depth=body_h * 0.8,
        location=(0, 0, body_h * 0.5),
    )
    torso = bpy.context.active_object
    torso.name = "MSTUDIO_Mannequin_Torso"

    # Scale to oval (narrower front-to-back)
    torso.scale.y = 0.7

    # Head sphere
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=body_w * 0.18,
        location=(0, 0, body_h * 0.95),
    )
    head = bpy.context.active_object
    head.name = "MSTUDIO_Mannequin_Head"

    # Collision modifier on both
    for obj in [torso, head]:
        col = obj.modifiers.new(name="Collision", type="COLLISION")
        col.settings.thickness_outer = 0.003
        col.settings.cloth_friction = 5.0

    # Parent head to torso
    head.parent = torso

    return torso


# ---------------------------------------------------------------------------
# 5. Position Garment Above Mannequin
# ---------------------------------------------------------------------------

def position_for_drape(garment, mannequin):
    """Move garment pieces above the mannequin for draping."""
    # Get mannequin top
    mann_top = mannequin.location.z + mannequin.dimensions.z / 2

    # Move garment above
    garment.location.z = mann_top + 0.3  # 30cm above mannequin top


# ---------------------------------------------------------------------------
# 6. Scene Setup for Rendering
# ---------------------------------------------------------------------------

def setup_render_scene():
    """Configure Cycles render + studio lighting."""
    scene = bpy.context.scene

    # Cycles
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 256
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.01

    # Color management
    scene.view_settings.view_transform = "AgX"

    # Resolution
    scene.render.resolution_x = 3840
    scene.render.resolution_y = 2160
    scene.render.resolution_percentage = 100

    # Background
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (0.85, 0.83, 0.80, 1.0)
        bg.inputs["Strength"].default_value = 1.0

    # Key light
    bpy.ops.object.light_add(type="AREA", location=(2, -2, 3))
    key = bpy.context.active_object
    key.name = "MSTUDIO_Key_Light"
    key.data.energy = 200
    key.data.size = 2.0

    # Fill light
    bpy.ops.object.light_add(type="AREA", location=(-2, 2, 2))
    fill = bpy.context.active_object
    fill.name = "MSTUDIO_Fill_Light"
    fill.data.energy = 80
    fill.data.size = 1.5

    # Camera — front 3/4 view
    bpy.ops.object.camera_add(location=(1.5, -2.5, 1.0))
    cam = bpy.context.active_object
    cam.name = "MSTUDIO_Camera"
    cam.data.lens = 85

    # Point camera at garment center
    constraint = cam.constraints.new(type="TRACK_TO")
    # Create an empty at center for the camera to track
    bpy.ops.object.empty_add(location=(0, 0, 0.5))
    target = bpy.context.active_object
    target.name = "MSTUDIO_Camera_Target"
    constraint.target = target
    constraint.track_axis = "TRACK_NEGATIVE_Z"
    constraint.up_axis = "UP_Y"

    scene.camera = cam
