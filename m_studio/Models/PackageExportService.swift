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

            // Build ZIP in memory and write to disk
            let zipURL = tmpDir.appendingPathComponent("\(packageName).mstudio")
            let zipData = try buildZip(from: packageDir)
            try zipData.write(to: zipURL)

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

    // MARK: - ZIP Builder (pure Swift, no shell)

    private func buildZip(from directory: URL) throws -> Data {
        let fm = FileManager.default
        var files: [(relativePath: String, data: Data)] = []

        // Collect all files recursively
        let basePath = directory.path
        if let enumerator = fm.enumerator(atPath: basePath) {
            while let relativePath = enumerator.nextObject() as? String {
                let fullPath = (basePath as NSString).appendingPathComponent(relativePath)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue {
                    if let data = fm.contents(atPath: fullPath) {
                        files.append((relativePath: relativePath, data: data))
                    }
                }
            }
        }

        var zipData = Data()

        struct FileEntry {
            let offset: UInt32
            let crc32: UInt32
            let compressedSize: UInt32
            let uncompressedSize: UInt32
            let nameData: Data
        }

        var entries: [FileEntry] = []

        // Write local file headers + data (stored, no compression)
        for file in files {
            let nameData = Data(file.relativePath.utf8)
            let crc = crc32Checksum(file.data)
            let size = UInt32(file.data.count)
            let offset = UInt32(zipData.count)

            entries.append(FileEntry(offset: offset, crc32: crc, compressedSize: size, uncompressedSize: size, nameData: nameData))

            // Local file header (30 bytes + name)
            zipData.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // signature
            zipData.appendUInt16(20)      // version needed
            zipData.appendUInt16(0)       // flags
            zipData.appendUInt16(0)       // compression: stored
            zipData.appendUInt16(0)       // mod time
            zipData.appendUInt16(0)       // mod date
            zipData.appendUInt32(crc)     // crc-32
            zipData.appendUInt32(size)    // compressed size
            zipData.appendUInt32(size)    // uncompressed size
            zipData.appendUInt16(UInt16(nameData.count)) // name length
            zipData.appendUInt16(0)       // extra field length
            zipData.append(nameData)      // file name
            zipData.append(file.data)     // file data
        }

        // Central directory
        let cdOffset = UInt32(zipData.count)
        for entry in entries {
            zipData.append(contentsOf: [0x50, 0x4B, 0x01, 0x02]) // signature
            zipData.appendUInt16(20)      // version made by
            zipData.appendUInt16(20)      // version needed
            zipData.appendUInt16(0)       // flags
            zipData.appendUInt16(0)       // compression
            zipData.appendUInt16(0)       // mod time
            zipData.appendUInt16(0)       // mod date
            zipData.appendUInt32(entry.crc32)
            zipData.appendUInt32(entry.compressedSize)
            zipData.appendUInt32(entry.uncompressedSize)
            zipData.appendUInt16(UInt16(entry.nameData.count))
            zipData.appendUInt16(0)       // extra field length
            zipData.appendUInt16(0)       // comment length
            zipData.appendUInt16(0)       // disk number
            zipData.appendUInt16(0)       // internal attrs
            zipData.appendUInt32(0)       // external attrs
            zipData.appendUInt32(entry.offset) // local header offset
            zipData.append(entry.nameData)
        }

        let cdSize = UInt32(zipData.count) - cdOffset

        // End of central directory
        zipData.append(contentsOf: [0x50, 0x4B, 0x05, 0x06]) // signature
        zipData.appendUInt16(0)           // disk number
        zipData.appendUInt16(0)           // disk with CD
        zipData.appendUInt16(UInt16(entries.count)) // entries on disk
        zipData.appendUInt16(UInt16(entries.count)) // total entries
        zipData.appendUInt32(cdSize)      // CD size
        zipData.appendUInt32(cdOffset)    // CD offset
        zipData.appendUInt16(0)           // comment length

        return zipData
    }

    private func crc32Checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (crc & 1 == 1 ? 0xEDB88320 : 0)
            }
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
    mutating func appendUInt32(_ value: UInt32) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
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
