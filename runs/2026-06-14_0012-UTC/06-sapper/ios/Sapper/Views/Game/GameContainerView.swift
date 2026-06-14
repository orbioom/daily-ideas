import SwiftUI
import SwiftData

/// Builds the GameViewModel for a route and hosts the board. Handles the resume
/// path (which can fail to decode → recoverable error state).
struct GameContainerView: View {
    let route: GameRoute

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("flagModeDefault") private var flagModeDefault = false
    @AppStorage("questionMarks") private var questionMarks = false

    @StateObject private var holder = VMHolder()
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let vm = holder.vm {
                GameBoardView(vm: vm, onPlayAgain: rebuildFresh)
                    .id(holder.generation)
            } else if loadFailed {
                errorState
            } else {
                loadingState
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { buildIfNeeded() }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Setting up the board…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var errorState: some View {
        VStack(spacing: 18) {
            EmptyStateView(systemImage: "exclamationmark.triangle",
                           title: "Couldn't load that game",
                           message: "The saved game was unreadable. Start a fresh board instead.")
            PrimaryButton(title: "Back to Home", systemImage: "house") {
                dismiss()
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private func buildIfNeeded() {
        guard holder.vm == nil, !loadFailed else { return }

        if route.resume {
            let descriptor = FetchDescriptor<SavedGame>()
            let saved = (try? context.fetch(descriptor))?.first
            guard let saved, let vm = GameViewModel(resuming: saved) else {
                loadFailed = true
                return
            }
            configure(vm)
            holder.vm = vm
            return
        }

        let config = BoardConfig(rows: route.rows, cols: route.cols, mines: route.mines)
        let kind: GameKind
        switch route.source {
        case .standard(let raw):
            kind = .standard(Difficulty(rawValue: raw) ?? .custom)
        case .daily(let key):
            kind = .daily(dateKey: key)
        }
        let vm = GameViewModel(kind: kind, config: config,
                               noGuess: route.noGuess, seed: route.seed)
        configure(vm)
        holder.vm = vm
    }

    private func configure(_ vm: GameViewModel) {
        vm.bind(context: context)
        vm.flagMode = flagModeDefault
        vm.allowQuestionMarks = questionMarks
    }

    /// Build a brand-new board for the same route source/config (for "Play again").
    /// Daily replays reuse the same seed; standard games get a new random board.
    private func rebuildFresh() {
        holder.vm?.stopTimer()
        let config = BoardConfig(rows: route.rows, cols: route.cols, mines: route.mines)
        let kind: GameKind
        var seed: UInt64? = nil
        switch route.source {
        case .standard(let raw):
            kind = .standard(Difficulty(rawValue: raw) ?? .custom)
        case .daily(let key):
            kind = .daily(dateKey: key)
            seed = route.seed
        }
        let vm = GameViewModel(kind: kind, config: config, noGuess: route.noGuess, seed: seed)
        configure(vm)
        holder.vm = vm
        holder.generation &+= 1
    }
}

/// Holds the view model so it survives view re-evaluation (created lazily in task).
@MainActor
final class VMHolder: ObservableObject {
    @Published var vm: GameViewModel?
    /// Bumped on "Play again" to force the board view to re-init (zoom, overlay, etc.).
    @Published var generation: Int = 0
}
