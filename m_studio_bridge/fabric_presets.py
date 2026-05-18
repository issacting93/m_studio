# Cloth simulation presets for M-STUDIO Bridge.
#
# Two categories:
#   TECHWEAR — M-STUDIO fabrics from Fabric.swift (ripstop, cordura, etc.)
#   STANDARD — common fashion fabrics calibrated against Blender's built-in
#              presets (silk, cotton, denim, leather, rubber) and extended
#              with jersey, fleece, canvas, wool, organza, chiffon, etc.
#
# All values use Blender 4.x cloth modifier API:
#   tension/compression/shear/bending _stiffness and _damping
#
# Reference: Blender source release/scripts/presets/cloth/*.py
#   Silk:    mass=0.15, structural=5,  bending=0.05, damping=0,  air=1
#   Cotton:  mass=0.30, structural=15, bending=0.50, damping=5,  air=1
#   Denim:   mass=1.00, structural=40, bending=10.0, damping=25, air=1
#   Leather: mass=0.40, structural=80, bending=150,  damping=25, air=1
#   Rubber:  mass=3.00, structural=15, bending=25.0, damping=25, air=1

FABRIC_PRESETS = {

    # ── TECHWEAR FABRICS (from M-STUDIO Fabric.swift) ─────────────────────

    "ripstop70": {
        "name": "Ripstop 70D",
        "category": "techwear",
        "gsm": 70,
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
        "category": "techwear",
        "gsm": 120,
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
        "category": "techwear",
        "gsm": 210,
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
        "category": "techwear",
        "gsm": 320,
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
        "category": "techwear",
        "gsm": 180,
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
        "category": "techwear",
        "gsm": 90,
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

    # ── STANDARD FABRICS (calibrated from Blender built-ins + real gsm) ───

    "silk": {
        "name": "Silk",
        "category": "standard",
        "gsm": 40,
        "mass": 0.04,
        "tension_stiffness": 5.0,
        "compression_stiffness": 5.0,
        "shear_stiffness": 3.0,
        "bending_stiffness": 0.05,
        "tension_damping": 0.0,
        "compression_damping": 0.0,
        "shear_damping": 0.0,
        "bending_damping": 0.0,
        "air_damping": 1.0,
        "sewing_force": 15.0,
    },
    "chiffon": {
        "name": "Chiffon",
        "category": "standard",
        "gsm": 30,
        "mass": 0.03,
        "tension_stiffness": 4.0,
        "compression_stiffness": 4.0,
        "shear_stiffness": 2.0,
        "bending_stiffness": 0.02,
        "tension_damping": 0.0,
        "compression_damping": 0.0,
        "shear_damping": 0.0,
        "bending_damping": 0.0,
        "air_damping": 1.5,
        "sewing_force": 10.0,
    },
    "organza": {
        "name": "Organza",
        "category": "standard",
        "gsm": 45,
        "mass": 0.045,
        "tension_stiffness": 8.0,
        "compression_stiffness": 8.0,
        "shear_stiffness": 4.0,
        "bending_stiffness": 1.0,
        "tension_damping": 1.0,
        "compression_damping": 1.0,
        "shear_damping": 1.0,
        "bending_damping": 0.5,
        "air_damping": 1.0,
        "sewing_force": 15.0,
    },
    "cotton": {
        "name": "Cotton",
        "category": "standard",
        "gsm": 140,
        "mass": 0.14,
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
    "jersey": {
        "name": "Jersey Knit",
        "category": "standard",
        "gsm": 180,
        "mass": 0.18,
        "tension_stiffness": 10.0,
        "compression_stiffness": 8.0,
        "shear_stiffness": 5.0,
        "bending_stiffness": 0.3,
        "tension_damping": 5.0,
        "compression_damping": 5.0,
        "shear_damping": 5.0,
        "bending_damping": 0.5,
        "air_damping": 1.0,
        "sewing_force": 18.0,
    },
    "french_terry": {
        "name": "French Terry",
        "category": "standard",
        "gsm": 280,
        "mass": 0.28,
        "tension_stiffness": 18.0,
        "compression_stiffness": 15.0,
        "shear_stiffness": 8.0,
        "bending_stiffness": 1.5,
        "tension_damping": 8.0,
        "compression_damping": 8.0,
        "shear_damping": 5.0,
        "bending_damping": 1.0,
        "air_damping": 1.0,
        "sewing_force": 22.0,
    },
    "fleece": {
        "name": "Fleece",
        "category": "standard",
        "gsm": 300,
        "mass": 0.30,
        "tension_stiffness": 12.0,
        "compression_stiffness": 10.0,
        "shear_stiffness": 6.0,
        "bending_stiffness": 2.0,
        "tension_damping": 10.0,
        "compression_damping": 10.0,
        "shear_damping": 8.0,
        "bending_damping": 2.0,
        "air_damping": 1.0,
        "sewing_force": 22.0,
    },
    "denim": {
        "name": "Denim",
        "category": "standard",
        "gsm": 370,
        "mass": 0.37,
        "tension_stiffness": 40.0,
        "compression_stiffness": 40.0,
        "shear_stiffness": 20.0,
        "bending_stiffness": 10.0,
        "tension_damping": 25.0,
        "compression_damping": 25.0,
        "shear_damping": 15.0,
        "bending_damping": 5.0,
        "air_damping": 1.0,
        "sewing_force": 30.0,
    },
    "canvas": {
        "name": "Canvas",
        "category": "standard",
        "gsm": 350,
        "mass": 0.35,
        "tension_stiffness": 50.0,
        "compression_stiffness": 50.0,
        "shear_stiffness": 25.0,
        "bending_stiffness": 12.0,
        "tension_damping": 20.0,
        "compression_damping": 20.0,
        "shear_damping": 12.0,
        "bending_damping": 5.0,
        "air_damping": 1.0,
        "sewing_force": 28.0,
    },
    "wool": {
        "name": "Wool Suiting",
        "category": "standard",
        "gsm": 260,
        "mass": 0.26,
        "tension_stiffness": 25.0,
        "compression_stiffness": 20.0,
        "shear_stiffness": 12.0,
        "bending_stiffness": 3.0,
        "tension_damping": 10.0,
        "compression_damping": 10.0,
        "shear_damping": 8.0,
        "bending_damping": 2.0,
        "air_damping": 1.0,
        "sewing_force": 22.0,
    },
    "linen": {
        "name": "Linen",
        "category": "standard",
        "gsm": 190,
        "mass": 0.19,
        "tension_stiffness": 20.0,
        "compression_stiffness": 18.0,
        "shear_stiffness": 10.0,
        "bending_stiffness": 2.0,
        "tension_damping": 8.0,
        "compression_damping": 8.0,
        "shear_damping": 5.0,
        "bending_damping": 1.5,
        "air_damping": 1.0,
        "sewing_force": 20.0,
    },
    "leather": {
        "name": "Leather",
        "category": "standard",
        "gsm": 600,
        "mass": 0.60,
        "tension_stiffness": 80.0,
        "compression_stiffness": 80.0,
        "shear_stiffness": 40.0,
        "bending_stiffness": 50.0,
        "tension_damping": 25.0,
        "compression_damping": 25.0,
        "shear_damping": 15.0,
        "bending_damping": 10.0,
        "air_damping": 1.0,
        "sewing_force": 35.0,
    },
    "faux_leather": {
        "name": "Faux Leather / PU",
        "category": "standard",
        "gsm": 400,
        "mass": 0.40,
        "tension_stiffness": 60.0,
        "compression_stiffness": 55.0,
        "shear_stiffness": 30.0,
        "bending_stiffness": 25.0,
        "tension_damping": 20.0,
        "compression_damping": 20.0,
        "shear_damping": 12.0,
        "bending_damping": 8.0,
        "air_damping": 1.0,
        "sewing_force": 30.0,
    },
    "neoprene": {
        "name": "Neoprene",
        "category": "standard",
        "gsm": 450,
        "mass": 0.45,
        "tension_stiffness": 20.0,
        "compression_stiffness": 15.0,
        "shear_stiffness": 10.0,
        "bending_stiffness": 8.0,
        "tension_damping": 15.0,
        "compression_damping": 15.0,
        "shear_damping": 10.0,
        "bending_damping": 5.0,
        "air_damping": 1.0,
        "sewing_force": 25.0,
    },
    "scuba": {
        "name": "Scuba Knit",
        "category": "standard",
        "gsm": 330,
        "mass": 0.33,
        "tension_stiffness": 22.0,
        "compression_stiffness": 18.0,
        "shear_stiffness": 10.0,
        "bending_stiffness": 5.0,
        "tension_damping": 12.0,
        "compression_damping": 12.0,
        "shear_damping": 8.0,
        "bending_damping": 3.0,
        "air_damping": 1.0,
        "sewing_force": 24.0,
    },
}


# Organized by category for UI display
def get_presets_by_category():
    """Return presets grouped by category."""
    categories = {}
    for fid, preset in FABRIC_PRESETS.items():
        cat = preset.get("category", "other")
        if cat not in categories:
            categories[cat] = []
        categories[cat].append((fid, preset))
    return categories


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
