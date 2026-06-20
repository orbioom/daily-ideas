import SwiftUI
import SwiftData

struct DropStatsView: View {
    @Query(sort: \DropResult.date, order: .reverse) private var results: [DropResult]

    private var wins: Int { results.filter { $0.outcome == "win" }.count }
    private var losses: Int { results.filter { $0.outcome == "loss" }.count }
    private var draws: Int { results.filter { $0.outcome == "draw" }.count }
    private var total: Int { results.count }
    private var winRate: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.22),
                        Color(red: 0.10, green: 0.14, blue: 0.38)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Win rate ring + big numbers
                            summarySection
                            // Per-difficulty breakdown
                            difficultyBreakdown
                            // Recent games list
                            recentGames
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.3))

            Text("No Games Yet")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Play your first game to\nsee your stats here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 16) {
            // Big stat numbers
            HStack(spacing: 12) {
                bigStatCard(value: wins, label: "Wins", color: .green)
                bigStatCard(value: losses, label: "Losses", color: DropTheme.humanColor)
                bigStatCard(value: draws, label: "Draws", color: .orange)
            }

            // Win rate ring
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: winRate)
                        .stroke(
                            AngularGradient(
                                colors: [.green, DropTheme.accent, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: winRate)

                    VStack(spacing: 0) {
                        Text("\(Int(winRate * 100))%")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Win Rate")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    statRow(label: "Total games", value: "\(total)")
                    statRow(label: "Best streak", value: "\(bestWinStreak)")
                    statRow(label: "Avg moves", value: avgMoves > 0 ? "\(avgMoves)" : "—")
                }

                Spacer()
            }
            .padding(20)
            .background(cardBackground)
        }
    }

    private var bestWinStreak: Int {
        var streak = 0
        var best = 0
        for result in results.reversed() {
            if result.outcome == "win" {
                streak += 1
                best = max(best, streak)
            } else {
                streak = 0
            }
        }
        return best
    }

    private var avgMoves: Int {
        guard !results.isEmpty else { return 0 }
        return results.map(\.moves).reduce(0, +) / results.count
    }

    private func bigStatCard(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Difficulty Breakdown

    private var difficultyBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Difficulty")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            let hasAnyDifficultyData = [1, 2, 3].contains { level in
                results.contains { $0.difficulty == level }
            }

            if !hasAnyDifficultyData {
                Text("Play on each difficulty to see breakdown")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(12)
            } else {
                ForEach([1, 2, 3], id: \.self) { level in
                    let levelResults = results.filter { $0.difficulty == level }
                    let levelWins = levelResults.filter { $0.outcome == "win" }.count
                    let levelTotal = levelResults.count
                    let rate = levelTotal > 0 ? Double(levelWins) / Double(levelTotal) : 0.0

                    if levelTotal > 0 {
                        difficultyRow(
                            name: DropTheme.difficultyName(level),
                            wins: levelWins,
                            total: levelTotal,
                            rate: rate,
                            color: difficultyColor(level)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func difficultyRow(name: String, wins: Int, total: Int, rate: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(wins)/\(total) wins")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(Int(rate * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 36, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * rate, height: 6)
                        .animation(.easeInOut(duration: 0.8), value: rate)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }

    private func difficultyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return DropTheme.accent
        case 3: return DropTheme.humanColor
        default: return .white
        }
    }

    // MARK: - Recent Games

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            ForEach(Array(results.prefix(10))) { result in
                recentGameRow(result: result)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func recentGameRow(result: DropResult) -> some View {
        HStack(spacing: 12) {
            // Outcome badge
            Text(outcomeEmoji(result.outcome))
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(outcomeColor(result.outcome).opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(outcomeLabel(result.outcome))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(outcomeColor(result.outcome))
                Text("\(DropTheme.difficultyName(result.difficulty)) · \(result.moves) moves")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text(result.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.04))
        )
    }

    private func outcomeEmoji(_ outcome: String) -> String {
        switch outcome {
        case "win": return "🏆"
        case "loss": return "💀"
        case "draw": return "🤝"
        default: return "❓"
        }
    }

    private func outcomeLabel(_ outcome: String) -> String {
        switch outcome {
        case "win": return "Victory"
        case "loss": return "Defeat"
        case "draw": return "Draw"
        default: return "Unknown"
        }
    }

    private func outcomeColor(_ outcome: String) -> Color {
        switch outcome {
        case "win": return .green
        case "loss": return DropTheme.humanColor
        case "draw": return .orange
        default: return .white
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}
