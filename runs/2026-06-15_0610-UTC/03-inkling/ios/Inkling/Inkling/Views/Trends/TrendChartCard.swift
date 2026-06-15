import SwiftUI
import Charts

/// A line+area trend chart for one tracker over the chosen range. Falls back to an empty note when
/// the tracker has too few points to draw a meaningful line.
struct TrendChartCard: View {
    let tracker: Tracker
    let points: [TrendPoint]
    let range: TimeRange

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    TrackerIcon(symbol: tracker.symbolName, color: tracker.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tracker.name)
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("\(range.label) · \(points.count) entries")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }

                if points.count < 2 {
                    Text("Log this on at least two days to see a trend line.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 140)
                } else {
                    chart
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { p in
                AreaMark(
                    x: .value("Day", p.date),
                    y: .value(tracker.name, p.value)
                )
                .foregroundStyle(
                    LinearGradient(colors: [tracker.color.opacity(0.28), tracker.color.opacity(0.02)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .interpolationMethod(.monotone)
            }
            ForEach(points) { p in
                LineMark(
                    x: .value("Day", p.date),
                    y: .value(tracker.name, p.value)
                )
                .foregroundStyle(tracker.color)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.monotone)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(Theme.rounded(10))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel().font(Theme.rounded(10))
            }
        }
        .accessibilityLabel("\(tracker.name) trend over \(range.label)")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let first = points.first?.value, let last = points.last?.value,
              let min = points.map(\.value).min(), let max = points.map(\.value).max() else {
            return "No data"
        }
        let dir = last > first ? "up" : (last < first ? "down" : "flat")
        return "Ranges from \(fmt(min)) to \(fmt(max)) across \(points.count) days, trending \(dir)."
    }

    private func fmt(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}
