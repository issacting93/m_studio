import Foundation

// MARK: - Saved Design

struct SavedDesign: Identifiable, Codable {
    var id: String { name }
    let name: String
    let saved: Date
    let silhouette: String
    let size: String
    let bodyLength: Double
    let bodyWidth: Double
    let overlap: Double
    let sleeveLength: Double
    let sleeveDepth: Double
    let sleeveOpen: Double
    let sleeveType: String
    let closure: String
    let pocket: String
    let graphic: String
    let colorway: String
    let fabric: String
    let graphicZoneX: Double
    let graphicZoneY: Double
    let graphicZoneW: Double
    let graphicZoneH: Double
    // v0.4 POMs
    let shoulderWidth: Double
    let neckOpeningWidth: Double
    let neckOpeningDepth: Double
    let armholeDepth: Double
    let hemWidth: Double
    let collarHeight: Double

    enum CodingKeys: String, CodingKey {
        case name, saved, silhouette, size
        case bodyLength, bodyWidth, overlap
        case sleeveLength, sleeveDepth, sleeveOpen
        case sleeveType, closure, pocket, graphic, colorway, fabric
        case graphicZoneX, graphicZoneY, graphicZoneW, graphicZoneH
        case shoulderWidth, neckOpeningWidth, neckOpeningDepth
        case armholeDepth, hemWidth, collarHeight
    }

    init(name: String, state: DesignState) {
        self.name = name
        self.saved = Date()
        self.silhouette = state.silhouette.rawValue
        self.size = state.size.rawValue
        self.bodyLength = state.bodyLength
        self.bodyWidth = state.bodyWidth
        self.overlap = state.overlap
        self.sleeveLength = state.sleeveLength
        self.sleeveDepth = state.sleeveDepth
        self.sleeveOpen = state.sleeveOpen
        self.sleeveType = state.sleeveType.rawValue
        self.closure = state.closure.rawValue
        self.pocket = state.pocket.rawValue
        self.graphic = state.graphic.rawValue
        self.colorway = state.colorway.rawValue
        self.fabric = state.fabric.rawValue
        self.graphicZoneX = state.graphicZone.x
        self.graphicZoneY = state.graphicZone.y
        self.graphicZoneW = state.graphicZone.w
        self.graphicZoneH = state.graphicZone.h
        self.shoulderWidth = state.shoulderWidth
        self.neckOpeningWidth = state.neckOpeningWidth
        self.neckOpeningDepth = state.neckOpeningDepth
        self.armholeDepth = state.armholeDepth
        self.hemWidth = state.hemWidth
        self.collarHeight = state.collarHeight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        saved = try c.decode(Date.self, forKey: .saved)
        silhouette = try c.decode(String.self, forKey: .silhouette)
        size = try c.decode(String.self, forKey: .size)
        bodyLength = try c.decode(Double.self, forKey: .bodyLength)
        bodyWidth = try c.decode(Double.self, forKey: .bodyWidth)
        overlap = try c.decode(Double.self, forKey: .overlap)
        sleeveLength = try c.decode(Double.self, forKey: .sleeveLength)
        sleeveDepth = try c.decode(Double.self, forKey: .sleeveDepth)
        sleeveOpen = try c.decode(Double.self, forKey: .sleeveOpen)
        sleeveType = try c.decode(String.self, forKey: .sleeveType)
        closure = try c.decode(String.self, forKey: .closure)
        pocket = try c.decode(String.self, forKey: .pocket)
        graphic = try c.decode(String.self, forKey: .graphic)
        colorway = try c.decode(String.self, forKey: .colorway)
        fabric = try c.decode(String.self, forKey: .fabric)
        graphicZoneX = try c.decode(Double.self, forKey: .graphicZoneX)
        graphicZoneY = try c.decode(Double.self, forKey: .graphicZoneY)
        graphicZoneW = try c.decode(Double.self, forKey: .graphicZoneW)
        graphicZoneH = try c.decode(Double.self, forKey: .graphicZoneH)
        // v0.4 — backward compat with defaults
        let sil = Silhouette(rawValue: silhouette) ?? .noragi
        let defs = sil.defaults
        shoulderWidth = try c.decodeIfPresent(Double.self, forKey: .shoulderWidth) ?? defs.shoulderWidth
        neckOpeningWidth = try c.decodeIfPresent(Double.self, forKey: .neckOpeningWidth) ?? defs.neckOpeningWidth
        neckOpeningDepth = try c.decodeIfPresent(Double.self, forKey: .neckOpeningDepth) ?? defs.neckOpeningDepth
        armholeDepth = try c.decodeIfPresent(Double.self, forKey: .armholeDepth) ?? defs.armholeDepth
        hemWidth = try c.decodeIfPresent(Double.self, forKey: .hemWidth) ?? defs.hemWidth
        collarHeight = try c.decodeIfPresent(Double.self, forKey: .collarHeight) ?? defs.collarHeight
    }

    func apply(to state: DesignState) {
        state.silhouette = Silhouette(rawValue: silhouette) ?? .noragi
        state.size = GarmentSize(rawValue: size) ?? .M
        state.bodyLength = bodyLength
        state.bodyWidth = bodyWidth
        state.overlap = overlap
        state.sleeveLength = sleeveLength
        state.sleeveDepth = sleeveDepth
        state.sleeveOpen = sleeveOpen
        state.sleeveType = SleeveType(rawValue: sleeveType) ?? .dropped
        state.closure = Closure(rawValue: closure) ?? .zip
        state.pocket = Pocket(rawValue: pocket) ?? .welt
        state.graphic = GraphicStyle(rawValue: graphic) ?? .milspec
        state.colorway = Colorway(rawValue: colorway) ?? .stealth
        state.fabric = Fabric(rawValue: fabric) ?? .ripstop70
        state.graphicZone = GraphicZone(x: graphicZoneX, y: graphicZoneY, w: graphicZoneW, h: graphicZoneH)
        state.shoulderWidth = shoulderWidth
        state.neckOpeningWidth = neckOpeningWidth
        state.neckOpeningDepth = neckOpeningDepth
        state.armholeDepth = armholeDepth
        state.hemWidth = hemWidth
        state.collarHeight = collarHeight
    }
}

// MARK: - Design Storage

@Observable
final class DesignStorage {
    var designs: [SavedDesign] = []

    private var storageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("M-Studio Designs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        loadAll()
    }

    func save(name: String, state: DesignState) {
        let design = SavedDesign(name: name, state: state)
        let fileURL = storageURL.appendingPathComponent("\(sanitize(name)).json")
        if let data = try? JSONEncoder().encode(design) {
            try? data.write(to: fileURL, options: .atomic)
        }
        loadAll()
    }

    func load(design: SavedDesign, into state: DesignState) {
        design.apply(to: state)
    }

    func delete(design: SavedDesign) {
        let fileURL = storageURL.appendingPathComponent("\(sanitize(design.name)).json")
        try? FileManager.default.removeItem(at: fileURL)
        loadAll()
    }

    func loadAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            designs = []
            return
        }
        designs = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> SavedDesign? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SavedDesign.self, from: data)
            }
            .sorted { $0.saved > $1.saved }
    }

    private func sanitize(_ name: String) -> String {
        name.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }
}
