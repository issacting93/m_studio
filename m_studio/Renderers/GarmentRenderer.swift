import SwiftUI

// MARK: - Theme Constants

enum Theme {
    // Core palette
    static let ink = Color(hex: "#1a1a1a")
    static let paper = Color(hex: "#f5f3ef")
    static let surface = Color.white
    static let accent = Color(hex: "#d63d2e")
    static let accent2 = Color(hex: "#2864db")
    static let soft = Color(hex: "#999691")
    static let highlight = Color(hex: "#ffd60a")
    static let border = Color.black.opacity(0.06)

    // Typography
    static let fontUI = "Inter"
    static let fontMono = "JetBrains Mono"
    static let fontDisplay = "Archivo"

    // Radii
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 8
    static let radiusLarge: CGFloat = 12
}

// MARK: - Garment Renderer

struct GarmentRenderer {
    let state: DesignState
    let scale: CGFloat
    let colorway: Colorway

    // Color blocking helpers
    var bodyColor: Color { state.colorBlocking.color(for: .body, colorway: colorway) }
    var sleeveColor: Color { state.colorBlocking.color(for: .sleeves, colorway: colorway) }
    var hoodColor: Color { state.colorBlocking.color(for: .hood, colorway: colorway) }
    var collarColor: Color { state.colorBlocking.color(for: .collar, colorway: colorway) }
    var cuffColor: Color { state.colorBlocking.color(for: .cuffs, colorway: colorway) }
    var hemColor: Color { state.colorBlocking.color(for: .hem, colorway: colorway) }
    var pocketColor: Color { state.colorBlocking.color(for: .pockets, colorway: colorway) }

    // MARK: - Noragi

    func drawNoragi(context: inout GraphicsContext, center: CGPoint, isBack: Bool) -> CGRect {
        let halfB = (state.bodyWidth / 2) * scale
        let bL = state.bodyLength * scale
        let slvL = state.sleeveLength * scale
        let slvDp = state.sleeveDepth * scale
        let ovr = state.overlap * scale
        let topY = center.y - bL / 2

        let lOut = center.x - halfB - slvL
        let rOut = center.x + halfB + slvL
        let sleeveBot = topY + slvDp
        let bodyBot = topY + bL

        // Main body + sleeves (one piece)
        var bodyPath = Path()
        bodyPath.move(to: CGPoint(x: lOut, y: topY))
        bodyPath.addLine(to: CGPoint(x: rOut, y: topY))
        bodyPath.addLine(to: CGPoint(x: rOut, y: sleeveBot))
        bodyPath.addLine(to: CGPoint(x: center.x + halfB, y: sleeveBot))
        bodyPath.addLine(to: CGPoint(x: center.x + halfB, y: bodyBot))
        bodyPath.addLine(to: CGPoint(x: center.x - halfB, y: bodyBot))
        bodyPath.addLine(to: CGPoint(x: center.x - halfB, y: sleeveBot))
        bodyPath.addLine(to: CGPoint(x: lOut, y: sleeveBot))
        bodyPath.closeSubpath()

        context.fill(bodyPath, with: .color(bodyColor))
        context.stroke(bodyPath, with: .color(Theme.ink), lineWidth: 1.6)

        // Shoulder seam lines (dashed)
        let dashStyle = StrokeStyle(lineWidth: 0.6, dash: [2, 2])
        var leftSeam = Path()
        leftSeam.move(to: CGPoint(x: center.x - halfB, y: topY))
        leftSeam.addLine(to: CGPoint(x: center.x - halfB, y: sleeveBot))
        context.stroke(leftSeam, with: .color(Theme.ink), style: dashStyle)

        var rightSeam = Path()
        rightSeam.move(to: CGPoint(x: center.x + halfB, y: topY))
        rightSeam.addLine(to: CGPoint(x: center.x + halfB, y: sleeveBot))
        context.stroke(rightSeam, with: .color(Theme.ink), style: dashStyle)

        if !isBack {
            // Neckline
            let neckW = halfB * 0.4
            let neckDepth = bL * 0.13
            var neckPath = Path()
            neckPath.move(to: CGPoint(x: center.x - neckW - 4, y: topY + 10))
            neckPath.addLine(to: CGPoint(x: center.x, y: topY + neckDepth + 5))
            neckPath.addLine(to: CGPoint(x: center.x + neckW + 4, y: topY + 10))
            context.fill(neckPath, with: .color(collarColor))
            context.stroke(neckPath, with: .color(Theme.ink), lineWidth: 1.2)

            // Center front overlap line
            var cfLine = Path()
            cfLine.move(to: CGPoint(x: center.x, y: topY + neckDepth + 5))
            cfLine.addLine(to: CGPoint(x: center.x - ovr, y: bodyBot))
            context.stroke(cfLine, with: .color(Theme.ink), lineWidth: 1.2)

            // Tie closure
            if state.closure == .tie {
                let ty = topY + bL * 0.36
                var tieLine = Path()
                tieLine.move(to: CGPoint(x: center.x - ovr * 0.5, y: ty))
                tieLine.addLine(to: CGPoint(x: center.x + ovr * 0.5, y: ty))
                context.stroke(tieLine, with: .color(colorway.accent), lineWidth: 1.3)
                context.fill(Circle().path(in: CGRect(x: center.x - ovr * 0.5 - 2.5, y: ty - 2.5, width: 5, height: 5)), with: .color(colorway.accent))
                context.fill(Circle().path(in: CGRect(x: center.x + ovr * 0.5 - 2.5, y: ty - 2.5, width: 5, height: 5)), with: .color(colorway.accent))
            }

            // Patch pockets
            if state.pocket == .patch {
                let pkY = topY + bL * 0.6
                let pkW = halfB * 0.55
                let pkH = bL * 0.14
                let leftPk = CGRect(x: center.x - halfB * 0.88, y: pkY, width: pkW, height: pkH)
                let rightPk = CGRect(x: center.x + halfB * 0.33, y: pkY, width: pkW, height: pkH)
                context.stroke(Path(leftPk), with: .color(Theme.ink), lineWidth: 1)
                context.stroke(Path(rightPk), with: .color(Theme.ink), lineWidth: 1)
            }
        }

        // Return body bounds for graphic zone
        return CGRect(x: center.x - halfB, y: topY, width: halfB * 2, height: bL)
    }

