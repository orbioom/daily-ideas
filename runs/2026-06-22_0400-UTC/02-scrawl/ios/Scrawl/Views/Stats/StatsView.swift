import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \ScrawlRecord.date, order: .reverse) private var records: [ScrawlRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    statsContent
                }
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("📊")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                Text("No games yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)

                Text("Play your first game to start tracking stats and scores.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overview cards
                overviewSection

                // Team leaderboard
                if !teamWins.isEmpty {
                    leaderboardSection
                }

                // Game history
                historySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)

            HStack(spacing: 12) {
                OverviewCard(
                    emoji: "🎮",
                    value: "\(records.count)",
                    label: "Games",
                    color: ScrawlTheme.skyBlue
                )
                OverviewCard(
                    emoji: "🎨",
                    value: "\(totalRounds)",
                    label: "Rounds",
                    color: ScrawlTheme.coral
                )
                OverviewCard(
                    emoji: "⭐",
                    value: "\(highScore)",
                    label: "High Score",
                    color: ScrawlTheme.warningOrange
                )
            }
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Wins")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)

            VStack(spacing: 8) {
                ForEach(Array(teamWins.enumerated()), id: \.element.0) { index, entry in
                    HStack(spacing: 12) {
                        Text(placeEmoji(index))
                            .font(.system(size: 18))
                            .frame(width: 30)

                        Text(entry.0)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(entry.1)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(index == 0 ? ScrawlTheme.warningOrange : ScrawlTheme.skyBlue)
                            Text("wins")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(ScrawlTheme.secondaryText)
                        }
                    }
                    .padding(14)
                    .background(
                        index == 0
                            ? ScrawlTheme.warningOrange.opacity(0.08)
                            : ScrawlTheme.cardBackground
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game History")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)

            VStack(spacing: 8) {
                ForEach(records) { record in
                    GameHistoryRow(record: record)
                }
            }
        }
    }

    // MARK: - Computed

    private var totalRounds: Int {
        records.reduce(0) { $0 + $1.roundCount }
    }

    private var highScore: Int {
        records.compactMap { $0.finalScores.max() }.max() ?? 0
    }

    private var teamWins: [(String, Int)] {
        var wins: [String: Int] = [:]
        for record in records {
            if let winner = record.winnerName {
                wins[winner, default: 0] += 1
            }
        }
        return wins.sorted { $0.value > $1.value }
    }

    private func placeEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)."
        }
    }
}

struct OverviewCard: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 24))
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ScrawlTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .scrawlCard()
    }
}

struct GameHistoryRow: View {
    let record: ScrawlRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.teamNames.joined(separator: " vs "))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(record.wordPackUsed)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.skyBlue)

                    Text("•")
                        .foregroundStyle(ScrawlTheme.secondaryText)

                    Text("\(record.roundCount) rounds")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.finalScores.map(String.init).joined(separator: " - "))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.coral)

                Text(record.formattedDate)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
            }
        }
        .padding(14)
        .scrawlCard()
    }
}
