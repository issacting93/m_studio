import SwiftUI
import SceneKit

struct ThreeDView: View {
    let state: DesignState

    var body: some View {
        ZStack {
            SceneKitGarmentView(state: state)

            // HUD overlays
            VStack {
                HStack {
                    Text("DRAG TO ROTATE · SCROLL TO ZOOM")
                        .font(.custom("JetBrains Mono", size: 9))
                        .foregroundColor(Theme.soft)
                        .tracking(1)
                        .padding(8)
                    Spacer()
                    Text("3D · SCENEKIT")
                        .font(.custom("JetBrains Mono", size: 9))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.ink)
                        .tracking(1)
                        .padding(8)
                }
                Spacer()
            }
        }
        .background(Theme.paper)
    }
}

// MARK: - SceneKit View

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#else
typealias ViewRepresentable = UIViewRepresentable
#endif

struct SceneKitGarmentView: ViewRepresentable {
    let state: DesignState

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    #if os(macOS)
    func makeNSView(context: Context) -> SCNView {
        let scnView = createSCNView()
        context.coordinator.scnView = scnView
        return scnView
    }

    func updateNSView(_ scnView: SCNView, context: Context) {
        rebuildScene(scnView: scnView)
    }
    #else
    func makeUIView(context: Context) -> SCNView {
        let scnView = createSCNView()
        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        rebuildScene(scnView: scnView)
    }
    #endif

    private func createSCNView() -> SCNView {
        let scnView = SCNView()
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        #if os(macOS)
        scnView.backgroundColor = NSColor(Color(hex: "#f1ede3"))
        #else
        scnView.backgroundColor = UIColor(Color(hex: "#f1ede3"))
        #endif

        let scene = SCNScene()
        scnView.scene = scene
        setupLighting(scene: scene)
        setupCamera(scene: scene)
        setupGrid(scene: scene)
        buildGarment(scene: scene)

        return scnView
    }

    private func rebuildScene(scnView: SCNView) {
        guard let scene = scnView.scene else { return }
        // Remove old garment group
        scene.rootNode.childNodes.filter { $0.name == "garment" }.forEach { $0.removeFromParentNode() }
        buildGarment(scene: scene)
    }

    // MARK: - Scene Setup

    private func setupCamera(scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 35
        cameraNode.camera?.zNear = 1
        cameraNode.camera?.zFar = 2000
        cameraNode.position = SCNVector3(0, 20, 280)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting(scene: SCNScene) {
        // Ambient
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 450
        scene.rootNode.addChildNode(ambient)

        // Key light
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 850
        key.position = SCNVector3(40, 80, 100)
        key.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(key)

        // Fill light
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 300
        fill.position = SCNVector3(-60, -20, 80)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        // Rim light (accent colored)
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 180
        rim.light?.color = platformColor(hex: "#d63d2e")
        rim.position = SCNVector3(0, 0, -100)
        rim.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(rim)
    }

    private func setupGrid(scene: SCNScene) {
        let floor = SCNFloor()
        floor.reflectivity = 0
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = platformColor(hex: "#e8e4da")
        floor.materials = [floorMat]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -120, 0)
        floorNode.opacity = 0.4
        scene.rootNode.addChildNode(floorNode)
    }

    // MARK: - Build Garment

