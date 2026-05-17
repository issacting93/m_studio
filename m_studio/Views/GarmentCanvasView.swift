import SwiftUI

struct GarmentCanvasView: View {
    @Bindable var state: DesignState

    @State private var zoom: CGFloat = 1.0
    @State private var baseZoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var isDragging = false
    @State private var dragStart: GraphicZone?
    @State private var resizeStart: GraphicZone?
    @State private var compDragStart: [UUID: (Double, Double)] = [:]
    @State private var compResizeStart: [UUID: (Double, Double)] = [:]
    @State private var zoneDragStart: [UUID: (Double, Double)] = [:]

    var body: some View {
        GeometryReader { geo in
            let layout = computeLayout(size: geo.size)

            ZStack {
                // Canvas rendering
                Canvas { context, size in
                    drawCanvas(context: &context, size: size, layout: layout)

                    let accentColor = state.colorway.accent
                    let pocketClr = state.colorBlocking.color(for: .pockets, colorway: state.colorway)

                    for comp in state.placedComponents {
                        let bounds = panelBounds(for: comp.panel, layout: layout)
                        let isSelected = state.selectedComponentID == comp.id
                        ComponentRenderer.draw(comp, context: &context, bounds: bounds, accentColor: accentColor, pocketColor: pocketClr, isSelected: isSelected)
                    }
                }
                .onTapGesture {
                    // Tap empty canvas to deselect
                    state.selectedComponentID = nil
                }

                // Graphic zone drag handles (high priority — beats canvas gestures)
                if state.graphic != .off, let gzRect = layout.graphicZoneRect {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: gzRect.width, height: gzRect.height)
                        .contentShape(Rectangle())
                        .position(x: gzRect.midX, y: gzRect.midY)
                        .highPriorityGesture(dragGesture(layout: layout))
                        #if os(macOS)
                        .onHover { hovering in
                            if hovering { NSCursor.openHand.push() } else { NSCursor.pop() }
                        }
                        #endif

                    // Resize handle — scales inversely with zoom
                    let handleSize = max(8, 10 / zoom)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: handleSize, height: handleSize)
                        .position(x: gzRect.maxX, y: gzRect.maxY)
                        .highPriorityGesture(resizeGesture(layout: layout))
                }

                // Multi-zone drag overlays
                ForEach(state.graphicZones.filter { $0.isActive }) { zone in
                    let bounds = zone.location.isFront ? layout.frontBounds : layout.backBounds
                    let f = zone.frame
                    let zw = f.w * bounds.width
                    let zh = f.h * bounds.height
                    let zx = bounds.minX + f.x * bounds.width
                    let zy = bounds.minY + f.y * bounds.height + zh / 2
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: zw, height: zh)
                        .contentShape(Rectangle())
                        .position(x: zx, y: zy)
                        .highPriorityGesture(zoneDragGesture(for: zone.id, isFront: zone.location.isFront, layout: layout))
                        .onTapGesture { state.activeZoneID = zone.id }
                }

                // Component overlays — always active, not just editMode
                ForEach(state.placedComponents) { comp in
                    let bounds = panelBounds(for: comp.panel, layout: layout)
                    let rect = ComponentRenderer.componentRect(comp, in: bounds)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: max(rect.width, 20), height: max(rect.height, 20))
                        .contentShape(Rectangle())
                        .position(x: rect.midX, y: rect.midY)
                        .highPriorityGesture(componentDragGesture(for: comp.id, panel: comp.panel, layout: layout))
                        .onTapGesture { state.selectedComponentID = comp.id }
                        #if os(macOS)
                        .onHover { hovering in
                            if hovering { NSCursor.openHand.push() } else { NSCursor.pop() }
                        }
                        #endif

