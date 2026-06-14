import SwiftUI
import Charts

/// A point on a balance-over-time series, downsampled for smooth rendering.
struct BalancePoint: Identifiable, Hashable {
    let id = UUID()
    let month: Int
    let date: Date
    let balance: Double
    let series: String
}

/// Balance over time: baseline (no extra) vs with-extra schedule.
struct BalanceLineChart: View {
    let baseline: [AmortRow]
    let withExtra: [AmortRow]
    let symbol: String
    var showBaseline: Bool = true

    private var points: [BalancePoint] {
        var out: [BalancePoint] = []
        if showBaseline {
            out.append(contentsOf: downsample(baseline, series: "Baseline"))
        }
        out.append(contentsOf: downsample(withExtra, series: "With extra"))
        return out
    }

    /// Keep charts smooth: cap to ~120 points by striding.
    private func downsample(_ rows: [AmortRow], series: String) -> [BalancePoint] {
        guard !rows.isEmpty else { return [] }
        let maxPoints = 120
        let stride = max(1, rows.count / maxPoints)
        var out: [BalancePoint] = []
        var i = 0
        while i < rows.count {
            let r = rows[i]
            out.append(BalancePoint(month: r.month, date: r.date, balance: r.balance, series: series))
            i += stride
        }
        // Always include the final point so the line reaches zero.
        if let last = rows.last, out.last?.month != last.month {
            out.append(BalancePoint(month: last.month, date: last.date, balance: last.balance, series: series))
        }
        return out
    }

    var body: some View {
        Chart(points) { p in
            LineMark(
                x: .value("Month", p.month),
                y: .value("Balance", p.balance)
            )
            .foregroundStyle(by: .value("Plan", p.series))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: p.series == "Baseline" ? 1.5 : 2.5,
                                   dash: p.series == "Baseline" ? [4, 4] : []))
        }
        .chartForegroundStyleScale([
            "With extra": Theme.accent,
            "Baseline": Theme.baselineTint
        ])
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(compact(v))
                            .font(Theme.rounded(10))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel {
                    if let m = value.as(Int.self) {
                        Text("\(m / 12)y")
                            .font(Theme.rounded(10))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance over time")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let extraMonths = withExtra.count
        let baseMonths = baseline.count
        if showBaseline && baseMonths > extraMonths {
            return "With extra payments the balance reaches zero in \(extraMonths) months, versus \(baseMonths) months on the baseline plan."
        }
        return "The balance reaches zero in \(extraMonths) months."
    }

    private func compact(_ v: Double) -> String {
        let symbolPrefix = symbol
        if v >= 1_000_000 { return "\(symbolPrefix)\(String(format: "%.1f", v / 1_000_000))M" }
        if v >= 1_000 { return "\(symbolPrefix)\(Int(v / 1_000))k" }
        return "\(symbolPrefix)\(Int(v))"
    }
}