    // MARK: - Bomber (also used by hoodie/parka)

    func drawBomber(context: inout GraphicsContext, center: CGPoint, isBack: Bool, hood: Bool = false, parka: Bool = false) -> CGRect {
        let halfB = (state.bodyWidth / 2) * scale
        let bL = state.bodyLength * scale
        let slvL = state.sleeveLength * scale
        let slvDp = state.sleeveDepth * scale
        let cuff = (state.sleeveOpen / 2) * scale
        let topY = center.y - bL / 2

        let ribHeight = parka ? 0 : bL * 0.08
        let collarH = bL * 0.06
        let taper = parka ? 0 : halfB * 0.08

        let bodyTop = topY + collarH
        let bodyEndY = topY + bL - ribHeight
        let shoulderTopY = topY + collarH
        let armholeY = shoulderTopY + (state.sleeveType == .raglan ? slvDp * 0.7 : slvDp * 0.5)

        // Body
        var bodyPath = Path()
        bodyPath.move(to: CGPoint(x: center.x - halfB, y: bodyTop))
        bodyPath.addLine(to: CGPoint(x: center.x + halfB, y: bodyTop))
        bodyPath.addLine(to: CGPoint(x: center.x + halfB - taper, y: bodyEndY))
        bodyPath.addLine(to: CGPoint(x: center.x - halfB + taper, y: bodyEndY))
        bodyPath.closeSubpath()
        context.fill(bodyPath, with: .color(bodyColor))
        context.stroke(bodyPath, with: .color(Theme.ink), lineWidth: 1.6)

        // Sleeves
        let slvAngle: CGFloat = state.sleeveType == .raglan ? 0.15 : (state.sleeveType == .setin ? 0.08 : 0.0)

        // Left sleeve
        let lShoulder = center.x - halfB
        let lCuffX = lShoulder - slvL
        let lCuffY = shoulderTopY + slvL * slvAngle + slvDp * 0.3

        var leftSleeve = Path()
        leftSleeve.move(to: CGPoint(x: lShoulder, y: shoulderTopY))
        leftSleeve.addLine(to: CGPoint(x: lShoulder, y: armholeY))
        leftSleeve.addLine(to: CGPoint(x: lCuffX, y: lCuffY + cuff * 1.2))
        leftSleeve.addLine(to: CGPoint(x: lCuffX, y: lCuffY))
        leftSleeve.closeSubpath()
        context.fill(leftSleeve, with: .color(sleeveColor))
        context.stroke(leftSleeve, with: .color(Theme.ink), lineWidth: 1.6)

        // Right sleeve
        let rShoulder = center.x + halfB
        let rCuffX = rShoulder + slvL
        let rCuffY = lCuffY

        var rightSleeve = Path()
        rightSleeve.move(to: CGPoint(x: rShoulder, y: shoulderTopY))
        rightSleeve.addLine(to: CGPoint(x: rShoulder, y: armholeY))
        rightSleeve.addLine(to: CGPoint(x: rCuffX, y: rCuffY + cuff * 1.2))
        rightSleeve.addLine(to: CGPoint(x: rCuffX, y: rCuffY))
        rightSleeve.closeSubpath()
        context.fill(rightSleeve, with: .color(sleeveColor))
        context.stroke(rightSleeve, with: .color(Theme.ink), lineWidth: 1.6)

        // Raglan seams
        if state.sleeveType == .raglan {
            let dashStyle = StrokeStyle(lineWidth: 0.7, dash: [2, 2])
            var lRaglan = Path()
            lRaglan.move(to: CGPoint(x: center.x - halfB * 0.3, y: bodyTop))
            lRaglan.addLine(to: CGPoint(x: center.x - halfB, y: armholeY))
            context.stroke(lRaglan, with: .color(Theme.ink), style: dashStyle)
            var rRaglan = Path()
            rRaglan.move(to: CGPoint(x: center.x + halfB * 0.3, y: bodyTop))
            rRaglan.addLine(to: CGPoint(x: center.x + halfB, y: armholeY))
            context.stroke(rRaglan, with: .color(Theme.ink), style: dashStyle)
        }

        // Rib hem
        if ribHeight > 0 {
            let ribRect = CGRect(x: center.x - halfB + taper, y: bodyEndY, width: halfB * 2 - taper * 2, height: ribHeight)
            context.fill(Path(ribRect), with: .color(hemColor))
            context.stroke(Path(ribRect), with: .color(Theme.ink), lineWidth: 1.4)
            // Rib lines
            for i in 1..<14 {
                let rx = center.x - halfB + taper + (halfB * 2 - taper * 2) * CGFloat(i) / 14
                var ribLine = Path()
                ribLine.move(to: CGPoint(x: rx, y: bodyEndY + 1))
                ribLine.addLine(to: CGPoint(x: rx, y: bodyEndY + ribHeight - 1))
                context.stroke(ribLine, with: .color(Theme.ink), lineWidth: 0.4)
            }
        }

        // Cuffs
        let cuffH: CGFloat = ribHeight > 0 ? ribHeight * 0.8 : 4
        let leftCuffRect = CGRect(x: lCuffX - 2, y: lCuffY, width: cuffH + 4, height: cuff * 1.2)
        context.fill(Path(leftCuffRect), with: .color(cuffColor))
        context.stroke(Path(leftCuffRect), with: .color(Theme.ink), lineWidth: 1.2)
        let rightCuffRect = CGRect(x: rCuffX - 2, y: rCuffY, width: cuffH + 4, height: cuff * 1.2)
        context.fill(Path(rightCuffRect), with: .color(cuffColor))
        context.stroke(Path(rightCuffRect), with: .color(Theme.ink), lineWidth: 1.2)

        // Hood or collar
        if hood {
            let hoodW = halfB * 0.7
            let hoodH = halfB * 0.7
            var hoodPath = Path()
            hoodPath.move(to: CGPoint(x: center.x - hoodW, y: topY + collarH))
            hoodPath.addQuadCurve(to: CGPoint(x: center.x, y: topY - hoodH * 0.6),
                                  control: CGPoint(x: center.x - hoodW * 0.9, y: topY - hoodH * 0.5))
            hoodPath.addQuadCurve(to: CGPoint(x: center.x + hoodW, y: topY + collarH),
                                  control: CGPoint(x: center.x + hoodW * 0.9, y: topY - hoodH * 0.5))
            hoodPath.closeSubpath()
            context.fill(hoodPath, with: .color(hoodColor))
            context.stroke(hoodPath, with: .color(Theme.ink), lineWidth: 1.6)

            if !isBack {
                var hoodCenter = Path()
                hoodCenter.move(to: CGPoint(x: center.x, y: topY - hoodH * 0.6))
                hoodCenter.addLine(to: CGPoint(x: center.x, y: topY + collarH))
                context.stroke(hoodCenter, with: .color(Theme.ink), lineWidth: 1)
                // Drawcord dots
                context.fill(Circle().path(in: CGRect(x: center.x - 4.5, y: topY - hoodH * 0.3 - 1.5, width: 3, height: 3)), with: .color(colorway.accent))
                context.fill(Circle().path(in: CGRect(x: center.x + 1.5, y: topY - hoodH * 0.3 - 1.5, width: 3, height: 3)), with: .color(colorway.accent))
            }
        } else {
            let collarRect = CGRect(x: center.x - halfB * 0.5, y: topY, width: halfB, height: collarH)
            context.fill(Path(collarRect), with: .color(collarColor))
            context.stroke(Path(collarRect), with: .color(Theme.ink), lineWidth: 1.4)
        }

        // Front details
        if !isBack {
            // Zip closure
            if state.closure == .zip {
                let dashStyle = StrokeStyle(lineWidth: 1.4, dash: [3, 2])
                var zipLine = Path()
                zipLine.move(to: CGPoint(x: center.x, y: topY + collarH))
                zipLine.addLine(to: CGPoint(x: center.x, y: bodyEndY + ribHeight))
                context.stroke(zipLine, with: .color(colorway.accent), style: dashStyle)
                // Zip pull
                let pullRect = CGRect(x: center.x - 3, y: bodyEndY + ribHeight - 12, width: 6, height: 6)
                context.fill(Path(pullRect), with: .color(colorway.accent))
                context.stroke(Path(pullRect), with: .color(Theme.ink), lineWidth: 0.6)
            } else if state.closure == .snap {
                for i in 1...4 {
                    let sy = topY + collarH + (bodyEndY - topY - collarH) * CGFloat(i) / 5
                    context.stroke(Circle().path(in: CGRect(x: center.x - 2.8, y: sy - 2.8, width: 5.6, height: 5.6)), with: .color(colorway.accent), lineWidth: 1.2)
                    context.fill(Circle().path(in: CGRect(x: center.x - 0.8, y: sy - 0.8, width: 1.6, height: 1.6)), with: .color(colorway.accent))
                }
            } else if state.closure == .buckle {
                // Webbing strap across waist
                let beltY = topY + bL * 0.48
                var strapLine = Path()
                strapLine.move(to: CGPoint(x: center.x - halfB * 0.8, y: beltY))
                strapLine.addLine(to: CGPoint(x: center.x + halfB * 0.4, y: beltY))
                context.stroke(strapLine, with: .color(Theme.ink), lineWidth: 2)
                // Buckle rectangle
                let buckleRect = CGRect(x: center.x + halfB * 0.1 - 4, y: beltY - 4, width: 10, height: 8)
                context.fill(Path(buckleRect), with: .color(colorway.accent))
                context.stroke(Path(buckleRect), with: .color(Theme.ink), lineWidth: 0.8)
                // Tail
                var tail = Path()
                tail.move(to: CGPoint(x: buckleRect.maxX, y: beltY))
                tail.addLine(to: CGPoint(x: buckleRect.maxX + halfB * 0.2, y: beltY + 6))
                context.stroke(tail, with: .color(Theme.ink), lineWidth: 1.5)
            }

            // Pockets
            if state.pocket == .welt {
                let pkY = topY + bL * 0.6
                var leftWelt = Path()
                leftWelt.move(to: CGPoint(x: center.x - halfB * 0.7, y: pkY))
                leftWelt.addLine(to: CGPoint(x: center.x - halfB * 0.18, y: pkY))
                context.stroke(leftWelt, with: .color(Theme.ink), lineWidth: 1.4)
                var rightWelt = Path()
                rightWelt.move(to: CGPoint(x: center.x + halfB * 0.18, y: pkY))
                rightWelt.addLine(to: CGPoint(x: center.x + halfB * 0.7, y: pkY))
                context.stroke(rightWelt, with: .color(Theme.ink), lineWidth: 1.4)
            } else if state.pocket == .patch {
                let pkY = topY + bL * 0.6
                let pkW = halfB * 0.5
                let pkH = bL * 0.14
                let leftPk = CGRect(x: center.x - halfB * 0.78, y: pkY, width: pkW, height: pkH)
                let rightPk = CGRect(x: center.x + halfB * 0.28, y: pkY, width: pkW, height: pkH)
                context.fill(Path(leftPk), with: .color(pocketColor))
                context.stroke(Path(leftPk), with: .color(Theme.ink), lineWidth: 1)
                context.fill(Path(rightPk), with: .color(pocketColor))
                context.stroke(Path(rightPk), with: .color(Theme.ink), lineWidth: 1)
            } else if state.pocket == .cargo {
                let ch = halfB * 0.4
                let cw_ = halfB * 0.45
                let positions: [(CGFloat, CGFloat)] = [
                    (-halfB * 0.78, topY + bL * 0.28),
                    (halfB * 0.33, topY + bL * 0.28),
                    (-halfB * 0.78, topY + bL * 0.6),
                    (halfB * 0.33, topY + bL * 0.6)
                ]
                for (dx, py) in positions {
                    let rect = CGRect(x: center.x + dx, y: py, width: cw_, height: ch)
                    context.fill(Path(rect), with: .color(pocketColor))
                    context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
                }
            } else if state.pocket == .zipperedWelt {
                let pkY = topY + bL * 0.6
                // Welt lines with zip pulls
                for side in [-1.0, 1.0] {
                    let x1 = center.x + side * halfB * 0.18
                    let x2 = center.x + side * halfB * 0.7
                    var welt = Path()
                    welt.move(to: CGPoint(x: x1, y: pkY))
                    welt.addLine(to: CGPoint(x: x2, y: pkY))
                    context.stroke(welt, with: .color(Theme.ink), lineWidth: 1.4)
                    // Small zip pull
                    let pullX = side > 0 ? x1 + 2 : x1 - 5
                    let pullRect = CGRect(x: pullX, y: pkY - 3, width: 3, height: 6)
                    context.fill(Path(pullRect), with: .color(colorway.accent))
                }
            } else if state.pocket == .molle {
                let pkY = topY + bL * 0.55
                let pkW = halfB * 0.5
                let pkH = bL * 0.18
                for side in [-1.0, 1.0] {
                    let pkX = center.x + side * halfB * 0.15 + (side > 0 ? 0 : -pkW)
                    let rect = CGRect(x: pkX, y: pkY, width: pkW, height: pkH)
                    context.fill(Path(rect), with: .color(pocketColor))
                    context.stroke(Path(rect), with: .color(Theme.ink), lineWidth: 1)
                    // MOLLE webbing loops
                    for row in 0..<3 {
                        let wy = pkY + 4 + CGFloat(row) * (pkH - 8) / 3
                        var webbing = Path()
                        webbing.move(to: CGPoint(x: pkX + 3, y: wy))
                        webbing.addLine(to: CGPoint(x: pkX + pkW - 3, y: wy))
                        context.stroke(webbing, with: .color(Theme.ink), lineWidth: 0.8)
                    }
                }
            }

            // Sleeve patch on front (non-back only)
            if state.graphic != .off {
                let sgX = lCuffX + slvL * 0.15
                let sgY = lCuffY + cuff * 0.2
                let patchRect = CGRect(x: sgX, y: sgY, width: slvL * 0.45, height: cuff * 0.6)
                context.fill(Path(patchRect), with: .color(colorway.accent))
                context.draw(
                    Text("M-\(state.silhouette.rawValue.prefix(3).uppercased())")
                        .font(.custom("Archivo", size: cuff * 0.3))
                        .fontWeight(.black)
                        .foregroundColor(colorway.primary),
                    at: CGPoint(x: sgX + slvL * 0.225, y: sgY + cuff * 0.3),
                    anchor: .center
                )
            }
        }

        return CGRect(x: center.x - halfB, y: bodyTop, width: halfB * 2, height: bodyEndY - bodyTop)
    }