                    if state.selectedComponentID == comp.id {
                        let handleSize = max(8, 10 / zoom)
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: handleSize, height: handleSize)
                            .position(x: rect.maxX, y: rect.maxY)
                            .highPriorityGesture(componentResizeGesture(for: comp.id, panel: comp.panel, layout: layout))
                    }
                }

                // Zoom HUD
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        // Zoom indicator
                        Text(String(format: "%.0f%%", zoom * 100))
                            .font(.custom(Theme.fontMono, size: 9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.ink.opacity(0.7))
                            .clipShape(Capsule())

                        // Fit button
                        Button { resetView() } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Theme.ink.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(12)
                }
            }
            .scaleEffect(zoom, anchor: .center)
            .offset(x: pan.width, y: pan.height)
            .gesture(zoomGesture)
            #if os(macOS)
            .onCanvasScroll { deltaX, deltaY, isZoom in
                guard !isDragging else { return }
                if isZoom {
                    zoom = max(0.3, min(5.0, zoom + deltaY * 0.03))
                } else {
                    pan = CGSize(
                        width: pan.width + deltaX * 2,
                        height: pan.height + deltaY * 2
                    )
                }
            }
            .onKeyPress(.escape) {
                state.selectedComponentID = nil
                return .handled
            }
            #endif
        }
        .clipped()
        .dropDestination(for: String.self) { items, location in
            guard let assetID = items.first,
                  let asset = GraphicAsset.bundled.first(where: { $0.id == assetID }),
                  let svg = asset.loadSVGContent() else { return false }

            // Apply to active zone or default fullBack
            if let activeID = state.activeZoneID,
               let index = state.graphicZones.firstIndex(where: { $0.id == activeID }) {
                state.graphicZones[index].svgContent = svg
            } else if let index = state.graphicZones.firstIndex(where: { $0.location == .fullBack }) {
                state.graphicZones[index].svgContent = svg
                state.activeZoneID = state.graphicZones[index].id
            }
            state.importedSVG = svg
            return true
        }
    }

    // MARK: - Zoom & Pan

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = max(0.3, min(5.0, baseZoom * value.magnification))
            }
            .onEnded { _ in
                baseZoom = zoom
            }
    }

    private func resetView() {
        withAnimation(.easeOut(duration: 0.25)) {
            zoom = 1.0
            baseZoom = 1.0
            pan = .zero
        }
    }
}

// MARK: - Scroll Wheel Handler (macOS)

#if os(macOS)
import AppKit

struct CanvasScrollModifier: ViewModifier {
    let onScroll: (_ deltaX: CGFloat, _ deltaY: CGFloat, _ isZoom: Bool) -> Void

    func body(content: Content) -> some View {
        content.overlay(CanvasScrollNSViewRepresentable(onScroll: onScroll))
    }

    struct CanvasScrollNSViewRepresentable: NSViewRepresentable {
        let onScroll: (_ deltaX: CGFloat, _ deltaY: CGFloat, _ isZoom: Bool) -> Void

        func makeNSView(context: Context) -> CanvasScrollNSView {
            let view = CanvasScrollNSView()
            view.onScroll = onScroll
            return view
        }

        func updateNSView(_ nsView: CanvasScrollNSView, context: Context) {
            nsView.onScroll = onScroll
        }

        class CanvasScrollNSView: NSView {
            var onScroll: ((_ deltaX: CGFloat, _ deltaY: CGFloat, _ isZoom: Bool) -> Void)?

            override func scrollWheel(with event: NSEvent) {
                // macOS injects .control for trackpad pinch-zoom events
                let isZoom = event.modifierFlags.contains(.control)
                onScroll?(event.scrollingDeltaX, event.scrollingDeltaY, isZoom)
            }
        }
    }
}

extension View {
    func onCanvasScroll(_ handler: @escaping (_ deltaX: CGFloat, _ deltaY: CGFloat, _ isZoom: Bool) -> Void) -> some View {
        modifier(CanvasScrollModifier(onScroll: handler))
    }
}
#endif

// MARK: - Canvas Drawing & Gestures

