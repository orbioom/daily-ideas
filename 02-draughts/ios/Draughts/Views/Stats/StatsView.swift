import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var statsList: [DraughtsStats]

    private var stats: DraughtsStats? { statsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                DraughtsTheme.background.ignoresSafeArea()

                if let stats = stats, stats.gamesPlayed > 0 {
                    statsContent(stats: stats)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DraughtsTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(DraughtsTheme.gold.opacity(0.50))

            Text("No Games Yet")
                .font(.title3.bold())
                .foregroundStyle(DraughtsTheme.text)

            Text("Play a game to see your statistics here.")
                .font(.subheadline)
                .foregroundStyle(DraughtsTheme.text.opacity(0.60))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Stats Content

    @ViewBuilder
    private func statsContent(stats: DraughtsStats) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summaryRow(stats: stats)

                // Win/Loss bar chart
                winLossChart(stats: stats)

                // Streak card
                streakCard(stats: stats)

                // Recent games
                recentGames(stats: stats)

                Spacer(minLength: 16)
            }
            .padding()
        }
    }

    // MARK: - Summary Row

    private func summaryRow(stats: DraughtsStats) -> some View {
        HStack(spacing: 12) {
            statCard(value: "\(stats.gamesPlayed)", label: "Games")
            statCard(value: "\(stats.wins)", label: "Wins")
            statCard(value: "\(stats.losses)", label: "Losses")
            statCard(value: winRateText(stats: stats), label: "Win Rate")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(DraughtsTheme.gold)
            Text(label)
                .font(.caption)
                .foregroundStyle(DraughtsTheme.text.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(DraughtsTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func winRateText(stats: DraughtsStats) -> String {
        guard stats.gamesPlayed > 0 else { return "—" }
        return "\(Int(stats.winRate * 100))%"
    }

    // MARK: - Bar Chart

    private func winLossChart(stats: DraughtsStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win vs Loss")
                .font(.headline)
                .foregroundStyle(DraughtsTheme.text)

            Chart {
                BarMark(
                    x: .value("Outcome", "Wins"),
                    y: .value("Count", stats.wins)
                )
                .foregroundStyle(DraughtsTheme.gold)
                .cornerRadius(6)

                BarMark(
                    x: .value("Outcome", "Losses"),
                    y: .value("Count", stats.losses)
                )
                .foregroundStyle(DraughtsTheme.redPiece)
                .cornerRadius(6)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(DraughtsTheme.text.opacity(0.70))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(DraughtsTheme.separatorColor)
                    AxisValueLabel()
                        .foregroundStyle(DraughtsTheme.text.opacity(0.70))
                }
            }
        }
        .padding()
        .background(DraughtsTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak Card

    private func streakCard(stats: DraughtsStats) -> some View {
        HStack(spacing: 0) {
            streakItem(
                icon: "flame.fill",
                value: "\(abs(stats.currentStreak))",
                label: stats.currentStreak >= 0 ? "Win Streak" : "Losing Streak",
                color: stats.currentStreak > 0 ? DraughtsTheme.gold : DraughtsTheme.redPiece
            )

            Divider()
                .background(DraughtsTheme.separatorColor)
                .frame(height: 50)

            streakItem(
                icon: "star.fill",
                value: "\(stats.bestStreak)",
                label: "Best Streak",
                color: DraughtsTheme.gold
            )
        }
        .padding()
        .background(DraughtsTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func streakItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(DraughtsTheme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(DraughtsTheme.text.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent Games

    private func recentGames(stats: DraughtsStats) -> some View {
        let history = stats.gameHistory.prefix(10)
        guard !history.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Games")
                    .font(.headline)
                    .foregroundStyle(DraughtsTheme.text)

                ForEach(Array(history.enumerated()), id: \.offset) { _, record in
                    gameRow(record: record)
                }
            }
            .padding()
            .background(DraughtsTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }

    private func gameRow(record: DraughtsStats.GameRecord) -> some View {
        HStack {
            Image(systemName: record.humanWon ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.humanWon ? DraughtsTheme.gold : DraughtsTheme.redPiece)

            Text(record.humanWon ? "Win" : "Loss")
                .font(.subheadline.bold())
                .foregroundStyle(DraughtsTheme.text)

            Spacer()

            Text("\(record.moves) moves")
                .font(.caption)
                .foregroundStyle(DraughtsTheme.text.opacity(0.60))

            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(DraughtsTheme.text.opacity(0.45))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [DraughtsStats.self], inMemory: true)
}