    // MARK: - Dispatchers

    // MARK: - Pullover

    func drawPullover(context: inout GraphicsContext, center: CGPoint, isBack: Bool) -> CGRect {
        // Pullover hoodie — like bomber with hood, no zip, kangaroo pocket
        let bounds = drawBomber(context: &context, center: center, isBack: isBack, hood: true)

        if !isBack && state.pocket == .kangaroo {
            let halfB = (state.bodyWidth / 2) * scale
            let bL = state.bodyLength * scale
            let topY = center.y - bL / 2
            let pkW = halfB * 1.4
            let pkH = bL * 0.14
            let pkY = topY + bL * 0.58
            let pkRect = CGRect(x: center.x - pkW / 2, y: pkY, width: pkW, height: pkH)
            context.fill(Path(pkRect), with: .color(pocketColor))
            context.stroke(Path(pkRect), with: .color(Theme.ink), lineWidth: 1)
            // Opening slit at top center
            var slit = Path()
            slit.move(to: CGPoint(x: center.x - pkW * 0.15, y: pkY))
            slit.addLine(to: CGPoint(x: center.x + pkW * 0.15, y: pkY))
            context.stroke(slit, with: .color(Theme.ink), lineWidth: 1.4)
        }

        return bounds
    }

    // MARK: - T-shirt

