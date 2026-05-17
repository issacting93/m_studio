import SwiftUI
import UniformTypeIdentifiers

struct ToolPanelView: View {
    @Bindable var state: DesignState
    var storage: DesignStorage

    @State private var showingSVGImporter = false
    @State private var showingFigmaImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Brand header
            HStack(spacing: 8) {
                Image(systemName: "scissors")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.accent)
                Text("M-Studio")
                    .font(.custom(Theme.fontDisplay, size: 15))
                    .fontWeight(.black)
                    .foregroundColor(Theme.ink)
                Spacer()
                Text("v0.4")
                    .font(.custom(Theme.fontMono, size: 9))
                    .foregroundColor(Theme.soft)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.border)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 2) {
                    silhouetteCard
                    viewSwitcherCard
                    componentCard
                    graphicsCard
                    colorwayCard
                    fabricCard
                    workspaceCard
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 224)
        .background(Theme.paper)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.border).frame(width: 1)
        }
        .fileImporter(isPresented: $showingSVGImporter, allowedContentTypes: [.svg]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let str = String(data: data, encoding: .utf8) {
                        state.importedSVG = SVGContent.fromFile(str)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingFigmaImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        state.customColorways.append(contentsOf: FigmaTokenImporter.parse(jsonData: data))
                    }
                }
            }
        }
    }

    // MARK: - Silhouette

    private var silhouetteCard: some View {
        ToolCard(title: "Silhouette", icon: "tshirt") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(Silhouette.allCases) { silo in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            state.silhouette = silo
                            state.applySilhouetteDefaults()
                        }
                    } label: {
                        VStack(spacing: 3) {
                            SilhouetteIcon(silhouette: silo)
                                .frame(width: 22, height: 22)
                            Text(silo.shortCode)
                                .font(.custom(Theme.fontMono, size: 6.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(state.silhouette == silo ? Theme.ink : Theme.surface)
                        .foregroundColor(state.silhouette == silo ? .white : Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Views

    private var viewSwitcherCard: some View {
        ToolCard(title: "View", icon: "rectangle.stack") {
            VStack(spacing: 2) {
                ForEach(CanvasTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { state.activeTab = tab }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconForTab(tab))
                                .font(.system(size: 10))
                                .frame(width: 14)
                            Text(tab.label)
                                .font(.custom(Theme.fontUI, size: 11))
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(state.activeTab == tab ? Theme.accent.opacity(0.1) : Color.clear)
                        .foregroundColor(state.activeTab == tab ? Theme.accent : Theme.soft)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func iconForTab(_ tab: CanvasTab) -> String {
        switch tab {
        case .garment: return "figure.stand"
        case .threeD: return "cube"
        case .pattern: return "rectangle.split.3x3"
        case .colorway: return "paintpalette"
        case .sizes: return "ruler"
        case .sourcing: return "shippingbox"
        }
    }

    // MARK: - Components

    private var componentCard: some View {
        ToolCard(title: "Components", icon: "puzzlepiece") {
            ComponentLibraryView(state: state)
        }
    }

    // MARK: - Graphics

    private var graphicsCard: some View {
        ToolCard(title: "Graphics", icon: "photo.artframe") {
            GraphicLibraryView(state: state)
        }
    }

    // MARK: - Colorway

    private var colorwayCard: some View {
        ToolCard(title: "Colorway", icon: "paintpalette") {
            VStack(spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                    ForEach(Colorway.allCases) { cw in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { state.colorway = cw }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cw.primary)
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
                            .frame(height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(state.colorway == cw ? Theme.ink : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 4) {
                    PillButton(label: "Import SVG", icon: "square.and.arrow.down") { showingSVGImporter = true }
                    PillButton(label: "Figma", icon: "paintbrush") { showingFigmaImporter = true }
                }
            }
        }
    }

    // MARK: - Fabric

    private var fabricCard: some View {
        ToolCard(title: "Fabric", icon: "square.3.layers.3d") {
            VStack(spacing: 2) {
                ForEach(Fabric.allCases) { fb in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { state.fabric = fb }
                    } label: {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 14, height: 14)
                            Text(fb.displayName)
                                .font(.custom(Theme.fontUI, size: 10))
                                .foregroundColor(Theme.ink)
                            Spacer()
                            Text("$\(fb.cost)")
                                .font(.custom(Theme.fontMono, size: 9))
                                .foregroundColor(Theme.soft)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(state.fabric == fb ? Theme.accent.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Workspace

    @State private var showingSaveDialog = false
    @State private var saveName = ""

    private var workspaceCard: some View {
        ToolCard(title: "Workspace", icon: "folder") {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    PillButton(label: "Save", icon: "square.and.arrow.down") {
                        saveName = "\(state.silhouette.displayName)-\(state.colorway.displayName)-\(state.size.rawValue)"
                        showingSaveDialog = true
                    }
                    PillButton(label: "Random", icon: "shuffle") { state.randomize() }
                }

                if !storage.designs.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(storage.designs) { design in
                            HStack {
                                Button { storage.load(design: design, into: state) } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc")
                                            .font(.system(size: 9))
                                            .foregroundColor(Theme.soft)
                                        Text(design.name)
                                            .font(.custom(Theme.fontUI, size: 10))
                                            .foregroundColor(Theme.ink)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                                Spacer()
                                Button { storage.delete(design: design) } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(Theme.soft)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .alert("Save Design", isPresented: $showingSaveDialog) {
            TextField("Name", text: $saveName)
            Button("Save") {
                guard !saveName.isEmpty else { return }
                storage.save(name: saveName, state: state)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Tool Card

struct ToolCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — tap to collapse
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        .padding(.vertical, 2)
    }
}

// MARK: - Pill Button

struct PillButton: View {
    let label: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .medium))
                }
                Text(label)
                    .font(.custom(Theme.fontUI, size: 9))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Theme.ink)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
