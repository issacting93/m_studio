import Foundation
import SwiftUI

/// Exports the garment 3D mesh as OBJ + MTL files for Blender import.
/// Each panel (body, sleeves, hood, collar, cuffs, pockets) gets a named material.
struct OBJExportService {
    let state: DesignState

    func export() -> (objURL: URL, mtlURL: URL)? {
        let tempDir = FileManager.default.temporaryDirectory
        let objURL = tempDir.appendingPathComponent("\(state.silhouette.code)-garment.obj")
        let mtlURL = tempDir.appendingPathComponent("\(state.silhouette.code)-garment.mtl")

        let mtlFilename = mtlURL.lastPathComponent
        var obj = "# M-STUDIO Garment Export\n# \(state.silhouette.displayName) · \(state.colorway.displayName)\nmtllib \(mtlFilename)\n\n"

        var vertexOffset = 0

        let bw = state.bodyWidth / 100  // convert cm to meters for Blender
        let bl = state.bodyLength / 100
        let sl = state.sleeveLength / 100
        let sd = state.sleeveDepth / 100
        let so = state.sleeveOpen / 100
        let depth = (state.silhouette == .noragi ? 16.0 : 22.0) / 100

        let isBomberish = state.silhouette == .bomber || state.silhouette == .hoodie || state.silhouette == .pullover
        let taper = isBomberish ? 0.85 : 1.0

        // BODY — tapered box
        obj += "g body\nusemtl mat_body\n"
        let hw = bw / 2, hh = bl / 2, hd = depth / 2
        let tw = taper * hw
        let bodyVerts = [
            (-hw, hh, hd), (hw, hh, hd), (hw, hh, -hd), (-hw, hh, -hd),
            (-tw, -hh, hd), (tw, -hh, hd), (tw, -hh, -hd), (-tw, -hh, -hd)
        ]
        for v in bodyVerts { obj += "v \(f(v.0)) \(f(v.1)) \(f(v.2))\n" }
        let o = vertexOffset
        obj += "f \(o+1) \(o+5) \(o+6) \(o+2)\n"  // front
        obj += "f \(o+3) \(o+7) \(o+8) \(o+4)\n"  // back
        obj += "f \(o+4) \(o+1) \(o+2) \(o+3)\n"  // top
        obj += "f \(o+5) \(o+8) \(o+7) \(o+6)\n"  // bottom
        obj += "f \(o+4) \(o+8) \(o+5) \(o+1)\n"  // left
        obj += "f \(o+2) \(o+6) \(o+7) \(o+3)\n"  // right
        vertexOffset += 8

        // SLEEVES — simplified as boxes (easier than cylinders in OBJ)
        let slvAngle = state.sleeveType == .raglan ? 0.4 : (state.sleeveType == .setin ? 0.25 : 0.1)
        for side in [-1.0, 1.0] {
            obj += "\ng sleeve_\(side > 0 ? "R" : "L")\nusemtl mat_sleeves\n"
            let sx = side * (bw / 2 + sl / 2)
            let sy = bl / 2 - sd / 2 - sin(slvAngle) * sl / 3
            let slvH = sd / 2, slvW = sl / 2, slvD = so / 4
            let sverts = [
                (sx - slvW, sy + slvH, slvD), (sx + slvW, sy + slvH, slvD),
                (sx + slvW, sy + slvH, -slvD), (sx - slvW, sy + slvH, -slvD),
                (sx - slvW, sy - slvH, slvD), (sx + slvW, sy - slvH, slvD),
                (sx + slvW, sy - slvH, -slvD), (sx - slvW, sy - slvH, -slvD)
            ]
            for v in sverts { obj += "v \(f(v.0)) \(f(v.1)) \(f(v.2))\n" }
            let so2 = vertexOffset
            obj += "f \(so2+1) \(so2+5) \(so2+6) \(so2+2)\n"
            obj += "f \(so2+3) \(so2+7) \(so2+8) \(so2+4)\n"
            obj += "f \(so2+4) \(so2+1) \(so2+2) \(so2+3)\n"
            obj += "f \(so2+5) \(so2+8) \(so2+7) \(so2+6)\n"
            obj += "f \(so2+4) \(so2+8) \(so2+5) \(so2+1)\n"
            obj += "f \(so2+2) \(so2+6) \(so2+7) \(so2+3)\n"
            vertexOffset += 8
        }

        // COLLAR — small box
        let hasHood = state.silhouette == .hoodie || state.silhouette == .parka || state.silhouette == .pullover
        if !hasHood {
            obj += "\ng collar\nusemtl mat_collar\n"
            let cw2 = bw * 0.25, ch = bl * 0.025, cd = depth * 0.4
            let cy = bl / 2 + ch
            let cverts = [
                (-cw2, cy + ch, cd), (cw2, cy + ch, cd), (cw2, cy + ch, -cd), (-cw2, cy + ch, -cd),
                (-cw2, cy - ch, cd), (cw2, cy - ch, cd), (cw2, cy - ch, -cd), (-cw2, cy - ch, -cd)
            ]
            for v in cverts { obj += "v \(f(v.0)) \(f(v.1)) \(f(v.2))\n" }
            let co = vertexOffset
            for face in boxFaces(co) { obj += face }
            vertexOffset += 8
        }

        // HOOD — hemisphere approximated as a dome
        if hasHood {
            obj += "\ng hood\nusemtl mat_hood\n"
            let hr = bw * 0.32
            let hcy = bl / 2 + bw * 0.12
            let segments = 8
            let rings = 4
            // Generate dome vertices
            var domeVerts: [(Double, Double, Double)] = []
            for ring in 0...rings {
                let phi = Double.pi / 2 * Double(ring) / Double(rings)
                let y = hcy + hr * 0.6 * cos(phi)
                let r = hr * sin(phi)
                for seg in 0..<segments {
                    let theta = 2 * Double.pi * Double(seg) / Double(segments)
                    domeVerts.append((r * cos(theta), y, r * 0.8 * sin(theta) - depth * 0.05))
                }
            }
            // Top vertex
            domeVerts.append((0, hcy + hr * 0.6, -depth * 0.05))
            for v in domeVerts { obj += "v \(f(v.0)) \(f(v.1)) \(f(v.2))\n" }
            // Faces
            let ho = vertexOffset
            for ring in 0..<rings {
                for seg in 0..<segments {
                    let next = (seg + 1) % segments
                    let a = ho + ring * segments + seg + 1
                    let b = ho + ring * segments + next + 1
                    let c = ho + (ring + 1) * segments + next + 1
                    let d = ho + (ring + 1) * segments + seg + 1
                    if ring < rings - 1 {
                        obj += "f \(a) \(b) \(c) \(d)\n"
                    }
                }
            }
            vertexOffset += domeVerts.count
        }

        // MTL file
        var mtl = "# M-STUDIO Materials\n\n"
        let cw = state.colorway
        let panels: [(String, Color)] = [
            ("mat_body", state.colorBlocking.color(for: .body, colorway: cw)),
            ("mat_sleeves", state.colorBlocking.color(for: .sleeves, colorway: cw)),
            ("mat_collar", state.colorBlocking.color(for: .collar, colorway: cw)),
            ("mat_hood", state.colorBlocking.color(for: .hood, colorway: cw)),
            ("mat_cuffs", state.colorBlocking.color(for: .cuffs, colorway: cw)),
            ("mat_pockets", state.colorBlocking.color(for: .pockets, colorway: cw)),
        ]
        for (name, color) in panels {
            let (r, g, b) = colorToRGB(color)
            mtl += "newmtl \(name)\n"
            mtl += "Kd \(f(r)) \(f(g)) \(f(b))\n"
            mtl += "Ka 0.1 0.1 0.1\n"
            mtl += "Ks 0.05 0.05 0.05\n"
            mtl += "Ns 10\n"
            mtl += "d 1.0\n\n"
        }

        do {
            try obj.write(to: objURL, atomically: true, encoding: .utf8)
            try mtl.write(to: mtlURL, atomically: true, encoding: .utf8)
            return (objURL, mtlURL)
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func f(_ v: Double) -> String {
        String(format: "%.4f", v)
    }

    private func boxFaces(_ o: Int) -> [String] {
        [
            "f \(o+1) \(o+5) \(o+6) \(o+2)\n",
            "f \(o+3) \(o+7) \(o+8) \(o+4)\n",
            "f \(o+4) \(o+1) \(o+2) \(o+3)\n",
            "f \(o+5) \(o+8) \(o+7) \(o+6)\n",
            "f \(o+4) \(o+8) \(o+5) \(o+1)\n",
            "f \(o+2) \(o+6) \(o+7) \(o+3)\n",
        ]
    }

    private func colorToRGB(_ color: Color) -> (Double, Double, Double) {
        #if os(macOS)
        let nsColor = NSColor(color)
        let c = nsColor.usingColorSpace(.sRGB) ?? nsColor
        return (Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent))
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Double(r), Double(g), Double(b))
        #endif
    }
}
