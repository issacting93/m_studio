import SwiftUI

struct SizeGradeView: View {
    let state: DesignState

    private let sizes = GarmentSize.allCases
    private let fields: [(key: String, label: String)] = [
        ("bodyLength", "Body L"),
        ("bodyWidth", "Body W"),
        ("shoulderWidth", "Shoulder"),
        ("hemWidth", "Hem W"),
        ("neckOpeningWidth", "Neck W"),
        ("armholeDepth", "Armhole"),
        ("collarHeight", "Collar H"),
        ("sleeveLength", "Sleeve L"),
        ("sleeveDepth", "Bicep"),
        ("sleeveOpen", "Cuff")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                gradeTable
                yardageSection
                guidance
            }
            .padding(24)
        }
        .background(Theme.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SIZE GRADE TABLE")
                .font(.custom("JetBrains Mono", size: 9))
                .fontWeight(.bold)
                .foregroundColor(Theme.soft)
                .tracking(2.5)
            Text("Base size \(state.size.rawValue). Other sizes graded with industry-standard rules (±4cm body width, ±2cm length, ±3cm sleeve per step).")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(Theme.soft)
                .lineSpacing(3)
        }
    }

    private var gradeTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 70, alignment: .leading)
                ForEach(sizes) { size in
                    Text(size.rawValue)
                        .font(.custom("JetBrains Mono", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(size == state.size ? Theme.paper : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(size == state.size ? Theme.accent : Color.clear)
                }
            }
            .background(Theme.ink.opacity(0.05))

            // Data rows
            ForEach(fields, id: \.key) { field in
                HStack(spacing: 0) {
                    Text(field.label)
                        .font(.custom("JetBrains Mono", size: 9))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.ink)
                        .frame(width: 70, alignment: .leading)
                    ForEach(sizes) { size in
                        let m = state.gradedMeasurements(for: size)
                        let value: Double = {
                            switch field.key {
                            case "bodyLength": return m.bodyLength
                            case "bodyWidth": return m.bodyWidth
                            case "shoulderWidth": return m.shoulderWidth
                            case "hemWidth": return m.hemWidth
                            case "neckOpeningWidth": return m.neckOpeningWidth
                            case "armholeDepth": return m.armholeDepth
                            case "collarHeight": return m.collarHeight
                            case "sleeveLength": return m.sleeveLength
                            case "sleeveDepth": return m.sleeveDepth
                            case "sleeveOpen": return m.sleeveOpen
                            default: return 0
                            }
                        }()
                        HStack(spacing: 1) {
                            Text("\(Int(value))")
                                .font(.custom("JetBrains Mono", size: 10))
                                .foregroundColor(Theme.ink)
                            Text("cm")
                                .font(.custom("JetBrains Mono", size: 7))
                                .foregroundColor(Theme.soft)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                }
            }

            // Yardage row
            HStack(spacing: 0) {
                Text("Yard @54\"")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink)
                    .frame(width: 70, alignment: .leading)
                ForEach(sizes) { size in
                    Text(String(format: "%.2f", state.yardage(for: size)))
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(Theme.ink)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
            }

            // Cost row
            HStack(spacing: 0) {
                Text("Mat. Cost")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ink)
                    .frame(width: 70, alignment: .leading)
                ForEach(sizes) { size in
                    Text("$\(Int(state.materialCost(for: size)))")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(Theme.ink)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)
        }
        .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
    }

    private var yardageSection: some View {
        EmptyView()
    }

    private var guidance: some View {
        Text("Sample makers and factories use these grade-rules. Copy this table into your tech pack's \"size chart\" section. Most techwear brands launch with S–XL (4 sizes) and add XS/XXL after validating demand.")
            .font(.custom("JetBrains Mono", size: 9))
            .foregroundColor(Theme.soft)
            .lineSpacing(3)
            .padding(.top, 8)
    }
}
