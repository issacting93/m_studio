import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType

extension UTType {
    static let mstudio = UTType(exportedAs: "com.mstudio.package", conformingTo: .zip)
}

// MARK: - Package Export Service

struct PackageExportService {
    let state: DesignState

    /// Build a .mstudio package and return the URL of the resulting ZIP file.
    func export() -> URL? {
        let fm = FileManager.default
        let packageName = "\(state.silhouette.code)-\(state.colorway.rawValue)"
        let tmpDir = fm.temporaryDirectory.appendingPathComponent("mstudio-\(UUID().uuidString)")
        let packageDir = tmpDir.appendingPathComponent(packageName)
        let graphicsDir = packageDir.appendingPathComponent("graphics")

        do {
            try fm.createDirectory(at: graphicsDir, withIntermediateDirectories: true)

            // Write JSON files
            try buildManifest().write(to: packageDir.appendingPathComponent("manifest.json"))
            try buildColorway().write(to: packageDir.appendingPathComponent("colorway.json"))
            try buildGrading().write(to: packageDir.appendingPathComponent("grading.json"))
            try buildComponents().write(to: packageDir.appendingPathComponent("components.json"))

            // Write graphic SVGs + placements
            let placements = buildPlacementsAndWriteSVGs(to: graphicsDir)
            try placements.write(to: graphicsDir.appendingPathComponent("placements.json"))

            // ZIP the package directory
            let zipURL = tmpDir.appendingPathComponent("\(packageName).mstudio")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--sequesterRsrc", packageDir.path, zipURL.path]
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            // Clean up the unzipped directory
            try? fm.removeItem(at: packageDir)

            return zipURL
        } catch {
            try? fm.removeItem(at: tmpDir)
            return nil
        }
    }

    // MARK: - manifest.json

