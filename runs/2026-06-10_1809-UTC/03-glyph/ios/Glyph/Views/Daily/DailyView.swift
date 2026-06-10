import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [SudokuGame]

    @State private var generating = false
    @State private var target: SudokuGame?

    /// The daily puzzle's difficulty rotates by weekday for variety.
    private var todayDifficulty: SudokuDifficulty {
        let wd = Calendar.current.component(.weekday, from: .now) // 1=Sun
        switch wd {
        case 1, 7: return .hard        // weekends harder
        case 2: return .easy
        case 3, 5: return .medium
        default: return .medium
        }
    }

    private var todaysGame: SudokuGame? {
        let today = Calendar.current.startOfDay(for: .now)
        return games.first {
            $0.isDaily && Calendar.current.startOfDay(for: $0.startedAt) == today
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        banner
                        if let g = todaysGame {
                            existingCard(g)
                        } else {
                            newCard
                        }
                        recentDailies
                    }
                    .padding(20)
                }
                if generating { GeneratingOverlay() }
            }
            .navigationTitle("Daily")
            .navigationDestination(item: $target) { game in
                GameView(session: GameSession(game: game, context: context))
            }
        }
    }

    private var banner: some View {
        VStack(spacing: 8) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline).foregroundStyle(Brand.text)
            Text("One puzzle a day, the same for everyone. Keep your streak alive.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func existingCard(_ g: SudokuGame) -> some View {
        VStack(spacing: 12) {
            HStack {
                Label(g.difficulty.title, systemImage: "calendar")
                    .font(.headline).foregroundStyle(g.difficulty.tint)
                Spacer()
                if g.isComplete {
                    Label("Solved", systemImage: "checkmark.seal.fill")
                        .font(.subheadline).foregroundStyle(Brand.live)
                }
            }
            if g.isComplete {
                HStack(spacing: 12) {
                    StatTile(value: StatsEngine.format(g.elapsedSeconds), label: "Time")
                    StatTile(value: "\(g.mistakes)", label: "Mistakes")
                }
            }
            Button {
                target = g
            } label: {
                Label(g.isComplete ? "Review puzzle" : "Continue today's puzzle",
                      systemImage: g.isComplete ? "eye" : "play.fill")
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(18).glassCard()
    }

    private var newCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(todayDifficulty.tint.opacity(0.16)).frame(width: 90, height: 90)
                Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(todayDifficulty.tint)
            }
            .accessibilityHidden(true)
            Text("Today's puzzle is \(todayDifficulty.title)")
                .font(.headline).foregroundStyle(Brand.text)
            Button { Task { await startDaily() } } label: {
                Label("Play today's puzzle", systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(generating)
        }
        .padding(18).glassCard()
    }

    private var recentDailies: some View {
        let solved = games.filter { $0.isDaily && $0.isComplete }
            .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
            .prefix(6)
        return Group {
            if !solved.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("RECENT DAILIES").font(Brand.mono(12, weight: .medium)).tracking(1.4)
                        .foregroundStyle(Brand.text3)
                    ForEach(Array(solved)) { g in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.live)
                            Text(g.finishedAt ?? g.startedAt, format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(Brand.text)
                            Text(g.difficulty.title).font(.caption).foregroundStyle(Brand.text3)
                            Spacer()
                            Text(StatsEngine.format(g.elapsedSeconds))
                                .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(18).glassCard()
            }
        }
    }

    private func startDaily() async {
        withAnimation { generating = true }
        let seed = StatsEngine.dailySeed()
        let puzzle = await PuzzleFactory.make(todayDifficulty, seed: seed)
        let game = SudokuGame(difficulty: todayDifficulty, givens: puzzle.givens,
                              solution: puzzle.solution, isDaily: true)
        context.insert(game)
        try? context.save()
        withAnimation { generating = false }
        target = game
        Haptics.tap()
    }
}

struct GeneratingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Brand.text)
                Text("Crafting today's puzzle…").font(.subheadline).foregroundStyle(Brand.text)
            }
            .padding(28).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .transition(.opacity)
        .accessibilityLabel("Generating puzzle")
    }
}

#Preview {
    DailyView().modelContainer(for: SudokuGame.self, inMemory: true)
}
