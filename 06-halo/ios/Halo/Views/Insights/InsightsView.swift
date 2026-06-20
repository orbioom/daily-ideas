import SwiftUI
import Charts
import SwiftData

struct InsightsView: View {
    @Query(sort: \HaloSession.date, order: .reverse) private var sessions: [HaloSession]

    private var last14Days: [DayCount] {
        let calendar = Calendar.current
        return (0..<14).reversed().map { offset -> DayCount in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let count = sessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count
            return DayCount(date: date, count: count)
        }
    }

    private var categoryDistribution: [CategoryCount] {
        let counts = Dictionary(grouping: sessions, by: \.category).mapValues(\.count)
        return BrainwaveCategory.allCases.compactMap { cat in
            guard let count = counts[cat.rawValue], count > 0 else { return nil }
            return CategoryCount(category: cat, count: count)
        }
    }

    private var avgMoodBefore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.moodBefore }) / Double(sessions.count)
    }

    private var avgMoodAfter: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.moodAfter }) / Double(sessions.count)
    }

    private var minutesByCategory: [CategoryMinutes] {
        let grouped = Dictionary(grouping: sessions, by: \.category)
        return BrainwaveCategory.allCases.compactMap { cat in
            guard let catSessions = grouped[cat.rawValue] else { return nil }
            let totalMinutes = catSessions.reduce(0.0) { $0 + $1.durationSeconds } / 60.0
            guard totalMinutes > 0 else { return nil }
            return CategoryMinutes(category: cat, minutes: totalMinutes)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Data Yet",
                        message: "Complete sessions to see your brainwave insights here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: HaloTheme.spacingL) {
                            sessionsBarChart
                            categoryDonut
                            moodComparisonChart
                            timeByCategory
                        }
                        .padding(.horizontal, HaloTheme.spacingM)
                        .padding(.vertical, HaloTheme.spacingM)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Insights")
            .toolbarBackground(HaloTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Charts

    private var sessionsBarChart: some View {
        chartCard(title: "Sessions — Last 14 Days", icon: "calendar") {
            Chart(last14Days) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Sessions", day.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [HaloTheme.primary, HaloTheme.accent],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                        .foregroundStyle(HaloTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(HaloTheme.textTertiary)
                }
            }
            .frame(height: 160)
        }
    }

    private var categoryDonut: some View {
        chartCard(title: "Category Distribution", icon: "chart.pie.fill") {
            if categoryDistribution.isEmpty {
                Text("No data")
                    .foregroundColor(HaloTheme.textTertiary)
                    .frame(height: 180)
            } else {
                Chart(categoryDistribution) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(4)
                }
                .frame(height: 180)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(categoryDistribution) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 8, height: 8)
                            Text("\(item.category.rawValue) (\(item.count))")
                                .font(HaloTheme.captionFont)
                                .foregroundColor(HaloTheme.textSecondary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var moodComparisonChart: some View {
        chartCard(title: "Average Mood Shift", icon: "heart.fill") {
            HStack(spacing: HaloTheme.spacingXL) {
                moodGauge(label: "Before", value: avgMoodBefore, color: HaloTheme.textSecondary)
                Image(systemName: "arrow.right")
                    .foregroundColor(HaloTheme.textTertiary)
                moodGauge(
                    label: "After",
                    value: avgMoodAfter,
                    color: avgMoodAfter >= avgMoodBefore ? .green : .red
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HaloTheme.spacingS)
        }
    }

    private func moodGauge(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(HaloTheme.captionFont)
                .foregroundColor(HaloTheme.textTertiary)
            Text(moodEmoji(for: value))
                .font(.system(size: 24))
        }
    }

    private func moodEmoji(for value: Double) -> String {
        switch value {
        case ..<1.5: return "😞"
        case ..<2.5: return "😕"
        case ..<3.5: return "😐"
        case ..<4.5: return "🙂"
        default: return "😄"
        }
    }

    private var timeByCategory: some View {
        chartCard(title: "Time by Category (min)", icon: "clock.fill") {
            Chart(minutesByCategory) { item in
                BarMark(
                    x: .value("Minutes", item.minutes),
                    y: .value("Category", item.category.rawValue)
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(HaloTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(HaloTheme.textSecondary)
                }
            }
            .frame(height: CGFloat(minutesByCategory.count) * 44 + 20)
        }
    }

    // MARK: - Helper

    private func chartCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
            Label(title, systemImage: icon)
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            content()
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Data models for Charts

struct DayCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct CategoryCount: Identifiable {
    var id: String { category.rawValue }
    let category: BrainwaveCategory
    let count: Int
}

struct CategoryMinutes: Identifiable {
    var id: String { category.rawValue }
    let category: BrainwaveCategory
    let minutes: Double
}