    func drawTshirt(context: inout GraphicsContext, center: CGPoint, isBack: Bool) -> CGRect {
        let halfB = (state.bodyWidth / 2) * scale
        let bL = state.bodyLength * scale
        let slvL = state.sleeveLength * scale
        let slvDp = state.sleeveDepth * scale
        let topY = center.y - bL / 2

        // Body rectangle
        var bodyPath = Path()
        bodyPath.addRect(CGRect(x: center.x - halfB, y: topY, width: halfB * 2, height: bL))
        context.fill(bodyPath, with: .color(bodyColor))
        context.stroke(bodyPath, with: .color(Theme.ink), lineWidth: 1.6)

        // Short set-in sleeves (trapezoidal)
        let shoulderY = topY
        let armholeY = topY + slvDp * 0.5

        // Left sleeve
        var leftSlv = Path()
        leftSlv.move(to: CGPoint(x: center.x - halfB, y: shoulderY))
        leftSlv.addLine(to: CGPoint(x: center.x - halfB, y: armholeY))
        leftSlv.addLine(to: CGPoint(x: center.x - halfB - slvL, y: armholeY + slvL * 0.1))
        leftSlv.addLine(to: CGPoint(x: center.x - halfB - slvL, y: shoulderY + slvL * 0.08))
        leftSlv.closeSubpath()
        context.fill(leftSlv, with: .color(sleeveColor))
        context.stroke(leftSlv, with: .color(Theme.ink), lineWidth: 1.6)

        // Right sleeve
        var rightSlv = Path()
        rightSlv.move(to: CGPoint(x: center.x + halfB, y: shoulderY))
        rightSlv.addLine(to: CGPoint(x: center.x + halfB, y: armholeY))
        rightSlv.addLine(to: CGPoint(x: center.x + halfB + slvL, y: armholeY + slvL * 0.1))
        rightSlv.addLine(to: CGPoint(x: center.x + halfB + slvL, y: shoulderY + slvL * 0.08))
        rightSlv.closeSubpath()
        context.fill(rightSlv, with: .color(sleeveColor))
        context.stroke(rightSlv, with: .color(Theme.ink), lineWidth: 1.6)

        // Crew neckline
        if !isBack {
            let neckW = halfB * 0.35
            let neckD = bL * 0.08
            var neckPath = Path()
            neckPath.move(to: CGPoint(x: center.x - neckW, y: topY))
            neckPath.addQuadCurve(to: CGPoint(x: center.x + neckW, y: topY),
                                  control: CGPoint(x: center.x, y: topY + neckD))
            context.fill(neckPath, with: .color(collarColor))
            context.stroke(neckPath, with: .color(Theme.ink), lineWidth: 1.2)
        }

        return CGRect(x: center.x - halfB, y: topY, width: halfB * 2, height: bL)
    }

