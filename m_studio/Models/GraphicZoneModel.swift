import Foundation

// MARK: - Zone Location

enum ZoneLocation: String, CaseIterable, Codable, Identifiable {
    case fullBack
    case centerBackStrip
    case leftChest
    case rightChest
    case centerChest
    case leftSleeve
    case rightSleeve

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBack: return "Full Back"
        case .centerBackStrip: return "Back Strip"
        case .leftChest: return "Left Chest"
        case .rightChest: return "Right Chest"
        case .centerChest: return "Center Chest"
        case .leftSleeve: return "Left Sleeve"
        case .rightSleeve: return "Right Sleeve"
        }
    }

    var icon: String {
        switch self {
        case .fullBack, .centerBackStrip: return "rectangle.portrait"
        case .leftChest, .rightChest, .centerChest: return "rectangle"
        case .leftSleeve, .rightSleeve: return "rectangle.landscape.rotate"
        }
    }

    /// Which garment panel this zone lives on (front or back)
    var isFront: Bool {
        switch self {
        case .fullBack, .centerBackStrip: return false
        case .leftChest, .rightChest, .centerChest: return true
        case .leftSleeve, .rightSleeve: return true // drawn on front view
        }
    }

    var defaultFrame: GraphicZoneFrame {
        switch self {
        case .fullBack: return GraphicZoneFrame(x: 0.5, y: 0.18, w: 0.9, h: 0.42)
        case .centerBackStrip: return GraphicZoneFrame(x: 0.5, y: 0.1, w: 0.2, h: 0.7)
        case .leftChest: return GraphicZoneFrame(x: 0.3, y: 0.15, w: 0.25, h: 0.15)
        case .rightChest: return GraphicZoneFrame(x: 0.7, y: 0.15, w: 0.25, h: 0.15)
        case .centerChest: return GraphicZoneFrame(x: 0.5, y: 0.2, w: 0.5, h: 0.25)
        case .leftSleeve: return GraphicZoneFrame(x: 0.5, y: 0.2, w: 0.6, h: 0.5)
        case .rightSleeve: return GraphicZoneFrame(x: 0.5, y: 0.2, w: 0.6, h: 0.5)
        }
    }
}

// MARK: - Zone Frame

struct GraphicZoneFrame: Codable, Equatable {
    var x: Double  // normalized center X (0-1)
    var y: Double  // normalized top Y (0-1)
    var w: Double  // normalized width (0-1)
    var h: Double  // normalized height (0-1)
}

// MARK: - Print Method

enum PrintMethod: String, CaseIterable, Codable, Identifiable {
    case screen, dtf, sublimation, embroidery, hd

    var id: String { rawValue }

    var label: String {
        switch self {
        case .screen: return "Screen"
        case .dtf: return "DTF"
        case .sublimation: return "Sub"
        case .embroidery: return "Emb"
        case .hd: return "HD"
        }
    }
}

// MARK: - Graphic Tint

enum GraphicTint: String, CaseIterable, Codable, Identifiable {
    case white
    case accent
    case graphic
    case original

    var id: String { rawValue }

    var label: String {
        switch self {
        case .white: return "White"
        case .accent: return "Accent"
        case .graphic: return "Graphic"
        case .original: return "Original"
        }
    }
}

// MARK: - Zone Config

struct GraphicZoneConfig: Identifiable, Codable, Equatable {
    var id = UUID()
    var location: ZoneLocation
    var frame: GraphicZoneFrame
    var style: GraphicStyle = .milspec
    var svgContent: SVGContent? = nil
    var isActive: Bool = true
    var tint: GraphicTint = .white
    var opacity: Double = 1.0
    var rotation: Double = 0
    var flipped: Bool = false
    var printMethod: PrintMethod = .screen

    init(location: ZoneLocation, style: GraphicStyle = .milspec) {
        self.location = location
        self.frame = location.defaultFrame
        self.style = style
    }

    static func == (lhs: GraphicZoneConfig, rhs: GraphicZoneConfig) -> Bool {
        lhs.id == rhs.id
    }
}
