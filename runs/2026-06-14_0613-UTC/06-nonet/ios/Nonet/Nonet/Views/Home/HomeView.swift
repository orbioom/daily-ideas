import SwiftUI
import SwiftData

/// Home: daily card + streak, continue, new game by difficulty, quick stats peek.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage(Pro.storageKey) private var isPro = false

    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Query(filter: #Predicate<SavedGame> { $0.isActive == true && $0.completed == false },
           sort: \SavedGame.lastPlayed, order: .reverse) private var activeGames: [SavedGame]

    @State private var launch: GameLaunch? = nil
    @State private var paywall: PaywallReason? = nil

    private var todayKey: String { DailySeed.dateKey(for: Date()) }
    private var dailySolvedToday: Bool { StreakStore.isDailySolved() }

    /// In-progress daily for today (if any).
    private var dailyInProgress: SavedGame? {
        activeGames.first { $0.isDaily && $0.dateKey == todayKey }
    }
    /// Most recent in-progress casual game.
    private var casualInProgress: SavedGame? {
        activeGames.first { !$0.isDaily }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    dailyCard
                    if let game = casualInProgress {
                        continueCard(game)
                    }
                    newGameCard
                    statsPeek
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nonet")
            .fullScreenCover(item: $launch) { l in
                GameView(launch: l)
            }
            .sheet(item: $paywall) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: Daily card

    private var dailyCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Daily Puzzle", systemImage: "calendar")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    streakBadge
                }
                Text(longDateString)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)

                if dailySolvedToday {
                    Label("Solved today — nice work!", systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.success)
                    Button("Replay Today's Daily") {
                        launch = GameLaunch(mode: .daily, resumeId: nil)
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.accentSoft))
                } else if let game = dailyInProgress {
                    ProgressView(value: game.progress)
                        .tint(Theme.accent)
                    Button("Resume Daily") {
                        launch = GameLaunch(mode: .daily, resumeId: game.id)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Play Today's Puzzle") {
                        launch = GameLaunch(mode: .daily, resumeId: nil)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill").foregroundStyle(Theme.warning)
            Text("\(StreakStore.displayCurrent())")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.warning.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily streak \(StreakStore.displayCurrent()) days")
    }

    // MARK: Continue card

    private func continueCard(_ game: SavedGame) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Continue", systemImage: "play.circle.fill")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                HStack {
                    Image(systemName: game.difficulty.symbol)
                        .foregroundStyle(game.difficulty.tint)
                    Text(game.isDaily ? "Daily • \(game.difficulty.title)" : game.difficulty.title)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(timeString(game.elapsedSec))
                        .font(Theme.mono(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ProgressView(value: game.progress).tint(Theme.accent)
                Button("Resume") {
                    launch = GameLaunch(mode: game.isDaily ? .daily : .casual(game.difficulty),
                                        resumeId: game.id)
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.accentSoft))
            }
        }
    }

    // MARK: New game card

    private var newGameCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("New Game", systemImage: "plus.square.fill")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                ForEach(Difficulty.allCases) { diff in
                    Button {
                        if diff.isPro && !isPro {
                            paywall = .difficulty(diff)
                        } else {
                            launch = GameLaunch(mode: .casual(diff), resumeId: nil)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: diff.symbol)
                                .foregroundStyle(diff.tint)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(diff.title)
                                    .font(Theme.rounded(16, .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(diff.subtitle)
                                    .font(Theme.rounded(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if diff.isPro && !isPro {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .accessibilityLabel("\(diff.title), \(diff.subtitle)\(diff.isPro && !isPro ? ", Pro locked" : "")")
                    if diff != Difficulty.allCases.last {
                        Divider().background(Theme.separator)
                    }
                }
            }
        }
    }

    // MARK: Stats peek

    private var statsPeek: some View {
        let won = records.filter { $0.won }
        let solved = won.count
        let bestTimes = won.map { $0.timeSec }
        let best = bestTimes.min()
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Your Progress", systemImage: "chart.bar.fill")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                if records.isEmpty {
                    Text("No games yet — your stats will appear here once you finish a puzzle.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    HStack {
                        peekStat("Solved", "\(solved)")
                        Divider().frame(height: 36).background(Theme.separator)
                        peekStat("Best Time", best.map(timeString) ?? "—")
                        Divider().frame(height: 36).background(Theme.separator)
                        peekStat("Streak", "\(StreakStore.displayCurrent())")
                    }
                }
            }
        }
    }

    private func peekStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    // MARK: Helpers

    private var longDateString: String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: Date())
    }

    private func timeString(_ sec: Int) -> String {
        let m = sec / 60, s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// What game to launch. Identifiable so it can drive `.fullScreenCover(item:)`.
struct GameLaunch: Identifiable, Equatable {
    enum Mode: Equatable {
        case daily
        case casual(Difficulty)
    }
    let id = UUID()
    let mode: Mode
    let resumeId: UUID?
}
