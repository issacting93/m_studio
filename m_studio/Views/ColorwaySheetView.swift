import SwiftUI

struct ColorwaySheetView: View {
    let state: DesignState

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.paper))

            // Header
            context.draw(
                Text("COLORWAY SHEET · 4 VARIANTS · FRONT")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: 30, y: 28),
                anchor: .leading
            )
            context.draw(
                Text(state.silhouette.displayName)
                    .font(.custom("Archivo", size: 12))
                    .fontWeight(.black)
                    .foregroundColor(Theme.ink),
                at: CGPoint(x: size.width - 30, y: 28),
                anchor: .trailing
            )

            var headerLine = Path()
            headerLine.move(to: CGPoint(x: 30, y: 42))
            headerLine.addLine(to: CGPoint(x: size.width - 30, y: 42))
            context.stroke(headerLine, with: .color(Theme.ink), lineWidth: 0.5)

            // 4 colorway panels in a 2x2 grid
            let showCWs: [Colorway] = [.stealth, .hazard, .tactical, .gunmetal]
            let cellW = (size.width - 60) / 2
            let cellH = (size.height - 80) / 2
            let positions: [(CGFloat, CGFloat)] = [
                (30 + cellW / 2, 60 + cellH / 2),
                (30 + cellW * 1.5, 60 + cellH / 2),
                (30 + cellW / 2, 60 + cellH * 1.5),
                (30 + cellW * 1.5, 60 + cellH * 1.5)
            ]

            let totalW = state.bodyWidth + state.sleeveLength * 2
            let s = min((cellW - 40) / totalW, (cellH - 60) / state.bodyLength)

            for (i, cw) in showCWs.enumerated() {
                let (px, py) = positions[i]
                let cellRect = CGRect(x: px - cellW / 2 + 4, y: py - cellH / 2 + 4, width: cellW - 8, height: cellH - 8)
                context.stroke(Path(cellRect), with: .color(Theme.ink), lineWidth: 1)

                // Label bar
                let labelRect = CGRect(x: cellRect.minX, y: cellRect.maxY - 20, width: cellRect.width, height: 20)
                context.fill(Path(labelRect), with: .color(Theme.ink))
                context.draw(
                    Text("CW-\(String(format: "%02d", i + 1)) · \(cw.displayName)")
                        .font(.custom("JetBrains Mono", size: 9))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.paper),
                    at: CGPoint(x: labelRect.midX, y: labelRect.midY),
                    anchor: .center
                )

                // Draw garment
                let renderer = GarmentRenderer(state: state, scale: s, colorway: cw)
                let garmentCenter = CGPoint(x: px, y: py - 15)
                _ = renderer.draw(context: &context, center: garmentCenter, isBack: false)

                // Color swatches
                let swatchSize: CGFloat = 10
                let swatchY = cellRect.minY + 6
                let swatchX = cellRect.minX + 6
                context.fill(Path(CGRect(x: swatchX, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(cw.primary))
                context.stroke(Path(CGRect(x: swatchX, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(Theme.ink), lineWidth: 0.5)
                context.fill(Path(CGRect(x: swatchX + 12, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(cw.secondary))
                context.stroke(Path(CGRect(x: swatchX + 12, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(Theme.ink), lineWidth: 0.5)
                context.fill(Path(CGRect(x: swatchX + 24, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(cw.accent))
                context.stroke(Path(CGRect(x: swatchX + 24, y: swatchY, width: swatchSize, height: swatchSize)), with: .color(Theme.ink), lineWidth: 0.5)
            }
        }
    }
}
