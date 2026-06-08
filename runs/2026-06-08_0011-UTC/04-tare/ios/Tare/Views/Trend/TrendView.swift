import SwiftUI
import SwiftData
import Charts

struct TrendView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("tare.goalKg") private var goalKg = 0.0
    @AppStorage("tare.smoothing") private var smoothing = 0.1
    @AppStorage("tare.range") private var rangeDays = 90

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var engine: TrendEngine { TrendEngine.build(entries: entries, alpha: smoothing) }

    private var visible: [TrendEngine.Point] {
        guard rangeDays > 0 else { return engine.points }
        let cutoff = Calendar.current.date(byAdding: .day, value: -rangeDays, to: .now) ?? .now
        return engine.points.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.count < 2 {
                    EmptyStateView(icon: "chart.line.downtrend.xyaxis", title: "Not enough data",
                                   message: "Log at least two weigh-ins to see your trend chart.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            rangePicker
                            chartCard
                            legend
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Trend")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $rangeDays) {
            Text("30d").tag(30); Text("90d").tag(90); Text("1y").tag(365); Text("All").tag(0)
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        let pts = visible
        let goalVal = goalKg > 0 ? Units.value(goalKg, unit: unit) : nil
        return GlassCard {
            Chart {
                ForEach(pts) { p in
                    PointMark(x: .value("Date", p.date),
                              y: .value("Weight", Units.value(p.raw, unit: unit)))
                        .foregroundStyle(Brand.text3.opacity(0.5))
                        .symbolSize(18)
                }
                ForEach(pts) { p in
                    LineMark(x: .value("Date", p.date),
                             y: .value("Trend", Units.value(p.trend, unit: unit)),
                             series: .value("s", "trend"))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Brand.info)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                }
                if let goalVal {
                    RuleMark(y: .value("Goal", goalVal))
                        .foregroundStyle(Brand.magic.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal").font(.caption2).foregroundStyle(Brand.magic)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Brand.hairline)
                    AxisValueLabel()
                }
            }
            .frame(height: 280)
        }
    }

    private var legend: some View {
        GlassCard {
            HStack(spacing: 20) {
                legendItem(Brand.text3.opacity(0.6), "Daily weigh-in", filled: true)
                legendItem(Brand.info, "Smoothed trend", filled: false)
                if goalKg > 0 { legendItem(Brand.magic, "Goal", filled: false) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func legendItem(_ c: Color, _ t: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            if filled { Circle().fill(c).frame(width: 8, height: 8) }
            else { Capsule().fill(c).frame(width: 16, height: 3) }
            Text(t).font(.caption).foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
    }
}
