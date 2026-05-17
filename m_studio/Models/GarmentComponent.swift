import Foundation

// MARK: - Component Types

enum ComponentCategory: String, CaseIterable, Identifiable {
    case pockets, closures, hardware, patches, stitching, straps
    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    var types: [ComponentType] {
        ComponentType.allCases.filter { $0.category == self }
    }
}

enum ComponentType: String, Codable, CaseIterable, Identifiable {
    // Pockets
    case pocketPatch, pocketWelt, pocketZipWelt, pocketCargo, pocketMolle, pocketSleeveZip
    // Closures
    case zipperFull, zipperHalf, snapRow, buckleRelease
    // Hardware
    case dRing, carabiner, pullerTab, eyelet
    // Patches
    case patchRect, patchCircle, labelWoven
    // Stitching
    case stitchTopstitch, stitchBarTack, stitchDartLine
    // Straps
    case webbingStrap, drawcord, elasticCord, chainLink

    var id: String { rawValue }

    var category: ComponentCategory {
        switch self {
        case .pocketPatch, .pocketWelt, .pocketZipWelt, .pocketCargo, .pocketMolle, .pocketSleeveZip:
            return .pockets
        case .zipperFull, .zipperHalf, .snapRow, .buckleRelease:
            return .closures
        case .dRing, .carabiner, .pullerTab, .eyelet:
            return .hardware
        case .patchRect, .patchCircle, .labelWoven:
            return .patches
        case .stitchTopstitch, .stitchBarTack, .stitchDartLine:
            return .stitching
        case .webbingStrap, .drawcord, .elasticCord, .chainLink:
            return .straps
        }
    }

    var displayName: String {
        switch self {
        case .pocketPatch: return "Patch"
        case .pocketWelt: return "Welt"
        case .pocketZipWelt: return "Zip Welt"
        case .pocketCargo: return "Cargo"
        case .pocketMolle: return "MOLLE"
        case .pocketSleeveZip: return "Sleeve Zip"
        case .zipperFull: return "Full Zip"
        case .zipperHalf: return "Half Zip"
        case .snapRow: return "Snap Row"
        case .buckleRelease: return "Buckle"
        case .dRing: return "D-Ring"
        case .carabiner: return "Carabiner"
        case .pullerTab: return "Puller"
        case .eyelet: return "Eyelet"
        case .patchRect: return "Rect Patch"
        case .patchCircle: return "Circle Patch"
        case .labelWoven: return "Label"
        case .stitchTopstitch: return "Topstitch"
        case .stitchBarTack: return "Bar Tack"
        case .stitchDartLine: return "Dart Line"
        case .webbingStrap: return "Webbing"
        case .drawcord: return "Drawcord"
        case .elasticCord: return "Elastic"
        case .chainLink: return "Chain"
        }
    }

    /// Default size (normalized) for this component type
    var defaultSize: (w: Double, h: Double) {
        switch self {
        case .pocketPatch: return (0.20, 0.12)
        case .pocketWelt: return (0.25, 0.02)
        case .pocketZipWelt: return (0.25, 0.03)
        case .pocketCargo: return (0.20, 0.16)
        case .pocketMolle: return (0.20, 0.16)
        case .pocketSleeveZip: return (0.10, 0.20)
        case .zipperFull: return (0.02, 0.80)
        case .zipperHalf: return (0.02, 0.35)
        case .snapRow: return (0.02, 0.60)
        case .buckleRelease: return (0.12, 0.04)
        case .dRing: return (0.04, 0.04)
        case .carabiner: return (0.03, 0.06)
        case .pullerTab: return (0.03, 0.04)
        case .eyelet: return (0.02, 0.02)
        case .patchRect: return (0.12, 0.08)
        case .patchCircle: return (0.06, 0.06)
        case .labelWoven: return (0.08, 0.03)
        case .stitchTopstitch: return (0.30, 0.01)
        case .stitchBarTack: return (0.03, 0.02)
        case .stitchDartLine: return (0.01, 0.20)
        case .webbingStrap: return (0.35, 0.03)
        case .drawcord: return (0.30, 0.02)
        case .elasticCord: return (0.20, 0.02)
        case .chainLink: return (0.03, 0.15)
        }
    }
}

// MARK: - Placed Component

enum ComponentPanel: String, Codable, CaseIterable, Identifiable {
    case frontBody, backBody, leftSleeve, rightSleeve
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .frontBody: return "Front"
        case .backBody: return "Back"
        case .leftSleeve: return "L Sleeve"
        case .rightSleeve: return "R Sleeve"
        }
    }
}

struct PlacedComponent: Identifiable, Codable {
    var id = UUID()
    let type: ComponentType
    var x: Double       // normalized center X (0-1 relative to panel bounds)
    var y: Double       // normalized center Y (0-1)
    var w: Double       // normalized width
    var h: Double       // normalized height
    var rotation: Double = 0
    var panel: ComponentPanel = .frontBody
    var flipped: Bool = false

    init(type: ComponentType, panel: ComponentPanel = .frontBody) {
        self.type = type
        self.panel = panel
        let size = type.defaultSize
        self.x = 0.5
        self.y = 0.4
        self.w = size.w
        self.h = size.h
    }
}
