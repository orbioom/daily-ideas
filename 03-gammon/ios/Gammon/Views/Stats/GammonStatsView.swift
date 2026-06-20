import SwiftUI
import SwiftData

struct GammonStatsView: View {
    @Query(sort: \GammonResult.date, order: .reverse)
    private var results: [GammonResult]

    @State private var selectedFilter: StatFilter = .all

    enum StatFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case ai = "vs AI"
        case twoPlayer = "2 Player"

        var id: String { rawValue }
    }

    private var filteredResults: [GammonResult] {
        switch selectedFilter {
        case .all: return results
        case .ai: return results.filter { $0.mode == "ai" }
        case .twoPlayer: return results.filter { $0.mode == "2player" }
        }
    }

    private var aiResults: [GammonResult] { results.filter { $0.mode == "ai" } }
    private var wins: Int { aiResults.filter { $0.outcome == "win" }.count }
    private var losses: Int { aiResults.filter { $0.outcome == "loss" }.count }
    private var winRate: Double {
        let total = wins + losses
        return total > 0 ? Double(wins) / Double(total) : 0
    }
    private var avgMoves: Double {
        let total = filteredResults.count
        guard total > 0 else { return 0 }
        return Double(filteredResults.reduce(0) { $0 + $1.gameMoves }) / Double(total)
    }

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: GammonTheme.sectionSpacing) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Statistics")
                            .font(GammonTheme.titleFont)
                            .foregroundStyle(GammonTheme.textPrimary)
                        Text("Your backgammon performance")
                            .font(.subheadline)
                            .foregroundStyle(GammonTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    if results.isEmpty {
                        emptyState()
                    } else {
                        // Overall stats cards
                        overallStatsSection()

                        // Win rate by difficulty
                        difficultyBreakdownSection()

                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(StatFilter.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(GammonTheme.accent)

                        // Recent games list
                        recentGamesSection()
                    }
                }
                .padding(.horizontal, GammonTheme.cardPadding)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(GammonTheme.textMuted)
            Text("No games played yet")
                .font(.headline)
                .foregroundStyle(GammonTheme.textSecondary)
            Text("Play your first game to see stats here")
                .font(.subheadline)
                .foregroundStyle(GammonTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func overallStatsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall")
                .font(GammonTheme.headingFont)
                .foregroundStyle(GammonTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Games Played", value: "\(results.count)", icon: "gamecontroller.fill", color: GammonTheme.accent)
                StatCard(title: "Win Rate", value: String(format: "%.0f%%", winRate * 100), icon: "percent", color: GammonTheme.winColor)
                StatCard(title: "Wins vs AI", value: "\(wins)", icon: "trophy.fill", color: Color(red: 0.9, green: 0.7, blue: 0.1))
                StatCard(title: "Avg Moves", value: String(format: "%.0f", avgMoves), icon: "arrow.left.arrow.right", color: Color(red: 0.4, green: 0.6, blue: 0.9))
            }

            // Win rate ring
            if wins + losses > 0 {
                winRateRing()
            }
        }
    }

    @ViewBuilder
    private func winRateRing() -> some View {
        VStack(spacing: 8) {
            Text("Win Rate vs AI")
                .font(.caption)
                .foregroundStyle(GammonTheme.textSecondary)

            ZStack {
                Circle()
                    .stroke(GammonTheme.loseColor.opacity(0.4), lineWidth: 12)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: winRate)
                    .stroke(GammonTheme.winColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: winRate)
                VStack(spacing: 0) {
                    Text(String(format: "%.0f%%", winRate * 100))
                        .font(.title3.bold())
                        .foregroundStyle(GammonTheme.textPrimary)
                    Text("wins")
                        .font(.caption2)
                        .foregroundStyle(GammonTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .gammonCard()
    }

    @ViewBuilder
    private func difficultyBreakdownSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Difficulty")
                .font(GammonTheme.headingFont)
                .foregroundStyle(GammonTheme.textPrimary)

            VStack(spacing: 8) {
                ForEach(1...3, id: \.self) { diff in
                    let diffResults = aiResults.filter { $0.difficulty == diff }
                    let diffWins = diffResults.filter { $0.outcome == "win" }.count
                    let diffTotal = diffResults.count
                    let rate = diffTotal > 0 ? Double(diffWins) / Double(diffTotal) : 0

                    DifficultyRow(
                        difficulty: diff,
                        wins: diffWins,
                        total: diffTotal,
                        rate: rate
                    )
                }
            }
            .padding(GammonTheme.cardPadding)
            .gammonCard()
        }
    }

    @ViewBuilder
    private func recentGamesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(GammonTheme.headingFont)
                .foregroundStyle(GammonTheme.textPrimary)

            if filteredResults.isEmpty {
                Text("No games in this category")
                    .font(.subheadline)
                    .foregroundStyle(GammonTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .gammonCard()
            } else {
                VStack(spacing: 1) {
                    ForEach(filteredResults.prefix(20)) { result in
                        GameResultRow(result: result)
                    }
                }
                .cornerRadius(GammonTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: GammonTheme.cornerRadius)
                        .stroke(GammonTheme.accentDark.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(GammonTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(GammonTheme.textSecondary)
        }
        .padding(GammonTheme.cardPadding)
        .gammonCard()
    }
}

struct DifficultyRow: View {
    let difficulty: Int
    let wins: Int
    let total: Int
    let rate: Double

    private var difficultyName: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        default: return "Hard"
        }
    }

    private var difficultyColor: Color {
        switch difficulty {
        case 1: return GammonTheme.winColor
        case 2: return GammonTheme.accent
        default: return GammonTheme.loseColor
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(difficultyName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(difficultyColor)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GammonTheme.surfaceHigh)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(difficultyColor)
                        .frame(width: geo.size.width * rate, height: 8)
                        .animation(.spring(response: 0.6), value: rate)
                }
            }
            .frame(height: 8)

            Text("\(wins)/\(total)")
                .font(.caption)
                .foregroundStyle(GammonTheme.textSecondary)
                .frame(width: 44, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

struct GameResultRow: View {
    let result: GammonResult

    private var outcomeIcon: String {
        switch result.outcome {
        case "win": return "checkmark.circle.fill"
        case "loss": return "xmark.circle.fill"
        default: return "minus.circle.fill"
        }
    }

    private var outcomeColor: Color {
        switch result.outcome {
        case "win": return GammonTheme.winColor
        case "loss": return GammonTheme.loseColor
        default: return GammonTheme.textMuted
        }
    }

    private var outcomeLabel: String {
        switch result.outcome {
        case "win": return "Win"
        case "loss": return "Loss"
        case "white": return "White Won"
        case "black": return "Black Won"
        default: return result.outcome.capitalized
        }
    }

    private var modeLabel: String {
        result.mode == "ai" ? "vs AI" : "2P"
    }

    private var difficultyLabel: String {
        guard result.mode == "ai" else { return "" }
        switch result.difficulty {
        case 1: return " • Easy"
        case 2: return " • Medium"
        case 3: return " • Hard"
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: outcomeIcon)
                .foregroundStyle(outcomeColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(outcomeLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GammonTheme.textPrimary)
                Text("\(modeLabel)\(difficultyLabel) • \(result.gameMoves) moves")
                    .font(.caption)
                    .foregroundStyle(GammonTheme.textSecondary)
            }

            Spacer()

            Text(result.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(GammonTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GammonTheme.surface)
    }
}

#Preview {
    GammonStatsView()
        .modelContainer(for: GammonResult.self, inMemory: true)
        .preferredColorScheme(.dark)
}
