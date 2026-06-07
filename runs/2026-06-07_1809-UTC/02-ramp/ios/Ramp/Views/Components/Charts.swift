import SwiftUI
import Charts

/// The Performance Management Chart: CTL (fitness) and ATL (fatigue) as lines,
/// with an optional TSB (form) area. Reused by Today (mini) and Trends (full).
struct PMCChart: View {
    let points: [LoadEngine.DayPoint]
    var showTSB: Bool = true
    var height: CGFloat = 240

    var body: some View {
        Chart {
            if showTSB {
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Date", p.date),
                        y: .value("Form", p.tsb)
                    )
                    .foregroundStyle(Brand.info.opacity(0.16))
                    .interpolationMethod(.monotone)
                }
            }
            ForEach(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Fitness", p.ctl),
                    series: .value("Metric", "Fitness (CTL)")
                )
                .foregroundStyle(Brand.live)
                .lineStyle(StrokeStyle(lineWidth: 2.4))
                .interpolationMethod(.monotone)
            }
            ForEach(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Fatigue", p.atl),
                    series: .value("Metric", "Fatigue (ATL)")
                )
                .foregroundStyle(Brand.warn)
                .lineStyle(StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                .interpolationMethod(.monotone)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel().font(Brand.mono(9))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.5))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day()).font(Brand.mono(9))
            }
        }
        .frame(height: height)
        .accessibilityLabel("Performance Management Chart")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let last = points.last else { return "No data" }
        return "Fitness \(Format.int(last.ctl)), fatigue \(Format.int(last.atl)), form \(Format.signedInt(last.tsb)). Trend over \(points.count) days."
    }
}

/// A small color key for the PMC lines.
struct LegendRow: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: Brand.live, label: "Fitness (CTL)")
            legendItem(color: Brand.warn, label: "Fatigue (ATL)")
            legendItem(color: Brand.info, label: "Form (TSB)")
        }
        .accessibilityHidden(true)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 14, height: 4)
            Text(label).font(Brand.mono(9)).foregroundStyle(Brand.text2)
        }
    }
}
