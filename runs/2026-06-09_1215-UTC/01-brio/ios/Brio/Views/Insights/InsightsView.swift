import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var weeks = 8

    private var summary: StatsEngine.Summary { StatsEngine.summary(sessions) }
    private var weekSeries: [StatsEngine.WeekPoint] { StatsEngine.minutesByWeek(sessions, weeks: weeks) }
    private var byCategory: [StatsEngine.CategoryPoint] { StatsEngine.byCategory(sessions) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.bar.xaxis",
                                   title: "Nothing to show yet",
                                   message: "Finish a workout and your minutes, streaks, and training mix will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        minutesChart
                        if !byCategory.isEmpty { categoryChart }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(summary.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(summary.longestStreak)", label: "Best streak")
            StatTile(value: Format.duration(summary.totalMinutes * 60), label: "Total time")
            StatTile(value: "\(Int((summary.completionRate * 100).rounded()))%", label: "Completed")
        }
    }

    private var minutesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Minutes per week")
                Spacer()
                Picker("Range", selection: $weeks) {
                    Text("8w").tag(8)
                    Text("12w").tag(12)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Chart(weekSeries) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(); AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: weeks > 8 ? 3 : 2)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of workout minutes per week")
        }
        .glassCard()
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Sessions by category")
            Chart(byCategory) { point in
                BarMark(
                    x: .value("Sessions", point.sessions),
                    y: .value("Category", point.category.label)
                )
                .foregroundStyle(point.category.tint.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(point.sessions)")
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
            }
            .frame(height: CGFloat(byCategory.count) * 38 + 20)
            .chartXAxis {
                AxisMarks { _ in AxisGridLine(); AxisValueLabel() }
            }
            .accessibilityLabel("Bar chart of sessions grouped by category")
        }
        .glassCard()
    }
}
