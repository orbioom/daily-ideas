import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \BowlingGame.date, order: .reverse) private var games: [BowlingGame]

    private var completedGames: [BowlingGame] {
        games.filter { $0.isComplete }
    }

    private var allPlayerScores: [Int] {
        completedGames.flatMap { game in
            game.finalScores().compactMap { $0 }
        }
    }

    private var personalBest: Int {
        allPlayerScores.max() ?? 0
    }

    private var averageScore: Double {
        guard !allPlayerScores.isEmpty else { return 0 }
        return Double(allPlayerScores.reduce(0, +)) / Double(allPlayerScores.count)
    }

    private var totalGames: Int { completedGames.count }

    private var strikePercentage: Double {
        let totalStrikes = completedGames.reduce(0) { $0 + $1.strikeCount() }
        let totalBallsThrown = completedGames.reduce(0) { $0 + $1.totalBalls() }
        guard totalBallsThrown > 0 else { return 0 }
        return Double(totalStrikes) / Double(totalBallsThrown) * 100
    }

    // Last 10 completed games for chart, oldest first
    private var chartData: [ChartEntry] {
        let recent = Array(completedGames.prefix(10).reversed())
        return recent.enumerated().map { idx, game in
            let scores = game.finalScores().compactMap { $0 }
            let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return ChartEntry(
                label: formatter.string(from: game.date),
                score: avgScore,
                gameIndex: idx
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AlleyTheme.darkBackground.ignoresSafeArea()

                if completedGames.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.fill",
                        title: "No Stats Yet",
                        message: "Complete some games to see your bowling statistics."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary cards grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(
                                    icon: "trophy.fill",
                                    iconColor: AlleyTheme.strikeColor,
                                    label: "Personal Best",
                                    value: "\(personalBest)",
                                    subtitle: personalBest == 300 ? "Perfect game!" : "pins"
                                )

                                StatCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    iconColor: AlleyTheme.spareColor,
                                    label: "Average Score",
                                    value: String(format: "%.1f", averageScore),
                                    subtitle: "per game"
                                )

                                StatCard(
                                    icon: "figure.bowling",
                                    iconColor: AlleyTheme.accent,
                                    label: "Games Played",
                                    value: "\(totalGames)",
                                    subtitle: totalGames == 1 ? "game" : "games"
                                )

                                StatCard(
                                    icon: "bolt.fill",
                                    iconColor: Color.orange,
                                    label: "Strike Rate",
                                    value: String(format: "%.1f%%", strikePercentage),
                                    subtitle: "of all balls"
                                )
                            }
                            .padding(.horizontal, 16)

                            // Score trend chart
                            if chartData.count >= 2 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Score Trend")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)

                                    Chart(chartData) { entry in
                                        BarMark(
                                            x: .value("Game", entry.label),
                                            y: .value("Score", entry.score)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AlleyTheme.accent, AlleyTheme.accent.opacity(0.5)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .cornerRadius(4)

                                        RuleMark(y: .value("Average", averageScore))
                                            .foregroundStyle(AlleyTheme.laneColor.opacity(0.7))
                                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                            .annotation(position: .topLeading) {
                                                Text("avg")
                                                    .font(.system(size: 9, weight: .medium))
                                                    .foregroundStyle(AlleyTheme.laneColor.opacity(0.7))
                                            }
                                    }
                                    .chartYScale(domain: 0...300)
                                    .chartXAxis {
                                        AxisMarks(values: .automatic) { _ in
                                            AxisValueLabel()
                                                .foregroundStyle(Color.white.opacity(0.5))
                                                .font(.system(size: 9))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(values: [0, 100, 200, 300]) { value in
                                            AxisGridLine()
                                                .foregroundStyle(Color.white.opacity(0.08))
                                            AxisValueLabel()
                                                .foregroundStyle(Color.white.opacity(0.4))
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding(.horizontal, 16)
                                }
                                .padding(.vertical, 16)
                                .background(AlleyTheme.frameBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                            }

                            // Per-player breakdown
                            PlayerBreakdownSection(games: completedGames)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ChartEntry: Identifiable {
    let id = UUID()
    let label: String
    let score: Int
    let gameIndex: Int
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(iconColor.opacity(0.8))
            }
        }
        .padding(16)
        .background(AlleyTheme.frameBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PlayerBreakdownSection: View {
    let games: [BowlingGame]

    struct PlayerStat: Identifiable {
        let id = UUID()
        let name: String
        let gamesPlayed: Int
        let best: Int
        let average: Double
    }

    private var playerStats: [PlayerStat] {
        var nameScores: [String: [Int]] = [:]
        for game in games {
            let scores = game.finalScores()
            for (idx, name) in game.playerNames.enumerated() {
                if idx < scores.count, let s = scores[idx] {
                    nameScores[name, default: []].append(s)
                }
            }
        }
        return nameScores.map { name, scores in
            PlayerStat(
                name: name,
                gamesPlayed: scores.count,
                best: scores.max() ?? 0,
                average: scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count)
            )
        }
        .sorted { $0.average > $1.average }
    }

    var body: some View {
        if !playerStats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Player Breakdown")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                ForEach(playerStats) { stat in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AlleyTheme.accent.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Text(String(stat.name.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AlleyTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("\(stat.gamesPlayed) game\(stat.gamesPlayed == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.0f avg", stat.average))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Best: \(stat.best)")
                                .font(.caption)
                                .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AlleyTheme.frameBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
}