    private func buildGarment(scene: SCNScene) {
        let group = SCNNode()
        group.name = "garment"

        let cw = state.colorway
        let mainMat = material(color: cw.primary)
        let secMat = material(color: cw.secondary)
        let accentMat = material(color: cw.accent)

        let bw = CGFloat(state.bodyWidth)
        let bl = CGFloat(state.bodyLength)
        let sl = CGFloat(state.sleeveLength)
        let sd = CGFloat(state.sleeveDepth)
        let so = CGFloat(state.sleeveOpen)
        let depth: CGFloat = state.silhouette == .noragi ? 16 : 22

        let isBomberish = state.silhouette == .bomber || state.silhouette == .hoodie
        let isParka = state.silhouette == .parka
        let taper: CGFloat = isBomberish ? 0.85 : 1.0

        // BODY — tapered box via custom geometry
        let bodyNode = createTaperedBox(width: CGFloat(bw), height: CGFloat(bl), depth: CGFloat(depth), taper: CGFloat(taper), material: mainMat)
        bodyNode.position = SCNVector3(0, 0, 0)
        group.addChildNode(bodyNode)

        // Ribbed hem for bomber/hoodie
        if isBomberish {
            let ribH = bl * 0.08
            let ribBox = SCNBox(width: CGFloat(bw * taper), height: CGFloat(ribH), length: CGFloat(depth * 1.02), chamferRadius: 0)
            ribBox.materials = [secMat]
            let rib = SCNNode(geometry: ribBox)
            rib.position = SCNVector3(0, -bl / 2 + ribH / 2, 0)
            group.addChildNode(rib)
        }

        // SLEEVES — tapered cylinders
        let slvDownAngle: CGFloat = state.sleeveType == .raglan ? 0.4 : (state.sleeveType == .setin ? 0.25 : 0.1)

        // Left sleeve
        let sleeveGeom = SCNCylinder(radius: sd / 2, height: sl)
        sleeveGeom.materials = [mainMat]
        let leftSleeve = SCNNode(geometry: sleeveGeom)
        let lSlvAngle = CGFloat.pi / 2 + slvDownAngle
        leftSleeve.eulerAngles = SCNVector3(0, 0, lSlvAngle)
        let lSlvX = -bw / 2 - sl / 2
        let lSlvY = bl / 2 - sd / 2 - sin(slvDownAngle) * sl / 3
        leftSleeve.position = SCNVector3(lSlvX, lSlvY, 0)
        group.addChildNode(leftSleeve)

        // Right sleeve
        let rightSleeve = SCNNode(geometry: sleeveGeom)
        let rSlvAngle = -(CGFloat.pi / 2 + slvDownAngle)
        rightSleeve.eulerAngles = SCNVector3(0, 0, rSlvAngle)
        let rSlvX = bw / 2 + sl / 2
        let rSlvY = leftSleeve.position.y
        rightSleeve.position = SCNVector3(rSlvX, rSlvY, 0)
        group.addChildNode(rightSleeve)

        // Cuffs
        if isBomberish {
            let cuffGeom = SCNCylinder(radius: so / 2 + 0.5, height: sd * 0.08)
            cuffGeom.materials = [secMat]

            let lcuff = SCNNode(geometry: cuffGeom)
            lcuff.eulerAngles = leftSleeve.eulerAngles
            let lcX = leftSleeve.position.x - cos(slvDownAngle) * sl / 2
            let lcY = leftSleeve.position.y - sin(slvDownAngle) * sl / 2
            lcuff.position = SCNVector3(lcX, lcY, 0)
            group.addChildNode(lcuff)

            let rcuff = SCNNode(geometry: cuffGeom)
            rcuff.eulerAngles = rightSleeve.eulerAngles
            let rcX = rightSleeve.position.x + cos(slvDownAngle) * sl / 2
            let rcY = leftSleeve.position.y - sin(slvDownAngle) * sl / 2
            rcuff.position = SCNVector3(rcX, rcY, 0)
            group.addChildNode(rcuff)
        }

        // HOOD or COLLAR
        let hasHood = state.silhouette == .hoodie || state.silhouette == .parka
        if hasHood {
            let hoodGeom = SCNSphere(radius: CGFloat(bw * 0.32))
            hoodGeom.materials = [mainMat]
            // Use half sphere by clipping with a plane or just positioning
            let hood = SCNNode(geometry: hoodGeom)
            hood.position = SCNVector3(0, bl / 2 + bw * 0.12, -depth * 0.1)
            // Scale to squash into hemisphere
            hood.scale = SCNVector3(1, 0.6, 0.8)
            group.addChildNode(hood)
        } else {
            let collarGeom = SCNBox(width: CGFloat(bw * 0.5), height: CGFloat(bl * 0.05), length: CGFloat(depth * 0.8), chamferRadius: 0)
            collarGeom.materials = [secMat]
            let collar = SCNNode(geometry: collarGeom)
            collar.position = SCNVector3(0, bl / 2 + bl * 0.025, 0)
            group.addChildNode(collar)
        }

        // POCKETS
        if state.pocket == .patch || state.pocket == .cargo {
            let pkW = bw * 0.22
            let pkH = bl * 0.12
            let pkGeom = SCNBox(width: pkW, height: pkH, length: 1, chamferRadius: 0)
            pkGeom.materials = [secMat]

            let positions: [(CGFloat, CGFloat)]
            if state.pocket == .cargo {
                let cpx1 = -bw * 0.26 + pkW / 2
                let cpx2 = bw * 0.04 + pkW / 2
                let cpy1 = bl * 0.05
                let cpy2 = -bl * 0.28
                positions = [(cpx1, cpy1), (cpx2, cpy1), (cpx1, cpy2), (cpx2, cpy2)]
            } else {
                let ppx1 = -bw * 0.32 + pkW / 2
                let ppx2 = bw * 0.10 + pkW / 2
                let ppy = -bl * 0.1
                positions = [(ppx1, ppy), (ppx2, ppy)]
            }
            let pkZ = depth / 2 + 0.5
            for (px, py) in positions {
                let pk = SCNNode(geometry: pkGeom)
                pk.position = SCNVector3(px, py, pkZ)
                group.addChildNode(pk)
            }
        }

        // ZIPPER
        if state.closure == .zip {
            let zipGeom = SCNBox(width: 0.6, height: bl * 0.9, length: 1, chamferRadius: 0)
            zipGeom.materials = [accentMat]
            let zip = SCNNode(geometry: zipGeom)
            let zipZ = depth / 2 + 0.6
            zip.position = SCNVector3(0, 0, zipZ)
            group.addChildNode(zip)
        }

        // Back graphic panel
        if state.graphic != .off {
            let plateGeom = SCNPlane(width: bw * 0.7, height: bl * 0.45)
            let graphicMat = material(color: cw.accent)
            graphicMat.diffuse.contents = platformColor(for: cw.accent, opacity: 0.6)
            plateGeom.materials = [graphicMat]
            let plate = SCNNode(geometry: plateGeom)
            plate.position = SCNVector3(0, bl * 0.05, -depth / 2 - 0.3)
            plate.eulerAngles = SCNVector3(0, Float.pi, 0)
            group.addChildNode(plate)
        }

        scene.rootNode.addChildNode(group)
    }

