import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var statsQuery: [PegStats]

    private var stats: PegStats { statsQuery.first ?? PegStats() }

    var body: some View {
        ZStack {
            PegTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Statistics")
                        .font(PegTheme.titleFont)
                        .foregroundStyle(PegTheme.goldAccent)
                        .padding(.top, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(label: "Games Played", value: "\(stats.gamesPlayed)")
                        statCard(label: "Games Won", value: "\(stats.gamesWon)")
                        statCard(label: "Win Rate", value: stats.gamesPlayed > 0 ? "\(Int(Double(stats.gamesWon)/Double(stats.gamesPlayed)*100))%" : "—")
                        statCard(label: "Best Streak", value: "\(stats.longestWinStreak)")
                        statCard(label: "Total Points", value: "\(stats.totalPoints)")
                        statCard(label: "High Score", value: "\(stats.highScore)")
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(PegTheme.goldAccent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(PegTheme.feltGreenDark.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
