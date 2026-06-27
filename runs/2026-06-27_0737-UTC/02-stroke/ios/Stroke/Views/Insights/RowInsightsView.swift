import SwiftUI
import SwiftData
import Charts

struct RowInsightsView: View {
    @Query(sort: \RowWorkout.date) private var workouts: [RowWorkout]
    @Query private var settings: [StrokeSettings]

    private var displayWatts: Bool { settings.first?.displayWatts ?? false }

    private var weekly: [WeeklyBucket] {
        RowEngine.weeklyBuckets(from: workouts, count: 8)
    }

    private var splitTrend: [(Date, Double)] {
        workouts.suffix(20).compactMap { w in
            guard w.avgSplitSeconds > 0 else { return nil }
            return (w.date, Double(w.avgSplitSeconds))
        }
    }

    private var typeDistribution: [(WorkoutType, Int)] {
        let grouped = Dictionary(grouping: workouts, by: { $0.workoutType })
        return WorkoutType.allCases.compactMap { t in
            let count = grouped[t]?.count ?? 0
            return count > 0 ? (t, count) : nil
        }.sorted { $0.1 > $1.1 }
    }

    private var totalKm: Double { Double(workouts.reduce(0) { $0 + $1.distanceM }) / 1000 }
    private var avgSplit: Int {
        let valid = workouts.filter { $0.avgSplitSeconds > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.avgSplitSeconds } / valid.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if workouts.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        summaryCards
                        weeklyChart
                        splitChart
                        typeChart
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            insightCard("Total km", value: String(format: "%.1f", totalKm), color: .teal)
            insightCard("Sessions", value: "\(workouts.count)", color: .orange)
            insightCard("Avg Split", value: RowEngine.formatSplit(avgSplit), color: .cyan)
        }
    }

    private var weeklyChart: some View {
        chartCard("Weekly Distance", subtitle: "Meters per week (last 8 weeks)") {
            Chart(weekly) { b in
                BarMark(x: .value("Week", b.id), y: .value("m", b.distanceM))
                    .foregroundStyle(Color.teal.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel("meters")
        }
    }

    private var splitChart: some View {
        chartCard("Split Trend", subtitle: "500m split over last 20 sessions (lower = faster)") {
            if splitTrend.count < 2 {
                Text("Log more sessions to see trends")
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart(splitTrend, id: \.0) { date, sec in
                    LineMark(x: .value("Date", date), y: .value("Split", sec))
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", date), y: .value("Split", sec))
                        .foregroundStyle(Color.orange.opacity(0.15))
                }
                .frame(height: 140)
                .chartYAxis {
                    AxisMarks(values: .automatic) { val in
                        AxisValueLabel {
                            if let sec = val.as(Double.self) {
                                Text(RowEngine.formatSplit(Int(sec)))
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
        }
    }

    private var typeChart: some View {
        chartCard("Workout Types", subtitle: "Session distribution by type") {
            if typeDistribution.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                Chart(typeDistribution, id: \.0) { type, count in
                    SectorMark(angle: .value("Count", count))
                        .foregroundStyle(by: .value("Type", type.rawValue))
                        .cornerRadius(4)
                }
                .frame(height: 160)
                VStack(spacing: 4) {
                    ForEach(typeDistribution, id: \.0) { type, count in
                        HStack {
                            Label(type.rawValue, systemImage: type.icon)
                                .font(.caption)
                            Spacer()
                            Text("\(count)")
                                .font(.caption.bold())
                        }
                    }
                }
            }
        }
    }

    private func insightCard(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func chartCard<C: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> C) -> some View {
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56)).foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.title3.bold())
            Text("Log rowing sessions to see weekly trends and split progression")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
