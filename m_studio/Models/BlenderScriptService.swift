import Foundation

/// Generates Blender Python scripts for garment import, cloth simulation, and material setup.
struct BlenderScriptService {
    let state: DesignState

    /// Generate a flat pattern OBJ file (all pieces at z=0) for cloth simulation
    func exportPatternOBJ() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("\(state.silhouette.code)-pattern.obj")

        var obj = "# M-STUDIO Flat Pattern for Blender Cloth Sim\n"
        obj += "# \(state.silhouette.displayName) · Size \(state.size.rawValue)\n"
        obj += "# Units: centimeters (scale 0.01 in Blender for meters)\n\n"

        var vertexOffset = 0
        let bw = state.bodyWidth
        let bl = state.bodyLength
        let sl = state.sleeveLength
        let sd = state.sleeveDepth

        // BACK piece
        obj += "g BACK\n"
        obj += "v 0 0 0\nv \(bw) 0 0\nv \(bw) \(bl) 0\nv 0 \(bl) 0\n"
        obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
        vertexOffset += 4

        // SLEEVE_L
        let slvX = bw + 10
        obj += "\ng SLEEVE_L\n"
        obj += "v \(slvX) 0 0\nv \(slvX + sl) 0 0\nv \(slvX + sl) \(sd) 0\nv \(slvX) \(sd) 0\n"
        obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
        vertexOffset += 4

        // SLEEVE_R
        let slvRX = bw + sl + 20
        obj += "\ng SLEEVE_R\n"
        obj += "v \(slvRX) 0 0\nv \(slvRX + sl) 0 0\nv \(slvRX + sl) \(sd) 0\nv \(slvRX) \(sd) 0\n"
        obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
        vertexOffset += 4

        // COLLAR
        let collarW = bl * 1.4
        let collarH = 10.0
        obj += "\ng COLLAR\n"
        obj += "v 0 \(bl + 10) 0\nv \(collarW) \(bl + 10) 0\nv \(collarW) \(bl + 10 + collarH) 0\nv 0 \(bl + 10 + collarH) 0\n"
        obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
        vertexOffset += 4

        // FRONT panels (non-noragi)
        if state.silhouette != .noragi {
            let frontH = bl * 0.7
            obj += "\ng FRONT_L\n"
            obj += "v 0 \(bl + 30) 0\nv \(bw/2) \(bl + 30) 0\nv \(bw/2) \(bl + 30 + frontH) 0\nv 0 \(bl + 30 + frontH) 0\n"
            obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
            vertexOffset += 4

            obj += "\ng FRONT_R\n"
            let frX = bw / 2 + 10
            obj += "v \(frX) \(bl + 30) 0\nv \(frX + bw/2) \(bl + 30) 0\nv \(frX + bw/2) \(bl + 30 + frontH) 0\nv \(frX) \(bl + 30 + frontH) 0\n"
            obj += "f \(vertexOffset+1) \(vertexOffset+2) \(vertexOffset+3) \(vertexOffset+4)\n"
            vertexOffset += 4
        }

