import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var beans: [Bean]

    private var hasBrews: Bool { beans.contains { !$0.brews.isEmpty } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if !hasBrews {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No stats yet",
                                   message: "Log a few brews and your methods, ratings and habits will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headlineGrid
                            methodCard
                            tasteCard
                            activityCard
                            if let fav = BrewStats.favoriteBean(beans) { favoriteCard(fav) }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStat(value: "\(BrewStats.totalBrews(beans))", label: "Brews")
            MiniStat(value: ratingText, label: "Avg rating", tint: Theme.crema)
            MiniStat(value: "\(beans.filter { !$0.isArchived }.count)", label: "Open bags")
        }
        .cremaCard()
    }

    private var ratingText: String {
        BrewStats.averageRating(beans).map { String(format: "%.1f", $0) } ?? "—"
    }

    private var methodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By method").font(.headline).foregroundStyle(Theme.textPrimary)
            let data = BrewStats.byMethod(beans)
            Chart(data) { item in
                BarMark(x: .value("Count", item.count), y: .value("Method", item.method.rawValue))
                    .foregroundStyle(Theme.cremaGradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
            }
            .frame(height: CGFloat(data.count) * 38 + 16)
            .accessibilityLabel("Bar chart of brews by method")
        }
        .cremaCard()
    }

    private var tasteCard: some View {
        let data = BrewStats.tasteBreakdown(beans)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Taste balance").font(.headline).foregroundStyle(Theme.textPrimary)
            if data.isEmpty {
                Text("Rate how your brews taste to see your balance.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(data) { item in
                    SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.58), angularInset: 2)
                        .cornerRadius(4)
                        .foregroundStyle(item.taste.color)
                }
                .frame(height: 180)
                .accessibilityLabel("Donut chart of taste outcomes")
                HStack(spacing: 14) {
                    ForEach(data) { item in
                        HStack(spacing: 5) {
                            Circle().fill(item.taste.color).frame(width: 9, height: 9)
                            Text("\(item.taste.rawValue.components(separatedBy: " ").first ?? "") \(item.count)")
                                .font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .cremaCard()
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 14 days").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(BrewStats.dailyCounts(beans, days: 14)) { item in
                BarMark(x: .value("Day", item.day, unit: .day), y: .value("Brews", item.count))
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(3)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
            .accessibilityLabel("Bar chart of brews per day over the last fourteen days")
        }
        .cremaCard()
    }

    private func favoriteCard(_ bean: Bean) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Top-rated coffee", systemImage: "trophy.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.crema)
            Text(bean.name).font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            if let best = bean.bestBrew {
                Text("Best brew: \(best.ratioString) · \(Int(best.timeSeconds))s · \(String(format: "%.1f★", best.rating))")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cremaCard()
    }
}
