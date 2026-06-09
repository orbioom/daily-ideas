import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var prayers: [Prayer]
    @Query private var logs: [ReadingLog]

    private var stats: VesperEngine.PrayerStats { VesperEngine.prayerStats(prayers) }
    private var streak: Int { VesperEngine.currentStreak(prayers, logs) }
    private var monthly: [VesperEngine.MonthActivity] { VesperEngine.monthlyActivity(prayers, logs, months: 6) }
    private var categories: [VesperEngine.CategoryCount] { VesperEngine.categoryBreakdown(prayers) }
    private var longest: [Prayer] { VesperEngine.longestStanding(prayers, limit: 5) }

    private var hasData: Bool { !prayers.isEmpty || !logs.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if !hasData {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No insight yet",
                                   message: "As you add prayers and read devotions, gentle patterns will appear here.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            statsGrid
                            monthlyChart
                            categoryChart
                            longestStandingSection
                            readingsChart
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(stats.active)", label: "Praying now", tint: Brand.info)
                StatTile(value: "\(stats.answered)", label: "Answered", tint: Brand.magic)
            }
            HStack(spacing: 12) {
                StatTile(value: "\(Int((stats.answeredRate * 100).rounded()))%", label: "Answered rate", tint: Brand.magic)
                StatTile(value: "\(streak)", label: "Day streak", tint: Brand.warn)
            }
        }
    }

    // MARK: Prayers added vs answered per month

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Added vs. answered")
            GlassCard {
                if monthly.allSatisfy({ $0.added == 0 && $0.answered == 0 }) {
                    chartEmpty("No prayers in this window yet.")
                } else {
                    Chart {
                        ForEach(monthly) { point in
                            BarMark(
                                x: .value("Month", point.month, unit: .month),
                                y: .value("Added", point.added)
                            )
                            .foregroundStyle(by: .value("Kind", "Added"))
                            .position(by: .value("Kind", "Added"))

                            BarMark(
                                x: .value("Month", point.month, unit: .month),
                                y: .value("Answered", point.answered)
                            )
                            .foregroundStyle(by: .value("Kind", "Answered"))
                            .position(by: .value("Kind", "Answered"))
                        }
                    }
                    .chartForegroundStyleScale(["Added": Brand.info, "Answered": Brand.magic])
                    .chartLegend(position: .bottom, spacing: 8)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.narrow))
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Bar chart of prayers added versus answered per month")
                }
            }
        }
    }

    // MARK: Category distribution

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Where your prayers gather")
            GlassCard {
                if categories.isEmpty {
                    chartEmpty("No active prayers to break down.")
                } else {
                    Chart(categories) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(item.category.tint)
                        .annotation(position: .overlay) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(Brand.mono(11, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Donut chart of active prayers by category")

                    VStack(spacing: 6) {
                        ForEach(categories) { item in
                            HStack(spacing: 8) {
                                Circle().fill(item.category.tint).frame(width: 9, height: 9)
                                    .accessibilityHidden(true)
                                Text(item.category.label)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(item.count)")
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text2)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.category.label): \(item.count)")
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var longestStandingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Longest-standing prayers")
            GlassCard {
                if longest.isEmpty {
                    chartEmpty("No active prayers right now.")
                } else {
                    let maxDays = max(1, longest.map { daysHeld($0) }.max() ?? 1)
                    VStack(spacing: 14) {
                        ForEach(longest) { prayer in
                            let days = daysHeld(prayer)
                            RankBar(title: prayer.title,
                                    detail: "\(days)d",
                                    fraction: Double(days) / Double(maxDays),
                                    tint: prayer.category.tint)
                        }
                    }
                }
            }
        }
    }

    private var readingsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Readings per month")
            GlassCard {
                if monthly.allSatisfy({ $0.readings == 0 }) {
                    chartEmpty("No readings logged yet.")
                } else {
                    Chart(monthly) { point in
                        LineMark(
                            x: .value("Month", point.month, unit: .month),
                            y: .value("Readings", point.readings)
                        )
                        .foregroundStyle(Brand.magic)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Month", point.month, unit: .month),
                            y: .value("Readings", point.readings)
                        )
                        .foregroundStyle(Brand.magic)
                        AreaMark(
                            x: .value("Month", point.month, unit: .month),
                            y: .value("Readings", point.readings)
                        )
                        .foregroundStyle(Brand.magic.opacity(0.15))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.narrow))
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Line chart of devotions read per month")
                }
            }
        }
    }

    private func chartEmpty(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Brand.text3)
            .frame(maxWidth: .infinity, minHeight: 120)
            .multilineTextAlignment(.center)
    }

    private func daysHeld(_ prayer: Prayer) -> Int {
        let cal = Calendar.current
        return max(0, cal.dateComponents([.day], from: cal.startOfDay(for: prayer.createdAt),
                                         to: cal.startOfDay(for: .now)).day ?? 0)
    }
}
