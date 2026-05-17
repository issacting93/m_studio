import SwiftUI

// MARK: - SVG Content Model

struct SVGContent: Codable, Equatable {
    let rawSVG: String
    let viewBoxWidth: Double
    let viewBoxHeight: Double

    init(rawSVG: String, viewBoxWidth: Double = 400, viewBoxHeight: Double = 200) {
        self.rawSVG = rawSVG
        self.viewBoxWidth = viewBoxWidth
        self.viewBoxHeight = viewBoxHeight
    }

    /// Parse an SVG file string, extracting the viewBox and inner content
    static func fromFile(_ svgString: String) -> SVGContent? {
        var vbW: Double = 400
        var vbH: Double = 200

        // Extract viewBox
        if let range = svgString.range(of: "viewBox=\"", options: .caseInsensitive) {
            let after = svgString[range.upperBound...]
            if let endQuote = after.firstIndex(of: "\"") {
                let vbStr = String(after[after.startIndex..<endQuote])
                let parts = vbStr.split(separator: " ").compactMap { Double($0) }
                if parts.count >= 4 {
                    vbW = parts[2]
                    vbH = parts[3]
                }
            }
        }

        return SVGContent(rawSVG: svgString, viewBoxWidth: vbW, viewBoxHeight: vbH)
    }
}

// MARK: - SVG Renderer

/// Renders SVG content into a SwiftUI Canvas GraphicsContext.
/// Supports a subset of SVG: rect, circle, line, polyline, path (basic), text, g.
struct SVGRenderer {

    static func render(_ svg: SVGContent, context: inout GraphicsContext, in rect: CGRect, tintColor: Color? = nil, skipBackground: Bool = false, opacity: Double = 1.0) {
        // Scale from viewBox to target rect
        let scaleX = rect.width / svg.viewBoxWidth
        let scaleY = rect.height / svg.viewBoxHeight
        let scale = min(scaleX, scaleY)
        let offsetX = rect.minX + (rect.width - svg.viewBoxWidth * scale) / 2
        let offsetY = rect.minY + (rect.height - svg.viewBoxHeight * scale) / 2

        // Parse and render basic SVG elements
        let elements = parseElements(from: svg.rawSVG)
        for (i, element) in elements.enumerated() {
            // Skip background rect: first rect that spans the full viewBox
            if skipBackground && i == 0 && element.tag == "rect" {
                let ew = Double(element.attributes["width"] ?? "0") ?? 0
                let eh = Double(element.attributes["height"] ?? "0") ?? 0
                if ew >= svg.viewBoxWidth * 0.95 && eh >= svg.viewBoxHeight * 0.95 {
                    continue
                }
            }
            if opacity < 1.0 {
                var opCtx = context
                opCtx.opacity = opacity
                renderElement(element, context: &opCtx, scale: scale, offsetX: offsetX, offsetY: offsetY, tintColor: tintColor)
            } else {
                renderElement(element, context: &context, scale: scale, offsetX: offsetX, offsetY: offsetY, tintColor: tintColor)
            }
        }
    }

    // MARK: - Simple XML Element Parsing

    struct SVGElement {
        let tag: String
        var attributes: [String: String]
        var children: [SVGElement]
        var textContent: String?
    }

