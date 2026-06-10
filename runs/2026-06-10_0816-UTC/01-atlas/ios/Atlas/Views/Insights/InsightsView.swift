import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("weeklyGoal") private var weeklyGoal = 3
    @State private var stats: TrainingStats?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let stats {
                    if stats.sessionCount == 0 {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "Nothing to chart yet",
                            message: "Finish your first workout and Atlas starts tracking volume, balance, and consistency."
                        )
                    } else {
                        content(stats)
                    }
                } else {
                    ProgressView("Crunching your training…")
                        .tint(Brand.text2)
                        .foregroundStyle(Brand.text2)
                }
            }
            .navigationTitle("Insights")
            .task(id: statsKey) {
                stats = StatsEngine.compute(sessions: sessions, weeklyGoal: weeklyGoal)
            }
        }
    }

    /// Recompute when data or the goal changes.
    private var statsKey: String { "\(sessions.count)-\(weeklyGoal)-\(sessions.first?.date.timeIntervalSince1970 ?? 0)" }

    private func content(_ stats: TrainingStats) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    bigStat("\(stats.thisWeekSessions)/\(weeklyGoal)", "this week")
                    bigStat("\(stats.weekStreak)", stats.weekStreak == 1 ? "week streak" : "week streak")
                    bigStat("\(stats.sessionCount)", "workouts")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Volume per week")
                    Chart(stats.weeklyTonnage) { p in
                        BarMark(
                            x: .value("Week", p.weekStart, unit: .weekOfYear),
                            y: .value("Volume", unit.display(fromKg: p.value))
                        )
                        .foregroundStyle(Brand.inkGradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 160)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                    Text("Total weight moved (\(unit.suffix)) across all done sets.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .glassCard()
                .accessibilityLabel("Bar chart of training volume per week")

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Sets by muscle · last 4 weeks")
                    if stats.setsPerMuscle.isEmpty {
                        Text("No sets logged in the last four weeks.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        Chart(stats.setsPerMuscle) { row in
                            BarMark(
                                x: .value("Sets", row.sets),
                                y: .value("Muscle", row.muscle.label)
                            )
                            .foregroundStyle(Brand.live.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: CGFloat(max(120, stats.setsPerMuscle.count * 34)))
                        Text("Spot neglected muscle groups at a glance.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .glassCard()
                .accessibilityLabel("Bar chart of sets per muscle group over the last four weeks")

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Sessions per week")
                    Chart {
                        ForEach(stats.weeklySessions) { p in
                            BarMark(
                                x: .value("Week", p.weekStart, unit: .weekOfYear),
                                y: .value("Sessions", p.value)
                            )
                            .foregroundStyle((p.value >= Double(weeklyGoal) ? Brand.live : Brand.text3).gradient)
                            .cornerRadius(4)
                        }
                        RuleMark(y: .value("Goal", Double(weeklyGoal)))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(height: 140)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                    Text("Green weeks hit your goal of \(weeklyGoal) sessions.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .glassCard()
                .accessibilityLabel("Bar chart of sessions per week against your goal")

                HStack(spacing: 14) {
                    bigStat(unit.format(kg: stats.totalTonnageKg), "lifetime volume")
                    bigStat(Duration.friendly(stats.avgDurationSeconds), "avg session")
                }
            }
            .padding(16)
        }
    }

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(18, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
