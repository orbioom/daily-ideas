import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PracticeLog.date, order: .reverse) private var logs: [PracticeLog]
    @Query private var affirmations: [Affirmation]

    private var streak: Int { MantraEngine.currentStreak(logs: logs) }
    private var total: Int { logs.count }
    private var days: Int { MantraEngine.daysPracticed(logs: logs) }
    private var favCategory: MantraCategory? { MantraEngine.favoriteCategory(logs: logs) }
    private var favoritesCount: Int { affirmations.filter { $0.isFavorite }.count }
    private var chartData: [(date: Date, count: Int)] { MantraEngine.dailyCounts(logs: logs, span: 14) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if logs.isEmpty {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No practice yet",
                                   message: "Affirm a line on the Today tab and your progress will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statRow
                            chartCard
                            if let fav = favCategory { favoriteCard(fav) }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            stat("Streak", "\(streak)", "flame.fill", Brand.warn)
            stat("Affirmed", "\(total)", "sparkles", Brand.magic)
            stat("Days", "\(days)", "calendar", Brand.info)
        }
    }

    private func stat(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(Brand.mono(24, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(Brand.mono(11)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Last 14 days")
            Chart(chartData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Affirmations", item.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.day()) } }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func favoriteCard(_ cat: MantraCategory) -> some View {
        HStack(spacing: 14) {
            Image(systemName: cat.icon)
                .font(.title)
                .foregroundStyle(cat.tint)
                .frame(width: 54, height: 54)
                .background(cat.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "You return to")
                Text(cat.rawValue).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                Text("\(favoritesCount) favorites saved").font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}
