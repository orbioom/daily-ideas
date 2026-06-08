import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Fast.start, order: .reverse) private var fasts: [Fast]

    private var stats: FastStats { FastStats.make(from: fasts) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if stats.completed == 0 {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No insights yet",
                                   message: "Finish a few fasts and your streak, averages, and weekly chart appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            streakCard
                            statsGrid
                            weeklyChart
                            completionCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var streakCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Brand.inkGradient).frame(width: 64, height: 64)
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(stats.currentStreakDays)")
                            .font(Brand.mono(36, weight: .semibold))
                            .foregroundStyle(Brand.text)
                        Text("day\(stats.currentStreakDays == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundStyle(Brand.text2)
                    }
                    Text("current streak")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var statsGrid: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    StatTile(value: "\(Format.hours(stats.averageHours))h", label: "Average")
                    StatTile(value: "\(Format.hours(stats.longestHours))h", label: "Longest", tint: Color(hex: 0xB5552F))
                }
                Divider().overlay(Brand.hairline)
                HStack(spacing: 16) {
                    StatTile(value: "\(stats.completed)", label: "Fasts logged")
                    StatTile(value: "\(Int(stats.totalHours))h", label: "Total fasted")
                }
            }
        }
    }

    private var weeklyChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "LAST 7 DAYS")
                Chart(stats.last7) { bar in
                    BarMark(
                        x: .value("Day", bar.date, unit: .day),
                        y: .value("Hours", bar.hours)
                    )
                    .foregroundStyle(bar.hitGoal ? Brand.live : Color(hex: 0xB5552F))
                    .cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel { if let h = value.as(Double.self) { Text("\(Int(h))h") } }
                        AxisGridLine().foregroundStyle(Brand.hairline)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 170)
                HStack(spacing: 14) {
                    legendDot(Brand.live, "Goal hit")
                    legendDot(Color(hex: 0xB5552F), "Under goal")
                }
                .font(.caption)
                .foregroundStyle(Brand.text2)
            }
        }
    }

    private func legendDot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 8, height: 8)
            Text(t)
        }
        .accessibilityElement(children: .combine)
    }

    private var completionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "GOAL COMPLETION")
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(stats.completionRate * 100))%")
                        .font(Brand.mono(34, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text("of fasts reached goal")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                ProgressView(value: stats.completionRate)
                    .tint(Brand.live)
                Text("\(stats.goalsHit) of \(stats.completed) completed fasts hit their target length.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }
        }
    }
}
