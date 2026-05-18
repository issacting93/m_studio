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
    Creates a shoulder pin group so the garment hangs instead of falling.
    Keyframes sewing force from 0 → target over 20 frames for stability.
    """
    preset = fabric_presets.get_preset(fabric_id)

    # Remove existing cloth modifiers
    for mod in list(garment.modifiers):
        if mod.type == "CLOTH":
            garment.modifiers.remove(mod)

    # --- Create shoulder pin group ---
    _create_pin_group(garment)

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

    # Pin group — keeps shoulders in place
    if "MSTUDIO_Pin" in garment.vertex_groups:
        s.vertex_group_mass = "MSTUDIO_Pin"

    # Simulation quality
    s.quality = 12
    s.time_scale = 1.0

    # Collision settings
    cloth.collision_settings.use_collision = True
    cloth.collision_settings.collision_quality = 5
    cloth.collision_settings.distance_min = 0.002

    # --- Keyframe sewing force: 0 → target over 20 frames ---
    scene = bpy.context.scene
    scene.frame_set(1)
    s.sewing_force_max = 0.0
    s.keyframe_insert(data_path="sewing_force_max", frame=1)
    target_force = preset.get("sewing_force", 20.0)
    s.sewing_force_max = target_force
    s.keyframe_insert(data_path="sewing_force_max", frame=20)

    return cloth


def _create_pin_group(garment):
    """
    Create a vertex group that pins the topmost vertices (shoulder area).
    Weight = 1.0 for pinned (immovable), 0.0 for free.
    In Blender cloth, pin weight 1.0 = fully pinned, 0.0 = fully simulated.
    """
    mesh = garment.data

    # Find the vertical extent of the garment
    zs = [v.co.z for v in mesh.vertices]
    if not zs:
        return
    z_max = max(zs)
    z_min = min(zs)
    z_range = z_max - z_min
    if z_range == 0:
        return

    # Pin the top 5% of vertices (shoulder/neckline area)
    pin_threshold = z_max - z_range * 0.05

    # Create or get the pin group
    if "MSTUDIO_Pin" in garment.vertex_groups:
        garment.vertex_groups.remove(garment.vertex_groups["MSTUDIO_Pin"])
    pin_group = garment.vertex_groups.new(name="MSTUDIO_Pin")

    for v in mesh.vertices:
        if v.co.z >= pin_threshold:
            # Fully pinned
            pin_group.add([v.index], 1.0, "REPLACE")
        else:
            # Fully free
            pin_group.add([v.index], 0.0, "REPLACE")


# ---------------------------------------------------------------------------
# 4. Mannequin
# ---------------------------------------------------------------------------

def create_mannequin(measurements=None, scale=0.01):
    """
    Create a collision mannequin. Uses MPFB2 if available, otherwise falls
    back to a basic primitive body.

    Args:
        measurements: dict with bodyWidth, bodyLength etc. (cm)
        scale: cm to Blender units

    Returns:
        bpy.types.Object — the mannequin body (with Collision modifier)
    """
    # Try MPFB2 first
    body = _try_mpfb2_body()
    if body:
        # Add collision
        _add_collision(body)
        body.name = "MSTUDIO_Mannequin"
        return body

    # Fallback: primitive mannequin
    return _create_primitive_mannequin(measurements, scale)


def _try_mpfb2_body():
    """Try to generate a body using MPFB2 if installed."""
    try:
        from mpfb.services.humanservice import HumanService
        from mpfb.entities.humanproperties import HumanProperties

        # Create a default human
        bpy.ops.mpfb.create_human()
        body = bpy.context.active_object
        if body:
            # Scale to roughly match garment proportions
            # MPFB generates at real-world scale (meters)
            return body
    except (ImportError, AttributeError):
        pass

    # Try the operator directly (simpler MPFB2 versions)
    try:
        if hasattr(bpy.ops, "mpfb") and hasattr(bpy.ops.mpfb, "create_human"):
            bpy.ops.mpfb.create_human()
            body = bpy.context.active_object
            if body and body.type == "MESH":
                return body
    except Exception:
        pass

    return None


def _create_primitive_mannequin(measurements=None, scale=0.01):
    """Fallback: build a mannequin from primitives."""
    body_w = (measurements or {}).get("bodyWidth", 52) * scale
    body_h = (measurements or {}).get("bodyLength", 70) * scale
    shoulder_w = (measurements or {}).get("shoulderWidth", 46) * scale

    # --- Torso ---
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32,
        radius=body_w / 2 * 0.55,
        depth=body_h * 0.65,
        location=(0, 0, body_h * 0.65),
    )
    torso = bpy.context.active_object
    torso.name = "MSTUDIO_Mannequin_Torso"
    torso.scale.y = 0.65  # oval cross-section

    # --- Shoulders (wider cylinder at top) ---
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=shoulder_w / 2 * scale,
        depth=body_h * 0.06,
        location=(0, 0, body_h * 0.95),
    )
    shoulders = bpy.context.active_object
    shoulders.name = "MSTUDIO_Mannequin_Shoulders"
    shoulders.scale.y = 0.4

    # --- Hips (wider at bottom) ---
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=body_w / 2 * 0.5,
        depth=body_h * 0.15,
        location=(0, 0, body_h * 0.35),
    )
    hips = bpy.context.active_object
    hips.name = "MSTUDIO_Mannequin_Hips"
    hips.scale.y = 0.7

    # --- Head ---
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=body_w * 0.16,
        location=(0, 0, body_h * 1.05),
    )
    head = bpy.context.active_object
    head.name = "MSTUDIO_Mannequin_Head"

    # --- Neck ---
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=body_w * 0.08,
        depth=body_h * 0.08,
        location=(0, 0, body_h * 0.99),
    )
    neck = bpy.context.active_object
    neck.name = "MSTUDIO_Mannequin_Neck"

    # --- Arms (cylinders angled outward) ---
    arm_len = (measurements or {}).get("sleeveLength", 62) * scale
    for side, sign in [("L", -1), ("R", 1)]:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=body_w * 0.07,
            depth=arm_len,
            location=(sign * shoulder_w / 2 * scale, 0, body_h * 0.75),
        )
        arm = bpy.context.active_object
        arm.name = f"MSTUDIO_Mannequin_Arm_{side}"
        # Angle arms slightly down and out
        arm.rotation_euler[1] = sign * math.radians(15)
        arm.parent = torso

    # Join all parts into one mesh
    parts = [obj for obj in bpy.data.objects if obj.name.startswith("MSTUDIO_Mannequin_")]
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = torso
    bpy.ops.object.join()

    torso.name = "MSTUDIO_Mannequin"

    # Apply transforms
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Smooth shading
    bpy.ops.object.shade_smooth()

    # Add collision
    _add_collision(torso)

    return torso


def _add_collision(obj):
    """Add collision modifier to an object."""
    # Remove existing collision modifiers
    for mod in list(obj.modifiers):
        if mod.type == "COLLISION":
            obj.modifiers.remove(mod)

    col = obj.modifiers.new(name="Collision", type="COLLISION")
    col.settings.thickness_outer = 0.005
    col.settings.thickness_inner = 0.002
    col.settings.cloth_friction = 15.0
    col.settings.damping = 0.5


# ---------------------------------------------------------------------------
# 5. Position Garment Above Mannequin
# ---------------------------------------------------------------------------

def position_for_drape(garment, mannequin):
    """
    Position garment pieces around the mannequin for draping.

    The pattern pieces start flat in the XY plane. We:
    1. Rotate to vertical (XZ plane)
    2. Center on the mannequin
    3. Offset slightly outward so the pieces surround the body
       (the sewing springs + collision will pull them into shape)
    """
    bpy.ops.object.select_all(action="DESELECT")
    garment.select_set(True)
    bpy.context.view_layer.objects.active = garment

    # Rotate from flat to vertical
    garment.rotation_euler[0] = math.radians(90)
    bpy.ops.object.transform_apply(rotation=True)

    # Get mannequin bounds
    mann_bounds = _get_bounds(mannequin)
    mann_center = Vector((
        (mann_bounds[0] + mann_bounds[3]) / 2,
        (mann_bounds[1] + mann_bounds[4]) / 2,
        (mann_bounds[2] + mann_bounds[5]) / 2,
    ))
    mann_height = mann_bounds[5] - mann_bounds[2]

    # Get garment bounds
    g_bounds = _get_bounds(garment)
    g_center = Vector((
        (g_bounds[0] + g_bounds[3]) / 2,
        (g_bounds[1] + g_bounds[4]) / 2,
        (g_bounds[2] + g_bounds[5]) / 2,
    ))
    g_height = g_bounds[5] - g_bounds[2]

    # Position garment centered on mannequin
    # Align the top of the garment with the top of the mannequin (shoulders)
    garment.location.x = mann_center.x - g_center.x
    garment.location.y = mann_center.y - g_center.y
    garment.location.z = (mann_bounds[5] - g_bounds[5]) + 0.02  # top-align + small offset

    # Apply location into mesh
    bpy.ops.object.transform_apply(location=True)

    # Push vertices slightly outward from mannequin center to wrap around body
    _wrap_around_body(garment, mann_center, radius_offset=0.03)


def _wrap_around_body(garment, body_center, radius_offset=0.03):
    """
    Push garment vertices slightly outward from the body center axis.
    This ensures the flat pieces surround the body instead of intersecting it.
    """
    mesh = garment.data
    for v in mesh.vertices:
        # Distance from body center axis (XY only)
        dx = v.co.x - body_center.x
        dy = v.co.y - body_center.y
        dist = math.sqrt(dx * dx + dy * dy)

        if dist < 0.001:
            # Vertex right on the axis — push forward
            v.co.y += radius_offset
        else:
            # Push outward from center axis
            scale = (dist + radius_offset) / dist
            v.co.x = body_center.x + dx * scale
            v.co.y = body_center.y + dy * scale

    mesh.update()


def _get_bounds(obj):
    """Get world-space bounding box as (min_x, min_y, min_z, max_x, max_y, max_z)."""
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    xs = [c.x for c in corners]
    ys = [c.y for c in corners]
    zs = [c.z for c in corners]
    return (min(xs), min(ys), min(zs), max(xs), max(ys), max(zs))


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
