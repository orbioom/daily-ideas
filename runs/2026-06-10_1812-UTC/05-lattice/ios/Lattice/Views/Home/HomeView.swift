import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var games: [SavedGame]
    @Query private var allStats: [GameStats]
    @State private var path: [SavedGame] = []
    @State private var generating = false

    private var resumable: SavedGame? {
        games.first { !$0.isDaily && !$0.isComplete }
    }
    private var totalWon: Int { allStats.reduce(0) { $0 + $1.won } }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        if let game = resumable { continueCard(game) }
                        newGameCard
                        statStrip
                    }
                    .padding(16)
                }
                if generating { generatingOverlay }
            }
            .navigationTitle("Lattice")
            .navigationDestination(for: SavedGame.self) { BoardView(game: $0) }
        }
    }

    private func continueCard(_ game: SavedGame) -> some View {
        Button {
            path.append(game)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Continue")
                    Spacer()
                    Label(game.difficulty.rawValue, systemImage: game.difficulty.icon)
                        .font(Brand.mono(12)).foregroundStyle(game.difficulty.tint)
                }
                HStack(alignment: .bottom) {
                    Text(timeString(game.elapsed))
                        .font(Brand.mono(30, weight: .semibold)).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(game.filledCount)/81 filled")
                        .font(Brand.mono(13)).foregroundStyle(Brand.text3)
                }
                ProgressView(value: game.progress).tint(game.difficulty.tint)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue \(game.difficulty.rawValue) game, \(game.filledCount) of 81 filled")
    }

    private var newGameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "New game")
            ForEach(Difficulty.allCases) { diff in
                Button { startNew(diff) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: diff.icon)
                            .foregroundStyle(diff.tint)
                            .frame(width: 40, height: 40)
                            .background(diff.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text(diff.rawValue).font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(diff.clueTarget) clues").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .disabled(generating)
                if diff != Difficulty.allCases.last {
                    Divider().background(Brand.hairline)
                }
            }
        }
        .glassCard()
    }

    private var statStrip: some View {
        HStack(spacing: 12) {
            miniStat("\(games.filter { $0.isComplete }.count)", "Solved")
            miniStat("\(totalWon)", "Wins")
            miniStat("\(games.filter { !$0.isComplete && !$0.isDaily }.count)", "In progress")
        }
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().tint(Brand.text)
                Text("Crafting a unique puzzle…").font(.subheadline).foregroundStyle(Brand.text2)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func startNew(_ difficulty: Difficulty) {
        guard !generating else { return }
        generating = true
        Haptics.tap()
        let seed = UInt64(Date.now.timeIntervalSince1970 * 1000)
            ^ (UInt64.random(in: 0...UInt64.max))
        Task {
            let puzzle = await Task.detached(priority: .userInitiated) {
                SudokuEngine.generate(difficulty: difficulty, seed: seed)
            }.value
            await MainActor.run {
                for game in games where !game.isDaily && !game.isComplete {
                    context.delete(game)
                }
                let game = SavedGame(difficulty: difficulty, givens: puzzle.givens, solution: puzzle.solution)
                context.insert(game)
                try? context.save()
                generating = false
                path.append(game)
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
