import SwiftUI

struct GraphicLibraryView: View {
    @Bindable var state: DesignState
    @State private var selectedCategory: GraphicCategory = .biomech
    @State private var loadedThumbnails: [String: SVGContent] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(GraphicCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            Text(cat.displayName)
                                .font(.custom("JetBrains Mono", size: 7))
                                .fontWeight(.bold)
                                .tracking(0.5)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(selectedCategory == cat ? Theme.ink : Color.clear)
                                .foregroundColor(selectedCategory == cat ? Theme.paper : Theme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Asset grid
            let assets = GraphicAsset.assets(for: selectedCategory)
            if assets.isEmpty {
                Text("No assets")
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                    ForEach(assets) { asset in
                        Button {
                            applyAsset(asset)
                        } label: {
                            VStack(spacing: 2) {
                                // SVG thumbnail
                                Canvas { context, size in
                                    // Dark background to preview graphic as it appears on garment
                                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.ink))
                                    if let svg = loadedThumbnails[asset.id] {
                                        let inset = CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6)
                                        SVGRenderer.render(svg, context: &context, in: inset, tintColor: .white, skipBackground: true)
                                    }
                                }
                                .frame(height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(isApplied(asset) ? Theme.accent : Theme.ink.opacity(0.1), lineWidth: isApplied(asset) ? 1.5 : 0.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                                Text(asset.name)
                                    .font(.custom("JetBrains Mono", size: 6.5))
                                    .foregroundColor(Theme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .draggable(asset.id) {
                            // Drag preview
                            VStack(spacing: 2) {
                                Canvas { context, size in
                                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.ink))
                                    if let svg = loadedThumbnails[asset.id] {
                                        let inset = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
                                        SVGRenderer.render(svg, context: &context, in: inset, tintColor: .white, skipBackground: true)
                                    }
                                }
                                .frame(width: 60, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(asset.name)
                                    .font(.custom("JetBrains Mono", size: 7))
                                    .foregroundColor(Theme.ink)
                            }
                            .padding(4)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                    }
                }
            }

            // Active zone indicator
            if let activeZone = state.activeZone {
                Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                    Text("ZONE: \(activeZone.location.displayName)")
                        .font(.custom("JetBrains Mono", size: 7))
                        .foregroundColor(Theme.soft)
                        .tracking(1)
                    Spacer()
                    if activeZone.svgContent != nil {
                        Button {
                            clearActiveZone()
                        } label: {
                            Text("x")
                                .font(.custom("JetBrains Mono", size: 10))
                                .foregroundColor(Theme.soft)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear { loadThumbnails() }
    }

    // MARK: - Actions

    private func applyAsset(_ asset: GraphicAsset) {
        guard let svg = loadedThumbnails[asset.id] ?? asset.loadSVGContent() else { return }

        // Apply to active zone, or default fullBack zone
        if let activeID = state.activeZoneID,
           let index = state.graphicZones.firstIndex(where: { $0.id == activeID }) {
            state.graphicZones[index].svgContent = svg
        } else if let index = state.graphicZones.firstIndex(where: { $0.location == .fullBack }) {
            state.graphicZones[index].svgContent = svg
            state.activeZoneID = state.graphicZones[index].id
        } else {
            // Create a fullBack zone with this asset
            var zone = GraphicZoneConfig(location: .fullBack)
            zone.svgContent = svg
            state.graphicZones.append(zone)
            state.activeZoneID = zone.id
        }

        // Also set on legacy single-zone for backward compat
        state.importedSVG = svg
    }

    private func isApplied(_ asset: GraphicAsset) -> Bool {
        guard let svg = loadedThumbnails[asset.id],
              let activeZone = state.activeZone else { return false }
        return activeZone.svgContent?.rawSVG == svg.rawSVG
    }

    private func clearActiveZone() {
        guard let activeID = state.activeZoneID,
              let index = state.graphicZones.firstIndex(where: { $0.id == activeID }) else { return }
        state.graphicZones[index].svgContent = nil
        state.importedSVG = nil
    }

    private func loadThumbnails() {
        for asset in GraphicAsset.bundled {
            if loadedThumbnails[asset.id] == nil {
                loadedThumbnails[asset.id] = asset.loadSVGContent()
            }
        }
    }
}