    func draw(context: inout GraphicsContext, center: CGPoint, isBack: Bool) -> CGRect {
        switch state.silhouette {
        case .noragi:
            return drawNoragi(context: &context, center: center, isBack: isBack)
        case .bomber:
            return drawBomber(context: &context, center: center, isBack: isBack)
        case .hoodie:
            return drawBomber(context: &context, center: center, isBack: isBack, hood: true)
        case .parka:
            return drawBomber(context: &context, center: center, isBack: isBack, hood: true, parka: true)
        case .pullover:
            return drawPullover(context: &context, center: center, isBack: isBack)
        case .tshirt:
            return drawTshirt(context: &context, center: center, isBack: isBack)
        }
    }

    // MARK: - Graphic Zone

    func drawGraphic(context: inout GraphicsContext, bounds: CGRect) {
        guard state.graphic != .off else { return }

        let gzX = bounds.minX + state.graphicZone.x * bounds.width - (state.graphicZone.w * bounds.width) / 2
        let gzY = bounds.minY + state.graphicZone.y * bounds.height
        let gzW = state.graphicZone.w * bounds.width
        let gzH = state.graphicZone.h * bounds.height

        let rect = CGRect(x: gzX, y: gzY, width: gzW, height: gzH)

        // Graphic border
        let dashStyle = StrokeStyle(lineWidth: 0.7, dash: [3, 3])
        context.stroke(Path(rect), with: .color(Theme.accent), style: dashStyle)

        // Render imported SVG if present (overrides built-in styles)
        if let svg = state.importedSVG {
            SVGRenderer.render(svg, context: &context, in: rect, tintColor: .white, skipBackground: true)
            return
        }

        // Draw graphic content based on style
        switch state.graphic {
        case .milspec:
            drawMilspec(context: &context, rect: rect)
        case .mecha:
            drawMecha(context: &context, rect: rect)
        case .type:
            drawTypo(context: &context, rect: rect)
        case .ai:
            drawAIPlaceholder(context: &context, rect: rect)
        case .off:
            break
        }
    }

