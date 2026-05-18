"""
garment_tool integration: detect the addon and register patterns/sewings/presets.
"""

import bpy
from . import fabric_presets


def is_available():
    """Check if garment_tool addon is installed and enabled."""
    return "garment_tool" in bpy.context.preferences.addons


def register_garment(name, objects, sewings, fabric_id):
    """
    Register a complete garment with garment_tool.

    Args:
        name: Garment display name (e.g., "M-NRG-001")
        objects: dict[str, bpy.types.Object] — pattern curve objects
        sewings: list[dict] — sewing definitions from sewing_map
        fabric_id: M-STUDIO fabric ID for cloth preset

    Returns:
        True if registration succeeded, False otherwise.
    """
    if not is_available():
        return False

    scene = bpy.context.scene

    # Verify garment_tool data structures exist
    if not hasattr(scene, "cloth_garment_data"):
        return False

    # Create garment entry
    garment = scene.cloth_garment_data.add()
    garment.name = name

    # Set garment index to the new entry
    if hasattr(scene, "garment_index"):
        scene.garment_index = len(scene.cloth_garment_data) - 1

    # Register each pattern piece
    for piece_name, obj in objects.items():
        pattern_entry = garment.sewing_patterns.add()
        pattern_entry.pattern_obj = obj
        pattern_entry.is_enabled = True

    # Register sewings
    for sew_def in sewings:
        source_name = sew_def["source"]
        target_name = sew_def["target"]

        if source_name not in objects or target_name not in objects:
            continue

        sewing = garment.garment_sewings.add()
        sewing.source_obj = objects[source_name]
        sewing.target_obj = objects[target_name]
        sewing.from_spline_idx = 0
        sewing.to_spline_idx = 0
        sewing.from_segment_idx = sew_def["from_seg"]
        sewing.to_segment_idx = sew_def["to_seg"]
        sewing.flip = sew_def.get("flip", False)

    # Apply cloth preset
    _apply_cloth_preset(garment, fabric_id)

    return True


def _apply_cloth_preset(garment, fabric_id):
    """Create a local cloth preset from M-STUDIO fabric properties."""
    scene = bpy.context.scene

    if not hasattr(scene, "garment_props"):
        return

    props = scene.garment_props
    if not hasattr(props, "local_cloth_presets"):
        return

    preset_data = fabric_presets.get_preset(fabric_id)
    preset_name = preset_data["name"]

    # Check if preset already exists
    existing = None
    for p in props.local_cloth_presets:
        if p.name == preset_name:
            existing = p
            break

    if existing is None:
        existing = props.local_cloth_presets.add()
        existing.name = preset_name

    # Set properties
    cloth_props = [
        "mass", "air_damping", "sewing_force",
        "tension_stiffness", "compression_stiffness", "shear_stiffness", "bending_stiffness",
        "tension_damping", "compression_damping", "shear_damping", "bending_damping",
    ]
    for prop_name in cloth_props:
        if prop_name in preset_data and hasattr(existing, prop_name):
            setattr(existing, prop_name, preset_data[prop_name])

    # Assign to garment
    if hasattr(garment, "default_cloth_preset"):
        garment.default_cloth_preset = preset_name