    // MARK: - Helpers

    private func createTaperedBox(width: CGFloat, height: CGFloat, depth: CGFloat, taper: CGFloat, material mat: SCNMaterial) -> SCNNode {
        let hw = Float(width / 2)
        let hh = Float(height / 2)
        let hd = Float(depth / 2)
        let tw = Float(taper) * hw  // tapered half-width at bottom

        // 8 vertices: top 4 (full width) + bottom 4 (tapered)
        let vertices: [SCNVector3] = [
            // Top face (y = +hh)
            SCNVector3(-hw, hh, hd),   // 0: top-left-front
            SCNVector3(hw, hh, hd),    // 1: top-right-front
            SCNVector3(hw, hh, -hd),   // 2: top-right-back
            SCNVector3(-hw, hh, -hd),  // 3: top-left-back
            // Bottom face (y = -hh), tapered
            SCNVector3(-tw, -hh, hd),  // 4: bot-left-front
            SCNVector3(tw, -hh, hd),   // 5: bot-right-front
            SCNVector3(tw, -hh, -hd),  // 6: bot-right-back
            SCNVector3(-tw, -hh, -hd), // 7: bot-left-back
        ]

        // 12 triangles (6 faces x 2 triangles)
        let indices: [Int32] = [
            // Front face
            0, 4, 5,  0, 5, 1,
            // Back face
            2, 6, 7,  2, 7, 3,
            // Top face
            3, 0, 1,  3, 1, 2,
            // Bottom face
            4, 7, 6,  4, 6, 5,
            // Left face
            3, 7, 4,  3, 4, 0,
            // Right face
            1, 5, 6,  1, 6, 2,
        ]

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: 12, bytesPerIndex: MemoryLayout<Int32>.size)

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.materials = [mat]

        let node = SCNNode(geometry: geometry)
        // Compute flat normals by enabling flatShading on material
        mat.lightingModel = .lambert
        return node
    }

    private func material(color: Color) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = platformColor(for: color, opacity: 1.0)
        mat.lightingModel = .lambert
        return mat
    }

    private func platformColor(hex: String) -> Any {
        #if os(macOS)
        return NSColor(Color(hex: hex))
        #else
        return UIColor(Color(hex: hex))
        #endif
    }

    private func platformColor(for color: Color, opacity: CGFloat) -> Any {
        #if os(macOS)
        return NSColor(color.opacity(opacity))
        #else
        return UIColor(color.opacity(opacity))
        #endif
    }

    class Coordinator {
        var scnView: SCNView?
    }
}
