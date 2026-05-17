import SwiftUI

struct FlatPatternView: View {
    let state: DesignState

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.paper))

            let totalWcm = state.bodyWidth + state.sleeveLength * 2 + 24
            let totalHcm = state.bodyLength + state.sleeveDepth + 60
            let s = min((size.width - 100) / totalWcm, (size.height - 100) / totalHcm)
            let cx = size.width / 2
            let topY: CGFloat = 60

            let halfB = (state.bodyWidth / 2) * s
            let bL = state.bodyLength * s
            let slv = state.sleeveLength * s
            let slvD = state.sleeveDepth * s
            let isNoragi = state.silhouette == .noragi

            // Header
            context.draw(
                Text("FLAT PATTERN · CUT LAYOUT · 1:\(Int(round(1 / s)))")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: 30, y: 28),
                anchor: .leading
            )
            context.draw(
                Text("\(state.silhouette.displayName) · \(state.size.rawValue)")
                    .font(.custom("Archivo", size: 12))
                    .fontWeight(.black)
                    .foregroundColor(Theme.ink),
                at: CGPoint(x: size.width - 30, y: 28),
                anchor: .trailing
            )

            // Back piece
            let backX = cx - halfB
            let backRect = CGRect(x: backX, y: topY, width: halfB * 2, height: bL)
            context.fill(Path(backRect), with: .color(.white.opacity(0.6)))
            context.stroke(Path(backRect), with: .color(Theme.ink), lineWidth: 1.4)

            // Center fold line (dashed)
            let foldDash = StrokeStyle(lineWidth: 0.7, dash: [5, 3])
            var foldLine = Path()
            foldLine.move(to: CGPoint(x: cx, y: topY))
            foldLine.addLine(to: CGPoint(x: cx, y: topY + bL))
            context.stroke(foldLine, with: .color(Theme.ink), style: foldDash)

            // Labels
            let pieceLabel = isNoragi ? "BACK + FRONTS" : "BACK"
            let cutLabel = isNoragi ? "CUT 1 ON FOLD" : "CUT 1"
            context.draw(
                Text(pieceLabel)
                    .font(.custom("Archivo", size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink),
                at: CGPoint(x: cx, y: topY + bL / 2 - 6),
                anchor: .center
            )
            context.draw(
                Text(cutLabel)
                    .font(.custom("JetBrains Mono", size: 8))
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: cx, y: topY + bL / 2 + 8),
                anchor: .center
            )

            // Grain line
            let grainY1 = topY + bL * 0.15
            let grainY2 = topY + bL * 0.85
            var grainLine = Path()
            grainLine.move(to: CGPoint(x: backX + 16, y: grainY1))
            grainLine.addLine(to: CGPoint(x: backX + 16, y: grainY2))
            context.stroke(grainLine, with: .color(Theme.soft), lineWidth: 0.6)

            // Grain arrows
            var topArrow = Path()
            topArrow.move(to: CGPoint(x: backX + 13, y: grainY1 + 5))
            topArrow.addLine(to: CGPoint(x: backX + 19, y: grainY1 + 5))
            topArrow.addLine(to: CGPoint(x: backX + 16, y: grainY1))
            topArrow.closeSubpath()
            context.fill(topArrow, with: .color(Theme.soft))

            var botArrow = Path()
            botArrow.move(to: CGPoint(x: backX + 13, y: grainY2 - 5))
            botArrow.addLine(to: CGPoint(x: backX + 19, y: grainY2 - 5))
            botArrow.addLine(to: CGPoint(x: backX + 16, y: grainY2))
            botArrow.closeSubpath()
            context.fill(botArrow, with: .color(Theme.soft))

            context.draw(
                Text("GRAIN")
                    .font(.custom("JetBrains Mono", size: 7))
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: backX + 24, y: (grainY1 + grainY2) / 2),
                anchor: .leading
            )

            // Left sleeve
            let sleeveTopY = topY + 12
            let leftSlvX = backX - slv - 10
            let leftSlvRect = CGRect(x: leftSlvX, y: sleeveTopY, width: slv, height: slvD)
            context.fill(Path(leftSlvRect), with: .color(.white.opacity(0.6)))
            context.stroke(Path(leftSlvRect), with: .color(Theme.ink), lineWidth: 1.4)

            context.draw(
                Text("SLEEVE L")
                    .font(.custom("Archivo", size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink),
                at: CGPoint(x: leftSlvX + slv / 2, y: sleeveTopY + slvD / 2 - 4),
                anchor: .center
            )
            context.draw(
                Text("CUT 1 · \(state.sleeveType.label.uppercased())")
                    .font(.custom("JetBrains Mono", size: 7))
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: leftSlvX + slv / 2, y: sleeveTopY + slvD / 2 + 8),
                anchor: .center
            )

            // Right sleeve
            let rightSlvX = backX + halfB * 2 + 10
            let rightSlvRect = CGRect(x: rightSlvX, y: sleeveTopY, width: slv, height: slvD)
            context.fill(Path(rightSlvRect), with: .color(.white.opacity(0.6)))
            context.stroke(Path(rightSlvRect), with: .color(Theme.ink), lineWidth: 1.4)

            context.draw(
                Text("SLEEVE R")
                    .font(.custom("Archivo", size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink),
                at: CGPoint(x: rightSlvX + slv / 2, y: sleeveTopY + slvD / 2 - 4),
                anchor: .center
            )
            context.draw(
                Text("MIRROR L")
                    .font(.custom("JetBrains Mono", size: 7))
                    .foregroundColor(Theme.soft),
                at: CGPoint(x: rightSlvX + slv / 2, y: sleeveTopY + slvD / 2 + 8),
                anchor: .center
            )

            // Graphic zone overlay
            if state.graphic != .off {
                let gzW = halfB * 1.4
                let gzH = bL * 0.32
                let gzX = cx - gzW / 2
                let gzY = topY + bL * 0.18
                let gzRect = CGRect(x: gzX, y: gzY, width: gzW, height: gzH)
                context.fill(Path(gzRect), with: .color(Theme.highlight.opacity(0.32)))
                let gzDash = StrokeStyle(lineWidth: 0.6, dash: [3, 2])
                context.stroke(Path(gzRect), with: .color(Theme.ink), style: gzDash)
                context.draw(
                    Text("GRAPHIC ZONE")
                        .font(.custom("JetBrains Mono", size: 8))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accent),
                    at: CGPoint(x: gzX + gzW / 2, y: gzY + 12),
                    anchor: .center
                )
            }

            // Dimension callouts
            // Body length (right side)
            let dimX = backX + halfB * 2 + 22
            var dimLine = Path()
            dimLine.move(to: CGPoint(x: dimX, y: topY))
            dimLine.addLine(to: CGPoint(x: dimX, y: topY + bL))
            context.stroke(dimLine, with: .color(Theme.accent), lineWidth: 0.7)

            var dimTopTick = Path()
            dimTopTick.move(to: CGPoint(x: dimX - 3, y: topY))
            dimTopTick.addLine(to: CGPoint(x: dimX + 3, y: topY))
            context.stroke(dimTopTick, with: .color(Theme.accent), lineWidth: 0.7)

            var dimBotTick = Path()
            dimBotTick.move(to: CGPoint(x: dimX - 3, y: topY + bL))
            dimBotTick.addLine(to: CGPoint(x: dimX + 3, y: topY + bL))
            context.stroke(dimBotTick, with: .color(Theme.accent), lineWidth: 0.7)

            context.draw(
                Text("L · \(Int(state.bodyLength))cm")
                    .font(.custom("JetBrains Mono", size: 8))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent),
                at: CGPoint(x: dimX + 5, y: topY + bL / 2),
                anchor: .leading
            )

            // Body width (top)
            var widthLine = Path()
            widthLine.move(to: CGPoint(x: backX, y: topY - 20))
            widthLine.addLine(to: CGPoint(x: backX + halfB * 2, y: topY - 20))
            context.stroke(widthLine, with: .color(Theme.accent), lineWidth: 0.7)

            context.draw(
                Text("W · \(Int(state.bodyWidth))cm")
                    .font(.custom("JetBrains Mono", size: 8))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent),
                at: CGPoint(x: cx, y: topY - 26),
                anchor: .center
            )

            // Sleeve dimension
            var slvDimLine = Path()
            slvDimLine.move(to: CGPoint(x: leftSlvX, y: sleeveTopY + slvD + 10))
            slvDimLine.addLine(to: CGPoint(x: leftSlvX + slv, y: sleeveTopY + slvD + 10))
            context.stroke(slvDimLine, with: .color(Theme.accent), lineWidth: 0.7)

            context.draw(
                Text("SLV · \(Int(state.sleeveLength))cm")
                    .font(.custom("JetBrains Mono", size: 7))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent),
                at: CGPoint(x: leftSlvX + slv / 2, y: sleeveTopY + slvD + 20),
                anchor: .center
            )
        }
    }
}
