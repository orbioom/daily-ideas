import SwiftUI
import SwiftData

struct PlayPickerView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var games: [BoardGame]

    @State private var playerCount = 3
    @State private var maxDuration = 0          // 0 = any
    @State private var minWeight = 1.0
    @State private var maxWeight = 5.0
    @State private var seed: UInt64 = 1
    @State private var revealed: BoardGame?
    @State private var logGame: BoardGame?
    @State private var paywall: PaywallReason?

    private var criteria: PlayPickerCriteria {
        PlayPickerCriteria(
            playerCount: playerCount,
            maxDuration: isPro ? maxDuration : 0,
            minWeight: isPro ? minWeight : 1.0,
            maxWeight: isPro ? maxWeight : 5.0
        )
    }
    private var eligible: [BoardGame] { PlayPicker.eligible(games, criteria: criteria) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        filtersCard
                        if let revealed {
                            revealCard(revealed)
                        }
                        resultsCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("What to Play?")
            .sheet(item: $logGame) { g in LogPlayView(preselectedGame: g) }
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
            .navigationDestination(for: UUID.self) { id in GameDetailResolver(gameID: id) }
        }
    }

    private var filtersCard: some View {
        CardSection("Tonight's table") {
            VStack(spacing: 14) {
                Stepper("Players at the table: \(playerCount)", value: $playerCount, in: 1...12)
                    .font(Theme.rounded(15))

                if isPro {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(maxDuration == 0 ? "Max time: Any" : "Max time: \(maxDuration) min")
                            .font(Theme.rounded(15))
                        Slider(value: Binding(get: { Double(maxDuration) },
                                              set: { maxDuration = Int($0) }), in: 0...240, step: 15)
                            .tint(Theme.accent)
                            .accessibilityLabel("Maximum play time")
                            .accessibilityValue(maxDuration == 0 ? "Any" : "\(maxDuration) minutes")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight: \(settings.showWeightAs.render(minWeight)) – \(settings.showWeightAs.render(maxWeight))")
                            .font(Theme.rounded(15))
                        HStack {
                            Slider(value: $minWeight, in: 1...5, step: 0.5)
                                .tint(Theme.accent).accessibilityLabel("Minimum weight")
                                .accessibilityValue(String(format: "%.1f", minWeight))
                                .onChange(of: minWeight) { _, v in if v > maxWeight { maxWeight = v } }
                            Slider(value: $maxWeight, in: 1...5, step: 0.5)
                                .tint(Theme.accentDeep).accessibilityLabel("Maximum weight")
                                .accessibilityValue(String(format: "%.1f", maxWeight))
                                .onChange(of: maxWeight) { _, v in if v < minWeight { minWeight = v } }
                        }
                    }
                } else {
                    Button {
                        paywall = .picker
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Unlock time & weight filters with Pro")
                                .font(Theme.rounded(14, .semibold))
                            Spacer()
                        }
                        .foregroundStyle(Theme.accentDeep)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.accentSoft.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    reroll()
                } label: {
                    Label("Surprise Me", systemImage: "sparkles")
                        .font(Theme.rounded(17, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(eligible.isEmpty)
            }
        }
    }

    private func revealCard(_ game: BoardGame) -> some View {
        CardSection("Tonight, play…") {
            VStack(spacing: 12) {
                NavigationLink(value: game.id) {
                    HStack(spacing: 14) {
                        GameCover(title: game.title, initials: game.initials,
                                  coverHue: game.coverHue, symbol: game.coverSymbol)
                            .frame(width: 84, height: 84)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title).font(Theme.serif(20, .bold)).foregroundStyle(Theme.textPrimary)
                            Text(game.designer).font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
                            HStack(spacing: 6) {
                                InfoPill(symbol: "person.2.fill", text: game.playerRangeText)
                                InfoPill(symbol: "clock", text: "\(game.playTimeMin)m")
                                InfoPill(symbol: "scalemass", text: settings.showWeightAs.render(game.weight), tint: Theme.accent)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                HStack {
                    Button { reroll() } label: {
                        Label("Re-roll", systemImage: "arrow.triangle.2.circlepath").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                    Button { logGame = game } label: {
                        Label("Log a play", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder private var resultsCard: some View {
        CardSection("Eligible games (\(eligible.count))") {
            if eligible.isEmpty {
                EmptyStateView(
                    symbol: "slider.horizontal.below.rectangle",
                    title: "No matches",
                    message: "Your filters are too tight, or you don't own a game for this table. Loosen the filters or add games."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(eligible) { g in
                        NavigationLink(value: g.id) {
                            HStack(spacing: 10) {
                                GameCover(title: g.title, initials: g.initials,
                                          coverHue: g.coverHue, symbol: g.coverSymbol)
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.textPrimary)
                                    Text("\(g.playerRangeText) players · \(g.playTimeMin)m · \(settings.showWeightAs.render(g.weight))")
                                        .font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                if g.rating > 0 {
                                    Text("\(g.rating)").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.warning)
                                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Theme.warning)
                                }
                            }
                            .contentShape(Rectangle()).padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        if g.id != eligible.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func reroll() {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        revealed = PlayPicker.pick(games, criteria: criteria, seed: seed)
        Haptics.tap(settings.hapticsEnabled)
    }
}
