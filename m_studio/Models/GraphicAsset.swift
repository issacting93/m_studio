import Foundation

// MARK: - Graphic Asset Category

enum GraphicCategory: String, CaseIterable, Identifiable {
    case biomech
    case geometric
    case type
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .biomech: return "BIOMECH"
        case .geometric: return "GEO"
        case .type: return "TYPE"
        case .custom: return "CUSTOM"
        }
    }
}

// MARK: - Graphic Asset

struct GraphicAsset: Identifiable, Equatable {
    let id: String
    let name: String
    let filename: String
    let category: GraphicCategory

    static func == (lhs: GraphicAsset, rhs: GraphicAsset) -> Bool {
        lhs.id == rhs.id
    }

    /// Load SVG content from the app bundle
    func loadSVGContent() -> SVGContent? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "svg") else { return nil }
        return loadFromURL(url)
    }

    private func loadFromURL(_ url: URL) -> SVGContent? {
        guard let data = try? Data(contentsOf: url),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return SVGContent.fromFile(str)
    }

    // MARK: - Bundled Library

    static let bundled: [GraphicAsset] = [
        GraphicAsset(id: "frame-43", name: "Rorschach I", filename: "Frame 43", category: .biomech),
        GraphicAsset(id: "frame-45", name: "Rorschach II", filename: "Frame 45", category: .biomech),
        GraphicAsset(id: "frame-5", name: "Rorschach III", filename: "Frame 5", category: .biomech),
    ]

    static func assets(for category: GraphicCategory) -> [GraphicAsset] {
        bundled.filter { $0.category == category }
    }

    /// Categories that have at least one asset
    static var activeCategories: [GraphicCategory] {
        GraphicCategory.allCases.filter { cat in
            bundled.contains { $0.category == cat }
        }
    }
}