    static func parseElements(from svgString: String) -> [SVGElement] {
        // Simple regex-based extraction for common SVG elements
        var elements: [SVGElement] = []

        // Match self-closing tags and content tags
        let tagPattern = "<(rect|circle|line|polyline|polygon|path|text|ellipse)\\s([^>]*?)(/?)>"
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: .dotMatchesLineSeparators) else { return elements }
        let nsString = svgString as NSString
        let matches = regex.matches(in: svgString, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            let tag = nsString.substring(with: match.range(at: 1))
            let attrStr = nsString.substring(with: match.range(at: 2))
            let attrs = parseAttributes(attrStr)

            var element = SVGElement(tag: tag, attributes: attrs, children: [], textContent: nil)

            // For text elements, try to extract text content
            if tag == "text" {
                let fullMatch = nsString.substring(with: match.range)
                if !fullMatch.hasSuffix("/>") {
                    // Find closing tag
                    let searchStart = match.range.location + match.range.length
                    let closeTag = "</text>"
                    if let closeRange = svgString.range(of: closeTag, range: svgString.index(svgString.startIndex, offsetBy: searchStart)..<svgString.endIndex) {
                        let textStart = svgString.index(svgString.startIndex, offsetBy: searchStart)
                        element.textContent = String(svgString[textStart..<closeRange.lowerBound])
                    }
                }
            }

            elements.append(element)
        }

