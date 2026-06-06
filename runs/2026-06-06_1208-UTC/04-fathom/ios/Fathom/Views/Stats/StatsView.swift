import SwiftUI
import SwiftData

/// Diving overview: totals, consumption, and a depth distribution.
struct StatsView: View {
    @Query(sort: \Dive.date) private var dives: [Dive]
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var fmt: DiveFmt { DiveFmt(unit: unit) }

    private var totalMin: Int { dives.reduce(0) { $0 + $1.durationMin } }
    private var avgSAC: Double {
        let valid = dives.map(\.sac).filter { $0 > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }
    private var avgDepth: Double {
        let valid = dives.map(\.maxDepthM).filter { $0 > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }
    /// Depth buckets (in metres) -> count.
    private var depthBuckets: [(String, Int)] {
        let ranges: [(String, ClosedRange<Double>)] = [
            ("0–10", 0...10), ("10–18", 10.0001...18), ("18–24", 18.0001...24),
            ("24–30", 24.0001...30), ("30+", 30.0001...1000)
        ]
        return ranges.map { label, range in (label, dives.filter { range.contains($0.maxDepthM) }.count) }
    }
    private var byType: [(DiveType, Int)] {
        DiveType.allCases.compactMap { t in
            let c = dives.filter { $0.type == t }.count
            return c > 0 ? (t, c) : nil
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if dives.isEmpty {
                        EmptyStateView(icon: "chart.bar", title: "No stats yet",
                                       message: "Log some dives to see your totals and trends.")
                    } else { content }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    StatTile(value: "\(dives.count)", label: "Total dives")
                    StatTile(value: "\(totalMin / 60)h \(totalMin % 60)m", label: "Bottom time", tint: Brand.live)
                }
                HStack(spacing: 10) {
                    StatTile(value: fmt.depth(dives.map(\.maxDepthM).max() ?? 0), label: "Deepest")
                    StatTile(value: fmt.depth(avgDepth), label: "Avg max depth")
                    StatTile(value: avgSAC > 0 ? String(format: "%.1f", avgSAC) : "—", label: "Avg SAC L/min", tint: Brand.info)
                }
                depthCard
                if !byType.isEmpty { typeCard }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private var depthCard: some View {
        let maxCount = depthBuckets.map(\.1).max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Depth distribution (m)")
            ForEach(depthBuckets, id: \.0) { label, count in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(label).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(count)").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Brand.info.opacity(0.85))
                            .frame(width: max(count == 0 ? 0 : 6, geo.size.width * (maxCount > 0 ? Double(count) / Double(maxCount) : 0)), height: 8)
                    }
                    .frame(height: 8)
                }
            }
        }
        .glassCard()
    }

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "By type")
            FlexWrap(byType.map { "\($0.0.label) · \($0.1)" }) { label in
                Pill(text: label)
            }
        }
        .glassCard()
    }
}

/// Minimal wrapping chip layout.
struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content
    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items; self.content = content
    }
    var body: some View { FlowLayout(spacing: 8) { ForEach(items, id: \.self) { content($0) } } }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
    }
}
