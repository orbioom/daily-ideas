import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var statsQuery: [PebbleStats]
    private var stats: PebbleStats { statsQuery.first ?? PebbleStats() }

    var body: some View {
        ZStack {
            PebbleTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Statistics")
                        .font(PebbleTheme.titleFont)
                        .foregroundStyle(PebbleTheme.sandGold)
                        .padding(.top, 20)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 16
                    ) {
                        statCard("Games Played", "\(stats.gamesPlayed)")
                        statCard("Games Won", "\(stats.gamesWon)")
                        statCard(
                            "Win Rate",
                            stats.gamesPlayed > 0
                                ? "\(Int(Double(stats.gamesWon) / Double(stats.gamesPlayed) * 100))%"
                                : "—"
                        )
                        statCard("Best Streak", "\(stats.longestWinStreak)")
                        statCard("Draws", "\(stats.gamesDrawn)")
                        statCard("High Score", "\(stats.highScore)")
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PebbleTheme.sandGold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(PebbleTheme.woodBrown.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
