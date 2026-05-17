import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var state: DesignState
    var storage: DesignStorage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                brandHeader
                modeToggle
                if state.editMode {
                    componentSection
                } else {
                    silhouetteSection
                    sizeSection
                    bodySection
                    sleeveSection
                    featuresSection
                }
                colorwaySection
                colorBlockingSection
                fabricSection
                workspaceSection
            }
            .padding(.bottom, 20)
        }
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 340)
        .background(Theme.paper)
        .fileImporter(isPresented: $showingSVGImporter, allowedContentTypes: [.svg]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let svgString = String(data: data, encoding: .utf8) {
                        state.importedSVG = SVGContent.fromFile(svgString)
                    }
                }
            }
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("M-STUDIO")
                    .font(.custom("Archivo", size: 20))
                    .fontWeight(.black)
                    .foregroundColor(Theme.ink)
                    .tracking(2)
                Text("PATTERN LAB · TECHWEAR")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(2)
            }
            Spacer()
            Text("v0.3")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(Theme.soft)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(Rectangle().stroke(Theme.soft, lineWidth: 0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            Button {
                state.editMode = false
                state.selectedComponentID = nil
            } label: {
                Text("PARAMETRIC")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(!state.editMode ? Theme.ink : Color.clear)
                    .foregroundColor(!state.editMode ? Theme.paper : Theme.ink)
            }
            .buttonStyle(.plain)

            Button {
                state.editMode = true
            } label: {
                Text("EDIT / PLACE")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(state.editMode ? Theme.accent : Color.clear)
                    .foregroundColor(state.editMode ? .white : Theme.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
        }
    }

    // MARK: - Component Library

    private var componentSection: some View {
        SidebarSection(title: "Components", number: "//") {
            ComponentLibraryView(state: state)
        }
    }

    // MARK: - Silhouette

    private var silhouetteSection: some View {
        SidebarSection(title: "Silhouette", number: "01") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(Silhouette.allCases) { silo in
                    Button {
                        state.silhouette = silo
                        state.applySilhouetteDefaults()
                    } label: {
                        VStack(spacing: 3) {
                            Text(silo.shortCode)
                                .font(.custom("JetBrains Mono", size: 6.5))
                                .tracking(0.5)
                            SilhouetteIcon(silhouette: silo)
                                .frame(width: 28, height: 28)
                            Text(silo.rawValue.capitalized)
                                .font(.custom("JetBrains Mono", size: 7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(state.silhouette == silo ? Theme.ink : Color.clear)
                        .foregroundColor(state.silhouette == silo ? Theme.paper : Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Size

    private var sizeSection: some View {
        SidebarSection(title: "Size (Base)", number: "02") {
            HStack(spacing: 4) {
                ForEach(GarmentSize.allCases) { size in
                    Button {
                        state.size = size
                    } label: {
                        Text(size.rawValue)
                            .font(.custom("JetBrains Mono", size: 10))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(state.size == size ? Theme.ink : Color.clear)
                            .foregroundColor(state.size == size ? Theme.paper : Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Body

    private var bodySection: some View {
        SidebarSection(title: "Body", number: "03") {
            VStack(spacing: 10) {
                ParameterSlider(label: "Length", value: $state.bodyLength, range: 50...115, unit: "cm")
                ParameterSlider(label: "Width", value: $state.bodyWidth, range: 48...92, unit: "cm")
                ParameterSlider(label: "Shoulder", value: $state.shoulderWidth, range: 38...66, unit: "cm")
                ParameterSlider(label: "Hem Width", value: $state.hemWidth, range: 44...90, unit: "cm")
                ParameterSlider(label: "Neck Width", value: $state.neckOpeningWidth, range: 12...26, unit: "cm")
                ParameterSlider(label: "Neck Drop", value: $state.neckOpeningDepth, range: 4...14, unit: "cm")
                ParameterSlider(label: "Armhole", value: $state.armholeDepth, range: 18...36, unit: "cm")
                ParameterSlider(label: "Collar Ht", value: $state.collarHeight, range: 2...15, unit: "cm")
                if state.silhouette == .noragi {
                    ParameterSlider(label: "Front Overlap", value: $state.overlap, range: 4...28, unit: "cm")
                }
            }
        }
    }

    // MARK: - Sleeve

    private var sleeveSection: some View {
        SidebarSection(title: "Sleeve", number: "04") {
            VStack(spacing: 10) {
                ParameterSlider(label: "Length", value: $state.sleeveLength, range: 18...80, unit: "cm")
                ParameterSlider(label: "Bicep", value: $state.sleeveDepth, range: 18...48, unit: "cm")
                ParameterSlider(label: "Cuff", value: $state.sleeveOpen, range: 12...42, unit: "cm")
                ToggleGroup(selection: $state.sleeveType, options: SleeveType.allCases) { $0.label }
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        SidebarSection(title: "Features", number: "05") {
            VStack(alignment: .leading, spacing: 10) {
                Text("CLOSURE")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.closure, options: Closure.allCases) { $0.label }

                Text("POCKET")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.pocket, options: Pocket.allCases) { $0.label }

                Text("GRAPHIC STYLE")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.graphic, options: GraphicStyle.allCases) { $0.label }

                HStack(spacing: 6) {
                    ActionButton(label: "IMPORT SVG") { showingSVGImporter = true }
                    if state.importedSVG != nil {
                        ActionButton(label: "CLEAR") { state.importedSVG = nil }
                    }
                }

                Text("COLLAR")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.collarType, options: CollarType.allCases) { $0.label }

                Text("CUFF")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.cuffType, options: CuffType.allCases) { $0.label }

                Text("HEM")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)
                ToggleGroup(selection: $state.hemType, options: HemType.allCases) { $0.label }
            }
        }
    }

    // MARK: - Colorway

    private var colorwaySection: some View {
        SidebarSection(title: "Colorway", number: "06") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(Colorway.allCases) { cw in
                    Button {
                        state.colorway = cw
                    } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                Rectangle().fill(cw.primary)
                                GeometryReader { geo in
                                    Path { path in
                                        path.move(to: CGPoint(x: geo.size.width * 0.6, y: 0))
                                        path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                        path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height))
                                    }
                                    .fill(cw.accent)
                                }
                            }
                            .frame(height: 28)
                            .overlay(
                                Rectangle()
                                    .stroke(state.colorway == cw ? Theme.ink : Color.clear, lineWidth: 2)
                            )
                            Text(cw.displayName)
                                .font(.custom("JetBrains Mono", size: 7))
                                .foregroundColor(Theme.ink)
                                .tracking(0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom colorways from Figma
            if !state.customColorways.isEmpty {
                VStack(spacing: 4) {
                    ForEach(state.customColorways) { cw in
                        Button {
                            state.activeCustomColorway = cw
                        } label: {
                            HStack(spacing: 4) {
                                Rectangle().fill(cw.primary).frame(width: 14, height: 14)
                                Rectangle().fill(cw.accent).frame(width: 14, height: 14)
                                Text(cw.name)
                                    .font(.custom("JetBrains Mono", size: 7.5))
                                    .foregroundColor(Theme.ink)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .background(state.activeCustomColorway?.id == cw.id ? Theme.ink.opacity(0.05) : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ActionButton(label: "IMPORT FIGMA TOKENS") { showingFigmaImporter = true }
        }
        .fileImporter(isPresented: $showingFigmaImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        let imported = FigmaTokenImporter.parse(jsonData: data)
                        state.customColorways.append(contentsOf: imported)
                    }
                }
            }
        }
    }

    @State private var showingFigmaImporter = false

    // MARK: - Color Blocking

    private var colorBlockingSection: some View {
        SidebarSection(title: "Color Blocking", number: "06B") {
            VStack(spacing: 6) {
                ForEach(GarmentPanel.allCases) { panel in
                    HStack(spacing: 4) {
                        Text(panel.displayName.uppercased())
                            .font(.custom("JetBrains Mono", size: 7.5))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.ink)
                            .frame(width: 52, alignment: .leading)
                        ForEach(PanelColorChoice.allCases) { choice in
                            Button {
                                state.colorBlocking.set(choice, for: panel)
                            } label: {
                                Rectangle()
                                    .fill(choice.resolve(with: state.colorway))
                                    .frame(width: 24, height: 16)
                                    .overlay(
                                        Rectangle()
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

    // MARK: - Fabric

    private var fabricSection: some View {
        SidebarSection(title: "Fabric", number: "07") {
            VStack(spacing: 4) {
                ForEach(Fabric.allCases) { fb in
                    Button {
                        state.fabric = fb
                    } label: {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(fb.displayName)
                                    .font(.custom("JetBrains Mono", size: 9))
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.ink)
                                Text(fb.spec)
                                    .font(.custom("JetBrains Mono", size: 7.5))
                                    .foregroundColor(Theme.soft)
                            }
                            Spacer()
                            Text("$\(fb.cost)/yd")
                                .font(.custom("JetBrains Mono", size: 8))
                                .foregroundColor(Theme.soft)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(state.fabric == fb ? Theme.ink.opacity(0.05) : Color.clear)
                        .overlay(Rectangle().stroke(state.fabric == fb ? Theme.ink : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Workspace

    @State private var exportFileURL: URL?
    @State private var showingExporter = false
    @State private var showingSaveDialog = false
    @State private var saveName = ""
    @State private var showingSVGImporter = false

    private var workspaceSection: some View {
        SidebarSection(title: "Workspace", number: "08") {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ActionButton(label: "SAVE") {
                        saveName = "\(state.silhouette.displayName)-\(state.colorway.displayName)-\(state.size.rawValue)"
                        showingSaveDialog = true
                    }
                    ActionButton(label: "RANDOMIZE") { state.randomize() }
                }
                HStack(spacing: 6) {
                    ActionButton(label: "PDF") { exportFile(type: .pdf) }
                    ActionButton(label: "DXF") { exportFile(type: .dxf) }
                    ActionButton(label: "JSON") { exportFile(type: .json) }
                }
                HStack(spacing: 6) {
                    ActionButton(label: "BLENDER") { exportBlender() }
                }

                // Saved designs list
                if !storage.designs.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(storage.designs) { design in
                            HStack {
                                Button {
                                    storage.load(design: design, into: state)
                                } label: {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(design.name)
                                            .font(.custom("JetBrains Mono", size: 9))
                                            .fontWeight(.bold)
                                            .foregroundColor(Theme.ink)
                                        Text("\(design.silhouette.uppercased()) · \(design.saved.formatted(.dateTime.month(.abbreviated).day()))")
                                            .font(.custom("JetBrains Mono", size: 7.5))
                                            .foregroundColor(Theme.soft)
                                    }
                                }
                                .buttonStyle(.plain)
                                Spacer()
                                Button {
                                    storage.delete(design: design)
                                } label: {
                                    Text("x")
                                        .font(.custom("JetBrains Mono", size: 11))
                                        .foregroundColor(Theme.soft)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                            }
                        }
                    }
                } else {
                    Text("NO SAVED DESIGNS YET")
                        .font(.custom("JetBrains Mono", size: 8))
                        .foregroundColor(Theme.soft)
                        .tracking(1)
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(url: exportFileURL),
            contentType: exportFileURL?.pathExtension == "json" ? .json : (exportFileURL?.pathExtension == "pdf" ? .pdf : .data),
            defaultFilename: exportFileURL?.lastPathComponent ?? "export"
        ) { _ in }
        .alert("Save Design", isPresented: $showingSaveDialog) {
            TextField("Design name", text: $saveName)
            Button("Save") {
                guard !saveName.isEmpty else { return }
                storage.save(name: saveName, state: state)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this design")
        }
    }

    private func exportBlender() {
        let objService = OBJExportService(state: state)
        let blenderService = BlenderScriptService(state: state)
        let results = objService.export()
        _ = blenderService.exportPatternOBJ()
        let scriptURL = blenderService.exportBlenderScript()
        // Export the Blender script as the primary file
        if let url = scriptURL ?? results?.objURL {
            exportFileURL = url
            showingExporter = true
        }
    }

    private enum ExportType { case pdf, dxf, json }

    private func exportFile(type: ExportType) {
        let service = ExportService(state: state)
        switch type {
        case .pdf:
            let pdfService = PDFExportService(state: state)
            exportFileURL = pdfService.generatePDF()
        case .dxf:
            exportFileURL = service.exportDXF()
        case .json:
            exportFileURL = service.exportJSON()
        }
        if exportFileURL != nil {
            showingExporter = true
        }
    }
}

// MARK: - Section Container

struct SidebarSection<Content: View>: View {
    let title: String
    let number: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink)
                    .tracking(2)
                Spacer()
                Text(number)
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundColor(Theme.soft)
            }
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
        }
    }
}

// MARK: - Parameter Slider

struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .tracking(1)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(Theme.ink)
        }
    }
}

// MARK: - Toggle Group

struct ToggleGroup<T: Identifiable & Equatable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    selection = option
                } label: {
                    Text(label(option).uppercased())
                        .font(.custom("JetBrains Mono", size: 8.5))
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(selection == option ? Theme.ink : Color.clear)
                        .foregroundColor(selection == option ? Theme.paper : Theme.ink)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 9))
                .fontWeight(.bold)
                .tracking(1.5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.ink)
                .foregroundColor(Theme.paper)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Silhouette Icon

struct SilhouetteIcon: View {
    let silhouette: Silhouette

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let scale = s / 40

            switch silhouette {
            case .noragi:
                var path = Path()
                path.move(to: p(8, 8, scale))
                path.addLine(to: p(14, 8, scale))
                path.addLine(to: p(14, 12, scale))
                path.addLine(to: p(26, 12, scale))
                path.addLine(to: p(26, 8, scale))
                path.addLine(to: p(32, 8, scale))
                path.addLine(to: p(32, 16, scale))
                path.addLine(to: p(28, 16, scale))
                path.addLine(to: p(28, 32, scale))
                path.addLine(to: p(12, 32, scale))
                path.addLine(to: p(12, 16, scale))
                path.addLine(to: p(8, 16, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)

            case .bomber:
                var path = Path()
                path.move(to: p(10, 12, scale))
                path.addLine(to: p(14, 8, scale))
                path.addLine(to: p(26, 8, scale))
                path.addLine(to: p(30, 12, scale))
                path.addLine(to: p(32, 18, scale))
                path.addLine(to: p(30, 20, scale))
                path.addLine(to: p(30, 28, scale))
                path.addLine(to: p(10, 28, scale))
                path.addLine(to: p(10, 20, scale))
                path.addLine(to: p(8, 18, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)

            case .hoodie:
                var path = Path()
                path.move(to: p(14, 6, scale))
                path.addQuadCurve(to: p(26, 6, scale), control: p(20, 3, scale))
                path.addLine(to: p(28, 10, scale))
                path.addLine(to: p(32, 12, scale))
                path.addLine(to: p(30, 18, scale))
                path.addLine(to: p(30, 30, scale))
                path.addLine(to: p(10, 30, scale))
                path.addLine(to: p(10, 18, scale))
                path.addLine(to: p(8, 12, scale))
                path.addLine(to: p(12, 10, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)

            case .parka:
                var path = Path()
                path.move(to: p(14, 4, scale))
                path.addQuadCurve(to: p(26, 4, scale), control: p(20, 2, scale))
                path.addLine(to: p(28, 10, scale))
                path.addLine(to: p(32, 14, scale))
                path.addLine(to: p(30, 18, scale))
                path.addLine(to: p(30, 36, scale))
                path.addLine(to: p(10, 36, scale))
                path.addLine(to: p(10, 18, scale))
                path.addLine(to: p(8, 14, scale))
                path.addLine(to: p(12, 10, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)

            case .pullover:
                // Hoodie shape without center line (no zip)
                var path = Path()
                path.move(to: p(14, 4, scale))
                path.addQuadCurve(to: p(26, 4, scale), control: p(20, 2, scale))
                path.addLine(to: p(28, 10, scale))
                path.addLine(to: p(32, 12, scale))
                path.addLine(to: p(30, 18, scale))
                path.addLine(to: p(30, 30, scale))
                path.addLine(to: p(10, 30, scale))
                path.addLine(to: p(10, 18, scale))
                path.addLine(to: p(8, 12, scale))
                path.addLine(to: p(12, 10, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)
                // Kangaroo pocket
                var pk = Path()
                pk.addRect(CGRect(x: 13 * scale, y: 22 * scale, width: 14 * scale, height: 4 * scale))
                context.stroke(pk, with: .color(.primary), lineWidth: 0.8)

            case .tshirt:
                var path = Path()
                path.move(to: p(12, 10, scale))
                path.addLine(to: p(6, 10, scale))
                path.addLine(to: p(6, 18, scale))
                path.addLine(to: p(12, 18, scale))
                path.addLine(to: p(12, 34, scale))
                path.addLine(to: p(28, 34, scale))
                path.addLine(to: p(28, 18, scale))
                path.addLine(to: p(34, 18, scale))
                path.addLine(to: p(34, 10, scale))
                path.addLine(to: p(28, 10, scale))
                path.addLine(to: p(12, 10, scale))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.2)
                // Crew neck
                var neck = Path()
                neck.move(to: p(16, 10, scale))
                neck.addQuadCurve(to: p(24, 10, scale), control: p(20, 13, scale))
                context.stroke(neck, with: .color(.primary), lineWidth: 0.8)
            }
        }
    }

    private func p(_ x: CGFloat, _ y: CGFloat, _ scale: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }
}
