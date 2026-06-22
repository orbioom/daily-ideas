import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \BingoGame.date, order: .reverse) private var games: [BingoGame]

    var completedGames: [BingoGame] { games.filter { $0.isComplete } }

    var avgCallsToWin: Double {
        guard !completedGames.isEmpty else { return 0 }
        return Double(completedGames.reduce(0) { $0 + $1.callCount }) / Double(completedGames.count)
    }

    var favoriteType: String {
        let numGames = games.filter { $0.gameType == "number" }.count
        let wordGames = games.filter { $0.gameType == "word" }.count
        if numGames == 0 && wordGames == 0 { return "None yet" }
        return numGames >= wordGames ? "Number" : "Word"
    }

    var winPatternCounts: [(pattern: String, count: Int)] {
        let patterns = ["row", "column", "diagonal", "corners", "blackout"]
        return patterns.map { p in
            (pattern: p, count: completedGames.filter { $0.winPattern == p }.count)
        }.filter { $0.count > 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                if games.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(BingoTheme.gold.opacity(0.5))
                        Text("No Games Played Yet")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Play some bingo and your stats will appear here!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary cards grid
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                                spacing: 12
                            ) {
                                StatCard(
                                    title: "Games Played",
                                    value: "\(games.count)",
                                    icon: "gamecontroller.fill",
                                    color: BingoTheme.gold
                                )
                                StatCard(
                                    title: "Wins",
                                    value: "\(completedGames.count)",
                                    icon: "trophy.fill",
                                    color: BingoTheme.red
                                )
                                StatCard(
                                    title: "Avg. Calls to Win",
                                    value: avgCallsToWin > 0 ? String(format: "%.1f", avgCallsToWin) : "—",
                                    icon: "timer",
                                    color: Color(hex: "#3B82F6")
                                )
                                StatCard(
                                    title: "Favorite Mode",
                                    value: favoriteType,
                                    icon: "star.fill",
                                    color: Color(hex: "#10B981")
                                )
                            }
                            .padding(.horizontal)

                            // Win pattern breakdown
                            if !winPatternCounts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Win Patterns")
                                        .font(.headline.bold())
                                        .foregroundColor(BingoTheme.gold)

                                    ForEach(winPatternCounts, id: \.pattern) { entry in
                                        WinPatternBar(
                                            pattern: entry.pattern,
                                            count: entry.count,
                                            total: completedGames.count
                                        )
                                    }
                                }
                                .padding()
                                .background(BingoTheme.lightNavy)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }

                            // Recent games list
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Games")
                                    .font(.headline.bold())
                                    .foregroundColor(BingoTheme.gold)
                                    .padding(.horizontal)

                                ForEach(games.prefix(10)) { game in
                                    GameHistoryRow(game: game)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(BingoTheme.lightNavy)
        .cornerRadius(12)
    }
}

struct WinPatternBar: View {
    let pattern: String
    let count: Int
    let total: Int

    var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var patternIcon: String {
        switch pattern {
        case "row": return "rectangle.split.3x1"
        case "column": return "rectangle.split.1x2"
        case "diagonal": return "arrow.down.right"
        case "corners": return "square.on.square"
        case "blackout": return "square.fill"
        default: return "checkmark"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: patternIcon)
                .font(.subheadline)
                .foregroundColor(BingoTheme.gold)
                .frame(width: 24)

            Text(pattern.capitalized)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(BingoTheme.navy.opacity(0.5))
                        .frame(height: 8)
                    Capsule()
                        .fill(BingoTheme.gold)
                        .frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundColor(BingoTheme.gold)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

struct GameHistoryRow: View {
    let game: BingoGame

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.packName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if game.isComplete {
                    Text("WON")
                        .font(.caption.bold())
                        .foregroundColor(BingoTheme.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BingoTheme.gold.opacity(0.2))
                        .cornerRadius(4)
                }
                Text("\(game.callCount) calls")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(BingoTheme.lightNavy)
        .cornerRadius(8)
    }
}
