import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]

    private var trend: [DayLog] { Array(logs.prefix(30)).sorted { $0.day < $1.day } }
    private var weekday: [WeekdayAvg] { StepEngine.byWeekday(logs: logs) }

    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if logs.count < 2 {
                    EmptyStateView(symbol: "chart.line.uptrend.xyaxis",
                                   title: "Insights build over time",
                                   message: "After a couple of days of walking, you'll see your trends, weekly rhythm and records here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            trendCard
                            rhythmCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(symbol: "sum", value: Fmt.steps(StepEngine.totalSteps(logs: logs)), label: "Total steps")
            StatTile(symbol: "chart.bar.fill", value: Fmt.steps(StepEngine.average(logs: logs)), label: "Daily average")
            StatTile(symbol: "trophy.fill", value: Fmt.steps(StepEngine.bestDay(logs: logs)?.steps ?? 0), label: "Best day", tint: Theme.warm)
            StatTile(symbol: "flame.fill", value: "\(StepEngine.longestStreak(logs: logs))", label: "Longest streak", tint: Theme.warm)
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "Last \(trend.count) days")
            Chart(trend) { log in
                AreaMark(x: .value("Day", log.day), y: .value("Steps", log.steps))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Day", log.day), y: .value("Steps", log.steps))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.accent)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Trend of daily steps over the last \(trend.count) days")
        }
        .treadCard()
    }

    private var rhythmCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "Your weekly rhythm")
            Text("Average steps by day of week")
                .font(.caption).foregroundStyle(Theme.textSecondary)
            Chart(weekday) { item in
                BarMark(
                    x: .value("Weekday", weekdaySymbols[(item.weekday - 1) % 7]),
                    y: .value("Average", item.avg)
                )
                .foregroundStyle(Theme.ringGradient)
                .cornerRadius(6)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Average steps for each weekday")
        }
        .treadCard()
    }
}
