import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SudokuGame.updatedAt, order: .reverse) private var games: [SudokuGame]

    @State private var generating = false
    @State private var target: SudokuGame?

    private var inProgress: SudokuGame? {
        games.first { !$0.isComplete && !$0.isDaily && $0.filledCount > $0.givenGrid.filter { $0 != 0 }.count }
            ?? games.first { !$0.isComplete && !$0.isDaily }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        title
                        if let g = inProgress { continueCard(g) }
                        newGameCard
                    }
                    .padding(20)
                }
                if generating { generatingOverlay }
            }
            .navigationTitle("Glyph")
            .navigationDestination(item: $target) { game in
                GameView(session: GameSession(game: game, context: context))
            }
        }
    }

    private var title: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SudokuDifficulty.medium.tint)
                .accessibilityHidden(true)
            Text("Clean Sudoku")
                .font(.title2.bold()).foregroundStyle(Brand.text)
            Text("No ads, no nagging. Pencil notes, smart hints, and conflict highlighting that actually teach.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 12)
        }
        .padding(.top, 8)
    }

    private func continueCard(_ g: SudokuGame) -> some View {
        Button { target = g } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(g.difficulty.tint.opacity(0.16)).frame(width: 54, height: 54)
                    Text("\(Int(g.progress * 100))%")
                        .font(Brand.mono(14, weight: .semibold)).foregroundStyle(g.difficulty.tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue").font(.headline).foregroundStyle(Brand.text)
                    Text("\(g.difficulty.title) · \(StatsEngine.format(g.elapsedSeconds)) elapsed")
                        .font(.caption).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "play.fill").foregroundStyle(g.difficulty.tint)
            }
            .padding(16).glassCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue \(g.difficulty.title) game, \(Int(g.progress * 100)) percent done")
    }

    private var newGameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEW GAME").font(Brand.mono(12, weight: .medium)).tracking(1.4)
                .foregroundStyle(Brand.text3)
            ForEach(SudokuDifficulty.allCases) { d in
                Button { Task { await start(d) } } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 4).fill(d.tint).frame(width: 4, height: 30)
                        Text(d.title).font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(d.targetClues) clues").font(.caption).foregroundStyle(Brand.text3)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14)
                    .glassCard(padding: 0)
                }
                .buttonStyle(.plain)
                .disabled(generating)
                .accessibilityLabel("New \(d.title) game")
            }
        }
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Brand.text)
                Text("Crafting a unique puzzle…").font(.subheadline).foregroundStyle(Brand.text)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .transition(.opacity)
        .accessibilityLabel("Generating puzzle")
    }

    private func start(_ d: SudokuDifficulty) async {
        withAnimation { generating = true }
        let puzzle = await PuzzleFactory.make(d)
        let game = SudokuGame(difficulty: d, givens: puzzle.givens, solution: puzzle.solution)
        context.insert(game)
        try? context.save()
        withAnimation { generating = false }
        target = game
        Haptics.tap()
    }
}

#Preview {
    HomeView().modelContainer(for: SudokuGame.self, inMemory: true)
}
