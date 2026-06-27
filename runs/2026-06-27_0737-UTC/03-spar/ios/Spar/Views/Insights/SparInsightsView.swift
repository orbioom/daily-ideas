import SwiftUI
import SwiftData
import Charts

struct SparInsightsView: View {
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @Query private var techniques: [Technique]
    @Query private var sparSettings: [SparSettings]

    private var weekly: [WeekBucket] {
        TrainingEngine.weeklyBuckets(from: sessions, count: 8)
    }

    private var typeDistribution: [(SessionType, Int)] {
        TrainingEngine.sessionTypeDistribution(from: sessions)
    }

    private var intensityDistribution: [(String, Int)] {
        let grouped = Dictionary(grouping: sessions, by: { $0.intensity.label })
        return SessionIntensity.allCases.reversed().compactMap { i in
            let count = grouped[i.label]?.count ?? 0
            return count > 0 ? (i.label, count) : nil
        }
    }

    private var masteryBreakdown: [(String, Int)] {
        MasteryLevel.allCases.compactMap { level in
            let count = techniques.filter { $0.mastery == level }.count
            return count > 0 ? (level.label, count) : nil
        }
    }

    private var totalHours: Double {
        Double(sessions.reduce(0) { $0 + $1.durationMinutes }) / 60
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        summaryRow
                        weeklyChart
                        typeChart
                        intensityChart
                        masteryChart
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            insightCard("Hours", value: String(format: "%.0f", totalHours), color: .red)
            insightCard("Sessions", value: "\(sessions.count)", color: .orange)
            insightCard("Techniques", value: "\(techniques.count)", color: .purple)
        }
    }

    private var weeklyChart: some View {
        chartCard("Weekly Training", subtitle: "Minutes per week (last 8 weeks)") {
            Chart(weekly) { b in
                BarMark(x: .value("Week", b.id), y: .value("Min", b.minutes))
                    .foregroundStyle(Color.red.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel("minutes")
        }
    }

    private var typeChart: some View {
        chartCard("Session Types", subtitle: "Distribution of training activities") {
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
                            Label(type.rawValue, systemImage: type.icon).font(.caption)
                            Spacer()
                            Text("\(count)").font(.caption.bold())
                        }
                    }
                }
            }
        }
    }

    private var intensityChart: some View {
        chartCard("Training Intensity", subtitle: "Sessions by intensity level") {
            Chart(intensityDistribution, id: \.0) { label, count in
                BarMark(x: .value("Count", count), y: .value("Intensity", label))
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 120)
        }
    }

    private var masteryChart: some View {
        chartCard("Technique Mastery", subtitle: "Your \(techniques.count) techniques by mastery level") {
            Chart(masteryBreakdown, id: \.0) { label, count in
                BarMark(x: .value("Count", count), y: .value("Mastery", label))
                    .foregroundStyle(Color.purple.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 120)
        }
    }

    private func insightCard(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
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
            Image(systemName: "chart.bar")
                .font(.system(size: 56)).foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.title3.bold())
            Text("Log training sessions to see your progress")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
