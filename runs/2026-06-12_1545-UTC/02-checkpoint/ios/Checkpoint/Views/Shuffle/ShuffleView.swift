import SwiftUI
import SwiftData

struct ShuffleView: View {
    @Query private var games: [Game]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var platformFilter: Platform? = nil
    @State private var maxLength: Double = 0   // 0 == any
    @State private var picked: Game?
    @State private var spinning = false
    @State private var spinTitle = ""

    private var pool: [Game] {
        games.filter { g in
            guard g.status.isPile else { return false }
            if let platformFilter, g.platform != platformFilter { return false }
            if maxLength > 0, g.estimatedHours > 0, g.estimatedHours > maxLength { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if BacklogEngine.pileSize(games) == 0 {
                    EmptyStateView(symbol: "tray",
                                   title: "Nothing in the pile",
                                   message: "Add some games to your backlog and Checkpoint will help you pick what to play.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            recommendationCard
                            resultCard
                            filterCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("What to play")
            .navigationDestination(for: Game.self) { GameDetailView(game: $0) }
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Our pick for you", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
            if let rec = BacklogEngine.nextUp(games) {
                NavigationLink(value: rec) {
                    HStack(spacing: 12) {
                        CoverSwatch(game: rec, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rec.title).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                            Text("\(rec.priority.label) priority · \(rec.estimatedHours > 0 ? Fmt.hours(rec.estimatedHours) : "unknown length")")
                                .font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("No backlog games match — add some or adjust filters below.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .cpCard()
    }

    private var resultCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.heroGradient)
                    .frame(height: 150)
                if spinning {
                    Text(spinTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal)
                } else if let picked {
                    VStack(spacing: 6) {
                        Text("Play this!").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                        Text(picked.title).font(.title2.weight(.bold)).foregroundStyle(.white)
                            .multilineTextAlignment(.center).lineLimit(2).padding(.horizontal)
                        Text("\(picked.platform.rawValue) · \(picked.estimatedHours > 0 ? Fmt.hours(picked.estimatedHours) : "?")")
                            .font(.caption).foregroundStyle(.white.opacity(0.85))
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "dice.fill").font(.largeTitle).foregroundStyle(.white)
                        Text("Tap shuffle for a random pick").font(.subheadline).foregroundStyle(.white.opacity(0.9))
                    }
                }
            }

            if let picked, !spinning {
                NavigationLink(value: picked) {
                    Text("Open \(picked.title)").font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.accent)
            }

            Button {
                shuffle()
            } label: {
                Label(spinning ? "Shuffling…" : "Shuffle the pile", systemImage: "dice")
                    .font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
            .disabled(pool.isEmpty || spinning)

            if pool.isEmpty {
                Text("No games match these filters.").font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                Text("\(pool.count) games in the pool").font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .cpCard()
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrow the pool").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Picker("Platform", selection: $platformFilter) {
                Text("Any platform").tag(Platform?.none)
                ForEach(platformsInPile, id: \.self) { p in Text(p.rawValue).tag(Platform?.some(p)) }
            }
            .pickerStyle(.menu)
            VStack(alignment: .leading) {
                HStack {
                    Text("Max length")
                    Spacer()
                    Text(maxLength == 0 ? "Any" : Fmt.hours(maxLength)).foregroundStyle(Theme.accent)
                }
                .font(.subheadline)
                Slider(value: $maxLength, in: 0...80, step: 5)
                    .tint(Theme.accent)
            }
        }
        .cpCard()
    }

    private var platformsInPile: [Platform] {
        Array(Set(games.filter { $0.status.isPile }.map(\.platform))).sorted { $0.rawValue < $1.rawValue }
    }

    private func shuffle() {
        let candidates = pool
        guard !candidates.isEmpty else { return }
        Haptics.tap()
        guard !reduceMotion else {
            picked = candidates.randomElement()
            Haptics.success()
            return
        }
        spinning = true
        picked = nil
        Task {
            for _ in 0..<14 {
                spinTitle = candidates.randomElement()?.title ?? ""
                try? await Task.sleep(for: .milliseconds(80))
            }
            picked = candidates.randomElement()
            spinning = false
            Haptics.success()
        }
    }
}
