import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    private let engine = JournalEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No insights yet",
                        message: "Write a few entries and your streaks, words, and mood trends will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            moodTrendCard
                            monthsCard
                            if !tagCounts.isEmpty { tagsCard }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var current: Int { engine.currentStreak(entries) }
    private var longest: Int { engine.longestStreak(entries) }
    private var words: Int { engine.totalWords(entries) }
    private var avgMood: Double? { engine.averageMood(entries) }
    private var trend: [JournalEngine.DayMood] { engine.moodTrend(entries, days: 30) }
    private var months: [JournalEngine.MonthCount] { engine.entriesPerMonth(entries, months: 6) }
    private var tagCounts: [JournalEngine.TagCount] { engine.tagCounts(entries) }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(entries.count)", label: "Entries", symbol: "book.closed.fill")
            StatTile(value: "\(current)", label: current == 1 ? "Day streak" : "Day streak",
                     symbol: "flame.fill", accent: current > 0)
            StatTile(value: "\(longest)", label: "Longest streak", symbol: "trophy.fill")
            StatTile(value: words.formatted(), label: "Words written", symbol: "text.alignleft")
            if let avg = avgMood {
                StatTile(value: String(format: "%.1f", avg), label: "Avg mood", symbol: "face.smiling")
            }
            StatTile(value: "\(daysSinceFirst)", label: "Days journaling", symbol: "calendar")
        }
    }

    private var daysSinceFirst: Int {
        guard let first = entries.map({ $0.date }).min() else { return 0 }
        let cal = Calendar.current
        let d = cal.dateComponents([.day], from: cal.startOfDay(for: first), to: cal.startOfDay(for: .now)).day ?? 0
        return max(0, d) + 1
    }

    private var moodTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood — last 30 days")
                .font(.headline).foregroundStyle(Brand.text)
            let rated = trend.filter { $0.average != nil }
            if rated.isEmpty {
                Text("Rate your entries to see your mood trend.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                Chart {
                    ForEach(rated) { dm in
                        let value = dm.average ?? 0
                        LineMark(x: .value("Day", dm.day), y: .value("Mood", value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.accentColor)
                        PointMark(x: .value("Day", dm.day), y: .value("Mood", value))
                            .foregroundStyle(Color(hex: Mood(rawValue: max(1, min(5, Int(value.rounded()))))?.colorHex ?? 0x7CA68F))
                            .symbolSize(40)
                    }
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self), let m = Mood(rawValue: v) {
                                Text(m.label).font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .glassCard()
    }

    private var monthsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Entries per month")
                .font(.headline).foregroundStyle(Brand.text)
            Chart(months) { m in
                BarMark(
                    x: .value("Month", m.month, unit: .month),
                    y: .value("Entries", m.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .frame(height: 160)
        }
        .glassCard()
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most-used tags")
                .font(.headline).foregroundStyle(Brand.text)
            ForEach(tagCounts.prefix(6)) { tc in
                HStack {
                    TagChip(name: tc.name, colorHex: tc.colorHex)
                    Spacer()
                    Text("\(tc.count)")
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        .glassCard()
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(accent ? Brand.live : Color.accentColor)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