        do {
            try obj.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Generate a Blender Python script that imports the pattern, sets up cloth sim, and applies materials
    func exportBlenderScript() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("\(state.silhouette.code)-blender-import.py")

        let fabric = state.fabric
        let cw = state.colorway

        // Resolve colors to RGB tuples
        func colorTuple(_ panel: GarmentPanel) -> String {
            let choice = state.colorBlocking.choice(for: panel)
            switch choice {
            case .primary: return hexToBlenderRGB(cw.primaryHex)
            case .secondary: return hexToBlenderRGB(cw.secondaryHex)
            case .accent: return hexToBlenderRGB(cw.accentHex)
            case .graphic: return hexToBlenderRGB(cw.graphicHex)
            }
        }

        let script = """
        # ============================================================
        # M-STUDIO → BLENDER IMPORT SCRIPT
        # Auto-generated · \(state.silhouette.displayName) · \(state.silhouette.code)
        # ============================================================
        import bpy
        import os

        # --- Configuration ---
        GARMENT_NAME = "\(state.silhouette.displayName)"
        FABRIC_NAME = "\(fabric.displayName)"

        # Fabric physics (Blender cloth simulation)
        FABRIC = {
            "mass": \(fabric.clothMass),
            "tension_stiffness": \(fabric.clothTensionStiffness),
            "bending_stiffness": \(fabric.clothBendingStiffness),
            "damping": 5.0,
            "quality": 12,
        }

        # Panel colors (linear sRGB)
        MATERIALS = {
            "body": \(colorTuple(.body)),
            "sleeves": \(colorTuple(.sleeves)),
            "hood": \(colorTuple(.hood)),
            "collar": \(colorTuple(.collar)),
            "cuffs": \(colorTuple(.cuffs)),
            "pockets": \(colorTuple(.pockets)),
        }

        # --- Helper Functions ---
        def create_fabric_material(name, color):
            mat = bpy.data.materials.new(name=f"MSTUDIO_{name}")
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = (*color, 1.0)
            bsdf.inputs["Metallic"].default_value = 0.0
            bsdf.inputs["Roughness"].default_value = 0.75
            bsdf.inputs["Specular IOR Level"].default_value = 0.2
            return mat

        def apply_cloth_sim(obj):
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_add(type='CLOTH')
            cloth = obj.modifiers["Cloth"].settings
            cloth.mass = FABRIC["mass"]
            cloth.tension_stiffness = FABRIC["tension_stiffness"]
            cloth.bending_stiffness = FABRIC["bending_stiffness"]
            cloth.quality = FABRIC["quality"]

        # --- Import 3D Garment Mesh ---
        script_dir = os.path.dirname(bpy.data.filepath) if bpy.data.filepath else os.getcwd()

        # Look for OBJ file in same directory as this script
        garment_obj = os.path.join(script_dir, "\(state.silhouette.code)-garment.obj")
        pattern_obj = os.path.join(script_dir, "\(state.silhouette.code)-pattern.obj")

        # Import 3D garment if found
        if os.path.exists(garment_obj):
            bpy.ops.wm.obj_import(filepath=garment_obj)
            print(f"Imported 3D garment: {garment_obj}")

            # Apply materials to imported objects
            for obj in bpy.context.selected_objects:
                if obj.type == 'MESH':
                    obj_name = obj.name.lower()
                    for panel_name, color in MATERIALS.items():
                        if panel_name in obj_name:
                            mat = create_fabric_material(panel_name, color)
                            obj.data.materials.clear()
                            obj.data.materials.append(mat)
                            break
        else:
            print(f"3D garment not found at: {garment_obj}")

        # Import flat pattern if found (for cloth simulation)
        if os.path.exists(pattern_obj):
            bpy.ops.wm.obj_import(filepath=pattern_obj)
            print(f"Imported flat pattern: {pattern_obj}")

            # Apply cloth sim to pattern pieces
            for obj in bpy.context.selected_objects:
                if obj.type == 'MESH':
                    apply_cloth_sim(obj)
                    # Scale from cm to meters
                    obj.scale = (0.01, 0.01, 0.01)
                    # Move above origin for draping
                    obj.location.z += 1.5
        else:
            print(f"Pattern not found at: {pattern_obj}")

        # --- Add Collision Mannequin ---
        bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.7, location=(0, 0, 0.65))
        torso = bpy.context.active_object
        torso.name = "Mannequin_Torso"
        bpy.ops.object.modifier_add(type='COLLISION')

        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(0, 0, 1.1))
        head = bpy.context.active_object
        head.name = "Mannequin_Head"
        bpy.ops.object.modifier_add(type='COLLISION')

        # --- Scene Setup ---
        # Set render engine to Cycles for best fabric rendering
        bpy.context.scene.render.engine = 'CYCLES'
        bpy.context.scene.cycles.samples = 128

        # Add studio lighting
        bpy.ops.object.light_add(type='AREA', location=(2, -2, 3))
        key_light = bpy.context.active_object
        key_light.name = "Key_Light"
        key_light.data.energy = 200
        key_light.data.size = 2

        bpy.ops.object.light_add(type='AREA', location=(-2, 2, 2))
        fill_light = bpy.context.active_object
        fill_light.name = "Fill_Light"
        fill_light.data.energy = 80
        fill_light.data.size = 3

        print(f"\\n{'='*50}")
        print(f"M-STUDIO import complete: {GARMENT_NAME}")
        print(f"Fabric: {FABRIC_NAME}")
        print(f"{'='*50}")
        """

        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func hexToBlenderRGB(_ hex: String) -> String {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        // Convert to linear sRGB for Blender
        func toLinear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return String(format: "(%.4f, %.4f, %.4f)", toLinear(r), toLinear(g), toLinear(b))
    }
}
