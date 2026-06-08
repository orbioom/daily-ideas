import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var allEntries: [HabitEntry]

    @State private var calendar = Calendar.current

    private var activeHabits: [Habit] {
        habits.filter { !$0.archived }
    }

    private var hasData: Bool {
        !allEntries.isEmpty && !activeHabits.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if !hasData {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Data Yet",
                        message: "Complete some habits to see your trends and insights here."
                    )
                    .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            summaryCards
                            weeklyCompletionChart
                            streakLeaderboard
                            contributionSection
                        }
                        .padding(16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        let today = calendar.startOfDay(for: .now)
        let totalCompletions = activeHabits.reduce(0) {
            $0 + StreakEngine.totalCompletions($1, entries: allEntries, calendar: calendar)
        }
        let best = activeHabits.map {
            StreakEngine.longestStreak($0, entries: allEntries, calendar: calendar)
        }.max() ?? 0
        let rate7 = overallRate(lastNDays: 7)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCell(label: "Total Completions", value: "\(totalCompletions)", icon: "checkmark.seal.fill", color: Brand.live)
            summaryCell(label: "Best Streak", value: Format.streakText(best), icon: "trophy.fill", color: Color(hex: 0xE0B86A))
            summaryCell(label: "7-Day Rate", value: Format.percent(rate7), icon: "chart.pie.fill", color: Brand.info)
            summaryCell(label: "Active Habits", value: "\(activeHabits.count)", icon: "list.bullet.circle.fill", color: Brand.magic)
        }
    }

    private func summaryCell(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Eyebrow(text: label)
            }
            Text(value)
                .font(Brand.mono(22, weight: .bold))
                .foregroundStyle(Brand.text)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Weekly completion chart

    private var weeklyCompletionChart: some View {
        let data = weeklyCompletionData()
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "8-Week Completion Rate")

            if data.isEmpty {
                Text("Not enough data for chart.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            } else {
                Chart {
                    ForEach(data) { point in
                        BarMark(
                            x: .value("Week", point.label),
                            y: .value("Rate", point.rate * 100)
                        )
                        .foregroundStyle(Brand.live.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.caption2)
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Brand.hairline)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Bar chart showing weekly completion rates over the past 8 weeks")
            }
        }
        .glassCard()
    }

    // MARK: - Streak leaderboard

    private var streakLeaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Current Streaks")

            let ranked = activeHabits
                .map { ($0, StreakEngine.currentStreak($0, entries: allEntries, asOf: calendar.startOfDay(for: .now), calendar: calendar)) }
                .filter { $0.1 > 0 }
                .sorted { $0.1 > $1.1 }
                .prefix(6)

            if ranked.isEmpty {
                Text("No active streaks. Complete habits to build momentum!")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(Array(ranked.enumerated()), id: \.offset) { item in
                    let idx = item.offset
                    let (habit, streak) = item.element
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(Brand.mono(14, weight: .bold))
                            .foregroundStyle(Brand.text3)
                            .frame(width: 20)

                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.colorHex).opacity(0.18))
                                .frame(width: 32, height: 32)
                            Image(systemName: habit.symbol)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: habit.colorHex))
                                .accessibilityHidden(true)
                        }

                        Text(habit.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(Brand.warn)
                                .accessibilityHidden(true)
                            Text(habit.scheduleType == .timesPerWeek
                                 ? Format.weeksStreakText(streak)
                                 : Format.streakText(streak))
                                .font(Brand.mono(13, weight: .semibold))
                                .foregroundStyle(Brand.warn)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(idx + 1). \(habit.name): \(streak) streak")

                    if idx < ranked.count - 1 {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Contribution heatmap

    private var contributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "12-Week Overview")

            ContributionHeatmap(
                weeks: buildOverallHeatmap(),
                color: Brand.live,
                cellSize: 13,
                spacing: 4
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Spacer()
                HStack(spacing: 4) {
                    HeatmapCell(intensity: 0.0, color: Brand.live, size: 10)
                    Text("None")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
                HStack(spacing: 4) {
                    HeatmapCell(intensity: 0.5, color: Brand.live, size: 10)
                    Text("Partial")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
                HStack(spacing: 4) {
                    HeatmapCell(intensity: 1.0, color: Brand.live, size: 10)
                    Text("All done")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
        .accessibilityLabel("12-week contribution heatmap showing overall habit completion")
    }

    // MARK: - Data helpers

    private struct WeekPoint: Identifiable {
        let id = UUID()
        let label: String
        let rate: Double
    }

    private func weeklyCompletionData() -> [WeekPoint] {
        let today = calendar.startOfDay(for: .now)
        var points: [WeekPoint] = []
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: StreakEngine.startOfWeek(for: today, calendar: calendar)) else { continue }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }
            let rate = overallRate(from: weekStart, through: min(weekEnd, today))
            let label = Format.dayOfMonth.string(from: weekStart) + "/" + Format.dayOfMonth.string(from: weekEnd)
            points.append(WeekPoint(label: label, rate: rate))
        }
        return points
    }

    private func overallRate(from start: Date, through end: Date) -> Double {
        guard !activeHabits.isEmpty else { return 0 }
        var scheduled = 0
        var completed = 0
        var cursor = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        while cursor <= endDay {
            for habit in activeHabits {
                if StreakEngine.isScheduled(habit, on: cursor, calendar: calendar) {
                    scheduled += 1
                    if StreakEngine.isComplete(habit, on: cursor, entries: allEntries, calendar: calendar) {
                        completed += 1
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }

    private func overallRate(lastNDays n: Int) -> Double {
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -(n - 1), to: today) else { return 0 }
        return overallRate(from: start, through: today)
    }

    private func buildOverallHeatmap() -> [[Double]] {
        let today = calendar.startOfDay(for: .now)
        let numWeeks = 12
        var result: [[Double]] = []

        for weekOffset in (0..<numWeeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: StreakEngine.startOfWeek(for: today, calendar: calendar)) else {
                result.append(Array(repeating: 0.0, count: 7))
                continue
            }
            var row: [Double] = []
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    row.append(0)
                    continue
                }
                if day > today {
                    row.append(0)
                    continue
                }
                let scheduled = activeHabits.filter {
                    StreakEngine.isScheduled($0, on: day, calendar: calendar)
                }
                if scheduled.isEmpty {
                    row.append(0)
                    continue
                }
                let done = scheduled.filter {
                    StreakEngine.isComplete($0, on: day, entries: allEntries, calendar: calendar)
                }.count
                row.append(Double(done) / Double(scheduled.count))
            }
            result.append(row)
        }
        return result
    }
}
