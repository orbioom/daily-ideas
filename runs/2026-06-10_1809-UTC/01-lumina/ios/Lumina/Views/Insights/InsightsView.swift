import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var logs: [DayLog]
    @Query private var affirmations: [Affirmation]

    private var stats: StreakStats { StreakEngine.stats(from: logs) }
    private var recent: [(date: Date, count: Int)] { StreakEngine.recent(logs, days: 14) }

    private var favoriteCount: Int { affirmations.filter { $0.isFavorite }.count }
    private var customCount: Int { affirmations.filter { $0.isCustom }.count }

    private var byTheme: [(AffirmationTheme, Int)] {
        AffirmationTheme.allCases.map { t in
            (t, affirmations.filter { $0.theme == t && $0.isFavorite }.count)
        }.filter { $0.1 > 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if logs.isEmpty {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No practice yet",
                                   message: "Affirm an intention on the Today tab to start building your streak and insights.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            tiles
                            chartCard
                            if !byTheme.isEmpty { favoritesCard }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var tiles: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(stats.current)", label: "Current streak", tint: Brand.magic)
                StatTile(value: "\(stats.longest)", label: "Longest streak")
            }
            HStack(spacing: 12) {
                StatTile(value: "\(stats.totalAffirmed)", label: "Affirmed total")
                StatTile(value: "\(stats.daysPracticed)", label: "Days practiced")
            }
            HStack(spacing: 12) {
                StatTile(value: "\(favoriteCount)", label: "Favorites", tint: Brand.danger)
                StatTile(value: "\(customCount)", label: "Your own")
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 14 days").font(.headline).foregroundStyle(Brand.text)
            Chart(recent, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Affirmed", item.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Daily affirmations practiced over the last 14 days")
        }
        .padding(18)
        .glassCard()
    }

    private var favoritesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorites by theme").font(.headline).foregroundStyle(Brand.text)
            ForEach(byTheme, id: \.0) { theme, count in
                HStack {
                    Image(systemName: theme.icon).foregroundStyle(theme.tint).frame(width: 24)
                    Text(theme.title).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(count)").font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text2)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(theme.title): \(count) favorites")
            }
        }
        .padding(18)
        .glassCard()
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
