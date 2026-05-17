import SwiftUI

// MARK: - Enums

enum Silhouette: String, CaseIterable, Identifiable {
    case noragi, bomber, hoodie, parka, pullover, tshirt
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noragi: return "M-NORAGI"
        case .bomber: return "M-BOMBER"
        case .hoodie: return "M-HOODIE"
        case .parka: return "M-PARKA"
        case .pullover: return "M-PULL"
        case .tshirt: return "M-TEE"
        }
    }

    var code: String {
        switch self {
        case .noragi: return "M-NRG-001"
        case .bomber: return "M-BMB-001"
        case .hoodie: return "M-HOD-001"
        case .parka: return "M-PRK-001"
        case .pullover: return "M-PUL-001"
        case .tshirt: return "M-TEE-001"
        }
    }

    var shortCode: String {
        switch self {
        case .noragi: return "M-NRG"
        case .bomber: return "M-BMB"
        case .hoodie: return "M-HOD"
        case .parka: return "M-PRK"
        case .pullover: return "M-PUL"
        case .tshirt: return "M-TEE"
        }
    }

    var defaults: SilhouetteDefaults {
        switch self {
        case .noragi: return SilhouetteDefaults(bodyLength: 85, bodyWidth: 68, sleeveLength: 42, sleeveDepth: 32, sleeveOpen: 28, sleeveType: .dropped, closure: .tie, pocket: .patch, overlap: 15, shoulderWidth: 60, neckOpeningWidth: 20, neckOpeningDepth: 10, armholeDepth: 28, hemWidth: 68, collarHeight: 4, collarType: .crew, cuffType: .open, hemType: .folded)
        case .bomber: return SilhouetteDefaults(bodyLength: 62, bodyWidth: 58, sleeveLength: 62, sleeveDepth: 32, sleeveOpen: 22, sleeveType: .raglan, closure: .zip, pocket: .welt, overlap: 6, shoulderWidth: 46, neckOpeningWidth: 18, neckOpeningDepth: 8, armholeDepth: 24, hemWidth: 50, collarHeight: 4, collarType: .stand, cuffType: .ribbed, hemType: .ribbed)
        case .hoodie: return SilhouetteDefaults(bodyLength: 68, bodyWidth: 60, sleeveLength: 64, sleeveDepth: 34, sleeveOpen: 22, sleeveType: .raglan, closure: .zip, pocket: .welt, overlap: 6, shoulderWidth: 48, neckOpeningWidth: 18, neckOpeningDepth: 8, armholeDepth: 26, hemWidth: 54, collarHeight: 5, collarType: .hood, cuffType: .ribbed, hemType: .ribbed)
        case .parka: return SilhouetteDefaults(bodyLength: 92, bodyWidth: 64, sleeveLength: 65, sleeveDepth: 36, sleeveOpen: 24, sleeveType: .setin, closure: .zip, pocket: .cargo, overlap: 8, shoulderWidth: 50, neckOpeningWidth: 19, neckOpeningDepth: 9, armholeDepth: 28, hemWidth: 64, collarHeight: 6, collarType: .hood, cuffType: .elastic, hemType: .drawcord)
        case .pullover: return SilhouetteDefaults(bodyLength: 70, bodyWidth: 60, sleeveLength: 64, sleeveDepth: 34, sleeveOpen: 22, sleeveType: .raglan, closure: .none, pocket: .kangaroo, overlap: 0, shoulderWidth: 52, neckOpeningWidth: 18, neckOpeningDepth: 8, armholeDepth: 26, hemWidth: 54, collarHeight: 5, collarType: .hood, cuffType: .ribbed, hemType: .ribbed)
        case .tshirt: return SilhouetteDefaults(bodyLength: 72, bodyWidth: 52, sleeveLength: 22, sleeveDepth: 22, sleeveOpen: 20, sleeveType: .setin, closure: .none, pocket: .none, overlap: 0, shoulderWidth: 44, neckOpeningWidth: 18, neckOpeningDepth: 8, armholeDepth: 22, hemWidth: 52, collarHeight: 3, collarType: .crew, cuffType: .open, hemType: .folded)
        }
    }
}

enum SleeveType: String, CaseIterable, Identifiable {
    case dropped, raglan, setin
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dropped: return "Dropped"
        case .raglan: return "Raglan"
        case .setin: return "Set-in"
        }
    }
}

enum Closure: String, CaseIterable, Identifiable {
    case zip, tie, snap, buckle, none
    var id: String { rawValue }
    var label: String {
        switch self {
        case .zip: return "YKK Zip"
        case .tie: return "Tie"
        case .snap: return "Snap"
        case .buckle: return "Buckle"
        case .none: return "None"
        }
    }
}

enum Pocket: String, CaseIterable, Identifiable {
    case welt, zipperedWelt, patch, cargo, molle, kangaroo, none
    var id: String { rawValue }
    var label: String {
        switch self {
        case .welt: return "Welt"
        case .zipperedWelt: return "Zip Welt"
        case .patch: return "Patch"
        case .cargo: return "Cargo"
        case .molle: return "MOLLE"
        case .kangaroo: return "Kangaroo"
        case .none: return "None"
        }
    }
}

