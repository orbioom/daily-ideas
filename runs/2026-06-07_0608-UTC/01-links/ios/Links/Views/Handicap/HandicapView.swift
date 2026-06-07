import SwiftUI
import SwiftData

/// The home screen: the big Handicap Index, its trend, and the differentials
/// table with the counting scores highlighted.
struct HandicapView: View {
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @State private var summary: HandicapEngine.Summary?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loading
                } else if let summary, summary.results.count >= 3 {
                    content(summary)
                } else {
                    needMore
                }
            }
            .navigationTitle("Handicap")
            .background(Brand.pageBackground)
        }
        .task(id: rounds.map(\.id)) { await recompute() }
    }

    private func recompute() async {
        isLoading = true
        // Yield so the loading state can render; the computation itself is fast
        // and touches SwiftData models, so it stays on the main actor.
        await Task.yield()
        summary = HandicapEngine.summarize(rounds: rounds)
        isLoading = false
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Calculating your index…")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var needMore: some View {
        ScrollView {
            EmptyStateView(
                icon: "flag.checkered",
                title: "Three rounds to go",
                message: "The World Handicap System needs at least three complete 18-hole rounds before it can establish your Index. Log a round to begin.")
            .glassCard()
            .padding()
        }
    }

    private func content(_ s: HandicapEngine.Summary) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                indexCard(s)
                if !s.results.isEmpty { trendCard(s) }
                differentialsCard(s)
            }
            .padding()
        }
    }

    private func indexCard(_ s: HandicapEngine.Summary) -> some View {
        VStack(spacing: 8) {
            Eyebrow(text: "Handicap Index")
            Text(s.index.map { fmt($0) } ?? "—")
                .font(Brand.mono(64, weight: .bold))
                .foregroundStyle(Brand.text)
                .contentTransition(.numericText())
                .accessibilityLabel("Handicap index \(s.index.map { fmt($0) } ?? "not established")")
            HStack(spacing: 16) {
                if let low = s.lowIndex {
                    metric("Low", fmt(low))
                }
                metric("Counting", "\(s.differentialsUsed) of \(s.totalCounted)")
                metric("Rounds", "\(s.results.count)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label.uppercased()).font(Brand.mono(9, weight: .medium)).tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func trendCard(_ s: HandicapEngine.Summary) -> some View {
        let diffs = s.results.suffix(20).map { $0.differential }
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Differential trend")
            DifferentialChart(values: Array(diffs))
                .frame(height: 120)
            Text("Most recent \(diffs.count) score differentials, oldest to newest.")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func differentialsCard(_ s: HandicapEngine.Summary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Score differentials")
            ForEach(Array(s.results.suffix(20).reversed())) { r in
                HStack {
                    Circle()
                        .fill(r.isCounting ? Brand.live : Brand.text3.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text(r.date, format: .dateTime.month(.abbreviated).day())
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text("AGS \(r.adjustedGross)")
                        .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    Text(fmt(r.differential))
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(r.isCounting ? Brand.text : Brand.text2)
                        .frame(width: 56, alignment: .trailing)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(r.date.formatted(date: .abbreviated, time: .omitted)), differential \(fmt(r.differential))\(r.isCounting ? ", counting" : "")")
                if r.id != s.results.suffix(20).first?.id {
                    Divider().overlay(Brand.hairline)
                }
            }
            HStack(spacing: 6) {
                Circle().fill(Brand.live).frame(width: 8, height: 8)
                Text("Counts toward your index")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .padding(.top, 4)
        }
        .glassCard()
    }

    private func fmt(_ v: Double) -> String {
        v < 0 ? "+" + String(format: "%.1f", -v) : String(format: "%.1f", v)
    }
}

/// A small line chart of differentials (lower is better) rendered with Canvas.
struct DifferentialChart: View {
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            if values.count < 2 {
                Text("Not enough data")
                    .font(.caption).foregroundStyle(Brand.text3)
                    .frame(width: w, height: h)
            } else {
                let lo = (values.min() ?? 0) - 1
                let hi = (values.max() ?? 1) + 1
                let range = max(0.001, hi - lo)
                Canvas { ctx, size in
                    var path = Path()
                    for (i, v) in values.enumerated() {
                        let x = size.width * Double(i) / Double(values.count - 1)
                        let y = size.height * (1 - (v - lo) / range)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    ctx.stroke(path, with: .color(Brand.live), lineWidth: 2)
                    // dots
                    for (i, v) in values.enumerated() {
                        let x = size.width * Double(i) / Double(values.count - 1)
                        let y = size.height * (1 - (v - lo) / range)
                        let r = CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)
                        ctx.fill(Path(ellipseIn: r), with: .color(Brand.text2))
                    }
                }
            }
        }
        .accessibilityLabel("Differential trend chart")
        .accessibilityValue(values.isEmpty ? "no data" :
            "from \(String(format: "%.1f", values.first ?? 0)) to \(String(format: "%.1f", values.last ?? 0))")
    }
}
