import SwiftUI
import SwiftData

/// Today's deterministic puzzle. The signature board, with progress that
/// persists across launches via `GameProgress`.
struct DailyView: View {
    private var puzzle: Puzzle {
        let bank = PuzzleBank.core
        let idx = DailyEngine.puzzleIndex(for: .now, count: bank.count)
        return bank.indices.contains(idx) ? bank[idx] : (bank.first ?? Self.fallback)
    }

    private var dayKey: String { DailyEngine.dayKey(for: .now) }

    static let fallback = Puzzle(id: -1, letters: ["a","b","c","d","e","f","g"],
                                 center: "a", answers: ["abcde"], pangrams: ["abcde"])

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                // A new VM is built per day key + puzzle so switching days resets cleanly.
                BoardHost(puzzle: puzzle, dayKey: dayKey)
                    .id(dayKey + "-\(puzzle.id)")
            }
            .navigationTitle("Daily")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(Fmt.relativeDay(.now))
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }
}

/// Builds and owns a `GameViewModel` for a given puzzle + day, bridging the
/// SwiftData context into the board. Kept separate so each board screen can
/// create its VM from a stable identity.
struct BoardHost: View {
    let puzzle: Puzzle
    let dayKey: String
    @Environment(\.modelContext) private var context
    @State private var vm: GameViewModel?

    var body: some View {
        Group {
            if let vm {
                BoardView(vm: vm)
            } else {
                ProgressView().tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if vm == nil {
                vm = GameViewModel(puzzle: puzzle, dayKey: dayKey, context: context)
            }
        }
    }
}