enum CollarType: String, CaseIterable, Identifiable {
    case crew, mock, funnel, stand, hood
    var id: String { rawValue }
    var label: String {
        switch self {
        case .crew: return "Crew"
        case .mock: return "Mock"
        case .funnel: return "Funnel"
        case .stand: return "Stand"
        case .hood: return "Hood"
        }
    }
}

enum CuffType: String, CaseIterable, Identifiable {
    case ribbed, elastic, thumbhole, open
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ribbed: return "Ribbed"
        case .elastic: return "Elastic"
        case .thumbhole: return "Thumb"
        case .open: return "Open"
        }
    }
}

enum HemType: String, CaseIterable, Identifiable {
    case ribbed, drawcord, raw, folded
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ribbed: return "Ribbed"
        case .drawcord: return "Drawcord"
        case .raw: return "Raw"
        case .folded: return "Folded"
        }
    }
}

enum GraphicStyle: String, CaseIterable, Identifiable, Codable {
    case milspec, mecha, type, ai, off
    var id: String { rawValue }
    var label: String {
        switch self {
        case .milspec: return "Mil-spec"
        case .mecha: return "Mecha"
        case .type: return "Typo"
        case .ai: return "AI"
        case .off: return "Off"
        }
    }
}

enum GarmentSize: String, CaseIterable, Identifiable {
    case XS, S, M, L, XL, XXL
    var id: String { rawValue }
}

enum DesignStage: String, CaseIterable, Identifiable {
    case shape, detail, surface, spec, export
    var id: String { rawValue }

    var label: String {
        switch self {
        case .shape: return "Shape"
        case .detail: return "Detail"
        case .surface: return "Surface"
        case .spec: return "Spec"
        case .export: return "Export"
        }
    }

    var icon: String {
        switch self {
        case .shape: return "figure.stand"
        case .detail: return "puzzlepiece"
        case .surface: return "paintpalette"
        case .spec: return "ruler"
        case .export: return "square.and.arrow.up"
        }
    }

    var number: Int {
        switch self {
        case .shape: return 1
        case .detail: return 2
        case .surface: return 3
        case .spec: return 4
        case .export: return 5
        }
    }
}

enum CanvasTab: String, CaseIterable, Identifiable {
    case garment, threeD, pattern, colorway, sizes, sourcing
    var id: String { rawValue }
    var label: String {
        switch self {
        case .garment: return "Garment"
        case .threeD: return "3D View"
        case .pattern: return "Flat Pattern"
        case .colorway: return "Colorway"
        case .sizes: return "Size Grade"
        case .sourcing: return "Sourcing"
        }
    }
}

// MARK: - Data Structs

struct SilhouetteDefaults {
    let bodyLength: Double
    let bodyWidth: Double
    let sleeveLength: Double
    let sleeveDepth: Double
    let sleeveOpen: Double
    let sleeveType: SleeveType
    let closure: Closure
    let pocket: Pocket
    let overlap: Double
    let shoulderWidth: Double
    let neckOpeningWidth: Double
    let neckOpeningDepth: Double
    let armholeDepth: Double
    let hemWidth: Double
    let collarHeight: Double
    let collarType: CollarType
    let cuffType: CuffType
    let hemType: HemType
}

struct GradeRule {
    let body: Double
    let length: Double
    let sleeveLen: Double
    let sleeveD: Double
    let cuff: Double
    let shoulder: Double
    let neck: Double
    let armhole: Double
    let hem: Double

    static let rules: [GarmentSize: GradeRule] = [
        .XS: GradeRule(body: -8, length: -4, sleeveLen: -6, sleeveD: -4, cuff: -3, shoulder: -2, neck: -1, armhole: -2, hem: -4),
        .S: GradeRule(body: -4, length: -2, sleeveLen: -3, sleeveD: -2, cuff: -1.5, shoulder: -1, neck: -0.5, armhole: -1, hem: -2),
        .M: GradeRule(body: 0, length: 0, sleeveLen: 0, sleeveD: 0, cuff: 0, shoulder: 0, neck: 0, armhole: 0, hem: 0),
        .L: GradeRule(body: 4, length: 2, sleeveLen: 3, sleeveD: 2, cuff: 1.5, shoulder: 1, neck: 0.5, armhole: 1, hem: 2),
        .XL: GradeRule(body: 8, length: 4, sleeveLen: 6, sleeveD: 4, cuff: 3, shoulder: 2, neck: 1, armhole: 2, hem: 4),
        .XXL: GradeRule(body: 12, length: 6, sleeveLen: 9, sleeveD: 6, cuff: 4.5, shoulder: 3, neck: 1.5, armhole: 3, hem: 6),
    ]
}

