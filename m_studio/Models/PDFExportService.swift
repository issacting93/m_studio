import SwiftUI
import CoreGraphics
import CoreText

struct PDFExportService {
    let state: DesignState

    private let pageWidth: CGFloat = 595   // A4
    private let pageHeight: CGFloat = 842
    private let margin: CGFloat = 36
    private let totalPages = 6

    func generatePDF() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(state.silhouette.code)-techpack.pdf")

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let ctx = CGContext(fileURL as CFURL, mediaBox: &mediaBox, nil) else { return nil }

        // Page 1: Cover — Properties + Front/Back
        drawPage(ctx: ctx, pageNum: 1, title: "Properties") { c, r in drawCoverPage(c, r) }

        // Page 2: Detail Sketch — callout annotations
        drawPage(ctx: ctx, pageNum: 2, title: "Detail Sketch") { c, r in drawDetailPage(c, r) }

        // Page 3: Colorway Sheet
        drawPage(ctx: ctx, pageNum: 3, title: "Colorways") { c, r in drawColorwayPage(c, r) }

        // Page 4: Bill of Materials
        drawPage(ctx: ctx, pageNum: 4, title: "Bill of Materials") { c, r in drawBOMPage(c, r) }

        // Page 5: Size Chart (Graded)
        drawPage(ctx: ctx, pageNum: 5, title: "Size Chart") { c, r in drawSizeChartPage(c, r) }

        // Page 6: Construction Details
        drawPage(ctx: ctx, pageNum: 6, title: "Construction Details") { c, r in drawConstructionPage(c, r) }