    private func buildManifest() -> Data {
        let manifest: [String: Any] = [
            "version": "1.0",
            "styleCode": "\(state.silhouette.code).A",
            "silhouette": state.silhouette.rawValue,
            "generated": ISO8601DateFormatter().string(from: Date()),
            "designer": state.metadata.designer,
            "season": state.metadata.season,
            "notes": state.metadata.notes,
            "measurements": [
                "bodyLength": state.bodyLength,
                "bodyWidth": state.bodyWidth,
                "sleeveLength": state.sleeveLength,
                "sleeveDepth": state.sleeveDepth,
                "sleeveOpen": state.sleeveOpen,
                "shoulderWidth": state.shoulderWidth,
                "neckOpeningWidth": state.neckOpeningWidth,
                "neckOpeningDepth": state.neckOpeningDepth,
                "armholeDepth": state.armholeDepth,
                "hemWidth": state.hemWidth,
                "collarHeight": state.collarHeight,
                "overlap": state.overlap,
            ],
            "construction": [
                "sleeveType": state.sleeveType.rawValue,
                "closure": state.closure.rawValue,
                "pocket": state.pocket.rawValue,
                "collarType": state.collarType.rawValue,
                "cuffType": state.cuffType.rawValue,
                "hemType": state.hemType.rawValue,
            ],
            "fabric": [
                "id": state.fabric.rawValue,
                "name": state.fabric.displayName,
                "spec": state.fabric.spec,
                "source": state.fabric.source,
                "cost": state.fabric.cost,
                "clothMass": state.fabric.clothMass,
                "tensionStiffness": state.fabric.clothTensionStiffness,
                "bendingStiffness": state.fabric.clothBendingStiffness,
            ] as [String: Any],
        ]
        return try! JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - colorway.json

    private func buildColorway() -> Data {
        // All colorway definitions
        var colorways: [String: Any] = [:]
        for cw in Colorway.allCases {
            colorways[cw.rawValue] = [
                "primary": cw.primaryHex,
                "secondary": cw.secondaryHex,
                "accent": cw.accentHex,
                "graphic": cw.graphicHex,
            ]
        }

        // Color blocking assignments
        var blocking: [String: String] = [:]
        for panel in GarmentPanel.allCases {
            blocking[panel.rawValue] = state.colorBlocking.choice(for: panel).rawValue
        }

        let colorwayData: [String: Any] = [
            "active": state.colorway.rawValue,
            "colorways": colorways,
            "blocking": blocking,
        ]
        return try! JSONSerialization.data(withJSONObject: colorwayData, options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - grading.json

    private func buildGrading() -> Data {
        var sizes: [String: Any] = [:]
        for size in GarmentSize.allCases {
            let m = state.gradedMeasurements(for: size)
            sizes[size.rawValue] = [
                "bodyLength": m.bodyLength,
                "bodyWidth": m.bodyWidth,
                "sleeveLength": m.sleeveLength,
                "sleeveDepth": m.sleeveDepth,
                "sleeveOpen": m.sleeveOpen,
                "shoulderWidth": m.shoulderWidth,
                "neckOpeningWidth": m.neckOpeningWidth,
                "armholeDepth": m.armholeDepth,
                "hemWidth": m.hemWidth,
                "collarHeight": m.collarHeight,
            ]
        }

        let grading: [String: Any] = [
            "baseSize": state.size.rawValue,
            "sizes": sizes,
        ]
        return try! JSONSerialization.data(withJSONObject: grading, options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - components.json

    private func buildComponents() -> Data {
        let components = state.placedComponents.map { comp -> [String: Any] in
            [
                "id": comp.id.uuidString,
                "type": comp.type.rawValue,
                "panel": comp.panel.rawValue,
                "x": comp.x,
                "y": comp.y,
                "w": comp.w,
                "h": comp.h,
                "rotation": comp.rotation,
                "flipped": comp.flipped,
            ]
        }
        return try! JSONSerialization.data(withJSONObject: ["components": components], options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - graphics/placements.json + SVG files

    private func buildPlacementsAndWriteSVGs(to graphicsDir: URL) -> Data {
        var zones: [[String: Any]] = []

        for (index, zone) in state.graphicZones.enumerated() where zone.isActive {
            let filename = "zone-\(index).svg"

            // Write SVG file if content exists
            if let svg = zone.svgContent {
                let svgURL = graphicsDir.appendingPathComponent(filename)
                try? svg.rawSVG.write(to: svgURL, atomically: true, encoding: .utf8)
            }

            // Resolve tint to RGB array
            let tintColor: [Double] = {
                switch zone.tint {
                case .white: return [1.0, 1.0, 1.0]
                case .accent:
                    let hex = state.colorway.accentHex
                    return hexToRGB(hex)
                case .graphic:
                    let hex = state.colorway.graphicHex
                    return hexToRGB(hex)
                case .original: return [0.0, 0.0, 0.0] // sentinel: no tint
                }
            }()

            let entry: [String: Any] = [
                "id": zone.id.uuidString,
                "location": zone.location.rawValue,
                "file": zone.svgContent != nil ? filename : "",
                "frame": [
                    "x": zone.frame.x,
                    "y": zone.frame.y,
                    "w": zone.frame.w,
                    "h": zone.frame.h,
                ],
                "tint": [
                    "mode": zone.tint.rawValue,
                    "color": tintColor,
                ] as [String: Any],
                "opacity": zone.opacity,
                "rotation": zone.rotation,
                "flipped": zone.flipped,
                "printMethod": zone.printMethod.rawValue,
            ]
            zones.append(entry)
        }

        return try! JSONSerialization.data(withJSONObject: ["zones": zones], options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - Helpers

    private func hexToRGB(_ hex: String) -> [Double] {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        return [
            Double((int >> 16) & 0xFF) / 255.0,
            Double((int >> 8) & 0xFF) / 255.0,
            Double(int & 0xFF) / 255.0,
        ]
    }
}

// MARK: - Export Document (for fileExporter)

struct MStudioDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.mstudio] }
    let url: URL

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = URL(fileURLWithPath: "/tmp/empty.mstudio")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}