extension GarmentCanvasView {

    // MARK: - Layout Computation

    struct CanvasLayout {
        let backCenter: CGPoint
        let backBounds: CGRect
        let frontCenter: CGPoint
        let frontBounds: CGRect
        let scale: CGFloat
        let size: CGSize
        var graphicZoneRect: CGRect?
    }

    func computeLayout(size: CGSize) -> CanvasLayout {
        let totalW = state.bodyWidth + state.sleeveLength * 2
        let totalH = state.bodyLength + (state.silhouette == .parka || state.silhouette == .hoodie || state.silhouette == .pullover ? 30 : 10)
        let maxH = size.height * 0.7
        let maxW = size.width * 0.35
        let s = min(maxW / totalW, maxH / totalH)

        let frontCenter = CGPoint(x: size.width * 0.28, y: size.height * 0.5)
        let backCenter = CGPoint(x: size.width * 0.72, y: size.height * 0.5)

        let halfB = (state.bodyWidth / 2) * s
        let bL = state.bodyLength * s
        let topY = backCenter.y - bL / 2

        let backBounds: CGRect
        switch state.silhouette {
        case .noragi, .tshirt:
            backBounds = CGRect(x: backCenter.x - halfB, y: topY, width: halfB * 2, height: bL)
        default:
            let collarH = bL * 0.06
            let isParka = state.silhouette == .parka
            let ribHeight = isParka ? 0 : bL * 0.08
            let bodyTop = topY + collarH
            let bodyEndY = topY + bL - ribHeight
            backBounds = CGRect(x: backCenter.x - halfB, y: bodyTop, width: halfB * 2, height: bodyEndY - bodyTop)
        }

        let frontTopY = frontCenter.y - bL / 2
        let frontBounds: CGRect
        switch state.silhouette {
        case .noragi, .tshirt:
            frontBounds = CGRect(x: frontCenter.x - halfB, y: frontTopY, width: halfB * 2, height: bL)
        default:
            let collarH = bL * 0.06
            let isParka = state.silhouette == .parka
            let ribHeight = isParka ? 0 : bL * 0.08
            let bodyTop = frontTopY + collarH
            let bodyEndY = frontTopY + bL - ribHeight
            frontBounds = CGRect(x: frontCenter.x - halfB, y: bodyTop, width: halfB * 2, height: bodyEndY - bodyTop)
        }

        var gzRect: CGRect? = nil
        if state.graphic != .off {
            let gzW = state.graphicZone.w * backBounds.width
            let gzH = state.graphicZone.h * backBounds.height
            let gzX = backBounds.minX + state.graphicZone.x * backBounds.width - gzW / 2
            let gzY = backBounds.minY + state.graphicZone.y * backBounds.height
            gzRect = CGRect(x: gzX, y: gzY, width: gzW, height: gzH)
        }

        return CanvasLayout(backCenter: backCenter, backBounds: backBounds, frontCenter: frontCenter, frontBounds: frontBounds, scale: s, size: size, graphicZoneRect: gzRect)
    }

    // MARK: - Graphic Zone Gestures

