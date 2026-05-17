import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ExportService {
    let state: DesignState

    // MARK: - DXF Export

    func buildDXF() -> String {
        var pieces: [(name: String, pts: [(Double, Double)])] = []
        let bw = state.bodyWidth
        let bl = state.bodyLength
        let sl = state.sleeveLength
        let sd = state.sleeveDepth

        // Back piece
        pieces.append((name: "BACK", pts: [(0, 0), (bw, 0), (bw, bl), (0, bl), (0, 0)]))

        // Sleeve L
        pieces.append((name: "SLEEVE_L", pts: [
            (bw + 10, 0), (bw + 10 + sl, 0),
            (bw + 10 + sl, sd), (bw + 10, sd), (bw + 10, 0)
        ]))

        // Sleeve R
        pieces.append((name: "SLEEVE_R", pts: [
            (bw + 20 + sl, 0), (bw + 20 + 2 * sl, 0),
            (bw + 20 + 2 * sl, sd), (bw + 20 + sl, sd), (bw + 20 + sl, 0)
        ]))

        // Collar strip
        let cw: Double = 5
        pieces.append((name: "COLLAR", pts: [
            (0, bl + 10), (bl * 1.4, bl + 10),
            (bl * 1.4, bl + 10 + cw * 2), (0, bl + 10 + cw * 2), (0, bl + 10)
        ]))

        // Front panels (non-noragi)
        if state.silhouette != .noragi {
            pieces.append((name: "FRONT_L", pts: [
                (0, bl + 30), (bw / 2, bl + 30),
                (bw / 2, bl * 1.7 + 30), (0, bl * 1.7 + 30), (0, bl + 30)
            ]))
            pieces.append((name: "FRONT_R", pts: [
                (bw / 2 + 10, bl + 30), (bw + 10, bl + 30),
                (bw + 10, bl * 1.7 + 30), (bw / 2 + 10, bl * 1.7 + 30), (bw / 2 + 10, bl + 30)
            ]))
        }

        var dxf = ""
        dxf += "0\nSECTION\n2\nHEADER\n0\nENDSEC\n"
        dxf += "0\nSECTION\n2\nTABLES\n"
        dxf += "0\nTABLE\n2\nLAYER\n70\n2\n"
        dxf += "0\nLAYER\n2\n0\n70\n0\n62\n7\n6\nCONTINUOUS\n"
        dxf += "0\nLAYER\n2\nPATTERN\n70\n0\n62\n7\n6\nCONTINUOUS\n"
        dxf += "0\nENDTAB\n0\nENDSEC\n"
        dxf += "0\nSECTION\n2\nENTITIES\n"

        for piece in pieces {
            dxf += "0\nPOLYLINE\n8\nPATTERN\n66\n1\n70\n1\n"
            for pt in piece.pts {
                dxf += "0\nVERTEX\n8\nPATTERN\n10\n\(pt.0)\n20\n\(pt.1)\n30\n0\n"
            }
            dxf += "0\nSEQEND\n8\nPATTERN\n"
            dxf += "0\nTEXT\n8\nPATTERN\n10\n\(piece.pts[0].0 + 2)\n20\n\(piece.pts[0].1 + 2)\n30\n0\n40\n3\n1\n\(piece.name)\n"
        }

        dxf += "0\nENDSEC\n0\nEOF\n"
        return dxf
    }

    // MARK: - JSON Tech Pack Export

    func buildTechPackJSON() -> String {
        let sizes: [GarmentSize] = GarmentSize.allCases
        var sizeData: [String: [String: Double]] = [:]
        for size in sizes {
            let m = state.gradedMeasurements(for: size)
            sizeData[size.rawValue] = [
                "bodyLength": m.bodyLength,
                "bodyWidth": m.bodyWidth,
                "sleeveLength": m.sleeveLength,
                "sleeveDepth": m.sleeveDepth,
                "sleeveOpen": m.sleeveOpen,
                "shoulderWidth": m.shoulderWidth,
                "neckOpeningWidth": m.neckOpeningWidth,
                "armholeDepth": m.armholeDepth,
                "hemWidth": m.hemWidth,
                "collarHeight": m.collarHeight
            ]
        }

        let data: [String: Any] = [
            "document": "\(state.silhouette.code).A",
            "silhouette": state.silhouette.rawValue,
            "designer": "Zac Ting",
            "generated": ISO8601DateFormatter().string(from: Date()),
            "measurements": [
                "bodyLength": state.bodyLength,
                "bodyWidth": state.bodyWidth,
                "overlap": state.overlap,
                "sleeveLength": state.sleeveLength,
                "sleeveDepth": state.sleeveDepth,
                "sleeveOpen": state.sleeveOpen,
                "shoulderWidth": state.shoulderWidth,
                "neckOpeningWidth": state.neckOpeningWidth,
                "neckOpeningDepth": state.neckOpeningDepth,
                "armholeDepth": state.armholeDepth,
                "hemWidth": state.hemWidth,
                "collarHeight": state.collarHeight,
                "sleeveType": state.sleeveType.rawValue,
                "closure": state.closure.rawValue,
                "pocket": state.pocket.rawValue,
                "graphic": state.graphic.rawValue,
                "collarType": state.collarType.rawValue,
                "cuffType": state.cuffType.rawValue,
                "hemType": state.hemType.rawValue,
                "size": state.size.rawValue
            ],
            "sizes": sizeData,
            "fabric": [
                "id": state.fabric.rawValue,
                "name": state.fabric.displayName,
                "spec": state.fabric.spec,
                "source": state.fabric.source,
                "cost": state.fabric.cost
            ],
            "colorway": [
                "id": state.colorway.rawValue,
                "name": state.colorway.displayName,
                "primary": state.colorway.primaryHex,
                "secondary": state.colorway.secondaryHex,
                "accent": state.colorway.accentHex,
                "graphic": state.colorway.graphicHex
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]) {
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }

    // MARK: - File Save Helpers

    func exportDXF() -> URL? {
        let content = buildDXF()
        return writeToTempFile(content: content, filename: "\(state.silhouette.code)-pattern.dxf")
    }

    func exportJSON() -> URL? {
        let content = buildTechPackJSON()
        return writeToTempFile(content: content, filename: "\(state.silhouette.code)-techpack.json")
    }

    private func writeToTempFile(content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}

// MARK: - Export Document for fileExporter

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .data] }

    let data: Data

    init(url: URL?) {
        if let url, let fileData = try? Data(contentsOf: url) {
            self.data = fileData
        } else {
            self.data = Data()
        }
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
