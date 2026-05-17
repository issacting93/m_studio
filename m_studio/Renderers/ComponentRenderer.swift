import SwiftUI

/// Draws placed components onto the garment canvas
struct ComponentRenderer {

    static func draw(_ component: PlacedComponent, context: inout GraphicsContext, bounds: CGRect, accentColor: Color, pocketColor: Color, isSelected: Bool) {
        let rect = componentRect(component, in: bounds)

        // Selection highlight
        if isSelected {
            let selDash = StrokeStyle(lineWidth: 1.2, dash: [4, 3])
            let selRect = rect.insetBy(dx: -3, dy: -3)
            context.stroke(Path(selRect), with: .color(Theme.accent), style: selDash)
            // Resize handle
            let handleRect = CGRect(x: rect.maxX - 4, y: rect.maxY - 4, width: 8, height: 8)
            context.fill(Path(handleRect), with: .color(Theme.accent))
        }

        switch component.type {
        // MARK: - Pockets
        case .pocketPatch:
            context.fill(Path(rect), with: .color(pocketColor))
            context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
            // Topstitch
            let inset = rect.insetBy(dx: 2, dy: 2)
            let dashStyle = StrokeStyle(lineWidth: 0.5, dash: [2, 1.5])
            context.stroke(Path(inset), with: .color(Theme.ink), style: dashStyle)

        case .pocketWelt:
            var line = Path()
            line.move(to: CGPoint(x: rect.minX, y: rect.midY))
            line.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(line, with: .color(Theme.ink), lineWidth: 1.4)

        case .pocketZipWelt:
            var line = Path()
            line.move(to: CGPoint(x: rect.minX, y: rect.midY))
            line.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(line, with: .color(Theme.ink), lineWidth: 1.4)
            // Zip pull
            let pullRect = CGRect(x: rect.minX + 2, y: rect.midY - 3, width: 4, height: 6)
            context.fill(Path(pullRect), with: .color(accentColor))

        case .pocketCargo:
            context.fill(Path(rect), with: .color(pocketColor))
            context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
            // Flap
            let flapRect = CGRect(x: rect.minX, y: rect.minY - rect.height * 0.2, width: rect.width, height: rect.height * 0.2)
            context.fill(Path(flapRect), with: .color(pocketColor))
            context.stroke(Path(flapRect), with: .color(Theme.ink), lineWidth: 1)
            // Snap on flap
            context.fill(Circle().path(in: CGRect(x: rect.midX - 2, y: flapRect.midY - 2, width: 4, height: 4)), with: .color(accentColor))

        case .pocketMolle:
            context.fill(Path(rect), with: .color(pocketColor))
            context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
            // MOLLE webbing rows
            let rowCount = max(2, Int(rect.height / 6))
            for i in 0..<rowCount {
                let wy = rect.minY + 3 + CGFloat(i) * (rect.height - 6) / CGFloat(rowCount)
                var web = Path()
                web.move(to: CGPoint(x: rect.minX + 3, y: wy))
                web.addLine(to: CGPoint(x: rect.maxX - 3, y: wy))
                context.stroke(web, with: .color(Theme.ink), lineWidth: 0.7)
            }

        case .pocketSleeveZip:
            context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
            // Diagonal zip
            let dashStyle = StrokeStyle(lineWidth: 1, dash: [3, 2])
            var zip = Path()
            zip.move(to: CGPoint(x: rect.midX, y: rect.minY))
            zip.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            context.stroke(zip, with: .color(accentColor), style: dashStyle)

        // MARK: - Closures
        case .zipperFull, .zipperHalf:
            let dashStyle = StrokeStyle(lineWidth: 1.4, dash: [3, 2])
            var zip = Path()
            zip.move(to: CGPoint(x: rect.midX, y: rect.minY))
            zip.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            context.stroke(zip, with: .color(accentColor), style: dashStyle)
            // Pull tab
            let pullRect = CGRect(x: rect.midX - 3, y: rect.maxY - 8, width: 6, height: 6)
            context.fill(Path(pullRect), with: .color(accentColor))
            context.stroke(Path(pullRect), with: .color(Theme.ink), lineWidth: 0.6)

        case .snapRow:
            let count = max(3, Int(rect.height / 12))
            for i in 0..<count {
                let sy = rect.minY + CGFloat(i) * rect.height / CGFloat(count) + rect.height / CGFloat(count * 2)
                context.stroke(Circle().path(in: CGRect(x: rect.midX - 3, y: sy - 3, width: 6, height: 6)), with: .color(accentColor), lineWidth: 1.2)
                context.fill(Circle().path(in: CGRect(x: rect.midX - 1, y: sy - 1, width: 2, height: 2)), with: .color(accentColor))
            }

        case .buckleRelease:
            // Strap
            var strap = Path()
            strap.move(to: CGPoint(x: rect.minX, y: rect.midY))
            strap.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(strap, with: .color(Theme.ink), lineWidth: 2)
            // Buckle body
            let bw = min(rect.width * 0.3, 12.0)
            let buckle = CGRect(x: rect.midX - bw / 2, y: rect.midY - 4, width: bw, height: 8)
            context.fill(Path(buckle), with: .color(accentColor))
            context.stroke(Path(buckle), with: .color(Theme.ink), lineWidth: 0.8)

        // MARK: - Hardware
        case .dRing:
            var dPath = Path()
            let cx = rect.midX, cy = rect.midY, r = min(rect.width, rect.height) * 0.4
            dPath.move(to: CGPoint(x: cx - r, y: cy - r))
            dPath.addLine(to: CGPoint(x: cx - r, y: cy + r))
            dPath.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
            dPath.closeSubpath()
            context.stroke(dPath, with: .color(Theme.ink), lineWidth: 1.5)

        case .carabiner:
            let cx = rect.midX, cy = rect.midY
            let w = rect.width * 0.35, h = rect.height * 0.4
            var carPath = Path()
            carPath.addRoundedRect(in: CGRect(x: cx - w, y: cy - h, width: w * 2, height: h * 2), cornerSize: CGSize(width: 3, height: 3))
            context.stroke(carPath, with: .color(Theme.ink), lineWidth: 1.5)
            // Gate
            var gate = Path()
            gate.move(to: CGPoint(x: cx + w, y: cy - h * 0.6))
            gate.addLine(to: CGPoint(x: cx + w, y: cy + h * 0.6))
            context.stroke(gate, with: .color(accentColor), lineWidth: 1)

        case .pullerTab:
            let tabRect = CGRect(x: rect.midX - 2, y: rect.minY, width: 4, height: rect.height)
            context.fill(Path(tabRect), with: .color(accentColor))
            context.stroke(Path(tabRect), with: .color(Theme.ink), lineWidth: 0.6)

        case .eyelet:
            let r = min(rect.width, rect.height) * 0.4
            let outer = CGRect(x: rect.midX - r, y: rect.midY - r, width: r * 2, height: r * 2)
            context.stroke(Circle().path(in: outer), with: .color(Theme.ink), lineWidth: 1.5)
            let inner = CGRect(x: rect.midX - r * 0.4, y: rect.midY - r * 0.4, width: r * 0.8, height: r * 0.8)
            context.fill(Circle().path(in: inner), with: .color(Theme.ink))

        // MARK: - Patches
        case .patchRect:
            context.fill(Path(rect), with: .color(accentColor.opacity(0.8)))
            context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
            let dashStyle = StrokeStyle(lineWidth: 0.5, dash: [1.5, 1])
            context.stroke(Path(rect.insetBy(dx: 2, dy: 2)), with: .color(Theme.ink), style: dashStyle)

        case .patchCircle:
            let r = min(rect.width, rect.height) / 2
            let circle = CGRect(x: rect.midX - r, y: rect.midY - r, width: r * 2, height: r * 2)
            context.fill(Circle().path(in: circle), with: .color(accentColor.opacity(0.8)))
            context.stroke(Circle().path(in: circle), with: .color(Theme.ink), lineWidth: 1)

        case .labelWoven:
            context.fill(Path(rect), with: .color(Theme.ink))
            context.draw(
                Text("M-STD")
                    .font(.custom("JetBrains Mono", size: max(rect.height * 0.5, 5)))
                    .foregroundColor(Theme.paper),
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center
            )

        // MARK: - Stitching
        case .stitchTopstitch:
            let dashStyle = StrokeStyle(lineWidth: 0.8, dash: [3, 2])
            var line = Path()
            line.move(to: CGPoint(x: rect.minX, y: rect.midY))
            line.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(line, with: .color(Theme.ink), style: dashStyle)

        case .stitchBarTack:
            for i in 0..<4 {
                let bx = rect.minX + CGFloat(i) * rect.width / 4 + rect.width / 8
                var bar = Path()
                bar.move(to: CGPoint(x: bx, y: rect.minY))
                bar.addLine(to: CGPoint(x: bx, y: rect.maxY))
                context.stroke(bar, with: .color(Theme.ink), lineWidth: 1.2)
            }

        case .stitchDartLine:
            let dashStyle = StrokeStyle(lineWidth: 0.6, dash: [4, 2])
            var line = Path()
            line.move(to: CGPoint(x: rect.midX, y: rect.minY))
            line.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            context.stroke(line, with: .color(Theme.ink), style: dashStyle)

        // MARK: - Straps
        case .webbingStrap:
            var strap = Path()
            strap.addRect(CGRect(x: rect.minX, y: rect.midY - 2, width: rect.width, height: 4))
            context.fill(strap, with: .color(Theme.ink))

        case .drawcord:
            var cord = Path()
            cord.move(to: CGPoint(x: rect.minX, y: rect.midY))
            cord.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(cord, with: .color(Theme.ink), lineWidth: 1)
            // Cord stops
            context.fill(Circle().path(in: CGRect(x: rect.minX + rect.width * 0.3 - 2, y: rect.midY - 2, width: 4, height: 4)), with: .color(accentColor))
            context.fill(Circle().path(in: CGRect(x: rect.minX + rect.width * 0.7 - 2, y: rect.midY - 2, width: 4, height: 4)), with: .color(accentColor))

        case .elasticCord:
            // Wavy line
            var wave = Path()
            let steps = 12
            for i in 0...steps {
                let px = rect.minX + CGFloat(i) * rect.width / CGFloat(steps)
                let py = rect.midY + sin(CGFloat(i) * .pi * 2 / 4) * 2
                if i == 0 { wave.move(to: CGPoint(x: px, y: py)) }
                else { wave.addLine(to: CGPoint(x: px, y: py)) }
            }
            context.stroke(wave, with: .color(Theme.ink), lineWidth: 1)

        case .chainLink:
            let linkH = min(rect.height / 4, 8.0)
            let count = max(2, Int(rect.height / linkH))
            for i in 0..<count {
                let ly = rect.minY + CGFloat(i) * rect.height / CGFloat(count) + linkH / 2
                let linkRect = CGRect(x: rect.midX - 3, y: ly - linkH / 2, width: 6, height: linkH)
                context.stroke(RoundedRectangle(cornerRadius: 2).path(in: linkRect), with: .color(Theme.ink), lineWidth: 1.2)
            }
        }
    }

    /// Compute the screen-space rect for a component given its normalized coords and panel bounds
    static func componentRect(_ comp: PlacedComponent, in bounds: CGRect) -> CGRect {
        let w = comp.w * bounds.width
        let h = comp.h * bounds.height
        let x = bounds.minX + comp.x * bounds.width - w / 2
        let y = bounds.minY + comp.y * bounds.height - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