struct GradedMeasurements {
    let bodyLength: Double
    let bodyWidth: Double
    let sleeveLength: Double
    let sleeveDepth: Double
    let sleeveOpen: Double
    let shoulderWidth: Double
    let neckOpeningWidth: Double
    let armholeDepth: Double
    let hemWidth: Double
    let collarHeight: Double
}

struct GraphicZone {
    var x: Double = 0.5
    var y: Double = 0.18
    var w: Double = 0.9
    var h: Double = 0.42
}

// MARK: - Observable State

@Observable
final class DesignState {
    var silhouette: Silhouette = .noragi
    var activeTab: CanvasTab = .garment
    var stage: DesignStage = .shape
    var size: GarmentSize = .M

    var bodyLength: Double = 85
    var bodyWidth: Double = 62
    var overlap: Double = 15
    var sleeveLength: Double = 42
    var sleeveDepth: Double = 32
    var sleeveOpen: Double = 28

    var shoulderWidth: Double = 60
    var neckOpeningWidth: Double = 20
    var neckOpeningDepth: Double = 10
    var armholeDepth: Double = 28
    var hemWidth: Double = 68
    var collarHeight: Double = 4

    var sleeveType: SleeveType = .dropped
    var closure: Closure = .tie
    var pocket: Pocket = .patch
    var graphic: GraphicStyle = .milspec
    var collarType: CollarType = .crew
    var cuffType: CuffType = .ribbed
    var hemType: HemType = .ribbed

    var colorway: Colorway = .stealth
    var fabric: Fabric = .ripstop70

    var graphicZone = GraphicZone()  // legacy — used by renderer for backward compat
    var aiGraphicSVG: String? = nil
    var importedSVG: SVGContent? = nil

    // Multi-zone system
    var graphicZones: [GraphicZoneConfig] = [
        GraphicZoneConfig(location: .fullBack)
    ]
    var activeZoneID: UUID? = nil

    var activeZone: GraphicZoneConfig? {
        get { graphicZones.first { $0.id == activeZoneID } }
    }

    func addZone(location: ZoneLocation) {
        guard !graphicZones.contains(where: { $0.location == location }) else { return }
        let zone = GraphicZoneConfig(location: location, style: graphic)
        graphicZones.append(zone)
        activeZoneID = zone.id
    }

    func removeZone(id: UUID) {
        graphicZones.removeAll { $0.id == id }
        if activeZoneID == id { activeZoneID = nil }
    }
    var metadata = DesignMetadata()
    var colorBlocking = ColorBlockingConfig()
    var customColorways: [CustomColorway] = []
    var activeCustomColorway: CustomColorway? = nil

    // Component system
    var placedComponents: [PlacedComponent] = []
    var selectedComponentID: UUID? = nil

    // Mode
    var editMode: Bool = false  // false = parametric mode, true = edit/place mode

    func applySilhouetteDefaults() {
        let d = silhouette.defaults
        bodyLength = d.bodyLength
        bodyWidth = d.bodyWidth
        sleeveLength = d.sleeveLength
        sleeveDepth = d.sleeveDepth
        sleeveOpen = d.sleeveOpen
        sleeveType = d.sleeveType
        closure = d.closure
        pocket = d.pocket
        overlap = d.overlap
        shoulderWidth = d.shoulderWidth
        neckOpeningWidth = d.neckOpeningWidth
        neckOpeningDepth = d.neckOpeningDepth
        armholeDepth = d.armholeDepth
        hemWidth = d.hemWidth
        collarHeight = d.collarHeight
        collarType = d.collarType
        cuffType = d.cuffType
        hemType = d.hemType
    }

    func gradedMeasurements(for size: GarmentSize) -> GradedMeasurements {
        let g = GradeRule.rules[size]!
        return GradedMeasurements(
            bodyLength: bodyLength + g.length,
            bodyWidth: bodyWidth + g.body,
            sleeveLength: sleeveLength + g.sleeveLen,
            sleeveDepth: sleeveDepth + g.sleeveD,
            sleeveOpen: sleeveOpen + g.cuff,
            shoulderWidth: shoulderWidth + g.shoulder,
            neckOpeningWidth: neckOpeningWidth + g.neck,
            armholeDepth: armholeDepth + g.armhole,
            hemWidth: hemWidth + g.hem,
            collarHeight: collarHeight
        )
    }

    func yardage(for size: GarmentSize) -> Double {
        let m = gradedMeasurements(for: size)
        let area = ((m.bodyLength * m.bodyWidth + m.sleeveLength * m.sleeveDepth * 2) * 1.25) / 10000
        return area / 1.28
    }

    func materialCost(for size: GarmentSize) -> Double {
        yardage(for: size) * Double(fabric.cost)
    }

    func randomize() {
        silhouette = Silhouette.allCases.randomElement()!
        applySilhouetteDefaults()
        colorway = Colorway.allCases.randomElement()!
        fabric = Fabric.allCases.randomElement()!
        graphic = [GraphicStyle.milspec, .mecha, .type].randomElement()!
    }
}
