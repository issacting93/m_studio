bl_info = {
    "name": "M-STUDIO Bridge",
    "description": "Import M-STUDIO packages and tech packs as garment_tool-compatible 2D pattern curves",
    "author": "Zac Ting",
    "version": (2, 0, 0),
    "blender": (4, 2, 0),
    "location": "File > Import > M-STUDIO Package (.mstudio / .json)",
    "category": "Import-Export",
}

import bpy
from . import import_techpack


def menu_func_import(self, context):
    self.layout.operator(
        import_techpack.MSTUDIO_OT_Import.bl_idname,
        text="M-STUDIO Package (.mstudio / .json)",
    )


def register():
    import_techpack.register()
    bpy.types.TOPBAR_MT_file_import.append(menu_func_import)


def unregister():
    bpy.types.TOPBAR_MT_file_import.remove(menu_func_import)
    import_techpack.unregister()