        return elements
    }

    static func parseAttributes(_ str: String) -> [String: String] {
        var attrs: [String: String] = [:]
        let pattern = "(\\w[\\w-]*)=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return attrs }
        let nsStr = str as NSString
        let matches = regex.matches(in: str, range: NSRange(location: 0, length: nsStr.length))
        for match in matches {
            let key = nsStr.substring(with: match.range(at: 1))
            let value = nsStr.substring(with: match.range(at: 2))
            attrs[key] = value
        }
        return attrs
    }

    // MARK: - Element Rendering

    static func renderElement(_ element: SVGElement, context: inout GraphicsContext, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat, tintColor: Color?) {
        let fillColor = tintColor ?? colorFromAttribute(element.attributes["fill"])
        let strokeColor = tintColor ?? colorFromAttribute(element.attributes["stroke"])
        let strokeWidth = CGFloat(Double(element.attributes["stroke-width"] ?? "1") ?? 1) * scale
        let opacity = CGFloat(Double(element.attributes["opacity"] ?? "1") ?? 1)

        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)
        }

        switch element.tag {
        case "rect":
            guard let x = Double(element.attributes["x"] ?? "0"),
                  let y = Double(element.attributes["y"] ?? "0"),
                  let w = Double(element.attributes["width"] ?? "0"),
                  let h = Double(element.attributes["height"] ?? "0") else { return }
            let rect = CGRect(x: offsetX + x * scale, y: offsetY + y * scale, width: w * scale, height: h * scale)
            if let fc = fillColor, element.attributes["fill"] != "none" {
                context.fill(Path(rect), with: .color(fc.opacity(opacity)))
            }
            if let sc = strokeColor {
                context.stroke(Path(rect), with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)
            }

        case "circle":
            guard let cx = Double(element.attributes["cx"] ?? "0"),
                  let cy = Double(element.attributes["cy"] ?? "0"),
                  let r = Double(element.attributes["r"] ?? "0") else { return }
            let circle = CGRect(x: offsetX + (cx - r) * scale, y: offsetY + (cy - r) * scale, width: r * 2 * scale, height: r * 2 * scale)
            if let fc = fillColor, element.attributes["fill"] != "none" {
                context.fill(Circle().path(in: circle), with: .color(fc.opacity(opacity)))
            }
            if let sc = strokeColor {
                context.stroke(Circle().path(in: circle), with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)
            }

        case "ellipse":
            guard let cx = Double(element.attributes["cx"] ?? "0"),
                  let cy = Double(element.attributes["cy"] ?? "0"),
                  let rx = Double(element.attributes["rx"] ?? "0"),
                  let ry = Double(element.attributes["ry"] ?? "0") else { return }
            let rect = CGRect(x: offsetX + (cx - rx) * scale, y: offsetY + (cy - ry) * scale, width: rx * 2 * scale, height: ry * 2 * scale)
            if let fc = fillColor, element.attributes["fill"] != "none" {
                context.fill(Ellipse().path(in: rect), with: .color(fc.opacity(opacity)))
            }
            if let sc = strokeColor {
                context.stroke(Ellipse().path(in: rect), with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)
            }

        case "line":
            guard let x1 = Double(element.attributes["x1"] ?? "0"),
                  let y1 = Double(element.attributes["y1"] ?? "0"),
                  let x2 = Double(element.attributes["x2"] ?? "0"),
                  let y2 = Double(element.attributes["y2"] ?? "0") else { return }
            var path = Path()
            path.move(to: pt(x1, y1))
            path.addLine(to: pt(x2, y2))
            let sc = strokeColor ?? .primary
            context.stroke(path, with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)

        case "polyline", "polygon":
            guard let pointsStr = element.attributes["points"] else { return }
            let points = parsePoints(pointsStr)
            guard points.count >= 2 else { return }
            var path = Path()
            path.move(to: pt(points[0].0, points[0].1))
            for i in 1..<points.count {
                path.addLine(to: pt(points[i].0, points[i].1))
            }
            if element.tag == "polygon" { path.closeSubpath() }
            if let fc = fillColor, element.attributes["fill"] != "none", element.tag == "polygon" {
                context.fill(path, with: .color(fc.opacity(opacity)))
            }
            if let sc = strokeColor {
                context.stroke(path, with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)
            }

        case "path":
            guard let d = element.attributes["d"] else { return }
            let cgPath = parseSVGPath(d: d, scale: scale, offsetX: offsetX, offsetY: offsetY)
            let path = Path(cgPath)
            if let fc = fillColor, element.attributes["fill"] != "none" {
                context.fill(path, with: .color(fc.opacity(opacity)))
            }
            if let sc = strokeColor {
                context.stroke(path, with: .color(sc.opacity(opacity)), lineWidth: strokeWidth)
            }

        case "text":
            guard let x = Double(element.attributes["x"] ?? "0"),
                  let y = Double(element.attributes["y"] ?? "0"),
                  let content = element.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !content.isEmpty else { return }
            let fontSize = CGFloat(Double(element.attributes["font-size"] ?? "12") ?? 12) * scale
            let fontFamily = element.attributes["font-family"] ?? "JetBrains Mono"
            let color = fillColor ?? .primary
            let anchor: UnitPoint = element.attributes["text-anchor"] == "middle" ? .center :
                                    element.attributes["text-anchor"] == "end" ? .trailing : .leading
            context.draw(
                Text(content)
                    .font(.custom(fontFamily, size: fontSize))
                    .foregroundColor(color.opacity(opacity)),
                at: pt(x, y),
                anchor: anchor == .center ? .center : (anchor == .trailing ? .trailing : .leading)
            )

        default:
            break
        }
    }

    // MARK: - SVG Path Parser (basic M, L, H, V, C, Q, Z commands)

    static func parseSVGPath(d: String, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> CGMutablePath {
        let path = CGMutablePath()
        var curX: CGFloat = 0
        var curY: CGFloat = 0

        // Tokenize: split on command letters, keeping the letter
        let commands = tokenizePath(d)

        for (cmd, nums) in commands {
            let relative = cmd.isLowercase
            let c = cmd.uppercased().first ?? "Z"

            switch c {
            case "M":
                var i = 0
                while i + 1 < nums.count {
                    let x = relative ? curX + nums[i] : nums[i]
                    let y = relative ? curY + nums[i + 1] : nums[i + 1]
                    if i == 0 { path.move(to: CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)) }
                    else { path.addLine(to: CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)) }
                    curX = x; curY = y
                    i += 2
                }
            case "L":
                var i = 0
                while i + 1 < nums.count {
                    let x = relative ? curX + nums[i] : nums[i]
                    let y = relative ? curY + nums[i + 1] : nums[i + 1]
                    path.addLine(to: CGPoint(x: offsetX + x * scale, y: offsetY + y * scale))
                    curX = x; curY = y
                    i += 2
                }
            case "H":
                for n in nums {
                    let x = relative ? curX + n : n
                    path.addLine(to: CGPoint(x: offsetX + x * scale, y: offsetY + curY * scale))
                    curX = x
                }
            case "V":
                for n in nums {
                    let y = relative ? curY + n : n
                    path.addLine(to: CGPoint(x: offsetX + curX * scale, y: offsetY + y * scale))
                    curY = y
                }
            case "C":
                var i = 0
                while i + 5 < nums.count {
                    let x1 = (relative ? curX + nums[i] : nums[i])
                    let y1 = (relative ? curY + nums[i+1] : nums[i+1])
                    let x2 = (relative ? curX + nums[i+2] : nums[i+2])
                    let y2 = (relative ? curY + nums[i+3] : nums[i+3])
                    let x = (relative ? curX + nums[i+4] : nums[i+4])
                    let y = (relative ? curY + nums[i+5] : nums[i+5])
                    path.addCurve(to: CGPoint(x: offsetX + x * scale, y: offsetY + y * scale),
                                  control1: CGPoint(x: offsetX + x1 * scale, y: offsetY + y1 * scale),
                                  control2: CGPoint(x: offsetX + x2 * scale, y: offsetY + y2 * scale))
                    curX = x; curY = y
                    i += 6
                }
            case "Q":
                var i = 0
                while i + 3 < nums.count {
                    let x1 = (relative ? curX + nums[i] : nums[i])
                    let y1 = (relative ? curY + nums[i+1] : nums[i+1])
                    let x = (relative ? curX + nums[i+2] : nums[i+2])
                    let y = (relative ? curY + nums[i+3] : nums[i+3])
                    path.addQuadCurve(to: CGPoint(x: offsetX + x * scale, y: offsetY + y * scale),
                                      control: CGPoint(x: offsetX + x1 * scale, y: offsetY + y1 * scale))
                    curX = x; curY = y
                    i += 4
                }
            case "Z":
                path.closeSubpath()
            default:
                break
            }
        }

        return path
    }

    static func tokenizePath(_ d: String) -> [(Character, [CGFloat])] {
        var result: [(Character, [CGFloat])] = []
        let cmdChars = Set("MmLlHhVvCcSsQqTtAaZz")
        var currentCmd: Character = "M"
        var numBuffer = ""
        var nums: [CGFloat] = []

        func flush() {
            if !numBuffer.isEmpty {
                if let n = Double(numBuffer) { nums.append(CGFloat(n)) }
                numBuffer = ""
            }
        }

        func pushCmd() {
            flush()
            if !nums.isEmpty || currentCmd == "Z" || currentCmd == "z" {
                result.append((currentCmd, nums))
                nums = []
            }
        }

        for char in d {
            if cmdChars.contains(char) {
                pushCmd()
                currentCmd = char
            } else if char == "," || char == " " || char == "\n" || char == "\r" || char == "\t" {
                flush()
            } else if char == "-" && !numBuffer.isEmpty && !numBuffer.hasSuffix("e") {
                flush()
                numBuffer.append(char)
            } else {
                numBuffer.append(char)
            }
        }
        pushCmd()

        return result
    }

    // MARK: - Color Parsing

    static func colorFromAttribute(_ value: String?) -> Color? {
        guard let value, value != "none", !value.isEmpty else { return nil }
        if value.hasPrefix("#") {
            return Color(hex: value)
        }
        switch value.lowercased() {
        case "white": return .white
        case "black": return .black
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "currentcolor": return .primary
        default: return .primary
        }
    }

    // MARK: - Points Parser

    static func parsePoints(_ str: String) -> [(Double, Double)] {
        let cleaned = str.replacingOccurrences(of: ",", with: " ")
        let nums = cleaned.split(separator: " ").compactMap { Double($0) }
        var points: [(Double, Double)] = []
        var i = 0
        while i + 1 < nums.count {
            points.append((nums[i], nums[i + 1]))
            i += 2
        }
        return points
    }
}
