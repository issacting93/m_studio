"""
Main import operator: File > Import > M-STUDIO Tech Pack
Supports both .mstudio packages (ZIP) and legacy .json tech packs.
"""

import bpy
from bpy.props import BoolProperty, EnumProperty, FloatProperty, StringProperty
from bpy_extras.io_utils import ImportHelper

from . import curve_builder, garment_tool_bridge, materials, package_reader, pattern_geometry, sewing_map


class MSTUDIO_OT_Import(bpy.types.Operator, ImportHelper):
    """Import M-STUDIO tech pack as 2D pattern curves"""

    bl_idname = "import_scene.mstudio_techpack"
    bl_label = "Import M-STUDIO Tech Pack"
    bl_options = {"REGISTER", "UNDO"}

    filename_ext = ".mstudio"
    filter_glob: StringProperty(default="*.mstudio;*.json", options={"HIDDEN"})

    scale: FloatProperty(
        name="Scale",
        description="Convert cm to Blender units (0.01 = cm to meters)",
        default=0.01,
        min=0.001,
        max=1.0,
    )

    register_garment_tool: BoolProperty(
        name="Register with garment_tool",
        description="Create garment_tool-compatible patterns with sewings",
        default=True,
    )

    apply_materials: BoolProperty(
        name="Apply Materials",
        description="Create and assign materials from colorway",
        default=True,
    )

    create_sewings: BoolProperty(
        name="Create Sewings",
        description="Define sewing connections between pattern pieces",
        default=True,
    )

    target_size: EnumProperty(
        name="Size",
        description="Which graded size to import",
        items=[
            ("BASE", "Base (M)", "Use base measurements as defined"),
            ("XS", "XS", "Extra small"),
            ("S", "S", "Small"),
            ("M", "M", "Medium"),
            ("L", "L", "Large"),
            ("XL", "XL", "Extra large"),
            ("XXL", "XXL", "Extra extra large"),
        ],
        default="BASE",
    )

    def execute(self, context):
        # Parse file (handles both .mstudio and .json)
        try:
            data = package_reader.read_file(self.filepath)
        except (ValueError, OSError) as e:
            self.report({"ERROR"}, f"Failed to read tech pack: {e}")
            return {"CANCELLED"}

        try:
            return self._import(context, data)
        finally:
            package_reader.cleanup(data)

    def _import(self, context, data):
        manifest = data["manifest"]
        silhouette = manifest.get("silhouette", "bomber")
        style_code = manifest.get("styleCode", "M-STUDIO")

        # Get measurements (with optional size grading)
        measurements = package_reader.get_measurements(data, self.target_size)
        fabric_data = manifest.get("fabric", {})
        fabric_id = fabric_data.get("id", "ripstop70")

        # Generate pattern geometry
        pieces = pattern_geometry.generate_pieces(measurements, silhouette)
        if not pieces:
            self.report({"ERROR"}, f"No pattern pieces generated for silhouette: {silhouette}")
            return {"CANCELLED"}

        # Build Blender curve objects
        collection_name = style_code.replace(".", "_")
        objects = curve_builder.build_all_curves(
            pieces, scale=self.scale, collection_name=collection_name
        )

        # Apply materials from colorway (with blocking support)
        if self.apply_materials:
            colors = package_reader.get_colorway_colors(data)
            blocking = package_reader.get_blocking(data)
            materials.apply_colorway(objects, colors, garment_name=collection_name, blocking=blocking)

        # Get sewing definitions
        sewings = []
        if self.create_sewings:
            sewings = sewing_map.get_sewings(silhouette, pieces)

        # Register with garment_tool
        gt_registered = False
        if self.register_garment_tool and garment_tool_bridge.is_available():
            gt_registered = garment_tool_bridge.register_garment(
                name=style_code,
                objects=objects,
                sewings=sewings,
                fabric_id=fabric_id,
            )

        # Report graphic placements (loaded but not yet applied to textures)
        placements = package_reader.get_graphic_placements(data)
        graphic_msg = ""
        if placements:
            svg_count = sum(1 for p in placements if p.get("file"))
            graphic_msg = f", {svg_count} graphics"

        # Report results
        piece_count = len(objects)
        sewing_count = len(sewings)
        size_label = f" ({self.target_size})" if self.target_size != "BASE" else ""

        msg = f"Imported {style_code}{size_label}: {piece_count} pieces, {sewing_count} sewings{graphic_msg}"
        if gt_registered:
            msg += " [garment_tool]"
        elif self.register_garment_tool and not garment_tool_bridge.is_available():
            self.report({"WARNING"}, "garment_tool not found — patterns created without registration")

        self.report({"INFO"}, msg)
        return {"FINISHED"}

    def draw(self, context):
        layout = self.layout
        layout.prop(self, "scale")
        layout.prop(self, "target_size")
        layout.separator()
        layout.prop(self, "apply_materials")
        layout.prop(self, "create_sewings")
        layout.prop(self, "register_garment_tool")


def register():
    bpy.utils.register_class(MSTUDIO_OT_Import)


def unregister():
    bpy.utils.unregister_class(MSTUDIO_OT_Import)
