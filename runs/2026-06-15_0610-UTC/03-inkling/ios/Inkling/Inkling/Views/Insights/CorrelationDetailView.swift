import SwiftUI
import Charts

/// Tap-through detail for one correlation: a scatter chart of paired (factor, outcome) values with
/// a trend line, plus a plain-English reading and the stats behind it.
struct CorrelationDetailView: View {
    let result: CorrelationEngine.Result
    let trackers: [Tracker]
    let lag: Int

    @Environment(\.dismiss) private var dismiss

    private var factor: Tracker? { trackers.first { $0.id == result.factorID } }
    private var outcome: Tracker? { trackers.first { $0.id == result.outcomeID } }

    private var points: [CorrelationEngine.ScatterPoint] {
        guard let f = factor, let o = outcome else { return [] }
        let fMap = dayMap(f), oMap = dayMap(o)
        return CorrelationEngine.scatterPoints(factor: fMap, outcome: oMap, lag: lag)
    }

    private var dirColor: Color {
        result.direction == .positive ? Theme.positive : Theme.negative
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headline
                    chartCard
                    readingCard
                    statsCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Correlation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headline: some View {
        HStack(spacing: 10) {
            if let factor { TrackerIcon(symbol: factor.symbolName, color: factor.color) }
            Image(systemName: "arrow.right").foregroundStyle(Theme.inkFaint).accessibilityHidden(true)
            if let outcome { TrackerIcon(symbol: outcome.symbolName, color: outcome.color) }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.factorName) → \(result.outcomeName)")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(lag == 1 ? "Next-day" : "Same-day") · \(result.n) shared days")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    private var chartCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Each dot is a day")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if points.count < CorrelationEngine.minSamples {
                    Text("Not enough overlapping days to chart.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart {
                        ForEach(points) { p in
                            PointMark(
                                x: .value(result.factorName, p.x),
                                y: .value(result.outcomeName, p.y)
                            )
                            .foregroundStyle(dirColor.opacity(0.75))
                            .symbolSize(60)
                        }
                        if let line = trendLine {
                            ForEach(line) { seg in
                                LineMark(
                                    x: .value("x", seg.x),
                                    y: .value("y", seg.y),
                                    series: .value("trend", "fit")
                                )
                                .foregroundStyle(Theme.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                            }
                        }
                    }
                    .frame(height: 220)
                    .chartXAxisLabel(axisLabel(for: factor, fallback: result.factorName))
                    .chartYAxisLabel(axisLabel(for: outcome, fallback: result.outcomeName))
                    .accessibilityLabel("Scatter plot of \(result.factorName) versus \(result.outcomeName)")
                    .accessibilityValue("\(points.count) days plotted. The dashed line shows the overall trend, which is \(result.direction == .positive ? "upward" : "downward").")
                }
            }
        }
    }

    private var readingCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label("What this says", systemImage: "text.quote")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(result.reading(factorScale: factor?.kind.title ?? "",
                                    outcomeScale: outcome?.kind.title ?? ""))
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Behind the number", systemImage: "function")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 10) {
                    StatTile(value: String(format: "%@%.2f", result.direction.sign, abs(result.r)),
                             caption: "Pearson r", color: dirColor)
                    StatTile(value: "\(result.n)", caption: "Shared days")
                    StatTile(value: result.strength.label, caption: "Strength", color: dirColor)
                }
                Text(result.confidenceLabel)
                    .font(Theme.rounded(13))
                    .foregroundStyle(result.n < 7 ? Theme.warn : Theme.inkSoft)
            }
        }
    }

    // MARK: Trend line

    private struct Seg: Identifiable { let id = UUID(); let x: Double; let y: Double }

    /// A least-squares fit across the scatter, returned as two endpoints for a LineMark.
    private var trendLine: [Seg]? {
        let pts = points
        guard pts.count >= CorrelationEngine.minSamples else { return nil }
        let xs = pts.map(\.x), ys = pts.map(\.y)
        let n = Double(xs.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var num = 0.0, den = 0.0
        for i in 0..<xs.count {
            let dx = xs[i] - meanX
            num += dx * (ys[i] - meanY)
            den += dx * dx
        }
        guard den > 1e-9, let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return nil }
        let slope = num / den
        let intercept = meanY - slope * meanX
        return [Seg(x: minX, y: slope * minX + intercept),
                Seg(x: maxX, y: slope * maxX + intercept)]
    }

    // MARK: Helpers

    private func dayMap(_ tracker: Tracker) -> [Date: Double] {
        var map: [Date: Double] = [:]
        for e in tracker.sortedEntries { map[DayMath.startOfDay(e.date)] = e.value }
        return map
    }

    private func axisLabel(for tracker: Tracker?, fallback: String) -> String {
        guard let tracker else { return fallback }
        if let unit = tracker.unit, !unit.isEmpty { return "\(tracker.name) (\(unit))" }
        return tracker.name
    }
}
