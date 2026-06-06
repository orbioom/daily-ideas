import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var hives: [Hive]
    @Query private var inspections: [Inspection]
    @AppStorage("massUnit") private var massRaw = MassUnit.kg.rawValue

    private var mass: MassUnit { MassUnit(rawValue: massRaw) ?? .kg }
    private var live: [Hive] { hives.filter { $0.status.isLive } }
    private var healthCounts: [(health: BeeLogic.Health, count: Int)] {
        let all: [BeeLogic.Health] = [.strong, .watch, .risk, .unknown]
        return all.map { h in (health: h, count: hives.filter { BeeLogic.health(for: $0) == h }.count) }
            .filter { $0.count > 0 }
    }
    private var totalHoneyKg: Double { hives.reduce(0) { $0 + $1.totalHoneyKg } }
    private var avgMites: Double {
        let recent = hives.compactMap { $0.latestInspection?.mitesPer300 }
        guard !recent.isEmpty else { return 0 }
        return Double(recent.reduce(0, +)) / Double(recent.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if hives.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No data yet",
                                   message: "Add hives and log inspections to see colony health and trends.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(live.count)", label: "Live colonies", accent: Brand.live)
                                StatTile(value: mass.format(kg: totalHoneyKg), label: "Total honey", accent: Brand.warn)
                            }
                            HStack(spacing: 12) {
                                StatTile(value: "\(inspections.count)", label: "Inspections")
                                StatTile(value: avgMites > 0 ? String(format: "%.1f", avgMites) : "—",
                                         label: "Avg mites/300",
                                         accent: avgMites >= Double(BeeLogic.mitesThresholdPer300) ? Brand.danger : Brand.text)
                            }

                            if !healthCounts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Colony health")
                                    Chart(healthCounts, id: \.health) { item in
                                        BarMark(x: .value("Count", item.count),
                                                y: .value("Health", item.health.rawValue))
                                        .foregroundStyle(item.health.color)
                                        .cornerRadius(4)
                                    }
                                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                                    .frame(height: max(120, CGFloat(healthCounts.count) * 44))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "Queens by year")
                                ForEach(queenYearCounts, id: \.year) { item in
                                    HStack {
                                        QueenDot(year: item.year, size: 16)
                                        Text("\(String(item.year)) · \(BeeLogic.queenColorName(year: item.year))")
                                            .font(.subheadline).foregroundStyle(Brand.text)
                                        Spacer()
                                        Text("\(item.count) hive\(item.count == 1 ? "" : "s")")
                                            .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var queenYearCounts: [(year: Int, count: Int)] {
        Dictionary(grouping: hives.filter { $0.status.isLive }, by: { $0.queenYear })
            .map { (year: $0.key, count: $0.value.count) }
            .sorted { $0.year > $1.year }
    }
}
