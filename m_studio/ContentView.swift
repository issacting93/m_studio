import SwiftUI

struct ContentView: View {
    @State private var state = DesignState()
    @State private var storage = DesignStorage()

    var body: some View {
        HStack(spacing: 0) {
            // Left: Tool Panel
            ToolPanelView(state: state, storage: storage)

            // Center: Canvas
            VStack(spacing: 0) {
                stageBar
                canvasBar
                canvasContent
                footer
            }
            .background(Theme.paper)

            // Right: Inspector
            InspectorView(state: state)
        }
        #if os(macOS)
        .frame(minWidth: 1200, minHeight: 750)
        #endif
    }

    // MARK: - Stage Bar

    private var stageBar: some View {
        HStack(spacing: 0) {
            ForEach(DesignStage.allCases) { stage in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { state.stage = stage }
                } label: {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(state.stage == stage ? Theme.accent : Theme.border)
                                .frame(width: 20, height: 20)
                            Text("\(stage.number)")
                                .font(.custom(Theme.fontMono, size: 9))
                                .fontWeight(.bold)
                                .foregroundColor(state.stage == stage ? .white : Theme.soft)
                        }
                        Text(stage.label)
                            .font(.custom(Theme.fontUI, size: 10))
                            .fontWeight(state.stage == stage ? .semibold : .regular)
                            .foregroundColor(state.stage == stage ? Theme.ink : Theme.soft)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(state.stage == stage ? Theme.accent.opacity(0.08) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Connector line between stages
                if stage != .export {
                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 1)
                        .frame(maxWidth: 20)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Theme.surface)
        .overlay(alignment: .bottom) { Divider().opacity(0.2) }
    }

    // MARK: - Canvas Bar

    private var canvasBar: some View {
        HStack {
            Text(state.activeTab.label)
                .font(.custom(Theme.fontUI, size: 12))
                .fontWeight(.semibold)
                .foregroundColor(Theme.ink)
            Spacer()
            Text("\(state.silhouette.code).A  ·  \(state.colorway.displayName)  ·  \(state.fabric.displayName)")
                .font(.custom(Theme.fontMono, size: 9))
                .foregroundColor(Theme.soft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider().opacity(0.3) }
    }

    // MARK: - Canvas Content

    @ViewBuilder
    private var canvasContent: some View {
        switch state.activeTab {
        case .garment:
            GarmentCanvasView(state: state)
        case .threeD:
            ThreeDView(state: state)
        case .pattern:
            FlatPatternView(state: state)
        case .colorway:
            ColorwaySheetView(state: state)
        case .sizes:
            SizeGradeView(state: state)
        case .sourcing:
            SourcingView(state: state)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("M-Studio  ·  Zac Ting / NYC  ·  2026")
                .font(.custom(Theme.fontUI, size: 9))
                .foregroundColor(Theme.soft)
            Spacer()
            Text("\(state.silhouette.code).A  ·  \(state.size.rawValue)  ·  \(state.colorway.displayName)")
                .font(.custom(Theme.fontMono, size: 9))
                .foregroundColor(Theme.soft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .overlay(alignment: .top) { Divider().opacity(0.3) }
    }
}

#Preview {
    ContentView()
}
