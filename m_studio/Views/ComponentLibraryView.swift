import SwiftUI

struct ComponentLibraryView: View {
    @Bindable var state: DesignState
    @State private var selectedCategory: ComponentCategory = .pockets

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ComponentCategory.allCases) { cat in
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

            // Component grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(selectedCategory.types) { type in
                    Button {
                        let component = PlacedComponent(type: type, panel: .frontBody)
                        state.placedComponents.append(component)
                        state.selectedComponentID = component.id
                    } label: {
                        VStack(spacing: 2) {
                            // Mini preview
                            Canvas { context, size in
                                let previewBounds = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
                                let comp = PlacedComponent(type: type)
                                let mockBounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                                var adjusted = comp
                                adjusted.x = 0.5
                                adjusted.y = 0.5
                                adjusted.w = 0.7
                                adjusted.h = 0.7
                                ComponentRenderer.draw(adjusted, context: &context, bounds: mockBounds, accentColor: Theme.accent, pocketColor: Theme.soft.opacity(0.3), isSelected: false)
                            }
                            .frame(width: 36, height: 28)
                            .background(Theme.paper)
                            .overlay(Rectangle().stroke(Theme.ink.opacity(0.1), lineWidth: 0.5))

                            Text(type.displayName)
                                .font(.custom("JetBrains Mono", size: 6.5))
                                .foregroundColor(Theme.ink)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Placed components list
            if !state.placedComponents.isEmpty {
                Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)

                Text("PLACED (\(state.placedComponents.count))")
                    .font(.custom("JetBrains Mono", size: 7))
                    .foregroundColor(Theme.soft)
                    .tracking(1.5)

                VStack(spacing: 2) {
                    ForEach(state.placedComponents) { comp in
                        HStack(spacing: 6) {
                            Button {
                                state.selectedComponentID = comp.id
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(state.selectedComponentID == comp.id ? Theme.accent : Theme.soft)
                                        .frame(width: 5, height: 5)
                                    Text("\(comp.type.displayName) · \(comp.panel.displayName)")
                                        .font(.custom("JetBrains Mono", size: 7.5))
                                        .foregroundColor(Theme.ink)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                state.placedComponents.removeAll { $0.id == comp.id }
                                if state.selectedComponentID == comp.id {
                                    state.selectedComponentID = nil
                                }
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
        }
    }
}