    // MARK: - Multi-Zone Rendering

    func drawGraphicZones(context: inout GraphicsContext, frontBounds: CGRect, backBounds: CGRect, selectedZoneID: UUID?) {
        for zone in state.graphicZones where zone.isActive {
            let bounds = zone.location.isFront ? frontBounds : backBounds
            let frame = zone.frame
            let gzW = frame.w * bounds.width
            let gzH = frame.h * bounds.height
            let gzX = bounds.minX + frame.x * bounds.width - gzW / 2
            let gzY = bounds.minY + frame.y * bounds.height
            let rect = CGRect(x: gzX, y: gzY, width: gzW, height: gzH)

            // Zone border
            let isSelected = zone.id == selectedZoneID
            let dashStyle = StrokeStyle(lineWidth: isSelected ? 1.2 : 0.5, dash: [3, 3])
            let borderColor = isSelected ? Theme.accent : Theme.soft.opacity(0.4)
            context.stroke(Path(rect), with: .color(borderColor), style: dashStyle)

            // Zone label
            context.draw(
                Text(zone.location.displayName)
                    .font(.custom(Theme.fontMono, size: 6))
                    .foregroundColor(borderColor),
                at: CGPoint(x: rect.minX + 3, y: rect.minY - 4),
                anchor: .leading
            )

            // Render SVG if present
            if let svg = zone.svgContent {
                let tint: Color? = {
                    switch zone.tint {
                    case .white: return .white
                    case .accent: return colorway.accent
                    case .graphic: return colorway.graphic
                    case .original: return nil
                    }
                }()
                SVGRenderer.render(svg, context: &context, in: rect, tintColor: tint, skipBackground: true, opacity: zone.opacity)
                continue
            }

            // Render built-in style
            switch zone.style {
            case .milspec: drawMilspec(context: &context, rect: rect)
            case .mecha: drawMecha(context: &context, rect: rect)
            case .type: drawTypo(context: &context, rect: rect)
            case .ai: drawAIPlaceholder(context: &context, rect: rect)
            case .off: break
            }
        }
    }

