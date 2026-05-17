import Foundation

enum Fabric: String, CaseIterable, Identifiable {
    case ripstop70, taslan, shell3l, cordura, twillpoly, meshmil
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ripstop70: return "Ripstop 70D"
        case .taslan: return "Taslan 228T"
        case .shell3l: return "3L Shell"
        case .cordura: return "Cordura 500D"
        case .twillpoly: return "Poly Twill"
        case .meshmil: return "Mil Mesh"
        }
    }

    var spec: String {
        switch self {
        case .ripstop70: return "70 g/m² · DWR"
        case .taslan: return "120 g/m² · DWR"
        case .shell3l: return "210 g/m² · WP"
        case .cordura: return "320 g/m² · Abrasion"
        case .twillpoly: return "180 g/m² · Soft"
        case .meshmil: return "90 g/m² · Vent"
        }
    }

    var source: String {
        switch self {
        case .ripstop70: return "Ripstop by the Roll"
        case .taslan: return "Toray / Taiana"
        case .shell3l: return "Seattle Fabrics"
        case .cordura: return "Rockywoods"
        case .twillpoly: return "Big Duck Canvas"
        case .meshmil: return "Rockywoods"
        }
    }

    var cost: Int {
        switch self {
        case .ripstop70: return 8
        case .taslan: return 14
        case .shell3l: return 28
        case .cordura: return 18
        case .twillpoly: return 6
        case .meshmil: return 10
        }
    }

    // Blender cloth simulation properties
    var clothMass: Double {  // kg/m²
        switch self {
        case .ripstop70: return 0.07
        case .taslan: return 0.12
        case .shell3l: return 0.21
        case .cordura: return 0.32
        case .twillpoly: return 0.18
        case .meshmil: return 0.09
        }
    }

    var clothTensionStiffness: Double {
        switch self {
        case .ripstop70: return 15
        case .taslan: return 25
        case .shell3l: return 40
        case .cordura: return 60
        case .twillpoly: return 30
        case .meshmil: return 8
        }
    }

    var clothBendingStiffness: Double {
        switch self {
        case .ripstop70: return 0.5
        case .taslan: return 1.5
        case .shell3l: return 5.0
        case .cordura: return 8.0
        case .twillpoly: return 3.0
        case .meshmil: return 0.2
        }
    }
}
