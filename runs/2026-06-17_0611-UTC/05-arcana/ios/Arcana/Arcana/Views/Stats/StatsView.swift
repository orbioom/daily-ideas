import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var readings: [Reading]
    @Query private var dailies: [DailyDraw]

    private var total: Int { StatsEngine.totalDraws(readings: readings, dailies: dailies) }
    private var mostDrawn: [StatsEngine.CardCount] { StatsEngine.mostDrawn(readings: readings, dailies: dailies, limit: 6) }
    private var suits: [StatsEngine.SuitSlice] { StatsEngine.suitDistribution(readings: readings, dailies: dailies) }
    private var arcana: [StatsEngine.ArcanaSlice] { StatsEngine.arcanaDistribution(readings: readings, dailies: dailies) }
    private var overTime: [StatsEngine.DayCount] { StatsEngine.readingsOverTime(readings: readings, dailies: dailies, days: 14) }
    private var streak: Int { StatsEngine.currentStreak(dailies: dailies) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if total == 0 {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No stats yet",
                                   message: "Draw your daily card and save a few readings — your patterns will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryRow
                            mostDrawnCard
                            suitChart
                            arcanaChart
                            overTimeChart
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(total)", label: "Cards drawn", icon: "rectangle.stack")
            statTile(value: "\(readings.count)", label: "Readings", icon: "book")
            statTile(value: "\(streak)", label: "Day streak", icon: "flame.fill")
        }
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Theme.gold)
            Text(value).font(Theme.serif(26, .bold)).foregroundStyle(Theme.ink)
            Text(label).font(.caption).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var mostDrawnCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Most-drawn cards", icon: "star")
            Chart(mostDrawn) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Card", item.card.name)
                )
                .foregroundStyle(item.card.suit?.color ?? Theme.accent)
                .cornerRadius(5)
                .annotation(position: .trailing) {
                    Text("\(item.count)").font(.caption2).foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXAxis { AxisMarks(position: .bottom) }
            .frame(height: max(120, CGFloat(mostDrawn.count) * 34))
            .accessibilityLabel("Most drawn cards")
            .accessibilityValue(mostDrawn.map { "\($0.card.name) \($0.count)" }.joined(separator: ", "))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().cardSurface()
    }

    private var suitChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "By suit", icon: "suit.diamond")
            if suits.allSatisfy({ $0.count == 0 }) {
                Text("Only Major Arcana drawn so far.").font(.callout).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(suits) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.suit.color)
                    .cornerRadius(3)
                }
                .frame(height: 200)
                .accessibilityLabel("Distribution by suit")
                .accessibilityValue(suits.map { "\($0.suit.rawValue) \($0.count)" }.joined(separator: ", "))
                suitLegend
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().cardSurface()
    }

    private var suitLegend: some View {
        FlexWrap(spacing: 12, lineSpacing: 8) {
            ForEach(suits) { slice in
                HStack(spacing: 6) {
                    Circle().fill(slice.suit.color).frame(width: 10, height: 10)
                    Text("\(slice.suit.rawValue) (\(slice.count))")
                        .font(.caption).foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var arcanaChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Major vs Minor", icon: "circle.lefthalf.filled")
            Chart(arcana) { slice in
                BarMark(
                    x: .value("Arcana", slice.arcana.rawValue),
                    y: .value("Count", slice.count)
                )
                .foregroundStyle(slice.arcana == .major ? Theme.accent : Theme.gold)
                .cornerRadius(5)
            }
            .frame(height: 160)
            .accessibilityLabel("Major versus Minor arcana")
            .accessibilityValue(arcana.map { "\($0.arcana.rawValue) \($0.count)" }.joined(separator: ", "))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().cardSurface()
    }

    private var overTimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Last 14 days", icon: "calendar")
            Chart(overTime) { day in
                LineMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Draws", day.count)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Draws", day.count)
                )
                .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.3), .clear],
                                                startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 170)
            .accessibilityLabel("Draws over the last 14 days")
            .accessibilityValue("\(overTime.reduce(0) { $0 + $1.count }) total")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().cardSurface()
    }
}
