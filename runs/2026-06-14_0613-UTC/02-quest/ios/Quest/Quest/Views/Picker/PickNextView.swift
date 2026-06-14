import SwiftUI
import SwiftData

struct PickNextView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var games: [Game]

    @State private var filters = PickFilters()
    @State private var seed: UInt64 = 1
    @State private var picked: Game?
    @State private var rolling = false
    @State private var spinFace: String = "?"
    @State private var paywall: PaywallReason?

    private var backlog: [Game] { games.filter { $0.status == .backlog } }

    private var candidates: [Game] {
        BacklogEngine.pickCandidates(games, filters: effectiveFilters)
    }

    /// Free users get even-odds with no advanced filters; Pro unlocks them.
    private var effectiveFilters: PickFilters {
        if isPro { return filters }
        var f = PickFilters()
        f.weighting = .even
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if backlog.isEmpty {
                    EmptyStateView(
                        symbol: "tray.fill",
                        title: "No backlog yet",
                        message: "Add games and set them to Backlog. Then spin here to decide what to play next."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            reel
                            if isPro {
                                filterCard
                            } else {
                                lockedFiltersCard
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Play Next")
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        }
    }

    // MARK: Reel

    private var reel: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(Theme.accent.opacity(0.4), lineWidth: 2))
                    .frame(height: 260)

                if rolling {
                    spinningFace
                } else if let game = picked {
                    resultFace(game)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Ready when you are")
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.text)
                        Text("\(candidates.count) games match")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            if candidates.isEmpty && !rolling {
                Text("No backlog games match these filters. Loosen them and try again.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.warning)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    roll()
                } label: {
                    Label(picked == nil ? "Spin" : "Roll again", systemImage: "arrow.triangle.2.circlepath")
                        .font(Theme.rounded(16, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                .foregroundStyle(.white)
                .disabled(candidates.isEmpty || rolling)

                if let game = picked, !rolling {
                    Button {
                        startPlaying(game)
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(Theme.rounded(16, .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Theme.success, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var spinningFace: some View {
        VStack(spacing: 8) {
            Text(spinFace)
                .font(Theme.rounded(22, .heavy))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            Text("Rolling…")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityHidden(true)
    }

    private func resultFace(_ game: Game) -> some View {
        VStack(spacing: 12) {
            GameCover(title: game.title, initials: game.initials,
                      hue: game.coverHue, style: settings.coverStyle)
                .frame(width: 92, height: 122)
            Text(game.title)
                .font(Theme.rounded(19, .heavy))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            HStack(spacing: 8) {
                Label(game.platform.label, systemImage: game.platform.symbol)
                Text("·")
                Label(game.mainStoryHours > 0 ? settings.formatHours(game.mainStoryHours) : "Length unknown",
                      systemImage: "clock")
            }
            .font(Theme.rounded(13, .medium))
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Picked \(game.title) on \(game.platform.label)")
    }

    // MARK: Filters (Pro)

    private var filterCard: some View {
        SectionCard(title: "Filters", systemImage: "slider.horizontal.3") {
            Picker("Platform", selection: $filters.platform) {
                Text("Any platform").tag(Platform?.none)
                ForEach(Platform.allCases) { p in
                    Text(p.label).tag(Platform?.some(p))
                }
            }
            Picker("Genre", selection: $filters.genre) {
                Text("Any genre").tag(Genre?.none)
                ForEach(Genre.allCases) { g in
                    Text(g.label).tag(Genre?.some(g))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Max length").font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(filters.maxHours == nil ? "Any" : settings.formatHours(filters.maxHours ?? 0))
                        .font(Theme.mono(14, .bold)).foregroundStyle(Theme.accent)
                }
                Slider(value: Binding(
                    get: { filters.maxHours ?? 0 },
                    set: { filters.maxHours = $0 <= 0 ? nil : $0 }
                ), in: 0...100, step: 5)
                .accessibilityLabel("Maximum length in hours")
                .accessibilityValue(filters.maxHours == nil ? "Any" : "\(Int(filters.maxHours ?? 0)) hours")
            }
            Toggle("Favorites only", isOn: $filters.favoritesOnly)
            Picker("Weighting", selection: $filters.weighting) {
                ForEach(PickWeighting.allCases) { w in
                    Text(w.label).tag(w)
                }
            }
            .pickerStyle(.menu)
        }
        .onChange(of: filters.platform) { _, _ in picked = nil }
        .onChange(of: filters.genre) { _, _ in picked = nil }
        .onChange(of: filters.favoritesOnly) { _, _ in picked = nil }
    }

    private var lockedFiltersCard: some View {
        Button {
            paywall = .picker
        } label: {
            SectionCard(title: "Advanced filters", systemImage: "lock.fill") {
                Text("Filter by platform, genre and length, and weight the odds toward short games or favorites with Quest Pro.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
                Text("Unlock Quest Pro")
                    .font(Theme.rounded(14, .bold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func roll() {
        guard !candidates.isEmpty else { return }
        picked = nil
        seed = seed &+ UInt64(Date().timeIntervalSince1970 * 1000) | 1
        Haptics.play(.medium, enabled: settings.hapticsEnabled)

        let result = BacklogEngine.pickNext(games, filters: effectiveFilters, seed: seed)

        if reduceMotion {
            picked = result
            Haptics.play(.success, enabled: settings.hapticsEnabled)
            return
        }

        rolling = true
        animateSpin(remaining: 12, result: result)
    }

    /// A simple slot-machine flicker: cycle candidate titles, slowing to the result.
    private func animateSpin(remaining: Int, result: Game?) {
        guard remaining > 0 else {
            rolling = false
            picked = result
            Haptics.play(.success, enabled: settings.hapticsEnabled)
            return
        }
        spinFace = candidates.randomElement()?.title ?? "?"
        let delay = 0.05 + (0.18 * (1 - Double(remaining) / 12.0))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            animateSpin(remaining: remaining - 1, result: result)
        }
    }

    private func startPlaying(_ game: Game) {
        game.status = .playing
        game.dateCompleted = nil
        try? modelContext.save()
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        picked = nil
    }
}
