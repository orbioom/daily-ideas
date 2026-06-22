import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScrawlRecord.date, order: .reverse) private var recentGames: [ScrawlRecord]
    @Query private var settingsArray: [ScrawlSettings]

    @State private var showingSetup = false
    @Environment(\.colorScheme) private var colorScheme

    private var settings: ScrawlSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Recent games
                    recentGamesSection

                    // Quick stats
                    if !recentGames.isEmpty {
                        quickStatsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingSetup) {
                SetupView()
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text("✏️")
                        .font(.system(size: 40))
                    Text("Scrawl")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(ScrawlTheme.primaryText)
                }

                Text("The party drawing game")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
            }
            .padding(.top, 20)

            // Start button
            Button {
                showingSetup = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Start Game")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ScrawlTheme.coral)
                .cornerRadius(20)
                .shadow(color: ScrawlTheme.coral.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel("Start a new game")
        }
    }

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)

            if recentGames.isEmpty {
                emptyGamesState
            } else {
                VStack(spacing: 10) {
                    ForEach(recentGames.prefix(5)) { game in
                        RecentGameRow(record: game)
                    }
                }
            }
        }
    }

    private var emptyGamesState: some View {
        VStack(spacing: 16) {
            Text("🎨")
                .font(.system(size: 48))

            VStack(spacing: 6) {
                Text("No games yet!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)

                Text("Tap Start Game to begin your first round.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .scrawlCard()
        .padding(.horizontal, 0)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatPill(
                label: "Games",
                value: "\(recentGames.count)",
                color: ScrawlTheme.skyBlue
            )

            StatPill(
                label: "Best Score",
                value: bestScore,
                color: ScrawlTheme.coral
            )

            StatPill(
                label: "Rounds",
                value: totalRounds,
                color: ScrawlTheme.successGreen
            )
        }
    }

    private var bestScore: String {
        let max = recentGames.compactMap { $0.finalScores.max() }.max() ?? 0
        return "\(max)"
    }

    private var totalRounds: String {
        let total = recentGames.reduce(0) { $0 + $1.roundCount }
        return "\(total)"
    }
}

struct RecentGameRow: View {
    let record: ScrawlRecord
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Trophy or pack icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ScrawlTheme.skyBlue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .foregroundStyle(ScrawlTheme.skyBlue)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 3) {
                if let winner = record.winnerName {
                    Text("\(winner) won!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScrawlTheme.primaryText)
                }

                Text(record.teamNames.joined(separator: " vs "))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(record.finalScores.map(String.init).joined(separator: "-"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
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

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ScrawlTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .scrawlCard()
    }
}
