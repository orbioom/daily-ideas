import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedGame> { $0.slot == 0 }) private var saved: [SavedGame]
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    @State private var path: [HomeRoute] = []
    @State private var showPaywall = false

    private var savedGame: SavedGame? { saved.first }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if let savedGame, let st = savedGame.decodedState() {
                        resumeCard(savedGame, state: st)
                    }
                    quickPlayCard
                    actionsGrid
                    if !pro.isPro { proNudge }
                    recentStrip
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Crest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HomeRoute.howToPlay) {
                        Image(systemName: "questionmark.circle")
                            .accessibilityLabel("How to play")
                    }
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .newGame:
                    NewGameView { request in path.append(.game(request)) }
                case .howToPlay:
                    HowToPlayView()
                case .game(let request):
                    GameContainerView(request: request) { path.removeAll() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text("Clear the peaks")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func resumeCard(_ saved: SavedGame, state: BoardState) -> some View {
        let remaining = state.tableau.filter { $0 != nil }.count
        return Button {
            path.append(.game(.resumeSaved(saved.layout, dealNumber: saved.dealNumber, isDaily: saved.isDaily)))
        } label: {
            SurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 52, height: 52)
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 22))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Resume game")
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(saved.layout.title) · \(remaining) cards left · \(Format.score(state.score)) pts")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Continue your in-progress game")
    }

    private var quickPlayCard: some View {
        let deal = Int.random(in: 1000...9999)
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "mountain.2.fill").foregroundStyle(Theme.accent)
                    Text("Three Peaks")
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("Free")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent.opacity(0.12)))
                }
                Text("Jump into a fresh random deal of the classic board.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "Quick play", icon: "play.fill") {
                    path.append(.game(.new(.threePeaks, dealNumber: deal, isDaily: false)))
                }
            }
        }
    }

    private var actionsGrid: some View {
        HStack(spacing: 14) {
            NavigationLink(value: HomeRoute.newGame) {
                actionTile(icon: "square.grid.2x2.fill", title: "New Game", subtitle: "Pick a board")
            }
            .buttonStyle(PressableStyle())
            NavigationLink(value: HomeRoute.howToPlay) {
                actionTile(icon: "book.fill", title: "How to Play", subtitle: "Learn the rules")
            }
            .buttonStyle(PressableStyle())
        }
    }

    private func actionTile(icon: String, title: String, subtitle: String) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var proNudge: some View {
        Button { showPaywall = true } label: {
            SurfaceCard {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock Crest Pro")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Pyramid, Diamond, daily archive & themes")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    @ViewBuilder
    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent games")
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            if results.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No games yet",
                    message: "Play your first deal and it will show up here."
                )
            } else {
                ForEach(results.prefix(4)) { r in
                    HStack(spacing: 12) {
                        Image(systemName: r.won ? "checkmark.seal.fill" : "xmark.seal")
                            .foregroundStyle(r.won ? Theme.good : Theme.inkFaint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.layout.title)
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(Format.shortDay.string(from: r.date) + (r.isDaily ? " · Daily" : ""))
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text("\(Format.score(r.score))")
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(r.layout.title), \(r.won ? "won" : "lost"), \(r.score) points")
                    if r.id != results.prefix(4).last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}
