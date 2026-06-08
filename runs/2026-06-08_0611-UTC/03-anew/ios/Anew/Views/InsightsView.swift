import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Quit.order) private var allQuits: [Quit]
    @Query private var allCheckIns: [CheckIn]
    @Query private var allRelapses: [Relapse]

    @AppStorage("anew.currency")     private var currencySymbol: String = "$"
    @AppStorage("anew.showInactive") private var showInactive: Bool = false

    private var quits: [Quit] {
        showInactive ? allQuits : allQuits.filter(\.active)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if quits.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No data yet",
                        message: "Add a quit on the Dashboard to see insights here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            totalCleanDaysCard
                            moneySavedCard
                            longestStreaksCard
                            moodTrendCard
                            relapseHistoryCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Total clean days per quit

    private var totalCleanDaysCard: some View {
        let data = quits.map { quit in
            (name: quit.name, days: SobrietyEngine.cleanDays(start: quit.startDate, now: Date()), color: Color(hex: quit.colorHex))
        }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Total Clean Days")

                Chart {
                    ForEach(data, id: \.name) { item in
                        BarMark(
                            x: .value("Days", item.days),
                            y: .value("Quit", item.name)
                        )
                        .foregroundStyle(item.color)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("\(item.days)d")
                                .font(Brand.mono(11, weight: .medium))
                                .foregroundStyle(Brand.text2)
                        }
                        .accessibilityLabel("\(item.name): \(item.days) days")
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(Brand.text3)
                        AxisGridLine()
                            .foregroundStyle(Brand.hairline)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(Brand.text2)
                    }
                }
                .frame(height: CGFloat(max(100, data.count * 48)))
            }
        }
    }

    // MARK: - Money saved + projection

    private var moneySavedCard: some View {
        let now = Date()
        // Current savings per quit
        let savings = quits.filter { $0.costPerUnit > 0 && $0.unitsPerDay > 0 }
            .map { quit -> (name: String, saved: Double, color: Color) in
                (quit.name, SobrietyEngine.moneySaved(quit: quit, now: now), Color(hex: quit.colorHex))
            }

        // Cumulative projection line over next 365 days (all quits combined)
        let totalPerDay = quits.reduce(0.0) { $0 + $1.unitsPerDay * $1.costPerUnit }
        let projectionPoints: [ProjectionPoint] = stride(from: 0, through: 365, by: 30).map { day in
            let alreadySaved = quits.reduce(0.0) {
                $0 + SobrietyEngine.moneySaved(quit: $1, now: now)
            }
            return ProjectionPoint(day: day, value: alreadySaved + totalPerDay * Double(day))
        }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Money Saved")

                if savings.isEmpty {
                    Text("Add cost tracking in your quit settings to see savings here.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                } else {
                    Chart {
                        ForEach(savings, id: \.name) { item in
                            BarMark(
                                x: .value("Quit", item.name),
                                y: .value("Saved", item.saved)
                            )
                            .foregroundStyle(item.color)
                            .accessibilityLabel("\(item.name): \(Format.currency(item.saved, symbol: currencySymbol)) saved")
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let d = value.as(Double.self) {
                                AxisValueLabel { Text(Format.currency(d, symbol: currencySymbol)).font(.caption) }
                            }
                            AxisGridLine().foregroundStyle(Brand.hairline)
                        }
                    }
                    .frame(height: 180)

                    if !projectionPoints.isEmpty && totalPerDay > 0 {
                        Divider()
                            .accessibilityHidden(true)
                        Text("Projected savings over the next year")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)

                        Chart {
                            ForEach(projectionPoints) { point in
                                LineMark(
                                    x: .value("Day", point.day),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(Brand.magic)
                                .interpolationMethod(.catmullRom)
                                .accessibilityLabel("Day \(point.day): \(Format.currency(point.value, symbol: currencySymbol))")
                            }
                        }
                        .chartXAxisLabel("Days from now")
                        .chartYAxis {
                            AxisMarks { value in
                                if let d = value.as(Double.self) {
                                    AxisValueLabel { Text(Format.currency(d, symbol: currencySymbol)).font(.caption2) }
                                }
                                AxisGridLine().foregroundStyle(Brand.hairline)
                            }
                        }
                        .frame(height: 140)
                    }
                }
            }
        }
    }

    // MARK: - Longest streaks

    private var longestStreaksCard: some View {
        let now = Date()
        let data = quits.map { quit -> (name: String, streak: Int, color: Color) in
            (quit.name, SobrietyEngine.longestStreak(quit: quit, now: now), Color(hex: quit.colorHex))
        }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Longest Streaks")

                Chart {
                    ForEach(data, id: \.name) { item in
                        BarMark(
                            x: .value("Streak", item.streak),
                            y: .value("Quit", item.name)
                        )
                        .foregroundStyle(item.color.gradient)
                        .annotation(position: .trailing) {
                            Text("\(item.streak)d")
                                .font(Brand.mono(11, weight: .medium))
                                .foregroundStyle(Brand.text2)
                        }
                        .accessibilityLabel("\(item.name): longest streak \(item.streak) days")
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(Brand.text3)
                        AxisGridLine().foregroundStyle(Brand.hairline)
                    }
                }
                .frame(height: CGFloat(max(100, data.count * 48)))
            }
        }
    }

    // MARK: - Mood trend

    private var moodTrendCard: some View {
        // Last 30 days of check-ins per quit, averaged per day
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let recent = allCheckIns.filter { $0.date >= thirtyDaysAgo }

        // Group by day, average mood
        var dayMoods: [Date: [Int]] = [:]
        for ci in recent {
            let day = Calendar.current.startOfDay(for: ci.date)
            dayMoods[day, default: []].append(ci.mood)
        }

        let moodPoints: [MoodPoint] = dayMoods.map { day, moods in
            let avg = moods.isEmpty ? 3.0 : Double(moods.reduce(0, +)) / Double(moods.count)
            return MoodPoint(date: day, avgMood: avg)
        }.sorted { $0.date < $1.date }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Mood Trend (30 days)")

                if moodPoints.isEmpty {
                    Text("No check-ins in the past 30 days. Log moods in your journal to see trends.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                } else {
                    Chart {
                        ForEach(moodPoints) { point in
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Mood", point.avgMood)
                            )
                            .foregroundStyle(Brand.info.opacity(0.25))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Mood", point.avgMood)
                            )
                            .foregroundStyle(Brand.info)
                            .interpolationMethod(.catmullRom)
                            .symbol(.circle)
                            .accessibilityLabel("\(Format.shortDate(point.date)): mood \(String(format: "%.1f", point.avgMood))")
                        }
                    }
                    .chartYScale(domain: 1...5)
                    .chartYAxis {
                        AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                            if let i = value.as(Int.self) {
                                AxisValueLabel {
                                    Text(Format.moodEmoji(i))
                                }
                            }
                            AxisGridLine().foregroundStyle(Brand.hairline)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(Brand.text3)
                            AxisGridLine().foregroundStyle(Brand.hairline)
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    // MARK: - Relapse history

    private var relapseHistoryCard: some View {
        let relapses = allRelapses.sorted { $0.date > $1.date }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Relapse History")
                    Spacer()
                    Text("\(relapses.count) total")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                if relapses.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Brand.live)
                            .accessibilityHidden(true)
                        Text("No relapses recorded.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                } else {
                    ForEach(relapses.prefix(8)) { relapse in
                        RelapseHistoryRow(relapse: relapse)
                        if relapse.id != relapses.prefix(8).last?.id {
                            Divider()
                                .padding(.vertical, 2)
                                .accessibilityHidden(true)
                        }
                    }

                    if relapses.count > 8 {
                        Text("+ \(relapses.count - 8) more")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Relapse history row

private struct RelapseHistoryRow: View {
    let relapse: Relapse

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.counterclockwise")
                .font(.caption)
                .foregroundStyle(Brand.warn)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(relapse.quit?.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text("After \(relapse.previousCleanDays) clean day\(relapse.previousCleanDays == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                if !relapse.note.isEmpty {
                    Text(relapse.note)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(Format.shortDate(relapse.date))
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Relapse for \(relapse.quit?.name ?? "unknown") on \(Format.shortDate(relapse.date)) after \(relapse.previousCleanDays) days")
    }
}

// MARK: - Chart data models

private struct ProjectionPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
}

private struct MoodPoint: Identifiable {
    let id = UUID()
    let date: Date
    let avgMood: Double
}
