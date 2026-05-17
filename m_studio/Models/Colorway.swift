import SwiftUI

enum Colorway: String, CaseIterable, Identifiable {
    case stealth, hazard, tactical, gunmetal, arctic, inferno, cyber, sand
    var id: String { rawValue }

    var displayName: String { rawValue.uppercased() }

    var primary: Color {
        switch self {
        case .stealth: return Color(hex: "#1a1a1a")
        case .hazard: return Color(hex: "#f4c10f")
        case .tactical: return Color(hex: "#3a4a2e")
        case .gunmetal: return Color(hex: "#5a5d63")
        case .arctic: return Color(hex: "#e8e6e0")
        case .inferno: return Color(hex: "#d63d2e")
        case .cyber: return Color(hex: "#1a1a1a")
        case .sand: return Color(hex: "#c8b896")
        }
    }

    var secondary: Color {
        switch self {
        case .stealth: return Color(hex: "#2a2a2a")
        case .hazard: return Color(hex: "#1a1a1a")
        case .tactical: return Color(hex: "#2a2f22")
        case .gunmetal: return Color(hex: "#3a3d43")
        case .arctic: return Color(hex: "#c0bdb4")
        case .inferno: return Color(hex: "#8b1d12")
        case .cyber: return Color(hex: "#0a0a0a")
        case .sand: return Color(hex: "#a89674")
        }
    }

    var accent: Color {
        switch self {
        case .stealth: return Color(hex: "#d63d2e")
        case .hazard: return Color(hex: "#d63d2e")
        case .tactical: return Color(hex: "#d6b15d")
        case .gunmetal: return Color(hex: "#2864db")
        case .arctic: return Color(hex: "#1a1a1a")
        case .inferno: return Color(hex: "#ffd60a")
        case .cyber: return Color(hex: "#00ffe0")
        case .sand: return Color(hex: "#5d3a1f")
        }
    }

    var graphic: Color {
        switch self {
        case .stealth: return Color(hex: "#ffffff")
        case .hazard: return Color(hex: "#1a1a1a")
        case .tactical: return Color(hex: "#f1ede3")
        case .gunmetal: return Color(hex: "#f1ede3")
        case .arctic: return Color(hex: "#1a1a1a")
        case .inferno: return Color(hex: "#1a1a1a")
        case .cyber: return Color(hex: "#ff007a")
        case .sand: return Color(hex: "#1a1a1a")
        }
    }
    // Hex string accessors for export
    var primaryHex: String {
        switch self {
        case .stealth: return "#1a1a1a"; case .hazard: return "#f4c10f"; case .tactical: return "#3a4a2e"
        case .gunmetal: return "#5a5d63"; case .arctic: return "#e8e6e0"; case .inferno: return "#d63d2e"
        case .cyber: return "#1a1a1a"; case .sand: return "#c8b896"
        }
    }
    var secondaryHex: String {
        switch self {
        case .stealth: return "#2a2a2a"; case .hazard: return "#1a1a1a"; case .tactical: return "#2a2f22"
        case .gunmetal: return "#3a3d43"; case .arctic: return "#c0bdb4"; case .inferno: return "#8b1d12"
        case .cyber: return "#0a0a0a"; case .sand: return "#a89674"
        }
    }
    var accentHex: String {
        switch self {
        case .stealth: return "#d63d2e"; case .hazard: return "#d63d2e"; case .tactical: return "#d6b15d"
        case .gunmetal: return "#2864db"; case .arctic: return "#1a1a1a"; case .inferno: return "#ffd60a"
        case .cyber: return "#00ffe0"; case .sand: return "#5d3a1f"
        }
    }
    var graphicHex: String {
        switch self {
        case .stealth: return "#ffffff"; case .hazard: return "#1a1a1a"; case .tactical: return "#f1ede3"
        case .gunmetal: return "#f1ede3"; case .arctic: return "#1a1a1a"; case .inferno: return "#1a1a1a"
        case .cyber: return "#ff007a"; case .sand: return "#1a1a1a"
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
