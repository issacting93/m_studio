"""
Convert PieceData (coordinates in cm) to Blender 2D Bezier curve objects.
"""

import bpy


def build_curve(name, piece_data, scale=0.01, collection=None):
    """
    Create a 2D Bezier curve object from a PieceData instance.

    Args:
        name: Object name (e.g., "BACK", "SLEEVE_L")
        piece_data: PieceData with points, handle_types, offset
        scale: Conversion factor (0.01 = cm to meters)
        collection: Blender collection to link to (defaults to active)

    Returns:
        The created bpy.types.Object
    """
    curve = bpy.data.curves.new(name=name, type="CURVE")
    curve.dimensions = "2D"
    curve.fill_mode = "BOTH"

    spline = curve.splines.new("BEZIER")
    spline.use_cyclic_u = True

    points = piece_data.points
    handle_types = piece_data.handle_types
    ox, oy = piece_data.offset

    # Add control points (one already exists by default)
    spline.bezier_points.add(count=len(points) - 1)

    for i, (x, y) in enumerate(points):
        pt = spline.bezier_points[i]
        pt.co = ((x + ox) * scale, (y + oy) * scale, 0.0)
        ht = handle_types[i] if i < len(handle_types) else "VECTOR"
        pt.handle_left_type = ht
        pt.handle_right_type = ht

    obj = bpy.data.objects.new(name, curve)

    if collection is None:
        collection = bpy.context.collection
    collection.objects.link(obj)

    return obj


def build_all_curves(pieces, scale=0.01, collection_name=None):
    """
    Build Blender curve objects for all pattern pieces.

    Args:
        pieces: dict[str, PieceData] from pattern_geometry.generate_pieces()
        scale: cm-to-Blender conversion (0.01 for meters)
        collection_name: Optional name for a new collection to contain pieces

    Returns:
        dict[str, bpy.types.Object] mapping piece names to Blender objects
    """
    # Create a dedicated collection if requested
    if collection_name:
        collection = bpy.data.collections.new(collection_name)
        bpy.context.scene.collection.children.link(collection)
    else:
        collection = bpy.context.collection

    objects = {}
    for name, piece_data in pieces.items():
        obj = build_curve(name, piece_data, scale=scale, collection=collection)
        objects[name] = obj

    return objects
