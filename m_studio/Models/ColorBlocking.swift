import SwiftUI

enum GarmentPanel: String, CaseIterable, Codable, Identifiable {
    case body, sleeves, hood, collar, cuffs, hem, pockets
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .body: return "Body"
        case .sleeves: return "Sleeves"
        case .hood: return "Hood"
        case .collar: return "Collar"
        case .cuffs: return "Cuffs"
        case .hem: return "Hem"
        case .pockets: return "Pockets"
        }
    }
}

enum PanelColorChoice: String, Codable, Equatable, CaseIterable, Identifiable {
    case primary, secondary, accent, graphic
    var id: String { rawValue }

    var label: String {
        switch self {
        case .primary: return "PRI"
        case .secondary: return "SEC"
        case .accent: return "ACC"
        case .graphic: return "GFX"
        }
    }

    func resolve(with colorway: Colorway) -> Color {
        switch self {
        case .primary: return colorway.primary
        case .secondary: return colorway.secondary
        case .accent: return colorway.accent
        case .graphic: return colorway.graphic
        }
    }
}

struct ColorBlockingConfig: Codable, Equatable {
    var assignments: [String: PanelColorChoice] = [:]

    func color(for panel: GarmentPanel, colorway: Colorway) -> Color {
        let choice = assignments[panel.rawValue] ?? defaultChoice(for: panel)
        return choice.resolve(with: colorway)
    }

    func choice(for panel: GarmentPanel) -> PanelColorChoice {
        assignments[panel.rawValue] ?? defaultChoice(for: panel)
    }

    mutating func set(_ choice: PanelColorChoice, for panel: GarmentPanel) {
        assignments[panel.rawValue] = choice
    }

    private func defaultChoice(for panel: GarmentPanel) -> PanelColorChoice {
        switch panel {
        case .body, .sleeves, .hood: return .primary
        case .collar, .cuffs, .hem: return .secondary
        case .pockets: return .secondary
        }
    }
}
