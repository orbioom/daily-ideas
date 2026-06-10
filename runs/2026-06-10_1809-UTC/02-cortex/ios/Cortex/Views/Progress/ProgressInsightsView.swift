import SwiftUI
import SwiftData
import Charts

struct ProgressInsightsView: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    private var streak: Int { StatsEngine.streak(results) }
    private var total: Int { StatsEngine.totalScore(results) }
    private var trend: [(date: Date, score: Int)] { StatsEngine.dailyBest(results, days: 14) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if results.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "No games yet",
                                   message: "Play a game or run the daily workout to see your progress here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(streak)", label: "Day streak", tint: Brand.magic)
                                StatTile(value: "\(results.count)", label: "Games played")
                                StatTile(value: total >= 1000 ? "\(total/1000)k" : "\(total)", label: "Total points")
                            }
                            trendCard
                            perGameCard
                            recentCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily best · 14 days").font(.headline).foregroundStyle(Brand.text)
            Chart(trend, id: \.date) { item in
                LineMark(x: .value("Day", item.date, unit: .day),
                         y: .value("Score", item.score))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Brand.info)
                AreaMark(x: .value("Day", item.date, unit: .day),
                         y: .value("Score", item.score))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Brand.info.opacity(0.15))
                PointMark(x: .value("Day", item.date, unit: .day),
                          y: .value("Score", item.score))
                    .foregroundStyle(Brand.info)
                    .symbolSize(item.score > 0 ? 30 : 0)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Daily best combined score over the last 14 days")
        }
        .padding(18).glassCard()
    }

    private var perGameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By game").font(.headline).foregroundStyle(Brand.text)
            ForEach(Game.allCases) { game in
                let s = StatsEngine.summary(results, game: game)
                if s.plays > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: game.icon).foregroundStyle(game.tint).frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text("\(s.plays) plays · \(Int(s.averageAccuracy * 100))% avg")
                                .font(.caption).foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(s.best)").font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                            Text("best").font(.caption2).foregroundStyle(Brand.text3)
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(game.title): best \(s.best), \(s.plays) plays")
                }
            }
        }
        .padding(18).glassCard()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent").font(.headline).foregroundStyle(Brand.text)
            ForEach(results.prefix(8)) { r in
                HStack(spacing: 10) {
                    Image(systemName: r.game.icon).foregroundStyle(r.game.tint).frame(width: 22)
                    Text(r.game.title).font(.subheadline).foregroundStyle(Brand.text)
                    if r.workoutID != nil {
                        Image(systemName: "bolt.fill").font(.caption2).foregroundStyle(Brand.magic)
                            .accessibilityLabel("part of workout")
                    }
                    Spacer()
                    Text(r.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption).foregroundStyle(Brand.text3)
                    Text("\(r.score)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text2)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18).glassCard()
    }
}

#Preview {
    ProgressInsightsView().modelContainer(for: GameResult.self, inMemory: true)
}
