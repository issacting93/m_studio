# Cloth simulation presets mapped from M-STUDIO Fabric enum values.
# Physics values sourced from Fabric.swift (clothMass, clothTensionStiffness, clothBendingStiffness).

FABRIC_PRESETS = {
    "ripstop70": {
        "name": "Ripstop 70D",
        "mass": 0.07,
        "tension_stiffness": 15.0,
        "compression_stiffness": 15.0,
        "shear_stiffness": 8.0,
        "bending_stiffness": 0.5,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 0.5,
        "air_damping": 1.0,
        "sewing_force": 20.0,
    },
    "taslan": {
        "name": "Taslan 228T",
        "mass": 0.12,
        "tension_stiffness": 25.0,
        "compression_stiffness": 25.0,
        "shear_stiffness": 12.0,
        "bending_stiffness": 1.5,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 1.0,
        "air_damping": 1.0,
        "sewing_force": 20.0,
    },
    "shell3l": {
        "name": "3L Shell",
        "mass": 0.21,
        "tension_stiffness": 40.0,
        "compression_stiffness": 40.0,
        "shear_stiffness": 20.0,
        "bending_stiffness": 5.0,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 2.0,
        "air_damping": 1.0,
        "sewing_force": 25.0,
    },
    "cordura": {
        "name": "Cordura 500D",
        "mass": 0.32,
        "tension_stiffness": 60.0,
        "compression_stiffness": 60.0,
        "shear_stiffness": 30.0,
        "bending_stiffness": 8.0,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 3.0,
        "air_damping": 1.0,
        "sewing_force": 30.0,
    },
    "twillpoly": {
        "name": "Poly Twill",
        "mass": 0.18,
        "tension_stiffness": 30.0,
        "compression_stiffness": 30.0,
        "shear_stiffness": 15.0,
        "bending_stiffness": 3.0,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 1.5,
        "air_damping": 1.0,
        "sewing_force": 20.0,
    },
    "meshmil": {
        "name": "Mil Mesh",
        "mass": 0.09,
        "tension_stiffness": 8.0,
        "compression_stiffness": 8.0,
        "shear_stiffness": 4.0,
        "bending_stiffness": 0.2,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 0.3,
        "air_damping": 1.0,
        "sewing_force": 15.0,
    },
}

# garment_tool LocalMainClothPreset property names
CLOTH_PROP_NAMES = [
    "mass",
    "air_damping",
    "sewing_force",
    "tension_stiffness",
    "compression_stiffness",
    "shear_stiffness",
    "bending_stiffness",
    "tension_damping",
    "compression_damping",
    "shear_damping",
    "bending_damping",
]


def get_preset(fabric_id):
    """Get cloth preset dict for a fabric ID. Falls back to ripstop70."""
    return FABRIC_PRESETS.get(fabric_id, FABRIC_PRESETS["ripstop70"])


def apply_to_cloth_modifier(obj, fabric_id):
    """Apply fabric physics directly to a Blender cloth modifier (no garment_tool)."""
    import bpy

    preset = get_preset(fabric_id)
    for mod in obj.modifiers:
        if mod.type == "CLOTH":
            settings = mod.settings
            settings.mass = preset["mass"]
            settings.tension_stiffness = preset["tension_stiffness"]
            settings.compression_stiffness = preset["compression_stiffness"]
            settings.shear_stiffness = preset["shear_stiffness"]
            settings.bending_stiffness = preset["bending_stiffness"]
            settings.tension_damping = preset["tension_damping"]
            settings.compression_damping = preset["compression_damping"]
            settings.shear_damping = preset["shear_damping"]
            settings.bending_damping = preset["bending_damping"]
            settings.air_damping = preset["air_damping"]
            break
