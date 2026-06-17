import SwiftUI
import Charts

/// Weight trend chart: raw weigh-ins (points) + EMA trend (line) + a goal line.
struct WeightTrendChart: View {
    @Environment(\.colorScheme) private var scheme

    let trend: [TrendPoint]
    let goalWeightKg: Double
    let unit: WeightUnit

    private var values: [Double] {
        trend.flatMap { [$0.rawKg, $0.emaKg] } + [goalWeightKg]
    }

    private var yDomain: ClosedRange<Double> {
        let vals = values.map { unit.fromKg($0) }
        guard let lo = vals.min(), let hi = vals.max() else { return 0...1 }
        let pad = max(0.5, (hi - lo) * 0.12)
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        Chart {
            // Goal reference line.
            RuleMark(y: .value("Goal", unit.fromKg(goalWeightKg)))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(FuelTheme.teal)
                .annotation(position: .top, alignment: .leading) {
                    Text("Goal \(Fmt.weightValue(goalWeightKg, unit: unit)) \(unit.label)")
                        .font(.caption2)
                        .foregroundStyle(FuelTheme.teal)
                }

            // Raw weigh-ins as faint points.
            ForEach(trend) { p in
                PointMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", unit.fromKg(p.rawKg))
                )
                .foregroundStyle(FuelTheme.secondaryText(scheme).opacity(0.5))
                .symbolSize(28)
            }

            // EMA trend line.
            ForEach(trend) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Trend", unit.fromKg(p.emaKg)),
                    series: .value("Series", "ema")
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(FuelTheme.orange)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
        .accessibilityLabel("Weight trend chart")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let first = trend.first, let last = trend.last else { return "No data yet" }
        let change = last.emaKg - first.emaKg
        let dir = change < 0 ? "down" : (change > 0 ? "up" : "level")
        return "Trend \(dir) from \(Fmt.weight(first.emaKg, unit: unit)) to \(Fmt.weight(last.emaKg, unit: unit)), goal \(Fmt.weight(goalWeightKg, unit: unit))"
    }
}
