import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @AppStorage("cradle.activeBaby") private var activeBabyID = ""
    @AppStorage("cradle.unit") private var unitRaw = "ml"

    @Query(sort: \Baby.order) private var babies: [Baby]
    @State private var rangeDays: Int = 7

    private var activeBaby: Baby? {
        babies.first(where: { $0.id.uuidString == activeBabyID }) ?? babies.first
    }

    private var events: [CareEvent] {
        activeBaby?.events ?? []
    }

    private var dayData: [CradleEngine.DayData] {
        CradleEngine.perDayData(events: events, lastNDays: rangeDays)
    }

    private var averages: CradleEngine.Averages {
        CradleEngine.averages(events: events, lastNDays: rangeDays)
    }

    private var avgFeedInterval: Double? {
        CradleEngine.averageFeedInterval(events: events, lastNDays: rangeDays)
    }

    private var longestSleep: TimeInterval? {
        CradleEngine.longestSleep(events: events, lastNDays: rangeDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Range toggle
                        rangeToggle
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if events.isEmpty {
                            EmptyStateView(
                                icon: "chart.bar",
                                title: "No data yet",
                                message: "Start logging feeds, sleep, and diapers to see your charts here."
                            )
                            .padding(.top, 60)
                        } else {
                            // Stats row
                            statsRow
                                .padding(.horizontal, 20)

                            // Feed chart
                            feedsChart
                                .padding(.horizontal, 20)

                            // Sleep chart
                            sleepChart
                                .padding(.horizontal, 20)

                            // Diaper chart
                            diaperChart
                                .padding(.horizontal, 20)

                            Spacer(minLength: 32)
                        }
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Range Toggle

    @ViewBuilder
    private var rangeToggle: some View {
        HStack(spacing: 0) {
            ForEach([7, 14], id: \.self) { days in
                Button {
                    Haptics.selection()
                    withAnimation(Brand.ease(0.25)) {
                        rangeDays = days
                    }
                } label: {
                    Text("Last \(days)d")
                        .font(.subheadline.weight(rangeDays == days ? .bold : .regular))
                        .foregroundStyle(rangeDays == days ? Brand.text : Brand.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            rangeDays == days ? Brand.text.opacity(0.08) : Color.clear,
                            in: Capsule()
                        )
                }
                .accessibilityLabel("Show last \(days) days")
                .accessibilityAddTraits(rangeDays == days ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(
                value: String(format: "%.1f", averages.feedsPerDay),
                label: "Avg feeds/day",
                symbol: "drop.fill",
                color: EventKind.feed.color
            )
            StatCard(
                value: String(format: "%.1f h", averages.sleepHoursPerDay),
                label: "Avg sleep/day",
                symbol: "moon.fill",
                color: EventKind.sleep.color
            )
            if let interval = avgFeedInterval {
                StatCard(
                    value: String(format: "%.1f h", interval),
                    label: "Avg feed interval",
                    symbol: "timer",
                    color: Brand.info
                )
            }
            if let longest = longestSleep {
                StatCard(
                    value: Format.duration(longest),
                    label: "Longest sleep",
                    symbol: "moon.stars.fill",
                    color: Brand.magic
                )
            }
        }
    }

    // MARK: - Feeds Chart

    @ViewBuilder
    private var feedsChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Feeds per day")

                Chart(dayData) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Feeds", day.feeds)
                    )
                    .foregroundStyle(EventKind.feed.color.gradient)
                    .cornerRadius(4)
                    .accessibilityLabel("\(Format.shortDate(day.day)): \(day.feeds) feeds")
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { val in
                        if let date = val.as(Date.self) {
                            AxisValueLabel(Format.weekdayShort(date))
                                .font(Brand.mono(10))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(Brand.mono(10))
                        AxisGridLine()
                    }
                }
                .frame(height: 140)
                .accessibilityLabel("Bar chart of feeds per day for the last \(rangeDays) days")
            }
        }
    }

    // MARK: - Sleep Chart

    @ViewBuilder
    private var sleepChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Sleep hours per day")
                HStack(spacing: 12) {
                    legendDot(color: Brand.magic, label: "Day")
                    legendDot(color: Brand.info, label: "Night")
                }

                Chart(dayData) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Day Sleep", day.daySleepHours)
                    )
                    .foregroundStyle(Brand.magic.opacity(0.85))
                    .cornerRadius(3)
                    .accessibilityLabel("\(Format.shortDate(day.day)): \(String(format: "%.1f", day.daySleepHours))h day sleep")

                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Night Sleep", day.nightSleepHours)
                    )
                    .foregroundStyle(Brand.info.opacity(0.85))
                    .cornerRadius(3)
                    .accessibilityLabel("\(Format.shortDate(day.day)): \(String(format: "%.1f", day.nightSleepHours))h night sleep")
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { val in
                        if let date = val.as(Date.self) {
                            AxisValueLabel(Format.weekdayShort(date))
                                .font(Brand.mono(10))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(Brand.mono(10))
                        AxisGridLine()
                    }
                }
                .frame(height: 140)
                .accessibilityLabel("Stacked bar chart of day and night sleep hours for the last \(rangeDays) days")
            }
        }
    }

    // MARK: - Diaper Chart

    @ViewBuilder
    private var diaperChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Diapers per day")

                Chart(dayData) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Diapers", day.diapers)
                    )
                    .foregroundStyle(EventKind.diaper.color.gradient)
                    .cornerRadius(4)
                    .accessibilityLabel("\(Format.shortDate(day.day)): \(day.diapers) diapers")
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { val in
                        if let date = val.as(Date.self) {
                            AxisValueLabel(Format.weekdayShort(date))
                                .font(Brand.mono(10))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(Brand.mono(10))
                        AxisGridLine()
                    }
                }
                .frame(height: 120)
                .accessibilityLabel("Bar chart of diapers per day for the last \(rangeDays) days")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text2)
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let value: String
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Brand.mono(22, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
