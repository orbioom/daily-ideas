import SwiftUI
import SwiftData
import Charts

/// Lifetime stats over every saved game: games played, pangrams, Genius count,
/// daily streak, a rank-distribution chart, and a recent-games list.
struct StatsView: View {
    @Environment(ProStore.self) private var pro
    @Query(sort: \GameProgress.startedAt, order: .reverse) private var records: [GameProgress]

    private var bank: [Puzzle] { PuzzleBank.all(includePro: pro.isPro) }
    private var stats: GameStats { GameStats.from(records, bank: bank) }
    private var playedRecords: [GameProgress] { records.filter { !$0.foundWords.isEmpty } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if playedRecords.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No games yet",
                                   message: "Play today's puzzle or pick one from Practice and your stats will land here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            rankChart
                            recentList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(stats.gamesPlayed)", label: "Games played")
            StatTile(value: "\(stats.currentStreak)", label: "Day streak", accent: Theme.good)
            StatTile(value: "\(stats.geniusCount)", label: "Genius", accent: Theme.ink)
            StatTile(value: "\(stats.totalPangrams)", label: "Pangrams")
            StatTile(value: "\(stats.totalFoundWords)", label: "Words found", accent: Theme.good)
            StatTile(value: stats.bestRankName, label: "Best rank", accent: Theme.ink)
        }
    }

    @ViewBuilder private var rankChart: some View {
        let data = stats.rankDistribution.filter { $0.count > 0 }
        if !data.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Games by rank reached", systemImage: "rosette")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(Array(data.enumerated()), id: \.offset) { _, item in
                        BarMark(x: .value("Rank", item.name),
                                y: .value("Games", item.count))
                            .foregroundStyle(Theme.accent)
                            .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { value in
                            if let s = value.as(String.self) {
                                AxisValueLabel { Text(s).font(Theme.rounded(9, .medium)) }
                            }
                        }
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent games").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(playedRecords.prefix(12))
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, rec in
                    rowFor(rec)
                    if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    @ViewBuilder private func rowFor(_ rec: GameProgress) -> some View {
        if let puzzle = bank.first(where: { $0.id == rec.puzzleID }) {
            let max = ScoreEngine.maxScore(puzzle)
            let score = ScoreEngine.currentScore(found: rec.foundWords, in: puzzle)
            let rank = ScoreEngine.rank(for: score, max: max)
            HStack(spacing: 12) {
                Image(systemName: rec.isDaily ? "calendar" : "infinity")
                    .foregroundStyle(Theme.accent).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.isDaily ? "Daily · \(rec.dayKey)" : "Practice · \(puzzle.letterSummary)")
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text("\(rank.name) · \(rec.foundWords.count) words")
                        .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text("\(score)")
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
