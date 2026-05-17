import SwiftUI

/// A user-defined colorway created from imported Figma tokens or custom input
struct CustomColorway: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String
    var graphicHex: String

    var primary: Color { Color(hex: primaryHex) }
    var secondary: Color { Color(hex: secondaryHex) }
    var accent: Color { Color(hex: accentHex) }
    var graphic: Color { Color(hex: graphicHex) }
}

/// Parses Figma design token JSON exports into colorways
struct FigmaTokenImporter {

    /// Parse a Figma token JSON file and extract colorways.
    /// Supports two formats:
    /// 1. Flat: keys like "stealth-primary", "stealth-secondary", etc.
    /// 2. Nested: { "stealth": { "primary": { "$value": "#1a1a1a" } } }
    static func parse(jsonData: Data) -> [CustomColorway] {
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return []
        }

        // Try nested format first
        var colorways: [String: [String: String]] = [:]  // name -> { role -> hex }

        for (key, value) in json {
            if let nested = value as? [String: Any] {
                // Check if it's a direct token { "$value": "#hex" }
                if let hex = nested["$value"] as? String, hex.hasPrefix("#") {
                    // Flat-ish: key contains the group name
                    let parts = key.split(separator: "-", maxSplits: 1)
                    if parts.count == 2 {
                        let group = String(parts[0]).lowercased()
                        let role = String(parts[1]).lowercased()
                        colorways[group, default: [:]][role] = hex
                    }
                } else {
                    // Nested group: { "primary": { "$value": "#hex" }, ... }
                    let group = key.lowercased()
                    for (subKey, subValue) in nested {
                        if let subDict = subValue as? [String: Any],
                           let hex = subDict["$value"] as? String, hex.hasPrefix("#") {
                            colorways[group, default: [:]][subKey.lowercased()] = hex
                        } else if let hex = subValue as? String, hex.hasPrefix("#") {
                            colorways[group, default: [:]][subKey.lowercased()] = hex
                        }
                    }
                }
            } else if let hex = value as? String, hex.hasPrefix("#") {
                // Simple flat: key is like "stealth-primary"
                let parts = key.split(separator: "-", maxSplits: 1)
                if parts.count == 2 {
                    let group = String(parts[0]).lowercased()
                    let role = String(parts[1]).lowercased()
                    colorways[group, default: [:]][role] = hex
                }
            }
        }

        return colorways.compactMap { (name, roles) -> CustomColorway? in
            guard let primary = roles["primary"] else { return nil }
            return CustomColorway(
                name: name.uppercased(),
                primaryHex: primary,
                secondaryHex: roles["secondary"] ?? primary,
                accentHex: roles["accent"] ?? "#d63d2e",
                graphicHex: roles["graphic"] ?? "#ffffff"
            )
        }.sorted { $0.name < $1.name }
    }
}
