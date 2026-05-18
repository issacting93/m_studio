"""
M-STUDIO Blender sidebar panel (N-panel).
Provides buttons for the full garment simulation pipeline.
"""

import bpy
from bpy.props import EnumProperty, StringProperty

from . import fabric_presets, simulation


# ---------------------------------------------------------------------------
# Panel
# ---------------------------------------------------------------------------

class MSTUDIO_PT_MainPanel(bpy.types.Panel):
    bl_label = "M-STUDIO"
    bl_idname = "MSTUDIO_PT_main"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "M-STUDIO"

    def draw(self, context):
        layout = self.layout
        layout.use_property_split = False

        # Import
        box = layout.box()
        box.label(text="Import", icon="IMPORT")
        box.operator("import_scene.mstudio_techpack", text="Import Package", icon="FILE_FOLDER")

        # Simulation pipeline
        box = layout.box()
        box.label(text="Simulation", icon="MOD_CLOTH")
        col = box.column(align=True)
        col.operator("mstudio.curves_to_mesh", icon="MESH_DATA")
        col.operator("mstudio.add_sewing", icon="GP_MULTIFRAME_EDITING")
        col.operator("mstudio.setup_cloth", icon="MOD_CLOTH")
        col.operator("mstudio.create_mannequin", icon="OUTLINER_OB_ARMATURE")
        col.separator()
        col.operator("mstudio.simulate", icon="PLAY")

        # Render
        box = layout.box()
        box.label(text="Render", icon="CAMERA_DATA")
        col = box.column(align=True)
        col.operator("mstudio.setup_scene", icon="LIGHT_AREA")
        col.operator("mstudio.render_lookbook", icon="RENDER_STILL")


# ---------------------------------------------------------------------------
# Operators
# ---------------------------------------------------------------------------

class MSTUDIO_OT_CurvesToMesh(bpy.types.Operator):
    """Convert imported pattern curves to simulation-ready mesh"""
    bl_idname = "mstudio.curves_to_mesh"
    bl_label = "Curves → Mesh"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        # Find curve objects in the scene, use canonical names
        curves = {}
        for obj in context.scene.objects:
            if obj.type == "CURVE":
                canonical = _strip_blender_suffix(obj.name)
                curves[canonical] = obj
        if not curves:
            self.report({"WARNING"}, "No curve objects found")
            return {"CANCELLED"}

        mesh_objects = simulation.curves_to_mesh(curves)
        self.report({"INFO"}, f"Converted {len(mesh_objects)} curves to mesh")
        return {"FINISHED"}


class MSTUDIO_OT_AddSewing(bpy.types.Operator):
    """Join pieces and add sewing springs between matching edges"""
    bl_idname = "mstudio.add_sewing"
    bl_label = "Add Sewing"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        from . import sewing_map

        # Find mesh objects (pattern pieces)
        # Strip Blender suffixes (.001, .002) to get canonical piece names
        mesh_objs = {}
        raw_objs = {}
        for obj in context.scene.objects:
            if obj.type == "MESH" and not obj.name.startswith("MSTUDIO_"):
                canonical = _strip_blender_suffix(obj.name)
                mesh_objs[canonical] = obj
                raw_objs[obj.name] = obj

        if not mesh_objs:
            self.report({"WARNING"}, "No mesh pattern pieces found")
            return {"CANCELLED"}

        # Detect silhouette from canonical piece names
        silhouette = _detect_silhouette(mesh_objs.keys())

        # Get sewings for this silhouette
        sewings = sewing_map.get_sewings(silhouette, mesh_objs)
        if not sewings:
            self.report({"WARNING"}, f"No sewings defined for silhouette: {silhouette}")
            return {"CANCELLED"}

        garment = simulation.join_and_sew(mesh_objs, sewings)
        if garment:
            self.report({"INFO"}, f"Joined {len(mesh_objs)} pieces with {len(sewings)} sewings")
        else:
            self.report({"ERROR"}, "Failed to join pieces")
            return {"CANCELLED"}

        return {"FINISHED"}


