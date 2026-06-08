import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \TimeBlock.start) private var allBlocks: [TimeBlock]
    private let cal = Calendar.current

    private var windowBlocks: [TimeBlock] {
        let start = cal.date(byAdding: .day, value: -13, to: cal.startOfDay(for: .now)) ?? .now
        return allBlocks.filter { $0.start >= start }
    }

    private struct DayStat: Identifiable {
        let id = UUID()
        let day: Date
        let scheduled: Int
        let done: Int
    }

    private var dayStats: [DayStat] {
        let today = cal.startOfDay(for: .now)
        return (0..<14).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let blocks = allBlocks.filter { cal.isDate($0.start, inSameDayAs: day) }
            return DayStat(day: day,
                           scheduled: blocks.reduce(0) { $0 + $1.durationMinutes },
                           done: blocks.filter { $0.isDone }.reduce(0) { $0 + $1.durationMinutes })
        }
    }

    private var categories: [ScheduleEngine.CategorySlice] {
        ScheduleEngine.categoryBreakdown(windowBlocks)
    }

    private var totalScheduled: Int { windowBlocks.reduce(0) { $0 + $1.durationMinutes } }
    private var totalDone: Int { windowBlocks.filter { $0.isDone }.reduce(0) { $0 + $1.durationMinutes } }
    private var overallCompletion: Double {
        totalScheduled > 0 ? Double(totalDone) / Double(totalScheduled) : 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if windowBlocks.isEmpty {
                    EmptyStateView(icon: "chart.pie",
                                   title: "No data yet",
                                   message: "Schedule and complete a few blocks to see how your time really flows.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headline
                            completionCard
                            categoryCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var headline: some View {
        HStack(spacing: 12) {
            metric(value: ScheduleEngine.durationString(totalScheduled), label: "Planned · 14d")
            metric(value: Format.percent(overallCompletion), label: "Completed")
            metric(value: "\(windowBlocks.count)", label: "Blocks")
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Scheduled vs Completed · hours/day")
            Chart(dayStats) { stat in
                BarMark(
                    x: .value("Day", stat.day, unit: .day),
                    y: .value("Hours", Double(stat.scheduled) / 60.0)
                )
                .foregroundStyle(Brand.text3.opacity(0.4))
                .position(by: .value("Kind", "Planned"))
                BarMark(
                    x: .value("Day", stat.day, unit: .day),
                    y: .value("Hours", Double(stat.done) / 60.0)
                )
                .foregroundStyle(Brand.live)
                .position(by: .value("Kind", "Done"))
            }
            .chartForegroundStyleScale(["Planned": Brand.text3.opacity(0.4), "Done": Brand.live])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Bar chart of planned versus completed hours per day over 14 days")
        }
        .glassCard()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Time by category · 14 days")
            Chart(categories) { slice in
                SectorMark(
                    angle: .value("Minutes", slice.minutes),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(slice.category.color)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .accessibilityLabel("Donut chart of time by category")

            VStack(spacing: 6) {
                ForEach(categories) { slice in
                    HStack(spacing: 8) {
                        Circle().fill(slice.category.color).frame(width: 9, height: 9)
                        Text(slice.category.title).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(ScheduleEngine.durationString(slice.minutes))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slice.category.title): \(ScheduleEngine.durationString(slice.minutes))")
                }
            }
        }
        .glassCard()
    }
}
