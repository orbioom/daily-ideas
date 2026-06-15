import SwiftUI
import SwiftData

/// Play menu: layout cards with previews + best times, Continue, Daily entry,
/// quick stats, and access to How to Play.
struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Query(sort: \SavedGame.savedAt, order: .reverse) private var savedGames: [SavedGame]

    @State private var path = NavigationPath()
    @State private var paywall: PaywallReason?
    @State private var showHowTo = false

    private var savedGame: SavedGame? { savedGames.first }

    private var snapshots: [StatsEngine.RecordSnapshot] {
        records.map { .init(layout: $0.layout, won: $0.won, durationSec: $0.durationSec, moves: $0.moves, date: $0.date) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let saved = savedGame { continueCard(saved) }
                    dailyCard
                    layoutsSection
                    quickStats
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Lantern")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHowTo = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("How to play")
                }
            }
            .navigationDestination(for: GameLaunch.self) { launch in
                GameContainerView(launch: launch)
            }
            .sheet(item: $paywall) { PaywallView(reason: $0) }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("A calm game of matching")
                .font(Theme.serif(15))
                .foregroundStyle(Theme.inkSoft)
            Text("Clear the board, one pair at a time.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Continue

    private func continueCard(_ saved: SavedGame) -> some View {
        Button {
            path.append(GameLaunch(source: .resume))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 56, height: 56)
                    Image(systemName: "play.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue")
                        .font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                    Text("\(saved.layout.displayName)\(saved.isDaily ? " · Daily" : "")")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    Text("Saved \(saved.savedAt.formatted(.relative(presentation: .named)))")
                        .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Resume your in-progress board")
    }

    // MARK: Daily

    private var dailyCard: some View {
        let key = DailyKey.key()
        return Button {
            path.append(GameLaunch(source: .daily(dateKey: key, layout: .turtle)))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.goldSoft)
                        .frame(width: 56, height: 56)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22)).foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Challenge")
                        .font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                    Text("Today's puzzle — same board for everyone")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    // MARK: Layouts

    private var layoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layouts")
                .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(LayoutKind.allCases) { layout in
                    layoutCard(layout)
                }
            }
        }
    }

    private func layoutCard(_ layout: LayoutKind) -> some View {
        let unlocked = Pro.isLayoutUnlocked(layout, isPro: isPro)
        let best = StatsEngine.bestTime(for: layout, in: snapshots)
        return Button {
            if unlocked {
                path.append(GameLaunch(source: .fresh(layout)))
            } else {
                paywall = .lockedLayout(layout)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    LayoutPreview(layout: layout, tint: settings.tileTheme(isPro: isPro).backColor)
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Theme.accent, in: Circle())
                            .padding(6)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.displayName)
                        .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(layout.tileCount) tiles")
                        .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    if let best {
                        Label(TimeFormat.clock(best), systemImage: "trophy.fill")
                            .font(Theme.rounded(11, .medium)).foregroundStyle(Theme.gold)
                    } else {
                        Text("No best time yet")
                            .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            .cardSurface(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(layout.displayName), \(layout.tileCount) tiles\(unlocked ? "" : ", locked")")
        .accessibilityHint(unlocked ? "Start a new game" : "Unlock with Lantern Pro")
    }

    // MARK: Quick stats

    private var quickStats: some View {
        let played = StatsEngine.totalPlayed(snapshots)
        let rate = StatsEngine.overallWinRate(snapshots)
        return HStack(spacing: 14) {
            quickStat("Games", "\(played)")
            quickStat("Win rate", played == 0 ? "—" : "\(Int((rate * 100).rounded()))%")
            quickStat("Layouts", "\(isPro ? LayoutKind.allCases.count : Pro.freeLayouts.count)/\(LayoutKind.allCases.count)")
        }
    }

    private func quickStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.accent)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