    private func drawMilspec(context: inout GraphicsContext, rect: CGRect) {
        let cx = rect.midX
        let gColor = colorway.graphic

        // Border
        context.stroke(Path(rect), with: .color(gColor), lineWidth: 0.8)

        // Title
        context.draw(
            Text(state.silhouette.displayName)
                .font(.custom("Archivo", size: rect.height * 0.13))
                .fontWeight(.black)
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.18),
            anchor: .center
        )

        // Divider line
        var divider = Path()
        divider.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.32))
        divider.addLine(to: CGPoint(x: rect.minX + rect.width * 0.85, y: rect.minY + rect.height * 0.32))
        context.stroke(divider, with: .color(gColor), lineWidth: 0.6)

        // Subtitle
        context.draw(
            Text("// TYPE 1.0 · \(state.silhouette.rawValue.uppercased())-SERIES")
                .font(.custom("JetBrains Mono", size: rect.height * 0.06))
                .fontWeight(.bold)
                .foregroundColor(colorway.accent),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.43),
            anchor: .center
        )

        // Spec line
        context.draw(
            Text("SPEC /2026 · IDN-NYC")
                .font(.custom("JetBrains Mono", size: rect.height * 0.05))
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.56),
            anchor: .center
        )

        // Colorway + fabric
        context.draw(
            Text("\(colorway.displayName) · \(state.fabric.displayName.uppercased())")
                .font(.custom("JetBrains Mono", size: rect.height * 0.04))
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.70),
            anchor: .center
        )

        // Bottom line
        var bottomDiv = Path()
        bottomDiv.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.82))
        bottomDiv.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.82))
        context.stroke(bottomDiv, with: .color(gColor), lineWidth: 0.4)

        context.draw(
            Text("EST.2026 · ZT/STUDIO")
                .font(.custom("JetBrains Mono", size: rect.height * 0.04))
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.92),
            anchor: .center
        )
    }

    private func drawMecha(context: inout GraphicsContext, rect: CGRect) {
        let cx = rect.midX
        let gColor = colorway.graphic

        // Title
        context.draw(
            Text(state.silhouette.displayName)
                .font(.custom("Archivo", size: rect.height * 0.1))
                .fontWeight(.black)
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.14),
            anchor: .center
        )

        // Box diagram
        let boxRect = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.3, width: rect.width * 0.6, height: rect.height * 0.4)
        context.stroke(Path(boxRect), with: .color(gColor), lineWidth: 0.6)

        // Cross lines in box
        var hLine = Path()
        hLine.move(to: CGPoint(x: boxRect.minX, y: boxRect.midY))
        hLine.addLine(to: CGPoint(x: boxRect.maxX, y: boxRect.midY))
        context.stroke(hLine, with: .color(gColor), lineWidth: 0.6)

        var vLine = Path()
        vLine.move(to: CGPoint(x: boxRect.midX, y: boxRect.minY))
        vLine.addLine(to: CGPoint(x: boxRect.midX, y: boxRect.maxY))
        context.stroke(vLine, with: .color(gColor), lineWidth: 0.6)

        // Accent dots
        context.fill(Circle().path(in: CGRect(x: rect.minX + rect.width * 0.35 - 2, y: rect.minY + rect.height * 0.4 - 2, width: 4, height: 4)), with: .color(colorway.accent))
        context.fill(Circle().path(in: CGRect(x: rect.minX + rect.width * 0.65 - 2, y: rect.minY + rect.height * 0.6 - 2, width: 4, height: 4)), with: .color(colorway.accent))

        // Labels
        context.draw(
            Text("UNIT-A").font(.custom("JetBrains Mono", size: rect.height * 0.04)).foregroundColor(gColor),
            at: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.35), anchor: .center
        )
        context.draw(
            Text("UNIT-B").font(.custom("JetBrains Mono", size: rect.height * 0.04)).foregroundColor(gColor),
            at: CGPoint(x: rect.minX + rect.width * 0.63, y: rect.minY + rect.height * 0.55), anchor: .center
        )

        // Bottom text
        context.draw(
            Text("// CHASSIS \(Int.random(in: 100...999))")
                .font(.custom("JetBrains Mono", size: rect.height * 0.05))
                .fontWeight(.bold)
                .foregroundColor(colorway.accent),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.82), anchor: .center
        )

        context.draw(
            Text("\(state.silhouette.rawValue.uppercased())/\(colorway.displayName)/2026")
                .font(.custom("JetBrains Mono", size: rect.height * 0.035))
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.92), anchor: .center
        )
    }

    private func drawTypo(context: inout GraphicsContext, rect: CGRect) {
        let cx = rect.midX
        let gColor = colorway.graphic

        // Big type
        context.draw(
            Text(state.silhouette.rawValue.uppercased())
                .font(.custom("Archivo", size: rect.height * 0.3))
                .fontWeight(.black)
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.35),
            anchor: .center
        )

        // Subtitle
        context.draw(
            Text("M·STUDIO")
                .font(.custom("JetBrains Mono", size: rect.height * 0.08))
                .fontWeight(.bold)
                .foregroundColor(colorway.accent),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.58),
            anchor: .center
        )

        // Divider
        var div = Path()
        div.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY + rect.height * 0.72))
        div.addLine(to: CGPoint(x: rect.minX + rect.width * 0.9, y: rect.minY + rect.height * 0.72))
        context.stroke(div, with: .color(gColor), lineWidth: 0.6)

        // Bottom
        context.draw(
            Text("TYPE 1.0 // EST.2026 // \(colorway.displayName)")
                .font(.custom("JetBrains Mono", size: rect.height * 0.045))
                .foregroundColor(gColor),
            at: CGPoint(x: cx, y: rect.minY + rect.height * 0.83),
            anchor: .center
        )
    }

    private func drawAIPlaceholder(context: inout GraphicsContext, rect: CGRect) {
        let dashStyle = StrokeStyle(lineWidth: 1, dash: [4, 4])
        context.stroke(Path(rect), with: .color(colorway.graphic), style: dashStyle)
        context.draw(
            Text("// AI GRAPHIC · ENTER PROMPT")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(colorway.graphic),
            at: CGPoint(x: rect.midX, y: rect.midY),
            anchor: .center
        )
    }
}