        ctx.closePDF()
        return fileURL
    }

    // MARK: - Page Template

    private func drawPage(ctx: CGContext, pageNum: Int, title: String, content: (CGContext, CGRect) -> Void) {
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        ctx.beginPage(mediaBox: &mediaBox)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: pageHeight)
        ctx.scaleBy(x: 1, y: -1)

        // Header bar
        let headerH: CGFloat = 50
        ctx.setFillColor(CGColor(gray: 0.96, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: headerH))

        txt(ctx, "M-STUDIO", x: margin, y: 18, size: 14, bold: true)
        txt(ctx, "\(state.silhouette.code) — \(state.silhouette.displayName)", x: margin + 100, y: 20, size: 9, color: CGColor(gray: 0.4, alpha: 1))
        txt(ctx, title, x: pageWidth - margin, y: 18, size: 10, bold: true, align: .right)
        txt(ctx, ISO8601DateFormatter().string(from: Date()).prefix(10).description, x: pageWidth - margin, y: 32, size: 8, color: CGColor(gray: 0.5, alpha: 1), align: .right)

        // Divider
        ctx.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: headerH))
        ctx.addLine(to: CGPoint(x: pageWidth - margin, y: headerH))
        ctx.strokePath()

        // Content
        let contentRect = CGRect(x: margin, y: headerH + 12, width: pageWidth - margin * 2, height: pageHeight - headerH - margin - 30)
        content(ctx, contentRect)

        // Footer
        let footerY = pageHeight - 20
        txt(ctx, "M-Studio · Zac Ting / NYC · 2026", x: margin, y: footerY, size: 7, color: CGColor(gray: 0.5, alpha: 1))
        txt(ctx, "Page \(pageNum) of \(totalPages)", x: pageWidth - margin, y: footerY, size: 7, color: CGColor(gray: 0.5, alpha: 1), align: .right)

        ctx.restoreGState()
        ctx.endPage()
    }

    // MARK: - Page 1: Cover / Properties

    private func drawCoverPage(_ ctx: CGContext, _ r: CGRect) {
        let col1W = r.width * 0.5
        var y = r.minY

        // Properties table
        let props: [(String, String)] = [
            ("Style Number", state.silhouette.code),
            ("Style Description", state.silhouette.displayName),
            ("Season", "FW 2026"),
            ("Designer", "Zac Ting"),
            ("Colorway", state.colorway.displayName),
            ("Fabric", state.fabric.displayName),
            ("Fabric Spec", state.fabric.spec),
            ("Closure", state.closure.label),
            ("Pocket", state.pocket.label),
            ("Collar", state.collarType.label),
            ("Cuff", state.cuffType.label),
            ("Hem", state.hemType.label),
        ]

        txt(ctx, "PROPERTIES", x: r.minX, y: y, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        y += 16

        for (key, value) in props {
            // Alternating row background
            if props.firstIndex(where: { $0.0 == key })! % 2 == 0 {
                ctx.setFillColor(CGColor(gray: 0.97, alpha: 1))
                ctx.fill(CGRect(x: r.minX, y: y - 2, width: col1W - 10, height: 16))
            }
            txt(ctx, key, x: r.minX + 4, y: y, size: 8, color: CGColor(gray: 0.4, alpha: 1))
            txt(ctx, value, x: r.minX + 120, y: y, size: 8, bold: true)
            y += 16
        }

        // Color swatches
        y += 16
        txt(ctx, "COLORS", x: r.minX, y: y, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        y += 14
        let swatchSize: CGFloat = 28
        let cwColors: [(String, String)] = [
            ("Primary", state.colorway.primaryHex),
            ("Secondary", state.colorway.secondaryHex),
            ("Accent", state.colorway.accentHex),
            ("Graphic", state.colorway.graphicHex),
        ]
        var sx = r.minX
        for (label, hex) in cwColors {
            drawColorSwatch(ctx, hex: hex, x: sx, y: y, size: swatchSize)
            txt(ctx, label, x: sx, y: y + swatchSize + 6, size: 6, color: CGColor(gray: 0.4, alpha: 1))
            sx += swatchSize + 20
        }

        // Right column: Fabric swatch area
        let rightX = r.minX + col1W + 10
        txt(ctx, "FABRIC", x: rightX, y: r.minY, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        // Fabric swatch placeholder
        ctx.setStrokeColor(CGColor(gray: 0.8, alpha: 1))
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: rightX, y: r.minY + 16, width: 80, height: 80))
        txt(ctx, state.fabric.displayName, x: rightX + 4, y: r.minY + 52, size: 9, bold: true)
        txt(ctx, state.fabric.spec, x: rightX + 4, y: r.minY + 66, size: 7, color: CGColor(gray: 0.4, alpha: 1))
        txt(ctx, "$\(state.fabric.cost)/yd · \(state.fabric.source)", x: rightX + 4, y: r.minY + 78, size: 7, color: CGColor(gray: 0.4, alpha: 1))

        // Trims
        let trimsY = r.minY + 110
        txt(ctx, "TRIMS", x: rightX, y: trimsY, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        let trims = ["Zipper: YKK Aquaguard #5", "Buckle: ITW Nexus", "Webbing: Mil-spec 25mm", "Label: Woven (Dutch Label Shop)"]
        for (i, trim) in trims.enumerated() {
            txt(ctx, trim, x: rightX + 4, y: trimsY + 16 + CGFloat(i) * 14, size: 7)
        }
    }

    // MARK: - Page 2: Detail Sketch

    private func drawDetailPage(_ ctx: CGContext, _ r: CGRect) {
        txt(ctx, "FRONT VIEW", x: r.minX, y: r.minY, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        txt(ctx, "BACK VIEW", x: r.midX + 20, y: r.minY, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))

        // Callout annotations
        let callouts: [(String, CGFloat, CGFloat)] = [
            ("\(state.collarType.label) Collar", r.minX + 80, r.minY + 60),
            ("\(state.closure.label) Closure", r.minX + 20, r.minY + 200),
            ("\(state.pocket.label) Pockets", r.minX + 20, r.minY + 300),
            ("\(state.cuffType.label) Cuff", r.minX + 20, r.minY + 400),
            ("\(state.hemType.label) Hem", r.minX + 80, r.minY + 460),
            ("\(state.sleeveType.label) Sleeve", r.minX + 200, r.minY + 120),
            ("Graphic Zone", r.midX + 60, r.minY + 200),
            ("Body L: \(Int(state.bodyLength))cm", r.midX + 120, r.minY + 350),
            ("Shoulder: \(Int(state.shoulderWidth))cm", r.midX + 60, r.minY + 60),
        ]

        for (text, x, y) in callouts {
            // Callout line
            ctx.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + 40, y: y))
            ctx.strokePath()
            // Dot
            ctx.setFillColor(CGColor(red: 0.84, green: 0.24, blue: 0.18, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
            // Text
            txt(ctx, text, x: x + 44, y: y - 4, size: 7)
        }

        // Description box
        let descY = r.maxY - 120
        ctx.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        ctx.stroke(CGRect(x: r.minX, y: descY, width: r.width, height: 100))
        txt(ctx, "DESCRIPTION", x: r.minX + 6, y: descY + 6, size: 7, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        txt(ctx, "\(state.silhouette.displayName) in \(state.colorway.displayName) colorway.", x: r.minX + 6, y: descY + 22, size: 8)
        txt(ctx, "\(state.fabric.displayName) shell. \(state.closure.label) closure.", x: r.minX + 6, y: descY + 36, size: 8)
        txt(ctx, "\(state.pocket.label) pockets. \(state.collarType.label) collar. \(state.cuffType.label) cuffs. \(state.hemType.label) hem.", x: r.minX + 6, y: descY + 50, size: 8)
    }

    // MARK: - Page 3: Colorways

    private func drawColorwayPage(_ ctx: CGContext, _ r: CGRect) {
        let colorways: [Colorway] = [.stealth, .hazard, .tactical, .gunmetal]
        let cellW = (r.width - 20) / 2
        let cellH: CGFloat = 280

        for (i, cw) in colorways.enumerated() {
            let col = CGFloat(i % 2)
            let row = CGFloat(i / 2)
            let cx = r.minX + col * (cellW + 20)
            let cy = r.minY + row * (cellH + 16)

            // Cell border
            ctx.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
            ctx.stroke(CGRect(x: cx, y: cy, width: cellW, height: cellH))

            // Name bar
            ctx.setFillColor(CGColor(gray: 0.15, alpha: 1))
            ctx.fill(CGRect(x: cx, y: cy + cellH - 22, width: cellW, height: 22))
            txt(ctx, "CW-\(String(format: "%02d", i + 1)) · \(cw.displayName)", x: cx + 8, y: cy + cellH - 16, size: 8, bold: true, color: CGColor(gray: 0.95, alpha: 1))

            // Color swatches
            drawColorSwatch(ctx, hex: cw.primaryHex, x: cx + 8, y: cy + 8, size: 16)
            drawColorSwatch(ctx, hex: cw.secondaryHex, x: cx + 28, y: cy + 8, size: 16)
            drawColorSwatch(ctx, hex: cw.accentHex, x: cx + 48, y: cy + 8, size: 16)
        }
    }

    // MARK: - Page 4: BOM

    private func drawBOMPage(_ ctx: CGContext, _ r: CGRect) {
        let yards = state.yardage(for: state.size)

        let headers = ["Material", "Product & Detail", "Usage", "Quantity", "Source", "Cost"]
        let colWidths: [CGFloat] = [70, 140, 50, 50, 110, 50]

        var y = r.minY

        // Header row
        ctx.setFillColor(CGColor(gray: 0.92, alpha: 1))
        ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 18))
        var hx = r.minX
        for (i, header) in headers.enumerated() {
            txt(ctx, header, x: hx + 4, y: y + 4, size: 7, bold: true)
            hx += colWidths[i]
        }
        y += 20

        // BOM rows
        let rows: [(String, String, String, String, String, String)] = [
            ("Shell Fabric", state.fabric.displayName, String(format: "%.1f yd", yards), "1", state.fabric.source, "$\(Int(yards * Double(state.fabric.cost)))"),
            ("Lining", "Polyester Taffeta", String(format: "%.1f yd", yards * 0.8), "1", "Big Duck Canvas", "$\(Int(yards * 0.8 * 6))"),
            ("Zipper", "YKK Aquaguard #5", "-", "1", "WAWAK / Zipperstop", "$3"),
            ("Hardware", "ITW Nexus buckles", "-", "2", "Rockywoods", "$4"),
            ("Webbing", "Mil-spec 25mm", "2 yd", "1", "Strapworks", "$3"),
            ("Labels", "Woven main + care", "-", "2", "Dutch Label Shop", "$1"),
            ("Thread", "Polyester core-spun", "-", "1", "A&E / Coats", "$2"),
        ]

        for (i, row) in rows.enumerated() {
            if i % 2 == 0 {
                ctx.setFillColor(CGColor(gray: 0.97, alpha: 1))
                ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 16))
            }
            let vals = [row.0, row.1, row.2, row.3, row.4, row.5]
            var rx = r.minX
            for (j, val) in vals.enumerated() {
                txt(ctx, val, x: rx + 4, y: y + 3, size: 7)
                rx += colWidths[j]
            }
            y += 16
        }

        // Total
        y += 8
        ctx.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: r.minX, y: y))
        ctx.addLine(to: CGPoint(x: r.maxX, y: y))
        ctx.strokePath()
        y += 6
        let totalMat = Int(yards * Double(state.fabric.cost)) + Int(yards * 0.8 * 6) + 13
        txt(ctx, "Estimated Material Cost:", x: r.minX + 4, y: y, size: 8, bold: true)
        txt(ctx, "$\(totalMat)/unit", x: r.minX + 160, y: y, size: 8, bold: true, color: CGColor(red: 0.84, green: 0.24, blue: 0.18, alpha: 1))
        y += 16
        txt(ctx, "Estimated CMT:", x: r.minX + 4, y: y, size: 8, bold: true)
        txt(ctx, "$15–25/unit (MOQ 50)", x: r.minX + 160, y: y, size: 8)
    }

    // MARK: - Page 5: Size Chart

    private func drawSizeChartPage(_ ctx: CGContext, _ r: CGRect) {
        let sizes = GarmentSize.allCases
        let fields: [(String, String, (GradedMeasurements) -> Double)] = [
            ("Body Length", "HPS to Hem", \.bodyLength),
            ("Body Width", "1\" below armhole", \.bodyWidth),
            ("Shoulder Width", "Seam to seam", \.shoulderWidth),
            ("Hem Width", "Bottom opening", \.hemWidth),
            ("Sleeve Length", "Shoulder to cuff", \.sleeveLength),
            ("Bicep Width", "Widest point", \.sleeveDepth),
            ("Cuff Opening", "Sleeve end", \.sleeveOpen),
            ("Armhole Depth", "Shoulder to underarm", \.armholeDepth),
            ("Collar Height", "Stand height", \.collarHeight),
        ]

        let pomW: CGFloat = 100
        let descW: CGFloat = 90
        let sizeW = (r.width - pomW - descW) / CGFloat(sizes.count)

        var y = r.minY
        txt(ctx, "POINTS OF MEASURE", x: r.minX, y: y, size: 8, bold: true, color: CGColor(gray: 0.4, alpha: 1))
        y += 18

        // Header
        ctx.setFillColor(CGColor(gray: 0.92, alpha: 1))
        ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 18))
        txt(ctx, "POM", x: r.minX + 4, y: y + 4, size: 7, bold: true)
        txt(ctx, "Tol ±", x: r.minX + pomW + 4, y: y + 4, size: 7, bold: true)
        for (i, size) in sizes.enumerated() {
            let sx = r.minX + pomW + descW + CGFloat(i) * sizeW
            let isCurrent = size == state.size
            if isCurrent {
                ctx.setFillColor(CGColor(red: 0.84, green: 0.24, blue: 0.18, alpha: 1))
                ctx.fill(CGRect(x: sx, y: y, width: sizeW, height: 18))
                txt(ctx, size.rawValue, x: sx + sizeW / 2 - 6, y: y + 4, size: 8, bold: true, color: CGColor(gray: 1, alpha: 1))
            } else {
                txt(ctx, size.rawValue, x: sx + sizeW / 2 - 6, y: y + 4, size: 8, bold: true)
            }
        }
        y += 20

        // Data rows
        for (i, field) in fields.enumerated() {
            if i % 2 == 0 {
                ctx.setFillColor(CGColor(gray: 0.97, alpha: 1))
                ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 16))
            }
            txt(ctx, field.0, x: r.minX + 4, y: y + 3, size: 7, bold: true)
            txt(ctx, "±1", x: r.minX + pomW + 4, y: y + 3, size: 7, color: CGColor(gray: 0.5, alpha: 1))
            for (j, size) in sizes.enumerated() {
                let m = state.gradedMeasurements(for: size)
                let val = field.2(m)
                let sx = r.minX + pomW + descW + CGFloat(j) * sizeW
                txt(ctx, String(format: "%.1f", val), x: sx + 4, y: y + 3, size: 7)
            }
            y += 16
        }

        // Yardage + cost rows
        y += 8
        ctx.setFillColor(CGColor(gray: 0.92, alpha: 1))
        ctx.fill(CGRect(x: r.minX, y: y, width: r.width, height: 16))
        txt(ctx, "Yardage @54\"", x: r.minX + 4, y: y + 3, size: 7, bold: true)
        for (j, size) in sizes.enumerated() {
            let sx = r.minX + pomW + descW + CGFloat(j) * sizeW
            txt(ctx, String(format: "%.2f", state.yardage(for: size)), x: sx + 4, y: y + 3, size: 7)
        }
        y += 16
        txt(ctx, "Material Cost", x: r.minX + 4, y: y + 3, size: 7, bold: true)
        for (j, size) in sizes.enumerated() {
            let sx = r.minX + pomW + descW + CGFloat(j) * sizeW
            txt(ctx, "$\(Int(state.materialCost(for: size)))", x: sx + 4, y: y + 3, size: 7)
        }
    }

    // MARK: - Page 6: Construction Details

    private func drawConstructionPage(_ ctx: CGContext, _ r: CGRect) {
        var y = r.minY

        let sections: [(String, [(String, String)])] = [
            ("Closure", [
                ("Type", state.closure.label),
                ("Hardware", state.closure == .zip ? "YKK Aquaguard #5 Vislon" : state.closure.label),
            ]),
            ("Pockets", [
                ("Type", state.pocket.label),
                ("Quantity", state.pocket == .cargo ? "4 (2 chest + 2 hip)" : "2"),
                ("Construction", state.pocket == .welt || state.pocket == .zipperedWelt ? "Set-in with facing" : "Applied"),
            ]),
            ("Collar / Neck", [
                ("Type", state.collarType.label),
                ("Height", "\(Int(state.collarHeight)) cm"),
                ("Opening", "\(Int(state.neckOpeningWidth)) x \(Int(state.neckOpeningDepth)) cm"),
            ]),
            ("Cuffs", [
                ("Type", state.cuffType.label),
                ("Opening", "\(Int(state.sleeveOpen)) cm"),
            ]),
            ("Hem", [
                ("Type", state.hemType.label),
                ("Width", "\(Int(state.hemWidth)) cm"),
            ]),
            ("Seams", [
                ("Body", "Overlock + topstitch"),
                ("Sleeves", "\(state.sleeveType.label) construction"),
                ("Finishing", "Taped seams on shell"),
            ]),
        ]

        for (title, rows) in sections {
            txt(ctx, title.uppercased(), x: r.minX, y: y, size: 8, bold: true, color: CGColor(red: 0.84, green: 0.24, blue: 0.18, alpha: 1))
            y += 14
            for (key, val) in rows {
                txt(ctx, key, x: r.minX + 8, y: y, size: 7, color: CGColor(gray: 0.4, alpha: 1))
                txt(ctx, val, x: r.minX + 100, y: y, size: 7, bold: true)
                y += 14
            }
            y += 10
        }

        // Components list
        if !state.placedComponents.isEmpty {
            txt(ctx, "PLACED COMPONENTS", x: r.minX, y: y, size: 8, bold: true, color: CGColor(red: 0.84, green: 0.24, blue: 0.18, alpha: 1))
            y += 14
            for comp in state.placedComponents {
                txt(ctx, "\(comp.type.displayName) on \(comp.panel.displayName)", x: r.minX + 8, y: y, size: 7)
                txt(ctx, String(format: "pos(%.0f%%, %.0f%%) size(%.0f%%, %.0f%%)", comp.x * 100, comp.y * 100, comp.w * 100, comp.h * 100), x: r.minX + 180, y: y, size: 6, color: CGColor(gray: 0.5, alpha: 1))
                y += 14
            }
        }
    }

    // MARK: - Helpers

    private enum TextAlign { case left, right }

    private func txt(_ ctx: CGContext, _ text: String, x: CGFloat, y: CGFloat, size: CGFloat, bold: Bool = false, color: CGColor = CGColor(gray: 0.1, alpha: 1), align: TextAlign = .left) {
        let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let drawX: CGFloat = align == .right ? x - CGFloat(width) : x
        ctx.saveGState()
        ctx.textPosition = CGPoint(x: drawX, y: y)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    private func drawColorSwatch(_ ctx: CGContext, hex: String, x: CGFloat, y: CGFloat, size: CGFloat) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1))
        ctx.fill(CGRect(x: x, y: y, width: size, height: size))
        ctx.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
        ctx.setLineWidth(0.5)
        ctx.stroke(CGRect(x: x, y: y, width: size, height: size))
    }
}