    func dragGesture(layout: CanvasLayout) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                if dragStart == nil { dragStart = state.graphicZone }
                guard let start = dragStart else { return }
                let bounds = layout.backBounds
                let dx = value.translation.width / bounds.width
                let dy = value.translation.height / bounds.height
                state.graphicZone.x = min(max(start.x + dx, state.graphicZone.w / 2), 1 - state.graphicZone.w / 2)
                state.graphicZone.y = min(max(start.y + dy, 0), 1 - state.graphicZone.h)
            }
            .onEnded { _ in dragStart = nil; isDragging = false }
    }

    func resizeGesture(layout: CanvasLayout) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                if resizeStart == nil { resizeStart = state.graphicZone }
                guard let start = resizeStart else { return }
                let bounds = layout.backBounds
                let dw = (value.translation.width / bounds.width) * 2
                let dh = value.translation.height / bounds.height
                state.graphicZone.w = min(max(start.w + dw, 0.2), 1.0)
                state.graphicZone.h = min(max(start.h + dh, 0.1), 0.8)
            }
            .onEnded { _ in resizeStart = nil; isDragging = false }
    }

    // MARK: - Component Gestures

    func panelBounds(for panel: ComponentPanel, layout: CanvasLayout) -> CGRect {
        switch panel {
        case .frontBody: return layout.frontBounds
        case .backBody: return layout.backBounds
        case .leftSleeve, .rightSleeve: return layout.frontBounds
        }
    }

    // MARK: - Zone Gestures

    func zoneDragGesture(for id: UUID, isFront: Bool, layout: CanvasLayout) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                state.activeZoneID = id
                if zoneDragStart[id] == nil, let zone = state.graphicZones.first(where: { $0.id == id }) {
                    zoneDragStart[id] = (zone.frame.x, zone.frame.y)
                }
                guard let start = zoneDragStart[id],
                      let index = state.graphicZones.firstIndex(where: { $0.id == id }) else { return }
                let bounds = isFront ? layout.frontBounds : layout.backBounds
                let dx = value.translation.width / bounds.width
                let dy = value.translation.height / bounds.height
                state.graphicZones[index].frame.x = min(max(start.0 + dx, 0), 1)
                state.graphicZones[index].frame.y = min(max(start.1 + dy, 0), 1)
            }
            .onEnded { _ in zoneDragStart[id] = nil; isDragging = false }
    }

    func componentDragGesture(for id: UUID, panel: ComponentPanel, layout: CanvasLayout) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                state.selectedComponentID = id
                if compDragStart[id] == nil, let comp = state.placedComponents.first(where: { $0.id == id }) {
                    compDragStart[id] = (comp.x, comp.y)
                }
                guard let start = compDragStart[id],
                      let index = state.placedComponents.firstIndex(where: { $0.id == id }) else { return }
                let bounds = panelBounds(for: panel, layout: layout)
                let dx = value.translation.width / bounds.width
                let dy = value.translation.height / bounds.height
                state.placedComponents[index].x = min(max(start.0 + dx, 0), 1)
                state.placedComponents[index].y = min(max(start.1 + dy, 0), 1)
            }
            .onEnded { _ in compDragStart[id] = nil; isDragging = false }
    }

    func componentResizeGesture(for id: UUID, panel: ComponentPanel, layout: CanvasLayout) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                if compResizeStart[id] == nil, let comp = state.placedComponents.first(where: { $0.id == id }) {
                    compResizeStart[id] = (comp.w, comp.h)
                }
                guard let start = compResizeStart[id],
                      let index = state.placedComponents.firstIndex(where: { $0.id == id }) else { return }
                let bounds = panelBounds(for: panel, layout: layout)
                let dw = value.translation.width / bounds.width
                let dh = value.translation.height / bounds.height
                state.placedComponents[index].w = min(max(start.0 + dw, 0.02), 0.8)
                state.placedComponents[index].h = min(max(start.1 + dh, 0.02), 0.8)
            }
            .onEnded { _ in compResizeStart[id] = nil; isDragging = false }
    }

    // MARK: - Canvas Drawing

    func drawCanvas(context: inout GraphicsContext, size: CGSize, layout: CanvasLayout) {
        // Background
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.paper))

        // Header text
        context.draw(
            Text("Garment Elevation")
                .font(.custom(Theme.fontUI, size: 10))
                .fontWeight(.semibold)
                .foregroundColor(Theme.soft),
            at: CGPoint(x: 30, y: 28),
            anchor: .leading
        )

        context.draw(
            Text("\(state.silhouette.displayName)  ·  \(state.size.rawValue)")
                .font(.custom(Theme.fontDisplay, size: 14))
                .fontWeight(.black)
                .foregroundColor(Theme.ink),
            at: CGPoint(x: size.width - 30, y: 28),
            anchor: .trailing
        )

        // Header line
        var headerLine = Path()
        headerLine.move(to: CGPoint(x: 30, y: 42))
        headerLine.addLine(to: CGPoint(x: size.width - 30, y: 42))
        context.stroke(headerLine, with: .color(Theme.border), lineWidth: 1)

        // Sub-header
        context.draw(
            Text("\(state.silhouette.code).A  ·  \(state.colorway.displayName)  ·  \(state.fabric.displayName)")
                .font(.custom(Theme.fontMono, size: 8))
                .foregroundColor(Theme.soft),
            at: CGPoint(x: 30, y: 56),
            anchor: .leading
        )

        let renderer = GarmentRenderer(state: state, scale: layout.scale, colorway: state.colorway)

        // Front (left)
        let frontBounds = renderer.draw(context: &context, center: layout.frontCenter, isBack: false)

        // Back (right)
        let backBounds = renderer.draw(context: &context, center: layout.backCenter, isBack: true)

        // Graphic on back panel (legacy single zone)
        renderer.drawGraphic(context: &context, bounds: backBounds)

        // Multi-zone graphics (on both front and back)
        renderer.drawGraphicZones(context: &context, frontBounds: frontBounds, backBounds: backBounds, selectedZoneID: state.activeZoneID)

        // Center divider
        let dashStyle = StrokeStyle(lineWidth: 0.4, dash: [2, 4])
        var divider = Path()
        divider.move(to: CGPoint(x: size.width / 2, y: 80))
        divider.addLine(to: CGPoint(x: size.width / 2, y: size.height - 60))
        context.stroke(divider, with: .color(Theme.soft.opacity(0.3)), style: dashStyle)

        // Labels
        let labelY = size.height - 40

        let frontLabel = CGRect(x: size.width * 0.28 - 25, y: labelY, width: 50, height: 16)
        let frontPath = Path(roundedRect: frontLabel, cornerRadius: 4)
        context.fill(frontPath, with: .color(Theme.surface))
        context.stroke(frontPath, with: .color(Theme.soft.opacity(0.3)), lineWidth: 1)
        context.draw(
            Text("Front").font(.custom(Theme.fontUI, size: 9)).fontWeight(.medium).foregroundColor(Theme.ink),
            at: CGPoint(x: frontLabel.midX, y: frontLabel.midY), anchor: .center
        )

        let backLabel = CGRect(x: size.width * 0.72 - 25, y: labelY, width: 50, height: 16)
        let backPath = Path(roundedRect: backLabel, cornerRadius: 4)
        context.fill(backPath, with: .color(Theme.ink))
        context.draw(
            Text("Back").font(.custom(Theme.fontUI, size: 9)).fontWeight(.medium).foregroundColor(.white),
            at: CGPoint(x: backLabel.midX, y: backLabel.midY), anchor: .center
        )
    }

    func drawCornerStamp(context: inout GraphicsContext, x: CGFloat, y: CGFloat, line1: String, line2: String) {
        let rect = CGRect(x: x, y: y, width: 130, height: 42)
        context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(Theme.soft.opacity(0.3)), lineWidth: 1)

        context.draw(
            Text("DWG · \(state.silhouette.code).A")
                .font(.custom(Theme.fontMono, size: 7)).fontWeight(.medium).foregroundColor(Theme.ink),
            at: CGPoint(x: x + 6, y: y + 10), anchor: .leading
        )
        context.draw(
            Text(line1).font(.custom(Theme.fontMono, size: 6.5)).foregroundColor(Theme.soft),
            at: CGPoint(x: x + 6, y: y + 23), anchor: .leading
        )
        context.draw(
            Text(line2).font(.custom(Theme.fontMono, size: 6.5)).foregroundColor(Theme.soft),
            at: CGPoint(x: x + 6, y: y + 34), anchor: .leading
        )
    }
}
