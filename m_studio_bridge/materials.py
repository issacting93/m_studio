"""
Convert M-STUDIO colorway hex values to Blender materials.
"""

import bpy


# Maps pattern piece names to colorway roles
PIECE_COLOR_ROLES = {
    "BACK": "primary",
    "FRONT": "primary",
    "FRONT_L": "primary",
    "FRONT_R": "primary",
    "SLEEVE_L": "primary",
    "SLEEVE_R": "primary",
    "COLLAR": "secondary",
    "HOOD": "secondary",
}


def hex_to_linear_rgb(hex_str):
    """Convert #RRGGBB hex string to linear sRGB tuple for Blender."""
    hex_str = hex_str.lstrip("#")
    if len(hex_str) != 6:
        return (0.5, 0.5, 0.5)
    r = int(hex_str[0:2], 16) / 255.0
    g = int(hex_str[2:4], 16) / 255.0
    b = int(hex_str[4:6], 16) / 255.0

    def to_linear(v):
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    return (to_linear(r), to_linear(g), to_linear(b))


def apply_colorway(objects, colorway, garment_name="MSTUDIO", blocking=None):
    """
    Create and assign materials to pattern piece objects based on colorway.

    Args:
        objects: dict[str, bpy.types.Object] — pattern curve objects
        colorway: dict with keys like "primary", "secondary", "accent", "graphic"
                  OR dict with "primaryHex", "secondaryHex", etc.
        garment_name: prefix for material names
        blocking: optional dict mapping panel names to color roles (from .mstudio package)
    """
    # Normalize colorway keys (handle both formats)
    colors = _normalize_colorway(colorway)

    # Build piece-to-role mapping from blocking if provided
    piece_roles = dict(PIECE_COLOR_ROLES)
    if blocking:
        # Map blocking panel names to pattern piece names
        _PANEL_TO_PIECES = {
            "body": ["BACK", "FRONT", "FRONT_L", "FRONT_R"],
            "sleeves": ["SLEEVE_L", "SLEEVE_R"],
            "collar": ["COLLAR"],
            "hood": ["HOOD"],
        }
        for panel, role in blocking.items():
            for piece in _PANEL_TO_PIECES.get(panel, []):
                piece_roles[piece] = role

    for piece_name, obj in objects.items():
        role = piece_roles.get(piece_name, "primary")
        hex_color = colors.get(role, colors.get("primary", "#808080"))
        rgb = hex_to_linear_rgb(hex_color)

        mat_name = f"{garment_name}_{piece_name}"
        mat = bpy.data.materials.new(name=mat_name)
        mat.use_nodes = True

        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
            bsdf.inputs["Metallic"].default_value = 0.0
            bsdf.inputs["Roughness"].default_value = 0.75
            # Specular IOR Level (Blender 4.0+) or Specular (3.x)
            if "Specular IOR Level" in bsdf.inputs:
                bsdf.inputs["Specular IOR Level"].default_value = 0.2
            elif "Specular" in bsdf.inputs:
                bsdf.inputs["Specular"].default_value = 0.2

        obj.data.materials.append(mat)


def _normalize_colorway(colorway):
    """Handle multiple colorway dict formats from M-STUDIO."""
    if not colorway:
        return {"primary": "#1a1a1a", "secondary": "#2a2a2a", "accent": "#d63d2e", "graphic": "#ffffff"}

    # If it already has "primary" key directly as hex
    if "primary" in colorway and isinstance(colorway["primary"], str) and colorway["primary"].startswith("#"):
        return colorway

    # If using "primaryHex" format (from Swift ColorBlocking)
    if "primaryHex" in colorway:
        return {
            "primary": colorway.get("primaryHex", "#1a1a1a"),
            "secondary": colorway.get("secondaryHex", "#2a2a2a"),
            "accent": colorway.get("accentHex", "#d63d2e"),
            "graphic": colorway.get("graphicHex", "#ffffff"),
        }

    # Fallback: try to find any hex values
    return {"primary": "#1a1a1a", "secondary": "#2a2a2a", "accent": "#d63d2e", "graphic": "#ffffff"}
