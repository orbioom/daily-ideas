import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var games: [SudokuGame]

    private var totalWins: Int { StatsEngine.totalWins(games) }
    private var streak: Int { StatsEngine.streak(games) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if games.filter({ $0.isComplete }).isEmpty {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No solved puzzles yet",
                                   message: "Finish a puzzle to see your best times and win rates by difficulty.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(totalWins)", label: "Solved")
                                StatTile(value: "\(streak)", label: "Day streak", tint: Brand.magic)
                                StatTile(value: "\(games.count)", label: "Started")
                            }
                            ForEach(SudokuDifficulty.allCases) { d in
                                difficultyCard(StatsEngine.stats(games, difficulty: d))
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private func difficultyCard(_ s: DifficultyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4).fill(s.difficulty.tint).frame(width: 4, height: 22)
                Text(s.difficulty.title).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if s.played > 0 {
                    Text("\(Int(s.winRate * 100))% won").font(.caption).foregroundStyle(Brand.text2)
                }
            }
            if s.played == 0 {
                Text("Not played yet").font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                HStack(spacing: 12) {
                    miniStat("Best", StatsEngine.format(s.bestSeconds))
                    miniStat("Average", StatsEngine.format(s.averageSeconds))
                    miniStat("Won", "\(s.won)/\(s.played)")
                }
            }
        }
        .padding(18).glassCard()
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    StatsView().modelContainer(for: SudokuGame.self, inMemory: true)
}