class MSTUDIO_OT_SetupCloth(bpy.types.Operator):
    """Add cloth modifier with fabric physics and sewing springs"""
    bl_idname = "mstudio.setup_cloth"
    bl_label = "Setup Cloth Sim"
    bl_options = {"REGISTER", "UNDO"}

    fabric: EnumProperty(
        name="Fabric",
        items=[
            (fid, f"{preset['name']}  ({preset['gsm']}gsm)", preset.get("category", "").upper())
            for fid, preset in fabric_presets.FABRIC_PRESETS.items()
        ],
        default="ripstop70",
    )

    def execute(self, context):
        garment = _find_garment(context)
        if not garment:
            self.report({"WARNING"}, "No garment mesh found. Run 'Add Sewing' first.")
            return {"CANCELLED"}

        simulation.setup_cloth(garment, fabric_id=self.fabric)
        self.report({"INFO"}, f"Cloth simulation configured: {fabric_presets.get_preset(self.fabric)['name']}")
        return {"FINISHED"}

    def invoke(self, context, event):
        return context.window_manager.invoke_props_dialog(self)


class MSTUDIO_OT_CreateMannequin(bpy.types.Operator):
    """Create a collision mannequin for draping"""
    bl_idname = "mstudio.create_mannequin"
    bl_label = "Create Mannequin"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        mannequin = simulation.create_mannequin()
        garment = _find_garment(context)
        if garment and mannequin:
            simulation.position_for_drape(garment, mannequin)
        self.report({"INFO"}, "Mannequin created")
        return {"FINISHED"}


class MSTUDIO_OT_Simulate(bpy.types.Operator):
    """Bake the cloth simulation"""
    bl_idname = "mstudio.simulate"
    bl_label = "Simulate Drape"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        garment = _find_garment(context)
        if not garment:
            self.report({"WARNING"}, "No garment found")
            return {"CANCELLED"}

        # Check for cloth modifier
        has_cloth = any(m.type == "CLOTH" for m in garment.modifiers)
        if not has_cloth:
            self.report({"WARNING"}, "No cloth modifier. Run 'Setup Cloth Sim' first.")
            return {"CANCELLED"}

        # Set frame range and bake
        context.scene.frame_start = 1
        context.scene.frame_end = 100
        context.scene.frame_set(1)

        # Select garment for bake
        bpy.ops.object.select_all(action="DESELECT")
        garment.select_set(True)
        context.view_layer.objects.active = garment

        # Bake
        bpy.ops.ptcache.bake_all(bake=True)

        # Jump to final frame
        context.scene.frame_set(100)

        self.report({"INFO"}, "Simulation baked (100 frames)")
        return {"FINISHED"}


class MSTUDIO_OT_SetupScene(bpy.types.Operator):
    """Set up Cycles render with studio lighting and camera"""
    bl_idname = "mstudio.setup_scene"
    bl_label = "Setup Scene"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        simulation.setup_render_scene()
        self.report({"INFO"}, "Scene configured: Cycles 256spp, AgX, studio lighting")
        return {"FINISHED"}


class MSTUDIO_OT_RenderLookbook(bpy.types.Operator):
    """Render the current view"""
    bl_idname = "mstudio.render_lookbook"
    bl_label = "Render"
    bl_options = {"REGISTER"}

    def execute(self, context):
        bpy.ops.render.render("INVOKE_DEFAULT")
        return {"FINISHED"}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_garment(context):
    """Find the joined garment mesh."""
    for obj in context.scene.objects:
        if obj.name == "MSTUDIO_Garment" and obj.type == "MESH":
            return obj
    # Fallback: any selected mesh
    if context.active_object and context.active_object.type == "MESH":
        return context.active_object
    return None


def _strip_blender_suffix(name):
    """Strip Blender's .001, .002 etc. suffixes from object names."""
    import re
    return re.sub(r"\.\d{3}$", "", name)


def _detect_silhouette(piece_names):
    """Guess silhouette from piece names (already stripped of .001 suffixes)."""
    names = set(piece_names)
    if "HOOD" in names:
        if "FRONT_L" in names or "FRONT_R" in names:
            return "hoodie"
        return "pullover"
    if "FRONT_L" in names or "FRONT_R" in names:
        return "bomber"
    if "FRONT" in names and "COLLAR" in names:
        return "tshirt"
    if "FRONT" in names:
        return "pullover"
    return "noragi"


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

CLASSES = [
    MSTUDIO_PT_MainPanel,
    MSTUDIO_OT_CurvesToMesh,
    MSTUDIO_OT_AddSewing,
    MSTUDIO_OT_SetupCloth,
    MSTUDIO_OT_CreateMannequin,
    MSTUDIO_OT_Simulate,
    MSTUDIO_OT_SetupScene,
    MSTUDIO_OT_RenderLookbook,
]


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)


def unregister():
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)
