import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    private var streak: Int { StatsEngine.dailyStreak(results: results) }
    private var accuracy: Double? { StatsEngine.overallAccuracy(results) }
    private var catAccuracy: [(category: TriviaCategory, accuracy: Double, games: Int)] {
        StatsEngine.categoryAccuracy(results).sorted { $0.accuracy > $1.accuracy }
    }
    private var dailyScores: [GameResult] {
        results.filter { $0.mode == .daily }.sorted { $0.date < $1.date }.suffix(14).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if results.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No stats yet",
                                   message: "Play the daily challenge or a practice round and your streaks, scores and accuracy will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsRow
                            if dailyScores.count >= 2 { scoreChart }
                            if !catAccuracy.isEmpty { categoryCard }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(streak)", label: "day streak", accent: Theme.gold)
            StatTile(value: "\(results.count)", label: "rounds played", accent: Theme.accent)
            StatTile(value: accuracy.map { "\(Int($0 * 100))%" } ?? "—", label: "accuracy", accent: Theme.good)
        }
    }

    private var scoreChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily scores").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(dailyScores) { r in
                    LineMark(x: .value("Date", r.date), y: .value("Score", r.score))
                        .foregroundStyle(Theme.accent).interpolationMethod(.monotone)
                    PointMark(x: .value("Date", r.date), y: .value("Score", r.score))
                        .foregroundStyle(Theme.gold)
                }
                .frame(height: 170)
                .accessibilityLabel("Daily challenge scores over time")
            }
        }
    }

    private var categoryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("By category").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                ForEach(catAccuracy, id: \.category) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: item.category.icon).font(.system(size: 13)).foregroundStyle(Theme.accent)
                            Text(item.category.label).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(Int(item.accuracy * 100))%").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.good)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.surfaceAlt)
                                Capsule().fill(Theme.accent).frame(width: max(0, min(1, item.accuracy)) * geo.size.width)
                            }
                        }
                        .frame(height: 7)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.category.label): \(Int(item.accuracy * 100)) percent over \(item.games) rounds")
                }
            }
        }
    }
}
