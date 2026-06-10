import SwiftUI
import SwiftData

/// Routes a Game to its player view. Used both for single plays and inside the
/// daily workout flow.
struct GamePlayer: View {
    let game: Game
    let difficulty: Difficulty
    let duration: Int
    let onComplete: (PlayResult) -> Void

    var body: some View {
        switch game {
        case .math, .focus, .logic:
            ChoiceGamePlayerView(game: game, difficulty: difficulty, duration: duration, onComplete: onComplete)
        case .memory:
            MemoryGameView(difficulty: difficulty, duration: duration, onComplete: onComplete)
        case .anagram:
            AnagramGameView(difficulty: difficulty, duration: duration, onComplete: onComplete)
        }
    }
}

/// Full-screen container for a single game: play → result.
struct SingleGameHost: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var results: [GameResult]

    let game: Game
    let difficulty: Difficulty
    let duration: Int

    @State private var result: PlayResult?
    @State private var playID = UUID()

    var body: some View {
        ZStack {
            if let result {
                ResultView(result: result,
                           best: StatsEngine.summary(results, game: game).best,
                           onAgain: replay,
                           onDone: { dismiss() })
            } else {
                GamePlayer(game: game, difficulty: difficulty, duration: duration) { r in
                    persist(r)
                }
                .id(playID)
            }
        }
    }

    private func persist(_ r: PlayResult) {
        context.insert(GameResult(game: r.game, score: r.score, accuracy: r.accuracy,
                                  correct: r.correct, attempted: r.attempted, difficulty: difficulty))
        try? context.save()
        withAnimation(Brand.ease()) { result = r }
    }

    private func replay() {
        result = nil
        playID = UUID()
    }
}

struct ResultView: View {
    let result: PlayResult
    let best: Int
    let onAgain: () -> Void
    let onDone: () -> Void

    private var isRecord: Bool { result.score >= best && result.score > 0 }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: result.game.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(result.game.tint)
                    .accessibilityHidden(true)
                Text(result.game.title).font(.title2.bold()).foregroundStyle(Brand.text)

                Text("\(result.score)")
                    .font(Brand.mono(64, weight: .bold))
                    .foregroundStyle(result.game.tint)
                Text("points").font(.subheadline).foregroundStyle(Brand.text2)

                if isRecord {
                    Label("New best!", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(Brand.magic)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Brand.magic.opacity(0.15), in: Capsule())
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(result.correct)", label: "Correct", tint: Brand.live)
                    StatTile(value: "\(Int(result.accuracy * 100))%", label: "Accuracy")
                    StatTile(value: "\(best)", label: "Best")
                }
                .padding(.horizontal, 20)

                Spacer()
                VStack(spacing: 12) {
                    Button { onAgain() } label: { Label("Play again", systemImage: "arrow.clockwise") }
                        .buttonStyle(InkButtonStyle())
                    Button("Done") { onDone() }
                        .font(.headline).foregroundStyle(Brand.text2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }
}
