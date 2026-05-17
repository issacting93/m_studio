import SwiftUI

struct SourcingView: View {
    let state: DesignState

    private var rows: [(role: String, name: String, sub: String, tag: String)] {
        let f = state.fabric
        return [
            (role: "Fabric", name: f.displayName, sub: "\(f.source) · $\(f.cost)/yd", tag: f.spec.components(separatedBy: "·").first?.trimmingCharacters(in: .whitespaces) ?? ""),
            (role: "Hardware", name: "YKK Aquaguard zipper", sub: "WAWAK · Zipperstop NYC (27 Allen St)", tag: "YKK #5"),
            (role: "Hardware", name: "ITW Nexus / Duraflex buckles", sub: "Rockywoods · direct", tag: "BUCKLE"),
            (role: "Webbing", name: "Mil-spec polyester webbing", sub: "Strapworks · Country Brook Design", tag: "1\" MIL-W"),
            (role: "Trim", name: "Woven labels & hangtags", sub: "Dutch Label Shop · no minimum", tag: "LABEL"),
            (role: "Print", name: state.graphic == .off ? "No print spec" : "DTF / Screen print on cut panels", sub: "Jakprints · Real Thread", tag: "GFX"),
            (role: "Sample", name: "TEG / Fashion Solutions NYC", sub: "NYC Garment District · 4–8 wk turnaround", tag: "NYC"),
            (role: "Production", name: "Bandung CMT · Project SGN (HCMC)", sub: "MOQ 30–100 · 4–8 wk lead time", tag: "IDN/VN")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SOURCING · SUPPLIERS")
                    .font(.custom("JetBrains Mono", size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.soft)
                    .tracking(2.5)
                    .padding(.bottom, 12)

                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 12) {
                        Text(row.role.uppercased())
                            .font(.custom("JetBrains Mono", size: 8))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.accent)
                            .tracking(1)
                            .frame(width: 70, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.custom("JetBrains Mono", size: 10))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.ink)
                            Text(row.sub)
                                .font(.custom("JetBrains Mono", size: 8.5))
                                .foregroundColor(Theme.soft)
                        }

                        Spacer()

                        Text(row.tag)
                            .font(.custom("JetBrains Mono", size: 8))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.ink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 0.5))
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
                    }
                }

                Text("Starting-point suppliers. After your first sample, your factory will have preferred mills with better pricing — ask for swatches first.")
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundColor(Theme.soft)
                    .lineSpacing(3)
                    .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Theme.paper)
    }
}
