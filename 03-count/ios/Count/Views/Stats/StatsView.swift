import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \TrainingRecord.date, order: .reverse) private var records: [TrainingRecord]
    @State private var statsVM = StatsViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if records.isEmpty {
                        EmptyStateView(
                            systemImage: "chart.bar.xaxis",
                            title: "No Stats Yet",
                            subtitle: "Complete some training sessions to see your performance data here."
                        )
                        .padding(.top, 60)
                    } else {
                        overallAccuracyCard
                        summaryStatsRow
                        accuracyChartCard
                        hardestScenariosCard
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
            .onAppear { statsVM.load(from: modelContext) }
            .onChange(of: records.count) { _, _ in statsVM.load(from: modelContext) }
        }
    }

    private var overallAccuracyCard: some View {
        VStack(spacing: 12) {
            Text("Overall Accuracy")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: statsVM.overallAccuracy)
                    .stroke(
                        accuracyColor(statsVM.overallAccuracy),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: statsVM.overallAccuracy)

                VStack(spacing: 2) {
                    Text("\(Int(statsVM.overallAccuracy * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(accuracyColor(statsVM.overallAccuracy))
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summaryStatsRow: some View {
        HStack(spacing: 12) {
            StatTileView(
                value: "\(statsVM.totalAnswered)",
                label: "Total Hands",
                icon: "rectangle.stack.fill",
                color: CountTheme.accent
            )
            StatTileView(
                value: "\(statsVM.totalCorrect)",
                label: "Correct",
                icon: "checkmark.circle.fill",
                color: CountTheme.correctGreen
            )
            StatTileView(
                value: "\(statsVM.currentStreak)",
                label: "Streak",
                icon: "flame.fill",
                color: .orange
            )
        }
    }

    private var accuracyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
                .padding(.horizontal, 4)

            let dailyStats = statsVM.last7DaysStats
            let hasData = dailyStats.contains { $0.count > 0 }

            if hasData {
                Chart(dailyStats) { stat in
                    BarMark(
                        x: .value("Day", stat.date, unit: .day),
                        y: .value("Accuracy", stat.accuracy * 100)
                    )
                    .foregroundStyle(
                        stat.count == 0
                            ? Color.secondary.opacity(0.3)
                            : accuracyColor(stat.accuracy)
                    )
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 180)
            } else {
                Text("Practice more hands to see your daily accuracy trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var hardestScenariosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hardest Scenarios")
                .font(.headline)

            let hardest = statsVM.hardestScenarios

            if hardest.isEmpty {
                Text("Practice at least 3 hands per scenario to see rankings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(hardest) { stat in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.scenario)
                                .font(.system(.subheadline, design: .monospaced).bold())
                            Text("\(stat.attempts) attempts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(stat.accuracy * 100))%")
                                .font(.headline.bold())
                                .foregroundStyle(accuracyColor(stat.accuracy))
                            Text("\(stat.correct)/\(stat.attempts)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)

                    if stat.id != hardest.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func accuracyColor(_ value: Double) -> Color {
        if value >= 0.80 { return CountTheme.correctGreen }
        if value >= 0.60 { return .yellow }
        return CountTheme.wrongRed
    }
}

struct StatTileView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
