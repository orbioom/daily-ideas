import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \ChargingSession.date) private var sessions: [ChargingSession]
    @Query private var settingsArr: [AmpSettings]
    private var currencySymbol: String { settingsArr.first?.currencySymbol ?? "$" }

    private var monthly: [MonthlyBucket] {
        ChargingEngine.monthlyBuckets(from: sessions, months: 6)
    }

    private var chargerBreakdown: [(ChargerType, Int)] {
        ChargingEngine.chargerBreakdown(from: sessions)
    }

    private var allStats: ChargingStats {
        ChargingEngine.stats(from: sessions)
    }

    private var costTrend: [(Date, Double)] {
        let sorted = sessions.sorted { $0.date < $1.date }
        var running = 0.0
        return sorted.map { s -> (Date, Double) in
            running += s.kwhAdded > 0 ? s.cost / s.kwhAdded : 0
            return (s.date, s.costPerKWh)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        kwhChart
                        costChart
                        chargerTypeChart
                        efficiencyCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var kwhChart: some View {
        ChartCard(title: "Monthly Energy", subtitle: "kWh charged per month") {
            Chart(monthly) { m in
                BarMark(
                    x: .value("Month", m.id),
                    y: .value("kWh", m.kwhAdded)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel("kWh")
        }
    }

    private var costChart: some View {
        ChartCard(title: "Monthly Cost", subtitle: "\(currencySymbol) spent per month") {
            Chart(monthly) { m in
                BarMark(
                    x: .value("Month", m.id),
                    y: .value("Cost", m.cost)
                )
                .foregroundStyle(Color.purple.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel(currencySymbol)
        }
    }

    private var chargerTypeChart: some View {
        ChartCard(title: "Charger Types", subtitle: "Sessions by charger category") {
            if chargerBreakdown.isEmpty {
                Text("No data yet")
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            } else {
                Chart(chargerBreakdown, id: \.0) { type, count in
                    SectorMark(angle: .value("Count", count))
                        .foregroundStyle(by: .value("Type", type.rawValue))
                        .cornerRadius(4)
                }
                .frame(height: 180)
                VStack(spacing: 4) {
                    ForEach(chargerBreakdown, id: \.0) { type, count in
                        HStack {
                            Label(type.rawValue, systemImage: type.icon)
                                .font(.caption)
                            Spacer()
                            Text("\(count) sessions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var efficiencyCard: some View {
        ChartCard(title: "Charging Efficiency", subtitle: "Average cost per kWh") {
            if sessions.count > 1 {
                Chart(sessions.sorted { $0.date < $1.date }) { s in
                    LineMark(
                        x: .value("Date", s.date),
                        y: .value("Cost/kWh", s.costPerKWh)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 120)
                .chartYAxisLabel("\(currencySymbol)/kWh")
            } else {
                Text("Log more sessions to see trends")
                    .foregroundStyle(.secondary)
                    .frame(height: 60)
            }
            HStack(spacing: 24) {
                summaryItem("Avg Rate", value: String(format: "\(currencySymbol)%.3f/kWh", allStats.avgCostPerKWh))
                summaryItem("CO₂ Saved", value: String(format: "%.0f kg", allStats.co2SavedKg))
                summaryItem("Gas Equiv", value: String(format: "%.0f gal", allStats.gasEquivSaved))
            }
            .padding(.top, 8)
        }
    }

    private func summaryItem(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.title3.bold())
            Text("Log charging sessions to see trends and analytics")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
