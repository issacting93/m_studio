import SwiftUI
import UniformTypeIdentifiers

struct InspectorView: View {
    @Bindable var state: DesignState

    @State private var exportFileURL: URL?
    @State private var showingExporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.silhouette.displayName)
                        .font(.custom(Theme.fontDisplay, size: 13))
                        .fontWeight(.black)
                        .foregroundColor(Theme.ink)
                    Text(state.silhouette.code)
                        .font(.custom(Theme.fontMono, size: 9))
                        .foregroundColor(Theme.soft)
                }
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.soft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 2) {
                    // Context-sensitive: component selected overrides stage
                    if let compID = state.selectedComponentID,
                       let index = state.placedComponents.firstIndex(where: { $0.id == compID }) {
                        componentInspector(index: index)
                    } else {
                        // Stage-driven inspector
                        switch state.stage {
                        case .shape:
                            measurementsCard
                        case .detail:
                            constructionCard
                        case .surface:
                            graphicZonesCard
                            colorBlockingCard
                        case .spec:
                            specCard
                            measurementsCard
                        case .export:
                            exportCard
                            specCard
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 280)
        .background(Theme.paper)
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.border).frame(width: 1)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(url: exportFileURL),
            contentType: {
                switch exportFileURL?.pathExtension {
                case "json": return .json
                case "pdf": return .pdf
                case "mstudio": return .mstudio
                default: return .data
                }
            }(),
            defaultFilename: exportFileURL?.lastPathComponent ?? "export"
        ) { _ in }
    }

    // MARK: - Component Inspector

    private func componentInspector(index: Int) -> some View {
        InspectorCard(title: "Component", icon: "puzzlepiece") {
            VStack(spacing: 10) {
                HStack {
                    Text(state.placedComponents[index].type.displayName)
                        .font(.custom(Theme.fontUI, size: 12))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.ink)
                    Spacer()
                    Button {
                        state.placedComponents.remove(at: index)
                        state.selectedComponentID = nil
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 9))
                            Text("Delete")
                                .font(.custom(Theme.fontUI, size: 9))
                        }
                        .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }

                // Panel picker
                HStack(spacing: 3) {
                    ForEach(ComponentPanel.allCases) { panel in
                        Button {
                            state.placedComponents[index].panel = panel
                        } label: {
                            Text(panel.displayName)
                                .font(.custom(Theme.fontUI, size: 9))
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(state.placedComponents[index].panel == panel ? Theme.ink : Theme.border)
                                .foregroundColor(state.placedComponents[index].panel == panel ? .white : Theme.ink)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                WarmSlider(label: "Position X", value: Binding(
                    get: { state.placedComponents[index].x },
                    set: { state.placedComponents[index].x = $0 }
                ), range: 0...1)
                WarmSlider(label: "Position Y", value: Binding(
                    get: { state.placedComponents[index].y },
                    set: { state.placedComponents[index].y = $0 }
                ), range: 0...1)
                WarmSlider(label: "Width", value: Binding(
                    get: { state.placedComponents[index].w },
                    set: { state.placedComponents[index].w = $0 }
                ), range: 0.02...0.8)
                WarmSlider(label: "Height", value: Binding(
                    get: { state.placedComponents[index].h },
                    set: { state.placedComponents[index].h = $0 }
                ), range: 0.02...0.8)

                HStack(spacing: 6) {
                    PillButton(label: "Flip", icon: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                        state.placedComponents[index].flipped.toggle()
                    }
                    PillButton(label: "+15\u{00B0}", icon: "rotate.right") {
                        state.placedComponents[index].rotation += 15
                    }
                }

                Button {
                    withAnimation(.easeOut(duration: 0.15)) { state.selectedComponentID = nil }
                } label: {
                    Text("Deselect")
                        .font(.custom(Theme.fontUI, size: 10))
                        .foregroundColor(Theme.soft)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Measurements

    private var measurementsCard: some View {
        InspectorCard(title: "Measurements", icon: "ruler") {
            VStack(spacing: 8) {
                // Size picker
                HStack(spacing: 3) {
                    ForEach(GarmentSize.allCases) { size in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { state.size = size }
                        } label: {
                            Text(size.rawValue)
                                .font(.custom(Theme.fontMono, size: 9))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(state.size == size ? Theme.ink : Theme.border)
                                .foregroundColor(state.size == size ? .white : Theme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                        }
                        .buttonStyle(.plain)
                    }
                }

                WarmSlider(label: "Body length", value: $state.bodyLength, range: 50...115, unit: "cm")
                WarmSlider(label: "Body width", value: $state.bodyWidth, range: 48...92, unit: "cm")
                WarmSlider(label: "Shoulder", value: $state.shoulderWidth, range: 38...66, unit: "cm")
                WarmSlider(label: "Hem width", value: $state.hemWidth, range: 44...90, unit: "cm")
                WarmSlider(label: "Sleeve length", value: $state.sleeveLength, range: 18...80, unit: "cm")
                WarmSlider(label: "Bicep", value: $state.sleeveDepth, range: 18...48, unit: "cm")
                WarmSlider(label: "Cuff", value: $state.sleeveOpen, range: 12...42, unit: "cm")
                WarmSlider(label: "Neck width", value: $state.neckOpeningWidth, range: 12...26, unit: "cm")
                WarmSlider(label: "Armhole", value: $state.armholeDepth, range: 18...36, unit: "cm")
                WarmSlider(label: "Collar height", value: $state.collarHeight, range: 2...15, unit: "cm")
                if state.silhouette == .noragi {
                    WarmSlider(label: "Overlap", value: $state.overlap, range: 4...28, unit: "cm")
                }
            }
        }
    }

    // MARK: - Construction

    private var constructionCard: some View {
        InspectorCard(title: "Construction", icon: "wrench.and.screwdriver") {
            VStack(alignment: .leading, spacing: 10) {
                WarmToggle(label: "Sleeve", selection: $state.sleeveType, options: SleeveType.allCases) { $0.label }
                WarmToggle(label: "Closure", selection: $state.closure, options: Closure.allCases) { $0.label }
                WarmToggle(label: "Pocket", selection: $state.pocket, options: Pocket.allCases) { $0.label }
                WarmToggle(label: "Collar", selection: $state.collarType, options: CollarType.allCases) { $0.label }
                WarmToggle(label: "Cuff", selection: $state.cuffType, options: CuffType.allCases) { $0.label }
                WarmToggle(label: "Hem", selection: $state.hemType, options: HemType.allCases) { $0.label }
                WarmToggle(label: "Graphic", selection: $state.graphic, options: GraphicStyle.allCases) { $0.label }
            }
        }
    }

    // MARK: - Graphic Zones

    private var graphicZonesCard: some View {
        InspectorCard(title: "Graphic Zones", icon: "rectangle.on.rectangle") {
            VStack(spacing: 8) {
                // Add zone buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(ZoneLocation.allCases) { loc in
                        let exists = state.graphicZones.contains { $0.location == loc }
                        Button {
                            if exists {
                                if let zone = state.graphicZones.first(where: { $0.location == loc }) {
                                    state.activeZoneID = zone.id
                                }
                            } else {
                                state.addZone(location: loc)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: loc.icon)
                                    .font(.system(size: 10))
                                Text(loc.displayName)
                                    .font(.custom(Theme.fontUI, size: 7))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(exists ? Theme.accent.opacity(0.1) : Theme.border)
                            .foregroundColor(exists ? Theme.accent : Theme.soft)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Active zones list
                if !state.graphicZones.isEmpty {
                    VStack(spacing: 3) {
                        ForEach(state.graphicZones) { zone in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(state.activeZoneID == zone.id ? Theme.accent : Theme.soft.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(zone.location.displayName)
                                    .font(.custom(Theme.fontUI, size: 10))
                                    .foregroundColor(Theme.ink)
                                Spacer()
                                Button {
                                    state.removeZone(id: zone.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundColor(Theme.soft)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                            .onTapGesture { state.activeZoneID = zone.id }
                        }
                    }
                }

                // Active zone properties
                if let activeID = state.activeZoneID,
                   let index = state.graphicZones.firstIndex(where: { $0.id == activeID }) {
                    Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)

                    VStack(spacing: 8) {
                        // Tint
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tint")
                                .font(.custom(Theme.fontUI, size: 10))
                                .foregroundColor(Theme.soft)
                            HStack(spacing: 3) {
                                ForEach(GraphicTint.allCases) { tint in
                                    Button {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            state.graphicZones[index].tint = tint
                                        }
                                    } label: {
                                        Text(tint.label)
                                            .font(.custom(Theme.fontUI, size: 9))
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(state.graphicZones[index].tint == tint ? Theme.ink : Theme.border)
                                            .foregroundColor(state.graphicZones[index].tint == tint ? .white : Theme.ink)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Print Method
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Print Method")
                                .font(.custom(Theme.fontUI, size: 10))
                                .foregroundColor(Theme.soft)
                            HStack(spacing: 3) {
                                ForEach(PrintMethod.allCases) { method in
                                    Button {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            state.graphicZones[index].printMethod = method
                                        }
                                    } label: {
                                        Text(method.label)
                                            .font(.custom(Theme.fontUI, size: 9))
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 4)
                                            .background(state.graphicZones[index].printMethod == method ? Theme.ink : Theme.border)
                                            .foregroundColor(state.graphicZones[index].printMethod == method ? .white : Theme.ink)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Opacity
                        WarmSlider(label: "Opacity", value: Binding(
                            get: { state.graphicZones[index].opacity },
                            set: { state.graphicZones[index].opacity = $0 }
                        ), range: 0.05...1.0)

                        // Rotation
                        WarmSlider(label: "Rotation", value: Binding(
                            get: { state.graphicZones[index].rotation },
                            set: { state.graphicZones[index].rotation = $0 }
                        ), range: 0...360, unit: "deg")

                        // Flip
                        HStack(spacing: 6) {
                            PillButton(label: "Flip H", icon: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                                state.graphicZones[index].flipped.toggle()
                            }
                        }

                        // Position & Size
                        WarmSlider(label: "Position X", value: Binding(
                            get: { state.graphicZones[index].frame.x },
                            set: { state.graphicZones[index].frame.x = $0 }
                        ), range: 0...1)
                        WarmSlider(label: "Position Y", value: Binding(
                            get: { state.graphicZones[index].frame.y },
                            set: { state.graphicZones[index].frame.y = $0 }
                        ), range: 0...1)
                        WarmSlider(label: "Width", value: Binding(
                            get: { state.graphicZones[index].frame.w },
                            set: { state.graphicZones[index].frame.w = $0 }
                        ), range: 0.05...1.0)
                        WarmSlider(label: "Height", value: Binding(
                            get: { state.graphicZones[index].frame.h },
                            set: { state.graphicZones[index].frame.h = $0 }
                        ), range: 0.05...1.0)

                        // Clear graphic
                        if state.graphicZones[index].svgContent != nil {
                            PillButton(label: "Clear Graphic", icon: "xmark") {
                                state.graphicZones[index].svgContent = nil
                                state.importedSVG = nil
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Color Blocking

    private var colorBlockingCard: some View {
        InspectorCard(title: "Color Blocking", icon: "paintpalette") {
            VStack(spacing: 5) {
                ForEach(GarmentPanel.allCases) { panel in
                    HStack(spacing: 4) {
                        Text(panel.displayName)
                            .font(.custom(Theme.fontUI, size: 10))
                            .foregroundColor(Theme.soft)
                            .frame(width: 50, alignment: .leading)
                        ForEach(PanelColorChoice.allCases) { choice in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    state.colorBlocking.set(choice, for: panel)
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(choice.resolve(with: state.colorway))
                                    .frame(width: 22, height: 16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(state.colorBlocking.choice(for: panel) == choice ? Theme.ink : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Spec Summary

    private var specCard: some View {
        let yards = state.yardage(for: state.size)
        let specs: [(String, String)] = [
            ("Silhouette", state.silhouette.displayName),
            ("Size", state.size.rawValue),
            ("Body", "\(Int(state.bodyLength)) x \(Int(state.bodyWidth)) cm"),
            ("Sleeve", "\(Int(state.sleeveLength)) / \(state.sleeveType.label)"),
            ("Colorway", state.colorway.displayName),
            ("Fabric", state.fabric.displayName),
            ("Yardage", String(format: "%.2f yd", yards)),
            ("Cost", "$\(Int(state.materialCost(for: state.size)))"),
        ]

        return InspectorCard(title: "Spec Summary", icon: "doc.text") {
            VStack(spacing: 4) {
                ForEach(Array(specs.enumerated()), id: \.offset) { _, spec in
                    HStack {
                        Text(spec.0)
                            .font(.custom(Theme.fontUI, size: 10))
                            .foregroundColor(Theme.soft)
                        Spacer()
                        Text(spec.1)
                            .font(.custom(Theme.fontMono, size: 10))
                            .fontWeight(.medium)
                            .foregroundColor(Theme.ink)
                    }
                }
            }
        }
    }

    // MARK: - Export

    private var exportCard: some View {
        InspectorCard(title: "Export", icon: "square.and.arrow.up") {
            VStack(spacing: 5) {
                PillButton(label: "Export .mstudio", icon: "shippingbox") { exportPackage() }

                Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)

                HStack(spacing: 4) {
                    PillButton(label: "PDF", icon: "doc.richtext") { exportFile(.pdf) }
                    PillButton(label: "DXF", icon: "square.on.square.dashed") { exportFile(.dxf) }
                    PillButton(label: "JSON", icon: "curlybraces") { exportFile(.json) }
                }
                PillButton(label: "Blender Package", icon: "cube") { exportBlender() }
            }
        }
    }

    private func exportFile(_ type: ExportType) {
        let service = ExportService(state: state)
        switch type {
        case .pdf: exportFileURL = PDFExportService(state: state).generatePDF()
        case .dxf: exportFileURL = service.exportDXF()
        case .json: exportFileURL = service.exportJSON()
        }
        if exportFileURL != nil { showingExporter = true }
    }

    private func exportPackage() {
        let service = PackageExportService(state: state)
        if let url = service.export() {
            exportFileURL = url
            showingExporter = true
        }
    }

    private func exportBlender() {
        let blenderService = BlenderScriptService(state: state)
        _ = OBJExportService(state: state).export()
        _ = blenderService.exportPatternOBJ()
        if let url = blenderService.exportBlenderScript() {
            exportFileURL = url
            showingExporter = true
        }
    }

    private enum ExportType { case pdf, dxf, json }
}

// MARK: - Inspector Card

struct InspectorCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.soft)
                        .frame(width: 14)
                    Text(title)
                        .font(.custom(Theme.fontUI, size: 11))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.ink)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.soft)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        .padding(.vertical, 2)
    }
}

// MARK: - Warm Slider

struct WarmSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var unit: String = ""

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom(Theme.fontUI, size: 10))
                .foregroundColor(Theme.soft)
                .frame(width: 70, alignment: .leading)
            Slider(value: $value, in: range, step: range.upperBound <= 1 ? 0.01 : 1)
                .tint(Theme.accent)
            Text(unit.isEmpty ? String(format: "%.2f", value) : "\(Int(value))")
                .font(.custom(Theme.fontMono, size: 9))
                .fontWeight(.medium)
                .foregroundColor(Theme.ink)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Warm Toggle

struct WarmToggle<T: Identifiable & Equatable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let text: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom(Theme.fontUI, size: 10))
                .foregroundColor(Theme.soft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(options) { option in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { selection = option }
                        } label: {
                            Text(text(option))
                                .font(.custom(Theme.fontUI, size: 9))
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selection == option ? Theme.ink : Theme.border)
                                .foregroundColor(selection == option ? .white : Theme.ink)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
